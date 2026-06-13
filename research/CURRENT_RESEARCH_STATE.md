# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-13 19:05 UTC
- **Rank-1 SOTA:** PR #2429 (H-FN), step 2850, n=4 mean **3.277700**, margin **0.004600** (mu_warmup=500).
- **Auxiliary reference (NEW)**: PR #321 static stack, step 2775, n=4 mean **3.277146**, margin **0.005708** (Track A static arm audited 19:00 UTC; not merged — earlier crossing step but no margin improvement vs #2429).

## Latest human direction

> "Resume only the minimal frozen beta2-pulse validation protocol described here; do not resume the older mixed PR queue." — morganmcg1, 2026-06-12 10:29 UTC (Issue #2447). Hard scope limit superseded by Issues #2460 and #2461 which authorize the Track A/B β₂ generalization investigations. Both NOW CONCLUDED — no live hard scope limit beyond the standard launch directive (build on best public work; bias to optimizer-state mechanisms, preconditioners, schedule, principled compositions of #1532/#1614 + SOTA lineages).

## Verdicts posted today

### Track B (Issue #2460): f=0.25 timing on #2429 stack — **CLOSED (FAILS)**
- Treatment n=4 @ step 2850 = **3.278725** (margin +0.002549, fails Track 3 validity).
- Baseline n=4 @ step 2850 = **3.277903** (margin +0.004195, reproduces #2429).
- Paired Δ very stable +0.000820 → +0.000838 across 2825-2890; 3/4 seeds favor baseline.
- 4 PRs closed (#2462-#2465). Verdict posted Issue #2460 comment 4699133331.
- **Implication:** Cross-budget f=0.25 generalization (T=1500, T=4500) is budget-conditional, NOT a normal-track optimum. #2429's pulse step 820 (f=0.284) is co-tuned to the rest of the stack.

### Track A (Issue #2461): PR #321 dynamic aux-β₂ surge — **COMPLETE & CLOSED (BOTH ARMS FAIL)**
- Static n=4 @ step 2775 = **3.277146** (margin +0.005708, OFFICIAL-VALID — reproduces PR #321 baseline).
- f=0.25 (pulse 725) n=4 @ step 2775 = **3.284738** (Δ +0.00759 vs static, margin −0.00948, FAILS).
- f=0.284 (pulse 824) n=4 @ step 2775 = **3.284237** (Δ +0.00709 vs static, margin −0.00848, FAILS).
- All 8 paired (treatment − static) comparisons positive across 4 seeds × 2 arms.
- 4 PRs closed (#2456 alphonse, #2457 askeladd, #2458 edward, #2459 fern). Unified verdict: Issue #2461 comment 4699480105.
- **Cross-lineage implication:** dynamic aux-β₂ surge axis CLOSED across BOTH #2429 (Track B) and PR #321 (Track A) lineages.

## Current posture — 4 students in flight, 4 students returning to idle

### In flight (compositional probes, n=2 screens at fixed steps 2825/2850/2875/2890)
| PR | Student | Hypothesis | Key change vs #2429 | ETA |
|---|---|---|---|---|
| #2466 | frieren | **H-GR**: mu_warmup 500→750 | Extend Muon μ-ramp (schedule) | ~21:00 UTC |
| #2467 | nezuko | **H-HL**: RI capture 2375→2500 (LATER) | Later readout snapshot | ~21:00 UTC |
| #2468 | tanjiro | **H-HM**: PR #321 + mu_warmup=500 | Cross-lineage composition | ~21:00 UTC |
| #2469 | thorfinn | **H-HN**: SOAP precond freq 10→{5,20} | Preconditioner refresh rate (2 arms × seeds 0,1) | ~22:00 UTC |

### Idle now — 4 students awaiting fresh hypothesis assignments
- **askeladd, fern, alphonse, edward** all idle (Track A closed 19:00 UTC).
- Researcher-agent dispatched at 18:55 UTC for 4 orthogonal hypotheses H-HO/HP/HQ/HR. Output target: `/research/RESEARCH_IDEAS_2026-06-13_19:00.md`. ETA ~19:15-19:30 UTC. Once received, assign immediately via senpai:assign-experiment.

## Validated rank-1 ingredients (current baseline composition, MERGED)

- NS5 inner iterations = **12** (H-FU PR #2434 confirmed near-optimal).
- Sinkhorn Arbor: **load-bearing** (H-GH Arm A FALSIFIED disabling +2.4e-3).
- EMA-Nesterov: **load-bearing** (H-GH Arm B FALSIFIED disabling +3.0e-3).
- β₂ pulse (0.95→0.995) @ step 820 ≈ f=0.284 of T=2890 (H-EJ / PR #2405). T=2890 optimum confirmed; cross-budget f=0.25 generalization closed as budget-conditional only.
- RI capture step 2375, γ = −0.075.
- AdamW eps = 1e-12.
- Muon mu_warmup = **500 steps** (H-FN / PR #2429 — current rank-1 increment).
- Existing rational logit soft-cap (`15·x/√(x²+225)`).
- Stochastic depth / DropPath: **does NOT improve** (H-GL FALSIFIED).
- Focal CE training loss: **does NOT improve** (H-GM FALSIFIED).
- NS-orth on AdamW gradient stream: **catastrophic** (H-GJ closed).

## Held queue / parking lot

Pre-staged for future rounds when current 4 in-flight hypotheses return:

1. **Composition**: H-GR × H-HL combined (mu_warmup=750 + ri_capture=2500) if both win.
2. **Public SOTA porting**: lift mechanisms from KellerJordan #305 (current public record at 2925, n=8, val 3.27812750) and #300 (2930, n=16, val 3.27844375).
3. **Cleanup PR**: ~13 FALSIFIED lm_head β₂ pulse variants left scaffolding in train_gpt_simple.py — assign as cleanup with deletion default.
4. **Optimizer-state**: hybrid Muon/Adam preconditioner, Shampoo or SOAP head on lm_head+embed only, sign-SGD with Muon-style projection, PSGD-affine on the auxiliary AdamW groups.
5. **Initialization**: μP (with LR rescale), depth-scaled init, orthogonal Muon init with LSUV pass.

## Operational notes

- **Track A f=0.284 will conclude in ~5 min.** Once alphonse/edward terminal, compute n=4 unified verdict, post to Issue #2461, close #2456-#2459.
- **Researcher agent dispatched** for 4 fresh hypotheses for the 4 students who will be idle after Track A closes.
- **No T=1500/T=4500 protocol residue** — that protocol fully terminated; all evidence in `EXPERIMENTS_LOG.md`.
- **Manual computation of n=2/n=4 means** required — agent summarization unreliable.
- **No mechanism additions** that aren't a single CLI flag change unless the hypothesis explicitly requires cross-lineage composition (H-HM is the one exception).
