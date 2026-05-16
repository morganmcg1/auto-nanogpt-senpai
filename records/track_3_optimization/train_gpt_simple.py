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


@torch.compiler.disable
@torch.no_grad()
def accum_xtx_(x: Tensor, accum: Tensor, count: Tensor):
    """Activation-side covariance accumulator used by the Newton-Muon
    right-preconditioner on attention weights.

    For 2D `accum` (in_features x in_features), each call adds (1/N) * xᵀx
    averaged over the batch dimension; `count` is incremented once per call.
    """
    x = x.detach().flatten(0, -2).float()
    accum.add_(x.T @ x, alpha=1 / x.size(0))
    count.add_(1)


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
        # Newton-Muon activation-cov accumulators (attention-only stack on top
        # of Contra+SOAP-MLP). q/k/v share one (dim x dim) input stat; attn.proj
        # has its own (hdim x hdim) input stat over the attention output.
        self.register_buffer("qkv_xtx", torch.zeros(dim, dim, dtype=torch.float32), persistent=False)
        self.register_buffer("qkv_count", torch.zeros((), dtype=torch.float32), persistent=False)
        self.register_buffer("o_xtx", torch.zeros(hdim, hdim, dtype=torch.float32), persistent=False)
        self.register_buffer("o_count", torch.zeros((), dtype=torch.float32), persistent=False)
        # Python bool; Dynamo specializes one graph with accumulation and one
        # without, so the compiled hot path has zero overhead when the flag is off.
        self._precond_active = False

    def forward(self, x: Tensor):
        if self._precond_active:
            accum_xtx_(x, self.qkv_xtx, self.qkv_count)
        B, T = x.size(0), x.size(1)
        q = self.q(x).view(B, T, self.num_heads, self.head_dim)
        k = self.k(x).view(B, T, self.num_heads, self.head_dim)
        v = self.v(x).view(B, T, self.num_heads, self.head_dim)
        q, k = F.rms_norm(q, (q.size(-1),)), F.rms_norm(k, (k.size(-1),))
        q, k = self.rotary(q), self.rotary(k)
        y = F.scaled_dot_product_attention(q.transpose(1, 2), k.transpose(1, 2),
                                           v.transpose(1, 2), scale=0.12, is_causal=True).transpose(1, 2)
        y = y.contiguous().view(B, T, self.num_heads * self.head_dim)
        if self._precond_active:
            accum_xtx_(y, self.o_xtx, self.o_count)
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


def attach_precond_stats(model: "GPT"):
    """Bind each attention-Linear weight to its activation-covariance accumulator.

    q/k/v share one (dim x dim) accumulator per block (xᵀx of the block input).
    attn.proj has its own (hdim x hdim) accumulator (xᵀx of the attention output).
    MLP weights deliberately omitted — they keep SOAP (gradient-side) preconditioning.
    """
    for block in model.blocks:
        a = block.attn
        qkv = dict(accum=a.qkv_xtx, count=a.qkv_count)
        o = dict(accum=a.o_xtx, count=a.o_count)
        for mod, ref in ((a.q, qkv), (a.k, qkv), (a.v, qkv), (a.proj, o)):
            mod.weight._stats_ref = ref


def set_precond_active(model: "GPT", active: bool) -> None:
    """Toggle activation-cov accumulation inside CausalSelfAttention forwards.

    Flipping this Python bool causes Dynamo to recompile/swap between an
    accum-free fast path (used in the normal compiled training forward) and an
    accum-included path (used by the eager refresh-step forward).
    """
    for b in model.blocks:
        b.attn._precond_active = active


########################################
#              Optimizer               #
########################################

# Contra-Muon + SOAP-on-MLP hyperparameters
CONTRA_MUON = 0.4
MU = 0.95
MUON_LR = 0.0375
MUON_WEIGHT_DECAY = 0.025  # nominal; Muon.step does not apply explicit wd (u/w-floor replaces it)
TARGET_UW = 0.35
NORMUON_BETA2 = 0.95
SOAP_BETA2 = 0.90
SOAP_PRECOND_FREQ = 10


def zeropower_via_newtonschulz5(G: Tensor) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT

    # Ensure spectral norm is at most 1
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    # Perform the NS iterations, not optimizing for wallclock speed
    a, b, c = 2, -1.5, 0.5
    for _ in range(12):
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


def soap_refresh(grad, state, beta2=SOAP_BETA2, refresh_freq=SOAP_PRECOND_FREQ):
    """Update row/col Gram EMAs every step; refresh eigenbasis every `refresh_freq` steps."""
    grad_f = grad.float()
    state["row_gg"].lerp_(grad_f @ grad_f.T, 1 - beta2)
    state["col_gg"].lerp_(grad_f.T @ grad_f, 1 - beta2)
    if state["q_row"] is None:
        state["q_row"] = soap_eigenbasis(state["row_gg"])
        state["q_col"] = soap_eigenbasis(state["col_gg"])
    elif state["soap_step"] > 0 and state["soap_step"] % refresh_freq == 0:
        state["q_row"], state["q_col"], state["exp_avg_sq"] = soap_basis_qr(
            state["row_gg"], state["col_gg"], state["q_row"], state["q_col"], state["exp_avg_sq"]
        )
    state["soap_step"] += 1


def soap_precondition(update, state, beta2=SOAP_BETA2, eps=1e-8):
    """Project update into the row/col eigenbasis, scale by inverse sqrt of second-moment EMA, project back, renormalize."""
    if state["q_row"] is None:
        return update
    update_f = update.float()
    q_row, q_col = state["q_row"], state["q_col"]
    projected = q_row.T @ update_f @ q_col
    state["exp_avg_sq"].mul_(beta2).add_(projected.square(), alpha=1 - beta2)
    precond = q_row @ (projected / state["exp_avg_sq"].sqrt().add(eps)) @ q_col.T
    precond.mul_(update_f.norm() / precond.norm().clamp_min(eps))
    return precond.to(update.dtype)


NEWTON_REFRESH_INTERVAL = 64
NEWTON_ALPHA = 0.05
NEWTON_DAMPING_FRAC = 0.2  # adaptive Tikhonov: 0.2 * mean(diag) + 1e-8


class Muon(torch.optim.Optimizer):
    def __init__(self, named_params, lr=MUON_LR, weight_decay=MUON_WEIGHT_DECAY, mu=MU,
                 newton_refresh_interval: int = NEWTON_REFRESH_INTERVAL):
        assert isinstance(named_params, list) and len(named_params) >= 1
        # Identify MLP weights (mlp.fc.weight / mlp.proj.weight) — only these receive SOAP preconditioning.
        self.soap_params = {
            p for n, p in named_params
            if n.endswith(".mlp.fc.weight") or n.endswith(".mlp.proj.weight")
        }
        # Identify attention weights (q/k/v/attn.proj) — only these receive Newton-Muon
        # activation-cov right-preconditioning. q/k/v of a block share one accumulator.
        self.newton_params = {
            p for n, p in named_params
            if (n.endswith(".attn.q.weight") or n.endswith(".attn.k.weight")
                or n.endswith(".attn.v.weight") or n.endswith(".attn.proj.weight"))
        }
        params = sorted([p for _, p in named_params], key=lambda x: x.size(), reverse=True)
        defaults = dict(lr=lr, weight_decay=weight_decay, mu=mu)
        super().__init__(params, defaults)
        self.newton_refresh_interval = newton_refresh_interval
        self.global_step = 0
        self._newton_attached = False
        self._newton_has_inv = False
        self._newton_stats = []
        self._newton_K = None
        self._newton_cov = None
        self._newton_count = None
        self._newton_matrix_count = None
        self._newton_matrix_count_clamped = None
        self._newton_matrix_stat_idx = None
        self._newton_alpha = None
        self._last_refresh_failures = 0

    @staticmethod
    def _eye_(x: Tensor, value: float):
        x.zero_()
        x.diagonal(dim1=-2, dim2=-1).fill_(value)

    @torch.no_grad()
    def attach_newton_preconditioner(self):
        """Bind each newton_params parameter to its activation-covariance stat and
        allocate the cov/inv working tensors. Idempotent across trials."""
        self._newton_attached = True
        self._newton_has_inv = False
        stats = {}
        for group in self.param_groups:
            for p in group["params"]:
                if p not in self.newton_params:
                    continue
                ref = getattr(p, "_stats_ref", None)
                assert ref is not None, f"Missing newton-precond stats for parameter {tuple(p.shape)}"
                key = id(ref["accum"])
                if key not in stats:
                    stats[key] = dict(accum=ref["accum"], count=ref["count"])
                self.state[p]["newton"] = stats[key]
        self._newton_stats = list(stats.values())
        if not self._newton_stats:
            return
        # All attention input stats are dim x dim or hdim x hdim. With head_dim=128
        # and num_heads = dim/head_dim, hdim == dim for this architecture; so all
        # stats share the same dim. Verify and pack into a single batched buffer.
        d = self._newton_stats[0]["accum"].size(-1)
        for s in self._newton_stats:
            assert s["accum"].shape == (d, d), f"unexpected stat shape {s['accum'].shape}"
        n = len(self._newton_stats)
        device = self._newton_stats[0]["accum"].device
        self._newton_K = torch.empty(n, d, d, device=device)
        self._newton_cov = torch.empty_like(self._newton_K)
        self._newton_count = torch.empty(n, device=device)
        self._newton_matrix_count = torch.empty(n, device=device)
        self._newton_matrix_count_clamped = torch.empty(n, device=device)
        self._newton_matrix_stat_idx = torch.arange(n, device=device)
        self._newton_alpha = torch.empty(n, 1, 1, device=device)
        for i, s in enumerate(self._newton_stats):
            s["cov"] = self._newton_cov[i]
            s["inv"] = self._newton_K[i]
            self._eye_(s["cov"], 0.001)
            self._eye_(s["inv"], 1.0)
            s["accum"].zero_()
            s["count"].zero_()
        self._last_refresh_failures = 0

    def newton_refresh_due(self, step: int) -> bool:
        return self._newton_attached and (int(step) + 1) % self.newton_refresh_interval == 0

    @torch.no_grad()
    def _refresh_newton(self):
        if not self._newton_stats:
            return
        K = self._newton_K
        d = K.size(-1)
        for j, s in enumerate(self._newton_stats):
            K[j].copy_(s["accum"])
            self._newton_count[j].copy_(s["count"])
        dist.all_reduce(K, op=dist.ReduceOp.SUM)
        dist.all_reduce(self._newton_count, op=dist.ReduceOp.SUM)
        torch.index_select(self._newton_count, 0, self._newton_matrix_stat_idx,
                           out=self._newton_matrix_count)
        self._newton_matrix_count_clamped.copy_(self._newton_matrix_count).clamp_min_(1)
        K.div_(self._newton_matrix_count_clamped.view(-1, 1, 1))
        # alpha=NEWTON_ALPHA on stats that received samples this window, else 0.
        self._newton_alpha.copy_(self._newton_matrix_count.gt(0).view(-1, 1, 1)).mul_(NEWTON_ALPHA)
        self._newton_cov.lerp_(K, self._newton_alpha)
        # Adaptive Tikhonov damping: NEWTON_DAMPING_FRAC * mean diagonal + 1e-8.
        diag = self._newton_cov.diagonal(dim1=-2, dim2=-1)
        reg = (diag.sum(-1) / d * NEWTON_DAMPING_FRAC + 1e-8).unsqueeze(-1)
        diag.add_(reg)
        L, info = torch.linalg.cholesky_ex(self._newton_cov, upper=False, check_errors=False)
        diag.sub_(reg)
        torch.cholesky_inverse(L, upper=False, out=K)
        failure_mask = info != 0
        n_failures = int(failure_mask.sum().item())
        if n_failures:
            self._eye_(K[failure_mask], 1.0)
        self._last_refresh_failures = n_failures
        for s in self._newton_stats:
            s["accum"].zero_()
            s["count"].zero_()
        self._newton_has_inv = True

    @torch.no_grad()
    def _precondition_newton_grads(self):
        if not self._newton_has_inv:
            return
        for group in self.param_groups:
            for p in group["params"]:
                if p not in self.newton_params or p.grad is None:
                    continue
                inv = self.state[p]["newton"]["inv"].to(p.grad.dtype)
                p.grad.copy_(p.grad @ inv)

    def newton_stats_summary(self) -> dict[str, float]:
        """Light-weight summary of Newton-Muon preconditioner state for W&B (rank 0)."""
        if not self._newton_has_inv:
            return {}
        cov = self._newton_cov
        inv = self._newton_K
        d = cov.size(-1)
        diag = cov.diagonal(dim1=-2, dim2=-1)
        trace = diag.sum(-1)
        return {
            "newton/refresh_step": int(self.global_step),
            "newton/cholesky_failures": float(self._last_refresh_failures),
            "newton/cov_trace_mean": float(trace.mean().item()),
            "newton/cov_trace_max": float(trace.max().item()),
            "newton/cov_diag_min": float(diag.min().item()),
            "newton/cov_diag_max": float(diag.max().item()),
            "newton/inv_fro_mean": float(inv.flatten(1).norm(dim=1).mean().item()),
            "newton/inv_fro_max": float(inv.flatten(1).norm(dim=1).max().item()),
            "newton/cov_dim": d,
            "newton/num_stats": len(self._newton_stats),
        }

    @torch.no_grad()
    def step(self):
        # Newton-Muon refresh + right-precondition (attention-only, MLP keeps SOAP).
        # Applied to RAW grad BEFORE momentum/Nesterov so all downstream stages
        # (momentum EMA, contra, NorMuon-lite second-moment, u/w-floor) see the
        # preconditioned gradient.
        if self._newton_attached and self.newton_refresh_due(self.global_step):
            self._refresh_newton()
        if self._newton_attached:
            self._precondition_newton_grads()

        world_size = dist.get_world_size()
        rank = dist.get_rank()
        for group in self.param_groups:
            params = group["params"]
            params_pad = params + [torch.empty_like(params[-1])] * (world_size - len(params) % world_size)
            for base_i in range(0, len(params), world_size):
                if base_i + rank < len(params):
                    p = params[base_i + rank]
                    state = self.state[p]
                    if "momentum" not in state:
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
                        if p in self.soap_params:
                            m, n = p.size(0), p.size(1)
                            state["row_gg"] = torch.zeros(m, m, dtype=torch.float32, device=p.device)
                            state["col_gg"] = torch.zeros(n, n, dtype=torch.float32, device=p.device)
                            state["q_row"] = None
                            state["q_col"] = None
                            state["exp_avg_sq"] = torch.zeros_like(p, dtype=torch.float32)
                            state["soap_step"] = 0
                    grad = p.grad
                    state["momentum"].lerp_(grad, 1 - group["mu"])
                    momentum_update = grad.lerp(state["momentum"], group["mu"])
                    use_soap = p in self.soap_params
                    # SOAP precondition applied to momentum BEFORE NS5+contra+NorMuon
                    # (matches public record #14 train_gpt_contra_normuon_soapish_mlp.py).
                    if use_soap:
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
                        soap_refresh(grad, state)
                dist.all_gather(params_pad[base_i:base_i + world_size], params_pad[base_i + rank])
        self.global_step += 1


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
# Bind newton-precond stat refs BEFORE compile so hooks/buffers are recognized
# by Dynamo; the actual accumulation happens only when set_precond_active(True).
attach_precond_stats(model)
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
            "optimizer/muon_lr": MUON_LR,
            "optimizer/muon_weight_decay_nominal": MUON_WEIGHT_DECAY,
            "optimizer/target_uw": TARGET_UW,
            "optimizer/normuon_beta2": NORMUON_BETA2,
            "optimizer/soap_beta2": SOAP_BETA2,
            "optimizer/soap_precond_freq": SOAP_PRECOND_FREQ,
            "optimizer/newton_refresh_interval": NEWTON_REFRESH_INTERVAL,
            "optimizer/newton_alpha": NEWTON_ALPHA,
            "optimizer/newton_damping_frac": NEWTON_DAMPING_FRAC,
            "optimizer/recipe": "newton-muon-attn + contra-muon + normuon-lite + soap-on-mlp",
        },
    )

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
                        dict(params=[model.proj.weight], lr=1/320, name="adam_lm_head"),
                        dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.01, name="adam_scalars")],
                       betas=(0.8, 0.95), eps=1e-10, weight_decay=0, fused=True)
    optimizer2 = Muon([(n, p) for n, p in model.blocks.named_parameters() if p.ndim >= 2],
                      lr=MUON_LR, weight_decay=MUON_WEIGHT_DECAY, mu=MU)
    optimizer2.param_groups[0]["name"] = "muon_blocks"
    optimizer2.attach_newton_preconditioner()
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
        for opt in optimizers:
            for group in opt.param_groups:
                group["lr"] = group["initial_lr"] * eta


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
        # Newton-Muon refresh shim: on refresh steps, run an EAGER no_grad forward
        # (via model.forward, bypassing the compiled wrapper) with the accumulation
        # flag ON, then turn it off for the normal training forward/backward. This
        # keeps the hot path's activation memory and runtime unchanged.
        optimizer2.global_step = step
        precond_refresh_due = optimizer2.newton_refresh_due(step)
        if precond_refresh_due:
            set_precond_active(model, True)
            with torch.no_grad():
                model.forward(inputs[:mbs], targets[:mbs])
            set_precond_active(model, False)
            torch.cuda.empty_cache()
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
        if dist.get_rank() == 0 and precond_refresh_due:
            newton_metrics = optimizer2.newton_stats_summary()
            if newton_metrics:
                newton_metrics["trial"] = trial_idx
                newton_metrics["train/step"] = train_step
                wandb.log(newton_metrics, step=wandb_step)
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
