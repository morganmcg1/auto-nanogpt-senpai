# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~18:30 UTC (launch day +3)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (unchanged since H-W merge)

**PR #2317 (nezuko H-W): NC × Arbor + EMA-Nesterov + RI = 3.276193 at 2890 steps**
- Stack: Cautious-Muon (NC) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075)
- W&B: `vk0jtb3z`. Contract margin: 0.007615.

## Active assignments (~18:40 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~38h. |
| **#2349** | open2-frieren | H-AY: AdamW eps sweep | **n=4 Arm B directed** — T1=3.275574 (beats rank-1!), T0=3.277014, n=2 mean=3.276294 INCONCLUSIVE. Variance escalation rule triggered (spread=0.001440 > 0.0008). Student launching seeds 2-3. |
| **#2351** | open2-fern | H-BC: Spectral radius norm | **Awaiting student SENPAI-RESULT** — T0=T1=3.280820 both FALSIFIED. Advisor directed closure comment posted. |
| **#2354** | open2-askeladd | H-BH: GC on Muon momentum buffer | **In flight** — `4q46nmwf` step ~2312/2890 (~80%). ETA ~13 min. |
| **#2355** | open2-tanjiro | H-BI: Depth-wise Muon LR | **In flight** — `hld6fioy` step ~2150/2890 (~74%). ETA ~17 min. |
| **#2356** | open2-edward | H-BJ: NS-iter × Muon LR coupling | Assigned 18:30 UTC. Arm A: NS8+LR×1.04. Arm B: NS16+LR×0.97. Awaiting student pickup + smoke. |
| **#2357** | open2-thorfinn | H-BK: Cosine warm-restart Muon LR at step 2000 | **JUST ASSIGNED 18:40 UTC** (PR #2357). Arm A: restart_step=2000, peak=0.5×. Awaiting student pickup. |
| **#2358** | open2-nezuko | H-BL: Embed LR decoupling | **JUST ASSIGNED 18:40 UTC** (PR #2358). Arm A: adam_embed_lr=0.20 (down). Arm B: adam_embed_lr=0.45 (mild up). Builds on H-BF SNR saturation finding. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 18:40 | #2353 (thorfinn H-BG) | PMuon + β₂-pulse | **CLOSED FALSIFIED** | T0=T1=3.278038 (identical, n=2 mean +0.001845). PMuon pre-NS5 split conflicts with NC post-NS5 equalization. **32nd saturated lever.** |
| 2026-06-07 18:40 | #2352 (nezuko H-BF) | SNR-adaptive AdamW LR | **CLOSED FALSIFIED** | T0=3.278413 (+0.002220, 4.4× noise floor). SNR saturates → flat 3× LR multiplier on all groups catastrophic. **31st saturated lever.** |
| 2026-06-07 18:25 | #2346 (edward H-AW) | EN REST_STEPS=2300 | **CLOSED FALSIFIED** | n=4 mean 3.276256 = +0.000063, σ=0.00126 (2.5× noise floor variance blow-out). **30th saturated lever.** Contract margin 0.007488 < rank-1's 0.007615. |
| 2026-06-07 18:20 | #2351 (fern H-BC) | Spectral radius norm | **CLOSED FALSIFIED** | T0=T1=3.280820 (identical, +0.004627). Mass redistribution into weight radius does not help. |
| 2026-06-07 16:15 | #2350 (tanjiro H-BA) | Sophia-G diagonal Hessian | **CLOSED FALSIFIED** | T0=3.35478 = **+0.07859** (157× noise floor). **29th saturated lever.** |
| 2026-06-07 14:50 | #2343 (askeladd H-AT) | GC on raw Muon gradient (n=4) | **CLOSED FALSIFIED** | n=4 mean 3.277174 = +0.000981, σ=0.000911. **28th saturated lever.** |
| 2026-06-07 14:13 | #2348 (thorfinn H-AZ) | Lookahead Muon k=6 α=0.5 | **CLOSED FALSIFIED** | T0=+0.0158 (32× noise floor). **27th saturated lever.** |

## Saturated levers count: 32 (+ 2 failed direction families)

(Levers 1-25 unchanged. Recently added:)

26. **EN γ warmup (H-AR)** — both arms FALSIFIED.
27. **Lookahead Muon wrapper (H-AZ)** — catastrophic +0.0158.
28. **GC on raw Muon gradient (H-AT)** — n=4 mean +0.001 with variance blow-out. H-BH (GC on momentum) is mechanism follow-up.
29. **Sophia-G on AdamW (H-BA)** — T0 catastrophic +0.079. AdamW-side preconditioner family closed for sparse-gradient param groups (embed/lm_head).
30. **EN REST_STEPS=2300 (H-AW)** — n=4 mean +0.000063 with variance blow-out σ=0.00126. EN rest-window timing axis fully saturated.
31. **SNR-adaptive AdamW LR (H-BF)** — T0 catastrophic +0.002220; SNR saturation degenerates to flat 3× LR multiplier.
32. **PMuon + β₂-pulse (H-BG)** — T0=T1=3.278038 identical, +0.001845. Momentum-state oscillation on Muon uniformly harmful.

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |

## Strategic context (deep plateau)

We are now **32 saturated levers and 2 failed direction families** into a deep plateau. A large wave 2-3 batch (H-BC, H-BF, H-BG, H-AW) all closed FALSIFIED this cycle, confirming the rank-1 stack is highly optimized.

**Aurora NS structure insight (H-BJ motivation):** The `_AURORA_K=3` outer loop × `_ns_inner` 12-iteration inner cubic poly = **36 effective NS-poly applications per step**. This joint precision × LR coupling has never been tested directly. H-BJ is the first test of whether the current (12-iter, LR=0.0375) pair is at the calibration sweet spot.

**KEY PENDING (next 1-2 hours):**
1. **frieren H-AY Arm B T1** (~19:25 UTC) — T0=3.277014, need T1 for n=2 decision.
2. **askeladd H-BH `4q46nmwf` T0** (~19:30 UTC) — GC on momentum buffer.
3. **tanjiro H-BI `hld6fioy` T0** (~19:45 UTC) — depth-wise Muon LR.
4. **fern/nezuko/thorfinn SENPAI-RESULT replies** — need label swaps for PRs #2351/#2352/#2353.
5. **edward H-BJ pickup** — student to implement `--ns_inner_iter` / `--muon_lr_scale` CLI flags, run smoke (50 steps), then n=2 Arm A.

## Next-wave hypotheses (queued for next idle students)

- All current hypotheses assigned. Next assignments when students become idle:
  - H-BM: lm_head LR sweep (decoupling from other groups)
  - H-BN: MUON_WEIGHT_DECAY sweep (0.01 vs 0.05 vs default 0.025)

## Open Operational Items

- **Alphonse pod broken** (Issue #2319 ~38h). No new assignment until pod restored.
- **PR #2351** (fern H-BC) — awaiting student SENPAI-RESULT comment to finalize label swap + close.
- **Frieren H-AY n=4 Arm B** — seeds 2-3 need to launch and complete (~3.5h ETA from 18:40 UTC).
