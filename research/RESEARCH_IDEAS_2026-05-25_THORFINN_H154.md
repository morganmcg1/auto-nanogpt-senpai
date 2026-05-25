# H154: ADOPT Aux Optimizer — Lagged Second-Moment Normalization for Embed/LM-Head/Scalars

**Student**: g1r3-thorfinn
**Date**: 2026-05-25
**Target**: beat val/loss 3.26547 @ 3325 steps; WIN threshold < 3.26467
**Research mode**: tier shift (mechanism-level swap, not scalar tuning)

---

## Research Reasoning

### Bottleneck identification

The aux optimizer (optimizer1 = AdamW) governs embed.weight (lr=0.3), proj.weight/lm_head (lr=1/320), and all scalar parameters (biases, gains, lr=0.01). The main body (MuonH-SI + NS5 + MuLoCo) is deeply explored and stable. The aux subsystem has been tested for:

- cautious gradient masking (H138, NULL)
- beta1 scheduling (H147, NULL/bilateral)
- beta2 scheduling (hook exists, not primary mechanism)
- embed weight decay (H142, non-load-bearing)

What has NOT been tested: the core update rule algorithm of the aux optimizer itself.

### Mechanism under test

ADOPT (Saito et al., NeurIPS 2024, arXiv 2411.02853) modifies Adam's update ordering so that the gradient normalization uses the LAGGED second moment v_{t-1} rather than the current v_t. This reordering is not a hyperparameter change — it alters the causal graph of Adam's update.

Standard Adam step t (simplified):
1. v_t = beta2 * v_{t-1} + (1-beta2) * g_t^2
2. m_t = beta1 * m_{t-1} + (1-beta1) * g_t / sqrt(v_t + eps)
3. theta_t = theta_{t-1} - lr * m_t / (1 - beta1^t)

ADOPT step t:
1. theta_t = theta_{t-1} - lr * m_t  [update using PREVIOUS momentum]
2. v_t = beta2 * v_{t-1} + (1-beta2) * g_t^2
3. m_{t+1} = beta1 * m_t + (1-beta1) * g_{t+1} / max(sqrt(v_t), eps)  [normalize by CURRENT v_t before accumulating next momentum]

The lagged normalization makes ADOPT provably convergent for any beta2 in (0,1), breaking the pathological correlation that prevented Adam convergence theory (the Reddi et al. 2018 counterexample). In practice this matters when:

1. Gradients are noisy relative to the signal (embed and lm_head have large, high-variance gradients)
2. The denominator is near-zero at init (confirmed: baseline uses eps=1e-10, abnormally small, which makes near-zero v at step 0 numerically dangerous for standard Adam)
3. beta2 deviates from a narrow "safe" range (baseline beta2=0.95 is already aggressive; ADOPT removes this constraint)

The ADOPT authors provide Clipped ADOPT as an instability fix (clip normalized gradient by step^0.25 schedule), specifically addressing zero-initialized last layers — which is exactly our lm_head (proj.weight initialized to zero at line 820 of the training script).

### Orthogonality argument

All closed/in-flight aux mechanism families:
- H138 cautious masking: gates updates by sign agreement — orthogonal (different signal filtering)
- H147 beta1 schedule: varies momentum accumulation rate — orthogonal (ADOPT changes normalization ordering)
- H152 Lion: different optimizer family entirely
- H142 embed WD: regularization scalar — orthogonal
- Existing beta2 schedule hook: varies second moment decay rate — orthogonal (ADOPT changes WHEN v enters the normalization, not what its value is)

ADOPT is the only mechanism that changes the causal ordering of Adam's update. It has not appeared in any of the ~154 hypotheses in the research log.

### Connection to current stack

The lm_head zero-init creates a regime where standard Adam (and AdamW) applies a near-zero denominator during the first steps. The baseline's eps=1e-10 (vs standard 1e-8) appears to acknowledge this sensitivity but does not eliminate it. ADOPT's lagged v ensures that the first normalization uses v_0 = g_0^2 rather than the freshly-updated v_1, which is structurally more stable at init for zero-initialized parameters.

The embed group (lr=0.3, highest aux LR) is the most momentum-sensitive aux group. High LR + standard Adam momentum correlation is precisely the failure mode ADOPT's reordering is designed to fix.

---

## Papers

1. **ADOPT: Modified Adam Can Converge with Any β₂ with the Optimal Rate**
   - Authors: Shohei Saito, Taiji Suzuki
   - Venue: NeurIPS 2024
   - arXiv: https://arxiv.org/abs/2411.02853
   - Summary: Proves standard Adam fails to converge with arbitrary β₂ (Reddi et al. counterexample), then shows reordering the momentum/normalization steps (using lagged v) restores optimal O(1/sqrt(T)) convergence rate for any β₂. Includes Clipped ADOPT for instability at init with zero-initialized layers. NLP experiments on GPT-2/OpenWebText show improvement over Adam especially under high gradient noise.

2. **On the Convergence of Adam and Beyond** (Reddi et al., ICLR 2018)
   - Why it matters: original counterexample showing Adam fails to converge with small β₂; ADOPT's theoretical contribution directly addresses this result.

---

## Implementation

The ADOPT class is a drop-in replacement for the three optimizer1 (AdamW) param groups. No changes to optimizer2 (MuonH), MuLoCo outer loop, AGC, LR schedule, or any other component.

### ADOPT class (~55 LoC)

```python
class ADOPT(torch.optim.Optimizer):
    """ADOPT: Modified Adam with lagged second-moment normalization.
    
    From Saito & Suzuki, NeurIPS 2024 (arXiv 2411.02853).
    Key difference from Adam: gradient is normalized by v_{t-1} (lagged)
    before entering the momentum buffer, not by v_t (current).
    
    clip_lambda: if not None, clips normalized gradient by step^clip_lambda.
    Default clip_lambda=0.25 (Clipped ADOPT) is recommended for zero-initialized
    parameters (e.g., lm_head).
    """
    def __init__(self, params, lr=1e-3, betas=(0.9, 0.999), eps=1e-6,
                 weight_decay=0.0, clip_lambda=0.25):
        defaults = dict(lr=lr, betas=betas, eps=eps,
                        weight_decay=weight_decay, clip_lambda=clip_lambda)
        super().__init__(params, defaults)

    @torch.no_grad()
    def step(self, closure=None):
        loss = closure() if closure is not None else None
        for group in self.param_groups:
            beta1, beta2 = group["betas"]
            eps = group["eps"]
            clip_lam = group["clip_lambda"]
            for p in group["params"]:
                if p.grad is None:
                    continue
                g = p.grad
                state = self.state[p]
                # Initialize state
                if len(state) == 0:
                    state["step"] = 0
                    # v_0 = g_0^2 (per ADOPT Algorithm 1, initialize with first grad)
                    state["exp_avg_sq"] = g.mul(g).clone()
                    # m_1 = g_1 / max(sqrt(v_0), eps)  (first momentum = normalized grad)
                    state["exp_avg"] = g.div(state["exp_avg_sq"].sqrt().clamp(min=eps)).clone()
                    # Update param at step 0: theta_1 = theta_0 - lr * m_1
                    if group["weight_decay"] != 0:
                        p.data.mul_(1 - group["lr"] * group["weight_decay"])
                    p.data.add_(state["exp_avg"], alpha=-group["lr"])
                    state["step"] = 1
                    continue
                state["step"] += 1
                step = state["step"]
                exp_avg, exp_avg_sq = state["exp_avg"], state["exp_avg_sq"]
                # Step 1: update param using current momentum (from previous step)
                if group["weight_decay"] != 0:
                    p.data.mul_(1 - group["lr"] * group["weight_decay"])
                p.data.add_(exp_avg, alpha=-group["lr"])
                # Step 2: update second moment v_t = beta2*v_{t-1} + (1-beta2)*g_t^2
                exp_avg_sq.mul_(beta2).addcmul_(g, g, value=1 - beta2)
                # Step 3: normalize gradient by v_t (current), then update momentum
                # m_{t+1} = beta1*m_t + (1-beta1) * g_t / max(sqrt(v_t), eps)
                denom = exp_avg_sq.sqrt().clamp(min=eps)
                normed_g = g / denom
                if clip_lam is not None:
                    clip_val = step ** clip_lam
                    normed_g = normed_g.clamp(-clip_val, clip_val)
                exp_avg.mul_(beta1).add_(normed_g, alpha=1 - beta1)
        return loss
```

### Optimizer instantiation change (lines 849-852)

Replace:
```python
optimizer1 = AdamW([...], betas=(0.8, args.aux_beta2_start), eps=args.aux_adamw_eps, weight_decay=0, fused=_aux_fused)
```

With:
```python
optimizer1 = ADOPT([...], betas=(args.aux_adopt_beta1, args.aux_adopt_beta2),
                   eps=args.aux_adamw_eps, weight_decay=0,
                   clip_lambda=args.aux_adopt_clip_lambda)
```

### New argparse flags (add after existing aux flags)

```python
parser.add_argument("--aux_adopt_beta1", type=float, default=float(os.environ.get("AUX_ADOPT_BETA1", "0.0")),
    help="ADOPT beta1 for aux groups. 0.0 = disabled (use AdamW instead).")
parser.add_argument("--aux_adopt_beta2", type=float, default=float(os.environ.get("AUX_ADOPT_BETA2", "0.999")),
    help="ADOPT beta2 for aux groups.")
parser.add_argument("--aux_adopt_clip_lambda", type=float, default=float(os.environ.get("AUX_ADOPT_CLIP_LAMBDA", "0.25")),
    help="Clipped ADOPT exponent. -1 = disable clipping.")
```

The flag `aux_adopt_beta1=0.0` acts as a gate: when 0.0, the code uses AdamW (baseline path). This lets arm_a be bit-identical to the current stack without any code-path divergence.

### Implementation notes

1. **Step 0 special case**: The ADOPT paper initializes v_0 = g_0^2 and m_1 = g_1/max(sqrt(v_0), eps). This means at step=0 the code initializes from the first gradient (before any optimizer.step()). The cleanest approach: initialize state on first call to step(), using the current gradient as both v_0 and the source for m_1.

2. **eps value**: The baseline eps=1e-10 is inherited from AdamW and is very aggressive. ADOPT with lagged v is more numerically stable, but using eps=1e-10 with the clipped variant is still acceptable. For arm_b (vanilla ADOPT), try eps=1e-6 which is closer to the ADOPT paper default and avoids instability from near-zero v_0 at init. For arm_c (tuned beta1 matching baseline), keep eps=1e-10 to isolate the algorithm change.

3. **beta2 schedule hook**: The existing `aux_beta2_schedule` / `aux_beta2_start` / `aux_beta2_end` hook writes `g["betas"] = (g["betas"][0], b2)` for optimizer1 groups. ADOPT reads `group["betas"]` the same way, so this schedule is compatible with ADOPT without code changes. For this experiment, keep `aux_beta2_schedule=constant` to isolate the mechanism.

4. **AGC compatibility**: The AGC step runs BEFORE optimizer1.step() and clips p.grad in-place. ADOPT reads p.grad, so AGC works identically. The aux_agc_clip_ratio=0.05 baseline is preserved.

5. **MuLoCo compatibility**: MuLoCo outer step operates on p.data directly (anchor snapshots + velocity update). ADOPT modifies p.data in step(), then MuLoCo applies its outer correction on top. No interaction — same as AdamW.

6. **fused=False**: ADOPT is a Python-level optimizer, no fused kernel. This removes the _aux_fused path entirely for optimizer1, but the performance impact is negligible (aux groups are a tiny fraction of parameters).

7. **Weight decay**: All aux groups have weight_decay=0 in the baseline. ADOPT implements decoupled WD (same as AdamW). Keep wd=0 for this experiment to isolate the update rule change.

---

## 3-Arm Design

All arms: train_steps=3325, 1 trial each, sequential execution on 1×H100.

### arm_a — CTRL (current AdamW stack, bit-identical baseline)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3325 \
  --aux_adopt_beta1 0.0 \
  --wandb_name "thorfinn/h154-arm-a-ctrl-adamw" \
  --wandb_group "h154-adopt-aux"
```

Expected: val/loss ~3.265-3.270 (current baseline neighborhood).

### arm_b — ADOPT vanilla (standard ADOPT defaults, Clipped)

Key change: AdamW → ADOPT with β₁=0.9 (ADOPT default), β₂=0.999, eps=1e-6, clip_lambda=0.25.

Rationale: β₁=0.9 is ADOPT paper default; β₂=0.999 is further from baseline 0.95 — tests ADOPT's claim that any β₂ works. The looser β₂ means slower second-moment adaptation, which may help with noisy embed gradients. eps=1e-6 avoids near-zero denominator at init under lagged v.

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3325 \
  --aux_adopt_beta1 0.9 \
  --aux_adopt_beta2 0.999 \
  --aux_adamw_eps 1e-6 \
  --aux_adopt_clip_lambda 0.25 \
  --wandb_name "thorfinn/h154-arm-b-adopt-vanilla" \
  --wandb_group "h154-adopt-aux"
```

### arm_c — ADOPT tuned (β₁=0.8 matching baseline, Clipped)

Key change: AdamW → ADOPT with β₁=0.8 (matches baseline AdamW β₁=0.8), β₂=0.999, eps=1e-10 (matches baseline), clip_lambda=0.25.

Rationale: Isolates the algorithm change (lagged v normalization) from the β₁ change. Keeping eps=1e-10 tests whether ADOPT's lagged v provides numerical stability even at the baseline's aggressive eps. If arm_c wins over arm_b, it suggests the β₁=0.8 momentum structure is important and ADOPT's pure algorithm change is the driver.

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3325 \
  --aux_adopt_beta1 0.8 \
  --aux_adopt_beta2 0.999 \
  --aux_adamw_eps 1e-10 \
  --aux_adopt_clip_lambda 0.25 \
  --wandb_name "thorfinn/h154-arm-c-adopt-tuned-beta1" \
  --wandb_group "h154-adopt-aux"
```

### Expected outcome and telemetry

The mechanism predicts that ADOPT provides better-conditioned updates for the embed group (largest LR, highest gradient variance) and the lm_head (zero-initialized, pathological for standard Adam at init). If the mechanism is active, we expect:

1. Early training (steps 0-500): ADOPT arms show smoother `train/grad/all/embed_weight` gradient norm trajectory vs arm_a. The lm_head group (`train/grad_param/adam_lm_head`) should show lower early-step gradient spikes.
2. Mid training: `val/loss` curves for arm_b or arm_c diverge from arm_a somewhere in steps 1000-2500. If they're identical to arm_a through step 2500, the mechanism is not firing for this aux setup.
3. Cooldown (steps 2000-3325): ADOPT's convergence guarantee implies better final-phase behavior. The `val/slope/loss_per_100_steps` should show steeper (more negative) slope for ADOPT arms in the last 10% of training.

Falsifying result: If both ADOPT arms match arm_a (CTRL) within 0.001 val/loss through step 3325 AND the gradient telemetry shows no difference in early steps, the lagged-v mechanism is not the binding constraint for this aux setup. This would support "aux algorithm is not the bottleneck" and redirect focus to the body optimizer.

### Stop condition

Kill any arm immediately if: non-finite loss or gradients in first 100 steps; val/loss > 3.35 at step 500 (early divergence). Do not kill based on trailing CTRL — let all arms run to 3325.

---

## Implementation cost estimate

- ADOPT class: ~55 LoC
- Argparse flags: ~6 LoC
- optimizer1 instantiation change: ~4 LoC (conditioned on aux_adopt_beta1 > 0)
- Total new code: ~65 LoC
- Changes to existing logic: 0 (arm_a path is bit-identical to current stack when aux_adopt_beta1=0.0)

---

## Research state update

**Current best explanation for remaining headroom**: The aux optimizer (embed, lm_head, scalars) has been treated as a fixed AdamW block while the body optimizer received essentially all algorithmic innovation (MuonH, NS5, MuLoCo, AGC, µ-schedule). The aux subsystem governs the embedding table and output projection — the two layers that mediate the model's interface with token space. A better update rule for these layers (ADOPT's lagged normalization) could unlock gains the body-focused experiments cannot see.

**Evidence**: H138 (cautious masking, NULL), H142 (embed WD, non-load-bearing), H147 (beta1 schedule, NULL) all failed to improve the aux subsystem through filtering or schedule changes. None tested the core update algorithm.

**Ruled out**: aux beta1 scheduling (H147), cautious gradient masking (H138), embed weight decay (H142), all confirmed NULL or non-load-bearing. Attempting any of these again without a structural change to the problem setup would not be warranted.

**Open uncertainties**:
1. Is the aux optimizer a meaningful bottleneck at all? The body (MuonH-SI) dominates parameter count and gradient computation. The embed + lm_head are only ~(50,257+1)*768 = ~39M of 124M params, but they are the information bottleneck layers.
2. Does ADOPT's theoretical guarantee (any β₂) translate to practical gain when β₂ is already reasonable (0.95) and the run is short (3325 steps)?
3. Does the zero-initialized lm_head actually create a meaningful Adam pathology at these scales, or is it absorbed by the warmup and LR schedule?

**Next discriminating experiment after H154**: If both ADOPT arms match CTRL, pivot to body-level changes (new preconditioner family, different NS polynomial, or a structural change to MuLoCo's sync interval or outer LR schedule). If one ADOPT arm wins, immediate follow-up is retuning embed LR and eps under ADOPT to find the new optimal configuration.

---

## Confidence

**External evidence**: Strong. ADOPT NeurIPS 2024, peer-reviewed, includes GPT-2/OpenWebText ablations, official PyTorch implementation available. The lagged-v mechanism is mathematically well-motivated and the zero-init lm_head instability is explicitly documented in the official ADOPT repository README.

**Transfer confidence**: Moderate. ADOPT's gains in the paper come from GPT-2 full model training (not just aux groups). Applying it only to 3 small aux groups is an untested narrowing. The mechanism should still apply, but the gain may be smaller or zero if the aux groups are not the binding constraint. This is a genuine uncertainty, not a fatal weakness — the experiment tests whether they are the constraint.

**Implementation risk**: Low. The ADOPT class is ~55 LoC, the algorithm is well-specified, the Optax and official PyTorch implementations are available for cross-reference, and the gate (aux_adopt_beta1=0.0 → AdamW) ensures arm_a is unaffected.

Overall: **2.5 / 4** — strong mechanism with real external evidence, moderate transfer confidence given the narrowing to aux-only application. The experiment has good information value either way (positive or negative result refines our understanding of the aux bottleneck).
