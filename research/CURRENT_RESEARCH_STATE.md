# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~07:23Z (poll #221)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536
  - OLD baseline (PR #162): mu=3.271362 (−2.89σ improvement; ffs 3100 vs 3141.67)


## ⭐ Active Hot Signals

1. **🎯 EDWARD CELL C `stable_only` — STRONGEST SIGNAL THIS ROUND** 🎯:
   - val=3.26663, ffs=3025 — **Δσ = −1.60σ vs NEW baseline** (closest to beat-baseline n=1)
   - ffs 75 steps faster than current baseline (3025 vs 3100)
   - **Mechanism:** cliff WD to 0 at cooldown start (step 975) beats linear ramp_down. Across A/B/C: less cooldown WD ⇒ better val (monotonic).
   - Cell D `early_dropoff` (`t4yf1o26`) auto-chained, Cell E `constant` next.
   - **Plan:** wait for D/E terminal, then P2 = n=4 confirmation on best cell.

2. **WD/LR TIMING DEEP-DIVES — Cell C/D running**:
   - **edward PR #422**: A=+1.52σ, B (lr_coupled) +1.04σ NEG, **C (stable_only) −1.60σ WINNER CANDIDATE**. Cell D `early_dropoff` `t4yf1o26` running.
   - **fern PR #423**: B (wd=0.0125) +5.43σ NEG, C (wd_mlp=0.0375) terminal +1.23σ neutral; Cell D `x7abxdny` (wd-peak-D-050) running.
   - **nezuko PR #427**: Cell B `l3a6wcda` (mlp_only) TERMINAL +3.42σ NEG. Cell C `8gqb5oav` (attn_only) running step ~65%.

3. **LR / SOAP / SCHEDULE EXPLORATION**:
   - **thorfinn PR #426**: B (linear_throughout) +3.44σ NEG. Cell C retry `46k4693a` (cosine_throughout) running ~77%.
   - **frieren PR #428**: A (β₂=0.90 ctrl) +0.31σ neutral; B (β₂=0.85) −0.24σ neutral (fails gate); re-launch `hx8kj0ej` crashed step 647 — advised redirect to Cell C (β₂=0.80) / D / E.
   - **askeladd PR #437**: A (constant ctrl) `fy5yw64u` TERMINAL +0.13σ neutral; Cell B `nbupkfcr` (ramp_down_4_32) running step ~29.

4. **TANJIRO PR #432 Muon nesterov ablation**:
   - A `g04kfqds` −0.87σ neutral; B retry `93s9wz05` (no_muon_nesterov) running ~94% (trending +18σ NEG).

5. **ALPHONSE PR #418 β corner sweep**:
   - B (β1=0.80, β2=0.98) +1.97σ neutral; C (β1=0.90, β2=0.95) +5.58σ NEG; **D `ilq161pe` (β1=0.90, β2=0.98) running ~31%** (β1 confirmed no-op); E (β1=0.70, β2=0.99) queued.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #437 | askeladd | SOAP precond_freq schedule (timing: ramp_down_4_32, ramp_down_8_64) | Cell A `fy5yw64u` (constant ctrl) ~65% step 2129 |
| #432 | tanjiro | Muon nesterov ablation (nesterov=True vs False after NS5) | A `g04kfqds` -0.87σ neutral; Cell B retry `93s9wz05` (no_nesterov) ~39% step 1273 |
| #428 | frieren | SOAP β₂ static sweep (0.80/0.85/0.90/0.95/0.98) | A `68v002ds` +0.31σ neutral; Cell B `sz3rwtrx` (β₂=0.85) ~76% step 2461 — proj ~3.263 WATCH |
| #427 | nezuko | Muon WD ramp_down per-block decomp (MLP vs attn) | B `l3a6wcda` +3.42σ NEG; Cell C `8gqb5oav` (attn_only) ~11% step 358 |
| #426 | thorfinn | LR schedule shape sweep | B `4ryxmej6` +3.44σ NEG; Cell C orig `r4tu4c5k` crashed → retry `46k4693a` ~20% step 652 |
| #423 | fern | WD peak sensitivity (wd_mlp ∈ {0.0125→0.075}) | B `onlxdpxd` +5.43σ NEG; Cell C `g3lkfo3o` (wd_mlp=0.0375) ~60% step 1954 |
| #422 | edward | Muon WD shape variants (lr_coupled / stable_only / early_dropoff) | B `swyx9211` +2.96σ NEG; Cell C `2qgw98tq` ~44% step 1441 |
| #418 | alphonse | AdamW aux (β₁, β₂) joint 2D corner sweep | B `2wut791f` +1.97σ neutral; Cell C `l6yui9jh` (β1=0.90, β2=0.95) ~80% step 2606 |


## Recent Closures

- **#398 askeladd ε-schedule sweep** — CLOSED clean-NEG (poll #202). 4/4 cells +2.39σ to +7.69σ vs NEW baseline. ε-schedule axis exhausted.
- **#368 tanjiro QKV ortho P2** — CLOSED clean-neutral (poll #193). n=4 mean=3.27250 (+5.53σ). QKV init family closed.
- **#346 frieren lr_attn P2** — CLOSED clean-neutral. n=4 mean ~3.272631 (+5.69σ vs NEW).
- **#383 nezuko Muon grad noise** — CLOSED clean-negative (poll #185). Best +3.48σ.
- **#382 thorfinn per-group Muon mu** — CLOSED clean-neutral (poll #184). Default mu=0.95 optimal.


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. Target: ffs=3100 → 3075 → beyond.

**Active mechanism threads:**

- **WD schedule timing (WINNER PR #371):** Three simultaneous follow-ups:
  - **edward #422**: shape variants — isolates which portion of ramp_down drives the win
  - **fern #423**: peak sensitivity — is wd_mlp=0.05 peak optimal? Cell B testing wd=0.0125
  - **nezuko #427**: per-block contribution — which group (MLP vs attn) carries the gain?

- **LR schedule shape (thorfinn #426):** "schedule shape matters" applied to LR axis.

- **SOAP schedule axes (frieren #428, askeladd #437):**
  - β₂ static sweep (frieren): preconditioner EMA half-life; default β₂=0.90 may not be optimal
  - precond_freq schedule (askeladd): timing of precond updates — ramp_down analogous to WD ramp_down insight

- **Muon nesterov ablation (tanjiro #432):** First test of nesterov=False after NS5.

- **AdamW aux β-corner (alphonse #418):** β1/β2 joint sweep; Cell B b1=0.80 neutral.

**Key insight from PR #371 breakthrough:**
WD *timing* is critically asymmetric: early-phase WD prevents bad trajectories; late-phase WD interferes with consolidation. General principle: **the stable high-LR phase is the most sensitive window**. Extended to: LR shape, SOAP β₂, SOAP precond_freq schedule.

**Exhausted mechanism slots (recent):**
- **AdamW aux ε schedule (#398 closed NEG):** All shapes worse; static ε=1e-10 optimal.
- **Muon attn LR (#346 neutral):** P2 n=4 gate failed.
- **Muon grad noise (#383 NEG):** Best +3.48σ.
- **Per-group Muon mu (#382 neutral):** mu=0.95 optimal.
- **AdamW aux β₁/β₂ schedules (#385, #381 neutral)**
- **SOAP precond_freq static (#360 neutral):** U-bowl, freq=16 optimal.
- **QKV ortho init (#368 P2 neutral):** Gate failed.
- Older: LR cooldown_frac, warmup_steps, WD static sweeps, Cautious-Muon, SWA, z-loss, etc.

**Candidate next hypotheses (queue):**
- **SOAP β₂ schedule (ramp)** — pending frieren #428 static sweep
- **Muon mu schedule** — ramp mu from 0.99 → 0.95 ("schedule-shape-matters" on Muon momentum)
- **AdamW aux WD ramp_down coupling** — after nezuko #427 informs per-block picture
- **SOAP preconditioner decoupled β** (precond_beta vs shampoo_beta independently) — both hardcoded to SOAP_BETA2=0.90
