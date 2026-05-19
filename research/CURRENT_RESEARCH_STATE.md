# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-19 22:00 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## 🎯 LIVE: Frieren #482 MARGINAL WIN — seed-2 confirmation running

**Arm A `89lpkhfc`** (MLP-WD=0.05, ATTN-WD=0): sr=2925, val=3.2622 → Δsr=−12.5 ✓, Δval=−0.00208 ✓. **First body-Muon structural partition signal ever.**
**Seed-2 `qpbwahok` RUNNING step 500/3250** — ETA ~2.5h to terminal. If confirms (sr≤2925, val stat-sig at n=2 threshold 3.277), merge as new baseline.

## Axes CLOSED this cycle (11:48–22:00 UTC)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#447** | fern | NS adaptive threshold | CLOSED 12:25 UTC |
| **#433** | edward | Aux AdamW β2-by-group | CLOSED 12:30 UTC |
| **#416** | askeladd | Aux AdamW β1=0.85 | CLOSED earlier |
| **#439** | thorfinn | Logit soft-cap c∈{10,30} symmetric +112.5 sr regression | CLOSED 14:10 UTC |
| **#440** | tanjiro | Embed init scale std∈{0.5,2.0} symmetric NULL | CLOSED 14:33 UTC |
| **#444** | frieren | PMuon γ_power phase ramp both directions: Δsr=+37.5 both arms | CLOSED 15:35 UTC |
| **#448** | nezuko | Decoupled cooldown_frac aux∈{0.5, 0.85} clear asymmetric NULL | CLOSED 16:13 UTC |
| **#460** | alphonse | scalar_lr fine-scan {0.020,0.030} symmetric +37.5 sr both, Δval +0.0024 both. 0.025 confirmed local optimum. | CLOSED 19:38 UTC |
| **#463** | askeladd | Embed eps scan {1e-8, 1e-7} clean monotone NULL. eps=1e-10 confirmed optimal. | CLOSED 20:01 UTC |
| **#466** | edward | Aux WD scan {0.001, 0.01} clean monotone NULL (Δsr +12.5/+37.5, Δval +0.0013/+0.0007). aux WD=0 confirmed. | CLOSED 20:25 UTC |
| **#465** | fern | Body-Muon lr fine-scan {0.030, 0.040} symmetric NULL (Δsr=+62.5 both, Δval +0.005/+0.003). lr=0.035 confirmed locally optimal. | CLOSED 20:51 UTC |
| **#480** | tanjiro | Attn-scale scan {0.09, 0.15} asymmetric NULL (A: Δsr +87.5/Δval +0.006; B: Δsr +37.5/Δval +0.002 marginal). attn_scale=0.12 confirmed. | **CLOSED 21:59 UTC** |

## Active experiments (8 students, 22:00 UTC)

| PR | Student | Run | Step | bl | Status |
|---|---|---|---|---|---|
| **#511** | **tanjiro** | (awaiting pickup) | — | — | **NEW — NS_ITERS scan {10, 14} vs baseline 12. Preconditioner-quality axis, diversifies away from body-Muon partition cluster.** |
| **#505** | fern | (awaiting pickup) | — | — | Lookahead wrapper on body-Muon k∈{5, 10}, α=0.5 |
| **#503** | edward | (awaiting pickup) | — | — | Body-Muon WD schedule warmup-25pct vs cooldown-25pct |
| **#502** | askeladd | (awaiting pickup) | — | — | PMuon body β_cov scan {0.90, 0.99} vs 0.95 |
| **#499** | alphonse | `vrmveqoe` Arm A | ~1700 | 3.51 | Body-Muon LR partition MLP=0.042/ATTN=0.028 |
| **#486** | nezuko | `u23wjr7m` Arm B | ~1525 | 3.57 | Skylight TARGET_UW=0.45 (Arm A fs=3025 NULL) |
| **#482** | frieren | `qpbwahok` seed-2 | ~1800 | 3.475 | n=2 confirmation of Arm A marginal win (PRIMARY SIGNAL) |
| **#476** | thorfinn | `a6375en7` Arm B | ~3200 | 3.285, fs=-1 | z-loss=1e-3 trending clear NULL (target not hit). Close-ready in ~3 min. |

## Next terminal events (from 22:00 UTC)

1. **thorfinn `a6375en7`** — step 3200, ~3 min to terminal (target never hit, fs=-1).
2. **frieren seed-2** — ~1h to terminal (PRIMARY SIGNAL).
3. **alphonse #499** — ~1.3h to terminal.
4. **nezuko Arm B** — ~1.5h to terminal.
5. **edward #503, askeladd #502, fern #505, tanjiro #511** — depend on pickup.

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 (Δsr=−37.5, Δval=−0.002942) | **MERGED 11:48 UTC** — current baseline. |
| **#367** | frieren | lm_head_lr=1/160: n=2 sr=2975 val=3.26722 | MERGED — prior baseline. |

## Current research focus (updated 22:00 UTC)

**Per-substructure mechanism class is the live frontier.** Frieren #482 Arm A (MLP-WD=0.05 / ATTN-WD=0) crossed sr ≤ 2925 with stat-sig val at n=1. Seed-2 (`qpbwahok`) running step 1800/3250 (~1h to terminal). Active orthogonal axes:

1. **Body-Muon WD partition** (frieren #482 — seed-2 running)
2. **Body-Muon LR partition** (alphonse #499 — running)
3. **PMuon β_cov scalar scan** (askeladd #502 — awaiting pickup)
4. **Body-Muon WD schedule** (edward #503 — awaiting pickup)
5. **Lookahead wrapper on body-Muon** (fern #505 — awaiting pickup, wrapper-class)
6. **NS_ITERS scan** (tanjiro #511 — awaiting pickup, preconditioner-quality diversifier)

**Pattern emerging:** scalar axes saturate at inherited defaults. 12 axes closed this cycle: {scalar_lr, NS adaptive threshold, β2-by-group, β1, logit soft-cap, embed init, γ_power, cooldown_frac aux, embed eps, aux WD, body-Muon lr fine, attn_scale}. Aux AdamW scalars fully audited; body-Muon scalars fully audited; architectural scalars (attn_scale, embed init, logit soft-cap) all at inherited defaults. **Body-Muon structural+temporal+wrapper mechanisms + preconditioner quality are the live exploration frontier.**

## Open unexplored axes (candidate next assignments)

- **Per-block residual scaling** (DeepNet-style gates) — on r4 #452
- **Skip-connection LR multiplier** — UNTESTED at r1
- **Per-block LR multiplier** (early vs late blocks) — UNTESTED
- **Lookahead-AdamW wrapper** — closed at old op point; could retest
- **Gradient clipping for body-Muon** — fresh mechanism
- **Per-head Muon WD partition** (finer than MLP/attention split)
- **PMuon NS_ITERS scan** {10, 14} vs 12 — preconditioner quality axis
- **Embed eps below 1e-10** {1e-12, 1e-14} — gradient pointed *down* from #463

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
