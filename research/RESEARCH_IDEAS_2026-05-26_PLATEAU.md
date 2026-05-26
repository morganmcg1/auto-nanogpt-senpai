# Research Hypotheses for edward — 2026-05-26 Plateau Session

**Date:** 2026-05-26
**Student:** g1r3-edward
**Context:** Cycle ~291, 21 consecutive NULL/NEG closures, plateau since H148 merged at cycle ~245.
**Baseline:** val/loss 3.26364 (PR #1157, H148, W&B `jg6p3l50`)
**WIN threshold:** <3.26284 (Δ = −0.00080 vs baseline)
**NULL band:** [3.26194, 3.26534]
**Edward's in-flight:** H156 Near-Identity Body Init (body init axis)

**In-flight (DO NOT duplicate):** H162 (per-block MuonH LR), H164 (MuonBP NS5), H165 (MGUP-on-AdamW-aux), H166 (Gradient Centralization), H167 (AdamP-on-aux), H168 (AdaBelief-on-aux), H169 (Adan-on-aux)

---

## Candidate Ranking Summary

Five hypotheses evaluated; two selected for immediate assignment, three deferred.

| Rank | Hypothesis | Target axis | Mechanistic anchor | LoC | Risk |
|------|-----------|-------------|-------------------|-----|------|
| 1 | FIRE-style AdamW v reset at cooldown entry | aux AdamW state | H161 bit-frozen finding | ~30 | Low |
| 2 | Momentum-SAM on aux AdamW (MSAM-aux) | aux perturbation | MSAM NeurIPS 2025 | ~50 | Medium |
| 3 | AdaMuon second moment on NS5 body | body update scaling | AdaMuon arXiv 2507.11005 | ~40 | Medium |
| 4 | Functional SAM on lm_head (logit-SAM) | lm_head perturbation | H158 brittleness + ICML 2025 | ~35 | Medium |
| 5 | Gradient sign coherence gate on MuonH body | body gradient filter | H155 cos(m,g) finding | ~45 | High |

---

## H_NEW_1: FIRE-Style AdamW Second-Moment Reset at Cooldown Entry

**SELECTED — Highest priority**

### Mechanism

At the step index when LR cooldown begins, execute a one-shot reset of the aux AdamW `exp_avg_sq` (v) buffer to its layer-wise mean (isotropic value), while leaving `exp_avg` (m₁) untouched.

The mechanistic claim is direct: H161 found that late-cooldown parameter F-norms become "bit-frozen" — an optimizer-state phenomenon, not a parameter-state phenomenon. The most natural explanation is that v (the second-moment EMA) has grown large and non-uniform over 3000+ stable-phase steps, causing the effective per-element LR (α / sqrt(v + ε)) to be so small for the "already learned" directions that the gradient signal from cooldown cannot actually move the parameters. A one-shot reset to v_iso = mean(v) at cooldown entry rebalances the effective LR across elements, allowing the momentum signal (m₁) to act on parameters again. This is analogous to FIRE (ICLR 2026, Han et al.) which reinitializes weight matrices to near-isometry; here we reinitialize the optimizer's curvature estimate to isotropic.

**Why this is different from H161 (which closed):** H161 tested parameter-level interventions (cooldown µ recovery). This hypothesis targets the optimizer STATE (the v buffer), not the parameters themselves. H161's finding that late-noise proves NULL is consistent with this: if v is the bottleneck, adding noise to parameters cannot help because AdamW will immediately dampen the noise signal with the large existing v values.

**Why this is different from H168 (AdaBelief-on-aux, in-flight):** AdaBelief changes the FORMULA for v on every step. This hypothesis uses standard AdamW formula but performs one targeted reset at cooldown entry only. These are orthogonal axes.

**Literature anchor:** FIRE (Han et al., ICLR 2026 Oral) — "Frobenius-Isometry Reinitialization" tests the idea that parameter isometry at key training phases improves convergence. The conceptual parallel here is optimizer-state isometry rather than weight isometry. AdaFactor's periodic second-moment factorization reset (Shazeer & Stern 2018) is an older ancestor: they found that resetting rank-1 curvature estimates periodically prevents curvature mismatch accumulation.

### Implementation

Add one argparse flag:

```python
parser.add_argument("--aux_adamw_v_reset", type=str,
                    default=os.environ.get("AUX_ADAMW_V_RESET", "off"),
                    choices=["off", "cooldown_isotropic"],
                    help="One-shot AdamW v buffer reset at cooldown entry. "
                         "'off' = baseline bit-identical.")
```

In the training loop, after the step counter increments and before the optimizer step, detect cooldown entry:

```python
# Detect cooldown entry (one-shot)
if args.aux_adamw_v_reset == "cooldown_isotropic":
    # cooldown_start_step = total_steps - cooldown_steps (already computed for LR schedule)
    if step == cooldown_start_step:
        for group in aux_optimizer.param_groups:
            for p in group["params"]:
                if p in aux_optimizer.state:
                    state = aux_optimizer.state[p]
                    if "exp_avg_sq" in state:
                        v = state["exp_avg_sq"]
                        # Reset to layer-wise isotropic mean
                        v.fill_(v.mean().item())
```

**Critical detail:** `cooldown_start_step` must match the exact step used by the LR scheduler — off-by-one would miss the trigger or double-fire. Verify the scheduler step indexing in `train_gpt_simple.py` before submitting. The reset must fire before the AdamW `.step()` call, not after.

**Feature flag off = bit-identical to baseline:** Yes. When `aux_adamw_v_reset == "off"`, no code path changes.

**LoC estimate:** ~30 lines.

### 3-Arm Chain Design

**arm_a CTRL:** Standard baseline, no v reset.

```
--aux_adamw_v_reset off
```

**arm_b COOLDOWN_ISO_RESET:** One-shot v reset at cooldown entry.

```
--aux_adamw_v_reset cooldown_isotropic
```

**arm_c (diagnostic — optional, time permitting):** Same as arm_b but log `exp_avg_sq.mean()` and `p.data.norm()` for each aux group at cooldown_start_step-1 and cooldown_start_step+1, to confirm the mechanism (v mean drops, param mobility increases). If logging is not easily injectable, skip arm_c and instead inspect arm_b W&B telemetry for any sign of a loss kink at cooldown entry.

### Expected Telemetry

**If hypothesis is correct:**
- val/loss should show sharper descent in cooldown phase (steps 2800–3325) compared to CTRL
- train/loss in cooldown should diverge from arm_a train/loss between steps 2800–3000
- Final val/loss: arm_b below 3.26284 (WIN threshold)
- The improvement should come almost entirely from the last 500 steps (cleanly localized to cooldown)

**If hypothesis is incorrect:**
- arm_b train/loss identical to arm_a after step 2800 (v reset has no effect — v was not the bottleneck)
- val/loss at 3325 steps is within ±0.0005 of arm_a (NULL)
- Or: v reset causes instability in cooldown (v too small → effective LR spike → divergence or NEG)

**Falsifying result:** If arm_b val/loss ≥ arm_a val/loss, the v bottleneck explanation for H161's bit-frozen finding is wrong. The failure mode is more likely either: (a) v is not large enough to matter, or (b) m₁ is itself directionally wrong and no amount of effective LR increase helps.

**WIN condition mechanistic interpretation:** A WIN confirms that accumulated curvature estimates in AdamW aux suppress late-phase learning, and that the cooldown LR schedule is operating against an effectively dead optimizer state. This would open a broader direction: periodic v resets, progressive v decay, or v warm-starting from a fresh initial value at cooldown.

### Wall-clock estimate

2-arm run × 1.65h/arm ≈ 3.3h total (fits within 5.5h budget).

---

## H_NEW_2: Momentum-SAM on Aux AdamW (MSAM-Aux)

**SELECTED — Second priority**

### Mechanism

Apply Momentum-SAM (MSAM, Becker et al. NeurIPS 2025) to the aux AdamW parameter group (embeddings, lm_head, biases, scalars). MSAM uses the optimizer's own accumulated first-moment vector (m₁) as the SAM perturbation direction instead of computing a separate gradient ascent step. This adds zero extra forward-backward passes — the perturbation direction comes from the existing momentum buffer.

The mechanistic claim: the aux AdamW group includes lm_head, which H158 showed has F-norm brittleness on the LR axis and is likely operating near a sharp loss region (gradient descent is unstable along certain perturbation directions). H165's MGUP-on-AdamW result (in-flight) tests whether a full optimizer replacement helps; MSAM-aux tests whether a targeted perturbation mechanism layered ON TOP of AdamW helps — these are orthogonal axes.

**The momentum direction as a sharpness proxy:** Becker et al. prove that MSAM's perturbation (ρ · m₁ / ||m₁||) approximates a gradient ascent step at the Nesterov-anticipated future point, directly connecting MSAM to the Nesterov-accelerated gradient intuition. The cos(m,g) sign POSITIVE finding for aux (from H165's early W&B data) is exactly what MSAM requires: m₁ is already aligned with the gradient, so using m₁ as a SAM perturbation direction is well-motivated (perturbation direction ≈ local gradient direction ≈ worst-case neighbor).

**Why not apply to MuonH body:** MuonH body already has cos(m,g) NEGATIVE (H155 finding). Negative cosine means m₁ and g point in opposite directions — using m₁ as SAM perturbation would push AWAY from the gradient rather than toward a sharper neighbor. MSAM-aux applies only to aux params where the sign is positive.

**Literature anchor:** "Momentum-SAM" (Becker et al., NeurIPS 2025) — introduces MSAM as a zero-extra-FLOPs SAM variant using momentum direction. "Functional SAM" (Singh et al., ICML 2025) warns that standard SAM applied to LLM weight norms causes logit hijacking; MSAM-aux sidesteps this because (a) it applies only to aux group, not full model, and (b) the perturbation is momentum-normalized, not gradient-norm normalized.

### Implementation

Add two argparse flags:

```python
parser.add_argument("--aux_msam_rho", type=float,
                    default=float(os.environ.get("AUX_MSAM_RHO", "0.0")),
                    help="MSAM perturbation radius for aux AdamW. 0.0 = off (baseline bit-identical).")
parser.add_argument("--aux_msam_start_step", type=int,
                    default=int(os.environ.get("AUX_MSAM_START_STEP", "0")),
                    help="Step to begin MSAM perturbation. 0 = from step 1.")
```

MSAM requires access to m₁ before the step. Insert in the training loop after loss.backward() but before aux_optimizer.step():

```python
# MSAM perturbation (aux AdamW only)
if args.aux_msam_rho > 0.0 and step >= args.aux_msam_start_step:
    perturbed_params = []
    for group in aux_optimizer.param_groups:
        for p in group["params"]:
            if p.grad is None:
                continue
            state = aux_optimizer.state.get(p, {})
            if "exp_avg" not in state:
                # m1 not yet initialized — skip this step
                continue
            m1 = state["exp_avg"]
            m1_norm = m1.norm()
            if m1_norm < 1e-8:
                continue
            # Perturb in momentum direction
            perturbation = args.aux_msam_rho * m1 / m1_norm
            p.data.add_(perturbation)
            perturbed_params.append((p, perturbation))

    # Recompute loss at perturbed point (for aux only — body is not perturbed)
    # Note: with mixed optimizers, we need only the aux grad update at perturbed point.
    # A full forward-backward here would give sharpness-aware gradients for aux params.
    # For zero-overhead version: skip recompute and use current grad (approximate MSAM).
    # For exact MSAM: forward + backward again with body params frozen.
    
    # Restore parameters
    for p, perturbation in perturbed_params:
        p.data.sub_(perturbation)
```

**Implementation choice — approximate vs exact MSAM:**
- Approximate MSAM (zero extra FLOPs): perturb, use EXISTING grad computed at original point, unperturb, then step. This is the zero-overhead version — momentum direction regularizes the step without recomputing grads.
- Exact MSAM: perturb, recompute forward+backward (freezing body params for efficiency), unperturb, step with perturbed-point gradients. ~1.5× wall-clock overhead.

Recommend **approximate MSAM** for arm_b (fast) and **exact MSAM** for arm_c (if budget allows, otherwise skip). The approximate version still flattens the loss surface in the momentum direction by incorporating the perturbation as a regularizer on the gradient-step direction.

**Feature flag off = bit-identical:** Yes. `rho=0.0` → perturbation is zero → no-op.

**LoC estimate:** ~50 lines.

### 3-Arm Chain Design

**arm_a CTRL:** Standard baseline.

```
--aux_msam_rho 0.0
```

**arm_b MSAM_RHO_0.01:** Light perturbation. At rho=0.01 with typical aux param norm ~O(1–10), perturbation magnitude ≈ 1% of typical parameter scale. Conservative starting point.

```
--aux_msam_rho 0.01 --aux_msam_start_step 0
```

**arm_c MSAM_RHO_0.05:** Stronger perturbation. Standard SAM papers use rho in [0.01, 0.1] for language tasks; 0.05 is a reasonable upper bound for the aux group given lm_head brittleness.

```
--aux_msam_rho 0.05 --aux_msam_start_step 0
```

**rho selection rationale:** Below rho=0.005, the perturbation is negligible relative to optimizer noise. Above rho=0.1, perturbation may destabilize lm_head given its F-norm brittleness (H158). The two arms bracket the useful regime.

### Expected Telemetry

**If hypothesis is correct:**
- Slightly slower early convergence (sharpness-aware training trades early speed for final quality)
- val/loss at 3325 steps: arm_b or arm_c below 3.26284 (WIN threshold)
- lm_head F-norm should be MORE stable across steps (perturbation regularizes the sharp lm_head landscape)

**If hypothesis is incorrect:**
- arm_b/arm_c identical to arm_a (perturbation too small or momentum direction not aligned with sharpness)
- Or: NEG result if rho=0.05 destabilizes lm_head (look for spike in train/loss around steps 100–300)

**Falsifying result:** If arm_b (rho=0.01) produces a clear NEG, aux parameters are too brittle for any SAM perturbation and the sharpness axis is closed for aux. If arm_b is NULL and arm_c is NEG, rho sensitivity is steep — try rho=0.03 in a follow-up if the mechanism shows any directional trend.

**WIN condition mechanistic interpretation:** A WIN confirms that aux AdamW parameters (particularly lm_head) are in a sharp loss basin and that momentum-direction perturbation successfully regularizes toward flatter solutions. This would suggest Functional SAM (ICML 2025) on lm_head specifically as the next direction.

### Wall-clock estimate

3-arm run × 1.65h/arm ≈ 4.95h total (within 5.5h budget, tight).

---

## H_NEW_3: AdaMuon Per-Element Second Moment on NS5 Body Gradients

**DEFERRED — Third priority; assign only if edward completes H156+H_NEW_1 before cycle ends**

### Mechanism

After NS5 orthogonalization produces an update direction `u` for each MuonH body parameter, maintain an element-wise EMA of squared updates `v_elem` and scale the final update by `u / (sqrt(v_elem) + ε)` before Frobenius-ball projection. This gives per-element adaptive scaling within the hyperball geometry, analogous to how Adam gives per-element adaptive scaling within Euclidean geometry.

The mechanistic claim: current MuonH applies uniform scaling within the hyperball (scale_invariant_update_ holds F-norm constant via a single global rescale). This means all singular modes of the update are treated equally after NS5 orthogonalization. AdaMuon (arXiv 2507.11005, Modded-NanoGPT community) argues that per-element variance of the NS5 output is non-uniform in practice, and that element-wise normalization improves conditioning. The v_elem EMA is initialized to 1.0 (no-op at first step) and converges to the element-wise update variance over training.

**Orthogonality:** H167 (AdamP-on-aux) and H168 (AdaBelief-on-aux) target the aux AdamW group. This hypothesis targets the MuonH body group with a fundamentally different mechanism: adding adaptive scaling to the orthogonalized gradient, not replacing the optimizer formula.

**Literature anchor:** AdaMuon (anon/community, arXiv 2507.11005) — element-wise second-moment + sign-stabilized orthogonalization; reports ~0.002 improvement on a similar nanoGPT benchmark. FIRE (Han et al., ICLR 2026 Oral) — validates that NS5 orthogonalization at key points improves GPT training, establishing NS5 as a reliable primitive to build on.

### Implementation

```python
parser.add_argument("--muonh_adamuon", type=int,
                    default=int(os.environ.get("MUONH_ADAMUON", "0")),
                    choices=[0, 1],
                    help="AdaMuon: per-element second moment on NS5 updates. 0=off (baseline).")
parser.add_argument("--muonh_adamuon_beta2", type=float,
                    default=float(os.environ.get("MUONH_ADAMUON_BETA2", "0.999")),
                    help="AdaMuon beta2 for v_elem EMA.")
parser.add_argument("--muonh_adamuon_eps", type=float,
                    default=float(os.environ.get("MUONH_ADAMUON_EPS", "1e-8")),
                    help="AdaMuon eps for v_elem denominator.")
```

In `MuonH.step()`, state initialization block add:

```python
if args.muonh_adamuon:
    state["v_elem"] = torch.ones_like(p.data)
    state["adamuon_step"] = 0
```

After NS5 produces orthogonalized update `u` and before `scale_invariant_update_`:

```python
if args.muonh_adamuon:
    state["adamuon_step"] += 1
    beta2 = args.muonh_adamuon_beta2
    eps = args.muonh_adamuon_eps
    v_elem = state["v_elem"]
    v_elem.mul_(beta2).addcmul_(u, u, value=1 - beta2)
    # Bias correction
    bc = 1.0 - beta2 ** state["adamuon_step"]
    u = u / (v_elem.sqrt() / math.sqrt(bc) + eps)
    # Renormalize to match pre-adamuon F-norm (preserve hyperball radius)
    u_norm = u.norm()
    orig_norm = ... # norm before element-wise scaling
    if u_norm > 0:
        u.mul_(orig_norm / u_norm)
```

**Critical detail:** The F-norm renormalization after element-wise scaling is mandatory — without it, AdaMuon will systematically change the effective hyperball radius and invalidate the scale_invariant_update_ guarantee.

**LoC estimate:** ~40 lines.

### Arm Structure

arm_a CTRL, arm_b ADAMUON_BETA2_0.999, arm_c ADAMUON_BETA2_0.99 (faster adaptation).

---

## H_NEW_4: Functional SAM on lm_head Only (Logit-SAM)

**DEFERRED — Fourth priority**

### Mechanism

Apply the Functional SAM perturbation (Singh et al., ICML 2025) to the lm_head weight only, perturbing in the direction that maximally increases the variance of output logit statistics (a function-space perturbation), then taking a standard backward pass. Standard SAM fails for LLMs via logit hijacking; Functional SAM sidesteps this by perturbing through logit statistics (mean/variance of the softmax output) rather than weight norms.

The H158 finding that lm_head F-norm has LR-axis brittleness (scales linearly with LR) and init-axis non-recovery directly motivates this: lm_head is operating in a sharp basin and standard gradient descent is insufficient to escape it. Logit-SAM perturbs lm_head in the direction of maximal logit variance increase, which directly addresses the sharpness in the output logit space.

**LoC estimate:** ~35 lines.

**Arm structure:** arm_a CTRL, arm_b LOGIT_SAM_RHO_0.01, arm_c LOGIT_SAM_RHO_0.05.

**Deferred because:** H_NEW_2 (MSAM-aux) covers the aux SAM direction more broadly and with less implementation complexity. If MSAM-aux wins, Functional SAM becomes the natural follow-up for lm_head specifically.

---

## H_NEW_5: Gradient Sign Coherence Gate on MuonH Body

**DEFERRED — Fifth priority**

### Mechanism

Before NS5 orthogonalization, apply an element-wise coherence mask to the gradient: pass only elements where `sign(grad_t) == sign(m₁_t)` (both agree on update direction). Elements in disagreement are zeroed before entering NS5. The H155 finding that cos(m,g) is NEGATIVE for MuonH body (many elements in anti-agreement) suggests a large fraction of gradient elements are fighting the accumulated momentum direction — possibly noise rather than signal.

**Mechanistic claim:** Pre-NS5 gradient filtering removes the noisiest elements before orthogonalization, giving NS5 a cleaner input. NS5 will then produce an orthogonal projection that more faithfully represents the agreeing signal.

**Risk:** The coherence gate discards gradient information. If the anti-agreement elements carry genuine curvature signal (not noise), this will hurt. The H155 finding alone does not distinguish "noisy elements" from "genuine curvature." This hypothesis has higher variance.

**LoC estimate:** ~45 lines.

**Deferred because:** Risk is higher than H_NEW_1 and H_NEW_2. Assign only after the higher-priority hypotheses have been tested.

---

## Primary Recommendation for Immediate Assignment

**Assign H_NEW_1 (FIRE-Style AdamW v Reset) to edward after H156 closes.**

Rationale:
1. Directly and mechanistically attacks the H161 bit-frozen finding — the only programme-grade finding that has not yet been targeted by a follow-up experiment.
2. Zero ongoing compute overhead — it is a one-shot state modification.
3. Clean on/off feature flag with bit-identical off path.
4. The FIRE paper (ICLR 2026 Oral) provides the closest validated analogue: resetting optimizer state toward isometry at a key training phase.
5. Completely orthogonal to all 7 in-flight experiments and to H156.
6. Implementation risk is low: ~30 LoC, no new optimizer state tensors, single trigger point.

**If edward has compute budget remaining after H_NEW_1, assign H_NEW_2 (MSAM-aux).**

---

## Reproduce Commands (H_NEW_1)

```bash
# arm_a CTRL
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r3-edward/H_FIRE_VRESET-ctrl" \
  --wandb_group "H_FIRE_VRESET-aux-adamw-v-reset" \
  --num_trials 1 --train_steps 3325 \
  --aux_adamw_v_reset off \
  --muonh_mode scale_invariant --muonh_cooldown_shape linear \
  --muonh_warmup_steps 100 --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 --aux_beta2_schedule constant \
  --aux_beta2_start 0.99 --muonh_mu_schedule linear \
  --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched

# arm_b COOLDOWN_ISO_RESET
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r3-edward/H_FIRE_VRESET-cooldown-iso" \
  --wandb_group "H_FIRE_VRESET-aux-adamw-v-reset" \
  --num_trials 1 --train_steps 3325 \
  --aux_adamw_v_reset cooldown_isotropic \
  --muonh_mode scale_invariant --muonh_cooldown_shape linear \
  --muonh_warmup_steps 100 --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 --aux_beta2_schedule constant \
  --aux_beta2_start 0.99 --muonh_mu_schedule linear \
  --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched
```

Base hyperparameters inherited from H148 arm_b (current baseline). DO NOT retune optimizer hyperparameters — only the aux_adamw_v_reset flag changes.

---

## Research State Update

**Current best explanation for the plateau:** The optimizer has reached a regime where (a) the hyperball geometry constrains MuonH body updates to a fixed F-norm budget that is well-calibrated from H148's init, (b) the aux AdamW group has accumulated curvature estimates (v) that dampen late-phase learning (H161 bit-frozen), and (c) the outer MuLoCo amplification mechanism (H163) is already active and contributing. The remaining headroom is likely in the aux optimizer state dynamics during cooldown, not in further init or schedule tuning.

**Evidence supporting this:** H161 (bit-frozen), H163 (outer amplification = load-bearing), H155 (cos(m,g) negative on body = MuonH already fighting noise), 21 NULL/NEG closures across init/schedule/architecture axes.

**Ruled-out paths:**
- Late-noise probes (H161 NULL bilateral)
- Cooldown µ recovery (H159 NULL bilateral)
- Pure hyperparameter hill-climbing on LR/WD
- Body init variants beyond orthogonal (H148 axis is mined; H156 explores last direction)
- Aux optimizer REPLACEMENT (H165/H167/H168/H169 all in-flight; avoid duplicating)

**Open uncertainties:**
1. Is the v buffer the specific bottleneck for bit-freezing, or is m₁ directionally wrong regardless of effective LR?
2. Does the outer MuLoCo sync (every 30 steps) interfere with fine-grained cooldown dynamics?
3. Is there a distinct failure mode in the lm_head that SAM-class methods can address?

**Next discriminating experiment:** H_NEW_1 (FIRE-style v reset). If arm_b val/loss drops > 0.0008 vs CTRL in the final 500 steps, the v bottleneck is confirmed. If NULL, the bit-frozen phenomenon is parameter-level not state-level, and the next direction is m₁ diagnosis.

**Stop condition for this direction:** If H_NEW_1 is NULL and H_NEW_2 is NULL, the aux AdamW state axis is exhausted. Redirect to MuonH body curvature (H_NEW_3 AdaMuon) or to a completely different abstraction level (data curriculum, position encoding, activation function).

---

## Taste Rubric

**H_NEW_1 (FIRE-style v reset):**
- Research mode: Frontier refinement (attacks a specific confirmed bottleneck)
- Mechanistic grounding: 4 — directly targets H161 bit-frozen finding with a named mechanism (v dampening), FIRE analogue, AdaFactor precedent
- Research-state value: 4 — WIN or FAIL both update the research map cleanly; failure rules out v as the bit-frozen bottleneck
- Execution value: 4 — ~30 LoC, zero ongoing FLOPs overhead, 2-arm design fits in 3.3h
- **Overall: 4/4/4 — highest priority**

**H_NEW_2 (MSAM-aux):**
- Research mode: Diagnostic (tests sharpness axis for aux params)
- Mechanistic grounding: 3 — motivated by H158 brittleness + cos(m,g) positive finding, MSAM paper directly applicable; link to this codebase is slightly loose (H158 finding was about init, not optimizer perturbation)
- Research-state value: 3 — WIN confirms sharpness is the aux bottleneck; FAIL constrains SAM-class methods for aux
- Execution value: 2 — 3-arm, 4.95h (tight budget), approximate vs exact MSAM adds interpretation complexity
- **Overall: 3/3/2 — second priority**

**H_NEW_3 (AdaMuon per-element second moment):**
- Research mode: Frontier refinement (adds adaptive scaling to MuonH body)
- Mechanistic grounding: 2 — community paper with similar benchmark, but MuonH-specific coupling to hyperball not validated
- Research-state value: 3 — results would constrain whether uniform vs adaptive scaling matters for hyperball geometry
- Execution value: 2 — medium complexity (~40 LoC), F-norm renormalization adds risk of silent bugs
- **Overall: 2/3/2 — deferred**

**H_NEW_4 (Functional SAM on lm_head):**
- Research mode: Diagnostic (tests lm_head-specific sharpness)
- Mechanistic grounding: 3 — H158 provides direct motivation; ICML 2025 FSAM paper validated for LLMs
- Research-state value: 2 — overlaps with H_NEW_2 direction; add value only if MSAM-aux fails
- Execution value: 2 — implementation complexity (logit perturbation setup); deferred behind H_NEW_2
- **Overall: 3/2/2 — deferred**

**H_NEW_5 (Sign coherence gate):**
- Research mode: Tier shift (pre-filter MuonH input)
- Mechanistic grounding: 2 — H155 cos(m,g) negative motivates but does not confirm noise is the cause
- Research-state value: 3 — would directly test whether negative cos(m,g) means noise vs genuine curvature
- Execution value: 1 — information loss risk is high; no external validation in similar settings
- **Overall: 2/3/1 — deferred**

---

## Confidence

**H_NEW_1:** Strong — H161 provides direct programme-grade evidence for the bit-frozen phenomenon; FIRE (ICLR 2026 Oral) and AdaFactor provide external validation of the optimizer-state-reset mechanism class; implementation risk is low.

**H_NEW_2:** Moderate — MSAM paper is validated on classification benchmarks; H158 and cos(m,g) positive findings for aux provide indirect motivation; no direct validation on language model aux AdamW in this exact configuration.

**H_NEW_3–5:** Speculative — interesting mechanisms with some external support but no confirmed connection to the specific bottleneck in this programme.
