# Fresh R5 Hypotheses — 2026-05-31 22:00

Generated for: g1r5-fern (IDLE — no open R5 WIP)

Confirmed NOT overlapping any closed or in-flight R5 experiment:
- All 7 open WIPs checked: #2020 nezuko (soap-beta2-cooldown), #2014 tanjiro (ns-iter-cooldown-ramp), #1994 thorfinn (soap-state-cooldown-reset), #1989 askeladd (aux-cooldown-shape-decoupling), #1979 alphonse (lr-warm-restart-probe), #1966 frieren (muon-momentum-schedule)
- Closed families reviewed: additive-pre-NS5 (4 members), AUX-side cooldown (eps+ema-decay+beta1, CLOSED FFS-NEUTRAL), LN-gain-init<1.0 (FFS-NEG), NS5-absorption family (3 members)
- AUX optimizer axis (Lion, Schedule-Free AdamW, AdaFactor): UNTOUCHED in all R5 experiments

---

## TOP RECOMMENDATION: Hypothesis 1 (assign to fern immediately)

**Lion as AUX optimizer** — replace AdamW for the embed/lm_head/scalars groups with Lion
(sign-based momentum, ~35 LOC, no torch.compile changes needed). The AUX-side cooldown
family exhausted additive schedule modifications on AdamW; Lion changes the underlying
update geometry. The AUX groups contribute ~10% of parameters but embed 100% of token
representations — update quality there is disproportionately impactful. Pre-mortem risk:
small-batch setting may suppress Lion's advantages (Chen et al. ablation; nanoGPT's
65,536 tokens/batch is in the borderline zone). The 4-cell design sweeps β₁ (0.9 vs 0.99)
and LR scale (0.1× vs 0.3×) to detect whether the advantage survives at this batch size.

---

## Hypothesis 1: lion-aux-optimizer

### One-sentence summary

Replace AdamW with Lion for the three AUX parameter groups (embed.weight,
lm_head.weight, scalars/biases/RMSNorm-gains) to test whether a sign-based
momentum update improves FFS performance compared to the current second-moment
Adam update on the embedding and output projection parameters.

---

### Mechanistic motivation

The current AUX optimizer uses AdamW (betas=(0.8, 0.95), eps=1e-10, wd=0):

```python
optimizer1 = AdamW([
    dict(params=[model.embed.weight], lr=0.3, name="adam_embed"),
    dict(params=[model.proj.weight], lr=1/320, name="adam_lm_head"),
    dict(params=[p for p in model.parameters() if p.ndim < 2],
         lr=args.lr_scalars, name="adam_scalars")
], betas=(0.8, 0.95), eps=1e-10, weight_decay=0, fused=True)
```

Lion (Chen et al. 2023) replaces the Adam update with:

```
update = sign(interpolate(gradient, momentum, β₁=0.9))
momentum = interpolate(gradient, momentum, β₂=0.99)
parameters = parameters - lr × update - lr × λ × parameters
```

Key difference: Lion's update direction is always ±1 (sign-quantized), which:
1. Removes second-moment variance adaptation — all parameters move the same
   step size each iteration (modulo LR scaling).
2. Reduces memory: only momentum state, no v_t second moment.
3. Scales with the number of updates not gradient magnitude — more like a
   trust-region method than a gradient descent.

The AUX-side cooldown family (eps, ema_eval_decay, beta1) all ran on AdamW
and was pronounced FFS-NEUTRAL (absorbed by LR decay). This does NOT rule out
a different optimizer algorithm — it rules out additive schedule modifications
to AdamW. Lion is a completely different update rule.

Why embed/lm_head specifically?
- embed.weight (50,257×768=38.6M params) sees every token gradient but with
  extreme sparsity (each forward pass touches only ~1024 out of 50,257 rows).
  Sign-based updates may be more stable under this sparsity pattern.
- lm_head is tied to embed in the nanoGPT reference; both see the same
  input/output vocabulary space. Lion's constant step size may encourage
  more uniform learning across rare vs. frequent tokens.

LR scaling requirement: Lion requires 3-10× smaller LR than Adam. Current
embed LR=0.3, so Lion needs lr≈0.03–0.10. Current lm_head LR=1/320≈0.003125,
so Lion needs lr≈0.0003–0.001. Current scalars LR=0.03, so Lion needs
lr≈0.003–0.010.

CRITICAL RISK — small-batch sensitivity:
Paper ablation (arxiv 2509.01440v1, "Lion: Adversarial Distillation of Closed-Form
Losses") confirms Lion underperforms AdamW at batch sizes ≤32×512 tokens
(~16K tokens/batch). NanoGPT uses batch=64×1024=65,536 tokens/step. This is
borderline — well above the dangerous floor, but below the clearly safe
≥256×512 regime where Lion shows consistent wins. The hypothesis is that
65,536 tokens/step is large enough for Lion's sign updates to remain stable,
but this is the primary uncertainty.

β₁ finding from LLM pretraining benchmark: Chen et al. (arxiv 2509.01440v1)
finds β₁=0.99 outperforms the paper default β₁=0.9 in LLM pretraining.
Cell C below tests this directly.

---

### Prior work review confirming this axis is open

All R5 closures (91 as of commit 180b376) reviewed. Zero experiments touch the
AUX optimizer algorithm:

- AUX-side cooldown family (tanjiro #1988, frieren-AUX #1983, nezuko-beta1 #1993):
  all modify AdamW schedule parameters (eps, beta1, ema_eval_decay). CLOSED
  FFS-NEUTRAL. Explicitly NOT algorithm changes.
- No PR has replaced AdamW with a different optimizer for any parameter group.
- Fern's cautious-optimizer WIP (r3 #2006): sign-agreement masking on existing
  Adam update. Structurally different — masks the Adam update, does not replace
  it. No overlap.
- Lion is not mentioned in any closed or open PR, research note, or experiment log.

---

### Implementation plan

**Step 1 — Add Lion optimizer class (~35 LOC, before optimizer instantiation):**

```python
class Lion(torch.optim.Optimizer):
    """Sign-based momentum optimizer. Chen et al. (2023).
    Requires 3-10x smaller LR than Adam."""
    def __init__(self, params, lr=1e-4, betas=(0.9, 0.99), weight_decay=0.0):
        defaults = dict(lr=lr, betas=betas, weight_decay=weight_decay)
        super().__init__(params, defaults)

    @torch.no_grad()
    def step(self):
        for group in self.param_groups:
            beta1, beta2 = group['betas']
            for p in group['params']:
                if p.grad is None:
                    continue
                grad = p.grad
                state = self.state[p]
                if len(state) == 0:
                    state['momentum'] = torch.zeros_like(p)
                m = state['momentum']
                # update direction: sign of (β₁ * m + (1-β₁) * grad)
                update = (beta1 * m + (1 - beta1) * grad).sign()
                # apply WD then update
                p.mul_(1 - group['lr'] * group['weight_decay'])
                p.add_(update, alpha=-group['lr'])
                # update momentum with β₂
                m.mul_(beta2).add_(grad, alpha=1 - beta2)
```

**Step 2 — Add CLI flags (~8 LOC):**

```python
parser.add_argument("--use_lion_aux", action="store_true", default=False,
    help="Replace AdamW with Lion for embed/lm_head/scalars groups.")
parser.add_argument("--lion_beta1", type=float, default=0.9,
    help="Lion β₁ (update interpolation weight). Default=0.9 (paper).")
parser.add_argument("--lion_beta2", type=float, default=0.99,
    help="Lion β₂ (momentum update weight). Default=0.99 (paper).")
parser.add_argument("--lion_lr_scale", type=float, default=0.1,
    help="Lion LR = AdamW LR × this scale. Paper recommends 0.1-0.33.")
```

**Step 3 — Replace optimizer1 instantiation (~20 LOC conditional):**

```python
if args.use_lion_aux:
    s = args.lion_lr_scale
    optimizer1 = Lion([
        dict(params=[model.embed.weight],
             lr=0.3 * s, betas=(args.lion_beta1, args.lion_beta2),
             weight_decay=0, name="lion_embed"),
        dict(params=[model.proj.weight],
             lr=(1/320) * s, betas=(args.lion_beta1, args.lion_beta2),
             weight_decay=0, name="lion_lm_head"),
        dict(params=[p for p in model.parameters() if p.ndim < 2],
             lr=args.lr_scalars * s, betas=(args.lion_beta1, args.lion_beta2),
             weight_decay=0, name="lion_scalars")
    ])
else:
    optimizer1 = AdamW([...])  # existing code unchanged
```

**Step 4 — W&B telemetry — no changes needed:** The existing train/lr/* logging
iterates over all optimizer param groups by name; Lion groups follow the same
naming convention (lion_embed, lion_lm_head, lion_scalars) and will be logged
automatically.

**Total change: ~63 LOC. No torch.compile changes needed.**

---

### Experimental cells

Use `--wandb_group fern/lion-aux-optimizer` for all runs.

Baseline mandatory stack (do NOT change):
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine
--ema_eval_decay 0.99
```

**Cell A — control (no-op):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "fern/lion-aux-A-ctrl" \
  --wandb_group "fern/lion-aux-optimizer" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99
```
Expected: FFS_ema ≈ 2875, FFS_trainval ≈ 2925 (seed-noise attractor baseline).

**Cell B★ — primary: Lion with paper defaults (β₁=0.9, lr_scale=0.1):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "fern/lion-aux-B-b1=0.9-lrs=0.1" \
  --wandb_group "fern/lion-aux-optimizer" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --use_lion_aux --lion_beta1 0.9 --lion_beta2 0.99 --lion_lr_scale 0.1
```
Rationale: embed lr=0.03, lm_head lr≈0.000313, scalars lr=0.003. Paper β₁=0.9.

**Cell C — LLM β₁=0.99 (benchmark-tuned):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "fern/lion-aux-C-b1=0.99-lrs=0.1" \
  --wandb_group "fern/lion-aux-optimizer" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --use_lion_aux --lion_beta1 0.99 --lion_beta2 0.99 --lion_lr_scale 0.1
```
Rationale: arxiv 2509.01440v1 finds β₁=0.99 improves LLM pretraining over
β₁=0.9. Lion becomes closer to pure sign-SGD with this setting.

**Cell D — larger LR scale (lr_scale=0.3, β₁=0.9):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "fern/lion-aux-D-b1=0.9-lrs=0.3" \
  --wandb_group "fern/lion-aux-optimizer" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --use_lion_aux --lion_beta1 0.9 --lion_beta2 0.99 --lion_lr_scale 0.3
```
Rationale: embed lr=0.09, lm_head lr≈0.000938, scalars lr=0.009. Less
aggressive LR reduction — tests if 0.1× is too conservative at this batch size.

---

### Signal gates and stop conditions

**Signal gate (n=1, proceed to n=4):**
Any cell shows FFS_ema ≤ 2862 OR FFS_trainval ≤ 2912.
Merge gate (n=4): μ₄(FFS_ema) ≤ 2887.5.

**No-signal stop (close as FFS-NEG/NEUTRAL):**
All cells show FFS_ema > 2950 AND FFS_trainval > 2975.

**Small-batch divergence watchdog:**
If any cell shows loss > 4.0 at step 500, kill that arm immediately (Lion
instability at small batch). Do not extend a crashed arm.

---

### Pre-mortem

1. **Small-batch instability**: At nanoGPT's 65,536 tokens/step, Lion is in
   the borderline regime per Chen et al. ablation. If embed/scalars updates
   become too noisy, expect loss > 4.0 early. Diagnostic: check train/loss at
   step 200, 500, 1000.

2. **No second-moment adaptation**: Lion treats all parameters equally
   (constant ±LR step). The RMSNorm gains (ndim<2) are very different in
   scale from embed rows. The scalars group bundling these together with Lion
   may cause some gain parameters to over/undershoot. Diagnostic: check
   train/weight_type/* norms for scalars group.

3. **LR scale sensitivity**: The 0.1× recommendation comes from Adam-to-Lion
   transfer in the image domain. For language modeling the correct scale may
   differ. Cells B and D bracket this uncertainty.

4. **WD=0 assumption**: Current AdamW AUX has weight_decay=0 for all groups.
   Lion cells preserve this. Paper recommends WD up to 10× larger with Lion,
   but testing non-zero WD on scalars/gains may interfere with normalization
   layers. Leave WD=0 for n=1 sweep; consider WD as a follow-up only if B★
   or C show clear signal.

---

### Literature citations

- Chen, X. et al. (2023). "Symbolic Discovery of Optimization Algorithms."
  arXiv:2302.06675. Introduces Lion via evolutionary program search.
  https://arxiv.org/abs/2302.06675

- Chen, X. et al. (2024/2025). "Lion: Adversarial Distillation of Closed-Form
  Losses." arXiv:2509.01440v1. LLM pretraining benchmark; β₁=0.99 finding;
  small-batch ablation critical for this experiment.

- Bernstein, J. et al. (2018). "signSGD: Compressed Optimisation for
  Non-Convex Problems." arXiv:1802.04434. Theoretical basis for sign-based
  updates; ℓ₁/ℓ₂ geometry insight relevant to why Lion behaves differently
  from Adam in high-sparsity settings (embed lookup).
  https://arxiv.org/abs/1802.04434

---

### FFS theory

Sign-based updates on embed/lm_head provide equal gradient contribution to
rare and frequent tokens. In Adam, high-frequency tokens accumulate large
second moments and receive small updates; rare tokens receive proportionally
larger updates (second moment small, so gradient divided by ~eps). Lion
removes this asymmetry entirely. If the FFS signal is bottlenecked by
unequal adaptation across vocabulary, Lion should help.

Estimated LOC complexity: ~63 LOC (Lion class 35 + CLI flags 8 + instantiation
conditional 20). No torch.compile modifications. No new dependencies. Easily
reverted by removing `--use_lion_aux` flag.

---

---

## Hypothesis 2: schedule-free-adamw-aux

### One-sentence summary

Replace the LR-scheduled AdamW AUX optimizer with Schedule-Free AdamW for the
embed/lm_head/scalars groups, using iterate averaging instead of a cooldown
schedule, to test whether removing the AdamW-cooldown dependence on the
schedule shape improves FFS.

---

### Mechanistic motivation

The current AUX optimizer uses AdamW with an LR schedule driven by
`lr_cooldown_shape=cosine`. The AUX-side cooldown family experiments
(eps, ema_eval_decay, beta1) showed that schedule modifications to AdamW
are FFS-NEUTRAL — absorbed by the main LR decay. This suggests the AUX
optimizer is schedule-shape-agnostic in the current form.

Schedule-Free AdamW (Defazio et al. 2024) eliminates the LR schedule
entirely using Polyak-Ruppert iterate averaging:

```
y_t = (1-β₁)z_t + β₁x_t         (evaluation point, interpolation of z,x)
g_t ∈ ∂f(y_t, ζ_t)              (gradient at evaluation point)
v_t = β₂v_{t-1} + (1-β₂)g_t²   (second moment, bias-corrected)
z_{t+1} = z_t - γ·g_t/√v_t - γ·λ·y_t   (base iterate)
c_{t+1} = γ²/Σᵢγᵢ²              (averaging weight)
x_{t+1} = (1-c_{t+1})x_t + c_{t+1}z_{t+1}  (Polyak-Ruppert average)
```

Key difference from Adam: x_t is the Polyak-Ruppert average (used for
evaluation), while z_t is the base iterate (used for gradient computation).
There is no LR schedule — γ is constant throughout, with only warmup.

Validation: Defazio et al. directly benchmark on NanoGPT 124M / OpenWebText
and find β=0.98 optimal. This is the closest possible analogous setting to
our benchmark.

Why this helps if it works: The current AUX optimizer's cooldown is inherited
from the Muon cooldown schedule (same `set_hparams` call). Schedule-Free AUX
would decouple the AUX parameters from the Muon LR decay entirely — they
would follow their own averaging trajectory. This may be better if the optimal
step size for embed updates during cooldown differs from what the cosine
schedule provides.

Important: `.train()` and `.eval()` mode switching in Schedule-Free is needed
for BatchNorm (swap x_t ↔ z_t). NanoGPT uses RMSNorm, NOT BatchNorm. The
mode-switching concern is reduced but should still be implemented for
correctness — use `.train()` before each forward pass and `.eval()` for
validation evaluations.

---

### Prior work review confirming this axis is open

Schedule-Free AdamW is not mentioned in any closed or open R5 experiment, PR
body, comment, or research note. The AUX-side cooldown family closed only
schedule parameter modifications (eps, beta1, ema_eval_decay) on vanilla
AdamW — not algorithm replacement.

Defazio et al. (2024) won the MLCommons 2024 AlgoPerf Self-Tuning track. Their
NanoGPT 124M benchmark is directly applicable. No prior R5 run has tested this.

---

### Implementation plan

**Step 1 — Add ScheduleFreeAdamW class (~30 LOC):**

```python
class ScheduleFreeAdamW(torch.optim.Optimizer):
    """Schedule-Free AdamW. Defazio et al. 2024 (arXiv:2405.15682).
    Use .train() before forward pass; .eval() for evaluation."""
    def __init__(self, params, lr=1e-3, betas=(0.98, 0.999), eps=1e-8,
                 weight_decay=0.0, warmup_steps=0):
        defaults = dict(lr=lr, betas=betas, eps=eps,
                        weight_decay=weight_decay, warmup_steps=warmup_steps)
        super().__init__(params, defaults)

    @torch.no_grad()
    def step(self):
        for group in self.param_groups:
            beta1, beta2 = group['betas']
            lr = group['lr']
            for p in group['params']:
                if p.grad is None:
                    continue
                grad = p.grad
                state = self.state[p]
                if len(state) == 0:
                    state['step'] = 0
                    state['z'] = p.data.clone()    # base iterate
                    state['x'] = p.data.clone()    # averaged iterate
                    state['v'] = torch.zeros_like(p)  # second moment
                    state['gamma_sq_sum'] = 0.0
                state['step'] += 1
                t = state['step']
                ws = group['warmup_steps']
                gamma = lr * min(1.0, t / max(1, ws))

                z, x, v = state['z'], state['x'], state['v']
                # second moment update (use grad at y_t = interpolated point)
                v.mul_(beta2).addcmul_(grad, grad, value=1 - beta2)
                v_hat = v / (1 - beta2 ** t)
                # WD applied to y_t (interpolated), not z
                y = (1 - beta1) * z + beta1 * x
                z.addcmul_(grad, 1.0 / (v_hat.sqrt() + group['eps']),
                           value=-gamma)
                if group['weight_decay'] > 0:
                    z.add_(y, alpha=-gamma * group['weight_decay'])
                # Polyak-Ruppert averaging
                state['gamma_sq_sum'] += gamma ** 2
                c = gamma ** 2 / state['gamma_sq_sum']
                x.mul_(1 - c).add_(z, alpha=c)
                # p holds x (evaluation iterate)
                p.data.copy_(x)

    def train(self):
        """Switch to z iterate for gradient computation."""
        for group in self.param_groups:
            for p in group['params']:
                if p in self.state and 'z' in self.state[p]:
                    p.data.copy_(self.state[p]['z'])

    def eval(self):
        """Switch to x iterate (averaged) for evaluation."""
        for group in self.param_groups:
            for p in group['params']:
                if p in self.state and 'x' in self.state[p]:
                    p.data.copy_(self.state[p]['x'])
```

**Step 2 — Add CLI flags (~5 LOC):**

```python
parser.add_argument("--use_sf_adamw_aux", action="store_true", default=False,
    help="Replace AdamW with Schedule-Free AdamW for AUX groups.")
parser.add_argument("--sf_beta1", type=float, default=0.98,
    help="SF-AdamW β₁ (Polyak averaging weight). NanoGPT optimal=0.98.")
parser.add_argument("--sf_warmup_steps", type=int, default=300,
    help="SF-AdamW warmup steps (default=300, ~9% of 3250 total).")
```

**Step 3 — Replace optimizer1 instantiation (~12 LOC conditional).**

**Step 4 — Call .train()/.eval() at appropriate points (~4 LOC):**
Before each forward pass: `optimizer1.train()` if `args.use_sf_adamw_aux`.
Before each validation eval: `optimizer1.eval()` if `args.use_sf_adamw_aux`.

**Total change: ~51 LOC. No torch.compile changes needed.**

---

### Experimental cells

Use `--wandb_group fern/schedule-free-adamw-aux` for all runs.

Baseline mandatory stack (do NOT change):
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine
--ema_eval_decay 0.99
```

**Cell A — control (no-op):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "fern/sf-adamw-A-ctrl" \
  --wandb_group "fern/schedule-free-adamw-aux" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99
```

**Cell B★ — primary: SF-AdamW β₁=0.98, same LR as current AdamW:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "fern/sf-adamw-B-b1=0.98" \
  --wandb_group "fern/schedule-free-adamw-aux" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --use_sf_adamw_aux --sf_beta1 0.98
```
Rationale: β=0.98 is the NanoGPT 124M optimal value per Defazio et al.
LR kept same as current AdamW — paper finds SF optimal LR is larger than
scheduled AdamW optimal, but starting at current LR is a safe baseline.

**Cell C — β₁=0.95:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "fern/sf-adamw-C-b1=0.95" \
  --wandb_group "fern/schedule-free-adamw-aux" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --use_sf_adamw_aux --sf_beta1 0.95
```
Rationale: less aggressive averaging weight; discriminates β sensitivity.

**Cell D — β₁=0.98 + LR×0.5 (explore LR sensitivity):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "fern/sf-adamw-D-b1=0.98-halfLR" \
  --wandb_group "fern/schedule-free-adamw-aux" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.015 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --use_sf_adamw_aux --sf_beta1 0.98
```
Note: embed lr=0.15, lm_head lr=1/640, scalars lr=0.015 (via lr_scalars flag).

---

### Signal gates and stop conditions

**Signal gate (n=1, proceed to n=4):**
Any cell shows FFS_ema ≤ 2862 OR FFS_trainval ≤ 2912.

**No-signal stop (close as FFS-NEG/NEUTRAL):**
All cells show FFS_ema > 2950 AND FFS_trainval > 2975, consistent with
AUX-side family pattern (absorbed by LR decay).

---

### Pre-mortem

1. **AUX optimizer change absorbed by Muon**: If Muon is the primary driver
   of FFS and AUX contributes only noise, replacing AdamW with Schedule-Free
   AdamW has no effect. This is the null hypothesis. The AUX-side cooldown
   family supports this concern, but algorithm replacement is structurally
   different from schedule modification.

2. **Iterate averaging adds stale-gradient bias**: The SF averaging uses x_t
   (averaged iterate) as evaluation point but z_t (current) for gradient
   computation. If the gap between x_t and z_t grows large (high LR, small
   warmup), gradients may be computed at a misleading point. Diagnostic:
   monitor train/loss at steps 100-500 for instability.

3. **Mode-switch implementation risk**: If `.train()`/`.eval()` calls are
   missed or called at wrong times (e.g., inside gradient accumulation),
   parameters will be at the wrong iterate during the forward pass. This is
   the primary implementation risk. Careful placement around validation
   evaluations is critical.

---

### Literature citations

- Defazio, A. et al. (2024). "The Road Less Scheduled." arXiv:2405.15682.
  Introduces Schedule-Free AdamW; validates on NanoGPT 124M; β=0.98 optimal;
  won MLCommons 2024 AlgoPerf Self-Tuning track.
  https://arxiv.org/abs/2405.15682

- Polyak, B.T., Juditsky, A.B. (1992). "Acceleration of stochastic
  approximation by averaging." SIAM Journal on Control and Optimization.
  Theoretical foundation for Polyak-Ruppert iterate averaging.

---

### FFS theory

If the AUX groups would benefit from more aggressive averaging (smoother
final parameters), SF-AdamW provides this without requiring a schedule.
The key question is whether the AUX groups are schedule-limited (their
final-step quality is constrained by what the cosine schedule can achieve)
or are irrelevant to FFS. The AUX-side cooldown family result weakly
suggests the latter, making this hypothesis medium-confidence.

Estimated LOC complexity: ~51 LOC. No torch.compile modifications.

---

---

## Hypothesis 3: adafactor-aux

### One-sentence summary

Replace AdamW with Adafactor for the embed.weight and lm_head.weight groups
(row/column factored second moment; memory-efficient) to test whether
factored variance estimation improves FFS for the high-dimensional embedding
and output projection parameters.

---

### Mechanistic motivation

Adafactor (Shazeer & Stern 2018) replaces Adam's per-element second moment
with factored row/column statistics:

```
V_t = R_t ⊗ C_t / (R_t 1 C_t^T)   (outer product rank-1 approximation)
R_t[i] = ρ_t R_{t-1}[i] + (1-ρ_t) Σ_j (G_t²[i,j])  (row factor)
C_t[j] = ρ_t C_{t-1}[j] + (1-ρ_t) Σ_i (G_t²[i,j])  (col factor)
```

For embed.weight (50,257×768), Adam stores 50,257×768=38.6M second moments;
Adafactor stores only 50,257+768=51,025 values (~0.13%). The factored estimate
captures the row-wise (per-token) and column-wise (per-dimension) variance
structure separately.

The inductive bias: row factor captures per-token gradient variance (some
tokens more noisy than others); column factor captures per-dimension variance
(some embedding dimensions more active than others). This factored structure
matches the natural sparsity of embedding lookups — each forward pass
activates a different subset of rows.

Relevance to R5: embed.weight is the largest AUX parameter (38.6M) and
also the most structured in terms of row-wise sparsity. If Adam's per-element
second moment is "overfitting" to token-wise gradient history, Adafactor's
rank-1 factorization may provide better generalization of the variance signal.

Note: Adafactor is primarily motivated by memory efficiency (relevant for
large T5-scale models). For 124M nanoGPT, memory savings are not the goal —
the hypothesis is that factored variance estimation is a better inductive
bias for sparse embedding updates than per-element tracking.

---

### Prior work review confirming this axis is open

Adafactor is not mentioned in any R5 experiment, PR, or research note. The
AUX optimizer axis is completely untouched by all R5 closed experiments.

---

### Implementation plan

**Step 1 — Add Adafactor class (~50 LOC) using standard factored form:**

See Shazeer & Stern (2018) Algorithm 1. Key implementation notes:
- Use `factored=True` for 2D params (embed, lm_head); `factored=False` for
  1D params (scalars, biases, gains).
- Clipping: apply RMS clipping with `d_hat = max(RMS(U_t), 1)` to stabilize
  large-step updates. This is load-bearing in the original paper.
- No β₁ (first moment): Adafactor uses only second moment + optional clipping.
- LR: Adafactor can use relative step size (1/√t) or fixed. Use fixed LR
  matching current AdamW values for fair comparison.

**Total estimated change: ~65 LOC. No torch.compile changes needed.**

---

### Experimental cells

Use `--wandb_group fern/adafactor-aux` for all runs.

Baseline mandatory stack: same as Hypotheses 1 and 2.

**Cell A — control (no-op)**: standard baseline.

**Cell B★ — primary: Adafactor for embed+lm_head, AdamW for scalars:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "fern/adafactor-B-embed-lmhead" \
  --wandb_group "fern/adafactor-aux" \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --use_adafactor_aux --adafactor_groups embed_lmhead
```

**Cell C — Adafactor for all AUX groups (including scalars):**
Same but `--adafactor_groups all`.

**Cell D — Adafactor embed+lmhead + LR×0.5:**
Tests if current LR is too large for Adafactor (paper uses relative step
which is typically smaller).

---

### Signal gates

Same FFS_ema ≤ 2862 gate as Hypotheses 1 and 2.

---

### Pre-mortem

1. **Memory efficiency motivation absent at 124M scale**: Adafactor was
   designed for T5-class 10B+ models. At 124M, the factored approximation
   trades away accuracy for memory savings that are not needed. The factored
   variance estimate may be systematically worse than per-element tracking.
2. **Clipping implementation sensitivity**: The RMS clipping threshold is
   critical and easy to mis-implement. A wrong `d_hat` can cause slow
   convergence that looks like a fundamental algorithm failure.

---

### Literature citations

- Shazeer, N., Stern, M. (2018). "Adafactor: Adaptive Learning Rates with
  Sublinear Memory Cost." arXiv:1801.04014. ICML 2018.
  https://arxiv.org/abs/1801.04014

---

### FFS theory

Factored second moment may better capture the row-wise (per-token) sparsity
of embedding gradient updates. Confidence: low. The strongest argument is
"untested axis, small LOC cost, well-understood algorithm."

Estimated LOC complexity: ~65 LOC.

---

---

## Research state summary

### Current bottleneck

After 91 R5 experiments, the primary signal frontier is:
- Muon body optimizer: frieren #1966 (n=4 in-flight, mu-ramp confirmed
  off-attractor at n=1 with {FFS_ema=2875, FFS_trainval=2875})
- AUX optimizer algorithm: COMPLETELY UNTESTED across all 91 experiments

### Ruled-out paths

- Additive pre-NS5 gradient modifiers (4 members): FFS-NEUTRAL
- AUX-side schedule modifications (eps, beta1, ema_eval_decay): FFS-NEUTRAL
- LN gain init < 1.0: FFS-NEG
- NS5-absorption family (2D weight init, post-NS5 LR scaling): FFS-NEUTRAL

### Open uncertainty: AUX optimizer algorithm

The AUX optimizer (AdamW) has been tuned in schedule shape and hyperparameters
but NEVER replaced with a different algorithm. Three candidate algorithms
(Lion, SF-AdamW, Adafactor) address different aspects of the AUX update:
- Lion: sign-quantized update, memory-efficient, equal step sizes across vocab
- SF-AdamW: iterate averaging, decoupled from LR schedule
- Adafactor: factored second moment, row-wise variance for embed sparsity

### Priority for fern assignment

Hypothesis 1 (lion-aux-optimizer) is recommended as fern's next assignment.
Justification: Lion is the most mechanistically distinct from existing AdamW
(different update geometry, not just schedule), has the best external evidence
(direct LLM pretraining benchmarks), and the small-batch risk is testable in
n=1 screening with a simple watchdog gate. If it fails with divergence, that
is informative and rules out a full family. If it succeeds, sign-based updates
on the vocabulary parameters would be a new compounding mechanism.
