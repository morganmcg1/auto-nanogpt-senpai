# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-17 05:45 UTC — **PRs #197 (EMA), #195 (cf-scan), #198 (deep-WD) CLOSED. 3 new assignments: PR #229 alphonse (NS coef ab-line-scan), PR #230 edward (aux β1-scan), PR #231 fern (Muon momentum scan). 5 WIP runs active.**
- **Most recent direction from humans:** None (no GitHub issues open at 05:40 UTC check).
- **Target:** Push `speedrun/final_first_step_to_target` below 3050 steps; public record is 3030 steps (Record #20).

## Current local baseline

**sr=3050, val/loss 3.26773 (n=1)** — PR #193 (g1r1-tanjiro, cubic-Newton NS coefs a=1.5, b=-0.5, c=0 on PMuon+u/w-floor+γ=1.2 base).
W&B run: `q8aduc16`

Note: n=1 only — thorfinn PR #225 Wave 7 stack (seeds 1+2) will serve as n=2 confirmation while simultaneously testing the 3-way stack.

Previous baseline (PR #137): sr=3062.5, val=3.269090 (n=2).

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                           | Status (05:45 UTC) |
| --- | ----------- | ------------------------------------------------------------------- | ------------------ |
| **#225** | **thorfinn** | **Wave 7: γ_power=0.4 + deep-strong WD + lm_head 1/160 on cubic-Newton base (n=2)** | Running (~step 625) |
| **#226** | **tanjiro** | **NS coef c-scan {0.1, 0.25} on cubic-Newton base** | Running (~step 725) |
| **#216** | **nezuko** | Aux AdamW β2 scan {0.99, 0.999} | Running (~step 2350) |
| **#202** | **frieren** | γ_power=0.4 WIN arm A (sr=3025); γ_power=0.2 arm B (~step 2600) | Arm B running |
| **#211** | **askeladd** | lm_head LR arm B 1/640 running (~step 1025) | Arm B running |
| **#229** | **alphonse** | NS coef (a,b) cubic-family line scan {a=1.3, 1.7} (c=0, a+b=1) | Just assigned |
| **#230** | **edward** | Aux AdamW β1 scan {0.7, 0.9} — current β1=0.8 | Just assigned |
| **#231** | **fern** | Muon gradient momentum scan {mu=0.9, 0.99} — current mu=0.95 | Just assigned |

## Recently closed

| PR | Student | Result | Decision |
|---|---|---|---|
| **#198** | edward | deep-strong sr=3050 val=3.268193 (NULL vs PR #193 baseline) | CLOSED — mechanism confirmed, in Wave 7 stack |
| **#197** | alphonse | α=0.99 sr=3100; α=0.999 sr=-1 | CLOSED — EMA bias-lag direction closed |
| **#195** | fern | cf=0.85 sr=3075; cf=0.5 sr=3150 (both NULL) | CLOSED — cf=0.7 sweet spot confirmed |
| **#193** | tanjiro | cubic-Newton arm B WIN sr=3050, val=3.26773 | **MERGED → new baseline** |
| **#184** | thorfinn | Both ns_iter=6/18 WIN sr=3050 — wide flat regime | **CLOSED informative null** |

## Key structural findings (program-level)

1. **PMuon polar orthogonality is non-load-bearing.** Changing NS coefs (cubic-Newton c=0, residual ~0.10) or NS iters (6→18, residual 2.31→0.148) produces <0.05% val difference. PMuon's bilateral whitening pre-conditions the gradient so well that only direction matters, not unit-spectrum precision.

2. **γ_power=0.4 is the biggest single-arm win ever (Δsr=−37.5 from 3062.5 baseline).** Arm B (γ_power=0.2) pending — if NULL, monotone direction for finer scan {0.5, 0.6}.

3. **NS coef axis partially characterized.** Quintic (c=0.5) = old baseline (null reference). Cubic-Newton (c=0) = WIN (merged). Jordan (oscillating) = NULL. c ∈ {0.1, 0.25} scan pending (tanjiro PR #226). (a,b) line scan pending (alphonse PR #229).

4. **Deep-strong per-block WD mechanism confirmed active.** WD acts on `p` directly, outside PMuon's whitening + polar path. Both slopes (±0.5) reshape per-block param-norm profile dramatically. Net effect vs PR #193 baseline: near-zero (informative null). Being tested as Wave 7 ingredient.

5. **EMA weight averaging is incompatible with power-law cooldown.** Bias-lag: cooldown's 25× LR drop over 175 steps means live weights improve fast while EMA lags. Negative at α=0.99; severe negative at α=0.999. Same mechanism closed Lookahead (PR #143).

6. **Schedule family (γ, cf) exhausted.** Both γ=1.2 (PR #179 confirmed optimum) and cf=0.7 (PR #195 confirmed concave minimum) are at their respective sweet spots. The "late-eta → val" story is oversimplified — real axis is stable-phase length vs cooldown integral balance.

## Wave 7 stacking plan

**Primary stack (PR #225 thorfinn):**
- γ_power=0.4 + deep-strong WD (slope=+0.5) + lm_head LR 1/160
- On cubic-Newton (c=0) + PMuon+u/w-floor+γ=1.2 base
- n=2 directly (seeds 1+2)
- Conservative additive from new baseline 3050: 3050 − 37.5 − 12.5 − 12.5 = **sr=2987.5**
- Would beat Record #20 (3030) if additive; at 50% compounding: sr≈3025-3037

**Parallel exploration:**
- PR #226 tanjiro: NS coef c-scan {0.1, 0.25} — maps the winning polynomial family
- PR #229 alphonse: NS coef (a,b) line scan — maps contraction aggressiveness of cubic family
- PR #230 edward: Aux AdamW β1 scan {0.7, 0.9} — maps aux optimizer momentum timescale
- PR #231 fern: Muon gradient momentum scan {mu=0.9, 0.99} — maps gradient smoothing window

## PMuon hyperparameter characterization

| Axis | Status | Best value | Best sr |
|---|---|---|---|
| **β_cov** (covariance horizon) | CLOSED (PR #129) | 0.95 | — |
| **γ_power** (whitening strength) | ACTIVE (PR #202) | 0.4 | **3025** (BIGGEST WIN) |
| **NS_ITERS** (polar convergence) | CLOSED (PR #184) | Wide flat: any ∈ {6,12,18} | — |
| **NS_coef c-axis** (degree of polynomial) | ACTIVE c-scan (PR #226) | c=0 cubic-Newton | **3050 (new baseline)** |
| **NS_coef (a,b) line** (contraction aggressiveness) | ACTIVE line scan (PR #229) | TBD | — |
| **TARGET_UW** (Skylight floor) | CLOSED (PR #131) | 0.35 | — |
| **mu** (gradient momentum) | ACTIVE (PR #231) | TBD (current 0.95) | — |

## Auxiliary optimizer (AdamW) — exploration in progress

| PR | Axis | Arm A result | Status |
|---|---|---|---|
| PR #211 (askeladd) | lm_head LR {1/160, 1/640} | 1/160: sr=3050 marginal (val ties baseline) | Arm B running |
| PR #216 (nezuko) | Aux β2 {0.99, 0.999} | Running | Arm A running |
| PR #230 (edward) | Aux β1 {0.7, 0.9} | Just assigned | Assigned |

Static config: embed_lr=0.3, lm_head_lr=1/320, betas=(0.8, 0.95), eps=1e-10. β2=0.95 unusual vs default 0.999; β1=0.8 also unusual vs default 0.9.

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3050, val=3.26773 (n=1, PR #193).**
n=1 threshold for new wins: val ≤ 3.276.
n=2 threshold: val ≤ 3.277.
