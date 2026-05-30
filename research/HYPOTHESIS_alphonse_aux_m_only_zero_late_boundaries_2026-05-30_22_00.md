# HYPOTHESIS — alphonse — Aux Adam m-only ZERO reset at LATE phase boundaries (pEMA refresh step 2600 vs pre-target step 2750)

**Branch:** `g1r1-alphonse/aux-m-zero-late-boundaries`
**Assigned:** 2026-05-30 22:00 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state resets/rescaling at phase boundaries; (c) short phase-specific mechanisms

## Why this hypothesis

The **asymmetric m vs m+v primitive paradigm** has produced one of the strongest signals in this research programme:

| Intervention | @975 (cooldown onset) | @2600 (pEMA boundary) | @2750 (pre-target) |
|---|---|---|---|
| **m + v full zero** | #1770 CATASTROPHIC (+v_t collapse +62.9 mnat transient) | #1830 NULL (+2.4 mnat) | #1830 NULL (+3.0 mnat) / #1726 NULL |
| **m-only zero** | **#1815 HOT WIN candidate (-0.616 mnat seed-1)** | **UNTESTED** | **UNTESTED** |
| **v×0.5 partial** | #1815 Arm B NULL (+16.5 mnat) | — | — |

The key mechanistic finding from #1815: **first-moment direction memory is dispensable at cooldown boundary (m-zero benign: 0 mnat transient), while v state is load-bearing (v×0.5 degrades).** The m+v full zero @2600/2750 (#1830) was BENIGN-but-disruptive (small +2-3 mnat penalties) — suggesting that at later boundaries the v-collapse transient is muted (1625+ steps of β₂=0.99 pre-fill), but the COMBINED zero still costs steps.

**Open question — is m-only ZERO benign at LATE phase boundaries (step 2600 and 2750)?**

If m-only zero is universally benign across phase boundaries, this would imply:
- First-moment direction memory in aux Adam is structurally dispensable at any clear regime transition
- Multiple m-zero pulses could compound (stacking opportunity)
- The cooldown-onset boundary is not unique to the m-only paradigm

If m-only zero is only benign at cooldown onset (#1815), this would imply:
- The cooldown phase boundary is qualitatively special for m-state direction reset
- Localizes the WIN signal more tightly

Either outcome is informative. This is the **direct temporal extension** of the m-only paradigm to the late phase boundaries.

## Distinct from in-flight and closed work

- **nezuko #1815** (HOT WIN candidate seed-2 in flight): aux Adam m-only ZERO @ step 975 — different boundary
- **#1830 edward** (CLOSED 21:15 UTC): aux Adam m+v FULL reset @ 2600 AND @ 2750 — bilateral NULL; tested COMBINED reset at these boundaries but NOT m-only alone
- **#1770 nezuko** (CLOSED): aux Adam m+v FULL reset @ step 975 — catastrophic; tested COMBINED at cooldown onset
- **#1726 nezuko** (CLOSED): L_cov/R_cov reset @ step 2750 — different state (covariance, not aux Adam m)
- **#1727 edward** (CLOSED): depth-stratified β_cov — different optimizer (body PMuon, not aux Adam)
- **#1876 fern** (in flight): body PMuon momentum HARD-ZERO @ cooldown onset — different optimizer
- **#1877 edward** (in flight): body PMuon LR step-down @ cooldown onset — different intervention type

**No prior aux Adam m-ONLY zero reset at step 2600 or step 2750.**

## Experiment design

**Bilateral temporal test on the m-ONLY zero paradigm (axis: phase boundary):**

- **Arm A — m-only ZERO RESET @ step 2600** (pEMA refresh boundary)
- **Arm B — m-only ZERO RESET @ step 2750** (pre-target boundary)

Both arms preserve all canonical interventions: aux β₂ pulse 0.95→0.99 @ 975, pEMA refresh @ 2600, late-higher block LR, ema_beta=0.97.

## Implementation guidance

This intervention requires the **m-only zero hook on aux Adam** — analogous to nezuko #1815's existing implementation but at a different step. The pattern is well-established.

**Step 1: Add CLI flag** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--aux_adam_m_zero_step", type=int, default=0,
    help="Step at which to hard-zero aux Adam first-moment buffers (exp_avg). "
         "Does NOT touch exp_avg_sq. 0 disables. Analog of nezuko #1815 Arm A.",
)
```

**Step 2: Apply m-only zero-reset in training loop** — BEFORE `optimizer1.step()`:

```python
if (args.aux_adam_m_zero_step > 0
        and step == args.aux_adam_m_zero_step):
    n_zeroed = 0
    for group in optimizer1.param_groups:
        for p in group["params"]:
            state = optimizer1.state.get(p, None)
            if state is None:
                continue
            m = state.get("exp_avg", None)
            if m is not None:
                m.zero_()
                n_zeroed += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux Adam m-ONLY ZERO reset (n_zeroed={n_zeroed}; v untouched)",
               console=True)
        if wandb.run is not None:
            wandb.log({
                "aux_adam_m_zero/step": step,
                "aux_adam_m_zero/n_zeroed": n_zeroed,
            }, step=step)
```

**CRITICAL:**
- Default `aux_adam_m_zero_step=0` MUST be a no-op (preserves baseline).
- Zero ONLY `exp_avg` — do NOT touch `exp_avg_sq`. The asymmetric paradigm REQUIRES leaving v untouched.
- Sentinel must report `n_zeroed ≈ 101` (matches #1830 m_tensors=101 count).
- Do NOT modify body PMuon (optimizer2) state — only aux Adam (optimizer1).
- If nezuko #1815 has already implemented `--aux_adam_m_zero_step`, REUSE that exact flag and code (cherry-pick from their branch). Otherwise implement fresh.

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_m_zero_step 50
```

Assert:
1. Sentinel `[step 50] aux Adam m-ONLY ZERO reset (n_zeroed=101; v untouched)` fires.
2. Verify by sparkline of `aux_adam/m_abs_mean` (drops at fire step) vs `aux_adam/v_abs_mean` (continuous).
3. No NaN, no loss spike at the pulse step.

## Reproduce commands

**Arm A — m-only ZERO @ step 2600 (pEMA refresh boundary):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_m_zero_step 2600 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse-aux-m-zero-late \
  --wandb_name g1r1-alphonse/aux-m-zero-armA-2600
```

**Arm B — m-only ZERO @ step 2750 (pre-target boundary):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_m_zero_step 2750 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse-aux-m-zero-late \
  --wandb_name g1r1-alphonse/aux-m-zero-armB-2750
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT zero `exp_avg_sq` (v state)** — that's the catastrophic mode from #1770. The m-only paradigm REQUIRES v untouched.
- **Do NOT zero at step 975** — that's nezuko #1815 territory (HOT WIN candidate in seed-2).
- **Do NOT zero m+v together** — that's #1830/#1770 territory (closed).
- **Do NOT touch body PMuon (optimizer2)** — separate axis.
- **Do NOT touch β₂ pulse, pEMA refresh, block LR pattern** — preserve all canonical interventions.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN (m-zero @2600)** | First-moment direction memory dispensable at pEMA refresh boundary; m-only paradigm temporally extensible. Strong signal — request seed-2. |
| **Arm B WIN (m-zero @2750)** | First-moment direction memory dispensable at pre-target boundary too; multiple phase boundaries respond to m-zero. Request seed-2. |
| **Both NULL similar** | m-only paradigm is uniquely beneficial at cooldown onset (step 975 only). Localizes nezuko #1815 WIN signal to the cooldown-phase-transition boundary. m-only axis @ late boundaries CLOSED. |
| **Both regress, asymmetric** | Boundary timing matters but neither passes gate; informative for understanding which phase transitions are most sensitive to m-state intervention. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
