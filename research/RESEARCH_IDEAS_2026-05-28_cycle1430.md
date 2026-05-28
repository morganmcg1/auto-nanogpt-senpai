# Research Ideas — Cycle ~1430 (2026-05-28)

## Context

Cycle ~1430 state. Baseline: H203 FFS=3025, val/loss=3.26830 (single-run stat-sig below 3.276).
101+ NULL/NEG closures across 48+ mechanism classes. Two idle students: `g1r3-askeladd` and `g1r3-fern`.

Critical structural constraints in force:
- PROGRAMME FINDING #54: outer Nesterov SGD structurally privileged; outer Adam CATASTROPHIC.
- PROGRAMME FINDING #51: body structural-tightness 6-axis cluster — NS5 coefficients, NS iterations,
  NS5 projection mode, per-element 2nd-moment, cooldown shape WSD, Schatten-p — all CLOSED NULL/NEG.
- PROGRAMME FINDING #55: aux optimizer replacement fully closed (4/4 bilateral NEG).
- PROGRAMME FINDING #57: raw-param terminal eval structurally privileged over EMA.
- @torch.compile boundary: new conditional branches inside compiled region cost +25 FFS per branch.
  Drift-free implementation patterns: (a) place code outside compile region, (b) @torch.compiler.disable
  decorator, (c) separate top-level compiled function.
- body_init: `orthogonal_fnorm_matched` gain-rescaled to match default F-norm (NOT true Stiefel).
  H249 mechanistic insight: riem_frob_ratio grew 0.77→2.37, effective step shrunk 58%.
  True Stiefel body_init has NEVER been tested in r3.
- warmup SHAPE: `--muonh_warmup_steps` exists (default=0, disabled) but shape is ALWAYS linear.
  `--muonh_cooldown_shape` already has cosine/sqrt tested; warmup shape is a parallel UNTESTED axis.

---

## Candidate Shortlist (5-8 Hypotheses)

### C1. body-init-qr-stiefel (SELECTED for askeladd)
Add `"orthogonal_qr"` choice to `--body_init`. Use `torch.nn.init.orthogonal_` WITHOUT gain rescaling
(true Stiefel W^T W = I for full-rank). Directly motivated by H249 Stiefel-mismatch mechanistic
insight. Zero training dynamics change — init runs before @torch.compile, inherently drift-free.

### C2. body-warmup-shape (SELECTED for fern)
Add `--muonh_warmup_shape` parameter with choices ["linear", "cosine", "sqrt"] (default "linear" =
baseline). Mirrors H203 cosine cooldown WIN pattern. Warmup shape is a completely parallel,
never-tested axis in r3. Implementation must use @torch.compiler.disable if inside compile region.

### C3. per-layer-agc-body
Heterogeneous per-layer AGC clip ratios for body weights vs aux weights. H234 tested a global
`--muonh_agc_clip_ratio` sweep — per-layer ratios with body and aux decoupled are distinct and
untested. Theoretical motivation: NS5 polar-projected body gradients have different magnitude
distributions than aux gradients; a uniform clip ratio cannot be optimal for both.

### C4. outer-lr-depth-schedule
Layer-depth-dependent outer_lr scaling at the MuLoCo outer step. Distinct from H244 (body inner
LR depth-scaling) which closed bilateral NEG. The outer step is a Nesterov SGD update on the
difference vector (delta = local_params - global_params); scaling this difference by layer depth
is a different mechanism than scaling the inner Muon step. Untested in r3.

### C5. sync-interval-fractional-cosine-schedule
Schedule sync_interval over training rather than holding it constant. H252 assigned to nezuko as
a VALUE sweep (K∈{15,30,60} fixed). A cosine schedule that starts dense (small K, frequent sync)
and ends sparse (large K, infrequent sync) is a distinct axis: it aligns with curriculum intuition
(early training benefits from tighter global coherence; late training benefits from larger local
exploration before sync). Untested.

### C6. body-weight-decay-depth-schedule
Layer-depth-dependent body weight decay (lower WD for early layers, higher for late layers).
Distinct from per-layer LR scaling (H244 closed). WD acts on the Muon parameter update scale;
depth-modulating it is a different mechanism. Theoretical motivation: later transformer layers
encode more task-specific features and may benefit from stronger regularization.

### C7. stiefel-retraction-cleanup
Post-step Stiefel retraction: after each Muon step, apply a single-step cheap projection back
toward true Stiefel (e.g., W ← W * (1.5*I - 0.5*W^T*W) — one step of iterative polar decomp).
This is distinct from H249 (which tested init, not retraction). The retraction keeps riem_frob_ratio
bounded and prevents the effective-step-shrinkage observed in H249. Extremely cheap (one matmul
per parameter matrix per step). Retraction code goes outside @torch.compile — drift-free.

---

## Selected Hypothesis 1: body-init-qr-stiefel (for g1r3-askeladd)

### Hypothesis
True Stiefel initialization (W^T W = I, no F-norm rescaling) will reduce riem_frob_ratio
drift during training relative to `orthogonal_fnorm_matched`, leading to a more stable effective
step size and improved FFS relative to baseline.

### Causal Story
H249 identified a mechanistic failure: `orthogonal_fnorm_matched` enforces matching of F-norm to
default init, but does NOT enforce W^T W = I (true Stiefel membership). Over training the
riem_frob_ratio grew from 0.77 to 2.37, causing the effective Riemannian step to shrink by ~58%.
The hypothesis is that starting at true Stiefel (W^T W = I) defers this drift longer, allowing
more effective steps early in training where loss per step is highest.

Note: `orthogonal_fnorm_matched` is NOT a simple scaling of true Stiefel — it rescales the gain
to match the per-weight F-norm of default (normal_) init, producing W with F-norm matching default
but columns that are NOT unit norm. True Stiefel (`orthogonal_qr`) gives unit column norms and a
global scale that may differ from default init F-norm.

### Mechanism
`torch.nn.init.orthogonal_` computes QR decomposition of a random normal matrix, returning Q
(orthogonal matrix). For a weight of shape (n, k) with n >= k, this gives W^T W = I_k exactly.
For the existing choices:
- `default`: per-module `normal_` init, no orthogonality.
- `orthogonal_fnorm_matched`: `orthogonal_` with gain = default_fnorm / orthogonal_fnorm (per weight).
- `orthogonal_qr` (new): `orthogonal_` with gain=1.0 — true Stiefel membership, unit column norms.

A fourth arm `orthogonal_qr_mean_fnorm` uses a global gain computed as the ratio of the mean
F-norm across all body weights under default init to the mean F-norm under `orthogonal_`. This
preserves overall scale signal while maintaining exact orthogonality.

### Falsifying Criteria
- If riem_frob_ratio telemetry at steps 100, 500, 1000 shows no slower growth under orthogonal_qr
  vs orthogonal_fnorm_matched, the mechanism is wrong.
- If FFS under orthogonal_qr is worse than baseline (FFS >= 3025 + noise), close.
- If early val/loss diverges (not just slower descent) under orthogonal_qr, the scale mismatch
  from default F-norm is a hard constraint and true Stiefel init is ruled out as a standalone lever.

### Implementation

**Step 1: Add new body_init choice in `parse_args`**

In `train_gpt_simple.py`, find:
```python
parser.add_argument("--body_init", type=str, default=os.environ.get("BODY_INIT", "default"),
                    choices=["default", "orthogonal_fnorm_matched", "orthogonal_bottom_damp"],
```
Change to:
```python
parser.add_argument("--body_init", type=str, default=os.environ.get("BODY_INIT", "default"),
                    choices=["default", "orthogonal_fnorm_matched", "orthogonal_bottom_damp",
                             "orthogonal_qr", "orthogonal_qr_mean_fnorm"],
```

**Step 2: Add initialization logic**

Find the body_init application block (the block that handles `orthogonal_fnorm_matched`).
After the `orthogonal_bottom_damp` branch, add:

```python
elif args.body_init == "orthogonal_qr":
    # True Stiefel init: W^T W = I (unit column norms), no F-norm rescaling.
    for name, param in model.named_parameters():
        if param.ndim == 2 and any(tag in name for tag in ["attn.q", "attn.k", "attn.v",
                                                             "attn.proj", "mlp.fc", "mlp.proj"]):
            torch.nn.init.orthogonal_(param, gain=1.0)
elif args.body_init == "orthogonal_qr_mean_fnorm":
    # True Stiefel init with global F-norm scaling to match mean body F-norm of default init.
    # Step 1: collect default F-norms before overwriting
    body_params = [(name, param) for name, param in model.named_parameters()
                   if param.ndim == 2 and any(tag in name for tag in
                   ["attn.q", "attn.k", "attn.v", "attn.proj", "mlp.fc", "mlp.proj"])]
    default_fnorms = [param.data.norm(p="fro").item() for _, param in body_params]
    mean_default_fnorm = sum(default_fnorms) / len(default_fnorms) if default_fnorms else 1.0
    # Step 2: apply orthogonal init and measure mean orthogonal F-norm
    for _, param in body_params:
        torch.nn.init.orthogonal_(param, gain=1.0)
    orth_fnorms = [param.data.norm(p="fro").item() for _, param in body_params]
    mean_orth_fnorm = sum(orth_fnorms) / len(orth_fnorms) if orth_fnorms else 1.0
    global_gain = mean_default_fnorm / mean_orth_fnorm if mean_orth_fnorm > 0 else 1.0
    # Step 3: rescale all body params by global_gain
    for _, param in body_params:
        param.data.mul_(global_gain)
```

**Step 3: Run 3-arm experiment**

Arms:
- arm_a CTRL: `--body_init orthogonal_fnorm_matched` (current baseline behavior)
- arm_b QR_RAW: `--body_init orthogonal_qr` (true Stiefel, unit column norms)
- arm_c QR_MEAN: `--body_init orthogonal_qr_mean_fnorm` (true Stiefel, mean-F-norm-scaled globally)

All arms: `--train_steps 3325 --num_trials 1`. Same seed (default).

Add riem_frob_ratio logging if not already present (check existing telemetry — H249 tracked it).

### Decision Criteria
- Win: arm_b or arm_c FFS < 3025 (CTRL arm should reproduce H203 baseline approximately).
- Promising: FFS within ±25 steps of CTRL but val/loss lower.
- Close: arm_b AND arm_c FFS >= 3025 + 50 (clear regression or null).
- Retrain: arm_b or arm_c shows early divergence — likely means scale is load-bearing; close direction.

### Compute
3 arms × 3325 steps × 1 GPU × ~2h = ~6h total. Single seed per arm for screening.

### Drift Risk
Zero: body_init is applied before `torch.compile`. No new argparse branches inside compiled region.

### Win Probability Estimate
Moderate (35-45%). Mechanistic grounding is precise (H249 riem_frob_ratio insight). The risk is
that F-norm scale IS load-bearing independent of orthogonality direction — in which case the pure
QR arm will underperform even if the direction argument is correct.

---

## Selected Hypothesis 2: body-warmup-shape (for g1r3-fern)

### Hypothesis
A non-linear (cosine or sqrt) warmup shape for the body (MuonH) learning rate will improve FFS
relative to the current linear warmup, by allowing the optimizer to ramp into its effective range
more gently (cosine) or more aggressively (sqrt), analogous to how H203 found cosine cooldown shape
superior to linear cooldown.

### Causal Story
H203 (the current winning run) established that cosine cooldown SHAPE is load-bearing — this was
a WIN over linear cooldown and is now part of the structural-tightness cluster. The warmup phase is
a direct parallel: both are monotone schedule segments with a non-trivial shape degree of freedom.
The warmup shape controls how quickly the optimizer reaches full learning rate from 0, which affects
how aggressively it updates in the early steps where per-step loss reduction is highest. Cosine
warmup (slow rise at start, faster in middle) delays full-rate steps slightly but may avoid early
instability; sqrt warmup (fast rise at start, slower near full rate) gives more early-training power.
Neither shape has been tested for warmup in r3.

### Mechanism
Currently `--muonh_warmup_steps` exists (default=0, disabled). When enabled, the warmup multiplier
applied to the learning rate is always: `t / warmup_steps` (linear ramp). The help text explicitly
says "Linear LR warmup steps".

The analogous parameter for cooldown shape is `--muonh_cooldown_shape` with choices
["linear", "cosine", "sqrt"], already working.

Adding a `--muonh_warmup_shape` parameter with the same shape library mirrors the cooldown
implementation exactly, making this extremely low-risk from an implementation perspective.

### Falsifying Criteria
- If cosine_warmup and sqrt_warmup both fail to beat linear_warmup (FFS >= CTRL FFS + 25),
  warmup shape is not a meaningful lever in this stack.
- If val/loss curves at steps 100-500 are indistinguishable across arms, warmup shape has no
  early-training signal and the mechanism is inactive for this optimizer.
- Stop condition: both non-linear arms show FFS >= CTRL + 50 with no val/loss advantage.

### Implementation

**Step 1: Add argparse parameter**

In `parse_args`, after the `--muonh_warmup_steps` argument:
```python
parser.add_argument("--muonh_warmup_shape", type=str,
                    default=os.environ.get("MUONH_WARMUP_SHAPE", "linear"),
                    choices=["linear", "cosine", "sqrt"],
                    help="Shape of the LR warmup ramp for MuonH groups. "
                         "'linear': t/T (default, backward-compatible). "
                         "'cosine': 0.5*(1-cos(pi*t/T)). "
                         "'sqrt': sqrt(t/T).")
```

**Step 2: Add shape function to warmup multiplier computation**

Find the warmup multiplier computation in the training loop (likely inside the LR scheduler update,
near where `muonh_warmup_steps` is consumed). The existing code should look like:
```python
if step < args.muonh_warmup_steps:
    warmup_factor = step / args.muonh_warmup_steps
```
Replace with:
```python
if step < args.muonh_warmup_steps:
    warmup_progress = step / args.muonh_warmup_steps
    if args.muonh_warmup_shape == "cosine":
        warmup_factor = 0.5 * (1 - math.cos(math.pi * warmup_progress))
    elif args.muonh_warmup_shape == "sqrt":
        warmup_factor = warmup_progress ** 0.5
    else:  # linear (default)
        warmup_factor = warmup_progress
```

**CRITICAL: Drift-free placement.** If this warmup_factor computation is inside a `@torch.compile`
decorated function, wrap the conditional block with `@torch.compiler.disable`. The safest approach
is to compute warmup_factor in the Python training loop before passing it to the compiled forward
function, since warmup_factor is a scalar and can be passed as a Python float argument.

**Step 3: Enable warmup for all arms**

Use `--muonh_warmup_steps 100` (a typical warmup value — check what H203 used; if warmup was
disabled in H203, use 100 as a screening value and set it identically across all arms so the ONLY
variable is shape).

If `--muonh_warmup_steps` was 0 in H203 (warmup disabled), then arm_a CTRL must also enable warmup
at 100 steps to create a clean comparison. Do NOT compare "no warmup" vs "cosine warmup" — that
conflates warmup enablement with warmup shape.

Arms:
- arm_a CTRL: `--muonh_warmup_steps 100 --muonh_warmup_shape linear`
- arm_b COSINE: `--muonh_warmup_steps 100 --muonh_warmup_shape cosine`
- arm_c SQRT: `--muonh_warmup_steps 100 --muonh_warmup_shape sqrt`

All arms: `--train_steps 3325 --num_trials 1`. Same seed (default).

**IMPORTANT prerequisite check:** Grep train_gpt_simple.py for `muonh_warmup_steps` to find where
warmup is applied. If warmup is applied inside a `torch.compile` decorated function, use the
`@torch.compiler.disable` pattern documented in the codebase for the conditional branch. If the
warmup multiplier is already computed in Python scope (not inside compile), no extra action needed.

### Decision Criteria
- Win: arm_b or arm_c FFS < CTRL FFS.
- Promising: within ±25 steps but val/loss lower at matched steps.
- Close: both non-linear arms FFS >= CTRL + 50.
- If CTRL arm (linear warmup, warmup enabled) is itself worse than H203 no-warmup baseline:
  warmup itself may be a regression; close and note that warmup is structurally NULL in this stack.

### Compute
3 arms × 3325 steps × 1 GPU × ~2h = ~6h total. Single seed per arm for screening.

### Drift Risk
Low-to-moderate. The warmup multiplier is likely in Python scope (it's a scalar multiplier on LR).
If it IS inside @torch.compile, student must use @torch.compiler.disable pattern. The PR should
include a note confirming where the computation lives.

### Win Probability Estimate
Moderate (30-40%). Mechanistic grounding is analogical (not direct) — the cooldown shape finding
motivates warmup shape exploration but does not guarantee symmetry. The risk is that warmup duration
in this stack is too short (100 steps out of 3325 = 3%) for shape to matter; if so, both non-linear
arms will be null. A stronger signal would appear if warmup is extended to 200-300 steps, but that
adds an interaction variable.

---

## Research State Update (Cycle ~1430)

### Current Best Explanation for the Plateau
The stack has accumulated 18 structural-tightness members and 6 PROGRAMME FINDINGS that rule out
large swaths of the parameter space. The bottleneck is NOT training (gradients are healthy) or
evaluation (metric contract verified). The bottleneck is that the local neighborhood of the
MuonH-SI/MuLoCo combination has been exhausted in the obvious directions:
- NS5 iterations and coefficients: CLOSED.
- Per-element second moment: CLOSED.
- Cooldown shape: CLOSED (cosine is a structural member).
- Outer optimizer form: CLOSED (Nesterov SGD only).
- Aux optimizer replacement: CLOSED.
- EMA eval: CLOSED.
- Depth-scaled inner LR: CLOSED.
- Sync interval VALUE: in-flight (H252).

### Remaining Fresh Axes (evidence from territory maps)
1. Body init beyond F-norm matching (TRUE Stiefel) — UNTESTED in r3. Selected: body-init-qr-stiefel.
2. Warmup SHAPE (non-linear ramp) — UNTESTED in r3. Selected: body-warmup-shape.
3. Stiefel retraction (post-step cleanup) — UNTESTED in r3. Listed as C7.
4. Per-layer heterogeneous AGC ratios — UNTESTED (H234 only tested global ratio). Listed as C3.
5. Outer-LR depth schedule for MuLoCo delta — UNTESTED (distinct from H244 inner LR). Listed as C4.
6. Sync-interval fractional cosine schedule — UNTESTED (H252 tests fixed values). Listed as C5.

### Open Uncertainties
1. Is the F-norm scale of body init truly a hard constraint, or can it be relaxed if orthogonality
   direction is enforced? (body-init-qr-stiefel will answer this.)
2. Does warmup shape matter when warmup duration is short relative to total training? (body-warmup-shape
   will answer this; if null, warmup is confirmed as structurally irrelevant in this stack.)
3. What is the theoretical floor? H203 at FFS=3025 is the best known result. The public speedrun
   track record (external, not cited) may be much lower; internal ceiling is unknown.

### Experiment Tree

If body-init-qr-stiefel WINS (FFS < 3025):
  → Next: add Stiefel retraction (C7) on top of the new body_init WIN
  → Next: retune outer_lr and outer_momentum on top of new body_init WIN (body_init may shift
    optimal outer step size)

If body-init-qr-stiefel NULL/NEG (FFS >= 3025):
  → Ruled out: true Stiefel init as a lever in this stack
  → Next: per-layer heterogeneous AGC (C3) as next body-side mechanism axis

If body-warmup-shape WINS (FFS < 3025):
  → Next: sweep warmup_steps jointly with shape to find optimal warmup duration for cosine/sqrt
  → Next: test warmup shape jointly with body-init-qr-stiefel if both win independently

If body-warmup-shape NULL/NEG (FFS >= CTRL):
  → Ruled out: warmup shape as a lever in this stack
  → Note: also check if CTRL arm (warmup enabled) vs H203 (warmup disabled) shows any delta —
    if warmup itself is a regression, flag warmup as structurally NULL and never re-test.
  → Next: assign fern to sync-interval cosine schedule (C5) or outer-lr depth schedule (C4).

### Stop Condition
If body-init-qr-stiefel NULL and body-warmup-shape NULL: escalate to Stiefel retraction (C7) and
outer-lr depth schedule (C4), then per-layer AGC (C3). If all four are NULL, consider escalating
to a fundamentally different optimizer mechanism (e.g., SinkGD/GMN from earlier proposal C6,
or WSM checkpoint merging from C8).

---

## Taste Rubric

| Hypothesis | Mode | Mechanistic Grounding | Research-State Value | Execution Value | Notes |
|---|---|---|---|---|---|
| body-init-qr-stiefel | diagnostic | 4 | 4 | 4 | H249 provides precise mechanistic prior; riem_frob_ratio telemetry makes it directly falsifiable; zero drift risk; runs pre-compile |
| body-warmup-shape | diagnostic | 3 | 3 | 4 | Analogical grounding (cooldown shape WIN motivates warmup shape); implementation straightforward; drift-free if warmup scalar in Python scope |
| per-layer-agc (C3) | frontier refinement | 3 | 3 | 3 | H234 provides partial evidence (global ratio closed); per-layer is distinct; adds complexity |
| outer-lr depth schedule (C4) | frontier refinement | 2 | 3 | 3 | Distinct from H244 (inner LR) but weaker mechanistic grounding |
| sync-interval cosine schedule (C5) | diagnostic | 2 | 3 | 3 | H252 in-flight limits interpretation; should wait for H252 result |
| stiefel retraction (C7) | tier shift | 3 | 4 | 3 | Strong mechanistic grounding; relatively cheap per step; best as follow-up to body-init-qr-stiefel |

**Confidence:** body-init-qr-stiefel grounding is STRONG (H249 provides direct mechanistic evidence).
body-warmup-shape grounding is MODERATE (analogical to cooldown finding, not direct evidence).
Both are genuinely untested in r3 and will sharpen the research map either way.
