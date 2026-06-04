# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-04 (launch day, updated ~22:05 UTC)
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

## Active assignments (as of 2026-06-04 ~20:00 UTC)

| PR | Student | Hypothesis | Base | Target step | Status | Source |
|---:|---|---|---|---:|---|---|
| #2281 | open2-alphonse | H1 NC on Aurora+RRE base | PR #305 | 2925 | trial 0 = 3.2769, trial 1 step ~2125 (72%, val 3.40) | PR #295 |
| #2282 | open2-askeladd | H2 EMA-Nesterov (β=0.3) | PR #300 | 2900 | trials 0+1 done (3.28135, 3.28122 — FAIL), trial 2 step ~875 | PR #309 |
| #2283 | open2-edward | H3 Circuit-Muon isolated | PR #300 | 2930 | n=4 `glygz1xt` trial 0 step ~2250 (77%, val 3.37) | PR #311 |
| #2284 | open2-fern | H4 Arbor vs NC ablation (3 arms) | PR #300 | 2930 | Arm A n=4 `m50dnbvb` trial 0 step ~1500 (51%); Arm B re-impl pending | PR #295, #310 |
| #2289 | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930 | Arm A control `wd1aaqtr` trial 0 step ~1125 (38%); Arm B sequential after Arm A | PR #307, #312 |
| #2286 | open2-nezuko | Replicate PR #309 EMA-Nesterov+Aurora | PR #309 | 2890 | **trials 0+1 done (3.27794, 3.27823), mean 3.27809**, trial 2 step ~625 | PR #309 |
| #2287 | open2-tanjiro | H9 Single-stage Tail Phase Readout | PR #300 | 2930 | trial 0 = 3.2791, trial 1 step ~1750 (60%, val 3.47) | PR #318 |
| #2288 | open2-thorfinn | Replicate PR #295 NC standalone | base Muon | 3325 | **Arm Z control** trial 0 = 3.2778, trial 1 step ~1375 (41%); Arm A NC pending | PR #295 |

**Top contenders (trial-status — ranked by current best aggregate):**

| Student | PR | Best aggregate | Step | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| nezuko | #2286 | **3.27809 (mean of 2 trials)** | 2890 | trials 2-3 in progress | EMA-Nesterov + Aurora (PR #309 lineage) |
| alphonse | #2281 | 3.2769 (trial 0) | 2925 | trial 1 ~72% | NC on PR #305 base (Aurora+RRE+Contra-Muon+NC) |
| tanjiro | #2287 | 3.2791 (trial 0) | 2930 | trial 1 ~60% | Single-stage Tail Phase Readout on PR #300 |
| thorfinn | #2288 | 3.2778 (trial 0, Arm Z = plain Muon control) | 3325 | Arm Z trial 1, Arm A NC pending | NC vs control on bare Muon (A/B) |
| askeladd | #2282 | 3.28129 (mean of 2 trials) | 2900 | FAILED — falsifying | EMA-Nesterov on PR #300 bare |

**Key analytical reads this turn:**

1. **Thorfinn correction:** `sx4q2hn0` is **Arm Z (control = plain Muon)**, not Arm A (NC). The 3.2778 trial 0 is the plain-Muon baseline at step 3325, not a "win". The NC arm hasn't started yet. His proper A/B will give matched-seed NC delta when Arm A launches. This actually moves him *off* the contender list — his result so far is a control baseline.

2. **Nezuko is the merge frontrunner.** Sub-2900 step count (2890) with 2-trial mean 3.27809 below PR #300 (3.27844) and PR #305 (3.27813). Trials 2-3 needed for n=4 stat-sig — current margin tight.

3. **Askeladd compositional insight (consistent with nezuko win):** EMA-Nesterov on PR #300 bare fails (mean 3.28129); EMA-Nesterov + Aurora on PR #309 lineage succeeds (mean 3.27809). The Aurora row-balanced polar is doing the work that turns EMA-Nesterov from a wash into a sub-2900 win.

**In-flight observations:**
- Alphonse trial 1 val 3.40 at step 2125/2925 looks slightly elevated vs trial 0 (3.277 final). Watching whether it descends normally to ≤ 3.28 at terminal.
- Edward trial 0 at step 2250/2930 (77%, val 3.37) close to terminal — expected within ~30 min.
- Fern Arm A NC trial 0 at step 1500/2930 (51%, val 3.52); Arm B re-impl pending per her own PR #310 spec correction.
- Frieren Arm A control at step 1125/3020 (38%, val 3.61). RI Arm B scheduled to auto-launch after Arm A.

**Resolved this turn:**
- W&B step encoding `trial_idx × (train_steps+1) + step` (line 676) misread as "divergence to 10.82 after target step". Actually trial 2 starting fresh — runs are healthy.
- PR #2285 (frieren H5 RI on PR #305 base) — closed earlier; PR #305 base NaN on Blackwell.
- Histogram bug fix landed on advisor branch as f8ecb78e (from tanjiro's eeaf2a30).

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
