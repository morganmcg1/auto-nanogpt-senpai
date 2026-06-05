# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~02:50 UTC (launch day +1)
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

## Active assignments (as of 2026-06-05 ~01:30 UTC)

| PR | Student | Hypothesis | Base | Target step | Status | Source |
|---:|---|---|---|---:|---|---|
| **#2292** | open2-alphonse | **H12 Senpai #1532 β2-pulse on PR #309 base NEW** | PR #309 | 2890 | just assigned (replaces closed #2281) | Senpai #1532/#1614 + PR #309 |
| **#2291** | open2-askeladd | **H11 Aurora+EMA-Nesterov+Circuit-Muon NEW** | PR #309 | 2890 | just assigned (replaces closed #2282) | nezuko #2286 + edward #2283 |
| #2283 | open2-edward | H3 Circuit-Muon isolated | PR #300 | 2930 | T0+T1 done (3.27895, 3.27822), mean 3.27859, T2 in progress | PR #311 |
| #2284 | open2-fern | H4 Arbor vs NC ablation (3 arms) | PR #300 | 2930 | Arm A T0=3.27828, T1=3.27760, **2-mean 3.27794** — leader!, T2 in progress | PR #295, #310 |
| #2289 | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930-3020 | Arm A control T0=3.27822; T1 in progress | PR #307, #312 |
| **#2290** | open2-nezuko | **H10 Aurora+EMA-Nesterov+NC NEW** | PR #309 | 2890 | just assigned (replaces closed #2286) | nezuko #2286 + fern #2284 |
| **#2293** | open2-tanjiro | **H13 Senpai #1614 PMuon on PR #309 base NEW** | PR #309 | 2890 | just assigned (replaces closed #2287) | Senpai #1532/#1614 + PR #309 |
| #2288 | open2-thorfinn | Replicate PR #295 NC standalone | base Muon | 3325 | Arm Z control n=2 mean 3.27846; **Arm A NC T0 = 3.27461 — striking**, T1 in progress | PR #295 |

**Closed this turn:** PR #2287 (tanjiro — single-stage TPR on PR #300 falsified, n=4 mean 3.27901, margin 0.001975 < 0.004; pulse mechanism real but ~30% post-pulse momentum slowdown erodes gain). Earlier this round: PR #2281 (alphonse — NC on PR #305 base falsified, n=4 mean 3.279857). Prior: PR #2286 (nezuko — 3.27838 tail event). PR #2282 (askeladd — 3.28075).

**Key new compositional read:** Alphonse vs fern Arm A discriminating variable is **RRE, not Contra-Muon**. Both have NC + Aurora + Contra-Muon; only alphonse has RRE. Alphonse FAILS, fern Arm A LEADS at n=2 mean 3.27794. Hypothesis: **NC + RRE interfere** (RRE re-extrapolates from NC-normalized updates, cancelling NC's directional adjustment).

**Top contenders (trial-status — ranked by current best aggregate at sub-3000 step budget):**

| Student | PR | Trials done | Mean | σ | Step | Status | Hypothesis |
|---|---:|---:|---:|---:|---:|---|---|
| **🥇 fern (Arm A)** | #2284 | **3** | **3.27830** | **0.00072** | 2930 | T2=3.27903 NEW (above T0/T1); T3 ~17%; **leader status eroded but still tight** | **NC standalone on PR #300 base** |
| edward | #2283 | **3** | **3.27936** | **— σ recalc pending** | 2930 | T0=3.27924, T1=3.28046, T2=3.27838 (corrected); T3 at 53% | Circuit-Muon isolated on PR #300 |
| frieren (Arm A) | #2289 | 1 | 3.27822 | — | 2930 | T1 at 34% | PR #300 vanilla (Arm A=control, no RI) |
| **nezuko — n=4 done, FAILS STAT-SIG** | #2286 | 4 | **3.27838** | **0.00080 (T3 tail)** | 2890 | T3=3.27956 tail event | EMA-Nesterov + Aurora (PR #309 lineage) |
| **tanjiro — FALSIFIED + CLOSED** | #2287 | 4 | **3.27901** | **0.00051** | 2930 | T0=3.27911, T1=3.27849, T2=3.27968, T3=3.27877; pulse real but post-pulse slow | Single-stage Tail Phase Readout on PR #300 |
| **askeladd — FALSIFIED** | #2282 | 4 | **3.28075** | **0.00059** | 2900 | T3=3.28046 done | EMA-Nesterov on PR #300 bare |
| **alphonse — FALSIFIED + CLOSED** | #2281 | 4 | **3.27986** | **0.00242** | 2925 | T0=3.27688, T1=3.28211, T2=3.28238, T3=3.27806; bimodal | NC on PR #305 base (Aurora+RRE+Contra-Muon+NC) |

**At higher step budget (3325, NOT directly comparable to sub-2900 goal):**

| Student | PR | Arm Z (control) | Arm A (NC) | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| thorfinn | #2288 | n=2 mean 3.27846 (T0=3.27781, T1=3.27910) | **T0 = 3.27461 NEW — striking** | Arm A T1 starting | NC vs control on bare Muon (A/B) |

**Key analytical reads this turn:**

1. **🔴 Nezuko T3 TAIL EVENT — n=4 mean fails stat-sig.** T3 = 3.27956 vs T0/T1/T2 mean 3.27799 (σ=0.00018). T3 is ~9σ above prior trials — true tail-of-distribution event. n=4 mean = **3.27838**, margin (3.28-3.27838)*√4 = 0.00324 < 0.004 required. Also worse than PR #305 baseline (3.27813) on raw mean. **NOT mergeable.**

   *Interpretation:* The underlying EMA-Nesterov+Aurora mean appears to be ~3.27800 with high seed-to-seed variance. PR #309's claimed sub-2890 result may have been cherry-picked or used different seeds. The mechanism is real but the margin is fragile.

   *Options:* (a) extend to n=8 to wash out tail — needs new 4-trial mean ≤ 3.27762, (b) reassign nezuko to the higher-EV compositional hypothesis Aurora+EMA-Nesterov+NC.

2. **🥇 Fern NC standalone now the best sub-2900 candidate.** T0=3.27828, T1=3.27760, n=2 mean **3.27794** at 2930 steps. If T2/T3 hold, n=4 mean projects in [3.27760, 3.27828] — would BEAT PR #305 (3.27813) and clear stat-sig (margin (3.28-3.27780)*√4 = 0.00440). T2/T3 ETA ~6h. **Primary merge candidate now.**

3. **Thorfinn Arm A NC T0 = 3.27461 at 3325 steps** — striking single result. Arm Z control at same steps was n=2 mean 3.27846. Delta = -0.00385 at single trial. If this replicates across T1/T2/T3, NC is a substantial contributor on bare Muon. Note: 3325 ≠ sub-2900 contract, but informs compositional understanding.

4. **Askeladd FALSIFIED.** n=4 mean 3.28075 confirms EMA-Nesterov bare-PR #300 does NOT compose to a sub-2900 win. The PR #309 mechanism's lift comes from interaction with Aurora.

5. **Compositional landscape after first wave:**
   - **NC on PR #300 base (fern Arm A)**: strong, possibly contract-clearing
   - **NC on bare Muon (thorfinn Arm A)**: strong T0, more trials pending
   - **NC + Contra-Muon (alphonse)**: FAILED — likely interference
   - **EMA-Nesterov + Aurora (nezuko)**: replicable mean ~3.27800 but tail-prone
   - **EMA-Nesterov bare (askeladd)**: FAILED
   - **Circuit-Muon (edward)**: modest standalone signal
   - **Tail Phase Readout (tanjiro)**: modest standalone signal
   - **RI (frieren Arm B)**: pending

6. **Refined NEXT WAVE priorities:**
   - **TOP: Aurora+EMA-Nesterov+NC** — combines two strong signals; still highest EV
   - **2nd: Aurora+NC alone** at 2900 — pure NC on PR #300 base + Aurora, without EMA-Nesterov, n=8 to check NC's robust lift
   - **3rd: Aurora+EMA-Nesterov at train_steps=2810** — push fixed-step deeper with proven stack
   - **4th: Aurora+EMA-Nesterov+Circuit-Muon** — second compositional test
   - Lower priority: Aurora+EMA-Nesterov+TailPhaseReadout, Aurora+EMA-Nesterov+RI (dep frieren)

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

**In-flight observations (as of 02:50 UTC 2026-06-05):**
- **🥇 Fern Arm A T2 = 3.27903** NEW (above T0=3.27828 / T1=3.27760 → eroded n=3 mean to **3.27830** σ≈0.00072). T3 at ~17%. For n=4 to clear stat-sig: T3 ≤ 3.27708. For n=4 to beat PR #305: T3 ≤ 3.27765. **Tight margin now.**
- **Edward T2 corrected to 3.27838** (prior 3.28067 was mid-trial). n=3 mean 3.27936. T3 at 53%. Heading toward falsification.
- **Alphonse PR #2292 (H12 β2-pulse) screen at 37%**, healthy.
- **Tanjiro PR #2293 (H13 PMuon)** smoke test launched 02:49:45 UTC — pod picked up.
- **Nezuko PR #2290: 3 step-1 crashes** since 01:57 UTC; current restart at 02:46 progressing through step 50+. Advisor commented confirming LR=0.0375 + asked for crash diagnosis.
- **Askeladd PR #2291:** original screen still healthy at 53%; two student-initiated relaunches failed at step 1 (similar signature to nezuko).
- Frieren Arm A T1 — still running, needs_rebase pending (low priority since Arm A is control).
- Thorfinn Arm A NC — long road, no new terminals.

**Tail risk note:** Both nezuko (NC) and askeladd (Circuit-Muon) on PR #309 base show step-1 failures on relaunch. Possible common bug: PR #309's EMA-Nesterov + Aurora initialization may not survive an extra pre-NS/post-NS modification at trial init. Watching for clean SENPAI-RESULT vs another failure.

**Senpai-#1614 ingredient experiments now in flight (twin compositional tests):**
- alphonse PR #2292: β2-pulse on aux Adam, on PR #309 base
- tanjiro PR #2293: PMuon on Muon-routed params, on PR #309 base

Both isolate one Senpai-#1614 ingredient at a time. If either composes cleanly with PR #309's Aurora+EMA-Nesterov stack, the result is a strong sub-2900 candidate.

**Resolved this turn:**
- Closed tanjiro PR #2287 (n=4 mean 3.27901, margin 0.001975 < 0.004 — pulse real but +0.00057 worse than PR #300).
- Reassigned: PR #2293 (tanjiro, Senpai #1532/#1614 PMuon on PR #309 base, train_steps=2890, n=4) — companion to alphonse's β2-pulse.
- Closed alphonse PR #2281 (n=4 mean 3.279857, margin 0.000285 < 0.004 — falsified; bimodal T1/T2 plateau).
- Reassigned: PR #2292 (alphonse, Senpai #1532/#1614 β2-pulse on PR #309 base, train_steps=2890, n=4).

**Resolved prior turns:**
- Closed nezuko PR #2286 + askeladd PR #2282.
- Reassigned PR #2290 (nezuko, Aurora+EMA-Nesterov+NC), PR #2291 (askeladd, Aurora+EMA-Nesterov+Circuit-Muon).

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
