# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-12 20:20 UTC
- **Rank-1**: PR #2429 H-FN (fern, Muon mu warmup 500 steps), n=4 mean @ 2850 = **3.277700**, margin 0.004600. **MERGED 2026-06-10 12:30 UTC.** Beats prior rank-1 (PR #2405 H-EJ, 3.277780) by 0.000080.
- **Fleet status**: **8/8 student replicas live**. Human researcher (morganmcg1) approved resumption on 2026-06-12 10:29 UTC.
- **Operations**: **ACTIVE** under the frozen β₂-pulse generalization protocol (#2447). All 8 students assigned single slots in the 24-run matrix; no other mechanisms are being explored until the matrix completes.

## Most recent human direction (issue #2447)

> "Yes, continue the generalization investigation. Resume only the minimal frozen beta2-pulse validation protocol described here; do not resume the older mixed PR queue." — morganmcg1, 2026-06-12 10:29 UTC

Hard scope limit: stop after the minimal protocol completes; no follow-up tuning or mechanism work without explicit human approval.

## Active matrix (PRs #2448–#2455, 8 PRs, 24 runs total)

W&B group for every run: `beta2-generalization-protocol-v1`. All arms share the rank-1 stack from PR #2429 (mu_warmup=500, RI capture scaled to ~82% of T, eps=1e-12, etc.) and differ only in the β₂ pulse flags.

| PR | Student | T | Seed | Arms | Pulse steps | ETA |
|---:|---|---:|---:|---|---|---|
| #2448 | open2-alphonse | 1500 | 1 | control + f=0.25 + f=0.284 | 375 / 426 | ~45–60 min |
| #2449 | open2-askeladd | 1500 | 2 | control + f=0.25 + f=0.284 | 375 / 426 | ~45–60 min |
| #2450 | open2-edward | 1500 | 3 | control + f=0.25 + f=0.284 | 375 / 426 | ~45–60 min |
| #2451 | open2-fern | 1500 | 4 | control + f=0.25 + f=0.284 | 375 / 426 | ~45–60 min |
| #2452 | open2-frieren | 4500 | 1 | control + f=0.25 + f=0.284 | 1125 / 1278 | ~2.5–3 h |
| #2453 | open2-nezuko | 4500 | 2 | control + f=0.25 + f=0.284 | 1125 / 1278 | ~2.5–3 h |
| #2454 | open2-tanjiro | 4500 | 3 | control + f=0.25 + f=0.284 | 1125 / 1278 | ~2.5–3 h |
| #2455 | open2-thorfinn | 4500 | 4 | control + f=0.25 + f=0.284 | 1125 / 1278 | ~2.5–3 h |

Within-student pairing: each student runs control + both pulse arms on the same hardware with the same seed, so per-seed Δ vs control is tight (no cross-machine variance).

40-shard FineWeb cache already present on the PVC (verified 2026-06-12); no pre-cache wait needed.

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

PR #2444 (tanjiro H-GK Muon cosine restart) was closed during the 2026-06-12 17:30 UTC triage; if Muon-schedule restart is worth revisiting it would be a fresh hypothesis post-protocol.

## Idea backlog status

`RESEARCH_IDEAS_2026-06-10_0630.md` (~42 KB) still contains unmined hypotheses — H-FY/H-FZ minimum, plus later H-G* range. Researcher-agent thrashed on 2026-06-12 18:00 UTC (3× autocompact in 3 turns, zero output). Not relaunching while protocol is active — would waste tokens and the protocol caps scope anyway.

## Operational policy reminders

- **Manual computation of n=2/n=4 means** from per-trial values — agent summarization is unreliable (multiple prior misreads).
- **Within-student pairing** preserved by having each student run control + both treatment arms with one seed. Cross-student variance only affects between-seed comparisons, which is acceptable for n=4 aggregation.
- **No mechanism additions while protocol active**: any PR that adds flags beyond the prescribed `--aux_b2_start/--aux_b2_target/--aux_b2_pulse_step` must be sent back.
- **Terminal SENPAI-RESULT marker required** for each PR: includes regime, seed, all 3 arm val/loss values at final step, both Δ values vs control, and 3 W&B run ids.
- **Human approval gate** for any work beyond the protocol matrix.
