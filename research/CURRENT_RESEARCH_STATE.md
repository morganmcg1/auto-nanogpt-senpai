# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-17 13:15 UTC — PR #225 CLOSED (Wave 7 stack NULL on n=2: mean sr=3037.5 vs baseline 3025, mean val=3.266425 vs baseline 3.26615 — within noise). PR #272 assigned thorfinn (AdamW eps scan {1e-8, 1e-9}, never tested 100× deviation from default). PR #250 tanjiro arm A FINISHED sr=3100 val=3.273 — student SENPAI-RESULT pending. PR #231 fern mu=0.99 diverging — early-kill comment posted. 8 students WIP.
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 3025 steps; public record is 3030 steps (Record #20). **WE ARE BEATING RECORD #20 (local n=1 sr=3025 < 3030).**

## Current local baseline

**sr=3025, val/loss 3.26615 (n=1)** — PR #202 (g1r1-frieren, γ_power=0.4 on cubic-Newton+PMuon+u/w-floor+γ=1.2 base).
W&B run: `prncgzv5`

Previous baselines:
- PR #193 (cubic-Newton): sr=3050, val=3.26773 (n=1)
- PR #137 (PMuon+u/w+γ=1.2): sr=3062.5, val=3.26909 (n=2)

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                           | Status (13:15 UTC) |
| --- | ----------- | ------------------------------------------------------------------- | ------------------ |
| **#272** | **thorfinn** | AdamW eps scan {1e-8, 1e-9} — never-scanned 100× deviation from default | Just assigned |
| **#261** | **frieren** | PMuon LR warmup scan {50, 150 steps} — fresh mechanism | Arm A `2sjpvck2` (warmup 50) step ~575 val=3.81 — running. 1 prior step-0 fail. |
| **#258** | **nezuko** | Skylight u/w-floor ablation: TARGET_UW ∈ {0.0, 0.7} | Arm A `yrvf83c0` (TARGET_UW=0.0) step 1925 (~59%). Arm B pending. |
| **#250** | **tanjiro** | NS coef c-scan on f'(1)=0 family: c ∈ {-0.25, +0.25} | Arm A `ecwyk0ej` (c=-0.25) FINISHED sr=3100 val=3.273 NULL. Arm B `qkxe6okw` FAILED step 1. Awaiting terminal SENPAI-RESULT. |
| **#248** | **askeladd** | Muon base LR retune {0.030, 0.040} | Arm A `dcm490bd` (lr=0.030) DONE sr=3025 val=3.2676 NULL. Arm B `wsze97nl` (lr=0.040) step 550 val=3.82 — running. |
| **#231** | **fern** | Muon mu scan {0.9, 0.99} | Arm A DONE sr=3125 NULL. Arm B `axf513rf` (mu=0.99) step 1725 val=5.0 DIVERGING — advisor comment recommending early-kill. |
| **#230** | **edward** | Aux AdamW β1 scan {0.7, 0.9} | Arm A `j4nfypgf` DONE sr=3050 val=3.2678 (NULL on stale pre-#202 base). Arm B `zu55900j` (β1=0.9) step 1375 (~42%) val=3.58 — running. |
| **#229** | **alphonse** | NS coef (a,b) line scan {a=1.3, 1.7} | Arm A DONE sr=3075 NULL. Arm B `xphiroo2` (a=1.7) step 2375 (~73%) val=3.37 — running. |

## Recently closed

| PR | Student | Result | Decision |
|---|---|---|---|
| **#225** | thorfinn | Wave 7 (deep-WD + lm_head 1/160) n=2: mean sr=3037.5 (+12.5), mean val=3.266425 (+0.00028) | CLOSED — NULL on both axes; γ_power=0.4 already absorbs the regularization gain |
| **#242** | frieren | Arm A (γ=0.5) sr=3150 NULL. Arm B (γ=0.6) 3 crashes. | CLOSED — γ_power axis CLOSED at 0.4 (local optimum) |
| **#216** | nezuko | β2=0.99 sr=3025 val=3.26640 NULL; β2=0.999 sr=3100 regression | CLOSED — β2 axis CLOSED: β2=0.95 optimal |
| **#226** | tanjiro | Arm A sr=3050 NULL; arm B crashed step 3 (structural: a+b+c≠1) | CLOSED — structural finding → follow-up PR #250 |
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

3. **NS coef family: f'(1)=0 constraint required.** Valid family: (a,b,c) = (1.5+c, -0.5-2c, c). c=0 cubic-Newton is baseline best. c-scan {-0.25, +0.25} pending (PR #250 — arm B c=+0.25 failed step 1 despite valid constraint; may have separate stability issue).

4. **Aux AdamW β2 axis CLOSED at 0.95.** Monotone: smaller β2 better.

5. **Aux AdamW β1 axis: β1=0.7 arm A finished NULL (stale base). β1=0.9 arm B just started.** Current β1=0.8 baseline. Both arms will be reviewed together.

6. **Muon mu: baseline mu=0.95 locally optimal.** mu=0.9 worse (sr=3125). mu=0.99 arm pending.

7. **Deep-WD + lm_head LR 1/160 compound test (Wave 7):** PR #225 thorfinn seed 1 val=3.26513 sr=3025 (marginal val win). n=2 seed 2 finishing ~12:55 UTC. KEY RESULT — if n=2 confirms, this is a merge candidate.

8. **Muon base LR retune:** arm A (lr=0.030) at 82%, finishing soon.

9. **u/w-floor ablation:** PR #258 nezuko arm A (TARGET_UW=0.0) at step 750.

10. **PMuon LR warmup:** PR #261 frieren just assigned. FRESH MECHANISM — never tested. Tests whether cold-start covariance EMA initialization needs LR gating.

11. **EMA weight averaging and schedule (γ_power, cf, COOLDOWN_POWER) CLOSED.**

## PMuon hyperparameter characterization

| Axis | Status | Best value | Best sr |
|---|---|---|---|
| **β_cov** (covariance horizon) | CLOSED (PR #129) | 0.95 | — |
| **γ_power** (whitening strength) | **CLOSED — optimum at 0.4** | 0.4 | **3025** |
| **NS_ITERS** (polar convergence) | CLOSED (PR #184) | Wide flat: 6–18 | — |
| **NS_coef c-axis** (f'(1)=0 family) | ACTIVE c-scan (PR #250) | c=0 cubic-Newton | 3025 |
| **NS_coef (a,b) line** | ACTIVE (PR #229) | c=0, a=1.5 baseline; a=1.3 NULL | — |
| **Muon base LR** | ACTIVE retune (PR #248) | 0.035 (testing 0.030/0.040) | — |
| **mu** (gradient momentum) | ACTIVE (PR #231) | 0.95 baseline; mu=0.9 NULL | — |
| **TARGET_UW** (Skylight floor) | ACTIVE ablation (PR #258) | 0.35 (testing 0.0/0.7) | — |
| **Muon LR warmup** | ACTIVE mechanism (PR #261) | None (new axis) | — |

## Auxiliary optimizer (AdamW) — exploration in progress

| PR | Axis | Arm A result | Status |
|---|---|---|---|
| PR #230 (edward) | Aux β1 {0.7, 0.9} | β1=0.7 DONE sr=3050 val=3.2678 NULL (stale base) | Arm B (β1=0.9) running |
| PR #216 (nezuko) CLOSED | Aux β2 {0.99, 0.999} | β2=0.99: sr=3025 val=3.26640 NULL | CLOSED — β2=0.95 optimal |

## Open axes (not yet assigned)

- AdamW eps scan {1e-8, 1e-9} — never tested (current 1e-10 is 100× aggressive vs default)
- COOLDOWN_POWER retune on γ_power=0.4 stack — last tested on old base (now stale)
- embed_lr scan {0.2, 0.4} — never tested (current 0.3)
- scalar_lr scan — never tested (current 0.01)
- z-loss auxiliary — never tested; speculative

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004`. **Current baseline: sr=3025, val=3.26615 (n=1, PR #202).**
n=1 win threshold: sr < 3025 OR (sr=3025 AND val < 3.26615).
Stat-sig threshold n=1: val ≤ 3.276. n=2: val ≤ 3.277.
