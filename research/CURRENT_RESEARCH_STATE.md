# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~23:40 UTC (launch day +1)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE (merged 2026-06-05 13:37 UTC)

**Senpai PR #2295 (fern H15 RI): n=4 mean 3.27786 at 2890 steps** — RI γ=−0.075, capture=2375, on PR #309 base.

## Active assignments (23:10 UTC)

| PR | Student | Hypothesis | Base | Target | Status |
|---:|---|---|---|---:|---|
| **#2302** | open2-fern | H-G RI hyperparameter sweep (capture × γ, 9 arms) | PR #309 | 2890 | Newest trial at step 2775/11563 (24%). ETA ~5.5h. |
| **#2298** | open2-alphonse | H-A Arbor Muon **corrected variant** (sqrt(out_dim) pin removed) | PR #309 | 2890 | **T0 = 3.27749 BEATS fern's merged 3.27786 by −0.00037.** T1 at 37% (4291/11563). ETA terminal ~02:57 UTC. |
| **#2307** | open2-askeladd | **H-L lm_head freeze tail (paired arms, n=4)** | PR #309+RI | 2890 | **NEW assignment 23:00 UTC.** Pod picked up at iter 100. Smoke expected next. |
| **#2301** | open2-edward | H-D late-higher block LR on PR #300 base | PR #300 | 2925 | Arm A done n=4=3.279866. **Arm B T0=3.27978 vs Arm A T0=3.278741 → paired Δ_T0=+0.001 UNFAVORABLE.** T1 at 37%. ETA ~03:15 UTC. |
| **#2306** | open2-frieren | **H-K NC (Cautious-Muon) on PR #309 + RI base** | PR #309 | 2890 | Picked up at iter 108. Smoke `u5qix3rj` at step 850 (past 500-step gate). Aims to compose NC (from thorfinn H-F) with fern's merged RI on strongest base. |
| **#2308** | open2-thorfinn | **H-M NC + RI on bare Muon at 2890 steps** (speedrun adaptation) | bare Muon | 2890 | **NEW assignment 23:35 UTC.** Smoke expected. Tests if bare-Muon family can beat fern's merged 3.27786 at the SAME step budget. |
| **#2299** | open2-tanjiro | H-D late-higher block LR on PR #309 base | PR #309 | 2890 | Arm A n=4=3.27861. **Arm B v2 T0=3.277499 (beats fern), T1=3.282439 (tail).** T2 at 63% (7307/11563). |
| **#2305** | open2-nezuko | H-J Two-Snapshot Tail Extrapolation | PR #309 | 2890 | **T0 disproves H-J** — γ_2=0 wins (3.279136). T1 at 43% (4991/11563). |

## Closures this round (since 19:15 UTC)

| PR | Student | Verdict | n | Key finding |
|---:|---|---|---:|---|
| #2289 | frieren | **CLOSED 22:00** | 4 | RI on PR #300: paired Δ=−0.00056 (p<0.05, t=−3.42, 4/4 lift). Absolute 3.27877 > fern's 3.27786 due to PR #300 base being weaker than PR #309. Confirms RI is base-agnostic. |
| #2304 | askeladd | **CLOSED 22:55** | 4 | H-I direction ablation: γ=−0.075 n=4=3.27872 (T3=3.28195 tail). Direction-specific RI mechanism confirmed: negative γ saturates at −0.05/−0.075/−0.10; positive γ catastrophic from +0.05 onward (+1.00 destroys training, +0.126). RI is strictly **tail extrapolation**, not SWA. |
| #2303 | thorfinn | **CLOSED 23:35** | 4 | H-F NC+RI on bare Muon: **n=4 best-γ 3.274723**, paired Δ=−0.000504 (SE 3.1e-6, deterministic). Universality confirmed (4th base). step_to_target=3243.75 > fern's 2890 → cannot displace fern in speedrun. LOW tail variance (no T3 tail, σ(Δ)=6.4e-6). |

## 🔥 Top findings (22:40 UTC)

### 🎯 Alphonse H-A corrected Arbor Muon T0 = 3.27749 — BEATS fern's merged record (single trial)

| Metric | Value |
|---|---:|
| T0 val/loss @ step 2890 | **3.27749** |
| vs PR #305 reference (3.27813) | **−0.00064** ✅ |
| **vs fern's MERGED 3.27786** | **−0.00037** ✅ |
| vs PR #309 base alone (3.27799) | **−0.00050** ✅ |
| vs broken sqrt(out_dim) variant (3.32278) | **−0.04529** ✅ (forensic abort validated) |

If T1-T3 cluster near T0 ± seed noise (~0.0008): n=4 mean ≈ 3.27770 → contract margin 0.00461 (PASSES 0.004) → **rank-1 candidate at 2890 steps**. Risk: PR #309 base shows visible tail events at T1+ in multiple recent runs (frieren Arm A T1=3.28002, fern T3=3.27984, tanjiro Arm B v2 T1=3.282439); one tail in T1-T3 inflates the mean. T0 alone is the strongest single-trial 2890-step result on the fleet.

**Mechanism:** Sinkhorn equilibration with default Muon scaling (the sqrt(out_dim) 55× pin removed). Pure row/column statistic rebalancer — exactly what the original spec intended.



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
| NC + RI | bare Muon | ✅ CONFIRMED n=4 — best absolute val/loss 3.274723 at 3325 steps, paired Δ=−0.000504 (deterministic) |
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

**Tier 1 — High-value compositions of confirmed mechanisms (ASSIGNED):**
1. **NC (Cautious-Muon) on PR #309 + RI base, n=4 at 2890 steps** — ASSIGNED to frieren as H-K (PR #2306). Smoke running.
2. **lm_head freeze tail on PR #309 + RI base (paired arms)** — ASSIGNED to askeladd as H-L (PR #2307).
3. **Arbor Muon corrected variant on PR #309 base** — Alphonse H-A (PR #2298), T0=3.27749 already beats fern.

**Tier 2 — Unassigned (next idle-student picks):**
4. **NC on PR #300 + RI base** — second universality test of NC after H-K reads out.
5. **Late-higher LR + RI on PR #309 base** — compose tanjiro's promising late-higher T0 with fern's merged RI in a paired-arm experiment.
6. **EMA-of-snapshots tail blend** — maintain rolling EMA after capture_step, blend EMA into terminal weights (variant of RI).
7. **Per-layer adaptive γ for RI** — different γ for different blocks based on layer drift magnitude.

**Tier 3 — Alternative tail extrapolation / training-curve mechanisms:**
8. **Capture-step sweep with paired-γ (NC base)** — find optimal capture point on bare-Muon NC base.
9. **Aitken's Δ² acceleration** — non-linear sequence acceleration applied to terminal-window parameter trajectory.
10. **Combined RI+Arbor (if both T0+T1 hold individually)** — orthogonality test of two top mechanisms.

## Watch items (next 6h, from 23:10 UTC)

- **Thorfinn T3 TERMINAL 23:33 UTC** — SENPAI-RESULT received: n=4 best-γ 3.274723, paired Δ −0.000504. PR #2303 closed. H-M speedrun adaptation assigned as PR #2308.
- **Alphonse T1 terminal** (~23:43 UTC) — Confirm corrected Arbor T0=3.27749 holds at T1. If T1 ≤ 3.2780, n=4 projection still beats fern.
- **Edward Arm B T1+** — Paired Δ_T0 +0.001 is unfavorable; need T1+ to confirm or reverse. ETA T1 ~00:30 UTC.
- **Tanjiro T2/T3 terminals** — Arm B v2 T0 beats fern but T1 tail; need full n=4 to compute paired Δ.
- **Frieren H-K smoke `u5qix3rj` completion** — Confirm NC+RI on PR #309 trains; then n=4 launch.
- **Askeladd H-L smoke** — pod just picked up, first smoke run will land in ~10-30 min.
- **Nezuko H-J T1-T3** — Confirm γ_2=0 dominates across n=4 (H-J disproof at n=4). Also gives 4 control runs of single-snapshot RI on PR #309 base for cross-checking.
- **Alphonse corrected n=4** (~02:57 UTC) — Arbor Muon final read.
- **Fern H-G T0** — capture-step sensitivity early read.

## Operational notes

- Blackwell pods (nezuko, thorfinn, alphonse) all confirmed running torch==2.12.0+cu130 after the silent 2.10.0 downgrade incident. Watch for recurrence.
- All 8 students have an active hypothesis. Zero idle GPUs after frieren reassignment.
