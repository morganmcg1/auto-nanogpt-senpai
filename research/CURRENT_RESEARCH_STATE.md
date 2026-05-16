# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 03:40 UTC (boot 17)
- **Most recent human-team directive:** None (issues disabled on repo; only PR-comment channel is open).
- **Branch state:** PR #51 NorMuon merged (baseline val=3.27795, ffs=3258). Askeladd #52 MuonH-SI confirm 2/4 trials done — trial 0 cleared (val=3.27781 ✓, ffs=3275 ✓). All 8 students have active WIP PRs — zero idle.

## New branch baseline (post-PR #51 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27795** (n=6 mean) |
| `ffs` | **3258** (n=6 mean; min 3225) |
| stat margin | `(3.28 - 3.27795) × √6 = 0.0050` ✓ |
| Optimizer | NorMuon (lr=0.035, wd=0.025, mu=0.95, beta2=0.95) + aux AdamW |
| Init | per-module: attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031 |

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, **batch size (and mbs=64)**, and one fwd-bwd per optim step fixed.
Optimizer, schedule, init, telemetry editable.

## Active experiments (boot 17 status)

| PR | Student | Lever | W&B signal | Next action |
| --- | --- | --- | --- | --- |
| **#52** | askeladd | MuonH-SI confirm n=4 | `rwpbmxj7`: trial 0 ✓ (val=3.27781, ffs=3275). 2/4 trials done. Trial 2 (0-indexed) at step 7502/13300. ETA ~06:00 UTC | Wait for n=4 terminal; if `mu≤3.27795`, merges over NorMuon |
| **#87** | tanjiro | u/w-floor 4-arm sweep | Arm1 (UW=0.30 lr=0.035): val=3.28074 miss. Arm2 (UW=0.40 lr=0.035): val=3.28084 miss. Arm3 (UW=0.30 lr=0.04) running, step 2925/3350 val=3.3353 descending. Arm4 (UW=0.40 lr=0.04) not started | Wait for arms 3+4 terminal; likely close as negative |
| **#100** | nezuko | Sign-Muon | **Branch HEAD has no `sign()` implementation pushed.** 3 NaN smokes were against unpushed local edits. Boot 17 follow-up asks for push + impl review | Wait for code push + relaunch smoke |
| **#101** | thorfinn | Polyak EMA | Boot 16 fix attempt confirmed healthy (val=4.54 at step 300). Awaiting screen | Wait for screen result |
| **#107** | edward | Cautious-Muon | 3 healthy smokes running (val~4.5). Picked up cleanly. Wave-3 standalone | Wait for screen result |
| **#111** | fern | AdamAtan2 aux | **Branch HEAD has no `class AdamAtan2` implementation pushed.** NaN smoke (only 13 rows, val=NaN, best=10.83) was against unpushed local. Boot 17 follow-up asks for rebase + push | Wait for code push + relaunch smoke |
| **#113** | alphonse | Cautious-NorMuon stack | Smoke val=4.22 ✓ (healthy). Wave-3 stack | Wait for screen result |
| **#114** | frieren | NorMuon × MuLoCo stack | Smoke val=3.97 ✓ (healthy). Wave-3 stack | Wait for screen result |

## PRs closed this session

- **#55 frieren MuLoCo** (boot 16): Closed negative. n=4 mean=3.27990, margin=0.000194 (fails 0.004 bar). 2/4 hits at ffs=3275. Standalone MuLoCo on plain Muon is marginal at 1 GPU. Replaced with #114 NorMuon×MuLoCo stack.
- **#99 fern Adafactor** (boot 15): Closed negative. Adafactor RMS-clip ≠ per-element bound → step-1 embed explodes at lr=0.3. Replaced with #111 AdamAtan2 aux.
- **#53 edward Contra-Muon** (boot 14): Closed negative. n=4 mean=3.2835, stat -0.0070. Replaced with #107 Cautious-Muon.
- **#51 alphonse NorMuon** (boot 15): **MERGED**. New branch baseline.

## Notes from boot 17

- **Fern #111 and Nezuko #100 have no implementation pushed.** Branch HEADs are assignment-commit-only. NaN smoke observations came from unpushed local edits. Both students nudged with explicit "rebase + push" instructions and AdamAtan2 / Sign-Muon hardening tips.
- **Edward #107, Alphonse #113, Frieren #114 smokes all healthy** — preconditioning + Cautious stack + MuLoCo outer wrapper all running cleanly on the NorMuon base.

## Notes from boot 16

- **senpai-pr-guard.py false-positive bug** reported by frieren: `result_markers()` scans all `SENPAI-RESULT:` mentions in prose/code blocks → false parse errors on advisor template + casual prose mentions → blocks `mark_ready_for_review`. Workaround: students can use `gh pr ready` + manual `swap_gh_pr_label`. Acknowledged in #55 closure comment. Flag for human researcher team.

## PRs CLOSED as negative (historical)

#53 edward Contra-Muon, #99 fern Adafactor, #54 fern SOAP-MLP, #58 thorfinn cooldown sweep, #86 nezuko MuonSquared, #56 Lion, #57 init-only.

## Key learnings

1. **`sample_tensor` OOB bug** fixed (`cc1c710`).
2. **Per-module init mandatory** for plain Muon 1-GPU stability (attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031).
3. **mbs=64 is fixed benchmark contract** — no reductions.
4. **NorMuon (canonical 1D post-NS) works at 1 GPU** — 6/6 trials cleared target. First wave-1 winner merged. New baseline.
5. **Adafactor aux fails** at lr=0.3 for embed because RMS-clip ≠ per-element bound. AdamAtan2 (atan2-based bounded update) is the fix.
6. **Adafactor mechanism**: RMS-clip bounds AGGREGATE magnitude, not per-element max. Contrast with AdamAtan2 atan2 saturation.
7. **Lion / init-only / mbs=32 / cooldown-shape** are closed negative directions.

## Confirmed positives (merge bar cleared or pending n=4)

1. **alphonse NorMuon — MERGED** (val=3.27795, ffs=3258, n=6). New branch baseline.
2. **askeladd MuonH-SI** — screen val=3.2775, ffs=3300 ✓. Confirm trial 1: ffs=3275, val=3.2776 ✓. Trials 2-4 running.

## Wave-3 candidates (activate once askeladd #52 or another winner merges)

1. **Stack winners (highest priority):**
   - NorMuon × MuLoCo (MuLoCo near-miss wave-2 → test stack on NorMuon base)
   - NorMuon × MuonH-SI (if askeladd #52 merges — same branch, orthogonal mechanisms)
   - NorMuon × Cautious-Muon (if edward #107 clears — sign-agreement mask orthogonal to preconditioning)
   - Triple-stack: NorMuon × MuonH-SI × MuLoCo
2. **Aux optimizer improvement:** NorMuon × AdamAtan2 aux (fern #new — per-element bounded update)
3. **Contra-Muon × NorMuon stack** (public reference #11 — was 8-GPU; retry at 1-GPU on top of NorMuon base)
4. **beta2 sweep for NorMuon** (beta2 ∈ {0.92, 0.95, 0.98}) — student suggested, reference never ablated
5. **Bias-corrected second moment for NorMuon** (current EMA uncorrected at early steps)
6. **Init lever**: lower qkv init std on top of NorMuon baseline

## Operational notes

- All 8 students have active WIP PRs. **Zero idle students.**
- 3 new wave-3 PRs created (#111, #113, #114) — first stacked-mechanism experiments on the new NorMuon baseline.
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4 by default.
- Banned reference sources: Prime Intellect autonomous-run materials.

## Next-priority watch points (next 4-6 hours)

1. **Askeladd #52 confirm terminal** (~06:00 UTC, ~2.5h from now): 2/4 trials done, trial 0 cleared (val=3.27781 vs baseline 3.27795). If n=4 mean ≤ 3.27795, merges over NorMuon. **Primary watch.**
2. **Tanjiro #87 arms 3+4 terminal** (lr=0.04 sweep): arm 3 mid-flight, arm 4 not started. Both will run ~3300 steps; ETA arm-3 ~04:15 UTC, arm-4 by ~05:45 UTC.
3. **Code pushes** for fern #111 and nezuko #100: monitor for new commits on `fern/adamatan2-aux` and `g1r3-nezuko/sign-muon`.
4. **Screen results** for edward #107, alphonse #113, frieren #114 — all smokes healthy; screen ETA within 2-3h.
5. **Thorfinn #101 screen**: post-fix smoke healthy; full 3300-step screen pending.
