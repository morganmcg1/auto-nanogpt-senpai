# HYPOTHESIS — thorfinn — Joint aux Adam multi-group LR DECAY at cooldown onset step 975

**Branch:** `g1r1-thorfinn/aux-adam-joint-lr-decay-cooldown`
**Assigned:** 2026-05-31 00:55 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (c) short phase-specific mechanisms; (e) schedules that steepen loss descent; (b) per-layer/per-block optimizer behavior

## Why this hypothesis

A FRESH SIGNAL emerged from frieren #1850 Arm B (`414cvcw7`): **scalar-only LR ×0.5 step-down @ step 975** delivered a thin-margin WIN candidate (sr=2875, val_ema=3.262813, -0.041 mnat below gate). The asymmetric counterpart (Arm A scalar_lr ×2 BOOST) regressed by +4.836 mnat NULL.

**Asymmetric pattern indicates a directional mechanism:** higher cooldown-onset scalar LR overshoots (HURTS); lower scalar LR damps that overshoot (HELPS).

The natural extension: **does this LR-decay benefit scale across ALL aux Adam groups, or is it localized to scalars?**

Aux Adam has three named param groups, each with very different baseline LRs:
- `adam_scalars` (lr=0.025) — RMSNorm gain/bias scaling — frieren tested here, thin WIN @ ×0.5
- `adam_embed` (lr=0.3) — token + position embeddings — UNTESTED at LR decay
- `adam_lm_head` (lr=1/160 ≈ 0.00625) — output projection — UNTESTED at LR decay

**Three plausible outcomes:**

1. **Joint decay BIGGER WIN than scalar-only:** All three aux groups benefit from LR damping at cooldown onset. The mechanism is general LR overshoot in cooldown phase, not just scalars. JOINT WIN dominates #1850 Arm B.
2. **Joint decay smaller/null:** The benefit is scalar-specific (RMSNorm gain dynamics are the critical mechanism). Embedding + lm_head LR decay introduces unhelpful perturbation. Closes the joint axis.
3. **Joint decay HURTS:** Decaying embed/lm_head LR at cooldown disrupts late-stage embedding refinement. Localizes WIN to scalar-only.

Each outcome is informative. Outcome 1 would be a NEW DOMINANT WIN ROUTE.

## Distinct from in-flight and closed work

- **frieren #1850** (in flight, Arm B thin WIN candidate, seed-2 requested): scalar-only LR step-down @975 — different group localization (scalars ONLY)
- **nezuko #1880** (assigned 00:55 UTC): body PMuon Nesterov OFF — different optimizer entirely
- **tanjiro #1881** (in flight): aux Adam m-state PARTIAL DECAY @975 — different state (m-buffer, not LR)
- **alphonse #1879** (in flight): aux Adam m-zero @ LATE boundaries — different temporal location
- **#1637, #1697** (CLOSED): body Muon LR-UP/LR-DOWN — different optimizer (body PMuon, not aux Adam)
- **No prior JOINT multi-group aux Adam LR pulse at any temporal boundary.**

## Experiment design

**Bilateral magnitude test on JOINT aux Adam LR decay at step 975 (axis: decay scale):**

- **Arm A — All 3 groups × 0.5 @ step 975** (matched magnitude with #1850 Arm B scalar test)
- **Arm B — All 3 groups × 0.25 @ step 975** (heavier decay; probe diminishing returns)

Both arms preserve all canonical interventions: aux β₂ pulse 0.95→0.99 @ 975, pEMA refresh @ 2600, late-higher block LR, ema_beta=0.97. Both arms target the same temporal boundary as the #1850 WIN candidate.

## Implementation guidance

The cosine LR schedule trap applies: modifying `group["lr"]` without `group["initial_lr"]` will be overridden by the scheduler on the next step. Both must change.

**Step 1: Add CLI flags** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--aux_adam_all_lr_scale_step", type=int, default=0,
    help="Step at which to multiplicatively scale ALL aux Adam param-group LRs "
         "(adam_scalars, adam_embed, adam_lm_head). 0 disables.",
)
parser.add_argument(
    "--aux_adam_all_lr_scale_factor", type=float, default=1.0,
    help="Scale factor applied to all aux Adam group LRs when "
         "aux_adam_all_lr_scale_step fires. 1.0 is no-op.",
)
```

**Step 2: Apply joint LR scale in training loop** — BEFORE `optimizer1.step()`:

```python
if (args.aux_adam_all_lr_scale_step > 0
        and step == args.aux_adam_all_lr_scale_step
        and args.aux_adam_all_lr_scale_factor != 1.0):
    n_scaled = 0
    scale = float(args.aux_adam_all_lr_scale_factor)
    log_groups = {}
    for group in optimizer1.param_groups:
        name = group.get("name", "<unnamed>")
        if "initial_lr" in group:
            new_initial = float(group["initial_lr"]) * scale
            old_initial = float(group["initial_lr"])
            group["initial_lr"] = new_initial
            log_groups[f"{name}/initial_lr_before"] = old_initial
            log_groups[f"{name}/initial_lr_after"] = new_initial
        if "lr" in group:
            new_lr = float(group["lr"]) * scale
            old_lr = float(group["lr"])
            group["lr"] = new_lr
            log_groups[f"{name}/lr_before"] = old_lr
            log_groups[f"{name}/lr_after"] = new_lr
        n_scaled += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux Adam JOINT LR x{scale} on {n_scaled} groups", console=True)
        for k, v in log_groups.items():
            print0(f"    {k} = {v:.6e}", console=True)
        if wandb.run is not None:
            wandb.log({"aux_adam_joint_lr/step": step,
                       "aux_adam_joint_lr/factor": scale,
                       "aux_adam_joint_lr/n_scaled": n_scaled,
                       **{f"aux_adam_joint_lr/{k}": v for k, v in log_groups.items()}},
                      step=step)
```

**CRITICAL:**
- Default `aux_adam_all_lr_scale_step=0` and `aux_adam_all_lr_scale_factor=1.0` MUST be a no-op.
- Modify BOTH `group["lr"]` and `group["initial_lr"]` — otherwise the cosine scheduler will override on the next step.
- Apply to ALL three aux groups: `adam_scalars`, `adam_embed`, `adam_lm_head`. Verify `n_scaled == 3` (or however many groups optimizer1 has).
- Do NOT touch body PMuon (optimizer2).
- Do NOT combine with `--aux_scalars_lr_scale_step` (frieren's flag) — separate intervention.

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_all_lr_scale_step 50 --aux_adam_all_lr_scale_factor 0.5
```

Assert:
1. Sentinel `[step 50] aux Adam JOINT LR x0.5 on 3 groups` fires.
2. Verify W&B logs show all three group LRs halve at step 50.
3. Train loss continues descending normally — no NaN, no spike, no overshoot from the LR step.
4. Verify subsequent cosine LR schedule continues from the new `initial_lr` (not the old).

## Reproduce commands

**Arm A — All aux groups × 0.5 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_all_lr_scale_step 975 --aux_adam_all_lr_scale_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-thorfinn-aux-joint-lr-decay \
  --wandb_name g1r1-thorfinn/aux-joint-lr-armA-x0.5
```

**Arm B — All aux groups × 0.25 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_all_lr_scale_step 975 --aux_adam_all_lr_scale_factor 0.25 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-thorfinn-aux-joint-lr-decay \
  --wandb_name g1r1-thorfinn/aux-joint-lr-armB-x0.25
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT forget to modify `initial_lr`** — cosine schedule trap; LR-only changes get overridden.
- **Do NOT touch body PMuon (optimizer2)** — separate axis.
- **Do NOT skip the joint pulse logging** — need to verify all 3 group LRs change, not just one.
- **Do NOT change temporal boundary** — step 975 is the WIN-bearing boundary per #1850.
- **Do NOT touch β₂ pulse, pEMA refresh, block LR pattern** — preserve all canonical interventions.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A or B WIN (deeper than #1850 Arm B)** | Joint LR decay dominates scalar-only — general cooldown LR overshoot is the mechanism. NEW DOMINANT WIN ROUTE. Request seed-2. |
| **Arm A or B WIN (within #1850 gate margin)** | LR decay benefit is broad — joint matches scalar-only. Cheaper to implement as scalar-only. |
| **Both NULL, Arm A closer to #1850 magnitude than Arm B** | Joint decay saturates; ×0.5 is the sweet spot but scalar-only captures the benefit. |
| **Both NULL or regress** | Embedding/lm_head LR decay is harmful — benefit is scalar-localized. Confirms #1850 mechanism is RMSNorm-specific. |
| **Both regress significantly** | Joint LR pulse perturbs essential cooldown-phase weight refinement. Closes the joint axis decisively. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
