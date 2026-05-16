# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 05:55 UTC (boot 19)
- **Most recent human-team directive:** None (issues disabled on repo; only PR-comment channel is open).
- **Branch state:** PR #51 NorMuon merged (baseline val=3.27795, ffs=3258). **Askeladd #52 confirm 3/4 trials ALL PASS** (T0=3.2776, T1=3.2778, T2=3.2767). Strong merge candidate, ETA terminal ~06:15 UTC. PR #101 thorfinn Polyak EMA CLOSED negative (val=3.2846). PR #122 thorfinn normuon-biascorr ASSIGNED. All 8 students active.

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

## Active experiments (boot 19 status — 05:55 UTC)

| PR | Student | Lever | W&B signal | Next action |
| --- | --- | --- | --- | --- |
| **#52** | askeladd | MuonH-SI confirm n=4 | `rwpbmxj7`: **T0=3.2776 ✓, T1=3.2778 ✓, T2=3.2767 ✓**. Trial 3 mid-flight ~step 953/3325. ETA terminal ~06:15 UTC | **Merge imminent** — monitor |
| **#87** | tanjiro | u/w-floor 4-arm sweep | A3 (UW=0.30 lr=0.04) **DONE val=3.2787 marginal pass**. A4 (UW=0.40 lr=0.04) running step 3015/3350 val=3.331 (no ffs yet) | Wait for A4 terminal; if val<3.28, sweep partially positive; if miss, close negative |
| **#100** | nezuko | Sign-Muon | 5+ NaN smokes (all local unpushed). Hard deadline 06:30 UTC: push code + post impl. If no push → close+reassign | Watch branch for new commit |
| **#101** | thorfinn | Polyak EMA | **CLOSED negative** (val=3.2846, ffs=-1). Replaced by #122 | — |
| **#107** | edward | Cautious-Muon | Screen `53awp1ju` step 3075/3350 val=3.342. Not hit target yet — 275 steps in cooldown | Wait for terminal |
| **#111** | fern | AdamAtan2 aux | 3 NaN smokes post-push. Root cause: per-module init override breaks zero-init projections. Commented fix (remove per-module block, keep only AdamAtan2 swap) | Monitor for fix + relaunch |
| **#113** | alphonse | Cautious-NorMuon stack | 3 smokes done val~4.21. New smoke `dsgn1trb` at step 50 | Watch for screen launch |
| **#114** | frieren | NorMuon × MuLoCo stack | 2 smokes done val~3.975. New smoke `8ei1g5d3` running | **High priority** — watch for screen launch |
| **#122** | thorfinn | NorMuon bias-corrected second moment | **Just assigned** (boot 19, 05:50 UTC) | Monitor for smoke pickup |

## PRs closed this session

- **#101 thorfinn Polyak EMA** (boot 19): Closed negative. Screen val=3.2846, ffs=-1. Polyak EMA fights Muon cooldown. Replaced with #122 normuon-biascorr.
- **#55 frieren MuLoCo** (boot 16): Closed negative. n=4 mean=3.27990. Replaced with #114 NorMuon×MuLoCo stack.
- **#99 fern Adafactor** (boot 15): Closed negative. Adafactor RMS-clip ≠ per-element bound. Replaced with #111 AdamAtan2 aux.
- **#53 edward Contra-Muon** (boot 14): Closed negative. n=4 mean=3.2835. Replaced with #107 Cautious-Muon.
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
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4 by default.
- Banned reference sources: Prime Intellect autonomous-run materials.
- **Key learning (boot 19)**: The merged NorMuon (PR #51) does NOT include per-module init — advisor-branch init is zero-proj + torch-default for other weights. State docs were wrong. Students adding per-module init BEFORE the generic `"proj" in name → zero` branch break the zero-proj invariant.

## Next-priority watch points (next 2-4 hours)

1. **Askeladd #52 terminal** (~06:15 UTC): 3/4 trials done, all pass. T4 mid-flight. **Merge candidate.** n=4 mean likely ~3.2774.
2. **Nezuko #100 hard deadline** (06:30 UTC): push code or close+reassign.
3. **Tanjiro #87 A4 terminal** (~06:30 UTC): UW=0.40 lr=0.04 step 3015/3350 val=3.331. Close as negative if A4 misses.
4. **Edward #107 screen terminal** (~06:15 UTC): step 3075/3350 val=3.342.
5. **Frieren #114 screen launch** (pending): smoke val=3.975 — highest-priority wave-3 signal.
6. **Alphonse #113 screen launch** (pending): 3 smokes done val~4.21.
7. **Fern #111 fix**: remove per-module init block; relaunch smoke.
