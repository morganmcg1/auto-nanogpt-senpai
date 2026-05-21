# Research Ideas — 2026-05-21 09:50

## Context

Generated after reviewing ~38 prior hypotheses (H10–H38), the current MuonH-SI+MuLoCo+AuxAdamW stack (baseline val/loss=3.27119, ffs=3100, PR #443), and targeted literature searches on AdEMAMix calibration, gradient centralization, SOAP/Muon preconditioning, μP initialization, and cooldown schedule shape. All hypotheses are compatible with the benchmark contract (fixed architecture, fixed data, one FBP/step, no cherry-picking), implementable in ≤50 LoC, and mechanism-distinct from each other and from closed experiments.

---

## Closed / Ruled-Out Mechanisms (do not repeat)

- Weight averaging (SF-AdamW #531, TRIPLE-NEG): dead
- Gradient-history mask (Cautious #544): NEG
- Gradient-history dual-EMA (AdEMAMix #567): NEG — but calibration failure, not mechanism failure (see H-ADEM below)
- Gradient-history γ-correction (MARS #582): NEG
- Gradient-difference Adan (#646): NEG (closed)
- Phase-gating / path-dependence (#616, #636): FULLY CLOSED
- Outer optimizer axis (#644 MuLoCo): SATURATED/CLOSED
- β1 pruning (#612): NEG
- β2 pruning (#631 H35): NEG (joint aux AdamW closure effect)
- PAdam (#643 H37): in-flight, assign-blocked
- Per-group eps (#670 H39): in-flight, assign-blocked

---

## Hypothesis H-ADEM: AdEMAMix with Horizon-Corrected β3

### What it is
Replace the standard AdamW third-momentum EMA (β3=0.9999) with a horizon-calibrated β3=0.9990 that saturates within the 3325-step training window, plus a linear warmup for both α and β3.

### Why it might help
PR #567 used β3=0.9999, which has a half-life of 6930 steps — more than double the total training duration. At step 3325, m_2 is only ~28% saturated, meaning the slow EMA contributes almost no signal. For a 3325-step run, β3=0.9990 gives half-life ≈ 693 steps, reaching ~99% saturation by step 2300. The mechanism (longer-horizon gradient history combining with short-horizon momentum) is theoretically sound (Pagliardini et al., 2024, NeurIPS 2024). The prior failure was exclusively a calibration error.

### Key papers
- **AdEMAMix** (Pagliardini et al., arxiv:2405.06130, NeurIPS 2024): Third EMA for long-range gradient history; α interpolates m_1 and m_2; β3 should match training horizon. https://arxiv.org/abs/2405.06130
- **AdEMAMix follow-up**: β3 warmup from β3_start=0.9 to β3_final over T_alpha_beta3=T steps prevents early-training instability from cold slow EMA.

### Implementation notes
- Cannot reuse fused PyTorch AdamW (no third momentum slot). Write a custom unfused loop ~25 LoC inside the optimizer1 `step()` closure.
- Only apply AdEMAMix to aux groups (embed, lm_head, scalars). MuonH handles 2D blocks.
- α=5.0 (AdEMAMix default), β1=0.8, β2=0.95, β3=0.9990, eps=1e-10 (inherited from current stack).
- Warmup: T_alpha_beta3 = train_steps (linear ramp β3 from 0.9 → 0.9990, α from 1 → 5 over full training).
- The β3=0.9990 choice can be swept: try 0.9985 (half-life ≈ 462 steps) and 0.9993 (half-life ≈ 990 steps) in follow-up.
- Known gotcha: m_2 must be initialized to the first gradient (warm start), not zero, otherwise the warmup ramp is dominated by cold start noise.

### Suggested experiment design
Minimal change: swap fused AdamW for custom unfused AdamW+3rd-EMA for optimizer1 groups only. Keep all other hyperparameters identical. Screen at 1000 steps to verify loss trajectory is better than baseline aux-only curve before committing to full 3325-step run.

### Causal explanation targeted
Training: the slow EMA is providing near-zero useful signal because it hasn't saturated. Correct calibration should unlock the "averaging over a long history of diverse gradients" mechanism.

### Taste score
- Mechanistic grounding: 4 — precise calibration fix with clear observable (m_2 saturation fraction) and strong external evidence
- Research-state value: 4 — either confirms mechanism (updates toward AdEMAMix being viable) or refutes it cleanly
- Execution value: 3 — ~25 LoC, screenable at 1000 steps before full run

---

## Hypothesis H-GC: Gradient Centralization for 2D Weight Gradients

### What it is
Before the NS5 orthogonalization step in MuonH, subtract the mean of each gradient row (GC: g ← g − mean(g, dim=1, keepdim=True)). This is a pure pre-step gradient transformation requiring ~3 LoC.

### Why it might help
Gradient Centralization (Yong et al., 2020) removes the "mean shift" component of weight gradients, improving loss landscape geometry. For transformer MLPs and attention projections, the gradient mean across the output dimension encodes a global bias signal that can destabilize training. The gradient heterogeneity paper (arxiv:2502.00213v3) shows that sign-based optimizers (like Muon) are less sensitive to cross-layer gradient variation, but GC targets within-matrix mean removal, a complementary effect. H28 was held due to pod breakage, not negative results. This is the lowest-effort untested mechanism in the current hypothesis bank.

### Key papers
- **Gradient Centralization** (Yong et al., ECCV 2020, arxiv:2004.01461): GC as a geometric constraint; improves generalization and convergence; works across optimizers. https://arxiv.org/abs/2004.01461
- **Gradient Heterogeneity** (arxiv:2502.00213v3, 2025): Sign-based methods beat SGD on transformers partly because they handle cross-layer gradient scale variation; GC handles within-matrix mean shift as a complementary effect.

### Implementation notes
- Insertion point: lines 1011–1022, after `dist.all_reduce(p.grad)` and before `opt.step()`.
- Only apply to 2D params (MuonH group). Embed and scalars are handled by AdamW and GC on embed may be harmful.
- Check: `if p.ndim >= 2 and p in muonh_param_set: p.grad.data -= p.grad.data.mean(dim=tuple(range(1, p.grad.ndim)), keepdim=True)` (generalized to arbitrary 2D+ shapes).
- Known gotcha: do not apply GC after NS5 (would undo orthogonalization). Must apply before `muon_update`.
- Verify gradient norm before/after GC stays finite; log `train/grad/global_norm` vs baseline.

### Suggested experiment design
Single flag `--grad_centralization` (bool, default False). Full 3325-step run. If loss at step 1000 is worse than baseline by >0.005, kill early.

### Causal explanation targeted
Training: gradient mean shift in 2D weight gradients creates a redundant direction that consumes update capacity; removing it should improve effective conditioning of NS5 orthogonalization.

### Taste score
- Mechanistic grounding: 3 — plausible mechanism, direct external evidence, previously HELD not NEG
- Research-state value: 3 — result either adds GC to the stack or closes it cleanly
- Execution value: 4 — 3 LoC, ~0 extra compute, screenable instantly

---

## Hypothesis H-MUP: Maximal Update Parameterization (μP) Initialization

### What it is
Replace the current custom ad-hoc initialization with μP-derived initialization scaling: attention and MLP weights scale as 1/fan_in^0.5 (standard), but the output projections (attn.proj, mlp.proj) scale as 1/width (depth-scaled) and LR scales as 1/width for 2D hidden weights via an additional per-group multiplier.

### Why it might help
The current initialization is hand-tuned (attn=0.33^0.5/sqrt(fan_in), proj=0.026, mlp=0.031) without principled μP scaling. The μP paper (Yang et al., 2022) shows that at width 768, incorrect parameterization causes feature learning to saturate with scale. For Muon-based optimizers, the μP+Muon scaling paper (arxiv:2512.05620) demonstrates ~1.4× speedup vs AdamW with correct μP scaling. The key insight for this stack: lm_head LR (currently 1/320 ≈ 0.00313) and MuonH LR (0.018) should both scale with 1/width to avoid activation explosion in the steady state.

### Key papers
- **μP** (Yang et al., arxiv:2203.03466, NeurIPS 2022): Principled parameterization for feature learning at any width; HP transfer between scales. https://arxiv.org/abs/2203.03466
- **μP+Muon scaling** (arxiv:2512.05620, 2025): Muon+SOAP+Shampoo achieve ~1.4× speedup vs AdamW with μP + 1/width weight decay; specific μP recipe for Muon. https://arxiv.org/abs/2512.05620

### Implementation notes
- In μP, hidden-to-hidden weights (2D blocks) use `std = 1/fan_in` not `1/fan_in^0.5`; this doubles the std of attn and mlp weights at width 768.
- Output projection (attn.proj, mlp.proj): std = 0.02 / sqrt(depth=12) ≈ 0.00577 — currently 0.026, a 4.5× difference.
- LM head: initialize with same std as embed (1.0), not zero. Currently zero — μP says zero is valid but non-zero with 1/vocab scaling is also defensible.
- MuonH LR should scale: lm_head LR = base_lr / width → 0.018 / 768 × some_const; find const by grid search at step 500.
- Critical: do NOT change the architecture (softcap, RMSNorm locations). Only change `model.init_weights()` and possibly per-group LR multipliers.
- Known gotcha: the current stack's custom init has been tuned by many prior experiments. A full μP swap will likely need LR retuning (screen first at 500 steps).

### Suggested experiment design
Two-phase: (1) Init-only change at current LRs — screen at 500 steps vs baseline. (2) If init-only helps, add per-group LR re-scaling. Full 3325-step run only after phase 1 passes.

### Causal explanation targeted
Training: current init is ad-hoc and may put activations in a suboptimal regime at the start of training; μP provides a principled initialization that enables maximum feature learning for this width/depth.

### Taste score
- Mechanistic grounding: 3 — strong external evidence for μP+Muon, but link to this exact stack is speculative (untested)
- Research-state value: 3 — result either establishes μP as a useful lever or rules it out
- Execution value: 3 — moderate LoC (~20), needs phased screening

---

## Hypothesis H-SOAP: SOAP-lite Kronecker Preconditioning for MuonH

### What it is
Replace the NS5 orthogonalization in `muon_update` with a Shampoo-style Kronecker preconditioner that accumulates L = G G^T and R = G^T G over a sliding window, then preconditions updates as L^{-1/4} G R^{-1/4}. This is the core of SOAP without the Adam-in-eigenbasis framing.

### Why it might help
NS5 orthogonalizes G to the nearest orthogonal matrix — a specific preconditioner that ignores the curvature accumulated over past gradients. SOAP/Shampoo shows that the Kronecker-factored curvature matrix significantly improves convergence, especially in the later stages of training when the gradient distribution has shifted. The COSMOS paper (arxiv:2502.17410) shows SOAP on the leading eigensubspace + Muon on residual — suggesting they are complementary. The SOAP gradient whitening paper (2509.22938) shows SOAP is theoretically equivalent to Shampoo. For a 768×768 matrix, Kronecker factors are 768×768, requiring ~2.4MB per layer — feasible on a single GPU.

### Key papers
- **SOAP** (Vyas et al., arxiv:2409.11321, ICLR 2025): Adam in Shampoo's eigenbasis; ~40% fewer iterations vs AdamW on LLMs. https://arxiv.org/abs/2409.11321
- **COSMOS** (arxiv:2502.17410, 2025): SOAP on leading eigensubspace + Muon on residual; memory-efficient; directly relevant. https://arxiv.org/abs/2502.17410
- **Gradient whitening** (arxiv:2509.22938, 2025): SOAP = Shampoo theoretically; Kronecker preconditioning is the key mechanism. https://arxiv.org/abs/2509.22938

### Implementation notes
- Accumulate `L += G @ G.T` and `R += G.T @ G` over `precond_interval` steps (suggest 100 steps).
- Invert via symmetric eigendecomposition: `L^{-1/4}` = `V @ diag(lambda^{-1/4}) @ V.T` (use `torch.linalg.eigh`).
- This is ~45 LoC in the MuonH class. Store L, R as buffers (no extra memory for BF16 768×768 = 1.2MB/layer, ~14 layers = ~17MB).
- Update interval: recompute L^{-1/4}, R^{-1/4} every 50–100 steps (expensive eigendecomp, amortize).
- Known gotcha: eigendecomp on 768×768 in float32 takes ~5ms; at 50-step interval adds <0.01% overhead.
- Alternative: skip full Kronecker, only use L^{-1/2} G (left-preconditioning only) — 20 LoC, lower risk.
- The current NS5 scale factor `max(1, m/n)^0.5` should be removed when using Kronecker.

### Suggested experiment design
Start with left-preconditioning only (L^{-1/2} G, precond_interval=100). Screen at 1000 steps. If promising, add right factor (full Kronecker). Do not swap NS5 entirely until screening confirms viability.

### Causal explanation targeted
Training: NS5 orthogonalizes to the nearest orthogonal matrix but ignores the accumulated gradient covariance; Kronecker preconditioning should better align updates with the local loss curvature.

### Taste score
- Mechanistic grounding: 3 — strong external evidence (SOAP, COSMOS), but direct integration with NS5-based MuonH is novel
- Research-state value: 4 — result would establish whether preconditioning beyond orthogonalization is viable in this stack
- Execution value: 2 — 45 LoC, eigendecomp complexity; phased approach (left-only first) mitigates risk

---

## Hypothesis H-CAT: Catapult LR Burst at Step ~500

### What it is
After the warmup phase (~800 steps), insert a single brief LR burst (1.5–2× peak LR) for ~50 steps before returning to the normal WSD schedule. This is inspired by the "catapult phase" observation in sharp minima literature.

### Why it might help
The catapult phase (Lewkowycz et al., 2020; Damian et al., 2022) describes a brief period of high-LR training where the model jumps to a wider, lower-loss basin. For LLMs, this is typically the early-training period where the LR is high relative to the sharpness. A controlled burst after the model is sufficiently trained but before the main plateau may push the model over local barriers. The key difference from just using a higher peak LR is that the burst is time-limited and then the model returns to the stable schedule. This was listed as H30 and has not been tested yet.

### Key papers
- **Catapult phase** (Lewkowycz et al., 2020, arxiv:2003.02218): High-LR burst in early training navigates to better basins; effect depends on timing relative to sharpness threshold. https://arxiv.org/abs/2003.02218
- **Edge of stability** (Cohen et al., ICLR 2021): GD at 2/sharpness performs well; brief overshooting can be beneficial.

### Implementation notes
- Add CLI args: `--catapult_start_step` (default 500), `--catapult_duration` (default 50), `--catapult_multiplier` (default 1.5).
- In the LR schedule function (lines 851–879): multiply LR by `catapult_multiplier` when `catapult_start <= step < catapult_start + catapult_duration`.
- Apply to MuonH only first (not aux AdamW), since MuonH dominates 2D weights.
- Screen: check train/loss curve — if the burst causes a spike that doesn't recover within 100 steps, the multiplier is too high.
- Sensitivity: try multiplier ∈ {1.3, 1.5, 2.0} and start_step ∈ {300, 500, 800}.

### Suggested experiment design
Minimal: catapult_start=500, duration=50, multiplier=1.5, MuonH only. Single screening run at 1500 steps to check loss recovery. Full run at 3325 steps if loss recovers cleanly.

### Causal explanation targeted
Training: the optimizer may be stuck in a relatively sharp basin after warmup; a brief LR burst navigates to a wider basin with lower final loss.

### Taste score
- Mechanistic grounding: 2 — mechanism is plausible, but catapult timing in this specific WSD+MuonH schedule is speculative
- Research-state value: 3 — cheap test that either closes the idea or opens a schedule-burst direction
- Execution value: 3 — ~5 LoC, screenable at 1500 steps

---

## Hypothesis H-VTR: Selective v_t Reset for LM Head at Cooldown Entry

### What it is
When the LR schedule transitions from main training to cooldown (step ~2700 for a 3325-step run), reset the Adam v_t (second moment) for the lm_head parameter group only, then let it re-accumulate from current gradients during cooldown. The embed and scalars keep their accumulated v_t.

### Why it might help
The lm_head (vocab projection) has a very different gradient distribution from internal weights. By end of main training, v_t for lm_head is a running average of squared gradients from the entire training trajectory — including early, large-gradient phases. This inflated v_t reduces the effective step size during cooldown precisely when large updates on the lm_head might be most beneficial (the loss surface has shifted toward the final objective). PR #512 tested a broader v_t reset strategy; this targets only lm_head and only at cooldown entry.

### Key papers
- **Amsgrad / moment reset** (Reddi et al., ICLR 2018): Shows that old second moments can cause v_t to dominate and prevent convergence; partial reset strategies are an active area.
- **Sophia** (Liu et al., 2023, arxiv:2305.14342): Hutchinson diagonal Hessian estimate for v_t; conceptually related to resetting to fresh curvature information. https://arxiv.org/abs/2305.14342

### Implementation notes
- Add `--lm_head_vt_reset_step` (default -1, disabled; set to ~int(0.8 * train_steps)).
- In training loop at `train_step == lm_head_vt_reset_step`: `optimizer1.state[model.proj.weight]['exp_avg_sq'].zero_()`.
- Also reset `exp_avg` (m_t) for lm_head? Try both variants: v_t only vs (m_t + v_t).
- Known gotcha: `optimizer1` group [1] is lm_head (model.proj.weight, lr=1/320). Check that `state` key is correct after fused AdamW — fused may use different state layout. May need to temporarily disable fused=True for this group or reset via manual grad step.
- Verify: log `train/weight_param/proj.weight_rms` before and after reset; expect a bump then smooth continuation.

### Suggested experiment design
Single screening run with reset at step 2700 (≈0.81 * 3325), v_t only for lm_head. Compare val/loss curve in cooldown vs baseline.

### Causal explanation targeted
Training: stale large v_t for lm_head suppresses effective LR during cooldown; selective reset restores adaptive step size when it matters most.

### Taste score
- Mechanistic grounding: 2 — mechanism plausible, but specificity to lm_head at cooldown is speculative; implementation has fused-AdamW gotcha
- Research-state value: 3 — result either rules out moment-reset on this stack or opens a targeted variant
- Execution value: 3 — ~10 LoC, negligible compute cost

---

## Hypothesis H-RMS: Per-Layer RMS-Normalized Gradient Clipping

### What it is
Before each optimizer step, clip gradients per-parameter by their own RMS rather than by global norm: `g ← g / max(1, rms(g) / clip_rms)` where `rms(g) = sqrt(mean(g^2))` and `clip_rms` is a threshold (e.g., 0.1).

### Why it might help
Global gradient clipping (the current default via `train/grad/global_norm` diagnostics) is dominated by layers with large gradient norms. Per-layer RMS clipping equalizes the update magnitude contribution from each layer, preventing any single layer from driving the overall clipping behavior. This is distinct from AGC (which clips per-parameter relative to the weight norm). For a stack with large gradient heterogeneity across embed/lm_head vs internal blocks, per-layer RMS clipping may improve stability in the early warmup and cooldown phases.

### Key papers
- **Gradient clipping survey** (Zhang et al., 2020, arxiv:2009.03106): Comparison of clipping strategies; per-layer can outperform global in heterogeneous settings. https://arxiv.org/abs/2009.03106
- **Gradient heterogeneity in transformers** (arxiv:2502.00213v3, 2025): Documents large cross-layer gradient variation in transformer training; motivates per-layer normalization strategies.

### Implementation notes
- Add `--per_layer_clip_rms` (default -1, disabled; try 0.05, 0.1, 0.2).
- Insert at lines 1011–1022 after all_reduce: `rms = p.grad.norm() / p.grad.numel()**0.5; if rms > clip_rms: p.grad.data.mul_(clip_rms / rms)`.
- Apply to both MuonH and aux groups, or MuonH only first.
- Check `train/grad/global_norm` before and after to quantify effect. If global norm is already small (baseline shows well-conditioned gradients), this may be a no-op.
- Known gotcha: this can interfere with AGC if AGC is also enabled. Check whether AGC is active (`clip_ratio=0.05` is set in MuonH). If so, the two may conflict; disable one for the test.

### Suggested experiment design
Screen with clip_rms=0.1, MuonH group only. Run 1000 steps. Check if `train/grad/global_norm` changes and if training loss is smoother or faster.

### Causal explanation targeted
Training: dominant-layer gradient norm drives global clipping and suppresses other layers; per-layer normalization equalizes update contributions and improves optimization trajectory.

### Taste score
- Mechanistic grounding: 2 — plausible mechanism, but baseline gradient norms may already be well-behaved
- Research-state value: 2 — result is informative but not decisive for the primary metric
- Execution value: 3 — ~5 LoC, very cheap to screen

---

## Ranked Summary

| Rank | Hypothesis | Mechanism | Est. LoC | Priority |
|------|-----------|-----------|----------|----------|
| 1 | H-ADEM: AdEMAMix β3-calibrated | Long-range gradient history with correct saturation | ~25 | HIGH — prior failure was calibration only |
| 2 | H-GC: Gradient Centralization | Remove gradient mean shift before NS5 | ~3 | HIGH — lowest risk, untested (HELD) |
| 3 | H-MUP: μP Initialization | Principled init + LR scaling for feature learning | ~20 | MEDIUM — needs phased screening |
| 4 | H-SOAP: SOAP-lite Kronecker | Curvature-informed preconditioning beyond orthogonalization | ~45 | MEDIUM — strong external evidence, higher complexity |
| 5 | H-CAT: Catapult LR burst | Brief post-warmup burst to escape sharp basins | ~5 | MEDIUM — H30 pending, mechanism uncertain |
| 6 | H-VTR: Selective v_t reset | Fresh second moment for lm_head at cooldown | ~10 | LOW-MEDIUM — fused-AdamW gotcha |
| 7 | H-RMS: Per-layer RMS clipping | Equalize per-layer gradient scale | ~5 | LOW — may be no-op if gradients already conditioned |

---

## Research State Notes

**Current bottleneck assessment**: The MuonH-SI+MuLoCo+AuxAdamW stack is well-characterized. The remaining gains likely come from (a) better gradient pre-conditioning for the NS5 step (H-SOAP, H-GC), (b) auxiliary optimizer improvements that leverage longer training history (H-ADEM), or (c) improved initialization that sets up a better loss landscape trajectory (H-MUP).

**Calibration debt**: AdEMAMix (H-ADEM) is the highest-confidence opportunity because the prior failure mechanism is precisely identified and the fix is clear. This should be the first assignment when a student becomes available.

**Gradient Centralization (H-GC)** should accompany any assignment as the lowest-risk add-on (3 LoC, zero compute cost).

**μP (H-MUP)** is the most architecturally distinct intervention and should be approached in two phases to avoid wasted full runs.

**SOAP-lite (H-SOAP)** is the highest-upside but highest-complexity option; defer until H-GC and H-ADEM are settled.
