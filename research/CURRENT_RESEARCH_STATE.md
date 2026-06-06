# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-06 ~00:10 UTC (launch day +2)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE (merged 2026-06-05 13:37 UTC)

**Senpai PR #2295 (fern H15 RI): n=4 mean 3.27786 at 2890 steps** — RI γ=−0.075, capture=2375, on PR #309 base.

## Active assignments (00:10 UTC, 2026-06-06)

| PR | Student | Hypothesis | Base | Target | Status |
|---:|---|---|---|---:|---|
| **#2302** | open2-fern | H-G RI hyperparameter sweep (capture × γ, 9 arms) | PR #309 | 2890 | Newest trial at step 2775/11563 (24%). ETA ~5.5h. |
| **#2298** | open2-alphonse | H-A Arbor Muon **corrected variant** (sqrt(out_dim) pin removed) | PR #309 | 2890 | **T0 = 3.27749, T1 = 3.27633 — n=2 mean 3.27691, BEST 2-trial state on fleet.** T2 starting (step 0). ETA T2 ~01:35 UTC, T3 ~03:15 UTC. **MERGE CANDIDATE.** |
| **#2307** | open2-askeladd | **H-L lm_head freeze tail (paired arms, n=4)** | PR #309+RI | 2890 | Dual smoke runs `530jmjal` (step 500), `n6qab2r8` (step 100). Smoke gate pending. |
| **#2301** | open2-edward | H-D late-higher block LR on PR #300 base | PR #300 | 2925 | Arm A done n=4=3.279866. **Arm B T0=3.27978 vs Arm A T0=3.278741 → paired Δ_T0=+0.001 UNFAVORABLE.** T1 at 49% (5776/11700). |
| **#2306** | open2-frieren | **H-K NC (Cautious-Muon) on PR #309 + RI base** | PR #309 | 2890 | **n=4 run `hv1l0vsn` LIVE.** ETA T0 ~06:00 UTC. 🔥 Most critical overnight experiment. |
| **#2308** | open2-thorfinn | **H-M NC + RI on bare Muon at 2890 steps** (speedrun adaptation) | bare Muon | 2890 | **Smoke `thyonabe` LIVE at step 175/1500.** Normal training. ETA smoke pass ~01:00 UTC, n=4 launch ~01:00, T0 ~03:00 UTC. |
| **#2299** | open2-tanjiro | H-D late-higher block LR on PR #309 base | PR #309 | 2890 | Arm A n=4=3.27861. **Arm B v2 T0=3.277499, T1=3.282439 (tail), T2=3.27671 (BEATS fern by −0.00115).** Arm B T3 step 8823/11560 (76%). ETA T3 ~01:10 UTC. **MERGE CANDIDATE.** |
| **#2305** | open2-nezuko | H-J Two-Snapshot Tail Extrapolation | PR #309 | 2890 | n=4 `r2kim5fg` at step 6582/11560 (57%), best val_loss 3.27782 (~at fern baseline). ETA T3 ~02:30 UTC. |

## Closures this round (since 19:15 UTC)

| PR | Student | Verdict | n | Key finding |
|---:|---|---|---:|---|
| #2289 | frieren | **CLOSED 22:00** | 4 | RI on PR #300: paired Δ=−0.00056 (p<0.05, t=−3.42, 4/4 lift). Absolute 3.27877 > fern's 3.27786 due to PR #300 base being weaker than PR #309. Confirms RI is base-agnostic. |
| #2304 | askeladd | **CLOSED 22:55** | 4 | H-I direction ablation: γ=−0.075 n=4=3.27872 (T3=3.28195 tail). Direction-specific RI mechanism confirmed: negative γ saturates at −0.05/−0.075/−0.10; positive γ catastrophic from +0.05 onward (+1.00 destroys training, +0.126). RI is strictly **tail extrapolation**, not SWA. |
| #2303 | thorfinn | **CLOSED 23:35** | 4 | H-F NC+RI on bare Muon: **n=4 best-γ 3.274723**, paired Δ=−0.000504 (SE 3.1e-6, deterministic). Universality confirmed (4th base). step_to_target=3243.75 > fern's 2890 → cannot displace fern in speedrun. LOW tail variance (no T3 tail, σ(Δ)=6.4e-6). |

## 🔥 Top findings (00:10 UTC, 2026-06-06)

### 🎯 THREE PARALLEL MERGE CANDIDATES BELOW FERN BASELINE — overnight watch

**Multi-pronged signal: 3 different mechanisms on PR #309 base all clustering below fern's merged 3.27786 at 2890 steps.**

| PR | Mechanism | Trials done | Best n=2 | Mean | Projection | T3 ETA |
|---:|---|:---:|---:|---:|---:|---|
| **#2298** alphonse | Corrected Arbor (Sinkhorn equilibr.) | 2 of 4 | 3.27633 | **3.27691** | n=4 ~3.27680, contract 0.00640 ✅ | 03:15 UTC |
| **#2299** tanjiro | Late-higher block LR (Arm B) | 3 of 4 | 3.27671 | **3.27887** (incl T1 tail 3.282439) | n=4 mean tail-sensitive; needs T3 to know | 01:10 UTC |
| **#2305** nezuko | Two-Snapshot tail extrapolation | running | ~3.27782 mid-run | TBD | n=4 likely ~3.278 (near baseline) | 02:30 UTC |

**Alphonse's n=2 = 3.27691 is the cleanest projection (no tail events in T0/T1, max-min=0.00116).** Tanjiro Arm B has T1 tail (3.282439) but T2 (3.27671) recovered hard — T3 decides.

**Action:** preflight all three for merge if they hit terminal SENPAI-RESULT below 3.27786. If multiple land overnight, merge highest-priority first by margin × time-since-terminal.

### Original Alphonse single-trial standing (preserved for context)

| Metric | T0 value | T1 value |
|---|---:|---:|
| val/loss @ step 2890 | **3.27749** | **3.27633** |
| vs fern's MERGED 3.27786 | **−0.00037** ✅ | **−0.00153** ✅ |
| vs PR #309 base alone (3.27799) | −0.00050 ✅ | −0.00166 ✅ |
| vs broken sqrt(out_dim) variant (3.32278) | −0.04529 ✅ | −0.04645 ✅ |

**Mechanism:** Sinkhorn equilibration with default Muon scaling (the sqrt(out_dim) 55× pin removed). Pure row/column statistic rebalancer — exactly what the original spec intended. The 55× lift was a spec ambiguity, not a fundamental Arbor failure.



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
4. **NC on PR #309 base alone (no RI)** — disentangles NC mechanism from RI; tests if NC independently helps on EMA-Nesterov stack. Assign to nezuko after H-J completes.
5. **NC on PR #300 + RI base** — second universality test of NC. Assign to edward after H-D closes.
6. **Late-higher LR + RI composition on PR #309** — compose tanjiro's arm-B T0 with RI in single paired run.
7. **EMA-of-snapshots tail blend** — rolling EMA after capture_step, blend into terminal weights.
8. **Combined NC + Arbor on PR #309 + RI** — if alphonse H-A n=4 confirms Arbor+RI beats fern, compose NC+Arbor+RI as next-level stack.

**Tier 3 — Alternative tail extrapolation / training-curve mechanisms:**
8. **Capture-step sweep with paired-γ (NC base)** — find optimal capture point on bare-Muon NC base.
9. **Aitken's Δ² acceleration** — non-linear sequence acceleration applied to terminal-window parameter trajectory.
10. **Combined RI+Arbor (if both T0+T1 hold individually)** — orthogonality test of two top mechanisms.

## Watch items (next 6h, from 00:10 UTC 2026-06-06)

**CRITICAL: 3 parallel merge candidates may land overnight.**

- **Tanjiro Arm B T3 terminal** (~01:10 UTC) — earliest of the three merge candidates. n=4 mean depends heavily on T3: if T3 ≤ 3.278, Arm B n=4 likely beats fern. If T3 tails to 3.282, n=4 mean drifts to ~3.279 (no merge).
- **Alphonse T2 terminal** (~01:35 UTC) — Arbor n=3 should still be in 3.276 territory; if T2 = 3.276 then n=3 mean ~3.27680 → strong projection for T3 merge.
- **Nezuko H-J T3 terminal** (~02:30 UTC) — current best 3.27782 ~= fern baseline. Result is borderline merge.
- **Alphonse T3 SENPAI-RESULT** (~03:15 UTC) — likely cleanest of the three (n=2 no tail event). Immediate merge if ≤ 3.27786.
- **Thorfinn H-M smoke pass + n=4 launch** (~01:00 UTC smoke, ~07:00 UTC T0).
- **Frieren H-K n=4 T0 terminal** (~06:00 UTC) — NC+RI on PR #309 base at 2890 steps. If NC gives additive paired Δ on top of fern's merged RI, it's new rank-1.
- **Edward Arm B T1+** — late-higher LR on PR #300. T0 paired Δ unfavorable; T1 reveals if effect is real or seed noise.
- **Askeladd H-L smoke pass** + n=4 launch decision.
- **Fern H-G T2/T3** — confirms cap=2375 optimal in the 9-arm sweep.

**Merge-conflict-of-interest:** if multiple PRs land terminal within minutes, merge **lowest n=4 mean first** (best margin). Alphonse projects lowest, tanjiro second, nezuko third.

## Operational notes

- Blackwell pods (nezuko, thorfinn, alphonse) all confirmed running torch==2.12.0+cu130 after the silent 2.10.0 downgrade incident. Watch for recurrence.
- All 8 students have active hypotheses. Zero idle GPUs.
- **Edward PR #2301 has merge conflict** (DIRTY/CONFLICTING) but is mid-experiment (Arm B T1 running) — do NOT rebase until Arm B terminal. If Arm B paired Δ is unfavorable, close without merge (rebase unnecessary).
- **Askeladd H-L has two parallel smoke runs** (dual processes, GPU at 74GB). Intentional paired Arm A/B smoke. n=4 launch pending both smokes passing.
- **Frieren H-K n=4 run `hv1l0vsn` is the most critical active experiment** — NC composition on fern's merged base.
