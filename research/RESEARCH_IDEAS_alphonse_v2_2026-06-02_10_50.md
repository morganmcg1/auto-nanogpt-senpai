# Fresh Hypotheses for g1r1-alphonse (post-#2264)

Generated: 2026-06-02 ~11:30 UTC
Baseline target: Beat PR #1532 — sr <= 2862.5 OR (sr=2875 AND val_ema < 3.262854)
Full baseline stack: --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99
  --muon_block_lr_pattern late-higher --paramema_refresh_only --paramema_refresh_step 2600
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99

## Zero-overlap verification performed

Nine rounds of gh pr list --state all --search queries were run before any recommendation.
Saturated axes (CLOSED PRs found): NS5 adaptive coefficients (#1184/#2221), uniform aux eps (#1178/#333/
#754), post-NS5 RMS per-element (#1094), body RMSProp (#1083), grad Frobenius normalize (#1101),
per-tensor grad clip (#968), grad-var-norm (#971), coherence LR (#1082), trust-region adaptive LR (#628),
SOAP drift refresh (#1134), PMuon bias correction / cold-start (#307), body grad lag ring buffer (#1354),
MGUP-MuonH alignment (#1187), AdaBelief aux (#875/#1210), AdEMAMix aux (#846), LaProp aux (#2157),
aux AGC (#1531), aux Lion (#1056), per-kind aux beta2 (#1603), per-kind aux WD (#1732).

---

## CANDIDATE 1 (TOP RECOMMENDATION)

### Aux Adam Pre-Update Gradient EMA

**Mechanism.** Before the raw gradient `g_t` is fed into aux AdamW's m_t/v_t accumulators, apply a
lightweight exponential moving average:

    g_smooth_t = alpha * g_smooth_{t-1} + (1 - alpha) * g_t
    m_t = beta1 * m_{t-1} + (1 - beta1) * g_smooth_t     # replaces raw g_t
    v_t = beta2 * v_{t-1} + (1 - beta2) * g_smooth_t**2

This adds one state tensor (same shape as the param) per aux group. It decouples the temporal smoothing
window for the first moment from beta1 itself — the pre-filter acts as a phase-offset that reduces
gradient noise before it enters the AdamW variance estimator. Alpha in [0.85, 0.95] adds ~1-4 steps
of effective smoothing without touching the existing beta1/beta2 schedule.

**Directive #1252 alignment**: criterion (c) phase-specific mechanisms — alpha can be scheduled to
taper toward 0 at cooldown onset (step 975), restoring raw gradients when the LR ramp amplifies signal.
Criterion (d) — this directly modifies what enters the momentum accumulator.

**Zero-overlap confirmation**: searches on "gradient ema alpha filter temporal smooth before aux update",
"gradient smoothing pre-filter exponential moving average adam", "aux adam gradient smooth temporal
filter pre-update", "aux adam gradient ema smooth pre accumulate beta" all returned ZERO matching
PRs. The adjacent PRs found (MGUP #1187, AdaBelief #875, AdEMAMix #846, LaProp #2157) are
distinct mechanisms — they modify the variance estimator or the momentum form, not the raw gradient
input to m_t.

**LOC delta**: ~25 lines. Add `g_smooth` state init in optimizer state setup and one lerp_ call before
m_t update.

**Bilateral arm design**:
- Arm A: alpha=0.90, always active (full training)
- Arm B: alpha=0.95, always active

Falsifying result: If both arms cluster in the same val_ema band as baseline (3.269-3.275) with no
acceleration, the pre-filter has no marginal benefit beyond what beta1 already provides. If Arm A
shows lower val_ema than Arm B, the stronger pre-filter is directional evidence.

**Reproduce commands (Arm A)**:
    torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
      --wandb_name "g1r1-alphonse/aux-pre-grad-ema-arm-a-alpha090" \
      --wandb_group "aux-pre-grad-ema" \
      --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
      --muon_block_lr_pattern late-higher --paramema_refresh_only --paramema_refresh_step 2600 \
      --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
      --aux_pre_grad_ema_alpha 0.90

**Reproduce commands (Arm B)**:
    torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
      --wandb_name "g1r1-alphonse/aux-pre-grad-ema-arm-b-alpha095" \
      --wandb_group "aux-pre-grad-ema" \
      --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
      --muon_block_lr_pattern late-higher --paramema_refresh_only --paramema_refresh_step 2600 \
      --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
      --aux_pre_grad_ema_alpha 0.95

---

## CANDIDATE 2

### Aux Adam Per-Group Asymmetric Epsilon

**Mechanism.** Set embed group eps != lm_head group eps in aux AdamW. The embed group sees high
token-frequency variance (Zipfian distribution) suggesting a larger eps floor (1e-6) reduces
denominator instability. The lm_head group maps to output logits where precision matters more,
suggesting a tighter eps (1e-8 or 1e-10). Prior PR #1178 tested a single uniform eps scalar change
(1e-8 vs 1e-12) — it did NOT test asymmetric per-group splits.

**Directive #1252 alignment**: criterion (b) per-layer/per-block behavior.

**Zero-overlap confirmation**: "aux epsilon per group embed lm_head different", "per group eps epsilon
embed lm head separate", "aux adam eps per group embed lm_head asymmetric epsilon" all returned
only #1178 (uniform eps change) and unrelated PRs.

**Bilateral arm design**:
- Arm A: embed_eps=1e-6, lm_head_eps=1e-8 (embed permissive / lm_head tight)
- Arm B: embed_eps=1e-8, lm_head_eps=1e-6 (embed tight / lm_head permissive)

**LOC delta**: ~10 lines. Split the single aux eps variable into two group-specific values.

---

## CANDIDATE 3

### Body Muon Sign-Flip Momentum Damping

**Mechanism.** Track per-element gradient sign history in body Muon. When sign(g_t) != sign(g_{t-1})
for an element (oscillation detected), apply a damping multiplier (e.g. 0.5) to that element's
momentum contribution before the NS5 step. Elements with consistent sign get full momentum.
This is a per-element adaptive momentum that targets oscillating coordinates without touching the
global mu schedule.

**Directive #1252 alignment**: criterion (d) momentum/preconditioner state handling, criterion (b)
per-layer element-wise behavior.

**Zero-overlap confirmation**: "muon sign flip oscillation detection gradient", "gradient sign change
oscillation suppress momentum body", "body muon oscillation sign flip dampen" all returned ZERO
matching PRs. MGUP (#1187) is gradient-momentum alignment scoring, not sign-flip detection.

**Bilateral arm design**:
- Arm A: damping_factor=0.5 (strong damping of oscillating elements)
- Arm B: damping_factor=0.75 (mild damping)

**LOC delta**: ~20 lines. Add sign_prev state tensor, compare signs, apply element-wise mask before
momentum lerp.

---

## Ranking

1. Candidate 1 (Pre-Update Gradient EMA) — targets aux Adam momentum accumulation quality directly;
   phase-schedulable; clear falsifying test; alpha is a continuous lever with adjacent values to try
   if directional signal appears; ~25 LOC.
2. Candidate 2 (Asymmetric Per-Group Eps) — very low LOC (~10), clear mechanism, directly targets
   Zipfian token distribution of embed group; easy to extend if directional.
3. Candidate 3 (Sign-Flip Momentum Damping) — highest novelty but hardest to implement cleanly;
   element-wise masking adds VRAM and complexity; best reserved if Candidates 1 and 2 close null.
