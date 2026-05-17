# Wave 4 Research Hypotheses for g1r4-edward
## Generated: 2026-05-17 ~06:15 UTC

### Context: edward's completed work
- PR #206: Per-group clip mechanism sweep — arm-C (muon-only clip=5.0, AdamW UNCLIPPED) best at val=3.27459/fs=3250. Arm-D (no clip at all) still in flight as of 06:00 UTC.
- PR #92: QKV init — CLOSED negative (NS equilibrates QKV within 50 steps regardless of init)
- PR #115: Bias correction + beta2=0.98 — arm-C showed positive signal at val=3.27490, but stat-sig not reached; axis inconclusive

### Deduplication check — what other students are covering (do NOT overlap)
- **thorfinn**: clip=10 × NS cooldown stack; per-group clip embed/lm_head; direct embed LR; aux WD cooldown ramp
- **frieren #176**: NS=12→16 cooldown boost (merge candidate)
- **tanjiro #185**: NS iter annealing (NS=14→8)
- **alphonse #188**: AdamW uniform aux LR sweep
- **askeladd #189**: Muon² eps sweep
- **fern #203**: NS polynomial coefficient c sweep
- **nezuko #227**: AdamW β1 cooldown decay (for AdamW aux groups)

### What has never been tried
- Muon's own momentum parameter `mu` scheduling (distinct from nezuko's AdamW β1 decay)
- AdamW β2 sweep — `betas=(0.8, 0.95)` — β2=0.95 is aggressive and has NEVER been touched for AdamW aux
- Per-block layer-wise LR decay (LLRD) — `set_hparams()` applies completely uniform `eta` to ALL groups
- Muon WD cooldown scheduling — WD=0.025 constant throughout, could relax during cooldown precision window

---

## Hypothesis 1 (TOP PRIORITY): Muon Momentum `mu` Cooldown Scheduling

### What
Schedule Muon's internal momentum parameter `mu` from 0.95 (stable phase) down to a lower value during the cooldown window (steps ~1005–3350). During cooldown, the LR is already decaying linearly toward zero, so heavy momentum smoothing is counterproductive — it causes each update to be a weighted average of many stale gradients rather than the fresh, precise gradient at that step. Reducing `mu` in cooldown lets the fresh gradient signal reach Newton-Schulz more directly during the precision window.

This is mechanistically distinct from nezuko's AdamW β1 cooldown decay, which operates on the AdamW aux parameter groups. This operates exclusively on the Muon optimizer's momentum parameter.

### Why
The cooldown phase is confirmed as a precision window: PR #204 (linear vs cosine shape sweep) showed that the cooldown gradient quality matters — only linear shape works. PR #176 (NS iter boost in cooldown) confirms the cooldown window benefits from more computational investment in orthogonalization. The consistent theme is: cooldown gradients need to be sharper, not smoothed. High `mu=0.95` during cooldown means each update has an effective lookback horizon of ~20 steps (`1/(1-0.95)`). When LR is shrinking, that 20-step average increasingly blends signal from a different optimization region. Reducing `mu` shortens the horizon precisely when the optimizer is making its final adjustments.

### Implementation
In `muon_update` (lines 476–484 of `train_gpt_simple.py`), `mu` is passed as a fixed argument. The training loop calls `optimizer2.step()` via the Muon class. To make `mu` step-dependent, add a scheduler:

```python
# In training loop, after set_hparams(step):
if NANOGPT_MUON_MU_COOLDOWN > 0 and progress >= 1 - cooldown_frac:
    # Linear interpolation: mu=0.95 at start of cooldown, mu=NANOGPT_MUON_MU_COOLDOWN at end
    cooldown_progress = (progress - (1 - cooldown_frac)) / cooldown_frac
    for group in optimizer2.param_groups:
        group["mu"] = 0.95 - (0.95 - NANOGPT_MUON_MU_COOLDOWN) * cooldown_progress
```

The `Muon.step()` must then read `group["mu"]` instead of a fixed default. Check if the Muon class accepts per-group `mu` — if not, add it.

New env var: `NANOGPT_MUON_MU_COOLDOWN` (default 0.0 = disabled, i.e., mu stays 0.95 constant).

### Arm design (4-arm sweep)
| Arm | mu schedule | Purpose |
|-----|-------------|---------|
| A | mu=0.95 constant | Control — verify code change doesn't break baseline |
| B | mu: 0.95→0.85 (linear over cooldown) | Gentle reduction — short horizon in cooldown |
| C | mu: 0.95→0.70 (linear over cooldown) | Aggressive reduction — near-gradient-descent in cooldown |
| D | mu: 0.95→0.50 (linear over cooldown) | Very aggressive — halfway between GD and smoothed |

Run arm-A first as 300-step smoke gate. If arm-B shows positive signal (val < 3.27474), launch arm-C before arm-D.

### Expected result
If hypothesis is correct: arm-B or arm-C should beat the current baseline of val=3.27474. Effect size estimate: the cooldown-phase mechanism gains from #176 (NS boost, Δ≈−0.001) suggest the cooldown window has ~0.001 val improvement available via better signal quality. Mu scheduling is a softer intervention — expect Δ ≈ −0.0005 to −0.001.

If hypothesis is wrong: all arms match or regress vs arm-A. This would mean Muon's momentum accumulation is beneficial even in cooldown (perhaps because NS already absorbs the smoothing effect of high momentum via its nonlinear projection).

### Stop condition
If arm-B val > 3.2760 (worse than the current best by 0.001+), the mechanism is clearly wrong. Close the mu scheduling axis.

---

## Hypothesis 2 (HIGH PRIORITY): AdamW β2 Sweep for Aux Groups

### What
The AdamW auxiliary optimizer uses `betas=(0.8, 0.95)`. While β1=0.8 has been studied indirectly (alphonse clip mechanism, nezuko β1 cooldown), β2=0.95 has NEVER been swept. β2=0.95 is an unusually aggressive (low) second-moment decay — the standard Adam default is 0.999. With β2=0.95, the second-moment estimate `v` adapts very rapidly to recent gradient variance, giving effective LR that fluctuates heavily with batch-to-batch gradient magnitude changes. A higher β2 (e.g., 0.999) would provide a more stable adaptive LR divisor, potentially giving smoother and more controlled updates especially during the cooldown precision window.

### Why
The embed and lm_head groups are the only parameters updated by AdamW (Muon handles transformer blocks). The clip=10 mechanism (PR #165, merged) works precisely by modulating the effective LR of the embed group. If AdamW's β2=0.95 is causing noisy per-step effective LR (because the v-estimate is adapting too fast), raising β2 would directly complement the clip effect by smoothing the denominator rather than capping the numerator. These are orthogonal mechanisms: clip caps the numerator (gradient norm), β2 controls the denominator stability (v-EMA decay).

Additionally, PR #115 arm-C (bias_correction=on + beta2=0.98) showed val=3.27490 — not stat-sig but directionally positive. The β2 axis was never isolated there (bias correction was bundled). This sweep isolates β2 cleanly without bias correction changes.

### Implementation
In optimizer1 definition (lines 617–619):
```python
# Current:
optimizer1 = AdamW([...], betas=(0.8, 0.95), eps=1e-10, weight_decay=0, fused=True)

# Parameterize β2:
adamw_beta2 = float(os.environ.get("NANOGPT_ADAMW_BETA2", "0.95"))
optimizer1 = AdamW([...], betas=(0.8, adamw_beta2), eps=1e-10, weight_decay=0, fused=True)
```

New env var: `NANOGPT_ADAMW_BETA2` (default 0.95 = current behavior).

**Warning**: PyTorch's fused AdamW may have restrictions on which β2 values trigger JIT paths. Test arm-A at 0.95 first to verify identical behavior. If fused=True causes issues at non-default β2, set fused=False for the sweep (expected <2% wall-clock impact).

### Arm design (4-arm sweep)
| Arm | AdamW β2 | Notes |
|-----|----------|-------|
| A | 0.95 | Control (current behavior) |
| B | 0.98 | PR #115 arm-C directional precedent |
| C | 0.99 | Intermediate stable |
| D | 0.999 | Standard Adam default — maximum stability |

If arm-B or arm-C wins, run arm-E at the midpoint (e.g., 0.985 if B=0.98 wins). The β2 landscape is likely unimodal — one peak expected.

### Expected result
If β2 is currently too aggressive: arm-B/C/D improves over arm-A. The current val=3.27474 is already well-tuned; a β2 improvement should yield Δ ≈ −0.001 to −0.002 if the effect is real. If the current β2=0.95 is already optimal for this specific noisy small-batch regime, arms B/C/D will regress (the fast adaptation is actually helping track gradient variance in a short-horizon training run).

### Stop condition
If arms B, C, and D are all within ±0.001 of arm-A, the β2 axis is closed. The current 0.95 setting is already at or near the optimum for this benchmark.

---

## Hypothesis 3: Per-Block Layer-wise LR Decay (LLRD)

### What
The current `set_hparams()` function applies a completely uniform `eta` multiplier to ALL optimizer groups — embed, lm_head, scalars, and all transformer blocks share the same LR schedule. No per-layer or per-block differentiation has ever been tested. Apply layer-wise LR decay (LLRD): scale each transformer block's Muon LR by `decay^(num_blocks-1-l)` where `l` is the block index (0=shallowest/nearest embed, 11=deepest/nearest lm_head) and `decay ∈ {0.85, 0.90, 0.95}`. Shallower blocks receive lower LR; deeper blocks receive full LR.

### Why
LLRD is well-established in finetuning literature (BERT, GPT finetuning) and has theoretical grounding in the observation that deeper layers adapt more rapidly in distribution shift scenarios while shallower representation layers require more stable updates. In a speedrun from scratch, the argument is different: deeper layers (closer to lm_head and final logit predictions) are more directly coupled to the loss signal and may benefit from higher LR, while shallow embedding-adjacent layers provide stable intermediate representations that should change more conservatively.

The Muon optimizer's Newton-Schulz projection already normalizes gradient magnitude per block, so the inter-block LR differentiation is purely about the rate of learning, not magnitude. This is an entirely fresh axis — not touched by any wave 1-3 experiment.

### Implementation
Split the single Muon parameter group into 12 per-block groups:
```python
# Replace current optimizer2 with:
muon_param_groups = []
for block_idx, block in enumerate(model.blocks):
    llrd_scale = float(os.environ.get("NANOGPT_LLRD_DECAY", "1.0")) ** (len(model.blocks) - 1 - block_idx)
    muon_param_groups.append({
        "params": [p for p in block.parameters() if p.ndim >= 2],
        "lr": 0.035 * llrd_scale,
        "weight_decay": 0.025,
        "name": f"muon_block_{block_idx}"
    })
optimizer2 = Muon(muon_param_groups)
```

New env var: `NANOGPT_LLRD_DECAY` (default 1.0 = uniform, current behavior).

**Implementation warning**: The Muon class's `__init__` and `step` methods must accept list-of-dicts format (standard PyTorch optimizer contract). Verify this before running. Also verify that `set_hparams` correctly iterates ALL parameter groups after the split — the current code does `for opt in optimizers: for group in opt.param_groups` which should work if groups are properly registered.

### Arm design (3-arm sweep)
| Arm | LLRD decay | Block 0 (shallow) LR | Block 11 (deep) LR |
|-----|------------|----------------------|--------------------|
| A | 1.00 | 0.035 (uniform) | 0.035 (uniform) |
| B | 0.95 | 0.035 × 0.95^11 ≈ 0.0178 | 0.035 |
| C | 0.90 | 0.035 × 0.90^11 ≈ 0.0110 | 0.035 |

### Expected result
LLRD effect in speedrun (from-scratch) training is uncertain — finetuning intuitions may not transfer. If deeper block specialization is the bottleneck, arm-B/C should win. If uniform LR already provides the right balance (since Muon's NS projection normalizes magnitudes), all arms should be approximately equal.

### Stop condition
If arm-B/C are both within ±0.001 of arm-A at terminal, LLRD axis is closed.

---

## Hypothesis 4: Muon Weight Decay Cooldown Reduction

### What
Muon uses constant WD=0.025 throughout training. During cooldown, the model is making fine-grained adjustments in a shrinking LR regime. WD adds L2 decay friction proportional to weight magnitude — during cooldown this friction competes with the very gradient signals the precision window needs to land precisely. Ramp WD down from 0.025 → a lower value during cooldown: `wd(step) = 0.025 × (1 - decay_frac × cooldown_progress)`.

### Why
The cooldown window is a confirmed precision zone. The theme across wave-3 winners is: give the cooldown window better gradient quality and more computational investment. WD=0.025 is tuned for the stable phase where weight magnitudes are growing and regularization prevents explosion. During cooldown, LR is already shrinking to zero — WD's regularization role is redundant (small LR already limits weight drift). Reducing WD in cooldown is mechanistically analogous to removing friction from a landing aircraft.

Note: thorfinn wave-4 hypothesis 4 is an embed-only WD RAMP (adding WD to AdamW aux during cooldown). This hypothesis is the OPPOSITE on the Muon side — reducing WD on Muon blocks during cooldown. Mechanistically distinct and non-overlapping.

### Implementation
In `set_hparams()`:
```python
# Add to set_hparams(), after computing eta:
if NANOGPT_MUON_WD_COOLDOWN_FINAL >= 0 and progress >= 1 - cooldown_frac:
    cooldown_progress = (progress - (1 - cooldown_frac)) / cooldown_frac
    muon_wd = 0.025 - (0.025 - NANOGPT_MUON_WD_COOLDOWN_FINAL) * cooldown_progress
    for opt in optimizers:
        for group in opt.param_groups:
            if group.get("weight_decay", 0) > 0:  # Only Muon groups have WD
                group["weight_decay"] = muon_wd
```

New env var: `NANOGPT_MUON_WD_COOLDOWN_FINAL` (default -1 = disabled).

### Arm design
| Arm | WD during cooldown | Purpose |
|-----|-------------------|---------|
| A | 0.025 constant | Control |
| B | 0.025 → 0.010 (linear) | Moderate reduction |
| C | 0.025 → 0.005 (linear) | Strong reduction |
| D | 0.025 → 0.000 (linear) | No WD in final cooldown |

### Expected result
If WD is acting as friction during cooldown precision window: arm-B/C should improve. Expect Δ ≈ −0.0003 to −0.001. If WD=0.025 is already well-calibrated for cooldown or if NS projection makes WD irrelevant (NS projects to manifold where WD has no grip), all arms should match.

### Stop condition
If arm-B/C/D all regress vs arm-A, Muon WD reduction in cooldown is harmful (WD provides useful implicit regularization even in final stage). Close axis.

---

## Priority ranking for edward

1. **Hypothesis 1 (Muon mu cooldown)** — fresh axis, zero prior coverage, mechanistically motivated by wave-3 cooldown precision theme. Highest information value.
2. **Hypothesis 2 (AdamW β2 sweep)** — completely uncharted, directly complements the clip=10 mechanism by addressing denominator stability rather than numerator cap. PR #115 arm-C provides weak directional support.
3. **Hypothesis 3 (LLRD)** — higher implementation complexity, more uncertain outcome, but fresh axis. Lower priority given edward's current in-flight arm-D on #206.
4. **Hypothesis 4 (Muon WD cooldown reduction)** — lower priority, mechanistically weaker case given NS projection may neutralize WD effects.

**Assignment order**: Wait for edward #206 arm-D terminal result first. Once #206 is closed, assign Hypothesis 1. If arm-B of Hypothesis 1 shows positive signal at terminal, Hypothesis 2 is the natural next assignment.
