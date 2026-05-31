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
    parser.add_argument("--train_steps", type=int, default=None, help="Override the per-trial train_steps")
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
        # float32 linspace can round the endpoint above numel-1 for tensors with
        # >~16M elements (e.g. embed/proj weights), so clamp to a safe range.
        idx = torch.linspace(0, values.numel() - 1, max_samples, device=values.device).long().clamp_(max=values.numel() - 1)
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
            if "betas" in group:
                metrics[f"train/beta1/{group_name}"] = float(group["betas"][0])
                metrics[f"train/beta2/{group_name}"] = float(group["betas"][1])
            if "mu" in group:
                metrics[f"train/mu/{group_name}"] = group["mu"]
            # PR #1754: log per-step AdamW moment norms for embed kind so the
            # selective-moment-reset sawtooth is visible in W&B telemetry.
            if group.get("name") == "adam_embed":
                exp_avg_sq_sum = 0.0
                exp_avg_sum = 0.0
                for p in group["params"]:
                    st = opt.state.get(p, {})
                    if "exp_avg" in st:
                        exp_avg_sum += float(st["exp_avg"].float().square().sum().item())
                    if "exp_avg_sq" in st:
                        exp_avg_sq_sum += float(st["exp_avg_sq"].float().square().sum().item())
                metrics["optimizer/embed/exp_avg.norm"] = exp_avg_sum ** 0.5
                metrics["optimizer/embed/exp_avg_sq.norm"] = exp_avg_sq_sum ** 0.5
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
        logits = LOGIT_SOFTCAP * logits * (logits.square() + LOGIT_SOFTCAP**2).rsqrt()
        return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")


########################################
#              Optimizer               #
########################################

# Contra-Muon + SOAP-on-MLP hyperparameters
CONTRA_MUON = float(os.environ.get("CONTRA_MUON", "0.5"))
MU = float(os.environ.get("MU_START", "0.95"))
MU_END = float(os.environ.get("MU_END", "0.95"))
# Cooldown-only mu schedule (Arm B of PR #288): hold MU_COOLDOWN_START during
# warmup/plateau, then linearly anneal to MU_COOLDOWN_END only during cooldown.
# Enabled when either env var is explicitly set; otherwise the MU/MU_END
# full-run linear schedule above is used.
MU_COOLDOWN_ENABLED = ("MU_COOLDOWN_START" in os.environ) or ("MU_COOLDOWN_END" in os.environ)
MU_COOLDOWN_START = float(os.environ.get("MU_COOLDOWN_START", "0.95"))
MU_COOLDOWN_END = float(os.environ.get("MU_COOLDOWN_END", "0.95"))
# Optional Muon momentum warmup (PR #415): linearly ramp cur_mu from
# MU_WARMUP_START -> MU_COOLDOWN_START over the first MU_WARMUP_STEPS optimizer
# steps before entering the plateau+cooldown schedule. Only active when
# MU_COOLDOWN_ENABLED is True. MU_WARMUP_STEPS=0 disables the warmup branch
# entirely and exactly reproduces the prior cooldown-only schedule.
MU_WARMUP_STEPS = int(os.environ.get("MU_WARMUP_STEPS", "0"))
MU_WARMUP_START = float(os.environ.get("MU_WARMUP_START", "0.85"))
MUON_LR = float(os.environ.get("MUON_LR", "0.0375"))
MUON_WEIGHT_DECAY = 0.025  # nominal; Muon.step does not apply explicit wd (u/w-floor replaces it)
TARGET_UW = 0.35
NORMUON_BETA2 = 0.95
SOAP_BETA2 = 0.90
SOAP_PRECOND_FREQ = 10
# Attention SOAP (record #16) hyperparameters
ATTN_SOAP_BETA2 = 0.90
ATTN_SOAP_PRECOND_FREQ = 10
ATTN_SOAP_TRUST_THRESHOLD = float(os.environ.get("ATTN_SOAP_TRUST_THRESHOLD", "0.9"))
NS5_ITERS = int(os.environ.get("NS5_ITERS", "12"))
WD_AUX = float(os.environ.get("WD_AUX", "0.0"))  # AdamW WD on embed + lm_head matrices (scalars stay at 0)
PER_KIND_AUX_WD_ENABLED = int(os.environ.get("PER_KIND_AUX_WD_ENABLED", "0"))
WD_LM_HEAD = float(os.environ.get("WD_LM_HEAD", "0.001"))
WD_EMBED_OVERRIDE = float(os.environ.get("WD_EMBED_OVERRIDE", "0.001"))
# PR #1789: PER_KIND_AUX_BETA1 — per-AUX-kind AdamW β1 dispatch
AUX_BETA1_DEFAULT = 0.80  # matches existing global default
AUX_BETA1_EMBED = float(os.environ.get("AUX_BETA1_EMBED", str(AUX_BETA1_DEFAULT)))
AUX_BETA1_LM_HEAD = float(os.environ.get("AUX_BETA1_LM_HEAD", str(AUX_BETA1_DEFAULT)))
AUX_BETA1_SCALARS = float(os.environ.get("AUX_BETA1_SCALARS", str(AUX_BETA1_DEFAULT)))
PER_KIND_AUX_BETA1_ENABLED = int(os.environ.get("PER_KIND_AUX_BETA1_ENABLED", "0")) or \
    ("AUX_BETA1_EMBED" in os.environ) or ("AUX_BETA1_LM_HEAD" in os.environ) or ("AUX_BETA1_SCALARS" in os.environ)
EMBED_INIT_STD = float(os.environ.get("EMBED_INIT_STD", "1.0"))  # default preserves baseline N(0,1)
LOGIT_SOFTCAP = float(os.environ.get("LOGIT_SOFTCAP", "15.0"))  # default = 15 (current hardcoded value); soft-cap value c in f(x) = c·x / sqrt(x^2+c^2)
# PR #1754: PER_KIND_AUX_PERIODIC_RESET_EMBED_MOMENT_ISOLATION — selective moment reset on embed
# PR #1824: PER_KIND_AUX_PERIODIC_RESET_LM_HEAD — selective moment reset on lm_head
# PR #1842/#1864/#1887: AUX_RESET_*_FACTOR partial-reset multiplier (0.0 = full zero, 1.0 = no-op)
# PR #1921: Scheme B aliases (PER_KIND_AUX_PERIODIC_RESET_ENABLED gate + AUX_RESET_KIND_FILTER +
#           kind-prefixed AUX_RESET_<KIND>_INTERVAL/MOMENT/FACTOR names) exposing the FACTOR control.
# Bitfield (MOMENT): 0 = legacy "both" (matches #1729 when only embed flag set),
# 1 = exp_avg_sq only (bit-0), 2 = exp_avg only (bit-1), 3 = both moments (bit-0 + bit-1).
#
# Scheme A (suffix-style, original): PER_KIND_AUX_PERIODIC_RESET_<KIND>_ENABLED + AUX_RESET_INTERVAL_<KIND> + AUX_RESET_MOMENT_<KIND>
# Scheme B (gate + filter, adds FACTOR): PER_KIND_AUX_PERIODIC_RESET_ENABLED + AUX_RESET_KIND_FILTER +
#     AUX_RESET_<KIND>_INTERVAL + AUX_RESET_<KIND>_MOMENT + AUX_RESET_<KIND>_FACTOR
# Both schemes coexist; Scheme B values override Scheme A when set.
PER_KIND_AUX_PERIODIC_RESET_GATE = int(os.environ.get("PER_KIND_AUX_PERIODIC_RESET_ENABLED", "0"))
AUX_RESET_KIND_FILTER = int(os.environ.get("AUX_RESET_KIND_FILTER", "0"))

def _resolve_reset_param(scheme_b_name: str, scheme_a_name: str, default: str, cast):
    """Prefer Scheme B (kind-prefixed) if set, else fall back to Scheme A (suffix)."""
    if scheme_b_name in os.environ:
        return cast(os.environ[scheme_b_name])
    return cast(os.environ.get(scheme_a_name, default))

# Embed reset config (resolved across both schemes).
PER_KIND_AUX_PERIODIC_RESET_EMBED_ENABLED = int(os.environ.get(
    "PER_KIND_AUX_PERIODIC_RESET_EMBED_ENABLED",
    str(PER_KIND_AUX_PERIODIC_RESET_GATE) if (PER_KIND_AUX_PERIODIC_RESET_GATE and AUX_RESET_KIND_FILTER) else "0",
))
AUX_RESET_INTERVAL_EMBED = _resolve_reset_param("AUX_RESET_EMBED_INTERVAL", "AUX_RESET_INTERVAL_EMBED", "0", int)
AUX_RESET_MOMENT_EMBED = _resolve_reset_param("AUX_RESET_EMBED_MOMENT", "AUX_RESET_MOMENT_EMBED", "0", int)
AUX_RESET_FACTOR_EMBED = _resolve_reset_param("AUX_RESET_EMBED_FACTOR", "AUX_RESET_FACTOR_EMBED", "0.0", float)

# LM-head reset config (resolved across both schemes).
PER_KIND_AUX_PERIODIC_RESET_LM_HEAD_ENABLED = int(os.environ.get(
    "PER_KIND_AUX_PERIODIC_RESET_LM_HEAD_ENABLED",
    str(PER_KIND_AUX_PERIODIC_RESET_GATE) if (PER_KIND_AUX_PERIODIC_RESET_GATE and AUX_RESET_KIND_FILTER) else "0",
))
AUX_RESET_INTERVAL_LM_HEAD = _resolve_reset_param("AUX_RESET_LM_HEAD_INTERVAL", "AUX_RESET_INTERVAL_LM_HEAD", "0", int)
AUX_RESET_MOMENT_LM_HEAD = _resolve_reset_param("AUX_RESET_LM_HEAD_MOMENT", "AUX_RESET_MOMENT_LM_HEAD", "0", int)
AUX_RESET_FACTOR_LM_HEAD = _resolve_reset_param("AUX_RESET_LM_HEAD_FACTOR", "AUX_RESET_FACTOR_LM_HEAD", "0.0", float)

# When Scheme B is used with kind filter, only enable kinds with a non-zero interval.
if PER_KIND_AUX_PERIODIC_RESET_GATE and AUX_RESET_KIND_FILTER:
    if AUX_RESET_INTERVAL_EMBED <= 0:
        PER_KIND_AUX_PERIODIC_RESET_EMBED_ENABLED = 0
    if AUX_RESET_INTERVAL_LM_HEAD <= 0:
        PER_KIND_AUX_PERIODIC_RESET_LM_HEAD_ENABLED = 0

# PR #2007: MLP-SOAP per-depth-half β2 dispatch (askeladd #1775/#1928 front_FAST lineage).
# When enabled, MLP-SOAP params with layer index < SPLIT (default 6) use the "front"
# β2 setting; otherwise use the "back" setting. Each half's boolean toggle (1/0)
# selects FAST (β2=0.85) or SLOW (β2=0.95). Canonical front_FAST: FRONT_HALF=1
# BACK_HALF=0 → front=0.85 back=0.95.
MLP_SOAP_PER_DEPTH_HALF_ENABLED = int(os.environ.get("MLP_SOAP_PER_DEPTH_HALF_ENABLED", "0"))
MLP_SOAP_FRONT_HALF = int(os.environ.get("MLP_SOAP_FRONT_HALF", "1"))
MLP_SOAP_BACK_HALF = int(os.environ.get("MLP_SOAP_BACK_HALF", "0"))
MLP_SOAP_DEPTH_SPLIT = int(os.environ.get("MLP_SOAP_DEPTH_SPLIT", "6"))
MLP_SOAP_BETA2_FAST = float(os.environ.get("MLP_SOAP_BETA2_FAST", "0.85"))
MLP_SOAP_BETA2_SLOW = float(os.environ.get("MLP_SOAP_BETA2_SLOW", "0.95"))

# Optional explicit RNG seed for n=2 verification protocol (PR #1806 lineage).
SEED_ENV = os.environ.get("SEED")
SEED = int(SEED_ENV) if SEED_ENV is not None else None

# Per-PR-instruction marker — surface flags for periodic-reset config-operative
# spot-check so disabled-reset is unambiguous in W&B config (PR #2007 step-0).
AUX_RESET_EMBED_ENABLED = int(os.environ.get("AUX_RESET_EMBED_ENABLED", "0"))
AUX_RESET_LM_HEAD_ENABLED = int(os.environ.get("AUX_RESET_LM_HEAD_ENABLED", "0"))


def zeropower_via_newtonschulz5(G: Tensor) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT

    # Ensure spectral norm is at most 1
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    # Perform the NS iterations, not optimizing for wallclock speed
    a, b, c = 2, -1.5, 0.5
    for _ in range(NS5_ITERS):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X

    if G.size(-2) > G.size(-1):
        X = X.mT
    return X


def scale_to_unit_operator_norm(G: Tensor, eps: float = 1e-10) -> Tensor:
    """Power-iteration estimate of spectral norm; divide G by it (used by Contra-Muon)."""
    X = G.float()
    v = torch.ones(X.size(-1), dtype=X.dtype, device=X.device)
    v = v / torch.clamp(v.norm(), min=eps)
    for _ in range(5):
        u = X @ v
        u = u / torch.clamp(u.norm(), min=eps)
        v = X.mT @ u
        v = v / torch.clamp(v.norm(), min=eps)
    op_norm = torch.clamp((X @ v).norm(), min=eps)
    return G / op_norm.to(G.dtype)


def contra_normuon_update(momentum_update, second_moment, beta2=NORMUON_BETA2):
    """Contra-Muon + NorMuon-lite: NS5 -> contra subtraction -> per-row variance normalize."""
    normalized_grad = scale_to_unit_operator_norm(momentum_update.clone())
    update = zeropower_via_newtonschulz5(momentum_update)
    opower_fro = update.norm()
    # Contra correction: subtract CONTRA_MUON / 2 * op-norm-normalized momentum.
    update = update - CONTRA_MUON / 2 * normalized_grad
    update = update * opower_fro / torch.clamp(update.norm(), min=1e-10)
    update *= max(1, update.size(-2) / update.size(-1))**0.5
    # NorMuon-lite per-row (or per-col) variance EMA + renormalize back to original Frobenius norm.
    if update.size(-2) >= update.size(-1):
        per_row_var = (update * update).mean(dim=-1, keepdim=True)
    else:
        per_row_var = (update * update).mean(dim=-2, keepdim=True)
    second_moment.lerp_(per_row_var.float(), 1 - beta2)
    vnorm = update.norm()
    update = update * second_moment.clamp_min(1e-10).rsqrt().to(update.dtype)
    vnorm_new = update.norm().clamp_min(1e-10)
    update = update * (vnorm / vnorm_new)
    return update


def soap_eigenbasis(mat: Tensor, eps: float = 1e-30) -> Tensor:
    """Initial SOAP eigenbasis (eigenvectors of mat, sorted in descending eigenvalue order)."""
    try:
        evals, q = torch.linalg.eigh(mat + eps * torch.eye(mat.size(0), device=mat.device))
    except RuntimeError:
        evals, q = torch.linalg.eigh(mat.double() + eps * torch.eye(mat.size(0), device=mat.device))
        evals, q = evals.float(), q.float()
    # Descending order so column 0 always corresponds to the dominant direction.
    return torch.flip(q, [1])


def soap_basis_qr(row_gg, col_gg, q_row, q_col, exp_avg_sq):
    """One step of subspace iteration: refresh basis while preserving the exp_avg_sq alignment."""
    row_eig = torch.diag(q_row.T @ row_gg @ q_row)
    row_sort = torch.argsort(row_eig, descending=True)
    q_row = q_row[:, row_sort]
    exp_avg_sq = exp_avg_sq.index_select(0, row_sort)
    q_row, _ = torch.linalg.qr(row_gg @ q_row)

    col_eig = torch.diag(q_col.T @ col_gg @ q_col)
    col_sort = torch.argsort(col_eig, descending=True)
    q_col = q_col[:, col_sort]
    exp_avg_sq = exp_avg_sq.index_select(1, col_sort)
    q_col, _ = torch.linalg.qr(col_gg @ q_col)
    return q_row, q_col, exp_avg_sq


def soap_refresh(grad, state, beta2=SOAP_BETA2, refresh_freq=SOAP_PRECOND_FREQ,
                 use_trust_gate=False, trust_threshold=ATTN_SOAP_TRUST_THRESHOLD):
    """Update row/col Gram EMAs every step; refresh eigenbasis every `refresh_freq` steps.

    When ``use_trust_gate`` is True (record #16 extension), the refresh runs the
    sort+QR subspace-iteration step inline so the pre-QR (but already sorted)
    basis can be compared against the post-QR basis. Comparing pre-sort q_old
    to post-QR q_new measures permutation overlap (~1/sqrt(D)), not rotation,
    which is why this path doesn't reuse ``soap_basis_qr``."""
    grad_f = grad.float()
    state["row_gg"].lerp_(grad_f @ grad_f.T, 1 - beta2)
    state["col_gg"].lerp_(grad_f.T @ grad_f, 1 - beta2)
    if state["q_row"] is None:
        state["q_row"] = soap_eigenbasis(state["row_gg"])
        state["q_col"] = soap_eigenbasis(state["col_gg"])
        if use_trust_gate:
            state["trust_gate"] = 1.0
            state["trust_cos_row"] = 1.0
            state["trust_cos_col"] = 1.0
    elif state["soap_step"] > 0 and state["soap_step"] % refresh_freq == 0:
        if use_trust_gate:
            row_gg = state["row_gg"]
            col_gg = state["col_gg"]
            q_row_old = state["q_row"]
            q_col_old = state["q_col"]
            exp_avg_sq = state["exp_avg_sq"]

            row_eig = torch.diag(q_row_old.T @ row_gg @ q_row_old)
            row_sort = torch.argsort(row_eig, descending=True)
            q_row_sorted = q_row_old[:, row_sort]
            exp_avg_sq = exp_avg_sq.index_select(0, row_sort)
            q_row_new, _ = torch.linalg.qr(row_gg @ q_row_sorted)

            col_eig = torch.diag(q_col_old.T @ col_gg @ q_col_old)
            col_sort = torch.argsort(col_eig, descending=True)
            q_col_sorted = q_col_old[:, col_sort]
            exp_avg_sq = exp_avg_sq.index_select(1, col_sort)
            q_col_new, _ = torch.linalg.qr(col_gg @ q_col_sorted)

            state["q_row"] = q_row_new
            state["q_col"] = q_col_new
            state["exp_avg_sq"] = exp_avg_sq

            cos_row = (q_row_new.T @ q_row_sorted).diagonal().abs().mean().item()
            cos_col = (q_col_new.T @ q_col_sorted).diagonal().abs().mean().item()
            state["trust_cos_row"] = cos_row
            state["trust_cos_col"] = cos_col
            state["trust_gate"] = 1.0 if (cos_row >= trust_threshold and cos_col >= trust_threshold) else 0.0
        else:
            state["q_row"], state["q_col"], state["exp_avg_sq"] = soap_basis_qr(
                state["row_gg"], state["col_gg"], state["q_row"], state["q_col"], state["exp_avg_sq"]
            )
    state["soap_step"] += 1


def soap_precondition(update, state, beta2=SOAP_BETA2, eps=1e-8):
    """Project update into the row/col eigenbasis, scale by inverse sqrt of second-moment EMA, project back, renormalize.

    Trust gate: if state['trust_gate'] == 0.0 (eigenbasis rotated too far at last refresh),
    fall back to the unpreconditioned update."""
    if state["q_row"] is None:
        return update
    if state.get("trust_gate", 1.0) == 0.0:
        return update
    update_f = update.float()
    q_row, q_col = state["q_row"], state["q_col"]
    projected = q_row.T @ update_f @ q_col
    state["exp_avg_sq"].mul_(beta2).add_(projected.square(), alpha=1 - beta2)
    precond = q_row @ (projected / state["exp_avg_sq"].sqrt().add(eps)) @ q_col.T
    precond.mul_(update_f.norm() / precond.norm().clamp_min(eps))
    return precond.to(update.dtype)


class Muon(torch.optim.Optimizer):
    def __init__(self, named_params, lr=MUON_LR, weight_decay=MUON_WEIGHT_DECAY, mu=MU):
        assert isinstance(named_params, list) and len(named_params) >= 1
        # MLP weights receive SOAP preconditioning (PR #78 / public record #14).
        self.soap_params = {
            p for n, p in named_params
            if n.endswith(".mlp.fc.weight") or n.endswith(".mlp.proj.weight")
        }
        # Attention weights (qkv + proj) receive trust-gated SOAP (public record #16 extension).
        self.attn_soap_params = {
            p for n, p in named_params
            if (n.endswith(".attn.q.weight") or n.endswith(".attn.k.weight")
                or n.endswith(".attn.v.weight") or n.endswith(".attn.proj.weight"))
        }
        # Track which sub-type each attention-SOAP param is (q/k/v/proj) for per-type telemetry.
        self.attn_soap_kind: dict[int, str] = {}
        # PR #2007 — per-depth-half MLP-SOAP β2 dispatch lookup tables.
        self.mlp_soap_beta2: dict[int, float] = {}
        self.mlp_soap_depth_half: dict[int, str] = {}  # "front" or "back"
        self.mlp_soap_layer: dict[int, int] = {}
        for n, p in named_params:
            layer_idx: int | None = None
            head = n.split(".", 1)[0]
            try:
                layer_idx = int(head)
            except ValueError:
                layer_idx = None
            if p in self.attn_soap_params:
                if n.endswith(".attn.q.weight"):
                    self.attn_soap_kind[id(p)] = "q"
                elif n.endswith(".attn.k.weight"):
                    self.attn_soap_kind[id(p)] = "k"
                elif n.endswith(".attn.v.weight"):
                    self.attn_soap_kind[id(p)] = "v"
                elif n.endswith(".attn.proj.weight"):
                    self.attn_soap_kind[id(p)] = "proj"
            elif p in self.soap_params and layer_idx is not None:
                self.mlp_soap_layer[id(p)] = layer_idx
                if MLP_SOAP_PER_DEPTH_HALF_ENABLED:
                    if layer_idx < MLP_SOAP_DEPTH_SPLIT:
                        # Front half: FRONT_HALF=1 → FAST (0.85); FRONT_HALF=0 → SLOW (0.95).
                        beta2 = MLP_SOAP_BETA2_FAST if MLP_SOAP_FRONT_HALF else MLP_SOAP_BETA2_SLOW
                        self.mlp_soap_beta2[id(p)] = beta2
                        self.mlp_soap_depth_half[id(p)] = "front"
                    else:
                        beta2 = MLP_SOAP_BETA2_FAST if MLP_SOAP_BACK_HALF else MLP_SOAP_BETA2_SLOW
                        self.mlp_soap_beta2[id(p)] = beta2
                        self.mlp_soap_depth_half[id(p)] = "back"
                else:
                    self.mlp_soap_beta2[id(p)] = SOAP_BETA2
                    self.mlp_soap_depth_half[id(p)] = "uniform"
        params = sorted([p for _, p in named_params], key=lambda x: x.size(), reverse=True)
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
                        # NorMuon-lite per-row (or per-col) variance buffer.
                        if p.size(-2) >= p.size(-1):
                            state["second_moment"] = torch.zeros(
                                (*p.shape[:-1], 1), dtype=torch.float32, device=p.device
                            )
                        else:
                            state["second_moment"] = torch.zeros(
                                (*p.shape[:-2], 1, p.shape[-1]), dtype=torch.float32, device=p.device
                            )
                        if p in self.soap_params or p in self.attn_soap_params:
                            m, n = p.size(0), p.size(1)
                            state["row_gg"] = torch.zeros(m, m, dtype=torch.float32, device=p.device)
                            state["col_gg"] = torch.zeros(n, n, dtype=torch.float32, device=p.device)
                            state["q_row"] = None
                            state["q_col"] = None
                            state["exp_avg_sq"] = torch.zeros_like(p, dtype=torch.float32)
                            state["soap_step"] = 0
                            if p in self.attn_soap_params:
                                # Default trust gate is 1.0 until the first basis refresh.
                                state["trust_gate"] = 1.0
                                state["trust_cos_row"] = 1.0
                                state["trust_cos_col"] = 1.0
                    grad = p.grad
                    state["momentum"].lerp_(grad, 1 - group["mu"])
                    momentum_update = grad.lerp(state["momentum"], group["mu"])
                    use_soap = p in self.soap_params
                    use_attn_soap = p in self.attn_soap_params
                    # SOAP precondition applied to momentum BEFORE NS5+contra+NorMuon
                    # (matches public record #14/16 — pre-NS5 placement). PR #2007:
                    # MLP-SOAP β2 is per-param to support depth-half dispatch.
                    if use_soap:
                        mlp_beta2 = self.mlp_soap_beta2.get(id(p), SOAP_BETA2)
                        momentum_update = soap_precondition(momentum_update, state, beta2=mlp_beta2)
                    elif use_attn_soap:
                        momentum_update = soap_precondition(momentum_update, state)
                    # NS5 + contra + NorMuon row variance on (possibly SOAP-preconditioned) momentum.
                    update = contra_normuon_update(momentum_update, state["second_moment"])
                    # u/w-floor: scale up if u/w < TARGET_UW; leave alone otherwise.
                    p_fro = p.float().norm().clamp_min(1e-8)
                    u_fro = update.float().norm().clamp_min(1e-8)
                    cur_uw = u_fro / p_fro
                    scale = torch.where(cur_uw < TARGET_UW, TARGET_UW * p_fro / u_fro, torch.ones_like(p_fro))
                    update = update * scale.to(update.dtype)
                    # Explicit weight decay intentionally omitted (matches record #14; u/w-floor replaces wd).
                    p.add_(update, alpha=-group["lr"])
                    # Refresh SOAP state with the raw grad (after applying the step).
                    if use_soap:
                        mlp_beta2 = self.mlp_soap_beta2.get(id(p), SOAP_BETA2)
                        soap_refresh(grad, state, beta2=mlp_beta2)
                    elif use_attn_soap:
                        soap_refresh(grad, state, beta2=ATTN_SOAP_BETA2,
                                     refresh_freq=ATTN_SOAP_PRECOND_FREQ,
                                     use_trust_gate=True,
                                     trust_threshold=ATTN_SOAP_TRUST_THRESHOLD)
                dist.all_gather(params_pad[base_i:base_i + world_size], params_pad[base_i + rank])

    def trust_gate_stats(self) -> dict[str, float]:
        """Return aggregate + per-weight-type trust-gate telemetry across attention SOAP params.

        Aggregate keys: count, on_fraction, mean_cos_row/col, min_cos_row/col.
        Per-type keys (kind in {q, k, v, proj}):
          {kind}/count, {kind}/on_fraction, {kind}/mean_cos_row, {kind}/mean_cos_col.
        """
        cos_rows: list[float] = []
        cos_cols: list[float] = []
        on_count = 0
        by_kind: dict[str, dict[str, list[float] | int]] = {
            "q": {"on": 0, "cos_row": [], "cos_col": []},
            "k": {"on": 0, "cos_row": [], "cos_col": []},
            "v": {"on": 0, "cos_row": [], "cos_col": []},
            "proj": {"on": 0, "cos_row": [], "cos_col": []},
        }
        for p in self.attn_soap_params:
            state = self.state.get(p)
            if state is None or "trust_gate" not in state:
                continue
            on = state["trust_gate"] >= 0.5
            cr = state.get("trust_cos_row", 1.0)
            cc = state.get("trust_cos_col", 1.0)
            cos_rows.append(cr)
            cos_cols.append(cc)
            if on:
                on_count += 1
            kind = self.attn_soap_kind.get(id(p))
            if kind is not None:
                by_kind[kind]["cos_row"].append(cr)
                by_kind[kind]["cos_col"].append(cc)
                if on:
                    by_kind[kind]["on"] += 1
        counts = len(cos_rows)
        if counts == 0:
            return {}
        out: dict[str, float] = {
            "count": counts,
            "on_fraction": on_count / counts,
            "mean_cos_row": sum(cos_rows) / counts,
            "mean_cos_col": sum(cos_cols) / counts,
            "min_cos_row": min(cos_rows),
            "min_cos_col": min(cos_cols),
        }
        for kind, agg in by_kind.items():
            crs = agg["cos_row"]
            ccs = agg["cos_col"]
            kn = len(crs)
            if kn == 0:
                continue
            out[f"{kind}/count"] = kn
            out[f"{kind}/on_fraction"] = agg["on"] / kn
            out[f"{kind}/mean_cos_row"] = sum(crs) / kn
            out[f"{kind}/mean_cos_col"] = sum(ccs) / kn
        return out


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
print0(
    f"[PER_KIND_AUX_PERIODIC_RESET] gate={PER_KIND_AUX_PERIODIC_RESET_GATE}"
    f" kind_filter={AUX_RESET_KIND_FILTER}"
)
print0(
    f"[per_kind_aux_periodic_reset embed] enabled={PER_KIND_AUX_PERIODIC_RESET_EMBED_ENABLED}"
    f" interval={AUX_RESET_INTERVAL_EMBED}"
    f" moment={AUX_RESET_MOMENT_EMBED}"
    f" factor={AUX_RESET_FACTOR_EMBED}"
)
print0(
    f"[per_kind_aux_periodic_reset lm_head] enabled={PER_KIND_AUX_PERIODIC_RESET_LM_HEAD_ENABLED}"
    f" interval={AUX_RESET_INTERVAL_LM_HEAD}"
    f" moment={AUX_RESET_MOMENT_LM_HEAD}"
    f" factor={AUX_RESET_FACTOR_LM_HEAD}"
)
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
            "train_steps_cli": args.train_steps,
            "optimizer/contra_muon": CONTRA_MUON,
            "optimizer/mu": MU,
            "optimizer/mu_start": MU,
            "optimizer/mu_end": MU_END,
            "optimizer/mu_cooldown_enabled": MU_COOLDOWN_ENABLED,
            "optimizer/mu_cooldown_start": MU_COOLDOWN_START,
            "optimizer/mu_cooldown_end": MU_COOLDOWN_END,
            "optimizer/mu_warmup_steps": MU_WARMUP_STEPS,
            "optimizer/mu_warmup_start": MU_WARMUP_START,
            "optimizer/muon_lr": MUON_LR,
            "optimizer/muon_weight_decay_nominal": MUON_WEIGHT_DECAY,
            "optimizer/target_uw": TARGET_UW,
            "optimizer/normuon_beta2": NORMUON_BETA2,
            "optimizer/soap_beta2": SOAP_BETA2,
            "optimizer/soap_precond_freq": SOAP_PRECOND_FREQ,
            "optimizer/attn_soap_beta2": ATTN_SOAP_BETA2,
            "optimizer/attn_soap_precond_freq": ATTN_SOAP_PRECOND_FREQ,
            "optimizer/attn_soap_trust_threshold": ATTN_SOAP_TRUST_THRESHOLD,
            "optimizer/ns5_iters": NS5_ITERS,
            "optimizer/wd_aux": WD_AUX,
            "optimizer/per_kind_aux_periodic_reset_gate": PER_KIND_AUX_PERIODIC_RESET_GATE,
            "optimizer/aux_reset_kind_filter": AUX_RESET_KIND_FILTER,
            "optimizer/per_kind_aux_periodic_reset_embed_enabled": int(PER_KIND_AUX_PERIODIC_RESET_EMBED_ENABLED),
            "optimizer/aux_reset_interval_embed": AUX_RESET_INTERVAL_EMBED,
            "optimizer/aux_reset_moment_embed": AUX_RESET_MOMENT_EMBED,
            "optimizer/aux_reset_factor_embed": AUX_RESET_FACTOR_EMBED,
            "optimizer/per_kind_aux_periodic_reset_lm_head_enabled": int(PER_KIND_AUX_PERIODIC_RESET_LM_HEAD_ENABLED),
            "optimizer/aux_reset_interval_lm_head": AUX_RESET_INTERVAL_LM_HEAD,
            "optimizer/aux_reset_moment_lm_head": AUX_RESET_MOMENT_LM_HEAD,
            "optimizer/aux_reset_factor_lm_head": AUX_RESET_FACTOR_LM_HEAD,
            "optimizer/per_kind_aux_wd_enabled": PER_KIND_AUX_WD_ENABLED,
            "optimizer/wd_lm_head": WD_LM_HEAD,
            "optimizer/wd_embed_override": WD_EMBED_OVERRIDE,
            "optimizer/aux_beta1_embed": AUX_BETA1_EMBED,
            "optimizer/aux_beta1_lm_head": AUX_BETA1_LM_HEAD,
            "optimizer/aux_beta1_scalars": AUX_BETA1_SCALARS,
            "optimizer/per_kind_aux_beta1_enabled": int(PER_KIND_AUX_BETA1_ENABLED),
            "optimizer/recipe": "contra-muon + normuon-lite + soap-on-mlp + soap-on-attn-trust-gate (pre-NS5, record #14 + record #16)",
            # PR #2007: MLP-SOAP per-depth-half + per-kind AdamW β1 compound dispatch.
            "optimizer/mlp_soap_per_depth_half_enabled": MLP_SOAP_PER_DEPTH_HALF_ENABLED,
            "optimizer/mlp_soap_front_half": MLP_SOAP_FRONT_HALF,
            "optimizer/mlp_soap_back_half": MLP_SOAP_BACK_HALF,
            "optimizer/mlp_soap_depth_split": MLP_SOAP_DEPTH_SPLIT,
            "optimizer/mlp_soap_beta2_fast": MLP_SOAP_BETA2_FAST,
            "optimizer/mlp_soap_beta2_slow": MLP_SOAP_BETA2_SLOW,
            "optimizer/aux_reset_embed_enabled": AUX_RESET_EMBED_ENABLED,
            "optimizer/aux_reset_lm_head_enabled": AUX_RESET_LM_HEAD_ENABLED,
            "seed": SEED if SEED is not None else -1,
        },
    )

# PR #2007: explicit RNG seeding for n=2 bilateral verification (Arm A SEED=1, Arm B SEED=2).
if SEED is not None:
    torch.manual_seed(SEED)
    torch.cuda.manual_seed_all(SEED)

for trial_idx in range(args.num_trials):


    ########################################
    #       Init & Optim Hyperparams       #
    ########################################

    # we want to minimize this while still reaching 3.28 val loss
    train_steps = args.train_steps if args.train_steps is not None else 3175

    # initialize model parameters
    for name, p in model.named_parameters():
        w = p.data
        if name.endswith("weight"):
            if "proj" in name:
                w.zero_()
            elif "embed" in name:
                w.normal_(std=EMBED_INIT_STD)
            else:
                w.normal_(std=0.33**0.5 / w.size(-1)**0.5)  # default torch init
        elif name.endswith("bias"):
            w.zero_()
        elif name.endswith("gains"):
            w.normal_(mean=1, std=0)
        else:
            raise Exception(f"Uninitialized parameter: {name}")

    # create the optimizer(s) — per-kind AdamW β1 + WD dispatch when enabled.
    if PER_KIND_AUX_WD_ENABLED:
        embed_wd = WD_EMBED_OVERRIDE
        lm_head_wd = WD_LM_HEAD
    else:
        embed_wd = WD_AUX
        lm_head_wd = WD_AUX
    if dist.get_rank() == 0 and trial_idx == 0:
        print(f"[per_kind_aux_wd] enabled={PER_KIND_AUX_WD_ENABLED} embed_wd={embed_wd:.6f} lm_head_wd={lm_head_wd:.6f}",
              flush=True)
        print(f"[per_kind_aux_beta1] enabled={int(PER_KIND_AUX_BETA1_ENABLED)} "
              f"embed_beta1={AUX_BETA1_EMBED} lm_head_beta1={AUX_BETA1_LM_HEAD} "
              f"scalars_beta1={AUX_BETA1_SCALARS}", flush=True)
    optimizer1 = AdamW([dict(params=[model.embed.weight], lr=0.3, name="adam_embed", weight_decay=embed_wd,
                             betas=(AUX_BETA1_EMBED, 0.95)),
                        dict(params=[model.proj.weight], lr=1/320, name="adam_lm_head", weight_decay=lm_head_wd,
                             betas=(AUX_BETA1_LM_HEAD, 0.95)),
                        dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.01, name="adam_scalars",
                             betas=(AUX_BETA1_SCALARS, 0.95))],
                       betas=(0.8, 0.95), eps=1e-10, weight_decay=0, fused=True)
    if dist.get_rank() == 0 and trial_idx == 0:
        for i, g in enumerate(optimizer1.param_groups):
            print(f"[per_kind_aux_beta1] param_group[{i}] name={g.get('name','?')} betas={tuple(g['betas'])} wd={g['weight_decay']:.6f}", flush=True)
    optimizer2 = Muon([(n, p) for n, p in model.blocks.named_parameters() if p.ndim >= 2],
                      lr=MUON_LR, weight_decay=MUON_WEIGHT_DECAY, mu=MU)
    optimizer2.param_groups[0]["name"] = "muon_blocks"

    # PR #2007 step-0 banner: confirm both compound infras are config-operative.
    if dist.get_rank() == 0:
        _banner_mlp = (
            f"[PR1806-ASKELADD-COMPOUND] MLP-SOAP per-depth-half "
            f"ENABLED={MLP_SOAP_PER_DEPTH_HALF_ENABLED} "
            f"front={MLP_SOAP_FRONT_HALF} back={MLP_SOAP_BACK_HALF}"
        )
        _banner_beta1 = (
            f"[per_kind_aux_beta1] enabled={int(PER_KIND_AUX_BETA1_ENABLED)} "
            f"embed={AUX_BETA1_EMBED} lm_head={AUX_BETA1_LM_HEAD} "
            f"scalars={AUX_BETA1_SCALARS}"
        )
        print0(_banner_mlp, console=True)
        print0(_banner_beta1, console=True)
        # Per-param β2 distribution diagnostic for MLP-SOAP depth-half:
        _front_betas = sorted({optimizer2.mlp_soap_beta2[id(p)]
                               for p in optimizer2.soap_params
                               if optimizer2.mlp_soap_depth_half.get(id(p)) == "front"})
        _back_betas = sorted({optimizer2.mlp_soap_beta2[id(p)]
                              for p in optimizer2.soap_params
                              if optimizer2.mlp_soap_depth_half.get(id(p)) == "back"})
        _n_front = sum(1 for p in optimizer2.soap_params
                       if optimizer2.mlp_soap_depth_half.get(id(p)) == "front")
        _n_back = sum(1 for p in optimizer2.soap_params
                      if optimizer2.mlp_soap_depth_half.get(id(p)) == "back")
        print0(
            f"[PR2007-compound] split={MLP_SOAP_DEPTH_SPLIT} front_n={_n_front} back_n={_n_back} "
            f"front_β2s={_front_betas} back_β2s={_back_betas} "
            f"FAST={MLP_SOAP_BETA2_FAST} SLOW={MLP_SOAP_BETA2_SLOW}",
            console=True,
        )
        # AdamW per-kind β1 per-group verification:
        for _grp in optimizer1.param_groups:
            _name = _grp.get("name", "?")
            _betas = _grp.get("betas", (0.8, 0.95))
            print0(f"[PR2007-compound] adam_group={_name} betas={_betas}", console=True)
        # Reset-axis config-operative spot-check (no reset for this PR):
        print0(
            f"[PR2007-compound] aux_reset_embed_enabled={AUX_RESET_EMBED_ENABLED} "
            f"aux_reset_lm_head_enabled={AUX_RESET_LM_HEAD_ENABLED}",
            console=True,
        )
    optimizers = [optimizer1, optimizer2]
    assert set(p for opt in optimizers for group in opt.param_groups
               for p in group["params"]) == set(model.parameters())
    for opt in optimizers:
        for group in opt.param_groups:
            group["initial_lr"] = group["lr"]

    # learning rate schedule: stable then decay
    def set_hparams(step, cooldown_frac=0.7):
        progress = step / train_steps
        assert 0 <= progress < 1
        if progress < 1 - cooldown_frac:
            eta = 1.0
        else:
            eta = (1 - progress) / cooldown_frac
        if MU_COOLDOWN_ENABLED:
            if step < MU_WARMUP_STEPS:
                w = step / MU_WARMUP_STEPS
                cur_mu = MU_WARMUP_START + (MU_COOLDOWN_START - MU_WARMUP_START) * w
            elif progress < 1 - cooldown_frac:
                cur_mu = MU_COOLDOWN_START
            else:
                t = (progress - (1 - cooldown_frac)) / cooldown_frac
                cur_mu = MU_COOLDOWN_START + (MU_COOLDOWN_END - MU_COOLDOWN_START) * t
        else:
            cur_mu = MU + (MU_END - MU) * progress
        for opt in optimizers:
            for group in opt.param_groups:
                group["lr"] = group["initial_lr"] * eta
                if group.get("name") == "muon_blocks":
                    group["mu"] = cur_mu


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
            )
        for opt in optimizers:
            opt.step()
        # PR #1754 (embed) + PR #1824 (lm_head) + PR #1921 (FACTOR): per-kind AdamW moment reset hooks.
        # Both blocks are independent — both can fire on the same step if intervals align.
        # factor in [0,1]: state.mul_(factor). factor=0.0 → legacy full zero; factor=1.0 → no-op.
        def _per_kind_reset(group_name: str, moment_mode: int, interval: int, factor: float, label: str) -> None:
            if interval <= 0 or step <= 0 or (step % interval) != 0:
                return
            params_reset_avg = 0
            params_reset_sq = 0
            pre_exp_avg_sq_sum = 0.0
            pre_exp_avg_sum = 0.0
            for g in optimizer1.param_groups:
                if g.get("name") == group_name:
                    for p in g["params"]:
                        st = optimizer1.state.get(p, {})
                        if "exp_avg" in st:
                            pre_exp_avg_sum += float(st["exp_avg"].float().square().sum().item())
                        if "exp_avg_sq" in st:
                            pre_exp_avg_sq_sum += float(st["exp_avg_sq"].float().square().sum().item())
                        # MOMENT=0 → both (legacy), MOMENT=1 → exp_avg_sq only, MOMENT=2 → exp_avg only, MOMENT=3 → both (bitfield)
                        if moment_mode in (0, 2, 3) and "exp_avg" in st:
                            if factor == 0.0:
                                st["exp_avg"].zero_()
                            else:
                                st["exp_avg"].mul_(factor)
                            params_reset_avg += 1
                        if moment_mode in (0, 1, 3) and "exp_avg_sq" in st:
                            if factor == 0.0:
                                st["exp_avg_sq"].zero_()
                            else:
                                st["exp_avg_sq"].mul_(factor)
                            params_reset_sq += 1
                    break
            post_exp_avg_sq_sum = 0.0
            post_exp_avg_sum = 0.0
            for g in optimizer1.param_groups:
                if g.get("name") == group_name:
                    for p in g["params"]:
                        st = optimizer1.state.get(p, {})
                        if "exp_avg" in st:
                            post_exp_avg_sum += float(st["exp_avg"].float().square().sum().item())
                        if "exp_avg_sq" in st:
                            post_exp_avg_sq_sum += float(st["exp_avg_sq"].float().square().sum().item())
                    break
            if dist.get_rank() == 0:
                pre_avg_norm = pre_exp_avg_sum ** 0.5
                post_avg_norm = post_exp_avg_sum ** 0.5
                pre_sq_norm = pre_exp_avg_sq_sum ** 0.5
                post_sq_norm = post_exp_avg_sq_sum ** 0.5
                wandb.log(
                    {
                        "trial": trial_idx,
                        "train/step": train_step,
                        f"{label}/exp_avg.norm_pre": pre_avg_norm,
                        f"{label}/exp_avg.norm_post": post_avg_norm,
                        f"{label}/exp_avg_sq.norm_pre": pre_sq_norm,
                        f"{label}/exp_avg_sq.norm_post": post_sq_norm,
                        f"{label}/reset_event_step": step,
                        f"{label}/reset_event_moment": moment_mode,
                        f"{label}/reset_event_factor": factor,
                    },
                    step=wandb_step,
                )
                print(
                    f"[PER_KIND_AUX_PERIODIC_RESET] step {step}: {label} AdamW state reset"
                    f" (moment={moment_mode}, factor={factor}, exp_avg reset={params_reset_avg},"
                    f" exp_avg_sq reset={params_reset_sq},"
                    f" exp_avg.norm pre={pre_avg_norm:.4f} post={post_avg_norm:.4f},"
                    f" exp_avg_sq.norm pre={pre_sq_norm:.4f} post={post_sq_norm:.4f})",
                    flush=True,
                )

        if PER_KIND_AUX_PERIODIC_RESET_EMBED_ENABLED:
            _per_kind_reset("adam_embed", AUX_RESET_MOMENT_EMBED, AUX_RESET_INTERVAL_EMBED, AUX_RESET_FACTOR_EMBED, "embed")
        if PER_KIND_AUX_PERIODIC_RESET_LM_HEAD_ENABLED:
            _per_kind_reset("adam_lm_head", AUX_RESET_MOMENT_LM_HEAD, AUX_RESET_INTERVAL_LM_HEAD, AUX_RESET_FACTOR_LM_HEAD, "lm_head")
        if dist.get_rank() == 0 and telemetry_due:
            for opt in optimizers:
                if hasattr(opt, "trust_gate_stats"):
                    stats = opt.trust_gate_stats()
                    if stats:
                        wandb.log(prefixed("train/attn_soap_trust_gate", stats), step=wandb_step)
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
