# Hypothesis: NS5 Polynomial Coefficient ATTN vs MLP Role-Split (frieren)

**Assigned:** 2026-06-02 12:15 UTC
**Student:** g1r1-frieren
**Branch:** g1r1-frieren/ns5-coef-attn-mlp-split
**Directive alignment:** (b) per-layer/per-block optimizer behavior + (d) momentum/preconditioner state handling

## Mechanism hypothesis

The current body Muon uses a uniform NS5 polynomial `f(x) = a·x + b·x³ + c·x⁵` with cubic-Newton coefficients `(a, b, c) = (1.5, -0.5, 0.0)` across **all** matrix parameter shapes — attention projections (square or near-square: `attn.c_q`, `attn.c_k`, `attn.c_v`, `attn.c_proj` are all 1024×1024 in this stack) and MLP projections (highly rectangular: `mlp.c_fc` is 4096×1024, `mlp.c_proj` is 1024×4096).

The Jordan-optimized aggressive contraction `(3.4445, -4.7750, 2.0315)` is known from the modded-nanogpt programme to produce sharper polar projection convergence per-iter at a given NS_ITERS budget; however, the closed body-Muon work (PR #193 Jordan-vs-cubic, #2184 KJ probe, #2167 per-group ITER COUNT) settled on **uniform** cubic-Newton at the current operating point.

**Hypothesis:** the optimal NS5 polynomial shape differs between attention matrices (square, full-rank, low aspect-ratio variance) and MLP matrices (highly rectangular, dominated by the wider dimension's row structure). The attn family may benefit from the smoother conservative cubic (current baseline) while MLP benefits from aggressive Jordan contraction — or vice versa. Either way, splitting the polynomial by structural role rather than running uniform should expose a free margin not captured by global coefficient sweeps.

This is structurally distinct from the closed per-role experiments which all tested **iteration count** or **coverage**, never coefficient SHAPE:
- PR #1839: `--ns_iter_mlp` vs `--ns_iter_attn` — iter COUNT per shape (CLOSED).
- PR #2167: `attn=7, mlp=5 NS5 iteration count` — iter COUNT per role (CLOSED).
- PR #1297: `NM coverage attn/mlp/none` — which params get NM at all (COVERAGE not coefficients).
- PR #1520: `NM ATTN-only vs MLP-only` — selective coverage.
- PR #807: `MuonH-SI per-block-type LR split (attn vs mlp)` — LR per role (CLOSED).
- PR #2093: `Body-Muon ATTN_LR_MULT fine bracket` — LR magnitude per role (CLOSED).

The NS5 **polynomial coefficient (a,b,c) per-role split** axis has not been tested in any closed PR across 12+ search queries. The role-split LR work (#807, #2093) and the iter count work (#1839, #2167) establish that role-conditioned differentiation is a real lever; this PR completes the third leg by varying coefficients.

## Why attn and mlp could differ

The NS5 polar projection minimizes ‖p(X) - sign(X)‖ over the eigenvalue range of `X^T X` (or `X X^T`). For square attn matrices, the spectrum tends to be relatively flat post-momentum-update with eigenvalues concentrated near unity; conservative cubic-Newton (1.5, -0.5, 0) converges in ~12 iters with low residual. For 4× rectangular MLP matrices, the spectrum is more eccentric — the inner dimension (1024) and outer dimension (4096) imply the implicit `X X^T` is 1024×1024 (always small side), but the effective polar problem is on a 4× wider matrix, with a wider range of singular values to contract toward 1. Aggressive Jordan coefficients are designed for exactly this regime.

The directional hypothesis: **MLP benefits from Jordan, ATTN stays on cubic-Newton baseline.** Bilateral tests both directions.

## Bilateral arm design

**Arm A** — MLP-aggressive (attn=baseline cubic, mlp=Jordan):
```
--ns_coef_attn_a 1.5    --ns_coef_attn_b -0.5    --ns_coef_attn_c 0.0
--ns_coef_mlp_a 3.4445  --ns_coef_mlp_b -4.7750  --ns_coef_mlp_c 2.0315
```

**Arm B** — ATTN-aggressive (attn=Jordan, mlp=baseline cubic):
```
--ns_coef_attn_a 3.4445 --ns_coef_attn_b -4.7750 --ns_coef_attn_c 2.0315
--ns_coef_mlp_a 1.5     --ns_coef_mlp_b -0.5     --ns_coef_mlp_c 0.0
```

Bilateral interpretation:
- If Arm A wins, Arm B null → MLP matrices want aggressive contraction; the rectangular MLP layers were under-orthogonalized at NS_ITERS=12 with cubic coefs.
- If Arm B wins, Arm A null → ATTN matrices want aggressive contraction; attn was the bottleneck shape.
- If both win → role-split (in either direction) outperforms uniform — generic asymmetry win.
- If both null → uniform cubic is genuinely optimal for both roles at NS_ITERS=12; close axis.

## Implementation sketch

The polar projection enters `zeropower_via_newtonschulz5(G, a, b, c, iters)` with module-level constants `NS_A, NS_B, NS_C`. For role-split, the optimizer step needs to dispatch (a,b,c) per param-group based on whether the param's qualified name contains `attn` or `mlp`.

```python
parser.add_argument('--ns_coef_attn_a', type=float, default=NS_A)
parser.add_argument('--ns_coef_attn_b', type=float, default=NS_B)
parser.add_argument('--ns_coef_attn_c', type=float, default=NS_C)
parser.add_argument('--ns_coef_mlp_a',  type=float, default=NS_A)
parser.add_argument('--ns_coef_mlp_b',  type=float, default=NS_B)
parser.add_argument('--ns_coef_mlp_c',  type=float, default=NS_C)

# In the body Muon optimizer __init__ or param-group setup:
# Tag each param-group with role ∈ {'attn', 'mlp'} based on name resolution
# at construction time (model.blocks[i].attn.* vs model.blocks[i].mlp.*).

# In the body Muon step, before calling zeropower_via_newtonschulz5:
role = group.get('role', 'attn')  # default to attn-like behavior
if role == 'attn':
    a, b, c = args.ns_coef_attn_a, args.ns_coef_attn_b, args.ns_coef_attn_c
else:
    a, b, c = args.ns_coef_mlp_a, args.ns_coef_mlp_b, args.ns_coef_mlp_c
out = zeropower_via_newtonschulz5(g, a=a, b=b, c=c, iters=NS_ITERS)
```

LOC delta: ~30. Runtime: identical (same NS_ITERS, just different scalar coefs per group). VRAM: zero. **No changes to optimizer1 (aux AdamW); no changes to the polar function signature.**

## Reproduce commands (full baseline stack)

**Arm A (MLP-aggressive Jordan, attn=baseline cubic):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --ns_coef_attn_a 1.5    --ns_coef_attn_b -0.5    --ns_coef_attn_c 0.0 \
  --ns_coef_mlp_a 3.4445  --ns_coef_mlp_b -4.7750  --ns_coef_mlp_c 2.0315 \
  --wandb_group g1r1-frieren-ns5-coef-attn-mlp-split \
  --wandb_name g1r1-frieren/ns5-coef-attn-mlp-split-arm-a-mlp-jordan
```

**Arm B (ATTN-aggressive Jordan, mlp=baseline cubic):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --ns_coef_attn_a 3.4445 --ns_coef_attn_b -4.7750 --ns_coef_attn_c 2.0315 \
  --ns_coef_mlp_a 1.5     --ns_coef_mlp_b -0.5     --ns_coef_mlp_c 0.0 \
  --wandb_group g1r1-frieren-ns5-coef-attn-mlp-split \
  --wandb_name g1r1-frieren/ns5-coef-attn-mlp-split-arm-b-attn-jordan
```

## Merge gate

Beat #1532 baseline: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Sentinel logging (REQUIRED)

At step 0 log: `ns_coef_attn=({a},{b},{c}), ns_coef_mlp=({a},{b},{c})` for both groups — confirms dispatch is wired up correctly.

For 1 attn param and 1 mlp param, log `polar/residual_attn = ‖XX^T - I‖_F / ‖I‖_F` and `polar/residual_mlp = ‖XX^T - I‖_F / ‖I‖_F` at step 100 — confirms different coefs produce different polar quality.

## Falsifying result

Both arms cluster at sr=2925 with val_ema ∈ [3.265, 3.275] → the NS5 polynomial coefficient is robust to role differentiation at NS_ITERS=12; the uniform cubic-Newton is near-optimal for both shapes. Close per-role coefficient axis.

## Stop / report

Post terminal SENPAI-RESULT for Arm A with `terminal=false, pending_arms=true`, then immediately launch Arm B without waiting for advisor ack. After Arm B terminal, post FINAL bilateral SENPAI-RESULT with `terminal=true, pending_arms=false` and both run IDs.
