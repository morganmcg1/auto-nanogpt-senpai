---
student: g1r1-askeladd
branch: auto-nanogpt-1gpu-r1
assigned: 2026-06-01 15:45 UTC
directive_alignment: (c) short phase-specific + (d) momentum/preconditioner state handling
---

# Hypothesis: Cautious Updates (cAdam) on aux Adam — bilateral PERMANENT vs TRANSIENT @ step 975

## Background

The aux Adam optimizer has been EXHAUSTIVELY probed across SCALAR perturbations:
- β₁ pulse UP/DOWN @975 — bilateral NULL (#1592, #1639, #1819, #2082)
- β₂ pulse joint @975 — IS THE BASELINE WIN (#1532)
- β₂ pulse param-group decomposition (embed-only / lm_head-only) — bilateral NULL (#2086, just closed)
- β₂ pulse timing sweep — all NULL except canonical @975 (#1915, #1987)
- m-state HARD-ZERO / DECAY / FRESH-START across all magnitudes + boundaries (975/2600/2750) — all NULL (#1815, #1881, #1830, #1879, #1934)
- v-state HARD-ZERO / DECAY across all magnitudes + boundaries — all NULL (#1770, #1830, #1962, #2053)
- LR DECAY scalar/embed/joint @975 — all NULL (#1850, #1868, #1899)
- LR step-down (×0.85, ×0.70) — close near-misses but NULL (#1877)

These are all **PARAMETER PERTURBATIONS** of the state arithmetic. We have NEVER tested a **CONDITIONAL UPDATE RULE** modification — i.e., a structural change that suppresses updates based on a per-element predicate.

The **Cautious Updates** trick (Liang et al. 2024, "Cautious Optimizers: Improving Training with One Line of Code") masks out Adam updates where the running average direction disagrees with the current gradient sign:

```python
m_hat = m / (1 - β₁^t)
v_hat = v / (1 - β₂^t)
mask = (sign(m_hat) == sign(grad)).float()
effective_update = mask * m_hat / (sqrt(v_hat) + eps)
```

The masked-out coordinates effectively skip their update for that step. Published evidence: 1.47× speedup on transformer pre-training (GPT-2 124M) at same final loss, with zero hyperparameter retuning. Mechanism: when m_hat sign ≠ grad sign, the Adam update is moving AGAINST the current local gradient signal (relic of stale momentum); skipping reduces noise injection and improves trajectory alignment.

This is a structurally distinct intervention from every prior aux Adam test — it modifies the UPDATE RULE not the STATE ARITHMETIC.

## Hypothesis

Cautious Updates on aux Adam (JOINT scope across embed + lm_head + scalars + biases/LNs) will improve target-crossing speed by reducing noise injection from stale-momentum updates, especially through the cooldown phase where local gradient signal is concentrated near the loss minimum.

Two activation regimes are bilateral-tested:

- **Arm A (PERMANENT cAdam from step 0):** Full-training application — tests whether cautious masking benefits warmup + cooldown jointly.
- **Arm B (TRANSIENT cAdam @ step 975 activation):** Phase-specific application mirroring the baseline β₂ pulse timing — tests whether cAdam is purely a cooldown-phase mechanism, orthogonal to the baseline β₂ pulse.

## Implementation

Add new CLI flags:
- `--caut_aux_enabled` (bool, default False)
- `--caut_aux_activation_step` (int, default 0 = permanent; positive int = transient activation)
- `--caut_aux_scope` (str, default "joint" — applies to all aux Adam groups)

Modify aux Adam step function:

```python
# In the aux Adam update loop (after computing m, v):
if args.caut_aux_enabled and step >= args.caut_aux_activation_step:
    m_hat = m / bias_correction1
    v_hat = v / bias_correction2
    mask = (torch.sign(m_hat) == torch.sign(grad)).float()
    update = mask * m_hat / (torch.sqrt(v_hat) + eps)
else:
    # canonical Adam
    update = m_hat / (sqrt(v_hat) + eps)
p.data.add_(-lr * update)
```

Sentinel logs:
- At step 0 (Arm A) or step 975 (Arm B): print `[step <N>] caut_aux ENABLED: scope=joint, activation_step=<N>`
- Every 100 steps after activation: log `caut_aux/mask_fraction` per group (fraction of coordinates retained)

## Arms

### Arm A — PERMANENT cAdam from step 0

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --caut_aux_enabled --caut_aux_activation_step 0 \
  --wandb_group g1r1-askeladd-caut-aux \
  --wandb_name g1r1-askeladd/caut-aux-permanent-arm-a
```

### Arm B — TRANSIENT cAdam activated @ step 975

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --caut_aux_enabled --caut_aux_activation_step 975 \
  --wandb_group g1r1-askeladd-caut-aux \
  --wandb_name g1r1-askeladd/caut-aux-transient-975-arm-b
```

## Baseline gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline #1532: aux Adam β₂ pulse 0.95→0.99 @ step 975. n=2 mean sr=2875, val_ema=3.262854.

## Expected outcomes

- **WIN scenario:** One or both arms produces sr ≤ 2862.5 OR (sr=2875 with val_ema < 3.262854). Mechanism interpretation: cautious masking reduces gradient noise during the cooldown phase, allowing the val_loss to descend below target earlier. Arm B succeeding without Arm A would isolate cAdam as a cooldown-specific mechanism.

- **NULL scenario:** Both arms sr ≥ 2925 with val_ema ≥ 3.263. Mechanism is benign or weakly detrimental on this stack — aux Adam updates are NOT dominated by stale-momentum noise. Closes cAdam axis at JOINT scope; per-group localization (lm_head-only / embed-only) would be the natural follow-up.

- **PARTIAL scenario:** Arm A NULL but Arm B WIN — pure cooldown mechanism; the cautious mask is helpful precisely when m and grad are near-orthogonal (which is more frequent late in training as the loss landscape flattens).

## Chain rule

- If Arm A is clear NULL (sr ≥ 2925), launch Arm B directly without seed-2 of Arm A.
- If Arm A is thin clause-2 PASS or WIN candidate (sr ≤ 2875 with val_ema near baseline), run seed-2 of Arm A before launching Arm B.
- Both arms terminal → post SENPAI-RESULT.

## Compute budget

Standard 3250-step run × 2 arms ≈ 6h wall-clock total. cAdam adds ~1% compute overhead (one sign comparison + multiplication per Adam update).
