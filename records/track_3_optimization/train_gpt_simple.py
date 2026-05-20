"""
train_gpt_simple.py

This file descends from the [NanoGPT speedrun](https://github.com/KellerJordan/modded-nanogpt).
It was prepared as a simplified version of the speedrun for use in neural net optimization research.
"""

import os
import sys
with open(sys.argv[0]) as f:
    code = f.read() # read the code of this file ASAP, for logging
import argparse
import math
import uuid
import time
from pathlib import Path

import torch
from torch import Tensor, nn
from torch.optim import AdamW
import torch.nn.functional as F
import torch.distributed as dist
import wandb

TARGET_VAL_LOSS = 3.28
STAT_SIG_DELTA = 0.004
SLOPE_FRACTION = 0.10


def parse_args():
    parser = argparse.ArgumentParser(description="Modded-NanoGPT optimizer speedrun trainer")
    parser.add_argument("legacy_num_trials", nargs="?", type=int, help="Backward-compatible positional trial count")
    parser.add_argument("--num_trials", type=int, default=None)
    parser.add_argument("--wandb_name", default=os.environ.get("WANDB_NAME", ""))
    parser.add_argument("--wandb_group", default=os.environ.get("WANDB_RUN_GROUP", ""))
    parser.add_argument("--wandb_project", default=os.environ.get("WANDB_PROJECT", "modded-nanogpt-senpai"))
    parser.add_argument("--wandb_entity", default=os.environ.get("WANDB_ENTITY", ""))
    parser.add_argument("--wandb_tags", default=os.environ.get("WANDB_TAGS", ""))
    parser.add_argument("--wandb_mode", default=os.environ.get("WANDB_MODE", "online"))
    parser.add_argument("--telemetry_interval", type=int, default=int(os.environ.get("NANOGPT_TELEMETRY_INTERVAL", "25")))
    parser.add_argument("--histogram_interval", type=int, default=int(os.environ.get("NANOGPT_HISTOGRAM_INTERVAL", "125")))
    parser.add_argument("--histogram_samples", type=int, default=int(os.environ.get("NANOGPT_HISTOGRAM_SAMPLES", "65536")))
    parser.add_argument("--param_histogram_limit", type=int, default=int(os.environ.get("NANOGPT_PARAM_HISTOGRAM_LIMIT", "24")))
    args = parser.parse_args()
    args.num_trials = args.num_trials if args.num_trials is not None else (args.legacy_num_trials or 1)
    args.wandb_tags = [tag.strip() for tag in args.wandb_tags.split(",") if tag.strip()]
    if args.telemetry_interval < 1 or args.histogram_interval < 1:
        raise ValueError("--telemetry_interval and --histogram_interval must be positive")
    return args


args = parse_args()


def clean_metric_name(name: str) -> str:
    return name.replace(".", "/")


def tensor_stats(tensor: Tensor) -> dict[str, float]:
    values = tensor.detach().float()
    finite = torch.isfinite(values)
    finite_count = int(finite.sum().item())
    total_count = values.numel()
    if finite_count == 0:
        return {
            "elements": total_count,
            "finite_elements": 0,
            "nonfinite_count": total_count,
        }
    finite_values = values if finite_count == total_count else values[finite]
    return {
        "elements": total_count,
        "finite_elements": finite_count,
        "nonfinite_count": total_count - finite_count,
        "norm": float(finite_values.norm().item()),
        "rms": float(finite_values.square().mean().sqrt().item()),
        "mean": float(finite_values.mean().item()),
        "mean_abs": float(finite_values.abs().mean().item()),
        "std": float(finite_values.std(unbiased=False).item()) if finite_count > 1 else 0.0,
        "min": float(finite_values.min().item()),
        "max": float(finite_values.max().item()),
        "max_abs": float(finite_values.abs().max().item()),
        "zero_fraction": float((finite_values == 0).float().mean().item()),
    }


def aggregate_stats(named_tensors: list[tuple[str, Tensor]]) -> dict[str, float]:
    total_count = 0
    finite_count = 0
    sum_values = 0.0
    sum_abs = 0.0
    sum_squares = 0.0
    zero_count = 0
    min_value = float("inf")
    max_value = float("-inf")
    max_abs = 0.0
    for _, tensor in named_tensors:
        values = tensor.detach().float()
        total_count += values.numel()
        finite = torch.isfinite(values)
        count = int(finite.sum().item())
        if count == 0:
            continue
        finite_values = values if count == values.numel() else values[finite]
        finite_count += count
        sum_values += float(finite_values.sum().item())
        sum_abs += float(finite_values.abs().sum().item())
        sum_squares += float(finite_values.square().sum().item())
        zero_count += int((finite_values == 0).sum().item())
        min_value = min(min_value, float(finite_values.min().item()))
        max_value = max(max_value, float(finite_values.max().item()))
        max_abs = max(max_abs, float(finite_values.abs().max().item()))
    if finite_count == 0:
        return {
            "elements": total_count,
            "finite_elements": 0,
            "nonfinite_count": total_count,
        }
    mean = sum_values / finite_count
    variance = max(0.0, sum_squares / finite_count - mean * mean)
    return {
        "elements": total_count,
        "finite_elements": finite_count,
        "nonfinite_count": total_count - finite_count,
        "norm": sum_squares ** 0.5,
        "rms": (sum_squares / finite_count) ** 0.5,
        "mean": mean,
        "mean_abs": sum_abs / finite_count,
        "std": variance ** 0.5,
        "min": min_value,
        "max": max_value,
        "max_abs": max_abs,
        "zero_fraction": zero_count / finite_count,
    }


def prefixed(prefix: str, stats: dict[str, float]) -> dict[str, float]:
    return {f"{prefix}/{key}": value for key, value in stats.items()}


def loss_slope_stats(history: list[tuple[int, float]], window_steps: int) -> dict[str, float]:
    if len(history) < 2:
        return {}
    current_step = history[-1][0]
    window_start = current_step - window_steps
    points = [(step, loss) for step, loss in history if step >= window_start]
    if len(points) < 2:
        return {}
    xs = torch.tensor([step for step, _ in points], dtype=torch.float64)
    ys = torch.tensor([loss for _, loss in points], dtype=torch.float64)
    centered_xs = xs - xs.mean()
    denom = centered_xs.square().sum()
    if denom == 0:
        return {}
    slope = float((centered_xs * (ys - ys.mean())).sum().item() / denom.item())
    return {
        "loss_per_step": slope,
        "loss_per_100_steps": 100 * slope,
        "loss_delta": float(ys[-1].item() - ys[0].item()),
        "window_steps": int(xs[-1].item() - xs[0].item()),
        "points": len(points),
    }


def param_module_types(model: nn.Module) -> dict[str, str]:
    modules = dict(model.named_modules())
    out = {}
    for name, _ in model.named_parameters():
        module_name = name.rsplit(".", 1)[0] if "." in name else ""
        out[name] = modules.get(module_name, model).__class__.__name__
    return out


def grouped_by_type(named_tensors: list[tuple[str, Tensor]], module_types: dict[str, str]):
    groups: dict[str, list[tuple[str, Tensor]]] = {}
    for name, tensor in named_tensors:
        groups.setdefault(module_types[name], []).append((name, tensor))
    return groups


def sample_tensor(tensor: Tensor, max_samples: int) -> Tensor:
    values = tensor.detach().float().flatten()
    if values.numel() > max_samples:
        # Use float64 to avoid endpoint rounding past values.numel() - 1 when numel > 2**24.
        idx = torch.linspace(0, values.numel() - 1, max_samples,
                             dtype=torch.float64, device=values.device).long()
        values = values[idx]
    values = values[torch.isfinite(values)]
    return values.cpu()


def log_training_telemetry(
    model: nn.Module,
    optimizers: list[torch.optim.Optimizer],
    module_types: dict[str, str],
    train_loss: float,
    trial_idx: int,
    step: int,
    train_steps: int,
    wandb_step: int,
    pre_clip_grad_norm: Tensor | None = None,
    clip_norm: float = 0.0,
    per_group_pre_clip: dict[str, Tensor] | None = None,
):
    grads = [(name, p.grad) for name, p in model.named_parameters() if p.grad is not None]
    grad_stats = aggregate_stats(grads)
    weight_stats = aggregate_stats([(name, p.data) for name, p in model.named_parameters()])
    metrics = {
        "trial": trial_idx,
        "train/step": step,
        "train/loss": train_loss,
        "speedrun/train_steps": train_steps,
        "speedrun/target_val_loss": TARGET_VAL_LOSS,
        "train/grad/global_norm": grad_stats.get("norm", 0.0),
        "train/grad/rms": grad_stats.get("rms", 0.0),
        "train/grad/max_abs": grad_stats.get("max_abs", 0.0),
        "train/grad/nonfinite_count": grad_stats.get("nonfinite_count", 0.0),
        "train/weight/global_norm_pre_update": weight_stats.get("norm", 0.0),
    }
    if pre_clip_grad_norm is not None:
        pre_clip_val = float(pre_clip_grad_norm.item())
        metrics["train/grad/pre_clip_global_norm"] = pre_clip_val
        metrics["train/grad/clip_norm_threshold"] = clip_norm
        metrics["train/grad/clip_activated"] = int(pre_clip_val > clip_norm)
        metrics["train/grad/clip_scale_factor"] = min(1.0, clip_norm / (pre_clip_val + 1e-12))
    if per_group_pre_clip is not None and clip_norm > 0:
        for group_name, raw_norm_tensor in per_group_pre_clip.items():
            raw_val = float(raw_norm_tensor.item())
            metrics[f"train/clip_ext/per_group_grad_norm_{group_name}"] = raw_val
            metrics[f"train/clip_ext/per_group_active_{group_name}"] = int(raw_val > clip_norm)
            metrics[f"train/clip_ext/effective_aux_lr_ratio_{group_name}"] = (
                min(1.0, clip_norm / (raw_val + 1e-12))
            )
    weight_norm = weight_stats.get("norm", 0.0)
    if weight_norm:
        metrics["train/grad/grad_to_weight_norm"] = grad_stats.get("norm", 0.0) / weight_norm
    metrics.update(prefixed("train/grad/all", grad_stats))
    for opt_idx, opt in enumerate(optimizers):
        for group_idx, group in enumerate(opt.param_groups):
            group_name = group.get("name", f"optimizer_{opt_idx}_group_{group_idx}")
            metrics[f"train/lr/{group_name}"] = group["lr"]
            metrics[f"train/weight_decay/{group_name}"] = group.get("weight_decay", 0.0)
    for module_type, tensors in grouped_by_type(grads, module_types).items():
        metrics.update(prefixed(f"train/grad_type/{module_type}", aggregate_stats(tensors)))
    for name, grad in grads:
        metrics.update(prefixed(f"train/grad_param/{clean_metric_name(name)}", tensor_stats(grad)))
    wandb.log(metrics, step=wandb_step)


@torch.no_grad()
def log_adamw_step_direction(
    optimizer: torch.optim.Optimizer,
    trial_idx: int,
    step: int,
    wandb_step: int,
):
    """Per-group ||m_hat / (sqrt(v_hat) + eps)|| for AdamW.
    Bias-corrected step direction whose variance over time reflects β2 stability."""
    beta1, beta2 = optimizer.param_groups[0].get("betas", (None, None))
    eps = optimizer.param_groups[0].get("eps", 1e-10)
    metrics = {"trial": trial_idx, "train/step": step}
    if beta1 is not None and beta2 is not None:
        metrics["train/optimizer1/beta1"] = float(beta1)
        metrics["train/optimizer1/beta2"] = float(beta2)
        metrics["train/optimizer1/eps"] = float(eps)
    grand_sq = 0.0
    grand_n = 0
    for group in optimizer.param_groups:
        group_name = group.get("name", "unknown")
        group_b1, group_b2 = group.get("betas", (beta1, beta2))
        group_eps = group.get("eps", eps)
        sq_sum = 0.0
        nel = 0
        max_abs = 0.0
        for p in group["params"]:
            st = optimizer.state.get(p, {})
            if "exp_avg" not in st or "exp_avg_sq" not in st:
                continue
            t = st.get("step")
            t_val = float(t.item()) if torch.is_tensor(t) else float(t or 0)
            if t_val <= 0:
                continue
            bc1 = 1.0 - group_b1 ** t_val
            bc2 = 1.0 - group_b2 ** t_val
            m_hat = st["exp_avg"] / bc1
            v_hat = st["exp_avg_sq"] / bc2
            step_dir = m_hat / (v_hat.sqrt() + group_eps)
            sq = float((step_dir * step_dir).sum().item())
            sq_sum += sq
            nel += step_dir.numel()
            m_abs = float(step_dir.abs().max().item())
            if m_abs > max_abs:
                max_abs = m_abs
        if nel > 0:
            norm = sq_sum ** 0.5
            rms = (sq_sum / nel) ** 0.5
            metrics[f"train/optimizer1_step_dir/{group_name}_norm"] = norm
            metrics[f"train/optimizer1_step_dir/{group_name}_rms"] = rms
            metrics[f"train/optimizer1_step_dir/{group_name}_max_abs"] = max_abs
            metrics[f"train/optimizer1_step_dir/{group_name}_numel"] = nel
            grand_sq += sq_sum
            grand_n += nel
    if grand_n > 0:
        metrics["train/optimizer1_step_dir/all_norm"] = grand_sq ** 0.5
        metrics["train/optimizer1_step_dir/all_rms"] = (grand_sq / grand_n) ** 0.5
    wandb.log(metrics, step=wandb_step)


def log_weight_telemetry(
    model: nn.Module,
    module_types: dict[str, str],
    trial_idx: int,
    step: int,
    wandb_step: int,
):
    weights = [(name, p.data) for name, p in model.named_parameters()]
    weight_stats = aggregate_stats(weights)
    metrics = {
        "trial": trial_idx,
        "train/step": step,
        "train/weight/global_norm": weight_stats.get("norm", 0.0),
        "train/weight/rms": weight_stats.get("rms", 0.0),
        "train/weight/max_abs": weight_stats.get("max_abs", 0.0),
        "train/weight/nonfinite_count": weight_stats.get("nonfinite_count", 0.0),
    }
    metrics.update(prefixed("train/weight/all", weight_stats))
    for module_type, tensors in grouped_by_type(weights, module_types).items():
        metrics.update(prefixed(f"train/weight_type/{module_type}", aggregate_stats(tensors)))
    for name, weight in weights:
        metrics.update(prefixed(f"train/weight_param/{clean_metric_name(name)}", tensor_stats(weight)))
    wandb.log(metrics, step=wandb_step)


def log_histograms(
    model: nn.Module,
    trial_idx: int,
    step: int,
    wandb_step: int,
    histogram_samples: int,
    param_histogram_limit: int,
):
    metrics = {
        "trial": trial_idx,
        "train/step": step,
    }
    grad_samples = []
    weight_samples = []
    for _, p in model.named_parameters():
        if p.grad is not None:
            sample = sample_tensor(p.grad, max(1, histogram_samples // 16))
            if sample.numel() > 0:
                grad_samples.append(sample)
        sample = sample_tensor(p.data, max(1, histogram_samples // 16))
        if sample.numel() > 0:
            weight_samples.append(sample)
    if grad_samples:
        metrics["train/grad_hist/all"] = wandb.Histogram(torch.cat(grad_samples).numpy())
    if weight_samples:
        metrics["train/weight_hist/all"] = wandb.Histogram(torch.cat(weight_samples).numpy())
    largest_params = sorted(model.named_parameters(), key=lambda item: item[1].numel(), reverse=True)
    for name, p in largest_params[:param_histogram_limit]:
        clean_name = clean_metric_name(name)
        if p.grad is not None:
            sample = sample_tensor(p.grad, histogram_samples)
            if sample.numel() > 0:
                metrics[f"train/grad_hist_param/{clean_name}"] = wandb.Histogram(sample.numpy())
        sample = sample_tensor(p.data, histogram_samples)
        if sample.numel() > 0:
            metrics[f"train/weight_hist_param/{clean_name}"] = wandb.Histogram(sample.numpy())
    wandb.log(metrics, step=wandb_step)


########################################
#              Dataloader              #
########################################

def _load_data_shard(file: Path):
    header = torch.from_file(str(file), False, 256, dtype=torch.int32) # header is 256 int32
    assert header[0] == 20240520, "magic number mismatch in the data .bin file"
    assert header[1] == 1, "unsupported version"
    num_tokens = int(header[2]) # number of tokens (claimed)
    with file.open("rb", buffering=0) as f:
        tokens = torch.empty(num_tokens, dtype=torch.uint16, pin_memory=True)
        f.seek(256 * 4)
        nbytes = f.readinto(tokens.numpy()) # avoid bytes->array copy
        assert nbytes == 2 * num_tokens, "number of tokens read does not match header"
    return tokens

def distributed_data_generator(filename_pattern: str, batch_size: int, seq_len=1024):
    files = sorted(Path.cwd().glob(filename_pattern))
    assert batch_size % dist.get_world_size() == 0
    local_batch_size = batch_size // dist.get_world_size()
    file_iter = iter(files)
    tokens, pos = _load_data_shard(next(file_iter)), 0
    while True:
        if pos + batch_size + 1 >= len(tokens):
            tokens, pos = _load_data_shard(next(file_iter)), 0
        buf = tokens[pos + dist.get_rank() * local_batch_size:][:local_batch_size + 1]
        inputs = buf[:-1].to(device="cuda", dtype=torch.int32, non_blocking=True)
        targets = buf[1:].to(device="cuda", dtype=torch.int64, non_blocking=True)
        pos += batch_size
        yield inputs.view(-1, seq_len), targets.view(-1, seq_len)


########################################
#             Architecture             #
########################################

class RMSNorm(nn.Module):
    def __init__(self, dim):
        super().__init__()
        self.gains = nn.Parameter(torch.ones(dim))

    def forward(self, x):
        return F.rms_norm(x, (x.size(-1),), weight=self.gains.type_as(x))

class Linear(nn.Linear):
    def __init__(self, in_features, out_features):
        super().__init__(in_features, out_features, bias=True)

    def forward(self, x):
        return F.linear(x, self.weight.type_as(x), self.bias.type_as(x))

class Rotary(nn.Module):
    def __init__(self, dim: int):
        super().__init__()
        # half-truncate RoPE (w/ base freq tuning)
        angular_freq = (1 / 1024) ** torch.linspace(0, 1, steps=dim//4, dtype=torch.float32)
        self.register_buffer("angular_freq", torch.cat([angular_freq, angular_freq.new_zeros(dim//4)]))

    def forward(self, x_BTHD: Tensor):
        pos = torch.arange(x_BTHD.size(1), dtype=torch.float32, device=x_BTHD.device)
        theta = torch.outer(pos, self.angular_freq)[None, :, None, :]
        cos, sin = theta.cos(), theta.sin()
        x1, x2 = x_BTHD.to(dtype=torch.float32).chunk(2, dim=-1)
        y1 = x1 * cos + x2 * sin
        y2 = x1 * (-sin) + x2 * cos
        return torch.cat((y1, y2), 3).type_as(x_BTHD)

class CausalSelfAttention(nn.Module):
    def __init__(self, dim: int, head_dim=128):
        super().__init__()
        self.num_heads = dim // head_dim
        self.head_dim = head_dim
        hdim = self.num_heads * self.head_dim
        self.q = Linear(dim, hdim)
        self.k = Linear(dim, hdim)
        self.v = Linear(dim, hdim)
        self.proj = Linear(hdim, dim)
        self.rotary = Rotary(head_dim)

    def forward(self, x: Tensor):
        B, T = x.size(0), x.size(1)
        q = self.q(x).view(B, T, self.num_heads, self.head_dim)
        k = self.k(x).view(B, T, self.num_heads, self.head_dim)
        v = self.v(x).view(B, T, self.num_heads, self.head_dim)
        q, k = F.rms_norm(q, (q.size(-1),)), F.rms_norm(k, (k.size(-1),))
        q, k = self.rotary(q), self.rotary(k)
        y = F.scaled_dot_product_attention(q.transpose(1, 2), k.transpose(1, 2),
                                           v.transpose(1, 2), scale=0.12, is_causal=True).transpose(1, 2)
        y = y.contiguous().view(B, T, self.num_heads * self.head_dim)
        y = self.proj(y)
        return y

class MLP(nn.Module):
    def __init__(self, dim: int):
        super().__init__()
        hdim = 4 * dim
        self.fc = Linear(dim, hdim)
        self.proj = Linear(hdim, dim)

    def forward(self, x: Tensor):
        x = self.fc(x)
        x = x.relu().square()
        x = self.proj(x)
        return x

class Block(nn.Module):
    def __init__(self, dim: int):
        super().__init__()
        self.attn = CausalSelfAttention(dim)
        self.mlp = MLP(dim)
        self.norm1 = RMSNorm(dim)
        self.norm2 = RMSNorm(dim)

    def forward(self, x: Tensor):
        x = x + self.attn(self.norm1(x))
        x = x + self.mlp(self.norm2(x))
        return x

class GPT(nn.Module):
    def __init__(self, vocab_size: int, num_layers: int, model_dim: int):
        super().__init__()
        self.embed = nn.Embedding(vocab_size, model_dim).bfloat16()
        self.blocks = nn.ModuleList([Block(model_dim) for _ in range(num_layers)])
        self.proj = Linear(model_dim, vocab_size)
        self.norm1 = RMSNorm(model_dim)
        self.norm2 = RMSNorm(model_dim)

    def forward(self, inputs: Tensor, targets: Tensor):
        x = self.norm1(self.embed(inputs))
        for block in self.blocks:
            x = block(x)
        logits = self.proj(self.norm2(x)).float()
        logits = 15 * logits * (logits.square() + 15**2).rsqrt()
        return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")


########################################
#              Optimizer               #
########################################

NS_ITERS = int(os.environ.get("NANOGPT_NS_ITERS", "12"))
NS_ITERS_COOLDOWN = int(os.environ.get("NANOGPT_NS_ITERS_COOLDOWN", "0"))  # 0 => no schedule, use NS_ITERS throughout
NS_COOLDOWN_START_FRAC = float(os.environ.get("NANOGPT_NS_COOLDOWN_START_FRAC", "0.7"))
# Shape of NS-iter transition during cooldown window. Compute-neutral by design (mean=NS_ITERS_COOLDOWN).
#   step       -> jump to NS_ITERS_COOLDOWN at cooldown_start (baseline behavior)
#   two_stage  -> midpoint(base,cooldown) first half of cooldown, midpoint(cooldown,peak) second half
#   linear_ramp-> linear ramp from NS_ITERS to peak = NS_ITERS + 2*(COOLDOWN-NS_ITERS) across cooldown
#   late_peak  -> NS_ITERS first half of cooldown, peak second half
NS_COOLDOWN_SHAPE = os.environ.get("NANOGPT_NS_COOLDOWN_SHAPE", "step")
NANOGPT_GRAD_CLIP = float(os.environ.get("NANOGPT_GRAD_CLIP", "0.0"))
# Per-group embed cooldown shape (applies to adam_embed group only; lm_head/scalars keep linear).
# options: "linear" (baseline), "cosine", "linear_floor", "quadratic"
NANOGPT_EMBED_COOLDOWN_SHAPE = os.environ.get("NANOGPT_EMBED_COOLDOWN_SHAPE", "linear")
_VALID_EMBED_COOLDOWN_SHAPES = ("linear", "cosine", "linear_floor", "quadratic")
if NANOGPT_EMBED_COOLDOWN_SHAPE not in _VALID_EMBED_COOLDOWN_SHAPES:
    raise ValueError(
        f"NANOGPT_EMBED_COOLDOWN_SHAPE={NANOGPT_EMBED_COOLDOWN_SHAPE!r}, must be one of {_VALID_EMBED_COOLDOWN_SHAPES}"
    )
NANOGPT_ADAMW_BETA2 = float(os.environ.get("NANOGPT_ADAMW_BETA2", "0.95"))
NANOGPT_ADAMW_EMBED_LR_MULT = float(os.environ.get("NANOGPT_ADAMW_EMBED_LR_MULT", "1.0"))
NANOGPT_ADAMW_LM_HEAD_LR_MULT = float(os.environ.get("NANOGPT_ADAMW_LM_HEAD_LR_MULT", "1.0"))
NANOGPT_ADAMW_SCALAR_LR_MULT = float(os.environ.get("NANOGPT_ADAMW_SCALAR_LR_MULT", "1.0"))
NS_COEF_SCHEDULE = os.environ.get("NANOGPT_NS_COEF_SCHEDULE", "constant")
# 0.0 = disabled (default, embed WD stays at 0 throughout). Positive float = WD value
# applied to the adam_embed group during the LR cooldown window only (step function:
# 0 outside cooldown, this value inside). lm_head and scalars stay at WD=0.
NANOGPT_EMBED_WD_COOLDOWN = float(os.environ.get("NANOGPT_EMBED_WD_COOLDOWN", "0.0"))


def get_ns_coef_at_iter(iter_idx: int, total_iters: int, schedule: str) -> tuple[float, float, float]:
    """Return (a, b, c) for NS iter iter_idx of total_iters.

    One-parameter polynomial family with f(1)=1, f'(1)=0:
        a = 1.5 + c,   b = -0.5 - 2c.
    All non-control arms average c ≈ 0.5 across the iters.
    """
    if schedule == "constant":
        c = 0.5
    elif schedule == "aggressive_to_gentle":
        c_vals = [0.7, 0.7, 0.7, 0.6, 0.6, 0.5, 0.5, 0.4, 0.4, 0.3, 0.3, 0.3]
        idx = round(iter_idx * (len(c_vals) - 1) / max(total_iters - 1, 1))
        c = c_vals[idx]
    elif schedule == "gentle_to_aggressive":
        c_vals = [0.3, 0.3, 0.3, 0.4, 0.4, 0.5, 0.5, 0.6, 0.6, 0.7, 0.7, 0.7]
        idx = round(iter_idx * (len(c_vals) - 1) / max(total_iters - 1, 1))
        c = c_vals[idx]
    elif schedule == "linear_ramp_down":
        # c=0.7 at iter 0 -> c=0.28 at iter total_iters-1, avg ~= 0.49
        c = 0.7 - (0.7 - 0.28) * iter_idx / max(total_iters - 1, 1)
    else:
        c = 0.5  # fallback
    a = 1.5 + c
    b = -0.5 - 2.0 * c
    return a, b, c


_NS_COEF_TABLE_CACHE: dict[tuple[int, str], tuple[tuple[float, float, float], ...]] = {}


def get_ns_coef_table(num_iters: int) -> tuple[tuple[float, float, float], ...]:
    """Pure-Python lookup; cached so torch.compile traces inline the constants."""
    key = (num_iters, NS_COEF_SCHEDULE)
    table = _NS_COEF_TABLE_CACHE.get(key)
    if table is None:
        table = tuple(
            get_ns_coef_at_iter(k, num_iters, NS_COEF_SCHEDULE) for k in range(num_iters)
        )
        _NS_COEF_TABLE_CACHE[key] = table
    return table




def get_ns_iters(step: int, total_steps: int, ns_base: int, ns_cooldown: int,
                 start_frac: float, shape: str) -> int:
    """Compute the NS-iter count for this step under the configured cooldown shape.

    All non-'step' shapes are compute-neutral with shape='step' (mean iters across
    the cooldown window equals ns_cooldown). Outside the cooldown window all
    shapes return ns_base. If ns_cooldown<=0 the schedule is disabled.
    """
    if ns_cooldown <= 0:
        return ns_base
    boost_start = int(start_frac * total_steps)
    if step < boost_start:
        return ns_base
    cd_len = max(total_steps - boost_start, 1)
    cd_progress = (step - boost_start) / cd_len
    cd_progress = max(0.0, min(1.0, cd_progress))
    # peak value for the non-flat shapes: keeps mean=ns_cooldown over [0,1).
    peak = ns_base + 2 * (ns_cooldown - ns_base)
    if shape == "step":
        return ns_cooldown
    elif shape == "two_stage":
        low = (ns_base + ns_cooldown) // 2
        high = (ns_cooldown + peak) // 2
        return low if cd_progress < 0.5 else high
    elif shape == "linear_ramp":
        val = ns_base + cd_progress * (peak - ns_base)
        return max(ns_base, int(val + 0.5))
    elif shape == "late_peak":
        return ns_base if cd_progress < 0.5 else peak
    return ns_cooldown


def zeropower_via_newtonschulz5(G: Tensor, ns_iters: int) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT

    # Ensure spectral norm is at most 1
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    # Perform the NS iterations, not optimizing for wallclock speed
    coef_table = get_ns_coef_table(ns_iters)
    for k in range(ns_iters):
        a, b, c = coef_table[k]
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X

    if G.size(-2) > G.size(-1):
        X = X.mT
    return X

@torch.compile
def muon_update(grad, momentum, v, ns_iters: int, mu=0.95, beta2=0.999, eps=1e-8, nesterov=True):
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    # Muon^2: Adam-style second-moment preconditioning before NS (arXiv:2504.09967).
    v.mul_(beta2).addcmul_(update, update, value=1 - beta2)
    update = update / (v.sqrt() + eps)
    update = zeropower_via_newtonschulz5(update, ns_iters=ns_iters)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update

class Muon(torch.optim.Optimizer):
    def __init__(self, params, lr=0.02, weight_decay=0, mu=0.95, beta2=0.999, eps=1e-8):
        assert isinstance(params, list) and len(params) >= 1 and isinstance(params[0], torch.nn.Parameter)
        params = sorted(params, key=lambda x: x.size(), reverse=True)
        defaults = dict(lr=lr, weight_decay=weight_decay, mu=mu, beta2=beta2, eps=eps)
        super().__init__(params, defaults)
        # Step-dependent NS iteration count. Set by the training loop before each step()
        # using `set_ns_iters_this_step()`. Defaults to the static NS_ITERS env var.
        self.ns_iters_this_step = NS_ITERS
        # Optional reference to the parameter whose orthogonalized update we
        # log spectral statistics for (e.g. blocks[0].attn.q.weight). When set,
        # `step()` populates `self.spectral_stats` with svd-based metrics that
        # the training loop reads back after the optimizer step.
        self.spectral_telemetry_param: torch.nn.Parameter | None = None
        self.spectral_stats: dict[str, float] | None = None

    def set_ns_iters_this_step(self, ns_iters: int) -> None:
        self.ns_iters_this_step = int(ns_iters)

    @torch.no_grad()
    def step(self):
        world_size = dist.get_world_size()
        rank = dist.get_rank()
        ns_iters = self.ns_iters_this_step
        spectral_target = self.spectral_telemetry_param
        # Reset spectral_stats at the start of each step; only the rank that
        # owns the tracked parameter on this round-robin shard will repopulate.
        self.spectral_stats = None
        for group in self.param_groups:
            params = group["params"]
            params_pad = params + [torch.empty_like(params[-1])] * (world_size - len(params) % world_size)
            for base_i in range(0, len(params), world_size):
                if base_i + rank < len(params):
                    p = params[base_i + rank]
                    state = self.state[p]
                    if len(state) == 0:
                        state["momentum"] = torch.zeros_like(p)
                        state["v"] = torch.zeros_like(p)
                    update = muon_update(p.grad, state["momentum"], state["v"],
                                         ns_iters=ns_iters,
                                         mu=group["mu"], beta2=group["beta2"], eps=group["eps"])
                    if spectral_target is not None and p is spectral_target:
                        # Singular values of the orthogonalized (post-NS) update.
                        # Multiplied by max(1, fan_in/fan_out)**0.5 inside muon_update;
                        # divide it out so the spectrum is the pure NS output.
                        scale = max(1, p.grad.size(-2) / p.grad.size(-1))**0.5
                        u_for_svd = (update.detach().float() / scale)
                        try:
                            svals = torch.linalg.svdvals(u_for_svd)
                            self.spectral_stats = {
                                "u_singular_max": float(svals.max().item()),
                                "u_singular_min": float(svals.min().item()),
                                "u_singular_mean": float(svals.mean().item()),
                                "u_singular_range": float((svals.max() - svals.min()).item()),
                                "u_singular_std": float(svals.std(unbiased=False).item()),
                                "ns_iters_used": float(ns_iters),
                            }
                        except Exception:
                            self.spectral_stats = None
                    p.mul_(1 - group["lr"] * group["weight_decay"])
                    p.add_(update, alpha=-group["lr"])
                dist.all_gather(params_pad[base_i:base_i + world_size], params_pad[base_i + rank])


########################################
#                Setup                 #
########################################

# torchrun sets these env variables
device = torch.device("cuda", int(os.environ["LOCAL_RANK"]))
torch.cuda.set_device(device)
dist.init_process_group(backend="nccl", device_id=device)
dist.barrier()
# this code can be run equivalently with 1, 2, 4, or 8 gpus.
assert 8 % dist.get_world_size() == 0

# logging setup
if dist.get_rank() == 0:
    os.makedirs("logs", exist_ok=True)
    logfile = f"logs/{uuid.uuid4()}.txt"
    print(logfile)
def print0(s, console=False, log=True):
    if dist.get_rank() == 0:
        if console:
            print(s)
        if log:
            with open(logfile, "a") as f:
                print(s, file=f)

# we begin by logging this file itself
print0(code)
print0("="*100)
print0(f"Running PyTorch {torch.version.__version__} compiled for CUDA {torch.version.cuda}"
       + f" on {torch.cuda.get_device_name(device)} with world_size {dist.get_world_size()}")
print0(f"GRAD_CLIP: max_norm={NANOGPT_GRAD_CLIP} ({'ENABLED' if NANOGPT_GRAD_CLIP > 0 else 'DISABLED'})",
       console=True)
print0(f"EMBED_COOLDOWN_SHAPE: {NANOGPT_EMBED_COOLDOWN_SHAPE} "
       f"(applies to adam_embed only; lm_head/scalars use linear)", console=True)
print0(f"ADAMW_BETA2: {NANOGPT_ADAMW_BETA2} (effective memory ~{int(1/(1-NANOGPT_ADAMW_BETA2)) if NANOGPT_ADAMW_BETA2 < 1 else 'inf'} steps)",
       console=True)
print0(f"ADAMW_LR_MULT: embed={NANOGPT_ADAMW_EMBED_LR_MULT} lm_head={NANOGPT_ADAMW_LM_HEAD_LR_MULT} scalar={NANOGPT_ADAMW_SCALAR_LR_MULT}", console=True)
print0(f"  Effective base LRs: embed={0.3*NANOGPT_ADAMW_EMBED_LR_MULT:.4f} lm_head={(1/320)*NANOGPT_ADAMW_LM_HEAD_LR_MULT:.6f} scalar={0.01*NANOGPT_ADAMW_SCALAR_LR_MULT:.4f}", console=True)
print0(f"EMBED_WD_COOLDOWN: {NANOGPT_EMBED_WD_COOLDOWN} "
       f"({'ENABLED (adam_embed group only, step transition at cooldown start)' if NANOGPT_EMBED_WD_COOLDOWN > 0 else 'DISABLED'})",
       console=True)
if NS_ITERS_COOLDOWN > 0:
    print0(f"NS_SCHEDULE: ns_iters={NS_ITERS} -> ns_iters_cooldown={NS_ITERS_COOLDOWN} "
           f"at fraction {NS_COOLDOWN_START_FRAC} of train_steps "
           f"(shape={NS_COOLDOWN_SHAPE})", console=True)
else:
    print0(f"NS_SCHEDULE: constant ns_iters={NS_ITERS} (NS_ITERS_COOLDOWN=0, schedule disabled)",
           console=True)
print0(f"NS_COEF_SCHEDULE: {NS_COEF_SCHEDULE}", console=True)
for _probe_iters in (NS_ITERS, NS_ITERS_COOLDOWN if NS_ITERS_COOLDOWN > 0 else NS_ITERS):
    _table = get_ns_coef_table(_probe_iters)
    _c_vals = [round(t[2], 3) for t in _table]
    _avg_c = sum(t[2] for t in _table) / len(_table)
    print0(f"  ns_iters={_probe_iters}: c=[{','.join(map(str, _c_vals))}] avg_c={_avg_c:.4f}",
           console=True)
print0("="*100)

val_tokens = 20 * 524288
batch_size = 8 * 64 * 1024
mbs = 64
val_inputs, val_targets = next(distributed_data_generator("data/fineweb10B/fineweb_val_*.bin", val_tokens))

model = GPT(vocab_size=50304, num_layers=12, model_dim=768).cuda()
model.compile(dynamic=False)

module_types = param_module_types(model)
if dist.get_rank() == 0:
    tags = ["track-3-optimization", "senpai"] + args.wandb_tags
    if os.environ.get("RESEARCH_TAG"):
        tags.append(os.environ["RESEARCH_TAG"])
    if os.environ.get("STUDENT_NAME"):
        tags.append(f"student:{os.environ['STUDENT_NAME']}")
    wandb.init(
        entity=args.wandb_entity or None,
        project=args.wandb_project,
        name=args.wandb_name or None,
        group=args.wandb_group or os.environ.get("RESEARCH_TAG") or None,
        tags=tags,
        mode=args.wandb_mode,
        config={
            "benchmark": "modded-nanogpt-track-3-optimization",
            "target_val_loss": TARGET_VAL_LOSS,
            "stat_sig_delta": STAT_SIG_DELTA,
            "num_trials": args.num_trials,
            "world_size": dist.get_world_size(),
            "batch_size_tokens": batch_size,
            "microbatch_sequences": mbs,
            "val_tokens": val_tokens,
            "telemetry_interval": args.telemetry_interval,
            "histogram_interval": args.histogram_interval,
            "histogram_samples": args.histogram_samples,
            "param_histogram_limit": args.param_histogram_limit,
            "slope_fraction": SLOPE_FRACTION,
            "nanogpt_grad_clip": NANOGPT_GRAD_CLIP,
            "nanogpt_ns_iters": NS_ITERS,
            "nanogpt_ns_iters_cooldown": NS_ITERS_COOLDOWN,
            "nanogpt_ns_cooldown_start_frac": NS_COOLDOWN_START_FRAC,
            "nanogpt_ns_cooldown_shape": NS_COOLDOWN_SHAPE,
            "nanogpt_embed_cooldown_shape": NANOGPT_EMBED_COOLDOWN_SHAPE,
            "nanogpt_adamw_beta2": NANOGPT_ADAMW_BETA2,
            "nanogpt_adamw_embed_lr_mult": NANOGPT_ADAMW_EMBED_LR_MULT,
            "nanogpt_adamw_lm_head_lr_mult": NANOGPT_ADAMW_LM_HEAD_LR_MULT,
            "nanogpt_adamw_scalar_lr_mult": NANOGPT_ADAMW_SCALAR_LR_MULT,
            "nanogpt_ns_coef_schedule": NS_COEF_SCHEDULE,
            "nanogpt_embed_wd_cooldown": NANOGPT_EMBED_WD_COOLDOWN,
        },
    )

for trial_idx in range(args.num_trials):


    ########################################
    #       Init & Optim Hyperparams       #
    ########################################

    # we want to minimize this while still reaching 3.28 val loss
    train_steps = int(os.environ.get("NANOGPT_TRAIN_STEPS", "3350"))

    # initialize model parameters
    for name, p in model.named_parameters():
        w = p.data
        if name.endswith("weight"):
            if "proj" in name:
                w.zero_()
            elif "embed" in name:
                w.normal_()  # default torch init
            else:
                w.normal_(std=0.33**0.5 / w.size(-1)**0.5)  # default torch init
        elif name.endswith("bias"):
            w.zero_()
        elif name.endswith("gains"):
            w.normal_(mean=1, std=0)
        else:
            raise Exception(f"Uninitialized parameter: {name}")

    # create the optimizer(s)
    optimizer1 = AdamW([dict(params=[model.embed.weight], lr=0.3 * NANOGPT_ADAMW_EMBED_LR_MULT, name="adam_embed"),
                        dict(params=[model.proj.weight], lr=(1/320) * NANOGPT_ADAMW_LM_HEAD_LR_MULT, name="adam_lm_head"),
                        dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.01 * NANOGPT_ADAMW_SCALAR_LR_MULT, name="adam_scalars")],
                       betas=(0.8, NANOGPT_ADAMW_BETA2), eps=1e-10, weight_decay=0, fused=True)
    optimizer2 = Muon([p for p in model.blocks.parameters() if p.ndim >= 2],
                      lr=0.035, weight_decay=0.025)
    optimizer2.param_groups[0]["name"] = "muon_blocks"
    # Track orthogonalized-update spectrum on first block's attention q.weight
    # to surface NS-schedule effects in W&B telemetry.
    optimizer2.spectral_telemetry_param = model.blocks[0].attn.q.weight
    cooldown_start_step = int(train_steps * NS_COOLDOWN_START_FRAC)
    ns_iters_history: list[int] = []
    ns_cumulative_iters = 0
    optimizers = [optimizer1, optimizer2]
    assert set(p for opt in optimizers for group in opt.param_groups
               for p in group["params"]) == set(model.parameters())
    for opt in optimizers:
        for group in opt.param_groups:
            group["initial_lr"] = group["lr"]

    # learning rate schedule: stable then decay.
    # All groups follow the default linear-to-zero cooldown except the
    # adam_embed group, which can be remapped via NANOGPT_EMBED_COOLDOWN_SHAPE.
    def set_hparams(step, cooldown_frac=0.7):
        progress = step / train_steps
        assert 0 <= progress < 1
        in_cooldown = progress >= (1 - cooldown_frac)
        if not in_cooldown:
            eta_default = 1.0
            eta_embed = 1.0
        else:
            eta_default = (1 - progress) / cooldown_frac
            cooldown_progress = 1.0 - eta_default  # 0 at cooldown start, 1 at end
            if NANOGPT_EMBED_COOLDOWN_SHAPE == "linear":
                eta_embed = eta_default
            elif NANOGPT_EMBED_COOLDOWN_SHAPE == "cosine":
                eta_embed = 0.5 * (1.0 + math.cos(math.pi * cooldown_progress))
            elif NANOGPT_EMBED_COOLDOWN_SHAPE == "linear_floor":
                eta_embed = 0.15 + 0.85 * eta_default  # decays from 1.0 to 0.15
            elif NANOGPT_EMBED_COOLDOWN_SHAPE == "quadratic":
                eta_embed = eta_default ** 2
            else:
                raise ValueError(f"unknown shape: {NANOGPT_EMBED_COOLDOWN_SHAPE}")
        # Step-function WD on the adam_embed group: 0 outside cooldown, target inside.
        # Disabled when NANOGPT_EMBED_WD_COOLDOWN == 0 (baseline path: WD stays 0 throughout).
        embed_wd = NANOGPT_EMBED_WD_COOLDOWN if (in_cooldown and NANOGPT_EMBED_WD_COOLDOWN > 0) else 0.0
        for opt in optimizers:
            for group in opt.param_groups:
                if group.get("name") == "adam_embed":
                    group["lr"] = group["initial_lr"] * eta_embed
                    group["weight_decay"] = embed_wd
                else:
                    group["lr"] = group["initial_lr"] * eta_default


    ########################################
    #        Training and Validation       #
    ########################################

    train_loader = distributed_data_generator("data/fineweb10B/fineweb_train_*.bin", batch_size)
    for p in model.parameters():
        dist.broadcast(p.detach(), 0)
    # start the clock
    training_time = 0
    last_val_step = 0
    best_val_loss = float("inf")
    best_val_step = -1
    first_step_to_target = -1
    slope_interval = max(1, round(train_steps * SLOPE_FRACTION))
    slope_window_steps = max(100, slope_interval)
    train_loss_history: list[tuple[int, float]] = []
    val_loss_history: list[tuple[int, float]] = []
    dist.barrier()
    t0 = time.perf_counter()
    for step in range(train_steps + 1):

        # --------------- VALIDATION SECTION -----------------
        val_step_freq = 125 if step / train_steps < 0.9 else 25
        if step == train_steps or step % val_step_freq == 0:
            # stop the clock
            dist.barrier()
            time_since_last_val = time.perf_counter() - t0
            step_avg = time_since_last_val / (step - last_val_step) if step > 0 else float("nan")
            last_val_step = step
            training_time += time_since_last_val
            model.eval()
            val_loss = torch.zeros((), device=device)
            with torch.no_grad():
                assert len(val_inputs) % mbs == 0
                for i in range(len(val_inputs) // mbs):
                    val_loss += model(val_inputs[i*mbs:(i+1)*mbs], val_targets[i*mbs:(i+1)*mbs])
            dist.all_reduce(val_loss, op=dist.ReduceOp.SUM)
            val_loss /= val_tokens
            val_loss_float = float(val_loss.item())
            if dist.get_rank() == 0:
                val_loss_history.append((step, val_loss_float))
                if val_loss_float < best_val_loss:
                    best_val_loss = val_loss_float
                    best_val_step = step
                if first_step_to_target < 0 and val_loss_float <= TARGET_VAL_LOSS:
                    first_step_to_target = step
                metrics = {
                    "trial": trial_idx,
                    "val/step": step,
                    "val/loss": val_loss_float,
                    "val/best_loss": best_val_loss,
                    "val/best_step": best_val_step,
                    "val/target_margin": TARGET_VAL_LOSS - val_loss_float,
                    "val/single_run_stat_sig_margin": TARGET_VAL_LOSS - val_loss_float - STAT_SIG_DELTA,
                    "speedrun/first_step_to_target": first_step_to_target,
                    "speedrun/reached_target": int(first_step_to_target >= 0),
                    "time/train_seconds": training_time,
                    "time/step_avg_ms": 1000 * step_avg,
                }
                metrics.update(prefixed("val/slope", loss_slope_stats(val_loss_history, slope_window_steps)))
                wandb.log(metrics, step=trial_idx * (train_steps + 1) + step)
            print0(f"step:{step}/{train_steps} val_loss:{val_loss:.5f} train_time:{training_time:.3f}s"
                   + f" step_avg:{1000*step_avg:.2f}ms", console=True)
            model.train()
            # start the clock again
            dist.barrier()
            t0 = time.perf_counter()

        if step == train_steps:
            break

        # --------------- TRAINING SECTION -----------------
        inputs, targets = next(train_loader)
        # accumulate across microbatches in case we are running with fewer than 8 gpus
        assert len(inputs) % mbs == 0
        step_loss = torch.zeros((), device=device)
        for i in range(len(inputs) // mbs):
            loss = model(inputs[i*mbs:(i+1)*mbs], targets[i*mbs:(i+1)*mbs])
            step_loss += loss.detach()
            loss.backward()
        for name, p in model.named_parameters():
            assert p.grad is not None, name
            dist.all_reduce(p.grad, op=dist.ReduceOp.SUM)
        if NANOGPT_GRAD_CLIP > 0:
            # Capture per-AdamW-aux-group raw gradient norms BEFORE the global clip
            # rescales them in place. Mechanism: under global clip the scale factor is
            # min(1, clip_norm / global_norm); these per-group norms tell us where each
            # group sits relative to the threshold (effective_aux_lr_ratio).
            per_group_pre_clip = {
                "embed": model.embed.weight.grad.detach().norm(),
                "lmhead": model.proj.weight.grad.detach().norm(),
            }
            pre_clip_grad_norm = torch.nn.utils.clip_grad_norm_(
                model.parameters(), max_norm=NANOGPT_GRAD_CLIP)
        else:
            pre_clip_grad_norm = None
            per_group_pre_clip = None
        dist.all_reduce(step_loss, op=dist.ReduceOp.SUM)
        train_loss = float((step_loss / batch_size).item())
        # set optimization hyperparameters and take a step
        set_hparams(step)
        train_step = step + 1
        telemetry_due = (step == 0 or (step + 1) % args.telemetry_interval == 0 or step + 1 == train_steps)
        histogram_due = (step == 0 or (step + 1) % args.histogram_interval == 0 or step + 1 == train_steps)
        slope_due = (train_step % slope_interval == 0 or train_step == train_steps)
        wandb_step = trial_idx * (train_steps + 1) + train_step
        if dist.get_rank() == 0:
            train_loss_history.append((train_step, train_loss))
        if dist.get_rank() == 0 and slope_due:
            slope_metrics = {
                "trial": trial_idx,
                "train/step": train_step,
                "train/slope/window_target_steps": slope_window_steps,
            }
            slope_metrics.update(prefixed("train/slope", loss_slope_stats(train_loss_history, slope_window_steps)))
            wandb.log(slope_metrics, step=wandb_step)
        if dist.get_rank() == 0 and telemetry_due:
            log_training_telemetry(
                model=model,
                optimizers=optimizers,
                module_types=module_types,
                train_loss=train_loss,
                trial_idx=trial_idx,
                step=train_step,
                train_steps=train_steps,
                wandb_step=wandb_step,
                pre_clip_grad_norm=pre_clip_grad_norm,
                clip_norm=NANOGPT_GRAD_CLIP,
                per_group_pre_clip=per_group_pre_clip,
            )
        # NS iteration schedule: cooldown shape controls how iters evolve during
        # the last (1 - NS_COOLDOWN_START_FRAC) fraction of training. shape='step'
        # is the legacy jump-to-cooldown behavior; other shapes are compute-neutral.
        ns_iters_this_step = get_ns_iters(
            step, train_steps, NS_ITERS, NS_ITERS_COOLDOWN,
            NS_COOLDOWN_START_FRAC, NS_COOLDOWN_SHAPE,
        )
        optimizer2.set_ns_iters_this_step(ns_iters_this_step)
        if dist.get_rank() == 0:
            ns_iters_history.append(ns_iters_this_step)
            if len(ns_iters_history) > 100:
                del ns_iters_history[:-100]
            ns_cumulative_iters += ns_iters_this_step
        for opt in optimizers:
            opt.step()
        # Per-100-step embed AdamW step-direction norm ||m_hat / (sqrt(v_hat) + eps)||.
        # This is the *direction* (pre-LR) so it captures whether the schedule change
        # is modulating the bias-corrected Adam update magnitude on the embed group.
        embed_step_due = (train_step % 100 == 0 or train_step == train_steps)
        if dist.get_rank() == 0 and embed_step_due:
            with torch.no_grad():
                embed_state = optimizer1.state.get(model.embed.weight, {})
                if "exp_avg" in embed_state and "exp_avg_sq" in embed_state:
                    embed_group = next(
                        g for g in optimizer1.param_groups if g.get("name") == "adam_embed"
                    )
                    beta1, beta2 = embed_group["betas"]
                    eps = embed_group["eps"]
                    raw_step = embed_state.get("step", 0)
                    step_count = float(raw_step.item() if torch.is_tensor(raw_step) else raw_step)
                    if step_count > 0:
                        bias1 = 1.0 - beta1 ** step_count
                        bias2 = 1.0 - beta2 ** step_count
                        m_hat = embed_state["exp_avg"].to(torch.float32) / bias1
                        v_hat = embed_state["exp_avg_sq"].to(torch.float32) / bias2
                        adam_step = m_hat / (v_hat.sqrt() + eps)
                        embed_step_norm = float(adam_step.norm().item())
                        embed_step_rms = float(adam_step.square().mean().sqrt().item())
                        wandb.log({
                            "trial": trial_idx,
                            "train/step": train_step,
                            "train/embed_schedule/adam_step_norm": embed_step_norm,
                            "train/embed_schedule/adam_step_rms": embed_step_rms,
                            "train/embed_schedule/lr_embed": embed_group["lr"],
                            "train/embed_schedule/wd_embed": embed_group["weight_decay"],
                            "train/embed_schedule/adam_steps_taken": step_count,
                        }, step=wandb_step)
        adamw_step_dir_due = (train_step % 100 == 0 or train_step == train_steps)
        if dist.get_rank() == 0 and adamw_step_dir_due:
            log_adamw_step_direction(
                optimizer=optimizer1,
                trial_idx=trial_idx,
                step=train_step,
                wandb_step=wandb_step,
            )
        if dist.get_rank() == 0 and telemetry_due:
            ns_metrics = {
                "trial": trial_idx,
                "train/step": train_step,
                "train/ns_schedule/iters_this_step": ns_iters_this_step,
                "train/ns_schedule/iters_avg_last_100_steps": (
                    sum(ns_iters_history) / max(1, len(ns_iters_history))
                ),
                "train/ns_schedule/cooldown_start_step": cooldown_start_step,
                "train/ns_schedule/in_cooldown": int(
                    NS_ITERS_COOLDOWN > 0 and step >= cooldown_start_step
                ),
                "train/ns_schedule/cumulative_iters": ns_cumulative_iters,
            }
            if optimizer2.spectral_stats is not None:
                for k, v in optimizer2.spectral_stats.items():
                    ns_metrics[f"train/ns_schedule/{k}"] = v
            # Per-iter NS coefficient telemetry (probes 3 representative iters).
            current_ns_iters = ns_iters_this_step
            a0, b0, c0 = get_ns_coef_at_iter(0, current_ns_iters, NS_COEF_SCHEDULE)
            a_mid, b_mid, c_mid = get_ns_coef_at_iter(
                current_ns_iters // 2, current_ns_iters, NS_COEF_SCHEDULE
            )
            a_last, b_last, c_last = get_ns_coef_at_iter(
                current_ns_iters - 1, current_ns_iters, NS_COEF_SCHEDULE
            )
            full_c = [
                get_ns_coef_at_iter(i, current_ns_iters, NS_COEF_SCHEDULE)[2]
                for i in range(current_ns_iters)
            ]
            ns_metrics.update({
                "train/ns/c_at_iter_0": c0,
                "train/ns/c_at_iter_mid": c_mid,
                "train/ns/c_at_iter_last": c_last,
                "train/ns/avg_c": sum(full_c) / len(full_c),
                "train/ns/a_at_iter_0": a0,
                "train/ns/b_at_iter_0": b0,
                "train/ns/a_at_iter_last": a_last,
                "train/ns/b_at_iter_last": b_last,
                "train/ns/schedule_id": {
                    "constant": 0,
                    "aggressive_to_gentle": 1,
                    "gentle_to_aggressive": 2,
                    "linear_ramp_down": 3,
                }.get(NS_COEF_SCHEDULE, -1),
            })
            wandb.log(ns_metrics, step=wandb_step)
        if dist.get_rank() == 0 and telemetry_due:
            log_weight_telemetry(
                model=model,
                module_types=module_types,
                trial_idx=trial_idx,
                step=train_step,
                wandb_step=wandb_step,
            )
        if dist.get_rank() == 0 and histogram_due:
            log_histograms(
                model=model,
                trial_idx=trial_idx,
                step=train_step,
                wandb_step=wandb_step,
                histogram_samples=args.histogram_samples,
                param_histogram_limit=args.param_histogram_limit,
            )
        model.zero_grad(set_to_none=True)
        approx_training_time = training_time + (time.perf_counter() - t0)
        print0(f"step:{step+1}/{train_steps} train_time:{approx_training_time:.3f}s"
               + f" step_avg:{1000*approx_training_time/(step + 1):.2f}ms", console=True, log=False)

    if dist.get_rank() == 0:
        print0(
            f"trial:{trial_idx} best_val_loss:{best_val_loss:.5f} best_val_step:{best_val_step}"
            + f" first_step_to_target:{first_step_to_target}",
            console=True,
        )
        wandb.log({
            "trial": trial_idx,
            "speedrun/final_best_val_loss": best_val_loss,
            "speedrun/final_best_val_step": best_val_step,
            "speedrun/final_first_step_to_target": first_step_to_target,
            "speedrun/final_reached_target": int(first_step_to_target >= 0),
        }, step=(trial_idx + 1) * (train_steps + 1) - 1)

if dist.get_rank() == 0:
    wandb.finish()
dist.destroy_process_group()
