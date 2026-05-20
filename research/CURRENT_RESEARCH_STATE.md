# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-20 13:35 UTC
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `val/loss` at 3350 steps (lower is better); `speedrun/final_first_step_to_target` secondary
- **Statistical merge rule:** `(3.28 − μ) × √n ≥ 0.004` AND n mean ≤ current baseline

## Current merged baseline — post-#393

**val=3.27174 / fs=3233.33 (n=3 paired-pod mean)**

Merged recipe:
```
NANOGPT_GRAD_CLIP=10.0
NANOGPT_NS_ITERS=12
NANOGPT_NS_ITERS_COOLDOWN=16
NANOGPT_NS_COOLDOWN_START_FRAC=0.7
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
NANOGPT_ADAMW_BETA2=0.99
NANOGPT_NS_COOLDOWN_SHAPE=late_peak
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
NANOGPT_ADAMW_EMBED_LR_MULT=1.5
```

### Merged stack history

| PR | Change | val (n) | Cumulative baseline |
|----|--------|---------|---------------------|
| #60 | Muon² | 3.2766 (2) | 3.2766 |
| #105 | clip=5.0 | 3.27527 (3) | 3.27527 |
| #165 | clip=10.0 | 3.27474 (3) | 3.27474 |
| #176 | NS=12→16@70% | 3.27461 (3) | 3.27461 |
| #235 | embed linear_floor=15% | 3.27434 (3) | 3.27434 |
| #236 | AdamW β₂=0.99 | 3.27407 (3) | 3.27407 |
| #285 | NS cooldown SHAPE=late_peak | 3.27352 (2) | 3.27352 |
| #290 | NS coef schedule=linear_ramp_down | 3.27200 (3) | 3.27200 |
| **#393** | **AdamW embed LR mult=1.5×** | **3.27174 (3)** | **3.27174** ← CURRENT |

---

## Active experiments (all on r4)

### ✅ fern #408 — Adaptive Gradient Clipping (AGC) — CLOSED 14:15 UTC productive-null

Paired-pod confirmation collapsed pod-0 signal. Final n=3 pooled: mean(val_B)=3.27271 > baseline 3.27200 → pre-staged rule triggers CLOSE. Pod-0 Δ=−0.00252 was favorable-seed luck. AGC mechanism consistent (99.4% trigger rate) but val benefit not reproducible. **16th productive-null this cycle.**
**Follow-up**: fern assigned **#477 OrthoGrad for aux groups**.

### ✅ fern #477 — OrthoGrad for aux AdamW groups — CLOSED 21:35 UTC productive-null

Arms B (embed: +0.00163), C (lm_head: +0.00285) regress; D (embed+lm_head: −0.00080) recovers. Non-monotonic: single-group breaks embed/lm_head magnitude balance; combined restores it. D Δ=−0.00080 passes stat-rule on absolute baseline but well short of −0.002 within-pod threshold — productive-null. **22nd productive-null/negative this cycle.** Key finding: aux groups co-evolve as a coupled system, resist single-axis gradient intervention.
**Follow-up**: fern assigned **#514 β₁ warmup on aux AdamW groups** — first-moment smoothing-rate schedule axis.

### ✅ fern #514 — AdamW β₁ warmup on aux groups — CLOSED 06:15 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS): A=3.27279, B=+0.00135 (null edge), C=+0.00162 (regression), D=+0.00252 (regression). Monotone-ish worsening with warmup aggressiveness. No arm passes stat-rule. **3rd consecutive "less constraint early" closure**: WD warmup (#483 NEGATIVE) + embed-LR warmup (#489 NEGATIVE) + β₁ warmup (#514 NEGATIVE) — bilateral closure across 3 aux-group AdamW schedule axes. Early-training window is uniformly well-tuned across WD/LR/β₁ at merged settings. **28th productive-null/negative this cycle.**
**Follow-up**: fern assigned **#547 lm_head cooldown SHAPE sweep** — pivot from temporal (warmup) to shape (cooldown) axes.

### 🔄 fern #547 — lm_head cooldown SHAPE sweep [assigned 06:20 UTC]

**Branch:** `g1r4-fern/lm-head-cooldown-shape`
**Hypothesis**: lm_head cooldown shape has been linear-default the entire cycle; #454 tested only floor variants. Other cooldown shapes (cosine, late_peak, linear_floor) are untested for lm_head specifically. Hypothesis parallels merged shape work: different parameter groups benefit from different cooldown shapes — embed=linear_floor (#235), NS_iter=late_peak (#285), NS_coef=linear_ramp_down (#290). Arm D re-tests #454 Arm B (lm_head linear_floor) as a sweep-internal sanity arm.
| Arm | NANOGPT_LM_HEAD_COOLDOWN_SHAPE | Profile |
|---|---|---|
| A | linear (control) | current baseline |
| B | cosine | smooth concave decay |
| C | late_peak | mirrors merged NS shape (flat→sharp drop) |
| D | linear_floor | floor=0.15 (re-tests #454 Arm B) |
**ETA full chain:** ~7.3h.

### 🔄 tanjiro #441 — Logit Z-loss (PaLM style) [assigned 06:49 UTC]

Loss-side: `loss += λ · Σ_t logsumexp(logits_t)²`. Arm A (control) terminal, B/C/D in progress. λ ∈ {0.0, 1e-5, 1e-4, 1e-3}.

### ✅ alphonse #442 — Adam-atan2 — CLOSED 17:53 UTC productive-NEGATIVE

b sweep {0.3, 1.0, 3.0}: all regress vs AdamW (b=0). D (b=3.0) misses 3.28 target (+0.010). Magnitude-transform of AdamW formula fully closed. **19th productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **#489 embed-only LR warmup**.

### ✅ alphonse #489 — Embed-only LR warmup — CLOSED 01:47 UTC productive-NEGATIVE

Monotone catastrophic worsening: A=3.27054, B=+0.01026 (frac=0.02), C=+0.01554 (frac=0.05), D=+0.02316 (frac=0.10). All 3 warmup arms fail benchmark (none reach 3.28 target). Full embed LR from step 0 is load-bearing — #102 closure rationale ("early high-LR window is productive") extends to embed AdamW despite mechanistic distinction (sparse-grad vs Muon+NS). **25th productive-null/negative this cycle.** Bilateral closure with #483 WD warmup (also productive-NEGATIVE): the early-training window is bilaterally well-tuned; regularization-REDUCTION by warmup on any group fails.
**Follow-up**: alphonse assigned **#526 embed LR step-0 boost** — inverse direction (boost above 1.5× at step 0, decay to merged 1.5×).

### ✅ alphonse #526 — Embed LR step-0 boost — CLOSED 09:30 UTC productive-NULL (bilateral with #489)

Single-seed 4-arm (drift gate A PASS, |3.27226−3.27174|=0.00052): A=3.27226, B (2.0×, 3%)=−0.00080 (null), C (2.5×, 3%)=−0.00081 (null), D (2.0×, 6%)=+0.00035 (null). B/C plateau identically (boost magnitude saturates by 2.0×); D regresses (longer 6% window mildly worse). Best arm (C) Δ_vs_A=−0.00081 far short of pre-staged −0.002 paired-pod threshold; the n=1 stat-rule "baseline beat" is partly Arm-A drift artifact. `first_step_to_target` invariant across A/B/C=3225. **Bilateral closure with #489**: combined evidence establishes embed step-0 LR at 1.5× is bilaterally optimal — neither boosting (this PR) nor reducing (#489 NEGATIVE) the early embed LR yields actionable improvement. **31st productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **#560 Per-group AdamW β₂ asymmetric sweep** — fresh axis on second-moment time constant (per-group cut of uniform-β₂=0.99 merged setting); motivated by embed-sparsity insights from #474 AdaBelief and #516 Yogi closures.

### 🔄 alphonse #560 — Per-group AdamW β₂ asymmetric sweep [assigned 09:30 UTC]

**Branch:** `g1r4-alphonse/aux-beta2-per-group`
**Hypothesis**: β₂=0.99 was set uniformly across embed/lm_head/scalar AdamW groups (#236). Embed (sparse rows, ~30K of 50K updated per batch, high per-row variance) has very different second-moment dynamics than lm_head (dense, every row every step) and scalar (LayerNorm gains/biases, low variance, small param count). Per-group β₂ has never been tested. Motivated by #474 AdaBelief and #516 Yogi closures — both showed embed sparsity creates pathological dynamics with alternative second-moment formulations; the natural untested question is whether standard AdamW's second-moment formula wants a different *time constant* per group. Structurally distinct from #236 (uniform sweep, MERGED), #474 (replaces formula), #516 (replaces formula), #490 (first-moment lookahead), #442 (magnitude transform).
| Arm | β₂_embed | β₂_lm_head | β₂_scalar | Hypothesis |
|---|---:|---:|---:|---|
| A | 0.99 (control) | 0.99 | 0.99 | Reproduces merged baseline |
| B | **0.95** | 0.99 | 0.99 | Shorter embed memory (sparse-row v_t reset between visits) |
| C | **0.999** | 0.99 | 0.99 | Longer embed memory (longer-window v_t averaging) |
| D | 0.95 | **0.999** | 0.99 | Combined: embed short + lm_head long |
**ETA full chain:** ~7.3h.

### ✅ tanjiro #441 — Logit Z-loss sweep — CLOSED 17:00 UTC productive-NEGATIVE

Z-loss (PaLM style λ∈{1e-5,1e-4,1e-3}) regresses at all non-zero λ. D (λ=1e-3) fails benchmark (val=3.29393 > 3.28). Root cause: logit softcap c=15 already provides sufficient logit regularization — z-loss is redundant and competes at high λ. **18th productive-null/negative this cycle.** Loss-side auxiliary regularization axis fully closed.
**Follow-up**: tanjiro assigned **#487 cooldown-NS pruning ablation**.

### 🔄 tanjiro #577 — NS-cooldown joint-pruning — interaction test [assigned 13:05 UTC]

**Branch:** `g1r4-tanjiro/ns-cooldown-joint-pruning`
**Hypothesis**: All three NS-cooldown sub-stack components (NS_ITERS_COOLDOWN=16, NS_COOLDOWN_SHAPE=late_peak, NS_COEF_SCHEDULE=linear_ramp_down) were individually classified as redundant in #487 (all single-drop Δ in productive-null band; B confirmed at paired-pod n=3). But joint-drop interactions are untested. This 4-arm ablation tests whether the sub-stack is load-bearing *as a unit*: if joint-drop (Arm B) ≈ baseline → 3-axis stack simplification; if Arm B regresses → system interacts nonlinearly (individually redundant but jointly necessary). Arms C and D decompose the interaction.
| Arm | NS_ITERS_COOLDOWN | NS_COOLDOWN_SHAPE | NS_COEF_SCHEDULE | Tests |
|---|---|---|---|---|
| A | 16 (ctrl) | late_peak | linear_ramp_down | Full merged stack control |
| B | **0** | step (inert) | **constant** | Full joint drop of all 3 |
| C | **0** | late_peak (inert) | linear_ramp_down | ITER-only drop (re-validates #487 paired-pod) |
| D | 16 | **step** | **constant** | SHAPE+COEF drop, ITER kept |
**Phase 1** (N=1 sweep ~7.3h) → **Phase 2** paired-pod confirmation if Arm B Δ ∈ null band or Δ ≤ −0.002. If Arm B Δ ≥ +0.005, Phase 1 is sufficient to close (sub-stack load-bearing at N=1).

### ✅ tanjiro #487 — Cooldown-NS pruning ablation — CLOSED 13:05 UTC productive-NULL [paired-pod n=3]

Sweep N=1 Arm B (drop NS_ITERS_COOLDOWN) Δ=−0.00385 winner candidate failed paired-pod confirmation: per-pod Δ split 1−/2+ around mean(Δ)=+0.00003, all three pods in productive-null/redundant band [−0.002, +0.0015]. Merge gates 1 (mean Δ) and 2 (mean val_B) fail; only stat-rule (gate 3) passes. **4th cycle precedent for single-seed → paired-pod collapse** (joining #344, #351, #408 AGC). Mechanism hypothesis (NS_ITERS_COOLDOWN over-orthogonalizes late-phase) falsified — within-pod effect is essentially zero. The N=1 winner was between-seed noise. **33rd productive-null this cycle.** All three NS-cooldown sub-stack components are now individually classified as redundant (B=redundant at n=3 paired-pod, C/D=null at N=1 sweep).
**Follow-up**: tanjiro assigned **NS-cooldown joint-pruning ablation** — joint-drop interaction test of the sub-stack.

### ✅ thorfinn #446 — Label smoothing sweep — CLOSED 15:38 UTC productive-NEGATIVE

Strictly monotone regression: A=3.27326 (ctrl), B=3.31900 (+0.046), C=3.37495 (+0.102), D=3.49666 (+0.223). B/C/D never reached 3.28 target. The merged stack already has three confidence-pressure regularizers (logit softcap=15, embed_lr_mult=1.5×, NS cooldown) — adding label smoothing subtracts gradient signal on already-regularized correct-token targets. **17th productive-null/negative this cycle.** Regularization-addition axes are fully closed.
**Follow-up**: thorfinn assigned **#483 WD warmup schedule** — first regularization-REDUCTION test this cycle.

### ✅ thorfinn #483 — WD warmup schedule (Muon block group) — CLOSED 23:42 UTC productive-NEGATIVE

Clean monotone worsening: A=3.27066, B=+0.00080 (null), C=+0.00258 (regression), D=+0.00400 (regression). Body-block WD=0.025 is load-bearing from step 0 — delaying it hurts. **24th productive-null/negative this cycle.** Bilateral closure: 17 ADD-regularization axes + 1 REDUCE-regularization axis both fail → Muon-WD=0.025 is bilaterally optimal.
**Follow-up**: thorfinn assigned **#520 Body Muon LR cooldown shape sweep** — alternative profiles over the load-bearing 30% cooldown window.

### ✅ thorfinn #520 — Body Muon LR cooldown shape sweep — CLOSED 07:55 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27261−3.27174|=0.00087): A linear=3.27261, B cosine=+0.00163 (marginal regression), C quadratic=+0.00864 (strong regression, fst=-1), D linear_floor=+0.01401 (strongest, fst=-1). Monotone with non-linear distortion of the final-window decay. **Mechanism**: body Muon needs (1) decay to ~zero at end, (2) linear shape (not steeper, not slower). NS-orthogonalized updates have rank-stable magnitudes — late-phase convergence requires actual zero LR to land. **Striking per-group cooldown contrast**: embed wins with linear_floor (#235), body LOSES strongest with linear_floor — different update statistics demand different profiles. Per-group cooldown-shape design axis substantially characterized (lm_head #547 in flight completes the matrix). **30th productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **#554 AdamW embed WD cooldown nudge** — adds small positive WD on embed during cooldown only (currently WD=0). Tests whether late-phase implicit regularization on sparse-row embed group helps; structurally distinct from edward #550 (Muon WD REDUCTION, body group, removes existing).

### 🔄 thorfinn #554 — AdamW embed WD cooldown nudge [assigned 07:55 UTC]

**Branch:** `g1r4-thorfinn/embed-wd-cooldown-nudge`
**Hypothesis**: Add a small positive WD on AdamW embed group during cooldown only (currently WD=0 throughout). Tests whether late-phase implicit regularization in the precision window helps embed representations. Mechanism: with EMBED_COOLDOWN_SHAPE=linear_floor (#235 merged) embed continues receiving non-trivial updates through cooldown — a small WD nudge during this window could gently shrink magnitudes to prevent late-noise drift. Structurally distinct from #483 (early-phase Muon WD warmup, CLOSED NEGATIVE — wrong group + wrong window) and #550 edward (Muon WD REDUCTION on body group — opposite direction + different group). Together with #550, provides bilateral coverage of the WD-cooldown axis.
| Arm | NANOGPT_EMBED_WD_COOLDOWN | Embed WD during cooldown |
|---|---:|---:|
| A | 0.0 (disabled, control) | 0.0 |
| B | 0.001 | 0.001 (~4% Muon scale) |
| C | 0.005 | 0.005 (~20% Muon scale) |
| D | 0.010 | 0.010 (~40% Muon scale) |
**ETA full chain:** ~7.3h.

### ✅ askeladd #452 — Block output projection init scale — CLOSED 05:05 UTC productive-null

Paired-pod confirmation: Arm B (s=0.5) pod-0 candidate Δ=−0.00227 reversed → mean(Δ_pool)=+0.00068 across n=3 pods. 4th paired-pod false-positive caught this cycle (after #344, #351, #408 AGC). DeepNet/T-Fixup family init-scaling axis closed: NS-normalized Muon updates wash out init scaling within first ~100 steps as hypothesized — but no preserved benefit signal. **27th productive-null/negative this cycle.**
**Follow-up**: askeladd assigned **#543 per-block NS iter budget** — spatial allocation by aspect ratio (Bernstein-Newhouse). (#542 Lion-aux mis-assignment closed 05:12 UTC — Lion on aux groups already closed in #77, prior round.)

### 🔄 askeladd #579 — Body Muon LR asymmetry (attn vs mlp) [assigned 13:35 UTC]

**Branch:** `g1r4-askeladd/muon-attn-mlp-lr-asym`
**Hypothesis**: Body Muon uses uniform LR for all body params. Attention matrices (768×768 square, information routing) and MLP matrices (tall/wide feature transformers) have structurally different roles. Post-NS spectral norm is ≈1 per matrix; the LR then sets the per-update spectral magnitude. Per-block-TYPE LR split (attn vs mlp) is structurally distinct from: #543 per-block NS iter, #393 per-group AdamW LR, #409 LLRD depth-LR. Implementation: split Muon into 2 param groups (attn / mlp), apply separate LR multipliers per group in `set_hparams()`.
| Arm | attn_mult | mlp_mult | Effective LRs | Tests |
|---|---:|---:|---|---|
| A | 1.00 | 1.00 | 0.05 / 0.05 | Control (bit-identical to merged) |
| B | **0.80** | 1.00 | 0.04 / 0.05 | Attn conservative (−20%) |
| C | 1.00 | **1.20** | 0.05 / 0.06 | MLP aggressive (+20%) |
| D | **0.80** | **1.20** | 0.04 / 0.06 | Compound attn-lower + MLP-higher |
**ETA full chain:** ~7.3h.

### ✅ askeladd #543 — Per-block NS iter budget — CLOSED 13:35 UTC productive-NULL

Single-seed 4-arm sweep (drift gate A PASS, |3.27243−3.27174|=0.00069): A uniform=3.27243, B aspect=+0.00077 (null), C manual_typeA=−0.00017 (null, best), D manual_typeB=+0.00056 (null). All 3 reallocation arms in productive-null band [−0.002, +0.0015]. NS=12 saturation **robust to spatial reallocation** — combined with #470 uniform escalation finding, NS-iter count is genuinely saturated at this budget. Architectural finding (student-documented): codebase uses split-qkv naming (`attn.q`/`attn.k`/`attn.v` all 768×768 square) — only 2-of-6 Muon blocks (`mlp.fc`, `mlp.proj`) have aspect > 1.0, limiting the spatial reallocation surface. **34th productive-null/negative this cycle.**
**Follow-up**: askeladd assigned **Body Muon LR asymmetry (attn vs mlp split)** — per-block-TYPE LR axis (vs #543 per-block iter), structurally distinct from #393 (AdamW per-group LR) and #409 (LLRD depth-LR).

### ✅ nezuko #454 — lm_head/scalar cooldown shape extension — CLOSED 18:05 UTC productive-null

Arms B/C/D (lm_head_floor, scalar_floor, both): best Δ=−0.00098 (arm B), half the −0.002 threshold. Arm D (stacked) regresses +0.00072 vs A, indicating cross-group interaction at end-of-cooldown. **linear_floor is embed-specific** (sparse-row coverage benefit), not aux-generic. Three prior paired-pod false-positives (#344, #351, #408 AGC) support conservative close. **20th productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#490 NAdam (Nesterov-AdamW) scope sweep** — first-moment reformulation, first Adam-family axis we haven't tested.

### ✅ nezuko #490 — NAdam (Nesterov-AdamW) scope sweep — CLOSED 02:15 UTC productive-null

Arms B (embed: Δ=−0.00059, mild +), C (lm_head: Δ=+0.00063, mild −), D (all_aux: Δ=+0.00275, regression). Best arm B well within null band (need ≤−0.002); D's compounded regression suggests scalar group is bad actor under NAdam (aggressive direction-change due to normalization layers). **26th productive-null/negative this cycle.** Closes the first-moment axis of the AdamW-internal three-axis ablation (magnitude #442 NEGATIVE, first-moment #490 null/regress, second-moment #474 NEGATIVE) — **AdamW-internal axis family substantially exhausted on merged stack**.
**Follow-up**: nezuko assigned **#530 Nesterov-Muon body scope sweep** — structurally parallel test on Muon body momentum (lookahead before NS).

### ✅ nezuko #530 — Nesterov-Muon body scope sweep — CLOSED 10:15 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27253−3.27174|=0.00079): A α=0.95=3.27253, B α=0.00 (bypass)=+0.00630 (regression), C α=0.50 (half-mix)=+0.04114 (severe, target NOT reached), D α=0.99 (over-Nesterov)=+0.00060 (null). **Structural finding**: the cliff is on the *low-α* side (NS-stability breakdown when current-grad weight >>0.05); the plateau is on the *high-α* side (Arm D within noise). α=μ=0.95 sits at boundary of safety — the mix is best understood as a tiny anti-staleness injection (~5% current-grad on top of 95% EMA), small enough to stay in NS's well-behaved spectral domain. Heavier current-grad injection pushes the NS input outside the Newton-Schulz polynomial's well-conditioned regime. **5th body-Muon mechanism axis closed** (joins #102 LR warmup, #356 μ schedule, #434 Lookahead-wrap, #483 WD warmup). Body Muon algorithmic axes on the merged stack are largely exhausted — future body-Muon ideas should target architectural changes (post-NS-side modifications, NS-iteration-count interactions). **32nd productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#568 Per-group cooldown_frac decoupling** — fresh structural axis on per-group cooldown WINDOW LENGTH (vs per-group cooldown SHAPE which is largely characterized).

### 🔄 nezuko #568 — Per-group cooldown_frac decoupling [assigned 10:15 UTC; arm values corrected 10:30 UTC]

**Branch:** `g1r4-nezuko/per-group-cooldown-frac`
**Hypothesis**: The merged stack uses a single cooldown_frac value applied uniformly across embed/body/lm_head/scalar parameter groups (NS has its own #176 NS_COOLDOWN_START_FRAC). Per-group cooldown SHAPE work has established each group has distinct cooldown needs: embed wants linear_floor (#235 MERGED), body wants strict linear (#520 closed NEGATIVE), NS_iter wants late_peak (#285 MERGED), NS_coef wants linear_ramp_down (#290 MERGED). If shapes diverge per group, window lengths likely do too — a structurally fresh untested axis. Mechanistically: embed (sparse-row AdamW) may want longer precision window for rare-row consolidation; body (dense NS-orthogonalized) may want longer precision-window for clean landing at zero LR. Structurally distinct from in-flight portfolio (no overlap with #487, #506, #543, #547, #550, #554, #560).

**Original PR body conflated `cooldown_frac=0.7` (actual code default, LR cooldown spans last 70% from step 1005) with `NANOGPT_NS_COOLDOWN_START_FRAC=0.7` (NS-iter timing only). Student g1r4-nezuko caught the error 10:25 UTC. Arms re-anchored around true 0.70 baseline 10:30 UTC — hypothesis and mechanism unchanged.**

| Arm | embed_cf | body_cf | lm_head_cf | scalar_cf | Tests |
|---|---:|---:|---:|---:|---|
| A | 0.70 (ctrl) | 0.70 | 0.70 | 0.70 | Reproduces merged baseline (cooldown steps 1005→3350) |
| B | **0.80** | 0.70 | 0.70 | 0.70 | Longer embed cooldown (embed enters cd at 670) |
| C | **0.60** | 0.70 | 0.70 | 0.70 | Shorter embed cooldown (embed enters cd at 1340) |
| D | 0.70 | **0.80** | 0.70 | 0.70 | Longer body Muon cooldown (body enters cd at 670) |
**ETA full chain:** ~7.3h.

### ✅ frieren #470 — NS iterations NORMAL phase sweep — CLOSED 20:55 UTC productive-null

Arms B=8 (+0.00235 regression), C=10 (−0.00168 null), D=14 (−0.00145 null). Wide saturation plateau NS ∈ [10, 14]; NS=8 below floor. **Critical compute finding: NS step-time is flat (±1%) across all NS values — orthogonalization is not the per-step bottleneck.** 21st productive-null/negative.
**Follow-up**: frieren assigned **#506 NS-iter warmup schedule** — ramp NS from {8,10} → 12 over first 5-10%.

### 🚨 frieren #506 — NS-iter warmup schedule [sent back to paired-pod 04:43 UTC]

**Branch:** `g1r4-frieren/ns-warmup`
**Hypothesis**: Ramp NS_ITERS from a low starting value → 12 over the first N% of normal phase. Builds on #470 findings: NS=8 is below precision floor in flat mode, but may be acceptable for the first 5% (noisy gradients). Structurally novel: first NS schedule experiment *within* the normal phase (all prior NS schedule work targeted cooldown). Pairs with WD warmup (#483) and embed LR warmup (#489) — "less constraint early" cluster.

**N=1 results (all 4 arms terminated):**
| Arm | NS_WARMUP_START | NS_WARMUP_FRAC | val/loss | Δ vs A | Δ vs baseline |
|---|---:|---:|---:|---:|---:|
| A | 12 | 0.0 | 3.27282 | 0 (ref) | +0.00108 (drift ✓) |
| B | 10 | 0.05 | 3.27321 | +0.00039 (null) | +0.00147 |
| **C** | **8** | **0.05** | **3.27163** | **−0.00119 (null but directional)** | **−0.00011** |
| D | 10 | 0.10 | 3.27215 | −0.00067 (null) | +0.00041 |

**Single-seed winner candidate**: Arm C passes stat-rule (val 3.27163 ≤ 3.27174 baseline AND margin 0.00837 ≥ 0.004), but within-pod Δ=−0.00119 is inside productive-null band [−0.002, +0.0015]. Arm A drifted +0.00108 — partly explaining the disagreement.

**Monotone pattern**: more aggressive early loosening → better val_loss. Aggressiveness (C beats B by 0.00158 at fixed 5% window) > Duration (D beats B by 0.00106 at fixed NS=10) > both axes coherent.

**Sent back for paired-pod confirmation (04:43 UTC)**: 3 paired A/B pods (B=NS=8 over 5% candidate). Same gates as #487: mean(Δ) ≤ −0.002 AND mean(val_B) ≤ 3.27174 AND `(3.28 − mean) × √3 ≥ 0.004`. ETA ~11h.

### ✅ edward #474 — AdaBelief for aux groups — CLOSED 22:35 UTC productive-NEGATIVE

Arms B (embed: +0.04081), C (lm_head: +0.00188), D (all-aux: +0.03479). D ≈ B trajectory confirms embed group dominates catastrophic regression. Root cause: AdaBelief's `(g−m)²` fails on sparse-row embed (absent rows have g=0 but m≠0 → `(g−m)²=m²`, inflating denominator globally). lm_head: stable mild regression. **23rd productive-null/negative this cycle.** Second-moment-formulation axis fully closed.
**Follow-up**: edward assigned **#516 Yogi optimizer on aux groups** — sign-based additive second-moment update (avoids embed sparsity pathology, structurally distinct).

### ✅ edward #516 — Yogi optimizer on aux groups — CLOSED 07:00 UTC productive-NEGATIVE (embed/all-aux) + productive-NULL (lm_head)

Single-seed 4-arm (drift gate A PASS, |3.27419−3.27174|=0.00245 ≤ 0.003): A=3.27419, B embed=+0.00386 (regression), C lm_head=+0.00038 (null), D all-aux=+0.00447 (regression). D ≈ B + 0.00061 — embed regression dominates; lm_head and scalars contribute marginally. Mechanism reading: Yogi's faster-additive v_t reaction destabilizes sparse-row embed at β₂=0.99 (regression grows monotonically through cooldown); dense lm_head indistinguishable from AdamW. Independent of AdaBelief mechanism (#474): Yogi accumulates g² same as AdamW. **Closes second-moment-update-rule axis** — joined with #474 AdaBelief, #442 Adam-atan2, #490 NAdam-aux. **29th productive-null/negative this cycle.**
**Follow-up**: edward assigned **#550 Muon WD cooldown reduction** — first late-phase WD axis (structurally distinct from #483 WD warmup which tested early reduction).

### 🔄 edward #550 — Muon WD cooldown reduction [assigned 07:00 UTC]

**Branch:** `g1r4-edward/muon-wd-cooldown-reduction`
**Hypothesis**: Muon body uses constant WD=0.025; during cooldown LR shrinks linearly toward 0 while WD friction remains constant — WD/LR ratio grows in relative importance. Reducing Muon WD over the cooldown window (0.025 → lower) removes competing magnitude-shrinkage friction at the precision window. Structurally distinct from #483 (CLOSED NEGATIVE) which tested early-phase WD warmup; this tests late-phase WD reduction. Stacks orthogonally with in-flight #487 NS-cooldown pruning and #506 NS-iter warmup (different mechanism: weight-magnitude friction, not orthogonalization budget).
| Arm | NANOGPT_MUON_WD_COOLDOWN_FINAL | WD at cooldown start | WD at cooldown end |
|---|---:|---:|---:|
| A | -1 (disabled, control) | 0.025 | 0.025 |
| B | 0.010 | 0.025 | 0.010 |
| C | 0.005 | 0.025 | 0.005 |
| D | 0.000 | 0.025 | 0.000 |
**ETA full chain:** ~7.3h.

---

## Research theme — current cycle

**34 productive-null/negative results** on optimizer-internal / parameter-temporal / loss-side axes. The strongest confirmed findings:
1. **The cooldown phase is load-bearing signal, not noise.** Any mechanism that blends, averages, or smooths parameters/gradients during the cooldown window hurts:
   - #436 weight-EMA → productive-NEGATIVE
   - #434 Lookahead → productive-NEGATIVE (Muon wrapping 4.5× worse)
   - #399 AdEMAMix → productive-null
   - #419 Cautious AdamW → productive-null
2. **Loss-side auxiliary regularization is exhausted.** Softcap c=15 is optimal (#354) and already bounds the logit-distribution axes that z-loss (#441) and label smoothing (#446) target. Both regress monotonically.
3. **Additive regularization always fails on this stack.** AGC, GC, gradient noise, label smoothing, z-loss — all hurt.

**Current open questions** (in-flight):
1. Does NS-iter warmup (low → 12 over first N%) extract benefit from early gradient noise? (#506 paired-pod confirmation in flight — pod 0 Δ=+0.00175 REVERSED from N=1, productive-NEGATIVE trajectory)
2. ~~Does per-block NS iter allocation (by aspect ratio) help over uniform NS=12?~~ **#543 CLOSED productive-NULL** — NS=12 saturation robust to spatial reallocation; codebase has limited surface (only 2-of-6 Muon blocks non-square).
3. Does lm_head cooldown SHAPE (cosine / late_peak / linear_floor) matter vs default linear? (#547, fern)
4. Does Muon WD reduction during cooldown extract precision-window gain? (#550, edward — late-phase WD axis, structurally distinct from #483 early reduction)
5. Does adding small WD on AdamW embed during cooldown (regularization-add at precision phase) help? (#554, thorfinn — paired with edward #550 to characterize WD-cooldown axis bilaterally across body/embed groups)
6. Does per-group AdamW β₂ asymmetry extract per-group second-moment time-constant gains? (#560, alphonse — fresh axis motivated by #474/#516 embed-sparsity insights)
7. Does per-group cooldown WINDOW LENGTH asymmetry around 0.70 baseline extract gains? (#568, nezuko — fresh structural axis paralleling SHAPE work)
8. Is the *entire* NS-cooldown sub-stack jointly load-bearing even though each component is individually redundant? (#487 follow-up, tanjiro — joint-pruning ablation, structurally novel compound subtraction)

**Stack convergence signal**: 28 productive-null/negative results. The baseline at 3.27174 is well-tuned. New wins will likely come from:
1. **"Less constraint early" schedule cluster** (in flight): NS-iter warmup (#506), β₁ warmup (#514) — early-phase schedule axes. WD warmup (#483) and embed-LR warmup (#489) both closed productive-NEGATIVE — bilateral structural finding.
2. **Late-phase cooldown shape**: body Muon LR cooldown shape (#520 thorfinn) — targeting the load-bearing 30% cooldown window.
3. **Stack simplification** — #487 paired-pod n=3 CLOSED productive-NULL (Arm B drop NS_ITERS_COOLDOWN: mean Δ=+0.00003, classified redundant but not improved). All three sub-stack components (NS_ITERS_COOLDOWN, NS_COOLDOWN_SHAPE=late_peak, NS_COEF_SCHEDULE=linear_ramp_down) are individually classified as redundant under their respective single-drop tests; **joint-drop interaction is untested** — that's the natural next step (follow-up assigned to tanjiro). If joint-drop ≈ baseline, the entire NS-cooldown machinery can be retired.
4. **Non-AdamW body-Muon mechanism axis** — Nesterov-Muon (#530, nezuko new) targets lookahead-before-NS, complementing pre-stage NS scheduling (#506) and shape (#520). The AdamW-internal three-axis ablation is closing (#442 NEGATIVE + #474 NEGATIVE + #490 null = body-side is the natural pivot).
5. **Bilateral regularization closure (from #483 + #489)**: both ADD (17 axes) and REDUCE-by-warmup (Muon-WD, embed-LR) regularization fail → early-training window is bilaterally well-tuned.
6. **Aux-group coupled system insight (from #477)**: future aux-group mechanism experiments should default to "all aux" scope; single-group regresses.
7. **Embed sparsity structural insight (from #474)**: `(g − m)²`-based second moments fail on embed group; `g²`-only formulations (AdamW, Yogi) are safe.

---

## Recently closed experiments

| PR | Student | Hypothesis | Outcome |
|---|---|---|---|
| #483 | thorfinn | Muon WD warmup frac∈{0.05,0.10,0.20} | CLOSED productive-NEGATIVE (monotone: +0.00080/+0.00258/+0.00400; body WD=0.025 is load-bearing from step 0; bilateral WD-level closure) |
| #474 | edward | AdaBelief aux scope sweep | CLOSED productive-NEGATIVE (B=+0.041/D=+0.035 catastrophic embed sparsity; C=+0.002 mild; second-moment-formulation axis closed) |
| #477 | fern | OrthoGrad aux scope sweep | CLOSED productive-null (D=−0.00080 short of −0.002; non-monotonic: singles regress, combined recovers; aux groups coupled system) |
| #470 | frieren | NS iterations normal phase NS∈{8,10,12,14} | CLOSED productive-null (wide plateau [10,14]; NS=8 below floor; NS step-time flat ±1%) |
| #454 | nezuko | lm_head/scalar linear_floor cooldown | CLOSED productive-null (best Δ=−0.00098, half threshold; embed-specific mechanism, not aux-generic) |
| #442 | alphonse | Adam-atan2 b∈{0.3,1.0,3.0} | CLOSED productive-NEGATIVE (D=+0.010 missed 3.28; all worse than ε-based AdamW; magnitude-transform axis closed) |
| #441 | tanjiro | Logit Z-loss λ∈{1e-5,1e-4,1e-3} | CLOSED productive-NEGATIVE (B=+0.00211/C=+0.00151/D=+0.022 missed 3.28; softcap c=15 already bounds logits, z-loss redundant) |
| #446 | thorfinn | Label smoothing α∈{0.05,0.1,0.2} | CLOSED productive-NEGATIVE (monotone: +0.046/+0.102/+0.223; stack already well-regularized) |
| #434 | edward | Lookahead scope sweep | CLOSED productive-NEGATIVE (all arms regression-monotone; Muon wrapping 4.5× worse) |
| #436 | frieren | Weight-EMA (Polyak averaging) | CLOSED productive-NEGATIVE (damage monotone with window; cooldown is signal not noise) |
| #419 | askeladd | Cautious AdamW (all scopes) | CLOSED productive-null (regression all scopes; β₁=0.80 leaves little room for cautious mask) |
| #409 | thorfinn | Per-block LR decay (LLRD for Muon) | CLOSED productive-null (NS normalizes depth-dependent LR) |
| #411 | alphonse | Gradient noise injection | CLOSED productive-null (noise clearly hurts; stack already near noise floor) |
| #407 | tanjiro | AdamW β₂ sensitivity | CLOSED productive-null (symmetric valley around β₂=0.99) |
| #402 | frieren | Gradient Centralization scope | CLOSED productive-null (NS already mean-centers block gradients) |
| #399 | edward | AdEMAMix on AdamW groups | CLOSED productive-null (slow-EMA redundant with β₂=0.99) |

---

## Closed axes (do not re-assign)

**Optimizer-internal / Adam-family**:
- β₁, β₂, ε per-group: all swept, β₁=0.80/β₂=0.99/ε=1e-10 confirmed
- WD per-group: all harmful, axis closed
- Gradient noise injection, GC, Cautious, AdEMAMix, Lookahead, Weight-EMA, AGC, OrthoGrad: all closed
- AdaBelief variance-of-prediction-error second moment: CLOSED productive-NEGATIVE (#474; embed sparsity pathology; `(g−m)²` fails on absent-row sparse groups)
- Muon-WD warmup (all fracs 5-20%): CLOSED productive-NEGATIVE (#483; monotone worsening; body WD=0.025 is bilaterally optimal)
- Lion, Adafactor on aux: closed (prior rounds)
- LLRD Muon: closed (NS normalizes depth scaling)
- AdamW LR per-group (embed=1.5× MERGED #393): embed_mult swept, scalar/lm_head confirmed optimal at 1.0×
- Adam-atan2 magnitude-transform (b∈{0.3,1.0,3.0}): CLOSED productive-NEGATIVE (#442; ε=1e-8 already optimal)
- NAdam (Nesterov-AdamW) aux scope sweep: CLOSED productive-null (#490; best arm B Δ=−0.00059 within null, joint D Δ=+0.00275 regression — scalars likely bad actor)
- Nesterov-Muon body weight sweep α∈{0.0, 0.50, 0.99}: CLOSED productive-NULL (#530; cliff on low-α side: α=0.50 catastrophic +0.04114 fst=-1, α=0.99 plateau null +0.00060; existing α=μ=0.95 is load-bearing AND optimally weighted; mechanism: tiny anti-staleness injection on top of NS-stable EMA; 5th body-Muon mechanism closure; 32nd null this cycle)

**NS precision family**:
- NS_ITERS_COOLDOWN: saturated (#388); **#487 Arm B (drop) at paired-pod n=3: mean(Δ)=+0.00003 — CLASSIFIED REDUNDANT** (not load-bearing, not improved); 4th cycle precedent for N=1 → paired-pod collapse
- NS cooldown SHAPE=late_peak: MERGED #285; #487 Arm C drop = +0.00080 null at N=1
- NS coef schedule=linear_ramp_down: MERGED #290; #487 Arm D drop = +0.00066 null at N=1
- **Joint-drop of NS-cooldown sub-stack: in-flight** (tanjiro #577, joint-pruning interaction test)
- **Per-block NS-iter spatial allocation (aspect ratio)**: CLOSED productive-NULL (#543; NS=12 saturated to spatial reallocation; codebase has only 2 non-square Muon blocks limiting surface)
- NS coef depth/center: saturated (#345, #384)
- NS=12 normal phase: CLOSED productive-null (#470; wide plateau NS ∈ [10,14]; NS=8 below floor; NS step-time flat ±1%)
- NS-iter warmup: in-flight (#506)

**Schedule**:
- Cooldown frac (global): closed
- Embed linear_floor: MERGED #235
- lm_head steeper-decay: harmful (#315)
- lm_head + scalar floor: CLOSED productive-null (#454; embed-specific mechanism, not aux-generic)
- Muon μ schedule: catastrophic; constant μ=0.95 confirmed (#356)
- Muon LR floor: monotone worse (#335)
- Embed-only LR warmup (frac∈{0.02, 0.05, 0.10}): CLOSED productive-NEGATIVE (#489; monotone catastrophic worsening; full embed LR from step 0 is load-bearing; 25th null this cycle)
- Embed LR step-0 boost (decay to 1.5×): CLOSED productive-NULL (#526; B/C plateau at Δ≈−0.0008 within noise floor; D longer window mildly worse; bilateral closure with #489; 31st null this cycle — embed step-0 LR=1.5× is bilaterally optimal)

**Init**:
- Embed init scale: null (#374)
- lm_head init std: monotone worse (#380)
- Block output projection init scale: in-flight (#452)

**Loss-side**:
- Logit softcap=15: confirmed optimal (#354)
- Z-loss λ∈{1e-5,1e-4,1e-3}: CLOSED productive-NEGATIVE (#441; softcap c=15 already bounds logits)
- Label smoothing α∈{0.0–0.2}: monotone catastrophic regression; closed (#446 productive-NEGATIVE)

**Clipping**:
- clip=5 → clip=10: MERGED #165
- AGC (per-parameter): productive-null per paired-pod trajectory (#408)
