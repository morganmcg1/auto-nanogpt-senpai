# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-17 14:55 UTC. **Two wave-3 merges complete**: thorfinn #165 (clip=10.0) and frieren #176 (NS=12→16 cooldown boost). Current best: **val=3.27461/fs=3266.7** (n=3 mean frieren #176). **Two wave-4 potential merge winners in confirmation**: tanjiro #235 arm-C (embed floor=15%, val=3.27245, n=1, confirmation ETA ~17:36 UTC) and alphonse #236 arm-C (β2=0.99, val=3.27439, n=1, confirmation seeds just launched). If both confirm, wave-5 baseline could reach ~3.271.
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
**Mechanism:** NANOGPT_GRAD_CLIP=10.0. Raises embed effective-LR from 8.4% → 16.9%. Clip effect structurally on AdamW aux ONLY (Muon side inert at clip=5; BOTH contribute at clip=10 per edward #206).

### frieren NS=12→16 cooldown (#176): **val=3.27461/fs=3266.7 (n=3)** — 2026-05-17 CURRENT BEST
**Mechanism:** NS-iter budget over-provisioned in flat-loss regions, under-provisioned in steep-descent cooldown window. Arm-D confirmed mid-training NS=8 ≈ NS=12 (spectrum saturated). Saturation at NS=16 in cooldown (arm-C NS=20 buys nothing). Singular_range halves from ~0.95 to ~0.47 at the NS=12→16 transition at step 2345 (70% of training).

## Wave 4 — Active experiments (14:55 UTC snapshot)

### tanjiro #235 (Embed-only cooldown shape) 🏆 CONFIRMATION RUNNING
**Status:** arm-C (linear_floor 15%)=3.27245/3250 (-0.00216 vs baseline, within-pod Δ=-0.00428). Confirmation seeds (s2, s3) running. Final n=3 result ETA ~17:36 UTC.
**Mechanism:** Sustained mid-LR pressure on embed (the most-clip-sensitive aux group) through final 30% of training while lm_head/scalar continue cosine→0. Per-group asymmetric schedule — directly complementary to clip=10 (which raised embed eff-LR by 2×).

### alphonse #236 (AdamW β2 sweep) 🏆 CONFIRMATION RUNNING
**Status:** arm-C (β2=0.99)=3.27439/3250 (within-pod Δ=-0.00309). n=2 confirmation seeds launched 14:55 UTC on fresh pod preferred. U-shaped β2 response: A(0.95)>B(0.98)≈C(0.99)>D(0.999). ETA confirmation terminal ~18:00 UTC.
**Mechanism:** v-EMA stability in precision window — longer memory (100 steps vs 20) smooths per-coordinate step sizes during cooldown.

### thorfinn #279 (AdamW aux weight decay sweep) 🆕 ASSIGNED (PIVOTED)
**Status:** Initially conceived as Muon WD sweep — student caught that baseline already has Muon WD=0.025 active (line 568). Pivoted to **AdamW aux WD sweep** (genuinely unexplored: aux groups have WD=0 in baseline). Arms: A=0.0 control, B=0.005, C=0.01, D=0.025. Implementation: `NANOGPT_ADAMW_WD` env var on AdamW aux instantiation.

### edward #280 (Per-aux-group AdamW β2 ablation) 🆕 ASSIGNED
**Hypothesis:** Alphonse #236 used global β2=0.99 (all aux groups). This PR triangulates which aux group drives the gain: arm-B (embed=0.99, others 0.95), arm-C (lm_head=0.99), arm-D (scalar=0.99) vs arm-A (all 0.95). Mechanistic follow-up; results valid regardless of #236 confirmation outcome.

### nezuko #266 (lm_head + scalar cooldown shape) 🔬 IN FLIGHT
**Hypothesis:** Does tanjiro #235's embed linear_floor=15% mechanism generalize to lm_head and scalar aux groups? Arms: A (control), B (lm_head floor=15%), C (scalar floor=15%), D (both floor=15%). Discriminates embed-specificity vs aux-general cooldown mechanism.

### askeladd #241 (Muon mu sweep) 🔬 IN FLIGHT
**Status:** arm-A (mu=0.95)=~3.277; arm-B (mu=0.90)=3.282 (regression). Lower mu hurts. arm-C (mu=0.93) and arm-D (mu=0.97) running. Pattern: lower mu hurts; waiting for mu=0.97, 0.99 arms to determine if higher mu helps.

### frieren #234 (NS boost trigger fraction sweep) 🔬 NEAR CLOSE
**Status:** arm-A (0.70 baseline reproduction) clusters near baseline; sweep arms mostly flat/noise. Likely closing as null after arm-E terminal.

### fern #203 (NS polynomial coefficient sweep) 🔬 NEAR CLOSE
**Status:** arm-A (c=0.5)=3.27463, arm-B (c=0.4)=+0.003 regression, arm-C (c=0.6)=+0.002 regression, arm-D (c=0.35)=+0.001 regression. c=0.5 is local optimum. arm-E (c=0.7) running. Closing after arm-E.

## Closed this cycle (wave-4)

- **#227 nezuko β1 cooldown decay** — closed null. arm-A=arm-C within ±0.0001.
- **#233 thorfinn NS×clip stack** — closed compute-neutral. NS=8 mid saves compute at zero quality cost; NS=20 cooldown shows 25-step improvement but doesn't clear re-pod noise floor.
- **#185 tanjiro NS=14→8 anneal** — closed. Mid-training spectrum saturates at NS=8.
- **#188 alphonse aux LR sweep** — closed neutral. Uniform LR scaling triangulated as null; asymmetric per-group is the mechanism.
- **#189 askeladd Muon² eps sweep** — closed null. eps never binds (preconditioner 30-33000× larger than swept eps).
- **#206 edward per-group clip v2** ✓ CLOSED 14:55 UTC — clean null + mechanism inversion. arm-D (no clip) = 3.27952, confirming clip=10 is load-bearing as a global rescaler. Threshold-dependent inversion confirmed: at clip=5, muon clip was dominant; at clip=10, aux clip is dominant. Per-group dispatch infra working; slight super-additivity between aux and muon clips.

## Wave 5 stacking candidates (14:55 UTC)

1. **embed linear_floor=15% cooldown (tanjiro #235)** 🏆 TOP CANDIDATE — n=3 ETA ~17:36 UTC; single-seed val=3.27245
2. **AdamW β2=0.99 (alphonse #236)** 🏆 SECOND CANDIDATE — confirmation seeds launched; single-seed val=3.27439, within-pod Δ=−0.003 strong
3. **lm_head+scalar cooldown shape (nezuko #266)** — tests generalization of tanjiro's embed-floor mechanism
4. **AdamW aux WD sweep (thorfinn #279)** — fresh unexplored axis; AdamW aux WD=0 in baseline
5. **Per-group β2 ablation (edward #280)** 🆕 — triangulates which aux group drives alphonse #236's β2 win
6. **Muon mu constants (askeladd #241)** — lower mu hurts; waiting for higher-mu arms (mu=0.97, 0.99)
7. ~~Per-group Muon clip (edward #206)~~ — closed null/mechanism study
8. ~~clip=10 × NS-iter stacking (thorfinn #233)~~ — closed compute-neutral
9. ~~AdamW β1 cooldown (nezuko #227)~~ — closed null
10. ~~NS boost trigger fraction (frieren #234)~~ — closing null
11. ~~NS polynomial coefs (fern #203)~~ — closing null (c=0.5 local optimum)

**Mechanism landscape (14:55 UTC)**: The "cooldown-window precision" theme consolidates around two axes that both confirm: (1) embed LR floor sustains update pressure in the last 30% of training; (2) β2=0.99 smooths the v-EMA for cleaner per-coordinate step sizes. Both are orthogonal to the clip/NS mechanics already merged. The immediate wave-5 priority: wait for tanjiro and alphonse confirmations, then stack them, then probe whether β2 asymmetry is group-specific (edward #280) and whether aux groups want WD (thorfinn #279).

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
| Per-group Muon clip | per-group clip dispatch at clip=10 | #206 (clip=10 is load-bearing globally; no per-group config wins) |
| AdamW β1 cooldown | β1 schedule on aux groups | #227 (null: A=C within ±0.0001) |
| NS×clip stacking | NS=8mid+16cd stack | #233 (compute-neutral only) |

## Statistical target

`(3.28 − mu(n=3)) × √3 ≥ 0.004` → mu ≤ 3.27769. Current bar to beat: **3.27461**.
