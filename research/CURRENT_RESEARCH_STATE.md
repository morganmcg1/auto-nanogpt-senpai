# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-15 21:30 UTC (wave 2 launched, wave 1 merged)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** 3275 steps, val=3.2766 (n=2) — **alphonse Muon² merged 2026-05-15**
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged winner — alphonse Muon² (#60) — NOW BASELINE

**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization.
- 2 seeds, both first_step_to_target=3275, val≈3.2766
- n=2 stat-sig: mu=3.276565, margin=0.004859 ≥ 0.004 ✓
- First branch stat-sig crossing of 3.28 in < 3350 steps

## Wave 1 final status

| PR | Student | Result |
|----|---------|--------|
| #60 | alphonse | **MERGED** — Muon² NS=12, 3275 steps, n=2 stat-sig |
| #62 | askeladd | CLOSED — SF-Muon failed (3.3638). Cooldown is load-bearing. |
| #66 | edward | CLOSED — Cosine/linear baseline both NaN/diverged. Branch corruption. |
| #75 | tanjiro | CLOSED — NS=8 safe (within noise), NS=6 fails. Wall-clock savings < 1%. |
| #77 | thorfinn | CLOSED — Lion aux groups failed (3.3109). |

## Active PRs (wave 1 still running + wave 2)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #70 | fern | Cooldown frac=0.5 | Confirm-s4 running (step 2345); n=3 mean=3.279, NOT stat-sig even with seed 4 likely |
| #72 | frieren | Nesterov mu sweep 0.90–0.98 | Screening done (best mu=0.92, val=3.3678); full 3350-step run at mu=0.92 + 0.95 requested |
| #73 | nezuko | WD warmup schedule | In flight |
| #90 | askeladd | muP LR sweep (0.025/0.030/0.035/0.042) | arm-a done (3.2784 @ lr=0.025); arms b/c/d blocked by precision bug (fix sent) |
| #91 | thorfinn | Aspect-ratio formula | Corrected formula (min denominator) sent; WIP |
| #92 | edward | Orthogonal QKV init | Just assigned |
| **#96** | **alphonse** | **Muon² LR retune (0.030/0.0375/0.040)** | **JUST ASSIGNED — wave 2** |
| **#97** | **tanjiro** | **Muon² beta2 sweep (0.95/0.98/0.999)** | **JUST ASSIGNED — wave 2** |

## Wave 2 focus: characterize the Muon² baseline

Wave 1 established:
1. **Muon² (NS=12)** is the mechanism — Adam 2nd-moment preconditioning before NS, 75 steps faster than starter
2. **NS=8 is safe** for compute headroom but < 1% wall-clock gain at this scale
3. **NS=6 fails** (under-orthogonalization)
4. **Cooldown shape**: fern's frac=0.5 shows positive signals but not stat-sig; not a clear win

Wave 2 immediately explores the two hyperparameters in Muon² that are most likely to improve on the new baseline:
- **LR retune** (alphonse #96): lr=0.035 was tuned for vanilla Muon; {0.030, 0.0375, 0.040} sweep
- **beta2 sweep** (tanjiro #97): paper default 0.999 may be wrong for our small-batch/short-horizon regime; {0.95, 0.98, 0.999}

## Potential next research directions (wave 3 candidates)

**Highest priority**:
1. **Muon² + Contra-Soft stack** — wave-1 winner + record #20's mechanism. Target sub-3250.
2. **Muon² + SOAP-MLP** — biggest lever to close gap to 3030. Complex port but highest ceiling.
3. **Muon² + LR + beta2 combined** — if wave 2 finds (lr*, beta2*) ≠ (0.035, 0.999), apply combined tuning.
4. **Muon² + cooldown_frac=0.5** — compose cooldown finding with Muon² if fern's signal holds.

**Diagnostic still needed**:
- Nesterov mu (frieren #72 — awaiting full 3350-step runs)
- muP LR for vanilla Muon (askeladd #90 — b/c/d blocked by bug)
- Orthogonal QKV init (edward #92 — just assigned)
- Aspect-ratio formula (thorfinn #91 — WIP)

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline: `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var now in main branch.
- GitHub rate limit: ~3597/5000 remaining at 21:22 UTC; reset at 1778883580 (~22:26 UTC).
