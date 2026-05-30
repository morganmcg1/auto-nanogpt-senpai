# HYPOTHESIS — edward — Body PMuon LR step-down at cooldown onset step 975

**Branch:** `g1r1-edward/body-muon-lr-stepdown-cooldown`
**Assigned:** 2026-05-30 21:30 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state/hyperparam intervention at phase boundary; (e) schedules that steepen loss descent before step 2925

## Why this hypothesis

The body PMuon LR cosine schedule decays smoothly from `muon_lr=0.040` toward zero. At the cooldown onset (step 975 — same step where aux Adam β₂ pulses 0.95→0.99), the body optimizer transitions from "fast learning" to "consolidation," but the LR continues its smooth cosine path. **What if a discrete step-down at step 975 — sharpening the LR transition to match the β₂ pulse boundary — steepens loss descent during the cooldown phase?**

**Mechanistic prior:**
- Lower body Muon LR during cooldown → finer-grained parameter updates → faster fine convergence toward val_loss target.
- The β₂ pulse @ 975 already establishes step 975 as a regime-change boundary; a coordinated LR step-down aligns the body schedule with the aux phase change.
- Cosine schedules average across the whole window; a phase-locked piecewise schedule can outperform smooth cosine when the optimal LR profile is non-monotone-smooth.

**Why this is directive-aligned and distinct:**
- Directive (a): persistent LR hyperparameter intervention triggered at phase boundary.
- Directive (e): step-down sharpens descent rate during cooldown.
- Distinct from #1697 (CLOSED): body Muon LR-DOWN pulse at **pre-target ~2750**, not cooldown onset 975.
- Distinct from #1637 (CLOSED): body Muon LR-UP pulse, opposite direction.
- Distinct from #1868 askeladd (aux Adam **embed_lr** pulse, not body Muon).
- Distinct from #1850 frieren (aux Adam **scalar_lr** pulse, not body Muon).
- Distinct from #1815 nezuko (aux Adam **m-state**, not LR).
- Distinct from fern (body PMuon **momentum**, not LR).
- Distinct from thorfinn #1849 (body PMuon **cov**, not LR).

## Distinct from in-flight and closed work

- **nezuko #1815** (HOT WIN seed-2): aux Adam m-only ZERO @ 975 — different optimizer, different axis.
- **thorfinn #1849** (in flight): body PMuon L/R cov per-side reset @ 1100 — different state.
- **frieren #1850** (in flight): aux Adam scalar_lr pulse — different optimizer.
- **askeladd #1868** (in flight): aux Adam embed_lr pulse — different optimizer.
- **alphonse #1836** (in flight): aux Adam pretarget-momentum-scale — different optimizer, different timing.
- **tanjiro #1837** (in flight): aux Adam β₂ per-group pulse — different axis.
- **fern** (just assigned): body PMuon momentum HARD-ZERO @ 975/1100 — different state (momentum buffer, not LR).
- **#1697** (CLOSED): body Muon LR-DOWN at pre-target window — different boundary.
- **#1637** (CLOSED): body Muon LR-UP — opposite direction.
- No prior body Muon LR step-down at cooldown onset step 975.

## Experiment design

**Bilateral SCALE-magnitude test (timing fixed at cooldown onset 975):**

- **Arm A — Body Muon LR ×0.85 from step 975 onwards** (light step-down; ~15% additional reduction beyond cosine)
- **Arm B — Body Muon LR ×0.70 from step 975 onwards** (heavier step-down; ~30% additional reduction beyond cosine)

Both arms preserve all canonical interventions: aux β₂ pulse @ 975, pEMA refresh @ 2600, late-higher block LR pattern, ema_beta=0.97.

## Implementation guidance

**CRITICAL — cosine LR schedule trap:** The training loop recomputes `group["lr"] = cosine_factor[step] * group["initial_lr"]` every step. Modifying only `group["lr"]` is overwritten at the next step. You **MUST** modify BOTH `group["initial_lr"]` AND `group["lr"]` to make the change persist.

This is the same pattern that askeladd #1868 uses for the aux embed_lr pulse. Reuse that template, but target `optimizer2` (body PMuon) instead of `optimizer1` (aux Adam).

**Step 1: Add CLI flags**

```python
parser.add_argument(
    "--body_muon_lr_stepdown_step", type=int, default=0,
    help="Step at which to apply persistent body Muon LR step-down (0 disables)",
)
parser.add_argument(
    "--body_muon_lr_stepdown_factor", type=float, default=1.0,
    help="Multiplicative factor applied to body Muon initial_lr at stepdown step (1.0 = no-op)",
)
```

**Step 2: Apply step-down in training loop**

At the start of the training step (BEFORE `optimizer2.step()`), check whether to apply the step-down:

```python
if (args.body_muon_lr_stepdown_step > 0
        and step == args.body_muon_lr_stepdown_step
        and args.body_muon_lr_stepdown_factor != 1.0):
    for group in optimizer2.param_groups:
        base_initial_lr_before = group["initial_lr"]
        group["initial_lr"] = group["initial_lr"] * args.body_muon_lr_stepdown_factor
        group["lr"] = group["lr"] * args.body_muon_lr_stepdown_factor
        if dist.get_rank() == 0:
            print0(
                f"[step {step}] body Muon LR step-down: "
                f"initial_lr {base_initial_lr_before:.6f} -> {group['initial_lr']:.6f} "
                f"(factor={args.body_muon_lr_stepdown_factor})",
                console=True,
            )
    if dist.get_rank() == 0 and wandb.run is not None:
        wandb.log({
            "body_muon_lr_stepdown/step": step,
            "body_muon_lr_stepdown/factor": args.body_muon_lr_stepdown_factor,
        }, step=step)
```

**CRITICAL:**
- Default `body_muon_lr_stepdown_step=0` MUST be a no-op (preserves baseline).
- Apply to optimizer2 (body PMuon) ONLY — do NOT touch optimizer1 (aux Adam).
- Block-LR pattern (`muon_block_lr_pattern=late-higher`) operates as multiplier on `initial_lr` per-block; the global step-down preserves the late-higher shape — DO NOT modify block-LR multipliers.
- Verify the step-down persists: at step 976, 1000, 2000, etc., `group["lr"]` should follow the new (scaled) cosine path.

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_lr_stepdown_step 50 --body_muon_lr_stepdown_factor 0.85
```

Assert:
1. Sentinel `[step 50] body Muon LR step-down: initial_lr X -> Y (factor=0.85)` fires at step 50.
2. `body_muon/lr` sparkline shows a discrete downward step at step 50, then continues cosine decay from scaled level.
3. No NaN, no loss spike at the pulse step.

## Reproduce commands

**Arm A — body Muon LR ×0.85 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_lr_stepdown_step 975 --body_muon_lr_stepdown_factor 0.85 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-edward-body-muon-lr-stepdown \
  --wandb_name g1r1-edward/body-muon-lr-stepdown-armA-085
```

**Arm B — body Muon LR ×0.70 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_lr_stepdown_step 975 --body_muon_lr_stepdown_factor 0.70 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-edward-body-muon-lr-stepdown \
  --wandb_name g1r1-edward/body-muon-lr-stepdown-armB-070
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT modify aux Adam LR** — that's askeladd #1868 / frieren #1850 territory.
- **Do NOT pulse LR** (transient one-step change) — this hypothesis tests **persistent step-down** for the remainder of training.
- **Do NOT modify block-LR pattern** — preserve late-higher shape.
- **Do NOT add cooldown/warmup re-rise** — the step-down is monotone-down.
- **Do NOT modify `muon_lr` arg** — keep it at 0.040; apply the scaling via the new flag.
- **Do NOT touch optimizer state** (momentum, cov) — that's fern / thorfinn / nezuko territory.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN (×0.85 @975)** | Light step-down at cooldown boundary outperforms smooth cosine — phase-locked schedule beats baseline. Request seed-2 confirmation. |
| **Arm B WIN (×0.70 @975)** | Heavier step-down preferred — strong signal that cosine is under-decaying during cooldown. Request seed-2 confirmation. |
| **Both WIN, Arm A better** | Light touch sufficient; suggests cosine is close to optimal but discrete boundary preferable. |
| **Both NULL** | Body Muon LR cosine schedule is already well-calibrated at cooldown boundary; step-down axis CLOSED. |
| **Both regress** | Body Muon LR needs to stay HIGH during cooldown — would suggest opposite intervention (LR step-up). |
| **One arm diverges** | Discrete LR change at phase boundary destabilizes Muon polar projection — unlikely but informative. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
