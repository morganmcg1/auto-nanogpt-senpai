# Aurora Optimizer Research — 2026-06-01
## Research question: Issue #2122

Is Aurora's leverage-equalization mechanism likely to improve FFS to val ≤ 3.28 on the H266 stack,
and what is the minimal experiment that would test it under official modded-nanoGPT rules?

---

## What Aurora Is

**Tilde Research, May 5 2026.** Authors: Alec Dewulf, Dhruv Pai, Li Yang, Ashley Zhang, Ben Keigwin.
Blog post only — no arXiv preprint. MIT license.
Source: https://github.com/tilde-research/aurora-release

Aurora is a Muon-family optimizer that replaces the standard polar factorization `U = polar(G)` with
an alternating-projection step that simultaneously satisfies two constraints: `U^T U = I_n`
(Stiefel/orthogonality) AND uniform row norms equal to `sqrt(n/m)` for tall `m x n` matrices.
Standard Muon satisfies only the first constraint; the second constraint enforces uniform leverage
scores (equal contribution of each output neuron to the gradient norm).

The core algorithm (tall-matrix branch only; square matrices reduce to standard polar):

```python
target_row_sq = n / m
D = 1.0 / row_norm(G)             # per-row inverse norms
for k in range(pp_iterations):
    U = polar(D * G)               # standard Newton-Schulz polar on preconditioned G
    if k < pp_iterations - 1:
        row_sq = U.pow(2).sum(-1, keepdim=True).clamp(min=eps)
        D = D * (target_row_sq / row_sq).pow(pp_beta)   # damped fixed-point update
```

Key hyperparameters:
- `pp_iterations` (default 2): alternating-projection refinement steps. Value of 1 reduces to
  "Muon EQ" (single row-normalize then polar — the simplest leverage baseline).
- `pp_beta` (default 0.5): damping exponent in [0,1]. Higher = faster D convergence, less stable.
- For square matrices Aurora is identical to standard Muon/MuonH polar.

The `polar.py` in aurora-release is the identical simple-quintic Newton-Schulz (12 iterations,
coefficients 2, -1.5, 0.5) used byte-for-byte with modded-nanoGPT's `zeropower_via_newtonschulz5`.
The Aurora authors explicitly matched this to ensure reproducibility against the leaderboard.

---

## Mechanism Characterization

**Problem Aurora targets:** In tall weight matrices (SwiGLU MLP up/gate projections, m >> n),
standard Muon polar can produce updates where some rows (neurons) receive much larger gradient
contributions than others, creating uneven per-neuron learning rates. This is a "neuron death /
dominance" pathology: Muon is designed to maximize gradient alignment subject to spectral-norm
unit ball, but leaves row-norm distribution unconstrained. Aurora adds the row-norm constraint
as a second projection, iterating to the feasible joint manifold.

**Mechanism axis:** Row-norm equalization of the polar update. This is orthogonal to all 7
confirmed hard-load-bearing axes on the H266 stack:
1. Optimizer momentum (H354/H355/H356 — SHAPE/ENDPOINT/CATASTROPHIC axes on MuonH mu schedule)
2. BODY init geometry (H342/H350 — catastrophic sensitivity)
3. AUX optimizer sign-mask (H343 — catastrophic)
4. BODY orthogonalizer kernel (NS step count, not touched by Aurora's column/row reweighting)
5. AUX lookahead delay (H344 — mildly load-bearing)
6. BODY init depth asymmetry (H348)
7. Structural LR decay curvature (H352)

Aurora does NOT change: momentum schedule, LR schedule, weight decay, initialization, or any
component outside the polar step. It is a single-line swap in `muon_update()`.

**Integration point in train_gpt_simple.py:**

```python
# Current (line 575 approximately):
update = zeropower_via_newtonschulz5(update)

# Aurora replacement (tall branch only, m > n):
# wrap with D-preconditioned alternating projection loop
```

The swap is surgical: `muon_update()` at line 572 calls `zeropower_via_newtonschulz5(update)`.
Aurora replaces only this call for tall matrices; square matrices stay unchanged.

**Why scale_invariant matters here:** In MuonH scale_invariant mode, the parameter F-norm is
held constant at each step via `scale_invariant_update_()`. Aurora's row-equalization changes
the direction of the update but not its scale (it still returns a matrix with constrained
column norms). Compatibility with scale_invariant is direct — same update direction geometry,
same post-update norm preservation.

---

## Prior Track-3 Evidence

Aurora WAS already tested in track-3 (`records/track_3_optimization/results/20260505_aurora/`):

| Config            | FFS (steps to 3.28) |
|-------------------|---------------------|
| Prior record #10  | 3250                |
| Prior record #11  | 3225                |
| Aurora + #11 stack| **3175**            |
| **H266 baseline** | **3000**            |

**Critical caveat:** The `20260505_aurora` run was layered on the Contra-Muon + u/w-floor stack
(#11 at FFS~3225), not on the MuonH scale_invariant + μLoCo H266 stack (FFS=3000). The prior
test demonstrates Aurora improves over its own comparison stack by 50 steps, but says nothing
about whether it helps or hurts on H266. These are mechanistically different stacks:

- H266 uses MuonH scale_invariant (always-active F-norm constraint)
- The #11 stack uses standard Muon polar without scale_invariant
- H266 uses μLoCo outer SGD (sync every 30 steps, outer Nesterov)
- The #11 stack has no outer momentum

Aurora has never been paired with scale_invariant mode or μLoCo. The prior test is uninformative
about H266 compatibility.

---

## Critical Verdict

**CONDITIONALLY VIABLE for a narrow mechanism-isolating probe.**

Supporting factors:
1. Aurora is mechanism-distinct from all 7 confirmed H266 hard-load-bearing axes — it operates
   on a previously untested degree of freedom (row-norm equalization within the polar step).
2. Aurora's improvement on its comparison stack (+50 FFS steps) is a proof-of-concept that the
   mechanism can produce gains; the question is whether it transfers to the H266 stack.
3. The integration is truly surgical (one function call replacement, two new flags). No risk of
   introducing confounds with other components.
4. Compatibility with scale_invariant is theoretically sound: Aurora changes direction geometry,
   scale_invariant constrains the parameter F-norm post-update — these are different operations
   on different objects.

Risk factors:
1. FFS on H266 (3000) is already 175 steps ahead of Aurora's best known result (3175 on #11
   stack). If Aurora's benefit is additive with the stack it was tested on, the net on H266
   could be near-zero or negative.
2. MuonH scale_invariant already normalizes parameter norms; it is unclear whether Aurora's
   row-equalization adds independent signal or is partially redundant with scale_invariant's
   per-step geometry preservation.
3. With pp_iterations=2 there is a modest compute overhead per step (~2× Newton-Schulz calls
   for tall matrices). On the H266 stack this is BODY parameters only (embed stays AdamW).
4. H266 is confirmed sensitive to polar kernel (NS step count); Aurora's D-preconditioned polar
   traverses a different sequence of iterates even with the same 12 NS steps. Unknown interaction.

**Net judgment:** The mechanism is untested in the H266 context, mechanism-distinct from ruled-out
axes, and cheap to probe. A 3-arm experiment costs one student slot. The prior evidence is
positive-but-conditional. Worth one targeted probe — but must control for the correct comparison
stack (H266, not #11).

---

## Minimal 3-Arm Hypothesis

**Hypothesis slug:** `aurora-polar-h266`

**Null hypothesis:** Row-norm equalization in the polar step provides no FFS benefit on the
H266 MuonH scale_invariant + μLoCo stack because scale_invariant's F-norm constraint already
absorbs the geometric benefit, or because the H266 stack's effective update geometry is already
approximately row-equalized through μLoCo momentum smoothing.

**Alternative:** Aurora's explicit row-equalization reduces directional dominance among tall
MLP neurons, lowering loss variance across seeds and accelerating passage through the 3.28
threshold, reducing FFS by ≥25 steps (one reporting interval).

All arms: H266 stack unchanged except the polar step in `muon_update()`.

| Arm | Config | Expected behavior if hypothesis is alive |
|-----|--------|------------------------------------------|
| A (CTRL)   | H266 exact baseline: `zeropower_via_newtonschulz5`, no new flags | FFS ≈ 3000, val ≈ 3.268 |
| B (AURORA) | Aurora polar: `pp_iterations=2, pp_beta=0.5` replacing `zeropower_via_newtonschulz5` in `muon_update()` for tall matrices; square matrices unchanged | FFS < 3000 if Aurora helps; FFS ≥ 3000 if neutral/harmful |
| C (EQ1)    | Muon EQ: `pp_iterations=1` (single row-normalize then polar — mechanism-minimal Aurora, no iterative refinement) | Diagnostic: if C matches B, the benefit is from row-norm init alone, not iterative refinement |

**Implementation instructions for student:**

In `muon_update()` (around line 572 of `train_gpt_simple.py`), replace:
```python
update = zeropower_via_newtonschulz5(update)
```

with an Aurora-style alternating-projection block controlled by `--pp_iterations` (default 1
to preserve current behavior at flag omission) and `--pp_beta` (default 0.5):

```python
if pp_iterations == 1:
    # Muon EQ: single row-normalize then standard polar
    m, n = update.size(-2), update.size(-1)
    if m > n:
        row_norm = update.norm(dim=-1, keepdim=True).clamp_(min=1e-7)
        update = zeropower_via_newtonschulz5(update / row_norm)
    else:
        update = zeropower_via_newtonschulz5(update)
else:
    # Aurora: alternating projection for tall, standard polar for square/wide
    m, n = update.size(-2), update.size(-1)
    if m > n:
        G32 = update.float()
        target_row_sq = n / m
        D = 1.0 / G32.norm(dim=-1, keepdim=True).clamp_(min=1e-7)
        for k in range(pp_iterations):
            U = zeropower_via_newtonschulz5((D * G32).bfloat16()).float()
            if k < pp_iterations - 1:
                row_sq = U.pow(2).sum(dim=-1, keepdim=True).clamp_(min=1e-14)
                D = D * (target_row_sq / row_sq).pow(pp_beta)
        update = U.bfloat16()
    else:
        update = zeropower_via_newtonschulz5(update)
```

Add argparse flags:
```
--pp_iterations  int, default=1  (1 = Muon EQ, 2 = full Aurora)
--pp_beta        float, default=0.5
```

Pass `pp_iterations` and `pp_beta` from `MuonH` group through `muon_update()` call signature.

**Note on default:** Set `--pp_iterations` default to 1 (Muon EQ) not 0 (current behavior)
so Arm C is the default and Arm B requires explicit `--pp_iterations 2`. This makes the flag
semantics clean: 1 = minimal equalization, 2 = full Aurora.

Or alternatively, add a separate `--aurora_polar` boolean flag that enables the Aurora branch,
keeping `--pp_iterations=1` and `--pp_beta=0.5` as Aurora-specific params. Either approach
is fine; the student should choose based on what is cleaner in the existing argparse structure.

**Run budget:** 3 seeds minimum per arm for initial screen; 10+ seeds if Arm B shows FFS gain.
Use same H266 hyperparameters: `lr=0.003`, `muonh_mode=scale_invariant`, μLoCo sync every 30,
EMA at H266 decay. Do NOT change any other hyperparameter.

**Discriminating observable:** FFS (first_fixed_step to val ≤ 3.28). Secondary: val at step
3000 and seed std at step 3000 (lower std = Aurora reducing directional dominance). If arm B
improves FFS but increases std, the mechanism is fragile. If arm C matches arm B, iterative
refinement adds no benefit and Muon EQ is the cheaper win.

**Falsifying result:** FFS ≥ 3025 on Arm B (no improvement, within noise) with n ≥ 3 seeds
would indicate Aurora's row-equalization either does not interact positively with scale_invariant
or is already satisfied by H266's geometry. Close the direction and return to other open axes.

---

## Related Papers and Refs

- Aurora blog (Tilde Research, 2026-05-05): https://tilde-research.github.io/aurora-release/
- Aurora source: https://github.com/tilde-research/aurora-release
- Muon optimizer (Jordan, 2024): https://github.com/KellerJordan/modded-nanogpt
- Muon paper (Kosson et al., 2024): Spectral descent / orthogonality-preserving updates
- MuonH (H266 stack component): `train_gpt_simple.py` in current codebase
- Prior track-3 Aurora result: `records/track_3_optimization/results/20260505_aurora/README.md`

---

## Research State Update

**Current best explanation for FFS ceiling:** H266 is at a joint optimum on 7 confirmed
hard-load-bearing axes. Further gains require either (a) an untested geometric/algorithmic
degree of freedom in the optimizer, or (b) a fundamentally different optimization regime.
Aurora probes (a). The seven confirmed axes are all saturated with catastrophic penalties for
deviation; Aurora operates orthogonally on row-norm distribution within the polar step.

**Open uncertainties blocking better decisions:**
1. Does scale_invariant mode in MuonH already implicitly enforce row-norm uniformity through
   its per-step F-norm projection, making Aurora's equalization redundant?
2. Is the μLoCo outer momentum (which smooths gradients across 30 steps) already averaging
   out row-norm imbalance before it reaches the polar step?
3. Is there a compute-per-step cost on the H266 stack that causes FFS regression even if
   per-step loss is improved (step count vs. wall-clock trade-off in the official metric)?

**Stop condition:** If Arm B FFS ≥ 3025 with n ≥ 5 seeds, close the Aurora direction.
If Arm B FFS ≤ 2975, merge and investigate Aurora + other axes (pp_beta sweep, lr re-tune
for Aurora's slightly different update geometry).
