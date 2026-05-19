# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~06:38Z (poll #202)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536
  - OLD baseline (PR #162): mu=3.271362 (−2.89σ improvement; ffs 3100 vs 3141.67)


## ⭐ Active Hot Signals

1. **🔥 WD TIMING MECHANISM — 3 PARALLEL DEEP-DIVES IN PROGRESS** 🔥:
   - **edward PR #422**: WD shape variants (lr_coupled/stable_only/early_dropoff) — Cell A ctrl terminal 3.2692 ffs=3100; Cell B `swyx9211` (lr_coupled) ~62% step 2031
   - **fern PR #423**: WD peak sensitivity (wd_mlp ∈ {0.0125→0.075}) — Cell A ctrl 3.265555 ffs=3075 (lucky seed); Cell B `onlxdpxd` (wd=0.0125) ~71% step 2339
   - **nezuko PR #427**: WD per-block decomposition (MLP vs attn) — Cell A ctrl 3.2675 ffs=3100; Cell B `l3a6wcda` (mlp_only) ~22% step 717

2. **LR / SOAP SCHEDULE EXPLORATION (3 active)**:
   - **thorfinn PR #426**: LR schedule shape — Cell A ctrl 3.2682 ffs=3100; Cell B `4ryxmej6` (linear_throughout) ~34% step 1114
   - **frieren PR #428**: SOAP β₂ static sweep (0.80/0.85/0.90/0.95/0.98) — Cell A `68v002ds` (ctrl β₂=0.90) at ~87% step 2854 — SURVIVING past prior crash point ✓
   - **askeladd PR #437**: SOAP precond_freq schedule (NEW) — freshly assigned; Cell A ctrl launching

3. **TANJIRO PR #432 Muon nesterov ablation**:
   - Cell A ctrl `g04kfqds` at ~62% step 2032
   - Cell B `6700r3ry` crashed at step 0 (premature launch attempt while Cell A still running — expected to retry after Cell A terminal)

4. **ALPHONSE PR #418 β corner sweep**:
   - Cell A ctrl: 3.27243 ffs=3150 (OLD regime ctrl)
   - Cell B `2wut791f` (β1=0.80, β2=0.98) TERMINAL: val=3.269572 ffs=3125 (+1.97σ vs NEW baseline — neutral)
   - Cell C pending auto-launch from sweep script


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #437 | askeladd | SOAP precond_freq schedule (timing: ramp_down_4_32, ramp_down_8_64) | **NEW** — Cell A ctrl starting |
| #432 | tanjiro | Muon nesterov ablation (nesterov=True vs False after NS5) | Cell A ctrl ~62%; Cell B pending Cell A terminal |
| #428 | frieren | SOAP β₂ static sweep (0.80/0.85/0.90/0.95/0.98) | Cell A `68v002ds` ~87% step 2854 — past crash threshold ✓ |
| #427 | nezuko | Muon WD ramp_down per-block decomp (MLP vs attn) | Cell A ctrl 3.2675 terminal; Cell B `l3a6wcda` ~22% step 717 |
| #426 | thorfinn | LR schedule shape sweep | Cell A ctrl 3.2682 terminal; Cell B `4ryxmej6` (linear_throughout) ~34% step 1114 |
| #423 | fern | WD peak sensitivity (wd_mlp ∈ {0.0125→0.075}) | Cell A ctrl 3.265555 ffs=3075 (lucky n=1); Cell B `onlxdpxd` (wd=0.0125) ~71% step 2339 |
| #422 | edward | Muon WD shape variants (lr_coupled / stable_only / early_dropoff) | Cell A ctrl 3.2692 terminal; Cell B `swyx9211` (lr_coupled) ~62% step 2031 |
| #418 | alphonse | AdamW aux (β₁, β₂) joint 2D corner sweep | Cell B `2wut791f` TERMINAL 3.269572 ffs=3125 (+1.97σ); Cell C auto-launching |


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
