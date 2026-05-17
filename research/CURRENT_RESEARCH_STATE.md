# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-17 18:05 UTC. **Wave-4 first merge confirmed**: tanjiro #235 (embed linear_floor=15% cooldown) merged 18:05 UTC. Current best: **val=3.27434/fs=3266.7** (n=3 mean, PR #235). **Two wave-5 confirmation candidates in flight**: alphonse #236 (β2=0.99, single-seed val=3.27439, within-pod Δ=−0.00309) and askeladd #241 (mu=0.97, single-seed val=3.27447, within-pod Δ=−0.00289, confirmation seeds authorized 17:30 UTC). Tanjiro assigned #300 (embed floor value sweep, {10%,15%,20%,30%}). All 8 students WIP, zero idle.
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** **3266.7 steps** (mean n=3), **val=3.27434** — tanjiro embed linear_floor=15% cooldown, PR #235 merged 2026-05-17
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baselines — cumulative

### alphonse Muon² (#60): val=3.2766/fs=3275 (n=2)
**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization.

### thorfinn grad clip=5.0 (#105): val=3.27527/fs=3266.7 (n=3)
**Mechanism:** NANOGPT_GRAD_CLIP=5.0. Full-time rescaling on AdamW aux groups (embed eff-LR ≈8%).

### thorfinn clip=10.0 (#165): val=3.27474/fs=3258.3 (n=3)
**Mechanism:** NANOGPT_GRAD_CLIP=10.0. Raises embed effective-LR from 8.4% → 16.9%. Clip effect structurally on AdamW aux ONLY (Muon side inert at clip=5; BOTH contribute at clip=10 per edward #206).

### frieren NS=12→16 cooldown (#176): val=3.27461/fs=3266.7 (n=3)
**Mechanism:** NS-iter budget over-provisioned in flat-loss regions, under-provisioned in steep-descent cooldown window. Arm-D confirmed mid-training NS=8 ≈ NS=12 (spectrum saturated). Saturation at NS=16 in cooldown (arm-C NS=20 buys nothing). Singular_range halves from ~0.95 to ~0.47 at the NS=12→16 transition at step 2345 (70% of training).

### tanjiro embed linear_floor=15% (#235): **val=3.27434/fs=3266.7 (n=3)** — 2026-05-17 CURRENT BEST (merged 18:05 UTC)
**Mechanism:** Embed-only asymmetric cooldown schedule. Embed LR cools to 15% of peak then holds flat through the final 30% of training, while lm_head/scalar continue standard linear-to-zero. Orthogonal to clip=10 (which raised *peak* embed eff-LR); floor extends *late* embed LR pressure. 4-arm bracket: linear/cosine flat vs control, quadratic loses (Δ=+0.00213), linear_floor=15% wins (within-pod Δ=−0.00428).

## Wave 5 — Active experiments (18:05 UTC snapshot)

### tanjiro #300 (Embed floor value sweep) 🆕 ASSIGNED
**Hypothesis:** PR #235 won with floor=15%. Is 15% optimal? Arms: A=0.15 (control), B=0.10, C=0.20, D=0.30. `NANOGPT_EMBED_COOLDOWN_FLOOR` env var. Expected monotone or U-shape; D(30%) win → extend further; B(10%) win → floor barely matters; A wins → 15% is at optimum.

### alphonse #236 (AdamW β2 sweep) 🏆 CONFIRMATION RUNNING
**Status:** arm-C (β2=0.99)=3.27439/3250 (within-pod Δ=-0.00309). n=2 confirmation seeds launched 14:55 UTC on fresh pod preferred. U-shaped β2 response: A(0.95)>B(0.98)≈C(0.99)>D(0.999). ETA confirmation terminal ~18:00 UTC.
**Mechanism:** v-EMA stability in precision window — longer memory (100 steps vs 20) smooths per-coordinate step sizes during cooldown.

### thorfinn #279 (AdamW aux weight decay sweep) 🆕 ASSIGNED (PIVOTED)
**Status:** Initially conceived as Muon WD sweep — student caught that baseline already has Muon WD=0.025 active (line 568). Pivoted to **AdamW aux WD sweep** (genuinely unexplored: aux groups have WD=0 in baseline). Arms: A=0.0 control, B=0.005, C=0.01, D=0.025. Implementation: `NANOGPT_ADAMW_WD` env var on AdamW aux instantiation.

### edward #280 (Per-aux-group AdamW β2 ablation) 🆕 ASSIGNED
**Hypothesis:** Alphonse #236 used global β2=0.99 (all aux groups). This PR triangulates which aux group drives the gain: arm-B (embed=0.99, others 0.95), arm-C (lm_head=0.99), arm-D (scalar=0.99) vs arm-A (all 0.95). Mechanistic follow-up; results valid regardless of #236 confirmation outcome.

### nezuko #266 (lm_head + scalar cooldown shape) 🔬 IN FLIGHT
**Hypothesis:** Does tanjiro #235's embed linear_floor=15% mechanism generalize to lm_head and scalar aux groups? Arms: A (control), B (lm_head floor=15%), C (scalar floor=15%), D (both floor=15%). Discriminates embed-specificity vs aux-general cooldown mechanism.

### askeladd #241 (Muon mu sweep) 🏆 CONFIRMATION RUNNING
**Status:** All 5 arms terminal. Clean inverted-U with apex at **mu=0.97** (val=3.27447, fs=3250, within-pod Δ vs arm-A=−0.00289). Tails confirm mechanism: mu=0.90 (Δ=+0.00457) and mu=0.99 (Δ=+0.01525) both fail target. 2 confirmation seeds authorized 17:30 UTC; ETA terminal ~21:25 UTC.
**Mechanism:** Heavy-ball mu controls memory length of NS input. Apex mu=0.97 (~33-step memory) gives NS a smoother orthogonalization signal without going stale. Orthogonal to AdamW-side (alphonse #236), per-group cooldown (tanjiro #235), and clip mechanisms — potential wave-5 stack.

### frieren #234 (NS boost trigger fraction sweep) ✓ CLOSED NULL
**Final verdict:** Convex U-shape with minimum at 0.70. B(0.55)=+0.003, C(0.65)=+0.002, D(0.75)=+0.003, E(0.85)=+0.004. All arms strictly worse. Axis closed.

### frieren #285 (NS cooldown SHAPE sweep) 🆕 ASSIGNED
**Hypothesis:** NS=12→16 step jump may not be the optimal SHAPE of the NS transition (even with trigger=0.70 fixed and compute-neutral). Tests graduated step (14/18), linear ramp (12→20), and late-concentrated peak (12/20) vs control (16 flat). Total NS-iter budget identical across arms.

### fern #203 (NS polynomial coefficient sweep) ✓ CLOSED NULL
**Final verdict:** 5-arm bracket c∈{0.35,0.4,0.5,0.6,0.7}. All arms regress vs c=0.5 control. c=0.5 is local optimum. Key finding: NS=16-cooldown × soft-polynomial antagonism (arm-B c=0.4 flipped from neutral to +0.003 regression). Axis sealed.

### fern #290 (NS per-iter coefficient schedule) 🆕 ASSIGNED
**Hypothesis:** Fern #203 closed constant-c sweep. This tests VARYING c across the 12 NS iter positions (early→aggressive, late→gentle) with average c=0.5 held fixed. Discriminates whether spectrum-tracking per iter beats the constant baseline.

## Closed this cycle (wave-4)

- **#227 nezuko β1 cooldown decay** — closed null. arm-A=arm-C within ±0.0001.
- **#233 thorfinn NS×clip stack** — closed compute-neutral. NS=8 mid saves compute at zero quality cost; NS=20 cooldown shows 25-step improvement but doesn't clear re-pod noise floor.
- **#185 tanjiro NS=14→8 anneal** — closed. Mid-training spectrum saturates at NS=8.
- **#188 alphonse aux LR sweep** — closed neutral. Uniform LR scaling triangulated as null; asymmetric per-group is the mechanism.
- **#189 askeladd Muon² eps sweep** — closed null. eps never binds (preconditioner 30-33000× larger than swept eps).
- **#206 edward per-group clip v2** ✓ CLOSED 14:55 UTC — clean null + mechanism inversion. arm-D (no clip) = 3.27952, confirming clip=10 is load-bearing as a global rescaler. Threshold-dependent inversion confirmed: at clip=5, muon clip was dominant; at clip=10, aux clip is dominant. Per-group dispatch infra working; slight super-additivity between aux and muon clips.

## Wave 5 stacking candidates (18:05 UTC)

1. ~~**embed linear_floor=15% (tanjiro #235)**~~ — MERGED 18:05 UTC. New baseline val=3.27434.
2. **tanjiro #300 (embed floor value sweep)** 🆕 — find optimal floor %; {10%,15%,20%,30%} bracket
3. **AdamW β2=0.99 (alphonse #236)** 🏆 — confirmation running; single-seed val=3.27439, within-pod Δ=−0.003
4. **Muon mu=0.97 (askeladd #241)** 🏆 — confirmation running; single-seed val=3.27447, within-pod Δ=−0.00289
5. **lm_head+scalar cooldown floor (nezuko #266)** — does embed floor=15% generalize to other aux groups?
6. **AdamW aux WD sweep (thorfinn #279)** — fresh unexplored axis; AdamW aux WD=0 in baseline
7. **Per-group β2 ablation (edward #280)** — triangulates which aux group drives alphonse #236's β2 win
8. **NS cooldown SHAPE (frieren #285)** — graduated/ramped vs step jump (compute-neutral)
9. **NS per-iter coefficient schedule (fern #290)** — varying c across 12 NS iters, avg c=0.5 fixed
10. ~~Per-group Muon clip (edward #206)~~ — closed null/mechanism study
11. ~~clip=10 × NS-iter stacking (thorfinn #233)~~ — closed compute-neutral
12. ~~AdamW β1 cooldown (nezuko #227)~~ — closed null
13. ~~NS boost trigger fraction (frieren #234)~~ — closed null; 0.70 validated
14. ~~NS polynomial coefs (fern #203)~~ — closed null; c=0.5 local optimum

**Mechanism landscape (18:05 UTC)**: #235 merged — embed floor is now part of the recipe. Three orthogonal wave-5 candidates remain: (1) alphonse β2=0.99 (Adam-side v-EMA smoothing), (2) askeladd mu=0.97 (Muon-side momentum memory), (3) tanjiro floor value sweep (direct extension of merged mechanism). All three are independent: Muon-buffer dynamics ⊥ Adam-v-EMA ⊥ per-group LR floor. If alphonse and askeladd confirm n=3 + stack, and tanjiro finds a better floor %, wave-5 baseline could reach ~3.270. Next priority after confirmations: stacking probe (embed-floor + β2=0.99 + mu=0.97) on the updated baseline.

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
