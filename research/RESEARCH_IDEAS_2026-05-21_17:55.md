# Research Ideas — 2026-05-21 17:55

Generated after reviewing all experiment history through cycle 71 mid-45.
Current baseline: val=3.26776, ffs=3000 (n=2, PR #613).

---

## Context: What Has Been Ruled Out

Before proposing new ideas, the following axes have been closed or are currently in-flight and must not be duplicated:

**Closed / ruled-out mechanisms (all stack versions):**
- AdamW eps sweep (various values) — closed flat
- Cautious AdamW — flat or regressed
- Schedule-free AdamW — diverged
- Z-loss (auxiliary logit penalty) — flat
- Per-block learning rate (differential LR per transformer block) — flat
- Gradient noise injection — flat + NaN instability
- Muon per-layer trust threshold sweeps (multiple variants) — flat
- Bimodal ffs variance reduction (9/9 closures): intrinsic data/loss geometry, not optimizer-addressable
- CONTRA_MUON sweep (confirmed best=0.4, Arm A=0.2 near-miss at ffs=3025)
- MUON_LR confirmed best=0.04
- MU_COOLDOWN_START/END confirmed best=0.95/0.90 (narrow win over 0.97/0.93)
- WD_AUX = 0.001 confirmed (re-run in-flight #701)
- LOGIT_SOFTCAP = 20.0 confirmed win (PR #613 merged)
- EMBED_INIT_STD = 0.1 confirmed win (PR #541 merged)
- NS5_ITERS = 14 confirmed (PR #677 closed, default=5 loses badly)
- ATTN_SOAP trust threshold sweep — in-flight #683

**Currently in-flight (do not duplicate):**
- #694 NS5_COEFS (Polar Express vs conservative vs default)
- #688 MUON_GRAD_CLIP
- #683 ATTN_SOAP_TRUST re-sweep
- #701 WD_AUX RE-RUN (n=2 confirmation)
- #702 MU_WARMUP_START sweep
- #675 SCALARS_LR sweep
- #703 MUON_NESTEROV
- #704 BLOCK_INIT_MULT (just assigned)

---

## Top New Ideas

### 1. BLOCK_INIT_MULT (ASSIGNED — PR #704)

Fan-in std multiplier on QKV and MLP fc block weights. Analogous to EMBED_INIT_STD=0.1 win. Two arms: 0.5x (shrink) and 2.0x (expand). Never tested on any stack version. Lowest-cost (~2 LoC), highest-analogy mechanism available.

---

### 2. AdEMAMix on the AdamW Group

**What it is:** Replace the AdamW update for the scalar/embed/lm_head group with AdEMAMix — a dual-EMA optimizer that maintains both a fast EMA (β1~0.9) and a very slow EMA (β3~0.9999) of gradients, then mixes them with a learned weight α. The slow EMA acts as a long-horizon memory that corrects for the recency bias in standard momentum.

**Why it might help:** The AdamW group includes lm_head and embed, which are updated less frequently in effective gradient terms because Muon handles all attention/MLP weights. These parameters may benefit from longer-horizon gradient memory. The PR #515 pattern tested something similar but on a different stack; this is the first time it would run on the c=20 mandatory stack with LOGIT_SOFTCAP and the confirmed WD_AUX/NS5_ITERS settings.

**Key reference:** "AdEMAMix Optimizer: Better, Faster, Older" (Pagliardini et al., 2024) — https://arxiv.org/abs/2409.03137. Core finding: slow EMA allows using larger effective batch sizes without instability; particularly effective for embed/output parameters.

**Implementation sketch (~15 LoC):**
```python
ADEMAMIX_ALPHA = float(os.environ.get("ADEMAMIX_ALPHA", "5.0"))
ADEMAMIX_BETA3 = float(os.environ.get("ADEMAMIX_BETA3", "0.9999"))
# In optimizer step for AdamW group:
# m1 = beta1 * m1 + (1-beta1) * g   # fast EMA (standard)
# m2 = beta3 * m2 + (1-beta3) * g   # slow EMA (new)
# update = (m1 + alpha * m2) / (sqrt(v) + eps)
```

**Suggested sweep:** ADEMAMIX_ALPHA ∈ {3.0, 5.0, 8.0}, ADEMAMIX_BETA3=0.9999. One arm at ALPHA=5.0 (paper default) first; screen at 1500 steps before committing to full run.

**Taste:** Mechanistic grounding 3/4, Research-state value 3/4, Execution value 2/4. Strong external evidence; moderate cost.

---

### 3. Muon Momentum Bias Correction

**What it is:** Adam-style `1/(1-β^t)` cold-start debiasing for Muon's zero-initialized momentum buffer. Standard Adam debiases both m and v estimates at step t. Muon's nesterov momentum accumulates from zero; at early steps the effective momentum is a biased low-amplitude estimate of the true gradient direction. Bias correction would amplify the early updates to match the expected magnitude.

**Why it might help:** The near-miss cluster (4 axes at ffs=3025) suggests the warmup phase is a bottleneck — the model is not learning fast enough in the first ~500 steps to pull ffs from 3025 to 3000. Bias-corrected early momentum would give stronger early updates during the MU_WARMUP_START ramp-up phase, potentially tightening the loss trajectory in exactly the steps that determine whether ffs=3000 or ffs=3025. This is the Schmidhuber-style "trace it back to Adam-1992" approach applied to a modern orthogonalised optimizer.

**Implementation (~3 LoC):**
```python
MU_BIAS_CORRECT = int(os.environ.get("MU_BIAS_CORRECT", "0"))
# In Muon update, after momentum accumulate:
# if MU_BIAS_CORRECT:
#     m_hat = momentum_buffer / (1 - beta_muon ** step)
#     update = NS5(m_hat)
# else:
#     update = NS5(momentum_buffer)  # current behavior
```

**Taste:** Mechanistic grounding 4/4 (precise cold-start bias story tied to early-training ffs bottleneck), Research-state value 3/4, Execution value 4/4 (3 LoC, cheap, falsifiable at step 500).

---

### 4. NS5 Spectral Normalization Variant: Normalize Before vs. After

**What it is:** In the current NS5 iteration, the gradient matrix G is iteratively orthogonalised and the result is applied as the update. An alternative is to normalise the gradient **before** entering NS5 (pre-norm variant) rather than relying on NS5 to handle scale. This decouples "direction finding" (NS5) from "scale correction" (AdamW-style denominator), potentially giving cleaner orthogonal directions at each step.

**Why it might help:** The NS5_ITERS=14 win (vs default 5) suggests the current iteration count is not fully converging — more iters helps. Pre-normalising the input to NS5 might accelerate convergence of the Newton-Schulz iteration itself (better-conditioned input matrix), allowing the same quality of orthogonalisation with fewer iters, or better quality at the current 14 iters.

**Implementation:** Scale G by 1/G.norm() before the NS5 loop; ensure the output is re-scaled appropriately. Env var: `NS5_PRENORM=1`.

**Taste:** Mechanistic grounding 3/4, Research-state value 3/4, Execution value 3/4.

---

### 5. Decoupled Muon LR for Attention vs MLP Blocks

**What it is:** Use separate `MUON_LR_ATTN` and `MUON_LR_MLP` instead of a single `MUON_LR=0.04`, split at the parameter level. Motivated by the fact that attention and MLP blocks have structurally different gradient spectra: attention weights operate on Q/K/V projections with tied dimensions, while MLP fc weights have 4x fan-out.

**Why it might help:** The per-block LR experiment (PR #268) failed on an older stack. However, that was a per-layer depth-based schedule, not a per-block-type split. A type-based split is a much simpler, lower-variance hypothesis: if the optimal MUON_LR differs for attention vs MLP by even 10-20%, a single combined LR is sub-optimal for both simultaneously.

**Suggested sweep:** MUON_LR_ATTN ∈ {0.03, 0.04, 0.05}, MUON_LR_MLP ∈ {0.03, 0.04, 0.05}, holding ATTN=0.04/MLP=0.05 as Arm A and ATTN=0.03/MLP=0.04 as Arm B.

**Important caveat:** Per-block LR was closed as flat on an older stack. This is a different axis (type-based not depth-based) but must explicitly distinguish itself from PR #268 in the PR body.

**Taste:** Mechanistic grounding 2/4, Research-state value 2/4, Execution value 3/4. Moderate prior evidence; likely useful as a secondary screen after more novel ideas.

---

### 6. SOAP for MLP Blocks (Extend ATTN_SOAP to MLP)

**What it is:** Currently ATTN_SOAP applies the SOAP preconditioner (Shampoo-style Kronecker-factored second-order preconditioner) only to attention blocks. Extending it to MLP blocks would apply the same second-order curvature information to the larger 4x-wide MLP matrices.

**Why it might help:** If ATTN_SOAP is winning (trust threshold sweep in-flight #683), the mechanism — more accurate preconditioning for large parameter matrices — should apply equally to MLP fc weights which are structurally similar (large rectangular weight matrices updated by Muon). The question is whether the per-step compute overhead is justified.

**Implementation:** Add `MLP_SOAP=1` env var; include `blocks.N.mlp.fc.weight` in the SOAP parameter group. The compute overhead per step should be profiled on a 5-step debug run before committing.

**Taste:** Mechanistic grounding 3/4, Research-state value 3/4, Execution value 2/4. Depends on #683 result — run only if ATTN_SOAP trust threshold experiment shows clear win.

---

### 7. Warmup-Free Muon with Higher Initial LR

**What it is:** Rather than ramping Muon LR from MU_WARMUP_START×0.04 to 0.04 over MU_WARMUP_STEPS=200, start directly at full LR=0.04 with a very brief 10-step linear warmup from near-zero. The current 200-step warmup may be unnecessarily conservative now that NS5_ITERS=14 and CONTRA_MUON=0.4 stabilise the early updates.

**Why it might help:** The MU_WARMUP_START sweep (#702, in-flight) tests values of the warmup start fraction. This idea is adjacent but distinct: ablate whether warmup is needed at all now that the stack has stabilised. If the warmup was originally added to prevent early NS5 divergence, and NS5_ITERS=14 has fixed that, the warmup may be pure overhead — delaying the first useful Muon update.

**Suggested experiment:** MU_WARMUP_STEPS=10, MU_WARMUP_START=0.01 (near-cold start). Run only after #702 closes to avoid duplication.

**Taste:** Mechanistic grounding 3/4, Research-state value 3/4, Execution value 3/4. Await #702 result before assigning.

---

### 8. Gradient Clipping on AdamW Group (Not Muon)

**What it is:** Apply per-group gradient norm clipping separately to the AdamW scalar/embed/lm_head group, independent of the global norm clip. Current global clip applies uniformly. The embed and lm_head gradients can spike late in training (near logit softcap saturation); group-level clipping would dampen these spikes without touching Muon's gradient norms.

**Why it might help:** With LOGIT_SOFTCAP=20.0, the logit distribution is actively being shaped. Near softcap, gradients through the lm_head/embed can be large and structured differently from Muon-group gradients. A separate clip (ADAMW_GRAD_CLIP=1.0) might reduce the noise contribution of these spikes in the late-run phase, which is where ffs=3000 vs ffs=3025 is typically decided.

**Distinct from #688:** #688 tests MUON_GRAD_CLIP (clip before NS5); this tests AdamW group clip only.

**Taste:** Mechanistic grounding 3/4, Research-state value 2/4, Execution value 3/4. Await #688 result first.

---

### 9. Proj Weight Init Scaling (MLP proj and Attn proj)

**What it is:** Currently `attn.proj` and `mlp.proj` weights are zero-initialised (residual stream stability trick). Consider initialising them to a very small non-zero value (e.g., std=1e-3) instead of hard zero. This is distinct from BLOCK_INIT_MULT which covers QKV/fc only.

**Why it might help:** Zero-init forces the residual stream to be "pure passthrough" at step 0, which helps stability but may slow early learning — the projection weights start with zero gradient signal until the attention/MLP activations grow large enough to produce non-trivial proj gradients. A near-zero init gives a small gradient signal at step 0, which may accelerate early convergence without destabilising the residual path.

**Env var:** `PROJ_INIT_STD=0.0` (default=0 = current behavior); test at 1e-4, 1e-3.

**Taste:** Mechanistic grounding 2/4, Research-state value 2/4, Execution value 3/4. Interesting but speculative — no direct prior evidence in this codebase.

---

### 10. SCALARS_LR Asymmetric Schedule (hold scalars warm during cooldown)

**What it is:** During the Muon LR cooldown phase (steps 3020–3175, MU_COOLDOWN_START=0.95), hold the AdamW SCALARS_LR constant rather than decaying it proportionally with the cosine schedule. Motivation: during Muon cooldown, the Muon update shrinks rapidly, so the embedding and scalar parameters become relatively more important for the final loss descent. Keeping SCALARS_LR at its peak value during this window may recover some of the loss improvement that Muon's cooldown "gives up."

**Implementation:** Add `SCALARS_COOLDOWN_HOLD=1` env var that freezes the AdamW group LR from MU_COOLDOWN_START fraction onward.

**Taste:** Mechanistic grounding 2/4, Research-state value 2/4, Execution value 3/4. Await #675 SCALARS_LR result first — if SCALARS_LR is sensitive at all, the asymmetric schedule becomes more interesting.

---

## Priority Ordering for Next Assignments

After BLOCK_INIT_MULT (#704):

1. **Muon Momentum Bias Correction** (#3 above) — 3 LoC, strong cold-start mechanism, falsifiable at step 500
2. **AdEMAMix on AdamW Group** (#2 above) — strong external evidence, ~15 LoC
3. **NS5 Pre-normalisation** (#4 above) — await NS5_COEFS (#694) result first
4. **SOAP for MLP Blocks** (#6 above) — await ATTN_SOAP trust (#683) result first
5. **Warmup-Free Muon** (#7 above) — await MU_WARMUP_START (#702) result first

Ideas #5, #8, #9, #10 are secondary — assign only after primary axes are exhausted or as parallel low-cost screens.
