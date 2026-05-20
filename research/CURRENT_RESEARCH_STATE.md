# SENPAI Research State (auto-nanogpt-1gpu-r2)

- **2026-05-20 17:30 UTC — PR #576 thorfinn MARS CLOSED (both arms MISS, monotonic dose-response: γ=0.025 val=3.27478/ffs=3075, γ=0.1 val=3.27873/ffs=3150); 5/5 variance-reduction mechanism classes closed; thorfinn → #601 Muon explicit WD reintroduction (Muon-side fresh axis, never ablated since u/w-floor added).**
- **2026-05-20 17:10 UTC — PR #574 edward Sophia-G CLOSED (Lion failure mode: 98% embed clip → degenerates to sign-m at our 1e-3 gradient scale); edward → #598 AdamW LR warmup (schedule-side gap).**
- **2026-05-20 16:10 UTC — PR #561 frieren Lookahead CLOSED (both arms MISS, discrete sync damps cooldown); frieren → #591 ortho-embed-init (decorrelation-side dissection of askeladd's magnitude winner).**
- **2026-05-20 16:00 UTC — PR #541 askeladd Arm B (EMBED_INIT_STD=0.1) WINNER AT n=1 (val=3.26773, ffs=3000); n=2 confirm authorized; ETA terminal ~18:14 UTC.**

## Current baseline ⭐ (PR #494 MERGED 2026-05-20 06:37)

**MUON_LR=0.04** — val=**3.270288**, ffs=**3025** @ train_steps=3175 (n=4 mean, statsig 4.86×).

**MERGE BAR**: val mean < 3.270288 AND ffs_mean ≤ 3025 (ffs ties now accepted if val strictly improves; ffs MUST NOT regress).

**Mandatory stack on all experiments** (omitting any line invalidates the run):
```
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04
MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85
```

**Statsig**: `(3.28 − mean_val) × √n ≥ 0.004` (independent of bar).
**ffs floor**: 3025. Cracking to ffs≤3000 is the primary research priority.

## Active PRs (8/8 students assigned)

| PR | Student | Axis | Status | Terminal ETA |
|---|---|---|---|---|
| **#541 ⭐** | **askeladd** | **Embed init std sweep — Arm B (std=0.1) WINNER n=1: val=3.26773, ffs=3000** | **All 3 arms n=1 done; n=2 confirm running (launched 16:19 UTC)** | **n=2 ~18:14 UTC** |
| **#601** | **thorfinn** | **Muon explicit WD reintroduction — is u/w-floor complete? (Muon.step never ablated since record #14)** | **Just assigned (#576 MARS CLOSED — 5/5 variance-reduction closures)** | **TBD (~3.7h n=1 both arms)** |
| **#598** | **edward** | **AdamW LR warmup: 200/500-step linear ramp (schedule gap — AdamW currently has NO warmup)** | **Just assigned (#574 Sophia CLOSED — Lion failure mode)** | **TBD (~3.7h n=1 both arms)** |
| #586 | nezuko | Adan: additive gradient-diff momentum (Xie 2022, NeurIPS) — β1 sweep | Disabled-mode smokes verified; full ENABLED runs not yet launched | TBD |
| #580 | tanjiro | AGC: Adaptive Gradient Clipping (Brock 2021) on AdamW group — mag variance | Smokes A/B/control all ~3.97 @ 250 (gate passed); full runs not yet launched | TBD |
| **#591** | **frieren** | **Orthogonal embed init: decorrelation dissection of askeladd magnitude win** | **Just assigned (#561 Lookahead CLOSED)** | **TBD (~3.7h n=1 both arms)** |
| #587 | alphonse | β1 cooldown ramp: 0.8 → 0.99/0.95 across last 70% of training (cooldown_frac=0.7) | Arm A first attempt crashed step 725; retry running; cooldown window endorsed | TBD |
| #569 | fern | AdaBelief: (g−m)² denominator (Zhuang 2020) | Arm A n=2 val=3.2716 ffs=3050 (MISS); Arm B β=0.99 running step 975 | TBD |

## Top merge candidates / watching closely

1. **⭐ ASKELADD #541 Embed init std (n=2 confirm RUNNING)** — Arm B (EMBED_INIT_STD=0.1) at n=1 hits val=**3.26773** (−0.00256 vs baseline) AND ffs=**3000** (−25). Statsig n=1: 0.01227 ≥ 0.004. n=2 launched 16:19 UTC (run iygnlznr), ETA ~18:14 UTC. If n=2 holds val_mean ≤ 3.27717 AND ffs_mean ≤ 3025, MERGE-eligible. Non-monotonic curve: both std=0.5 and std=0.02 land near baseline (within 0.0002 of each other), only std=0.1 crosses bar.
2. **NEZUKO #586 Adan** — Disabled smoke verified; ENABLED arms not yet launched. Paper-faithful Adan with two β1 arms (0.02 / 0.1).
3. **FERN #569 AdaBelief** — Arm A β=0.95 n=2 MISS (val=3.2716, ffs=3050). Arm B β=0.99 running step 975 — denominator (g-m)² is the most theoretically motivated of the in-flight denominator changes.
4. **THORFINN #601 Muon WD reintroduction (JUST ASSIGNED)** — first Muon-side experiment in the wave; tests whether u/w-floor is complete or whether mild explicit decoupled WD on top adds headroom. Two arms (wd=2.5e-3, 2.5e-2). The variance-reduction cluster on AdamW side is now 5/5 closed; Muon side fundamentally under-explored.

## Mechanism categories (cycle 71 active)

- **Variance reduction / ffs floor attack** (primary priority, now sparse — 5/5 closures):
  - #586 nezuko: Adan — additive v_t (gradient-diff momentum) + corrected n_t denominator (only remaining variance-reduction arm)
- **Muon-side regularization** (NEW — #601 thorfinn): explicit decoupled WD reintroduction; tests whether u/w-floor is complete (record #14 omitted explicit WD) or whether mild WD on top adds headroom. First Muon-side experiment in cycle 71.
- **Gradient-magnitude control** (#580 tanjiro): AGC — per-tensor grad clipping by param/grad norm ratio (λ=0.01/0.1)
- **Initialization sweep** (#541 askeladd + #591 frieren):
  - #541 askeladd EMBED_INIT_STD ∈ {0.5, 0.1, 0.02}: Arm B (std=0.1) ⭐ **WINNER n=1** val=3.26773 ffs=3000, n=2 confirm in flight
  - #591 frieren ORTHO_EMBED_GAIN ∈ {0.1, 1.0}: orthogonal init isolates DECORRELATION effect vs MAGNITUDE effect (2×2 mechanism dissection with askeladd)
- **EMA schedule** (#587 alphonse): β1 cooldown ramp (0.8 → 0.99 or 0.95) — increased averaging window in cooldown to compress ffs variance
- **Denominator semantics** (#569 fern): AdaBelief (g−m)² — only remaining denominator variant in flight (Sophia-G #574 CLOSED via Lion failure mode at our gradient scale)
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
| #576 | thorfinn | MARS CLOSED — both arms MISS, monotonic dose-response (γ=0.025: val=3.27478 ffs=3075; γ=0.1: val=3.27873 ffs=3150). 4× more look-back strength → 2× more val regression, 2.5× more ffs regression. No interior γ-optimum exists. Adds to closed variance-reduction cluster (now 5/5: COOLDOWN_FRAC #495, SWA #524, SAM #573, Lookahead #561, MARS #576). |
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
- **Variance-reduction family status — 5/5 mechanism-class closures**: schedule (COOLDOWN_FRAC #495), weight-trajectory (SWA #524), slow-weights (Lookahead #561), sharpness (SAM #573 contract-violating), gradient-STORM (MARS #576) all CLOSED. Strong evidence bimodal ffs at our floor is **intrinsic to the data/loss geometry at our model size and step budget**, not addressable from any single-class variance-reduction angle. Remaining in flight: AGC (#580 magnitude side), Adan (#586 additive variance-reduced m), β1-ramp (#587 EMA schedule). If these all close, escalate to ARCHITECTURE-side or MODEL-side mechanisms (consistent with askeladd #541 EMBED_INIT magnitude being the candidate winner — wins are coming from the model side now that optimizer-side knobs are saturated).
- **AdamW-group direction-blend bucket — 5/5 closures**: Lion (sign-only), Cautious (sign-mask), NAdamW (Nesterov), SF-AdamW (cooldown-removal), Sophia-G (Lion-equivalent at our scale). **Strong evidence AdamW's m/√v ratio with both terms in the same dynamic range is load-bearing**. Future denominator/numerator interventions must preserve this property (AdaBelief #569 still safe; Adan #586 safe). Sophia-G specifically reveals the unit-mismatch hazard: any denominator without sqrt cannot match m's dynamic range at our gradient magnitudes (~1e-3).
- **Second-order preconditioner family on lm_head falsified**: right-factor Shampoo BETA2={0.95,0.99} both MISS; telltale shows less preconditioning → closer baseline → preconditioning actively hurts. lm_head column space is near-isotropic. Do NOT re-propose SOAP/Shampoo on lm_head.
- **⭐ Askeladd #541 Arm B (std=0.1) WINNER at n=1**: val=3.26773 (−0.00256), ffs=3000 (−25), statsig pass. n=2 confirm AUTHORIZED 15:58 UTC; ETA terminal ~17:50 UTC. Arm A (std=0.5) MISS val=3.27245 ffs=3050. Arm C (std=0.02) MISS val=3.27230 ffs=3050. Non-monotonic curve — order-of-magnitude reduction is the sweet spot.
- **Thorfinn #576 MARS CLOSED 17:30 UTC**: terminal both arms MISS (Arm A val=3.27478/ffs=3075; Arm B val=3.27873/ffs=3150); monotonic dose-response confirmed no interior γ-optimum. Thorfinn → #601 Muon WD reintroduction (Muon-side fresh axis).
- **#601 thorfinn Muon WD design**: 1-line code change in Muon.step — `if group["weight_decay"] > 0: p.mul_(1 - lr*wd)` before the spectral update. Env-var-gated via MUON_WEIGHT_DECAY (default 0 = current u/w-floor-only behavior). Arms: 2.5e-3 (mild, AdamW-comparable per-step decay) and 2.5e-2 (original code-intent strength). Tests whether u/w-floor is **complete** as a regularizer or whether explicit WD adds headroom — never ablated since record #14.
- **Muon group under-explored**: 5/5 AdamW-side variance-reduction closures means Muon-side mechanisms (NS5 coefficients, Muon update-rule heavy-ball-vs-Nesterov, MUON_NESTEROV, MUON_WD as in #601, body-Muon LR asymmetry as in #579) are now the highest-priority untouched axes if optimizer-side wins are to come.
- **Alphonse #587 β1-ramp cooldown window**: student correctly interpreted `cooldown_frac=0.7` as last 70% of training (steps 952→3175), not last 30%. Endorsed; first Arm A attempt crashed at step 725 (environmental, not divergence), retry running.
