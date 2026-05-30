# HYPOTHESIS — fern — Body PMuon γ pulse at cooldown onset step 975 (symmetric body-side analog of #1532 aux β₂ WIN)

**Branch:** `g1r1-fern/body-pmuon-gamma-cooldown-pulse`
**Assigned:** 2026-05-30 13:25 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state regime shift at phase boundaries + (c) short phase-specific mechanism

## Why this hypothesis

The canonical β₂ pulse 0.95→0.99 on aux AdamW at step 975 is a CONFIRMED WIN (#1532). Its mechanism: at cooldown onset, the aux-side variance estimator switches to a longer-memory regime, stabilizing the adaptive denominator through cooldown.

The body PMuon side has an analogous load-bearing scalar at cooldown onset: **γ**, the whitening exponent in `L^{-γ} · g · R^{-γ}`. γ controls the SHARPNESS of the bilateral whitening. Default γ=0.4. Lower γ → closer to raw NS5 output (less aggressive whitening, more raw direction). Higher γ → sharper preconditioning (tighter direction estimate via L/R covariance).

**The hypothesis:** at cooldown onset (step 975), the gradient distribution shifts to a more stable, lower-noise regime. A γ pulse at this step would re-tune the whitening sharpness for the cooldown gradient distribution, analogous to how β₂ pulse re-tunes v's memory for cooldown.

**Mechanistic reasoning — two directions:**

1. **γ→0.3 (RELAX whitening).** Hypothesis: under cooldown LR decay, L and R EMAs continue to track shifting cooldown gradient stats. A SHARPER whitening (γ=0.4) over-precisions on the warmup-regime L/R estimates that haven't fully transitioned. Relaxing γ pulls the update closer to raw NS5 output — less reliant on the still-transitioning L/R. Mirrors the "shorter polar projection" intuition from #1739 (NS_ITERS closure showed polar accuracy ISN'T the bottleneck → but γ controls how much L/R correction is APPLIED to the polar projection, which is a magnitude/persistence channel).

2. **γ→0.5 (SHARPEN whitening).** Hypothesis: cooldown gradients become more concentrated; sharper whitening extracts more signal from cleaner L/R estimates. Under stable cooldown gradient regime, the sharper preconditioner doesn't carry warmup noise forward.

**Why distinct from prior γ work:**
- **nezuko #1680** (CLOSED): γ pulse at PRE-TARGET window (step ~2750) — bilateral NULL. Pre-target gradients are already cooldown-stable; γ change doesn't help there.
- This PR fires at COOLDOWN ONSET (step 975), which is structurally the moment when β₂ pulse WINS (#1532). The mechanism is symmetric: at this exact boundary, the optimizer state regime ought to shift.
- No prior γ test at step 975.

**Why distinct from in-flight body PMuon work:**
- **frieren #1780** (HOT, seed-2 pending): L_cov/R_cov ZERO RESET (state DISCARD, hyperparameter UNCHANGED). γ pulse is the opposite: state PRESERVED, hyperparameter SHIFTED. Orthogonal mechanism.
- **thorfinn #1797** (in-flight): body PMuon momentum buffer partial SCALE. Different state (momentum, not whitening).
- **alphonse #1788** (Arm A NULL, Arm B running): per-block μ depth-asymmetric. Different mechanism (per-block scalar, not whitening exponent).

## Experiment design

**Bilateral on γ pulse MAGNITUDE (cooldown-onset boundary fixed at step 975):**

- **Arm A — γ pulse 0.4 → 0.3** (relax whitening). Step toward raw NS5 output.
- **Arm B — γ pulse 0.4 → 0.5** (sharpen whitening). Step toward sharper preconditioner.

Both fire at step 975 alongside the existing β₂ pulse 0.95→0.99. γ is a permanent step-change held to terminal (same shape as canonical β₂ pulse).

**Critical:** γ pulse changes the HYPERPARAMETER (controlling future polar projection), NOT the L/R state. L/R carry forward seamlessly.

## Implementation guidance

Add CLI flags to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--body_muon_gamma_pulse_step", type=int, default=-1,
    help="Step at which to apply body PMuon γ pulse (-1 = disabled)",
)
parser.add_argument(
    "--body_muon_gamma_pulse_target", type=float, default=0.0,
    help="Target γ value after pulse (0.0 = unused; 0.3 or 0.5 for production)",
)
```

In the training loop, immediately AFTER the existing `aux_b2_pulse` block and BEFORE `optimizer2.step()`:

```python
if (args.body_muon_gamma_pulse_step > 0
        and step == args.body_muon_gamma_pulse_step):
    n_groups = 0
    old_gammas = []
    for group in optimizer2.param_groups:
        if "gamma" in group:
            old_gammas.append(group["gamma"])
            group["gamma"] = args.body_muon_gamma_pulse_target
            n_groups += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] body PMuon γ PULSE "
               f"target={args.body_muon_gamma_pulse_target:.4f} "
               f"(applied to {n_groups} param groups, prior values={old_gammas})",
               console=True)
        if wandb.run is not None:
            wandb.log({
                "body_gamma_pulse/step": step,
                "body_gamma_pulse/target": args.body_muon_gamma_pulse_target,
                "body_gamma_pulse/n_groups": n_groups,
            }, step=step)
```

**IMPORTANT:** Inspect `optimizer2.param_groups` for the EXACT key used to store γ — it may be `"gamma"`, `"polar_gamma"`, `"muon_gamma"`, or accessed via a param group attribute. Read `records/track_3_optimization/train_gpt_simple.py` body PMuon param group construction and the polar-projection step to find the canonical key. If γ is hardcoded in the optimizer's `step()` rather than stored per-group, surface this as a blocker — DO NOT silently rewrite the polar step. Comment back on this PR with the exact location, and I will redesign.

**Validation requirement before launch:** Run a 100-step smoke with `--body_muon_gamma_pulse_step 50 --body_muon_gamma_pulse_target 0.3`. Assert:
1. Sentinel `[step 50] body PMuon γ PULSE target=0.3000 (applied to N param groups, prior values=[0.4, ...])` fires (N=12 or however many body PMuon groups exist).
2. `body_gamma_pulse/target=0.3` appears in W&B summary.
3. Train_loss continues monotone within ±0.3 mnat at the pulse step (γ change is typically silent; if it spikes >1 mnat investigate before continuing).

## Reproduce commands

**Arm A (γ pulse 0.4 → 0.3 @ 975):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_gamma_pulse_step 975 --body_muon_gamma_pulse_target 0.3 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-fern-body-pmuon-gamma-cooldown-pulse \
  --wandb_name g1r1-fern/gamma-pulse-0.3-armA
```

**Arm B (γ pulse 0.4 → 0.5 @ 975):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_gamma_pulse_step 975 --body_muon_gamma_pulse_target 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-fern-body-pmuon-gamma-cooldown-pulse \
  --wandb_name g1r1-fern/gamma-pulse-0.5-armB
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT touch the β₂ pulse** — `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99` MUST be present in both arms.
- **Do NOT zero or scale L/R state** — that is frieren #1780's territory. This PR changes the γ HYPERPARAMETER only.
- **Do NOT change the firing step from 975** — symmetric with β₂ pulse is the entire mechanism.
- **Do NOT pulse γ to <0.2 or >0.6** — outside that window, the polar projection is either nearly raw NS5 (γ→0) or aggressively whitened (γ→1); we want a measured pulse, not a regime change.
- **Do NOT modify NS_ITERS, μ, β_cov, or LR** — those are different axes already closed.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate (γ=0.3 relax)** | Cooldown gradients benefit from RELAXED whitening; request seed-2. Follow-up: γ→0.2 (further relax) at same step. |
| **Arm B WIN merge gate (γ=0.5 sharpen)** | Cooldown gradients benefit from SHARPER whitening; request seed-2. Follow-up: γ→0.6 or γ→0.7. |
| **Both NULL, similar trajectory** | γ at cooldown onset is not load-bearing — symmetric mechanism on body side is NOT a free WIN. Combined with #1680 closure, **body PMuon γ axis FULLY CLOSED across pre-target AND cooldown-onset**. |
| **Arms diverge in direction (one improves, one regresses)** | The mechanism IS responsive but the optimal direction is non-trivial; depth study warranted. |
| **Either arm crashes/diverges** | γ change at cooldown is structurally destabilizing — likely the L/R EMAs are too out-of-distribution for the new γ to make sense; would close mechanism harder than NULL. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```

Post a milestone comment when Arm A passes step ~975 (confirm pulse fired + γ value read from optimizer state changed) and at ~50%/80% of Arm B.
