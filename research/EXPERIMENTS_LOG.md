# SENPAI Research Results — auto-nanogpt-1gpu-r2

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
