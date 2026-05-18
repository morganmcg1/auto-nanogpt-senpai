# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-18 00:22 UTC
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Statistical merge rule:** `(3.28 − μ) × √3 ≥ 0.004` AND n=3 mean ≤ current baseline
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate)

## Current merged baseline — post-#236

**val=3.27407 / fs=3258.3 (n=3 mean)**

Merged recipe:
```
NANOGPT_GRAD_CLIP=10.0
NANOGPT_NS_ITERS=12
NANOGPT_NS_ITERS_COOLDOWN=16
NANOGPT_NS_COOLDOWN_START_FRAC=0.7
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
NANOGPT_ADAMW_BETA2=0.99
```

Baseline commit: `d5aa8d3` (alphonse #236 merged 00:00 UTC 2026-05-18)

### Merged stack history

| PR | Change | val (n=3) | fs (n=3) | Cumulative baseline |
|----|--------|-----------|----------|---------------------|
| #60 | Muon² | 3.2766 | 3275 | 3.2766 |
| #105 | clip=5.0 | 3.27527 | 3266.7 | 3.27527 |
| #165 | clip=10.0 | 3.27474 | 3258.3 | 3.27474 |
| #176 | NS=12→16@70% | 3.27461 | 3266.7 | 3.27461 |
| #235 | embed linear_floor=15% | 3.27434 | 3266.7 | 3.27434 |
| **#236** | **AdamW β2=0.99** | **3.27407** | **3258.3** | **3.27407** ← CURRENT |

### Mechanism landscape

All six merges target different structural axes:
1. **Muon² v-EMA** (#60): second-moment before NS orthogonalization
2. **Grad clip** (#165): embed effective-LR raise (8.4% → 16.9%)  
3. **NS timing** (#176): more NS iters during precision-critical cooldown
4. **Embed LR floor** (#235): hold embed at 15% of peak through final 30% of training
5. **AdamW β2** (#236): longer second-moment memory (20 → 100 step) smooths step sizes in cooldown

These are largely orthogonal axes. Remaining stacking potential is high.

---

## Active experiments (wave 5–6) — 02:10 UTC status

### ⚡ fern #290 — NS per-iter coefficient schedule [TOP PRIORITY]
**Status:** Sent back for n=3 confirmation 00:12 UTC on post-#236 baseline. arm-D (linear_ramp_down, c=0.70→0.24) val=**3.27325**, which is Δ=−0.00082 BELOW the new baseline (3.27407) already from a single seed. Within-pod Δ=−0.00342 vs arm-A (strongest wave-5 signal observed).  
**Mechanism:** Ramping NS quintic coefficient c down from 0.70 to 0.24 across the 12 NS iterations concentrates aggressive orthogonalization early (when spectrum is far from identity) and gentles it late (when updates are near-optimal). Orthogonal to AdamW-side merges.  
**ETA:** ~3 seeds × ~1h45m = 5h25m from confirmation start. Confirmation chain must include `NANOGPT_ADAMW_BETA2=0.99`.  
**Gate:** n=3 mean val ≤ 3.27407 AND stat-sig ≥ 0.004.

### ⚡ thorfinn #279 — AdamW aux weight decay sweep [WINNER, SENT BACK FOR REBASE + 1 PROBE]
**Status:** Terminal n=3 mean **val=3.27346 / fs=3250.0** (seeds 523f65i3, grj9q69u, turhktxv). Δ=−0.00061 vs current baseline (3.27407). Stat-sig 0.01132 ≥ 0.004 ✓. Sent back 01:11 UTC for rebase + 1 compositional probe seed on post-#236 stack.  
**Mechanism:** AdamW aux WD=0.005 (baseline=0.0) provides moderate regularization on embed, lm_head, scalar. Embed Frobenius norm drops to 31% of unregularized. U-curve apex confirmed at WD=0.005 (arm-C WD=0.01 regresses to Δ=+0.00389). Independent of #235/#236 — student's confirmation stack missed both ingredients and still beat baseline.  
**Compositional prediction:** Full orthogonality → 3.27292. Partial → 3.27319. Subsumption → 3.27346 (still wins). Anti-correlation implausible (WD on weights vs β2 EMA vs embed LR shape — different math).  
**Probe decision rule:** seed ≤ 3.27400 → merge (n=4 evidence). 3.27400–3.27600 → n=2 more (3 total). >3.27600 → close.  
**ETA:** ~2h for probe seed after rebase.

### ✅ edward #280 — Per-aux-group AdamW β2 ablation [CLOSED mechanism-study 02:05 UTC]
**Verdict:** 4-arm chain complete. **SURPRISE: scalar (D) > embed (B) > lm_head (C)** — inverts pre-registration. Mechanism re-read: v-EMA collapse is driven by gradient SPARSITY, not magnitude. Scalar params (~10s total) are sparsest → most collapse-vulnerable at β2=0.95 → most gain from β2=0.99. Sub-additivity: sum Δs = −0.00781 vs global Δ = −0.00309 → 2.5× overlap. Closed as mechanism study; production recipe (#236 global β2=0.99) already incorporates the effect.  
**New insight propagates to:** per-group eps (#322 alphonse global; a per-group scalar eps follow-up may be valuable), per-group β1, per-group WD, per-group LR.  

### ⚡ edward [ASSIGNED 02:10 UTC] — Muon LR cooldown FLOOR sweep
**Branch:** `g1r4-edward/muon-lr-cooldown-floor`  
**Hypothesis:** PR #235 (embed linear_floor=15%) showed that maintaining LR at floor through the cooldown precision-critical window helps the embed group. Does the same mechanism apply to Muon blocks (currently linear-to-zero)? Add `NANOGPT_MUON_COOLDOWN_FLOOR` env var; sweep floor∈{0.00, 0.05, 0.10, 0.15}.  
**Mechanism basis:** NS=12→16 cooldown schedule (#176) already signals Muon updates want more precision at end-of-training; a LR floor could extend the effective window where NS=16 polishing has sufficient gradient pressure to converge.  
**Arms:** A=0.00 (control), B=0.05, C=0.10, D=0.15 (mirrors embed winner). Single-seed within-pod chain.  
**ETA:** ~7.5h total chain. Decision: within-pod Δ ≤ −0.002 → signal. −0.003 or better → n=3 confirmation.

### frieren #285 — NS cooldown SHAPE sweep [medium priority]
**Status:** Restarted at 00:14 UTC on post-#236 baseline with `NANOGPT_ADAMW_BETA2=0.99` after student aborted the stale chain. arm-D (late_peak shape) within-pod Δ=−0.00143 was 0.00007 short of −0.0015 threshold on the old recipe. Confirmation n=3 chain for arm-D now running fresh.  
**Mechanism:** NS iter shape (step vs graduated ramp vs late-peak) during cooldown. Late-peak concentrates NS=20 power at the final ~10% of training where optimizer must converge precisely.  
**ETA:** seed-1 ETA ~02:00 UTC, full chain ~02:00–08:00 UTC.  
**Gate:** n=3 mean val ≤ 3.27407. Previously within-pod Δ was marginal; fresh confirmation will clarify.

### ⚡ tanjiro #300 — Embed floor value sweep [SCREENING COMPLETE, n=3 CONFIRMATION RUNNING]
**Status:** 4-arm chain complete 02:50 UTC. Inverted-U with apex at floor=0.20 (arm-C). Within-pod Δ vs A = **−0.00159** (above signal threshold, marginal regime).  
**Screening table (pre-#236 stack, single seed)**:
- arm-B (floor=0.10): 3.27630 (Δ=+0.00189)
- arm-A (floor=0.15, control): 3.27441
- arm-C (floor=0.20): **3.27282** ✓ best
- arm-D (floor=0.30): 3.27549 (Δ=+0.00108)

**n=3 confirmation chain (post-#236 stack)**: launched ~02:50 UTC, ETA ~08:00 UTC. Tests whether the 0.20 floor signal holds when stacked with β2=0.99.  
**Merge gate**: n=3 mean ≤ 3.27407 AND stat-sig ≥ 0.004.

### alphonse #322 — AdamW ε sweep [medium priority]
**Status:** Newly assigned 00:05 UTC. Re-tunes ε after β2=0.99 shift: longer variance EMA may change optimal noise floor. Arms: {1e-10 (control), 1e-9, 1e-8, 1e-7}.  
**Mechanism:** With β2=0.99, variance estimate is 100-step EMA. The ε noise floor that prevents divide-by-zero may need upward adjustment since the EMA is smoother and less noisy. Or downward if the smoother EMA allows tighter conditioning.  
**ETA:** 4 arms × ~1h45m = 7h.

### nezuko #315 — lm_head steeper-decay cooldown shape [medium priority]
**Status:** Newly assigned. Tests whether lm_head (unlike embed) benefits from a *steeper* cooldown (quadratic/cubic/exp_decay vs linear). Hypothesis: lm_head has different dynamics than embed (lm_head is already clip-saturated at <0.4% eff-LR). A steeper decay might better match its convergence profile.  
**Note:** #266 (nezuko lm_head floor=15%) showed floor HURTS (Δ=+0.00295), falsifying that embed mechanism generalizes. This PR tests the inverse direction.  
**ETA:** 4 arms × ~1h45m = 7h.

### askeladd #324 — AdamW β1 sweep [fresh axis]  ← JUST ASSIGNED 00:22 UTC
**Status:** Just assigned. Parallel to merged β2=0.99 work: does first-moment EMA on aux groups also benefit from longer memory (β1=0.8 → 0.85/0.90/0.95)?  
**Mechanism:** β1 controls per-coordinate direction memory (~5-step at β1=0.8, ~10-step at β1=0.9, ~20-step at β1=0.95). Combined with β2=0.99 (smooth variance), longer β1 could give smoother gradient direction during cooldown. Standard Adam uses β1=0.9–0.95; β1=0.8 may be under-smoothing.  
**Implementation:** Add `NANOGPT_ADAMW_BETA1` env var, modify optimizer1 betas, log to W&B config.  
**Arms:** A=0.8 (control), B=0.85, C=0.90, D=0.95. Smoke arm-D (200 steps) before full sweep.  
**ETA:** ~7h total sweep + confirmation if needed.

---

## Recently closed

- **edward #280 (per-aux-group β2 ablation)** — mechanism study complete 02:05 UTC. Sparsity-driven mechanism identified (scalar > embed > lm_head, inverts pre-registration). No merge candidate (global β2=0.99 already merged via #236). Sub-additivity 2.5× confirms global β2=0.99 captures UNION of per-group effects.
- **askeladd #241 (Muon mu=0.97)** — productive-null close. Within-pod sweep showed clean inverted-U apex at mu=0.97 (Δ=−0.00289 on pre-#235 recipe). n=3 cross-pod confirmation on post-#236 baseline: mean=3.27525, Δ=+0.00118 above gate. Mechanism may partially substitute with β2=0.99. **Key lesson**: cross-pod n=3 chains have noise floor ~0.0015 stdev — within-pod signals <0.003 may not survive. Future confirmations for marginal signals should use within-pod paired design.

---

## Potential next research directions (after wave-5 confirmations)

### High-priority fresh axes
1. **Muon LR cooldown floor** — ✅ ASSIGNED to edward (branch: `g1r4-edward/muon-lr-cooldown-floor`). Mirror of embed-floor but for Muon blocks.
2. **Per-group AdamW eps (scalar-focused)** — edward #280 sparsity finding points here. alphonse #322 probes global eps; per-group scalar eps is the mechanism-validated follow-up. Assign after #322 terminals.
3. **AdEMAMix on aux groups** — triple-EMA: fast β1, slow β3~0.9999, mixing α. Published transformer-LM gains. Adds long-memory momentum leg complementary to β2 (variance smoothing). Compute overhead: one extra EMA buffer per aux param. (g1r1-frieren #305 is testing this on r1 branch.)
4. **Joint β1 × β2 surface** (2×2: β1∈{0.8,0.9} × β2∈{0.95,0.99}) — pending askeladd #324 β1 sweep result.
5. **Per-group Muon mu** — edward-style ablation on Muon mu per block type. (After Muon-floor experiment closes.)

### Medium-priority axes
5. **mu cooldown schedule** — late-training mu↑ during cooldown (complement to constant mu=#241 null). Student-suggested in #241 close.
6. **Embed floor × Muon floor combined** — stack both once individual confirmation lands.
7. **NS coefficient learning** — parameterize NS quintic {a,b,c} as learnable scalars with meta-gradient (DARTS-style), initialized at current values.

### What we know about stacking
- clip=10 + NS=12→16 + embed_floor + β2=0.99 are largely orthogonal (each wins on a fresh merge of the others)
- Muon-side mechanisms (NS coefficient, NS shape, Muon LR floor) are orthogonal to AdamW-side mechanisms (β1, β2, ε, WD, group-specific betas)
- If fern #290 (NS c-schedule) and thorfinn #279 (aux WD) both confirm, the combined stack could approach val=3.270, reducing the gap to public SOTA from ~0.007 to ~0.001 nats

---

## Closed mechanisms (do not re-explore)

| Category | Mechanism | Evidence |
|----------|-----------|----------|
| Temporal smoothing | Polyak EMA, Lookahead | #104, #120 |
| Element-wise direction shaping | Contra-Soft per-element | #126 |
| Magnitude-coupled trust region | ||w||_F coupled cap | #117 |
| LR warmup | 0/50/100 step warmup | #102 |
| Cooldown frac (timing only) | {0.4, 0.5, 0.6} | #106 |
| Cooldown LR shape (global) | cosine, sqrt, quadratic, exp | #204 |
| Lion optimizer (aux) | Lion embed+lm_head | #77 |
| Per-layer NS adaptive | sigmoid-controlled NS iters | #145 |
| Momentum reset (DMR) | periodic v reset with decay | #163 |
| SOAP/Adafactor on aux | Shampoo rotation / factored v | #144, #180 |
| Adam-style BC in Muon² | BC + beta2=0.98 (bundled) | #115 |
| NS=8 floor test | constant NS=8 | #75 |
| NS high-early anneal | NS=14→8 | #185 |
| Uniform aux LR scaling | 0.5× / 1.5× embed/lm_head/scalar | #188 |
| Muon² eps floor | sweep 1e-9 to 1e-6 | #189 |
| Per-group Muon clip | per-group clip dispatch at clip=10 | #206 |
| AdamW β1 cooldown schedule | β1 linear decay schedule | #227 (null) |
| lm_head + scalar cooldown floor | floor=15% on non-embed aux | #266 (HURTS) |
| Muon mu=0.97 (constant) | within-pod Δ=−0.00289 but cross-pod fail | #241 (productive-null) |
