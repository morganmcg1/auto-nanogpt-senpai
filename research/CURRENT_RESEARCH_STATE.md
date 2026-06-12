# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-12 17:30 UTC
- **Rank-1**: PR #2429 H-FN (fern, Muon mu warmup 500 steps), n=4 mean @ 2850 = **3.277700**, margin 0.004600. **MERGED 2026-06-10 12:30 UTC.** Beats prior rank-1 (PR #2405 H-EJ, 3.277780) by 0.000080.
- **Fleet status**: **ALL POD REPLICAS = 0/0**. Human researcher scaled the fleet down ~2 days ago. No training is currently running.
- **Operations**: **PAUSED** awaiting human approval of the frozen pulse-generalization protocol I proposed on issue #2447 (last comment 2026-06-12 07:10 UTC).
- **PR queue**: cleaned. Only PR #2444 (tanjiro H-GK Muon cosine restart) remains open. All other stale WIP PRs from 2026-06-10 closed with detailed reasons (see EXPERIMENTS_LOG.md 2026-06-12 17:30 entry).

## Most recent human direction (issue #2447, 2026-06-11)

> "Stop the current mixed training stream. Do not launch more runs until this protocol is acknowledged and converted into a small, predeclared experiment matrix."

Critique: recent pulse work mixes single-pulse + staircase schedules, beta2 targets 0.99/0.995, fractions 0.25/0.284/0.30, and Muon warmup changes — useful local speedrun tricks but **not** yet a portable rule. Want one clean candidate rule isolated and validated across regimes (T=1500, 2890, 4500) with paired controls and predeclared n.

**My response (2026-06-12 07:10 UTC):** Proposed a frozen protocol — single β₂ pulse (0.95→0.995), f∈{0.25, 0.284}, n=4 paired seeds, controls = same stack with pulse disabled, 24 new runs total, ~12–15 GPU-hours. Awaiting approval before resuming.

## Validated rank-1 ingredients (current baseline composition)

- NS5 inner iterations = **12** (H-FU PR #2434 confirmed near-optimal — both 8 iters and 16 iters regress vs 12)
- Sinkhorn Arbor: **load-bearing** (H-GH PR #2440 Arm A FALSIFIED disabling it, +2.4e-3)
- EMA-Nesterov: **load-bearing** (H-GH PR #2440 Arm B FALSIFIED disabling it, +3.0e-3)
- β₂ pulse (0.95→0.995) @ step 820 ≈ f=0.284 of T=2890 (H-EJ / PR #2405) — validated at T=2890 only; cross-budget transfer is the open question on #2447
- RI capture step 2375, γ = −0.075
- AdamW eps = 1e-12
- Muon mu_warmup = 500 steps (H-FN / PR #2429)
- Existing rational logit soft-cap (`15·x/√(x²+225)`) — already in baseline; H-GI confirms ±15 ceiling at local optimum
- Stochastic depth / DropPath: **does NOT improve** (H-GL FALSIFIED +1.5e-2)
- Focal CE training loss: **does NOT improve** (H-GM FALSIFIED +5.5e-2)
- NS-orth on AdamW gradient stream: **catastrophic** (H-GJ closed)

## State of open PRs (snapshot 2026-06-12 17:30 UTC)

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| #2444 | tanjiro | H-GK cosine momentum restart dip in Muon schedule | OPEN WIP — Arm A was at step 1770/2890 when fleet scaled down. Needs rebase + relaunch decision when fleet returns. Hypothesis independent of pulse axis. |

All other 2026-06-10 WIP PRs closed: #2440 (H-GH diagnostic complete), #2441 (H-GI readout reparameterization exhausted), #2442 (H-GJ NS-orth Adam catastrophic), #2445 (H-GO superseded by #2447 protocol).

## Open research questions (post-pause, when fleet returns)

### Priority 1 — Frozen pulse-generalization protocol (#2447, human-directed)

24 runs across T=1500/4500 control and pulse arms (f=0.25, f=0.284), n=4 paired seeds. This must run first when operations resume. Outcome categorizes the β₂ pulse as either a portable rule or a T=2890-specific recipe.

### Priority 2 — Tier-shift hypotheses for fresh assignment when fleet returns

Pulse axis is now under tight protocol control. We should assign other students orthogonal mechanisms. Candidates worth deeper exploration:
1. **Composition tests** (held aside until pulse rule resolves): mu_warmup=500 × ns_inner_iters=16 (alphonse Arm B noise-positive); double-pulse β₂ at f=0.60; orthogonal init + LSUV calibration.
2. **Optimizer-state mechanisms**: hybrid Muon/Adam preconditioner, Shampoo or SOAP head on lm_head+embed only, sign-SGD with Muon-style projection, PSGD-affine on the auxiliary AdamW groups.
3. **Schedule / readout**: untied-rate schedule for lm_head, lm_head LR cooldown asymmetry vs Muon body, late-cooldown rescheduling, post-readout RMSNorm with learned scalar.
4. **Initialization**: μP (with the LR rescale that makes it work), depth-scaled init, orthogonal Muon init with LSUV pass.
5. **Public SOTA porting**: lift mechanisms from KellerJordan #305 (current public record at 2925, n=8, val 3.27812750) and #300 (2930, n=16, val 3.27844375), specifically any pieces of their stack that are absent from our rank-1 composition.

### Priority 3 — Cleanup PR

~13 FALSIFIED lm_head β₂ pulse variants (H-FA through H-FZ family) left scaffolding in train_gpt_simple.py. Assign as a cleanup PR when fleet returns — deletion default, prove existing smoke tests still pass.

## Immediate next priorities (queue for when human approves resumption)

1. **Run the frozen β₂-pulse protocol on #2447** as a single coordinated assignment family across ~6 student GPUs. Holds other lines until results are in.
2. **Revisit PR #2444 (tanjiro H-GK)** — decide whether to rebase+relaunch (Muon cosine restart is an unexplored direction) or close. Lean keep.
3. **Assign tier-shift hypotheses to the remaining students** while the protocol runs. Optimizer-state mechanisms and public-SOTA porting are the highest-leverage axes.
4. **Cleanup PR**: prune dead FALSIFIED β₂-pulse scaffolding.

## Operational policy reminders

- **Manual computation of n=2/n=4 means** from per-trial values — agent summarization is unreliable (multiple prior misreads).
- **n=2 confirmation is unreliable for sub-5e-4 effect sizes** — always escalate to n=4 before merge (H-FU Arm B precedent).
- **Validation policy**: merge only when terminal SENPAI-RESULT shows mean ≤ new rank-1 (3.277700) at step ≤ 2850, with n≥4 and pending_arms=false.
- **Human approval gate**: no pulse-family experiments until #2447 protocol approved.
- **0 idle GPUs goal** is suspended while pods are at 0/0; resume aggressive assignment when fleet returns.
