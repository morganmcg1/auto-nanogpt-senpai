# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-06 ~02:12 UTC (launch day +2)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE (merged 2026-06-05 13:37 UTC)

**Senpai PR #2295 (fern H15 RI): n=4 mean 3.27786 at 2890 steps** — RI γ=−0.075, capture=2375, on PR #309 base.

## Active assignments (02:12 UTC, 2026-06-06)

| PR | Student | Hypothesis | Base | Target | Status |
|---:|---|---|---|---:|---|
| **#2298** | open2-alphonse | H-A Arbor Muon corrected variant | PR #309 | 2890 | **T0=3.27749, T1=3.27633, T2=3.27714 → n=3 mean 3.276987.** σ=0.00048 (very tight, no tail event). T3 mid-run ETA ~03:20 UTC. **TOP MERGE CANDIDATE.** |
| **#2305** | open2-nezuko | H-J Two-Snapshot RI | PR #309 | 2890 | **FALSIFIED** at n=3 (γ₂=0 wins in 11/12 cells; Richardson null). n=3 mean 3.278241. T3 step 890/2890, ETA ~02:58 UTC. Close after SENPAI-RESULT, assign H-Q Lookahead-Muon. |
| **#2306** | open2-frieren | H-K NC + RI on PR #300 base | PR #300 | 2930 | Smoke passed. n=4 run `hv1l0vsn` LIVE — no comments since 23:30 UTC, nudged at 01:51 UTC. T0 ETA ~06:00 UTC. Most critical overnight experiment. |
| **#2307** | open2-askeladd | H-L lm_head freeze tail (paired arms) | PR #309+RI | 2890 | Smoke `530jmjal` PASSED. **Arm A `v7pfq024` running** at T0 step ~1774/2890. Arm B watchdog auto-chains. Arm A T0 terminal ~02:50 UTC. |
| **#2308** | open2-thorfinn | H-M NC + RI at 2890 steps (speedrun adaptation) | bare Muon | 2890 | **n=4 `7qcq1iwa` LIVE** at step 2175/2890 (T0 ~75%). T0 terminal ETA ~02:35 UTC. |
| **#2309** | open2-fern | **H-N NC + RI compositional stack on PR #309** | PR #309+RI | 2890 | **n=4 `rifpfrd4` launched 02:08 UTC.** Step 0+. Watch first val_loss at step ~100. T0 ETA ~08:00 UTC. |
| **#2310** | open2-edward | **H-O NC alone on PR #309 (isolation test)** | PR #309 | 2890 | **Arm A control `zyfbkso7` running** at step 75 (02:05 UTC start). Arm B watchdog pending. T0 Arm A ETA ~05:00 UTC. |
| **#2311** | open2-tanjiro | **H-P NC + RI on PR #305 base (universality grid)** | PR #305 | 2925 | **Smoke `0m9b7z4v` running** at step 100 (02:04 UTC start). Smoke gate ETA ~03:00 UTC, n=4 launch follows. |

## Closures this round (since 19:15 UTC, 2026-06-05)

| PR | Student | Verdict | n | Key finding |
|---:|---|---|---:|---|
| #2289 | frieren | **CLOSED 22:00** | 4 | RI on PR #300: paired Δ=−0.00056 (p<0.05, t=−3.42, 4/4 lift). Absolute 3.27877 > fern's 3.27786 due to PR #300 base being weaker than PR #309. Confirms RI is base-agnostic. |
| #2304 | askeladd | **CLOSED 22:55** | 4 | H-I direction ablation: γ=−0.075 n=4=3.27872 (T3=3.28195 tail). Direction-specific RI confirmed: negative γ saturates at −0.05/−0.075/−0.10; positive γ catastrophic from +0.05 onward. RI is strictly **tail extrapolation**, not SWA. |
| #2303 | thorfinn | **CLOSED 23:35** | 4 | H-F NC+RI on bare Muon: **n=4 best-γ 3.274723**, paired Δ=−0.000504 (SE 3.1e-6, deterministic). Universality confirmed (4th base). step_to_target=3243.75 > fern's 2890 → cannot displace fern in speedrun. LOW tail variance. |
| #2302 | fern | **CLOSED 00:20** | 4 | H-G RI hyperparameter sweep: 12-arm × n=4. Best arm (cap=2375, γ=−0.075) n=4 mean 3.278365 — **matches merged baseline within seed noise**. Surface flat around optimum. Closes (cap, γ) search direction. |
| #2301 | edward | **CLOSED 00:20** | 2 (aborted) | H-D late-higher LR on PR #300: paired Δ n=2=+0.001576 (both trials unfavorable). FALSIFIED on PR #300 base (PR #300 optimizer internally saturates late-block emphasis). |
| #2299 | tanjiro | **CLOSED 01:39** | 4 | H-D late-higher LR on PR #309: paired Δ n=4=+0.000475 (p=0.617, T1 Arm B tail 3.282439). NULL. **Closes off late-higher block LR across all bases.** Reassigned tanjiro → H-P #2311. |

## 🔥 Top findings (02:12 UTC, 2026-06-06)

### 🎯 ALPHONSE H-A T3 IMMINENT — MERGE LIKELY

**Single dominant merge candidate.** Alphonse corrected Arbor n=3 cluster σ=0.00048, mean 3.276987.

| Trial | val/loss | Δ vs fern merged 3.27786 |
|---:|---:|---:|
| T0 | 3.27749 | **−0.00037** ✅ |
| T1 | 3.27633 | **−0.00153** ✅ |
| T2 | 3.27714 | **−0.00072** ✅ |
| **n=3 mean** | **3.276987** | **−0.00088** ✅ |
| max−min | 0.00116 | well below 0.0015 tail flag |

**T3 cluster projection (if T3 ≈ 3.27630-3.27750):** n=4 mean ~3.27695, contract margin `(3.28-3.27695)·2=0.0061` (~50% headroom over 0.004 contract).

**Action plan at T3 SENPAI-RESULT:**
1. Preflight via `senpai_merge_winner_preflight 2298 target/`
2. If pass → `senpai:merge-winner 2298 target/`
3. New baseline ~3.27695 → all NC × base universality runs (PRs #2306, #2308, #2309, #2310, #2311) become **NC composability tests with the new Arbor-merged stack**
4. Assign cleanup PR (delete `apply_arbor 0` paths + broken sqrt(out_dim) variant from train_gpt_simple.py)

ETA T3 terminal: ~03:20 UTC.

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

## Watch items (next 8h, from 02:12 UTC 2026-06-06)

**Primary: alphonse merge runway, secondary: nezuko close + reassign, tertiary: fleet pickup verification.**

| Time | Event | Action |
|---|---|---|
| ~02:35 UTC | **Thorfinn H-M T0 terminal** (`7qcq1iwa`) | T0 paired Δ_γ ≤ −0.0002 → composability of NC+RI on bare Muon confirmed. |
| ~02:50 UTC | **Askeladd Arm A T0** (`v7pfq024`) | RI on PR #309+RI control. Baseline for paired Δ vs Arm B (freeze tail). |
| ~02:58 UTC | **Nezuko H-J T3 SENPAI-RESULT** (PR #2305) | FALSIFIED — close. Assign H-Q Lookahead-Muon (body drafted, /tmp/h-q-nezuko-body.md). |
| ~03:20 UTC | **Alphonse T3 SENPAI-RESULT** (PR #2298) | **MERGE.** n=3 mean 3.276987, margin ~0.0061 above contract. Run preflight → merge-winner → cleanup PR. |
| ~03:30 UTC | **Fern H-N smoke** (`rifpfrd4`) | Reaches step 1500 if step pace 2s/step from 02:08 launch (~02:58 UTC). Watch val_loss at step 1500 (~3.49 band expected). |
| ~03:30 UTC | **Tanjiro H-P smoke** (`0m9b7z4v`) | Same. Verify PR #305 base stable on single-GPU (per H-P spec note). |
| ~06:00 UTC | **Frieren H-K T0** (`hv1l0vsn`) | NC+RI on PR #300. T0 paired Δ ≤ −0.0001 → on track for merge. |
| ~12:00 UTC | **Askeladd Arm B T3** (freeze tail variant) | If paired Δ(B-A) ≤ −0.0002 AND Arm B n=4 ≤ 3.27786 → MERGE.|

**Merge priority:** alphonse first (terminal cluster + clean σ). Then track frieren H-K, askeladd Arm B, fern H-N as next candidates.

## Operational notes

- Blackwell pods (nezuko, thorfinn, alphonse) all confirmed running torch==2.12.0+cu130 after the silent 2.10.0 downgrade incident.
- All 8 students have active hypotheses (PRs #2298, #2305, #2306, #2307, #2308, #2309, #2310, #2311). Zero idle GPUs.
- **Alphonse PR #2298 is THE merge candidate** — n=3 mean 3.276987, σ=0.00048, clean cluster, no tail events. T3 SENPAI-RESULT ETA ~03:20 UTC.
- **Frieren H-K `hv1l0vsn` silent** — nudged at 01:51 UTC; await status pulse. Long single-GPU run on PR #300 base; T0 ETA ~06:00 UTC.
- **Thorfinn H-M `7qcq1iwa` n=4 LIVE** (T0 at step 2175/2890). Smoke restart anomaly `3irauhie` at 01:51 was a harmless launch abort.
- **Askeladd Arm A `v7pfq024` running** with Arm B watchdog auto-chaining. n=4 Arm A terminal ~06:46 UTC; Arm B terminal ~12:00 UTC.
- **Nezuko H-Q Lookahead-Muon body drafted** at /tmp/h-q-nezuko-body.md — ready to assign post-T3 close.
