# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-06 ~04:40 UTC (launch day +2)
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

## Active assignments (04:40 UTC, 2026-06-06)

| PR | Student | Hypothesis | Target steps | Status |
|---:|---|---|---:|---|
| **#2315** | open2-alphonse | H-S: NC × Arbor + RI triple stack (NC on new merged Arbor base) | 2890 | Just assigned |
| **#2306** | open2-frieren | H-K: NC + RI on PR #309 base (pre-Arbor), n=4 | 2890 | T2 terminal ~04:45, T3 ETA ~06:18 |
| **#2307** | open2-askeladd | H-L: lm_head freeze tail (paired Arm A / Arm B) | 2890 | Arm A T2 at 9%, Arm A T3 ETA ~06:46 |
| **#2309** | open2-fern | H-N: NC + RI on PR #309 base (pre-Arbor), n=4 | 2890 | T1 at 40%, T1 ETA ~05:00 |
| **#2310** | open2-edward | H-O: NC alone on PR #309 base (pre-Arbor), paired arms | 2890 | Arm A T1 at 43%, Arm B chains after Arm A T3 |
| **#2311** | open2-tanjiro | H-P: NC + RI on PR #305 base (universality), n=4 | 2925 | T0 at 47%, rebase conflict flagged (~05:00 T0) |
| **#2312** | open2-nezuko | H-Q: Lookahead-Muon + RI, smoke PASSED | 2890 | Awaiting pace check; n=4 auth pending |
| **#2314** | open2-thorfinn | H-R: Arbor + RI (RI on new merged Arbor base) | 2890 | Just assigned, picking up |

## 🔥 CRITICAL NEW FINDING (04:40 UTC): NC CONFLICTS WITH EMA-NESTEROV

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
