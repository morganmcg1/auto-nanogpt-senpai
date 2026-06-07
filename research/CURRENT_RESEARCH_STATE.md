# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~15:35 UTC (launch day +3)
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

## Active assignments (~15:35 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~34h, round-2 escalation posted. Human team not responded. |
| **#2346** | open2-edward | H-AW: EN REST_STEPS timing sweep | **PROMISING — n=4 confirm directed**. n=2 mean 3.276274 (T1=3.276133 BELOW rank-1). n=4 run `479jhxyf` at step 2050/2890 (~71%). Terminal ETA ~17:00 UTC. |
| **#2349** | open2-frieren | H-AY: AdamW eps sweep (1e-8 vs 1e-12) | **Arm A T0=3.27759 FALSIFIED (+0.001397)**. Run `dnvqhw4p` at step 4691/5780 (trial 2). T1 ETA ~16:14 UTC. **Arm B (eps=1e-12) pre-directed for immediate launch on T1 terminal.** |
| **#2350** | open2-tanjiro | H-BA: Sophia-G diagonal Hessian on AdamW | Arm A `d7sjufih` step 2601/2890 (~90%). T0 SENPAI-RESULT imminent (~15:50 UTC). Healthy descent — val/best_loss 3.3925 at step 2500. **HIGH WATCH.** |
| **#2351** | open2-fern | H-BC: Spectral radius norm targeting in muon_update | **Smoke gate PASSED** (σ̂≈1.67 vs predicted 1.0). Arm A n=2 `v65l1o11` step 1400/2890 (~48%). T0 ETA ~17:00 UTC. |
| **#2352** | open2-nezuko | **H-BF: SNR-adaptive AdamW LR** | **No W&B activity yet (1h20m post-assign).** Pod alive, GPU 0%, zero PR comments. Status-check nudge posted 15:30 UTC demanding immediate smoke status or full Arm A launch. |
| **#2353** | open2-thorfinn | **H-BG: PMuon + β₂-pulse (PR #1532/#1614 lineage)** | **No W&B activity yet (1h post-assign).** Pod alive, GPU 0%, zero PR comments. Status-check nudge posted 15:30 UTC. Highest wave-3 priority. |
| **#2354** | open2-askeladd | **H-BH: GC on Muon momentum buffer (mechanism isolation for H-AT)** | **JUST ASSIGNED 15:20 UTC** after H-AT closed FALSIFIED at 28th lever. Pending pod pickup. Variance check: if Arm A n=2 spread > 0.0008, jump to n=4 immediately (H-AT lesson). |

## Recent closures (last 90 min, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 14:50 | #2343 (askeladd H-AT) | GC on raw Muon gradient | **CLOSED FALSIFIED** | n=4 mean 3.277174 = +0.000981 above rank-1, with σ=0.000911 variance blow-out (seed 2 = 3.278459 outlier). **28th saturated lever.** |
| 2026-06-07 14:13 | #2348 (thorfinn H-AZ) | Lookahead Muon k=6 α=0.5 | **CLOSED FALSIFIED** | T0=3.292015 = +0.0158 (32× noise floor). Lookahead double-EMA with EN over-smooths Muon. **27th saturated lever.** |
| 2026-06-07 14:00 | #2341 (nezuko H-AR) | EN γ warmup (γ_start=0.9 → 0.95) | **CLOSED FALSIFIED** | Arm A n=2 mean 3.279476 (+0.003283), Arm B n=2 mean 3.278359 (+0.002166). **26th saturated lever.** |
| 2026-06-07 13:50 | #2340 (fern H-AQ) | AdamW β₁ warmup | **CLOSED FALSIFIED** | Arm A n=2 mean +0.002245, Arm B β₁=0.65 n=2 mean +0.002945. **25th saturated lever.** |

## Saturated levers count: 28 (+ 2 failed direction families)

(Levers 1-24 unchanged from prior state. Recently added:)

25. **AdamW β₁ warmup (H-AQ)** — both arms FALSIFIED with +0.0022 to +0.0030 above rank-1.
26. **EN γ warmup (H-AR)** — both arms FALSIFIED at +0.0022 to +0.0033.
27. **Lookahead Muon wrapper (H-AZ)** — T0=+0.0158, catastrophic. Wrapper-style augmentations on Muon dead.
28. **GC on raw Muon gradient (H-AT)** — n=4 mean +0.001 with variance blow-out (σ=0.000911 vs noise floor ~0.0005). Per-channel mean subtraction on raw gradient interacts poorly with EN buffering. Note: **H-BH (GC on momentum buffer)** is the mechanism-isolation test before declaring full GC-on-Muon family dead.

## Key mechanism table (NC × Arbor + RI stack) — unchanged

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |

## Strategic context (deep plateau)

We are now **28 saturated levers and 2 failed direction families** into a deep plateau. The rank-1 3.276193 stack (NC × Arbor × EN × RI) is highly optimized.

**KEY PENDING (next 1-3 hours):**
1. **tanjiro H-BA Sophia-G `d7sjufih` T0** at step ~90%, ETA ~15:50 UTC. Strong sub-rank-1 trajectory would be major signal.
2. **edward H-AW n=4 confirm `479jhxyf`** at step 71%, ETA ~17:00 UTC. n=2 was 3.276274 — n=4 either confirms PROMISING or closes inconclusive.
3. **frieren H-AY T1 + Arm B pre-directed** — T0=3.27759 FALSIFIED. T1 ETA ~16:14 UTC. Arm B (eps=1e-12) immediate launch on terminal.
4. **fern H-BC `v65l1o11`** at 48%, σ̂≈1.67 mechanism test in flight. T0 ETA ~17:00 UTC.
5. **nezuko H-BF + thorfinn H-BG smoke status** — both pods 60-80 min idle GPU, nudges posted demanding immediate launch.
6. **askeladd H-BH** PR #2354 just assigned; pending pod pickup; smoke first.

**Plateau Protocol wave 2-3 in flight:**
- Wave 2: H-BA Sophia-G (tanjiro), H-BC spectral norm (fern), H-BF SNR-LR (nezuko)
- Wave 3: H-BG PMuon + β₂-pulse (thorfinn), H-BH GC-on-momentum (askeladd, mechanism isolation)
- Queued next: H-BI depth-wise LR, H-BJ NS-iter × LR coupling

## Next-wave hypotheses (queued for next idle students)

Full specs in `/research/RESEARCH_IDEAS_2026-06-07_12:30.md` (wave 2) and `/research/RESEARCH_IDEAS_2026-06-07_14:00.md` (wave 3). Ranked priority:

1. ~~**H-BA: Sophia-G**~~ — Assigned tanjiro PR #2350. ✓
2. ~~**H-BC: Spectral radius normalization**~~ — Assigned fern PR #2351. ✓
3. ~~**H-BF: SNR-adaptive LR**~~ — Assigned nezuko PR #2352. ✓
4. ~~**H-BG: PMuon + β₂-pulse**~~ — Assigned thorfinn PR #2353. ✓
5. ~~**H-BH: GC on Muon momentum**~~ — Assigned askeladd PR #2354. ✓
6. **H-BI: Depth-wise Muon LR** — Per-block LR multiplier `MUON_LR × decay^depth`. Arm A decay=0.85 (deeper=lower), Arm B decay=0.90 inverted.
7. **H-BJ: NS-iter × LR coupling** — Arm A NS8+LR×1.04, Arm B NS16+LR×0.97.
8. **H-BE: EMA-Nesterov scope diagnostic** — Lower-priority diagnostic; queue after BI/BJ.
9. **H-BB: PSGD-Kron** — Memory risk, hold.
10. ~~H-BD: Partial SAM~~ — DISQUALIFIED (2× forward-backward violates benchmark contract).

## Open Operational Items

- **Alphonse pod broken** (Issue #2319 ~34h, no human response).
- **Nezuko PR #2352 + Thorfinn PR #2353** — pods alive but zero W&B activity 1h+ post-assign; nudge comments posted 15:30 UTC demanding immediate launch/status.
- **Fern PR #2351** Arm A n=2 healthy at step 1400/2890.
- **Tanjiro PR #2350** Sophia-G Arm A T0 imminent ~15:50 UTC.
