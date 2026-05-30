# HYPOTHESIS — askeladd — Aux Adam EMBED_LR pulse @ cooldown onset step 975

**Branch:** `g1r1-askeladd/embed-lr-pulse-cooldown`
**Assigned:** 2026-05-30 20:00 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state rescaling at phase boundaries + (b) per-layer/per-block (per-GROUP) optimizer behavior

## Why this hypothesis

The aux Adam optimizer has three named param groups: `adam_embed` (lr=0.3), `adam_lm_head` (lr=1/160), and `adam_scalars` (lr=0.025). The β₂ pulse @ step 975 (#1532 WIN) applies uniformly to ALL three. Per-group β₂ localization is in flight (tanjiro #1837: embed-only vs lm_head-only). Per-group **scalar_lr** pulse is in flight (frieren #1850).

**The largest aux group — `adam_embed` (lr=0.3) — has NEVER been tested with a per-group LR perturbation at the cooldown phase boundary.**

The `adam_embed` group governs the input token embeddings, the largest single block of aux-Adam-managed parameters (vocab × hidden). Its dynamics at cooldown onset (step 975, where body LR begins decaying and aux β₂ jumps 0.95→0.99) are systemically influential:

- **Boost (×2, lr=0.6):** Allow token embeddings to adapt FASTER while body adapts SLOWER. The embedding layer effectively becomes the "fast feature extractor" during cooldown, letting the body transformer fine-tune against a richer input representation. Matches the pattern in distillation where embedding-layer LR is held higher during the converging phase.
- **Decay (×0.5, lr=0.15):** Stabilize token embeddings EARLIER so the body model can fine-tune against a fixed input representation through cooldown. Matches the pattern in NLP pretraining where embedding LR is dropped earlier than body LR for stability.

These are opposite directional predictions — the bilateral test falsifies one direction definitively.

**Why this is directive-aligned and distinct:**
- Directive (a): parameter rescaling at phase boundary (LR is a parameter)
- Directive (b): per-group (per-layer-class) optimizer behavior
- Distinct from frieren #1850 (scalar_lr ×2 / ×0.5 — different GROUP, smallest 1D RMSNorm params)
- Distinct from tanjiro #1837 (β₂ pulse on embed/lm_head — different AXIS: β₂ momentum not LR)
- Distinct from all CLOSED embed_lr work: #413-era sweeps established lr=0.3 globally in STABLE-phase tuning; no phase-boundary perturbation tested
- Distinct from body Muon LR pulse closures (#1637 LR-UP, #1697 LR-DOWN): different optimizer (aux Adam), different group (embed)

## Distinct from in-flight and closed work

- **frieren #1850** (in flight): aux Adam scalar_lr pulse — same axis (per-group LR), DIFFERENT group (`adam_scalars`, the 1D params). Together with this PR forms a 2-of-3 sweep over per-group LR at cooldown; lm_head-only would be the third.
- **tanjiro #1837** (in flight): aux Adam β₂ pulse per-group (embed-only / lm_head-only) — DIFFERENT axis (β₂ not LR), overlapping groups but orthogonal mechanism.
- **edward #1830** (in flight): aux Adam m+v full reset at late boundaries (2600/2750) — different state, different boundary.
- **nezuko #1815 Arm A** (HOT WIN candidate, awaiting seed-2): aux Adam m-only ZERO reset @975 — sets the precedent that aux-Adam state interventions at cooldown ARE viable. Per-group LR pulse is the matched per-group cousin on a different state axis (LR vs m).
- **#1532** (BASELINE): aux Adam β₂ pulse all-groups @ 975 — different axis.
- **#1592 / #1639** (CLOSED): aux Adam β₁ pulse — different parameter, both directions tested.
- No prior aux Adam per-group LR phase-boundary intervention.

## Experiment design

**Bilateral asymmetric direction test (step 975 fixed):**

- **Arm A — embed_lr BOOST** (×2: 0.3 → 0.6) at step 975, held to terminal
- **Arm B — embed_lr DECAY** (×0.5: 0.3 → 0.15) at step 975, held to terminal

Both arms preserve canonical interventions: β₂ pulse @ 975, pEMA refresh @ 2600, late-higher block LR, ema_beta=0.97.

## Implementation guidance

Inspect `records/track_3_optimization/train_gpt_simple.py` for `optimizer1` (aux AdamW) param_groups setup. The `adam_embed` group is defined alongside `adam_lm_head` and `adam_scalars`.

**CRITICAL — LR-schedule interaction:** The cosine LR schedule recomputes `group["lr"] = group["initial_lr"] * eta` every step (see frieren #1850 implementation comment for confirmation). Therefore the pulse MUST modify `group["initial_lr"]`, not `group["lr"]`. Modifying only `lr` will be erased at step 976.

**Step 1: Add CLI flags**

```python
parser.add_argument(
    "--aux_embed_lr_pulse_step", type=int, default=0,
    help="Step at which to apply embed_lr pulse (0 disables)",
)
parser.add_argument(
    "--aux_embed_lr_pulse_factor", type=float, default=1.0,
    help="Multiplicative factor applied to embed_lr at pulse step (e.g. 2.0 doubles, 0.5 halves)",
)
```

**Step 2: Apply pulse in training loop**

At the start of each training step (BEFORE `set_hparams` / before `optimizer1.step()`), check whether to apply the pulse. The pulse is a one-shot multiplicative change to the `adam_embed` group's `initial_lr` attribute, held to terminal:

```python
if (args.aux_embed_lr_pulse_step > 0
        and step == args.aux_embed_lr_pulse_step
        and args.aux_embed_lr_pulse_factor != 1.0):
    n_applied = 0
    base_lr_before = None
    for group in optimizer1.param_groups:
        name = group.get("name", "")
        short_name = name.removeprefix("adam_")
        if short_name == "embed":
            base_lr_before = group["initial_lr"]
            group["initial_lr"] = group["initial_lr"] * args.aux_embed_lr_pulse_factor
            # Also update current lr to take effect immediately this step
            group["lr"] = group["lr"] * args.aux_embed_lr_pulse_factor
            n_applied += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux embed_lr pulse: initial_lr {base_lr_before:.6f} -> "
               f"{base_lr_before * args.aux_embed_lr_pulse_factor:.6f} "
               f"(factor={args.aux_embed_lr_pulse_factor}, applied to {n_applied} groups)",
               console=True)
        if wandb.run is not None:
            wandb.log({
                "aux_embed_lr_pulse/factor": args.aux_embed_lr_pulse_factor,
                "aux_embed_lr_pulse/initial_lr_before": base_lr_before,
                "aux_embed_lr_pulse/initial_lr_after": base_lr_before * args.aux_embed_lr_pulse_factor,
                "aux_embed_lr_pulse/n_applied": n_applied,
            }, step=step)
```

**CRITICAL:**
- Default `aux_embed_lr_pulse_factor=1.0` MUST be a no-op (preserves baseline behavior).
- The pulse modifies ONLY the `adam_embed` group; verify `adam_lm_head` and `adam_scalars` groups are UNTOUCHED.
- Modify BOTH `initial_lr` (so cosine schedule scaling at step 976+ uses the new base) AND current `lr` (so the pulse takes effect this step before optimizer.step()).
- Sentinel must report 1 group affected (only `adam_embed`).

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_embed_lr_pulse_step 50 --aux_embed_lr_pulse_factor 2.0
```

Assert:
1. Sentinel `[step 50] aux embed_lr pulse: initial_lr 0.300000 -> 0.600000 (factor=2.0, applied to 1 groups)` fires.
2. `aux_embed_lr_pulse/n_applied=1` (only embed group).
3. The `adam_lm_head` and `adam_scalars` lr values are UNCHANGED at step 51 (verify by printing all 3 group lrs at step 49, 50, 51).
4. Verify cosine schedule scaling at step 100 uses 0.6 as base (not 0.3) — print `group["lr"]` and confirm it's roughly 0.6 × eta(step 100).
5. No NaN, no loss spike at the pulse step.

## Reproduce commands

**Arm A — embed_lr BOOST ×2 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_embed_lr_pulse_step 975 --aux_embed_lr_pulse_factor 2.0 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-askeladd-embed-lr-pulse \
  --wandb_name g1r1-askeladd/embed-lr-boost-2x-armA
```

**Arm B — embed_lr DECAY ×0.5 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_embed_lr_pulse_step 975 --aux_embed_lr_pulse_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-askeladd-embed-lr-pulse \
  --wandb_name g1r1-askeladd/embed-lr-decay-0p5x-armB
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT pulse all groups** — that's a generic aux LR scale, not the per-group axis under test
- **Do NOT modify `adam_lm_head` or `adam_scalars` LR** — those are tanjiro #1837 / frieren #1850 territory
- **Do NOT change pulse step from 975** — canonical cooldown onset; co-locates with #1532 β₂ pulse
- **Do NOT touch β₂ pulse, pEMA refresh, block LR pattern** — preserve all canonical interventions
- **Do NOT modify body PMuon** — separate axis (frieren #1780 just closed)
- **Do NOT forget to scale `initial_lr`** — modifying only `lr` will be erased at step 976 by the cosine schedule

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN (×2 boost)** | Faster embedding adaptation during cooldown is load-bearing. Request seed-2. Follow-up: scan factors {1.5, 3.0, 4.0}. |
| **Arm B WIN (×0.5 decay)** | Stable embedding basis during cooldown is load-bearing. Request seed-2. Follow-up: scan factors {0.25, 0.75, 0.0 (freeze)}. |
| **Both NULL similar** | embed_lr is amplitude-invariant at this boundary; per-group embed LR axis CLOSED. |
| **Both regress, asymmetric magnitude** | embed_lr is locally pinned at 0.3 optimum; cooldown does NOT shift the local optimum. |
| **One arm diverges** | embed_lr at that magnitude breaks embedding dynamics; expected if ×2 boost causes embedding gradient explosion. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
