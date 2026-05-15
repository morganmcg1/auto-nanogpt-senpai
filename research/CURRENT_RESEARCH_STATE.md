# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-15 19:00 UTC (wave 1 closing, new assignments issued)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)
- **Wave 1 best (pending terminal PR):** alphonse Muon² at **3275 steps** (n=2 stat-sig confirmed, val≈3.2765)

## STAT-SIG CONFIRMED HOT result — alphonse Muon² (#60)

- Arm-A NS=12, seed 1: val=3.2766, first_step_to_target=3275 (run s0oq3dnx)
- Arm-A NS=12, seed 2: val=3.2765, first_step_to_target=3275 (run 4hedrgf4)
- **n=2 stat-sig**: mu=3.27655, (3.28-3.27655)*sqrt(2) = 0.00488 >= 0.004 ✓
- Arm-B (NS=8) still running — if NS=8 matches or beats NS=12, confirmation can stack there
- **Action taken**: commented on PR to inform of stat-sig pass, told to post terminal SENPAI-RESULT after Arm-B finishes

## Other HOT results (not yet stat-sig)

| PR | Student | Recipe | val/loss (best) | first_step_to_target | Status |
|----|---------|--------|-----------------:|----------------------|--------|
| #60 | alphonse | Muon² (NS=12) | **3.2765** | **3275** | **Stat-sig n=2 ✓** — Arm-B (NS=8) running |
| #70 | fern | cooldown_frac=0.5 | 3.2790/3.2793 (n=2) | 3325–3350 | Seed 3 running; n=2 margin 0.0012 < 0.004 |
| #75 | tanjiro | NS=8 (compute headroom) | 3.2785 | 3325 | NS=6 running; needs stat-sig confirmation seeds |

**Critical methodology**: Two baseline noise crossings (tanjiro NS=12 = starter recipe, nezuko wd_warmup=0.00) confirmed single-seed crossings are within natural seed variance. Stat-sig is the binding constraint.

## Closed PRs this wave

| PR | Student | Result |
|----|---------|--------|
| #62 | askeladd | SF-Muon FAILED (best 3.3638, 0.084 nats above target). Cooldown is load-bearing — SF can't substitute. |
| #77 | thorfinn | Lion aux groups FAILED (best 3.3109). AdamW is better for small aux groups. |

## Active wave 1 PRs (8 total)

| PR | Student | Hypothesis | Latest status |
|----|---------|-----------|---------------|
| #60 | alphonse | Muon² (NS=12/8 arms) | Arm-B running; stat-sig confirmed at NS=12 n=2 |
| #66 | edward | Cosine vs linear cooldown | NaN bug at step 3; advisor sent debug guidance |
| #70 | fern | Cooldown frac=0.5 | Confirmation seed 3 running; ETA ~21:45 UTC |
| #72 | frieren | Nesterov mu sweep 0.90–0.98 | mu=0.97 hit precision bug (val=10.826); advisor asked to patch + add mu=0.98 |
| #73 | nezuko | WD warmup schedule | Arm-B running; Arm-A was baseline noise crossing |
| #75 | tanjiro | NS iter sweep 12/8/6 | NS=6 running; NS=8 marginally better than NS=12 |
| #90 | askeladd | **NEW**: muP LR sweep (0.025/0.030/0.035/0.042) | Newly assigned — pod will pick up |
| #91 | thorfinn | **NEW**: Adaptive aspect-ratio scaling for Muon | Newly assigned — pod will pick up |

## Key findings from wave 1

1. **Muon² works**: 2-seed stat-sig confirmed at 3275 steps (50 steps faster than baseline noise crossings). Mechanism: Adam 2nd-moment preconditioning before NS produces a better-conditioned matrix, reducing effective NS work. Paper-aligned (arXiv:2504.09967).

2. **Cooldown shape matters a lot**: SF-Muon failed because the 70% linear LR cooldown is doing real work collapsing parameters into a sharp basin — it is not replaceable with running-average trajectory smoothing. Understanding WHY the final 1000 steps drop loss so fast is high-value future research.

3. **NS iterations have headroom**: NS=8 matches NS=12 at val/loss (both ~3.278-3.279), suggesting the 12-iteration count has computational slack. Enables either (a) NS=8 going forward to save ~33% NS cost per step, or (b) using the freed compute for more train steps.

4. **Lion doesn't work for aux groups**: Sign-momentum is too lossy for the small embed/head/scalar groups where AdamW already provides efficient per-element scaling.

5. **Baseline noise crossings**: The unmodified starter recipe can cross 3.28 in single seeds (tanjiro NS=12, nezuko wd_warmup=0.00). Single-seed results are unreliable. n>=2 with stat-sig is the binding constraint.

## Current research focus and themes

The leaderboard is dominated by **matrix preconditioners stacked on Muon**:
Contra-Muon (correlation correction), Soft-Muon (smooth polar relaxation), Aurora (leverage equilibration), Newton-Muon (activation-covariance right precond), NorMuon (row/col variance), PMuon (bilateral covariance power), SOAP / KL-SOAP (Shampoo-style with diagonal Adam in eigenbasis), hyperball constraints, MuLoCo outer Nesterov.

Wave 1 established:
- Muon² (2nd-moment preconditioning before NS) is our first confirmed mechanism
- NS=8 is equivalent to NS=12 — enabling compute headroom
- Schedule-Free and Lion are dead ends for this benchmark

## Potential next research directions (wave 2 candidates)

**Highest priority** (informed by wave 1):
- **Muon² + reduced NS iterations**: if alphonse's Arm-B (NS=8) also beats 3.28, run Muon²+NS=8 as combined win
- **Port SOAP-Muon recipe** (#14/#16 from leaderboard) into train script — biggest lever to close gap to SOTA 3030
- **Compose schedule wins**: if cosine cooldown (#66) or frac=0.5 (#70) both win individually, compose them
- **Muon² + Contra-Soft stack**: if Muon² is confirmed, try combining with Contra-Soft-Muon (the additive preconditioning + direction correction)

**Diagnostic** (wave 1 gaps):
- **Newton-Muon port** (#15 from leaderboard) — activation-covariance right-preconditioning, never combined with our pruning experiments
- **Ablate Contra-Soft from #20** (H03) — once/if #20 stack is ported, cheap diagnostic
- **muP LR scaling sweep** (H05) — askeladd running; will confirm whether 0.035 is optimal

**Novel mechanisms not yet tried**:
- **Adaptive aspect-ratio scaling** (H14) — thorfinn running; tests calibration of Muon update formula
- **Per-layer LR scaling** (H16) — layer-wise LR adaptation via gradient norm ratios
- **Orthogonal QKV init** — spectral initialization for attention weights
- **Aurora (#17) with Soft-Muon layered on** — systematic stack expansion

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials
  (`https://www.primeintellect.ai/auto-nanogpt` and the
  `experiments-autonomous-speedrunning` repo).
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- No per-run val-loss early stopping.
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`
- Infrastructure: `sample_tensor` float32 OOB bug fix is in multiple student branches (nezuko canonical); will land on advisor branch when nezuko's PR merges.
- GitHub rate limit: cyclic issue — hit 0/5000 at 18:40 UTC, resets ~19:20 UTC.
