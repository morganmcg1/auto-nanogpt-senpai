# HYPOTHESIS — alphonse: pre-target depth-stratified body PMuon momentum DECAY ×0.10 @ step 2750

**Status:** ASSIGNED 2026-06-01 10:00 UTC
**Student:** g1r1-alphonse
**PR:** TBD

## Mechanism

Block-stratified body PMuon momentum PARTIAL DECAY (`m *= 0.10`) at **step 2750 (pre-target boundary)**, bilateral on the two extreme depth subsets:

- **Arm A:** shallow blocks (0-3), factor ×0.10 @ step 2750
- **Arm B:** deep blocks (8-11), factor ×0.10 @ step 2750

The intervention reuses the same flag set as alphonse #2048 (`--body_muon_momentum_zero_blockwise_step / _subset / _factor`); only the step boundary moves from 975 → 2750 and the factor moves from 0.25/0.50 → 0.10.

## Why this fills a real cell

The body PMuon momentum DECAY surface is the closest the entire 1gpu-r1 wave has come to crossing the gate. The matrix so far:

| boundary | subset | ×0.10 | ×0.20 | ×0.25 | ×0.50 | source |
|---|---|---|---|---|---|---|
| **step 975** | shallow (0-3) | edward #2040 in-flight (seed-2) | edward #2040 in-flight | **+0.286 (MIN)** | +1.703 | #1980/#2040 |
| **step 975** | deep (8-11) | — | — | +2.086 | +1.966 | #2048 (CLOSED) |
| **step 975** | joint (all) | — | — | +1.37 (HARD-ZERO=#1876) | — | #1876 |
| **step 2750** | **joint** | — | — | +2.06 (#1836) | +2.40 (#1836) | #1836 |
| **step 2750** | **shallow** | **THIS PR Arm A** | — | — | — | — |
| **step 2750** | **deep** | **THIS PR Arm B** | — | — | — | — |

**Two facts collide here:**
1. shallow ×0.25 @ step 975 is the closest near-miss of the entire body PMuon momentum surface (+0.286 mnat; need ~0.3 mnat more).
2. step 2750 (pre-target boundary) is where the val_ema gap signal materializes — the canonical β₂ pulse @ step 975 doesn't reach this boundary.

**Pre-target × depth-stratified × DECAY is the only depth × boundary × decay cell unfilled** and the factor ×0.10 matches edward's near-miss-suggesting magnitude at the lower end of the U-shape.

## Predictions

| outcome | interpretation |
|---|---|
| Arm A (shallow) clean WIN (sr≤2862.5 OR sr=2875 AND val_ema<3.262854) | Depth asymmetry from step 975 transfers — shallow blocks tolerate momentum decay even better at pre-target. Strong mechanism candidate. Trigger seed-2. |
| Arm A NULL, near-miss | Mark the pre-target × shallow cell with the closest-miss magnitude. Inform next-step fine sweep. |
| Both arms strongly NULL (+2 mnat or worse) | Pre-target × depth × DECAY closed; body PMuon momentum surface fully exhausted. Move alphonse off the momentum axis entirely. |
| Arm B (deep) better than Arm A (shallow) | Depth asymmetry inverts at pre-target — implies deep blocks need REDUCED momentum at the final descent boundary. Counterintuitive and informative. |

## Reproduce commands

### Arm A — shallow (0-3) × ×0.10 @ 2750

```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 2750 \
  --body_muon_momentum_zero_blockwise_subset shallow \
  --body_muon_momentum_zero_blockwise_factor 0.10 \
  --wandb_group g1r1-alphonse-pretarget-depth-decay \
  --wandb_name g1r1-alphonse/pretarget-shallow-x0.10
```

### Arm B — deep (8-11) × ×0.10 @ 2750

```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 2750 \
  --body_muon_momentum_zero_blockwise_subset deep \
  --body_muon_momentum_zero_blockwise_factor 0.10 \
  --wandb_group g1r1-alphonse-pretarget-depth-decay \
  --wandb_name g1r1-alphonse/pretarget-deep-x0.10
```

**Chain rule:** Arm A first, Arm B after Arm A terminates cleanly (wait for `wandb.finish()` AND training process exit code).

**Seed-2 trigger:** If either arm shows sr=2875 AND val_ema < 3.262854 (clean clause-2 pass), launch a seed-2 confirmation run of that arm before posting terminal SENPAI-RESULT.

## Baseline (PR #1532)

- **speedrun/final_first_step_to_target:** 2875 (n=2)
- **ema/val_loss_ema:** 3.262854 (n=2 mean)
- **Gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
- **W&B baseline runs:** `9coyk2ke` (seed-1), `09qrijtm` (seed-2)

## Sentinel verification

Expected log line at step 2750 (both arms):
```
[step 2750] body_muon_momentum_zero_blockwise: n_eligible=24, n_scaled=24 (subset={shallow|deep}, factor=0.10)
```

W&B summary expectations:
- `body_mom_blockwise/n_modified=24` (4 blocks × 6 PMuon param tensors)
- `body_mom_blockwise/factor=0.10`
- `body_mom_blockwise/op_decay=1`
- `body_mom_blockwise/fired=1`

## SENPAI-RESULT format

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA>","<armB>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<int>},"test_metric":{"name":"ema/val_loss_ema","value":<float>}}
```

Use the run with the BEST primary_metric (lower sr is better) for the metric values. If both arms tie on sr, use the run with lower val_ema.

## Why this assignment for alphonse

- Direct continuation of alphonse's #2048 (deep ×0.25/0.50 @ step 975) — same flag set, only step + subset + factor differ
- Pre-target boundary is the unique unfilled timing axis for body PMuon momentum
- Single-flag-swap experiment, zero new code
- Pre-target ×0.10 × shallow is the most likely cell to produce a positive signal given edward's #2040 trend
- Directive #1252 alignment: (a) optimizer-state at phase boundaries, (b) per-block optimizer behavior, (d) momentum state handling
