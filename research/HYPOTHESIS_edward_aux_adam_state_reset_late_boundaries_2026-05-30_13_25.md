# HYPOTHESIS — edward — Aux Adam m+v full state reset at LATE phase boundaries (2600 vs 2750)

**Branch:** `g1r1-edward/aux-adam-state-reset-late`
**Assigned:** 2026-05-30 13:25 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state reset at phase boundaries + (c) short phase-specific mechanism

## Why this hypothesis

nezuko #1770 closed aux Adam m+v full-zero reset at **step 975** (cooldown onset, simultaneous with β₂ pulse) — bilateral NULL with the specific failure mode of v-denominator collapse (+62.9 mnat transient as β₂=0.99 slowly refilled v). That's a **boundary-specific failure**, not a fundamental indictment of aux Adam state reset.

This PR tests the SAME mechanism (full m+v zero reset) at the TWO LATE phase boundaries that have not been touched on aux Adam:

1. **Step 2600 — paramEMA refresh boundary.** Canonical pEMA refresh fires here (#1429 WIN). The aux Adam β₂=0.99 (post-#1532 pulse) has integrated 1625 steps of cooldown gradient statistics. v has rich, regime-appropriate statistics. Resetting m+v here discards a lot of information — but it also synchronizes the optimizer with the freshly-refreshed paramEMA snapshot.

2. **Step 2750 — pre-target boundary.** nezuko #1726 demonstrated cov-state reset at exactly this step was a CLOSE MISS (sr=2875, +1.07 mnat above gate) on body PMuon. The pre-target window appears structurally responsive to RESET interventions. The natural follow-up is: does aux Adam state share this responsiveness, or is the close-miss a body-PMuon-specific signature?

**Mechanistic reasoning:**
- Unlike step 975, both these boundaries are **post-β₂-pulse-integration**: v has already accumulated cooldown statistics under β₂=0.99 for hundreds-to-thousands of steps. No simultaneous v-collapse-vs-pulse-refill conflict like nezuko #1770.
- At step 2600, the m/v carry information from EARLY cooldown (steps 975-2600 spans the regime where LR was decaying linearly from warmup peak). At step 2750, m/v carry late-cooldown info plus paramEMA-refresh-aware gradients (steps 2600-2750).
- A reset at 2600 says "the optimizer should start fresh in concert with the paramEMA refresh — both the model snapshot AND the optimizer state get a clean slate at the same moment."
- A reset at 2750 says "the optimizer state should clear immediately before the target-crossing window — let the final 500 steps run on freshly-bootstrapped m/v stats from purely late-cooldown gradients."

**Why distinct from in-flight/closed work:**
- **nezuko #1770** (CLOSED): aux Adam m+v reset @ step 975 — DIFFERENT boundary (early cooldown w/ concurrent β₂ pulse)
- **nezuko #1815** (in-flight): aux Adam asymmetric m-only zero vs v-partial-decay @ step 975 — DIFFERENT boundary AND different mechanism (partial)
- **askeladd #1819** (in-flight): aux Adam β₁ joint pulse @ 975 — DIFFERENT boundary AND different mechanism (β change vs state reset)
- **nezuko #1726** (CLOSED): cov-state reset @ 2750 — DIFFERENT optimizer (body PMuon, not aux Adam) — but close-miss timing pattern motivates this PR
- **frieren #1780** (HOT, seed-2 pending): cov-state reset @ 1100 — DIFFERENT optimizer AND different timing
- No prior aux Adam state reset at 2600 OR 2750.

## Experiment design

**Bilateral on TIMING (mechanism fixed at aux Adam m+v full-zero reset):**

- **Arm A — m+v reset @ step 2600 (pEMA refresh boundary)**. Tests if pEMA refresh + aux optimizer state reset jointly form a cleaner phase transition.
- **Arm B — m+v reset @ step 2750 (pre-target boundary)**. Tests if the cov-state close-miss timing pattern (nezuko #1726 was sr=2875 +1.07 mnat above gate) transfers from body PMuon to aux Adam.

Both arms preserve the canonical β₂ pulse @ 975 (do NOT touch).

## Implementation guidance

Add CLI flags to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--aux_adam_mv_reset_step", type=int, default=-1,
    help="Step at which to zero-reset aux Adam m+v state (-1 = disabled)",
)
```

In the training loop, AFTER the existing `aux_b2_pulse` block and BEFORE `optimizer1.step()` (same insertion point as nezuko #1770/#1815):

```python
if (args.aux_adam_mv_reset_step > 0
        and step == args.aux_adam_mv_reset_step):
    n_m, n_v = 0, 0
    for group in optimizer1.param_groups:
        for p in group["params"]:
            state = optimizer1.state.get(p, None)
            if state is None:
                continue
            if "exp_avg" in state:
                state["exp_avg"].zero_()
                n_m += 1
            if "exp_avg_sq" in state:
                state["exp_avg_sq"].zero_()
                n_v += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux Adam m+v ZERO RESET "
               f"(m_tensors={n_m}, v_tensors={n_v})", console=True)
        if wandb.run is not None:
            wandb.log({
                "aux_adam_mv_reset/step": step,
                "aux_adam_mv_reset/m_tensors": n_m,
                "aux_adam_mv_reset/v_tensors": n_v,
            }, step=step)
```

This is the **identical reset path** nezuko #1770 used — only the firing step differs. No other state modification.

## Reproduce commands

**Arm A (m+v reset @ step 2600):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_mv_reset_step 2600 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-edward-aux-adam-state-reset-late \
  --wandb_name g1r1-edward/aux-mv-reset-2600-armA
```

**Arm B (m+v reset @ step 2750):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_mv_reset_step 2750 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-edward-aux-adam-state-reset-late \
  --wandb_name g1r1-edward/aux-mv-reset-2750-armB
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Validation checklist

Smoke test with `--aux_adam_mv_reset_step 50` over 100 steps:

1. Sentinel `[step 50] aux Adam m+v ZERO RESET (m_tensors=N, v_tensors=N)` fires once (N matches optimizer1 param tensor count).
2. Verify N values match what nezuko #1770's identical reset code produced (sanity check that the reset code path is structurally equivalent).
3. Train_loss may spike at the smoke-test step (m/v reset with active LR triggers a one-step direction change); should recover within 5-10 steps. **At step 2600/2750 with cooldown LR, transient should be much smaller.**

## Anti-patterns

- **Do NOT modify the β₂ pulse** — preserve `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99` in BOTH arms.
- **Do NOT change body PMuon code or flags** — this is aux-AdamW state intervention only.
- **Do NOT use partial reset (m-only or v-partial)** — those are nezuko #1815's territory at a different step.
- **Do NOT pulse β₁ alongside reset** — askeladd #1819 owns β₁ pulse at 975. Keep this PR a CLEAN state-reset isolation test at late boundaries.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate (reset@2600)** | pEMA refresh + aux-state reset jointly form a phase transition. Request seed-2; follow-up: variant with cov-reset at same step. |
| **Arm B WIN merge gate (reset@2750)** | Pre-target reset close-miss (nezuko #1726) transfers to aux side. Request seed-2; opens up "combined aux + body state reset @ 2750" follow-up. |
| **Both NULL similar trajectories** | Aux Adam state at late cooldown is structurally load-bearing; full discard is too aggressive regardless of phase. Combined with #1770, **aux Adam FULL m+v reset CLOSED across all 3 main phase boundaries (975, 2600, 2750)**. |
| **Both close-miss (sr=2875, val_ema +1-3 mnat above gate)** | The reset mechanism produces consistent close-miss but never quite breaks through. Frame as candidate for "reset with smaller phase-correction" follow-up. |
| **Either arm crashes/diverges** | Late-cooldown m/v statistics are too critical to discard; expect this is more likely for Arm B (2750) than Arm A (2600). |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```

Post a brief milestone comment when Arm A passes step ~2600 (so we can confirm the reset fired) and at ~50%/80% of Arm B.
