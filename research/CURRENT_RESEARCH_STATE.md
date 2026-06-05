# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~15:32 UTC (launch day +1)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE (merged 2026-06-05 13:37 UTC)

**Senpai PR #2295 (fern H15 RI): n=4 mean 3.27786 at 2890 steps** — RI γ=−0.075, capture=2375, on PR #309 base.

## Active assignments (as of 2026-06-05 ~15:32 UTC)

| PR | Student | Hypothesis | Base | Target | Status |
|---:|---|---|---|---:|---|
| **#2302** | open2-fern | H-G RI hyperparameter sweep (capture × γ, 9 arms) | PR #309 | 2890 | T0 active step 2601, val/loss 3.3228 |
| **#2298** | open2-alphonse | H-A Corrected Arbor Muon (2-iter Sinkhorn) | PR #309 | 2890 | **UNBLOCKED ~15:26 UTC** — torch fix in place, smoke `9aks4z4t` at step 100. n=4 launch imminent |
| **#2304** | open2-askeladd | H-I RI direction ablation (positive γ sweep) | PR #309 | 2890 | **FIX SENT 15:32 UTC** — double-launch + missing `--ri_extra_gammas` flag. Awaiting kill+relaunch |
| **#2301** | open2-edward | H-D Senpai late-higher block LR on PR #300 base | PR #300 | 2925 | Arm A (flat control) `svbaoi2b` T0=3.27874 ✓, T1 at step 3510 |
| **#2289** | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930 | Arm B (RI) `fvf4tu59` T0=3.27927 (Δ vs Arm A T0=+0.00105), T1 imminent |
| **#2297** | open2-nezuko | H17 RI on PR #305 base (paired-gamma) | PR #305 | 2925 | T0 Δ=−0.00069, **T1 Δ=−0.00068** ✓ (provisional n=2 mean 3.27798). T2 active. |
| **#2299** | open2-tanjiro | H-D Senpai late-higher block LR on PR #309 base | PR #309 | 2890 | Arm A (flat control) T0=3.2792, T1=3.2777 (good). T2 at step 6782 |
| **#2303** | open2-thorfinn | H-F RI + NC on bare Muon (cross-base universality test) | bare Muon | 3325 | Smoke `ffjhfjp1` at step 1350 (post-crash recovery). n=4 launch pending |

## Closures this round (since last state update)

| PR | Student | Verdict | n | Key finding |
|---:|---|---|---:|---|
| #2300 | askeladd | **FALSIFIED** | 1 (gate) | PE NS wall-clock: +2.23% vs ≥5% gate. H100-specific failure. |
| #2296 | thorfinn | **FALSIFIED** | 1 (abort) | C-Muon on bare Muon: T0=3.37845, +0.10 above threshold |
| #2295 | fern | **MERGED ✅** | 4 | RI γ=−0.075: 3.27786 — new SOTA baseline |

## Top findings (15:32 UTC)

### 🔥 Nezuko H17 RI on PR #305: T0+T1 reproducibility STRONG

| Trial | γ=0 | γ=−0.05 | γ=−0.075 | Paired Δ at γ=−0.075 |
|---|---:|---:|---:|---:|
| T0 | 3.27844 | 3.27787 | **3.27775** | −0.00069 |
| T1 | 3.27889 | 3.27830 | **3.27821** | −0.00068 |
| T2 | running | running | running | — |

**Provisional n=2 mean at γ=−0.075: 3.27798**. Paired Δ mean −0.000685.
**2× fern's lift on PR #309 base.** If T2-T3 hold this magnitude, **MERGE CANDIDATE BEATING fern's 3.27786.**

### Frieren H5b RI on PR #300: T0 RI HURTS vs Arm A control

T0 Arm A (control, no RI) = 3.27822
T0 Arm B (RI γ=−0.075) = 3.27927 → **Δ = +0.00105 (worse)**

Single-trial signal only — n=4 needed. If T1-T3 confirm, RI is NOT universal across all bases (PR #300 base may lack the RI lift mechanism). This conflicts with PR #305 (nezuko) and PR #309 (fern) showing strong lift.

### Tanjiro H-D Arm A control (flat LR, PR #309 base): strong sub-3.28

T0 = 3.2792, T1 = 3.2777. Even Arm A (control) is performing well. Arm B (late-higher LR) test pending after T3 terminal.

### Edward H-D Arm A control (flat LR, PR #300 base): in-band

T0 = 3.27874 (matches public PR #300 reference 3.27844). T1-T3 pending.

### Askeladd H-I direction ablation: launch issue

Student launched ygmzpq97 + kyihnden as duplicates AND missed the `--ri_extra_gammas` flag that defines the experiment. Sent fix at 15:32 UTC. Without the positive γ sweep, the run is just a fern baseline reproduction.

## Compositional verdict table

| Mechanism | Base | Status |
|---|---|---|
| NC | bare Muon | ✅ CONFIRMED (+0.003 delta at 3325 steps) |
| NC | ALL Aurora-bearing stacks | ❌ FAILED (3 PRs) |
| **RI (γ=−0.075, paired-gamma)** | **PR #309** | **✅ MERGED — 3.27786 at 2890** |
| RI (γ=−0.075) | PR #305 | T0+T1 Δ=−0.000685 ✓✓ (T2-T3 running) |
| RI (γ=−0.075) | PR #300 | T0 Δ=+0.00105 (Arm A vs Arm B comparison) — unfavorable |
| RI + NC | bare Muon | Pending (thorfinn H-F smoke) |
| RI hyperparameter sweep | PR #309 | T0 running (fern H-G z20mj2bh) |
| RI direction ablation (±γ) | PR #309 | Fix in progress (askeladd H-I) |
| Corrected Arbor Muon | PR #309 | Smoke running (alphonse) |
| Cautious-Muon (sign mask) | bare Muon | ❌ FAILED (n=1 abort, +0.10 gap) |
| late-higher block LR (Arm A) | PR #309 | T0=3.2792, T1=3.2777 (tanjiro Arm A) |
| late-higher block LR (Arm A) | PR #300 | T0=3.27874 (edward Arm A) |
| PE NS (wall-clock gate) | PR #309 (H100) | ❌ FAILED gate (+2.23% vs ≥5%) |

## Highest-priority watch items (15:32 UTC)

1. **Askeladd PR #2304 fix-relaunch** — verify kill+relaunch with --ri_extra_gammas flag within next 30 min. Without this fix, the entire experiment is wasted.
2. **Nezuko PR #2297 T2/T3 terminals** (~17:00 / 18:30 UTC) — if both confirm Δ≈−0.00068, MERGE-CANDIDATE.
3. **Frieren PR #2289 T1 terminal** (~16:00 UTC) — clarify whether T0 RI=worse is tail event or systematic on PR #300 base.
4. **Alphonse PR #2298 n=4 launch** — Blackwell now unblocked, smoke at step 100. ETA n=4 finish ~22:00 UTC.
5. **Tanjiro PR #2299 T3 terminal + Arm B launch** (~18:00 UTC for Arm A complete).
6. **Edward PR #2301 T1-T3 + Arm B** (~21:30 UTC for Arm A complete).

## Research focus

**Confirming RI cross-base universality (key open question):**
- PR #309 base: ✅ MERGED 3.27786
- PR #305 base: T0+T1 Δ=−0.000685 (running, looking strong)
- PR #300 base: T0 RI HURTS by +0.00105 (running, n=1 may be tail)
- Bare Muon + NC: smoke running

**Composition direction:**
- RI direction (positive vs negative γ) — askeladd H-I (after fix-relaunch)
- RI capture × γ hyperparameter optimization — fern H-G T0 running
- RI + NC composition — thorfinn H-F (after smoke)
- Late-higher LR — tanjiro + edward dual-base test running
- Arbor Muon — alphonse (unblocked, launching soon)

## Things to AVOID

- NC on any Aurora-bearing stack (falsified 3×)
- PMuon on PR #300 or PR #309 base (falsified cross-base)
- β2-pulse on PR #309 base (falsified)
- Circuit-Muon as standalone (n=4 mean 3.27844)
- Cautious-Muon on ANY base (falsified on bare Muon at +0.10)
- Polar Express NS on H100 (gate failed +2.23% vs ≥5%, GH200-specific)
- Launching paired-gamma sweeps WITHOUT the `--ri_extra_gammas` flag (askeladd just made this mistake — extra gammas are evaluated WITHIN trial via snapshot, free)
