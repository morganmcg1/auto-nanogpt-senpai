# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~09:15 UTC (launch day +1)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

This launch was opened explicitly as an open-context SOTA combination run: mine
the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed)
plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below
2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## Active assignments (as of 2026-06-05 ~06:20 UTC)

| PR | Student | Hypothesis | Base | Target step | Status | Source |
|---:|---|---|---|---:|---|---|
| **#2292** | open2-alphonse | H12 Senpai #1532 β2-pulse on PR #309 base | PR #309 | 2890 | T0=3.27971 (worse than base); T1 at step ~975, ETA 10:26 UTC | Senpai #1532/#1614 + PR #309 |
| **#2291** | open2-askeladd | H11 Aurora+EMA-Nesterov+Circuit-Muon | PR #309 | 2890 | T0=3.27960; T1 at step ~425, ETA ~10:30 UTC | nezuko #2286 + edward #2283 |
| **#2294** | open2-edward | H14 Senpai #1614 PMuon on PR #300 base | PR #300 | 2925 | T0 step ~600/2925 (5%), ETA ~18:07 UTC | Senpai #1532/#1614 + PR #300 |
| **#2295** | open2-fern | **H15 Tail Reference Interpolation on PR #309 base (paired gamma sweep)** | PR #309 | 2890 | n=4 confirm `bbs74fx3` running (paired: γ=0,−0.05,−0.075 per trial), ETA ~13:05 UTC | PR #307, #312 |
| **#2289** | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930-3020 | Arm A: T0=3.27822, T1=3.28002 (tail), T2=3.27952; T3 just started, Arm B auto-launches ~09:00 UTC | PR #307, #312 |
| **#2290** | open2-nezuko | H10 Aurora+EMA-Nesterov+NC | PR #309 | 2890 | T0=3.27938 (worse than base); T1 at step ~1275, ETA ~09:00 UTC | nezuko #2286 + fern #2284 |
| **#2293** | open2-tanjiro | H13 Senpai #1614 PMuon on PR #309 base | PR #309 | 2890 | T0 step ~1750/2890 (60%), ETA ~12:00 UTC | Senpai #1532/#1614 + PR #309 |
| **#2296** | **open2-thorfinn** | **H16: Cautious-Muon on PR #305 base (normalized vs unnormalized, n=4 each)** | **PR #305** | **2925** | **just assigned (replaces closed #2288)** | Liu et al. ICLR 2026, PR #305 |

**Closed this turn:** PR #2288 (thorfinn — NC bare-Muon CONFIRMED at 3325 steps, n=4 mean 3.27537, but NOT sub-2900 eligible; foundational compositional finding). Prior closures: PR #2283 (edward, Circuit-Muon isolated falsified 3.27874), PR #2287 (tanjiro, TPR 3.27901), PR #2281 (alphonse, NC+PR #305 3.27986), PR #2286 (nezuko, PR #309 tail 3.27838), PR #2282 (askeladd, EMA-Nesterov bare 3.28075), PR #2284 (fern, NC+PR #300 3.27875, Arbor-fixed screen failed). **Assigned PR #2296** (thorfinn H16 Cautious-Muon on PR #305 base, 2-arm normalized vs unnormalized, n=4 each at 2925 steps).

**🚨 NC compositional verdict (FINAL — thorfinn PR #2288 terminal):**
- NC (PR #295) on PR #300 stack: FAILED (fern #2284, n=4 mean 3.27875)
- NC on PR #305 stack (Aurora+RRE): FAILED (alphonse #2281, n=4 mean 3.27986)
- **NC on bare Muon: CONFIRMED** (thorfinn #2288, n=4 mean 3.27537 at 3325 steps, σ=0.00080, margin 0.00926)
- **Definitive rule: NC is redundant with Aurora's row-aware polar refinement. NC + Aurora → no lift. NC alone → genuine lift (~0.003 delta vs control). These share the same row-spectrum degree of freedom.**
- NC carry-over: valid on bare-Muon stacks. NOT directly a sub-2900 mechanism since vanilla-Muon + NC at 2925 steps will not beat PR #305's Aurora+RRE.

**Top contenders (trial-status — ranked by current best aggregate at sub-3000 step budget):**

| Student | PR | Trials done | Mean | σ | Step | Status | Hypothesis |
|---|---:|---:|---:|---:|---:|---|---|
| **— NO MERGE WINNER YET (PR #305 still rank-1 at 3.27813)** | | | | | | | |
| **fern (Arm A) — FALSIFIED, closing** | #2284 | **4** | **3.27875** | **0.00104** | 2930 | T0=3.27828, T1=3.27760, T2=3.27903, **T3=3.28007** tail; margin 0.00250 fails; +0.00031 worse than PR #300 ref | NC standalone on PR #300 base |
| **edward — FALSIFIED + CLOSED** | #2283 | 4 | **3.27874** | **0.00055** | 2930 | T0=3.27895, T1=3.27822, T2=3.27838, T3=3.27942; V/O telemetry perfect | Circuit-Muon isolated on PR #300 (no EMA-Nesterov) |
| frieren (Arm A) | #2289 | 1 | 3.27822 | — | 2930 | T2 ~47% in `wd1aaqtr`, run name suggests control replication progress | PR #300 vanilla (Arm A=control, no RI) |
| **nezuko #2286 — CLOSED, FAILS STAT-SIG** | #2286 | 4 | **3.27838** | **0.00080 (T3 tail)** | 2890 | T3=3.27956 tail event | EMA-Nesterov + Aurora (PR #309 lineage) |
| **tanjiro #2287 — FALSIFIED + CLOSED** | #2287 | 4 | **3.27901** | **0.00051** | 2930 | T0=3.27911, T1=3.27849, T2=3.27968, T3=3.27877; pulse real but post-pulse slow | Single-stage Tail Phase Readout on PR #300 |
| **askeladd #2282 — FALSIFIED + CLOSED** | #2282 | 4 | **3.28075** | **0.00059** | 2900 | T3=3.28046 done | EMA-Nesterov on PR #300 bare |
| **alphonse #2281 — FALSIFIED + CLOSED** | #2281 | 4 | **3.27986** | **0.00242** | 2925 | T0=3.27688, T1=3.28211, T2=3.28238, T3=3.27806; bimodal | NC on PR #305 base (Aurora+RRE+Contra-Muon+NC) |

**At higher step budget (3325, NOT directly comparable to sub-2900 goal):**

| Student | PR | Arm Z (control) | Arm A (NC) | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| thorfinn | #2288 (CLOSED 06:15 UTC) | Arm Z n=2 mean 3.27846 | **Arm A NC n=4 mean 3.27537** (T0=3.27461, T1=3.27582, T2=3.27628, T3=3.27477, σ=0.00080, margin 0.00926) | **CONFIRMED — not sub-2900 eligible** | NC on bare Muon works; not composable with Aurora |

**Key analytical reads (06:20 UTC):**

1. **🔴 Fern Arm A FALSIFIED at terminal — NC standalone on PR #300 base does NOT win.** Per-trial: T0=3.27828, T1=3.27760, T2=3.27903, **T3=3.28007 tail event** (T3 is ~8σ above prior trials). n=4 mean = 3.27875, margin 0.00250 < 0.004; +0.00031 worse than PR #300 reference (3.27844, n=16). The PR #305 rank-1 baseline (3.27813) is still the merge target. **No current merge candidate from the first wave.** Closing fern after terminal SENPAI-RESULT.

2. **NC compositional verdict FINAL (06:20 UTC):** NC confirmed on bare Muon (thorfinn n=4 mean 3.27537, margin 0.00926) and falsified on ALL Aurora-bearing stacks. Rule: NC is structurally redundant with Aurora's row-balanced polar refinement. NC-only future hypothesis must start from bare Muon.

3. **PR #309-base composition T0/T1 pattern CONFIRMED 3-of-3 (08:00 UTC):** All three mechanisms have T1 sub-base, with T0 above base:
    - nezuko (NC):       T0=3.27938, T1=3.27753 → n=2 mean **3.278455**
    - alphonse (β2):     T0=3.27971, T1=3.27775 → n=2 mean **3.278730**
    - askeladd (Circuit-Muon): T0=3.27958, T1=**3.27726** ← lowest T1 of the three → n=2 mean **3.278420**

    Earlier 07:35 read of askeladd at val/best 3.36 @ 2250 was just mid-trial descent — final landed sub-base. All three n=2 means are within 0.00031 of each other (3.27842 to 3.27873), and all hover at/near PR #309 base (3.27800). T0/T1 ranges (~0.00185 to ~0.00232) are 10–13× the typical PR #309 base trial-to-trial variance (~0.00018).

    **Strong working hypothesis:** PR #309 base + ANY perturbation introduces high seed-dependent variance, with seed=0 unusually bad and seed=1 unusually good. If T2/T3 are average, n=4 means will hover near base, making all three mechanisms statistically indistinguishable from PR #309 base alone. If T2/T3 follow seed=1 behavior, all three are wins. Need n=4 means to disambiguate. ETAs: nezuko ~08:35 UTC, alphonse ~08:54 UTC, askeladd ~09:19 UTC.

    **Tanjiro H13 PMuon on PR #309 base is the exception:** T0=3.28237 did NOT reach the 3.28 target. PMuon may not compose with PR #309 base — only mechanism in this round that genuinely regresses.

    **Fern's RI (g32gn44z) T0 paired-gamma TERMINAL (08:21 UTC):** γ=0 (control) = 3.27798, γ=-0.05 = 3.27766, γ=-0.075 = **3.27765** (best). Within-trial lift ~0.00033 — first positive PR #309-base composition signal of the round. Paired design eliminates seed noise. Critically, control γ=0 = 3.27798 sits AT PR #309 base mean, suggesting fern's seed=0 trajectory is itself a "normal" trial (vs other students' bad seed=0 T0s). The 0.00033 lift is RI's pure additive contribution. If lift holds across T1/T2/T3, n=4 mean projects ~3.27765 — cleanly clearing PR #305 (3.27813) and the n=4 stat-sig contract (3.27800). T3 ETA ~13:00 UTC.

    **Tanjiro H13 PMuon planning abort:** T0=3.28237 falsification floor is 3.27909 (even with theoretical best T1-T3 = 3.27800 each). Student plans to abort T2/T3 if T1 > 3.27950 at ~10:30 UTC. Approved.

4. **CRITICAL FLEET FINDING (08:38 UTC): Thorfinn's pod (RTX Pro 6000 Blackwell) cannot run PR #305 OR PR #309 base on 1 GPU.** Student verified by pulling alphonse's H12 file (which runs cleanly on alphonse's pod per W&B `1tegunyu`) and getting identical step-2 NaN on Blackwell pod. Bare advisor base runs cleanly past step 19 on same pod. Confirmed: Aurora row-rescaling + proj-zero-init combination is bf16-precision incompatible on Blackwell. **Operational implication:** future Aurora-stack hypotheses MUST NOT be routed to thorfinn's pod. Thorfinn pivoted (second time) to C-Muon on bare Muon at train_steps=3325 (matching PR #2288 budget). 2-arm ablation (normalized/unnormalized) × n=4. Baselines: PR #2288 Arm Z (bare Muon n=2 mean 3.278455), PR #2288 Arm A (bare Muon + NC, n=3 mean 3.27557). Not sub-2900-eligible but answers structural question + sets up potential NC + C-Muon stack as follow-up.

4. **New next-wave (thorfinn H16):** Cautious-Muon on PR #305 base — post-NS sign mask from Liu et al. ICLR 2026. Different mechanism class from NC (sign-agreement direction control vs. spectrum normalization). PR #296 (open2-thorfinn) just assigned.

**Compositional landscape (as of 06:20 UTC):**

| Mechanism | Base | Status |
|---|---|---|
| NC (pre-NS normalization) | bare Muon | ✅ CONFIRMED (+0.003 delta at 3325 steps, NOT sub-2900) |
| NC (pre-NS normalization) | PR #300 (Aurora+Contra-Muon) | ❌ FAILED (fern n=4 mean 3.27875) |
| NC (pre-NS normalization) | PR #305 (Aurora+RRE) | ❌ FAILED (alphonse n=4 mean 3.27986) |
| NC (pre-NS normalization) | PR #309 (Aurora+EMA-Nesterov) | ❌ Likely failed (nezuko T0=3.27938, n=4 pending ~09:00) |
| EMA-Nesterov ramp | bare PR #300 | ❌ FAILED (askeladd n=4 mean 3.28075) |
| EMA-Nesterov + Aurora | PR #309 | ~neutral (n=4 mean 3.27838 — matches PR #300 ref) |
| Circuit-Muon | PR #300 | ❌ FAILED (edward n=4 mean 3.27874) |
| Circuit-Muon | PR #309 (aurora+EMA-N) | Pending (askeladd T0=3.27960, n=4 ~10:30 UTC) |
| β2-pulse (Senpai) | PR #309 | Likely failing (alphonse T0=3.27971, n=4 ~10:26 UTC) |
| PMuon (PR #64) | PR #309 | Pending (tanjiro, ~12:00 UTC) |
| PMuon (PR #64) | PR #300 | Pending (edward, ~18:07 UTC) |
| RI (γ=−0.075, PR #307) | PR #300 | Pending (frieren Arm B, ~20:30 UTC) |
| RI (γ=−0.075, PR #307) | PR #309 | **RUNNING** (fern bbs74fx3, paired gamma sweep, ~13:05 UTC) |
| Cautious-Muon (post-NS) | PR #305 | **JUST ASSIGNED** (thorfinn PR #2296, ~2925 steps) |

**In-flight fleet summary (06:45 UTC):**

| Student | PR | W&B | Trial | Progress | Best T0 | ETA |
|---|---:|---|---:|---:|---:|---|
| open2-alphonse | #2292 | 1tegunyu | T1 | step ~1975/2890 (68%) | **3.27971** | ~14:20 UTC |
| open2-askeladd | #2291 | ar3yhz6f | T1 | step ~1275/2890 (44%) | **3.27958** | ~10:50 UTC |
| open2-edward | #2294 | i97y7os1 | T0 | step ~1168/2925 (40%) | — | ~18:10 UTC |
| open2-fern | #2295 | **g32gn44z (recovery)** | T0 | step ~125/2890 (paired γ) | — | ~13:05 UTC |
| open2-frieren | #2289 | wd1aaqtr | T3 (Arm A) | step ~100/3020 | 3.27822 | Arm A ~09:00, Arm B ~20:30 UTC |
| open2-nezuko | #2290 | 7frhd6u6 | T1 | step ~1275/2890 (44%) | 3.27938 | ~09:00 UTC |
| open2-tanjiro | #2293 | 7eimwktx | T0 | step ~1750/2890 (60%) | — | ~12:00 UTC |
| open2-thorfinn | **#2296 (new)** | — | — | pod picked up branch; training to launch next iter (~06:45 UTC) | — | ~13:30 UTC est |

**Fern PR #2295:** bbs74fx3 SIGTERM at step 720 (session group cleanup issue). New run **g32gn44z** launched 06:36 UTC by student auto-recovery. Paired-gamma design (γ=0/−0.05/−0.075 evaluated from SAME trajectory + same step-2375 snapshot) — strictly better statistical power than independent arms. Smoke result confirmed monotonic improvement (4.10597→4.0862→4.07752).

**Tanjiro PR #2293:** confirm `7eimwktx` T0 ~60% (step 1750/2890). PMuon on PR #309 base; running cleanly.

**Edward PR #2294:** confirm `i97y7os1` T0 at step 1168/2925 (~40%). PMuon on PR #300 base. ETA ~18:10 UTC.

**Askeladd PR #2291:** confirm `ar3yhz6f` **T0 TERMINAL at 3.27958** at step 2890. T1 mid-run at step 1275 (44%). Aurora+EMA-Nesterov+Circuit-Muon on PR #309 — T0 worse than PR #309 base (~3.27800). Pattern: Circuit-Muon + EMA-Nesterov composition appears to interfere on Aurora-bearing stack just like NC and β2-pulse.

**Thorfinn PR #2296 (NEW):** H16 Cautious-Muon on PR #305 base assigned 06:23 UTC. Pod has fetched branch `open2-thorfinn/h16-cmuon-pr305-base` and entered iteration 51 at 06:24 UTC; GPU still 0% at last log (06:35 UTC). Training start expected next iteration (~06:45 UTC).

## Research focus (06:45 UTC)

**Primary question:** Can layering the strongest community sub-2900 mechanisms + Senpai #1532/#1614 ingredients push the fixed-step crossing below 2900? PR #305 is rank-1 at 3.27813 @ 2925 steps, n=8.

**Active matrix (in-flight confirms):**
1. **RI on PR #309 base** (fern H15, `bbs74fx3`, paired-gamma sweep γ=0/−0.05/−0.075, n=4, ~13:05 UTC) — highest-priority open test, directly targeting PR #312's audited 3.278939
2. **RI on PR #300 base** (frieren H5b, `wd1aaqtr` → Arm B, Arm A control ~09:00 UTC, Arm B ~20:30 UTC) — cross-base RI validation
3. **Circuit-Muon on PR #309 base** (askeladd H11, `ar3yhz6f`, ~10:30 UTC) — Arm mechanism different from NC; T0=3.27960 so far neutral
4. **β2-pulse on PR #309 base** (alphonse H12, `1tegunyu`, ~10:26 UTC) — Senpai ingredient; T0=3.27971 not promising
5. **PMuon on PR #309 base** (tanjiro H13, `7eimwktx`, T1 step 1625/2930, ~10:30 UTC) — T0=3.28237 already above falsification; per pre-approved abort, T1 ≥ 3.27950 triggers early stop
6. **PMuon on PR #300 base** (edward H14, `i97y7os1`, T1 step 375/2930) — T0=3.28256 also above falsification; mirrors tanjiro pattern; PMuon weakness on multiple bases concerning
7. **Cautious-Muon on BARE MUON (pivot #2)** (thorfinn H16, PR #2296, 3325 steps) — Blackwell pod cannot run any Aurora-bearing stack; redirected to C-Muon on bare Muon, 2 arms (normalized/unnormalized) × n=4; iteration 59 launched 09:00:40, training run not yet visible in W&B

**🟢 Frieren PR #2289 Arm A complete (09:13 UTC):**
- Arm A control n=4 mean **3.27934** (sd 0.000776), T0=3.27822, T1=3.28002 (tail), T2=3.27952, T3=3.27958
- +0.00090 vs PR #300 reference (3.27844, n=16) — within ±2 SE, consistent with seed variance, not harness regression
- Arm B (RI applied) launched 09:12:30 in `fvf4tu59` with APPLY_RI=1 REFERENCE_STEP=2375 REFERENCE_WEIGHT=0.075 RUN_STOP_STEP=2930
- Paired Arm B vs Arm A is correct attribution method; expected lift ≥ +0.0003 to call a clear hit
- ETA ~20:45 UTC

**Key open hypotheses (not yet assigned):**
- H-D: Senpai late-higher block LR pattern on PR #309 base (from RESEARCH_IDEAS_2026-06-05_04-40.md)
- H-E: Polar Express NS wall-clock gate (from RESEARCH_IDEAS)
- Corrected Arbor Muon on PR #309 base — Sinkhorn equil. on mlp.fc+mlp.proj only
- RRE + EMA-Nesterov composition (PR #305 + PR #309)
- Stack winning mechanisms from current confirms once n=4 means land

## Next research directions (second wave, pending confirm outcomes)

- If **RI on PR #309** (fern) wins → stack RI + EMA-Nesterov. Could be first sub-2900 merge candidate.
- If **PMuon** (tanjiro or edward) wins → stack PMuon on PR #305 base, then PMuon + RI composition
- If **C-Muon** (thorfinn H16) wins → stack C-Muon + RRE, then C-Muon + RI composition
- If Circuit-Muon wins on PR #309 → full #311 stack reconstruction on Senpai infra
- NC on bare Muon confirmed → explore NC + EMA-Nesterov WITHOUT Aurora (a fresh base that avoids the Aurora redundancy)
- Outer-Nesterov (MuLoCo PR #277) wrapper as architectural fallback if all above plateau
- Polar Express NS (PR #254) as drop-in for standard NS inside Muon
  optimizer.

## Things to AVOID without strong justification

- Scalar LR/WD sweeps as the primary contribution of a PR — only retune to
  make a new mechanism fair.
- Repeating "Muon + aux Adam, lr=X, wd=Y" hyperparameter tweaks unless the new
  step budget makes the existing setting stale.
- Heavy hyperparameter searches in the first 24 hours; bias toward mechanism
  diversity until we know which families work on our infra.
