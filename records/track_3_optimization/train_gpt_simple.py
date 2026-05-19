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
    parser.add_argument("--muonh_budget_mult", type=float, default=float(os.environ.get("MUONH_BUDGET_MULT", "1.0")))
    parser.add_argument("--muonh_lr", type=float, default=float(os.environ.get("MUONH_LR", "0.018")))
    parser.add_argument("--muonh_mode", type=str, default=os.environ.get("MUONH_MODE", "clip"), choices=["clip", "scale_invariant"])
    parser.add_argument("--muonh_cooldown_shape", type=str, default=os.environ.get("MUONH_COOLDOWN_SHAPE", "linear"), choices=["linear", "cosine", "sqrt"], help="LR cooldown shape for MuonH groups (AdamW aux groups stay linear)")
    parser.add_argument("--muonh_warmup_steps", type=int, default=int(os.environ.get("MUONH_WARMUP_STEPS", "0")), help="Linear LR warmup steps for MuonH groups only (0 = disabled, no-op vs baseline). AdamW aux groups are not warmed.")
    parser.add_argument("--train_steps", type=int, default=int(os.environ.get("TRAIN_STEPS", "3350")))
    # MuLoCo outer Nesterov SGD (Algorithm 1, K=1). Wraps all trainable params;
    # snapshots an anchor at trial start, then every sync_interval inner steps
    # computes delta = anchor - p, integrates Nesterov velocity, and steps the
    # model toward anchor - lr*(mu*v + delta). Inner optimizer state is NOT reset.
    parser.add_argument("--use_outer_optimizer", type=int, default=int(os.environ.get("USE_OUTER_OPTIMIZER", "1")))
    parser.add_argument("--outer_lr", type=float, default=float(os.environ.get("OUTER_LR", "0.7")))
    parser.add_argument("--outer_momentum", type=float, default=float(os.environ.get("OUTER_MOMENTUM", "0.5")))
    parser.add_argument("--sync_interval", type=int, default=int(os.environ.get("SYNC_INTERVAL", "30")))
    # AGC (Brock et al. 2021): per-parameter adaptive gradient clipping applied to
    # AdamW aux groups (embed, lm_head, scalars). Clips grad to clip_ratio * |param|.
    # Default 0.0 disables (no-op for bit-identical baseline).
    parser.add_argument("--aux_agc_clip_ratio", type=float, default=float(os.environ.get("AUX_AGC_CLIP_RATIO", "0.0")))
    parser.add_argument("--aux_agc_eps", type=float, default=float(os.environ.get("AUX_AGC_EPS", "1e-3")))
    # Inner-MuonH AGC: clip the reduced gradient on MuonH block params BEFORE the
    # momentum buffer integrates it. Same per-param formula as aux AGC (the L2
    # norm and RMS formulations are equivalent because the sqrt(n) cancels in
    # the ratio). Default 0.0 keeps the MuonH inner path bit-identical.
    parser.add_argument("--muonh_agc_clip_ratio", type=float, default=float(os.environ.get("MUONH_AGC_CLIP_RATIO", "0.0")),
                        help="If > 0, apply AGC to inner MuonH gradient BEFORE momentum buffer. "
                             "Same formula as aux AGC: clip_scale = min(1, ratio * param_norm / grad_norm). "
                             "0.0 = disabled (default).")
    parser.add_argument("--muonh_agc_eps", type=float, default=float(os.environ.get("MUONH_AGC_EPS", "1e-3")))
    # NS5 Newton-Schulz polynomial coefficients (default = current hardcoded values).
    # σ_new = σ * (a + b*σ² + c*σ⁴). Default (2, -1.5, 0.5) has fixed points at σ=1 and σ=√2.
    # Classical NS quintic (1.875, -1.25, 0.375) and sharper (2.5, -2.0, 0.5) both have unique FP at σ=1.
    parser.add_argument("--ns5_a", type=float, default=float(os.environ.get("NS5_A", "2.0")),
                        help="NS5 polynomial coefficient a (linear term). Default: 2.0")
    parser.add_argument("--ns5_b", type=float, default=float(os.environ.get("NS5_B", "-1.5")),
                        help="NS5 polynomial coefficient b (cubic term). Default: -1.5")
    parser.add_argument("--ns5_c", type=float, default=float(os.environ.get("NS5_C", "0.5")),
                        help="NS5 polynomial coefficient c (quintic term). Default: 0.5")
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
    n = values.numel()
    if n > max_samples:
        # float64 + clamp: float32 linspace endpoint rounds up for n > ~2^24 (e.g. embed.weight),
        # producing an OOB index that trips IndexKernel.cu at step 0 in log_histograms.
        idx = torch.linspace(0, n - 1, max_samples, dtype=torch.float64, device=values.device).long()
        idx.clamp_(0, n - 1)
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

def zeropower_via_newtonschulz5(G: Tensor, a: float = 2.0, b: float = -1.5, c: float = 0.5) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT

    # Ensure spectral norm is at most 1
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    # Perform the NS iterations, not optimizing for wallclock speed
    for _ in range(12):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X

    if G.size(-2) > G.size(-1):
        X = X.mT
    return X

@torch.compile
def muon_update(grad, momentum, mu=0.95, nesterov=True,
                a: float = 2.0, b: float = -1.5, c: float = 0.5):
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    update = zeropower_via_newtonschulz5(update, a=a, b=b, c=c)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update


@torch.no_grad()
def compute_ns5_sigma_telemetry(grad, momentum, mu, a, b, c, nesterov=True):
    """Measure max σ before and after NS5 on a single param. Runs on clones so
    the actual training state is unaffected. Called only at telemetry steps."""
    m = momentum.clone()
    g = grad.clone()
    m.lerp_(g, 1 - mu)
    update = g.lerp_(m, mu) if nesterov else m
    X = update.bfloat16()
    if X.size(-2) > X.size(-1):
        X = X.mT
    X_in = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    input_max_sigma = float(torch.linalg.matrix_norm(X_in.float(), ord=2).item())
    out = zeropower_via_newtonschulz5(update, a=a, b=b, c=c)
    output_max_sigma = float(torch.linalg.matrix_norm(out.float(), ord=2).item())
    return input_max_sigma, output_max_sigma


class Muon(torch.optim.Optimizer):
    def __init__(self, params, lr=0.02, weight_decay=0, mu=0.95):
        assert isinstance(params, list) and len(params) >= 1 and isinstance(params[0], torch.nn.Parameter)
        params = sorted(params, key=lambda x: x.size(), reverse=True)
        defaults = dict(lr=lr, weight_decay=weight_decay, mu=mu)
        super().__init__(params, defaults)

    @torch.no_grad()
    def step(self):
        world_size = dist.get_world_size()
        rank = dist.get_rank()
        for group in self.param_groups:
            params = group["params"]
            params_pad = params + [torch.empty_like(params[-1])] * (world_size - len(params) % world_size)
            for base_i in range(0, len(params), world_size):
                if base_i + rank < len(params):
                    p = params[base_i + rank]
                    state = self.state[p]
                    if len(state) == 0:
                        state["momentum"] = torch.zeros_like(p)
                    update = muon_update(p.grad, state["momentum"], mu=group["mu"],
                                         a=args.ns5_a, b=args.ns5_b, c=args.ns5_c)
                    p.mul_(1 - group["lr"] * group["weight_decay"])
                    p.add_(update, alpha=-group["lr"])
                dist.all_gather(params_pad[base_i:base_i + world_size], params_pad[base_i + rank])


@torch.no_grad()
def adaptive_gradient_clip(parameters, clip_ratio: float, eps: float = 1e-3):
    """Per-tensor AGC (Brock et al. 2021).

    For each param p, scale its grad in-place if ||g|| exceeds clip_ratio * max(||p||, eps).
    Returns telemetry: total params seen, count clipped, max pre-clip g_to_clip_threshold ratio,
    plus the applied-scale min and mean across all tracked params (1.0 when no clip fires).
    No-op (and bit-identical) when clip_ratio <= 0.
    """
    stats = {
        "agc_total": 0,
        "agc_clipped": 0,
        "agc_max_ratio": 0.0,
        "agc_scale_min": 1.0,
        "agc_scale_mean": 1.0,
    }
    if clip_ratio <= 0:
        return stats
    max_ratio = 0.0
    scale_min = 1.0
    scale_sum = 0.0
    for p in parameters:
        if p.grad is None:
            continue
        stats["agc_total"] += 1
        p_norm = p.data.norm(2).clamp_min(eps)
        g_norm = p.grad.norm(2)
        max_g = clip_ratio * p_norm
        # Per-param ratio of g_norm to its allowed max (>1 means clipping fires).
        ratio = float((g_norm / max_g.clamp_min(1e-30)).item())
        if ratio > max_ratio:
            max_ratio = ratio
        if ratio > 1.0:
            scale = float((max_g / g_norm.clamp_min(1e-30)).item())
            p.grad.mul_(max_g / g_norm.clamp_min(1e-30))
            stats["agc_clipped"] += 1
        else:
            scale = 1.0
        if scale < scale_min:
            scale_min = scale
        scale_sum += scale
    stats["agc_max_ratio"] = max_ratio
    if stats["agc_total"] > 0:
        stats["agc_scale_min"] = scale_min
        stats["agc_scale_mean"] = scale_sum / stats["agc_total"]
    return stats


def scale_invariant_update_(param, update, lr, eps=1e-10):
    """Always-active hyperball step: rescale update to param's current norm scale,
    take the step, then renormalise the result back onto the sphere of radius
    ||initial param||. Holds Frobenius norm exactly constant across training."""
    p_norm = param.norm()
    u_norm = update.norm()
    new_param = param - lr * update * p_norm / torch.clamp(u_norm, min=eps)
    new_norm = torch.clamp(new_param.norm(), min=eps)
    param.copy_(new_param / new_norm * p_norm)


class MuonH(torch.optim.Optimizer):
    """Muon with a hyperball (Frobenius-ball) projection on hidden 2D weight matrices.

    mode="clip": after the regular Muon step, project the parameter back into a
    ball of radius R = (initial Frobenius norm) * budget_mult only when the norm
    exceeds R. The projection replaces weight decay as the implicit regularizer.

    mode="scale_invariant": always-active variant from the bundled reference -
    rescale the update to the param's current norm scale, then renormalise the
    new param back onto the sphere of radius ||initial param||. Holds Frobenius
    norm exactly constant; weight_decay must be 0.
    """
    def __init__(self, params, lr=0.018, weight_decay=0.0, mu=0.95,
                 hyperball=True, budget_mult=1.0, mode="clip"):
        assert isinstance(params, list) and len(params) >= 1 and isinstance(params[0], torch.nn.Parameter)
        assert mode in ("clip", "scale_invariant")
        params = sorted(params, key=lambda x: x.size(), reverse=True)
        defaults = dict(lr=lr, weight_decay=weight_decay, mu=mu,
                        hyperball=hyperball, budget_mult=budget_mult, mode=mode)
        super().__init__(params, defaults)
        self._last_active_fraction = 0.0
        self._last_radius_to_norm_max = 0.0
        self._last_norm_to_radius_max = 0.0

    @torch.no_grad()
    def step(self):
        world_size = dist.get_world_size()
        rank = dist.get_rank()
        clip_count_local = 0
        total_count_local = 0
        max_r_over_n_local = 0.0
        max_n_over_r_local = 0.0
        for group in self.param_groups:
            params = group["params"]
            params_pad = params + [torch.empty_like(params[-1])] * (world_size - len(params) % world_size)
            hb = group["hyperball"]
            budget_mult = group["budget_mult"]
            mode = group["mode"]
            for base_i in range(0, len(params), world_size):
                if base_i + rank < len(params):
                    p = params[base_i + rank]
                    state = self.state[p]
                    if len(state) == 0:
                        state["momentum"] = torch.zeros_like(p)
                        if hb:
                            state["hyperball_radius"] = p.data.norm().item() * budget_mult
                    update = muon_update(p.grad, state["momentum"], mu=group["mu"],
                                         a=args.ns5_a, b=args.ns5_b, c=args.ns5_c)
                    if hb and mode == "scale_invariant":
                        # Always-active variant: norm is held at initial value by construction.
                        scale_invariant_update_(p.data, update, group["lr"])
                        total_count_local += 1
                        clip_count_local += 1  # by definition projection is always active
                    else:
                        p.mul_(1 - group["lr"] * group["weight_decay"])
                        p.add_(update, alpha=-group["lr"])
                        if hb:
                            R = state["hyperball_radius"]
                            norm = p.data.norm().item()
                            total_count_local += 1
                            if R > 0:
                                r_over_n = R / max(norm, 1e-30)
                                n_over_r = norm / R
                                if r_over_n > max_r_over_n_local:
                                    max_r_over_n_local = r_over_n
                                if n_over_r > max_n_over_r_local:
                                    max_n_over_r_local = n_over_r
                            if norm > R:
                                p.data.mul_(R / norm)
                                clip_count_local += 1
                dist.all_gather(params_pad[base_i:base_i + world_size], params_pad[base_i + rank])
        if world_size > 1:
            counts = torch.tensor([clip_count_local, total_count_local],
                                  device="cuda", dtype=torch.float64)
            dist.all_reduce(counts, op=dist.ReduceOp.SUM)
            ratios = torch.tensor([max_r_over_n_local, max_n_over_r_local],
                                  device="cuda", dtype=torch.float64)
            dist.all_reduce(ratios, op=dist.ReduceOp.MAX)
            clip_count = float(counts[0].item())
            total_count = float(counts[1].item())
            max_r_over_n = float(ratios[0].item())
            max_n_over_r = float(ratios[1].item())
        else:
            clip_count = float(clip_count_local)
            total_count = float(total_count_local)
            max_r_over_n = max_r_over_n_local
            max_n_over_r = max_n_over_r_local
        self._last_active_fraction = clip_count / total_count if total_count > 0 else 0.0
        self._last_radius_to_norm_max = max_r_over_n
        self._last_norm_to_radius_max = max_n_over_r


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
if args.use_outer_optimizer:
    print0(f"MuLoCo outer optimizer ENABLED: outer_lr={args.outer_lr} "
           f"outer_momentum={args.outer_momentum} sync_interval={args.sync_interval}", console=True)
else:
    print0("MuLoCo outer optimizer DISABLED", console=True)
print0(f"MuonH mode={args.muonh_mode} lr={args.muonh_lr} budget_mult={args.muonh_budget_mult} cooldown_shape={args.muonh_cooldown_shape}", console=True)
if args.aux_agc_clip_ratio > 0:
    print0(f"AGC ENABLED on aux AdamW groups: clip_ratio={args.aux_agc_clip_ratio} eps={args.aux_agc_eps}", console=True)
else:
    print0("AGC DISABLED on aux AdamW groups (clip_ratio=0)", console=True)
if args.muonh_agc_clip_ratio > 0:
    print0(f"AGC ENABLED on inner MuonH gradient: clip_ratio={args.muonh_agc_clip_ratio} eps={args.muonh_agc_eps}", console=True)
else:
    print0("AGC DISABLED on inner MuonH gradient (clip_ratio=0)", console=True)
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
            "muonh_budget_mult": args.muonh_budget_mult,
            "muonh_lr": args.muonh_lr,
            "muonh_mode": args.muonh_mode,
            "muonh_cooldown_shape": args.muonh_cooldown_shape,
            "muonh_warmup_steps": args.muonh_warmup_steps,
            "train_steps": args.train_steps,
            "muloco_use_outer_optimizer": bool(args.use_outer_optimizer),
            "muloco_outer_lr": args.outer_lr,
            "muloco_outer_momentum": args.outer_momentum,
            "muloco_sync_interval": args.sync_interval,
            "aux_agc_clip_ratio": args.aux_agc_clip_ratio,
            "aux_agc_eps": args.aux_agc_eps,
            "muonh_agc_clip_ratio": args.muonh_agc_clip_ratio,
            "muonh_agc_eps": args.muonh_agc_eps,
            "ns5_a": args.ns5_a,
            "ns5_b": args.ns5_b,
            "ns5_c": args.ns5_c,
        },
    )

for trial_idx in range(args.num_trials):


    ########################################
    #       Init & Optim Hyperparams       #
    ########################################

    # we want to minimize this while still reaching 3.28 val loss
    train_steps = args.train_steps

    # Per-module init std: gives MuonH non-zero matrices to operate on from step 0
    # while keeping the LM head (model.proj.weight) at zero so initial logits are 0.
    # The "proj" substring matches both block proj weights and the LM head, so the
    # LM head is special-cased by exact-name first.
    for name, p in model.named_parameters():
        w = p.data
        if name.endswith("weight"):
            if name == "proj.weight":
                w.zero_()  # LM head: keep zero like starter
            elif name == "embed.weight":
                w.normal_()  # token embedding: default torch init
            elif "attn.proj" in name:
                w.normal_(std=0.026)
            elif "mlp.proj" in name:
                w.normal_(std=0.031)
            elif "mlp.fc" in name:
                w.normal_(std=0.031)
            elif "attn." in name:
                w.normal_(std=0.33**0.5 / w.size(-1)**0.5)
            else:
                w.normal_(std=0.33**0.5 / w.size(-1)**0.5)
        elif name.endswith("bias"):
            w.zero_()
        elif name.endswith("gains"):
            w.normal_(mean=1, std=0)
        else:
            raise Exception(f"Uninitialized parameter: {name}")

    # create the optimizer(s)
    # MuonH replaces plain Muon on the hidden 2D weights: hard hyperball projection
    # after each step (R = initial Frobenius norm * budget_mult), wd=0 since the
    # projection now controls norm growth. AdamW aux groups match the starter
    # (lr 0.3 / 1/320 / 0.01, betas=(0.8, 0.95), eps=1e-10, wd=0).
    optimizer1 = AdamW([dict(params=[model.embed.weight], lr=0.3, name="adam_embed"),
                        dict(params=[model.proj.weight], lr=1/320, name="adam_lm_head"),
                        dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.01, name="adam_scalars")],
                       betas=(0.8, 0.95), eps=1e-10, weight_decay=0, fused=True)
    optimizer2 = MuonH([p for p in model.blocks.parameters() if p.ndim >= 2],
                       lr=args.muonh_lr, weight_decay=0.0, mu=0.95,
                       hyperball=True, budget_mult=args.muonh_budget_mult,
                       mode=args.muonh_mode)
    optimizer2.param_groups[0]["name"] = "muonh_blocks"
    optimizers = [optimizer1, optimizer2]
    # AGC targets: AdamW aux groups (embed, lm_head, scalars). Built from optimizer1
    # param groups to track exactly the same params AdamW updates.
    aux_params_for_agc = [p for g in optimizer1.param_groups for p in g["params"]]
    # Inner-MuonH AGC targets: block 2D weights consumed by MuonH. Clipped BEFORE
    # the MuonH momentum buffer integrates the gradient.
    muonh_params_for_agc = [p for g in optimizer2.param_groups for p in g["params"]]
    assert set(p for opt in optimizers for group in opt.param_groups
               for p in group["params"]) == set(model.parameters())
    for opt in optimizers:
        for group in opt.param_groups:
            group["initial_lr"] = group["lr"]
    # Per-group cooldown_frac: MuonH groups use full linear cooldown from step 0
    # (h_cooldown_frac=1.0); AdamW aux groups use a shorter cooldown so the
    # embed / head keep learning for the first ~60% of training.
    h_cooldown_frac = 1.0
    aux_cooldown_frac = 0.4
    for group in optimizer1.param_groups:
        group["cooldown_frac"] = aux_cooldown_frac
        group["cooldown_shape"] = "linear"
    for group in optimizer2.param_groups:
        group["cooldown_frac"] = h_cooldown_frac
        group["cooldown_shape"] = args.muonh_cooldown_shape

    # learning rate schedule: stable then decay, with per-group cooldown_frac.
    # Within the cooldown phase, eta decays from 1 → 0 in one of three shapes.
    # c is normalized cooldown progress in [0, 1].
    def set_hparams(step):
        progress = step / train_steps
        assert 0 <= progress < 1
        # MuonH-only linear warmup: scales LR by (step+1)/K for the first K steps.
        # AdamW aux groups are unaffected. warmup_steps=0 is a no-op (factor=1.0).
        if args.muonh_warmup_steps > 0:
            muonh_warmup = min(1.0, (step + 1) / args.muonh_warmup_steps)
        else:
            muonh_warmup = 1.0
        for opt in optimizers:
            for group in opt.param_groups:
                cooldown_frac = group["cooldown_frac"]
                if progress < 1 - cooldown_frac:
                    eta = 1.0
                else:
                    c = (1 - progress) / cooldown_frac  # 1 → 0 over cooldown
                    shape = group["cooldown_shape"]
                    if shape == "linear":
                        eta = c
                    elif shape == "cosine":
                        eta = 0.5 * (1.0 - math.cos(math.pi * c))
                    elif shape == "sqrt":
                        eta = math.sqrt(max(0.0, c))
                    else:
                        raise ValueError(f"unknown cooldown_shape: {shape}")
                if opt is optimizer2:
                    eta = eta * muonh_warmup
                group["lr"] = group["initial_lr"] * eta
        return muonh_warmup


    ########################################
    #        Training and Validation       #
    ########################################

    train_loader = distributed_data_generator("data/fineweb10B/fineweb_train_*.bin", batch_size)
    for p in model.parameters():
        dist.broadcast(p.detach(), 0)

    # MuLoCo outer Nesterov SGD state (Algorithm 1, K=1). Snapshot after broadcast
    # so all ranks agree on the anchor. Velocity starts at zero. Wraps ALL
    # trainable params so the outer pull is applied uniformly across MuonH-SI
    # (block 2D weights), AdamW (embed / lm_head / scalars), and any biases or
    # gains. Inner optimizer state (MuonH momentum, AdamW exp_avg) is NOT reset
    # at outer-step boundaries — matches public ref #13 and closed PR #55.
    use_outer = bool(args.use_outer_optimizer)
    if use_outer:
        outer_anchor = {n: p.detach().clone() for n, p in model.named_parameters()}
        outer_velocity = {n: torch.zeros_like(p) for n, p in model.named_parameters()}
    else:
        outer_anchor = None
        outer_velocity = None
    outer_applied_steps = 0

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
        dist.all_reduce(step_loss, op=dist.ReduceOp.SUM)
        train_loss = float((step_loss / batch_size).item())
        # set optimization hyperparameters and take a step
        muonh_warmup_factor = set_hparams(step)
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
            )
        # NS5 input/output max-σ telemetry. Sample the first 5 MuonH params at a
        # fixed set of steps to compare polynomial behaviour on real gradients.
        # Must run BEFORE optimizer step because muon_update mutates grad+momentum.
        ns5_telem_due = (
            dist.get_rank() == 0
            and train_step in (100, 500, 1500, 3000, train_steps)
        )
        if ns5_telem_due:
            ns5_telem_metrics = {"trial": trial_idx, "train/step": train_step}
            ns5_in_vals = []
            ns5_out_vals = []
            for opt in optimizers:
                if isinstance(opt, MuonH):
                    muonh_params = opt.param_groups[0]["params"]
                    mu_val = opt.param_groups[0]["mu"]
                    for pi, p in enumerate(muonh_params[:5]):
                        if p.grad is None:
                            continue
                        state = opt.state[p]
                        if "momentum" not in state:
                            continue
                        in_sig, out_sig = compute_ns5_sigma_telemetry(
                            p.grad, state["momentum"], mu_val,
                            args.ns5_a, args.ns5_b, args.ns5_c,
                        )
                        ns5_telem_metrics[f"train/ns5/block_{pi}/input_max_sigma"] = in_sig
                        ns5_telem_metrics[f"train/ns5/block_{pi}/output_max_sigma"] = out_sig
                        ns5_in_vals.append(in_sig)
                        ns5_out_vals.append(out_sig)
            if ns5_in_vals:
                ns5_telem_metrics["train/ns5/input_max_sigma_mean"] = sum(ns5_in_vals) / len(ns5_in_vals)
                ns5_telem_metrics["train/ns5/output_max_sigma_mean"] = sum(ns5_out_vals) / len(ns5_out_vals)
                ns5_telem_metrics["train/ns5/output_max_sigma_max"] = max(ns5_out_vals)
                wandb.log(ns5_telem_metrics, step=wandb_step)
        # AGC on aux AdamW groups: clip per-param grad to clip_ratio * |param|.
        # No-op (bit-identical) when args.aux_agc_clip_ratio <= 0.
        agc_stats = adaptive_gradient_clip(
            aux_params_for_agc, args.aux_agc_clip_ratio, eps=args.aux_agc_eps,
        )
        # AGC on inner MuonH gradient: clip BEFORE the momentum buffer integrates
        # the reduced gradient. No-op (bit-identical) when clip_ratio <= 0.
        muonh_agc_stats = adaptive_gradient_clip(
            muonh_params_for_agc, args.muonh_agc_clip_ratio, eps=args.muonh_agc_eps,
        )
        for opt in optimizers:
            opt.step()
        # Log warmup telemetry every 10 steps during warmup (and at telemetry events
        # afterwards) so we capture the warmup curve at high resolution. Cheap since
        # it's just two floats.
        warmup_due = (
            args.muonh_warmup_steps > 0
            and step < args.muonh_warmup_steps + 50
            and (step == 0 or (step + 1) % 10 == 0)
        )
        if dist.get_rank() == 0 and (telemetry_due or warmup_due):
            muonh_metrics = {"trial": trial_idx, "train/step": train_step}
            for opt in optimizers:
                if isinstance(opt, MuonH):
                    if telemetry_due:
                        muonh_metrics["train/muonh/active_fraction"] = opt._last_active_fraction
                        muonh_metrics["train/muonh/radius_to_norm_max"] = opt._last_radius_to_norm_max
                        muonh_metrics["train/muonh/norm_to_radius_max"] = opt._last_norm_to_radius_max
                    muonh_metrics["train/muonh/warmup_factor"] = muonh_warmup_factor
                    muonh_metrics["train/muonh/effective_lr"] = opt.param_groups[0]["lr"]
            if telemetry_due and args.aux_agc_clip_ratio > 0 and agc_stats["agc_total"] > 0:
                muonh_metrics["train/agc/active_fraction"] = agc_stats["agc_clipped"] / agc_stats["agc_total"]
                muonh_metrics["train/agc/clipped_count"] = agc_stats["agc_clipped"]
                muonh_metrics["train/agc/total_count"] = agc_stats["agc_total"]
                muonh_metrics["train/agc/max_ratio"] = agc_stats["agc_max_ratio"]
                muonh_metrics["train/agc/scale_min"] = agc_stats["agc_scale_min"]
                muonh_metrics["train/agc/scale_mean"] = agc_stats["agc_scale_mean"]
            if args.muonh_agc_clip_ratio > 0 and muonh_agc_stats["agc_total"] > 0:
                muonh_metrics["train/muonh/agc/fraction_active"] = (
                    muonh_agc_stats["agc_clipped"] / muonh_agc_stats["agc_total"]
                )
                muonh_metrics["train/muonh/agc/clipped_count"] = muonh_agc_stats["agc_clipped"]
                muonh_metrics["train/muonh/agc/total_count"] = muonh_agc_stats["agc_total"]
                muonh_metrics["train/muonh/agc/max_ratio"] = muonh_agc_stats["agc_max_ratio"]
                muonh_metrics["train/muonh/agc/scale_min"] = muonh_agc_stats["agc_scale_min"]
                muonh_metrics["train/muonh/agc/scale_mean"] = muonh_agc_stats["agc_scale_mean"]
            if len(muonh_metrics) > 2:
                wandb.log(muonh_metrics, step=wandb_step)
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

        # MuLoCo outer Nesterov step (Algorithm 1, K=1). Fires every sync_interval
        # inner steps, never on the final step (we want the last inner update to
        # remain the live state). All ranks hold identical p.data after MuonH's
        # all_gather and AdamW's identical-on-all-ranks update, so the outer step
        # computes the same result on every rank without explicit syncing.
        # MuonH-SI interaction note: outer step pulls live weights off the
        # initial-Frobenius sphere; the next MuonH-SI inner step reads
        # ``param.norm()`` at that step and preserves the new norm. Acceptable
        # behavior — the goal is trajectory smoothing, not strict norm invariance.
        if use_outer and train_step % args.sync_interval == 0 and train_step < train_steps:
            log_outer = (dist.get_rank() == 0)
            if log_outer:
                delta_sq = torch.zeros((), device=device)
                velocity_sq = torch.zeros((), device=device)
                total_count = 0
            with torch.no_grad():
                for n, p in model.named_parameters():
                    delta = outer_anchor[n] - p.data
                    outer_velocity[n].mul_(args.outer_momentum).add_(delta)
                    p.data.copy_(outer_anchor[n] - args.outer_lr *
                                 (args.outer_momentum * outer_velocity[n] + delta))
                    outer_anchor[n].copy_(p.data)
                    if log_outer:
                        delta_sq = delta_sq + delta.float().square().sum()
                        velocity_sq = velocity_sq + outer_velocity[n].float().square().sum()
                        total_count += delta.numel()
            outer_applied_steps += 1
            if log_outer:
                delta_rms = (delta_sq.item() / max(1, total_count)) ** 0.5
                velocity_rms = (velocity_sq.item() / max(1, total_count)) ** 0.5
                wandb.log({
                    "trial": trial_idx,
                    "train/step": train_step,
                    "train/muloco/outer_step": outer_applied_steps,
                    "train/muloco/delta_rms": delta_rms,
                    "train/muloco/velocity_rms": velocity_rms,
                }, step=wandb_step)

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
