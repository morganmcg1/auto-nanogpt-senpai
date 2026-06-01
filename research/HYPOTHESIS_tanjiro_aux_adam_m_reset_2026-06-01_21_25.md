---
student: g1r1-tanjiro
branch: auto-nanogpt-1gpu-r1
assigned: 2026-06-01 21:25 UTC
directive_alignment: (a) optimizer-state at phase boundaries
---

# Hypothesis: AUX-Adam first-moment (m) HARD-ZERO RESET — bilateral boundary @ 2750 vs @ 1750

## Background

PR #2115 (tanjiro, just closed) bilaterally closed BODY-Muon momentum reset @ 2750:
- Arm A (pure hard-zero @ 2750): sr=2925 (+50), val_ema=3.265256 (+2.40e-3) — NULL
- Arm B (hard-zero + μ=0.85 refractory 2750-2900): sr=2950 (+75), val_ema=3.267498 (+4.64e-3) — NULL

This combined with previously-closed body-Muon μ-modulation @ 2750 (fern #1604, askeladd #1686) leaves the @2750 BODY-Muon momentum state pulse-axis bilaterally exhausted: load-bearing across all known disturbance modes.

Tanjiro's own suggested follow-up #4 (verbatim from #2115 SENPAI-RESULT):
> "Reset embed/lm_head only (not body Muon) — The body Muon momentum is provably load-bearing here. The head/embed optimizers use a different optimizer (likely Adam) with different state semantics. Resetting their momentum at the pre-target boundary may behave differently."

The aux Adam optimizer handles `embed.weight` and `lm_head.weight` (and any other non-block parameters). It maintains separate first-moment (m) and second-moment (v) buffers. These two scopes (body Muon vs aux Adam) play different roles in the model:
- **Body Muon** updates the residual stack weights — directional content of the network
- **Aux Adam** updates the input/output projection — token-level representation alignment

The momentum buffers serve different functions. Body Muon's μ=0.95-weighted history is load-bearing for direction convergence. Aux Adam's m-buffer (β₁=0.95-weighted) is for embed/lm_head — which receive sparse gradient signal (per-token) and may have very different state dynamics.

**KEY untested question:** Is aux Adam first-moment also load-bearing at the pre-target boundary, or does it differ structurally from body Muon?

## Hypothesis

**If aux Adam m-buffer is structurally analogous to body Muon momentum** → hard-zero reset @ 2750 will hurt aux Adam convergence the same way it hurt body Muon: sr regresses by ~50, val_ema worsens by ~2-3 mnat.

**If aux Adam m-buffer is NOT load-bearing at the pre-target boundary** → reset is neutral or BENEFICIAL: stale per-token momentum gets flushed, and re-accumulation from current gradients yields better embed/lm_head alignment for the final ~250 steps.

**Boundary effect:** Reset at @1750 (the `ema_warmup_steps` phase boundary, before the cooldown phase begins) vs @2750 (deep pre-target window) tests WHICH PHASE the aux Adam state matters for. If @1750 hurts but @2750 is neutral → aux Adam state matters during cooldown buildup. If @2750 hurts but @1750 is neutral → aux Adam state matters only deep into pre-target window.

Bilateral asymmetric outcomes are most informative.

## Implementation

**Add two new CLI flags** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument("--aux_adam_m_reset_step", type=int, default=-1,
                    help="Step at which to hard-zero the aux-Adam first-moment (m) buffer. "
                         "-1 disables (default; matches baseline bit-exactly). "
                         "Applies to ALL parameters in the aux Adam param group "
                         "(embed.weight, lm_head.weight, any other non-block params).")
parser.add_argument("--aux_adam_v_reset", action="store_true",
                    help="If set together with --aux_adam_m_reset_step, ALSO hard-zero "
                         "the second-moment (v) buffer at the same step. "
                         "Off by default (m-only reset preserves variance estimate).")
```

**Add the reset hook** in the training loop, immediately after `optimizer1.step()` (or wherever the aux Adam step is taken). Reference the existing body-Muon hard-zero reset code from PR #2115 as the canonical pattern. Apply via:

```python
if args.aux_adam_m_reset_step >= 0 and step == args.aux_adam_m_reset_step:
    for group in aux_optimizer.param_groups:
        for p in group['params']:
            state = aux_optimizer.state.get(p, {})
            if 'exp_avg' in state:
                state['exp_avg'].zero_()
            if args.aux_adam_v_reset and 'exp_avg_sq' in state:
                state['exp_avg_sq'].zero_()
    # sentinel log
    if step == args.aux_adam_m_reset_step:
        n_reset = sum(1 for g in aux_optimizer.param_groups for p in g['params']
                      if 'exp_avg' in aux_optimizer.state.get(p, {}))
        print(f"[step {step}] aux_adam_m_reset: zeroed {n_reset} m-buffers "
              f"(v_reset={args.aux_adam_v_reset})")
```

Note the exact attribute names depend on the torch/Adam implementation. If it's a custom NormalizedAdam, inspect `state.keys()` at step 0 to find the correct buffer names. The body-Muon reset code from tanjiro #2115 (`--muon_momentum_reset_step`) is the canonical reference pattern.

**Sentinel logging at step 0** alongside existing aux Adam config logs:

```python
wandb.log({
    "optim/aux_adam_m_reset_step": args.aux_adam_m_reset_step,
    "optim/aux_adam_v_reset": int(args.aux_adam_v_reset),
}, step=0)
```

**Sentinel logging at reset step:**

```python
wandb.log({
    "optim/aux_adam_m_reset_executed": 1,
    "optim/aux_adam_m_reset_step_actual": step,
    "optim/aux_adam_n_buffers_zeroed": n_reset,
}, step=args.aux_adam_m_reset_step)
```

**CRITICAL backward-compat check**: With NO flag set (`--aux_adam_m_reset_step -1`), trajectory MUST be bit-exact baseline. Run 50 training steps and confirm loss matches baseline #1532 before launching arms.

## Arms

### Arm A — aux Adam m-reset @ 2750 (PRE-TARGET boundary, m-only)

Same boundary as body Muon Arm A from #2115. Tests whether aux Adam responds analogously to body Muon at the pre-target window.

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_m_reset_step 2750 \
  --wandb_group g1r1-tanjiro-aux-adam-m-reset \
  --wandb_name g1r1-tanjiro/aux-adam-m-reset-2750-arm-a
```

### Arm B — aux Adam m-reset @ 1750 (EMA WARMUP boundary, m-only)

Reset at the `ema_warmup_steps` boundary (start of EMA cooldown phase). Tests whether the aux Adam state matters during cooldown buildup rather than only deep pre-target.

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_adam_m_reset_step 1750 \
  --wandb_group g1r1-tanjiro-aux-adam-m-reset \
  --wandb_name g1r1-tanjiro/aux-adam-m-reset-1750-arm-b
```

## Baseline gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline #1532: n=2 mean sr=2875, val_ema=3.262854.

## Expected outcomes

- **Arm A WIN (m-reset @2750):** Aux Adam first-moment is NOT load-bearing at pre-target; the per-token momentum gets stale and resetting it improves embed/lm_head alignment. Sharp structural asymmetry vs body Muon. Follow-up: try m+v dual reset (set `--aux_adam_v_reset`), or bracket reset step (2600/2700/2800).
- **Arm B WIN (m-reset @1750):** Aux Adam state matters at the cooldown-onset boundary, not the pre-target boundary. Follow-up: try resetting at @975 (aux β₂ pulse boundary, even earlier).
- **Bilateral NULL:** Aux Adam m-buffer is also load-bearing at both pre-target AND cooldown boundaries — same as body Muon. Closes the aux Adam m-reset axis. Combined with #2115 confirms momentum state is universally load-bearing in the pre-target window. Pivot to m+v dual reset OR momentum SCALE-DOWN (×0.5/×0.1) bridging hard-zero and decay.
- **Both arms HURT BUT differently:** Asymmetric NULL ranking informs which boundary matters more for aux Adam.

## Chain rule

1. **Implement** `--aux_adam_m_reset_step` and `--aux_adam_v_reset` flags.
2. **Verify** with no flag set, run is bit-exact baseline (50-step smoke).
3. **Launch Arm A (@2750) first.**
   - Clear NULL (val_ema worse than baseline by >2 mnat at sr=2875+) → launch Arm B immediately.
   - WIN candidate → seed-2 of WIN before Arm B.
4. Both arms terminal → post terminal SENPAI-RESULT and stop. Do NOT chain into follow-up brackets without advisor approval.

## Why this aligns with directive (a)

Directive (a) is "optimizer-state at phase boundaries". This PR tests an UNTESTED optimizer (aux Adam) at TWO phase boundaries (cooldown-onset @1750, pre-target @2750). Following the bilateral closure of body-Muon @ 2750 (PR #2115), aux Adam is the natural next scope to test on the same axis. The two arms together probe both WHICH OPTIMIZER and WHICH BOUNDARY matters most.

## Notes

- The aux Adam optimizer in this codebase is likely `NormalizedAdam` or a custom variant. Verify the exact state dict key names at step 0 before launching arms — `exp_avg` (m) and `exp_avg_sq` (v) are the standard torch.optim.Adam names but a custom optimizer may differ.
- If `aux_optimizer` is split into multiple optimizers (one for embed, one for lm_head), reset ALL of them. The hypothesis tests aux-scope-wide reset, not selective.
- The body Muon `--muon_momentum_reset_step` flag from #2115 was merged but reverted (PR closed bilateral NULL). The flag may still be in the codebase as dead code; if so, follow the same implementation pattern but for the aux Adam path. If the flag was removed in the close-up, re-add the body-Muon reset path as well for parity, but ONLY trigger it when explicitly set (-1 default = no-op = bit-exact baseline).
- For Arm A (@2750), expected behavior if aux Adam IS analogous: post-reset val bumps then converges slightly above baseline trajectory, sr=2925 NULL like body Muon. If aux Adam is NOT analogous: post-reset val dips below baseline trajectory (FASTER convergence) and sr improves.
- Watch for divergence in the 50 steps immediately after the reset — if val_loss spikes by >20e-3, flag and stop early.
- This is a DIRECT followup to #2115. Use the same baseline stack (#1532) in both arms. Keep all other hyperparameters fixed.
