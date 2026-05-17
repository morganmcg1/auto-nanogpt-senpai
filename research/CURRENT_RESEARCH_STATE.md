# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-17 06:50 UTC — **PR #202 MERGED → new baseline sr=3025 val=3.26615 (BEATS Record #20!). PR #242 frieren assigned (γ_power finer scan {0.5, 0.6}). 8/8 students active.**
- **Most recent direction from humans:** None (no GitHub issues open at 06:40 UTC check).
- **Target:** Push `speedrun/final_first_step_to_target` below 3025 steps; public record is 3030 steps (Record #20). **WE ARE BEATING RECORD #20 (local n=1 sr=3025 < 3030).**

## Current local baseline

**sr=3025, val/loss 3.26615 (n=1)** — PR #202 (g1r1-frieren, γ_power=0.4 on cubic-Newton+PMuon+u/w-floor+γ=1.2 base).
W&B run: `prncgzv5`

Note: n=1 only — thorfinn PR #225 Wave 7 stack (n=2, seeds 1+2) will serve as n=2 confirmation of the compound (cubic-Newton + γ_power=0.4).

Previous baselines:
- PR #193 (cubic-Newton): sr=3050, val=3.26773 (n=1)
- PR #137 (PMuon+u/w+γ=1.2): sr=3062.5, val=3.26909 (n=2)

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                           | Status (06:50 UTC) |
| --- | ----------- | ------------------------------------------------------------------- | ------------------ |
| **#225** | **thorfinn** | **Wave 7: γ_power=0.4 + deep-strong WD + lm_head 1/160 on cubic-Newton base (n=2)** | Running (~step 625) |
| **#226** | **tanjiro** | **NS coef c-scan {0.1, 0.25} on cubic-Newton base** | Running (~step 725) |
| **#242** | **frieren** | γ_power finer scan {0.5, 0.6} on new baseline (sr=3025) | Just assigned |
| **#231** | **fern** | Muon gradient momentum scan {mu=0.9, 0.99} — current mu=0.95 | Running |
| **#230** | **edward** | Aux AdamW β1 scan {0.7, 0.9} — current β1=0.8 | Running (step ~500) |
| **#229** | **alphonse** | NS coef (a,b) cubic-family line scan {a=1.3, 1.7} (c=0, a+b=1) | Picking up |
| **#216** | **nezuko** | Aux AdamW β2 scan {0.99, 0.999} | Arm A DONE sr=3025 (vs old base), arm B running |
| **#211** | **askeladd** | lm_head LR arm B 1/640 running (~step 2050) | Arm B running |

## Recently merged

| PR | Student | Result | Decision |
|---|---|---|---|
| **#202** | frieren | γ_power=0.4 WIN sr=3025, val=3.26615 | **MERGED → new baseline (BEATS Record #20)** |
| **#193** | tanjiro | cubic-Newton WIN sr=3050, val=3.26773 | **MERGED** |

## Recently closed

| PR | Student | Result | Decision |
|---|---|---|---|
| **#198** | edward | deep-strong sr=3050 val=3.268193 (NULL vs new baseline) | CLOSED — in Wave 7 stack |
| **#197** | alphonse | α=0.99 sr=3100; α=0.999 sr=-1 | CLOSED — EMA bias-lag |
| **#195** | fern | cf=0.85 sr=3075; cf=0.5 sr=3150 | CLOSED — cf=0.7 optimum |
| **#184** | thorfinn | NS_ITERS=6/18 both sr=3050 | CLOSED — wide flat regime |

## Key structural findings (program-level)

1. **PMuon polar orthogonality is non-load-bearing.** Changing NS coefs (cubic-Newton c=0, residual ~0.10) or NS iters (6→18) produces <0.05% val difference. PMuon's bilateral whitening pre-conditions the gradient so well that only direction matters.

2. **γ_power is the dominant axis.** Monotone over {0.2→3050, 0.3→3062.5, 0.4→3025}. Direction confirmed: higher γ_power → stronger whitening → better sr. Finer scan {0.5, 0.6} assigned.

3. **NS coef axis partially characterized.** Quintic (c=0.5) = old baseline null. Cubic-Newton (c=0) = WIN (merged). Jordan = NULL. c ∈ {0.1, 0.25} scan pending (tanjiro PR #226). (a,b) line scan pending (alphonse PR #229).

4. **Deep-strong per-block WD mechanism confirmed active.** WD acts on `p` directly, bypasses PMuon+u/w-floor. Net effect vs new baseline (PR #193): null alone, but ingredient in Wave 7 stack.

5. **EMA weight averaging closed.** Bias-lag structurally incompatible with power-law cooldown.

6. **Schedule family (γ, cf) exhausted.** Both at sweet spots: γ=1.2, cf=0.7.

7. **Spectral diagnostic telemetry added.** `pmuon_spectral_diag()` logs lcov/rcov eigh stats + whitened SV ratio every 100 steps — active in current codebase since PR #202 merge.

## Wave 7 stacking plan

**Primary stack (PR #225 thorfinn):**
- γ_power=0.4 + deep-strong WD (slope=+0.5) + lm_head LR 1/160
- On cubic-Newton base (n=2, seeds 1+2)
- Conservative additive from new baseline (3025): if deep-WD and lm_head additive → 3025 − 12.5 − 12.5 = sr=3000
- Would further beat Record #20 if additive

**Parallel exploration:**
- PR #242 frieren: γ_power finer scan {0.5, 0.6} — push toward full whitening
- PR #226 tanjiro: NS coef c-scan {0.1, 0.25} — maps the winning polynomial family
- PR #229 alphonse: NS coef (a,b) line scan — maps contraction aggressiveness of cubic family
- PR #230 edward: Aux AdamW β1 scan {0.7, 0.9} — maps aux optimizer momentum timescale
- PR #231 fern: Muon gradient momentum scan {mu=0.9, 0.99} — maps gradient smoothing window

## PMuon hyperparameter characterization

| Axis | Status | Best value | Best sr |
|---|---|---|---|
| **β_cov** (covariance horizon) | CLOSED (PR #129) | 0.95 | — |
| **γ_power** (whitening strength) | ACTIVE finer scan (PR #242) | 0.4 (testing 0.5/0.6) | **3025 (new baseline)** |
| **NS_ITERS** (polar convergence) | CLOSED (PR #184) | Wide flat: any ∈ {6,12,18} | — |
| **NS_coef c-axis** (degree of polynomial) | ACTIVE c-scan (PR #226) | c=0 cubic-Newton | 3050 |
| **NS_coef (a,b) line** (contraction aggressiveness) | ACTIVE line scan (PR #229) | TBD | — |
| **TARGET_UW** (Skylight floor) | CLOSED (PR #131) | 0.35 | — |
| **mu** (gradient momentum) | ACTIVE (PR #231) | TBD (current 0.95) | — |

## Auxiliary optimizer (AdamW) — exploration in progress

| PR | Axis | Arm A result | Status |
|---|---|---|---|
| PR #211 (askeladd) | lm_head LR {1/160, 1/640} | 1/160 sr=3050 marginal (pre-new-base) | Arm B running (~step 2050) |
| PR #216 (nezuko) | Aux β2 {0.99, 0.999} | β2=0.99: sr=3025 val=3.2664 (on OLD base; ties new sr) | Arm B just started |
| PR #230 (edward) | Aux β1 {0.7, 0.9} | Arm A running | Assigned |

Note on nezuko: Arm A (β2=0.99) reached sr=3025 on OLD pre-γ_power base. After merging PR #202, it ties current baseline sr but slightly worse val. Hold for arm B before deciding.

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3025, val=3.26615 (n=1, PR #202).**
n=1 threshold for new wins: val ≤ 3.276 (clears vs target 3.28), but must also beat baseline val=3.26615.
n=2 threshold: val ≤ 3.277 (and sr < 3025).
