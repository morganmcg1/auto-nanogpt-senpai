# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-16 (poll #57, ~23:50 UTC)
- **Most recent research direction from human researcher team:** none (no open GitHub issues for `auto-nanogpt-1gpu-r5`).
- **Current baseline**: `ffs=3150 (mean), best=3125, mu=3.273735, n=6` (PR #116 SOAP-attn + trust gate, merged 2026-05-16 16:30 UTC)
- **Merge statsig rule**: `(3.273735 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.27210 for n=6, ≤ 3.27245 for n=8

## Active Wave-3 Portfolio (all on merged SOAP-MLP + SOAP-attn base)

| PR # | Student         | Hypothesis                                                              | Type    | Status                                               |
|------|-----------------|-------------------------------------------------------------------------|---------|------------------------------------------------------|
| 162  | g1r5-edward     | Per-group LR sweep: lr_mlp ∈ {0.025,0.035,0.045,0.055,(0.065)}        | exploit | **STRONGEST SIGNAL** — Cell D (lr=0.055) n=1: ffs=3125, val=**3.26987** beats baseline on BOTH metrics; Cell C (lr=0.045) n=1: ffs=3125, val=3.27131. Monotonic A→B→C→D on val_loss (B→C −0.00438; C→D −0.00144 diminishing). Cell E (lr=0.065) running ETA ~01:15Z; n=4 confirm next at winner. |
| 148  | g1r5-thorfinn   | Depth-Scaled Residual Init (replace zero-init with depth-scaled Gaussian on residual output projections) | explore | WIP — n=4 screen `sn61ims4` running, step ~5626/13000 (trial 1 mid-cooldown). Full screen ETA ~03:25 UTC. |
| 175  | g1r5-askeladd   | SOAP β2 cooldown annealing (β2 0.90→0.75 over last 70% of training)   | exploit | WIP — 3 smokes finished (val 3.905-3.909 ~baseline); 4th smoke running. Needs to graduate to full run. |
| 186  | g1r5-frieren    | z-loss auxiliary regularizer (α·log²Z on partition function, α∈{1e-4,3e-4,1e-3}) | explore | **BLOCKED → FIX SENT** — 3 OOM crashes on `logits.float()` autograd buffer (13.2 GB on top of 75 GB SOAP baseline). Advisor sent bf16 logsumexp fix at poll #57. |
| 194  | g1r5-tanjiro    | Asymmetric per-group WD: wd_mlp vs wd_attn sweep ({0.015,0.035}² corners) | exploit | WIP — Cell A (0.015,0.015) trial 0 running step ~4449. ETA full sweep multi-cell ~24h. |
| 170  | g1r5-fern       | SOAP-attn precond_freq=8 (halve attn eigenbasis refresh period vs MLP=16) | exploit | WIP — 2 smokes finished (val 3.899-3.901 ~baseline); 3rd smoke running. Needs to graduate to full run. |
| 171  | g1r5-nezuko     | SOAP trust-gate threshold sweep (0.3 / 0.5 / 0.7) on SOAP-attn base  | exploit | WIP — Arm A (0.3) ffs=3150, val=3.27307 ~baseline; Arm B (0.5) ffs=3175, val=3.27497 (worse); Arm C (0.7) running step ~1908. |
| 196  | g1r5-alphonse   | SOAP col-only preconditioning for lm_head (AdamW→Muon, col-only 768×768 Gram) | exploit | WIP — debug-300 finished val=3.991 (~baseline); smoke `r3jbtzrs` running. Awaits smoke pass + full run. |

## Closed PRs Summary

| PR # | Hypothesis                         | Outcome                                                                              |
|------|------------------------------------|--------------------------------------------------------------------------------------|
| 43   | NorMuonH (record #8)               | **CLOSED** clean negative — n=8 mu=3.27962; numerical failure                       |
| 44   | Contra-Muon isolated               | **CLOSED** clean negative — n=8 mu=3.27876; ffs=3325 +125 steps slow               |
| 45   | Muon² (Adam v-buffer + NS, lr=0.10)| **CLOSED** clean negative — n=8 mu=3.27843, +100 ffs slower than SOAP-MLP           |
| 46   | SOAP-MLP isolated                  | **MERGED ✓** — ffs=3200, mu=3.27744, n=6; former baseline                          |
| 47   | MuonH (record #5 reproduction)     | **CLOSED** clean negative — n=8 mu=3.28088                                          |
| 48   | Cooldown shape sweep (plain Muon)  | **CLOSED** clean negative — linear at local optimum                                  |
| 49   | Lookahead k×α over Muon            | **CLOSED** clean negative                                                             |
| 50   | Polyak/SWA tail averaging          | **CLOSED** clean negative — above baseline                                           |
| 98   | Cautious-Muon (sign-agreement mask)| **CLOSED** clean negative — mask harms NS                                           |
| 116  | SOAP-attn + trust gate             | **MERGED ✓** — ffs=3150/3125, mu=3.273735, n=6; **current baseline**               |
| 121  | Schedule-free Muon (uniform c_t)   | **CLOSED** clean negative — val_x=3.366; z diverges + warmup mass dominates        |
| 123  | Newton-Muon (activation-cov on attn)| **CLOSED** ffs regression — n=6 mean ffs=3208 (+58 vs baseline 3150); run also used train_steps=3350 vs baseline 3250 |
| 130  | Label smoothing ε sweep            | **CLOSED** clean negative — all arms ffs=-1; CE margin already small at step 3200  |
| 141  | Gradient Centralization pre-momentum| **CLOSED** clean negative — n=4 mu=3.27863 (10σ worse); NS5 subsumes row-mean     |
| 147  | Output Embedding Mean-Centering    | **CLOSED** clean negative — val=3.29977 (52σ); softcap breaks gauge invariance      |
| 155  | Polynomial schedule-free Muon      | **CLOSED** clean negative — all p∈{2,4,6} arms val>3.34; z diverges at constant LR |

## Research Focus & Themes (wave-3+)

**Primary goal:** Stack orthogonal mechanisms onto SOAP-MLP + SOAP-attn base to push below ffs=3125. Target trajectory: ffs=3100 → 3075 → beyond.

**HOTTEST signal — PR #162 edward, Cell D (lr_mlp=0.055):**
Cell D n=1: ffs=3125, val=**3.26987** — beats baseline (3.273735) by 0.00387 on val AND beats best-of-baseline (3125) on ffs at single seed. Already passes n=1 merge rule heuristic. Cell C (lr=0.045) also ties on ffs (3125) and val=3.27131. Monotonic improvement A→B→C→D on val but marginal C→D gain only −0.00144 (vs B→C −0.00438). Cell E (lr=0.065) launched ~23:30Z, ETA ~01:15Z to determine if peak still climbing. Next: n=4 confirm at winner cell.

**Decision tree post-Cell E:**
- If E < D on val: Cell F (lr=0.075) screen, then n=4 confirm at peak.
- If E ≥ D on val (plateau/regression): **n=4 confirm at lr_mlp=0.055**. Need n=4 mean mu ≤ 3.27174 for merge.

**Active mechanism slots:**

1. **Per-group LR** (edward PR #162) — Cell D (lr=0.055) is single-seed new best at val=3.26987 / ffs=3125. Cell E (lr=0.065) will determine 0.055 vs 0.065 vs 0.075 for n=4 confirm.
2. **lm_head SOAP col-only** (alphonse PR #196) — debug-300 finished val=3.991 (~baseline at 300 steps). Smoke running.
3. **Init** (thorfinn PR #148) — depth-scaled Gaussian on residual projections; n=4 screen mid-trial-1, ETA ~03:25 UTC.
4. **SOAP β2 cooldown anneal** (askeladd PR #175) — 3 smokes finished ~baseline; needs full run promotion.
5. **z-loss auxiliary** (frieren PR #186) — BLOCKED on OOM; advisor sent bf16 logsumexp fix.
6. **Asymmetric WD** (tanjiro PR #194) — Cell A (0.015/0.015) trial 0 running.
7. **Attn precond_freq=8** (fern PR #170) — 2 smokes finished ~baseline; needs full run promotion.
8. **Trust-gate threshold sweep** (nezuko PR #171) — Arm A ≈baseline (val=3.27307), Arm B WORSE (val=3.27497), Arm C running.

**Closed mechanism slots (do NOT re-open):**
- Per-module init-multiplier: NorMuonH, MuonH
- NS wrappers: Lookahead, Cautious masking, Contra-Muon
- Cooldown shape on plain Muon: linear at optimum
- Polyak/SWA standalone
- Uniform schedule-free Muon (PR #121)
- Polynomial schedule-free Muon (PR #155) — both uniform and polynomial closed; z diverges at constant LR
- Muon² v-buffer (double-scales with SOAP)
- Output embedding mu-centering (softcap breaks gauge argument)
- Label smoothing ε sweep (CE margin already small)
- Gradient Centralization pre-momentum (NS5 subsumes; disrupts SOAP eigenbasis)
- Activation-covariance Newton-Muon on attn (PR #123) — ffs regression; gate too conservative at cos<0.5

## Infrastructure Notes

- **torch==2.11** required. Blackwell NaN at step 2 with model.compile on 2.10.
- **`sample_tensor` float64 linspace fix** in merged base.
- **stale_wip watchdog** is a recurring false positive. Always verify against W&B.
- **train_steps=3250 is standard** (line 683 default). PR #123 ran at 3350 (SENPAI_TRAIN_STEPS env override) — comparison with 3250-step baseline was unfair. **Flag all new assignments to verify `echo $SENPAI_TRAIN_STEPS` before running.**
- **12-step cubic NS** confirmed in baseline (a=2, b=-1.5, c=0.5, range(12)).
- **SOAP-attn peak memory**: 75.23 GB / 80 GB (tight budget for further additions; col-only lm_head adds ~50 MB = OK).
- **Trust gate**: cos_sim always ≥ 0.033; gate at threshold=0.0 is decorative on current stack.

## Next Research Directions (if edward Cell D confirms peak)

1. **n=4 confirm at best lr_mlp** (edward PR #162) — if Cell C or D wins, immediate n=4 confirm.
2. **lm_head SOAP col-only** (alphonse PR #196) — runs on existing SOAP-attn base.
3. **AdamW eps tuning** — eps=1e-10 for all groups; sweep eps∈{1e-8,1e-9,1e-10} for embed/lm_head.
4. **KL-SOAP-H / PMuon** (records #19/#18) — wave-4 candidates if mechanism slots exhaust.
5. **Close weak WIP**: Monitor PR #148, #175, #186 for early kill-gate signals.

## Standing Constraints

- **Banned sources**: `primeintellect.ai/auto-nanogpt`, `PrimeIntellect-ai/experiments-autonomous-speedrunning`.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed.
- **Reporting rule**: every terminal result needs SENPAI-RESULT marker + predeclared n, mu, statsig.
- **GPU budget**: 1× H100 (~80 GB) per student, ~1.93 s/step.
