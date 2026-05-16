# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-16 03:55 (Wave 3 active: PR #94 W&B WINNER `yeyewcj6` sr=3100 val=3.2679 ✓ (student notified, running n=2 confirm `205sycku`); PR #88 edward CLOSED null; PR #95 alphonse CLOSED clean negative; PR #93 fern sent back for row-wise NorMuon retry; edward→PR #118 cooldown_frac scan; alphonse→PR #119 measured-scale Contra-Muon)
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3150 steps (current local best); public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3150 steps, val/loss 3.27447** — PR #64 (g1r1-fern, PMuon bilateral covariance EMA preconditioning, n=1, margin +0.00553 ✓).
W&B run: `vx0r7rp2`. Merged 2026-05-15.

**Pending merge:** PR #94 askeladd (PMuon + u/w-floor, run `yeyewcj6`) hit **sr=3100, val=3.2679, margin 0.00812 ✓** at n=1 — clean winner once terminal SENPAI-RESULT posted. Student running n=2 confirmation `205sycku` before posting terminal result. Expected terminal ~06:40 UTC.

## CRITICAL FINDING: Aurora+Contra+u/w base (PR #68) is empirically unreliable

**Discovered 2026-05-15 by askeladd PR #84:** Multiple fresh runs of the PR #68 recipe diverge at step ~125 with `train/grad/global_norm ≈ 234K` — matching the Inductor compile-bug signature. The original PR #68 winner `lg4xdlkt` was a lucky compile-cache draw.

PMuon (PR #64, run `vx0r7rp2`) is the only reliably-reproducible local baseline.

## Active experiments (status:wip) — Wave 3 (all on PMuon base)

| PR  | Student     | Mechanism on PMuon base                              | Status |
| --- | ----------- | ---------------------------------------------------- | ------ |
| #94 | askeladd    | + **Skylight u/w-floor** (TARGET_UW=0.35)            | **WINNER** `yeyewcj6` sr=3100 val=3.2679 margin 0.00812 ✓ — n=2 confirm `205sycku` running; terminal SENPAI-RESULT pending ~06:40 UTC |
| #85 | nezuko      | + **Power-law cooldown** γ=1.2                       | n=2 confirm `u3o8j3yj` running (step 1075/3250 @ 03:40 UTC), ~6h remaining |
| #110 | thorfinn   | + **PMuon γ-scan** (γ=0.25 arm A, γ=0.35 arm B)     | arm A `6g8boli8` running step 725/3250 val 3.74; arm B queued |
| #83 | tanjiro     | + **SOAP-MLP** on PMuon                              | smoke `x91f0af2` at step 75; Newton-Muon parallel arm `cpoe66ut` step 450 val 3.91 |
| #65 | frieren     | MuonH hyperball-Frobenius-cap on PMuon               | rebase confirmed commit `a107ed2`; launching n=1 full run ~03:27 UTC |
| #93 | fern        | + **NorMuon row-wise** (send-back, was element-wise) | sent back for row-wise retry; first arm `0x6cgq1a` (element-wise) finished sr=3225 (worse); will relaunch |
| #118 | edward     | + **cooldown_frac scan** (0.5 vs 0.8, default 0.7)  | newly assigned — student picks up on next poll cycle |
| #119 | alphonse   | + **Measured-scale Contra-Muon** (coeff 0.10, 0.05) | newly assigned — calibrated target_scale to actual ||update||_F; building on PR #95 root-cause |

## Closed this session

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| #89 | thorfinn | Per-module init on PMuon: sr=3175 (+25 worse), margin 0.00361 fails rule | Closed negative; PMuon zero-init for *.proj.weight does real work via covariance EMA |
| #88 | edward   | Soft-Muon p=0.1 cooldown: sr=3150 (same as baseline), val −0.000146 within noise | Closed null; PMuon whitening already targets the same SVD direction that Soft-Muon blends |
| #95 | alphonse | Contra-Muon coeff=0.2 and 0.1: both catastrophically diverge (val 7.3-7.5 at step 1000) | Closed negative; dir_norm_ratio=1.59 → naïve target_scale miscalibrated on PMuon; fix in PR #119 |
| #59 | alphonse | Vanilla Muon: 3350 steps, val 3.29743 (target NOT reached) | Attribution anchor; compile-bug root-cause was main contribution |
| #61 | askeladd | NorMuon standalone: sr=3275, val 3.27920 (n=1, doesn't beat baseline) | Mechanism validated; stacking attempt in #93 |
| #63 | edward   | u/w floor: 1/2 hit at sr=3275 val 3.278 | Mechanism returns in #94 |
| #67 | nezuko   | SOAP-MLP standalone: sr=3200, val 3.27705 | Mechanism returns in #83 |
| #69 | thorfinn | KL-SOAP-H: projected ~3.9 at step 3150 | Clean negative; NS polar essential |
| #84 | askeladd | NorMuon on broken Aurora+Contra+u/w base: divergent | Base was the problem (PR #68 unreproducible) |

## Key cross-cutting issues

1. **`sample_tensor` linspace bug** — FIXED in PR #64 merge (fp64+clamp variant).

2. **Inductor compile bug — KNOWN, partial workaround.** `torch.compile(model, dynamic=False)` NaNs `blocks.0.attn.proj.bias` grad at step 1 on RTX PRO 6000 Blackwell.
   - **Vanilla Muon**: `dynamic=True` fully fixes it
   - **PMuon**: robust empirically (covariance whitening damps seed-NaN amplitude)
   - **Aurora+Contra+u/w**: `dynamic=True` alone NOT sufficient — makes PR #68 unreproducible

3. **bf16 vs fp32 in NS** — frieren's finding: NS in raw bf16 triggers NaN; explicit fp32 cast required before NS.

4. **Muon weight_decay**: applies WD via `p.mul_(1 - lr*wd)`. At lr=0.035, wd=0.025 → effective decay ~0.000875/step.

5. **Contra-Muon calibration bug on PMuon base** — alphonse PR #95 root cause: PMuon's post-polar Frobenius is ~0.62× the assumed `sqrt(min(m,n))` target_scale, making `dir_norm_ratio≈1.59` and causing 32% off-direction perturbation at coeff=0.2. Fix: normalize `contra_dir` to actual `||update||_F` (PR #119 measured-scale Contra-Muon).

## Wave 3 status summary

Wave 3 portfolio testing single-mechanism additions on PMuon base (target: sub-3150 steps):

| Mechanism | PR | Status | Result |
| --- | --- | --- | --- |
| u/w-floor (TARGET_UW=0.35) | #94 | WINNER PENDING MERGE | sr=3100 val=3.2679 margin 0.00812 ✓ |
| Power-law cooldown γ=1.2 | #85 | Confirmation running | n=2 `u3o8j3yj` in flight |
| PMuon γ-scan (0.25/0.35) | #110 | In flight | arm A step 725 |
| SOAP-MLP | #83 | In flight (smoke) | early |
| MuonH hyperball cap | #65 | Launched | n=1 full run started |
| NorMuon row-wise | #93 | Send-back | retry with row-wise |
| cooldown_frac scan (0.5/0.8) | #118 | Newly assigned | pending first run |
| Measured-scale Contra-Muon | #119 | Newly assigned | pending first run |
| Soft-Muon p=0.1 | #88 | CLOSED | null result (sr=3150 same as baseline) |
| Contra-Muon (naïve) | #95 | CLOSED | both coeff 0.2/0.1 catastrophically diverge |
| Per-module init std | #89 | CLOSED | sr=3175 worse than baseline |

## Wave 4 roadmap (after Wave 3 winners)

1. **Merge PR #94** (u/w-floor winner, sr=3100) as new baseline first.
2. **Stack two Wave 3 winners** — if cooldown_frac or power-law cooldown also beat 3150, stack them on u/w-floor base.
3. **PMuon β_cov scan** {0.90, 0.95, 0.99} — unexplored HP on the merged base.
4. **MuLoCo / Lookahead outer Nesterov** (Record #13) — sync_interval=30, slow-moving outer copy on PMuon. Frieren partially exploring.
5. **n≥4 seed batch on new local best** once frontier stabilizes below 3100.

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004` required for final claims. n=1 screening winners need n≥2 seed confirmation before merge. All currently-open PRs are single-trial screening except #85 nezuko (n=2 in flight) and #94 (n=2 confirm in flight).
