## Hypothesis: Body-PMuon momentum β₁ block-stratified ramp (late-higher vs late-lower)

**Date:** 2026-06-02 08:45 UTC
**Student:** thorfinn (auto-nanogpt-1gpu-r1)
**Directive alignment:** #1252 (b) per-layer/per-block optimizer behavior + (d) preconditioner/momentum state handling

## Context

Thorfinn #2171 just closed bilateral NULL on the per-block LR MAGNITUDE axis (n=2 confirmed). Combined with #2110 (direction axis closed: uniform +1.68 mnat, late-lower +3.66 mnat), the **per-block LR (direction × magnitude) 2D subspace is bracketed and locally optimal** at the merged late-higher / spread=0.20 configuration.

Thorfinn's terminal report flagged three follow-up structural axes:
1. ~~Per-block weight decay ramp~~ — **already CLOSED** via nezuko #2151 bilateral (DESCENDING vs ASCENDING WD)
2. **Per-block body-PMuon momentum (β₁) ramp** — **pristine, never tested**
3. Per-block effective gradient clip — pristine but more complex

This hypothesis pursues option 2.

## Mechanism hypothesis

Body PMuon momentum β₁ is currently uniform across all 12 transformer blocks at β₁=0.95 (Muon standard). The per-block LR pattern that won (late-higher: deep blocks get 1.15× LR, shallow blocks get 0.85× LR) creates an asymmetric step-size profile across depth. Momentum smoothing currently does NOT compensate for this asymmetry.

Two opposing physical predictions:

**Prediction A (compensating coupling — late-higher β₁ wins):**
Deep blocks already take *larger* steps (1.15× LR). Larger steps amplify gradient noise per-update. Deep blocks should therefore use SLOWER/SMOOTHER momentum (higher β₁=0.975, longer averaging window) to absorb the larger-LR noise. Shallow blocks with smaller steps (0.85× LR) tolerate FASTER/MORE responsive momentum (β₁=0.925, shorter window).
→ **Arm A: late-higher β₁ pattern** (shallow 0.925, deep 0.975) — coupled with LR pattern

**Prediction B (anti-correlated decoupling — late-lower β₁ wins):**
Deep blocks taking larger steps need momentum that TRACKS the gradient signal *faster* — because each step matters more, you want the momentum direction to reflect the freshest gradient. Shallow blocks with smaller per-step impact can afford to smooth over more history.
→ **Arm B: late-lower β₁ pattern** (shallow 0.975, deep 0.925) — anti-correlated with LR pattern

Either outcome localizes the coupling sign between per-block LR and per-block momentum. Bilateral NULL closes the symmetric perturbation axis (combined with merged uniform β₁=0.95, the per-block β₁ slope axis is fully exhausted at this magnitude).

## Bilateral arm design

- **Arm A (LATE-HIGHER β₁, "compensating coupling"):** shallow blocks (0-5) β₁=0.925, deep blocks (6-11) β₁=0.975. Spread=0.05 around mean 0.95.
- **Arm B (LATE-LOWER β₁, "anti-correlated decoupling"):** shallow blocks (0-5) β₁=0.975, deep blocks (6-11) β₁=0.925. Same spread, opposite direction.

Scope: body-PMuon params only (block.* params, ndim≥2). Aux Adam β₁=0.8 untouched. Per-block override stays in effect throughout the run (no time-varying schedule).

## Implementation

Add CLI flags + per-block β₁ override in the body-PMuon optimizer:

```python
parser.add_argument("--muon_block_b1_pattern", type=str, default="uniform",
                    choices=["uniform", "late-higher", "late-lower"],
                    help="Per-block body-PMuon β₁ ramp. 'uniform' = baseline β₁=0.95 across all blocks.")
parser.add_argument("--muon_block_b1_spread", type=float, default=0.05,
                    help="±spread around mean β₁=0.95 (e.g. spread=0.05 → shallow 0.925, deep 0.975 for late-higher).")
```

In the Muon optimizer setup (mirror the existing `muon_block_lr_pattern` per-block multiplier code path):

```python
def per_block_b1(block_idx, n_blocks, pattern, spread, b1_mean=0.95):
    if pattern == "uniform":
        return b1_mean
    half = n_blocks // 2
    is_shallow = block_idx < half
    if pattern == "late-higher":
        return b1_mean - spread if is_shallow else b1_mean + spread
    elif pattern == "late-lower":
        return b1_mean + spread if is_shallow else b1_mean - spread

# When building param groups for body PMuon:
for block_idx, block_params in enumerate(body_pmuon_groups_by_block):
    block_b1 = per_block_b1(block_idx, n_blocks, args.muon_block_b1_pattern, args.muon_block_b1_spread)
    param_groups.append({
        "params": block_params,
        "which": "body",
        "block_idx": block_idx,
        "muon_b1": block_b1,  # consumed in Muon.step
    })
```

In `Muon.step`, replace the global β₁ read with the per-group `muon_b1`:

```python
b1 = group.get("muon_b1", 0.95)
# ... rest of momentum buffer update ...
```

Add per-block sentinel at step 0 (mirror the existing per-block LR sentinel):

```python
if args.muon_block_b1_pattern != "uniform":
    print(f"per-block body-PMuon β₁ pattern: {args.muon_block_b1_pattern} spread=±{args.muon_block_b1_spread}")
    for block_idx in range(n_blocks):
        b1 = per_block_b1(block_idx, n_blocks, args.muon_block_b1_pattern, args.muon_block_b1_spread)
        print(f"  block {block_idx}: muon_b1={b1:.4f}")
    wandb.log({
        "optim/muon_block_b1_pattern": args.muon_block_b1_pattern,
        "optim/muon_block_b1_spread": args.muon_block_b1_spread,
        "optim/muon_block_0_b1": per_block_b1(0, n_blocks, args.muon_block_b1_pattern, args.muon_block_b1_spread),
        "optim/muon_block_11_b1": per_block_b1(11, n_blocks, args.muon_block_b1_pattern, args.muon_block_b1_spread),
    }, step=0)
```

Delta: ~30 LOC + 2 CLI args. Reuse the per-block LR sentinel infrastructure (already in place).

## Reproduce commands

**Smoke test (baseline reproduction, uniform pattern):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_block_b1_pattern uniform \
  --wandb_group g1r1-thorfinn-block-b1 \
  --wandb_name g1r1-thorfinn/block-b1-uniform-smoke
```
Run ~50 steps and verify loss matches baseline. (Optional — only if you want bit-exact backward-compat check.)

**Arm A (LATE-HIGHER β₁, spread=0.05 → shallow 0.925 / deep 0.975):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_block_b1_pattern late-higher --muon_block_b1_spread 0.05 \
  --wandb_group g1r1-thorfinn-block-b1 \
  --wandb_name g1r1-thorfinn/block-b1-late-higher-arm-a
```

**Arm B (LATE-LOWER β₁, spread=0.05 → shallow 0.975 / deep 0.925):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_block_b1_pattern late-lower --muon_block_b1_spread 0.05 \
  --wandb_group g1r1-thorfinn-block-b1 \
  --wandb_name g1r1-thorfinn/block-b1-late-lower-arm-b
```

## Chain rule

1. Implement flag + per-block β₁ override in body-PMuon param group setup + `Muon.step`.
2. (Optional) Smoke-test with `--muon_block_b1_pattern uniform` to verify baseline bit-exactness.
3. Launch **Arm A (LATE-HIGHER β₁)** first.
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

If both arms sr ≥ 2925 AND val_ema ≥ +1.5 mnat over baseline (i.e., both NULL), per-block body-PMuon β₁ slope at spread=±0.05 is structurally NULL in both directions — combined with merged uniform β₁=0.95, the per-block β₁ slope axis is bracketed and closed at this magnitude.

If one arm clearly wins, the coupling sign between per-block LR (late-higher) and per-block β₁ is localized:
- Arm A wins → **compensating coupling** (deep blocks need slower momentum to absorb larger LR noise).
- Arm B wins → **anti-correlated decoupling** (deep blocks need faster momentum to track fresher gradients despite larger LR).

Either WIN opens follow-up sweeps:
- Magnitude sweep at the winning direction (spread=0.025, 0.075) to bracket the optimum.
- Cross-block-LR pattern test (e.g. late-higher β₁ paired with uniform LR) to confirm whether coupling is intrinsic or LR-induced.

## Notes for student

- Body PMuon currently uses β₁=0.95 as the standard Muon momentum value. Confirm this is the actual default in the codebase before launching (grep for `0.95` near the Muon optimizer setup) — if your default differs, recenter the spread accordingly.
- The flag name `--muon_block_b1_pattern` mirrors the existing `--muon_block_lr_pattern` convention for consistency. Spread convention also mirrors `--muon_block_lr_spread`.
- Step-0 sentinel: confirm bit-exact per-block β₁ assignments (block_0=0.925, block_11=0.975 for Arm A; reversed for Arm B).
- aux Adam β₁=0.8 is untouched — this hypothesis affects body PMuon only.
