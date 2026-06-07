# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~19:25 UTC (launch day +3)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (unchanged since H-W merge)

**PR #2317 (nezuko H-W): NC × Arbor + EMA-Nesterov + RI = 3.276193 at 2890 steps**
- Stack: Cautious-Muon (NC) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075)
- W&B: `vk0jtb3z`. Contract margin: 0.007615.

## Active assignments (~19:25 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~38h. |
| **#2349** | open2-frieren | H-AY: AdamW eps sweep | **n=2 Arm B in flight** — T0=3.277014 (FALSIFIED), T1 at step ~5266 of run, ETA T1 terminal ~19:35 UTC. n=4 directed if T1 rescues. |
| **#2351** | open2-fern | H-BC: Spectral radius norm | **Arm B kill directed 19:25 UTC** — Arm A FALSIFIED 3.280025 (35th lever). Awaiting SENPAI-RESULT. H-BO drafted. |
| **#2354** | open2-askeladd | H-BH: GC on Muon momentum buffer | **EARLY ABORT directed 19:20 UTC** — T0=3.284688 catastrophic (+0.0085, 17× noise floor). 33rd lever. H-BM drafted. |
| **#2355** | open2-tanjiro | H-BI: Depth-wise Muon LR | **EARLY ABORT directed 19:20 UTC** — T0=3.29223 super-catastrophic (+0.016, 32× noise floor). 34th lever. H-BN drafted. PR was stale_wip. |
| **#2356** | open2-edward | H-BJ: NS-iter × Muon LR coupling | Assigned 18:30 UTC. Arm A: NS8+LR×1.04. Arm B: NS16+LR×0.97. Awaiting student smoke + n=2. |
| **#2357** | open2-thorfinn | H-BK: Cosine warm-restart Muon LR at step 2000 | Assigned 18:40 UTC. Arm A: restart_step=2000, peak=0.5×. Awaiting student pickup. |
| **#2358** | open2-nezuko | H-BL: Embed LR decoupling | Assigned 18:40 UTC. Arm A: adam_embed_lr=0.20. Arm B: adam_embed_lr=0.45. Builds on H-BF SNR saturation finding. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 19:25 | #2351 (fern H-BC Arm B kill) | Spectral radius norm σ_target=0.7 | **CLOSURE DIRECTED** | Arm A FALSIFIED 3.280025. Arm B mechanistically worse (0.42 vs 0.60 scaling). **35th saturated lever (pending SENPAI-RESULT).** |
| 2026-06-07 19:20 | #2355 (tanjiro H-BI) | Depth-wise Muon LR decay=0.85 | **EARLY ABORT** | T0=3.29223 catastrophic (+0.016, 32× noise floor). Muon LR layer-asymmetry breaks NC × Arbor uniformity invariant. **34th lever (pending SENPAI-RESULT).** |
| 2026-06-07 19:20 | #2354 (askeladd H-BH) | GC on Muon momentum buffer | **EARLY ABORT** | T0=3.284688 catastrophic (+0.0085, 17× noise floor). Momentum-buffer centering disrupts EN slow-trajectory mean component. **33rd lever (pending SENPAI-RESULT).** |
| 2026-06-07 18:40 | #2353 (thorfinn H-BG) | PMuon + β₂-pulse | **CLOSED FALSIFIED** | T0=T1=3.278038 (identical, n=2 mean +0.001845). PMuon pre-NS5 split conflicts with NC post-NS5 equalization. **32nd lever.** |
| 2026-06-07 18:40 | #2352 (nezuko H-BF) | SNR-adaptive AdamW LR | **CLOSED FALSIFIED** | T0=3.278413 (+0.002220, 4.4× noise floor). SNR saturates → flat 3× LR multiplier on all groups catastrophic. **31st lever.** |
| 2026-06-07 18:25 | #2346 (edward H-AW) | EN REST_STEPS=2300 | **CLOSED FALSIFIED** | n=4 mean 3.276256 = +0.000063, σ=0.00126 (2.5× noise floor variance blow-out). **30th lever.** Contract margin 0.007488 < rank-1's 0.007615. |

## Saturated levers count: 32 (+ 3 pending formal close = projected 35)

(Levers 1-29 unchanged.)

30. **EN REST_STEPS=2300 (H-AW)** — n=4 mean +0.000063 with variance blow-out σ=0.00126.
31. **SNR-adaptive AdamW LR (H-BF)** — T0 catastrophic +0.002220; SNR saturation degenerates to flat 3× LR multiplier.
32. **PMuon + β₂-pulse (H-BG)** — T0=T1 identical +0.001845. Momentum-state oscillation on Muon uniformly harmful.
33. **GC on Muon momentum buffer (H-BH)** [pending SENPAI-RESULT] — T0 catastrophic +0.0085. Closes GC-on-Muon family (H-AT raw grad already closed).
34. **Depth-wise Muon LR (H-BI)** [pending SENPAI-RESULT] — T0 catastrophic +0.016. Layer-asymmetric LR breaks NC × Arbor uniformity invariant.
35. **Spectral radius norm post-NS5 (H-BC)** [pending SENPAI-RESULT] — Arm A FALSIFIED 3.280025. Post-NS5 update spectrum concentration is the wrong direction.

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |

## Strategic context (deep plateau)

We are now **35 projected saturated levers and 2 failed direction families** into a deep plateau. This cycle closed 3 more (H-BH momentum-GC, H-BI depth-wise LR, H-BC spec-norm) — all by clean catastrophic FALSIFIED at T0 (no need for T1). The Muon-side experimental space is heavily saturated; the productive frontier is now **AdamW-side decoupling**.

**AdamW decoupling decomposition (current wave):**
- **H-AY (frieren, in-flight)**: AdamW eps scalar — Arm A FALSIFIED, Arm B T0 FALSIFIED, T1 pending.
- **H-BL (nezuko)**: embed-only LR ±50% — orthogonal to H-BF.
- **H-BM (askeladd, pending assignment)**: lm_head-only LR ±60% — orthogonal to H-BL.
- **H-BO (fern, pending assignment)**: AdamW (β₁, β₂) — global momentum/2nd-moment axis.

If all four AdamW-side hypotheses FALSIFY, the AdamW configuration is fully saturated and the productive frontier shifts to **schedule shape** (H-BK warm-restart, in flight) and **NS-iter coupling** (H-BJ, in flight).

**Aurora NS structure insight (H-BJ motivation):** The `_AURORA_K=3` outer loop × `_ns_inner` 12-iteration inner cubic poly = **36 effective NS-poly applications per step**. This joint precision × LR coupling has never been tested directly.

**KEY PENDING (next 1-2 hours):**
1. **askeladd H-BH SENPAI-RESULT** + assign H-BM (lm_head LR sweep).
2. **tanjiro H-BI SENPAI-RESULT** + assign H-BN (MUON_WEIGHT_DECAY sweep).
3. **fern H-BC Arm B kill confirmation** + assign H-BO (AdamW betas).
4. **frieren H-AY Arm B T1 terminal** (~19:35 UTC) — T0=3.277014, need T1 for n=2 decision.
5. **edward H-BJ smoke + n=2 launch**.

## Queued hypotheses (drafts ready)

- **H-BM**: `lm_head` LR sweep (askeladd) — `/tmp/h-bm-askeladd-body.md`
- **H-BN**: MUON_WEIGHT_DECAY sweep (tanjiro) — `/tmp/h-bn-tanjiro-body.md`
- **H-BO**: AdamW (β₁, β₂) sweep (fern) — `/tmp/h-bo-fern-body.md`

## Next-wave hypotheses (for next-next idle students)

- **H-BP**: Muon `MU` (momentum coefficient) sweep — current 0.95, test 0.90 / 0.98.
- **H-BQ**: EN `lookahead_stepsize` sweep — never ablated against rank-1 stack.
- **H-BR**: NS5 cubic polynomial coefficient retune (alternative (3, -3, 1) candidates).
- **H-BS**: AdamW per-group weight decay (currently all 0) — non-zero on scalars only.

## Open Operational Items

- **Alphonse pod broken** (Issue #2319 ~38h). No new assignment until pod restored.
- **PR #2351** (fern H-BC) — awaiting student kill confirmation + SENPAI-RESULT to formally close.
- **PR #2354** (askeladd H-BH) — awaiting student abort SENPAI-RESULT.
- **PR #2355** (tanjiro H-BI) — awaiting student abort SENPAI-RESULT. PR was stale_wip — student check needed.
- **Frieren H-AY Arm B** — T0=3.277014 FALSIFIED, T1 in flight ETA ~19:35 UTC. Decision pending T1.
