# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 09:30 UTC
- **Rank-1 holds**: PR #2405 H-EJ (askeladd β₂ pulse 0.95→0.995 @ step 820), n=4 mean @ 2850 = **3.277780**, margin 0.004440. Unchanged since 2026-06-09 09:20 UTC.
- **Wave status**: 8/8 students assigned. 13+ FALSIFIED experiments overnight in the lm_head β₂ pulse mechanism class. Plateau Protocol active — tier-shift assignments begun.

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
| #2439 | frieren | H-GG Lookahead-AdamW wrapper (k=5, α=0.5) | Just assigned — tier-shift |
| #2438 | thorfinn | H-FZ lm_head-only RI γ sweep | Running, step ~575/2890 |
| #2437 | askeladd | H-GC SAM lm_head perturbation (ρ=0.05) | Running, step ~1374/2890 |
| #2436 | nezuko | H-FW lm_head β₂ pulse timing (Arm B step720 in flight) | Arm A FALSIFIED; Arms C/D to be aborted on respawn |
| #2434 | alphonse | H-FU NS inner iter sweep (Arm B 16-iter running) | Arm A FALSIFIED at 2890 |
| #2433 | edward | H-FQ lm_head β₂ amp (Arm B tgt=0.999 running) | Arm A FALSIFIED; Arm B last hope |
| #2432 | tanjiro | H-FS lm_head LR pulse (Arm B mult=1.3 running) | Arm A FALSIFIED |
| #2429 | fern | H-FN Muon mu warmup 500 (chained; 6mol5fdn running seeds 2,3) | kqadlpxd n=2 incomplete due to 672xz9fr crash; trial-0 cross-run mean already regressing |

## Potential next directions (tier-shift queue)

1. **H-GG (assigned)**: Lookahead optimizer wrapper around AdamW (frieren)
2. **H-GH** (planned): Sophia-G optimizer for AdamW groups (second-order via Hutchinson)
3. **H-GI** (planned): Architecture pruning audit — remove Sinkhorn Arbor; show whether it's net positive on current stack
4. **H-GJ** (planned): μP-style readout reparameterization with learned temperature
5. **H-GK** (planned): Cosine restart schedule for Muon mu (rather than fixed warmup → cooldown)
6. **H-GL** (planned): Stochastic depth / DropPath schedule (currently absent)
7. **H-GM** (planned): Apollo or Lion optimizer for the embed group only (lighter than full replacement)
8. **H-GN** (planned): Focal-style hard-token loss reweighting (currently uniform CE)

Researcher-agent running in background — will commit `RESEARCH_IDEAS_2026-06-10_0835.md` with concrete implementation plans.

## Operational concerns

- **Dead student loops** (frieren, tanjiro, fern): the training subprocess kept running but the loop iteration didn't progress. K8s deployments will respawn when the pod restarts. No action needed unless they don't recover within next cycle.
- **fern run 672xz9fr crashed** at step 4991 (trial 1 never started). Replacement 6mol5fdn launched seeds 2,3.
- **Edward arm-b (gkzy9oiy) ETA**: ~1h to trial-1 completion; ~3.5h to n=2 completion.
- **Researcher-agent background task**: tier-shift hypothesis generation — will surface ~5-8 ideas with implementation costs.

## Validation policy

Per CLAUDE.md and BASELINE.md: merge only when terminal SENPAI-RESULT shows mean ≤ rank-1's mean (3.277780) at step ≤ 2850, with n≥4 robustness. n=2 winners are escalated to n=4 confirmation, NOT merged directly.

**Future advisor cycles must compute n=2 means manually from the per-trial values** — two misreads this session (08:10 H-FR "near-miss", 08:11 H-FQ "near-miss") were caused by trusting an agent's summary that confused per-trial values with n=2 means.
