# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-22 22:05 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2925 steps. LOCAL RECORD **2925** (PR #737, merged 2026-05-22). **POTENTIAL NEW RECORD PENDING:** #822 alphonse Arm A sr=2875 (Δsr=−50) — FINISHED, awaiting student terminal SENPAI-RESULT.
- **75 closed axes** (#796 edward aux β1 cooldown ramp closed as 75th — both arms NULL, β1 does not mirror β2; proves smoothing-UP schedule is parameter-specific not class-wide).
- **🚨 HIGH PRIORITY:** PR #822 alphonse Arm A `8b0m4nzt` FINISHED sr=2875 (Δsr=−50 BIG WIN). Arm B `5gy0esey` (β_cov=0.98) running. Awaiting student terminal SENPAI-RESULT. Once posted, n=2 confirmation run will likely be needed (Δsr=-50 is far past marginal but all sr changes require n=2 for baseline changes).
- **Active n=2 confirmation:** #802 thorfinn seed-2 just launched at β_target=0.98 (n=1 win Δval=-0.000346, marginal). ETA ~01:15-01:30 UTC.

## Current local baseline

**sr=2925 (n=2 mean, both seeds 2925), val/loss=3.266926 (n=2 mean)** — PR #737 (g1r1-thorfinn, Polyak EMA β_target=0.99 cooldown ramp). **MERGED 2026-05-22 13:21 UTC.**

Config: PR #413 config + `--ema_beta 0.95 --ema_warmup_steps 2250 --ema_beta_target 0.99` (β ramps 0.95→0.99 during cooldown, coupled to lr_mult). EMA buffer: FP32 body-Muon matrix params; inference uses EMA-swapped weights.

W&B seeds: `rdbmnzpc` (seed-1), `32r3isz5` (seed-2). **Win vs new baseline:** sr ≤ 2912.5 OR (sr = 2925 AND val < 3.266926). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001 vs new baseline): request n=2 before merge. n=1 stat-sig threshold: val ≤ 3.276.

Val note: +2.65 mnat regression vs PR #413 val (3.264278) is accepted — primary metric is sr and it improved. Future experiments must compare against sr=2925/val=3.266926.

## Active experiments (8 in-flight, 22:05 UTC)

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| **#822** | alphonse | PMuon L_cov/R_cov Adam-style bias correction (β_cov=0.95 vs 0.98, BC ON) | Arm A `8b0m4nzt` **FINISHED sr=2875/val=3.2646 — BIG WIN**. Arm B `5gy0esey` (β_cov=0.98+BC) running step 300. Awaiting terminal SENPAI-RESULT (~01:30 UTC). |
| **#821** | fern | Kahan BF16 compensated weight update for body-Muon | Arm A `1segjgvo` FINISHED sr=2925/val=3.2665 (TIE, FP32→Kahan no-op as predicted). Arm B `ji1hed72` (Kahan+EMA lerp) running step 300. Awaiting terminal SENPAI-RESULT (~01:25 UTC). |
| **#827** | nezuko | Post-NS Frobenius normalization (post vs pre, polar RMS=1) | Arm A `q72w28l9` (post) running step 2400/3250. ETA terminal ~22:50 UTC. Arm B (pre) chains. |
| **#814** | askeladd | Aux RAdam — rectified-Adam variance warmup | Arm A `o9et1cs6` TERMINAL sr=2925/val=3.26659 (TIE, RAdam≈baseline, axis closing). Arm B `t80hfeqy` running step 1325/3250. ETA ~23:30 UTC. |
| **#802** | thorfinn | EMA β_target n=2 seed-2 (β_target=0.98, n=1 marginal win Δval=−0.000346) | Seed-2 just launched at 21:36. ETA ~01:15-01:30 UTC. |
| **#778** | tanjiro | PMuon per-type γ narrow (γ_attn=0.45, γ_mlp=0.4) — clean seed-1 re-run | `b958vx2r` running step 625/3250 (launched 20:51). ETA ~00:25 UTC. |
| **#841** | frieren | EMA β ramp shape: delayed nonlinear ramp (delay_frac 0.5/0.7) | Arm A `quhyt7s4` running step 150/3250 (picked up 21:29). ETA ~01:30 UTC. |
| **#846** | edward | AdEMAMix-Aux α sweep: dual first-moment EMA for aux groups (α=2 vs α=8) | ASSIGNED 22:05 UTC. Replaces AdamW aux with dual-EMA optimizer (slow β₃=0.9999 + fast β₁=0.8, α warmup over 512 steps). |

## Recently closed (since session start)

| PR | Axis # | Verdict | Mechanism |
|---|---|---|---|
| **#796** edward | 75th | Aux β1 ramp NULL/NULL (A sr=2950 DOWN 0.8→0.7, B sr=2925 TIE UP 0.8→0.9) | β1 does NOT mirror β2 (#741). UP-ramp on β1 yields +0.057 μnat (TIE) vs −306 μnat for β2. Proves smoothing-UP schedule is parameter-specific not class-wide. Aux β1=0.8 static is local optimum. |
| **#803** frieren | 74th | γ_power WARMUP ramp NULL/NULL (A sr=2975 0.2→0.4, B sr=2950 0.3→0.4) | Both arms regress on sr. Monotone less-whitening→worse. γ_power=0.4 static is fully pinned across both warmup (#803) and cooldown (#760) ramp axes. Student insight: EMA β is the clean manipulation target. |
| **#780** nezuko | 73rd | u/w CEILING NULL/NULL (A sr=3125 ceiling=0.5, B sr=3225 ceiling=0.4) | Monotone tighter→worse. Ceiling fires 43-71% events. High u/w updates are productive (confident PMuon directions); clamping removes per-tensor adaptivity. Floor at 0.35 is load-bearing (49% fire rate, asymmetric). |
| **#741** alphonse | 72nd | Aux β2 cooldown ramp NULL on primary (n=2 sr=2950), val-frontier shift (−0.0017) | Val-frontier shift confirmed at n=2; doesn't move primary sr. Pattern: cooldown mechanism changes shift (sr,val) Pareto frontier but rarely improve both. |
| **#777** fern | 71st | Body-Muon mu cooldown ramp NULL/NULL (A sr=2925/val=3.269, B sr=3025/val=3.268) | Body-Muon momentum spec PINNED at static mu=0.95 across 5 sub-axes. |
| **#760** frieren | 69th | γ_power COOLDOWN ramp NULL/NULL (A sr=2975 γ→0.5, B sr=2975 γ→0.3) | Both arms regress vs old baseline (+37.5 sr, +0.003/+0.002 val). Arm B "less bad" — softer whitening in cooldown ~2× closer to baseline. γ_power=0.4 static well-tuned; ramping exponent during cooldown over-rotates spectral geometry. Closes γ_power cooldown axis. |
| **#774** edward | 68th | PMuon cov warmup fast-mix NULL/crash (A K=20 sr=2975 NULL; B K=50 crashed step 41) | Arm A: mild over-smooth, no benefit. Arm B: numerical instability intrinsic to β_cov=0.0 collapsing EMA to outer-product accumulation (rank-deficient R_cov → eigh divergence). K=50 fast-warmup with β=0 is structurally unstable. |
| **#745** nezuko | 67th | Per-type LR cooldown asymmetry NULL/NULL (A sr=3025 attn0.5, B sr=3050 mlp0.5) | Both arms regress non-marginally. CROSSOVER pattern: sub-component cooldown sensitivities trade off symmetrically, neither recovers baseline. Closes per-type LR family (#499, #535, #532, #745). |
| **#736** tanjiro | 66th | Per-type γ asymmetry wide split NULL/NULL (A sr=3050 attn0.3, B sr=2975 attn0.5) | Direction validated — γ_attn > γ_mlp helps. Magnitude insufficient. Wide-split closed; narrow test open via #778. |
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
