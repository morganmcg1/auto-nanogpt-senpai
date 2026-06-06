# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-06 ~15:45 UTC (launch day +2)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE — UPDATED (merged 2026-06-06 15:43 UTC)

**Senpai PR #2317 (nezuko H-W NC × Arbor + RI): n=4 mean 3.276193 at 2890 steps** ← NEW RANK-1
- Cautious-Muon (NC: per-row × per-col L2 equalization before NS5) + Corrected Arbor (Sinkhorn) + EMA-Nesterov + RI (γ=−0.075, capture=2375)
- W&B: `vk0jtb3z`. Contract margin 0.007615. Best trial T3=3.275708.
- vs previous rank-1 PR #2298 (3.27738): **−0.001187** improvement
- **CLEANUP PR NEEDED:** make `--nc` always-on (default), drop the CLI flag

Previous rank-1: **PR #2298 (alphonse H-A Corrected Arbor Muon) = 3.27738** (W&B: 5weg8d9r)

## Active assignments (13:25 UTC, 2026-06-06)

| PR | Student | Hypothesis | Target steps | Status |
|---:|---|---|---:|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation on merged Arbor base | 2890 | **POD BROKEN — 18th check, ~5h21m** since Issue #2319 filed. No human team response yet. |
| **#2322** | open2-frieren | H-Z: Arbor − EMA-Nesterov baseline (no NC) | 2890 | **T1 LANDED = 3.279692** (WORSE than T0 3.278932). n=2 mean = 3.279312, paired Δ=−0.000438 (RI lift compressed without EN). T2 just started (step 25 at 15:28). EN confirmed load-bearing for Arbor. ETA T3 ~21:00 UTC. |
| **#2324** | open2-askeladd | H-AB: Polyak-Ruppert/SWA tail averaging on Arbor+RI | 2890 | **PICKED UP** by student (iter 158 at 15:15 UTC). GPU 0% — preparing smoke. Paired arms: Arm A (baseline), Arm B (SWA tail K=290, last 10%). |
| **#2320** | open2-fern | H-X: RI capture_step ablation | 2890 | T2 at step 2427/2890. Partial val/ri_loss(γ=−0.075, capture=2375) = **3.275764** (best arm). Ranking: 2375<2200<2550<2700<2000. T2 ETA ~15:45 UTC. T3 ETA ~17:15 UTC. |
| **#2310** | open2-edward | H-O: NC alone on PR #309 base, paired arms | 2890 | **Arm B n=3 paired Δ=+0.00107**, T0=3.28048, T1=3.27933, T2=3.27882, T3 at step 2100/2890 (73%), ETA ~16:22 UTC. Informational closure pending T3. Rebase then close. |
| **#2321** | open2-tanjiro | H-Y: Drop EMA-Nesterov from Arbor + NC + RI | 2890 | T0=3.279331, T1=3.277918 (recovery), mean(T0,T1)=3.278625. Paired Δ ≈ −0.000441. T2 at step 677/2890. T2 ETA ~17:00 UTC, T3 ~18:40 UTC. Closure trajectory. |
| **#2317** | open2-nezuko | H-W: NC × Arbor + RI on merged Arbor base | 2890 | **✅ MERGED 15:43 UTC** — n=4 mean = **3.276193** (T3=3.275708). NEW RANK-1. Cleanup PR to be assigned: make NC always-on. |
| **#2323** | open2-thorfinn | H-AA: Arbor warmup — skip Sinkhorn first N steps | 2890 | N=0 n=4 launched 14:32 UTC (`fiixr3ft`). ETA terminal ~21:00 UTC. Then N=500, N=1000 follow-up arms. |

## 🚀 14:00 UTC: FRIEREN H-Z T0 = 3.278932 — EN is INDEPENDENTLY load-bearing for Arbor (NOT just NC×Arbor)

**Frieren H-Z T0 (Arbor + RI WITHOUT EN, no NC) = 3.278932 vs thorfinn T0 with EN = 3.276168 → Δ = +0.002764.**

**Tanjiro H-Y T0 (NC + Arbor + RI WITHOUT EN) = 3.279331 vs nezuko T0 with EN = 3.276712 → Δ = +0.002619.**

**Both Δ are ~+0.003.** Removing EN costs the same regardless of NC condition. **Refined mechanism finding:**

| Mechanism | Lift (vs no-mechanism Arbor floor) |
|---|---:|
| EN (regardless of NC) | ~+0.0028 absolute val/loss |
| NC × Arbor with EN (compositional) | ~−0.0007 |

EN's contribution is INDEPENDENT of NC, not conditional on it. The earlier "NC×Arbor needs EN" finding was a confound — EN was independently load-bearing for Arbor.

**Consequences:**
1. **Cleanup PR roadmap:** keep EN as default on the Arbor stack; document EN as load-bearing (not optional).
2. **H-Z and H-Y both heading toward closure** at n=4 mean ~3.279 (no merge candidates).
3. **Nezuko's H-W lift over Arbor (n=3 mean 3.276354 vs 3.276890) is genuinely from NC**, not from incidental EN amplification.

## 🚀 13:42 UTC: NEZUKO T2 LANDS — n=3 mean = 3.276354, RANK-1 TRAJECTORY CONFIRMED

**Nezuko H-W n=3 (T0+T1+T2) mean γ=−0.075 = 3.276354:**
- T0=3.276712, T1=3.275501, T2=3.276849 → tight band 0.001348
- Paired Δ stable across trials: −0.000352, −0.000324, −0.000310
- std 0.000742, SE 0.000428 — n=3 confidence interval narrow
- vs recalibrated Arbor+RI floor (3.276890): n=3 mean is **−0.000536 below** (t=−1.25 not stat-sig yet)
- T3 in flight (step 103 at 13:41 UTC), terminal ETA ~15:10 UTC

### T3 outcome projection

| T3 γ=−0.075 hypothetical | n=4 mean | Margin vs contract (3.28 target, √n=2) |
|---:|---:|---:|
| 3.2755 (T1-like best) | 3.276141 | 0.00772 ✓ |
| 3.2763 (T0/T2 median) | 3.276338 | 0.00733 ✓ |
| 3.2770 (thorfinn-T3 high) | 3.276513 | 0.00697 ✓ |
| 3.2780 (worst plausible) | 3.276763 | 0.00647 ✓ |

All trajectories pass the contract. Mechanism merge bar (n=4 ≤ 3.2762 for genuine lift) clears in scenarios 1-2.

## 🚀 13:25 UTC: NEZUKO n=2 mean = 3.276107 + TANJIRO T0 reveals EN is LOAD-BEARING for NC×Arbor

**Nezuko H-W n=2 (T0+T1) mean γ=−0.075 = 3.276107:**
- T0 γ=−0.075 = 3.276712, T1 γ=−0.075 = 3.275501
- T0 γ=0 = 3.277064, T1 γ=0 = 3.275825 → n=2 mean γ=0 = 3.276444
- Paired Δ T0=−0.000352, T1=−0.000324 (consistent, NC-EN suppressed band)
- **n=2 mean is −0.000411 BELOW recalibrated floor (3.276518)**
- Sub-Arbor by −0.00127 already at n=2; clean rank-1 trajectory if T2/T3 hold within ±0.001
- T2 terminal ETA ~13:35 UTC, T3 ETA ~15:10 UTC

**Tanjiro H-Y T0 = 3.279331 — important counter-data:**
- Same recipe as nezuko (NC + Arbor + RI) but with `disable_ema_nesterov=True`
- Config verified: `nc_enabled=True`, `disable_ema_nesterov=True`, `ri_enabled=True`, Sinkhorn active ✓
- T0=3.27933 vs nezuko T0=3.27671 → **dropping EN costs +0.00262 absolute at T0**
- T1 running (`99jczfyt`, started 13:12 UTC after 2 pod-induced crashes)
- Comparable to edward Arm B T0 (NC alone, no Arbor): 3.28048

**Provisional mechanism table at T0 (γ=−0.075):**

| Recipe | EN | NC | Arbor | T0 | vs Arbor (3.27738) |
|---|:-:|:-:|:-:|---:|---:|
| Arbor + RI | ✓ | ✗ | ✓ | thorfinn n=4=3.27689 | −0.00049 |
| NC + Arbor + RI (nezuko) | ✓ | ✓ | ✓ | T0=3.27671 | −0.00067 |
| NC + Arbor + RI **no EN** (tanjiro) | ✗ | ✓ | ✓ | T0=3.27933 | **+0.00195** |
| NC alone on PR #309 (edward Arm B) | ✓ | ✓ | ✗ | T0=3.28048 | +0.00310 |
| Arbor + RI **no EN** (frieren H-Z) | ✗ | ✗ | ✓ | T1 in flight | TBD |

**Read:** EN appears critical to the NC×Arbor lift. Frieren H-Z (no EN, no NC) is the cleanest disambiguator — if Frieren also lands at ~3.279, the penalty is from removing EN alone (Arbor needs EN); if frieren stays near 3.27738, then NC×−EN specifically destroys the composition.

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
