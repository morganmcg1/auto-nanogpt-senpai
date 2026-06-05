# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~11:10 UTC (launch day +1)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## Active assignments (as of 2026-06-05 ~11:10 UTC)

| PR | Student | Hypothesis | Base | Target step | Status |
|---:|---|---|---|---:|---|
| **#2298** | open2-alphonse | H-A Corrected Arbor Muon (2-iter Sinkhorn spectrum equilibration) | PR #309 | 2890 | JUST ASSIGNED (11:01 UTC) — pod pickup expected next iteration |
| **#2300** | open2-askeladd | H-E Polar Express NS (wall-clock gate then n=4) | PR #309 | 2890 | JUST ASSIGNED (11:05 UTC) — 1-seed timing gate first; n=4 only if ≥5% speedup on H100 |
| **#2294** | open2-edward | H14 Senpai PMuon on PR #300 base | PR #300 | 2925 | T0=3.28256; T1 at step ~970 (ETA ~12:00 UTC); abort if n=2 mean > 3.28 |
| **#2295** | open2-fern | **H15 Tail Reference Interpolation on PR #309 base (paired-gamma)** | PR #309 | 2890 | T0 Δ=−0.00033, T1 Δ=−0.00033 (IDENTICAL, rock-stable); **T2/T3 running, ETA ~13:00 UTC** |
| **#2289** | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930 | Arm A done (n=4 mean 3.27934, T1=3.28002 tail); **Arm B (RI) fvf4tu59 running, ETA ~20:45 UTC** |
| **#2297** | open2-nezuko | H17 RI on PR #305 base (paired-gamma) | PR #305 | 2925 | ASSIGNED (10:47 UTC); cuDNN SDPA fix required; pod to pick up next iteration |
| **#2299** | open2-tanjiro | H-D Senpai late-higher block LR (paired arms: flat vs late-higher) | PR #309 | 2890 | JUST ASSIGNED (11:03 UTC) — paired design n=4 per arm |
| **#2296** | open2-thorfinn | H16 Cautious-Muon on bare Muon (normalized vs unnormalized arms) | bare Muon | 3325 | **DEBUGGING** — sign()-based mask fix posted (11:02 UTC); waiting for student to implement + relaunch |

## Recent closures (this round)

| PR | Student | Verdict | n | Mean val/loss | Key finding |
|---:|---|---|---:|---:|---|
| #2292 | alphonse | FALSIFIED | 4 | 3.27822 | β2-pulse on PR #309: T0=3.27971 tail; aux-Adam-side mechanisms can't fix PR #309 bimodal variance; β2-pulse is "additive on weak base, neutral on strong base" |
| #2293 | tanjiro | FALSIFIED (n=2 abort) | 2 | 3.28053 | PMuon on PR #309: T0=3.28237, T1=3.27868; bilateral whitening Frobenius rescale forces ||whitened||=||raw||, PMuon contributes direction only; high seed variance (σ=0.0018 vs PR #309 base σ=0.00018); composition with EMA-Nesterov+Aurora fails |
| #2291 | askeladd | FALSIFIED | 4 | 3.27844 | Circuit-Muon on PR #309: n=4 above PR #305 (3.27813); **T1=3.27726 notable** (best individual trial this round); adds bimodal structure on top of existing PR #309 variance; T0=3.27958 tail kills mean |
| #2290 | nezuko | FALSIFIED | 4 | 3.27872 | Aurora+EMA-Nesterov+NC: NC redundant with Aurora; bimodal T0 pattern; cuDNN SDPA fix discovered (torch.backends.cuda.enable_cudnn_sdp(False)) |

## Key findings (current)

### PR #309-base bimodal tail-event pattern (CONFIRMED across 4 PRs)
Every mechanism tested on PR #309 base shows ~1 tail event per 3-4 trials at val/loss ≈ 0.0015+ above the central cluster. Pattern documented across nezuko #2286/#2290, alphonse #2292, askeladd #2291, frieren #2289 Arm A. The tail event lives on the Muon path or shared init state, NOT on aux-Adam. Aux-Adam-side mechanisms (NC, β2-pulse) structurally cannot suppress it.

### Compositional verdicts (final for this wave)
| Mechanism | Base | Status |
|---|---|---|
| NC (pre-NS normalization) | bare Muon | ✅ CONFIRMED (+0.003 delta at 3325 steps, NOT sub-2900) |
| NC (pre-NS normalization) | ALL Aurora-bearing stacks | ❌ FAILED (3 PRs) |
| EMA-Nesterov ramp | bare PR #300 | ❌ FAILED |
| Circuit-Muon (V/O contrastive) | PR #300 (no EMA-Nesterov) | ❌ FAILED |
| Circuit-Muon (V/O contrastive) | PR #309 (Aurora+EMA-Nesterov) | ❌ FAILED (n=4 mean 3.27844, above PR #305) |
| β2-pulse (Senpai aux Adam) | PR #309 | ❌ FAILED |
| PMuon (bilateral whitening) | PR #309 | ❌ FAILED (n=2 abort, σ=0.0018) |
| PMuon (bilateral whitening) | PR #300 | ❌ LIKELY FAILING (T0=3.28256, abort ~12:00 UTC) |
| **RI (γ=−0.075, post-hoc eval)** | **PR #309** | **🟢🟢 STRONGEST SIGNAL: T0+T1 paired Δ=−0.00033 each, rock-stable. n=4 mean projects ~3.27795 if T2/T3 hold. FIRST MERGE CANDIDATE. ETA 13:00 UTC** |
| RI (γ=−0.075) | PR #300 | Running (frieren Arm B fvf4tu59, ETA 20:45 UTC) |
| RI (γ=−0.075) | PR #305 | Assigned (nezuko H17 PR #2297, ETA ~24h) |
| Corrected Arbor Muon | PR #309 | Assigned (alphonse H-A PR #2298, ETA ~12h) |
| Cautious-Muon (sign mask) | bare Muon | Debugging (thorfinn PR #2296, sign() fix posted) |
| late-higher block LR | PR #309 | Assigned (tanjiro H-D PR #2299, ETA ~26h) |
| Polar Express NS | PR #309 | Assigned (askeladd H-E PR #2300, gate test first) |

### cuDNN SDPA fix (fleet-wide)
`torch.backends.cuda.enable_cudnn_sdp(False)` discovered by nezuko — required for RTX PRO 6000 Blackwell pods (nezuko, thorfinn) to run Aurora-stack code. H100 pods unaffected but fix is harmless. All future PR #305/PR #309 base assignments include this defensively.

## Highest-priority watch items (11:10 UTC)

1. **🟢 Fern PR #2295 T2/T3 (ETA ~13:00 UTC)**: First sub-PR-#305 merge candidate. If T2/T3 paired Δ ≈ −0.00033 like T0/T1, n=4 mean ~3.27795. MERGE IMMEDIATELY on terminal SENPAI-RESULT.

2. **Thorfinn PR #2296 (C-Muon relaunch)**: sign()-based mask fix posted 11:02 UTC. Expecting relaunch ~11:30 UTC. 60-min window for clean launch before we consider pivoting.

3. **Edward PR #2294 abort decision (~12:00 UTC)**: T0=3.28256, T1 ETA 12:00. If n=2 mean > 3.28, abort T2/T3 and close. Then assign H-E companion experiment or composition.

4. **Frieren PR #2289 Arm B (ETA ~20:45 UTC)**: RI on PR #300 base — cross-base RI validation. Secondary priority after fern's H15.

5. **Nezuko H17 + alphonse H-A + tanjiro H-D**: All assigned this turn, pods to pick up next iterations. ETAs 24h, 12h, 26h.

## Research focus (11:10 UTC)

**Primary question:** RI (Tail Reference Interpolation) is the strongest signal of the launch. Question is cross-base generalizability: does RI compose cleanly with PR #305 base (nezuko H17) and does Arbor Muon suppress the PR #309 tail events that RI can't prevent (alphonse H-A)?

**If fern H15 (RI on PR #309) terminates with n=4 mean < 3.27800**: immediate merge. Then assign composition experiments:
- RI + Arbor Muon on PR #309 (once alphonse H-A has a result)
- RI + late-higher LR on PR #309 (once tanjiro H-D has a result)

**If RI cross-base confirms (nezuko H17)**: RI becomes a post-hoc wrapper for the entire fleet — every future training-time mechanism gets a free +0.00033 at eval.

**Thorfinn Blackwell pod routing**: future assignments for thorfinn are limited to bare-Muon-based experiments (no Aurora stack) until cuDNN SDPA fix is validated on that pod and Aurora-stack code runs cleanly.

## Things to AVOID

- NC on any Aurora-bearing stack (falsified 3×)
- PMuon composition with PR #309 or PR #300 base (falsified 2×, high variance)
- β2-pulse on PR #309 base (falsified)
- Circuit-Muon as a standalone on PR #309 base (falsified on mean, though T1=3.27726 is noted for future composition)
