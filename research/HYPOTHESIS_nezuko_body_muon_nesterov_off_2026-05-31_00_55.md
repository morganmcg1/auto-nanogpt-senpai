# HYPOTHESIS — nezuko — Body PMuon NESTEROV OFF at cooldown onset step 975

**Branch:** `g1r1-nezuko/body-muon-nesterov-off-cooldown`
**Assigned:** 2026-05-31 00:55 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state rescaling at phase boundaries; (d) momentum/preconditioner state handling changes; (c) short phase-specific mechanisms

## Why this hypothesis

Body PMuon currently uses **Nesterov momentum**: `update = grad + μ × momentum_buffer` (with `momentum_buffer = μ × momentum_buffer + grad`). The look-ahead amplification of Nesterov is benign during warmup/stable phase (consistent gradient direction) but may be **over-aggressive during cooldown LR decay**, where the gradient direction shifts more sharply as the loss landscape steepens toward the target.

Prior closures hint at this:
- Body PMuon LR step-down @975 (edward #1877, in flight) — testing scalar LR magnitude
- Body PMuon momentum HARD-ZERO @975 (fern #1876, in flight) — testing full momentum reset
- Body PMuon momentum SCALE @975/@2750 (#1797 / #1836) — both bilateral NULL across temporal boundaries
- Body PMuon γ pulse @975 (#1831) — bilateral NULL
- All scalar LR perturbations (#1637 LR-UP, #1697 LR-DOWN, #1660 NS-coefs) — closed

**Untested axis: the Nesterov ON/OFF flag at cooldown onset.** Turning Nesterov OFF removes the look-ahead amplification while preserving the momentum buffer's accumulated direction. This is structurally distinct from momentum scaling, zeroing, or LR perturbation — it changes the UPDATE FORMULA itself.

**Mechanistic prediction:** If Nesterov amplification is the source of cooldown-onset instability, OFF should help. If it's the source of cooldown-onset descent speed, OFF should hurt. Either outcome is informative.

## Distinct from in-flight and closed work

- **fern #1876** (in flight): body PMuon momentum HARD-ZERO @975/@1100 — different intervention (zero buffer, not change update rule)
- **edward #1877** (in flight): body PMuon LR persistent step-down @975 — different axis (LR magnitude)
- **alphonse #1879** (in flight): aux Adam m-only ZERO at LATE boundaries (2600/2750) — different optimizer
- **tanjiro #1881** (in flight): aux Adam m partial DECAY @975 — different optimizer
- **#1815 nezuko** (CLOSED 00:50 UTC): aux Adam m-only ZERO @975 — bilateral NULL on n=2
- **No prior Nesterov ON/OFF intervention on body PMuon at any boundary.**

## Experiment design

**Bilateral test on Nesterov flag at cooldown onset (axis: persistence):**

- **Arm A — Nesterov OFF PERMANENT** from step 975 to terminal (3250)
- **Arm B — Nesterov OFF TRANSIENT** from step 975 to step 2600 (then OFF→ON re-enable at pEMA refresh boundary)

Both arms preserve all canonical interventions: aux β₂ pulse 0.95→0.99 @ 975, pEMA refresh @ 2600, late-higher block LR, ema_beta=0.97. Nesterov is the ONLY axis changed.

## Implementation guidance

The body PMuon optimizer (`optimizer2`) accepts `nesterov` as a per-group flag. At step 975 (or 2600 for Arm B's re-enable), flip the flag.

**Step 1: Add CLI flags** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--body_muon_nesterov_off_step", type=int, default=0,
    help="Step at which to disable Nesterov on body PMuon (optimizer2). 0 disables.",
)
parser.add_argument(
    "--body_muon_nesterov_on_step", type=int, default=0,
    help="Step at which to re-enable Nesterov on body PMuon (transient off). 0 disables (no re-enable).",
)
```

**Step 2: Apply Nesterov flag changes in training loop** — BEFORE `optimizer2.step()`:

```python
if args.body_muon_nesterov_off_step > 0 and step == args.body_muon_nesterov_off_step:
    n_groups = 0
    for group in optimizer2.param_groups:
        if "nesterov" in group:
            group["nesterov"] = False
            n_groups += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] body PMuon Nesterov OFF (n_groups={n_groups})", console=True)
        if wandb.run is not None:
            wandb.log({"body_muon_nesterov/off_step": step, "body_muon_nesterov/n_groups_off": n_groups}, step=step)

if args.body_muon_nesterov_on_step > 0 and step == args.body_muon_nesterov_on_step:
    n_groups = 0
    for group in optimizer2.param_groups:
        if "nesterov" in group:
            group["nesterov"] = True
            n_groups += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] body PMuon Nesterov ON (n_groups={n_groups})", console=True)
        if wandb.run is not None:
            wandb.log({"body_muon_nesterov/on_step": step, "body_muon_nesterov/n_groups_on": n_groups}, step=step)
```

**CRITICAL:**
- Default `body_muon_nesterov_off_step=0` MUST be a no-op (preserves baseline).
- Flip ONLY `optimizer2` (body PMuon) — do NOT touch `optimizer1` (aux Adam) which has no Nesterov flag.
- Verify that `group["nesterov"]` is actually read inside the PMuon step function (it should be, but verify in `records/track_3_optimization/muon_optimizer.py` or equivalent).
- If the PMuon implementation caches the Nesterov flag elsewhere, you may need to flip a buffer attribute as well — check the implementation.

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_nesterov_off_step 50
```

Assert:
1. Sentinel `[step 50] body PMuon Nesterov OFF (n_groups=N)` fires (N is the number of param groups in optimizer2, expected 6-8 depending on block split).
2. Train loss continues descending normally (no NaN, no spike).
3. Add a follow-up sentinel verifying that `optimizer2.param_groups[0]["nesterov"] is False` at step 60.

## Reproduce commands

**Arm A — Nesterov OFF PERMANENT from step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_nesterov_off_step 975 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-nezuko-body-nesterov-off \
  --wandb_name g1r1-nezuko/body-nesterov-off-permanent-armA
```

**Arm B — Nesterov OFF TRANSIENT (off @975, re-ON @2600):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_nesterov_off_step 975 --body_muon_nesterov_on_step 2600 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-nezuko-body-nesterov-off \
  --wandb_name g1r1-nezuko/body-nesterov-off-transient-armB
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT touch aux Adam (optimizer1)** — aux Adam has no Nesterov flag.
- **Do NOT change Nesterov BEFORE step 975** — preserve the warmup-phase Nesterov-ON regime.
- **Do NOT combine with momentum reset or LR pulse** — preserve all canonical interventions; Nesterov is the ONLY axis being changed.
- **Do NOT skip Arm B** — the transient variant tests whether Nesterov OFF is good in cooldown but bad in late phase (or vice versa). Both arms required.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN (Nesterov OFF permanent)** | Nesterov look-ahead is universally over-aggressive in post-cooldown phase. Permanent removal helps. Request seed-2. |
| **Arm B WIN (Nesterov OFF transient, re-ON @2600)** | Nesterov is harmful in cooldown but helpful in late phase. Phase-specific Nesterov scheduling is the lever. Request seed-2. |
| **Arm A NULL, Arm B WIN** | Nesterov is needed in late phase but harmful in cooldown — clear phase-specific signal. |
| **Both NULL similar** | Nesterov flag is a no-op at cooldown — momentum direction memory is already smooth enough. Closes the axis. |
| **Both regress similarly** | Nesterov ON is structurally load-bearing throughout cooldown — closes the axis decisively. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
