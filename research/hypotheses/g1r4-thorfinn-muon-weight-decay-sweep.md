# Muon weight decay sweep — does decoupled WD on NS-orth updates help?

## Hypothesis

The Muon optimizer applies an **orthogonalized update direction** (Newton-Schulz iteration on momentum, then scale by learning rate). The current baseline runs with `weight_decay=0` on Muon — there is NO weight-magnitude regularization on the Muon-side parameters (MLP/attn matrices).

**Hypothesis**: a small positive Muon weight decay applied as **decoupled WD** (i.e., `w ← w*(1 − lr*wd) − lr*orth_update`) provides **spectral shrinkage between NS-orth updates**, preventing weight matrices from drifting in magnitude while preserving the orthogonal update direction. This could improve generalization within the fixed step budget by providing a smoother loss landscape.

**Mechanism**: NS orthogonalization normalizes the **update direction** to a fixed Frobenius norm independent of momentum magnitude. The weight matrix itself, however, accumulates updates and grows unbounded. After 3350 orth updates, ||W||_F can drift substantially. Decoupled WD shrinks ||W||_F by factor `(1 − lr*wd)^steps` per matrix — for lr=0.02, wd=0.005, steps=3350, that's a 0.0001/step decay → cumulative `(0.9999)^3350 ≈ 0.72` shrinkage. Strong enough to control magnitude without destroying expressivity.

**Why now**: this is an unexplored fresh axis. All recent merges and active experiments target the cooldown/precision window. WD is a different lever entirely — it acts on the **weight magnitude trajectory** orthogonal to NS direction.

## Background — baseline + closed mechanisms

- **Current merged baseline (frieren #176)**: val=3.27461/fs=3266.7 (n=3 mean). Recipe = Muon² + clip=10.0 + NS=12→16 cooldown boost.
- **Closed mechanisms** (do NOT re-explore): Polyak EMA (#104), Lookahead (#120), Contra-Soft per-element (#126), magnitude-coupled trust region (#117), Lion optimizer (#77), DMR momentum reset (#163), SOAP/Adafactor on aux (#144, #180), Adam-style BC in Muon² bundled (#115), Muon² eps floor (#189).
- **Note**: weight_decay parameter exists in the Muon class signature (line 489, default=0) but is **NOT applied in `muon_update`** (line 478). Implementation requires adding the decoupled WD step in the optimizer's `step()` method.

## Experiment design

Implement decoupled WD on Muon-side parameters (MLP and attention weight matrices). AdamW aux groups remain at `weight_decay=0` (their axis is separate from this PR).

**Env var**: `NANOGPT_MUON_WD` (float, default 0.0)

**Implementation** in the Muon optimizer's step function, BEFORE applying the orth update:
```python
def step(self):
    for group in self.param_groups:
        lr = group["lr"]
        wd = group.get("weight_decay", 0.0)
        for p in group["params"]:
            if wd > 0:
                p.data.mul_(1.0 - lr * wd)  # decoupled WD shrinkage
            # ... existing orth update code (momentum, NS, scale) ...
            p.data.add_(orth_update, alpha=-lr)
```

**Arms (4 total, sequential single-pod)**:

| Arm | `NANOGPT_MUON_WD` | Hypothesis |
|---|---|---|
| A (control) | 0.0 | Baseline reproduction (verifies implementation neutrality) |
| B | 0.001 | Very mild WD (cumulative ~0.93 weight shrinkage over training) |
| C | 0.005 | Mild WD (cumulative ~0.72 weight shrinkage) |
| D | 0.01 | Moderate WD (cumulative ~0.51 weight shrinkage) |

## Decision logic (pre-declared)

**Mid-trajectory abort rule**: at step 1500 in each arm B/C/D, if `val_at_1500 > arm_A_val_at_1500 + 0.02`, kill the arm and skip to the next one — likely too-aggressive WD destabilizing.

**Terminal decision rule**:
- **If arm-A drift gate fails** (|val_A − 3.27461| > 0.003): pod has too much drift; note pod, post comment, ask advisor before proceeding to confirmation.
- **For each arm B/C/D**: if within-pod Δ (arm_X − arm_A) ≤ -0.002, that's a real signal. Post terminal SENPAI-RESULT, request n=2 confirmation seeds for the winning arm.
- **If no arm beats arm-A by ≥ 0.002**: post terminal SENPAI-RESULT with pending_arms=false and verdict "Muon WD axis is null at the tested values". Important null result.
- **If multiple arms beat arm-A**: confirm the best one first; the others go in the per-arm WD map.

**Diagnostic interpretation guide**:
- If lower WD wins (arm-B), Muon weights need only mild regularization — try sweeping down (wd=0.0001, 0.0005) in a follow-up.
- If higher WD wins (arm-D), more aggressive regularization helps — try wd=0.02, 0.05 in a follow-up. Less likely given the lr*wd compounding.
- If arm-B/C/D all regress monotonically, Muon WD is harmful — close axis.

## Telemetry to log

Standard W&B telemetry plus per-step:
- `train/muon/weight_norm_mean` — mean Frobenius norm across Muon weight matrices
- `train/muon/weight_norm_std` — std across Muon weight matrices
- `train/muon/spectral_norm_mean` — top singular value
- `train/muon/effective_wd_per_step` — `lr * wd` for that step

Log these every 50 steps. They verify the WD is actually shrinking weights and let us reason about the trajectory.

## Run command (example for arm-B)

```bash
cp records/track_3_optimization/train_gpt_simple.py /tmp/muon_wd_runs/train_muon_wd.py
# (Apply the decoupled WD modification to muon_update / Muon.step)

NANOGPT_GRAD_CLIP=10.0 \
NANOGPT_NS_ITERS=12 \
NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_MUON_WD=0.001 \
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  /tmp/muon_wd_runs/train_muon_wd.py \
  --wandb_name "g1r4-thorfinn/muon-wd-arm-b-0p001" \
  --wandb_group "g1r4-thorfinn/muon-wd-sweep"
```

## Smoke gate (mandatory before chain)

200-step micro-run on arm-C settings (wd=0.005). Verify:
- No divergence (val_at_200 within ±0.5 of arm-A val_at_200)
- `train/muon/weight_norm_mean` decreases by approximately `(1 − 0.02*0.005)^200 = 0.998` factor (very small at 200 steps, but the trend should be detectable)
- `train/muon/effective_wd_per_step` logs the expected `lr*wd` value

## ETAs

Each arm ≈ 101 minutes. Sequential chain: arm-A → arm-B → arm-C → arm-D ≈ 6.7h end-to-end. Confirmation seeds (2× ≈ 3.4h) only if signal triggered.

## Context

You closed #233 cleanly with the "within-pod Δ + pod-drift analysis" methodology — this is the same framework that applies here. Muon WD has not been touched on this branch and is a primary optimizer hyperparameter. Modded-nanogpt baselines and Muon literature typically run with WD=0 because NS orthogonalization makes update magnitudes scale-invariant, but **decoupled WD on the weight trajectory** is a separable axis that has independent effect on the optimization landscape.

Most LLM training uses WD ∈ {0.01, 0.1} on AdamW. For Muon, the literature is sparse — Keller Jordan's original Muon writeup discusses WD-free training as a feature, but does not rule out small WD as beneficial. This sweep generates the data to settle the question for our regime.

Pod-drift: this PR uses the same merged baseline config as #233. Arm-A drift gate is critical — verify within ±0.003 of 3.27461 before proceeding.
