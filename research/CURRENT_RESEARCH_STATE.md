# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 19:35 UTC
- **Most recent human-team directive:** None received.
- **Branch state:** 1 commit beyond seed (cc1c710 — `sample_tensor` clamp fix).
  No experiment PRs merged yet. Wave 1 ~7 hours in. Wave 2 assignments begun.
  - PRs #56 (Lion) and #57 (per-module init) **closed as negative results**.
  - PRs #86 (nezuko MuonSquared) and #87 (tanjiro u/w-floor) **newly assigned**.
  - 3 confirmation runs in flight: frieren #55 n=4 @ step 1890/3300, edward #53 n=4 @ step 2254/3225, alphonse #51 @ step 2300/3300.
  - Wave 1 variance exploration: askeladd #52 (budget_mult=0.85 @ step 375), thorfinn #58 (per-module init diagnostics pending), fern #54 (smoke v5 with per-module init pending).

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, and batch size fixed; optimizer, schedule, init, telemetry editable.

## Wave 1 — current status

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #51 | alphonse | NorMuon (after EMA fix) | `normuon-clean-confirm3300` @ step 2300/3300, val=3.40 (healthy) | Let run |
| #52 | askeladd | MuonH clip-only | `budget0.85` probe @ step 375; prior screen crashed @ step 1825 | Let budget sweep run; will need per-module init for stability |
| #53 | edward | Contra-Muon | n=4 confirm `3225-n4` @ step 2254/3225, val=3.40 (healthy) | Let confirmation run |
| #54 | fern | SOAP-MLP precond before NS | SOAP code correct; awaiting smoke v5 with per-module init | Pending |
| #55 | frieren | MuLoCo outer Nesterov | n=4 confirm `3300-n4` @ step 1890/3300, val=3.47 (healthy) | Let confirmation run |
| #56 | ~~nezuko~~ | ~~Lion replacing AdamW + Muon~~ | CLOSED: negative result (val=6.64 diverged; best arm val=5.02) | — |
| #57 | ~~tanjiro~~ | ~~Per-module init std (plain Muon)~~ | CLOSED: negative result (n=2 mean val=3.286, ffs=-1) | — |
| #58 | thorfinn | Cooldown shape × frac sweep | warmup-100 also failed @ step 3; awaiting per-module init smokes A & B | Pending |

## Wave 2 — new assignments

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| #86 | nezuko | MuonSquared (squared NS update with Adam second-moment, public #7) | Just assigned |
| #87 | tanjiro | u/w-floor (update/weight norm floor = 0.35 replaces wd, public #9 component) | Just assigned |

## Key learnings from wave 1

1. **Starter `sample_tensor` had an OOB bug** for tensors with `n > 2^24` (embed.weight). Fix cherry-picked as `cc1c710`.
2. **Plain Muon at 1 GPU with default init is NaN-unstable, root cause: `torch.compile` Inductor kernel bug.** Produces NaN in `blocks.0.attn.proj.bias.grad` at step 1, propagates via `all_reduce(SUM)`. Fix: **per-module init std** (`attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031`) — the only stable 1-GPU plain-Muon config on this branch. Fallback: disable `@torch.compile`. LR warmup does NOT fix this (thorfinn warmup-100 also failed at step 3).
3. **My NorMuon spec had an EMA bug** (fixed, sent to alphonse). Alphonse's corrected rerun is mid-flight, healthy.
4. **My SOAP spec underspecified `_matrix_power`** (fixed, sent to fern). SOAP code v2 is correct; still blocked on per-module init stability prerequisite.
5. **Per-module init in isolation doesn't improve step count** (tanjiro n=2 val=3.286, ffs=-1). Free-rider lever — apply on top of algorithmic winners.
6. **MuonH clip-only is weaker than always-active variant.** Default to `scale_invariant_update_` for any future Frobenius-ball variant.
7. **MuLoCo wrapper is a promising signal.** frieren's screen reached the target (ffs=3325 n=1). n=4 confirmation in progress.
8. **Lion is a confirmed negative.** No arm reached val<4.0. Closed with documented sweep table.

## Current research focus and themes

- **Imminent results:** frieren #55 n=4 and edward #53 n=4 confirmations are ~30–60 min from completion. Either or both could be the first merges. alphonse #51 corrected NorMuon is also ~1000 steps from finishing.
- **Wave 2 exploration in parallel:** nezuko #86 (MuonSquared) and tanjiro #87 (u/w-floor) are freshly assigned and independent of wave-1 outcomes — they can run while wave-1 confirmations complete.
- **Recovery:** fern #54 SOAP and thorfinn #58 cooldown sweep are waiting on per-module init diagnostic runs.

## Next research directions (wave 3 candidates)

Activate once wave 1 winners merge:

1. **Stack confirmed winners** — MuLoCo × Contra-Muon, MuLoCo × NorMuon, Contra-Muon × NorMuon (= public #11).
2. **Always-active MuonH** — if askeladd's budget sweep continues to underperform, move to reference `scale_invariant_update_` variant + per-module init.
3. **Soft-Muon interpolation** (public #20 component) — sign-modulated Contra-Muon/Muon interpolation.
4. **PSGD-Kron** — Kronecker-factored preconditioner (lr=0.0005, wd=0.625); not yet attempted.
5. **Adafactor aux** — replace AdamW aux with Adafactor for embed/lm_head.
6. **Schedule post-thorfinn:** if cosine wins, try schedule-free Muon; if linear wins, try trapezoidal.

## Operational notes

- All 8 students currently have active WIP PRs. No idle GPUs.
- **Per-module init std is mandatory for any plain-Muon-1-GPU experiment** (attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031). Folded into both wave-2 assignment specs.
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill, post failure mode.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4. No cherry-picking.
- Banned reference sources: Prime Intellect autonomous-run materials.
