# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-17 01:40 UTC — **TWO independent arm A WINS detected via W&B: thorfinn ns_iter=6 (sr=3050, val=3.26774) AND edward deep-strong WD (sr=3050, val=3.26819). Both tie on sr; orthogonal mechanisms. Alphonse α=0.99 NEGATIVE, nezuko/fern/tanjiro arm A NULL. Frieren γ_power=0.4 78%, nezuko γ=1.3 82%.**
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3062.5 steps; public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3062.5 steps, val/loss 3.269090 (n=2 mean)** — PR #137 (g1r1-nezuko, PMuon + Skylight u/w-floor + power-law cooldown γ=1.2).
W&B runs: `8quuvdrj` (seed-1, sr=3075, val=3.270012) + `l5bdkm6e` (seed-2, sr=3050, val=3.268167). Merged 2026-05-16 18:26 UTC.

n=2 stat-sig margin: (3.28 − 3.269090)·√2 = 0.01543 ✓

**TWO PENDING NEW BASELINES (terminal post + arm B needed):**
- **thorfinn arm A** (ns_iter=6): sr=3050, val=3.26774, run `crelrjzb` — partial posted ✓, arm B running
- **edward arm A** (deep-strong WD): sr=3050, val=3.26819, run `7lzjw46u` — partial NOT YET posted, arm B running

## Active experiments (status:wip)

| PR  | Student     | Arm A result                                                        | Arm B status (01:40 UTC) |
| --- | ----------- | ------------------------------------------------------------------- | ----------------- |
| **#211** | **askeladd** | lm_head LR scan — arm A (1/160) running (~25%, step 825/3250) | Sequential |
| **#202** | **frieren** | γ_power=0.4 running (~78%, step 2525/3250) | After arm A |
| **#198** | **edward** | **deep-strong WD WIN sr=3050 val=3.26819** (partial pending post) | deep-weak running (~4%) |
| **#197** | **alphonse** | EMA α=0.99 NEGATIVE sr=3100 val=3.27504 | α=0.999 running (~3%) |
| **#195** | **fern** | cf=0.85 NULL sr=3075 val=3.27214 (partial pending post) | cf=0.5 running (~4%) |
| **#193** | **tanjiro** | Jordan-opt NULL sr=3075 val=3.27041 (partial pending post) | cubic-Newton running (~34%) |
| **#184** | **thorfinn** | **ns_iter=6 WIN sr=3050 val=3.26774** | ns_iter=18 running (~31%) |
| **#179** | **nezuko** | γ=1.1 NULL on sr=3075 val=3.26813 | γ=1.3 running (~82%) |

## Recently closed (this session)

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| **#131** | **askeladd** | TARGET_UW {0.25, 0.30, 0.40, 0.45}: all NULL; best sr=3100 (uw=0.30); fired_fraction collapses below uw=0.30 | **CLOSED NULL** — TARGET_UW=0.35 at fired_fraction transition sweet spot |
| **#129** | **frieren** | β_cov scan: all 3 arms NULL; eigh shows β=0.95 at conditioning sweet spot | **CLOSED NULL** — β_cov axis fully characterized |
| **#169** | **alphonse** | Per-head polar: sr=3125, polar saturation confirmed structural | **CLOSED NULL** |
| **#158** | **edward** | LLRD: sr=-1 both arms (NEGATIVE) — direction reversed | **NEGATIVE** |
| **#168** | **fern** | Cosine: sr=3075 (NULL vs merged baseline) | **CLOSED NULL** |
| **#167** | **tanjiro** | SOAP-attn: sr=3100, post_to_pre_ratio≈1.0 | **CLOSED NULL** |
| **#143** | **thorfinn** | Lookahead: sr=-1 both arms | **NEGATIVE** |
| #137 | nezuko | Power-law γ=1.2 n=2: sr=3062.5 val=3.269090 | **MERGED — current baseline** |

## 🏆🏆 DUAL ARM A WIN: thorfinn × edward

**Two orthogonal mechanisms tie on sr=3050 (n=1):**

| Axis            | Mechanism                | Δsr vs baseline | Δval vs baseline | Bypasses PMuon u/w-floor? |
|----------------|-------------------------|-----------------|------------------|---------------------------|
| Polar projection | ns_iter=6 (PR #184)      | −12.5           | −0.00135         | No (still gradient direction) |
| Weight decay   | deep-strong WD (PR #198) | −12.5           | −0.00090         | **Yes** (acts on `p` directly) |

**Mechanistic distinction:**
- **thorfinn (ns_iter=6):** changes the gradient direction quality. `polar/ortho_residual_sample=2.31` (high — less convergent) means the polar step preserves more momentum direction information. Over-orthogonalization removes useful gradient signal.
- **edward (deep-strong WD):** changes the weight regularization. WD acts on `p` directly (`p ← p·(1 − lr·wd)`), so it bypasses PMuon whitening + u/w-floor and provides a damping term that scales with parameter magnitude. Deep-strong (block_11 = 1.5-3× grad-norm dominance, per PR #158 LLRD diagnostic) successfully counterbalances without starving its LR (LLRD's failure mode).

**Why these are orthogonal:** ns_iter changes the optimizer step direction at the polar projection level. Per-block WD changes the parameter regularization independently. They modify different parts of the update equation:
- ns_iter affects `D_polar = polar(D_whitened)` (one matrix per param)
- WD affects `p_t+1 = (1 − lr·wd)·p_t − lr·D_polar` (subtractive penalty)

**Stacking prediction for Wave 7:**
- Conservative additive estimate: 3062.5 − 12.5 − 12.5 = **3037.5** (if effects compound linearly at n=1)
- If interactive (sub-additive): 3050 or so
- If synergistic (super-additive, rare): could push toward 3025 or below
- Public record is 3030 (Record #20 Contra-Soft-Muon stack)

**Action plan:**
1. Wait for thorfinn arm B (ns_iter=18) terminal (~04:30 UTC)
2. Wait for edward arm A partial post + arm B (deep-weak) terminal (~06:20 UTC)
3. Wave 7 PR: ns_iter=6 + deep-strong WD stacking on PMuon+u/w-floor+γ=1.2 base, n=1 screening then n=2 confirmation

## Polar saturation context — updated by thorfinn finding

Prior characterization was "all polar mechanism additions null". Thorfinn arm A nuances this:
- The polar MAP itself can be changed — fewer NS iterations changes the polar projection character
- The saturation is not "polar is always useless" but "post-polar additions are useless"
- Action: if thorfinn terminal confirms ns_iter=6, explore {ns_iter=3, 4, 5} and interaction with γ_power

## PMuon hyperparameter status

- **β_cov** (covariance horizon): CLOSED — β=0.95 at local optimum
- **γ_power** (whitening strength): ACTIVE PR #202 (frieren) — arm A γ_power=0.4 78% done, expect terminal ~02:30 UTC
- **NS_iters** (polar convergence): ACTIVE PR #184 (thorfinn) — ARM A WINS at ns_iter=6
- **NS_coef** (polar polynomial): ACTIVE PR #193 (tanjiro) — arm A Jordan NULL (sr=3075); cubic-Newton at 34%

**Ortho_residual connection:** Jordan coef gives residual=11.12 (worse than ns_iter=6's 2.31) but Jordan arm is NULL while ns_iter=6 WINS. Mechanism: the PATH to impure polar matters — ns_iter=6 is "early exit from good convergence direction" while Jordan is "aggressive but different polynomial path."

## Auxiliary optimizer (AdamW) — NEW DIRECTION

**First probe ever on aux optimizer hyperparameters:**
- lm_head LR scan {1/640, 1/160} — PR #211 (askeladd) arm A (1/160) running 25%, expect terminal ~04:00 UTC
- Static config since PR #64 era: embed_lr=0.3, lm_head_lr=1/320, betas=(0.8, 0.95), eps=1e-10
- Next: if PR #211 nulls, sweep aux β1={0.85, 0.95} and/or β2={0.99, 0.999}

## Wave 5 — multi-axis portfolio status

| PR | Mechanism | Status |
|---|---|---|
| PR #137 (merged) | γ=1.2, cf=0.7 | **Baseline (sr=3062.5)** |
| PR #179 (nezuko) | γ ∈ {1.1, 1.3}, cf=0.7 | Arm A NULL (γ=1.1 sr=3075); arm B (γ=1.3) 82% done |
| PR #195 (fern) | γ=1.2, cf ∈ {0.5, 0.85} | Arm A NULL (cf=0.85 sr=3075); arm B running |
| PR #184 (thorfinn) | NS_ITERS ∈ {6, 18} | **ARM A WIN (sr=3050)**; arm B 31% |
| PR #193 (tanjiro) | NS coefficients {Jordan, cubic-Newton} | Arm A Jordan NULL (sr=3075); arm B 34% |
| PR #197 (alphonse) | EMA weight averaging α ∈ {0.99, 0.999} | Arm A NEGATIVE (sr=3100); arm B 3% |
| PR #198 (edward) | Per-block WD coupling {strong, weak} | **ARM A WIN (sr=3050)**; arm B running |
| PR #202 (frieren) | PMuon γ_power ∈ {0.2, 0.4} | Arm A γ_power=0.4 at 78% done |

## Null/negative tally — mechanism additions on PMuon+u/w-floor

**19 consecutive nulls/negatives → TWO non-schedule WINS arm A (thorfinn + edward, both at sr=3050)**

Schedule shape confirmed win (PR #137). FIRST and SECOND non-schedule wins:
1. NS_ITERS=6 (PR #184 arm A) — polar projection quality
2. Deep-strong per-block WD (PR #198 arm A) — parameter regularization

Both at n=1, need terminal SENPAI-RESULTs to merge.

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3062.5, val=3.269090** (n=2 PR #137).
Thorfinn arm A n=1: (3.28-3.26774)×√1 = 0.01226 ✓ (margin 3× above threshold)
Edward arm A n=1: (3.28-3.26819)×√1 = 0.01181 ✓ (margin 3× above threshold)
