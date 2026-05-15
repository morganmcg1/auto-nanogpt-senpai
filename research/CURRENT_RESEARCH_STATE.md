# SENPAI Research State

- **Date**: 2026-05-15 (launch day, fresh advisor pod)
- **Most recent research direction from human researcher team**: None yet (no GitHub Issues addressed to advisor / launch fresh).
- **Current research focus**: Modded-NanoGPT track 3 optimization benchmark. Reduce optimizer steps to reach FineWeb val cross-entropy ≤ 3.28 while satisfying `(3.28 - mu) * sqrt(n) >= 0.004`.

## Current best (auto-nanogpt-r5)

Starter script reference baseline: plain Muon (lr=0.035, wd=0.025, mu=0.95, 12 NS iter) + aux AdamW, 3350 steps. No improvements landed yet — round 1 in flight.

## Wave-1 portfolio (assigned 2026-05-15)

Balanced across exploitation of known public stacks and fresh exploration:

- **Exploit/reproduce**: `muonh-baseline` (alphonse), `normuon-h` (askeladd).
- **Exploit/tune** (schedule/numerics): `cooldown-shape-sweep` (edward), `ns-iter-sweep` (frieren).
- **Explore (wrappers / new mechanism)**: `lookahead-muon` (fern), `muon-squared` (nezuko), `soap-muon-mlp` (tanjiro), `polyak-tail-avg` (thorfinn).

## Next research directions (wave-2 candidates)

Once wave-1 results arrive, candidate next experiments:

1. **Contra-Muon** (orthogonal column subspace anti-correlation) layered onto whichever stack wins wave-1.
2. **MuLoCo outer-Nesterov wrap** (DiLoCo-style) — distributes communication step.
3. **PSGD-Kron** preconditioner — fundamentally different paradigm; the public README hints `lr=0.0005 wd=0.625` is reasonable.
4. **u/w-floor hyperball** (skylight001 setup) — replaces weight decay with norm clamp.
5. **Per-parameter-type momentum/LR coupling** — different mu/lr for qkv vs proj vs mlp.
6. **Trust-gated SOAP** — TrustLight-style cosine gate on second-order directions.
7. **Per-module hyperball alongside u/w-floor** — combine #5 + #9 from public history.
8. **Schedule-free / parameter-free optimizers** (D-adaptation, Prodigy, etc.) — less hand-tuning.

## Plateau-protocol watch list

If 5+ consecutive experiments yield no improvement, escalate by reading the worst predictions, checking gradient/parameter telemetry distributions, and switching strategy tier (architecture → loss → data representation considerations are off-limits per the contract; that leaves: optimizer/schedule architecture). The researcher-agent can be re-tasked then with a deeper literature dive.
