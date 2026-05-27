"""Verify refresh trajectory for Arm B PR #1378 — EMA-buffer recovery around step 2600."""
import wandb

api = wandb.Api()
PROJECT = "wandb-applied-ai-team/modded-nanogpt-senpai"

ARMS = [
    ("Arm A (pEMA @ 2275, no Lcov)", "scg8wq17", 2275),
    ("Arm B (pEMA @ 2600, no Lcov)", "y4nxof1m", 2600),
]

KEYS = ["_step", "val/loss", "val/loss_live", "ema/val_loss_ema", "ema/val_loss_live",
        "ema/buffer_frob_dist", "ema_refresh/fired", "ema_refresh/step"]


def show(name, rid, refresh_step):
    print(f"\n{'='*78}")
    print(f"{name}  run={rid}  refresh_step={refresh_step}")
    print('='*78)
    run = api.run(f"{PROJECT}/{rid}")
    rows = list(run.scan_history(keys=KEYS))
    vrows = [r for r in rows if r.get("val/loss") is not None]

    target_steps = sorted({max(0, refresh_step - 50), refresh_step - 25, refresh_step,
                           refresh_step + 25, refresh_step + 50, refresh_step + 100,
                           refresh_step + 200, refresh_step + 325, 3250})

    for s in target_steps:
        # find closest val row at step >= s
        cands = [r for r in vrows if r.get("_step", -1) >= s]
        if cands:
            r = min(cands, key=lambda r: r["_step"])
        else:
            cands = [r for r in vrows if r.get("_step", -1) <= s]
            r = max(cands, key=lambda r: r["_step"]) if cands else None
        if r is None:
            continue
        rs = r.get("_step")
        ema = r.get("ema/val_loss_ema")
        live = r.get("ema/val_loss_live")
        frob = r.get("ema/buffer_frob_dist")
        print(f"  step {rs:>5}: ema/val_loss_ema={ema:.6f}  ema/val_loss_live={live:.6f}  frob={frob}")


for name, rid, rs in ARMS:
    show(name, rid, rs)
