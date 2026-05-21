# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-21 13:35 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Active experiments (8 students, 13:50 UTC — 0 idle)

| PR | Student | Run | Step/3250 | val | Status |
|---|---|---|---|---|---|
| **#662** | thorfinn | β=0.99 sub-run (post-LMC pivot) | ~2800 | TBD | Polyak EMA β=0.99 substitute run (100-step window, avg only last ~100 steps under tiny LR). ETA ~15:00. |
| **#660** | alphonse | Arm A done sr=3025, Arm B running | — | 3.269 (A done) | Nesterov OFF mu=0.95 NULL. Arm B nesterov=False mu=0.90 running. |
| **#658** | edward | `d9ifhvbr` Arm A at ~1875 | ~1875 | healthy | Post-NS momentum Arm A running cleanly after bf16↔fp32 fix. |
| **#651** | tanjiro | Arm A v2 running | ~775 | 3.73 | LR warmup=100 Arm A v2 running (v1 crashed; v2 clean). Arm B warmup=250 follows. |
| **#682** | askeladd | NEWLY ASSIGNED | — | — | **NEW 13:35 UTC — Body-Muon mu schedule: Arm A mu 0.95→0.85 cooldown ramp; Arm B mu 0.0→0.95 warmup.** |
| **#684** | frieren | NEWLY ASSIGNED | — | — | **NEW 13:50 UTC — Body-Muon Langevin noise post-NS, σ_base ∈ {0.01, 0.05}.** |
| **#644** | fern | Arm A k=1.5 near terminal, Arm B k=3.0 in progress | ~2625/TBD | ~3.32 | Winsorization. Arm A DNF trajectory. |
| **#667** | nezuko | `3qn5btoq` Arm B cosine+stable | ~485 | 3.88 (step 375) | Arm A (pure cosine) DONE sr=3000 val=3.2766 — CLEAR NULL (+62.5 sr, +0.012 val). Arm B (cosine+30% stable plateau) running, ETA ~16:20 UTC. |

## Recently closed (this session)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#622** | frieren | Tanh-squash NULL/NULL/NULL — all arms (scale_mult=0.5/0.02/0.005). Post-whitening entries too small vs scale; even Arm C (max_ratio=1.26) shows only 4% Frob compression with no detectable signal. Gradient-domain pre-NS transformation class FULLY CLOSED. | **CLOSED 13:45 UTC — 47th axis.** |
| **#647** | askeladd | WSD longer cf NULL/NULL — cf=0.80 sr=2950 val=3.26675, cf=0.85 sr=2975 val=3.27016. Monotonic ordering confirms cf=0.70 at optimum. Mechanism: spreading COOLDOWN_POWER=1.4 over more steps proportionally weakens LR throughout decay tail. | **CLOSED 13:30 UTC — 46th axis.** |
| **#627** | nezuko | Per-block grad norm NULL/NULL — Arm A all val=3.269108 sr=3000 (Δsr=+62.5); Arm B mlp_only val=3.265763 sr=2950 (Δsr=+12.5 wrong direction). Pre-NS per-block magnitude conditioning axis CLOSES. | **CLOSED 08:50 UTC — 45th axis.** |
| **#623** | thorfinn | Schedule-Free Adam on aux NULL/NULL decisive. Both arms DNF val~3.31. Aux WSD cooldown load-bearing. Aux side saturated across 9 optimizer families. | **CLOSED 08:15 UTC — 44th axis.** |
| **#617** | edward | Lookahead wrapper on aux NULL/NULL. k=5 Δsr=+37.5, k=10 Δsr=+87.5. | **CLOSED 07:10 UTC — 42nd axis.** |
| **#607** | alphonse | LR floor NULL/NULL. Linear damage ∝ floor magnitude × activation duration. Decay-to-zero tail is load-bearing. | **CLOSED 07:45 UTC — 43rd axis.** |

## Recently merged

| PR | Student | Key result |
|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 | **MERGED 11:48 UTC** — current baseline. |

## Current research focus (updated 13:50 UTC)

**Five active frontiers after 47 closed axes:**

**1. LR schedule family (non-WSD):**
- WSD shape fully pinned (5 sub-axes). Cosine LR schedule (#667 nezuko): Arm A pure cosine NULL (sr=3000 Δsr=+62.5, Δval=+0.012), Arm B cosine+30% stable plateau in flight ETA ~16:20.
- Key finding: stable plateau appears essential. Pure cosine loses by removing it.

**2. Body-Muon operator ordering / mechanism:**
- Post-NS momentum position (#658 edward, Arm A in progress)
- Nesterov ON/OFF (#660 alphonse, Arm A sr=3025 NULL; Arm B mu=0.90 in progress)

**3. Parameter-space averaging (mechanism investigation):**
- Polyak EMA (#662 thorfinn) found LMC failure in cooldown due to cubic-NS multi-basin traversal. β=0.99 substitute near terminal (~15:00 UTC). Key finding: parameter-space averaging INCOMPATIBLE with PMuon cubic-NS curvature.

**4. Temporal schedule axes (NEW):**
- Body-Muon mu schedule (#682 askeladd): Arm A cooldown ramp 0.95→0.85, Arm B warmup 0.0→0.95. First time-varying mu test.
- LR warmup (#651 tanjiro): warmup=100 and warmup=250. Second open schedule axis.

**5. Stochastic exploration (NEW):**
- Body-Muon Langevin noise post-NS (#684 frieren): σ_base ∈ {0.01, 0.05}, noise ∝ lr_t. First stochastic perturbation test. Motivated by plateau protocol.

**Pattern after 47 axes:**
- Aux side FULLY SATURATED (9 optimizer families + all scalars all NULL)
- Body-Muon gradient-domain pre-NS FULLY CLOSED: GC subtract/amplify, clip, per-block norm, tanh-squash, winsorization (near-terminal)
- Body-Muon parameter-space averaging CLOSED (Lookahead, Polyak EMA — LMC failure)
- WSD schedule shape FULLY PINNED (5 axes)
- Open levers: operator ordering (#658), Nesterov (#660), cosine schedule (#667), mu schedule (#682), stochastic noise (#684)

## Key mechanisms confirmed to date

- **WSD cooldown is load-bearing:** decay-to-zero tail IS the mechanism (shorter → NULL, LR floor → NULL)
- **Aux gradient noise dominant:** no update-rule change, averaging, or warmup helps aux
- **PMuon spectral whitening absorbs magnitude info:** per-block grad norm, gradient clipping, GC operations all NULL
- **COOLDOWN_POWER=1.4 near-optimal within WSD:** NS, scalar scans all optimum-confirmed
- **WSD schedule is superior to naive alternatives** (to be confirmed by #667 cosine test)

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Closed axes reference (47 total)

*PMuon scalars COMPLETE (all 5 pinned):* γ_power=0.4, β_cov=0.95, NS_ITERS=12 (5-pt V-curve), NS coeff cubic (1.5,-0.5,0), ε=1e-12, mu=0.95.

*Body-Muon LR partition FULLY CLOSED:* per-type (#499), sub-MLP (#535), depth-based (#532).

*Body-Muon scalars/wrappers:* WD partition (#482), WD schedule (#503), grad clipping (#513), γ_power ramp (#444), lr fine-scan (#465), Lookahead (#505).

*Body-Muon parameter-space averaging CLOSED:* Lookahead (#505 DNF), Polyak EMA (#662 LMC failure in cooldown — key finding).

*Aux AdamW update-rule mechanisms FULLY CLOSED (9 families):* AdaBelief (#545), NadamW (#575), AdEMAMix (#585), AMSGrad (#578), Adamax (#583), LAMB (#609), Lion (#604), Lookahead (#617), Schedule-Free Adam (#623).

*Aux scalars/static:* scalar_lr (#460), β1 (#416), β2 by-group (#433), embed eps (#463), aux WD (#466).

*Skylight u/w-floor:* magnitude (#486), phase-out (#522). TARGET_UW=0.35 confirmed.

*Gradient transformation body-Muon FULLY CLOSED:* GC subtract (#553), column-mean amplify (#588), clipping (#513), per-block grad-norm (#627 45th), tanh-squash (#622 47th). Winsorization (#644 in-flight, near-NULL trajectory).

*WSD schedule shape FULLY PINNED (5 axes):* shorter-cooldown (#606 39th), LR floor (#607 43rd), NS_ITERS ramp (#559 38th), decoupled aux cooldown (#448), longer-cooldown (#647 46th).

*Other:* z-loss (#476), embed init (#440), attn-scale (#480), logit soft-cap (#439), NS adaptive threshold (#447).
