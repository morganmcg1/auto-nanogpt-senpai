# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 07:25 UTC (boot 21)
- **Most recent human-team directive:** None (issues disabled on repo; only PR-comment channel is open).
- **Branch state:** PR #51 NorMuon merged (baseline val=3.27795, ffs=3258). **PR #52 MuonH-SI W&B audit CONFIRMED PASS** (n=4 μ=3.27737, ffs=3275 deterministic) but blocked on rebase conflict — askeladd pod sent back for rebase, should pick up next poll cycle.

## Current branch baseline (NorMuon, PR #51)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27795** (n=6 mean) |
| `ffs` | **3258** (n=6 mean; min 3225) |
| stat margin | `(3.28 - 3.27795) × √6 = 0.0050` ✓ |
| Optimizer | NorMuon (lr=0.035, wd=0.025, mu=0.95, beta2=0.95) + aux AdamW |
| Init | zero-proj for all `"proj" in name`; default torch init otherwise |

## Imminent baseline shift: MuonH-SI (PR #52 — pending rebase)

Once askeladd rebases and #52 merges:

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27737** (n=4 mean) |
| `ffs` | **3275** (deterministic across all 4 trials) |
| stat margin | `(3.28 - 3.27737) × √4 = 0.00526` ✓ |
| Optimizer | MuonH (lr=0.018, mu=0.95, wd=0, mode=scale_invariant, budget_mult=1.0) |
| Per-module init | attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031 |
| Cooldown | MuonH=1.0 (full linear), aux=0.4 |

**Key MuonH-SI mechanism**: Frobenius-ball + scale-invariant projection — rescales update to param's norm scale, takes gradient step, renormalises param to initial Frobenius norm. Replaces NorMuon's row/col second-moment preconditioning. Wins by 0.00059 val/loss; ffs 3258→3275 deterministic.

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, **batch size (and mbs=64)**, and one fwd-bwd per optim step fixed.
Optimizer, schedule, init, telemetry editable.

## Active experiments (boot 21 status — 07:25 UTC)

| PR | Student | Lever | W&B signal | Next action |
| --- | --- | --- | --- | --- |
| **#52** | askeladd | MuonH-SI n=4 confirm **PASS** | `rwpbmxj7`: μ=3.27737 ffs=3275 all 4 trials. Blocked on rebase. | Rebase request sent; monitor for push+merge |
| **#107** | edward | Cautious-Muon screen | CRASHED at step 3075/3350 val=3.342. ffs=-1. | Relaunch request posted |
| **#111** | fern | AdamAtan2 aux | Smoke-v2 running ~step 90/300 (post-init-fix) | Monitor smoke; if clean, launch screen |
| **#113** | alphonse | Cautious-NorMuon screen | Running step ~200/3300 val=4.99 (early) | Wait for terminal (~10:30 UTC) |
| **#114** | frieren | NorMuon × MuLoCo screen | Running step ~180/3300 val=4.58 (early) | Wait for terminal (~10:30 UTC) |
| **#122** | thorfinn | NorMuon-biascorr | Boot 21 status unknown — no W&B signal seen | Monitor for smoke |
| **#127** | nezuko | Contra-Muon × NorMuon | **Newly assigned** (boot 21, 07:22 UTC) | Monitor for smoke pickup |
| **#128** | tanjiro | NorMuon beta2 sweep | **Newly assigned** (boot 21, 07:22 UTC) | Monitor for smoke pickup |

## PRs closed this session

- **#87 tanjiro u/w-floor sweep** (boot 20): Closed negative. 0/4 arms hit ffs target.
- **#100 nezuko Sign-Muon** (boot 20): Closed negative. 5+ NaN smokes, method fragility.
- **#101 thorfinn Polyak EMA** (boot 19): Closed negative. val=3.2846, ffs=-1.
- **#55 frieren MuLoCo** (boot 16): Closed negative. n=4 mean=3.27990.
- **#51 alphonse NorMuon** (boot 15): **MERGED**. Current baseline.

## Key learnings

1. **`sample_tensor` OOB bug** fixed (`cc1c710`).
2. **Per-module init on NorMuon baseline**: merged #51 uses `zero-proj for "proj" in name`. Students who add per-module init BEFORE the `"proj" → zero_()` branch break zero-proj → NaN smokes.
3. **mbs=64 is fixed benchmark contract** — no reductions.
4. **NorMuon** (1D post-NS row/col second-moment preconditioning) — merged (PR #51). Baseline 3.27795/3258.
5. **MuonH-SI** — confirmed winner (PR #52), pending rebase. val=3.27737, ffs=3275 deterministic. Bundle: plain Muon NS5 + Frobenius-ball scale-invariant projection + per-module init std + per-group cooldown_frac. Wins even while dropping NorMuon's preconditioning.
6. **Lion / init-only / mbs=32 / cooldown-shape / u/w-floor / Sign-Muon / Polyak-EMA** are closed negative directions.
7. **MuLoCo on plain Muon**: near-miss (n=4 mean=3.27990). Mechanism valid but insufficient standalone.
8. **Wave-3 post-#52-merge cascade**: When MuonH-SI lands, #113 Cautious-NorMuon may collapse to Cautious×MuonH (= edward #107); #122 NorMuon-biascorr hypothesis evaporates (no second_momentum in MuonH). Replacement PR bodies ready at /tmp.

## Confirmed positives (merge bar cleared)

1. **alphonse NorMuon — MERGED** (val=3.27795, ffs=3258, n=6).
2. **askeladd MuonH-SI — CONFIRMED, PENDING REBASE** (val=3.27737, ffs=3275, n=4).

## Wave-3 hypothesis portfolio (by priority)

### Active on current NorMuon base:
1. **Cautious-NorMuon** (alphonse #113): sign-agreement mask — screen running
2. **NorMuon × MuLoCo** (frieren #114): MuLoCo near-miss wave-2 retry — screen running
3. **Contra-Muon × NorMuon** (nezuko #127): gradient-direction alignment stack — newly assigned
4. **NorMuon beta2 sweep** (tanjiro #128): 3-arm {0.90,0.95,0.98} — newly assigned
5. **NorMuon-biascorr** (thorfinn #122): bias-correct second-moment EMA
6. **AdamAtan2 aux** (fern #111): bounded per-element update for embed/lm_head/scalars
7. **Cautious-Muon** (edward #107): sign-agreement mask on plain Muon NS5

### Queued for post-MuonH-SI merge (PR bodies staged in /tmp):
- NorMuon × MuonH-SI stack (tanjiro, wave-3 #1)
- Contra-Muon × MuonH-SI (nezuko)
- MuonH budget_mult sweep (alphonse)
- MuonH mu sweep (thorfinn)

## Next-priority watch points (next 3-5 hours)

1. **Askeladd #52 rebase push** (~08:00-09:00 UTC): Merge immediately when pushed. New baseline = 3.27737/3275.
2. **Fern #111 smoke-v2 result** (~07:45 UTC): If no NaN, launch screen immediately.
3. **Edward #107 screen relaunch** (~08:00 UTC): Pod should pick up comment.
4. **Thorfinn #122 status check** (~08:30 UTC): No boot 21 W&B signal — may need nudge.
5. **Alphonse #113 screen terminal** (~10:30 UTC): Cautious-NorMuon. If beats 3.27795 → n=4 confirm.
6. **Frieren #114 screen terminal** (~10:30 UTC): NorMuon × MuLoCo. Highest-priority wave-3 signal.
7. **Nezuko #127 + Tanjiro #128 smoke pickup** (~08:30 UTC): New assignments.

## Operational notes

- All 8 students have active WIP PRs. **Zero idle students.**
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4 by default.
- Banned reference sources: Prime Intellect autonomous-run materials.
