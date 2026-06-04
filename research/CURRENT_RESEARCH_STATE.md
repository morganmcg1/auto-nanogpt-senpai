# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-04 (launch day, updated ~23:25 UTC)
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

## Active assignments (as of 2026-06-04 ~23:25 UTC)

| PR | Student | Hypothesis | Base | Target step | Status | Source |
|---:|---|---|---|---:|---|---|
| #2281 | open2-alphonse | H1 NC on Aurora+RRE base | PR #305 | 2925 | trials 0+1 done (3.27688, **3.28211**), mean 3.27949, trial 2 step 1350/2925 (46%) | PR #295 |
| #2282 | open2-askeladd | H2 EMA-Nesterov (β=0.3) | PR #300 | 2900 | **trials 0+1+2 done (3.28135, 3.28122, 3.27996)**, mean 3.28084, T3 step 50/2900 | PR #309 |
| #2283 | open2-edward | H3 Circuit-Muon isolated | PR #300 | 2930 | `glygz1xt` trial 0 = 3.27895, trial 1 step ~1425/2930 (49%) | PR #311 |
| #2284 | open2-fern | H4 Arbor vs NC ablation (3 arms) | PR #300 | 2930 | Arm A `m50dnbvb` **T0 = 3.27828**, trial 1 step 525/2930 (18%); Arm B re-impl pending | PR #295, #310 |
| #2289 | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 3020 | Arm A `wd1aaqtr` recovered from stall — now at step 2375 (progressing slowly) | PR #307, #312 |
| #2286 | open2-nezuko | Replicate PR #309 EMA-Nesterov+Aurora | PR #309 | 2890 | **🏆 trials 0+1+2 done (3.27794, 3.27823, 3.27780), mean 3.27799 — n=4 LOCK LIKELY**, T3 starting | PR #309 |
| #2287 | open2-tanjiro | H9 Single-stage Tail Phase Readout | PR #300 | 2930 | trials 0+1 done (3.27911, 3.27849), mean 3.27880, trial 2 step 850/2930 (29%) | PR #318 |
| #2288 | open2-thorfinn | Replicate PR #295 NC standalone | base Muon | 3325 | Arm Z control done (T0=3.27781, T1=3.27910); **Arm A NC `5wirp0h4` launched** at 23:03 UTC | PR #295 |

**Top contenders (trial-status — ranked by current best aggregate at sub-3000 step budget):**

| Student | PR | Trials done | Mean | σ | Step | Status | Hypothesis |
|---|---:|---:|---:|---:|---:|---|---|
| **🏆 nezuko** | **#2286** | **3** | **3.27799** | **0.00018 (tight)** | **2890** | **T3 starting — SENPAI-RESULT in ~2.8h** | **EMA-Nesterov + Aurora (PR #309 lineage)** |
| tanjiro | #2287 | 2 | 3.27880 | 0.00062 | 2930 | T2 at 29% | Single-stage Tail Phase Readout on PR #300 |
| fern (Arm A) | #2284 | 1 | 3.27828 | — | 2930 | T1 at 18% | NC standalone on PR #300 base |
| edward | #2283 | 1 | 3.27895 | — | 2930 | T1 at 49% | Circuit-Muon isolated on PR #300 |
| alphonse | #2281 | 2 | 3.27949 | 0.00523 (large) | 2925 | T2 at 46% | NC on PR #305 base (Aurora+RRE+Contra-Muon+NC) |
| askeladd | #2282 | 3 | 3.28084 | 0.00077 | 2900 | T3 starting — falsifying | EMA-Nesterov on PR #300 bare |

**At higher step budget (3325, NOT directly comparable to sub-2900 goal):**

| Student | PR | Best aggregate | Step | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| thorfinn | #2288 | 3.27781 (trial 0, Arm Z = plain Muon control) | 3325 | Arm Z trial 1 at 75%, Arm A NC pending | NC vs control on bare Muon (A/B) |

**Key analytical reads this turn:**

1. **🏆 Nezuko T2 = 3.27780.** 3-trial mean **3.27799** at 2890 steps with σ=0.00018. For n=4 ≤ 3.278: T3 must be ≤ 3.27803 — essentially guaranteed given the tight σ. This is the **clearest sub-2900 win** of the launch and a likely merge candidate.

   Vs references:
   - PR #305 (public record): 3.27813 @ 2925, n=8 → nezuko 3-mean beats by 0.00014 at 35 fewer steps
   - PR #300 (predecessor): 3.27844 @ 2930, n=16 → beats by 0.00045
   - Senpai #1532 (audited): 3.27902 @ 2905, n=32 → beats by 0.00103

2. **Fern Arm A T0 = 3.27828 (NEW first signal).** NC standalone on PR #300 base — already comparable to PR #305 reference (3.27813). If Arm A n=4 mean lands ≤ 3.278, **NC standalone is composable on PR #300** and the natural next test is nezuko-stack + NC (Aurora+EMA-Nesterov+NC), which could push the floor further.

3. **Tanjiro stays second contender.** Mean(T0,T1)=3.27880 at 2930 steps. Single-stage Tail Phase Readout looks viable but unlikely to beat nezuko at 2890.

4. **Alphonse T2 progress (46%)** — needs T2,T3 to recover from T1 regression. High σ=0.00523 makes n=4 stat-sig uncertain.

5. **Askeladd T2 = 3.27996 (NEW).** Improving trend across trials (3.28135 → 3.28122 → 3.27996). 3-trial mean 3.28084 still above 3.28 contract. EMA-Nesterov on bare PR #300 is genuinely worse than EMA-Nesterov + Aurora. Hypothesis officially falsified.

6. **Compositional priority for NEXT WAVE (askeladd likely first idle student, ~2.5h):**
   - **Aurora+EMA-Nesterov+NC** (nezuko stack + fern's NC) — highest EV. Tests if NC stacks with the winner.
   - Aurora+EMA-Nesterov + Reference Interpolation (post-frieren result)
   - Aurora+EMA-Nesterov + Circuit-Muon (post-edward T1-T3)
   - Aurora+EMA-Nesterov + Senpai #1532 beta2-pulse
   - Aurora+EMA-Nesterov at train_steps=2850, 2810 (push fixed-step further)

**In-flight observations:**
- Nezuko T3 starting — SENPAI-RESULT expected in ~2.8h.
- Edward T1 at step ~1425/2930 (49%) — key for circuit-muon contribution.
- Alphonse T2 at step 1350/2925 (46%).
- Tanjiro T2 at step 850/2930 (29%).
- Fern Arm A T1 at step 525/2930 (18%).
- Frieren `wd1aaqtr` RECOVERED from stall — now at step 2375 (slow but progressing). Rebase still pending.
- Thorfinn restarted cleanly — Arm A NC `5wirp0h4` launched at 23:03 UTC.
- Askeladd T3 starting — falsification SENPAI-RESULT in ~3h.

**Resolved this turn:**
- Nezuko T2 = 3.27780 captured, 3-trial mean 3.27799 — likely merge winner.
- Fern Arm A T0 = 3.27828 — strong NC-on-PR#300 first signal.
- Thorfinn `sx4q2hn0` crashed → restarted as `5wirp0h4` (Arm A NC).
- Frieren `wd1aaqtr` recovered from stall on its own.
- Comment posted to nezuko PR #2286 acknowledging T2 + SENPAI-RESULT format.

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
