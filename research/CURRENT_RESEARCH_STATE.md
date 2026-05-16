# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-16 14:25 (PR #137 nezuko n=1 SENPAI-RESULT received sr=3075 val=3.270012 → SENT BACK for n=2 seed-2; PR #129 frieren arm B running step 2847 ETA 14:13, green light for arm C 0.99 + arm A clean 0.90; all 8 students active)
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3100 steps; public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3100 steps, val/loss 3.267696 (n=2 mean)** — PR #94 (g1r1-askeladd, PMuon + Skylight u/w-floor, TARGET_UW=0.35).
W&B runs: `yeyewcj6` (n=1) + `205sycku` (n=2 confirm). Merged 2026-05-16.

n=2 stat-sig margin: (3.28 − 3.267696)·√2 = 0.01740 ✓

**Key property:** u/w-floor fires at 100% of eligible params every step — the floor acts as a universal update magnitude multiplier, not a targeted safety catch. γ and TARGET_UW are coupled hyperparameters for the new base.

## 🔥 POTENTIAL WINNER: PR #137 nezuko — sent back for n=2 confirmation

**W&B run `8quuvdrj` (power-law cooldown γ=1.2 on PMuon+u/w-floor base, n=1):**
- `speedrun/final_first_step_to_target`: **3075** (25 steps better than baseline 3100) ✅
- val/loss at step 3250: **3.270012** (+0.00232 vs baseline n=2 mean 3.267696 — within 0.004)
- n=1 stat-sig vs 3.28: margin 0.00999 > 0.004 ✓
- `final_reached_target`: 1, no NaN/divergence
- Config verified: power_cooldown_gamma=1.2, target_uw=0.35, beta_cov=0.95, gamma=0.30, cooldown_frac=0.70

**Advisor decision: SENT BACK for seed-2 launch.** Three reasons recorded in PR #137 send-back comment:
1. val/loss regression vs baseline mean is within 0.004 — triggers project's n=2 confirmation rule
2. The 25-step sr gain is exactly 1 validation cadence tick → could be quantization noise without a second seed
3. The student themselves flagged n=2 as priority #1 in their suggested follow-ups

**Mechanism interpretation (from student's analysis):** power-law cooldown γ=1.2 trades a small amount of final val/loss for earlier target attainment. The concave-down shape drops the lr faster in mid-cooldown (0.5^1.2=0.435 vs 0.5 linear), so the optimizer crosses 3.28 sooner but spends more time at near-zero lr at the end of training. For the speedrun benchmark this is the right trade — but only if it's not seed noise. Seed-2 will decide.

ETA on seed-2: ~3.5h. Re-review when SENPAI-RESULT lands with n=2 mean.

## Active experiments (status:wip) — Wave 4

| PR  | Student     | Mechanism on PMuon + u/w-floor base                                  | Status (as of 13:25) |
| --- | ----------- | --------------------------------------------------------------------- | ------ |
| **#137** | **nezuko** | + **Stack power-law cooldown γ=1.2** (n=1 sr=3075 val=3.270012, SENT BACK for n=2)  | seed-2 launch pending, ETA ~3.5h |
| #158 | edward     | + **Depth-wise per-block LR decay** (LLRD, decay=0.85 arm A / 0.90 arm B) | just assigned 13:40 UTC, awaiting pod pickup |
| #143 | thorfinn   | + **Lookahead outer optimizer** (k=5 arm A, k=10 arm B)              | stale_wip, no pickup yet since 11:30 UTC assignment |
| #151 | alphonse   | + **Aurora row-norm equilibration** (pre-polar, pp_iterations=2)     | assigned ~12:05 UTC, awaiting pod pickup |
| #150 | fern       | + **Cautious update sign-mask** (post-polar, before u/w-floor)       | assigned ~12:05 UTC, awaiting pod pickup |
| #140 | tanjiro     | + **SOAP-MLP + u/w-floor stack** on PMuon                           | stale_wip, no pickup yet since ~10:40 UTC assignment |
| #129 | frieren    | + **PMuon β_cov scan** (0.90/0.95/0.99) on u/w-floor base           | arm B `86t9bo8l` bcov=0.95 step 2847 ETA 14:13; green-lit arm C 0.99 then arm A clean 0.90 |
| #131 | askeladd   | + **TARGET_UW sweep** {0.25, 0.30, 0.40, 0.45}                      | arm 0p40 sr=3150 DONE; arms 0p45/0p25/0p30 pending |

## Closed this session

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| #118 | edward  | cooldown_frac scan: arm A sr=3175 val=3.27493, arm B sr=3150 val=3.27415 | Closed null; default 0.7 is plateau optimum; → PR #158 LLRD |
| #93 | fern     | NorMuon row-wise on PMuon+u/w base: sr=3175 val=3.2757 | Closed null; direction-shaping on PMuon redundant; → PR #150 Cautious sign-mask |
| #119 | alphonse | Contra-Muon arm B+: coeff=0.05 warmup=500, sr=-1, val=3.316 (never crossed) | Closed fundamental incompatibility; bilateral whitening×orthogonal perturbation; → PR #151 Aurora |
| #110 | thorfinn | γ-scan: arm A γ=0.25 sr=3150 val=3.27286, arm B γ=0.35 sr=3150 val=3.27380 | Closed null; γ=0.30 is optimal; → PR #143 Lookahead |
| #83 | tanjiro  | SOAP-MLP on bare PMuon: sr=3150 val=3.27419, null vs PR #64 (Δval=−0.00028) | Closed null; u/w-floor not substitutable by SOAP; → PR #140 SOAP+u/w stack |
| #94 | askeladd | u/w-floor: sr=3100 val=3.267696 n=2 ✓ | **MERGED** — new baseline |
| #85 | nezuko   | Power-law γ=1.2 on bare PMuon (n=2): sr=3125 val=3.27505 | Closed: n=2 confirmed but loses to new baseline (sr+25, val+0.0074) |
| #65 | frieren  | MuonH hyperball: val=3.3302, target never reached, −1 sr | Closed negative; PMuon whitening incompatible with hyperball |
| #89 | thorfinn | Per-module init on PMuon: sr=3175 (+25 worse), margin 0.00361 fails | Closed negative |
| #88 | edward   | Soft-Muon p=0.1 cooldown: sr=3150 (same as baseline), null | Closed null |
| #95 | alphonse | Contra-Muon coeff=0.2 and 0.1: both catastrophically diverge | Closed negative; dir_norm_ratio=1.59 root cause → PR #119 |
| #59 | alphonse | Vanilla Muon: 3350 steps, val 3.29743 (target NOT reached) | Attribution anchor |
| #61 | askeladd | NorMuon standalone: sr=3275, val 3.27920 (n=1) | Mechanism validated; stacking attempt in #93 |
| #63 | edward   | u/w floor: 1/2 hit at sr=3275 val 3.278 | Mechanism returns in #94 |
| #67 | nezuko   | SOAP-MLP standalone: sr=3200, val 3.27705 | Mechanism returns in #140 |
| #69 | thorfinn | KL-SOAP-H: projected ~3.9 at step 3150 | Clean negative; NS polar essential |
| #84 | askeladd | NorMuon on broken Aurora+Contra+u/w base: divergent | Base was the problem |

## Key cross-cutting issues

1. **`sample_tensor` linspace bug** — FIXED in PR #64 merge (fp64+clamp variant).

2. **Inductor compile bug — KNOWN, workaround applied.** `torch.compile(model, dynamic=False)` NaNs `blocks.0.attn.proj.bias` grad at step 1 on RTX PRO 6000 Blackwell.
   - **Vanilla Muon / PMuon**: `dynamic=True` fixes it
   - **Aurora+Contra+u/w**: `dynamic=True` alone NOT sufficient — PR #68 was unreproducible

3. **bf16 vs fp32 in NS** — frieren's finding: NS in raw bf16 triggers NaN; explicit fp32 cast required before NS.

4. **Contra-Muon × PMuon fundamental incompatibility** — even with correct measured-scale calibration and linear warmup ramp, Contra-Muon at any tested coeff destabilizes PMuon's bilateral covariance. CLOSED in PR #119.

5. **u/w-floor fires universally** — PMuon's whitening always shrinks below 0.35·‖w‖, making TARGET_UW a de facto update magnitude multiplier. This couples β_cov and TARGET_UW: PR #129 β_cov scan may reveal the optimal covariance tracking rate for this combined system.

6. **Silent-fail rate-limit duplicate launch pattern** — confirmed across frieren PR #129 (4 arm relaunches), nezuko PR #137, edward PR #118, thorfinn PR #110. Root cause: pod's assignment poller raises JSONDecodeError on rate-limited 403s and silently sleeps; on wake it doesn't see a recent PR comment and re-launches. Intervention: add `pgrep -f train_gpt_simple` guard before any torchrun call.

7. **SOAP-MLP vs u/w-floor substitutability** — PR #83 closed this: SOAP's mid-training advantage evaporates during cooldown. u/w-floor's late-phase magnitude inflation is mechanistically distinct from SOAP's second-moment normalization. The two may compose orthogonally (PR #140 tests this).

8. **Power-law cooldown wins on schedule shape** — PR #137 n=1 result: γ=1.2 concave-down cooldown hits target 25 steps faster than linear cosine cooldown on the same base. Pending n=2 confirmation. If confirmed, power-law cooldown becomes the new schedule default.

## Cross-cutting pattern: direction-shaping mechanisms null on PMuon base

Confirmed from PRs #83, #93, #110, #118, #119: **all post-polar direction-shaping mechanisms and schedule scalar tweaks produce null or negative results on PMuon+u/w-floor**. PMuon's bilateral whitening (`L^{-γ} R^{-γ}`) already does the heavy lifting on update shape. The wins on this base come from:
1. **Magnitude control** (u/w-floor itself — PR #94; TARGET_UW sweep — PR #131; LLRD — PR #158)
2. **Schedule shape** (power-law cooldown — PR #137 🔥 potential winner)
3. **Outer-loop mechanisms** (Lookahead — PR #143)
4. **Pre-polar mechanisms** (Aurora — PR #151)
5. **Sign-coherence** (Cautious update — PR #150)
6. **Covariance tracking** (β_cov scan — PR #129)

This insight guides what to try: avoid more post-polar scaling/whitening; focus on outer-loop, pre-polar, magnitude, and schedule.

## Wave 4 priorities (as of 14:25 UTC)

1. **PR #137 nezuko seed-2 launch** — POTENTIAL WINNER. SENT BACK to nezuko at 14:00 UTC for n=2 confirmation. Seed-2 ETA ~3.5h after pickup. If sr ≤ 3100 mean with n=2 stat-sig clear, merge — first speedrun improvement this session.
2. **PR #129 frieren β_cov scan** — arm B bcov=0.95 step 2847 finishing ~14:13 UTC; advisor green-lit arm C 0.99 then arm A clean 0.90. Three-arm comparison after both finish.
3. **PR #131 askeladd TARGET_UW sweep** — arm 0p45 needs launch (highest priority); then 0p25/0p30.
4. **Stale pickups: PRs #140 tanjiro (SOAP+u/w), #143 thorfinn (Lookahead), #158 edward (LLRD)** — none have student comments yet, may need pickup nudges if still stale on next loop.
5. **PRs #150 fern (Cautious), #151 alphonse (Aurora)** — awaiting pod pickup, only ~2h since assignment.
6. **n≥4 seed batch on new local best** after PR #137 confirms (or after next winner emerges).

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004` required for final claims. **Current baseline is sr=3100, val=3.267696** (n=2 PR #94). At n=1, val ≤ 3.276 is required to even approach the target. Anything within 0.004 of 3.267696 at n=1 needs n=2 confirmation before merge.
