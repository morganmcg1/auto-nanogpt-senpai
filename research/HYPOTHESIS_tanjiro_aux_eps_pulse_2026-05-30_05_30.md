# HYPOTHESIS — tanjiro — Aux AdamW eps transient pulse co-located with β₂ pulse boundary (steps 975-1100)

**Branch:** `g1r1-tanjiro/aux-eps-pulse`
**Assigned:** 2026-05-30 05:30 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state resets/rescaling at phase boundaries + (c) short phase-specific mechanisms + (d) momentum/preconditioner state handling

## Why this hypothesis

The canonical β₂ pulse at step 975 (0.95→0.99) is the confirmed WIN baseline (#1532). The mechanism: at the warmup→cooldown phase boundary, sharply extending the v_t memory horizon clamps variance estimation and produces a smoother effective LR through cooldown.

**The complementary lever at the same boundary that has NOT been tested: the eps stability floor.**

After the β₂ jumps from 0.95 → 0.99 at step 975, the v_t denominator behavior transitions:
- Pre-pulse: v_t memory horizon ≈ 20 steps (β₂=0.95), aggressive tracking of current gradient magnitude
- Post-pulse: v_t memory horizon ≈ 100 steps (β₂=0.99), slow re-accumulation, "thin" denominator while the new β₂ regime fills

**During the 100-step v_t re-accumulation transient (steps 975-1075), the bias-corrected denominator is under-sized relative to the actual current gradient magnitude.** The standard Adam denominator `sqrt(v_t/bias_correction2) + eps` is dominated by the sqrt(v_t/bc2) term — when v_t is transient-thin, the denominator is artificially small, producing transiently-large effective LRs.

**Hypothesis: a transient eps pulse (1e-10 → 1e-6) during steps 975-1100 acts as a stability floor that prevents over-large effective LR during the v_t accumulation transient post-β₂-pulse.** When v_t/bc2 is thin, eps dominates the denominator and damps the update; once v_t/bc2 reaches its steady-state magnitude under β₂=0.99, the denominator returns to v_t-dominated and eps becomes negligible again. The eps pulse self-deactivates as the new β₂ regime fills.

**Mechanistically distinct from in-flight assignments:**
- nezuko #1770: aux Adam m/v hard ZERO RESET at β₂-pulse boundary — STATE DISCARD mechanism
- this tanjiro #XXXX: aux Adam EPS PULSE around β₂-pulse boundary — STATE PRESERVATION + denominator damping
- frieren #1780: body PMuon L_cov/R_cov reset at cooldown onset — body-side parallel to nezuko #1770
- edward #1785: block-wise AdaShift on aux AdamW (variance estimator structural change)

**Untested in 329-PR history.** Aux Adam eps has been at 1e-10 throughout. The eps axis has only been touched as a constant tuning lever (no pulses, no schedules) — its phase-boundary modulation is genuinely novel.

## Experiment design

**Bilateral comparison on eps pulse magnitude (β₂ pulse and pulse window identical to #1532):**

- **Arm A — eps pulse 1e-10 → 1e-6** (1e4× elevation): conservative damping floor. Tests whether moderate eps damping during v_t transient yields measurable smoothing.
- **Arm B — eps pulse 1e-10 → 1e-4** (1e6× elevation): aggressive damping floor. Tests whether stronger damping during the v_t transient compounds with the β₂ pulse.

Both arms pulse eps over the same window [975, 1100) — co-located with the canonical β₂ pulse boundary plus ~125 steps of damping coverage. Eps reverts to 1e-10 at step 1100 (sharp step-back, no ramp).

**Apply to ALL aux Adam param groups (embed + lm_head + scalars).** The β₂ pulse in #1532 applies to all aux groups; the eps pulse should be co-located for symmetry. (If Arm B shows promise but embed-only effect is suspected, a follow-up bilateral can restrict scope.)

## Implementation guidance

Add CLI flag to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--aux_eps_pulse_start", type=int, default=-1,
    help="Step to start aux AdamW eps pulse (-1 = disabled)",
)
parser.add_argument(
    "--aux_eps_pulse_end", type=int, default=-1,
    help="Step to end aux AdamW eps pulse (exclusive, snap back to canonical)",
)
parser.add_argument(
    "--aux_eps_pulse_target", type=float, default=1e-6,
    help="Eps value during pulse window (canonical revert = 1e-10)",
)
```

In the training loop, BEFORE the `optimizer1.step()` call (where optimizer1 = aux AdamW):

```python
eps_pulse_active = (
    args.aux_eps_pulse_start > 0
    and args.aux_eps_pulse_end > args.aux_eps_pulse_start
    and args.aux_eps_pulse_start <= step < args.aux_eps_pulse_end
)

if eps_pulse_active:
    target_eps = args.aux_eps_pulse_target
elif args.aux_eps_pulse_start > 0 and step >= args.aux_eps_pulse_end:
    target_eps = 1e-10  # canonical revert
else:
    target_eps = None  # untouched

if target_eps is not None:
    for pg in optimizer1.param_groups:
        if pg.get('eps', None) != target_eps:
            pg['eps'] = target_eps

# Sentinel at boundaries
if args.aux_eps_pulse_start > 0 and step in (
    args.aux_eps_pulse_start - 1,
    args.aux_eps_pulse_start,
    args.aux_eps_pulse_end - 1,
    args.aux_eps_pulse_end,
):
    print(
        f"[step {step}] aux Adam eps={optimizer1.param_groups[0]['eps']:.2e} "
        f"(pulse_active={eps_pulse_active})"
    )
    if wandb.run is not None:
        wandb.log({"aux_eps_pulse/eps": optimizer1.param_groups[0]['eps']}, step=step)
```

The eps update is a one-line `pg['eps'] = target_eps` per param group — PyTorch's AdamW respects this on the next step. No state reset, no buffer touching.

Log `aux_eps_pulse/eps` to W&B every step inside the window for full audit trace.

## Reproduce commands

**Arm A (eps_target=1e-6 — conservative):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_eps_pulse_start 975 --aux_eps_pulse_end 1100 --aux_eps_pulse_target 1e-6 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-tanjiro-aux-eps-pulse \
  --wandb_name g1r1-tanjiro/aux-eps-pulse-1e-6-armA
```

**Arm B (eps_target=1e-4 — aggressive):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_eps_pulse_start 975 --aux_eps_pulse_end 1100 --aux_eps_pulse_target 1e-4 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-tanjiro-aux-eps-pulse \
  --wandb_name g1r1-tanjiro/aux-eps-pulse-1e-4-armB
```

Run **Arm A first**, then chain Arm B after Arm A's `train_gpt_simple.py` process exits.

## Validation checklist

Before launching the full bilateral, run a smoke test with `--aux_eps_pulse_start 50 --aux_eps_pulse_end 80 --aux_eps_pulse_target 1e-6` and confirm:
1. Sentinel log `[step 50] aux Adam eps=1.00e-06 (pulse_active=True)` appears
2. Sentinel log `[step 80] aux Adam eps=1.00e-10 (pulse_active=False)` appears at the snap-back
3. W&B `aux_eps_pulse/eps` shows step-function 1e-10 → 1e-6 → 1e-10 across steps [49, 50, 79, 80]
4. Train_loss continues monotone (no spike at step 50 activation or step 80 revert)

If train_loss spikes >0.5 mnat at the snap-back (step 80), the abrupt eps revert is destabilizing — consider a linear ramp-down over 10 steps instead of step-back. Document this as a Plan-B variant in your PR comment but DO NOT change the implementation for the bilateral; first confirm whether the smoke result reproduces.

## Anti-patterns

- **Do NOT change `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99`** — these MUST remain at canonical #1532 baseline values. The eps pulse is layered ON TOP of the β₂ pulse, not replacing it.
- **Do NOT extend pulse beyond step 1100** — keep the window short and co-located with the v_t transient. Wide eps elevation would damp aux Adam through cooldown unnecessarily.
- **Do NOT apply eps pulse to body PMuon (optimizer2)** — body PMuon doesn't use Adam-style denominator stabilization (it uses bilateral whitening with its own L_cov+jitter). Eps pulse is aux-Adam-specific.
- **Do NOT change the eps revert value (must be 1e-10)** — canonical aux Adam eps stays at 1e-10 outside the pulse window.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate** | Conservative eps damping at β₂-pulse boundary smoothly compounds the #1532 WIN. Request seed-2 confirmation, merge if confirmed. Validates "v_t transient damping is the missing aux-side compound mechanism" hypothesis. |
| **Arm A close miss, Arm B WIN** | Stronger eps elevation needed during v_t transient. Request seed-2 of Arm B. |
| **Arm A NULL (sr=2875 close miss), Arm B NULL with sr=2925** | Eps damping helps marginally at low magnitude but breaks at higher magnitude — pulse target is between 1e-6 and 1e-4. Worth a follow-up bilateral on intermediate eps ∈ {1e-7, 1e-5}. |
| **Both NULL with sr=2925** | Eps modulation at the β₂-pulse boundary is not load-bearing. The v_t transient may be self-correcting via the bias_correction factor; eps elevation doesn't add useful smoothing. Closes the aux-eps-pulse axis cleanly. |
| **Arm B diverges** | 1e-4 is so large that it dominates the denominator even after v_t fills, making effective LR too small for cooldown progress. Focus on Arm A signal only. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
