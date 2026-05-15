# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-15
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below current public
  best of 3030 steps (Record #20, Contra-Soft-Muon stack). Local baseline not
  yet established.

## Current focus and themes

- **Wave 1 priority:** Establish a local baseline at the starter-script
  settings (vanilla Muon + aux Adam, lr=0.035 wd=0.025, `train_steps=3350`).
  Simultaneously screen single-feature additions from the strongest historical
  records, so we know which mechanisms transfer reliably to our local hardware
  before stacking them.

## Wave 1 portfolio (1 GPU/student × 8 students)

| Student | Hypothesis | Mechanism | Public reference | Risk |
| ------- | ---------- | --------- | ---------------- | ---- |
| alphonse | Local baseline | Vanilla Muon + aux Adam | starter | low |
| askeladd | NorMuon (short-axis EMA) | per-row variance EMA after NS | #10 / #8 | low |
| edward | u/w floor (Skylight) | clamp `||u||/||w||` ≥ 0.35, no WD | #9 | low |
| fern | PMuon | streaming L^{-γ} m R^{-γ} preconditioning | #18 | medium |
| frieren | MuonH (hyperball) | scale-invariant param update, no WD | #5 | low |
| nezuko | SOAP-MLP | Shampoo eigenbasis Adam preconditioning on MLP weights | #14 | medium |
| tanjiro | Aurora | iterative row-norm equilibration before polar | #17 | medium |
| thorfinn | KL-SOAP-H | replace NS entirely with SOAP-in-Q-basis update | #19 | high |

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
