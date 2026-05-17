# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-17 02:34 UTC — **THREE INDEPENDENT ARM A WINS: frieren γ_power=0.4 sr=3025 val=3.26615 (BIGGEST, −37.5 sr), thorfinn ns_iter=6 sr=3050 val=3.26774 (−12.5 sr), edward deep-strong WD sr=3050 val=3.26819 (−12.5 sr). Nezuko closed γ axis + reassigned aux β2. 3-way stack est. sr=3000-3025, targeting Record #20 (3030).**
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3062.5 steps; public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3062.5 steps, val/loss 3.269090 (n=2 mean)** — PR #137 (g1r1-nezuko, PMuon + Skylight u/w-floor + power-law cooldown γ=1.2).
W&B runs: `8quuvdrj` (seed-1, sr=3075, val=3.270012) + `l5bdkm6e` (seed-2, sr=3050, val=3.268167). Merged 2026-05-16 18:26 UTC.

n=2 stat-sig margin: (3.28 − 3.269090)·√2 = 0.01543 ✓

**THREE PENDING WINS (terminal post + arm B confirmation needed):**
- **frieren arm A** (γ_power=0.4): sr=3025, val=3.26615, run `prncgzv5` — **BIGGEST (−37.5 sr)**
- **thorfinn arm A** (ns_iter=6): sr=3050, val=3.26774, run `crelrjzb` — partial posted ✓
- **edward arm A** (deep-strong WD): sr=3050, val=3.26819, run `7lzjw46u` — partial NOT posted

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                           | Status (02:34 UTC) |
| --- | ----------- | ------------------------------------------------------------------- | ------------------ |
| **#216** | **nezuko** | **Aux AdamW β2 scan {0.99, 0.999}** (just assigned) | Arm A starting |
| **#211** | **askeladd** | lm_head LR scan — arm A (1/160) | Running (~52%, step 1700/3250) |
| **#202** | **frieren** | PMuon γ_power=0.4 WIN arm A; γ_power=0.2 arm B | Arm B just launched |
| **#198** | **edward** | deep-strong WD WIN arm A; deep-weak arm B | Running (~26%, step 850/3250) |
| **#197** | **alphonse** | EMA α=0.99 NEGATIVE; α=0.999 arm B | Running (~29%, step 950/3250) |
| **#195** | **fern** | cf=0.85 NULL arm A; cf=0.5 arm B | Running (~29%, step 950/3250) |
| **#193** | **tanjiro** | Jordan NULL arm A; cubic-Newton arm B | Running (~60%, step 1950/3250) |
| **#184** | **thorfinn** | ns_iter=6 WIN arm A; ns_iter=18 arm B | Running (~55%, step 1801/3250) |

## Recently closed (this session)

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| **#179** | **nezuko** | γ=1.1: sr=3075; γ=1.3: sr=3075 — both NULL | **CLOSED** — γ=1.2 confirmed local optimum |
| **#131** | **askeladd** | TARGET_UW {0.25-0.45}: all NULL | **CLOSED NULL** — TARGET_UW=0.35 sweet spot |
| **#129** | **frieren** | β_cov: all 3 arms NULL | **CLOSED NULL** — β=0.95 at optimum |
| **#169** | **alphonse** | Per-head polar: sr=3125 | **CLOSED NULL** |
| **#158** | **edward** | LLRD: sr=-1 both arms | **NEGATIVE** |
| **#168** | **fern** | Cosine: sr=3075 | **CLOSED NULL** |
| **#167** | **tanjiro** | SOAP-attn: sr=3100 | **CLOSED NULL** |
| **#143** | **thorfinn** | Lookahead: sr=-1 both arms | **NEGATIVE** |
| #137 | nezuko | Power-law γ=1.2 n=2 | **MERGED — current baseline** |

## 🏆🏆🏆 THREE ARM A WINS — 3-WAY STACKING PLAN

| Rank | Source PR | Mechanism | sr | val | Δsr |
|---|---|---|---|---|---|
| **#1** | frieren PR #202 arm A | γ_power=0.4 (stronger PMuon whitening) | **3025** | **3.26615** | **−37.5** |
| #2 | thorfinn PR #184 arm A | ns_iter=6 (less precise polar) | 3050 | 3.26774 | −12.5 |
| #3 | edward PR #198 arm A | deep-strong per-block WD | 3050 | 3.26819 | −12.5 |

**All three are orthogonal mechanisms:**
- **γ_power=0.4:** Changes the whitening exponent in PMuon's covariance preconditioning. More aggressive spectral normalization of the gradient space before polar projection.
- **ns_iter=6:** Changes the polar projection convergence. Fewer iterations = less precise but preserves more gradient direction information. `ortho_residual=2.31` (high — "useful impurity").
- **deep-strong WD:** Changes per-block parameter regularization. WD acts on `p` directly (`p ← p·(1−lr·wd)`), bypassing PMuon whitening and u/w-floor. Counterbalances block_11's 1.5-3× grad-norm dominance (diagnosed in PR #158).

**3-way stacking prediction:**
- Conservative additive (each win independent): 3062.5 − 37.5 − 12.5 − 12.5 = **sr=3000 steps**
- Sub-additive (50% compounding): ~3025-3037
- This would **tie or beat Prime Intellect public Record #20 (3030 steps)**

**Wave 7 plan (3-way stack, n=2 directly):**
- Wait for thorfinn arm B + edward arm B + frieren arm B terminals to confirm arm A wins hold
- Then assign one student the 3-way stacking PR (n=2, seeds 1+2)
- Expected timeline: ~04:30 UTC for thorfinn terminal; ~06:00 UTC for edward terminal
- Frieren arm B (γ_power=0.2) ETA: ~06:00 UTC

## PMuon hyperparameter status

- **β_cov** (covariance horizon): CLOSED — β=0.95 at local optimum
- **γ_power** (whitening strength): ACTIVE PR #202 — arm A 0.4 WINS BIG; arm B 0.2 just launched
- **NS_iters** (polar convergence): ACTIVE PR #184 — arm A ns_iter=6 WINS; arm B ns_iter=18 at 55%
- **NS_coef** (polar polynomial): ACTIVE PR #193 — arm A Jordan NULL; arm B cubic-Newton at 60%
- **TARGET_UW** (Skylight floor): CLOSED — 0.35 at fired_fraction sweet spot

## Auxiliary optimizer (AdamW) — exploration in progress

| PR | Axis | Status |
|---|---|---|
| PR #211 (askeladd) | lm_head LR {1/160, 1/640} | Arm A running ~52% |
| PR #216 (nezuko) | Aux β2 {0.99, 0.999} | Just assigned |

Static config: embed_lr=0.3, lm_head_lr=1/320, betas=(0.8, **0.95**), eps=1e-10. β2=0.95 is unusually low vs AdamW default of 0.999.

## Wave 5 — multi-axis portfolio final status

| PR | Mechanism | Final result |
|---|---|---|
| #137 (merged) | γ=1.2, cf=0.7 | **Baseline (sr=3062.5)** |
| #179 (CLOSED) | γ ∈ {1.1, 1.3} | Both NULL — γ=1.2 optimum, axis closed |
| #195 (fern) | cf ∈ {0.5, 0.85} | Arm A NULL (cf=0.85); arm B cf=0.5 running |
| #184 (thorfinn) | NS_ITERS ∈ {6, 18} | **ARM A WIN (ns_iter=6, sr=3050)** |
| #193 (tanjiro) | NS coefs | Arm A Jordan NULL; arm B cubic-Newton running |
| #197 (alphonse) | EMA avg | Arm A NEGATIVE (α=0.99); arm B α=0.999 running |
| #198 (edward) | Per-block WD | **ARM A WIN (deep-strong, sr=3050)** |
| #202 (frieren) | γ_power ∈ {0.2, 0.4} | **ARM A WIN (γ_power=0.4, sr=3025, BIGGEST)** |

## Null/negative tally

**19 consecutive nulls/negatives → THREE non-schedule WINS arm A:**
1. γ_power=0.4 (frieren PR #202 arm A) — sr=3025, biggest win
2. ns_iter=6 (thorfinn PR #184 arm A) — sr=3050
3. deep-strong WD (edward PR #198 arm A) — sr=3050

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3062.5, val=3.269090** (n=2 PR #137).
- Frieren arm A n=1: (3.28−3.26615)×√1 = **0.01385 ✓** (3.46× threshold)
- Thorfinn arm A n=1: (3.28−3.26774)×√1 = **0.01226 ✓** (3.07× threshold)
- Edward arm A n=1: (3.28−3.26819)×√1 = **0.01181 ✓** (2.95× threshold)
