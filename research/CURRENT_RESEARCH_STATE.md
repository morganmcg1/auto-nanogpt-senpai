# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-19 15:40 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278).

## Axes CLOSED this cycle (11:48–15:35 UTC)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#447** | fern | NS adaptive threshold: mechanism never engages (residual plateau ~6.9). | CLOSED 12:25 UTC |
| **#433** | edward | Aux AdamW β2-by-group: both NULL/regression. Uniform 0.95 optimal. | CLOSED 12:30 UTC |
| **#416** | askeladd | Aux AdamW β1=0.85: n=2 falsification. β1 axis closes at 0.8. | CLOSED earlier |
| **#439** | thorfinn | Logit soft-cap c∈{10,30}: symmetric +112.5 sr regression. c=15 in local optimum. | CLOSED 14:10 UTC |
| **#440** | tanjiro | Embed init scale std∈{0.5,2.0}: symmetric NULL. std=1.0 in local optimum. | CLOSED 14:33 UTC |
| **#444** | frieren | PMuon γ_power phase ramp both directions: Δsr=+37.5 both arms. γ=0.4 STATIC invariant. | **CLOSED 15:35 UTC** |

## Active experiments (8 students, 15:40 UTC)

| PR | Student | Run | Step | bl | ETA term | Status |
|---|---|---|---|---|---|---|
| **#482** | **frieren** | (awaiting pickup) | — | — | ~7h sequential | **NEW — body Muon WD partition: MLP-only vs attention-only WD.** First structural partition of body group. |
| **#480** | tanjiro | `kz1m6rzg` Arm A attn-scale=0.09 | 725 | 3.754 | ~2.9h | First softmax temperature scan running |
| **#476** | thorfinn | `j3gh6b0q` Arm A z-loss=1e-4 | 975 | 3.687 | ~2.5h | Z-loss running cleanly |
| **#465** | fern | `jyizvqdk` Arm A muon-lr=0.030 | 2275 | 3.368 | ~50m | Late cooldown |
| **#466** | edward | `p9teuxjm` Arm A aux-wd=0.001 | 2475 | 3.356 | ~36m | Late cooldown |
| **#463** | askeladd | `jdhgubwr` Arm A embed-eps=1e-8 | 2600 | 3.336 | ~28m | Late cooldown |
| **#460** | alphonse | `a7bmaf65` Arm A scalar_lr=0.020 | 3075 | 3.272 | **~12m** | Closest to terminal; fs=2975 locks NULL on 1st clause |
| **#448** | nezuko | `taremaia` Arm B cf-aux=0.85 | 2725 | 3.321 | ~22m | Late cooldown |

## Next terminal events (from 15:40 UTC)

1. **alphonse a7bmaf65** — ~15:52 UTC (~12 min). bl=3.272, fs=2975 already locked → NULL on first clause; would need val<3.264 in ~175 steps. Plausible NULL.
2. **nezuko taremaia** — ~16:02 UTC (~22 min).
3. **askeladd jdhgubwr** — ~16:08 UTC (~28 min).
4. **edward p9teuxjm** — ~16:16 UTC (~36 min).
5. **fern jyizvqdk** — ~16:30 UTC (~50 min).
6. **thorfinn j3gh6b0q** — ~18:10 UTC (~2.5h).
7. **tanjiro kz1m6rzg** — ~18:30 UTC (~2.9h).
8. **frieren #482** — depends on pickup; ~7h sequential after launch.

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 (Δsr=−37.5, Δval=−0.002942) | **MERGED 11:48 UTC** — current baseline. |
| **#367** | frieren | lm_head_lr=1/160: n=2 sr=2975 val=3.26722 | MERGED — prior baseline. |

## Current research focus (updated 15:40 UTC)

**Pattern intensifying: three consecutive axes (soft-cap, embed init, γ_power phase) closed at inherited defaults with symmetric bracket regressions.** Plus PMuon scalar axes (γ_power phase, β_cov static, LR warmup) all NULL via frieren's three closures. PMuon scalar HPs and inherited model constants are saturated at this op point. Productive frontier:

1. **Structurally novel mechanisms** (Z-loss orthogonal to soft-cap, softmax temperature): thorfinn #476, tanjiro #480.
2. **Body Muon structural partition** (MLP vs attention WD): frieren #482 — first partition of body group ever tested.
3. **Per-group optimizer axes still characterizing** (eps, WD on aux groups): askeladd #463, edward #466.
4. **Schedule decoupling** (per-group cooldown): nezuko #448.
5. **Body-Muon scalar mechanism** (Muon LR fine): fern #465.

## Open unexplored axes (candidate next assignments)

- **Pre-softmax logit scaling** (decouple temperature from soft-cap)
- **PMuon EMA bias correction revisit** (#307 closed; revisit at new op point?)
- **Lookahead-AdamW wrapper on aux** (#143 closed at old op point — being tested at r2)
- **scalar_lr × COOLDOWN_POWER interaction** (alphonse suggested compound after #460)
- **Different NS polynomial coefficients** (c ≠ 0 variants with asymmetric a,b)
- **Per-block residual scaling** (DeepNet-style gates) — being tested on r4 #452
- **Skip-connection LR multiplier**
- **β_cov scheduled ramp** (orthogonal to γ — frieren suggested as last untested PMuon axis)
- **Per-block LR multiplier on deepest vs shallowest blocks**
- **Output projection scale (block exit) — small-scale init for proj.weight**

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
