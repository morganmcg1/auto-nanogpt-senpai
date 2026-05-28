# Research Ideas — Cycle ~980 (2026-05-28)

Generated for two idle students after H236 (fern, outer MuLoCo Polyak FORM, bilateral NULL/NEG) and H237 (nezuko, AdEMAMix dual-timescale aux momentum, bilateral NEG).

Baseline: PR #1398, H203, FFS=3025, val=3.26830.

WIP (must not duplicate): H238 AdaMuon per-element body scaling, H239 SF-AdamW aux, H240 EMA model averaging, H241 Lion aux sign-based, H242 MuonH WSD stable phase, H243 Fractional NS spectral exponent.

---

## H244 — Depth-scaled per-layer LR on MuonH body (μP-inspired)

**Assigned to: g1r3-fern**

### What it is

Replace the single uniform learning rate shared across all 72 body weight matrices in MuonH with per-layer learning rates that decay with layer depth. The scaling follows the μP (Maximal Update Parameterization) insight that, in residual networks, the effective contribution of each layer's update to the output logits grows with depth, so later layers should use smaller step sizes to remain in a stable training regime.

### Mechanism class

Per-layer LR scaling on the body optimizer — **never tested in this programme**. All 94 closed hypotheses and all 6 WIP hypotheses apply a single scalar LR multiplied uniformly across every body weight matrix. This is the first experiment to break that single-group structure.

### Why it might help

The nanoGPT model has 12 transformer layers. Layer 0 sits directly after the embedding; layer 11 sits directly before the logit projection. In a residual network the pre-softmax logit is the sum of all layer contributions: `logit = embed + sum_{l=0}^{11} F_l(...)`. If all 12 `F_l` are updated with the same step size, later layers that have accumulated more residual signal will see a proportionally larger change to the logit on each step. μP theory (Yang et al. 2022, Doshi et al. 2025) prescribes scaling each layer's LR by `1/depth_factor(l)` to keep the logit-update magnitude roughly constant across layers. A cleaner per-layer LR profile should reduce interference between layers during the first half of training and sharpen the cooldown trajectory.

The NS5 polar projection already normalizes gradient spectral norm to ~1, so the per-layer update direction is already well-conditioned; only the step magnitude varies. This means depth-scaling only adds the missing magnitude calibration on top of an already-structured update.

### Why it is fresh / non-redundant

- H238 (AdaMuon): per-element diagonal preconditioner, still uniform LR across layers.
- H222 (outer_lr magnitude sweep): tunes a scalar for MuLoCo outer step, not per MuonH layer.
- H225 (muonh_beta1 sweep): scalar momentum, not per-layer.
- H228 (muonh_WD bilateral): scalar WD on body, not per-layer.
- H203 (baseline H-forks): all body in one MuonH group.

No prior experiment has created multiple MuonH param_groups or varied the per-layer LR profile.

### Key papers

1. Yang et al. (2022). "Tensor Programs V: Tuning Large Neural Networks via Zero-Shot Hyperparameter Transfer." arXiv:2203.03466. Derives the μP prescription: hidden-layer LR ∝ 1/fan_in; in a depth-d residual net this implies LR ∝ 1/sqrt(d_l) for the l-th residual block to keep logit perturbation O(1).

2. Doshi et al. (2025). "μP in Practice." arXiv:2505.02222 (Essential AI). Empirical validation of μP across GPT-class models; shows per-layer scaling consistently improves convergence rate. Key finding: linear depth scaling (LR * (1 - l/2L)) and inverse-sqrt scaling (LR / sqrt(1 + l/L)) both work; linear is slightly more aggressive at deep layers.

3. Everett et al. (2024). "Scaling Exponents Across Parameterizations and Optimizers." arXiv:2407.05872. Shows that the correct per-layer LR exponent depends on the optimizer's effective preconditioner; for sign-normalized updates (like NS5-Muon) the exponent is closer to linear than to 1/sqrt.

### 3-arm design

- **arm_a (CTRL)**: current baseline — all body params in a single MuonH group, `muonh_lr=0.018`. This is bit-identical to H203 and serves as the within-experiment reference.
- **arm_b (LINEAR_DEPTH)**: 12 per-layer MuonH param groups; layer `l` gets `lr = 0.018 * (1.0 - l / (2 * 12))` which gives `lr_0=0.018, lr_11=0.018*0.542=0.00975`. Linear taper from μP theory + Everett et al. 2024 recommendation for sign-based optimizers.
- **arm_c (INVSQRT_DEPTH)**: same 12-group split; layer `l` gets `lr = 0.018 / sqrt(1.0 + l / 12)`, giving `lr_0=0.018, lr_11=0.018/sqrt(1.917)=0.01300`. Softer taper matching Yang et al. 2022 prescription.

All other HPs identical to H203: `train_steps=3350`, `outer_lr=0.7`, `outer_momentum=0.5`, `sync_interval=30`, `aux_beta2_start=0.95`, `aux_beta2_end=0.99`, `muonh_budget_mult=1.0`, `body_init=default`.

### Expected wallclock

~1h48m per arm × 3 arms = ~5h24m total. No added per-step cost — only optimizer initialization changes (group creation is O(12) not O(1), negligible).

### Implementation sketch (~60 LoC)

Add CLI arg:
```python
parser.add_argument("--muonh_depth_scale", type=str, default="none",
                    choices=["none", "linear", "invsqrt"],
                    help="Depth-scaled per-layer LR on MuonH body")
```

Replace optimizer2 creation (around line 929):
```python
import math

if args.muonh_depth_scale == "none":
    # Original single-group path — preserves bit-identity for CTRL arm
    optimizer2 = MuonH(
        [p for p in model.blocks.parameters() if p.ndim >= 2],
        lr=args.muonh_lr, weight_decay=0.0, mu=0.95,
        hyperball=True, budget_mult=args.muonh_budget_mult,
        mode=args.muonh_mode)
    optimizer2.param_groups[0]["name"] = "muonh_blocks"
else:
    body_groups = []
    for layer_idx, block in enumerate(model.blocks):
        layer_params = [p for p in block.parameters() if p.ndim >= 2]
        if not layer_params:
            continue
        if args.muonh_depth_scale == "linear":
            scale = 1.0 - layer_idx / (2.0 * len(model.blocks))
        else:  # invsqrt
            scale = 1.0 / math.sqrt(1.0 + layer_idx / len(model.blocks))
        body_groups.append({
            "params": layer_params,
            "lr": args.muonh_lr * scale,
            "name": f"muonh_layer_{layer_idx}",
        })
    optimizer2 = MuonH(
        body_groups, weight_decay=0.0, mu=0.95,
        hyperball=True, budget_mult=args.muonh_budget_mult,
        mode=args.muonh_mode)
```

The `set_hparams(step)` function already iterates over all `opt.param_groups` and applies
`group["lr"] = group["initial_lr"] * eta`, so cooldown/warmup automatically respects the
per-layer initial LR. The `MuonH.__init__` reads `params` as a list of dicts in the standard
PyTorch way, so each dict becomes its own param group with its own `initial_lr`.

**IMPORTANT — MuonH.__init__ must store `initial_lr` per group.** Check that the constructor
does `group["initial_lr"] = group["lr"]` for each group as part of `self.add_param_group`.
If it only stores it for a single group, add:
```python
for g in optimizer2.param_groups:
    g["initial_lr"] = g["lr"]
    g.setdefault("cooldown_frac", h_cooldown_frac)
    g.setdefault("warmup_steps", h_warmup_steps)
```
right after optimizer2 is created (before `set_hparams` is called at step 0).

**WandB telemetry fix** — line 1193 logs only `param_groups[0]["lr"]`. For per-layer arms,
also log the mean body LR and the min/max spread:
```python
if args.muonh_depth_scale != "none":
    lrs = [g["lr"] for g in optimizer2.param_groups]
    wandb_log({"train/lr/muonh_mean": sum(lrs)/len(lrs),
               "train/lr/muonh_min": min(lrs),
               "train/lr/muonh_max": max(lrs)}, step=step)
```

**MuLoCo outer step** (lines 1267–1303) iterates `model.named_parameters()` uniformly and
applies the same `outer_lr`/`outer_momentum` regardless of layer — no changes needed.

### Predicted outcome

Moderately optimistic: **WIN with ~50 FFS improvement probability ~35%, NULL ~50%, NEG ~15%.**

Rationale: The NS5 polar projection already removes magnitude variation from the gradient direction, leaving only the question of step size. The uniform LR has served well (H203 FFS=3025), but it is plausible that early-layer weights are over-stepped relative to late-layer weights. The μP literature shows consistent gains in medium-scale GPT models. However, the nanoGPT model is small (768d, 12L) and heavily tuned — marginal gains from LR-only adjustment at this scale may be within noise. The linear taper (arm_b) is the more theoretically motivated choice for NS5/Muon-like optimizers per Everett et al. 2024; the invsqrt taper (arm_c) provides a softer alternative. If arm_b wins by >25 FFS, the mechanism is real and should be followed by a sweep of the taper slope.

### Stop condition

Close without follow-up if both treatment arms are within +/- 1 sigma of CTRL (FFS within ~25 steps and val/loss within 1e-4). Send back for taper-slope sweep if arm_b or arm_c wins by >25 FFS.

---

## H245 — ADana log-time momentum schedule on aux AdamW

**Assigned to: g1r3-nezuko**

### What it is

Replace the fixed β1=0.8, β2=0.95–0.99 schedule in the aux AdamW optimizer with ADana's theoretically-motivated log-time schedule: `β_t = 1 - δ/(δ+t)` for the first moment and optionally also the second moment. ADana (Adaptive Anytime Adam) is an Adam variant proven to achieve optimal convergence rates without a manually-tuned learning rate or momentum schedule, by letting the effective window size grow logarithmically with training time.

### Mechanism class

Log-time adaptive momentum schedule for the aux optimizer — **never tested in this programme**. All 94 closed hypotheses and all 6 WIP hypotheses either use fixed β1 (H225 found β1=0.8 optimal for body), a manual cosine/linear/ramp schedule (H229 NS5 Nesterov), or a fully schedule-free formulation (H239 SF-AdamW). ADana is the only known schedule that achieves anytime-optimal convergence via parameter-free log-time adaptation.

### Why it might help

The aux AdamW handles embed (LR=0.3), lm_head (LR=1/320), biases, and scalars — parameters that are NOT processed through NS5 polar projection and do NOT benefit from Muon's spectral normalization. These are low-dimensional or effectively 1D parameters (embed is [50304, 768] but treated as a lookup table). For these parameters, the standard Adam bias correction produces effective β windows that grow as `1/(1-β^t)`, making early steps very noisy (low β_eff) and late steps very conservative (high β_eff). ADana's log-time schedule produces β_t ≈ 1 - 1/ln(t+e), which gives a natural, theoretically-optimal window growth without the sharp corner that the cosine cooldown introduces. The existing `aux_beta2_start=0.95 → aux_beta2_end=0.99` ramp (which is already a nod to this direction) only adjusts β2; ADana adjusts both β1 and β2 simultaneously in a principled way.

The aux optimizer is also where the embed is trained — the embed LR is extremely high (0.3 vs 0.018 for body), making it the most dynamics-sensitive parameter group. A schedule that provides larger effective windows early (when gradients are most informative) and narrows them late (when the embed has converged) could sharpen the embed's training trajectory without the abrupt transitions from manual schedules.

### Why it is fresh / non-redundant

- H239 (SF-AdamW): schedule-free formulation eliminates LR schedule entirely; different mechanism, WIP.
- H225 (muonh_beta1 sweep): body-only, fixed scalar β1 on MuonH momentum; not aux, not log-time.
- H229 (NS5 inner Nesterov): Nesterov form for MuonH inner step; not aux, not log-time.
- H237 (AdEMAMix): dual time-scale momentum with a fixed α blend; aux-side, fixed HPs, bilateral NEG. ADana is fundamentally different — single optimizer, log-time schedule, no extra buffer, no auxiliary momentum.

No prior experiment has applied a log-time momentum schedule to the aux AdamW.

### Key paper

Ferbach et al. (2026). "ADana: Adaptive Anytime Adam." arXiv:2602.05298. Main result: by setting `β_t = 1 - δ/(δ+t)` for both moments (with δ chosen to match the desired early-time β), ADana achieves the minimax-optimal convergence rate for non-convex stochastic optimization at every intermediate time step, not just at a fixed horizon. The paper shows that this eliminates the need for tuned LR decay while preserving or improving final loss. Key ablation: δ≈8 is robust across tasks; the β2 log-schedule matters more than the β1 log-schedule for Adam-family optimizers.

### 3-arm design

- **arm_a (CTRL)**: current aux AdamW with β1=0.8 (fixed), β2 cosine ramp 0.95→0.99. Bit-identical to H203 aux side.
- **arm_b (ADANA_B2ONLY)**: Apply ADana schedule to β2 only: `β2_t = 1 - δ/(δ+t)`, δ=100 (so β2_0 ≈ 1 - 100/101 ≈ 0.0099 — note: this is the β of the *moment*, not the standard 0.99; equivalently β2_t approaches 1 as t→∞). Keep β1=0.8 fixed. `δ=100` chosen so that β2_t=0.99 at t ≈ 9900 steps (close to end of 3350 steps ≈ β2≈0.971), providing a natural ramp that is more aggressive than the current cosine ramp in early steps.

  Actually, use a more interpretable parameterization: `β2_t = 1 - δ/(δ+t)` means at t=1: β2=1-δ/(δ+1)≈1-1=0 which is wrong. The correct ADana form starts from a small initial window. Use:
  ```
  β2_t = 1 - δ/(δ + t)   with δ=8
  ```
  At t=1: β2=1-8/9=0.111; at t=30: β2=1-8/38=0.789; at t=100: β2=1-8/108=0.926; at t=1000: β2=1-8/1008=0.992; at t=3350: β2=1-8/3358=0.9976. This naturally grows from ~0.11 at step 1 to ~0.998 at end of run, providing larger effective windows later. Note this is MORE aggressive early than the current β2=0.95 fixed.

- **arm_c (ADANA_BOTH)**: Apply ADana schedule to BOTH β1 and β2: `β1_t = 1 - δ/(δ+t)` with δ_1=3 (slower growth for β1), `β2_t = 1 - δ/(δ+t)` with δ_2=8. At t=1: β1=0.25, β2=0.111; at t=100: β1=0.971, β2=0.926; at t=3350: β1=0.9991, β2=0.9976. The δ values are chosen so that β1 starts near 0 and reaches ~0.95+ midway through training, mirroring the natural Adam bias-correction regime. This arm tests whether the β1 schedule adds signal beyond the β2 schedule.

All other HPs identical to H203: `train_steps=3350`, `muonh_lr=0.018`, `outer_lr=0.7`, `outer_momentum=0.5`, `sync_interval=30`, `muonh_budget_mult=1.0`, `body_init=default`.

### Expected wallclock

~1h48m per arm × 3 arms = ~5h24m total. ADana adds 2 division operations per step to `set_hparams`, negligible cost.

### Implementation sketch (~50 LoC)

Add CLI args:
```python
parser.add_argument("--aux_adana_delta_b2", type=float, default=0.0,
                    help="ADana delta for aux beta2 log-time schedule; 0=disabled")
parser.add_argument("--aux_adana_delta_b1", type=float, default=0.0,
                    help="ADana delta for aux beta1 log-time schedule; 0=disabled")
```

In `set_hparams(step)`, after the existing beta2 schedule block (which sets `b2` and then
`g["betas"] = (g["betas"][0], b2)` for optimizer1 groups), add:

```python
# ADana log-time schedule for aux optimizer betas
# Must run AFTER the existing beta2 cosine ramp so ADana overrides it when active
t = step + 1  # 1-indexed for log-time schedule
if args.aux_adana_delta_b2 > 0:
    delta_b2 = args.aux_adana_delta_b2
    adana_b2 = 1.0 - delta_b2 / (delta_b2 + t)
    for g in optimizer1.param_groups:
        old_b1 = g["betas"][0]
        g["betas"] = (old_b1, adana_b2)

if args.aux_adana_delta_b1 > 0:
    delta_b1 = args.aux_adana_delta_b1
    adana_b1 = 1.0 - delta_b1 / (delta_b1 + t)
    for g in optimizer1.param_groups:
        old_b2 = g["betas"][1]
        g["betas"] = (adana_b1, old_b2)
```

**Arm configs:**

arm_a (CTRL): `--aux_adana_delta_b2 0.0 --aux_adana_delta_b1 0.0`
(standard cosine β2 ramp, β1=0.8 fixed)

arm_b (ADANA_B2ONLY): `--aux_adana_delta_b2 8.0 --aux_adana_delta_b1 0.0`
(ADana β2 log-time, β1=0.8 fixed)

arm_c (ADANA_BOTH): `--aux_adana_delta_b2 8.0 --aux_adana_delta_b1 3.0`
(ADana β2 AND β1 log-time)

**Implementation note on ordering:** The existing `set_hparams` code computes `b2` from a
cosine/cooldown_ramp schedule and then assigns `g["betas"] = (g["betas"][0], b2)`. The ADana
block above must come AFTER that existing block so that it overrides `b2` with the log-time
value. The cleanest approach is to gate the existing beta2 ramp with `if args.aux_adana_delta_b2 == 0.0:` and put ADana in the else branch, to avoid unnecessary computation.

**WandB telemetry:** Add logging for the current aux betas at each `set_hparams` call:
```python
wandb_log({"train/aux_beta1": optimizer1.param_groups[0]["betas"][0],
           "train/aux_beta2": optimizer1.param_groups[0]["betas"][1]}, step=step)
```
This is essential for diagnosing whether the schedule is tracking as expected.

**Important implementation caveat:** The existing `aux_beta2_start` and `aux_beta2_end` args
must still be accepted by argparse (for CTRL arm compatibility), but their effect on arm_b and
arm_c should be bypassed. The cleanest way is to check `args.aux_adana_delta_b2 > 0` before
applying the cosine ramp.

### Predicted outcome

Cautiously optimistic: **WIN probability ~30%, NULL ~55%, NEG ~15%.**

Rationale: The ADana paper demonstrates its advantage most clearly in settings where the
optimal LR schedule horizon is unknown (i.e., when you cannot tune a cosine decay endpoint).
In this benchmark the step count is fixed at 3350 and the existing β2 ramp is already a
manual approximation of larger-window-late behavior. ADana's log-time schedule provides a
more principled and continuous version of the same idea. The most likely win scenario is on
the embed, where the 0.3 LR is very high and the embed is the first thing to converge —
an early-steps small effective β window (from the log-time schedule starting near 0) could
provide better gradient signal integration before the embed saturates. The NEG scenario
arises if the very-small-β2 in early steps (β2_0≈0.11 for δ=8) makes Adam's second-moment
estimate too noisy, leading to unstable early updates. The safeguard is that the embed LR
is controlled by the cooldown and is already quite high; if early instability occurs it
should manifest as loss spikes in the first ~100 steps, clearly visible in train/loss.

arm_c (ADANA_BOTH) is the riskier arm — starting β1 near 0 means almost no momentum early,
which could hurt or help depending on whether early gradient noise is signal or noise for
the embed. arm_b (ADANA_B2ONLY) is the conservative test of the core ADana claim.

### Stop condition

Close without follow-up if both treatment arms are within +/- 1 sigma of CTRL (FFS within
~25 steps). Investigate if early train/loss (first 300 steps) shows instability — that would
indicate delta values need upward adjustment (larger delta = smaller early window growth).
Send back for delta sweep if arm_b wins by >25 FFS with stable early loss.

---

## Summary table

| ID | Student | Mechanism | Class | Arms | Predicted WIN prob |
|----|---------|-----------|-------|------|--------------------|
| H244 | g1r3-fern | μP depth-scaled per-layer LR on MuonH | Body LR topology | linear / invsqrt | ~35% |
| H245 | g1r3-nezuko | ADana log-time β schedule on aux AdamW | Aux momentum schedule | b2-only / both | ~30% |

Both hypotheses target different parts of the optimizer stack (body LR distribution vs aux
momentum schedule), are mechanistically orthogonal to each other and to all 6 WIP experiments,
and are grounded in published theory with explicit arxiv citations and known ablation results.
