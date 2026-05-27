# Research Ideas — Plateau-50 Escalation
# Generated: 2026-05-27
# Context: 50 consecutive NULL/NEG closures since H148 baseline (FFS=3125, val=3.26364)

## Programme State

Baseline: H148 edward — val=3.26364, FFS=3125, plateau envelope FFS=3150, σ=0.000884
Stack: MuonH-SI body (NS5-12, a=2, b=-1.5, c=0.5) + AdamW aux (AGC clip=0.05, ε=1e-6, β2=0.99)
       + MuLoCo outer Nesterov (outer_lr=0.7, outer_momentum=0.5, sync_interval=30)
       + body_init=orthogonal_fnorm_matched + h_cooldown_frac=1.0 + aux_cooldown_frac=0.4

## Exhausted Axes (do not repeat)

Body: NS5 iter/coeffs, per-layer NS5, block-periodic NS5, Sophia-G, SOAP-lite, PSGD-Kron,
      MARS-M, GMN, Contra-Muon, Soft-Muon, per-layer mu/LR, per-block LR, GC pre-NS5,
      AGC on body, scale-invariant mode, momentum reset, mu schedules, LR warmup shapes,
      AdaMuon second-moment, inner LR cooldown shape.

Aux: eps/β sweeps, AGC variants, v_t freeze/reset, cooldown shape/frac (partially), weight
     decay, full optimizer swaps (Lion, Adafactor, ADOPT, AdaBelief, AdEMAMix, Adan, PAdam,
     Sophia-H, Cautious AdamW, RACS, AdamP, Lookahead, MGUP, WSM, AdamWAtan2), fp32 state.

Outer: outer_lr/momentum sweep/schedule, sync_interval sweep/scheduling, heavy-ball vs
       Nesterov, outer Adam/Lion/true-Nesterov/AGC, schedule-free averaging, Lookahead,
       EMA-stabilized velocity, NS5-orthogonalized velocity.

---

## Hypotheses — Ordered by (Impact × Novelty × Feasibility)

---

### H-A: Dual-EMA on MuonH Momentum Buffer (Body AdEMAMix)
**Rank: 1 — Tier: Mechanism shift on body optimizer**

**Mechanism**: H144 applied dual slow+fast EMA to auxiliary AdamW's second moment. That axis
is exhausted. The body optimizer (MuonH) has never used a dual-EMA buffer. The idea: maintain
two exponential averages of the raw gradient — fast (β_f=0.95, the current momentum) and slow
(β_s=0.999) — and blend them as `α * fast + (1-α) * slow` before NS5 polar projection. The
slow EMA acts as a long-horizon gradient memory that can correct momentum's short-memory bias
during the plateau region. This is mechanistically distinct from AdEMAMix-on-aux because the
update direction feeds into Newton-Schulz, so the slow EMA interacts with the nonlinear
polar projection step, not just a scalar divisor.

**Modification site**: `MuonH.__init__` and `MuonH.step` (lines ~750–830 in train_gpt_simple.py).
Add `state['slow_ema']` buffer, initialize to zeros. In `step()`, update:
  `slow_ema.lerp_(grad, 1 - beta_slow)`  [new, 1 line]
  `blend = alpha * momentum + (1 - alpha) * slow_ema`  [new, 1 line]
  Pass `blend` to `zeropower_via_newtonschulz5` instead of the Nesterov update.
New hyperparams: `beta_slow=0.999`, `ema_alpha=0.5` (sweep: 0.3, 0.5, 0.7).
Extra memory: one extra buffer per body matrix parameter (~same size as momentum).
Extra compute: two lerp calls per param per step — negligible.

**Predicted mode**: NULL/WIN. If slow EMA adds no signal (gradients are already well-estimated
by fast EMA) → NULL. If it corrects oscillation or momentum overshoot in late training → WIN.

**Overlap check**: H144 was dual-EMA on AdamW v_t (aux). This is dual-EMA on MuonH momentum
(body). Different optimizer, different location, different interaction (NS5 projection).
No overlap. H145 (AdaMuon second-moment) was a scalar second-moment estimate on body, not
dual-EMA of first moment. No overlap.

**Arms**: 3 arms × ~22 min = ~66 min total
  arm_a: beta_slow=0.999, ema_alpha=0.5 (baseline-adjacent)
  arm_b: beta_slow=0.999, ema_alpha=0.3 (slow EMA dominates less)
  arm_c: beta_slow=0.9999, ema_alpha=0.5 (very slow long-horizon memory)

---

### H-B: Scheduled Gradient Noise Injection (Annealed Stochastic Gradient Noise)
**Rank: 2 — Tier: Escape mechanism / stochastic regularization**

**Mechanism**: Neelakantan et al. (2015) showed that adding zero-mean isotropic Gaussian noise
to gradients before parameter updates helps escape sharp minima, with variance schedule
σ²=η₀/(1+t)^γ. In this setting: inject noise BEFORE `momentum.lerp_(grad, 1-mu)` in
`muon_update` (or equivalently, just before the MuonH step in the training loop). The noise
rides through NS5 polar projection — the projected update will still be approximately
unit-Frobenius-norm (noise averages out), but the accumulated momentum will be slightly
perturbed. This targets the "sharp flat basin" explanation for the plateau: the optimizer may
be trapped in a neighborhood where all neighbors are equally suboptimal because local curvature
is too flat to navigate.

**Modification site**: training loop, lines ~1162–1173 (just before `optimizer2.step()`).
```python
if args.noise_std > 0.0:
    decay = (1.0 + train_step) ** args.noise_gamma
    sigma = args.noise_std / decay
    for group in optimizer2.param_groups:
        for p in group['params']:
            if p.grad is not None:
                p.grad.data.add_(torch.randn_like(p.grad.data) * sigma)
```
New hyperparams: `noise_std` (0.01–0.05), `noise_gamma` (0.5 is canonical).
Extra compute: one randn_like per body parameter per step — roughly 2-5% overhead.

**Predicted mode**: NULL/WIN (more likely NULL; noise injection is a known fragile technique
but the 50-NULL plateau justifies testing escape mechanisms).

**Overlap check**: No prior experiment injected gradient noise. GC (Gradient Centralization,
H196) is a different transform. Cautious-MuonH (H195) is a directional filter, not noise.
No overlap.

**Arms**: 2 arms × ~22 min = ~44 min total
  arm_a: noise_std=0.02, noise_gamma=0.55 (canonical Neelakantan)
  arm_b: noise_std=0.01, noise_gamma=0.5 (conservative)

---

### H-C: Mid-Training Single LR Warm Restart (SGDR Restarts on Body)
**Rank: 3 — Tier: Schedule mechanism (untested in this exact form)**

**Mechanism**: The current LR schedule is warmup → constant → linear cooldown. No internal
restarts have been tested. SGDR (Loshchilov & Hutter 2017) uses cosine restarts; here we
test a single mid-training LR dip-and-restart for the MuonH body group only. At step
T_restart ≈ 1500 (approximately 45% of 3325), reduce LR to `restart_min_frac` × base_lr
over `restart_down_steps` steps, then raise back to base_lr over `restart_up_steps` steps.
The aux AdamW groups keep their standard schedule. Rationale: the plateau starts after ~1500
steps of flat training (after warmup). A single forced perturbation may dislodge from the
flat basin. H43 tested "catapult" only post-warmup (step 0–200 range); no mid-plateau restart
has been tested.

**Modification site**: `set_hparams` function (lines ~965–1030), add a branch in the MuonH
LR computation:
```python
# Mid-training restart window
if args.restart_step > 0:
    down_end = args.restart_step + args.restart_down_steps
    up_end = down_end + args.restart_up_steps
    if train_step >= args.restart_step and train_step < down_end:
        t = (train_step - args.restart_step) / args.restart_down_steps
        frac = 1.0 - (1.0 - args.restart_min_frac) * t
        body_lr *= frac  # override
    elif train_step >= down_end and train_step < up_end:
        t = (train_step - down_end) / args.restart_up_steps
        frac = args.restart_min_frac + (1.0 - args.restart_min_frac) * t
        body_lr *= frac  # override
```
New hyperparams: `restart_step=1500`, `restart_down_steps=150`, `restart_up_steps=150`,
`restart_min_frac=0.3` (30% of base LR at the trough).

**Predicted mode**: NULL (most likely) / WIN (if flat-basin hypothesis is correct).
**Overlap check**: H43 was catapult pre-warmup. No mid-training restart experiment found.

**Arms**: 2 arms × ~22 min = ~44 min
  arm_a: restart_step=1500, min_frac=0.3, down=150, up=150
  arm_b: restart_step=1200, min_frac=0.5, down=100, up=100 (gentler, earlier)

---

### H-D: Never-Ran H194 — Aux AdamW Cooldown Fraction Sweep (IMMEDIATELY ACTIONABLE)
**Rank: 4 — Tier: Diagnostic / schedule axis**

**Mechanism**: Current hardcoded `aux_cooldown_frac=0.4` means embed/lm_head/scalars start
cooldown at 60% of training. H194 parameterizes this with a 3-arm sweep: 0.0 (start cooldown
immediately), 0.4 (current), 1.0 (full-run cooldown). Code is already written and committed
to the H194 branch. Immediately runnable.

**Why now**: This is a legitimate axis that hasn't completed. With 50 NULL/NEGs on body
optimizer mechanics, the aux schedule axis may have remaining headroom. The aux groups hold
the embedding and lm_head, which are high-signal parameters.

**Overlap check**: H186 varied aux_cooldown_frac as a single variable (0.0/0.4/1.0) — this IS
H194. H186 is listed as CLOSED (44th NULL). **CAUTION: H186 already closed this axis.**
If H186 arm coverage was complete (all 3 arms), do not re-run H194. If H186 only ran 1-2 arms,
H194 adds the missing arms. Verify H186 arm completion before assigning.

**Arms**: 3 arms × ~22 min = ~66 min (if H186 was incomplete)

---

### H-E: Never-Ran H197 — MuLoCo Outer Nesterov Ablation + outer_lr Scan (IMMEDIATELY ACTIONABLE)
**Rank: 5 — Tier: Ablation / outer optimizer axis**

**Mechanism**: H197 tests whether the MuLoCo outer Nesterov wrapper is net positive. Code
already written. Tests: (a) no outer wrapper (outer_lr=0), (b) current settings, (c) outer_lr
grid search around 0.7. The outer-dynamics axis was assigned as the 8th off-axis direction
(cycle ~342). Code ready to run.

**Overlap check**: outer_lr and outer_momentum sweeps were listed as exhausted in the
off-axis portfolio. H197 may be a re-test of exhausted arms. Verify PR #1370 arm configs
before assigning to avoid repeating closed results.

**Arms**: 3-4 arms × ~22 min = ~66-88 min (if not already covered)

---

### H-F: Cautious NS5 — Gradient-Agreeing Mask on Newton-Schulz Output
**Rank: 6 — Tier: Mechanism shift (untested combination)**

**Mechanism**: Cautious optimizer (Liang et al. 2024) masks an update to zero wherever the
update direction disagrees with the gradient sign, applied componentwise. H195 applied
Cautious masking to the MuonH output (Cautious-MuonH). But "Cautious" on a projected update
is unusual — the mask is applied AFTER NS5 projects the momentum into the Stiefel manifold.
This experiment instead applies the mask BEFORE NS5: compute momentum Nesterov update, compute
the raw gradient, mask the momentum update using `sign(momentum) == sign(grad)`, THEN project
masked momentum through NS5. The hypothesis: pre-NS5 masking preserves more gradient
information because NS5 subsequently redistributes the masked update across the manifold
rather than zeroing it post-projection.

**Modification site**: `muon_update` function (lines ~680–695):
```python
# After: update = grad.lerp_(momentum, mu) [Nesterov]
# Add mask before NS5:
if args.cautious_prenorm:
    mask = (update * grad > 0).to(update.dtype)
    mask_frac = mask.mean()  # log for diagnostics
    update = update * mask
# Then: update = zeropower_via_newtonschulz5(update)
```
New hyperparam: `cautious_prenorm=True/False`.

**Predicted mode**: NULL (likely; H195 Cautious-MuonH was closed with NULL, and this is a
variant). Worth one quick arm to confirm mechanism difference.

**Overlap check**: H195 was post-NS5 Cautious masking. This is pre-NS5 masking. Mechanistically
different interaction with NS5 projection. One arm only — if NULL, close.

**Arms**: 1 arm × ~22 min = 22 min
  arm_a: cautious_prenorm=True (vs. H195 baseline which was post-NS5)

---

### H-G: EMA Polyak Averaging on Body Weights for Evaluation (Never-Ran H198)
**Rank: 7 — Tier: Evaluation mechanism (distinct from optimizer dynamics)**

**Mechanism**: H198 maintains a running EMA of model weights (Polyak averaging) and uses the
EMA model for validation rather than the live optimizer state. This does not change training
dynamics — only what weights are evaluated. The hypothesis: the live optimizer state is noisy
(MuLoCo outer steps create discontinuities every 30 steps), and the EMA-smoothed weights may
have lower validation loss at identical step counts. Code is already written.

**Overlap check**: no prior experiment used EMA weight averaging for val. H144's dual-EMA was
on optimizer state buffers. Distinct from EMA on model weights.

**Arms**: 2 arms × ~22 min = ~44 min (EMA decay=0.999 and 0.9999)

---

## Assignment Recommendation

**g1r3-nezuko** → H-A (Dual-EMA on MuonH momentum buffer)
  Priority 1. Genuinely untested mechanism on the body optimizer. 3-arm sweep.
  If NULL: fall back to H-B (gradient noise injection, 2 arms).

**g1r3-fern** → H-C (Mid-training single LR warm restart)
  Priority 2. Untested schedule form; targets flat-basin plateau hypothesis.
  If NULL: fall back to H-F (pre-NS5 Cautious masking, 1 arm diagnostic).

Before assigning H194/H197 (H-D/H-E), verify:
  - H186 arm completion (H-D may be fully closed already)
  - PR #1370 arm configs (H-E outer_lr axis may be covered)

---

## Causal Model for Plateau

**Current best explanation**: The optimizer has converged to a flat basin in the loss landscape
where all gradient-aligned perturbations (momentum, schedule changes, preconditioner variants)
yield the same loss. The scale-invariant update mode constrains weight norms, eliminating one
natural escape direction. The outer MuLoCo wrapper introduces periodic snapshotting that may
suppress exploration.

**What has not been tested as an escape**:
1. Stochastic perturbation of the accumulated momentum buffer (H-A slow EMA is adjacent but
   not identical to momentum reset, which was already tried)
2. Direct gradient noise injection pre-momentum (H-B)
3. Mid-training LR restart to dislodge the optimizer trajectory (H-C)

**Stop condition for this plateau escalation**: If H-A, H-B, H-C all return NULL with
FFS > 3125, the evidence will point toward the loss landscape being fundamentally exhausted at
this step count and model scale, and the next escalation tier should be initialization
experiments (untested: Fixup, spectral initialization, scaled orthogonal with random sign
flips) or outer-wrapper removal (testing whether MuLoCo is net negative at the plateau).
