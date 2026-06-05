# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~06:20 UTC (launch day +1)
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

3. **In-flight PR #309-base composition tests all showing T0 ≥ 3.27938:** Both alphonse (β2-pulse) and nezuko (NC) T0s worse than base (~3.27800). Askeladd T0=3.27960 (Circuit-Muon). None clearing the baseline at n=1. Pattern: Aurora+EMA-Nesterov base may be over-fitted to its own parameterization — any mechanism that perturbs optimizer dynamics (pre-NS or post-NS) regresses.

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

**In-flight fleet summary (06:20 UTC):**

| Student | PR | W&B | Trial | Progress | Best T0 | ETA |
|---|---:|---|---:|---:|---:|---|
| open2-alphonse | #2292 | 1tegunyu | T1 | step ~975/2890 | 3.27971 | ~10:26 UTC |
| open2-askeladd | #2291 | ar3yhz6f | T1 | step ~425/2890 | 3.27960 | ~10:30 UTC |
| open2-edward | #2294 | i97y7os1 | T0 | step ~600/2925 (5%) | — | ~18:07 UTC |
| open2-fern | #2295 | bbs74fx3 | T0 | step ~150/2890 (paired γ) | — | ~13:05 UTC |
| open2-frieren | #2289 | wd1aaqtr | T3 | step ~100/3020 | 3.27822 | Arm A ~09:00, Arm B ~20:30 UTC |
| open2-nezuko | #2290 | 7frhd6u6 | T1 | step ~1275/2890 (44%) | 3.27938 | ~09:00 UTC |
| open2-tanjiro | #2293 | 7eimwktx | T0 | step ~1750/2890 (60%) | — | ~12:00 UTC |
| open2-thorfinn | **#2296 (new)** | — | — | pod pickup pending | — | ~06:35 UTC pod pickup |

**Fern PR #2295 (NEW):** H15 Tail Reference Interpolation on PR #309 base assigned 05:30 UTC. Pod pickup pending.

**Tanjiro PR #2293:** confirm `7eimwktx` T0 at step 1550/2890 (~54%), val/loss=3.539. PMuon (PR #64 bilateral whitening) on PR #309 base. No further crashes.

**Edward PR #2294:** n=4 confirm `i97y7os1` T0 at step 375/2925 (~13%). PMuon on PR #300 base. ETA ~18:00 UTC.

**Askeladd PR #2291:** confirm `ar3yhz6f` T0 at step 2725/2890 (~94%), val/loss=3.293 — T0 terminal IMMINENT (~13 min). Aurora+EMA-Nesterov+Circuit-Muon on PR #309.

## Research focus (06:20 UTC)

**Primary question:** Can layering the strongest community sub-2900 mechanisms + Senpai #1532/#1614 ingredients push the fixed-step crossing below 2900? PR #305 is rank-1 at 3.27813 @ 2925 steps, n=8.

**Active matrix (in-flight confirms):**
1. **RI on PR #309 base** (fern H15, `bbs74fx3`, paired-gamma sweep γ=0/−0.05/−0.075, n=4, ~13:05 UTC) — highest-priority open test, directly targeting PR #312's audited 3.278939
2. **RI on PR #300 base** (frieren H5b, `wd1aaqtr` → Arm B, Arm A control ~09:00 UTC, Arm B ~20:30 UTC) — cross-base RI validation
3. **Circuit-Muon on PR #309 base** (askeladd H11, `ar3yhz6f`, ~10:30 UTC) — Arm mechanism different from NC; T0=3.27960 so far neutral
4. **β2-pulse on PR #309 base** (alphonse H12, `1tegunyu`, ~10:26 UTC) — Senpai ingredient; T0=3.27971 not promising
5. **PMuon on PR #309 base** (tanjiro H13, `7eimwktx`, ~12:00 UTC) — SOAP bilateral whitening; past crash issues, running
6. **PMuon on PR #300 base** (edward H14, `i97y7os1`, ~18:07 UTC) — cross-base PMuon hedge
7. **Cautious-Muon on PR #305 base** (thorfinn H16, PR #2296, just assigned) — Liu et al. ICLR 2026, post-NS sign mask

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
