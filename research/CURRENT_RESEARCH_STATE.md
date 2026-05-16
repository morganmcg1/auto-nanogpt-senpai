# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-16 16:40 UTC. Post-#105 wave-3 continuing. All 7 active students have arms running. Tanjiro infra-blocked (issue #160 still pending). 4 PRs pinged about rebase needed after #105 merged (#163, #138, #157, #144 status).
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** **3266.7 steps** (mean n=3), **val=3.27527** — thorfinn grad clip=5.0 merged 2026-05-16 (#105)
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — Muon² + grad clip=5.0

### alphonse Muon² (#60): val=3.2766/fs=3275 (n=2)
**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization.

### thorfinn grad clip=5.0 (#105): **val=3.27527/fs=3266.7 (n=3)** — 2026-05-16 CURRENT BEST
**Mechanism:** NANOGPT_GRAD_CLIP=5.0. Full-time gradient rescaling on AdamW aux groups (embed/lm_head); NS absorbs magnitude on Muon blocks → clip acts only on aux. Equivalent to constant effective-LR multiplier on AdamW aux groups. n=3 seeds: mu=3.27527, mean fs=3266.7. Baseline commit: 8566c3e.

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
| #105 | thorfinn | **MERGED 2026-05-16** — grad clip=5.0 val=3.27527/fs=3266.7 (n=3). New branch baseline. Mechanism: full-time gradient rescaling on AdamW aux groups. |
| #149 | tanjiro | CLOSED infra-blocked — 3rd reproduction of pod NaN cascade on unmodified baseline (step-1 grad=232102, step-25 nonfinite=147M). Issue #160 filed for pod rotation. |
| #154 | fern | CLOSED on strict smoke gate — layer-aggregate global_cos_neg=0.9 ≫ 0.3 threshold. Surprising mechanistic finding: grad·momentum < 0 ~90% of steps under Muon². Mechanism degenerates to mild constant gradient downscaler (~0.85x multiplier). Motivated follow-up #163 DMR. |

## Active PRs

### Wave 3 mechanism stacks — critical path 🎯

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#115** | **edward** | **Muon² + Adam bias correction** | 🎯 n=3 stat-sig PASS on old baseline (mu=3.27532). Sent back to re-test on NEW clip=5.0 baseline. Currently visible: control `tak4oqhf` step 1625/3350 ETA ~57min; 3 BC seeds not yet visible (likely sequential queue). Total ~5h to terminal. |
| **#105** | **thorfinn** | **Gradient clipping sweep** | **✅ MERGED 2026-05-16 15:30 UTC** — val=3.27527/fs=3266.7 (n=3). New branch baseline. |

**Key mechanism insight from thorfinn's gradient norm analysis:** Raw global_norm is 4–5 orders of magnitude larger than both clip thresholds → clip is active at EVERY step → not clipping rare spikes but full-time gradient rescaling. NS already absorbs magnitude for Muon blocks → clip only has effect on AdamW aux groups (embed/lm_head). Grad clip = effective AdamW aux LR multiplier.

### Wave 3 other in-flight

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #138 | frieren | **Polar Express NS** (ICLR 2026 Oral) | arm-A=3.2783/3325 sanity ✓. arm-B (PE iters=12)=3.2767 baseline parity. arm-C (PE iters=8)=3.276 parity. **arm-D (PE iters=6) `4chpm8ru` step 2050/3350 ETA ~43min**. Re-rebase ping sent — branch CONFLICTING after #105 merge. |
| **#163** | **fern** | **Decoupled Momentum Reset (DMR)** | smoke passed 14:51 UTC (K=50, val_loss=4.26 at step 200, cos_block0_q flipped +0.044 after resets). Arms A→D sequential via dispatcher (~6.4h). Rebase ping sent — branch CONFLICTING after #105 merge. |
| **#144** | **alphonse** | **SOAP for AdamW aux groups** | arm-A `lfcnprqg` finished val=3.27595/fs=3275 ✓ baseline parity. **arm-B `8ym5zef8` (embed-only) FINISHED val=3.27978 — WORSE than baseline by 0.005**. arm-C `82mx9xwy` (full SOAP) step 175/3350 ETA ~2.2h. Status ping sent. |
| **#145** | **nezuko** | **Per-layer adaptive NS iterations** | arm-A `z2ygnqxh` finished val=3.27841/fs=3325 ✓. **Critical telemetry finding: spread saturates 11–25 ≫ midpoint=2.0 → arms B/C/D effectively fixed NS=16/14/18 uniform sweep, not adaptive**. arm-B `mxzk59qm` step 100 (warmup). Rebase ping sent (branch CONFLICTING). |
| **#172** | **askeladd (NEW)** | **Cautious Update Mask** (Bansal & Schaul 2024) | just assigned — apply Muon² update only when grad·momentum > 0. Tests fern's #154 staleness finding via signal-mask rather than erasure. 4 arms: off/after_ns/before_ns/soft. |
| **#165** | **thorfinn** | **Clip value extension sweep** | just assigned 15:30 UTC — extends clip=5.0→{10,25,50}; awaiting student pickup |

## Infra-blocked

- **tanjiro** (GPU UUID 7998cef9-...): **3rd reproduction confirmed 2026-05-16 13:34 UTC** — merged baseline diverges at step 25 (NaN, nonfinite=147M; step-1 grad_norm=232102) across #97/#108/#149 smoke tests. ECC clean, same hardware model as healthy pods. Silicon-binning bf16 issue. **Issue #160 filed** requesting GPU rotation. Not assigning new work until human/infra team rotates the pod — tanjiro slot is unproductive until then. NS-iter annealing hypothesis held in reserve.

## Wave 3 post-#105 — current sequencing

**#105 merged at 15:30 UTC as first wave-3 winner.** Branch baseline: val=3.27527/fs=3266.7 (n=3).

**Next merge candidates ranked by expected EV**:
1. **#115 edward retest** — orthogonal mechanism (touches Muon² v-EMA), expected to stack with clip=5.0. ETA ~5h to terminal SENPAI-RESULT.
2. **#138 frieren** — arms A/B/C all at baseline parity (~3.276); arm-D (PE iters=6) finishing soon. Best-case outcome is compute-efficiency story (NS=12-quality output at NS=6-cost), not val/loss improvement.
3. **#165 thorfinn clip-extension** — extends clip=5.0→{10,25,50}; monotone trend may continue. ETA ~7h once student picks up.
4. **#144 alphonse SOAP-aux** — arm-B (embed-only) FAILED (val=3.27978, +0.005 vs baseline). Mechanism may be wrong direction. Arm-C (full SOAP both groups) is the salvage attempt.
5. **#163 fern DMR** — falsifiable mechanism test. Big swing: either validates the staleness hypothesis or definitively closes the temporal-momentum family.
6. **#145 nezuko per-layer NS** — degenerated to uniform-NS sweep (saturation). Still informative as NS={14,16,18} vs baseline NS=12 sweep, but adaptive narrative is dead.

**Stack candidate**: bias_corr=ON + beta2=0.98 + clip=5.0 — pending #115 retest confirmation.

**Statistical target**: `(3.28 − mu(n=3)) × √3 ≥ 0.004` → mu ≤ 3.27769. New bar is to beat 3.27527.

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
