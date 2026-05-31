# Fresh Hypothesis for g1r5-thorfinn (post-#1870 closure)

Generated: 2026-05-31
Context: thorfinn #1870 label-smoothing α=0.05 closed FFS-NEG (val/loss=3.3154, never crossed 3.28).
Triggering closure: Loss-function-space-regularization family CLOSED. AdamW aux-group VALUE sweeps CLOSED (β₁ + β₂ + ε + cooldown_mu + lr_scalars value — see CURRENT_RESEARCH_STATE.md 02:36Z note).

---

## Slug

`ln-gain-init-small`

---

## One-sentence summary

Initialize all LayerNorm and RMSNorm gain parameters (γ) to α < 1.0 instead of the canonical 1.0, reducing the initial gradient scale on these parameters so that early-training variance in the residual stream is lower, yielding a smoother optimization trajectory and more reliable FFS crossings in the 2800–3050 window.

---

## Mechanistic argument

### Why γ=1.0 is not obviously optimal

Standard LayerNorm initializes γ_l = 1.0 for all layers l. At initialization, the residual stream variance accumulates additively across L=11 transformer blocks. The LN gain at each sublayer scales the normalized activations before they re-enter the residual. With γ=1.0, the initial gradient with respect to γ_l is O(1), which is the same scale as gradient contributions from the weight matrices — but the LN gain parameters are low-dimensional scalars updated by AdamW, not Muon+NS5, and their learning rate is set via `--lr_scalars`.

The risk is that full-scale γ gradients early in training drive LN gains to locally optimal but globally suboptimal values before the weight matrices have settled into well-conditioned territory. Empirically, in transformers trained without careful init or warm-up, the LN gain can overshoot and create residual variance spikes that destabilize the trajectory.

### How small γ init compresses FFS

Setting γ_l = α < 1.0 at initialization:

1. **Reduces initial gradient scale**: ∂L/∂γ_l is proportional to the normalized activations, which are O(1) after layer norm. But the loss gradient flowing back through the residual connection is scaled by γ_l itself in the backward pass. Smaller γ_l at init → smaller gradient magnitude on early steps → more conservative early-training dynamics.

2. **Lowers residual stream variance at init**: The output of each LN sublayer is scaled by γ_l before adding to the residual. With γ_l = α < 1.0, the LN contribution to the residual sum is attenuated, which stabilizes the variance growth across depth early in training.

3. **Self-correcting via AdamW**: Because γ_l is updated by AdamW with `lr_scalars`, the optimizer naturally drives γ_l toward whatever final value the loss requires. Small init just changes the starting trajectory, not the final attractor. This is NOT a permanent constraint — it is a warm-up mechanism via init.

4. **FFS-relevant phase**: FFS crossings concentrate in steps 2800–3050, during the cooldown phase (steps 975–3250). If early-training trajectory instability pushes the model into a sharper basin, the cooldown LR decay cannot compensate. A smoother early trajectory lands the model in a flatter basin by cooldown onset, increasing crossing probability.

### Precedent and theory

- **T-Fixup** (Huang et al. 2020, arxiv:2002.04745): Shows that sub-unity γ at initialization, combined with appropriate depth-scaled weight init, enables training deep transformers without warmup. Key finding: γ=0 at init is safe (degenerates to pure residual at init), γ→final via optimization.
- **Admin initialization** (Liu et al. 2020, arxiv:2004.08249): Learns residual amplification factors that start small; the LN gain participates in this as a residual-branch scaling term.
- **Small-init in nanoGPT-style models** (Takase et al. 2023, arxiv:2310.06695): Direct evidence that initializing specific transformer parameters smaller than canonical values reduces training instability and improves convergence speed.
- **musoft (depth_init_mode)**: Already in R5 stack, applies depth-scaled init to WEIGHT MATRICES (residual-branch scaling). This is structurally analogous for weight matrices. `ln-gain-init-small` is the complementary move for the LN gain scalars. musoft does NOT touch LN gains (code confirmed: it applies only to attn.c_attn, attn.c_proj, mlp.c_fc, mlp.c_proj).

---

## Orthogonality table

| In-flight axis | PR | Axis description | Orthogonal to ln-gain-init-small? |
|---|---|---|---|
| Schulz polish square α-blend | #1858 (edward) | NS5 post-processing, attn SQUARE matrices | YES — NS5 phase, not LN init |
| μ-cooldown schedule | #1880 (tanjiro) | Muon momentum anneal during cooldown | YES — momentum schedule, not LN init |
| Gradient centralization | #1885 (fern) | Pre-NS5 gradient mean subtraction | YES — gradient pre-processing, not LN init |
| GE-SAM extrapolation | #1891 (askeladd) | Gradient extrapolation before NS5 | YES — gradient manipulation, not LN init |
| Lookahead-Muon | #1895 (frieren) | Slow/fast weight wrapper around Muon | YES — trajectory averaging, not LN init |
| Annealed gradient noise | #1897 (nezuko) | SGLD-style noise into Muon grads before NS5 | YES — gradient noise injection, not LN init |
| Stochastic depth | #1903 (alphonse) | Training-time block dropout | YES — block-level dropout, not LN init |

| Closed family | Closure basis | Orthogonal to ln-gain-init-small? |
|---|---|---|
| musoft depth-init | Weight matrices only (c_attn, c_proj, c_fc, c_proj) | YES — musoft does NOT touch γ params |
| AdamW aux-group VALUE sweeps | β₁, β₂, ε, cooldown_mu, lr_scalars VALUE | YES — this is INIT change not runtime value change |
| Label-smoothing / loss regularization | #1870, #1703 (family closed) | YES — loss function, not init |
| EMA eval | #1761 (FFS-neutral) | YES — eval-time averaging, not init |
| SOAP-attn phase-gating | #818, #914, #1707, #1860 (family closed) | YES — SOAP activation gating, not init |
| NS-iter family | #1821, #1839, #1834 (family closed) | YES — orthogonalization iterations, not init |
| NS-polynomial replacement | #1826 Padé, #1838 nonsquare polish, #1825 Cayley, #1796 phase-schedule (family closed) | YES — NS5 polynomial shape, not init |
| Pre-NS normalization | #1829, #1841 (family closed) | YES — input normalization to NS5, not init |
| SOAP eigenbasis smoothing | #1776 (closed) | YES — eigenbasis computation, not init |
| Per-group EMA / adaptive staleness | historical (closed) | YES — SOAP refresh policy, not init |
| Mu decouple | historical (closed) | YES — Muon momentum separate from AdamW, not init |
| NS-input-shape | historical (closed) | YES — matrix reshape for NS5, not init |

**Summary**: `ln-gain-init-small` is the FIRST hypothesis in R5 to target the initialization of LN/RMSNorm gain scalars. It is structurally novel within 70 closures.

---

## Implementation surface

The implementation is a targeted init pass over all named LN gain parameters after model construction, before optimizer creation. The LN gain parameter names in nanoGPT-style code are typically `weight` fields on `nn.LayerNorm` modules (or the equivalent `norm.weight` fields on RMSNorm-like layers).

**Target parameters**: Any `param` in `model.named_parameters()` where `'norm' in name and 'weight' in name` OR where the parameter is a 1D scalar param from a LayerNorm/RMSNorm module. Cross-check: musoft init identifies non-Muon parameters as `'ln' in name or 'bias' in name or param.ndim < 2`. The complement of that — `param.ndim >= 2` — gets musoft. LN gains are `ndim == 1`, so they are NOT touched by musoft. The implementation fills those `ndim == 1` weight params that belong to norm layers.

```python
# Approximately 10-15 LOC; insert immediately after model construction,
# before optimizer creation, after any existing init (including musoft).

def apply_ln_gain_init(model, alpha: float = 0.5):
    """Initialize all LayerNorm/RMSNorm gain (gamma) parameters to alpha.
    
    musoft (depth_init_mode) only touches weight matrices (ndim >= 2).
    This targets the complementary set: 1D weight params on norm layers.
    Alpha < 1.0 reduces early-training residual variance.
    alpha = 1.0 is the canonical baseline (no-op).
    """
    count = 0
    for name, module in model.named_modules():
        if isinstance(module, (nn.LayerNorm, nn.RMSNorm)):
            if module.weight is not None:
                with torch.no_grad():
                    module.weight.fill_(alpha)
                count += 1
    if master_process:
        print(f"[ln-gain-init-small] Set {count} LN/RMSNorm gain params to alpha={alpha}")

# Call immediately after model construction:
# apply_ln_gain_init(model, alpha=args.ln_gain_init_alpha)
```

**CLI flag addition** (add to argparse section, ~5 LOC):
```python
parser.add_argument("--ln_gain_init_alpha", type=float, default=1.0,
    help="Initial value for LayerNorm/RMSNorm gain (gamma) params. "
         "Default 1.0 = canonical. <1.0 = small-init variant. "
         "Only changes initialization; AdamW drives gains to task-optimal values.")
```

**Integration note**: Call `apply_ln_gain_init(model, alpha=args.ln_gain_init_alpha)` AFTER `depth_init_mode` is applied (so musoft runs first on weight matrices), BEFORE optimizer creation. If model uses `torch.compile`, the init must happen before compilation.

**Total LOC**: ~20 LOC including CLI flag, function definition, and call site. Well within 50 LOC budget.

**Gotcha**: If the model uses custom RMSNorm that stores the gain as a different attribute name (e.g., `scale` instead of `weight`), the `isinstance` check will miss it. Verify by printing the count from the print statement — it should be > 0 (expected: 2 norms per block × 11 blocks + final output norm = 23 for standard nanoGPT). If count is 0, the LN/RMSNorm class is not `nn.LayerNorm` or `nn.RMSNorm` — inspect `model.named_modules()` to find the correct class.

---

## Experimental cells

### Cell 0: KG_smoke (mandatory gate)

**Purpose**: Verify implementation correctness — confirm γ params are modified, no NaN, W&B logging functional.
**Config**: `--ln_gain_init_alpha 0.5`, 100 steps, 1 seed.
**Pass gate**: Finite loss at step 100. Print from `apply_ln_gain_init` shows count > 0 (expected 23). W&B run shows `train/loss` finite at step 100.
**Fail gate**: count=0 (missed target params), NaN loss within first 10 steps (α too aggressive, which at 0.5 should not happen — if it does, check for a custom norm class that wasn't patched).

### Cell A: Control (α=1.0)

**Purpose**: Establish per-seed baseline on this run. α=1.0 is the standard init — should match historical FFS_ema≈2925 modal baseline.
**Config**: `--ln_gain_init_alpha 1.0`, 3250 steps, 1 seed (fresh, not reused from #1870).
**Expected**: FFS_ema≈2925 (baseline), val/loss≈3.271. Deviation from this indicates seed variation, not effect.
**R5 mandatory stack**: `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99`

### Cell B (primary): α=0.5

**Purpose**: Sweet-spot test. α=0.5 is the midpoint between canonical (1.0) and zero (pure residual). Prior work on small-init transformers identifies the α∈[0.3,0.7] range as effective.
**Config**: `--ln_gain_init_alpha 0.5`, 3250 steps, 1 seed.
**Expected**: FFS_ema ≤ 2900 (FFS compression vs Cell A).
**FFS-alive gate**: FFS_ema ≤ 2975.
**Promote gate**: FFS_ema ≤ 2900 OR (FFS_ema ≤ 2925 AND val/loss ≤ 3.269).

### Cell C: α=0.3

**Purpose**: Test whether more aggressive attenuation helps. T-Fixup uses γ=1/(4·L^(1/4)) ≈ 0.35 for 11-layer networks.
**Config**: `--ln_gain_init_alpha 0.3`, 3250 steps, 1 seed.
**Expected**: FFS_ema between Cell B and Cell D. If undershoot (α too small, early training too slow), FFS_ema may worsen vs Cell B.

### Cell D: α=0.7

**Purpose**: Test mild attenuation — closer to canonical but with some regularization benefit.
**Config**: `--ln_gain_init_alpha 0.7`, 3250 steps, 1 seed.
**Expected**: Small FFS compression vs Cell A, smaller than Cell B.
**Use**: If Cell B and Cell C both show improvement, Cell D confirms monotone-in-α structure and tightens the sweet-spot.

### Cell E: n=4 confirmation (conditional)

**Trigger condition**: Any of Cells B, C, D achieves FFS_ema ≤ 2975 (FFS-alive gate per human directive 2026-05-26).
**Config**: Best α from screen cells, 4 fresh seeds (independent, non-cherry-picked).
**Merge gate**: μ₄(FFS_ema) ≤ 2887.5 (per program.md statistical rule: (3.28 − μ) × √n ≥ 0.004 at n=4 requires mean val/loss < 3.278, which corresponds approximately to μ₄(FFS_ema) < 2912.5 at baseline σ; 2887.5 is the improvement gate).
**Promote gate**: μ₄(FFS_ema) ≤ 2912.5 AND (3.28 − μ₄(val)) × √4 ≥ 0.004.
**Close gate**: μ₄(FFS_ema) > 2925.

---

## KG_smoke gate

Before launching any screen cells, Cell 0 must pass:
1. `apply_ln_gain_init` count > 0 (LN gain params found and modified).
2. `train/loss` finite at step 100.
3. W&B run created with correct group tag.
4. `train/weight/all/*` telemetry shows LN gains are < 1.0 at step 0 (can verify via weight histogram if logged).

If Cell 0 fails count=0: inspect `model.named_modules()` for the correct norm class name, update the `isinstance` check accordingly, rerun smoke.

---

## Pass/Fail gates

| Gate | Condition | Action |
|---|---|---|
| KG_smoke | count > 0 AND loss finite at step 100 | Proceed to screen cells A–D |
| FFS-alive | Best screen cell FFS_ema ≤ 2975 | Proceed to n=4 Cell E |
| FFS-dead | All screen cells FFS_ema > 2975 | CLOSE: mechanism not FFS-load-bearing |
| Promote | Best cell FFS_ema ≤ 2900 OR (≤ 2925 AND Δval ≤ −2.5σ₄) | Request n=4 confirm |
| Merge | μ₄(FFS_ema) ≤ 2887.5 AND (3.28 − μ₄) × √4 ≥ 0.004 | MERGE |
| Reject n=4 | μ₄(FFS_ema) > 2925 | CLOSE |

---

## Stop conditions

1. **Cell 0 smoke fails with count=0 and cannot be fixed within 15 min**: Stop. The training script uses a custom norm class that requires a code change beyond the ~20 LOC budget. Escalate to advisor to inspect model architecture and reassign.

2. **All screen cells (B, C, D) return FFS_ema ≥ 2950**: Stop after confirming Cell A is also near baseline. The mechanism does not compress FFS on this model/stack. Close as FFS-NEG with val/loss secondary note.

3. **val/loss diverges or becomes NaN on any cell with α ≤ 0.3**: This indicates the LN gain is too small for stable early training. Stop the offending cell. If α=0.5 (Cell B) is still healthy, continue with Cell B and Cell D only.

4. **n=4 confirm μ₄(FFS_ema) > 2925**: Seed noise amplified, not reduced. Close as FFS-NEG seed-noise artifact, record as `ln_gain_init_ffs_neutral` memory rule.

---

## Pre-mortems

### Pre-mortem 1: LN gains are not FFS-load-bearing in this stack

**Failure mode**: Small γ init reduces early-training gradient scale on LN params, but the FFS bottleneck lives in the weight matrix dynamics (where musoft and NS5 operate), not in the LN gains. The LN gains converge to their task-optimal values within a few hundred steps regardless of initialization, and by the time the cooldown phase starts (step 975), γ_l ≈ γ_final for all layers. Net effect on FFS: zero.

**Observable**: FFS_ema and val/loss are identical across Cells A, B, C, D within seed noise. Δval < 1σ₄ on all cells.

**Response**: Close as FFS-NEG, record `ln_gain_init_ffs_neutral`. The mechanism is valid but not load-bearing at this model scale and training duration.

### Pre-mortem 2: α=0.5 FFS compression is seed-noise artifact

**Failure mode**: Cell B shows FFS_ema=2875, FFS_trainval=2925 — the documented seed-noise lower tail (same as #1796 Cell B, #1689 Cell A, #1860 Cell A). The val/loss improvement is < 2σ₄. n=4 confirm regresses to mean.

**Observable**: Cell B FFS_ema=2875 with FFS_trainval=2925 but val/loss ≥ 3.270. Fails promotion gate (FFS_trainval > 2900 AND val/loss > 3.269). n=4 μ₄ > 2912.5.

**Response**: Do NOT promote after single-seed seed-noise signature. Apply pre-declared promotion gate strictly. Close if n=4 triggered and μ₄ > 2912.5.

### Pre-mortem 3: Early-training instability with small α

**Failure mode**: α=0.3 or lower causes early-training loss spikes because the LN outputs are atypically small, causing the residual stream to be dominated by the raw pre-norm activations in early steps. This manifests as unstable `train/loss` in the first 200 steps, possibly NaN.

**Observable**: `train/grad/global_norm` spikes > 10× baseline in steps 1–200 for Cell C (α=0.3). Loss NaN or divergence.

**Response**: Close Cell C early (legitimate crash stop). Continue Cell B (α=0.5) and Cell D (α=0.7). If B and D are healthy, report the instability boundary at α < 0.4 and use B/D results for FFS assessment.

### Pre-mortem 4: Implementation misses custom norm class

**Failure mode**: The nanoGPT training script uses a custom RMSNorm implementation (not inheriting from `nn.LayerNorm` or `nn.RMSNorm`) that stores the gain as `self.scale` or `self.weight` on a plain `nn.Module`. The `isinstance(module, (nn.LayerNorm, nn.RMSNorm))` check returns False for all layers. `apply_ln_gain_init` modifies 0 parameters. Cell A and Cell B both behave as if α=1.0.

**Observable**: Print statement shows count=0. Cells A and B have identical metrics.

**Response**: Diagnose immediately in KG_smoke. Fix: iterate `model.named_modules()`, look for modules with a 1D `weight` attribute of dimension equal to `d_model` (768 for nanoGPT-117M). Alternatively, target by name pattern: `'norm' in name.lower()` in `model.named_parameters()` with `param.ndim == 1`. Update the isinstance check, rerun smoke. If still unresolvable, escalate to advisor.

---

## Sweep structure summary

```
Cell 0 (KG_smoke, 100 steps, α=0.5)
  → PASS: proceed to screen
  → FAIL count=0: fix norm class detection, rerun smoke

Screen (3250 steps each, 1 seed each):
  Cell A: α=1.0 (control)
  Cell B: α=0.5 (★ primary sweet-spot)
  Cell C: α=0.3 (T-Fixup-motivated)
  Cell D: α=0.7 (mild attenuation)

If best(B,C,D) FFS_ema ≤ 2975:
  Cell E: n=4 confirm at best α
  Merge if μ₄(FFS_ema) ≤ 2887.5 AND stat-sig gate

If all(B,C,D) FFS_ema > 2975:
  CLOSE FFS-NEG
```

**Recommended launch order**: Cell 0 first (verify), then Cells A + B + C + D in parallel (same GPU budget as a single n=4 run).

---

## References

1. **T-Fixup** — Huang et al. 2020. "Improving Transformer Optimization Through Better Initialization." ICML 2020. arxiv:2002.04745. Key result: initializing embedding and LN gain parameters small enables training without warmup in deep transformers.

2. **Admin Initialization** — Liu et al. 2020. "Understanding the Difficulty of Training Transformers." EMNLP 2020. arxiv:2004.08249. Key result: early-training residual amplification dominates instability; small amplification factors at init stabilize training.

3. **Small-init for NanoGPT-style transformers** — Takase et al. 2023. "Spike No More: Stabilizing the Pre-training of Large Language Models." arxiv:2312.16903. Key result: specific small-init recipes reduce training loss spikes in GPT-style models; LN gain init is one lever.

4. **musoft depth-scaled init** — Applied in current R5 stack via `--depth_init_mode musoft`. Targets weight matrices (ndim≥2) with depth-dependent scaling. This hypothesis targets the complementary set (ndim==1 LN gains), making the two init strategies composable rather than redundant.

5. **Residual stream variance analysis** — He et al. 2016 (ResNet identity init), applied to transformers in Zoph et al. 2022 (ST-MoE). Small residual branch init reduces initial residual variance growth, which is the same mechanism exploited by `ln-gain-init-small` via the LN gain pathway.

---

## Taste rubric (self-assessment)

**Research mode**: Frontier refinement (exploitation of a known-good init family in a novel axis within the current R5 stack).

| Criterion | Score | Justification |
|---|---|---|
| Mechanistic grounding | 3 | Mechanism is concrete (LN gain scale → early-training gradient scale → trajectory smoothness → FFS crossing probability), tied to T-Fixup and musoft analogues. Link to FFS is plausible but not directly confirmed by prior R5 evidence. |
| Research-state value | 3 | Will definitively close or open the LN-gain-init axis, which is genuinely unexplored in 70 closures. Cheap smoke + 4 parallel screens = ~4× the compute of a single n=4 run. Either outcome sharpens the map. |
| Execution value | 3 | ~20 LOC, staged smoke gate, parallel 4-cell screen, conditional n=4. Well-scoped. Targets FFS directly. |

**Overall**: Strong experimental design. Clear mechanism, structurally novel axis, minimal implementation risk, staged and cheap.

---

## Confidence statement

**Mechanism confidence**: Medium-high. T-Fixup and Admin-init provide strong precedent for small LN gain init being beneficial in deep transformers. The musoft analogy (same depth-scaling principle, different param group) increases plausibility. The FFS link is speculative but the mechanistic chain is coherent.

**Execution confidence**: High. Implementation is trivially verifiable via count print. KG_smoke gate catches misidentified norm classes before wasting screen compute.

**Prior evidence from R5**: None directly (this is the first LN-gain-init hypothesis). The closest is musoft (#1533, baseline), which establishes that depth-scaled init of weight matrices helps — but does not test LN gains.

**Hedge**: The LN gains converge fast under AdamW. If they reach their task-optimal values within the first 200 steps (possible at lr_scalars=0.03 with AdamW), the initialization choice may be irrelevant to FFS. This is the Pre-mortem 1 failure mode. The only way to test is to run it.
