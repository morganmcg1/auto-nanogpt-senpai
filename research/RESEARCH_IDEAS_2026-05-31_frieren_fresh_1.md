# Frieren Fresh Hypothesis — 2026-05-31

## muon-momentum-schedule: Cooldown Muon β ramp-down

### One-sentence summary

Schedule the Nesterov momentum coefficient `mu` in Muon from 0.95 to a lower
value (0.70–0.80) across the cooldown phase, reducing the EMA memory window
as LR collapses, so the update direction better tracks current loss-basin
geometry at the FFS crossing window.

---

### Mechanistic motivation

`muon_update` uses Nesterov momentum with `mu=0.95` throughout all 3250 steps.
This creates a gradient EMA with an effective memory of roughly 1/(1-0.95)=20
steps.

During the stable phase (steps 0–975), this tight EMA is desirable — it
smooths stochastic gradient noise and accelerates progress.

During cooldown (steps 975–3250), LR drops from its peak ~100× via cosine
decay. At step 3000 (near the FFS crossing window), LR is roughly 0.3% of
peak. At this scale:
- The gradient magnitude is much smaller
- The loss basin geometry near the target is highly curved
- A 20-step EMA tail lags behind the current gradient direction by a
  significant fraction of the remaining descent path

Reducing `mu` from 0.95 → 0.70 during cooldown shortens the EMA memory to
~3 steps, making Muon more reactive to the current gradient geometry. The NS5
Stiefel projection still operates on the resulting momentum update — it
ortho-normalizes whatever the Nesterov blend produces.

Key distinction from prior μ-cooldown work (PR #1880, FFS-NEUTRAL, CLOSED):
- #1880 was **pre-NS5 additive gradient perturbation** — it added a signal to
  the raw gradient before NS5 projection. NS5 absorbed it (relative magnitude
  too small to survive projection).
- This proposal changes the **Nesterov EMA coefficient** (`mu=`) — a
  multiplicative parameter that controls which gradient direction is fed into
  NS5. This is structurally different: a lower `mu` means the Nesterov blend
  `grad.lerp(momentum, mu)` shifts toward the raw gradient rather than the
  smoothed EMA. The resulting input to NS5 is directionally different, not
  just perturbed by a small additive term.
- Confirmed: `mu` is passed as `mu=group["mu"]` at the call site (line 670),
  not as a compiled constant. Dynamic scheduling works without any
  recompilation (unlike NS_ITER which required two compiled function pairs).

For SOAP-preconditioned params (MLP fc/proj + attn Q/K/V/proj with `--soap_attn`),
the same `group["mu"]` is used in lines 655-656:
```python
state["momentum"].lerp_(p.grad, 1 - group["mu"])
raw_nesterov = p.grad.lerp(state["momentum"], group["mu"])
```
So the same schedule applies to both Muon and SOAP update paths uniformly.

---

### Prior work review confirming this axis is open

All 81 R5 closures reviewed. No experiment has touched `mu=0.95`:

- #1880 tanjiro μ-cooldown: **pre-NS5 gradient perturbation**, not the
  Nesterov coefficient. FFS-NEUTRAL. CLOSED. Explicitly different mechanism.
- #1897 nezuko SGLD: additive gradient noise, pre-NS5. FFS-NEG. CLOSED.
- #1891 askeladd GE-SAM: sharpness-aware gradient modifier, pre-NS5.
  FFS-NEUTRAL. CLOSED.
- #1885 fern gradient clipping: pre-NS5. FFS-NEUTRAL. CLOSED.
- All 4 members of additive-pre-NS5 family: CLOSED. Ruled out.
- Muon `mu` parameter: confirmed NEVER touched in any closed or open WIP at
  the time of this assignment.

In-flight PRs (7 WIPs), none touch `mu`:
- tanjiro #1964: ns-iter-cooldown (NS_ITER schedule at 75%)
- thorfinn #1957: ema-decay-cooldown-schedule (ema_eval_decay ramp)
- nezuko #1955: adamw-eps-cooldown (AdamW ε log-decay)
- edward #1948: precond-freq-cooldown-schedule (PRECOND_FREQ ramp)
- alphonse #1941: muon-depth-lr-scale (per-layer LR scaling)
- askeladd #1942: logit-z-loss (logit variance regularization)
- fern #1922: wd-cooldown-shape (weight-decay shape)

---

### Implementation plan

The change is confined to `set_hparams()` (lines 917-931 of train_gpt_simple.py).

**Step 1 — Add CLI flags (~5 LOC near other schedule flags):**

```python
parser.add_argument("--mu_cooldown_target", type=float, default=None,
    help="If set, linearly ramp Muon momentum from 0.95 to this value "
         "across the cooldown phase. None = constant 0.95 (default).")
```

**Step 2 — Add a helper or inline ramp in set_hparams (~10 LOC):**

Inside `set_hparams(step, cooldown_frac=0.7)`, after the existing LR/WD block,
add for Muon groups:

```python
if args.mu_cooldown_target is not None:
    if progress < 1 - cooldown_frac:
        mu_sched = 0.95  # stable phase: unchanged
    else:
        x = (progress - (1 - cooldown_frac)) / cooldown_frac
        # linear ramp from 0.95 to mu_cooldown_target across cooldown
        mu_sched = 0.95 + (args.mu_cooldown_target - 0.95) * x
    for opt in optimizers:
        for group in opt.param_groups:
            if group.get("name", "").startswith("muon_"):
                group["mu"] = mu_sched
```

**Step 3 — Log the current mu to W&B:**

In the telemetry block, add:
```python
if args.mu_cooldown_target is not None:
    # log the current mu value for each Muon group
    for group in optimizer2.param_groups:
        gname = group.get("name", "muon")
        wandb.log({"train/mu/" + gname: group["mu"]}, step=step, commit=False)
```

**Total change: ~20 LOC. No torch.compile modifications needed.**

---

### Experimental cells

Use `--wandb_group frieren/muon-momentum-schedule` for all runs.

Baseline mandatory stack (do NOT change):
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine
--ema_eval_decay 0.99
```

**Cell A — control (no-op)**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "frieren/mu-sched-A-ctrl" \
  --wandb_group "frieren/muon-momentum-schedule" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99
```
Expected: FFS_ema ≈ 2875, FFS_trainval ≈ 2925 (seed-noise attractor baseline).

**Cell B★ — primary: linear ramp 0.95→0.70 across cooldown**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "frieren/mu-sched-B-0.70" \
  --wandb_group "frieren/muon-momentum-schedule" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --mu_cooldown_target 0.70
```
Rationale: 0.70 gives ~3-step memory at end of cooldown vs 20-step at 0.95.
The ramp is linear: at step 975 mu=0.95, at step 3250 mu=0.70.

**Cell C — shallower ramp: 0.95→0.80**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "frieren/mu-sched-C-0.80" \
  --wandb_group "frieren/muon-momentum-schedule" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --mu_cooldown_target 0.80
```
Rationale: mu=0.80 gives ~5-step memory. More conservative ramp. Good
discriminator between "mu reduction helps" vs "exact target matters."

**Cell D — deep ramp: 0.95→0.60**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "frieren/mu-sched-D-0.60" \
  --wandb_group "frieren/muon-momentum-schedule" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --mu_cooldown_target 0.60
```
Rationale: at mu=0.60 EMA memory = 2.5 steps. Almost no smoothing. May
cause instability or underfitting if gradient noise is still significant at
these scales. Diagnostic for instability floor.

---

### Signal gates and stop conditions

**Signal gate (n=1, proceed to n=4):**
Any cell shows FFS_ema ≤ 2862 OR FFS_trainval ≤ 2912.

**No-signal stop (close as FFS-NEG/NEUTRAL):**
All cells show FFS_ema > 2950 AND FFS_trainval > 2975.

**Monotone pattern analysis:**
If B★(0.70) > C(0.80) > A(0.95) in FFS terms (more ramp = worse), that
matches the same monotone pattern seen in LN-gain-init (#1907) and label
smoothing (#1870) — it would mean the R5 stack is at a tight variance optimum
and also at a tight momentum optimum. Close immediately in that case.

If non-monotone (e.g., C(0.80) better than both A and D), the signal is live:
there is a sweet spot in EMA memory length. Proceed to n=4 with the best cell.

---

### Pre-mortem

1. **NS5 re-absorbs the change**: If reducing `mu` only shifts the
   Nesterov-blend direction by a small fraction, NS5's orthogonalization may
   normalize it away. Counter: unlike pre-NS5 additive perturbation, changing
   `mu` changes the *input direction* to NS5, not just adds noise to it. A
   different input direction to NS5 produces a genuinely different orthogonal
   update. The pre-NS5 family was absorbed because the perturbation was small
   *relative to the dominant singular vectors* — but mu changes the entire
   blend weight, which affects all singular components.

2. **SOAP preconditioner adapts, washing out the change**: SOAP's eigenbasis
   `q_row, q_col` is updated every 16 steps (PRECOND_FREQ=16). If the
   momentum direction change from a lower `mu` is gradual, SOAP's
   second-moment estimate will adapt, partially canceling the effect.
   Diagnostic: check cos_sim values in W&B to see if trust-gate behavior
   changes. If SOAP cos_sims increase (more trust granted), that confirms the
   momentum change is improving update quality.

3. **Seed noise dominance**: The FFS crossing window (2800-3050) has known
   ≈50-step seed noise. If the signal is <25 FFS steps, it will be
   statistically invisible at n=1. Always need n=4 for confirmation below that
   threshold.

4. **Per-group mu divergence**: Both `muon_mlp` and `muon_attn` groups get the
   same `mu` schedule. It's possible the two groups benefit from different
   schedules. Do not test this at n=1 — it's a follow-up hypothesis (4 cells).

---

### Baseline

Current best metrics at R5 (PR #1533 n=4 confirmation):
- `speedrun/final_first_step_to_target` (primary): μ₄=2912.5, σ₄=25
- `val/loss`: 3.276 (n=1 1-sigma margin from 3.28)
- FFS range: {2875, 2925, 2925, 2925} across 4 seeds
- Reproduce: mandatory stack above with no extra flags
- W&B run ids (n=4): see PR #1533

Statistical claim rule: `(3.28 - mu) * sqrt(n) >= 0.004`
- n=1: loss < 3.276 required
- n=4: mean loss < 3.278 required
