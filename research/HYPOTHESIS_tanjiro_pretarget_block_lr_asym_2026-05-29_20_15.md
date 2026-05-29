# HYPOTHESIS — tanjiro pre-target depth-asymmetric body-Muon LR burst

## Tier-2 classification
**Per-block / per-layer optimizer behavior + phase-specific schedule**, directly aligned with human directive #1252 (per-layer optimizer behavior + structural mechanisms over scalar pulses).

## Motivation

Body-Muon **uniform** LR pulse axis is now bilaterally exhausted at the pre-target window:
- LR-UP uniform ×1.25 / ×1.50 — NULL bilateral (alphonse #1637, n=2 seed variance locks sr=2925)
- LR-DOWN uniform ×0.75 / ×0.50 — NULL bilateral (tanjiro #1697; monotonic worsening with deeper drop)

But the LR scalar interacts with the **canonical per-block-lr-pattern** which already injects depth-conditional structure ("late higher LR" pattern was a merged WIN earlier in the run). The closed UP/DOWN tests perturbed all blocks **uniformly** — they did not probe whether the optimal LR change in the pre-target window is **depth-asymmetric**.

Concurrently, edward #1727 is testing **depth-split β_cov** binary group (early=0.97/late=0.92 vs inverted). The directly analogous experiment in **LR** space is untested.

If late-vs-early imbalance is the missing axis, depth-asymmetric LR burst could unlock the WIN that uniform pulses could not.

## Hypothesis

A **per-block LR-multiplier burst** during [2750, 2900) — boosting one half of the 12-block stack and holding the other at canonical — is qualitatively different from uniform ×k pulses and may shift the target-crossing trajectory below baseline sr=2875.

## Bilateral arms

Apply on top of the canonical `muon_block_lr_pattern` (preserve existing per-block weighting). The burst multiplier `M=1.5` is layered on top of the pattern only during the pulse window [2750, 2900), then reverts at step 2900.

| Arm | Block IDs boosted ×1.5 | Block IDs held at ×1.0 |
|---|---|---|
| **A: early-boost** | 0, 1, 2, 3, 4, 5 | 6, 7, 8, 9, 10, 11 |
| **B: late-boost** | 6, 7, 8, 9, 10, 11 | 0, 1, 2, 3, 4, 5 |

Symmetric arms isolate the **direction** of depth dependence.

## Mechanistic separation

| in-flight Tier-2 | what it changes | this hypothesis |
|---|---|---|
| edward #1727 | depth-split **β_cov** (covariance state EMA half-life per depth) | depth-split **LR** scalar — different param of the same depth-asymmetric class |
| nezuko #1726 | covariance-state hard zero **reset** (state discard) | LR boost on state-preserving updates (no state change) |
| askeladd #1730 | momentum-buffer hard zero **reset** (first-moment discard) | LR scaling layered on existing momentum (state-preserving) |
| fern #1739 | NS_ITERS burst (polar projection iter count) | LR scalar burst (no polar change) |
| alphonse #1703 | ADOPT update-rule order swap (whitening async) | canonical PMuon update; LR-only intervention |

## Implementation sketch

The existing `Muon` optimizer already supports `_param_lr_mults` per block. Add three CLI flags:

```python
parser.add_argument('--muon_block_lr_burst_start', type=int, default=-1)
parser.add_argument('--muon_block_lr_burst_end', type=int, default=-1)
parser.add_argument('--muon_block_lr_burst_pattern', type=str, default='none',
                    choices=['none', 'early', 'late'])
parser.add_argument('--muon_block_lr_burst_factor', type=float, default=1.5)
```

In the train loop, mirror tanjiro #1697's per-step-in-window pattern:

```python
burst_active = (args.muon_block_lr_burst_start > 0
                and args.muon_block_lr_burst_end > args.muon_block_lr_burst_start
                and args.muon_block_lr_burst_pattern != 'none'
                and args.muon_block_lr_burst_start <= step < args.muon_block_lr_burst_end)
if burst_active:
    pattern = args.muon_block_lr_burst_pattern  # 'early' or 'late'
    factor = args.muon_block_lr_burst_factor
    # For each param in optimizer2.param_groups, multiply its _param_lr_mult by factor
    # if its block_id matches the selected pattern (early=0-5, late=6-11).
    # set_hparams handles the revert implicitly on step >= end.
```

The exact mutation should mirror tanjiro's working approach in #1697 (mutate `g["lr"]` per-step in window) — but **per-param** rather than per-group, using each param's `_param_lr_mult` and the block id encoded in param naming. Refer to lines 614-617 of `Muon.step` for the per-param multiplier hook.

**Smoke test:** Run with `--muon_block_lr_burst_start 50 --muon_block_lr_burst_end 80 --muon_block_lr_burst_pattern early --muon_block_lr_burst_factor 1.5` for 100 steps. Verify (a) early-block param updates are ×1.5 LR in window, (b) late-block param updates are unchanged, (c) no exception, (d) revert at step 80.

## Reproduce command (single arm)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern <canonical pattern flags> \
  --muon_block_lr_burst_start 2750 --muon_block_lr_burst_end 2900 \
  --muon_block_lr_burst_pattern early --muon_block_lr_burst_factor 1.5 \
  --wandb_name g1r1-tanjiro/pretarget-block-lr-asym-early \
  --wandb_group tanjiro/pretarget-block-lr-asym
```

Replace `--muon_block_lr_burst_pattern early` with `late` for Arm B.

## Telemetry to log

- `pmuon_lr/block{i}_active` for i in [0, 11] — verify the burst pattern shapes LR per block
- `pmuon_lr/burst_fired` (0=pre, 1=in, 2=post)
- Console ENTER/REVERT prints at step 2750/2900
- Existing val_loss_ema/val_loss_live/sr telemetry

## Reporting contract (terminal SENPAI-RESULT)

After Arm A + Arm B both terminal at step 3250, post single bilateral SENPAI-RESULT marker (`terminal=true`, `pending_arms=false`):

```json
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<arm_a>","<arm_b>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<min_sr>},"test_metric":{"name":"val/loss_ema","value":<min_val_ema>}}
```

Include the **bilateral table** (sr / val_ema / val_live / target_margin for both arms vs baseline) and the **per-block LR audit at sentinel steps** (2749, 2751, 2800, 2900, 2901) confirming the burst shaped LR correctly per arm.

## Baseline + merge gate

| metric | baseline #1532 (n=2) |
|---|---|
| `speedrun/final_first_step_to_target` | 2875 |
| `val/loss_ema` | 3.262854 |

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`. Bilateral fail → NULL closure; either arm pass → request seed-2 confirmation before merge.

## Risk note

A 50% boost on half the blocks is large; the burst could destabilize NS5 convergence (matrix conditioning depends on update magnitude). If divergent loss appears in the smoke test, retry with `factor=1.25` before launching full runs.
