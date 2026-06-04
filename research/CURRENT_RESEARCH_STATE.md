# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-04 (launch day, updated ~22:55 UTC)
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

## Active assignments (as of 2026-06-04 ~22:55 UTC)

| PR | Student | Hypothesis | Base | Target step | Status | Source |
|---:|---|---|---|---:|---|---|
| #2281 | open2-alphonse | H1 NC on Aurora+RRE base | PR #305 | 2925 | trials 0+1 done (3.27688, **3.28211 — regression**), mean 3.27949, trial 2 in progress | PR #295 |
| #2282 | open2-askeladd | H2 EMA-Nesterov (β=0.3) | PR #300 | 2900 | trials 0+1 done (3.28135, 3.28122 — FAIL), trial 2 step 1825/2900 (63%) | PR #309 |
| #2283 | open2-edward | H3 Circuit-Muon isolated | PR #300 | 2930 | `glygz1xt` **trial 0 = 3.27895**, trial 1 step 225/2930 (8%) | PR #311 |
| #2284 | open2-fern | H4 Arbor vs NC ablation (3 arms) | PR #300 | 2930 | Arm A n=4 `m50dnbvb` trial 0 step 2475/2930 (85%, val 3.35); Arm B re-impl pending | PR #295, #310 |
| #2289 | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 3020 | **Arm A `wd1aaqtr` STALLED at step 1875 for 15+ min** — operational comment posted | PR #307, #312 |
| #2286 | open2-nezuko | Replicate PR #309 EMA-Nesterov+Aurora | PR #309 | 2890 | **trials 0+1 done (3.27794, 3.27823), mean 3.27809 ✅verified**, trial 2 step 2250/2890 (78%) — terminal <20 min | PR #309 |
| #2287 | open2-tanjiro | H9 Single-stage Tail Phase Readout | PR #300 | 2930 | **trials 0+1 done (3.27911, 3.27849), mean 3.27880**, trial 2 step 300/2930 (10%) | PR #318 |
| #2288 | open2-thorfinn | Replicate PR #295 NC standalone | base Muon | 3325 | **Arm Z control** trial 0 = 3.27781, trial 1 step 2500/3325 (75%); Arm A NC pending | PR #295 |

**Top contenders (trial-status — ranked by current 2-trial aggregate at sub-3000 step budget):**

| Student | PR | Best 2-trial mean | σ (T0,T1 spread) | Step | Status | Hypothesis |
|---|---:|---:|---:|---:|---|---|
| **nezuko** | **#2286** | **3.27809** | **0.00029 (tight)** | **2890** | **trial 2 at 78% — terminal <20 min** | **EMA-Nesterov + Aurora (PR #309 lineage)** |
| tanjiro | #2287 | 3.27880 | 0.00062 | 2930 | trial 2 at 10% | Single-stage Tail Phase Readout on PR #300 |
| edward | #2283 | 3.27895 (n=1 only) | — | 2930 | trial 1 at 8% | Circuit-Muon isolated on PR #300 |
| alphonse | #2281 | 3.27949 | 0.00523 (large) | 2925 | trial 2 in progress | NC on PR #305 base (Aurora+RRE+Contra-Muon+NC) |
| askeladd | #2282 | 3.28129 | 0.00013 | 2900 | FAILED — falsifying | EMA-Nesterov on PR #300 bare |

**At higher step budget (3325, NOT directly comparable to sub-2900 goal):**

| Student | PR | Best aggregate | Step | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| thorfinn | #2288 | 3.27781 (trial 0, Arm Z = plain Muon control) | 3325 | Arm Z trial 1 at 75%, Arm A NC pending | NC vs control on bare Muon (A/B) |

**Key analytical reads this turn:**

1. **Frieren operational issue (NEW):** Arm A control run `wd1aaqtr` STALLED at step 1875 for 15+ min. GPU memory still pinned (57787 MiB), but W&B no progression. Watchdog "no train.py process" is a false positive (script is `train_gpt_simple.py`). Posted detailed recovery instructions to PR #2289 (W&B upload error in logs is suspect). Manual student intervention required.

2. **Nezuko remains the clear leader** with VERIFIED 2-trial mean **3.27809** (T0=3.27794, T1=3.27823, σ=0.00029). Sub-2900 step budget (2890). T2 at 78% — terminal <20 min. For n=4 mean ≤ 3.278: T2+T3 mean ≤ 3.27791 each (achievable given tight σ).

3. **Tanjiro emerges as solid second contender.** T1 just terminated at 3.27849. Mean(T0,T1)=3.27880 at 2930 steps. σ=0.00062 (much tighter than alphonse's σ=0.00523). For n=4 ≤ 3.278: T2+T3 mean ≤ 3.27720 — tight but plausible. Single-stage Tail Phase Readout is a real mechanism, not noise.

4. **Alphonse T1 regression with high seed variance** — T0=3.27688, T1=3.28211, mean 3.27949. σ=0.00523 is 13× higher than nezuko's. The NC-on-PR#305 stack appears to have higher seed sensitivity. For n=4 ≤ 3.278: T2+T3 mean ≤ 3.27651 — tight given the spread.

5. **Compositional insight (refined):** EMA-Nesterov on PR #300 bare fails (askeladd mean 3.28129); EMA-Nesterov + Aurora succeeds (nezuko mean 3.27809). The Aurora row-balanced polar is the load-bearing element. This is the single clearest compositional signal of the launch.

6. **Compositional priority for next wave (given nezuko leadership):**
   - + NC (PR #295) on EMA-Nesterov + Aurora → most natural, low risk
   - + Reference Interpolation (post-frieren result, if RI works on PR #300)
   - + Circuit-Muon (post-edward T1-T3 results)
   - + Senpai PR #1532 beta2-pulse on nezuko stack
   - Reduce nezuko step count from 2890 → 2850 → 2810 to push fixed-step further

**In-flight observations:**
- Nezuko trial 2 at step 2250/2890 (78%, alive) — terminal <20 min. This is the key event.
- Edward trial 1 just started at step 225/2930 (8%).
- Alphonse trial 2 in progress.
- Tanjiro trial 2 just started at step 300/2930 (10%).
- Fern Arm A NC trial 0 at step 2475/2930 (85%) — terminal ~25 min.
- Thorfinn Arm Z trial 1 at step 2500/3325 (75%) — terminal ~40 min.
- Frieren STALLED — pending student recovery.

**Resolved this turn:**
- Verified nezuko T0/T1 via deep W&B history scan (3.27794, 3.27823) — earlier "3.27943" read was wrong.
- Tanjiro T1 terminal captured (3.27849).
- Frieren operational comment posted (issue #4626714006).

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
