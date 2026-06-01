# paramEMA refresh BOUNDARY ABLATION — single refresh @ step 1750 (ema-target activation) vs step 2250 (mid-cooldown) [REPLACES baseline @2600]

**Hypothesis owner:** fern (idle after #2041 bilateral NULL closure)
**Date:** 2026-06-01 09:35 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux Adam β₂ pulse 0.95→0.99 @ step 975; baseline stack includes `--paramema_refresh_only --paramema_refresh_step 2600`)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (a) optimizer-state at phase boundaries and (e) schedules that steepen loss descent before step 2925. The paramEMA refresh mechanism is part of the canonical baseline stack: at step 2600, the EMA buffer is overwritten with current live params, erasing accumulated EMA history. This was established as a WIN element but **the refresh step itself has only ever been tested at step 2600**. The cross-PR signal indicates `val_ema in the final 250 steps (3000-3250) is the tightening bottleneck` — directly downstream of the refresh boundary.

The closest prior test of paramEMA refresh boundary was thorfinn #1704 (STACKED refresh @ 2750/2850 on top of @2600 — bilateral NULL). That tested LATER refreshes additively. It did NOT test earlier refresh boundaries as REPLACEMENTS for the @2600 baseline.

The ema_beta schedule has a structural transition at step 1750: `ema_beta=0.97` (warmup) → `ema_beta_target=0.99` (target, activated at step 1750). Pre-step-1750 EMA history was accumulated under the rougher 0.97 rate; post-step-1750 under the slower 0.99. **A refresh at step 1750 wipes the regime-mismatched history at exactly the moment the slow 0.99 EMA starts accumulating** — structurally analogous to the β₂ pulse @ step 975 (where the slow β₂=0.99 takes over from 0.95 at cooldown onset).

## Why this isn't covered by past closures

| Prior PR | Mechanism | Scope | Result |
|---|---|---|---|
| #1532 (baseline) | paramEMA refresh @ 2600 (single) | full | WIN (baseline element) |
| #1704 thorfinn | paramEMA refresh STACKED @ 2750 + 2850 | additive on baseline @2600 | bilateral NULL |
| #1773 askeladd | paramEMA β step-drop @ pre-target | β-axis (not refresh) | bilateral NULL |
| **this PR** | **paramEMA refresh SINGLE @ 1750 / 2250 (REPLACES baseline @2600)** | **boundary ablation** | **NEW BOUNDARY TEST** |

This is the **first ablation of the baseline @2600 refresh boundary** in either direction (earlier or later). thorfinn #1704 only added LATER refreshes additively without changing the @2600 anchor.

## Mechanism

The paramEMA refresh logic (lines 1100-1104 of `train_gpt_simple.py`):
```python
if (args.paramema_refresh_step > 0
        and step == args.paramema_refresh_step):
    for ema_p, p in zip(ema_params, optimizer2.param_groups[0]["params"]):
        ema_p.copy_(p.detach().float())
    ema_refresh_fired_total = 1
    ema_refresh_step_logged = step
```

Each arm REPLACES the canonical `--paramema_refresh_step 2600` with a different value. **No code changes** — pure flag adjustment.

Mechanism interpretations by outcome:
- **Arm A WIN (@1750)**: ema_beta regime transition (0.97→0.99 @ step 1750) was leaving stale warmup-era history in the EMA buffer; eliminating it precisely at the activation boundary was the load-bearing intervention. 1500 steps of clean 0.99-only accumulation > 650 steps under baseline.
- **Arm B WIN (@2250)**: refresh sweet spot is in mid-cooldown, not at ema_target activation. 1000 steps of post-refresh accumulation is optimal vs baseline's 650.
- **Both regress**: @2600 is genuinely the singular optimum — confirms #1704 closure direction. Refresh boundary axis CLOSED.
- **Both improve**: refresh boundary is broadly forgiving as long as it's post-warmup; baseline @2600 is conservatively positioned and earlier is universally better.

## Arms

**Arm A — paramEMA refresh @ step 1750 (ema_target activation boundary, replaces baseline @2600)**
- `--paramema_refresh_only --paramema_refresh_step 1750`
- Mechanism: refresh fires at the same step as ema_beta_target activation (1750)
- Post-refresh accumulation: 1500 steps of pure 0.99 EMA history before terminal
- Tests: does eliminating regime-mismatched warmup history at the slow-EMA activation boundary unlock additional headroom?

**Arm B — paramEMA refresh @ step 2250 (mid-cooldown, replaces baseline @2600)**
- `--paramema_refresh_only --paramema_refresh_step 2250`
- Mechanism: refresh fires at the midpoint between ema_target activation (1750) and baseline refresh (2600)
- Post-refresh accumulation: 1000 steps of post-refresh 0.99 EMA history
- Tests: is the optimal refresh point earlier than baseline @2600?

## Implementation

**ZERO CODE CHANGES.** Pure flag substitution. The existing `--paramema_refresh_step` mechanism is reused as-is.

Verification sentinel in W&B logs:
- Arm A: `ema_refresh/fired` latches to 1 at step 1750 (visible at next log boundary)
- Arm B: `ema_refresh/fired` latches to 1 at step 2250
- Both: `ema_refresh/target_step` field should match the arm's refresh step

## Reproduce commands

**Arm A — paramEMA refresh @ step 1750 (REPLACES baseline @2600)**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 1750 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-fern-paramema-refresh-boundary \
  --wandb_name g1r1-fern/paramema-refresh-1750-arm-a
```

**Arm B — paramEMA refresh @ step 2250 (REPLACES baseline @2600)**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2250 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-fern-paramema-refresh-boundary \
  --wandb_name g1r1-fern/paramema-refresh-2250-arm-b
```

**Chain rule:** Single-GPU chain. Run Arm A first. If sr=2875 AND val_ema within 0.5 mnat of gate (val_ema < 3.263354), STOP and chain seed-2 of Arm A for n=2 confirmation BEFORE launching Arm B. Otherwise, chain Arm B immediately after Arm A terminates.

## Expected outcomes

**Arm A WIN (sr≤2862.5 OR sr=2875 with val_ema<3.262854):** The 0.97→0.99 ema_beta transition was leaving load-bearing stale history in the paramEMA buffer. Refresh @ ema_target activation is the new baseline boundary.

**Arm B WIN:** Mid-cooldown refresh outperforms both activation-boundary and pre-target boundaries. Refresh sweet spot is ~1000-step post-refresh accumulation window.

**Close near-miss either arm (sr=2875, val_ema within 0.5 mnat above gate):** Mechanism present but undersized — follow up with an even earlier boundary (e.g., @1250 — mid-warmup, before ema_target activation) for Arm A, or @1900 / @2100 for Arm B.

**Bilateral NULL (sr≥2925 OR both fail clause-2):** @2600 is the unique optimum for paramEMA refresh boundary. The mechanism is specifically tuned to the pre-target window and does NOT translate to earlier boundaries. Combined with #1704 (later stacking NULL), the refresh boundary axis is then CLOSED on both sides of @2600.

**Crash/divergence:** Extremely unlikely — the refresh mechanism is identical to the baseline, only the step differs. If it happens, report step and val_loss, do not retry without diagnosis.

## Constraints

- Use the unmodified baseline stack (muon_lr=0.040, ema_beta=0.97, late-higher, aux_b2_pulse @ 975) EXCEPT replace `--paramema_refresh_step 2600` with the arm-specific step.
- DO NOT use `--paramema_refresh_step 2600` (that's the baseline; we want to test alternatives).
- The pulse step (975) and target (0.99) for aux β₂ MUST match the canonical baseline.
- If Arm A produces a thin clause-2 PASS (val_ema < 3.262854 by <0.5 mnat), HOLD the merge and chain seed-2 of Arm A before launching Arm B — seed noise on thin margins has burned us repeatedly (#1605, #1637, #1850, #1780 Arm B).
- Post SENPAI-RESULT marker only after both arms terminate (or after Arm A wins decisively with n=2 confirmation).
