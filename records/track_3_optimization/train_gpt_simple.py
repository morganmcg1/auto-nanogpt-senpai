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
COOLDOWN_POWER = 1.4
PMUON_GAMMA = 0.4  # PMuon bilateral whitening exponent (PR #202 arm A WIN; was 0.3 baseline)

# Newton-Schulz quintic polar map coefficients f(x) = a*x + b*x^3 + c*x^5.
# Default (2, -1.5, 0.5) is the conservative quintic used since program inception.
# Arm A (Jordan-optimized): (3.4445, -4.7750, 2.0315) — aggressive contraction from Muon paper.
# Arm B (cubic Newton):     (1.5, -0.5, 0.0)        — degenerate quintic, classical Newton iteration.
NS_A = 1.5
NS_B = -0.5
NS_C = 0.0
NS_ITERS = 12
MUON_METHOD = "pmuon-uw-floor-power-cool-1p2-ns-coef-cubic-gamma-power-0p4"


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
    parser.add_argument("--ema_beta", type=float, default=0.0,
                        help="EMA decay (base) for body-Muon param averaging. 0=disabled.")
    parser.add_argument("--ema_warmup_steps", type=int, default=975,
                        help="Steps to TRACK params live before EMA averaging begins.")
    parser.add_argument("--ema_beta_target", type=float, default=None,
                        help="If set, dynamically ramp EMA β from --ema_beta (base) to "
                             "--ema_beta_target during cooldown, coupling β to the LR schedule. "
                             "Requires --ema_beta>0. β_t = ema_beta + (ema_beta_target - ema_beta) "
                             "× (1 - lr_mult_t).")
    parser.add_argument("--kahan_muon", action="store_true", default=False,
                        help="Kahan compensated weight update for body-Muon BF16 params")
    parser.add_argument("--kahan_muon_ema", action="store_true", default=False,
                        help="Also apply Kahan compensation to Polyak EMA lerp accumulation")
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
        # float64 + clamp: linspace at fp32 default loses precision above 2^24 and can
        # produce an end index of numel (one past last) for large tensors like embeddings.
        idx = torch.linspace(
            0, values.numel() - 1, max_samples, dtype=torch.float64, device=values.device
        ).long().clamp_(max=values.numel() - 1)
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

def zeropower_via_newtonschulz5(G: Tensor, a: float = NS_A, b: float = NS_B, c: float = NS_C, iters: int = NS_ITERS) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT

    # Ensure spectral norm is at most 1
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    # Perform the NS iterations, not optimizing for wallclock speed
    for _ in range(iters):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X

    if G.size(-2) > G.size(-1):
        X = X.mT
    return X


def matrix_neg_power(M: Tensor, gamma: float, eps: float = 1e-12) -> Tensor:
    # Symmetric PSD M -> M^{-gamma} via eigendecomposition; eps clamp handles rank deficiency.
    M = 0.5 * (M + M.T)
    eigvals, eigvecs = torch.linalg.eigh(M)
    eigvals = eigvals.clamp_min(eps).pow(-gamma)
    return (eigvecs * eigvals) @ eigvecs.T


def pmuon_update(
    grad: Tensor,
    momentum: Tensor,
    L_cov: Tensor,
    R_cov: Tensor,
    mu: float = 0.95,
    beta_cov: float = 0.95,
    gamma: float = PMUON_GAMMA,
    eps: float = 1e-12,
    nesterov: bool = True,
    ns_a: float = NS_A,
    ns_b: float = NS_B,
    ns_c: float = NS_C,
    polar_diag: dict | None = None,
) -> Tensor:
    # Streaming raw (unnormalized) bilateral covariance EMAs in fp32.
    g32 = grad.detach().float()
    L_cov.mul_(beta_cov).add_(g32 @ g32.T)
    R_cov.mul_(beta_cov).add_(g32.T @ g32)

    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum

    L_neg = matrix_neg_power(L_cov, gamma, eps)
    R_neg = matrix_neg_power(R_cov, gamma, eps)
    m_pre = (L_neg @ update.float()) @ R_neg

    polar = zeropower_via_newtonschulz5(m_pre.to(update.dtype), a=ns_a, b=ns_b, c=ns_c)
    # Sample ortho residual ||X X^T - I||_F on the polar output (before spectral scaling).
    # Only the first eligible parameter per step writes — keeps cost ~O(d^2) once per step.
    if polar_diag is not None and "residual" not in polar_diag:
        X = polar
        m, n = X.shape[-2], X.shape[-1]
        Xf = X.float()
        if m <= n:
            gram = Xf @ Xf.T
            eye = torch.eye(m, device=X.device, dtype=Xf.dtype)
        else:
            gram = Xf.T @ Xf
            eye = torch.eye(n, device=X.device, dtype=Xf.dtype)
        polar_diag["residual"] = float(torch.linalg.norm(gram - eye).item())
        polar_diag["sample_rows"] = m
        polar_diag["sample_cols"] = n
    update = polar * (max(1, grad.size(-2) / grad.size(-1)) ** 0.5)
    return update


def kahan_add_(p: Tensor, update: Tensor, comp: Tensor) -> None:
    """Compensated in-place add for low-precision parameter tensors.

    The PR-spec form `comp = y - (t - p_f32)` captures only the FP32 add error,
    which is ~0 at body-Muon scales; the actual precision lost is in the BF16
    downcast on `p.copy_(t.to(p.dtype))`. This version tracks the downcast
    residual in `comp` so sub-ULP updates accumulate across steps and eventually
    cross the BF16 representability threshold. Verified by per-step trace:
    after 750 steps of +2.88e-4 on a p=0.5 BF16 weight, plain bf16 add stays at
    0.5 (full precision loss), spec Kahan stays at 0.5 with comp=0 (no-op), and
    this form reaches p+comp=0.716 matching the true sum. Same memory footprint
    (one FP32 buffer per param)."""
    p_f32 = p.detach().float()
    t = p_f32 + update.float() + comp
    p_new = t.to(p.dtype)
    comp.copy_(t - p_new.float())
    p.copy_(p_new)


class Muon(torch.optim.Optimizer):
    def __init__(self, params, lr=0.02, weight_decay=0, mu=0.95, beta_cov=0.95, gamma=PMUON_GAMMA,
                 ns_a=NS_A, ns_b=NS_B, ns_c=NS_C):
        assert isinstance(params, list) and len(params) >= 1 and isinstance(params[0], torch.nn.Parameter)
        params = sorted(params, key=lambda x: x.size(), reverse=True)
        defaults = dict(lr=lr, weight_decay=weight_decay, mu=mu, beta_cov=beta_cov, gamma=gamma,
                        ns_a=ns_a, ns_b=ns_b, ns_c=ns_c)
        super().__init__(params, defaults)

    @torch.no_grad()
    def step(self):
        world_size = dist.get_world_size()
        rank = dist.get_rank()
        # Skylight u/w-floor: enforce ||u||_F / ||w||_F >= TARGET_UW per parameter.
        TARGET_UW = 0.35
        floor_fired_count = 0
        floor_eligible_count = 0
        polar_diag: dict = {}
        # Per-step update magnitudes are stashed as GPU tensors; conversion to
        # python floats is deferred to telemetry time to avoid per-step syncs.
        kahan_update_abs_tensors: list[Tensor] = []
        for group in self.param_groups:
            params = group["params"]
            params_pad = params + [torch.empty_like(params[-1])] * (world_size - len(params) % world_size)
            for base_i in range(0, len(params), world_size):
                if base_i + rank < len(params):
                    p = params[base_i + rank]
                    state = self.state[p]
                    if len(state) == 0:
                        state["momentum"] = torch.zeros_like(p)
                        state["L"] = torch.zeros(p.shape[0], p.shape[0], device=p.device, dtype=torch.float32)
                        state["R"] = torch.zeros(p.shape[1], p.shape[1], device=p.device, dtype=torch.float32)
                    if args.kahan_muon and "kahan_comp" not in state:
                        state["kahan_comp"] = torch.zeros_like(p, dtype=torch.float32)
                    update = pmuon_update(
                        p.grad,
                        state["momentum"],
                        state["L"],
                        state["R"],
                        mu=group["mu"],
                        beta_cov=group["beta_cov"],
                        gamma=group["gamma"],
                        ns_a=group["ns_a"],
                        ns_b=group["ns_b"],
                        ns_c=group["ns_c"],
                        polar_diag=polar_diag,
                    )
                    floor_eligible_count += 1
                    w_norm = p.norm()
                    if w_norm > 0:
                        ratio = update.norm() / w_norm
                        if 0 < ratio < TARGET_UW:
                            floor_fired_count += 1
                            update.mul_(TARGET_UW / ratio)
                    if args.kahan_muon:
                        # Sub-ULP compensated update: WD + gradient step folded into a
                        # single FP32 add via kahan_add_ for BF16 storage precision.
                        p_f32 = p.detach().float()
                        wd_update = group["lr"] * group["weight_decay"] * p_f32
                        full_update = group["lr"] * update.float() + wd_update
                        kahan_update_abs_tensors.append(full_update.abs().mean())
                        kahan_add_(p, -full_update, state["kahan_comp"])
                    else:
                        p.mul_(1 - group["lr"] * group["weight_decay"])
                        p.add_(update, alpha=-group["lr"])
                dist.all_gather(params_pad[base_i:base_i + world_size], params_pad[base_i + rank])
        self._floor_diag = {"fired": floor_fired_count, "eligible": floor_eligible_count}
        self._polar_diag = polar_diag
        # Defer .item() to telemetry-due steps to avoid per-step CPU sync overhead.
        self._kahan_update_abs_tensors = kahan_update_abs_tensors


def pmuon_spectral_diag(optimizer: torch.optim.Optimizer, gamma: float) -> dict[str, float]:
    # Post-whitening spectral diagnostic on the first PMuon-managed param (largest
    # by sort order). Re-evaluated against current L_cov, R_cov, momentum state.
    if dist.get_rank() != 0:
        return {}
    for group in optimizer.param_groups:
        for p in group["params"]:
            state = optimizer.state.get(p, None)
            if not state or "L" not in state:
                continue
            with torch.no_grad():
                L_cov = state["L"]
                R_cov = state["R"]
                momentum = state["momentum"].float()
                L_sym = 0.5 * (L_cov + L_cov.T)
                R_sym = 0.5 * (R_cov + R_cov.T)
                L_eig = torch.linalg.eigvalsh(L_sym).clamp_min(0)
                R_eig = torch.linalg.eigvalsh(R_sym).clamp_min(0)
                L_neg = matrix_neg_power(L_cov, gamma)
                R_neg = matrix_neg_power(R_cov, gamma)
                whitened = (L_neg @ momentum) @ R_neg
                sv = torch.linalg.svdvals(whitened)
                sv_min = sv.min().clamp_min(1e-12)
                l_min = float(L_eig.min().item())
                l_max = float(L_eig.max().item())
                r_min = float(R_eig.min().item())
                r_max = float(R_eig.max().item())
                return {
                    "pmuon/gamma_power": float(gamma),
                    "pmuon/lcov_eigh_min": l_min,
                    "pmuon/lcov_eigh_max": l_max,
                    "pmuon/lcov_eigh_ratio": l_max / max(l_min, 1e-12),
                    "pmuon/rcov_eigh_min": r_min,
                    "pmuon/rcov_eigh_max": r_max,
                    "pmuon/rcov_eigh_ratio": r_max / max(r_min, 1e-12),
                    "pmuon/whitened_sv_max": float(sv.max().item()),
                    "pmuon/whitened_sv_min": float(sv_min.item()),
                    "pmuon/whitened_sv_ratio": float((sv.max() / sv_min).item()),
                    "pmuon/sample_shape_dim0": float(momentum.shape[0]),
                    "pmuon/sample_shape_dim1": float(momentum.shape[1]),
                }
    return {}


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
model.compile(dynamic=True)

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
            # PMuon (bilateral covariance preconditioning, record #18) hyperparameters.
            "muon_lr": 0.035,
            "muon_weight_decay": 0.025,
            "pmuon_beta_cov": 0.95,
            "pmuon_gamma": PMUON_GAMMA,
            "pmuon_gamma_power": PMUON_GAMMA,
            "ns_iterations": NS_ITERS,
            "ns_coef_a": NS_A,
            "ns_coef_b": NS_B,
            "ns_coef_c": NS_C,
            "target_uw_floor": 0.35,
            "target_uw": 0.35,
            "power_cooldown_gamma": COOLDOWN_POWER,
            "cooldown_frac": 0.7,
            "muon_method": MUON_METHOD,
            "ema_beta": args.ema_beta,
            "ema_warmup_steps": args.ema_warmup_steps,
            "ema_beta_target": args.ema_beta_target if args.ema_beta_target is not None else 0.0,
            "ema_dynamic_ramp_active": int(args.ema_beta_target is not None and args.ema_beta > 0),
            "kahan_muon": int(args.kahan_muon),
            "kahan_muon_ema": int(args.kahan_muon_ema),
        },
    )

for trial_idx in range(args.num_trials):


    ########################################
    #       Init & Optim Hyperparams       #
    ########################################

    # we want to minimize this while still reaching 3.28 val loss
    train_steps = 3250

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
    optimizer1 = AdamW([dict(params=[model.embed.weight], lr=0.3, name="adam_embed"),
                        dict(params=[model.proj.weight], lr=1/160, name="adam_lm_head"),
                        dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.025, name="adam_scalars")],
                       betas=(0.8, 0.95), eps=1e-10, weight_decay=0, fused=True)
    optimizer2 = Muon([p for p in model.blocks.parameters() if p.ndim >= 2],
                      lr=0.035, weight_decay=0.025, beta_cov=0.95, gamma=PMUON_GAMMA)
    optimizer2.param_groups[0]["name"] = "muon_blocks"
    optimizers = [optimizer1, optimizer2]
    assert set(p for opt in optimizers for group in opt.param_groups
               for p in group["params"]) == set(model.parameters())
    for opt in optimizers:
        for group in opt.param_groups:
            group["initial_lr"] = group["lr"]

    # Polyak/EMA inference weights for body-Muon matrix params (FP32 buffer).
    # During the first args.ema_warmup_steps the buffer tracks params live
    # (handles attn.proj/mlp.proj zero-init bias and seeds buffer with stable
    # post-warmup params). After warmup, EMA averaging begins. If
    # --ema_beta_target is set, the EMA β is dynamically ramped from
    # ema_beta (base) to ema_beta_target as the LR multiplier decays to 0.
    ema_params = None
    ema_kahan_comps = None
    if args.ema_beta > 0:
        ema_params = [p.detach().float().clone() for p in optimizer2.param_groups[0]["params"]]
        if args.kahan_muon_ema:
            ema_kahan_comps = [torch.zeros_like(ep, dtype=torch.float32) for ep in ema_params]

    # learning rate schedule: stable then power-law cooldown (gamma = COOLDOWN_POWER)
    def compute_lr_mult(step, cooldown_frac=0.7):
        """Pure: LR multiplier (eta) at `step`. Matches set_hparams."""
        if step >= train_steps:
            return 0.0
        progress = step / train_steps
        if progress < 1 - cooldown_frac:
            return 1.0
        cooldown_progress = (progress - (1 - cooldown_frac)) / cooldown_frac
        w = 1.0 - cooldown_progress
        return w ** COOLDOWN_POWER

    def compute_ema_beta_t(step):
        """Dynamic β_t = β_base + (β_target - β_base) × (1 - lr_mult_t).
        Returns β_base when β_target unset; clamped to [β_base, β_target]."""
        if args.ema_beta <= 0:
            return 1.0  # EMA disabled; sentinel
        if args.ema_beta_target is None:
            return args.ema_beta
        lr_mult = compute_lr_mult(step)
        beta_t = args.ema_beta + (args.ema_beta_target - args.ema_beta) * (1.0 - lr_mult)
        lo = min(args.ema_beta, args.ema_beta_target)
        hi = max(args.ema_beta, args.ema_beta_target)
        return max(lo, min(hi, beta_t))

    def set_hparams(step, cooldown_frac=0.7):
        progress = step / train_steps
        assert 0 <= progress < 1
        if progress < 1 - cooldown_frac:
            eta = 1.0
            cooldown_progress = 0.0
        else:
            cooldown_progress = (progress - (1 - cooldown_frac)) / cooldown_frac
            w = 1.0 - cooldown_progress  # equivalent to (1 - progress) / cooldown_frac
            eta = w ** COOLDOWN_POWER
        for opt in optimizers:
            for group in opt.param_groups:
                group["lr"] = group["initial_lr"] * eta
        return progress, cooldown_progress, eta


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
            # If EMA active: first measure val on LIVE train weights, then swap in
            # EMA buffer to produce val_loss_ema. val_loss is the EMA-swapped value
            # (since EMA is what we'd ship); val_loss_live is the unmodified train model.
            val_loss_live_float = float("nan")
            buffer_frob_dist = float("nan")
            if ema_params is not None:
                val_loss_live = torch.zeros((), device=device)
                with torch.no_grad():
                    assert len(val_inputs) % mbs == 0
                    for i in range(len(val_inputs) // mbs):
                        val_loss_live += model(val_inputs[i*mbs:(i+1)*mbs], val_targets[i*mbs:(i+1)*mbs])
                dist.all_reduce(val_loss_live, op=dist.ReduceOp.SUM)
                val_loss_live /= val_tokens
                val_loss_live_float = float(val_loss_live.item())
            # Swap in EMA weights (body-Muon matrix params only) for the eval pass.
            train_bufs = None
            if ema_params is not None:
                train_bufs = [p.detach().clone() for p in optimizer2.param_groups[0]["params"]]
                # Compute Frobenius distance ||ema - live|| across all body-Muon params.
                sq_sum = 0.0
                for ema_p, p in zip(ema_params, optimizer2.param_groups[0]["params"]):
                    diff = (ema_p - p.detach().float())
                    sq_sum += float(diff.square().sum().item())
                buffer_frob_dist = sq_sum ** 0.5
                for ema_p, p in zip(ema_params, optimizer2.param_groups[0]["params"]):
                    p.data.copy_(ema_p.to(p.dtype))
            val_loss = torch.zeros((), device=device)
            with torch.no_grad():
                assert len(val_inputs) % mbs == 0
                for i in range(len(val_inputs) // mbs):
                    val_loss += model(val_inputs[i*mbs:(i+1)*mbs], val_targets[i*mbs:(i+1)*mbs])
            dist.all_reduce(val_loss, op=dist.ReduceOp.SUM)
            val_loss /= val_tokens
            val_loss_float = float(val_loss.item())
            # Restore train weights immediately after eval so subsequent backward passes use them.
            if train_bufs is not None:
                for train_p, p in zip(train_bufs, optimizer2.param_groups[0]["params"]):
                    p.data.copy_(train_p)
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
                if ema_params is not None:
                    lr_mult_now = compute_lr_mult(step)
                    beta_t_now = compute_ema_beta_t(step)
                    metrics["val/loss_live"] = val_loss_live_float
                    metrics["val/ema_minus_live"] = val_loss_float - val_loss_live_float
                    metrics["ema/val_loss_ema"] = val_loss_float
                    metrics["ema/val_loss_live"] = val_loss_live_float
                    metrics["ema/delta_ema_minus_live"] = val_loss_float - val_loss_live_float
                    # delta in mnat (millinats) for legibility in the dashboard.
                    metrics["ema/delta_ema_minus_live_mnat"] = (val_loss_float - val_loss_live_float) * 1000.0
                    metrics["ema/buffer_frob_dist"] = buffer_frob_dist
                    metrics["ema/lr_mult_t"] = lr_mult_now
                    metrics["ema/beta_t"] = beta_t_now
                    metrics["ema/beta_target"] = (args.ema_beta_target if args.ema_beta_target is not None
                                                  else args.ema_beta)
                    metrics["ema/n_eff"] = 1.0 / max(1e-12, (1.0 - beta_t_now))
                    metrics["ema/active"] = int(step >= args.ema_warmup_steps)
                    metrics["ema/warmup_steps"] = args.ema_warmup_steps
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
        sched_progress, sched_cooldown_progress, sched_eta = set_hparams(step)
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
        # EMA buffer update on body-Muon matrix params.
        # During warmup: track params live (no averaging) so post-warmup buffer is
        # seeded with stable, non-zero params (handles proj zero-init bias and lets
        # the EMA window cover only the late-cooldown regime).
        # After warmup: lerp at (1 - β_t) where β_t is the dynamic cooldown-aware β.
        ema_beta_t_now = float("nan")
        ema_lr_mult_now = float("nan")
        if ema_params is not None:
            if step < args.ema_warmup_steps:
                for ema_p, p in zip(ema_params, optimizer2.param_groups[0]["params"]):
                    ema_p.copy_(p.detach().float())
                ema_beta_t_now = args.ema_beta
                ema_lr_mult_now = compute_lr_mult(step)
            else:
                ema_lr_mult_now = compute_lr_mult(step)
                ema_beta_t_now = compute_ema_beta_t(step)
                lerp_w = 1.0 - ema_beta_t_now
                if ema_kahan_comps is not None:
                    for ema_p, p, ema_comp in zip(ema_params,
                                                  optimizer2.param_groups[0]["params"],
                                                  ema_kahan_comps):
                        delta = (p.detach().float() - ema_p) * lerp_w
                        kahan_add_(ema_p, delta, ema_comp)
                else:
                    for ema_p, p in zip(ema_params, optimizer2.param_groups[0]["params"]):
                        ema_p.lerp_(p.detach().float(), lerp_w)
        if dist.get_rank() == 0 and telemetry_due:
            log_weight_telemetry(
                model=model,
                module_types=module_types,
                trial_idx=trial_idx,
                step=train_step,
                wandb_step=wandb_step,
            )
            floor_diag = getattr(optimizer2, "_floor_diag", None)
            if floor_diag is not None:
                eligible = floor_diag.get("eligible", 0)
                fired = floor_diag.get("fired", 0)
                wandb.log({
                    "trial": trial_idx,
                    "train/step": train_step,
                    "train/uw_floor/eligible": eligible,
                    "train/uw_floor/fired": fired,
                    "train/uw_floor/fired_fraction": (fired / eligible) if eligible > 0 else 0.0,
                }, step=wandb_step)
            polar_diag = getattr(optimizer2, "_polar_diag", None)
            if polar_diag and "residual" in polar_diag:
                wandb.log({
                    "trial": trial_idx,
                    "train/step": train_step,
                    "polar/ortho_residual_sample": polar_diag["residual"],
                    "polar/sample_rows": polar_diag.get("sample_rows", 0),
                    "polar/sample_cols": polar_diag.get("sample_cols", 0),
                    "polar/ns_coef_a": NS_A,
                    "polar/ns_coef_b": NS_B,
                    "polar/ns_coef_c": NS_C,
                }, step=wandb_step)
            wandb.log({
                "trial": trial_idx,
                "train/step": train_step,
                "train/cooldown/progress": sched_progress,
                "train/cooldown/cooldown_progress": sched_cooldown_progress,
                "train/cooldown/lr_multiplier": sched_eta,
                "train/cooldown/power_gamma": COOLDOWN_POWER,
            }, step=wandb_step)
            if ema_params is not None:
                wandb.log({
                    "trial": trial_idx,
                    "train/step": train_step,
                    "ema/beta": args.ema_beta,
                    "ema/beta_target_param": (args.ema_beta_target if args.ema_beta_target is not None
                                              else args.ema_beta),
                    "ema/beta_t_train": ema_beta_t_now,
                    "ema/lr_mult_t_train": ema_lr_mult_now,
                    "ema/n_eff_train": (1.0 / max(1e-12, (1.0 - ema_beta_t_now))
                                        if ema_beta_t_now < 1.0 else float("inf")),
                    "ema/warmup_steps": args.ema_warmup_steps,
                    "ema/active_train": int(step >= args.ema_warmup_steps),
                    "ema/ramp_enabled": int(args.ema_beta_target is not None),
                }, step=wandb_step)
            if args.kahan_muon:
                update_abs_tensors = getattr(optimizer2, "_kahan_update_abs_tensors", None)
                if update_abs_tensors:
                    n = len(update_abs_tensors)
                    update_mag = float(torch.stack(update_abs_tensors).mean().item())
                    comp_tensors = [optimizer2.state[p]["kahan_comp"]
                                    for grp in optimizer2.param_groups for p in grp["params"]
                                    if "kahan_comp" in optimizer2.state[p]]
                    comp_rms_mean = float(torch.stack([c.square().mean().sqrt()
                                                       for c in comp_tensors]).mean().item()) \
                                    if comp_tensors else 0.0
                    kahan_metrics = {
                        "trial": trial_idx,
                        "train/step": train_step,
                        "kahan/body_muon_comp_rms_mean": comp_rms_mean,
                        "kahan/update_magnitude": update_mag,
                        "kahan/body_muon_param_count": n,
                    }
                    if ema_kahan_comps is not None:
                        ema_rms = float(torch.stack([c.square().mean().sqrt()
                                                     for c in ema_kahan_comps]).mean().item())
                        kahan_metrics["kahan/ema_comp_rms_mean"] = ema_rms
                    wandb.log(kahan_metrics, step=wandb_step)
        if dist.get_rank() == 0 and (train_step % 100 == 0 or train_step == train_steps):
            spec = pmuon_spectral_diag(optimizer2, PMUON_GAMMA)
            if spec:
                spec["trial"] = trial_idx
                spec["train/step"] = train_step
                wandb.log(spec, step=wandb_step)
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
