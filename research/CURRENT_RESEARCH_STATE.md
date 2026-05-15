# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 19:05 UTC
- **Most recent human-team directive:** None received.
- **Branch state:** 1 commit beyond seed (cc1c710 — `sample_tensor` clamp fix).
  No experiment PRs merged yet. Wave 1 is ~6.5 hours in:
  - 1 PR has a clean target-reaching single-seed run (frieren #55 MuLoCo, val=3.2793 ffs=3325). In n=4 confirmation.
  - 1 PR finished sub-target (askeladd #52 MuonH clip-only, val=3.2917 ffs=-1). Variant follow-ups requested.
  - 1 PR is a confirmed negative (nezuko #56 Lion-everywhere). Asked to close.
  - 1 PR is finishing 2nd seed of a weak-lever isolation (tanjiro #57 per-module init).
  - 1 PR has a 4-seed confirmation in flight (edward #53 Contra-Muon).
  - 1 PR delivered a clean root-cause diagnosis (fern #54 SOAP): SOAPMuon is correct, the NaN is the upstream `torch.compile`/plain-Muon-default-init bug. Sent: apply per-module init + smoke v5; fallback = disable `@torch.compile`.
  - 2 PRs are still iterating on stability fixes: alphonse #51 (NorMuon, after EMA fix), thorfinn #58 (cooldown sweep, warmup-100 also failed).

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, and batch size fixed; optimizer, schedule, init, telemetry editable.

## Wave 1 — current status

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #51 | alphonse | NorMuon (after EMA fix) | New `confirm3300` run @ step 25 | Let run; check at step 300+ |
| #52 | askeladd | MuonH clip-only | Screen finished val=3.2917 ffs=-1 (miss) | Sent: budget_mult sweep + per-module init; then always-active variant |
| #53 | edward | Contra-Muon | n=4 confirmation @ 3225 launched, step 1 | Let confirmation run |
| #54 | fern | SOAP-MLP precond before NS | Root-caused NaN to upstream `torch.compile` plain-Muon bug; SOAP code is correct | Sent: apply per-module init + smoke v5; fallback = disable `@torch.compile` |
| #55 | frieren | MuLoCo outer Nesterov | Screen finished val=3.2793 ffs=3325 (n=1, miss stat rule) | Sent: n=4 confirm @ 3300; sweep outer_lr×outer_momentum if miss |
| #56 | nezuko | Lion replacing AdamW + Muon | LR sweep diverged (val=6.64); best Lion-flavored val=3.31 (worse than baseline) | Sent: stop, post negative SENPAI-RESULT, swap to review for close |
| #57 | tanjiro | Per-module init std (plain Muon) | s0 finished val=3.2858 ffs=-1; s1 mid-run | Sent: let s1 finish, post 2-seed negative, close |
| #58 | thorfinn | Cooldown shape × frac sweep | Warmup-100 fix also failed @ step 3 | Sent: per-module init diagnostic smokes A & B before sweep |

## Key learnings from wave 1 so far

1. **Starter `sample_tensor` had an OOB bug** for tensors with `n > 2^24` (embed.weight). Three students caught it; cherry-picked the fix (commit `cc1c710`) so wave 2 inherits a clean starter.
2. **Plain Muon at 1 GPU with default init is NaN-unstable, and the unstable lever is *init*, not the schedule.** thorfinn's 100-step LR warmup failed at step 3, while tanjiro's per-module-init plain Muon (no warmup, no compile change) is the only stable 1-GPU plain-Muon configuration on this branch. Fern's PR #54 diagnostic (W&B runs `dlv7rkck`, `tce8dakn`, `zoqo0l97`) cross-references alphonse's PR #59 on `auto-nanogpt-1gpu-r1` showing the underlying cause is a `torch.compile` Inductor kernel-emission bug producing NaN in `blocks.0.attn.proj.bias.grad` at step 1, which then propagates via `dist.all_reduce(SUM)` to every rank. **For any future plain-Muon 1-GPU experiment, fold per-module init std in by default**: `attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031`. If per-module init isn't applicable, disable `@torch.compile` on the train step (justifiable since the comparison axis is step count, not wallclock).
3. **My NorMuon spec had an EMA bug** (`row_var.add_(g², alpha=1-beta2)` without `mul_(beta2)` first), the likely root cause of alphonse's NaN. Fix sent.
4. **My SOAP spec underspecified `_matrix_power`** stability and didn't include a preconditioner warmup, the likely root cause of fern's NaN. Fix sent, still failing — may need a more conservative restart (skip preconditioner entirely on first 100 steps, or precondition only attention).
5. **Per-module init alone doesn't move the needle** at our config: tanjiro 1-seed `val=3.2858, ffs=-1` is consistent with baseline. It's a free-rider lever — apply on top of algorithmic winners.
6. **MuonH clip-only is meaningfully weaker than always-active.** askeladd's clip-only screen (n=1, `val=3.2917, ffs=-1`) misses public #5 always-active (`val=3.2782, ffs=3325` n=10) by 0.014 val + the target line. Default to always-active for any future Frobenius-ball variant.
7. **MuLoCo wrapper is a positive signal.** frieren's screen reached the 3.28 line with plain-Muon inside MuLoCo — the first wave-1 PR to do so. n=4 confirmation will tell whether the wrapper alone is worth merging.
8. **Lion at this scale is dead.** nezuko's lion-everywhere LR sweep diverged to val=6.64; lion-on-aux only reached val=3.31. Closing as documented negative.

## Current research focus and themes

- **Confirmation-pass priority:** frieren #55 (MuLoCo n=4) and edward #53 (Contra-Muon n=4) are both in the highest-leverage state right now — either could merge in the next iteration if their confirmation mean satisfies the statistical rule.
- **Bug recovery in flight:** alphonse #51 (NorMuon EMA fix), fern #54 (SOAP precond warmup). One more iteration each before deciding to close.
- **Variant exploration:** askeladd #52 (MuonH budget sweep + per-module init), thorfinn #58 (per-module init diagnostic + cooldown sweep).
- **Closing:** nezuko #56 (Lion negative), tanjiro #57 (init-only negative after s1).

## Next research directions (wave 2 candidates)

Triggered after wave 1 winners are merged. Prioritized list:

1. **Stack confirmed winners** — if MuLoCo merges, immediately try MuLoCo × Contra-Muon and MuLoCo × NorMuon (= public #13).
2. **Always-active MuonH + per-module init** — if askeladd's clip-only variant continues to underperform, run the reference always-active scale_invariant_update_ variant to reproduce public #5.
3. **Soft-Muon interpolation** (public #20 component) — sign-modulated interpolation between Muon and Contra-Muon directions.
4. **MuonSquared** (public #7) — squared NS update, lr=0.10 wd=0.0125, single SOTA-class result with a clean implementation. Good for nezuko's freed slot.
5. **u/w-floor weight-decay alternative** (public #9 component) — clamp `||u||_F / ||w||_F` to 0.35 in place of weight decay; clean swap.
6. **PSGD-Kron** — Kronecker-factored preconditioner with lr=0.0005 wd=0.625; a fresh preconditioner that hasn't been pulled in yet. Good for tanjiro's freed slot.
7. **Adafactor aux** — currently aux is AdamW; replace with Adafactor or Adafactor-with-momentum for embed/lm_head.
8. **Schedule innovation post-thorfinn:** if cosine wins the (eventually launched) thorfinn sweep, try schedule-free Muon next; if linear wins, try trapezoidal.

## Operational notes

- All 8 students currently have active WIP PRs with concrete actions. No idle GPUs yet, but nezuko #56 and tanjiro #57 may free up within the next 1–2 iterations.
- Standard kill gates established: NaN `val/loss` or non-finite `train/grad/global_norm` → kill trial, post failure mode, no retry.
- Step budgets: tiny (≤300) smoke, short (1500–2500) screening, full (≥3000) confirmation. Predeclare seed/step count for confirmation runs.
- Confirmation rule: any merge claim needs `(3.28 - mu) * sqrt(n) >= 0.004` and `n >= 4`. No cherry-picking of seeds or arms.
- Banned reference sources: Prime Intellect autonomous-run materials.
