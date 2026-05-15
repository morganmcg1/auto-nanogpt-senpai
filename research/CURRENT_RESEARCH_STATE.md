# SENPAI Research State — `auto-nanogpt-r1`

- 2026-05-15 (advisor boot, first wave forming)
- Most recent human researcher directive: none yet.
- Current research focus: **lower `speedrun/final_first_step_to_target` on the
  modded-nanogpt track-3 optimizer benchmark**, starting from the in-repo
  `Muon + aux AdamW, lr=0.035 wd=0.025, 3350 steps` baseline. Treat each public
  track-3 record as one component that can be ported and stacked individually.
- The current public global best is record #20 at 3030 steps (Contra-Muon →
  Soft-Muon interp + SOAP MLP + SOAP attn.v + power-law cooldown). We do not
  need to ship that exact stack; we just need to beat the in-repo baseline by a
  statistically significant margin per `(3.28 - mu) * sqrt(n) >= 0.004`.

## Themes for the opening wave

1. **Port single mechanisms from records onto the simple baseline.** NorMuon
   row/col precond, Contra-Muon, SOAP-MLP, MuonH hyperball, MuLoCo outer loop,
   Muon², PMuon, Newton-Muon. Each is a contained code change with a known
   record-level step gain.
2. **Schedule research.** Current schedule is trapezoidal `cooldown_frac=0.7`.
   Try power-law cooldown (record #20 uses `c*(t_end-step)^1.2`), trapezoidal
   warmup-stable-decay, cosine, schedule-free / Polyak averaging.
3. **Initialization research.** Per-module init std as in #4/#5 (attn.proj
   std=.026, mlp.proj/fc std=.031, qkv default). μP/μ-transfer width scaling.
4. **Fresh optimizer mechanisms.** Lion / Sophia / Schedule-Free / Adan /
   Lookahead / SignSGD-Muon / spectral-steering variants — pick a few to
   screen at 1 seed before committing to confirmation budgets.
5. **Ablation / pruning.** Once a stacked winner emerges, run pruning PRs to
   see which components were load-bearing.

## Potential next research directions (rolling)

- Stacked record reproductions (Contra-Soft-Muon, KL-SOAP-H, NorMuonH-MuLoCo)
  after their constituent pieces land individually.
- Width-aware (μP / μ-transfer) re-tune of Muon group LRs.
- Two-sided preconditioning variants (PMuon γ sweep, KL-SOAP precond_freq
  sweep).
- Polyak / EMA / SWA weight averaging applied only to the Muon group.
- Compute-aware schedules: spend more cooldown when Muon has lower frob-norm
  growth in the trailing window.
- Optimizer-aware initialization: scale init by predicted update norm so the
  effective LR is uniform across modules.

This file is a living document. Prune entries that have been tried, add new
ones as the portfolio evolves.
