"""Fetch terminal metrics + EMA/LCOV diagnostics for PR #1378 pEMA-only ablation arms."""
import wandb

api = wandb.Api()
PROJECT = "wandb-applied-ai-team/modded-nanogpt-senpai"
ARMS = [
    ("Arm A (pEMA-only refresh @ 2275, no L_cov)", "scg8wq17"),
    ("Arm B (pEMA-only refresh @ 2600, no L_cov)", "y4nxof1m"),
    ("Baseline #1289 (reference)", "3zhwgfiw"),
]

SUMMARY_KEYS = [
    "speedrun/final_first_step_to_target",
    "speedrun/first_step_to_target",
    "speedrun/final_best_val_loss",
    "val/loss",
    "val/loss_live",
    "val/best_loss",
    "val/best_step",
    "ema/val_loss_ema",
    "ema/val_loss_live",
    "ema/delta_ema_minus_live_mnat",
    "ema/buffer_frob_dist",
    "ema_refresh/fired",
    "ema_refresh/step",
    "ema_refresh/target_step",
    "ema_refresh/only",
    "lcov_refresh/fired",
    "lcov_refresh/target_step",
    "train_runtime_s",
    "peak_memory_gb",
    "time/train_seconds",
    "_step",
]

VAL_KEYS = ["_step", "val/loss", "val/loss_live", "ema/val_loss_ema", "ema/val_loss_live"]
REFRESH_KEYS = ["_step", "ema_refresh/fired", "ema_refresh/step", "ema_refresh/target_step",
                "lcov_refresh/fired", "lcov_refresh/target_step"]


def show_run(name, run_id):
    print(f"\n{'='*78}")
    print(f"{name} — run {run_id}")
    print('='*78)
    try:
        run = api.run(f"{PROJECT}/{run_id}")
    except Exception as e:
        print(f"  FAILED to load: {e}")
        return
    print(f"  Name:    {run.name}")
    print(f"  State:   {run.state}")
    print(f"  Group:   {run.group}")
    print(f"  Created: {run.created_at}")

    sm = run.summary_metrics
    print(f"\n  --- Summary metrics ---")
    for k in SUMMARY_KEYS:
        v = sm.get(k)
        if v is not None:
            print(f"    {k}: {v}")

    print(f"\n  --- val trajectory (last few rows step>=3000) ---")
    val_rows = list(run.scan_history(keys=VAL_KEYS))
    late = [r for r in val_rows if r.get("_step", 0) >= 3000 and r.get("val/loss") is not None]
    for r in late[-10:]:
        s = r.get("_step")
        vl = r.get("val/loss")
        vlive = r.get("val/loss_live")
        vema = r.get("ema/val_loss_ema")
        velive = r.get("ema/val_loss_live")
        print(f"    step {s:>5}: val(ema)={vl}  val_live={vlive}  ema/val_loss_ema={vema}  ema/val_loss_live={velive}")

    print(f"\n  --- refresh diagnostics (rows where fired transitions) ---")
    ref_rows = list(run.scan_history(keys=REFRESH_KEYS))
    ref_rows = [r for r in ref_rows if r.get("ema_refresh/fired") is not None]
    seen_fired = -1
    for r in ref_rows:
        f = r.get("ema_refresh/fired")
        if f != seen_fired:
            print(f"    step {r.get('_step'):>5}: ema_refresh/fired={f} step={r.get('ema_refresh/step')} "
                  f"target_step={r.get('ema_refresh/target_step')} "
                  f"lcov_refresh/fired={r.get('lcov_refresh/fired')} "
                  f"lcov_refresh/target_step={r.get('lcov_refresh/target_step')}")
            seen_fired = f


if __name__ == "__main__":
    for name, rid in ARMS:
        show_run(name, rid)
