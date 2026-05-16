# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-16 11:35 UTC (wave 3 three positive signals 🎯 — edward bias-corr val=3.2749/fs=3250, thorfinn clip=5.0 val=3.2742/fs=3250 [new sweep best], frieren polar-express arm-A sanity nearly done; edward confirm seed 1 running; thorfinn confirmation seeds redirected to clip=5.0)
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
| #102 | fern | CLOSED — LR warmup monotone WORSE; clean negative |
| #104 | frieren | CLOSED — Polyak EMA at eval ≥ live val_loss in every arm; cooldown is load-bearing |
| #106 | nezuko | CLOSED — Muon² cooldown_frac: frac=0.6 retry val=3.27766 indistinguishable from baseline; fern PR #70's vanilla-Muon positive does not transfer |
| #117 | alphonse | CLOSED — Trust-region cap by ||w||_F: arm-A=3.27657/3275 EXACT baseline; arms B/C/D all collapse to val~5.69 (self-reinforcing choke loop) |

## Active PRs

### Wave 3 mechanism stacks (5 in flight)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#115** | **edward** | **Muon² + Adam bias correction** | 🎯 **arm-C (bias_corr=on, beta2=0.98) val=3.2749/fs=3250 BEATS BASELINE.** arm-A=3.2793/3325, arm-B=3.2772/3300 (no step-25 divergence at beta2=0.95). arm-D (bias_corr=on, beta2=0.999) running step 2010. Confirmation seeds at beta2=0.98 queued. |
| **#105** | **thorfinn** | **Gradient clipping sweep** | 🎯 **arm-C (clip=5.0) val=3.27420/fs=3250 — NEW SWEEP BEST, beats arm-B.** arm-A (disabled)=3.2789/3325, arm-B (clip=1.0)=3.2755/3275. BOTH B and C beat baseline. Confirmation seeds **redirected to clip=5.0**. |
| #120 | askeladd | **Lookahead Muon² (k inner steps + α blend)** | arm-A=3.2773/3350 (within-noise), arm-B (k=5,α=0.5)=3.2884 (WORSE). arm-C (k=10,α=0.5) running step 2685, val=3.3544 — tracking worse |
| #126 | fern | **Contra-Soft momentum direction shaping** | arm-A (disabled)=3.2762/3275 EXACT baseline. arm-B (α=0.5) KILLED step 1600 val=4.06 (kill gate). arm-C (α=0.25) just launched step 100 — student following kill notice |
| #138 | frieren | **Polar Express NS** (ICLR 2026 Oral) | arm-A (classical NS sanity) running step 1050, val=3.6363 — healthy trajectory |

## Infra-blocked

- **tanjiro** (GPU UUID 7998cef9-...): merged baseline diverges at step 25 (NaN, nonfinite=147M in both smoke tests). ECC clean, same hardware model as healthy pods. Likely silicon-binning bf16 issue. Bias correction work reassigned to edward (#115). Not assigning new work until human/infra team rotates the pod.

## Wave 3 frontier — mechanism stacks

The plateau protocol calls for mechanism extensions beyond hyperparameter tuning. Current direction queue:

**In flight**:
1. **#115 edward — Muon² + bias correction** (Adam-style v_hat) — fixes known mechanism flaw, may unlock lower beta2 values
2. **#117 alphonse — Trust-region Muon²** — CLOSED clean negative on ||w||_F-coupled cap (feedback loop)

### Critical path 🎯 — dual positive signals, confirmation seeds in flight

**Both #115 (bias correction, beta2=0.98) and #105 (grad clip=1.0) produced single-seed baseline-beating results.** Mechanism orthogonality: bias correction touches v-EMA preconditioner; grad clip touches gradient before momentum — independent slots, expected to stack cleanly if both confirm.

**Sequencing**:
1. Edward #115: wait arm-D finish (~80 min) → launch 2 confirmation seeds at beta2=0.98
2. If #115 confirms (mu(n=3) ≤ 3.2777) → merge first as cleanest mechanism win
3. Thorfinn #105: wait arm-C finish → launch 2 confirmation seeds at clip=1.0
4. If #105 also confirms → merge on top of #115
5. Stack test: bias_corr=on + clip=1.0 combined-mechanism PR

### Other in-flight
- **#120 askeladd Lookahead** — arm-B (k=5, α=0.5) val=3.2884 WORSE; arm-C (k=10) tracking similar; likely closes negative
- **#126 fern Contra-Soft** — arm-B (α=0.5) killed at val=4.06 (kill gate); arm-C (α=0.25) just launched; if also fails, element-wise direction-shaping closed (try layer-aggregate next)
- **#138 frieren Polar Express NS** — adaptive NS coefficients (ICLR 2026 Oral); arm-A sanity in flight

### Newly assigned (idle students)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#144** | **alphonse** | **SOAP for AdamW aux groups** (embed + lm_head Shampoo preconditioner) | just assigned |
| **#145** | **nezuko** | **Per-layer adaptive NS iterations** (budget-neutral redistribution by singular spread) | just assigned |
| **#146** | **tanjiro** | **NS-iters annealing schedule** (high-to-low; smoke-test gate first) | just assigned; smoke gate required |

### Next-tier (future assignments)
- **Polar-decomposition Muon** — exact orthogonalization via SVD on smaller projections vs iterative NS
- **Muon for embed/lm_head** — apply Muon² to all params (not just blocks), unifying the optimizer
- **Contra-Muon layer-aggregate** — if fern #126 closes negative, try inner-product (per-layer) conflict score instead of element-wise sign
- **Grad clip per-group (thorfinn follow-up)** — different thresholds for Muon blocks vs AdamW aux groups

**Key insight (edward's #92 mechanism analysis)**: Newton-Schulz continuously re-orthogonalizes Muon-trained matrices within ~50 steps; init structure is irrelevant for those. Init experiments only matter for AdamW-trained matrices (embed/lm_head). This narrows the init-exploration space.

**Failed-mechanism pattern to avoid**: magnitude-suppression that depends on current weight/update creates self-reinforcing feedback loops at init (alphonse #117 trust-region; fern #126 arm-B Contra-Soft α=0.5). Any future mechanism with this structure should delay activation past step N or use NS-natural scale invariants (sqrt(min(rows,cols)) not ||w||_F).

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM, multi-step optimizers that need extra forwards).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline includes `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var.
- 1 GPU per student node — sequential arm execution required.
- **Pattern (post-tanjiro pod issue)**: All Muon²-touching PRs should include 100-step smoke test before launching long arms.
- **Pattern (post-thorfinn crashes)**: Always commit code to branch before launching long arms; uncommitted state combined with potential pod preemption produces unrecoverable crashes.
