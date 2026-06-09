# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-09 ~16:50 UTC — **H-FC MECHANISM FALSIFIED (PR #2421 closed); H-FD per-group β₂ pulse ablation assigned (PR #2422 alphonse). Fleet: 8/8 active.**

  **KEY MECHANISM RESULT:** H-FC (explicit v warm-restart at step 820) caused catastrophic +6.33 val_loss spike. This **definitively proves the H-EJ rank-1 mechanism is smoothing-rate change, NOT v-reset**. v-reset class mechanisms are deprioritized. Future mechanism exploration should target smoothing-dynamics, per-group differentiation, and Muon-side analogs.

  **H-FD per-group ablation (PR #2422, alphonse):**  localizes *which AdamW group* drives the β₂ pulse benefit:
  - Arm A: embed ONLY (expect: most likely winner — largest group, dominates loss surface)
  - Arm B: lm_head ONLY
  - Arm C: scalars ONLY

  **Amplitude axis FULLY CHARACTERIZED** (locked at 0.995, step 820):
  - ~~0.990~~ INFERIOR, ~~0.997~~ FALSIFIED, ~~0.999~~ FALSIFIED
  - **0.995 = RANK-1** (step 2850, n=4 mean 3.277780)

  **All 8 students active (zero idle):**

  | PR | Student | Hypothesis | Status |
  |---|---|---|---|
  | #2412 | tanjiro | H-EU STAIRCASE fractional generalization | Arm B running |
  | #2414 | fern | H-EV cross-axis (0.995, step=770) | n=4 running, ETA 17:00 UTC |
  | #2415 | frieren | H-EW cross-axis (0.995, step=870) | n=4 running, ETA 16:30 UTC |
  | #2416 | edward | H-EX cross-axis (0.995, step=720) | n=2 progressing |
  | #2418 | askeladd | H-EZ STAIRCASE-DESCENT 0.995→0.99@cooldown | n=4 ETA 20:02 UTC |
  | #2419 | thorfinn | H-FA STAIRCASE-PEAK-AT-COOLDOWN | Pickup pending |
  | #2420 | nezuko | H-FB STAIRCASE-ASCENT 0.95→0.99@410→0.995@820 | Pickup pending |
  | #2422 | **alphonse** | **H-FD per-group β₂ pulse ablation (embed/lm_head/scalars)** | **Just assigned** |

  **4-cell staircase trajectory ablation IN FLIGHT:**

  | trajectory | pre-820 | high (820-cd) | cooldown |
  |---|---|---|---|
  | **RANK-1 H-EJ** | 0.95 | **0.995** | **0.995** |
  | H-EZ DESCENT (#2418) | 0.95 | 0.995 | 0.99 |
  | H-FA PEAK-COOLDOWN (#2419) | 0.95 | 0.99 | 0.995 |
  | H-FB ASCENT (#2420) | 0.95→0.99@410 | 0.995 | 0.995 |

  **Cross-axis step grid (amp=0.995) IN FLIGHT:**
  - (0.995, 720): edward PR #2416 [n=2]
  - (0.995, 770): fern PR #2414 [n=4 ETA 17:00 UTC]
  - **(0.995, 820): RANK-1 ✓**
  - (0.995, 870): frieren PR #2415 [n=4 ETA 16:30 UTC]

  **Fractional generalization IN FLIGHT (tanjiro PR #2412):**
  - Arm A frac=0.25 (step 723) n=2 STRONG: step 2875 = 3.276165 PASSES n=2 ≤ 3.277172
  - Arm B frac=0.30 running

  **Next-direction queue:**
  - If H-FD embed-only matches rank-1: mechanism is localized → target embed smoothing in future experiments
  - If staircase ablation finds winner: compound with rank-1 merge and push for step 2825
  - If cross-axis finds step<820 winner: rerun amplitude search at new step

---

- **As of:** 2026-06-09 ~14:40 UTC — **PR #2411 nezuko H-EQ LATER-basin CLOSED INFERIOR/FALSIFIED (~+0.00089 worse than rank-1 at every step); H-FB STAIRCASE-ASCENT assigned (PR #2420).**

  Two terminal closures this cycle from the amp=0.99 axis confirm: amp=0.99 cannot beat amp=0.995. The amplitude axis dominates the step axis. Both #2410 (step=970) and #2411 (step=1156) had seed 4 outliers (~+0.0025 above seeds 1/2/3) suggesting amp=0.995 also has tighter seed dispersion as a side benefit.

  **All 8 students now active (zero idle):**

  | PR | Student | Hypothesis | Status |
  |---|---|---|---|
  | #2412 | tanjiro | H-EU STAIRCASE fractional generalization (Arm B frac=0.30) | T1 ~15:50 UTC |
  | #2414 | fern | H-EV cross-axis (0.995, step=770) | T0 done 3.27871; T1 ~13:46 UTC |
  | #2415 | frieren | H-EW cross-axis (0.995, step=870) | T0 done 3.27863; T1 ~13:55 UTC |
  | #2416 | edward | H-EX cross-axis (0.995, step=720) | T0 done 3.27887; T1 ~14:25 UTC |
  | #2417 | alphonse | H-EY (0.997, step=820) amplitude bisection | T0 imminent ~14:40 UTC |
  | #2418 | askeladd | H-EZ STAIRCASE-995-DESCENT 0.995→0.99@cooldown | n=4 in flight; ETA ~14:11 UTC for T0 |
  | #2419 | thorfinn | H-FA STAIRCASE-PEAK-AT-COOLDOWN 0.99 plateau→0.995 cooldown | Just assigned 13:25 UTC |
  | #2420 | nezuko | **H-FB STAIRCASE-ASCENT 0.95→0.99@410→0.995@820** | **Just assigned** |

  **4-cell staircase trajectory ablation (peak β₂=0.995 @ step 820):**

  | trajectory | low (0-409) | mid (410-819) | high (820-cd) | cooldown |
  |---|---|---|---|---|
  | **RANK-1 H-EJ (two-stage)** | 0.95 (0-819) | — | **0.995** (820-cd) | **0.995** |
  | H-EZ DESCENT (askeladd #2418) | 0.95 | — | 0.995 | 0.99 (drops) |
  | H-FA PEAK-COOLDOWN (thorfinn #2419) | 0.95 | — | 0.99 (low peak) | 0.995 |
  | **H-FB ASCENT (nezuko #2420)** | **0.95** | **0.99** | **0.995** | **0.995** |

  These 4 cells dissect two axes of trajectory shape:
  - **WHERE peak amp=0.995 lives:** H-EJ holds it through plateau+cooldown; H-EZ drops it in cooldown; H-FA elevates only during cooldown.
  - **HOW the trajectory enters the peak:** H-EJ does a direct jump 0.95 → 0.995; H-FB does a graduated ramp via 0.99.

  Combined with the cross-axis grid (step axis at amp=0.995) and amplitude bisection (0.997 between rank-1 and FALSIFIED 0.999), this fully characterizes the local landscape of β₂ schedule shapes.

  **Cross-axis grid status — locked down around rank-1 (0.995, 820):**
  - (0.995, 720): edward PR #2416 [T0 done — val/loss step 2850 = 3.27887 worse than rank-1 mean; trial 1 ~14:25 UTC]
  - (0.995, 770): fern PR #2414 [T0 done — val/loss step 2850 = 3.27871; trial 1 ~13:46 UTC]
  - **(0.995, 820): PR #2405 RANK-1 ✓** (n=4 mean step 2850 = 3.277780)
  - (0.995, 870): frieren PR #2415 [T0 done — val/loss step 2850 = 3.27863; trial 1 ~13:55 UTC]
  - (0.997, 820): alphonse PR #2417 [trial 0 step 2311/2890, val_loss=3.36 at step 2250 — running clean after duplicate kill]
  - ~~(0.999, 820)~~: PR #2413 [CLOSED — FALSIFIED]
  - ~~(amp=0.99 × step=970)~~: thorfinn PR #2410 [CLOSED — INFERIOR step 2875]
  - ~~(amp=0.99 × step=1156)~~: nezuko PR #2411 [CLOSED — INFERIOR step 2875, ~+0.00089 worse]
  - **STAIRCASE-995-DESCENT**: askeladd PR #2418 [n=4 in flight]
  - **STAIRCASE-PEAK-COOLDOWN**: thorfinn PR #2419 [pending pickup]
  - **STAIRCASE-ASCENT**: nezuko PR #2420 [pending pickup]
  - **STAIRCASE generalization (fractional)**: tanjiro PR #2412 [Arm A frac=0.25 done — n=2 mean step 2875 = 3.276165 viable; Arm B running]

  **Track 1 (speedrun optimization — next target step 2825):** Need n=4 mean ≤ 3.278 at step 2825. Rank-1 hits 3.279596 at step 2825 (misses by 0.0016). Cross-axis grid is most likely to push step 2825 across via earlier-pulse cells; H-EZ/H-FA/H-FB staircase variants test whether shape can reduce variance enough.

  **Next-direction queue (post-plateau triggers):**
  - If staircase 4-cell ablation finds NO winner over rank-1: pivot to NEW mechanism class (e.g., AdamW eps schedule, Muon NS coefficient schedule, RI dual capture, layer-wise β₂)
  - If cross-axis grid finds NO step<820 winner: amplitude bisection (0.996, 0.998) brackets locked
  - If amplitude bisection finds NO 0.997 winner: 0.995 is the precise peak — pivot to compound (β₂ × ε schedule joint pulse)

---

- **As of:** 2026-06-09 ~13:25 UTC — **PR #2410 thorfinn H-EO canonical step=970 CLOSED INFERIOR (step 2875 only); H-FA STAIRCASE-PEAK-AT-COOLDOWN assigned.** Per-seed n=4: seeds 1/2/3 strong (n=3 mean step 2850 = 3.277504 would have passed n=3 threshold), but seed 4 outlier (val/loss 3.282584 at step 2850, never hit 3.28) pulled n=4 above threshold at step 2850 (3.278774 > 3.278). Earliest official-valid step = 2875 vs rank-1 step 2850. Branch-rank diagnostic INCONCLUSIVE (+0.000150). Step-970 amp=0.99 cell does NOT push speedrun frontier; amplitude axis dominates step axis.

  **Thorfinn reassigned to H-FA STAIRCASE-PEAK-AT-COOLDOWN** (PR #2419) — β₂ 0.95 → **0.99 @ step 820** (moderate during plateau) → **0.995 @ step 1156** (peak during cooldown). Mirror of askeladd's H-EZ DESCENT. Completes 2×2 ablation matrix of high-amp placement:

  | | plateau β₂ | cooldown β₂ | source |
  |---|---|---|---|
  | RANK-1 H-EJ | 0.995 | 0.995 | PR #2405 MERGED ✓ |
  | H-EZ DESCENT (askeladd) | 0.995 | 0.99 | PR #2418 [running] |
  | **H-FA PEAK-COOLDOWN (thorfinn)** | **0.99** | **0.995** | **PR #2419 [just assigned]** |
  | H-EQ baseline (nezuko) | 0.95 | 0.99 | PR #2411 [running, trial 3] |

  Once H-EZ and H-FA land, we'll know whether peak amplitude β₂=0.995 helps MORE during plateau, MORE during cooldown, or both equally.

  **Cross-axis grid status — locked down around rank-1 (0.995, 820):**
  - (0.995, 720): edward PR #2416 [T0 done — val/loss step 2850 = 3.27887 worse than rank-1 mean; trial 1 ~14:25 UTC]
  - (0.995, 770): fern PR #2414 [T0 done — val/loss step 2850 = 3.27871; trial 1 ~13:46 UTC]
  - **(0.995, 820): PR #2405 RANK-1 ✓** (n=4 mean step 2850 = 3.277780)
  - (0.995, 870): frieren PR #2415 [T0 done — val/loss step 2850 = 3.27863; trial 1 ~13:55 UTC]
  - (0.997, 820): alphonse PR #2417 [trial 0 step 2311/2890, val_loss=3.36 at step 2250 — running clean after duplicate kill]
  - ~~(0.999, 820)~~: PR #2413 [CLOSED — FALSIFIED]
  - **(amp=0.99 × step=1156)**: nezuko PR #2411 [n=3 partial step 2850 = 3.277894 ≈ tied with rank-1 step 2850 + ~0.0001 worse; trial 3 ~14:19 UTC]
  - **STAIRCASE-995-DESCENT**: askeladd PR #2418 [smoke gate]
  - **STAIRCASE-PEAK-COOLDOWN**: thorfinn PR #2419 [just assigned]
  - **STAIRCASE generalization (fractional)**: tanjiro PR #2412 [Arm A frac=0.25 done — n=2 mean step 2875 = 3.276165 viable, matches PR #2403 baseline; Arm B frac=0.30 running, ETA 15:50 UTC]

  **Preliminary cross-axis T0 finding:** ALL fern/frieren/edward T0 single-seed val/loss at step 2850 are 3.2786-3.2789 — WORSE than rank-1 n=4 mean at step 2850 (3.277780). Consistent with inverted-U peak at step=820. Even if seeds 2/3 strong, n=2 partial unlikely to beat rank-1 at step 2850.

  **Track 1 (speedrun optimization — next target step 2825):** Need n=4 mean ≤ 3.278 at step 2825. Rank-1 hits 3.279596 at step 2825 (misses by 0.0016). Cross-axis grid is most likely to push step 2825 across via earlier-pulse cells; H-EZ/H-FA staircase variants test whether shape can reduce variance enough.

  **Track 2 (generalization study):** tanjiro PR #2412 Arm A frac=0.25 result confirms fractional rule generalizes (matches PR #2403 baseline). Arm B will confirm whether 30% fraction also works.

  **Plateau check:** Not yet — 2 merges in last 8 cycles + 5+ in-flight terminals expected next 4 hours. Active 2D characterization of (amp × step × shape) landscape.

- **As of:** 2026-06-09 ~11:40 UTC — **PR #2413 askeladd amp=0.999 FALSIFIED; INVERTED-U amplitude curve confirmed.** Single completed trial (W&B dy9cdabc) hit val/loss 3.279641 at step 2890 — fails n=1 threshold (3.276) at ALL fixed steps, +0.006 worse than rank-1 seed 2 reference. **The amplitude lever has been characterized: 0.99 → step 2875 only; 0.995 → step 2850 (RANK-1); 0.999 → no official validity.** Peak at 0.995 (W≈200); pushing higher breaks adaptive moment tracking.

  **Askeladd reassigned to H-EZ: STAIRCASE-995-DESCENT** (PR #2418) — β₂ 0.95 → 0.995 (step 820, overshoot) → 0.99 (step 1156, cd_start settle). Combines proven STAIRCASE structure (PR #2403) with dominant amplitude 0.995. Tests whether SCHEDULE SHAPE (descent during cooldown) can reduce variance and push step 2825 across threshold (rank-1 currently misses by 0.0016 at step 2825).

  **Cross-axis grid status — locked down around rank-1 (0.995, 820):**
  - (0.995, 720): edward PR #2416 [running]
  - (0.995, 770): fern PR #2414 [running]
  - **(0.995, 820): PR #2405 RANK-1 ✓**
  - (0.995, 870): frieren PR #2415 [running]
  - (0.997, 820): alphonse PR #2417 [running — amplitude bisection]
  - ~~(0.999, 820)~~: askeladd PR #2413 [CLOSED — FALSIFIED, inverted-U peak confirmed]
  - **schedule-shape probe**: askeladd PR #2418 STAIRCASE-995-DESCENT [just assigned]

  **Track 1 (speedrun optimization — next target step 2825):** Need n=4 mean ≤ 3.278 at step 2825. Rank-1 hits 3.279596 at step 2825 (misses by 0.0016). Cross-axis (0.995 × earlier-pulse) cells most likely to push step 2825 across; H-EZ STAIRCASE-995-DESCENT tests whether late-cooldown amplitude descent (0.995 → 0.99) reduces variance enough to recover step 2825 even at the current pulse position.

  **Track 2 (generalization study):** tanjiro PR #2412 H-EU fraction-based pulse timing in flight. Thorfinn PR #2410 canonical step=970 n=4 confirm running (run `71390416`, mid-trial 2, ETA ~14:00-15:00 UTC).

  **Plateau check:** Not yet — 2 merges in last 8 cycles (STAIRCASE → H-EJ amplitude=0.995) and active frontier discovery. Amplitude axis now characterized; schedule-shape axis (STAIRCASE-995-DESCENT) and cross-axis grid cells (step ∈ {720, 770, 870}) still active.

- **As of:** 2026-06-09 ~10:15 UTC — **Cross-axis grid completion cycle.** Three (0.99 × pulse_step) PRs closed as INFERIOR to rank-1 PR #2405: frieren PR #2406 (step=770, official @ 2875), edward PR #2407 (step=870, official @ 2875), alphonse PR #2409 (eps-pulse, official @ 2890 only). Three new (amp=0.995 cross-axis × amp curve) PRs assigned: frieren PR #2415 (amp=0.995 × step=870), edward PR #2416 (amp=0.995 × step=720), alphonse PR #2417 (amp=0.997 × step=820 amplitude bisection). PR #2411 nezuko (amp=0.99 × step=1156) still running; ETA ~14:00 UTC; W&B sub-agent triage shows official-valid at step 2875 only — projected INFERIOR.

  **Cross-axis grid status — locked down around rank-1 (0.995, 820):**
  - (0.995, 720): edward PR #2416 [running]
  - (0.995, 770): fern PR #2414 [running]
  - **(0.995, 820): PR #2405 RANK-1 ✓**
  - (0.995, 870): frieren PR #2415 [running]
  - (0.997, 820): alphonse PR #2417 [running]
  - (0.999, 820): askeladd PR #2413 [running]

  **Track 1 (speedrun optimization — next target step 2825):** Need n=4 mean ≤ 3.278 at step 2825. Rank-1 hits 3.279596 at step 2825 (misses by 0.0016). The cross-axis cells (0.995 × earlier-pulse) are the most likely to push step 2825 across the threshold; the amplitude curve (0.997, 0.999) characterizes whether bidding amplitude higher continues monotone gain.

  **Track 2 (generalization study):** tanjiro PR #2412 H-EU fraction-based pulse timing in flight. Thorfinn PR #2410 canonical step=970 n=4 confirm running (run `71390416`, mid-trial 2, ETA ~14:00-15:00 UTC).

  **Plateau check:** Not yet — last 8 cycles produced 2 merges (STAIRCASE → H-EJ amplitude=0.995) and active frontier discovery. Cross-axis × amplitude space has 5-6 unexplored cells.

- **As of:** 2026-06-09 ~09:20 UTC — **✅ H-EJ MERGED (PR #2405) — NEW SPEEDRUN RANK-1 = step 2850** (−25 steps vs STAIRCASE). β₂ single-pulse 0.95→0.995 @ step 820, n=4 mean 3.277780, margin 0.004440. BASELINE.md updated. Two active tracks:

  **Track 1 (speedrun optimization — next target: step 2825):** Need n=4 mean ≤ 3.278 at step 2825. Currently step 2850 is new rank-1. Seed 2 of PR #2405 already hit 3.277865 at step 2825 (barely under threshold) — if amplitude=0.999 or earlier-pulse+0.995 combination tightens variance, step 2825 may be reachable.

  **Track 2 (generalization study — human directive 08:19 UTC):** tanjiro PR #2412 H-EU tests fraction-based pulse timing (frac=0.25 vs 0.30 vs 0.284 reference). Demonstrates mechanism is principled across budgets, not hardcoded step number.

  **Active next-amplitude probe:** askeladd H-EJ Arm B: target=0.999 (W≈1000) — the PR #2405 student explicitly suggested this as the next amplitude probe. Assignment in progress.

- **As of:** 2026-06-09 ~08:30 UTC — **✅ STAIRCASE MERGED (PR #2403) — speedrun rank-1 = step 2875 (now demoted to rank-2).**

  **Track 1 (speedrun optimization):** 6 students have n=4 confirms in flight that could push official-valid step below 2875 (to 2850 or 2825). askeladd PR #2405 is the strongest candidate: single-seed val/loss @ 2825 = 3.277865 (barely under n=4 threshold 3.278).

  **Track 2 (generalization study — NEW, human directive 08:19 UTC):** tanjiro PR #2412 H-EU assigned: tests fraction-based pulse timing to show STAIRCASE mechanism is principled (not lucky step number). Arm A: frac=0.25 → step 723. Arm B: frac=0.30 → step 867. Reference: frac=0.284 → step 820 (PR #2403).

  **All 8 students have work assigned (zero idle GPUs).** New speedrun record: step 2875, n=4 mean 3.276833 (margin 0.006335).

- **As of:** 2026-06-09 ~07:30 UTC — **🚨 HUMAN RULE-CHECK on Issue #2388 (07:16 UTC): officiality framing corrected.** The primary metric is **earliest fixed step ≤ 2890 at which `(3.28 − μ) × √n ≥ 0.004`** — NOT lowest final-2890 mean vs PR #2349. Per-n thresholds: n=1 ≤ 3.276000; n=2 ≤ 3.277172; n=3 ≤ 3.277691; n=4 ≤ 3.278000. Eval lattice 2825 / 2850 / 2875 / 2890. **Branch rank (final-2890) is a diagnostic, NOT a kill criterion.** Do not close a direction solely because final-2890 is worse than PR #2349 — it must also fail official at ALL fixed steps 2825/2850/2875/2890.

  **BASELINE.md reframed** (commit 51128b11). CURRENT correction cascade in flight: ALL 7 in-flight PRs will receive corrected-framing comments + fixed-step-history requests (harvest val/loss at 2825/2850/2875/2890 in SENPAI-RESULT).

  **Active gates (NEW, official framing):**
  - **Official-VALID at n=k** ⇔ mean ≤ per-n threshold at SOME fixed step ≤ 2890.
  - **Earliest official-valid step** = our speedrun score. Lower = better. PR #2349 is official at 2890 only (μ=3.276172, n=4 threshold = 3.278000 ✓).
  - **Local robustness policy:** prefer n=4 confirms for any merge candidate, but n=2 / n=3 official passes are KEPT ALIVE while n=4 in flight.
  - Branch-rank gates (still useful as diagnostics):
    - STRONG ≤ 3.275772 (clearly beats PR #2349 final-2890)
    - MERGE-eligible (3.275772, 3.276172] (matches/edges PR #2349 final-2890)
    - INCONCLUSIVE (3.276172, 3.276572)
    - "Diagnostic worse" ≥ 3.276572 — but check ALL fixed-step official passes before closing.

  **🚨 IN-FLIGHT STRONG SIGNALS (per latest student posts at ~06:14-07:25 UTC):**

  | PR | Student | Mechanism | n=k mean | Per-seed first_step_to_target | Branch class | Official class |
  |---:|---|---|---:|---|---|---|
  | #2402 | fern | step=720 | n=2 = **3.274656** (s1=3.275366, s2=3.273947) | not yet posted; var spread 0.001419 | STRONG | likely n=1 OV @ 2825 for s2 |
  | #2403 | tanjiro | STAIRCASE 820+1156 | n=3 = **3.275037** (3.27512, 3.27501, 3.27498) | **2825 for ALL 3 seeds** | STRONG (very tight var 0.00014) | **n=3 OFFICIAL-VALID @ step 2825** ✓ |
  | #2405 | askeladd | target=0.995 @820 | n=2 = 3.275966 (3.27659, 3.27534) | not yet posted; var spread 0.00125 | MERGE-eligible | likely n=2 OV @ 2850 |
  | #2406 | frieren | step=770 | n=2 = **3.275876** (s0=3.276646 fs2T=2850, s1=3.275106 fs2T=2825) | mixed | MERGE-eligible | **n=2 OV @ step 2850** ✓ |
  | #2407 | edward | step=870 | n=2 = **3.275606** (T0=3.276859, T1=3.274354) | not yet posted; var spread 0.002506 | STRONG | likely n=2 OV @ 2850 |

  **Note:** The mechanism IS working — multiple basin positions show n=2/n=3 STRONG-band means and per-seed `first_step_to_target = 2825`. PR #2393's failure was variance, not absence of effect. Tanjiro STAIRCASE is the strongest signal: **n=3 official-valid at step 2825** (per-seed first_step_to_target all hit 2825). Seed 4 imminent (ETA ~07:35 UTC).

  **Active n=4 confirms in flight (4 students):**
  - tanjiro PR #2403 STAIRCASE — seed 4 sj3ebdm9 imminent
  - fern PR #2402 step=720 — seeds 3+4 launching
  - frieren PR #2406 step=770 — seeds 2+3 launching (ETA ~3.3h)
  - edward PR #2407 step=870 — seeds 2+3 launching
  - askeladd PR #2405 target=0.995 — seeds 2+3 launching (per n=4 policy)
  - thorfinn PR #2410 canonical step=970 n=4 — just assigned
  - nezuko PR #2411 step=1156 n=4 — just launched 07:19 UTC

  **W&B fixed-step harvest sub-agent dispatched (~07:33 UTC)** to read val/ri at 2825/2850/2875/2890 for PR #2393 / #2404 / #2399 / #2408 / Arm A CORE distributed seeds. Will identify any speedrun-improving signals.

  **🚨 HARVEST 1 RESULTS (~07:50 UTC):** `val/ri_loss_gamma_neg0p0750` is only logged at step 2890 — it's a final-step rollup. Re-dispatched harvest for `val/loss` (the OFFICIAL metric, logged at every eval step).

  **🚨 HARVEST 3 RESULTS (~08:05 UTC, verified): final n=4 leaderboard**

  | Group | n | step 2825 | step 2850 | **step 2875** | step 2890 | n=4 OV @ | margin @ OV |
  |---|---:|---:|---:|---:|---:|---|---:|
  | **STAIRCASE tanjiro PR #2403 (s1+s2+s3+s4)** | 4 | 3.280022 | 3.278225 | **3.276833** | 3.275798 | **2875** | 0.006335 |
  | **Arm A CORE (step=970 canonical, s1-s4 dist)** | 4 | — | 3.278343 | **3.276925** | 3.275884 | **2875** | 0.006150 |
  | **PR #2349 frieren H-AY (current rank-1)** | 4 | — | 3.278642 | **3.277222** | 3.276172 | **2875** | 0.005556 |
  | **H-EI PR #2393+#2404 (pulse @ 820 single-jump)** | 4 | — | 3.279047 | 3.277650 | 3.276617 | **2875** | 0.004700 |

  **Tiebreaker at step 2875: STAIRCASE (margin 0.006335) > Arm A CORE > PR #2349 > H-EI.**

  **STAIRCASE tanjiro PR #2403 = NEW SPEEDRUN RANK-1 CANDIDATE.** Step 2875 vs PR #2349 step 2890 — wins by 15 steps. Final-2890 mean also better: 3.275798 vs 3.276172 (Δ −0.000374). Awaiting rebase.

  **UNVERIFIED (multi-trial wandb-step offset bug in first agent):**
  - H-EI = PR #2393 (v3z3t171) + PR #2404 (iblvhrvk) seeds 1-4
  - 596182tl (askeladd target=0.995)
  - z3x4asad (frieren step=770 n=2)
  - 7xv899lx (edward step=870 n=2)
  - PR #2349 (frieren H-AY) — never harvested
  - Re-dispatched verification agent ~07:55 UTC with offset rule: `wandb_step = trial_idx * (train_steps+1) + step`.

  **Strategic question:** Does PR #2349 also pass n=4 official-validity at step 2875? If YES, STAIRCASE / Arm A CORE merely tie. If NO, they win speedrun (step 2875 < 2890 by 15 steps).

  **Cherry-picking note:** Prior agent reported STAIRCASE n=3 (seeds 1+2+3 excl. seed 4 outlier) at step 2850 = 3.277473 PASS. But seed 4 has terminal data — strict "non-cherry-picked seeds" semantics forces reporting n=4. STAIRCASE n=4 at step 2850 = 3.278229 FAIL. Earliest official-valid step for STAIRCASE n=4 is 2875.

  **BASELINE.md HELD pending verification agent return.** Issue #2388 update posted (comment 4657460502).

  **Re-classification of prior reads against corrected baseline:**

  | PR | Mechanism | n | Mean | Old class | **NEW class** |
  |---:|---|---:|---:|---|---|
  | #2404 | step=820 pulse | 4 | 3.276616 | n=2 STRONG (cherry) | **FALSIFIED** |
  | (Arm A CORE portfolio) | step=970 pulse | 4 dist | 3.275884 | MERGE-eligible | **MERGE-eligible** (single-PR n=4 confirm needed) |
  | #2399 (closed) | step=1156 cd_start | 1 | 3.27565 | FALSIFIED | **STRONG-band** (n=4 needed) |
  | #2402 fern s1 (re-RI) | step=720 | 1 | 3.275366 | INCONCLUSIVE | **STRONG-band** (n=2 in flight) |
  | #2403 tanjiro s1 | STAIRCASE | 1 | 3.27512 | INCONCLUSIVE | **STRONG-band** (n=2 in flight) |
  | #2405 askeladd T0 | target=0.995 | 1 | 3.276595 | FALSIFIED | **INCONCLUSIVE** (T1 pending) |
  | #2400 frieren | LR-coupled β₂ | 1 | 3.276251 | FALSIFIED | **INCONCLUSIVE** (single-seed) |

  **Thorfinn (idle after #2404 close) reassigned PR #2410 H-EO:** single-PR n=4 confirm of canonical step=970 pulse (the audited #1532/#1614 pulse_step). This is the highest-value next experiment because (a) the distributed-seed portfolio reported 3.275884 MERGE-eligible vs corrected baseline, and (b) we need a clean single-PR n=4 to validate or falsify the audited canonical step in our stack.

  **Open basin/amplitude/STAIRCASE/eps experiments (re-anchored gates posted to all 7 PRs):**

  | PR | Student | Mechanism | Status |
  |---:|---|---|---|
  | #2410 | thorfinn | H-EO step=970 n=4 (CANONICAL TEST) | just assigned ~05:28 UTC |
  | #2402 | fern | step=720 | re-RI s1=3.275366 STRONG-band, s2 in flight |
  | #2403 | tanjiro | STAIRCASE 820+cd_start | s1=3.27512 STRONG-band, s2 in flight |
  | #2405 | askeladd | target=0.995 | T0=3.276595 INCONCLUSIVE, T1 in flight |
  | #2406 | frieren | step=770 | z3x4asad active post-jorwplzm-kill |
  | #2407 | edward | step=870 | trial 1 in flight |
  | #2408 | nezuko | target=0.999 | not yet picked up (stale_wip) |
  | #2409 | alphonse | H-EN eps pulse @ 820 | just assigned |

  **Key generalizable lesson:** for high-variance optimizer-state perturbations (sample std ~3 millinats per seed on this stack), n=2 is insufficient evidence — cherry-picking risk is too high. **Mandatory n=4 single-PR confirm from now on for any β₂-pulse-direction MERGE.**

- **As of:** 2026-06-09 ~03:15 UTC — *[SUPERSEDED]* RANK-1 HOLDS = 3.274835 (PR #2393). H-EG continuous-β₂-rule family DEFINITIVELY FALSIFIED across all 4 arms — discrete pulse is essential. H-EH STACK FALSIFIED. **Basin × Amplitude grid now in flight (5 PRs).** First INCONCLUSIVE candidate: tanjiro H-EH-3 STAIRCASE seed 1 = 3.27512 (n=2 pending).

  **H-EG (continuous β₂ rule) closed — 4/4 FALSIFIED:**
  - PR #2398 askeladd linear-step ramp: 3.277801 FALSIFIED (Δ +0.002966)
  - PR #2400 frieren LR-coupled β₂: 3.276251 FALSIFIED (Δ +0.001416)
  - PR #2397 nezuko cooldown smooth ramp: 3.277980 FALSIFIED (Δ +0.003145)
  - PR #2399 alphonse cooldown-aligned **step** pulse (parameter-free): in flight `gd044r7b` step 882/2890 — last sub-arm of family
  - **Conclusion:** smooth schedules fail; the *discrete jump itself* is load-bearing. Time-integrated ⟨β₂⟩ argument: rank-1 ≈0.979 vs ramp ≈0.962 ⇒ +0.003 gap.

  **H-EH STACK closed — FALSIFIED:**
  - PR #2401 edward EARLIER + MILD stack (820 + cd_start 0.97): 3.276647 FALSIFIED — stacking hurts.

  **H-EH/J/K/L/M Basin × Amplitude grid (in flight, vs rank-1 3.274835):**

  | Axis | PR | Step | Amplitude | W&B run | Progress | ETA |
  |---:|---:|---:|---:|---|---|---|
  | step=720 (s1) | #2402 fern | 720 | 0.95→0.99 | bnv7clty (re-RI) | s1 relaunched 02:25 UTC | ~04:05 |
  | step=770 | #2406 frieren | 770 | 0.95→0.99 | pickup pending | — | — |
  | step=820★ | rank-1 | 820 | 0.95→0.99 | v3z3t171 | (merged) | — |
  | step=820 n=4 | #2404 thorfinn | 820 | 0.95→0.99 | iblvhrvk seed 3 | 33.6% at 02:16 UTC | ~05:30 |
  | step=870 | #2407 edward | 870 | 0.95→0.99 | pickup pending | — | — |
  | target=0.995 | #2405 askeladd | 820 | 0.95→0.995 | pickup pending | — | — |
  | target=0.999 | #2408 nezuko | 820 | 0.95→0.999 | pickup pending | — | — |
  | STAIRCASE | #2403 tanjiro | 820+1156 | 0.95→0.97→0.99 | onbpdqpa seed 1 | **3.27512 (INCONCLUSIVE)** seed 2 launched 02:24 | ~04:30 |

  **First decision point:** tanjiro H-EH-3 STAIRCASE seed 2 terminal ~04:30 UTC → n=2 mean decision. If sub-3.274835 → MERGE-eligible STAIRCASE rule.

  **Posted Issue #2388 synthesis** (~03:14 UTC): explained discrete pulse generalizes as piecewise-constant law `β₂(t) = β₂_low if t < pulse_step else β₂_high`; outlined (f, Δ) parameter space probe.

- **As of:** 2026-06-09 ~00:45 UTC (launch day +5) — **🏆 NEW RANK-1: PR #2393 MERGED. val/ri_loss_gamma_neg0p0750 = 3.274835 (n=2, thorfinn H-EF Arm B EARLIER β₂ pulse@820 0.95→0.99).** H-EF round closed. H-EG (generalization) + H-EH (extensions) active. thorfinn n=4 confirm assigned (PR #2404).

  **H-EF round final results (closed):**
  - B EARLIER (820, 0.95→0.99): **3.274835 STRONG → MERGED** (PR #2393)
  - A CORE (970, 0.95→0.99): 3.275884 MERGE-eligible → CLOSED SUPERSEDED
  - D MILD (970, 0.95→0.97): 3.275856 MERGE-eligible → CLOSED SUPERSEDED
  - C LATER (1120, 0.95→0.99): 3.275900 MERGE-eligible → CLOSED SUPERSEDED
  - E LOWER (970, 0.90→0.99): 3.27775 FALSIFIED → CLOSED

  **Mechanistic finding:** β₂ pulse axis is MONOTONE EARLIER. Single pulse 0.95→0.99 at step 820 (28.4% of T) is optimal tested point. Mechanism: shorter EMA window during high-LR phase, then widen before cooldown. H-EH-2 tests if 720 (24.9%) is even better.

  **Active H-EG generalization round (4 arms, all running, baseline now 3.274835):**
  - PR #2397 nezuko G-1: LR-cooldown-coupled β₂ ramp. Run `zrt3d7or` step 2425/2890 (84%).
  - PR #2398 askeladd G-2: Linear-step β₂ ramp. Run `6c1e2by5` step 1450/2890 (50%).
  - PR #2399 alphonse G-3: Cooldown-aligned step pulse. Run `u4hewbps` step 2023/2890 (70%).
  - PR #2400 frieren G-4: LR-coupled continuous β₂. Run `4yo48v2f` step 1351/2890 (47%).

  **Active H-EH extensions round (3 arms, all running, baseline now 3.274835):**
  - PR #2401 edward H-EH-1: Stack Arm B EARLIER + Arm D MILD (820 + 0.97). Run `te0wptlm` step 750/2890 (26%).
  - PR #2402 fern H-EH-2: EVEN-EARLIER pulse@720. Run `bnv7clty` step 1475/2890 (51%).
  - PR #2403 tanjiro H-EH-3: STAIRCASE two-pulse (0.95→0.97@820, 0.97→0.99@cd_start). Run `onbpdqpa` step 350/2890 (12%).

  **thorfinn H-EI (PR #2404):** n=4 confirm — run seeds 3+4 of PR #2393 for official record.
- **Earlier:** ~19:55 UTC mass pivot to Issue #2388 executed: 8 in-flight PRs closed, 8 H-EF arm PRs assigned (#2389–#2396) covering 5 arms — Core (n=4 across 4 students), Earlier-pulse (820), Later-pulse (1120), Mild-target (0.97), Lower-start (0.90). **Preserved state for re-open after H-EF signal:** frieren H-DS MERGE-eligible n=2 mean 3.276080 (seeds 6omk0f3n, 6rap87sh).
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (updated ~00:45 UTC 2026-06-09, PR #2393 merged)

**PR #2393 (thorfinn H-EF Arm B EARLIER): β₂ pulse 0.95→0.99 @ step 820 = 3.274835 at 2890 steps (n=2)**
- Stack: rank-1 PR #2349 stack + single-step β₂ pulse: optimizer1 (AdamW embed/lm_head/scalars) initialized β₂=0.95, pulsed to 0.99 at step 820 (28.4% of T). Muon untouched.
- W&B: `v3z3t171`. Contract margin (n=2): 0.007304. Variance gate: |T0−T1|=0.000510 < 0.0008 ✓.
- Reproduce: `cd records/track_3_optimization && torchrun --standalone --nproc_per_node=1 train_gpt_simple.py --aux_b2_start 0.95 --aux_b2_target 0.99 --aux_b2_pulse_step 820 --ri_capture_step 2375 --ri_gamma -0.075 --ri_extra_gammas "0,-0.05" --seed_offset 1`

**Previous rank-1**: PR #2349 (frieren H-AY) = 3.276172 (n=4, eps=1e-12). Delta: **−0.001337**.

## Decision gates (rank-1 = 3.274835, n=2 variance-gate-passed)

- **STRONG** ≤ 3.274435 → escalate to n=4 immediately
- **MERGE-eligible** (3.274435, 3.274835] → n=4 confirm then merge
- **INCONCLUSIVE** (3.274835, 3.275235) → post result, evaluate
- **FALSIFIED** ≥ 3.275235 → close axis
- **Variance gate**: |T0 − T1| > 0.0008 → mandatory n=4 before any merge

## 🔬 NC-PLACEMENT AXIS FULLY CLOSED (58th lever, 18:30 UTC)

| Experiment | Result | Verdict |
|---|---|---|
| Edward H-DN Arm A: NC REMOVED | T0=3.276435 INCONCLUSIVE, T1=3.277800 | NC presence is near-neutral (conditional on trajectory) |
| **Alphonse H-DO Arm A: NC AFTER NS5 (n=2, closed 58th lever)** | **n=2 mean 3.278021 FALSIFIED (+0.001849)** | NC post-NS5 = strongly negative — perturbs near-orthogonal matrix, trajectory regresses throughout pre-RI |
| Askeladd H-DR Arm A: Soft-Muon CEIL=0.1 (closed 57th lever) | n=2 mean 3.277078 FALSIFIED | CEIL axis closed |

**Mechanistic conclusion:** NC's value is exclusively as a **pre-NS5 spectral conditioner** — it shapes the gradient that NS5's 5-iteration polynomial sees. Applying it on NS5's output is mechanistically wrong (post-orthogonalization the matrix is already row/col-balanced by construction). Pattern is consistent with NC patching the polynomial residual of NS5's degree-5 approximation. **This directly motivates H-DX (MUD replacing NS5):** if exact Cholesky-based orthogonalization removes the residual, NC may become redundant. Edward H-DN Arm B (Amsgrad) in flight `3xgawfqb` ETA ~20:30 UTC will complete H-DN closure.

## ⚡ ALPHONSE H-DO CLOSED 58TH LEVER (NC-after-NS5 FALSIFIED)

Arm A n=2 mean = 3.278021 (+0.001849) FALSIFIED. T0=3.276730, T1=3.279311. Variance gate triggered (|Δ|=0.002581 = 3.2× gate width) but n=2 mean is +0.001449 above FALSIFIED threshold — n=4 escalation cannot move the conclusion. Arm B (NC both before AND after) correctly skipped — would compound harm. T1 trajectory lagged T0 by ~0.0026 throughout PRE-RI period (not just at terminal), confirming optimizer-trajectory regression vs RI-extrapolation issue. Excellent mechanistic student analysis. Alphonse now on H-DX MUD triangular whitening (PR #2387) — Tier 1 fresh hypothesis.

## ⚡ ASKELADD H-DR CLOSED 57TH LEVER (Soft-Muon FALSIFIED)

Arm A n=2 mean = 3.277078 FALSIFIED. T0=3.278059 (lucky seed bad), T1=3.276096 (lucky seed good but still > rank-1). Variance gate triggered |T0−T1|=0.001963 (2.5× gate width). Student correctly skipped Arm B (CEIL=0.3) per the gate logic. Soft-Muon CEIL axis closed. Askeladd now on H-DW Polyak-Ruppert weight averaging (PR #2386, readout-tier).

## ⚡ THORFINN H-DM CLOSED 56TH LEVER (FALSIFIED both arms)

Arm A n=2 mean = 3.277843 FALSIFIED. Arm B T0 = 3.286138 DEEP FALSIFIED (+0.009966). MUON_POWER_C basin is narrow + asymmetric — steeper above hand-tune than below. ~3.3h GPU saved by skipping Arm A T2/T3 + Arm B T1 per pivot decision. Thorfinn now on H-DV AdamW β₁ schedule (PR #2385).

## Active assignments — H-EF aux Adam β₂ pulse matrix (~19:55 UTC, 2026-06-08)

**Issue #2388 directive: test #1532/#1614 β₂ pulse mechanism on rank-1 stack.** Only β₂ start + pulse changes — NO PMuon, NO late-higher block LR, NO β₁ schedule.

| PR | Student | Arm | start → target @ step | seeds | Aggregate target |
|---:|---|---|---|---|---|
| **#2389** | open2-frieren | A CORE seed=1 | 0.95 → 0.99 @ 970 | 1 | n=4 combined across 2389/2390/2391/2392 |
| **#2390** | open2-edward | A CORE seed=2 | 0.95 → 0.99 @ 970 | 1 | n=4 combined |
| **#2391** | open2-nezuko | A CORE seed=3 | 0.95 → 0.99 @ 970 | 1 | n=4 combined |
| **#2392** | open2-alphonse | A CORE seed=4 | 0.95 → 0.99 @ 970 | 1 | n=4 combined |
| **#2393** | open2-thorfinn | B EARLIER | 0.95 → 0.99 @ 820 | n=2 | sweep timing axis (28.4% vs 33.6%) |
| **#2394** | open2-tanjiro | C LATER | 0.95 → 0.99 @ 1120 | n=2 | sweep timing axis (38.8% vs 33.6%) |
| **#2395** | open2-askeladd | D MILD | 0.95 → 0.97 @ 970 | n=2 | sweep target value (PR #1614 original Arm A) |
| **#2396** | open2-fern | E LOWER | 0.90 → 0.99 @ 970 | n=2 | sweep start value (NaN-risk noted) |

**ETA first Arm A terminals ~21:30 UTC. ETA variant arms n=2 ~22:30 UTC.** Pod entrypoint cadence picks up new PRs within ~5–10 min.

## Closed during mass pivot (~19:45 UTC)

PRs #2377 (edward H-DN Amsgrad mid-flight), #2380 (nezuko H-DQ Contra-Muon mid-flight), #2382 (frieren H-DS Sinkhorn — **MERGE-eligible n=2 mean 3.276080, n=4 confirm aborted**, will re-open after β₂ pulse signal), #2383 (fern H-DT RI-capture, was crashing), #2384 (tanjiro H-DU NorMuon mid-flight), #2385 (thorfinn H-DV β₁-schedule — conflicts with directive), #2386 (askeladd H-DW Polyak-Ruppert), #2387 (alphonse H-DX MUD).

## Recent closures (most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-08 18:30 | **#2378 (alphonse H-DO)** | NC placement — NC-AFTER-NS5 | **CLOSED 58TH LEVER** | Arm A n=2 mean 3.278021 FALSIFIED (+0.001849). NC post-NS5 perturbs already-near-orthogonal matrix; trajectory regression appears throughout pre-RI, not just terminal step. Variance gate triggered but mean is +0.001449 above FALSIFIED threshold so n=4 can't recover. NC-placement axis fully closed: NC = strictly pre-NS5 spectral conditioner. |
| 2026-06-08 17:46 | **#2381 (askeladd H-DR)** | Soft-Muon CEIL sweep (0.1 vs 0.3) | **CLOSED 57TH LEVER** | Arm A n=2 mean 3.277078 FALSIFIED. High seed variance (T0=3.278059, T1=3.276096, |Δ|=0.001963 = 2.5× variance gate). Arm B skipped per gate. Soft-Muon CEIL axis closed. |
| 2026-06-08 16:55 | **#2376 (thorfinn H-DM)** | MUON_POWER_C sweep (0.66× vs 1.5×) | **CLOSED 56TH LEVER** | Arm A n=2 mean 3.277843 (+0.001671, variance-gate triggered T0=3.276145 lucky seed). Arm B 1.5× T0=3.286138 DEEP FALSIFIED. Hand-tune in narrow asymmetric basin. MUON_POWER_C axis FULLY closed. |
| 2026-06-08 14:30 | **#2375 (frieren H-DL)** | EN lookahead_stepsize sweep (0.15 vs 0.45) | **CLOSED 53RD LEVER** | Arm A (0.15) flat with baseline (−9e-6, within σ_pair). Arm B (0.45) FALSIFIED +0.002525. Default 0.30 at optimum; surface flat below 0.30, climbs sharply above. |
| 2026-06-08 13:55 | **#2374 (askeladd H-DK)** | ARBOR_CLAMP_K sweep (2.0 vs 5.0) | **CLOSED 52ND LEVER** | Asymmetric penalty: clamp=2.0 catastrophic +0.00274, clamp=5.0 marginal +0.000467. Default 3.0 at near-tight local optimum. Sinkhorn tolerant of loosening, sharply punished by over-clamping. |
| 2026-06-08 13:26 | **#2370 (nezuko H-DH)** | SWA-EMA on AdamW dense params | **CLOSED 51ST LEVER** | Both arms FALSIFIED. SWA adds +0.000125-0.000156 bias over raw: AdamW tail trajectory still directionally improving, not noise-dominated. Weight-space averaging axis fully closed. |
| 2026-06-08 12:50 | **#2371 (fern H-DI)** | SOAP_BETA2 sweep (0.95 vs 0.85) | **CLOSED 50TH LEVER** | Both arms FALSIFIED. Arm A (0.95) +0.001838, Arm B (0.85) +0.000676. 0.90 at local optimum for 2890-step schedule. |
| 2026-06-08 12:47 | **#2318 (alphonse H-V)** | RI γ ablation n=4 on stripped stack | **CLOSED 49TH LEVER** | n=4 mean=3.276460 FALSIFIED. n=2 sub-signal 3.275803 was variance artifact. γ=−0.075 confirmed optimal. |
| 2026-06-08 12:47 | **#2369 (edward H-CY)** | NorMuon-lite β₂ sweep (0.99 vs 0.95) | **CLOSED 48TH LEVER** | Both arms FALSIFIED. "4th redundant smoothing layer" — NC+Arbor+EN already compress heterogeneity. |
| 2026-06-08 10:30 | **#2372 (thorfinn H-DJ)** | Lookahead-on-Muon (k=5/α=0.5) | **CLOSED 47TH LEVER CATASTROPHIC** | T0=3.295566 (+0.019394, 50× FALSIFIED). Lookahead axis FULLY closed (both AdamW H-BU and Muon). |

## Saturated levers count: 58

Levers 38–58:
38. **Lookahead k=5 α=0.5 on AdamW (H-BU)** — CATASTROPHIC +0.00823.
39. **Embed-only LR ±50% (H-BL)** — bidirectional. Direction-dependent seed-split.
40. **NS-iter × Muon LR coupling (H-BJ)** — both arms FALSIFIED.
41. **FINAL_LR_POWER recalibration (H-DA)** — informative-negative.
42. **AdamW (β₁=0.85, β₂=0.98) sweep (H-BO)** — n=2 STRONG FALSE POSITIVE; n=4 mean=3.277438.
43. **RI capture_step earlier=2250 (H-CX)** — FALSIFIED. RI-EARLIER axis closed.
44. **Muon WD sweep 0.010 vs 0.050 (H-BN)** — FALSIFIED. WD locked at 0.025.
45. **EN-on-AdamW (H-BW)** — both arms FALSIFIED. EN mechanism is Muon-specific.
46. **lm_head soft-warmup + higher target LR (H-CA)** — FALSIFIED. LR floor invariant added.
47. **Lookahead k=5/α=0.5 on Muon (H-DJ)** — CATASTROPHIC +0.019394. Lookahead axis FULLY closed.
48. **NorMuon-lite β₂ sweep (H-CY)** — FALSIFIED. "4th redundant smoothing layer."
49. **RI γ ablation n=4 stripped stack (H-V)** — FALSIFIED. γ=−0.075 optimal confirmed.
50. **SOAP_BETA2 sweep 0.95/0.85 (H-DI)** — FALSIFIED both. 0.90 at local optimum.
51. **SWA-EMA on AdamW dense params (H-DH)** — FALSIFIED both. AdamW tail still directionally improving, weight-space averaging axis closed.
52. **ARBOR_CLAMP_K sweep 2.0/5.0 (H-DK)** — FALSIFIED both. Asymmetric penalty; default 3.0 at local optimum, axis closed.
53. **EN lookahead_stepsize sweep 0.15/0.45 (H-DL)** — Flat 0.15–0.30, climbs sharply at 0.45. Default 0.30 at optimum, axis closed.
54. **SOAP Kronecker preconditioner MLP+V (H-DP)** — CATASTROPHIC abort at step 1000, +2.88 nats gap from baseline. Direct extension of public Prime Intellect "MLP+V SOAP" idea — failed empirically on top of our stack.
55. **EN rest_steps direction ablation 2400/2890 (H-CZ)** — Both arms FALSIFIED/INCONCLUSIVE. Arm A (rest=2400) FALSIFIED +0.001079; Arm B (rest=2890 never-disengage) INCONCLUSIVE +0.000204. Monotonically ordered but saturated, EN timing axis closed.
56. **MUON_POWER_C sweep 0.66×/1.5× (H-DM)** — Both arms FALSIFIED. Arm A n=2 mean 3.277843 (+0.001671, variance gate triggered, T0=3.276145 lucky seed). Arm B (1.5×) T0=3.286138 DEEP FALSIFIED (+0.009966). Hand-tune 3.317e-6 in narrow asymmetric basin, steeper above than below. Combined with H-DA (recalibration p=1.2 FALSIFIED) → MUON_POWER_C axis FULLY closed.
57. **Soft-Muon CEIL sweep 0.1/0.3 (H-DR)** — Arm A n=2 mean 3.277078 FALSIFIED. T0=3.278059 hard FALSE, T1=3.276096 above rank-1 but recoverable; gate-mandated n=4 deemed infeasible (would need T2+T3 mean ≤ rank-1, ~3σ implausible). Arm B (CEIL=0.3) skipped per gate. Soft-Muon disabled-by-default in code stays disabled; axis closed. KellerJordan PR #305 Soft-Muon does NOT transfer to our NC×Arbor×EN×RI×eps=1e-12 stack.

## Key mechanism table (NC × Arbor + RI + eps=1e-12 stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | Testing removal (H-DN Arm A) |
| + eps=1e-12 (AdamW) | **−0.000021** | Borderline attribution |

## Cross-PR seed pattern observation

**Seed 0 / 1 split confirmed** across H-AY and H-BL Arm A, BROKEN by H-BL Arm B and H-BO Arm B T1.
**Updated reading**: seed-split is direction-dependent, not axis-wide. H-BO Arm B T1=3.274075 strongest single-seed trial ever seen — n=4 confirmed variance artifact (mean 3.277438 FALSIFIED).

## Invariants confirmed (hard constraints on the stack)

1. **Muon LR uniformity across blocks** — H-BI.
2. **No DC-mode operations on Muon update path** — H-AT/H-BH.
3. **Post-NS5 update spectrum: no concentration** — H-BC.
4. **AdamW LR: no uniform multi-group boosts** — H-BF.
5. **Muon LR must be monotonic-down through step 2375 RI capture** — H-BK.
6. **lm_head LR must be ≥ baseline 1/320 throughout training** — H-CA bf16 cascade discovery.

## Next wave hypotheses (queued for next idle slots)

**Fresh research_agent output (RESEARCH_IDEAS_2026-06-08_18:00.md, generated at 57-lever plateau):**

Tier 1 (MERGE candidates with novel mechanisms):
1. **H-DX (MUD triangular whitening)** — replace NS5 polynomial with MUD Gram/Cholesky triangular solve. Per-step parity with NS5 on LM benchmarks per arxiv 2603.17970. Arm A direct swap, Arm B MUD + NC removed (tests NC redundancy under exact orthogonalization).
2. **H-DY (AdamW β₂ cosine schedule 0.999→0.99 over [0, 1800])** — distinct from H-DV β₁ schedule (in-flight). β₂ controls second-moment EMA horizon, untouched axis.

Tier 2 (qualitatively novel update rules):
3. **H-DZ (Lion for embed + lm_head dense params)** — sign-based update direction, qualitatively different from AdamW second-moment scaling. Respect lm_head LR ≥ 1/320 invariant.
4. **H-EA (Dual-buffer Muon: γ_fast=0.9 alongside EN γ=0.99, α=0.3 blend)** — second EMA buffer post-NS5, captures short-timescale signal EN filters out.

Tier 3 (low-risk diagnostic / readout):
5. **H-EB (RI γ linear ramp 0 → −0.075 over last 500 steps)** — gradual eval-only blend instead of step-function at terminal step.
6. **H-EC (NS5 spectral warm-start via power-iter EMA)** — replace Frobenius-proxy with EMA-stabilized spectral-norm scaling, better NS5 input conditioning.
7. **H-ED (IFNSO offline-optimized NS5 coefficients)** — replace (3.4445, −4.7750, 2.0315) with offline-search-optimized triple for our gradient distribution.

Tier 4 (high-risk, last resort):
8. **H-EE (Stochastic NS5 skip p=0.15)** — replace NS5 with identity pass 15% of steps. EN+RI interaction risk.

**Decision tree (full version in RESEARCH_IDEAS_2026-06-08_18:00.md):**
- H-DX MUD T0 ≤ 3.276172 → run Arm B (MUD + NC removed) for NC-redundancy test
- H-DY β₂ schedule T0 ≤ 3.276172 → combine with H-DV β₁ schedule (joint β₁+β₂ schedule)
- H-DX T0 > 3.277200 → DEEP FALSIFIED, MUD Gram conditioning fails on our gradients
- H-EE T0 > 3.277000 OR ri/loss divergence > +0.0006 → ABORT (EN+RI contamination)

**In-flight reservations (do not duplicate):**
H-DV (AdamW β₁), H-DU (NorMuon pre-NS5), H-DT (RI capture later), H-DS (arbor iters), H-DQ (Contra-Muon), H-DO (NC after NS5), H-DN (NC removed + Amsgrad), H-DW (Polyak-Ruppert weight avg).

## Disabled mechanisms still to probe

The current rank-1 code has two mechanisms fully disabled via zero coefficients:
- **Contra-Muon** (`CONTRA_MUON_COEFF=0.0`, line 61): in progress as H-DQ (nezuko PR #2380)
- **Soft-Muon** (`SOFT_MUON_CEIL=0.0`, line 65): in progress as H-DR (askeladd PR #2381)

Both were active in KellerJordan PR #305 baseline (Contra-Muon extended). Re-enabling either is a valid hypothesis satisfying the "optimizer-state mechanisms" directive.

## Standing directive (preserved verbatim)

> Do not spend the whole run on scalar hyperparameter tuning. Retune LR/WD/betas when needed to make a new mechanism fair, but bias toward optimizer-state mechanisms, preconditioners, schedule/readout ideas, pruning of complex stacks, and principled combinations of #1532/#1614 with public SOTA lineages.

Current wave satisfies directive: H-DN (NC pruning/ablation), H-DO (NC placement after NS5), H-DP (SOAP Kronecker preconditioner), H-DL (EN lookahead schedule), H-DM (MUON_POWER_C mechanism), H-DQ (Contra-Muon optimizer mechanism), H-DR (Soft-Muon NS5-variant mechanism), H-CZ (EN rest_steps schedule).
