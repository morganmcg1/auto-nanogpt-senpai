# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~22:00 UTC (launch day +1)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE (merged 2026-06-05 13:37 UTC)

**Senpai PR #2295 (fern H15 RI): n=4 mean 3.27786 at 2890 steps** — RI γ=−0.075, capture=2375, on PR #309 base.

## Active assignments (22:00 UTC)

| PR | Student | Hypothesis | Base | Target | Status |
|---:|---|---|---|---:|---|
| **#2302** | open2-fern | H-G RI hyperparameter sweep (capture × γ, 9 arms) | PR #309 | 2890 | T0 ~11% — early. |
| **#2298** | open2-alphonse | H-A Arbor Muon **corrected variant** (sqrt(out_dim) pin removed) | PR #309 | 2890 | n=4 `5weg8d9r` T0 at 24%. ETA terminal ~02:50 UTC. |
| **#2304** | open2-askeladd | H-I RI direction ablation (paired-γ 8 arms) | PR #309 | 2890 | T0-T2 done, **T3 at 92%**. γ=−0.075 = 3.2785 aggregate. ETA ~00:30 UTC. |
| **#2301** | open2-edward | H-D late-higher block LR on PR #300 base | PR #300 | 2925 | **Arm A done n=4=3.279866** (T3 tail 3.281341). Arm B `jbdhh1bz` at 24%. ETA ~03:15 UTC. |
| **#2289** | open2-frieren | H5b RI on PR #300 base (Arm A control / Arm B RI) | PR #300 | 2930 | **CLOSE 22:00 UTC** — Arm B n=4=3.27877, paired Δ=−0.00056 (p<0.05). Universality confirmed; absolute > fern's 3.27786 at +40 steps. |
| **#2303** | open2-thorfinn | H-F RI + NC on bare Muon (universality) | bare Muon | 3325 | **T2 = 3.272994** at γ=−0.075 (BEST val/loss on fleet). T3 at 84%. ETA ~23:30 UTC. |
| **#2299** | open2-tanjiro | H-D late-higher block LR on PR #309 base | PR #309 | 2890 | Arm A n=4=3.27861. **Arm B v2 T0=3.277499 (beats fern), T1=3.282439 (tail).** T2 at 50%. |
| **#2305** | open2-nezuko | H-J Two-Snapshot Tail Extrapolation | PR #309 | 2890 | **T0 disproves H-J** — γ_2=0 wins (3.279136). T1 just started. |

## Closures this round (since 19:15 UTC)

| PR | Student | Verdict | n | Key finding |
|---:|---|---|---:|---|
| #2289 | frieren | **CLOSED 22:00** | 4 | RI on PR #300: paired Δ=−0.00056 (p<0.05, t=−3.42, 4/4 lift). Absolute 3.27877 > fern's 3.27786 due to PR #300 base being weaker than PR #309. Confirms RI is base-agnostic. |

## 🔥 Top findings (22:00 UTC)

### Thorfinn H-F RI + NC on bare Muon — STRONGEST ABSOLUTE val/loss on fleet

| Trial | val/loss (best γ=−0.075) | Step |
|---|---:|---:|
| T0 | 3.275366 | 3325 |
| T1 | 3.275821 | 3325 |
| **T2** | **3.272994** ← BEST | 3325 |
| T3 | running, 84% | 3325 |

Per-γ at T2: γ=0→3.273498, γ=−0.05→3.273050, **γ=−0.075→3.272994**.

**This is the largest absolute val/loss lift on the fleet** (3.272994 vs fern's 3.27786 = −0.0049). BUT at 3325 steps vs fern's 2890, so it cannot directly displace fern from rank-1 in the speedrun benchmark. The mechanism (NC+RI on bare Muon) is composing additively.

**Next-action implication: port NC (Cautious-Muon) to PR #309 base + RI at 2890 steps.** If NC delivers any positive paired Δ, the composition becomes a true rank-1 candidate.

### Askeladd H-I RI direction ablation — DIRECTION-SPECIFIC mechanism confirmed at n=3

T0-T2 aggregate per-γ ranking (PR #309 base, 2890 steps):

| γ | Mean val/loss | Δ vs γ=0 |
|---|---:|---:|
| **−0.075** | **3.2785** | **best (saturated)** |
| −0.10 | 3.2786 | +0.0001 |
| −0.05 | 3.2785 | best (saturated) |
| 0 | 3.2788 | baseline |
| +0.05 | 3.2796 | +0.0008 (hurts) |
| +0.25 | 3.2872 | +0.0084 (catastrophic) |
| +0.50 | 3.3084 | +0.0296 (catastrophic) |
| +1.00 | 3.4048 | +0.126 (destroys training) |

**Confirms RI is TAIL EXTRAPOLATION (away from snapshot toward final direction), not SWA-style averaging.** Mechanism is direction-specific and saturates at γ ≈ −0.05 to −0.10. T3 at 92% — final n=4 projection ~3.2775.

### Tanjiro H-D late-higher LR on PR #309 — MIXED signal at n=2

- Arm A (flat control): n=4=3.27861 (T0=3.27917, T1=3.27770, T2=3.27772, T3=3.27984)
- Arm B v2 (late-higher LR):
  - T0=3.277499 (BEATS fern's merged 3.27786 by −0.00036!)
  - T1=3.282439 (tail event)
  - T2/T3 pending (T2 at 50%)

n=2 mean already 3.279969. If T2+T3 are ~3.2775, n=4 mean ≈ 3.27894 — slightly above fern. The T1 tail is concerning; need T2/T3 to interpret.

### Nezuko H-J Two-Snapshot Tail Extrapolation — DISPROVEN at T0

Best (γ_1, γ_2) at T0: (−0.075, **0.000**) = 3.279136. Adding any second-snapshot γ_2 ≠ 0 degrades. **Single-snapshot is the optimum** — Richardson-style two-point extrapolation does not help on this trajectory. T1+ may slightly shift this but the structural result is clear.

**Mechanism implication:** the parameter trajectory near training-end is well-approximated by a single linear extrapolation; the higher-order curvature term we hoped to capture is dominated by noise. RI's mechanism is fundamentally first-order.

### Edward H-D late-higher LR on PR #300 — Arm A done, Arm B running

Arm A n=4=3.279866 (T3 tail 3.281341 inflates the mean; T0-T2 cluster tightly at 3.27871).  Stat contract margin 0.000536 < 0.004 (fails as control, expected). Arm B `jbdhh1bz` at T0 24%; ETA ~03:15 UTC.

### Alphonse H-A Arbor Muon — corrected variant launched

n=4 corrected `5weg8d9r` (sqrt(out_dim) pin dropped, default Muon scaling restored). At T0 24%. ETA terminal ~02:50 UTC. Smoke at step 500 was 3.78166 vs broken-variant 4.30753 — large step-500 lift suggests the corrected variant is at least training stably.

### Frieren H5b RI on PR #300 — TERMINAL (closing 22:00 UTC)

Arm A n=4=3.27934 (T1=3.28002 tail). Arm B n=4=3.27877. Paired Δ=−0.00056, p<0.05, 4/4 trial pairs lift. Doesn't beat fern's 3.27786 (PR #300 base is weaker than PR #309); closes as universality confirmation.

### Fern H-G RI hyperparameter sweep — early

T0 at 11%. ETA ~10h from now.

## Compositional verdict table (updated 22:00 UTC)

| Mechanism | Base | Status |
|---|---|---|
| NC (Cautious-Muon) | bare Muon | ✅ CONFIRMED (delta vs control >0.003) |
| NC + RI | bare Muon | ✅ STRONG — best absolute val/loss on fleet (3.272994 at 3325 steps) |
| RI | PR #300 (Aurora+CM+SOAP) | ✅ UNIVERSAL — paired Δ=−0.00056 (p<0.05) |
| RI | PR #305 (Aurora+RRE+CM+SOAP) | ✅ UNIVERSAL (nezuko n=4=3.278421, paired Δ=−0.000664) |
| RI | PR #309 (Aurora+EMA-Nest) | ✅ MERGED at 3.27786 |
| Two-snapshot RI (H-J) | PR #309 | ❌ DISPROVEN (γ_2=0 wins; single-snapshot is the optimum) |
| Late-higher block LR | PR #300 | ⏳ Arm B running |
| Late-higher block LR | PR #309 | ⏳ Arm B v2 running (T0 strong, T1 tail) |
| Arbor Muon (sqrt out_dim pin) | PR #309 | ❌ FALSIFIED (55× lift bug) |
| Arbor Muon (corrected) | PR #309 | ⏳ T0 running |
| RI direction (negative γ) | PR #309 | ✅ CONFIRMED — direction-specific, saturates at γ ≈ −0.05 to −0.10 |
| RI direction (positive γ) | PR #309 | ❌ FALSIFIED — catastrophic at γ > 0 |

## Next-wave hypothesis backlog (ordered by tier)

**Tier 1 — High-value compositions of confirmed mechanisms:**
1. **NC (Cautious-Muon) on PR #309 + RI base, n=4 at 2890 steps** — port thorfinn's bare-Muon win to PR #309. Frieren next. Paired arms: A=PR#309+RI (fern's merged), B=PR#309+RI+NC.
2. **NC on PR #300 + RI base** — second universality test of NC. Possibly edward/frieren after closure.
3. **Late-higher LR + RI on PR #309 base** — compose tanjiro's promising late-higher T0 with fern's merged RI in a paired-arm experiment.

**Tier 2 — Schedule / readout experiments:**
4. **lm_head freeze tail (final 5-10% of training)** — reduce readout-layer noise in the last cooldown phase. Cheap to implement.
5. **EMA-of-snapshots tail blend** — maintain rolling EMA after capture_step, blend EMA into terminal weights (variant of RI).
6. **Per-layer adaptive γ for RI** — different γ for different blocks based on layer drift magnitude.

**Tier 3 — Alternative tail extrapolation:**
7. **Capture-step sweep with paired-γ (NC base)** — find optimal capture point on bare-Muon NC base.
8. **Aitken's Δ² acceleration** — non-linear sequence acceleration applied to terminal-window parameter trajectory.

## Watch items (next 6h)

- **Thorfinn T3 terminal** (~23:30 UTC) — SENPAI-RESULT for H-F bare-Muon NC+RI; if n=4 mean ≈ 3.2745, then NC is high-value to port to PR #309
- **Askeladd T3 terminal** (~00:30 UTC) — H-I direction ablation final, projected n=4 ≈ 3.2775
- **Tanjiro T2 terminal** (~22:30 UTC) — interpret T1 tail event
- **Edward Arm B T0 terminal** (~22:30 UTC) — first late-higher signal on PR #300
- **Alphonse corrected n=4** (~02:50 UTC) — Arbor Muon last shot
- **Nezuko H-J T1+** — confirm γ_2=0 dominates across n=4 (H-J disproof)
- **Fern H-G T0** — capture-step sensitivity early read

## Operational notes

- Blackwell pods (nezuko, thorfinn, alphonse) all confirmed running torch==2.12.0+cu130 after the silent 2.10.0 downgrade incident. Watch for recurrence.
- All 8 students have an active hypothesis. Zero idle GPUs after frieren reassignment.
