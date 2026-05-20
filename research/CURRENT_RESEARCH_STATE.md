# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-20 03:42 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Axes CLOSED this cycle (11:48–03:42 UTC)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#447** | fern | NS adaptive threshold | CLOSED 12:25 UTC |
| **#433** | edward | Aux AdamW β2-by-group | CLOSED 12:30 UTC |
| **#416** | askeladd | Aux AdamW β1=0.85 | CLOSED earlier |
| **#439** | thorfinn | Logit soft-cap c∈{10,30} symmetric +112.5 sr regression | CLOSED 14:10 UTC |
| **#440** | tanjiro | Embed init scale std∈{0.5,2.0} symmetric NULL | CLOSED 14:33 UTC |
| **#444** | frieren | PMuon γ_power phase ramp both directions: Δsr=+37.5 both arms | CLOSED 15:35 UTC |
| **#448** | nezuko | Decoupled cooldown_frac aux∈{0.5, 0.85} clear asymmetric NULL | CLOSED 16:13 UTC |
| **#460** | alphonse | scalar_lr fine-scan {0.020,0.030} symmetric +37.5 sr both. 0.025 confirmed. | CLOSED 19:38 UTC |
| **#463** | askeladd | Embed eps scan {1e-8, 1e-7} clean monotone NULL. eps=1e-10 confirmed. | CLOSED 20:01 UTC |
| **#466** | edward | Aux WD scan {0.001, 0.01} clean monotone NULL. aux WD=0 confirmed. | CLOSED 20:25 UTC |
| **#465** | fern | Body-Muon lr fine-scan {0.030, 0.040} symmetric NULL. lr=0.035 confirmed. | CLOSED 20:51 UTC |
| **#480** | tanjiro | Attn-scale scan {0.09, 0.15} asymmetric NULL. attn_scale=0.12 confirmed. | CLOSED 21:59 UTC |
| **#476** | thorfinn | Z-loss scan {1e-4, 1e-3} clean monotone NULL. z-loss=0 confirmed; net-harmful. | CLOSED 22:08 UTC |
| **#482** | frieren | Body-Muon WD partition (MLP=0.05, ATTN=0): n=2 mean sr=2950, Δval=−0.0002. Per-substructure WD partition NULL. | CLOSED 23:25 UTC |
| **#486** | nezuko | Skylight u/w-floor scan TARGET_UW∈{0.25, 0.45}: symmetric +87.5 sr both arms. 0.35 confirmed local optimum. fired_fraction=0.16/0.87/0.93 reveals floor amplifying cooldown-phase updates. | CLOSED 00:15 UTC |
| **#502** | askeladd | PMuon β_cov scan {0.90, 0.99}: Arm A fs=2950 val=3.264775 (marginal NULL Δsr=+12.5 Δval=+0.0005), Arm B fs=3000 val=3.269313 (clear NULL Δsr=+62.5 Δval=+0.005). β_cov=0.95 locally optimal; asymmetric loss curve rules out scheduled ramp. PMuon scalar block saturated. | CLOSED 03:25 UTC |
| **#499** | alphonse | Body-Muon LR per-type partition (MLP=0.042/ATTN=0.028 vs swap): both arms clear NULL ~Δval=+0.006 symmetric. Δsr +62.5–+87.5. Centered geomean preserved (sqrt(MLP×ATTN)=0.0343≈0.035) — *the split itself* hurts, not the effective LR. PMuon's per-matrix whitening already equalizes per-module gradient geometry. | **CLOSED 03:40 UTC** |

## Active experiments (8 students, 03:42 UTC)

| PR | Student | Run | Step/3250 | bl | Status |
|---|---|---|---|---|---|
| **#535** | **alphonse** | (awaiting pickup) | — | — | **NEW — Sub-MLP LR partition: c_fc vs c_proj. Arm A c_fc-heavy (1.20x/0.80x), Arm B c_proj-heavy (0.80x/1.20x). Fresh sub-axis inside MLP — student-suggested follow-up from #499 closure.** |
| **#532** | askeladd | (awaiting pickup) | — | — | NEW — Body-Muon per-block LR multiplier (depth-based partition). |
| **#522** | nezuko | `1ohe6cf7` Arm A | ~2225 | 3.363 | Skylight floor cooldown decay (linear). Arm B (hard switch) pending. |
| **#519** | frieren | `7baa1iif` Arm A | ~3000 | 3.293 | PMuon γ_power=0 (γ load-bearing hypothesis). fs not yet triggered; likely DNF/strong NULL. ~25 min to terminal. |
| **#513** | thorfinn | Arm B `m5fjt5gz` clip=0.5 | ~592 | 3.80 | Body-Muon gradient clipping. Arm A (clip=1.0) closed NULL fs=3000. ~3h to terminal. |
| **#511** | tanjiro | Arm B `ldezjd0y` NS_ITERS=14 | ~1000 | 3.66 | NS preconditioner quality. Arm A (NS=10) closed NULL fs=3000. ~2.5h to terminal. |
| **#505** | fern | Arm B `e3zkawez` Lookahead k=10 | ~1100 | 3.58 | Body-Muon Lookahead wrapper. Arm A (k=5) STRONG NULL fs=-1 val=3.284. ~2.5h to terminal. |
| **#503** | edward | Arm B `bu075bqm` cooldown-25pct | ~2321 | 3.377 | Body-Muon WD schedule. Arm A (warmup-25pct) marginal NULL fs=2950 val=3.265. ~1h to terminal. |

## Next terminal events (from 03:42 UTC)

1. **frieren #519 Arm A** — ~15 min to step 3250 terminal. γ=0 likely strong NULL.
2. **edward #503 Arm B** — ~1h to terminal.
3. **nezuko #522 Arm A** — ~1h to terminal (had crash/restart cycle; `1ohe6cf7` is clean restart).
4. **fern #505 / tanjiro #511 Arm Bs** — ~2.5h to terminal.
5. **thorfinn #513 Arm B** — ~3h to terminal.
6. **alphonse #535 + askeladd #532** — depend on pickup.

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 | **MERGED 11:48 UTC** — current baseline. |

## Current research focus (updated 03:42 UTC)

**Body-Muon mechanism diversification on 8 orthogonal axes.** 17 scalar/mechanism axes closed at inherited defaults. Active families:

1. **LR partition by sub-MLP geometry** (alphonse #535 — NEW): tests c_fc vs c_proj partition inside MLP. Refines #499 NULL.
2. **LR partition by depth** (askeladd #532 — NEW): early-fast vs late-fast block multiplier. Fresh class.
3. **WD schedule** (edward #503 — Arm A marginal NULL, Arm B near-terminal): first temporal schedule on body-Muon
4. **Lookahead wrapper** (fern #505 — Arm A STRONG NULL k=5, Arm B k=10 mid-flight): wrapper-class
5. **NS preconditioner quality** (tanjiro #511 — Arm A clear NULL NS=10, Arm B NS=14): preconditioner axis
6. **Gradient clipping** (thorfinn #513 — Arm A clear NULL clip=1.0, Arm B clip=0.5): damping family
7. **PMuon γ pruning ablation** (frieren #519 — Arm A γ=0 near-terminal, looks strong NULL): ablation-class; γ confirmed load-bearing
8. **Skylight floor schedule** (nezuko #522 — Arm A linear decay running): cooldown↔floor interaction probe

**Emerging pattern after 17 closed axes:** mechanism scalars (PMuon γ_power, β_cov, NS_ITERS, body-lr, etc.) saturate at inherited defaults. **Per-substructure partition family fully closed** (MLP-vs-ATTN: WD #482 NULL, LR #499 NULL/NULL clear regression both directions). PMuon's per-matrix whitening already equalizes per-module gradient geometry — any hand-imposed structural asymmetry destroys this equalization. Fresh exploration: sub-MLP (c_fc/c_proj) and depth-partition still untested for whitening invariance.

## Open unexplored axes (candidate next assignments)

- **Per-block LR multiplier** (depth-based) — **NOW IN FLIGHT (#532 askeladd)**
- **Sub-MLP LR partition (c_fc vs c_proj)** — **NOW IN FLIGHT (#535 alphonse)**
- **Skip-connection LR multiplier** — UNTESTED
- **NS coefficient (a,b,c) joint scan** — separate from NS_ITERS, never coordinated
- **Embed eps below 1e-10** {1e-12, 1e-14} — gradient pointed *down* from #463, but BF16 floor concern
- **AdaBelief** for aux AdamW group — variance of belief in gradient
- **EMA wrapper (Polyak) on body-Muon** — sister mechanism to Lookahead, different averaging dynamics
- **Per-token-position embed weight init asymmetry** — UNTESTED
- **COOLDOWN_POWER fine-scan** {1.3, 1.5, 1.6} — scalar likely NULL given pattern; low priority
- **Per-block residual scaling** (DeepNet-style gates) — architecture-adjacent, on r4 #452
- **Tied lm_head ↔ embed** — out of scope (architecture change)

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
