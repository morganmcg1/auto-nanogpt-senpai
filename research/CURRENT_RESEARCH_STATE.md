# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~14:35 UTC (launch day +3)
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

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, push the Track 3 fixed-step record below 2900. **Bias toward optimizer-state mechanisms, preconditioners, schedule/readout ideas, principled combinations of #1532/#1614 with public SOTA lineages.**

## Active assignments (~14:35 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~33h, round-2 escalation posted. Human team not responded. |
| **#2343** | open2-askeladd | H-AT: Gradient Centralization on Muon | n=4 confirm `crhbqarp` step 5166/5780 (~89% of seed 3 / T3). T0=3.276329, T1=3.276839, **T2=3.27846**. **n=3 mean = 3.277209** = +0.001016 above rank-1 (FALSIFIED band approaching). T3 terminal ETA ~15:00 UTC. Even with T3≈3.275 (best-case), n=4 mean ≈ 3.27669 → still INCONCLUSIVE-FALSIFIED. **Likely close on T3 SENPAI-RESULT.** |
| **#2346** | open2-edward | H-AW: EN REST_STEPS timing sweep | **PROMISING — n=4 confirm directed**. n=2 mean 3.276274 (T0=3.276414, T1=3.276133 BELOW rank-1). Student to relaunch with `--seed_offset 2`. Terminal ETA ~17:00 UTC. |
| **#2349** | open2-frieren | H-AY: AdamW eps sweep (1e-8 vs 1e-12) | Arm A `dnvqhw4p` (eps=1e-12) step 3341/5780 (trial 2 ~451). **T0 ≈ 3.27759 (likely terminal, +0.001397, FALSIFIED)**. Awaiting T1 to compute n=2 mean. ETA T1 ~15:47 UTC. If n=2 FALSIFIED, immediate Arm B (eps=1e-8). |
| **#2350** | open2-tanjiro | H-BA: Sophia-G diagonal Hessian on AdamW | Arm A `d7sjufih` step 1445/5780 (~25% T0), healthy descent val/loss 3.6167. T0 ETA ~17:30 UTC. |
| **#2351** | open2-fern | H-BC: Spectral radius norm targeting in muon_update | **Smoke gate PASSED.** σ̂ probe at step 5 returned ~1.67 (above predicted 1.0±0.3). Arm A n=2 `v65l1o11` step 100 live. Possible dup-run zombie `k9m4k8qg` at step 0 stale — student asked to verify. T0 ETA ~17:30 UTC. |
| **#2352** | open2-nezuko | **H-BF: SNR-adaptive AdamW LR** | **JUST ASSIGNED 14:10 UTC** (after H-AR closed FALSIFIED both arms — 26th lever). Pending pod pickup; smoke first. Per-step `sqrt(m²/(v−m²))` LR multiplier per AdamW group, clamped to [1/3, 3]. |
| **#2353** | open2-thorfinn | **H-BG: PMuon + β₂-pulse (PR #1532/#1614 lineage)** | **JUST ASSIGNED 14:30 UTC** (after H-AZ closed FALSIFIED at T0=+0.0158 — 27th lever). Highest-priority wave-3 hypothesis. Arm A: pure PMuon (direction/magnitude split before NS5). Arm B: PMuon + β₂ pulse 0.99→0.90 over steps 2500-2650. |

## Recent closures (last 90 min, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 14:13 | #2348 (thorfinn H-AZ) | Lookahead Muon k=6 α=0.5 | **CLOSED FALSIFIED** | T0=3.292015 = +0.0158 (32× noise floor). Lookahead double-EMA with EN over-smooths Muon. **27th saturated lever** (lookahead wrappers dead). |
| 2026-06-07 14:00 | #2341 (nezuko H-AR) | EN γ warmup (γ_start=0.9 → 0.95) | **CLOSED FALSIFIED** | Arm A n=2 mean 3.279476 (+0.003283), Arm B n=2 mean 3.278359 (+0.002166). EN init-schedule axis dead. **26th saturated lever.** |
| 2026-06-07 13:50 | #2340 (fern H-AQ) | AdamW β₁ warmup | **CLOSED FALSIFIED** | Arm A n=2 mean +0.002245, Arm B β₁=0.65 n=2 mean +0.002945. β₁ warmup direction family failed. **25th saturated lever.** |
| 2026-06-07 12:43 | #2347 (tanjiro H-AX) | EN PREFILL_STEPS=100 | **CLOSED FALSIFIED** | T0=+0.000834 + trial 2 crashed. **24th saturated lever** (EN timing axis). |

## Saturated levers count: 27 (+ 2 failed direction families)

(Levers 1-24 unchanged from prior state. Recently added:)

25. **AdamW β₁ warmup (H-AQ)** — both arms FALSIFIED with +0.0022 to +0.0030 above rank-1; β₁-warmup direction family dead.
26. **EN γ warmup (H-AR)** — both arms FALSIFIED at +0.0022 to +0.0033. EN initialization-schedule axis (PREFILL/warmup) fully saturated when combined with H-AX, H-AW results.
27. **Lookahead Muon wrapper (H-AZ)** — T0=+0.0158, catastrophic. Lookahead double-EMA with existing EN over-smooths. Wrapper-style augmentations on Muon dead.

## Key mechanism table (NC × Arbor + RI stack) — unchanged

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |

## Strategic context (deep plateau)

We are now **27 saturated levers and 2 failed direction families** into a deep plateau. The rank-1 3.276193 stack (NC × Arbor × EN × RI) is highly optimized.

**KEY PENDING (next 1-3 hours):**
1. **askeladd H-AT n=4 confirm `crhbqarp`** ~89% of T3. T2 was 3.27846 dragging n=3 mean to 3.277209. T3 terminal ~15:00 UTC. **High likelihood of close on FALSIFIED** unless T3 < 3.275.
2. **edward H-AW REST=2300 n=4 confirm** directed — needs student to relaunch with `--seed_offset 2`. Terminal ETA ~17:00 UTC. n=2 was 3.276274 (T1 BELOW rank-1!), so n=4 is genuine PROMISING confirm.
3. **frieren H-AY Arm A eps=1e-12 T0≈3.27759** (FALSIFIED). Awaiting T1 — if n=2 FALSIFIED, jump to Arm B (eps=1e-8).
4. **fern H-BC σ̂≈1.67 observation** — actual operator-norm of post-NS5 update is 1.7× the heuristic. Mechanism test in flight (Arm A n=2 launched).
5. **tanjiro H-BA Sophia-G** Arm A T0 ETA ~17:30 UTC.
6. **nezuko H-BF SNR-LR** PR #2352 pending pod pickup; smoke first.
7. **thorfinn H-BG PMuon + β₂-pulse** PR #2353 pending pod pickup; **highest wave-3 priority — directly composes audited #1532/#1614 levers onto current rank-1**.

**Plateau Protocol wave 2-3 in flight:**
- Wave 2: H-BA Sophia-G (tanjiro), H-BC spectral norm (fern), H-BF SNR-LR (nezuko)
- Wave 3: H-BG PMuon + β₂-pulse (thorfinn)
- Queued next: H-BH GC-on-Muon-momentum, H-BI depth-wise LR, H-BJ NS-iter × LR coupling

## Next-wave hypotheses (queued for next idle students)

Full specs in `/research/RESEARCH_IDEAS_2026-06-07_12:30.md` (wave 2) and `/research/RESEARCH_IDEAS_2026-06-07_14:00.md` (wave 3). Ranked priority:

1. ~~**H-BA: Sophia-G**~~ — Assigned tanjiro PR #2350. ✓
2. ~~**H-BC: Spectral radius normalization**~~ — Assigned fern PR #2351. ✓
3. ~~**H-BF: SNR-adaptive LR**~~ — Assigned nezuko PR #2352. ✓
4. ~~**H-BG: PMuon + β₂-pulse**~~ — Assigned thorfinn PR #2353. ✓
5. **H-BH: GC on Muon momentum** — Strong candidate for next idle slot (askeladd after H-AT close). Mechanism isolation: tests whether H-AT's GC effect lives in the gradient or in the accumulated momentum.
6. **H-BI: Depth-wise Muon LR** — Per-block LR multiplier `MUON_LR × decay^depth`. Arm A decay=0.85 (deeper=lower), Arm B decay=0.90 inverted.
7. **H-BJ: NS-iter × LR coupling** — Arm A NS8+LR×1.04, Arm B NS16+LR×0.97. Tests if extra NS iters are wasted or useful.
8. **H-BE: EMA-Nesterov scope diagnostic** — Lower-priority diagnostic; queue after BH/BI/BJ.
9. **H-BB: PSGD-Kron** — Memory risk, hold.
10. ~~H-BD: Partial SAM~~ — DISQUALIFIED (2× forward-backward violates benchmark contract).

## Open Operational Items

- **Alphonse pod broken** (Issue #2319 ~33h, no human response).
- **Fern PR #2351 dup-run check** — possible zombie `k9m4k8qg` at step 0; awaiting student verify.
- **Edward PR #2346 student relaunch** — directed n=4 confirm; awaiting acknowledgement.
