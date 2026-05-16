# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-16 20:45 UTC — **PR #167 tanjiro SOAP-attn CLOSED (null, sr=3100, post_to_pre_ratio≈1.0 confirms post-polar slot exhausted); tanjiro → NS coefficient scan PR #193; all 8 g1r1 students active**
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3062.5 steps; public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3062.5 steps, val/loss 3.269090 (n=2 mean)** — PR #137 (g1r1-nezuko, PMuon + Skylight u/w-floor + power-law cooldown γ=1.2).
W&B runs: `8quuvdrj` (seed-1, sr=3075, val=3.270012) + `l5bdkm6e` (seed-2, sr=3050, val=3.268167). Merged 2026-05-16 18:26 UTC.

n=2 stat-sig margin: (3.28 − 3.269090)·√2 = 0.01543 ✓

**Key property:** Power-law cooldown γ=1.2 is the ONLY win on PMuon+u/w-floor base after 14+ experiments. Schedule-shape is the confirmed open lever. All optimizer mechanism additions + outer-loop changes have been null or negative.

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                              | Status (~20:45 UTC) |
| --- | ----------- | --------------------------------------------------------------------- | ------ |
| **#193** | **tanjiro** | **Wave 5: NS coefficient scan {Jordan (3.4445,-4.7750,2.0315), cubic-Newton (1.5,-0.5,0)}** | **Just assigned** |
| **#184** | **thorfinn** | **Wave 5: NS iter count scan {6, 18}** (fundamental polar hyperparameter — never tested) | **Just assigned** |
| **#179** | **nezuko** | **Wave 5: γ scan {1.1, 1.3}** (bracket γ=1.2 optimum) | `v8hz5obx` (γ=1.1) at step 900/3250 (28%), ETA ~23:30 UTC |
| #168 | fern       | + Cosine cooldown shape (Wave 5 — s-curve vs concave-down comparison) | `sf7fq2ul` at step 2466/3250 (76%), ETA ~21:30 UTC |
| #169 | alphonse   | + Per-head polar projection on attention q/k/v (Wave 5 — structural polar) | `8mgxsj35` at step 2075/3250 (64%), ETA ~22:00 UTC |
| #158 | edward     | + Depth-wise per-block LR decay (arm A NEGATIVE; arm B 0.90 running) | arm B `z6xxow8s` at step 2025/3250 (62%), ETA ~22:00 UTC |
| #131 | askeladd   | + TARGET_UW sweep {0.25 pending, 0.30 at 91%, 0.40 NULL, 0.45 NULL}               | arm 0.30 `dkxweoah` almost done; arm 0.25 queued; student active |
| #129 | frieren    | + PMuon β_cov scan (arm A running, arm B 0.95 NULL sr=3125, arm C 0.99 NULL sr=3150) | arm A `dstsva72` step ~35%, ETA ~22:10 UTC |

## Recently closed

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| **#167** | **tanjiro** | SOAP-attn: sr=3100, val=3.26806, post_to_pre_ratio≈1.0 | **CLOSED NULL** — Frobenius renorm cancels SOAP eigenbasis rescaling; post-polar slot exhausted |
| **#143** | **thorfinn** | Lookahead k=5: val=3.2836 sr=-1 / k=10: val=3.2839 sr=-1 | **NEGATIVE** — slow-weight pullback × u/w-floor magnitude conflict (cosine_drift +0.75) |
| #137 | nezuko | Power-law γ=1.2 n=2: sr=3062.5 val=3.269090 | **MERGED — current baseline** |

## Wave 5 — current research focus

**Confirmed direction: SCHEDULE SHAPE** (only axis that has improved on PMuon+u/w-floor base)

| PR | γ / shape / mechanism | Expected character | Status |
|---|---|---|---|
| PR #137 (merged) | γ=1.2 power-law | Concave-down, mid-cooldown acceleration | **Baseline (sr=3062.5)** |
| PR #179 (nezuko) | γ ∈ {1.1, 1.3} | Bracket curvature optimum | **Running arm A (28%)** |
| PR #168 (fern) | Cosine | S-curve, back-loaded | **Running (76%)** |
| PR #169 (alphonse) | Per-head polar | Structural NS change | **Running (64%)** |
| PR #184 (thorfinn) | NS iters {6, 18} | Fundamental polar depth | **Just assigned** |
| PR #193 (tanjiro) | NS coefficients {Jordan, cubic-Newton} | Polar polynomial family | **Just assigned** |

**Expected completions tonight:** fern #168 ~21:30, alphonse #169 ~22:00, edward #158 arm B ~22:00, frieren #129 arm A ~22:10, nezuko #179 arm A ~23:30.

## Null/negative tally — mechanism additions on PMuon+u/w-floor

**15 consecutive nulls/negatives (post-polar slot now fully exhausted). Schedule-shape remains the ONLY confirmed win.**

1. PR #83 SOAP-MLP → NULL
2. PR #93 NorMuon row-wise → NULL
3. PR #110 γ-scan ±0.05 → NULL
4. PR #118 cooldown_frac ±0.1 → NULL
5. PR #119 Contra-Muon × PMuon → NEGATIVE (4 arms)
6. PR #129 arm B bcov=0.95 → NULL; arm C bcov=0.99 → NULL
7. PR #140 SOAP-MLP+u/w stack → NULL (post_to_pre_ratio≈1.0)
8. PR #143 Lookahead k=5 → NEGATIVE; k=10 → NEGATIVE
9. PR #150 Cautious sign-mask → NEGATIVE
10. PR #151 Aurora pre-polar → NULL
11. PR #131 TARGET_UW=0.40 → NULL; TARGET_UW=0.45 → NULL
12. PR #158 LLRD decay=0.85 arm A → NEGATIVE; arm B (0.90) running
13. PR #167 SOAP-attn q/k/v → NULL (post_to_pre_ratio≈1.0; same mechanism as #140)

## Post-polar preconditioning slot — EXHAUSTED

**PR #140 (SOAP-MLP) + PR #167 (SOAP-attn)** together confirm: the Frobenius-preserving renorm (`multiplier = pre_norm / post_norm`) cancels eigenbasis rescaling regardless of which weight family it's applied to. This slot is **closed**. The c=0 degenerate quintic (cubic-Newton) and Jordan-optimized coefficients are the next structural probe (PR #193).

## Key cross-cutting issues

1. **Mechanism-addition plateau confirmed at 15 nulls/negatives**: pre-polar, post-polar, outer-loop, sign-mask — all blocked.
2. **Only schedule-shape wins**: γ=1.2 power-law cooldown → sr=3062.5 (PR #137). Schedule dimension still open.
3. **NS hyperparameter space now fully probed**: PR #184 (thorfinn iter count) + PR #193 (tanjiro coefficients) together map the NS polar map's two fundamental axes. If both null, the polar family is exhausted.
4. **Rebase needed on stale PRs**: PRs created before PR #137 merge need rebase before final SENPAI-RESULT submission — deferred until run completion.
5. **Silent-fail rate-limit pattern**: pgrep guard now mandatory; students active (askeladd 18:37, frieren 18:46, thorfinn 19:34).

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3062.5, val=3.269090** (n=2 PR #137). At n=1, val ≤ 3.276 required vs 3.28; to beat baseline on sr requires n=2 mean < 3062 or compelling n=1 evidence.
