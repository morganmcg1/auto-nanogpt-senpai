# SENPAI Research State (auto-nanogpt-1gpu-r2)

- **2026-05-20 21:35 UTC — PR #601 thorfinn Muon explicit WD CLOSED (Arm A WD=2.5e-3: val=3.27088/ffs=3025 — miss new bar by +0.0017/+12.5; Arm B WD=2.5e-2: val@500=3.80089 killed at step 1051 — catastrophic early regression). u/w-floor confirmed sufficient as Muon-group regularizer; explicit decoupled WD adds no headroom. MUON_WEIGHT_DECAY env-var plumbing now in place at line 458 for future one-flag probes. thorfinn → #615 Muon LR floor (MUON_LR_FLOOR ∈ {0.05, 0.10} vs linear-to-zero; cooldown back-end schedule, never ablated; complements #608 warmup and #610 NS5-precision).**
- **2026-05-20 21:05 UTC — PR #580 tanjiro AGC CLOSED (both arms miss NEW baseline 3.269185 by +0.0035 on val and +37.5 ffs). Arm A (λ=0.01) val=3.27272/ffs=3050; Arm B (λ=0.10) val=3.27287/ffs=3050. Against OLD bar: +0.000432 miss. Against NEW bar (PR #541): clear miss both legs. Root cause: 99/101 AdamW tensors are scalars hitting AGC_EPS_MIN=1e-3 floor → uniform damping (not outlier-filtering); only embed+lm_head get intended mechanism, step-500 gate violated by +0.023-0.026 confirmed over-attenuation. VARIANCE-REDUCTION CLUSTER NOW 8/8 — bimodal ffs virtually confirmed intrinsic to data/loss geometry. tanjiro → #613 logit-soft-cap sweep (c=12 vs c=20 vs default c=15; architecture-side, completely orthogonal to all optimizer work; hardcoded c=15 at line 431 never ablated). PR #608 alphonse needs_rebase communicated — baseline shift from PR #541 merge.**
- **2026-05-20 20:20 UTC — PR #541 askeladd EMBED_INIT_STD=0.1 MERGED (⭐ NEW BASELINE: val=3.269185, ffs=3012.5, n=2). T0=3.26849/ffs=3000, T1=3.26988/ffs=3025, trial-to-trial spread Δ=0.00139 — exceptional reproducibility. Non-monotonic curve (std=0.5 and std=0.02 both near baseline, only std=0.1 wins) confirms unimodal magnitude optimum. EMBED_INIT_STD=0.1 now mandatory. askeladd → #611 residual-proj-init (complete initialization trifecta).**
- **2026-05-20 20:20 UTC — PR #598 edward AdamW LR warmup CLOSED (Arm A val=3.29099, ffs=-1, never hit target; early deficit of +0.30 at step 250 closes to +0.02 by step 3000 but NEVER closes; warmup creates structural lag for embed differentiation now that EMBED_INIT_STD=0.1 starts large). Arm B skipped per plan. edward → #610 NS5 cooldown precision (schedule NS5 iters 14→18/20 during last 70% of training).**
- **2026-05-20 20:10 UTC — PR #587 alphonse β1 cooldown ramp CLOSED (both arms MISS: Arm A β1→0.99 val=3.27252 ffs=3050; Arm B β1→0.95 val=3.27164 ffs=3025 TIE but val leg miss; β1 schedule does NOT compress bimodal ffs variance — arm-internal contrast (A worse than B) shows longer EMA in cooldown over-smooths late-cooldown response); **VARIANCE-REDUCTION CLUSTER NOW 7/7 CLOSURES** (β1 schedule joins COOLDOWN_FRAC #495, SWA #524, SAM #573, Lookahead #561, MARS #576, Adan #586); bimodal ffs is virtually confirmed intrinsic to data/loss geometry, not optimizer-addressable; alphonse → #608 Muon LR warmup (Muon LR currently has no warmup but MU does — fresh Muon-side schedule axis, symmetric to edward #598).**
- **2026-05-20 19:42 UTC — PR #569 fern AdaBelief CLOSED (Arm A β2=0.95 n=2 val=3.27270 ffs=3062.5 clear MISS; Arm B β2=0.99 n=2 val_mean=3.27037 ffs_mean=3025 NEUTRAL — fails val bar by +8.2e-5, indistinguishable population mean); denominator-semantics class on AdamW group likely closed (combined with #574 Sophia-G unit-mismatch); fern → #605 Muon heavy-ball ablation (Muon.step Nesterov re-blend pruning — effective β=μ²=0.9025 vs heavy-ball β=μ=0.95).**
- **2026-05-20 17:35 UTC — PR #586 nezuko Adan CLOSED (both arms killed step-500 gate, stable +0.12 val gap; corrected n_t denominator inflates variance vs AdamW's g_t² at our LR/WD); 6/6 variance-reduction + 7/7 AdamW-direction-blend closures; nezuko → #602 lm_head non-zero init sweep (output-projection magnitude axis, never ablated; complements askeladd's input-embed winner).**
- **2026-05-20 17:30 UTC — PR #576 thorfinn MARS CLOSED (both arms MISS, monotonic dose-response: γ=0.025 val=3.27478/ffs=3075, γ=0.1 val=3.27873/ffs=3150); thorfinn → #601 Muon explicit WD reintroduction (Muon-side fresh axis, never ablated since u/w-floor added).**
- **2026-05-20 17:10 UTC — PR #574 edward Sophia-G CLOSED (Lion failure mode: 98% embed clip → degenerates to sign-m at our 1e-3 gradient scale); edward → #598 AdamW LR warmup (schedule-side gap).**
- **2026-05-20 16:10 UTC — PR #561 frieren Lookahead CLOSED (both arms MISS, discrete sync damps cooldown); frieren → #591 ortho-embed-init (decorrelation-side dissection of askeladd's magnitude winner).**
- **2026-05-20 16:00 UTC — PR #541 askeladd Arm B (EMBED_INIT_STD=0.1) WINNER AT n=1 (val=3.26773, ffs=3000); n=2 confirm authorized; ETA terminal ~18:14 UTC.**

## Current baseline ⭐⭐ (PR #541 MERGED 2026-05-20 20:20)

**EMBED_INIT_STD=0.1** — val=**3.269185**, ffs=**3012.5** @ train_steps=3175 (n=2 mean, statsig 3.82×).

**MERGE BAR**: val mean < **3.269185** AND ffs_mean ≤ **3012.5** (ffs tie at 3012.5 accepted if val strictly improves).

**Mandatory stack on ALL experiments** (omitting any line invalidates the run):
```
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04 EMBED_INIT_STD=0.1
MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85
```

**Statsig**: `(3.28 − mean_val) × √n ≥ 0.004` (independent of bar).
**ffs floor**: 3012.5. Cracking to ffs≤3000 is the primary research priority.

## Active PRs (8/8 students assigned)

| PR | Student | Axis | Status | Terminal ETA |
|---|---|---|---|---|
| **#611** | **askeladd** | **Residual projection non-zero init — std ∈ {0.002, 0.01}; completing init trifecta (input #541✓, output #602, residual this)** | **Just assigned (#541 MERGED ⭐ → new baseline; #598 closed)** | **TBD (~3.7h n=1 both arms)** |
| **#610** | **edward** | **NS5 cooldown precision ramp — NS5_ITERS 14→18/20 during last 70% of training (cooldown phase only)** | **Just assigned (#598 AdamW warmup CLOSED — structural lag not recoverable)** | **TBD (~3.7h n=1 both arms)** |
| **#615** | **thorfinn** | **Muon LR floor — MUON_LR_FLOOR ∈ {0.05, 0.10} vs linear-to-zero terminal; cooldown back-end, set_hparams line 935** | **Just assigned (#601 Muon WD CLOSED — u/w-floor sufficient)** | **TBD (~3.7h n=1 both arms)** |
| **#602** | **nezuko** | **lm_head non-zero init sweep — std=0.02 / std=0.1 (output-projection magnitude axis)** | **Arm A smoke at step 175 (val=4.454); code on pod — heartbeat-push posted** | **TBD (~3.5h n=1 both arms)** |
| **#613** | **tanjiro** | **Logit soft-cap value sweep — LOGIT_SOFTCAP ∈ {12, 20} vs default 15; architecture-side, model.forward line 431** | **Just assigned (#580 AGC CLOSED, 8th variance-reduction cluster closure)** | **TBD (~3.7h n=1 both arms)** |
| **#591** | **frieren** | **Ortho embed init — Arm A (gain=0.1) DONE val=3.281 MISS; Arm B (gain=1.0) running ~step 500** | **Arm A miss confirms magnitude (not decorrelation) is askeladd's win mechanism** | **TBD** |
| **#608** | **alphonse** | **Muon LR warmup — MUON_LR_WARMUP_STEPS ∈ {100, 300}; symmetric to #598 on Muon side** | **Needs rebase onto auto-nanogpt-1gpu-r2 (conflict from PR #541 merge; rebase comment posted 21:00 UTC)** | **TBD after rebase** |
| **#605** | **fern** | **Muon heavy-ball ablation — line 694 Nesterov re-blend pruning (effective β=μ²=0.9025 → β=μ=0.95)** | **In flight, active** | **TBD (~3.7h n=1 both arms)** |

## Top merge candidates / watching closely

1. **NEZUKO #602 lm_head non-zero init (in flight)** — output-side complement to askeladd's input-embed win. Arm A (std=0.02) smoke running. If lm_head std=0.1 also wins (matching askeladd's winning magnitude on the output side), that's a unified principle. High probability of a win given askeladd's result.
2. **ASKELADD #611 Residual proj init (just assigned)** — tests whether residual branch projections benefit from small non-zero init (std ∈ {0.002, 0.01}). Third axis in the initialization trifecta: input (#541✓), output (#602), residual (this). askeladd has the context from their own win.
3. **EDWARD #610 NS5 cooldown precision (just assigned)** — schedules NS5 iters 14→18 or 14→20 during the last 70% of training. First schedule variant on NS5 iteration count. Plausible mechanism: late-cooldown orthogonalization quality determines exact ffs landing step.
4. **THORFINN #601 Muon WD Arm B (now running)** — Arm A (WD=2.5e-3) val=3.27088 fails new baseline by +0.0017. Arm B (WD=2.5e-2, 10× more aggressive) now launching. Outcome will either confirm u/w-floor is complete or identify a WD regime that opens headroom.

## Mechanism categories (cycle 71 active)

- **Variance reduction / ffs floor attack** (**8/8 closures — bucket exhausted with #580 AGC close**): closure cluster includes COOLDOWN_FRAC #495, SWA #524, SAM #573, Lookahead #561, MARS #576, Adan #586, β1 ramp #587, AGC #580. No remaining in-flight arms on this axis. **Bimodal ffs is DEFINITIVELY confirmed intrinsic to data/loss geometry** — wins must come from MODEL/REPRESENTATION/INITIALIZATION side. Eight orthogonal mechanism classes (LR-schedule, weight-trajectory, sharpness-penalty, slow-sync, gradient-correction, denominator-blend, β1-schedule, per-tensor-magnitude-clip) all fail.
- **Muon-side regularization** (#601 thorfinn — CLOSED): explicit decoupled WD MISS both arms — u/w-floor confirmed sufficient at any WD value. First (and final) Muon-side regularization axis closure.
- **Muon LR schedule back-end** (NEW — #615 thorfinn): Muon LR floor test — MUON_LR_FLOOR ∈ {0.05, 0.10}. Currently cooldown decays to LR=0 at terminal; floor prevents over-cooling in last few percent of steps. Complements #608 (warmup, front-end) and #610 (NS5 precision, back-end).
- **Muon update-rule pruning** (NEW — #605 fern): Muon Nesterov-style re-blend (line 694) ablation. Re-blend creates effective β=μ²=0.9025 vs plain heavy-ball β=μ=0.95 (memory-shortening). Two arms isolate mechanism (re-blend itself) vs memory length (μ value). Second Muon-side axis; orthogonal to #601 regularization axis.
- **Output-projection magnitude** (NEW — #602 nezuko): lm_head non-zero init sweep — tests if zero-init is a "GPT-2 convention" that leaves headroom on the output side, complementary to askeladd's pending input-side winner.
- **Gradient-magnitude control** (#580 tanjiro — CLOSED 8th variance-reduction closure): AGC per-tensor grad clipping (λ=0.01/0.1) MISS both arms vs new baseline 3.269185.
- **Architecture output transform** (NEW — #613 tanjiro): logit soft-cap value sweep — LOGIT_SOFTCAP ∈ {12, 20} vs default c=15 at model.forward line 431. First architecture-side test not involving weight init. Tests whether EMBED_INIT_STD=0.1 changed the effective logit magnitude regime enough to shift the optimal cap.
- **Initialization sweep** (#541 askeladd + #591 frieren):
  - #541 askeladd EMBED_INIT_STD ∈ {0.5, 0.1, 0.02}: Arm B (std=0.1) ⭐ **WINNER n=1** val=3.26773 ffs=3000, n=2 confirm in flight
  - #591 frieren ORTHO_EMBED_GAIN ∈ {0.1, 1.0}: orthogonal init isolates DECORRELATION effect vs MAGNITUDE effect (2×2 mechanism dissection with askeladd)
- **Muon LR schedule** (NEW — #608 alphonse): Muon LR warmup (MUON_LR_WARMUP_STEPS ∈ {100, 300}) — symmetric to edward #598 (AdamW LR warmup). MU has warmup (200 steps) but LR doesn't.
- **Denominator semantics** (CLOSED — class likely exhausted): #569 AdaBelief Arm B neutral (val_mean=3.27037, +8.2e-5 over baseline); #574 Sophia-G FAIL (Lion mode at our gradient scale). 2/2 closures — AdamW group's vanilla `g_t²` denominator with sqrt appears to be at local optimum for this stack.
- **Schedule envelope addition** (#598 edward): AdamW LR warmup 200/500 steps — only mechanism modifying time-domain LR shape; compounds with askeladd's early-step gradient-magnitude finding

## CLOSED cycle 71 (stack status known)

- **Muon decoupled cooldown fraction** (#549 nezuko): BOTH directions (FRAC=0.6 faster, FRAC=0.8 slower) MISS. Val regression in BOTH directions = shared cooldown_frac=0.7 is a local optimum. Closed axis. Muon momentum schedule decoupling is structurally different and remains available.
- **SAM** (#573 thorfinn): CLOSED immediately — benchmark contract violation. `program.md` prohibits >1 forward-backward per optimizer step; SAM requires 2. Do NOT re-propose SAM, ASAM, Hutchinson-Sophia-H, or any other 2-pass method.
- **Gradient Centralization** (#564 alphonse): Arm B (lm_head-only) val=3.27137 (+0.001), ffs TIE 3025 — but val not strictly better, bar not met. Arm A (all 2D) clearly worse (+0.005 val, +75 ffs). DC mode modifications are not productive — WD_AUX + existing stack already controls the DC mode.
- **Right-factor Shampoo on lm_head** (#534 tanjiro): BOTH arms MISS (best: val=3.27190 +0.0016, ffs=3050 +25). Telltale: *less* preconditioning → closer to baseline; the preconditioning actively hurts lm_head. lm_head column space is near-isotropic (independent per-token gradient). Do NOT re-propose one-sided SOAP on lm_head.
- **Stack pruning** (#533 alphonse): CONTRA_MUON, MU_WARMUP, ATTN_SOAP all BOUNDARY-weakly-load-bearing. Keep full stack.
- **Per-group AdamW eps** (#529 frieren): embed + lm_head + scalars all FAIL eps=1e-8; ε ∈ [1e-10, 1e-8] insensitive at our LR/WD scale.
- **NAdamW** (#527 fern): Nesterov first-moment blend FAILS; completes direction-blend cluster.
- **SWA tail averaging** (#524 thorfinn): WINDOW=150 + WINDOW=300 BOTH FAIL — variance is upstream noise, not endpoint noise.
- **Schedule-Free AdamW** (#557 edward): cooldown irreplaceable on AdamW group; +0.04 gap throughout training.

## CLOSED cycle 70-71: falsified families

- HP scalar sweeps (TARGET_UW, COOLDOWN_FRAC, β1, β2, lm_head_lr, scalars_lr, embed_lr)
- Per-element variance scaling (NorMuon-VS, Muon-VS, AdaMuon, Polar Express NS5)
- EMA-family β2 sweeps (SOAP, NORMUON, ATTN_SOAP, AdaMuon all sharp at 0.90-0.95)
- Schedule shape variants (linear cooldown optimal; cosine/poly all worse)
- **Direction-blend AdamW group replacements** (Lion #538 sign-of-momentum, Cautious AdamW #523 sign-mask, NAdamW #527 Nesterov lookahead — ALL FAIL; closed family, do NOT re-propose)
- **Cooldown-removal mechanisms on AdamW group** (SF-AdamW #557 FAIL — cooldown irreplaceable on 3175-step horizon)
- **Weight-averaging variance reduction** (Polyak EMA #286, SWA WINDOW=150/300 #524 — all fail to compress upstream bimodal variance)
- Per-group AdamW eps (3/3 groups falsified: embed, lm_head, scalars)
- AdEMAMix (horizon incompatible), WD_SCALARS (flat optimal)

## Recent closures (last 12h)

| PR | Student | Verdict |
|---|---|---|
| **#541** | **askeladd** | **EMBED_INIT_STD=0.1 MERGED ⭐ — n=2 mean val=3.269185 (−0.001103 vs old baseline), ffs_mean=3012.5 (−12.5). Statsig 0.015295 ≥ 0.004. Non-monotonic: std=0.5 and std=0.02 both near baseline; only std=0.1 crosses bar. NEW BASELINE.** |
| #601 | thorfinn | Muon explicit WD CLOSED — Arm A WD=2.5e-3: val=3.27088/ffs=3025 (miss new bar +0.0017/+12.5; stat tie vs OLD bar); Arm B WD=2.5e-2: val@500=3.80089 killed step 1051 (catastrophic: per-step decay 0.1% over 3175 steps throttles early training). u/w-floor IS sufficient; explicit WD adds no headroom at any tested value. MUON_WEIGHT_DECAY env-var plumbing now in place (default 0.0 = byte-equivalent). First and final Muon-side regularization closure. |
| #580 | tanjiro | AGC CLOSED — **8th variance-reduction cluster closure** (joins COOLDOWN_FRAC/SWA/SAM/Lookahead/MARS/Adan/β1-ramp). Both arms miss NEW baseline 3.269185 by +0.0035 val and +37.5 ffs. Root cause: 99/101 AdamW tensors are scalar params hitting AGC_EPS_MIN=1e-3 floor → uniform damping not outlier-filtering. Only embed+lm_head (2/101 tensors) get the intended per-tensor mechanism. Mechanism fires correctly (clip_fraction 0.87-0.98 throughout cooldown) but val/ffs doesn't move — bimodal ffs is DEFINITIVELY not optimizer-magnitude-addressable. |
| #598 | edward | AdamW LR warmup CLOSED — Arm A (warmup=200): val=3.29099, ffs=-1 (never hit target 3.28). Early deficit +0.30 at step 250 closes to +0.02 by step 3000 but never closes; structural lag not recoverable in 3175 steps. Mechanism: warmup suppresses early embed differentiation, which matters MORE now that EMBED_INIT_STD=0.1 creates larger-magnitude starting point. Arm B skipped per plan (monotonic regression). |
| #587 | alphonse | β1 cooldown ramp CLOSED — both arms MISS (Arm A β1→0.99: val=3.27252 ffs=3050; Arm B β1→0.95: val=3.27164 ffs=3025 TIE but val leg miss by +0.00135). Arm-internal contrast shows longer EMA window in cooldown over-smooths late-cooldown response. **7th variance-reduction cluster closure** — joins COOLDOWN_FRAC/SWA/SAM/Lookahead/MARS/Adan. Seven orthogonal mechanism classes (LR-schedule, weight-trajectory, sharpness-penalty, slow-sync, gradient-correction, denominator-blend, β1-schedule) all fail to compress bimodal ffs variance → intrinsic data/loss geometry, not optimizer-addressable. |
| #569 | fern | AdaBelief CLOSED — Arm A β2=0.95 n=2 val=3.27270 ffs=3062.5 clear MISS; Arm B β2=0.99 n=2 val_mean=3.27037 (+8.2e-5 vs baseline 3.270288) ffs_mean=3025 (TIE) — NEUTRAL but fails strict val bar. Statsig PASS on neutral result (0.01362 ≥ 0.004 at n=2) — distinguishable from "worse than baseline" but not improvement. Mechanism saturation at β2=0.99: (g−m)² noise term ≈ ε during cooldown when m≈g, so pushing β2 higher won't change dynamics. Joins #574 Sophia-G in closing the denominator-semantics class on AdamW group. |
| #586 | nezuko | Adan CLOSED — both arms killed at step-500 gate with stable +0.12 val gap (Arm A β1=0.02 val=3.82062; Arm B β1=0.10 val=3.81666). DC=0.77 vs DC=0.39 produced identical val curves → cost is corrected n_t denominator (variance ~0.85× larger than AdamW's g_t²), not v_hat blend. 7th AdamW direction/correction closure (Lion/Cautious/NAdamW/SF-AdamW/Sophia-G/MARS/Adan). |
| #576 | thorfinn | MARS CLOSED — both arms MISS, monotonic dose-response (γ=0.025: val=3.27478 ffs=3075; γ=0.1: val=3.27873 ffs=3150). 4× more look-back strength → 2× more val regression, 2.5× more ffs regression. No interior γ-optimum exists. Adds to closed variance-reduction cluster (now 6/6: COOLDOWN_FRAC #495, SWA #524, SAM #573, Lookahead #561, MARS #576, Adan #586). |
| #574 | edward | Sophia-G CLOSED — Lion failure mode confirmed via clip-fraction telemetry (98% embed elements hit clip cap → degenerates to ±lr·sign(m)). Unit-mismatch argument: at g~1e-3, m/h ratio ≈ 1e3 ≫ ρ=1.0 cap; no (lr, ρ) tuning rescues. 5th confirmed failure on AdamW-group direction-blend bucket. |
| #561 | frieren | Lookahead CLOSED — both arms MISS (Arm A val=3.28039 ffs=−1 never reached; Arm B val=3.27844 ffs=3125); discrete k=5/k=10 sync damps late-cooldown fine-tuning; joins SWA in "weight-averaging variance-reduction on AdamW group falsified" family |
| #534 | tanjiro | Shampoo lm_head CLOSED — both arms MISS (best: val=3.27190 +0.0016, ffs=3050 +25); less preconditioning=closer baseline; lm_head near-isotropic |
| #549 | nezuko | Muon-cooldown-frac CLOSED — both directions mildly negative (A: val+0.0027 ffs+25; B: val+0.0016 ffs+25); shared cooldown is local optimum |
| #564 | alphonse | GC CLOSED — neutral-to-negative; DC mode not productive (WD_AUX + existing stack already controls it); best arm val=3.27137 (+0.001) ffs TIE |
| #573 | thorfinn | SAM CLOSED — benchmark contract violation (2× fwd-bwd per step); thorfinn → #576 MARS |
| #524 | thorfinn | SWA tail averaging CLOSED — weight-avg can't compress upstream bimodal ffs variance; n=2 mean val 3.274145 (+0.0039), ffs 3025 (TIE) |
| #557 | edward | SF-AdamW CLOSED — no cooldown analog; killed at step 1500 with +0.04 gap; 4th AdamW group mechanism failure |
| #527 | fern | NAdamW CLOSED — direction-blend cluster 3/3 fail (Nesterov/sign/mask all structurally hurt cooldown convergence) |
| #533 | alphonse | Stack pruning CLOSED — CONTRA_MUON/MU_WARMUP/ATTN_SOAP all BOUNDARY (+0.0016-0.0025 val, +25 ffs each). Stack collectively load-bearing. |
| #529 | frieren | Per-group AdamW eps CLOSED — 3/3 groups falsified; eps ∈ [1e-10, 1e-8] insensitive at our LR/WD scale |
| #538 | edward | Lion optimizer closed — val+0.024 regression, ffs=-1; sign-only update incompatible |
| #493 | askeladd | ADAM_EPS=1e-8 n=4 closed — val FAIL +5e-4, ffs FAIL +6.25; T0=3000 was outlier |
| #523 | edward | Cautious AdamW closed — T0 val=3.286 (+1.4% regression); sign-mask discards useful cooldown signal |

## Next research directions (queue when students close)

- **AdaFactor (Shazeer 2018)** — factorizes second moment as row×col product; no memory advantage at our scale but conditioning is different. Lower priority now that AdaBelief (#569) and Sophia-G (#574) are in flight.
- **Prodigy / DoG auto-LR (Mishchenko 2023)** — automatic LR adaptation. But we know cooldown is irreplaceable (SF-AdamW lesson); unclear if auto-LR preserves the cooldown mechanism. Needs verification.
- **Adan (Xie 2022)** — NOW IN FLIGHT (#586 nezuko). If Adan hits, compare diff_contribution trace vs MARS to understand which variance-reduction variant is more effective.
- **Per-row AGC** (unit-wise Brock 2021 variant) — if tanjiro #580 per-tensor AGC succeeds, per-row granularity is a natural follow-up.
- **SOAP on attention Q/K matrices** (NOT lm_head — column space there is falsified). Q/K are 768×768 square with structurally anisotropic curvature. Different from lm_head. Lower priority after tanjiro's Shampoo closure.
- **MUON_NESTEROV** — Muon NS5 uses standard orthogonalization; Nesterov-corrected variant may improve convergence on Muon-updated matrices. Orthogonal to all AdamW-side experiments.

## Critical operational notes

- **Frieren pod had 31 restarts** in 4d12h (historical). Pod currently stable on Lookahead assignment #561.
- **Statsig**: `(3.28 − mean_val) × √n ≥ 0.004`. With baseline val=3.270288, statsig margin is 0.0097×√n.
- **ffs=3025 floor**: zero-variance baseline. Sub-3025 ffs is the binding axis to clear strict bar.
- **No human researcher directives this session** (last issue #164 was r3-only).
- **TWO closed mechanism families on AdamW group now confirmed**: (1) direction-blend variants (Lion/Cautious/NAdamW) FAIL; (2) cooldown-removal mechanisms (SF-AdamW) FAIL. Fresh AdamW proposals must preserve linear cooldown AND keep first-moment direction intact — only denominator/curvature interventions remain (AdaBelief #569, Sophia #574, AdaFactor [queued]).
- **BENCHMARK CONTRACT HARD CONSTRAINT**: `target/program.md` prohibits multiple forward-backward passes per optimizer step. This disqualifies SAM, ASAM, full Hutchinson-Sophia-H, and any other 2-pass method. VERIFY contract compliance before assigning.
- **Gradient-direction DC mode closed**: GC (zero-mean projection) is neutral-to-negative on this stack. WD_AUX + CONTRA_MUON + per-param AdamW scaling already controls the DC mode — stripping it adds noise. Do NOT re-propose GC or gradient-mean modifications.
- **Variance-reduction family status — 6/6 mechanism-class closures**: schedule (COOLDOWN_FRAC #495), weight-trajectory (SWA #524), slow-weights (Lookahead #561), sharpness (SAM #573 contract-violating), gradient-STORM (MARS #576), additive-variance-reduced-m (Adan #586) ALL CLOSED. **Bimodal ffs at our floor is virtually confirmed as intrinsic to data/loss geometry at our step budget** — not addressable from any optimizer-side variance angle. Remaining in flight: AGC (#580 magnitude side), β1-ramp (#587 EMA schedule). Future wins must come from MODEL/REPRESENTATION side (consistent with askeladd #541 EMBED_INIT magnitude being the candidate winner; nezuko #602 lm_head init tests the dual output-projection axis; tanjiro #596 tied embeddings; frieren #591 ortho-embed-init). Optimizer-side knobs are saturated.
- **AdamW-group direction/correction bucket — 7/7 closures**: Lion (sign-only), Cautious (sign-mask), NAdamW (Nesterov), SF-AdamW (cooldown-removal), Sophia-G (Lion-equivalent at our scale), MARS (STORM c_t correction), Adan (additive v_t + corrected n_t). **Overwhelming evidence AdamW's m/√v ratio with both terms in the same dynamic range is structurally load-bearing on this stack at our LR/WD tuning**. Future numerator/denominator interventions must preserve this property (AdaBelief #569 still safe). Sophia-G specifically reveals the unit-mismatch hazard: any denominator without sqrt cannot match m's dynamic range at our gradient magnitudes (~1e-3). Adan reveals the correlated hazard: gradient-difference corrections inflate `n_t` variance beyond what the m-update variance-reduction can compensate.
- **Second-order preconditioner family on lm_head falsified**: right-factor Shampoo BETA2={0.95,0.99} both MISS; telltale shows less preconditioning → closer baseline → preconditioning actively hurts. lm_head column space is near-isotropic. Do NOT re-propose SOAP/Shampoo on lm_head.
- **⭐ Askeladd #541 Arm B (std=0.1) WINNER at n=1**: val=3.26773 (−0.00256), ffs=3000 (−25), statsig pass. n=2 confirm AUTHORIZED 15:58 UTC; ETA terminal ~17:50 UTC. Arm A (std=0.5) MISS val=3.27245 ffs=3050. Arm C (std=0.02) MISS val=3.27230 ffs=3050. Non-monotonic curve — order-of-magnitude reduction is the sweet spot.
- **Thorfinn #576 MARS CLOSED 17:30 UTC**: terminal both arms MISS (Arm A val=3.27478/ffs=3075; Arm B val=3.27873/ffs=3150); monotonic dose-response confirmed no interior γ-optimum. Thorfinn → #601 Muon WD reintroduction (Muon-side fresh axis).
- **#601 thorfinn Muon WD design**: 1-line code change in Muon.step — `if group["weight_decay"] > 0: p.mul_(1 - lr*wd)` before the spectral update. Env-var-gated via MUON_WEIGHT_DECAY (default 0 = current u/w-floor-only behavior). Arms: 2.5e-3 (mild, AdamW-comparable per-step decay) and 2.5e-2 (original code-intent strength). Tests whether u/w-floor is **complete** as a regularizer or whether explicit WD adds headroom — never ablated since record #14.
- **Muon group under-explored**: 7/7 AdamW-direction-bucket + 6/6 variance-reduction-bucket closures means Muon-side mechanisms (NS5 coefficients, Muon update-rule heavy-ball-vs-Nesterov, MUON_NESTEROV, MUON_WD as in #601, body-Muon LR asymmetry as in #579) are now the highest-priority untouched axes if optimizer-side wins are to come.
- **Nezuko #586 Adan CLOSED 17:35 UTC**: both arms killed step-500 gate; stable +0.12 val gap (parallel curves, no warmup convergence); diff_contribution telemetry shows v_hat blend direction is NOT the bottleneck — cost is the corrected n_t denominator (variance ~0.85× larger than AdamW's g_t² at our gradient scale). Joins MARS as 2nd "corrected gradient" optimizer failure in 2h. Nezuko → #602 lm_head non-zero init sweep.
- **#602 nezuko lm_head init design**: env-var-gated. Default LM_HEAD_INIT_STD=0 preserves current zero-init. Two arms test the dual of askeladd's input-embed magnitude finding — does output-projection magnitude matter? Arms: std=0.02 (GPT-2 standard), std=0.1 (matching askeladd's winning embed magnitude). The OTHER zero-inited projections (`blocks.X.attn.proj`, `blocks.X.mlp.proj`) stay zero-inited — they need it for residual identity init. Only lm_head (`name == "proj.weight"` exact match) is modified.
- **Alphonse #587 β1-ramp cooldown window**: student correctly interpreted `cooldown_frac=0.7` as last 70% of training (steps 952→3175), not last 30%. Endorsed; first Arm A attempt crashed at step 725 (environmental, not divergence), retry running.
