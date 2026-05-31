# Hypothesis: AdamW Epsilon Cooldown Schedule for FFS Plateau Breaking

**Date:** 2026-05-31
**Student:** g1r5-nezuko
**Research mode:** Frontier refinement — schedule-side lever, pure numerical change to AdamW denominator damping
**Novelty:** Confirmed — "epsilon" does not appear in any of the 78 closed R5 PR titles or descriptions

---

## One-Sentence Hypothesis

Linearly decay AdamW's denominator stabilizer (ε) from its default value (1e-8) toward a near-zero floor (1e-12 or 1e-15) during the cooldown phase so that the optimizer extracts more curvature signal from the second-moment estimate precisely during the FFS crossing window (steps ~2800–3050).

---

## Mechanism Prediction (specific and falsifiable)

In the AdamW parameter update:

    θ_t ← θ_t-1 - α_t * m̂_t / (v̂_t^0.5 + ε)

ε prevents division by near-zero second moments. During **cooldown** (steps ~2800–3250):

1. v̂_t has been accumulating for ~2800 steps and is well-estimated — the denominator has stabilized and ε is no longer needed for numerical safety.
2. The model sits in the 3.30–3.32 val/loss range where small curvature differences matter: parameters with very small v̂_t get strongly amplified updates when ε is reduced, enabling finer-grained tuning of low-gradient-variance directions.
3. Decaying ε in log-space from 1e-8 to 1e-12 over the cooldown window allows AdamW to act more like a true second-moment-normalized update without disturbing the main training phase.

Expected: FFS_ema decreases 20–60 steps (from 2912.5 toward 2875). No degradation in main phase (ε unchanged before cooldown start).

Falsifier: If val/loss curves in cooldown are identical to control across all seeds and FFS_ema > 2975, the mechanism is inert — cooldown ε decay does not meaningfully change AdamW step geometry in this setting.

Known risk: Must apply ε decay ONLY to optimizer groups that have an `"eps"` key (AdamW groups). The `"eps" in group` guard skips Muon groups (which use NS5, not AdamW ε) and only touches scalar/embedding/attention AdamW groups.

---

## Lit-Search Grounding (2 references)

**FAdam** (Hwang 2024; arxiv 2405.12807): Establishes that fixed ε is theoretically suboptimal from a Fisher-information-geometry perspective; proposes "adaptive epsilon" as a principled correction to Adam, motivated by diagonal empirical Fisher information; shows improved perplexity in LLM pre-training, lower WER in ASR, and better reconstruction in VQ-VAE.
URL: https://arxiv.org/abs/2405.12807

**Cooldown theory** (Schaipp et al. 2025; arxiv 2501.18965): Shows cooldown phase updates are qualitatively different from main-phase updates and that denominator terms (second-moment estimates) matter disproportionately at low learning rate; supports the hypothesis that modifying ε specifically in cooldown targets the right window.
URL: https://arxiv.org/abs/2501.18965

---

## Implementation Sketch (~25 LOC)

**File:** `records/track_3_optimization/train_gpt_simple.py`

**Step 1 — argparse (add after `--ema_eval_decay` argument):**
```python
parser.add_argument("--eps_cooldown_end", type=float, default=1e-8,
                    help="AdamW epsilon at end of cooldown. Default 1e-8 (no schedule). "
                         "Values like 1e-12 or 1e-15 test the epsilon-cooldown mechanism.")
parser.add_argument("--eps_cooldown_start_step", type=int, default=-1,
                    help="Step at which to begin epsilon decay. -1 = auto (uses cooldown_start_step).")
```

**Step 2 — in the per-step hyperparameter update block (same region as LR/WD cooldown scheduling), add after existing cooldown lr/wd updates:**
```python
if args.eps_cooldown_end < 1e-8:
    eps_start_step = args.eps_cooldown_start_step if args.eps_cooldown_start_step > 0 else cooldown_start
    if step >= eps_start_step:
        frac = (step - eps_start_step) / max(1, total_steps - eps_start_step)
        frac = min(frac, 1.0)
        log_eps = math.log(1e-8) + frac * (math.log(args.eps_cooldown_end) - math.log(1e-8))
        current_eps = math.exp(log_eps)
        for group in optimizer.param_groups:
            if "eps" in group:
                group["eps"] = current_eps
```

**Note on `"eps" in group` guard:** Muon optimizer groups do not have an `"eps"` key. This guard ensures that only AdamW-based parameter groups (scalars, layer norm, embeddings, and SOAP-preconditioned attention) receive the schedule. Muon groups are unaffected.

**Requires `import math`** — likely already present; confirm before submitting.

Total delta: ~18 LOC. No new dependencies.

---

## Cells Matrix

| Cell | `--eps_cooldown_end` | n | Role | Expected FFS_ema |
|------|---------------------|---|------|-----------------|
| A | 1e-8 (default, no schedule) | 4 | CTRL | ~2912.5 (σ≈25) |
| B★ | 1e-12 | 4 | Main hypothesis | ~2875 (target) |
| C | 1e-15 | 4 | Max curvature (conditional on B★) | unknown |
| D | 1e-10 | 4 | Conservative probe (conditional, if B★ marginal) | conditional |

Run order: A and B★ in parallel (n=4 direct — FFS-PRIMARY framing means no n=1 pre-screen needed, but see KG_smoke gate below). If B★ fails alive-gate (FFS_ema > 2975), stop sweep. Run C if B★ passes. Run D only if B★ is marginal (FFS_ema in 2890–2975 range).

Wandb group: `g1r5-nezuko/eps-cooldown-sweep`

---

## Gates

**KG_smoke (n=1, Cell B★, 500 steps):**
- Loss is finite (not NaN/Inf)
- val/loss at step 500 is in [3.35, 3.55] range (within 0.05 of CTRL)
- No CUDA errors
- PASS → launch full n=4 Cells A and B★

**Signal gate (n=4, Cell B★):** `FFS_ema ≤ 2975`
- If FFS_ema > 2975: close without C/D

**Promotion gate:** `μ_4(FFS_ema) ≤ 2887.5` AND `μ_4(FFS_trainval) ≤ 2900`
- Both metrics must move together to avoid seed-noise false positive

**Stop condition:** μ_4(FFS_ema) > 2950 and val/loss curves visually identical to control → close without C/D

---

## Distinctness Argument

**vs 78 closed R5 families:** "epsilon" appears in zero closed PR titles or descriptions across all 78 R5 closures. The closed families cover: NS polynomial variants, SOAP scalar HPs, Muon body wrappers (AGC, QHM, GC, Lookahead, Cautious), aux optimizer variants (AdaFactor, AdaGrad, Lamb, Adan), schedule variants (trapezoidal, SGDR, cosine, linear), init variants, label smoothing, spectral norm, Higham polish, Schulz polish, drop-path, forward-pass regularizers, gradient noise (SGLD, #1897 just closed), and the full additive gradient modifier family. None touch AdamW denominator ε.

**vs 7 in-flight axes:**
- edward #1948: precond_freq cooldown schedule (SOAP preconditioner refresh rate) — orthogonal
- alphonse #1941: depth LR scale (per-layer Muon LR) — orthogonal
- askeladd #1942: logit z-loss (output logit regularizer) — orthogonal
- tanjiro #1937: QKV ortho init (initialization) — orthogonal
- fern #1922: WD cooldown (weight decay schedule) — orthogonal (WD not ε)
- frieren #1910: bias LN LR scale (per-group LR scaling) — orthogonal (LR not ε)
- thorfinn #1907: LN gain init small (initialization) — orthogonal

Zero overlap with any closed or in-flight axis.

---

## CLI Commands

**KG_smoke (100-step viability check, Cell B★):**
```bash
cd "$PROBLEM_DIR" && SENPAI_TRAIN_STEPS=500 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 --eps_cooldown_end 1e-12 \
  --wandb_name "g1r5-nezuko/eps-smoke-B-1e12" \
  --wandb_group "g1r5-nezuko/eps-cooldown-sweep"
```

**Cell A (CTRL, n=4):**
```bash
cd "$PROBLEM_DIR" && SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 4 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 --eps_cooldown_end 1e-8 \
  --wandb_name "g1r5-nezuko/eps-ctrl-a1e8-n4" \
  --wandb_group "g1r5-nezuko/eps-cooldown-sweep"
```

**Cell B★ (main hypothesis, n=4):**
```bash
cd "$PROBLEM_DIR" && SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 4 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 --eps_cooldown_end 1e-12 \
  --wandb_name "g1r5-nezuko/eps-B-1e12-n4" \
  --wandb_group "g1r5-nezuko/eps-cooldown-sweep"
```

**Cell C (max curvature, conditional):**
```bash
cd "$PROBLEM_DIR" && SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 4 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 --eps_cooldown_end 1e-15 \
  --wandb_name "g1r5-nezuko/eps-C-1e15-n4" \
  --wandb_group "g1r5-nezuko/eps-cooldown-sweep"
```

**Cell D (conservative, conditional):**
```bash
cd "$PROBLEM_DIR" && SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 4 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 --eps_cooldown_end 1e-10 \
  --wandb_name "g1r5-nezuko/eps-D-1e10-n4" \
  --wandb_group "g1r5-nezuko/eps-cooldown-sweep"
```

---

## Research State Update

**Current best explanation for FFS plateau:**
The NS/SOAP/schedule cluster is saturated across 78 closed axes. The remaining headroom must come from loss-level (training objective), initialization changes, or schedule-side levers that have not yet been touched. AdamW ε is the only AdamW internal parameter that has never been touched across 281 R5 PRs.

**Ruled-out paths (do not repeat without new evidence):**
- All NS polynomial variants, NS iter count, NS fp precision changes
- All SOAP scalar HPs (β₁, β₂, precond_freq, trust)
- All Muon body wrappers (AGC, QHM, GC, Lookahead, Cautious)
- All aux optimizer variants (AdaFactor, AdaGrad, Lamb, Adan)
- All schedule variants (trapezoidal, SGDR, cosine, linear)
- All init variants (muP, maximal update, zero-init attn, LN gain small)
- All gradient noise / SGLD injection variants (PR #1897, just closed 78th)
- Label smoothing (PR #1870, FFS-NEG)
- Drop-path (PR #1903, FFS-NEG)
- GE-SAM (PR #1891, FFS-NEUTRAL)
- Schulz polynomial polish on non-square MLP (FFS-neutral)
- Spectral-norm pre-NS (catastrophic)
- Higham polar Newton polish on square attn (catastrophic)
- Cayley map gradient orthogonalization (catastrophic)

**Open uncertainties:**
1. Whether the `"eps" in group` guard correctly identifies AdamW-only groups in the specific optimizer setup used in `train_gpt_simple.py` — the student must inspect the param group structure before implementing.
2. Whether the SOAP-preconditioned attention groups also use AdamW ε (they may use a different internal optimizer state) — the student must check the SOAP group structure.
3. What the optimal ε floor value is for this architecture and vocabulary size — the FAdam paper used values from 1e-8 down to 1e-30 in different settings, so B★'s 1e-12 may be too conservative or too aggressive.

**Confidence:** Moderate. The mechanism is grounded in Fisher-information theory (FAdam 2024) and cooldown-phase analysis (Schaipp 2025). The specific interaction with this Muon+SOAP stack is unverified. The zero-overlap distinctness is confirmed.

**Taste rubric:**
- Mechanistic grounding: 3 — mechanism targets a specific structural property (ε in AdamW denominator) that is well-motivated by the FAdam Fisher-geometry analysis and the cooldown timing hypothesis; the link to this specific Muon+SOAP stack is speculative but plausible.
- Research-state value: 4 — either outcome cleanly separates "AdamW ε matters in cooldown" from "it is inert" and adds a new dimension to the R5 closure map.
- Execution value: 4 — single-flag, ~18 LOC, no new dependencies, clean sweep design, runs on the same 4-seed harness with staged conditional cells.
