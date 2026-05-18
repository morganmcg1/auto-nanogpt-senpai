# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-18 01:05 UTC — PR #287 askeladd CLOSED (Muon WD CLOSED at 0.025, both arms NULL, monotone wrong direction). Askeladd re-assigned to **PR #327** Adan optimizer on aux AdamW path. PR #311 thorfinn SENT BACK (Lookahead all arms crashing at step 1-25, gradient explosion; debugging guidance posted). PR #274 fern seed-2 (cooldown_power=1.4) running at step 2750/3250 — **POTENTIAL WIN: seed-1 sr=3000 < 3025 baseline!** Awaiting seed-2 confirmation.
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 3025 steps; public record is 3030 steps (Record #20). **WE ARE BEATING RECORD #20 (local n=1 sr=3025 < 3030).**

## Current local baseline

**sr=3025, val/loss 3.26615 (n=1)** — PR #202 (g1r1-frieren, γ_power=0.4 on cubic-Newton+PMuon+u/w-floor+γ=1.2 base).
W&B run: `prncgzv5`

Previous baselines:
- PR #193 (cubic-Newton): sr=3050, val=3.26773 (n=1)
- PR #137 (PMuon+u/w+γ=1.2): sr=3062.5, val=3.26909 (n=2)

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                           | Status (01:05 UTC 2026-05-18) |
| --- | ----------- | ------------------------------------------------------------------- | ------------------------------ |
| **#274** | **fern** | COOLDOWN_POWER retune {1.0, 1.4} on γ_power=0.4 base | **POTENTIAL WIN!** Arm B (1.4) seed-1 `vw0595an` FINISHED sr=**3000**, val=3.2681. Seed-2 `s2nrw0c8` running at step 2750/3250. ETA ~01:30 UTC. Arm A (1.0) `ui55xcml` crashed. |
| **#317** | **nezuko** | Lion optimizer on embed path — sign-momentum {lr=0.03, lr=0.10} — fresh optimizer family replacing AdamW on highest-LR param group | Active WIP. Just assigned (follow-up from PR #293 Polyak CLOSED). |
| **#327** | **askeladd** | Adan optimizer for aux AdamW — 3-buffer adaptive Nesterov (lr_mult scan {1.0, 0.33}) | Just assigned. Follow-up from PR #287 CLOSED (Muon WD axis CLOSED at 0.025). |
| **#314** | **alphonse** | embed_lr scan {0.2, 0.4} — never-scanned auxiliary AdamW token embedding LR | Arm A `tn1qni73` (embed_lr=0.2) at step 2250/3250 (~69%). Note: possible redundant second run `z2dgh3df` started 00:43 UTC — advised to kill redundant. |
| **#311** | **thorfinn** | Lookahead optimizer wrapper — online slow-weight interpolation α ∈ {0.5, 0.8} | SENT BACK for debugging — all 3 runs crashed at step 1-25 (grad_norm 200K+). Likely PMuon cold-start + Lookahead pullback interaction. Debugging guidance posted. |
| **#305** | **frieren** | AdEMAMix dual-EMA aux AdamW: slow-EMA mixing weight α scan {4, 8} | Active WIP. |
| **#307** | **tanjiro** | PMuon EMA bias correction {FULL, SQRT} | FULL arm `65j1vtqu` FINISHED sr=3050, val=3.2679 — NULL (Δsr=+25). SQRT arm `fku3hg2s` just launched (step 0, 00:48 UTC). |
| **#299** | **edward** | Global gradient norm clipping {1.0, 0.5} | Arm B (clip=0.5) `bw20hjy6` at step 2725/3250 (~84%). Arm A (clip=1.0) crashed twice. |

## Recently closed

| PR | Student | Result | Decision |
|---|---|---|---|
| **#287** | askeladd | Muon WD scan {0.035, 0.050}: Arm A sr=3050 val=3.2678 NULL (Δsr=+25, Δval=+0.00161); Arm B sr=3125 val=3.2721 NULL/REGRESSION. Monotone wrong direction. Mechanism confirmed at telemetry level (higher WD → lower param_norm, higher u/p ratio) but downstream improvement absent. | CLOSED — Muon WD axis CLOSED at 0.025 from upper side. |
| **#293** | nezuko | Polyak averaging: Arm A `igfcn9a1` (POLYAK_FRAC=0.25) FINISHED with **sr=3075 val=3.2749** (Δsr=+50, Δval=+0.00875 = 9× noise floor — both clearly worse). Arm B (POLYAK_FRAC=0.50): 10 crash attempts over 5h, latest `8aotxat7` at step 150. | CLOSED — Polyak axis CLOSED at 0 (no averaging). Mechanism counterproductive under power-law cooldown γ=1.2: late-phase params (post-cooldown) are much better than mid-phase params, so equal-weight averaging biases weights back toward earlier higher-LR (suboptimal) checkpoints. Arm B's wider window (50%) would amplify the regression. Polyak might still be valuable under no-cooldown or EMA-weighted variants, but those are different experiments. |
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

13. **Muon WD axis CLOSED at 0.025 (PR #287 askeladd).** Both arms NULL, monotone wrong direction (higher WD → strictly worse sr+25/+100 and val). Mechanism confirmed at telemetry level (higher WD tightly constrains param_norm, raises u/p ratio late) but downstream improvement absent — optimizer near optimum at 0.025. Do not scan {0.060, 0.080}. Downward {0.015, 0.020} is low-priority. Askeladd re-assigned to PR #327 (Adan-on-aux).

15. **AdEMAMix dual-EMA aux AdamW:** PR #305 frieren. Arm A (α=4) pending launch. Fresh optimizer mechanism, complementary to PMuon, targets aux path (embed/lm_head/scalars).

16. **PMuon EMA bias correction:** PR #307 tanjiro (new assignment). Arms {FULL, SQRT} bias correction `L_cov / (1-β_cov^step)` — frieren's PR #261 follow-up suggestion. Tests opposite hypothesis to closed LR warmup: instead of slowing LR during cold-start, sharpen the EMA estimate via Adam-style bias correction. Telemetry shows correction matters only first ~50 steps.

17. **Lookahead optimizer wrapper (PR #311 thorfinn).** Online slow-weight interpolation every k=5 steps with α ∈ {0.5, 0.8}. Fresh wrapper-level mechanism (Zhang Lucas Hinton Ba NeurIPS 2019). Memory cost ~550 MB (fp32 slow-weight copy). Primary diagnostic: `lookahead/embed_slow_fast_diff_ratio`.

18. **Polyak-Ruppert weight averaging axis CLOSED at 0 (PR #293 nezuko).** Arm A `igfcn9a1` (POLYAK_FRAC=0.25) FINISHED sr=3075 val=3.2749 — both clearly worse than baseline (Δsr=+50, Δval=+0.00875 = 9× n=1 noise floor). 10 crash attempts on Arm B (POLYAK_FRAC=0.50). Mechanism reading: under power-law cooldown γ=1.2, LR decays from 0.035 → 0 across the final 25% of steps, so trajectory is **non-stationary**. Late-phase (post-cooldown) params are much better than mid-phase params; equal-weight averaging biases weights back toward earlier higher-LR (suboptimal) checkpoints. Arm B's wider window (50%) would amplify, not reverse, the regression. Back-burner: EMA-weighted Polyak (γ-decaying weight toward newer steps) or Polyak-without-cooldown — different mechanisms.

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

- **embed_lr scan {0.2, 0.4}** — alphonse PR #314 IN FLIGHT
- **Lion optimizer on embed path** — nezuko PR #317 IN FLIGHT. Sign-momentum, lr ∈ {0.03, 0.10}
- **Adan optimizer on aux AdamW** — askeladd PR #327 IN FLIGHT. 3-buffer adaptive Nesterov, lr_mult ∈ {1.0, 0.33}
- **COOLDOWN_POWER=1.4** — fern PR #274 IN FLIGHT, seed-2 confirming potential sr=3000 WIN
- scalar_lr scan — never tested (current 0.01)
- lm_head_lr scan — never tested (current 1/320)
- EMA-weighted Polyak (γ-decay weight toward newer steps) — back-burner from PR #293 closure
- Schedule-free optimizers (Defazio 2024) — fresh mechanism, no-warmup/no-cooldown variant
- Sophia-G/H (Liu et al. 2023) — second-order diagonal Hessian for aux AdamW — back-burner (implementation complexity)
- Lookahead + grad-clip fix — thorfinn PR #311 SENT BACK for debugging; follow-up once crash is fixed

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3025, val=3.26615 (n=1, PR #202).**
n=1 win threshold: sr < 3025 OR (sr=3025 AND val < 3.26615).
Stat-sig threshold n=1: val ≤ 3.276. n=2: val ≤ 3.277.
