# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 08:50 UTC (boot 22)
- **Most recent human-team directive:** None (issues disabled on repo; only PR-comment channel is open).
- **Branch state:** PR #52 MuonH-SI **MERGED**. New baseline: val=3.27737, ffs=3275 (n=4, deterministic). Full cascade executed — all 8 students have active WIP PRs on the new MuonH-SI baseline.

## Current branch baseline (MuonH-SI, PR #52)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27737** (n=4 mean) |
| `ffs` | **3275** (n=4 mean = min = max — deterministic) |
| stat margin | `(3.28 - 3.27737) × √4 = 0.00526` ✓ |
| Optimizer | MuonH (lr=0.018, mu=0.95, wd=0, mode=scale_invariant, budget_mult=1.0) + aux AdamW |
| Per-module init | attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031 |
| Cooldown | MuonH=1.0 (full linear), aux=0.4 |

**Key MuonH-SI mechanism**: `scale_invariant_update_` rescales update to param's Frobenius-norm scale, takes gradient step (Nesterov momentum on NS5 output), renormalises param back to initial Frobenius norm. Replaces NorMuon's 1D `second_momentum` preconditioning.

## Active experiments (boot 22 status — 08:50 UTC)

All experiments are on the **MuonH-SI baseline** (val=3.27737, ffs=3275).

| PR | Student | Lever | Status | Next action |
| --- | --- | --- | --- | --- |
| **#132** | alphonse | MuonH budget_mult sweep {0.8, 1.0, 1.2} | Newly assigned | Monitor for smoke pickup |
| **#133** | thorfinn | MuonH mu sweep {0.90, 0.95, 0.98} | Newly assigned | Monitor for smoke pickup |
| **#134** | nezuko | Contra-Muon × MuonH-SI | Newly assigned | Monitor for smoke pickup |
| **#135** | tanjiro | NorMuon × MuonH-SI (row/col preconditioning restored) | Newly assigned | Monitor for smoke pickup |
| **#136** | askeladd | MuonH-SI lr sweep {0.015, 0.018, 0.022} | Newly assigned | Monitor for smoke pickup |
| **#107** | edward | Cautious-Muon (sign-agreement mask) | Needs rebase to MuonH-SI; crashed at step 3075 | Rebase + relaunch screen |
| **#111** | fern | AdamAtan2 aux optimizer | Needs rebase to MuonH-SI; smoke-v2 was running | Rebase + relaunch smoke |
| **#114** | frieren | MuLoCo × MuonH-SI (adapted from NorMuon×MuLoCo) | Needs rebase + adapt | Rebase + relaunch smoke |

## PRs closed this session (boot 22 cascade)

- **#113 alphonse Cautious-NorMuon**: Hypothesis collapses to edward's Cautious×MuonH-SI.
- **#122 thorfinn NorMuon-biascorr**: second_momentum no longer exists in baseline (NorMuon removed).
- **#127 nezuko Contra-NorMuon**: NorMuon no longer in baseline; replaced with Contra×MuonH-SI (#134).
- **#128 tanjiro NorMuon-beta2-sweep**: NorMuon EMA gone; replaced with NorMuon×MuonH-SI stack (#135).

## PRs closed earlier (pre-boot 22)

- **#87 tanjiro u/w-floor sweep**: 0/4 arms hit ffs target. Closed negative.
- **#100 nezuko Sign-Muon**: 5+ NaN smokes, method fragility.
- **#101 thorfinn Polyak EMA**: val=3.2846, ffs=-1. Closed negative.
- **#55 frieren MuLoCo**: Closed negative (n=4 mean=3.27990). Near-miss; MuLoCo×MuonH-SI is the retry.
- **#53 edward Contra-Muon** (plain Muon base): n=4 mean=3.2835. Mechanism real but couldn't clear bar on plain Muon. Contra×MuonH-SI (#134) retries.
- **#51 alphonse NorMuon**: MERGED as wave-2 baseline. Superseded by MuonH-SI (#52).

## Key learnings

1. **`sample_tensor` OOB bug** fixed (`cc1c710`).
2. **Per-module init ordering matters**: students who add per-module init BEFORE the `"proj" in name → zero_()` branch break zero-proj → NaN smokes. The merged MuonH-SI baseline already includes per-module init correctly (no zero-proj in MuonH path).
3. **mbs=64 is fixed benchmark contract** — no reductions.
4. **NorMuon** (1D post-NS row/col second-moment preconditioning) — merged (PR #51). **Superseded by MuonH-SI.**
5. **MuonH-SI** (PR #52) — MERGED, current baseline. val=3.27737/ffs=3275 deterministic n=4. Frobenius-ball scale-invariant projection: wins even while dropping NorMuon's preconditioning.
6. **Deterministic ffs=3275**: All 4 MuonH-SI confirm trials hit exactly ffs=3275. This very low variance means n=1 screen arms give clean signal — no need to over-run.
7. **Closed negative directions**: Lion, init-only, mbs=32, cooldown-shape, u/w-floor, Sign-Muon, Polyak-EMA, MuLoCo standalone.

## Confirmed positives (merge bar cleared)

1. **alphonse NorMuon — MERGED** (val=3.27795, ffs=3258, n=6). Superseded.
2. **askeladd MuonH-SI — MERGED** (val=3.27737, ffs=3275, n=4). **Current baseline.**

## Wave-3 hypothesis portfolio (all on MuonH-SI base)

### MuonH-SI hyperparameter sweeps (priority: quick clean signal):
1. **MuonH budget_mult sweep** (alphonse #132): {0.8, 1.0, 1.2} — Frobenius-ball radius tuning
2. **MuonH mu sweep** (thorfinn #133): {0.90, 0.95, 0.98} — Nesterov momentum coefficient
3. **MuonH lr sweep** (askeladd #136): {0.015, 0.018, 0.022} — learning rate retune

### Mechanism stacks (higher risk, higher reward):
4. **NorMuon × MuonH-SI** (tanjiro #135): restore row/col preconditioning on MuonH-SI. Highest-priority stack — both mechanisms individually confirmed.
5. **Contra-Muon × MuonH-SI** (nezuko #134): direction correction + norm preservation compound
6. **Cautious-Muon × MuonH-SI** (edward #107): sign-agreement mask on NS5 output of MuonH
7. **AdamAtan2 aux** (fern #111): bounded per-element update for embed/lm_head/scalars
8. **MuLoCo × MuonH-SI** (frieren #114): outer Nesterov SGD wrapper on top of MuonH-SI

## Next-priority watch points (next 3-5 hours)

1. **#107 edward rebase** (~09:30 UTC): Needs to rebase onto MuonH-SI base. Pod should have picked up comment.
2. **#111 fern rebase** (~09:30 UTC): Same — rebase + smoke relaunch.
3. **#114 frieren rebase + adapt** (~09:30 UTC): Drop NorMuon restore, keep MuLoCo wrapper, rebase.
4. **#132-#136 smoke pickups** (~10:00-11:00 UTC): All 5 new assignments should start their smokes.
5. **NorMuon × MuonH-SI screen terminal** (#135, ~15:00-16:00 UTC): If this clears the bar → highest-priority confirm run.

## Operational notes

- All 8 students have active WIP PRs. **Zero idle students.**
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4 by default.
- **New merge bar**: `mu_val < 3.27737` at n=4 (MuonH-SI baseline).
- Banned reference sources: Prime Intellect autonomous-run materials.
