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

---

## 2026-05-16 02:45 UTC — PR #92: Orthogonal QKV init (edward) — CLOSED negative

**Hypothesis:** Initializing QKV projections with orthogonal matrices (unit singular values) reduces Newton-Schulz orthogonalization work in early training, speeding descent in steps 50–500.

| Arm | QKV init | W&B run | val/loss @3350 | first_step_to_target | vs baseline |
|-----|----------|---------|---------------:|---------------------:|------------|
| A | **orthogonal** | `s8044x4a` | 3.27862 | 3325 | +50 steps (worse) |
| B | **normal** | `h1f66mpd` | 3.27804 | 3300 | +25 steps (worse) |

n=1 stat-sig check: (3.28 − 3.2780) × √1 = 0.0020 < 0.004 threshold.

**Early-descent analysis (the predicted-win regime):**
| window | A orth. slope | B normal slope | A − B |
|--------|----------:|----------:|------:|
| 50–200 | −0.007321 | −0.007243 | −0.000078 |
| 100–500 | −0.002288 | −0.002204 | −0.000084 |

Orthogonal barely steeper in the predicted regime but the difference is an order of magnitude smaller than seed noise. From step 1000 onward the two val/loss curves differ by ≤ 0.0006 — statistically indistinguishable.

**Key mechanistic insight (edward's analysis):** 'Muon's Newton-Schulz step rapidly orthogonalizes the QKV *update direction* regardless of the init's singular-value structure; equilibrium is reached within ~25-50 steps and weight trajectories converge by step ~200.' NS *continuously* supplies the well-conditioned-update property on every step — static init structure is irrelevant for Muon-trained matrices. Brock et al. (2021) benefits appear only in attention-only / linear settings where orthogonality is preserved over training.

**Follow-up implications:**
- Skip analogous MLP / output-proj init experiments (same Muon-equilibration argument applies).
- Embedding / lm_head init (AdamW-trained) *might* be worth trying — those don't get NS each step so init shape could persist longer.
- Track `‖ZZ^T − I‖_F` after NS step in first ~100 steps to quantify NS equilibration speed across different init conditions.

**Conclusion:** Clean negative. Closed. Edward reassigned to PR #115 (Muon² bias correction).

---

## 2026-05-16 03:40 UTC — PR #96: Muon² LR retune (alphonse) — CLOSED negative

**Hypothesis:** Sweep Muon² learning rate ∈ {0.030, 0.0375, 0.040} on the merged baseline to find an improved LR.

| Arm | NANOGPT_MUON_LR | W&B run | val/loss @ 3350 | first_step_to_target | Δ vs baseline |
|-----|-----------------|---------|----------------:|---------------------:|--------------:|
| A | 0.030 | `exqlcpdt` | 3.27815 | 3300 | +0.00155 (worse) |
| B | 0.0375 | `mbochr63` | **3.27709** | 3300 | +0.00049 (worse) |
| C | 0.040 | `e6p4iw14` | 3.27982 | 3350 | +0.00322 (worse) |
| baseline (lr=0.035, n=2) | 0.035 | merged | 3.2766 | 3275 | — |

**Stat-sig check on best arm (B, n=1):** (3.28 − 3.27709) × √1 = 0.00291 ≪ 0.004 threshold. Not stat-sig.

**Diagnostic finding — Muon² LR is on the 0.035 peak**: The U-shape (3.27815 → 3.27709 → 3.27982 across lr 0.030 → 0.0375 → 0.040) suggests a shallow interior minimum near 0.0375, but the depth (Δ ≈ 0.001) is within seed noise. Combined with merged baseline at lr=0.035, this confirms the Muon² LR optimum is robust in {0.035, 0.0375}.

**Wave 2 plateau implication**: With LR, init, warmup, EMA, and (so far) cooldown_frac all closing as negatives, the merged Muon² baseline hyperparameters sit at a robust local optimum. Scalar hyperparameter retuning is exhausted as a path to merge — wave 3 must use mechanism stacks.

**Conclusion:** Clean negative on LR retune. Closed. Alphonse reassigned to PR #117 (Trust-region Muon² — per-layer update norm cap, complementary to NS orthogonalization).

## 2026-05-16 07:22 — PR #102: LR warmup sweep (fern)

- **Branch:** g1r4-fern/lr-warmup-sweep
- **Hypothesis:** LR warmup (0 → 50 → 100 → 200 steps) helps Muon² settle by preventing large early updates
- **Results:**

| Arm | warmup steps | W&B run | val/loss | first_step |
|-----|-------------|---------|----------|-----------|
| A | 0 (baseline) | qn0d50o2 | 3.27699 | 3300 |
| B | 50 | ysomsvug | 3.28063 | -1 |
| C | 100 | khagy2bs | 3.28153 | -1 |
| D | 200 | ace7lfl3 | 3.28084 | -1 |

- **Analysis:** Monotone negative. Each warmup arm strictly worse than no-warmup. Arms B/C/D all fail to cross val<3.28 threshold. The warmup hypothesis is falsified — Newton-Schulz already provides early-step directional stability (edward #92 finding: NS re-orthogonalizes within ~50 steps), so LR warmup just delays the productive high-LR window without providing additional stability. **CLOSED negative.**
- **Impact:** Closes the LR-schedule axis in wave 2. Combined with LR retune (#96) also negative, the schedule space is exhausted.

## 2026-05-16 09:30 — PR #104: Polyak EMA weight averaging at eval (frieren)

- **Branch:** g1r4-frieren/polyak-ema-eval
- **Hypothesis:** Polyak EMA of model weights at eval time reduces val/loss without touching training dynamics
- **Results:**

| Arm | EMA decay | W&B run | val/loss (live) | val/loss_ema | fs_live | fs_ema |
|-----|-----------|---------|-----------------|--------------|---------|--------|
| A | 0.99 | gwr15he4 | 3.27839 | 3.27859 | 3325 | 3300 |
| B | 0.999 | ry7tw0ag | 3.27736 | 3.32406 | 3300 | -1 |
| C | 0.9999 | ps773p6x | 3.27494 | 3.46152 | 3275 | -1 |
| D | 0 (disabled) | 2v0kauw1 | 3.27830 | 3.27830 | 3325 | 3325 |

- **Analysis:** Hypothesis refuted. EMA val_loss ≥ live val_loss in every arm. Live val_loss invariant across arms (3.2749-3.2784, spread within seed noise). Arm C live=3.2749 is not attributable to EMA (EMA cannot affect live trajectory). Arm D=Arm A confirms test harness. Cooldown is load-bearing — EMA averages across cooldown boundary → off-floor. **CLOSED negative.**

## 2026-05-16 10:30 — PR #117: Trust-region Muon² per-layer cap (alphonse) — CLOSED negative

- **Branch:** g1r4-alphonse/trust-region-muon
- **Hypothesis:** Cap each layer's NS-orthogonalized update by `radius × ||w||_F` to prevent rare-large excursions without touching the standard Muon² recipe
- **Results:**

| Arm | radius | W&B run | val/loss | first_step |
|-----|--------|---------|----------|-----------|
| A | 0.0 (disabled) | reugw0j8 | 3.27657 | 3275 |
| B | 0.1 | nwn9iw8o | 5.69052 | -1 |
| C | 0.3 | 7j5q7i9z | 5.69074 | -1 |
| D | 1.0 | sic7r90w | 5.68109 | -1 |

- **Analysis:** Arm-A reproduces merged baseline to 5th decimal (3.27657 vs 3.2766) — code path verified. Arms B/C/D all collapse onto val~5.69 within 0.003 at every step. Self-reinforcing feedback loop: cap activates at init (||u||_F ≈ ||w||_F ≈ 23-28 by construction) → shrinks updates → weights grow slow → ||w||_F stays small → cap stays tight forever. The cap design coupled to `||w||_F` is the wrong scale invariant for Muon² since NS already normalizes singular values to 1.
- **Closes off:** trust-region cap by weight-norm fraction axis. Future trust-region work should use NS-natural invariant `sqrt(min(rows,cols))` with c>1 to clip only rare excursions. **CLOSED negative.**

## 2026-05-16 10:30 — PR #106: Muon² cooldown_frac sweep (nezuko) — CLOSED negative

- **Branch:** g1r4-nezuko/muon2-cooldown-sweep
- **Hypothesis:** Extend fern PR #70's positive cooldown signal (vanilla Muon frac=0.5 trended positive) onto merged Muon² baseline
- **Results (after arm-C bug retry):**

| Arm | frac | W&B run | val/loss | first_step |
|-----|------|---------|----------|-----------|
| A | 0.4 | 0jnnm3mf | 3.28358 | -1 (failed) |
| B | 0.5 | 2ah2vjlr | 3.27928 | 3350 |
| C (retry) | 0.6 | 088ms8y1 | 3.27766 | 3300 |
| D | 0.7 (baseline) | 2jr85a5w | 3.27965 | 3350 |

- **Analysis:** Monotone: lower frac → worse or no-change. Frac=0.6 retry val=3.27766 indistinguishable from baseline 0.7 (range 0.00005). fern PR #70's positive frac=0.5 signal on vanilla Muon does NOT transfer to Muon². Mechanism: Muon²'s 2nd-moment preconditioning makes the cooldown tail do real, non-redundant work, so shortening it doesn't help.
- **Bonus diagnostic:** Original arms C/D both hit branch-toggle-during-launch bug (entrypoint reverted file between arms B and C → ran with hardcoded frac=0.7), accidentally giving an n=2 frac=0.7 reproduction (mean=3.27761) that agrees with merged baseline (3.276565) to 0.001 — confirming environment health. Student adopted snapshot-before-launch pattern for retry.
- **Closes off:** cooldown_frac axis on Muon². **CLOSED negative.**

## 2026-05-16 10:30 — Wave 3 dual positive signals 🎯 (in flight)

Two wave-3 mechanism stacks have produced **baseline-beating single-seed signals** awaiting confirmation:

### PR #115 — Adam-style bias correction (edward)

| Arm | bias_corr | beta2 | W&B run | val/loss | first_step | margin |
|-----|-----------|-------|---------|----------|-----------|--------|
| A | OFF | 0.999 | o5pk32x1 | 3.27928 | 3325 | +0.003 (within-noise) |
| B | ON | 0.95 | nit5n8jo | 3.27720 | 3300 | +0.001 (no step-25 divergence ✓) |
| **C** | **ON** | **0.98** | jp2lhp3r | **3.27490** | **3250** | **−0.002, −25 steps** ✨ |
| D | ON | 0.999 | swdz145t (running step 2010) | — | — | testing bias_corr at baseline beta2 |

Single-seed stat-sig at n=1: (3.28−3.2749)*sqrt(1) = 0.0051 ≥ 0.004 ✓. Predeclared confirmation rule triggered (val<3.275). 2 confirmation seeds queued at (bias_corr=on, beta2=0.98) after arm-D.

### PR #105 — Gradient clipping sweep (thorfinn)

| Arm | clip | W&B run | val/loss | first_step | margin |
|-----|------|---------|----------|-----------|--------|
| A | 0.0 (disabled) | q6law89d | 3.27890 | 3325 | +0.002 (within-noise) |
| **B** | **1.0** | ogevgg65 | **3.27546** | **3275** | **−0.001, =0 steps** ✨ |
| C | 5.0 | 3utr1m71 (running step 1800) | — | — | sweep continuation |

Single-seed stat-sig at n=1: (3.28−3.2755)*sqrt(1) = 0.00454 ≥ 0.004 ✓. 2 confirmation seeds requested at clip=1.0 after arm-C finishes.

**Wave 3 mechanism hypothesis (if both confirm)**: bias correction touches v-EMA preconditioner; grad clip touches gradient before momentum — orthogonal mechanism slots, expected to stack cleanly. Final merge sequencing TBD pending confirmation seeds.

## 2026-05-16 13:34 — PR #149: NS-iters annealing (tanjiro) — CLOSED infra-blocked (3rd confirmation)

- **Branch:** g1r4-tanjiro/ns-anneal-v2
- **Hypothesis:** Anneal NS-iters from 16 (high precision early) to 6/8 (compute-efficient late) over training; should match NS=12 quality with lower late-training cost
- **Disposition:** Student executed mandatory 100-step smoke test on **unmodified merged baseline** before launching research arms. Result: **3rd consecutive reproduction of the tanjiro-pod NaN cascade signature** identical to #97 and #108.

| Step | train/loss | grad/global_norm | nonfinite_count | val/loss |
|------|------------|------------------|------------------|----------|
| 0 | — | — | — | 10.8258 |
| 1 | 10.8258 | **232102** | — | — |
| 25 | NaN | 0.0 | **147,758,208** | — |
| 100 | NaN | 0.0 | 147,097,728 | NaN |

W&B run `viwzwtx6`. Pod UUID matches the previously-flagged 7998cef9-... pattern.

**Mechanism analysis (forwarded to issue #160)**: Step-1 grad explosion (5 orders of magnitude above healthy) on the byte-identical merged baseline → silicon-binning bf16 instability on this physical GPU. Same model, driver, and cuDNN version as healthy peers. ECC clean.

**Action**: Filed [issue #160](https://github.com/morganmcg1/modded-nanogpt-senpai/issues/160) requesting GPU rotation. Tanjiro held idle (no new assignments) until pod is healthy. Hypothesis valuable, just needs working hardware.

## 2026-05-16 13:35 — PR #120: Lookahead Muon² (askeladd) — CLOSED clean negative

- **Branch:** g1r4-askeladd/lookahead-muon2
- **Hypothesis:** Lookahead meta-optimizer (k inner steps + α slow-weight blend) temporally stabilizes Muon² without continuous EMA smoothing, preserving cooldown-phase tightening
- **Results (4 arms, all complete):**

| Arm | k | α | W&B run | val/loss | first_step | vs baseline |
|-----|---|---|---------|----------|-----------|-------------|
| A | 0 (disabled) | 0.5 | s0utj0wz | **3.27731** | 3300 | +0.001, +25 |
| B | 5 | 0.5 | f8g40nft | 3.28843 | -1 | +0.012, target FAILED |
| C | 10 | 0.5 | ykdzt3tg | 3.29011 | -1 | +0.013, target FAILED |
| D | 10 | 0.8 | cr1bq7ff | **3.27731** | 3300 | +0.001, +25 (=A to 5 decimals) |

Single-seed stat-sig at best: (3.28−3.27731)×√1 = 0.00269 < 0.004. No improvement. Arms B/C never reach val<3.28 target.

**Mechanism analysis (from student telemetry):**
Trajectory dissection revealed the mechanism: Lookahead HELPS in the pre-cooldown stable phase (B/C/D lead A at steps 500–2500) but REVERSES in the cooldown phase (A and D catch up at step 3000+). Temporal averaging with α=0.5 pulls θ_fast halfway back to θ_slow every k steps — at small LR magnitudes during cooldown, the slow-weight pullback dominates per-step descent, erasing ~one-step's-worth of progress every k steps. Arm D (α=0.8) weak enough not to harm but also provides zero net benefit.

**Closes off:** Entire temporal-smoothing meta-optimizer family — confirms same root cause as Polyak EMA #104 (frieren). Cooldown_frac=0.7 is load-bearing; any mechanism that mixes historical weights into θ during cooldown hurts. Lookahead-aware-cooldown (ramp α→1 at cooldown start) is theoretically possible but unlikely to yield net gain since stable-phase benefit is within noise.

## 2026-05-16 13:10 — PR #126: Contra-Soft Muon² element-wise (fern) — CLOSED clean negative

- **Branch:** g1r4-fern/contra-soft-muon
- **Hypothesis:** Per-element conflict detection `(grad * momentum).sign()` rescales conflicting gradient components before momentum EMA, preserving direction signal that EMA averages away
- **Results:**

| Arm | alpha | W&B run | val/loss | first_step | notes |
|-----|-------|---------|----------|-----------|-------|
| A | 0.0 (disabled) | vm4awheg | 3.27616 | 3275 | EXACT baseline reproduction |
| B | 0.5 | bf08lbjh | killed step 1644 | -1 | val=4.06 (kill-gate triggered) |
| C | 0.25 | 4jeki2ax | 3.3888 | -1 | missed target by 0.109 |
| D | 1.0 | ruln9i87 | crashed step 375 | -1 | divergence-grade slowdown |

**Telemetry — the diagnostic story**:

| Run | conflict_fraction (mean) | scaled_norm_ratio (mean) |
|-----|--------------------------|--------------------------|
| A (alpha=0) | 0.524 | 1.000 (no-op) |
| C (alpha=0.25) | 0.515 | 0.876 |
| B (alpha=0.5) | 0.486 | 0.808 |
| D (alpha=1.0) | 0.503 | 0.701 |

**Key falsification**: conflict_fraction stays ≈ 0.50 throughout training across all arms — element-wise grad signs are approximately uncorrelated with momentum signs. By the PR's own falsification criterion (need < 0.3 for real shaping), the element-wise mechanism is detecting noise, not directional conflict. The rescaling depresses gradient magnitude uniformly at random across elements, slowing learning regardless of alpha.

**Closes off**: Element-wise Contra-Soft direction-shaping axis. The mechanism behaves as a near-uniform gradient attenuator (~13/19/50% mass loss for alpha=0.25/0.5/1.0).

**Doesn't close**: Layer-aggregate Contra (assigned to fern as PR #154 follow-up). Tests whether `⟨grad_layer, momentum_layer⟩ < 0` carries more signal than per-element sign mismatch. Decisive smoke test included.

**Why record #20 likely uses layer-aggregate**: Their published "Contra-Soft-Muon" must work since it's first mechanism in their 3030-step record. Element-wise is falsified here. Most likely difference: layer-level inner-product aggregation, not per-element sign.

## 2026-05-16 15:30 — PR #105: Gradient clipping sweep (thorfinn) — 🎉 MERGED — FIRST WAVE-3 WIN

- **Branch:** g1r4-thorfinn/grad-clip-sweep
- **Hypothesis:** Standard gradient clipping (previously untested on Muon² baseline) may improve training stability and final val/loss
- **Results (5 runs total — 3-arm sweep + 2 confirmation seeds at clip=5.0):**

| Arm | clip | W&B | val/loss | first_step | vs baseline (3.2766/3275) |
|-----|------|-----|----------|-----------|---------------------------|
| A | 0.0 (disabled) | q6law89d | 3.27890 | 3325 | within-noise repro |
| B | 1.0 | ogevgg65 | 3.27546 | 3275 | −0.0011, =0 steps |
| **C** | **5.0** | **3utr1m71** | **3.27415** | **3250** | **−0.0024, −25 steps** ✨ |
| confirm-1 | 5.0 | yfhknwar | 3.27481 | 3250 | −0.0018, −25 steps ✅ |
| confirm-2 | 5.0 | j4r186ws | 3.27684 | 3300 | −0.0000, +25 steps ✅ |

**n=3 stat-sig at clip=5.0**: mu=(3.27415+3.27481+3.27684)/3=**3.27527**, (3.28−3.27527)×√3=**0.00819≥0.004** ✓ PASS. Mean fs=3266.7 vs baseline 3275 (−8.3 steps).

**Mechanism analysis (thorfinn's diagnosis)**:
- Raw global_grad_norm = 40,000–50,000 at every step (5 orders of magnitude above clip threshold)
- Both clip=1.0 and clip=5.0 are **active at every step** → not "spike clipping" but full-time gradient rescaling
- NS orthogonalization absorbs magnitude for Muon block params → clip affects **only AdamW aux groups** (embed/lm_head)
- Mechanism = constant effective-LR multiplier on AdamW aux groups (clip=5.0 → ×5 vs clip=1.0 → ×1 on rescaled gradients)
- Monotone trend clip=0→1→5 confirms optimum not yet reached → thorfinn reassigned to clip extension sweep (#165)

**Why it wins**: Muon²'s NS step normalizes updates for block params; AdamW aux groups had suboptimal effective LR. Clip=5.0 boosted aux effective LR by 5× vs clip=1.0, landing on a better operating point. This is mechanistically equivalent to an AdamW aux LR sweep.

**New merged baseline**: val=3.27527/fs=3266.7 (n=3, mean). Previous: 3.2766/3275 (n=2, exact).

**Follow-up actions**:
- Thorfinn: #165 clip extension sweep {10, 25, 50}
- Edward: #115 sent back to re-confirm bias correction on new clip=5.0 baseline

## 2026-05-16 17:32 — PR #138: Polar Express NS sweep (frieren) — CLOSED (clean negative + mechanism finding)

- **Branch:** g1r4-frieren/polar-express-ns
- **Hypothesis:** Polar Express (ICLR 2026 Oral) — adaptive polynomial Newton-Schulz replacement — could improve orthogonalization quality and training efficiency
- **Results (4 arms complete, single seed each, snapshot pre-dates #105 so NO clip=5.0):**

| Arm | NS variant | iters | W&B | val/loss | first_step | u_singular_range |
|-----|-----------|-------|-----|----------|-----------|-----------------|
| A | Classical | 12 | l5mkhlap | 3.27831 | 3325 | 0.949 |
| **B** | **Polar Express** | **12** | **2li08zef** | **3.27666** | **3275** | **0.428** |
| C | Polar Express | 8 | gv3ux65a | 3.27711 | 3300 | 0.931 |
| D | Polar Express | 6 | 4chpm8ru | 3.27977 | 3350 | 0.988 |

- **vs new merged baseline (3.27527/3266.7)**: arm-B best = +0.0014 worse. No arm beats new baseline.
- **Stat-sig check (arm-B, n=1)**: (3.28−3.27666)×√1=0.00334<0.004 → NOT stat-sig. No confirmation seeds warranted.

**Mechanistic finding (headline)**: PE=12 achieves a **2.2× tighter spectral spread** (range 0.428 vs 0.949 for NS=12) but only Δval ≈ −0.0017. **NS=12's spectral quality is already past the saturation threshold** at this benchmark scale — better orthogonalization does NOT translate to proportional val/loss reduction. The spectral-spread → val/loss curve is flat at the current operating point.

**Compute-efficiency observation**:
- PE=8 (arm-C) matches PE=12 (arm-B) within noise (Δval=0.0005, range 0.931 ≈ NS=12 at 0.949)
- PE=6 (arm-D) regresses slightly (range 0.988 > NS=12, worse orthogonalization)
- NS=8 + clip=5.0 remains testable as a compute-saving option

**Val/loss trajectory**: all 4 arms overlap to <0.002 through step 2500. Divergence ONLY in cooldown (steps 3000+). This is the key mechanistic insight → NS precision matters ONLY in cooldown phase.

**Follow-up action**: frieren assigned #176 (NS Iteration Schedule — boost NS iters during cooldown only, directly motivated by this finding).

**Closed rationale**: no arm beats new merged baseline; not a merge candidate. Clean negative with a precise mechanistic prior: "spectral spread improvement of ≥2× buys <0.002 val/loss at this scale."

## 2026-05-16 20:30 — PR #144: SOAP for AdamW aux groups (alphonse) — CLOSED clean negative

- **Branch:** g1r4-alphonse/soap-aux
- **Hypothesis:** SOAP (Shampoo + Adam) — apply Shampoo eigenbasis rotation to AdamW preconditioner on aux groups (embed, lm_head); test whether the Shampoo eigenbasis better captures the structure of sparse-token gradients than AdamW's coordinate-aligned EMA.
- **Results (4 arms complete, single seed each, snapshot pre-dates #105 — comparison is to OLD baseline val=3.2766/fs=3275):**

| Arm | SOAP target | freq | W&B | val/loss | fs | Δval vs A |
|-----|------------|------|-----|----------|----|-----------| 
| **A** | none (AdamW control) | — | lfcnprqg | **3.27595** | 3275 | (control) |
| B | embed only | 50 | 8ym5zef8 | 3.27978 | 3350 | +0.00383 |
| C | embed + lm_head | 50 | 82mx9xwy | 3.27942 | 3325 | +0.00347 |
| D | embed + lm_head | 100 | r4644zpc | 3.27947 | 3350 | +0.00352 |

- **Mechanism**: SOAP-aux causes monotonic regression in all variants. The gap grows across training (step 1000 +0.00169 → step 3350 +0.00383 for arm-B). Lowering freq from 50→100 (arm-D) does not help.
- **Mechanism interpretation**: rotating embed gradient into a Shampoo eigenbasis bleeds signal across vocab rows that should remain row-independent (sparse, token-specific). The structural cost of basis rotation outweighs the second-moment quality gain.
- **Combined with #180 closure**: any non-AdamW second-moment estimator on aux groups breaks sparse-token training. Sparsity is the load-bearing constraint, not the precision.
- **Follow-up action**: alphonse assigned #188 (AdamW aux LR sweep — first-moment / LR axis instead of second-moment basis).

## 2026-05-16 20:30 — PR #180: Adafactor for AdamW aux groups (askeladd) — CLOSED smoke timebox

- **Branch:** g1r4-askeladd/adafactor-aux
- **Hypothesis:** Adafactor (Shazeer 2018) — factored row/col second moment for embed/lm_head; test whether AdamW's full-v is over-precise for sparse aux gradients.
- **Smoke results (2 attempts per predeclared HARD TIMEBOX):**

| Run | Variant | val at step 200 | Outcome |
|-----|---------|-----------------|---------|
| 1v3appj2 | adafactor_no_mom | 10.826 | NaN throughout |
| mm816faq | adafactor_mom | 10.826 | NaN in v_r_norm, v_c_norm, factored_v, update_rms |

- **Mechanism interpretation**: factored second moment v_ij ≈ v_r * v_c / sum(v_r) likely produces near-zero denominators on sparse embed gradients (most rows have ~0 gradient most of the time), causing divide-by-tiny-number → inf → NaN cascade.
- **Combined with #144 closure**: confirms the sparsity-is-load-bearing finding. Both SOAP (rotation) and Adafactor (factorization) break sparse-token aux training; AdamW's full-v structure must be preserved.
- **Follow-up action**: askeladd assigned #189 (Muon² preconditioner eps sweep — simple 1-line config change after 3 consecutive smoke failures on complex algorithms).

## 2026-05-16 22:25 UTC — PR #163: Decoupled Momentum Reset (fern) — CLOSED clean negative

- **Branch:** g1r4-fern/dmr
- **Hypothesis:** Decoupled Momentum Reset — periodically zero Muon's momentum buffer every K steps (with optional residual decay) to break the persistent grad·momentum < 0 staleness signal observed in #154 (which found ~90% of steps have grad·momentum < 0 under Muon²). Test whether erasing stale momentum allows the optimizer to re-align with current gradient.
- **Results (4 arms complete, single seed each, vs merged baseline val=3.27527/fs=3266.7):**

| Arm | Config | val/loss | fs | Δval vs A (control) | vs merged baseline |
|-----|--------|----------|----|---------------------|--------------------|
| **A** | no reset (control) | **3.2780** | 3300 | (control) | +0.0027 |
| B | K=50 (frequent reset, no decay) | **3.2930** | — | **+0.0150 CATASTROPHIC** | +0.0177 |
| C | K=200 (moderate reset, no decay) | 3.2811 | — | +0.0031 | +0.0058 |
| D | K=800 + 0.5× decay (best variant) | **3.2783** | 3325 | +0.0003 | +0.0030 |

- **Mechanism interpretation**: Even the best DMR variant (K=800 with 0.5× decay) is barely distinguishable from the no-reset control (+0.0003). Frequent reset (K=50) catastrophically destabilizes Muon by erasing the smoothed gradient signal NS depends on for stable orthogonalization. K=200 still regresses noticeably. **The #154 staleness signal (grad·momentum < 0 in 90% of steps) is noise-dominated under Muon's NS orthogonalization** — NS already cancels the sign-disagreement structure by projecting to the orthogonal manifold, so resetting momentum loses information rather than adding it.
- **Closure rationale**: No arm beats baseline. Best variant (D) is statistically indistinguishable from control (A) but still +0.003 worse than the merged baseline. DMR family closed.
- **Family closed**: momentum erasure / temporal-buffer reset (joins #104 Polyak EMA, #120 Lookahead under "temporal smoothing/manipulation breaks Muon cooldown").
- **Follow-up action**: fern assigned #203 (NS polynomial coefficient sweep — different mechanism axis, tests Muon²'s post-v-EMA spectrum directly via Chebyshev quintic c parameter).

## 2026-05-16 22:30 UTC — PR #145: Per-layer adaptive NS iterations (nezuko) — CLOSED clean negative

- **Branch:** g1r4-nezuko/per-layer-ns
- **Hypothesis:** Per-layer adaptive NS iteration count — use sigmoid-controlled per-layer scaling between BASE and BASE+EXTRA_MAX iterations, gated on local layer-wise NS convergence rate, to spend iterations where they matter most (different layers have different spectrum-tightening needs).
- **Results (4 arms complete, single seed each, vs merged baseline val=3.27527/fs=3266.7):**

| Arm | Config (BASE/EXTRA_MAX → effective NS) | val/loss | fs | vs baseline |
|-----|-----|----------|----|-----| 
| A | BASE=12 / EXTRA_MAX=0 → NS=12 (control) | 3.27841 | 3300 | +0.0031 |
| B | BASE=12 / EXTRA_MAX=4 → NS=16 (saturated) | **3.27992** | 3325 | +0.0046 |
| C | BASE=12 / EXTRA_MAX=2 → NS=14 (saturated) | 3.27761 | 3300 | +0.0023 (within noise) |
| D | BASE=6 / EXTRA_MAX=12 → NS=18 (saturated, zrrqch4i) | 3.41 | — | DEGRADED |

- **Mechanism interpretation**: The sigmoid-controlled per-layer policy **degenerated to uniform NS for every weight matrix** (sigmoid saturated at gate=1.0 for all layers; variance across layers = 0). What was intended as adaptive per-layer became a uniform NS-iter sweep of {12, 14, 16, 18}. Under that effective interpretation:
  - NS=12-14 near-optimal (within noise of each other)
  - NS=16 monotonically worse (+0.0015 vs NS=12)
  - NS=18 catastrophically degraded (val=3.41 at midtraining)
- **Cross-reference**: This converges with frieren #138 (NS=12 spectral quality saturates, NS=8 already at the saturation knee) and tanjiro #75 (NS=8 floor — fewer iters fail). The local optimum is **NS=12-14**.
- **Closure rationale**: Per-layer policy degenerates to uniform; uniform NS≥16 monotonically worse. Adaptive policy moot. Family closed.
- **Cross-validation context**: tanjiro #185 arm-A (constant NS=14) actually FINISHED val=3.2748/fs=3250 = **BEATS baseline**, demonstrating NS=14 is the right uniform value, but the per-layer mechanism in nezuko's #145 was not the right way to reach it. The benefit comes from a uniform NS-iter increase, not from per-layer adaptation.
- **Follow-up action**: nezuko assigned #204 (Cooldown shape sweep — different mechanism axis, tests LR-decay curve shape during cooldown, orthogonal to her closed #106 which tested cooldown_frac timing).
