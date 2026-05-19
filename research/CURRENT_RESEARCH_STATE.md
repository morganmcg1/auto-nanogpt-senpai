# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~16:20Z (poll #254)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ Active Winner Candidates (P2 in progress)

### #1 EDWARD #422 — Cell C `stable_only` WD: −1.60σ (n=1)
- **Mechanism:** WD=0 during entire cooldown phase (cliff at cooldown start). Less cumulative cooldown WD = better val.
- **P2 n=4 LAUNCHED:** edward running `--num_trials 4 --wd_schedule stable_only`. Run `ob6ek9zt`.
  - **Trial 1 (idx 0) TERMINAL:** val=3.2658, ffs=3000 → −2.61σ on n=1 (beats baseline on BOTH metrics).
  - **Trial 2 (idx 1) running:** step ~3122/3250, current best_val=3.2720 — terminal in ~8 min.
- **Gate:** mu_p2 ≤ 3.265948. So far so good — trial 1 well below gate, trial 2 hovering near it.

### #2 ASKELADD #437 — Cell C `ramp_down_8_64` precond_freq: −1.27σ (n=1)
- **Cell C single-trial:** val=3.266906, ffs=3075 — beats baseline on BOTH metrics
- **Mechanism:** SOAP precond_freq ramps down (8→64 updates per step), less frequent precond during cooldown = better. CROSS-AXIS CONFIRMATION of "less intensity in cooldown" principle.
- **P2 n=4 LAUNCHED (poll #244).** Run `h8g04vyb`.
  - **Trial 1 (idx 0) TERMINAL:** val=3.2680, ffs=3100 → −0.06σ on n=1 (essentially baseline mean — single-trial winner regressing).
  - **Trial 2 (idx 1) running:** step ~1622/3250, current val=3.5333. ~108 min from trial 2 terminal.
- **Gate:** mu_p2 ≤ 3.265948. Already in trouble — trial 1 lands at mu, leaves ZERO margin. P2 likely fails unless trials 2-4 land well below 3.266.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #472 | frieren | SOAP scope ablation (MLP+ATTN / MLP-only / ATTN-only / none) | **Cell A `qcycy1e9` running ~42% (smokes passed)** |
| #467 | nezuko | SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8) | A val=3.2669 ffs=3075; **WATCHER STALLED 80+ min — diagnostic comment posted on PR; `1ufeapa2` advancing (step 560) but still trust=0** |
| #461 | thorfinn | NS iteration count sweep (6/8/10/12/14) | A TERMINAL ctrl val=3.2662 ffs=3075; **Cell B `mv7ee25g` (ns_iter=6) running step 127** |
| #457 | fern | cooldown_frac sweep (0.3/0.5/0.7/0.85/1.0) | A val=3.26757 ffs=3100; B (0.3) val=3.2790 ffs=3225 (+13.4σ NEG); **Cell C `sr1uguv4` (cooldown_frac=0.5) running step 251** |
| #455 | alphonse | AdamW aux WD sweep (wd_aux=0/0.0025/0.025 × constant/ramp_down) | A (rd, wd_aux=0) val=3.2672 (−0.66σ); B (rd, 0.0025) val=3.2675 ffs=3100 (−0.54σ); **Cell C `w5gsh5k2` (rd, 0.025) running step 337** |
| #473 | tanjiro | adam_embed LR sweep (0.05/0.1/0.3/0.6/1.0) | **Cell A `74k60vo3` running ~41% (smokes passed)** |
| #437 | askeladd | SOAP precond_freq schedule | C −1.27σ WINNER; **P2 trial 1 val=3.2680 ffs=3100 at-mu; trial 2 train/step 2790/3250 (~42 min from trial 2 terminal)** |
| #422 | edward | Muon WD shape variants | **P2 trial 1 TERMINAL val=3.2656 ffs=3000 ✓ (−2.61σ); trial 2 train/step 999/3250 (~72 min from trial 2 terminal)** |


## Recent Closures (polls #242–248)

- **#445 tanjiro Muon mu schedule sweep** — CLOSED clean-NEG (poll #249). Any mu schedule change hurts: ramp_up +11.29σ, ramp_down +8.11σ. Static 0.95 is the robust optimum. Axis closed.
- **#428 frieren SOAP β₂ static sweep** — CLOSED clean-NEG (poll #248). β₂ axis flat in {0.80..0.98} (all ±1σ). Axis closed.
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

**Muon mu schedule axis (tanjiro #445) — CLOSED NEG:** both ramp directions catastrophic (+8–11σ). Static 0.95 confirmed optimal.

**AdamW embed LR axis (tanjiro #473 — NEW):** adam_embed=0.3 hardcoded, never ablated. 5-cell log-spaced sweep {0.05, 0.1, 0.3, 0.6, 1.0}. LR=0.3 is 30× typical Adam; may be over-tuned or under-tuned on embed.

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
