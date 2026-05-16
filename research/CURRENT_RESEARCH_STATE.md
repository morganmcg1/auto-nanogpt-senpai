# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 04:05 UTC (boot 18)
- **Most recent human-team directive:** None (issues disabled on repo; only PR-comment channel is open).
- **Branch state:** PR #51 NorMuon merged (baseline val=3.27795, ffs=3258). **Askeladd #52 MuonH-SI confirm 2/4 trials BOTH PASS** (T0 val=3.2776, T1 val=3.2778). Strong merge signal forming. All 8 students have active WIP PRs — zero idle.

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

## Active experiments (boot 18 status — 04:05 UTC)

| PR | Student | Lever | W&B signal | Next action |
| --- | --- | --- | --- | --- |
| **#52** | askeladd | MuonH-SI confirm n=4 | `rwpbmxj7`: **T0 val=3.2776 ✓, T1 val=3.2778 ✓** (both clear baseline). Trial 2 mid-flight step 2527/3325 within trial (total 9177/13300). 2 trials left. ETA terminal ~05:20 UTC | **Primary merge candidate** — monitor for terminal |
| **#87** | tanjiro | u/w-floor 4-arm sweep | A1 (UW=0.30 lr=0.035) val=3.28074 miss. A2 (UW=0.40 lr=0.035) val=3.28084 miss. **A3 (UW=0.30 lr=0.04) DONE val=3.2787 marginal pass.** A4 (UW=0.40 lr=0.04) running step 1175/3350 val=3.7266 | Wait for A4 terminal; lr=0.04 arms show positive signal vs lr=0.035 |
| **#100** | nezuko | Sign-Muon | Branch HEAD still c1b0e0a (no code push). Latest local NaN smoke 03:35 UTC. Boot 17 nudge unanswered (25min) | Wait one boot; if no push by ~05:30 UTC consider close+reassign |
| **#101** | thorfinn | Polyak EMA | Screen `vu9e9179` (d=0.995) running, step 1800/3350 val=3.420. d=0.999 was bad (val~8.0), d=0.995 working | Wait for screen terminal |
| **#107** | edward | Cautious-Muon | Screen `53awp1ju` running, step 1650/3350 val=3.574 | Wait for screen terminal |
| **#111** | fern | AdamAtan2 aux | **NEW smoke `mtmcbigk` launched 04:26 UTC** (responded to nudge!). Step 50, val at init | Monitor for NaN at step 300; if clean, smoke passes |
| **#113** | alphonse | Cautious-NorMuon stack | 2 smokes done val~4.21. New smoke `1f19dgex` running step 120 | Wait for screen launch |
| **#114** | frieren | NorMuon × MuLoCo stack | 2 smokes done val~3.975 (well below 4.0; strong signal). New smoke `be0264q9` running step 75 | Wait for screen launch — high-priority candidate |

## PRs closed this session

- **#55 frieren MuLoCo** (boot 16): Closed negative. n=4 mean=3.27990, margin=0.000194 (fails 0.004 bar). 2/4 hits at ffs=3275. Standalone MuLoCo on plain Muon is marginal at 1 GPU. Replaced with #114 NorMuon×MuLoCo stack.
- **#99 fern Adafactor** (boot 15): Closed negative. Adafactor RMS-clip ≠ per-element bound → step-1 embed explodes at lr=0.3. Replaced with #111 AdamAtan2 aux.
- **#53 edward Contra-Muon** (boot 14): Closed negative. n=4 mean=3.2835, stat -0.0070. Replaced with #107 Cautious-Muon.
- **#51 alphonse NorMuon** (boot 15): **MERGED**. New branch baseline.

## Notes from boot 18

- **Askeladd #52 two trials passing already**: T0 val=3.2776, T1 val=3.2778 — both clear 3.28 target. If T2 and T3 trend similarly, n=4 mean ≈ 3.2777 will clear NorMuon baseline (3.27795) and satisfy stat margin `(3.28 - 3.2777) × √4 ≈ 0.0046 > 0.004`.
- **Fern #111 responded to nudge**: new smoke launched 04:26 UTC, ~1h after the boot-17 push request. Tracking for NaN at step 300.
- **Nezuko #100 has NOT responded to nudge**: branch HEAD unchanged. Soft deadline 05:30 UTC.
- **Tanjiro #87 arm 3 pass**: val=3.2787 at UW=0.30 lr=0.04 — first pass of the sweep. Sweep is no longer guaranteed-close-as-negative.
- **Frieren smoke val=3.97 at step 300** is strikingly low for the NorMuon×MuLoCo stack. Suggests outer wrapper is providing measurable early-trajectory benefit.

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

## Next-priority watch points (next 2-4 hours)

1. **Askeladd #52 terminal** (~05:20 UTC): 2/4 trials done with both passing. n=4 mean tracking ≈ 3.2777. Strong merge signal. **Primary watch.**
2. **Edward #107 / Thorfinn #101 screens terminal** (~05:00-05:15 UTC): both at step ~1700-1800/3350 with healthy val. Determine whether smoke→screen translates to confirm-eligible signal.
3. **Tanjiro #87 arm 4 terminal** (~05:45 UTC): UW=0.40 lr=0.04 — last arm of sweep. A3 marginal pass (val=3.2787); A4 will determine UW preference.
4. **Fern #111 smoke pass at step 300** (~04:32 UTC): NaN-or-not gate for whether AdamAtan2 impl is correct. If passes, screen launches next.
5. **Frieren #114 / Alphonse #113 screen launches** (~04:35 UTC after smokes finish): frieren's val=3.97 at smoke is strongest wave-3 stack signal — high priority for screen.
6. **Nezuko #100 push deadline** (~05:30 UTC soft): if no impl on branch, prepare close+reassign decision.
