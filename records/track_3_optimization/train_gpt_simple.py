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
SOAP_BETA2 = 0.90
PRECOND_FREQ = 16
NS_ITER = 12  # overridden by args.ns_iter at module load


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
    parser.add_argument("--soap_attn", action="store_true",
                        help="Extend SOAP preconditioning to attention projections with trust gate")
    parser.add_argument("--soap_trust_threshold", type=float, default=0.0,
                        help="Cosine similarity threshold below which SOAP update falls back to plain Muon (when --soap_attn)")
    parser.add_argument("--lr_mlp", type=float, default=0.035,
                        help="Muon learning rate for MLP weights (.mlp.fc.weight / .mlp.proj.weight)")
    parser.add_argument("--wd_mlp", type=float, default=0.025,
                        help="Muon weight decay for MLP weights")
    parser.add_argument("--lr_attn", type=float, default=0.035,
                        help="Muon learning rate for attention weights (.attn.q/k/v/proj.weight)")
    parser.add_argument("--wd_attn", type=float, default=0.025,
                        help="Muon weight decay for attention weights")
    parser.add_argument("--wd_schedule", type=str, default="constant",
                        choices=["constant", "ramp_up", "ramp_down", "triangle", "cosine_updown"],
                        help="Schedule shape for wd_mlp and wd_attn on the Muon optimizer side. "
                             "constant=fixed at args.wd_mlp/wd_attn; "
                             "ramp_up=linear 0->2x over training (average matches constant); "
                             "ramp_down=linear 2x->0 over training (average matches constant); "
                             "triangle=linear 0->2x->0 with peak at midpoint; "
                             "cosine_updown=cosine 0->2x->0 (smooth triangle). "
                             "Only applies to Muon param groups; AdamW aux is unaffected.")
    parser.add_argument("--ns_iter", type=int, default=12,
                        help="Number of Newton-Schulz iterations in zeropower_via_newtonschulz5. "
                             "Default 12 (current hardcoded value). Lower = less orthogonal but faster.")
    parser.add_argument("--lr_scalars", type=float, default=0.01,
                        help="LR for AdamW adam_scalars group (RMSNorm gains; "
                             "params with ndim < 2). Default 0.01 — hardcoded, "
                             "never ablated. ~20K params total in this model.")
    parser.add_argument(
        "--depth_init_mode",
        type=str,
        default="ctrl",
        choices=["ctrl", "musoft", "mumedium", "muall", "smallconst"],
        help="Depth-aware init for block residual projections: "
             "ctrl=zero-init (current); "
             "musoft=std=sqrt(0.33)/sqrt(fan_in*L); "
             "mumedium=std=sqrt(0.33)/(L*sqrt(fan_in)); "
             "muall=musoft + non-residual block 2D weights also scaled by 1/sqrt(L); "
             "smallconst=std=1e-3 depth-independent.",
    )
    parser.add_argument("--cautious_muon", action="store_true",
                        help="Enable Cautious mask on Muon updates (Liang et al. 2024, arXiv:2411.16085)")
    parser.add_argument("--cautious_muon_stage", type=str, default="pre_ns",
                        choices=["pre_ns", "post_ns"],
                        help="Apply Cautious mask before or after Newton-Schulz orthogonalization. "
                             "pre_ns: mask the Nesterov buffer before NS, then NS re-orthogonalizes. "
                             "post_ns: mask the final post-NS update.")
    parser.add_argument("--cautious_muon_rescale", action="store_true",
                        help="Rescale survivors by 1/keep_rate to preserve Frobenius RMS (matches Liang et al.)")
    parser.add_argument("--cautious_muon_scope", type=str, default="all",
                        choices=["all", "mlp", "attn"],
                        help="Which Muon param groups to apply Cautious to")
    args = parser.parse_args()
    args.num_trials = args.num_trials if args.num_trials is not None else (args.legacy_num_trials or 1)
    args.wandb_tags = [tag.strip() for tag in args.wandb_tags.split(",") if tag.strip()]
    if args.telemetry_interval < 1 or args.histogram_interval < 1:
        raise ValueError("--telemetry_interval and --histogram_interval must be positive")
    return args


args = parse_args()
NS_ITER = args.ns_iter


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
        # Use float64 so values.numel() - 1 round-trips exactly through .long() even
        # for tensors with > 2**24 elements (e.g. the embedding weight).
        idx = torch.linspace(
            0, values.numel() - 1, max_samples,
            device=values.device, dtype=torch.float64,
        ).long()
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

def zeropower_via_newtonschulz5(G: Tensor) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT

    # Ensure spectral norm is at most 1
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    # Perform the NS iterations, not optimizing for wallclock speed
    a, b, c = 2, -1.5, 0.5
    for _ in range(NS_ITER):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X

    if G.size(-2) > G.size(-1):
        X = X.mT
    return X

@torch.compile
def muon_update(grad, momentum, mu=0.95, nesterov=True):
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    update = zeropower_via_newtonschulz5(update)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update


@torch.compile
def soap_ns_step(nesterov_update):
    update = zeropower_via_newtonschulz5(nesterov_update)
    update *= max(1, nesterov_update.size(-2) / nesterov_update.size(-1))**0.5
    return update


def soap_eigenbasis(mat: Tensor) -> Tensor:
    eye = torch.eye(mat.size(0), device=mat.device)
    try:
        _, q = torch.linalg.eigh(mat + 1e-30 * eye)
    except RuntimeError:
        _, q = torch.linalg.eigh(mat.double() + 1e-30 * eye.double())
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


def soap_precondition_momentum(update, state, beta2=SOAP_BETA2, eps=1e-8):
    update_f = update.float()
    if state["q_row"] is None:
        return update
    q_row, q_col = state["q_row"], state["q_col"]
    projected = q_row.T @ update_f @ q_col
    state["exp_avg_sq"].mul_(beta2).add_(projected.square(), alpha=1 - beta2)
    precond = q_row @ (projected / state["exp_avg_sq"].sqrt().add(eps)) @ q_col.T
    precond.mul_(update_f.norm() / precond.norm().clamp_min(eps))
    return precond.to(update.dtype)


def soap_update_preconditioner(grad, state, shampoo_beta=SOAP_BETA2, precondition_frequency=PRECOND_FREQ):
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


def _apply_cautious_mask(buffer: Tensor, grad: Tensor, rescale: bool):
    """Cautious mask (Liang et al. 2024, arXiv:2411.16085).

    Zero out elements of ``buffer`` whose sign disagrees with ``grad``. Returns
    the masked buffer and a 0-dim ``kept_rate`` tensor (fraction of elements
    retained). When ``rescale`` is true, surviving entries are divided by
    ``kept_rate`` so the Frobenius RMS is preserved (matches the paper).
    """
    mask = (buffer.sign() == grad.sign())
    kept_rate = mask.to(buffer.dtype).mean()
    out = buffer * mask
    if rescale:
        out = out / (kept_rate + 1e-8)
    return out, kept_rate.detach().float()


class Muon(torch.optim.Optimizer):
    SOAP_MLP_SUFFIXES = (".mlp.fc.weight", ".mlp.proj.weight")
    SOAP_ATTN_SUFFIXES = (".attn.q.weight", ".attn.k.weight", ".attn.v.weight", ".attn.proj.weight")

    def __init__(self, named_params, lr=0.02, weight_decay=0, mu=0.95,
                 soap_attn=False, trust_threshold=0.0,
                 cautious_muon=False, cautious_muon_stage="pre_ns",
                 cautious_muon_rescale=False, cautious_muon_scope="all"):
        # `named_params` can be either:
        #   (a) list of (name, param) tuples → single param group (legacy form)
        #   (b) list of dicts {"named_params": [(name, param), ...], "lr": ?, "weight_decay": ?, "mu": ?, "name": ?}
        #       → multiple param groups, one per dict
        assert isinstance(named_params, list) and len(named_params) >= 1
        if isinstance(named_params[0], dict):
            groups_raw = named_params
            all_named = [(n, p) for g in groups_raw for n, p in g["named_params"]]
        else:
            groups_raw = [{"named_params": named_params, "lr": lr, "weight_decay": weight_decay, "mu": mu}]
            all_named = named_params

        soap_suffixes = self.SOAP_MLP_SUFFIXES + (self.SOAP_ATTN_SUFFIXES if soap_attn else ())
        self.soap_params = {
            p for n, p in all_named
            if any(n.endswith(suf) for suf in soap_suffixes)
        }
        self.param_names = {id(p): n for n, p in all_named}
        self.soap_attn = soap_attn
        self.trust_threshold = float(trust_threshold)
        self.use_trust_gate = soap_attn
        self.cos_sims_buffer: dict[str, Tensor] = {}
        self.cautious_muon = bool(cautious_muon)
        self.cautious_muon_stage = cautious_muon_stage
        self.cautious_muon_rescale = bool(cautious_muon_rescale)
        self.cautious_muon_scope = cautious_muon_scope
        # Per-step buffer of kept-rate scalars keyed by group name (e.g. "muon_mlp").
        self.cautious_kept_buffer: dict[str, list[Tensor]] = {}

        param_groups = []
        for g in groups_raw:
            g_params = sorted([p for _, p in g["named_params"]], key=lambda x: x.size(), reverse=True)
            g_dict = {
                "params": g_params,
                "lr": g.get("lr", lr),
                "weight_decay": g.get("weight_decay", weight_decay),
                "mu": g.get("mu", mu),
            }
            if "name" in g:
                g_dict["name"] = g["name"]
            param_groups.append(g_dict)
        defaults = dict(lr=lr, weight_decay=weight_decay, mu=mu)
        super().__init__(param_groups, defaults)

    def _scope_matches(self, group_name: str) -> bool:
        scope = self.cautious_muon_scope
        if scope == "all":
            return True
        if scope == "mlp":
            return group_name == "muon_mlp"
        if scope == "attn":
            return group_name == "muon_attn"
        return False

    @torch.no_grad()
    def step(self):
        self.cos_sims_buffer = {}
        self.cautious_kept_buffer = {}
        world_size = dist.get_world_size()
        rank = dist.get_rank()
        for group in self.param_groups:
            params = group["params"]
            group_name = group.get("name", "")
            apply_cautious = self.cautious_muon and self._scope_matches(group_name)
            norm_sum = torch.zeros((), device=params[0].device, dtype=torch.float32)
            params_pad = params + [torch.empty_like(params[-1])] * (world_size - len(params) % world_size)
            for base_i in range(0, len(params), world_size):
                if base_i + rank < len(params):
                    p = params[base_i + rank]
                    state = self.state[p]
                    use_soap = p in self.soap_params
                    if len(state) == 0:
                        state["momentum"] = torch.zeros_like(p)
                        if use_soap:
                            state["exp_avg_sq"] = torch.zeros_like(p, dtype=torch.float32)
                            state["row_gg"] = torch.zeros(p.size(0), p.size(0), dtype=torch.float32, device=p.device)
                            state["col_gg"] = torch.zeros(p.size(1), p.size(1), dtype=torch.float32, device=p.device)
                            state["q_row"] = None
                            state["q_col"] = None
                            state["soap_step"] = 0
                    raw_grad = p.grad
                    if use_soap:
                        state["momentum"].lerp_(raw_grad, 1 - group["mu"])
                        raw_nesterov = raw_grad.lerp(state["momentum"], group["mu"])
                        # Pre-NS Cautious: mask raw_nesterov (gradient-space) before SOAP precond + NS.
                        if apply_cautious and self.cautious_muon_stage == "pre_ns":
                            raw_nesterov, kept_rate = _apply_cautious_mask(
                                raw_nesterov, raw_grad, self.cautious_muon_rescale
                            )
                            self.cautious_kept_buffer.setdefault(group_name, []).append(kept_rate)
                        precond_nesterov = soap_precondition_momentum(raw_nesterov, state)
                        u_soap = soap_ns_step(precond_nesterov)
                        if self.use_trust_gate:
                            u_muon = soap_ns_step(raw_nesterov)
                            us = u_soap.float()
                            um = u_muon.float()
                            cos_sim_t = (us * um).sum() / (us.norm() * um.norm() + 1e-8)
                            update = torch.where(cos_sim_t < self.trust_threshold, u_muon, u_soap)
                            self.cos_sims_buffer[self.param_names[id(p)]] = cos_sim_t
                        else:
                            update = u_soap
                        soap_update_preconditioner(raw_grad, state)
                    elif apply_cautious:
                        # Non-SOAP cautious path (no torch.compile, explicit).
                        state["momentum"].lerp_(raw_grad, 1 - group["mu"])
                        nesterov_buf = raw_grad.lerp(state["momentum"], group["mu"])
                        if self.cautious_muon_stage == "pre_ns":
                            nesterov_buf, kept_rate = _apply_cautious_mask(
                                nesterov_buf, raw_grad, self.cautious_muon_rescale
                            )
                            self.cautious_kept_buffer.setdefault(group_name, []).append(kept_rate)
                        update = zeropower_via_newtonschulz5(nesterov_buf)
                        update = update * (max(1, raw_grad.size(-2) / raw_grad.size(-1)) ** 0.5)
                    else:
                        update = muon_update(raw_grad, state["momentum"], mu=group["mu"])
                    # Post-NS Cautious mask on the final update.
                    if apply_cautious and self.cautious_muon_stage == "post_ns":
                        update, kept_rate = _apply_cautious_mask(
                            update, raw_grad, self.cautious_muon_rescale
                        )
                        self.cautious_kept_buffer.setdefault(group_name, []).append(kept_rate)
                    norm_sum.add_(update.float().norm())
                    p.mul_(1 - group["lr"] * group["weight_decay"])
                    p.add_(update, alpha=-group["lr"])
                dist.all_gather(params_pad[base_i:base_i + world_size], params_pad[base_i + rank])
            group["_step_norm_sum"] = norm_sum
            group["_step_norm_count"] = len(params)

    def get_cautious_kept_rates(self) -> dict[str, float]:
        """Per-group mean cautious-mask kept-rate across all ranks.

        Returns a dict {group_name: mean_kept_rate} plus an "__all__" entry
        averaging across every recorded param. Empty when cautious is disabled
        or when no params were processed this step.
        """
        if not self.cautious_muon:
            return {}
        world_size = dist.get_world_size()
        out: dict[str, float] = {}
        sum_total = 0.0
        count_total = 0
        for group in self.param_groups:
            gname = group.get("name", "")
            if not group["params"]:
                continue
            device = group["params"][0].device
            kept_list = self.cautious_kept_buffer.get(gname, [])
            if kept_list:
                sum_t = torch.stack(kept_list).sum().to(device=device, dtype=torch.float32)
                count_local = len(kept_list)
            else:
                sum_t = torch.zeros((), device=device, dtype=torch.float32)
                count_local = 0
            if world_size > 1:
                sum_reduced = sum_t.clone()
                dist.all_reduce(sum_reduced, op=dist.ReduceOp.SUM)
                count_tensor = torch.tensor(count_local, device=device, dtype=torch.float32)
                dist.all_reduce(count_tensor, op=dist.ReduceOp.SUM)
                count_global = float(count_tensor.item())
            else:
                sum_reduced = sum_t
                count_global = float(count_local)
            if count_global > 0:
                mean = float(sum_reduced.item()) / count_global
                out[gname] = mean
                sum_total += float(sum_reduced.item())
                count_total += int(count_global)
        if count_total > 0:
            out["__all__"] = sum_total / count_total
        return out

    def get_step_update_norms(self) -> dict[str, float]:
        """Return per-group mean Frobenius norm of the most recent step's updates.

        Returns a dict mapping group name (e.g., 'muon_mlp') to mean ‖update‖_F.
        Requires distributed all_reduce when world_size > 1.
        """
        world_size = dist.get_world_size()
        result: dict[str, float] = {}
        for g_idx, group in enumerate(self.param_groups):
            norm_sum = group.get("_step_norm_sum", None)
            count = group.get("_step_norm_count", 0)
            if norm_sum is None or count == 0:
                continue
            if world_size > 1:
                ns = norm_sum.clone()
                dist.all_reduce(ns, op=dist.ReduceOp.SUM)
                mean = float(ns.item()) / count
            else:
                mean = float(norm_sum.item()) / count
            name = group.get("name", f"group_{g_idx}")
            result[name] = mean
        return result


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
            "world_size": dist.get_world_size(),
            "batch_size_tokens": batch_size,
            "microbatch_sequences": mbs,
            "val_tokens": val_tokens,
            "telemetry_interval": args.telemetry_interval,
            "histogram_interval": args.histogram_interval,
            "histogram_samples": args.histogram_samples,
            "param_histogram_limit": args.param_histogram_limit,
            "slope_fraction": SLOPE_FRACTION,
            "soap_enabled": True,
            "soap_scope": "mlp.fc.weight,mlp.proj.weight" + (
                ",attn.q.weight,attn.k.weight,attn.v.weight,attn.proj.weight" if args.soap_attn else ""
            ),
            "soap_beta2": SOAP_BETA2,
            "soap_precond_freq": PRECOND_FREQ,
            "ns_iter": NS_ITER,
            "soap_attn_enabled": bool(args.soap_attn),
            "soap_trust_threshold": float(args.soap_trust_threshold),
            "lr_mlp": args.lr_mlp,
            "wd_mlp": args.wd_mlp,
            "lr_attn": args.lr_attn,
            "wd_attn": args.wd_attn,
            "wd_schedule": args.wd_schedule,
            "lr_scalars": args.lr_scalars,
            "depth_init_mode": args.depth_init_mode,
            "cautious_muon": bool(args.cautious_muon),
            "cautious_muon_stage": args.cautious_muon_stage,
            "cautious_muon_rescale": bool(args.cautious_muon_rescale),
            "cautious_muon_scope": args.cautious_muon_scope,
        },
    )

for trial_idx in range(args.num_trials):


    ########################################
    #       Init & Optim Hyperparams       #
    ########################################

    # we want to minimize this while still reaching 3.28 val loss
    train_steps = int(os.environ.get("SENPAI_TRAIN_STEPS", 3250))

    NUM_LAYERS = len(model.blocks)  # = 12 for the fixed baseline architecture

    def _resid_proj_std(fan_in: int, mode: str, L: int) -> float:
        base = (0.33 ** 0.5) / (fan_in ** 0.5)
        if mode == "musoft":
            return base / (L ** 0.5)
        elif mode == "mumedium":
            return base / L
        elif mode == "muall":
            return base / (L ** 0.5)
        elif mode == "smallconst":
            return 1e-3
        else:
            raise ValueError(mode)

    def _is_block_residual_proj(name: str) -> bool:
        return (name.startswith("blocks.") and
                (".attn.proj.weight" in name or ".mlp.proj.weight" in name))

    def _is_block_nonresidual_2d(name: str) -> bool:
        return (name.startswith("blocks.") and
                name.endswith(".weight") and
                not _is_block_residual_proj(name))

    # initialize model parameters
    for name, p in model.named_parameters():
        w = p.data
        if name.endswith("weight"):
            if _is_block_residual_proj(name):
                # residual-injection paths — experiment axis
                if args.depth_init_mode == "ctrl":
                    w.zero_()
                else:
                    std = _resid_proj_std(w.size(-1), args.depth_init_mode, NUM_LAYERS)
                    w.normal_(std=std)
            elif "proj" in name:
                # lm_head (model.proj.weight) — keep zero-init for ALL cells
                w.zero_()
            elif "embed" in name:
                w.normal_()  # N(0,1) — unchanged
            else:
                # non-residual 2D weights (block Q/K/V/fc and any others)
                std_base = (0.33 ** 0.5) / (w.size(-1) ** 0.5)
                if args.depth_init_mode == "muall" and _is_block_nonresidual_2d(name):
                    w.normal_(std=std_base / (NUM_LAYERS ** 0.5))
                else:
                    w.normal_(std=std_base)
        elif name.endswith("bias"):
            w.zero_()
        elif name.endswith("gains"):
            w.normal_(mean=1, std=0)
        else:
            raise Exception(f"Uninitialized parameter: {name}")

    # Sanity print — will appear in W&B stdout logs
    _ex_resid_std = _resid_proj_std(768, args.depth_init_mode, NUM_LAYERS) if args.depth_init_mode != "ctrl" else 0.0
    print0(f"[init] mode={args.depth_init_mode}  L={NUM_LAYERS}  block_residual_attn.proj_std={_ex_resid_std:.6f}", console=True)

    # create the optimizer(s)
    optimizer1 = AdamW([dict(params=[model.embed.weight], lr=0.3, name="adam_embed"),
                        dict(params=[model.proj.weight], lr=1/320, name="adam_lm_head"),
                        dict(params=[p for p in model.parameters() if p.ndim < 2], lr=args.lr_scalars, name="adam_scalars")],
                       betas=(0.8, 0.95), eps=1e-10, weight_decay=0, fused=True)
    named_blocks = [(n, p) for n, p in model.blocks.named_parameters() if p.ndim >= 2]
    mlp_named = [(n, p) for n, p in named_blocks
                 if n.endswith(".mlp.fc.weight") or n.endswith(".mlp.proj.weight")]
    attn_named = [(n, p) for n, p in named_blocks
                  if not (n.endswith(".mlp.fc.weight") or n.endswith(".mlp.proj.weight"))]
    assert len(mlp_named) + len(attn_named) == len(named_blocks)
    optimizer2 = Muon(
        [
            dict(named_params=mlp_named,  lr=args.lr_mlp,  weight_decay=args.wd_mlp,  name="muon_mlp"),
            dict(named_params=attn_named, lr=args.lr_attn, weight_decay=args.wd_attn, name="muon_attn"),
        ],
        soap_attn=args.soap_attn, trust_threshold=args.soap_trust_threshold,
        cautious_muon=args.cautious_muon,
        cautious_muon_stage=args.cautious_muon_stage,
        cautious_muon_rescale=args.cautious_muon_rescale,
        cautious_muon_scope=args.cautious_muon_scope,
    )
    optimizers = [optimizer1, optimizer2]
    assert set(p for opt in optimizers for group in opt.param_groups
               for p in group["params"]) == set(model.parameters())
    for opt in optimizers:
        for group in opt.param_groups:
            group["initial_lr"] = group["lr"]
            group["initial_wd"] = group.get("weight_decay", 0.0)

    def _wd_multiplier(step, total_steps, schedule):
        if schedule == "constant":
            return 1.0
        p = step / total_steps
        if schedule == "ramp_up":
            return 2.0 * p
        elif schedule == "ramp_down":
            return 2.0 * (1.0 - p)
        elif schedule == "triangle":
            return 4.0 * p if p < 0.5 else 4.0 * (1.0 - p)
        elif schedule == "cosine_updown":
            import math
            return 1.0 - math.cos(2 * math.pi * p)
        else:
            raise ValueError(f"Unknown wd_schedule: {schedule}")

    # learning rate schedule: stable then decay
    def set_hparams(step, cooldown_frac=0.7):
        progress = step / train_steps
        assert 0 <= progress < 1
        if progress < 1 - cooldown_frac:
            eta = 1.0
        else:
            eta = (1 - progress) / cooldown_frac
        wd_mu = _wd_multiplier(step, train_steps, args.wd_schedule)
        for opt in optimizers:
            for group in opt.param_groups:
                group["lr"] = group["initial_lr"] * eta
                if "initial_wd" in group and group.get("name", "").startswith("muon_"):
                    group["weight_decay"] = group["initial_wd"] * wd_mu


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
        if telemetry_due:
            update_norms = optimizer2.get_step_update_norms()
            current_lrs = {group.get("name", f"group_{i}"): group["lr"]
                           for i, group in enumerate(optimizer2.param_groups)}
            current_wds = {group.get("name", f"group_{i}"): group.get("weight_decay", 0.0)
                           for i, group in enumerate(optimizer2.param_groups)}
            if dist.get_rank() == 0:
                per_group_metrics = {"trial": trial_idx, "train/step": train_step}
                for name, mean_norm in update_norms.items():
                    per_group_metrics[f"train/update_norm/{name}"] = mean_norm
                for name, lr in current_lrs.items():
                    per_group_metrics[f"train/lr/{name}"] = lr
                for name, wd in current_wds.items():
                    per_group_metrics[f"train/wd/{name}"] = wd
                per_group_metrics["train/wd_mlp_now"] = current_wds.get("muon_mlp", 0.0)
                per_group_metrics["train/wd_attn_now"] = current_wds.get("muon_attn", 0.0)
                per_group_metrics["train/wd_schedule_progress"] = train_step / train_steps
                wandb.log(per_group_metrics, step=wandb_step)
        if dist.get_rank() == 0 and optimizer2.cos_sims_buffer:
            cs_names = list(optimizer2.cos_sims_buffer.keys())
            cs_tensors = list(optimizer2.cos_sims_buffer.values())
            cs_values = torch.stack(cs_tensors).detach().cpu().tolist()
            trust_metrics = {"trial": trial_idx, "train/step": train_step}
            fired_count = 0
            fired_mlp = 0
            fired_attn = 0
            mlp_vals: list[float] = []
            attn_vals: list[float] = []
            for cs_name, cs_val in zip(cs_names, cs_values):
                trust_metrics[f"trust/cos_sim/{clean_metric_name(cs_name)}"] = cs_val
                fired = 1 if cs_val < args.soap_trust_threshold else 0
                trust_metrics[f"trust/fired/{clean_metric_name(cs_name)}"] = fired
                fired_count += fired
                if any(cs_name.endswith(suf) for suf in Muon.SOAP_ATTN_SUFFIXES):
                    attn_vals.append(cs_val)
                    fired_attn += fired
                else:
                    mlp_vals.append(cs_val)
                    fired_mlp += fired
            trust_metrics["trust/cos_sim_min"] = min(cs_values)
            trust_metrics["trust/cos_sim_max"] = max(cs_values)
            trust_metrics["trust/cos_sim_mean"] = sum(cs_values) / len(cs_values)
            trust_metrics["trust/fired_count"] = fired_count
            trust_metrics["trust/fired_fraction"] = fired_count / len(cs_values)
            if mlp_vals:
                trust_metrics["trust/cos_sim_mean_mlp"] = sum(mlp_vals) / len(mlp_vals)
                trust_metrics["trust/fired_count_mlp"] = fired_mlp
            if attn_vals:
                trust_metrics["trust/cos_sim_mean_attn"] = sum(attn_vals) / len(attn_vals)
                trust_metrics["trust/fired_count_attn"] = fired_attn
            wandb.log(trust_metrics, step=wandb_step)
        if telemetry_due and optimizer2.cautious_muon:
            kept_rates = optimizer2.get_cautious_kept_rates()
            if dist.get_rank() == 0 and kept_rates:
                stage = optimizer2.cautious_muon_stage
                kept_metrics = {"trial": trial_idx, "train/step": train_step}
                for gname, rate in kept_rates.items():
                    if gname == "__all__":
                        kept_metrics[f"train/cautious_kept/{stage}/all"] = rate
                    else:
                        short = "mlp" if gname == "muon_mlp" else "attn" if gname == "muon_attn" else gname
                        kept_metrics[f"train/cautious_kept/{stage}/{short}"] = rate
                wandb.log(kept_metrics, step=wandb_step)
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
