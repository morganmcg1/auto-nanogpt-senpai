# Research Ideas — 2026-05-31 (dual fresh hypotheses)

Generated for advisor branch `auto-nanogpt-1gpu-r5`.
Baseline: μ_4(FFS_ema) = 2912.5, σ_4 = 25. Merge gate: μ_4 ≤ 2887.5.
Mandatory stack: `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99`

---

## Hypothesis 1 — EMA Decay Cooldown Ramp

**Slug:** `ema-decay-cooldown-ramp`

**One-sentence hypothesis:**
Linearly ramping `ema_eval_decay` upward from 0.99 toward 0.9999 during the cooldown phase (steps 975–3250) makes the EMA weight more heavily concentrate on the final high-quality end-of-training snapshots rather than averaging broadly over the entire cooldown trajectory, improving FFS_ema by ≥ 50 steps.

**Mechanism story:**
The current EMA eval uses a fixed decay `d = 0.99` applied at every validation event. The EMA weight on a checkpoint `t` steps in the past is proportional to `d^t`. With `d = 0.99`, the EMA has an effective half-life of ~70 steps — meaning weight snapshots from more than ~300 steps ago have negligible contribution. During cooldown (30% of training = 975 steps for train_steps=3250), the model converges rapidly toward the target loss basin. This is desirable. But with constant `d = 0.99`, the EMA also tracks every intermediate "mid-cooldown" snapshot at nearly equal weight, introducing noise from the early cooldown phase when the model is still far from converged.

Ramping `d` upward during cooldown — e.g. from 0.99 at step 975 to 0.9999 at step 3250 linearly — increases the EMA's half-life as cooldown progresses. By the final 200 steps, `d = 0.9999` gives a half-life of ~6931 steps, so the EMA effectively tracks only the most recent few checkpoints with high weight. This means: (1) the bias-corrected EMA `(ema - d^t * init) / (1 - d^t)` concentrates its mass on the best end-of-cooldown weights; (2) the FFS_ema threshold crossing happens earlier because the EMA more faithfully reflects the current model quality rather than a smeared average over the whole cooldown history.

This is distinct from all closed axes: it operates entirely on the **eval readout path** (no change to optimizer, training dynamics, gradients, or any parameter update). The NS5-absorption family acts on the optimizer; the SOAP preconditioning family acts on the momentum update; this acts on neither. The `ema_eval_decay` scalar exists as a flag and is referenced in `set_hparams` and EMA state initialization — so the ramped version is a pure additive change.

**Implementation surface:**
- Add `--ema_decay_cooldown_target` float flag (default = `args.ema_eval_decay`, i.e. no ramp = backward compatible).
- In `set_hparams`, when cooldown is active (`step >= cooldown_start_step`), compute `p_cooldown = (step - cooldown_start_step) / (train_steps - cooldown_start_step)` and interpolate `effective_decay = args.ema_eval_decay + p_cooldown * (args.ema_decay_cooldown_target - args.ema_eval_decay)`.
- Before the EMA update loop (the lines `ema_state[n] = d * ema_state[n] + (1-d) * p.data`), replace fixed `d = args.ema_eval_decay` with `effective_decay` from above.
- Log `effective_decay` to W&B under `train/ema_decay_effective`.
- Approximately 12 LOC additive.

**Cells:**

| Cell | Config | Purpose |
|------|--------|---------|
| A_ctrl | Mandatory stack, `ema_eval_decay=0.99`, no ramp | Baseline (matches existing baseline) |
| B★ | Mandatory stack + `ema_decay_cooldown_target=0.9999` | Primary probe: ramp 0.99→0.9999 over cooldown |
| C | Mandatory stack + `ema_decay_cooldown_target=0.999` | Softer ramp (0.99→0.999) — distinguish sensitivity |
| D | Mandatory stack + `ema_decay_cooldown_target=0.99999` | Aggressive ramp (0.99→0.99999) — upper bound |

Run A+B at n=1 first. If B★ FFS_ema ≤ 2875 (not the seed-noise attractor *and* val_loss Δ outside ±0.005), escalate to n=4 on B★. Run C and D only if B★ is alive.

**Signal gate:**
- n=1 alive: FFS_ema(B★) ≤ 2875 **AND** val_loss(B★) < val_loss(A_ctrl) - 0.005 (exclude attractor).
- n=4 merge gate: μ_4(FFS_ema) ≤ 2887.5.
- Falsifying result: FFS_ema(B★) ≥ FFS_ema(A_ctrl) or val_loss delta within ±0.003.

**Pre-mortem:**
- The EMA bias correction `(ema - d^t * init) / (1-d^t)` already partially compensates for the changing effective window — but it compensates for initialization bias, not for trajectory smearing. The ramp changes the trajectory weighting, which the bias correction does not undo.
- If model weights are nearly converged by step 975 already (loss plateau early), then end-of-cooldown snapshots and mid-cooldown snapshots are nearly identical → negligible gain.
- If `d` ramps too fast, the EMA becomes nearly an instantaneous readout at the final step, equivalent to no EMA smoothing at all → could increase variance between runs rather than decrease it.
- The intervention only affects val, not train → zero risk of destabilizing training. If it fails, cost is one screening run.

**Freshness justification:**
No prior R5 closure touched `ema_eval_decay` scheduling (the 88 closures cover optimizer, schedule, init, and NS5 interactions). The `ema_eval_decay` flag is a fixed constant in all prior and current runs. This is a readout-path intervention with zero training dynamics footprint. Not in any closed axis family. Not in any WIP axis (#1988 adamw-beta1-cooldown, #1989 aux-cooldown-shape-decoupling, #1979 lr-warm-restart-probe, #1983 wd-schedule-ablation, #1948 precond_freq-cooldown, #1966 frieren).

---

## Hypothesis 2 — Muon Momentum Reset at Cooldown Start

**Slug:** `muon-momentum-cooldown-reset`

**One-sentence hypothesis:**
Zero-resetting all Muon momentum buffers exactly at cooldown_start (step 975) removes the stale warm-phase velocity accumulated over the first 70% of training, allowing the cosine LR decay to drive convergence cleanly from a fresh gradient signal rather than fighting stale momentum inertia, improving FFS_ema by ≥ 50 steps.

**Mechanism story:**
The Muon optimizer accumulates a momentum buffer `state["momentum"]` for each parameter group. This buffer is initialized at zero and updated every step: `state["momentum"].lerp_(grad, 1 - muon_momentum)` (where `muon_momentum` defaults to 0.95). After 975 warm-training steps, these buffers carry an exponentially weighted average of gradients from the entire warm phase, representing the model's "velocity" direction in weight space.

At cooldown_start, the LR begins cosine decay from its peak. The momentum buffer now interacts with the decaying LR in a non-trivial way: the stored velocity from late warm-phase gradients (which pointed toward rapid loss descent) continues to inject a directional bias into the early cooldown steps, even as the LR is ramping down. If the optimal cooldown trajectory in weight space is geometrically different from the warm-phase descent direction — which is plausible because the loss surface near the 3.28 threshold is flatter and more curved — then stale momentum will push the model along the wrong directions during the critical early cooldown phase, causing it to oscillate or overshoot the basin before the low LR finally damps it out.

A one-time zero-reset of all Muon momentum buffers at `step == cooldown_start` removes this inertia. The optimizer then re-accumulates momentum purely from cooldown-regime gradients, which are smaller and more basin-local. This is conceptually similar to "learning rate warm-up restart" (SGDR / warm restarts) but applied to the momentum state rather than the LR schedule, and applied only once (at cooldown_start) rather than periodically.

This is distinct from all closed axes: the NS5 absorption family operates on pre/post-Newton-Schulz perturbations; the μP depth-LR axis is closed; the GC/GE-SAM family is closed. None of these involve resetting momentum buffers at a specific phase transition. The edward #1948 precond_freq-cooldown is the closest active WIP, but it modifies the SOAP eigenbasis refresh frequency during cooldown — a fundamentally different mechanism (preconditioner state) than the Muon momentum buffer state. No closed PR has tested momentum state manipulation at phase transitions.

**Implementation surface:**
- Add `--muon_momentum_cooldown_reset` bool flag (default False = backward compatible).
- In the training loop, after computing `cooldown_start_step = round((1 - args.cooldown_frac) * train_steps)`, add a one-time reset block:
  ```python
  if args.muon_momentum_cooldown_reset and step == cooldown_start_step:
      for group in optimizer2.param_groups:
          for p in group["params"]:
              if p in optimizer2.state and "momentum" in optimizer2.state[p]:
                  optimizer2.state[p]["momentum"].zero_()
  ```
- Log the reset event to W&B: `wandb.log({"train/muon_momentum_reset": 1}, step=step)` once at the reset step.
- Approximately 10 LOC additive.

**Cells:**

| Cell | Config | Purpose |
|------|--------|---------|
| A_ctrl | Mandatory stack, `muon_momentum_cooldown_reset=False` | Baseline (matches existing baseline) |
| B★ | Mandatory stack + `muon_momentum_cooldown_reset=True` | Primary probe: one-time reset at step 975 |
| C | Mandatory stack + `muon_momentum_cooldown_reset=True` + `cooldown_frac=0.40` | Reset at step 800 — earlier intervention |
| D | Mandatory stack + reset=True + `muon_momentum` reduced to 0.90 after reset | Lower post-reset momentum — faster re-accumulation |

Run A+B at n=1 first. Escalate to n=4 on B★ if signal gate passes.

**Signal gate:**
- n=1 alive: FFS_ema(B★) ≤ 2875 **AND** val_loss(B★) < val_loss(A_ctrl) - 0.005 (exclude attractor).
- Check `train/loss` trajectory around step 975: expect a brief loss plateau or slight uptick immediately after reset (1–3 steps), then steeper descent. Absence of this signature suggests the reset is not activating correctly.
- n=4 merge gate: μ_4(FFS_ema) ≤ 2887.5.
- Falsifying result: FFS_ema(B★) ≥ FFS_ema(A_ctrl), or loss spikes at step 975 without recovery within 50 steps.

**Pre-mortem:**
- If warm-phase momentum is actually well-aligned with the cooldown descent direction, the reset wastes the accumulated velocity signal and hurts convergence speed early in cooldown → FFS regression.
- The reset interacts with SOAP: `soap_precondition_momentum` operates on the momentum buffer after the NS5 step. If momentum is zero'd, the first preconditioned update is purely based on the current gradient with no smoothing → higher variance. May manifest as a brief loss spike at step 975 visible in `train/loss`.
- Cooldown starts at step 975 = 30% of 3250. If the model is not yet near the target at step 975, a momentum reset delays the early-cooldown descent, potentially making FFS worse for slow-converging seeds.
- The `soap_step` counter and SOAP eigenbasis state are **not** reset — only the Muon momentum buffer. If the eigenbasis is stale and momentum is zeroed simultaneously, the preconditioner may apply a poorly aligned correction on the first post-reset steps. Can be diagnosed from `train/grad/all/*` telemetry showing a brief spike then decay.

**Freshness justification:**
Zero of the 88 R5 closures reset optimizer state at a phase transition. The warmup-restart literature (Loshchilov & Hutter SGDR, 2017) applies LR restarts to schedule — no prior PR applied state resets to the momentum buffer specifically. The NS5 absorption family operates on gradient preprocessing before momentum accumulation; this operates on the accumulated momentum state itself. The edward #1948 SOAP precond_freq cooldown modifies eigenbasis refresh cadence, not the momentum buffer. Not in any WIP or closed axis family. Distinct mechanism with falsifiable training-loss signature.

---

## Ranking and Recommendation

**Preferred order for assignment:** Hypothesis 2 (muon-momentum-cooldown-reset) first, then Hypothesis 1 (ema-decay-cooldown-ramp).

Rationale: Hypothesis 2 has a falsifiable training-loss signature (brief loss plateau at step 975) that allows early diagnosis within the first 50 post-cooldown steps, providing a cheap mechanism check before the full run cost. Hypothesis 1 operates purely on the eval path and has no early-training diagnostic signal — it must run to at least the first FFS_ema val event to know if the mechanism is alive. Both are ≤30 LOC additive, both are ≤6 hours, both are outside all 88 closed axes and all 6 active WIP axes.
