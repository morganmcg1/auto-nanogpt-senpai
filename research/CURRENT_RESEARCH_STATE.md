# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-15 15:40 UTC (wave 1 mid-flight)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)
- **Prior W&B context:** 62 runs in rounds 1–3, closest val/loss=3.2813 at step 3300 (none crossed 3.28).

## HOT signals (in-flight, n=1, not yet terminal) — 17:25 UTC

Four students have crossed val/loss < 3.28 in single seeds. Confirmation seeds are running for some but not all.

| PR | Student | Recipe | val/loss | first_step_to_target | Seeds queued? |
|----|---------|--------|---------:|---------------------:|---------------|
| #60 | alphonse | **Muon² (NS=12)** | 3.2766 | **3275** | seed 2 at step 1725; needs 1 more |
| #75 | tanjiro | NS=12 (baseline) | 3.2789 | 3325 | seed 2 + ns-8 arm running |
| #70 | fern | cooldown frac=0.5 | 3.2790 | 3325 | seed 2 at step 1600 |
| #73 | nezuko | wd_warmup_frac=0.00 (= baseline) | 3.2797 | 3350 | none — advisor asked to start arms B/C |

**Critical methodology**: 2 of 4 crossings (tanjiro NS=12, nezuko wd_warmup=0.00) are the **unmodified starter recipe with different seeds**. Prior 62 W&B rounds of this baseline never crossed 3.28. So single-seed crossings are within seed noise of the baseline itself; stat-sig (`(3.28 - mu) * sqrt(n) >= 0.004`) is the binding constraint.

Best real-mechanism candidate: **alphonse Muon²** at 3275 steps — 50 steps better than baseline crossings. If confirmed at n>=3 it's a worthwhile result (still far from SOTA 3030).

## Infrastructure bug discovered (nezuko, PR #73)

- `sample_tensor` (line 183 of `train_gpt_simple.py`) uses `torch.linspace(0, n-1, max_samples).long()` which fails for n > ~2^24 due to float32 precision. The embed gradient has 38.6M elements → idx OOB → CUDA crash at step 0.
- Many w1 wandb runs show val/loss=10.826 at step 0-1 as the failure signature.
- Fix (use float64 linspace + clamp) is in nezuko's PR. Will land on advisor branch when #73 merges; meanwhile other students are patching locally.

## Wave 1 — active assignments (8 PRs, all status:wip)

| PR | Student | Hypothesis | Category |
|----|---------|-----------|----------|
| #60 | g1r4-alphonse | Muon² (Adam-style 2nd-moment precond before NS) | New optimizer (bold) |
| #62 | g1r4-askeladd | Schedule-Free Muon (Polyak–Ruppert averaging) | New optimizer (bold) |
| #66 | g1r4-edward | Cosine vs linear cooldown shape (3 arms) | Schedule lever |
| #70 | g1r4-fern | Cooldown fraction 0.5/0.6/0.7 (3 arms) | Schedule lever |
| #72 | g1r4-frieren | Muon Nesterov mu sweep (5 arms, 0.90–0.98) | Hparam sweep |
| #73 | g1r4-nezuko | WD warmup (0 → 0.025 over first 10%) | Schedule lever |
| #75 | g1r4-tanjiro | NS iteration sweep (12/8/6) — compute headroom | Mechanism diagnostic |
| #77 | g1r4-thorfinn | Lion for aux groups (embed/head/scalars) | New optimizer (low-risk) |

## Current research focus and themes

The leaderboard is dominated by **matrix preconditioners stacked on Muon**:
Contra-Muon (correlation correction), Soft-Muon (smooth polar relaxation),
Aurora (leverage equilibration), Newton-Muon (activation-covariance right
precond), NorMuon (row/col variance), PMuon (bilateral covariance power),
SOAP / KL-SOAP (Shampoo-style with diagonal Adam in eigenbasis), hyperball
constraints, MuLoCo outer Nesterov.

The best recipe (#20) is a **complex stack** with multiple interpolation
schedules between mechanisms. This means three under-explored angles:

1. **Stack pruning / ablations** — which components in #20 are load-bearing?
2. **Clean novel optimizers** — Schedule-Free, sign-based (Lion), ADOPT,
   AdamMini, Sophia, AdaBelief, K-FAC / Shampoo variants, SWAN, Galore, etc.
3. **Schedules and initialization** — WSD cooldowns, momentum/WD schedules,
   spectral / structured init, μP-style parameterization.

## Potential next research directions (wave 2 candidates)

After wave 1 results land, prioritize:
- **Compose winning schedule changes**: if cosine (#66) AND extended stable phase (#70) both win individually, test their composition.
- **Compose WD warmup with the winning LR schedule**.
- **Port a SOAP-Muon recipe (#14 / #16)** into the train script to close the gap toward the public 3030-step SOTA.
- **Newton-Muon (#15)** port — never been combined with our pruning experiments.
- **PMuon (#18)** retune at higher seed count (the public record is only n=9).
- **Aurora (#17)** retune with Soft-Muon mechanism layered on.
- **muP-style LR scaling sweep** (researcher's H05) if base Muon LR matters.
- **AdamH / hyperball constraint** on hidden matrices.
- **Spectral / orthogonal QKV init**.

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials
  (`https://www.primeintellect.ai/auto-nanogpt` and the
  `experiments-autonomous-speedrunning` repo).
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- No per-run val-loss early stopping.
- Full ideas list: `/research/RESEARCH_IDEAS_2026-05-15_BOOT.md` (16 ideas H01–H16).
