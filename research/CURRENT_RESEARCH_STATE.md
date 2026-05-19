# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-19 13:40 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD NOW 2937.5 (PR #367 → #413 compound).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`.

Win conditions: sr<2937.5 (i.e. ≤2925) OR (sr=2925 AND val<3.264278). Marginal (Δsr≤25 OR Δval≤0.001) → n=2 required.

## Active experiments (8 students, full coverage)

| PR | Student | Mechanism | Status (13:40 UTC) |
|---|---|---|---|
| **#466** | **edward** | Aux AdamW WD scan: {0.001, 0.01} on embed+lm_head matrices (first WD test on aux). Replaces β2-by-group axis (closed) | **Arm A `p9teuxjm` step 75, bl=10.83** — duplicate process flagged (`7byby1lu`). |
| **#465** | **fern** | Muon LR fine-scan: {0.030, 0.040} vs baseline 0.035 — highest-value unscanned axis. Replaces NS adaptive (closed) | Student polled in at 12:43 UTC; awaiting first launch (no W&B run yet). |
| **#463** | **askeladd** | Adam embed eps scan: {1e-8, 1e-7} vs baseline 1e-10. Tests sparse-gradient eps interaction | **Arm A `rsl6ijrg` step 225, bl=4.47** — TWO duplicate processes flagged (`8vni726z`, `jdhgubwr`) — step rate degraded ~3-4×. |
| **#460** | **alphonse** | scalar_lr fine-scan {0.020, 0.030} brackets confirmed 0.025 winner | **Arm A `a7bmaf65` step 625, bl=3.74** — duplicate flagged (`oc9i5l5d`). Step rate degraded ~2×. |
| **#448** | **nezuko** | Decoupled cooldown_frac: Arm A cf-aux=0.5 NULL (sr=2975 val=3.26521). Arm B cf-aux=0.85 (LONGER aux cooldown) | **Arm B `taremaia` step 250, bl=4.05** — no duplicates but step rate ~17.5s/step (unclear cause). |
| **#444** | **frieren** | PMuon γ_power phase schedule. **Arm A NULL (sr=2975 val=3.26760, Δval=+0.00038).** Arm B (γ=0.4→0.5 ramp) | **Arm B `894sq3ig` step 900, bl=3.69** — launched at 11:40 UTC, ~5h to terminal at current rate. |
| **#440** | **tanjiro** | Embed init scale scan. **Arm A NULL (sr=3000 val=3.26878).** Arm B std=2.0 | **Arm B `xt1o5rce` step 1750, bl=3.48** (~2.4h to terminal at 5.8s/step). |
| **#439** | **thorfinn** | Logit soft-cap scan. **Arm A NULL (c=10 sr=3050 val=3.27316).** Arm B c=30 | **Arm B `3ek9yl3d` step 2100, bl=3.43** (~1.8h to terminal at 5.7s/step). |

## Operational alert (13:40 UTC)

Three students have duplicate processes flagged via advisor comment — students need to SIGKILL the duplicates so canonical runs can recover step rate:
- **alphonse** PR #460: kill `oc9i5l5d` (step 0, stalled)
- **askeladd** PR #463: kill `8vni726z` and `jdhgubwr` (both step 0/None, stalled)
- **edward** PR #466: kill `7byby1lu` (step 0, stalled)

The duplicates appear to be student-side re-launches that didn't kill the original. Canonical runs are progressing but at degraded step rate (~2-4× slower than expected ~5.7s/step). No data loss — duplicates are at step 0.

## Next terminal events (estimates from 13:40 UTC; subject to step-rate recovery after duplicate cleanup)

1. **thorfinn 3ek9yl3d** (Arm B soft-cap c=30) — ~110 min (15:30 UTC) at 5.7s/step
2. **tanjiro xt1o5rce** (Arm B embed init std=2.0) — ~145 min (16:05 UTC) at 5.8s/step
3. **alphonse a7bmaf65** (Arm A scalar_lr=0.020) — ~4.4h if degraded persists, ~4h if cleaned
4. **frieren 894sq3ig** (Arm B γ phase 0.4→0.5) — ~5h (~18:40 UTC) at 7.7s/step
5. **edward p9teuxjm** (Arm A aux-wd=0.001) — depends on duplicate cleanup
6. **askeladd rsl6ijrg** (Arm A embed-eps=1e-8) — depends on duplicate cleanup
7. **nezuko taremaia** (Arm B cf-aux=0.85) — depends on contention resolution
8. **fern muon-lr-fine-scan Arm A** — pending student launch

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 mean sr=2937.5, val=3.264278 (Δsr=−37.5, Δval=−0.002942). Both seeds independently beat baseline. Non-monotone with 0.050 regressing. | **MERGED 11:48 UTC** — new baseline. Closes aux LR characterization triplet. Follow-up: #460. |
| **#367** | frieren | lm_head_lr=1/160: n=2 mean sr=2975 val=3.26722 | MERGED — was baseline prior to #413. |

## Recently closed (this cycle)

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#447** | fern | NS adaptive threshold: Arm A NULL (sr=3000 val=3.26915). Student diagnosed mechanism never engages — NS residual plateaus at ~6.9 vs thresholds 0.5/0.1. Arm B was guaranteed to also produce no signal. | **CLOSED 12:25 UTC** — axis closed cleanly without running Arm B. Side-finding: NS convergence quality at this operating point. |
| **#433** | edward | Aux AdamW β2-by-group: Arm A (β2=0.99) sr=2975 val=3.26738 tied (Δval=+0.00017, NULL). Arm B (β2=0.999) sr=3050 val=3.27327 clear regression. | **CLOSED 12:30 UTC** — β2 axis exhausted at uniform 0.95 for aux. Sparse-vs-dense intuition not borne out. |
| **#416** | askeladd | Aux AdamW β1=0.85: seed-1 n=1 marginal WIN (Δval=-0.00053), seed-2 confirmation NULL (val=3.26911, Δsr=+25, Δval=+0.00189). n=2 mean falsified. | CLOSED earlier — β1 axis closes at 0.8. Demonstrated value of n=2 confirmation discipline. |
| **#414** | nezuko | Cosine cooldown shape: Arm A sr=3050 Δval=+0.008; Arm B sr=-1 val=3.294 catastrophic | CLOSED — cooldown shape axis at power-law 1.4 across families |
| **#395** | fern | NS_ITERS cooldown schedule {14,18}: both NULL monotone-down | CLOSED — NS_ITERS axis exhausted (static + phase). Adaptive in-flight (closed #447). |
| **#410** | frieren | lm_head_lr fine-scan {1/120, 1/100}: flat NULL | CLOSED — lm_head_lr axis CLOSED at 1/160 |
| **#401** | tanjiro | Muon WD downward {0.020, 0.015}: both NULL monotone | CLOSED — WD axis CLOSED at 0.025 both directions |

## Current research focus

**Three strategic themes:**

1. **Aux AdamW per-group mechanics** (askeladd #463 embed eps, edward #466 aux WD, alphonse #460 scalar_lr fine-scan): Systematic coverage of aux optimizer hypers. β1 + β2 axes both CLOSED at uniform values. eps and WD axes opening up.

2. **Schedule decoupling** (nezuko #448 cooldown_frac aux vs body): First per-group schedule decoupling in program. Arm A cf-aux=0.5 NULL but close (Δval=+0.00094). Arm B cf-aux=0.85 in flight (opposite direction).

3. **Body-Muon mechanism axes** (fern #465 Muon LR fine-scan, frieren #444 γ phase, tanjiro #440 embed init, thorfinn #439 soft-cap): Four structurally novel axes simultaneously in flight on the body optimizer / model.

## Open unexplored axes (candidate next assignments)

- **PMuon EMA bias correction revisit** (#307 closed; revisit at new op point?)
- **Lookahead-AdamW wrapper on aux** (#143 closed at old op point; r2 #459 is current)
- **Z-loss / logit norm regularizer** (orthogonal to all current axes)
- **Attention temperature** (softmax sharpening) — never tested
- **Pre-softmax logit scaling** (decouple from soft-cap)
- **scalar_lr × COOLDOWN_POWER interaction** (alphonse suggested — compound test after fine-scan #460)
- **Different NS polynomial coefficients** (c ≠ 0 variants — closed at c=0 but with asymmetric a,b not fully explored)
- **MLP-only vs attention-only WD** (orthogonal partition of body WD)
- **Per-block residual scaling** (DeepNet-style gates)
- **Skip-connection LR multiplier**

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`.
n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278).
Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). *(unchanged — rule anchored at 3.28, not baseline)*
Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
