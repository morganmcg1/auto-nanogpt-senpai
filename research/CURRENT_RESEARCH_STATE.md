# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-19 16:15 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278).

## Axes CLOSED this cycle (11:48–16:13 UTC)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#447** | fern | NS adaptive threshold: mechanism never engages (residual plateau ~6.9). | CLOSED 12:25 UTC |
| **#433** | edward | Aux AdamW β2-by-group: both NULL/regression. Uniform 0.95 optimal. | CLOSED 12:30 UTC |
| **#416** | askeladd | Aux AdamW β1=0.85: n=2 falsification. β1 axis closes at 0.8. | CLOSED earlier |
| **#439** | thorfinn | Logit soft-cap c∈{10,30}: symmetric +112.5 sr regression. c=15 in local optimum. | CLOSED 14:10 UTC |
| **#440** | tanjiro | Embed init scale std∈{0.5,2.0}: symmetric NULL. std=1.0 in local optimum. | CLOSED 14:33 UTC |
| **#444** | frieren | PMuon γ_power phase ramp both directions: Δsr=+37.5 both arms. γ=0.4 STATIC invariant. | CLOSED 15:35 UTC |
| **#448** | nezuko | Decoupled cooldown_frac aux∈{0.5, 0.85} vs body 0.7: clear asymmetric NULL. cf=0.7 uniform optimal. | **CLOSED 16:13 UTC** |

## Active experiments (8 students, 16:15 UTC)

| PR | Student | Run | Step | bl | ETA term | Status |
|---|---|---|---|---|---|---|
| **#486** | **nezuko** | (awaiting pickup) | — | — | ~7h sequential | **NEW — Skylight u/w-floor TARGET_UW scan {0.25, 0.45} vs baseline 0.35.** First scan of floor-amplification threshold. |
| **#482** | frieren | Arm A `89lpkhfc` post-correction retry | 225+ | running | ~3.4h | Two-Muon partition approach (after Muon ctor fix); diagnostic alias `optimizer2=optimizer2_mlp` |
| **#480** | tanjiro | `kz1m6rzg` Arm A attn-scale=0.09 | 1275 | 3.62 | ~2.5h | First softmax temperature scan |
| **#476** | thorfinn | `j3gh6b0q` Arm A z-loss=1e-4 | 1500 | 3.56 | ~2h | Z-loss running cleanly |
| **#466** | edward | `p9teuxjm` Arm A aux-wd=0.001 | 3000 | 3.276 | **~17m** | fs=2950 marginal Δsr=+12.5 (within 25); Arm B not yet launched |
| **#465** | fern | `jyizvqdk` Arm A muon-lr=0.030 | 2800 | 3.300 | ~30m | Late cooldown, fs not yet reached |
| **#463** | askeladd | `jdhgubwr` Arm A embed-eps=1e-8 | 3125 | 3.270 | **~8m** | fs=2975 locked NULL Δsr=+37.5; Arm B not yet launched |
| **#460** | alphonse | Arm A TERMINAL NULL; Arm B `evr56g3n` running | 275+ | running | ~3.4h | Arm A NULL (sr=2975 Δsr=+37.5, Δval=+0.002); Arm B scalar_lr=0.030 |

## Next terminal events (from 16:15 UTC)

1. **askeladd jdhgubwr** — ~16:23 UTC (~8 min). Arm A fs=2975 locked NULL.
2. **edward p9teuxjm** — ~16:32 UTC (~17 min). Arm A fs=2950 marginal NULL Δsr=+12.5.
3. **fern jyizvqdk** — ~16:45 UTC (~30 min). Arm A fs not yet reached.
4. **thorfinn j3gh6b0q** — ~18:15 UTC (~2h). Arm A.
5. **tanjiro kz1m6rzg** — ~18:45 UTC (~2.5h). Arm A.
6. **alphonse evr56g3n Arm B** — ~19:30 UTC (~3.4h).
7. **frieren 89lpkhfc Arm A** — ~19:35 UTC (~3.4h).
8. **nezuko #486** — depends on pickup; ~7h sequential after launch.

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 (Δsr=−37.5, Δval=−0.002942) | **MERGED 11:48 UTC** — current baseline. |
| **#367** | frieren | lm_head_lr=1/160: n=2 sr=2975 val=3.26722 | MERGED — prior baseline. |

## Current research focus (updated 16:15 UTC)

**Pattern fully established: four consecutive axes (soft-cap c=15, embed std=1.0, γ=0.4 static, cf=0.7 uniform) closed at inherited defaults with bracket regressions.** Simple inherited-scalar axes are saturated at this op point. PMuon scalar HPs particularly characterized (frieren did 3 closures: γ_power phase, β_cov static, LR warmup). Productive frontier:

1. **Structurally novel mechanisms** (Z-loss orthogonal to soft-cap, softmax temperature): thorfinn #476, tanjiro #480.
2. **Body Muon structural partition** (MLP vs attention WD): frieren #482 — first partition of body group ever tested.
3. **Optimizer threshold mechanisms still uncharacterized** (Skylight u/w-floor): nezuko #486 — first scan of `TARGET_UW=0.35` floor amplification threshold.
4. **Per-group optimizer axes still characterizing** (eps, WD on aux groups): askeladd #463, edward #466.
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
