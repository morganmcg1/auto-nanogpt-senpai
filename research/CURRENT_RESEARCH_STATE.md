# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-08 ~13:00 UTC (launch day +4) — **levers 48/49/50 CLOSED**: edward H-CY NorMuon-lite FALSIFIED (mechanism inert on saturated stack, "4th redundant smoothing layer"); alphonse H-V RI-γ ablation n=4 mean=3.276460 FALSIFIED (n=2 sub-signal 3.275803 did NOT survive to n=4 — variance regression to mean, not a real NC×RI/eps×RI interaction); fern H-DI SOAP_BETA2 FALSIFIED both directions (0.95 and 0.85 both hurt, 0.90 at local optimum). Three new PRs assigned: edward H-DN (stack prune NC + Amsgrad AdamW), alphonse H-DO (NC placement before NS-iter), fern H-DP (SOAP Kronecker preconditioner on MLP+V). **50 saturated levers total.**
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (updated ~23:30 UTC 2026-06-07, PR #2349 merged)

**PR #2349 (frieren H-AY): NC × Arbor + EMA-Nesterov + RI + eps=1e-12 = 3.276172 at 2890 steps**
- Stack: Cautious-Muon (NC) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075) + **AdamW eps=1e-12** (tightened from 1e-10)
- W&B: `521ky42j`/`nbptdumy`. Contract margin: 0.007656.

**Previous rank-1**: PR #2317 (nezuko H-W) = 3.276193 (margin 0.007615). Delta: −0.000021.

## Decision gates (rank-1 = 3.276172)

- STRONG ≤ 3.275772 → n=4 confirm → MERGE
- (3.275772, 3.276172] → MERGE-eligible → n=4 confirm
- (3.276172, 3.276572) → INCONCLUSIVE → close axis
- ≥ 3.276572 → FALSIFIED → close axis
- **Variance gate**: |T0 − T1| > 0.0008 → mandatory n=4 before any merge

## Active assignments (~13:00 UTC, 2026-06-08)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2377** | open2-edward | H-DN: stack prune NC + Amsgrad AdamW | NEW — awaiting pod pickup. Arm A: `--nc 0` (remove NC, keep Arbor). Arm B: `--amsgrad 1` (full stack + Amsgrad). |
| **#2378** | open2-alphonse | H-DO: NC placement before NS-iter | NEW — awaiting pod pickup. Single arm: NC moved BEFORE NS-iter (normalize rows/cols before NS-iter, not after). |
| **#2379** | open2-fern | H-DP: SOAP Kronecker preconditioner MLP+V | NEW — awaiting pod pickup. Arm A: SOAP on MLP (c_fc, c_proj). Arm B: extend to attn-V if Arm A ≥ INCONCLUSIVE. |
| **#2376** | open2-thorfinn | H-DM: Direct MUON_POWER_C sweep (0.66× vs 1.5×) | Arm A `a4rhgzhh` ~step 2225 (~77% T0), val/loss 3.358 raw. ETA ~13:30 UTC. |
| **#2375** | open2-frieren | H-DL: EN lookahead_stepsize sweep (0.15 vs 0.45) | Arm A T0=3.276163 INCONCLUSIVE (just −0.000009 below rank-1). Arm B `croo9cfc` ~step 625 (~22%), ETA ~14:30 UTC. |
| **#2374** | open2-askeladd | H-DK: Arbor clamp_k sweep (2.0 vs 5.0) | Arm A (clamp_k=2.0) T0=3.278912 FALSIFIED. Arm B `yzquk63n` ~step 1650 (~57%), ETA ~14:15 UTC. |
| **#2370** | open2-nezuko | H-DH: SWA-EMA on AdamW dense params | Arm A n=2 mean FALSIFIED (+0.0017 bias). Arm B `031u7v6t` ~step 2375 (~82%), SWA start=2500 decay=0.95, ETA ~13:30 UTC. |
| **#2373** | open2-tanjiro | H-CZ: EN rest_steps direction ablation | Arm A n=2 mean=3.277251 FALSIFIED. Arm B `095o6qc4` ~step 650 (~22%), rest=2890 never-disengage, ETA ~16:30 UTC. |

## Recent closures (~10:35–13:00 UTC, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-08 12:50 | **#2371 (fern H-DI)** | SOAP_BETA2 sweep (0.95 vs 0.85) | **CLOSED 50TH LEVER** | Both arms FALSIFIED. Arm A (0.95) +0.001838, Arm B (0.85) +0.000676. 0.90 at local optimum for 2890-step schedule with RI. |
| 2026-06-08 12:47 | **#2318 (alphonse H-V)** | RI γ ablation n=4 on stripped stack | **CLOSED 49TH LEVER** | n=4 mean at γ=−0.075 = 3.276460 (+0.000288, FALSIFIED). n=2 sub-signal 3.275803 was variance artifact. γ=−0.075 confirmed optimal monotonically. |
| 2026-06-08 12:47 | **#2369 (edward H-CY)** | NorMuon-lite β₂ sweep (0.99 vs 0.95) | **CLOSED 48TH LEVER** | Both arms FALSIFIED. Mechanism inert: NorMuon-lite correct (ratio=1.000000, 1.34→1.05 compression) but NC+Arbor+EN already compressed heterogeneity — "4th redundant smoothing layer". |
| 2026-06-08 10:30 | **#2372 (thorfinn H-DJ)** | Lookahead-on-Muon (k=5/α=0.5) | **CLOSED 47TH LEVER CATASTROPHIC** | T0=3.295566 (+0.019394, 50× FALSIFIED). Combined with H-BU (Lookahead-on-AdamW), Lookahead axis FULLY closed for both inner optimizers. |
| 2026-06-08 08:20 | **#2364 (frieren H-BW)** | EN-on-AdamW EMA β sweep | **CLOSED 45TH LEVER** | Both arms FALSIFIED. EN is Muon-specific; AdamW β₁=0.9 is equivalent smoothing. |
| 2026-06-08 08:20 | **#2365 (askeladd H-CA)** | lm_head soft-warmup + higher target LR | **CLOSED 46TH LEVER** | n=2 mean=3.276957 FALSIFIED. Key finding: zero-warmup → bf16 sign-flip cascade → LR floor constraint added to invariants. |

## Saturated levers count: 50

Levers 38–50:
38. **Lookahead k=5 α=0.5 on AdamW (H-BU)** — CATASTROPHIC +0.00823.
39. **Embed-only LR ±50% (H-BL)** — bidirectional. Direction-dependent seed-split.
40. **NS-iter × Muon LR coupling (H-BJ)** — both arms FALSIFIED.
41. **FINAL_LR_POWER recalibration (H-DA)** — informative-negative. Hand-tuned power_c not reproducible.
42. **AdamW (β₁=0.85, β₂=0.98) sweep (H-BO)** — n=2 STRONG FALSE POSITIVE; n=4 mean=3.277438. VARIANCE GATE WIN.
43. **RI capture_step earlier=2250 (H-CX)** — FALSIFIED. RI-EARLIER axis closed.
44. **Muon WD sweep 0.010 vs 0.050 (H-BN)** — FALSIFIED. WD locked at 0.025.
45. **EN-on-AdamW (H-BW)** — both arms FALSIFIED. EN mechanism is Muon-specific.
46. **lm_head soft-warmup + higher target LR K=25 (H-CA)** — FALSIFIED. LR floor invariant added.
47. **Lookahead k=5/α=0.5 on Muon (H-DJ)** — CATASTROPHIC +0.019394. Lookahead axis FULLY closed.
48. **NorMuon-lite β₂ sweep (H-CY)** — FALSIFIED. "4th redundant smoothing layer" on saturated stack.
49. **RI γ ablation n=4 stripped stack (H-V)** — FALSIFIED. n=2 sub-signal was variance artifact; γ=−0.075 optimal confirmed.
50. **SOAP_BETA2 sweep 0.95/0.85 (H-DI)** — FALSIFIED both. 0.90 at local optimum.

## Key mechanism table (NC × Arbor + RI + eps=1e-12 stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | Testing removal (H-DN Arm A) |
| + eps=1e-12 (AdamW) | **−0.000021** | Borderline — cross-PR seed pattern complicates attribution |

## Cross-PR seed pattern observation

**Seed 0 / 1 split confirmed across H-AY (eps), H-BL Arm A (embed_lr=0.20), but BROKEN by H-BL Arm B (embed_lr=0.45) and by H-BO Arm B T1.**

| Arm | T0 (seed 0) | T1 (seed 1) | n=2 mean |
|---|---:|---:|---:|
| H-AY Arm A (eps=1e-8) | 3.277593 BAD | 3.275574 GOOD | 3.276584 INCONCL |
| H-AY Arm B (eps=1e-12) | 3.277014 BAD | 3.275707 GOOD | 3.276361 INCONCL |
| H-BL Arm A (embed_lr=0.20) | 3.277526 BAD | 3.275901 GOOD | 3.276713 BARELY FALSIFIED |
| H-BL Arm B (embed_lr=0.45) | **3.276104** | **3.276428** | 3.276266 (split BROKEN — compressed) |
| H-BO Arm B (β₁=0.85, β₂=0.98) | 3.276597 BAD | **3.274075 EXCEPTIONAL** | 3.275336 STRONG |

**Updated reading**: seed-split is direction-dependent, not axis-wide. H-BO Arm B T1=3.274075 is the strongest single-seed trial seen on this baseline — n=4 confirmed variance artifact (mean 3.277438 FALSIFIED).

## Invariants confirmed (hard constraints on the stack)

1. **Muon LR uniformity across blocks** — H-BI.
2. **No DC-mode operations on Muon update path** — H-AT/H-BH.
3. **Post-NS5 update spectrum: no concentration** — H-BC.
4. **AdamW LR: no uniform multi-group boosts** — H-BF.
5. **Muon LR must be monotonic-down through step 2375 RI capture** — H-BK.
6. **lm_head LR must be ≥ baseline 1/320 throughout training** — H-CA bf16 cascade discovery.

## Next wave hypotheses (from researcher-agent 12:50 UTC)

Priority ranked for next idle slots:
1. **H-DP (ASSIGNED fern)**: SOAP Kronecker preconditioner on MLP+V — Prime Intellect evidence, expected −0.0003 to −0.0012.
2. **Contra-Muon** (for nezuko after H-DH closes): Negated phase NS5 — high risk/high reward, expected −0.001 to −0.003.
3. **H-DN (ASSIGNED edward)**: NC pruning + Amsgrad — low risk, informative.
4. **H-DO (ASSIGNED alphonse)**: NorMuon pre-NS5 row normalization — low-medium risk.
5. **AdamW β₁ schedule** (for askeladd after H-DK closes): Ramp β₁ from 0.9→0.95 or 0.9→0.8 over training — untouched axis after 50 experiments.

## Queued hypotheses (future idle slots)

- **H-DB**: Aurora K sweep (`--aurora_k` 1 vs 5 vs default 3). Row-balance iterations.
- **H-BQ**: EN `lookahead_stepsize` extended range (0.1 vs 0.6) — pending H-DL Arm B result.
- **H-BR**: NS5 cubic polynomial coefficient retune (`(3, -3, 1)` alternatives).
- **H-BP**: Muon momentum MU sweep (0.90/0.98 vs default 0.95). SCALAR — lower priority.
- **Aurora compliance check** (for tanjiro after H-CZ closes): Verify benchmark eligibility of Aurora row-balance under track-3 contract.

## Standing directive (preserved verbatim)

> Do not spend the whole run on scalar hyperparameter tuning. Retune LR/WD/betas when needed to make a new mechanism fair, but bias toward optimizer-state mechanisms, preconditioners, schedule/readout ideas, pruning of complex stacks, and principled combinations of #1532/#1614 with public SOTA lineages.

Current wave satisfies directive: H-DN (NC pruning), H-DO (NC placement — optimizer precondition), H-DP (SOAP Kronecker — preconditioner), H-DK (Arbor clamp_k), H-DL (EN lookahead_stepsize), H-DM (MUON_POWER_C direct), H-DH (SWA-EMA optimizer-state), H-CZ (EN rest_steps schedule).
