# Research Ideas — 2026-05-17 05:30 UTC

**Context:** Baseline sr=3050, val=3.26773 (n=1, PR #193 cubic-Newton). Wave 7 stack (PR #225 thorfinn) testing γ_power=0.4 + deep-WD + lm_head 1/160, conservative est. sr=2987.5. Three students (alphonse, edward, fern) finishing arm B runs; will become idle soon.

**Open axes confirmed by full experiment history (lines 1-958 EXPERIMENTS_LOG):**
- AdamW β1=0.8 — never scanned; 0.9 is default
- AdamW eps=1e-10 — never scanned; 1e-8 is default (1e-10 is 100× more aggressive)
- Muon momentum mu=0.95 — hardcoded in `pmuon_update`, never scanned
- Muon base LR=0.035 — not retuned since cubic-Newton merge
- COOLDOWN_POWER=1.2 — not retuned on new cubic-Newton+γ_power stack
- embed_lr=0.3 — never scanned
- scalars_lr=0.01 — never scanned
- deep-WD slope refinement — arm A WIN at slope=0.5, may have finer optimum
- Warmup schedule — PMuon covariance EMA starts from cold; never probed
- z-loss / logit entropy auxiliary — never tried
- Muon LR retune on γ_power=0.4 stack — larger whitening strength may shift optimal LR

---

## TOP 8 EXPERIMENTS — Ranked by Expected Value

### RANK 1: Muon momentum mu scan {0.90, 0.98}

**Hypothesis:** mu=0.95 is hardcoded in `pmuon_update` and has *never been scanned* across the entire program history (960 lines of EXPERIMENTS_LOG confirmed). This is the highest-priority unexplored scalar in the optimizer. mu controls the momentum averaging timescale for the polar direction. With the bilateral whitening now more aggressive (γ_power=0.4 confirmed optimal), the optimal momentum horizon may shift. mu=0.9 reduces inertia (faster direction tracking), mu=0.98 increases it (more stable direction averaging). With power-law cooldown that front-loads LR drop, longer momentum buffers can smooth the rapid LR transitions at the start of cooldown.

**Arms:**
- Arm A: mu=0.90 (on current cubic-Newton baseline with γ_power=0.3 while wave 7 is in flight)
- Arm B: mu=0.98

**Mechanism:** mu determines how quickly the nesterov momentum buffer tracks gradient direction changes. Smaller mu → faster direction adaptation (helps in early training where loss landscape shifts rapidly). Larger mu → more stable direction averaging (helps in late cooldown where steps are small). The current mu=0.95 was inherited from the pre-PMuon era and has never been validated. This is a pure mechanism probe, not a schedule tweak.

**Expected Δsr:** −12.5 to −25 sr-steps if optimal mu deviates from 0.95. Null if 0.95 is already optimal. Zero downside risk (soft fallback to baseline).

**Code change (exact):**
```python
# In pmuon_update signature, add mu as parameter (currently hardcoded):
def pmuon_update(grad, momentum, L_cov, R_cov, mu=0.95, ...):
    momentum.lerp_(grad, 1 - mu)  # already parameterized in signature, just hardcoded in call

# In Muon.__init__, add to group:
optimizer2 = Muon([...], lr=0.035, weight_decay=0.025, beta_cov=0.95, gamma=0.3, mu=0.95)

# Arm A: mu=0.90
# Arm B: mu=0.98
```

**Cost:** ~1 GPU-run each arm (same as all previous screening runs). n=1 each arm.

**Falsifying result:** Both arms null or negative → mu=0.95 is a local optimum or the axis is flat. Continue only if one arm wins.

**Taste score:**
- Mechanistic grounding: 4 (hardcoded, never touched, well-motivated mechanism for momentum-LR interaction)
- Research-state value: 4 (sharp update either way: confirms a known unknown or finds a new win axis)
- Execution value: 4 (trivial code change, 2-arm, directly tests a never-probed axis)

---

### RANK 2: AdamW eps scan {1e-8, 1e-9}

**Hypothesis:** eps=1e-10 is extraordinarily aggressive — 2 orders of magnitude smaller than PyTorch default (1e-8) and 10× smaller than the already-nonstandard 1e-9. Aggressive eps amplifies parameter updates whenever second-moment estimates are small, which maps cleanly onto the embed and lm_head parameters that AdamW handles. The question is whether eps=1e-10 is actually optimal or was inherited from early tuning. With the cubic-Newton change and γ_power now in flux, the effective gradient scale of embed and lm_head may have shifted.

**Arms:**
- Arm A: eps=1e-8 (PyTorch default — strong regularization of updates)
- Arm B: eps=1e-9 (intermediate)

**Mechanism:** In AdamW, the effective LR for parameter p is `lr / (sqrt(v) + eps)`. When v is small (e.g., early training, rarely-activated tokens), eps acts as a floor on the denominator. eps=1e-10 effectively removes this floor, making updates pure `lr / sqrt(v)` for most of training. Larger eps dampens this — potentially stabilizing the embed and lm_head updates. Embed gradients have high sparsity (only touched tokens per batch), making eps particularly consequential for embed updates.

**Expected Δsr:** −12.5 to −25 if current eps is too aggressive. Null or small negative if 1e-10 is already optimal.

**Code change (exact):**
```python
# Current:
optimizer1 = AdamW([...], betas=(0.8, 0.95), eps=1e-10, ...)

# Arm A: eps=1e-8
# Arm B: eps=1e-9
```

**Cost:** ~1 GPU-run each arm. n=1.

**Falsifying result:** Both arms worse → 1e-10 is optimal (very aggressive eps actually helps). Would be interesting mechanistic finding.

**Taste score:**
- Mechanistic grounding: 3 (never scanned, plausible mechanism, link to sparse embed updates is solid)
- Research-state value: 3 (constrains AdamW eps axis which is fully open; result is interpretable)
- Execution value: 4 (one-line change, 2-arm, cheap)

---

### RANK 3: AdamW β1 scan {0.85, 0.90}

**Hypothesis:** β1=0.8 is unusually low for AdamW (default 0.9, common range 0.85-0.95). It was set early in the program and never revisited. Lower β1 means less momentum in the auxiliary optimizer paths (embed, lm_head, scalars). With power-law cooldown, β1 matters especially during the 70% cooldown phase where rapid LR decay occurs — higher β1 slows the optimizer's response to LR changes. At β1=0.8, the auxiliary optimizer tracks recent gradients very closely; at β1=0.9, it maintains longer momentum that may provide smoother updates through the aggressive cooldown.

**Arms:**
- Arm A: β1=0.85 (intermediate)
- Arm B: β1=0.90 (standard PyTorch default)

**Mechanism:** β1 controls the EMA timescale for the first moment (gradient direction) in AdamW. Lower β1 → faster adaptation to current gradient direction, higher variance in update direction. Higher β1 → smoother direction averaging, potentially beneficial when LR is rapidly dropping. The interaction with power-law cooldown (which has a 25× LR drop over 175 steps) is the key question: does faster or slower direction tracking help through the aggressive cooldown?

**Expected Δsr:** −12.5 if higher β1 smooths cooldown transitions. Null if flat axis. Unlikely to be negative unless very sensitive.

**Code change (exact):**
```python
# Current:
optimizer1 = AdamW([...], betas=(0.8, 0.95), ...)

# Arm A: betas=(0.85, 0.95)
# Arm B: betas=(0.90, 0.95)
```

**Cost:** ~1 GPU-run each arm. n=1.

**Falsifying result:** Both arms null → β1=0.8 is near-optimal or axis is flat. Close and move on.

**Taste score:**
- Mechanistic grounding: 3 (never scanned, plausible mechanism, but β1 effect on AdamW paths for embed/lm_head only — limited scope)
- Research-state value: 3 (closes an open axis; result is interpretable)
- Execution value: 4 (trivial change, 2-arm, cheap)

---

### RANK 4: Muon base LR retune {0.030, 0.040} on cubic-Newton base

**Hypothesis:** The Muon LR=0.035 was set before the cubic-Newton merge (PR #193). The cubic-Newton NS polynomial changes the effective magnitude scaling of the polar direction — it has a different convergence basin than the quintic. Combined with the deep-WD WIN (which independently damps weights), the optimal LR may have shifted. This is support work for the new stack but tests a genuine hypothesis: the effective gradient scale after cubic-Newton polar is different, and the current LR was tuned to the old quintic polar.

**Arms:**
- Arm A: lr=0.030 (−14% from current)
- Arm B: lr=0.040 (+14% from current)

**Mechanism:** PMuon's update norm is partially controlled by the polar step's convergence. Cubic-Newton's lower ortho_residual (~0.10 vs quintic ~0.01) means the polar is slightly less perfectly unit-spectrum. The u/w-floor then rescales, but the initial magnitude from polar affects downstream scaling. Lower LR compensates if cubic-Newton is inherently more aggressive; higher LR compensates if it's less aggressive.

**Expected Δsr:** −12.5 to −25 if LR drifted from optimum after cubic-Newton. Null if 0.035 is robust across polynomial families.

**Code change (exact):**
```python
# Current:
optimizer2 = Muon([...], lr=0.035, ...)

# Arm A: lr=0.030
# Arm B: lr=0.040
```

**Cost:** ~1 GPU-run each arm. n=1.

**Falsifying result:** Both arms null → lr=0.035 is robust to NS polynomial change. Expected — polynomial shape change is small relative to the u/w-floor rescaling that dominates.

**Taste score:**
- Mechanistic grounding: 2 (plausible mechanism, but u/w-floor absorbs most magnitude variation — likely null)
- Research-state value: 2 (closes a support-work axis; useful but not novel)
- Execution value: 3 (cheap, quick to close)

---

### RANK 5: Warmup schedule for PMuon covariance EMA

**Hypothesis:** PMuon's bilateral covariance EMAs (L_cov, R_cov) start from zero and are progressively filled by gradient outer products. In early training (steps 1-~100), the EMA estimates are unreliable — they represent only a handful of gradient samples. The `matrix_neg_power(L_cov, gamma)` call on an under-populated covariance matrix will produce very noisy eigenvalues, leading to erratic whitening in early steps. A short warmup that either (a) ramps gamma from 0→0.3 over the first 100 steps, or (b) ramps the Muon LR from 0→0.035 over the first 50 steps, could stabilize early preconditioning.

**Arms:**
- Arm A: Linear LR warmup for Muon — ramp from 0→0.035 over first 50 steps (before covariance EMA has filled)
- Arm B: gamma warmup — ramp gamma from 0.0→0.3 over first 100 steps

**Mechanism:** Early covariance EMA quality: after k steps, L_cov = sum_{i=1}^{k} beta^(k-i) * g_i g_i^T. With beta_cov=0.95 and k=20, the effective sample count is only ~(1/(1-0.95)) × (1 - 0.95^20) ≈ 20 × 0.64 = 12.8 samples. matrix_neg_power on a 12.8-sample estimate of a 768×768 matrix (or smaller for individual blocks) will have high eigenvalue noise. Warming up gamma prevents the noisy early covariance from being aggressively applied; warming up LR delays the optimizer from committing to early whitened directions.

**Expected Δsr:** −12.5 to −25 if early whitening noise is causing suboptimal gradient directions in the warm-up phase. More speculative than the mu/eps axes.

**Code change:**
```python
# Arm A: Add LR warmup for optimizer2 (Muon only)
MUON_WARMUP_STEPS = 50
# In set_hparams:
if step < MUON_WARMUP_STEPS:
    muon_eta = (step + 1) / MUON_WARMUP_STEPS
else:
    muon_eta = eta  # use power-law cooldown eta
optimizer2.param_groups[0]["lr"] = 0.035 * muon_eta

# Arm B: gamma warmup
GAMMA_WARMUP_STEPS = 100
effective_gamma = min(0.3, 0.3 * (step + 1) / GAMMA_WARMUP_STEPS)
# Pass effective_gamma to pmuon_update each step
```

**Cost:** ~1 GPU-run each arm. n=1. Slightly more code complexity than scalar HP changes.

**Falsifying result:** Both arms null → early covariance noise is self-correcting or the u/w-floor absorbs it. Expected given that beta_cov=0.95 means the EMA fills quickly.

**Taste score:**
- Mechanistic grounding: 3 (clear physical mechanism for early covariance unreliability; connects to known beta_cov=0.95 EMA dynamics)
- Research-state value: 3 (novel axis never probed; if wins, adds a principled warmup mechanism)
- Execution value: 2 (more code complexity; mechanism may self-correct via u/w-floor)

---

### RANK 6: COOLDOWN_POWER retune on γ_power=0.4 stack {1.0, 1.4}

**Hypothesis:** COOLDOWN_POWER=1.2 was optimized on the old baseline (PR #137 with γ_power=0.3). With γ_power=0.4 confirmed as a 37.5 sr-step WIN, the optimal cooldown shape may have shifted. Stronger whitening (γ_power=0.4) changes the gradient curvature landscape during cooldown — the preconditioned gradient directions may be more or less sensitive to the LR schedule shape. Note: PR #179 confirmed γ=1.1 and γ=1.3 are NULL on the γ_power=0.3 stack, suggesting a narrow optimum. The question is whether that optimum shifts with γ_power=0.4.

**Arms:**
- Arm A: COOLDOWN_POWER=1.0 (linear cooldown — less front-loaded than current 1.2)
- Arm B: COOLDOWN_POWER=1.4 (more concave — more front-loaded)

**Mechanism:** The power-law cooldown eta = (1 - cooldown_progress)^COOLDOWN_POWER controls the LR decay shape during the 70% cooldown phase. Higher power = more concave = LR drops faster initially but slower near end. With γ_power=0.4 providing stronger whitening, the gradient directions are more precisely estimated — possibly allowing a more aggressive (front-loaded) cooldown without loss. Or the opposite: better preconditioning means a gentler cooldown (closer to linear) suffices.

**Expected Δsr:** −12.5 if cooldown optimum shifts with γ_power. Null if cooldown is robust. This is support work for the γ_power=0.4 stack.

**Code change (exact):**
```python
# Also set gamma=0.4 to match the new optimal:
# Current: COOLDOWN_POWER = 1.2, gamma=0.3
# Arm A: COOLDOWN_POWER = 1.0, gamma=0.4
# Arm B: COOLDOWN_POWER = 1.4, gamma=0.4
```

**Cost:** ~1 GPU-run each arm. n=1. Note: run on γ_power=0.4 stack (not current baseline) — ensure comparison is vs frieren arm A result (sr=3025, val=3.26615).

**Caveat:** This experiment should run AFTER frieren PR #202 arm B terminates to confirm that γ_power=0.4 wins montonely over γ_power=0.2 (i.e., direction confirmed). If arm B of frieren also wins, the optimal γ_power needs to be pinned before retuning COOLDOWN_POWER.

**Falsifying result:** Both arms null → γ=1.2 is robust to γ_power change. Expected given PR #179 showed a narrow cooldown optimum.

**Taste score:**
- Mechanistic grounding: 2 (plausible interaction but COOLDOWN_POWER axis was tested on prior stack and showed narrow optimum; likely null again)
- Research-state value: 2 (closes support axis for wave 7 stack; result interpretable)
- Execution value: 2 (depends on frieren arm B first; not standalone)

---

### RANK 7: embed_lr scan {0.20, 0.40}

**Hypothesis:** embed_lr=0.3 was set early in the program history and has never been revisited. The embed matrix (vocab_size=50304 × model_dim=768) is handled by AdamW with its own LR. With the PMuon stack now much stronger (cubic-Newton + γ_power improvements), the embed optimizer's contribution to total gradient flow may have changed relative balance. Too-high embed LR can cause embedding instability that limits the transformer blocks' effective LR; too-low embed LR means the embedding doesn't adapt fast enough.

**Arms:**
- Arm A: embed_lr=0.20 (−33% from current)
- Arm B: embed_lr=0.40 (+33% from current)

**Mechanism:** The embed matrix is the only parameter connected to the discrete token distribution. Its gradient is sparse (only activated token positions receive nonzero gradient). AdamW with β2=0.95 accumulates a variance estimate that adapts quickly; the effective per-token update rate is embed_lr / sqrt(v_token). Changing embed_lr scales all token embedding updates uniformly. With train_steps=3250 and vocab=50304, each token sees approximately 3250 × 512 (tokens/seq) × 8 (seqs/batch) / 50304 ≈ 265 gradient updates, so convergence of rarer tokens may be LR-sensitive.

**Expected Δsr:** −12.5 if current embed LR is mistuned. Likely null — embed is a single matrix and the AdamW adaptive scaling dominates.

**Code change (exact):**
```python
# Current: dict(params=[model.embed.weight], lr=0.3, name="adam_embed")
# Arm A: lr=0.20
# Arm B: lr=0.40
```

**Cost:** ~1 GPU-run each arm. n=1.

**Falsifying result:** Both arms null → embed_lr=0.3 is robust. Very likely outcome given the adaptive scaling of AdamW.

**Taste score:**
- Mechanistic grounding: 2 (plausible but embed AdamW is well-conditioned by design; mechanism is weak)
- Research-state value: 2 (closes an open axis but expected null)
- Execution value: 3 (trivially cheap)

---

### RANK 8: z-loss auxiliary on logits

**Hypothesis:** The logit soft-cap `logits = 15 * logits * (logits.square() + 15**2).rsqrt()` bounds the magnitude but does not prevent the logit distribution from collapsing to low-entropy solutions (all probability concentrated on a few tokens). A z-loss penalty `z_loss = beta * logsumexp(logits)^2` added to the cross-entropy loss can stabilize the logit scale and prevent entropy collapse during the aggressive cooldown phase, leading to more uniform token distributions that generalize better. This technique was used in PaLM and Gemini for training stability.

**Arms:**
- Arm A: z_loss_weight=1e-4 (small penalty)
- Arm B: z_loss_weight=1e-3 (moderate penalty)

**Mechanism:** The loss = cross_entropy(logits, targets) + z_loss_weight * mean(logsumexp(logits)^2). The z-loss penalizes large logit norms while the cross-entropy rewards correct predictions. The tension between these forces prevents the model from using extremely large logit magnitudes to make confident (but brittle) predictions. During aggressive cooldown, the loss landscape is rapidly contracting; z-loss provides a stabilizing force that prevents the optimizer from taking huge steps in logit-space at large-LR steps.

**Expected Δsr:** −12.5 to −25 if logit entropy collapse is a limiting factor. More speculative — requires checking telemetry for logit norm growth during training.

**Code change:**
```python
# Add z-loss to the main training loop:
Z_LOSS_WEIGHT = 1e-4  # arm A; 1e-3 for arm B

# In forward pass, after computing loss:
log_z = torch.logsumexp(logits.float(), dim=-1)  # (B*T,)
z_loss = Z_LOSS_WEIGHT * (log_z ** 2).mean()
total_loss = loss + z_loss
total_loss.backward()

# Note: log separately as train/z_loss for telemetry
```

**Cost:** ~1 GPU-run each arm. n=1. Slightly more code — need to restructure forward pass to return both loss and logits.

**Caveat:** The logit soft-cap may already suppress z-loss benefit by capping logit magnitude. If the soft-cap is already preventing entropy collapse, z-loss will be a null that adds training cost for no benefit.

**Falsifying result:** Both arms null or negative → logit soft-cap is sufficient; z-loss adds regularization that fights the fast-converging PMuon+cooldown stack.

**Taste score:**
- Mechanistic grounding: 2 (well-motivated in general; but logit soft-cap may already handle this; speculative connection to speedrun objective)
- Research-state value: 3 (novel mechanism, never tried; result would confirm or rule out logit entropy collapse as a limiting factor)
- Execution value: 2 (more code complexity; soft-cap likely makes this null; save for after cheaper axes exhausted)

---

## Summary Table

| Rank | Experiment | Mechanism | Expected Δsr | Taste (MG/RSV/EV) | Priority |
|---|---|---|---|---|---|
| 1 | Muon mu scan {0.90, 0.98} | Momentum timescale — never scanned | −12.5 to −25 | 4/4/4 | **ASSIGN FIRST** |
| 2 | AdamW eps scan {1e-8, 1e-9} | Adaptive scaling floor — never scanned | −12.5 to −25 | 3/3/4 | **ASSIGN SECOND** |
| 3 | AdamW β1 scan {0.85, 0.90} | Momentum horizon for embed/lm_head | −12.5 | 3/3/4 | **ASSIGN THIRD** |
| 4 | Muon LR retune {0.030, 0.040} | LR drift after cubic-Newton polynomial change | −12.5 to −25 | 2/2/3 | Assign if 3 idle |
| 5 | PMuon warmup {LR warmup, gamma warmup} | Early covariance EMA cold-start noise | −12.5 to −25 | 3/3/2 | Assign if 4 idle |
| 6 | COOLDOWN_POWER retune {1.0, 1.4} on γ_power=0.4 | Cooldown shape drift after whitening change | −12.5 | 2/2/2 | After frieren arm B terminates |
| 7 | embed_lr scan {0.20, 0.40} | Embedding LR drift — never scanned | −12.5 | 2/2/3 | Background axis |
| 8 | z-loss auxiliary {1e-4, 1e-3} | Logit entropy collapse prevention | −12.5 to −25 | 2/3/2 | After cheap axes done |

## Assignment Recommendation for alphonse, edward, fern

- **alphonse** (finishing PR #197 arm B): Assign **Rank 1 — Muon mu scan** as next experiment
- **edward** (finishing PR #198 arm B): Assign **Rank 2 — AdamW eps scan**
- **fern** (finishing PR #195 arm B): Assign **Rank 3 — AdamW β1 scan**

All three are on the same timescale (~7h remaining for arm B, then idle). These three axes are mutually orthogonal (Muon mu vs AdamW eps vs AdamW β1) so can run in parallel without interaction concerns.

**Why these three now?** These are the highest-EV never-scanned scalars that:
1. Target different optimizer components (Muon internal vs AdamW eps floor vs AdamW β1)
2. Have clear mechanism stories
3. Are trivially cheap (one-line changes)
4. Are fully orthogonal to each other and to the running Wave 7 stack (PR #225)
5. Would directly improve the cubic-Newton+γ_power base that Wave 7 is building on

If Wave 7 (PR #225) returns sr≤3000, then Ranks 1-3 should be rerun on that new base immediately, as the optimal scalar values may shift with the stronger overall stack.
