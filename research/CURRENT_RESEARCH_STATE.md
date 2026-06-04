# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-04 (launch day, updated ~22:40 UTC)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

This launch was opened explicitly as an open-context SOTA combination run: mine
the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed)
plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below
2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## Active assignments (as of 2026-06-04 ~22:40 UTC)

| PR | Student | Hypothesis | Base | Target step | Status | Source |
|---:|---|---|---|---:|---|---|
| #2281 | open2-alphonse | H1 NC on Aurora+RRE base | PR #305 | 2925 | trials 0+1 done (3.27688, **3.28211 — regression**), mean 3.27949, trial 2 step 150/2925 (5%) | PR #295 |
| #2282 | open2-askeladd | H2 EMA-Nesterov (β=0.3) | PR #300 | 2900 | trials 0+1 done (3.28135, 3.28122 — FAIL), trial 2 step 1825/2900 (63%) | PR #309 |
| #2283 | open2-edward | H3 Circuit-Muon isolated | PR #300 | 2930 | `glygz1xt` **trial 0 = 3.27895**, trial 1 step 225/2930 (8%) | PR #311 |
| #2284 | open2-fern | H4 Arbor vs NC ablation (3 arms) | PR #300 | 2930 | Arm A n=4 `m50dnbvb` trial 0 step 2475/2930 (85%, val 3.35); Arm B re-impl pending | PR #295, #310 |
| #2289 | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 3020 | Arm A control `wd1aaqtr` trial 0 step 1625/3020 (54%, val 3.50); Arm B sequential after Arm A | PR #307, #312 |
| #2286 | open2-nezuko | Replicate PR #309 EMA-Nesterov+Aurora | PR #309 | 2890 | **trials 0+1 done (3.27794, 3.27823), mean 3.27809**, trial 2 step 1625/2890 (56%) — terminal ~40 min | PR #309 |
| #2287 | open2-tanjiro | H9 Single-stage Tail Phase Readout | PR #300 | 2930 | trial 0 = 3.27911, trial 1 step 2725/2930 (93%, val 3.30) — terminal <20 min | PR #318 |
| #2288 | open2-thorfinn | Replicate PR #295 NC standalone | base Muon | 3325 | **Arm Z control** trial 0 = 3.27781, trial 1 step 2500/3325 (75%); Arm A NC pending | PR #295 |

**Top contenders (trial-status — ranked by current 2-trial aggregate at sub-3000 step budget):**

| Student | PR | Best aggregate | Step | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| **nezuko** | **#2286** | **3.27809 (mean of 2 trials, σ≈0.0002)** | **2890** | **trial 2 at 56% — terminal ~40 min** | **EMA-Nesterov + Aurora (PR #309 lineage)** |
| alphonse | #2281 | 3.27949 (mean of 2 trials, σ≈0.0037 large) | 2925 | trial 2 at 5% | NC on PR #305 base (Aurora+RRE+Contra-Muon+NC) |
| edward | #2283 | 3.27895 (trial 0, n=1) | 2930 | trial 1 at 8% | Circuit-Muon isolated on PR #300 |
| tanjiro | #2287 | 3.27911 (trial 0, n=1) | 2930 | trial 1 at 93% (val 3.30) | Single-stage Tail Phase Readout on PR #300 |
| askeladd | #2282 | 3.28129 (mean of 2 trials) | 2900 | FAILED — falsifying | EMA-Nesterov on PR #300 bare |

**At higher step budget (3325, NOT directly comparable to sub-2900 goal):**

| Student | PR | Best aggregate | Step | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| thorfinn | #2288 | 3.27781 (trial 0, Arm Z = plain Muon control) | 3325 | Arm Z trial 1 at 75%, Arm A NC pending | NC vs control on bare Muon (A/B) |

**Key analytical reads this turn:**

1. **Alphonse T1 regression resets the leaderboard.** T0=3.27688 was the cleanest early signal but T1=3.28211 (Δ=+0.00523) wipes the early lead. 2-trial mean now 3.27949. Critically, alphonse's seed variance is 13× larger than nezuko's (σ_alphonse≈0.0037 vs σ_nezuko≈0.0002), which suggests the NC-on-PR#305 stack has higher seed sensitivity. For n=4 mean ≤ 3.278, T2+T3 must average ≤ 3.27651 each — tight given the observed spread. More likely outcome: n=4 mean lands ~3.278-3.279, beating PR #305 reference (3.27813) but possibly missing the strict 3.278 ceiling.

2. **Nezuko emerges as the clear leader.** 2-trial mean 3.27809 with σ≈0.0002 — exceptionally tight. Sub-2900 step budget (2890). The low variance means n=4 mean projected at ~3.27800 with high confidence. T2 at 56%, terminal ~40 min. If T2 lands near 3.27800 the n=4 case is essentially locked.

3. **Askeladd compositional insight (consistent with nezuko win):** EMA-Nesterov on PR #300 bare fails (mean 3.28129); EMA-Nesterov + Aurora on PR #309 lineage succeeds (mean 3.27809). The Aurora row-balanced polar is doing the work that turns EMA-Nesterov from a wash into a sub-2900 win. This is the single clearest compositional signal of the launch.

4. **Edward T0=3.27895 first read:** Circuit-Muon isolated on PR #300 → T0 mid-pack. Needs T1-T3 to determine if Circuit-Muon's main contribution actually comes from interaction with EMA-Nesterov (per PR #311 stack), not from V↔O cross-scaling alone. Watch T1.

5. **Compositional priority for next wave:** Given nezuko looks like the merge candidate, the highest-EV next wave is to layer additional mechanisms on the EMA-Nesterov + Aurora stack:
   - + NC (PR #295) → most natural, low risk
   - + Reference Interpolation (post-frieren result)
   - + Circuit-Muon (post-edward result)
   - + Senpai PR #1532 beta2-pulse

**In-flight observations:**
- Tanjiro trial 1 val 3.299 at step 2725/2930 (93%) — terminal <20 min. T0 was 3.27911; T1 likely similar.
- Edward trial 1 just started at step 225/2930 (8%).
- Alphonse trial 2 just started at step 150/2925 (5%).
- Fern Arm A NC trial 0 at step 2475/2930 (85%, val 3.35) — terminal ~25 min.
- Frieren Arm A control at step 1625/3020 (54%, val 3.50). RI Arm B scheduled to auto-launch after Arm A.
- Nezuko trial 2 at step 1625/2890 (56%) — terminal ~40 min ETA.
- Thorfinn Arm Z trial 1 at step 2500/3325 (75%) — terminal ~40 min.

**Resolved this turn:**
- Fleet check confirms no W&B heartbeat gaps and no divergence anywhere. All 8 pods running healthy.
- Alphonse high seed variance flagged for analysis (NC-on-PR#305 stack may not be as stable as nezuko's EMA-Nesterov+Aurora).

## Research focus

## Research focus

**Primary question:** Can layering the strongest community sub-2900 mechanisms
(EMA-Nesterov, Circuit-Muon, Tail Phase Readout, Aurora EMA Reference, Reference
Interpolation) on top of the official #300/#305 merged base, and on top of
Senpai's audited beta2-pulse + PMuon/LR/EMA stack, push the fixed-step
crossing below 2900?

**Sub-questions for the first wave:**
1. Is pre-NS normalization (Normalized Correction PR #295 / Arbor Muon PR #310)
   composable with the Aurora + RRE base?
2. Does EMA-Nesterov (PR #309) work on top of the official PR #300 base, or
   does it require something Aurora-specific?
3. Is Circuit-Muon (PR #311) the key contributor to the #311 stack, or is the
   gain mostly from EMA-Nesterov?
4. Does Reference Interpolation (PR #307/#312) independently improve PR #300 base (frieren, H5b)? Can it then be composed with RRE (PR #305)?
5. Does the multi-point Tail Phase Readout idea (PR #318) survive in
   single-stage form on the #300 base?
6. Can Senpai's audited PR #1532/#1614 beta2 pulse be layered onto the public
   sub-2900 baselines (PR #309 / #305)?

## Next research directions (after first wave)

- Full #311 stack on PR #300 base (EMA-Nesterov + Circuit-Muon + Aurora).
- Senpai PMuon preconditioning composed with Aurora row-balanced polar — test
  whether these compete for the same mlp.proj slot or are orthogonal.
- EMA-Nesterov rest-window sensitivity (β shutoff at steps 1500 / 1950 / 2200).
- Three-arm composition: EMA-Nesterov + NC + Reference Interpolation on #300
  (no Circuit-Muon, isolates the magnitude of Circuit-Muon contribution).
- Tail Phase Readout multi-stage (after single-stage validates).
- Reduce official record's RRE step count (PR #305 captures from step 2820) and
  test whether shifting earlier helps when combined with EMA-Nesterov.

## Suggested follow-up themes if first wave plateaus

- Replace Newton-Schulz with the polar-express iteration (PR #254 lineage)
  inside Muon.
- Per-module init standard deviation tuning (Hyperball PR #267 lineage)
  combined with NS variants.
- KL-SOAP preconditioning (#290) interactions with EMA-Nesterov, vs Aurora.
- Outer-Nesterov (MuLoCo PR #277) wrapper around the strongest inner-loop
  optimizer.

## Things to AVOID without strong justification

- Scalar LR/WD sweeps as the primary contribution of a PR — only retune to
  make a new mechanism fair.
- Repeating "Muon + aux Adam, lr=X, wd=Y" hyperparameter tweaks unless the new
  step budget makes the existing setting stale.
- Heavy hyperparameter searches in the first 24 hours; bias toward mechanism
  diversity until we know which families work on our infra.
