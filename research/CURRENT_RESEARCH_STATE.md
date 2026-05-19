# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 08:56 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro + thorfinn + alphonse still broken; nezuko's pod is healthy. esc#21 posted at 07:09 UTC 2026-05-19 — ~83.5h total operator silence. esc#22 due ~09:09 UTC.
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

## Active experiments (08:56 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#451** | nezuko | **MuonH hyperball `budget_mult` sweep** (0.9 vs 1.0 ctrl vs 1.1) | **Newly assigned 08:50 UTC.** ZERO code changes — `--muonh_budget_mult` flag exists. No W&B run started yet. |
| **#450** | askeladd | **MuonH inner static mu sweep** (0.90 / 0.95 ctrl / 0.98) | **Newly assigned 08:50 UTC.** Adds `--muonh_mu` CLI flag, threads to optimizer at line 817. Arm 1 ctrl `iye79oh5` step 175 (just starting). |
| **#443** | edward | **Aux AdamW eps sweep** (1e-10 ctrl / 1e-8 PyTorch-std / 1e-6 heavier-reg) | Arm 1 ctrl `wgtlme0x` step 2790/3325 val=3.32319 (cooldown phase, on baseline trajectory). ETA ~25 min. |
| **#438** | fern | **NS5 polynomial coefficient sweep** (2.0,-1.5,0.5) ctrl / (1.875,-1.25,0.375) classical Halley / (2.5,-2.0,0.5) sharper unique-FP | Arm 1 ctrl re-launch `g1we1d9w` step 1575/3325 val=3.62052 (healthy mid-run). Original `0ueal82x` crashed at step 775 (suspected infra). ETA ~50 min. |
| **#425** | frieren | **MuonH-SI inner mu cooldown sweep** (0.95→0.95 ctrl / 0.70 / 0.50) | Arm 1 ctrl `o8zyjowj` val=3.27325 (baseline-equiv). Arm 2 `v7ztc5yx` val=3.28051 NEG (~9σ). **Arm 3 `xld472fl` (mu_final=0.50) step 3090/3325 93% val=3.29482 — catastrophic NEG confirmed, ~5min to terminal.** Will close axis. |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED 83.5h+** — confirmed silicon failure on GPU `g71b0d6`. esc#21 posted. |
| **#298** | tanjiro | **Residual branch init rescale** (1/sqrt(2L)) | **POD-BLOCKED 83.5h+** — NaN on GPU `gd125a8`. esc#21 posted. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/needs_rebase** — `gd103cc`. esc#21 posted. |

**8/8 students assigned.** 3 pods broken (alphonse + tanjiro + thorfinn) = 37.5% research capacity lost.

## Recent closures (07:10 UTC → 08:50 UTC wave)

| PR | Student | Result |
|---|---|---|
| **#424 CLOSED** | askeladd | **MuLoCo outer Nesterov-SGDM mu sweep — ALL NEG.** Arm 1 (drop_nesterov, val=3.27863, ~7σ NEG); arm 2 ctrl (mu=0.5, val=3.27353, baseline-equiv); **arm 3 (mu=0.8, val=3.35359, ~100σ catastrophic NEG, ffs=-1).** Nesterov-SGDM with mu=0.5 confirmed optimal — both drop-Nesterov AND higher-momentum directions fail. Axis CLOSED. |
| **#421 CLOSED** | nezuko | **MuonH inner AGC clip_ratio sweep — close-equiv across arms.** Arm 1 ctrl (clip=0.05, val=3.27522), arm 2 (clip=0.02, val=3.27372), arm 3 (clip=0.10, val=3.27404). All within ~σ. AGC clip activates rarely under scale-invariant projection — low-signal axis. CLOSED. |
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

## Saturated levers (as of 08:56 UTC)

- **Inner LR dynamics**: MuonH-SI HPs (lr/mu/wd), cooldown shape ✓, LR warmup step-count=100 ✓, warmup shape ✓, mu warmup (PR #389 NEG), **cooldown_frac (PR #417 CLOSED NEG — 1.0 is only viable)**, **mu cooldown (PR #425 closing NEG)**.
- **Inner optimizer geometry**: AGC clip_ratio (PR #421 closed — close-equiv across arms, low-signal axis), Nesterov outer SGDM mu (PR #424 CLOSED, mu=0.5 is unique optimum, drop_nest AND mu=0.8 both NEG).
- **Aux optimizer**: Lion/AdEMAMix/AdamW NEG for outer; betas=(0.8,0.95) confirmed optimal (PR #183); embed lr_mult, cooldown shape/frac, LR warmup, lm_head wd — all saturated. **eps NEW AXIS (PR #443 in-flight)**.
- **NS5**: fp32 closed, k-count blocked (#190), **coefficients retesting on new baseline via #438 in-flight**.
- **Logit softsign cap**: cap=15 is local optimum; axis CLOSED (#392).
- QK-Norm (removing or learning both NEG), gradient centralization NEG, schedule-free NEG, depth-LR NEG, lookahead NEG.

## Research direction (08:56 UTC)

**Current plateau signal**: 5+ consecutive screens with no wins since PR #329 merge. Major optimizer axes saturated near current operating point. The cosine-cooldown + AGC stack has narrowed the viable HP envelope substantially.

**Remaining live axes (in priority order):**

1. **NS5 polynomial shape** (PR #438 fern) — classical Halley quintic eliminates σ=√2 fixed-point leak. High-potential geometry change. Re-launched after infra crash.
2. **Aux AdamW eps** (PR #443 edward) — hardcoded eps=1e-10 never swept. Aux covers most params (embed 38M+ lm_head + scalars). eps directly controls effective update magnitude when v_hat is small. Arm 1 ctrl close to terminal.
3. **MuonH inner static mu** (PR #450 askeladd, NEW) — hardcoded mu=0.95 never swept on current baseline. Two-tier momentum system with outer Nesterov-SGDM may have shifted optimum.
4. **MuonH hyperball budget_mult** (PR #451 nezuko, NEW) — `budget_mult=1.0` may have shifted under AGC + warmup stack. Zero code changes; fast iteration.
5. **MuonH mu cooldown** (PR #425 frieren) — arm 3 close to terminal, expected catastrophic NEG. Axis CLOSING this hour.

**Next hypothesis candidates** (when students become idle):
- **MuLoCo sync_interval re-sweep** {15, 30 ctrl, 45, 60} — was tested on older baseline.
- **NS5 normalization eps** (hardcoded 1e-7 at line 467) — never swept; needs CLI flag.
- **Aux AdamW lr group ratios** (embed/lm_head/scalars) — not retested on current baseline.
- **MuonH inner LR step-count fine-grid** (warmup=50/100 ctrl/200) — orthogonal to shape axis.
- **Embedding init scale** (architectural; blocked on pod issues for arch experiments).
- **Bigger swings**: schedule-free hybrid for aux only, learned EMA on weight space, lr_mult per parameter group with auto-tuning.

**Plateau protocol considerations**: 5+ screens NEG. The inner LR schedule/geometry levers are mostly exhausted. With AGC + cosine cooldown stack the viable mu / clip / momentum envelope is narrow. Need to move toward:
- **Frontier exploration**: NS5 polynomial geometry (PR #438), aux numerical floor (PR #443).
- **Architectural changes** (blocked on tanjiro/alphonse pod issues).
- **Fresh formulation ideas** (new loss reg, optimizer hybrid).

**Operator silence on Issue #164**: 83.5h total, 3 broken pods. esc#21 posted at 07:09 UTC 2026-05-19. esc#22 due ~09:09 UTC.
