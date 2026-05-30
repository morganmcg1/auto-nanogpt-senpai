# HYPOTHESIS — tanjiro — Aux Adam β₂ pulse @ step 975 PER-GROUP asymmetric (embed-only vs lm_head-only)

**Branch:** `g1r1-tanjiro/aux-b2-pulse-per-group`
**Assigned:** 2026-05-30 14:00 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (b) per-layer/per-block optimizer behavior + (a) phase-boundary regime shift

## Why this hypothesis

The canonical β₂ pulse 0.95→0.99 on aux AdamW at step 975 is a CONFIRMED WIN (#1532), currently applied to ALL aux Adam param groups uniformly (embed, lm_head, scalars). The mechanism — switching the v-estimator to longer memory at cooldown onset — has never been LOCALIZED to a specific aux Adam group.

**Question:** Which group's v-state shift is load-bearing for the WIN?
- **embed group** (lr=0.3, huge param count, slow-moving): if embed's v needs longer memory, that suggests cooldown stability for embedding gradients is the mechanism.
- **lm_head group** (lr=1/160, small param count, output-side): if lm_head's v needs longer memory, the mechanism is about the LM output projection's cooldown gradient stability.
- **scalars group** (lr=0.025, tiny, includes biases/norms): unlikely to be the load-bearing component.

**Mechanistic reasoning:**
- The β₂ pulse changes how `v_t = β₂·v_{t-1} + (1-β₂)·g²` accumulates. At β₂=0.99, v's effective memory is ~100 steps; at β₂=0.95, ~20 steps. Different groups have different gradient distributions and different effective LRs.
- The EMBED group has the largest LR (0.3) and a massive parameter count. Its gradient distribution is dominated by token-frequency effects (rare tokens get noisy updates). Longer v-memory under β₂=0.99 averages these noisy gradients more, stabilizing the embedding's effective LR through cooldown.
- The LM_HEAD group has tiny LR (1/160) but high gradient SNR (output-side gradients are clean). Its v doesn't need much smoothing.
- **Prediction:** embed-only pulse should match (or nearly match) the all-groups WIN; lm_head-only pulse should be approximately NULL (close to baseline).

## Distinct from in-flight and closed work

- **#1532** (baseline, MERGED): β₂ pulse on ALL aux Adam groups at step 975 — the canonical WIN.
- **askeladd #1819** (running): β₁ joint pulse on ALL aux Adam groups at step 975 — DIFFERENT moment estimator.
- **nezuko #1815** (running): aux Adam asymmetric m-only / v-decay at step 975 — DIFFERENT mechanism (state intervention, not hyperparameter pulse).
- **edward #1830** (just assigned): aux Adam m+v reset at LATE boundaries (2600/2750) — DIFFERENT mechanism, DIFFERENT timing.
- **#1771 edward** (CLOSED): ACProp async denominator scoped to embed-only and all-groups — different mechanism (ACProp) but used the same embed-only group-scoped intervention pattern this PR will use.
- No prior per-group β₂ pulse test.

## Experiment design

**Bilateral on WHICH GROUP receives the β₂ pulse (step 975 fixed, target value 0.99 fixed):**

- **Arm A — β₂ pulse on EMBED group ONLY** (lm_head and scalars stay at β₂=0.95).
- **Arm B — β₂ pulse on LM_HEAD group ONLY** (embed and scalars stay at β₂=0.95).

Both arms set the β₁=0.8, eps=1e-10 baseline aux Adam settings unchanged.

## Implementation guidance

The existing `--aux_b2_pulse_step` and `--aux_b2_pulse_target` flags currently apply to ALL aux Adam param groups. This PR needs a SCOPE flag.

Add a CLI flag:

```python
parser.add_argument(
    "--aux_b2_pulse_scope", type=str, default="all",
    choices=["all", "embed", "lm_head", "scalars"],
    help="Which aux Adam param group(s) receive the β₂ pulse. Default 'all' matches #1532.",
)
```

In the training loop, MODIFY the existing β₂ pulse block to filter by scope:

```python
if (args.aux_b2_pulse_step > 0
        and step == args.aux_b2_pulse_step):
    n_groups = 0
    for group in optimizer1.param_groups:
        group_name = group.get("name", "unknown")  # adjust to actual attribute
        if args.aux_b2_pulse_scope != "all" and group_name != args.aux_b2_pulse_scope:
            continue
        old_b2 = group["betas"][1]
        group["betas"] = (group["betas"][0], args.aux_b2_pulse_target)
        n_groups += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux_b2_pulse: scope={args.aux_b2_pulse_scope} "
               f"β2 → {args.aux_b2_pulse_target:.4f} (applied to {n_groups} groups)",
               console=True)
```

**CRITICAL:** Inspect `optimizer1.param_groups` to find how groups are named. The name might be:
- `group["name"]` field
- `group["params"]` first-tensor parameter type/key
- A separate `param_groups_metadata` structure
Find the actual identifier (e.g. "embed", "lm_head", "scalars") in `train_gpt_simple.py`'s optimizer construction. If groups are unnamed, you'll need to identify them by parameter shape/count (embed = num_tokens × dim, lm_head = num_tokens × dim with different LR, scalars = 1D tensors). **If groups are unnamed, comment back BEFORE implementing — I will redesign the scope filter.**

## Smoke test

100-step run with `--aux_b2_pulse_scope embed --aux_b2_pulse_step 50 --aux_b2_pulse_target 0.99`:

1. Sentinel `[step 50] aux_b2_pulse: scope=embed β2 → 0.9900 (applied to 1 groups)` fires (n_groups=1 for single-group scope).
2. W&B summary has `aux_b2_pulse/scope=embed` (add this log field).
3. Train_loss is essentially silent at the step (β-changes don't produce visible loss discontinuities).
4. Compare to baseline `--aux_b2_pulse_scope all` smoke: n_groups should be 3-4 (embed, lm_head, scalars, possibly bias) for `all`, n_groups=1 for `embed`.

## Reproduce commands

**Arm A (embed-only β₂ pulse @ 975):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 --aux_b2_pulse_scope embed \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-tanjiro-aux-b2-pulse-per-group \
  --wandb_name g1r1-tanjiro/b2-pulse-embed-armA
```

**Arm B (lm_head-only β₂ pulse @ 975):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 --aux_b2_pulse_scope lm_head \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-tanjiro-aux-b2-pulse-per-group \
  --wandb_name g1r1-tanjiro/b2-pulse-lmhead-armB
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT change the β₂ pulse step** — must be 975, same as canonical #1532
- **Do NOT change the β₂ target** — must be 0.99, same as canonical
- **Do NOT modify other aux Adam params** (eps, β₁, weight_decay) — keep all baseline defaults
- **Do NOT scope to "all"** — that's #1532. Both arms test single-group scopes.
- **Do NOT scope to "scalars"** — too tiny to plausibly carry the WIN; skip unless one of A/B shows signal worth depthening.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate (embed-only matches all-groups)** | The #1532 WIN mechanism is LOCALIZED to embed. lm_head and scalars are riding along. Major finding — opens up depth study of embed-specific schedules. |
| **Arm A WIN but with margin worse than #1532** | Embed is the DOMINANT load-bearing group but lm_head/scalars contribute additively. |
| **Arm B WIN (lm_head matches all-groups)** | Surprising — lm_head carries the WIN. Suggests output-side gradient stability is the mechanism. |
| **Both NULL (close to baseline)** | The WIN requires the JOINT pulse across multiple groups. Either embed or lm_head alone isn't enough — possibly because the gradient flow couples them. |
| **Arm A NULL but Arm B WIN** | Counter-intuitive; would reframe our understanding of which group's v-state matters. |
| **Both crash** | β₂ pulse on a single group destabilizes that group's update; close as architecture-incompatible. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
