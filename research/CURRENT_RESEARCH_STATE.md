# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 11:00 UTC
- **Rank-1 holds**: PR #2405 H-EJ (askeladd β₂ pulse 0.95→0.995 @ step 820), n=4 mean @ 2850 = **3.277780**, margin 0.004440. Unchanged since 2026-06-09 09:20 UTC.
- **Wave status**: 8/8 students assigned. All slots productive.

## Near-winners (monitor priority)

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| #2429 | fern | H-FN Muon mu warmup 500 | **Near-winner**: n=3 partial mean @2850 = 3.2777717 (essentially tied with rank-1). Per-trial: t0=3.278708, t1=3.277227, t2=3.277380. Trial 3 (seed 3) ETA ~12:20 UTC. If t3 @2850 ≤ 3.277805 → n=4 mean ≤ 3.278000 → BEATS rank-1. MANUAL CALCULATION REQUIRED. |
| #2434 | alphonse | H-FU Arm B 16 NS iters | **Near-winner**: n=2 mean @2850 = 3.277286 (beats rank-1 by 0.000494). n=4 confirmation run `0wgxla5w` (seeds 2+3) launched, ETA ~15:30 UTC. MANUAL CALCULATION REQUIRED. |

## Current wave

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| #2445 | thorfinn | H-GO: β₂ pulse f-fraction generalization (cross-budget) | Just assigned. Arm A: T=1500 pulse@426; Arm B: T=1500 no-pulse; Arm C: T=2890 pulse@722 (f=0.25). Directly addresses Issue #2388 Comment 4+18 generalization directive. |
| #2444 | tanjiro | H-GK: cosine momentum restart dip in Muon schedule | Just assigned. SGDR-inspired dip at restart_step. Arm A: restart=1500, hw=200; Arm B: restart=1200, hw=150. |
| #2443 | nezuko | H-GM: focal/hard-token loss reweighting (γ=2.0) | Just assigned. Token-level focal CE to focus on hard tokens. |
| #2442 | edward | H-GJ: NS-orthogonalized gradient for AdamW groups | Recently assigned. Applies NS1 orthogonalization to lm_head + embed gradients before AdamW update. |
| #2441 | askeladd | H-GI: lm_head soft-cap cap=30 + μP output scaling | Recently assigned (tier-shift). |
| #2440 | frieren | H-GH: stack ablation (remove Sinkhorn Arbor / EMA-Nesterov) | Recently assigned (tier-shift diagnostic). |
| #2434 | alphonse | H-FU Arm B 16 NS iters | Near-winner; n=4 confirmation in flight. |
| #2429 | fern | H-FN Muon mu warmup 500 | Near-winner; trial 3 in flight. |

## Research focus

**Primary goal**: Push earliest official-valid step below 2850 (current record: step 2850, PR #2405).

**Dual track**:
1. **Speedrun improvements**: Meta-optimizer wrappers (Lookahead, momentum restarts), schedule variants (cosine restart), architecture diagnostics (stack ablation), loss reformulation (focal CE), gradient orthogonalization.
2. **Generalization study** (Issue #2388 directives 4+18): H-GO (PR #2445, thorfinn) directly tests whether the β₂ pulse f-fraction rule (f≈0.284) generalizes across budgets T=1500 and T=2890. If confirmed, provides a portable rule: "apply β₂ pulse from 0.95→0.995 at ~28% of total training steps."

## Strategy after plateau

The lm_head β₂ pulse hyperparameter family is saturated — 13 FALSIFIED runs with no improvement. Tier-shift wave now in progress:

1. **Meta-optimizer wrappers**: Muon momentum restart dip (H-GK), Lookahead variants
2. **Different optimizers**: Sophia, Lion, Adan, Apollo
3. **Architecture diagnostics**: Stack ablation to identify which components (Sinkhorn Arbor, EMA-Nesterov) are net positive
4. **Loss reformulation**: Focal CE token reweighting
5. **Schedule restarts**: Cosine restarts, momentum cycling
6. **Generalization validation**: f-fraction cross-budget study

## Potential next directions (tier-shift queue)

1. **H-GL**: Stochastic depth / DropPath schedule (currently absent)
2. **H-GN**: Focal-style hard-token loss reweighting (currently uniform CE) — now assigned H-GM (variant)
3. **H-GG** (next idle): Orthogonal init + LSUV calibration for Muon-managed weights
4. **H-GK** (next idle): Cosine restart schedule for Muon mu (assigned tanjiro #2444)
5. **H-GP** (planned): Double-pulse β₂: apply pulse again at f=0.60 (step ~1734) — test whether a second pulse in mid-cooldown helps
6. **H-GQ** (planned): Longer-range pulse sweep: f=0.15, f=0.20, f=0.35 to fully characterize the f-fraction landscape

## Operational concerns

- **STRICT POLICY**: All n=2/n=4 means computed MANUALLY from per-trial values — NEVER trust agent summarization (three misreads this session).
- **PR #2429 fern H-FN — POTENTIAL WINNER**: n=3 partial mean = 3.2777717 (tied with rank-1). Manual n=4 calculation required when trial 3 arrives ~12:20 UTC.
- **PR #2434 alphonse H-FU Arm B — POTENTIAL WINNER**: n=2 mean = 3.277286. Manual n=4 calculation required when `0wgxla5w` completes ~15:30 UTC.
- **Validation policy**: merge only when terminal SENPAI-RESULT shows mean ≤ rank-1's mean (3.277780) at step ≤ 2850, with n≥4. n=2 winners escalate to n=4, NOT merged directly.
