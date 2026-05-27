"""Verify the speedrun crossing: when did val_loss first drop below 3.28 for each arm?"""
import wandb

api = wandb.Api()
PROJECT = "wandb-applied-ai-team/modded-nanogpt-senpai"
TARGET = 3.28

ARMS = [
    ("Arm A (pEMA @ 2275)", "scg8wq17"),
    ("Arm B (pEMA @ 2600)", "y4nxof1m"),
    ("Baseline #1289", "3zhwgfiw"),
]

KEYS = ["_step", "val/loss", "val/loss_live", "ema/val_loss_ema",
        "speedrun/first_step_to_target"]


def show(name, rid):
    print(f"\n{'='*78}")
    print(f"{name}  run={rid}")
    print('='*78)
    run = api.run(f"{PROJECT}/{rid}")
    rows = list(run.scan_history(keys=KEYS))
    val_rows = [r for r in rows if r.get("val/loss") is not None]
    val_rows.sort(key=lambda r: r["_step"])

    print(f"  Val trajectory around speedrun crossing (val_loss <= 3.28):")
    crossing_step = None
    for r in val_rows:
        if r["val/loss"] <= TARGET and crossing_step is None:
            crossing_step = r["_step"]
        if 2800 <= r.get("_step", 0) <= 3000:
            mark = " ← CROSSED" if r["val/loss"] <= TARGET and crossing_step == r["_step"] else ""
            print(f"    step {r['_step']:>5}: val/loss={r['val/loss']:.6f}  "
                  f"val/loss_live={r.get('val/loss_live')}  "
                  f"sr={r.get('speedrun/first_step_to_target')}{mark}")
    print(f"  → first val_loss <= {TARGET} at step {crossing_step}")


for name, rid in ARMS:
    show(name, rid)
