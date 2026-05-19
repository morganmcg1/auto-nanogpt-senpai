# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~11:30Z (poll #242)
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
   - **Cell E `3fdvpo5h` (`constant` no-decay) running ~86% step ~2786**, ETA ~16min.
   - **Plan:** after Cell E terminal → P2 = n=4 confirmation on Cell C `stable_only`. PR #422 is highest-priority winner candidate.

2. **WD-PEAK SENSITIVITY (fern #423)** — bowl confirmed asymmetric:
   - Peak {0.025, 0.050, 0.075, 0.100}: Δσ = +5.42, **−2.91 (ctrl), +1.23, +7.41** vs NEW baseline.
   - Peak=0.050 (current ctrl) is sweet spot; high side falls off more steeply than low side.
   - **Cell E `5gwchl7s` (peak=0.150) ~98% step ~3177**, effectively terminal — ETA min. Will be NEG.

3. **PER-BLOCK WD DECOMP (nezuko #427)** — axis closing:
   - B `mlp_only` (no attn WD): +3.42σ NEG; **C `attn_only` (no MLP WD): +12.40σ NEG**
   - **Cell D `c6xs02nv` TERMINAL val=3.2872 → +23.4σ NEG** — catastrophic; whatever D's decomp, it's worse than C. MLP WD is overwhelmingly load-bearing. Axis closing cleanly NEG — will close PR after nezuko posts final results.

4. **LR-SHAPE SWEEP (thorfinn #426)** — closing clean-NEG:
   - B (linear_throughout) +3.44σ NEG; C (cosine_throughout) val=3.2782 +12.5σ; **D (stable_then_cosine) TERMINAL val=3.273911, ffs=3000, +7.25σ NEG**. All LR-shape variants worse than ramp_down baseline. Axis closes when student posts unified table.

5. **SOAP β₂ STATIC SWEEP (frieren #428)** — flat band confirmed:
   - A (0.90 ctrl) +0.31σ; B (0.85) −0.24σ; **C (0.80) TERMINAL −0.14σ**. All within ±0.5σ. β₂ static axis is flat in {0.80..0.90}.
   - **Cell D `cvoqggz6` (β₂=0.95) running ~65% step ~2105**, ETA ~39min.
   - If D/E within ±0.5σ → close clean-neutral; if 0.95 trends negative → β₂ scheduling axis next.

6. **SOAP PRECOND_FREQ SCHEDULE (askeladd #437)**:
   - A (constant ctrl) +0.13σ ✓; **B `nbupkfcr` (ramp_down_4_32) TERMINAL +17.39σ NEG**. Frequent early precond updates (freq=4) inject noise; sparse cooldown (freq=32) can't recover.
   - **Cell C `mukq2juj` (ramp_down_8_64) running ~44% step ~1444**, ETA ~62min.

7. **AdamW β CORNER (alphonse #418)** — CLOSED clean-NEG:
   - All 5 cells +1.97 to +5.58σ vs NEW baseline. β₁/β₂ corner effect is redundant with WD ramp_down in NEW regime.

8. **TANJIRO MUON MU SCHEDULE (PR #445)**:
   - **Cell A `xxjjw1ab` (constant ctrl) TERMINAL val=3.264929, ffs=3075, −3.67σ vs n=4 mean** — variance calibration: single-seed baseline can land well below n=4 mean.
   - **Cell B `3tvr1x36` (ramp_up_090_099) running ~59% step ~1925**, ETA ~45min. Auto-chain to C (ramp_down_099_090) then D (cliff_at_cooldown).

9. **🆕 AdamW AUX WD SWEEP (alphonse #455)** — NEW:
   - **Hypothesis**: AdamW aux groups (embed/lm_head/scalars) have `weight_decay=0` — completely unregularized. If the WD-timing winner mechanism (regularize stable phase, release at cooldown) generalizes across optimizer families, adding ramp_down WD to aux groups should compound.
   - **5 cells**: A (ctrl wd_aux=0), B (const 0.0025), C (const 0.025), D (ramp_down 0.0025), E (ramp_down 0.025 — full winner mirror)
   - **Code change**: add `--wd_aux` + `--wd_aux_schedule` CLI flags, thread into AdamW constructor and `set_hparams`

**⚠️ Variance calibration insight (poll #234):** Tanjiro Cell A control reproduction at −3.67σ shows single-seed std of baseline is wider than the n=4 SEM suggests. **Edward Cell C (−1.60σ) and Cell D (−0.61σ) signals are weaker than tanjiro's lucky control reproduction — both may be noise.** P2 n=4 confirmation is essential before claiming a winner.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #455 | alphonse | AdamW aux WD sweep (wd_aux=0/0.0025/0.025, schedule=constant/ramp_down) | **NEW — Cell A (ctrl) first** |
| #445 | tanjiro | Muon mu schedule sweep (constant / ramp_up / ramp_down / cliff) | A TERMINAL val=3.2649 −3.67σ; **B `3tvr1x36` (ramp_up) ~59% step 1925** |
| #437 | askeladd | SOAP precond_freq schedule (constant/ramp_down_4_32/ramp_down_8_64) | A +0.13σ ✓; B +17.39σ NEG; **C `mukq2juj` ~44% step 1444** |
| #428 | frieren | SOAP β₂ static sweep (0.80/0.85/0.90/0.95/0.98) | A +0.31σ; B −0.24σ; C −0.14σ; **D `cvoqggz6` ~65% step 2105** |
| #427 | nezuko | Muon WD ramp_down per-block decomp (MLP vs attn) | B +3.42σ NEG; C +12.40σ NEG; **D `c6xs02nv` TERMINAL val=3.2872 +23.4σ NEG** — closing |
| #426 | thorfinn | LR schedule shape sweep | B +3.44σ; C +12.5σ; **D TERMINAL +7.25σ NEG** — closing |
| #423 | fern | WD peak sensitivity (peak ∈ {0.025..0.150}) | A=−2.91σ ✓; B/C/D +5.42/+1.23/+7.41σ; **E `5gwchl7s` (peak=0.150) ~98%** |
| #422 | edward | Muon WD shape variants (lr_coupled/stable_only/early_dropoff/constant) | A=+1.51σ; B=+2.25σ; **C=−1.60σ (#1)**; D=−0.61σ; **E `3fdvpo5h` ~86% step 2786** |


## Recent Closures

- **#418 alphonse AdamW β corner (β₁, β₂) joint 2D sweep** — CLOSED clean-NEG (poll #242). All 5 cells +1.97σ to +5.58σ vs NEW baseline. β₁/β₂ corner effect is redundant with WD ramp_down in NEW regime. Cell B (β1=0.80) had -2.42σ signal vs OLD baseline but that was already encoded in PR #371 mechanism.
- **#432 tanjiro Muon nesterov ablation** — CLOSED clean-neutral (poll #222).
- **#398 askeladd ε-schedule sweep** — CLOSED clean-NEG (poll #202). 4/4 cells +2.39σ to +7.69σ vs NEW baseline.
- **#368 tanjiro QKV ortho P2** — CLOSED clean-neutral (poll #193).
- **#346 frieren lr_attn P2** — CLOSED clean-neutral.
- **#383 nezuko Muon grad noise** — CLOSED clean-negative (poll #185). Best +3.48σ.
- **#382 thorfinn per-group Muon mu** — CLOSED clean-neutral (poll #184).


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. Target: ffs=3100 → 3075 → beyond.

**Active mechanism threads:**

- **WD schedule timing (WINNER PR #371):** Three simultaneous follow-ups:
  - **edward #422**: shape variants — isolates which portion of ramp_down drives the win (Cell C `stable_only` leading at −1.60σ)
  - **fern #423**: peak sensitivity — is wd_mlp=0.05 peak optimal? Cell E (peak=0.150) near terminal, expected NEG
  - **nezuko #427**: per-block contribution — MLP WD load-bearing confirmed; axis closing NEG

- **LR schedule shape (thorfinn #426):** All variants worse; closing.

- **SOAP schedule axes (frieren #428, askeladd #437):**
  - β₂ static sweep (frieren): flat in {0.80..0.90}; Cell D (β₂=0.95) in flight
  - precond_freq schedule (askeladd): B strongly NEG; Cell C (ramp_down_8_64) in flight

- **AdamW aux WD (alphonse #455):** Fresh untested axis — embed/lm_head/scalars completely unregularized. Testing if WD timing principle generalizes.

- **Muon mu schedule (tanjiro #445):** Timing insight applied to Muon momentum axis.

**Key insight from PR #371 breakthrough:**
WD *timing* is critically asymmetric: early-phase WD prevents bad trajectories; late-phase WD interferes with consolidation. General principle: **the stable high-LR phase is the most sensitive window**. Extended to: LR shape, SOAP β₂, SOAP precond_freq schedule, AdamW aux WD.

**Exhausted mechanism slots (recent):**
- **AdamW aux β corner (#418 closed NEG):** β₁/β₂ joint sweep; all NEG vs NEW baseline.
- **AdamW aux ε schedule (#398 closed NEG):** All shapes worse; static ε=1e-10 optimal.
- **Muon attn LR (#346 neutral):** P2 n=4 gate failed.
- **Muon grad noise (#383 NEG):** Best +3.48σ.
- **Per-group Muon mu (#382 neutral):** mu=0.95 optimal.
- **AdamW aux β₁/β₂ schedules (#385, #381 neutral)**
- **SOAP precond_freq static (#360 neutral):** U-bowl, freq=16 optimal.
- **QKV ortho init (#368 P2 neutral):** Gate failed.

**Candidate next hypotheses (queue):**
- **SOAP β₂ schedule (ramp)** — pending frieren #428 static sweep result
- **Edward Cell C P2 n=4** — highest priority after Cell E terminal; PR #422 win candidate
- **AdamW aux WD ramp_down coupling** — alphonse #455 in flight; cross-optimizer generalization test
- **SOAP preconditioner decoupled β** (precond_beta vs shampoo_beta independently)
- **Muon mu schedule** — tanjiro #445; ramp_up/down/cliff on momentum axis
- **Hybrid LR (stable_then_smooth)** — thorfinn Cell D found ffs=3000 with smooth cooldown; combining with ramp_down LR shape
