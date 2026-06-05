# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~19:15 UTC (launch day +1)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE (merged 2026-06-05 13:37 UTC)

**Senpai PR #2295 (fern H15 RI): n=4 mean 3.27786 at 2890 steps** — RI γ=−0.075, capture=2375, on PR #309 base.

## Active assignments (as of 2026-06-05 ~19:15 UTC)

| PR | Student | Hypothesis | Base | Target | Status |
|---:|---|---|---|---:|---|
| **#2302** | open2-fern | H-G RI hyperparameter sweep (capture × γ, 9 arms) | PR #309 | 2890 | T1 done (γ=−0.075 cap=2375 still best). T2 active. |
| **#2298** | open2-alphonse | H-A Corrected Arbor Muon | PR #309 | 2890 | **ABORT 19:10 UTC** — T0=3.32278, T1=3.32056 (55× lift bug). Pivot to corrected scaling authorized. |
| **#2304** | open2-askeladd | H-I RI direction ablation (paired-γ 8 arms) | PR #309 | 2890 | **n=2 STRONG.** T0+T1 γ=−0.075: 3.277050/3.277379 (best on fleet). +γ catastrophic. T2 running. |
| **#2301** | open2-edward | H-D late-higher block LR on PR #300 base | PR #300 | 2925 | Arm A T0+T1: 3.27874/3.27872. T2 in progress. Arm B chains. |
| **#2289** | open2-frieren | H5b RI on PR #300 base (Arm A control / Arm B RI) | PR #300 | 2930 | Arm A done (n=4=3.27934). **Arm B T0/T1/T2 paired Δ −0.00024/−0.00075/−0.00092.** T3 in T4 warmup. |
| **#2297** | open2-nezuko | H17 RI on PR #305 base (paired-γ) | PR #305 | 2925 | **CLOSED 19:10 UTC** — n=4=3.278421. Universality confirmed, but fails contract at 2925 steps. |
| **#2299** | open2-tanjiro | H-D late-higher block LR on PR #309 base | PR #309 | 2890 | Arm A done (n=4=3.27861, FALSIFIED). **Arm B v2 `xcwr1ed9` running** (after double-launch collision resolved). |
| **#2303** | open2-thorfinn | H-F RI + NC on bare Muon (universality) | bare Muon | 3325 | **T0 STRONG** γ=−0.075=3.27537 (Δ=−0.00049). T1 ETA ~19:30 UTC. |

## Closures this round (since 15:32 UTC update)

| PR | Student | Verdict | n | Key finding |
|---:|---|---|---:|---|
| #2297 | nezuko | **CLOSED** | 4 | RI on PR #305: n=4 paired Δ=−0.000664 (largest on fleet) but absolute val/loss 3.278421 > fern's 3.27786 |

## Top findings (19:15 UTC)

### 🔥 Askeladd H-I RI direction ablation — DIRECTION-ASYMMETRY CONFIRMED at n=2

Per-trial paired-γ values at end of trial (PR #309 base, 2890 steps):

| γ | T0 | T1 | n=2 mean |
|---|---:|---:|---:|
| **−0.10** | 3.277152 | 3.277468 | 3.277310 |
| **−0.075** | **3.277050** | **3.277379** | **3.277215** ← BEST |
| **−0.05** | 3.277058 | 3.277390 | 3.277224 |
| 0 | 3.277353 | 3.277713 | 3.277533 |
| +0.05 | 3.278089 | 3.278467 | 3.278278 |
| +0.25 | 3.285616 | 3.286036 | 3.285826 (+0.0083) |
| +0.50 | 3.306867 | 3.307252 | 3.307060 (+0.0297) |
| +1.00 | 3.403965 | 3.403688 | 3.403827 (+0.126) |

**Key findings:**
- **Negative γ saturates at γ ≈ −0.05 to −0.10** (no extra lift beyond γ=−0.05)
- **Positive γ scales catastrophically** — even γ=+0.05 hurts; γ=+1.00 destroys training
- **The mechanism is TAIL EXTRAPOLATION, not weight averaging.** SWA-direction (positive γ) is unambiguously harmful.
- T0 γ=−0.075 = 3.277050 is the **single best trial on the fleet** (beats fern's merged single-trial 3.27765).

**n=4 projection:** if T2/T3 hold ~3.2772, n=4 mean ≈ 3.27722 → stat contract margin = (3.28−3.27722)×2 = 0.00556, PASSES 0.004. Could supersede fern's 3.27786 at SAME step count (same base, same gamma).

### Frieren H5b RI on PR #300 — HEALTHY, RI LIFT CONFIRMED AT n=3

Arm A (control, no RI):
- T0 3.27822, T1 3.28002, T1 tail event, T2 3.27952, T3 3.27958 → n=4 = **3.27934**

Arm B (RI applied, γ=−0.075):
- T0 3.27798, T1 3.27927, T2 3.27860, T3 in warmup → provisional n=3 = **3.27862**
- Paired Δ vs Arm A: T0=−0.00024, T1=−0.00075, T2=−0.00092 → **n=3 paired Δ mean = −0.000637**

**The "divergence" earlier reported was AGENT MISREAD** of trial reset warmup curves. Run is healthy.

If T3 holds, Arm B n=4 ≈ 3.2786, paired Δ n=4 ≈ −0.00074. Confirms RI universality on PR #300 with comparable magnitude to nezuko's PR #305 finding.

### Thorfinn H-F RI + NC on bare Muon — LARGEST SINGLE LIFT ON FLEET (T0)

| γ | T0 |
|---|---:|
| 0 (NC only) | 3.275862 |
| −0.05 | 3.275421 |
| **−0.075** | **3.275366** ← Δ=−0.000496 |

Strongest absolute val/loss at γ=−0.075 yet (3.275366) — but at 3325 steps, so not a direct record-beater vs fern's 2890-step. Confirms RI+NC composition is additive on bare Muon.

T1 ETA ~19:30 UTC.

### Nezuko H17 RI on PR #305 (CLOSED) — universality confirmed but no merge

| Trial | γ=0 | γ=−0.075 | Paired Δ |
|---|---:|---:|---:|
| T0 | 3.278435 | 3.277755 | −0.000680 |
| T1 | 3.278891 | 3.278214 | −0.000677 |
| T2 | 3.278571 | 3.277914 | −0.000657 |
| T3 | 3.280442 | 3.279802 | −0.000640 |

**n=4 mean γ=−0.075 = 3.278421** | paired Δ mean = −0.000664 (SE 0.0000086, essentially zero variance).

**FAILS contract at 2925 steps** (margin 0.00316 < 0.004). **DOES NOT BEAT fern's 3.27786** (PR #305 base γ=0 control is 0.00089 worse than PR #309 base γ=0, can't be overcome by RI lift). Closed as universality confirmation; reassignment pending.

### Tanjiro H-D Arm A control — falsified as record beater (PR #309 base)

n=4 mean 3.27861 (T0=3.27917, T1=3.27770, T2=3.27772, T3=3.27984). Tight cluster but slightly above fern's 3.27786. Arm B (late-higher LR) v2 launched after double-launch collision; T0-T3 pending.

### Edward H-D Arm A control (PR #300 base) — flat tracking

T0=3.27874, T1=3.27872 (very tight). T2 in progress at step 375 of trial 3. Arm B chains.

### Alphonse H-A Corrected Arbor Muon — ABORTED, pivot in flight

T0=3.32278, T1=3.32056 (~+0.045 above baseline). Student diagnosed the spec's `sqrt(out_dim)` post-Sinkhorn pin produces 55× magnitude lift on mlp.fc — broken. Authorized corrected variant: drop the post-Sinkhorn scaling entirely, let default `max(1, out/in)**0.5` Muon path apply. Smoke + n=4 corrected ETA ~02:30 UTC tomorrow.

### Fern H-G hyperparameter sweep — γ=−0.075 cap=2375 holds as optimum

T0+T1 confirm the merged choice is the local optimum. T2 in progress.

## Compositional verdict table

| Mechanism | Base | Status |
|---|---|---|
| NC | bare Muon | ✅ CONFIRMED (+0.003 delta at 3325 steps) |
| NC | ALL Aurora-bearing stacks | ❌ FAILED (3 PRs) |
| **RI (γ=−0.075, paired-γ)** | **PR #309** | **✅ MERGED — 3.27786 at 2890** |
| RI (γ=−0.075) | PR #305 | ✅ n=4 paired Δ=−0.000664 (largest on fleet) BUT base too slow to beat record |
| RI (γ=−0.075) | PR #300 | ✅ n=3 paired Δ=−0.000637 (confirmed working) |
| RI + NC | bare Muon | ✅ T0 paired Δ=−0.00049 (T1-T3 running) |
| RI direction ablation (±γ) | PR #309 | ✅ **n=2 confirms +γ catastrophic, −γ helps (saturates at γ≈−0.05)** |
| RI hyperparameter sweep | PR #309 | ✅ γ=−0.075 cap=2375 is local optimum (T0+T1) |
| Corrected Arbor Muon | PR #309 | ❌ FALSIFIED at n=1.5 (55× lift bug). Pivot in flight. |
| Cautious-Muon (sign mask) | ANY | ❌ FALSIFIED |
| Late-higher LR (paired) | PR #309 Arm A | n=4=3.27861 (tighter cluster than fern but doesn't beat). Arm B v2 running. |
| Late-higher LR (paired) | PR #300 Arm A | T0+T1 in (~3.27873). Arm B chains. |
| PE NS (wall-clock gate) | PR #309 (H100) | ❌ FAILED gate (+2.23% vs ≥5%, GH200-specific) |

## Highest-priority watch items (19:15 UTC)

1. **Askeladd PR #2304 T2 terminal** (~20:30 UTC) — if γ=−0.075 holds ~3.2773, n=4 ≈ 3.27722 → **SUPERSEDE MERGE CANDIDATE** vs fern.
2. **Thorfinn PR #2303 T1 terminal** (~19:30 UTC) — if Δ holds, cross-base + composition validation.
3. **Alphonse PR #2298 corrected variant pickup** — watch for new W&B run IDs (smoke + n=4).
4. **Edward PR #2301 T2/T3 terminals** (~20:00 UTC) — Arm A reproduce, then Arm B late-higher LR.
5. **Tanjiro PR #2299 Arm B v2 (`xcwr1ed9`) T0 terminal** (~22:30 UTC) — late-higher LR true test.
6. **Frieren PR #2289 T3 Arm B terminal** (~22:00 UTC) — confirms n=4 paired Δ on PR #300.
7. **Fern PR #2302 T2/T3 sweep terminals** — confirms hyperparameter local optimum.
8. **Nezuko assignment** — new hypothesis (H-J Multi-snapshot Tail Extrapolation? — pending researcher-agent output).

## Research focus (19:15 UTC)

**Confirmed:** RI is universal across all 4 tested bases (PR #309 merged, PR #305 nezuko, PR #300 frieren, bare Muon thorfinn). Lift magnitude correlates with base "choppiness" — PR #305 with RRE damping gives 2× lift of PR #309 with EMA-Nesterov.

**Direction confirmed:** Tail EXTRAPOLATION (γ<0). SWA-direction (γ>0) catastrophic. Saturates at γ ∈ [−0.10, −0.05].

**Open questions:**
- Can we beat fern's 3.27786 at FEWER than 2890 steps?
- Does multi-snapshot extrapolation give bigger lift than single-snapshot?
- Can a corrected Arbor (spectrum equilibration without magnitude bug) help?
- Does late-higher LR compose with RI?
- What other ML/physics mechanisms haven't been tried?

**Active researcher-agent** (background) generating H-K, H-L, H-M, ... hypotheses for next round.

## Things to AVOID

- NC on any Aurora-bearing stack (falsified 3×)
- PMuon on PR #300 or PR #309 base (falsified cross-base)
- β2-pulse on PR #309 base (falsified)
- Circuit-Muon as standalone (n=4 mean 3.27844)
- Cautious-Muon on ANY base (falsified at +0.10)
- Polar Express NS on H100 (gate failed, GH200-specific)
- Positive γ in RI (catastrophic per H-I data)
- Arbor Muon with `sqrt(out_dim)` post-NS scaling (55× lift bug)
- Launching paired-γ sweeps without `--ri_extra_gammas` flag
