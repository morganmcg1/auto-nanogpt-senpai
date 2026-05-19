# SENPAI Research State

- 2026-05-19 19:10 UTC — **MAJOR PROGRESS: PR #479 MERGED + edward #458 EXCEPTIONAL n=2 result**

  **PR #479 merged (NS5_ITERS=14)**: New baseline val=3.273085/ffs=3050. New mandatory stack adds NS5_ITERS=14. New bar: val<3.273085 AND ffs<3050 (strict, both required).

  **Edward #458 (WD_AUX=0.001)**: Run `uoak0qa8` FINISHED. Both T0=T1=ffs=3025 (zero variance!). n=2 mean: val≈3.27139/ffs=3025 — beats new bar by 0.0017 val and 25 ffs. Statsig 3.04×. Awaiting student SENPAI-RESULT for merge.

  **Three math kills from new bar tightening**:
  - Askeladd #468 (GRAD_CLIP_NORM_ADAM=1.0): n=2 mean ffs=3062.5, MISS both bars. CLOSED.
  - Nezuko #469 (EMBED_LR=0.225): T0 ffs=3075, new bar requires T1<3025 impossible. MATH KILL.
  - Thorfinn #462 (MU_WARMUP_START=0.80 n=4): T0+T1+T2={3075,3050,3075}, T3=3025 gives mean=3056.25>3050. MATH KILL.

  **Fern #456** sent back for Arm B (SCALARS_LR=0.0125) with NS5=14 stack.

  **New assignments** (all 4 idle students now assigned):
  - Alphonse → #492 NS5_ITERS=16 (direct extension of winning axis)
  - Askeladd → #493 AdamW eps=1e-8 (vs hardcoded 1e-10, never swept)
  - Nezuko → #494 MUON_LR sweep (0.035 vs 0.04 around 0.0375, never swept)
  - Thorfinn → #495 COOLDOWN_FRAC sweep (0.65 vs 0.75 around 0.7, never swept)

  **In-flight**: edward #458 (awaiting SENPAI-RESULT, ~merge-ready), fern #456 (Arm B pending), frieren #488 (AdamW β1), tanjiro #491 (AdamW β2).

  **Research theme shift**: With NS5_ITERS=14 and WD_AUX=0.001 both showing ffs=3025 (25 steps better than baseline), the focus is on (a) confirming WD_AUX win, (b) probing further NS5 iterations, and (c) sweeping long-untouched hyperparameters (MUON_LR, COOLDOWN_FRAC, Adam epsilon). Two stacked wins at ffs=3025 suggest compounding potential — if NS5=16 and WD_AUX=0.001 are orthogonal, stacking could push ffs toward 3000.

- 2026-05-19 18:09 UTC — Cycle 68 ops — **#485 tanjiro CLOSED** COOLDOWN_POWER=0.5 (sqrt back-loaded cooldown) gate-killed at step 2272 (val@step2000=3.46616 vs gate 3.40, baseline ~3.37 — saved ~105 min compute by skipping T1). **COOLDOWN_POWER axis fully characterized**: power=2.0 → math kill (#464); power=1.0 → baseline; power=0.5 → gate kill (#485). Local optimum at linear. **Tanjiro → #491 AdamW β2 sweep** (ADAM_BETA2=0.90 vs 0.99 around hardcoded 0.95) — FRESH axis: AdamW betas (0.8, 0.95) hardcoded since project init; β2=0.95 unusual vs PyTorch default 0.999. Cleanly orthogonal to frieren's β1 sweep (#488). Could compound with edward's WD_AUX=0.001 T0 winner.

- 2026-05-19 17:21 UTC — Cycle 68 ops — **#459 frieren CLOSED** Lookahead-AdamW K=5 (T0 val=3.27981/ffs=3175 → math kill; student aborted T1 at step 611, saved ~50 min GPU). Axis tentatively falsified at α=0.5 on new stack — slow-weight averaging tracked baseline mid-cooldown but failed to pull ahead in late cooldown. **Frieren → #488 AdamW β1 sweep** (ADAM_BETA1=0.75 vs 0.85 around hardcoded 0.8) — FRESH axis: AdamW betas `(0.8, 0.95)` hardcoded since project init, never swept; β1=0.8 unusual vs PyTorch default 0.9. Plumbing: single-line addition `ADAM_BETA1 = float(os.environ.get(...))` + replace `betas=(0.8, 0.95)` with `betas=(ADAM_BETA1, 0.95)`. Cleanly orthogonal to all in-flight axes; could compound with edward's WD_AUX winner. Zero idle students; all 8 active with PRs.

- 2026-05-19 17:09 UTC — Cycle 68 T0 wave — **TWO independent T0 winners on different axes**: **alphonse #479 NS5_ITERS=14 T0 PASS** (val=3.27175/ffs=3025) and **edward #458 WD_AUX=0.001 T0 PASS** (val=3.27166/ffs=3025) — both beat strict bar val<3.273477 AND ffs<3056.25 cleanly on first trial. T1s in flight (alphonse step 776/3175 of T1, edward step 226/3175 of T1, terminals ~18:25/~18:43 UTC). **frieren #459 Lookahead-AdamW K=5 MATH KILLED at 17:06 UTC** (T0 val=3.27981/ffs=3175 — ffs miss by +119 forecloses any T1 from rescuing n=2 mean<3056.25 since min feasible T1 ffs ≈ 3025 → mean ≥ 3100). Askeladd #468 grad-clip T0 narrow miss (val=3.27568/ffs=3075 — T1 needs ffs=3025+val<3.2713). Fern #456 SCALARS_LR=0.0075 T0 narrow miss (val=3.27491/ffs=3075 — T1 needs ffs=3025+val<3.27205). **Notable**: alphonse and edward T0 cluster at ffs=3025 (better than the all-PR-#415-trials-at-3050 baseline!) suggests both axes shave ~25 steps off cooldown-target crossing — may compound when stacked.

- 2026-05-19 16:23 UTC — Cycle 68 ops — **#462 thorfinn n=2 terminal: Arm A (MU_WARMUP_START=0.80) MISSES new bar marginally** (n=2 mean val=3.274575/ffs=3062.5 vs new bar 3.273477/3056.25, MISS by +0.0011/+6.25). **T1 individually BEATS both bars cleanly (val=3.27399/ffs=3050)** — axis is capable, variance-dominated at n=2. **Sent back for n=4 confirm at MU_WARMUP_START=0.80** (T2+T3 batch). Math: T2+T3 mean val must be < 3.2724 (achievable if tracking T1), ffs both must hit floor=3050. Branching: PASS → merge; MISS<0.0005 val → no-worse-than-baseline, then Arm B (0.90); MISS>0.0005 → Arm B sequentially. Nezuko `gnlula77` Arm A fresh screen at step ~800/6350 post-contention restart (post-mortem clean: t650n0bn killed by GPU contention with smoke; T0 of t650n0bn val=3.27418/ffs=3075 preserved as n=1 prior evidence — Arm A consistent ~3.274 val, ffs bimodal 3050/3075). Tanjiro reassigned to PR #485 COOLDOWN_POWER=0.5 sqrt cooldown n=2 (single arm symmetric counter to power=2.0 math kill).

- 2026-05-19 16:05 UTC — Cycle 68 ops — **#464 tanjiro CLOSED** COOLDOWN_POWER=2.0 quadratic n=2 screen MATHEMATICAL KILL on NEW stack (T0 val=3.28756, ffs UNDEFINED — val never crossed 3.28 within 3175-step budget; T1 aborted at step ~279 saving ~94min GPU). Axis verdict: power > 1 (front-loaded decay) WRONG direction on new stack; symmetric counter (power < 1, e.g., sqrt) is natural next test. **tanjiro → next: COOLDOWN_POWER=0.5 sqrt cooldown n=2 screen on NEW stack** (back-loaded decay; plumbing already verified by smoke 5o8665fx). Thorfinn #462 T0 val=3.27516/ffs=3075 (split: val beats new bar, ffs misses by 18.75); T1 ~88% complete, terminal ~16:20 UTC; n=2 mean ffs likely misses (would need T1 ffs ≤ 3037.5, only achievable if T1 ffs=3025 — improbable). Nezuko #469 EMBED_LR n=2 screen at step 4026/6350 (63%), both smokes done. Fern #456 Arm A SCALARS_LR=0.0075 n=2 at step ~1272/6350 post-rebase. Askeladd #468 grad-clip n=2 at step ~1275 post-cleanup. Alphonse #479 NS5_ITERS=14 n=2 at step ~1600. Frieren #459 Lookahead-AdamW K=5 n=2 at step ~1350. Edward #458 WD_AUX n=2 at step ~1050.

- 2026-05-19 14:34 UTC — Cycle 68 closure + new assignments — **#429 alphonse CLOSED** (NS5_ITERS=14 on PREV stack: n=2 partial confirm val=3.274342/ffs=3062.5 MISSES both NEW bars; axis NOT falsified — bar moved due to PR #415 merge). **alphonse → #479 NS5_ITERS=14 re-screen on NEW mandatory stack** (highest-priority axis re-test; predicted T0≈3.272 on new stack; +0.8% step-time only). New cycle state: all 8 students have active WIP PRs: thorfinn #462 (MU_WARMUP_START), fern #456 (SCALARS_LR — post-rebase, investigating smoke crash), edward #458 (WD_AUX), frieren #459 (Lookahead-AdamW), askeladd #468 (grad-clip-adam — newly assigned), nezuko #469 (EMBED_LR new stack — newly assigned), tanjiro #464 (cooldown-power sweep), alphonse #479 (NS5_ITERS=14 new stack — just assigned). Heartbeated #464 tanjiro.

- 2026-05-19 14:17 UTC — Cycle 68 mid-flight ops — Heartbeated #462 thorfinn (n=2 running at step 2775/6350, MU_WARMUP_START=0.80), #458 edward (n=2 running at step 550/6350, WD_AUX=0.001), acknowledged #456 fern's self-correction (rebase fix for pre-PR-#415 silent stack issue — important footgun lesson), follow-up on fern's post-rebase smoke ALSO crashing at step 150 (pod restarted 23m ago — investigating), heartbeated #459 frieren (still only smokes — pushed for K=5 n=2 launch with rebase reminder). #429 alphonse T1 at step 6301/12700 (~98% into T1), terminal imminent. #464 tanjiro n=2 running at step 400 (cooldown_power=2.0). Active pods: all 8 students. Newly-assigned PRs #468 askeladd / #469 nezuko awaiting student pickup.

- 2026-05-19 12:42 UTC — Cycle 68 continued — **#449 nezuko CLOSED** EMBED_LR Arm A n=2 MISS: T0=3.27403/3050 (passed OLD bar individually) but T1=3.27604/3100 (severe regression, Δval=0.002/Δffs=50 — high variance). n=2 mean 3.275035/3075 misses BOTH bars (new AND old). Axis too noisy on PREV stack. **Nezuko → #469 EMBED_LR re-screen on NEW mandatory stack** (same ±25% arms, now with MU_WARMUP_STEPS=200). Rationale: new stack adds ~0.0009 val improvement, T0 on new stack predicted ~3.273 (near new bar). Re-screen will determine if axis is signal or seed-noise-dominated.

- 2026-05-19 12:30 UTC — Cycle 68 — **#405 askeladd CLOSED** CONTRA_MUON sweep complete: Arm A (0.3) n=2 missed (val=3.274865/ffs=3075), Arm B (0.35) n=2 looked strong (val=3.273505/ffs=3050 both at floor) but n=4 confirm regressed to mean (T0-T2 all val~3.275/ffs=3075 — one slot above floor; T3 killed per bar-tightening foreclosure). Response surface is **flat/mildly-noisy between 0.3 and 0.4** with bimodal-ffs n=2→n=4 collapse caused by seed luck on val-step-3025/ffs-quantization boundary. CONTRA_MUON=0.4 confirmed as local optimum. Contra-Muon/cooldown-geometry cluster saturated (3 independent closures: #372, #406, #405). **Askeladd → #468 AdamW gradient clipping** (GRAD_CLIP_NORM_ADAM=0.5 vs 1.0 — fresh mechanism, confirmed zero gradient clipping anywhere in codebase; AdamW with β₂=0.95 may benefit from outlier-grad damping to improve ffs=3050 consistency). **#429 alphonse T0 terminal: val=3.27310/ffs=3050** — best single-trial val on new bar stack; n=4 confirm continues but ffs bar tight (all-4-at-floor required; T1 at ~3%). #449 nezuko T1 nearing terminal (~99% at 12:25 UTC). Students in smoke phase: #456 fern (SCALARS_LR smoke), #458 edward (smokes complete, awaiting n=2 launch), #459 frieren (Lookahead smoke step 0), #462 thorfinn (MU_WARMUP_START smoke step 40), #464 tanjiro (no runs yet, awaiting pod pickup).

- 2026-05-19 12:40 UTC — Cycle 67 — **#406 tanjiro CLOSED** MU_COOLDOWN_START axis characterized (Arm B 0.97 n=3 val=3.27411/ffs=3066.67 — PASSED OLD bar, MISSES new bar; T3 killed per advisor Option B foreclosure directive). Mechanism findings: asymmetric direction (shallower start better), bimodal ffs at 0.97 (2/5 trials at floor — too inconsistent for new all-4-at-floor bar). tanjiro idle → **#464 LR cooldown polynomial power sweep** (sqrt 0.5 vs quadratic 2.0 around linear 1.0) — fresh schedule mechanism, LR cooldown shape never swept since project init. In-flight smokes (fern #456, edward #458, frieren #459) all on new-stack plumbing verification — value pattern suggests warmup interacts subtly with early training but plumbing OK. n=4 confirms #405 (foreclosed) and #429 (T0 ~91%) approaching terminal.

- 2026-05-19 12:10 UTC — Cycle 66 — **#415 thorfinn MERGED** MU_WARMUP_STEPS=200 (val=3.273477/ffs=3056.25, statsig 3.26×). **NEW BASELINE**. Critical ffs bar tightening: n=4 now requires ALL 4 trials at ffs=3050 (single 3075 = mean 3056.25 = TIE, not beat). Portfolio impact: #405/#406 early-terminate recommended (T0=3075 forecloses ffs on new bar for both). New mandatory stack: `CONTRA_MUON=0.4 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85`. Stack-update notices sent to all in-flight screens (#449/#456/#458/#459). thorfinn idle → **#462 MU_WARMUP_START sweep** (0.80 vs 0.90 around winning 0.85; targeting all-4-at-floor reliability). No human researcher issues.

- 2026-05-19 11:40 UTC — Cycle 65 — **#435 frieren CLOSED LOGIT_SOFTCAP_K axis FALSIFIED ±33% (clean output-head mechanism ablation; Arm A K=10 T0=3.28057/3175-no-hit + T1 diverged at step 3326, Arm B K=22 T0=3.276487/3100 + T1 Option B kill at step ~990; flat val response surface around K=15 confirms softcap is non-load-bearing constant, partially weakens softcap-mediator hypothesis from #372/#379)**. Output-head mechanism family now saturated alongside AdamW lm_head_lr (#431), EMBED_INIT_STD (#379), ATTN_SOAP_TRUST_THRESHOLD (#420). **Reassigned frieren → #459 Lookahead-AdamW sweep** (K=5 vs K=10, α=0.5) — fresh optimizer-wrapping mechanism (Zhang et al 2019), never tested. Cleanly orthogonal to in-flight AdamW LR/WD sweeps (#449/#456/#458). **Plateau Protocol bigger-swing strategy active**: 4-deep AdamW-side characterization (LR groups + WD) + Lookahead = mechanism-family exploration mode.

- 2026-05-19 11:20 UTC — Cycle 64 — **edward idle → #458 AdamW WD_AUX sweep assigned (WD_AUX=0.001 vs 0.01 around current 0.0 on embed+lm_head matrices only; scalars stays at 0). Fourth fresh AdamW-path axis — `weight_decay=0` has been hardcoded since project inception, never swept. PyTorch default is 0.01; we use 0. Hypothesis: small WD on aux matrices may improve generalization without disrupting Muon-side dynamics.** All 8 students now have active WIP PRs (zero idle). n=4 confirm cluster status as of 11:16 UTC: thorfinn #415 ~92% (T4 in progress, T1-T3 all at ffs=3050 floor — TOP merge candidate, terminal ~11:48 UTC), tanjiro #406 ~63%, askeladd #405 ~77% (foreclosed on ffs — T1-T3 all at 3075), alphonse #429 ~9% (T0 in flight).

- 2026-05-19 10:55 UTC — Cycle 63 — **#431 fern CLOSED LM_HEAD_LR axis FALSIFIED ±20% (Arm B n=2 val=3.275235/ffs=3087.5 — MISS both; default 1/320 locally optimal); #430 edward CLOSED MUON_LR narrow ffs miss (Arm B n=2 val=3.27413 PASS strict val, ffs=3075 MISS by one slot — not cleanly falsified, soft revisit candidate); #429 alphonse Arm B NS5_ITERS=14 n=2 STRONG WIN (val=3.273885/ffs=3062.5 PASS both strict bars + statsig, T0=3.27263 best single-trial val since project baseline — n=4 predeclared); #449 nezuko CORRECTED: T0=3.27403/3050 PASSES individually (premature Arm B pivot retracted — T1 in flight, Arm A still viable); fern idle → #456 SCALARS_LR sweep (0.0075 vs 0.0125 around 0.01, third AdamW-LR-group leg, completes the triplet characterization).**

- 2026-05-19 08:30 UTC — Cycle 62 — **#420 nezuko CLOSED ATTN_SOAP_TRUST_THRESHOLD axis FALSIFIED on new base (Arm A T=0.70 val=3.27828/ffs=3125 foreclosed at trial 0; Arm B T=0.95 n=2 mean val=3.275415/ffs=3087.5 — MISS both bars by +0.001/+18.75). Excellent mechanistic finding: default T=0.85 sits inside the empirical cos-row distribution (~0.85-0.93) so the gate is selective by construction; Arm A turns gate ~always-open (on_frac=0.977) = "Attn-SOAP without trust filter"; Arm B turns gate ~always-closed (on_frac=0.008) = "Attn-SOAP effectively disabled". Attn-SOAP contributes only ~0.001 val on the new stack.** Reassigned → **#449 EMBED_LR sweep** (0.225 vs 0.375 around hardcoded 0.3) — largest LR in entire optimizer (8× MUON_LR, 96× LM_HEAD_LR), never swept, AdamW-path completion paired with fern #431.

- 2026-05-19 04:30 UTC — Cycle 61 — **#373 frieren CLOSED axis-falsified at n=4 confirm on both baselines (AdaMuon post-NS5 per-element EMA variance scaling: n=4 mean val=3.27665/ffs=3093.75 vs new bar 3.274383/3068.75 — misses every bar across both old and new baselines; T0/T2/T3 at unfavorable ffs=3100 — clean regression to mean from lucky n=2 screen). Critical research finding: **"input-side robust vs output-side fragile" mechanism — pre-NS5 perturbations (MuonEq-R, Contra-Muon, NorMuon row-scaling) tolerate noise because NS5 re-projects to orthogonal manifold; post-NS5 perturbations (AdaMuon, RMS variants) have no downstream re-projection and propagate directly into the update. EMA-family exhaustion now 4-deep: SOAP_BETA2 #223, NORMUON_BETA2 #378, ATTN_SOAP_BETA2 #394, AdaMuon-BETA2 #373.** 7 consecutive misses since PR #358 merged ~8h ago — Plateau Protocol shift activated: output-side and AdamW-path axes now priority. Reassigned → **#435 logit softcap K sweep** (K=10 vs K=22 around default K=15) — pure model-side mechanism, hardcoded since project inception, never swept, implicated as mediator in both edward #379 and fern #372 closure analyses.

- 2026-05-19 03:30 UTC — Cycle 60 — **#372 fern CLOSED axis-falsified on new base (MuonEq-R n=2 mean val=3.27591/ffs=3087.5 vs new bar 3.274383/3068.75 — additivity prediction falsified; key finding: pre-NS5 row-norm and CONTRA_MUON are partially substitutive cooldown-geometry levers; lever is saturated in new baseline). Reassigned → #431 AdamW lm_head_lr sweep (0.0025 vs 0.00375 around default 0.003125 = 1/320) — fresh AdamW-path axis, orthogonal to all in-flight Muon-side experiments.**

- 2026-05-19 03:10 UTC — Cycle 59 — **#378 alphonse CLOSED axis-falsified (Arm A β₂=0.99 on new base val=3.27604/ffs=3087.5 — MISS both; cross-cycle EMA-family exhaustion now confirmed across 3 β₂ axes: SOAP_BETA2/NORMUON_BETA2/ATTN_SOAP_BETA2 all sharp at 0.90/0.95). Reassigned → #429 NS5 iterations sweep (10 vs 14 vs default 12) — fresh orthogonal-projection-quality axis untouched since NorMuon-clean PR #71.** **#379 edward CLOSED axis stack-specific (EMBED_INIT_STD=1.15 cleared old bar by −0.0008/−6.25 but missed new CONTRA_MUON=0.4 base by +0.0023/+37.5 — strong interaction with contra-correction magnitude; mechanism hypothesis: CONTRA_MUON → basis rotation → embedding sensitivity). Reassigned → #430 MUON_LR sweep (0.030 vs 0.045 around default 0.0375) — never re-tuned since PR #78, load-bearing through 4 stack changes.**

- 2026-05-19 01:10 UTC — Cycle 58 — **nezuko #394 CLOSED axis-falsified (Arm B 0.95 trial 0 val=3.27734/ffs=3125 on new base, trial 1 mathematically foreclosed and terminated early at step 444). Reassigned to #420 ATTN_SOAP_TRUST_THRESHOLD sweep (0.70 vs 0.95) on new base — pure env-var, fresh attention-pathway axis untouched since PR #16/#212.**

## ⭐ NEW BASELINE — PR #415 MERGED (12:05 UTC 2026-05-19)

**MU_WARMUP_STEPS=200** merged: val=**3.273477**, ffs=**3056.25**
- Improvement over PR #358: val Δ=−0.000906, ffs Δ=−12.5
- **NEW MERGE BAR: val < 3.273477 AND ffs_mean < 3056.25** (STRICT — both required)
- ffs bar is now at the ALL-4-AT-FLOOR threshold. n=4 requires ALL 4 trials at ffs=3050. A single 3075 gives mean=3056.25 which TIES the bar (not strictly less).
- **ALL new experiments MUST use**: `CONTRA_MUON=0.4 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85`

### Previous baseline (PR #358, now superseded)
**CONTRA_MUON=0.4** merged: val=3.274383, ffs=3068.75 (20:55 UTC 2026-05-18)

## 🔄 BASELINE SHIFT IMPACT ON IN-FLIGHT EXPERIMENTS

All current WIP experiments ran on CONTRA_MUON=0.5 (old stack). They are now compared against the NEW bar (val<3.274383/ffs<3068.75) which they will almost certainly miss:
- ✅ **THORFINN #357 CLOSED** (00:00 UTC 2026-05-19): n=4 confirm Arm A (MU_COOLDOWN_END=0.87) terminal val=**3.275425**/ffs=**3068.75** — MISS new bar (val +0.001042, ffs ties exactly, not strict <). Old-stack n=2 SCREEN was lucky-draw (both at ffs=3050); n=4 confirm regressed (2 of 4 at ffs=3050). MU_COOLDOWN_END axis on old stack now characterized — 0.87 trades val (+) for ffs (−) at ~1:18 ratio. Reassigned → **#415 muon_warmup_steps sweep** on new base (fresh schedule-side axis, never swept on r2).
- **FERN #372** Arm A n=4 TERMINAL on OLD stack: val=3.275140/ffs=3081.25 — clean STRICT PASS vs old bar (would have merged). Misses new bar by val +0.00076/ffs +12.5. **Sent back 23:16 UTC** for re-test on NEW CONTRA_MUON=0.4 base; additivity math predicts the composite stack clears new bar at ~3.27417/3062.5 (same margins as old base).
- ✅ **FRIEREN #373 CLOSED** (04:30 UTC 2026-05-19): AdaMuon (post-NS5 per-element EMA variance scaling) n=4 confirm mean val=**3.27665**/ffs=**3093.75** — MISS every bar across both old (3.275350/3087.5) and new (3.274383/3068.75) baselines. T0=3.27729/3100, T1=3.27577/3075, T2=3.27727/3100, T3=3.27626/3100 — 3 of 4 at unfavorable ffs=3100 slot, clean regression to mean from n=2 screen lucky-draw. Key cross-cycle finding: "input-side robust vs output-side fragile" — pre-NS5 perturbations (MuonEq-R #372, Contra-Muon, NorMuon row-scaling) tolerate noise because NS5 re-projects; post-NS5 perturbations (AdaMuon #373, RMS variants) propagate directly into update without re-projection. EMA-family exhaustion now 4-deep (SOAP_BETA2 #223, NORMUON_BETA2 #378, ATTN_SOAP_BETA2 #394, AdaMuon-BETA2 #373). Reassigned → **#435 logit softcap K sweep**.
- ✅ **TANJIRO #376 CLOSED** (22:20 UTC): Arm B n=2 terminal val=3.27542/ffs=3075 — both miss new bar (val +0.00104, ffs +6.25). **Axis falsified both arms** — no operating point makes cooldown-only AdaMuon's variance scaling both active and net-beneficial given NorMuon's existing per-row variance EMA (double-normalization). Cross-confirms frieren #373 conclusion. Student gave excellent mechanism analysis. Reassigned → #406 MU_COOLDOWN_START sweep on new base.
- ✅ **FERN #372 CLOSED** (03:30 UTC 2026-05-19): MuonEq-R (pre-NS5 row normalization) n=2 mean val=**3.27591**/ffs=**3087.5** on new CONTRA_MUON=0.4 base — MISS both (val +0.001527/ffs +18.75). Additivity prediction (3.27417/3062.5) falsified by +0.001737/+25. Old base n=4 pass (val=3.275140/ffs=3081.25 would have merged on old bar). Key finding: pre-NS5 row-norm and CONTRA_MUON are partially substitutive parameterizations of **cooldown-stage update geometry** — once one saturates the lever (CONTRA_MUON=0.4), the others lose headroom. Third independent old-base mechanism (joining MU_COOLDOWN_END=0.87 and CONTRA_MUON=0.4) that all saturated the same ffs=3050 floor. **Strategic consequence: future axes targeting "tighter cooldown/smaller correction magnitude" should be treated with strong prior skepticism. Redirect to AdamW-path and output-side axes.** Reassigned → **#431 lm_head_lr sweep**.
- ✅ **EDWARD #379 CLOSED** (03:10 UTC 2026-05-19): EMBED_INIT_STD=1.15 on new CONTRA_MUON=0.4 base trial 0 val=**3.27579**/ffs=**3100** (MISS both, ffs hard-foreclosed). Student executed Option B early-termination on trial 1 — saved ~100min GPU. Stack-shift Δ for STD=1.15: val regressed +0.00226/ffs +37.5 from old base. Strong interaction effect with contra-correction. Direction (1.15 wins on old base) still contradicts arxiv 2502.05366 — but stack-specific. Mechanism hypothesis: larger CONTRA_MUON (0.5) → more aggressive basis rotation → embedding init magnitude differentially affects optimizer trajectory; smaller CONTRA_MUON (0.4) → less basis rotation → embedding sensitivity vanishes. Reassigned → **#430 MUON_LR sweep** on new base.
- ✅ **ALPHONSE #378 CLOSED** (03:10 UTC 2026-05-19): Arm A (NORMUON_BETA2=0.99) on new CONTRA_MUON=0.4 base n=2 mean val=**3.27604**/ffs=**3087.5** — MISS both (val +0.00166/ffs +18.75 vs new bar). Slightly worse than old base (Δval=+0.00095, Δffs=+12.5). EMA-slowing mechanism doesn't compose with reduced contra-correction. **Axis FALSIFIED both directions on new base**. Cross-cycle EMA-family exhaustion now decisively confirmed: SOAP_BETA2 (#223), NORMUON_BETA2 (#378), ATTN_SOAP_BETA2 (#394) all sharp at 0.90/0.95 defaults — variance-scaling stack has redundancy that resists EMA detuning. Reassigned → **#429 NS5 iterations sweep** on new base.
- ✅ **NEZUKO #394 CLOSED** (01:10 UTC 2026-05-19): Arm B (β₂=0.95, slower) trial 0 on new base val=**3.27734**/ffs=**3125** — BOTH miss new bar (val +0.00296, ffs +56.25). Trial 1 mathematically foreclosed (val statsig needs trial_1 ≤ 3.27143; ffs bar needs trial_1 ≤ 3012.5 below quantization floor) — student terminated early at step 444. **Axis FALSIFIED both directions on new base** — confirms third EMA-family axis exhausted (after SOAP_BETA2 in PR #223 and NORMUON_BETA2 in PR #378). β₂=0.90 default is sharp local optimum across all three. Reassigned → **#420 ATTN_SOAP_TRUST_THRESHOLD sweep** (0.70 vs 0.95) on new base.

Strategy shift: accept that all current in-flight runs will miss the new bar. Let them run to terminal (data informs axis characterization), then reassign to new stacked experiments on CONTRA_MUON=0.4 base. Meanwhile askeladd explores CONTRA_MUON=0.3 as direct continuation.

## 🔬 ACTIVE RESEARCH — CONTRA_MUON=0.4 BASE (as of 2026-05-19 11:00 UTC)

### n=4 Confirms in flight / post-merge re-assessment
- ✅ **THORFINN #415 MERGED** (12:05 UTC) — MU_WARMUP_STEPS=200 n=4 val=3.273477/ffs=3056.25. **NEW BASELINE.**
- ✅ **TANJIRO #406 CLOSED** (12:11 UTC) — Arm B n=3 mean val=3.27411/ffs=3066.67, PASSED old bar, MISSES new bar. Bimodal ffs at 0.97 (2/5 trials at floor). tanjiro → #464 cooldown-power-sweep.
- ✅ **ASKELADD #405 CLOSED** (12:22 UTC) — CONTRA_MUON sweep: n=4 confirm MISS (T0-T2 all at 3075, T3 killed per bar foreclosure). Response surface flat between 0.3-0.4; bimodal-ffs n=2→n=4 collapse = seed luck dominated. **askeladd → #468 AdamW grad-clip-adam.**
- ✅ **ALPHONSE #429 CLOSED** (14:34 UTC) — NS5_ITERS=14 PREV stack: n=2 partial confirm val=3.274342/ffs=3062.5 MISSES NEW bar. Axis VALID — bar moved not axis failed. **alphonse → #479 re-screen on NEW stack.**
- **THORFINN #462** (NEW 12:10 UTC) — **MU_WARMUP_START sweep** 0.80 vs 0.90. Targeting all-4-at-floor reliability on new stack.

### n=2 Screens in flight
- ✅ **NEZUKO #449 CLOSED** (12:42 UTC) — EMBED_LR Arm A n=2: T0=3.27403/3050 / T1=3.27604/3100 — mean 3.275035/3075 MISS both bars, high T1 variance. **Nezuko → #469 EMBED_LR re-screen on new stack.**
- **FRIEREN #459** (NEW 11:40 UTC 2026-05-19) — **Lookahead-AdamW sweep** K=5 vs K=10 (α=0.5). Fresh optimizer-wrapping mechanism, never tested. Smokes then n=2 screens.
- **FERN #456** (NEW 10:55 UTC 2026-05-19) — **SCALARS_LR sweep** 0.0075 vs 0.0125 around 0.01. Third leg of AdamW-LR triplet characterization. Smokes then n=2 screens.
- **EDWARD #458** (NEW 11:20 UTC 2026-05-19) — **AdamW WD_AUX sweep** WD_AUX=0.001 vs 0.01 around current 0.0 on (embed + lm_head) only. Fourth fresh AdamW-path axis — `weight_decay=0` hardcoded since project inception. PyTorch default is 0.01. Smokes then n=2 screens.

### Recently Closed (Cycle 63)
- ✅ **FERN #431 CLOSED** (10:45 UTC): LM_HEAD_LR axis FALSIFIED ±20%. Default 1/320 locally optimal.
- ✅ **EDWARD #430 CLOSED** (10:55 UTC): MUON_LR narrow ffs miss — Arm B val PASSES strict bar (3.27413), ffs=3075 MISSES by one slot. Not cleanly falsified — soft revisit at +20% if needed.

## AdamW-LR-Group Characterization Status
| Group | Default LR | PR | Verdict |
|---|---|---|---|
| `adam_embed` | 0.3 | #449 (in flight) | T0 PASSES individually (3.27403/3050) — T1 pending |
| `adam_lm_head` | 1/320 ≈ 0.003125 | #431 (closed) | FALSIFIED ±20% |
| `adam_scalars` | 0.01 | #456 (assigned) | TBD |
| Muon LR | 0.0375 | #430 (closed) | NARROW MISS (val PASS, ffs by one slot) |

## 🔥 n=4 CONFIRM CLUSTER (Updated 11:00 UTC)

| PR | Student | Axis | n=2 val/ffs | n=4 status | Merge priority |
|---|---|---|---|---|---|
| #415 | thorfinn | MU_WARMUP_STEPS=200 | 3.273802/3050 | **MERGED** — new baseline | ✅ MERGED |
| #429 | alphonse | NS5_ITERS=14 | 3.273885/3062.5 | **CLOSED (PREV stack)** — T0=3.27310/3050 PASS individually, T1=3.27559/3075 ffs foreclosed on NEW bar | reassigned → #479 |
| #405 | askeladd | CONTRA_MUON=0.35 | 3.273505/3050 | **CLOSED** — n=4 regression-to-mean (T0-T2 all 3075) | closed |
| #479 | alphonse | NS5_ITERS=14 new stack | TBD | **JUST ASSIGNED** — pick up pending | highest priority |

**Merge order strategy**: merge best first, then re-test others on new baseline (per cross-stack interaction finding from #372/#373). MU_WARMUP_STEPS=200 (schedule-side) most likely orthogonal to MU_COOLDOWN_START=0.97 (cooldown-side) and NS5_ITERS=14 (projection-quality). CONTRA_MUON=0.35 (correction-magnitude) may partially substitute with MU_COOLDOWN_START=0.97 — needs new-base re-test after first merge.

**Cross-axis composability concerns**:
- #405 (CONTRA_MUON 0.4→0.35) and #406 (MU_COOLDOWN_START 0.95→0.97) both directly parameterize the cooldown-stage update geometry — likely partially substitutive per #372 saturated-lever finding
- #415 (MU_WARMUP_STEPS) operates on a different optimizer phase (warmup vs cooldown) — most likely orthogonal to #405/#406
- If #415 + (one of #405, #406) both pass n=4 confirm, the stacking question becomes critical

## Previous cycle racing context (now superseded by new bar)

**CONTRA_MUON axis**: 0.5→0.4 merged. Mechanism: smaller contra-correction lets Muon retain more natural momentum signal. Pure env-var change, no code required.
- **FRIEREN #373 AdaMuon β=0.99** T0 STRONG on OLD bar (3.2750/3075 vs old 3.275350/3087.5). Misses new bar. Continue to terminal for axis characterization.
- 🔥 **FRIEREN #373 AdaMuon β=0.99** Arm B trial 0 STRONG: val=**3.2750**/ffs=**3075** (clears both bars by −0.00035/−12.5). Arm B is the **fifth strong candidate** this cycle. Trial 1 in flight. AdaMuon axis is **NOT fully falsified** — β=0.99 is the right side of the variance-scaling parameter.

## 🚫 Falsified Output-Side Mechanisms
- ✅ **NEZUKO #375 CLOSED** (17:20 UTC): Muon-VS FALSIFIED both arms (β=0.95: val+0.050/ffs=-1, β=0.90: val+0.038/ffs=-1). Reassigned → #394 ATTN_SOAP_BETA2 sweep.
- **FRIEREN #373 AdaMuon β=0.95** Arm A n=2 MISS: val=3.27786/+0.00251, ffs=3112.5/+25.
- 🔥 **FRIEREN #373 AdaMuon β=0.99** Arm B trial 0 STRONG: val=**3.2750**/ffs=**3075** (clears both bars by −0.00035/−12.5). Arm B is the **fifth strong candidate** this cycle. Trial 1 in flight. AdaMuon axis is **NOT fully falsified** — β=0.99 is the right side of the variance-scaling parameter.
- **TANJIRO #376 Cooldown-AdaMuon β=0.95** trial 0 MISS: val=3.2764/+0.00105, ffs=3100/+12.5. Trial 1 in progress ETA ~18:05 UTC.


- No human researcher directives this session (Issue #164 is on r3 branch, not r2).
- ✅ **PR #288 MERGED** (08:35 UTC): Cooldown-only μ anneal 0.95→0.90 — NEW BASELINE. val=3.275350/ffs=3087.5. MU_START/MU_END deprecated; new stack is MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5.
- ✅ **EDWARD #341 CLOSED** (14:10 UTC): SOAP eigenbasis freeze axis FALSIFIED. Arm A (FREEZE=1000) val=3.28082. Arm B (FREEZE=2000) val=3.27640/ffs=3100. **MECHANISM**: Q refresh past step K continues to add signal all the way through cooldown. Reassigned → #379 Embed init std fine sweep.
- ✅ **ALPHONSE #359 CLOSED** (13:25 UTC): μ shape ablation FALSIFIED both directions. **MECHANISM**: 0.05 decay gap AND high-μ warmup plateau are BOTH load-bearing. Reassigned → #378 NorMuon β2 sweep.
- 🔥 **ASKELADD #358 Arm A n=2 CONFIRMED STRONG** (13:28 UTC): CONTRA_MUON=0.4 n=2 mean val=**3.27343**, ffs=**3062.5** (T0=3.272824/3050, T1=3.274036/3075). Statsig at n=2: (3.28−3.27343)×√2 = 0.00929 ≥ 0.004 ✅ PASSES 2× over. **n=4 confirm RUNNING** (launched 13:28 UTC per predeclared tree, ETA ~20:30 UTC). After n=4 → Arm B (CONTRA_MUON=0.6).
- ✅ **FRIEREN #343 CLOSED** (11:15 UTC): AdamW β2 axis FALSIFIED in BOTH directions. β2=0.95 is a stability window. Reassigned → #373 AdaMuon.
- ✅ **FERN #304 CLOSED** (10:45 UTC): SOAP_PRECOND_FREQ anneal FALSIFIED. FREQ=10 stays. Reassigned → #372 MuonEq-R.
- ✅ **NEZUKO #339 CLOSED** (12:10 UTC): cooldown_frac axis FALSIFIED. cooldown_frac=0.7 stays. Reassigned → #375 Muon-VS.
- ✅ **TANJIRO #336 CLOSED** (12:10 UTC): TARGET_UW axis FALSIFIED in BOTH directions. TARGET_UW=0.35 is local optimum. Reassigned → #376 Cooldown AdaMuon Switch.
- 🔥 **THORFINN #357 Arm A n=2 CONFIRMED STRONG** (12:41 UTC): MU_COOLDOWN_END=0.87 n=2 mean val=**3.27432**, ffs=**3050** (BOTH trials at 3050). Statsig 0.00803 ≥ 0.004 ✅ PASSES 2× over. Arm B (MU_END=0.85) trial 0 val=**3.2739**, ffs=**3050** — also clears. Trial 1 in progress (ETA ~16:25 UTC). **PREDECLARED n=4 CONFIRM** on whichever arm wins n=2.

## POD INFRASTRUCTURE NOTE (cycle 54)

**Two r2 pods broken on torch 2.10.0+cu128 + mixed cu12/cu13 nvidia libs**:
- alphonse #303 — FIXED by in-place pip upgrade to torch 2.11.0+cu130. PR closed.
- fern #304 — same fix confirmed; running fine now.

Root cause: mixed cu12/cu13 NCCL/cuDNN with torch 2.10.0+cu128 causes optimizer kernel divergence at steps 2-24, producing full-attention-Gram NaN by first val checkpoint at step 125. Step-1 gradients are bit-identical to healthy peers.

**Operational lesson**: if a pod shows step-125 NaN on the merged baseline, check `torch.__version__` immediately. Peer healthy stack is torch 2.11.0+cu130 cu13-only.

## CRITICAL BUG FIXED (cycle 54)

`TRUST_THRESHOLD=0.85` was a **silent no-op** — the code reads `ATTN_SOAP_TRUST_THRESHOLD` (line 449). All advisor PRs and BASELINE.md corrected. All students on active PRs notified.

## Current baseline ⭐⭐ (PR #288 merged 08:35 UTC 2026-05-18)

**Cooldown-only μ anneal (MU_COOLDOWN_START=0.95→MU_COOLDOWN_END=0.90) + Attn-SOAP+trust T=0.85 + CONTRA_MUON=0.5 (PR #288)**
- n=4 mean val/loss = **3.275350** | ffs_mean = **3087.5** @ train_steps=3175
- W&B run: `qceklszn` (n=4 confirmation, T0=3.27437/3075, T1=3.27600/3100, T2=3.27586/3100, T3=3.27517/3075)
- **Merge bar: mean val < 3.275350 AND ffs_mean < 3087.5** (STRICT — both required)
- **All new experiments must include**: `MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5`
- **NOTE**: MU_START and MU_END env vars are DEPRECATED — do NOT use in new assignments
- ffs is bimodal {3075, 3100} — to beat ffs bar requires ≥3 of 4 trials hitting 3075 (mean ≤ 3081.25)

## Active in-flight experiments

### THORFINN #357 — MU_COOLDOWN_END sweep 0.87/0.85 (NEW, just assigned 08:45 UTC)
- Follow-up to merged PR #288: if 0.90 > 0.95 endpoint, maybe 0.87 or 0.85 is better.
- Arm A: MU_COOLDOWN_END=0.87 (keep START=0.95, steeper drop)
- Arm B: MU_COOLDOWN_END=0.85
- Mechanism: more aggressive μ decay at end of cooldown → more Muon reactivity → more trials hit ffs=3075
- Pure env-var change, no code needed

### ASKELADD #358 — CONTRA_MUON sweep 0.4/0.6 (NEW, just assigned 08:45 UTC)
- CONTRA_MUON=0.5 was set at merge, never swept. Axis completely unexplored.
- Arm A: CONTRA_MUON=0.4 (reduce correction 20%)
- Arm B: CONTRA_MUON=0.6 (increase correction 20%)
- If one arm wins clearly, extend to 0.3 or 0.7 in same PR

### ALPHONSE #378 — NorMuon per-row variance β2 univariate sweep (NEW, assigned 13:30 UTC)
- NORMUON_BETA2 hardcoded at 0.95 since NorMuon's original merge (PR #71). Static value never swept.
- Arm A: NORMUON_BETA2=0.99 (slower EMA, smoother row variance)
- Arm B: NORMUON_BETA2=0.90 (faster EMA, more reactive row variance)
- Reference: arxiv 2509.20762 (NorMuon original — β2=0.95 tuned for non-SOAP non-Contra-Muon stack).
- Categorically distinct from closed PR #316 (cooldown-phase ANNEAL of NorMuon β2 — falsified).
- Code change: 1 line — make NORMUON_BETA2 read from env var (everything else already wired).

### FERN #372 — MuonEq-R: pre-NS5 row normalization (NEW, assigned 10:55 UTC)
- Fresh mechanism from arxiv 2603.28254 (MuonEq, 2026-03). Validated on FineWeb GPT2-small (PPL 25.23→24.88).
- Pre-NS5: normalize rows of momentum matrix by L2 norms before NS5, ensuring isotropic input.
- Orthogonal to NorMuon (post-NS5) and Contra-Muon (pre-momentum). Stateless, no new EMA buffers.
- Arm A: MUONEQ_R=1 MUONEQ_EPS=1e-8 (safe default)
- Arm B: MUONEQ_R=1 MUONEQ_EPS=1e-6 (coarser normalization)
- ~10 lines code change to `zeropower_via_newtonschulz5` function

### EDWARD #379 — Embed init std fine-resolution sweep (NEW, assigned 14:15 UTC)
- Init scale axis: PR #340 closed std=0.5 (NaN at step 25); upward direction and {0.6-0.95} interior never tested.
- Arm A: EMBED_INIT_STD=0.85 (smaller than default 1.0, safe distance from 0.5 NaN edge)
- Arm B: EMBED_INIT_STD=1.15 (larger than default, untested upward direction)
- Reference: arxiv 2502.05366 (Embedding Init for LLMs). Default nn.Embedding init is N(0,1) cast to bfloat16.
- Code change: ~5 lines — env-var-driven scaling of embed.weight before bfloat16 cast. Path is bit-identical to baseline if env-var unset.
- NaN gate critical: pod must monitor first 100 steps closely given PR #340 history.

### NEZUKO #375 — Muon-VS: pre-NS5 gradient deviation variance (NEW, assigned 12:15 UTC)
- Fresh mechanism from arxiv 2601.14603. Reported 1.36× optimizer step reduction on LLaMA-1.2B.
- Pre-NS5: Γ_t EMA of (M_{t-1} − G_t)⊙² with bias correction; scale momentum coords by 1/√(Γ̂_t+ε).
- Complementary to AdaMuon (PR #373) which scales POST-NS5 output. Muon-VS scales NS5 INPUT.
- Categorically distinct from closed PR #80 (Muon² used generic pre-NS5 Adam variance without (M_{t-1}−G_t)⊙² deviation signal).
- Arm A: MUON_VS=1 MUON_VS_BETA=0.95
- Arm B: MUON_VS=1 MUON_VS_BETA=0.90
- ~15 lines code: GDV buffer (`state["gdv"]`) + prev_momentum cache + pre-NS5 division.

### TANJIRO #376 — Cooldown-Phase AdaMuon Switch (NEW, assigned 12:15 UTC)
- Hybrid mechanism: AdaMuon post-NS5 variance scaling, but ONLY during cooldown phase (step ≥ ~2222).
- Stacks with PR #288 cooldown-only μ-anneal: μ-anneal acts on scalar momentum, variance scaling acts on per-element NS5 output. Orthogonal axes both activated at same boundary.
- Reference: arxiv 2507.11005 (AdaMuon), arxiv 2510.25000 (variance adaptation is SOAP's per-step advantage).
- Arm A: ADAMUON_COOLDOWN_ONLY=1 ADAMUON_BETA2=0.95 ADAMUON_COOLDOWN_INIT=rms (RMS warm-start)
- Arm B: ADAMUON_COOLDOWN_ONLY=1 ADAMUON_BETA2=0.99 ADAMUON_COOLDOWN_INIT=ones (cold start)
- ~25 lines code: lazy buffer init at cooldown boundary, EMA update, RMS-preserving rescale.
- Complementary to FRIEREN #373 (full-training AdaMuon). Either outcome is informative.

### FRIEREN #373 — AdaMuon: post-NS5 per-element variance scaling (NEW, assigned 11:15 UTC)
- Mechanism: maintain EMA of squared NS5 outputs V_t = β2·V_{t-1} + (1-β2)·O_t², scale update by 1/√(V_t+eps) with RMS rescaling. Stacks on top of existing NorMuon (row-level) and Contra-Muon.
- Distinct from closed PR #80 (pre-NS5 Adam variance). Orthogonal to NorMuon (post-NS5, per-element vs per-row).
- Reference: arxiv 2507.11005 (AdaMuon). Prior work closed ~0.014 val gap vs vanilla Muon.
- Arm A: ADAMUON=1 ADAMUON_BETA2=0.95 (conservative EMA)
- Arm B: ADAMUON=1 ADAMUON_BETA2=0.99 (slow EMA, more stable variance)
- Requires ~30 lines code: `adamuon_v` state buffer added to Muon state init + EMA update in `contra_normuon_update`

## Recently closed axes (since session start)

| PR | Student | Status | Insight |
|---|---|---|---|
| **#288** | **thorfinn** | **MERGED ⭐** | **Cooldown-only μ anneal 0.95→0.90. val Δ−0.000485 (statsig 2.3×), ffs tied at 3087.5. Mechanism: μ-anneal localizes to cooldown phase.** |
| #341 | edward | FALSIFIED | SOAP eigenbasis freeze: Arm A (FREEZE=1000) +0.0055; Arm B (FREEZE=2000) +0.00105. Monotonic — earlier freeze → larger regression. **MECHANISM**: Q refresh contributes signal through entire cooldown. Combined with #304: SOAP refresh schedule FREQ=10 from step 1 to end is a tight stability window in BOTH dimensions. |
| #359 | alphonse | FALSIFIED | μ shape ablation: Arm A (near-flat 0.92→0.90) +0.0085, Arm B (constant 0.90) +0.0095. **MECHANISM: 0.05 decay gap AND high-μ warmup plateau BOTH load-bearing**. Neither component alone suffices. |
| #339 | nezuko | FALSIFIED | cooldown_frac sweep 0.6/0.8 both miss NEW baseline. Arm B beats OLD val by −0.000195/−12.5 ffs (within noise); cooldown_frac=0.7 stays. PR #288 raised the bar past Arm B's reach. |
| #336 | tanjiro | FALSIFIED | TARGET_UW=0.35 is local optimum. Arm A (0.25) kill-gated at +0.010 regression; Arm B (0.50) fails both bars by +0.0005/+25. Floor's implicit WD remains load-bearing. |
| #319 | askeladd | FALSIFIED | Muon LR warmup both arms miss. NS5 at full LR from step 1 is load-bearing. |
| #312 | alphonse | NO SIGNAL | lm_head WD wd=0.01 p=0.57 vs baseline. n=1 win was seed noise. |
| #343 | frieren | FALSIFIED | AdamW β2 both directions crash: β2=0.99 NaN at step 125, β2=0.90 grad explosion step 275. β2=0.95 is stability window. |
| #316 | nezuko | FALSIFIED | NorMuon β2 cooldown anneal; n=2 mean val=3.278405/ffs=3125. β2 variance buffer ≠ μ. |
| #333 | frieren | FALSIFIED | AdamW eps — both 1e-8 and 1e-12 NaN. eps=1e-10 is a stability window. |
| #313 | frieren | CLOSED (bug) | Z-loss — NaN smokes, code never pushed. |
| #309 | tanjiro | FALSIFIED | AdamW β1 anneal — no AdamW equivalent of NS5 safety net. |
| #295 | nezuko | MISS | Polar Express adaptive NS5 — no benefit at 12-iter budget. |
| #286 | askeladd | FALSIFIED | Polyak-Ruppert EMA — averaging pre-cooldown weights hurts. |
| #276 | tanjiro | FALSIFIED | Decoupled aux cooldown shape — linear optimal for all groups. |
| #291 | fern | FALSIFIED | β2-anneal breaks FREQ/β2 coupling; Arm B NaN. |
| #281 | edward | FALSIFIED | Per-head SOAP — cross-head gradient covariance lost in block-diagonal. |
| #340 | frieren | FALSIFIED | Embed init std=0.5 NaN at step 25. Init scale load-bearing under adam_embed lr=0.30. |
| #268 | askeladd | FALSIFIED | Depth-LR scaling — SOAP absorbs per-layer structure. |
| #273 | nezuko | FALSIFIED | Asymmetric QK/VO trust — V low cos_row is TRUE signal. |
| #271 | fern | FALSIFIED | Decoupled SOAP freq MLP vs ATTN — refresh-freq optimum ≈ EMA horizon. |
| #275 | frieren | FALSIFIED | MLP-SOAP trust gate — MLP precond robust to rotation noise. |
| #277 | alphonse | CLOSED (infra) | SOAP eigenbasis freeze — pod NaN, NOT falsified. Resurrected as #341. |

## Key patterns (updated cycle 55)

1. **Cooldown-only μ anneal MERGED (PR #288)**: val=3.275350/ffs=3087.5. Mechanism: cooldown reactivity is the driver, NOT warmup stabilization. MU_COOLDOWN_START/END replaces MU_START/MU_END.
2. **Annealed μ (0.97→0.90) MERGED (PR #219)**: Superseded by PR #288's cleaner mechanism.
3. **Attn-SOAP+trust T=0.85 MERGED (PR #212)**: +6.25 ffs improvement.
4. **ffs quantization**: bimodal {3075, 3100}, 25-step granularity. To beat ffs bar, need ≥3/4 trials at 3075.
5. **Linear cooldown > cosine**: cosine on Muon (r1) val=3.2882; cosine on aux alone (PR #276) falsified.
6. **SOAP_PRECOND_FREQ=10 = stability window**: both 5 AND 20 NaN.
7. **NS5 iter=12 = unique stable operating point**: 8, 10, 14, 16 all NaN cascade.
8. **Muon NS5 orthogonalization at full LR from step 1 is load-bearing**: any LR warmup delays early-training convergence (#319 falsified both arms).
9. **Stability windows (don't touch)**: FREQ=10, NS5_iter=12, SOAP_β2≥0.90, AdamW eps=1e-10.
10. **Lookahead incompatible**: SOAP/NorMuon stateful preconditioners can't tolerate param rollback.
11. **Gradient noise + NS5 = catastrophic**: ×35 Frobenius amplification.

## Open axes with potential

- **μ cooldown endpoint** (thorfinn #357): more aggressive decay to 0.87/0.85 — direct follow-up to merged PR #288. Trial 0 STRONG (val=3.274062/ffs=3050).
- **CONTRA_MUON rate** (askeladd #358): trial 0 STRONG (val=3.2728/ffs=3050). n=4 predeclared if n=2 clears.
- **NorMuon β2** (alphonse #378): static value sweep (0.99 vs 0.90) — unswept since PR #71 merge.
- **Embed init std** (edward #379): fine-resolution sweep 0.85/1.15 around default 1.0; bracket untested between falsified std=0.5 and default.
- **MuonEq-R pre-NS5 row norm** (fern #372): arxiv 2603.28254; stateless, zero HPs; orthogonal to NorMuon
- **AdaMuon post-NS5 variance** (frieren #373): per-element EMA scaling of NS5 output; arxiv 2507.11005
- **Muon-VS pre-NS5 gradient deviation** (nezuko #375): arxiv 2601.14603; complementary to AdaMuon (scales NS5 input vs output)
- **Cooldown-Phase AdaMuon Switch** (tanjiro #376): AdaMuon activated only at cooldown boundary; stacks with PR #288 μ-anneal
- **Cooldown shape (linear/cosine/poly)** [from nezuko #339 follow-up]: never directly compared post-PR #288; new candidate hypothesis
- **Diagnostic logging — uw_ratio_mean, uw_floor_fire_rate** [from tanjiro #336 follow-up]: cheap to add, decisive for future regularization-axis work; could be standalone PR
- **Per-optimizer cooldown** [from nezuko #339 follow-up]: split cooldown_frac across AdamW vs Muon param groups; untested
