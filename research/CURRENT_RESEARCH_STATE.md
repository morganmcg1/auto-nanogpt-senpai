# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-18 00:05 UTC. **WAVE-5 FIRST MERGE**: alphonse #236 (β2=0.99) merged. New baseline: **val=3.27407/fs=3258.3** (n=3 mean). Current best (cumulative): **val=3.27407 / fs=3258.3**.
  - **MERGED** ✓ alphonse #236 β2=0.99: val=3.27407/fs=3258.3, Δ=−0.00027 val / −8.4 fs. `NANOGPT_ADAMW_BETA2=0.99` now part of baseline recipe.
  - **alphonse #322 (AdamW ε sweep) 🆕 ASSIGNED**: re-tune ε after β2=0.99 changes v̂ distribution. Arms: 1e-10 (control), 1e-9, 1e-8, 1e-7.
  - **askeladd #241 (mu=0.97) — LIKELY DOA**: n=2 mean=3.27543, new seed-3 gate=3.27136 (was 3.27217). Extremely tight. Let seed-3 land but expect close. Notified 00:02 UTC.
  - **edward #280 (per-group β2) — mechanism**: arm-B embed=0.99 Δ=−0.00280 (strong). arm-C (lm_head) ETA ~23:53 UTC (past), arm-D (scalar) ETA ~01:37 UTC.
  - **thorfinn #279 (AdamW aux WD=0.005) ⚡ — n=2 mean=3.27342, seed-3 gate ≤3.27537**: comfortable margin. ETA ~01:00-01:15 UTC. Still strongest wave-5 non-merged candidate.
  - **fern #290 (NS per-iter c) — arm-D decisive**: arm-B (agg→gentle) val=3.27382, arm-C null. arm-D ETA ~23:58 UTC (past or imminent).
  - **frieren #285 (NS late_peak) — n=3 confirmation in flight**: arm-D near-miss Δ=−0.00143. Sent back for rebase + confirmation chain on NEW baseline (gate: n=3 mean ≤ 3.27407).
  - **nezuko #315 (lmhead-decay-shape) 🆕 ASSIGNED**: test lm_head=quadratic/cubic/exp_decay vs linear.
  - **tanjiro #300 (embed floor)** — arm-B (0.10) HURTS. arm-C (0.20) running ETA ~01:00 UTC.
All 8 students WIP. Wave-5 recipe stack so far: clip=10 + NS=12/16 + embed_linear_floor + β2=0.99. Next merge candidate: thorfinn aux WD=0.005.
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

### thorfinn #279 (AdamW aux weight decay sweep) ⚡ STRONG ARM-B SIGNAL
**Status:** Initially conceived as Muon WD sweep — student caught that baseline already has Muon WD=0.025 active (line 568). Pivoted to **AdamW aux WD sweep** (genuinely unexplored: aux groups have WD=0 in baseline). Arms: A=0.0 control, B=0.005, C=0.01, D=0.025. Implementation: `NANOGPT_ADAMW_WD` env var on AdamW aux instantiation.
**Screening complete** (21:25 UTC): arm-A=3.27435, **arm-B (WD=0.005)=3.27158 (Δ=−0.00277, WINNER)**, arm-C (WD=0.01)=3.27824 (Δ=+0.00389, over-regularization), arm-D SKIPPED per rule (B→C regression confirms U-curve apex at WD=0.005). Embed Fro scales monotonically (71680→22528→13440 ≈ 0.31×→0.19× per 2× WD); val_loss is U-shaped. **n=3 confirmation chain launched on same pod**: seed-2 ETA ~23:15 UTC, seed-3 ETA ~01:05 UTC, terminal SENPAI-RESULT ~01:15 UTC. Merge gate: n=3 mean ≤ 3.27434 → required (seed-2 + seed-3) avg ≤ 3.27573. **Strongest wave-5 candidate**.

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

### fern #290 (NS per-iter coefficient schedule) ⚡ STRONG ARM-B SIGNAL
**Hypothesis:** Fern #203 closed constant-c sweep. This tests VARYING c across the 12 NS iter positions (early→aggressive, late→gentle) with average c=0.5 held fixed. Discriminates whether spectrum-tracking per iter beats the constant baseline.
**Result so far** (20:20 UTC, OLD baseline): arm-A=3.27667 (drift Δ=+0.00206 vs new baseline, gate pass), **arm-B (aggressive_to_gentle, c=0.7→0.3) val=3.27382/fs=3250, within-pod Δ=−0.00285**. arm-C (inverse, gentle_to_aggressive) is the falsification test — running, ETA ~21:55 UTC. arm-D (linear ramp-down) ETA ~23:38 UTC. If arm-C regresses, mechanism is confirmed asymmetric. Confirmation seeds will require rebase to NEW baseline.

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
6. ⚡ **AdamW aux WD=0.005 (thorfinn #279) — CONFIRMATION RUNNING (n=3 chain)**. arm-B seed-1 val=3.27158 (within-pod Δ=−0.00277). arm-C (WD=0.01) regresses to 3.27824 — U-curve apex confirmed at 0.005. arm-D skipped per rule. Merge gate: n=3 mean ≤ 3.27434. Mechanism: explicit embed regularization (Fro norm 22528 vs 71680). ETA terminal SENPAI-RESULT ~01:15 UTC.
7. **Per-group β2 ablation (edward #280)** — triangulates which aux group drives alphonse #236's β2 win
8. **NS cooldown SHAPE (frieren #285)** — graduated/ramped vs step jump (compute-neutral)
9. ⚡ **NS per-iter c-schedule (fern #290) arm-B agg→gentle** — single-seed val=3.27382, within-pod Δ=−0.00285 (OLD baseline). arm-C (inverse) and arm-D (smoother) still pending. **Two clean wave-5 signals now**: thorfinn aux WD=0.005 and fern c=0.7→0.3 schedule. Both are mechanistically distinct from #235 and orthogonal to alphonse/askeladd candidates.
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

`(3.28 − mu(n=3)) × √3 ≥ 0.004` → mu ≤ 3.27769. Current bar to beat: **3.27434** (post-#235).
