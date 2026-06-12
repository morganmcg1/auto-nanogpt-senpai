# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-12 17:00 UTC
- **Rank-1**: PR #2429 H-FN (fern, Muon mu warmup 500 steps), n=4 mean @ 2850 = **3.277700**, margin 0.004600. **MERGED 2026-06-10 12:30 UTC.** Beats prior rank-1 (PR #2405 H-EJ, 3.277780) by 0.000080.
- **Fleet status**: **ALL POD REPLICAS = 0/0**. Human researcher scaled the fleet down ~2 days ago after issuing the directive in issue #2447. No training is currently running.
- **Operations**: **PAUSED** awaiting human approval of the frozen pulse-generalization protocol I proposed on issue #2447 (last comment 2026-06-12). No new assignments until protocol is acknowledged.

## Most recent human direction (issue #2447)

> "Stop the current mixed training stream. Do not launch more runs until this protocol is acknowledged and converted into a small, predeclared experiment matrix."

The human team flagged that the recent pulse work mixes single-pulse + staircase schedules, beta2 targets 0.99/0.995, fractions 0.25/0.284/0.30, and Muon warmup changes — useful local speedrun tricks but **not** yet a portable rule. They want one clean candidate rule isolated and validated across regimes (T=1500, 2890, 4500) with paired controls and predeclared n.

**My response (2026-06-12):** Proposed a frozen protocol — single β₂ pulse (0.95→0.995), f∈{0.25, 0.284}, n=4 paired seeds, controls = same stack with pulse disabled, 24 new runs total, ~12–15 GPU-hours. Awaiting approval before resuming.

## State of open PRs (snapshot 2026-06-12 17:00 UTC)

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| #2446 | fern | H-GL stochastic depth on MLP residuals | **CLOSED 17:00** — FALSIFIED n=1, val@2890 = 3.29121 (+0.015) |
| #2443 | nezuko | H-GM focal loss γ=2.0 | **CLOSED 17:00** — FALSIFIED n=1, val@2890 = 3.33070 (+0.055) |
| #2434 | alphonse | H-FU NS inner iter sweep (8/16 vs 12) | **CLOSED 17:00** — INFORMATIVE; n=2 lead at 16 iters collapsed at n=4 (mean 3.277814, +1.1e-4). NS=12 is near-optimal. |
| #2445 | thorfinn | H-GO β₂ pulse f-fraction cross-budget | WIP (stale 2026-06-10); needs_rebase. **Superseded** by the frozen protocol on #2447. |
| #2444 | tanjiro | H-GK cosine momentum restart dip | WIP (stale 2026-06-10); was running Arm A when pod scaled down. Needs rebase + relaunch. |
| #2442 | edward | H-GJ NS-orth gradient for AdamW groups | WIP (stale 2026-06-10); 2 crashes + run with val=3.44 mid-train — looks catastrophic. Likely close after re-survey. |
| #2441 | askeladd | H-GI lm_head soft-cap ceiling sweep | WIP (stale 2026-06-10); Arm A FALSIFIED before pause; redirected to ceiling sweep — incomplete. |
| #2440 | frieren | H-GH stack ablation (Arbor / EN diagnostic) | WIP (stale 2026-06-10); Arms A+B FALSIFIED; Arm C started but pod scaled before completion. Diagnostic conclusion already in hand. |

**No idle-student assignment work to do** while pods are at 0 and human directive blocks new launches.

## Validated rank-1 ingredients (current baseline composition)

- NS5 inner iterations = **12** (H-FU confirmed near-optimal)
- Sinkhorn Arbor: **load-bearing** (H-GH Arm A FALSIFIED disabling it)
- EMA-Nesterov: **load-bearing** (H-GH Arm B FALSIFIED disabling it)
- β₂ pulse (0.95→0.995) @ step 820 ≈ f=0.284 of T=2890 (H-EJ / PR #2405) — validated at T=2890 only
- RI capture step 2375, γ = −0.075
- AdamW eps = 1e-12
- Muon mu_warmup = 500 steps (H-FN / PR #2429)
- Existing rational logit soft-cap (±15) — confirmed already present
- ns_inner_iters=12 is near-optimal for this composite

## Open research questions (post-pause, when fleet returns)

1. **Pulse-rule generalization** (highest priority — human directive). The frozen protocol on #2447 must run first when operations resume. If f=0.284 transfers to T=1500 and T=4500 with consistent paired-seed sign, we have a portable rule; otherwise it is a T=2890-specific recipe.
2. **Composition tests** held aside until pulse rule resolves: mu_warmup=500 × ns_inner_iters=16 (alphonse Arm B noise-positive); double-pulse β₂ at f=0.60; orthogonal init + LSUV; per-group readout reparameterization beyond the existing ±15 cap.
3. **Stack pruning**: ~13 FALSIFIED lm_head β₂ pulse variants left scaffolding in train_gpt_simple.py. Assign as a cleanup PR when fleet returns.
4. **Outside the pulse axis**: optimizer-state mechanisms (Shampoo/SOAP head, modified PSGD, hybrid Muon/Adam preconditioners), schedule/readout ideas (untied-rate schedule, late-cooldown rescheduling), and bold initialization changes (μP, depth-scaled init).

## Immediate next priorities (queue for when human approves resumption)

1. **Run the frozen β₂-pulse protocol on #2447** as a single coordinated assignment family across 6 student GPUs (T=1500 control + 2 pulse arms, T=4500 control + 2 pulse arms = 6 arms × 4 seeds). Holds other lines until results are in.
2. **Survey WIP PRs**: revisit each of #2440–#2445 for relaunch-vs-close decisions after the rebase. #2442 H-GJ looks catastrophic — likely close. #2440 H-GH diagnostic is already informative — likely close after writing up. #2441 H-GI ceiling sweep is worth completing. #2444 H-GK and #2445 H-GO will be subsumed by the frozen protocol or relaunched fresh.
3. **Cleanup PR**: prune dead FALSIFIED β₂-pulse scaffolding (H-FA through H-FZ family).
4. **Fresh tier-shift hypotheses**: have the researcher-agent prepare a new batch with emphasis on mechanisms orthogonal to the pulse axis, since the pulse is now under tight protocol control.

## Operational policy reminders

- **Manual computation of n=2/n=4 means** from per-trial values — agent summarization is unreliable (multiple prior misreads).
- **n=2 confirmation is unreliable for sub-5e-4 effect sizes** — always escalate to n=4 before merge (H-FU Arm B precedent).
- **Validation policy**: merge only when terminal SENPAI-RESULT shows mean ≤ new rank-1 (3.277700) at step ≤ 2850, with n≥4 and pending_arms=false.
- **Human approval gate**: no pulse-family experiments until #2447 protocol approved.
