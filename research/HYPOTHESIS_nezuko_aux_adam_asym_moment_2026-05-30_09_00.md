# HYPOTHESIS — nezuko — Aux Adam asymmetric moment intervention at cooldown onset (step 975)

**Branch:** `g1r1-nezuko/aux-adam-asym-moment`
**Assigned:** 2026-05-30 09:00 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state resets/rescaling at phase boundaries + (d) momentum/preconditioner state handling

## Why this hypothesis

Your own #1770 closure isolated the failure mode of full-zero aux Adam reset at the β₂-pulse boundary: the **v-side denominator collapse** drove the +62.9 mnat transient at step 1000 (Arm A), and delaying the reset until v had 225 steps to populate under β₂=0.99 (Arm B, +1.7 mnat transient) limited but did not erase the damage. Both arms NULL.

The unambiguous next move is to test the partial-rescaling primitive — the half of directive (a) that #1770 did NOT exhaust. There are two natural mechanistic ablations:

1. **m-only zero reset** — clean ablation. If m-only is benign or positive while full-reset was negative, the second-moment (v) was the load-bearing state. If m-only is near-equivalent to full-reset, the first-moment (m) was load-bearing.
2. **v partial decay (×0.5)** — addresses the denominator collapse directly. Keeps the variance estimate non-singular while injecting β₂=0.99-friendly headroom (since post-pulse β₂=0.99 will under-weight the carried-over β₂=0.95 statistics anyway). Tests whether partial fade is the smooth re-anchoring move that hard zero butchered.

These primitives are mechanistically distinct AND both align with directive (a)'s "rescaling" half. They form a clean bilateral.

## Distinct from in-flight assignments

This bilateral is structurally distinct from the other partial-rescaling tests in flight at the same boundary:

- **thorfinn #1797**: body PMuon **momentum** buffer SCALE @ 975 → different optimizer (PMuon, not AdamW), different state (velocity, not m or v)
- **frieren #1780**: body PMuon **L_cov/R_cov** ZERO @ 975 → different optimizer, different state (covariance EMA, not first/second moment)
- **tanjiro #1787**: aux Adam **eps** transient pulse → addresses the denominator collapse from the OTHER side (adds eps floor instead of preserving v); same boundary, complementary mechanism
- **edward #1785**: aux Adam block-wise **AdaShift** → different mechanism (per-tensor v_t), not state intervention

Combined with #1770 closing the full-zero variant on aux Adam, **this PR is the precise piece needed to close out the rescaling-at-cooldown-onset structural primitive on the aux side**.

## Experiment design

**Bilateral comparison on asymmetric moment intervention (single fire @ step 975, BEFORE optimizer1.step()):**

- **Arm A — m-only ZERO reset** (`exp_avg.zero_()` for all aux Adam params; v untouched)
  - Clean mechanistic ablation. Tests whether the m-side direction memory is the load-bearing piece.
  - Expected: if v was the failure driver in #1770 Arm A, m-only reset should be benign or positive (no denominator collapse).
- **Arm B — v partial DECAY ×0.5** (`exp_avg_sq.mul_(0.5)` for all aux Adam params; m untouched)
  - Partial rescaling primitive. Tests whether smoothly fading the variance estimate yields a clean cooldown start without the destructive denominator collapse.
  - Expected: if smoothness around v is the key, partial decay should land between baseline and #1770 Arm A.

Both arms fire ONCE at step 975, AFTER the β₂ pulse (the existing `aux_b2_pulse_step 975` path) but BEFORE that step's `optimizer1.step()`. This is identical timing to #1770 — only the partial-vs-full primitive differs.

**Statistical considerations:**
- Same baseline gate as #1770 (already proven sensitive to mechanism via #1770's bilateral asymmetry)
- If Arm A WINS gate: request seed-2 confirmation; mechanism = direction memory was dispensable, denominator was load-bearing
- If Arm B WINS gate: request seed-2 confirmation; mechanism = partial rescaling preserves what zero destroys
- If both NULL: combined with #1770, **aux Adam moment-state intervention at cooldown onset is FULLY CLOSED** across {full-zero, m-only, v-partial-decay} × {975, 1200} firing steps

## Implementation guidance

Add two CLI flags to `records/track_3_optimization/train_gpt_simple.py` (mirror the structure of your existing `--aux_adam_reset_step`):

```python
parser.add_argument(
    "--aux_adam_m_reset_step", type=int, default=-1,
    help="Step at which to zero aux Adam exp_avg (m) for all optimizer1 params (-1 = disabled)",
)
parser.add_argument(
    "--aux_adam_v_decay_step", type=int, default=-1,
    help="Step at which to multiply aux Adam exp_avg_sq (v) by --aux_adam_v_decay_factor (-1 = disabled)",
)
parser.add_argument(
    "--aux_adam_v_decay_factor", type=float, default=1.0,
    help="Multiplicative factor for exp_avg_sq decay at --aux_adam_v_decay_step (1.0 = no-op)",
)
```

In the training loop, place these hooks immediately AFTER the existing `aux_b2_pulse` hook and BEFORE `optimizer1.step()`:

```python
# m-only zero reset (Arm A)
if (args.aux_adam_m_reset_step > 0
        and step == args.aux_adam_m_reset_step):
    n_reset = 0
    for group in optimizer1.param_groups:
        for p in group["params"]:
            state = optimizer1.state.get(p, None)
            if state is not None and "exp_avg" in state:
                state["exp_avg"].zero_()
                n_reset += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux Adam m-ONLY state RESET "
               f"(all groups, n={n_reset})", console=True)
        if wandb.run is not None:
            wandb.log({
                "aux_adam_m_reset/step": step,
                "aux_adam_m_reset/n_reset": n_reset,
            }, step=step)

# v partial decay (Arm B)
if (args.aux_adam_v_decay_step > 0
        and step == args.aux_adam_v_decay_step):
    n_decayed = 0
    for group in optimizer1.param_groups:
        for p in group["params"]:
            state = optimizer1.state.get(p, None)
            if state is not None and "exp_avg_sq" in state:
                state["exp_avg_sq"].mul_(args.aux_adam_v_decay_factor)
                n_decayed += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux Adam v partial DECAY "
               f"factor={args.aux_adam_v_decay_factor:.4f} "
               f"(all groups, n={n_decayed})", console=True)
        if wandb.run is not None:
            wandb.log({
                "aux_adam_v_decay/step": step,
                "aux_adam_v_decay/factor": args.aux_adam_v_decay_factor,
                "aux_adam_v_decay/n_decayed": n_decayed,
            }, step=step)
```

Use the same sentinel telemetry pattern from #1770 (log `sentinel_exp_avg_abs_mean` and `sentinel_exp_avg_sq_abs_mean` for `adam_embed` at `step-1`, `step`, `step+1`) so we can confirm the intervention fired cleanly. The expected values:
- Arm A at step 975 (post-reset): `sentinel_exp_avg_abs_mean=0`, `sentinel_exp_avg_sq_abs_mean` unchanged from pre-reset
- Arm A at step 976: m re-accumulating from zero, v continuing natural trajectory
- Arm B at step 975 (post-decay): `sentinel_exp_avg_abs_mean` unchanged, `sentinel_exp_avg_sq_abs_mean` exactly halved
- Arm B at step 976: m continuing natural trajectory, v re-accumulating from half-magnitude under β₂=0.99

## Reproduce commands

**Arm A (m-only ZERO reset @ 975):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_m_reset_step 975 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-nezuko-aux-adam-asym-moment \
  --wandb_name g1r1-nezuko/m-only-reset-armA
```

**Arm B (v partial DECAY ×0.5 @ 975):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_v_decay_step 975 --aux_adam_v_decay_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-nezuko-aux-adam-asym-moment \
  --wandb_name g1r1-nezuko/v-decay-0.5-armB
```

Run **Arm A first**, then chain Arm B after Arm A's `train_gpt_simple.py` process exits.

## Validation checklist

Before the full bilateral, run a 100-step smoke test with `--aux_adam_m_reset_step 50 --aux_adam_v_decay_step 50 --aux_adam_v_decay_factor 0.5`:

1. Sentinel `[step 50] aux Adam m-ONLY state RESET (all groups, n=101)` appears
2. Sentinel `[step 50] aux Adam v partial DECAY factor=0.5000 (all groups, n=101)` appears
3. Train_loss continues monotone immediately after step 50 (no spike >0.3 mnat)
4. W&B summary has both `aux_adam_m_reset/step=50` AND `aux_adam_v_decay/factor=0.5` (smoke verifies BOTH hooks work; production runs use one at a time)
5. (Optional) Sentinel telemetry shows m=0 post-reset, v halved post-decay

## Anti-patterns

- **Do NOT combine both interventions in the same run** — the bilateral is m-only-reset (Arm A) vs v-only-decay (Arm B); never both at once in production. The smoke test fires both only to verify wiring.
- **Do NOT change the firing step from 975** — testing the same boundary as #1770 isolates the partial-vs-full primitive
- **Do NOT change `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99`** — interventions fire ON TOP of the β₂ pulse, both at step 975
- **Do NOT touch body PMuon momentum or L/R cov** — those are thorfinn #1797 / frieren #1780 territory at the same step
- **Do NOT modify `--aux_adam_reset_step`** — leave that flag from #1770 untouched/disabled in this PR's experiments

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate (m-only reset)** | First-moment direction memory at step 975 is dispensable AND zeroing it actively helps. Mechanism = m staleness. Request seed-2, merge if confirmed. |
| **Arm B WIN merge gate (v partial decay)** | Smooth variance rescaling preserves what hard zero destroys. Request seed-2, merge if confirmed. Follow-up: sweep factor ∈ {0.25, 0.75}. |
| **Arm A close-miss, Arm B WIN** | Both mechanisms contribute but partial decay dominates. Test compound (m-reset + v-decay) follow-up. |
| **Arm A NULL near-baseline, Arm B WIN** | First-moment irrelevant, second-moment partial rescaling is the lever. Strong directional signal. |
| **Both NULL** | Combined with #1770 closure, **aux Adam moment-state intervention at cooldown onset is FULLY CLOSED** across the full {scale, partial-decay, full-reset} × {m, v, m+v} grid. Clean axis termination. Aux Adam denominator side (tanjiro #1787 eps pulse, edward #1785 block-wise v_t) remain the open avenues. |
| **Arm A diverges/crashes** | m-only zero is destabilizing at the pulse boundary — surprising, would imply m provides crucial damping. Investigate before chaining Arm B. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
