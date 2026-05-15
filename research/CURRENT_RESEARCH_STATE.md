# SENPAI Research State — `auto-nanogpt-r1`

- 2026-05-15 (Wave 1 assigned, all 8 students busy)
- Most recent human researcher directive: none yet.
- Current research focus: **lower `speedrun/final_first_step_to_target` on the
  modded-nanogpt track-3 optimizer benchmark**, starting from the in-repo
  `Muon + aux AdamW, lr=0.035 wd=0.025, 3350 steps` baseline. Treat each public
  track-3 record as one component that can be ported and stacked individually.
- The current public global best is record #20 at 3030 steps (Contra-Muon →
  Soft-Muon interp + SOAP MLP + SOAP attn.v + power-law cooldown). We do not
  need to ship that exact stack; we just need to beat the in-repo baseline by a
  statistically significant margin per `(3.28 - mu) * sqrt(n) >= 0.004`.

## Wave 1 portfolio (assigned 2026-05-15)

| PR  | Student     | Slug                          | Family            | Status   | Notes |
| --- | ----------- | ----------------------------- | ----------------- | -------- | ----- |
| #12 | r1-alphonse | lookahead-on-baseline         | outer-loop        | WIP      | Lookahead sweep on simple baseline |
| #18 | r1-askeladd | trapezoidal-lr-short-cooldown | schedule          | **closed (failed)** | cf=0.2 val/loss 3.329 vs target 3.28; cooldown is load-bearing. Bug fix cherry-picked. |
| #27 | r1-edward   | normuon-port                  | preconditioner    | WIP      | Paper-faithful post-NS single-axis after advisor send-back |
| #28 | r1-fern     | schedule-free-muon            | schedule          | WIP      | Polyak iterate averaging, constant LR for Muon group |
| #29 | r1-frieren  | mup-perlayer-lr-scaling       | optimizer-hparam  | WIP      | Attn vs MLP LR split |
| #30 | r1-nezuko   | post-ns-nesterov              | optimizer-update  | WIP      | Nesterov applied in orthogonalized space |
| #31 | r1-tanjiro  | spectral-weight-decay         | regularization    | WIP      | Rank-1 spectral WD vs L2 WD on Muon params |
| #32 | r1-thorfinn | adopt-aux-optimizer           | optimizer         | WIP      | ADOPT replaces AdamW for embed/lm_head/scalar aux groups |
| #41 | r1-askeladd | pmuon-bilateral-cov-precond   | preconditioner    | WIP      | Port PMuon (record #18) — bilateral streaming cov precond before polar |

## Themes for the opening wave

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

## Potential next research directions (wave-2 reserves)

Records-aligned ports we have NOT yet assigned this wave (high leverage):
- **Contra-Muon** technique (record #11 worth ~25 steps on top of NorMuon).
- **SOAP-MLP** Shampoo-eigen precond before NS for `mlp.fc/mlp.proj` weights
  (record #14 worth ~100 steps on top of Contra-Muon).
- **MuLoCo outer-Nesterov** wrapper around the inner optimizer (record #13).
- **PMuon** bilateral covariance preconditioning before polar (record #18).
- **MuonH hyperball constraint** + per-module init std (record #5).
- **Newton-Muon** activation-covariance right-precond every 64 steps (#15).
- **Power-law cooldown** `c*(t_end-step)^1.2` from record #20's tuned schedule.
- **KL-SOAP-H** with `precond_freq=1` (record #19).

Fresh / underexplored mechanisms not yet in the records:
- **Lion** / SignSGD-Muon hybrid for the Muon group.
- **Sophia** Hessian-diagonal preconditioner for aux groups.
- **CASPR** / Distributed-Shampoo variants on full param set.
- **EMA / SWA** weight averaging on the Muon group only.
- **μP / μ-transfer** re-init that scales weights so effective LR is uniform.
- **Adaptive NS iteration count** based on momentum spectral norm.
- **Restarting** schedules (SGDR cosine restarts with decreasing amplitude).
- **Layer-wise grad-norm-aware LR** (per-layer LR scaled by trailing grad RMS).

After wave-1 results land, prioritize stacking the proven winners (e.g.
NorMuon + Lookahead, or schedule-free + post-NS-Nesterov) and pruning the
non-load-bearing components.

This file is a living document. Prune entries that have been tried, add new
ones as the portfolio evolves.
