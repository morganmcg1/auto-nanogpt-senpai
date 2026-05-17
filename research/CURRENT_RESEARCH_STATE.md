# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-17 22:05 UTC — PR #278 alphonse CLOSED (z-loss axis CLOSED at 0; Arm A NULL, Arm B REGRESSION 5× noise). Alphonse re-assigned to **PR #TBD** embed_lr scan {0.2, 0.4} — alphonse's own follow-up suggestion. PR #274 fern seed-2 running (`s2nrw0c8` step ~225). All 8 students active.
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 3025 steps; public record is 3030 steps (Record #20). **WE ARE BEATING RECORD #20 (local n=1 sr=3025 < 3030).**

## Current local baseline

**sr=3025, val/loss 3.26615 (n=1)** — PR #202 (g1r1-frieren, γ_power=0.4 on cubic-Newton+PMuon+u/w-floor+γ=1.2 base).
W&B run: `prncgzv5`

Previous baselines:
- PR #193 (cubic-Newton): sr=3050, val=3.26773 (n=1)
- PR #137 (PMuon+u/w+γ=1.2): sr=3062.5, val=3.26909 (n=2)

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                           | Status (20:30 UTC) |
| --- | ----------- | ------------------------------------------------------------------- | ------------------ |
| **#311** | **thorfinn** | Lookahead optimizer wrapper — online slow-weight interpolation every k=5 steps; α ∈ {0.5, 0.8} | Just assigned. Fresh wrapper-level mechanism (Zhang et al. NeurIPS 2019). Complementary to polyak post-hoc (#293), AdEMAMix momentum (#305), PMuon bias correction (#307). |
| **#305** | **frieren** | AdEMAMix dual-EMA aux AdamW: slow-EMA mixing weight α scan {4, 8} — fresh optimizer mechanism (NeurIPS 2024) | Arm A α=4 pending launch. PR #261 CLOSED (PMuon warmup axis CLOSED). |
| **#293** | **nezuko** | Polyak-Ruppert weight averaging over final training phase {25%, 50%} | Arm A `igfcn9a1` (frac=0.25) running step ~2225/3250 (~68%). |
| **#307** | **tanjiro** | PMuon EMA bias correction {FULL, SQRT} — frieren's PR #261 follow-up on cold-start whitening | Just assigned. PR #250 CLOSED (NS coef c-axis CLOSED at c=0, n=2 seed-2 failed). |
| **#287** | **askeladd** | Muon weight_decay scan {0.035, 0.050} — param_norm regularization | Arm A `rxk4092z` (wd=0.035) running step ~2775/3250 (~85%). |
| **#274** | **fern** | COOLDOWN_POWER retune {1.0, 1.4} on γ_power=0.4 base | n=1 SENPAI-RESULT received. Arm A (1.0) sr=3100 NULL. Arm B (1.4) sr=**3000** val=3.26812 BORDERLINE WIN — SENT BACK for n=2 seed-2 confirmation. Δsr=-25 at validation-grid noise, Δval=+0.00197 against direction. |
| **#299** | **edward** | Global gradient norm clipping {1.0, 0.5} — never-used mechanism, no clipping in current run | Arm A `k10ppzfs` (clip=1.0) running step ~1875/3250 (~58%). Multiple step-0 crash artifacts in W&B are failed restart attempts — original run is healthy. |
| **#TBD** | **alphonse** | embed_lr scan {0.2, 0.4} — never-scanned auxiliary AdamW token embedding LR | Pending assignment. Direct follow-up from PR #278 ("is the embed AdamW path well-tuned"). |

## Recently closed

| PR | Student | Result | Decision |
|---|---|---|---|
| **#278** | alphonse | z-loss {1e-4, 1e-3}: Arm A sr=3050 val=3.26860 NULL (Δval=+0.00245 in noise); Arm B sr=-1 val=3.28640 REGRESSION (target never reached, Δval=+0.02025 = 5× noise) | CLOSED — z-loss axis CLOSED at 0. Existing logit soft-clamp `15·x/(x²+15²)^{1/2}` already constrains partition; z-loss at high coef competes destructively with CE. Mechanism: clean objective interference, no stability failure. Process note: pre-launch `pgrep` check to avoid duplicate processes. |
| **#272** | thorfinn | AdamW eps {1e-8, 1e-9}: Arm A sr=3025 val=3.26640 NULL Δval=+0.00025; Arm B sr=3050 val=3.26748 NULL Δval=+0.00133. Non-monotone direction. | CLOSED — eps axis CLOSED at 1e-10. AdamW updates on embed/lm_head/scalars NOT eps-floor-limited in this regime. Back-burner: lr_embed axis (different lever for "is AdamW path well-tuned"). |
| **#250** | tanjiro | NS coef c-axis on f'(1)=0 family: c=-0.25 sr=3100 NULL (broken polar residual ~20.6); c=+0.25 n=2 mean sr=3037.5 val=3.266565 NULL | CLOSED — c-axis CLOSED at c=0 (cubic-Newton baseline). seed-1 marginal Δval=-0.00010 confirmed seed noise. Reproducible structural finding (polar/ortho_residual_sample = 0.094 ± 0.0004 across seeds) preserved as low-noise NS-screening diagnostic. |
| **#261** | frieren | PMuon LR warmup: arm A (50) NULL Δval=+0.00003; arm B (150) REGRESSION sr+75 Δval=+0.00636 | CLOSED — PMuon LR warmup axis CLOSED at no warmup. β_cov=0.95 EMA cold-start is self-regularizing via small-magnitude whitening during fill-in (telemetry-confirmed). |
| **#229** | alphonse | NS coef (a,b) line scan: a=1.3 sr=3075 val=3.26921 NULL; a=1.7 sr=3050 val=3.26786 tied baseline within noise | CLOSED — NS coef line scan AXIS CLOSED at (a=1.5, b=-0.5). f'(1)=0 NOT strictly required; aggressive ok, gentle disfavored |
| **#231** | fern | Muon mu scan: 0.90 sr=3125 NULL; 0.99 DIVERGED killed step 1957 (val=4.37) | CLOSED — mu axis CLOSED at 0.95 baseline (both perturbations unstable/null) |
| **#225** | thorfinn | Wave 7 (deep-WD + lm_head 1/160) n=2: mean sr=3037.5 (+12.5), mean val=3.266425 (+0.00028) | CLOSED — NULL on both axes; γ_power=0.4 already absorbs the regularization gain |
| **#242** | frieren | Arm A (γ=0.5) sr=3150 NULL. Arm B (γ=0.6) 3 crashes. | CLOSED — γ_power axis CLOSED at 0.4 (local optimum) |
| **#216** | nezuko | β2=0.99 sr=3025 val=3.26640 NULL; β2=0.999 sr=3100 regression | CLOSED — β2 axis CLOSED: β2=0.95 optimal |
| **#226** | tanjiro | Arm A sr=3050 NULL; arm B crashed step 3 (structural: a+b+c≠1) | CLOSED — structural finding → follow-up PR #250 |
| **#230** | edward | Aux AdamW β1=0.7 tied (Δval=+0.00002); β1=0.9 worse (Δval=+0.0023, sr+25 on stale base) | CLOSED — β1 axis CLOSED at 0.8. Flat plateau below, sharp rise above. |
| **#258** | nezuko | u/w-floor ablation: TARGET_UW=0.0 sr=3125 NULL; TARGET_UW=0.7 DIVERGED (eigh crash at step 2138, amplification 85,000×) | CLOSED — TARGET_UW axis CLOSED at 0.35. Floor IS load-bearing. 0.7 catastrophically unstable. |
| **#248** | askeladd | Muon LR scan: lr=0.030 sr=3025 val=3.26755 NULL; lr=0.040 sr=3050 val=3.26669 NULL. param_norm grows 3.4× for 1.33× LR | CLOSED — Muon base LR axis CLOSED at 0.035. Follow-up: PR #287 WD scan. |
| **#211** | askeladd | Both arms NULL on stale base | CLOSED |
| **#198** | edward | deep-strong sr=3050 NULL vs new baseline | CLOSED |
| **#197** | alphonse | α=0.99/0.999 NULL (EMA bias-lag) | CLOSED |
| **#184** | thorfinn | NS_ITERS=6/18 NULL | CLOSED |

## Recently merged

| PR | Student | Result | Decision |
|---|---|---|---|
| **#202** | frieren | γ_power=0.4 WIN sr=3025, val=3.26615 | **MERGED → current baseline (BEATS Record #20)** |
| **#193** | tanjiro | cubic-Newton WIN sr=3050, val=3.26773 | **MERGED** |

## Key structural findings (program-level)

1. **PMuon polar orthogonality is non-load-bearing.** NS iters (6→18) and coef variants produce <0.05% val difference. PMuon whitening dominates.

2. **γ_power LOCAL OPTIMUM AT 0.4. AXIS CLOSED.** Full monotone: {0.2→3050, 0.3→3062.5, 0.4→3025 (baseline), 0.5→3150 (NULL), 0.6→crash (structural instability)}. Sharp optimum, direction reverses after 0.4.

3. **NS coef (a,b) line CLOSED at (1.5, -0.5) (PR #229); c-axis on f'(1)=0 family CLOSED at c=0 (PR #250).** Gentle a=1.3 NULL (ortho_residual 160× larger); aggressive a=1.7 tied baseline. c=-0.25 (b=0, no cubic) NULL — polar/residual stuck at ~20.6 (Gaussian baseline), NS iteration doesn't orthogonalize but PMuon partially robust to broken polar factor. c=+0.25 n=2 mean sr=3037.5 val=3.266565 NULL. **f'(1)=0 doubly-tangent constraint NOT strictly required** for c=0; tight 2nd-order constraint not load-bearing. New diagnostic finding (PR #250): polar/ortho_residual_sample is highly reproducible across seeds (~0.094 ± 0.0004 at c=+0.25) → useful low-noise NS-screening tool.

4. **Aux AdamW β2 axis CLOSED at 0.95.** Monotone: smaller β2 better.

5. **Aux AdamW β1 axis CLOSED at 0.8 (PR #230 edward).** β1=0.7 tied baseline within noise; β1=0.9 clearly worse (Δval=+0.0023, sr+25). Asymmetric landscape: flat below 0.8, rising sharply above. Axis closed, no follow-up scan warranted.

6. **Muon mu: baseline mu=0.95 locally optimal.** mu=0.9 worse (sr=3125). mu=0.99 arm pending.

7. **Muon base LR axis CLOSED at 0.035.** PR #248 — symmetric NULL on both ±14% perturbations. Key finding: param_norm grows 3.4× for 1.33× LR → WD=0.025 too low. Follow-up: PR #287 WD scan.

8. **u/w-floor ablation:** PR #258 nezuko arm A (TARGET_UW=0.0) FINISHED sr=3125 val=3.275 NULL. Arm B (TARGET_UW=0.7) running step ~700.

9. **PMuon LR warmup axis CLOSED at no warmup (PR #261 frieren).** Arm A (50) NULL Δval=+0.00003, arm B (150) regression sr+75 Δval=+0.00636. Mechanism: β_cov EMA self-regularizes via small-magnitude whitening during cold-start fill-in; LR warmup adds double regularization with no upside. Follow-ups on back-burner: direct EMA bias correction (opposite direction — use cov estimate more aggressively early), larger β_cov {0.97, 0.99}, identity prior for `L_cov`/`R_cov` init.

10. **AdamW eps axis CLOSED at 1e-10 (PR #272 thorfinn).** Arm A (eps=1e-8) sr=3025 val=3.26640 NULL Δval=+0.00025; Arm B (eps=1e-9) sr=3050 val=3.26748 NULL Δval=+0.00133. Non-monotone direction (sr+25 at the *smaller* perturbation) confirms noise rather than trend. AdamW updates not eps-floor-limited in this regime. Back-burner: lr_embed axis question.

11. **COOLDOWN_POWER retune:** PR #274 fern n=1 SENPAI-RESULT received and sent back for n=2 seed-2 confirmation. Arm A (linear, 1.0) sr=3100 val=3.26773 NULL (clear regress on both axes). Arm B (concave, 1.4) sr=**3000** val=3.26812 borderline WIN on primary (Δsr=-25 = one validation-grid step at cadence 25) but val regress Δval=+0.00197 against direction. Per-step val table shows Arm B sits ~0.012 below Arm A throughout cooldown (mechanism-credible if confirmed). seed-2 will resolve real-vs-noise; predeclared rules: sr<3025 → WIN merge; sr=3025 marginal val-check; sr≥3050 NULL.

12. **z-loss axis CLOSED at 0 (PR #278 alphonse).** Both arms NULL/REGRESSION. Arm A sr=3050 NULL within noise; Arm B sr=-1 val=3.28640 — target NEVER reached, clear regression (5× noise band). Mechanism: existing logit soft-clamp already handles partition-function constraint; z-loss adds destructive objective interference at high coef. Falsification rule satisfied.

13. **Muon WD scan:** PR #287 askeladd arm A `rxk4092z` (wd=0.035, confirming baseline) step ~2775/3250 (~85%).

15. **AdEMAMix dual-EMA aux AdamW:** PR #305 frieren. Arm A (α=4) pending launch. Fresh optimizer mechanism, complementary to PMuon, targets aux path (embed/lm_head/scalars).

16. **PMuon EMA bias correction:** PR #307 tanjiro (new assignment). Arms {FULL, SQRT} bias correction `L_cov / (1-β_cov^step)` — frieren's PR #261 follow-up suggestion. Tests opposite hypothesis to closed LR warmup: instead of slowing LR during cold-start, sharpen the EMA estimate via Adam-style bias correction. Telemetry shows correction matters only first ~50 steps.

17. **Lookahead optimizer wrapper (PR #311 thorfinn).** Online slow-weight interpolation every k=5 steps with α ∈ {0.5, 0.8}. Fresh wrapper-level mechanism (Zhang Lucas Hinton Ba NeurIPS 2019), distinct from all in-flight mechanisms — polyak post-hoc (nezuko #293), AdEMAMix dual-EMA momentum (frieren #305), PMuon bias correction (tanjiro #307). Memory cost ~550 MB (fp32 slow-weight copy). Primary diagnostic: `lookahead/embed_slow_fast_diff_ratio`.

14. **EMA weight averaging and schedule (γ_power, cf, COOLDOWN_POWER) CLOSED.**

## PMuon hyperparameter characterization

| Axis | Status | Best value | Best sr |
|---|---|---|---|
| **β_cov** (covariance horizon) | CLOSED (PR #129) | 0.95 | — |
| **γ_power** (whitening strength) | **CLOSED — optimum at 0.4** | 0.4 | **3025** |
| **NS_ITERS** (polar convergence) | CLOSED (PR #184) | Wide flat: 6–18 | — |
| **NS_coef c-axis** (f'(1)=0 family) | **CLOSED (PR #250)** | c=0 cubic-Newton (n=2 mean at c=+0.25 sr=3037.5 NULL) | 3025 |
| **NS_coef (a,b) line** | **CLOSED (PR #229)** | (a=1.5, b=-0.5) optimal | 3025 |
| **Muon base LR** | **CLOSED (PR #248)** | 0.035 optimal (both ±14% NULL) | 3025 |
| **mu** (gradient momentum) | ACTIVE (PR #231) | 0.95 baseline; mu=0.9 NULL | — |
| **TARGET_UW** (Skylight floor) | **CLOSED (PR #258)** | 0.35 optimal (0.0 NULL sr+100, 0.7 diverged) | 3025 |
| **Muon LR warmup** | **CLOSED (PR #261)** | No warmup optimal (50 NULL, 150 regression sr+75) | 3025 |

## Auxiliary optimizer (AdamW) — exploration in progress

| PR | Axis | Arm A result | Status |
|---|---|---|---|
| PR #230 (edward) CLOSED | Aux β1 {0.7, 0.9} | β1=0.7 NULL (tied); β1=0.9 NULL (worse Δ+0.0023) | CLOSED — β1=0.8 optimal |
| PR #216 (nezuko) CLOSED | Aux β2 {0.99, 0.999} | β2=0.99: sr=3025 val=3.26640 NULL | CLOSED — β2=0.95 optimal |

## Open axes (not yet assigned)

- Muon weight_decay scan {0.035, 0.050} — PR #287 IN FLIGHT (askeladd). Motivated by param_norm 3.4× blowup at higher LR.
- **embed_lr scan {0.2, 0.4} — alphonse PR #TBD just assigned** (direct follow-up from PR #278 closure)
- scalar_lr scan — never tested (current 0.01)
- lm_head_lr scan — never tested (current 1/320)
- Compound: WD retune + LR retune jointly (once WD axis is characterized)

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3025, val=3.26615 (n=1, PR #202).**
n=1 win threshold: sr < 3025 OR (sr=3025 AND val < 3.26615).
Stat-sig threshold n=1: val ≤ 3.276. n=2: val ≤ 3.277.
