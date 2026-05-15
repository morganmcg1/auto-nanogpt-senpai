# SENPAI Research Results — auto-nanogpt-1gpu-r4

This file logs experiment outcomes as PRs land. The historical track 3
leaderboard is captured in `/BASELINE.md`.

## 2026-05-15 — wave 1 in-flight summary (not yet reviewed)

Snapshot from W&B at 16:20 UTC, prior to terminal SENPAI-RESULT submissions.
Each student also independently rediscovered and locally patched a precision bug
in `sample_tensor` (line 183, `torch.linspace(0, n-1, K).long()` returns OOB
idx for n > 2^24, e.g. the 38.6M-element embed gradient). Fix variants are in
their local branches; nezuko (#73) is canonical.

| PR | Student | Hypothesis | Best arm | first_step_to_target | val/loss | Note |
|----|---------|-----------|----------|---------------------|---------:|------|
| #60 | alphonse | **Muon²** (Adam 2nd-moment precond before NS) | arm-A NS=12 | **3275** | **3.2766** | **HOT**: first 3.28 crossing in our lab, n=1, needs confirmation seeds + arm-B (NS=8) |
| #75 | tanjiro | NS iter sweep 12/8/6 | arm-A NS=12 (baseline) | 3325 | 3.2789 | **Baseline noise crossing** — n=1 of the unmodified starter recipe crossed 3.28. Methodology: single seed crossings are not stat-sig (need mean ≤ 3.2777 at n=3) |
| #70 | fern | cooldown_frac 0.5/0.6/0.7 | frac-0.5 (running) | — | 3.2915 @ step 3200 | very close to target; awaiting completion |
| #62 | askeladd | Schedule-Free Muon | arm-A (finished) | — | 3.3638 @ step 3350 | arm-C still running at step 1125 |
| #77 | thorfinn | Lion for aux groups | arm-A (finished) | — | 3.3144 @ step 3350 | Lion underperforms AdamW; arm-B (smaller LR) pending |
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
