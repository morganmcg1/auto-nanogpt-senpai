# HYPOTHESIS — alphonse — Body PMuon per-block depth-asymmetric momentum decay (μ)

**Branch:** `g1r1-alphonse/blockwise-mu-depth`
**Assigned:** 2026-05-30 05:50 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (b) per-layer/per-block optimizer behavior + (d) momentum/preconditioner state handling

## Why this hypothesis

Canonical body PMuon uses uniform μ=0.95 across all 12 blocks. The canonical late-higher LR pattern (#1289 WIN) assigns higher LR multipliers to late blocks (block 0 ×0.90 → block 11 ×1.10, ~1.65× higher LR for the deepest block). **The momentum decay μ has remained uniform despite the per-block LR asymmetry being a known load-bearing axis.**

**Mechanism hypothesis:** the effective momentum-update interaction depends on μ × lr. With uniform μ=0.95 and depth-varying LR, late blocks (high LR) experience a different effective momentum smoothing than early blocks (low LR):
- Late blocks: high LR × μ=0.95 → momentum buffer scales rapidly with each step, ~20-step memory horizon
- Early blocks: low LR × μ=0.95 → momentum buffer scales more slowly, but with same nominal memory horizon

A **depth-conditional μ** can re-tune this interaction so that the effective momentum memory is consistent in update-space across depth — or deliberately inconsistent in a load-bearing direction.

**Why not closed by prior μ work:**
- askeladd #1686 closed UNIFORM μ pulses (transient μ shifts across all blocks at pre-target)
- fern #1604 closed PERMANENT UNIFORM μ pulse (also all-blocks)
- No prior PR has tested per-block depth-asymmetric μ — this is a structurally fresh axis

**Why not closed by per-block LR axes:**
- tanjiro #1742 just closed depth-asymmetric LR burst — but LR is a magnitude lever, μ is a temporal lever
- The canonical late-higher LR pattern (#1289) IS the depth-asymmetric counterpart for LR — μ has no analog
- Adding per-block μ creates a separate orthogonal control axis

**Why directive (b)+(d) at the same time:**
- (b) per-block optimizer behavior — depth-conditional momentum decay
- (d) momentum/preconditioner state handling — modulating the temporal memory of the body Muon momentum buffer

## Experiment design

**Bilateral comparison on depth gradient direction:**

- **Arm A — μ ascending with depth** (early μ=0.90, late μ=0.99): late blocks get LONGER momentum memory (matches their high-LR regime by providing more smoothing); early blocks get shorter memory (faster response to gradient signal in their low-LR regime).
- **Arm B — μ descending with depth** (early μ=0.99, late μ=0.90): early blocks get longer memory (smoother low-LR descent); late blocks get shorter memory (faster response to gradient signal in their high-LR regime).

Both arms use a **linear ramp** between early and late values across blocks 0-11:
- Arm A: μ[i] = 0.90 + (0.99 - 0.90) × i / 11
- Arm B: μ[i] = 0.99 - (0.99 - 0.90) × i / 11

This is a falsifying bilateral: only ONE direction can be the right one. NULL on both closes the depth axis cleanly.

Both arms identical to PR #1532 baseline EXCEPT for the new per-block μ assignment.

## Implementation guidance

Add CLI flag to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--muon_block_mu_pattern", type=str, default="uniform",
    choices=["uniform", "ascending", "descending"],
    help="Per-block μ pattern: uniform (canonical 0.95) | ascending (0.90→0.99) | descending (0.99→0.90)",
)
parser.add_argument(
    "--muon_block_mu_low", type=float, default=0.90,
    help="Low-μ endpoint for ascending/descending pattern",
)
parser.add_argument(
    "--muon_block_mu_high", type=float, default=0.99,
    help="High-μ endpoint for ascending/descending pattern",
)
```

In the body PMuon optimizer setup (where param groups are constructed with per-block LR multipliers), compute per-block μ similarly:

```python
def per_block_mu(pattern, n_blocks, mu_low, mu_high, mu_canonical=0.95):
    if pattern == "uniform":
        return [mu_canonical] * n_blocks
    elif pattern == "ascending":
        return [mu_low + (mu_high - mu_low) * i / (n_blocks - 1) for i in range(n_blocks)]
    elif pattern == "descending":
        return [mu_high - (mu_high - mu_low) * i / (n_blocks - 1) for i in range(n_blocks)]
    else:
        raise ValueError(f"Unknown mu_pattern: {pattern}")

# Apply per param group
n_blocks = 12
block_mus = per_block_mu(args.muon_block_mu_pattern, n_blocks,
                          args.muon_block_mu_low, args.muon_block_mu_high)

for block_idx, mu in enumerate(block_mus):
    # set per-group μ for the block's body Muon params
    # exact mechanism depends on how body Muon param groups are organized
    group['mu'] = mu  # or however the optimizer reads per-group μ

# Sentinel print after init
if args.muon_block_mu_pattern != "uniform":
    print(f"[init] body PMuon per-block μ pattern={args.muon_block_mu_pattern}: " +
          ", ".join(f"b{i}={mu:.4f}" for i, mu in enumerate(block_mus)))
```

If body PMuon's momentum update uses a per-param-group μ, just assign it. If it uses a single global μ, you'll need to refactor the optimizer to read per-group μ — this is a small change to the body PMuon's `step()` method (replace `self.defaults['mu']` with `group['mu']`).

Log per-block μ at init to W&B summary:
```python
if wandb.run is not None:
    wandb.summary['muon_block_mu_pattern'] = args.muon_block_mu_pattern
    for i, mu in enumerate(block_mus):
        wandb.summary[f'muon_block_mu/b{i}'] = mu
```

## Reproduce commands

**Arm A (μ ascending: early=0.90 → late=0.99):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_block_mu_pattern ascending --muon_block_mu_low 0.90 --muon_block_mu_high 0.99 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse-blockwise-mu-depth \
  --wandb_name g1r1-alphonse/blockwise-mu-ascending-armA
```

**Arm B (μ descending: early=0.99 → late=0.90):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_block_mu_pattern descending --muon_block_mu_low 0.90 --muon_block_mu_high 0.99 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse-blockwise-mu-depth \
  --wandb_name g1r1-alphonse/blockwise-mu-descending-armB
```

Run **Arm A first**, then chain Arm B after Arm A's `train_gpt_simple.py` process exits.

## Validation checklist

Before launching the full bilateral, run a 100-step smoke test with `--muon_block_mu_pattern ascending` and confirm:
1. Init sentinel `[init] body PMuon per-block μ pattern=ascending: b0=0.9000, b1=0.9082, ..., b11=0.9900` appears
2. W&B summary has `muon_block_mu/b0=0.9000, ..., muon_block_mu/b11=0.9900`
3. No NaN/Inf in train_loss through step 100
4. Momentum buffer norms vary across blocks (early blocks should have smaller buffer norms due to lower μ → less accumulation; late blocks larger)

If buffer norms don't show the expected per-block variation, the optimizer is not reading per-group μ correctly — fix the refactor before proceeding.

## Anti-patterns

- **Do NOT use a linear ramp with extreme endpoints (μ < 0.85 or μ > 0.995)** — outside this range the momentum dynamics shift qualitatively and the result loses interpretability
- **Do NOT omit `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99`** — merge gate is against #1532
- **Do NOT also vary block-LR pattern** — keep `late-higher` for both arms; the depth axis being tested is μ, not LR
- **Do NOT apply per-block μ to aux Adam** — only body PMuon (optimizer2)

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate (ascending)** | Late-block longer momentum memory compounds with high-LR late-blocks → smoother high-LR descent. Request seed-2 confirmation. Validates depth-conditional μ as a separate axis from LR. |
| **Arm B WIN merge gate (descending)** | Early-block longer memory compounds with low-LR early-blocks. Different mechanism than Arm A — would suggest early-block momentum stability is the load-bearing factor. |
| **Falsifying Arm B beats Arm A** | Like edward #1727 β_cov depth-split — suggests the mechanism reversal is not load-bearing, and effective momentum tuning happens elsewhere. Closes the axis. |
| **Both NULL with sr=2925** | Per-block μ depth-asymmetric is not load-bearing. Closes this axis. Combined with the closed per-block depth-asymmetric LR (#1742) and depth-asymmetric β_cov (#1727), this would FULLY close the depth-asymmetric scalar primitive family on body PMuon. |
| **Arm A or B diverges** | μ near 0.99 too sticky for cooldown gradient regime. Focus on the non-diverging arm. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
