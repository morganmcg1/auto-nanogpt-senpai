# Research Ideas: Alphonse — RoPE Base Frequency Probe
# Generated: 2026-06-01 00:30Z
# Context: Post-PR-#1979 tier-shift (FFS representational-capacity-bound finding)

---

## One-Line Title

Parameterize the RoPE base frequency (currently a magic constant `1/1024`) to probe whether positional representation capacity is limiting the FFS crossing.

---

## Hypothesis

The current RoPE implementation uses `(1/1024)^linspace(0,1)` as the angular frequency spectrum — a heavily non-standard base chosen without ablation. Standard RoPE uses base 10000; the nanoGPT speedrun tradition has kept `1/1024` because it appeared in the original codebase. If the FFS crossing is representational-capacity-bound (not optimization-landscape-bound, per PR #1979), then the positional spectrum width directly shapes what the model can distinguish. An under-sized frequency range (too low a base) compresses all token positions into a narrow angular range, collapsing positional distinctions at longer distances. An over-sized base fans out positions too much, concentrating most representational capacity in high-frequency terms the model rarely uses. The optimal base is almost certainly not `1024` — it was never ablated — and finding it could shift FFS by 50-100 steps.

---

## Mechanism

`Rotary.__init__` computes:
```python
angular_freq = (1 / 1024) ** torch.linspace(0, 1, steps=dim//4, dtype=torch.float32)
```

The `linspace(0,1)` spans `[1.0, 1/base]`, so `base=1024` gives a frequency range of `[1.0, 0.000977]`. With `head_dim=128`, `dim//4=32` frequencies are active (the other 32 are zero-padded). The standard RoPE base `10000` gives range `[1.0, 0.0001]` — 10x more compressed. Smaller bases (e.g. 64) expand the range to `[1.0, 0.0156]` — 16x more spread than current.

The positional spectrum affects:
1. **Short-range attention** (nearby token discrimination): higher-frequency components (larger per-step angle changes) determine this.
2. **Long-range attention** (in-context continuity): lower-frequency components carry distance-agnostic context.

In a 1024-token sequence, with the current base `1024`:
- Highest-frequency component cycles once per ~1 token → fine-grained position
- Lowest-frequency component cycles once per ~1024 tokens → nearly non-rotating

At base 10000:
- Highest-frequency still cycles once per ~1 token (unchanged — linspace starts at 0, freq=1.0)
- Lowest-frequency cycles once per ~10000 tokens → essentially DC over 1024 tokens (no positional gradient)

The sweep tests whether the current `1024` base is near-optimal, too wide (try 64, 256), or too narrow (try 4096, 10000). FFS is expected to be most sensitive because crossing requires the model to generalize across diverse token sequences, and positional representation quality is highest-leverage during that stage of training.

---

## Prior-Work Check

**Not in any closed family.** RoPE base has never been ablated in the R5 stack. Confirmed no in-flight experiment targets this axis:
- edward #1948: SOAP precond_freq cooldown
- frieren #1966: Muon mu cooldown ramp
- thorfinn #1994: SOAP state hard-reset
- tanjiro #2014: NS5 iteration count cooldown ramp
- nezuko #2020: SOAP beta2 cooldown ramp
- fern #2023: Lion as AUX optimizer
- askeladd #2030: Schedule-Free Muon Polyak-Ruppert

**External literature:**
- Su et al. 2022 (RoFormer): original RoPE with base 10000 for 512-token BERT-scale sequences.
- Black et al. 2022 (GPT-NeoX): base 10000 throughout.
- Peng et al. 2023 (YaRN/Code Llama): extended base (up to 500k) for long-context extrapolation — opposite direction, but establishes base as a tunable axis.
- Kaiokendev 2023 (Position Interpolation): base directly controls effective context window.

The key empirical insight from long-context literature: **smaller bases** amplify short-range positional detail (frequencies rotate fast), while **larger bases** compress positional info (frequencies rotate slowly, effectively increasing "useful" context length). For a fixed 1024-token window, a base of 1024 sits at the knee of the rotation-per-window curve. Whether the knee is optimal is an empirical question.

The nanoGPT speedrun base `1024` was chosen to approximately match the sequence length. This is a heuristic, not a principled derivation. It is one of the oldest constants in the codebase and has never been ablated in the R5 era.

---

## Implementation Plan (~30 LOC delta)

**Step 1: Add CLI arg in `parse_args()`** (~4 lines):
```python
parser.add_argument("--rope_base", type=float, default=1024.0,
                    help="RoPE angular frequency base. Default=1024.0 (current hardcoded constant). "
                         "Standard RoPE uses 10000. Try {64, 256, 1024, 4096, 10000}.")
```

**Step 2: Thread `args` through to `Rotary.__init__`.**

The `Rotary` class is instantiated inside `CausalSelfAttention.__init__`, which is instantiated inside `Block.__init__`, which is instantiated inside `GPT.__init__`. `GPT` is instantiated at module level with `model = GPT(...)`. The cleanest approach is a module-level global (matching how `NS_ITER` is handled):

```python
# After args = parse_args() and NS_ITER override (line ~112), add:
ROPE_BASE = args.rope_base
```

Then in `Rotary.__init__`:
```python
class Rotary(nn.Module):
    def __init__(self, dim: int):
        super().__init__()
        # half-truncate RoPE (w/ base freq tuning)
        angular_freq = (1.0 / ROPE_BASE) ** torch.linspace(0, 1, steps=dim//4, dtype=torch.float32)
        self.register_buffer("angular_freq", torch.cat([angular_freq, angular_freq.new_zeros(dim//4)]))
```

**Step 3: Log the value at run start** (~2 lines):
```python
# In the W&B config dict (wherever other hyperparams are logged), add:
"rope_base": args.rope_base,
```

**Total delta: ~8 lines of meaningful change, ~4 lines of logging.** This is the smallest possible clean test of the hypothesis.

**No other changes required.** The optimizer, loss, init, schedule, and all other components are untouched. The only change is the angular frequency spectrum used by all 12 `Rotary` instances in the 12 `CausalSelfAttention` blocks.

---

## 3-4 Cell Experimental Design

**Run length:** 3250 steps (default, full training including cooldown). The RoPE base affects all stages, not just cooldown, so full-length runs are needed. 3250 steps is the current default `SENPAI_TRAIN_STEPS`.

**Cell design:** 4-cell dose-response across base frequency, spanning 3 orders of magnitude above and below current:

### Baseline (Cell 0 — implicit control, skip if tight on GPU-hours)
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --rope_base 1024.0 \
  --ema_eval_decay 0.9996 \
  --wandb_name "alphonse/rope-base-1024-ctrl" \
  --wandb_group "rope-base-freq-probe"
```
Expected: FFS_ema ~2900-2950 (canonical attractor). Confirms no regression from adding the arg.

### Cell 1 — Narrow base, high-frequency compression (below current)
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --rope_base 64.0 \
  --ema_eval_decay 0.9996 \
  --wandb_name "alphonse/rope-base-64" \
  --wandb_group "rope-base-freq-probe"
```
Hypothesis direction: wider frequency spread, better short-range discrimination.

### Cell 2 — Slightly below current
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --rope_base 256.0 \
  --ema_eval_decay 0.9996 \
  --wandb_name "alphonse/rope-base-256" \
  --wandb_group "rope-base-freq-probe"
```

### Cell 3 — Slightly above current
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --rope_base 4096.0 \
  --ema_eval_decay 0.9996 \
  --wandb_name "alphonse/rope-base-freq-probe-4096" \
  --wandb_group "rope-base-freq-probe"
```

### Cell 4 — Standard RoPE base
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --rope_base 10000.0 \
  --ema_eval_decay 0.9996 \
  --wandb_name "alphonse/rope-base-10000" \
  --wandb_group "rope-base-freq-probe"
```
Hypothesis direction: standard RoPE frequencies may be better-calibrated for BPE token sequences.

**If budget is tight:** Run Cell 1, Cell 3, Cell 4 (skip explicit baseline and Cell 2). Cell 3 and 4 test the "base was too low" hypothesis; Cell 1 tests the "base was too high" direction.

---

## Signal Gates

**Strong positive signal (FFS-POS):**
- Any cell achieves `FFS_ema < 2850` (>50-step improvement over current mean ~2912)
- Val loss at step 3250 improves by >0.001 over baseline ~3.2696 on any cell

**Weak positive signal (worth n=4 confirm):**
- Any cell achieves `FFS_ema < 2875` (escaping the attractor band)
- Monotone improvement trend: {64, 256} better than {1024} better than {4096, 10000} OR the reverse — either direction confirms the axis is alive

**Null / FFS-NEG gate (close the axis):**
- All cells land within ±30 steps of baseline FFS_ema (2880-2940 range) — axis dead, base was near-optimal
- Any cell shows divergence (loss > 4.0 at step 500) — that specific value is pathological, but may not close the whole axis

**n=1 attractor caveat:**
- If winning cell lands exactly at {FFS_ema=2875, FFS_trainval=2925} — known seed-noise attractor — escalate to n=4 before claiming positive.

---

## Pre-Mortem: Top Risks

1. **The base `1024` was already near-optimal by accident.** The sequence length is 1024, and `base=seq_len` is an informal heuristic that appears in some NLP implementations. If the frequencies are already well-matched to the training distribution, all sweep cells will land within noise. This would close the RoPE-base axis. Falsifier: monotone dose-response showing clear winner.

2. **Base change is absorbed by RMSNorm gain learning.** The model's RMSNorm gains adapt to the magnitude of attention outputs, so if the rotary frequencies merely rescale the Q/K dot products, the gains compensate and the final loss trajectory is unchanged. This is the NS5-absorption analogue for the positional encoding axis. Observable: if train/loss curves are nearly identical for all cells, absorption is likely.

3. **Very small bases (64) cause frequency aliasing.** At base 64, the highest-frequency component cycles 16x per token in a 1024-token window. This may cause attention scores to be dominated by the highest-frequency rotary component, effectively destroying position information for tokens more than ~4 apart. Observable: divergence or unusually high early training loss for base=64.

4. **Very large bases (10000) wash out positional information in short sequences.** At base 10000, the lowest-frequency component rotates only 0.1 radians over the full 1024-token sequence. The model may fail to learn long-range positional structure. Observable: val loss at base=10000 should be clearly worse than baseline in early training if this matters.

5. **Interaction with half-truncation (zero-padding).** The current implementation zero-pads half the `angular_freq` buffer, effectively making 32 of the 64 head-dim slots position-insensitive. This truncation could interact with base changes in non-obvious ways — a lower base might make the active 32 frequencies too wide, overwhelming the non-positional slots. Hard to diagnose without attention head analysis; treat as background noise.

---

## Literature Citations

- Su J, Lu Y, Pan S, Murtadha A, Wen B, Liu Y (2022). "RoFormer: Enhanced Transformer with Rotary Position Embedding." arXiv:2104.09864. Original RoPE; base 10000 is the reference point.
- Peng B, Quesnelle J, Fan H, Shippole E (2023). "YaRN: Efficient Context Window Extension of Large Language Models." arXiv:2309.00071. Shows base is a primary lever for extending effective context.
- Kaiokendev (2023). "Things I'm learning while training SuperHOT." Blog post. First to empirically show RoPE base tuning changes effective context window for fine-tuning.
- Black S, et al. (2022). "GPT-NeoX-20B: An Open-Source Autoregressive Language Model." arXiv:2204.06745. Uses base 10000; reference for standard practice.
- Chen S, et al. (2023). "Extending Context Window of Large Language Models via Positional Interpolation." arXiv:2306.15595. Demonstrates base directly governs angular velocity; lower base = faster rotation per token.

---

## Research State Update

**Current best explanation for FFS bottleneck:**
PR #1979 ruled out optimization-landscape trapping (LR warm-restart at step 2500/2700 with magnitude 0.3/0.5x — ALL FFS-NEG). The bottleneck is representational: the model cannot represent what it needs to represent at the FFS crossing moment, regardless of whether you perturb the optimizer trajectory. Positional representation is one untested axis within this family.

**Evidence:**
- 93 R5 experiments; PR #1979 is 93rd. All schedule/momentum/optimizer-perturbation experiments have failed to advance FFS beyond the 2875-2925 attractor band.
- EMA-eval confirms crossing is real, not an artifact.
- Representational axes (init schemes) have moved FFS in the past (depth_init_mode, zero-init).

**Ruled-out paths:**
- LR warm-restart / cyclic perturbation (PR #1979, all 4 cells FFS-NEG)
- NS5 absorption family: additive pre-NS gradient modifiers, 2D weight init perturbations, per-block depth-LR scaling
- LN gain init below 1.0 (double-counts variance suppression)
- Aux cooldown shape/param decoupling

**Open uncertainties:**
1. Is the FFS attractor at 2875-2925 genuinely representational, or is it an EMA-eval artifact from the decay parameter?
2. Does the RoPE base interact with the SOAP preconditioner (SOAP operates in gradient eigenspace — if RoPE changes the Q/K gradient structure, SOAP may precondition differently)?
3. Can any positional scheme change (RoPE base, learned embeddings, ALiBi) shift FFS, or is the bottleneck entirely in the MLP representation?

**Next discriminating experiment:**
This RoPE base sweep. If base=10000 lands at FFS_ema~2860 (a 50-step improvement), it confirms: (a) the current `1/1024` was suboptimal, (b) the representational-capacity interpretation is correct, and (c) alignment with standard LLM practice closes the gap.

**Stop condition for this direction:**
If all 4 cells land within ±30 steps of the attractor, close the RoPE-base axis. The model is insensitive to positional spectrum, and future representational-capacity hypotheses should focus on MLP width/depth alternatives or attention head specialization.
