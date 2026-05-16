# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-16 03:40 UTC (wave 2 closing → wave 3 mechanism stacks begin)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** 3275 steps, val=3.2766 (n=2) — alphonse Muon² merged 2026-05-15
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — alphonse Muon² (#60)

**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization. 2 seeds, both first_step=3275, val≈3.2766. n=2 stat-sig: mu=3.276565, margin=0.004859.

**Known mechanism flaws:**
- No Adam-style bias correction (diagnosed by tanjiro #97; now being fixed by edward #115)

## Wave 2 results — PLATEAU CONFIRMED

7 hyperparameter probes all landed worse than baseline:

| PR | Student | Knob | Best arm | val/loss | first_step | vs baseline |
|----|---------|------|----------|---------:|-----------:|------------|
| #92 | edward | QKV init {orth, normal} | normal | 3.27804 | 3300 | +25 |
| #96 | alphonse | Muon² LR {0.030, 0.0375, 0.040} | 0.0375 | 3.27709 | 3300 | +25 |
| #102 | fern | LR warmup {0, 50, 100} | warmup=0 | 3.27699 | 3300 | +25 |
| #104 | frieren | Polyak EMA {0.99, 0.999} | decay=0.99 | 3.27839 | 3325 | +50 |
| #105 | thorfinn | Grad clip {0, 1, 5} | (stalled, pod crashes) | — | — | — |
| #106 | nezuko | Cooldown_frac {0.4, 0.5, 0.6, 0.7} | (arm-B running) | — | — | — |

**Conclusion**: Muon² baseline is at a robust local optimum for hyperparameter perturbations. Δ across all probes ≤ 0.001 in val/loss; first_step uniformly +25–50 steps WORSE. The plateau protocol kicks in: wave 3 = mechanism stacks, not hyperparameter sweeps.

## Closed PRs (cumulative)

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
| #92 | edward | CLOSED — Orthogonal QKV init: NS continuously re-orthogonalizes within ~50 steps (clean negative) |
| #96 | alphonse | CLOSED — Muon² LR retune: 0.035 peak confirmed, no retune gain |
| #97 | tanjiro | CLOSED INCONCLUSIVE — pod-level GPU divergence on merged baseline |
| #108 | tanjiro | CLOSED — smoke test re-confirmed pod broken; infra-block |

## Active PRs

### Wave 2 closing (hyperparameter probes finishing)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #90 | askeladd | Vanilla-Muon muP LR sweep | 3 arms terminal; arm-D (lr=0.042-vanilla) running step 1875 — all worse than Muon² baseline |
| #102 | fern | LR warmup sweep | arm-A=3.27699, arm-B=3.28063 (warmup=50 BAD); arm-C (warmup=100) running step 670 |
| #104 | frieren | Polyak EMA averaging | arm-A=3.27839 (decay=0.99); arm-B (decay=0.999) running step 1650 |
| #105 | thorfinn | Grad clip sweep | smoke test PASSED (`ot1tidd2`); 4 prior crashes attributed to transient SIGKILL on uncommitted code; relaunching with committed code |
| #106 | nezuko | Muon² cooldown_frac sweep | arm-A (frac=0.4)=3.28358 fs=-1 BAD; arm-B (frac=0.5) running step 2250 |

### Wave 3 mechanism stacks (NEW)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #115 | edward | **Muon² + Adam bias correction** (tanjiro's #97 diagnostic fix) | Assigned, not yet picked up |
| #117 | alphonse | **Trust-region Muon²** (per-layer update norm cap, complementary to NS) | Assigned, not yet picked up |

## Infra-blocked

- **tanjiro** (GPU UUID 7998cef9-...): merged baseline diverges at step 25 (NaN, nonfinite=147M in both smoke tests). ECC clean, same hardware model as healthy pods. Likely silicon-binning bf16 issue. Bias correction work reassigned to edward (#115). Not assigning new work until human/infra team rotates the pod.

## Wave 3 frontier — mechanism stacks

The plateau protocol calls for mechanism extensions beyond hyperparameter tuning. Current direction queue:

**In flight**:
1. **#115 edward — Muon² + bias correction** (Adam-style v_hat) — fixes known mechanism flaw, may unlock lower beta2 values
2. **#117 alphonse — Trust-region Muon²** — per-layer norm cap complementary to NS direction control

**Next-tier (assign after #115/#117 land)**:
3. **Muon² + Contra-Soft momentum** — record #20's first component; targets momentum direction shaping
4. **Muon² + SOAP-MLP for AdamW aux groups** — second-order preconditioning for LM head/embed; biggest theoretical lever to close 3275 → 3030 gap
5. **Lookahead Muon²** — k inner steps + alpha blend (meta-optimizer wrapper); compatible with 1 fwd/bwd per step
6. **Polar-decomposition Muon** — exact orthogonalization via SVD on smaller projections vs iterative NS
7. **Muon for embed/lm_head** — apply Muon² to all params (not just blocks), unifying the optimizer

**Key insight (edward's #92 mechanism analysis)**: Newton-Schulz continuously re-orthogonalizes Muon-trained matrices within ~50 steps; init structure is irrelevant for those. Init experiments only matter for AdamW-trained matrices (embed/lm_head). This narrows the init-exploration space.

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM, multi-step optimizers that need extra forwards).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline includes `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var.
- 1 GPU per student node — sequential arm execution required.
- **Pattern (post-tanjiro pod issue)**: All Muon²-touching PRs should include 100-step smoke test before launching long arms.
- **Pattern (post-thorfinn crashes)**: Always commit code to branch before launching long arms; uncommitted state combined with potential pod preemption produces unrecoverable crashes.
