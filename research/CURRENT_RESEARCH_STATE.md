# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-06 ~13:00 UTC (launch day +2)
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
- W&B: `5weg8d9r`. Contract margin 0.00524.
- **Cleanup PR #2313 merged 04:30 UTC:** Arbor is now always-on (no flag). Removed broken sqrt variant.

## Active assignments (13:00 UTC, 2026-06-06)

| PR | Student | Hypothesis | Target steps | Status |
|---:|---|---|---:|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation on merged Arbor base | 2890 | **POD BROKEN** — Issue #2319 open ~3h31m, no human response. |
| **#2322** | open2-frieren | H-Z: Arbor − EMA-Nesterov baseline (no NC) | 2890 | **n=4 LAUNCHED** (run `9y3k8kea`, step 75 T0). Second smoke `slvja2cs` confirmed clean. ETA T3 ~18:30 UTC. |
| **#2307** | open2-askeladd | H-L: freeze tail paired arms | 2890 | Arm B T1=3.27997 (+0.003003 vs Arm A) — confirms freeze tail negative. T2 in progress. ETA T3 ~14:04 UTC. |
| **#2320** | open2-fern | H-X: RI capture_step ablation | 2890 | n=4 active (run 0ygp3njz, step 471 at 10:46 UTC). ETA ~17:16 UTC. |
| **#2310** | open2-edward | H-O: NC alone on PR #309 base, paired arms | 2890 | Arm A n=4=3.27894. Arm B T0=3.28048 (+0.00085 vs control). T1 running ETA ~12:18 UTC, T3 ~15:33 UTC. |
| **#2321** | open2-tanjiro | H-Y: Drop EMA-Nesterov from Arbor + NC + RI | 2890 | n=4 run `5an0slvc` at step 775/2890 (T0, val=3.71). step_avg ~2017ms. ETA T0 ~13:18, T3 ~17:30 UTC. |
| **#2317** | open2-nezuko | H-W: NC × Arbor + RI on merged Arbor base | 2890 | **T1 RI = 3.275501** (below recalibrated baseline −0.001). T0 val_loss=3.27671. T2 at step ~175/2890. **POTENTIAL RANK-1** — clean per-trial table pending. |
| **#2323** | open2-thorfinn | H-AA: Arbor warmup — skip Sinkhorn first N steps | 2890 | **ASSIGNED 12:58 UTC**. H-R CLOSED (calibration-only, n=4=3.276890). Smoke sweep N∈{0,250,500,1000} then n=4. |

## 🔬 13:00 UTC: Thorfinn H-R CLOSED (calibration) + H-AA assigned; Edward Arm B T1=+0.00141

**Thorfinn H-R PR #2314 CLOSED — n=4 = 3.276890, CALIBRATION ONLY:**
- Zero code changes. Recalibrated true Arbor+RI mean: pooled n=8 ≈ 3.27713.
- Recalibrated merge bar: n=4 ≤ **3.2762** to claim genuine mechanism lift.
- Thorfinn reassigned H-AA: Arbor warmup (PR #2323). Sweep skip-Sinkhorn-first-N steps.

**Edward H-O Arm B T1=3.27933 — n=2 paired Δ = +0.00113 (NC DEFINITIVELY HURTS without Arbor):**
- T0 Δ=+0.00085, T1 Δ=+0.00141. NC alone on PR #309 base consistently destructive.
- Key contrast: NC × Arbor + RI (nezuko) HELPS. NC alone (edward) HURTS. → Arbor rescues NC.

## 🚨 12:00 UTC: NEZUKO H-W T1 RI = 3.275501 — POTENTIAL NEW RANK-1 CANDIDATE

**W&B `vk0jtb3z` summary after T1 (NC × Arbor + RI on merged Arbor base):**
- val/ri_loss_gamma_neg0p0750 = **3.275501** (T1 RI)
- T0 val/loss (γ=0) was 3.27671 — n=2 RI mean likely ~3.276 range
- T2 running at step ~175/2890. T3 ETA ~15:08 UTC.

**This contradicts the "NC × EN closed" verdict at the absolute-value level:**
- Earlier mechanism finding: NC on PR #309 base alone gives +0.002 absolute hurt (paired Δ compressed −0.0003).
- BUT NC × Arbor + RI lands BELOW recalibrated baseline (3.276518).
- **Hypothesis:** Sinkhorn equilibration changes the noise structure enough to rescue NC composition. NC is closed on raw PR #309 but **may compose on Arbor**.

**Requested clean per-trial table from nezuko (paired γ).** T2/T3 are decisive — if n=4 mean ≤ 3.276, NEW RANK-1.

## 🔬 11:25 UTC: Thorfinn T2 lands clean + Tanjiro H-Y already in n=4

**Thorfinn H-R T2 = 3.27679 — n=3 mean = 3.276518, std 0.000311:**
- T0=3.276168, T1=3.276595, T2=3.27679. Very tight cluster. T3 ETA ~12:38 UTC.
- **Recalibrated Arbor+RI floor:** new mechanisms must beat ~3.2765 (not 3.27738) to be genuine winners.

**Tanjiro H-Y fast pickup — n=4 already running:**
- Smoke completed at val/loss=4.087 (consistent with launch baseline)
- n=4 T0 at step ~250/2890 by 11:25 UTC. Code change + smoke + n=4 in <40 minutes — excellent execution.
- Tanjiro PR #2321 has the `--disable_ema_nesterov` flag implementation; frieren can adopt.

**Frieren H-Z smoke running:**
- Smoke at step ~50/250 at 11:25 UTC. Healthy startup (val=10.826 ln(50257) sentinel at step 0).
- Will use tanjiro's flag implementation when n=4 launches.

**Askeladd H-L freeze tail — third paired Δ confirms direction:**
- Arm B T0 Δ = +0.002305, T1 Δ = +0.003003 — both substantially negative
- Combined with frieren H-T n=2 (+0.00225 above baseline), freeze tail is conclusively dead

## 🔬 11:05 UTC: Frieren H-T ABORTED + H-Z assigned; thorfinn n=3=3.276519

**Frieren H-T PR #2316 ABORTED (n=2=3.279633, +0.00225 above baseline):**
- T0=3.278676 (+0.00130), T1=3.28059 (+0.00321). Both confirm freeze tail × Arbor negative.
- Mechanism: RI prior violated when lm_head frozen (pre-freeze trajectory included in RI snapshot).
- frieren reassigned H-Z: Arbor − EN baseline (no NC), control arm to tanjiro H-Y.

**Thorfinn H-R n=3 mean = 3.276519 — recalibrated Arbor+RI floor:**
- T0=3.27617, T1=3.27659, T2=3.27679. Very consistent. T3 ETA ~12:40 UTC.
- n=3 mean 3.276519, n=4 likely ~3.2765-3.2767

**Freeze tail DEAD across both arms — close direction:**
- Askeladd H-L Arm B T1 Δ = +0.003003 (vs Arm A), T0 Δ = +0.002305
- Frieren H-T n=2 mean = +0.00225 above baseline

## 🔬 10:38 UTC: Tanjiro H-P n=4 CLOSED + NC×EN table finalized

**Tanjiro H-P PR #2311 CLOSED — n=4 = 3.279177, NOT mergeable**

**4-way mechanism boundary grid (NC+RI paired Δ):**

| Base | Paired Δ | EMA-Nesterov? |
|---|---:|---|
| bare Muon (thorfinn H-F) | ~−0.0006 | No |
| PR #305 (tanjiro H-P) | **−0.000647 ± 8e-6** | No |
| PR #309 (frieren H-K) | −0.000290 | Yes |
| PR #309 (fern H-N T0) | −0.000310 | Yes |

**Conclusion: EN specifically halves NC×RI lift.** Tanjiro reassigned H-Y (drop EN from merged Arbor, retest NC composition).

## 🔬 10:27 UTC: Edward Arm B T0=3.2805 — NC hurts +0.0009 vs control on PR #309

Edward H-O paired arms: Arm A (no NC) T0=3.27963, Arm B (NC=1) T0=3.2805. Δ=+0.0009 — NC hurts on merged Arbor base (EN present). Consistent with NC×EN suppression pattern.

## 🔬 09:15 UTC: MAJOR DATA DROP — 4 simultaneous terminals

### FINDING A: Thorfinn H-R n=2 = 3.27638 — recalibrates "true" Arbor+RI mean

| Trial | val/loss (γ=−0.075) | paired Δ |
|---:|---:|---:|
| T0 | 3.276168 | −0.000317 |
| T1 | 3.276595 | −0.000295 |
| **n=2 mean** | **3.276382** | **−0.000306** |

**Implication:** Rank-1 PR #2298 (3.27738) was on the upper end of seed variance. True Arbor+RI mean ≈ 3.276-3.277. **Merge bar for new mechanisms should now be ~3.2765.**

### FINDING B: Fern H-N n=4 = 3.278737 — 4th NC×EMA-Nesterov confirmation

n=4 mean +0.00136 above Arbor. Mean paired Δ = −0.000325 (compressed vs normal −0.0005). NC mechanism boundary on PR #309 fully characterized.

### FINDING C: Freeze tail T0 hurts on BOTH arms (askeladd + frieren agree)

- **Askeladd Arm B T0** (PR #309 + RI, freeze ON): paired Δ vs Arm A = **+0.002305** (freeze hurts ~+0.002)
- **Frieren H-T T0** (merged Arbor base, freeze ON): absolute 3.278676 = **+0.00130** above Arbor baseline

Two independent T0 data points both show freeze tail is net negative. H-L (askeladd) and H-T (frieren) both likely dead ends — pending n=4 paired t.

## 🔬 06:38 UTC: Frieren H-K CLOSED — NC × EMA-Nesterov confirmed n=4

**Final frieren H-K n=4 result (NC + RI on PR #309 base):**

| Trial | val/loss (γ=−0.075) | first_step_to_target |
|---:|---:|---:|
| T0 | 3.28091 | -1 |
| T1 | 3.27996 | 2890 |
| T2 | 3.27777 | 2875 |
| T3 | 3.27825 | ~2890 |
| **n=4 mean** | **3.27922** | — |

**Verdict: CLOSED (does NOT beat Arbor baseline 3.27738)**. Gap = +0.00184 above rank-1.

**This is the 3rd independent confirmation of NC × EMA-Nesterov conflict** (alongside fern H-N, edward H-O). NC hurts absolute val/loss on PR #309 base by ~+0.002 vs no-NC baseline.

**frieren reassigned to H-T (PR #2316)**: lm_head freeze tail × Arbor + RI.

## 🔥 CRITICAL MECHANISM FINDING: NC × EMA-NESTEROV CONFLICT

### Summary

| Base | NC paired Δ (RI lift under NC) | NC absolute impact |
|---|---:|---|
| bare Muon | −0.000504 | NEUTRAL-POSITIVE |
| PR #305 (Aurora + Contra-Muon) | −0.0006 | NEUTRAL (tanjiro T0) |
| **PR #309 (EMA-Nesterov β=0.95)** | **−0.00029 to −0.00032** | **NEGATIVE ~+0.002 hurt** |
| PR #309 + Arbor | **~−0.0003?** | **NEGATIVE (H-S blocked, env NaN)** |

**Mechanism:** PR #309's EMA-Nesterov β=0.95 captures per-step momentum-sign info that NC's row/col gating was designed to provide. Double-counting degrades gradient signal. PR #305 uses Aurora + Contra-Muon (different mechanism), no conflict.

**Implication for all PR #309-derived experiments:** NC is closed off as a compositional mechanism. Do not assign NC experiments on PR #309-derived bases.

## 🚨 Alphonse H-S: Environmental NaN — pod GPU suspected

- Blackwell GPU (CC 12.0), pod `senpai-auto-nanogpt-open-sota-v2-20260604-open2-alphonse-7t946p`
- Deterministic NaN at `blocks.0.attn.proj.bias.grad` positions 7/768 in backward of step 1
- Same NaN regardless of: NC on/off, Arbor on/off, RI on/off, TF32 on/off, clean cache
- Even successful smoke baseline (a92fc412) now crashes — confirms environmental
- Thorfinn running cleanly on same code = pod-specific
- Recovery plan posted: soft CUDA reset first, then close + reassign if unrecoverable
- **H-U (Lookahead × Arbor) CANCELLED as backup** — nezuko H-Q T0=3.29391 confirms Lookahead-Muon failing on PR #309 base

## ✨ STRONG SIGNAL: Askeladd H-L Arm A sub-baseline performance

**Askeladd H-L Arm A (RI only, NO freeze tail — same as fern merged):**
T0=3.27757, T1=3.27697, T2=3.27685. n=3 mean=**3.27713** — **below Arbor baseline 3.27738!**

This is strong variance but suggests:
1. lm_head freeze Arm B should show even lower values if freeze tail adds lift
2. If Arm B paired Δ vs Arm A ≤ −0.0002, freeze tail × RI is a new rank-1 candidate
3. H-T (frieren) tests freeze tail × ARBOR — the merge-relevant composition

## ⚠️ Nezuko H-Q: Lookahead-Muon failing badly (T0=3.29391)

Lookahead k=10, α=0.5 on PR #309 base: T0 = 3.29391. This is ~0.016 above the 3.28 target, far worse than any mechanism we've tested. Likely cause: Lookahead slow-weight interpolation interferes with EMA-Nesterov momentum state (similar conflict as NC). T1 at 40% — will confirm direction but Lookahead-Muon is a dead end.

## Compositional verdict table (06:50 UTC)

| Mechanism | Base | Status |
|---|---|---|
| RI alone | PR #309 | ✅ MERGED at 3.27786 (fern PR #2295) |
| Arbor (Sinkhorn equilibration) | PR #309 + RI | ✅ **MERGED at 3.27738 (alphonse PR #2298)** — RANK-1 |
| NC (Cautious-Muon) | bare Muon | ✅ CONFIRMED (paired Δ −0.0005 at 3325 steps) |
| NC + RI | bare Muon | ✅ CONFIRMED n=4 — 3.274723 at 3325 steps |
| RI | PR #300 / #305 | ✅ UNIVERSAL |
| **NC alone** | **PR #309 (EMA-Nesterov)** | **❌ CLOSED — hurts ~+0.002 vs RI-only** |
| **NC + RI** | **PR #309 (EMA-Nesterov)** | **❌ CLOSED (frieren H-K n=4 3.27922)** |
| **NC + RI** | **PR #309 + Arbor** | **⚠️ H-S blocked by environmental NaN** |
| **Lookahead-Muon + RI** | **PR #309** | **❌ FAILING (nezuko H-Q T0=3.29391)** |
| lm_head freeze tail + RI | PR #309 | ⏳ askeladd H-L Arm A (sub-baseline!), Arm B pending |
| lm_head freeze tail × Arbor + RI | PR #309 + Arbor | ⏳ frieren H-T (PR #2316) — just assigned |
| Arbor + RI (RI on merged Arbor base) | PR #309 | ⏳ thorfinn H-R (PR #2314) — T0 61% |
| NC + RI | PR #305 | ⏳ tanjiro H-P (PR #2311) — T1 ~terminal |

## Next-wave hypotheses

**When alphonse pod recovers or reassigned:**
- **H-V: RI extended γ ablation on merged Arbor base** — test γ ∈ {−0.10, −0.125, −0.15} from capture_step=2375. Current best: γ=−0.075. No code changes, just CLI args. Zero implementation risk. Could compound existing RI lift.
- OR: revisit H-S (NC × Arbor) if pod recovers cleanly

**After askeladd Arm A T3 terminal (~07:20 UTC):**
- If Arm A n=4 mean ≤ 3.27738 (Arm A alone beats Arbor!) → potential merge, then Arm B data is frozen
- If Arm A n=4 mean > 3.27738 → wait for Arm B (freeze tail) result

**After nezuko H-Q T3 terminal (~10:00 UTC):**
- Close H-Q as dead end (Lookahead-Muon + EMA-Nesterov conflict)
- Reassign nezuko to something orthogonal: e.g. Sinkhorn temperature schedule or RI capture-step sweep

**Bold bets (for when top-stack plateau):**
- Aitken's Δ² extrapolation (uses 3 snapshots instead of 1, higher-order convergence)
- Per-layer RI (earlier layers converge faster → earlier capture_step for shallow layers)
- Dynamic β schedule: anneal EMA-Nesterov β from 0.95 → 0.85 in last 10% of training
- NC after Sinkhorn (reversed composition — NC operates on already-equilibrated updates)

## Watch items (next 6h from 08:05 UTC)

| Time | Event | Expected |
|---|---|---|
| ~08:10 | Nezuko H-W n=4 launch verification | GPU should be 100% if launch picked up |
| ~08:50 | Edward H-O Arm A T3 terminal | n=4 mean ~3.2784 (NC-alone confirmation) |
| ~08:55 | Thorfinn H-R T1 terminal | If T1 holds near T0 (3.276), strong rank-1 trajectory |
| ~08:55 | Frieren H-T T1 terminal | First freeze tail × Arbor data point |
| ~09:00 | Fern H-N T3 terminal | n=4 NC+RI mean (~3.2787 projected) — confirms PR #309 conflict |
| ~10:16 | Tanjiro H-P T3 terminal | n=4 paired Δ stability for PR #305 mechanism boundary |
| ~13:30 | Askeladd Arm B T3 terminal | Freeze tail effect vs Arm A (mechanism Δ) |
| TBD | Alphonse pod restart | Awaiting human team response to Issue #2319 |

### ⚠️ Askeladd Arm A MERGE NOTE
Arm A n=3 mean 3.27713 is sub-baseline, but **Arm A uses pre-Arbor PR #309 code**. Do NOT merge Arm A — it would regress to pre-Arbor code over the merged baseline. Arm A data is mechanistic context only (confirms RI-alone baseline for Arm B Δ calculation). Only Arm B (freeze tail + RI on pre-Arbor code) is relevant for Arm B vs Arm A Δ; the MERGE-ELIGIBLE test is frieren H-T (freeze tail on merged Arbor base).

## Operational notes (08:05 UTC)

- Alphonse pod environmental NaN — Issue #2319 awaiting human team kubectl restart
- 7/8 GPUs actively training (excluding alphonse)
- NC × EMA-Nesterov conflict CONFIRMED across 3 PR #309 bases (frieren H-K, fern H-N, edward H-O)
- **NEW: Mechanism boundary fully traced** — NC works on bare Muon + PR #305 (no EMA-Nesterov), fails on PR #309 (EMA-Nesterov saturates sign budget). Tanjiro H-P n=2 paired Δ=−0.000644 confirms.
- **Strongest single-trial val/loss so far: thorfinn H-R T0 = 3.276168** (Arbor+RI on merged base). Watch T1 closely.
- **Freeze tail next data:** frieren H-T T1 + askeladd Arm B T1+ both coming in next ~6h.
- Askeladd Arm A n=4 = 3.277684 — slightly above baseline. Pre-Arbor code so not merge-eligible anyway; Arm B Δ is the mechanism payload.
