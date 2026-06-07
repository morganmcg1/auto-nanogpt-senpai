# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~23:35 UTC (launch day +3) — NEW RANK-1 landed
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

## Active assignments (~23:00 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~42h. No new assignment until pod restored. |
| **#2363** | open2-frieren | H-AY cleanup: remove --adam_eps_override flag | **ASSIGNED ~23:35 UTC** (PR #2363). Prune --adam_eps_override flag, hardcode eps=1e-12. Smoke gate only (50 steps). |
| **#2356** | open2-edward | H-BJ: NS-iter × Muon LR coupling | **Arm A FALSIFIED** (n=2 mean 3.277806, 36th lever). Arm B `876rihlt` (NS16+LR×0.97) step 1225/5780 (~21%), ETA revised ~05:30 UTC. |
| **#2358** | open2-nezuko | H-BL: Embed LR decoupling | **Arm A n=2 FALSIFIED (BARELY)** mean=3.276713 (+0.000520), T0=3.277526 / T1=3.275901 (sub-baseline single seed). Spread 0.001626 ≫ 0.0008. Per cross-PR seed pattern (see below), letting Arm B run rather than n=4 Arm A. Arm B `pmvj0tp6` (embed_lr=0.45) step ~250, n=2 ETA ~02:25 UTC. |
| **#2359** | open2-askeladd | H-BM: lm_head LR decoupling (lm_head_lr=0.002) | `vn32x4gj` T0=3.276283 **INCONCLUSIVE** (+0.000090, very close to baseline). T1 at step ~726/2890 (~25% into T1), ETA ~01:20 UTC. n=2 mean could land MERGE-eligible if T1 ≤ 3.276103. |
| **#2360** | open2-tanjiro | H-BN: MUON_WEIGHT_DECAY sweep | `9tlotgem` T0=3.277600 **FALSIFIED** (+0.001407). T1 at step ~926/2890. n=2 ETA ~01:10 UTC. Likely closes axis WD=0.010 falsified — may direct WD=0.050 Arm B post-close. |
| **#2361** | open2-fern | H-BO: AdamW (β₁, β₂) sweep | `j9lofncb` Arm A (β=0.9/0.95) step 2725 (~94%) T0 imminent. `wemjdth9` Arm B (β=0.85/0.98) step 867 in parallel (multi-GPU?). Both still pre-terminal. |
| **#2362** | open2-thorfinn | H-BU: Lookahead-on-AdamW | **Smoke run `oqmty85f` step 175, healthy.** First AdamW optimizer-state mechanism. Arm A k=5 α=0.5; Arm B k=10 α=0.5. Muon NC×EN×RI stack untouched. n=2 launch expected once smoke clears (likely within 30 min of smoke complete). |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 19:35 | #2351 (fern H-BC) | Spectral radius norm σ_target=1.0/0.7 | **CLOSED FALSIFIED** | Arm A n=2 mean 3.280025 (+0.004). Post-NS5 principal direction is noise-amplified; concentrating mass onto it = double-suppression vs NC. **35th lever.** |
| 2026-06-07 19:30 | #2355 (tanjiro H-BI) | Depth-wise Muon LR decay=0.85 | **CLOSED FALSIFIED** | T0=3.29223 catastrophic (+0.016, 32× noise floor). Layer-asymmetric LR breaks NC × Arbor × NS5 uniformity invariant. **34th lever.** |
| 2026-06-07 19:26 | #2354 (askeladd H-BH) | GC on Muon momentum buffer | **CLOSED FALSIFIED** | T0=3.284688 catastrophic (+0.0085, 17× noise floor). Double DC-mode cancellation (centering + NC post-NS5) destroys EN slow-trajectory mean component. **33rd lever.** |
| 2026-06-07 18:40 | #2353 (thorfinn H-BG) | PMuon + β₂-pulse | **CLOSED FALSIFIED** | T0=T1=3.278038 identical, +0.001845. PMuon pre-NS5 conflicts with NC post-NS5. **32nd lever.** |
| 2026-06-07 18:40 | #2352 (nezuko H-BF) | SNR-adaptive AdamW LR | **CLOSED FALSIFIED** | T0=3.278413 +0.002220. SNR saturates → flat 3× LR catastrophic. **31st lever.** |
| 2026-06-07 18:25 | #2346 (edward H-AW) | EN REST_STEPS=2300 | **CLOSED FALSIFIED** | n=4 mean 3.276256 = +0.000063, σ=0.00126. **30th lever.** |

## Saturated levers count: 37

(Levers 36-37 newly added this session:)
36. **NS8+LR×1.04 (H-BJ Arm A)** — n=2 mean 3.277806 FALSIFIED (+0.001613). NS-iter below default + compensating LR boost: post-NS5 spectrum at NS8 too anisotropic, LR boost doesn't recover orthogonalization quality.
37. **Cosine warm-restart Muon LR at step 2000 (H-BK)** — T0=3.287374 CATASTROPHIC (+0.011182, 22× noise floor). Confirms **Invariant #5**: monotonic-down Muon LR through step 2375 RI capture is load-bearing.

**Pending close (next 1-6h):**
- **frieren H-AY n=4 confirm** ~30 min — currently 3.276387 FALSIFIED-trending; will be **38th lever** (axis closed, both arms saturated).
- **tanjiro H-BN Arm A** ~01:10 UTC (T0=3.277600 FALSIFIED, n=2 likely closes WD=0.010 direction).
- **askeladd H-BM Arm A** ~01:20 UTC — T0 INCONCLUSIVE (+0.000090); could go either way.
- **nezuko H-BL Arm B** ~02:25 UTC (38th lever pending if also FALSIFIED).
- **edward H-BJ Arm B** ~05:30 UTC (revised — NS16+LR×0.97).

(Levers 1-29 unchanged. Recent:)

30. **EN REST_STEPS=2300 (H-AW)** — n=4 mean +0.000063 with variance blow-out.
31. **SNR-adaptive AdamW LR (H-BF)** — T0 catastrophic +0.002220.
32. **PMuon + β₂-pulse (H-BG)** — T0=T1 identical +0.001845.
33. **GC on Muon momentum buffer (H-BH)** — T0 catastrophic +0.0085. Closes GC-on-Muon family.
34. **Depth-wise Muon LR (H-BI)** — T0 catastrophic +0.016. Muon LR uniformity load-bearing.
35. **Spectral radius norm post-NS5 (H-BC)** — Arm A n=2 mean +0.004. Post-NS5 spectrum concentration wrong direction.

**Pending closure (36th):** H-BJ Arm A NS8+LR×1.04 — T0=+0.001647. T1 must be ≤ 3.274546 for MERGE band (6σ swing from T0, unlikely).

## Key mechanism table (NC × Arbor + RI + eps=1e-12 stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |
| + eps=1e-12 (AdamW) | **−0.000021** | Borderline — cross-PR seed pattern complicates attribution |

## Cross-PR seed pattern observation (NEW this cycle)

**Across H-AY (eps sweep) AND H-BL (embed_lr=0.20), seeds 0 and 1 show systematic split:**

| Arm | T0 (seed 0) | T1 (seed 1) | n=2 mean |
|---|---:|---:|---:|
| H-AY Arm A (eps=1e-8) | 3.277593 BAD | 3.275574 GOOD | 3.276584 INCONCL |
| H-AY Arm B (eps=1e-12) | 3.277014 BAD | 3.275707 GOOD | 3.276361 INCONCL |
| H-BL Arm A (embed_lr=0.20) | 3.277526 BAD | 3.275901 GOOD | 3.276713 BARELY FALSIFIED |

Three independent AdamW perturbations: seed 0 lands ~+0.0014 above rank-1, seed 1 lands ~−0.0005 below rank-1. The "good T1" signal is the SAME magnitude regardless of variable — this is **seed-luck dominating perturbation effect at n=2** on the AdamW group axis.

Frieren n=4 confirms: extends to seeds 2,3 → mean ~3.276387 (above rank-1, FALSIFIED-trending). Seeds 2,3 are NOT sub-baseline.

**Operational implication**: future variance escalation calls on AdamW-group perturbations should consider this systematic seed pattern. n=2 (3.275×××) sub-baseline T1 is NOT a real positive signal — it's seed luck. Tightens our prior that AdamW group axis is locked at PR #309's tuning.

## Invariants confirmed (hard constraints on the stack)

1. **Muon LR uniformity across blocks** — H-BI: layer-asymmetric LR breaks NC × Arbor × NS5 equalization invariant.
2. **No DC-mode operations on Muon update path** — H-AT/H-BH: raw-grad or momentum-buffer centering + NC post-NS5 = double DC-mode cancellation, destroys EN slow-trajectory signal.
3. **Post-NS5 update spectrum: no concentration** — H-BC: concentrating onto principal singular direction degrades, NC already biases toward orthogonal.
4. **AdamW LR: no uniform multi-group boosts** — H-BF: uniform 3× across embed/lm_head/scalars catastrophic.
5. **Muon LR must be monotonic-down through step 2375 RI capture** — H-BK: cosine warm-restart at step 2000 destroys EN slow-trajectory coherence AND corrupts RI anchor. Confirmed by H-AU + H-AV.

## Strategic context (deep plateau — 37 saturated levers)

**AdamW decoupling decomposition** (current live wave):
- **H-AY (frieren)**: AdamW eps — n=4 Arm B T0=3.276387 INCONCLUSIVE. T1 in flight (~01:43 UTC). If all 4 trials average INCONCLUSIVE, axis saturated.
- **H-BL (nezuko)**: embed-only LR — Arm A T0=3.277526 FALSIFIED. T1 ~8% (ETA 22:42 UTC). Watchdog → Arm B (embed_lr=0.45).
- **H-BM (askeladd)**: lm_head-only LR — Arm A at ~60%, T0 ETA ~22:30 UTC.
- **H-BO (fern)**: AdamW (β₁, β₂) — Arm A at ~64%, T0 ETA ~22:00 UTC.
- **H-BU (thorfinn, NEW)**: Lookahead-on-AdamW (k-step slow-weight mixing on embed/lm_head/scalars) — first optimizer-state mechanism on AdamW side. Picking up smoke now.

**Muon side** (current live wave):
- **H-BN (tanjiro)**: MUON_WEIGHT_DECAY sweep — Arm A at ~60-70% step. T0 ETA ~22:00-22:30 UTC.
- **H-BJ (edward)**: NS-iter × Muon LR coupling — Arm A FALSIFIED (n=2 mean 3.277806, 36th lever). Arm B `876rihlt` (NS16+LR×0.97) running, ETA ~00:30 UTC.
- **H-BK (thorfinn)**: CLOSED FALSIFIED 37th lever — invariant #5 confirmed. Thorfinn → H-BU.

**Frieren H-AY n=4 confirm**: Arm B (eps=1e-12) n=2 mean 3.276361 INCONCLUSIVE with T1=3.275574 STRONG. n=4 launched per variance escalation. If mean lands sub-rank-1 → MERGE.

## Next-wave hypotheses (for next idle students)

- **H-BP**: Muon momentum (MU) sweep — current MU=0.95, test 0.90 / 0.98. SCALAR — lower priority per user directive.
- **H-BQ**: EN `lookahead_stepsize` sweep — never ablated vs rank-1 stack.
- **H-BR**: NS5 cubic polynomial coefficient retune — `(3, -3, 1)` alternatives.
- **H-BS**: AdamW per-group weight decay (currently all 0) — non-zero on scalars only. SCALAR — lower priority.
- **H-BT**: Embed × lm_head joint LR ratio sweep (after H-BL and H-BM close singly). SCALAR.
- **H-BV**: Stochastic weight averaging (SWA) on AdamW groups — collect checkpoints after step 2000, average before RI capture. State mechanism, complements H-BU.
- **H-BW**: EN on AdamW (apply EMA-Nesterov's slow-trajectory mechanism to embed/lm_head) — direct comparison to H-BU's Lookahead. MECHANISM.

## Open Operational Items

- **Alphonse pod broken** (Issue #2319 ~42h). No new assignment until pod restored.
- **Edward H-BJ Arm B** (`876rihlt`, NS16+LR×0.97) running step 1225/5780, ETA ~05:30 UTC.
- **Nezuko H-BL Arm B** (`pmvj0tp6`, embed_lr=0.45) running step ~250, ETA ~02:25 UTC. Decision: NO n=4 Arm A confirm despite variance escalation (cross-PR seed pattern overrides — see observation above).
- **Frieren H-AY n=4** (`nbptdumy`) at 90%, ETA ~30 min. Currently 3.276387 → axis closing as 38th lever on terminal.
- **Askeladd H-BM T0 INCONCLUSIVE** (3.276283), T1 ~25% in. ETA ~01:20 UTC.
- **Tanjiro H-BN T0 FALSIFIED** (3.277600), T1 ~32% in. ETA ~01:10 UTC.
- **Fern H-BO** Arm A near terminal (~94%), Arm B at ~30%. Watch dual progression.
- **Thorfinn H-BU** smoke running. Expect n=2 launch within ~30 min.
- **Per user directive**: all future assignments must bias toward optimizer-state mechanisms, preconditioners, readout ideas, NOT scalar hyperparameter tuning. H-BU (thorfinn) = first such assignment.
