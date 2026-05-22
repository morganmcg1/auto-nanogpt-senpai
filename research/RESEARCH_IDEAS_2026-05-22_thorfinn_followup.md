# Hypothesis for g1r5-thorfinn: Cautious Muon

## Date: 2026-05-22

## Background and Motivation

After the closure of PR #781 (per-group AdamW eps sweep, clean-NEG), the full
per-group AdamW HP family (LR, β1, β2, ε, global ε) is now a closed axis.
All scalar/embed/lm_head AdamW tuning has been exhausted.

The remaining live surface is the Muon optimizer's update rule itself. The
current pipeline applies Newton-Schulz (NS) orthogonalization to accumulate a
momentum-based direction, then takes a step. Once NS delivers its orthogonalized
update `u_t`, that update is applied unconditionally — even for elements where
the orthogonalized direction disagrees with the sign of the current raw gradient.

Liang et al. (arXiv 2411.16085, "Cautious Optimizers") show that masking out
update components that oppose the current gradient consistently speeds up LLM
pretraining with no hyperparameter retuning:

    w_{t+1} ← w_t − ε_t · u_t ⊙ 𝕀(u_t ⊙ g_t > 0) · α

where `α = dim / (nnz(u_t ⊙ g_t > 0) + 1)` rescales the surviving elements so
the effective step RMS is preserved. The mask is a pure sign-consistency check
(no threshold) between the proposed update direction and the current gradient.

**Why this mechanism could help Muon specifically:**

Muon's NS orthogonalization maximizes the spectral norm of the update subject to
a Frobenius budget. This can cause large elements in directions that happen to
oppose g_t on that step — NS has no awareness of gradient alignment. The
Cautious mask acts as a per-element veto: "don't move in a direction the current
gradient opposes." This is strictly more conservative than unconstrained Muon,
which may be desirable at the fine-tuning stage of a near-converged run.

The paper reports ~0.3-1.0% perplexity improvement on 130M-520M LLM pretraining
(FineWeb-Edu), with gains increasing at larger scale. No tested configuration
degraded performance.

**Distinctness from all in-flight PRs:**

| In-flight | Mechanism | Why orthogonal |
|-----------|-----------|----------------|
| #823 SignMuon | Transforms Nesterov momentum to its sign before NS | Different: sign of momentum, not gradient-agreement masking after NS |
| #826 Lookahead (askeladd) | Slow/fast weight interpolation every k steps | Different: weight-space interpolation, not per-element update masking |
| #840 AdEMAMix (nezuko) | Dual EMA (fast + slow) before NS | Different: momentum construction, not post-NS masking |
| #785 alphonse α-sweep | Residual alpha coefficient | Different: init/architecture, not optimizer update rule |
| #800, #815, #824 | Various other axes | None touch Muon post-NS masking |

No closed PR has applied sign-agreement masking to the Muon update after NS.
PR #823 SignMuon applies sign() to the Nesterov buffer before orthogonalization
— an entirely different operation at a different pipeline stage.

## Current Baseline

- μ = 3.261221, σ = 0.000593, n = 4 (post-musoft, post-#699)
- n=4 statsig gate: μ ≤ 3.259221
- Mandatory flags: `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`

## Hypothesis

Applying the Cautious mask (Liang et al. 2411.16085) to the NS-orthogonalized
Muon update — masking out elements where `sign(u_t) ≠ sign(g_t)` and rescaling
to preserve step RMS — will reduce val loss by 0.001-0.003 relative to the
musoft baseline, without any other HP changes.

## 5-Cell P1 Sweep Design

All cells use `--num_trials 1` and `--train_steps 3250` (screening length).

Mandatory flags in every cell:
`--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`

### Implementation

The Cautious mask is applied inside the Muon optimizer step, after
`zeropower_via_newtonschulz5` returns the orthogonalized update `g` (which is
the variable name used in the existing code for the NS output). The change is:

```python
# After NS produces g (the orthogonalized update direction):
# g = zeropower_via_newtonschulz5(grad.bfloat16(), steps=NS_ITER)
# ... (existing reshape/norm logic) ...
# Just before: param.data.add_(g, alpha=-lr)

# INSERT Cautious mask here:
if cautious:
    mask = (g * raw_grad).gt(0)          # True where update aligns with grad
    alpha_rescale = mask.numel() / (mask.sum().float() + 1.0)
    g = g * mask.float() * alpha_rescale

param.data.add_(g, alpha=-lr)
```

`raw_grad` is the unmodified `param.grad` captured before the Muon step begins
(store it before `grad = param.grad` is detached/zeroed).

New CLI flag to add: `--cautious_muon` (boolean flag, default False).

For cells that test SOAP-preconditioned attention (--soap_attn is mandatory),
the Cautious mask should also be applied to the SOAP update for attention
weights. Capture `raw_grad` for those params in the same way.

### Cell table

| Cell | `--cautious_muon` | Notes |
|------|-------------------|-------|
| A (ctrl) | off | Baseline replication — confirms no regression from refactor |
| B (primary) | on | Full Cautious Muon as described above |
| C (mlp_only) | on (MLP only) | Mask applied to MLP weights only; skip attn weights — isolates whether gain is from MLP or attn |
| D (attn_only) | on (attn only) | Mask applied to attn weights only; skip MLP — complementary ablation to C |
| E (lr_up) | on + `--lr_mlp 0.060` | If B wins, test whether cautious allows a slightly larger LR (conservative masking may tolerate higher step sizes) |

**Predicted ranking:** B ≥ C > D > A, E ≈ B ± 0.001

**Primary cell:** B — full Cautious Muon, minimal change from baseline.

**Kill conditions:**
- If Cell A diverges from baseline by > 0.0003: stop, the refactor introduced a bug — do not interpret B-E.
- If B, C, D are all within 0.0003 of A after P1: clean-NEG, report and close.
- If B beats A by > 0.0015 on the screening run: flag as P2 candidate.

## P2 Gate

If any cell in P1 achieves val_loss ≤ 3.260 on a single seed, proceed to P2:
run the best cell at `--num_trials 4` to collect n=4 seeds. Report μ and σ.
Gate for merge: μ ≤ 3.259221.

## W&B Group

`--wandb_group "thorfinn-cautious-muon"`

## ETA Estimate

P1 (5 cells × 3250 steps × 1 trial): ~2.5 hours on 1×H100
P2 (best cell × 4 trials × 4500 steps): ~4 hours if triggered

## Reference Papers

- Liang et al. (2024). "Cautious Optimizers: Improving Training with One Line of Code."
  arXiv 2411.16085. https://arxiv.org/abs/2411.16085
  Reports consistent LLM pretraining improvements on FineWeb-Edu (130M-520M scale)
  with C-AdamW and C-Lion. Key result: ~0.33% perplexity gain at 130M,
  ~1.0% at 520M. No tested configuration degraded performance. No threshold
  tuning needed — pure sign check.
- Reference implementation: https://github.com/kyleliang919/C-Optim

## Stop Condition

Report clean-NEG if B, C, D all within 0.0003 of A.
Report clean-NEG if B wins P1 but fails P2 gate (μ > 3.259221 on n=4).
Escalate to next hypothesis if clean-NEG on both P1 and P2.
