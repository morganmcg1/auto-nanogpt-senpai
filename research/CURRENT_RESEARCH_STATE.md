# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-19 14:35 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278).

## Three axes CLOSED this cycle (11:48–14:33 UTC)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#447** | fern | NS adaptive threshold: mechanism never engages (residual plateau ~6.9). | CLOSED 12:25 UTC |
| **#433** | edward | Aux AdamW β2-by-group: both NULL/regression. Uniform 0.95 optimal. | CLOSED 12:30 UTC |
| **#416** | askeladd | Aux AdamW β1=0.85: n=2 falsification. β1 axis closes at 0.8. | CLOSED earlier |
| **#439** | thorfinn | Logit soft-cap c∈{10,30}: symmetric +112.5 sr regression both arms. c=15 in local optimum. | **CLOSED 14:10 UTC** |
| **#440** | tanjiro | Embed init scale std∈{0.5,2.0}: symmetric NULL both arms. std=1.0 in local optimum. | **CLOSED 14:33 UTC** |

## Active experiments (8 students, 14:35 UTC)

| PR | Student | Run | Step | bl | ETA term | Status |
|---|---|---|---|---|---|---|
| **#480** | **tanjiro** | (awaiting pickup) | — | — | ~3.5h after launch | **NEW — attention scale scan {0.09, 0.15} vs baseline 0.12.** First scan of softmax temperature. |
| **#476** | **thorfinn** | `j3gh6b0q` Arm A z-loss=1e-4 | 125 | 4.47 | ~4.7h | Z-loss (log-Z regularizer) just started; orthogonal to soft-cap. |
| **#465** | fern | `jyizvqdk` Arm A muon-lr=0.030 | 1450 | 3.5423 | ~136m | Duplicate killed; canonical solo again. |
| **#466** | edward | `p9teuxjm` Arm A aux-wd=0.001 | 1650 | 3.5041 | ~115m | Stable progression |
| **#463** | askeladd | `jdhgubwr` Arm A embed-eps=1e-8 | 1725 | 3.5036 | ~101m | Stable progression |
| **#460** | alphonse | `a7bmaf65` Arm A scalar_lr=0.020 | 2250 | 3.3767 | ~70m | Mid-cooldown |
| **#448** | nezuko | `taremaia` Arm B cf-aux=0.85 | 1900 | 3.4477 | ~94m | Mid-cooldown |
| **#444** | frieren | `894sq3ig` Arm B γ ramp 0.4→0.5 | 2525 | 3.3355 | **~50m** | Closest to terminal |

## Next terminal events (from 14:35 UTC)

1. **frieren 894sq3ig** — ~15:25 UTC (50 min). bl=3.336, late cooldown. Plausible NULL (would need bl<3.264 in 700 steps).
2. **alphonse a7bmaf65** — ~15:45 UTC (70 min). bl=3.38.
3. **nezuko taremaia** — ~16:09 UTC (94 min).
4. **askeladd jdhgubwr** — ~16:16 UTC (101 min).
5. **edward p9teuxjm** — ~16:30 UTC (115 min).
6. **fern jyizvqdk** — ~16:51 UTC (136 min).
7. **thorfinn j3gh6b0q** — ~19:15 UTC (4.7h, just started).
8. **tanjiro PR #480** — depends on pickup time (just assigned).

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 (Δsr=−37.5, Δval=−0.002942) | **MERGED 11:48 UTC** — current baseline. |
| **#367** | frieren | lm_head_lr=1/160: n=2 sr=2975 val=3.26722 | MERGED — prior baseline. |

## Current research focus (updated 14:35 UTC)

**Pattern emerging: two consecutive axes (soft-cap, embed init) closed at inherited defaults with symmetric bracket regressions.** This suggests the inherited constants in the model definition are largely well-tuned for this op point. Productive frontier shifts toward:

1. **Structurally novel mechanisms** (Z-loss orthogonal to soft-cap, attention temperature as inherited-but-not-round-number constant): thorfinn #476, tanjiro #480.
2. **Per-group optimizer axes still characterizing** (eps, WD on aux groups): askeladd #463, edward #466.
3. **Schedule decoupling** (per-group cooldown): nezuko #448.
4. **Body-Muon mechanism axes**: fern #465 (Muon LR fine), frieren #444 (γ phase).

## Open unexplored axes (candidate next assignments)

- **Pre-softmax logit scaling** (decouple temperature from soft-cap)
- **PMuon EMA bias correction revisit** (#307 closed; revisit at new op point?)
- **Lookahead-AdamW wrapper on aux** (#143 closed at old op point)
- **scalar_lr × COOLDOWN_POWER interaction** (alphonse suggested compound after #460)
- **Different NS polynomial coefficients** (c ≠ 0 variants with asymmetric a,b)
- **MLP-only vs attention-only WD** (orthogonal partition of body WD)
- **Per-block residual scaling** (DeepNet-style gates)
- **Skip-connection LR multiplier**
- **Body weight std multiplier** (tanjiro suggested — 0.33 constant in body init never scanned)

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
