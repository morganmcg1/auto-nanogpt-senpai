# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-17 04:10 UTC — **FIVE INDEPENDENT ARM WINS detected via W&B**: frieren γ_power=0.4 sr=3025 (BIGGEST), thorfinn ns_iter=6 sr=3050 + ns_iter=18 sr=3050 (BOTH ARMS WIN — wide polar regime), tanjiro cubic-Newton sr=3050, edward deep-strong WD sr=3050, askeladd lm_head 1/160 sr=3050 (marginal — val ties baseline). 3-4 terminal SENPAI-RESULTs awaited.
- **Most recent direction from humans:** None (no GitHub issues open at 04:10 UTC check).
- **Target:** Push `speedrun/final_first_step_to_target` below 3062.5 steps; public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3062.5 steps, val/loss 3.269090 (n=2 mean)** — PR #137 (g1r1-nezuko, PMuon + Skylight u/w-floor + power-law cooldown γ=1.2).
W&B runs: `8quuvdrj` (seed-1, sr=3075, val=3.270012) + `l5bdkm6e` (seed-2, sr=3050, val=3.268167). Merged 2026-05-16 18:26 UTC.

n=2 stat-sig margin: (3.28 − 3.269090)·√2 = 0.01543 ✓

## FIVE ARM WINS — W&B-confirmed, awaiting terminal SENPAI-RESULTs

| Rank | Source PR | Mechanism | sr | val | Δsr | Posted? | Δval-stat-sig at n=1 |
|---|---|---|---|---|---|---|---|
| **#1** | frieren PR #202 arm A | γ_power=0.4 (stronger PMuon whitening) | **3025** | **3.26615** | **−37.5** | Partial posted | 0.01385 (3.46×) ✓ |
| #2a | thorfinn PR #184 arm A | ns_iter=6 (less precise polar) | 3050 | 3.26774 | −12.5 | Partial posted | 0.01226 (3.07×) ✓ |
| #2b | thorfinn PR #184 arm B | ns_iter=18 (more precise polar) | 3050 | **3.26720** | −12.5 | Terminal pending | 0.01280 (3.20×) ✓ |
| #3 | tanjiro PR #193 arm B | cubic-Newton NS coefs | 3050 | 3.26773 | −12.5 | Terminal pending | 0.01227 (3.07×) ✓ |
| #4 | edward PR #198 arm A | deep-strong per-block WD | 3050 | 3.26819 | −12.5 | Partial posted | 0.01181 (2.95×) ✓ |
| #5 | askeladd PR #211 arm A | lm_head LR 1/160 | 3050 | **3.26900** | −12.5 | Terminal pending | 0.01100 (2.75×) ✓ |

**Key new finding:** thorfinn arm B (ns_iter=18) ALSO wins at sr=3050, with even better val than arm A. **The polar-projection iteration count has a wide good regime, not a narrow optimum.** This makes ns_iter a less attractive stacking ingredient than initially thought — the default 12 may be slightly suboptimal in both directions.

**Note:** askeladd lm_head 1/160 is marginal — val 3.26900 ≈ baseline mean 3.269090 (effectively tied). The sr=3050 alone suggests it crossed 3.28 earlier in this run but val plateaued at baseline. Could be noise. Needs terminal n=2 confirmation before stacking.

## Orthogonality re-analysis (for stacking)

| Pair | Orthogonal? | Reasoning |
|---|---|---|
| γ_power × ns_iter | YES | Whitening exponent (pre-polar) vs polar iteration count |
| γ_power × cubic-Newton | YES | Whitening exponent vs polar polynomial coefficients |
| γ_power × deep-strong WD | YES | Whitening vs param-magnitude decay |
| γ_power × lm_head LR | YES | PMuon (block) vs aux AdamW (lm_head) |
| ns_iter × cubic-Newton | **NO** | Both modify NS polar projection (overlapping mechanism) |
| ns_iter × deep-strong WD | YES | Polar vs param-magnitude decay |
| ns_iter × lm_head LR | YES | Block-PMuon vs aux AdamW |
| cubic-Newton × deep-strong WD | YES | Polar vs param-magnitude decay |
| cubic-Newton × lm_head LR | YES | Block-PMuon vs aux AdamW |
| deep-strong WD × lm_head LR | YES | Block-WD vs aux AdamW |

**Best 4-way orthogonal stack candidates:**
- **Stack A (primary):** γ_power=0.4 + ns_iter=6 + deep-strong WD + lm_head 1/160 — conservative additive sr=2987.5 (would BEAT Record #20)
- **Stack B (alt-polar):** γ_power=0.4 + cubic-Newton + deep-strong WD + lm_head 1/160 — alt polar variant
- **Stack C (no aux):** γ_power=0.4 + ns_iter=6 + deep-strong WD — original 3-way est. sr=3000
- **Stack D (no aux, alt):** γ_power=0.4 + cubic-Newton + deep-strong WD — alt polar 3-way est. sr=3000

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                           | Status (04:10 UTC) |
| --- | ----------- | ------------------------------------------------------------------- | ------------------ |
| **#216** | **nezuko** | Aux AdamW β2 scan {0.99, 0.999} | Arm A starting |
| **#211** | **askeladd** | lm_head LR scan — arm A 1/160 W&B-WIN sr=3050 (marginal val); arm B 1/640 to launch | Arm A finished, partial pending |
| **#202** | **frieren** | γ_power=0.4 WIN arm A; γ_power=0.2 arm B at ~48% | Arm B running |
| **#198** | **edward** | deep-strong WD WIN arm A; deep-weak arm B at ~82% val=3.334 mid-run | Arm B running |
| **#197** | **alphonse** | α=0.99 NEGATIVE arm A; α=0.999 arm B at ~79% val=3.511 mid-run (likely negative) | Arm B running |
| **#195** | **fern** | cf=0.85 NULL arm A; cf=0.5 arm B at ~78% val=3.393 mid-run | Arm B running |
| **#193** | **tanjiro** | Jordan NULL arm A; cubic-Newton W&B-WIN sr=3050 arm B | Arm B finished, terminal pending |
| **#184** | **thorfinn** | ns_iter=6 WIN arm A; ns_iter=18 W&B-WIN sr=3050 arm B | Arm B finished, terminal pending |

## PMuon hyperparameter status

- **β_cov** (covariance horizon): CLOSED PR #129 — β=0.95 at local optimum
- **γ_power** (whitening strength): ACTIVE PR #202 — arm A 0.4 WINS BIG; arm B 0.2 mid-run
- **NS_iters** (polar convergence): PR #184 W&B-complete — BOTH arms WIN (6, 12, 18 all close); wide regime, no sharp optimum
- **NS_coef** (polar polynomial): PR #193 W&B-complete — Jordan NULL, cubic-Newton WIN at sr=3050
- **TARGET_UW** (Skylight floor): CLOSED PR #131 — 0.35 at fired_fraction sweet spot

## Auxiliary optimizer (AdamW) — exploration in progress

| PR | Axis | Status |
|---|---|---|
| PR #211 (askeladd) | lm_head LR {1/160, 1/640} | Arm A W&B-WIN (marginal val); arm B to launch |
| PR #216 (nezuko) | Aux β2 {0.99, 0.999} | Just assigned |

Static config: embed_lr=0.3, lm_head_lr=1/320, betas=(0.8, **0.95**), eps=1e-10. β2=0.95 unusual vs default 0.999.

## Wave 5 — multi-axis portfolio picture (W&B-complete)

| PR | Mechanism | Final result |
|---|---|---|
| #137 (merged) | γ=1.2, cf=0.7 | Baseline (sr=3062.5) |
| #179 (CLOSED) | γ ∈ {1.1, 1.3} | Both NULL — γ=1.2 optimum, axis closed |
| #195 (fern) | cf ∈ {0.5, 0.85} | Arm A NULL (cf=0.85); arm B cf=0.5 mid-run |
| #184 (thorfinn) | NS_ITERS ∈ {6, 18} | **BOTH ARMS WIN sr=3050** — wide regime |
| #193 (tanjiro) | NS coefs Jordan vs cubic-Newton | Jordan NULL; **cubic-Newton WIN sr=3050** |
| #197 (alphonse) | EMA avg | Arm A NEGATIVE (α=0.99); arm B mid-run (predicted NEGATIVE) |
| #198 (edward) | Per-block WD | **deep-strong WIN sr=3050**; deep-weak mid-run |
| #202 (frieren) | γ_power ∈ {0.2, 0.4} | **γ_power=0.4 WIN sr=3025 (BIGGEST)**; γ_power=0.2 mid-run |

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3062.5, val=3.269090** (n=2 PR #137).

All 5 arm wins clear stat-sig at n=1; will need n=2 confirmation for merge.

## Wave 7 stacking plan (revised after 5-arm picture)

**Step 1 (immediate, when PRs close):**
- thorfinn PR #184: when terminal posted, BOTH arms ns_iter=6/18 win → could merge ns_iter=18 as new baseline OR close as informative-but-no-stacking (since cubic-Newton from tanjiro is a stronger candidate on val). Lean toward closing #184 since the polar regime is wide → stacking unlikely to compound.
- tanjiro PR #193: when terminal posted, merge cubic-Newton arm B at sr=3050 OR roll into stacking.

**Step 2: Wave 7 4-way stacks (parallel)**
- **Stack A (thorfinn)**: γ_power=0.4 + ns_iter=6 + deep-strong WD + lm_head 1/160 — primary stack, est. sr=2987.5
- **Stack B (tanjiro)**: γ_power=0.4 + cubic-Newton + deep-strong WD + lm_head 1/160 — alt polar variant
- Conservative additive prediction would beat Record #20 (3030) in both cases.
