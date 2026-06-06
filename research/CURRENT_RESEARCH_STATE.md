# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-06 ~05:25 UTC (launch day +2)
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

## Active assignments (04:55 UTC, 2026-06-06)

| PR | Student | Hypothesis | Target steps | Status |
|---:|---|---|---:|---|
| **#2315** | open2-alphonse | H-S: NC × Arbor + RI triple stack (NC on new merged Arbor base) | 2890 | **NC code re-implemented** (was on closed branches); smoke 250 finished, n=4 launch pending |
| **#2306** | open2-frieren | H-K: NC + RI on PR #309 base (pre-Arbor), n=4 | 2890 | T2=3.27777 (sub-baseline!), T3 just started @ step 125, ETA ~06:18 |
| **#2307** | open2-askeladd | H-L: lm_head freeze tail (paired Arm A / Arm B) | 2890 | **Arm A n=2 mean 3.27727 BELOW new Arbor 3.27738**, T2 @ 61% |
| **#2309** | open2-fern | H-N: NC + RI on PR #309 base (pre-Arbor), n=4 | 2890 | T0=3.27973, paired Δ=−0.00031; T1 @ 61%, ETA ~05:45 |
| **#2310** | open2-edward | H-O: NC alone on PR #309 base (pre-Arbor), paired arms | 2890 | Arm A T0=3.27963; T1 @ 65%, ETA ~05:30 |
| **#2311** | open2-tanjiro | H-P: NC + RI on PR #305 base (universality), n=4 | 2925 | T0=3.2795, paired Δ=−0.0006 (mechanism boundary!); T1 @ 12% |
| **#2312** | open2-nezuko | H-Q: Lookahead-Muon + RI, smoke PASSED | 2890 | n=4 running @ step 675 (duplicate smoke killed) |
| **#2314** | open2-thorfinn | H-R: Arbor + RI (RI on new merged Arbor base) | 2890 | Smoke @ step 1230 val 3.615 (progressing) |

## 🆕 05:25 UTC UPDATE: Tanjiro H-P T0 confirms NC × EMA-Nesterov mechanism boundary

**Tanjiro H-P T0 (NC + RI on PR #305 base, 2925 steps):**
- val/loss (γ=−0.075) = 3.2795
- val/loss (γ=0) = 3.2801
- **Paired Δ = −0.0006** (normal RI lift, comparable to bare Muon H-F −0.0005)
- first_step_to_target = 2925 (just barely reached)

This is **2× larger paired Δ** than PR #309-derived bases (frieren −0.00029, fern −0.00031), confirming:
- **NC × EMA-Nesterov conflict is a SPECIFIC interaction, not a general NC problem**
- NC works normally on bare Muon (H-F) and Aurora-based PR #305 (your data)
- NC conflicts only with EMA-Nesterov state (PR #309)

**Mechanism interpretation refined:** PR #309's EMA-Nesterov (β=0.95) captures per-step momentum-sign info that NC's row/col gating duplicates. PR #305 uses Aurora + Contra-Muon (different momentum mechanism), no conflict.

Absolute val/loss 3.2795 still above merged baselines (Arbor 3.27738, RI 3.27786). PR #305 + NC at 2925 steps doesn't directly compete with PR #309-derived stacks, but the mechanism finding is publishable.

## 🆕 04:55 UTC UPDATE: Askeladd Arm A shows surprising strength

**Askeladd H-L Arm A (RI-only, NO freeze, NO Arbor — essentially fern's merged stack):**

| Trial | val/loss (γ=−0.075) | val/loss (γ=0) | Paired Δ | first_step_to_target |
|---:|---:|---:|---:|---:|
| T0 | 3.27757 | — | — | 2875 |
| T1 | **3.27697** | 3.27729 | −0.00032 | 2850 |
| n=2 mean | **3.27727** | — | — | — |

**Arm A n=2 mean 3.27727 BEATS new Arbor baseline 3.27738 by −0.00011** at single-trial level. If T2/T3 stay in the 3.276–3.278 band, Arm A n=4 mean could push below 3.27738 — but this would NOT directly merge (Arm A is same RI mechanism already merged on fern's PR #2295). Instead it would imply:
- Either: Arbor's −0.00048 over fern was seed luck (alphonse's seed sequence happened to be lucky; askeladd's is similarly lucky)
- OR: There's something distinctive about askeladd's environment giving slight uplift

Real merge-eligibility test is Arm B (freeze tail) paired Δ vs Arm A. If Arm B improves paired Δ ≤ −0.0003 AND n=4 mean < 3.27738, then freeze tail composes with RI for new rank-1.

## 🔬 Frieren T2 = 3.27777 — sub-baseline single trial, mean still high

Frieren H-K n=3 standing (NC + RI on PR #309 base):

| Trial | val/loss (γ=−0.075) | Note |
|---:|---:|---|
| T0 | 3.28091 | high tail |
| T1 | 3.27996 | mid |
| **T2** | **3.27777** | **sub-baseline single trial** (below fern's 3.27786) |
| n=3 mean | 3.27955 | high due to T0 tail |

T2 below fern's merged 3.27786 at trial level confirms NC × RI sometimes lands well, but the high variance + T0 tail dominate the n=4 mean. T3 would need ≤ 3.27280 to beat fern's mean (extremely tight). Most likely close with mechanism finding (NC × EMA-Nesterov conflict).

## 🔥 CRITICAL FINDING (04:40 UTC): NC CONFLICTS WITH EMA-NESTEROV

### NC hurts on PR #309 base — EMA-Nesterov conflict confirmed

| Experiment | Mechanism | T0 val/loss | vs fern merged 3.27786 | vs PR #309 base 3.27813 |
|---|---|---:|---:|---:|
| frieren H-K T0 | NC + RI (γ=−0.075) | 3.27996 | +0.00210 (WORSE) | +0.00183 (WORSE) |
| frieren H-K T0 γ=0 | NC only | ~3.28091 | +0.00305 (WORSE) | +0.00278 (WORSE) |
| edward H-O T0 | NC only (Arm A = no-NC control) | 3.27963 | +0.00177 | +0.00150 |
| fern H-N T0 | NC + RI (γ=−0.075) | 3.27973 | +0.00187 | +0.00160 |

**All NC experiments on PR #309 base are ABOVE the pre-Arbor fern RI baseline (3.27786).** NC is a net negative on EMA-Nesterov bases.

**Mechanism interpretation:** PR #309's EMA-Nesterov (β=0.95) creates a per-step momentum correction that already captures sign-consistency information. NC adds a redundant sign-gate on top, interfering with the existing momentum state. On bare Muon (no EMA-Nesterov), NC provides clean signal; on EMA-Nesterov, it double-counts momentum and reduces gradient fidelity.

**Paired RI Δ within NC stack:** frieren H-K T0 Δ(γ=−0.075 vs γ=0) = −0.000947 (RI still helps, and lift is LARGER than without NC). The enlarged RI Δ under NC suggests NC changes the parameter trajectory to be more linear/directional in the tail — mechanistically interesting, but doesn't compensate for NC's base hurt.

### Implications for H-S (alphonse, NC × Arbor + RI)

If NC hurts on all EMA-Nesterov-derived bases, H-S will likely also show NC hurting on Arbor+RI base (which is still EMA-Nesterov underneath). BUT:
- Arbor's Sinkhorn equilibration reshapes parameter distributions
- This might change how EMA-Nesterov interacts with sign information
- Still worth running: either confirms mechanism boundary or reveals unexpected composability

## Compositional verdict table (04:40 UTC)

| Mechanism | Base | Status |
|---|---|---|
| RI alone | PR #309 | ✅ MERGED at 3.27786 (fern PR #2295) |
| Arbor (corrected) | PR #309 + RI | ✅ **MERGED at 3.27738 (alphonse PR #2298)** — RANK-1 |
| NC (Cautious-Muon) | bare Muon | ✅ CONFIRMED (paired Δ −0.0005 at 3325 steps) |
| NC + RI | bare Muon | ✅ CONFIRMED n=4 — 3.274723 at 3325 steps |
| RI | PR #300 / #305 | ✅ UNIVERSAL |
| **NC alone** | **PR #309 (EMA-Nesterov)** | **⚠️ T0 = 3.27963 — HURTS vs RI-only baseline** |
| **NC + RI** | **PR #309 (EMA-Nesterov)** | **⚠️ T0 = 3.27996 — HURTS vs RI-only baseline** |
| **NC + RI** | **PR #309 (EMA-Nesterov)** | **⏳ n=4 confirming frieren H-K, fern H-N, edward H-O** |
| Arbor + RI | PR #309 | ⏳ thorfinn H-R (PR #2314) — just assigned |
| NC + Arbor + RI | PR #309 | ⏳ alphonse H-S (PR #2315) — just assigned |
| lm_head freeze + RI | PR #309 | ⏳ askeladd H-L Arm A/B — Arm A T2 running |
| Lookahead-Muon + RI | PR #309 | ⏳ nezuko H-Q (PR #2312) — smoke passed, n=4 pending |
| NC + RI | PR #305 | ⏳ tanjiro H-P (PR #2311) — T0 47% |

## Recent closures

| PR | Student | Verdict | Key finding |
|---:|---|---|---|
| #2313 | alphonse | MERGED (cleanup) | Arbor now always-on. Removed broken sqrt path + flags. |
| #2308 | thorfinn | CLOSED | NC+RI on bare Muon at 2890 steps: target unreachable (3.298). Step budget too short. |
| #2298 | alphonse | **MERGED RANK-1** | Corrected Arbor Muon: 3.27738 n=4. |
| #2305 | nezuko | CLOSED | H-J Richardson null: two-snapshot = no gain over one-snapshot. |

## Next-wave hypotheses (when students free up)

**When frieren H-K closes (~06:30 UTC):**
- **H-T: Freeze tail × Arbor** — does lm_head freeze compose with Arbor (orthogonal to RI)?
- OR **H-U: Arbor on PR #305 base** — does Arbor work on a different optimizer stack?

**After edward H-O Arm B (~12:00 UTC):**
- Final verdict on NC conflict (paired Δ n=4 confirms mechanism)
- If confirmed null: **H-V: Muon momentum parameter sweep (β)** on Arbor base — can tweaking β=0.95 give RI-like lift without the separate RI mechanism?

**Bold bets (if top of stack has plateaued):**
- Aitken's Δ² acceleration on terminal window
- Per-layer capture step (early layers converge faster)
- Lookahead k/α grid search (if H-Q shows positive signal)

## Watch items (next 4h from 04:40 UTC)

| Time | Event | Expected |
|---|---|---|
| ~04:45 | Frieren H-K T2 terminal | NC+RI val/loss ~3.279; paired Δ ~ −0.0009 |
| ~05:00 | Edward H-O T1 terminal | NC alone T1 above baseline; watch for consistency |
| ~05:00 | Fern H-N T1 terminal | NC+RI T1; confirm T0 pattern |
| ~05:00 | Tanjiro H-P T0 terminal | NC+RI on PR #305 base; universality grid |
| ~05:30 | Nezuko H-Q n=4 launch decision | Awaiting pace confirmation |
| ~06:18 | Frieren H-K T3 terminal + close | Close + reassign frieren to H-T or H-U |
| ~06:46 | Askeladd H-L Arm A T3 terminal | Arm B watchdog chains after |

## Operational notes (04:40 UTC)

- All 8 students active. Zero idle GPUs.
- **NC × EMA-Nesterov conflict discovered** — reframes H-S expected outcome.
- Tanjiro PR #2311 has merge conflict (from Arbor cleanup). Run continues; rebase before marking review.
- Nezuko H-Q 2x slowdown under investigation. Smoke val/loss 3.4510 at step 1500 is promising.
- Thorfinn H-R and alphonse H-S are the two highest-priority experiments: Arbor+RI and NC×Arbor+RI respectively.
