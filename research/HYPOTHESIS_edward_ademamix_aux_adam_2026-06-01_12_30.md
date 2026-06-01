# HYPOTHESIS — edward: AdEMAMix dual-EMA on AUX Adam (embeddings + lm_head + biases/LNs)

**Status:** ASSIGNED 2026-06-01 12:30 UTC
**Student:** g1r1-edward
**PR:** TBD

## Mechanism

AdEMAMix (Pagliardini et al., 2024 — https://arxiv.org/abs/2409.03137) replaces the single-EMA first moment in Adam with **two parallel EMAs at different timescales**: a fast EMA `m1` (β₁=0.9) and a very-slow EMA `m2` (β₃=0.9999). The update direction is then a blend `α·m1 + (1-α)·m2` (or equivalent additive form). The slow EMA captures long-horizon directional consistency; the fast EMA tracks recent gradient information. The key empirical finding is that traditional Adam with a single fast-EMA discards the slow signal entirely — but the slow signal is genuinely informative for language modeling, especially during cooldown.

**Prior testing on this branch:**
- thorfinn #1749 tested AdEMAMix on BODY Muon (dual-EMA on the Muon `momentum_buffer`). **BILATERAL NULL.** Body Muon's polar-projection step (Newton-Schulz5) likely flattens the multi-timescale information because NS5 normalizes the input to ~orthogonal — losing magnitude info that the slow EMA encoded.
- AdEMAMix on AUX Adam (embeddings + lm_head + biases + layer_norms) has **never been tested.** Aux Adam doesn't go through any polar projection — the m̂_t / √(v̂_t + eps) update faithfully preserves whatever the multi-timescale m encodes. This is the structurally appropriate scope for AdEMAMix.

**Why aux Adam is the right scope:**
1. Aux Adam covers ~6% of model params (embed + lm_head + LNs + biases) but they're high-signal — embedding rows have very sparse update patterns (each row sees gradient ~B/V steps where V=50k, B=batch); lm_head rows have similarly sparse updates. Long-horizon EMA is mechanically more appropriate for sparse-update params than fast-EMA.
2. Aux Adam param updates are NOT whitened/projected — multi-timescale information passes through to the parameter step.
3. The aux β₂ pulse @ step 975 (0.95→0.99) is already in baseline — confirms aux Adam β-axis is non-trivially load-bearing at the cooldown boundary. Dual-EMA is a richer perturbation of the same dimension.

This is directive #1252 (d): momentum/preconditioner state handling — applied to the previously-untested aux-side momentum state.

## Bilateral arm design

Both arms add a slow second EMA `m2` to AUX Adam params only (do NOT touch body Muon). They differ in the mixing weight α between fast and slow EMAs.

- **Arm A** (mild mix, α=0.85 fast / 0.15 slow): conservative slow-signal injection. The fast EMA still dominates; slow EMA contributes 15% of the update direction. Tests whether even small slow-EMA injection helps.
- **Arm B** (balanced mix, α=0.50 fast / 0.50 slow): aggressive slow-signal weighting. Tests whether the slow EMA is genuinely co-equal in informativeness, or whether the slow term overpowers and tanks convergence.

Both arms use β₁=0.9 (canonical fast), β₃=0.9999 (canonical AdEMAMix slow). The β₂ pulse @975 baseline behavior is preserved unchanged.

## Predictions

| outcome | interpretation |
|---|---|
| Arm A clean WIN, Arm B NULL/regress | Slow-EMA helps in small dose. Optimal α likely between 0.85 and 0.95. Trigger seed-2 then narrow α. |
| Arm B clean WIN, Arm A NULL | Slow-EMA is dominantly informative. α optimum near 0.50 or lower (more slow). Trigger seed-2. |
| Both clean WIN | AdEMAMix on aux is broadly beneficial. Pick best, seed-2 confirm, merge. |
| Arm A NULL, Arm B catastrophic (val_ema +5+ mnat) | Slow-EMA overpowers in aggressive mixing. Mechanism class is real but α=0.5 is too aggressive. Worth a third arm at α=0.95 if Arm A is close. |
| Both NULL | AdEMAMix benefit doesn't transfer to aux Adam at this model scale / cooldown schedule. Adds aux-AdEMAMix to closed matrix; mechanism class is structurally not load-bearing here. |

## Implementation sketch

In `train_gpt_simple.py`, modify the aux Adam optimizer's state and step logic to track a second EMA `m2` and use the blend.

```python
# CLI flags
parser.add_argument('--aux_ademamix_alpha', type=float, default=-1.0,
                    help='Aux Adam dual-EMA mix weight (alpha) for fast EMA. -1.0 disables AdEMAMix. '
                         'Update = alpha * m1_hat + (1-alpha) * m2_hat. Body Muon NOT affected.')
parser.add_argument('--aux_ademamix_beta3', type=float, default=0.9999,
                    help='Slow EMA beta for aux AdEMAMix m2. Canonical 0.9999.')

# In aux Adam step (or wherever the aux optimizer's step lives — typically a custom Adam class
# or torch.optim.AdamW):
# Initialize state['m2'] = torch.zeros_like(p) lazily on first encounter
# Existing: m1 = beta1 * m1 + (1-beta1) * g  ; v = beta2 * v + (1-beta2) * g**2
# Add:
#   if args.aux_ademamix_alpha > 0:
#       m2 = state.get('m2', torch.zeros_like(p))
#       m2 = beta3 * m2 + (1 - beta3) * g
#       state['m2'] = m2
#       m1_hat = m1 / (1 - beta1**t)        # bias-corrected fast
#       # m2 bias correction: 1 / (1 - beta3**t), but for beta3=0.9999 this term is ~t*1e-4 for t<10000
#       m2_hat = m2 / (1 - beta3**t)
#       v_hat = v / (1 - beta2**t)
#       update_num = args.aux_ademamix_alpha * m1_hat + (1 - args.aux_ademamix_alpha) * m2_hat
#       p.data.addcdiv_(update_num, v_hat.sqrt().add_(eps), value=-lr)
#   else:
#       # original Adam path
```

**Critical scoping note:** The flag must affect ONLY the aux Adam optimizer (covering embed + lm_head + biases + layer_norms). The body Muon optimizer must remain untouched. Find the aux optimizer's identification path in the current `train_gpt_simple.py` (likely something like `optimizer1` or `aux_optimizer` — verify before coding).

**Sentinel print at step 1:**
```python
if args.aux_ademamix_alpha > 0:
    print0(f"[step 1] aux AdEMAMix ENABLED: alpha={args.aux_ademamix_alpha:.3f}, beta3={args.aux_ademamix_beta3:.4f}", console=True)
```

## Reproduce commands

**Full baseline stack required on both arms.**

### Arm A — α=0.85 (mild mix)

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_ademamix_alpha 0.85 --aux_ademamix_beta3 0.9999 \
  --wandb_group g1r1-edward-aux-ademamix \
  --wandb_name g1r1-edward/aux-ademamix-arm-a-alpha-085
```

### Arm B — α=0.50 (balanced mix)

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_ademamix_alpha 0.50 --aux_ademamix_beta3 0.9999 \
  --wandb_group g1r1-edward-aux-ademamix \
  --wandb_name g1r1-edward/aux-ademamix-arm-b-alpha-050
```

**Chain rule:** Arm A first. Launch Arm B after Arm A `wandb.finish()` AND training process exit. Use the `pgrep`+`flag-file`+`settle` guarded-chain pattern.

**Seed-2 trigger:** If either arm achieves `sr ≤ 2875 AND val_ema < 3.262854`, launch a seed-2 confirmation run before posting terminal SENPAI-RESULT.

## Baseline (PR #1532)

- **speedrun/final_first_step_to_target:** 2875 (n=2)
- **ema/val_loss_ema:** 3.262854 (n=2 mean)
- **Gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
- **W&B baseline runs:** `9coyk2ke` (seed-1), `09qrijtm` (seed-2)

## Sentinel verification

Expected stdout log line at step 1 (rank 0):
- Arm A: `[step 1] aux AdEMAMix ENABLED: alpha=0.850, beta3=0.9999`
- Arm B: `[step 1] aux AdEMAMix ENABLED: alpha=0.500, beta3=0.9999`

Verify on W&B that body Muon `momentum_buffer` histograms are IDENTICAL to baseline (confirming body Muon is untouched). Only aux Adam state should differ.

## SENPAI-RESULT format

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA>","<armB>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<int>},"test_metric":{"name":"ema/val_loss_ema","value":<float>}}
```

Use the run with the BEST primary_metric (lower sr is better). If both arms tie on sr, use the lower val_ema.

## Why this assignment for edward

- edward has just closed the body PMuon mom-state work (#2040 shallow-DECAY exhausted at n=2). Pivoting OFF body-mom to a structurally distinct scope (aux Adam) avoids further depth/factor sweeps on an exhausted axis.
- AdEMAMix on aux Adam is the cleanest pristine multi-timescale-momentum hypothesis in our matrix — body-side was tested (#1749 NULL) but aux-side is untouched.
- edward has demonstrated ability to write clean optimizer state extensions (he implemented adashift, multi-EMA reset, depth-stratified decay) — AdEMAMix dual-EMA is well within his code expertise.
- Directive (d) momentum/preconditioner state handling on the previously-untested optimizer scope.
