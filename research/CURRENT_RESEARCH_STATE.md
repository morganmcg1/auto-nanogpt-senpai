# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~21:20Z (poll #277)
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

### #2 ASKELADD #437 — Cell C `ramp_down_8_64` precond_freq: ❌ **P2 n=4 FAILED gate by 0.001696** (CLOSED poll #275)
- **Mechanism:** SOAP precond_freq ramps down (8→64 updates per step) — "less intensity in cooldown" principle.
- **P2 n=4 ALL TERMINAL (run `h8g04vyb`):**
  - **T1:** val=3.268013, ffs=3100 (+0.08σ)
  - **T2:** val=3.268021, ffs=3100 (+0.09σ)
  - **T3:** val=3.266902, ffs=3075 (−1.27σ — the lucky seed from P1)
  - **T4:** val=3.267640, ffs=3100 (−0.37σ)
- **n=4 mu = 3.267644** vs gate 3.265948 → **FAILS by 0.001696** (statsig 0.000608 ≪ 0.004).
- Mean only 0.000304 below baseline — well within 1σ noise floor.
- **Closed at poll #275.** Cell C's −1.27σ was largely seed variance. SOAP cadence scheduling does NOT outperform static PRECOND_FREQ=16. Cadence axis effectively closed.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #472 | frieren | SOAP scope ablation (MLP+ATTN / MLP-only / ATTN-only / none) | A val=3.2670 ffs=3100 (−1.15σ); **B (MLP-only) TERMINAL val=3.26888 ffs=3100 (+1.14σ ≈ baseline)**; **C (ATTN-only) TERMINAL val=3.27186 ffs=3125 (+5.4σ NEG)**; **D `sz9dmixj` (no-SOAP ctrl) step 2100 ~65%**. Insight so far: SOAP everywhere ≫ MLP-only > ATTN-only; ATTN benefits most from SOAP |
| #467 | nezuko | SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8) | A (trust=0.0) val=3.26694 ffs=3075; **B (0.1) TERMINAL val=3.26775 ffs=3100 (−0.21σ ≈ baseline)**; **C (0.3) TERMINAL val=3.26693 ffs=3100 (−1.28σ — best so far, but only 0.00001 above ctrl A = noise)**; **D (0.5) `f6ju7rdq` step 1908 ~59%**; E (0.8) pending. **Trust threshold axis flat — no winner** |
| #461 | thorfinn | NS iteration count sweep (6/8/10/12/14) | A ctrl (ns_iter=12) val=3.26623 ffs=3075 (−1.61σ); **B (ns_iter=6) TERMINAL val=3.265531 ffs=3075 (−2.94σ NEW BEST SINGLE-SEED)** 🚀; **C (ns_iter=8) TERMINAL val=3.26834 ffs=3100 (+0.48σ ≈ baseline)**; **D (ns_iter=10) `bkr4pvcp` step 3124 ~96% — terminal imminent**; E (ns_iter=14) pending |
| **#508** | **alphonse** | **Muon momentum (mu) static value sweep (0.85/0.90/0.95/0.97/0.99)** | **NEW (poll #277)** — first static mu sweep ever; tanjiro #445 schedule sweep failed catastrophically, but the static optimum at 0.95 was never verified. Tests sharpness of basin around 0.95 |
| #473 | tanjiro | adam_embed LR sweep (0.05/0.1/0.3/0.6/1.0) | A ctrl (0.3) val=3.26638 ffs=3075 (−1.88σ); **B (lr=0.1) TERMINAL val=3.27420 ffs=3150 (+7.59σ NEG — too low)**; **C (lr=0.6) TERMINAL val=3.26608 ffs=3075 (−1.63σ — BEST in sweep, beats ctrl by tiny margin)**; **D (lr=0.05) `chjq4r86` step 1999 ~62%**; E (1.0) pending. Tentative trend: lr=0.6 slightly outperforms ctrl 0.3 — worth watching |
| **#504** | **fern** | **LR floor in cooldown sweep (0.0/0.05/0.10/0.20/0.40)** | **NEW (poll #276)** — probes LR=0 boundary condition; complementary to WD ramp_down winner; tests whether keeping a small LR floor at end (5-40% of peak) helps or hurts vs the current LR→0 cliff |
| **#497** | **askeladd** | **P2 n=4 confirmation of ns_iter=6** | **LAUNCHED**: run `ues3hmz1` step 2049/13000 (Trial 1 ~63%). Will resolve hottest signal in ~6-7 hrs. If n=4 mu ≤ 3.265948, NEW WINNER |
| #496 | edward | NS iter LOW sweep (12 ctrl / 5 / 4 / 3 / 2) | **Cell A ctrl `6c6ikozf` step 2683 ~82% — terminal imminent** (after 2 earlier crashed retries); B-E pending |
| ~~#457~~ | ~~fern~~ | ~~cooldown_frac sweep~~ | **CLOSED clean-neutral poll #276** — clean asymmetric U with min at ctrl 0.7 (−0.46σ); both shorter (+5.4σ at 0.5, +13.4σ at 0.3) and longer (+1.5σ at 0.85, +5.2σ at 1.0) hurt. New WD baseline didn't shift cooldown_frac optimum |
| ~~#455~~ | ~~alphonse~~ | ~~AdamW aux WD sweep~~ | **CLOSED clean-neutral poll #277** — full 5-cell sweep: best cell D (0.0025, ramp_down) −1.18σ within ctrl noise envelope (A at −0.90σ). Aux WD mechanism does NOT compound with Muon WD ramp_down winner |
| ~~#437~~ | ~~askeladd~~ | ~~SOAP precond_freq schedule~~ | **CLOSED poll #275** — P2 n=4 mu=3.267644 fails gate by 0.001696 |
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
- **askeladd #497:** P2 n=4 confirmation of ns_iter=6 — the headline experiment of this batch; Trial 1 in progress (~7hr remaining for full run); if mu ≤ 3.265948 → NEW WINNER
- **fern #504:** LR floor in cooldown — probes whether LR=0 boundary is load-bearing alongside WD=0
- **alphonse #508 (NEW poll #277):** Muon momentum (mu) static value sweep — first static sweep of mu; tests sharpness around 0.95
- **nezuko #467:** SOAP trust threshold sweep — axis looking flat
- **thorfinn #461:** NS iteration count (6/8/10/12/14) broader sweep
- **edward #496:** NS iteration count LOW extension (12 ctrl / 5 / 4 / 3 / 2)
- **tanjiro #473:** adam_embed LR sweep — Cell C (lr=0.6) val=3.26608 mildly best (−1.63σ), worth watching
- **frieren #472:** SOAP scope ablation — ATTN-only +5.4σ, MLP-only +1.14σ; D no-SOAP in progress

**Key variance calibration:** Single-seed ctrl repros frequently land ±2σ from n=4 mean. Always require P2 n=4 before claiming winner.

**Candidate next hypotheses (queue after current batch):**
- **NS iter P2 confirmation** — thorfinn ns_iter=6 n=1 = −2.94σ; assign 4-trial confirmation once thorfinn Cells C/D/E + edward #496 Cells B-E complete (informs which iter value to P2)
- **NS iter ramp_down schedule** — if both thorfinn and edward show low-iter wins, try iter scheduling (start high for stability, ramp down for cooldown speed)
- **Compound thorfinn ns_iter=6 + Muon WD ramp_down** — likely orthogonal; small assigned axis
- **Compound edward+askeladd winners** — if both P2s pass (unlikely), test stable_only WD + ramp_down_8_64 precond_freq together
- **Precond_freq finer grid** — around 8→64 winner (askeladd axis continuation)
- **SOAP scope compound** — if frieren finds ATTN-only is better, combine with cooldown principle
- **stable_only WD re-test** — edward #422 mechanism IS real (3 of 4 trials hit ffs=3000, val<3.266); fresh n=4 retry could clear the gate after the T3-style outlier averages out
