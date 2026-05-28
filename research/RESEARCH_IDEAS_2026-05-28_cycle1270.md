# H250 — thorfinn — Asymmetric aux schedule SHAPE+FRAC replacement

Cycle ~1270. Mechanism class **#46: aux-side cooldown schedule structural axis replacement**.

## Mechanism class

The H148+H203-derived baseline runs an *asymmetric* per-group cooldown:

- MuonH body groups: `cooldown_frac=1.0` with shape controlled by `--muonh_cooldown_shape` (default `linear`; merged to `cosine` post-H203).
- AdamW aux groups (embed/head/scalars): `cooldown_frac=0.4`, shape `linear` — both **hardcoded** at `train_gpt_simple.py:953-957`, never argparse-exposed, never ablated.

H242 has just confirmed (CATASTROPHIC bilateral NEG) that body cooldown shape and frac=1.0 cosine is structurally load-bearing on the body side. The student's H242 closure suggestion explicitly asked: *is the asymmetric aux schedule (linear, cf=0.4) still optimal once body is cf=1.0 cosine?*

This is the **only structurally-load-bearing knob that has never been touched**: the body axis is closed, MuLoCo HP/FORM is closed (Finding #54), aux *optimizer* replacement is closed (Finding #55), but aux *schedule SHAPE/FRAC* has not been tested as an axis ever in the campaign — it has only ever been swept implicitly by inheriting from H148 calibration. Different mechanism class from H245 ADana (which is aux **β** schedule, not aux **LR** schedule).

## Hypothesis

A cosine-shaped aux cooldown extending over a larger fraction of training will improve FFS to **<3025** by better matching the post-NS5 step-size geometry that the body side now relies on. Specifically: replacing aux `(linear, cf=0.4)` with `(cosine, cf=1.0)` — symmetric with body — or with `(cosine, cf=0.6)` — partial extension — should improve FFS.

Falsifiable: if both treatment arms regress FFS bilaterally (NEG ≥ +25), the aux asymmetry `linear @ cf=0.4` is itself structurally load-bearing (Programme Finding #56 candidate solidifies: aux schedule as a WHOLE is locked, complementing the body-side lock). If TIE both ways, aux schedule shape/frac is structurally NULL (cheap and uninteresting axis).

## Theoretical grounding

1. **Hägele et al., "Scaling Laws and Compute-Optimal Training Beyond Fixed Training Durations"** (arXiv:2405.18392, 2024). WSD ablations show schedule shape matters most via "Mpemba" effect during cooldown; cosine outperforms linear at small cooldown fractions but flips at large fractions, and the optimal cf depends on whether the optimizer needs large stable LR or large decay region.
2. **"Training Dynamics of the Cooldown Stage in WSD"** (arXiv:2508.01483, Aug 2025). Direct finding: cosine cooldown shape outperforms linear via bias-variance trade-off in the cooldown phase; effect is *comparable in magnitude* to AdamW β₂ tuning. This is the closest published result to our setting and directly motivates testing cosine on the aux side.

Both establish that for AdamW, schedule shape interacts with second-moment dynamics. Our aux is AdamW with β₂=0.99 (H148) — this regime is exactly the one the 2508.01483 paper recommends cosine cooldown for.

## Exact code changes — `records/track_3_optimization/train_gpt_simple.py`

Two minimal edits.

**Edit 1 — expose argparse flags (near line 48, alongside `--muonh_cooldown_shape`):**

```python
parser.add_argument("--aux_cooldown_shape", type=str,
                    default=os.environ.get("AUX_COOLDOWN_SHAPE", "linear"),
                    choices=["linear", "cosine", "sqrt"],
                    help="LR cooldown shape for AdamW aux groups (embed/head/scalars). Baseline 'linear'.")
parser.add_argument("--aux_cooldown_frac", type=float,
                    default=float(os.environ.get("AUX_COOLDOWN_FRAC", "0.4")),
                    help="Fraction of training spent in AdamW aux cooldown. Baseline 0.4 (H148-derived asymmetric).")
```

**Edit 2 — replace lines 953-957 with argparse-driven values:**

```python
h_cooldown_frac = 1.0
aux_cooldown_frac = args.aux_cooldown_frac   # NEW: was hardcoded 0.4
for group in optimizer1.param_groups:
    group["cooldown_frac"] = aux_cooldown_frac
    group["cooldown_shape"] = args.aux_cooldown_shape   # NEW: was hardcoded "linear"
for group in optimizer2.param_groups:
    group["cooldown_frac"] = h_cooldown_frac
    group["cooldown_shape"] = args.muonh_cooldown_shape
```

Also extend the W&B config logging block (~line 835) to include `aux_cooldown_shape` and `aux_cooldown_frac` for run grouping/audit.

That's it. ~10 lines net. Zero changes inside any `@torch.compile` region. Schedule resolution happens inside `set_hparams(step)` which runs in Python loop scope — already non-compiled. No conditional `if` branch is inserted into a compiled path; the `cooldown_shape` lookup at line 981 is an existing Python dispatch.

## torch.compile soft-drift gate

`set_hparams` is **not** inside any compiled region (it mutates `group["lr"]` on the Python optimizer object directly). The new flags only change values read by this Python-scope function. The `cooldown_shape == "cosine"` branch at line 985 is already present in source for body-side use, so adding a *third* call site using it for aux groups does NOT introduce any new compiled branch and CANNOT cause retracing. **Drift risk: ~0.** Confirmed by inspection of code at lines 965-992.

Step_avg should be identical to baseline byte-for-byte at step 0 (no compiled-region change, no init change).

## Bit-identity gate

All three arms must hit step-0 val=**10.82583** EXACT (no init or compile-graph change). Verify before launching `train_steps`.

## 3-arm experimental design

`--wandb_group=h250_aux_schedule_shape`

| Arm | Aux shape | Aux cf | Body shape | Body cf | Identity |
|-----|-----------|--------|------------|---------|----------|
| **arm_a CTRL** | `linear` | `0.4` | `cosine` | `1.0` | byte-for-byte H203 baseline (default flag values; CTRL must reproduce FFS=3025 ±10) |
| **arm_b TREATMENT_DEFAULT** | `cosine` | `1.0` | `cosine` | `1.0` | symmetric — aux fully mirrors body schedule (student's direct suggestion) |
| **arm_c TREATMENT_VARIATION** | `cosine` | `0.6` | `cosine` | `1.0` | partial extension — cosine shape, longer cooldown than baseline but not full; tests whether shape or frac dominates |

Why three arms not two:
- arm_b alone confounds shape change with frac change. arm_c isolates shape effect at a frac that is not the body's.
- If only arm_b wins, full symmetry helps.
- If only arm_c wins, cosine shape helps but full-cf hurts (aux benefits from earlier transition).
- If arm_b wins and arm_c ties, both axes matter and we have a follow-up tier-shift toward fine-grained sweep.

## Diagnostic telemetry to log

Inject at end of `set_hparams` (cheap, Python-scope):
- per-step `aux_lr` and `body_lr` to W&B at every log_step (or every 100 steps for speed).
- log `aux_eta` and `body_eta` separately so we can plot the schedule trajectories overlaid.

This lets us *see* the shape, not just the FFS endpoint, and will be load-bearing for the inevitable "are the two schedules actually behaving how we think?" follow-up.

Also log val_loss trajectory at canonical eval cadence so we can read the bias-variance trade-off shape predicted by arXiv:2508.01483 (variance dominates early cooldown, bias late).

## Expected outcome ranges

Campaign base rate WIN ≈ 10%. Mechanism class is novel (first aux schedule SHAPE+FRAC test ever).

- **WIN both arms** (FFS<3000 bilateral): aux schedule was suboptimal, large structural finding. Prob ~8%.
- **WIN one arm** (FFS<3025 unilateral, other TIE): localized improvement, merge winner. Prob ~12%.
- **TIE both** (FFS=3025±10): aux schedule structurally null on top of current body schedule. Cheap Finding #56 candidate. Prob ~35%.
- **NEG one arm**, TIE other: shape OR frac is load-bearing in a specific direction. Useful constraint. Prob ~20%.
- **NEG both arms** (FFS≥3050 bilateral): aux schedule as a WHOLE is structurally load-bearing — Programme Finding #56 confirmed in strongest form (aux side mirrors body side load-bearing pattern). Prob ~25%.

**Aggregate WIN probability: ~20%** (≈ 2× campaign base rate). Reasoning: this is the last untouched structurally-asymmetric knob; published literature in directly analogous WSD/AdamW regime (arXiv:2508.01483) shows cosine > linear is non-trivial; and the asymmetry was set in H148 calibration *before* the body schedule was migrated to cosine, so there is now a clear coherence argument for re-examining it.

## Why higher EV than the alternatives

Comparing to the other candidate axes listed:

- **Aux schedule SHAPE (chosen)**: novel mechanism class, ~10 LoC change, zero compile risk, directly motivated by H242 finding + student suggestion + published literature. WIN prob ~20%. **HIGHEST EV per compute.**
- Body weight orthogonality regularizer: novel but loss-surgery requires careful Frobenius accounting and adds optimizer-step cost; expected drift risk +25 FFS likely from compile retracing. WIN ~10%, higher complexity.
- SAM at body: expensive (2× forward+backward), drift-prone (NS5 inside ascent+descent path), and PSGD-Kron family already failed at this layer. WIN ~6%.
- Stochastic Polyak: requires f* estimate or proxy; mechanism unclear on Muon body; high research-state value low.
- Adaptive NS iter count: directly conflicts with H243 in-flight (fractional NS).
- Body Shampoo/SOAP, HVP-GGN: collide with H248 in-flight (post-NS5 EMA-g²); should wait for H248 read-out before adding a second post-NS5 preconditioner axis.
- Compressed inner-aggregation MuLoCo: MuLoCo HP/FORM closed in Finding #54; needs new evidence before reopening.
- Eigenvalue-spectrum init beyond F-norm matched: init axis has lower coupling to FFS endpoint per H203 evidence; secondary priority.
- Aux warmup vs body warmup decoupling: both currently 0/100; small change but no published evidence cooldown matters vs warmup in this regime; lower theoretical grounding.

Aux schedule SHAPE+FRAC is the cheapest discriminating experiment that either (a) opens a real win or (b) finalizes Programme Finding #56 — both outcomes update the research map sharply. The other candidates either duplicate in-flight axes, carry drift risk, or have weaker prior probability.

## Research state update

- **Current best explanation for plateau**: H148-derived calibration baked an asymmetric aux schedule (linear cf=0.4) that has never been re-examined after body migrated to cosine cf=1.0; the structural axes that *have* been swept (body shape, MuLoCo, aux optimizer) are all locked, but aux schedule shape itself has not been tested.
- **Evidence**: H242 bilateral CATASTROPHIC NEG locks body cf=1.0 cosine; H225/H237/H239/H241 lock aux optimizer identity; H222/H229/H233/H236 lock MuLoCo. Aux schedule axis is the residual untested asymmetric knob.
- **Ruled-out paths**: do not retest body schedule shape; do not retest MuLoCo HP/FORM; do not retest aux optimizer identity. Do not collide with H243 (NS iter), H248 (post-NS5 preconditioner), H249 (Riemannian SI metric).
- **Open uncertainties**: (1) is aux asymmetry structurally load-bearing or accidental from H148 calibration? (2) does cosine shape transfer to AdamW second-moment regime at β₂=0.99? (3) is the aux side mid-training LR drop (cf=0.4 means stable until 60% then linear-to-zero) protecting embed/head capacity, or wasting potential?
- **Next discriminating experiment**: this H250.
- **Stop condition**: if both arm_b and arm_c are NEG ≥ +25 FFS bilateral, ratify Programme Finding #56 (aux schedule axis structurally locked) and move to next-tier axes (sharpness-aware, second-order post-NS5, or compressed inner-aggregation).

## Experiment tree

```
H250 (aux cosine schedule)
├── arm_b WIN (cf=1.0 cosine helps)
│   └── follow-up H251: sweep aux cf ∈ {0.5, 0.7, 0.85, 1.0} cosine, find optimum
│       └── if optimum != 1.0: H252 joint aux+body cf coupling
├── arm_c WIN (cf=0.6 cosine helps, cf=1.0 does not)
│   └── follow-up H251: sweep aux cf ∈ {0.4, 0.5, 0.55, 0.6, 0.7} cosine
├── arm_b TIE, arm_c WIN (shape > frac matters)
│   └── follow-up H251: keep cf=0.4 fixed, sweep aux shape ∈ {cosine, sqrt, sigmoid, 1-x^p}
├── both TIE (axis NULL)
│   └── Finding #56 candidate; next pick from queue: sharpness-aware body or compressed inner-aggregation
├── both NEG (axis load-bearing in wrong direction)
│   └── Finding #56 CONFIRMED; aux schedule asymmetry is intentional; document as fragile lock; move to fundamentally new mechanism class
```

## Taste rubric

Research mode: **frontier refinement** with a discriminating diagnostic — the closest untouched asymmetric structural axis in the locked stack.

| Criterion | Score | Justification |
|---|---|---|
| Mechanistic grounding | 3 | Targets a specific asymmetric calibration baked at H148 that was never re-examined post-cosine body migration. Mechanism is precise (per-group cooldown shape and frac), and tied to published WSD/AdamW result arXiv:2508.01483 in directly analogous regime. Falls short of 4 only because the published evidence is on AdamW alone, not Muon-AdamW heterogeneous stacks. |
| Research-state value | 4 | Result updates research map sharply either way: a WIN merges and reopens schedule-shape territory; a bilateral NEG ratifies Finding #56 and closes the residual untested structural asymmetry. Compared to most candidates this is the cleanest "either win or finalize a programme finding" experiment. |
| Execution value | 4 | ~10 LoC, zero compile-region change, zero drift risk, no new optimizer or model code, 3-arm uses existing schedule dispatch. Highest information gain per unit compute among current candidate axes. |

## Confidence

**Medium-high.** Strong evidence from arXiv:2508.01483 that cosine cooldown beats linear in AdamW at β₂≈0.95-0.99 regime; strong code-level evidence that the asymmetry was never deliberately ablated; strong fit to student's H242 closure suggestion. Main uncertainty: whether the H148-era cf=0.4 was empirically tuned (asymmetry is signal) or just inherited from an earlier baseline (asymmetry is artifact). Either way the result is informative.

## Student-facing notes for thorfinn

- thorfinn just demonstrated phase-by-phase trajectory analysis discipline on H242 (verified bit-id, checked NEG direction monotonicity per-phase). This experiment continues exactly in that idiom: 3 schedules, log per-step `aux_lr` and `body_lr`, compare trajectories.
- Bit-id gate is mandatory at step 0 across all 3 arms (val=10.82583 EXACT). arm_a CTRL must reproduce FFS=3025 ±10.
- Use `--wandb_group=h250_aux_schedule_shape` for grouping.
- Log aux_lr, body_lr, aux_eta, body_eta to W&B every 100 steps for trajectory comparison.
- Treat NEG outcomes as evidence not failure — bilateral NEG locks Programme Finding #56 and is a publication-grade structural finding.
