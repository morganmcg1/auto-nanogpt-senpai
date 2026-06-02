# Hypothesis: Aux Adam Per-Group ε Asymmetric Allocation (askeladd)

**Assigned:** 2026-06-02 10:00 UTC
**Student:** g1r1-askeladd
**Branch:** g1r1-askeladd/aux-eps-per-group-split
**Directive alignment:** (b) per-layer/per-group optimizer behavior

## Mechanism hypothesis

The baseline uses `eps=1e-8` uniformly across all aux Adam groups (embed, lm_head, scalars). The `eps_dominance_frac` telemetry from PR #1178 reveals a structural asymmetry:

- `adamw/embed/eps_dominance_frac` (terminal) ≈ **0.687%** — embed has non-trivial eps-regime behavior
- `adamw/lm_head/eps_dominance_frac` (terminal) ≈ **0.0015%** — lm_head has essentially zero eps-regime behavior

This asymmetry means embed and lm_head are in fundamentally different AdamW operating regimes. In the eps-dominated regime, the denominator is floored and the update magnitude is controlled by the gradient EMA numerator rather than the second-moment preconditioner.

**lm_head** has near-zero eps_dominance_frac — it is always in the true AdamW second-moment regime. Tightening its ε (1e-8 → 1e-12) gives the preconditioner more dynamic range without disturbing numerics, potentially sharpening the effective LR near cooldown onset.

**embed** has ~0.69% eps-dominated coordinates — the sparse token embedding rows visited infrequently have small accumulated v̂. Tightening ε for embed forces those rare coordinates into a longer second-moment warmup, which may slow early convergence for long-tail tokens.

Bilateral design tests both allocation directions, asking which group benefits more from precision tightening in isolation.

## Why this axis is pristine

- PR #463: Tested embed eps ∈ {1e-8, 1e-7} (both arms changed embed group ONLY — tested looser not tighter)
- PR #1178: Tested global eps ∈ {1e-8, 1e-12} uniformly across ALL groups simultaneously — null result (no differential signal possible)

Neither PR tested asymmetric allocation where one group gets tighter ε while others remain at baseline. The eps_dominance_frac asymmetry was only available as telemetry AFTER PR #1178 ran.

## Bilateral arm design

**Arm A** — lm_head tight, others baseline: `--aux_lm_head_eps 1e-12`

**Arm B** — embed tight, others baseline: `--aux_embed_eps 1e-12`

Bilateral logic: if Arm A wins and Arm B loses (or is neutral), the mechanism is confirmed — lm_head is the load-bearing group for eps precision. If both win, the baseline eps is globally suboptimal. If both lose, eps tightening is harmful regardless of group.

## Implementation sketch

```python
parser.add_argument('--aux_embed_eps', type=float, default=None)
parser.add_argument('--aux_lm_head_eps', type=float, default=None)
parser.add_argument('--aux_scalar_eps', type=float, default=None)

def get_aux_eps(group_name, args):
    override = getattr(args, f'aux_{group_name}_eps', None)
    return override if override is not None else args.aux_eps  # baseline 1e-8

embed_eps   = get_aux_eps('embed',   args)
lm_head_eps = get_aux_eps('lm_head', args)
scalar_eps  = get_aux_eps('scalar',  args)

optimizer_aux = torch.optim.AdamW([
    {'params': embed_params,   'eps': embed_eps,   ...},
    {'params': lm_head_params, 'eps': lm_head_eps, ...},
    {'params': scalar_params,  'eps': scalar_eps,  ...},
], ...)
```

LOC delta: ~20. Runtime: identical to baseline. Each arm: ~3.5h to terminal.

## Reproduce commands (full baseline stack)

**Arm A (lm_head tight, ε=1e-12):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_lm_head_eps 1e-12 \
  --wandb_group g1r1-askeladd-aux-eps-split \
  --wandb_name g1r1-askeladd/aux-eps-per-group-arm-a-lmhead-tight
```

**Arm B (embed tight, ε=1e-12):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_embed_eps 1e-12 \
  --wandb_group g1r1-askeladd-aux-eps-split \
  --wandb_name g1r1-askeladd/aux-eps-per-group-arm-b-embed-tight
```

## Merge gate

Beat #1532 baseline: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Sentinel logging (REQUIRED)

At step 0 log: `per-group aux eps: embed={embed_eps}, lm_head={lm_head_eps}, scalar={scalar_eps}`

## Falsifying result

Both arms lose vs. baseline → eps precision is irrelevant to the loss trajectory; close axis.

## Stop / report

Post terminal SENPAI-RESULT for Arm A with `terminal=false, pending_arms=true`, then immediately launch Arm B without waiting for advisor ack. After Arm B terminal, post FINAL bilateral SENPAI-RESULT with `terminal=true, pending_arms=false` and both run IDs.
