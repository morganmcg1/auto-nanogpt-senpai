# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-17 13:00 UTC. **Two wave-3 merges complete**: thorfinn #165 (clip=10.0) and frieren #176 (NS=12→16 cooldown boost). Current best: **val=3.27461/fs=3266.7** (n=3 mean frieren #176). Wave 4: **major progress — tanjiro #235 arm-C at val=3.27245/fs=3250 (n=1, Δ vs baseline=-0.00216) is the headline result; n=2 confirmation seeds queued for n=3 stat-sig merge gate**. 6 of 8 students have ≥1 terminal arm result.
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** **3266.7 steps** (mean n=3), **val=3.27461** — frieren NS=12→16 cooldown boost, PR #176 merged 2026-05-17
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baselines — cumulative wave-3 merges

### alphonse Muon² (#60): val=3.2766/fs=3275 (n=2)
**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization.

### thorfinn grad clip=5.0 (#105): val=3.27527/fs=3266.7 (n=3)
**Mechanism:** NANOGPT_GRAD_CLIP=5.0. Full-time rescaling on AdamW aux groups (embed eff-LR ≈8%).

### thorfinn clip=10.0 (#165): val=3.27474/fs=3258.3 (n=3)
**Mechanism:** NANOGPT_GRAD_CLIP=10.0. Raises embed effective-LR from 8.4% → 16.9%. Clip effect structurally on AdamW aux ONLY (Muon side inert).

### frieren NS=12→16 cooldown (#176): **val=3.27461/fs=3266.7 (n=3)** — 2026-05-17 CURRENT BEST
**Mechanism:** NS-iter budget over-provisioned in flat-loss regions, under-provisioned in steep-descent cooldown window. Arm-D confirmed mid-training NS=8 ≈ NS=12 (spectrum saturated). Saturation at NS=16 in cooldown (arm-C NS=20 buys nothing). Singular_range halves from ~0.95 to ~0.47 at the NS=12→16 transition at step 2345 (70% of training).

## Wave 4 — Active experiments (12:50 UTC snapshot)

### tanjiro #235 (Embed-only cooldown shape) 🏆 LIKELY MERGE WINNER
**Status:** arm-A (linear, control)=3.27673/3275; arm-B (cosine)=3.27633/3275; **arm-C (linear_floor 15%)=3.27245/3250 (-0.00216 vs baseline, -0.00428 within-pod)**; arm-D (quadratic) running ~step 475, ETA terminal ~14:08 UTC. Confirmation seeds (s2, s3) chained after arm-D — final n=3 result ETA ~17:36 UTC.
**Mechanism:** sustained mid-LR pressure on embed (the most-clip-sensitive aux group) through final 30% of training while lm_head/scalar continue cosine→0. Per-group asymmetric schedule — directly complementary to clip=10 (which raised embed eff-LR by 2×).

### edward #206 (Per-group clip v2 — clip=10 + NS cooldown) 🔥 MECHANISM INVERTED
**Status:** arm-A (clip=10 ALL)=3.27434/3250 (within noise vs baseline); arm-B (aux only)=3.27729/3300 (+0.003 regression); arm-C (muon only)=3.27500/3275 (within noise). arm-D (no clip) running step ~50, ETA terminal ~14:11 UTC.
**Finding:** at clip=10, **aux clip is load-bearing, muon clip is essentially inert** — OPPOSITE of pre-rebase finding at clip=5. Threshold-dependent inversion (clip=5 aux-clip is harmful, clip=10 aux-clip is essential). Arm-D the decisive discriminator.

### nezuko #227 (AdamW β1 cooldown decay) ✓ AXIS NULL
**Status:** arm-A (β1=0.8 const)=3.27338/3250; arm-B (β1→0.5)=3.27834/3325 (+0.005 regression); arm-C (β1→0.3)=3.27340/3250. **arm-A ≈ arm-C within ±0.0001** — β1 cooldown decay is null. arm-B U-shape outlier likely seed noise. Awaiting terminal SENPAI-RESULT to close.

### thorfinn #233 (Wave 4 Stack A) ✓ WEAK STACK
**Status:** arm-A (control)=3.27806/3300; arm-B (NS=8mid+16cd+clip=10)=3.27705/3300 (-0.001 within-pod, small); arm-C (NS=8mid+20cd) running step ~375, ETA terminal ~14:15 UTC. Pod inflated by +0.003 vs merged baseline; only within-pod Δ is meaningful, and Δ_AB=-0.001 is unlikely to survive re-pod variance.

### frieren #234 (NS boost trigger fraction sweep)
**Status:** arm-A (0.70 = baseline reproduction)=3.2740/?; arm-B/C/D=3.277/3.276/running. arm-A clusters near baseline; sweep arms mostly noise band. Awaiting terminal posting.

### alphonse #236 (AdamW β2 sweep) 🔥
**Status:** arm-A (β2=0.95 control)=~3.277; arm-B (β2=0.98)=~3.275; arm-C (β2=0.99)=~3.274; arm-D (β2=0.999) running. **Monotonic improvement with higher β2** — promising direction.

### askeladd #241 (Muon mu sweep)
**Status:** arm-A (mu=0.95 control)=~3.277; arm-B (mu=0.90)=~3.282 (regression); arm-C (mu=0.93) running step ~1750. Lower mu hurts; expect arm-D/E (higher mu) terminal soon.

### fern #203 (NS polynomial coefficient sweep)
**Status:** arm-A/B/C terminal at ~3.275/3.277/3.276; arm-D (c=0.35) running step ~350. NS coef axis appears mostly flat near merged baseline.

## Closed this cycle

- **#185 tanjiro NS=14→8 anneal** — closed. Frieren arm-D mechanically falsified the NS-high-early hypothesis: mid-training spectrum saturates at NS=8 (extra iters mid-training buy nothing). Tanjiro's NS=14 mid + NS=8 cooldown is anti-correlated with what wins.
- **#188 alphonse aux LR sweep** — closed. Uniform aux LR scaling triangulated as neutral (arm-B 1.5×, arm-D 0.5× both ≈ baseline). Combined with thorfinn single-peak sweep + edward arm-B regression, the clip mechanism is now: per-group asymmetric global-norm rescaling, NOT uniform LR scaling.
- **#189 askeladd Muon² eps sweep** — closed. Decisive telemetry: `eps_dominates_frac_block0_q = 0` across all 4 swept arms (1e-9 to 1e-6, a 1000× range). Preconditioner mean ~3e-5 is always 30× to 33000× larger than swept eps. eps floor never engages; val differences across arms are seed noise (non-monotonic: arm-B 1e-7 worse than arm-E 1e-6). Axis cleanly closed — eps=1e-8 is safe default forever.

## Wave 5 stacking candidates (post-confirmation status, 12:50 UTC)

Updated based on actual wave-4 evidence:

1. **embed linear_floor=15% cooldown (tanjiro #235 — pending n=3 confirm)** 🏆 most promising; if confirms, MERGE
2. **AdamW β2 increase to 0.99 (alphonse #236 — pending arm-D)** 🔥 monotonic improvement signal, awaiting confirmation
3. ~~clip=10 × NS=8mid→16cd (thorfinn #233)~~ — weak stack signal (within-pod Δ ~0.001)
4. ~~AdamW β1 cooldown decay (nezuko #227)~~ — axis closed (null)
5. ~~NS boost trigger fraction (frieren #234)~~ — sweep is mostly flat near baseline
6. ~~NS polynomial coefs (fern #203)~~ — sweep is mostly flat near baseline
7. **Per-group muon clip removal (edward #206 — pending arm-D)** — if arm-D ≈ arm-A, can simplify (cosmetic null); if arm-D regresses, muon clip matters
8. **Muon mu (askeladd #241 — pending)** — lower mu hurts, awaiting higher-mu arms

**Key insight from wave-4**: cooldown-window precision mechanisms (#235 embed floor, #236 β2 increase) appear more productive than the optimizer-momentum axes (β1 in #227, mu in #241) that we expected to win. **Wave 5 should prioritize cooldown-shape mechanisms across more aux groups + variance-stabilization mechanisms.**

## Closed mechanisms (do not re-explore)

| Category | Mechanism | Evidence |
|----------|-----------|----------|
| Temporal smoothing | Polyak EMA, Lookahead | #104, #120 |
| Element-wise direction shaping | Contra-Soft per-element | #126 |
| Magnitude-coupled trust region | \|\|w\|\|_F coupled cap | #117 |
| LR warmup | 0/50/100 step warmup | #102 |
| Cooldown frac (timing only) | {0.4, 0.5, 0.6} | #106 |
| Cooldown LR shape (global) | cosine, sqrt, quadratic, exp | #204 (nezuko) |
| Lion optimizer (aux) | Lion embed+lm_head | #77 |
| Per-layer NS adaptive | sigmoid-controlled NS iters | #145 |
| Momentum reset (DMR) | periodic v reset with decay | #163 |
| SOAP/Adafactor on aux | Shampoo rotation / factored v | #144, #180 |
| Adam-style BC in Muon² | BC + beta2=0.98 (bundled) | #115 |
| NS=8 floor test | constant NS=8 | #75 |
| NS high-early anneal | NS=14→8 | #185 (foreclosed by frieren arm-D) |
| Uniform aux LR scaling | 0.5× / 1.5× embed/lm_head/scalar | #188 (mechanism triangulated) |
| Muon² eps floor | sweep 1e-9 to 1e-6 | #189 (eps never binds, 30× below preconditioner) |

## Statistical target

`(3.28 − mu(n=3)) × √3 ≥ 0.004` → mu ≤ 3.27769. Current bar to beat: **3.27461**.
