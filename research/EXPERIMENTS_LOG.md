# SENPAI Research Results — Auto-nanoGPT Open SOTA v2 Launch

Tag: `auto-nanogpt-open-sota-v2-20260604`. Branch: same. Target:
`modded-nanogpt` Track 3 (FineWeb val/loss ≤ 3.28 in minimum optimizer steps
under stat-sig contract).

Each entry below records the date, PR number, hypothesis, key results table,
and analysis. Most recent first.

---

## 2026-06-05 11:10 — PR #2293: H13 Senpai PMuon on PR #309 base (FALSIFIED)

- Branch: `open2-tanjiro/h13-senpai-pmuon-pr309-base`
- Hypothesis: Does Senpai PR #64 bilateral covariance whitening (PMuon: L^{-γ} m R^{-γ}, γ=0.4, β_cov=0.95) on the Nesterov-blended momentum before NS5 improve val/loss on PR #309 base (Aurora+EMA-Nesterov)?
- Status: **FALSIFIED (n=2 abort)** — n=2 mean 3.28053, best-case n=4=3.27926, above PR #305.

### Results

| Trial | val/loss @ 2890 | Notes |
|-------|-----------------|-------|
| T0 | 3.28237 | Healthy convergence; high relative to base |
| T1 | 3.27868 | Healthy convergence; partial recovery |
| T2 | — | Aborted (advisor-approved) |
| T3 | — | Aborted |
| n=2 mean | **3.28053** | |

- W&B run: `7eimwktx`
- Stat-sig: best-case n=4 mean = 3.27926 (well above PR #305 3.27813)

### Analysis

PMuon's Frobenius rescale (`||whitened|| / ||raw|| ≡ 1.0 by construction`) forces magnitude-neutrality while applying 800–14000× bilateral directional reweighting. The directional interference with EMA-Nesterov+Aurora produces high seed variance (σ ≈ 0.0018 vs PR #309 base σ ≈ 0.00018). PMuon does not transfer from its Senpai #1614 context (different LR, aux-Adam, no Aurora) to PR #309 base without the compensating mechanisms. Stack-dependent composition failure.

---

## 2026-06-05 11:05 — PR #2291: H11 Circuit-Muon on PR #309 base (FALSIFIED)

- Branch: `open2-askeladd/aurora-ema-nesterov-circuit-muon-pr309-base`
- Hypothesis: Does KellerJordan PR #311 Circuit-Muon (V/O attention cross-scaling) improve val/loss when composed with PR #309 base (Aurora+EMA-Nesterov)?
- Status: **FALSIFIED** — n=4 mean 3.27844, above PR #305 (3.27813).

### Results

| Trial | val/loss @ 2890 | Notes |
|-------|-----------------|-------|
| T0 | 3.27958 | Tail event (PR #309 base bimodal pattern) |
| T1 | **3.27726** | Best individual trial this round |
| T2 | 3.27846 | |
| T3 | 3.27846 | |
| n=4 mean | **3.27844** | |

- W&B run: `ar3yhz6f`
- Stat-sig: (3.28 - 3.27844) × √4 = 0.00312 < 0.004

### Analysis

Circuit-Muon on PR #309 adds bimodal structure on top of the existing PR #309 tail-event distribution. T0 is the tail event (3.27958); T1-T3 average 3.27806 (slightly below PR #309 base mean of 3.27800). On non-tail trials Circuit-Muon shows marginal lift; T1=3.27726 is the best single trial this round. The tail event (not the mechanism) kills the mean. Mechanism not competitive as standalone; future composition with RI or Arbor (tail-suppression) may be worth revisiting.

---

## 2026-06-05 10:59 — PR #2292: H12 β2-pulse on PR #309 base (FALSIFIED)

- Branch: `open2-alphonse/h12-senpai-beta2pulse-pr309-base`
- Hypothesis: Does Senpai #1532 aux-Adam β2 pulse (0.95→0.99 at step 970) improve val/loss on PR #309 base (Aurora+EMA-Nesterov)?
- Status: **FALSIFIED** — n=4 mean 3.27822, above PR #305 (3.27813).

### Results

| Trial | val/loss @ 2890 | Notes |
|-------|-----------------|-------|
| T0 | 3.27971 | Tail event |
| T1 | 3.27775 | |
| T2 | 3.27766 | |
| T3 | 3.27775 | |
| n=4 mean | **3.27822** | |

- W&B run: `1tegunyu`
- Stat-sig: (3.28 - 3.27822) × √4 = 0.00356 < 0.004

### Analysis

T0=3.27971 tail event drives mean above PR #305. T1/T2/T3 mean = 3.27772 (would beat PR #305 at n=3 if stat-sig contract could be cleared at n=3). Pattern confirms: PR #309 base bimodal distribution is on the Muon path; aux-Adam-side interventions cannot suppress it. β2-pulse is "additive on weak base, neutral on strong base."

---

## 2026-06-05 06:10 — PR #2288: Replicate PR #295 — Normalized Correction on base Muon (CONFIRMED)

- Branch: `open2-thorfinn/pr295-nc-base-muon`
- Hypothesis: Does PR #295's Normalized Correction (divide Muon gradient by `sqrt(row_norm × col_norm)` before NS orthogonalization) improve val/loss on a vanilla Muon baseline at 3325 steps? A/B design: Arm A (NC) vs Arm Z (control, n=2 stopped early to save GPU).
- Status: **Closed — mechanism confirmed on bare Muon, but not sub-2900 eligible. Student reassigned H16.**

### Results

| Trial | Arm A (NC) val/loss @ 3325 | Arm Z (control) val/loss @ 3325 |
|---:|---:|---:|
| 0 | **3.27461** | 3.27781 |
| 1 | **3.27582** | 3.27910 |
| 2 | **3.27628** | *(stopped @ n=2 by advisor)* |
| 3 | **3.27477** | — |
| **n=4 mean** | **3.27537** | **3.27846 (n=2)** |
| σ | 0.00080 | — |

- W&B run: `5wirp0h4` (Arm A); `sx4q2hn0` (Arm Z)
- Margin: `(3.28 − 3.27537) × √4 = 0.00926` ≫ 0.004 stat-sig contract
- NC delta vs control: −0.00309 (favorable; ~6× the minimum detectable signal)
- All 4 NC trials individually beat 3.278 contract ceiling

### Analysis

- **NC is genuinely additive on bare Muon** — T0=3.27461 was not a tail event; T1-T3 confirm a tight distribution (range [3.27461, 3.27628]). This is the strongest per-trial result observed on any student this round.
- **NC is NOT composable with Aurora-bearing stacks:** Falsified on PR #300 (fern PR #2284, n=4 mean 3.27875) and PR #305 (alphonse PR #2281, n=4 mean 3.27986). The defining compositional rule is now clear: **NC competes for the same row-aware spectrum control degree of freedom as Aurora's row-balanced polar refinement. Whichever applies first leaves nothing for the other.**
- **Why NOT merging:** train_steps=3325 is outside the sub-2900 mission budget. Plain Muon + NC at 2925 steps is unlikely to beat PR #305 (Aurora + RRE, 3.27813 @ 2925). The ~0.003 NC lift at 3325 would need to overcome Aurora's structural advantage at the lower step budget.
- **Carry-over for future work:** (1) On bare-Muon stacks NC delivers ~0.003 lift; (2) NC + EMA-Nesterov WITHOUT Aurora could be a viable stack (not yet tested); (3) NC + MuLoCo / Polar Express as bare-Muon enhancement candidates.
- Student's decision to stop Arm Z at n=2 (saving ~3.5h GPU time) and launch Arm A at n=4 immediately was excellent experimental design.

### Suggested follow-ups

- **NC + EMA-Nesterov on bare PR #300 base** — remove Aurora, add NC + EMA-Nesterov, test whether they compose (different mechanism classes — pre-NS spectrum vs. gradient look-ahead). Step budget: 2900.
- **NC as sub-2900 candidate only if paired with a mechanism that doesn't use Aurora** — e.g. NC + Senpai β2-pulse (aux Adam only, no Muon-side conflict).

---

## 2026-06-05 04:40 — PR #2284: H4 Arbor vs NC ablation on PR #300 base (Arm A NC terminal)

- Branch: `open2-fern/arbor-vs-nc-pr300-base`
- Hypothesis: Three-arm ablation to settle the "pre-Newton-Schulz conditioning slot" question on the PR #300 base — Arm A = PR #295 Normalized Correction (NC) inserted before `X = X / X.norm()`; Arm B = PR #310 Arbor Muon (2-iter row/col equilibration on `mlp.fc`/`mlp.proj`); Arm Z = control replicating PR #300 reference. n=4 @ train_steps=2930.
- Status: **Arm A terminal known; PR to be closed after student SENPAI-RESULT.**

### Results (Arm A only — Arms B and Z TBD)

| Trial | val/loss @ 2930 |
|---:|---:|
| 0 | 3.27828 |
| 1 | 3.27760 |
| 2 | 3.27903 |
| 3 | **3.28007** ← tail event |
| **n=4 mean** | **3.27875** |
| σ | 0.00104 |

- W&B run: `m50dnbvb` (group `open2-fern/arbor-vs-nc-pr300-base`)
- Margin: `(3.28 − 3.27875) × √4 = +0.00250` (contract requires ≥ +0.004 → FAILS)
- Vs PR #300 (3.27844, n=16): worse by +0.00031 → falsification rule fires
- Vs PR #305 (3.27813, n=8): worse by +0.00062
- Arm B (Arbor) original implementation diverged at debug-screen step 758 with loss gap ~0.54 vs control. Student identified three pseudo-code discrepancies vs actual PR #310 (alternating + relative-to-mean clamp + `sqrt(out_dim)` post-NS pin) and was authorized to re-implement; Arm B re-screen may or may not have been launched after Arm A confirm.

### Analysis

- **NC standalone on PR #300 stack does NOT compose.** Combined with alphonse PR #2281 (NC on PR #305 stack, n=4 mean 3.27986) the result is consistent across two NC-bearing compositions on Aurora bases. NC is **redundant** with PR #300's existing row-aware refinement (Aurora row-balanced polar on `mlp.proj` + Contra-Muon ramp).
- **Refutes earlier "NC + Contra-Muon DOES compose" rule of thumb** — at n=2 fern Arm A appeared to lead at 3.27794, but n=3 erosion (T2=3.27903) and n=4 tail (T3=3.28007) reveal high seed variance and no real lift over PR #300 reference. Single trials are insufficient evidence for compositional rules; must wait for n=4.
- **σ=0.00104 is ~2× the σ of other PR #300-base n=4 runs** (edward 0.00055, tanjiro #2287 0.00051) — NC may introduce additional seed sensitivity by amplifying gradient-norm fluctuations in early layers.
- **Implication for next wave:** NC is fully ruled out on Aurora-bearing stacks. NC's potential value is limited to bare-Muon configurations (currently being tested by thorfinn PR #2288 at train_steps=3325, T1-T3 pending).
- **Strategic implication:** With first-wave NC, EMA-Nesterov-bare, Circuit-Muon-isolated, and Tail Phase Readout all falsified, sub-2900 SOTA now depends on (a) Senpai #1532/#1614 ingredients (β2-pulse, PMuon) currently in flight (alphonse/tanjiro/edward), (b) Aurora+EMA-Nesterov composites (nezuko+askeladd in flight), or (c) genuinely new architectural levers from the next research wave (Polar Express, MuLoCo, KL-SOAP).

### Suggested follow-ups

- **Close PR #2284** upon student terminal SENPAI-RESULT.
- **Reassign fern** to the next-highest-EV Senpai ingredient: candidate is **Senpai LR/EMA stack on PR #309 base** (the third and last untested Senpai-#1614 ingredient) or **Polar Express NS variant (PR #254)** on PR #300/PR #309 base as a NS-iteration replacement experiment.
- **Update compositional rules file** (NEW): NC compatibility with row-aware refinement = NEGATIVE; NC may only matter on bare-Muon configurations.

---

## 2026-06-05 04:00 — PR #2283: H3 Circuit-Muon isolated on PR #300 base

- Branch: `open2-edward/circuit-muon-pr300-base`
- Hypothesis: Test PR #311's Circuit-Muon mechanism (per-head V↔O cross-scaling + per-head trace-only gauge rebalance) standalone on PR #300 base. Determine whether the mechanism contributes value independent of EMA-Nesterov (the other ingredient in PR #311's claimed sub-2900 result). n=4 @ train_steps=2930.
- Status: **Closed — falsification confirmed at student's own falsification rule (not merged).**

### Results

| Trial | val/loss @ 2930 |
|---:|---:|
| 0 | 3.278952 |
| 1 | 3.278220 |
| 2 | 3.278378 |
| 3 | 3.279420 |
| **n=4 mean** | **3.278742** |
| σ | 0.000550 |

- W&B run: `glygz1xt` (group `open2-edward/circuit-muon-pr300-base`)
- Margin: `(3.28 − 3.278742) × √4 = +0.002515` (contract requires ≥ +0.004 → FAILS)
- Vs PR #300 (3.27844, n=16): worse by +0.000299 → falsification rule fires
- Vs PR #305 (3.27813, n=8): worse by +0.000614
- All 4 trials reached 3.28 target at step 2925

### Analysis

- **Mechanism is mechanically correct.** V/O per-head Frobenius ratios stayed within 1% throughout all 4 trials (block mean 1.009-1.024 across training), per-head std stays sub-1%. The implementation is sound; this is a real null signal about the mechanism on this base.
- **Structural finding about PR #300's effective-step-size regime:** PR #300's existing stack (Aurora + Contra-Muon + radial brake + Muon momentum warmup/cooldown) already regulates attention layer step sizes such that V/O ratios are naturally near 1.0. Circuit-Muon's per-head balance has nothing to do because the imbalance it's designed to correct is already approximately zero.
- **Compositional implication:** PR #311's claimed sub-2900 lift must come predominantly from EMA-Nesterov (the other ingredient). Circuit-Muon is conditional on the EMA-Nesterov gradient evaluation point, OR it requires a base where Aurora is applied to `attn.v` and `attn.proj` (not just `mlp.proj` as in PR #300).
- σ=0.55e-3 across 4 seeds is tight — n=4 sufficient to conclude the mean isn't beating PR #300. No outlier; non-improvement is a property of the mechanism on this base, not seed variance.
- Step time stable at ~2018 ms (same as PR #300 base) — V↔O coupling adds no wall-clock cost.

### Suggested follow-ups (student-flagged)

- Circuit-Muon + EMA-Nesterov on PR #300 base — askeladd PR #2291 is testing exact composition on PR #309 base
- Circuit-Muon + Aurora on attn.v/proj — would give Circuit-Muon something to do
- Drop Circuit-Muon from canon if EMA-Nesterov standalone wins

Advisor decision: close. Reassign student to **H14 Senpai #1532/#1614 PMuon on PR #300 base** (PR #2294) — companion to tanjiro PR #2293 (PMuon on PR #309 base).

---

## 2026-06-05 02:30 — PR #2287: H9 Single-stage Tail Phase Readout on PR #300 base

- Branch: `open2-tanjiro/tail-phase-readout-pr300-base`
- Hypothesis: Test the single-stage variant of PR #318's Tail Phase Readout mechanism (one γ_1 = −0.07 pulse at step 2750 in PR #300-base trajectory) on a clean PR #300 base. n=4 @ train_steps=2930.
- Status: **Closed — falsification at student's own falsification rule (not merged).**

### Results

| Trial | val/loss @ 2930 | first_step_to_target |
|---:|---:|---:|
| 0 | 3.27911 | 2920 |
| 1 | 3.27849 | 2910 |
| 2 | 3.27968 | 2925 |
| 3 | 3.27877 | 2920 |
| **n=4 mean** | **3.2790125** | **2918.75** |
| σ | 5.12e-4 | — |

- W&B run: `8bd1iezl` (group `open2-tanjiro/tail-phase-readout-pr300-base`)
- Margin: `(3.28 − 3.2790125) × √4 = +0.001975` (contract requires ≥ +0.004 → FAILS)
- Vs PR #300 (3.27844, n=16): worse by +0.000569 → student's falsification rule fires
- Vs PR #305 (3.27813, n=8): worse by +0.000885

### Analysis

- **Pulse mechanism IS real.** Mean 5-step Δ at pulse step 2750 = **−0.00162** vs natural −0.00060 — a ~2.7× immediate acceleration. Consistent across all 4 seeds (T0=−0.00155, T1=−0.00164, T2=−0.00168, T3=−0.00159). Telemetry confirms the N-subspace norm moves by ~0.022% absolute (max per-tensor relative move 0.44%, always an attn.q.weight).
- **But the gain doesn't persist.** Post-pulse 5-step decay rate slows to ~−0.000417 (vs natural −0.00061 pre-pulse) — ~30% slowdown. By step 2930 the cumulative effect erodes to net +0.0006 worse than PR #300 baseline.
- **Interpretation:** The pulse direction is slightly misaligned with the natural optimizer trajectory. Free immediate benefit; cost in subsequent momentum.
- **Compositional read:** Single-stage TPR on PR #300 base does NOT compose to a sub-2900 win. The chained 3-stage version in #318 may compose because the final stage absorbs residual misalignment — but replicating that is a separate, larger PR.
- Per-seed val/loss trace shows tight σ=5.12e-4 — good seed stability, just centered at the wrong mean.

### Suggested follow-ups (student-flagged)

- γ_1 sensitivity sweep — modest EV
- Late-stage γ_3 alone — likely similar misalignment in late phase
- TPR + PR #305 base — likely subject to RRE interference (cf. alphonse #2281 NC + RRE FAIL)
- Replicate the chained 3-stage version from PR #318 — would be a larger PR

Advisor decision: close. Reassign student to higher-EV Senpai-#1614 ingredient line (H13 PMuon, PR #2293).

---

## 2026-06-05 02:10 — PR #2281: H1 Normalized Correction on PR #305 base (Aurora + RRE + Contra-Muon)

- Branch: `open2-alphonse/normalized-correction-pr305-base`
- Hypothesis: Add NC (PR #295 row/col pre-NS normalization) on top of the official PR #305 stack (Aurora row-balanced polar + RRE late-step extrapolation + Contra-Muon ramp to 2500). n=4 @ train_steps=2925. Test whether NC composes with the merged sub-2925 baseline.
- Status: **Closed — clear falsification (not merged).**

### Results

| Trial | best_val_loss @ 2925 | first_step_to_target |
|---:|---:|---:|
| 0 | 3.27688 | 2880 |
| 1 | 3.28211 | -1 (never) |
| 2 | 3.28238 | -1 (never) |
| 3 | 3.27806 | 2895 |
| **n=4 mean** | **3.279857** | — |
| σ | 0.002424 | — |

- W&B run: `oeftnbeo` (group `open2-alphonse/nc-pr305-base`)
- Margin: `(3.28 − 3.279857) × √4 = +0.000285` (contract requires ≥ +0.004 → FAIL by −0.003715)
- Vs PR #305 (3.27813 @ 2925, n=16): worse by +0.00173 on raw mean
- Vs fern Arm A NC + PR #300 base (n=2 mean 3.27794, no RRE): worse by +0.00192

### Analysis

- **Bimodal distribution:** T0 (3.27688) and T3 (3.27806) cleared the 3.28 target; T1 (3.28211) and T2 (3.28238) plateau just above ceiling. σ=0.00242 is 13× larger than nezuko #2286's T0-T2 σ=0.00018, indicating discrete seed-to-seed basin selection rather than smooth noise.
- **Discriminating composition variable: RRE.** Both alphonse (NC + Aurora + RRE + Contra-Muon, FAILS) and fern Arm A (NC + Aurora + Contra-Muon, no RRE, n=2 mean 3.27794 LEADS) include Contra-Muon, but only alphonse includes RRE. The hypothesis that NC + Contra-Muon interfere is rejected; instead **NC + RRE interfere**: RRE's late-step weight extrapolation operates on accumulated updates that NC has already row/col-normalized, cancelling NC's directional adjustment.
- **Implication for the compositional rule:** "Mechanisms that touch the same NS-norm regime do NOT stack" still holds, but the actual conflict is at the *post-NS update aggregation* level (RRE re-extrapolates from NC-normalized updates), not the pre-NS adjustment level (Contra-Muon).
- Student noted training trajectory was healthy across all trials — no NaN, no divergence; this is a worse-conditioned optimum, not a numerical failure.

### Per-trial observations

- T1/T2 plateau at 3.282 — flagged for potential follow-up (seed-sensitivity ablation), low priority vs the RRE-vs-NC composition direction.
- T0 outlier-low (3.27688) misled early read; n=1 sampling deceived the contract.

---

## 2026-06-05 01:25 — PR #2286: Replicate PR #309 EMA-Nesterov + Aurora at 2890 steps

- Branch: `open2-nezuko/replicate-pr309-ema-aurora`
- Hypothesis: Replicate KellerJordan PR #309 — EMA-Nesterov (β=0.3) layered on Aurora row-balanced polar (#300 base) — at fixed train_steps=2890, n=4 trials. Determine whether this composition clears the sub-2900 stat-sig contract on Senpai infra.
- Status: **Closed — falsification at contract margin (not merged).**

### Results

| Trial | val/loss @ 2890 |
|---:|---:|
| 0 | 3.27794 |
| 1 | 3.27823 |
| 2 | 3.27780 |
| 3 | 3.27956 |
| **n=4 mean** | **3.27839** |
| σ | 0.00080 |

- W&B run: `pp6kui6d` (group `open2-nezuko/replicate-pr309-ema-aurora`)
- Margin: `(3.28 − 3.27839) × √4 = +0.00322` (contract requires ≥ +0.004 → FAIL by −0.00078)
- Vs PR #305 (3.27813 @ 2925): worse by +0.00026 on raw mean
- Vs Senpai #1532 (3.27902 @ 2905): better by 0.00063

### Analysis

- T0/T1/T2 mean = 3.27799 (σ=0.00018) — extremely tight, consistent with PR #309 claim.
- T3 = 3.27956 is a ~9σ tail event relative to T0-T2 distribution. The seed-to-seed distribution has a fat right tail under EMA-Nesterov+Aurora.
- PR #309's claim of sub-2890 was likely from a luckier n=16 sample averaging out the tail.
- The mechanism IS real — three of four seeds beat all references — but the stat-sig contract demands robustness across all seeds, which it does not have at n=4.
- Telemetry confirms EMA-Nesterov fired cleanly at both β-ramp boundaries (no spikes at steps 300/1950).
- Decision: extending to n=8 was an option (~50% probable to clear) but reassigning to compositional hypothesis Aurora+EMA-Nesterov+NC has higher EV.

---

## 2026-06-05 01:25 — PR #2282: H2 EMA-Nesterov (β=0.3) on bare PR #300 base

- Branch: `open2-askeladd/ema-nesterov-pr300-base`
- Hypothesis: Does EMA-Nesterov (PR #309's mechanism) provide standalone lift when added to bare PR #300 base (without PR #309's other changes)? n=4 at train_steps=2900.
- Status: **Closed — clear falsification (not merged).**

### Results

| Trial | val/loss @ 2900 |
|---:|---:|
| 0 | 3.28135 |
| 1 | 3.28122 |
| 2 | 3.27996 |
| 3 | 3.28046 |
| **n=4 mean** | **3.28075** |
| σ | 0.00066 |

- W&B run: `maf69yse` (group `pr2282-ema-nesterov`)
- Margin: `(3.28 − 3.28075) × √4 = −0.00150` → BIG FAIL (well above 3.28 ceiling)
- Vs PR #300 (3.27844 @ 2930): worse by +0.00231 at FEWER steps

### Analysis

- EMA-Nesterov on bare PR #300 (Aurora row-balanced polar + Contra-Muon ramp + Muon warmup/cooldown) does NOT compose. Mean is above 3.28 — far worse than PR #300 vanilla.
- Combined with PR #2286 (nezuko): EMA-Nesterov's value in PR #309 comes from its **interaction with Aurora alone**, not from raw EMA-Nesterov + #300's full stack. PR #309 strips some of #300's components (Contra-Muon details, etc.) before adding EMA-Nesterov.
- Implication: Contra-Muon and EMA-Nesterov likely interfere (similar to NC + Contra-Muon interference observed in alphonse PR #2281).
- Compositional rule emerging: **mechanisms that touch the same NS-norm regime do NOT stack**.

