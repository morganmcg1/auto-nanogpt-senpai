# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-15 23:55 UTC (wave 2 in full execution, all 7 students assigned)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** 3275 steps, val=3.2766 (n=2) — alphonse Muon² merged 2026-05-15
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — alphonse Muon² (#60)

**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization.
- 2 seeds, both first_step_to_target=3275, val≈3.2766
- n=2 stat-sig: mu=3.276565, margin=0.004859 ≥ 0.004 ✓
- Bundled: `sample_tensor` float64 precision fix, `NANOGPT_NS_ITERS` env var

## Wave 1 + 2 closed PRs

| PR | Student | Result |
|----|---------|--------|
| #60 | alphonse | **MERGED** — Muon² NS=12, 3275 steps, n=2 stat-sig |
| #62 | askeladd | CLOSED — SF-Muon failed (3.3638). Cooldown is load-bearing. |
| #66 | edward | CLOSED — Cosine/linear baseline both NaN/diverged. Branch corruption. |
| #70 | fern | CLOSED — frac=0.5 n=4 mean=3.27924, margin=0.00152 NOT stat-sig |
| #72 | frieren | CLOSED — Nesterov mu=0.92 full-length val=3.2811, worse than baseline |
| #73 | nezuko | CLOSED — WD warmup n=2 mean=3.27919, margin=0.00114 NOT stat-sig |
| #75 | tanjiro | CLOSED — NS=8 safe (within noise), NS=6 fails. Wall-clock savings < 1%. |
| #77 | thorfinn | CLOSED — Lion aux groups failed (3.3109). |
| #91 | thorfinn | CLOSED — aspect-ratio formula NaN cascade, branch corruption. |

## Active PRs (wave 2 — all 7 students engaged)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #90 | askeladd | muP LR sweep on vanilla Muon (0.025/0.030/0.035/0.042) | arm-A=3.2807; arms B/C/D blocked on rebase (commented) |
| #92 | edward | Orthogonal QKV init | arm-A descending normally (3.3438 @ step 2750); arm-B normal-init queued sequential |
| #96 | alphonse | Muon² LR retune (0.030/0.0375/0.040) | arm-A=3.2781 (worse than baseline); arm-B running, arm-C queued |
| #97 | tanjiro | Muon² beta2 sweep (0.95/0.98/0.999) | beta2=0.95 AND 0.98 hard-diverge at step 25 (no bias correction); arm-C (0.999) confirming baseline |
| #102 | fern | LR warmup sweep (0/50/100/200 steps) | Just assigned, no runs yet |
| #104 | frieren | Polyak EMA model weight averaging | Just assigned, no runs yet |
| #105 | thorfinn | Gradient clipping sweep (0.0/1.0/5.0) | Just assigned, no runs yet |
| #106 | nezuko | Muon² cooldown_frac sweep (0.4/0.5/0.6/0.7) | **JUST ASSIGNED — extends fern's positive cooldown signal onto Muon²** |

## Wave 2 focus

Three complementary thrusts:

**(a) Characterize Muon² hyperparameters** — the merged mechanism inherited paper defaults:
- LR retune (alphonse #96): lr=0.030 worse, awaiting 0.0375/0.040
- beta2 sweep (tanjiro #97): **DIAGNOSTIC RESULT** — Muon² lacks Adam-style bias correction; only beta2=0.999 stable. Suggests follow-up: add `v_hat = v/(1-beta2^t)` and re-sweep.
- cooldown_frac on Muon² (nezuko #106): extend fern's positive vanilla-Muon signal

**(b) Standard practices skipped by starter** — orthogonal to Muon mechanism:
- LR warmup (fern #102)
- Gradient clipping (thorfinn #105)
- Polyak EMA at eval (frieren #104)

**(c) Initialization & architecture probes**:
- Orthogonal QKV init (edward #92)
- muP LR scaling on vanilla Muon (askeladd #90 — needs rebase)

## Potential next research directions (wave 3 candidates)

**Driven by wave 2 evidence**:
1. **Muon² + bias correction** — tanjiro #97's diagnostic shows Muon² is stuck at beta2=0.999 due to no `(1-beta2^t)` correction. Add bias correction and re-sweep beta2. Likely tanjiro's natural follow-up.
2. **Muon² + (lr*, beta2*, cooldown_frac*) combined** — apply wave-2 sweep findings together.
3. **Muon² + best standard practice** — compose any of {warmup, clip, EMA} that show signal.

**Higher-effort stack mechanisms**:
4. **Muon² + Contra-Soft stack** — wave-1 winner + record #20's mechanism. Target sub-3250.
5. **Muon² + SOAP-MLP** — biggest lever to close gap to 3030. Complex port but highest ceiling.

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline includes `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var.
- 1 GPU per student node — sequential arm execution required (concurrent torchrun → OOM); pattern: `run_arms_sequential.sh`.
- GitHub rate limit: ~4000/5000 remaining at 23:50 UTC; reset at 1778894384 (~00:30 UTC tomorrow).
- Branch corruption pattern: PRs #66, #91 both had NaN cascades from working tree drift. Solution: all new PRs include explicit `git reset --hard origin/auto-nanogpt-1gpu-r4` instruction.
