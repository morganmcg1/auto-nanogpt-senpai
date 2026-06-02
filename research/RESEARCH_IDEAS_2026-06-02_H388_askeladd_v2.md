# H388 v2 — Per-Aux-Group Cooldown Fraction Decoupling (lm_head Independent Schedule)

**Assigned to:** g1r3-askeladd  
**Date:** 2026-06-02  
**Branch slug:** `h388-aux-lmhead-cooldown-decouple`  
**LoC estimate:** ~13 LoC (2 CLI flags + conditional per-group assignment)  
**WIN probability:** 10–12%  
**Novelty verification:** Grepped EXPERIMENTS_LOG.md against all closed axes including H319/H328/H334/H335/H337/H338/H340 (AUX WD + schedule family), H130/H250 (AUX cooldown shape), H194 (AUX cooldown fraction uniform sweep), H153 strategy-tier EMA closure, H149/H157 (AGC schedule), H254 (muonh warmup shape), H303/H332 (PEMA decay schedule), H354 (body β shape), H312 (bias correction BODY), H385 (AUX→BODY v_t coupling) — no prior experiment has tested per-aux-group cooldown_frac decoupling; H130 line 9584 EXPLICITLY flags this as never-tested future direction.

---

## Mechanism

All three AUX AdamW parameter groups — `adam_embed` (lr=0.3), `adam_lm_head` (lr=1/320), `adam_scalars` (lr=0.01) — currently share an identical `cooldown_frac=0.4` value, meaning all three begin their linear LR ramp-down at the same fractional point (~step 2010 of 3350). H130 (PR #1071) identified that this shared schedule is *bound* by `lm_head`'s dynamics: lm_head has systematically larger grad norms than embed and scalars, and its step-by-step LR trajectory is what differentiates performance across arms. H130 line 9584 explicitly states: *"lm_head is the schedule-binding aux sub-component... Motivates per-aux-group schedule axes as future direction (student suggestion #2 logged for future programme work)."* Line 8374 endorses *"decoupled aux LR cooldown"* as a viable future schedule-axis intervention.

The hypothesis is that lm_head's large grad-norm regime may benefit from an *earlier* onset of LR decay (giving more time in the low-LR convergent regime) or alternatively a *later* onset (preserving higher LR longer to avoid premature convergence in a high-curvature loss surface near the output projection). The current H194-validated optimum of `cooldown_frac=0.4` for the UNIFORM case may be a compromise between what embed+scalars want and what lm_head wants.

---

## Orthogonality Reasoning

| Closed axis | Closure PR | Why this proposal is orthogonal |
|---|---|---|
| AUX WD value + schedule | H328 PR #1926, H319 | Tests `cooldown_frac`, not `weight_decay`. WD=0 is hardcoded and untouched. |
| AUX cooldown SHAPE (uniform) | H130 PR #1071, H250 | H130 tested `cooldown_shape` ∈ {linear, cosine, sqrt} with ALL groups sharing the same shape. This proposal fixes shape=linear for all groups and varies only lm_head's `cooldown_frac` value. |
| AUX cooldown FRACTION VALUE (uniform) | H194 PR #1311 | H194 tested `cooldown_frac` ∈ {0.0, 0.4, 1.0} applying the SAME value to all 3 groups simultaneously. This proposal holds embed+scalars at 0.4 and varies only lm_head's fraction — a structurally different experiment. |
| AUX AdamW-family extensions | H345 region closure | This is a schedule-axis intervention, not an AdamW variant (betas, eps, second-moment, curvature). |
| EMA / SWA weight averaging | H153 strategy-tier closure | Cooldown LR schedule is not weight averaging. |
| BODY MuonH bias_correction | H312 | AUX-only change. |
| AUX→BODY v_t coupling | H385 PR #2247 | This proposal does not cross optimizer boundaries; it only changes schedule timing within AUX. |

The H266 baseline code already applies `cooldown_frac` as a per-group dict key in a loop:

```python
for group in optimizer1.param_groups:
    group["cooldown_frac"] = aux_cooldown_frac
    group["cooldown_shape"] = "linear"
```

Per-group decoupling requires only that this loop be broken into conditional assignments by `group["name"]`. No structural optimizer change.

---

## 3-Arm Chain Design

All arms use `train_steps=3350`, `--wandb_group h388-aux-lmhead-cooldown-decouple`.

### arm_a — CTRL (bit-identity sentinel)

Run with all default H266 flags. No new flags set. Verifies step-0 val = **10.82583 EXACT**.

```bash
python train_gpt_simple.py \
  --wandb_project <project> \
  --wandb_group h388-aux-lmhead-cooldown-decouple \
  --run_name h388_arm_a_ctrl
```

Expected: step-0 val = 10.82583, FFS ≈ 3000 (baseline).

### arm_b — LH_EARLY (lm_head cooldown starts earlier)

lm_head `cooldown_frac=0.65` (cooldown onset ~step 1167 vs default ~2010); embed and scalars remain at `cooldown_frac=0.4`.

Rationale: lm_head's large grad norms may reflect a high-curvature basin near the output projection. Starting the cooldown earlier gives more steps in a decaying LR regime, potentially improving the final convergent step quality.

```bash
python train_gpt_simple.py \
  --aux_lmhead_cooldown_frac 0.65 \
  --wandb_project <project> \
  --wandb_group h388-aux-lmhead-cooldown-decouple \
  --run_name h388_arm_b_lh_early
```

Expected: FFS shift ±50 steps relative to CTRL; direction informs whether lm_head benefits from a longer low-LR tail.

### arm_c — LH_LATE (lm_head cooldown starts later)

lm_head `cooldown_frac=0.20` (cooldown onset ~step 2680 vs default ~2010); embed and scalars remain at `cooldown_frac=0.4`.

Rationale: lm_head may be oversuppressed by the early cooldown start, and maintaining higher LR longer could allow continued escape from local minima before the final convergent basin.

```bash
python train_gpt_simple.py \
  --aux_lmhead_cooldown_frac 0.20 \
  --wandb_project <project> \
  --wandb_group h388-aux-lmhead-cooldown-decouple \
  --run_name h388_arm_c_lh_late
```

Expected: FFS shift ±50 steps relative to CTRL; together with arm_b, determines which side of default=0.4 is better (if either).

---

## Decision Rules

- **Step-0 val check (gate):** arm_a must produce step-0 val = 10.82583 ± 0.00001. If not, abort and report; the CTRL config has drifted.
- **Merge gate (strict per Issue #1260):** any arm with FFS < 3000 and terminal SENPAI-RESULT with `terminal=true, pending_arms=false` is a winner. FFS = 3000 is a TIE, not a WIN.
- **Promising direction (send back):** if one arm shows FFS in [2990, 2999] without clean beating, report direction and request a tighter sweep (e.g., arm_b_prime at cf=0.55, arm_c_prime at cf=0.30).
- **Close:** if both treatment arms show FFS ≥ 3000 and neither shows a val/loss improvement below noise floor σ_H174 = 0.000884, close as NULL and record as "per-aux-group cooldown_frac variation on lm_head CLOSED."
- **Do not cherry-pick seeds.** Use the single fixed seed. Do not rerun an arm because it showed a slightly worse FFS — report the single run result.

---

## Implementation Guidance

### New CLI flags to add

```python
parser.add_argument("--aux_lmhead_cooldown_frac", type=float, default=None,
    help="If set, overrides cooldown_frac for the adam_lm_head group only. "
         "embed and scalars remain at aux_cooldown_frac=0.4.")
```

Total: 3 lines (argparse add_argument).

### Per-group assignment in optimizer init (replaces the existing loop)

Find the existing block (approximately lines 956–966 of train_gpt_simple.py):

```python
aux_cooldown_frac = 0.4
for group in optimizer1.param_groups:
    group["cooldown_frac"] = aux_cooldown_frac
    group["cooldown_shape"] = "linear"
```

Replace with:

```python
aux_cooldown_frac = 0.4
for group in optimizer1.param_groups:
    if group.get("name") == "adam_lm_head" and args.aux_lmhead_cooldown_frac is not None:
        group["cooldown_frac"] = args.aux_lmhead_cooldown_frac
    else:
        group["cooldown_frac"] = aux_cooldown_frac
    group["cooldown_shape"] = "linear"
```

Total: 4 lines added (net +3 vs original loop body, +2 vs baseline counting argparse). Grand total: ~13 LoC including the argparse definition.

### Pattern A bit-identity preservation

The new flag defaults to `None`, which triggers the `else` branch and preserves `cooldown_frac=0.4` for all groups. This guarantees arm_a (CTRL, no flag set) produces the identical computation path as H266 baseline — step-0 val = 10.82583 is preserved by construction.

### No new dependencies

No third-party optimizer packages. The change is purely within the scheduler loop that modifies param_group dicts before `get_lr()` is called at each step.

### Telemetry to log

Add per-group LR logging at each step so the W&B run makes the decoupled trajectories visible:

```python
# In the per-step logging block:
for group in optimizer1.param_groups:
    wandb.log({f"aux_lr/{group['name']}": group['lr']}, step=step)
```

This is ~3 lines and makes the per-group cooldown trajectories directly auditable in W&B, which is critical for interpreting the result. If lm_head's LR trajectory is now visibly decoupled from embed/scalars, the mechanism is confirmed active.

---

## Why 10–12% WIN Probability

- **Positive signal:** H130 directly fingerprinted lm_head as the schedule-binding component and explicitly recommended this axis. Line 8374 endorses it. The direction is not speculative.
- **Uncertainty:** H194 confirmed that the UNIFORM optimum is `cooldown_frac=0.4`. The decoupled optimum for lm_head alone is unknown, but the test values (0.65, 0.20) bracket the default from both sides, giving the arm_b/arm_c pair a reasonable chance of landing near a better lm_head-specific optimum.
- **Headroom limit:** We are at cycle ~2700 with 236 closures and 1 WIN (H266). The schedule-axis neighborhood has not fully been explored at the per-group granularity level, but the global optimum for aux schedules may already be close to the H266 point. The gain, if any, is likely ~20–50 FFS improvement, which meets the FFS < 3000 merge gate.
- **Against:** lm_head's large grad norms may mean the default `cooldown_frac=0.4` already correctly reflects its binding constraint; changing it could simply move from one suboptimal decoupled state to another. The H130 binding finding may describe a fixed point, not a suboptimality.

---

## Baseline Reference

Current best: **H266** (PEMA decay=0.05)  
- FFS: **3000** (merge gate requires strictly < 3000)  
- val/loss at step 3350 (full train): ~3.278  
- Step-0 val (bit-identity check): **10.82583 EXACT**

All treatment arms must beat FFS=3000 strictly. A tie at 3000 is NOT a win.
