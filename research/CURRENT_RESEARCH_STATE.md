# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~01:15Z (poll #183)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536
  - OLD baseline (PR #162): mu=3.271362 (−2.89σ improvement; ffs 3100 vs 3141.67)

## ⭐ Active Hot Signals

1. **🔥 WD TIMING MECHANISM CONFIRMED — BOTH STUDENTS EXPLOITING** 🔥:
   - **edward PR #422**: WD shape variants (lr_coupled/stable_only/early_dropoff) — dissects mechanism
   - **fern PR #423**: WD peak sensitivity (wd_mlp ∈ {0.0125, 0.025, 0.0375, 0.05, 0.075}) — squeezes more

2. **FRIEREN PR #346 lr_attn P2 — Clean-Neutral Close Imminent** ⚠️:
   - T0=3.275463, T1=3.270923, T2~3.272217 (W&B obs), T3 in flight (~38%)
   - Running mean ≈ 3.272868 — n=4 gate impossible (T3 needs -10.5σ)
   - Once T3 done, close clean-neutral

3. **TANJIRO PR #368 QKV ortho P2 — Clean-Neutral Close Pending** ⚠️:
   - T0=3.270026, T1=3.274355 — running mean 3.272191
   - T2 at 71%, T3 not started — n=4 gate impossible
   - Once both done, close clean-neutral


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #422 | edward | Muon WD shape variants (lr_coupled / stable_only / early_dropoff / constant-sanity) | **NEW. Cell A ctrl ramp_down launching.** |
| #423 | fern | WD ramp_down peak sensitivity (wd_mlp ∈ {0.0125, 0.025, 0.0375, 0.05, 0.075}) | **NEW. Cell A ctrl launching.** |
| #383 | nezuko | Muon gradient noise injection sweep std ∈ {0, 1e-4, 1e-3} × {constant, decay, cooldown_only} | A=3.27218, B=3.27108, C std=1e-3 const=3.27081 (best, −0.58σ OLD baseline), D decay=3.27158 (regression). **E std=1e-3 cooldown RUNNING.** |
| #382 | thorfinn | Per-group Muon mu sweep (mu_mlp × mu_attn ∈ {0.93, 0.95, 0.97}) | A ctrl=3.269644 (-1.46σ OLD lucky), B=3.271077, C=3.273785 neg, D=3.272758 neg. **E (0.95/0.97) RUNNING.** |
| #418 | alphonse | AdamW aux (β₁, β₂) joint 2D corner sweep | **NEW. Cell A ctrl=(0.80, 0.95) launching.** |
| #368 | tanjiro | Orthogonal QKV init P2 — ortho_qk_only | P2 T0=3.270026, T1=3.274355, T2 running (71%). Closing clean-neutral. |
| #398 | askeladd | AdamW aux ε schedule sweep | A ctrl=3.269913 (-1.23σ OLD, lucky seed), **B ramp_up RUNNING** (prev=3.274273 finished = clean-NEG), C ramp_down just launched. |
| #346 | frieren | Muon attn LR P2 (lr_attn=0.025) | P2 T0=3.275463, T1=3.270923, T2~3.272, T3 running (38%). Closing clean-neutral. |


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. Target: ffs=3100 → 3075 → beyond. NEW BASELINE now at 3.267948.

**Active mechanism threads:**

- **🆕 Muon WD SCHEDULE (WINNER PR #371):** ramp_down (linear 2x→0) beats constant by −2.89σ. ALL 4 trials ffs=3100. Mechanism confirmed: frontloaded WD regularizes high-LR phase; zero WD at cooldown avoids late-training interference. Follow-up:
  - **edward #422**: shape variants (lr_coupled, stable_only, early_dropoff) — which sub-mechanism drives the gain?
  - **fern #423**: peak sensitivity (wd_mlp ∈ {0.0125→0.075}) — is 0.05 peak optimal?

- **AdamW aux β₁ schedule (edward, CLOSED #385 clean-neutral):** All 5 shapes neutral/negative. B ramp_up +2.54σ, D triangle +2.81σ — any early-phase β₁ < 0.8 incurs penalty. Constant 0.8 default is at the optimum. β₁-schedule family retired.

- **AdamW aux β₂ schedule (alphonse, CLOSED #381 clean-neutral):** ramp_up best at -1.14σ, missed gate by 0.00002. Sub-σ signal, β₂ schedule family effectively saturated. Joint (β₁×β₂) interaction still being tested (#418).

- **AdamW aux ε schedule (askeladd #398 in flight):** A ctrl=3.269913 (lucky seed). B ramp_up=3.274273 (clean-NEG +2.46σ vs old base). C ramp_down launched. Early ε schedule trend: negative, similar to β₁ pattern.

- **Muon grad noise (nezuko #383):** C std=1e-3 const=3.27081 close-miss (-0.58σ OLD baseline). D decay=3.27158 regression. E cooldown running. Likely closes clean-neutral.

- **Per-group Muon mu (thorfinn #382):** A ctrl lucky-seed, B/C/D neutral-neg. E running. Mechanism closes neutral.

- **LR cooldown_frac (thorfinn, closed):** default 0.70 optimal. Per-group Muon mu now testing.

- **Muon attn LR (frieren #346 P2):** P2 T0/T1/T2 all trend above n=4 gate. Closing clean-neutral.

- **QKV ortho init (tanjiro #368 P2):** P2 T0/T1 above gate, closing clean-neutral.

**Key insight from PR #371 breakthrough:**
WD *timing* is critically asymmetric: early-phase WD prevents bad optimization trajectories; late-phase WD (during cooldown) interferes with trajectory consolidation. The β₁ analogy (early phase β₁ < 0.8 = penalty) supports a general principle: **the stable high-LR phase is the most regularization-sensitive window**. Follow-ups should test this principle across other optimizer hyperparameters.

**Exhausted mechanism slots (recent additions):**
- **AdamW aux β₁ schedule (edward, closed PR #385 clean-neutral):** all 5 shapes neutral/negative; constant 0.8 optimal
- **AdamW aux β₂ schedule (alphonse, closed PR #381 clean-neutral):** ramp_up best, sub-σ signal, 0.00002 from gate
- **SOAP precond_freq static (askeladd, closed PR #360 clean-neutral):** U-bowl, freq=16 default optimal
- **AdamW aux β₂=0.98 static (edward, closed PR #320 clean-neutral):** n=4 mean=3.27073, sub-statsig
- LR warmup_steps (thorfinn, closed PR #353 clean-neg)
- AdamW aux wd_aux uniform (nezuko, closed PR #349 clean-neg)

**Exhausted mechanism slots (older):**
- lr_embed=0.80 (frieren, clean-neutral n=6)
- NS5 polynomial space (askeladd, clean-neutral)
- SOAP attn eigvec smoothing (thorfinn, clean-neutral)
- SOAP β₂ cold-start warmup (edward, clean-neutral)
- Q/K shared Gram (fern, clean-neutral)
- AdamW eps sweep (alphonse, clean-neutral)
- Per-layer LR decay (nezuko, clean-negative)
- NS5 iteration count (askeladd, clean-neutral)
- SOAP attn Gram damping (fern, clean-neutral)
- AGC λ=0.03 (nezuko, closed PR #283)
- Muon WD static sweep (askeladd, closed PR #334 clean-neg)
- Muon mu sweep (tanjiro, closed PR #323 clean-neg)
- AdamW aux β₁=0.70 (fern, closed PR #318 clean-neutral)
- lr_lm_head=0.030 (alphonse, closed PR #306 clean-neutral)
- Cautious-Muon, Lookahead, SWA, z-loss, gradient centralization, label smoothing, depth-init, per-head SOAP, schedule-free Muon, polynomial schedule-free Muon, SOAP β₂ cooldown annealing — all closed

**Candidate next hypotheses (queue for idle students):**
- **LR ramp-shape analogous to WD ramp_down** — does "lr-frontloaded" (decaying faster early) improve on stable-then-linear? Could couple WD and LR schedule shapes.
- **Muon nesterov=False screen** — never directly tested in r5; frieren will be idle soon when #346 closes
- **SOAP precond_freq upper tail {64, 128}** — askeladd next when #398 closes
- **AdamW aux WD ramp_down coupling** — wd_aux=0 currently; a small ramp_down wd_aux might stack
- **Per-block WD heterogeneity** — MLP vs ATN may want different ramp_down peaks/shapes
- **β₁×β₂ joint interaction** — alphonse #418 in flight; closes this question
- **SOAP β₂ for attn-SOAP (static sweep)** — untested in r5 (SOAP β₂=0.90 default, may have headroom)
