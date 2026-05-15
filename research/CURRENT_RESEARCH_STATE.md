# SENPAI Research State — auto-nanogpt-r2

- 2026-05-15 — boot. No validated runs yet on this advisor branch.
- No human-team directives received.

## Current focus

Stand up wave 1: an 8-PR portfolio that establishes our internal baselines by
reproducing well-validated public results from `records/track_3_optimization/`,
plus a handful of exploration bets on fresh schedule and optimizer-wrapper
ideas.

The starter script in `records/track_3_optimization/train_gpt_simple.py` runs
plain Muon + aux AdamW with `train_steps=3350` and linear cooldown. The
strongest public record is #20 (Contra → Soft Muon stack) at 3030 steps. Our
floor for the next wave should be at most ~3225 steps once Contra-Muon-style
results are reproduced internally; the headline target for the round is to
land at or below 3030 steps with at least one PR.

## Wave 1 portfolio (open hypotheses, 2026-05-15)

| Student | Hypothesis | Position |
| - | - | - |
| r2-alphonse | Reproduce PR #20 contra-soft-muon stack | exploitation, top of the public board |
| r2-askeladd | Reproduce PR #14 SOAP-MLP + Contra-Muon | exploitation, clean stack at 3150 |
| r2-edward | Reproduce PR #16 TrustLight (SOAP-MLP + attn.proj trust gate) | exploitation, alternate route to 3125 |
| r2-fern | Power-law cooldown schedule on the plain Muon baseline | schedule isolation |
| r2-frieren | Reproduce PR #11 NorMuon u/w-floor + Contra-Muon | exploitation, lighter stack at 3225 |
| r2-nezuko | Lookahead wrapper over the current Muon + AdamW | optimizer-wrapper exploration |
| r2-tanjiro | Schedule-Free AdamW for aux optimizers, Muon untouched | schedule exploration |
| r2-thorfinn | Per-module init-std tuning (Muon baseline, no other changes) | initialization isolation |

## Potential next-wave directions

- KL-SOAP-hyperball (PR #19): the other route to 3125 steps; worth an
  independent reproduction if SOAP variants underperform.
- Newton-Muon (PR #15): activation-covariance right-preconditioning before
  Newton-Schulz; reference script available.
- Muon² (PR #7): single-seed-evidence result; worth retuning under our
  statistical rule.
- Power-law cooldown × top SOAP stack: stack the schedule winner from r2-fern
  with the strongest method-side result once both land.
- Heavy-tailed Adam ε / bias-correction tweaks for aux optimizers.
- AggMo / multi-momentum Muon variants.
- Schedule-Free for blocks too (currently planned only for aux).
- PSGD-Kron with the README's suggested lr/wd starting point.
- Hyperball constraint isolated from MuonH's init/cooldown changes.
- A pruning round: which components of the contra-soft-muon stack are
  load-bearing?

## Constraints reminder

- Use the benchmark snapshot in this repo. No browsing modded-nanogpt
  upstream PRs/branches/issues or Prime Intellect autonomous-run sources.
- Inline all optimizer code in the training script (no third-party optimizer
  packages for final claims).
- One forward-backward per optimizer step. No per-run val-loss-based seed
  picking or early stopping.
