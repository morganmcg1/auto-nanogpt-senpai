# Wave-2 Research Ideas — 2026-05-15

Generated after wave-1 screening signal (PRs #43–50). Record #20 baseline: 3030 steps, n=30 (Soft-Muon + Contra-Muon interpolation + SOAP-MLP + SOAP-attn trust gate).

---

## Category A: Stack Known Strong Recipes (exploit)

### A1: NorMuon + SOAP-MLP + Soft-Muon interpolation (full #20 stack minus attn gate)

**Mechanism:** Record #20 combines four independently validated gains: SOAP-MLP (rec #14/#16), Contra/Soft-Muon interpolation (rec #20), NorMuon row/col preconditioning (rec #8), and SOAP-attn trust gate (rec #16). Wave-1 PR #43 is running NorMuonH which includes the hyperball + per-module init. The hypothesis here is to stack the rec #20 Soft-Muon interpolation technique on top of the confirmed NorMuon base (rec #8), without the SOAP components, to isolate the contribution of Soft-Muon interpolation on the stronger NorMuon base vs. the Contra-Muon base used in rec #20.

**Expected gain:** If NorMuon's row/col variance preconditioning and Soft-Muon interpolation are orthogonal improvements, stacking gives ~3030 - ~20 = sub-3010 steps.

**Discriminating signal:** Single-seed ffs vs. rec #20's 3030. If ffs > 3100 this stacking is not additive; if ffs < 3030 proceed to n=8 confirmation.

**Step budget:** smoke=300, screen=3050 (1 seed), confirm=3050 (n=8).

---

### A2: KL-SOAP-H + Soft-Muon interpolation (rec #19 base + rec #20 technique)

**Mechanism:** Record #19 (KL-SOAP-H, 3125 steps, n=6) uses KL-divergence covariance updates with precondition_frequency=1 and the hyperball constraint. Record #20 adds Soft-Muon interpolation on top of a SOAP base. Stacking Soft-Muon interpolation onto the KL-SOAP-H base tests whether the interpolation technique is architecture-agnostic across different second-order preconditioners.

**Expected gain:** KL-SOAP-H at 3125 is 95 steps behind rec #20. If Soft-Muon interpolation contributes ~95–100 steps independently of the preconditioner, this stack reaches ~3030 or better.

**Discriminating signal:** Does Soft-Muon interpolation give the same gain on KL-SOAP as on SOAP? If yes, the interpolation is a robust modular add-on. If no, it's specific to SOAP's eigenbasis rotation.

**Step budget:** smoke=300, screen=3100 (1 seed), confirm=3050 (n=6).

---

### A3: PMuon + Soft-Muon interpolation (rec #18 base + rec #20 technique)

**Mechanism:** PMuon (rec #18, 3225 steps, n=9) uses bilateral streaming covariance power preconditioning before NS. The gap from rec #18 to rec #20 is 195 steps. Test whether the Soft-Muon interpolation from rec #20 closes this gap when applied to PMuon's bilateral preconditioner.

**Expected gain:** If Soft-Muon interpolation is ~100 steps and PMuon preconditioning is orthogonal, target is ~3125. If they interact poorly, could be worse than rec #18.

**Discriminating signal:** Does ffs drop below 3125? If yes, the mechanisms are complementary. If ffs is between 3125–3225, partial overlap. If worse than 3225, negative interaction.

**Step budget:** screen=3250 (1 seed), confirm=3150 (n=6).

---

### A4: Aurora optimizer on rec #20 base (rec #17 base → rec #20 base)

**Mechanism:** Record #17 (Aurora, 3175 steps, n=20) was built on rec #11 base (Contra-Muon, 3225 steps). Record #20 is a stronger base at 3030 steps. Aurora's technique (Tilde Research's aurora-release optimizer) showed a ~50-step gain over its base (3225 → 3175). If the same gain applies to the stronger rec #20 base, target would be ~2980 steps.

**Key implementation note:** Aurora was stacked on rec #11 base. When porting to rec #20 base, verify there is no double-application of the Contra-Muon / Soft-Muon interpolation (rec #17 already includes rec #11's Contra-Muon; rec #20 has a different formulation).

**Discriminating signal:** Does Aurora's technique give an additional gain on top of rec #20? If ffs < 3030 the techniques compound. If ffs ≈ 3030–3080, Aurora's gain is already captured by the rec #20 stack. If ffs > 3080, there is a negative interaction.

**Step budget:** smoke=300, screen=3050 (1 seed), confirm=3000 (n=8).

---

### A5: MuLoCo outer-loop on rec #20 base (rec #13 base → rec #20 base)

**Mechanism:** MuLoCo (rec #13, 3210 steps, n=10) wraps an outer Nesterov SGD step (K=1, outer_lr=0.7, outer_momentum=0.5, sync_interval=30) around the NorMuonH inner optimizer. Applied to rec #20's base, this tests whether the outer-loop momentum averaging technique is orthogonal to Soft-Muon interpolation and SOAP preconditioning.

**Key caution:** MuLoCo's outer step modifies parameter trajectories independently of the inner preconditioner. With SOAP's eigenbasis rotation, the outer-loop correction may fight the preconditioner's curvature adaptation. Consider reducing outer_lr to 0.4–0.5 when stacking on SOAP-heavy bases.

**Discriminating signal:** ffs vs. rec #20 (3030). Also compare to MuLoCo on rec #11 base (3210 vs 3225 base → ~15 step gain). If gain is similar proportionally, the mechanism is base-agnostic.

**Step budget:** screen=3050 (1 seed), confirm=3000 (n=6).

---

## Category B: Fresh Optimizer Mechanisms Not Yet Tried (explore)

### B1: Cautious-Muon — sign-agreement masking on the NS update

**Mechanism:** "Cautious" masking (Liang et al., ICLR 2026): zero-out any component of the optimizer update where the update and current gradient disagree in sign. Applied after Newton-Schulz orthogonalization: `u_ns = NS(m_t); mask = (u_ns * g_t > 0).float(); p -= lr * u_ns * mask / (mask.mean() + 1e-8)`. The intuition is that the NS update is clipped to only act where the raw gradient and the preconditioned direction agree — preventing the orthogonalized momentum from overshooting when the loss surface has recently curved.

**Why it might help here:** Muon's NS step can push parameters in directions orthogonal to the current gradient, creating oscillations near saddle points or sharp minima. Cautious masking preserves the beneficial curvature adaptation of NS while preventing disagreement-direction updates. Given rec #20's plateau at 3030 steps (n=30), oscillation control near the end of training is plausible as a bottleneck.

**Implementation (inline, ~10 lines):**
```python
def cautious_ns_update(u_ns, g):
    # u_ns: Newton-Schulz direction, g: current gradient (same shape)
    mask = (u_ns * g > 0).to(u_ns.dtype)
    normalizer = mask.mean().clamp(min=1e-8)
    return u_ns * mask / normalizer
```
Apply this in the Muon update step after NS, replacing the direct `p.add_(u_ns, alpha=-lr)`.

**Key hyperparameters:** No new HP beyond clamp epsilon (1e-8 default). May interact with lr: cautious masking effectively reduces update magnitude by `mask.mean()` ≈ 0.4–0.6 empirically. Consider lr multiplier of 1.5–2.0x when enabling.

**Falsifying result:** If single-seed ffs is worse than rec #20 (3030) at the same lr, try lr * 1.5. If still worse at 1.5x lr, cautious masking has negative interaction with NS orthogonalization.

**Step budget:** smoke=300, screen=3050 (1 seed, lr sweep: 1.0x and 1.5x base), confirm=3000 (n=6).

---

### B2: AdamS in-place of AdamW for auxiliary (embed/head) groups

**Mechanism:** AdamS (Liang et al.): replace the second-moment denominator `sqrt(v_t) + eps` with `RMS(β₁ * m_{t-1} + (1-β₁) * g_t) + eps` — i.e., the denominator is the RMS of the current weighted momentum rather than an exponential moving average of squared gradients. This eliminates the `v` buffer (saves memory) and avoids Adam's warm-up instability from near-zero `v_0`. Validated on GPT-2/Llama2 in the paper; shown to match or beat AdamW with fewer HPs.

**Why it matters here:** The embedding and lm_head groups (currently AdamW) account for a disproportionate fraction of parameter updates during early training. AdamS's warm-up-free denominator could improve the first 20% of steps where AdamW's `v` buffer is cold.

**Implementation (inline, replaces AdamW group update):**
```python
# AdamS update: denominator = RMS(current EMA gradient) 
m_t = beta1 * m_prev + (1 - beta1) * g
denom = m_t.norm() / (m_t.numel() ** 0.5) + eps  # scalar RMS
p.addcdiv_(m_t, denom.expand_as(m_t), value=-lr)
```
Note: The per-element version uses `(m_t * m_t).mean().sqrt()` as denominator. The paper's formulation is per-element: `denom_i = sqrt(sum_j m_{t,j}^2 / n) + eps` applied uniformly, equivalent to `m_t / (m_t.norm() / sqrt(n) + eps)`.

**Key HP:** beta1=0.9 (same as AdamW default), eps=1e-8 or 1e-6. Weight decay treatment: same as AdamW decoupled.

**Discriminating signal:** Compare val/loss at step 500 and step 1000 between AdamS-aux and AdamW-aux variants on the same Muon base. If AdamS shows lower early loss, the warm-up effect is real. If final ffs is the same, AdamS is memory-neutral neutral.

**Step budget:** screen=3050 (1 seed), compare AdamS-only-aux vs full AdamW-aux vs baseline.

---

### B3: Shampoo-style right-preconditioning for QKV projections only

**Mechanism:** The QKV projection is currently under-preconditioned: SOAP-MLP preconditioning (rec #14) and SOAP-attn trust gate (rec #16) help attention, but QKV's gradient structure (rows are query/key/value heads) has a different geometric structure than the value projection. Apply a Shampoo-style right-preconditioner only to the QKV weight matrix: maintain `G_R = β * G_R + (1-β) * W^T W` (right factor, d_model × d_model) and update via `W -= lr * G^{-1/4} @ G_R^{-1/4}` (using NS approximation of the inverse root). This targets the inter-head correlation structure that standard Muon's NS step does not explicitly model.

**Why QKV specifically:** The attention QKV projection maps from d_model to 3*n_heads*d_head. The row structure (per-head groups) has strong covariance within heads but near-independence between heads. A right preconditioner on the d_model dimension whitens the input feature correlations shared across Q, K, V heads simultaneously.

**Implementation note:** Use the existing NS iteration as the matrix inverse root approximation for the right factor, with a separate refresh every 64 steps (same as Newton-Muon's activation covariance refresh schedule). The right factor accumulation should use β=0.95, consistent with Muon²'s β₂.

**Discriminating signal:** Does grad/rms for attn.qkv drop faster than for attn.proj and mlp.* groups? If yes, the per-group preconditioning is taking effect. If no discriminative gradient behavior, the mechanism is not engaging.

**Step budget:** screen=3050 (1 seed), monitor grad_type/attn_qkv vs attn_proj vs mlp_* in W&B.

---

### B4: Decoupled per-module learning rate via μP-style width scaling

**Mechanism:** μP (Maximal Update Parametrization) assigns per-layer learning rate multipliers proportional to `1/fan_in` for hidden weight matrices and `1/sqrt(fan_in)` for attention logits, so that all layers reach their optimum simultaneously as width scales. Even at fixed width, applying the μP multipliers to the current rec #20 base may improve the balance between layers. The hypothesis: the current single-lr-for-all-Muon-groups assignment is sub-optimal; attn.proj and mlp.fc layers have different fan_in and may need different relative lr.

**Implementation:** Compute multipliers `c_l = d_model / fan_in_l` for each Muon parameter group, then scale group lr as `lr_l = base_lr * c_l / mean(c)`. For the current 768d model: qkv fan_in=768, proj fan_in=768, mlp.fc fan_in=768, mlp.proj fan_in=3072. The mlp.proj group would get lr * 4 relative to qkv/proj groups.

**Key caution:** μP multipliers at fixed width may interact poorly with the hyperball constraint, which already bounds ‖w‖_F per module. If per-module norms are already equalized by the hyperball, μP multipliers may be redundant. Run a diagnostic: compare per-module ‖w‖_F and ‖g‖_F across groups in a baseline run first (use W&B weight_type/* metrics).

**Discriminating signal:** Compare final ffs and per-module loss-slope timing (does the mlp.proj layer converge faster with higher lr?). If no layer-timing improvement, μP multipliers are not the bottleneck.

**Step budget:** 300-step diagnostic (log per-module weight/grad norms), then screen=3050 (1 seed) if the diagnostic shows layer imbalance.

---

### B5: Spectral norm constraint instead of hyperball (Frobenius → spectral)

**Mechanism:** Record #9 (u/w-floor) and rec #20 (hyperball) both constrain parameter norms, but use Frobenius norm. The spectral norm (largest singular value) is more directly related to the network's Lipschitz constant and the stability of gradient flow through layers. Replacing the Frobenius-based hyperball with a spectral norm constraint: `if σ_max(W) > C: W *= C / σ_max(W)` (clip the largest singular value to C). This directly prevents exploding singular values without affecting the distribution of smaller singular values.

**Why now:** Davis & Drusvyatskiy (arXiv:2512.04299) show that layerwise spectral updates beat Euclidean when the nuclear-to-Frobenius ratio is low and the stable rank of activations is moderate. The condition is likely met for attn.proj and mlp.proj (tall rectangular matrices with low stable rank under language modeling). The spectral constraint specifically targets the direction that spectral gradient theory predicts matters most.

**Implementation:** Use a power-iteration step (1–3 iterations) to estimate σ_max efficiently at each step. The constraint replaces the full `hyperball_constraint` function. Computational overhead: ~2% (one power iter per weight matrix per step).

**Key HPs:** C (spectral norm ceiling) — start with C = sqrt(d_model) ≈ 27.7 for the 768d model. This is the expected σ_max for a random Gaussian matrix of the same shape.

**Falsifying result:** If spectral-constrained runs show worse or equal val/loss slope compared to Frobenius hyperball at equal steps, the Frobenius constraint is sufficient and spectral theory's stronger prediction does not hold in this setting.

**Step budget:** 300-step diagnostic (log σ_max per layer via W&B), screen=3050 (1 seed) if σ_max is actually being clipped.

---

### B6: Gradient centralization + Muon (remove mean before NS)

**Mechanism:** Gradient Centralization (Yong et al., 2020) removes the mean of each gradient tensor along the output dimension before the optimizer update: `g_c = g - g.mean(dim=0, keepdim=True)`. Applied before the Muon momentum accumulation: `m_t = β * m_{t-1} + (1-β) * (g - g.mean(dim=0))`, then NS on m_t. The mean-removal projects gradients onto the hyperplane of zero-sum outputs, which has regularization and loss-landscape smoothing effects related to weight normalization.

**Why it connects to Muon:** The NS orthogonalization in Muon already removes isotropic scaling; gradient centralization removes the isotropic shift (mean). The two operations are complementary in the sense that NS whitens the variance structure while GC centers the mean structure. Together they may clean the gradient tensor more thoroughly before the update.

**Implementation (~3 lines):**
```python
# In Muon update, before momentum accumulation:
if g.ndim >= 2:
    g = g - g.mean(dim=tuple(range(1, g.ndim)), keepdim=True)
m = beta * m + (1 - beta) * g
# ... rest of NS update unchanged
```

**Key HP:** No new HPs. GC is parameter-free. May interact with weight decay: if GC already centers the update, AdamW-style weight decay may be less necessary for the Muon groups. Consider testing wd=0 for Muon groups with GC.

**Step budget:** screen=3050 (1 seed), ablation: GC-on vs GC-off at same base rec #20.

---

### B7: Nesterov lookahead momentum (k=1, α=0.5) inside the NS step

**Mechanism:** Instead of applying Nesterov correction at the outer SGD level (as MuLoCo does), apply it inside the Muon step: use the Nesterov extrapolated point `θ̃ = θ - β * lr * u_prev` to compute the gradient for the current step, then apply the NS-orthogonalized update. This is Nesterov's classical trick applied specifically to the NS momentum direction rather than the raw gradient.

**Distinction from PR #49 (Lookahead):** PR #49 tested Zhang et al.'s Lookahead (slow weights k=5, α=0.5) as an outer wrapper — a different mechanism. Inner Nesterov on the momentum direction (before NS) is a different level of intervention: it changes what gradient the NS step sees, rather than averaging parameter snapshots.

**Implementation:**
```python
# Nesterov look-ahead: compute gradient at extrapolated point
with torch.no_grad():
    for p in group['params']:
        p.data.add_(buf[p], alpha=-beta * lr)  # extrapolate
# Forward-backward at extrapolated point (within same step)
# ... THIS VIOLATES the one-fwd-bwd-per-step rule. DO NOT USE.
```

**Important:** Full Nesterov requires a gradient at the lookahead point, which would be a second forward-backward pass. This violates the benchmark contract. Instead, use the **approximation**: `g_nesterov ≈ g_t + β * (g_t - g_{t-1})` (momentum correction using previous gradient). This gives Nesterov-style extrapolation with one grad per step.

**Revised implementation:**
```python
g_corrected = g_t + beta * (g_t - g_prev)  # approximate Nesterov
m_t = beta * m_prev + (1 - beta) * g_corrected
u_ns = newton_schulz(m_t / m_t.norm())
```
Requires storing `g_prev` per parameter (same memory as one extra momentum buffer).

**Step budget:** screen=3050 (1 seed). Diagnostic: compare momentum buffer alignment (cos similarity of m_t and g_t) between standard Muon and Nesterov-corrected Muon.

---

### B8: Schedule-free inner loop on Muon (Defazio et al., 2024)

**Mechanism:** Defazio et al.'s Schedule-Free wrapper eliminates the lr schedule entirely: instead of a cosine/warmup schedule, maintain two parameter vectors `x` (averaging point) and `z` (gradient step point), updating `z -= lr * g; x = (1 - c) * x + c * z` where c is a weight that grows over training. The key property: the method is provably equivalent to an exponentially-scheduled run without needing to know the horizon T in advance.

**Why this is relevant to the step-count speedrun:** The current benchmark is step-count limited. Schedule-free optimization may find a better loss/step trade-off than hand-tuned cosine+cooldown because it implicitly adapts its effective lr to the curvature without a fixed schedule. The rec #20 cooldown design (`h_cooldown_frac=1.0, aux_cooldown_frac=0.4`) is already a complex schedule; eliminating it would reduce HPs and may expose a cleaner signal.

**Key implementation detail:** Schedule-free requires using `x` (the average) for evaluation and `z` for gradient computation. The existing `model.eval()` call must be preceded by `optimizer.eval()` to swap to x-weights for val loss logging. Missing this step causes val/loss to appear worse than training/loss in a systematic way that is not a real gap.

**Known failure mode:** Schedule-free is sensitive to the initial lr. Start with 3x the current base lr (as recommended in the paper for AdamW; may differ for Muon). Also, the method assumes constant lr; the existing warmup logic must be removed or replaced with a linear interpolation of c from 0.

**Step budget:** screen=3050 (1 seed, lr sweep: 1x, 2x, 3x base), confirm=3000 (n=6 if screen beats 3050).

---

## Category C: Pruning Ablations of Complex Stacks (diagnose)

### C1: Remove SOAP-attn trust gate from rec #20 (SOAP-MLP only)

**Mechanism:** Record #16 (3125 steps) added a trust gate to SOAP-attn: the attn SOAP preconditioner is only applied when the update norm exceeds a threshold. Record #20 (3030 steps) inherits this. The trust gate adds code complexity and a HP. The question: does the attn trust gate contribute meaningfully, or is SOAP-MLP alone sufficient?

**Expected behavior:** If SOAP-MLP (rec #14, 3150 steps) and SOAP-attn with trust gate (rec #16, 3125 steps) are roughly additive, their combination might be rec #20's position. If removing the attn trust gate from rec #20 gives ffs ≈ 3080–3100, the trust gate is worth ~50–70 steps. If ffs is still ≈ 3030, the trust gate contributes nothing and should be pruned.

**Discriminating signal:** ffs vs. rec #20 (3030) on a 3050-step screen. If removal costs >30 steps, the gate is load-bearing. If removal costs <15 steps (within noise), prune it to simplify the stack.

**Step budget:** screen=3050 (1 seed), compare to baseline rec #20.

---

### C2: Remove hyperball constraint from rec #20 (Frobenius weight bounding disabled)

**Mechanism:** The hyperball constraint (rec #9 foundation, extended in rec #20) clamps the Frobenius norm of hidden weight matrices. It was introduced as a stability measure and has been inherited through multiple generations of records. The question: is it still load-bearing in the rec #20 stack, or does the combination of SOAP preconditioning + Soft-Muon interpolation already provide sufficient implicit regularization?

**Expected behavior:** If removing hyperball from rec #20 causes training instability (exploding weight norms, val/loss spike), the constraint is still necessary. If ffs is similar (±30 steps) with weight norms remaining bounded, SOAP + Soft-Muon provides equivalent implicit regularization.

**Diagnostic:** Monitor `train/weight/all/attn_proj_rms` and `train/weight/all/mlp_proj_rms` in W&B. If these remain stable without hyperball, the constraint is redundant.

**Step budget:** 300-step diagnostic (watch weight norms), abort if ‖w‖_F > 3x baseline after 200 steps. If stable, screen=3050 (1 seed).

---

## Summary Table

| ID | Category | Mechanism | Expected ffs | Risk | Priority |
|----|----------|-----------|-------------|------|----------|
| A1 | Exploit  | NorMuon + Soft-Muon interpolation | ~3010 | Low | High |
| A2 | Exploit  | KL-SOAP-H + Soft-Muon interpolation | ~3030 | Med | High |
| A3 | Exploit  | PMuon + Soft-Muon interpolation | ~3125 | Med | Med |
| A4 | Exploit  | Aurora on rec #20 base | ~2980 | Med-High | High |
| A5 | Exploit  | MuLoCo on rec #20 base | ~3000 | Med | Med |
| B1 | Explore  | Cautious-Muon (sign-agreement mask) | ~3000 | Med | High |
| B2 | Explore  | AdamS for aux groups | ~3020 | Low | Med |
| B3 | Explore  | QKV-only right-preconditioning | ~3000 | Med | Med |
| B4 | Explore  | μP per-layer lr scaling | ~3010 | Low | Med |
| B5 | Explore  | Spectral norm constraint | ~3010 | Med | Low |
| B6 | Explore  | Gradient centralization + Muon | ~3020 | Low | Med |
| B7 | Explore  | Nesterov-corrected gradient in Muon | ~3020 | Med | Low |
| B8 | Explore  | Schedule-free Muon (Defazio 2024) | ~2990 | High | Med |
| C1 | Prune    | Remove SOAP-attn trust gate | diagnostic | Low | Med |
| C2 | Prune    | Remove hyperball constraint | diagnostic | Low | High |

Total: 15 ideas.

---

## Top 3 Dispatches if All 8 Students Were Idle

1. **A4 (Aurora on rec #20 base)**: Aurora showed ~50-step gain on rec #11 base (n=20, high evidence). Applied to rec #20 base could reach sub-3000. Highest expected absolute gain. Concrete implementation path (port rec #17 Aurora technique to rec #20 setup). Mechanistic grounding: 4/4. Research value: 4/4.

2. **B1 (Cautious-Muon)**: Inline 10-line implementation. Strong external evidence (ICLR 2026 paper, matches Muon's known overshoot failure mode near convergence). Falsifiable with single-seed screen. Mechanistic grounding: 3/4 (solid theory, no domain validation yet).

3. **A1 (NorMuon + Soft-Muon interpolation)**: Tests whether Soft-Muon interpolation (rec #20's key innovation) is separable from the SOAP preconditioning underneath it. Low implementation risk, high discriminating value. If additive → sub-3010 on simpler stack; if not additive → reveals SOAP is load-bearing for the interpolation effect.

---

## Implementation Notes for Wave-2 Students

- All experiments target rec #20 base (3030 steps, n=30) as comparison point.
- Standard smoke run: 300 steps, verify finite gradients, finite val/loss, W&B logging.
- Standard screen: predeclared step count (3050 or 3100 depending on idea risk), 1 seed. No early stopping.
- Standard confirm: predeclared step count, n=6 or n=8 seeds. Report all seeds non-cherry-picked.
- Statsig rule for n=6: need mean < 3.28 - 0.004/sqrt(6) = 3.2784. For n=8: mean < 3.2786.
- Use `--wandb_group "wave2-<hypothesis-slug>"` to group related runs.
- All optimizer code must be inline in train_gpt_simple.py — no third-party optimizer packages.
- torch version: confirm torch>=2.11 to avoid model.compile NaN bug (torch==2.10 had NaN at step 2).
