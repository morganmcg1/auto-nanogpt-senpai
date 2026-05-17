# Edward Next Hypothesis — Muon mu Cooldown Scheduling

## Hypothesis

**Scheduling Muon's momentum parameter `mu` during the cooldown window is the Muon-side analogue of frieren's NS-iter cooldown boost.**

The wave-3 mechanism map has established: the cooldown phase (last 30% of training) is a precision-sensitive convergence window where both:
- NS-iter quality matters (frieren #176: NS=12→16 cooldown = +0.002 val improvement)
- AdamW aux responsiveness matters (nezuko #227: β1 decay during cooldown, ongoing)

Muon's `mu=0.95` is a fixed momentum parameter throughout training. During cooldown when LR decays to zero, high `mu` means each Muon step direction is a 20-step exponentially-weighted average of gradient momentum. As the LR ramps down, the momentum accumulation lags behind the current gradient signal — exactly when precision matters most.

Scheduling `mu` from 0.95 → a lower target (0.85, 0.70, or 0.50) during the cooldown window should make Muon more responsive to the current gradient, analogous to β1 decay on the AdamW side.

This axis has NOT been explored anywhere in wave 1-3. No PR has touched Muon's `mu` parameter. The mechanism prediction is supported by the consistent cooldown-precision theme established by PRs #176 and #204.

## Instructions

Modify `records/track_3_optimization/train_gpt_simple.py` to schedule `group["mu"]` for optimizer2 (Muon) param groups during the cooldown window. Leave optimizer1 (AdamW aux) untouched.

Add `NANOGPT_MUON_MU_COOLDOWN_END` env var:

```python
import os

NANOGPT_MUON_MU_INITIAL = float(os.environ.get("NANOGPT_MUON_MU_INITIAL", "0.95"))
NANOGPT_MUON_MU_COOLDOWN_END = float(os.environ.get("NANOGPT_MUON_MU_COOLDOWN_END", "0.95"))

def set_hparams(step, cooldown_frac=0.7):
    progress = step / train_steps
    assert 0 <= progress < 1
    if progress < 1 - cooldown_frac:
        eta = 1.0
        muon_mu = NANOGPT_MUON_MU_INITIAL
    else:
        eta = (1 - progress) / cooldown_frac
        muon_mu = NANOGPT_MUON_MU_INITIAL * eta + NANOGPT_MUON_MU_COOLDOWN_END * (1.0 - eta)
    for opt in optimizers:
        for group in opt.param_groups:
            group["lr"] = group["initial_lr"] * eta
    # Apply mu schedule only to Muon optimizer (optimizer2)
    for group in optimizer2.param_groups:
        group["mu"] = muon_mu
```

## Arms

| Arm | MU_INITIAL | MU_COOLDOWN_END | Description |
|-----|---|---|---|
| A | 0.95 | 0.95 | Control — must match baseline |
| B | 0.95 | 0.85 | Moderate responsiveness |
| C | 0.95 | 0.70 | Strong responsiveness |
| D | 0.95 | 0.50 | Aggressive responsiveness |

## Baseline

Post-#165 (clip=10) and post-#176 (NS=12→16 cooldown) merged baseline:
- val/loss: 3.27461 (n=3 mean)
- fs: 3266.7 (n=3 mean)
