# Hypothesis: Newton-Schulz iteration count BLOCK-STRATIFIED bilateral (edward)

**Date:** 2026-06-02 05:15 UTC
**Student:** edward (auto-nanogpt-1gpu-r1)
**Directive alignment:** #1252 (b) per-layer/per-block optimizer behavior + (d) preconditioner state handling

## Context

Edward #2180 just closed bilateral NULL on body-Muon per-block LR ramp SHAPE (convex p=0.5 +3.49 mnat / concave p=2.0 +2.10 mnat). Per-block LR ramp axis is now exhaustively explored: direction (#2110), magnitude (#2171 in flight), shape (#2180). The merged late-higher linear pattern is the sharp local optimum for the per-block LR family.

Per-block polar projection PRECISION remains a pristine axis:
- alphonse #2162 closed the TEMPORAL NS_ITERS cooldown schedule (12→8 +3.53 mnat / 12→4 +3.96 mnat NULL — polar precision is structurally required per step)
- alphonse #2219 in flight on NS polynomial COEFFICIENT phase-switch at step 2600 (orthogonal: Jordan fast-conv vs near-identity)
- Block-stratified NS iteration COUNT has never been tested

## Mechanism hypothesis

Late-higher per-block LR gives deep blocks (8-11) ~1.1× the body-Muon LR and shallow blocks (0-3) ~0.9×. The post-NS spectral scaling `update = polar * sqrt(max(1, m/n))` is identical across blocks, but the *input* magnitude to NS (the L_neg @ update @ R_neg whitened gradient) differs systematically with depth via the late-higher pattern.

If polar projection quality varies with input magnitude — i.e., NS converges *faster* on well-conditioned inputs and slower on poorly-conditioned inputs — then the OPTIMAL iter count is plausibly depth-dependent. The Stiefel-manifold projection residual `‖XXᵀ - I‖_F` may stabilize at different polar-convergence basins for shallow vs deep blocks.

Two opposing hypotheses for the asymmetry:
- **(A) Deep blocks benefit from MORE iters:** late-higher LR means deeper blocks get larger updates, larger updates have larger spectral perturbations, polar projection needs more iters to settle the spectrum to clean isometry. Arm B should win.
- **(B) Shallow blocks benefit from MORE iters:** shallow blocks get smaller updates, smaller updates have less spectral signal-to-noise, polar projection extracts the direction more reliably with extra iters. Deep updates are already large enough that ~12 iters is sufficient. Arm A should win.

Either outcome cleanly disambiguates the polar-precision × depth relationship — pristine axis with high informational value.

## Bilateral arm design

NS_ITERS=12 baseline (uniform). Split blocks into shallow (0-5) and deep (6-11). One half raised to NS_ITERS=16, other half held at 12. Mean NS_ITERS = 14 per block — wall-clock slower by ~17% on body-Muon path but ~3.5h terminal still within budget.

- **Arm A (SHALLOW-heavy precision):** NS_ITERS=16 for blocks 0-5, NS_ITERS=12 for blocks 6-11
- **Arm B (DEEP-heavy precision):** NS_ITERS=12 for blocks 0-5, NS_ITERS=16 for blocks 6-11

## Implementation

Add two CLI flags to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument("--ns_iters_shallow", type=int, default=NS_ITERS,
                    help="NS_ITERS override for body-Muon shallow blocks (0-5). "
                         "Default matches global NS_ITERS=12.")
parser.add_argument("--ns_iters_deep", type=int, default=NS_ITERS,
                    help="NS_ITERS override for body-Muon deep blocks (6-11). "
                         "Default matches global NS_ITERS=12.")
```

Modify `pmuon_update` signature to accept `iters_override` (default `None`):

```python
def pmuon_update(..., iters_override: int | None = None, ...):
    ...
    iters = iters_override if iters_override is not None else NS_ITERS
    polar = zeropower_via_newtonschulz5(m_pre.to(update.dtype),
                                         a=ns_a, b=ns_b, c=ns_c,
                                         iters=iters)
```

In `Muon.step` (around line 601), compute per-param iters using the same block-index lookup already used for `param_lr_mults`:

```python
# Existing param_lr_mults logic at line 826 stores per-id block multipliers.
# Mirror it for block-stratified NS_ITERS.
param_ns_iters = {}  # populated at hparam-setup time alongside param_lr_mults
for block_idx, block in enumerate(model.blocks):
    iters_for_block = args.ns_iters_shallow if block_idx < 6 else args.ns_iters_deep
    for p in block.parameters():
        if p.ndim >= 2:
            param_ns_iters[id(p)] = iters_for_block

# Pass through:
update = pmuon_update(..., iters_override=param_ns_iters.get(id(p), NS_ITERS), ...)
```

Add a single sentinel log at step 0:
```python
wandb.log({
    "optim/ns_iters_shallow": args.ns_iters_shallow,
    "optim/ns_iters_deep": args.ns_iters_deep,
}, step=0)
```

Delta: ~25 LOC + 2 CLI args.

## Reproduce commands

**Smoke test (baseline reproduction, both flags = 12 = NS_ITERS):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --ns_iters_shallow 12 --ns_iters_deep 12 \
  --wandb_group g1r1-edward-ns-iters-block \
  --wandb_name g1r1-edward/ns-iters-block-baseline-smoke
```
Run ~50 steps and verify loss matches baseline. (Optional — only if you want bit-exact backward-compat check.)

**Arm A (SHALLOW-heavy precision, shallow=16, deep=12):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --ns_iters_shallow 16 --ns_iters_deep 12 \
  --wandb_group g1r1-edward-ns-iters-block \
  --wandb_name g1r1-edward/ns-iters-block-shallow-heavy-arm-a
```

**Arm B (DEEP-heavy precision, shallow=12, deep=16):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --ns_iters_shallow 12 --ns_iters_deep 16 \
  --wandb_group g1r1-edward-ns-iters-block \
  --wandb_name g1r1-edward/ns-iters-block-deep-heavy-arm-b
```

## Chain rule

1. Implement flags + modify pmuon_update.
2. (Optional) Smoke-test both flags = 12 matches baseline bit-exactly.
3. Launch **Arm A (shallow-heavy)** first.
4. When Arm A is terminal, post intermediate SENPAI-RESULT (terminal=false, pending_arms=true), then launch Arm B.
5. Both arms terminal → post final SENPAI-RESULT (terminal=true, pending_arms=false) with bilateral verdict.

## Baseline / merge gate

Current best: baseline #1532 — n=2 mean sr=2875, val_ema=3.262854.

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline reproduce:
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99
```

## Falsifying outcome

If both arms sr ≥ 2925 AND val_ema ≥ +1.5 mnat over baseline (i.e., both NULL), polar projection precision is depth-invariant — the uniform NS_ITERS=12 is already sufficient regardless of block depth, and adding precision in either half is wasted compute. Closes the spatial NS-iter-count axis.

If one arm clearly wins, the load-bearing depth side localizes where additional polar precision pays off, opening a follow-up fine-stratification (e.g., per-block ramp from 12→18).
