# Research Hypothesis: clip-aux-norm
**Generated**: 2026-06-02 02:05Z
**Student target**: tanjiro
**Advisor branch**: auto-nanogpt-1gpu-r5

---

## Hypothesis

**Slug**: `clip-aux-norm`

**One-line summary**: Apply per-group L2 gradient norm clipping exclusively to the three AdamW auxiliary parameter groups (adam_embed, adam_lm_head, adam_scalars) before `optimizer1.step()`, leaving Muon body weights entirely untouched (NS5 already normalizes their gradient scale).

**Research mode**: Diagnostic / frontier refinement

---

## Motivation and Mechanism

The current R5 stack runs three AdamW aux groups at very different learning rates:
- `adam_embed`: lr=0.3 (10× higher than lr_mlp=0.055)
- `adam_lm_head`: lr=1/320 ≈ 0.003125
- `adam_scalars`: lr=args.lr_scalars (baseline 0.03)

The embed group at lr=0.3 is the highest-risk gradient pipeline. When the FineWeb token distribution has rare or high-frequency tokens, gradient spikes from the embedding lookup can be large in L2 norm and corrupt AdamW's first and second moment accumulators (m_t and v_t) in a way that persists for many steps. Once v_t is inflated by a spike, it dampens the effective step for many subsequent steps (v_t decays with β₂=0.95, so a spike halves v_t's contribution only after ~14 steps). This is a qualitatively different failure mode from the Muon body: NS5 orthogonalization in Newton-Schulz 5 already provides an implicit gradient scale normalization for 2D weight matrices, clamping the effective update magnitude. The aux groups have no such protection.

The hypothesis: a moderate per-group clip threshold applied only to optimizer1's groups will smooth the moment accumulator trajectory during the warmup and body phases, giving AdamW aux parameters a more stable optimization path without interfering with Muon's NS5 orthogonalization.

**Predicted mechanism trace**:
- If alive: `train/grad/all/embed` norm spikes become less frequent; embed weight RMS trajectory becomes smoother; FFS improves or EMA loss at step 2875 drops
- If dead: clipping is never active (aux grad norms are naturally small throughout), no change in any metric vs. control

**Key distinction from closed PRs**:
- PR #521: global `clip_grad_norm_(model.parameters(), max_norm)` clips ALL parameters including Muon body weights — fundamentally different scope
- PR #283 / #887 / #1441: Adaptive Gradient Clipping (AGC) — adaptive per-parameter threshold = `lambda * param_norm`, not a fixed L2 norm per group
- This proposal: fixed L2 norm threshold applied per optimizer1 group (not per parameter, not adaptive, not global) — Muon/optimizer2 completely untouched

---

## Novelty Verification

All `gh search prs` commands were run against `morganmcg1/modded-nanogpt-senpai` with label `auto-nanogpt-1gpu-r5`. Zero hits required for the axis to be novel.

```
gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "aux clip"
# RESULT: ZERO HITS ✓

gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "adam clip"
# RESULT: ZERO HITS ✓

gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "clip aux"
# RESULT: ZERO HITS ✓

gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "clip norm"
# RESULT: PR #521 (global clip_grad_norm_ on ALL params), PR #756 (centralization)
#   → Both confirmed as DIFFERENT scope: #521 clips model.parameters() globally,
#     proposed approach clips ONLY optimizer1.param_groups (3 aux groups)

gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "adamw clip"
# RESULT: PR #283 (AGC — adaptive per-parameter scaling, not fixed group L2 norm)
#   → Confirmed DIFFERENT: AGC threshold = lambda * param_norm (adaptive, per-parameter);
#     proposed approach = fixed L2 norm threshold per optimizer group (not per parameter)

gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "embed clip"
# RESULT: PR #1502 (Sophia-G 2nd-order curvature on AdamW aux groups)
#   → Confirmed DIFFERENT: #1502 is a second-order preconditioner, not gradient clipping

gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "gradient clipping"
# RESULT: PR #521 (global), #283/#887/#1441 (AGC variants), #993 (anomaly reset)
#   → ALL confirmed different: global scope, adaptive per-param, or anomaly detection
```

**Conclusion**: The specific combination of (1) fixed L2 norm threshold, (2) applied per-optimizer-group (not per-parameter, not globally), (3) restricted to optimizer1 aux groups only (optimizer2/Muon excluded) — is a genuinely untested axis at R5.

---

## Memory-Rule Compliance

Checking all 12 closed families from advisor memory:

| Family | Rule | Compliance |
|--------|------|-----------|
| SGLD/additive pre-NS gradient modifiers | Absorbed by NS5; need NS5-bypass mechanism | COMPLIANT — clip-aux-norm applies to AdamW aux (optimizer1), not Muon/NS5 pipeline |
| LN gain init below 1.0 | FFS-NEG at R5 | COMPLIANT — does not touch init |
| NS5 absorption family (2D init, depth-LR, pre-NS5 grad mods) | Closed | COMPLIANT — clip-aux-norm is post-grad, pre-AdamW-step on aux groups only |
| NS5 internal eps | Irrelevant at R5 gradient scale | COMPLIANT — does not touch NS5 |
| SF/Polyak cooldown-freeze failure | Needs cooldown-start reset or SWA accumulation | COMPLIANT — does not involve EMA/averaging |
| Warmup-mu ramp axis | CLOSED — NS5 absorbs gradient-history perturbations at steps 0-975 | COMPLIANT — does not touch mu schedule |
| AdamW aux tetrad (β₁, β₂, eps, WD) | ALL CLOSED | COMPLIANT — clip-aux-norm is not a hyperparameter of AdamW itself; it is a pre-step gradient operation |
| n=1→n=4 dual-metric attractor reversion | When FFS_ema=2875/FFS_trainval=2925, escalate to n=4 | COMPLIANT — escalation protocol included in cell design |
| Global gradient clipping (PR #521) | Closed as FFS-neutral | COMPLIANT — restricted to aux groups only, mechanistically distinct |
| AGC variants (#283/#887/#1441) | Closed | COMPLIANT — not adaptive, not per-parameter |
| Advisor branch commit hygiene | Commit on advisor branch | COMPLIANT — this file committed on advisor branch |
| Merge gate | FFS_ema ≤ 2862.5 OR val ≤ 3.26507 at FFS=2875 | Gate defined below |

---

## Current Baseline

- **μ_4 FFS_ema**: 2875.0 steps (σ=0.0, n=4, zero variance)
- **μ_4 val_loss**: 3.27007
- **Single-run merge gate**: FFS_ema ≤ 2862.5 OR val_loss ≤ 3.26507 at FFS=2875
- **n=4 merge gate**: FFS_ema_mean ≤ 2862.5 OR `(3.28 - mu_val) * sqrt(4) >= 0.004`
- **Mandatory baseline stack** (must appear in every cell):

```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
--lr_scalars 0.03 --depth_init_mode musoft \
--lr_cooldown_shape cosine --ema_eval_decay 0.99
```

Note: `--mu_cooldown_target 0.80` is the baked-in code default (not needed on CLI).

---

## Implementation Patch (~15 LOC)

### 1. In `parse_args()` (add after other clip/norm args, ~line 95-115 area):

```python
parser.add_argument("--clip_aux_norm", type=float, default=None,
                    help="Per-group gradient L2 norm clip threshold for AdamW aux groups "
                         "(adam_embed, adam_lm_head, adam_scalars). None=disabled. "
                         "Applied per group independently before optimizer1.step(). "
                         "Muon body weights are NOT clipped (NS5 normalizes them).")
```

### 2. In training loop (insert between telemetry logging and `opt.step()`, ~lines 1200-1201):

**Current code** at lines 1200-1202:
```python
    # [telemetry logging ends here]
for opt in optimizers:
    opt.step()
```

**After patch**:
```python
    # [telemetry logging ends here]
# Per-aux-group gradient norm clipping (optimizer1 only; Muon/optimizer2 untouched)
if args.clip_aux_norm is not None:
    for group in optimizer1.param_groups:
        torch.nn.utils.clip_grad_norm_(group["params"], args.clip_aux_norm)
for opt in optimizers:
    opt.step()
```

**Total lines changed/added**: 5 LOC in parse_args + 3 LOC in training loop = 8 LOC net, well within 15-20 LOC budget.

**No imports needed**: `torch.nn.utils.clip_grad_norm_` is already available via the existing `import torch`.

**No interaction with gradient accumulation**: The all_reduce of gradients happens before this point (lines ~1165-1172), so the clipped gradients will be the reduced gradients. This is correct — we want to clip the final gradient that AdamW will consume.

**W&B telemetry**: The existing `log_training_telemetry(...)` call logs `train/grad/all/*` including embed norms. This call happens BEFORE the clip insertion point, so the logged norms reflect the pre-clip gradients. This is intentional and useful for diagnosing whether clipping is ever active. If desired, the student may add a post-clip norm log, but this is optional.

---

## Experimental Cells

All cells use the mandatory baseline stack. Default `train_steps` from the training script is used unless noted.

### Cell 0 (Control — clip disabled)
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --wandb_name "tanjiro/clip-aux-norm-ctrl" \
  --wandb_group "clip-aux-norm"
```
Expected: FFS_ema ≈ 2875 (baseline reproduction check)

### Cell 1 (Tight clip — catches only large spikes)
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --clip_aux_norm 0.3 \
  --wandb_name "tanjiro/clip-aux-norm-0p3" \
  --wandb_group "clip-aux-norm"
```
Risk: may be too aggressive on embed updates given embed lr=0.3; watch for slow early convergence

### Cell 2 (Moderate — primary screening candidate)
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --clip_aux_norm 0.7 \
  --wandb_name "tanjiro/clip-aux-norm-0p7" \
  --wandb_group "clip-aux-norm"
```
Rationale: 0.7 is approximately 2-3× the expected per-group RMS grad norm for embed at steady state

### Cell 3 (Loose — rarely active, minimal interference)
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --clip_aux_norm 1.5 \
  --wandb_name "tanjiro/clip-aux-norm-1p5" \
  --wandb_group "clip-aux-norm"
```
Rationale: should only activate during rare gradient spike events; safest test of the mechanism

### Cell 4 (Very loose — near-off, sanity check)
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --clip_aux_norm 3.0 \
  --wandb_name "tanjiro/clip-aux-norm-3p0" \
  --wandb_group "clip-aux-norm"
```
Expected: near-identical to control; if FFS is identical to ctrl, mechanism is inert at this threshold

---

## Merge Gates and Decision Protocol

**Single-run merge gate (n=1)**:
- FFS_ema ≤ 2862.5 (5σ below μ_4=2875), OR
- val_loss ≤ 3.26507 at any FFS_ema ≤ 2875

**If n=1 result lands on attractor {FFS_ema=2875, FFS_trainval=2925}**:
- DO NOT promote or close. Escalate to n=4 per memory rule.
- n=4 gate: FFS_ema_mean ≤ 2862.5 OR `(3.28 - mu_val) * sqrt(4) >= 0.004`

**Decision tree**:
1. Run Cell 2 (0.7) first as primary screening candidate
2. If FFS_ema ≤ 2862.5: run 3 more seeds at same threshold → terminal result
3. If FFS_ema = 2875 (attractor): escalate to n=4
4. If FFS_ema > 2875: try Cell 3 (1.5) — maybe clip is too tight
5. If Cell 3 also worse than baseline: clip-aux-norm is inert at R5, close
6. If Cell 3 shows improvement: fine-tune between 0.7 and 1.5

**Falsifying result**: clip-aux-norm is falsified if Cells 1-4 all produce FFS_ema ≥ 2875 and grad norm telemetry shows aux norms are naturally below thresholds throughout (clip never activates). In that case, the mechanism assumption (that aux grad spikes are causing moment corruption) is wrong for FineWeb at R5 scale.

---

## Diagnostic Telemetry to Watch

The existing W&B telemetry already captures what we need:
- `train/grad/all/embed` — per-step embed gradient L2 norm; look for spikes vs. control
- `train/grad_param/embed` — same, per-parameter granularity
- `train/weight/all/embed` — embed weight RMS; should be smoother if clipping helps
- `train/grad/global_norm` — global grad norm; should be similar to control (Muon unchanged)

If clip is active on many steps (aux norms frequently exceed threshold), the mechanism is structurally present. If clip is active on 0 steps, the hypothesis is falsified by construction.

---

## Honest Predicted Outcomes

| Cell | threshold | Expected FFS_ema | Confidence | Notes |
|------|-----------|-----------------|------------|-------|
| Cell 0 | None (ctrl) | 2875 | High | Baseline reproduction |
| Cell 1 | 0.3 | 2875-2925 | Low | Risk: too aggressive on embed, may hurt |
| Cell 2 | 0.7 | 2875 or slight improvement | Medium | Primary test; may be FFS-NEUTRAL |
| Cell 3 | 1.5 | 2875 | Medium-high | Likely neutral (rarely fires) |
| Cell 4 | 3.0 | 2875 | High | Near-identical to control |

**Overall outlook**: Moderate-probability FFS-NEUTRAL (mechanism may be inert because aux grad norms at R5 are naturally stable), low-probability small improvement (FFS_ema ≈ 2862), very low probability of FFS regression (only Cell 1 at 0.3 is a realistic regression risk). This is a cheap diagnostic with upside — the 8 LOC change is trivially reversible, and the W&B telemetry will directly reveal whether the mechanism is alive regardless of FFS outcome.

---

## References

- PR #521: global `clip_grad_norm_(model.parameters(), max_norm)` — closed FFS-NEUTRAL, ALL parameters
- PR #283/#887/#1441: AGC (adaptive per-parameter) — closed
- PR #993: anomaly detection reset — closed
- Kingma & Ba (2015), Adam §4: "... in practice, the first few updates can be very large, especially for the embedding parameters which can have very high gradient variance due to data sparsity"
- Pascanu et al. (2013), "On the difficulty of training recurrent neural networks" — gradient clipping for stability, distinct from the per-group formulation here
