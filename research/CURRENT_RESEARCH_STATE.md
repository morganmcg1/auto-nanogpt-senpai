# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-16 02:45 UTC (wave 2 execution; tanjiro infra-blocked; edward reassigned to bias correction)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** 3275 steps, val=3.2766 (n=2) — alphonse Muon² merged 2026-05-15
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — alphonse Muon² (#60)

**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization. 2 seeds, both first_step=3275, val≈3.2766. n=2 stat-sig: mu=3.276565, margin=0.004859.

**Known mechanism flaw (diagnosed by tanjiro #97):** No Adam-style bias correction `v_hat = v / (1-beta2^t)`. Tanjiro pod infra-blocked so reassigned to edward (#115).

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
| #92 | edward | CLOSED — Orthogonal QKV init: arm-A val=3.27862 fs=3325, arm-B val=3.27804 fs=3300. Clean negative: NS continuously re-orthogonalizes QKV updates, eclipsing init structure within ~50 steps. |
| #97 | tanjiro | CLOSED INCONCLUSIVE — pod-level GPU divergence on merged baseline |
| #108 | tanjiro | CLOSED — smoke test re-confirmed pod broken; infra-block |

## Active PRs (wave 2)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #90 | askeladd | muP LR sweep on vanilla Muon | arm-A val=3.2807 (lr=0.025); arm-B val=3.27788 fs=3300 (lr=0.030); arm-C (lr=0.035-vanilla) running step 3225 val=3.2865 |
| #96 | alphonse | Muon² LR retune | arm-A val=3.27815 fs=3300 (lr=0.030); arm-B val=3.27709 fs=3300 (lr=0.0375); arm-C (lr=0.040) running step 2100 val=3.452 |
| #102 | fern | LR warmup sweep | arm-A val=3.27699 fs=3300 (warmup=0, baseline repro); arm-B (warmup=50) running step 2050 val=3.447 |
| #104 | frieren | Polyak EMA model weight averaging | arm-A (decay=0.99) running step 3100 val=3.2985 — EMA appears to degrade val |
| #105 | thorfinn | Gradient clipping sweep | **STALLED** — 3 consecutive arm-A crashes (process kill, nf=0). Sent back for diagnosis + smoke test. |
| #106 | nezuko | Muon² cooldown_frac sweep | arm-A (frac=0.4) val=3.28358 fs=-1 DONE; arm-B (frac=0.5) running step 225 |
| #115 | edward | Muon² Adam-style bias correction | **NEWLY ASSIGNED** — 4 arms: A (off/0.999 baseline), B (on/0.95), C (on/0.98), D (on/0.999) |

## Infra-blocked

- **tanjiro** (GPU UUID 7998cef9-...): merged baseline diverges at step 25 (NaN, nonfinite=147M in both smoke tests lk0xojgy and asri4q5f). ECC clean, same hardware model as healthy pods. Likely silicon-binning bf16 issue. Bias correction work reassigned to edward (#115). Not assigning new work until human/infra team rotates the pod.

## Wave 2 plateau picture (as of 02:45 UTC)

All hyperparameter probes landing in **3.27699 - 3.27862** range with first_step in {3300, 3325} — WORSE than merged baseline 3275. No arm has triggered confirmation-seed criterion (val < 3.275 or first_step < 3275).

| Arm | val | first_step | vs baseline |
|-----|-----|-----------|------------|
| alphonse #96 arm-B lr=0.0375 | 3.27709 | 3300 | +25 steps (worse) |
| fern #102 arm-A warmup=0 | 3.27699 | 3300 | +25 steps (worse) |
| edward #92 arm-B normal init | 3.27804 | 3300 | +25 steps (worse) |
| edward #92 arm-A orthogonal | 3.27862 | 3325 | +50 steps (worse) |
| nezuko #106 arm-A frac=0.4 | 3.28358 | -1 | failed to cross 3.28 |

**Interpretation**: The Muon² baseline is at a local optimum for small perturbations of LR/init/warmup/cooldown. Standard hyperparameter probes have been exhausted. **Wave 2 is triggering the plateau protocol**.

## Plateau protocol — wave 3 direction

Wave 2 negative on all hyperparameter probes → escalate to mechanism stacks:

1. **Muon² + bias correction** ← edward #115 (HIGHEST PRIORITY — fixes known flaw, enables meaningful beta2 sweep)
2. **Muon² + Contra-Soft** — record #20's mechanism; biggest ceiling, higher complexity
3. **Muon² + SOAP-MLP for AdamW aux groups** — largest lever to close gap to 3030
4. **Trust-region Muon** — per-layer update norm cap, complementary to NS

When wave 2 fully closes (all arms terminal), pivot all idle students to mechanism stacks. The hyperparameter knobs {LR, init, warmup, cooldown_frac, grad_clip, EMA} are exhausted as lone interventions.

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline includes `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var.
- 1 GPU per student node — sequential arm execution required.
- **Pattern (post-tanjiro pod issue)**: All Muon²-touching PRs should include 100-step smoke test before launching long arms.
- GitHub rate limit: ~790/5000 remaining at 02:00 UTC; reset at ~02:39 UTC.
- **Edward NS insight (#92)**: Newton-Schulz continuously re-orthogonalizes QKV updates within ~25-50 steps — init structure is irrelevant for Muon-trained matrices. Only AdamW-trained matrices (embedding, lm_head) where init persists are worth init experiments.
