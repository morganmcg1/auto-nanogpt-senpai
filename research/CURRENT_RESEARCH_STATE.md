# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-12 13:00 UTC
- **Rank-1**: PR #2429 H-FN (fern, Muon mu warmup 500 steps), n=4 mean @ 2850 = **3.277700**, margin 0.004600. **MERGED 2026-06-10 12:30 UTC.** Beats prior rank-1 (PR #2405 H-EJ, 3.277780) by 0.000080.
- **Fleet status**: **8/8 student replicas live**, all actively training. Human researcher (morganmcg1) approved resumption on 2026-06-12 10:29 UTC.
- **Operations**: **ACTIVE** under the frozen β₂-pulse generalization protocol (#2447). All 8 students executing single slots in the 24-run matrix; no other mechanisms are being explored until the matrix completes.

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

### T=1500 f=0.25 arm — 1/4 done, 2/4 running, 1/4 pending

| Seed | Student | W&B run | Status | val/loss @ 1500 | Δ vs control |
|---:|---|---|---|---:|---:|
| 1 | alphonse | `7tfszy1p` | running, step ~1100 | — | — |
| 2 | askeladd | (not started — see #2449 advisor comment) | pending | — | — |
| 3 | edward | `0vfxt7ln` | finished | **3.474925** | **−0.003091** |
| 4 | fern | `hlpwn3pa` | running, step ~1450 | — | — |

Edward's single-seed Δ = −0.003091 is a **strong** signal at n=1; aggregate decision must wait for n=4.

### T=1500 f=0.284 arm — 1/4 running, 3/4 pending

| Seed | Student | W&B run | Status |
|---:|---|---|---|
| 1 | alphonse | pending | will launch after f=0.25 finishes |
| 2 | askeladd | pending | will launch after f=0.25 finishes |
| 3 | edward | `cvsla0xs` | running, step ~150 |
| 4 | fern | pending | will launch after f=0.25 finishes |

### T=4500 control arm — all 4 running

| Seed | Student | W&B run | Started | Current step | ETA |
|---:|---|---|---|---:|---|
| 1 | frieren | `wjhc8pe9` | 10:52 UTC | 3325 / 4500 | ~40 min remaining |
| 2 | nezuko | `x1ecrbzn` | 10:52 UTC | 3550 / 4500 | ~30 min remaining |
| 3 | tanjiro | `j47czkhz` | 10:52 UTC | 2500 / 4500 | ~1.7 h remaining (RTX PRO 6000 Blackwell, ~3.1 s/step) |
| 4 | thorfinn | `x7m9akxm` | 10:54 UTC | 3250 / 4500 | ~40 min remaining |

### T=4500 pulse arms — all 8 pending (waiting on control finish)

## Operational anomalies and interventions

- **Duplicate torchrun problem**: On the heartbeat iteration around 11:08–11:15 UTC, six students (edward, fern, frieren, thorfinn, tanjiro, plus the dropout above) launched a SECOND torchrun for the control arm in parallel with the original. Advisor sent the kill-duplicate intervention to PRs #2450/#2451/#2452/#2455 at 11:21 UTC — all four students confirmed kill by 11:31 UTC.
- **Tanjiro self-recovered**: Tanjiro detected and killed its own duplicate (`vndyzc95`) at 12:14 UTC and posted at 12:49 UTC; also noted its pod has an RTX PRO 6000 Blackwell (not H100), giving ~3.1 s/step at T=4500 — total ~3.9 h/arm there.
- **Alphonse (#2448) and askeladd (#2449)** are the remaining anomaly cases (no comments before today). Advisor sent dedicated duplicate-killer comments at ~13:00 UTC. alphonse's f=0.25 (`7tfszy1p`) is healthy and should continue; the duplicate control (`b0tc03iq`) must die. askeladd's original control (`gx4ke0x1`) is canonical; the duplicate (`kmide6c7`) must die and arms 2+3 must launch cleanly afterward.

## Decision gates (advisor-side aggregation when all 8 PRs return)

For each T regime (n=4 across seeds 1–4):
- **Strong signal**: pulse_mean − control_mean ≤ −0.0003
- **Weak signal**: pulse_mean − control_mean ≤ −0.0001
- **No generalization**: |effect| < 0.0001, or sign flips between regimes

Escalate to n=8 only if effect < 0.0001 or sign disagreement. Decisions on what to do next live with the human, not the advisor — the directive says "stop after the minimal protocol completes."

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
