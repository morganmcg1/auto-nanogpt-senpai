# Research Ideas — Wave 3 Nezuko Assignment
# Generated: 2026-05-17 UTC
# Student: g1r4-nezuko
# Context: Post-#105 baseline (val=3.27527/fs=3266.7, n=3). Wave-3 mechanism triangulation complete.

## Background: Wave-3 Mechanism Map

Wave-3 established two ORTHOGONAL improvement axes:
- **Clip axis (AdamW aux — embed/lm_head/scalar):** clip=10 peak ~−0.001 val; saturated past clip=10
- **NS-iter axis (Muon blocks):** NS=12→16 cooldown boost, NS=14 constant, NS=14→8 anneal — all ~−0.001 val

These are structurally independent (different parameter groups). Both axis peaks have single-seed evidence pending n=3 confirmation.

**Wave-3 mechanism triangulation (edward #206, alphonse #188):**
- clip effect is AdamW aux ONLY — Muon gradient norms inert to clipping (NS absorbs magnitude)
- uniform aux LR scaling does NOT reproduce clip's effect → clip's gain is asymmetric per-group rescaling geometry

**Nezuko dead ends (do not repeat):**
- WD warmup (#73): n=2 mean=3.27919, not stat-sig
- cooldown_frac (#106): frac sweep clean negative (0.4–0.7 all worse)
- Polyak EMA (#104): cooldown load-bearing, temporal smoothing family closed
- Per-layer NS iters (#145): degenerates to uniform NS=18; NS≥16 monotonically worse
- Cooldown shape (#204, in-flight close): cosine regresses; sweep closed clean negative

---

## Hypothesis 1 (TOP PICK): AdamW β1 Cooldown Decay on Aux Groups

### Title
AdamW β1 cooldown decay — reduce aux-group momentum during the convergence window

### Mechanism Story
The wave-3 finding establishes that AdamW aux groups (embed/lm_head/scalar) are the sensitive lever: clip=10 helps by geometrically rescaling their effective LR. The β1 parameter (momentum accumulation) is a SEPARATE degree of freedom that has not been touched. During cooldown (final 70% of training = ~2345 steps), the momentum buffer tracks a running average with β1=0.9 — meaning the step direction at any point in cooldown reflects a ~10-step exponential memory. As LR decays toward zero, this memory makes the aux groups "lag" behind the current gradient, smoothing fine-grained loss geometry. Decaying β1 toward 0 during cooldown (e.g., 0.9→0.5) forces the aux groups to respond more aggressively to the CURRENT gradient signal in the precision window. This is structurally different from WD warmup (#73) — that modified weight decay (the L2 term), not the first-moment accumulation. It is also different from cooldown_frac (#106) — that changed WHEN cooldown starts, not what the optimizer does during it.

The timing argument: NS-iter cooldown boost (frieren #176) gains value by sharpening Muon block preconditioner during cooldown. β1 decay is the aux-group analogue: sharpening AdamW response during the same convergence window. If both gain is from "better conditioning in the final window", they should be stackable.

### Predicted Outcome
β1=0.9→0.5 linear decay during cooldown: val ~3.274–3.275, fs ~3250 (−17 steps). Expected to be orthogonal and additively stackable with clip=10 stack once the latter confirms.

### Experimental Design
- **Arm A (control):** baseline β1=0.9 constant (sanity check, should match 3.27527)
- **Arm B (primary):** β1 linearly decayed 0.9→0.5 during cooldown only (cooldown_frac=0.7 unchanged)
- **Arm C:** β1 linearly decayed 0.9→0.3 (more aggressive)
- **Arm D (optional):** β1 decayed 0.9→0.7 (mild)

Implementation: in the optimizer update loop, compute `t_cooldown = (step - warmup_steps) / cooldown_steps` and set `beta1 = 0.9 * (1 - t_cooldown) + target_beta1 * t_cooldown` for aux param groups only (leave Muon block betas unchanged). This is a ~5-line change to the optimizer step function.

### Connection to Wave-3 Findings
Pure aux-group lever consistent with wave-3 mechanism story. Orthogonal to NS-iter axis. Not a proxy for any closed dead end.

---

## Hypothesis 2: Embed/lm_head Initialization Scale Sweep

### Title
Embedding and lm_head initialization scale — AdamW-trained params retain init structure

### Mechanism Story
Edward's #92 note explicitly flagged this as untested: "lm_head/embed init scale haven't been varied; since NS continuously re-orthogonalizes QKV within ~50 steps, init matters less for Muon blocks, but the aux groups are AdamW-trained and retain their initial structure throughout."

The key insight: Muon's NS step continuously projects weight matrices to a fixed scale — initial scale is destroyed within a few steps. But embed (vocab × 768) and lm_head (768 × vocab) are AdamW-trained: their scale at initialization persists as a multiplicative baseline that AdamW's adaptive scaling adjusts relative to. If the init scale is too large, early gradients are dominated by large embedding activations and AdamW spends early steps correcting this; if too small, the embedding contributes under-sized activations and the LM head's output distribution is noisy at initialization. The clip=5.0 mechanism finding is consistent: clipping stabilizes the effective LR of embed/lm_head, which suggests these groups are sensitive to their gradient magnitudes — and that magnitude is partly set by init scale.

Wave-3 also established that the clip axis is saturated past clip=10–15. A different entry point into the same aux-group sensitivity could yield a complementary gain.

### Predicted Outcome
Scale ∈ {0.5, 0.75, 1.0 (baseline), 1.5}: best arm likely 0.75 (tighter init → less corrective overhead). Expected val improvement ~−0.001 if mechanism holds; possible neutral if AdamW's adaptive scaling already compensates within the first N steps.

### Experimental Design
- **Arm A (control):** default init scale=1.0
- **Arm B:** embed and lm_head init × 0.75 (weight_init_std or direct embed.weight initialization)
- **Arm C:** embed and lm_head init × 0.5
- **Arm D:** embed and lm_head init × 1.5 (larger, expect regression)

Only scale embed.weight and lm_head.weight at init — do NOT touch positional encodings or layer norms. The lm_head weight is typically tied to embed weight in nanogpt; verify whether the codebase uses weight tying and scale consistently.

### Connection to Wave-3 Findings
Targets aux parameter groups via a different lever (init structure) than clip (effective LR) or β1 (momentum). Complementary, not redundant. Edward #92's explicit call-out makes this a first-principles due diligence check.

---

## Hypothesis 3: Muon² β2 Cooldown Schedule (Preconditioner Stabilization)

### Title
Muon² β2 schedule — raise second-moment EMA during cooldown for stable preconditioner in convergence window

### Mechanism Story
Muon² feeds `m / (sqrt(v) + eps)` into NS. The v-EMA parameter β2 controls how quickly the preconditioner adapts: β2=0.999 (current) means the effective window is ~1000 steps. During cooldown (final 2345 steps of 3350), the preconditioner is the dominant signal shaping NS input quality. The hypothesis: a HIGHER β2 during cooldown (e.g., 0.999 → 0.9999) would smooth the preconditioner estimate over a longer window, reducing per-step noise in the NS input. This is structurally analogous to frieren's NS=12→16 cooldown boost (#176), which improved Muon block output by spending more compute on NS orthogonalization during cooldown. Boosting β2 during cooldown is a complementary route: instead of spending more NS iterations, we reduce the noise that NS must orthogonalize around.

Note: edward #115 showed BC (bias correction) and clip=5.0 are redundant, and tanjiro #97 established β2=0.999 is safe on the merged clip baseline. Those experiments held β2 CONSTANT. A cooldown schedule on β2 is a different hypothesis: not correcting for warm-up bias, but stabilizing late-training preconditioner dynamics.

Important: apply to Muon blocks only (consistent with wave-3 Muon-axis experiments). The AdamW aux groups already have their own β2 — if this helps, it helps through the Muon preconditioner path.

### Predicted Outcome
β2 0.999→0.9999 linear ramp during cooldown: val ~3.274–3.275. Possible neutral outcome if NS orthogonalization already absorbs preconditioner noise. Riskier than hypothesis 1 (less direct mechanism link), but ORTHOGONAL to all aux-group levers.

### Experimental Design
- **Arm A (control):** β2=0.999 constant
- **Arm B (primary):** β2 ramped 0.999→0.9999 linearly during cooldown (Muon block groups only)
- **Arm C:** β2 ramped 0.999→0.99999 (aggressive; may over-smooth)
- **Arm D:** β2 ramped 0.999→0.9995 (mild)

Implementation: track `beta2_muon` in optimizer state and update per step during cooldown. Only modify param groups belonging to Muon blocks (not the aux AdamW groups).

### Connection to Wave-3 Findings
Targets Muon blocks via the v-EMA path (orthogonal to NS-iter count axis). NS-iter cooldown boost (frieren #176) works via orthogonalization compute; β2 cooldown works via input conditioning quality. If both axes confirm, stacking β2 cooldown with NS=12→16 cooldown should be considered.

---

## Hypothesis 4: AdamW Weight Decay Cooldown Boost on Aux Groups

### Title
AdamW WD cooldown boost — opposite direction from WD warmup (#73); full WD then boost during convergence

### Mechanism Story
WD warmup (#73) was closed as not-stat-sig: ramping WD from zero to full during warmup failed. The reasoning was that low early WD means the model doesn't penalize large aux weights during the initial trajectory. The OPPOSITE mechanism is untested: start at full WD (0.1) and then BOOST it during cooldown (e.g., 0.1→0.3) to pull aux parameters more aggressively toward zero as the optimizer converges. This is a "basin sharpening" effect during cooldown: higher L2 penalty biases the final weights toward lower-norm solutions, which in the language model context often means more generalizable embeddings with less memorization. The mechanism is distinct from WD warmup (#73) because it targets the final convergence window (same temporal scope as clip, β1 decay, NS cooldown boost) rather than initialization geometry.

Risk: WD too high could over-regularize and degrade val. The sweep must include a control arm and a mild boost to confirm the direction before going aggressive.

### Predicted Outcome
WD boost 0.1→0.2 during cooldown: small val improvement possible (~−0.001) or neutral. Stronger boost (0.1→0.4) likely regresses. Lower confidence than hypotheses 1–3.

### Experimental Design
- **Arm A (control):** WD=0.1 constant
- **Arm B:** WD linearly boosted 0.1→0.2 during cooldown (aux groups only — Muon blocks use WD=0 per standard Muon practice)
- **Arm C:** WD linearly boosted 0.1→0.3
- **Arm D:** WD boosted 0.1→0.4 (expect regression)

Scope: aux param groups ONLY (embed, lm_head, scalar). Muon block WD should remain at its current value.

### Connection to Wave-3 Findings
Pure aux-group lever. Not a proxy for closed dead end (#73 was warmup direction not cooldown boost; different mechanism).

---

## Hypothesis 5: Per-Block Layer-wise LR Scaling (muP-Style, Muon Blocks)

### Title
Layer-depth LR scaling for Muon blocks — linear scaling front-to-back (muP-style, NOT per-layer NS iters)

### Mechanism Story
Per-layer NS iters (#145) was closed as degenerating to uniform NS=18. That experiment varied NS ITERATION COUNT per layer. This hypothesis varies LEARNING RATE per block, which is a completely different lever. In maximal update parametrization (muP), the optimal LR varies as 1/depth for attention layers in deep transformers. Our 12-layer model is too shallow for full muP transfer, but there is a softer version: early blocks (1–4) have larger gradient norms because they receive gradients from all subsequent layers; late blocks (9–12) have smaller norms. Scaling LR linearly with depth (block 1 gets 0.8×, block 12 gets 1.2×) could better-balance the effective step sizes across the residual stream. This is strictly a LR allocation problem, not an NS problem — the NS orthogonalization still applies uniformly and saturation at NS≥16 is irrelevant.

Note: Muon's NS step outputs a matrix of fixed Frobenius norm, so LR scaling is the primary mechanism for controlling effective step size per block (not gradient magnitude, which NS has absorbed).

### Predicted Outcome
Linear depth scaling ±20%: possibly small gain (~−0.001) or neutral. Risk of miscalibration if scaling is too steep. Lower confidence than hypotheses 1–3; more speculative mechanism.

### Experimental Design
- **Arm A (control):** uniform LR for all Muon blocks
- **Arm B:** linear LR scaling 0.8× (block 0) to 1.2× (block 11) — 12 groups
- **Arm C:** inverse linear 1.2× (block 0) to 0.8× (block 11) — earlier blocks get more LR
- **Arm D:** sqrt-depth scaling {0.88, 0.93, 1.0, 1.05, 1.09, 1.13, 1.16, 1.20, 1.22, 1.24, 1.26, 1.28} × base LR

Implementation: expand Muon param groups from one list to 12 per-block groups, each with its own LR multiplier. The base LR (0.035) is preserved on average.

### Connection to Wave-3 Findings
Targets Muon blocks via LR allocation (orthogonal to NS-iter axis and aux-group axis). Not a repeat of closed #145 (that varied NS iters per layer, not LR).

---

## Hypothesis 6: Label Smoothing on Cross-Entropy Loss

### Title
Label smoothing — modify loss signal to broaden/sharpen convergence basin

### Mechanism Story
Label smoothing (ε ∈ [0.05, 0.15]) replaces the one-hot targets with a soft distribution. In language modeling, it has two effects: (1) it reduces overconfidence in high-probability tokens, which can prevent the model from sharpening on spurious n-gram patterns, and (2) it changes the effective gradient signal at the final token — the KL divergence between predicted distribution and smoothed target has lower gradient magnitude near high-confidence predictions. For a fixed-architecture model at late convergence, this can be analogous to a form of entropy regularization. On this benchmark specifically: the model is measured at the validation loss level, and label smoothing ε > 0 means the TRAINING loss is measured on smoothed targets while val loss is still measured on clean targets — so the train/val loss gap widens. There is a real risk that label smoothing hurts the val metric by miscalibrating the model at convergence. The counter-case: ε=0.05–0.10 might smooth the loss landscape enough to let the optimizer reach a lower-variance final basin, improving generalization.

This is a loss-level lever, architecturally independent of all optimizer axes. It has not been tried by any student.

### Predicted Outcome
ε=0.05: possible small gain or neutral; ε=0.10–0.15: likely regression (train/val gap too wide). High uncertainty; this is an exploratory hypothesis rather than a mechanistically grounded one.

### Experimental Design
- **Arm A (control):** ε=0
- **Arm B:** ε=0.05
- **Arm C:** ε=0.10
- **Arm D:** ε=0.15

Implement as `F.cross_entropy(logits, targets, label_smoothing=ε)` in the training loop. No other changes.

### Connection to Wave-3 Findings
Loss-level lever; independent of all optimizer axes. Exploratory; lower priority than hypotheses 1–4 unless 1–3 all exhaust.

---

## Ranking Summary

| Rank | Hypothesis | Axis | Confidence | Mechanism Strength |
|------|-----------|------|-----------|-------------------|
| 1 | AdamW β1 cooldown decay | Aux group, momentum | High | Wave-3 consistent, directly analogous to NS cooldown boost on Muon side |
| 2 | Embed/lm_head init scale | Aux group, init | Medium-High | edward #92 explicit flag; wave-3 aux sensitivity story |
| 3 | Muon² β2 cooldown schedule | Muon block, preconditioner | Medium | Analogous to NS cooldown boost; orthogonal axis |
| 4 | WD cooldown boost (aux) | Aux group, regularization | Medium-Low | Reasonable but lower mechanistic grounding |
| 5 | Per-block LR scaling | Muon block, LR allocation | Low-Medium | Speculative; muP analogy indirect for 12-layer |
| 6 | Label smoothing | Loss level | Low | Exploratory; high risk of train/val miscalibration |

**TOP PICK FOR NEZUKO: Hypothesis 1 (AdamW β1 cooldown decay)**
