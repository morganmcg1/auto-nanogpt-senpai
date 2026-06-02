# Fresh Hypotheses for askeladd and nezuko — 2026-06-02 09:43

Generated after full closed-axis audit of 402 PRs (results_table_2026-06-02_09-44.md).
Both axes are verified pristine against all ran experiments.

---

## Hypothesis 1 (askeladd): Aux Adam Per-Group ε Asymmetric Allocation

### Mechanism hypothesis

The baseline uses `eps=1e-8` uniformly across all aux Adam groups (embed, lm_head, scalars).
The `eps_dominance_frac` telemetry from PR #1178 reveals a structural asymmetry:
- `adamw/embed/eps_dominance_frac` (terminal) ≈ **0.687%** — embed has non-trivial eps-regime behavior
- `adamw/lm_head/eps_dominance_frac` (terminal) ≈ **0.0015%** — lm_head has essentially zero eps-regime behavior

This asymmetry means embed and lm_head are in fundamentally different AdamW operating regimes.
In the eps-dominated regime, the denominator is floored and the update magnitude is controlled
entirely by the numerator (gradient EMA) rather than the second-moment preconditioner.
The hypothesis is that these groups benefit from different ε values:

- **lm_head** has near-zero eps_dominance_frac — it is always in the true AdamW second-moment regime.
  Tightening its ε (1e-8 → 1e-12) gives the preconditioner more dynamic range without disturbing
  the numerics, potentially sharpening the effective LR near cooldown onset.
- **embed** has ~0.69% eps-dominated coordinates — the sparse token embedding rows visited
  infrequently have small accumulated v̂. Tightening ε for embed forces those rare coordinates
  into a longer second-moment warmup, which may slow early convergence for long-tail tokens.
  Loosening ε for embed (or leaving it at 1e-8 baseline) lets those coordinates remain
  in the stable floor regime.

Bilateral design tests both allocation directions, asking which group benefits more from
precision tightening in isolation.

### Why this axis is pristine

- PR #463: Tested embed eps ∈ {1e-8, 1e-7} (both arms changed embed group ONLY — not a cross-group split, and tested looser not tighter)
- PR #1178: Tested global eps ∈ {1e-8, 1e-12} uniformly across ALL groups simultaneously — null result (no differential signal possible when all groups move together)

Neither PR tested asymmetric allocation where one group gets tighter ε while others remain
at baseline. The eps_dominance_frac asymmetry was only available as telemetry AFTER PR #1178
ran; no experiment has used this asymmetry to construct a principled differential allocation.

### Bilateral arm design

**Arm A** — lm_head tight, others baseline:
```
--aux_lm_head_eps 1e-12
# embed=1e-8 (baseline), scalars=1e-8 (baseline)
```
Prediction: lm_head's zero eps-regime behavior means it can handle a tight floor.
Tighter preconditioner denominator in the output projection sharpens gradient scaling
during late cooldown where lm_head receives concentrated signal.

**Arm B** — embed tight, others baseline:
```
--aux_embed_eps 1e-12
# lm_head=1e-8 (baseline), scalars=1e-8 (baseline)
```
Prediction: Forcing embed into tight-eps regime removes the natural floor for long-tail
token rows, which may help or hurt depending on whether those rows matter near step 2925.
This is the contrastive condition that would falsify the mechanism if Arm B also wins.

Bilateral logic: if Arm A wins and Arm B loses (or is neutral), the mechanism is confirmed
— lm_head is the load-bearing group for eps precision. If both win, the baseline eps is
globally suboptimal. If both lose, eps tightening is harmful regardless of group.

### Implementation sketch

```python
# New CLI flags (3 flags, all optional, default=None means use global --aux_eps)
parser.add_argument('--aux_embed_eps', type=float, default=None)
parser.add_argument('--aux_lm_head_eps', type=float, default=None)
parser.add_argument('--aux_scalar_eps', type=float, default=None)

# In optimizer construction (replace current single-eps AdamW setup):
def get_aux_eps(group_name, args):
    """Return per-group eps; fall back to global aux_eps (default 1e-8)."""
    override = getattr(args, f'aux_{group_name}_eps', None)
    return override if override is not None else args.aux_eps  # args.aux_eps=1e-8 baseline

embed_eps  = get_aux_eps('embed',   args)
lm_head_eps = get_aux_eps('lm_head', args)
scalar_eps = get_aux_eps('scalar',  args)

optimizer_aux = torch.optim.AdamW([
    {'params': embed_params,   'eps': embed_eps,   ...},
    {'params': lm_head_params, 'eps': lm_head_eps, ...},
    {'params': scalar_params,  'eps': scalar_eps,  ...},
], ...)
```

### Estimated LOC + runtime

- LOC delta: ~20 LOC (3 flag definitions + `get_aux_eps` helper + 3 group eps lookups)
- Runtime: identical to baseline (no per-step compute change)
- Each arm: ~3.5h to terminal (sr=2925 or early kill at step 3250)

### Reproduce commands (full baseline stack)

**Arm A (lm_head tight):**
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 \
  --ema_beta 0.97 \
  --ema_warmup_steps 1750 \
  --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --muon_block_lr_spread 0.20 \
  --paramema_refresh_only \
  --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 \
  --aux_b2_pulse_target 0.99 \
  --aux_lm_head_eps 1e-12 \
  --wandb_group askeladd-aux-eps-split
```

**Arm B (embed tight):**
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 \
  --ema_beta 0.97 \
  --ema_warmup_steps 1750 \
  --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --muon_block_lr_spread 0.20 \
  --paramema_refresh_only \
  --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 \
  --aux_b2_pulse_target 0.99 \
  --aux_embed_eps 1e-12 \
  --wandb_group askeladd-aux-eps-split
```

### Falsifying result

Both arms lose vs. baseline → eps precision is irrelevant to the loss trajectory; the
eps_dominance_frac asymmetry is a diagnostic artifact not a leverage point. Close axis.

---

## Hypothesis 2 (nezuko): PMuon Covariance EMA Update Stride Stratified by Block Depth

### Mechanism hypothesis

PMuon computes the whitening preconditioner via bilateral covariance EMAs:
```
L_cov ← β_cov * L_cov + (1 - β_cov) * (G @ G.T)
R_cov ← β_cov * R_cov + (1 - β_cov) * (G.T @ G)
```
Currently all 12 transformer blocks update their L_cov/R_cov at **every step** with the
same β_cov=0.95. The whitening matrix is then derived: `W = L_cov^{-γ} @ m @ R_cov^{-γ}`.

The gradient distribution stationarity hypothesis: transformer blocks at different depths
have qualitatively different gradient stationarity profiles during training:

- **Shallow blocks** (layers 0-5): Handle low-level syntactic/token-level features.
  Their gradient covariance structure stabilizes early in training and changes slowly
  thereafter. The marginal value of a fresh covariance estimate at step t+1 vs t is low
  because L_cov at shallow layers barely changed.
- **Deep blocks** (layers 6-11): Handle high-level semantic representations that continue
  adapting throughout cooldown. Their gradient covariance structure evolves faster,
  especially during the phase shift at cooldown onset (step 975) and pre-target window.

If this is true, then updating L_cov/R_cov every step for shallow blocks is wasteful — the
covariance estimate from step t-1 is nearly as good as from step t. Conversely, skipping
updates for deep blocks during cooldown would leave the preconditioner stale at exactly the
moment when rapid adaptation is needed.

**Proposed intervention**: Per-block covariance update stride — shallow blocks use stride=2
(update every other step), deep blocks use stride=1 (update every step). This asymmetry
lets compute be concentrated where gradient statistics are most dynamic while maintaining
a stable preconditioner for the already-converged shallow features.

Secondary prediction: Even if stride=2 for shallow is "free" in terms of loss, it releases
a mild regularization effect — the preconditioner at shallow layers uses a slightly older
(smoother) covariance estimate, potentially acting as implicit noise injection.

### Why this axis is pristine

All prior β_cov experiments changed the EMA *rate* (the decay constant β), not the
*frequency of update*. There is a fundamental difference:
- β_cov=0.9 (PR #502, #129): All blocks update every step, but older gradients are
  forgotten faster
- β_cov depth-split (PR #1727): Shallow/deep blocks use different β_cov values, but
  BOTH groups still update at every step
- Cov-reset experiments: Zeroed accumulated state at phase boundaries, did not skip updates

No experiment has ever set stride > 1 for any block — i.e., skipping the covariance
EMA update entirely on certain steps. The stride axis is orthogonal to the rate axis.

### Bilateral arm design

**Arm A** — shallow stride=2, deep stride=1 (depth-stratified, favors deep freshness):
```
--cov_stride_shallow 2
--cov_stride_deep 1
```
Prediction: This is the theory-consistent arm. Deep blocks need fresh preconditioners
during cooldown. Shallow blocks can tolerate stale covariance. Expect SR improvement.

**Arm B** — shallow stride=1, deep stride=2 (inverted, contrastive condition):
```
--cov_stride_shallow 1
--cov_stride_deep 2
```
Prediction: Staling deep block preconditioners during the critical cooldown window
should hurt. If Arm B is worse than baseline while Arm A wins, the mechanism is confirmed.
If Arm B is also neutral/positive, the gradient stationarity hypothesis is wrong and
the benefit is coming from a different mechanism (e.g. implicit regularization).

Block boundary: layers 0-5 = shallow, layers 6-11 = deep (assumes 12-block GPT).
Use `block_idx < num_blocks // 2` for generality.

### Implementation sketch

```python
# New CLI flags
parser.add_argument('--cov_stride_shallow', type=int, default=1,
                    help='Cov EMA update stride for shallow blocks (layers 0..N//2-1)')
parser.add_argument('--cov_stride_deep', type=int, default=1,
                    help='Cov EMA update stride for deep blocks (layers N//2..N-1)')

# In PMuon update step (inside per-block covariance update loop):
num_blocks = len(self.param_groups)  # or however blocks are enumerated
for block_idx, group in enumerate(self.param_groups_body):
    is_shallow = block_idx < num_blocks // 2
    stride = args.cov_stride_shallow if is_shallow else args.cov_stride_deep
    
    if self.state['step'] % stride == 0:
        # Existing covariance EMA update
        G = group['grad_matrix']  # reshaped gradient
        group['L_cov'].mul_(beta_cov).add_(
            (1 - beta_cov) * (G @ G.T)
        )
        group['R_cov'].mul_(beta_cov).add_(
            (1 - beta_cov) * (G.T @ G)
        )
    # else: skip cov update this step; use cached L_cov/R_cov from previous update

    # Whitening proceeds unconditionally using whatever L_cov/R_cov is current
    update = apply_whitening(group['momentum'], group['L_cov'], group['R_cov'], gamma)
    group['param'].add_(-lr * update)
```

### Estimated LOC + runtime

- LOC delta: ~35 LOC (2 flag definitions + stride lookup per block + conditional cov update + comments)
- Runtime: ~2-3% faster than baseline on stride=2 blocks (half as many covariance matmuls for those blocks)
- Each arm: ~3.5h to terminal

### Reproduce commands (full baseline stack)

**Arm A (shallow stride=2, deep stride=1):**
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 \
  --ema_beta 0.97 \
  --ema_warmup_steps 1750 \
  --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --muon_block_lr_spread 0.20 \
  --paramema_refresh_only \
  --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 \
  --aux_b2_pulse_target 0.99 \
  --cov_stride_shallow 2 \
  --cov_stride_deep 1 \
  --wandb_group nezuko-cov-stride-depth
```

**Arm B (shallow stride=1, deep stride=2):**
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 \
  --ema_beta 0.97 \
  --ema_warmup_steps 1750 \
  --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --muon_block_lr_spread 0.20 \
  --paramema_refresh_only \
  --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 \
  --aux_b2_pulse_target 0.99 \
  --cov_stride_shallow 1 \
  --cov_stride_deep 2 \
  --wandb_group nezuko-cov-stride-depth
```

### Falsifying result

Arm A and Arm B both match baseline (null, both within noise) → gradient covariance
stationarity-by-depth is not a leverage point; all blocks update fast enough that
stride-2 sub-sampling makes no difference. The next step would be to test stride=4 or
stride=8 (more aggressive skipping) to find the point where staleness matters.

---

## Research State Update

### Current best explanation for what is limiting progress

The current floor appears to be in the optimizer state dynamics during the cooldown phase
(steps 975-3250+). The successful baseline innovations all touch this window:
the β₂ pulse at step 975, the paramEMA refresh at step 2600, the late-higher LR pattern.
The remaining headroom is likely in **per-group or per-block differentiation** that the
current uniform-treatment baseline is leaving on the table.

### Closed axes (do not repeat without new evidence)

- Global eps sweeps (all groups together): PR #1178
- Embed-only eps (any single group in isolation, without differential allocation): PR #463
- β_cov rate sweeps (uniform): PR #502, #129
- β_cov rate depth-split (per-block rate, not stride): PR #1727
- Cov resets at phase boundaries: multiple PRs

### Open uncertainties

1. Whether the eps_dominance_frac asymmetry (embed ~0.69% vs lm_head ~0%) is
   mechanistically load-bearing or merely a reflection of architecture-level sparsity
   patterns that don't affect the loss trajectory.
2. Whether gradient covariance stationarity is actually stratified by depth in this
   12-block GPT, or whether all blocks have similar gradient dynamics during cooldown.
3. Whether the gains from per-block/per-group differentiation are already saturated
   by the existing late-higher LR pattern, or whether independent axes (eps, cov stride)
   still have headroom.

### Next discriminating experiment

The eps-split experiment (askeladd) is the faster diagnostic: it requires zero compute
overhead and will cleanly separate whether the eps_dominance_frac asymmetry is a
leverage point or an irrelevant artifact.

### Stop condition for these hypotheses

- askeladd: Both arms ≥ baseline (sr > 2875 both arms) with no mechanistic signal → close eps-split axis entirely
- nezuko: Both arms null (sr=2925 both arms, val_ema ≥ 3.265) → cov-stride-depth axis closed; consider deeper block stratification or phase-conditional stride activation
