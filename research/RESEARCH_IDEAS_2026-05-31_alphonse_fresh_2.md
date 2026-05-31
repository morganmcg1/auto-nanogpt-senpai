# Fresh Hypothesis for g1r5-alphonse
Generated: 2026-05-31

---

## 1. Slug

`muon-depth-lr-scale`

---

## 2. One-Sentence Summary

Apply a linear depth-based decay factor to the Muon learning rate across transformer blocks — shallower blocks get a larger effective step size than deeper blocks — exploiting the known gradient magnitude asymmetry between early and late layers to accelerate the FFS crossing during the cooldown phase.

---

## 3. Mechanistic Argument

**What muon-depth-lr-scale does:** Rather than a single `lr_muon` applied uniformly to all transformer block parameters, we assign each block `i` an effective Muon LR of:

```
lr_i = lr_muon * (1 - depth_lr_scale_decay * i / (num_layers - 1))
```

where `depth_lr_scale_decay ∈ (0, 1)` is the new hyperparameter. Block 0 (shallowest) retains `lr_muon`; block `num_layers-1` (deepest) gets `lr_muon * (1 - depth_lr_scale_decay)`.

**Why FFS should improve:**

1. **Gradient magnitude asymmetry in deep transformers is well established.** Yang & Hu (μP, 2021; arxiv:2203.03466) show that without depth-aware LR scaling, later layers receive systematically larger gradient signals (feature learning favored at depth), while shallow layers can be under-driven. In Muon's NS5 step the gradient is renormalized — but the *effective step size* in weight space is still `lr * spectral_norm(update)`. Deep blocks already have larger spectral components post-NS5 because their gradients have larger amplitude before the NS step. A uniform LR therefore over-steps deep blocks and under-steps shallow ones.

2. **FFS crossing is a cooldown-phase phenomenon.** Empirically, the target crossing window in this benchmark is steps 2800–3050. During cooldown, the LR decays by ~10× from peak. Any instability from over-stepped deep layers manifests precisely during this phase — loss oscillates or stalls near the crossing boundary. Reducing deep-block LR by 10–30% moderates this oscillation without slowing early training (where LR is large enough that the factor has less relative impact).

3. **The μP analogy holds exactly.** μP's "depth multiplier" (width-and-depth-aware LR prescription) is derived from mean-field theory: for signal propagation to be stable at initialization and throughout training, LR should scale inversely with depth for residual layers. The modded-nanoGPT stack already uses `depth_init_mode=musoft` which scales residual projection *weights* by 1/sqrt(L). This paper's prescription would complete the μP contract by also scaling the residual projection *learning rates* by a compatible factor. The two mechanisms are complementary: musoft reduces how far a random gradient step distorts the residual stream; depth-lr-scale reduces how aggressively Muon step-sizes drive that distortion at training time.

4. **Layer-wise LR schedules have strong empirical support in transformer fine-tuning.** Zhang et al. (LLRD, 2022; arxiv:2006.05987) found 5–15% improvements in downstream task metrics by decaying LR linearly from top to bottom of BERT/ViT. While fine-tuning differs from pretraining, the mechanism is the same: top layers (deepest in our numbering) are already near their optima earlier; forcing large steps on them during cooldown destabilizes fine convergence. Pretraining analog: the 3250-step regime has the same structural problem — cooldown-phase deep layers are near their loss basin and need smaller steps.

5. **Interaction with NS5.** Newton-Schulz renormalizes the *direction* of the gradient but not its magnitude (the output has spectral norm ≈ 1, but the matrix shape determines the Frobenius norm). For MLP weight matrices (4D × D), NS5 output has Frobenius norm ≈ sqrt(4D). Thus `lr_muon * sqrt(4D)` is the actual step size per element. This is layer-shape-dependent but not depth-dependent. Adding a depth decay factor on top of NS5 is strictly complementary — it does not interfere with the direction renormalization, only the scalar step size.

**Why this is distinct from all in-flight work and closed families:**

- `frieren #1910 bias-ln-lr-scale`: targets AdamW bias and LN/RMSNorm gain parameter *groups* — 1D scalars only, not per-block Muon depth factor on 2D weight matrices. Different parameter class, different mechanism.
- `thorfinn #1907 ln-gain-init-small`: initialization of 1D LN scalars, not runtime LR.
- `tanjiro #1937 qkv-ortho-init`: initialization of Q/K/V matrices, not runtime LR.
- `depth_init_mode=musoft` (stack constant): scales residual std at *init time*, not at *update time*.
- Closed μ-cooldown (#1880): temporal LR schedule (LR as a function of step t), not spatial distribution (LR as a function of block index i). Orthogonal axes.
- Closed NS-iter family: modifies the NS polynomial degree, not the per-block step size.
- Closed gradient-preprocessing family: modifies gradient before NS5 input; depth-lr-scale modifies the scalar multiplier after NS5 output.
- Closed trajectory-averaging family: averaging of model snapshots, not LR distribution.
- Closed forward-pass regularization family: stochastic-depth (#1903) and others; this proposal does not touch the forward pass.

---

## 4. Freshness Table

| Axis | Mechanism | Same as muon-depth-lr-scale? | Notes |
|------|-----------|------------------------------|-------|
| frieren #1910 bias-ln-lr-scale | AdamW 1D scalar group LR split | **No** | Different optimizer (AdamW not Muon), different param class (1D scalars not 2D blocks), different dimension of variation (group membership not block depth) |
| depth_init_mode=musoft | Residual std at init | **No** | Init-time, not update-time |
| tanjiro #1937 qkv-ortho-init | Q/K/V init | **No** | Init-time, not update-time |
| thorfinn #1907 ln-gain-init-small | LN gain init | **No** | Init-time, 1D scalars |
| μ-cooldown (closed #1880) | LR as fn of step t | **No** | Temporal schedule; depth-lr-scale is spatial by block index i, orthogonal |
| GC (closed #1885) | Pre-NS DC centering | **No** | Gradient direction, not step size |
| NS-iter family (closed) | NS polynomial degree | **No** | Orthogonalizer strength, not step size |
| Lookahead (closed #1895) | Outer averaging loop | **No** | Trajectory averaging, not per-block LR |
| Stochastic-depth (closed #1903) | Forward-pass block dropout | **No** | Forward-pass, not update-time |
| lr_mlp=0.055 (stack constant) | MLP group LR (single scalar) | **No** | Same scalar for all blocks; depth-lr-scale makes it block-dependent |
| SOAP_ATTN (stack constant) | Eigenbasis preconditioning on attn | **No** | Preconditioner space, not step size distribution |

---

## 5. Key References

1. **μP: Tensor Programs V (Yang & Hu, 2021)** — arxiv:2203.03466. The principled derivation of depth-aware LR scaling from mean-field theory. Shows that without depth correction, residual layers at different depths receive inconsistent signal strengths, causing either feature learning collapse (too-small deep LR) or training instability (too-large deep LR). The prescription is `lr_l ∝ 1/depth_l` for residual projections.

2. **LLRD: Revisiting Few-Sample BERT Fine-Tuning (Zhang et al., 2022)** — arxiv:2006.05987. Empirical demonstration of Layer-wise Learning Rate Decay in transformers: decaying LR from shallowest to deepest layer by factor 0.8–0.9 per layer gives 5–15% downstream gains on GLUE, with the mechanism being that deeper (more task-specific) layers need smaller steps near their optima. The pretraining FFS analog: cooldown-phase deep layers behave like "near-optima" fine-tuning layers.

3. **T-Fixup (Huang et al., 2020)** — arxiv:2002.01172. Shows that depth-aware *initialization* (scaling by 1/L^{1/4}) combined with layer-specific LR is the correct coupled prescription: init and LR are not independent, they must be co-scaled. Directly motivates our hypothesis as the "missing half" of the musoft fix already in the stack.

4. **Admin Init: Improving Transformer Training (Liu et al., 2021)** — arxiv:2103.01378. Demonstrates that poorly-calibrated per-layer update magnitudes (not just gradient directions) are the primary cause of early instability in deep transformers, and that explicit per-layer step-size control is more important than gradient clipping or LR warmup alone.

---

## 6. Implementation Surface

Total change: ~18 LOC in the training script. No new imports required.

### Where to modify

The Muon optimizer is built in the training script's `configure_optimizers` function (or equivalent). Currently all transformer block parameters go into a single Muon group with `lr=lr_muon`. The change creates one Muon group per block layer with a depth-scaled LR.

### Core implementation

```python
# --- CLI flag (1 line) ---
parser.add_argument("--muon_depth_lr_decay", type=float, default=0.0,
    help="Linear LR decay fraction from block 0 to block N-1 for Muon groups. "
         "0.0 = uniform (baseline). 0.2 = deepest block gets 80% of lr_muon.")

# --- In configure_optimizers (or wherever Muon groups are built) ---
# Replace the single "all transformer block params" Muon group with per-block groups:

num_blocks = len(model.blocks)  # e.g. 12 for nanoGPT
muon_groups = []
for block_idx, block in enumerate(model.blocks):
    # Linear decay: block 0 -> lr_muon, block N-1 -> lr_muon*(1-decay)
    depth_factor = 1.0 - args.muon_depth_lr_decay * block_idx / max(num_blocks - 1, 1)
    block_lr = args.lr_muon * depth_factor
    block_params = [p for p in block.parameters()
                    if p.ndim >= 2 and p.requires_grad]  # Muon: 2D+ only
    if block_params:
        muon_groups.append({"params": block_params, "lr": block_lr})

# Pass muon_groups to Muon optimizer instead of one flat group
# (All other optimizer construction remains identical)
```

### Critical notes

- `p.ndim >= 2` filter: Muon only orthogonalizes 2D+ tensors; 1D biases/gains go to AdamW. This must be preserved exactly.
- The existing `lr_mlp` flag sets a different LR for MLP vs attn within a block. depth-lr-scale multiplies on top of both, since both are in the same block. If `lr_mlp` is implemented as a per-param filter, adjust accordingly to multiply by `depth_factor` after the per-param LR assignment.
- LR telemetry: log `train/lr/muon_block_0` and `train/lr/muon_block_11` to verify the gradient in W&B.
- The Muon optimizer internally divides by NS5's spectral output; the `lr` argument to the optimizer is the pre-NS5 scalar. This is fine — we want to scale the post-NS5 step size, and `lr` controls exactly that.

---

## 7. Experimental Cells

| Cell | muon_depth_lr_decay | train_steps | Seeds | Purpose |
|------|---------------------|-------------|-------|---------|
| A_ctrl | 0.00 (baseline) | 3250 | 1 | Code-split baseline; verify identical to reference |
| B★ | 0.15 | 3250 | 1 | Primary screen cell (15% decay at deepest block) |
| C | 0.25 | 3250 | 1 | Upper bound screen |
| D | 0.08 | 3250 | 1 | Lower bound screen (conservative) |
| E (confirm) | best of B/C/D | 3250 | 4 | Stat-sig confirmation if B/C/D passes FFS-alive gate |

Rationale for decay=0.15 as primary: the μP prescription for a 12-layer model gives ~1/sqrt(12) ≈ 0.29 per-layer LR reduction relative to the shallowest layer, but this is a total-depth correction applied linearly. A 15% linear decay (0.85× at block 11) is a conservative first test of the mechanism without risk of under-driving deep layers.

### Command-lines

```bash
# Cell A_ctrl (code-split baseline)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/muon-depth-lr-scale-A-ctrl" \
  --wandb_group "muon-depth-lr-scale" \
  --train_steps 3250 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --muon_depth_lr_decay 0.0

# Cell B★ (primary screen)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/muon-depth-lr-scale-B-0.15" \
  --wandb_group "muon-depth-lr-scale" \
  --train_steps 3250 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --muon_depth_lr_decay 0.15

# Cell C (upper bound)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/muon-depth-lr-scale-C-0.25" \
  --wandb_group "muon-depth-lr-scale" \
  --train_steps 3250 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --muon_depth_lr_decay 0.25

# Cell D (conservative lower bound)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/muon-depth-lr-scale-D-0.08" \
  --wandb_group "muon-depth-lr-scale" \
  --train_steps 3250 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --muon_depth_lr_decay 0.08

# Cell E (n=4 confirm — run only if at least one of B/C/D passes FFS-alive gate)
# Replace BEST_DECAY with the decay value that gave best FFS in B/C/D
for seed in 1 2 3 4; do
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/muon-depth-lr-scale-E-confirm-s${seed}" \
  --wandb_group "muon-depth-lr-scale" \
  --train_steps 3250 \
  --seed ${seed} \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --muon_depth_lr_decay BEST_DECAY
done
```

---

## 8. KG_Smoke Gate

Before Cell A, run a 100-step smoke to verify implementation correctness:

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/muon-depth-lr-scale-smoke" \
  --wandb_group "muon-depth-lr-scale" \
  --train_steps 100 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --muon_depth_lr_decay 0.15
```

Pass conditions (all required):
1. `train/loss` is finite at step 100 (no NaN/Inf).
2. `train/grad/global_norm` is finite and < 50.
3. W&B logs show distinct LR values for `train/lr/muon_block_0` vs `train/lr/muon_block_11` — specifically `muon_block_11 ≈ 0.85 * muon_block_0`. If only one LR group is logged, the depth-split did not take effect.
4. `train/lr/muon_block_0` matches the baseline `lr_muon` value exactly (no off-by-one in the formula).
5. No CUDA OOM or Python exception.

If condition 3 fails (only one LR group), the per-block Muon group creation is broken — debug before proceeding.

---

## 9. Signal / Promote / Merge Gates

**FFS-alive gate (cell B, C, or D):** At least one cell achieves `speedrun/final_first_step_to_target` (FFS_ema) ≤ 2887 on n=1. Per human directive 2026-05-26, no n=4 confirmation unless FFS is alive. The attractor pattern `{FFS_ema=2875, FFS_trainval=2925}` is known seed noise — require at least FFS_ema ≤ 2887 AND a val/loss improvement of ≥ 0.001 below baseline (3.2704) to pass. Do not promote on FFS_ema=2875 alone.

**Val-loss floor:** No cell should have `speedrun/final_best_val_loss` above 3.29 (deep layer under-driving). If Cell C (decay=0.25) exceeds this, do not try higher decay values.

**Confirm gate (cell E):** Mean FFS_ema over 4 seeds ≤ 2887.5 (baseline μ_4 = 2912.5 - 25 = 2887.5) with margin `(3.28 - mu) * sqrt(4) >= 0.004`.

**Merge gate:** `mu_4(FFS_ema) ≤ 2887.5` with the above margin satisfied.

---

## 10. Stop Conditions

Stop and close the PR (do not run Cell E) if:

1. All of B, C, D have FFS_ema > 2975 (mechanism not alive at n=1 — outside the FFS-alive window even for seed noise).
2. Cell C (decay=0.25) shows `val/loss > 3.29` — over-shooting indicates deep layers are critically under-driven; further tuning within this parameter family is unlikely to help.
3. A_ctrl FFS_ema differs from reference baseline by more than 50 steps in either direction — indicates a code integration problem that must be debugged first (the hypothesis cannot be evaluated against a broken baseline).
4. Cells B, C, D all land at the known seed-noise attractor `{FFS_ema=2875, FFS_trainval=2925}` with no val/loss improvement — treat as decisive null (same as μ-cooldown #1880 outcome).
5. Training loss is NaN in any cell — implementation error (likely incorrect parameter filtering in the depth-split loop).

---

## 11. Pre-Mortems

**Failure mode 1 — NS5 absorption neutralizes depth asymmetry:**
Newton-Schulz renormalizes each block's gradient matrix to approximately the same spectral norm regardless of depth. If NS5 already equalizes the effective step sizes across blocks (deep blocks have their large gradients compressed, shallow blocks have their small gradients amplified), then applying a depth-LR decay on top is double-counting a correction that NS5 already makes implicitly. The mechanism would be inert. Detectable by inspecting `train/grad_type/Linear_post_NS` norms per block — if they are already approximately equal across depth, NS5 is already solving the problem and adding depth-lr-scale cannot help.

**Failure mode 2 — lr_mlp interaction breaks the depth scaling:**
The existing `lr_mlp=0.055` applies a different scalar to MLP vs attn parameters. If the training script implements `lr_mlp` by overriding the per-parameter LR inside the Muon step (not as a separate optimizer group), then splitting into per-block Muon groups may conflict with the `lr_mlp` override logic. The deepest block MLP params could end up at `lr_mlp * (1 - decay)` or at `lr_muon * (1 - decay)` depending on which override wins — producing an undefined combination. Must verify this interaction in code before Cell A.

**Failure mode 3 — FFS bottleneck is not deep-layer instability:**
The current working hypothesis is that FFS crossing (2800–3050 range) is delayed by cooldown-phase oscillation in deep blocks. If instead the bottleneck is early-training plateau (shallow blocks learn too slowly before step 1000), depth-lr-scale in the wrong direction would be needed — deeper blocks should get *higher* LR, not lower. Partially testable by inspecting `train/loss` slope per block using the grad telemetry in the first 500 steps. If Cell B shows faster early descent but slower final crossing, the direction of decay should be reversed in a follow-up.

**Failure mode 4 — Identical result to seed-noise attractor:**
As with μ-cooldown (#1880), if all cells land at `{FFS_ema=2875, FFS_trainval=2925}` regardless of decay value, the mechanism is masked by seed noise and cannot be evaluated without n=4 runs even at screen stage. Per the human directive policy (FFS-alive requires ≤ 2887 not just ≤ 2925), this constitutes a decisive null — close without cell E.
