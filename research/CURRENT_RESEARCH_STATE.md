# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-19 23:50 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## 🔚 Frieren #482 marginal-win NULLed at n=2 (CLOSED 23:25 UTC)

**Seed-2 `qpbwahok`** landed fs=2975, val=3.26593. **n=2 mean: sr=2950 (Δsr=+12.5 vs baseline), val=3.264065 (Δval=−0.000213 ≪ stat-sig margin 0.001).** Seed-1 Arm A win (sr=2925, val=3.2622) didn't replicate — within seed noise. **Axis CLOSES at uniform body-Muon WD=0.025.** This is the textbook n=2 filter doing its job on a marginal n=1 win.

## Axes CLOSED this cycle (11:48–23:50 UTC)

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
| **#480** | tanjiro | Attn-scale scan {0.09, 0.15} asymmetric NULL (A: Δsr +87.5/Δval +0.006; B: Δsr +37.5/Δval +0.002 marginal). attn_scale=0.12 confirmed. | CLOSED 21:59 UTC |
| **#476** | thorfinn | Z-loss scan {1e-4, 1e-3} clear monotone NULL (A: Δsr +37.5/Δval +0.0028; B: DNF/Δval +0.02). z-loss=0 confirmed; mechanism net-harmful. | CLOSED 22:08 UTC |
| **#482** | frieren | Body-Muon WD partition (MLP=0.05, ATTN=0): seed-1 sr=2925 val=3.2622 marginal win, seed-2 sr=2975 val=3.26593. **n=2 mean sr=2950, Δval=−0.0002 (≪ 0.001 stat-sig)**. Per-substructure WD partition does not improve over uniform WD. | **CLOSED 23:25 UTC** |

## Active experiments (8 students, 23:50 UTC)

| PR | Student | Run | Step | bl | Status |
|---|---|---|---|---|---|
| **#519** | **frieren** | (awaiting pickup) | — | — | **NEW — PMuon γ pruning ablation γ_power∈{0, 0.8} vs baseline 0.4. Is the γ mechanism load-bearing? First *ablation*-class test (γ=0 fully prunes correction).** |
| **#513** | thorfinn | `2w9fkwqa` Arm A | ~1342 | 3.59 | Body-Muon gradient clipping max_norm=1.0 (Arm B max_norm=0.5). Damping family. ~2.5h to terminal. |
| **#511** | tanjiro | `x6pxjdk4` Arm A | ~1575 | 3.53 | NS_ITERS=10 (Arm B =14). Preconditioner-quality axis. ~2.2h to terminal. |
| **#505** | fern | `8ad3mzjz` Arm A | ~2025 | 3.39 | Lookahead k=5 (Arm B k=10), α=0.5 on body-Muon. Wrapper-class first test. ~1.4h to terminal. |
| **#503** | edward | `vcc1mty6` Arm A | ~2776 | 3.30 | Body-Muon WD warmup-25pct schedule. Val ~3.30 at step 2776 — trailing baseline (~3.32 at this step is acceptable cooldown territory). ~35 min to terminal. |
| **#502** | askeladd | Arm A `o31yd0nw` **FINISHED** fs=2950 val=3.264775 (Δsr=+12.5, Δval=+0.000497 — marginal/NULL); Arm B `7donghzb` β_cov=0.99 step 1 just started | — | — | β_cov=0.90 marginal NULL. Awaiting Arm B verdict (~3.5h). |
| **#499** | alphonse | Arm A `vrmveqoe` **FINISHED** fs=3025 val=3.270402 (Δsr=+87.5, Δval=+0.0061 — clear NULL); Arm B `tdw0diir` (MLP=0.028/ATTN=0.042 swap) step 1 just started | — | — | MLP-fast/ATTN-slow direction NULL. Awaiting swap direction (~3h). |
| **#486** | nezuko | `u23wjr7m` Arm B TARGET_UW=0.45 | ~3100 | 3.27 | Step 3100/3250, fs=3025 — NULL trajectory. ~5 min to terminal. |

## Next terminal events (from 23:50 UTC)

1. **nezuko Arm B** — ~5 min to terminal (Skylight 0.45 NULL likely).
2. **edward #503 Arm A** — ~35 min to terminal (val/loss trajectory looks weak, likely NULL).
3. **fern #505 Arm A** — ~1.4h to terminal (Lookahead wrapper).
4. **tanjiro #511 Arm A** — ~2.2h to terminal (NS_ITERS=10).
5. **thorfinn #513 Arm A** — ~2.5h to terminal (grad-clip max_norm=1.0).
6. **alphonse #499 Arm B + askeladd #502 Arm B** — ~3h each (swap arms started).
7. **frieren #519** — depends on pickup, then ~3.5h.

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 (Δsr=−37.5, Δval=−0.002942) | **MERGED 11:48 UTC** — current baseline. |
| **#367** | frieren | lm_head_lr=1/160: n=2 sr=2975 val=3.26722 | MERGED — prior baseline. |

## Current research focus (updated 23:50 UTC)

**Per-substructure partition hypothesis partially refuted; body-Muon mechanism diversification on multiple orthogonal axes is the live frontier.** Frieren #482 closed at n=2 NULL — the textbook seed-1 marginal-win → seed-2 regression-to-mean pattern. Alphonse #499 Arm A NULL (MLP-fast/ATTN-slow direction); Arm B (swap) is the last partition-direction test. Active orthogonal axes:

1. **Body-Muon LR partition swap direction** (alphonse #499 — Arm B running)
2. **PMuon β_cov scalar** (askeladd #502 — Arm A marginal NULL, Arm B running)
3. **Body-Muon WD schedule** (edward #503 — Arm A near-terminal)
4. **Lookahead wrapper on body-Muon** (fern #505 — Arm A running)
5. **NS_ITERS scan** (tanjiro #511 — Arm A running, preconditioner-quality)
6. **Body-Muon gradient clipping** (thorfinn #513 — Arm A running, damping)
7. **PMuon γ pruning ablation** (frieren #519 — awaiting pickup, ablation-class)
8. **Skylight u/w-floor** (nezuko #486 — Arm B near-terminal)

**Pattern emerging:** scalar axes saturate at inherited defaults. **14 axes closed this cycle**: {scalar_lr, NS adaptive threshold, β2-by-group, β1, logit soft-cap, embed init, γ_power phase ramp, cooldown_frac aux, embed eps, aux WD, body-Muon lr fine, attn_scale, z-loss, body-Muon WD partition}. Aux AdamW scalars fully audited; body-Muon scalars fully audited; architectural scalars fully audited; regularizer family closes net-harmful; per-substructure WD partition closes NULL at n=2. **Body-Muon mechanism diversification: partition (swap arm remaining), scalar (β_cov), schedule (WD), wrapper (Lookahead), preconditioner (NS_ITERS), damping (grad-clip), ablation (γ pruning) all active in parallel — 7 distinct mechanism families.**

## Open unexplored axes (candidate next assignments)

- **Per-block residual scaling** (DeepNet-style gates) — on r4 #452
- **Skip-connection LR multiplier** — UNTESTED at r1
- **Per-block LR multiplier** (early vs late blocks) — UNTESTED
- **Lookahead-AdamW wrapper** — closed at old op point; could retest after #505 verdict
- **Per-head Muon WD partition** (finer than MLP/attention split) — partition class regressing, lower priority
- **Embed eps below 1e-10** {1e-12, 1e-14} — gradient pointed *down* from #463
- **Tied lm_head ↔ embed** (weight sharing experiment)
- **Curriculum/data-ordering** — UNTESTED
- **Auxiliary distillation/self-distillation step** — UNTESTED

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
