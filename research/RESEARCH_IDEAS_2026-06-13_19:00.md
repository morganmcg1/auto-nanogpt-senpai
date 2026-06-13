# Research Ideas 2026-06-13 19:00 — 4 Fresh Orthogonal Hypotheses for askeladd / fern / alphonse / edward

**Context**: Current SOTA is #2429 at step 2850, n=4 mean 3.277700, margin 0.004600.
Validity criterion: (3.28 − μ) · √n ≥ 0.004 with n ≥ 4.
Aux-β₂ pulse timing/magnitude axis is exhausted (Track A and Track B both fail).
In-flight axes (do NOT duplicate): mu_warmup (H-GR/#2466), ri_capture_step (H-HL/#2467), PR #321 composition (H-HM/#2468), SOAP_PRECONDITION_FREQUENCY (H-HN/#2469).
All 4 hypotheses below are orthogonal to exhausted and in-flight axes.

---

## H-HO: RI γ Value Sweep — −0.075 → {−0.050, −0.100}

**Title**: Retrospective Interpolation γ strength sweep: −0.075 → {−0.050, −0.100}

**Mechanism**: Retrospective Interpolation evaluates `θ_eval = θ_final + γ · (θ_final − θ_capture)` with the canonical γ = −0.075 and capture_step = 2375. This is a weight-space polynomial extrapolation that "un-drifts" the model backward along its training trajectory tail. The parameter γ controls the strength of that correction: γ = 0 disables RI entirely (pure final weights), γ = −0.075 applies the current correction magnitude, and values further from zero (e.g. −0.100) apply a stronger correction that overshoots further along the extrapolation direction. Crucially, γ has NEVER been varied in this research programme — every experiment uses exactly 0.0 (disabled) or −0.075 (canonical). There is zero evidence that −0.075 is optimal; it was the first non-zero value tried and was never swept. Two arms test the symmetry of the γ landscape around the current value: γ = −0.050 (lighter correction, less extrapolation) and γ = −0.100 (stronger correction, more extrapolation). The `--ri_extra_gammas` flag allows paired evaluation of multiple γ values in a single run at zero additional training cost — the same weights are evaluated at multiple γ, only affecting the final checkpoint read-out.

**Single Intervention**: Add `--ri_extra_gammas "-0.050,-0.100"` to the canonical #2429 run. This evaluates γ ∈ {−0.050, −0.075, −0.100} from the same training run at zero extra training cost. The student should report val/loss at each γ value. If either alternative beats −0.075, follow up with `--ri_gamma <winner>` as the main flag in an n=4 confirmation.

**Expected Effect Size**: ±0.0002–0.0006 on n=4 mean val/loss. γ = −0.075 may already be near-optimal (the correction is small), in which case expect ±0.0002. If the landscape is not flat and a stronger correction helps, γ = −0.100 may yield −0.0003 to −0.0006. Either direction sharpens our knowledge of the RI γ landscape, which has been completely unexplored.

**Run Command Sketch**:
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 2 --seed_offset 0 \
  --aux_b2_start 0.95 --aux_b2_target 0.995 --aux_b2_pulse_step 820 \
  --ri_capture_step 2375 --ri_gamma -0.075 \
  --ri_extra_gammas "-0.050,-0.100" \
  --muon_mu_warmup_steps 500 \
  --wandb_group H-HO-ri-gamma-sweep
```
The same run reports val/loss at γ ∈ {−0.050, −0.075, −0.100}. Run again with `--seed_offset 2` (seeds 2,3) to form n=4 for each γ. Pick the best γ for the official n=4 mean.

**Decision Criterion**:
- WIN (merge): Best γ achieves n=4 mean val/loss < 3.277700 AND margin ≥ 0.004 — set `--ri_gamma <winner>` as new canonical
- EXTEND: Best γ within 0.0003 of baseline — try γ = −0.125 or fine-grain sweep γ ∈ {−0.060, −0.070, −0.080, −0.090}
- CLOSE: All three γ within 0.0002 of each other — γ landscape is flat near −0.075; no gain from γ tuning

**Reference**: PR #2429 (H-FN, canonical γ = −0.075). RI mechanism introduced in KJ PR #307 (Senpai fork). `--ri_extra_gammas` flag confirmed present in `train_gpt_simple.py` argparse. γ has literally never been varied in any recorded experiment — this is a completely open axis. Assigned to: **askeladd**.

---

## H-HP: SOAP_BLEND Partial Shampoo/Adam Interpolation — 1.0 → 0.8

**Title**: SOAP preconditioner blend factor: full Shampoo (1.0) → partial blend (0.8)

**Mechanism**: The SOAP optimizer in this codebase uses `SOAP_BLEND=1.0` as a hardcoded constant, meaning the update direction is 100% Shampoo-preconditioned. SOAP_BLEND controls the interpolation `update = blend * shampoo_update + (1 - blend) * adam_update`. At blend=1.0, the optimizer is pure Shampoo (Adam-style momentum in the Shampoo eigenspace). At blend=0.8, 20% of the update is the raw Adam direction, which adds a regularizing pull back toward the Adam diagonal approximation. This is a known stabilization technique from the SOAP paper itself: partial blending can improve numerical robustness when the Kronecker-factor preconditioner has ill-conditioned eigenvalues. In the late-training, low-LR cooldown phase (steps 2000–2890), the preconditioner may accumulate stale curvature from the high-LR phase, and partial Adam blending may reduce over-adaptation to stale second-moment estimates. This constant has never been varied — blend=1.0 was set at initial integration and left untouched through all subsequent experiments.

**Single Intervention**: Change `SOAP_BLEND` constant in the script from 1.0 to 0.8 (or add a `--soap_blend` CLI flag and pass `--soap_blend 0.8`). All other flags are identical to canonical #2429 stack. Run one arm at blend=0.8; do not also run blend=0.9 in the same PR (that is a separate follow-up if this arm passes screening).

**Expected Effect Size**: ±0.0002–0.0005. Blend stabilization tends to have modest gains on well-tuned stacks. If the Kronecker preconditioner is well-conditioned at this scale (768-dim GPT-2), blending may show no benefit or a tiny regression. If there is stale curvature from the high-LR phase, blend=0.8 may reduce overshoot in cooldown and yield −0.0002 to −0.0004 improvement. Small chance of a larger win if preconditioner ill-conditioning is currently masking a better optimum.

**Run Command Sketch**:
```bash
# IMPORTANT: SOAP_BLEND is a hardcoded constant at line 80 of train_gpt_simple.py — there is NO --soap_blend CLI flag.
# The student must edit the script header directly: change SOAP_BLEND = 1.00 to SOAP_BLEND = 0.80 at line 80.
# (Note: V_SOAP_BLEND = 0.95 already exists at line 85 — do NOT change that line; only change SOAP_BLEND.)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 2 --seed_offset 0 \
  --aux_b2_start 0.95 --aux_b2_target 0.995 --aux_b2_pulse_step 820 \
  --ri_capture_step 2375 --ri_gamma -0.075 \
  --muon_mu_warmup_steps 500 \
  --wandb_group H-HP-soap-blend-0.8
```
Run again with `--seed_offset 2` for n=4 confirmation if n=2 screens positive.

**Decision Criterion**:
- WIN (merge): n=4 mean val/loss < 3.277700 AND margin ≥ 0.004
- EXTEND: n=2 mean in [3.277500, 3.278000] — try blend=0.9 as second arm in a follow-up PR
- CLOSE: n=2 mean > 3.278000 (any regression > 0.0003) — SOAP_BLEND is not a live lever at this scale; full Shampoo (1.0) is optimal

**Reference**: SOAP paper (Vyas et al. 2024): Section 4.1 discusses blend parameter sensitivity. SOAP_BLEND=1.0 set at initial integration (KJ PR #321 base); never varied in any Senpai or public PR. Partial blending is standard practice in hybrid Shampoo/Adam implementations (e.g. distributed Shampoo in JAX uses similar interpolation). Assigned to: **fern**.

---

## H-HQ: Sinkhorn Arbor ARBOR_CLAMP_K Sweep — 3.0 → {1.5, 6.0}

**Title**: Sinkhorn Arbor relative clamp factor: ARBOR_CLAMP_K 3.0 → {1.5, 6.0}

**Mechanism**: Sinkhorn Arbor is confirmed load-bearing in this stack (H-GH ablation: disabling regresses +2.4e-3). The `arbor_sinkhorn_equilibrate` function applies doubly-stochastic normalisation via alternating row/column rescaling. Crucially, it uses a **relative clamp** (not a hard floor): at each iteration, row norms are clamped to `[mean − k·std, mean + k·std]` and column norms similarly, where k = `ARBOR_CLAMP_K = 3.0`. This clamp prevents any single row or column from dominating the doubly-stochastic update without applying a hard minimum. `ARBOR_CLAMP_K` controls how tightly the normalisation concentrates:

- Smaller k (e.g. 1.5): tighter clamp — more uniform row/column energy, fewer outlier directions allowed to dominate. Closer to true doubly-stochastic normalisation at each step.
- Larger k (e.g. 6.0): looser clamp — more variance in row/column norms allowed through; normalisation is gentler and more permissive of gradient outliers.

`ARBOR_CLAMP_K = 3.0` was set at initial integration and has **never been varied in any experiment**. The 3.0 value has no special theoretical justification — it was a reasonable statistical outlier threshold (3 sigma). Whether tighter or looser clamp helps at this training scale is completely unknown.

**Single Intervention**: Edit `ARBOR_CLAMP_K` in the script header (line 116) to test two arms in sequence. Run **one arm per seed pair**: first arm `ARBOR_CLAMP_K = 1.5`, second arm `ARBOR_CLAMP_K = 6.0`. If the student has 2 GPU runs available simultaneously, they may run both arms at `--seed_offset 0` in parallel; then run the better arm again at `--seed_offset 2` for n=4 confirmation.

**Expected Effect Size**: ±0.0002–0.0005. The clamp factor shapes how concentrated the doubly-stochastic normalisation is. A tighter clamp (1.5) may improve tail convergence by enforcing more uniform gradient scaling. A looser clamp (6.0) may help if the current 3.0 over-clips beneficial high-curvature directions. Given Arbor is load-bearing (+2.4e-3 on disable), there is non-trivial upside here even for a modest relative change.

**Run Command Sketch**:
```bash
# Arm A: edit ARBOR_CLAMP_K = 1.5 in script header (line 116), then:
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 2 --seed_offset 0 \
  --aux_b2_start 0.95 --aux_b2_target 0.995 --aux_b2_pulse_step 820 \
  --ri_capture_step 2375 --ri_gamma -0.075 \
  --muon_mu_warmup_steps 500 \
  --wandb_group H-HQ-arbor-clamp-1.5

# Arm B: edit ARBOR_CLAMP_K = 6.0 in script header (line 116), then:
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 2 --seed_offset 0 \
  --aux_b2_start 0.95 --aux_b2_target 0.995 --aux_b2_pulse_step 820 \
  --ri_capture_step 2375 --ri_gamma -0.075 \
  --muon_mu_warmup_steps 500 \
  --wandb_group H-HQ-arbor-clamp-6.0
```
Report n=2 mean val/loss for both arms. Run winning arm again with `--seed_offset 2` for n=4 official confirmation.

**Decision Criterion**:
- WIN (merge): Best arm achieves n=4 mean val/loss < 3.277700 AND margin ≥ 0.004 — update ARBOR_CLAMP_K constant
- EXTEND: Best arm n=2 mean in [3.277200, 3.278000] — try finer sweep: 2.0 or 4.5
- CLOSE: Both arms n=2 mean > 3.278000 — clamp factor is not a live lever at this scale; 3.0 is near-optimal

**Reference**: H-GH (Arbor ablation, PR #2434 context): Arbor confirmed load-bearing (+2.4e-3 regression on disable). `ARBOR_CLAMP_K = 3.0` set at Arbor integration (KJ PR #310 port); confirmed at line 116 of `train_gpt_simple.py`. The `arbor_sinkhorn_equilibrate` function at line 887 uses `row_norms.clamp(rn_mean - clamp_k*rn_std, rn_mean + clamp_k*rn_std)` — this is the exact parameter being varied. Value has never been changed in any recorded Senpai experiment. Assigned to: **alphonse**.

---

## H-HR: β₂ Pulse Ablation on Updated #2429 + mu_warmup=500 Stack

**Title**: β₂ pulse load-bearing test on the mu_warmup=500 stack — does the pulse still matter?

**Mechanism**: The β₂ pulse (0.95 → 0.995 at step 820) was established as beneficial in PR #2405 (H-EJ). However, that validation was performed on a pre-mu_warmup=500 stack. PR #2429 then added mu_warmup=500 on top of the pulsed stack, achieving rank-1. This means the pulse's individual necessity has never been re-tested in the presence of mu_warmup=500. The mu_warmup extension itself reshapes the early-phase gradient accumulation dynamics: the slower Nesterov momentum ramp may already provide some of the "optimizer state stabilisation" benefit that the β₂ pulse was designed to provide (slowing down the AdamW second-moment accumulation at a key training milestone). If these two mechanisms are partially redundant, removing the pulse from the mu_warmup=500 stack could be neutral or even mildly positive (fewer interacting schedule components). Conversely, if they are truly orthogonal, removing the pulse will regress by approximately the size of the original H-EJ win (~0.002). Either outcome is high-value: a null result from ablation simplifies the stack and removes a co-tuned component; a confirmed regression validates the full composition and closes this pruning question.

**Single Intervention**: On the canonical #2429 stack (with mu_warmup=500), disable the β₂ pulse by setting `--aux_b2_start -1.0` (the flag default that disables the pulse rule). All other flags remain at #2429 canonical values including `--muon_mu_warmup_steps 500 --ri_capture_step 2375 --ri_gamma -0.075`.

**Expected Effect Size**: Either +0.001 to +0.003 regression (pulse is still load-bearing → retain it) or neutral ±0.0002 (pulse is redundant with mu_warmup → prune it for a cleaner stack). A neutral result is itself a win — it would permit removing the co-tuned pulse step from the stack, reducing timing sensitivity.

**Run Command Sketch**:
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 2 --seed_offset 0 \
  --aux_b2_start -1.0 \
  --ri_capture_step 2375 --ri_gamma -0.075 \
  --muon_mu_warmup_steps 500 \
  --wandb_group H-HR-pulse-ablation-mu500
```
Note: `--aux_b2_start -1.0` disables the pulse rule (default value = no pulse). Confirm this by checking val/loss trajectory — without the pulse, β₂ should stay flat at 0.95 throughout training. Run again with `--seed_offset 2` for n=4 if surprising (neutral or better).

**Decision Criterion**:
- PRUNE WIN (merge as simplification): n=4 mean val/loss ≤ 3.277700 AND margin ≥ 0.004 — pulse is redundant; remove from stack and update canonical flags
- CLOSE-CONFIRMED (pulse load-bearing): n=2 mean > 3.278500 — pulse is still individually necessary even with mu_warmup=500; retain pulse and close PR
- BORDERLINE (< +0.0005 regression): n=4 confirmation — if very small regression, consider whether stack simplification is worth the minor loss

**Reference**: PR #2405 (H-EJ): β₂ pulse first established as beneficial. PR #2429 (H-FN): mu_warmup=500 added on top of pulsed stack. H-GH: Arbor and EMA-Nesterov confirmed load-bearing on the combined stack (but pulse was NOT individually re-tested). Last standalone pulse ablation predates mu_warmup=500. Assigned to: **edward**.

---

## Summary Table

| Hypothesis | Student | Axis | Base Stack | Single Change | Expected Δ |
|---|---|---|---|---|---|
| H-HO | askeladd | RI γ strength sweep | #2429 | γ −0.075 → **{−0.050, −0.100}** via `--ri_extra_gammas` | ±0.0003–0.0006 |
| H-HP | fern | SOAP_BLEND partial Adam interpolation | #2429 | blend 1.0 → **0.8** | ±0.0002–0.0005 |
| H-HQ | alphonse | Sinkhorn Arbor ARBOR_CLAMP_K relative clamp sweep | #2429 | ARBOR_CLAMP_K 3.0 → **{1.5, 6.0}** (edit line 116) | ±0.0002–0.0005 |
| H-HR | edward | β₂ pulse ablation on mu_warmup=500 stack | #2429 | `--aux_b2_start -1.0` (disable pulse) | +0.001 to +0.003 if load-bearing, else ±0.0002 |

All 4 hypotheses are orthogonal to in-flight H-GR/H-HL/H-HM/H-HN and to exhausted aux-β₂ timing/magnitude axis.
No repeat of ruled-out mechanisms. Each is a single-knob intervention on the canonical #2429 stack.
