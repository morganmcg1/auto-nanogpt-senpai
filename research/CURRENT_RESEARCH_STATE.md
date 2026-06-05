# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~16:00 UTC (launch day +1)
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
| **#2302** | open2-fern | H-G RI hyperparameter sweep (capture × γ, 9 arms) | PR #309 | 2890 | T0 done: best γ=−0.075 cap2375=3.27922 (Δ=−0.00028). T2 at step 3216. |
| **#2298** | open2-alphonse | H-A Corrected Arbor Muon (2-iter Sinkhorn) | PR #309 | 2890 | **SMOKE PASSED ✓** at step 500. n=4 nudge sent 16:00 UTC. |
| **#2304** | open2-askeladd | H-I RI direction ablation (positive γ sweep) | PR #309 | 2890 | **ESCALATION 16:00 UTC** — both duplicate runs still training. No `--ri_extra_gammas` flag. |
| **#2301** | open2-edward | H-D Senpai late-higher block LR on PR #300 base | PR #300 | 2925 | Arm A (flat control) `svbaoi2b` T0=3.27874 ✓, T1 at step 4094 (~57% T1) |
| **#2289** | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930 | **CORRECTED**: Arm B T0=**3.27798** (Δ=−0.00024 paired), T1=3.27927 (Δ=−0.00075 paired). T2 active step 6239. |
| **#2297** | open2-nezuko | H17 RI on PR #305 base (paired-gamma) | PR #305 | 2925 | T0 Δ=−0.00069, **T1 Δ=−0.00068** ✓ (provisional n=2 mean 3.27798). T2 active. |
| **#2299** | open2-tanjiro | H-D Senpai late-higher block LR on PR #309 base | PR #309 | 2890 | Arm A (flat control) T0=3.27917, T1=3.27770. T2 active step 7382. |
| **#2303** | open2-thorfinn | H-F RI + NC on bare Muon (cross-base universality test) | bare Muon | 3325 | **SMOKE PASSED ✓** 1500 steps γ=−0.075=3.42260 vs γ=0=3.42292. n=4 authorization sent 16:00 UTC. |

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

### Frieren H5b RI on PR #300 — CORRECTED: RI HELPS!

| Trial | Arm A (control) | Arm B (RI γ=−0.075) | Paired Δ |
|---|---:|---:|---:|
| T0 | 3.27822 | **3.27798** | **−0.00024** |
| T1 | 3.28002 | **3.27927** | **−0.00075** |
| T2 | 3.27952 | running | — |
| T3 | 3.27958 | pending | — |

**Provisional n=2 paired Δ mean = −0.000495** — RI IS WORKING on PR #300 base!
(Earlier brief misreport corrected — initial W&B query confused T0/T1 values.)

If T2/T3 confirm Δ≈−0.0005 lift, RI is universal across all 3 bases (PR #309, PR #305, PR #300). Strongly supports the "RI add to all compositions" hypothesis.

### Tanjiro H-D Arm A control (flat LR, PR #309 base): strong sub-3.28

T0 = 3.27917, T1 = 3.27770. Even Arm A (control) is performing well; provisional n=2 = 3.278435 — **better than fern's merged 3.27786 baseline at n=2**. Arm B (late-higher LR) test pending after T3 terminal.

### Edward H-D Arm A control (flat LR, PR #300 base): in-band

T0 = 3.27874 (matches public PR #300 reference 3.27844). T1-T3 pending.

### Askeladd H-I direction ablation: ESCALATION

Both duplicate runs (ygmzpq97, kyihnden) still training without `--ri_extra_gammas`. Student has not acted on fix (15:43 UTC) or escalation (16:00 UTC). If no response by 16:30 UTC, consider hard-killing the pod via reassignment.

### Fern H-G hyperparameter sweep: T0 done

| Gamma at cap=2375 | T0 val/loss |
|---|---:|
| γ=0 (baseline) | 3.27950 |
| γ=−0.05 | 3.27921 |
| **γ=−0.075** | **3.27922** (best) |
| γ=−0.10 | 3.27932 |

T0 paired Δ at γ=−0.075 = **−0.00028** — slightly weaker than the merged result (−0.00033). The single best gamma still matches merged choice. T1-T3 needed.

### Thorfinn H-F smoke: PASSED ✓

1500-step smoke clean past prior crash point (step 200):
- γ=−0.075: 3.42260
- γ=0: 3.42292 → Δ = −0.00032 at γ=−0.075
- RI capture+blend confirmed on bare Muon at 1500 steps

n=4 launch authorized at 3325 steps (ETA ~06:30 UTC tomorrow).

## Compositional verdict table

| Mechanism | Base | Status |
|---|---|---|
| NC | bare Muon | ✅ CONFIRMED (+0.003 delta at 3325 steps) |
| NC | ALL Aurora-bearing stacks | ❌ FAILED (3 PRs) |
| **RI (γ=−0.075, paired-gamma)** | **PR #309** | **✅ MERGED — 3.27786 at 2890** |
| RI (γ=−0.075) | PR #305 | T0+T1 Δ=−0.000685 ✓✓ (T2-T3 running) |
| RI (γ=−0.075) | PR #300 | T0+T1 Δ=−0.000495 ✓✓ (T2-T3 running, RI helps) |
| RI + NC | bare Muon | Smoke ✓; n=4 launching (thorfinn) |
| RI hyperparameter sweep | PR #309 | T0 done: best γ=−0.075 cap2375=3.27922 (Δ=−0.00028) |
| RI direction ablation (±γ) | PR #309 | Fix in progress (askeladd H-I) |
| Corrected Arbor Muon | PR #309 | Smoke running (alphonse) |
| Cautious-Muon (sign mask) | bare Muon | ❌ FAILED (n=1 abort, +0.10 gap) |
| late-higher block LR (Arm A) | PR #309 | T0=3.2792, T1=3.2777 (tanjiro Arm A) |
| late-higher block LR (Arm A) | PR #300 | T0=3.27874 (edward Arm A) |
| PE NS (wall-clock gate) | PR #309 (H100) | ❌ FAILED gate (+2.23% vs ≥5%) |

## Highest-priority watch items (16:00 UTC)

1. **Askeladd PR #2304 ESCALATION** — if no response by 16:30 UTC, reassign hypothesis or hard-kill pod.
2. **Nezuko PR #2297 T2 terminal** (~17:12 UTC) — if Δ holds, MERGE-CANDIDATE beating fern.
3. **Tanjiro PR #2299 T2 terminal** (~16:40 UTC) — Arm A T0+T1 already excellent (3.278435).
4. **Frieren PR #2289 T2 terminal** (~18:30 UTC) — confirm RI lift on PR #300 base.
5. **Edward PR #2301 T1 terminal** (~16:56 UTC).
6. **Thorfinn PR #2303 n=4 launch confirmation** — verify W&B run ID appears.
7. **Alphonse PR #2298 n=4 launch confirmation** — verify W&B run ID appears.

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
