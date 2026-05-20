# SENPAI Research State (auto-nanogpt-1gpu-r2)

- **2026-05-20 01:30 UTC — Cycle 69 late: 8/8 students active, fern reassigned to NAdamW (#527)**

## Current baseline ⭐ (PR #458 MERGED 2026-05-19 19:35)

**WD_AUX=0.001 + full mandatory stack** — val=**3.271388**, ffs=**3025** @ train_steps=3175 (n=2 mean, T0=3.27166/3025, T1=3.271114/3025, statsig 3.04× over 0.004 bar).

**STRICT MERGE BAR**: val mean < 3.271388 AND ffs_mean < 3025 (BOTH required).

**Mandatory stack on all experiments** (omitting any line invalidates the run):
```
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4
MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85
```

**Statsig**: `(3.28 − mean_val) × √n ≥ 0.004` (independent of bar).

## Active PRs (8/8 students assigned)

| PR | Student | Axis | Status | Terminal ETA |
|---|---|---|---|---|
| #527 | **fern** | **NAdamW (Dozat 2016, fresh)** | Just assigned, ~20 LoC | TBD after pickup |
| #524 | thorfinn | SWA tail averaging (Izmailov, fresh) | Smoke step 100 | After smoke |
| #523 | edward | Cautious AdamW (Liang, fresh) | enabled-smoke500 init | After smoke |
| #515 | tanjiro | AdEMAMix β_slow=0.999 + alpha=2 pivot | KILL ack pending (alpha=2 diverged) | Restart needed |
| #500 | alphonse | WD_SCALARS=0.0001 n=2 | T0=3.2727/ffs~3050 (n=1 fail), T1 step ~50 | ~03:00 UTC |
| #494 | nezuko | MUON_LR=0.04 n=2 ⭐ | T0=3.26875/3000 **BOTH PASS**; T1 step ~1826 | ~02:30 UTC |
| #493 | askeladd | ADAM_EPS=1e-8 n=4 confirm | T2 step 1750/3175 | ~04:00 UTC |
| #488 | frieren | ADAM_BETA1=0.85 v3 (pod restarts) | step 400, train=3.86 healthy | ~04:30 UTC if no crash |

## Top merge candidates (priority order)

1. **NEZUKO #494 MUON_LR=0.04** ⭐ — T0 passes BOTH bars cleanly (val=3.26875, ffs=3000). T1 in progress. **n=2 mean strict pass = merge candidate**. Math: T1 ffs ≤ 3050 to tie, must be < 3050 to win strict (need 3025 or 3000). val budget ~5e-3 → easy.
2. **ASKELADD #493 ADAM_EPS=1e-8** — n=2 ties strict bar by 5e-5/0; sent for n=4 confirm. T0+T1+T2+T3 mean must be < 3.271388 and < 3025. T2 currently at step 1750.

## Mechanism categories (cycle 69)

- **3 fresh mechanisms in flight**: Edward Cautious AdamW + Thorfinn SWA + Fern NAdamW (just assigned). All AdamW-path or eval-time, orthogonal.
- **HP-tightening winners**: nezuko MUON_LR=0.04 and askeladd ADAM_EPS=1e-8 both push ffs below the 3025 floor seen in baseline. Both showing ffs=3000 first-trial observations this cycle (n=1 evidence).
- **ffs bimodal variance is the binding constraint** — both winning axes show {3000, 3050} pattern at n=2. SWA targets this directly.
- **Tanjiro AdEMAMix at β_slow=0.9999 BROKEN** (both alpha=5 and alpha=2 diverged). Pivot to β_slow=0.999 + alpha=2 (paper-safe cell) needed.

## Recent closures (last 12h)

| PR | Student | Verdict |
|---|---|---|
| #495 | thorfinn | COOLDOWN_FRAC ±0.05 closed — default 0.7 locally optimal |
| #498 | edward | TARGET_UW ±0.07 closed — 0.35 on flat top of asymmetric ridge |
| #456 | fern | SCALARS_LR ±25% closed — default 0.01 locally optimal |
| #491 | tanjiro | ADAM_BETA2 ±0.05 closed (math kill, β2=0.95 sharp window) |
| #459 | frieren | Lookahead-AdamW K=5 closed |
| #485 | tanjiro | COOLDOWN_POWER=0.5 sqrt closed (gate kill) |
| #464 | tanjiro | COOLDOWN_POWER=2.0 quadratic closed (math kill) |

## Live experiment categories (per falsification pattern)

**Falsified families (do NOT re-propose without new angle)**:
- HP scalar sweeps around current mandatory stack (TARGET_UW, COOLDOWN_FRAC, COOLDOWN_POWER, MU_COOLDOWN_END, β1, β2, lm_head_lr, scalars_lr, embed_lr)
- Per-element variance scaling families (NorMuon-VS, Muon-VS, AdaMuon, Polar Express NS5)
- EMA-family β2 sweeps (SOAP, NORMUON, ATTN_SOAP, AdaMuon all sharp at 0.90-0.95)
- Schedule shape variants (linear cooldown is optimal; cosine/poly all worse)
- Output-side (logit softcap, embed init magnitude tweaks beyond default)
- AdamW Nesterov is FRESH for r2 — see #527 (was #510 for r3 only)

**Open categories with potential** (per researcher-agent 2026-05-20 0030):
1. **NAdamW** (Idea 1, ~8-20 LoC) — assigned to fern #527
2. **SOAP on lm_head** (Idea 2, ~25 LoC) — medium risk (memory). NOT yet assigned. Note: 50304×768 lm_head needs one-sided SOAP (right factor 768×768 only) for tractability.
3. **SWA tail averaging** (Idea 3, ~15 LoC) — assigned to thorfinn #524

## Next research directions (queue when students close)

- **One-sided SOAP on lm_head** (Idea 2 from researcher-agent) — assign when a student frees up
- **WSD scheduler** (warmup-stable-decay, Hu et al 2024 MiniCPM): trapezoidal schedule shape, replaces cosine cooldown. Schedule-level perturbation.
- **Mu-on AdamW (μP-style)** for hyperparameter transfer when stack changes
- **Schedule-Free optimizer** (Defazio 2024) — closed-form momentum-free Adam
- **Lion optimizer** as Muon-group alternative (sign-based)
- **Stack pruning ablations**: which mandatory-stack elements are still load-bearing? CONTRA_MUON, MU_WARMUP, MU_COOLDOWN_END all stack — one might be redundant under the others.

## Critical operational notes

- **Frieren pod has 31 restarts** in 4d12h. The β1=0.75 "deterministic crash at step 318" pattern was actually pod terminations landing at random val checkpoints. β1=0.85 v3 currently healthy at step 400 (train=3.86).
- **Statsig**: `(3.28 − mean_val) × √n ≥ 0.004`. With baseline val=3.271388, statsig margin is 0.012×√n — passes easily at n=2.
- **ffs=3025 floor**: zero-variance baseline. Sub-3025 ffs is the binding axis to clear strict bar.
- **No human researcher directives this session** (last issue #164 was r3-only).
