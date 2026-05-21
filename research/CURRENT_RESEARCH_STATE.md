# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-21 08:15 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Active experiments (8 students, 08:15 UTC — 0 idle)

| PR | Student | Run | Step/3250 | val | Status |
|---|---|---|---|---|---|
| **#658** | edward | pending pickup | — | — | **NEW (07:10 UTC) — Post-NS momentum position in PMuon. Arm A: post_ns (momentum on polar outputs, no repolar). Arm B: post_ns_repolar (momentum on polar outputs + re-apply polar to restore unit spectral norm). Both at mu=0.95. First operator-ordering test in 43 closed experiments.** |
| **#651** | tanjiro | `8m6903wo` Arm A warmup=100 | running | early | LR warmup phase — Arm A warmup_steps=100. Arm B warmup_steps=250 queued after Arm A. |
| **#647** | askeladd | `tk8hizl3` Arm A cf=0.80 | running ~step 944 | early | WSD LONGER cooldown_frac — Arm A cf=0.80. Concurrent torchrun duplicate self-cleaned (06:32 UTC). Arm B cf=0.85 queued after Arm A. |
| **#644** | fern | `5erh0eht` Arm A k=1.5 warmup100-fix | running | early | Winsorization pre-NS — EMA fix iteration 2 (warmup extended 10→100 steps for L_cov transient). |
| **#660** | alphonse | pending pickup | — | — | **NEW (07:45 UTC) — PMuon Nesterov ON/OFF. Arm A: nesterov=False, mu=0.95. Arm B: nesterov=False, mu=0.90 (compensates effective grad weight). First direct ablation of Nesterov flag in 44 closed experiments.** |
| **#622** | frieren | `w1rzdmoy` Arm C scale_mult=0.005 | running | early | tanh-squash follow-up. Arm C 0.005 exercises squash per-frieren telemetry analysis. |
| **#662** | thorfinn | pending pickup | — | — | **NEW (08:15 UTC) — Polyak EMA on body-Muon weights. Arm A: β=0.999 (window ~1000 steps, covers WSD cooldown). Arm B: β=0.9995 (window ~2000 steps). FP32 EMA buffer; swap to EMA at eval, restore for training. First parameter-space averaging test on signal-dominant matrix params.** |
| **#627** | nezuko | `xaaqncix` Arm B mlp-only | running ~step 1275 | 3.59 | Per-block grad L2 norm pre-NS. Arm A all-body finished (sr=3000 NULL). Arm B MLP-only running. |

## Recently closed (this session)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#623** | thorfinn | Schedule-Free Adam on aux NULL/NULL decisive — Arm A r=0 val=3.30923 sr=-1 DNF (Δval=+0.0450); Arm B r=1.0 val=3.30752 sr=-1 DNF (Δval=+0.0432). Mechanism: aux LR cooldown is load-bearing (≥10× shrink over final 30%); SF averaging c_t≈3e-4 at step 3250 cannot match effective step-size reduction of WSD. Polyak-tilt (r=1.0) marginally better by 0.0017 — "less averaging = better" signal direction. **Aux side now fully saturated across 9 optimizer families.** | **CLOSED 08:15 UTC — 44th axis.** |
| **#617** | edward | Lookahead wrapper on aux NULL/NULL — Arm A k=5 val=3.267040 sr=2975; Arm B k=10 val=3.269989 sr=3025. Mechanism: Lookahead's pull-back (1-α) per sync halves effective aux LR. Longer k→worse. | **CLOSED 07:10 UTC — 42nd axis.** |
| **#607** | alphonse | LR floor NULL/NULL — Arm A lr_floor=0.10 val=3.270903 sr=3025 (Δval=+0.00662); Arm B lr_floor=0.05 val=3.266955 sr=2975 (Δval=+0.00268). Linear damage proportional to floor magnitude × activation duration. Decay-to-zero tail is load-bearing. | **CLOSED 07:45 UTC — 43rd axis.** |
| **#604** | tanjiro | Lion on aux NULL/NULL DNF. Lion's sign-of-momentum strips magnitude info from per-group LRs. | **CLOSED 05:50 UTC — 41st axis.** |
| **#609** | askeladd | LAMB trust ratio on aux NULL/NULL DNF. Trust ratio saturates at max_trust=10 entire run (degenerate domain). | **CLOSED 05:00 UTC — 40th axis.** |
| **#606** | fern | WSD shorter cooldown_frac NULL — Arm A cf=0.25 val=3.30081 DNF. Cooldown_frac=0.70 is load-bearing. | **CLOSED 04:30 UTC — 39th axis.** |

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 | **MERGED 11:48 UTC** — current baseline. |

## Current research focus (updated 08:15 UTC)

**Entering body-Muon mechanism and parameter-space domains.** After 44 closed axes exhausting:
- All PMuon scalars (γ_power, β_cov, NS_ITERS, NS coefficients, ε, mu)
- All aux update-rule mechanisms (5/5 AdamW variants + LAMB + Lion + Lookahead + Schedule-Free = 9 optimizer families, all NULL)
- Body-Muon LR partition family (all 3 sub-axes NULL)
- WSD schedule shape (shorter-cooldown, LR-floor, plus longer-cooldown + warmup still in-flight)

**Pattern after 44 axes:**
- Aux side FULLY SATURATED across 9 optimizer families. Aux gradient noise on embed/lm_head/scalars is dominant enough that no update-rule, wrapper, or averaging change helps. What matters is LR magnitude schedule (WSD cooldown).
- Body-Muon gradient-domain: Gradient Centralization (#553 NULL), clipping (#513 NULL), per-block norm (#627 in-flight), tanh-squash (#622 in-flight), Winsorization (#644 in-flight).
- Body-Muon operator-ordering: pre-NS vs post-NS momentum (#658 in-flight NEW).
- Body-Muon Nesterov flag: first direct ablation in 44 experiments (#660 in-flight NEW).
- **NEW: Parameter-space averaging: Polyak EMA on body-Muon eval weights (#662 thorfinn NEW).**

**Open frontiers:**
1. Body-Muon momentum position (pre/post-NS, #658 edward)
2. PMuon Nesterov flag (#660 alphonse)
3. WSD LONGER cooldown (#647 askeladd)
4. LR warmup phase (#651 tanjiro)
5. Body-Muon parameter-space averaging (#662 thorfinn — Polyak EMA β={0.999, 0.9995})
6. Gradient element transformation on body-Muon (#622 frieren, #644 fern, #627 nezuko)

**WSD schedule shape axes:**
- **Shorter-cooldown (CLOSED #606, 39th axis):** NULL — cooldown_frac=0.70 load-bearing.
- **LR floor (CLOSED #607, 43rd axis):** NULL/NULL — decay-to-zero tail load-bearing; linear damage ∝ floor × duration.
- **Longer-cooldown (IN FLIGHT #647):** {0.80, 0.85} — symmetric closure.
- **Warmup phase (IN FLIGHT #651):** {100, 250 steps} — codebase zero-warmup never tested.
- WSD schedule shape now pinned across 4 axes (shorter, floor, longer in-flight, warmup in-flight).

**Body-Muon mechanism — NEW axes opened this session:**
- **Post-NS momentum (#658 edward):** First operator-ordering test. Arm A: post_ns (no repolar). Arm B: post_ns_repolar (restore unit spectral norm after momentum mixing). Mechanism: momentum has lived pre-whitening/pre-NS in all 44 closed experiments — never tested the alternative ordering.
- **Nesterov ON/OFF (#660 alphonse):** First direct ablation of Nesterov flag. Arm A: nesterov=False, mu=0.95. Arm B: nesterov=False, mu=0.90 (compensates effective gradient weighting). Mechanism: Nesterov → `grad.lerp_(momentum, mu)` vs non-Nesterov → `momentum` only.
- **Polyak EMA on body-Muon (#662 thorfinn NEW):** Parameter-space averaging. FP32 EMA of body-Muon matrix params; swap to EMA weights at eval, restore for training. Arm A: β=0.999 (~1000-step window, covers WSD cooldown). Arm B: β=0.9995 (~2000-step window, covers cooldown + late stable). First parameter-space averaging test on signal-dominant (matrix) params.

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Closed axes reference (44 total)

*PMuon scalars COMPLETE:* γ_power=0.4 (#519), β_cov=0.95 (#502), NS_ITERS=12 (#511+#546), NS coeff cubic (1.5,-0.5,0) (#540), ε=1e-12 (#562), mu=0.95 (#570).

*Body-Muon LR partition FULLY CLOSED:* per-type (#499), sub-MLP (#535), depth-based (#532).

*Body-Muon scalars/wrappers:* WD partition (#482), WD schedule (#503), grad clipping (#513), γ_power ramp (#444), lr fine-scan (#465), Lookahead wrapper (#505).

*Aux AdamW scalars/static:* scalar_lr (#460), β1 (#416), β2 by-group (#433), embed eps (#463), aux WD (#466), embed lr (#413 baseline), lm_head lr (#367 baseline).

*Aux update-rule mechanisms FULLY CLOSED (9 families):* AdaBelief (#545), NadamW (#575), AdEMAMix (#585), AMSGrad (#578), Adamax (#583), LAMB (#609), Lion (#604), Lookahead (#617), Schedule-Free Adam (#623).

*Skylight u/w-floor:* magnitude (#486), phase-out (#522). TARGET_UW=0.35 confirmed.

*Gradient transformation body-Muon:* GC subtraction (#553 NULL), column-mean amplification (#588 NULL), clipping (#513 NULL).

*WSD schedule shape:* shorter-cooldown (#606 NULL 39th), decoupled aux cooldown (#448), LR floor (#607 NULL 43rd). Longer-cooldown and warmup in-flight.

*NS schedule:* NS_ITERS cooldown ramp (#559 NULL 38th).

*Other:* z-loss (#476), embed init (#440), attn-scale (#480), logit soft-cap (#439), NS adaptive threshold (#447).
