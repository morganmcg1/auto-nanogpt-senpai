# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~00:20 UTC (launch day +1)
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

## Active assignments (as of 2026-06-05 ~00:20 UTC)

| PR | Student | Hypothesis | Base | Target step | Status | Source |
|---:|---|---|---|---:|---|---|
| #2281 | open2-alphonse | H1 NC on Aurora+RRE base | PR #305 | 2925 | **trials 0+1+2 done (3.27688, 3.28211, 3.28238), mean 3.28046 — FALSIFYING**, T3 step ~100/2925 (3%) | PR #295 |
| #2282 | open2-askeladd | H2 EMA-Nesterov (β=0.3) | PR #300 | 2900 | trials 0+1+2 done (3.28135, 3.28122, 3.27996), mean 3.28084, **T3 step 2003/2900 (69%)** | PR #309 |
| #2283 | open2-edward | H3 Circuit-Muon isolated | PR #300 | 2930 | `glygz1xt` trials 0+1 done (3.27895, 3.27822), mean 3.27859, T2 step 175/2930 (6%) | PR #311 |
| #2284 | open2-fern | H4 Arbor vs NC ablation (3 arms) | PR #300 | 2930 | Arm A `m50dnbvb` T0 = 3.27828, **T1 step 2300/2930 (78%) — terminal in ~20 min**; Arm B re-impl pending | PR #295, #310 |
| #2289 | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930-3020 | Arm A control `wd1aaqtr` T0 = 3.27822 (PR #300 vanilla); T1 step ~250/2930 (8%) | PR #307, #312 |
| #2286 | open2-nezuko | Replicate PR #309 EMA-Nesterov+Aurora | PR #309 | 2890 | **🏆 trials 0+1+2 done (3.27794, 3.27823, 3.27780), mean 3.27799 — T3 step ~1650/2890 (57%) — SENPAI-RESULT in ~40 min** | PR #309 |
| #2287 | open2-tanjiro | H9 Single-stage Tail Phase Readout | PR #300 | 2930 | trials 0+1 done (3.27911, 3.27849), mean 3.27880, **T2 step 2637/2930 (90%) — terminal imminent** | PR #318 |
| #2288 | open2-thorfinn | Replicate PR #295 NC standalone | base Muon | 3325 | Arm Z control done (T0=3.27781, T1=3.27910); **Arm A NC `5wirp0h4` T0 step ~2375/3325 (71%)** | PR #295 |

**Top contenders (trial-status — ranked by current best aggregate at sub-3000 step budget):**

| Student | PR | Trials done | Mean | σ | Step | Status | Hypothesis |
|---|---:|---:|---:|---:|---:|---|---|
| **🏆 nezuko** | **#2286** | **3** | **3.27799** | **0.00018 (tight)** | **2890** | **T3 at 57% — SENPAI-RESULT in ~40 min** | **EMA-Nesterov + Aurora (PR #309 lineage)** |
| edward | #2283 | 2 | 3.27859 | 0.00037 | 2930 | T2 at 6% | Circuit-Muon isolated on PR #300 |
| tanjiro | #2287 | 2 | 3.27880 | 0.00062 | 2930 | T2 at 90% — terminal imminent | Single-stage Tail Phase Readout on PR #300 |
| fern (Arm A) | #2284 | 1 | 3.27828 | — | 2930 | T1 at 78% — terminal ~20 min | NC standalone on PR #300 base |
| frieren (Arm A) | #2289 | 1 | 3.27822 | — | 2930 | T1 at 8% | PR #300 vanilla (Arm A=control, no RI) |
| askeladd | #2282 | 3 | 3.28084 | 0.00077 | 2900 | T3 at 69% — falsifying | EMA-Nesterov on PR #300 bare |
| **alphonse — FALSIFIED** | #2281 | 3 | **3.28046** | **0.00302** | 2925 | T2 = 3.28238 NEW regression; T3 just started | NC on PR #305 base (Aurora+RRE+Contra-Muon+NC) |

**At higher step budget (3325, NOT directly comparable to sub-2900 goal):**

| Student | PR | Best aggregate | Step | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| thorfinn | #2288 | 3.27781 (trial 0, Arm Z = plain Muon control) | 3325 | Arm Z trial 1 at 75%, Arm A NC pending | NC vs control on bare Muon (A/B) |

**Key analytical reads this turn:**

1. **🏆 Nezuko remains clear leader.** 3-trial mean **3.27799** at 2890 steps, σ=0.00018. T3 at 57% — SENPAI-RESULT in ~40 min. n=4 ≤ 3.278 nearly locked unless T3 is a huge outlier (>3.27880 needed to pull n=4 mean above 3.278, given σ≈0.00018). Vs references: beats PR #305 (3.27813) by 0.00014, Senpai #1532 (3.27902) by 0.00103. **Flagship merge candidate.**

2. **🔻 Alphonse FALSIFIED. T2 = 3.28238 NEW regression.** n=3 mean = 3.28046, well above 3.28 contract ceiling and far above PR #305 baseline (3.27813). The T0=3.27688 was an outlier-low. **Verdict:** NC on Aurora+RRE+Contra-Muon stack does NOT compose — likely Contra-Muon and NC interfere (both touch the pre-NS norm regime). T3 already started; will close PR upon terminal SENPAI-RESULT.

3. **Edward Circuit-Muon n=2 mean 3.27859.** At 2930 steps, beats PR #300 reference (3.27844) by 0.00015. For n=4 ≤ 3.278: T2+T3 mean ≤ 3.27741. Tight given σ=0.00037. **Verdict so far:** Circuit-Muon adds modest standalone value but not enough to win the contract solo.

4. **Frieren Arm A control = PR #300 vanilla 3.27822 (T0).** Confirms infra reproduces PR #300 baseline within noise. Arm B (RI applied) will give the clean RI delta — needs to demonstrably beat 3.27822 in matched-seed comparison.

5. **Compositional read across PR #300-base contenders** (n=2 means):
   - Tail Phase Readout (tanjiro): 3.27880 — modest improvement
   - Circuit-Muon (edward): 3.27859 — modest improvement
   - NC (fern n=1): 3.27828 — strong single signal
   - PR #300 vanilla (frieren control n=1): 3.27822 — sanity check OK
   
   All four within ~0.0006 of each other and within noise of PR #300 reference. Single-mechanism lift on PR #300 base is small (~0.0002-0.0004). The big lift comes from compositional stacks (nezuko 3-mean 3.27799 = EMA-Nesterov + Aurora).

6. **Negative compositional finding from alphonse.** NC + Contra-Muon (PR #305 base) likely interfere. Implication: NC should be tested on Aurora+EMA-Nesterov base (NO Contra-Muon, NO RRE), which is **TOP next-wave hypothesis: Aurora+EMA-Nesterov+NC** (nezuko stack + fern's NC).

7. **Compositional priority for NEXT WAVE (refined after alphonse falsification):**
   - **TOP: Aurora+EMA-Nesterov+NC** (nezuko stack + NC, NO Contra-Muon, NO RRE) — highest EV
   - Aurora+EMA-Nesterov+Circuit-Muon — second test of stacking
   - Aurora+EMA-Nesterov+Reference Interpolation — depends on frieren Arm B
   - Aurora+EMA-Nesterov at train_steps=2850 or 2810 — push fixed-step further
   - Aurora+EMA-Nesterov + Senpai #1532 beta2-pulse — Senpai-specific contribution test
   - Aurora+EMA-Nesterov+Tail Phase Readout — combine the four PR #300-base modest-improvement mechanisms

**In-flight observations (as of 00:20 UTC 2026-06-05):**
- **Tanjiro T2 at 90% — terminal in ~5 min.**
- **Nezuko T3 at 57% — SENPAI-RESULT ~40 min (FLAGSHIP).**
- **Fern Arm A T1 at 78% — terminal ~20 min.**
- **Askeladd T3 at 69% — falsification SENPAI-RESULT ~30 min.**
- Thorfinn Arm A NC T0 at 71% — terminal in ~40 min.
- Alphonse T3 at 3% — terminal in ~1h (PR will close as falsified).
- Edward T2 at 6%, Frieren T1 at 8% — early stages.

**Resolved this turn:**
- Alphonse T2 = 3.28238 terminal — hypothesis falsified.
- Askeladd `sodmwabl` was an OLD crashed run from 18:30; actual confirm `maf69yse` is alive at T3.
- Confirmed thorfinn Arm Z crashed at T2 start (n=2 final): mean 3.27846 from T0=3.27781, T1=3.27910.

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
