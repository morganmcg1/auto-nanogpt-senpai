# SENPAI Research Results — auto-nanogpt-1gpu-r2

## 2026-05-16 01:45 — PR #79: MuLoCo on plain Muon — CLOSED (all 4 corners missed)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- Final W&B sweep runs:

| run | si | outer_lr | train_steps | val/loss | reached |
| --- | --- | --- | --- | --- | --- |
| `bqfv4523` | 15 | 0.5 | 3300 | 3.2829 | 0 |
| `q57yhybv` | 30 | 0.7 | 3300 | 3.2810 | 0 |
| `ecohqy9o` | 15 | 0.7 | 3300 | 3.2815 | 0 |
| `v2wn0t8t` | 60 | 0.5 | 3300 | **3.2865** | 0 |

- Conclusion: All 4 sweep corners failed to reach 3.28. The si=60/lr=0.5 corner
  (meant to allow longer inner runs between outer steps) was actually the **worst**
  result. Plain Muon's NS5 orthogonalization already smooths the gradient direction
  — MuLoCo's outer Nesterov momentum provides no additional benefit. Public record
  #13's success was likely driven by MuLoCo wrapping NorMuon (which has noisy
  per-element variance), not plain Muon.
- Status: **CLOSED (dead end)**. Frieren reassigned to MuLoCo+NorMuon (PR #109).

## 2026-05-16 01:50 — PR #81: Newton-Muon — n=4 confirmation at train_steps=3275 (terminal, non-statsig)
- Branch: `g1r2-tanjiro/newton-muon`
- Hypothesis: Activation-covariance right-preconditioning applied to the Muon
  gradient before Newton-Schulz (refresh every 64 steps).
- W&B run: `xsb35b0m` | num_trials=4 | train_steps=3275

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.279715 | 3275 |
| T1 | 3.278674 | 3250 |
| T2 | **3.277678** | **3225** |
| T3 | 3.281277 | -1 (missed) |
| **n=4 mean** | **3.27934** | — |

- Statsig check: `(3.28 - 3.27934) × √4 = 0.001328` — BELOW 0.004. **Non-statsig.**
- Analysis: T0–T2 all cleared 3.28 individually, including T2 at 3.2777 (among
  the best individual trials in wave 1). T3 was a bad seed — 3.2813 — above the
  target, which dragged the mean to 3.279. The recipe is real but has high
  seed variance. Needs more cooldown steps to tighten the distribution.
- Status: WIP. Sent back for fresh n=4 at predeclared `train_steps=3325`.

## 2026-05-15 23:20 — PR #79: MuLoCo on plain Muon — sweep arm si=15 (terminal)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- W&B run: `ecohqy9o` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/ecohqy9o`)
  | num_trials=1 | train_steps=3300 | sync_interval=15, outer_lr=0.7
- Result: terminal **val/loss=3.2815 @ step 3300**,
  `speedrun/final_first_step_to_target=-1`, `speedrun/final_reached_target=0`.
  **Did NOT cross 3.28.**
- Context: 3rd consecutive single-seed screen to miss — `bqfv4523`=3.2829,
  `q57yhybv`=3.2810, `ecohqy9o`=3.2815. All at or above 3.281 margin.
- Conclusion: MuLoCo on plain Muon appears break-even or slightly worse than
  starter at train_steps=3300. si=60/lr=0.5 corner still pending. If that
  corner also misses ≥ 3.281, MuLoCo-on-plain-Muon is dead and frieren will
  be pivoted to MuLoCo wrapping a confirmed inner optimizer (NorMuon or
  Contra-Muon, per the approach of public record #13).
- Status: WIP. si=60 sweep arm pending.

## 2026-05-15 22:45 — PR #80: Muon² (Adam variance BEFORE Newton-Schulz) — single-seed screen
- Branch: `g1r2-nezuko/muon-sq`
- Hypothesis: Per-element Adam variance applied to gradients *before* the
  Newton-Schulz orthogonalization should preserve NorMuon's variance-normalization
  benefit while keeping the orthogonalization geometry clean. lr=0.10, wd=0.0125,
  β₂=0.95, train_steps=3350 (per record #7 / nezuko PR body).
- W&B run: `n18mqjfy`
  (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/n18mqjfy`) | num_trials=1 |
  train_steps=3350.
- Result: terminal **val/loss=3.2773 @ step 3350**,
  `speedrun/final_first_step_to_target=3300`, `reached_target=1`.
- Statsig at n=1 (informational): (3.28 − 3.2773) × √1 = 0.0027 — does NOT
  clear the 0.004 single-seed bar, but is below 3.28 and on track for n=4
  consideration with cooldown headroom.
- Status: WIP. n=4 confirmation `7lxk02m6` launched (T0 early at step 275).
  Single-seed margin smaller than edward/fern/alphonse, so n=4 statsig is
  uncertain; will need mean ≤ 3.278 across 4 seeds.

## 2026-05-15 20:30 — PR #74: NorMuonH (row/col variance + hyperball + per-module init std)
- Branch: `g1r2-askeladd/normuonh-perinit`
- Hypothesis: NorMuon's row/col Adafactor-style variance combined with hyperball
  constraint (preserve ‖p‖_F per step) and per-module init std (×1.25 attn.proj,
  zero block-level proj for residual-branch safety) should reduce optimizer
  steps. Public record #8: 3225 steps, mean val/loss 3.2776 (n=10).
- W&B run: `sohiul20` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/sohiul20`)
  | num_trials=4 | train_steps=3250 (predeclared confirmation).
- Per-trial final val/loss at step 3250:
  | trial | val/loss |
  | --- | --- |
  | 0 | 3.27849 |
  | 1 | 3.27942 |
  | 2 | 3.27835 |
  | 3 | 3.27840 |
  | **mean** | **3.27867** |
  | std | ~0.0005 |
- `speedrun/final_first_step_to_target = 3225`, all 4 trials cleared 3.28.
- Statsig check (rule `(3.28 − μ) × √n ≥ 0.004`): (3.28 − 3.27867) × 2 =
  **0.00267** — below the 0.004 threshold at n=4. **Not statsig.**
- Conclusion: NorMuonH is a real, reproducible recipe (very tight inter-seed
  variance) but its mean at step 3250 falls 0.0007 above the statsig ceiling.
  Adding more seeds at step 3250 would not help (mean too stable). Sent back
  asking for a fresh n=4 batch at a predeclared step ∈ {3275, 3300} to gain
  ~0.001 of cooldown headroom for statsig clearance.
- Status: WIP / not merged. Awaiting follow-up predeclared confirmation.
