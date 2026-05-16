# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-16 16:35 UTC — PR #151 alphonse Aurora pre-polar NULL closed; PR #150 fern Cautious NEGATIVE closed (+silent-fail duplicate flagged); PR #168 (fern cosine cooldown) and PR #169 (alphonse per-head polar) assigned; askeladd 0p45 done sr=3150 val=3.2716 NULL (moving to 0.30 arm); null tally now at 11 add-on/scalar nulls; **plateau watch CONFIRMED — Wave 5 pivot active**
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3100 steps; public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3100 steps, val/loss 3.267696 (n=2 mean)** — PR #94 (g1r1-askeladd, PMuon + Skylight u/w-floor, TARGET_UW=0.35).
W&B runs: `yeyewcj6` (n=1) + `205sycku` (n=2 confirm). Merged 2026-05-16.

n=2 stat-sig margin: (3.28 − 3.267696)·√2 = 0.01740 ✓

**Key property:** u/w-floor fires at 100% of eligible params every step — the floor acts as a universal update magnitude multiplier, not a targeted safety catch.

## 🔥 POTENTIAL WINNER: PR #137 nezuko — seed-2 running, ETA ~17:15 UTC

**W&B run `8quuvdrj` (γ=1.2 power-law cooldown on PMuon+u/w-floor, n=1):**
- `speedrun/final_first_step_to_target`: **3075** (25 better than baseline) ✅
- val/loss at step 3250: **3.270012** (+0.00232 vs baseline, within 0.004)
- n=1 stat-sig vs 3.28: 0.00999 > 0.004 ✓

**Seed-2 `l5bdkm6e`:** step ~2250/3250 (69%), val 3.39, ETA ~17:15 UTC. This is the critical n=2 confirmation for the only improvement direction we have on this base.

**Merge gate:** (3.28 − μ) × √2 ≥ 0.004 ⇒ μ ≤ 3.2772. Plenty of margin if seed-2 lands around 3.270 like seed-1.

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                                              | Status (16:35 UTC) |
| --- | ----------- | --------------------------------------------------------------------- | ------ |
| **#137** | **nezuko** | + γ=1.2 power-law cooldown (seed-2 n=2 confirmation)              | `l5bdkm6e` step ~2250/3250 (69%), ETA ~17:15 UTC |
| #167 | tanjiro    | + SOAP on attention q/k/v only (spectral-skew hypothesis)            | `sb4u7xhb` step ~0/3250 (picked up, just starting) |
| #158 | edward     | + Depth-wise per-block LR decay (LLRD, arm A=0.85, arm B=0.90)       | arm A `8v3v2l4h` step 2350/3250 (72%), ETA ~17:15 UTC |
| #143 | thorfinn   | + Lookahead outer optimizer (arm A k=5 NULL; arm B k=10 running)     | arm B `i4eb7s2p` step 630/3250 (19%), ETA ~19:30 UTC |
| #129 | frieren    | + PMuon β_cov scan (arm A 0.90, arm B 0.95 DONE NULL; arm C 0.99)    | arm C `rnq53ele` step 1750/3250 (54%), ETA ~17:45 UTC |
| #131 | askeladd   | + TARGET_UW sweep {0.25, 0.30, 0.40 DONE, 0.45 DONE}                 | arm 0.30 `dkxweoah` just started, then 0.25 |
| **#168** | **fern**    | + **Cosine cooldown shape** (Wave 5 — schedule shape probe)         | just assigned, awaiting pickup |
| **#169** | **alphonse**| + **Per-head polar projection on attention q/k/v** (Wave 5 — structural polar) | just assigned, awaiting pickup |

## Closed this session

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| #151 | alphonse | Aurora pre-polar: sr=3125 val=3.269743 | NULL — pre-polar slot saturated by PMuon whitening; → PR #169 per-head polar |
| #150 | fern     | Cautious sign-mask: sr=−1 val=3.2938 (never crossed) + silent-fail duplicate | NEGATIVE — sign-mask destroys whitening; → PR #168 cosine cooldown |
| #140 | tanjiro  | SOAP-MLP+u/w stack: sr=3125 val=3.2698 (post_to_pre_ratio≈1.0 confirms direction-rotation null) | NULL → PR #167 SOAP-ATTENTION |
| #143 arm A | thorfinn | Lookahead k=5: never crossed 3.28, val=3.2836 | NULL (arm B k=10 running) |
| #118 | edward  | cooldown_frac scan {0.5, 0.8}: both sr=3150-3175 val>baseline | NULL → PR #158 LLRD |
| #93 | fern     | NorMuon row-wise: sr=3175 val=3.2757 | NULL → previously |
| #119 | alphonse | Contra-Muon × PMuon: 4 arms, never converged | NEGATIVE (incompatibility) |
| #110 | thorfinn | γ-scan: arm A 0.25, arm B 0.35 both sr=3150 | NULL (γ=0.30 optimal) |
| #83 | tanjiro  | SOAP-MLP on bare PMuon | NULL → PR #140 stack attempt |
| #94 | askeladd | u/w-floor n=2: sr=3100 val=3.267696 | **MERGED — current baseline** |
| #85 | nezuko   | Power-law γ=1.2 on bare PMuon n=2 | Closed (loses to baseline after u/w-floor merge) |

## Plateau watch — CONFIRMED 

**Cross-cutting null/negative tally on PMuon+u/w-floor base: 11 (10 post-polar/pre-polar/structural; 2 NEGATIVE):**

1. PR #83 SOAP-MLP on bare PMuon → NULL
2. PR #93 NorMuon row-wise → NULL  
3. PR #110 γ-scan ±0.05 → NULL
4. PR #118 cooldown_frac scan ±0.1 → NULL
5. PR #119 Contra-Muon × PMuon → NEGATIVE (incompatibility)
6. PR #129 arm B bcov=0.95 → NULL (3rd seed of baseline)
7. PR #140 SOAP-MLP+u/w stack → NULL
8. PR #143 arm A lookahead k=5 → NULL (never crossed)
9. PR #150 fern Cautious sign-mask → NEGATIVE (never crossed)
10. PR #151 alphonse Aurora pre-polar → NULL
11. PR #131 askeladd TARGET_UW=0.40 → NULL (sr=3150 val=3.2772)
12. PR #131 askeladd TARGET_UW=0.45 → NULL (sr=3150 val=3.2716)

**Only PR #137 power-law cooldown γ=1.2 (n=1 sr=3075) shows improvement.** That's a SCHEDULE-SHAPE change, not an optimizer-mechanism addition. n=2 pending.

### Plateau interpretation: PMuon's bilateral whitening occupies both the pre-polar AND post-polar shaping slots completely

Evidence:
- Post-polar slot saturated (PRs #83, #93, #110, #129B, #140, #143A, #150). Any mechanism that rotates, sign-masks, EMA-smooths, or eigenbasis-preconditions the polar output is null or negative.
- Pre-polar slot saturated (PR #151 Aurora). Pre-polar row-norm equilibration is redundant with bilateral covariance eigenvalue inversion.
- Scalar tweaks within the same mechanism family saturated (PRs #110 γ, #118 cooldown_frac, #131 TARGET_UW 0.40/0.45). The current hyperparameter point is at a local optimum.
- Outer-loop saturated (PR #143A lookahead k=5). Periodic pullback to slow weights counterproductively dampens PMuon+u/w-floor's effective magnitude.

### Wave 5 pivot — categorically different probes now active

**Schedule-shape (currently the only proven improvement direction):**
- PR #137 γ=1.2 power-law (n=2 pending) — front-loaded decay
- **PR #168 fern cosine cooldown (NEW)** — s-shape, back-loaded decay; mechanistically distinct from γ=1.2

**Structural polar (untouched until now):**
- **PR #169 alphonse per-head polar on attention q/k/v (NEW)** — changes the structural unit of NS itself, not what wraps it. First test of "polar should respect multi-head architecture."

**Spectrum-restricted preconditioning (untouched until now):**
- PR #167 tanjiro SOAP-ATTENTION (running) — SOAP only on attention q/k/v (different singular value spectra than MLPs)

**Magnitude direction-orthogonal probes still in-flight:**
- PR #158 edward LLRD (depth-indexed LR multiplier — magnitude change orthogonal to PMuon's whitening)

**β_cov sensitivity remaining:**
- PR #129 frieren arm C bcov=0.99 (last point of sensitivity scan)

**Remaining TARGET_UW arms:**
- PR #131 askeladd 0.30 (starting), 0.25 (after) — for full sweep

### Wave 5 hypotheses pending (if current wave nulls out)

1. **NS quintic coefficient scan** — Skylight uses different a,b,c from current (2, -1.5, 0.5). Untouched mechanism in NS itself.
2. **NS iteration count scan** — currently 12; literature varies 6-18. Untouched.
3. **Sophia diagonal Hessian** — replaces NS polar with Hutchinson Hessian preconditioning. Different optimizer family.
4. **WSD schedule (warmup-stable-decay) ratio change** — restructure stable vs cooldown allocation.
5. **NorMuon long-axis variant** — Skylight uses long-axis NorMuon; we've only tested short-axis. Different normalization direction.
6. **SOAP-attn trust gate (Trustlight)** — record #16 mechanism, trust-gated eigenbasis adaptation. Different SOAP variant.

## Key cross-cutting issues

1. **`sample_tensor` linspace bug** — FIXED in PR #64 merge.
2. **Inductor compile bug** — KNOWN, `dynamic=True` workaround for vanilla PMuon.
3. **Contra-Muon × PMuon fundamental incompatibility** — CLOSED in PR #119.
4. **Cautious × PMuon incompatibility** — CLOSED in PR #150 (sign-mask destroys whitening signal).
5. **Aurora × PMuon redundancy** — CLOSED in PR #151 (pre-polar equilibration overlaps with bilateral whitening).
6. **u/w-floor fires universally** — couples β_cov, TARGET_UW, γ as a system.
7. **Silent-fail rate-limit pattern — TWO modes** (resolved by W&B-first audit):
   - **Duplicate-launch:** advised students to add `pgrep -f train_gpt_simple` guard (still hitting fern PR #150 today). Need to push this defensive guard more aggressively.
   - **False-stale-wip:** pod's poller hits 403 → "No assigned PRs" → silent sleep. Survey heuristic flags PR, but training may be active. Audit: check W&B before nudging.
8. **SOAP-MLP null mechanism confirmed** — `post_to_pre_ratio≈1.0` + `amp_cap_fire_fraction=0.000` (PR #140). SOAP-ATTENTION (PR #167) tests whether attention's different spectrum changes this.
9. **Power-law cooldown wins on schedule shape** — PR #137 n=1 result pending n=2.

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004` required for final claims. **Current baseline is sr=3100, val=3.267696** (n=2 PR #94). Anything within 0.004 of 3.267696 at n=1 needs n=2 confirmation before merge.
