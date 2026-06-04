# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-04 (launch day, updated ~22:30 UTC)
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

## Active assignments (as of 2026-06-04 ~22:30 UTC)

| PR | Student | Hypothesis | Base | Target step | Status | Source |
|---:|---|---|---|---:|---|---|
| #2281 | open2-alphonse | H1 NC on Aurora+RRE base | PR #305 | 2925 | **trial 0 = 3.27688 (early leader)**, trial 1 step 2525/2925 (86%, val 3.334 descending) | PR #295 |
| #2282 | open2-askeladd | H2 EMA-Nesterov (β=0.3) | PR #300 | 2900 | trials 0+1 done (3.28135, 3.28122 — FAIL), trial 2 step 1200/2900 (41%) | PR #309 |
| #2283 | open2-edward | H3 Circuit-Muon isolated | PR #300 | 2930 | n=4 `glygz1xt` trial 0 step 2575/2930 (88%, val 3.331) — terminal ~30 min | PR #311 |
| #2284 | open2-fern | H4 Arbor vs NC ablation (3 arms) | PR #300 | 2930 | Arm A n=4 `m50dnbvb` trial 0 step 1800/2930 (61%, val 3.47); Arm B re-impl pending | PR #295, #310 |
| #2289 | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 3020 | Arm A control `wd1aaqtr` trial 0 step 1250/3020 (41%, val 3.58); Arm B sequential after Arm A | PR #307, #312 |
| #2286 | open2-nezuko | Replicate PR #309 EMA-Nesterov+Aurora | PR #309 | 2890 | **trials 0+1 done (3.27794, 3.27823), mean 3.27809**, trial 2 step 1025/2890 (35%) | PR #309 |
| #2287 | open2-tanjiro | H9 Single-stage Tail Phase Readout | PR #300 | 2930 | trial 0 = 3.2791, trial 1 step 2100/2930 (72%, val 3.42 descending normally) | PR #318 |
| #2288 | open2-thorfinn | Replicate PR #295 NC standalone | base Muon | 3325 | **Arm Z control** trial 0 = 3.2778, trial 1 step 2195/3325 (66%); Arm A NC pending | PR #295 |

**Top contenders (trial-status — ranked by current best aggregate at sub-3000 step budget):**

| Student | PR | Best aggregate | Step | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| **alphonse** | **#2281** | **3.27688 (trial 0)** | **2925** | **trial 1 at 86% (val 3.334)** | **NC on PR #305 base (Aurora+RRE+Contra-Muon+NC)** |
| nezuko | #2286 | 3.27809 (mean of 2 trials) | 2890 | trial 2 at 35% | EMA-Nesterov + Aurora (PR #309 lineage) |
| tanjiro | #2287 | 3.27911 (trial 0) | 2930 | trial 1 at 72% | Single-stage Tail Phase Readout on PR #300 |
| askeladd | #2282 | 3.28129 (mean of 2 trials) | 2900 | FAILED — falsifying | EMA-Nesterov on PR #300 bare |

**At higher step budget (3325, NOT directly comparable to sub-2900 goal):**

| Student | PR | Best aggregate | Step | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| thorfinn | #2288 | 3.27781 (trial 0, Arm Z = plain Muon control) | 3325 | Arm Z trial 1 at 66%, Arm A NC pending | NC vs control on bare Muon (A/B) |

**Key analytical reads this turn:**

1. **Alphonse vaults to early lead.** Trial 0 = 3.27688 at 2925 steps. Compared with public references:
   - PR #300 (16-seed): 3.27844 @ 2930 — alphonse n=1 is 0.00156 below this
   - PR #305 (8-seed): 3.27813 @ 2925 — alphonse n=1 is 0.00125 below this
   - PR #309 (claim): 3.278 @ 2890 (his stack is at 2925)
   - Even if trials 1-3 average 3.279, n=4 mean = (3.27688 + 3.279×3)/4 = 3.27847 — still within statistical contract `(3.28-mu)×√4 ≥ 0.004` (need mean ≤ 3.278). Margin tight but plausible.

2. **Nezuko remains a strong sub-2900 contender.** 2-trial mean 3.27809 below both PR #300 and PR #305. For n=4 statistical contract at 2890 steps, trials 2-3 must average ≤ 3.27791 each (mean 3.278 over all 4). Achievable given trial-1 variance pattern.

3. **Askeladd compositional insight (consistent with nezuko win):** EMA-Nesterov on PR #300 bare fails (mean 3.28129); EMA-Nesterov + Aurora on PR #309 lineage succeeds (mean 3.27809). The Aurora row-balanced polar is doing the work that turns EMA-Nesterov from a wash into a sub-2900 win.

4. **Compositional read on alphonse vs nezuko:** Both achieve sub-3.278 at sub-3000 steps. Alphonse's stack (Aurora+RRE+Contra-Muon+NC) and nezuko's stack (Aurora+EMA-Nesterov) share Aurora as the load-bearing element. If both n=4 confirm, the natural next experiment is **Aurora+RRE+Contra-Muon+NC+EMA-Nesterov** stacked — predicting they're orthogonal.

5. **Thorfinn Arm Z (plain Muon control at 3325)** = 3.27781 confirms plain Muon meets the contract at 3325 budget. NOT directly comparable to sub-2900 goal; informs PR #295 NC's standalone value when Arm A launches.

**In-flight observations:**
- Alphonse trial 1 val 3.334 at step 2525/2925 (86%) — descending normally, terminal ~25 min ETA.
- Edward trial 0 at step 2575/2930 (88%, val 3.331) — terminal ~30 min ETA. First major signal on Circuit-Muon isolated.
- Tanjiro trial 1 val 3.420 at step 2100/2930 (72%) — descending normally (earlier "elevated" flag was projection-based; actual descent on-track).
- Fern Arm A NC trial 0 at step 1800/2930 (61%, val 3.47); Arm B re-impl pending per her own PR #310 spec correction.
- Frieren Arm A control at step 1250/3020 (41%, val 3.58). RI Arm B scheduled to auto-launch after Arm A.
- Nezuko trial 2 at step 1025/2890 (35%) — pace will determine n=4 close.

**Resolved this turn:**
- Fleet check confirms no W&B heartbeat gaps and no real divergence anywhere. All 8 pods running.
- Thorfinn run identity = Arm Z (plain Muon control), Arm A NC not yet launched. Suggestion posted to cut Arm Z to n=2 to save ~5h GPU time before Arm A launch.

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
