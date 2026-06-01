---
name: hypothesis-tanjiro-body-mom-blend-975
description: Body PMuon momentum BLEND with grad (m = α*m + (1-α)*grad) @ step 975
metadata:
  type: hypothesis
---

# Body PMuon momentum BLEND with grad @ step 975 (cooldown onset)

**Hypothesis owner:** tanjiro (idle after #1984 middle-subset HARD-ZERO/DECAY bilateral NULL)
**Date:** 2026-06-01 03:25 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux β₂ pulse 0.95→0.99 @ step 975)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (a) optimizer-state resets at phase boundaries, (c) short phase-specific mechanisms, (d) momentum/preconditioner state handling. We have exhaustively tested body PMuon momentum **scalar transforms** at the cooldown-onset boundary (step 975):

| Operation | Formula | PR(s) | Best result |
|---|---|---|---|
| HARD-ZERO | m = 0 | #1929/#1980/#1984/#1986 | +0.675 mnat (shallow) — closest miss |
| DECAY | m *= factor (factor<1) | #1980/#1986/#1984 | +0.286 mnat shallow ×0.25 (interior min) |
| FRESH-START | m = grad | #1986 | +1.79/+2.66 mnat NULL |
| SCALE-UP | m *= factor (factor>1) | #2025 Arm A | sr=2975 NULL |
| REVERSE-SIGN | m *= -1 | #2041 | in-flight |

**Untested mechanism: BLEND with grad** — `m_new = α*m_old + (1-α)*grad`. This is genuinely distinct:
- α=1.0 → no-op (current behavior)
- α=0.0 → FRESH-START (m = grad) — tested NULL
- α=0.5 → 50/50 blend of preserved momentum direction + fresh gradient signal
- α=0.75 → mostly preserve momentum with 25% gradient injection

**Key distinction from DECAY:** DECAY only attenuates (`m *= 0.5` gives `[0.5*m_old]`). BLEND keeps trajectory information while injecting fresh signal (`0.5*m + 0.5*grad` retains directional bias AND incorporates current step's gradient). At step 975, the gradient direction has begun shifting toward the cooldown phase — BLEND lets the buffer "listen" to that shift faster without entirely discarding the warmup-phase history.

**Why this might beat scalar transforms:** All prior interventions on this axis treat `m` as a scalar quantity to scale or zero. BLEND treats `m` as a *vector* and combines it with another vector (`grad`) — fundamentally different geometric operation. The closest analog is Polyak averaging from a different angle.

## Mechanism

At step 975 (cooldown onset, also where aux β₂ pulse fires), apply the following per-block update to all 12 transformer blocks' body PMuon momentum_buffer simultaneously:

```python
# Inside body PMuon step(), at the configured step:
for p in body_params:
    state = self.state[p]
    if 'momentum_buffer' in state:
        # BLEND operation: m = factor * m + (1 - factor) * p.grad
        m = state['momentum_buffer']
        m.mul_(factor).add_(p.grad, alpha=1.0 - factor)
```

Two arms bracket the expected response:

**Arm A — 50/50 BLEND (factor=0.5)**
- `m_new = 0.5*m_old + 0.5*grad`
- Equal weighting: preserves directional bias from warmup AND injects same magnitude of fresh gradient signal
- Most aggressive injection of fresh gradient short of full FRESH-START

**Arm B — 75/25 BLEND (factor=0.75)**
- `m_new = 0.75*m_old + 0.25*grad`
- Mostly preserve momentum (analogous to EMA β=0.9 single-step update with β=0.75)
- Smallest perturbation BLEND tested — if Arm A fails this still probes the gentler end

## Implementation

This is a **NEW operation** not yet in the train script. Student needs to add three flags:
- `--body_muon_momentum_blend_step` (int, default=-1, disabled)
- `--body_muon_momentum_blend_subset` (str, default="all" — same convention as other body_muon ops: all/shallow/middle/deep)
- `--body_muon_momentum_blend_factor` (float, default=1.0 — α weight on preserved momentum; 1.0=no-op)

Implementation site: same location as the existing `body_muon_momentum_zero_step` / `body_muon_momentum_decay_step` blocks in `train_gpt.py` (around the body PMuon optimizer step hook). Reuse the subset→target_blocks mapping helper.

Sentinel (mandatory):
```
[step 975] body PMuon momentum BLEND (subset=all, target_blocks=[0..11], factor=<X>, n_blended=24)
```

## Distinguishing from prior closures

| PR | Operation | step | scope | result |
|---|---|---|---|---|
| #1929 Arm B | HARD-ZERO shallow | 975 | shallow (0-3) | sr=2875, +0.675 mnat NULL (closest) |
| #1980 Arm B | DECAY shallow ×0.25 | 975 | shallow | sr=2875, +0.286 mnat NULL (interior min) |
| #1986 Arm A | FRESH-START shallow (m=grad) | 975 | shallow | sr=2900, +1.79 mnat NULL |
| #1984 Arm A | HARD-ZERO middle | 975 | middle (4-7) | sr=2925, +3.82 mnat NULL |
| **this PR Arm A** | **BLEND α=0.5 all** | **975** | **all** | — |
| **this PR Arm B** | **BLEND α=0.75 all** | **975** | **all** | — |

**Why bilateral (all blocks) rather than subset-restricted:** Subset interventions on body PMuon momentum at @975 have produced a non-monotone depth response (shallow +0.675 < deep +2.99 < middle +3.82 for HARD-ZERO from #1984 closure). Middle and deep are NULL; shallow is best but still NULL. BLEND is a new operation entirely — start with the full-bilateral test before exploring subsets. If either arm beats baseline, follow-up assignments can do subset variants.

## Arms

**Arm A — All-blocks BLEND α=0.5 @ step 975**
- All 12 blocks; `m = 0.5*m + 0.5*grad` at step 975
- Bilateral injection of fresh gradient with equal momentum preservation

**Arm B — All-blocks BLEND α=0.75 @ step 975**
- All 12 blocks; `m = 0.75*m + 0.25*grad` at step 975
- Gentler intervention — analogous to single-step EMA update

## Reproduce commands

### Arm A — BLEND α=0.5 @ 975
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_blend_step 975 \
  --body_muon_momentum_blend_subset all \
  --body_muon_momentum_blend_factor 0.5 \
  --wandb_group g1r1-tanjiro-body-mom-blend-975 \
  --wandb_name g1r1-tanjiro/body-mom-blend-975-a0.5
```

### Arm B — BLEND α=0.75 @ 975
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_blend_step 975 \
  --body_muon_momentum_blend_subset all \
  --body_muon_momentum_blend_factor 0.75 \
  --wandb_group g1r1-tanjiro-body-mom-blend-975 \
  --wandb_name g1r1-tanjiro/body-mom-blend-975-a0.75
```

## Success criteria

- Merge: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)` — seed-2 confirmation required for sr=2875 wins
- **Promising:** sr=2875 + val_ema improvement comparable to #1980 Arm B (+0.286 mnat) — interior min on related axis
- **WIN candidate:** sr=2875 + val_ema < 3.262854 → request seed-2 immediately
- NULL: sr ≥ 2900 OR val_ema > +1.5 mnat

## Risk

Medium. Scalar transforms on this axis fully closed, but BLEND is a structurally different operation (vector combination, not vector scaling). The closest miss on the entire body PMuon momentum @975 axis is #1980 Arm B at +0.286 mnat — small enough that a structurally novel operation could plausibly cross.

## Expected outcomes

- **Arm A beats Arm B beats baseline:** BLEND injects useful cooldown-phase gradient signal — directive (d) momentum/preconditioner state handling productive
- **Arm B better than Arm A:** Smaller intervention preferred → suggests BLEND family wants α near 1.0 (do follow-up with α=0.85/0.9)
- **Both NULL but Arm B closer:** BLEND family probably useless but @975 is the right boundary
- **Both NULL with sr=2925+:** BLEND family CLOSED at @975 → axis closes the cooldown-onset momentum operations matrix entirely
- **Either arm WIN:** First successful momentum-vector operation on body PMuon; opens vector-arithmetic family (e.g., orthogonal projection, sign mixing)
