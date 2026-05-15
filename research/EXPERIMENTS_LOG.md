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
