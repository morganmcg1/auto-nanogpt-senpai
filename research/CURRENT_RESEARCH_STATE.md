# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~03:00Z (poll #185)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536
  - OLD baseline (PR #162): mu=3.271362 (−2.89σ improvement; ffs 3100 vs 3141.67)

## ⭐ Active Hot Signals

1. **🔥 WD TIMING MECHANISM CONFIRMED — EXPLOITING IN 3 DIRECTIONS** 🔥:
   - **edward PR #422**: WD shape variants (lr_coupled/stable_only/early_dropoff) — Cell A ctrl ~step 532 (~16%), Cell B just launched
   - **fern PR #423**: WD peak sensitivity (wd_mlp ∈ {0.0125, 0.025, 0.0375, 0.05, 0.075}) — Cell A ctrl ~step 824 (~25%)
   - **nezuko PR #427**: WD per-block decomposition (MLP vs attn contribution) — **NEW**

2. **LR SCHEDULE SHAPE SWEEP (thorfinn PR #426)**:
   - Cell A ctrl (stable_then_linear) just launched (~60/3250, warmup)
   - Tests: linear_throughout, cosine_throughout, stable_then_cosine, stable_then_sq
   - Code change required: add `_lr_multiplier` + `--lr_schedule` CLI flag

3. **FRIEREN PR #346 lr_attn P2 — Terminal Imminent** ⚠️:
   - T3 at ~98.7%, val=3.2856 current (will drop at terminal), best_val=3.2722
   - Close clean-neutral when student posts final SENPAI-RESULT

4. **TANJIRO PR #368 QKV ortho P2 — In Flight** ⚠️:
   - ~81.7% done (T3 mid-recovery), best_val=3.2716
   - Close clean-neutral when complete (~15-20 min)


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #422 | edward | Muon WD shape variants (lr_coupled / stable_only / early_dropoff / constant-sanity) | **Cell A ctrl ~step 532 (~16%), Cell B just launching (~step 206).** |
| #423 | fern | WD ramp_down peak sensitivity (wd_mlp ∈ {0.0125, 0.025, 0.0375, 0.05, 0.075}) | **Cell A ctrl ~step 824 (~25%), healthy.** |
| #427 | nezuko | Muon WD ramp_down per-block decomposition (MLP vs attn contribution: both/mlp-only/attn-only/none/asym) | **NEW. Cell A ctrl launching.** |
| #426 | thorfinn | LR schedule shape (stable_then_linear ctrl / linear_throughout / cosine_throughout / stable_then_cosine / stable_then_sq) | **NEW. Code change + Cell A ctrl launched (~step 60/3250, warmup).** |
| #418 | alphonse | AdamW aux (β₁, β₂) joint 2D corner sweep | **Cell A ctrl ~step 1743/3250 (~54%). Rebase briefed — will rebase after Cell A terminal.** |
| #398 | askeladd | AdamW aux ε schedule sweep | A=3.26991 ctrl, B=3.27427 clean-NEG; **Cell C ramp_down ~63% in flight; D/E auto-launch pending.** |
| #368 | tanjiro | Orthogonal QKV init P2 — ortho_qk_only | P2 T3 ~81.7%, best_val=3.2716. n=4 gate impossible. Close clean-neutral when done. |
| #346 | frieren | Muon attn LR P2 (lr_attn=0.025) | P2 ~98.7%, best_val=3.2722. n=4 gate impossible. Close clean-neutral imminently. |


## Recent Closures (poll #185)

- **#383 nezuko Muon grad noise** — CLOSED clean-negative. Best Cell C std=1e-3 const val=3.27081 (+4.69σ vs NEW baseline). Mechanism: noise during stable phase slightly beneficial (C > D > E ranking), but sub-statsig and far from new gate. Family retired for r5.
- **#382 thorfinn per-group Muon mu** — CLOSED clean-neutral (poll #184). Default mu=0.95 optimal.
- **#385 edward β₁ schedule** — CLOSED clean-neutral (poll #183).
- **#381 alphonse β₂ schedule** — CLOSED clean-neutral (poll #183).


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. Target: ffs=3100 → 3075 → beyond. NEW BASELINE now at 3.267948.

**Active mechanism threads:**

- **🆕 Muon WD SCHEDULE (WINNER PR #371):** ramp_down (linear 2x→0) beats constant by −2.89σ. ALL 4 trials ffs=3100. Mechanism confirmed: frontloaded WD regularizes high-LR phase; zero WD at cooldown avoids late-training interference. Follow-up triple:
  - **edward #422**: shape variants (lr_coupled, stable_only, early_dropoff) — which sub-mechanism drives the gain?
  - **fern #423**: peak sensitivity (wd_mlp ∈ {0.0125→0.075}) — is 0.05 peak optimal?
  - **nezuko #427**: per-block decomposition (MLP vs attn) — which group carries the win?

- **LR schedule shape (thorfinn #426):** Parallel hypothesis to WD ramp_down: does cooldown shape (cosine vs linear), or absence of stable phase (linear/cosine throughout), extract headroom? Code: add `_lr_multiplier` + `--lr_schedule`.

- **AdamW aux β-joint (alphonse #418):** β₁×β₂ 2D corner sweep. Cell A ctrl ~54% done. Rebase needed after Cell A terminal (conflict: #371 merge vs student's CLI flag additions).

- **AdamW aux ε schedule (askeladd #398):** A ctrl=3.26991, B ramp_up=3.27427 (clean-NEG). Cell C ramp_down ~63%. Trend: ε schedule negative, similar to β₁ pattern.

- **Muon attn LR (frieren #346 P2):** Terminal imminent. Close clean-neutral.

- **QKV ortho init (tanjiro #368 P2):** T3 ~82% done. Close clean-neutral when done.

**Key insight from PR #371 breakthrough:**
WD *timing* is critically asymmetric: early-phase WD prevents bad optimization trajectories; late-phase WD (during cooldown) interferes with trajectory consolidation. A general principle: **the stable high-LR phase is the most regularization-sensitive window**. All current active WD experiments test variants of this axis; LR shape tests whether the same principle holds for LR.

**Exhausted mechanism slots (recent):**
- **Muon grad noise injection (nezuko, closed PR #383 clean-negative):** best Cell C std=1e-3 const val=3.27081, +4.69σ vs new baseline. Mechanism direction correct (stable-phase noise helps vs cooldown-only) but too far from gate. Family retired.
- **Per-group Muon mu (thorfinn, closed PR #382 clean-neutral):** default mu=0.95 optimal in [0.93, 0.97] band. Retired.
- **AdamW aux β₁ schedule (edward, closed PR #385 clean-neutral):** constant 0.8 optimal
- **AdamW aux β₂ schedule (alphonse, closed PR #381 clean-neutral):** ramp_up sub-σ, 0.00002 from gate
- **SOAP precond_freq static (askeladd, closed PR #360 clean-neutral):** U-bowl, freq=16 optimal
- **AdamW aux β₂=0.98 static (edward, closed PR #320 clean-neutral):** n=4 mean=3.27073 sub-statsig
- LR warmup_steps (thorfinn, closed PR #353 clean-neg)
- AdamW aux wd_aux uniform (nezuko, closed PR #349 clean-neg)
- LR cooldown_frac sweep (thorfinn, closed clean-neutral; 0.70 optimal)
- Cautious-Muon, Lookahead, SWA, z-loss, label smoothing, depth-init, per-head SOAP, schedule-free Muon, polynomial schedule-free Muon, SOAP β₂ cooldown annealing — all closed (older)

**Candidate next hypotheses (queue for idle students):**
- **Muon nesterov=False screen** — frieren will be idle when #346 closes (imminent)
- **SOAP precond_freq upper tail {64, 128}** — askeladd next when #398 closes
- **AdamW aux WD ramp_down coupling** — wd_aux=0 currently; approach with caution (PR #349 showed mixed-LR-scale aux groups hurt with uniform WD)
- **SOAP β₂ for attn-SOAP (static sweep)** — untested in r5 (SOAP β₂=0.90 default, may have headroom)
- **Per-block WD peak asymmetry follow-up** — pending nezuko #427 results to determine if MLP or attn dominates
