# BASELINE — Auto-nanoGPT Open SOTA v2 (launch 2026-06-04)

Primary metric: `speedrun/final_first_step_to_target` (lower is better). Statistical
contract: `(3.28 - mu) * sqrt(n) >= 0.004` across `n` non-cherry-picked seeds.

## Current best to beat

| Rank | Source | Step | n | Mean val/loss | Margin | Notes |
|---:|---|---:|---:|---:|---:|---|
| 1 | KellerJordan PR #305 (merged) | **2925** | 8 | 3.27812750 | 0.005297 | Aurora + late capped RRE + Contra-Muon extended. Current official public record. |
| 2 | Senpai PR #1532/#1614 (internal audit) | 2905 | 32 | 3.279022187 | 0.005531 | Aux Adam beta2 pulse + PMuon/LR/EMA stack. Best internal but not on track-3-open-sota-v2 tag. |
| 3 | KellerJordan PR #300 (merged) | 2930 | 16 | 3.27844375 | — | Aurora row-balanced polar on `mlp.proj` + Contra-Muon ramp to 2500 + Muon momentum warmup/cooldown. |

The PR #305 result is treated as the launch baseline for "official, fully
auditable, fixed-step" comparisons. PR #1532/#1614 is the strongest internal
result but lives under different tags; this launch needs fresh
benchmark-valid evidence to claim parity or improvement.

Open public claims under 2900 steps (PR #318/#312/#311/#309/#307 at 2850–2900)
are valuable IDEA sources, not baselines, until we reproduce them under the
benchmark contract on our own infra.

## Update Procedure

When a PR on `auto-nanogpt-open-sota-v2-20260604` beats the baseline at a
declared fixed step with `n>=4` non-cherry-picked seeds and `(3.28 - mu) *
sqrt(n) >= 0.004`, update this file with:

- New rank-1 row pointing to the winning PR number, step, n, mean, margin,
  W&B run ids, and one-line mechanism summary.
- Demote the previous rank-1 row to rank 2 with a parenthetical "(previous
  baseline)".

Commit the update on the advisor branch.
