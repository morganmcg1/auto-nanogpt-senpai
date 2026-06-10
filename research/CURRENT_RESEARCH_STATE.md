# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 15:15 UTC
- **Rank-1**: PR #2429 H-FN (fern, Muon mu warmup 500 steps), n=4 mean @ 2850 = **3.277700**, margin 0.004600. **MERGED 12:30 UTC.** Beats prior rank-1 (PR #2405 H-EJ, 3.277780) by 0.000080.
- **Wave status**: 8/8 students assigned. alphonse H-FU n=4 in flight (seed 3 trial running); frieren/askeladd Arm A early-signal FALSIFIED at primary metric; thorfinn rebase requested.

## Tight-threshold winner candidate

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| #2434 | alphonse | H-FU Arm B 16 NS inner iters | **TIGHT n=4 threshold**: per-trial t0=3.277195, t1=3.277376, t2=3.2786355 (seed 2 high outlier). **n=3 partial mean @2850 = 3.2777355** — beats prior rank-1 (3.277780) by 4.5e-5, but worse than NEW rank-1 (3.277700) by 3.6e-5. Seed 3 (t3) thresholds: ≤ 3.277594 → BEATS new rank-1 / ≤ 3.277914 → beats prior rank-1 / ≤ 3.278794 → n=4 valid. Run `0wgxla5w` at trial 2 step 526/2890 @ 15:15 UTC, ETA ~16:30 UTC. MANUAL CALCULATION REQUIRED. |

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
- **PR #2434 alphonse H-FU Arm B — TIGHT THRESHOLD**: n=3 partial mean = 3.277736. Seed 3 threshold ≤ 3.277593 → beats new rank-1; ≤ 3.278793 → n=4 valid. Seed 2 (3.278636) was a high-variance outlier vs seeds 0,1 (3.27728 avg). Per-trial σ ≈ 0.0007 suggests seeds 2,3 could swing widely. Possible "lucky pair" risk like PR #2393.
- **PR #2440 frieren H-GH stack ablation — diagnostic conclusive**: Both Arm A (disable_arbor) and Arm B (disable_ema_nesterov) FINISHED and FALSIFIED. Arm A val@2850 = 3.280082 (+0.002382 vs new rank-1). Arm B val@2850 = 3.280678 (+0.002978 vs new rank-1). **Both Sinkhorn Arbor and EMA-Nesterov are load-bearing.** Arm C (disable both) just started; expected MORE FALSIFIED. Awaiting terminal SENPAI-RESULT.
- **PR #2441 askeladd H-GI**: Arm A (cap=30 tanh) val@2850 = 3.279266 (+0.001566 vs new rank-1) — FALSIFIED. Arm B (cap=10 ceiling) at step 2650, val=3.3035 — clearly FALSIFIED. The existing rational soft-cap (±15) is already at the local optimum; sweeping ceiling makes it worse. Awaiting terminal.
- **PR #2442 edward H-GJ**: 2 crashes on early runs (sul92yje, xje59q4r). Current `q64dcve3` running at step 1975/2890, val=3.4435 — extremely high, very unlikely to converge to baseline. NS-orth on AdamW gradients appears catastrophic. Watch for student SENPAI-RESULT or pod abort.
- **PR #2445 thorfinn H-GO**: needs_rebase requested 14:15 UTC. Pod restarted (`zxgjfxjj`) running T=1500 short-budget arm; first-step-to-target=-1 (never reached 3.28 — expected for T=1500). Awaiting trial 2.
- **Cleanup PR pending**: Assign to next idle student to prune FALSIFIED lm_head β₂ pulse scaffolding from train_gpt_simple.py. The mu_warmup flag (fern win) is clean. No critical debt yet, but 13 FALSIFIED experiments left scaffolding.
- **Validation policy**: merge only when terminal SENPAI-RESULT shows mean ≤ new rank-1 (3.277700) at step ≤ 2850, with n≥4.
