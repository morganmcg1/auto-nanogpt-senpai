# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-06 ~00:45 UTC (launch day +2)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE (merged 2026-06-05 13:37 UTC)

**Senpai PR #2295 (fern H15 RI): n=4 mean 3.27786 at 2890 steps** — RI γ=−0.075, capture=2375, on PR #309 base.

## Active assignments (00:45 UTC, 2026-06-06)

| PR | Student | Hypothesis | Base | Target | Status |
|---:|---|---|---|---:|---|
| **#2298** | open2-alphonse | H-A Arbor Muon corrected variant | PR #309 | 2890 | **T0=3.27749, T1=3.27633 → n=2 mean 3.27691.** T2 mid-run. ETA T2 ~01:35, T3 ~03:15 UTC. **TOP MERGE CANDIDATE.** |
| **#2311** | open2-tanjiro | **H-P NC + RI on PR #305 base (universality grid)** | PR #305 | 2925 | **NEWLY ASSIGNED** (~01:55 UTC). Fills last cell of 4-way base grid. Smoke + n=4. ETA T0 ~09:00 UTC. |
| **#2305** | open2-nezuko | H-J Two-Snapshot RI | PR #309 | 2890 | **FALSIFIED** at n=2 (γ₂=0 dominates; Richardson null). n=4 mean ~3.27848, above fern. T3 ETA ~02:30 UTC. Close after SENPAI-RESULT. |
| **#2306** | open2-frieren | H-K NC + RI on PR #300 base | PR #300 | 2930 | Smoke passed. n=4 run `hv1l0vsn` LIVE. T0 ETA ~06:00 UTC. Most critical overnight experiment. |
| **#2307** | open2-askeladd | H-L lm_head freeze tail (paired arms) | PR #309+RI | 2890 | Dual smoke runs in progress (530jmjal step 500, n6qab2r8 step 100). Smoke gate pending. |
| **#2308** | open2-thorfinn | H-M NC + RI at 2890 steps (speedrun adaptation) | bare Muon | 2890 | Smoke running. ETA smoke pass ~01:00 UTC, n=4 ~01:00, T0 ~03:00 UTC. |
| **#2309** | open2-fern | **H-N NC + RI compositional stack on PR #309** | PR #309+RI | 2890 | **NEWLY ASSIGNED** (00:40 UTC). Smoke + n=4 confirm. ETA T0 ~08:30 UTC. |
| **#2310** | open2-edward | **H-O NC alone on PR #309 (isolation test)** | PR #309 | 2890 | **NEWLY ASSIGNED** (00:44 UTC). Arm A (control) + Arm B (NC). ETA T0 ~08:30 UTC. |

## Closures this round (since 19:15 UTC, 2026-06-05)

| PR | Student | Verdict | n | Key finding |
|---:|---|---|---:|---|
| #2289 | frieren | **CLOSED 22:00** | 4 | RI on PR #300: paired Δ=−0.00056 (p<0.05, t=−3.42, 4/4 lift). Absolute 3.27877 > fern's 3.27786 due to PR #300 base being weaker than PR #309. Confirms RI is base-agnostic. |
| #2304 | askeladd | **CLOSED 22:55** | 4 | H-I direction ablation: γ=−0.075 n=4=3.27872 (T3=3.28195 tail). Direction-specific RI confirmed: negative γ saturates at −0.05/−0.075/−0.10; positive γ catastrophic from +0.05 onward. RI is strictly **tail extrapolation**, not SWA. |
| #2303 | thorfinn | **CLOSED 23:35** | 4 | H-F NC+RI on bare Muon: **n=4 best-γ 3.274723**, paired Δ=−0.000504 (SE 3.1e-6, deterministic). Universality confirmed (4th base). step_to_target=3243.75 > fern's 2890 → cannot displace fern in speedrun. LOW tail variance. |
| #2302 | fern | **CLOSED 00:20** | 4 | H-G RI hyperparameter sweep: 12-arm × n=4. Best arm (cap=2375, γ=−0.075) n=4 mean 3.278365 — **matches merged baseline within seed noise**. Surface flat around optimum. Closes (cap, γ) search direction. |
| #2301 | edward | **CLOSED 00:20** | 2 (aborted) | H-D late-higher LR on PR #300: paired Δ n=2=+0.001576 (both trials unfavorable). FALSIFIED on PR #300 base (PR #300 optimizer internally saturates late-block emphasis). |

## 🔥 Top findings (00:45 UTC, 2026-06-06)

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

## Compositional verdict table (updated 00:45 UTC, 2026-06-06)

| Mechanism | Base | Status |
|---|---|---|
| NC (Cautious-Muon) | bare Muon | ✅ CONFIRMED (delta vs control >0.003) |
| NC + RI | bare Muon | ✅ CONFIRMED n=4 — best absolute val/loss 3.274723 at 3325 steps, paired Δ=−0.000504 (deterministic) |
| RI | PR #300 (Aurora+CM+SOAP) | ✅ UNIVERSAL — paired Δ=−0.00056 (p<0.05) |
| RI | PR #305 (Aurora+RRE+CM+SOAP) | ✅ UNIVERSAL (nezuko n=4=3.278421, paired Δ=−0.000664) |
| RI | PR #309 (Aurora+EMA-Nest) | ✅ MERGED at 3.27786 |
| Two-snapshot RI (H-J) | PR #309 | ❌ DISPROVEN (γ_2=0 wins; Richardson null at n=2) |
| Late-higher block LR | PR #300 | ❌ FALSIFIED (both trials unfavorable, aborted at n=2) |
| Late-higher block LR | PR #309 | ❌ NULL (n=4 paired Δ +0.000475, p=0.62, T1 tail) |
| Arbor Muon (sqrt out_dim pin) | PR #309 | ❌ FALSIFIED (55× lift bug) |
| Arbor Muon (corrected) | PR #309 | ⏳ n=4 in progress (T0=3.27749, T1=3.27633 → n=2=3.27691 ✅) |
| NC alone | PR #309 | ⏳ ASSIGNED to edward (H-O PR #2310) — ETA ~08:30 UTC |
| NC + RI | PR #309 | ⏳ ASSIGNED to fern (H-N PR #2309) — ETA ~08:30 UTC |
| RI direction (negative γ) | PR #309 | ✅ CONFIRMED — direction-specific, saturates at γ ≈ −0.05 to −0.10 |
| RI direction (positive γ) | PR #309 | ❌ FALSIFIED — catastrophic at γ > 0 |

## Next-wave hypothesis backlog (ordered by tier)

**Tier 1 — Active (fully assigned):**
1. **NC + RI on PR #309 base at 2890** — fern H-N (PR #2309). NEWLY ASSIGNED.
2. **NC alone on PR #309 at 2890 (isolation test)** — edward H-O (PR #2310). NEWLY ASSIGNED.
3. **lm_head freeze tail on PR #309+RI base (paired arms)** — askeladd H-L (PR #2307).
4. **NC + RI on PR #300 base at 2930** — frieren H-K (PR #2306). n=4 running.
5. **NC + RI on bare Muon at 2890** — thorfinn H-M (PR #2308). Smoke running.
6. **Corrected Arbor Muon on PR #309 at 2890** — alphonse H-A (PR #2298). T3 ETA ~03:15.

**Tier 2 — Next idle-student candidates (when nezuko/tanjiro terminate):**
7. **NC on PR #300 + RI base (NC universality on PR #300)** — frieren becomes idle after H-K; pivot to NC on PR #300 base specifically.
8. **Triple stack NC + Arbor + RI on PR #309** — if both alphonse (Arbor) and fern (NC+RI) win, full triple composition is next.
9. **Late-higher LR + RI composition on PR #309** — isolated test of compose tanjiro arm-B mechanism with RI in single run (not paired arms).
10. **EMA-of-snapshots tail blend** — rolling EMA after capture_step, blend into terminal weights; contrast with single-snapshot RI extrapolation.

**Tier 3 — Bold bets if current stacks plateau:**
11. **Aitken's Δ² acceleration** — non-linear sequence acceleration applied to terminal-window parameter trajectory.
12. **Warmup fraction sweep** — sweep warmup from 5% to 10% at 2890 steps; fern's merged uses default ~250/2890=8.6%.
13. **Per-layer RI capture** — different capture_step per transformer layer (early layers converge faster than late layers).

## Watch items (next 8h, from 00:45 UTC 2026-06-06)

**CRITICAL: 2 parallel merge candidates + 1 borderline — all landing overnight.**

| Time | Event | Action |
|---|---|---|
| ~01:10 UTC | **Tanjiro H-D Arm B T3** (PR #2299) | If T3 ≤ 3.278: n=4 mean may beat fern despite T1 tail. Immediate preflight merge if SENPAI-RESULT ≤ 3.27786. |
| ~01:35 UTC | **Alphonse T2** (PR #2298) | Expect T2 in 3.276 band. If T2=3.276, n=3 mean ~3.27670 → T3 will almost certainly merge. |
| ~02:30 UTC | **Nezuko H-J T3** (PR #2305) | FALSIFIED — close, assign next hypothesis. |
| ~03:15 UTC | **Alphonse T3 SENPAI-RESULT** (PR #2298) | **Highest-priority merge** if ≤ 3.27786. n=2 mean 3.27691 cleanest on fleet. |
| ~03:15 UTC | **Thorfinn H-M smoke pass** (PR #2308) | Authorize n=4 if smoke passes (no NaN, RI direction negative). |
| ~06:00 UTC | **Frieren H-K T0** (PR #2306) | NC+RI on PR #300. If paired Δ < −0.0001 AND n=4 mean < 3.27786 → new rank-1. |
| ~08:30 UTC | **Fern H-N / Edward H-O pod pickup** (#2309, #2310) | Smoke launches for NC+RI and NC-alone on PR #309 base. |

**Merge priority:** alphonse > tanjiro (by projected margin). If both land terminal within minutes, merge alphonse first.

## Operational notes

- Blackwell pods (nezuko, thorfinn, alphonse) all confirmed running torch==2.12.0+cu130 after the silent 2.10.0 downgrade incident. Watch for recurrence.
- All 8 students have active hypotheses (PRs #2298, #2299, #2305, #2306, #2307, #2308, #2309, #2310). Zero idle GPUs.
- **Frieren H-K n=4 run `hv1l0vsn` is the most critical active experiment** — NC composition on PR #300 base. T0 ETA ~06:00 UTC.
- **Askeladd H-L has two parallel smoke runs** (dual processes). n=4 launch pending smoke gate.
- **Alphonse PR #2298 is the top merge candidate** — n=2 mean 3.27691, no tail events in first two trials. Monitor closely for T3 SENPAI-RESULT at ~03:15 UTC.
- **Tanjiro PR #2299 Arm B T3 decides merge eligibility** — T1 tail event (3.282) makes n=4 mean very sensitive to T3; merge only if n=4 mean ≤ 3.27786.
