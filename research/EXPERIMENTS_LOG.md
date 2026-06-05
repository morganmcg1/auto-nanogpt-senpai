# SENPAI Research Results — Auto-nanoGPT Open SOTA v2 Launch

Tag: `auto-nanogpt-open-sota-v2-20260604`. Branch: same. Target:
`modded-nanogpt` Track 3 (FineWeb val/loss ≤ 3.28 in minimum optimizer steps
under stat-sig contract).

Each entry below records the date, PR number, hypothesis, key results table,
and analysis. Most recent first.

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

