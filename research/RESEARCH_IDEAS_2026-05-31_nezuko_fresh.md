# Fresh Hypothesis: g1r5-nezuko
# Generated: 2026-05-31
# Axis: Annealed Gradient Noise Injection

---

## 1. Slug

`annealed-gradient-noise-muon`

---

## 2. One-sentence summary

Inject per-step annealed Gaussian noise into Muon gradients before NS5 processing to widen the effective loss basin traversed during training, increasing the probability that the EMA-smoothed trajectory crosses the 3.28 threshold in the FFS window.

---

## 3. Mechanistic argument

**The FFS bottleneck is threshold reliability, not mean loss level.**

The R5 stack achieves mu_4(FFS_ema)=2912.5 with sigma_4=25. The baseline val loss at FFS crossing is ~3.276-3.278 — the model reaches loss regions where small curvature-geometry differences (~1sigma) determine whether EMA crosses 3.28 by step 2875 or 2925 or 2975. There is no large systematic gap to close; the problem is the stochastic geometry of the final descent into the 3.28 basin.

**Gradient noise injection widens the basin explored.**

Annealed Gaussian noise added to gradients before optimizer processing (and thus before NS5 orthogonalization) is equivalent to stochastic gradient Langevin dynamics (SGLD, Welling & Teh 2011). At finite temperature, the optimizer explores a wider region of weight space, preferentially converging to flatter minima. Flat minima have:
- Lower curvature -> smaller Hessian trace -> sharpness-aware advantage
- Wider loss basin -> EMA smoother crosses threshold more reliably per step
- Less sensitivity to EMA-eval lag: a flat basin means val and EMA-val are nearly equal near threshold

The noise schedule sigma_t^2 = eta / (1 + t)^gamma (Neelakantan et al. 2015) anneals to zero by late training, so the final weights are NOT perturbed. The late-stage annealing means GE-SAM (#1891, in-flight) and gradient noise are architecturally complementary: GE-SAM sharpens the search direction via finite-difference HVP; gradient noise broadens the basin explored during mid-training. Their mechanisms are orthogonal.

**Interaction with NS5 processing.**

The noise is added to the raw gradient G before the NS5 call. NS5 then orthogonalizes the NOISY gradient. This has a subtlety worth tracking: for small noise magnitudes relative to signal, NS5 will absorb the noise into the orthogonal direction that is closest to the noisy gradient — effectively projecting noise onto the signal-dominated singular value subspace. For large noise, the NS5 orthogonalization direction rotates non-trivially. The optimal regime is noise << signal (low SNR effect only in the direction NOT covered by the dominant singular values). This makes gamma=0.55 (sub-sqrt annealing) important: too slow and noise dominates late-stage NS5.

A critical diagnostic: log `diag/noise_snr = grad_rms / injected_noise_rms` per step. If SNR < 1 at step 100+, the noise magnitude is too large and should be reduced. The KG_smoke cell must pass this diagnostic.

**Why this is fresh.**

The closed axis inventory for R5 covers:
- NS5 polynomial approximation family (all variants closed: poly, Padé, Cayley, Higham, Schulz polish, per-head, adaptive iter)
- SOAP internal structure (all scalar HPs, Gram init, QR iter, basis refresh)
- Muon momentum and init (4/4 closed)
- AdamW aux group (4/4 closed)
- Schedule shape and per-class decoupling (all closed)
- GC (#1885, in-flight): subtracts per-row mean from gradient — affects translational invariance
- GE-SAM (#1891, in-flight): finite-difference gradient extrapolation — sharpness
- Lookahead (#1895, in-flight): slow/fast weight interpolation — trajectory space

Gradient noise injection is NOT in any of these families. It operates via additive stochastic perturbation of the gradient tensor before any optimizer transformation. It is:
- Orthogonal to GC: GC is deterministic (mean subtraction); noise is stochastic
- Orthogonal to GE-SAM: GE-SAM uses previous gradient to extrapolate; noise adds fresh randomness
- Orthogonal to Lookahead: Lookahead averages weight trajectories; noise perturbs gradient inputs
- Orthogonal to all NS5 structural variants: those changed HOW the gradient is orthogonalized; this changes WHAT is orthogonalized

---

## 4. Structural orthogonality

| Closed/in-flight axis | Mechanism | Noise injection mechanism | Orthogonal? |
|---|---|---|---|
| NS5 polynomial (all variants) | How gradient is orthogonalized | What gradient is fed to NS5 | YES |
| SOAP all scalar HPs | Kronecker preconditioner parameters | Pre-optimizer gradient | YES |
| Muon momentum/init | Momentum buffer content/start state | Gradient before momentum | YES |
| AdamW aux group | LR/WD/beta/schedule for scalars | Does not affect AdamW params | YES |
| GC #1885 | Per-row mean subtraction (deterministic) | Additive stochastic noise | YES |
| GE-SAM #1891 | g_t + alpha*(g_t - g_{t-1}) extrapolation | Independent Gaussian draw | YES |
| Lookahead #1895 | Slow/fast weight averaging over k steps | Gradient input perturbation | YES |
| Init axes (all 4 closed) | Starting weights | Training-time gradient | YES |

No overlap with any closed or in-flight axis. This is a structurally clean fresh axis.

---

## 5. Implementation surface

**Target file:** `records/track_3_optimization/train_gpt_simple.py`

**New flags (add to argparse):**
- `--grad_noise_eta FLOAT` — noise scale (default 0.0 = disabled)
- `--grad_noise_gamma FLOAT` — annealing exponent (default 0.55)

**Implementation: ~20 LOC added to the Muon `step()` function.**

The noise injection should happen inside the Muon step, BEFORE the `zeropower_via_newtonschulz5` call. The relevant code region is approximately lines 501-530 (the NS5 + Frobenius-norm + update application block).

Pseudocode for the injection:

```python
# In Muon.step(), before calling zeropower_via_newtonschulz5:
if self.grad_noise_eta > 0.0:
    # Neelakantan et al. 2015: sigma_t^2 = eta / (1 + t)^gamma
    t = self._step_count  # track per-optimizer step count
    sigma_t = math.sqrt(self.grad_noise_eta / (1.0 + t) ** self.grad_noise_gamma)
    noise = torch.randn_like(g) * sigma_t
    g = g + noise
    # Optional diagnostic: log SNR for KG_smoke verification
    # snr = g.norm() / noise.norm()  (log to W&B if diag mode)
```

**Step counter:** Add `self._step_count = 0` to `__init__` and `self._step_count += 1` at the start of each `step()` call. This is distinct from the global training step counter and must be per-optimizer-instance.

**Distributed correctness:** Each rank injects INDEPENDENT noise (no all-reduce of noise). This is intentional — it increases effective stochasticity beyond the gradient noise already present from data batches. If synchronization is desired, use `torch.manual_seed(global_step + rank)` deterministically, but the async variant is standard SGLD.

**W&B diagnostic logging (add to telemetry block):**
- `train/grad_noise/sigma_t` — injected noise std at current step
- `train/grad_noise/snr` — ratio `grad_rms / sigma_t` (must be >> 1 post-step-200)

**Do NOT inject noise into the AdamW group** — scalars/LN/biases are already well-conditioned and noise would destabilize them. Only apply to the Muon group (embed, attn, mlp matrices).

**Key hyperparameter sensitivity notes:**
- `eta=0.01` is a moderate starting point. The Neelakantan et al. 2015 paper used eta=0.01 for RNNs; language models with Muon may prefer smaller values (0.001-0.005) due to the large gradient norms post-NS5.
- `gamma=0.55` is the Neelakantan recommendation; values in [0.5, 0.7] are the typical search range. Lower gamma = slower annealing = more late-stage noise.
- The noise is added to the RAW gradient (before Frobenius normalization and NS5). After NS5 orthogonalization the effective noise level in the update is further reduced. The post-NS5 noise level in the update scales as sigma_t / sqrt(n_params_per_matrix) due to projection.

---

## 6. Experimental cells

| Cell | eta | gamma | n | Purpose |
|---|---|---|---|---|
| A (CTRL) | 0.0 | — | 1 | Baseline reproduce, verify W&B telemetry |
| B★ | 0.005 | 0.55 | 1 | Primary test: moderate noise, Neelakantan default gamma |
| C | 0.001 | 0.55 | 1 | Light noise: closer to zero-noise limit |
| D | 0.01 | 0.55 | 1 | Stronger noise: tests if more exploration helps |
| E (falsifier) | 0.005 | 0.10 | 1 | Slow annealing: noise persists into late stage — should HURT (falsifier if B★ helps) |

**Cell ordering:** Run A and B★ in parallel (if student GPU allows sequential). Run C and D only if B★ passes FFS-alive gate. Run E only if B★ shows positive signal (to confirm the annealing mechanism is load-bearing).

**Promotion gate for n=4 confirm:** B★ FFS_ema <= 2875 AND FFS_trainval <= 2900 on seed=42.

---

## 7. KG_smoke gate

**Command (verify code is correct, loss is finite, W&B logs noise metrics):**

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --grad_noise_eta 0.005 --grad_noise_gamma 0.55 \
  --train_steps 500 \
  --wandb_name "g1r5-nezuko/annealed-gradient-noise-muon-smoke" \
  --wandb_group "annealed-gradient-noise-muon"
```

**KG_smoke pass criteria:**
1. Loss is finite (not NaN/Inf) at step 500
2. `train/grad_noise/sigma_t` decreases monotonically from step 1 to step 500
3. `train/grad_noise/snr` > 5.0 by step 100 (noise << signal; if SNR < 1, eta is too large)
4. `val/loss` at step 500 is in [3.35, 3.50] range (approximately same as CTRL)
5. No CUDA errors, no OOM

**KG_smoke FAIL criteria (close immediately):**
- NaN/Inf loss at any step
- SNR < 1 at step 100 (noise drowning signal — eta too large by 10x)
- val/loss > 3.6 at step 500 (training severely disrupted)

---

## 8. Gates

| Gate | Condition | Action if PASS | Action if FAIL |
|---|---|---|---|
| KG_smoke | finite loss + SNR>5 at step 100 | Launch Cell A + B★ (500 -> 3250 steps) | Close: implementation issue or eta too large |
| FFS-alive (Cell B★) | FFS_ema <= 2975 on n=1 | Continue Cells C, D, E | Close: noise unhelpful even in best eta regime |
| Primary gate (Cell B★) | FFS_ema <= 2875 AND FFS_trainval <= 2900 | Promote to n=4 confirm | Request-changes: try Cell C (smaller eta) |
| n=4 confirm | mu_4(FFS_ema) <= 2887.5 | MERGE candidate | Close: seed-noise on n=1 |

---

## 9. Stop conditions

1. **Close immediately** if KG_smoke fails (NaN, OOM, SNR < 1).
2. **Close after Cell B★** if FFS_ema > 2975 (not FFS-alive).
3. **Close after Cells B★+C+D** if all three show FFS_ema >= 2925 and no trend suggesting lower eta would help.
4. **Close Cell E if B★ fails gate** — no point testing the falsifier on a dead mechanism.
5. **Request-changes (try smaller eta=0.001)** if B★ shows FFS_ema=2925 but val/loss is notably lower than CTRL (suggests mechanism is right but overdamped — eta too large).

---

## 10. Pre-mortems

**Pre-mortem 1: Noise is absorbed by NS5 orthogonalization.**
NS5 projects the noisy gradient onto the nearest orthogonal matrix. For small noise relative to signal, the update direction barely changes — the orthogonalized noise component is tiny. **Expected observable:** B★ FFS_ema = CTRL at 2925 with no val improvement. **Falsifier check:** Cell C (smaller eta) should also be neutral if this is the mechanism. **Response:** if both B★ and C = 2925, close as null axis.

**Pre-mortem 2: Noise disrupts Frobenius normalization calibration.**
The Frobenius norm is used to calibrate Muon LR. Adding noise increases ‖G‖_F, so the effective per-step LR scales down slightly. This is an LR perturbation side-effect. **Expected observable:** FFS_ema worsens slightly (2950) rather than improving. **Diagnostic:** check `train/lr/muon` trace — if it drifts lower than CTRL, the normalization effect dominates. **Response:** add `g = g / (g.norm() / g_original_norm)` to hold norm constant after noise injection; but this first implementation should test the direct version.

**Pre-mortem 3: Slow annealing in Cell E does NOT replicate B★ degradation.**
If B★ is positive but Cell E also positive, the annealing mechanism is not load-bearing — the noise is simply a regularizer that helps regardless of when it's removed. **Response:** merge B★ but flag that gamma exploration is needed. If B★ positive and E ties, that is still a positive result (noise helps; annealing not critical). If B★ positive and E worse than CTRL, the annealing IS load-bearing, which is the strongest mechanistic confirmation.

**Pre-mortem 4: Benefits are seed-specific (n=1 positive regresses at n=4).**
This is the dominant failure mode across all 69+ closures. **Protocol:** Report BOTH FFS_ema AND FFS_trainval for every cell from the start. Only cells with FFS_trainval <= 2900 should be promoted to n=4.

**Pre-mortem 5: GE-SAM (#1891) and gradient noise are NOT additive.**
If GE-SAM extrapolates in the gradient direction and noise adds orthogonal stochasticity, the two may compete for the "gradient preparation" role. Since GE-SAM is in-flight (assigned to askeladd), there is a potential interaction. **Protocol:** run this experiment on its own first (without GE-SAM's `--grad_extrapolate_alpha`). If both axes show positive signal independently, a joint experiment could follow.
