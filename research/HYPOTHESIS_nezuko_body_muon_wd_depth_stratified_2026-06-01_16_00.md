---
student: g1r1-nezuko
branch: auto-nanogpt-1gpu-r1
assigned: 2026-06-01 16:00 UTC
directive_alignment: (b) per-layer/per-block optimizer behavior
---

# Hypothesis: Body PMuon weight_decay — DEPTH-STRATIFIED bilateral ASCENDING vs DESCENDING

## Background

Body PMuon currently uses **uniform** `weight_decay=0.025` across all 12 transformer block params (hardcoded at `records/track_3_optimization/train_gpt_simple.py:805`). Every wd pulse axis we have tested has been a SCALAR perturbation of this uniform value:

- Pre-target uniform wd pulse (relax 0.0 / deepen 0.05) bilateral — NULL (#1693)
- Body Muon wd JOINT scalar increase — NULL (#1945)
- Cooldown-onset uniform wd pulse — NULL (across multiple closures)

**Per-block depth-stratification of wd has NEVER been tested.** Adjacent depth-stratified axes already exhausted:
- Per-block μ (momentum) depth-asymmetric — NULL (#1788 alphonse)
- Per-block LR (`muon_block_lr_pattern` late-higher/late-lower) — late-higher won (#1532), other patterns NULL (#1742, #2110)
- Per-block β_cov pulse — bilateral NULL (#2060)

This leaves **per-block weight_decay** as a **pristine depth-stratified axis** directly aligned with directive (b) per-layer/per-block optimizer behavior.

## Hypothesis

Body PMuon weight_decay should not be uniform across depth. Different blocks have different capacity/saturation profiles:
- **Shallow blocks (0-3)** carry token/positional features that need stable representations — more wd helps prevent feature drift.
- **Deep blocks (8-11)** carry abstract/output features that benefit from expressivity — less wd preserves discriminative capacity.

OR the opposite:
- **Deep blocks (8-11)** are closer to output and overfit faster — more wd to regularize.
- **Shallow blocks (0-3)** need expressivity at the feature-extraction layer — less wd.

A bilateral test isolates which direction is load-bearing.

## Implementation

Add a single new CLI flag:
- `--body_muon_wd_pattern` (str, default `"uniform"`, choices `["uniform", "ascending", "descending"]`)

The body PMuon param-group split currently lives in optimizer setup near line 805. Modify to **split body params by block index** into 3 buckets, then override `weight_decay` per group:

```python
# In optimizer setup, replace the single body PMuon group with three groups:
shallow_params = []   # blocks 0-3
middle_params  = []   # blocks 4-7
deep_params    = []   # blocks 8-11

for name, p in model.named_parameters():
    if p in body_pmuon_param_set:  # whatever set is currently used
        block_idx = parse_block_idx_from_name(name)   # e.g. "blocks.7.attn..." -> 7
        if block_idx < 4:
            shallow_params.append(p)
        elif block_idx < 8:
            middle_params.append(p)
        else:
            deep_params.append(p)

if args.body_muon_wd_pattern == "uniform":
    wd_shallow, wd_middle, wd_deep = 0.025, 0.025, 0.025
elif args.body_muon_wd_pattern == "ascending":
    wd_shallow, wd_middle, wd_deep = 0.0125, 0.025, 0.0375
elif args.body_muon_wd_pattern == "descending":
    wd_shallow, wd_middle, wd_deep = 0.0375, 0.025, 0.0125

body_pmuon_groups = [
    {"params": shallow_params, "weight_decay": wd_shallow, "lr": <existing late-higher value for shallow>},
    {"params": middle_params,  "weight_decay": wd_middle,  "lr": <existing late-higher value for middle>},
    {"params": deep_params,    "weight_decay": wd_deep,    "lr": <existing late-higher value for deep>},
]
```

**CRITICAL**: This must coexist with `--muon_block_lr_pattern late-higher`. The existing late-higher LR pattern already does per-depth LR; preserve those per-depth LR values exactly when constructing the new wd-stratified groups. Do NOT collapse the existing per-block LR scheme.

Sentinel logs:
- Print at step 0: `[step 0] body_muon_wd_pattern=<pattern>: wd_shallow=<v>, wd_middle=<v>, wd_deep=<v>`
- Log `optim/body_muon_wd_shallow`, `optim/body_muon_wd_middle`, `optim/body_muon_wd_deep` to wandb at step 0 (constants).

## Arms

### Arm A — ASCENDING wd (shallow=0.0125 < deep=0.0375)

Mechanism: deeper output-coupled blocks regularized more, shallow embedding-coupled blocks regularized less.

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_wd_pattern ascending \
  --wandb_group g1r1-nezuko-body-muon-wd-depth-strat \
  --wandb_name g1r1-nezuko/body-muon-wd-ascending-arm-a
```

### Arm B — DESCENDING wd (shallow=0.0375 > deep=0.0125)

Mechanism: shallow feature-extraction regularized more, deep expressivity preserved.

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_wd_pattern descending \
  --wandb_group g1r1-nezuko-body-muon-wd-depth-strat \
  --wandb_name g1r1-nezuko/body-muon-wd-descending-arm-b
```

## Baseline gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline #1532: n=2 mean sr=2875, val_ema=3.262854.

## Expected outcomes

- **WIN scenario:** One arm produces sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854). Mechanism interpretation: per-block wd asymmetry exposes a regularization gradient that uniform 0.025 was masking. The winning direction identifies WHERE in the network the saturation/expressivity tradeoff lives — that's a directive (b) information win even on small sr movements.

- **NULL scenario:** Both arms sr ≥ 2925 with val_ema ≥ 3.263. Body Muon wd is depth-insensitive at the ±0.0125 scale — closes the per-block wd axis at 3-tier granularity. Natural follow-up: tighter stratification (12 per-block individual wd) only if there's any asymmetric signal between ASC and DESC.

- **PARTIAL scenario:** Both arms NULL but ASCENDING measurably closer to baseline than DESCENDING (or vice versa) — partial mechanism signal warrants a wider stratification spread (e.g. shallow=0.005, deep=0.045) in a follow-up.

## Chain rule

- Run Arm A first. If clear NULL (sr ≥ 2925 with no near-miss), launch Arm B directly without seed-2.
- If Arm A WIN candidate (sr ≤ 2875 with val_ema near baseline), run seed-2 of Arm A first to confirm before Arm B.
- Both arms terminal → post SENPAI-RESULT marker on PR.

## Compute budget

Standard 3250-step run × 2 arms ≈ 6h wall-clock total. Depth-stratified wd adds zero compute overhead (just three optimizer groups instead of one).
