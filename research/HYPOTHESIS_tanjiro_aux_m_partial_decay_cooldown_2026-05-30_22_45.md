# HYPOTHESIS — tanjiro — Aux Adam m-state PARTIAL DECAY at cooldown onset step 975 (×0.5 / ×0.25)

**Branch:** `g1r1-tanjiro/aux-adam-m-partial-decay-cooldown`
**Assigned:** 2026-05-30 22:45 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state resets/rescaling at phase boundaries; (d) momentum/preconditioner state handling

## Why this hypothesis

The **asymmetric m-state intervention matrix** at the cooldown onset boundary (step 975) is nearly complete. The one remaining untested cell is **partial decay** of the aux Adam first-moment buffer:

| m intervention @ step 975 | Status | Reference | Outcome |
|---|---|---|---|
| **m hard-zero** (m ← 0) | TESTED | nezuko #1815 Arm A | **HOT WIN candidate** seed-1 val_ema=3.262238 (-0.616 mnat) |
| **m partial decay ×0.5** | **UNTESTED** | This experiment Arm A | ? |
| **m partial decay ×0.25** | **UNTESTED** | This experiment Arm B | ? |
| v partial decay ×0.5 | TESTED | nezuko #1815 Arm B | NULL (+16.5 mnat) — degrades |
| m+v full zero | TESTED | nezuko #1770 | CATASTROPHIC (+v transient collapse) |

The HOT WIN at full m-zero (#1815) raises an obvious question: **is partial discard of m direction memory BETTER or WORSE than full zero?** Three plausible outcomes:

1. **Partial decay BETTER than zero (×0.5 wins big):** Hard discontinuity creates unnecessary disruption; a smooth partial reset preserves some useful direction memory while still flushing stale gradient signals. This would be a NEW WIN ROUTE and dominate #1815.
2. **Partial decay WORSE than zero (incomplete benefit):** The benefit of m-zero is COMPLETE flushing of stale cooldown-onset gradient memory. Half-flushing or quarter-flushing diminishes the benefit linearly — partial decay regresses toward NULL as scale increases.
3. **Partial decay equivalent to zero (binary signal):** The mechanism is binary (any non-zero residual contaminates; near-zero is enough) — both partial values cluster near the WIN value, confirming m-state at cooldown onset is FUNGIBLE down to a near-zero threshold.

**Each outcome is informative**, and outcome 1 would be a major win. The completeness argument compels this test: the m-state intervention matrix at step 975 should not be left with this critical cell unfilled.

## Distinct from in-flight and closed work

- **nezuko #1815** (HOT WIN candidate seed-2 in flight): aux Adam m-ZERO @ 975 (this is the WIN baseline)
- **alphonse #1879** (in flight): aux Adam m-zero @ LATE boundaries (2600 vs 2750) — different temporal axis
- **fern #1876** (in flight): body PMuon momentum HARD-ZERO @ cooldown onset — different optimizer, different intervention type (zero, not decay)
- **#1837 tanjiro** (CLOSED 22:30 UTC): aux Adam β₂ pulse PER-GROUP localization (embed-only vs lm_head-only) — bilateral NULL; different state (β₂, not m); different axis (group localization, not partial decay)
- **#1830 edward** (CLOSED): aux Adam m+v FULL zero @ late boundaries — bilateral NULL; combined m+v reset at different temporal location
- **#1770 nezuko** (CLOSED): aux Adam m+v FULL zero @ 975 — catastrophic; combined reset at this temporal location

**No prior aux Adam m-PARTIAL-DECAY at any temporal boundary.**

## Experiment design

**Bilateral magnitude test on the m-PARTIAL-DECAY paradigm at step 975 (axis: decay scale):**

- **Arm A — m ← m × 0.5 @ step 975** (light partial decay, 50% memory retained)
- **Arm B — m ← m × 0.25 @ step 975** (heavy partial decay, 25% memory retained)

Both arms preserve all canonical interventions: aux β₂ pulse 0.95→0.99 @ 975, pEMA refresh @ 2600, late-higher block LR, ema_beta=0.97. Both arms target the same temporal boundary as the #1815 HOT WIN.

## Implementation guidance

This intervention requires the **m-only partial-scale hook on aux Adam** — analogous to nezuko #1815's existing `--aux_adam_m_zero_step` implementation but with a configurable scale factor instead of hard zero. The pattern follows the existing momentum-scale hook on body PMuon (#1797 thorfinn, #1836 alphonse).

**Step 1: Add CLI flags** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--aux_adam_m_scale_step", type=int, default=0,
    help="Step at which to multiplicatively scale aux Adam first-moment buffers (exp_avg). "
         "Does NOT touch exp_avg_sq. 0 disables.",
)
parser.add_argument(
    "--aux_adam_m_scale_factor", type=float, default=1.0,
    help="Scale factor applied to exp_avg when aux_adam_m_scale_step fires. "
         "0.5 = retain 50%, 0.25 = retain 25%. 1.0 is no-op.",
)
```

**Step 2: Apply m-only partial scale in training loop** — BEFORE `optimizer1.step()`:

```python
if (args.aux_adam_m_scale_step > 0
        and step == args.aux_adam_m_scale_step
        and args.aux_adam_m_scale_factor != 1.0):
    n_scaled = 0
    scale = float(args.aux_adam_m_scale_factor)
    for group in optimizer1.param_groups:
        for p in group["params"]:
            state = optimizer1.state.get(p, None)
            if state is None:
                continue
            m = state.get("exp_avg", None)
            if m is not None:
                m.mul_(scale)
                n_scaled += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux Adam m-ONLY SCALE x{scale} (n_scaled={n_scaled}; v untouched)",
               console=True)
        if wandb.run is not None:
            wandb.log({
                "aux_adam_m_scale/step": step,
                "aux_adam_m_scale/factor": scale,
                "aux_adam_m_scale/n_scaled": n_scaled,
            }, step=step)
```

**CRITICAL:**
- Default `aux_adam_m_scale_step=0` and `aux_adam_m_scale_factor=1.0` MUST be a no-op (preserves baseline).
- Scale ONLY `exp_avg` — do NOT touch `exp_avg_sq`. The asymmetric paradigm REQUIRES leaving v untouched.
- Sentinel must report `n_scaled ≈ 101` (matches the m-tensor count from #1815/#1830).
- Do NOT modify body PMuon (optimizer2) state — only aux Adam (optimizer1).
- Do NOT combine with `--aux_adam_m_zero_step` (separate intervention; this is the partial-decay analog).

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_m_scale_step 50 --aux_adam_m_scale_factor 0.5
```

Assert:
1. Sentinel `[step 50] aux Adam m-ONLY SCALE x0.5 (n_scaled=101; v untouched)` fires.
2. Verify by sparkline of `aux_adam/m_abs_mean` (halves at fire step) vs `aux_adam/v_abs_mean` (continuous).
3. No NaN, no loss spike at the pulse step.

## Reproduce commands

**Arm A — m ← m × 0.5 @ step 975 (light partial decay):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_m_scale_step 975 --aux_adam_m_scale_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-tanjiro-aux-m-partial-decay \
  --wandb_name g1r1-tanjiro/aux-m-partial-armA-x0.5
```

**Arm B — m ← m × 0.25 @ step 975 (heavy partial decay):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_m_scale_step 975 --aux_adam_m_scale_factor 0.25 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-tanjiro-aux-m-partial-decay \
  --wandb_name g1r1-tanjiro/aux-m-partial-armB-x0.25
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT zero `exp_avg_sq` (v state)** — that's the catastrophic mode from #1770. The m-only paradigm REQUIRES v untouched.
- **Do NOT use `aux_adam_m_zero_step`** — that's the hard-zero variant (#1815 nezuko's territory). This experiment is the partial-decay analog.
- **Do NOT change the temporal boundary** — step 975 is the only WIN-bearing boundary for m-state (per #1815). Stay at 975.
- **Do NOT touch β₂ pulse, pEMA refresh, block LR pattern** — preserve all canonical interventions.
- **Do NOT touch body PMuon (optimizer2)** — separate axis (fern #1876 is testing body PMuon momentum hard-zero).

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A or B WIN (better than #1815 m-zero seed-1)** | Smooth partial reset outperforms hard discontinuity. NEW DOMINANT WIN ROUTE. Request seed-2 confirmation. May supersede #1815 as the m-state intervention of choice. |
| **Arm A or B WIN (within #1815 gate)** | Partial decay equivalent to full zero — m-state at cooldown is fungible to a near-zero threshold. Independent confirmation of the m-state benefit. Request seed-2. |
| **Both NULL, monotone (×0.25 closer to #1815 WIN than ×0.5)** | Benefit scales with completeness of reset; full zero is the sharpest variant. m-zero (#1815) is the optimal point on this axis. Closes the partial-decay cell as a strictly inferior route. |
| **Both NULL, magnitude-invariant** | Partial decay does not capture the m-zero mechanism. m-state benefit is a HARD-ZERO phenomenon. Localizes the WIN to the exact zero point. |
| **Both regress significantly** | Partial decay introduces disruption without the compensating reset benefit. m-state benefit requires either full retention OR full zero — partial is the worst region. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
