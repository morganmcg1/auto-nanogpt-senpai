# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-17 07:30 UTC. **Two wave-3 merges complete**: thorfinn #165 (clip=10.0) and frieren #176 (NS=12→16 cooldown boost). Current best: **val=3.27461/fs=3266.7** (n=3 mean frieren #176).
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

## Wave 4 — Active experiments

### thorfinn #233 (Wave 4 Stack A) 🔥🔥
**Hypothesis:** clip=10 (AdamW aux, merged) × aggressive NS schedule (NS=8mid→NS=16cooldown, Muon blocks). Two orthogonal mechanism axes should compose additively. Expected val ≈ 3.272–3.273.

### frieren #234 (NS boost trigger fraction sweep) 🔥
**Hypothesis:** The 70% trigger point for NS=12→16 was arbitrary. Sweep {0.55, 0.65, 0.70, 0.75, 0.85}.

### tanjiro #235 (Embed-only cooldown shape) 🆕
**Hypothesis:** Embed is the most-sensitive aux group per clip mechanism. Apply custom cooldown shape (cosine, linear_floor at 15%, quadratic) to embed only while lm_head/scalar stay on linear. Tests whether per-group schedule shape matters.

### alphonse #236 (AdamW β2 sweep) 🆕
**Hypothesis:** Our β2=0.95 is unusually aggressive (Adam standard 0.999). Raising β2 stabilizes the per-coordinate effective LR during cooldown. Fresh axis — never swept in isolation on AdamW aux. Sweep {0.95, 0.98, 0.99, 0.999}.

### nezuko #227 (AdamW β1 cooldown decay)
**Hypothesis:** Decay β1 from 0.8→{0.5, 0.3} during cooldown to reduce momentum lag. Aux responsiveness axis (orthogonal to β2 in #236).

### edward #206 (Per-group clip — rebased + sharpened) 🔥
**Hypothesis after rebase:** With clip=10 merged, the no-clip arm-D is now the decisive discriminator: is clip ≥ 10 even better, or is clip itself superfluous at the new effective-LR? Per-group arms updated to clip=10 references.

### askeladd #189 (Muon² eps sweep — rebasing)
**Hypothesis:** Sweep eps in `sqrt(v) + eps` denominator of Muon². Orthogonal to clip and NS schedule.

### fern #203 (NS polynomial coefficient sweep — rebasing)
**Hypothesis:** Sweep (a, b, c) coefficients in NS quintic polynomial. Orthogonal to NS iter count and clip.

## Closed this cycle

- **#185 tanjiro NS=14→8 anneal** — closed. Frieren arm-D mechanically falsified the NS-high-early hypothesis: mid-training spectrum saturates at NS=8 (extra iters mid-training buy nothing). Tanjiro's NS=14 mid + NS=8 cooldown is anti-correlated with what wins.
- **#188 alphonse aux LR sweep** — closed. Uniform aux LR scaling triangulated as neutral (arm-B 1.5×, arm-D 0.5× both ≈ baseline). Combined with thorfinn single-peak sweep + edward arm-B regression, the clip mechanism is now: per-group asymmetric global-norm rescaling, NOT uniform LR scaling.

## Wave 4 stacking matrix (post-confirmation candidates)

If multiple wave-4 arms beat new baseline, the stacking candidates for wave 5:
1. **clip=10 × NS=8mid→16cd (thorfinn #233)** — the aggressive variant
2. **+ optimal NS trigger frac (frieren #234)** — better cooldown transition point
3. **+ optimal embed cooldown shape (tanjiro #235)** — embed-specific schedule
4. **+ AdamW β2 increase (alphonse #236)** — variance stabilization
5. **+ AdamW β1 cooldown decay (nezuko #227)** — responsiveness boost
6. **+ Muon mu cooldown (edward, queued)** — Muon-side responsiveness

These are 6 orthogonal axes targeting precision/responsiveness from independent angles. Even fractional stacking gains compound.

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

## Statistical target

`(3.28 − mu(n=3)) × √3 ≥ 0.004` → mu ≤ 3.27769. Current bar to beat: **3.27461**.
