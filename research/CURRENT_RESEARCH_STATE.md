# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~09:30Z (poll #233)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536
  - OLD baseline (PR #162): mu=3.271362 (−2.89σ improvement; ffs 3100 vs 3141.67)


## ⭐ Active Hot Signals

1. **🎯 EDWARD WD-SHAPE SWEEP — Cell C still strongest, Cell D confirms direction**:
   - **Cell C `stable_only`**: val=3.26663, ffs=3025 → **−1.60σ vs NEW baseline** (#1 beat-baseline candidate, n=1)
   - **Cell D `early_dropoff` TERMINAL (09:15Z)**: val=3.26745, ffs=3025 → **−0.61σ** (#2)
   - Cell A `ramp_down` (ctrl): +1.51σ; B `lr_coupled`: +2.25σ NEG
   - **Mechanism confirmed:** less cumulative cooldown WD ⇒ better val. Cumulative WD ordering B>A>D>C matches inverse val ordering. "Full stable WD + cliff to 0 at cooldown" (C) beats "linear taper to mid then 0" (D).
   - **Cell E `3fdvpo5h` (`constant` no-decay) running step ~345/3250**, ETA ~10:55Z.
   - **Plan:** after Cell E terminal → P2 = n=4 confirmation on Cell C `stable_only`. PR #422 is highest-priority winner candidate.

2. **WD-PEAK SENSITIVITY (fern #423)** — bowl confirmed asymmetric:
   - Peak {0.025, 0.050, 0.075, 0.100}: Δσ = +5.42, **−2.91 (ctrl), +1.23, +7.41** vs NEW baseline.
   - Peak=0.050 (current ctrl) is sweet spot; high side falls off more steeply than low side.
   - **Cell E `5gwchl7s` (peak=0.150) running step ~789/3250**, ETA ~11:30Z.

3. **PER-BLOCK WD DECOMP (nezuko #427)**:
   - B `mlp_only` (no attn WD): +3.42σ NEG; **C `attn_only` (no MLP WD): +12.40σ NEG** — confirms **MLP WD is overwhelmingly load-bearing**. Cell D `c6xs02nv` running step ~2303 (~71%).

4. **LR-SHAPE SWEEP (thorfinn #426)**:
   - B (linear_throughout) +3.44σ NEG; C (cosine_throughout) val=3.2782 +12.5σ NEG but ffs=3050 (50 steps faster — interesting tradeoff). Cell D `bwhvrqmy` (stable_then_cosine) running step ~2707 (~83%).

5. **SOAP β₂ STATIC SWEEP (frieren #428)** — flat band confirmed:
   - A (0.90 ctrl) +0.31σ; B (0.85) −0.24σ; **C (0.80) TERMINAL −0.14σ**. All within ±0.5σ. β₂ static axis is flat in {0.80..0.90}.
   - Advisor flagged Cell C retry `7z7s1zj5` for kill. Directed launch of Cell D (β₂=0.95) per cell plan.
   - If D/E within ±0.5σ → close clean-neutral; if 0.95 trends negative → β₂ scheduling axis next.

6. **SOAP PRECOND_FREQ SCHEDULE (askeladd #437)**:
   - A (constant ctrl) +0.13σ ✓; **B `nbupkfcr` (ramp_down_4_32) TERMINAL +17.39σ NEG**. Frequent early precond updates (freq=4) inject noise; sparse cooldown (freq=32) can't recover.
   - Advisor flagged 2 duplicate Cell B retries (`60vwhvpg`, `zc2f9o9j`) for kill — GPU mem 71GB ⇒ both running on same H100. Directed launch of Cell C (ramp_down_8_64).

7. **AdamW β CORNER (alphonse #418)** — anti-synergy at joint corner:
   - B (β1=0.80, β2=0.98) +1.97σ; C (β1=0.90, β2=0.95) +5.58σ NEG; **D (β1=0.90, β2=0.98) TERMINAL +4.18σ NEG** (anti-synergy: regressed +1.45σ above additive prediction).
   - **Cell E `blrvl2n1` (β1=0.70, β2=0.99) running step ~1307** (~40%); ETA ~11:00Z.

8. **TANJIRO MUON MU SCHEDULE (NEW PR #445)**:
   - **Cell A `xxjjw1ab` (muon-mu-A-constant ctrl) running step ~1855 (~57%)**, ETA ~11:00Z.
   - Tests: constant / ramp_up_090_099 / ramp_down_099_090 / cliff_at_cooldown_095_099 — apply "schedule timing" insight to Muon momentum axis. Auto-chains A→B→C.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #445 | tanjiro | Muon mu schedule sweep (constant / ramp_up / ramp_down / cliff) | Cell A `xxjjw1ab` (constant ctrl) ~57% step 1855 |
| #437 | askeladd | SOAP precond_freq schedule (constant/ramp_down_4_32/ramp_down_8_64) | A +0.13σ ✓; **B +17.39σ NEG**; 2 retries (`60vwhvpg`,`zc2f9o9j`) flagged — Cell C next |
| #428 | frieren | SOAP β₂ static sweep (0.80/0.85/0.90/0.95/0.98) | A +0.31σ; B (0.85) −0.24σ; **C (0.80) −0.14σ**; retry `7z7s1zj5` flagged — Cell D next |
| #427 | nezuko | Muon WD ramp_down per-block decomp (MLP vs attn) | B (mlp_only) +3.42σ NEG; C (attn_only) +12.40σ NEG; D `c6xs02nv` ~71% step 2303 |
| #426 | thorfinn | LR schedule shape sweep | B (linear) +3.44σ NEG; C (cosine) +12.5σ ffs=3050; D `bwhvrqmy` ~83% step 2707 |
| #423 | fern | WD peak sensitivity (peak ∈ {0.025..0.150}) | A=-2.91σ ✓; B/C/D +5.42/+1.23/+7.41σ; **E `5gwchl7s` (peak=0.150)** ~24% step 789 |
| #422 | edward | Muon WD shape variants (lr_coupled/stable_only/early_dropoff/constant) | A=+1.51σ; B=+2.25σ; **C=−1.60σ (#1)**; **D=−0.61σ (#2)**; E `3fdvpo5h` ~11% step 345 |
| #418 | alphonse | AdamW aux (β₁, β₂) joint 2D corner sweep | B +1.97σ; C +5.58σ; **D (β1=0.90,β2=0.98) TERMINAL +4.18σ NEG**; E `blrvl2n1` ~40% step 1307 |


## Recent Closures

- **#432 tanjiro Muon nesterov ablation** — CLOSED clean-neutral (poll #222). nesterov on/off is no-op after NS5 orthogonalization.
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
