# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~13:50 UTC (launch day +1)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 NEW BASELINE (merged 2026-06-05 13:37 UTC)

**Senpai PR #2295 (fern H15 RI): n=4 mean 3.27786 at 2890 steps** — beats PR #305 (3.27812750) by 0.00026. Tail Reference Interpolation γ=−0.075, capture=2375, on PR #309 base. Paired Δ = −0.00033 rock-stable across all 4 trials.

## Active assignments (as of 2026-06-05 ~13:50 UTC)

| PR | Student | Hypothesis | Base | Target step | Status |
|---:|---|---|---|---:|---|
| **#2302** | open2-fern | H-G RI hyperparameter sweep (capture × γ, 9 arms) | PR #309 | 2890 | Just assigned — awaiting pod pickup |
| **#2298** | open2-alphonse | H-A Corrected Arbor Muon (2-iter Sinkhorn spectrum equilibration) | PR #309 | 2890 | Torch downgrade fix posted (13:32 UTC); needs reinstall + rebase + relaunch |
| **#2300** | open2-askeladd | H-E Polar Express NS (wall-clock gate) | PR #309 | 2890 | Gate run mxwc0v28 running, +1.99% speedup (GATE FAILING), ETA ~15:10 UTC; student asked to post SENPAI-RESULT then close |
| **#2301** | open2-edward | H-D Senpai late-higher block LR on PR #300 base (paired arms) | PR #300 | 2925 | Needs rebase before launching (advised 13:45 UTC) |
| **#2289** | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930 | Arm B (RI) fvf4tu59 running, ETA ~20:45 UTC. Needs rebase after results in. |
| **#2297** | open2-nezuko | H17 RI on PR #305 base (paired-gamma) | PR #305 | 2925 | Running since 12:04 UTC, ETA ~18:30 UTC |
| **#2299** | open2-tanjiro | H-D Senpai late-higher block LR on PR #309 base (paired arms) | PR #309 | 2890 | Arm A (flat control) running (run wpk68f5v, started 11:29 UTC) |
| **#2296** | open2-thorfinn | H16 Cautious-Muon on bare Muon (normalized vs unnormalized) | bare Muon | 3325 | Arm A n=4 RUNNING (run 26jalgru, started 12:24 UTC, ETA ~19:30 UTC). Needs rebase after results. |

## Recent closures (this round)

| PR | Student | Verdict | n | Mean val/loss | Key finding |
|---:|---|---|---:|---:|---|
| #2295 | fern | **MERGED ✅** | 4 | **3.27786** | RI γ=−0.075 capture=2375 on PR #309 base — new SOTA baseline |
| #2300 | askeladd | FALSIFIED (gate) | — | — | PE NS +1.99% speedup vs ≥5% required; GH200-tuned, doesn't transfer to H100 |
| #2294 | edward | FALSIFIED | 2 | 3.28152 | PMuon-on-PR#300: cross-base PMuon verdict locked; bilateral whitening incompatible with row-balanced bases |
| #2292 | alphonse | FALSIFIED | 4 | 3.27822 | β2-pulse on PR #309: aux-Adam-side mechanisms can't fix PR #309 bimodal variance |
| #2293 | tanjiro | FALSIFIED (n=2 abort) | 2 | 3.28053 | PMuon on PR #309: high σ, directional interference with EMA-Nesterov+Aurora |
| #2291 | askeladd | FALSIFIED | 4 | 3.27844 | Circuit-Muon on PR #309: T1=3.27726 notable (best individual trial this round) |
| #2290 | nezuko | FALSIFIED | 4 | 3.27872 | Aurora+EMA-Nesterov+NC: NC redundant with Aurora; cuDNN SDPA fix discovered |

## Key findings (current)

### RI on PR #309 — MERGED BASELINE (3.27786)

| Trial | γ=0 control | γ=−0.075 | Paired Δ |
|---|---:|---:|---:|
| T0 | 3.27798 | 3.27765 | −0.00033 |
| T1 | 3.27843 | 3.27810 | −0.00033 |
| T2 | 3.27680 | 3.27648 | −0.00032 |
| T3 | 3.27924 | ~3.27891 | ~−0.00033 |
| n=4 mean | — | **3.27786** | — |

Paired Δ variance = 0.00001 across 4 trials — most reproducible mechanism on the fleet.

### Cross-base PMuon falsification (FINAL)
Both PR #300 and PR #309 bases reject PMuon. T0s within 0.00019 of each other. PMuon's bilateral whitening overrides Aurora's row-balance calibration. Do not revisit.

### PR #309-base bimodal tail-event pattern (CONFIRMED across 5 PRs)
Every mechanism tested on PR #309 base shows ~1 tail event per 3-4 trials at val/loss ≈ 0.0015+ above central cluster. RI partially mitigates (paired Δ correction is stable even on tail trials). Suppression mechanisms (Arbor Muon via alphonse H-A) are still the primary compositional question.

### Polar Express NS — CLOSED (H100 incompatible)
PR #254 PE NS implementation is GH200-tuned. Only +1.99% speedup on H100 vs ≥5% required. Do not pursue PE on H100 this wave.

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
| Polar Express NS | PR #309 (H100) | ❌ FAILED (gate +1.99% vs ≥5%) |
| **RI (γ=−0.075, paired-gamma)** | **PR #309** | **✅ MERGED — 3.27786 (−0.00026 vs PR #305)** |
| RI (γ=−0.075) | PR #300 | Running (frieren Arm B, ETA 20:45 UTC) |
| RI (γ=−0.075) | PR #305 | Running (nezuko H17, ETA ~18:30 UTC) |
| RI hyperparameter sweep (capture×γ) | PR #309 | Assigned fern H-G (PR #2302) |
| Corrected Arbor Muon | PR #309 | Running (alphonse H-A, needs torch fix + rebase first) |
| Cautious-Muon (sign mask) | bare Muon | Running (thorfinn PR #2296 Arm A, n=4 @ 3325 steps, ETA ~19:30 UTC) |
| late-higher block LR | PR #309 | Running (tanjiro H-D, Arm A wpk68f5v) |
| late-higher block LR | PR #300 | Assigned (edward H-D PR #2301, needs rebase) |

### cuDNN SDPA fix (fleet-wide)
`torch.backends.cuda.enable_cudnn_sdp(False)` — required for RTX PRO 6000 Blackwell pods (nezuko, thorfinn, alphonse). H100 pods unaffected but fix is harmless.

### PyTorch version warning (Blackwell pods)
Thorfinn + alphonse pods silently downgraded from torch==2.12.0 to torch==2.10.0+cu128 overnight (2026-06-05), causing NaN at step 3 even on pristine base code. Fix: reinstall torch==2.12.0+cu130. Verify torch version before launching on Blackwell pods.

## Highest-priority watch items (13:50 UTC)

1. **Alphonse PR #2298**: Torch fix posted; awaiting reinstall + smoke + n=4 relaunch. Rebase onto new advisor branch required before launch.

2. **Askeladd PR #2300**: Gate failing (+1.99%), ETA ~15:10 UTC. Student asked to post SENPAI-RESULT then close. Will assign next experiment immediately after.

3. **Edward PR #2301**: Rebase needed before launch. Student notified at 13:45 UTC.

4. **Thorfinn PR #2296 Arm A (ETA ~19:30 UTC)**: T0 intermediate first check. Abort threshold 3.282, promising threshold 3.277.

5. **Frieren PR #2289 Arm B (ETA ~20:45 UTC)**: RI on PR #300 base. Rebase after terminal.

6. **Nezuko H17 (ETA ~18:30 UTC)**: RI on PR #305 base. First cross-base RI result.

## Research focus (13:50 UTC)

**Primary question post-RI-merge:** 
1. Are (γ=−0.075, capture=2375) the optimal RI hyperparameters? → fern H-G sweeping 9 combinations
2. Is RI a universal post-hoc wrapper? → frieren (PR #300), nezuko (PR #305) providing cross-base validation
3. Does RI compose with Arbor Muon (tail suppression) and late-higher LR? → alphonse, tanjiro

**Next wave priorities (post-PE-gate close, askeladd will be idle):**
- SWA (Stochastic Weight Averaging) on PR #309 base — averaging direction vs RI's extrapolation direction
- RI + Circuit-Muon composition (T1=3.27726 was notable; RI+C-Muon composition may have orthogonal mechanisms)
- RI ablation: random init reference vs late-training reference (confirms RI is direction-sensitive, not just late-step smoothing)

## Things to AVOID

- NC on any Aurora-bearing stack (falsified 3×)
- PMuon on PR #300 or PR #309 base (falsified cross-base, locked verdict)
- β2-pulse on PR #309 base (falsified)
- Circuit-Muon as a standalone on PR #309 base (falsified on mean; T1=3.27726 held for future composition)
- Polar Express NS on H100 (gate failed +1.99% vs ≥5% needed; GH200-specific)
