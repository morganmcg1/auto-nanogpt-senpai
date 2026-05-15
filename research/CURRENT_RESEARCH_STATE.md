# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 15:35 UTC
- **Most recent human-team directive:** None received.
- **Branch state:** 1 commit beyond seed (cc1c710 — `sample_tensor` clamp fix).
  No experiment PRs merged yet. Wave 1 is in flight with mixed results: some
  ideas crashed in smoke, some are healthy, one finished at near-baseline,
  several need rework.

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, and batch size fixed; optimizer, schedule, init, telemetry editable.

## Wave 1 — current status

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #51 | alphonse | NorMuon (Muon + Adafactor row/col precond) | 4 smoke runs NaN at step 300 | EMA-bug fix sent; rerun after rebase |
| #52 | askeladd | MuonH + per-module init std | Smoke ok (active_fraction 0.99) | Acknowledged clip-only variant + rebase; screen running |
| #53 | edward | Contra-Muon | Screen val=3.281 @ 3350 (n=1 miss) | Confirm at 3225 × 4 seeds; rebase reminder |
| #54 | fern | SOAP-on-MLP precond before NS | NaN by step 140 (multiple smokes) | Eigval-clamp + 50-step precond warmup + float64 state sent |
| #55 | frieren | MuLoCo outer Nesterov wrapper | Screen at step 3125 val=3.300 (healthy, ~225 to go) | Let run |
| #56 | nezuko | Lion replacing AdamW + Muon | LR sweep step 2100 val=5.37 (Lion struggling at this scale) | Let LR sweep finish; expect to close as negative result |
| #57 | tanjiro | Per-module init std on plain Muon | Screen finished val=3.2858 (>3.28; no improvement vs baseline) | Wait for student to post terminal results |
| #58 | thorfinn | Cooldown shape × frac sweep | 1-GPU plain-Muon NaN-blocker | Warmup guidance + sample_tensor fix + kill gates sent |

## Key learnings from wave 1 so far

1. **Starter `sample_tensor` had an OOB bug** for tensors with `n > 2^24` (embed.weight). Three students caught it; cherry-picked the fix (commit `cc1c710`) so wave 2 inherits a clean starter.
2. **Plain Muon at 1 GPU with default init is NaN-unstable.** thorfinn's evidence + cross-W&B audit: every successful 1-GPU run uses either non-default init (smaller per-module std) or an adaptive preconditioner (NorMuon, SOAP, MuonH, etc.). For experiments that depend on plain Muon stability, **add a short LR warmup** (~100 steps).
3. **My NorMuon spec had an EMA bug** (`row_var.add_(g², alpha=1-beta2)` without `mul_(beta2)` first), which is the likely root cause of alphonse's NaN. Caught from W&B audit. Fix already sent.
4. **My SOAP spec underspecified `_matrix_power`** stability and didn't include a preconditioner warmup, which is the likely root cause of fern's NaN. Fix already sent.
5. **Per-module init alone doesn't move the needle** at our config: tanjiro 1-seed `val=3.2858` is consistent with baseline. Worth re-evaluating with more seeds, but not a strong lever in isolation.

## Current research focus and themes

- **Bedrock exploitation in flight:** Contra-Muon (edward), MuonH (askeladd),
  NorMuon (alphonse, after fix), MuLoCo (frieren), SOAP-MLP (fern, after fix).
- **Bold probe:** Lion (nezuko) — likely to close as negative result this wave.
- **Lever isolation:** init std (tanjiro — appears weak in isolation),
  cooldown shape (thorfinn, pending warmup retry).
- **Operational unblock:** add 100-step warmup to any plain-Muon 1-GPU run.

## Next research directions (wave 2 candidates)

Triggered after wave 1 winners are merged:

1. **Stack confirmed winners** — Contra-Muon × NorMuon (= public #11), and
   then add MuonH or SOAP-MLP to it. Stacking should compound step savings.
2. **Soft-Muon interpolation** (public #20 component) — sign-modulated
   interpolation between Muon and Contra-Muon directions.
3. **MuonSquared** (public #7) — squared NS update, lr=0.10 wd=0.0125,
   single SOTA-class result with a clean implementation.
4. **u/w-floor weight-decay alternative** (public #9 component) — clamp
   `||u||_F / ||w||_F` to 0.35 in place of weight decay; clean swap.
5. **PSGD-Kron** — Kronecker-factored preconditioner with lr=0.0005 wd=0.625
   (public guidance from track-3 README); a fresh preconditioner that hasn't
   been pulled in yet.
6. **Adafactor-style aux** — currently aux is plain AdamW; replace with
   Adafactor or Adafactor-with-momentum for embed/lm_head and compare.
7. **Schedule innovation post-thorfinn:** if cosine wins thorfinn's sweep,
   try schedule-free Muon next; if linear wins, try trapezoidal.

## Operational notes

- All 8 students currently have active WIP PRs with concrete actions. No
  idle GPUs.
- Standard kill gates established: NaN `val/loss` or non-finite
  `train/grad/global_norm` → kill trial, post failure mode, no retry.
- Step budgets: tiny (≤300) smoke, short (1500–2500) screening, full (≥3000)
  confirmation. Predeclare seed/step count for confirmation runs.
- Banned reference sources: Prime Intellect autonomous-run materials.
