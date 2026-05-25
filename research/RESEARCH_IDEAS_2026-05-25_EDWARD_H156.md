# H156 Research Hypothesis: Near-Identity Body Init (α·I_padded + β·Q)

**Date:** 2026-05-25
**Student:** g1r3-edward
**Context:** Post-H148 WIN (val/loss 3.26364, new baseline; Δ=−0.00183 vs 3.26547)

---

## Candidate Ranking

Five candidates evaluated in priority order:

### 1. Near-Identity (α·I_padded + β·Q, F-norm matched) — SELECTED

**Mechanism:** Initialize each body 2D weight as a convex combination of a padded identity matrix and a random orthogonal basis, then hard-rescale to exactly match the F-norm of the default init.

**Why this is interesting:** H148's arm_b win had sv_med=0.7188 at step 1 (not 1.0). The F-norm preservation was the necessary condition; the orthogonal basis was sufficient. Near-identity tests whether adding an explicit identity-alignment component — which has sv=1.0 by construction — produces a better-conditioned initial landscape for MuonH. The identity matrix I_pad is in the null space of "random orthogonal" in expectation, so the cross-term α⟨I_pad, Q⟩ ≈ 0, and F-norm budget decomposes cleanly:

    ||α·I_pad + β·Q||_F² ≈ α²·k + β²·k
    ⟹ β = sqrt(max(target_fnorm² − α²·k, 0) / k)

Final hard-rescale guarantees exact F-norm match regardless of approximation error.

**Mechanistic claim:** Identity alignment raises the sv distribution floor from ~0.57 (H148 arm_b) toward 1.0, giving MuonH a better-conditioned starting surface. The optimizer then spends fewer early steps "unwinding" near-zero singular modes.

**Literature anchor:** "Conditioned Initialization for Attention" (Saratchandran & Lucey, ICLR 2026, OpenReview cKNOCYPo2W) reports spectral structure at init improves early convergence for Q,K,V. Identity-alignment is a natural spectral prior that reduces condition number. "Two failure modes of deep transformers" (ICLR 2026) identifies rank collapse at init as a distinct failure mode; near-identity directly addresses rank collapse by preventing near-zero sv components.

**Orthogonality to closed PRs:**
- H125: mu-end variation (optimizer schedule, not init)
- H128: init under cosine schedule (LR schedule timing, not weight structure)
- H135: embed init (token embedding, not body 2D weights)
- H140: LWLRD asymmetric damping (per-layer LR, not init structure)
- H148: pure orthogonal basis (no identity component — this extends the direction class)
- H150 in-flight: LM head init (AdamW aux group, not MuonH body)

**LoC estimate:** ~40 lines in train_gpt_simple.py

---

### 2. Identity-Plus-Noise (α·I_padded + β·ε, F-norm matched)

Same residual-stream hypothesis but with unstructured Gaussian noise instead of an orthogonal complement. Simpler but less principled: the noise component has no guarantee of spanning the complement of I_pad, so SVs may be more chaotic. Useful as an ablation arm to isolate "does orthogonal complement matter, or is any complement fine?"

**Decision:** Use as arm_c variant rather than a separate hypothesis.

---

### 3. Orthogonal Embed Init

H148 covered MuonH body (attn.q/k/v/proj, mlp.fc/proj). Embed uses AdamW, not MuonH — the hyperball geometry argument does not apply directly. "Learning to Recall Beyond Orthogonal Embeddings" (ICLR 2026) shows orthogonal embed is an idealized capacity case. However H135 may have partially covered this; without confirmed H135 scope, this risks a duplicate test.

**Decision:** Defer pending H135 scope confirmation.

---

### 4. Init-Gain Sweep (gain ∈ {0.5, 0.75, 1.5}, F-norm matched)

Scalar multiplier on the orthogonal init gain. This is pure hyperparameter hill-climbing on a single scalar. program.md explicitly warns against letting research collapse into "only learning-rate and weight-decay hill-climbing." The same warning applies to init-gain sweeps that do not change the structural class.

**Decision:** Low priority; skip unless near-identity shows a gain effect worth isolating.

---

### 5. Cleaned H140 Asymmetric Damp

H140 was bilaterally closed (NULL/NEG). Re-running without a new mechanism or bug-fix evidence is a dead end.

**Decision:** Eliminated.

---

## Selected Hypothesis: H156 — Near-Identity Body Init

### 3-Arm Chain Design

Total wall-clock estimate on 1×H100 at 3325 steps: ~5.5h (1.65h/arm, consistent with H148 timing).

**arm_a CTRL:** Default random init, identical to H148 arm_a and current baseline. Establishes within-run anchor.

    --body_init default

**arm_b NEAR_IDENTITY_ALPHA_0.3:** Moderate identity component. At α=0.3 with k=min(m,n) body dims, identity contributes α²·k to F-norm budget, leaving β ≈ 0.954·σ for the orthogonal component (rough estimate; exact β computed per-layer).

    --body_init near_identity_fnorm_matched --body_init_identity_alpha 0.3

**arm_c NEAR_IDENTITY_ALPHA_0.5:** Stronger identity component. α=0.5 means identity carries 25% of F-norm budget (α²k / target_fnorm²), orthogonal complement carries remaining 75%.

    --body_init near_identity_fnorm_matched --body_init_identity_alpha 0.5

**Alpha selection rationale:** α=0.3 and α=0.5 bracket the "interesting" regime. Below α=0.2, the identity component is negligible and result converges to pure orthogonal (H148 arm_b). Above α=0.7, the orthogonal complement becomes too small to maintain spectral diversity across the weight matrix (k remaining sv slots split ~50/50). F-norm constraint ensures neither arm violates the MuonH hyperball radius.

---

### Implementation Anchor

```python
def near_identity_fnorm_matched(w: torch.Tensor, alpha: float = 0.3) -> None:
    """w = alpha*I_pad + beta*Q, then hard-rescale to ||w||_F = target_fnorm."""
    import math
    m, n = w.shape
    target_fnorm = w.data.norm('fro').item()  # preserve from existing (default) init
    k = min(m, n)
    device, dtype = w.device, w.dtype

    # Padded identity
    I_pad = torch.zeros(m, n, device=device, dtype=dtype)
    I_pad[:k, :k] = torch.eye(k, device=device, dtype=dtype)

    # Random orthogonal basis (full m×n matrix with orthonormal columns/rows)
    Q = torch.empty(m, n, device=device, dtype=dtype)
    torch.nn.init.orthogonal_(Q, gain=1.0)

    # F-norm budget: ||alpha*I_pad + beta*Q||_F^2 ≈ alpha^2*k + beta^2*k (cross-term ~0)
    id_contrib = (alpha ** 2) * k
    beta = math.sqrt(max(target_fnorm ** 2 - id_contrib, 0.0) / k) if id_contrib < target_fnorm ** 2 else 0.0

    w.data.copy_(alpha * I_pad + beta * Q)

    # Hard-rescale to exactly match target F-norm (absorbs cross-term error)
    actual = w.data.norm('fro').item()
    if actual > 0.0:
        w.data.mul_(target_fnorm / actual)
```

CLI args to add:
- `--body_init` choices: add `near_identity_fnorm_matched` to existing `['default', 'orthogonal_fnorm_matched', 'orthogonal_bottom_damp']`
- `--body_init_identity_alpha` (float, default=0.3)

Dispatch: in the body init loop (alongside existing H148 `orthogonal_fnorm_matched` branch), add:

```python
elif args.body_init == 'near_identity_fnorm_matched':
    near_identity_fnorm_matched(w, alpha=args.body_init_identity_alpha)
```

**Critical detail:** `target_fnorm = w.data.norm('fro').item()` must be called BEFORE any modification to `w`. The default init (`w.normal_()`) runs before this branch — confirm ordering in train_gpt_simple.py's `__init__` block.

---

### Expected Telemetry

**If hypothesis is correct (identity alignment helps):**
- sv_med at step 1 should be higher than H148 arm_b's 0.7188 (pulled toward 1.0 by identity component)
- sv_min should be higher (fewer near-zero singular modes)
- train/loss slope in first 500 steps should be steeper (better-conditioned starting surface)
- Final val/loss: arm_b or arm_c below 3.26284 (WIN threshold vs new baseline 3.26364)

**If hypothesis is incorrect:**
- sv_med at step 1 close to H148 arm_b (identity component has no lasting effect after NS5 quintic reshapes SVs in first ~100 steps)
- val/loss similar to CTRL or slightly above H148 arm_b win (NULL)
- Worst case: alpha too high → F-norm mismatch degrades hyperball geometry → NEG

**Falsifying result:** If arm_b and arm_c both show sv_med at step 1 ≈ arm_b H148 sv_med (0.7188), the identity component is being overwhelmed by the orthogonal basis, and alpha is not the lever. If val/loss is above CTRL for both arms, the extra identity structure hurts rather than helps — possibly because it introduces directional bias that MuonH must overcome.

---

## Research State Update

**Current best explanation for why H148 won:** F-norm preservation at initialization ensures the MuonH hyperball radius is calibrated correctly from step 0. The orthogonal direction basis provides a better-distributed starting SV spectrum (sv_med=0.7188) than default random init, reducing early optimization curvature mismatch. The NS5 quintic attractor will reshape SVs toward 1.0 regardless; the init advantage is in the early gradient signal before the attractor dominates.

**What H156 tests:** Whether adding an explicit identity alignment (sv=1.0 component in the init direction) accelerates early convergence further, or whether the orthogonal basis alone (H148) is already near-optimal for F-norm-matched body init.

**Open uncertainties:**
1. At what alpha does the identity component dominate the spectral distribution at step 1, and does that help or hurt?
2. Does the NS5 attractor erase any init-condition advantage within the first 200 steps, making all structured inits converge to the same trajectory?
3. Is the H148 win reproducible as arm_a CTRL in this run (necessary for within-run comparison validity)?

**Stop condition:** If both arm_b and arm_c are NULL (within ±0.0008 of baseline 3.26364) and sv_med at step 1 is not materially different from H148 arm_b, conclude that near-identity does not extend the H148 win and close the identity-component direction entirely.

---

## Full Reproduce Command Template

```bash
# arm_a CTRL
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r3-edward/H156-near-identity-ctrl" \
  --wandb_group "H156-near-identity-body-init" \
  --num_trials 1 --train_steps 3325 \
  --body_init default \
  --muonh_mode scale_invariant --muonh_cooldown_shape linear \
  --muonh_warmup_steps 100 --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 --aux_beta2_schedule constant \
  --aux_beta2_start 0.99 --muonh_mu_schedule linear \
  --muonh_mu_start 0.95 --muonh_mu_end 0.90

# arm_b NEAR_IDENTITY_ALPHA_0.3
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r3-edward/H156-near-identity-alpha03" \
  --wandb_group "H156-near-identity-body-init" \
  --num_trials 1 --train_steps 3325 \
  --body_init near_identity_fnorm_matched --body_init_identity_alpha 0.3 \
  [... same optimizer flags as arm_a ...]

# arm_c NEAR_IDENTITY_ALPHA_0.5
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r3-edward/H156-near-identity-alpha05" \
  --wandb_group "H156-near-identity-body-init" \
  --num_trials 1 --train_steps 3325 \
  --body_init near_identity_fnorm_matched --body_init_identity_alpha 0.5 \
  [... same optimizer flags as arm_a ...]
```

Base hyperparameters inherited from H148 arm_b (the winning configuration). DO NOT retune optimizer hyperparameters in this PR — the only change is the init structure.
