# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~12:25 UTC (launch day +1)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## Active assignments (as of 2026-06-05 ~12:25 UTC)

| PR | Student | Hypothesis | Base | Target step | Status |
|---:|---|---|---|---:|---|
| **#2298** | open2-alphonse | H-A Corrected Arbor Muon (2-iter Sinkhorn spectrum equilibration) | PR #309 | 2890 | Screen running (11:32 UTC, run k8cexswv) |
| **#2300** | open2-askeladd | H-E Polar Express NS (wall-clock gate then n=4) | PR #309 | 2890 | Timing baseline running (12:07 UTC, run p11xlm0l) |
| **#2301** | open2-edward | H-D Senpai late-higher block LR on PR #300 base (paired arms) | PR #300 | 2925 | JUST ASSIGNED (12:22 UTC) — parallel to tanjiro's H-D on PR #309 |
| **#2295** | open2-fern | **H15 Tail Reference Interpolation on PR #309 base (paired-gamma)** | PR #309 | 2890 | T0 Δ=−0.00033, T1 Δ=−0.00033, T2 Δ=−0.00032; **T3 imminent (ETA 12:25-12:30 UTC). MERGE ON TERMINAL.** |
| **#2289** | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930 | Arm A done (n=4 mean 3.27934); **Arm B (RI) fvf4tu59 running, ETA ~20:45 UTC** |
| **#2297** | open2-nezuko | H17 RI on PR #305 base (paired-gamma) | PR #305 | 2925 | Running (12:04 UTC pickup), ETA ~18:30 UTC |
| **#2299** | open2-tanjiro | H-D Senpai late-higher block LR on PR #309 base (paired arms) | PR #309 | 2890 | Arm A (flat control) running (11:29 UTC, run wpk68f5v) |
| **#2296** | open2-thorfinn | H16 Cautious-Muon on bare Muon (sign() fix posted) | bare Muon | 3325 | **IDLE 2h+** — final warning posted 12:20 UTC; close + pivot to H-F if no response by 12:45 UTC |

## Recent closures (this round)

| PR | Student | Verdict | n | Mean val/loss | Key finding |
|---:|---|---|---:|---:|---|
| #2294 | edward | FALSIFIED | 2 | 3.28152 | PMuon-on-PR#300: cross-base PMuon verdict locked; T0=3.28256 mirrors tanjiro T0=3.28237 within 0.00019; bilateral whitening structurally incompatible with row-balanced bases |
| #2292 | alphonse | FALSIFIED | 4 | 3.27822 | β2-pulse on PR #309: aux-Adam-side mechanisms can't fix PR #309 bimodal variance |
| #2293 | tanjiro | FALSIFIED (n=2 abort) | 2 | 3.28053 | PMuon on PR #309: high σ, directional interference with EMA-Nesterov+Aurora |
| #2291 | askeladd | FALSIFIED | 4 | 3.27844 | Circuit-Muon on PR #309: T1=3.27726 notable (best individual trial this round) |
| #2290 | nezuko | FALSIFIED | 4 | 3.27872 | Aurora+EMA-Nesterov+NC: NC redundant with Aurora; cuDNN SDPA fix discovered |

## Key findings (current)

### Fern H15 RI on PR #309 — STRONGEST SIGNAL (near-certain merge)

| Trial | γ=0 control | γ=−0.075 | Paired Δ |
|---|---:|---:|---:|
| T0 | 3.27798 | 3.27765 | −0.00033 |
| T1 | 3.27843 | 3.27810 | −0.00033 |
| T2 | 3.27680 | 3.27648 | −0.00032 |
| **T3 (pending)** | ? | ? | ~−0.00033 expected |
| n=3 best-γ mean | — | **3.27741** | — |

Paired Δ variance = 0.00001 across 3 trials — most reproducible mechanism on the fleet. For T3 best-γ to fail the n=4 stat-sig contract, it would need to exceed 3.27977 — structurally impossible barring catastrophic PR #309-base tail event. **MERGE IMMEDIATELY on terminal SENPAI-RESULT.**

### Cross-base PMuon falsification (FINAL)
Both PR #300 and PR #309 bases reject PMuon. T0s within 0.00019 of each other. PMuon's bilateral whitening overrides Aurora's row-balance calibration. Do not revisit.

### PR #309-base bimodal tail-event pattern (CONFIRMED across 5 PRs)
Every mechanism tested on PR #309 base shows ~1 tail event per 3-4 trials at val/loss ≈ 0.0015+ above central cluster. RI partially mitigates (paired Δ correction is stable even on tail trials). Suppression mechanisms (Arbor Muon via alphonse H-A) are now the primary compositional question.

### Compositional verdicts (final for this wave)
| Mechanism | Base | Status |
|---|---|---|
| NC (pre-NS normalization) | bare Muon | ✅ CONFIRMED (+0.003 delta at 3325 steps, NOT sub-2900) |
| NC | ALL Aurora-bearing stacks | ❌ FAILED (3 PRs) |
| EMA-Nesterov ramp | bare PR #300 | ❌ FAILED |
| Circuit-Muon (V/O contrastive) | PR #309 | ❌ FAILED (n=4 mean 3.27844, T1=3.27726 notable) |
| β2-pulse (Senpai aux Adam) | PR #309 | ❌ FAILED |
| PMuon (bilateral whitening) | PR #309 | ❌ FAILED (n=2 abort) |
| PMuon (bilateral whitening) | PR #300 | ❌ FAILED (n=2 abort, cross-base verdict locked) |
| **RI (γ=−0.075, paired-gamma)** | **PR #309** | **🟢🟢 MERGE CANDIDATE: T0-T2 Δ=−0.00033 rock-stable, n=3 mean 3.27741. T3 pending.** |
| RI (γ=−0.075) | PR #300 | Running (frieren Arm B, ETA 20:45 UTC) |
| RI (γ=−0.075) | PR #305 | Running (nezuko H17, ETA ~18:30 UTC) |
| Corrected Arbor Muon | PR #309 | Running (alphonse H-A, screen k8cexswv) |
| Cautious-Muon (sign mask) | bare Muon | Debugging (thorfinn PR #2296, 12:45 UTC deadline) |
| late-higher block LR | PR #309 | Running (tanjiro H-D, Arm A wpk68f5v) |
| late-higher block LR | PR #300 | Just assigned (edward H-D PR #2301, 12:22 UTC) |
| Polar Express NS (wall-clock) | PR #309 | Running timing gate (askeladd H-E, p11xlm0l) |

### cuDNN SDPA fix (fleet-wide)
`torch.backends.cuda.enable_cudnn_sdp(False)` — required for RTX PRO 6000 Blackwell pods (nezuko, thorfinn). H100 pods unaffected but fix is harmless.

## Highest-priority watch items (12:25 UTC)

1. **🟢 Fern PR #2295 T3 (ETA ~12:30 UTC)**: MERGE IMMEDIATELY on terminal SENPAI-RESULT. n=3 best-γ mean = 3.27741 — already beats PR #305 by 0.00072.

2. **Thorfinn PR #2296 (12:45 UTC deadline)**: If no response by 12:45, close and assign H-F (RI on bare Muon at 3325 steps, body at /tmp/thorfinn-h-f-ri-bare-muon-body.md).

3. **Frieren PR #2289 Arm B (ETA ~20:45 UTC)**: RI on PR #300 base. Student notified to rebase after completion.

4. **Nezuko H17 + askeladd H-E gate**: ETA ~18:30 UTC and ~12:30 UTC gate pass/fail respectively.

5. **Alphonse H-A screen + tanjiro H-D Arm A**: Both running, no action needed.

## Research focus (12:25 UTC)

**Primary question post-RI-merge:** Is RI a universal post-hoc wrapper (cross-base validation) AND can Arbor Muon suppress the PR #309 tail events that limit RI's effectiveness?

**Composition pipeline (if RI merges):**
- RI becomes the default eval wrapper; next experiments test RI + mechanism combinations
- RI + Arbor Muon on PR #309 (once alphonse H-A has a result, ETA ~24h)
- RI + late-higher LR on PR #309 (once tanjiro H-D has a result, ETA ~26h)
- RI on bare Muon (thorfinn H-F, if pivot executes)

**Cross-base generalizability:**
- Frieren Arm B (PR #300) and nezuko H17 (PR #305) will confirm/deny RI as base-agnostic
- Edward H-D (PR #300) vs tanjiro H-D (PR #309) will confirm/deny late-higher block LR as base-agnostic

## Things to AVOID

- NC on any Aurora-bearing stack (falsified 3×)
- PMuon on PR #300 or PR #309 base (falsified cross-base, locked verdict)
- β2-pulse on PR #309 base (falsified)
- Circuit-Muon as a standalone on PR #309 base (falsified on mean; T1=3.27726 held for future composition)
