# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~13:15Z (poll #245)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ Active Winner Candidates (P2 in progress)

### #1 EDWARD #422 — Cell C `stable_only` WD: −1.60σ (n=1)
- **Mechanism:** WD=0 during entire cooldown phase (cliff at cooldown start). Less cumulative cooldown WD = better val.
- **P2 n=4 LAUNCHED:** edward running `--num_trials 4 --wd_schedule stable_only`. Run `ob6ek9zt`. ETA ~14:00Z+.
- **Gate:** mu_p2 ≤ 3.265948

### #2 ASKELADD #437 — Cell C `ramp_down_8_64` precond_freq: −1.27σ (n=1)
- **val=3.266906, ffs=3075** — beats baseline on BOTH metrics
- **Mechanism:** SOAP precond_freq ramps down (8→64 updates per step), less frequent precond during cooldown = better. CROSS-AXIS CONFIRMATION of "less intensity in cooldown" principle.
- **P2 n=4 LAUNCHED (poll #244).** Run `h8g04vyb`. ETA ~14:00Z+.
- **Gate:** mu_p2 ≤ 3.265948


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #467 | nezuko | SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8) | **NEW — Cell A (ctrl) first** |
| #461 | thorfinn | NS iteration count sweep (6/8/10/12/14) — code edit + ctrl running | **Cell A `4ggucv59` running ~10%** |
| #457 | fern | cooldown_frac sweep on WD ramp_down baseline (0.3/0.5/0.7/0.85/1.0) | **Cell A `z4qxld9o` running ~65%** |
| #455 | alphonse | AdamW aux WD sweep (wd_aux=0/0.0025/0.025 × constant/ramp_down) | **Cell A `7iniw4rh` running ~53%** |
| #445 | tanjiro | Muon mu schedule sweep | A −3.67σ ctrl; B +11.29σ NEG; **C `ramp_down_099_090` nudged to launch** |
| #437 | askeladd | SOAP precond_freq schedule | C TERMINAL −1.27σ WINNER; **P2 n=4 `h8g04vyb` running ~21%** |
| #428 | frieren | SOAP β₂ static sweep | A–D complete; **Cell E `zj5qoyzq` (β₂=0.98) running ~53%** |
| #422 | edward | Muon WD shape variants | **P2 n=4 `ob6ek9zt` running ~69%** |


## Recent Closures (polls #242–245)

- **#427 nezuko Muon WD per-block decomp** — CLOSED clean-NEG (poll #245). Cell E asym heavy-MLP +4.56σ. All variants worse than ctrl; MLP WD dominant, asymmetric decomposition adds no value.
- **#426 thorfinn LR schedule shape** — CLOSED clean-NEG (poll #244). Cell E (stable_then_sq) +15.43σ. All 5 variants worse than ctrl. Linear cliff remains optimal.
- **#423 fern WD peak sensitivity** — CLOSED clean-NEG (poll #243). Peak=0.050 optimal; asymmetric bowl.
- **#418 alphonse AdamW β corner** — CLOSED clean-NEG (poll #242).
- **#432, #398, #368, #346, #383, #382** — all previously closed.


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. Two winner candidates in P2.

**"Less intensity in cooldown" principle — confirmed across 3 axes:**
- **PR #371 (WINNER):** Muon WD ramp_down → zero WD at end
- **Edward #422 Cell C `stable_only` (P2 in progress):** cliff to zero WD at cooldown start
- **Askeladd #437 Cell C `ramp_down_8_64` (P2 directed):** less frequent SOAP precond in cooldown
- **Thorfinn #426 (closed NEG):** LR shape — linear cliff remains optimal (no improvement from smooth LR)

**Active fresh mechanism threads:**
- **nezuko #467:** SOAP trust threshold — controls Muon fallback gate; entirely untested axis; no code change needed (flag + telemetry already exist)
- **thorfinn #461:** NS iteration count (6/8/10/12/14) — fundamental Muon mechanism parameter
- **fern #457:** cooldown_frac re-sweep on NEW baseline
- **alphonse #455:** AdamW aux WD axis (embed/lm_head/scalars currently at WD=0)

**SOAP β₂ axis (frieren #428):** Flat in {0.80..0.90}; 0.95 clearly NEG (+2.00σ). Cell E (0.98) running — if also NEG, axis closes; β₂ scheduling may be queued.

**tanjiro #445 Muon mu schedule:** Cell B `ramp_up_0_1` catastrophic (+11.29σ NEG). Cell C `ramp_down_099_090` nudged to launch — a mild mu ramp-down during training.

**Key variance calibration:** Single-seed ctrl repros frequently land ±2σ from n=4 mean. Always require P2 n=4 before claiming winner.

**Candidate next hypotheses (queue after current batch):**
- **Asymmetric per-group WD schedule** (MLP `stable_only` + attn `ramp_down`) — if edward P2 passes, compound the per-group insight
- **SOAP β₂ schedule** (ramp_down) — pending frieren static sweep result
- **Adaptive Muon LR decay timing** — coupling LR schedule to gradient norm
- **Precond_freq schedule variants** — finer grid around 8→64 winner (askeladd axis continuation)
- **NS iter scheduling** — ramp down iterations during cooldown (follow-up if thorfinn static sweep shows interesting variation)
