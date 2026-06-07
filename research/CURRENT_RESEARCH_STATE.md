# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~21:05 UTC (launch day +3)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (unchanged since H-W merge)

**PR #2317 (nezuko H-W): NC × Arbor + EMA-Nesterov + RI = 3.276193 at 2890 steps**
- Stack: Cautious-Muon (NC) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075)
- W&B: `vk0jtb3z`. Contract margin: 0.007615.

## Active assignments (~20:50 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~40h. Student correctly waiting for pod recycle. |
| **#2349** | open2-frieren | H-AY: AdamW eps sweep | **Arm B n=4 in flight** (`nbptdumy`). T0=3.276387 INCONCLUSIVE (+0.000194). T1 at step ~501/2890 (~17%). 3 trials remaining, ETA ~4h38m (~01:43 UTC tomorrow). |
| **#2356** | open2-edward | H-BJ: NS-iter × Muon LR coupling | **Arm A T0=3.277840 FALSIFIED**. T1 at step ~2401/2890 (~83%, ETA ~22:00 UTC). ⚠ **WATCHDOG STATUS UNCLEAR** — no Arm B main run detected on W&B as of 21:00; nudge posted. |
| **#2357** | open2-thorfinn | H-BK: Cosine warm-restart Muon LR at step 2000 | **T0=3.287374 CATASTROPHIC** (+0.011182, ~22× noise floor). Abort directive posted 21:00 UTC. Awaiting SENPAI-RESULT. **36th lever pending close.** |
| **#2358** | open2-nezuko | H-BL: Embed LR decoupling | **Arm A T0=3.277526 FALSIFIED** (+0.001333). T1 at ~50% (ETA ~21:30 UTC). Direction posted: launch Arm B (embed_lr=0.45) after T1 lands. |
| **#2359** | open2-askeladd | H-BM: lm_head LR decoupling | `vn32x4gj` step 1734/2890 (~60%). Arm A lm_head_lr=0.002. T0 ETA ~22:30 UTC. |
| **#2360** | open2-tanjiro | H-BN: MUON_WEIGHT_DECAY sweep | `9tlotgem` step 1925/2890 (~67%). Arm A WD=0.010. T0 ETA ~22:00 UTC. |
| **#2361** | open2-fern | H-BO: AdamW (β₁, β₂) sweep | `j9lofncb` step 1850/2890 (~64%). Arm A (β₁,β₂)=(0.9,0.95). T0 ETA ~22:00 UTC. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 19:35 | #2351 (fern H-BC) | Spectral radius norm σ_target=1.0/0.7 | **CLOSED FALSIFIED** | Arm A n=2 mean 3.280025 (+0.004). Post-NS5 principal direction is noise-amplified; concentrating mass onto it = double-suppression vs NC. **35th lever.** |
| 2026-06-07 19:30 | #2355 (tanjiro H-BI) | Depth-wise Muon LR decay=0.85 | **CLOSED FALSIFIED** | T0=3.29223 catastrophic (+0.016, 32× noise floor). Layer-asymmetric LR breaks NC × Arbor × NS5 uniformity invariant. **34th lever.** |
| 2026-06-07 19:26 | #2354 (askeladd H-BH) | GC on Muon momentum buffer | **CLOSED FALSIFIED** | T0=3.284688 catastrophic (+0.0085, 17× noise floor). Double DC-mode cancellation (centering + NC post-NS5) destroys EN slow-trajectory mean component. **33rd lever.** |
| 2026-06-07 18:40 | #2353 (thorfinn H-BG) | PMuon + β₂-pulse | **CLOSED FALSIFIED** | T0=T1=3.278038 identical, +0.001845. PMuon pre-NS5 conflicts with NC post-NS5. **32nd lever.** |
| 2026-06-07 18:40 | #2352 (nezuko H-BF) | SNR-adaptive AdamW LR | **CLOSED FALSIFIED** | T0=3.278413 +0.002220. SNR saturates → flat 3× LR catastrophic. **31st lever.** |
| 2026-06-07 18:25 | #2346 (edward H-AW) | EN REST_STEPS=2300 | **CLOSED FALSIFIED** | n=4 mean 3.276256 = +0.000063, σ=0.00126. **30th lever.** |

## Saturated levers count: 35 (+3 pending closure)

**Pending close imminent:**
- **edward H-BJ Arm A** (T0=3.277840 FALSIFIED, T1 ~83%)
- **thorfinn H-BK** (T0=3.287374 CATASTROPHIC, T1 abort directive posted)
- **nezuko H-BL Arm A** (T0=3.277526 FALSIFIED, T1 ~50%, then Arm B planned)

(Levers 1-29 unchanged. Recent:)

30. **EN REST_STEPS=2300 (H-AW)** — n=4 mean +0.000063 with variance blow-out.
31. **SNR-adaptive AdamW LR (H-BF)** — T0 catastrophic +0.002220.
32. **PMuon + β₂-pulse (H-BG)** — T0=T1 identical +0.001845.
33. **GC on Muon momentum buffer (H-BH)** — T0 catastrophic +0.0085. Closes GC-on-Muon family.
34. **Depth-wise Muon LR (H-BI)** — T0 catastrophic +0.016. Muon LR uniformity load-bearing.
35. **Spectral radius norm post-NS5 (H-BC)** — Arm A n=2 mean +0.004. Post-NS5 spectrum concentration wrong direction.

**Pending closure (36th):** H-BJ Arm A NS8+LR×1.04 — T0=+0.001647. T1 must be ≤ 3.274546 for MERGE band (6σ swing from T0, unlikely).

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |

## Invariants confirmed (hard constraints on the stack)

1. **Muon LR uniformity across blocks** — H-BI: layer-asymmetric LR breaks NC × Arbor × NS5 equalization invariant.
2. **No DC-mode operations on Muon update path** — H-AT/H-BH: raw-grad or momentum-buffer centering + NC post-NS5 = double DC-mode cancellation, destroys EN slow-trajectory signal.
3. **Post-NS5 update spectrum: no concentration** — H-BC: concentrating onto principal singular direction degrades, NC already biases toward orthogonal.
4. **AdamW LR: no uniform multi-group boosts** — H-BF: uniform 3× across embed/lm_head/scalars catastrophic.

## Strategic context (deep plateau — 35 saturated levers)

**AdamW decoupling decomposition** (current live wave):
- **H-AY (frieren)**: AdamW eps scalar — Arm B T1=3.275574 STRONG. n=4 confirm in flight (~02:23 UTC). **PRIMARY MERGE CANDIDATE.**
- **H-BL (nezuko)**: embed-only LR ±50% — Arm A `k6p7wqy5` step 2475/2890 (~86%), T0 ETA ~21:30 UTC.
- **H-BM (askeladd)**: lm_head-only LR ±60% — Arm A `vn32x4gj` step 225/2890 (~8%).
- **H-BO (fern)**: AdamW (β₁, β₂) — first betas ablation. Arm A `j9lofncb` step 325/2890 (~11%).

**Muon side** (current live wave):
- **H-BN (tanjiro)**: MUON_WEIGHT_DECAY sweep — Arm A `9tlotgem` step 200/2890 (~7%).
- **H-BJ (edward)**: NS-iter × Muon LR coupling — Arm A T0=3.277840 FALSIFIED, T1 in flight, watchdog auto-launches Arm B on exit.
- **H-BK (thorfinn)**: Cosine warm-restart Muon LR — `zs6jedkm` step 2600/2890 (~90%), T0 ETA ~21:15 UTC.

**Frieren H-AY n=4 confirm**: Arm B (eps=1e-12) n=2 mean 3.276361 INCONCLUSIVE with T1=3.275574 STRONG. n=4 launched per variance escalation. If mean lands sub-rank-1 → MERGE.

## Next-wave hypotheses (for next idle students)

- **H-BP**: Muon momentum (MU) sweep — current MU=0.95, test 0.90 / 0.98.
- **H-BQ**: EN `lookahead_stepsize` sweep — never ablated vs rank-1 stack.
- **H-BR**: NS5 cubic polynomial coefficient retune — `(3, -3, 1)` alternatives.
- **H-BS**: AdamW per-group weight decay (currently all 0) — non-zero on scalars only.
- **H-BT**: Embed × lm_head joint LR ratio sweep (after H-BL and H-BM close singly).

## Open Operational Items

- **Alphonse pod broken** (Issue #2319 ~40h). No new assignment until pod restored.
- **Edward H-BJ watchdog status unclear** — Arm B main run not detected on W&B. Student nudged 21:00 UTC to verify watchdog or manually launch Arm B after T1.
- **Thorfinn H-BK abort directive posted** — awaiting SENPAI-RESULT for close + next assignment (H-BU optimizer-state mechanism, NOT scalar).
- **Nezuko H-BL Arm A FALSIFIED** — let T1 finish (~21:30 UTC), then Arm B (embed_lr=0.45) launch.
- **Frieren H-AY n=4** ETA ~01:43 UTC tomorrow. T0=3.276387 INCONCLUSIVE. If T1-T3 trend similar → axis saturated (no merge).
- **Per user directive**: bias next assignments toward optimizer-state mechanisms, preconditioners, readout ideas, NOT scalar hyperparameter tuning.
