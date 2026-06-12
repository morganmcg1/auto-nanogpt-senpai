# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-12 19:10 UTC
- **DENSE T=1500 RERUN COMPLETE (12 finished runs, group `beta2-generalization-dense-v1`).** Per-seed paired n=4 same-step Δ and RI-probe Δ computed. Key finding:
  - **f=0.25 REPLICATES original protocol direction**: same-step Δ = **−0.003890** (vs original −0.003020); RI-probe Δ = **−0.004770**. All 4 seeds negative on both metrics.
  - **f=0.284 FAILS TO REPLICATE original protocol direction**: same-step Δ = **+0.001162** (vs original −0.004816); RI-probe Δ = **+0.001787**. 2 of 4 seeds POSITIVE (worse than control) on both metrics.
  - **Threshold-crossing step gain (Track-3 style) = 0** for both arms on both metrics, all 4 seeds. Consistent with original protocol finding.
- **Dense per-seed numbers (val/loss @ 1500):** ctl/f025/f0284 — seed1 3.476178/3.474540/3.484483; seed2 3.482578/3.471430/3.475082; seed3 3.476760/3.475719/3.473771; seed4 3.477784/3.476051/3.484612. f=0.284 seeds 1 and 4 are +0.008 and +0.007 vs paired control.
- **Implication of reversal**: the original protocol's f=0.284 mean Δ = −0.0048 was dominated by the alphonse seed-1 outlier (−0.013). With independent n=4 replication, f=0.284 is essentially neutral / slightly worse. f=0.25 is the more reliable of the two pulse fractions at T=1500. Track-3-style step gain finding (=0) is unchanged.
- **Posted full n=4 analysis to Issue #2447 at 19:12 UTC** (comment 4694452144). Two-column reporting at step 1500 + RI-probe Δ; both reads agree on direction.
- **Human team posted independent dense audit at 20:02 UTC.** Their pooled n=4 mean methodology differs from my per-seed paired (less noisy, picks up smaller systematic effects): f=0.25 pooled n=4 mean RI-probe crosses pooled control threshold (3.478325) at step 1495 (one 5-step bin earlier than control). f=0.284 never crosses. Human offered two options: (1) stop and write up limited T=1500 result, (2) launch predeclared second-regime control/treatment test with dense fixed-step logging.
- **Advisor recommendation posted 20:14 UTC** (comment 4694972055): take option 1 (clean finding is publishable as-is) + revert to broader Open-Context SOTA arc for the 8 idle pods (per launch reminder). If human picks option 2, proposed T=2000 single-regime design as the cleanest interpolation test.
- **My A/B/C ask is effectively superseded** by the dense rerun (a fourth "D" option from the human team). The original A (T=4500 schedule repair) and B (broader SOTA arc) remain on the table; broader-arc resumption is what my latest recommendation re-raises.
- **PROTOCOL TERMINATED (original protocol matrix).** Human ops (15:39 UTC) closed all T=4500 PRs (#2452–#2455) and declared "stop this protocol as run." All student PRs are closed.
- **T=1500 MATRIX FULLY CLOSED (n=4 × 2 arms × 2 metrics)** — was the only valid evidence delivered by the protocol.
  - **Same-step val/loss Δ**: f=0.25 n=4 mean = **−0.003020**, f=0.284 n=4 mean = **−0.004816**. All 8 treatment runs beat their paired control.
  - **Threshold-crossing step gain (Track-3 style)**: **0** for both f, all 4 seeds. Pulse rule does NOT shorten time-to-control-threshold.
  - **Bottom line**: same-step val/loss is lower with the pulse rule at T=1500, but Track-3-style step-count transfer is NOT established.
- **T=4500 unanswerable** without script repair due to `FINAL_SCHEDULE_STEPS=2980` bug.
- **Frieren operational incident (15:30 UTC)**: relaunched a third invalid T=4500 f=0.25 attempt (`00q30fi9`), killed by ops. Three total invalid frieren launches (`4pbor27e`, …, `00q30fi9`) — pattern suggests the student's harness keeps re-triggering until told otherwise. Now resolved via PR closure.
- **NEXT-PHASE DECISION PENDING**: human has not yet authorized either (a) a repaired protocol re-run (with scale-aware LR horizon) or (b) the broader Open-Context Auto-nanoGPT SOTA research arc (per the launch reminder: composing #1532/#1614 ingredients on top of #305 lineage). Posting an explicit ask on Issue #2447. Will hold all 8 students idle until response.
- **T=4500 controls all done (n=4)**: 3.273832, 3.274065, 3.275019, 3.275554. Clustered around 3.2745 ± 0.0008 due to schedule bug freezing all 4 from step 2980. Useful as a "T=2890-style schedule" reference, NOT as a T=4500 control.
- **Frieren `4pbor27e` killed cleanly** at 14:33 UTC per OPS comment; GPU verified clear.
- **Rank-1**: PR #2429 H-FN (fern, Muon mu warmup 500 steps), n=4 mean @ 2850 = **3.277700**, margin 0.004600. **MERGED 2026-06-10 12:30 UTC.** Beats prior rank-1 (PR #2405 H-EJ, 3.277780) by 0.000080.
- **Fleet status**: **8/8 student replicas live**, all actively training. Human researcher (morganmcg1) approved resumption on 2026-06-12 10:29 UTC.
- **Operations**: Ops-driven dense T=1500 rerun in progress (12 runs, `beta2-generalization-dense-v1`). Student deployments are running ops-driven workloads, NOT student-driven PR work. **DO NOT assign new student PRs** — the 8 "idle students" reported by survey skill are actually busy with dense-rerun work via tmux. Wait for completion + human's threshold-crossing analysis on Issue #2447.

## Most recent human direction (issue #2447)

> "Yes, continue the generalization investigation. Resume only the minimal frozen beta2-pulse validation protocol described here; do not resume the older mixed PR queue." — morganmcg1, 2026-06-12 10:29 UTC

Hard scope limit: stop after the minimal protocol completes; no follow-up tuning or mechanism work without explicit human approval.

## In-flight progress (live, as of 2026-06-12 13:00 UTC)

### T=1500 control arm — **n=4 complete** ✅

W&B group: `beta2-generalization-protocol-v1`. All four T=1500 control runs are finished with no pulse flags. Δ vs control will be computed per-seed once each pulse arm finishes.

| Seed | Student | W&B run | val/loss @ 1500 |
|---:|---|---|---:|
| 1 | alphonse | `aepbts1a` | 3.487725 |
| 2 | askeladd | `gx4ke0x1` | 3.476017 |
| 3 | edward | `xflzxs2m` | 3.478016 |
| 4 | fern | `34a4sy91` | 3.477639 |
| **mean** |   |   | **3.479849** |

### T=1500 f=0.25 arm — **n=4 COMPLETE**

Two-column reporting per human direction at 14:47 UTC:

| Seed | Student | W&B run | val/loss @ 1500 | same-step Δ | threshold-cross step (3.479883909) |
|---:|---|---|---:|---:|---:|
| 1 | alphonse | `7tfszy1p` | 3.483414 | −0.004311 | 1500 |
| 2 | askeladd | `cwp90ivr` | 3.472855 | −0.003162 | 1500 |
| 3 | edward | `0vfxt7ln` | 3.474925 | −0.003091 | 1500 |
| 4 | fern | `hlpwn3pa` | 3.475986 | −0.001653 | 1500 |
| **n=4** |   |   |   | **−0.003054** | **step gain = 0** |

Same-step val/loss is consistently lower (strong by old framing), but earliest-threshold-crossing step gain is **zero**. The pulse rule does NOT shorten time-to-control-threshold at T=1500.

### T=1500 f=0.284 arm — **n=4 COMPLETE**

| Seed | Student | W&B run | val/loss @ 1500 | same-step Δ | threshold-cross step (3.481126706) |
|---:|---|---|---:|---:|---:|
| 1 | alphonse | `dkr7zp4x` | 3.474851 | −0.012874 (outlier — control high) | 1500 |
| 2 | askeladd | `v2bmp334` | 3.475576 | −0.000441 (smallest) | 1500 |
| 3 | edward | `cvsla0xs` | 3.474098 | −0.003918 | 1500 |
| 4 | fern | `62bj7pmv` | 3.475610 | −0.002029 | 1500 |
| **n=4 mean Δ** |   |   |   | **−0.004816** | **step gain = 0** |

All 4 same-step Δ negative; f=0.284 ordering vs f=0.25 flips between seeds (alphonse f=0.284 dominates; askeladd f=0.25 dominates) — single-seed noise. Threshold-crossing step gain = 0 across all 4 seeds.

### T=4500 control arm — **n=4 COMPLETE** (interpreted with caveats)

| Seed | Student | W&B run | val/loss @ 4500 (= val/loss @ ~3000 due to bug) |
|---:|---|---|---:|
| 1 | frieren | `wjhc8pe9` | 3.274065 |
| 2 | nezuko | `x1ecrbzn` | 3.273832 |
| 3 | tanjiro | `j47czkhz` | 3.275019 |
| 4 | thorfinn | `x7m9akxm` | 3.275554 |
| **n=4 mean** |   |   | **3.274617** |
| **n=4 std**  |   |   | **±0.000789** |

Tight cluster (std ≈ 8e-4). All four reach `val/best_loss` at step 3000 then freeze. This is effectively a "T=2890-style schedule extended to 4500 nominal steps" cluster, NOT a T=4500 control.

### T=4500 pulse arms — ALL PAUSED

- frieren `4pbor27e` f=0.25 launched 13:45:15 UTC — pre-empted pause comment by 70 seconds. **Killed cleanly at 14:33 UTC** (OPS confirmation on PR #2452); GPU verified clear.
- tanjiro and thorfinn confirmed pause hold (no pulse arms launched).
- nezuko paused at advisor's instruction after control finished.

## Operational anomalies and interventions

- **CRITICAL: nezuko found LR schedule bug (13:37 UTC)** — `FINAL_SCHEDULE_STEPS = 2980` hardcoded at `train_gpt_simple.py:49`, `_power_lr` (line 1364) uses `t_end = FINAL_SCHEDULE_STEPS` instead of `train_steps`. For T=4500, LR=0 from step 2980; for T=1500, schedule never finishes cooling. Verified via W&B run `x1ecrbzn` (val/loss byte-identical 3.273831605911255 for 28 consecutive evals from step 3000). Escalated to human via Issue #2447 at 13:45 UTC with 4 options; T=4500 pulse-arm launches paused on all 4 students. T=1500 students continue (their Δ is still meaningful as paired comparison even if f×T interpretation is changed).
- **Duplicate torchrun problem (iteration 2, ~11:08–11:15 UTC)**: edward, fern, frieren, thorfinn launched duplicate controls. Resolved by 11:31 UTC.
- **Tanjiro self-recovered**: killed its own duplicate at 12:14 UTC; has an RTX PRO 6000 Blackwell, ~3.1 s/step at T=4500.
- **Alphonse / askeladd intervention (13:00 UTC)**: duplicate-killer comments sent. Both resolved.
- **Alphonse second duplicate (13:18 UTC)**: launched two f=0.284 torchruns 30 seconds apart. `jihotesj` crashed; `dkr7zp4x` continues clean.

## Decision gates (advisor-side aggregation when all 8 PRs return)

**Revised after 14:47 UTC human clarification.** Per-regime n=4 aggregation reports TWO signals separately:
1. **Same-step val/loss Δ** (treatment − control at step T). Already what we've been reporting.
2. **Threshold-crossing step gain** (Track-3 style): predeclare a control-derived threshold; report earliest step at which each curve crosses. Step gain = control_cross_step − treatment_cross_step (positive = transfer wins).

Old thresholds (still useful for column 1):
- Strong: same-step Δ ≤ −0.0003
- Weak: same-step Δ ≤ −0.0001

For column 2 (Track-3-style transfer), only a positive step gain (treatment crosses earlier) counts as transfer. So far at T=1500: column 1 = strong negative, column 2 = zero.

Decisions on what to do next live with the human — the directive says "stop after the minimal protocol completes."

## Validated rank-1 ingredients (current baseline composition)

- NS5 inner iterations = **12** (H-FU PR #2434 confirmed near-optimal — both 8 iters and 16 iters regress vs 12)
- Sinkhorn Arbor: **load-bearing** (H-GH PR #2440 Arm A FALSIFIED disabling it, +2.4e-3)
- EMA-Nesterov: **load-bearing** (H-GH PR #2440 Arm B FALSIFIED disabling it, +3.0e-3)
- β₂ pulse (0.95→0.995) @ step 820 ≈ f=0.284 of T=2890 (H-EJ / PR #2405) — validated at T=2890; cross-budget transfer is the open question being tested right now
- RI capture step 2375, γ = −0.075
- AdamW eps = 1e-12
- Muon mu_warmup = 500 steps (H-FN / PR #2429)
- Existing rational logit soft-cap (`15·x/√(x²+225)`)
- Stochastic depth / DropPath: **does NOT improve** (H-GL FALSIFIED +1.5e-2)
- Focal CE training loss: **does NOT improve** (H-GM FALSIFIED +5.5e-2)
- NS-orth on AdamW gradient stream: **catastrophic** (H-GJ closed)

## Held queue (post-protocol, only after human re-authorization)

Pulse axis is under tight protocol control. When the human re-authorizes broader exploration, these candidates are pre-staged:

1. **Composition tests**: mu_warmup=500 × ns_inner_iters=16 (alphonse Arm B noise-positive); double-pulse β₂ at f=0.60; orthogonal init + LSUV calibration.
2. **Optimizer-state mechanisms**: hybrid Muon/Adam preconditioner, Shampoo or SOAP head on lm_head+embed only, sign-SGD with Muon-style projection, PSGD-affine on the auxiliary AdamW groups.
3. **Schedule / readout**: untied-rate schedule for lm_head, lm_head LR cooldown asymmetry vs Muon body, late-cooldown rescheduling, post-readout RMSNorm with learned scalar.
4. **Initialization**: μP (with LR rescale), depth-scaled init, orthogonal Muon init with LSUV pass.
5. **Public SOTA porting**: lift mechanisms from KellerJordan #305 (current public record at 2925, n=8, val 3.27812750) and #300 (2930, n=16, val 3.27844375), specifically anything absent from our rank-1 stack.
6. **Cleanup PR**: ~13 FALSIFIED lm_head β₂ pulse variants left scaffolding in train_gpt_simple.py — assign as cleanup with deletion default.

PR #2444 (tanjiro H-GK Muon cosine restart) was closed during earlier triage; if Muon-schedule restart is worth revisiting it would be a fresh hypothesis post-protocol.

## Idea backlog status

`RESEARCH_IDEAS_2026-06-10_0630.md` (~42 KB) still contains unmined hypotheses — H-FY/H-FZ minimum, plus later H-G* range. Researcher-agent thrashed on 2026-06-12 18:00 UTC (3× autocompact in 3 turns, zero output). Not relaunching while protocol is active — would waste tokens and the protocol caps scope anyway.

## Operational policy reminders

- **Manual computation of n=2/n=4 means** from per-trial values — agent summarization is unreliable (multiple prior misreads).
- **Within-student pairing** preserved by having each student run control + both treatment arms with one seed. Cross-student variance only affects between-seed comparisons, which is acceptable for n=4 aggregation.
- **No mechanism additions while protocol active**: any PR that adds flags beyond the prescribed `--aux_b2_start/--aux_b2_target/--aux_b2_pulse_step` must be sent back.
- **Terminal SENPAI-RESULT marker required** for each PR: includes regime, seed, all 3 arm val/loss values at final step, both Δ values vs control, and 3 W&B run ids.
- **Human approval gate** for any work beyond the protocol matrix.
- **Always check for duplicate torchruns** before declaring a student "active"; the iteration-2 launch pattern produced duplicates on 6 of 8 pods (now all resolved or being resolved).
