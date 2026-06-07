# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~14:00 UTC (launch day +3)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (unchanged since H-W merge)

**PR #2317 (nezuko H-W): NC × Arbor + EMA-Nesterov + RI = 3.276193 at 2890 steps**
- Stack: Cautious-Muon (NC, always-on after PR #2325) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075)
- W&B: `vk0jtb3z`. Contract margin: 0.007615.
- Constants: `MUON_LR=0.0375`, `MUON_WEIGHT_DECAY=0.025`, `EMA_NESTEROV_GAMMA=0.99`, NS12 iter count.

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, push the Track 3 fixed-step record below 2900.

## Active assignments (~14:00 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~33h, round-2 escalation posted. Human team not responded. |
| **#2341** | open2-nezuko | H-AR: EN γ warmup | Arm A FALSIFIED (n=2 mean 3.279476). Arm B (γ_start=0.95) `3vhyodcg` T0=3.277508 FALSIFIED; **awaiting Arm B T1 terminal SENPAI-RESULT** (likely ~13:30 UTC, may already be terminal). |
| **#2343** | open2-askeladd | H-AT: Gradient Centralization on Muon | n=4 confirm running: `crhbqarp` step 1525/2890 (seed 2 ~53%) at 13:54 UTC. Final n=4 result at ~14:00-15:00 UTC. Bands: ≤3.275793→STRONG merge; ≤3.276193→Promising merge; (3.276193,3.276593)→confirmed inconclusive; ≥3.276593→FALSIFIED. **STRONGEST positive signal of last 15 arms tested.** |
| **#2346** | open2-edward | H-AW: EN REST_STEPS timing sweep | **PROMISING** — n=2 mean 3.276274 (T0=3.276414, T1=3.276133 BELOW rank-1). Directed n=4 confirm (seeds 2-3, `--seed_offset 2`) at 13:52 UTC. Awaiting student relaunch. |
| **#2348** | open2-thorfinn | H-AZ: Lookahead wrapper on Muon | **T0 CATASTROPHIC** — `tjv3mars` trial-1 step 2890 val/ri_loss = **3.292015** (+0.0158, ~32× noise). Abort requested 13:52 UTC. Awaiting SENPAI-RESULT to close. |
| **#2349** | open2-frieren | H-AY: AdamW eps sweep (1e-8 vs 1e-12) | Arm A `dnvqhw4p` (eps=1e-12) step ~910/2890 (~32% of trial 1 of 2), pace ~2035ms/step. n=2 ETA ~15:47 UTC. Zombie `hh8ank8b` killed at 13:04 UTC. |
| **#2350** | open2-tanjiro | H-BA: Sophia-G diagonal Hessian on AdamW | Smoke `d7sjufih` passed at 13:34 UTC; full n=2 Arm A run started. Step 25 at 13:38 UTC (live). T0 ETA ~16:30 UTC. |
| **#2351** | open2-fern | **H-BC: Spectral radius norm targeting in muon_update** | **JUST ASSIGNED 13:50 UTC** (after PR #2340 H-AQ CLOSED FALSIFIED both arms). Pending pod pickup. Replaces line-918 shape heuristic with true power-iteration spectral norm. Arms A=σ_target=1.0, B=0.7. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 13:50 | #2340 (fern H-AQ) | AdamW β₁ warmup | **CLOSED FALSIFIED** | Arm A n=2 mean 3.278438 (+0.002245), Arm B β₁=0.65 n=2 mean 3.279138 (+0.002945). β₁ warmup direction family failed. **25th saturated lever.** |
| 2026-06-07 12:43 | #2347 (tanjiro H-AX) | EN PREFILL_STEPS=100 | **CLOSED FALSIFIED** | T0=3.277027 = +0.000834 (FALSIFIED), trial 2 CRASHED at step 3316. **24th saturated lever** (EN timing axis). |
| 2026-06-07 09:55 | #2337 (edward H-AO) | Per-block Muon LR (both arms) | **CLOSED FALSIFIED** | Arm A T0=+0.0078, Arm B T0=+0.006015. Both 12-16× noise floor. 21st saturated lever. |
| 2026-06-07 09:50 | #2344 (tanjiro H-AU) | Muon LR warmup 0→0.0375 over 200 steps | **CLOSED FALSIFIED** | T0=3.281785 = +0.005592. Early abort. 20th saturated lever. |
| 2026-06-07 08:00 | #2339 (thorfinn H-AP) | lm_head on Muon (mult=0.1) | **CLOSED FALSIFIED** | T0=3.291868 = +0.0157. 19th saturated lever. |
| 2026-06-07 07:10 | #2335 (tanjiro H-AM) | Muon WD cosine 0.025→0 | **CLOSED FALSIFIED** | n=2 mean 3.276455 > gate. High seed variance. 18th saturated lever. |
| 2026-06-07 07:05 | #2331 (askeladd H-AI) | NS quartic (3,−3,1) | **CLOSED FALSIFIED** | n=2 mean 3.276558 > gate. Lucky T0 seed. 17th saturated lever. |

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |
| **Muon LR ±20%** | regresses | **SATURATED (H-AG)** |
| **EMA-Nesterov γ (constant)** | regresses | **SATURATED (H-AH)** |
| **NS10 vs NS12** | within noise | **SATURATED (H-AF)** |
| **z-loss aux** | +0.004 to +0.013 | **SATURATED (H-AJ)** |
| **Cautious-AdamW (all groups)** | diverges | **FAILED (H-AK)** |
| **Cautious-AdamW dense-only** | diverges | **FAILED (H-AK')** |
| **Arbor warmup N=(0,500)** | within noise | **SATURATED (H-AA)** |
| **Multi-anchor RI (2200+2375)** | +0.00134 | **SATURATED (H-AN)** |
| **AdamW β₂ warmup** | n=2 mean +0.000292 | **SATURATED (H-AL)** |
| **NS quartic (3,−3,1)** | n=2 mean +0.000365 | **SATURATED (H-AI)** |
| **Muon WD cosine 0.025→0** | n=2 mean +0.000262 | **SATURATED (H-AM)** |
| **lm_head on Muon (mult=0.1)** | T0=+0.0157 | **SATURATED (H-AP)** |
| **Per-block Muon LR (both arms)** | T0 = +0.006 to +0.008 | **SATURATED (H-AO)** |
| **Muon LR warmup 0→0.0375** | T0=+0.0056 | **SATURATED (H-AU)** |
| **AdamW β₁ warmup (both arms)** | Arm A +0.00225, Arm B +0.00295 | **SATURATED (H-AQ)** |
| **EN γ warmup (0.9→0.99)** | T0=+0.00211 (FALSIFIED) | H-AR T1 pending (nezuko) |
| **Muon gradient noise (σ_0=0.01)** | n=2 mean +0.001498 | **SATURATED (H-AS)** |
| **Gradient Centralization** | T0=+0.000136 (PROMISING) | H-AT n=4 confirm ~14-15 UTC (askeladd) |
| **FINAL_LR_POWER sweep (0.9, renorm)** | T0=+0.004326 (8× noise floor) | **SATURATED (H-AV)** |
| **EN REST_STEPS timing (2300)** | n=2 mean 3.276274 (PROMISING) | H-AW n=4 directed (edward) |
| **EN PREFILL_STEPS=100** | T0=+0.000834 (FALSIFIED) + crash | **SATURATED (H-AX)** |
| **Lookahead on Muon k=6 α=0.5** | T0=+0.0158 | **SATURATED (H-AZ)** — awaiting close |

## Saturated levers count: 25 (+ 2 failed direction families)

1. RI γ axis (H-AD)
2. RI single-anchor capture × γ sweep (H-AE)
3. SWA tail averaging (H-AB)
4. Arbor without EN (H-Z)
5. NC without Arbor
6. Drop EN from NC×Arbor stack (H-Y)
7. EMA-Nesterov γ constant sweep (H-AH)
8. Muon LR ±20% (H-AG)
9. NS iteration count NS10 vs NS12 (H-AF)
10. z-loss aux (H-AJ)
11. Cautious-AdamW uniform recipe (H-AK)
12. Cautious-AdamW dense-only (H-AK')
13. Arbor warmup-from-1 N=(0,500) (H-AA)
14. Multi-anchor RI steps 2200+2375 (H-AN)
15. AdamW β₂ warmup 0.95→0.99 (H-AL)
16. NS quartic (3,−3,1) (H-AI) — T0 lucky seed
17. Muon WD cosine 0.025→0 (H-AM) — high variance
18. Per-block Muon LR Arm A early-boost (H-AO partial)
19. lm_head on Muon mult=0.1 (H-AP) — catastrophic
20. Muon LR warmup 0→0.0375 (H-AU) — catastrophic
21. Per-block Muon LR Arm B late-boost (H-AO complete) — both arms catastrophic
22. FINAL_LR_POWER=0.9 with renormalized power_c (H-AV) — 8× noise floor, decay-tail shape axis saturated
23. Muon gradient noise σ_0=0.01 Neelakantan decayed (H-AS) — n=2 mean +0.001498, noise poisons NS orthogonalization
24. EN PREFILL_STEPS=100 (H-AX) — T0=+0.000834, crashed in trial 2; EN window-timing axis FALSIFIED with PREFILL=100
25. **AdamW β₁ warmup (H-AQ) — both arms FALSIFIED with +0.0022 to +0.0030 above rank-1; β₁ warmup direction family for AdamW dead**

## Strategic context (deep plateau)

We are now **25 saturated levers and 2 failed direction families** into a deep plateau. The rank-1 3.276193 stack (NC × Arbor × EN × RI) is highly optimized.

**KEY PENDING (next 1-3 hours):**
1. **askeladd H-AT GC n=4 confirm** running (`crhbqarp` step ~1700/2890 seed 2). Final at ~14:30-15:00 UTC. Only positive signal in last 15+ arms tested. n=2 mean had been 3.276584 (T0=3.276329, T1=3.276839, spread ≈ noise floor).
2. **edward H-AW REST=2300 n=4 confirm directed**: n=2 mean 3.276274 (T0=+0.000221, T1=−0.000060, both within noise band; T1 BELOW rank-1). Student to relaunch with `--seed_offset 2`, terminal ETA ~17:00 UTC.
3. **thorfinn H-AZ Lookahead catastrophic at T0** (+0.0158). Awaiting abort SENPAI-RESULT to close. **Lookahead wrapper family dead** (26th lever).
4. **fern H-BC spectral norm targeting** (PR #2351) — Replacement for line-918 Frobenius heuristic with true σ via 3-iter power iteration. Smoke gate first then n=2.
5. **tanjiro H-BA Sophia-G** (PR #2350) — Smoke passed, n=2 Arm A in flight, T0 ETA ~16:30 UTC.
6. **frieren H-AY AdamW eps** (PR #2349) — Arm A (eps=1e-12) `dnvqhw4p` n=2 ETA ~15:47 UTC.

**Plateau Protocol wave 2 in flight:** Sophia-G (2nd-order curvature), Spectral-norm targeting (operator-norm scaling fix). Queued next: H-BE EN scope diagnostic, H-BF SNR-LR.

## Next-wave hypotheses (queued for next idle students)

Full specs in `/research/RESEARCH_IDEAS_2026-06-07_12:30.md`. Ranked priority:

1. ~~**H-BA: Sophia-G**~~ — Assigned tanjiro PR #2350. ✓
2. ~~**H-BC: Spectral radius normalization**~~ — Assigned fern PR #2351. ✓
3. **H-BE: EMA-Nesterov scope diagnostic** — Wrap EN around Muon params only vs all params. Next assignment for whichever student becomes idle next (likely thorfinn after H-AZ close).
4. **H-BF: SNR-adaptive LR on AdamW** — Per-param gradient SNR from existing m_t, v_t; suppress low-SNR updates.
5. **H-BB: PSGD-Kron** + **H-BD: partial SAM** — written but have memory / benchmark-contract risks; hold for later wave.

## Awaiting research-agent wave 3 ideas if needed

If plateau extends past wave 2 closures with no positive signal, escalate to a fresh researcher-agent pass — focus on:
- Optimizer-state mechanisms not yet tried (decoupled MomentumStorage, NSGD-like, sign-only Muon variants)
- Schedule/readout reformulations (lr schedule per-block, weight-tied readout pruning)
- Principled combinations of #1532/#1614 lineage with current rank-1 (PMuon+LR + NC+Arbor)
- Compute-budget aware bold swings (ns_steps=7-10, Muon LR coupled to ns_steps)
