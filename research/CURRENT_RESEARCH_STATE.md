# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~18:55Z (poll #260)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ Active Winner Candidates (P2 in progress)

### #1 EDWARD #422 — Cell C `stable_only` WD: ⭐ **n=2 PASSES, ON TRACK FOR WINNER** ⭐
- **Mechanism:** WD=0 during entire cooldown phase (cliff at cooldown start). Less cumulative cooldown WD = better val.
- **P2 n=4 results so far:**
  - **Trial 1 TERMINAL:** val=**3.265809**, ffs=**3000**
  - **Trial 2 TERMINAL:** val=**3.265615**, ffs=**3000** ✓ CONFIRMED
  - **n=2 mean = 3.265712, std = 0.000137 (TIGHT)**, both ffs=3000 (100 steps faster than baseline)
- **Trial 3 (idx 2) running:** train/step 2618/3250 (81%), ~58 min from terminal
- **Trial 4 not yet started:** ~6 hr from terminal
- **Gate:** mu_p2 ≤ 3.265948 (n=4). n=2 mean already passes by 0.000236; trials 3+4 need to avg ≤ 3.266184 — high probability given trials 1+2 came in at 3.2656.

### #2 ASKELADD #437 — Cell C `ramp_down_8_64` precond_freq: −1.27σ (n=1) — **P2 LIKELY FAILING**
- **Cell C single-trial:** val=3.266906, ffs=3075 — beat baseline on BOTH metrics
- **Mechanism:** SOAP precond_freq ramps down (8→64 updates per step). Cross-axis confirmation of "less intensity in cooldown" principle.
- **P2 n=4 LAUNCHED.** Run `h8g04vyb`. n=2 results so far identical:
  - **Trial 1 TERMINAL:** val=3.2680, ffs=3100 (+0.06σ above baseline mu)
  - **Trial 2 TERMINAL:** val=3.2680, ffs=3100 (identical to trial 1, +0.06σ)
  - **Trial 3 (idx 2) starting** ~step 63
- **Gate analysis:** n=2 mean=3.2680 already above mu=3.267948. For n=4 gate (mu_p2 ≤ 3.265948), trials 3+4 must average ≤ 3.2639 — very unlikely given trials 1+2 came in identical at 3.2680. Single-trial Cell C result was likely a positive variance draw.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #472 | frieren | SOAP scope ablation (MLP+ATTN / MLP-only / ATTN-only / none) | A TERMINAL ctrl val=3.2670 ffs=3100 (−1.15σ); **B `hpmoe4v4` (MLP-only) step 250; C smoke `lvzj4zsz` starting** |
| #467 | nezuko | SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8) | A val=3.2669 ffs=3075; **Cell B `sbroalg6` (trust=0.1) LAUNCHED step 255 — watcher recovered!** (`1ufeapa2` ctrl-dup also still alive at step 875) |
| #461 | thorfinn | NS iteration count sweep (6/8/10/12/14) | A TERMINAL ctrl val=3.2662 ffs=3075; **Cell B `mv7ee25g` (ns_iter=6) running step 127** |
| #457 | fern | cooldown_frac sweep (0.3/0.5/0.7/0.85/1.0) | A val=3.26757 ffs=3100; B (0.3) val=3.2790 ffs=3225 (+13.4σ NEG); **Cell C `sr1uguv4` (cooldown_frac=0.5) running step 251** |
| #455 | alphonse | AdamW aux WD sweep (wd_aux=0/0.0025/0.025 × constant/ramp_down) | A (rd, wd_aux=0) val=3.2672 (−0.66σ); B (rd, 0.0025) val=3.2675 ffs=3100 (−0.54σ); **Cell C `w5gsh5k2` (rd, 0.025) running step 337** |
| #473 | tanjiro | adam_embed LR sweep (0.05/0.1/0.3/0.6/1.0) | A TERMINAL ctrl (0.3) val=3.2664 ffs=3075 (−1.88σ re-anchor); **Cell B `r41glyh7` (lr=0.1) launched** |
| #437 | askeladd | SOAP precond_freq schedule | C −1.27σ WINNER → **P2 LIKELY FAILING** (T1+T2 both val=3.2680 ffs=3100, n=2 mean=3.2680 above mu); T3 starting |
| #422 | edward | Muon WD shape variants | ⭐ **P2 n=2 PASS** (T1=3.265809, T2=3.265615, both ffs=3000); T3 81% (~58min); T4 ~6hr; **on track for n=4 winner** |


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
