# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-06 ~03:45 UTC (launch day +2)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE (merged 2026-06-06 03:45 UTC)

**Senpai PR #2298 (alphonse H-A Corrected Arbor Muon): n=4 mean 3.27738 at 2890 steps**
- Sinkhorn row/column equilibration (corrected: sqrt(out_dim) pin removed) on PR #309 base (Aurora+EMA-Nesterov+RI from PR #2295)
- W&B: `5weg8d9r`, group `open2-alphonse/h-a-arbor-pr309-corrected`
- Contract margin 0.00524. Previous baseline: fern H15 RI at 3.27786.

## Active assignments (03:45 UTC, 2026-06-06)

| PR | Student | Hypothesis | Target steps | Status |
|---:|---|---|---:|---|
| **#2313** | open2-alphonse | **CLEANUP**: prune broken Arbor sqrt(out_dim) path, default apply_arbor=True, 250-step smoke | N/A | Just assigned, cleanup (~1-2h) |
| **#2306** | open2-frieren | H-K: NC + RI on PR #309 base, n=4 | 2890 | `hv1l0vsn` at step 6832 (T2 ~37%); T0 terminal, T1 terminal, T2 ~03:55 UTC ETA |
| **#2307** | open2-askeladd | H-L: lm_head freeze tail (paired Arm A / Arm B) | 2890 | Arm A `v7pfq024` at step 5591 (T1 ~93%); T1 ETA ~03:48 UTC; Arm B watchdog chains after Arm A T3 |
| **#2308** | open2-thorfinn | H-M: NC + RI at 2890 steps on bare Muon | 2890 | `7qcq1iwa` at step 5141 (T1 ~78%); T0 known 3.29757 (step budget too tight); T1 ETA ~03:55 UTC |
| **#2309** | open2-fern | H-N: NC + RI on PR #309 base at 2890 | 2890 | `rifpfrd4` at step 2675/2890 (T0 93%); T0 ETA ~03:50 UTC |
| **#2310** | open2-edward | H-O: NC alone on PR #309 base at 2890 | 2890 | `zyfbkso7` at step 2750/2890 (T0 95%); T0 ETA ~03:47 UTC |
| **#2311** | open2-tanjiro | H-P: NC + RI on PR #305 base at 2925 (universality grid) | 2925 | `6ygg4kze` at step 525/2890 (T0 18%); T0 ETA ~04:50 UTC |
| **#2312** | open2-nezuko | H-Q: Lookahead-Muon (online slow-weights) on PR #309 + RI base | 2890 | `g4xrj5kn` at step 375/2890 (13% smoke); smoke ETA ~04:10 UTC |

## Recent closures

| PR | Student | Verdict | n | Key finding |
|---:|---|---|---:|---|
| #2298 | alphonse | **MERGED 03:45 UTC** | 4 | Corrected Arbor Muon: n=4=3.27738, margin 0.00524. NEW RANK-1. Sinkhorn row/col equilibration (sqrt(out_dim) pin removed) delivers −0.00048 over fern's merged RI. |
| #2305 | nezuko | **CLOSED 03:19 UTC** | 4 | H-J Two-Snapshot RI: NULL, paired Δ=−3e-7, SE 7.4e-6. Richardson null — tail is first-order. Reassigned → H-Q Lookahead-Muon. |
| #2299 | tanjiro | **CLOSED 01:39 UTC** | 4 | Late-higher block LR on PR #309: paired Δ=+0.000475 (p=0.62). Closes LR ramp direction. |

## 🔥 Top findings (03:45 UTC, 2026-06-06)

### NEW: Corrected Arbor Muon is MERGED rank-1

3.27738 n=4, beating fern's 3.27786 by −0.00048. Mechanism: Sinkhorn row/column equilibration is a pure magnitude-preserving redistributor. The 55× broken-variant lift was a bug, not signal — the corrected path delivers genuine lift.

**Implication for fleet:** All currently in-flight NC experiments (PRs #2306, #2308, #2309, #2310) are testing on the pre-Arbor PR #309 base. Their results establish whether NC composes with the old merged stack. After they terminate, the high-priority next-wave is NC × Arbor (on the new merged Arbor base).

### Frieren H-K (NC + RI, PR #309 base) — T0 terminal, T1 known

| Trial | val/loss | Δ vs NEW baseline 3.27738 |
|---:|---:|---:|
| T0 | 3.280907 | +0.00353 (above baseline) |
| T1 | ~3.28091 | +0.00353 (above baseline) |
| T2 | ~step 1052/2890 | ETA 03:55 UTC |

T0/T1 both ~3.28091 (deterministic consistency). paired Δ(NC vs no-NC) = −0.000292 (NC helps). But absolute val/loss 3.2809 > new baseline 3.27738, so frieren needs to run on the full Arbor merged base to compete. Direction confirmed, absolute insufficient.

### Edward H-O (NC alone, PR #309 base) — T0 imminent

Step 2750/2890 at 03:45 UTC. Terminal in ~3 min.

### Fern H-N (NC + RI, PR #309 base) — T0 imminent

Step 2675/2890 at 03:45 UTC. Terminal in ~7 min.

### Thorfinn H-M (NC + RI, bare Muon base) — T1 territory

T0 = 3.29757 (bare Muon at 2890 steps — step budget too short vs 3325 context). T1 at 78%. This will likely confirm NC+RI mechanism is base-agnostic but absolute val/loss will remain above new baseline.

### Tanjiro H-P (NC + RI, PR #305 base) and Nezuko H-Q (Lookahead-Muon)

Both in early-run territory. Universality and new mechanism tests respectively.

## Compositional verdict table (03:45 UTC, 2026-06-06)

| Mechanism | Base | Status |
|---|---|---|
| RI alone | PR #309 | ✅ MERGED at 3.27786 (fern PR #2295) |
| Arbor Muon (corrected) | PR #309 + RI | ✅ **MERGED at 3.27738 (alphonse PR #2298)** — NEW RANK-1 |
| NC (Cautious-Muon) | bare Muon | ✅ CONFIRMED (paired Δ confirmed, best absolute 3.274723 at 3325 steps) |
| NC + RI | bare Muon | ✅ CONFIRMED n=4 — paired Δ=−0.000504, 3325 steps |
| RI | PR #300 | ✅ UNIVERSAL — paired Δ=−0.00056 (p<0.05) |
| RI | PR #305 | ✅ UNIVERSAL — paired Δ=−0.000664 |
| Two-snapshot RI (H-J) | PR #309 | ❌ DISPROVEN — Richardson null, γ₂=0 wins |
| Late-higher block LR | PR #309 | ❌ NULL (n=4 paired Δ +0.000475, p=0.62) |
| Late-higher block LR | PR #300 | ❌ FALSIFIED |
| Arbor Muon (broken sqrt variant) | PR #309 | ❌ FALSIFIED (55× lift bug) |
| NC + RI | PR #309 | ⏳ fern H-N PR #2309 — T0 terminal in minutes |
| NC alone | PR #309 | ⏳ edward H-O PR #2310 — T0 terminal in minutes |
| NC + RI | PR #305 | ⏳ tanjiro H-P PR #2311 — T0 ~04:50 UTC |
| lm_head freeze tail + RI | PR #309 | ⏳ askeladd H-L PR #2307 — Arm A T1 ~03:48 UTC |
| Lookahead-Muon + RI | PR #309 | ⏳ nezuko H-Q PR #2312 — smoke ~04:10 UTC |
| NC + RI | PR #309 base (original, pre-Arbor) | ⏳ frieren H-K PR #2306 — T2 at 37% |

## Next-wave hypothesis backlog (ordered by tier)

**Tier 1 — Most valuable when alphonse finishes cleanup (~05:30 UTC):**
1. **NC × Arbor (Cautious-Muon on new merged Arbor base)** — NC lifted bare Muon by −0.000504; now test if it also lifts the Arbor-merged PR #309 base at 2890 steps. If both compound, expect n=4 mean ~3.2762.
2. **Arbor + RI explicit eval** — Current merged Arbor stack (PR #2298) was tested WITHOUT RI eval. Adding `--ri_capture_step 2375 --ri_gamma -0.075` to the Arbor base should give additional ~0.0003 lift from trajectory extrapolation. Expected n=4 mean ~3.2771.
3. **Lookahead × Arbor** — If nezuko H-Q confirms Lookahead+RI lift, compose with Arbor.

**Tier 2 — After current round closes (~06-08 UTC):**
4. **Triple stack: NC + Arbor + RI on PR #309 at 2890** — full compositional test of all three confirmed mechanisms. If all three are additive, project ~3.275.
5. **NC on PR #300 base** — frieren has confirmed NC helps on PR #309 pre-Arbor; universality on PR #300 is natural extension.
6. **Per-layer RI capture** — different capture_step per transformer layer (early layers converge faster).

**Tier 3 — Bold bets if current stacks plateau:**
7. **Aitken's Δ² acceleration** — non-linear sequence acceleration on terminal-window parameter trajectory.
8. **Warmup fraction sweep** — sweep warmup from 5% to 10% at 2890 steps.
9. **EMA-of-snapshots tail blend** — rolling EMA after capture_step.

## Operational notes (03:45 UTC)

- **PR #2298 MERGED** — alphonse now doing cleanup PR #2313 (~1.5h).
- **PRs #2309 (fern) and #2310 (edward) T0 terminals imminent** — both within 5-10 min.
- **Frieren H-K absolute val/loss above new baseline** — NC+RI on pre-Arbor PR #309 is ~3.2809, which is above new rank-1 3.27738. NC direction confirmed but won't displace Arbor stack.
- **Next assignment for alphonse after cleanup:** NC × Arbor composition OR Arbor + RI explicit eval.
- **Zero idle GPUs confirmed.** All 8 students active.
