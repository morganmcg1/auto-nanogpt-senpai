# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-15 22:30 UTC (wave 2 expanded; all students assigned)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** 3275 steps, val=3.2766 (n=2) — alphonse Muon² merged 2026-05-15
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — alphonse Muon² (#60)

**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization.
- 2 seeds, both first_step_to_target=3275, val≈3.2766
- n=2 stat-sig: mu=3.276565, margin=0.004859 ≥ 0.004 ✓
- First branch stat-sig crossing of 3.28 in < 3350 steps
- Bundled: `sample_tensor` float64 precision fix, `NANOGPT_NS_ITERS` env var

## Wave 1 final status

| PR | Student | Result |
|----|---------|--------|
| #60 | alphonse | **MERGED** — Muon² NS=12, 3275 steps, n=2 stat-sig |
| #62 | askeladd | CLOSED — SF-Muon failed (3.3638). Cooldown is load-bearing. |
| #66 | edward | CLOSED — Cosine/linear baseline both NaN/diverged. Branch corruption. |
| #70 | fern | CLOSED — frac=0.5 n=4 mean=3.27924, margin=0.00152 NOT stat-sig |
| #72 | frieren | CLOSED — Nesterov mu=0.92 full-length val=3.2811, worse than baseline |
| #73 | nezuko | WD warmup — all 4 arms ~3.279, not stat-sig (terminal SENPAI-RESULT pending) |
| #75 | tanjiro | CLOSED — NS=8 safe (within noise), NS=6 fails. Wall-clock savings < 1%. |
| #77 | thorfinn | CLOSED — Lion aux groups failed (3.3109). |
| #91 | thorfinn | CLOSED — aspect-ratio formula NaN cascade, branch corruption. |

## Active PRs (wave 2)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #90 | askeladd | muP LR sweep on vanilla Muon (0.025/0.030/0.035/0.042) | arm-A=3.2807; sequential launcher running B/C/D |
| #92 | edward | Orthogonal QKV init | Running; awaiting normal-init sanity arm |
| #96 | alphonse | Muon² LR retune (0.030/0.0375/0.040) | arm-A=3.2781; arms B/C pending |
| #97 | tanjiro | Muon² beta2 sweep (0.95/0.98/0.999) | arm-A NaN diagnosis; arm-B at step 0 |
| #102 | fern | LR warmup sweep (0/50/100/200 steps) | Just assigned |
| **#104** | **frieren** | **Polyak EMA model weight averaging** | **JUST ASSIGNED — wave 2 eval-only** |
| **#105** | **thorfinn** | **Gradient clipping sweep (0.0/1.0/5.0)** | **JUST ASSIGNED — wave 2 std practice** |

## Wave 2 focus

Two complementary thrusts:

**(a) Characterize Muon² hyperparameters** — the merged mechanism inherited paper defaults that may not be optimal for our 1-GPU/3350-step regime:
- LR retune (alphonse #96)
- beta2 sweep (tanjiro #97)
- combined retune as wave-3 follow-up if either finds (lr*, beta2*) ≠ default

**(b) Standard practices skipped by starter** — orthogonal to Muon mechanism, plausibly free improvements:
- LR warmup (fern #102): starter has zero warmup, unusual for transformer recipes
- Gradient clipping (thorfinn #105): starter has no clipping, also unusual
- Polyak EMA at eval (frieren #104): late-training weight smoothing for free margin

**(c) Initialization & architecture** — single-shot probes:
- Orthogonal QKV init (edward #92)
- muP LR scaling on vanilla Muon (askeladd #90)

## Potential next research directions (wave 3 candidates)

**Highest priority** (compose merged mechanism with promising findings):
1. **Muon² + Contra-Soft stack** — wave-1 winner + record #20's mechanism. Target sub-3250.
2. **Muon² + SOAP-MLP** — biggest lever to close gap to 3030. Complex port but highest ceiling.
3. **Muon² + (lr*, beta2*) combined** — apply wave-2 sweep findings together.
4. **Muon² + best standard practice** — compose any of {warmup, clip, EMA} that show signal.

**Diagnostic still needed**:
- WD warmup terminal results (nezuko #73)
- Aspect-ratio formula (if thorfinn returns to it after grad-clip)

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline: `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var now in main branch.
- GitHub rate limit: ~375/5000 remaining at 22:30 UTC; reset at 1778890783 (~23:26 UTC). Conserve calls until reset.
- Two prior PRs (#66, #91) NaN-cascaded from branch corruption. Future PRs include explicit clean-rebase instruction.
