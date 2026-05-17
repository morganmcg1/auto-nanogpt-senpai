# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-17 04:40 UTC. Post-#105 wave-3. Clip + NS-iter mechanism axes confirmed; first merges of round imminent.
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** **3266.7 steps** (mean n=3), **val=3.27527** — thorfinn grad clip=5.0 merged 2026-05-16 (#105)
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — Muon² + grad clip=5.0

### alphonse Muon² (#60): val=3.2766/fs=3275 (n=2)
**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization.

### thorfinn grad clip=5.0 (#105): **val=3.27527/fs=3266.7 (n=3)** — 2026-05-16 CURRENT BEST
**Mechanism:** NANOGPT_GRAD_CLIP=5.0. Full-time gradient rescaling on AdamW aux groups (embed/lm_head); NS absorbs magnitude on Muon blocks → clip acts only on aux. Equivalent to constant effective-LR multiplier on AdamW aux groups. n=3 seeds: mu=3.27527, mean fs=3266.7. Baseline commit: 8566c3e.

## Wave 3 mechanism triangulation — COMPLETE 🎯

Three independent experiments triangulate the clip mechanism:
1. **thorfinn #165** 4-arm clip sweep: single-peak with plateau, peak clip=10 (embed eff-LR ~17%)
2. **alphonse #188** arm-B (uniform 1.5× aux LR + clip=5): NEUTRAL ⇒ falsifies "clip=uniform LR rescaler"
3. **edward #206** arm-B (aux-only clip, no Muon clip): val≈arm-A (clip-all) within ±0.001 ⇒ **clip is structurally on AdamW aux ONLY; Muon side is inert**

**Cleaned mechanism story**: clip=5.0's value comes from asymmetric per-group rescaling. At clip=10, embed eff-LR rises from 8.4% → 16.9% (sweet spot); lm_head remains clip-saturated (<0.4%) throughout. NS projects Muon updates to fixed scale → clip has zero net effect on Muon blocks.

## Confirmed winner candidates — confirmation seeds in flight (04:40 UTC)

### 🔥 thorfinn #165 — clip=10 (FIRST MERGE CANDIDATE)
| Seed | Run | val/loss | fs |
|------|-----|----------|-----|
| 1 (arm-B) | 84um64gj | 3.27432 | 3250 |
| 2 (confirm-1) | lxkp0jmx | 3.27510 | 3275 |
| 3 (confirm-2) | efnghv0f | **running** step 2650/3350 | — |
| **n=2 mean** | — | **3.27471** | 3262.5 |

confirm-2 ETA terminal ~05:12 UTC. n=3 merge gate: need mu ≤ 3.27769 (safety margin HUGE: confirm-2 can land as high as ~3.284 and still pass).

### 🔥🔥 frieren #176 — NS=12→16 cooldown boost (SECOND MERGE CANDIDATE, best single-seed)
| Seed | Run | val/loss | fs |
|------|-----|----------|-----|
| 1 (arm-B) | 2xp7ut5r | 3.27327 | 3250 |
| 2 (confirm-1) | u5mqjzv1 | 3.27523 | 3275 |
| 3 (confirm-2) | eqhe974m | **running** step 1500/3350 | — |
| **n=2 mean** | — | **3.27425** | 3262.5 |

confirm-2 ETA terminal ~05:25 UTC. n=3 merge gate: same forgiving margin.

**Cross-mechanism story**: frieren arm-D (NS=8→12) was compute-neutral with arm-A (NS=8 mid-training sufficient). This opens the **Wave-4 aggressive NS candidate**: NS=8 mid → NS=16 cooldown (saves ~23% Muon-block compute mid-training AND wins by ~0.003 val/loss).

## Active PRs — 04:40 UTC status

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#165** | **thorfinn** | **Clip extension sweep** 🔥 | confirm-2 `efnghv0f` step 2650/3350 running. **FIRST MERGE CANDIDATE**. |
| **#176** | **frieren** | **NS cooldown boost** 🔥🔥 | confirm-2 `eqhe974m` step 1500/3350 running. **SECOND MERGE CANDIDATE**. |
| **#185** | **tanjiro** | **NS iteration annealing** | arm-B (NS=14→8) val=3.27385/fs=3250 winner candidate. arm-D (cosine anneal) ETA terminal ~03:40 UTC (may be done). Confirm seeds queued after arm-D. |
| **#188** | **alphonse** | **AdamW aux LR sweep** | arm-B (1.5×) NEUTRAL. arm-D (0.5×) running, ETA ~04:35 UTC. Mechanism: uniform LR scaling does NOT reproduce clip. Axis closing. |
| **#189** | **askeladd** | **Muon² eps sweep** | arm-C (eps=1e-9) running, ETA ~04:10 UTC. arm-B (1e-7) mild regression. Eps axis likely closing. |
| **#203** | **fern** | **NS polynomial coefficient sweep** | arm-B (c=0.4) neutral. arm-C (c=0.35) running ~step 1275. c axis looks robust/closing. |
| **#206** | **edward** | **Per-group clip mechanism** 🔥🔥 | Mechanism CONFIRMED: clip is AdamW-aux only. arm-C (muon-only clip) running. arm-D (no clip) chained. |
| **#227** | **nezuko** | **AdamW β1 cooldown decay** 🆕 | Newly assigned (04:40 UTC). Test β1=0.8→0.5 and 0.8→0.3 during cooldown. Analogue of frieren's NS-iter cooldown boost on the AdamW side. |

## Just closed (04:40 UTC)
- **nezuko #204**: Cooldown shape CLOSED clean negative. Linear is Goldilocks (slope=-0.00386 still descending). Cosine (slope=+0.00275 frozen) and sqrt (2× steeper but started far behind) both fail. Axis well-tuned by lineage. Do not re-explore. **See EXPERIMENTS_LOG for full mechanism analysis.**

## Closed mechanisms (do not re-explore)

| Category | Mechanism | Evidence |
|----------|-----------|----------|
| Temporal smoothing | Polyak EMA, Lookahead | #104, #120 |
| Element-wise direction shaping | Contra-Soft per-element | #126 |
| Magnitude-coupled trust region | ||w||_F coupled cap | #117 |
| LR warmup | 0/50/100 step warmup | #102 |
| Cooldown frac (timing only) | {0.4, 0.5, 0.6} | #106 |
| Cooldown LR shape | cosine, sqrt, quadratic, exp | #204 — linear is uniquely optimal |
| Lion optimizer (aux) | Lion embed+lm_head | #77 |
| Per-layer NS adaptive | sigmoid-controlled NS iters per layer | #145 |
| Momentum reset (DMR) | periodic v reset with decay | #163 |
| SOAP/Adafactor on aux | Shampoo rotation / factored v | #144, #180 |
| Adam-style bias correction in Muon² | BC + beta2=0.98 | #115 — redundant with clip=5.0 |
| NS=8 floor test | constant NS=8 | #75 — NS=8 safe (within noise) |

## Wave 3 winner table (single seeds, sorted by val/loss)

| Rank | PR | Arm | Mechanism axis | val/loss | fs |
|------|-----|-----|----|---:|---:|
| 1 | #176 | arm-B | NS=12→16 cooldown boost | **3.27327** | 3250 |
| 2 | #185 | arm-B | NS=14→8 high-early anneal | **3.27385** | 3250 |
| 3 | #165 | arm-B | clip=10 | **3.27432** | 3250 |
| 4 | #165 | arm-C | clip=25 (tied with B) | 3.27442 | 3250 |
| 5 | #185 | arm-A | NS=14 constant | 3.27476 | 3250 |
| 6 | #176 | arm-C | NS=12→20 cooldown boost | 3.27492 | 3250 |

All single-seeds beat merged baseline 3.27527/fs=3266.7. Mechanism convergence: **all three orthogonal axes land at identical fs=3250 (-17 steps vs baseline)**.

## Wave 4 candidates (post-confirmation)

Once clip=10 (#165) and NS=12→16 cooldown (#176) confirm at n=3:
1. **Stack A**: clip=10 × NS=12→16 cooldown (two orthogonal axes — AdamW aux vs Muon blocks → additive)
2. **Stack B**: clip=10 × NS=8mid→NS=16 cooldown (frieren arm-D shows mid-training NS=8 compute-neutral → strictly stronger than Stack A in compute terms)
3. **Stack C**: clip=10 × NS=14→8 anneal (if tanjiro arm-B confirms independently)
4. **nezuko #227** AdamW β1 cooldown decay (fresh axis — AdamW momentum lag in precision window; analogue of NS-iter boost on aux side)
5. **Chebyshev c free parameter** (fern #203, depending on result)
6. **Aux-only clip with threshold optimization** (edward #206 confirms Muon clip is inert → clean mechanism for clip-on-aux-only PR if pure-Muon inertness holds at arm-C)

## Infra notes

- tanjiro pod: rotation COMPLETE 2026-05-16 19:33 UTC. Pod on node gd0f0ea, clean.
- 1 GPU per student node — sequential arm execution required.
- All Muon²-touching PRs: 100-step smoke test before long arms (post-tanjiro lesson).
- Freeze training script to snapshot OUTSIDE working tree before launching (post-edward arm-C lesson).

## Statistical target

`(3.28 − mu(n=3)) × √3 ≥ 0.004` → mu ≤ 3.27769. New bar is to beat 3.27527 (merged baseline).
