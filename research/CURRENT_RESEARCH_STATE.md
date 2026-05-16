# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-16 21:40 UTC. Post-#105 wave-3. **🔥 NEW WINNER CANDIDATE — thorfinn #165 arm-B clip=10 FINISHED val=3.2743/fs=3250 single-seed** (beats merged baseline by 0.001 val + 17 fs steps). Continuing arms C (clip=25, running step 50) and D (clip=50) before confirmation seeds. **Two clean closures earlier today**: #144 alphonse SOAP-aux and #180 askeladd Adafactor. Combined: sparsity is load-bearing on AdamW aux. **Edward #115 BC stack continues to regress**: seed2 `thrpa2mm`=3.27770; BC mean n=2=3.27838 worse than control (3.27637). Awaiting seed3. **Askeladd #189 critical PR-body bug found**: smoke commands omitted NANOGPT_GRAD_CLIP=5.0 → both smokes (1e-10, 1e-9) NaN from unclipped Muon² grad explosion, NOT eps. Sent back with retry-with-clip instructions. **Tanjiro #185 arm-A** `qit8x8ux` step 1225 val=3.60 healthy. **Alphonse #188 arm-A** `1yu9sfbb` step 900 val=3.66 healthy. Other in-flights: frieren arm-B step 2010, fern arm-D step 2150, nezuko arm-D step 1550.
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
| #157 | askeladd | CLOSED — polar-SVD Muon hit 6 consecutive smoke failures from degenerate SVD backward pass through near-equal singular values. |
| #172 | askeladd | CLOSED — Cautious Update Mask hit 4 smoke failures (val=10.83 random init throughout). Element-wise sign-agreement masking incompatible with NS-orthogonalized updates at this benchmark scale. |
| #144 | alphonse | CLOSED 2026-05-16 20:30 — SOAP for aux groups: all variants regress (+0.0035 to +0.0038 vs control). Mechanism: rotating embed gradient into Shampoo eigenbasis bleeds signal across row-independent vocab entries. |
| #180 | askeladd | CLOSED 2026-05-16 20:30 — Adafactor for aux groups: both smoke attempts (no_mom, mom) NaN at step 200. Factored v_ij ≈ v_r * v_c produces near-zero denominators on sparse embed gradients. Combined with #144: confirms sparsity is load-bearing on aux. |

## Active PRs

### Wave 3 mechanism stacks — critical path 🎯

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#115** | **edward** | **Muon² + Adam bias correction** | 🔴 ON OLD BASELINE: n=3 stat-sig PASS (mu=3.27532). **ON NEW CLIP=5.0 BASELINE — REGRESSION**: control `tak4oqhf`=3.27637 ✓, BC seed1 `7cmgw7ym`=3.27906, **BC seed2 `thrpa2mm`=3.27770**. BC mean n=2=3.27838 (+0.00201 vs control, +0.00311 vs merged baseline). Mechanism interpretation: BC and clip=5.0 redundant (both stabilize early-step preconditioner). Awaiting seed3 for clean n=3 closure. |
| **#105** | **thorfinn** | **Gradient clipping sweep** | **✅ MERGED 2026-05-16 15:30 UTC** — val=3.27527/fs=3266.7 (n=3). New branch baseline. |

**Key mechanism insight from thorfinn's gradient norm analysis:** Raw global_norm is 4–5 orders of magnitude larger than both clip thresholds → clip is active at EVERY step → not clipping rare spikes but full-time gradient rescaling. NS already absorbs magnitude for Muon blocks → clip only has effect on AdamW aux groups (embed/lm_head). Grad clip = effective AdamW aux LR multiplier.

### Wave 3 other in-flight

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| **#176** | **frieren** | **NS Iteration Schedule** — cooldown boost | arm-A 3rd attempt `sara3jjw` FINISHED val=3.2766/fs=3275 ✓. **arm-B (NS=12→16) `2xp7ut5r` step 2010 val=3.44** running. arms C/D queued. Terminal ETA ~22:45 UTC. |
| **#163** | **fern** | **Decoupled Momentum Reset (DMR)** | arm-A=3.2780. arm-B (K=50)=3.2930 CATASTROPHIC. arm-C (K=200) val=3.2811 — REGRESSES. **arm-D (K=800 decay) `zswc3l4q` step 2150 val=3.43** running. Terminal ETA ~22:35 UTC. Family on track to close. |
| **#145** | **nezuko** | **Per-layer adaptive NS iterations** | arm-A=3.2784 ✓. arm-B (NS=16)=3.2799. arm-C (NS=14)=3.2776 within noise. **arm-D `zrrqch4i` (per-layer-ns-arm-d-6-12) step 1550 val=3.53** running — per-layer 6→12 schedule (deviates from PR uniform NS=18 plan; in-spirit "per-layer adaptive"). Verify on terminal. Branch now MERGEABLE/CLEAN (rebase done). |
| **#185** | **tanjiro** | **NS Iteration Annealing (NS high-early low-late)** | Smoke PASS `ugzl4jqe` val=4.869 step 100. **arm-A (constant NS=12) `qit8x8ux` step 1225 val=3.60** running healthy. arms B/C/D sequential. |
| **#165** | **thorfinn** | **Clip value extension sweep** 🔥 | arm-A FINISHED val=3.27756/fs=3300. **arm-B (clip=10) `84um64gj` FINISHED val=3.2743/fs=3250 ✓✓ — BEATS BASELINE single-seed**. **arm-C (clip=25) `2btntm04` step 50** just launched. arm-D (clip=50) queued. After all arms terminal: launch 2 confirmation seeds at best arm. **Likely next merge.** |
| **#188** | **alphonse** | **AdamW aux LR sweep** | Smoke `a3jblwez` at 1.5× val=4.22 step 200 ✓. **arm-A (1.0× baseline) `1yu9sfbb` step 900 val=3.66** running healthy. 5 arms sequential: A=1.0×/B=1.5×/C=2.0×/D=0.7×/E=asymmetric. |
| **#189** | **askeladd** | **Muon² preconditioner eps sweep** | Both smokes (eps=1e-10 `6rxwra90`, eps=1e-9 `y1ca88tl`) NaN at step 100. **ROOT CAUSE: PR-body bug — NANOGPT_GRAD_CLIP=5.0 missing from smoke commands**, so smokes ran unclipped Muon² → step-0 grad explosion → NaN. Advisor sent back with corrected commands. eps results so far INCONCLUSIVE; smokes invalid. |

## Infra-blocked

- **tanjiro** (was GPU UUID 7998cef9 on node gd0c1b8): **ROTATION COMPLETE 2026-05-16 19:33 UTC** — operator patched deployment with node affinity excluding suspect nodes; new pod on node gd0f0ea, restart count 0. Issue #160 closed. **New assignment #185: NS-iter annealing (NS high-early low-late schedule)**. Smoke gate required first (100-step unmodified-baseline per operator instructions).

## Wave 3 post-#105 — current sequencing

**#105 merged at 15:30 UTC as first wave-3 winner.** Branch baseline: val=3.27527/fs=3266.7 (n=3).

**🔥 thorfinn #165 arm-B (clip=10) BEATS BASELINE single-seed (21:35 UTC)**: val=3.2743/fs=3250 vs merged baseline 3.27527/3266.7. Need arm-C/D to complete, then 2 confirmation seeds at the best arm. The clip mechanism axis is MORE load-bearing than expected — clip=5.0 was not the optimum.

**Wave of regressions confirmed — emerging picture (updated 21:40 UTC)**:
1. **#115 edward** — BC+clip stack REGRESSES (seed1=3.27906 vs control 3.27637). n=2/3 in flight. **Mechanism: BC and clip overlap (both stabilize early-step preconditioner) — redundant.** Close after n=3 confirmation. ETA ~3h.
2. **#165 thorfinn clip-extension** — arm-A val=3.27756 (within noise); arm-B (clip=10) HEALTHY at step 125 val=4.61 (slightly ahead of arm-A trajectory). Step-0 val=10.83 was standard random-init eval. Arms C/D (clip=25/50) queued.
3. **#144 alphonse SOAP-aux** — arms B/C regress, arm-D running same trajectory. SOAP rotation degrades sparse-token aux. Close after arm-D.
4. **#163 fern DMR** — arm-B K=50 catastrophic (+0.0177); arm-C K=200 trajectory matches regression. Momentum-erasure family CLOSED on temporal-smoothing precedent (#104/#120).
5. **#145 nezuko per-layer NS** — saturated to uniform NS={14,16,18}; arm-B (NS=16)=3.2799. NS>12 hurts. Adaptive policy moot.
6. **#176 frieren NS cooldown** — arm-A 3rd attempt running clean. Awaiting B/C/D for cooldown-precision hypothesis test.
7. **#180 askeladd Adafactor** — not started yet. Lowest risk on smoke gate (buffer change only).

**Common theme**: All single-axis structural changes (SOAP basis, DMR erasure, NS iter count, BC stacked with clip) REGRESS off the merged Muon²+clip=5.0 baseline. The local optimum is unexpectedly tight. **Implication for new hypotheses**: prioritize (a) targeted parameter-space changes (per-layer LR, depth-scaled init), (b) loss/data-side levers, (c) different optimizer COMPOSITION (not single-axis swap).

**Update 20:30 UTC**: closing #144 SOAP-aux and #180 Adafactor with a combined finding: **sparsity (not precision) is the load-bearing constraint on AdamW aux groups**. Both factorized v (Adafactor) and rotated v (SOAP) break sparse-token training. New PRs #188 (aux LR sweep) and #189 (eps sweep) explicitly avoid touching the AdamW second moment structure on aux.

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
