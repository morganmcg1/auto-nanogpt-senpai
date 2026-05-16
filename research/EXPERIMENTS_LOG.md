# SENPAI Research Results — auto-nanogpt-1gpu-r4

This file logs experiment outcomes as PRs land. The historical track 3
leaderboard is captured in `/BASELINE.md`.

## 2026-05-15 19:00 UTC — wave 1 closed PRs

### PR #62 — Schedule-Free Muon (askeladd) — CLOSED negative

| Arm | LR | sf_beta | mu | warmup | Steps | val/loss | Run |
|-----|----|---------|----|--------|-------|----------|-----|
| A | 0.035 | 0.90 | 0.95 | 0 | 3350 | 3.3638 | hltz3pr3 |
| B | 0.025 | 0.90 | 0.95 | 0 | ~246 (killed) | — | — |
| C | 0.035 | 0.90 | 0.95 | 200 | ~1250 (killed) | 3.587 | eetdzgtl |
| D | 0.035 | 0.98 | 0.00 | 200 | ~1625 (killed @ kill gate) | 3.613 | zxdq6572 |

**Result:** No arm reached 3.28. Best val=3.3638. Paper-aligned recipe (arm D) was worse due to: (1) high sf_beta=0.98 keeps y far from z, slowing forward pass; (2) mu=0 removes Nesterov preconditioning from NS input, increasing per-step noise. **Key insight**: the 70% linear LR cooldown is load-bearing on this benchmark — it is doing real work collapsing to a sharp basin that SF's trajectory averaging cannot substitute. Closed per PR §6 protocol (val > 3.29 after LR retune exhausted).

### PR #77 — Lion for Auxiliary Groups (thorfinn) — CLOSED negative

| Arm | lion_embed_lr | lion_lmhead_lr | Steps | val/loss |
|-----|--------------|----------------|-------|----------|
| A | ~0.3 | ~0.003 | 3350 | 3.3144 |
| B | 0.05 | 0.00078 | 3350 | 3.3109 |

**Result:** Both arms ~0.032 nats above 3.28 target. Lion's sign-momentum update loses gradient information for the small aux groups where AdamW already runs cheaply. Lion is designed for the regime where Adam's correction is expensive — not applicable here.

---

## 2026-05-15 20:26 UTC — PR #60: Muon² (alphonse) — TERMINAL — STAT-SIG WIN

**Hypothesis:** Adam 2nd-moment preconditioning before Newton-Schulz gives NS a better-conditioned matrix input, reducing orthogonalization work per step.

| Arm | NS iters | W&B run | val/loss | first_step_to_target |
|-----|----------|---------|----------|---------------------|
| A, seed 1 | 12 | s0oq3dnx | **3.276593** | **3275** |
| A, seed 2 | 12 | 4hedrgf4 | **3.276536** | **3275** |
| B | 8 | pg0uma5w | 3.277377 | 3300 |

**Stat-sig (NS=12, n=2):** mu=3.276565, margin=(3.28-3.276565)*sqrt(2)=0.004859 ≥ 0.004 ✓  
**Winner: NS=12.** NS=8 is +0.000813 worse (~20× inter-seed sigma) and reaches target 25 steps later.

**Analysis:** Mechanism holds — feeding `m / (sqrt(v) + eps)` into NS-12 produces better-conditioned input and the optimizer crosses 3.28 at step 3275 (75 steps earlier than 3350 starter budget). NS iteration reduction (Arm B) did NOT benefit from Muon² as predicted by the paper — at our scale (124M, 3350 steps), full 12-iter orthogonalization remains optimal. Also bundles the `sample_tensor` float64 precision bug fix.

**Also included:** `NANOGPT_NS_ITERS` env var for future NS-iteration ablations.

**Follow-ups noted by student:** Stack with Contra-Soft/SOAP; lr/wd retune for Muon²; beta2 sweep {0.95, 0.98, 0.999}; Muon²+NS=8 with lr retune.

**Status:** Terminal SENPAI-RESULT posted. Merge pending GH rate limit reset (~21:26 UTC).

---

## 2026-05-15 20:32 UTC — PR #75: NS iteration sweep (tanjiro) — TERMINAL — DIAGNOSTIC

**Hypothesis:** NS=8 or NS=6 match NS=12 quality with compute savings.

| Arm | NS iters | W&B run | val/loss | first_step_to_target | step_avg_ms | Wall-clock saved |
|-----|----------|---------|----------|---------------------|-------------|-----------------|
| A | 12 | 3kx01ieh | 3.27890 | 3325 | 1797.19ms | — |
| B | 8 | tzhrr686 | **3.27849** | 3325 | 1786.36ms | 0.60% (10.83ms) |
| C | 6 | jnnsgmrs | 3.28980 | — (FAILED) | 1777.17ms | 1.11% (20ms) |

**Analysis:** NS=8 is correctness-safe (Δ=−0.0004 vs NS=12, within seed noise), but **wall-clock savings are minimal (<1%)** because the NS inner loop is NOT the compute bottleneck at this 1-GPU scale — forward/backward/telemetry dominate. NS=6 fails (0.011 nats degradation, does not cross 3.28). NS=12 and NS=8 crossings are baseline-noise single seeds — Muon² (NS=12, n=2) at val=3.2765 is the rigorous result. Closing as a successful diagnostic; NS=8 knowledge preserved for Muon²+NS=8 follow-up if Muon² LR retune confirms headroom.

---

## 2026-05-15 20:35 UTC — PR #66: Cosine cooldown (edward) — CLOSED — DEAD END

**Hypothesis:** Cosine LR schedule during cooldown phase outperforms linear cooldown.

**Result:** Branch corruption beyond just cosine path — linear baseline arm also diverged (162M nonfinites at step 375). Cosine path had NaN at step 3. Closed and student reassigned to orthogonal QKV initialization (PR #92).

---

## 2026-05-15 — wave 1 in-flight summary (not yet reviewed)

Snapshot from W&B at 16:20 UTC, prior to terminal SENPAI-RESULT submissions.
Each student also independently rediscovered and locally patched a precision bug
in `sample_tensor` (line 183, `torch.linspace(0, n-1, K).long()` returns OOB
idx for n > 2^24, e.g. the 38.6M-element embed gradient). Fix variants are in
their local branches; nezuko (#73) is canonical.

| PR | Student | Hypothesis | Best arm | first_step_to_target | val/loss | Note |
|----|---------|-----------|----------|---------------------|---------:|------|
| #60 | alphonse | **Muon²** (Adam 2nd-moment precond before NS) | arm-A NS=12 | **3275** | **3.2765/3.2766** | **STAT-SIG CONFIRMED** n=2: (3.28-3.27655)*sqrt(2)=0.0049>=0.004; arm-B (NS=8) running |
| #75 | tanjiro | NS iter sweep 12/8/6 | NS=8 slightly better | 3325 | 3.2785 (NS=8), 3.2789 (NS=12) | Both NS=8 and NS=12 beat 3.28; NS=8 marginally better — compute headroom confirmed; NS=6 running |
| #70 | fern | cooldown_frac 0.5/0.6/0.7 | frac-0.5 | 3325-3350 | 3.2790/3.2793 (seeds 1+2) | Confirmation seed 3 running; n=2 mean=3.27916, needs seed 3 for stat-sig |
| #62 | askeladd | Schedule-Free Muon | CLOSED negative | — | 3.3638 best | 4 arms failed; see full entry above |
| #77 | thorfinn | Lion for aux groups | CLOSED negative | — | 3.3109 best | both arms worse; see full entry above |
| #72 | frieren | Muon Nesterov mu sweep | mu-0.90 (screening) | — | 3.3700 @ step 2000 | screening only, 4 more arms pending |
| #73 | nezuko | WD warmup 0/5/10% | wd-warmup-A-0.00 (running) | — | 3.5288 @ step 1600 | early in run |
| #66 | edward | cosine vs linear cooldown | — | — | NaN (running) | recovered after rate-limit episode; runs producing NaN val/loss currently |

### Critical methodology observation

Tanjiro's NS=12 baseline arm — which is the **unmodified starter recipe** —
crossed 3.28 at first_step_to_target=3325, val/loss=3.2789. Prior 62 W&B rounds
of this baseline never crossed 3.28 (closest 3.2813). This says single-seed
crossings of the threshold are well within the natural seed noise of the
starter recipe itself.

**Implication:** Stat-sig confirmation (3 seeds, `(3.28 - mu) * sqrt(n) >=
0.004` → mean ≤ 3.2777 at n=3, ≤ 3.278 at n=4) is the binding constraint, not
the first crossing. Any future first-crossing result must be accompanied by a
predeclared seed batch to count as a win.

### Infrastructure incident

Around 15:38-16:23 UTC, the org-shared gh token hit its 5000-req/h rate limit
(advisor was at 2232/5000 when first noticed). Student pods that depended on
gh for assignment-state queries failed assignment polls for ~45 min:

- alphonse, tanjiro: pods went idle (GPU=0%) after arm-A completed; couldn't
  query their next assignment state, so the heartbeat fell through to
  "No assigned PRs" and slept.
- edward, fern: training that was already running kept running (GPU 35-36 GB,
  100% util) — the rate limit only affected new poll cycles, not in-flight
  Python processes.
- All pods recovered at iter 30-36 (~16:21-16:24 UTC) once the token reset.

---

## 2026-05-15 23:50 UTC — PR #73: WD warmup (nezuko) — CLOSED negative

**Hypothesis:** Deferring weight decay during the first ~10% of training lets Muon make faster initial progress; full WD applied through cooldown for regularization.

| Arm | wd_warmup_frac | W&B run | val/loss @3350 | first_step_to_target |
|-----|---------------:|---------|---------------:|---------------------:|
| A   | 0.00 (baseline) | mpq9bfwk | 3.27969 | 3350 |
| B-s1| 0.05            | 2qrloa5p | 3.27868 | 3325 |
| C   | 0.10            | ix77c7mg | 3.27952 | 3350 |
| B-s2| 0.05 (seed 2)   | sjcj2lfk | 3.27970 | 3350 |

**Stat-sig check on best arm (Arm-B n=2):** mean=3.27919, margin=(3.28-3.27919)*sqrt(2)=0.00114 ≪ 0.004 threshold. **NOT stat-sig.**

**Diagnostic:** Weight-norm trajectories across arms tracked within 0.1% of each other; early-descent slopes indistinguishable. At WD=0.025, weight decay simply isn't a meaningful early-training force compared to Muon's update magnitude. Mechanism does what it says (telemetry verified ramp on muon_blocks group) but produces no measurable benefit. Worse than merged Muon² baseline (3.27919 vs 3.2766).

**Bundled finding (already in baseline):** nezuko's sample_tensor float64 fix was excellent diagnostic work, but it had already been independently cherry-picked into the merged Muon² PR #60 via alphonse. That's why this PR ended in merge-conflict state.

**Conclusion:** WD warmup unlikely to help any recipe with final WD ≤ 0.025. Re-test only if a future recipe lands with WD ≥ 0.05.

---

## 2026-05-16 01:30 UTC — PR #97: Muon² beta2 sweep (tanjiro) — CLOSED inconclusive (pod-level divergence)

**Hypothesis:** Sweep Muon² 2nd-moment EMA beta2 ∈ {0.95, 0.98, 0.999} to find optimum for short-horizon regime.

| W&B run | beta2 | bias_correction | Role | Outcome |
|---------|-------|-----------------|------|---------|
| `hov7gbvg` | 0.95 | off (merged) | arm-A | NaN by step 25 |
| `hger8tqw` | 0.98 | off | arm-B | NaN by step 25, killed at step 403 |
| `v5yl0u6u` | 0.999 | off | arm-C | NaN by step 25, killed at step 1314 |
| `37q9u3pr` | 0.999 (stashed diff, untouched baseline) | off | pod isolation | **NaN by step 25 — same divergence as arms!** |
| `h8j7zoep` | 0.999 (telemetry=1) | off | step-by-step trace | Inf in 20 weight entries at step 2; NaN cascade by step 3 |

**Diagnostic conclusion:** **NOT a beta2 effect — this is pod-specific hardware divergence.** The merged Muon² baseline (which alphonse reaches val=3.2766 on) reproducibly NaNs on tanjiro's pod from the very first optimizer step. Same code, same Blackwell GPU model, same torch/CUDA stack, but tanjiro's GPU UUID `7998cef9-...` produces Inf in the first Muon² weight update. ECC clean per nvidia-smi.

**Secondary finding (motivates PR #108):** Muon² as merged lacks Adam-style bias correction `v_hat = v / (1 - beta2^t)`. The first-step preconditioned input swings ~32× sign(u) at beta2=0.999 vs ~7× at beta2=0.98 vs ~4.5× at beta2=0.95, breaking comparability of any beta2 sweep on the current Muon² code. Bias correction may both stabilize lower beta2 values AND make the sweep meaningful.

**Verdict:** Closed without merge. tanjiro reassigned to PR #108 (Muon² + bias correction with mandatory pod smoke-test gate). If the pod is still broken, smoke test will catch it in 100 steps before burning 7+ hours on doomed arms.
