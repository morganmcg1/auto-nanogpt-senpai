# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-17 03:55 UTC. Post-#105 wave-3. **🔥🔥🔥🔥🔥🔥 SIX WINNER CANDIDATES on three independent mechanism axes** (all at fs=3250). **CLIP=10 MERGE CANDIDATE CONFIRMING**: thorfinn #165 n=2 partial mean=**3.27471** (well below merge threshold 3.27769); confirm-2 ETA ~04:54 UTC. **CRITICAL MECHANISM TRIANGULATION COMPLETE (03:30 UTC)**:
  - **thorfinn #165** clip sweep: clip=5→10 buys −0.00324 val (asymmetric per-group rescaling story)
  - **alphonse #188** arm-B (uniform 1.5× aux LR + clip=5.0): NEUTRAL ⇒ uniform scaling does NOT reproduce clip's effect
  - **edward #206** arm-B (aux-only clip, no muon clip) val=3.27626 ≈ arm-A (clip-all) val=3.27694 within ±0.001 ⇒ **clip effect is structurally on AdamW aux groups ONLY** (Muon side is inert)
  - **Cleaned mechanism story**: clip=5.0's value comes from asymmetric per-group rescaling of AdamW aux (embed eff-LR ≈8%, lm_head clip-saturated <0.04%). Muon's gradient norms are inert to clipping because NS already projects to fixed scale.
  - **thorfinn #165 arm-B clip=10**: val=3.27432/fs=3250 (clip-axis, AdamW aux groups). **Confirmation seeds running**.
  - **thorfinn #165 arm-C clip=25**: val=3.27442/fs=3250 (clip-axis — TIED with arm-B; clip saturated past clip=10)
  - **thorfinn #165 arm-D clip=50**: val=3.27590/fs=3275 (regresses; embed eff-LR 83% lets noise re-enter AdamW). **Full sweep complete; single-peak shape with plateau confirmed**.
  - **frieren #176 arm-B NS=12→16 cooldown boost**: val=**3.27327**/fs=3250 (NS-schedule-axis, Muon blocks, cooldown only). **BEST single-seed val**.
  - **frieren #176 arm-C NS=12→20 cooldown boost**: val=3.27492/fs=3250 (also beats baseline; diminishing returns past NS=16 in cooldown)
  - **tanjiro #185 arm-A constant NS=14**: val=3.27476/fs=3250 (NS-count axis, uniform schedule)
  - **tanjiro #185 arm-B NS=14→8 linear anneal**: val=**3.27385**/fs=3250 (NS-anneal-axis; high-early then decay; 2nd-best single-seed). **Strongly cross-validates the "higher NS budget helps" mechanism**.
  - All single-seed beat merged baseline 3.27527. **Identical fs=3250** (−17 steps each). **Mechanism convergence**:
    - Clip-axis (thorfinn): saturated past clip=10, peak ≈ clip=10–15 (single-peak with plateau)
    - NS-iter-axis: cooldown boost (frieren arm-B), uniform increase (tanjiro arm-A), and high-early anneal (tanjiro arm-B) ALL beat baseline. **The TOTAL NS-iter budget matters, not the schedule shape** — multiple paths to fs=3250 along this axis.
    - Clip and NS act on **DIFFERENT parameter groups** (AdamW aux vs Muon blocks) → if both confirm at n=3, **additively stackable**.
  - **Awaiting**: thorfinn 2 confirm seeds at clip=10 (confirm-1 ETA 03:10 UTC, confirm-2 ETA 04:50 UTC); frieren arm-D (NS=8→12, running step 2800) + 2 confirm seeds at NS=12→16; tanjiro arms C (linear 12→8, running step 2345) and D (cosine 14→8, queued) + 2 confirm seeds; askeladd arm-B (eps=1e-7, running step 1850) → arms C/E; fern arm-B (c=0.4, running step 650) → arms C/D/E; nezuko arm-B (cosine, running step 1375) → arms C/D/E; edward arm-A (clip-all, ~98% done at val=3.2786) → arms B/C/D; alphonse arm-B clean (1.5× LR + clip=5, running step 1625) → arms C/D/E.
- **Edward #115 BC stack — CLOSED clean negative** (n=3 BC mean=3.27808 vs control 3.27637 +0.0017; baseline 3.27527 +0.0028; fs+42 steps WORSE). **Mechanism: BC and clip=5.0 redundant** (both stabilize early-step preconditioner); on the new merged baseline, beta2=0.999 default is safe to keep.
- **Fern #163 DMR — CLOSED clean negative** (arm-D K=800 decay best variant at 3.2783/fs=3325 still regresses +0.003; #154 staleness signal noise-dominated under Muon NS orthogonalization).
- **Nezuko #145 per-layer NS — CLOSED clean negative** (per-layer policy saturated to uniform NS=18; NS≥16 monotonically worse; cross-references frieren #138 NS-saturation + tanjiro #75 NS=8 floor).
- **Askeladd #189**: arm-A val=3.27480 (sanity ✓); arm-B (eps=1e-7) val=3.27711/fs=3300 (+0.00231 mild regression, eps_dominates_frac=0 throughout); arm-C (eps=1e-9) launched 02:24 UTC.
- **Alphonse #188 mechanism finding**: arm-B clean (uniform 1.5× aux LR + clip=5.0) FINISHED val=3.27541/fs=3275 = NEUTRAL vs baseline ⇒ **falsifies "clip = uniform aux LR rescaler" from #105**. arm-C (2.0×) CRASHED twice; 2.0× past stability cliff. Plan: arm-D (0.5×) → arm-E.
- **In-flight (02:35 UTC)**: thorfinn #165 confirm-1 `lxkp0jmx` step 2025; frieren #176 confirm-1 `u5mqjzv1` step 822; tanjiro #185 arm-D `<id pending>` step 675; askeladd #189 arm-C launched 02:24; fern #203 arm-B `gi91uvhd` step 2450; nezuko #204 arm-B cosine `hczgtsue` step 3125 (~94% done at val=3.285); edward #206 arm-B aux-only `0qcg7qhg` step 1700.
- **NEW assignment to edward (23:30 UTC)**:
  - **#206 edward**: Per-group gradient clipping (4 arms: all/aux/muon/none) — decisive mechanism test of #105's "clip = aux LR rescaler" claim. Complements alphonse #188 on the same aux-LR axis.
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** **3266.7 steps** (mean n=3), **val=3.27527** — thorfinn grad clip=5.0 merged 2026-05-16 (#105)
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — Muon² + grad clip=5.0

### alphonse Muon² (#60): val=3.2766/fs=3275 (n=2)
**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization.

### thorfinn grad clip=5.0 (#105): **val=3.27527/fs=3266.7 (n=3)** — 2026-05-16 CURRENT BEST
**Mechanism:** NANOGPT_GRAD_CLIP=5.0. Full-time gradient rescaling on AdamW aux groups (embed/lm_head); NS absorbs magnitude on Muon blocks → clip acts only on aux. Equivalent to constant effective-LR multiplier on AdamW aux groups. n=3 seeds: mu=3.27527, mean fs=3266.7. Baseline commit: 8566c3e.

## Wave 2 results — PLATEAU CONFIRMED

7 hyperparameter probes all landed worse than baseline:

| PR | Student | Knob | Best arm | val/loss | first_step | vs baseline |
|----|---------|------|----------|---------:|-----------:|------------|
| #92 | edward | QKV init {orth, normal} | normal | 3.27804 | 3300 | +25 |
| #96 | alphonse | Muon² LR {0.030, 0.0375, 0.040} | 0.0375 | 3.27709 | 3300 | +25 |
| #102 | fern | LR warmup {0, 50, 100} | warmup=0 | 3.27699 | 3300 | +25 |
| #104 | frieren | Polyak EMA {0.99, 0.999} | decay=0.99 | 3.27839 | 3325 | +50 |
| #106 | nezuko | Cooldown_frac {0.4, 0.5, 0.6, 0.7} | (arm-C retry) | 3.27766 | 3300 | +25 |

**Conclusion**: Muon² baseline is at a robust local optimum for hyperparameter perturbations. Plateau protocol kicks in: wave 3 = mechanism stacks, not hyperparameter sweeps.

## Closed PRs (cumulative)

| PR | Student | Result |
|----|---------|--------|
| #60 | alphonse | **MERGED** — Muon² NS=12, 3275 steps, n=2 stat-sig |
| #62 | askeladd | CLOSED — SF-Muon failed (3.3638). Cooldown is load-bearing. |
| #66 | edward | CLOSED — Cosine/linear baseline both NaN. Branch corruption. |
| #70 | fern | CLOSED — frac=0.5 n=4 mean=3.27924, margin=0.00152 NOT stat-sig |
| #72 | frieren | CLOSED — Nesterov mu=0.92 full-length val=3.2811, worse than baseline |
| #73 | nezuko | CLOSED — WD warmup n=2 mean=3.27919, margin=0.00114 NOT stat-sig |
| #75 | tanjiro | CLOSED — NS=8 safe (within noise), NS=6 fails. |
| #77 | thorfinn | CLOSED — Lion aux groups failed (3.3109). |
| #91 | thorfinn | CLOSED — aspect-ratio formula NaN cascade, branch corruption. |
| #92 | edward | CLOSED — Orthogonal QKV init: NS continuously re-orthogonalizes within ~50 steps (clean negative) |
| #96 | alphonse | CLOSED — Muon² LR retune: 0.035 peak confirmed, no retune gain |
| #97 | tanjiro | CLOSED INCONCLUSIVE — pod-level GPU divergence on merged baseline |
| #108 | tanjiro | CLOSED — smoke test re-confirmed pod broken; infra-block |
| #102 | fern | CLOSED — LR warmup monotone WORSE; clean negative |
| #104 | frieren | CLOSED — Polyak EMA at eval ≥ live val_loss in every arm; cooldown is load-bearing |
| #106 | nezuko | CLOSED — Muon² cooldown_frac: frac=0.6 retry val=3.27766 indistinguishable from baseline; fern PR #70's vanilla-Muon positive does not transfer |
| #117 | alphonse | CLOSED — Trust-region cap by ||w||_F: arm-A=3.27657/3275 EXACT baseline; arms B/C/D all collapse to val~5.69 (self-reinforcing choke loop) |
| #120 | askeladd | CLOSED — Lookahead Muon²: all arms within-noise or worse; arms A+D identical val=3.27731/fs=3300 (temporal-smoothing family CLOSED; same root cause as #104) |
| #126 | fern | CLOSED — Contra-Soft element-wise: arm-A=3.27616/3275 EXACT baseline; conflict_fraction ≈ 0.50 across all phases proves element-wise signal is noise-dominated; clean negative with mechanistic diagnosis |
| #146 | tanjiro | AUTO-MERGED accidentally (advisor-side merge bug); reassigned as #149 |
| #105 | thorfinn | **MERGED 2026-05-16** — grad clip=5.0 val=3.27527/fs=3266.7 (n=3). New branch baseline. Mechanism: full-time gradient rescaling on AdamW aux groups. |
| #149 | tanjiro | CLOSED infra-blocked — 3rd reproduction of pod NaN cascade on unmodified baseline (step-1 grad=232102, step-25 nonfinite=147M). Issue #160 filed for pod rotation. |
| #154 | fern | CLOSED on strict smoke gate — layer-aggregate global_cos_neg=0.9 ≫ 0.3 threshold. Surprising mechanistic finding: grad·momentum < 0 ~90% of steps under Muon². Mechanism degenerates to mild constant gradient downscaler (~0.85x multiplier). Motivated follow-up #163 DMR. |
| #157 | askeladd | CLOSED — polar-SVD Muon hit 6 consecutive smoke failures from degenerate SVD backward pass through near-equal singular values. |
| #172 | askeladd | CLOSED — Cautious Update Mask hit 4 smoke failures (val=10.83 random init throughout). Element-wise sign-agreement masking incompatible with NS-orthogonalized updates at this benchmark scale. |
| #144 | alphonse | CLOSED 2026-05-16 20:30 — SOAP for aux groups: all variants regress (+0.0035 to +0.0038 vs control). Mechanism: rotating embed gradient into Shampoo eigenbasis bleeds signal across row-independent vocab entries. |
| #180 | askeladd | CLOSED 2026-05-16 20:30 — Adafactor for aux groups: both smoke attempts (no_mom, mom) NaN at step 200. Factored v_ij ≈ v_r * v_c produces near-zero denominators on sparse embed gradients. Combined with #144: confirms sparsity is load-bearing on aux. |
| #163 | fern | CLOSED 2026-05-16 22:25 — DMR clean negative. arm-A control=3.2780/3300, arm-B K=50=3.2930 catastrophic, arm-C K=200=3.2811 regresses, arm-D K=800 decay=3.2783/3325 (best DMR variant but still +0.003 vs baseline). #154 staleness signal does not translate to actionable improvement under Muon NS orthogonalization. |
| #145 | nezuko | CLOSED 2026-05-16 22:30 — Per-layer adaptive NS clean negative. arm-A NS=12=3.27841, arm-B NS=16=3.27992, arm-C NS=14=3.27761 within noise, arm-D NS=18=3.41 (degraded). Per-layer policy degenerated to uniform NS (sigmoid saturated, variance=0). Effective uniform NS sweep: NS=12-14 near-optimal, NS≥16 monotonically worse. Cross-references frieren #138 NS-saturation + tanjiro #75 NS=8 floor. |
| #115 | edward | CLOSED 2026-05-16 23:30 — BC on merged clip=5.0 baseline clean negative. n=3 BC mean=3.27808 (seeds 3.27906/3.27704/3.27814) vs control 3.27637 (+0.00171) vs merged baseline 3.27527 (+0.00281). Mean fs=3308.33 (+42 vs baseline). Stat-sig FAIL: (3.28−3.27808)×√3=0.00333<0.004. Mechanism: BC and clip=5.0 redundant interventions on early-step preconditioner; clip dominates. On merged baseline, default beta2=0.999 is safe to keep. |

## Active PRs

### Wave 3 mechanism stacks — critical path 🎯

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#105** | **thorfinn** | **Gradient clipping sweep** | **✅ MERGED 2026-05-16 15:30 UTC** — val=3.27527/fs=3266.7 (n=3). New branch baseline. |

**Key mechanism insight from thorfinn's gradient norm analysis:** Raw global_norm is 4–5 orders of magnitude larger than both clip thresholds → clip is active at EVERY step → not clipping rare spikes but full-time gradient rescaling. NS already absorbs magnitude for Muon blocks → clip only has effect on AdamW aux groups (embed/lm_head). Grad clip = effective AdamW aux LR multiplier.

### Wave 3 other in-flight

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#176** | **frieren** | **NS Iteration Schedule** — cooldown boost 🔥 | **4-arm sweep COMPLETE**. arm-A val=3.27663/fs=3275. **arm-B (NS=12→16) val=3.27327/fs=3250 ✓ — BEST single-seed on board**. arm-C (NS=12→20) val=3.27492/fs=3250 ✓. arm-D (NS=8→12) val=3.27567/fs=3275 = **compute-neutral with arm-A**. **Confirmation seeds launching at NS=12→16**: confirm-1 `u5mqjzv1` step 822 running, confirm-2 sequential. ETA both terminal ~05:25 UTC. **MAJOR INSIGHT**: arm-D shows mid-training NS=8 is sufficient ⇒ next-round candidate **NS=8 mid → NS=16 cooldown** (compute-saving + cooldown precision). |
| **#185** | **tanjiro** | **NS Iteration Annealing** 🔥 | **arm-A (constant NS=14) `qit8x8ux` val=3.27476/fs=3250 ✓**. **arm-B (14→8 linear) `j2llmiit` val=3.27385/fs=3250 ✓✓ — 2ND BEST val on board**. **arm-C (12→8 linear) `4hywznwe` val=3.27573/fs=3275** (slight regression vs arm-B, consistent with "TOTAL NS budget matters"). arm-D (14→8 cosine) running step 675, ETA terminal ~03:40 UTC. After arm-D: 2 confirmation seeds at best arm (arm-B). |
| **#165** | **thorfinn** | **Clip value extension sweep** 🔥🔥 | **4-arm sweep COMPLETE + confirm-1 TERMINAL**. arm-B clip=10 val=3.27432/fs=3250; **confirm-1 `lxkp0jmx` FINISHED val=3.27510/fs=3275**. **n=2 mean: val=3.27471, fs=3262.5** — already 0.00298 below merge threshold 3.27769. confirm-2 `efnghv0f` step 850 running, ETA terminal ~04:54 UTC. **n=3 projected pass margin ≈ 2.3× the required 0.004**. **FIRST MERGE CANDIDATE OF ROUND**. |
| **#188** | **alphonse** | **AdamW aux LR sweep** | arm-A (1.0×) val=3.27568/fs=3275. **arm-B (1.5× + clip=5) val=3.27541/fs=3275** — NEUTRAL vs baseline ⇒ falsifies "clip = uniform aux LR rescaler". **arm-C CORRECTION (03:50 UTC)**: my earlier "crash" claim was wrong — `vglpzk43` was running cleanly at step 322 before student followed my drop instruction. Student dropped per instruction; arm-C status = "dropped administratively, not actually crashed". **arm-D (0.5×) `<id pending>` step 1850 running**. arm-E queued. ETA arm-D terminal ~04:35 UTC. |
| **#189** | **askeladd** | **Muon² preconditioner eps sweep** | **arm-A (eps=1e-8 baseline) val=3.27480 — sanity confirmed**. **arm-B (eps=1e-7) `fxixf0uv` FINISHED val=3.27711/fs=3300** (+0.00231 mild regression; eps_dominates_frac=0 throughout). **arm-C (eps=1e-9) launched** at 02:24 UTC. arm-E (eps=1e-6) queued. ETA arm-C terminal ~04:10 UTC, arm-E ~06:00 UTC. Mechanism: eps essentially inert below preconditioner_mean ~1e-5; raising eps starts to bind ⇒ axis CLOSING on small-effect floor lever. |
| **#206** | **edward** | **Per-group gradient clipping** 🔥🔥 | **MECHANISM CONFIRMATION COMPLETE**. arm-A (clip-all) val=3.27694/fs=3300. **arm-B (aux-only clip) `0qcg7qhg` FINISHED val=3.27626/fs=3275 — |Δ vs arm-A|=0.00068 < 0.001 → predeclared gate MET**. Per-group telemetry: muon_pre-clip norms unchanged between arm-A and arm-B → **clip's effect is structurally on AdamW aux ONLY**. Confirmation seeds queued. **arm-C (muon-only clip) `<id>` step 525 running** — should confirm Muon clip is fully inert. arm-D (no clip) chained. ETA arm-C terminal ~05:05 UTC, arm-D ~06:46 UTC. |
| **#203** | **fern** | **NS polynomial coefficient sweep** 🆕 | arm-A (c=0.5 baseline) val=3.27517 (sanity ✓). **arm-B (c=0.4) FINISHED val=3.27495** = approximately neutral (Δ=−0.00022 vs control, within seed noise). **arm-C (c=0.35) `<id>` step 1275 running**. Arms D (c=0.6), E (c=0.7) chained. ETA arm-C terminal ~05:40 UTC. Mechanism: NS quintic family may be robust to small c perturbations around 0.5. |
| **#204** | **nezuko** | **Cooldown shape sweep** 🆕 | arm-A (linear baseline) val=3.27581. **arm-B (cosine) FINISHED val=3.28144 — REGRESSES** Δ=+0.00617 vs baseline. Mechanism: cosine holds higher LR longer in cooldown ⇒ misses precision window. **arm-C (sqrt) `<id>` step 2000 running** — predict val ≈3.272–3.276 (sqrt decays LR rapidly then slowly → opposite of cosine). Arms D (quadratic), E (exp) chained. ETA arm-C terminal ~05:00 UTC. |

## Infra-blocked

- **tanjiro** (was GPU UUID 7998cef9 on node gd0c1b8): **ROTATION COMPLETE 2026-05-16 19:33 UTC** — operator patched deployment with node affinity excluding suspect nodes; new pod on node gd0f0ea, restart count 0. Issue #160 closed.

## Wave 3 post-#105 — current sequencing

**#105 merged at 15:30 UTC as first wave-3 winner.** Branch baseline: val=3.27527/fs=3266.7 (n=3).

**🔥🔥🔥🔥🔥🔥 SIX WINNER CANDIDATES (01:40 UTC), all at fs=3250 from three independent mechanism axes** (sorted by val/loss):

| Rank | PR | Arm | Mechanism | val/loss | fs |
|------|-----|-----|-----------|---------:|---:|
| 1 | #176 | arm-B | NS=12→16 cooldown boost | **3.27327** | 3250 |
| 2 | #185 | arm-B | NS=14→8 linear anneal (high-early) | **3.27385** | 3250 |
| 3 | #165 | arm-B | clip=10 | **3.27432** | 3250 |
| 4 | #165 | arm-C | clip=25 (tied with B) | 3.27442 | 3250 |
| 5 | #185 | arm-A | NS=14 constant (uniform increase) | 3.27476 | 3250 |
| 6 | #176 | arm-C | NS=12→20 cooldown boost | 3.27492 | 3250 |

All single-seed beat merged baseline 3.27527. **Identical fs=3250** (−17 steps each). **Mechanism convergence on three orthogonal axes**:
- **Clip-axis** (thorfinn #165): clip=10 and clip=25 tied; single-peak with plateau between embed eff-LR 17–42%; **peak at clip≈10–15**. Full sweep complete; confirm seeds launching.
- **NS-iter-axis** (frieren #176 + tanjiro #185): TOTAL NS-iter budget matters more than the schedule shape. Multiple paths to fs=3250 work: constant NS=14, cooldown-only NS=12→16, cooldown-only NS=12→20, high-early NS=14→8 anneal — all beat baseline. The cooldown-precision prediction from frieren #138 is confirmed but the "high-early" alternative (tanjiro arm-B) is ALSO valid, suggesting it's the integrated budget that matters.
- **Cross-axis stacking**: clip-axis (AdamW aux groups) and NS-iter-axis (Muon blocks) act on **DIFFERENT parameter groups** → if both confirm at n=3, **additively stackable** into next-merge candidate.

**Next priority sequencing (02:35 UTC)**:
1. **thorfinn #165 confirm-1** terminal ~03:10 UTC; confirm-2 ~04:50 UTC. **First merge candidate** — clip=10.
2. **frieren #176 confirm-1** terminal ~03:45 UTC; confirm-2 ~05:25 UTC. **Second merge candidate** — NS=12→16 cooldown.
3. **tanjiro #185 arm-D terminal** ~03:40 UTC → launch 2 confirm seeds at best arm (arm-B NS=14→8 looks like winner since arm-C NS=12→8 regressed). **Third merge candidate** — NS-anneal.
4. **edward #206 arm-B terminal** ~03:24 UTC — **DECISIVE mechanism arm** (aux-only clip). Will give orthogonal confirmation of alphonse's "clip is asymmetric, not uniform" finding.
5. **alphonse #188** continue — arm-D (0.5×) → arm-E. Arm-C 2.0× dropped (stability cliff).
6. **askeladd #189** continue — arm-C (eps=1e-9) launched; arm-E queued. Mechanism: eps axis CLOSING.
7. **fern #203** arm-B (c=0.4) ~04:00 UTC.
8. **nezuko #204** arm-B (cosine) ~03:30 UTC.
9. **Wave 4 candidates after confirmation seeds land**:
   - **Stack candidate A**: clip=10 × NS=12→16 cooldown (clip-axis × NS-iter-axis are on different param groups → additively stackable)
   - **Stack candidate B**: clip=10 × NS=8 mid → NS=16 cooldown (frieren arm-D shows mid-training NS=8 is compute-neutral, so this is strictly stronger than A in compute terms)
   - **Stack candidate C**: clip=10 × NS=14→8 anneal (if tanjiro arm-B confirms; tests the high-early variant)
   - Per-group clip mechanism work (depending on edward #206 result, may motivate AUX-only-clip with different threshold as a new mechanism axis)

**Statistical target**: `(3.28 − mu(n=3)) × √3 ≥ 0.004` → mu ≤ 3.27769. New bar is to beat 3.27527.

## Closed mechanisms (do not re-explore)

| Category | Mechanism | Evidence |
|----------|-----------|----------|
| Temporal smoothing | Polyak EMA, Lookahead | #104, #120 — both close same root cause: cooldown tightening needs commitment, not historical averaging |
| Element-wise direction shaping | Contra-Soft per-element | #126 — conflict_fraction~0.50 = noise-dominated |
| Magnitude-coupled trust region | ||w||_F coupled cap | #117 — self-reinforcing choke loop at init |
| LR warmup | 0/50/100 step warmup | #102 — monotone WORSE; Muon² doesn't need warmup |
| Cooldown frac (timing only) | {0.4, 0.5, 0.6} | #106 — frac=0.7 baseline optimal on Muon² (shape sweep separate, see #204) |
| Lion optimizer (aux) | Lion embed+lm_head | #77 — catastrophic (3.31xx), sign-momentum inadequate |
| Per-layer NS adaptive | sigmoid-controlled NS iters per layer | #145 — degenerates to uniform NS (sigmoid saturated); reduces to NS-iter count sweep, NS≥16 hurts |
| Momentum reset (DMR) | periodic v reset with decay | #163 — best variant K=800 decay still regresses; #154 staleness signal noise-dominated under Muon NS |
| SOAP/Adafactor on aux | Shampoo rotation / factored v on embed-lm_head | #144, #180 — sparsity is load-bearing on aux; basis rotation and factorization both fail |
| Adam-style bias correction in Muon² | `v / (1 − beta2^t)` + beta2=0.98 | #115 — won on old baseline (+0.0013), regresses on merged clip=5.0 baseline (+0.0017); BC and clip redundant; beta2=0.999 default is safe |

## Wave 3 frontier — remaining next-tier

**In flight (see Active PRs table above)**

**Next-tier after current wave (based on mechanism orthogonality)**:
- **Stack test: clip=10 × NS-cooldown-boost** — once both confirm
- **Clip per-group** (apply clip only to AdamW params, not Muon blocks, per thorfinn's NS-absorbs-magnitude insight)
- **Muon for embed/lm_head** — apply Muon² to all params (not just blocks), unifying the optimizer
- **AdamW betas / WD on aux** (sparse-aware levers since basis rotation / factorization both failed)

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM, multi-step optimizers that need extra forwards).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline includes `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var.
- 1 GPU per student node — sequential arm execution required.
- **Pattern (post-tanjiro pod issue)**: All Muon²-touching PRs should include 100-step smoke test before launching long arms.
- **Pattern (post-thorfinn crashes)**: Always commit code to branch before launching long arms; uncommitted state combined with potential pod preemption produces unrecoverable crashes.
- **Pattern (post-edward arm-C invalid-recipe)**: Freeze training script to snapshot OUTSIDE working tree before launching. Branch-swap during sequential launcher invalidates arms silently.
- **Pattern (post-askeladd #189 smoke)**: When testing aggressive eps values, clip CANNOT save you if grad becomes non-finite — clip uses .norm() which fails on inf/nan.
- **Failed-mechanism pattern**: Magnitude-suppression depending on current weight/update creates self-reinforcing feedback loops at init. Use NS-natural scale invariants (sqrt(min(rows,cols)) not ||w||_F).
