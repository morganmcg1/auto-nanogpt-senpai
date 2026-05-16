# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-16 14:40 UTC (wave 3 confirmation seeds advancing 🎯 — edward confirm-2 step 1200/3350 ETA ~70 min, thorfinn confirm-2 step 475/3350 launched on schedule ETA ~110 min. Tanjiro pod 3rd-time confirmed broken — issue #160 filed.)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** 3275 steps, val=3.2766 (n=2) — alphonse Muon² merged 2026-05-15
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — alphonse Muon² (#60)

**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization. 2 seeds, both first_step=3275, val≈3.2766. n=2 stat-sig: mu=3.276565, margin=0.004859.

**Known mechanism flaw (being fixed by edward #115):**
- No Adam-style bias correction (diagnosed by tanjiro #97; edward #115 arm-C confirms fix)

## Wave 2 results — PLATEAU CONFIRMED

7 hyperparameter probes all landed worse than baseline:

| PR | Student | Knob | Best arm | val/loss | first_step | vs baseline |
|----|---------|------|----------|---------:|-----------:|------------|
| #92 | edward | QKV init {orth, normal} | normal | 3.27804 | 3300 | +25 |
| #96 | alphonse | Muon² LR {0.030, 0.0375, 0.040} | 0.0375 | 3.27709 | 3300 | +25 |
| #102 | fern | LR warmup {0, 50, 100} | warmup=0 | 3.27699 | 3300 | +25 |
| #104 | frieren | Polyak EMA {0.99, 0.999} | decay=0.99 | 3.27839 | 3325 | +50 |
| #106 | nezuko | Cooldown_frac {0.4, 0.5, 0.6, 0.7} | (arm-C retry) | 3.27766 | 3300 | +25 |

**Conclusion**: Muon² baseline is at a robust local optimum for hyperparameter perturbations. Plateau protocol kicks in: wave 3 = mechanism stacks, not hyperparameter sweeps.

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
| #120 | askeladd | CLOSED — Lookahead Muon²: all arms within-noise or worse; arms A+D identical val=3.27731/fs=3300 (temporal-smoothing family CLOSED; same root cause as #104) |
| #126 | fern | CLOSED — Contra-Soft element-wise: arm-A=3.27616/3275 EXACT baseline; conflict_fraction ≈ 0.50 across all phases proves element-wise signal is noise-dominated; clean negative with mechanistic diagnosis |
| #146 | tanjiro | AUTO-MERGED accidentally (advisor-side merge bug); reassigned as #149 |
| #149 | tanjiro | CLOSED infra-blocked — 3rd reproduction of pod NaN cascade on unmodified baseline (step-1 grad=232102, step-25 nonfinite=147M). Issue #160 filed for pod rotation. |

## Active PRs

### Wave 3 mechanism stacks — critical path 🎯

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#115** | **edward** | **Muon² + Adam bias correction** | 🎯 **arm-C (bias_corr=on, beta2=0.98) val=3.2749/fs=3250 BEATS BASELINE.** D=3.2768/3300. confirm-1=3.2754/3275 ✅. confirm-2 (`wxs7if5z`) running step 1200/3350, val=3.604 healthy. ETA ~70 min. n=2 partial mu=3.27515 — plenty of margin. |
| **#105** | **thorfinn** | **Gradient clipping sweep** | 🎯 **arm-C (clip=5.0) val=3.2742/fs=3250 NEW SWEEP BEST.** arm-B (clip=1.0)=3.2755/3275. confirm-1 (`yfhknwar`) **FINISHED val=3.2748/fs=3250 EXACT MATCH** ✅. confirm-2 (`j4r186ws`) running step 475/3350 launched on schedule. ETA ~110 min. n=2 partial mu=3.27450 — excellent margin. |

**Key mechanism insight from thorfinn's gradient norm analysis:** Raw global_norm is 4–5 orders of magnitude larger than both clip thresholds → clip is active at EVERY step → not clipping rare spikes but full-time gradient rescaling. NS already absorbs magnitude for Muon blocks → clip only has effect on AdamW aux groups (embed/lm_head). Grad clip = effective AdamW aux LR multiplier.

### Wave 3 other in-flight

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #138 | frieren | **Polar Express NS** (ICLR 2026 Oral) | arm-A=3.2783/3325 (within-noise baseline sanity ✓). arm-B (PE iters=12) running step ~1575, val=3.524 — tracking slightly behind arm-A at this step. arm-C/D queued. |
| **#154** | **fern** | **Layer-aggregate Contra-Muon** | smoke test `4vfw6ubf` running step 425/500, val=3.856 healthy. Awaiting smoke gate verdict. |
| **#144** | **alphonse** | **SOAP for AdamW aux groups** | arm-A SOAP sanity run `lfcnprqg` running step 1800, val=3.481 — on-track |
| **#145** | **nezuko** | **Per-layer adaptive NS iterations** | arm-A sanity `z2ygnqxh` running step 2225, val=3.426. Also running smoke test `4ov863qm` |
| **#157** | **askeladd** | **Polar-decomposition Muon via exact SVD** | just assigned (follow-up to #120; tests if NS approximation error is load-bearing). Awaiting student pickup. |

## Infra-blocked

- **tanjiro** (GPU UUID 7998cef9-...): **3rd reproduction confirmed 2026-05-16 13:34 UTC** — merged baseline diverges at step 25 (NaN, nonfinite=147M; step-1 grad_norm=232102) across #97/#108/#149 smoke tests. ECC clean, same hardware model as healthy pods. Silicon-binning bf16 issue. **Issue #160 filed** requesting GPU rotation. Not assigning new work until human/infra team rotates the pod — tanjiro slot is unproductive until then. NS-iter annealing hypothesis held in reserve.

## Wave 3 critical path — merge sequencing

**Both #115 (bias correction, beta2=0.98) and #105 (grad clip=5.0) are on cusp of n=3 confirmation.**

**Sequencing**:
1. Whoever posts terminal SENPAI-RESULT first merges first (whoever finishes confirm seed 2 first)
2. After first merge, the remaining PR re-tests on NEW merged baseline — expect either same win (orthogonal mechanisms) or adjustment needed
3. If both confirm at n=3: launch stack PR (bias_corr=on + clip=5.0 combined) as next assignment

**Statistical target for both**: `(3.28 − mu(n=3)) × √3 ≥ 0.004` → mu ≤ 3.27769
- Edward n=2 partial mu = 3.27515 — margin plenty for mu ≤ 3.27769 if seed 2 ≤ 3.2795
- Thorfinn n=2 partial mu = 3.27450 — margin excellent; seed 2 can be ≤ 3.2810 and still pass

## Closed mechanisms (do not re-explore)

| Category | Mechanism | Evidence |
|----------|-----------|----------|
| Temporal smoothing | Polyak EMA, Lookahead | #104, #120 — both close same root cause: cooldown tightening needs commitment, not historical averaging |
| Element-wise direction shaping | Contra-Soft per-element | #126 — conflict_fraction~0.50 = noise-dominated |
| Magnitude-coupled trust region | ||w||_F coupled cap | #117 — self-reinforcing choke loop at init |
| LR warmup | 0/50/100 step warmup | #102 — monotone WORSE; Muon² doesn't need warmup |
| Cooldown frac | {0.4, 0.5, 0.6} | #106 — frac=0.7 baseline optimal on Muon² |
| Lion optimizer (aux) | Lion embed+lm_head | #77 — catastrophic (3.31xx), sign-momentum inadequate |

## Wave 3 frontier — remaining next-tier

**In flight (see Active PRs table above)**

**Next-tier after current wave (based on mechanism orthogonality)**:
- **Stack test: bias_corr + clip=5.0 combined** — once both confirm
- **AdamW aux LR sweep** (follow-up to thorfinn #105 mechanism diagnosis: clip=5.0 = aux LR rescaler; test direct LR increase)
- **Clip per-group** (apply clip only to AdamW params, not Muon blocks, per thorfinn's NS-absorbs-magnitude insight)
- **Muon for embed/lm_head** — apply Muon² to all params (not just blocks), unifying the optimizer (after alphonse #144 SOAP settles)

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM, multi-step optimizers that need extra forwards).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline includes `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var.
- 1 GPU per student node — sequential arm execution required.
- **Pattern (post-tanjiro pod issue)**: All Muon²-touching PRs should include 100-step smoke test before launching long arms.
- **Pattern (post-thorfinn crashes)**: Always commit code to branch before launching long arms; uncommitted state combined with potential pod preemption produces unrecoverable crashes.
- **Pattern (post-edward arm-C invalid-recipe)**: Freeze training script to snapshot OUTSIDE working tree before launching. Branch-swap during sequential launcher invalidates arms silently.
- **Failed-mechanism pattern**: Magnitude-suppression depending on current weight/update creates self-reinforcing feedback loops at init. Use NS-natural scale invariants (sqrt(min(rows,cols)) not ||w||_F).
