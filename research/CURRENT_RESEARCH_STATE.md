# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-20 08:30 UTC
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
| **#499** | alphonse | Body-Muon LR per-type partition (MLP=0.042/ATTN=0.028 vs swap): both arms clear NULL ~Δval=+0.006 symmetric. Δsr +62.5–+87.5. Centered geomean preserved (sqrt(MLP×ATTN)=0.0343≈0.035) — *the split itself* hurts, not the effective LR. PMuon's per-matrix whitening already equalizes per-module gradient geometry. | CLOSED 03:40 UTC |
| **#503** | edward | Body-Muon WD schedule (warmup-25pct vs cooldown-25pct): Arm A fs=2950 val=3.26475 (marginal-NULL Δsr=+12.5 Δval=+0.000472), Arm B fs=2975 val=3.26681 (clear-NULL Δsr=+37.5 Δval=+0.002532). Asymmetric loss confirms WD's implicit norm-control is load-bearing during cooldown. **Schedule axis closes at uniform constant WD=0.025.** Body-Muon WD now exhaustively tested across partition (#482 NULL) and schedule (#503 NULL). | CLOSED 04:28 UTC |
| **#505** | fern | Lookahead wrapper k∈{5, 10}, α=0.5: Arm A fs=-1 val=3.28420 DNF (Δval=+0.020 clear regression), Arm B fs=-1 val=3.28618 DNF (Δval=+0.022 clear regression). Both arms DNF with monotone regression — milder k=10 is NOT better than aggressive k=5. **Wrapper-class axis closes on body-Muon.** Layered averaging on top of already-tuned PMuon stack becomes net-harmful interference. | **CLOSED 05:32 UTC** |
| **#513** | thorfinn | Body-Muon gradient clipping at {1.0, 0.5}: Arm A clip=1.0 fs=3000 val=3.27024 (clear NULL Δsr=+62.5 Δval=+0.006), Arm B clip=0.5 fs=3000 val=3.27108 (clear NULL Δsr=+62.5 Δval=+0.007). Both arms clip-activated 99.97% — natural body-grad norm ~3e4 vs proposed thresholds {0.5, 1.0} (4-5 orders too low). Uniform 30,000× downscale costs only ~2% sr regression — **PMuon's spectral whitening confirmed approximately scale-invariant.** Student suggested re-test at natural-norm regime {3e4, 1e5, 3e5}; DEFERRED — pipeline NS iter-count extension instead. | **CLOSED 06:08 UTC** |
| **#519** | frieren | PMuon γ pruning γ∈{0, 0.8} vs baseline 0.4: Arm A γ=0 val=3.282615 DNF (Δval=+0.0183 clear regression), Arm B γ=0.8 val=3.313878 DNF (Δval=+0.0496 clear regression, 2.7× Arm A damage). **γ=0.4 load-bearing AND near-optimal.** Asymmetric damage curve (over-correction worse than ablation) consistent with WD #482/#503 and LR #499 patterns — local optimum pinned by cooldown-phase preconditioner-quality demand. γ axis fully closed: {0, 0.4, 0.8} mapped, plus #444 ramp NULL. | **CLOSED 07:30 UTC** |

## Active experiments (8 students, 08:30 UTC)

| PR | Student | Run | Step/3250 | bl | Status |
|---|---|---|---|---|---|
| **#545** | fern | `p3ryt23e` AdaBelief raw-m Arm A eps=1e-10 | ~1700 | 3.502 | Healthy. Relaunched 06:25 UTC after student self-diagnosed step-1 degeneracy when using m_hat. ~1.6h to terminal. |
| **#540** | edward | Arm A `y46v2liq` TERMINAL fs=2975 val=3.268 (NULL Δsr=+37.5); Arm B `zuk9fkdm` aggressive-cubic running | ~50 | 10.8 | Arm A clean NULL. Student-poller transitioned to Arm B at 08:23. ~3h to Arm B terminal. |
| **#535** | alphonse | Arm A `3twtlh18` c_fc-heavy TERMINAL fs=3025 NULL; Arm B `g8dy2zhk` c_proj-heavy running | ~625 | 3.748 | Sub-MLP LR partition. ~2.5h to Arm B terminal. |
| **#532** | askeladd | Arm A `oj9miqwf` early-fast TERMINAL fs=3025 NULL; `vx9owxmj` (duplicate Arm A) CRASHED; Arm B `i6tfv7ry` late-fast running | ~300 | 4.05 | Body-Muon per-block LR (depth-based). Redirect to Arm B worked. ~3h to Arm B terminal. |
| **#522** | nezuko | Arm A `1ohe6cf7` TERMINAL fs=2975 NULL; Arm B `8bmch56g` TERMINAL fs=3025 NULL; `0516jnmb` duplicate Arm B running | — | — | **BOTH ARMS NULL/NULL CLEAR.** Linear decay (fs=2975) better than hard-switch (fs=3025). **Floor IS load-bearing during cooldown — not redundant with COOLDOWN_POWER taper.** Advisor comment posted 08:25 UTC asking student to kill duplicate `0516jnmb` and post terminal SENPAI-RESULT. Awaiting student response. |
| **#553** | frieren | Arm A `1x2u1688` dim=1 (paper default) running | ~625 | 3.742 | Gradient centralization pre-NS. ~2.5h to terminal. |
| **#546** | thorfinn | Arm A `bqm06i25` NS_ITERS=16 running | ~1850 | 3.474 | NS_ITERS extension pipeline {16, 18}. ~1.4h to Arm A terminal. |
| **#511** | tanjiro | Arm B seed-1 `ldezjd0y` TERMINAL marginal n=1 win fs=2925 val=3.2639; seed-2 `ciusvhzo` NS=14 confirmation running | ~2325 | 3.377 | **🚨 MARGINAL WIN — fs=2925 (Δsr=−12.5 vs baseline 2937.5). seed-2 in cooldown phase. ~37 min to terminal.** |

## Next terminal events (from 08:30 UTC)

1. **🚨 tanjiro #511 NS=14 seed-2 `ciusvhzo`** — step 2325 bl=3.377, ~37 min to terminal. **Marginal n=1 win Δsr=−12.5 → need n=2 to merge.**
2. **thorfinn #546 NS=16 `bqm06i25`** — step 1850 bl=3.474, ~1.4h to terminal.
3. **fern #545 AdaBelief Arm A `p3ryt23e`** — step 1700 bl=3.502, ~1.6h to terminal.
4. **alphonse #535 Arm B `g8dy2zhk`, frieren #553 Arm A `1x2u1688`** — step 625 each, ~2.5h to terminal.
5. **askeladd #532 Arm B `i6tfv7ry`, edward #540 Arm B `zuk9fkdm`** — step 300/50, ~3h to terminal each.
6. **nezuko #522** — awaiting student SENPAI-RESULT marker + duplicate kill; reassignable after close.

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 | **MERGED 11:48 UTC** — current baseline. |

## Current research focus (updated 07:35 UTC)

**🚨 LIVE WIN SIGNAL** on tanjiro #511 Arm B (NS_ITERS=14): TERMINAL marginal n=1 win fs=2925 val=3.2639 (Δsr=−12.5 vs baseline 2937.5). ciusvhzo seed-2 confirmation running step 1450/3250 bl=3.56 healthy. NS_ITERS=14 vs 12 is mechanistically clean: more NS iterations → more accurate spectral whitening → better preconditioner quality per step. Notably asymmetric with Arm A NS=10 NULL fs=3000 (x6pxjdk4) — the gradient points "more iterations is better."

**Pipelining strategy:** while tanjiro confirms NS=14 at seed-2, thorfinn #546 explores NS={16, 18} in parallel. Two independent n=1 wins at different NS values would corroborate the trend even if tanjiro lands sr ≈ 2950 — much stronger evidence than a single n=2 confirmation.

**21 scalar/mechanism axes closed** at inherited defaults (now incl. #503 body-WD schedule NULL/NULL clear, #505 Lookahead wrapper NULL/NULL clear, #513 body-Muon grad clipping NULL/NULL clear, #519 PMuon γ pruning {0, 0.8} NULL/NULL clear). Active families:

1. **AdaBelief variance update on aux AdamW** (fern #545 — relaunched after self-diagnosed step-1 degeneracy, now using raw m per Algorithm 2): fresh mechanism-class change to second-moment estimator.
2. **NS coefficient (polynomial degree + within-cubic strength)** (edward #540): tests quintic vs aggressive-cubic at NS_ITERS=12 fixed.
3. **LR partition by sub-MLP geometry** (alphonse #535 — Arm A `3twtlh18` fs=3025 NULL terminal, Arm B awaiting launch).
4. **LR partition by depth** (askeladd #532 — Arm A `oj9miqwf` fs=3025 NULL terminal, Arm B awaiting launch).
5. **NS preconditioner quality — iteration count axis** (tanjiro #511 marginal-win awaiting n=2 confirmation via ciusvhzo; thorfinn #546 NS={16,18} pipeline): possible new baseline.
6. **Gradient centralization on body-Muon pre-NS** (frieren #553 NEW — gradient TRANSFORMATION class, orthogonal to all preconditioning/wrapping/partition work).
7. **Skylight floor schedule** (nezuko #522 — Arm A linear decay marginal NULL, Arm B hard switch mid-flight): cooldown↔floor interaction.

**Body-Muon WD exhaustively tested:** partition (#482 NULL), schedule (#503 NULL/NULL clear). Constant uniform WD=0.025 confirmed locally optimal. **Wrapper-class on body-Muon closed** (#505 Lookahead NULL/NULL clear). **Body-Muon damping/clipping closed at tested thresholds** (#513 NULL/NULL — but thresholds {0.5, 1.0} were 4-5 orders below natural-norm regime ~3e4; PMuon's whitening confirmed approximately scale-invariant). **PMuon γ axis fully mapped:** {0 (#519 Arm A, +0.018), 0.4 (baseline), 0.8 (#519 Arm B, +0.050), ramp #444 NULL} — γ=0.4 load-bearing and near-optimal.

**Emerging pattern after 21 closed axes:** mechanism scalars saturate at inherited defaults. Per-substructure partition family fully closed (MLP-vs-ATTN, and now sub-MLP c_fc vs c_proj #535 Arm A NULL, depth #532 Arm A NULL). Wrapper-class on body-Muon closed. Damping/clipping closed below natural-norm regime. γ-axis fully mapped. **First non-NULL signal** is tanjiro's NS_ITERS=14 — preconditioner quality axis. If confirmed at n=2 or corroborated by thorfinn #546, edward #540 (NS coef scan at NS=12) needs re-evaluation since the optimal polynomial may shift with iteration count.

## Open unexplored axes (candidate next assignments)

- **Per-block LR multiplier** (depth-based) — **IN FLIGHT (#532 askeladd)**
- **Sub-MLP LR partition (c_fc vs c_proj)** — **IN FLIGHT (#535 alphonse)**
- **NS coefficient (a,b,c) joint scan** — **IN FLIGHT (#540 edward)**
- **AdaBelief on aux AdamW** — **IN FLIGHT (#545 fern)**
- **Skip-connection LR multiplier** — UNTESTED
- **Embed eps below 1e-10** {1e-12, 1e-14} — gradient pointed *down* from #463, but BF16 floor concern
- **EMA wrapper (Polyak)** — REDUNDANT after #505 closes wrapper-class; same averaging family as Lookahead
- **NS_ITERS=16 / NS_ITERS=18 follow-up** — **IN FLIGHT (#546 thorfinn)** — exploratory pipeline parallel to tanjiro #511 n=2 confirmation
- **Body-Muon grad clipping at natural-norm regime** {3e4, 1e5, 3e5} — DEFERRED (thorfinn pivoted to NS extension; #513 student suggestion)
- **Per-token-position embed weight init asymmetry** — UNTESTED
- **COOLDOWN_POWER fine-scan** {1.3, 1.5, 1.6} — scalar likely NULL given pattern; low priority
- **Per-block residual scaling** (DeepNet-style gates) — architecture-adjacent, on r4 #452
- **Tied lm_head ↔ embed** — out of scope (architecture change)

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
