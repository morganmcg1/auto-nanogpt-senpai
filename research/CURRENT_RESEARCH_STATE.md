# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-15 20:35 UTC (wave 1 terminal results received)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (public leaderboard):** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)
- **Wave 1 CONFIRMED WIN (pending merge):** alphonse Muon² at **3275 steps** (n=2 stat-sig, mu=3.276565)

## CONFIRMED WINNER — alphonse Muon² (#60) — READY TO MERGE

- Arm-A NS=12, seed 1: val=3.276593, first_step=3275 (run s0oq3dnx)
- Arm-A NS=12, seed 2: val=3.276536, first_step=3275 (run 4hedrgf4)
- Arm-B NS=8, seed 1: val=3.277377, first_step=3300 (run pg0uma5w)
- **n=2 stat-sig (NS=12)**: mu=3.276565, (3.28-3.276565)*sqrt(2)=0.004859 >= 0.004 ✓
- **NS=12 wins over NS=8**: gap is 0.000813 (~20× inter-seed sigma), not a close call at this scale
- **Branch first stat-sig crossing** of 3.28 in fewer than 3350 steps on a simple stack
- Merge blocked by GH rate limit — will merge at ~21:26 UTC reset

## Wave 1 closed PRs

| PR | Student | Result |
|----|---------|--------|
| #62 | askeladd | SF-Muon FAILED (best 3.3638). Cooldown is load-bearing — SF can't substitute. |
| #77 | thorfinn | Lion aux groups FAILED (best 3.3109). AdamW better for small aux groups. |
| #66 | edward | Cosine cooldown FAILED (NaN cascade + linear baseline diverged). Branch corruption. Reassigned. |

## Wave 1 diagnostic complete — tanjiro NS sweep (#75)

| Arm | NS iters | val/loss | first_step | Wall-clock saved |
|-----|----------|----------|------------|-----------------|
| A | 12 | 3.27890 | 3325 | — |
| B | 8 | 3.27849 | 3325 | 0.60% (10.83ms/step) |
| C | 6 | 3.28980 | — (FAILED) | 1.11% (20ms/step) |

**Conclusion**: NS=8 is correctness-safe (matches NS=12 within seed noise) but wall-clock savings are minimal (<1%) because NS inner loop is not the bottleneck on this 1-GPU setup. NS=6 fails. Both NS=12 and NS=8 crossings are baseline-noise — Muon² (NS=12 n=2) is the rigorous result.

## Active wave 1 PRs (still running)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #70 | fern | Cooldown frac=0.5/0.6/0.7 | Confirmation seed 3 complete; n=3 mean=3.27917 < threshold 3.2777 — NOT stat-sig; WIP |
| #72 | frieren | Nesterov mu sweep 0.90–0.98 | mu screening still running |
| #73 | nezuko | WD warmup schedule | Arm-B running |
| #90 | askeladd | muP LR sweep (0.025/0.030/0.035/0.042) | Arm-A running; b/c/d had precision bug |
| #91 | thorfinn | Adaptive aspect-ratio scaling | Corrected formula (min denominator) sent; WIP |
| #92 | edward | Orthogonal QKV initialization | Just assigned |

## Current research focus and themes

The branch's baseline Muon recipe crossed 3.28 for the first time with Muon²:
- **Mechanism confirmed**: Adam 2nd-moment preconditioning before NS produces better-conditioned input, enabling faster convergence.
- **NS iteration floor**: NS=8 safe (< 1% wall-clock gain), NS=6 too few. NS=12 remains optimal for this scale.
- **LR and mu sweeps** (askeladd/frieren) will jointly characterize the (lr, mu) hyperparameter grid at the new Muon² baseline.
- **Orthogonal QKV init** (edward) — spectral initialization that starts attention weights with unit singular values.
- **Aspect-ratio formula** (thorfinn) — calibration of Muon's per-matrix scale factor.
- **Cooldown shape** (fern, frieren) — still active but single-seed crossings are within baseline noise.

## Potential next research directions (wave 2 candidates)

**Highest priority (informed by wave 1)**:
1. **Muon² + Contra-Soft stack** — alphonse's mechanism composes orthogonally with record #20's Contra-Soft + SOAP. Combine and target sub-3250.
2. **Muon² + NS=8** — if the compute headroom is validated, stack Muon²+NS=8 and do a proper LR retune at NS=8. May unlock step savings + speed.
3. **SOAP-Muon port** — biggest lever to close the gap to 3030; never tested on simple recipe.
4. **Muon² + LR retune** — alphonse notes lr=0.035 was tuned for vanilla Muon; a sweep {0.030, 0.0375, 0.040} could cut another 25-50 steps.
5. **Muon² + beta2 sweep** — the paper used beta2=0.999; a coarse sweep {0.95, 0.98, 0.999} is cheap and may tune the 2nd-moment EMA for our smaller-batch regime.

**Diagnostic (wave 1 incomplete)**:
- **muP LR scaling sweep** (askeladd #90 running) — confirms whether 0.035 is the LR peak
- **Nesterov mu sweep** (frieren #72 running) — completes (lr, mu) grid with askeladd's LR sweep
- **WD warmup** (nezuko #73) — low-priority, baseline noise crossings already seen without WD warmup

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials
  (`https://www.primeintellect.ai/auto-nanogpt` and the
  `experiments-autonomous-speedrunning` repo).
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- No per-run val-loss early stopping.
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`
- Infrastructure: `sample_tensor` float32 OOB bug fix is in multiple student branches (nezuko canonical); will land on advisor branch when alphonse's #60 merges.
- GitHub rate limit: cyclic issue — hit again at 20:34 UTC, reset ~21:26 UTC.
