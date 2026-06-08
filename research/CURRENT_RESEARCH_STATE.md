# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-08 ~06:05 UTC (launch day +4) — **edward H-BJ CLOSED FALSIFIED** (Arm A n=2=3.277806, Arm B n=4=3.277618 = 40th saturated lever), **edward H-CY (NorMuon-lite) ASSIGNED as PR #2369**; **nezuko H-DA Option 1 abort signed off** (Arm S recal n=1=3.283095 +0.0069 vs rank-1, recalibration too disruptive — awaiting seed=1 terminal ~07:35 UTC then close + assign H-DH SWA-EMA pre-drafted); tanjiro H-BN n=4 confirm `qq89qmbd` running (ETA 07:00 UTC); frieren H-BW Arm B γ=0.95 in flight (ETA ~07:55 UTC); fern H-BO n=4 MERGE WATCH (ETA ~06:30 UTC, 41st-positive-lever candidate); askeladd H-CA Arm A n=2 `9hld96fr` ETA ~07:55 UTC; thorfinn H-CX Arm A T0 `lt5ggymy` ETA ~07:15 UTC.
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

## Active assignments (~06:05 UTC, 2026-06-08)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~45h+. Advisor escalation posted (round 4). No new assignment until pod restored. |
| **#2369** | open2-edward | **H-CY: NorMuon-lite — per-row update-norm EMA** | **NEW ASSIGNMENT (~05:55 UTC).** Post-Arbor per-row L2 norm EMA buffer with Frobenius rescale (preserves total update magnitude). Arm A `--nor_beta2 0.99` slow EMA, Arm B 0.95 fast EMA. Bit-exact at `--nor_beta2 1.0`. Reference: arxiv 2510.05491 (Li et al., Oct 2025). Per standing directive: **post-NS5 optimizer-state mechanism**. |
| **#2360** | open2-tanjiro | H-BN: MUON_WEIGHT_DECAY sweep | **n=4 confirm in flight** — `qq89qmbd` (seeds 2-3). Terminal ETA ~07:00 UTC. n=2 spread 1.98× variance gate; trial 1=3.275799 alone MERGE-eligible. Speedrun contract already passes at n=2 mean 3.276590. |
| **#2361** | open2-fern | H-BO: AdamW (β₁, β₂) sweep | **🚨 T2 LANDED 3.277347** — running n=3 mean = (T0+T1 mean 3.275336 × 2 + T2 3.277347)/3 = **3.276006 MERGE-eligible band**. T3 at 68% (step 1976/2890), ETA ~06:35 UTC. For n=4 to stay MERGE-eligible T3 ≤ 3.276669 needed; for STRONG T3 ≤ 3.275069. PR has merge conflict — must rebase before merge. |
| **#2364** | open2-frieren | H-BW: EN-on-AdamW | **Arm A n=2 FALSIFIED at 3.277298**. Arm B γ=0.95 `cwes9skt` auto-launched per PR spec. ETA ~07:55 UTC. Close H-BW + assign new hypothesis post-Arm B terminal. |
| **#2365** | open2-askeladd | H-CA: lm_head soft-warmup × higher target LR | **Arm A n=2 launched** `9hld96fr` after torch 2.10→2.11 fix resolved 16 step-1 NaN failures (root cause: Blackwell bf16 bug, not mechanism). Terminal ETA ~07:55 UTC. |
| **#2366** | open2-thorfinn | H-CX: RI capture_step timing sweep (2250 vs 2500) | **T0=3.277571 FALSIFIED** (+0.001399 vs rank-1). T1 at 25% (step 726/2890), ETA ~07:30 UTC. PR needs rebase. Likely close H-CX + assign next hypothesis post-T1 (or interrupt T1 if Arm B becomes priority). |
| **#2367** | open2-nezuko | H-DA: FINAL_LR_POWER sweep | **🔴 OPTION 1 ABORT SIGNED OFF ~05:55 UTC.** Arm S recal p=1.2 n=1=3.283095 (+0.0069 vs rank-1, 7× threshold). Recalibration formula too disruptive — hardcoded `power_c` encodes hand-tuned schedule structure with implicit t_end ~2222. Seed=1 (`k6uh7bvo`) finishing for n=2 archival data (~07:35 UTC). Will close + assign **H-DH SWA-EMA on AdamW dense params** pre-drafted post-SENPAI-RESULT. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-08 05:55 | **#2356 (edward H-BJ)** | NS-iter × Muon LR coupling | **CLOSED FALSIFIED — both arms** | Arm A n=2=3.277806 (+0.001613, tight spread 0.000068). Arm B n=4=3.277618 (+0.001425, T0=3.280203 catastrophic seed-luck event; T1 alone=3.276022 MERGE-eligible single seed). Excellent variance escalation discipline caught false positive. **40th saturated lever — NS-iter × Muon LR coupling axis closed.** |
| 2026-06-08 03:30 | **#2358 (nezuko H-BL)** | Embed LR decoupling (0.20 vs 0.45) | **CLOSED — axis closed bidirectionally** | Arm A n=2 mean 3.276713 FALSIFIED (high variance 0.001626=2.0× thr). Arm B n=2 mean 3.276266 INCONCLUSIVE (tight 0.000324). **39th lever.** Novel finding: embed_lr=0.45 COMPRESSES seed-0/1 split, embed_lr=0.20 PRESERVES it. Direction-dependent seed-split behavior. |
| 2026-06-08 01:30 | #2362 (thorfinn H-BU) | Lookahead on AdamW groups | **CLOSED FALSIFIED** | Arm A T0=3.28440 CATASTROPHIC (+0.00823). Zero-init layers amplified by k=5 fast-weight steps. **38th lever.** |
| 2026-06-07 23:30 | #2349 (frieren H-AY) | AdamW eps=1e-12 | **🏆 MERGED** | n=4 Arm B confirm 3.276172 → new rank-1. eps tightened from 1e-10. |
| 2026-06-07 19:35 | #2351 (fern H-BC) | Spectral radius norm σ_target=1.0/0.7 | **CLOSED FALSIFIED** | Arm A n=2 mean 3.280025 (+0.004). **35th lever.** |
| 2026-06-07 19:30 | #2355 (tanjiro H-BI) | Depth-wise Muon LR decay=0.85 | **CLOSED FALSIFIED** | T0=3.29223 catastrophic. **34th lever.** |
| 2026-06-07 19:26 | #2354 (askeladd H-BH) | GC on Muon momentum buffer | **CLOSED FALSIFIED** | T0=3.284688 catastrophic. **33rd lever.** |

## Saturated levers count: 40 (positive 41st candidate pending — H-BO Arm B n=4 confirm)

Recent levers (37-40):
37. **Cosine warm-restart Muon LR at step 2000 (H-BK)** — T0=3.287374 (+0.011, 22× noise floor). Invariant #5 confirmed.
38. **Lookahead k=5 α=0.5 on AdamW groups (H-BU)** — T0=3.2844 CATASTROPHIC (+0.0082).
39. **Embed-only LR ±50% (H-BL)** — bidirectional axis closure. Arm A 0.20 FALSIFIED +0.000541 high variance. Arm B 0.45 INCONCLUSIVE +0.000094 tight. Direction-dependent seed-split.
40. **NS-iter × Muon LR coupling (H-BJ)** — Arm A (iter=8, LR×1.04) n=2=3.277806 (+0.001613, tight). Arm B (iter=16, LR×0.97) n=4=3.277618 (+0.001425, T0 catastrophic outlier seed 0 = 3.280203). NS5 iteration count and Muon LR not productively coupled on rank-1 stack.

**41st positive-lever candidate (~06:30 UTC):** H-BO Arm B (β₁=0.85, β₂=0.98) — n=2 STRONG 3.275336 pending n=4 confirm with seeds 2-3. If holds, REPLACES canonical (0.8, 0.99) tuning from PR #309.

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

- **(H-CY assigned to edward PR #2369 ~05:55 UTC)** NorMuon-lite — per-row update-norm EMA, post-NS5 OPTIMIZER-STATE MECHANISM.
- **H-DH** (nezuko, awaiting Arm S seed=1 SENPAI-RESULT ~07:35 UTC): **SWA-EMA on AdamW dense params (embed.weight, proj.weight) in post-RI-capture tail.** Arm A `--swa_start_step 2375 --swa_decay 0.99`, Arm B `--swa_start_step 2500 --swa_decay 0.95`. Bit-exact at default 0. Reference: Izmailov 2018 (arxiv 1803.05407). WEIGHT-SPACE EMA on readout pathway — 3 of 4 directive bias categories (optimizer-state, schedule, readout).
- **H-CZ** (tanjiro, post-H-BN close): **EN rest_steps earlier disable.** Flag `--ema_nesterov_rest_steps` (default 1950). H-AW tested 2300 (FALSIFIED). Test earlier: Arm A=1500, Arm B=1200. SCHEDULE.

## Longer-term hypotheses

- **H-DB**: Aurora K sweep (`--aurora_k` 1 vs 5 vs default 3). Row-balance iterations.
- **H-BQ**: EN `lookahead_stepsize` sweep (never ablated vs rank-1 stack).
- **H-BR**: NS5 cubic polynomial coefficient retune (`(3, -3, 1)` alternatives).
- **H-BT**: Embed × lm_head joint LR ratio sweep. SCALAR — lower priority.
- **H-BV**: SWA on AdamW groups (checkpoints post step 2000, average before RI capture). MECHANISM.
- **H-BP**: Muon momentum MU sweep (0.90/0.98 vs default 0.95). SCALAR — lower priority.
- **H-DC** (NEW post H-BL): **Embed-only beta ablation** — β₁_embed, β₂_embed independently from {lm_head, scalars}. Hold pending H-BO n=4 result. If fern's (0.85, 0.98) merges uniformly, per-group betas become next axis.

## Open Operational Items (~06:05 UTC)

- **Alphonse pod broken** (Issue #2319 ~45h). Advisor escalation posted (round 4). Awaiting human action.
- **Fern H-BO Arm B n=4 confirm** (`i8cg4ixy` seeds 2-3): **🚨 MERGE WATCH ~06:30 UTC.** Must rebase before merge. 41st-positive-lever candidate.
- **Tanjiro H-BN Arm B n=4 confirm** (`qq89qmbd` seeds 2-3): ETA ~07:00 UTC. Spread 1.98× variance gate; T1=3.275799 MERGE-eligible single seed.
- **Nezuko H-DA Arm S seed=1** (`k6uh7bvo`): ETA ~07:35 UTC → SENPAI-RESULT post → close PR #2367 + assign H-DH (SWA-EMA, pre-drafted).
- **Thorfinn H-CX Arm A T0** (`lt5ggymy`): ETA ~07:15 UTC. PR #2366 needs rebase post-terminal.
- **Frieren H-BW Arm B γ=0.95** (`cwes9skt`): ETA ~07:55 UTC. T0 alone determines close → next assignment.
- **Askeladd H-CA Arm A n=2** (`9hld96fr`): ETA ~07:55 UTC. Mechanism + floor warmup validation.
- **Edward H-CY** (PR #2369): just assigned ~05:55 UTC. Expect smoke launch within 30 min.

## Standing directive (preserved verbatim)

> Do not spend the whole run on scalar hyperparameter tuning. Retune LR/WD/betas when needed to make a new mechanism fair, but bias toward optimizer-state mechanisms, preconditioners, schedule/readout ideas, pruning of complex stacks, and principled combinations of #1532/#1614 with public SOTA lineages.

This cycle satisfies the directive: H-CA (lm_head warmup mechanism), H-CX (RI capture timing — schedule), H-BW (EN-on-AdamW — optimizer-state), H-CY (NorMuon — optimizer-state, JUST ASSIGNED), pending H-DH (SWA-EMA — weight-space optimizer-state, queued), H-CZ (EN rest_steps — schedule). Saturated H-DA (FINAL_LR_POWER — recalibration too disruptive, informative negative).
