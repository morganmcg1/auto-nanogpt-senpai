# HYPOTHESIS — askeladd — Aux Adam SCALAR-group v-state PARTIAL DECAY at cooldown onset step 975

**Branch:** `g1r1-askeladd/aux-scalar-v-decay-cooldown`
**Assigned:** 2026-05-31 04:28 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state resets/rescaling at phase boundaries; (d) preconditioner state handling; (c) short phase-specific mechanisms

## Why this hypothesis

Two recent signals localize the cooldown-onset benefit to the `adam_scalars` group on the LR axis:

1. **frieren #1850 Arm B** (`414cvcw7`): aux `scalar_lr` ×0.5 @ step 975 → thin WIN candidate sr=2875, val_ema=3.262813 (-0.041 mnat below gate). Seed-2 (`mcqx7lvb`) in flight at 04:28 UTC.
2. **askeladd #1868 (just closed)**: aux `embed_lr` ×0.5 @ step 975 → +4.65 mnat NULL. The same DECAY pattern on a DIFFERENT aux group fails.

**Open question:** Is the scalar benefit driven by **LR change** alone, by **state change** alone, or by their combination? The β₂ pulse 0.95→0.99 already runs jointly at step 975 and dramatically reshapes v-buffer integration timescale (~20 → ~100 steps), making the pre-pulse v-estimate stale under the new β₂ regime — but this is APPLIED to all aux groups uniformly.

**This hypothesis isolates the v-state side on the scalar group only:** decay `adam_scalars` `exp_avg_sq` (v) at the same step 975 phase boundary, while preserving everything else (β₂ pulse, LRs, m-state, embed/lm_head untouched).

If WIN: cooldown benefit has an independent v-state component on scalars — stacks orthogonally with frieren's LR-decay WIN.
If NULL: cooldown benefit is LR-localized (not state-localized) on scalars.

Either outcome is informative. This is also directive (a) + (d) — preconditioner state rescaling at phase boundary.

## Distinct from in-flight and closed work

- **frieren #1850** (seed-2 in flight): scalar `lr` decay @ 975 — different axis (LR not v)
- **tanjiro #1881**: aux m-state PARTIAL DECAY @ 975 — different state (m not v), and joint across all aux groups (not scalar-only)
- **alphonse #1879**: aux m-state ZERO at LATE boundaries (2600/2750) — different state, different temporal, different magnitude
- **thorfinn #1899**: JOINT multi-group aux LR decay @ 975 — different axis (LR not v), joint scope
- **edward #1785 (closed)**: aux m+v zero at 2600/2750 — full ZERO not partial decay, late boundary not cooldown onset
- **No prior aux SCALAR-group v-state partial decay at ANY temporal boundary.** Cleanly novel.

## Experiment design

**Bilateral magnitude test on `adam_scalars` v-buffer decay at step 975 (axis: decay scale):**

- **Arm A — `adam_scalars` v × 0.5 @ step 975** (matched magnitude with frieren #1850 Arm B scope)
- **Arm B — `adam_scalars` v × 0.25 @ step 975** (heavier decay; probe whether benefit deepens with stronger reset)

Both arms preserve all canonical interventions: aux β₂ pulse 0.95→0.99 @ 975, pEMA refresh @ 2600, late-higher block LR, ema_beta=0.97, all LRs untouched.

## Implementation guidance

**Step 1: Add CLI flags** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--aux_scalars_v_decay_step", type=int, default=0,
    help="Step at which to multiplicatively scale the adam_scalars group's "
         "exp_avg_sq (v) buffer. 0 disables.",
)
parser.add_argument(
    "--aux_scalars_v_decay_factor", type=float, default=1.0,
    help="Scale factor applied to adam_scalars exp_avg_sq when "
         "aux_scalars_v_decay_step fires. 1.0 is no-op.",
)
```

**Step 2: Apply v-decay in training loop** — BEFORE `optimizer1.step()`:

```python
if (args.aux_scalars_v_decay_step > 0
        and step == args.aux_scalars_v_decay_step
        and args.aux_scalars_v_decay_factor != 1.0):
    n_params_scaled = 0
    scale = float(args.aux_scalars_v_decay_factor)
    v_before_max = 0.0
    v_after_max = 0.0
    v_before_mean = 0.0
    v_after_mean = 0.0
    for group in optimizer1.param_groups:
        name = group.get("name", "")
        if name == "adam_scalars":
            for p in group["params"]:
                state = optimizer1.state.get(p, None)
                if state is None or "exp_avg_sq" not in state:
                    continue
                v = state["exp_avg_sq"]
                v_before_max = max(v_before_max, float(v.max()))
                v_before_mean += float(v.mean())
                v.mul_(scale)
                v_after_max = max(v_after_max, float(v.max()))
                v_after_mean += float(v.mean())
                n_params_scaled += 1
    if dist.get_rank() == 0:
        if n_params_scaled > 0:
            v_before_mean /= n_params_scaled
            v_after_mean /= n_params_scaled
        print0(f"[step {step}] aux_scalars v-decay x{scale} on {n_params_scaled} params: "
               f"v.mean {v_before_mean:.6e}->{v_after_mean:.6e}, "
               f"v.max {v_before_max:.6e}->{v_after_max:.6e}",
               console=True)
        if wandb.run is not None:
            wandb.log({
                "aux_scalars_v_decay/step": step,
                "aux_scalars_v_decay/factor": scale,
                "aux_scalars_v_decay/n_params_scaled": n_params_scaled,
                "aux_scalars_v_decay/v_mean_before": v_before_mean,
                "aux_scalars_v_decay/v_mean_after": v_after_mean,
                "aux_scalars_v_decay/v_max_before": v_before_max,
                "aux_scalars_v_decay/v_max_after": v_after_max,
            }, step=step)
```

**CRITICAL:**
- Default `aux_scalars_v_decay_step=0` and `aux_scalars_v_decay_factor=1.0` MUST be a no-op.
- ONLY scale `adam_scalars` group's `exp_avg_sq`. Do NOT touch `adam_embed`, `adam_lm_head`, or any other group.
- Do NOT touch `exp_avg` (m-state). Only `exp_avg_sq` (v-state).
- Do NOT touch LRs of any group.
- Do NOT touch body PMuon (optimizer2).
- Apply BEFORE `optimizer1.step()` so the very next update uses the decayed v.

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_scalars_v_decay_step 50 --aux_scalars_v_decay_factor 0.5
```

Assert:
1. Sentinel `[step 50] aux_scalars v-decay x0.5 on <N> params: v.mean ...` fires.
2. W&B logs show `aux_scalars_v_decay/v_mean_after` ≈ 0.5 × `aux_scalars_v_decay/v_mean_before`.
3. `n_params_scaled` > 0 (scalars exist).
4. Train loss continues descending normally — no NaN, no spike, no overshoot.
5. Body PMuon optimizer2 untouched.

## Reproduce commands

**Arm A — adam_scalars v × 0.5 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_scalars_v_decay_step 975 --aux_scalars_v_decay_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-askeladd-aux-scalar-v-decay \
  --wandb_name g1r1-askeladd/aux-scalar-v-decay-armA-x0.5
```

**Arm B — adam_scalars v × 0.25 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_scalars_v_decay_step 975 --aux_scalars_v_decay_factor 0.25 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-askeladd-aux-scalar-v-decay \
  --wandb_name g1r1-askeladd/aux-scalar-v-decay-armB-x0.25
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT modify `exp_avg` (m-state)** — tanjiro #1881 covers m-state; this is v-state only.
- **Do NOT modify embed or lm_head v-state** — closure of #1868 shows non-scalar groups regress.
- **Do NOT modify LRs** — frieren #1850 covers scalar LR; this is v-state only, isolating the state-side mechanism.
- **Do NOT touch body PMuon (optimizer2)** — separate axis.
- **Do NOT change temporal boundary** — step 975 is the WIN-bearing boundary per #1850.
- **Do NOT touch β₂ pulse, pEMA refresh, block LR pattern** — preserve all canonical interventions.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN (sr=2875 AND val_ema < 3.262854)** | Scalar v-decay independently produces cooldown benefit. Combined with frieren #1850, two orthogonal scalar mechanisms at cooldown onset. Request seed-2; stack-test with LR-decay next. |
| **Arm B WIN (sr=2875 AND val_ema < frieren #1850 seed-1 = 3.262813)** | Heavier v-decay deepens the WIN. NEW DOMINANT WIN ROUTE. |
| **Arm A NULL, Arm B WIN** | Heavy v-reset required to break inertia of stale v-buffer. Probe deeper magnitudes. |
| **Both NULL, val_ema within 1 mnat of gate** | v-state perturbation marginally helpful but insufficient alone; scalar LR is the dominant lever (frieren #1850 mechanism). |
| **Both NULL or regress significantly** | The cooldown scalar benefit is LR-localized, not state-localized. Closes the scalar v-state axis; refocuses on LR-only mechanisms. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
