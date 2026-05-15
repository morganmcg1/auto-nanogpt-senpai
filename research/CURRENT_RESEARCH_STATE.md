# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-15 (early afternoon)
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below current public
  best of 3030 steps (Record #20, Contra-Soft-Muon stack). Local baseline not
  yet established — the alphonse vanilla anchor diverged (see below).

## Current focus and themes

- **Wave 1 priority:** Establish a local baseline at the starter-script
  settings (vanilla Muon + aux Adam, lr=0.035 wd=0.025, `train_steps=3350`).
  Simultaneously screen single-feature additions from the strongest historical
  records, so we know which mechanisms transfer reliably to our local hardware
  before stacking them.

## Wave 1 observations (snapshot 2026-05-15 mid-day)

| PR | Student | Mechanism | Status | Best result so far |
| -- | ------- | --------- | ------ | ----------------- |
| #59 | alphonse | vanilla Muon | **DIVERGED** — step-1 gnorm 234K, NaN by step 25; sent back | n/a |
| #61 | askeladd | NorMuon short-axis | training, step 1500, val 3.52 | n/a |
| #63 | edward | u/w floor | **reached target**, step 3275, val 3.2781 (n=1, margin 0.0019 < 0.004) | 3275 (n=1) |
| #64 | fern | PMuon | training, step 1300, val 3.56; bug-fix landed in PR | n/a |
| #65 | frieren | MuonH hyperball | **DIVERGED** (same pattern as alphonse) | n/a |
| #67 | nezuko | SOAP-MLP | training, step 75 (just restarted) | n/a |
| #68 | tanjiro | Aurora + Contra-Muon | **reached target**, step 3175, val 3.2744 (n=1, margin 0.0056 ≥ 0.004) ✓ stat-sig | **3175 (n=1)** ★ |
| #69 | thorfinn | KL-SOAP-H | training, step 1890, val 5.68 | n/a |

## Key cross-cutting issues found in wave 1

1. **`sample_tensor` linspace bug** (records/track_3_optimization/train_gpt_simple.py:184):
   `torch.linspace(0, numel-1, k)` in fp32 produces an out-of-range index for
   tensors with > 2^24 elements, crashing the first histogram log via a CUDA
   assert. Originally caught by g1r1-fern and g1r1-tanjiro. Fix is a
   two-character change (`dtype=torch.float64` + `.clamp_(max=numel-1)`).
   Both their PRs include the patch; we'll inherit it when one of them merges.

2. **Step-1 gradient explosion on vanilla starter for some students.** PRs #59
   (alphonse, vanilla) and #65 (frieren, MuonH) both show gnorm ~10^5 at step 1
   and 100% NaN gradients by step 25, while PRs #61, #63, #64, #67, #68, #69
   train cleanly on the same script. Suggests an environment- or pod-specific
   issue, not a code issue. Investigation pending — both PRs sent back with
   diagnostic instructions.

## Likely Wave 2 directions (after wave-1 closure)

- **Merge order if confirmed:** tanjiro Aurora+Contra-Muon (3175 steps,
  stat-sig) → then layer u/w floor and NorMuon if those confirm. Edward needs
  n>=3 seeds to clear the stat bar.
- **Stacking targets:**
  - Aurora + Contra-Muon + NorMuon short-axis (combines tanjiro's win with
    askeladd's mechanism)
  - Aurora + Contra-Muon + SOAP-MLP (closer to record #14 / #16)
  - Soft-Muon mechanism (singular-value shrinkage p=0.1) blended in cooldown
    (record #20)
- **Schedule levers:** power-law cooldown `c * (t_end - step)^1.2` instead of
  linear (record #20 schedule)
- **Per-module init std** tuning, especially for proj layers
- **MuLoCo outer Nesterov SGD** wrapper (record #13)
- **PSGD-Kron** baseline (track-3 README mentions `lr=0.0005, wd=0.625`)
- **Investigation track:** root-cause the step-1 gnorm explosion; if
  reproducible across env, a baseline-level gradient clip floor is on the
  table (with explicit advisor sign-off to keep within benchmark contract).

## Wave 1 portfolio (1 GPU/student × 8 students) — assigned 2026-05-15

| PR | Student | Hypothesis | Mechanism | Public reference | Risk |
| -- | ------- | ---------- | --------- | ---------------- | ---- |
| #59 | alphonse | Local baseline | Vanilla Muon + aux Adam (`lr=0.035 wd=0.025 steps=3350`) | starter | low |
| #61 | askeladd | NorMuon (short-axis EMA) | per-row variance EMA after NS | #10 / #8 | low |
| #63 | edward | u/w floor (Skylight) | clamp `||u||/||w||` ≥ 0.35, no WD | #9 | low |
| #64 | fern | PMuon | streaming L^{-γ} m R^{-γ} preconditioning | #18 | medium |
| #65 | frieren | MuonH (hyperball) | scale-invariant param update, no WD | #5 | low |
| #67 | nezuko | SOAP-MLP | Shampoo eigenbasis Adam preconditioning on MLP weights | #14 | medium |
| #68 | tanjiro | Aurora + Contra-Muon | iterative row-norm equilibration before polar | #17 | medium |
| #69 | thorfinn | KL-SOAP-H | replace NS entirely with SOAP-in-Q-basis update | #19 | high |

## Logic of this portfolio

- **Exploitation slot (alphonse):** Needed because we have no local anchor.
  Without a baseline `val/loss` curve at the starter settings, we cannot judge
  follow-up runs.
- **Single-feature additions (askeladd, edward, frieren, tanjiro):** Each
  isolates one mechanism so we learn what individually contributes. Stackable
  in Wave 2.
- **Preconditioner exploration (fern, nezuko, thorfinn):** Three different
  preconditioning strategies — streaming covariance (PMuon), Shampoo-basis
  Adam on MLP only (SOAP-MLP), and Shampoo-basis Adam replacing the entire NS
  polar step (KL-SOAP-H). This balances safer subset-application against the
  more radical full replacement.

## Likely Wave 2 directions (depending on Wave 1 outcomes)

- Stack the winners: e.g. NorMuon + u/w floor (Record #11), then add SOAP-MLP
  (Record #14), then SOAP-attn trust gate (Record #16).
- Soft-Muon mechanism (singular-value shrinkage with p≈0.1) blended in
  cooldown (Record #20).
- Power-law cooldown schedules: `c * (t_end - step)^1.2` instead of linear.
- Per-module init std tuning (attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031),
  applied with hyperball variants.
- MuLoCo-style outer Nesterov SGD wrapper (Record #13), sync_interval=20–40.
- PSGD-Kron baseline (lr=0.0005, wd=0.625) — explicitly mentioned in the
  track 3 README but never reproduced in records.
- Adam-style auxiliary group retuning when the inner optimizer changes
  drastically (e.g. with KL-SOAP-H).

## Constraints to remember

- Statistical rule `(3.28 - mu) * sqrt(n) >= 0.004` applies for final claims.
  Single-trial screening runs are fine for hypothesis filtering but a winner
  ready for merge needs predeclared step count and seed batch.
- The starter `Muon.step` ignores its stored `weight_decay`. Document this in
  hypotheses where WD matters.
- One forward-backward per optimizer step. No third-party optimizer libs in
  final code — copy needed code inline.
