# HYPOTHESIS — fern — Body PMuon momentum HARD-ZERO reset at cooldown onset step 975

**Branch:** `g1r1-fern/body-momentum-zero-cooldown`
**Assigned:** 2026-05-30 21:15 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state rescaling at phase boundaries

## Why this hypothesis

Nezuko #1815 Arm A (aux Adam **m-only ZERO reset** at step 975) is a STRONG WIN candidate on seed-1 (sr=2875, val_ema=3.262238, **−0.616 mnat below gate**), currently in seed-2 confirmation. The mechanistic read: discarding aux Adam first-moment direction memory at the cooldown phase boundary is BENIGN (0 mnat transient), while v-state scaling (Arm B v×0.5) degrades (+16.5 mnat transient). **First-moment direction memory is dispensable at cooldown onset for aux Adam.**

**Open question:** Is the same true for **body PMuon momentum**? Body PMuon is governed by a different optimizer (Polar-Muon with NS5 polar projection) but has an analogous momentum buffer. The asymmetric primitive paradigm — hard-zero vs partial scaling — has been tested only as SCALE on body PMuon momentum:
- #1797 thorfinn (×0.5 and ×0.25 @ step 975): bilateral NULL, INVARIANT to attenuation magnitude
- #1730 (body Muon momentum hard-zero @ step 2750 pre-target): NULL

**The body PMuon momentum HARD-ZERO at COOLDOWN ONSET (step 975) has NEVER been tested.** This is the missing point in the body-PMuon momentum-state intervention matrix. The #1797 invariance-to-magnitude finding does NOT rule out the qualitative ZERO limit case — full discard of momentum direction is mechanistically distinct from partial attenuation (the same way nezuko #1815 Arm A m-zero is benign but Arm B v×0.5 still degrades).

**Mechanistic prior:** If body PMuon momentum behaves like aux Adam m at the cooldown boundary, then full ZERO reset should be benign (analogous to nezuko's m-only WIN candidate). If it behaves like aux Adam v, then ZERO will degrade. Either outcome is informative.

**Why this is directive-aligned and distinct:**
- Directive (a): parameter rescaling at phase boundary
- Distinct from #1797 (SCALE, not ZERO; bilateral magnitudes tested but ZERO not tested) — qualitative limit case
- Distinct from #1730 (hard-zero at pre-target step 2750, not cooldown onset)
- Distinct from nezuko #1815 (aux Adam, not body PMuon)
- Distinct from frieren #1780 (body PMuon L/R **cov**, not momentum)
- Distinct from thorfinn #1849 (body PMuon L/R cov per-side reset, currently in flight)

## Distinct from in-flight and closed work

- **nezuko #1815** (HOT WIN candidate seed-2 in flight): aux Adam m-only ZERO @ 975 — different optimizer (aux Adam), same paradigm
- **thorfinn #1849** (in flight): body PMuon L/R cov per-side ZERO @ step 1100 — different state (covariance, not momentum), different timing
- **frieren #1850** (in flight): aux Adam scalar_lr pulse — different optimizer, different axis
- **askeladd #1868** (in flight): aux Adam embed_lr pulse — different optimizer, different axis
- **#1797** (CLOSED): body PMuon momentum SCALE @ 975 — invariant to attenuation magnitude; ZERO is the qualitative limit not tested
- **#1730** (CLOSED): body PMuon momentum hard-zero @ pre-target step 2750 — different boundary
- **#1770** (CLOSED): aux Adam m+v full reset @ 975 — different optimizer (aux Adam)
- No prior body PMuon momentum hard-zero at cooldown onset.

## Experiment design

**Bilateral asymmetric test on a TEMPORAL axis (HARD-ZERO fixed):**

- **Arm A — Body PMuon momentum ZERO RESET @ step 975** (cooldown onset; canonical β₂ pulse boundary)
- **Arm B — Body PMuon momentum ZERO RESET @ step 1100** (125 steps into cooldown; same boundary as frieren #1780 Arm B cov-reset and thorfinn #1849 cov-reset)

Both arms preserve canonical interventions: β₂ pulse @ 975, pEMA refresh @ 2600, late-higher block LR, ema_beta=0.97.

## Implementation guidance

Inspect `records/track_3_optimization/train_gpt_simple.py` for `optimizer2` (body PMuon) and its `state` dict. The momentum buffer is the `momentum_buffer` key per parameter (or similar — verify by reading the optimizer's `step()` implementation).

**Note:** thorfinn #1797 implemented `--body_muon_momentum_scale_factor` for SCALE. You may extend their hook to support `--body_muon_momentum_zero_step` (a one-shot full discard), OR copy the canonical pattern from thorfinn's PR.

**Step 1: Add CLI flag**

```python
parser.add_argument(
    "--body_muon_momentum_zero_step", type=int, default=0,
    help="Step at which to hard-zero body PMuon momentum buffers (0 disables; analog of aux m-only ZERO reset in nezuko #1815)",
)
```

**Step 2: Apply zero-reset in training loop**

At the start of the training step (BEFORE optimizer2.step()), check whether to zero:

```python
if (args.body_muon_momentum_zero_step > 0
        and step == args.body_muon_momentum_zero_step):
    n_zeroed = 0
    for group in optimizer2.param_groups:
        for p in group["params"]:
            state = optimizer2.state.get(p, None)
            if state is None:
                continue
            buf = state.get("momentum_buffer", None)
            if buf is not None:
                buf.zero_()
                n_zeroed += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] body PMuon momentum HARD-ZERO reset (n_zeroed={n_zeroed})",
               console=True)
        if wandb.run is not None:
            wandb.log({
                "body_muon_momentum_zero/step": step,
                "body_muon_momentum_zero/n_zeroed": n_zeroed,
            }, step=step)
```

**CRITICAL:**
- Default `body_muon_momentum_zero_step=0` MUST be a no-op (preserves baseline).
- Verify the momentum buffer key — in the body PMuon implementation it may be `momentum_buffer`, `buf`, `momentum`, or another name. Check `train_gpt_simple.py` for the body Muon optimizer class.
- Sentinel must report n_zeroed ≈ 72 (the number of body PMuon-managed parameter tensors, matching thorfinn #1797's count).
- Do NOT modify aux Adam state — only body PMuon (optimizer2).

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_step 50
```

Assert:
1. Sentinel `[step 50] body PMuon momentum HARD-ZERO reset (n_zeroed=72)` fires.
2. Verify zero by sparkline of `body_muon/momentum_abs_mean` (e.g. `█▁?` pattern at fire step).
3. No NaN, no loss spike at the pulse step.

## Reproduce commands

**Arm A — momentum ZERO @ step 975 (cooldown onset):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_step 975 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-fern-body-momentum-zero \
  --wandb_name g1r1-fern/body-mom-zero-armA-975
```

**Arm B — momentum ZERO @ step 1100 (mid-cooldown):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_step 1100 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-fern-body-momentum-zero \
  --wandb_name g1r1-fern/body-mom-zero-armB-1100
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT scale momentum** — that's #1797's axis (closed bilateral NULL)
- **Do NOT zero on aux Adam** — that's nezuko #1815 / #1770 territory
- **Do NOT zero at pre-target (2750)** — that's #1730 territory
- **Do NOT touch L/R covariance state** — that's thorfinn #1849 / frieren #1780 territory
- **Do NOT touch β₂ pulse, pEMA refresh, block LR pattern** — preserve all canonical interventions
- **Do NOT modify aux Adam** — separate axis

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN (zero @975)** | Body PMuon momentum direction memory is dispensable at cooldown boundary, analogous to aux Adam m-only. Strong signal — request seed-2. |
| **Arm B WIN (zero @1100)** | Body PMuon momentum needs 125 cooldown-phase steps before discarding is OK. Request seed-2. |
| **Both NULL similar** | Body PMuon momentum is qualitatively different from aux Adam m at cooldown — full discard is NOT benign, despite the magnitude-invariance finding in #1797. Body PMuon momentum-zero axis CLOSED across all temporal boundaries. |
| **Both regress, asymmetric** | Boundary timing matters but neither passes gate; informative for future temporal scans. |
| **One arm diverges** | Body PMuon momentum hard-zero breaks NS5 polar projection invariants. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
