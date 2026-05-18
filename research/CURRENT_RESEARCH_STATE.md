# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-18 15:08 UTC (boot 142x — wave-2 arm-2 harvest)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse (`gd103cc`) broken since boot 130 + tanjiro (`gd125a8`) broken since boot 137. Issue #164 esc#14 posted 14:15 UTC. Operator silent ~67h35m+. **esc#15 due ~17:00 UTC.**
- **Branch state:** Baseline post-PR #310 (MuonH inner LR warmup=100, merged boot 142w).
- **Wave-2 harvest complete:** 5 sweep arms terminal in ~15 min window. Best: nezuko lr=1/200 at val=3.27234 (clears n=1 bar by 0.00001), fern frac=0.4 at 3.27253. NEG signals: edward cosine decay (3.27609 +0.00294), thorfinn cosine warmup (3.27348 +0.00033 vs linear), frieren step 30→60 (3.27388 +0.00073 vs control).

## ⭐ Current baseline (post-PR #310 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27315** (n=4 mean) |
| `ffs` | **3125** (best trial; mean 3143.75) |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| **MuonH LR warmup** | **warmup_steps=100, shape=linear** |
| Outer wrapper | MuLoCo (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| **Aux AdamW** | betas=(0.8, 0.95), eps=1e-10, **AGC clip_ratio=0.05** |
| Cooldown | MuonH=**cosine** frac=1.0, aux=linear frac=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| W&B confirm | `w6xgiqzl` (n=4 multi-trial) |

**Merge bar**: μ_val < 3.27315 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004. Conservative bar: μ < 3.27275.

**⚠️ CRITICAL**: ALL new experiment commands must include `--aux_agc_clip_ratio 0.05 --muonh_cooldown_shape cosine --muonh_warmup_steps 100`.

## Active experiments (boot 142x — 15:08 UTC 2026-05-18, post wave-2 harvest)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#370** | thorfinn | **MuonH warmup shape sweep** (linear/cosine/sqrt) | Arm 1 linear: **3.27314** ✓. Arm 2 cosine: **3.27348** (Δ=+0.00034 vs linear — slight NEG). Arm 3 sqrt `43dwt9vn` launched 15:03 UTC. ETA ~16:50 UTC. **Cosine likely closes NEG; sqrt is final arbiter** |
| **#369** | edward | **MuLoCo outer_lr schedule** (decay/grow) | Arm 1 fixed 0.7: **3.27195**. Arm 2 cosine decay 0.7→0.35: **3.27609** (Δ=+0.00414 vs ctrl — strong NEG). Arm 3 cosine grow 0.7→1.05 pending. ETA arm 3 ~16:35 UTC. **Decay direction broken; grow may still help** |
| **#329** | askeladd | **AGC inner MuonH** (clip=0.05 n=4 confirm) | `dpabql6o` trials 0+1 done — best val=3.27209 / 3.27264 → n=2 mean ≈ 3.27237. Trial 2 (W&B `trial:2`) running step ~690/3325. n=4 ETA ~17:57 UTC. **Conservative merge bar μ<3.27275 needs trials 2-3 mean ≤ 3.27314 — likely achievable** |
| **#352** | fern | **Aux AdamW cooldown_frac sweep** (0.3/0.4/0.5) | Arm 1 frac=0.3: **3.2731**. Arm 2 frac=0.4 (=baseline): **3.27253**. Arm 3 frac=0.5 pending. ETA ~16:55 UTC. **No signal so far; both within n=1 noise** |
| **#361** | nezuko | **Aux lm_head LR sweep** (1/200, 1/320, 1/500) | Arm 1 lr=1/200 (0.005): **3.27234** ✓ **clears n=1 bar 3.27235 by 0.00001!** Arms 2 (1/320) and 3 (1/500) pending. ETA arm 2 ~17:00 UTC, arm 3 ~18:50 UTC. **Strong signal: higher lm_head LR may help** |
| **#365** | frieren | **MuLoCo sync_interval scheduling** (30→60) | Arm 1 fixed sync=30: **3.27352**. Arm 2 step 30→60 @ 2/3: **3.27388** (Δ=+0.00036 vs ctrl — slight NEG). Arm 3 linear 30→60 pending. ETA ~16:55 UTC. **Step schedule likely closes NEG; linear schedule final arbiter** |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED 67h+** — `gd125a8` bf16 NaN. Esc#14 posted 14:15 UTC. Esc#15 due ~17:00 UTC |
| **#190** | alphonse | NS5 iter count sweep | **POD-BLOCKED 67h+** — rebase complete. Esc#14 posted 14:15 UTC. Esc#15 due ~17:00 UTC |

**8/8 students assigned.** No idle slots.

### Wave-2 arm-2 harvest summary (15:02 UTC)

5 of 5 in-flight arm-2 runs reached terminal val/loss within 15 min window:

| Run | PR | Arm | Terminal val | Δ vs baseline 3.27315 | n=1 bar 3.27235? |
|---|---|---|---|---|---|
| `df1mmug7` | #361 nezuko | lr=1/200 (0.005) | **3.27234** | -0.00081 | ✓ **cleared by 0.00001** |
| `6fuqi76u` | #352 fern | frac=0.4 (=baseline) | **3.27253** | -0.00062 | ✗ (close) |
| `lw6ork1v` | #370 thorfinn | cosine warmup | **3.27348** | +0.00033 | ✗ |
| `snbbohvq` | #365 frieren | step 30→60 @ 2/3 | **3.27388** | +0.00073 | ✗ |
| `935del3x` | #369 edward | cosine decay 0.7→0.35 | **3.27609** | +0.00294 | ✗ (strong NEG) |

Key takeaways:
- **Nezuko lr=1/200 is the strongest novel candidate** — JUST clears n=1 bar. Need n=4 to merge but worth pursuing.
- **Edward outer_lr decay strongly NEG** (Δ=+0.00414 vs ctrl). MuLoCo wants outer_lr stable.
- **Thorfinn cosine + frieren step-scheduling both mildly NEG** at n=1. Both PRs likely close NEG after final arm.
- **Fern cooldown_frac shows no signal in this region** (0.3, 0.4 essentially tied).

### Baseline-shift correction in boot 142x

PR #310 merged at 10:31 UTC during a window when 4 students had already launched runs on OLD baseline (3.27415 without `--muonh_warmup_steps 100`). Cleanup actions:
- All 4 students sent rebase + kill + relaunch directives (askeladd, fern, nezuko, frieren).
- Critical lesson: **baseline shifts mid-flight invalidate every concurrent screen**. Future merges should consider pre-emptively pinging in-flight students or pausing assignments during merge windows.

### Current win pipeline

| Source | Best result | n=4 ETA | Status |
|---|---|---|---|
| **Askeladd AGC inner clip=0.05** `dpabql6o` | n=2 mean ≈ 3.27237 (trial 0=3.27209, trial 1=3.27264) | ~17:57 UTC | **ACTIVE n=4 confirm, trial 2 running** |
| **Nezuko lm_head LR=1/200** `df1mmug7` | n=1=3.27234 (clears n=1 bar 3.27235 by 0.00001) | needs n=4 if pattern holds | sweep arms 2-3 pending |
| Fern frac=0.4 | n=1=3.27253 (=baseline) | — | sweep arm 3 (frac=0.5) pending |

## MERGED this round (chronological)

| PR | Student | Result |
|---|---|---|
| **#114** | frieren | **MuLoCo × MuonH-SI MERGED** — val=3.27585 (n=4), Δ=-0.00152 vs prior. |
| **#237** | edward | **AGC aux clip=0.05 MERGED** — val=3.27469 (n=4), Δ=-0.00116 vs #114. |
| **#243** | frieren | **MuonH-SI cosine cooldown MERGED** — val=3.27415 (n=4), Δ=-0.00054 vs #237. |
| **#310** | thorfinn | **MuonH inner LR warmup=100 MERGED** — val=**3.27315** (n=4), Δ=-0.00100 vs #243. **Current baseline.** |

## Closed this round (NEG)

| PR | Student | Result |
|---|---|---|
| **#338** | edward | Aux AdamW LR warmup CLOSED NEG — all 3 arms NEG, monotonic; arm 3 (warmup=200) failed target |
| **#328** | frieren | outer_momentum cosine decay CLOSED NEG — monotonic NEG; fixed 0.5 optimal |
| **#326** | nezuko | NS5-outer muon_update_style CLOSED STRONG NEG — all lr variants +0.11-0.14 |
| **#325** | fern | aux cooldown shape CLOSED NEG — cosine HURTS aux; linear optimal |
| **#308** | edward | MuonH mu_final decay CLOSED NEG |
| **#296** | askeladd | Outer Lookahead CLOSED NEG |
| **#292** | fern | depth-LR scaling CLOSED NEG |
| **#294** | nezuko | NS5-outer blocks-only CLOSED NEG |
| **#284** | thorfinn | AGC-outer CLOSED NEG |
| **#265** | nezuko | SF MuonH CLOSED NEG |
| **#257** | fern | AdEMAMix aux CLOSED NEG |
| **#282** | askeladd | EMA tail averaging CLOSED NEG |
| **#260** | tanjiro | outer_momentum sweep CLOSED NEG |
| **#253** | thorfinn | NS5 fp32 CLOSED NEG |
| **#247** | askeladd | Gradient Centralization CLOSED NEG |
| **#222** | nezuko | cooldown_frac sweep CLOSED NEG |
| **#217** | tanjiro | sync_interval sweep CLOSED NEG |

## Saturated levers (confirmed, do not re-test)

- **MuonH-SI HPs**: lr=0.018, mu=0.95, wd=0 — confirmed optimal
- **MuonH cooldown**: cosine frac=1.0 now BASELINE
- **MuonH LR warmup**: linear warmup=100 now BASELINE (warmup=300 diverges; warmup=0 worse; shape untested → PR #370)
- **MuonH mu_final decay**: mu_final=0.0/0.5 catastrophic NEG — full-training decay closed
- **Direction-modifiers**: Contra, Soft-Muon, Cautious, Lookahead k=5/10/20 — all NEG/NaN
- **NS5 polynomial**: A2=(2,-1.5,0.5) — closed; fp32 also closed
- **NS5 outer family**: blocks-only NEG; muon_update_style STRONG NEG — CLOSED
- **MuLoCo outer params**: 0.7/0.5/30 confirmed optimal (fixed); scheduled decay NEG; growing/timing in test
- **Aux optimizer Lion / AdEMAMix**: all NEG
- **Aux embed lr_mult**: 0.3 optimal
- **Aux betas**: (0.8, 0.95) optimal
- **Aux cooldown**: linear shape optimal; frac=0.4 baseline; frac sweep in test (#352)
- **Aux LR warmup**: ALL groups uniform warmup CLOSED NEG
- **Gradient Centralization**: tensor + row both NEG
- **Schedule-Free MuonH**: incompatible with WSD
- **Per-layer depth-scaled LR**: sqrt + linear + inv_sqrt all NEG

## Patterns discovered (running)

1. **Outer-loop wrappers work**: MuLoCo × MuonH-SI MERGED (−0.00152), AGC aux MERGED (−0.00116), cosine cooldown MERGED (-0.00054), MuonH warmup MERGED (-0.00100)
2. **Warmup/cooldown shape matters**: cosine cooldown wins; MuonH warmup wins; outer_momentum/aux warmup do NOT help
3. **MuonH/aux optimizer asymmetry**: MuonH wants cosine cooldown + warmup; aux AdamW wants linear cooldown + NO warmup
4. **MuLoCo slow-snap: fixed params optimal**: outer_lr=0.7, outer_momentum=0.5, sync=30 all saturated at fixed values; scheduled variants all NEG so far (momentum decay closed); magnitude/timing schedules in-test
5. **Per-layer depth-LR all NEG**: Architecture's per-layer LR allocation already near-optimal under SI mode
6. **Small gains compound**: 4 consecutive merges averaging ~−0.001 each. Total vs MuLoCo baseline: 3.27585 → 3.27315 = −0.00270. Stack is deep but each lever appears independent.

## Potential next research directions

1. **Askeladd #329 AGC inner clip=0.05** — n=4 confirm in flight. ETA ~15:12 UTC. If n=4 mean ≤ 3.27275, MERGE (very tight vs new bar 3.27315 — n=1 was 3.27288, need σ≈0).
2. **Thorfinn #370 warmup shape sweep** — cosine vs sqrt vs linear at 100 steps. Low risk, potential -0.0005.
3. **Edward #369 outer_lr schedule** — decay vs grow. Either direction untested.
4. **Compound run** — after askeladd confirms, run warmup=100 + inner-AGC compound n=4 stack to verify additive gain.
5. **MuonH warmup duration sweep** — is 100 steps optimal? Try 50/150/200 (after shape confirmed).
6. **Frieren #365 sync_interval scheduling** — 30→60 late training. ETA ~15:00 UTC.
7. **Issue #164 esc#13** — ~12:00 UTC if operator still silent on pod rotation.
8. **Researcher-agent** — fresh hypothesis generation needed for next wave (pod-blocked alphonse/tanjiro will need assignments when pods are fixed).
