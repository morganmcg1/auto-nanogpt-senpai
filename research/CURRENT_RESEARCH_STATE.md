# SENPAI Research State (auto-nanogpt-1gpu-r2)

- **2026-05-20 09:52 UTC — alphonse #533 stack pruning CLOSED (3/3 BOUNDARY); alphonse → #564 Gradient Centralization; frieren #529 per-group eps CLOSED; frieren → #561 Lookahead; thorfinn T0 ffs=3000 BREAKTHROUGH — T1 ETA 11:05 UTC. 8/8 active.**

## Current baseline ⭐ (PR #494 MERGED 2026-05-20 06:37)

**MUON_LR=0.04** — val=**3.270288**, ffs=**3025** @ train_steps=3175 (n=4 mean, statsig 4.86×).

**MERGE BAR**: val mean < 3.270288 AND ffs_mean ≤ 3025 (ffs ties now accepted if val strictly improves; ffs MUST NOT regress).

**Mandatory stack on all experiments** (omitting any line invalidates the run):
```
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04
MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85
```

**Statsig**: `(3.28 − mean_val) × √n ≥ 0.004` (independent of bar).
**ffs floor**: 3025. Cracking to ffs≤3000 is the primary research priority.

## Active PRs (8/8 students assigned)

| PR | Student | Axis | Status | Terminal ETA |
|---|---|---|---|---|
| **#524** | **thorfinn** | **SWA tail averaging WINDOW=300 n=2** | **T0 ffs=3000 BREAKTHROUGH; T1 running at step 125** | **~11:05 UTC** |
| #557 | edward | Schedule-Free AdamW (Defazio 2024, Polyak avg) 2 arms | Just assigned; impl in progress | TBD |
| #561 | frieren | Lookahead AdamW wrapper (Zhang 2019, k=5/k=10) | Just assigned; #529 closed | TBD |
| #549 | nezuko | Muon decoupled cooldown (MUON_COOLDOWN_FRAC 0.8/0.6) | Disabled-check ✅; Arm A smoke in flight | TBD |
| #541 | askeladd | Embed init std sweep (0.5/0.1/0.02) | All 3 smokes healthy (~3.697@500); n=1 full runs authorized | ~12:00 UTC |
| #534 | tanjiro | Right-factor Shampoo on lm_head | 2nd nudge; still no disabled-check posted | TBD |
| **#564** | **alphonse** | **Gradient Centralization on AdamW group (Yong 2020, ~10 LoC)** | **Just assigned; #533 closed** | **TBD** |
| #527 | fern | NAdamW (Dozat 2016) | Arm A n=2 FAIL; Arm B T0 val=3.274/ffs=3075 WORSE; T1 foreclosed; await terminal SENPAI-RESULT | ~10:15 UTC |

## Top merge candidates / watching closely

1. **THORFINN #524 T1** — T0 hit ffs=3000 (BREAKTHROUGH vs 3025 baseline). T1 running, ETA 11:05 UTC. If T1 also ffs≤3025 → n=2 mean ffs breaks floor. Watch closely for n=2 merge decision.
2. **NEZUKO #549 Muon-cooldown-frac** — Arm A smoke in flight. Directly targets ffs floor via Muon-group LR in final convergence window. Primary targeted mechanism.
3. **EDWARD #557 Schedule-Free AdamW** — Just assigned. Polyak averaging eliminates LR cooldown timing dependence. Strong theoretical attack on bimodal ffs variance.
4. **FRIEREN #561 Lookahead AdamW** — Just assigned. Periodic slow-weights sync. ~30 LoC wrapper, different variance-reduction angle from SWA/SF.

## Mechanism categories (cycle 71 active)

- **Variance reduction / ffs floor attack** (primary priority):
  - #524 thorfinn: SWA WINDOW=300 — T0 ffs=3000 BREAKTHROUGH, T1 ETA 11:05 UTC
  - #549 nezuko: Muon decoupled cooldown frac — Arm A smoke in progress
  - #557 edward: Schedule-Free AdamW — Polyak avg eliminates cooldown timing
  - #561 frieren: Lookahead AdamW wrapper — discrete slow-weights sync k=5/10
- **Initialization sweep** (#541 askeladd): EMBED_INIT_STD ∈ {0.5, 0.1, 0.02}; all smokes healthy; n=1 full runs launched
- **Gradient-level modification** (#564 alphonse): GC zero-mean projection of grad over output dim; just assigned
- **Preconditioner on lm_head** (#534 tanjiro): right-factor Shampoo; STUCK (still no disabled-check)
- **NAdamW** (#527 fern): FAILING — Arm B T0 val=3.274/ffs=3075 worse than Arm A; T1 running, expected close

## CLOSED cycle 71 (stack status known)

- **Stack pruning**: CONTRA_MUON, MU_WARMUP, ATTN_SOAP all BOUNDARY-weakly-load-bearing (each costs +25 ffs / +0.0016-0.0025 val when removed). Keep full stack.
- **Per-group AdamW eps**: embed + lm_head + scalars all FAIL eps=1e-8; epsilon range [1e-10, 1e-8] insensitive at our LR/WD scale.

## CLOSED cycle 70-71: falsified families

- HP scalar sweeps (TARGET_UW, COOLDOWN_FRAC, β1, β2, lm_head_lr, scalars_lr, embed_lr)
- Per-element variance scaling (NorMuon-VS, Muon-VS, AdaMuon, Polar Express NS5)
- EMA-family β2 sweeps (SOAP, NORMUON, ATTN_SOAP, AdaMuon all sharp at 0.90-0.95)
- Schedule shape variants (linear cooldown optimal; cosine/poly all worse)
- **Sign-family AdamW group replacements** (Lion #538 sign-only, Cautious AdamW #523 sign-mask BOTH FAIL)
- Per-group AdamW eps (3/3 groups falsified: embed, lm_head, scalars)
- AdEMAMix (horizon incompatible), WD_SCALARS (flat optimal), NAdamW (FAILING)

## Recent closures (last 12h)

| PR | Student | Verdict |
|---|---|---|
| #533 | alphonse | Stack pruning CLOSED — CONTRA_MUON/MU_WARMUP/ATTN_SOAP all BOUNDARY (+0.0016-0.0025 val, +25 ffs each). Stack collectively load-bearing. |
| #529 | frieren | Per-group AdamW eps CLOSED — 3/3 groups (embed, lm_head, scalars) falsified; eps ∈ [1e-10, 1e-8] insensitive at our LR/WD scale |
| #538 | edward | Lion optimizer closed — val+0.024 regression, ffs=-1; sign-only update incompatible (3rd sign-family failure) |
| #493 | askeladd | ADAM_EPS=1e-8 n=4 closed — val FAIL +5e-4, ffs FAIL +6.25; T0=3000 was outlier, T1-T3 cluster at noise floor |
| #523 | edward | Cautious AdamW closed — T0 val=3.286 (+1.4% regression); sign-mask discards useful cooldown signal |
| #495 | thorfinn | COOLDOWN_FRAC ±0.05 closed — default 0.7 locally optimal |
| #498 | edward | TARGET_UW ±0.07 closed — 0.35 on flat top of asymmetric ridge |
| #456 | fern | SCALARS_LR ±25% closed — default 0.01 locally optimal |
| #491 | tanjiro | ADAM_BETA2 ±0.05 closed (math kill, β2=0.95 sharp window) |

## Live experiment categories (per falsification pattern)

**Falsified families (do NOT re-propose without new angle)**:
- HP scalar sweeps around current mandatory stack (TARGET_UW, COOLDOWN_FRAC, COOLDOWN_POWER, MU_COOLDOWN_END, β1, β2, lm_head_lr, scalars_lr, embed_lr)
- Per-element variance scaling families (NorMuon-VS, Muon-VS, AdaMuon, Polar Express NS5)
- EMA-family β2 sweeps (SOAP, NORMUON, ATTN_SOAP, AdaMuon all sharp at 0.90-0.95)
- Schedule shape variants (linear cooldown is optimal; cosine/poly all worse)
- Output-side (logit softcap, embed init magnitude tweaks beyond default)
- **Sign-family AdamW group replacements** (Lion #538 sign-only, Cautious AdamW #523 sign-mask both failed; do NOT re-propose sign-based updates)
- AdamW Nesterov is FRESH for r2 — see #527 (was #510 for r3 only)

**Open categories with potential** (per researcher-agent 2026-05-20 0030):
1. **NAdamW** (Idea 1, ~8-20 LoC) — assigned to fern #527
2. **SOAP on lm_head** (Idea 2, ~25 LoC) — medium risk (memory). NOT yet assigned. Note: 50304×768 lm_head needs one-sided SOAP (right factor 768×768 only) for tractability.
3. **SWA tail averaging** (Idea 3, ~15 LoC) — assigned to thorfinn #524

## Next research directions (queue when students close)

- **One-sided SOAP on lm_head** (Idea 2 from researcher-agent) — queue for next free student after tanjiro #534 (which is right-factor Shampoo on same target)
- **AdaFactor (Shazeer 2018)** — factorizes second moment v as row×col product; half memory, slightly different conditioning. Fresh mechanism orthogonal to all in-flight.
- **Lookahead wrapper (Zhang 2019)** — periodic slow-weights sync, wraps existing AdamW. ~30 LoC. Variance-reduction angle; different from SWA (which is tail-only).
- **Prodigy / DoG auto-LR** (Mishchenko 2023) — automatic LR adaptation, no manual LR tuning. Could improve robustness on bimodal variance.
- **Stack pruning confirmation Arm C** (alphonse #533 in-flight): if ATTN_SOAP_TRUST_THRESHOLD=1.0 also fails, stack has THREE load-bearing elements confirmed.
- **Lion / Muon-group alternative** — closed on AdamW group. NOT worth re-trying on Muon group (NS5 already provides orthogonalization which is Lion-like for matrices).

## Critical operational notes

- **Frieren pod has 31 restarts** in 4d12h. The β1=0.75 "deterministic crash at step 318" pattern was actually pod terminations landing at random val checkpoints. β1=0.85 v3 currently healthy at step 400 (train=3.86).
- **Statsig**: `(3.28 − mean_val) × √n ≥ 0.004`. With baseline val=3.271388, statsig margin is 0.012×√n — passes easily at n=2.
- **ffs=3025 floor**: zero-variance baseline. Sub-3025 ffs is the binding axis to clear strict bar.
- **No human researcher directives this session** (last issue #164 was r3-only).
