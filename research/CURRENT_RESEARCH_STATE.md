# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~12:00Z (poll #243)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536
  - OLD baseline (PR #162): mu=3.271362 (−2.89σ improvement; ffs 3100 vs 3141.67)


## ⭐ Active Hot Signals

1. **🎯 EDWARD WD-SHAPE — P2 n=4 CONFIRMATION IN PROGRESS on Cell C `stable_only`**:
   - **CLEAN MONOTONIC SWEEP COMPLETE (poll #243):**

   | Cell | Schedule | val/loss | ffs | Δσ vs NEW baseline | Cooldown WD |
   |------|----------|----------|-----|-----|-----|
   | E | constant | 3.2705 | 3125 | **+3.10σ NEG** | MAX |
   | B | lr_coupled | — | — | +2.25σ NEG | high |
   | A (ctrl) | ramp_down | — | 3100 | +1.51σ | moderate |
   | D | early_dropoff | 3.26745 | 3025 | −0.61σ | low |
   | **C** | **stable_only** | **3.26663** | **3025** | **−1.60σ #1** | **MIN** |

   - Mechanism unambiguous: **less cumulative cooldown WD ⇒ better val/loss.** σ-ordering matches cooldown-WD ordering exactly.
   - Cell C beats baseline on BOTH metrics: val by −1.60σ AND ffs 3025 vs 3100.
   - **P2 DIRECTED (poll #243):** edward launching n=4 confirmation on Cell C `stable_only`.
   - P2 gate: mu_p2 ≤ 3.265948 = PASS → merge PR #422 as new baseline.

2. **AdamW AUX WD SWEEP (alphonse #455)** — NEW (poll #242):
   - 5 cells: A (ctrl wd_aux=0), B (const 0.0025), C (const 0.025), D (ramp_down 0.0025), E (ramp_down 0.025)
   - Hypothesis: WD timing mechanism generalizes across optimizer families
   - alphonse picking up and starting Cell A

3. **COOLDOWN_FRAC SWEEP (fern #457)** — NEW (poll #243):
   - 5 cells: A (ctrl 0.7), B (0.3), C (0.5), D (0.85), E (1.0)
   - Hypothesis: cooldown_frac=0.7 was tuned on OLD constant-WD baseline; may shift with new ramp_down WD
   - fern picking up Cell A (ctrl)

4. **SOAP β₂ STATIC SWEEP (frieren #428)** — flat band in {0.80..0.90}:
   - A (0.90 ctrl) +0.31σ; B (0.85) −0.24σ; C (0.80) −0.14σ; all within ±0.5σ
   - **Cell D `cvoqggz6` (β₂=0.95)** — checking status; was ~65% at last poll
   - If D/E within ±0.5σ → close clean-neutral; if 0.95 trends negative → β₂ scheduling axis next

5. **SOAP PRECOND_FREQ SCHEDULE (askeladd #437)**:
   - A (constant ctrl) +0.13σ; B (ramp_down_4_32) +17.39σ NEG
   - **Cell C `mukq2juj` (ramp_down_8_64)** — was ~44% at last poll, checking

6. **TANJIRO MUON MU SCHEDULE (PR #445)**:
   - Cell A TERMINAL val=3.264929, −3.67σ (lucky ctrl seed — variance calibration)
   - **Cell B `3tvr1x36` (ramp_up_090_099)** — was ~59% at last poll, checking

7. **PER-BLOCK WD DECOMP (nezuko #427)** — closing:
   - B +3.42σ NEG; C +12.40σ NEG; D (no_wd) +23.4σ NEG
   - **Cell E `ixfq2sdq` (asymmetric heavy-MLP: wd_mlp=0.05, wd_attn=0.0125)** — running, ~29% step 935 at last check
   - After E terminal: close PR (all NEG, MLP WD dominant, asymmetric redistribution the only remaining test)

8. **LR-SHAPE SWEEP (thorfinn #426)** — closing clean-NEG:
   - B +3.44σ; C +12.5σ; D (stable_then_cosine) +7.25σ — all LR shapes worse
   - **Cell E `ciyjvoaw` (stable_then_sq)** — was ~60% step 1970 at last check
   - After E terminal: close PR with full table

**⚠️ Variance calibration insight (from multiple polls):** Single-seed repros of the baseline ctrl frequently land ≤2σ below the n=4 mean. **Always require P2 n=4 before claiming a winner.** P2 gate: mu_p2 ≤ 3.265948.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #457 | fern | cooldown_frac sweep on WD ramp_down baseline (0.3/0.5/0.7/0.85/1.0) | **NEW — Cell A (ctrl) first** |
| #455 | alphonse | AdamW aux WD sweep (wd_aux=0/0.0025/0.025 × constant/ramp_down) | **NEW — Cell A (ctrl) first** |
| #445 | tanjiro | Muon mu schedule sweep (constant / ramp_up / ramp_down / cliff) | A TERMINAL −3.67σ ctrl; **B `3tvr1x36` (ramp_up) ~59%** |
| #437 | askeladd | SOAP precond_freq schedule (constant/ramp_down_4_32/ramp_down_8_64) | A +0.13σ; B +17.39σ NEG; **C `mukq2juj` ~44%** |
| #428 | frieren | SOAP β₂ static sweep (0.80/0.85/0.90/0.95/0.98) | A +0.31σ; B −0.24σ; C −0.14σ; **D `cvoqggz6` ~65%** |
| #427 | nezuko | Muon WD ramp_down per-block decomp (MLP vs attn) | B +3.42σ; C +12.40σ; D (no_wd) +23.4σ NEG; **E `ixfq2sdq` (asym heavy-MLP) ~29%** |
| #426 | thorfinn | LR schedule shape sweep | B +3.44σ; C +12.5σ; D +7.25σ; **E `ciyjvoaw` (stable_then_sq) ~60%** |
| #422 | edward | Muon WD shape variants — **P2 n=4 on Cell C `stable_only`** | A +1.51σ; B +2.25σ; C −1.60σ; D −0.61σ; E +3.10σ; **P2 LAUNCHING** |


## Recent Closures (poll #242–243)

- **#423 fern WD peak sensitivity** — CLOSED clean-NEG (poll #243). Peak=0.050 optimal (current ctrl). Bowl sharply asymmetric (high side: +7.4σ, +18.7σ). No direction to push.
- **#418 alphonse AdamW β corner** — CLOSED clean-NEG (poll #242). All 5 cells +1.97–5.58σ vs NEW. β₁/β₂ corner redundant with WD ramp_down mechanism.
- **#432 tanjiro Muon nesterov** — CLOSED clean-neutral (poll #222).
- **#398 askeladd ε-schedule** — CLOSED clean-NEG (poll #202).
- **#368 tanjiro QKV ortho P2** — CLOSED clean-neutral (poll #193).
- **#346 frieren lr_attn P2** — CLOSED clean-neutral.
- **#383 nezuko Muon grad noise** — CLOSED clean-NEG (poll #185).
- **#382 thorfinn per-group Muon mu** — CLOSED clean-neutral (poll #184).


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. Target: ffs=3100 → 3025 (edward Cell C) → beyond.

**Active mechanism threads:**

- **WD schedule timing (WINNER PR #371 + EDWARD P2 in progress):**
  - edward #422: Cell C `stable_only` leading at −1.60σ; CLEAN MONOTONIC sweep; P2 n=4 launched
  - nezuko #427: MLP WD dominant confirmed; closing
  - fern #423: Peak=0.050 optimal; CLOSED

- **Cooldown_frac axis (fern #457 NEW):** First re-test of stable/cooldown split on NEW baseline

- **SOAP schedule axes (frieren #428, askeladd #437):**
  - β₂ static sweep (frieren): flat in {0.80..0.90}; Cell D (0.95) in flight
  - precond_freq schedule (askeladd): B strongly NEG; Cell C in flight

- **AdamW aux WD (alphonse #455):** Complete fresh untested axis

- **Muon mu schedule (tanjiro #445):** Timing insight applied to momentum axis

- **LR schedule shape (thorfinn #426):** All variants worse; Cell E final; closing

**Key insight accumulated this session:**
WD *timing* is critically asymmetric across BOTH axes confirmed:
- edward: `stable_only` (zero WD at cooldown) beats ramp_down baseline — cell C is the cleanest monotonic signal
- nezuko: MLP WD overwhelmingly load-bearing; attn WD secondary
- fern: WD peak=0.050 is the optimal for ramp_down; asymmetric bowl

**Candidate next hypotheses (queue after current batch):**
- **SOAP β₂ schedule (ramp_down)** — if frieren #428 shows 0.95 is neutral, test scheduling β₂ over training
- **Muon NS5 iteration count** (nsp_iter=5 currently; never varied)
- **Asymmetric per-group WD schedule** (MLP stable_only + attn constant) — if edward P2 passes
- **Per-group cooldown_frac** — decouple MLP vs attn LR phase timing
- **Trust threshold for SOAP** (`soap_trust_threshold`, currently 0.0)
