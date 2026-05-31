# Fresh Hypothesis for g1r5-alphonse
Generated: 2026-05-31

---

## 1. Slug

`stochastic-depth-residual-dropout`

---

## 2. One-Sentence Summary

Apply stochastic depth (random per-block residual zeroing with linear survival schedule) to the transformer blocks during training, forcing earlier layers to build self-sufficient representations and sharpening early-training loss descent to lower FFS.

---

## 3. Mechanistic Argument

**What stochastic depth does:** During a forward pass each residual branch (attn or MLP) is independently kept with survival probability `p_l` and zeroed-and-rescaled otherwise. The rescaling `x / p_l` (when using "expected-value" mode) preserves the gradient expectation at the zeroed block's input. At evaluation the full network runs deterministically.

**Why FFS should improve:**

- The FFS metric is dominated by the loss descent rate in the first ~2500 steps, before the cooldown saturates at step ~3000. Any mechanism that steepens the early descent curve directly compresses FFS.
- With stochastic depth, later blocks are randomly disabled, so gradients must flow through fewer blocks on some micro-batches. Early blocks receive stronger, less-diluted gradient signal in those steps, learning faster and reducing loss sooner.
- The effective depth seen per mini-batch is shallower on average, which is equivalent to increasing the "per-layer learning rate" without changing the optimizer. This is a regularization effect that has empirically been shown (Huang et al. 2016) to compress loss descent in early training at the cost of slightly higher asymptotic loss — a worthwhile trade when we care about FFS rather than final loss.
- The linear survival schedule (1.0 at block 0 → p_L at the deepest block, default p_L ≈ 0.85-0.9 for 12 layers) minimally disrupts the shallowest layers that carry the most gradient signal, while randomizing the deeper layers that already converge faster thanks to depth-aware init (`musoft`).
- Because `depth_init_mode=musoft` already scales residual projection std by 1/sqrt(L), the two mechanisms are complementary: `musoft` reduces the initial residual contribution magnitude of deep layers, while stochastic depth randomly zeros them during training — both push the network toward relying less on deep layers early in training.

**Why this is distinct from all in-flight work:**

All 7 in-flight experiments operate in optimizer-space or gradient-space: label smoothing (loss function), μ-cooldown (LR schedule), GC (gradient clipping), GE-SAM (gradient perturbation), Lookahead-Muon (momentum accumulation), annealed gradient noise (gradient injection), Schulz-square polish (NS polynomial). Stochastic depth operates entirely in the **forward pass** — it is invisible to the optimizer and does not alter any gradient computation rule; it changes which subgraph the gradient flows through on a given step.

---

## 4. Orthogonality Table

| Axis | Mechanism | Orthogonal to SD? | Notes |
|------|-----------|-------------------|-------|
| NS_ITER=6 | Newton-Schulz polynomial iterations | Yes | Orthogonal: optimizer update rule unchanged |
| SOAP_ATTN | Eigenbasis preconditioning on attn weights | Yes | Orthogonal: preconditioner sees the same gradient distribution |
| LR_MLP=0.055 | MLP group learning rate | Yes | SD does not change the learning rate |
| WD_SCHEDULE=ramp_down | WD linearly decays | Yes | WD applied after update, independent of forward pass |
| LR_SCALARS=0.03 | Scalar (RMSNorm gains) LR | Yes | These params are never dropped by SD |
| DEPTH_INIT=musoft | Residual std scaled by 1/sqrt(L) | Complementary | SD zeroes deep layers; musoft shrinks their init magnitude |
| LR_COOLDOWN=cosine | Cosine cooldown shape | Yes | Schedule applied to optimizer, not forward pass |
| EMA_EVAL=0.99 | SWA-style EMA at eval | Yes | EMA averages the full model; eval is always deterministic |
| In-flight: label-smooth | Loss fn change | Yes | Loss computed after full forward pass |
| In-flight: μ-cooldown | LR schedule | Yes | |
| In-flight: GC | Gradient clipping | Yes | |
| In-flight: GE-SAM | Gradient perturbation | Yes | |
| In-flight: Lookahead-Muon | Momentum accumulation | Yes | |
| In-flight: annealed grad noise | Gradient injection | Yes | |
| In-flight: Schulz-square polish | NS polynomial | Yes | |

---

## 5. Implementation Surface

The only change required is to the `Block.forward` method and the `GPT.__init__` method. No optimizer, schedule, or data changes.

### Core code snippet

```python
# --- In GPT.__init__, after building self.blocks ---
# survival_prob_per_block[l] = 1 - (l / (num_layers - 1)) * (1 - drop_path_rate)
# For num_layers=12, drop_path_rate=0.1: probs go from 1.0 down to 0.9
import torch

class GPT(nn.Module):
    def __init__(self, vocab_size: int, num_layers: int, model_dim: int,
                 drop_path_rate: float = 0.0):
        super().__init__()
        self.embed = nn.Embedding(vocab_size, model_dim).bfloat16()
        self.blocks = nn.ModuleList([Block(model_dim) for _ in range(num_layers)])
        self.proj = Linear(model_dim, vocab_size)
        self.norm1 = RMSNorm(model_dim)
        self.norm2 = RMSNorm(model_dim)
        # Linear survival schedule: block 0 = 1.0, block L-1 = (1 - drop_path_rate)
        if drop_path_rate > 0.0:
            self.survival_probs = [
                1.0 - (i / max(num_layers - 1, 1)) * drop_path_rate
                for i in range(num_layers)
            ]
        else:
            self.survival_probs = None

    def forward(self, inputs: Tensor, targets: Tensor):
        x = self.norm1(self.embed(inputs))
        for i, block in enumerate(self.blocks):
            if self.training and self.survival_probs is not None:
                p = self.survival_probs[i]
                if torch.rand(1).item() < p:
                    x = x + block.attn(block.norm1(x)) / p
                    x = x + block.mlp(block.norm2(x)) / p
                # if dropped: x unchanged (residual skip identity)
            else:
                x = block(x)
        logits = self.proj(self.norm2(x)).float()
        logits = 15 * logits * (logits.square() + 15**2).rsqrt()
        return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1),
                               reduction="sum")
```

**Alternative (cleaner) implementation using a DropPath module:**

```python
def drop_path(x: Tensor, survival_prob: float, training: bool) -> Tensor:
    """Apply stochastic depth to a residual branch output."""
    if not training or survival_prob >= 1.0:
        return x
    # Bernoulli mask: shape (B, 1, 1) broadcasts over T and D
    mask = torch.rand(x.size(0), 1, 1, device=x.device, dtype=x.dtype)
    mask = (mask < survival_prob).float() / survival_prob
    return x * mask
```

Then in `Block.forward`:
```python
def forward(self, x: Tensor, survival_prob: float = 1.0) -> Tensor:
    x = x + drop_path(self.attn(self.norm1(x)), survival_prob, self.training)
    x = x + drop_path(self.mlp(self.norm2(x)), survival_prob, self.training)
    return x
```

And in `GPT.forward` pass `self.survival_probs[i]` to each block call.

**CLI flag to add:**
```python
parser.add_argument("--drop_path_rate", type=float, default=0.0,
                    help="Max stochastic depth drop probability at deepest block (linear schedule)")
```

---

## 6. Experimental Cells

| Cell | drop_path_rate | R5 stack | train_steps | Seeds | Purpose |
|------|----------------|----------|-------------|-------|---------|
| A (smoke) | 0.10 | full R5 | 300 | 1 | Verify loss finite, SD code correct, no regression |
| B (screen-low) | 0.05 | full R5 | 2500 | 1 | Check FFS_ema vs 2975 gate |
| C (screen-mid) | 0.10 | full R5 | 2500 | 1 | Primary screen cell |
| D (screen-high) | 0.15 | full R5 | 2500 | 1 | Upper bound on drop rate |
| E (confirm) | best of B/C/D | full R5 | 3250 | 4 | Stat-sig confirmation n=4 |

If no cell in B/C/D reaches FFS_ema ≤ 2975, close after screen. Do not run cell E.

---

## 7. KG_Smoke Gate (Cell A)

Run 300 steps. Pass conditions:
- `train/loss` is finite at step 300 (no NaN/Inf).
- `train/grad/global_norm` is finite and below 50.
- W&B logs show `val/loss` is logged at least once.
- No CUDA OOM or Python exception.

If any condition fails, diagnose the bug before continuing.

---

## 8. Pass / Fail Gates

**FFS-alive gate (cell B, C, or D):** At least one cell achieves `speedrun/final_first_step_to_target` ≤ 2975 (EMA-based FFS) on n=1. This is the screen pass threshold — below the baseline mean (2912.5) is not required at screen stage.

**Confirm gate (cell E):** Mean FFS_ema over 4 seeds ≤ baseline 2912.5 with margin (3.28 - μ_val) * sqrt(4) ≥ 0.004.

**Val-loss floor:** No cell should have `speedrun/final_best_val_loss` above 3.29 at the chosen step count (indicates the drop rate is too high and hurts late-training convergence).

---

## 9. Stop Conditions

Stop and close after cell C if:
- All of B, C, D have FFS_ema > 3000 (the mechanism is not alive at 1 seed).
- Cell C shows `speedrun/final_best_val_loss` > 3.30 (stochastic depth is hurting convergence too much; the regularization is too strong for this dataset size / step count).
- Training loss explodes or goes NaN in any cell (implementation bug or compatibility issue with `muoft` init that should be debugged first).

Stop and close after cell E if:
- Mean FFS_ema over 4 seeds does not beat 2912.5, even if individual seeds pass.

---

## 10. Pre-Mortems

**Failure mode 1 — Too little training budget to benefit:**
Stochastic depth is a regularizer. On small models trained for a short time, the regularization effect may not convert to faster early descent; instead it may simply slow convergence (higher loss at every checkpoint). The 3250-step budget and 124M-parameter model may be in the regime where drop rates even as low as 5% reduce net loss descent speed. Detectable in cell C by checking if the full loss curve is shifted up uniformly versus just stretched, which would indicate regularization dominates.

**Failure mode 2 — Conflict with depth_init_mode=musoft:**
`musoft` initializes residual projections with std scaled by 1/sqrt(L), which already reduces the magnitude of deep-layer contributions. Stochastic depth zeroing those same deep layers may double-penalize early training signal from deep layers to the point where the model effectively trains as a shallower network — potentially reducing representational capacity and slowing FFS rather than accelerating it. Detectable by comparing `train/weight_type/Linear` norms in the dropped vs. non-dropped run.

**Failure mode 3 — Batch-level noise is too high:**
The batch-level Bernoulli mask (one draw per sample in the batch) introduces high variance in the gradient estimate when batch size per GPU is small. For nanoGPT's batch size (batch=B, seq=1024 tokens), if the effective tokens-per-step is already small, the SD noise could hurt optimizer convergence despite the theoretical benefit. This interacts specifically with Muon's Newton-Schulz step which normalizes the gradient matrix — if the gradient is noisy, NS amplifies the noise rather than filtering it. Can be partially mitigated by using a single block-level draw per step rather than per-sample, at the cost of less regularization.
