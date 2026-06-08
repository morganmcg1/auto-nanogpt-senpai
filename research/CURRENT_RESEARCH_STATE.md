# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-08 ~03:55 UTC (launch day +4) — H-BN n=2 terminal (Arm B trial 1=3.275799 alone MERGE-eligible, n=2 mean 3.276590 at FALSIFIED edge); n=4 confirm authorized for tanjiro; fern H-BO n=4 at 44%; thorfinn H-CX smoke PASSED + Arm A n=2 launched; nezuko H-DA Arm S full n=1 launched; askeladd H-CA 16 step-1 crashes (advisor diagnostic standing).
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (updated ~23:30 UTC 2026-06-07, PR #2349 merged)

**PR #2349 (frieren H-AY): NC × Arbor + EMA-Nesterov + RI + eps=1e-12 = 3.276172 at 2890 steps**
- Stack: Cautious-Muon (NC) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075) + **AdamW eps=1e-12** (tightened from 1e-10)
- W&B: `521ky42j`/`nbptdumy`. Contract margin: 0.007656.

**Previous rank-1**: PR #2317 (nezuko H-W) = 3.276193 (margin 0.007615). Delta: −0.000021.

## Decision gates (rank-1 = 3.276172)

- STRONG ≤ 3.275772 → n=4 confirm → MERGE
- (3.275772, 3.276172] → MERGE-eligible → n=4 confirm
- (3.276172, 3.276572) → INCONCLUSIVE → close axis
- ≥ 3.276572 → FALSIFIED → close axis
- **Variance gate**: |T0 − T1| > 0.0008 → mandatory n=4 before any merge

## 🚨 OPEN MERGE WATCHES (parallel)

1. **Fern H-BO Arm B (β₁=0.85, β₂=0.98)** — n=2 STRONG 3.275336. n=4 confirm `i8cg4ixy` (seeds 2-3) at 44% (step 1275/2890). Terminal ETA ~06:05 UTC. PR has merge conflict — must rebase before merge.
2. **Tanjiro H-BN Arm B (MUON_WD=0.050)** — n=2 mean 3.276590 at FALSIFIED edge (across by 0.000018) BUT trial 1 alone = 3.275799 (MERGE-eligible). Spread 0.001583 > 0.0008 → n=4 confirm authorized at 03:55 UTC. Realistic upside: escape FALSIFIED to MERGE-eligible if trial 1 not a seed fluke.

## Active assignments (~03:55 UTC, 2026-06-08)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~43h+. Advisor escalation posted. No new assignment until pod restored. |
| **#2356** | open2-edward | H-BJ: NS-iter × Muon LR coupling | **Arm B n=4 confirm in flight** — `9yb9do7u` past T2 (T2 ri=3.276362), now T3. Running average (T0+T1+T2)/3 = 3.277529 → n=4 mean essentially FALSIFIED (T3 needs 3.273701 to escape). Close + assign **H-CY (NorMuon)** post-terminal. ETA ~05:20 UTC. |
| **#2360** | open2-tanjiro | H-BN: MUON_WEIGHT_DECAY sweep | **n=4 confirm authorized 03:55 UTC** (seeds 2-3). Terminal ETA ~07:00 UTC. n=2 spread 1.98× variance gate; trial 1=3.275799 alone MERGE-eligible. Speedrun contract already passes at n=2 mean 3.276590. |
| **#2361** | open2-fern | H-BO: AdamW (β₁, β₂) sweep | **🚨 ARM B n=4 confirm 44%** (`i8cg4ixy` seeds 2-3, step 1275/2890). Terminal ETA ~06:05 UTC. **MERGE WATCH — 40th positive lever candidate.** Must rebase before merge (CONFLICTING). |
| **#2364** | open2-frieren | H-BW: EN-on-AdamW | **T0=3.276831 FALSIFIED** (+0.000659). `7lz3mqbv` T2 in flight (step ~1651/2890, ~57%). Terminal ETA ~05:40 UTC. Close + assign new hypothesis post-terminal. |
| **#2365** | open2-askeladd | H-CA: lm_head soft-warmup × higher target LR | **🚨 16 STEP-1 FAILURES on smoke v3 (Option 1 floor warmup).** Diagnostic ping posted 03:24 UTC (crash trace + step-0/step-1 telemetry + impl diff request). Pod healthy 1/1, GPU idle. Awaiting student response. If silent past 05:00 UTC → abort H-CA, assign alt. |
| **#2366** | open2-thorfinn | H-CX: RI capture_step timing sweep (2250 vs 2500) | **Smoke PASSED + Arm A n=2 launched 03:45 UTC.** torch 2.10→2.11 cu130 fix in PR (Blackwell NaN regression). Smoke ri=3.337 (proxy). Arm A capture=2250 ETA ~07:15 UTC. |
| **#2367** | open2-nezuko | H-DA: FINAL_LR_POWER sweep | **Arm S recal p=1.2 smoke PASSED** (val/loss 4.175 at step 200, formula validated). Full Arm S n=1 (`z7byinfk`) at ~9.5% (step 275). Validates recalibration baseline before Arms A/B. ETA ~05:27 UTC. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-08 03:30 | **#2358 (nezuko H-BL)** | Embed LR decoupling (0.20 vs 0.45) | **CLOSED — axis closed bidirectionally** | Arm A n=2 mean 3.276713 FALSIFIED (high variance 0.001626=2.0× thr). Arm B n=2 mean 3.276266 INCONCLUSIVE (tight 0.000324). **38th lever.** Novel finding: embed_lr=0.45 COMPRESSES seed-0/1 split, embed_lr=0.20 PRESERVES it. Direction-dependent seed-split behavior. |
| 2026-06-08 01:30 | #2362 (thorfinn H-BU) | Lookahead on AdamW groups | **CLOSED FALSIFIED** | Arm A T0=3.28440 CATASTROPHIC (+0.00823). Zero-init layers amplified by k=5 fast-weight steps. **39th lever.** |
| 2026-06-07 23:30 | #2349 (frieren H-AY) | AdamW eps=1e-12 | **🏆 MERGED** | n=4 Arm B confirm 3.276172 → new rank-1. eps tightened from 1e-10. |
| 2026-06-07 19:35 | #2351 (fern H-BC) | Spectral radius norm σ_target=1.0/0.7 | **CLOSED FALSIFIED** | Arm A n=2 mean 3.280025 (+0.004). **35th lever.** |
| 2026-06-07 19:30 | #2355 (tanjiro H-BI) | Depth-wise Muon LR decay=0.85 | **CLOSED FALSIFIED** | T0=3.29223 catastrophic. **34th lever.** |
| 2026-06-07 19:26 | #2354 (askeladd H-BH) | GC on Muon momentum buffer | **CLOSED FALSIFIED** | T0=3.284688 catastrophic. **33rd lever.** |

## Saturated levers count: 39 (40th candidate pending — H-BO Arm B n=4 confirm)

Recent levers (37-39):
37. **Cosine warm-restart Muon LR at step 2000 (H-BK)** — T0=3.287374 (+0.011, 22× noise floor). Invariant #5 confirmed.
38. **Embed-only LR ±50% (H-BL)** — bidirectional axis closure. Arm A 0.20 (33% down) FALSIFIED +0.000541 high variance. Arm B 0.45 (50% up) INCONCLUSIVE +0.000094 tight. No productive embed-only LR direction within ±50%.
39. **Lookahead k=5 α=0.5 on AdamW groups (H-BU)** — T0=3.2844 CATASTROPHIC (+0.0082).

**40th candidate (~05:00-06:00 UTC):** H-BO Arm B (β₁=0.85, β₂=0.98) — n=2 STRONG 3.275336 pending n=4 confirm with seeds 2-3. If holds, REPLACES canonical (0.8, 0.99) tuning from PR #309.

## Key mechanism table (NC × Arbor + RI + eps=1e-12 stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |
| + eps=1e-12 (AdamW) | **−0.000021** | Borderline — cross-PR seed pattern complicates attribution |

## Cross-PR seed pattern observation

**Seed 0 / 1 split confirmed across H-AY (eps), H-BL Arm A (embed_lr=0.20), but BROKEN by H-BL Arm B (embed_lr=0.45) and by H-BO Arm B T1.**

| Arm | T0 (seed 0) | T1 (seed 1) | n=2 mean |
|---|---:|---:|---:|
| H-AY Arm A (eps=1e-8) | 3.277593 BAD | 3.275574 GOOD | 3.276584 INCONCL |
| H-AY Arm B (eps=1e-12) | 3.277014 BAD | 3.275707 GOOD | 3.276361 INCONCL |
| H-BL Arm A (embed_lr=0.20) | 3.277526 BAD | 3.275901 GOOD | 3.276713 BARELY FALSIFIED |
| H-BL Arm B (embed_lr=0.45) | **3.276104** | **3.276428** | 3.276266 (split BROKEN — compressed) |
| H-BO Arm B (β₁=0.85, β₂=0.98) | 3.276597 BAD | **3.274075 EXCEPTIONAL** | 3.275336 STRONG |

**Updated reading**: seed-split is direction-dependent, not axis-wide. Some perturbations damp the spread, others amplify it. **H-BO Arm B T1=3.274075 is the strongest single-seed trial seen on this baseline** — n=4 confirm critical to disambiguate.

## Invariants confirmed (hard constraints on the stack)

1. **Muon LR uniformity across blocks** — H-BI.
2. **No DC-mode operations on Muon update path** — H-AT/H-BH.
3. **Post-NS5 update spectrum: no concentration** — H-BC.
4. **AdamW LR: no uniform multi-group boosts** — H-BF.
5. **Muon LR must be monotonic-down through step 2375 RI capture** — H-BK.
6. **(EMERGING) lm_head LR must be ≥ baseline 1/320 throughout training** — H-CA bf16 cascade discovery: warmup-from-zero silences embed gradient signal → bf16 sign-flip → NaN. Floor warmup needed.

## Queued hypotheses (next assignments for idle students)

- **H-CY** (edward, post-H-BJ close): **NorMuon-lite — per-row variance normalization.** Flag `--nor_beta2` (disabled at 1.0). Arm A=0.99, Arm B=0.95. Post-NS5 row-wise second-moment normalization. OPTIMIZER-STATE MECHANISM.
- **H-CZ** (tanjiro, post-H-BN close): **EN rest_steps earlier disable.** Flag `--ema_nesterov_rest_steps` (default 1950). H-AW tested 2300 (FALSIFIED). Test earlier: Arm A=1500, Arm B=1200. SCHEDULE.
- **(H-DA assigned to nezuko PR #2367 03:30 UTC)** FINAL_LR_POWER sweep — schedule mechanism.

## Longer-term hypotheses

- **H-DB**: Aurora K sweep (`--aurora_k` 1 vs 5 vs default 3). Row-balance iterations.
- **H-BQ**: EN `lookahead_stepsize` sweep (never ablated vs rank-1 stack).
- **H-BR**: NS5 cubic polynomial coefficient retune (`(3, -3, 1)` alternatives).
- **H-BT**: Embed × lm_head joint LR ratio sweep. SCALAR — lower priority.
- **H-BV**: SWA on AdamW groups (checkpoints post step 2000, average before RI capture). MECHANISM.
- **H-BP**: Muon momentum MU sweep (0.90/0.98 vs default 0.95). SCALAR — lower priority.
- **H-DC** (NEW post H-BL): **Embed-only beta ablation** — β₁_embed, β₂_embed independently from {lm_head, scalars}. Hold pending H-BO n=4 result. If fern's (0.85, 0.98) merges uniformly, per-group betas become next axis.

## Open Operational Items (~03:30 UTC)

- **Alphonse pod broken** (Issue #2319 ~44h). Advisor escalation posted. Awaiting human action.
- **Edward H-BJ Arm B n=4 confirm** (seeds 2-3): self-launched per variance escalation. ETA ~05:00 UTC → close PR #2356 + assign H-CY.
- **Tanjiro H-BN Arm B T1**: ETA ~03:36 UTC. T0 FALSIFIED. Likely close + assign H-CZ.
- **Fern H-BO Arm B n=4 confirm** (seeds 2-3): authorized at 03:30 UTC. **🚨 MERGE WATCH** at ~05:30 UTC.
- **Nezuko H-DA pickup** (PR #2367): just assigned. Expect smoke launch within 30 min.
- **Frieren H-BW T0**: terminal ETA ~02:55 UTC. Then T1 likely chains.
- **Thorfinn H-CX smoke**: ETA ~03:20 UTC after torch fix landed.
- **Askeladd H-CA**: green-lit Option 1 floor warmup at 03:30 UTC. Smoke v3 expected ~04:00 UTC.

## Standing directive (preserved verbatim)

> Do not spend the whole run on scalar hyperparameter tuning. Retune LR/WD/betas when needed to make a new mechanism fair, but bias toward optimizer-state mechanisms, preconditioners, schedule/readout ideas, pruning of complex stacks, and principled combinations of #1532/#1614 with public SOTA lineages.

This cycle satisfies the directive: H-CA (lm_head warmup mechanism), H-CX (RI capture timing — schedule), H-DA (FINAL_LR_POWER — schedule), H-BW (EN-on-AdamW — optimizer-state), pending H-CY (NorMuon — optimizer-state), H-CZ (EN rest_steps — schedule).
