# HYPOTHESIS — alphonse Newton-Muon activation-Gram right-preconditioner on body PMuon

## Tier-2 classification

**Preconditioner state-handling change** on body PMuon — directive #1252 category (d). Adds a new curvature signal (activation-side input correlations) as a pre-step BEFORE the existing NS5 → polar pipeline. NS5 is fully preserved (avoiding the Shampoo catastrophe from #985).

## Motivation

PMuon's existing bilateral whitening `L^{-γ} @ m @ R^{-γ}` operates on the **momentum buffer m**, with `L_cov, R_cov` accumulated from `g @ g.T`, `g.T @ g` of the gradient. This captures **output-side gradient covariance** — how the gradient's row/column directions are correlated **after** the layer's linear map.

What this misses: **input-side activation correlation**. For a linear layer `y = W @ x`, the gradient `∂L/∂W = (∂L/∂y) @ x.T`. If two input features `x_i, x_j` are strongly correlated across the batch, the corresponding columns of the gradient are linearly coupled regardless of any `L/R_cov` whitening on the gradient itself. Standard KFAC / natural-gradient theory (Martens & Grosse 2015) factorizes the Fisher block per-layer as `F_W ≈ A ⊗ G`, where `A = E[x x^T]` is the input-activation Gram matrix and `G = E[(∂L/∂y)(∂L/∂y)^T]` is the output Gram. SOAP (Vyas et al., arXiv:2409.11321) showed Adam-in-Shampoo-eigenbasis exploits this factorization on transformer LMs.

The PMuon stack already captures the output side (`L_cov, R_cov` on the gradient). The **input side is untouched**: right-multiplying the gradient by `A^{-1/2}` (where `A = X^T X / B` is the input-activation Gram EMA) decorrelates the gradient columns in the input feature basis, **then** the momentum buffer / NS5 / polar pipeline operates on a feature-decorrelated signal. This is mechanistically orthogonal to every closed/in-flight axis in this stack.

**Critical guard (PR #985 Shampoo catastrophe):** Shampoo failed in this repo because it **replaced** the NS5 → polar pipeline with its own matrix-power update. NS5 is triple-load-bearing (magnitude normalization, rank-deficiency clipping, null-space suppression). This hypothesis adds activation preconditioning **before** NS5 — the polar pipeline is unchanged.

## Hypothesis

Pre-conditioning the body PMuon gradient `G` by the inverse square-root of the input-activation Gram matrix `A_ema = EMA(X^T X / B)` accelerates target crossing or beats val_ema 3.262854. The bilateral arms test the **information density** of off-diagonal Gram correlations: Arm A uses only the diagonal (cheap variance normalization), Arm B uses the full Gram matrix (off-diagonal feature decorrelation).

## Bilateral arms

Both arms preserve the canonical baseline stack (β₂ pulse @ 975, late-higher block LR, paramema_refresh_step=2600).

| Arm | Gram approximation | Mechanism | β_gram | eps_gram |
|---|---|---|---|---|
| **A: diagonal Gram** | `scale = 1 / sqrt(diag(A_ema) + eps)` per input feature | Per-column gradient scaling (variance normalization only) | 0.95 | 1e-6 |
| **B: full Gram** | `G_precond = G @ matrix_neg_power(A_ema, 0.5)` | Full off-diagonal feature decorrelation | 0.95 | 1e-6 |

Arm A is the **cheap discriminating screen** — if input-side variance normalization alone helps, Arm B (off-diagonal correlations) is worth the matrix-power cost. If Arm A is NULL, Arm B likely doesn't help either; the asymmetric arms map cleanly to a yes/no on each layer of mechanism.

## Mechanistic separation from in-flight Tier-2 and closed axes

| Item | What it operates on | Newton-Muon |
|---|---|---|
| Existing `L_cov, R_cov` whitening | Output-side gradient covariance, on momentum **m** | Input-side activation Gram, on raw gradient **G** |
| #985 Shampoo (CLOSED catastrophic) | **Replaced** NS5 with own matrix-power update | **Preserves** NS5 (operates BEFORE polar pipeline) |
| #1703 alphonse ADOPT (CLOSED) | Async update-rule **order** swap on PMuon | Synchronous preconditioner state (new buffer) |
| #1726 nezuko (in flight) | L_cov/R_cov **hard zero reset** at 2750 | Continuous activation-Gram EMA accumulation |
| #1727 edward (in flight) | Per-block β_cov split | Per-layer activation-Gram (orthogonal to β_cov) |
| #1730 askeladd (in flight) | First-moment buffer hard reset | Pre-momentum preconditioner (no reset) |
| #1739 fern (in flight) | NS_ITERS burst (polar projection depth) | Pre-NS5 mechanism (orthogonal to polar) |
| #1742 tanjiro (in flight) | Per-block LR-mult burst | Per-layer preconditioner (orthogonal to LR scalar) |
| #1749 thorfinn (in flight) | Aux AdamW first-moment dual-EMA | Body PMuon preconditioner (different optimizer) |
| #1709 edward AdaShift (CLOSED) | Aux Adam temporal-lag second moment | Body PMuon spatial preconditioner |

This is the only hypothesis in the round that touches **input-side activation curvature** — a previously-untouched axis on body PMuon.

## Implementation sketch

### Step 1: Forward-hook activation capture per body Linear layer

In `train_gpt_simple.py`, after model construction but before optimizer creation, walk every body `Linear` layer and register a forward pre-hook that stashes the layer's input activation on the **weight parameter** itself. Skip embed (`nn.Embedding`) and `proj` (lm_head) — those are aux AdamW territory.

```python
# Walk attn (q, k, v, proj) and mlp (fc, proj) Linears inside each Block.
# Use the weight parameter as the key so the Muon optimizer step can find the cached X.
def _activation_capture_pre_hook(module, inputs):
    # inputs[0] is the layer input X of shape [B, T, in_features]
    x = inputs[0]
    # Flatten (B, T) for Gram: X_flat shape [B*T, in_features]
    x_flat = x.detach().reshape(-1, x.shape[-1])
    # Stash on the weight param for the optimizer step.
    module.weight._captured_x = x_flat

# After model.compile, register hooks on every body Linear.
body_linear_modules = []
for blk in model.blocks:
    for lin in [blk.attn.q, blk.attn.k, blk.attn.v, blk.attn.proj, blk.mlp.fc, blk.mlp.proj]:
        lin.register_forward_pre_hook(_activation_capture_pre_hook)
        body_linear_modules.append(lin)
```

### Step 2: CLI flags + Muon initialization

```python
parser.add_argument('--muon_act_gram_mode', type=str, default='off',
                    choices=['off', 'diag', 'full'],
                    help='Newton-Muon activation Gram right-preconditioner: '
                         "'off' = baseline, 'diag' = Arm A diagonal A_ema, "
                         "'full' = Arm B full Gram matrix_neg_power.")
parser.add_argument('--muon_act_gram_beta', type=float, default=0.95,
                    help='EMA decay for activation Gram accumulator.')
parser.add_argument('--muon_act_gram_eps', type=float, default=1e-6,
                    help='Numerical floor for sqrt(diag(A_ema)) and Gram inverse.')
```

### Step 3: Modify `Muon.step()` (or `pmuon_update`) to apply preconditioner

Insert the activation-Gram preconditioner **before** the gradient enters the momentum/NS5 pipeline. Stored state per param: `state["A_ema"]` (shape `[in_features, in_features]`, fp32). The hook stashed `x_flat` on `p` itself.

```python
# Inside Muon.step() per param p:
state = self.state[p]
if "A_ema" not in state and args.muon_act_gram_mode != "off":
    in_features = p.shape[1]
    state["A_ema"] = torch.zeros(in_features, in_features,
                                 device=p.device, dtype=torch.float32)

# Apply preconditioner BEFORE pmuon_update consumes p.grad
g = p.grad
if args.muon_act_gram_mode != "off" and hasattr(p, "_captured_x"):
    x = p._captured_x  # shape [B*T, in_features]
    # Update Gram EMA in fp32
    batch_size_eff = x.shape[0]
    x_fp32 = x.float()
    A_new = (x_fp32.T @ x_fp32) / batch_size_eff  # [in, in]
    state["A_ema"].mul_(args.muon_act_gram_beta).add_(
        A_new, alpha=(1.0 - args.muon_act_gram_beta))

    if args.muon_act_gram_mode == "diag":
        # Arm A: per-column scaling by 1/sqrt(diag(A))
        diag = state["A_ema"].diagonal().clamp_min(args.muon_act_gram_eps)
        scale = 1.0 / diag.sqrt()  # [in]
        g = g * scale.to(g.dtype).unsqueeze(0)  # broadcast over [out, in]
    elif args.muon_act_gram_mode == "full":
        # Arm B: full Gram inverse-sqrt
        A_neg_half = matrix_neg_power(state["A_ema"], 0.5)
        g = (g.float() @ A_neg_half).to(g.dtype)

    del p._captured_x  # release for next step

update = pmuon_update(g, state["momentum"], state["L"], state["R"], ...)
```

**Key invariants:**
- `A_ema` is fp32 (precision-critical for matrix_neg_power).
- `A_ema` is zero-initialized; first 50-100 steps may give noisy preconditioner. Consider warmup: skip Gram preconditioner until step 50 (use `state["A_ema"]` accumulation but bypass `g` transformation).
- Hook must be registered AFTER `model.compile(dynamic=True)` may not propagate hooks into compiled forward — verify activations actually populate by checking `p._captured_x` exists at step 1.
- Skip embed (`nn.Embedding`) and lm_head (`model.proj`) — those are aux AdamW.

### Step 4: Smoke test

Run 200 steps with `--muon_act_gram_mode diag`. Verify:
- `p._captured_x` exists for every body Linear weight at step 1.
- `state["A_ema"]` diagonal grows to plausible variance values (not zero, not NaN) by step 50.
- Loss trajectory matches or exceeds baseline through step 200.
- Telemetry confirms `actgram/diag_min`, `actgram/diag_max`, `actgram/diag_ratio` populate.

If diag smoke passes, swap to `--muon_act_gram_mode full` and verify same conditions + `actgram/full_inv_sv_min` (smallest singular value of `A_neg_half`) is finite at step 100.

### Step 5: Run two arms sequentially (pgrep gate)

**Arm A — diagonal Gram:**
```bash
pgrep -f 'train_gpt_simple\.py' && echo "BLOCKED: prior run still active" && exit 1
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_act_gram_mode diag --muon_act_gram_beta 0.95 --muon_act_gram_eps 1e-6 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse/newton-muon-actgram \
  --wandb_name g1r1-alphonse/actgram-arm-a-diag
```

**Arm B — full Gram:**
```bash
pgrep -f 'train_gpt_simple\.py' && echo "BLOCKED: prior run still active" && exit 1
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_act_gram_mode full --muon_act_gram_beta 0.95 --muon_act_gram_eps 1e-6 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse/newton-muon-actgram \
  --wandb_name g1r1-alphonse/actgram-arm-b-full
```

If Arm A is clearly NULL (val_ema > 3.265 at step 3250), **post Arm A SENPAI-RESULT and ask the advisor before launching Arm B** — Arm B is more expensive and the asymmetric early signal often predicts Arm B outcome.

## Telemetry to log

Per telemetry interval (already wired for other diagnostics):
- `actgram/diag_min`, `actgram/diag_max`, `actgram/diag_ratio` — min/max/ratio of `diag(A_ema)` on a sample param
- `actgram/diag_norm_pre` — Frobenius norm of `G` before preconditioner (per sample step)
- `actgram/diag_norm_post` — Frobenius norm after preconditioner
- `actgram/full_inv_sv_max` (Arm B only) — top singular value of `matrix_neg_power(A_ema, 0.5)` on sample param
- `actgram/full_inv_sv_min` (Arm B only) — bottom singular value
- Existing `val/loss_ema`, `val/loss_live`, `pmuon/lcov_eigh_min/max`, `speedrun/first_step_to_target`

Console ENTER print at step 0 confirming mode active + sample param's Gram shape.

## Reproduce command (single arm A)

See Step 5 above.

## Reporting contract (terminal SENPAI-RESULT)

After both arms terminal at step 3250 (or after Arm A NULL + advisor confirm), post single bilateral marker (`terminal=true`, `pending_arms=false`):

```json
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<arm_a>","<arm_b>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<min_sr>},"test_metric":{"name":"val/loss_ema","value":<min_val_ema>}}
```

Include:
- Bilateral table (sr / val_ema / val_live / target_margin per arm vs baseline)
- Activation-Gram audit: `diag(A_ema)` magnitude trajectory at sentinel steps {0, 50, 200, 975, 2000, 2750, 3250}
- For Arm B: `full_inv_sv_max/min/ratio` trajectory at same sentinels
- Step-time comparison vs baseline (Arm A overhead ~ negligible, Arm B overhead ~ matrix_neg_power × N_body_layers per step)
- For each arm, the val_ema trajectory at {2125, 2500, 2750, 2875, 2925, 3000, 3100, 3250}

## Baseline + merge gate

| metric | baseline #1532 (n=2) |
|---|---|
| `speedrun/final_first_step_to_target` | 2875 |
| `val/loss_ema` | 3.262854 |

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`. Bilateral fail → NULL closure; either arm pass → request seed-2 confirmation before merge.

## Risk notes

- **Hook + torch.compile interaction:** `model.compile(dynamic=True)` may inline forward and skip pre-hooks. Verify activation capture works by asserting `hasattr(p, "_captured_x")` at step 1. If hooks don't fire, fall back to manual capture by monkey-patching `F.linear` or by storing X inside the `Linear.forward` itself (since `Linear` is defined in `train_gpt_simple.py` and is editable).
- **MLP `fc` Gram size:** `fc` has `in_features=768`, `out_features=3072` → Gram is `768×768` (fine). `proj` has `in_features=3072`, `out_features=768` → Gram is `3072×3072` (~36 MB fp32, matrix_neg_power non-trivial). Profile Arm B step time vs baseline; if step time inflates >2×, consider restricting Arm B to attention layers only (no MLP `proj`) as a follow-up.
- **Early-step rank deficiency:** `A_ema` is rank ≤ `B*T = 8 * 64 * 1024 = 524288` from a single forward, so input-rank-deficiency is not a concern for `in_features ≤ 3072`. But `matrix_neg_power` may still be unstable at step 1-10 — use the existing eigh jitter retry from `matrix_neg_power` (already in baseline post-#1709).
- **Hook memory:** each captured activation is `B*T × in_features` × bf16 = ~24 MB per layer × ~72 body layers × 1 step retained = ~1.7 GB transient. Release `p._captured_x` after use (sketched in step 3).

## Distinguishing this from the Shampoo catastrophe (#985)

PR #985 closed because Shampoo's right-multiplication of `g @ R^{-1/4}` was applied **as a replacement for the NS5 → polar pipeline**. This caused null-eigenvalue amplification (1000× weight norm blow-up by step 500).

This hypothesis is structurally different:
1. **Preconditioner source:** `A = E[X^T X]` (input activation Gram) vs Shampoo's `R = E[G^T G]` (gradient covariance). These are different statistical objects.
2. **Pipeline position:** activation preconditioner is applied **before** NS5; Shampoo replaced NS5.
3. **Scope:** activation Gram is per-layer input correlation; existing `L/R_cov` is per-layer gradient covariance. Adding the input side is an addition, not a replacement.

If this works, it stacks with the existing bilateral whitening rather than competing with it.
