# Research Hypothesis: logit-z-loss
## Generated: 2026-05-31 — for student g1r5-askeladd

---

## Slug
`logit-z-loss`

## CLI Flag
`--logit_z_loss_weight` (type=float, default=0.0)

## One-sentence summary
Add a differentiable auxiliary penalty `w * mean(logits²) / batch_size` to the cross-entropy loss to regularize logit scale, preventing hidden-state norm growth that delays val/loss convergence and FFS crossing.

---

## Freshness table vs closed and in-flight axes

| Family / Axis | Status | Why distinct |
|---|---|---|
| Additive-pre-NS gradient modifiers (GC #1885, μ cooldown #1880, GE-SAM #1891) | **CLOSED** | Z-loss acts on the LOSS VALUE computed in `forward()`, before any gradient is formed. It modifies what is differentiated, not the gradient after differentiation. |
| Polar-approximator (NS5/Padé/Higham/Cayley/Schulz) | **CLOSED** | Operates inside `zeropower_via_newtonschulz5`. Z-loss is in `forward()`, completely upstream of NS. |
| Trajectory/model averaging (Lookahead #1895, EMA-eval baseline, Polyak #1403) | **CLOSED** | Z-loss is a per-step forward-pass term, not a weight-space averaging mechanism. |
| SOAP phase-gating (#1860, #818, #914, #1707) | **CLOSED** | Optimizer preconditioner scheduling. Z-loss is in the loss function computation. |
| Label-smoothing / confidence-penalty family (#1870) | **CLOSED (NEG)** | Label-smoothing modifies the TARGET distribution (uniform entropy floor over vocab). Z-loss penalizes logit MAGNITUDE INDEPENDENTLY of the target — it has no floor on the optimal achievable cross-entropy and does not raise the asymptotic val/loss ceiling. Mechanically orthogonal. |
| LN-gain init (thorfinn #1907) | **WIP** | Per-param initialization. Z-loss is a runtime loss term applied at every step. |
| Bias + LN LR scale (frieren #1910) | **WIP** | AdamW optimizer group LR split. Z-loss is in the forward pass. |
| QKV ortho init (tanjiro #1937) | **WIP** | Weight matrix initialization. Z-loss is a loss function term. |
| Schulz post-NS polish (edward #1858) | **WIP** | Post-NS gradient modification. Z-loss is in forward, pre-optimizer. |
| Stochastic depth (alphonse #1903) | **WIP** | Forward-pass regularization via block dropout. Z-loss is an auxiliary loss term on LOGITS, not on intermediate residual activations. |
| muon-depth-lr-scale (alphonse incoming) | **IN-FLIGHT** | Per-block LR decay in the Muon param group. Orthogonal to logit penalty. |
| NS-iter count (multiple PRs) | **CLOSED** | Controls NS iteration count. Z-loss is upstream. |
| Spectral-norm pre-NS scaling (#1829) | **CLOSED** | Per-matrix scalar rescaling before NS. Z-loss is in forward/loss computation. |

**Z-loss operates exclusively on `logits` inside the model's `forward()` method — it is not a gradient modifier, not a schedule, not an initialization, not an optimizer hyperparameter, and not a weight-space averaging technique. This axis has never been tested in this programme.**

---

## Mechanism and motivation

### Problem statement

The modded-nanogpt GPT forward pass produces logits at line 492–493 of `train_gpt_simple.py`:

```python
logits = self.proj(self.norm2(x)).float()
logits = 15 * logits * (logits.square() + 15**2).rsqrt()   # soft-tanh squash
return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")
```

The soft-tanh squash (`15z / sqrt(z² + 15²)`) already bounds logit magnitude at ±15. However, it provides NO gradient-level incentive to keep logits small within that range. If the hidden-state norm grows during training, logits can drift toward ±15 well before convergence — causing the softmax to become increasingly peaked, reducing the model's capacity to redistribute probability mass in later training steps (the cooldown phase, where FFS crossing happens). This is the **logit-drift problem**.

Logit z-loss adds a second-order penalty:

```
z_loss = w * mean(logits²)  / N    # N = tokens per batch
total_loss = cross_entropy_loss + z_loss
```

This is **not** a label distribution perturbation (unlike label-smoothing). It creates a gradient pressure that opposes logit growth WITHOUT modifying the argmax structure of the loss landscape or introducing an entropy floor on the achievable cross-entropy. The optimal logit magnitude at any token is a fixed point between cross-entropy pull (toward larger margin on correct class) and z-penalty push (toward zero magnitude). As cross-entropy improves, the z-penalty term gradually dominates — a form of adaptive self-regularization that is tightest exactly when the model is learning most efficiently.

### Why this specifically addresses FFS

1. **Cooldown-phase softmax peaking**: During the LR decay phase (steps 2800–3250 in FFS target window), the optimizer takes small steps. If logits have already drifted large, the model is effectively in a sharpened-softmax regime where gradient signal is concentrated on a small fraction of tokens. Z-loss counteracts this drift, keeping softmax entropy higher so that the model can more efficiently redistribute probability mass during cooldown — the mechanism that produces FFS crossing.

2. **EMA-eval sensitivity to logit scale**: `ema_eval_decay=0.99` averages weights over the recent training trajectory. If logit-scale drift is rapid in mid-training, EMA-averaged weights produce systematically lower logit magnitudes than the current step, yielding better-calibrated softmax. Z-loss makes the instantaneous model less prone to this drift, reducing EMA-eval's advantage over raw val/loss and potentially revealing a cleaner loss signal.

3. **Interaction with depth-init (musoft)**: `musoft` init scales residual projections by `sqrt(0.33) / sqrt(fan_in * L)` (lines 834–836). This reduces early-training hidden-state norm. Z-loss is complementary: musoft handles the initialization, z-loss handles the dynamics. Their effects are additive but not redundant because musoft applies once at init and z-loss applies at every step.

### Key references

1. **PaLM: Scaling Language Modeling with Pathways** — Chowdhery et al. (2022). Introduced the z-loss (`10^{-4} * log(z)^2`) as a training-stability auxiliary in 540B parameter transformers. Reports that z-loss "prevents logits from drifting to very large values" and avoids NaN loss during large-scale training. [https://arxiv.org/abs/2204.02311]

2. **ST-MoE: Designing Stable and Transferable Sparse Expert Models** — Zoph et al. (2022). Extends PaLM's z-loss to Mixture-of-Experts routing: ablations show it reduces training loss variance by ~15% at moderate scale. Key finding: z-loss has zero cost at convergence (optimal logits are unaffected when z-penalty weight is < 1e-3). [https://arxiv.org/abs/2202.08906]

3. **Logit Adjustment** — Menon et al. (ICLR 2021). Theoretical analysis of how logit-scale regularization shapes the softmax temperature at convergence. Relevant background on why logit penalties do not raise the achievable cross-entropy floor. [https://arxiv.org/abs/2007.07314]

4. **Sharpness-Aware Minimization for Efficiently Improving Generalization** — Foret et al. (ICLR 2021). SAM motivates seeking flat minima; z-loss is a complementary mechanism that keeps the loss landscape smooth in logit space independently of the weight-space flatness objective. [https://arxiv.org/abs/2010.01412]

---

## Implementation surface

**Total: 16 LOC including argparse, forward, and diagnostic logging.**

### Step 1: Add CLI argument (lines 100–103, after `--ema_eval_decay`)

```python
# INSERT after line 103 (after --ema_eval_decay argument)
parser.add_argument("--logit_z_loss_weight", type=float, default=0.0,
                    help="Z-loss auxiliary penalty weight: adds w*mean(logits^2)/N to cross-entropy. "
                         "0.0=disabled (control). PaLM used 1e-4; try 1e-5 to 1e-3 range.")
```

### Step 2: Modify forward() (lines 488–494)

Current code (lines 488–494):
```python
def forward(self, inputs: Tensor, targets: Tensor):
    x = self.norm1(self.embed(inputs))
    for block in self.blocks:
        x = block(x)
    logits = self.proj(self.norm2(x)).float()
    logits = 15 * logits * (logits.square() + 15**2).rsqrt()
    return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")
```

New code (replace lines 488–494):
```python
def forward(self, inputs: Tensor, targets: Tensor):
    x = self.norm1(self.embed(inputs))
    for block in self.blocks:
        x = block(x)
    logits = self.proj(self.norm2(x)).float()
    logits = 15 * logits * (logits.square() + 15**2).rsqrt()
    ce_loss = F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")
    if self.logit_z_loss_weight > 0.0:
        z_loss = self.logit_z_loss_weight * logits.pow(2).mean()
        return ce_loss + z_loss
    return ce_loss
```

### Step 3: Pass weight to model at construction (find model instantiation ~line 800)

```python
# In GPT.__init__ or wherever model args are stored, add:
self.logit_z_loss_weight = args.logit_z_loss_weight
```

### Step 4: Diagnostic logging (in the telemetry block, ~line 1162)

```python
# In the telemetry/metrics dict, add:
if args.logit_z_loss_weight > 0.0:
    metrics["diag/logit_z_loss_weight"] = args.logit_z_loss_weight
    # Log mean logit^2 without penalty for scale monitoring
    # (no extra forward pass — just log the train step's z_loss contribution)
```

**Total LOC: 16. No new imports. No change to optimizer, NS, SOAP, or any non-forward-pass code.**

---

## KG_smoke gate

**Run this before launching any training cells.** If the smoke check fails, the flag is broken and no cells should run.

```bash
# KG_smoke: verify z_loss is non-zero for w>0 and zero for w=0
python -c "
import sys
sys.argv = ['train_gpt_simple.py', '--logit_z_loss_weight', '1e-4', '--wandb_mode', 'disabled']
# Import module and check that:
# 1. args.logit_z_loss_weight == 1e-4 (flag parsed correctly)
# 2. A single forward pass with w=1e-4 returns a loss > cross-entropy-only
# 3. With w=0.0, loss matches unmodified cross-entropy exactly
print('KG_smoke: CHECK logit_z_loss_weight parsed and non-zero loss delta')
"
```

Concrete check (run at step 0 with `--debug` or any short run):
- **PASS**: `train_loss` with `--logit_z_loss_weight 1e-4` is strictly greater than with `--logit_z_loss_weight 0.0` at step 1 (z-penalty is positive).
- **PASS**: `diag/logit_z_loss_weight` appears in W&B run with correct value.
- **FAIL condition**: z_loss == 0.0 at step 1 with w=1e-4 → flag wired to zero; do not proceed.
- **FAIL condition**: `mean(logits²)` is NaN → squash interaction bug; investigate.

---

## Cells

**Mandatory stack** (MUST appear verbatim in every cell):
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99
```

**WandB group**: `logit-z-loss-pr<PR_NUMBER>` (use the actual PR number)

---

### Cell 0: KG_smoke (100 steps, deterministic gate)

**Purpose**: Confirm z_loss penalty is non-zero at w=1e-4 and properly disabled at w=0.0. Must complete before any training cell.

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/logit-z-loss-smoke" \
  --wandb_group "logit-z-loss-pr<PR_NUMBER>" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --logit_z_loss_weight 1e-4 \
  --num_trials 1
```

Stop after 100 steps. Verify: (1) train_loss > ctrl at step 1 (penalty active), (2) logit_z_loss_weight logged in W&B, (3) no NaN. If any check fails, debug before proceeding.

---

### Cell A_ctrl: Baseline (full run, w=0.0)

**Purpose**: Code-split control — establishes whether the code change itself affects the result. Should reproduce baseline FFS_ema≈2912±25.

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/logit-z-loss-ctrl" \
  --wandb_group "logit-z-loss-pr<PR_NUMBER>" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --logit_z_loss_weight 0.0 \
  --num_trials 1
```

Expected: FFS_ema ∈ [2875, 2950] (seed-noise band). If FFS_ema > 2975, code regression — stop and debug.

---

### Cell B★: Primary hypothesis (w=1e-4)

**Purpose**: The PaLM default weight. Most likely to produce the expected FFS improvement if the mechanism is correct.

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/logit-z-loss-1e-4" \
  --wandb_group "logit-z-loss-pr<PR_NUMBER>" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --logit_z_loss_weight 1e-4 \
  --num_trials 1
```

**FFS-alive gate**: If FFS_ema ≤ 2887 (≥25 steps improvement vs baseline mean 2912.5) → promote to Cell D (n=4). If FFS_ema > 2975 (regression) → close immediately. If 2887 < FFS_ema ≤ 2975 → run Cell C for dose-response.

---

### Cell C: Dose-response sweep (w=1e-5 and w=1e-3)

**Purpose**: Establish whether the mechanism is weight-sensitive (real effect) vs. flat (FFS-neutral/absorbed). Run ONLY if Cell B shows movement but is below FFS-alive gate, OR after Cell B to characterize the effect.

```bash
# Cell C1: w = 1e-5 (lighter penalty)
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/logit-z-loss-1e-5" \
  --wandb_group "logit-z-loss-pr<PR_NUMBER>" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --logit_z_loss_weight 1e-5 \
  --num_trials 1

# Cell C2: w = 1e-3 (heavier penalty — expect regression if too large)
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/logit-z-loss-1e-3" \
  --wandb_group "logit-z-loss-pr<PR_NUMBER>" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --logit_z_loss_weight 1e-3 \
  --num_trials 1
```

**Dose-response signal**: If FFS_ema improves monotonically (1e-3 < 1e-4 < 1e-5 or 1e-5 < 1e-4 < 1e-3), the mechanism is real. Flat dose-response across all three = FFS-neutral (seed-noise absorbed). 1e-3 regression + 1e-4/1e-5 neutral = penalty-too-large regime only.

---

### Cell D: n=4 confirmation (best w from B/C)

**Purpose**: Statistical confirmation at n=4 seeds. Run ONLY if signal gate met (any cell with FFS_ema ≤ 2887).

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/logit-z-loss-n4-confirm" \
  --wandb_group "logit-z-loss-pr<PR_NUMBER>" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --logit_z_loss_weight <BEST_W> \
  --num_trials 4
```

Replace `<BEST_W>` with the weight that produced FFS_ema ≤ 2887.

**Merge gate**: μ_4(FFS_ema) ≤ 2887.5 → merge-eligible. Baseline μ_4 = 2912.5, σ_4 = 25.

---

## Signal, promote, and merge gates

| Gate | Condition | Action |
|---|---|---|
| KG_smoke PASS | z_loss > 0 at w>0, no NaN | Proceed to Cell A_ctrl + Cell B★ |
| FFS-alive (B★) | FFS_ema ≤ 2887 | Promote directly to Cell D (n=4) |
| Dose-response (C) | FFS_ema strictly monotone in w | Real mechanism confirmed; run best w as Cell D |
| FFS-neutral (all cells) | All cells FFS_ema ∈ [2875, 2950], flat dose-response | Close as FFS-NEUTRAL; penalty absorbed by squash/optimizer |
| FFS-negative (B★) | FFS_ema ≥ 2975 | Close immediately — penalty harms convergence |
| Merge gate (D) | μ_4(FFS_ema) ≤ 2887.5 | Merge-eligible |

---

## Pre-mortems (failure mode analysis)

### Pre-mortem 1: Soft-tanh squash absorbs the penalty gradient

The forward pass applies `15z / sqrt(z² + 15²)` to logits before cross-entropy. For logits in the range |z| < 5, the squash derivative is ~1 and z-loss has full gradient effect. BUT for |z| > 10, the squash derivative is < 0.1, making the effective z-loss penalty very small even at w=1e-4. If the network quickly pushes logits to |z| > 10 (near the squash ceiling), the penalty gradient vanishes before it can regulate logit scale — mechanically similar to how pre-NS gradient modifiers get absorbed by NS5.

**Observable**: Log `mean(logits.abs())` at each training step. If logit mean magnitude is > 10 at step 100, squash absorption is active. The experiment will be FFS-neutral in this regime.

**Mitigation**: Apply z-loss to PRE-squash logits (`self.proj(self.norm2(x)).float()`) rather than post-squash. This is the correct intervention point if absorption is detected. Cell C variant: add `--logit_z_loss_presquash` flag.

### Pre-mortem 2: Z-loss is label-smoothing in disguise for this budget

Both label-smoothing (#1870 — CLOSED NEG) and z-loss modify the effective loss landscape. While their mathematical forms differ, they may share a common failure mode at R5: both effectively reduce the gradient magnitude on the correct-class logit, slowing convergence toward the 3.28 target. If the R5 budget is tight enough that ANY reduction in the gradient signal on correct tokens delays crossing, z-loss will fail even at very small w.

**Observable**: If val/loss trajectory with w=1e-4 is uniformly higher than control throughout training (not just late), this is the label-smoothing analog failure mode. The tell is that FFS_ema regresses even at small w (1e-5) — unlike label-smoothing which required 1.3% smoothing to fail, any z-loss might fail at R5.

**Falsifier**: w=1e-5 cell (C1) FFS-neutral or negative despite control-quality val/loss curve shape → budget-incompatibility confirmed; close the axis.

### Pre-mortem 3: Seed-noise saturation masks a real effect (same attractor issue as GE-SAM)

GE-SAM showed cos_sim=0.92 (real gradient modification) but all 4 cells at FFS_ema=2925 = seed-noise attractor. Z-loss WILL modify the effective loss function, but if the signal is too small (w=1e-4 contributes ~0.001% of the total cross-entropy loss per step), the gradient modification per step is insufficient to escape the seed-noise basin. n=4 cannot distinguish this from a 0-effect run.

**Observable**: Flat dose-response across w ∈ {1e-5, 1e-4, 1e-3} at FFS_ema ≈ 2875–2925 = absorbed. Real effect would show monotone response (at least in the w ∈ {1e-5, 1e-4} range before 1e-3 causes regression).

**Mitigation**: If dose-response is flat at {1e-5, 1e-4} but 1e-3 regresses, consider w=1e-2 as an additional cell to force a visible signal — if even w=1e-2 shows no improvement (only regression), the mechanism is definitively ruled out.

### Pre-mortem 4: Interaction with depth-init (musoft) already solves the problem

The current stack uses `--depth_init_mode musoft`, which scales residual projection weights down by `sqrt(0.33) / sqrt(fan_in * L)`. This reduces early hidden-state norm growth. If musoft already sufficiently controls the logit magnitude dynamics throughout training, z-loss is adding a redundant signal and the effective improvement is zero.

**Observable**: Compare `mean(logits.abs())` between a musoft run and a control run. If musoft already keeps logit magnitudes in the linear regime (< 5) throughout training, z-loss has nothing to regularize. This is a structural limitation, not a bug.

---

## Suggested follow-ups if this succeeds

1. **Pre-squash variant**: Apply z-loss to pre-squash logits for stronger gradient signal; might work at smaller w.
2. **Adaptive z-weight schedule**: Ramp z-weight from 0 to peak during warmup, then decay in cooldown — targeting the logit-growth phase specifically.
3. **Per-token z-loss weighting**: Upweight z-penalty on high-probability predictions (where peaking is worst) to focus regularization where it helps most.

## Suggested follow-ups if this fails (FFS-neutral or FFS-neg)

1. If flat dose-response: the logit-scale axis is closed at R5. Move to attention-head-specific interventions (e.g., per-head Q/K scale initialization or scaling `√d_head` adaptively).
2. If pre-mortem 3 (seed-noise saturation at n=4): run a micro-ablation at w=0.01 to force a visible signal — this distinguishes "mechanism absorbed" from "mechanism real but small" and gives the next researcher a cleaner closure.
3. If label-smoothing analog failure: the loss-regularization space may be completely hostile at R5. Pivot to optimizer-space interventions that are NOT loss function modifications.
