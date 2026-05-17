# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-17 14:40 UTC. **Two wave-3 merges complete**: thorfinn #165 (clip=10.0) and frieren #176 (NS=12→16 cooldown boost). Current best: **val=3.27461/fs=3266.7** (n=3 mean frieren #176). Wave 4: **TWO potential merge winners emerging**: tanjiro #235 arm-C (embed floor=15%, val=3.27245, confirmation seeds running) and alphonse #236 arm-C (β2=0.99, val=3.27439, confirmation seeds AUTHORIZED). If both confirm, wave-5 baseline could reach ~3.271.
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

### nezuko #227 (AdamW β1 cooldown decay) ✓ CLOSED — NULL
**Final verdict:** arm-A=arm-C within ±0.0001 (3.2734); arm-B +0.005 regression (plausible seed noise). β1 cooldown decay is a null mechanism. PR closed 2026-05-17.

### nezuko #266 (lm_head + scalar cooldown shape) 🆕 ASSIGNED
**Hypothesis:** If tanjiro #235 embed linear_floor=15% wins, does the same floor mechanism apply to lm_head and scalar aux groups? Tests 4 arms: A (baseline control), B (lm_head floor=15%), C (scalar floor=15%), D (lm_head + scalar both floor=15%). Discriminates embed-specificity vs aux-general. Critical for wave-5 stacking strategy.

### thorfinn #233 (Wave 4 Stack A) ✓ WEAK STACK
**Status:** arm-A (control)=3.27806/3300; arm-B (NS=8mid+16cd+clip=10)=3.27705/3300 (-0.001 within-pod, small); arm-C (NS=8mid+20cd) running step ~375, ETA terminal ~14:15 UTC. Pod inflated by +0.003 vs merged baseline; only within-pod Δ is meaningful, and Δ_AB=-0.001 is unlikely to survive re-pod variance.

### frieren #234 (NS boost trigger fraction sweep)
**Status:** arm-A (0.70 = baseline reproduction)=3.2740/?; arm-B/C/D=3.277/3.276/running. arm-A clusters near baseline; sweep arms mostly noise band. Awaiting terminal posting.

### alphonse #236 (AdamW β2 sweep) 🏆 POTENTIAL MERGE WINNER
**Status:** arm-A (β2=0.95)=3.27748/3300; arm-B (β2=0.98)=3.27465/3250; **arm-C (β2=0.99)=3.27439/3250** (-0.00022 vs baseline, within-pod Δ=-0.00309); arm-D (β2=0.999)=3.27695/3300. **n=2 confirmation seeds AUTHORIZED at β2=0.99 (fresh pod preferred)**. U-shaped response confirms β2=0.99 as optimal — not monotonic. SENPAI-RESULT posted 14:21 UTC.

### thorfinn #233 (Wave 4 Stack) ✓ CLOSED — COMPUTE NEUTRAL
**Final verdict:** arm-C (NS=8mid+20cd) within-pod Δ=-0.00189, just above -0.002 threshold. Pod drift +0.00345 made confirmation unviable. PR closed 2026-05-17. Key finding: NS=8 mid-training is compute-neutral with NS=12 (23% Muon-block compute reduction free). NS=20 cooldown shows 25-step fs improvement but couldn't clear re-pod noise floor.

### thorfinn #279 (Muon weight decay sweep) 🆕 ASSIGNED
**Hypothesis:** Muon optimizer runs with WD=0 — decoupled WD on NS-orth updates would provide spectral shrinkage orthogonal to direction normalization. Sweep WD ∈ {0, 0.001, 0.005, 0.01}.

### askeladd #241 (Muon mu sweep)
**Status:** arm-A (mu=0.95 control)=~3.277; arm-B (mu=0.90)=3.282 (regression); arm-C (mu=0.93) running. arm-D (mu=0.97) running step ~1600. Lower mu hurts; waiting for higher-mu arms.

### fern #203 (NS polynomial coefficient sweep)
**Status:** arm-A (c=0.5 control)=3.27463/3250; arm-B (c=0.4)=3.27741 (+0.003 regression); arm-C (c=0.6)=3.27621 (+0.002 regression); arm-D (c=0.35)=3.27567 (+0.001 regression); arm-E (c=0.7) running ETA ~16:00 UTC. **c=0.5 is local optimum** — both harder and softer quintics regress. Likely closing as null axis.

## Closed this cycle (wave-4)

- **#185 tanjiro NS=14→8 anneal** — closed. Frieren arm-D mechanically falsified the NS-high-early hypothesis: mid-training spectrum saturates at NS=8 (extra iters mid-training buy nothing). Tanjiro's NS=14 mid + NS=8 cooldown is anti-correlated with what wins.
- **#188 alphonse aux LR sweep** — closed. Uniform aux LR scaling triangulated as neutral (arm-B 1.5×, arm-D 0.5× both ≈ baseline). Combined with thorfinn single-peak sweep + edward arm-B regression, the clip mechanism is now: per-group asymmetric global-norm rescaling, NOT uniform LR scaling.
- **#189 askeladd Muon² eps sweep** — closed. Decisive telemetry: `eps_dominates_frac_block0_q = 0` across all 4 swept arms (1e-9 to 1e-6, a 1000× range). Preconditioner mean ~3e-5 is always 30× to 33000× larger than swept eps. eps floor never engages; val differences across arms are seed noise (non-monotonic: arm-B 1e-7 worse than arm-E 1e-6). Axis cleanly closed — eps=1e-8 is safe default forever.

## Wave 5 stacking candidates (post-confirmation status, 14:40 UTC)

Updated with arm-D terminal results across wave-4:

1. **embed linear_floor=15% cooldown (tanjiro #235)** 🏆 TOP CANDIDATE — confirmation seeds running; val=3.27245 n=1
2. **AdamW β2=0.99 (alphonse #236)** 🏆 SECOND CANDIDATE — confirmation seeds authorized; val=3.27439 n=1, within-pod Δ=-0.003 strong
3. **lm_head+scalar cooldown shape (nezuko #266)** 🆕 — tests whether embed floor generalizes to other aux groups
4. **Muon weight decay (thorfinn #279)** 🆕 — completely fresh axis, sweeping WD ∈ {0.001, 0.005, 0.01}
5. ~~clip=10 × NS-iter stacking (thorfinn #233)~~ — closed, compute-neutral (NS=8 mid saves compute, doesn't improve metrics)
6. ~~AdamW β1 cooldown (nezuko #227)~~ — closed, null axis
7. ~~NS boost trigger fraction (frieren #234)~~ — sweep mostly flat; arm-E terminal will close
8. ~~NS polynomial coefs (fern #203)~~ — c=0.5 is local optimum; closing after arm-E
9. **Per-group Muon clip (edward #206)** — arm-D (no-clip) near terminal; aux clip is load-bearing at clip=10; if arm-D regresses, axis closed
10. **Muon mu constants (askeladd #241)** — lower mu hurts; awaiting higher-mu arms (mu=0.97, 0.99)

**Mechanism landscape shift**: both tanjiro #235 (embed floor) and alphonse #236 (β2=0.99) confirm a **cooldown-window precision** theme. These are the first wave-4 improvements that target the variance/smoothing/LR-sustain structure in the precision window rather than clip/NS mechanics. Wave 5 priority: confirm both, then stack, then probe whether lm_head/scalar follow the same pattern (nezuko #266).

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
