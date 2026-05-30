# HYPOTHESIS — frieren — Aux Adam SCALAR_LR pulse @ cooldown onset step 975

**Branch:** `g1r1-frieren/scalar-lr-pulse-cooldown`
**Assigned:** 2026-05-30 16:15 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state rescaling at phase boundaries + (b) per-layer/per-block (per-GROUP) optimizer behavior

## Why this hypothesis

The aux Adam optimizer has three named param groups: `adam_embed` (lr=0.3), `adam_lm_head` (lr=1/160), and `adam_scalars` (lr=0.025). The β₂ pulse @ step 975 (#1532 WIN) applies uniformly to ALL three. Per-group β₂ localization is in flight (tanjiro #1837: embed-only vs lm_head-only). **Per-group LR perturbation at the same boundary is the untested orthogonal axis.**

The `adam_scalars` group (RMSNorm gains and biases — 1D ndim params) is the smallest and most under-explored group. The current scalar_lr=0.025 was established at PR #413 as the GLOBAL optimum in stable-phase tuning, but no phase-boundary perturbation has tested whether the scalar group benefits from a DIFFERENT LR under cooldown.

**Mechanistic prior:** RMSNorm gains and biases stabilize the activation distribution layer-by-layer. Their dynamics at cooldown onset (step 975, where body LR begins decaying and aux β₂ jumps 0.95→0.99) may need DIFFERENT scaling than during the stable phase:
- **Boost (×2, lr=0.050):** Compensates for body LR decay by allowing normalization parameters to adapt FASTER while body adapts SLOWER. Lets RMSNorm "catch up" to a shifting activation distribution as the body model updates compress.
- **Decay (×0.5, lr=0.0125):** Stabilizes normalization parameters EARLIER so the body model can fine-tune against a fixed normalization basis through cooldown.

These are opposite directional predictions — the bilateral test falsifies one direction definitively.

**Why this is directive-aligned and distinct:**
- Directive (a): parameter rescaling at phase boundary (LR is a parameter)
- Directive (b): per-group (per-layer-class) optimizer behavior
- Distinct from tanjiro #1837 (β₂ pulse on embed/lm_head — different axis, different groups)
- Distinct from all CLOSED scalar_lr work: #413 established scalar_lr=0.025 in STABLE-phase tuning; no phase-boundary perturbation tested
- Distinct from CLOSED body Muon LR pulse (#1637 LR-UP, #1697 LR-DOWN): different optimizer (aux Adam), different group (scalars only)

## Distinct from in-flight and closed work

- **tanjiro #1837** (in flight): β₂ pulse per-group (embed-only / lm_head-only) — different axis, different groups
- **edward #1830** (in flight): aux Adam m+v full reset at late boundaries (2600/2750) — different mechanism, different boundary, different state
- **askeladd #1819** (in flight): aux Adam β₁ joint pulse @ 975 — different parameter axis
- **#1532** (CURRENT BASELINE): aux Adam β₂ pulse all-groups @ 975 — different axis
- **#413** (MERGED): established scalar_lr=0.025 in stable-phase tuning — no phase-boundary perturbation
- **#1637/#1697** (CLOSED): body Muon LR pulse — different optimizer, different scope
- No prior aux Adam scalar_lr phase-boundary intervention.

## Experiment design

**Bilateral asymmetric direction test (step 975 fixed):**

- **Arm A — scalar_lr BOOST** (×2: 0.025 → 0.050) at step 975, held to terminal
- **Arm B — scalar_lr DECAY** (×0.5: 0.025 → 0.0125) at step 975, held to terminal

Both arms preserve canonical interventions: β₂ pulse @ 975, pEMA refresh @ 2600, late-higher block LR, ema_beta=0.97.

## Implementation guidance

Inspect `records/track_3_optimization/train_gpt_simple.py` for the `optimizer1` (aux AdamW) param_groups setup, around L800 where `adam_scalars` group is defined.

**Step 1: Add CLI flags**

```python
parser.add_argument(
    "--aux_scalar_lr_pulse_step", type=int, default=0,
    help="Step at which to apply scalar_lr pulse (0 disables)",
)
parser.add_argument(
    "--aux_scalar_lr_pulse_factor", type=float, default=1.0,
    help="Multiplicative factor applied to scalar_lr at pulse step (e.g. 2.0 doubles, 0.5 halves)",
)
```

**Step 2: Apply pulse in training loop**

At the start of each training step (BEFORE optimizer1.step()), check whether to apply the pulse. The pulse is a one-shot multiplicative change to the `adam_scalars` group's `lr` attribute, held to terminal:

```python
if (args.aux_scalar_lr_pulse_step > 0
        and step == args.aux_scalar_lr_pulse_step
        and args.aux_scalar_lr_pulse_factor != 1.0):
    n_applied = 0
    base_lr_before = None
    for group in optimizer1.param_groups:
        name = group.get("name", "")
        short_name = name.removeprefix("adam_")
        if short_name == "scalars":
            base_lr_before = group["lr"]
            group["lr"] = group["lr"] * args.aux_scalar_lr_pulse_factor
            n_applied += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux scalar_lr pulse: {base_lr_before:.6f} -> "
               f"{base_lr_before * args.aux_scalar_lr_pulse_factor:.6f} "
               f"(factor={args.aux_scalar_lr_pulse_factor}, applied to {n_applied} groups)",
               console=True)
        if wandb.run is not None:
            wandb.log({
                "aux_scalar_lr_pulse/factor": args.aux_scalar_lr_pulse_factor,
                "aux_scalar_lr_pulse/lr_before": base_lr_before,
                "aux_scalar_lr_pulse/lr_after": base_lr_before * args.aux_scalar_lr_pulse_factor,
                "aux_scalar_lr_pulse/n_applied": n_applied,
            }, step=step)
```

**CRITICAL:**
- Default `aux_scalar_lr_pulse_factor=1.0` MUST be a no-op (preserves baseline behavior).
- The pulse modifies ONLY the `adam_scalars` group; verify `adam_embed` and `adam_lm_head` groups are UNTOUCHED.
- If the training loop has any scheduler that overrides `group["lr"]` per step (LR cooldown), apply the pulse AFTER the scheduler so the multiplicative factor stacks correctly. If the scheduler stores a base_lr that's multiplied each step, you may need to modify base_lr instead of current lr. Check the schedule code path.
- Sentinel must report 1 group affected (only `adam_scalars`).

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_scalar_lr_pulse_step 50 --aux_scalar_lr_pulse_factor 2.0
```

Assert:
1. Sentinel `[step 50] aux scalar_lr pulse: 0.025000 -> 0.050000 (factor=2.0, applied to 1 groups)` fires.
2. `aux_scalar_lr_pulse/n_applied=1` (only scalars group).
3. The `adam_embed` and `adam_lm_head` lr values are UNCHANGED at step 51 (verify by printing all 3 group lrs).
4. No NaN, no loss spike at the pulse step.

## Reproduce commands

**Arm A — scalar_lr BOOST ×2 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_scalar_lr_pulse_step 975 --aux_scalar_lr_pulse_factor 2.0 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-frieren-scalar-lr-pulse \
  --wandb_name g1r1-frieren/scalar-lr-boost-2x-armA
```

**Arm B — scalar_lr DECAY ×0.5 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_scalar_lr_pulse_step 975 --aux_scalar_lr_pulse_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-frieren-scalar-lr-pulse \
  --wandb_name g1r1-frieren/scalar-lr-decay-0p5x-armB
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT pulse all groups** — that's a generic aux LR scale, not the per-group axis under test
- **Do NOT modify `adam_embed` or `adam_lm_head` LR** — those are tanjiro #1837 / future hypothesis territory
- **Do NOT change pulse step from 975** — canonical cooldown onset; co-locates with #1532 β₂ pulse
- **Do NOT touch β₂ pulse, pEMA refresh, block LR pattern** — preserve all canonical interventions
- **Do NOT modify body PMuon** — separate axis (frieren #1780 just closed)

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN (×2 boost)** | Faster RMSNorm adaptation during cooldown is load-bearing. Request seed-2. Follow-up: scan factors {1.5, 3.0, 4.0}. |
| **Arm B WIN (×0.5 decay)** | Stable RMSNorm basis during cooldown is load-bearing. Request seed-2. Follow-up: scan factors {0.25, 0.75, 0.0 (freeze)}. |
| **Both NULL similar** | scalar_lr is amplitude-invariant at this boundary; per-group scalar LR axis CLOSED. |
| **Both regress, asymmetric magnitude** | scalar_lr is locally pinned at #413 optimum; cooldown does NOT shift the local optimum. |
| **One arm diverges** | scalar_lr at that magnitude breaks normalization dynamics; expected if ×2 boost causes RMSNorm gain explosion or ×0.5 decay causes accumulated lag. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
