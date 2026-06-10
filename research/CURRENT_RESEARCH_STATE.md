# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 10:10 UTC
- **Rank-1 holds**: PR #2405 H-EJ (askeladd β₂ pulse 0.95→0.995 @ step 820), n=4 mean @ 2850 = **3.277780**, margin 0.004440. Unchanged since 2026-06-09 09:20 UTC.
- **Wave status**: 8/8 students assigned. Tier-shift wave 2 now in progress (frieren #2440 H-GH, askeladd #2441 H-GI). Remaining 6 students on lm_head pulse mechanism final cleanup runs.

## Plateau diagnosis

The lm_head β₂ pulse family is saturated at rank-1 H-EJ. Every permutation tested shows either no improvement or uniform +0.0006-0.0013 regression at step 2850:

- H-FQ Arm A (tgt=0.997): +6.40e-4 vs rank-1 → FALSIFIED
- H-FR (lm_head + scalars combined): +8.2e-5 vs rank-1 (regression in noise) → FALSIFIED
- H-FW Arm A (pulse@step620): +1.09e-3 → FALSIFIED
- H-FO (cooldown=200): +6.80e-4 → FALSIFIED
- H-FA (staircase peak), H-FB (staircase ascent), H-FD (per-group embed), H-FE (AMSGrad), H-FF (joint β₁×β₂), H-FH (adaptive CD), H-FI (EN-γ anneal), H-FK (Muon SWA), H-FJ (?): all FALSIFIED
- H-FN (Muon mu warmup 500): trial-0 cross-run mean @ 2850 already +1.7e-3; will FALSIFY at n=2

## Most recent human directive (issue #2388, 09:20 UTC)

Human asked "how are they looking now?" — replied with fleet status + 13 FALSIFIED summary + tier-shift action. Note: skill-forked answer claimed fern trial 1 hit valid @ step 2825 — this is INCORRECT. Verified: fern kqadlpxd trial 1 first crosses n=1 thresh at trial-relative step 2876, not 2825. Correction pending on issue thread.

## Current research focus

**Strategy shift**: From lm_head β₂ pulse hyperparameter tuning to:
1. **Meta-optimizer wrappers** (Lookahead, SWA — already partially via EMA-Nesterov)
2. **Different optimizer families** (Sophia, Lion, Adan, Apollo)
3. **Init / reparameterization** (LSUV, μP, learned readout temperature)
4. **Architecture pruning** (test whether Sinkhorn Arbor / EMA-Nesterov are net positive)
5. **Schedule restarts** (cosine restarts, mu cycling)
6. **Token-level loss reweighting** (focal-style, hard-token mining)

## Live in-flight wave

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| #2440 | frieren | H-GH Stack ablation — remove Sinkhorn Arbor / EMA-Nesterov | Just assigned (tier-shift tier 4 diagnostic) |
| #2441 | askeladd | H-GI lm_head soft-cap cap=30 / μP output scaling | Just assigned (tier-shift tier 3) |
| #2438 | thorfinn | H-FZ lm_head-only RI γ sweep | Running (step ~575/2890 @ 09:30); needs rebase before SENPAI-RESULT |
| #2436 | nezuko | H-FW lm_head β₂ pulse timing (Arm B step720) | Arm A FALSIFIED (+1.09e-3); Arm B n=2 running; ETA trial 1 ~09:38, trial 2 ~11:30 UTC |
| #2434 | alphonse | H-FU NS inner iter sweep (Arm B 16-iter, `y29yszuw`) | Arm A FALSIFIED; Arm B launched 07:55 UTC; ETA ~12:25 UTC |
| #2433 | edward | H-FQ lm_head β₂ amp (Arm B tgt=0.999, `gkzy9oiy`) | Arm A FALSIFIED (+6.40e-4); Arm B step ~1609/2890 @ 08:32 UTC; ETA ~11:00 UTC |
| #2432 | tanjiro | H-FS lm_head LR pulse (Arm B mult=1.3 running) | Arm A FALSIFIED (+1.22e-3, n=2 mean 3.27900); Arm B in flight |
| #2429 | fern | H-FN Muon mu warmup 500 (`6mol5fdn` seeds 2,3) | Seeds 2-3 running @ step ~375/2890 (09:13 UTC); trial-0 cross-run mean +1.7e-3 → will FALSIFY |

## Potential next directions (tier-shift queue)

1. **H-GG** (CLOSED — CATASTROPHIC): Lookahead-AdamW wrapper — duplicate of H-BU (zero-init lm_head amplification, +0.008)
2. **H-GH (assigned #2440)**: Stack ablation — remove Sinkhorn Arbor / EMA-Nesterov diagnostic (frieren)
3. **H-GI (assigned #2441)**: lm_head soft-cap cap=30 + μP output scaling (askeladd)
4. **H-GG** (next idle slot): Orthogonal init + LSUV calibration for Muon-managed weights
5. **H-GJ** (next idle slot): NS1-orthogonalized gradient for AdamW groups (lm_head + embed)
6. **H-GK** (planned): Cosine restart schedule for Muon mu (rather than fixed warmup → cooldown)
7. **H-GL** (planned): Stochastic depth / DropPath schedule (currently absent)
8. **H-GN** (planned): Focal-style hard-token loss reweighting (currently uniform CE)

Researcher-agent running in background — will commit `RESEARCH_IDEAS_2026-06-10_0835.md` with concrete implementation plans.

## Operational concerns

- **PR #2438 thorfinn H-FZ**: `needs_rebase` — commented asking thorfinn to rebase after run completes. Training already in flight (step ~575/2890 @ 09:30).
- **PR #2432 tanjiro H-FS Arm B**: stale_wip flag; Arm B (mult=1.3) should be running — no comment yet. Wait for results.
- **fern 6mol5fdn**: seeds 2-3 of H-FN running but cross-run trial-0 mean already +1.7e-3 → expect FALSIFY verdict.
- **Session doctrine update**: all n=2 means computed MANUALLY from per-trial values — never trust agent summarization.

## Validation policy

Per CLAUDE.md and BASELINE.md: merge only when terminal SENPAI-RESULT shows mean ≤ rank-1's mean (3.277780) at step ≤ 2850, with n≥4 robustness. n=2 winners are escalated to n=4 confirmation, NOT merged directly.

**Future advisor cycles must compute n=2 means manually from the per-trial values** — two misreads this session (08:10 H-FR "near-miss", 08:11 H-FQ "near-miss") were caused by trusting an agent's summary that confused per-trial values with n=2 means.
