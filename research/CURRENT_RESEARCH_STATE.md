# SENPAI Research State (auto-nanogpt-1gpu-r2)

- **2026-05-20 03:40 UTC — Cycle 70: alphonse #533 stack-pruning assigned; tanjiro #534 Shampoo-lmhead assigned; #500 WD_SCALARS CLOSED; #515 AdEMAMix CLOSED; SWA n=2 launched; askeladd T3 running**

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
| #534 | **tanjiro** | **Shampoo-lmhead right-factor (2 arms n=1)** | Just assigned | TBD |
| #533 | **alphonse** | **Stack pruning ablation (3 arms n=1)** | Just assigned | ~08:30 UTC |
| #529 | frieren | Per-group AdamW eps (3 arms n=1) | Disabled-check run 2 starting | TBD |
| #527 | fern | NAdamW (Dozat 2016, fresh) | Disabled-check done; awaiting arms | TBD |
| #524 | thorfinn | SWA tail averaging WINDOW=150 | n=2 screen launched after smoke (val+0.0015) | ~07:00 UTC |
| #523 | edward | Cautious AdamW n=2 screen | step 1650, val=3.52 | ~06:00 UTC |
| #494 | **nezuko** | **MUON_LR=0.04 n=4 confirm** | T2 step 1350 (43%); T3 pending | ~06:00 UTC |
| #493 | **askeladd** | **ADAM_EPS=1e-8 n=4 confirm** | T3 step 1909/3175 (60%) | ~04:10 UTC |

## Top merge candidates (priority order)

1. **ASKELADD #493 ADAM_EPS=1e-8** ⭐ — T3 step 60%, T2 val=3.27114/ffs=3025. n=4 strict pass needs T3 val ≤ 3.271552 AND T3 ffs ≤ 2999 (3000). Terminal ETA ~04:10 UTC.
2. **NEZUKO #494 MUON_LR=0.04** ⭐ — n=4 T2 step 43%. T2+T3 need ≥1 ffs=3000 AND mean val < 3.271388. Terminal ETA ~06:00 UTC. **Orthogonal to askeladd — both can merge.**

## Mechanism categories (cycle 70)

- **2 axes on n=4 confirm path** (MUON_LR=0.04, ADAM_EPS=1e-8): both val=PASS at n=2, ffs ties baseline floor. Orthogonal mechanisms — both can merge if n=4 passes.
- **2 fresh mechanism screens** (Cautious AdamW n=2, Shampoo-lmhead n=1): both AdamW-group modifications, orthogonal to each other and to Muon stack.
- **2 fresh mechanism pending pickup** (NAdamW fern, per-group eps frieren): await plumbing/disabled-check phase.
- **Stack pruning ablation** (alphonse): tests CONTRA_MUON, MU_WARMUP, ATTN_SOAP in isolation. First systematic pruning of mandatory stack.
- **SWA n=2** (thorfinn): slight regression at smoke (val+0.0015), n=2 needed to confirm/falsify.
- **CLOSED this cycle**: WD_SCALARS (flat optimal), AdEMAMix (horizon incompatible), SCALARS_LR (flat optimal), β1/β2 sweeps.

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
