# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-17 07:15 UTC. **Two wave-3 merges complete**: thorfinn #165 (clip=10.0) and frieren #176 (NS=12→16 cooldown boost). New baseline: **val=3.27461/fs=3266.7** (n=3 mean frieren #176).
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
**Mechanism:** NANOGPT_GRAD_CLIP=10.0. Raises embed effective-LR from 8.4% → 16.9% (sweet spot). Clip effect structurally on AdamW aux ONLY (Muon side inert per edward #206).

### frieren NS=12→16 cooldown (#176): **val=3.27461/fs=3266.7 (n=3)** — 2026-05-17 CURRENT BEST
**Mechanism:** NS-iter budget over-provisioned in flat-loss regions, under-provisioned in steep-descent cooldown window. Arm-D confirmed mid-training NS=8 ≈ NS=12 (spectrum saturated). Saturation at NS=16 in cooldown (arm-C NS=20 buys nothing). Singular_range halves from ~0.95 to ~0.47 at the NS=12→16 transition at step 2345 (70% of training). n=3 seeds: arm-B 2xp7ut5r (3.27327/3250), confirm-1 u5mqjzv1 (3.27523/3275), confirm-2 eqhe974m (3.27533/3275). **Also fixed senpai-pr-guard.py false-positive parsing bug (prose mentions of SENPAI-RESULT no longer trip the validator).**

## Wave 4 — Active experiments

### thorfinn #233 (Wave 4 Stack A) 🔥🔥 — JUST ASSIGNED
**Hypothesis:** clip=10 (AdamW aux, merged) × aggressive NS schedule (NS=8mid→NS=16cooldown, Muon blocks). Two orthogonal mechanism axes should compose additively. Expected val ≈ 3.272–3.273 if additive.
- Arm A: control (clip=10 + NS=12→16) = baseline reproduction
- Arm B: clip=10 + NS=8→16 (the key test)
- Arm C: clip=10 + NS=8→20 (exploratory)

### frieren #234 (NS boost trigger fraction sweep) 🔥 — JUST ASSIGNED
**Hypothesis:** The 70% trigger point for NS=12→16 was arbitrary. Sweep {0.55, 0.65, 0.70, 0.75, 0.85}. Earlier trigger = longer NS=16 window; later trigger = more focused precision burst.
- 5-arm sweep; arm-A (0.70) is control

## Wave 3 — Active PRs (still in flight)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#185** | **tanjiro** | **NS iteration annealing** 🔥 | Confirm seeds at arm-B (NS=14→8). ETA TBD. |
| **#188** | **alphonse** | **AdamW aux LR sweep** | arm-E = 0.5× confirm seed in flight. ETA ~07:10 UTC. |
| **#189** | **askeladd** | **Muon² eps sweep** | arm-C (eps=1e-9). Axis likely closing. |
| **#203** | **fern** | **NS polynomial sweep** | arm-C (c=0.35). c axis looks robust. |
| **#206** | **edward** | **Per-group clip mechanism** 🔥 | arm-D (no clip) running, ETA ~07:06 UTC. Hold on edward new assignment until #206 closed. Edward next hyp: Muon mu cooldown scheduling (→ /research/EDWARD_NEXT_HYPOTHESIS.md). |
| **#227** | **nezuko** | **AdamW β1 cooldown decay** | arm-A control queued. Fresh aux responsiveness axis. |

## Edward #206 outstanding decision tree (arm-D pending)

arm-C (muon-only clip=5.0, AdamW UNCLIPPED): val=3.27459/fs=3250 — BEST arm, within noise of old baseline.

Arm-D discriminates:
- If arm-D ≈ arm-C → Muon clip is also neutral; clip mechanism unknown or artifact
- If arm-D regresses vs arm-C → Muon clip IS load-bearing (contradicts prior story)
- If arm-D beats new baseline (3.27461) → no clip beats clip=10?

## Wave 4 candidates (after in-flight PRs close)

1. **thorfinn #233 stack result** — primary wave-4 test; if arm-B confirms, val ~3.272–3.273
2. **frieren #234 trigger-frac result** — if non-70% trigger wins, stack that onto #233
3. **tanjiro #185** — NS=14→8 anneal confirmation; if confirms at n=3, another axis for the stack
4. **nezuko #227 β1 cooldown** — if arm-B wins, three-way stack (clip × NS-schedule × β1) becomes the wave-5 target
5. **edward next (Muon mu cooldown scheduling)** — Muon mu=0.95→0.85 or 0.70 during cooldown; orthogonal to all above; assign after #206 closes

## Closed mechanisms (do not re-explore)

| Category | Mechanism | Evidence |
|----------|-----------|----------|
| Temporal smoothing | Polyak EMA, Lookahead | #104, #120 |
| Element-wise direction shaping | Contra-Soft per-element | #126 |
| Magnitude-coupled trust region | \|\|w\|\|_F coupled cap | #117 |
| LR warmup | 0/50/100 step warmup | #102 |
| Cooldown frac (timing only) | {0.4, 0.5, 0.6} | #106 |
| Cooldown LR shape | cosine, sqrt, quadratic, exp | #204 (nezuko) |
| Lion optimizer (aux) | Lion embed+lm_head | #77 |
| Per-layer NS adaptive | sigmoid-controlled NS iters | #145 |
| Momentum reset (DMR) | periodic v reset with decay | #163 |
| SOAP/Adafactor on aux | Shampoo rotation / factored v | #144, #180 |
| Adam-style BC in Muon² | BC + beta2=0.98 | #115 |
| NS=8 floor test | constant NS=8 | #75 |

## Statistical target

`(3.28 − mu(n=3)) × √3 ≥ 0.004` → mu ≤ 3.27769. Current bar to beat: **3.27461**.
