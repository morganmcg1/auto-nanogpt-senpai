# SENPAI Research Ideas — 2026-05-19 18:30 UTC

Generated for: auto-nanogpt-1gpu-r3
Baseline: val=3.27119, ffs=3100 (post-PR #443, Aux AdamW eps=1e-6)
Noise floor: σ≈0.0012 (n=5 ctrl samples). n=1 merge bar: val < 3.27039 (Δ ≤ −0.0008).
Required flags on ALL new commands:
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --muonh_cooldown_shape cosine --muonh_warmup_steps 100 --aux_adamw_eps 1e-6

NOT in-flight (active arms all cover scalar HP sweeps on eps=1e-6 baseline):
  #471 n=4 eps confirm, #478 embed LR, #475 scalars LR, #481 lm_head LR, #484 cooldown_frac

---

## Hypothesis 1: Per-group eps decomposition (embed vs lm_head vs scalars)

**Mechanism**: The eps=1e-6 win may be concentrated in one param group. Aux AdamW uses a single
shared `eps` argument for all three groups (embed lr=0.3, lm_head lr=1/320, scalars lr=0.01).
Split into three independent argparse flags; sweep each while holding the others at the old
eps=1e-10, one group at a time.

**Theory**: Different groups have very different weight norms, gradient variances, and update
scales. The optimal eps for the embed (large weights, large gradients) need not match the optimal
eps for RMSNorm gains (tiny scalars). Finding which group drives the win narrows future eps tuning
and may reveal further improvement by pushing the winning group below 1e-6 or holding losers
higher.

**Expected delta**: If one group dominates, isolating it may recover ~80% of the eps win
(−0.00130 est.) vs the full −0.00167. Combining two optimised groups could exceed the current win.

**Implementation footprint (~18 lines)**:
```python
# argparse additions:
parser.add_argument("--aux_embed_eps",    type=float, default=None)
parser.add_argument("--aux_lm_head_eps",  type=float, default=None)
parser.add_argument("--aux_scalars_eps",  type=float, default=None)

# in optimizer setup, replace single eps with per-group fallback:
embed_eps    = args.aux_embed_eps   or args.aux_adamw_eps
lm_head_eps  = args.aux_lm_head_eps or args.aux_adamw_eps
scalars_eps  = args.aux_scalars_eps or args.aux_adamw_eps

optimizer1 = AdamW([
    dict(params=[model.embed.weight], lr=0.3,   eps=embed_eps,   name="adam_embed"),
    dict(params=[model.proj.weight],  lr=1/320, eps=lm_head_eps, name="adam_lm_head"),
    dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.01, eps=scalars_eps, name="adam_scalars"),
], betas=(0.8, 0.95), weight_decay=0, fused=True)
```

**3-arm screening plan**:
- Arm 1 (ctrl): all three groups eps=1e-6 (baseline, verifies split is neutral)
- Arm 2: embed eps=1e-10, lm_head eps=1e-6, scalars eps=1e-6 (test: embed NOT responsible)
- Arm 3: embed eps=1e-6, lm_head eps=1e-10, scalars eps=1e-10 (test: embed IS the source)
- Chain arm 4 if arm 3 wins: push embed eps to 1e-7 or 1e-5 to verify direction.

**Risk**: Low. Pure decomposition. Worst case confirms the shared win is uniformly distributed.

---

## Hypothesis 2: Lookahead wrapper on Aux AdamW (not on MuonH)

**Mechanism**: Lookahead maintains a slow weight copy updated as θ_slow += α(θ_fast − θ_slow)
every k fast steps. Applied to Aux AdamW only (embed, lm_head, scalars), it adds a second
smoothing stage on top of the existing momentum without altering the MuonH-managed block weights.

**Theory**: The eps=1e-6 win suggests Aux AdamW updates were previously noisy. Lookahead further
reduces variance in the slow weights by averaging across k fast steps, effectively giving a
low-pass filter on the optimisation trajectory. This is complementary to lower eps (signal
preservation). With α=0.5 and k=5, Lookahead has historically recovered 10–30% of remaining
loss in settings where the inner optimizer is already well-tuned.

**Expected delta**: Speculative; analogous results in transformer finetuning suggest Δ ≈ −0.001
to −0.002. Wider confidence interval than per-group eps.

**Implementation footprint (~25 lines)**:
```python
class LookaheadAux:
    def __init__(self, base_optimizer, alpha=0.5, k=5):
        self.base = base_optimizer
        self.alpha = alpha; self.k = k; self.step_count = 0
        self.slow = {id(p): p.detach().clone()
                     for group in base_optimizer.param_groups
                     for p in group['params']}
    def step(self):
        self.base.step()
        self.step_count += 1
        if self.step_count % self.k == 0:
            for group in self.base.param_groups:
                for p in group['params']:
                    slow = self.slow[id(p)]
                    slow.add_(p.detach() - slow, alpha=self.alpha)
                    p.data.copy_(slow)
    def zero_grad(self): self.base.zero_grad()
    @property
    def param_groups(self): return self.base.param_groups
    def state_dict(self): return self.base.state_dict()
    def load_state_dict(self, d): self.base.load_state_dict(d)
```
Wrap: `optimizer1 = LookaheadAux(optimizer1, alpha=args.la_alpha, k=args.la_k)`

**3-arm screening plan**:
- Arm 1 (ctrl): standard AdamW eps=1e-6, no Lookahead
- Arm 2: Lookahead α=0.5, k=5 (canonical Zhang et al. 2019 defaults)
- Arm 3: Lookahead α=0.5, k=10 (less interference with cooldown)

**Risk**: Medium. Must verify MuLoCo outer sync still works correctly with the slow weight
interpolation — both outer anchor and Lookahead slow weights will diverge. If interaction causes
instability, disable Lookahead during cooldown.

---

## Hypothesis 3: Stochastic Weight Averaging (SWA) in last 10% of training

**Mechanism**: After step (1 − cooldown_frac) × train_steps, begin averaging current weights
into a running SWA model. At the end of training, evaluate using the averaged weights rather than
the terminal fast weights. MuLoCo already does outer averaging but at a coarser timescale; SWA
operates at a finer grain during the tail.

**Theory**: The current cooldown is a scheduled LR decay. SWA replaces or augments this by
explicitly seeking a flat loss basin centre rather than following gradient descent to a narrow
minimum. Flatter minima generalise better on validation, and the fixed 10%-tail window avoids
interfering with the main training phase.

**Expected delta**: Izmailov et al. (2018) report consistent 0.1–0.4% test error reductions.
In step-count terms, a 0.001 val loss improvement seems plausible. Δ ≈ −0.001 to −0.003.

**Implementation footprint (~20 lines)**:
```python
parser.add_argument("--swa_frac", type=float, default=0.0)
# ... after main loop:
swa_weights = None; swa_count = 0
if step >= (1 - args.swa_frac) * train_steps and args.swa_frac > 0:
    if swa_weights is None:
        swa_weights = {n: p.detach().clone() for n, p in model.named_parameters()}
    else:
        for n, p in model.named_parameters():
            swa_weights[n].mul_(swa_count / (swa_count + 1)).add_(p.detach() / (swa_count + 1))
    swa_count += 1
# At final val eval, load swa_weights into model if swa_count > 0
```

**3-arm screening plan**:
- Arm 1 (ctrl): swa_frac=0.0 (no SWA)
- Arm 2: swa_frac=0.10 (average last 10% of steps, ~330 steps at 3325 total)
- Arm 3: swa_frac=0.20 (average last 20%, overlaps with existing cooldown)

**Risk**: Low-medium. No interaction with optimizer state. Key unknown: does SWA-averaged model
need BN renorm? (No BN here — safe.) Does MuLoCo outer anchor interfere? (Separate state — likely
fine.)

---

## Hypothesis 4: Aux AdamW Nesterov momentum (use_nesterov=True for all param groups)

**Mechanism**: Nesterov accelerated gradient (NAG) evaluates the gradient at the lookahead
position θ − β·v rather than the current position. In AdamW, this means using the gradient
computed with momentum-extrapolated weights before accumulating. PyTorch's AdamW does not natively
expose `nesterov=True`, but the modification is a one-line second-moment denominator swap.

**Theory**: MuonH inner optimizer and the MuLoCo outer optimizer both already use Nesterov-style
updates for the matrix weights. Making Aux AdamW also Nesterov creates consistency across the
full optimizer stack. Nesterov momentum is empirically faster than standard momentum in convex
settings and often in deep learning. Given the embed (1 large matrix) and lm_head are the dominant
non-MuonH weights, this is the highest-impact site.

**Expected delta**: Δ ≈ −0.001 to −0.002. Uncertainty high — results from Muon-related contexts
suggest Nesterov helps, but Aux AdamW is a quite different regime.

**Implementation footprint (~15 lines)**:
```python
# Custom NAG-AdamW step — replace fused=True with manual loop:
def nag_adamw_step(optimizer):
    for group in optimizer.param_groups:
        beta1, beta2 = group['betas']
        eps, lr = group['eps'], group['lr']
        for p in group['params']:
            if p.grad is None: continue
            state = optimizer.state[p]
            # Nesterov: extrapolate exp_avg by beta1 before applying grad
            exp_avg = state['exp_avg']
            grad = p.grad + beta1 * exp_avg  # lookahead grad
            # ... standard AdamW update with lookahead grad
```
Alternatively: add `--aux_nesterov` flag; if set, wrap AdamW with a thin class that pre-adds
beta1*momentum before each step (clean ~18 lines).

**3-arm screening plan**:
- Arm 1 (ctrl): standard AdamW, no Nesterov
- Arm 2: NAG-AdamW, Nesterov applied to all three param groups
- Arm 3: NAG-AdamW embed+lm_head only (scalars excluded — they are tiny)

**Risk**: Medium. PyTorch fused AdamW cannot be used with custom Nesterov; must fall back to
unfused loop (mild throughput cost ~2%). Test correctness by comparing step 1 update norms
against ctrl.

---

## Hypothesis 5: Embedding init scale sweep (std multiplier on embed.weight)

**Mechanism**: Current embed init is `w.normal_()` (std=1.0, mean=0). This is unusually large —
standard GPT-2-style embeddings use std=0.02. The embed is then normalised by RMSNorm before
entering the blocks, which will rescale it; however, the *relative* scale between embedding
table entries affects the Adam effective step size through the second moment estimate. Given eps
just moved to 1e-6, the interaction with embed norm may have shifted.

**Theory**: Very large initial embedding norms inflate the second moment early in training, causing
Adam to take smaller effective steps through the entire warmup phase. Reducing std from 1.0 toward
0.02–0.1 may speed early learning on the embedding. This is a direct test of whether the embed
init was accidentally compensating for eps=1e-10 (which inflates denominator and tolerates large
norms), and whether eps=1e-6 has made this sub-optimal.

**Expected delta**: Δ ≈ −0.001 to −0.004 (high uncertainty). If std=1.0 was previously masked
by eps bias, this could be material.

**Implementation footprint (~3 lines)**:
```python
parser.add_argument("--embed_init_std", type=float, default=1.0)
# in init block:
elif name == "embed.weight": w.normal_(std=args.embed_init_std)
```

**3-arm screening plan**:
- Arm 1 (ctrl): std=1.0 (current default)
- Arm 2: std=0.1 (10x smaller, still larger than GPT-2 style)
- Arm 3: std=0.02 (GPT-2 style canonical)

**Risk**: Low. Pure init change, no optimizer code touch. Divergence risk is real if std too
small causes very slow early learning — watch val at step ~500 for early kill signal.

---

## Hypothesis 6: Decoupled second-moment reset at cooldown onset (Adam warm restart)

**Mechanism**: At the step where cooldown begins (step = (1 − cooldown_frac) × train_steps),
reset exp_avg_sq (second moment buffer) in Aux AdamW to its current running values divided by a
factor (partial reset), effectively re-estimating variance with more weight on recent gradients.
This is an Adam analogue of the SGDR cosine restart idea — at cooldown onset, the gradient
landscape has shifted; stale second moments over-dampen updates precisely when we need them most.

**Theory**: The second moment in Adam integrates gradient history over the full training run. By
cooldown (last 40%), the embedding distribution has substantially shifted from its initialisation.
A partial second-moment reset (factor 0.5–0.9 reduction) allows Adam to increase step size just
as LR is being reduced, potentially sustaining useful gradient signal later in training than the
current schedule allows. This mechanism is distinct from LR scheduling.

**Expected delta**: Δ ≈ −0.001 to −0.003. Speculative — no direct prior in this stack, but
strong theoretical motivation given the long cooldown fraction.

**Implementation footprint (~12 lines)**:
```python
parser.add_argument("--aux_v_reset_frac", type=float, default=1.0)
# in set_hparams or training loop at cooldown start:
if step == cooldown_start and args.aux_v_reset_frac < 1.0:
    for group in optimizer1.param_groups:
        for p in group['params']:
            if p in optimizer1.state:
                optimizer1.state[p]['exp_avg_sq'].mul_(args.aux_v_reset_frac)
                optimizer1.state[p]['step'] = torch.tensor(1, dtype=torch.float)
```

**3-arm screening plan**:
- Arm 1 (ctrl): aux_v_reset_frac=1.0 (no reset)
- Arm 2: aux_v_reset_frac=0.5 (halve second moment at cooldown start)
- Arm 3: aux_v_reset_frac=0.1 (near-full reset — aggressive)

**Risk**: Medium. The step counter reset (`step=1`) is important: without it, bias correction
keeps effective lr suppressed even after the v reset. Verify effective lr spike is bounded by AGC.

---

## Hypothesis 7: Per-group Aux AdamW weight decay (currently all WD=0)

**Mechanism**: Currently all three Aux AdamW groups use weight_decay=0. The embed and lm_head
are large matrices that benefit from implicit regularisation from Muon's orthogonal updates —
but embed and proj are NOT in the MuonH group, so they have no such regularisation. Introducing
small non-zero WD specifically for embed (0.01–0.1) may tighten the validation loss by reducing
memorisation in the embedding table.

**Theory**: Embedding tables are known to overfit in language models, and the current softsign
logit cap only acts at the output. Weight decay on embed acts as a Gaussian prior on embedding
norms, compatible with the RMSNorm that follows. lm_head (zero init) is more sensitive; WD there
may hurt early learning but help late. Scalars (gains/biases) should stay at WD=0 (well-known
best practice).

**Expected delta**: Δ ≈ −0.001 to −0.002. Low confidence; WD at 0 may already be optimal.

**Implementation footprint (~5 lines)**:
```python
parser.add_argument("--aux_embed_wd", type=float, default=0.0)
parser.add_argument("--aux_lm_head_wd", type=float, default=0.0)
# Change optimizer1 group dicts to use these values instead of weight_decay=0
```

**3-arm screening plan**:
- Arm 1 (ctrl): embed_wd=0, lm_head_wd=0 (current baseline)
- Arm 2: embed_wd=0.01, lm_head_wd=0 (embed-only regularisation)
- Arm 3: embed_wd=0.1, lm_head_wd=0 (stronger embed regularisation)

**Risk**: Low. WD is a well-understood lever. Decouple correctly from AdamW's fused kernel if
fused=True doesn't respect per-group WD (verify in PyTorch docs; it should since PyTorch 2.0).

---

## Hypothesis 8: AdaBelief as Aux AdamW replacement (gradient belief signal)

**Mechanism**: AdaBelief adapts the learning rate based on the "belief" in the gradient direction
— it uses (grad − exp_avg)^2 as the denominator rather than grad^2. This means: when the gradient
aligns with the running mean (high confidence), it takes larger steps; when they disagree (noisy
gradient), it shrinks the step. Drop-in replacement for AdamW in the Aux group.

**Theory**: With eps=1e-6 (cleaner signal than 1e-10), AdaBelief's denominator (grad - EMA)^2 is
no longer swamped by eps. The eps win may indicate the model has stabilised into a regime where
the gradient signal is more reliable, making AdaBelief's variance-of-gradient denominator more
accurate. Reported wins of 0.5–2% in training loss vs Adam in several transformer benchmarks.

**Expected delta**: Δ ≈ −0.001 to −0.003 if gradient direction is stable; could hurt if
gradients are inherently noisy for embed/lm_head.

**Implementation footprint (~30 lines)**:
```python
class AdaBelief(torch.optim.Optimizer):
    def __init__(self, params, lr, betas, eps, weight_decay=0):
        defaults = dict(lr=lr, betas=betas, eps=eps, weight_decay=weight_decay)
        super().__init__(params, defaults)
    def step(self):
        for group in self.param_groups:
            b1, b2 = group['betas']
            for p in group['params']:
                if p.grad is None: continue
                g = p.grad
                state = self.state[p]
                if 'step' not in state:
                    state.update({'step': 0, 'exp_avg': torch.zeros_like(p),
                                  'exp_avg_var': torch.zeros_like(p)})
                state['step'] += 1
                m, v = state['exp_avg'], state['exp_avg_var']
                m.mul_(b1).add_(g, alpha=1-b1)
                v.mul_(b2).addcmul_(g - m, g - m, value=1-b2).add_(group['eps'])
                bc1 = 1 - b1**state['step']; bc2 = 1 - b2**state['step']
                step_size = group['lr'] * (bc2**0.5) / bc1
                p.addcdiv_(m, v.sqrt() + group['eps'], value=-step_size)
                if group['weight_decay']: p.mul_(1 - group['lr']*group['weight_decay'])
```

**3-arm screening plan**:
- Arm 1 (ctrl): standard AdamW eps=1e-6, betas=(0.8, 0.95) — establishes per-student baseline
- Arm 2: AdaBelief eps=1e-6, betas=(0.8, 0.95) — exact drop-in
- Arm 3: AdaBelief eps=1e-8, betas=(0.9, 0.99) — canonical AdaBelief paper defaults

**Risk**: Medium-high. AdaBelief cannot use fused=True (custom kernel required). Unfused loop is
~3–5% slower per step. Must implement AGC wrapper around AdaBelief separately (current AGC hooks
into AdamW param groups directly — verify compatibility). No third-party package allowed; full
implementation must be in-script.

---

## Priority ordering

1. **H1 (per-group eps)** — highest confidence, directly tests mechanism behind existing win,
   ≤18 lines, clean falsification. Score: mechanistic 4/4, info 4/4, cost 4/4.

2. **H5 (embed init std)** — 3 lines, tests whether std=1.0 was compensating for eps=1e-10 bias.
   Direct interaction with the eps win hypothesis. Score: 3/3/4.

3. **H6 (second-moment reset at cooldown)** — novel, targets the cooling phase gap, 12 lines.
   Score: 3/4/3.

4. **H4 (Nesterov on Aux AdamW)** — aligns optimizer philosophy across stack, 18 lines.
   Score: 3/3/3.

5. **H7 (per-group WD)** — low risk, 5 lines, tests unregularised embed. Score: 2/3/4.

6. **H2 (Lookahead on Aux)** — more speculative, interaction with MuLoCo to verify. Score: 2/3/3.

7. **H3 (SWA tail averaging)** — well-motivated but adds eval complexity. Score: 3/3/2.

8. **H8 (AdaBelief)** — interesting mechanism but highest implementation risk (fused loss, AGC
   compat). Run only after H1–H4 settled. Score: 2/3/2.
