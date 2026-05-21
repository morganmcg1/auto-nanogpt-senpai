# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-21 16:52 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Active experiments (8 students, 16:52 UTC — 0 idle)

| PR | Student | Run | Step/3250 | val | Status |
|---|---|---|---|---|---|
| **#697** | alphonse | NEWLY ASSIGNED | — | — | **NEW 16:46 UTC — QHM (Quasi-Hyperbolic Momentum) on body-Muon. Arm A: ν=0.10 β=0.95; Arm B: ν=0.20 β=0.95 (both nesterov=False). Direct follow-up to #660 Nesterov closure — tests if there's headroom beyond Nesterov on the (ν,β) plane.** |
| **#698** | nezuko | NEWLY ASSIGNED | — | — | **NEW 16:52 UTC — NAdam (Nesterov-AdamW) for aux groups. Arm A: β₁=0.8 unchanged; Arm B: β₁=0.9 retuned. Cross-family extension of #660 — is Nesterov load-bearing for AdamW too?** |
| **#695** | thorfinn | NEWLY ASSIGNED | — | — | Polyak EMA short-window anti-centroid-lag. Arm A: β=0.9 EMA_WARMUP=2500; Arm B: β=0.95 EMA_WARMUP=2250. |
| **#696** | tanjiro | NEWLY ASSIGNED | — | — | Contra-Muon contrarian momentum subtraction on body-Muon. Arm A: CONTRA_COEFF=0.2; Arm B: CONTRA_COEFF=0.1. |
| **#690** | edward | `znxwk1om` Arm A SGDR-1-restart | 380+ | tracking baseline | SGDR wiring confirmed; cycle_idx/cycle_step/mult firing as designed. ETA ~17:30+. |
| **#682** | askeladd | `0uvvmh8p` Arm A mu 0.95→0.85 | 1633 | 3.472 @ 1625 | **Early +30 mnat signal vs baseline at step 1625.** ETA 17:25. Arm B (mu 0→0.95) sequential. |
| **#684** | frieren | `chhogu08` Arm A σ=0.01 | 1673 | 3.531 @ 1500 | Noise confirmed firing. Healthy. ETA ~17:25. Arm B sequential. |
| **#686** | fern | `z6fo7pix` Arm A (warm-start) | 1233 | 3.51 | Arm A β_cov 0.90→0.95 warm-start running, ETA ~3h from 15:50. Arm B sequential. |

## Recently closed (this session)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#667** | nezuko | Cosine schedule NULL/NULL — Arm A (pure cosine) val=3.276601 sr=3000 (+62.5); Arm B (cosine_wsd 30% stable + cosine 70%) val=3.272568 sr=3000 (+62.5). **Mechanism (two findings):** (1) stable plateau is REQUIRED — Arm B beats Arm A by Δval=0.004 at identical sr; (2) WSD power-1.4 tail beats cosine tail by +62.5 sr-steps when stable phase is fixed. Both arms cross 3.28 at step 3000. **Schedule family WSD-LOCKED across 7 sub-axes.** | **CLOSED 16:47 UTC — 53rd axis.** |
| **#660** | alphonse | Nesterov ON/OFF NULL/NULL — Arm A (nesterov=False mu=0.95) val=3.26949 sr=3025 (+87.5 sr); Arm B (nesterov=False mu=0.90) val=3.27833 sr=3150 (+212.5 sr). **Mechanism:** Arm B was designed to match Nesterov's effective g-weight (1-0.90=0.10 ≈ 0.0975 Nesterov) by lowering mu. Instead it diverged FURTHER. Proves Nesterov lookahead is NOT equivalent to (1-mu) reweighting — cross-term μ²·m_prev + (1-μ²)·g coupling matters. **mu=0.95 AND nesterov=True both independently load-bearing.** | **CLOSED 16:42 UTC — 52nd axis.** |
| **#662** | thorfinn | Polyak EMA β=0.99 NULL — val_ema=3.267219 (+2.9 mnat) sr=2925 (−12.5 marginal). Peak EMA −63 mnat at step 1625 REAL, but centroid-lag (50-step lag at near-zero LR) FLIPPED sign at step 3100 → terminal EMA slightly WORSE than live. **Centroid-lag kills at terminal, NOT LMC failure.** | **CLOSED 16:22 UTC — 50th axis.** |
| **#651** | tanjiro | LR warmup NULL/NULL — warmup=100 sr=3000 val=3.26926, warmup=250 sr=3050 val=3.27341. Monotonic: longer warmup → worse. Zero-warmup load-bearing (same conclusion as cooldown_frac). WSD schedule shape FULLY PINNED (6 sub-axes). | **CLOSED 16:22 UTC — 51st axis.** |
| **#658** | edward | Post-NS momentum NULL/NULL — Arm A val=3.29212 DNF, Arm B val≈3.288 extrapolated (killed step 2550). Key finding: **direction matters, not magnitude** — polar(EMA(grads)) vs EMA(polar(grads)) are qualitatively different; pre-NS placement is load-bearing. | **CLOSED 15:15 UTC — 49th axis.** |
| **#644** | fern | Winsorization NULL/NULL — k=1.5 sr=3075 Δval=+0.00973 (32% clip, 29% norm reduce), k=3.0 sr=2975 Δval=+0.00342 (5% clip). Monotone: more clipping = worse. Combined with #622 tanh-squash, elementwise outlier treatment of post-whitening m_pre FULLY CLOSED. | **CLOSED 14:00 UTC — 48th axis.** |
| **#622** | frieren | Tanh-squash NULL/NULL/NULL — all arms (scale_mult=0.5/0.02/0.005). Post-whitening entries too small vs scale; even Arm C (max_ratio=1.26) shows only 4% Frob compression with no detectable signal. Gradient-domain pre-NS transformation class FULLY CLOSED. | **CLOSED 13:45 UTC — 47th axis.** |
| **#647** | askeladd | WSD longer cf NULL/NULL — cf=0.80 sr=2950 val=3.26675, cf=0.85 sr=2975 val=3.27016. Monotonic ordering confirms cf=0.70 at optimum. Mechanism: spreading COOLDOWN_POWER=1.4 over more steps proportionally weakens LR throughout decay tail. | **CLOSED 13:30 UTC — 46th axis.** |
| **#627** | nezuko | Per-block grad norm NULL/NULL — Arm A all val=3.269108 sr=3000 (Δsr=+62.5); Arm B mlp_only val=3.265763 sr=2950 (Δsr=+12.5 wrong direction). Pre-NS per-block magnitude conditioning axis CLOSES. | **CLOSED 08:50 UTC — 45th axis.** |
| **#623** | thorfinn | Schedule-Free Adam on aux NULL/NULL decisive. Both arms DNF val~3.31. Aux WSD cooldown load-bearing. Aux side saturated across 9 optimizer families. | **CLOSED 08:15 UTC — 44th axis.** |
| **#607** | alphonse | LR floor NULL/NULL. Linear damage ∝ floor magnitude × activation duration. Decay-to-zero tail is load-bearing. | **CLOSED 07:45 UTC — 43rd axis.** |
| **#617** | edward | Lookahead wrapper on aux NULL/NULL. k=5 Δsr=+37.5, k=10 Δsr=+87.5. | **CLOSED 07:10 UTC — 42nd axis.** |

## Recently merged

| PR | Student | Key result |
|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 | **MERGED 11:48 UTC** — current baseline. |

## Current research focus (updated 16:25 UTC)

**Six active frontiers after 53 closed axes:**

**1. Parameter-space averaging (deep investigation):**
- Polyak EMA β=0.99 (#662 CLOSED 50th axis): NULL via centroid-lag at terminal — peak −63 mnat mid-cooldown is REAL but terminal EMA flips sign at step 3100 when LR → 0
- **#695 thorfinn** (NEW): β=0.9 + EMA_WARMUP=2500 anti-lag test; β=0.95 + EMA_WARMUP=2250. Direct ablation: is centroid-lag the killer?

**2. LR schedule family (non-WSD / non-monotone):**
- Cosine #667 nezuko CLOSED 53rd: both arms NULL — schedule family WSD-LOCKED. Stable plateau REQUIRED; WSD power-1.4 tail > cosine tail by +62.5 sr.
- SGDR restarts #690 edward: 1 restart / 2 restart arms. First non-monotone test. Arm A running step 380+ at 16:00 UTC.

**3. Mechanism exploration:**
- **#696 tanjiro** (NEW): Contra-Muon contrarian momentum subtraction (CONTRA_COEFF ∈ {0.2, 0.1}). Known mechanism in public Track 3 records. First time testing on PMuon stack.
- **#697 alphonse** (NEW): QHM body-Muon ν ∈ {0.10, 0.20} at β=0.95. Direct follow-up to #660 Nesterov closure — decouple ν,β to span the gradient-blend space beyond Nesterov.
- **#698 nezuko** (NEW): NAdam (Nesterov-AdamW) for aux groups. Cross-family extension — is Nesterov load-bearing for AdamW too? Arm A β₁=0.8 unchanged; Arm B β₁=0.9 retuned.

**4. Temporal mu schedule:**
- Body-Muon mu schedule #682 askeladd: **EARLY +30 mnat signal at step 1625!** Arm A mu 0.95→0.85 ramp at 50%, ETA 17:25. Signal growing monotonically from step 1000 (+0.7 mnat) to step 1625 (+30 mnat).

**5. Stochastic exploration:**
- Langevin noise #684 frieren: σ=0.01 Arm A at step 1673, noise confirmed firing at 1.1% of update magnitude. Healthy. ETA 17:25.

**6. PMuon covariance:**
- β_cov schedule #686 fern: responsive-early (0.90→0.95) vs smoother-cooldown (0.95→0.98). In flight.

**Pattern after 53 axes:**
- Aux side FULLY SATURATED (9 optimizer families + all scalars all NULL; NAdam #698 first test of Nesterov family on aux)
- Body-Muon gradient-domain pre-NS FULLY CLOSED (all 6 families)
- Body-Muon operator ordering FULLY CLOSED: post-NS CLOSED (#658 49th)
- WSD schedule FULLY PINNED across 7 sub-axes (cooldown_frac, cooldown_power, LR floor, warmup, cosine NULL #667, longer cf both directions)
- **Nesterov axis CLOSED (#660 52nd)**: nesterov=True AND mu=0.95 BOTH independently load-bearing; cross-term coupling non-trivial → QHM natural follow-up (#697 alphonse) + cross-family NAdam test (#698 nezuko)
- Polyak EMA: centroid-lag mechanism confirmed (not LMC) → short-window + late-start test next (#695)
- **Contra-Muon** UNTESTED in PMuon stack — first big new mechanism in 10 closures (#696 in flight)

## Key mechanisms confirmed to date

- **WSD cooldown is load-bearing:** decay-to-zero tail IS the mechanism (shorter → NULL, LR floor → NULL, warmup → NULL monotone)
- **Aux gradient noise dominant:** no update-rule change, averaging, or warmup helps aux
- **PMuon spectral whitening absorbs magnitude info:** per-block grad norm, gradient clipping, GC operations all NULL
- **COOLDOWN_POWER=1.4 near-optimal within WSD:** NS, scalar scans all optimum-confirmed
- **Pre-NS momentum placement LOAD-BEARING:** direction of polar(EMA(grads)) qualitatively better than post-NS (#658 49th)
- **Polyak EMA centroid-lag:** β=0.99 100-step window gives real −63 mnat mid-cooldown advantage; terminal failure is centroid-lag (not LMC) as LR→0; narrower window (β=0.9, 10-step) should have 5-step lag only

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Closed axes reference (51 total)

*PMuon scalars COMPLETE (all 5 pinned):* γ_power=0.4, β_cov=0.95, NS_ITERS=12 (5-pt V-curve), NS coeff cubic (1.5,-0.5,0), ε=1e-12, mu=0.95.

*Body-Muon LR partition FULLY CLOSED:* per-type (#499), sub-MLP (#535), depth-based (#532).

*Body-Muon scalars/wrappers:* WD partition (#482), WD schedule (#503), grad clipping (#513), γ_power ramp (#444), lr fine-scan (#465), Lookahead (#505).

*Body-Muon parameter-space averaging:* Lookahead (#505 DNF), Polyak EMA β=0.999 LMC failure, β=0.99 centroid-lag (#662 50th); β=0.9 short-window in flight (#695).

*Body-Muon operator ordering CLOSED:* post-NS momentum (#658 49th — pre-NS placement load-bearing, direction > magnitude). Pre-NS confirmed as optimum.

*Aux AdamW update-rule mechanisms FULLY CLOSED (9 families):* AdaBelief (#545), NadamW (#575), AdEMAMix (#585), AMSGrad (#578), Adamax (#583), LAMB (#609), Lion (#604), Lookahead (#617), Schedule-Free Adam (#623).

*Aux scalars/static:* scalar_lr (#460), β1 (#416), β2 by-group (#433), embed eps (#463), aux WD (#466).

*Skylight u/w-floor:* magnitude (#486), phase-out (#522). TARGET_UW=0.35 confirmed.

*Gradient transformation body-Muon FULLY CLOSED:* GC subtract (#553), column-mean amplify (#588), clipping (#513), per-block grad-norm (#627 45th), tanh-squash (#622 47th), Winsorization (#644 48th). All elementwise post-whitening transformations exhausted.

*WSD schedule shape FULLY PINNED (6 axes):* shorter-cooldown (#606 39th), LR floor (#607 43rd), NS_ITERS ramp (#559 38th), decoupled aux cooldown (#448), longer-cooldown (#647 46th), LR warmup (#651 51st).

*Other:* z-loss (#476), embed init (#440), attn-scale (#480), logit soft-cap (#439), NS adaptive threshold (#447).

*Other:* z-loss (#476), embed init (#440), attn-scale (#480), logit soft-cap (#439), NS adaptive threshold (#447).
