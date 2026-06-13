# Research Ideas 2026-06-13 16:45 — 4 Compositional Hypotheses for frieren / nezuko / tanjiro / thorfinn

**Context**: Current SOTA is #2429 at step 2850, n=4 mean 3.277700, margin 0.004600.
Validity criterion: (3.28 − μ) · √n ≥ 0.004 with n ≥ 4.
Aux-β₂ pulse timing/magnitude axis is exhausted (Track A and Track B both fail).
All 4 hypotheses below are orthogonal to the β₂ pulse axis and compositional with audited wins.

---

## H-GR: Muon Momentum Warmup Extension 500 → 750

**Title**: Muon mu_warmup extension 500 → 750

**Mechanism**: The Muon optimizer ramps the Nesterov momentum parameter μ from `_MU_MIN=0.85` to `_MU_MAX=0.95` over `_MU_WARMUP_STEPS`. PR #2429 (H-FN) established that extending warmup from the default 300 to 500 steps produces the current rank-1 result (mean 3.277700, margin 0.004600). The mechanism is that a slower μ ramp keeps early gradient second-moment estimates reliable before Arbor-Sinkhorn's column-normalisation kicks in, reducing the chance that momentum accumulates a misaligned direction during the noisiest phase of training. At step 500 the ramp reaches μ=0.95 at step 500. Extending to 750 delays this plateau further, meaning the optimizer spends more of the high-LR phase in a lower-momentum, more exploratory regime. Whether 500 is optimal or merely better than 300 is an open question left explicitly in the #2429 analysis — this experiment closes it.

**Single Intervention**: Change `--muon_mu_warmup_steps` from 500 to 750. No other flag changes from the canonical #2429 stack.

**Expected Effect Size**: ±0.0003–0.0008 on n=4 mean val/loss. If 500 > 300 by ~0.0003 and the gain saturates logarithmically, 750 may yield another +0.0002. If 500 was already optimal, 750 may regress ~0.0003. Either outcome sharply constrains the mu_warmup search space and either beats baseline or rules out further extension.

**Run Command Sketch**:
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 2 --seed_offset 0 \
  --aux_b2_start 0.95 --aux_b2_target 0.995 --aux_b2_pulse_step 820 \
  --ri_capture_step 2375 --ri_gamma -0.075 \
  --muon_mu_warmup_steps 750 \
  --wandb_group H-GR-mu-warmup-750
```
Run again with `--seed_offset 2` (seeds 2,3) for n=4 aggregation.

**Decision Criterion**:
- WIN (merge): n=4 mean val/loss < 3.277700 AND (3.28 − μ) · √4 ≥ 0.004
- EXTEND: n=4 mean in [3.277700, 3.277900] — try mu_warmup=1000 as follow-up arm
- CLOSE: n=4 mean > 3.278000 (regression > 0.0003 from #2429)

**Reference**: PR #2429 (H-FN): mu_warmup 300→500, WIN, step 2850, n=4 mean 3.277700. PR #2360 (H-BG, Muon WD sweep): FALSIFIED — confirms WD is not the lever but warmup shape may be. Assigned to: **frieren**.

---

## H-HL: RI Capture Step Later — 2375 → 2500

**Title**: Retrospective Interpolation capture step extended to 2500 (LATER direction)

**Mechanism**: Retrospective Interpolation (RI) at eval time computes `θ_eval = θ_final + γ · (θ_final − θ_capture)` with γ = −0.075 and capture_step = 2375. This "un-drifts" the weights by extrapolating backward from the final checkpoint toward the direction of the captured snapshot, effectively a weight-space polynomial extrapolation along the training trajectory tail. PR #2366 (H-CX) tested the EARLIER direction (capture_step=2250) and it FAILED (+0.001399 above rank-1). The LATER direction — capturing a snapshot closer to the end of training — has never been tested. At capture_step=2500, the distance `θ_final − θ_capture` is smaller (only 390 steps vs 515 steps), so the RI vector has less to project. With γ=−0.075 held fixed, this means a weaker but potentially cleaner correction that avoids over-extrapolation. The hypothesis is that the current 2375 choice may be sub-optimal and the loss landscape near the optimum is sufficiently flat that a later capture (capturing when weights are already near-convergent) gives a cleaner gradient direction for the RI correction.

**Single Intervention**: Change `--ri_capture_step` from 2375 to 2500. All other flags identical to canonical #2429 stack.

**Expected Effect Size**: ±0.0002–0.0005. If the RI correction is slightly mis-aimed with the current 2375 capture, a later capture may reduce noise in the correction vector and yield −0.0002 to −0.0004 improvement. If 2375 is already near-optimal for the trajectory shape, expect a small neutral-to-negative result (< +0.0003 regression).

**Run Command Sketch**:
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 2 --seed_offset 0 \
  --aux_b2_start 0.95 --aux_b2_target 0.995 --aux_b2_pulse_step 820 \
  --ri_capture_step 2500 --ri_gamma -0.075 \
  --muon_mu_warmup_steps 500 \
  --wandb_group H-HL-ri-capture-2500
```
Run again with `--seed_offset 2` for n=4.

**Decision Criterion**:
- WIN (merge): n=4 mean val/loss < 3.277700 AND margin ≥ 0.004
- EXTEND: Within 0.0003 of baseline — try capture_step=2600 or tune γ concurrently
- CLOSE: n=4 mean > 3.278000 — RI-LATER direction ruled out; try γ tuning instead

**Reference**: PR #2366 (H-CX): capture_step=2250 EARLIER → FALSIFIED. RI mechanism introduced in KJ PR #307 (Senpai fork). γ=−0.075 from #2429 canonical stack. Assigned to: **nezuko**.

---

## H-HM: PR #321 Stack + Senpai mu_warmup=500 Cross-Lineage Composition

**Title**: SOAP-f1 (#321 base) + Senpai mu_warmup=500 composition

**Mechanism**: PR #321 (ypwang61, SOAP-f1 + aux-beta2) achieves step 2775, n=4 mean 3.277146 on Track A static — notably beating the #2429 stack on the crossing step dimension even if the margin is close. The #321 stack uses SOAP_PRECONDITION_FREQUENCY=10, SOAP_BLEND=1.0, and its own aux-β₂ setup. Crucially, its mu_warmup setting is 300 (the old default, never upgraded). PR #2429 showed mu_warmup=500 yields the current best result on the #2429 base. Since mu_warmup is a Muon optimizer schedule parameter orthogonal to SOAP's preconditioner or the β₂ pulse step, applying mu_warmup=500 to the #321 base tests whether this win is compositional across lineages. If it is, the combined system may achieve both the earlier crossing step of #321 AND the tighter margin of #2429.

**Single Intervention**: On the #321 stack, set `--muon_mu_warmup_steps 500`. This requires branching from the PR #321 merged head rather than the canonical #2429 stack.

**Expected Effect Size**: If mu_warmup=500 is genuinely orthogonal, expect the combined system to improve the #321 mean by ~0.0003–0.0005 (proportional to the #2429 gain), potentially achieving mean ~3.276600–3.276900 with crossing step ≤ 2775. This would be a new SOTA on both axes.

**Run Command Sketch**:
```bash
# Branch from PR #321 merged head
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 2 --seed_offset 0 \
  --muon_mu_warmup_steps 500 \
  --wandb_group H-HM-pr321-mu-warmup-500
```
Note: The #321 stack sets its own aux-β₂ and SOAP flags as defaults/constants; the student should verify what the #321 head's default arguments are before running. Use `--seed_offset 2` for seeds 2,3.

**Decision Criterion**:
- WIN (merge): n=4 mean val/loss < 3.277146 (beats #321 base) AND margin ≥ 0.004
- ALSO WIN if: n=4 mean < 3.277700 (beats #2429) regardless of crossing step
- CLOSE: n=4 mean > 3.277700 on both metrics — composition is not additive

**Reference**: PR #321 (Track A, step 2775, n=4 mean 3.277146); PR #2429 (H-FN mu_warmup=500 WIN, step 2850, n=4 mean 3.277700). Compositional hypothesis: orthogonal optimizer schedule ingredients should stack. Assigned to: **tanjiro**.

---

## H-HN: SOAP Preconditioner Refresh Frequency Sweep — 10 → {5, 20}

**Title**: SOAP preconditioner refresh frequency sweep: 10 → 5 (more frequent) vs 20 (less frequent)

**Mechanism**: The SOAP optimizer in this codebase uses `SOAP_PRECONDITION_FREQUENCY=10`, meaning the Kronecker-factor preconditioner is recomputed every 10 steps. This constant has never been varied. The preconditioner is a low-rank approximation of the full Hessian; recomputing it more frequently (every 5 steps) increases curvature information recency at the cost of ~2× overhead in preconditioner compute, while less frequent updates (every 20 steps) reduce overhead and introduce more preconditioner lag. In the cooldown phase (approximately steps 2000–2890), the LR is decaying while curvature is changing rapidly as the model approaches a local minimum. More frequent preconditioner updates during cooldown may track the changing curvature better and accelerate final convergence. This is a purely computational/algorithmic lever, never tested, with a clear mechanism (preconditioner staleness vs. curvature tracking fidelity) and trivially reversible by changing a single constant.

**Single Intervention**: Run two arms from the canonical #2429 stack: Arm A with `SOAP_PRECONDITION_FREQUENCY=5` (edit constant in script head), Arm B with `SOAP_PRECONDITION_FREQUENCY=20`. This requires a code constant change, not a CLI flag — the student should add a `--soap_precond_freq` CLI flag (or hardcode the arm value) and document which arm ran which value.

**Expected Effect Size**: Small: ±0.0002–0.0004. Preconditioner frequency primarily affects convergence speed, not final loss. However, at the margin (3.28 − μ ≈ 0.002), even a 0.0002 improvement changes whether we clear the validity threshold. More frequent refresh (freq=5) is the higher-conviction arm given we are in a convergence-sensitive regime.

**Run Command Sketch**:
```bash
# Arm A: SOAP_PRECONDITION_FREQUENCY = 5 (edit constant or add CLI flag)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 2 --seed_offset 0 \
  --aux_b2_start 0.95 --aux_b2_target 0.995 --aux_b2_pulse_step 820 \
  --ri_capture_step 2375 --ri_gamma -0.075 \
  --muon_mu_warmup_steps 500 \
  --soap_precond_freq 5 \
  --wandb_group H-HN-soap-freq-5

# Arm B: SOAP_PRECONDITION_FREQUENCY = 20
# (same but --soap_precond_freq 20 --wandb_group H-HN-soap-freq-20)
```
Use `--seed_offset 2` for seeds 2,3 on the winning arm for n=4 confirmation.

**Decision Criterion**:
- WIN either arm: n=2 mean val/loss < 3.278000 — proceed to n=4 confirmation with that arm
- WIN confirmation: n=4 mean < 3.277700 AND margin ≥ 0.004
- CLOSE: Both arms worse than baseline by > 0.0003 — preconditioner frequency is not a live lever at this scale

**Reference**: SOAP paper (Vyas et al. 2024, "SOAP: Improving and Stabilizing Shampoo using Adam"). Preconditioner frequency sensitivity is discussed in Section 4.2: "SOAP is relatively insensitive to preconditioner update frequency in the range 5–50 for small models." This experiment tests whether the sensitivity boundary matters in the 2890-step curriculum with aggressive LR cooldown. Assigned to: **thorfinn**.

---

## Summary Table

| Hypothesis | Student | Axis | Base Stack | Single Change | Expected Δ |
|---|---|---|---|---|---|
| H-GR | frieren | mu_warmup shape | #2429 | 300→500→**750** | ±0.0003 |
| H-HL | nezuko | RI capture step LATER | #2429 | capture_step 2375→**2500** | ±0.0003 |
| H-HM | tanjiro | Cross-lineage composition | #321 base | + mu_warmup=**500** | −0.0003 to −0.0007 |
| H-HN | thorfinn | SOAP preconditioner refresh | #2429 | freq 10→**{5, 20}** | ±0.0002 |

All 4 hypotheses are orthogonal to aux-β₂ pulse timing/magnitude. None repeat ruled-out axes.
NC × RRE interference respected (not composed). EMA-Nesterov × Contra-Muon interference respected.
