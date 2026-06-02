# frieren — PMuon Update Frobenius-Norm Ceiling Relative to Weight Norm bilateral (γ=0.5 vs γ=0.3)

## Context

Baseline #1532: `speedrun/first_step_to_target` (sr) = **2875**, `val/loss_ema` = **3.262854**.

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`.

Current PMuon update magnitude control (lines ~615–620):
```python
# u/w FLOOR — LOWER bound only
w_norm = p.norm()
if w_norm > 0:
    ratio = update.norm() / w_norm
    if 0 < ratio < TARGET_UW:  # TARGET_UW = 0.35
        update.mul_(TARGET_UW / ratio)
```

The u/w floor (PR #94 askeladd, merged ~2026-05-16) was a 50-step WIN on top of pure PMuon — it scales UP small updates so every step moves at least `0.35 × ||W||_F`. The floor fires at 100% of body-PMuon params every step throughout the run.

**The floor exists; the ceiling does not.** There is no upper bound on `||update||_F / ||W||_F`. In principle PMuon could take an arbitrarily large step relative to the weight norm — and in the final cooldown phase, as LR decays, the absolute update size naturally shrinks, but the RATIO `||update||/||W||` is governed only by the Kronecker whitening + NS polar projection chain, not by any explicit ceiling.

The u/w floor proves that **update magnitude control matters** (without it, 100% of body params take steps below 0.35·||W||, hurting late-phase progress). The missing direction is the symmetric question: does **excess** update magnitude in the final phase also hurt? PR #331 showed per-tensor embed grad clipping got val_loss=3.2685 (near-miss — best non-merged result in the embed/lm_head axis). This is suggestive evidence that magnitude ceilings can also matter, but at the body-PMuon level it has never been tested.

Closed adjacent axes:
- u/w floor TARGET_UW value scans — established 0.35 as optimum (#94 et seq.)
- per-tensor embed grad clipping (#331) — near-miss, separate subsystem
- raw gradient clipping pre-whitening — closed in early experiments
- L2-norm normalization of post-polar update (#627) — closed
- PMuon γ_power axis — closed at 0.4 (#202)

PRISTINE axis: **upper bound on body-PMuon update Frobenius norm relative to current weight norm**. The mechanism is mathematically complementary to the existing u/w floor (which sets a LOWER bound at TARGET_UW = 0.35). Adding a ceiling tests whether late-phase over-magnitude updates create paramEMA-buffer noise or per-step loss spikes that prevent the final 250-step descent from cleanly crossing 3.28 before step 2862.5.

## Hypothesis

The current PMuon update magnitude distribution has a floor (TARGET_UW=0.35) but no ceiling. The floor was load-bearing because PMuon's bilateral L^{-γ} R^{-γ} whitening systematically SHRINKS updates below 0.35·||W|| (per the #94 mechanism description: "u/w-floor fires at 100% of eligible params every step"). But the polar projection output, after multiplication by `max(1, m/n)**0.5`, can produce updates whose norm-ratio occasionally exceeds the typical operating range. In the final cooldown phase, these excursions may correspond to noisy gradient batches where the optimizer "wants" to take a large step in a direction that ends up hurting the paramEMA buffer (which averages over the final 250 steps and decides val_ema).

A weight-norm-relative upper bound `||update||_F ≤ γ·||W||_F` adds a complementary magnitude clamp without changing the floor mechanism. Both arms keep the existing u/w floor untouched (still applies first); the ceiling is layered on top.

Two arms test the threshold strength:

- **Arm A (LOOSE γ=0.5):** clip when `||update||_F > 0.5·||W||_F`. Conservative — leaves wide operating range above floor (0.35) but caps the rare excursions. Hypothesis: only the extreme outliers matter; most updates pass through unchanged.
- **Arm B (TIGHT γ=0.3):** clip when `||update||_F > 0.3·||W||_F`. **Tighter than the existing u/w floor (0.35)**. This creates a structural inversion in some steps: the floor would scale UP to 0.35·||W||, then the ceiling would scale DOWN to 0.3·||W||. The net effect is that every body-PMuon update is clamped to exactly `||update||_F = 0.3·||W||_F` (within numerical precision). This is essentially "constant relative step magnitude" mode for PMuon, removing all update-magnitude variability.

The arms test opposing theories: Arm A says "magnitude ceilings only matter for outliers"; Arm B says "constant-magnitude updates outperform variable-magnitude updates".

Directive (a) optimizer-state rescaling at phase boundaries (the ceiling is a magnitude rescaling complementary to the existing u/w floor). Directive (e) schedules that steepen loss descent before step 2925 (removing late-phase magnitude excursions could clean up the final 250 steps).

Mechanistically distinct from:
- u/w floor (#94 et seq.) — LOWER bound, FIRES on 100% of params
- gradient clipping pre-whitening — operates on raw gradient, before optimizer state
- post-polar L2 normalization (#627) — normalizes to fixed magnitude, removes both direction-dependent variation AND magnitude
- per-block LR scheduling — modulates magnitude indirectly via LR multiplier per block, not per-update

## Implementation

**File:** `records/track_3_optimization/train_gpt_simple.py`

### CLI flag

```python
parser.add_argument("--pmuon_update_clip_gamma", type=float, default=-1.0,
                    help="Upper bound on PMuon update Frobenius norm relative to weight norm: "
                         "if ||update||_F > gamma * ||W||_F, scale update down to gamma * ||W||_F. "
                         "-1 (default) disables the ceiling (baseline behavior). "
                         "Applies AFTER the u/w floor.")
```

### Ceiling logic

In `Muon.step()` (search for the `pmuon_update` call site and the u/w floor block, likely around lines 615–625). The ceiling is added IMMEDIATELY AFTER the existing u/w floor block:

```python
# Existing u/w FLOOR (do not modify):
w_norm = p.norm()
if w_norm > 0:
    ratio = update.norm() / w_norm
    if 0 < ratio < TARGET_UW:
        update.mul_(TARGET_UW / ratio)

# NEW: u/w CEILING (added)
if args.pmuon_update_clip_gamma > 0:
    if w_norm > 0:
        u_norm = update.norm()
        clip_thresh = args.pmuon_update_clip_gamma * w_norm
        if u_norm > clip_thresh:
            update.mul_(clip_thresh / u_norm)
```

**IMPORTANT:** Use the **same** `w_norm` computed by the floor block — do not recompute (waste). Use the **fresh** `update.norm()` AFTER the floor has potentially scaled the update up. In Arm B (γ=0.3 < 0.35 floor), the floor will fire first and produce `||update||_F = 0.35·||W||`, then the ceiling will fire and scale down to `||update||_F = 0.3·||W||`. The order floor-then-ceiling produces "exactly γ·||W||" updates in Arm B — this is intentional and is the structural test.

### Telemetry

Log at standard cadence:
- `optim/pmuon_update_clip_gamma` (constant per run, set at step 0)
- `optim/pmuon_clip_fire_rate` (per step, fraction of body-PMuon params that hit the ceiling — measures how often the ceiling actually clamps)
- `optim/pmuon_pre_clip_norm_ratio_mean` (per step, mean `||update||/||W||` BEFORE ceiling, AFTER floor — gives the distribution shape we're clipping)
- `optim/pmuon_post_clip_norm_ratio_mean` (per step, mean ratio AFTER ceiling — should be exactly γ for params that hit, lower for ones that didn't)

These four metrics let us see the ceiling's actual impact across training. Accumulate fire counts in a tensor across the step's body-PMuon params, then log the fraction at the end of `Muon.step()`.

### Sentinel at step 0

```python
if step == 0 and dist.get_rank() == 0:
    print0(f"[step 0] pmuon_update_clip_gamma={args.pmuon_update_clip_gamma}, "
           f"TARGET_UW (floor)={TARGET_UW}",
           console=True)
    if wandb.run:
        wandb.log({"optim/pmuon_update_clip_gamma": args.pmuon_update_clip_gamma,
                   "optim/uw_floor_target": TARGET_UW}, step=0)
```

### CRITICAL: bitwise-baseline check

`--pmuon_update_clip_gamma -1.0` (default) MUST reproduce baseline trajectory exactly. The conditional `args.pmuon_update_clip_gamma > 0` skips the ceiling block entirely. Verify first 50 train loss values bitwise-match a known baseline run.

## Baseline reproduce (always include full stack)

```bash
# Arm A — LOOSE ceiling (γ=0.5)
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --pmuon_update_clip_gamma 0.5 \
  --wandb_group g1r1-frieren-pmuon-update-clip \
  --wandb_name g1r1-frieren/pmuon-clip-loose-arm-a

# Arm B — TIGHT ceiling (γ=0.3 < TARGET_UW=0.35; floor+ceiling produce exactly γ·||W||)
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --pmuon_update_clip_gamma 0.3 \
  --wandb_group g1r1-frieren-pmuon-update-clip \
  --wandb_name g1r1-frieren/pmuon-clip-tight-arm-b
```

## Chain rule

1. Implement flag + sentinel + telemetry. Smoke-verify `--pmuon_update_clip_gamma -1.0` reproduces baseline (first 50 train losses bit-for-bit match a known baseline run).
2. **Launch Arm A (LOOSE γ=0.5) first.** Check `optim/pmuon_clip_fire_rate` at step ~100 — confirms the ceiling actually fires nonzero times (or is essentially never active, in which case Arm A is bitwise-baseline and you should skip to Arm B).
   - Clear NULL (sr ≥ 2925, val_ema ≥ 3.265): launch Arm B (TIGHT γ=0.3) directly.
   - WIN candidate (sr ≤ 2875, val_ema near baseline): run seed-2 of Arm A first before Arm B.
3. Both arms terminal → post:

```markdown
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<a-id>","<b-id>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<sr>},"test_metric":{"name":"val/loss_ema","value":<val_ema>}}
```

## Expected outcomes

| Outcome | Meaning | Follow-up |
|---|---|---|
| Arm A WIN (LOOSE 0.5) | Magnitude ceilings matter for outlier steps only | Bracket γ ∈ {0.4, 0.6} |
| Arm B WIN (TIGHT 0.3) | Constant-magnitude updates outperform variable | Test γ ∈ {0.25, 0.35}; consider stacking with per-block γ schedule |
| Both NULL | u/w floor already captures the magnitude control we need | Close ceiling axis at this granularity |
| Arm A NULL, Arm B WIN | Magnitude variability HURTS late phase; clamping ALL updates to constant helps | Investigate why; possibly add to baseline as 4th magnitude-control mechanism |
| Asymmetric near-miss | One direction measurably closer to baseline | Narrow bracket on winning side |

## Why this might break the plateau

The plateau analysis identifies the bottleneck as val_ema in steps 3000–3250 not converging fast enough. The paramEMA buffer averages over these 250 steps — any per-step update that creates a transient large-magnitude excursion will contaminate the buffer. The u/w floor's existence proves the update-magnitude distribution matters for the floor side; the ceiling side has never been tested. If the late-phase val_ema is being dragged up by occasional oversized updates that the paramEMA absorbs as noise, a ceiling could clean up the final 250 steps without affecting the high-LR descent phase (where most updates are below the ceiling anyway). The bilateral arm split (loose vs tight) is well-shaped to discriminate outlier-suppression (LOOSE) from constant-magnitude-mode (TIGHT).

## Falsifying outcome

Both arms sr ≥ 2900 or significantly worse: update magnitude excursions are not load-bearing for late-phase convergence — the u/w floor + LR schedule + polar projection already control update magnitude adequately. A ceiling either does nothing (loose) or removes too much useful variability (tight). Close direction.

## Files to touch

- `records/track_3_optimization/train_gpt_simple.py` (CLI arg + ceiling block in `Muon.step` + sentinel logging + 4 telemetry metrics)

No other files. Delta: ~25 LOC.

## Per-arm GPU usage estimate

Single trial per arm, full 3250-step run. ~3.5–4h per arm wall-clock on 1×H100. Total expected: ~7–8h for bilateral.
