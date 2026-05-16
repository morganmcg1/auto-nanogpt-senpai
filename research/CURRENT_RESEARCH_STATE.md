# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-16 23:30 UTC. Post-#105 wave-3. **🔥🔥🔥🔥 FOUR WINNER CANDIDATES on three independent mechanism axes** (all clustering at fs=3250):
  - **thorfinn #165 arm-B clip=10**: val=3.2743/fs=3250 (clip-axis, AdamW aux groups)
  - **thorfinn #165 arm-C clip=25**: val=3.2744/fs=3250 (clip-axis confirmation — clip=10/25 effectively tied; ⇒ aux LR is saturated past clip=10 since global_norm ~55000 ⇒ both clip values bind every step)
  - **frieren #176 arm-B NS=12→16 cooldown boost**: val=3.2733/fs=3250 (NS-schedule-axis, Muon blocks, cooldown only)
  - **tanjiro #185 arm-A constant NS=14**: val=3.2748/fs=3250 (NS-count axis, Muon blocks, uniform schedule)
  - All at fs=3250 (−17 steps vs baseline). Both NS results (frieren cooldown + tanjiro constant) independently confirm **higher NS iterations help**. Clip-axis is mechanically distinct (AdamW aux vs Muon blocks). **If clip and NS confirm at n=3, additively stackable** — best next merge is likely a clip × NS-iter stack.
  - **Awaiting**: thorfinn arm-D (clip=50), tanjiro arms B/C/D (anneal variants), frieren arms C (NS=12→20, running)/D (NS=8→12, queued), then confirmation seeds.
- **Edward #115 BC stack — CLOSED clean negative** (n=3 BC mean=3.27808 vs control 3.27637 +0.0017; baseline 3.27527 +0.0028; fs+42 steps WORSE). **Mechanism: BC and clip=5.0 redundant** (both stabilize early-step preconditioner); on the new merged baseline, beta2=0.999 default is safe to keep.
- **Fern #163 DMR — CLOSED clean negative** (arm-D K=800 decay best variant at 3.2783/fs=3325 still regresses +0.003; #154 staleness signal noise-dominated under Muon NS orthogonalization).
- **Nezuko #145 per-layer NS — CLOSED clean negative** (per-layer policy saturated to uniform NS=18; NS≥16 monotonically worse; cross-references frieren #138 NS-saturation + tanjiro #75 NS=8 floor).
- **Askeladd #189 arm-D eps=1e-10 CONFIRMED unsafe** (3rd smoke `z4gco0kb` NaN with clip=5.0); arm-A (eps=1e-8) `6j6xaer1` running step 1375.
- **In-flight**: Tanjiro #185 arm-B `j2llmiit` step 1650; Alphonse #188 arm-B `t7chrr8p` step 1275; Thorfinn #165 arm-D queued; Frieren #176 arm-C `odmxk60i` step 2300; Fern #203 arm-A `qvutgp97` step 25 (just launched); Nezuko #204 arm-A `mcqv2g69` step 725.
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
| **#176** | **frieren** | **NS Iteration Schedule** — cooldown boost 🔥 | arm-A 3rd `sara3jjw` val=3.2766/fs=3275 ✓. **arm-B (NS=12→16) `2xp7ut5r` FINISHED val=3.2733/fs=3250 ✓✓ — BEATS BASELINE single-seed**. arm-C (NS=12→20) and arm-D (NS=8→12 balanced) queued. After all arms terminal: 2 confirmation seeds at best arm. Mechanism: #138 cooldown-precision prediction confirmed. |
| **#185** | **tanjiro** | **NS Iteration Annealing** 🔥 | Smoke `ugzl4jqe` val=4.869 PASS. **arm-A (constant NS=14) `qit8x8ux` FINISHED val=3.2748/fs=3250 ✓✓ — BEATS BASELINE single-seed**. arm-B (14→8 linear) `j2llmiit` step 1650 running. Arms C/D queued. **Strongly cross-validates frieren #176 finding: higher NS iterations help (NS=14 constant vs NS=12→16 cooldown both at fs=3250).** |
| **#165** | **thorfinn** | **Clip value extension sweep** 🔥🔥 | arm-A `f6ym89r7` FINISHED val=3.27756/fs=3300. **arm-B (clip=10) `84um64gj` FINISHED val=3.2743/fs=3250 ✓✓ — BEATS BASELINE single-seed**. **arm-C (clip=25) `2btntm04` FINISHED val=3.2744/fs=3250 ✓✓ — TIED with arm-B**. Clip=10 and clip=25 effectively tied → aux LR saturates past clip=10 (global_norm ≈55000 ⇒ both bind every step). arm-D (clip=50) queued. After all arms terminal: launch 2 confirmation seeds at best arm. **Strongest single-axis merge candidate.** |
| **#188** | **alphonse** | **AdamW aux LR sweep** | Smoke `a3jblwez` PASS. **arm-A (1.0× baseline) `1yu9sfbb` FINISHED val=3.2757/fs=3275** (within noise of baseline). arm-B (1.5×) `t7chrr8p` step 1275 running. Arms C/D/E sequential. Direct test of clip=5.0 → aux LR rescaler mechanism. |
| **#189** | **askeladd** | **Muon² preconditioner eps sweep** | First 2 smokes ran with NANOGPT_GRAD_CLIP=0 (PR-body bug). 3rd smoke `z4gco0kb` with clip=5.0 AND eps=1e-10 ALSO NaN; arm-D dropped. smoke-1e-9-clipped-v2 `mpxwictd` step 100 val=4.81 PASS. **arm-A (eps=1e-8 control) `6j6xaer1` step 1375 running**. Arms B/C/E sequential. |
| **#206** | **edward** | **Per-group gradient clipping** 🆕 | NEW 23:30 UTC. 4 arms: all/aux/muon/none. Decisive mechanism test of #105's "clip = aux LR rescaler" claim. ~10-line code change; smoke gate then arms A-D sequential. |
| **#203** | **fern** | **NS polynomial coefficient sweep** 🆕 | NEW 22:55 UTC. 5 arms over c∈{0.35,0.4,0.5,0.6,0.7} in Chebyshev quintic family (f(x) = (1.5+c)·x + (-0.5-2c)·x³ + c·x⁵). Tests if Muon² v-EMA-flattened spectrum favors different polynomial than current (a=2, b=-1.5, c=0.5). Env-var NANOGPT_NS_C single-line change. |
| **#204** | **nezuko** | **Cooldown shape sweep** 🆕 | NEW 22:55 UTC. 5 arms over LR-decay curves (linear/cosine/sqrt/quadratic/exp). Orthogonal to her closed #106 (cooldown_frac timing). Env-var NANOGPT_COOLDOWN_SHAPE in `set_hparams`. |

## Infra-blocked

- **tanjiro** (was GPU UUID 7998cef9 on node gd0c1b8): **ROTATION COMPLETE 2026-05-16 19:33 UTC** — operator patched deployment with node affinity excluding suspect nodes; new pod on node gd0f0ea, restart count 0. Issue #160 closed.

## Wave 3 post-#105 — current sequencing

**#105 merged at 15:30 UTC as first wave-3 winner.** Branch baseline: val=3.27527/fs=3266.7 (n=3).

**🔥🔥🔥🔥 FOUR WINNER CANDIDATES (23:30 UTC), all at fs=3250 from three independent mechanism axes**:
- **thorfinn #165 arm-B clip=10**: val=3.2743/fs=3250 (clip-axis on AdamW aux groups)
- **thorfinn #165 arm-C clip=25**: val=3.2744/fs=3250 (clip-axis — TIED with arm-B; clip is saturated past clip=10)
- **frieren #176 arm-B NS=12→16 cooldown boost**: val=3.2733/fs=3250 (NS-iter-schedule on Muon blocks, cooldown only)
- **tanjiro #185 arm-A constant NS=14**: val=3.2748/fs=3250 (NS-iter-count on Muon blocks, uniform schedule)

All single-seed beat merged baseline 3.27527/3266.7. **Identical fs=3250** (−17 steps each). **Mechanism convergence**:
- Clip-axis: arms B (clip=10) and C (clip=25) tied at val ≈ 3.2744 ⇒ the clip threshold is **saturated past clip=10**; both bind every step since global_norm ≈55000 (4 orders of magnitude above threshold).
- NS-iter axis: constant NS=14 (tanjiro) and NS=12→16 cooldown (frieren) both land at fs=3250 ⇒ **higher NS iters help, especially during cooldown** (frieren's val=3.2733 is slightly better, suggesting cooldown-only is more efficient than uniform).
- Clip and NS act on **DIFFERENT parameter groups** → if both confirm at n=3, may be **additively stackable** into next-merge candidate.

**Next priority sequencing (post-arms-complete)**:
1. Once #176 arms C/D terminal, launch 2 confirm seeds at NS=12→16 cooldown.
2. Once #165 arm-D terminal, launch 2 confirm seeds at clip=10 (since clip=10/25 tied, use cheaper threshold).
3. Once #185 arm-B/C/D terminal, evaluate against tanjiro's arm-A; if no anneal variant beats constant NS=14, the NS-iter mechanism is fully described.
4. If clip and NS both confirm, design **clip=10 × NS=12→16 cooldown stack** PR for the next merge.

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
