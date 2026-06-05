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
    parser.add_argument("--train_steps", type=int, default=2930,
                        help="Number of optimizer steps per trial (default 2930 matches PR #300 declared step)")
    parser.add_argument("--seed", type=int, default=0,
                        help="Base seed; trial i uses seed (--seed + i)")
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
    if args.train_steps < 1:
        raise ValueError("--train_steps must be positive")
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
        # float32 linspace can produce an endpoint one larger than numel-1 once numel
        # exceeds float32 integer precision (>~16M). Clamp before indexing.
        idx = torch.linspace(0, values.numel() - 1, max_samples, device=values.device).long()
        idx.clamp_(max=values.numel() - 1)
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


def log_pmuon_telemetry(
    optimizer,
    trial_idx: int,
    step: int,
    wandb_step: int,
):
    """Aggregate L/R covariance EMA stats across all Muon-routed params.

    Logs eigenvalue spread and condition number proxies so the advisor can verify
    the bilateral whitening is healthy and not collapsing to identity (cold start)
    or blowing up (rank deficiency).
    """
    l_max_eigs: list[float] = []
    l_min_eigs: list[float] = []
    l_traces: list[float] = []
    l_fros: list[float] = []
    r_max_eigs: list[float] = []
    r_min_eigs: list[float] = []
    r_traces: list[float] = []
    r_fros: list[float] = []
    for group in optimizer.param_groups:
        for p in group["params"]:
            state = optimizer.state.get(p, {})
            if "L" not in state or "R" not in state:
                continue
            L = state["L"]
            R = state["R"]
            with torch.no_grad():
                l_fro = float(L.norm().item())
                r_fro = float(R.norm().item())
                l_traces.append(float(L.diagonal().sum().item()))
                r_traces.append(float(R.diagonal().sum().item()))
                l_fros.append(l_fro)
                r_fros.append(r_fro)
                # Cheap eigenvalue range via power iteration would be costly here;
                # use trace bounds as a proxy. trace >= max_eig, trace/n <= mean_eig.
                # Better: take an eigh on a sample of layers (skip for now to keep telemetry cheap).
    metrics: dict[str, float] = {
        "trial": trial_idx,
        "train/step": step,
    }
    if l_fros:
        l_fro_t = torch.tensor(l_fros)
        r_fro_t = torch.tensor(r_fros)
        l_tr_t = torch.tensor(l_traces)
        r_tr_t = torch.tensor(r_traces)
        metrics.update({
            "train/pmuon/L_fro_mean": float(l_fro_t.mean()),
            "train/pmuon/L_fro_min": float(l_fro_t.min()),
            "train/pmuon/L_fro_max": float(l_fro_t.max()),
            "train/pmuon/R_fro_mean": float(r_fro_t.mean()),
            "train/pmuon/R_fro_min": float(r_fro_t.min()),
            "train/pmuon/R_fro_max": float(r_fro_t.max()),
            "train/pmuon/L_trace_mean": float(l_tr_t.mean()),
            "train/pmuon/R_trace_mean": float(r_tr_t.mean()),
            "train/pmuon/num_pmuon_params": float(len(l_fros)),
        })
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

# --- PR #300 / KellerJordan Aurora-on-mlp.proj + Contra-Muon extended + radial brake stack ---
# Aurora row-balanced polar (only applied to wide matrices, i.e. mlp.proj 768x3072 here).
_AURORA_K = 3
_AURORA_BETA = 0.25
_AURORA_EPS = 1e-7

# Contra-Muon -> Soft-Muon ramp parameters. Soft-Muon is disabled via SOFT_MUON_CEIL=0.
CONTRA_MUON_COEFF = -0.2
CONTRA_HOLD_END_STEP = 0
CONTRA_TO_NORMAL_END_STEP = 2500  # PR #300 extends to 2500
NORMAL_TO_SOFT_START_STEP = 2500
NORMAL_TO_SOFT_END_STEP = 3010
SOFT_MUON_P = 0.1
SOFT_MUON_SCALE = "none"
SOFT_MUON_INPUT_NORM = "frobenius_schatten4"
SOFT_MUON_CEIL = 0.00  # disabled

# NorMuon-lite (per-row variance EMA). PR #300 disables via NOR_BETA2=1.0.
NOR_BETA2 = 1.0

# Muon hyperparameters (Skylight + PR #300).
MU = 0.95
MUON_LR = 0.0375
MUON_WEIGHT_DECAY = 0.025
TARGET_UW = 0.3825
SOAP_TARGET_UW = TARGET_UW
NONSOAP_TARGET_UW = TARGET_UW

# SOAP preconditioning (mlp_plus_v: mlp.fc, mlp.proj, attn.v).
SOAP_BETA2 = 0.90
SOAP_PRECONDITION_FREQUENCY = 10
SOAP_DENOM_POWER = 0.50
SOAP_BLEND = 1.00
SOAP_UPDATE_BEFORE_USE = False
SOAP_PARAM_MODE = "mlp_plus_v"
ATTN_SOAP_DENOM_FLOOR = 0.55
ATTN_SOAP_BLEND = 1.00
V_SOAP_BLEND = 0.95
V_SOAP_BLEND_RAMP_END_STEP = 0
ATTN_EARLY_TRUST_FLOOR = 0.45
ATTN_EARLY_TRUST_CAP = 0.85
ATTN_TRUST_FLOOR_END_STEP = 1375
ATTN_TRUST_FLOOR_FADE_END_STEP = 1625
ATTN_TRUST_MIN_AGREE = 0.20
ATTN_TRUST_MIN_GRAD_ALIGN = 0.00
ATTN_TRUST_POWER = 1.00
ATTN_SOAP_FADE_START_STEP = 1_000_000_000
ATTN_SOAP_FADE_END_STEP = 1_000_000_000
NO_CONTRA_PARAM = ""
NO_SOFTMUON_PARAM = ""

# Radial brake (PR #294 / #300): dampens outward radial component before u/w floor.
RADIAL_OUTWARD_SCALE = 0.5
RADIAL_INWARD_SCALE = 1.0

# Muon mu (momentum) schedule: warmup then cooldown around the LR cooldown.
_MU_MIN = 0.85
_MU_MAX = 0.95
_MU_WARMUP_STEPS = 300
_MU_COOLDOWN_STEPS = 100
# Anchor mu cooldown to PR #300's FINAL_TRAIN_STEPS so an early stop at e.g. 2930
# sees the same mu profile as PR #300 (cd_start = 3020-100 = 2920). Without this
# anchor, args.train_steps=2930 would put cd_start at 2830 and apply a much more
# aggressive 100-step cooldown vs PR #300's near-zero cooldown at step 2930,
# making the Circuit-Muon comparison non-apples-to-apples.
_MU_COOLDOWN_REF_STEPS = 3020

# PR #287 power-law LR cooldown. schedule_steps is the t_end of the power-law and
# is kept at PR #300's value (3050) so that an early stop at e.g. 2930 sees the same
# LR profile as PR #300 did at step 2930 during its 3020-step run.
FINAL_SCHEDULE_STEPS = 3050
FINAL_LR_POWER = 1.2
ADAM_EMBED_POWER_C = 4.976805410800738e-05
ADAM_PROJ_POWER_C = 5.184172302917436e-07
ADAM_OTHER_POWER_C = 1.6589351369335795e-06
MUON_POWER_C = 3.3169534699576625e-06

# Init mods (from prior speedrun lineage), kept exact to PR #300.
_DI_FC_ALPHA = 0.30
_CGI_ALPHA = 0.14

# --- PMuon (Senpai PR #64 by fern; canonical PMuon mechanism in the audited #1532/#1614 stack) ---
# Streaming raw (unnormalized) bilateral covariance EMAs preconditioning the
# Nesterov-blended momentum, applied PRE-NS for all 2D Muon-routed params.
PMUON_BETA_COV = 0.95
PMUON_GAMMA = 0.3
PMUON_EPS = 1e-12
# PMuon eigendecomposition refresh cadence. PR #64 refreshes per step (cadence=1).
# For 3072x3072 eigh this costs ~5-10ms per step; SOAP uses cadence=10 for a similar tradeoff.
# We follow PR #64 (every step) so PMuon's L^{-γ}/R^{-γ} stay tight with the
# streaming EMAs. If wall-clock becomes a bottleneck we can amortize later.


def gram_frobenius_norm_estimate(G: Tensor, keepdim: bool = False, eps: float = 1e-10) -> Tensor:
    X = G.float()
    gram = X.mT @ X if X.size(-2) > X.size(-1) else X @ X.mT
    return gram.norm(dim=(-2, -1), keepdim=keepdim).sqrt().clamp_min(eps)


def _ns_inner(X: Tensor) -> Tensor:
    a, b, c = 2, -1.5, 0.5
    for _ in range(12):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
    return X


def zeropower_via_newtonschulz5(G: Tensor) -> Tensor:
    """Aurora row-balanced polar on wide matrices (mlp.proj); plain NS-5 otherwise."""
    assert G.ndim >= 2
    is_originally_wide = G.size(-2) < G.size(-1)
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT

    if is_originally_wide:
        Xt = X.mT
        Xt32 = Xt.to(torch.float32)
        target_row_sq = Xt.size(-1) / Xt.size(-2)
        row_norm = Xt32.norm(dim=-1, keepdim=True).clamp_(min=_AURORA_EPS)
        D = 1.0 / row_norm
        U = None
        for k in range(_AURORA_K):
            scaled = (D * Xt32).to(Xt.dtype)
            scaled_wide = scaled.mT
            scaled_wide = scaled_wide / gram_frobenius_norm_estimate(scaled_wide, keepdim=True, eps=1e-7).to(scaled_wide.dtype)
            U_wide = _ns_inner(scaled_wide)
            U = U_wide.mT
            if k < _AURORA_K - 1:
                U32 = U.to(torch.float32)
                row_sq = U32.pow(2).sum(dim=-1, keepdim=True).clamp_(min=_AURORA_EPS * _AURORA_EPS)
                D = D * (target_row_sq / row_sq).pow(_AURORA_BETA)
        X = U.mT
    else:
        X = X / gram_frobenius_norm_estimate(X, keepdim=True, eps=1e-7).to(X.dtype)
        X = _ns_inner(X)

    if G.size(-2) > G.size(-1):
        X = X.mT
    return X


def _soft_coefficients(p: float):
    if p == 0.0:
        return 1.0, (0.0,) * 12
    if p == 0.1:
        return 0.0, (0.1091613623, 0.07085664498, 0.05210528973, 0.05457295795,
                     0.05011334061, 0.03334622198, 0.05022104481, 0.1053727358,
                     0.1187323776, 0.1185061091, 0.1185059576, 0.1185059576)
    raise ValueError(f"unsupported soft-muon singular-value power: {p}")


def zeropower_frobenius_norm_like(G: Tensor) -> float:
    return (G.numel() / max(G.size(-2), G.size(-1)))**0.5


def soft_via_newtonschulz5(G: Tensor, p: float, scale_mode: str, input_norm: str) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT

    if input_norm in ("frobenius_schatten4", "frobenius"):
        X = X / gram_frobenius_norm_estimate(X, keepdim=True, eps=1e-7).to(X.dtype)
    else:
        raise ValueError(f"unsupported soft_muon input_norm: {input_norm}")
    constant, coeffs = _soft_coefficients(p)

    a, b, c = 2, -1.5, 0.5
    basis = [X]
    for _ in range(len(coeffs)):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
        basis.append(X)

    out = constant * basis[-1]
    for coeff, basis_term in zip(coeffs, basis[:-1]):
        out = out + coeff * basis_term

    value_at_one = constant + sum(coeffs)
    if scale_mode == "top":
        out = out / value_at_one
    elif scale_mode == "top_sqrt":
        out = out / value_at_one**0.5
    elif scale_mode == "frobenius":
        theoretical_opower_norm = zeropower_frobenius_norm_like(out)
        out = out * theoretical_opower_norm / gram_frobenius_norm_estimate(out)
    elif scale_mode == "frobenius_sqrt":
        theoretical_opower_norm = zeropower_frobenius_norm_like(out)
        out = out * (theoretical_opower_norm / gram_frobenius_norm_estimate(out))**0.5
    elif scale_mode != "none":
        raise ValueError(f"unsupported soft_muon scale: {scale_mode}")

    if G.size(-2) > G.size(-1):
        out = out.mT
    return out


def scale_to_unit_operator_norm(G: Tensor, eps: float = 1e-10) -> Tensor:
    return G / gram_frobenius_norm_estimate(G, eps=eps).to(G.dtype)


def should_soap_param(name: str) -> bool:
    is_mlp_fc = name.endswith(".mlp.fc.weight")
    is_mlp_proj = name.endswith(".mlp.proj.weight")
    is_v = name.endswith(".attn.v.weight")
    if SOAP_PARAM_MODE == "mlp_plus_v":
        return is_mlp_fc or is_mlp_proj or is_v
    raise ValueError(f"unknown SOAP_PARAM_MODE={SOAP_PARAM_MODE}")


def is_attn_proj_param(name: str) -> bool:
    return name.endswith(".attn.proj.weight")


def is_attn_param(name: str) -> bool:
    return (
        name.endswith(".attn.q.weight")
        or name.endswith(".attn.k.weight")
        or name.endswith(".attn.v.weight")
        or name.endswith(".attn.proj.weight")
    )


def is_v_param(name: str) -> bool:
    return name.endswith(".attn.v.weight")


def param_matches_spec(name: str, spec: str) -> bool:
    keys = {part.strip() for part in spec.split(",") if part.strip()}
    return (
        ("q" in keys and name.endswith(".attn.q.weight"))
        or ("k" in keys and name.endswith(".attn.k.weight"))
        or ("v" in keys and name.endswith(".attn.v.weight"))
        or ("attn_proj" in keys and name.endswith(".attn.proj.weight"))
    )


def tensor_cosine(a: Tensor, b: Tensor, eps: float = 1e-8) -> Tensor:
    a_f, b_f = a.float(), b.float()
    return (a_f * b_f).sum() / (a_f.norm() * b_f.norm()).clamp_min(eps)


def trust_gate(raw: Tensor, soap: Tensor, grad: Tensor, eps: float = 1e-8) -> Tensor:
    raw_grad = tensor_cosine(raw, grad, eps)
    soap_grad = tensor_cosine(soap, grad, eps)
    soap_raw = tensor_cosine(soap, raw, eps)
    agree_gate = ((soap_raw - ATTN_TRUST_MIN_AGREE) / (1 - ATTN_TRUST_MIN_AGREE)).clamp(0, 1)
    denom = (raw_grad - ATTN_TRUST_MIN_GRAD_ALIGN).clamp_min(eps)
    grad_gate = ((soap_grad - ATTN_TRUST_MIN_GRAD_ALIGN) / denom).clamp(0, 1)
    gate = (agree_gate * grad_gate).clamp(0, 1)
    if ATTN_TRUST_POWER != 1.0:
        gate = gate.pow(ATTN_TRUST_POWER)
    return gate


def early_trust_floor_for_step(step: int) -> float:
    if ATTN_TRUST_FLOOR_FADE_END_STEP <= ATTN_TRUST_FLOOR_END_STEP:
        return 0.0 if step >= ATTN_TRUST_FLOOR_FADE_END_STEP else ATTN_EARLY_TRUST_FLOOR
    if step < ATTN_TRUST_FLOOR_END_STEP:
        return ATTN_EARLY_TRUST_FLOOR
    if step >= ATTN_TRUST_FLOOR_FADE_END_STEP:
        return 0.0
    return ATTN_EARLY_TRUST_FLOOR * (
        ATTN_TRUST_FLOOR_FADE_END_STEP - step
    ) / (ATTN_TRUST_FLOOR_FADE_END_STEP - ATTN_TRUST_FLOOR_END_STEP)


def bounded_trust_gate(gate: Tensor, step: int) -> Tensor:
    floor = early_trust_floor_for_step(step)
    cap = ATTN_EARLY_TRUST_CAP if step < ATTN_TRUST_FLOOR_FADE_END_STEP else 1.0
    return gate.clamp(min=floor, max=cap)


def attention_soap_blend_for_step(step: int) -> float:
    if step < ATTN_SOAP_FADE_START_STEP:
        return 1.0
    if step >= ATTN_SOAP_FADE_END_STEP:
        return 0.0
    if ATTN_SOAP_FADE_END_STEP <= ATTN_SOAP_FADE_START_STEP:
        return 0.0
    return (
        ATTN_SOAP_FADE_END_STEP - step
    ) / (ATTN_SOAP_FADE_END_STEP - ATTN_SOAP_FADE_START_STEP)


def norm_preserving_blend(raw: Tensor, soap: Tensor, gate: Tensor, eps: float = 1e-8) -> Tensor:
    blended = raw + (soap - raw) * gate.to(raw.dtype)
    raw_norm = gram_frobenius_norm_estimate(raw, eps=eps)
    blended_norm = gram_frobenius_norm_estimate(blended, eps=eps)
    return (blended * (raw_norm / blended_norm).to(blended.dtype)).to(raw.dtype)


def scale_radial_update(update: Tensor, param: Tensor, eps: float = 1e-12) -> Tensor:
    update_f = update.float()
    param_f = param.float()
    denom = (param_f * param_f).sum().clamp_min(eps)
    coeff = (update_f * param_f).sum() / denom
    radial = coeff * param_f
    tangential = update_f - radial
    radial_scale = torch.where(
        coeff < 0,
        update_f.new_tensor(RADIAL_OUTWARD_SCALE),
        update_f.new_tensor(RADIAL_INWARD_SCALE),
    )
    return (tangential + radial_scale * radial).to(update.dtype)


def target_radius_after_update(param: Tensor, update: Tensor, lr: float, eps: float = 1e-8) -> Tensor:
    param_f = param.float()
    update_f = update.float()
    before_norm = param_f.norm().clamp_min(eps)
    radial_delta = -lr * (update_f * param_f).sum() / before_norm
    return (before_norm + radial_delta).clamp_min(eps)


def rescale_to_radius(param: Tensor, target_norm: Tensor, eps: float = 1e-8):
    after_norm = param.float().norm().clamp_min(eps)
    param.mul_((target_norm / after_norm).to(param.dtype))


def soap_eigenbasis(mat: Tensor) -> Tensor:
    try:
        _, q = torch.linalg.eigh(mat + 1e-30 * torch.eye(mat.size(0), device=mat.device))
    except RuntimeError:
        _, q = torch.linalg.eigh(mat.double() + 1e-30 * torch.eye(mat.size(0), device=mat.device))
        q = q.float()
    return torch.flip(q, [1])


def soap_basis_qr(row_gg, col_gg, q_row, q_col, exp_avg_sq):
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


def soap_precondition_momentum(update, state, beta2=SOAP_BETA2, eps=1e-8,
                               blend=SOAP_BLEND, denom_floor_ratio=0.0):
    update_f = update.float()
    if state["q_row"] is None:
        return update
    q_row, q_col = state["q_row"], state["q_col"]
    projected = q_row.T @ update_f @ q_col
    state["exp_avg_sq"].mul_(beta2).add_(projected.square(), alpha=1 - beta2)
    denom = state["exp_avg_sq"].clamp_min(eps * eps).pow(SOAP_DENOM_POWER)
    if denom_floor_ratio > 0:
        denom_floor = denom.float().square().mean().sqrt().mul(denom_floor_ratio).clamp_min(eps)
        denom = denom.clamp_min(denom_floor.to(denom.dtype))
    precond = q_row @ (projected / denom) @ q_col.T
    if blend != 1.0:
        precond = blend * precond + (1 - blend) * update_f
    precond.mul_(gram_frobenius_norm_estimate(update_f, eps=eps) / gram_frobenius_norm_estimate(precond, eps=eps))
    return precond.to(update.dtype)


def soap_update_preconditioner(grad, state, shampoo_beta=SOAP_BETA2, precondition_frequency=SOAP_PRECONDITION_FREQUENCY):
    grad_f = grad.float()
    state["row_gg"].lerp_(grad_f @ grad_f.T, 1 - shampoo_beta)
    state["col_gg"].lerp_(grad_f.T @ grad_f, 1 - shampoo_beta)
    if state["q_row"] is None:
        state["q_row"] = soap_eigenbasis(state["row_gg"])
        state["q_col"] = soap_eigenbasis(state["col_gg"])
    elif state["soap_step"] > 0 and state["soap_step"] % precondition_frequency == 0:
        state["q_row"], state["q_col"], state["exp_avg_sq"] = soap_basis_qr(
            state["row_gg"], state["col_gg"], state["q_row"], state["q_col"], state["exp_avg_sq"]
        )
    state["soap_step"] += 1


def _linear_ramp(step: int, start_step: int, end_step: int) -> float:
    if end_step <= start_step:
        return 1.0 if step >= end_step else 0.0
    return min(1.0, max(0.0, (step - start_step) / (end_step - start_step)))


def contra_coeff_for_step(step: int) -> float:
    contra_to_normal = _linear_ramp(step, CONTRA_HOLD_END_STEP, CONTRA_TO_NORMAL_END_STEP)
    return CONTRA_MUON_COEFF * (1.0 - contra_to_normal)


def soft_blend_for_step(step: int) -> float:
    return min(SOFT_MUON_CEIL, _linear_ramp(step, NORMAL_TO_SOFT_START_STEP, NORMAL_TO_SOFT_END_STEP))


def muon_update(update, second_moment, step, beta2=NOR_BETA2, use_contra=True, use_soft=True):
    normalized_grad = scale_to_unit_operator_norm(update.clone())
    ns_update = zeropower_via_newtonschulz5(update)
    update_norm_estimate = gram_frobenius_norm_estimate(ns_update)

    contra_coeff = contra_coeff_for_step(step) if use_contra else 0.0
    contra_update = ns_update + contra_coeff * normalized_grad
    contra_update = contra_update * update_norm_estimate / gram_frobenius_norm_estimate(contra_update)
    if use_soft:
        soft_update = soft_via_newtonschulz5(update, SOFT_MUON_P, SOFT_MUON_SCALE, SOFT_MUON_INPUT_NORM)
        soft_update = soft_update * update_norm_estimate / gram_frobenius_norm_estimate(soft_update)
        blend = soft_blend_for_step(step)
    else:
        soft_update = contra_update
        blend = 0.0
    update = contra_update + (soft_update - contra_update) * blend
    update = update * update_norm_estimate / gram_frobenius_norm_estimate(update)
    update *= max(1, update.size(-2) / update.size(-1))**0.5
    if update.size(-2) >= update.size(-1):
        per_row_var = (update * update).mean(dim=-1, keepdim=True)
    else:
        per_row_var = (update * update).mean(dim=-2, keepdim=True)
    second_moment.lerp_(per_row_var.float(), 1 - beta2)
    vnorm = gram_frobenius_norm_estimate(update)
    update = update * second_moment.clamp_min(1e-10).rsqrt().to(update.dtype)
    vnorm_new = gram_frobenius_norm_estimate(update)
    update = update * (vnorm / vnorm_new)
    return update


def matrix_neg_power(M: Tensor, gamma: float, eps: float = PMUON_EPS) -> Tensor:
    """Symmetric PSD M -> M^{-gamma} via eigendecomposition.

    eps clamp on eigenvalues handles rank deficiency at trial start when L/R EMAs
    are near-zero. Matches PR #64 (fern) verbatim except that gamma/eps are wired
    through as kwargs instead of module-level constants.
    """
    M = 0.5 * (M + M.T)
    eigvals, eigvecs = torch.linalg.eigh(M)
    eigvals = eigvals.clamp_min(eps).pow(-gamma)
    return (eigvecs * eigvals) @ eigvecs.T


class Muon(torch.optim.Optimizer):
    def __init__(self, named_params, lr=0.02, weight_decay=0, mu=0.95,
                 beta_cov=PMUON_BETA_COV, gamma=PMUON_GAMMA, eps=PMUON_EPS):
        assert isinstance(named_params, list) and len(named_params) >= 1
        self.soap_params = {p for n, p in named_params if should_soap_param(n)}
        self.attn_soap_params = {p for n, p in named_params if should_soap_param(n) and is_attn_param(n)}
        self.attn_proj_soap_params = {p for n, p in named_params if should_soap_param(n) and is_attn_proj_param(n)}
        self.v_params = {p for n, p in named_params if is_v_param(n)}
        self.no_contra_params = {p for n, p in named_params if param_matches_spec(n, NO_CONTRA_PARAM)}
        self.no_soft_params = {p for n, p in named_params if param_matches_spec(n, NO_SOFTMUON_PARAM)}
        self.step_count = 0
        params = sorted([p for _, p in named_params], key=lambda x: x.size(), reverse=True)
        defaults = dict(lr=lr, weight_decay=weight_decay, mu=mu,
                        beta_cov=beta_cov, gamma=gamma, eps=eps)
        super().__init__(params, defaults)

    def _ensure_state(self, p):
        state = self.state[p]
        if len(state) == 0:
            state["momentum"] = torch.zeros_like(p)
            # PMuon (PR #64) streaming bilateral covariance EMAs in float32.
            # Identity-init guarantees L^{-γ}/R^{-γ} are well-conditioned at step 1,
            # avoiding the step-1 NS crash seen on PR #309 base + Muon mechanisms.
            # L_t = β L_{t-1} + G G^T grows by accumulated gradient energy; starting
            # from I gives M^{-γ} = I at step 0 so the first whitened momentum_update
            # equals the unconditioned momentum_update.
            state["L"] = torch.eye(p.size(0), dtype=torch.float32, device=p.device)
            state["R"] = torch.eye(p.size(1), dtype=torch.float32, device=p.device)
            if p in self.soap_params:
                state["exp_avg_sq"] = torch.zeros_like(p, dtype=torch.float32)
                state["row_gg"] = torch.zeros(p.size(0), p.size(0), dtype=torch.float32, device=p.device)
                state["col_gg"] = torch.zeros(p.size(1), p.size(1), dtype=torch.float32, device=p.device)
                state["q_row"] = None
                state["q_col"] = None
                state["soap_step"] = 0
            if p.size(-2) >= p.size(-1):
                state["second_moment"] = torch.zeros((*p.shape[:-1], 1),
                    dtype=torch.float32, device=p.device)
            else:
                state["second_moment"] = torch.zeros((*p.shape[:-2], 1, p.shape[-1]),
                    dtype=torch.float32, device=p.device)

    def _direction(self, p, group):
        """momentum -> SOAP -> PMuon whitening -> muon_update; returns the raw (pre-radial) update.

        Composition order rationale (H14 / PR #2294):
          - SOAP rotating-basis preconditioning is applied first (when active);
            it operates on the Nesterov-blended momentum in a learned basis.
          - PMuon bilateral whitening m_pre = L^{-γ} m R^{-γ} is applied PRE-NS to
            the (possibly SOAP-preconditioned) momentum. The L/R covariance EMAs
            use the RAW gradient (per PR #64 fern), not the SOAP-blended update.
          - The whitened m_pre is then passed to muon_update where Aurora NS5
            (on wide mlp.proj) and Contra-Muon (post-NS attention contrastive)
            run unchanged. Contra-Muon's normalized_grad uses the PMuon-whitened
            input, which is consistent with treating PMuon as a refinement of the
            "effective gradient" the NS pipeline sees.
        """
        state = self.state[p]
        grad = p.grad
        state["momentum"].lerp_(grad, 1 - group["mu"])
        momentum_update = grad.lerp(state["momentum"], group["mu"])
        is_attn_soap = p in self.attn_soap_params
        use_soap = p in self.soap_params
        if use_soap and SOAP_UPDATE_BEFORE_USE:
            soap_update_preconditioner(grad, state)
        if use_soap:
            if is_attn_soap:
                soap_blend = V_SOAP_BLEND if p in self.v_params else ATTN_SOAP_BLEND
                if p in self.v_params and V_SOAP_BLEND_RAMP_END_STEP > 0:
                    soap_blend *= _linear_ramp(self.step_count, 0, V_SOAP_BLEND_RAMP_END_STEP)
                soap_update = soap_precondition_momentum(
                    momentum_update, state, blend=soap_blend,
                    denom_floor_ratio=ATTN_SOAP_DENOM_FLOOR
                )
                if p in self.attn_proj_soap_params:
                    gate = bounded_trust_gate(
                        trust_gate(momentum_update, soap_update, grad),
                        self.step_count
                    )
                else:
                    gate = torch.ones((), dtype=torch.float32, device=p.device)
                gate = gate * attention_soap_blend_for_step(self.step_count)
                momentum_update = norm_preserving_blend(momentum_update, soap_update, gate)
            else:
                momentum_update = soap_precondition_momentum(momentum_update, state, blend=SOAP_BLEND)

        # PMuon bilateral whitening (PR #64). Update L/R from RAW gradient, then
        # apply L^{-γ} @ momentum_update @ R^{-γ}. Keep covariance EMAs in float32.
        g32 = grad.detach().float()
        state["L"].mul_(group["beta_cov"]).add_(g32 @ g32.T)
        state["R"].mul_(group["beta_cov"]).add_(g32.T @ g32)
        L_neg = matrix_neg_power(state["L"], group["gamma"], group["eps"])
        R_neg = matrix_neg_power(state["R"], group["gamma"], group["eps"])
        m_pre = (L_neg @ momentum_update.float()) @ R_neg
        momentum_update = m_pre.to(momentum_update.dtype)

        return muon_update(
            momentum_update,
            state["second_moment"],
            self.step_count,
            use_contra=p not in self.no_contra_params,
            use_soft=p not in self.no_soft_params,
        )

    def _finish(self, p, group, update):
        """radial scale -> u/w floor -> apply -> radius correction -> SOAP refresh."""
        use_soap = p in self.soap_params
        update = scale_radial_update(update, p)
        p_fro = p.float().norm().clamp_min(1e-8)
        u_fro = update.float().norm().clamp_min(1e-8)
        cur_uw = u_fro / p_fro
        target_uw = SOAP_TARGET_UW if use_soap else NONSOAP_TARGET_UW
        scale = torch.where(cur_uw < target_uw, target_uw * p_fro / u_fro, torch.ones_like(p_fro))
        update = update * scale.to(update.dtype)
        target_radius = target_radius_after_update(p, update, group["lr"])
        p.add_(update, alpha=-group["lr"])
        rescale_to_radius(p, target_radius)
        if use_soap and not SOAP_UPDATE_BEFORE_USE:
            soap_update_preconditioner(p.grad, self.state[p])

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
                    self._ensure_state(p)
                    update = self._direction(p, group)
                    self._finish(p, group, update)
                dist.all_gather(params_pad[base_i:base_i + world_size], params_pad[base_i + rank])
        self.step_count += 1


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
            "train_steps": args.train_steps,
            "base_seed": args.seed,
            "world_size": dist.get_world_size(),
            "batch_size_tokens": batch_size,
            "microbatch_sequences": mbs,
            "val_tokens": val_tokens,
            "telemetry_interval": args.telemetry_interval,
            "histogram_interval": args.histogram_interval,
            "histogram_samples": args.histogram_samples,
            "param_histogram_limit": args.param_histogram_limit,
            "slope_fraction": SLOPE_FRACTION,
            # PR #300 stack
            "experiment": "pmuon-pr300-base",
            "muon_lr": MUON_LR,
            "muon_weight_decay": MUON_WEIGHT_DECAY,
            "mu_mid": MU,
            "mu_min": _MU_MIN,
            "mu_max": _MU_MAX,
            "mu_warmup_steps": _MU_WARMUP_STEPS,
            "mu_cooldown_steps": _MU_COOLDOWN_STEPS,
            "mu_cooldown_ref_steps": _MU_COOLDOWN_REF_STEPS,
            "target_uw": TARGET_UW,
            "contra_muon_coeff": CONTRA_MUON_COEFF,
            "contra_to_normal_end_step": CONTRA_TO_NORMAL_END_STEP,
            "soft_muon_ceil": SOFT_MUON_CEIL,
            "nor_beta2": NOR_BETA2,
            "soap_param_mode": SOAP_PARAM_MODE,
            "v_soap_blend": V_SOAP_BLEND,
            "radial_outward_scale": RADIAL_OUTWARD_SCALE,
            "radial_inward_scale": RADIAL_INWARD_SCALE,
            "aurora_K": _AURORA_K,
            "aurora_beta": _AURORA_BETA,
            "final_schedule_steps": FINAL_SCHEDULE_STEPS,
            "final_lr_power": FINAL_LR_POWER,
            "di_fc_alpha": _DI_FC_ALPHA,
            "cgi_alpha": _CGI_ALPHA,
            # PMuon (Senpai PR #64 by fern)
            "pmuon_beta_cov": PMUON_BETA_COV,
            "pmuon_gamma": PMUON_GAMMA,
            "pmuon_eps": PMUON_EPS,
            "pmuon_init": "identity",
            "pmuon_pipeline_position": "pre-NS, after SOAP, before Contra-Muon",
        },
    )

for trial_idx in range(args.num_trials):


    ########################################
    #       Init & Optim Hyperparams       #
    ########################################

    # Per-trial reproducibility: trial i uses seed (args.seed + i).
    torch.manual_seed(args.seed + trial_idx)

    train_steps = args.train_steps

    # Reset all parameters to fresh init each trial. The model is created once so
    # trial 1+ would otherwise start from trial 0's trained weights. nn.Linear and
    # nn.Embedding use reset_parameters(); RMSNorm gains go back to 1.
    with torch.no_grad():
        for m in model.modules():
            if isinstance(m, (nn.Linear, nn.Embedding)):
                m.reset_parameters()
            elif isinstance(m, RMSNorm):
                m.gains.data.fill_(1.0)

    # PR #300 init: zero all "proj" weights and biases.
    for name, p in model.named_parameters():
        if "proj" in name:
            p.data.zero_()

    # Depth-scaled mlp.fc init (alpha=0.30) — DI-fc.
    num_blocks = len(model.blocks)
    with torch.no_grad():
        for l_idx, block in enumerate(model.blocks):
            ramp = l_idx / (num_blocks - 1) if num_blocks > 1 else 0.0
            s_l = 1.0 - _DI_FC_ALPHA * ramp
            block.mlp.fc.weight.data.mul_(s_l)

    # CGI Rademacher channel-gain split (alpha=0.14) on norm1/norm2 gains.
    with torch.no_grad():
        for block in model.blocks:
            s = (torch.randint(0, 2, block.norm1.gains.shape,
                               device=block.norm1.gains.device, dtype=torch.float32) * 2 - 1)
            block.norm1.gains.data.copy_((1.0 - _CGI_ALPHA * s).to(block.norm1.gains.dtype))
            block.norm2.gains.data.copy_((1.0 + _CGI_ALPHA * s).to(block.norm2.gains.dtype))

    # Adam groups per PR #300: betas=(0.8, 0.99), distinct power_c per group.
    optimizer1 = AdamW([dict(params=[model.embed.weight], lr=0.3, name="adam_embed",
                             power_c=ADAM_EMBED_POWER_C),
                        dict(params=[model.proj.weight], lr=1/320, name="adam_lm_head",
                             power_c=ADAM_PROJ_POWER_C),
                        dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.01,
                             name="adam_scalars", power_c=ADAM_OTHER_POWER_C)],
                       betas=(0.8, 0.99), eps=1e-10, weight_decay=0, fused=True)
    # Muon takes (name, p) tuples so it can identify SOAP/attention/V params for
    # the SOAP preconditioning path. PMuon bilateral whitening applies to every 2D
    # routed param uniformly.
    optimizer2 = Muon([(n, p) for n, p in model.blocks.named_parameters() if p.ndim >= 2],
                      lr=MUON_LR, weight_decay=MUON_WEIGHT_DECAY, mu=MU)
    optimizer2.param_groups[0]["name"] = "muon_blocks"
    optimizer2.param_groups[0]["power_c"] = MUON_POWER_C
    optimizers = [optimizer1, optimizer2]
    assert set(p for opt in optimizers for group in opt.param_groups
               for p in group["params"]) == set(model.parameters())
    for opt in optimizers:
        for group in opt.param_groups:
            group["initial_lr"] = group["lr"]

    def _power_law_lr(step, initial_lr, power_c, power=FINAL_LR_POWER, t_end=FINAL_SCHEDULE_STEPS):
        flat_lr = initial_lr
        downward_lr = power_c * max(0.0, t_end - step) ** power
        return min(flat_lr, downward_lr)

    def _muon_mu_at_step(step):
        cd_start = _MU_COOLDOWN_REF_STEPS - _MU_COOLDOWN_STEPS
        if step < _MU_WARMUP_STEPS:
            frac = step / max(_MU_WARMUP_STEPS, 1)
            return _MU_MIN + frac * (_MU_MAX - _MU_MIN)
        if step > cd_start:
            frac = (step - cd_start) / max(_MU_COOLDOWN_STEPS, 1)
            return _MU_MAX - frac * (_MU_MAX - _MU_MIN)
        return _MU_MAX

    def set_hparams(step):
        for opt in optimizers:
            for group in opt.param_groups:
                group["lr"] = _power_law_lr(step, group["initial_lr"], group["power_c"])
        mu = _muon_mu_at_step(step)
        for group in optimizer2.param_groups:
            group["mu"] = mu


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
        if dist.get_rank() == 0 and telemetry_due:
            log_weight_telemetry(
                model=model,
                module_types=module_types,
                trial_idx=trial_idx,
                step=train_step,
                wandb_step=wandb_step,
            )
            log_pmuon_telemetry(
                optimizer=optimizer2,
                trial_idx=trial_idx,
                step=train_step,
                wandb_step=wandb_step,
            )
        if dist.get_rank() == 0 and histogram_due and args.histogram_samples > 0:
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
