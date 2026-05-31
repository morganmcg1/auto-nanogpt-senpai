# HYPOTHESIS — edward — Body PMuon momentum HARD-ZERO BLOCKWISE @ step 975 (deep-only vs shallow-only)

**Branch:** `g1r1-edward/body-momentum-zero-blockwise`
**Assigned:** 2026-05-31 05:30 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (b) per-layer/per-block optimizer behavior; (d) momentum/preconditioner state handling changes; (a) optimizer-state resets at phase boundaries

## Why this hypothesis

**Closed:** body PMuon momentum GLOBAL reset (across ALL blocks) is INVARIANT:
- #1797 (×0.5 / ×0.25 @975): bilateral NULL
- #1876 (zero @975 / @1100): bilateral NULL (just closed at 05:30)
- #1836 (zero @2750): NULL

But all of those applied the perturbation **uniformly across all 12 blocks**. The canonical `muon_block_lr_pattern=late-higher` makes deep blocks effectively higher-LR than shallow blocks throughout training, so the relative stale-state burden of momentum is NOT uniform across depth. Mechanistic reasoning:

- **Deep blocks** receive larger effective updates per step → momentum_buffer accumulates more stable-phase direction-memory.
- At cooldown onset, deep blocks need to adapt to the rapidly-decaying LR; their stale momentum is **most** misaligned with the new regime.
- **Shallow blocks** have smaller effective updates and accumulate less stale momentum → resetting them may discard useful early-layer features.

**Open question:** Does block-localized momentum reset (deep blocks only) capture a benefit that global reset destroys?

If WIN on deep-only: the cooldown momentum-staleness is depth-localized; global reset failed because shallow blocks paid the cost.
If WIN on shallow-only: opposite localization — shallow blocks needed the reset; global was right idea but contaminated by deep.
If both NULL: confirms the global #1797/#1876 conclusion — body momentum truly invariant to reset at this boundary regardless of localization. Closes depth-stratification axis on body momentum.

## Experiment design

**Bilateral block-bucket test (axis: localization on depth):**

- **Arm A — momentum ZERO in DEEP blocks only @ step 975:** Zero `momentum_buffer` for params in the last 4 of 12 body PMuon blocks (deep half-ish).
- **Arm B — momentum ZERO in SHALLOW blocks only @ step 975:** Zero `momentum_buffer` for params in the first 4 of 12 body PMuon blocks (shallow half-ish).

Both arms preserve all canonical interventions: aux β₂ pulse 0.95→0.99 @975, pEMA refresh @2600, late-higher block LR, ema_beta=0.97. The DEEP vs SHALLOW partition is hard-coded by block index — read the param groups in `optimizer2.param_groups` and partition by the `block_idx` (or equivalent) attribute already used by `muon_block_lr_pattern=late-higher`.

## Distinct from in-flight and closed work

- **#1797 closed**: GLOBAL body momentum scale @975 — bilateral NULL (×0.5, ×0.25)
- **#1876 closed**: GLOBAL body momentum hard-zero @975 / @1100 — bilateral NULL
- **#1836 closed**: GLOBAL body momentum zero @2750 — NULL
- **No prior block-stratified body PMuon momentum reset at ANY temporal boundary.** Cleanly novel.

## Implementation guidance

**Step 1: Read the existing block structure.** Open `records/track_3_optimization/train_gpt_simple.py` and find where `optimizer2.param_groups` are constructed and where `muon_block_lr_pattern=late-higher` is applied — there must already be a way to associate each param group with a block index (typically `group["block_idx"]` or similar). USE THE EXISTING MECHANISM. Do not re-invent block partitioning.

**Step 2: Add CLI flags:**

```python
parser.add_argument(
    "--body_muon_momentum_zero_blockwise_step", type=int, default=0,
    help="Step at which to zero body PMuon momentum_buffer for a subset of blocks (0 disables)",
)
parser.add_argument(
    "--body_muon_momentum_zero_blockwise_subset",
    type=str, default="none",
    choices=["none", "deep", "shallow"],
    help="Which block subset to zero: 'deep' = last 4 of 12, 'shallow' = first 4 of 12",
)
```

**Step 3: Apply blockwise zero** — BEFORE `optimizer2.step()`:

```python
if (args.body_muon_momentum_zero_blockwise_step > 0
        and step == args.body_muon_momentum_zero_blockwise_step
        and args.body_muon_momentum_zero_blockwise_subset != "none"):
    # Discover block-index range from optimizer2.param_groups
    block_indices = sorted({
        g["block_idx"]  # or whichever attribute the existing late-higher code uses
        for g in optimizer2.param_groups
        if "block_idx" in g
    })
    n_blocks = len(block_indices)
    if args.body_muon_momentum_zero_blockwise_subset == "deep":
        target_blocks = set(block_indices[-4:])     # last 4
    elif args.body_muon_momentum_zero_blockwise_subset == "shallow":
        target_blocks = set(block_indices[:4])      # first 4
    else:
        target_blocks = set()

    n_zeroed = 0
    for group in optimizer2.param_groups:
        if group.get("block_idx") not in target_blocks:
            continue
        for p in group["params"]:
            state = optimizer2.state.get(p, None)
            if state is None:
                continue
            buf = state.get("momentum_buffer", None)
            if buf is not None:
                buf.zero_()
                n_zeroed += 1
    if dist.get_rank() == 0:
        print0(
            f"[step {step}] body PMuon momentum HARD-ZERO blockwise "
            f"(subset={args.body_muon_momentum_zero_blockwise_subset}, "
            f"target_blocks={sorted(target_blocks)}, n_zeroed={n_zeroed}) "
            f"out of n_blocks={n_blocks}",
            console=True,
        )
        if wandb.run is not None:
            wandb.log({
                "body_muon_momentum_zero_blockwise/step": step,
                "body_muon_momentum_zero_blockwise/n_zeroed": n_zeroed,
                "body_muon_momentum_zero_blockwise/n_target_blocks": len(target_blocks),
            }, step=step)
```

**CRITICAL:**
- `default=0` and `subset="none"` MUST be a no-op (preserves baseline).
- **Read the actual block-indexing attribute name** from the existing `muon_block_lr_pattern=late-higher` code path before implementing — `block_idx` is a placeholder; use the real name.
- If `block_idx` doesn't exist as a distinct attribute and is instead derived from group ordering, partition by group index sorted by depth.
- Apply to optimizer2 (body PMuon) ONLY — do NOT touch optimizer1.
- Apply BEFORE `optimizer2.step()` so the very next update uses zeroed momentum.

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 50 --body_muon_momentum_zero_blockwise_subset deep
```

Assert:
1. Sentinel `[step 50] body PMuon momentum HARD-ZERO blockwise (subset=deep, target_blocks=[...], n_zeroed=N) out of n_blocks=12` fires.
2. n_blocks = 12 (modded-nanogpt model depth).
3. target_blocks contains exactly 4 indices (the last 4).
4. n_zeroed > 0.
5. No NaN, no crash.

## Reproduce commands

**Arm A — momentum ZERO in DEEP blocks (last 4) @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 975 --body_muon_momentum_zero_blockwise_subset deep \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-edward-body-mom-zero-blockwise \
  --wandb_name g1r1-edward/body-mom-zero-blockwise-armA-deep
```

**Arm B — momentum ZERO in SHALLOW blocks (first 4) @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 975 --body_muon_momentum_zero_blockwise_subset shallow \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-edward-body-mom-zero-blockwise \
  --wandb_name g1r1-edward/body-mom-zero-blockwise-armB-shallow
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT zero all blocks** — that is the closed #1876 GLOBAL test. Subset MUST be "deep" or "shallow", not "all".
- **Do NOT touch aux Adam (optimizer1)** — body PMuon only.
- **Do NOT modify cov state, NS coefs, γ, μ, or LR** — momentum_buffer only.
- **Do NOT change the canonical β₂ pulse step or amplitude** — keep step 975 / target 0.99.
- **Do NOT skip reading the existing block-indexing code path** — implementation MUST use the canonical mechanism.
- **Do NOT introduce additional flags beyond the two listed.**

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A (deep) WIN** | Cooldown momentum staleness is depth-localized to deep blocks. Global reset failed because shallow blocks paid the cost. Request seed-2; deepens block-stratification thesis. |
| **Arm B (shallow) WIN** | Opposite localization — shallow blocks needed the reset (counterintuitive given late-higher LR). Request seed-2. |
| **Both WIN** | Block-stratified zeroing universally helps; the GLOBAL reset failed due to interaction. Surprising — request seed-2 on best arm. |
| **Both NULL** | Confirms #1797/#1876 conclusion across all block partitions. Body PMuon momentum is genuinely invariant to reset at cooldown onset. Depth-stratification axis on body momentum CLOSED. |
| **Arm A NULL, Arm B regresses** | Deep momentum benign, shallow harmful — informative depth-localization map even if no WIN. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
