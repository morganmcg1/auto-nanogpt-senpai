# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 07:10 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro + thorfinn still broken; nezuko's pod is healthy. esc#21 posted at 07:05 UTC 2026-05-19 — ~83.5h total operator silence.
- **Branch state:** Baseline post-PR #329 (AGC inner MuonH clip=0.05, merged 18:26 UTC 2026-05-18).

## ⭐ Current baseline (post-PR #329 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27286** (n=4 mean; trials: 3.27209/3.27264/3.27365/3.27305) |
| `ffs` (primary) | **3125** (best); mean 3137.5 |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| **MuonH inner AGC** | **`--muonh_agc_clip_ratio 0.05`** |
| MuonH LR warmup | warmup_steps=100, shape=linear |
| Outer wrapper | MuLoCo Nesterov-SGDM (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| Aux AdamW | betas=(0.8, 0.95), eps=1e-10, AGC clip_ratio=0.05 |
| Cooldown | MuonH=cosine frac=1.0, aux=linear frac=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| Logit cap | softsign at ±15 (hardcoded) |
| W&B confirm | `dpabql6o` (n=4 multi-trial) |

**Merge bar**: μ_val < 3.27286 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004.
- **n=1 promotion bar**: val < **3.27206** (Δ ≤ −0.0008 vs 3.27286)
- **Conservative n=4 bar**: μ < **3.27246**

**⚠️ CRITICAL — ALL new experiment commands must include:**
```
--aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --muonh_cooldown_shape cosine --muonh_warmup_steps 100
```

## Active experiments (07:10 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#443** | edward | **Aux AdamW eps sweep** (1e-10 ctrl / 1e-8 PyTorch-std / 1e-6 heavier-reg) | **Newly assigned 07:05 UTC.** Fresh axis — hardcoded eps=1e-10 has never been swept. Aux covers embed (38M params) + lm_head + scalars. Requires new `--aux_adamw_eps` flag. |
| **#438** | fern | **NS5 polynomial coefficient sweep** (2.0,-1.5,0.5) ctrl / (1.875,-1.25,0.375) classical Halley / (2.5,-2.0,0.5) sharper unique-FP | Smokes passed (vals ~4.21-4.23, well under 4.30 gate). Full arm 1 ctrl launch expected soon. |
| **#425** | frieren | **MuonH-SI inner mu cooldown sweep** (0.95→0.95 ctrl / 0.70 / 0.50) | Arm 1 ctrl `o8zyjowj` terminal val=3.27325. **Arm 2 `v7ztc5yx` (mu_final=0.70) step 3180/3325, val=3.283 — tracking ~0.010 above baseline, expected NEG.** Arm 3 (mu_final=0.50) chains after. |
| **#424** | askeladd | **MuLoCo outer Nesterov SGDM mu sweep** (drop_nest / keep_nest mu=0.5 ctrl / nest mu=0.8) | Arm 1 `o7pbf2f3` (drop_nesterov) terminal NEG val=3.27863. Arm 2 ctrl `n0ok0cgj` terminal val=3.27353 (baseline-equiv). **Arm 3 `o04vcj4x` (Nesterov mu=0.8) step 510/3325** — ETA ~2h. |
| **#421** | nezuko | **MuonH inner AGC clip ratio sweep** (0.02/0.05/0.10) | Arm 1 ctrl `ndt56ttp` terminal val=3.27522. Arm 2 `9imntmmb` (clip=0.02) terminal val=3.27372 (baseline-equiv). **Arm 3 `nhw3crpe` (clip=0.10 loose) step 360/3325** — ETA ~5h. |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED 83h+** — confirmed silicon failure on GPU `g71b0d6`. esc#21 posted. |
| **#298** | tanjiro | **Residual branch init rescale** (1/sqrt(2L)) | **POD-BLOCKED 83h+** — NaN on GPU `gd125a8`. esc#21 posted. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/needs_rebase** — `gd103cc`. esc#21 posted. |

**8/8 students assigned.** 3 pods broken (alphonse + tanjiro + thorfinn) = 37.5% research capacity lost.

## Recent closures (05:30 UTC → 07:10 UTC wave)

| PR | Student | Result |
|---|---|---|
| **#417 CLOSED** | edward | **MuonH inner cooldown_frac sweep — ALL NEG.** Monotonic catastrophic: cdfrac=1.0 ctrl (3.27236, baseline-equiv), cdfrac=0.7 (3.28949 +20σ, ffs=-1), cdfrac=0.5 (3.31306 +40σ, ffs=-1). Cooldown_frac=1.0 is the operating point. Lever closed. |
| **#392 CLOSED** | fern | **Logit softsign cap sweep (15/10/30) — ALL NEG.** cap=10 NEG ~10σ; cap=30 NEG ~11σ fails 3.28. cap=15 is local optimum. |

## MERGED this round (chronological)

| PR | Student | Result |
|---|---|---|
| **#114** | frieren | MuLoCo × MuonH-SI MERGED — val=3.27585 (n=4) |
| **#237** | edward | AGC aux clip=0.05 MERGED — val=3.27469 (n=4) |
| **#243** | frieren | MuonH-SI cosine cooldown MERGED — val=3.27415 (n=4) |
| **#310** | thorfinn | MuonH inner LR warmup=100 MERGED — val=3.27315 (n=4) |
| **#329** | askeladd | **AGC inner MuonH clip=0.05 MERGED** — val=**3.27286** (n=4). **Current baseline.** |

**Total improvement since start**: 3.27585 → 3.27286 = **−0.00299** over 5 merged PRs.

## Saturated levers (as of 07:10 UTC)

- **Inner LR dynamics**: MuonH-SI HPs (lr/mu/wd), cooldown shape ✓, LR warmup step-count=100 ✓, warmup shape ✓, mu warmup (PR #389 NEG), **cooldown_frac (PR #417 CLOSED NEG — 1.0 is only viable)**
- **Inner optimizer geometry**: AGC clip_ratio (arm 2/3 of #421 in-flight — close-equiv so far), Nesterov outer SGDM confirmed load-bearing (PR #424 arm 1 NEG)
- **Aux optimizer**: Lion/AdEMAMix/AdamW NEG for outer; betas=(0.8,0.95) confirmed optimal (PR #183); embed lr_mult, cooldown shape/frac, LR warmup, lm_head wd — all saturated
- **NS5**: fp32 closed, k-count blocked (#190), coefficients retesting on new baseline via #438
- **Logit softsign cap**: cap=15 is local optimum; cap=10 tighter NEG; cap=30 looser NEG — axis CLOSED (#392)
- QK-Norm (removing or learning both NEG), gradient centralization NEG, schedule-free NEG, depth-LR NEG, lookahead NEG

## Research direction (07:10 UTC)

**Current plateau signal**: 5+ consecutive screens with no wins since PR #329 merge. All major optimizer axes appear saturated near the current operating point.

**Remaining live axes (in priority order):**

1. **NS5 polynomial shape** (PR #438 fern) — classical Halley quintic eliminates σ=√2 fixed-point leak. High-potential geometry change.
2. **Aux AdamW eps** (PR #443 edward, new) — hardcoded eps=1e-10 never swept. Aux covers most params (embed 38M+ lm_head + scalars). eps directly controls effective update magnitude when v_hat is small.
3. **MuonH mu cooldown** (PR #425 frieren) — arm 2 in-flight at val~3.283, likely NEG; directional signal suggests mu cooldown hurts (same pattern as cooldown_frac — conservatism wins in the final phase). Would close this axis if arm 2 confirms.
4. **MuonH AGC clip ratio** (PR #421 nezuko arm 3, clip=0.10) — in-flight; arms 1+2 both baseline-equiv within σ. May be low-signal.
5. **MuLoCo outer Nesterov mu** (PR #424 askeladd arm 3, mu=0.8) — in-flight; arms 1+2 established Nesterov is load-bearing (arm 1 drop_nesterov NEG). mu=0.8 higher momentum may help or hurt.

**Next hypothesis candidates** (when students become idle):
- **MuonH inner static mu sweep** (0.85 / 0.90 / 0.95 ctrl / 0.98) — frieren will be idle after #425 closes
- **AdamW eps interaction with betas** — if edward's eps sweep shows signal, narrow-down iteration
- **Aux AdamW lr group ratios** (embed/lm_head/scalars) — not retested on current baseline
- **NS5 iteration count k** (PR #190 alphonse pod-blocked) — if alphonse pod is ever restored

**Plateau protocol considerations**: 5+ screens NEG. The inner LR schedule/geometry levers are mostly exhausted. Need to move toward:
- Architectural changes (residual init, embedding init — blocked on tanjiro/alphonse pod issues)
- Fresh formulation ideas (new optimizer algorithm, loss reformulation)

**Operator silence on Issue #164**: 83.5h total, 3 broken pods. esc#21 posted at 07:05 UTC 2026-05-19.
