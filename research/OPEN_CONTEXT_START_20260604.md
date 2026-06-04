# Open-Context Track 3 Launch Notes - 2026-06-04

This launch should exploit the full public `modded-nanogpt` Track 3 ecosystem:
merged records, open PRs, closed PRs, issues, result logs, public optimizer
writeups, and prior Senpai work. Public claims are idea sources until this
launch reproduces them under the official benchmark contract.

## Strongest Known Evidence

| Source | Status | Step | n | Mean val/loss | Notes |
|---|---:|---:|---:|---:|---|
| Senpai PR #1532 / #1614 | internal audited | 2905 | 32 | 3.279022187 | Aux Adam beta2 pulse plus PMuon/LR/EMA stack. Current Senpai best; use as a mechanism source and composition target. |
| KellerJordan PR #305 | official merged | 2925 | 8 | 3.27812750 | Late capped RRE overlay on #300. Current official public record in the merged README. |
| KellerJordan PR #300 | official merged | 2930 | 16 | 3.27844375 | Aurora on `mlp.proj`, radial brake lineage, extended Contra-Muon, no Soft-Muon/NorMuon-lite. |
| KellerJordan PR #294 | official merged | 2990 | 11 | 3.27866818 | Radial brake ancestor to #300. Mostly absorbed by #300/#305 but useful for ablations. |
| KellerJordan PR #303 | official merged | 3000 | 9 | 3.27779333 | SODA-style initialization anchor fade. Interesting orthogonal composition source. |

## Open/Closed PR Mining

The advisor should inspect all public `KellerJordan/modded-nanogpt` PRs and
issues, not only merged records. In particular, current open lower-step claims
around 2850-2900 are high-value idea sources, but they are not final evidence
until reproduced with fixed-step, non-cherry-picked runs in this launch.

For every borrowed idea, write down:

- Source PR/issue/log/paper URL.
- Whether the source was official merged, open, closed, or speculative.
- Which mechanism is being copied, pruned, or composed.
- What would falsify the idea under the official Track 3 rule.

## First Research Directions

- Port the Senpai #1532/#1614 beta2-pulse and PMuon/LR/EMA ideas onto newer
  public baselines, especially #300 and #305.
- Test whether #305's RRE overlay can be moved earlier, made layerwise, or
  combined with a declared EMA handoff without live-vs-EMA cherry-picking.
- Test orthogonal public ideas such as SODA-fade, Aurora/RRE refinements,
  Circuit/EMA/Nesterov-style open PR ideas, and optimizer-state interventions
  from closed PRs.
- Avoid spending the whole run on scalar retuning. Retuning is useful when it
  makes a new mechanism fair, but the goal is fresh optimizer machinery and
  clever compositions.

## Claim Discipline

Final claims must preserve the public benchmark contract: fixed FineWeb data,
fixed architecture, fixed batch size, one forward-backward pass per optimizer
step, standard validation cross-entropy, a fixed submitted step across all
seeds, and `(3.28 - mean) * sqrt(n) >= 0.004`.
