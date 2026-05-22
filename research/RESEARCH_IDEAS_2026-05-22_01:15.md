# Research Ideas — 2026-05-22 01:15 (Cycle 40 Plateau Escalation)

**Context**: Baseline is val/loss=3.27119 at ffs=3100 (PR #443). Stack: MuonH-SI + MuLoCo outer (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) + dual AGC (clip_ratio=0.05) + cosine MuonH cooldown + aux linear cooldown + aux eps=1e-6. Fixed 3325 steps, GPT-768/12L, FineWeb.

**Constraints confirmed closed** (do not revisit without new evidence):
- Iterate-averaging family (EMA/SWA/SF/Lookahead): PRs #525, #200, #531, #555
- VR-on-aux 5-mechanism / 4-class closure: PRs #531, #544, #567, #582, #646
- Left-only Kronecker on MuonH (scale_invariant overwrites): PR #700
- Gradient Centralization on MuonH inner (RMSNorm null-space): PR #672
- PAdam v_t power p!=0.5 (diverges): PR #643
- Aux AdamW structural pieces (beta1=0.8, beta2=0.95, v_t power all load-bearing): PRs #612, #631, #643
- Cooldown-gated inner momentum reset (path-dependence): PR #636
- Long-horizon aux EMA during cooldown (cooldown demands sharp aux updates): PR #689
- Per-group eps decoupling: PR #670
- Aux AdamW warmup: PR #412
- Init rescaling (MuonH-SI washes out init differences): PR #298
- Phase-gating inner momentum: PR #636

**Public benchmark gap**: Best public solution achieves ffs=3030 vs our ffs=3100. PR #20 uses Contra-Muon + Soft-Muon + SOAP MLP + SOAP attn trust gate on a different base stack. These core techniques have never been stacked on our MuLoCo×MuonH-SI baseline.

---

## Idea 1: Contra-Muon × MuonH-SI stack

**Hypothesis**: Adding Contra-Muon's coordinated-update correction on top of MuonH-SI will improve convergence by aligning the NS5 update direction with the actual gradient direction, recovering lost signal that pure orthogonalization discards.

**Mechanism**: Contra-Muon modifies the NS5 orthogonalized update `u = NS5(g)` by computing an operator-norm correction factor: `u_contra = u - γ · (u·u^T·g / ||u||_F^2)`. This removes the component of `u` that is anti-aligned with `g` in the operator sense, producing an update that is both orthogonalized AND directionally consistent with the true gradient. The public leaderboard result #20 (ffs=3030, 70 fewer steps than our 3100) uses this technique on a different optimizer stack. It has never been tested on the MuLoCo×MuonH-SI baseline (PR #134 in queue, never ran).

**Why not closed**: Contra-Muon operates on the DIRECTION of the MuonH inner update before it reaches MuLoCo outer — it is NOT iterate-averaging, NOT VR-on-aux, NOT a preconditioner change, NOT a warmup schedule. It is a direction correction on the NS5 orthogonalization step itself. None of the closure experiments touch this mechanism.

**Implementation**:
```python
# In muon_update() inside train_gpt_simple.py, after computing:
# update = newton_schulz5(grad_matrix, steps=12)  # NS5 orthogonalized
# Insert contra correction before applying:
# gamma is a hyperparameter in [0.0, 0.5]
if contra_gamma > 0.0:
    # operator-norm direction alignment
    ug = (update * grad_matrix).sum()       # <u, g> in Frobenius sense
    uu = (update * update).sum()            # ||u||_F^2
    if uu > 0:
        update = update - contra_gamma * (ug / uu) * update
        # re-normalize to unit Frobenius norm (NS5 output convention)
        update = update / (update.norm() + 1e-8) * update.norm().detach()
```

**Arm design** (2-arm sweep):
- Arm A: `contra_gamma=0.1` — modest correction
- Arm B: `contra_gamma=0.3` — stronger correction, closer to public #20 spirit

**Risk assessment**: Medium. The mechanism is externally validated (public #20) but on a different base stack. MuLoCo outer Nesterov might interact nonlinearly with Contra correction — the outer momentum accumulates contra-corrected deltas, which could either amplify or cancel the benefit. Key failure mode: if MuLoCo already handles the directional alignment implicitly via its outer Nesterov momentum, Contra may be redundant or harmful. Crossover risk: Contra removes gradient signal → looser constraint → possible cooldown degradation. Monitor step-2500 trajectory.

**Expected signal**: val/loss improvement of 0.001–0.003, ffs reduction of 20–50 steps.

---

## Idea 2: Soft-Muon × MuonH-SI interpolation

**Hypothesis**: Interpolating the MuonH inner update between the NS5-orthogonalized direction and the raw gradient (Soft-Muon) will achieve better convergence by preserving gradient magnitude information while still benefiting from orthogonalization's noise reduction.

**Mechanism**: Pure NS5 orthogonalization maps `g → NS5(g)` where the output is on the Stiefel manifold (unit Frobenius norm, approximate orthogonal). This discards ALL magnitude information. Soft-Muon instead computes `u = α·NS5(g) + (1-α)·(g/||g||_F)`, interpolating between orthogonalized and normalized-raw update. At α=1.0 we recover standard Muon; at α=0.0 we get pure gradient-direction updates. The optimal α trades off manifold geometry (NS5) against gradient magnitude geometry (raw). Public result #20 (ffs=3030) uses Soft-Muon alongside Contra-Muon. PR #142 has never run on our baseline.

**Why not closed**: Like Contra-Muon, this operates on the pre-MuLoCo inner update direction. None of the closed experiments (iterate-averaging, VR, preconditioner, etc.) touch the NS5 interpolation axis. Gradient Centralization closure (PR #672) is a DIFFERENT mechanism (subtracts mean, orthogonal to interpolation).

**Implementation**:
```python
# In muon_update(), replace:
#   update = newton_schulz5(grad_matrix, steps=12)
# with:
ns5_update = newton_schulz5(grad_matrix, steps=12)  # Frobenius-unit
g_norm = grad_matrix / (grad_matrix.norm() + 1e-8)  # normalized raw
update = soft_alpha * ns5_update + (1 - soft_alpha) * g_norm
# re-normalize to Frobenius unit (preserve scale convention)
update = update / (update.norm() + 1e-8) * ns5_update.norm().detach()
```

**Arm design** (3-arm sweep):
- Arm A: `soft_alpha=0.95` — 5% gradient blending, conservative
- Arm B: `soft_alpha=0.85` — 15% gradient blending, moderate (matches PR #142 queued values)
- Arm C: `soft_alpha=0.90` — 10% gradient blending, intermediate

**Risk assessment**: Medium-low. The interpolation is smooth and easily reversible. Key failure mode: at the wrong α, we reintroduce the ill-conditioning NS5 was designed to remove. Magnitude information from raw gradient could destabilize scale-invariant mode if the normalization conventions don't align. Important: ensure final update maintains the same scale convention as baseline (the re-normalize step above is critical). Arm A is the safest entry point.

**Expected signal**: val/loss improvement of 0.001–0.003, ffs reduction of 15–40 steps. Best case: matches or exceeds public #20 efficiency.

---

## Idea 3: RACS-style row-column scaled aux preconditioner

**Hypothesis**: Replacing AdamW's per-element v_t second-moment with a row-and-column aggregated diagonal (RACS-style) will provide a better-structured approximation of the Fisher information matrix for embed/lm_head parameters without the instability axes that closed per-element alternatives (PAdam p≠0.5, β2=0 pruning) triggered.

**Mechanism**: Row-and-Column Scaled SGD (RACS, ICLR 2026) computes:
  `v_row[i] = mean_j(g[i,j]^2)` and `v_col[j] = mean_i(g[i,j]^2)`
  `precond_scale[i,j] = 1 / sqrt(v_row[i] * v_col[j])`
  
This is a rank-2 structured approximation to the full second-moment matrix. Unlike PAdam (closed, changes v_t power globally), this changes the STRUCTURE of the preconditioner from per-element to row-column factored, which is a qualitatively different axis. The closed experiments (PAdam, β2 sweep, eps sweep) all preserve the per-element structure — they only tune the power or scale. RACS provides a structured FIM approximation that has demonstrated convergence speed improvements on LLM pretraining.

**Why not closed**: The complete AdamW preconditioner closure (PRs #643, #631, #612) establishes that the PER-ELEMENT structure with β1=0.8, β2=0.95, p=0.5 is load-bearing. RACS is NOT a modification to per-element v_t — it REPLACES the per-element accumulation with a factored row-column structure. This is mechanistically distinct. The closed axes are: (a) v_t power change (PAdam, closed), (b) β2 removal (closed), (c) β1 removal (closed). RACS row-column factoring is axis (d) — untested.

**Implementation sketch**:
```python
# Replace aux AdamW's EMA+sqrt step for 2D weight matrices:
# Standard: v = beta2*v + (1-beta2)*g^2; update = g / (sqrt(v) + eps)
# RACS variant (for 2D tensors only, keep standard for 1D):
if g.dim() == 2:
    # Row and column second-moment aggregation
    g_sq = g.pow(2)
    v_row = beta2 * v_row + (1 - beta2) * g_sq.mean(dim=1, keepdim=True)
    v_col = beta2 * v_col + (1 - beta2) * g_sq.mean(dim=0, keepdim=True)
    # Factored preconditioner
    scale = (v_row * v_col).sqrt() + eps
    update = g / scale
else:
    # Standard AdamW for 1D params (biases, layer norms)
    v = beta2 * v + (1 - beta2) * g_sq
    update = g / (v.sqrt() + eps)
```

**Arm design** (2-arm):
- Arm A: RACS on embed+lm_head, standard AdamW on scalars (highest-signal 2D groups)
- Arm B: RACS on all aux groups (full replacement)
- Key config: keep beta1=0.8, beta2=0.95, eps=1e-6 (load-bearing values preserved)

**Risk assessment**: Medium-high novelty, medium risk. Key failure mode: row-column factoring may over-smooth the preconditioner relative to per-element, particularly during cooldown where individual parameter gradients become sparser. The geometric mean `sqrt(v_row * v_col)` may produce pathological scaling if row norms and column norms have very different magnitudes (embed matrix rows corresponding to rare tokens, for instance). Diagnostic: inspect per-token preconditioner scale magnitudes in early steps.

**Expected signal**: val/loss improvement of 0.001–0.004, ffs reduction of 20–60 steps. Uncertainty is higher than Ideas 1-2 due to less direct evidence. Literature result is strong but on a different training regime.

---

## Idea 4: Blockwise LR multipliers for aux parameter groups

**Hypothesis**: The embed.weight, lm_head.weight, and scalar parameter groups currently share the same aux lr schedule despite having different sharpness profiles and gradient scales. Applying distinct per-group lr multipliers will improve convergence by right-sizing the effective learning rate for each group's loss landscape geometry.

**Mechanism**: The Sharpness Disparity Principle (ICML 2025) demonstrates empirically that different transformer parameter blocks have distinct sharpness profiles that diverge significantly during training, and that blockwise learning rate assignment scaled to these profiles achieves ~2x convergence speedup vs uniform lr. Our aux groups cover: (a) embed.weight — vocabulary embedding, very large matrix, sparse gradients; (b) lm_head.weight — tied or independent output projection; (c) scalar params — biases, LayerNorm scale/bias, very small tensors. These have radically different gradient statistics. Current baseline: all share lr_mult=1.0 except embed which uses lr_mult=0.3 (from PR #237). The scalar group and lm_head group have never been separately tuned after the AGC merge.

**Why not closed**: PR #191 swept `embed lr_mult ∈ {0.15, 0.3, 0.5}` only. PR #670 swept per-group eps but kept lr_mult fixed. The lm_head and scalar groups have NEVER had their individual lr_mults swept since the AGC integration (PR #237). Distinct from eps tuning (closed), distinct from beta tuning (structural closure).

**Implementation**:
```python
# In set_hparams or optimizer creation, modify aux param groups:
# Current (post-baseline):
adam_embed: lr_mult=0.3, others: lr_mult=1.0

# Proposed sweep:
# Arm A: lm_head lr_mult = 0.5, scalars lr_mult = 1.5
# Arm B: lm_head lr_mult = 0.7, scalars lr_mult = 2.0
# Arm C: lm_head lr_mult = 0.3, scalars lr_mult = 2.0 (freeze lm_head more)
# Keep embed lr_mult=0.3 (established baseline)
# Note: AGC clip_ratio=0.05 continues to apply per-group
```

**Arm design** (2-arm sweep with gradient monitoring):
- Arm A: lm_head_lr_mult=0.5, scalars_lr_mult=1.5 — moderate differentiation
- Arm B: lm_head_lr_mult=0.7, scalars_lr_mult=2.0 — stronger differentiation
- Both arms: embed_lr_mult=0.3 unchanged

**Risk assessment**: Low-medium. This is a hyperparameter sweep on a well-understood axis (lr_mult). Key failure mode: scalars include critical LayerNorm parameters — if their lr is too high, RMSNorm can become unstable. Upside: if lm_head is over-regularized or scalars are under-tuned, even small adjustments will compound across the full 3325 steps. This is the most conservative experiment of this cycle.

**Expected signal**: val/loss improvement of 0.0005–0.002, ffs reduction of 10–25 steps. Lower ceiling than Ideas 1-3 but also lower risk and faster to debug.

---

## Idea 5: Per-step AGC clip_ratio schedule (tighter during cooldown)

**Hypothesis**: Applying a dynamic AGC clip_ratio schedule — looser during the stable training phase, tighter during cooldown — will improve convergence by preserving gradient signal during stable training while enforcing stronger gradient control during the cooldown phase where outlier gradients are most harmful.

**Mechanism**: PR #689's key finding is that "cooldown demands sharp aux updates." The current baseline uses a fixed clip_ratio=0.05 throughout training. During the stable phase, gradients are relatively well-conditioned and AGC clips infrequently. During cooldown, the LR decays but gradient variance may remain high relative to the decayed step size — a fixed clip_ratio of 0.05 may be too loose for the sharper landscape geometry near convergence. A schedule that tightens clip_ratio as LR decays keeps the effective trust radius proportional to the step size, analogous to how LAMB/LARS scale the update by the ratio of parameter norm to gradient norm.

**Implementation**:
```python
# In training loop, compute dynamic clip_ratio each step:
def get_dynamic_clip_ratio(step, total_steps, cooldown_start,
                            base_clip=0.05, min_clip=0.02):
    if step < cooldown_start:
        return base_clip  # no change during stable phase
    # linear tightening from base_clip to min_clip during cooldown
    progress = (step - cooldown_start) / (total_steps - cooldown_start)
    return base_clip - (base_clip - min_clip) * progress

# cooldown_start = total_steps * (1 - cooldown_frac)
# For baseline: cooldown_frac=1.0 → cooldown_start = 0 (full cosine)
# For aux linear cooldown: cooldown_frac=0.4 → cooldown_start = 3325*0.6 = 1995
```

**Note on interaction with MuonH cosine cooldown**: With MuonH cooldown_frac=1.0, the cooldown starts from step 0 for MuonH. The AGC schedule should probably track the AUX cooldown start (step 1995 for cooldown_frac=0.4) rather than MuonH cooldown, since it's the aux AGC that most benefits from tightening during the final convergence phase.

**Arm design** (2-arm):
- Arm A: aux_agc tightens from 0.05 → 0.02 during cooldown; muonh_agc stays fixed at 0.05
- Arm B: both aux_agc and muonh_agc tighten from 0.05 → 0.02 during cooldown

**Risk assessment**: Medium. The mechanism is well-motivated by PR #689's finding. Key failure mode: tightening AGC may clip beneficial large updates that are needed to navigate the final loss landscape. The crossover risk (technique that looks good mid-training but hurts cooldown) is inverted here — we're specifically designing the schedule to improve cooldown behavior. Monitor whether clip events increase at cooldown boundary.

**Expected signal**: val/loss improvement of 0.0005–0.002, ffs reduction of 10–30 steps.

---

## Idea 6: Contra-Muon + Soft-Muon joint stack (replicating public #20 kernel)

**Hypothesis**: The combination of Contra-Muon (direction alignment) and Soft-Muon (magnitude blending) applied together on MuonH-SI will synergistically reproduce the core of public result #20's optimizer advantage, potentially explaining the ffs=3030 vs our ffs=3100 gap.

**Mechanism**: Public result #20 explicitly uses both techniques together in its winning configuration. Ideas 1 and 2 above test them individually to diagnose which component carries the signal. Idea 6 tests the joint stack, which is what the public result uses. The two mechanisms are complementary: Contra removes anti-aligned components in the NS5 update; Soft blends in gradient magnitude. Together they modify both the DIRECTION and MAGNITUDE of the inner MuonH update. The joint effect may be greater than the sum due to interaction terms.

**Sequencing note**: This experiment should run AFTER Ideas 1 and 2 return results. If either individual technique improves performance, the joint stack is the natural follow-up. If both fail individually, the joint stack is still worth testing once (the interaction may be what produces the public result's benefit). If both succeed individually, the joint stack becomes the primary experiment.

**Implementation**: Combine the code from Ideas 1 and 2:
```python
# After NS5:
ns5_update = newton_schulz5(grad_matrix, steps=12)
# Step 1: Contra correction
if contra_gamma > 0.0:
    ug = (ns5_update * grad_matrix).sum()
    uu = (ns5_update * ns5_update).sum()
    if uu > 0:
        ns5_update = ns5_update - contra_gamma * (ug / uu) * ns5_update
# Step 2: Soft interpolation
g_norm = grad_matrix / (grad_matrix.norm() + 1e-8)
update = soft_alpha * ns5_update + (1 - soft_alpha) * g_norm
update = update / (update.norm() + 1e-8) * newton_schulz5(grad_matrix).norm().detach()
```

**Arm design** (1-arm, conditional on Ideas 1+2):
- Primary config: contra_gamma=0.1, soft_alpha=0.90 (best individual arms from Ideas 1+2)
- Only run this if at least one of Ideas 1 or 2 shows signal (delta > -0.0005)

**Risk assessment**: Medium — conditional on earlier results. Higher confidence if Ideas 1 and 2 individually show positive signal. If both fail individually, this is still a valid test but with lower prior.

**Expected signal**: val/loss improvement of 0.002–0.005 (cumulative of both techniques). If public #20's advantage is fully explained by this combination, could achieve ffs near 3030–3060.

---

## Idea 7: MuonH outer-loop warmup staggering (inner warmup vs outer sync onset)

**Hypothesis**: The MuLoCo outer Nesterov wrapper currently begins accumulating outer momentum from step 1. The inner MuonH-SI has a 100-step warmup during which it produces noisy, low-quality updates. Delaying the outer loop's sync onset until after the inner warmup completes (step 100) will prevent low-quality inner updates from poisoning the outer momentum buffer, improving the quality of the outer Nesterov velocity trajectory.

**Mechanism**: MuLoCo outer works by accumulating inner deltas `Δθ = θ_{t+sync} - θ_t` every 30 steps, then applying outer Nesterov: `v_outer = 0.5 * v_outer + Δθ; θ -= outer_lr * v_outer`. During steps 0-100 (warmup), the inner MuonH LR linearly ramps from 0 to full. The accumulated deltas `Δθ` during steps 0-30 and 30-60 and 60-90 are small-magnitude and potentially low-quality (the inner optimizer is still ramping). These low-quality deltas enter the outer momentum buffer and persist (with decay 0.5^(30/30) ≈ 0.5 per sync) for many subsequent steps. Delaying the outer sync onset until step 100 means the outer buffer is initialized from high-quality, fully-warm inner deltas.

**Why not closed**: PR #412 tests warmup ASYMMETRY (aux warmup vs MuonH warmup) and finds aux warmup harmful. That is a DIFFERENT mechanism — aux wants immediate full-gradient signal. This idea is about the OUTER LOOP initialization quality, not the inner or aux optimizer warmup schedule. PR #260 sweeps outer_momentum but not sync_onset. No prior experiment has tested staggering the outer sync onset.

**Implementation**:
```python
# In training loop, modify outer sync condition:
# Current: if (step + 1) % sync_interval == 0:
# Proposed: if step >= warmup_delay and (step - warmup_delay + 1) % sync_interval == 0:
# Where warmup_delay = muonh_warmup_steps = 100

# Additionally: skip outer velocity accumulation during warmup:
if step < muonh_warmup_steps:
    # Just track θ_0 but don't apply outer Nesterov
    outer_theta_snapshot = params.clone()
else:
    # Normal MuLoCo outer loop
    ...
```

**Arm design** (2-arm):
- Arm A: Delay outer sync onset to step 100 (matches inner warmup end)
- Arm B: Delay outer sync onset to step 60 (2 sync intervals into warmup, softer version)

**Risk assessment**: Low-medium. The mechanism is well-motivated by the known inner warmup dynamics. Key failure mode: delaying outer sync means 3 fewer outer sync cycles in the budget (steps 0-90 become inner-only), which could reduce the effective outer momentum benefit. Monitor outer_velocity magnitude evolution. If the outer momentum provides most of its benefit during stable phase (steps 100-2000), losing 3 early syncs matters little; if early syncs are critical for aligning outer trajectory, the delay will hurt.

**Expected signal**: val/loss improvement of 0.0005–0.002, ffs reduction of 5–20 steps. This is a targeted diagnostic as much as an optimization — it directly tests whether early outer sync quality matters.

---

## Priority ordering and experiment tree

```
Round 1 (run in parallel — independent):
├── Idea 1: Contra-Muon (gamma=0.1, 0.3)         [highest evidence, never ran]
├── Idea 2: Soft-Muon (alpha=0.95, 0.85, 0.90)   [highest evidence, never ran]
├── Idea 4: Blockwise lr_mult (safest, cheapest)  [low risk diagnostic]
└── Idea 7: Outer sync staggering (novel mechanism, low cost)

Round 2 (conditional on Round 1):
├── If Idea 1 or 2 positive → Idea 6: Joint Contra+Soft stack
├── If Idea 4 positive → sweep finer lr_mult grid
├── Idea 3: RACS preconditioner (higher novelty, higher risk)
└── Idea 5: Dynamic AGC schedule (motivated by PR #689 finding)

Round 3:
└── If Idea 6 matches public #20 performance → investigate SOAP MLP trust gate
    (the remaining component of public #20 we haven't tried)
```

## Research state summary

**Current best explanation for performance gap (ffs=3100 vs public ffs=3030)**:
The 70-step gap with the public leaderboard is most likely explained by the combination of Contra-Muon + Soft-Muon + SOAP MLP trust gate in the public solution. These three techniques have never been tested on our MuLoCo×MuonH-SI baseline. The aux optimizer space is essentially closed (structural pieces load-bearing, VR family exhausted). The remaining actionable search space is: (1) MuonH inner update direction modifications (Contra, Soft), (2) structured preconditioners for aux (RACS), (3) outer loop initialization quality (Idea 7), (4) per-group lr differentiation (Idea 4).

**Stop conditions**:
- Abandon Contra/Soft if both show delta > +0.001 (worse) with n >= 2 seeds
- Abandon RACS if v_t structure is unstable within 500 steps (monitor via gradient norms)
- Abandon Idea 7 if outer velocity evolution is qualitatively unchanged from baseline
- Proceed to SOAP MLP trust gate (full public #20 replication) if Ideas 1+2+6 achieve ffs < 3070
