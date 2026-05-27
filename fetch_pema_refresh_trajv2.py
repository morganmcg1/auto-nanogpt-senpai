"""EMA-buffer recovery trajectory around the refresh step for both arms."""
import wandb

api = wandb.Api()
PROJECT = "wandb-applied-ai-team/modded-nanogpt-senpai"

ARMS = [
    ("Arm A pEMA @ 2275", "scg8wq17", 2275),
    ("Arm B pEMA @ 2600", "y4nxof1m", 2600),
]

KEYS = ["_step", "val/loss", "val/loss_live", "ema/val_loss_ema", "ema/val_loss_live",
        "ema/buffer_frob_dist"]


def show(name, rid, refresh_step):
    print(f"\n{'='*78}")
    print(f"{name}  run={rid}  refresh_step={refresh_step}")
    print('='*78)
    run = api.run(f"{PROJECT}/{rid}")
    rows = sorted({r["_step"]: r for r in run.scan_history(keys=KEYS)
                   if r.get("val/loss") is not None}.values(), key=lambda r: r["_step"])
    print(f"  val/ema rows from refresh_step-50 to terminal:")
    for r in rows:
        s = r.get("_step")
        if s is None or s < refresh_step - 50 or s > 3250:
            continue
        if s in (refresh_step - 25, refresh_step, refresh_step + 25, refresh_step + 50,
                 refresh_step + 100, refresh_step + 200, 2925, 3250):
            print(f"    step {s:>5}: ema/val_loss_ema={r['ema/val_loss_ema']:.6f}  "
                  f"ema/val_loss_live={r['ema/val_loss_live']:.6f}  "
                  f"frob={r['ema/buffer_frob_dist']:.4f}")


for name, rid, rs in ARMS:
    show(name, rid, rs)
