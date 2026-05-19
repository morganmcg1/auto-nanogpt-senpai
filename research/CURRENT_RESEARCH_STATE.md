# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-19 11:55 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD NOW 2937.5 (PR #367 → #413 compound).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`.

Win conditions: sr<2937.5 (i.e. ≤2925) OR (sr=2925 AND val<3.264278). Marginal (Δsr≤25 OR Δval≤0.001) → n=2 required.

## Active experiments (8 students)

| PR | Student | Mechanism | Status (11:55 UTC) |
|---|---|---|---|
| **#460** | **alphonse** | scalar_lr fine-scan {0.020, 0.030} — brackets the confirmed 0.025 winner (predeclared follow-up from #413). Peak localization | Just assigned (11:52 UTC). Arm A to launch. |
| **#448** | **nezuko** | Decoupled cooldown_frac: aux groups vs body Muon. Arm A aux cf=0.5, Arm B aux cf=0.85. First per-group schedule decoupling | **Arm A `0a9r5lof` step 2750, bl=3.302** (~38 min to terminal). |
| **#447** | **fern** | NS polar adaptive convergence threshold: data-dependent iter count. Arm A threshold=0.5, Arm B threshold=0.1 | **Arm A `7logfkqq` step 2725, bl=3.320** (~39 min to terminal). |
| **#444** | **frieren** | PMuon γ_power phase schedule. **Arm A FINISHED NULL (sr=2975 val=3.26760, Δval=+0.00038).** Advisor comment posted for Arm B launch | Arm B (γ=0.4→0.5 ramp) pending student launch. |
| **#440** | **tanjiro** | Embed init scale scan. **Arm A NULL (sr=3000 val=3.26878).** Advisor comment posted for Arm B launch | **Arm B `xt1o5rce` step 825, bl=3.750** (~3.1h to terminal). |
| **#439** | **thorfinn** | Logit soft-cap scan. **Arm A NULL (c=10 sr=3050 val=3.27316).** | **Arm B `3ek9yl3d` step 1225, bl=3.665** (~2.8h to terminal). |
| **#433** | **edward** | Aux AdamW β2 by group: embed+lm_head {0.99, 0.999} vs scalars 0.95. **Arm A (β2=0.99) TIED baseline (sr=2975 val=3.26738 Δval=+0.00016 NULL).** | **Arm B `2qoyvxmz` step 2750, bl=3.309** (~38 min to terminal). |
| **#416** | **askeladd** | Aux AdamW β1 fine-scan {0.75, 0.85}. **Arm B (β1=0.85) seed-1 val=3.26669 (Δval=−0.00053 — marginal WIN). n=2 confirmation in flight.** | **seed-2 `k7u7pfy5` step 2875, bl=3.290** (~28 min to terminal). |

## Next terminal events (estimates from 11:55 UTC)

1. **askeladd k7u7pfy5** (seed-2 β1=0.85 confirmation) — ~28 min (12:23 UTC)
2. **edward 2qoyvxmz** (Arm B β2=0.999) — ~38 min (12:33 UTC)
3. **nezuko 0a9r5lof** (Arm A cooldown_frac decoupled) — ~38 min (12:33 UTC)
4. **fern 7logfkqq** (Arm A NS adaptive) — ~39 min (12:34 UTC)
5. **tanjiro xt1o5rce** (Arm B embed init 2.0) — ~3.1h (15:05 UTC)
6. **thorfinn 3ek9yl3d** (Arm B soft-cap c=30) — ~2.8h (14:45 UTC)

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 mean sr=2937.5, val=3.264278 (Δsr=−37.5, Δval=−0.002942). Both seeds independently beat baseline. Non-monotone with 0.050 regressing. | **MERGED 11:48 UTC** — new baseline. Closes aux LR characterization triplet. Follow-up: #460. |
| **#367** | frieren | lm_head_lr=1/160: n=2 mean sr=2975 val=3.26722 | MERGED — was baseline prior to #413. |

## Recently closed

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#414** | nezuko | Cosine cooldown shape: Arm A sr=3050 Δval=+0.008; Arm B sr=-1 val=3.294 catastrophic | CLOSED — cooldown shape axis at power-law 1.4 across families |
| **#395** | fern | NS_ITERS cooldown schedule {14,18}: both NULL monotone-down | CLOSED — NS_ITERS axis exhausted (static + phase). Adaptive in-flight #447. |
| **#410** | frieren | lm_head_lr fine-scan {1/120, 1/100}: flat NULL | CLOSED — lm_head_lr axis CLOSED at 1/160 |
| **#401** | tanjiro | Muon WD downward {0.020, 0.015}: both NULL monotone | CLOSED — WD axis CLOSED at 0.025 both directions |

## Current research focus

**Three strategic themes:**

1. **Aux AdamW per-group mechanics** (askeladd #416 β1, edward #433 β2, alphonse #460 scalar_lr fine-scan): Systematic coverage of aux optimizer hypers. β1=0.85 is a marginal n=1 WIN awaiting n=2 confirmation.

2. **Schedule decoupling** (nezuko #448 cooldown_frac aux vs body): First per-group schedule decoupling in program. Arm A (aux shorter cooldown) in flight.

3. **Fresh mechanism classes** (fern #447 adaptive NS, frieren #444 γ phase, tanjiro #440 embed init, thorfinn #439 soft-cap): Four structurally novel axes simultaneously in flight.

## Open unexplored axes (candidate next assignments)

- NS adaptive threshold follow-up (after fern #447 closes direction)
- PMuon γ_power phase ramp Arm B (frieren assigned, pending launch)
- Embed init Arm B std=2.0 (tanjiro assigned, running xt1o5rce)
- soft-cap c=30 Arm B (thorfinn assigned, running 3ek9yl3d)
- **Adam ε per-group** (embed/lm_head sparse vs scalars dense — never tested)
- **Muon LR fine-scan** (0.035 is long-standing; try {0.030, 0.038, 0.040})
- **β_cov fine-scan at new operating point** (closed at 0.95 on old stack; scalar_lr merge may shift optimum)
- **Inverse LLRD** (bottom layers HIGHER LR — contradicts ULMFiT but may hold for pretraining)
- **scalar_lr × COOLDOWN_POWER interaction** (alphonse suggested — compound test after fine-scan)
- **Different NS polynomial coefficients** (c ≠ 0 variants — closed at c=0 but with asymmetric a,b not fully explored)

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`.
n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278).
Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). *(unchanged — rule anchored at 3.28, not baseline)*
Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
