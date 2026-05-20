# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-20 21:50 UTC
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

### 🔄 fern #584 — lm_head AdamW LR multiplier sweep around 1.0× [assigned 14:15 UTC]

**Branch:** `g1r4-fern/lm-head-lr-ratio`
**Hypothesis**: `NANOGPT_ADAMW_LM_HEAD_LR_MULT` was tested at only one non-control value in #393 (C arm lm_head=1.5×, rejected). Values <1.0× and intermediate values between 1.0× and 1.5× remain unexplored on the post-#393 stack which has `ADAMW_EMBED_LR_MULT=1.5×` merged. Joint vocab update budget mechanism: if embed_mult=1.5× is load-bearing, lm_head_mult may want < 1.0× to balance — specifically 1/1.5 ≈ 0.67. Pure env-var sweep (no code changes; env var already exists from #393). Structurally distinct from #393 (boost-only), #547 (cooldown SHAPE), #454 (cooldown linear_floor).
| Arm | NANOGPT_ADAMW_LM_HEAD_LR_MULT | Effective lm_head LR | Hypothesis |
|---|---:|---:|---|
| A | 1.00 (ctrl) | 1/320 ≈ 0.003125 | Reproduces merged baseline |
| B | **0.70** | ~0.00219 | Joint vocab budget balance (~1/1.5) |
| C | **1.30** | ~0.00406 | Intermediate boost (fills #393's 1.0→1.5 gap) |
| D | **0.50** | ~0.00156 | Deeper LR reduction (locates minimum) |
**ETA full chain:** ~7.3h.

### ✅ fern #547 — lm_head cooldown SHAPE sweep — CLOSED 14:15 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27273−3.27174|=0.00099): A linear=3.27273, B cosine=+0.00012 (null), C late_peak=+0.00179 (regression), D linear_floor=+0.00024 (null). No arm meets −0.002 threshold. **Cross-axis SHAPE transfer hypothesis falsified**: NS late_peak does NOT transfer to lm_head — lm_head wants monotonic decay (dense AdamW group with no mid-phase quality plateau analogous to NS orthogonalization). Reproduces #454 Arm B (linear_floor null). **Per-group cooldown SHAPE design space now substantially characterized**: embed=linear_floor (#235), body=linear (#520 NEG on alternatives), NS_iter=late_peak (#285), NS_coef=linear_ramp_down (#290), lm_head=linear (#547 NEG on alternatives); scalar gap untested. **35th productive-null/negative this cycle.**
**Follow-up**: fern assigned **lm_head AdamW LR ratio sweep** — denser sweep around 1.0× on post-#393 stack (untested space: #393 rejected lm_head=1.5× but <1.0× and intermediate values unexplored; joint vocab update budget mechanism predicts ~0.67×).

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

### ✅ alphonse #560 — Per-group AdamW β₂ asymmetric sweep — CLOSED 17:15 UTC productive-NULL/NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27121−3.27174|=0.00053): A=3.27121, B (β₂_embed=0.95)=+0.00089 (null), C (β₂_embed=0.999)=+0.00359 (regression), D (B + β₂_lm_head=0.999)=+0.00097 (null). No arm beats merged baseline within-pod. Longer embed memory clearly harmful (v_t anchors to early-training stats for ~700-step half-life in 3350-step run); shorter embed memory null (hypothesized sparse-row v_t reset benefit doesn't materialize). D ≈ B within ±0.0001 — lm_head β₂=0.999 inert. **AdamW-internal axis family substantially exhausted**: per-group β₂ joins #442 (magnitude), #474 (AdaBelief formulation), #516 (Yogi update rule), #490 (NAdam first-moment lookahead) as closed. Embed sparse-row gradient statistics on this benchmark are well-served by uniform β₂=0.99 in the 0.95–0.999 range. **38th productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **per-group AdamW β₁ time-constant sweep** — first-moment time constant, structurally distinct from this PR's second-moment axis. Mechanism: at β₁=0.8 with sparse embed rows, momentum decays to near-zero between visits (`0.8^50 ≈ 0`), effectively scaling sparse-row step magnitude down by ~0.2 vs dense groups; ADAMW_EMBED_LR_MULT=1.5 partially compensates via LR; lowering β₁_embed tests whether it's a more principled magnitude restorer.

### 🔄 alphonse #599 — Per-group AdamW β₁ time-constant sweep [assigned 17:15 UTC]

**Branch:** `g1r4-alphonse/adamw-beta1-per-group`
**Hypothesis**: β₁=0.8 uniform across embed/lm_head/scalar (`betas=(0.8, β₂)` hardcoded at line 844). For sparse embed rows seen every ~50 steps, momentum decays `0.8^50 ≈ 1.4e-5` between visits — so m_t at the second visit ≈ `0.2 · g_visit2`, effectively 5× smaller than a dense-group update. Lower β₁_embed restores full sparse-row update magnitude (β₁=0.0 → `m_t = g_visit`, 5× larger than current); higher β₁_embed extends momentum across visits. Untested. Mechanistic complement to #560 (second-moment time constant — disconfirmed) on the first-moment axis.
| Arm | β₁_embed | β₁_lm_head | β₁_scalar | Effective step magnitude on sparse row | Hypothesis |
|---|---:|---:|---:|---|---|
| A | 0.80 (ctrl) | 0.80 | 0.80 | ~0.2·g (current) | Reproduces merged baseline |
| B | **0.50** | 0.80 | 0.80 | ~0.5·g (2.5× boost) | Less smoothing, larger sparse-row updates |
| C | **0.00** | 0.80 | 0.80 | 1.0·g (5× boost) | No momentum — direct gradient step on each visit |
| D | **0.90** | 0.80 | 0.80 | ~0.1·g (0.5× of A) | More smoothing — extend momentum across visits (opposite direction) |
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

### 🔄 thorfinn #590 — NS-cooldown START_FRAC sweep [assigned 15:35 UTC]

**Branch:** `g1r4-thorfinn/ns-cooldown-start-frac`
**Hypothesis**: `NANOGPT_NS_COOLDOWN_START_FRAC=0.7` (NS=12→16 ramp start point) has never been independently swept on the merged stack — bundled at #176 merge with NS_ITERS_COOLDOWN=16 as a heuristic, not an optimized value. Other NS-cooldown axes saturated (#176 mag=16, #285 shape=late_peak, #290 coef=linear_ramp_down) but the TIMING of when the precision window begins is unexplored. Pure env-var sweep. Structurally distinct from #506 (NS-iter warmup at start of training), #487/#577 (sub-stack pruning), #543 (per-block NS spatial), #520 (LR cooldown not NS).
| Arm | NANOGPT_NS_COOLDOWN_START_FRAC | NS=16 ramp starts at | Window length | Tests |
|---|---:|---:|---|---|
| A | 0.70 (ctrl) | step 2345 | 30% (1005 steps) | Reproduces merged baseline |
| B | **0.50** | step 1675 | **50% (1675 steps)** | Longer precision window (more NS=16 compute) |
| C | **0.85** | step 2848 | **15% (502 steps)** | Shorter precision window (concentrated late NS=16) |
| D | **0.60** | step 2010 | 40% (1340 steps) | Intermediate longer (B/A split) |
**ETA full chain:** ~7.3h.

### ✅ thorfinn #554 — AdamW embed WD cooldown nudge — CLOSED 15:35 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27277−3.27174|=0.00103): A=3.27277, B (0.001)=−0.00035 (null edge, fails baseline parity +0.00068), C (0.005)=+0.00657 (regression), D (0.010)=+0.01571 (regression, **FAILS 3.28 target**). Clean monotone regression — any embed WD during cooldown is harmful. Mechanism: with EMBED_COOLDOWN_SHAPE=linear_floor holding embed LR at 15% floor, embed updates are already small; adding WD uniformly shrinks rarely-updated rare-token rows whose representations depend on *accumulated information*. **Bilateral asymmetry on WD-cooldown axis** (paired with #550 winner candidate): embed group rejects added WD during cooldown (NEGATIVE), body Muon group may benefit from REDUCED WD during cooldown (#550 N=1 winner, paired-pod confirming). Both point to "do not constrain rare/sparse representations during cooldown precision window". **36th productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **NS-cooldown START_FRAC sweep** — fresh untested axis. NS_COOLDOWN_START_FRAC=0.7 was bundled at #176 merge, never independently swept on merged stack.

### ✅ askeladd #452 — Block output projection init scale — CLOSED 05:05 UTC productive-null

Paired-pod confirmation: Arm B (s=0.5) pod-0 candidate Δ=−0.00227 reversed → mean(Δ_pool)=+0.00068 across n=3 pods. 4th paired-pod false-positive caught this cycle (after #344, #351, #408 AGC). DeepNet/T-Fixup family init-scaling axis closed: NS-normalized Muon updates wash out init scaling within first ~100 steps as hypothesized — but no preserved benefit signal. **27th productive-null/negative this cycle.**
**Follow-up**: askeladd assigned **#543 per-block NS iter budget** — spatial allocation by aspect ratio (Bernstein-Newhouse). (#542 Lion-aux mis-assignment closed 05:12 UTC — Lion on aux groups already closed in #77, prior round.)

### 🔄 askeladd #579 — Body Muon LR asymmetry (attn vs mlp) [single-seed COMPLETE 21:36 UTC; SENT BACK 21:50 UTC for paired-pod confirmation of compound D]

**Branch:** `g1r4-askeladd/muon-attn-mlp-lr-asym`

**Single-seed 4-arm result** (drift gate A PASS, |3.27189−3.27174|=0.00015):
| Arm | attn | mlp | val/loss | Δ vs A | first_step |
|---|---:|---:|---:|---:|---:|
| A | 1.00 | 1.00 | 3.27189 | — (drift +0.00015 PASS) | 3225 |
| B | 0.80 | 1.00 | 3.27272 | +0.00083 (null) | 3250 |
| C | 1.00 | 1.20 | 3.27269 | +0.00080 (null) | 3250 |
| D | **0.80** | **1.20** | **3.27052** | **−0.00137 (signal, sub-threshold)** | **3225** |

**Pre-staged pattern rule fires exactly**: singletons B/C both null, compound D direction-correct improvement. Sub-threshold of −0.002 mark at n=1. Drift gate clean (+0.00015) confirms implementation correct. **Mechanism**: attn matrices want conservative effective step (less jitter in routing) + mlp matrices want larger step; sub-threshold individually, compose when both applied — aspect-ratio shift between body-Muon matrix types.

**Paired-pod follow-up assigned 21:50 UTC**: 2-arm × 3-pod (A=(1.00, 1.00) ctrl + D=(0.80, 1.20) treatment, 6 runs total, ~6h × 3 parallel pods or ~10.8h sequential). Decision rule predeclared: Δ_mean ≤ −0.002 AND (3.28 − μ_D_mean)·√3 ≥ 0.004 AND μ_D_mean ≤ 3.27174 ⇒ MERGE; else close.

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

### ✅ nezuko #568 — Per-group cooldown_frac decoupling — CLOSED 18:40 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27134−3.27174|=0.00040): A=3.27134, B (embed=0.80)=−0.00014 (null), C (embed=0.60)=**+0.00242 (regression)**, D (body=0.80)=−0.00067 (null, best). No arm crosses −0.002 signal threshold. Best arm D passes single-seed stat-rule at n=1 ((3.28−3.27067)×√1=0.00933 ≥ 0.004) AND beats baseline (3.27067 ≤ 3.27174), BUT within-pod Δ=−0.00067 short of pre-staged paired-pod gate. Embed direction asymmetric-monotonic with floor at 0.70 (shortening hurts; lengthening gives only sub-threshold improvement). Body direction mildly positive sub-threshold (NS-orthogonalized landing benefits *mildly* from longer precision-window but not enough at ±0.10 perturbation). **SHAPE→FRAC analogy fails at this perturbation scale**: per-group cooldown SHAPE matters (real asymmetry) but per-group cooldown WINDOW LENGTH does NOT show same asymmetry within ±0.10 of 0.70. **39th productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#603 AdamW second-moment warmstart via ghost steps** — fresh untested mechanism addressing cold-start direction problem in `exp_avg_sq` that bias correction (magnitude rescaling) explicitly does not solve. Pre-training ghost-step loop accumulates m_t, v_t without weight updates; first ~100 training steps then operate on directionally-informed second-moment estimates instead of cold-start zero.

### 🔄 nezuko #603 — AdamW second-moment warmstart via ghost steps [assigned 18:40 UTC]

**Branch:** `g1r4-nezuko/ghost-step-warmstart`
**Hypothesis**: PyTorch fused AdamW applies bias correction (`m_hat = m / (1−β₁^t)`, `v_hat = v / (1−β₂^t)`) which rescales magnitudes but does NOT change the relative inter-parameter direction of v_t. At β₂=0.99, v_t requires ~1/(1−β₂)=100 steps to reach stationary directional state. During those steps, AdamW aux-group updates use under-informed `v` estimates (initialized to zero). A pre-training warmstart loop running N ghost batches forward/backward, accumulating `exp_avg`/`exp_avg_sq` *without* `optimizer.step()`, could provide a directionally-informed cold-start for the first 100 training steps. Mechanistically distinct from #115 bias correction (separate problem) and from all closed optimizer-family axes (#442, #474, #490, #516, #560 → magnitude/formula/lookahead/update-rule/time-constant changes, none address cold-start direction). Reference: Lion paper notes ghost-step warm-up as a known technique for second-moment buffers.

| Arm | Ghost steps | Scope | Mechanism tested |
|---|---:|---|---|
| A | 0 (ctrl) | n/a | Reproduces merged baseline (cold-start v=0) |
| B | **10** | AdamW aux only | Mild warmstart (~10% of cold-start window) |
| C | **25** | AdamW aux only | Moderate warmstart (25% of cold-start window) |
| D | **50** | AdamW aux only | Strong warmstart (50% of cold-start window; should saturate via bias correction) |
**ETA full chain:** ~7.3h + ~50 ghost steps total across all arms (<<1% overhead).

### ✅ frieren #470 — NS iterations NORMAL phase sweep — CLOSED 20:55 UTC productive-null

Arms B=8 (+0.00235 regression), C=10 (−0.00168 null), D=14 (−0.00145 null). Wide saturation plateau NS ∈ [10, 14]; NS=8 below floor. **Critical compute finding: NS step-time is flat (±1%) across all NS values — orthogonalization is not the per-step bottleneck.** 21st productive-null/negative.
**Follow-up**: frieren assigned **#506 NS-iter warmup schedule** — ramp NS from {8,10} → 12 over first 5-10%.

### 🔄 frieren #593 — Per-group AdamW WD sweep [assigned 16:15 UTC]

**Branch:** `g1r4-frieren/adamw-wd-per-group`
**Hypothesis**: AdamW constructor uses `weight_decay=0` uniformly across all 3 groups (embed/lm_head/scalar) — this default was inherited from upstream modded-nanogpt and never validated on r4 branch. Per-group dense vs sparse update statistics differ substantially: embed sparse-row rejects WD addition (#554 confirmed), but dense lm_head and small-param scalar groups are completely untested at WD>0. Pivots frieren off the now-fully-fenced NS-axis program onto AdamW-internal axes. Structurally distinct from #554 (sparse embed, cooldown only, NEGATIVE), #550 (Muon body), #483 (Muon warmup), #393 (LR multiplier, MERGED), #560 (β₂, in-flight).
| Arm | EMBED_WD | LM_HEAD_WD | SCALAR_WD | Tests |
|---|---:|---:|---:|---|
| A | 0.0 (ctrl) | 0.0 | 0.0 | Reproduces merged baseline |
| B | 0.0 | **0.01** | 0.0 | lm_head WD only (dense output regularization) |
| C | 0.0 | 0.0 | **0.01** | scalar WD only (low-impact null fencepost) |
| D | 0.0 | **0.01** | **0.01** | Combined lm_head + scalar |

Requires minimal code change: 3 env vars + per-group `weight_decay` in AdamW param-group dicts (same pattern as #393 LR multipliers). **EMBED_WD stays at 0** across all arms per #554 closure (embed sparse-row rejects WD).
**ETA full chain:** ~7.3h.

### ✅ frieren #506 — NS-iter warmup schedule — CLOSED 16:15 UTC productive-NEGATIVE [paired-pod n=3]

Paired-pod n=3 confirmation: all 3 pods regress (mean Δ=+0.00087, wrong sign). Gates 1+2 fail (mean Δ above 0, mean val_B 3.27329 > baseline 3.27174). The N=1 Δ_C=−0.00119 was an Arm-A drift artifact (original Arm A drifted +0.00108 above baseline; paired-pod Arm-A controls anchor at +0.00068). **5th cycle precedent for single-seed → paired-pod collapse** (joins #344, #351, #408, #487). **NS-axis program now fully fenced**: 3/3 NS-iter schedule axes closed by frieren (warmup #506, normal-phase #470, cooldown saturation #388) + 3 cooldown-machinery components MERGED (#176, #285, #290) + sub-stack pruning #487 null + spatial #543 null. **37th productive-null/negative this cycle.**
**Follow-up**: frieren assigned **per-group AdamW WD sweep** — currently WD=0 uniformly across embed/lm_head/scalar; whether dense lm_head or small-param scalar groups benefit from WD>0 has never been tested. Structurally distinct from #554 (embed WD ADD cooldown, NEGATIVE — sparse-row mechanism), #550 (Muon body WD), #483 (Muon WD warmup, NEGATIVE).

### ✅ edward #474 — AdaBelief for aux groups — CLOSED 22:35 UTC productive-NEGATIVE

Arms B (embed: +0.04081), C (lm_head: +0.00188), D (all-aux: +0.03479). D ≈ B trajectory confirms embed group dominates catastrophic regression. Root cause: AdaBelief's `(g−m)²` fails on sparse-row embed (absent rows have g=0 but m≠0 → `(g−m)²=m²`, inflating denominator globally). lm_head: stable mild regression. **23rd productive-null/negative this cycle.** Second-moment-formulation axis fully closed.
**Follow-up**: edward assigned **#516 Yogi optimizer on aux groups** — sign-based additive second-moment update (avoids embed sparsity pathology, structurally distinct).

### ✅ edward #516 — Yogi optimizer on aux groups — CLOSED 07:00 UTC productive-NEGATIVE (embed/all-aux) + productive-NULL (lm_head)

Single-seed 4-arm (drift gate A PASS, |3.27419−3.27174|=0.00245 ≤ 0.003): A=3.27419, B embed=+0.00386 (regression), C lm_head=+0.00038 (null), D all-aux=+0.00447 (regression). D ≈ B + 0.00061 — embed regression dominates; lm_head and scalars contribute marginally. Mechanism reading: Yogi's faster-additive v_t reaction destabilizes sparse-row embed at β₂=0.99 (regression grows monotonically through cooldown); dense lm_head indistinguishable from AdamW. Independent of AdaBelief mechanism (#474): Yogi accumulates g² same as AdamW. **Closes second-moment-update-rule axis** — joined with #474 AdaBelief, #442 Adam-atan2, #490 NAdam-aux. **29th productive-null/negative this cycle.**
**Follow-up**: edward assigned **#550 Muon WD cooldown reduction** — first late-phase WD axis (structurally distinct from #483 WD warmup which tested early reduction).

### 🚨 edward #550 — Muon WD cooldown reduction [N=1 winner candidate, sent back to paired-pod 15:05 UTC]

**Branch:** `g1r4-edward/muon-wd-cooldown-reduction`
**Hypothesis**: Muon body uses constant WD=0.025; during cooldown LR shrinks linearly toward 0 while WD friction remains constant — WD/LR ratio grows in relative importance. Reducing Muon WD over the cooldown window (0.025 → lower) removes competing magnitude-shrinkage friction at the precision window. Structurally distinct from #483 (CLOSED NEGATIVE early-phase WD warmup); this tests late-phase WD reduction.

**N=1 sweep results (drift gate A PASS, |3.27303−3.27174|=0.00129):**
| Arm | WD_final | val/loss | Δ vs A | Δ vs baseline | first_step_to_target |
|---|---:|---:|---:|---:|---:|
| A | n/a (0.025 constant) | 3.27303 | — | +0.00129 (drift PASS) | 3250 |
| B | 0.010 | 3.27277 | −0.00026 (null) | +0.00103 | 3225 |
| C | 0.005 | 3.27308 | +0.00005 (null) | +0.00134 | 3225 |
| **D** | **0.000** | **3.26966** | **−0.00337** ⭐ | **−0.00208** | **3175** |

**Arm D passes all three merge gates at N=1**: within-pod Δ ≤ −0.002 ✓, val ≤ 3.27174 ✓, stat-rule (3.28−3.26966)×√1=0.01034 ≥ 0.004 ✓. Non-linear response: only full WD cancellation (0.000) extracts gain; B/C partial reductions are null. Mechanism reading: WD≥0.005 still mechanistically tied to early-phase magnitude regularization; only WD=0 removes the late-phase friction term entirely, letting shrinking-LR gradient signal steer the final landing without competing magnitude pressure. Structurally orthogonal to #176/#285/#290 cooldown-NS work (friction vs orthogonalization budget axes).

**Sent back for paired-pod n=3 confirmation (15:05 UTC)**: 3 paired A/D pods with controlled `SENPAI_SEED` per pod (same seed within pod). Identical merge gates to #487 paired-pod protocol. 4th-cycle single-seed→paired-pod collapse precedent (#344, #351, #408, #487) requires this confirmation before merge. ETA ~10h30m for 6 runs.

---

## Research theme — current cycle

**38 productive-null/negative results** on optimizer-internal / parameter-temporal / loss-side axes. The strongest confirmed findings:
1. **The cooldown phase is load-bearing signal, not noise.** Any mechanism that blends, averages, or smooths parameters/gradients during the cooldown window hurts:
   - #436 weight-EMA → productive-NEGATIVE
   - #434 Lookahead → productive-NEGATIVE (Muon wrapping 4.5× worse)
   - #399 AdEMAMix → productive-null
   - #419 Cautious AdamW → productive-null
2. **Loss-side auxiliary regularization is exhausted.** Softcap c=15 is optimal (#354) and already bounds the logit-distribution axes that z-loss (#441) and label smoothing (#446) target. Both regress monotonically.
3. **Additive regularization always fails on this stack.** AGC, GC, gradient noise, label smoothing, z-loss — all hurt.

**Current open questions** (in-flight):
1. ~~Does NS-iter warmup (low → 12 over first N%) extract benefit from early gradient noise?~~ **#506 CLOSED productive-NEGATIVE** — all 3 pods regress, 5th single-seed→paired-pod collapse precedent; NS-axis program fully fenced.
2. ~~Does per-block NS iter allocation (by aspect ratio) help over uniform NS=12?~~ **#543 CLOSED productive-NULL** — NS=12 saturation robust to spatial reallocation; codebase has limited surface (only 2-of-6 Muon blocks non-square).
3. ~~Does lm_head cooldown SHAPE (cosine / late_peak / linear_floor) matter vs default linear?~~ **#547 CLOSED productive-NULL** — lm_head wants monotonic linear; late_peak doesn't cross-axis transfer from NS.
4. Does Muon WD reduction during cooldown extract precision-window gain? (**#550, edward — N=1 Arm D WD=0 Δ=−0.00337 strong winner candidate; sent back for paired-pod n=3 confirmation, identical protocol to #487; non-linear axis response (only WD=0 extracts gain) is structurally novel; either fresh merge candidate or 5th single-seed→paired-pod collapse**)
5. ~~Does adding small WD on AdamW embed during cooldown help?~~ **#554 CLOSED productive-NEGATIVE** — clean monotone regression; embed group rejects added WD during cooldown; bilateral asymmetry with #550 (body benefits from REDUCED WD, embed rejects ADDED WD).
6. ~~Does per-group AdamW β₂ asymmetry extract per-group second-moment time-constant gains?~~ **#560 CLOSED productive-NULL/NEGATIVE** — embed β₂=0.999 regression (+0.00359), β₂=0.95 null (+0.00089), D inert; AdamW-internal axis family substantially exhausted.
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
| #560 | alphonse | Per-group AdamW β₂ asymmetric sweep (embed/lm_head decoupling) | CLOSED productive-NULL/NEGATIVE (B=+0.00089 null, C β₂_embed=0.999=+0.00359 regression, D inert; AdamW-internal family exhausted; 38th this cycle) |
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
- β₁ per-group: in-flight (alphonse follow-up to #560)
- β₂ per-group asymmetry (embed swept 0.95/0.999, lm_head 0.999): CLOSED productive-NULL/NEGATIVE (#560; embed β₂=0.999 +0.00359 regression, β₂=0.95 +0.00089 null, D inert; AdamW-internal family substantially exhausted)
- ε per-group: all swept, β₂=0.99/ε=1e-10 confirmed
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
- **NS-iter warmup (NS=8→12 over first 5%)**: CLOSED productive-NEGATIVE (#506; paired-pod n=3 mean Δ=+0.00087, all 3 pods regress; 5th single-seed→paired-pod collapse; NS axis fully fenced — 3/3 frieren NS schedule corners closed + sub-stack pruning + spatial reallocation also null)

**Schedule**:
- Cooldown frac (global): closed
- Embed linear_floor: MERGED #235
- lm_head steeper-decay: harmful (#315)
- lm_head + scalar floor: CLOSED productive-null (#454; embed-specific mechanism, not aux-generic)
- **lm_head cooldown SHAPE (cosine/late_peak/linear_floor)**: CLOSED productive-NULL (#547; cross-axis NS late_peak transfer falsified, +0.00179 biggest regression; lm_head wants monotonic linear; reproduces #454 linear_floor null; per-group SHAPE design space now substantially characterized — only scalar untested)
- Muon μ schedule: catastrophic; constant μ=0.95 confirmed (#356)
- Muon LR floor: monotone worse (#335)
- Embed-only LR warmup (frac∈{0.02, 0.05, 0.10}): CLOSED productive-NEGATIVE (#489; monotone catastrophic worsening; full embed LR from step 0 is load-bearing; 25th null this cycle)
- Embed LR step-0 boost (decay to 1.5×): CLOSED productive-NULL (#526; B/C plateau at Δ≈−0.0008 within noise floor; D longer window mildly worse; bilateral closure with #489; 31st null this cycle — embed step-0 LR=1.5× is bilaterally optimal)
- **Embed AdamW WD cooldown nudge (additive)**: CLOSED productive-NEGATIVE (#554; monotone regression A→D, B=+0.00068 null-edge fails baseline parity, C=+0.00657 regression, D=+0.01571 fails 3.28 target; mechanism: embed sparse-row representations depend on accumulated info not noise; WD overrides accumulation; bilateral asymmetry with #550 candidate)

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
