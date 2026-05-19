# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~13:55Z (poll #248)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ Active Winner Candidates (P2 in progress)

### #1 EDWARD #422 — Cell C `stable_only` WD: −1.60σ (n=1)
- **Mechanism:** WD=0 during entire cooldown phase (cliff at cooldown start). Less cumulative cooldown WD = better val.
- **P2 n=4 LAUNCHED:** edward running `--num_trials 4 --wd_schedule stable_only`. Run `ob6ek9zt`. Trial 1 ffs=3000 (better than baseline 3100!); trial 2 at step ~955.
- **Gate:** mu_p2 ≤ 3.265948

### #2 ASKELADD #437 — Cell C `ramp_down_8_64` precond_freq: −1.27σ (n=1)
- **val=3.266906, ffs=3075** — beats baseline on BOTH metrics
- **Mechanism:** SOAP precond_freq ramps down (8→64 updates per step), less frequent precond during cooldown = better. CROSS-AXIS CONFIRMATION of "less intensity in cooldown" principle.
- **P2 n=4 LAUNCHED (poll #244).** Run `h8g04vyb`. Step ~2733, progressing.
- **Gate:** mu_p2 ≤ 3.265948


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #472 | frieren | SOAP scope ablation (MLP+ATTN / MLP-only / ATTN-only / none) | **NEW — add `--no_soap_mlp` flag; Cell A (ctrl) first** |
| #467 | nezuko | SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8) | **Cell A `y9fsimjv` running ~41%** |
| #461 | thorfinn | NS iteration count sweep (6/8/10/12/14) | **Cell A `zcpp564w` running ~36%** |
| #457 | fern | cooldown_frac sweep (0.3/0.5/0.7/0.85/1.0) | Cell A TERMINAL val=3.26757 ffs=3100; **Cell B `el26535y` (cooldown_frac=0.3) running ~24%** |
| #455 | alphonse | AdamW aux WD sweep (wd_aux=0/0.0025/0.025 × constant/ramp_down) | A TERMINAL −0.90σ ctrl; **Cell B `3tm0uy2a` (const tiny 0.0025) running ~10%** |
| #445 | tanjiro | Muon mu schedule sweep | A −3.67σ ctrl; B +11.29σ NEG; **C TERMINAL +8.11σ NEG** (ramp_down 0.99→0.90 very bad); Cell D chaining |
| #437 | askeladd | SOAP precond_freq schedule | C −1.27σ WINNER; **P2 n=4 `h8g04vyb` running** |
| #422 | edward | Muon WD shape variants | **P2 n=4 `ob6ek9zt` trial 1 ffs=3000 ✓; trial 2 step ~955** |


## Recent Closures (polls #242–248)

- **#428 frieren SOAP β₂ static sweep** — CLOSED clean-NEG (poll #248). β₂ axis flat in {0.80..0.98} (all ±1σ); Cell D (β₂=0.95) +2.00σ outlier non-monotonic, likely seed noise. Axis closed.
- **#427 nezuko Muon WD per-block decomp** — CLOSED clean-NEG (poll #245). +4.56σ asym-heavy-MLP worst.
- **#426 thorfinn LR schedule shape** — CLOSED clean-NEG (poll #244). Linear cliff optimal.
- **#423 fern WD peak sensitivity** — CLOSED clean-NEG (poll #243). Peak=0.050 optimal.
- **#418 alphonse AdamW β corner** — CLOSED clean-NEG (poll #242).


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. Two winner candidates in P2.

**"Less intensity in cooldown" principle — confirmed across 3 axes:**
- **PR #371 (WINNER):** Muon WD ramp_down → zero WD at end
- **Edward #422 Cell C `stable_only` (P2):** cliff to zero WD at cooldown start; trial 1 ffs=3000 promising
- **Askeladd #437 Cell C `ramp_down_8_64` (P2):** less frequent SOAP precond in cooldown

**Muon mu schedule axis (tanjiro #445) — CLOSING NEG:**
- Any mu schedule change hurts: ramp_up 0→1: +11.29σ, ramp_down 0.99→0.90: +8.11σ
- Axis is clearly closed: mu=0.95 constant is optimal. Cell D still chaining but axis conclusion is clear.

**SOAP β₂ static axis (frieren #428) — CLOSED FLAT:** insensitive to β₂ in {0.80..0.98}; no winner.

**SOAP scope ablation (frieren #472 — NEW):** Critical fresh axis — does SOAP on MLP actually help? With `--soap_attn` + trust_threshold=0.0, every 2D weight uses SOAP. Muon NS is never invoked in current best config. Testing MLP-only / ATTN-only / no-SOAP to understand what SOAP actually contributes.

**Active fresh mechanism threads:**
- **nezuko #467:** SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8)
- **thorfinn #461:** NS iteration count (6/8/10/12/14)
- **fern #457:** cooldown_frac re-sweep on NEW baseline
- **alphonse #455:** AdamW aux WD axis (currently WD=0 for embed/lm_head/scalars)

**Key variance calibration:** Single-seed ctrl repros frequently land ±2σ from n=4 mean. Always require P2 n=4 before claiming winner.

**Candidate next hypotheses (queue after current batch):**
- **Compound edward+askeladd winners** — if both P2s pass, test stable_only WD + ramp_down_8_64 precond_freq together
- **Asymmetric per-group WD schedule** (MLP `stable_only` + attn `ramp_down`) — from edward P2 insight
- **Precond_freq finer grid** — around 8→64 winner (askeladd axis continuation)
- **NS iter scheduling** — follow-up if thorfinn static sweep shows variation
- **SOAP scope compound** — if frieren finds ATTN-only is better, combine with cooldown principle
