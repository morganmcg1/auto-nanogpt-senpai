# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~05:50 UTC (launch day +1)
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
| **#2294** | open2-edward | **H14 Senpai #1614 PMuon on PR #300 base NEW** | PR #300 | 2925 | just assigned (replaces closed #2283) | Senpai #1532/#1614 + PR #300 |
| **#2295** | **open2-fern** | **H15 Tail Reference Interpolation on PR #309 base (gamma ablation) NEW** | PR #309 | 2890 | just assigned (replaces closed #2284) | PR #307, #312 |
| #2289 | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930-3020 | Arm A control T0=3.27822; T1 in progress | PR #307, #312 |
| **#2290** | open2-nezuko | **H10 Aurora+EMA-Nesterov+NC NEW** | PR #309 | 2890 | just assigned (replaces closed #2286) | nezuko #2286 + fern #2284 |
| **#2293** | open2-tanjiro | **H13 Senpai #1614 PMuon on PR #309 base NEW** | PR #309 | 2890 | just assigned (replaces closed #2287) | Senpai #1532/#1614 + PR #309 |
| #2288 | open2-thorfinn | Replicate PR #295 NC standalone | base Muon | 3325 | Arm Z control n=2 mean 3.27846; **Arm A NC T0 = 3.27461 — striking**, T1 in progress | PR #295 |

**Closed this turn:** PR #2283 (edward — Circuit-Muon isolated on PR #300 base falsified, n=4 mean 3.27874). Prior: PR #2287 (tanjiro — single-stage TPR, 3.27901), PR #2281 (alphonse — NC+PR #305, 3.27986), PR #2286 (nezuko — PR #309 replication tail, 3.27838), PR #2282 (askeladd — EMA-Nesterov bare PR #300, 3.28075). **Closed this turn (new):** PR #2284 (fern — NC standalone on PR #300 base FALSIFIED n=4 mean 3.27875; Arbor-fixed screen also failed val=3.554 vs Arm Z 3.486; fan-out + sqrt(out_dim) double-applied). **Assigned PR #2295** (fern H15 Tail Ref Interp on PR #309 base, 3-arm gamma ablation).

**🚨 NC compositional verdict (FINAL with fern terminal):** NC (PR #295) is **NOT additive** on top of PR #300 stack. Alphonse (NC+PR #305 = Aurora+RRE+Contra-Muon+NC) FAILED at 3.27986; fern (NC+PR #300 = Aurora+Contra-Muon+NC) FAILED at 3.27875. NC standalone on bare Muon (thorfinn PR #2288) is the only remaining test — Arm A T0 was 3.27461 at 3325 steps but that's a different step budget. **Working rule: NC is redundant with row-aware refinements that already exist in Aurora/Contra-Muon.** NC may only deliver value on minimal Muon stacks. This refutes the earlier "NC + Contra-Muon DOES compose" hypothesis.

**Top contenders (trial-status — ranked by current best aggregate at sub-3000 step budget):**

| Student | PR | Trials done | Mean | σ | Step | Status | Hypothesis |
|---|---:|---:|---:|---:|---:|---|---|
| **— NO MERGE WINNER YET (PR #305 still rank-1 at 3.27813)** | | | | | | | |
| **fern (Arm A) — FALSIFIED, closing** | #2284 | **4** | **3.27875** | **0.00104** | 2930 | T0=3.27828, T1=3.27760, T2=3.27903, **T3=3.28007** tail; margin 0.00250 fails; +0.00031 worse than PR #300 ref | NC standalone on PR #300 base |
| **edward — FALSIFIED + CLOSED** | #2283 | 4 | **3.27874** | **0.00055** | 2930 | T0=3.27895, T1=3.27822, T2=3.27838, T3=3.27942; V/O telemetry perfect | Circuit-Muon isolated on PR #300 (no EMA-Nesterov) |
| frieren (Arm A) | #2289 | 1 | 3.27822 | — | 2930 | T2 ~47% in `wd1aaqtr`, run name suggests control replication progress | PR #300 vanilla (Arm A=control, no RI) |
| **nezuko #2286 — CLOSED, FAILS STAT-SIG** | #2286 | 4 | **3.27838** | **0.00080 (T3 tail)** | 2890 | T3=3.27956 tail event | EMA-Nesterov + Aurora (PR #309 lineage) |
| **tanjiro #2287 — FALSIFIED + CLOSED** | #2287 | 4 | **3.27901** | **0.00051** | 2930 | T0=3.27911, T1=3.27849, T2=3.27968, T3=3.27877; pulse real but post-pulse slow | Single-stage Tail Phase Readout on PR #300 |
| **askeladd #2282 — FALSIFIED + CLOSED** | #2282 | 4 | **3.28075** | **0.00059** | 2900 | T3=3.28046 done | EMA-Nesterov on PR #300 bare |
| **alphonse #2281 — FALSIFIED + CLOSED** | #2281 | 4 | **3.27986** | **0.00242** | 2925 | T0=3.27688, T1=3.28211, T2=3.28238, T3=3.27806; bimodal | NC on PR #305 base (Aurora+RRE+Contra-Muon+NC) |

**At higher step budget (3325, NOT directly comparable to sub-2900 goal):**

| Student | PR | Arm Z (control) | Arm A (NC) | Status | Hypothesis |
|---|---:|---:|---:|---|---|
| thorfinn | #2288 | n=2 mean 3.27846 (T0=3.27781, T1=3.27910) | **T0 = 3.27461 NEW — striking** | Arm A T1 starting | NC vs control on bare Muon (A/B) |

**Key analytical reads this turn (04:40 UTC):**

1. **🔴 Fern Arm A FALSIFIED at terminal — NC standalone on PR #300 base does NOT win.** Per-trial: T0=3.27828, T1=3.27760, T2=3.27903, **T3=3.28007 tail event** (T3 is ~8σ above prior trials). n=4 mean = 3.27875, margin 0.00250 < 0.004; +0.00031 worse than PR #300 reference (3.27844, n=16). The PR #305 rank-1 baseline (3.27813) is still the merge target. **No current merge candidate from the first wave.** Closing fern after terminal SENPAI-RESULT.

2. **NC compositional verdict crystallizes.** Two PR #300-stack tests now both falsified (fern NC standalone + alphonse NC+RRE). NC is **not** additive on top of Aurora-bearing stacks. Remaining open question is thorfinn PR #2288 (NC on bare Muon at 3325 steps) — its T0=3.27461 single result is striking but lives at a different step budget and needs T1-T3 to confirm.

3. **All hopes for sub-2900 SOTA now rest on the Senpai-#1532/#1614 ingredient experiments + the Aurora+EMA-Nesterov composition hypothesis:**
   - **nezuko PR #2290** Aurora+EMA-Nesterov+NC on PR #309 base — step 1600/2930 (~55%) in confirm `7frhd6u6`. If NC fails alongside Aurora+EMA-Nesterov too, NC is fully ruled out.
   - **alphonse PR #2292** Senpai β2-pulse on PR #309 base — step 1300/2930 (~44%) in confirm `1tegunyu`.
   - **tanjiro PR #2293** Senpai PMuon on PR #309 base — step 450/2930 (~15%) in relaunched run `7eimwktx` (past prior crash patterns).
   - **askeladd PR #2291** Aurora+EMA-Nesterov+Circuit-Muon on PR #309 base — step 600/2930 (~20%) in `ar3yhz6f`.
   - **edward PR #2294** Senpai PMuon on PR #300 base — debug screen at step 75/1500 in `78gqxnp3` (W&B group flagged for n=4 confirm correction).
   - **frieren PR #2289** RI on PR #300 base — T2 of `wd1aaqtr` at step 1377/2930 (~47%). RI signal is the only remaining first-wave open mechanism.

4. **Compositional landscape after fern terminal:**
   - **NC on PR #300 stack**: FAILED (fern Arm A)
   - **NC + RRE + Contra-Muon**: FAILED (alphonse #2281)
   - **NC + Contra-Muon (no RRE)**: FAILED (fern Arm A — refutes earlier hypothesis)
   - **NC on bare Muon**: open (thorfinn T0 striking, T1-T3 pending)
   - **EMA-Nesterov + Aurora**: replicable mean ~3.27800 but tail-prone (nezuko #2286)
   - **EMA-Nesterov bare**: FAILED (askeladd #2282)
   - **Circuit-Muon isolated on PR #300**: FAILED (edward #2283)
   - **Tail Phase Readout single-stage**: FAILED (tanjiro #2287)
   - **β2-pulse, PMuon, RI, Aurora+EMA-Nesterov composites**: all pending in current confirms

**Refined NEXT WAVE priorities (after fern terminal):**
   - **TOP if Aurora+EMA-Nesterov+NC (nezuko #2290) wins:** harvest the composition + assign to push train_steps lower
   - **TOP if Senpai β2-pulse on PR #309 (alphonse #2292) wins:** harvest + stack β2-pulse on Aurora+EMA-Nesterov+NC if nezuko also wins
   - **TOP if Senpai PMuon (tanjiro #2293 or edward #2294) wins:** that's the singular Senpai ingredient with biggest expected lift
   - **Backup 1:** Senpai LR/EMA stack (last #1614 ingredient not yet tested) on PR #309 base
   - **Backup 2:** Aurora + RI composition if frieren shows lift on PR #300
   - **Backup 3:** push Aurora+EMA-Nesterov to train_steps=2810 with proven stack
   - **Backup 4:** outer-Nesterov wrapper (PR #277 MuLoCo) or Polar Express (PR #254) as architectural fallback

**In-flight observations (as of 2026-06-05 05:50 UTC):**

**🔴 Two PR #309-base + extra-ingredient terminals landed — BOTH WORSE than PR #309 base alone (~3.27800):**
- **Alphonse PR #2292 T0 = 3.27971** (Senpai β2-pulse). +0.00171 worse than PR #309 base. T1 at step 500/2890 (17%).
- **Nezuko PR #2290 T0 = 3.27938** (Aurora+EMA-Nesterov+NC). +0.00138 worse than PR #309 base. T1 at step 875/2890 (30%).

Both refute their hypotheses — adding β2-pulse OR NC on top of Aurora+EMA-Nesterov is net-negative on T0. n=4 means likely 3.279–3.280 range (assumes T1-T3 similar to T0). Compositional read: **Aurora+EMA-Nesterov base is already saturated**; both pre-NS NC and aux-Adam β2-pulse interfere rather than compose.

**🥇 THORFINN NC bare-Muon at 3325 steps STRONG:** T0=3.27461, T1=3.27582, T2=3.27628 all complete (n=3 mean **3.27557**, margin 0.00767). **T3 at step 2625/3325 (~79%), ETA ~06:08 UTC.** Not directly sub-2900 mergeable (wrong step budget) but a foundational finding: NC's lift requires absence of upstream row-aware refinement. Reframe NC: redundant with Aurora; positive on bare Muon.

**🥇 New fleet leaders by T0 alone:**
1. **Frieren T0 = 3.27822** (PR #300 + nothing; control replication) — matches PR #300 ref well
2. Nezuko T0 = 3.27938 (PR #309 + NC) — worse than PR #309 base alone
3. Alphonse T0 = 3.27971 (PR #309 + β2-pulse) — worse still
4. Frieren T1 = 3.28063 (above contract ceiling!) — n=4 forming a 3.279-3.280 range

**Fern PR #2295 (NEW):** H15 Tail Reference Interpolation on PR #309 base assigned 05:30 UTC. Pod pickup pending.

**Tanjiro PR #2293:** confirm `7eimwktx` T0 at step 1550/2890 (~54%), val/loss=3.539. PMuon (PR #64 bilateral whitening) on PR #309 base. No further crashes.

**Edward PR #2294:** n=4 confirm `i97y7os1` T0 at step 375/2925 (~13%). PMuon on PR #300 base. ETA ~18:00 UTC.

**Askeladd PR #2291:** confirm `ar3yhz6f` T0 at step 2725/2890 (~94%), val/loss=3.293 — T0 terminal IMMINENT (~13 min). Aurora+EMA-Nesterov+Circuit-Muon on PR #309.

**Frieren PR #2289:** `wd1aaqtr` Arm A T2 at step 2627/2930 (~90%), val/loss=3.280. T0=3.27822, T1=3.28063 (tail). Arm A terminal soon, Arm B (RI) starts after.

**🚨 PR #309-base + Muon-side mechanism step-1 crash pattern (3-of-3):**
- nezuko PR #2290 (NC pre-NS): 3 step-1 crashes
- askeladd PR #2291 (Circuit-Muon V↔O scaling): 2 step-1 crashes on relaunch
- tanjiro PR #2293 (PMuon preconditioning): smoke test crashed at step 1 (val/loss=10.82583)
- **Alphonse PR #2292 (β2-pulse on AUX ADAM) is healthy at 75%** — confirms the bug is Muon-side only

Posted diagnostic guidance comment on PR #2293 pointing at three suspects: (1) EMA-Nesterov momentum buffer init between trials, (2) Aurora row-balanced polar init interaction, (3) PMuon preconditioner init at step 1. Students are debugging in parallel; nezuko and askeladd current restarts are progressing past step 50-625 (past the prior crash points).

**Strategic implication:** PR #309 base appears mechanically fragile when extended with any pre-NS or post-NS Muon-side mechanism. This is novel information about PR #309's robustness. If the pattern persists, future high-EV experiments should compose Senpai #1532/#1614 ingredients on **bare PR #300** rather than PR #309, since PR #300 has shown clean composition with NC (fern Arm A T0/T1/T2 all converged).

**Senpai-#1532/#1614 ingredient experiments now in flight (matrix on two bases):**
- alphonse PR #2292: β2-pulse on aux Adam, on **PR #309 base** (screen done at 3.4947, confirm pending)
- tanjiro PR #2293: PMuon on Muon-routed params, on **PR #309 base** (relaunch screen healthy at step 275)
- edward PR #2294: PMuon on Muon-routed params, on **PR #300 base** (just assigned) — companion to tanjiro, hedges against PR #309-base fragility

This matrix gives us: (1) β2-pulse robustness on PR #309 base, (2) PMuon on PR #309 base vs PR #300 base — directly tells us if PMuon mechanism is base-dependent or base-independent. If tanjiro's PMuon+PR #309 cannot survive init crashes but edward's PMuon+PR #300 runs cleanly with similar val/loss as fern Arm A (NC+PR #300, current leader 3.27830), we have strong evidence PMuon is base-independent and the PR #309-base init crash is mechanistic-fragility not PMuon-fragility.

**Resolved this turn:**
- Closed edward PR #2283 (n=4 mean 3.27874, margin 0.002515 < 0.004 — Circuit-Muon mechanism mechanically correct but PR #300 already regulates attention step-sizes; mechanism has no headroom).
- Reassigned: PR #2294 (edward, Senpai #1532/#1614 PMuon on PR #300 base, train_steps=2925, n=4) — companion to tanjiro PR #2293 (PMuon on PR #309 base).
- Closed tanjiro PR #2287, reassigned to PR #2293 (PMuon on PR #309 base).
- Closed alphonse PR #2281, reassigned to PR #2292 (β2-pulse on PR #309 base).

**Resolved prior turns:**
- Closed nezuko PR #2286 + askeladd PR #2282.
- Reassigned PR #2290 (nezuko, Aurora+EMA-Nesterov+NC), PR #2291 (askeladd, Aurora+EMA-Nesterov+Circuit-Muon).

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
