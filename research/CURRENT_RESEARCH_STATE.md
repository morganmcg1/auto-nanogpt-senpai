# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-22 13:00 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. LOCAL RECORD 2937.5 (PR #413).
- **68 closed axes** (#774 cov-warmup-fast-mix closed 13:00 UTC)
- **3 sub-baseline-marginal signals in n=2 confirmation pipeline:**
  - #737 thorfinn Polyak EMA β=0.99 (sr=2925/val=3.265811; seed-2 `32r3isz5` in flight)
  - #741 alphonse aux β2→0.999 (sr=2950/val=**3.263972** beats baseline mean; seed-1 `nsvxxmvl` in flight)
  - #777 fern body-Muon mu→0.85 (sr=2925/val=3.26880, just terminal; pending Arm B + n=2)

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Active experiments (8 students, 08:30 UTC — 0 idle)

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| **#774** | edward | PMuon cov warmup fast-mix (β_cov=0→0.95 at K=20 vs K=50) | Newly assigned 08:10 UTC. In implementation phase. |
| **#769** | askeladd | Aux AdamW delayed cooldown start (300 vs 600 step delay) | Newly assigned 06:40 UTC. In implementation phase. |
| **#760** | frieren | PMuon γ_power cooldown ramp (0.4→0.5 vs 0.4→0.3) | Arm A `4yzrav20` running step ~1650. ETA ~08:45 UTC. |
| **#741** | alphonse | Aux AdamW β2 cooldown ramp **n=2 confirmation of Arm B** | Sent back 09:15 UTC for n=2. Both arms marginal; **Arm B sr=2950/val=3.263972 (Δval=−0.000306, beats baseline mean)**. n=2 will decide merge vs close. ETA ~7h32min. |
| **#780** | nezuko | Body-Muon u/w trust-region ceiling (0.5 vs 0.4) | Newly assigned 09:25 UTC. Fresh direction (NOT cooldown-coupled). u/w-floor exists (TARGET_UW=0.35); this adds upper bound. Diagnostic: ceiling_fired counts will reveal upper-tail of u/w distribution. Tied mechanistically to #730 directional-travel finding. |
| **#737** | thorfinn | Polyak EMA cooldown-aware β ramp | Arm A **sr=2925 MARGINAL** (val=3.265811 regresses, n=1 AND clause fails). Arm B `b4q13sgm` running step 2825 val=3.292. ETA ~09:10 UTC. **Plan**: if Arm A holds best, request n=2 confirmation of β=0.99 ramp. |
| **#777** | fern | Body-Muon mu cooldown ramp (0.95→0.85 vs 0.95→0.98) | Newly assigned 08:25 UTC. In implementation phase. Smooth-ramp mu lever — never tested. Parallel to #737 (Polyak EMA β ramp, sr=2925 marginal) but operates inside Muon's own momentum buffer. |
| **#778** | tanjiro | PMuon per-type γ narrow asymmetric (γ_attn=0.5/0.45, γ_mlp=0.4 pinned) | Newly assigned 08:45 UTC. Direction validated by #736 wide split → narrow test with mlp pinned at scalar optimum. Either fully closes per-type γ axis or surfaces sub-baseline signal. |

## Recently closed (since session start)

| PR | Axis # | Verdict | Mechanism |
|---|---|---|---|
| **#745** nezuko | 67th | Per-type LR cooldown asymmetry NULL/NULL (A sr=3025 attn0.5, B sr=3050 mlp0.5) | Both arms regress non-marginally (Δsr=+87.5/+112.5, Δval=+0.007/+0.011). CROSSOVER pattern: B led through mid-cooldown, A overtook in final 250 steps — sub-component cooldown sensitivities trade off symmetrically, neither recovers symmetric (1.0,1.0) baseline. Closes per-type LR family (#499 static, #535 sub-MLP, #532 depth, #745 cooldown). |
| **#736** tanjiro | 66th | Per-type γ asymmetry wide split NULL/NULL (A sr=3050 attn0.3, B sr=2975 attn0.5) | Direction validated (B>A by ~0.005 val from step 1250) — γ_attn > γ_mlp helps. Magnitude insufficient: 0.5/0.3 places both endpoints below scalar optimum γ=0.4 (per #519). Wide-split axis closed; narrow attn-only-raised remains open via #778. |
| **#727** fern | 65th | WD cooldown schedule NULL/NULL (A sr=2975, B sr=2975) | Symmetric-NULL: both UP/DOWN regress identically (Δsr=+37.5, Δval ≈+0.003/+0.002). Cross-arm Δval=+0.001 below marginal threshold. WD-temporal-schedule axis EXHAUSTED — WD=0.025 STATIC sits at local optimum. Adds to cooldown-trajectory lever cluster (#647, #607, #717+#690). |
| **#730** edward | 64th | SWA cooldown init NULL/NULL (A sr=3000, B sr=3000) | Body-Muon weights travel directionally (27-37% Frobenius distance per 100-200 steps) — not basin-orbiting. SWA average is lagged anchor, not centroid. Buffer-modification at cooldown_start FULLY CLOSED across all categories (state + parameter space). |
| **#725** askeladd | 63rd | PMuon cov reset NULL/NULL (Arm A sr=2975, Arm B sr=2950) | Covariance buffer (L_cov/R_cov, 72 tensors) also load-bearing. Same non-monotone pattern as #723. Buffer-modification axis at cooldown_start FULLY CLOSED across all PMuon buffer types (momentum + covariance). |
| **#723** frieren | 62nd | Momentum reset NULL/NULL (Arm A sr=2975, Arm B sr=2950) | Body-Muon momentum buffer is load-bearing for cooldown. Non-monotone (0.5× worse than 0.0×) — partial reset creates mismatch worse than either extreme. 3rd confirmed buffer-modification dead lever at cooldown_start. |
| **#698** nezuko | 61st | NAdam-aux NULL/NULL (val=3.268/3.268, sr=3000/3000) | β₁ ∈ [0.8, 0.9] gives statistically-identical terminals (Δ=+0.00018 val). AdamW denominator absorbs Nesterov lookahead — structural absorption, not retuning issue. 10th aux update-rule family NULL → aux saturation pattern confirmed (only schedule machinery moves aux). |
| **#738** alphonse | — | Design error — closed without launch | Student g1r1-alphonse caught math error before launch: codebase uses EMA-form Nesterov (`lerp_`), so Arm B `(1-μ²)g+μ²m_prev` IS baseline. The (a,b) sum=1 convex line on g/m_prev is FULLY CLOSED by #660+#697 (heavy-ball NULL, Nesterov BEST, QHM NULL). Saved 6h GPU time. Memory file updated. |
| **#697** alphonse | 60th | QHM (ν,β) NULL/NULL (val=3.271/3.278, sr=3025/3125) | Super-linear penalty in ν (Δν=0.10 cost +0.00188 → +0.00614, 3× acceleration). QHM blend `ν·g + (1-ν)·m` cannot replicate Nesterov cross-term. 4TH AND STRONGEST cooldown-erosion: -71 mnat mid → +8 mnat terminal (79 mnat swing). Body-Muon momentum spec PINNED across 9 sub-axes. |
| **#695** thorfinn | 59th | Polyak EMA β=0.9/0.95 short-window NULL/NULL | Peak EMA signal and lag shrink together — no static (β, warmup) separates them. Arm B sr=2925 boundary but val>baseline. Full β-scan closure: intrinsic lag/signal coupling in PMuon-EMA. |
| **#696** tanjiro | 58th | Contra-Muon NULL/NULL (val=3.276/3.269, sr=3125/3000) | PMuon whitening compresses slow EMA ~6× in polar space → effective sub 1.5-3% vs design 15-25%. Monotone dose-response in wrong direction. Post-NS perturbation family adds to spectral absorption pattern. |
| **#690** edward | 57th | SGDR NULL/NULL (val=3.306/3.323, sr=-1/-1) | Restart spike +0.13-0.17 unrecoverable in cycle budget. More restarts → worse. 3rd cooldown-erosion instance: mid-cycle advantage eroded at terminal. LR schedule SHAPE closed (non-monotone direction). |
| **#686** fern | 56th | β_cov schedule SYMMETRIC NULL | Arm A (0.90→0.95) and Arm B (0.95→0.98) produce IDENTICAL regression in opposite directions = canonical static-optimum. β_cov axis FULLY CLOSED (scalar + schedule). |
| **#682** askeladd | 55th | mu schedule NULL/inconclusive | Arm A (cooldown ramp) sr=2925 but val=3.26985 regression fails win rule. Arm B (warmup ramp) NULL sr=3050. Body-Muon mu PINNED at static across 4 sub-axes. |
| **#684** frieren | 54th | Langevin noise NULL/NULL | 5× noise difference, identical sr=2975. PMuon polar map already flat — SGLD has no sharp basin to escape. Gradient-domain perturbation family FULLY CLOSED (4 sub-axes). |
| **#667** nezuko | 53rd | Cosine schedule NULL/NULL | Stable plateau REQUIRED; WSD power-1.4 tail beats cosine by +62.5 sr. Schedule family WSD-LOCKED across 7 sub-axes. |
| **#660** alphonse | 52nd | Nesterov ON/OFF NULL | mu=0.95 AND nesterov=True both independently load-bearing. Cross-term coupling (μ²·m_prev + (1-μ²)·g) non-trivial. |
| **#662** thorfinn | 50th | Polyak EMA β=0.99 NULL | Peak −63 mnat mid-cooldown REAL but centroid-lag flips sign as LR→0. Terminal EMA slightly worse than live. |

## KEY MECHANISM: Cooldown-erosion pattern (4 confirmed instances)

Mid-run optimizer-mechanism advantages compress to zero during WSD cooldown:
1. **#690 SGDR** — cycle-1 advantage −0.019 at step 2125 → +0.058 final regression
2. **#697 QHM** — **STRONGEST**: −49 to −71 mnat advantage at steps 1000-1750 → +1.9 to +8.0 mnat penalty terminal (79 mnat mid→terminal swing)
3. **#686 β_cov schedule** — symmetric NULL (opposite directions, same regression)
4. **#695 Polyak EMA** — peak signal at step 2400 → centroid-lag sign flip as LR→0

**Mechanism hypothesis:** WSD cooldown (steps 975-3250, 70% of training) is rate-limiting; optimizer differences compress toward zero as LR → 0. The monotone decay is already near-optimal for final refinement. **Implication:** Better targets are step 975 initialization or cooldown-phase buffer state. Current experiments directly test this:
- **#723 frieren**: momentum reset at step 975 (direct event)
- **#725 askeladd**: covariance reset at step 975 (direct event)
- **#727 fern**: WD ramp during cooldown (continuous modification)
- **#730 edward**: SWA weight reset at step 975 (weight-space centroid)

## Current research focus

**Primary frontier: Cooldown-mechanism interventions.** After 57 closed axes, the WSD schedule itself is pinned and optimizer mid-run differences erode in cooldown. The four running experiments (#723/#725/#727/#730) directly attack the cooldown-start initialization and cooldown-trajectory optimality.

**Secondary frontier: Mechanism completion.** Five near-terminal PRs (#697/#698/#695/#696/#690-closed) complete the QHM/NAdam/Polyak/Contra-Muon axis survey. Expected: all NULL (consistent with cooldown-erosion pattern).

**Portfolio balance:** 4/8 slots on novel cooldown interventions (momentum/cov/WD/SWA reset) + 4/8 on terminal completions. When terminal cluster completes (00:00-01:00 UTC), next batch should diversify toward non-cooldown angles: fresh preconditioners, structural inits, or cross-family mechanism tests.

## Axes still untested (high priority)

- Contra-Muon at designed regime (coeff=1.0 to reach 15-25% subtraction magnitude — #696 Arm A gave only 3% due to PMuon whitening compression). Follow-up pending #696 closure.
- Aux β2 ramp (never tested as schedule; static tested at #433)
- Spectral normalization / Frobenius-normalized NS output
- PSGD / Shampoo as body-Muon replacement
- SWA w/ alpha blend (partial weight replace) — #730 tests full replace; blend arm not included

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Closed axes reference (67 total)

*PMuon scalars COMPLETE (all 5 pinned):* γ_power=0.4, β_cov=0.95 (scalar+schedule CLOSED #686), NS_ITERS=12, NS coeff cubic (1.5,-0.5,0), ε=1e-12, mu=0.95 (schedule CLOSED #682).

*Body-Muon LR partition FULLY CLOSED:* per-type (#499), sub-MLP (#535), depth-based (#532).

*Body-Muon scalars/wrappers:* WD partition (#482), WD schedule (#503), grad clipping (#513), γ_power ramp (#444), lr fine-scan (#465), Lookahead (#505).

*Body-Muon LR schedule shape FULLY CLOSED:* WSD pinned across 7 sub-axes (shorter/longer cf, LR floor, NS_ITERS ramp, decoupled aux, warmup); cosine NULL (#667 53rd); SGDR restarts NULL (#690 57th). All non-monotone and shape-variation directions closed.

*Post-NS body-Muon perturbations CLOSED:* Contra-Muon post-NS subtraction (#696 58th) — bilateral whitening compresses slow EMA ~6× in polar space → designed regime unreachable. Full perturbation axis (pre-NS: winsorization/tanh-squash/per-block-norm/Langevin; post-NS: contra-momentum) CLOSED.

*Body-Muon operator ordering CLOSED:* post-NS momentum (#658 49th), Nesterov (#660 52nd), QHM (ν,β) plane (#697 60th — super-linear penalty in ν, 4th cooldown-erosion instance).

*Body-Muon parameter-space averaging FULLY CLOSED:* Lookahead (#505 NULL), Polyak EMA β=0.999 (LMC failure), β=0.99 centroid-lag (#662 50th), β=0.9/0.95 short-window (#695 59th — all NULL via intrinsic lag/signal coupling). Cooldown-aware β ramp (#737 in flight — decouples lag from signal via LR-coupled β schedule).

*Aux AdamW update-rule FULLY CLOSED (10 families):* AdaBelief (#545), NadamW (#575), AdEMAMix (#585), AMSGrad (#578), Adamax (#583), LAMB (#609), Lion (#604), Lookahead (#617), Schedule-Free Adam (#623), NAdam-aux (#698 61st — β₁ ∈ [0.8, 0.9] insensitive). Saturation pattern: aux is structurally insensitive to update-rule changes, only schedule machinery moves outcomes.

*Aux scalars/static:* scalar_lr (#460), β1 (#416), β2 by-group (#433), embed eps (#463), aux WD (#466).

*Skylight u/w-floor:* magnitude (#486), phase-out (#522). TARGET_UW=0.35 confirmed.

*Gradient transformation body-Muon FULLY CLOSED (all families):* GC subtract (#553), column-mean amplify (#588), clipping (#513), per-block grad-norm (#627 45th), tanh-squash (#622 47th), winsorization (#644 48th), Langevin noise (#684 54th).

*Other:* z-loss (#476), embed init (#440), attn-scale (#480), logit soft-cap (#439), NS adaptive threshold (#447).
