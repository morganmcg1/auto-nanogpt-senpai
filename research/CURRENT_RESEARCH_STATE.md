# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-23 14:50 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2925 steps. LOCAL RECORD **2925** (PR #864, merged 2026-05-23 14:10 UTC). **ONE POTENTIAL IMPROVEMENT PENDING:** #893 edward PMuon momentum BC Arm A marginal val win (Arm B BC warmup-only in flight ETA ~16:50 UTC).
- **88 closed axes** (#884 nezuko NS_ITERS={8,16} both-NULL 88th — NS_ITERS fully pinned at static=12 across {8, 12, 16, 20}; asymmetric closure: 8→under-converged catastrophic (residual 14), 16→over-saturation marginal (residual 0.067), 12 saturating equilibrium (residual 0.10). Combined with #540 (polynomial at NS=12 fixed), NS subsystem pinned across all 2D cells except quintic×low-iters joint cell). #899 Arm A terminal NULL; Arm B in flight. Zero idle students after #913 + #918 + #920 assigned.

## Current local baseline

**sr=2925 (n=2 mean, both seeds 2925), val/loss=3.266826 (n=2 mean)** — PR #864 (g1r1-thorfinn, EMA warmup_steps=1750). **MERGED 2026-05-23 14:10 UTC.**

Config: PR #413 config + `--ema_beta 0.95 --ema_warmup_steps 1750 --ema_beta_target 0.99` (warmup shortened from 2250 → 1750 to add 500 cooldown-phase averaging steps; β ramps 0.95→0.99 during cooldown coupled to lr_mult). EMA buffer: FP32 body-Muon matrix params; inference uses EMA-swapped weights.

W&B seeds: `j8nsn77s` (seed-1 val=3.266355), `08ursg5n` (seed-2 val=3.267298). **Win vs new baseline:** sr ≤ 2912.5 OR (sr = 2925 AND val < 3.266826). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001 vs new baseline): request n=2 before merge. n=1 stat-sig threshold: val ≤ 3.276.

Note: The val improvement is razor-thin (−0.1 mnat over PR #737). Future experiments that previously compared against val=3.266926 now compare against 3.266826 (slightly harder target).

## Active experiments (8 in-flight, 14:50 UTC)

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| ~~**#864**~~ | thorfinn | EMA warmup_steps re-tune (1750 vs 2500) | **MERGED 14:10 UTC as new baseline.** n=2 mean val=3.266826 (Δval=−0.0001 vs #737). ema_warmup_steps=1750 adopted. |
| ~~**#884**~~ | nezuko | NS_ITERS tune: 8 vs 16 polar convergence (current=12) | **CLOSED 14:50 UTC as 88th NULL.** Arm A (NS=8) sr=3050/val=3.2744 catastrophic regression (residual ~14, under-cliff). Arm B (NS=16) sr=2975/val=3.2703 marginal regression (residual ~0.067, over-saturation). NS_ITERS axis CLOSED at static=12 across {8, 12, 16, 20}. |
| **#920** | nezuko | Quintic NS at low iter count (NS_ITERS=5 vs 6) — joint cell never tested | **Newly assigned 14:48 UTC** after #884 closure. Quintic coefs (3.4445, -4.7750, 2.0315) at NS_ITERS={5,6}. Joint cell quintic×low-iters is the last untested cell in the 2D NS coef × iter family. Tests whether quintic's faster per-iter small-σ amplification can match cubic-at-12 in fewer iters with a different per-iter spectral signature. |
| **#893** | edward | PMuon momentum first-moment Adam-style BC (1/(1-mu^t)) | **Arm A `lrackrk3` TERMINAL marginal val WIN: sr=2925/val=3.266211 (Δval=−0.000715).** Cross-axis falsification of #822 "PMuon warmup mechanically denoised" prediction — m_pre BC is directional (NS5 absorbs magnitude bias but NOT directional bias). Arm B (BC warmup-only) chained, running. **ETA terminal ~16:50 UTC.** |
| **#896** | askeladd | Cautious-Muon body: post-NS multiplicative sign-mask | **Arm A `qw18ifdw` TERMINAL HARD NULL: val=3.2974, sr=−1, mask_frac=0.625.** Confirms #696 Contra-Muon closure pattern: post-NS perturbations break polar map spectral structure. Arm B (mask-only, no renorm) chained, running. **ETA terminal ~17:15 UTC.** |
| **#897** | tanjiro | Body-Muon adaptive WD coupled to ||p||/target_norm | **Arm A TERMINAL NULL: sr=3000, val=3.270003**, terminal wd_mult=2.549 (moderated from mid-run 3.22). Adds to body-Muon WD axis closure pattern: static 0.025 locked across 5 closed sub-axes. Arm B (α=0.5 sqrt) chained, running. **ETA terminal ~17:30 UTC.** |
| **#898** | alphonse | PMuon residual-driven adaptive NS_ITERS (per-tensor early termination) | **Arm A `d332v1wk` TERMINAL 13:58 UTC: sr=2925, val=3.26813 (Δval=+0.00120 vs new baseline 3.266826).** `adaptive_ns/iter_count=20` constant — eps=1e-3 unreachable (residual floor 0.05). Arm A degenerates to static NS_ITERS=20, gives same sr but slight val regression vs NS_ITERS=12. Arm B `ypejugws` inadvertently launched (script-edit hazard), now running as n=2 sanity confirmation. **ETA Arm B terminal ~17:57 UTC.** |
| **#899** | fern | Aux Polyak EMA: lm_head only vs embed only (β-ramp matches body) | **Arm A `byqi2lgf` TERMINAL 14:15 UTC NULL: sr=2925 TIE, val=3.268543 (Δval=+0.00172 vs new baseline; val_live=3.267891, val/ema_minus_live=+0.000652 — EMA slightly WORSE than live).** Structural finding: aux EMA on lm_head SMEARS across uncorrelated update vectors (consistent with #875 `s/m²≫1` and #854 `||Δg||/||g||≈1.45`). 17th aux family closure direction. Arm B `cw1ub4f3` (`--ema_aux_embed`) launched 14:16 UTC, running step ~50. **ETA Arm B terminal ~18:05 UTC.** |
| **#913** | frieren | Aux embed/lm_head LR retune at PR #737 baseline | **Assigned 14:05 UTC after #875 closure.** Arm A=embed_lr=0.4/lm_head_lr=0.008 (UP); Arm B=embed_lr=0.225/lm_head_lr=0.005 (DOWN). embed/lm_head LRs unchanged since PR #413; body-Muon (γ_pre=0.4, β_cov=0.95) and EMA wrapper (β_target=0.99 ramp) have shifted effective body magnitude. Base-case probe — sharpens 16-closure "aux saturation" finding from #875 `s/m²≫1`. |
| **#918** | thorfinn | Body-Muon LR retune at post-#864 baseline (UP 0.040 vs DOWN 0.030) | **Newly assigned 14:25 UTC** after #864 merge. Arm A `muon_lr=0.040` (UP +14%); Arm B `muon_lr=0.030` (DOWN −14%). Body-Muon static LR was last retuned at PR #248 BEFORE EMA wrapper (PR #737) and shortened warmup (PR #864) — last retune is structurally stale. **Forms parallel pair with #913 (aux LR retune)**: joint outcome produces LR-axis saturation signal at post-#864 baseline (5th sub-axis after WD ±, mu ±, β_cov ±, γ ±). |

**Recently closed (this session):**
- #846 edward (AdEMAMix-Aux 82nd, both arms NULL)
- #827 nezuko (NS-output Frobenius 81st, n=2 informative-NULL)
- #853 askeladd (Cautious-AdamW aux 83rd, both arms NULL; mask fired correctly, renorm load-bearing, mask alone no benefit)
- #854 tanjiro (Adan-aux 84th, both arms NULL; m_t lag killed paper β1=0.98 like #846 AdEMAMix; β1=0.80 near-baseline. **Key insight: aux gradients i.i.d. step-to-step** `||Δg||/||g|| ≈ 1.45` constant → cosine ≈ -0.05 → rules out Adan/NAdam-lookahead/Polyak heavy-ball/MARS family on aux).
- #822 alphonse (PMuon L_cov/R_cov Adam-style BC 85th, n=3 boundary informative-NULL. Seed sequence 2875/2925/2950 → n=3 mean sr=2916.67 > 2900 MERGE threshold. Mechanism telemetry-confirmed correct across all 3 seeds; effect at seed-noise boundary. Closes PMuon warmup-phase second-moment-BC sub-axis).
- #863 fern (Adam-mini-aux 86th NULL, 15th aux Adam-family closure). Arm A per_row: sr=2925/val=3.267874 sub-marginal regression TIE. Arm B per_tensor: sr=−1/val=3.299257 catastrophic hard NULL. Clean ablation: per_row preserves cross-row variance (mild regression); per_tensor collapses to SGD+momentum (catastrophic). Mechanism: Adam per-coord variance is LOAD-BEARING for sparse-gradient tensors (embed/lm_head).
- **#875 frieren (AdaBelief-aux 87th NULL, 16th aux Adam-family closure). Arm A paper β=(0.9, 0.999) sr=3025/val=3.27288 clean regression; Arm B drop-in β=(0.8, 0.95) sr=2950/val=3.26852 Δsr marginal-boundary but Δval>0.001. Telemetry win: `s/m² ≫ 1` everywhere on aux (embed/lm_head 5.9×, scalars 23×) → m_t does NOT predict g_t → AdaBelief's confidence-update path never engages. Cross-axis confirmation of #854 i.i.d. aux gradient finding via independent measurement angle. `v_vs_s_ratio = 1.426` confirms surprise denominator correctly tighter by ~30% but unused. Open aux levers narrowed to: aux parameter EMA (#899 in flight, fresh family), direct base-LR retune (#913 newly assigned to frieren), SOAP/Shampoo for lm_head (complex/deferred).**
- #892 edward Lookahead-Muon (closed pre-launch as duplicate of #505 — same arms k=5/k=10 α=0.5 already NULL/NULL on body-Muon at PR #505 2026-05-20; pre-launch duplicate-check failure caught before student touched it).

## Recently closed (since session start)

| PR | Axis # | Verdict | Mechanism |
|---|---|---|---|
| **#841** frieren | 80th | EMA β ramp shape informative-NULL (Arm A Δval=−0.000182, Arm B Δval=−0.0000042) | Terminal β_t=0.99 identical across all configs. Steady-state EMA dominated by final ~100 steps. Student correctly identified informative-NULL despite technically passing predeclared WIN rule. Spec note: baseline ramp is concave not linear (lr_mult power=1.4). |
| **#802** thorfinn | 79th | Polyak EMA β_target=0.98 n=2 informative-NULL (n=2 mean sr=2937.5, val=3.267043) | seed-1 sr=2925 (lucky) + seed-2 sr=2950 → +12.5 sr regression. β/(1−β) lag scaling replicated stable across seeds (~0.229 mnat at β=0.98 vs ~0.54 at β=0.99); mechanism real but N_eff=50 cannot dampen 25-step EMA-swap-val target-crossing jitter. β_target frontier settled: 0.99 BEST, 0.98 marginal-NULL, 0.97/0.999 NULL. |
| **#821** fern | 78th | Kahan BF16 compensated weight update NULL/NULL (A sr=2925/val=3.266462 TIE, B sr=2925/val=3.267573 TIE) | Pre-launch dtype audit caught the structural issue: body-Muon params AND EMA buffer already FP32. `p.add_(update.to(p.dtype))` is exact when p is FP32 → Kahan compensation comp_rms_mean ≈ 0 (5.4e-9 Arm A, 0 Arm B). Only `self.embed` is BF16. Pure mechanistic no-op confirmed by both arms tying baseline within sub-noise. |
| **#778** tanjiro | 77th | PMuon per-type γ narrow TIE (clean n=2 sr=2925/val=3.266815, Δval=−0.000111 sub-noise) | Δval is 22× smaller than seed-variance (0.0025); 9× below 0.001 marginal threshold. PMuon per-type γ axis FULLY CLOSED (wide #736 + narrow #778). Kronecker L_cov/R_cov capture per-tensor curvature; per-type γ scalar offers no orthogonal gain. |
| **#814** askeladd | 76th | Aux RAdam NULL/NULL (A LR=0.30 sr=2925 TIE, B LR=0.22 sr=2950 regression) | Mechanism intact (rho_t 1→38.15, r_t 0→0.987, in_sgd_fallback flip). AdamW β2=0.95 already handles variance warmup implicitly at high aux LRs. Aux Adam-family variance-warmup mechanism FULLY CLOSED across NAdam (#698), β2 ramp (#741), β1 ramp (#796), RAdam (#814). |
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

## Closed axes reference (87 total)

*Aux Adam-family update rules SATURATED (16 closed):* NAdam (#698 61st), β2 ramp (#741 72nd), β1 ramp (#796 75th), RAdam (#814 76th), AdEMAMix (#585 + #846 82nd α-sweep), AMSGrad (#578), Adamax (#583), LAMB (#609), Lookahead (#617), Schedule-Free (#623), AdaBelief (#545), Lion (#604), Cautious-AdamW (#853 83rd — mask fires in expected 0.45-0.77 band, renorm load-bearing, mask itself no aux benefit), Adan (#854 84th — m_t lag + Δg correction strictly worse on aux), Adam-mini (#863 86th — per_row sub-marginal regression, per_tensor catastrophic NULL; per-coord variance LOAD-BEARING for sparse-gradient tensors), **AdaBelief revisit (#875 87th — Arm A paper β NULL +100 sr/+0.006 val; Arm B drop-in β NULL Δsr=+25 marginal-boundary, Δval=+0.0016 fails marginal-win; mechanism active `v_vs_s=1.426` but `s/m² ≫ 1` everywhere → confidence-update path never engages)**. Mechanistic insight from #854 telemetry: aux gradients i.i.d. step-to-step (`||Δg||/||g|| ≈ 1.45` constant → cosine ≈ -0.05). Independently re-confirmed by #875 `s/m² ≫ 1` finding via the AdaBelief denominator. Rules out Δg-autocorrelation methods (Adan, NAdam-lookahead, MARS, Polyak heavy-ball γ>0) AND momentum-magnitude-based adaptive optimizers more broadly. **#863 closure-derived insight:** Adam per-coord variance is load-bearing on sparse-gradient tensors — variance compression (per_row or per_tensor) sacrifices rare-token adaptivity for memory savings that don't help in this regime. **Open aux levers (3 remaining):** aux parameter EMA (#899 in flight — fresh mechanism family, never tested), **direct base-LR retune (#913 frieren in flight — embed_lr/lm_head_lr never re-tuned since PR #413)**, SOAP/Shampoo for lm_head (complex/deferred). **Telemetry filter (from #875):** future aux Adam-family candidates with `s/m² > 5` on first 500-step run can be invalidated before full 4-GPU-hour benchmark.

*PMuon warmup-phase interventions:* β_cov warmup fast-mix (#774 — K=20 mild NULL, K=50 crash from β_cov=0 rank-deficiency), **L_cov/R_cov Adam-style BC (#822 85th — n=3 boundary informative-NULL; mechanism telemetry-verified, effect at seed-noise boundary)**. PMuon momentum first-moment BC (#893 in flight). Cross-cutting insight: PMuon warmup is mechanically denoised (NS5 polar map absorbs small preconditioner errors); warmup-phase fixes have <seed-noise impact unless they alter polar DIRECTION (not just magnitude).



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
