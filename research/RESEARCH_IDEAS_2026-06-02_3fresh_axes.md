# Fresh Optimizer Hypotheses — 2026-06-02
# 3 Mechanism-Distinct Axes for Cycle ~2700 | H389 / H390 / H391

Generated for the auto-nanogpt-1gpu-r3 advisor branch.
Baseline: H266 (MuonH-SI + MuLoCo + Polyak-Ruppert EMA decay=0.05), val/loss=3.26818, FFS=3000.
Strict merge gate: FFS < 3000 (per Issue #1260).
Statistical rule: (3.28 - mu) * sqrt(n) >= 0.004 — single run needs val < 3.276.

---

## H389 — AUX AdamW Warmup Schedule
**Student:** alphonse (rank-1, ~11% WIN probability)
**Axis class:** WARMUP CURVE SHAPE on AUX (completely untested)
**LoC estimate:** ~10 LoC

### Orthogonality Verification

All previously closed warmup work targets BODY (MuonH / optimizer2) only.
The `set_hparams` function applies `muonh_warmup` exclusively to `optimizer2` via
`if opt is optimizer2: eta = eta * muonh_warmup` (lines 996-998).
The argparse comment on `--muonh_warmup_steps` (line 49) explicitly states:
"AdamW aux groups are not warmed."
No `--aux_warmup_steps` argument exists anywhere in the training script.
The AUX AdamW groups (embed / lm_head / scalar params) begin training at full
initial_lr from step 0, with zero warmup, on every run including H266.

This is a genuinely untested axis. It is orthogonal to:
- H266 (Polyak EMA — scope/decay change, not schedule)
- All OUTER-LOOP closures (MuLoCo / optimizer3 scope)
- AUX preconditioner family (6 axes: LaProp/Adan/Sophia/Lion/Schedule-Free/AdEMAMix/AdaBelief)
- MuonH warmup (--muonh_warmup_steps, optimizer2 only)
- All NS orthogonalization axes (STATIC H88 + ADAPTIVE H380)
- GC/centering H378, body orthogonality regularizer H322
- Per-shape PEMA blocks H383 (edward in-flight)

### Mechanism

Linear warmup for AUX AdamW from lr=0 to initial_lr over N steps.
The causal story: embedding and lm_head weights receive full-magnitude Adam
updates from step 0. At initialization the gradient magnitudes for these
parameter groups can be large (especially embed when tokens are random),
and full-LR updates early in training can overshoot low-loss regions before
the loss landscape has been explored. Linear warmup dampens the first N steps,
allowing the MuonH body layers to establish their representation before the
output and input projections commit to a direction. This is especially plausible
given that H266's Polyak EMA has a short half-life (~20 steps, decay=0.05),
meaning early-training weight trajectories are directly visible in the eval
shadow weights.

### Implementation (~10 LoC)

Changes to `records/track_3_optimization/train_gpt_simple.py`:

1. In `parse_args` after the `--muonh_warmup_steps` arg (~line 50):
```python
parser.add_argument("--aux_warmup_steps", type=int,
    default=int(os.environ.get("AUX_WARMUP_STEPS", "0")),
    help="Linear LR warmup steps for AUX AdamW groups (0 = disabled, H266 default).")
```

2. In `set_hparams` just after the muonh_warmup block (~line 994):
```python
if args.aux_warmup_steps > 0:
    aux_warmup = min(1.0, (step + 1) / args.aux_warmup_steps)
else:
    aux_warmup = 1.0
```

3. In the existing per-group loop inside `set_hparams`, change the warmup
application from:
```python
if opt is optimizer2:
    eta = eta * muonh_warmup
```
to:
```python
if opt is optimizer2:
    eta = eta * muonh_warmup
elif opt is optimizer1:
    eta = eta * aux_warmup
```

CTRL (arm_a): `--aux_warmup_steps 0` (no change to H266 behavior).
arm_b: `--aux_warmup_steps 100` (~3% of 3325 total steps, mild ramp).
arm_c: `--aux_warmup_steps 300` (~9% of 3325 total steps, slower ramp).

### 3-Arm Chain Design

All arms use the H266 baseline stack:
- `--polyak_ema_decay 0.05`
- `--aux_agc_clip_ratio 0.05`
- `--muonh_agc_clip_ratio 0.05`
- `--outer_lr 0.7 --outer_momentum 0.5 --outer_sync_interval 30`
- `train_steps=3325`

arm_a CTRL (bit-for-bit H266 sentinel):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/H389-arm_a-ctrl" \
  --wandb_group "H389-aux-warmup" \
  --aux_warmup_steps 0
```

arm_b treatment (mild warmup):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/H389-arm_b-warmup100" \
  --wandb_group "H389-aux-warmup" \
  --aux_warmup_steps 100
```

arm_c treatment (longer warmup):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/H389-arm_c-warmup300" \
  --wandb_group "H389-aux-warmup" \
  --aux_warmup_steps 300
```

### Decision Rules

- WIN: any arm achieves FFS < 3000 strictly. Report n=arm_count seeds at that step, verify (3.28 - mu)*sqrt(n) >= 0.004.
- PROMISING: arm_b or arm_c achieves val/loss materially below 3.26818 with FFS at or near 3000 — retune warmup length, try 50/200/500.
- NULL/CLOSE: all arms FFS >= 3000 and val/loss within noise of 3.26818 — axis closed.
- NEG/CLOSE: any arm val/loss significantly worse than 3.26818 or diverged — axis closed, warmup hurt.

### Falsifying Result

If arm_c (strongest warmup) is worse than arm_a CTRL, the causal story (early AUX instability) is wrong; the AUX path may not be a bottleneck at initialization. If arm_b is better than arm_c, diminishing-returns schedule tuning is warranted. If both treatments are identical to CTRL, the AUX groups are already well-conditioned at step 0 and this axis is inert.

---

## H390 — Uniform Window SWA-Style Averaging at Eval
**Student:** edward (rank-2, ~11% WIN probability)
**Axis class:** EMA FORM — uniform window vs exponential (completely untested)
**LoC estimate:** ~20 LoC

### Orthogonality Verification

All closed EMA/averaging axes to date:
- H323: Polyak EMA decay VALUE bilateral (tested higher/lower decay, exponential form kept fixed)
- H267: Body-only PEMA scope (exponential form kept fixed)
- H332: EMA schedule — cosine/ramp decay schedule over cooldown (exponential form kept fixed)
- H383: Per-shape PEMA decay blocks (edward in-flight; still exponential, tests per-shape VALUE)

None of the above touched the FORM of averaging. All four axes used the same
`state.mul_(1-decay).add_(param, alpha=decay)` exponential update formula.
The question of whether a uniform-weight window over the last N weight snapshots
outperforms the geometrically-decayed exponential has never been tested.

This is the Stochastic Weight Averaging (SWA) insight applied to our EMA:
Izmailov et al. 2018 showed that flat minima are better captured by averaging
checkpoints uniformly over a cycle than by tracking an exponential shadow.
The mechanism is distinct from value tuning — a very slow exponential EMA
(e.g., decay=0.001) approximates a long window but still overweights recent steps.

### Mechanism

Replace the exponential `polyak_ema_state` with a circular buffer of the last
N weight snapshots. At eval, average all N snapshots uniformly. During training,
every step overwrites the oldest buffer slot (circular indexing: `buf[step % N]`).

The causal story: the H266 exponential EMA with decay=0.05 gives a half-life of
~14 steps (ln(2)/0.05). This very short window may be tracking a noisy local
trajectory rather than a basin center. A uniform window over, say, the last 50
steps gives equal weight to all recent checkpoints, smoothing the trajectory more
symmetrically and potentially centering on a lower-loss flat region. SWA literature
consistently shows that uniform averaging outperforms exponential EMA for finding
wide flat minima in overparameterized networks. The cost is O(N * param_count)
memory for the buffer, which is a fixed overhead per run.

### Implementation (~20 LoC)

Changes to `records/track_3_optimization/train_gpt_simple.py`:

1. Add `--swa_window` arg in `parse_args`:
```python
parser.add_argument("--swa_window", type=int,
    default=int(os.environ.get("SWA_WINDOW", "0")),
    help="Uniform-window SWA checkpoint count. 0 = use exponential EMA (H266 default).")
```

2. Initialization block (after existing polyak_ema_state init, ~line 1074):
```python
swa_buffer = None
if args.swa_window > 0:
    swa_buffer = [
        {name: param.data.clone().detach() for name, param in model.named_parameters()}
        for _ in range(args.swa_window)
    ]
    swa_filled = 0  # tracks how many slots have been written
```

3. In the per-step update block (~line 1220, after optimizer step):
```python
if swa_buffer is not None:
    slot = step % args.swa_window
    for name, param in model.named_parameters():
        swa_buffer[slot][name].copy_(param.data)
    swa_filled = min(swa_filled + 1, args.swa_window)
```

4. In the eval swap block (~line 1100), add a branch before the existing EMA swap:
```python
if swa_buffer is not None and swa_filled > 0:
    live_backup = {name: param.data.clone() for name, param in model.named_parameters()}
    n_slots = swa_filled
    for name, param in model.named_parameters():
        avg = sum(swa_buffer[i][name] for i in range(n_slots)) / n_slots
        param.data.copy_(avg)
    # ... run validation ...
    for name, param in model.named_parameters():
        param.data.copy_(live_backup[name])
    del live_backup
```

Note: `swa_window > 0` disables the exponential EMA path entirely; set
`--polyak_ema_decay 0.0` when using `--swa_window` to avoid double-averaging.

CTRL (arm_a): `--polyak_ema_decay 0.05 --swa_window 0` (H266 default).
arm_b: `--polyak_ema_decay 0.0 --swa_window 20` (short uniform window, ~14-step equivalent half-life).
arm_c: `--polyak_ema_decay 0.0 --swa_window 50` (longer uniform window, wider basin capture).

### 3-Arm Chain Design

arm_a CTRL (bit-for-bit H266 sentinel):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "edward/H390-arm_a-ctrl" \
  --wandb_group "H390-swa-form" \
  --polyak_ema_decay 0.05 \
  --swa_window 0
```

arm_b treatment (short SWA window):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "edward/H390-arm_b-swa20" \
  --wandb_group "H390-swa-form" \
  --polyak_ema_decay 0.0 \
  --swa_window 20
```

arm_c treatment (longer SWA window):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "edward/H390-arm_c-swa50" \
  --wandb_group "H390-swa-form" \
  --polyak_ema_decay 0.0 \
  --swa_window 50
```

### Decision Rules

- WIN: any arm achieves FFS < 3000 strictly.
- PROMISING: val/loss improves materially vs CTRL without hitting FFS<3000 — try window sizes 10/30/100, or combine with exponential EMA (dual-track shadow).
- NULL/CLOSE: both treatments within noise of CTRL and FFS not improved.
- NEG/CLOSE: SWA form hurts val/loss or destabilizes training (large val loss spikes during buffer fill phase).

Memory note: swa_window=50 requires 50x the param_count in float32 snapshots. For GPT-768/12L (~124M params), this is ~50 * 124M * 4B = ~25 GB. This fits in 96 GB VRAM but is a non-trivial overhead. If OOM is observed, try swa_window=20 first.

### Falsifying Result

If arm_c (window=50) is worse than arm_b (window=20) which is worse than CTRL, the uniform window form introduces more noise than benefit — the exponential form's recency bias is load-bearing. If arm_c matches arm_b but both are better than CTRL, a moderate window is the right setting and we should test 30/40/60 next. If both treatments match CTRL exactly, the averaging form is inert and only the EMA decay value matters (which H323 already closed).

---

## H391 — AGC Clip Ratio Cooldown Schedule
**Student:** thorfinn (rank-3, ~9% WIN probability)
**Axis class:** AGC SCHEDULE — time-varying clip_ratio (completely untested)
**LoC estimate:** ~12 LoC

### Orthogonality Verification

All previously closed AGC axes:
- H361: Static BODY AGC VALUE bilateral (muonh_agc_clip_ratio = {0.01, 0.03, 0.05, 0.07, 0.1} — all static throughout training)
- H353: Static AUX AGC VALUE bilateral (aux_agc_clip_ratio tested at multiple static values)

Both axes tested the static VALUE of AGC but never varied it over training time.
In the current implementation, `set_hparams` is called every step but AGC is
applied outside `set_hparams` using `args.aux_agc_clip_ratio` and
`args.muonh_agc_clip_ratio` directly — they are never modified by the scheduler.
No `--agc_schedule` or equivalent argument exists.

The SCHEDULE of AGC is a new axis: starting at the H266 static value (0.05) and
ramping it down during the cooldown phase has not been tested.

### Mechanism

Ramp the AGC clip_ratio down linearly from its full value (0.05) to a reduced
value (e.g., 0.01) over the cooldown window. During warmup and stable training
phases, AGC at 0.05 protects against large gradient spikes typical of early
training. During cooldown, the LR is already falling toward zero, gradient
magnitudes shrink, and the protective clipping may be over-constraining the
final few hundred steps. A tighter clip_ratio during cooldown allows the
weight trajectory to follow the gradient more precisely as LR → 0, potentially
finding a slightly better minimum within the basin.

The causal story: AGC clips the gradient norm relative to the parameter norm.
At high LR (early-mid training), aggressive clipping (0.05) prevents trajectory
escape. At low LR (cooldown), the parameter updates are already small;
the effective AGC constraint may be redundant or even slightly distorting
the gradient direction on near-zero-magnitude parameters. Tightening to
0.01 preserves more of the gradient's direction while maintaining the
scale-invariant property.

### Implementation (~12 LoC)

Changes to `records/track_3_optimization/train_gpt_simple.py`:

1. Add `--agc_cooldown_clip_ratio` arg in `parse_args`:
```python
parser.add_argument("--agc_cooldown_clip_ratio", type=float,
    default=float(os.environ.get("AGC_COOLDOWN_CLIP_RATIO", "-1.0")),
    help="AGC clip ratio at end of cooldown. -1 = static (H266 default). "
         "Linearly ramps from args.*_agc_clip_ratio to this value over cooldown.")
```

2. In `set_hparams` after cooldown fraction is computed (~line 970), add:
```python
if args.agc_cooldown_clip_ratio >= 0.0:
    # Determine cooldown progress across both optimizer groups
    aux_cd_start = 1.0 - aux_cooldown_frac   # = 1.0 - 0.4 = 0.6
    h_cd_start   = 1.0 - h_cooldown_frac     # = 0.0
    cd_progress = max(0.0, (progress - aux_cd_start) / max(aux_cooldown_frac, 1e-8))
    agc_t = args.aux_agc_clip_ratio + cd_progress * (
        args.agc_cooldown_clip_ratio - args.aux_agc_clip_ratio)
else:
    agc_t = None
```

3. In the step loop where AGC is called (~line 1207), replace static calls:
```python
_aux_clip = agc_t if (agc_t is not None) else args.aux_agc_clip_ratio
_body_clip = agc_t if (agc_t is not None) else args.muonh_agc_clip_ratio
agc_stats = adaptive_gradient_clip(aux_params_for_agc, _aux_clip, ...)
muonh_agc_stats = adaptive_gradient_clip(muonh_params_for_agc, _body_clip, ...)
```

Note: `agc_t` must be returned from `set_hparams` or stored in a shared mutable
container. The cleanest approach is to make `set_hparams` return `agc_t` or
use a module-level variable updated by `set_hparams`.

CTRL (arm_a): `--agc_cooldown_clip_ratio -1` (static, H266 default).
arm_b: `--agc_cooldown_clip_ratio 0.02` (moderate cooldown tightening: 0.05 → 0.02).
arm_c: `--agc_cooldown_clip_ratio 0.005` (aggressive cooldown tightening: 0.05 → 0.005).

### 3-Arm Chain Design

arm_a CTRL (bit-for-bit H266 sentinel):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "thorfinn/H391-arm_a-ctrl" \
  --wandb_group "H391-agc-schedule" \
  --agc_cooldown_clip_ratio -1.0
```

arm_b treatment (moderate tightening):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "thorfinn/H391-arm_b-agc-to-0.02" \
  --wandb_group "H391-agc-schedule" \
  --agc_cooldown_clip_ratio 0.02
```

arm_c treatment (aggressive tightening):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "thorfinn/H391-arm_c-agc-to-0.005" \
  --wandb_group "H391-agc-schedule" \
  --agc_cooldown_clip_ratio 0.005
```

### Decision Rules

- WIN: any arm achieves FFS < 3000 strictly.
- PROMISING: val/loss improvement without FFS<3000 — try finer ramp schedules (start earlier, non-linear ramp), or separate aux/body clip schedules.
- NULL/CLOSE: all arms FFS >= 3000 and val/loss within noise — AGC schedule is inert on this stack.
- NEG/CLOSE: arm_c (aggressive tightening) causes gradient norm growth or val loss spike in cooldown — over-tightening disrupts cooldown convergence.

### Falsifying Result

If arm_c is worse than arm_b and arm_b worse than arm_a, tightening AGC during
cooldown actively hurts — the protection it provides is load-bearing even at
low LR. If arm_b and arm_c are identical to CTRL, the AGC is never binding
during cooldown at either value, and the axis is inert. If arm_b is better than
arm_c but both beat CTRL, the ramp endpoint needs tuning (try 0.01-0.03).

---

## Summary Table

| ID | Axis Class | Student | WIN% | LoC | Primary Mechanism |
|----|------------|---------|------|-----|-------------------|
| H389 | WARMUP CURVE SHAPE on AUX | alphonse | ~11% | ~10 | Linear warmup added to AUX AdamW groups (embed/lm_head/scalars), currently zero warmup |
| H390 | EMA FORM (uniform window) | edward | ~11% | ~20 | Replace exponential Polyak EMA with SWA-style circular buffer + uniform mean at eval |
| H391 | AGC SCHEDULE (cooldown ramp) | thorfinn | ~9% | ~12 | Ramp AGC clip_ratio down linearly during cooldown, from static 0.05 to 0.005-0.02 |

All three hypotheses verified as genuinely untested axes against EXPERIMENTS_LOG.md
and train_gpt_simple.py code inspection as of 2026-06-02.
All three use the 3-arm chain design with bit-for-bit H266 CTRL sentinel as arm_a.
