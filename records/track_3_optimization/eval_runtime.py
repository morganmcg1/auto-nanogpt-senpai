"""Runtime contracts injected by the Senpai evaluation harness."""

from __future__ import annotations

import math
import os
import struct
import threading
from pathlib import Path
from typing import Any, Iterable


TIMEOUT_EXIT_CODE = 124
EXPECTED_TRAIN_SHARDS = tuple(f"fineweb_train_{index:06d}.bin" for index in range(1, 21))
EXPECTED_VAL_SHARDS = ("fineweb_val_000000.bin",)
FINEWEB_MAGIC = 20240520
FINEWEB_VERSION = 1
FINEWEB_SHARD_TOKENS = 100_000_000
FINEWEB_HEADER_BYTES = 256 * 4
FINEWEB_SHARD_BYTES = FINEWEB_HEADER_BYTES + 2 * FINEWEB_SHARD_TOKENS


def timeout_minutes_from_env(default: float = 30.0) -> float:
    """Return the positive, finite wall-clock limit for this process."""
    raw_value = os.environ.get("SENPAI_TIMEOUT_MINUTES", str(default))
    minutes = float(raw_value)
    if not math.isfinite(minutes) or minutes <= 0:
        raise ValueError("SENPAI_TIMEOUT_MINUTES must be a positive finite number")
    return minutes


def resolve_wandb_group(cli_group: str | None) -> str | None:
    """Use the harness group when present so CLI args cannot split an eval."""
    env_group = os.environ.get("WANDB_RUN_GROUP")
    if env_group is None:
        return cli_group
    if not env_group.strip():
        raise ValueError("WANDB_RUN_GROUP must not be empty")
    return env_group


def resolve_trial_seed(cli_seed: int) -> int:
    """Use the harness seed when present so every outer trial is reproducible."""
    seed = int(os.environ.get("SENPAI_TRIAL_SEED", str(cli_seed)))
    if seed < 0:
        raise ValueError("SENPAI_TRIAL_SEED must be non-negative")
    return seed


def apply_torch_seed(torch_module: Any, seed: int) -> None:
    """Seed CPU and CUDA RNGs with the authoritative trial seed."""
    torch_module.manual_seed(seed)
    torch_module.cuda.manual_seed_all(seed)


def has_exact_fineweb_shards(
    train_shards: Iterable[str | Path],
    val_shards: Iterable[str | Path],
) -> bool:
    """Match every benchmark shard name, header, token count, and byte size."""
    train_paths = tuple(sorted(map(Path, train_shards)))
    val_paths = tuple(sorted(map(Path, val_shards)))
    return (
        tuple(path.name for path in train_paths) == EXPECTED_TRAIN_SHARDS
        and tuple(path.name for path in val_paths) == EXPECTED_VAL_SHARDS
        and all(_valid_fineweb_shard(path) for path in (*train_paths, *val_paths))
    )


def _valid_fineweb_shard(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size != FINEWEB_SHARD_BYTES:
        return False
    with path.open("rb") as shard:
        header = shard.read(12)
    if len(header) != 12:
        return False
    magic, version, tokens = struct.unpack("<iii", header)
    return (
        magic == FINEWEB_MAGIC
        and version == FINEWEB_VERSION
        and tokens == FINEWEB_SHARD_TOKENS
    )


def summarize_trials(
    trial_results: list[dict[str, float | int]],
    expected_trials: int,
    target_val_loss: float,
    stat_sig_delta: float,
) -> dict[str, float | bool]:
    """Recompute the fixed-step multi-seed statistical acceptance contract."""
    completed = len(trial_results) == expected_trials and expected_trials > 0
    final_losses = [float(result["final_val_loss"]) for result in trial_results]
    finite_results = completed and all(math.isfinite(loss) for loss in final_losses)
    all_reached_target = completed and all(
        int(result["first_step_to_target"]) >= 0 for result in trial_results
    )
    if not final_losses:
        return {
            "completed": False,
            "finite_results": False,
            "all_reached_target": False,
            "mean_final_loss": math.nan,
            "std_final_loss": math.nan,
            "significance_margin": math.nan,
            "statistically_valid": False,
            "trial_ranking_eligible": False,
        }

    mean_final_loss = sum(final_losses) / len(final_losses)
    variance = sum((loss - mean_final_loss) ** 2 for loss in final_losses) / len(final_losses)
    significance_margin = (
        (target_val_loss - mean_final_loss) * math.sqrt(len(final_losses)) - stat_sig_delta
    )
    statistically_valid = finite_results and significance_margin >= 0
    return {
        "completed": completed,
        "finite_results": finite_results,
        "all_reached_target": all_reached_target,
        "mean_final_loss": mean_final_loss,
        "std_final_loss": math.sqrt(variance),
        "significance_margin": significance_margin,
        "statistically_valid": statistically_valid,
        "trial_ranking_eligible": all_reached_target and statistically_valid,
    }


def arm_hard_timeout(minutes: float) -> threading.Timer:
    """Hard-exit this process at the wall-clock limit, even inside GPU work."""
    seconds = minutes * 60.0

    def terminate() -> None:
        message = f"SENPAI_TIMEOUT_MINUTES={minutes:g} expired; terminating process\n"
        try:
            os.write(2, message.encode())
        finally:
            os._exit(TIMEOUT_EXIT_CODE)

    timer = threading.Timer(seconds, terminate)
    timer.daemon = True
    timer.start()
    return timer
