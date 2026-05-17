# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-17 04:35 UTC — **PR #193 cubic-Newton MERGED (new baseline sr=3050). PR #184 CLOSED (wide flat NS_ITERS regime). Wave 7 3-way stack assigned to thorfinn (PR #225). NS coef c-scan assigned to tanjiro (PR #226). 5+ arm B runs still pending.**
- **Most recent direction from humans:** None (no GitHub issues open at 04:10 UTC check).
- **Target:** Push `speedrun/final_first_step_to_target` below 3050 steps; public record is 3030 steps (Record #20).

## Current local baseline

**sr=3050, val/loss 3.26773 (n=1)** — PR #193 (g1r1-tanjiro, cubic-Newton NS coefs a=1.5, b=-0.5, c=0 on PMuon+u/w-floor+γ=1.2 base).
W&B run: `q8aduc16`

Note: n=1 only — thorfinn PR #225 Wave 7 stack (seeds 1+2) will serve as n=2 confirmation while simultaneously testing the 3-way stack.

Previous baseline (PR #137): sr=3062.5, val=3.269090 (n=2).

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                           | Status (04:35 UTC) |
| --- | ----------- | ------------------------------------------------------------------- | ------------------ |
| **#225** | **thorfinn** | **Wave 7: γ_power=0.4 + deep-strong WD + lm_head 1/160 on cubic-Newton base (n=2)** | Just assigned — ETA ~7h |
| **#226** | **tanjiro** | **NS coef c-scan {0.1, 0.25} on cubic-Newton base** | Just assigned — ETA ~7h |
| **#216** | **nezuko** | Aux AdamW β2 scan {0.99, 0.999} | Arm A running |
| **#211** | **askeladd** | lm_head LR arm A done (sr=3050 marginal); arm B 1/640 to launch | Arm A finished, arm B pending |
| **#202** | **frieren** | γ_power=0.4 WIN arm A (sr=3025); γ_power=0.2 arm B mid-run | Arm B running (~48%) |
| **#198** | **edward** | deep-strong WD WIN arm A; deep-weak arm B mid-run | Arm B running (~82%) |
| **#197** | **alphonse** | α=0.99 NEGATIVE arm A; α=0.999 arm B mid-run (predicted NEGATIVE) | Arm B running (~79%) |
| **#195** | **fern** | cf=0.85 NULL arm A; cf=0.5 arm B mid-run (η↑ at same step → might win) | Arm B running (~78%) |

## Recently closed/merged

| PR | Student | Result | Decision |
|---|---|---|---|
| **#193** | tanjiro | cubic-Newton arm B WIN sr=3050, val=3.26773 | **MERGED → new baseline** |
| **#184** | thorfinn | Both ns_iter=6/18 WIN sr=3050 — wide flat regime | **CLOSED informative null** |
| **#179** | nezuko | γ=1.1/1.3 both NULL | CLOSED — γ=1.2 confirmed optimum |
| **#131** | askeladd | TARGET_UW scan — all NULL | CLOSED — 0.35 at sweet spot |
| **#129** | frieren | β_cov scan — all NULL | CLOSED — β=0.95 at optimum |

## Key structural findings (program-level)

1. **PMuon polar orthogonality is non-load-bearing.** Changing NS coefs (cubic-Newton c=0, residual ~0.10) or NS iters (6→18, residual 2.31→0.148) produces <0.05% val difference. PMuon's bilateral whitening pre-conditions the gradient so well that only direction matters, not unit-spectrum precision.

2. **γ_power=0.4 is the biggest single-arm win ever (Δsr=−37.5 from 3062.5 baseline).** Arm B (γ_power=0.2) pending — if NULL, monotone direction for finer scan {0.5, 0.6}.

3. **NS coef axis partially characterized.** Quintic (c=0.5) = old baseline (null reference). Cubic-Newton (c=0) = WIN (merged). Jordan (oscillating) = NULL. c ∈ {0.1, 0.25} scan pending with tanjiro PR #226.

4. **Deep-strong per-block WD bypasses PMuon.** WD acts on `p` directly, outside PMuon's whitening + polar path. Provides depth-coupled regularization unreachable through any other axis.

5. **EMA weight averaging is incompatible with power-law cooldown.** Bias-lag: cooldown's 25× LR drop over 175 steps means live weights improve fast while EMA lags. Negative at α=0.99; expected negative at α=0.999 too.

## Wave 7 stacking plan

**Primary stack (PR #225 thorfinn):**
- γ_power=0.4 + deep-strong WD (slope=+0.5) + lm_head LR 1/160
- On cubic-Newton (c=0) + PMuon+u/w-floor+γ=1.2 base
- n=2 directly (seeds 1+2)
- Conservative additive from new baseline 3050: 3050 − 37.5 − 12.5 − 12.5 = **sr=2987.5**
- Would beat Record #20 (3030) if additive; at 50% compounding: sr≈3025-3037

**Parallel exploration (PR #226 tanjiro):**
- NS coef c-scan {0.1, 0.25} on cubic-Newton base
- Maps the winning polynomial family

## PMuon hyperparameter characterization

| Axis | Status | Best value | Best sr |
|---|---|---|---|
| **β_cov** (covariance horizon) | CLOSED (PR #129) | 0.95 | — |
| **γ_power** (whitening strength) | ACTIVE (PR #202) | 0.4 | **3025** (BIGGEST WIN) |
| **NS_ITERS** (polar convergence) | CLOSED (PR #184) | Wide flat: any ∈ {6,12,18} | — |
| **NS_coef** (polar polynomial) | ACTIVE c-axis (PR #226) | c=0 cubic-Newton | **3050 (new baseline)** |
| **TARGET_UW** (Skylight floor) | CLOSED (PR #131) | 0.35 | — |

## Auxiliary optimizer (AdamW) — exploration in progress

| PR | Axis | Arm A result | Status |
|---|---|---|---|
| PR #211 (askeladd) | lm_head LR {1/160, 1/640} | 1/160: sr=3050 marginal (val ties baseline) | Arm B to launch |
| PR #216 (nezuko) | Aux β2 {0.99, 0.999} | Running | Arm A running |

Static config: embed_lr=0.3, lm_head_lr=1/320, betas=(0.8, 0.95), eps=1e-10. β2=0.95 unusual vs default 0.999.

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3050, val=3.26773 (n=1, PR #193).**
n=1 threshold for new wins: val ≤ 3.276.
n=2 threshold: val ≤ 3.277.
