# HYPOTHESIS — alphonse — Body PMuon γ pulse BLOCK-STRATIFIED @ step 975 (DEEP-only vs SHALLOW-only γ→0.5)

**Branch:** `g1r1-alphonse/body-gamma-blockwise`
**Assigned:** 2026-05-31 05:57 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (b) per-layer/per-block optimizer behavior; (d) preconditioner state handling; (a) state resets at phase boundaries

## Why this hypothesis

**Closed:** body PMuon γ (whitening exponent) GLOBAL pulse at cooldown onset:
- #1831 fern (γ→0.3 RELAX, γ→0.5 SHARPEN @ 975) — bilateral NULL (+4.2 / +3.4 mnat)
- #1680 (γ pulse at pre-target step 2750) — bilateral NULL

Both tests applied γ change UNIFORMLY across all 12 body PMuon blocks. The canonical `muon_block_lr_pattern=late-higher` means deep blocks effectively run at HIGHER LR — their L^{-γ}·g·R^{-γ} whitening operator sees larger gradient magnitudes per step and accumulates larger cov estimates → γ exponent change has DIFFERENT effective scale across depth.

**Mechanistic reasoning for block-stratified γ pulse:**
- Body PMuon whitening: `L^{-γ} · g · R^{-γ}` — larger γ → sharper whitening → larger effective update step
- Deep blocks (high effective LR): SHARPEN at deep blocks gives outsized magnitude boost; may overshoot
- Shallow blocks (low effective LR): SHARPEN at shallow blocks gives modest magnitude boost in low-leverage region; could be benign and aid feature stability

**Open question:** Does γ pulse target the right blocks? Global γ→0.5 failed because deep blocks (high LR) overshot. Restricting γ change to ONE subset may reveal where the headroom lives.

- **Arm A — γ→0.5 SHARPEN in DEEP blocks only (last 4 of 12) @ step 975**
- **Arm B — γ→0.5 SHARPEN in SHALLOW blocks only (first 4 of 12) @ step 975**

Bilateral on localization (depth subset), with magnitude held at SHARPEN (γ→0.5) — which was the marginally-less-bad direction in #1831. If shallow-only WIN: the headroom is shallow-block whitening sharpness. If deep-only WIN: opposite localization. If both NULL: γ axis truly closed regardless of localization.

## Distinct from in-flight and closed work

- **#1831 fern (closed)**: GLOBAL γ pulse @ 975 (γ→0.3 / γ→0.5) — bilateral NULL
- **#1680 (closed)**: GLOBAL γ pulse @ pre-target 2750 — bilateral NULL
- **edward #1929 (in-flight)**: block-stratified body PMuon MOMENTUM zero @ 975 — DIFFERENT state (momentum_buffer not cov whitening exponent)
- **No prior block-stratified γ pulse at ANY temporal boundary.** Cleanly novel.

## Experiment design

**Bilateral block-bucket test (axis: depth localization with γ→0.5 SHARPEN fixed):**

- **Arm A — γ→0.5 in DEEP blocks (last 4 of 12) @ step 975**
- **Arm B — γ→0.5 in SHALLOW blocks (first 4 of 12) @ step 975**

Both arms preserve canonical interventions. The γ pulse is PERMANENT (not a transient pulse) — once applied at step 975, γ=0.5 remains for the target subset through end of training. This matches the #1831 pulse semantics.

## Implementation guidance

**Step 1: Locate the body PMuon γ parameter** in `records/track_3_optimization/train_gpt_simple.py`. The body PMuon class stores γ as either `group["gamma"]` or a class-level attribute. Find the canonical default (γ=0.4) and the existing pulse mechanism (#1831 added a global pulse).

**Step 2: Locate the existing block-index attribute** used by `muon_block_lr_pattern=late-higher`. Edward #1929 (in flight) uses the same mechanism. Use the same attribute name in your code.

**Step 3: Add CLI flags:**

```python
parser.add_argument(
    "--body_muon_gamma_pulse_blockwise_step", type=int, default=0,
    help="Step at which to set body PMuon γ to a target value for a subset of blocks (0 disables)",
)
parser.add_argument(
    "--body_muon_gamma_pulse_blockwise_target", type=float, default=0.4,
    help="γ target value for blockwise pulse (default 0.4 = canonical no-op)",
)
parser.add_argument(
    "--body_muon_gamma_pulse_blockwise_subset",
    type=str, default="none",
    choices=["none", "deep", "shallow"],
    help="Which block subset receives the pulse: 'deep' = last 4 of 12, 'shallow' = first 4 of 12",
)
```

**Step 4: Apply blockwise γ pulse** — BEFORE `optimizer2.step()`:

```python
if (args.body_muon_gamma_pulse_blockwise_step > 0
        and step == args.body_muon_gamma_pulse_blockwise_step
        and args.body_muon_gamma_pulse_blockwise_subset != "none"):
    block_indices = sorted({
        g["block_idx"]   # use actual attribute name
        for g in optimizer2.param_groups
        if "block_idx" in g
    })
    n_blocks = len(block_indices)
    if args.body_muon_gamma_pulse_blockwise_subset == "deep":
        target_blocks = set(block_indices[-4:])
    elif args.body_muon_gamma_pulse_blockwise_subset == "shallow":
        target_blocks = set(block_indices[:4])
    else:
        target_blocks = set()

    target_gamma = float(args.body_muon_gamma_pulse_blockwise_target)
    n_groups_modified = 0
    gamma_before = None
    for group in optimizer2.param_groups:
        if group.get("block_idx") not in target_blocks:
            continue
        if gamma_before is None:
            gamma_before = group.get("gamma", None)
        group["gamma"] = target_gamma
        n_groups_modified += 1
    if dist.get_rank() == 0:
        print0(
            f"[step {step}] body PMuon γ pulse blockwise "
            f"(subset={args.body_muon_gamma_pulse_blockwise_subset}, "
            f"target_blocks={sorted(target_blocks)}, γ {gamma_before}->{target_gamma}, "
            f"n_groups_modified={n_groups_modified}) out of n_blocks={n_blocks}",
            console=True,
        )
        if wandb.run is not None:
            wandb.log({
                "body_muon_gamma_pulse_blockwise/step": step,
                "body_muon_gamma_pulse_blockwise/target_gamma": target_gamma,
                "body_muon_gamma_pulse_blockwise/n_groups_modified": n_groups_modified,
                "body_muon_gamma_pulse_blockwise/n_target_blocks": len(target_blocks),
            }, step=step)
```

**CRITICAL:**
- `default=0`, `subset="none"`, and `target=0.4` MUST be a no-op.
- The pulse is PERMANENT — γ stays at the target value for the target blocks until end of training.
- Apply to optimizer2 (body PMuon) ONLY.
- Block-index attribute name MUST match the existing late-higher implementation (likely `block_idx`).
- Do NOT modify γ in non-target blocks; they retain canonical γ=0.4.
- If γ is a class-level attribute on the PMuon optimizer (not per-group), you may need a per-group override mechanism — check the PMuon class for how γ is consumed during whitening computation.

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_gamma_pulse_blockwise_step 50 \
  --body_muon_gamma_pulse_blockwise_target 0.5 \
  --body_muon_gamma_pulse_blockwise_subset deep
```

Assert sentinel fires showing γ changes from 0.4→0.5 on the last 4 of 12 blocks. No NaN. Verify in-PMuon-step whitening uses the new γ value (logging or assert).

## Reproduce commands

**Arm A — γ→0.5 in DEEP blocks (last 4) @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_gamma_pulse_blockwise_step 975 \
  --body_muon_gamma_pulse_blockwise_target 0.5 \
  --body_muon_gamma_pulse_blockwise_subset deep \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse-body-gamma-blockwise \
  --wandb_name g1r1-alphonse/body-gamma-blockwise-armA-deep
```

**Arm B — γ→0.5 in SHALLOW blocks (first 4) @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_gamma_pulse_blockwise_step 975 \
  --body_muon_gamma_pulse_blockwise_target 0.5 \
  --body_muon_gamma_pulse_blockwise_subset shallow \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse-body-gamma-blockwise \
  --wandb_name g1r1-alphonse/body-gamma-blockwise-armB-shallow
```

Run Arm A first, then chain Arm B.

## Anti-patterns

- **Do NOT modify γ in all blocks** — that's the closed #1831 GLOBAL test.
- **Do NOT touch β_cov, μ, NS coefs, momentum, cov state** — γ exponent only.
- **Do NOT change γ target value** beyond 0.5 — keep magnitude fixed to isolate localization axis.
- **Do NOT change canonical β₂ pulse step or amplitude**.
- **Do NOT skip reading the existing block-indexing code path** — use the canonical mechanism.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A (deep) WIN** | γ→0.5 in deep blocks captures the cooldown sharpening benefit that global #1831 diluted via shallow-block contamination. Request seed-2. |
| **Arm B (shallow) WIN** | Shallow-block whitening sharpness is the headroom; counterintuitive given late-higher LR pattern. Request seed-2. |
| **Both WIN** | Block-stratified γ universally helps; the global test failed due to interaction. |
| **Both NULL** | γ axis is invariant to depth localization — global #1831 conclusion holds at every block subset. **Body PMuon γ axis truly closed across all magnitudes, temporal boundaries, AND depth scopes.** |
| **Both regress significantly** | Block-stratified γ surgery is harmful regardless of localization. Closes block-stratified γ axis. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
