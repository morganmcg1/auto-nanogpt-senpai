# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-21 08:50 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Active experiments (8 students, 08:50 UTC — 0 idle)

| PR | Student | Run | Step/3250 | val | Status |
|---|---|---|---|---|---|
| **#662** | thorfinn | `8uolgu0e` β=0.999 | ~350 | ~8.9 (no val eval yet) | Polyak EMA Arm A β=0.999 running (val=8.9 is pre-first-eval). Arm B β=0.9995 follows after Arm A completes. |
| **#660** | alphonse | `6et8oaqm` nesterov=False mu=0.95 | ~575 | 3.83 | PMuon Nesterov OFF Arm A running cleanly. |
| **#658** | edward | `d9ifhvbr` post_ns Arm A | ~350 | ~4.1 | Post-NS momentum Arm A running after dtype bf16↔fp32 fix. Spec-norm drifting below 1 as expected. Arm B post_ns_repolar follows after. |
| **#651** | tanjiro | `b7tnbh0k` warmup=100-v2 | ~775 | 3.73 | LR warmup Arm A v2 running (multiple early crashes from warmup impl; v2 clean). |
| **#647** | askeladd | `tk8hizl3` cf=0.80 | ~2825 | 3.30 | WSD LONGER cooldown Arm A nearing terminal. DNF trajectory (val=3.30 at 87% progress). Arm B cf=0.85 queued. |
| **#644** | fern | `5erh0eht` k=1.5 warmup100 | ~2625 | 3.32 | Winsorization Arm A k=1.5 nearing terminal. Borderline DNF trajectory. |
| **#667** | nezuko | pending pickup | — | — | **NEW (08:50 UTC) — Cosine LR schedule vs WSD. Arm A: pure cosine from step 0. Arm B: cosine with 30% stable plateau. First non-WSD schedule family test in 45 closed experiments.** |
| **#622** | frieren | `w1rzdmoy` scale_mult=0.005 | ~2650 | 3.32 | Tanh-squash Arm C scale_mult=0.005 nearing terminal. DNF trajectory. |

## Recently closed (this session)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#627** | nezuko | Per-block grad norm NULL/NULL — Arm A all val=3.269108 sr=3000 (Δsr=+62.5); Arm B mlp_only val=3.265763 sr=2950 (Δsr=+12.5 wrong direction). Arm A loudly hurt (pooling attn+MLP destroys inter-sublayer scale). Arm B noise-level-NULL. Pre-NS per-block magnitude conditioning axis CLOSES. | **CLOSED 08:50 UTC — 45th axis.** |
| **#623** | thorfinn | Schedule-Free Adam on aux NULL/NULL decisive. Both arms DNF val~3.31. Aux WSD cooldown load-bearing. Aux side saturated across 9 optimizer families. | **CLOSED 08:15 UTC — 44th axis.** |
| **#617** | edward | Lookahead wrapper on aux NULL/NULL. k=5 Δsr=+37.5, k=10 Δsr=+87.5. | **CLOSED 07:10 UTC — 42nd axis.** |
| **#607** | alphonse | LR floor NULL/NULL. Linear damage ∝ floor magnitude × activation duration. Decay-to-zero tail is load-bearing. | **CLOSED 07:45 UTC — 43rd axis.** |

## Recently merged

| PR | Student | Key result |
|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 | **MERGED 11:48 UTC** — current baseline. |

## Current research focus (updated 08:50 UTC)

**Three active frontiers after 45 closed axes:**

**1. LR schedule shape (mostly WSD-internal, now opening cross-family):**
- WSD shape fully pinned within family: shorter (#606 NULL), LR-floor (#607 NULL), WSD longer-cooldown (#647 in-flight), warmup (#651 in-flight)
- **NEW → Cosine LR schedule (#667 nezuko):** First test of a completely different schedule family (cosine vs WSD). Arm A pure cosine. Arm B cosine+WSD-stable-phase.

**2. Body-Muon operator ordering / mechanism:**
- Post-NS momentum position (#658 edward, Arm A in progress — dtype fix applied, spec-norm telemetry confirms expected post-NS drift)
- Nesterov ON/OFF (#660 alphonse, Arm A in progress)

**3. Parameter-space averaging:**
- Polyak EMA on body-Muon (#662 thorfinn, Arm A β=0.999 in progress)

**4. Body-Muon gradient-domain transformations (mostly converging to NULL):**
- Tanh-squash (#622 frieren, Arm C scale_mult=0.005 nearing terminal — DNF trajectory)
- Winsorization (#644 fern, Arm A k=1.5 nearing terminal — borderline DNF)
- Per-block grad norm (#627 nezuko, **CLOSED NULL/NULL 45th axis**)

**Pattern after 45 axes:**
- Aux side FULLY SATURATED (9 optimizer families all NULL)
- Body-Muon gradient-domain heavily explored: GC subtract/amplify/clip all NULL; tanh-squash/winsorization converging to NULL; per-block norm CLOSED
- Body-Muon scalars + LR partitions all closed
- WSD schedule shape exhaustively tested within family (4 axes)
- Remaining open levers: body-Muon operator ordering (#658), Nesterov flag (#660), parameter-space averaging (#662), cosine schedule family (#667)

## Key mechanisms confirmed to date

- **WSD cooldown is load-bearing:** decay-to-zero tail IS the mechanism (shorter → NULL, LR floor → NULL)
- **Aux gradient noise dominant:** no update-rule change, averaging, or warmup helps aux
- **PMuon spectral whitening absorbs magnitude info:** per-block grad norm, gradient clipping, GC operations all NULL
- **COOLDOWN_POWER=1.4 near-optimal within WSD:** NS, scalar scans all optimum-confirmed
- **WSD schedule is superior to naive alternatives** (to be confirmed by #667 cosine test)

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Closed axes reference (45 total)

*PMuon scalars COMPLETE (all 5 pinned):* γ_power=0.4, β_cov=0.95, NS_ITERS=12 (5-pt V-curve), NS coeff cubic (1.5,-0.5,0), ε=1e-12, mu=0.95.

*Body-Muon LR partition FULLY CLOSED:* per-type (#499), sub-MLP (#535), depth-based (#532).

*Body-Muon scalars/wrappers:* WD partition (#482), WD schedule (#503), grad clipping (#513), γ_power ramp (#444), lr fine-scan (#465), Lookahead (#505).

*Aux AdamW update-rule mechanisms FULLY CLOSED (9 families):* AdaBelief (#545), NadamW (#575), AdEMAMix (#585), AMSGrad (#578), Adamax (#583), LAMB (#609), Lion (#604), Lookahead (#617), Schedule-Free Adam (#623).

*Aux scalars/static:* scalar_lr (#460), β1 (#416), β2 by-group (#433), embed eps (#463), aux WD (#466).

*Skylight u/w-floor:* magnitude (#486), phase-out (#522). TARGET_UW=0.35 confirmed.

*Gradient transformation body-Muon:* GC subtract (#553 NULL), column-mean amplify (#588 NULL), clipping (#513 NULL), per-block grad-norm (#627 NULL 45th).

*WSD schedule shape:* shorter-cooldown (#606 NULL 39th), LR floor (#607 NULL 43rd), NS_ITERS cooldown ramp (#559 NULL 38th), decoupled aux cooldown (#448).

*Other:* z-loss (#476), embed init (#440), attn-scale (#480), logit soft-cap (#439), NS adaptive threshold (#447).
