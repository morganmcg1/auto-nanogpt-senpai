# Wave 4 Research Hypotheses for g1r4-thorfinn
## Generated: 2026-05-17 ~05:45 UTC

### Context: thorfinn's completed work
- PR #60: Muon² baseline — first stat-sig win
- PR #105: clip=5.0 — merged, val=3.27527/fs=3266.7
- PR #165: clip=10.0 — merged, val=3.27474/fs=3258.3 (current branch best)
- **Clip axis is exhausted**: sweep over {5,10,25,50} complete, peak at 10-15, plateau between 10-25, regression at 50. Nothing left to explore there.
- **Mechanism confirmed**: clip acts only on AdamW aux (embed/lm_head). Muon blocks are inert because NS projects updates to fixed scale.

### In-flight context relevant to thorfinn
- frieren #176 (NS=12→16 cooldown boost): n=2 mean=3.27425/fs=3262.5, confirm-2 terminal ~05:45 UTC. Expected to merge as second wave-3 winner.
- tanjiro #185 (NS=14→8 anneal): arm-B val=3.27385/fs=3250, confirm seeds pending.
- nezuko #227 (AdamW β1 cooldown decay): newly assigned, fresh axis.

---

## Hypothesis 1 (TOP PRIORITY): Stack A — clip=10 x NS=12→16 cooldown

### What
Run both thorfinn's clip=10 and frieren's NS=12→16 cooldown boost simultaneously. These two mechanisms act on completely orthogonal parameter groups: clip reshapes the AdamW aux effective LR (embed, lm_head); NS-iter boost improves spectral quality of Muon orthogonalization (transformer blocks). There is no interaction pathway. If both mechanisms are independently additive, the stack should yield val ~ 3.272-3.273, fs ~ 3225-3250.

### Why
Mechanistic orthogonality is the strongest possible case for additive stacking. The wave-3 triangulation established: (a) clip effect is zero on Muon blocks because NS absorbs magnitude, (b) NS-iter schedule is a Muon-internal modification that leaves aux LR completely untouched. The two effects live in non-overlapping parts of the optimizer state. If the stack fails (val regresses vs either single-winner baseline), it tells us there is a hidden coupling that the triangulation missed — valuable negative evidence that constrains wave-5.

### Implementation
```
NANOGPT_GRAD_CLIP=10.0  # thorfinn's clip, already in code
NANOGPT_NS_ITERS=12     # mid-training baseline
NANOGPT_NS_ITERS_COOLDOWN=16   # frieren's boost (student must add this env var from #176)
NANOGPT_NS_COOLDOWN_START_FRAC=0.7  # matches cooldown_frac=0.7 in set_hparams
```

The student needs to add the NS cooldown schedule from frieren's PR #176 into the training script. The hook is in `zeropower_via_newtonschulz5` — pass `ns_iters_this_step` as a step-dependent argument instead of the global `NS_ITERS`. The step threshold is `int(train_steps * 0.7) = 2345` for train_steps=3350.

### Arm design (3-arm sweep + confirm)
| Arm | Config | Purpose |
|-----|--------|---------|
| A | clip=10, NS=12 constant | Control — re-verify clip=10 on current code state |
| B | clip=10, NS=12→16 cooldown | The stack hypothesis |
| C | clip=10, NS=8→16 cooldown | Stack B variant: compute-neutral mid + aggressive cooldown |

Run arm-A first as a 300-step smoke gate verifying the code modification didn't disturb baseline. Then arms B and C sequentially. If arm-B beats arm-A by >0.001 val → launch 2 confirm seeds before C.

### Expected result
Arm-B target: val ≈ 3.272-3.273, fs ≈ 3225-3250. If additive gain is ~0.002 from NS boost alone (frieren arm-B=3.27327 vs baseline 3.27527 ≈ 0.002 delta) and clip=10 already contributed 0.0005, stack could approach 3.272-3.273. Arm-C is Stack-B from the wave-4 candidate list — possibly stronger still since NS=8 mid-training is compute-neutral and NS=16 cooldown is identical.

### Stop condition
If arm-B val > 3.2745 (no improvement over clip=10 alone at 3.27474), the orthogonality assumption is wrong. Close the stack axis and investigate why.

---

## Hypothesis 2: Embed-Only Clip with Sweep — fix lm_head saturation

### What
The current clip=10 mechanism has an asymmetry: embed group reaches ~16.9% effective LR (healthy), but lm_head group is still clip-saturated at <0.4% effective LR. This suggests lm_head is being systematically under-updated compared to embed. Try per-group clip: apply clip=10 to embed group, clip=50 (or no clip) to lm_head group, to let lm_head catch up.

### Why
Edward's #206 confirmed that clip is structurally on aux only. The question left open is whether the lm_head saturation is beneficial (regularizing output logits), neutral, or harmful. The wave-3 sweep couldn't distinguish lm_head and embed contributions because they share the same global clip. A per-group clip or a higher clip for lm_head only is a direct test of whether lm_head under-updating is the drag.

### Implementation
The current code applies clip to all parameters uniformly (`clip_grad_norm_(model.parameters(), max_norm)`). Per-group clipping requires running `clip_grad_norm_` separately on each param group:

```python
# In training loop, replace single clip call with:
if NANOGPT_GRAD_CLIP_EMBED > 0:
    torch.nn.utils.clip_grad_norm_(
        optimizer1.param_groups[0]["params"], max_norm=NANOGPT_GRAD_CLIP_EMBED)
if NANOGPT_GRAD_CLIP_LM_HEAD > 0:
    torch.nn.utils.clip_grad_norm_(
        optimizer1.param_groups[1]["params"], max_norm=NANOGPT_GRAD_CLIP_LM_HEAD)
```

New env vars: `NANOGPT_GRAD_CLIP_EMBED`, `NANOGPT_GRAD_CLIP_LM_HEAD`.

### Arm design
| Arm | Config | Purpose |
|-----|--------|---------|
| A | clip_embed=10, clip_lm_head=10 | Control (matches PR #165 mechanism but via per-group) |
| B | clip_embed=10, clip_lm_head=50 | Let lm_head see larger updates |
| C | clip_embed=10, clip_lm_head=off | No constraint on lm_head at all |
| D | clip_embed=25, clip_lm_head=10 | Higher embed LR (28% effective) — test whether embed can go further |

### Expected result
If lm_head under-updating is harmful: arm-B/C beats arm-A. If lm_head saturation is actually beneficial (output logit regularization): arm-B/C regresses. Either way, this mechanistically resolves the lm_head question left open by wave-3.

### Stop condition
If arms B and C are both within ±0.001 of arm-A, the lm_head clip level is inert. Close this axis.

---

## Hypothesis 3: AdamW Embed LR Direct Sweep (clip-free mechanism test)

### What
Since clip=10 effectively raises embed effective LR from 8.4% to 16.9%, test if directly setting `adam_embed.lr` to achieve the same 16-17% ratio (relative to scale) works equally well — or better — without relying on the indirect clip mechanism. This tests whether the clip mechanism is purely an LR rescaler for embed (i.e., a noisy way to achieve a known target) or whether the per-step adaptive rescaling adds something beyond a fixed LR adjustment.

Note: alphonse #188 tested uniform 1.5× aux LR (all three aux groups together) and found it NEUTRAL. This is different — it tests embed-ONLY LR, which is what clip actually targets.

### Why
Wave-3 established: uniform aux LR scaling is neutral (alphonse arm-B). Clip is NOT a uniform rescaler (because lm_head is saturated while embed is active). This means the benefit comes from embed-specific effective LR increase. The direct test isolates whether: (a) the benefit is purely the higher embed LR (direct scaling achieves the same), or (b) the adaptive nature of clip (larger rescaling when grad norm exceeds threshold) adds something that a fixed LR cannot replicate.

### Implementation
In `optimizer1` group for embed (line 617 of train_gpt_simple.py):
```python
# Current: lr=0.3
# Test: lr=0.3 * (target_ratio / baseline_ratio)
# baseline embed effective-LR ratio: ~8.4% (from PR #105 analysis)
# clip=10 effective ratio: ~16.9%
# Target LR to match clip=10 effect: 0.3 * (16.9/8.4) = ~0.604
```

Env var: `NANOGPT_EMBED_LR` (overrides the 0.3 default).

### Arm design
| Arm | Embed LR | Equiv clip | Purpose |
|-----|----------|------------|---------|
| A | 0.30 | baseline | Control |
| B | 0.60 | ~clip=10 equivalent | Does direct LR match clip=10? |
| C | 0.45 | ~clip=7 | Intermediate |
| D | 0.90 | ~clip=20 | Upper range |

### Expected result
If arm-B matches clip=10 (val~3.274): clip is a noisy LR rescaler and we can simplify the mechanism to a single LR parameter.
If arm-B underperforms clip=10: the adaptive clip rescaling (larger rescaling when norm exceeds threshold) adds real value beyond a fixed LR.
This experiment has high diagnostic value regardless of outcome.

### Stop condition
If B/C/D all regress vs arm-A control, the embed LR axis is closed independently, and the clip mechanism has an adaptive component we don't understand yet.

---

## Hypothesis 4 (speculative): Weight-decay asymmetry for aux groups

### What
Currently AdamW on aux groups has `weight_decay=0` (line 620). The Muon group has `weight_decay=0.025` (line 622). The embed weight handles vocabulary representations while lm_head is tied or closely related. Try a small nonzero WD on the embed group specifically (0.001-0.01 range) during the cooldown phase, analogous to frieren's NS-iter cooldown boost — a cooldown-only WD nudge that encourages final-stage sharpening.

### Why
During cooldown, the model is doing fine-grained optimization in a shrinking LR regime. Adding a small WD on embed during this window could act as an implicit regularizer that prevents the embed representations from over-fitting to the training noise that dominated the stable phase. This is an unexplored axis (WD on aux has not been tested; only Muon WD has been tuned).

### Implementation
In `set_hparams`, add a WD ramp for the embed group during cooldown:
```python
# In set_hparams(), add:
for group in opt.param_groups:
    if group.get("name") == "adam_embed" and NANOGPT_EMBED_WD_COOLDOWN > 0:
        if progress >= 1 - cooldown_frac:
            group["weight_decay"] = NANOGPT_EMBED_WD_COOLDOWN
```

Env var: `NANOGPT_EMBED_WD_COOLDOWN` (default 0.0).

### Arm design
| Arm | Embed WD cooldown | Purpose |
|-----|-------------------|---------|
| A | 0.0 | Control |
| B | 0.001 | Small nudge |
| C | 0.005 | Moderate |
| D | 0.01 | Strong (Muon-scale) |

### Priority
This is lower priority than Hypotheses 1-3. Run only if thorfinn has compute budget after Stack A and the per-group clip sweep.

---

## Priority ranking for assignment

1. **Hypothesis 1 (Stack A)** — highest-confidence, mechanistically orthogonal stacking of two confirmed winners. Assign first.
2. **Hypothesis 2 (per-group clip)** — closes the lm_head saturation question left open by wave-3 triangulation.
3. **Hypothesis 3 (embed LR direct)** — diagnostic test of clip mechanism, may allow simplification.
4. **Hypothesis 4 (aux WD cooldown)** — speculative, lower confidence, run only with remaining compute.

Given thorfinn has one GPU (sequential arms), assign Hypothesis 1 first. If arm-B of Hypothesis 1 is clearly positive at first terminal, consider whether Hypothesis 3 (which could be a 2-arm minimal check) is the highest-value next use of thorfinn's GPU vs. waiting for wave-4 stack confirmation.
