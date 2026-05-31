# HYPOTHESIS — tanjiro — Aux Adam m-state HARD-ZERO PER-GROUP localization @ step 975 (lm_head-only vs embed-only)

**Branch:** `g1r1-tanjiro/aux-m-zero-per-group`
**Assigned:** 2026-05-31 05:57 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state resets at phase boundaries; (b) per-layer/per-block optimizer behavior; (c) short phase-specific mechanisms

## Why this hypothesis

**Just closed:** aux Adam m-state perturbation axis @ all temporal boundaries:
- #1881 (your prior PR — partial decay ×0.5/×0.25 @ 975) — bilateral NULL, non-monotone (partial worse than zero AND worse than baseline)
- #1815 nezuko (joint m-zero @ 975 n=2) — bilateral NULL on cross-seed (seed-1 was thin-WIN but seed-2 failed)
- #1879 alphonse (m-zero @ 2600 / @ 2750) — bilateral NULL
- #1770 nezuko (joint m+v zero @ 975/1200) — bilateral NULL

ALL of these tested m-zero **uniformly across all 3 aux Adam param groups** (embed + lm_head + scalars). The cross-seed-noise pattern for #1815 (seed-1 thin WIN, seed-2 fail) suggests there MAY be a load-bearing m-state component in ONE specific group that, when zeroed alone, captures the signal — but the bulk benefit gets diluted or contaminated by zeroing the OTHER groups.

**Mirror of #1837 logic on a different state axis:** Your prior #1837 tested β₂ pulse PER-GROUP localization (embed-only vs lm_head-only), and the result was: per-group localization closed the β₂ pulse axis (only JOINT switch produces WIN). The opposite signature on m-state would be: per-group localization OPENS where joint failed.

**Open question:** Does m-zero in ONE specific aux group capture the cooldown benefit that was diluted in the joint reset?

- **Arm A — m-zero lm_head-only @ step 975:** lm_head has the lowest LR (1/160 = 0.00625) and is the projection-to-vocab layer; its m-state encodes vocab-direction momentum. Zeroing only lm_head's m at cooldown onset might give targeted benefit.
- **Arm B — m-zero embed-only @ step 975:** embed has the highest LR (0.3) and feeds the model input representation. Zeroing only embed's m at cooldown onset tests the input-side staleness hypothesis.

We deliberately SKIP `adam_scalars` since RMSNorm-gain group is well-covered by frieren #1850 (LR-axis CLOSED) and askeladd #1912 (v-state in flight). Cleanest novelty is on lm_head and embed.

## Distinct from in-flight and closed work

- **#1815 nezuko (closed)**: JOINT m-zero @ 975 (all 3 groups) — bilateral NULL on n=2
- **#1879 alphonse (closed 05:57 UTC)**: JOINT m-zero @ 2600 / @ 2750 — bilateral NULL
- **#1881 your prior (closed 05:57 UTC)**: JOINT m partial decay @ 975 — bilateral NULL
- **#1837 your prior (closed)**: β₂ pulse PER-GROUP localization — different state buffer (β₂ rate vs m-state)
- **No prior aux Adam m-state HARD-ZERO with PER-GROUP localization at any boundary.** Cleanly novel.

## Experiment design

**Bilateral PER-GROUP localization test on m-zero @ step 975:**

- **Arm A — m-zero on `adam_lm_head` only @ step 975**
- **Arm B — m-zero on `adam_embed` only @ step 975**

Both arms preserve canonical interventions: aux β₂ pulse 0.95→0.99 @975, pEMA refresh @2600, late-higher block LR, ema_beta=0.97.

## Implementation guidance

**Step 1: Add CLI flags** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--aux_m_zero_per_group_step", type=int, default=0,
    help="Step at which to hard-zero exp_avg (m) of a SPECIFIC aux Adam group (0 disables)",
)
parser.add_argument(
    "--aux_m_zero_per_group_target",
    type=str, default="none",
    choices=["none", "adam_lm_head", "adam_embed"],
    help="Which aux group to zero m-state in. NOT adam_scalars (excluded by design).",
)
```

**Step 2: Apply per-group m-zero** — BEFORE `optimizer1.step()`:

```python
if (args.aux_m_zero_per_group_step > 0
        and step == args.aux_m_zero_per_group_step
        and args.aux_m_zero_per_group_target != "none"):
    target_name = args.aux_m_zero_per_group_target
    n_zeroed = 0
    for group in optimizer1.param_groups:
        if group.get("name", "") != target_name:
            continue
        for p in group["params"]:
            state = optimizer1.state.get(p, None)
            if state is None or "exp_avg" not in state:
                continue
            state["exp_avg"].zero_()
            n_zeroed += 1
    if dist.get_rank() == 0:
        print0(
            f"[step {step}] aux Adam m-ZERO PER-GROUP (target='{target_name}', "
            f"n_zeroed={n_zeroed}; exp_avg_sq untouched)",
            console=True,
        )
        if wandb.run is not None:
            wandb.log({
                "aux_m_zero_per_group/step": step,
                "aux_m_zero_per_group/n_zeroed": n_zeroed,
            }, step=step)
```

**CRITICAL:**
- `default=0` and `target="none"` MUST be a no-op.
- Only touch `exp_avg` (m). Do NOT touch `exp_avg_sq` (v) — that's askeladd's axis.
- Verify the canonical `group["name"]` matches one of the param group names — if "adam_embed" / "adam_lm_head" don't match, inspect optimizer1 construction and use the actual names.
- Do NOT touch body PMuon (optimizer2).

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_m_zero_per_group_step 50 --aux_m_zero_per_group_target adam_lm_head
```

Assert sentinel `[step 50] aux Adam m-ZERO PER-GROUP (target='adam_lm_head', n_zeroed=N; ...)` fires with `n_zeroed > 0`. No NaN.

## Reproduce commands

**Arm A — m-zero `adam_lm_head` only @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_m_zero_per_group_step 975 --aux_m_zero_per_group_target adam_lm_head \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-tanjiro-aux-m-zero-per-group \
  --wandb_name g1r1-tanjiro/aux-m-zero-pergroup-armA-lmhead
```

**Arm B — m-zero `adam_embed` only @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_m_zero_per_group_step 975 --aux_m_zero_per_group_target adam_embed \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-tanjiro-aux-m-zero-per-group \
  --wandb_name g1r1-tanjiro/aux-m-zero-pergroup-armB-embed
```

Run Arm A first, then chain Arm B.

## Anti-patterns

- **Do NOT zero all groups** — that is the closed #1815 JOINT test.
- **Do NOT zero `adam_scalars`** — scalars is covered by frieren #1850 (LR axis closed) and askeladd #1912 (v-state, in flight).
- **Do NOT touch exp_avg_sq (v)** — that's askeladd's axis.
- **Do NOT change boundary** — step 975 only.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A (lm_head-only) WIN** | Cooldown m-staleness localized to lm_head. Request seed-2; potential new merge candidate orthogonal to β₂ pulse. |
| **Arm B (embed-only) WIN** | Cooldown m-staleness localized to embed (input side). Request seed-2. |
| **Both WIN, different magnitudes** | Per-group structure shows up; identifies the more useful group. |
| **Both NULL** | m-state cooldown intervention is invariant to per-group localization — the global #1815/#1879/#1881 conclusion holds at every scope. **Aux Adam m-state axis fully closed across magnitudes, temporal boundaries, AND group scopes.** |
| **Both regress significantly** | m-state per-group surgery is harmful; closes the per-group localization axis. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
