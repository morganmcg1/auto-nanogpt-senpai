# Wave-3 Research Hypotheses (H-BG onward)
# Generated: 2026-06-07 14:00 UTC

## Context

Rank-1 baseline: PR #2317 (nezuko H-W), mean val/loss = 3.276193, n=4, step=2890.
Stack: NC (per-row × per-col L2 equalization before NS5) + Sinkhorn-Arbor (mlp.fc/proj) + EMA-Nesterov (γ=0.99, PREFILL=300, REST=2300 pending H-AW) + RI (capture=2375, γ=−0.075).

Statistical contract: `(3.28 − μ) × √n ≥ 0.004`. Noise floor ≈ 0.0005.

**Decision gates (all hypotheses):**
- T0 STRONG (n=2 mean ≤ 3.275793) → immediate merge
- T1 PROMISING (n=2 mean ≤ 3.276193) → merge, beats rank-1
- T2 INCONCLUSIVE (3.276193 < mean ≤ 3.276593) → n=4 seed confirm directed
- T3 FALSIFIED (n=2 mean > 3.276593) → close

**H-BD (Partial SAM) DISQUALIFIED.** SAM requires two forward-backward passes per optimizer step. The benchmark contract explicitly forbids this. H-BD must not be assigned to any student.

**In-flight wave-2 (do not duplicate):** H-BA (Sophia-G, tanjiro), H-BC (spectral norm PI, fern), H-BE (EN scope, queued), H-BF (SNR-LR, queued), H-AT GC n=4 (askeladd), H-AW REST=2300 n=4 (edward).

---

## Priority 1 — Implementation-Ready (Full Spec)

---

### H-BG: PMuon + LR-Pulse + Beta2-Pulse from PR #1532/#1614 Lineage Composed with NC×Arbor×EN×RI Stack

**Category:** optimizer composition / known-good stack integration
**Expected impact:** HIGH — PR #1532/#1614 achieved 3.279022 (n=32) on a weaker base; composing its unique levers with the NC×Arbor×EN×RI stack is the single highest-leverage untried composition.
**Risk:** MEDIUM — PMuon interacts with NC (per-row/col normalization before NS5); beta2-pulse timing may need recalibration.

**Mechanism:** PR #1532/#1614 combined three levers not in current rank-1 stack: (a) PMuon (projected momentum: normalize momentum direction independently from magnitude), (b) auxiliary AdamW beta2-pulse (briefly drop beta2 to reset variance memory at tail), (c) per-group LR pulse on Muon. The rank-1 stack gained ~0.0028 from EN and ~0.0002 from RI — those are outer wrappers. The PR #1532/#1614 levers operate inside the Muon step itself and should be orthogonal.

**Key mechanism question:** Does PMuon (projected-momentum normalization before NS5) conflict with or complement NC (per-row/col L2 equalization after NS5)? If they are orthogonal, composition should win.

**Code change location:** `train_gpt_simple.py`, `Muon.step()` lines 984-986 (momentum accumulation), and the `muon_update` function at lines ~880-928. Also the AdamW optimizer1 configuration at lines 1268-1271 (beta2-pulse needs a schedule).

**Arm A (PMuon only):**
- In `Muon.step()`, before calling `muon_update()`, add projected momentum: normalize `state["momentum"]` to unit Frobenius norm, then scale by its norm × `group["mu"]`. This is PMuon: direction from projection, magnitude from raw EMA.
```python
# After line 985 (momentum lerp), before line 986 (momentum_update):
mom_norm = state["momentum"].float().norm().clamp_min(1e-8)
mom_dir = state["momentum"] / mom_norm
momentum_update = grad.lerp(mom_dir * mom_norm, group["mu"])
```
- No beta2-pulse, no LR-pulse. Isolate PMuon contribution first.
- Arm A smoke: `python train_gpt_simple.py --num_trials=2 --seed_offset=0 --train_steps=2890`

**Arm B (PMuon + beta2-pulse at step 2500):**
- Add PMuon as in Arm A.
- Add beta2-pulse to AdamW optimizer1: drop `betas[1]` from 0.99 to 0.90 for steps 2500-2650, then restore to 0.99. This resets variance memory so the tail LR adjustment is less stale.
```python
# In set_hparams(step):
beta2 = 0.90 if 2500 <= step < 2650 else 0.99
for group in optimizer1.param_groups:
    group["betas"] = (group["betas"][0], beta2)
```
- Arm B tests whether the beta2 reset compounds with PMuon under the NC×Arbor×EN×RI stack.

**Smoke command:**
```bash
cd /workspace/senpai/target/records/track_3_optimization
torchrun --nproc-per-node=8 train_gpt_simple.py \
  --num_trials=2 --seed_offset=0 --train_steps=2890 \
  --wandb_project=senpai --wandb_group=h-bg-pmuon-pulse \
  --ri_gamma=-0.075 --ri_capture_step=2375
```

**Decision gate:**
- After Arm A (n=2): if ≤ 3.276193, merge + run Arm B for confirmation. If > 3.276193 but < 3.276593, run Arm B before deciding.
- After Arm B (n=2): apply 4-tier gate above.
- If both arms T3 → close (PMuon conflicts with NC under this stack).

---

### H-BH: Gradient Centralization on Muon Momentum (Not Raw Grad) — Mechanism Isolation for H-AT

**Category:** diagnostic / mechanism isolation
**Expected impact:** MEDIUM-HIGH — H-AT (GC on raw grad) is PROMISING / n=4 confirm running. GC on momentum is a distinct operation: removes group-mean from the accumulated EMA, not from individual micro-batch gradients. This is cleaner for matrix weights (the mean-subtraction acts on rows/columns of the 2D matrix, not the scalar gradient).
**Risk:** LOW — trivial code change, orthogonal to H-AT.

**Mechanism:** GC as applied in H-AT centers the raw gradient `g` before the EMA: `g -= g.mean(dim=tuple(range(1, g.dim())), keepdim=True)`. Applying the same operation to the momentum buffer instead (post-EMA) is a different operation: it re-centers the accumulated direction. For Muon params (matrix weights), the effective gradient direction entering NS5 is determined by the post-EMA momentum. Centering the momentum before NS5 removes the mean-shift that accumulates in the EMA across training, which may improve the NS5 convergence quality (NS5 assumes centered inputs).

This is also an important diagnostic: if H-AT with GC-on-grad succeeds and H-BH with GC-on-momentum also succeeds, we learn that centering the direction entering NS5 is the key mechanism, not the micro-batch noise reduction effect.

**Code change location:** `Muon.step()` lines 984-986. After the momentum lerp (line 985), apply centering to `state["momentum"]` in-place before forming `momentum_update`.

**Arm A (GC on momentum, ndim≥2 only):**
```python
# After line 985 (state["momentum"].lerp_(grad, 1 - group["mu"])):
if state["momentum"].dim() >= 2:
    mom_mean = state["momentum"].float().mean(dim=tuple(range(1, state["momentum"].dim())), keepdim=True)
    state["momentum"].add_(-mom_mean.to(state["momentum"].dtype))
momentum_update = grad.lerp(state["momentum"], group["mu"])
```

**Arm B (GC on momentum_update — after blend, before NS5):**
Same centering applied to `momentum_update` after the `grad.lerp(state["momentum"], group["mu"])` blend, so it enters `muon_update` centered.

**Smoke command:**
```bash
cd /workspace/senpai/target/records/track_3_optimization
torchrun --nproc-per-node=8 train_gpt_simple.py \
  --num_trials=2 --seed_offset=0 --train_steps=2890 \
  --wandb_project=senpai --wandb_group=h-bh-gc-momentum \
  --ri_gamma=-0.075 --ri_capture_step=2375
```

**Decision gate:**
- H-AT n=4 confirm result (askeladd, ~14:00 UTC) comes first — read it before launching H-BH.
- If H-AT is FALSIFIED → launch H-BH Arm A immediately to check if momentum-centering works where grad-centering did not.
- If H-AT MERGES → launch H-BH to test composition (GC-grad + GC-momentum might over-center).
- 4-tier gate on n=2, direct n=4 if T2.

---

### H-BI: Depth-Wise LR Scaling on Muon — Scale Per-Layer LR by Layer Index

**Category:** architecture / optimizer geometry
**Expected impact:** MEDIUM — deep LMs exhibit gradient norm variation across layers (deeper layers often have smaller effective gradients post-normalization). The current stack applies uniform MUON_LR=0.0375 to all blocks. Depth-wise scaling lets early layers train faster and late layers more conservatively (or vice versa), which may align with the FineWeb loss landscape.
**Risk:** MEDIUM — adds 12 per-group LR values; interaction with the power-law schedule and EMA-Nesterov lookahead may require retuning.

**Mechanism:** Standard per-layer LR in vision models (DeiT, ViT fine-tuning) applies a depth multiplier: `lr_layer = base_lr * decay^(depth - layer_index)`. For a 12-layer transformer, the top layer gets `base_lr` and the bottom gets `base_lr * decay^11`. Applied to Muon (which handles all `model.blocks` params), this means splitting `optimizer2.param_groups` into 12 groups, one per block, each with its own `initial_lr`.

**Code change location:** Lines 1272-1273 (optimizer2 construction). Instead of one `Muon([(n,p) for n,p in model.blocks.named_parameters() if p.ndim>=2], lr=MUON_LR, ...)`, create per-block param groups with scaled LRs. The `_power_lr` schedule uses `group["initial_lr"]`, so depth scaling is preserved through training.

**Arm A (decay=0.85, top layer = MUON_LR, deeper layers scaled down):**
```python
# Replace lines 1272-1274:
DEPTH_LR_DECAY = 0.85
num_blocks = len(list(model.blocks))
block_params = []
for block_idx, block in enumerate(model.blocks):
    block_lr = MUON_LR * (DEPTH_LR_DECAY ** (num_blocks - 1 - block_idx))
    block_named = [(f"{block_idx}.{n}", p) for n, p in block.named_parameters() if p.ndim >= 2]
    block_params.append(dict(named_params=block_named, lr=block_lr))
# Then construct Muon with these groups (requires Muon.__init__ to accept multi-group init)
```
Note: Muon currently takes `named_params` as a flat list. The simplest implementation passes all params to a single Muon but overrides `group["lr"]` per block after construction. Alternatively, split into 12 separate Muon instances (more invasive). Student should use post-construction `param_groups` override if Muon's internals permit it.

**Arm B (decay=0.90, inverted — deeper layers get HIGHER LR):**
Inverted scaling tests the opposite hypothesis: deeper layers have more compressed gradients post-normalization and benefit from a higher effective update.

**Smoke command:**
```bash
cd /workspace/senpai/target/records/track_3_optimization
torchrun --nproc-per-node=8 train_gpt_simple.py \
  --num_trials=2 --seed_offset=0 --train_steps=2890 \
  --wandb_project=senpai --wandb_group=h-bi-depth-lr \
  --ri_gamma=-0.075 --ri_capture_step=2375
```

**Decision gate:** 4-tier standard gate on n=2. If T2 for either arm, run n=4. If both T3 → close (uniform LR is already calibrated).

**Implementation note:** The current Muon `__init__` constructs a flat list and a single param group. The simplest implementation is to post-hoc override group LR in `set_hparams()` after construction. Student must verify that `power_c` assignment at lines 1292-1295 still works correctly when there are 12 groups (currently assigns to `optimizer2.param_groups[0]`; must broadcast to all groups).

---

### H-BJ: NS Iteration Count Sweep (NS8 vs NS16) Coupled to LR Rescaling

**Category:** optimizer inner loop / spectrum orthogonalization quality
**Expected impact:** MEDIUM — current codebase uses NS12 (12-step Newton-Schulz). The NS convergence quality (how close to true polar factor) directly determines the effective preconditioner for Muon. NS8 is faster but leaves ≈4% spectral error; NS16 reaches <0.1%. The key question: does the extra NS quality at NS16 matter given that NC (per-row/col equalization) and Arbor (Sinkhorn) already post-correct the update, or does NS8 suffice and free budget for other mechanisms?
**Risk:** LOW-MEDIUM — NS iteration count is a global constant; changing it uniformly affects all Muon params. No third-party dependencies.

**Mechanism:** Newton-Schulz iteration converges quadratically to the polar factor U = V Σ^{1/2} W^T of G=UΣV^T. Each step roughly halves the spectral error. The "shape heuristic" at line 918 `update *= max(1, update.size(-2) / update.size(-1))**0.5` is a fixed scaling to match the expected operator norm. If NS8 under-converges, the heuristic at line 918 compensates imperfectly. If we drop to NS8, we should rescale the LR upward by the expected convergence ratio (≈1.03-1.05x) to maintain the same effective update magnitude.

The coupling of NS steps to LR rescaling is the untested lever: prior ablations just changed NS steps without compensating LR.

**Code change location:** Find the NS polynomial constants (typically a list or named constant). Search for `newtonschulz5` or the NS loop. The NS5 function is referenced at line 910 (`soft_via_newtonschulz5`) and implicit in the main Muon path. The iteration count is likely a constant like `NS_STEPS = 12` or embedded in a function name `newtonschulz12`.

**Arm A (NS8, MUON_LR × 1.04):**
- Reduce NS iteration count from 12 to 8.
- Increase MUON_LR from 0.0375 to 0.039 (≈4% upward rescale).
- Rationale: faster per-step, slightly higher LR to compensate for the ≈4% lower polar approximation quality.

**Arm B (NS16, MUON_LR × 0.97):**
- Increase NS iteration count from 12 to 16.
- Slightly decrease MUON_LR from 0.0375 to 0.0364 to compensate for the slightly larger effective update from near-perfect polar factor.
- Rationale: if NC+Arbor+EN+RI all benefit from cleaner orthogonalization, NS16 quality may propagate to final metric.

**Smoke command:**
```bash
cd /workspace/senpai/target/records/track_3_optimization
torchrun --nproc-per-node=8 train_gpt_simple.py \
  --num_trials=2 --seed_offset=0 --train_steps=2890 \
  --wandb_project=senpai --wandb_group=h-bj-ns-steps \
  --ri_gamma=-0.075 --ri_capture_step=2375
```

**Implementation note:** Locate the NS iteration loop. It may be a function like `newtonschulz12` or use a loop variable. The student must (a) find the constant/loop, (b) change it, (c) adjust the LR accordingly, (d) verify the update magnitude is similar to baseline by checking the `vnorm_new/vnorm` ratio logged in W&B if available.

**Decision gate:** 4-tier standard gate on n=2. Both arms must be evaluated before closing. If Arm A (NS8) wins → insight that NS12→NS8 + LR correction is viable (faster training). If Arm B (NS16) wins → insight that NC+Arbor do NOT fully compensate for NS convergence quality and the polar factor matters.

---

## Priority 2 — Sketch-Level Hypotheses (H-BK onward)

---

### H-BK: Warm-Restart Learning Rate at Step 2000 (Cosine Restart)

**Category:** LR schedule
**Motivation:** The current power-law schedule decreases monotonically from start. A single cosine warm-restart at step ~2000 can temporarily increase the LR and help the optimizer escape late-training flat regions before the final tail. This is a classic trick from SGDR (Loshchilov & Hutter 2017) that has not been composed with the NC×Arbor×EN×RI stack.
**Direction:** Add a single cosine restart: at step 2000, reset LR to `base_lr × 0.5` and cosine-anneal to 0 over 890 steps. The RI capture at step 2375 will then capture parameters in a "re-sharpened" loss basin.
**Expected impact:** MEDIUM — restart disrupts the EN lookahead buffer. Risk: EN accumulates momentum direction; a restart may partially invalidate it. Interaction with RI is interesting: the restart perturbs the tail trajectory and may widen the basin RI explores.
**Tag:** schedule

---

### H-BL: Embed Weight LR Decoupling from Power Schedule

**Category:** per-group LR tuning / mechanistic
**Motivation:** The embed.weight uses `lr=0.3` with `ADAM_EMBED_POWER_C` controlling the power-law decay. The embed is trained by AdamW (optimizer1), not Muon. Its effective LR at step 2890 is determined by `_power_lr(2890, 0.3, ADAM_EMBED_POWER_C)`. Current embed LR has not been individually tuned on top of the NC×Arbor×EN×RI stack — all embed tuning was done on weaker bases.
**Direction:** Arm A: `embed lr = 0.4` (30% increase). Arm B: `embed lr = 0.2` (33% decrease). Keep `lm_head lr = 1/320` fixed. The embed and lm_head are weight-tied or at least co-trained — changing embed LR without lm_head may disentangle their learning dynamics in interesting ways.
**Expected impact:** LOW-MEDIUM — embed is a single param group; its gradient signal is sparse (only the vocabulary tokens present in each batch receive a gradient). The power schedule already attenuates it; under-attenuation or over-attenuation can matter.
**Tag:** hyperparameter / mechanistic

---

### H-BM: Stochastic Weight Averaging (SWA) as Alternative to RI at Tail

**Category:** tail ensemble / averaging
**Motivation:** RI (Reference Interpolation) extrapolates *away* from the tail mean by γ=−0.075. SWA averages uniformly. SWA was foundational (Izmailov et al. 2018) but the extrapolation direction in RI is the novel insight. The question is whether interpolating *toward* the tail mean (γ=+0.05 to +0.20) at a different point in training beats the current negative γ. This is effectively a grid search over RI γ sign but framed as SWA to motivate the direction.
**Direction:** Keep `ri_capture_step=2375`. Arm A: `ri_gamma=+0.05` (interpolate toward tail mean). Arm B: `ri_gamma=+0.15`. Compare to rank-1 `ri_gamma=−0.075`. If positive γ wins, we learn the basin is concave near the tail (SWA-favorable). If negative γ wins as before, the basin is convex or the tail mean is a saddle.
**Expected impact:** LOW — RI γ has been explored but positive γ has not been systematically tested on the NC×Arbor stack. Low risk (single scalar change). May falsify RI's contribution as unique.
**Tag:** tail ensemble

---

### H-BN: AdaGrad-Norm on Muon Momentum (Per-Row Second-Moment for Direction)

**Category:** preconditioned Muon / adaptive learning
**Motivation:** The current second-moment at lines 919-927 applies per-row (or per-col) variance rescaling *after* NS5 to normalize update magnitude. This is a magnitude-only correction. AdaGrad-Norm would apply a *direction*-aware second moment to the momentum buffer *before* NS5, biasing which directions get amplified. Specifically: maintain a per-row AdaGrad accumulator for `momentum_update`; scale rows of `momentum_update` by inverse sqrt of their accumulated squared norm. This is distinct from SOAP (which is a full Kronecker preconditioner) and from the current second-moment (which applies after NS5).
**Direction:** Add a `per_row_adagrad` state initialized to zeros. Before calling `muon_update`, compute `row_norm_sq = (momentum_update**2).mean(dim=-1, keepdim=True)` and accumulate `adagrad_acc.lerp_(row_norm_sq, 0.01)`. Scale `momentum_update /= (adagrad_acc.sqrt() + 1e-8)`. The `muon_update` then sees a pre-conditioned direction.
**Expected impact:** MEDIUM — this is a distinct mechanism from all current levers. Risk: may interfere with the NC (per-row/col equalization) that happens after NS5.
**Tag:** preconditioner / Muon

---

### H-BO: Scheduled Momentum Warmdown (μ Ramp) Starting Earlier

**Category:** momentum schedule
**Motivation:** Current code has `_MU_WARMUP_STEPS` and `_MU_COOLDOWN_STEPS` for Muon momentum (μ) ramp-up and ramp-down. The cooldown schedule may be too late or too abrupt given the EN lookahead operating on top. An earlier μ cooldown (starting at step 2400 instead of ~2700) would make the Muon gradient direction less "sticky" near the tail, potentially letting RI and EN have a cleaner final trajectory to extrapolate from.
**Direction:** Reduce `_MU_COOLDOWN_STEPS` from its current value (check the constant) to start at step 2400. Arm A: cooldown start=2400. Arm B: cooldown start=2200. The μ at cooldown end should still reach `_MU_MIN`.
**Expected impact:** LOW-MEDIUM — momentum schedule has been partially explored but not in the context of the RI capture at 2375 and EN REST at 2300. An earlier μ cooldown might make the RI snapshot cleaner.
**Tag:** schedule / momentum

---

### H-BP: Muon Update Clipping by Frobenius Norm Percentile

**Category:** gradient stability / robustness
**Motivation:** The current `gram_frobenius_norm_estimate` normalizes all updates to the same target norm. But outlier parameters (e.g., the first MLP layer, which has a different init scale due to `_DI_FC_ALPHA` depth scaling) may receive disproportionately large updates relative to their weight norms. Per-param update clipping (clip the Frobenius norm of the update to `max_update_norm = clip_ratio × weight_frobenius_norm`) is a robustness mechanism that has not been tested in this stack.
**Direction:** After `scale_radial_update(update, p)` at line 1024, add: `update_norm = update.float().norm(); weight_norm = p.float().norm(); if update_norm > clip_ratio * weight_norm: update = update * (clip_ratio * weight_norm / update_norm)`. Arm A: `clip_ratio=0.05`. Arm B: `clip_ratio=0.02`.
**Expected impact:** LOW — this is a regularization/robustness mechanism. May help on seeds with high-variance trajectories. May be a no-op if the existing `target_radius_after_update` / `rescale_to_radius` already handles this.
**Tag:** robustness / gradient

---

### H-BQ: RI Capture Step Sweep (2250, 2500) vs Baseline 2375

**Category:** tail ensemble / RI ablation
**Motivation:** RI capture at step 2375 was fixed in PR #2295 and has not been re-swept on top of the NC×Arbor base (PR #2317). The optimal capture point may have shifted with EN REST=2300 and the shape heuristic. Earlier capture (step 2250) grabs more of the training trajectory in the tail mean; later capture (step 2500) is closer to the final weights.
**Direction:** Arm A: `--ri_capture_step=2250 --ri_gamma=-0.075`. Arm B: `--ri_capture_step=2500 --ri_gamma=-0.075`. Keep all other hyperparameters identical to rank-1.
**Expected impact:** LOW-MEDIUM — pure scalar ablation but untested on the current stack. This is cheap (no code change, only CLI args) and could improve or confirm the current optimum.
**Tag:** tail ensemble / ablation

---

### H-BR: Orthogonal Initialization for Muon MLP Weights (Instead of Scaled Normal)

**Category:** initialization
**Motivation:** Muon's update at each step approximates the polar factor of the gradient matrix, projecting it toward an orthogonal matrix. Initializing MLP weights (especially `mlp.fc.weight`) to be exactly orthogonal (via `torch.nn.init.orthogonal_`) means the first Muon step is a near-identity correction rather than a large alignment step. This may accelerate early learning and leave the model in a better basin by step 2890.
**Direction:** In the per-trial init block (lines 1240-1256), after the default `module.reset_parameters()`, override `mlp.fc.weight` and `mlp.proj.weight` with orthogonal init, then apply the `_DI_FC_ALPHA` depth scaling on top.
```python
# After reset_parameters() in the trial init loop:
for block in model.blocks:
    nn.init.orthogonal_(block.mlp.fc.weight)
    nn.init.orthogonal_(block.mlp.proj.weight)
# Then re-apply depth scaling as before
```
Arm A: orthogonal init for `mlp.fc` + `mlp.proj`. Arm B: orthogonal init for attention Q, K, V projections as well.
**Expected impact:** MEDIUM-LOW — initialization effects decay over training. Under 2890 steps with a good optimizer the init effect may be small; however, orthogonal init for Muon params has theoretical appeal (starts in the fixed-point manifold).
**Tag:** initialization

---

## Experiment Tree

```
Wave-3 launch
├── H-BG (PMuon+pulse) — highest expected impact
│   ├── T0/T1 → merge, compose with H-BH (GC + PMuon)
│   └── T3 → PMuon conflicts with NC; close; route to H-BH as standalone
├── H-BH (GC on momentum) — depends on H-AT result
│   ├── H-AT MERGES → run H-BH to test composition
│   ├── H-AT FALSIFIED → run H-BH as standalone (different centering point)
│   ├── H-BH T0/T1 → merge + test H-BG×H-BH composition
│   └── H-BH T3 → centering direction into NS5 is not the H-AT mechanism; diagnostic value
├── H-BI (depth-wise LR) — independent
│   ├── T0/T1 → merge, compose with H-BG if both win
│   └── T3 → uniform LR is already well-calibrated; don't revisit
├── H-BJ (NS steps + LR coupling) — independent
│   ├── NS8 wins → pipeline speed improvement; merge
│   ├── NS16 wins → NC+Arbor don't fully compensate polar quality; deepen NS in all arms
│   └── Both T3 → NS12 is already near the optimum for this stack
├── H-BK (warm restart) — launch if ≥2 idle students remain
├── H-BL (embed LR) — cheap, launch anytime
├── H-BM (RI γ positive) — launch after H-AW REST confirm (edward)
├── H-BN (AdaGrad-Norm on momentum) — launch if H-BG falsified (same code region)
├── H-BO (μ cooldown timing) — launch after H-AW REST closes
├── H-BP (update clipping) — low priority
├── H-BQ (RI capture sweep) — cheap, launch anytime alongside H-BM
└── H-BR (orthogonal init) — lowest priority, launch last
```

---

## Taste Rubric

| ID | Mode | Mechanistic grounding | Research-state value | Execution value | Score |
|---|---|---|---|---|---|
| H-BG | Frontier refinement | 4 — targets known-good levers from PR #1532/#1614 not composed with current stack | 4 — win tells us PMuon+pulse compose; loss tells us NC and PMuon conflict | 3 — n=2 initial, staged | **3.7** |
| H-BH | Diagnostic | 4 — isolates centering point (grad vs momentum) as mechanism for H-AT signal | 4 — result either confirms or refutes H-AT mechanism precisely | 4 — trivial code change, high discriminating power | **4.0** |
| H-BI | Frontier refinement | 3 — depth-wise LR has external evidence (DeiT, ViT) but Muon impl complexity moderate | 3 — result either confirms depth heterogeneity matters or rules it out | 2 — implementation non-trivial (Muon param group split) | **2.7** |
| H-BJ | Diagnostic | 3 — NS quality coupled to LR rescaling is the novel framing; prior NS ablations didn't rescale | 4 — either arm win is a useful map update about NC+Arbor compensation | 3 — low risk, targeted | **3.3** |
| H-BK | Frontier refinement | 2 — LR restart has external evidence but interaction with EN buffer is unclear | 2 — result is hard to interpret cleanly (EN buffer corruption confound) | 2 — moderate | **2.0** |
| H-BL | Frontier refinement | 2 — embed LR is scalar knob, mechanism is "better signal flow through embeddings" | 2 — confirms/rules out embed LR as saturated lever | 3 — trivial (single scalar change) | **2.3** |
| H-BM | Diagnostic | 3 — tests RI γ sign hypothesis, well-motivated by SWA literature | 3 — distinguishes concave vs convex basin shape near tail | 4 — CLI-only, no code change | **3.3** |
| H-BN | Frontier refinement | 3 — AdaGrad-Norm on momentum is distinct from all current levers | 3 — result distinguishes whether direction precondition before NS5 matters | 2 — code change in inner Muon loop, interaction with NC | **2.7** |
| H-BO | Frontier refinement | 2 — μ cooldown timing has weak external analogy | 2 — low information even if it wins | 3 — trivial constant change | **2.3** |
| H-BP | Frontier refinement | 2 — update clipping is a robustness regularizer | 2 — hard to interpret: may mask or cure a different problem | 2 — moderate risk of obscuring the benchmark signal | **2.0** |
| H-BQ | Diagnostic | 3 — RI capture sweep is a direct parametric ablation of a core mechanism | 3 — confirms whether 2375 is still optimal on NC×Arbor base | 4 — CLI-only, no code change | **3.3** |
| H-BR | Frontier refinement | 2 — orthogonal init for Muon has theoretical appeal but 2890-step decay is strong | 2 — init effects hard to distinguish from optimizer effects at this step count | 2 — medium implementation complexity | **2.0** |
