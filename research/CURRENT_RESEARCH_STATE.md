# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-16 22:50 UTC — **PR #129 frieren β_cov CLOSED (null, β=0.95 conditioning sweet spot confirmed by eigh telemetry); frieren → PMuon γ_power scan PR #202 (PR #201 auto-merged due to FF-merge bug, re-issued as #202); all 8 students active**
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3062.5 steps; public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3062.5 steps, val/loss 3.269090 (n=2 mean)** — PR #137 (g1r1-nezuko, PMuon + Skylight u/w-floor + power-law cooldown γ=1.2).
W&B runs: `8quuvdrj` (seed-1, sr=3075, val=3.270012) + `l5bdkm6e` (seed-2, sr=3050, val=3.268167). Merged 2026-05-16 18:26 UTC.

n=2 stat-sig margin: (3.28 − 3.269090)·√2 = 0.01543 ✓

**Key property:** Power-law cooldown γ=1.2 is the ONLY win on PMuon+u/w-floor base after 18+ experiments. Schedule-shape is the confirmed open lever.

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                              | Status (~22:35 UTC) |
| --- | ----------- | --------------------------------------------------------------------- | ------ |
| **#202** | **frieren** | **PMuon γ_power whitening exponent scan {0.2, 0.4}** (dual axis to β_cov; re-issue of auto-merged #201) | **Just assigned** |
| **#197** | **alphonse** | **EMA model weight averaging {α=0.99, 0.999}** (pivot from polar saturation) | Running ~21:45 UTC |
| **#198** | **edward** | **Per-block weight decay {deep-strong, deep-weak}** (WD bypasses PMuon + u/w-floor) | Running ~21:45 UTC |
| **#195** | **fern** | **Wave 5: cooldown_frac scan {0.5, 0.85}** | Running ~21:05 UTC |
| **#193** | **tanjiro** | **Wave 5: NS coefficient scan {Jordan, cubic-Newton}** | Running ~20:45 UTC |
| **#184** | **thorfinn** | **Wave 5: NS iter count scan {6, 18}** | Running ~20:30 UTC |
| **#179** | **nezuko** | **Wave 5: γ scan {1.1, 1.3}** | Arm A done (γ=1.1, sr=3075, val=3.26813); arm B (γ=1.3) running |
| **#131** | **askeladd** | + TARGET_UW sweep (arm 0.25 running) | Running ~20:30 UTC |

## Recently closed (this session)

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| **#129** | **frieren** | β_cov scan: all 3 arms NULL; best arm A sr=3125 val=3.26889; eigh shows β=0.95 at conditioning sweet spot | **CLOSED NULL** — β_cov axis fully characterized; non-monotonic conditioning confirms 0.95 is local optimum |
| **#169** | **alphonse** | Per-head polar: sr=3125, val=3.2706; per-head conditioning 1000-2000× better but null | **CLOSED NULL** — polar saturation confirmed structural; mechanism worked, learning didn't |
| **#158** | **edward** | LLRD arm A (0.85): sr=-1 val=3.300; arm B (0.90): sr=-1 val=3.286 | **NEGATIVE** — reversed direction (block_11 highest grad-norm, not block_00); u/w-floor absorbs LR signal |
| **#168** | **fern** | Cosine: sr=3075, val=3.276583 (n=1 margin negative) | **CLOSED NULL** — late-cooldown lr collapse explains val regression |
| **#167** | **tanjiro** | SOAP-attn: sr=3100, val=3.26806, post_to_pre_ratio≈1.0 | **CLOSED NULL** — Frobenius renorm cancels SOAP; post-polar slot exhausted |
| **#143** | **thorfinn** | Lookahead: sr=-1 both arms | **NEGATIVE** |
| #137 | nezuko | Power-law γ=1.2 n=2: sr=3062.5 val=3.269090 | **MERGED — current baseline** |

## Wave 5 — multi-axis portfolio

**Schedule-shape (confirmed win axis):**

| PR | γ, cooldown_frac | Status |
|---|---|---|
| PR #137 (merged) | γ=1.2, cf=0.7 | **Baseline (sr=3062.5)** |
| PR #179 (nezuko) | γ ∈ {1.1, 1.3}, cf=0.7 | Arm A done (γ=1.1 sr=3075); arm B (γ=1.3) running |
| PR #195 (fern) | γ=1.2, cf ∈ {0.5, 0.85} | Running |

**NS polar hyperparameters (never tested before):**

| PR | Mechanism | Status |
|---|---|---|
| PR #184 (thorfinn) | NS_ITERS ∈ {6, 18} | Running |
| PR #193 (tanjiro) | NS coefficients {Jordan, cubic-Newton} | Running |

**PMuon preconditioner hyperparameters (two orthogonal axes):**

| PR | Mechanism | Status |
|---|---|---|
| PR #129 (frieren, CLOSED) | β_cov ∈ {0.90, 0.95, 0.99} | **NULL — β=0.95 is conditioning sweet spot** |
| PR #202 (frieren) | γ_power ∈ {0.2, 0.4} | Just assigned (re-issue of #201) |

**Orthogonal axes (plateau protocol pivot):**

| PR | Mechanism | Hypothesis |
|---|---|---|
| PR #197 (alphonse) | EMA weight averaging α ∈ {0.99, 0.999} | Post-hoc smoothing bypasses polar/WD stack entirely |
| PR #198 (edward) | Per-block WD coupling depth ∈ {strong, weak} | WD on p bypasses PMuon whitening + u/w-floor |

## PMuon hyperparameter characterization

Both fundamental PMuon preconditioner axes now being probed:
- **β_cov** (covariance horizon): **CLOSED** — β=0.95 confirmed at local optimum via eigh conditioning telemetry (non-monotonic: 0.90→near-singular, 0.95→healthy=26.6, 0.99→degraded=0.57)
- **γ_power** (whitening strength): **Active PR #201** — {0.2 (weaker), 0.4 (stronger)} bracketing default 0.3

If PR #201 also nulls, both PMuon-internal axes are closed and we can declare the preconditioner fully tuned at defaults.

## Null/negative tally — mechanism additions on PMuon+u/w-floor

**18+ consecutive nulls/negatives. Schedule-shape remains the ONLY confirmed win.**

1. PR #83 SOAP-MLP → NULL
2. PR #93 NorMuon row-wise → NULL
3. PR #110 γ-scan ±0.05 → NULL
4. PR #118 cooldown_frac ±0.1 → NULL
5. PR #119 Contra-Muon × PMuon → NEGATIVE (4 arms)
6. PR #129 β_cov scan {0.90, 0.95, 0.99} → NULL (all 3 arms; conditioning sweet spot confirmed)
7. PR #140 SOAP-MLP+u/w stack → NULL
8. PR #143 Lookahead k=5 → NEGATIVE; k=10 → NEGATIVE
9. PR #150 Cautious sign-mask → NEGATIVE
10. PR #151 Aurora pre-polar → NULL
11. PR #131 TARGET_UW ∈ {0.40, 0.45, 0.30} → NULL
12. PR #158 LLRD decay=0.85 → NEGATIVE; decay=0.90 → NEGATIVE
13. PR #167 SOAP-attn q/k/v → NULL
14. PR #168 Cosine cooldown → NULL vs merged baseline
15. PR #169 Per-head polar attn q/k/v → NULL (polar saturation structural)

## Polar saturation — confirmed (CLOSE THIS DIRECTION)

All polar mechanism probes exhausted:
- Post-polar Frobenius-preserving: SOAP-MLP (null), SOAP-attn (null)
- Pre-polar: Aurora (null), NorMuon (null)
- Structural unit: Per-head (null)
- Outer-loop: Lookahead (negative), Contra-Muon (negative)

**Active probes of NS hyperparameters (PR #184, #193) are NOT polar mechanism additions — they test the polar polynomial itself, which is untouched since program start.**

## Open schedule-shape mechanism insight

PR #168 (fern cosine) decomposed the schedule-shape effect:
- **Crossing step**: responds to integral of recent lr in cooling window (both cosine + γ=1.2 give sr=3075 vs linear 3100)
- **Post-crossing val**: requires preserved late-cooldown lr (γ=1.2 eta=0.041 at step 3100 → val refinement continues)

PR #179 nezuko arm A confirms: γ=1.1 gives sr=3075 (matches cosine; slower than γ=1.2). Val=3.26813 — slightly BETTER than baseline (3.269090). Suggests γ=1.1's gentler early-cooldown slope buys val quality while losing crossing speed.

PR #179 arm B (γ=1.3) will test: does stronger concavity accelerate crossing below 3062.5? 

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3062.5, val=3.269090** (n=2 PR #137). At n=1, val ≤ 3.276 required vs 3.28; to beat baseline on sr requires n=2 mean < 3062 or compelling n=1 evidence.
