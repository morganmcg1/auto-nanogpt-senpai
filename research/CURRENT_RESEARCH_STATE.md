# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 12:30 UTC
- **Rank-1**: PR #2429 H-FN (fern, Muon mu warmup 500 steps), n=4 mean @ 2850 = **3.277700**, margin 0.004600. **MERGED 12:30 UTC.** Beats prior rank-1 (PR #2405 H-EJ, 3.277780) by 0.000080.
- **Wave status**: 8/8 students assigned. alphonse H-FU n=4 confirmation still in flight — POTENTIAL WINNER vs new rank-1.

## Near-winner (monitor priority)

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| #2434 | alphonse | H-FU Arm B 16 NS inner iters | **POTENTIAL WINNER vs new rank-1**: verified n=2 mean @2850 = 3.2772858 (beats new rank-1 by 0.000414). n=4 confirmation run `0wgxla5w` (seeds 2+3) in flight, step ~1125/5780 @ 12:25 UTC, ETA ~15:30 UTC. For n=4 mean ≤ 3.277700 (beats new rank-1): seeds 2+3 must avg ≤ 3.278115. MANUAL CALCULATION REQUIRED. |

## Current wave

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| #2446 | fern | H-GL: stochastic depth / DropPath on MLP residuals | Just assigned. Arm A: constant 0.05; Arm B: linear ramp 0→0.10; Arm C: per-layer. |
| #2445 | thorfinn | H-GO: β₂ pulse f-fraction generalization (cross-budget) | Running. Tests whether f≈0.284 generalizes across T=1500 and T=2890. |
| #2444 | tanjiro | H-GK: cosine momentum restart dip in Muon schedule | Running. SGDR-inspired dip at restart_step. |
| #2443 | nezuko | H-GM: focal / hard-token loss reweighting (γ=2.0) | Running. Token-level focal CE to focus on hard tokens. |
| #2442 | edward | H-GJ: NS-orthogonalized gradient for AdamW groups | Running. Applies NS1 orthogonalization to lm_head + embed gradients before AdamW update. |
| #2441 | askeladd | H-GI: lm_head soft-cap ceiling sweep + μP output scaling | Running. Arm A: tanh cap=30; Arm B: cap-ceiling sweep (10, 20 vs default 15). |
| #2440 | frieren | H-GH: stack ablation — remove Sinkhorn Arbor / EMA-Nesterov | Running. Diagnostic for which stack components are net positive. |
| #2434 | alphonse | H-FU Arm B: 16 NS inner iters | Near-winner; n=4 confirmation in flight (ETA 15:30 UTC). |

## Research focus

**Primary goal**: Push earliest official-valid step below 2850 (current record: step 2850, PR #2429).

**Active tracks**:
1. **Muon optimizer internals** — H-FU (NS inner iters, confirmed n=2 near-winner), H-GO (f-fraction generalization), H-GK (momentum restart dip). H-FN WIN validates this as the most productive direction.
2. **Architecture diagnostics** — H-GH (stack ablation) determines which NC × Arbor × EN components are load-bearing.
3. **Loss reformulation** — H-GM (focal CE) for harder gradient signal.
4. **Gradient orthogonalization** — H-GJ (NS1 on AdamW lm_head + embed).
5. **Readout reparameterization** — H-GI (softcap ceiling sweep).
6. **Regularization** — H-GL (stochastic depth).

## Immediate next priorities (queue for next idle slots)

1. **H-GR** (next idle): Muon mu warmup sweep — 750 and 1000 steps. Is 500 optimal? Shallow cost, high information.
2. **H-GS** (next idle after alphonse confirmation): Composition mu_warmup=500 × ns_inner_iters=16. If alphonse H-FU n=4 confirms, these two mechanisms are independent (Muon warmup phase vs NS5 geometry) and should compound.
3. **H-GG**: Orthogonal init + LSUV calibration for Muon-managed weights.
4. **H-GP**: Double-pulse β₂ at f=0.60 (~step 1734).
5. **Cleanup PR**: Prune stale lm_head β₂ pulse FALSIFIED scaffolding (H-FA through H-FZ, ~13 variants) from train_gpt_simple.py. Assign to first idle student.

## Operational concerns

- **STRICT POLICY**: All n=2/n=4 means computed MANUALLY from per-trial values — NEVER trust agent summarization (three misreads this session).
- **PR #2434 alphonse H-FU Arm B — POTENTIAL WINNER**: n=2 mean = 3.2772858 (beats new rank-1 3.277700 by 0.000414). Threshold: seeds 2+3 avg ≤ 3.278115. ETA ~15:30 UTC.
- **Cleanup PR pending**: Assign to next idle student to prune FALSIFIED lm_head β₂ pulse scaffolding from train_gpt_simple.py. The 16 NS inner iters mechanism (alphonse, if confirmed) is a clean flag; the mu_warmup flag (fern win) is also clean. No critical debt yet, but 13 FALSIFIED experiments left scaffolding that should be removed.
- **Validation policy**: merge only when terminal SENPAI-RESULT shows mean ≤ new rank-1 (3.277700) at step ≤ 2850, with n≥4. n=2 winners escalate to n=4 first.
