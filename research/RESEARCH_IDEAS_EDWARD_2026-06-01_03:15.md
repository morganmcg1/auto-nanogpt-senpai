# Research Hypothesis: MLP Activation Variant
**Student:** edward
**Date:** 2026-06-01 03:15
**Axis:** Representational capacity — MLP nonlinearity
**Research mode:** Frontier refinement (cheap discriminating probe)
**LOC delta:** ~20 LOC

---

## Hypothesis Statement

Replace the current `x.relu().square()` (ReLU²) activation in `MLP.forward` with a smooth activation function — SiLU as the primary test, with GELU and SwiGLU as escalation cells. ReLU² has a hard zero region creating structurally dead neurons and a quadratic-growth regime that may produce magnitude imbalance. Smooth activations (SiLU/GELU) have non-zero gradient everywhere, producing a more informative gradient signal for SOAP preconditioning that is already applied to MLP weights. This targets the representational-capacity bottleneck identified in the 93rd R5 closure (alphonse #1979).

---

## Background and Mechanistic Grounding

### Current code (confirmed in train_gpt_simple.py line 462)

```python
def forward(self, x: Tensor):
    x = self.fc(x)
    x = x.relu().square()  # ReLU² — target for replacement
    x = self.proj(x)
    return x
```

### Why ReLU² may limit representational capacity

ReLU² has two structural properties that may limit capacity at this scale:

1. **Hard zero region**: Any pre-activation ≤ 0 produces zero output AND zero gradient. With SOAP preconditioning (`--soap_attn`) already applied to the MLP `fc` and `proj` matrices, dead neurons reduce the effective rank of preconditioned gradient updates — partially negating the benefit of second-order curvature estimation.

2. **Quadratic magnitude growth**: Activations grow as x² for positive inputs. With no post-activation normalization in MLP, this creates large magnitude imbalances across the hidden dim that the downstream `proj` layer must compensate for implicitly.

### Why smooth activations address this

SiLU (`x * sigmoid(x)`) and GELU (`x * Φ(x)`) have non-zero gradient for all inputs including negative values ("soft negative saturation" property). This means:

- More hidden units receive gradient signal → higher effective rank in the SOAP preconditioner update
- Smoother activation landscape → more stable curvature estimates in SOAP's Kronecker factors
- More uniform activation magnitude distribution → reduced implicit bias in `proj` weight learning

SwiGLU (`silu(x_gate) * x_val`, with `fc` output doubled to 2× hidden dim) adds a learned gating mechanism that further increases representational expressivity. It is the MLP default in LLaMA, Mistral, Gemma, and PaLM — chosen via internal ablations over GELU.

### Why this is NOT in any closed family

- NOT a weight init perturbation (NS5-absorbed family is closed via `[[ns5_absorbs_2d_weight_init_perturbations_at_r5]]`)
- NOT an LR or WD schedule change (fully closed family)
- NOT a QK-norm addition: QK-norm is **already in the baseline** at line 445 (`q, k = F.rms_norm(q, (q.size(-1),)), F.rms_norm(k, (k.size(-1),))` — parameter-free RMS normalization before RoPE)
- NOT a Muon optimizer modification (askeladd #2030 in flight — avoid)
- NOT a RoPE or positional encoding change (alphonse #2042 in flight — avoid)
- MLP activation has **zero closed PRs in R5**. This is a genuinely open axis.

### Tier-shift alignment

The 93rd R5 closure (alphonse #1979, lr-warm-restart-probe) established: "FFS bottleneck is NOT local-minimum-escape — likely representational-capacity-bound." MLP nonlinearity directly controls what function the MLP sub-network can approximate. Changing the activation changes representational capacity, not optimization landscape geometry.

---

## Implementation

**Target file:** `records/track_3_optimization/train_gpt_simple.py`

### 1. Add CLI flag (argparse section, ~3 LOC)

```python
parser.add_argument("--mlp_act", type=str, default="relu2",
                    choices=["relu2", "silu", "gelu", "swiglu"],
                    help="MLP hidden activation: relu2 (default), silu, gelu, swiglu. "
                         "swiglu doubles fc output dim and uses a gated architecture.")
```

### 2. Pass activation choice through to MLP (GPTConfig or direct, ~3 LOC)

Add `mlp_act` to any config dataclass or pass directly to MLP constructor. If GPTConfig is used, add `mlp_act: str = "relu2"` to its fields.

### 3. MLP.__init__ modification for SwiGLU fc dim (~4 LOC)

```python
# In MLP.__init__, after setting hidden_dim:
self.act = mlp_act
fc_out = 2 * hidden_dim if mlp_act == "swiglu" else hidden_dim
self.fc = nn.Linear(in_features, fc_out, bias=False)
self.proj = nn.Linear(hidden_dim, in_features, bias=False)
```

### 4. MLP.forward activation dispatch (~10 LOC)

```python
def forward(self, x: Tensor):
    x = self.fc(x)
    if self.act == "relu2":
        x = x.relu().square()
    elif self.act == "silu":
        x = F.silu(x)
    elif self.act == "gelu":
        x = F.gelu(x)
    elif self.act == "swiglu":
        x_gate, x_val = x.chunk(2, dim=-1)
        x = F.silu(x_gate) * x_val
    x = self.proj(x)
    return x
```

**Total delta:** ~20 LOC. No new dependencies — `F.silu` and `F.gelu` are already in `torch.nn.functional`. The `relu2` default preserves backward compatibility exactly.

---

## Experiment Cells

### Cell A — Control (baseline confirmation, optional)
- `--mlp_act relu2` (default, no change)
- Skip if current FFS_ema baseline is fresh (within last 48h). Reuse PR #1533 baseline.

### Cell B★ — SiLU (primary falsifier, run first)
- `--mlp_act silu`
- No parameter count change, no fc dim change
- ~3 LOC effective change (dispatch in forward)
- **This is the cheapest discriminating test.** Run as n=1. If FFS_ema ≥ 2950, close axis immediately without running C or D.

### Cell C — GELU (run only if Cell B ≤ 2925)
- `--mlp_act gelu`
- GELU vs SiLU: empirically similar but GELU has heavier left tail. May interact differently with SOAP's curvature estimate on the fc/proj matrices.
- If both B and C land at ≤ 2925, pick the better one for n=4.

### Cell D — SwiGLU (run only if Cell B or C ≤ 2875)
- `--mlp_act swiglu`
- Doubles fc output dim; proj input stays the same. Parameter count increases by ~8M in fc layer.
- SwiGLU is the MLP default in LLaMA/Mistral/Gemma precisely because it outperforms ReLU-family on downstream tasks. Only worth the overhead if the smooth activation axis is confirmed alive by B or C first.

---

## Decision Tree

```
Run Cell B (SiLU, n=1)
├── FFS_ema ≤ 2875 → STRONG SIGNAL
│   ├── Run Cell C (GELU, n=1) and Cell D (SwiGLU, n=1) in parallel
│   │   ├── Pick best of B/C/D
│   │   └── Run winner at n=4 for merge gate
│   └── Merge gate: μ_4(FFS_ema) < 2912.5
├── FFS_ema = 2900–2925 → MARGINAL SIGNAL
│   ├── Run Cell C (GELU, n=1) to distinguish activation profiles
│   ├── If C also in 2900–2925 range → run best of B/C at n=2 for noise check
│   └── If n=2 mean still ≤ 2912.5 → escalate to n=4
└── FFS_ema ≥ 2950 → REGRESSION / AXIS DEAD
    ├── Do NOT run C or D
    └── Close PR: "smooth activations harmful at this scale/stack; ReLU² optimal"
```

**Kill gate:** If Cell B FFS_ema ≥ 2950 on n=1 run, close immediately. No n=4, no C or D.

**Merge gate:** n=4 μ_4(FFS_ema) < 2912.5. Per significance rule: `(3.28 - mu) * sqrt(4) >= 0.004` → need mu < 2912.

---

## Reproduce Commands

### Cell B★ (SiLU, n=1 — run first):
```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --mlp_act silu \
    --wandb_name "g1r5-edward/mlp-act-silu-n1-probe" \
    --wandb_group "g1r5-edward/mlp-act-variant"
```

### Cell C (GELU, n=1 — run if Cell B ≤ 2925):
```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --mlp_act gelu \
    --wandb_name "g1r5-edward/mlp-act-gelu-n1-probe" \
    --wandb_group "g1r5-edward/mlp-act-variant"
```

### Cell D (SwiGLU, n=1 — run only if Cell B or C ≤ 2875):
```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --mlp_act swiglu \
    --wandb_name "g1r5-edward/mlp-act-swiglu-n1-probe" \
    --wandb_group "g1r5-edward/mlp-act-variant"
```

### n=4 confirmation (after best cell identified, ≤ 2925):
```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --mlp_act <BEST_ACT> \
    --wandb_name "g1r5-edward/mlp-act-<BEST_ACT>-n4-confirm" \
    --wandb_group "g1r5-edward/mlp-act-variant"
```

---

## Expected Observables

1. **Training loss at step 100**: SiLU/GELU should show marginally lower loss than ReLU² if dead neurons are significant. If training loss curves are identical through step 100, the dead-neuron mechanism is not active at this scale.
2. **EMA eval loss convergence speed**: Smooth activations may reach the target loss threshold faster (lower FFS) due to richer gradient signal, or may plateau earlier if ReLU²'s sparsity was beneficial for generalization.
3. **W&B activation statistics (optional)**: Log mean and std of post-activation hidden units. If ReLU² produces significantly higher variance than SiLU, the magnitude imbalance explanation is supported.

---

## External Evidence

- SiLU/GELU outperform ReLU-family in transformer LM pretraining at multiple scales (GPT-2, Chinchilla, LLaMA ablations). Typical improvement: 0.1-0.5% on validation perplexity.
- SwiGLU is the default MLP in PaLM, LLaMA, Gemma, Mistral — chosen empirically over GELU in internal ablations. Improvement at 7B scale: ~0.5-1%.
- At smaller scales (≤125M params, short training), the activation advantage is smaller and noisier. The FineWeb speedrun at 10k steps is aggressive; the n=1 Cell B falsifier is needed to check if the gap is detectable.
- SOAP preconditioning (already in stack via `--soap_attn`) captures second-order curvature in fc/proj matrices. A smoother activation landscape may reduce variance in the SOAP gradient signal, making the preconditioner more effective — potentially a compounding benefit.

---

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| SiLU/GELU FFS-NEUTRAL (NS5+SOAP already compensates for dead neurons) | Medium | Kill gate on Cell B; ~25 min to falsify |
| SwiGLU parameter increase causes overfitting at 10k steps | Low-medium | Only run D if B/C confirm axis alive at ≤ 2875 |
| `--mlp_act` flag implementation conflicts with existing code | Low | Default `relu2` preserves backward compat exactly |
| frieren #1966 merges before edward completes, shifting baseline | Medium | If frieren merges (new baseline 2875), rebase and adjust gate to FFS_ema < 2875 |

---

## Taste Rubric

| Criterion | Score | Rationale |
|---|---|---|
| Mechanistic grounding | 3/4 | Mechanism (dead neurons reduce effective SOAP preconditioner rank) targets a specific property of the current stack. Code location is precise. Prior art in transformer LM ablations supports smooth activation benefit. The dead-neuron claim is plausible but not directly measured in R5 yet. |
| Research-state value | 3/4 | Result is discriminating either way: win confirms MLP representational capacity as an open axis; FFS-NEUTRAL closes the axis cleanly and constrains the bottleneck hypothesis further. |
| Execution value | 4/4 | ~20 LOC change, n=1 Cell B falsifier in ~25 minutes, staged escalation to C/D only on positive signal. Very high information per GPU-hour. No new dependencies. |

**Overall:** High-value frontier refinement. Cheap to run, interpretable result, targets a specific untried axis on the representational-capacity tier with staged escalation.

---

## Confidence Assessment

**Mechanistic analogy:** Moderate. Smooth activations outperforming ReLU-family is well-supported externally, but no R5 evidence yet. The connection to FFS improvement specifically (rather than just perplexity) is speculative — FFS is sensitive to the convergence trajectory shape, not just final loss.

**Expected FFS_ema for Cell B★:** Likely 2875 or 2912.5 (attractor). A result at 2850 (below attractor) would be surprising and high-leverage. A result at 2950+ would close the activation axis and constrain the bottleneck to something other than MLP nonlinearity.

**Stop condition:** If Cell B FFS_ema ≥ 2950 and Cell C (run opportunistically) also ≥ 2950, close the MLP activation axis entirely. ReLU² appears optimal for the NS5+SOAP+musoft stack at R5 scale.
