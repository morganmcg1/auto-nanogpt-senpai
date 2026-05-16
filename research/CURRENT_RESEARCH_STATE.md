# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-16 02:00 UTC (wave 2 in execution; tanjiro infra-blocked on pod)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** 3275 steps, val=3.2766 (n=2) — alphonse Muon² merged 2026-05-15
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — alphonse Muon² (#60)

**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization. 2 seeds, both first_step=3275, val≈3.2766. n=2 stat-sig: mu=3.276565, margin=0.004859.

**Known mechanism flaw (diagnosed by tanjiro #97):** No Adam-style bias correction `v_hat = v / (1-beta2^t)`. Currently un-fixable due to infra-block on tanjiro pod (the natural follow-up assignee).

## Closed PRs

| PR | Student | Result |
|----|---------|--------|
| #60 | alphonse | **MERGED** — Muon² NS=12, 3275 steps, n=2 stat-sig |
| #62 | askeladd | CLOSED — SF-Muon failed (3.3638). Cooldown is load-bearing. |
| #66 | edward | CLOSED — Cosine/linear baseline both NaN. Branch corruption. |
| #70 | fern | CLOSED — frac=0.5 n=4 mean=3.27924, margin=0.00152 NOT stat-sig |
| #72 | frieren | CLOSED — Nesterov mu=0.92 full-length val=3.2811, worse than baseline |
| #73 | nezuko | CLOSED — WD warmup n=2 mean=3.27919, margin=0.00114 NOT stat-sig |
| #75 | tanjiro | CLOSED — NS=8 safe (within noise), NS=6 fails. |
| #77 | thorfinn | CLOSED — Lion aux groups failed (3.3109). |
| #91 | thorfinn | CLOSED — aspect-ratio formula NaN cascade, branch corruption. |
| #97 | tanjiro | CLOSED INCONCLUSIVE — pod-level GPU divergence on merged baseline |
| #108 | tanjiro | CLOSED — smoke test re-confirmed pod broken; infra-block |

## Active PRs (wave 2)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #90 | askeladd | muP LR sweep on vanilla Muon | arm-A=3.2807; blocked on rebase (commented) |
| #92 | edward | Orthogonal QKV init | **arm-A=3.27862 (worse than baseline)**; arm-B normal-init running at step 2150, val=3.428 |
| #96 | alphonse | Muon² LR retune | **arm-A=3.27815, arm-B=3.27709 (both worse)**; arm-C (lr=0.040) running, val=3.94 @ step 400 |
| #102 | fern | LR warmup sweep | **arm-A=3.27699 (warmup=0 baseline reproduction)**; arm-B (warmup=50) running at step 375, val=3.97 |
| #104 | frieren | Polyak EMA model weight averaging | arm-A (decay=0.99) running at step 1550, val=3.522 |
| #105 | thorfinn | Gradient clipping sweep | arm-A (clip=disabled baseline) running at step 2025, val=3.441 |
| #106 | nezuko | Muon² cooldown_frac sweep | arm-A (frac=0.4) running at step 2000, val=3.512 |

## Infra-blocked

- **tanjiro** (GPU UUID 7998cef9-...): merged baseline diverges at step 25 (first Muon² weight update produces Inf in 20 entries). ECC clean, same hardware model as healthy pods. Likely silicon-binning bf16 issue. Closed PR #108. Not assigning new work until human/infra team rotates the pod.

## Wave 2 emerging picture (as of 02:00 UTC)

Six hyperparameter probes are all landing in **3.27699 - 3.27862** range — clustered just above the merged baseline 3.2766 with no decisive improvement:

- alphonse #96 LR retune: lr=0.030 → 3.27815, lr=0.0375 → 3.27709 (best so far, still ≥3.275 threshold)
- edward #92 init: orthogonal QKV → 3.27862
- fern #102 warmup: warmup=0 (baseline reproduction) → 3.27699 (consistent with baseline noise band)

**No arm has triggered confirmation-seed criterion (val < 3.275).** Two interpretations:
1. The Muon² baseline is genuinely near a local optimum on this 3350-step recipe — small perturbations of LR/init/warmup/cooldown don't shift it.
2. Stat-sig measurement requires n≥3 seeds AND a 0.004-margin lead, which is harder than crossing 3.28 once.

If wave 2 closes with no merge-eligible result, the **plateau protocol** kicks in: bigger mechanism changes (Muon² + bias correction is the natural one, blocked on tanjiro pod; Muon² + Contra-Soft or Muon² + SOAP-MLP are the next-tier stack mechanisms).

## Potential next research directions

**Driven by wave 2 evidence + plateau protocol**:
1. **Muon² + bias correction** — blocked on tanjiro pod; reassign to another student if infra delay continues.
2. **Muon² + Contra-Soft stack** — record #20's mechanism; bigger ceiling, higher complexity.
3. **Muon² + SOAP-MLP for AdamW aux groups** — biggest lever to close gap to 3030.
4. **Trust-region Muon** — per-layer update norm cap, complementary to NS orthogonalization.

**If standard practices (fern #102 warmup, thorfinn #105 clip, frieren #104 EMA, nezuko #106 cooldown) deliver no signal**: pivot all wave-3 students to mechanism stacks rather than continued hyperparameter sweeps.

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline includes `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var.
- 1 GPU per student node — sequential arm execution required.
- **Pattern (post-tanjiro pod issue)**: All Muon²-touching PRs should include 100-step smoke test before launching long arms.
- GitHub rate limit: ~790/5000 remaining at 02:00 UTC; will reset ~02:39 UTC.
