# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 01:45 UTC (boot 15)
- **Most recent human-team directive:** None received (GitHub API rate-limited both times checked).
- **Branch state:** **PR #51 alphonse NorMuon MERGED** — NorMuon is the new branch baseline (val=3.27795, ffs=3258, n=6). Wave-2 smokes still in debug. Rate limit depleted, resets 02:19 UTC.

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

## Active experiments (boot 15 status)

| PR | Student | Lever | W&B signal | Next action |
| --- | --- | --- | --- | --- |
| **#52** | askeladd | MuonH-SI (always-active) | `rwpbmxj7` trial 1: ffs=3275 val=3.2776 ✓. Step 3901 = mid-trial 2 | Wait for n=4 terminal; merge if stat clears |
| **#55** | frieren | MuLoCo outer Nesterov | `0qry1ckh` T1=3.2792, T2=3.2785, T3=3.2808 (miss). Trial 4 running | **Close as negative** when T4 terminals. n=4 cannot clear bar (T4 needs val≤3.2735) |
| **#87** | tanjiro | u/w-floor sweep | Arm1 (lr=0.035, UW=0.30): val=3.28074 ffs=-1 (close miss). Arm2 (UW=0.40) in flight ~01:53 UTC ETA. Arms 3+4 pending | Wait for 4-arm sweep terminal; best corner may close |
| **#100** | nezuko | Sign-Muon | 3 runs: all NaN/zero-gradient. Root cause: sign taken BEFORE lerp_ at step 0 → NS5 input all-zeros → div-by-zero. Debug hint sent | Wait for fix attempt + clean smoke |
| **#101** | thorfinn | Polyak EMA | 3 smokes all val~8 at step 300 (spec target <6.5). Root cause: EMA initialization bias (raw EMA at step 300 with β=0.999 is ~26% of true weight value). Debug hint sent | Wait for bias-corrected smoke |
| **#107** | edward | Cautious-Muon | PR created (00:28 UTC). No smoke yet detected. | Wait for student to pick up |
| **fern** (idle) | fern | AdamAtan2 aux | Branch `fern/adamatan2-aux` pushed. PR pending rate limit reset (02:19 UTC) | Create PR after 02:19 UTC |

## PRs closed this session

- **#99 fern Adafactor** (boot 15): Closed negative. Adafactor RMS-clip does not bound per-element max → step-1 embed explodes at lr=0.3.
- **#53 edward Contra-Muon** (boot 14): Closed negative. n=4 mean=3.2835 (stat -0.0070).
- **#51 alphonse NorMuon** (boot 15): **MERGED**. New baseline.

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

- All 8 students have active WIP PRs (or are being assigned now). Zero idle GPUs.
- **Rate limit depleted, resets 02:19:45 UTC.** Fern PR creation pending.
- All 8 r3 pods healthy (assumed — kubectl not checked this boot due to rate limit focus).
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4 by default.
- Banned reference sources: Prime Intellect autonomous-run materials.
