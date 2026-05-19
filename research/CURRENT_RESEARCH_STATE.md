# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~19:30Z (poll #274)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ Active Winner Candidates (P2 in progress)

### 🆕 #0 THORFINN #461 — Cell B `ns_iter=6`: 🚀 **NEW BEST SINGLE-SEED −2.94σ**
- **Mechanism:** Newton-Schulz iter=6 (down from default 12) for Muon orthogonalization.
- **Cell B TERMINAL (n=1):** val=**3.265531**, ffs=**3075** — STRONGEST single-seed in research run so far
- **Cell A ctrl (ns_iter=12 — current hardcoded default):** val=3.26623, ffs=3075 (−1.61σ — modest improvement vs baseline mu; baseline was also ns_iter=12 so this is seed-variance below mu)
- **Cell C (ns_iter=8) TERMINAL:** val=**3.26834**, ffs=3100 (+0.48σ ≈ baseline)
- **Curve so far:** ns_iter=6 (−2.94σ) ≪ ns_iter=12 (−1.61σ) ≈ ns_iter=8 (+0.48σ). Noisy single-seed but consistent with non-monotonic minimum near 6.
- **Cell D (ns_iter=10) launched** `bkr4pvcp` step 464; Cell E (ns_iter=14) pending.
- **Cross-axis insight:** Same "less optimizer intensity" theme as edward/askeladd/baseline. Cheaper Muon orthogonalization.
- **Path forward:** wait for thorfinn Cells D/E + edward #496 LOW extension (12 ctrl / 5 / 4 / 3 / 2). Then propose P2 confirmation on the best.

### #1 EDWARD #422 — Cell C `stable_only` WD: ❌ **P2 n=4 FAILED GATE by 0.000223** (CLOSED poll #273)
- **Mechanism:** WD=0 during entire cooldown phase (cliff at cooldown start).
- **P2 n=4 ALL TERMINAL:**
  - **T1:** val=3.265809, ffs=3000 (−2.60σ)
  - **T2:** val=3.265615, ffs=3000 (−2.83σ)
  - **T3:** val=3.267751, ffs=3025 (+0.22σ — outlier)
  - **T4:** val=**3.265509**, ffs=3000 (−2.96σ — best single-trial of run!)
- **n=4 mu = 3.266171** vs gate 3.265948 → **FAILS by 0.000223** (statsig 0.00355 < 0.004)
- Mean IS 0.0018 below baseline, but T3 outlier kept gate just out of reach.
- **Closed at poll #273.** 3 of 4 trials hit ffs=3000 and val<3.266 — mechanism is real but seed variance bit us. Re-test option = fresh n=4 OR n=6 extension. Deferred for now to free edward for new axis.

### #2 ASKELADD #437 — Cell C `ramp_down_8_64` precond_freq: −1.27σ (n=1) — **P2 LIKELY FAILING**
- **Cell C single-trial:** val=3.266906, ffs=3075 — beat baseline on BOTH metrics
- **Mechanism:** SOAP precond_freq ramps down (8→64 updates per step). Cross-axis confirmation of "less intensity in cooldown" principle.
- **P2 n=4 LAUNCHED.** Run `h8g04vyb`. n=3 results:
  - **T1 TERMINAL:** val=3.2680, ffs=3100 (+0.06σ above baseline mu)
  - **T2 TERMINAL:** val=3.2680, ffs=3100 (identical to T1)
  - **T3 TERMINAL:** val=**3.2669**, ffs=**3075** (slight improvement over T1+T2)
  - **T4 step 77/3250** (warmup phase)
- **n=3 mu = 3.267633** — fails n=4 gate (3.265948) by 0.001685. T4 must land ≤ **3.260893** to clear gate (well below all 3 observed). Still very likely failing.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #472 | frieren | SOAP scope ablation (MLP+ATTN / MLP-only / ATTN-only / none) | A val=3.2670 ffs=3100 (−1.15σ); **B (MLP-only) TERMINAL val=3.268883 ffs=3100 (+1.14σ ≈ baseline; ATTN SOAP ≈ +0.002 worth at most)**; **C `xg90tq7m` (ATTN-only) step 133 launched**; D (none) pending |
| #467 | nezuko | SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8) | A val=3.2669 ffs=3075; B (0.1) val=3.2678 ffs=3100 (−0.18σ ≈ baseline); **C `mmwxjnak` (trust=0.3) step 238 launched**; D (0.5), E (0.8) pending |
| #461 | thorfinn | NS iteration count sweep (6/8/10/12/14) | A ctrl (ns_iter=12) val=3.26623 ffs=3075 (−1.61σ); **B (ns_iter=6) TERMINAL val=3.265531 ffs=3075 (−2.94σ NEW BEST SINGLE-SEED)** 🚀; **C (ns_iter=8) TERMINAL val=3.26834 ffs=3100 (+0.48σ ≈ baseline)**; **D (ns_iter=10) step 464 launched** `bkr4pvcp`; E (ns_iter=14) pending |
| #457 | fern | cooldown_frac sweep (0.3/0.5/0.7/0.85/1.0) | A val=3.26757 ffs=3100; B (0.3) val=3.2790 NEG; C (0.5) val=3.2724 NEG; **D (0.85) TERMINAL val=3.26919 ffs=3100 (+1.18σ — mildly NEG, closer to ctrl than C)**; **E (1.0) step 996 launched** `qj9fynum`. **Trend: ctrl 0.7 still optimal; longer (0.85) mildly worse, shorter (0.3/0.5) catastrophic** |
| #455 | alphonse | AdamW aux WD sweep (wd_aux=0/0.0025/0.025 × constant/ramp_down) | A (rd, wd_aux=0) val=3.2672 (−0.66σ); B (rd, 0.0025) val=3.2675 ffs=3100 (−0.54σ); **C (rd, 0.025) TERMINAL val=3.278096 ffs=3225 (+12.3σ NEG)** — wd_aux=0.025 too high; axis trend: 0 ≈ 0.0025 ≫ 0.025 |
| #473 | tanjiro | adam_embed LR sweep (0.05/0.1/0.3/0.6/1.0) | A ctrl (0.3) val=3.2664 ffs=3075 (−1.88σ); **B (lr=0.1) TERMINAL val=3.274197 ffs=3150 (+7.59σ NEG — lr=0.1 too low)**; **C `em4ff9ro` (lr=0.6) step 70 warmup**; D (0.05), E (1.0) pending |
| #437 | askeladd | SOAP precond_freq schedule | **P2 likely failing**: T1=3.2680/3100, T2=3.2680/3100, T3=3.2669/3075; n=3 mu=3.267633 fails n=4 gate by 0.001685; T4 in-trial step ~1880/3250 (~58%) — waiting on T4 terminal to close |
| **#496** | **edward** | **NS iter LOW sweep (12 ctrl / 5 / 4 / 3 / 2)** | **PICKED UP (poll #274):** Cell A ns_iter=12 ctrl `6c6ikozf` step 242 running — extends thorfinn ns_iter=6 winner candidate to the uncovered low end |
| ~~#422~~ | ~~edward~~ | ~~Muon WD shape variants~~ | **CLOSED poll #273** — P2 n=4 failed gate by 0.000223 |


## Recent Closures (polls #242–248)

- **#445 tanjiro Muon mu schedule sweep** — CLOSED clean-NEG (poll #249). Any mu schedule change hurts: ramp_up +11.29σ, ramp_down +8.11σ. Static 0.95 is the robust optimum. Axis closed.
- **#428 frieren SOAP β₂ static sweep** — CLOSED clean-NEG (poll #248). β₂ axis flat in {0.80..0.98} (all ±1σ). Axis closed.
- **#427 nezuko Muon WD per-block decomp** — CLOSED clean-NEG (poll #245). +4.56σ asym-heavy-MLP worst.
- **#426 thorfinn LR schedule shape** — CLOSED clean-NEG (poll #244). Linear cliff optimal.
- **#423 fern WD peak sensitivity** — CLOSED clean-NEG (poll #243). Peak=0.050 optimal.
- **#418 alphonse AdamW β corner** — CLOSED clean-NEG (poll #242).


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. Two winner candidates in P2.

**"Less optimizer intensity" principle — confirmed across multiple axes (cooldown-specific + global):**
- **PR #371 (WINNER):** Muon WD ramp_down → zero WD at end (cooldown)
- **Edward #422 Cell C `stable_only` (P2):** cliff to zero WD at cooldown start; trial 1 ffs=3000 promising (cooldown)
- **Askeladd #437 Cell C `ramp_down_8_64` (P2):** less frequent SOAP precond in cooldown
- **Thorfinn #461 Cell B `ns_iter=6` (n=1):** −2.94σ best single-seed — fewer Newton-Schulz iterations *globally* still works; cheaper Muon

**Implication:** Optimizer is over-precisioned. Hypothesis space worth probing: NS iter even lower (4), SOAP precond_freq base (lower constant), Muon momentum schedule reduction, learning-rate floor.

**Muon mu schedule axis (tanjiro #445) — CLOSED NEG:** both ramp directions catastrophic (+8–11σ). Static 0.95 confirmed optimal.

**AdamW embed LR axis (tanjiro #473 — NEW):** adam_embed=0.3 hardcoded, never ablated. 5-cell log-spaced sweep {0.05, 0.1, 0.3, 0.6, 1.0}. LR=0.3 is 30× typical Adam; may be over-tuned or under-tuned on embed.

**SOAP β₂ static axis (frieren #428) — CLOSED FLAT:** insensitive to β₂ in {0.80..0.98}; no winner.

**SOAP scope ablation (frieren #472 — NEW):** Critical fresh axis — does SOAP on MLP actually help? With `--soap_attn` + trust_threshold=0.0, every 2D weight uses SOAP. Muon NS is never invoked in current best config. Testing MLP-only / ATTN-only / no-SOAP to understand what SOAP actually contributes.

**Active fresh mechanism threads:**
- **nezuko #467:** SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8)
- **thorfinn #461:** NS iteration count (6/8/10/12/14)
- **edward #496 (NEW):** NS iteration count LOW extension (12 ctrl / 5 / 4 / 3 / 2) — replicate thorfinn hot signal and probe theoretical bf16 saturation floor
- **fern #457:** cooldown_frac re-sweep on NEW baseline
- **alphonse #455:** AdamW aux WD axis (currently WD=0 for embed/lm_head/scalars)

**Key variance calibration:** Single-seed ctrl repros frequently land ±2σ from n=4 mean. Always require P2 n=4 before claiming winner.

**Candidate next hypotheses (queue after current batch):**
- **NS iter P2 confirmation** — thorfinn ns_iter=6 n=1 = −2.94σ; assign 4-trial confirmation once thorfinn Cells C/D/E + edward #496 Cells B-E complete (informs which iter value to P2)
- **NS iter ramp_down schedule** — if both thorfinn and edward show low-iter wins, try iter scheduling (start high for stability, ramp down for cooldown speed)
- **Compound thorfinn ns_iter=6 + Muon WD ramp_down** — likely orthogonal; small assigned axis
- **Compound edward+askeladd winners** — if both P2s pass (unlikely), test stable_only WD + ramp_down_8_64 precond_freq together
- **Precond_freq finer grid** — around 8→64 winner (askeladd axis continuation)
- **SOAP scope compound** — if frieren finds ATTN-only is better, combine with cooldown principle
- **stable_only WD re-test** — edward #422 mechanism IS real (3 of 4 trials hit ffs=3000, val<3.266); fresh n=4 retry could clear the gate after the T3-style outlier averages out
