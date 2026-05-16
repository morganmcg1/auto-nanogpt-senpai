# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-16 09:35 (Wave 4 active: PR #94 MERGED new baseline sr=3100 val=3.267696 n=2; PR #85 nezuko CLOSED n=2 confirmed worse-than-baseline; PR #129 frieren bcov=0.90 CRASHED; PR #137 nezuko newly assigned stacking power-law cooldown on u/w-floor base; PR #131 askeladd uw_sweep arm 0p40 running; PR #119 alphonse arm B q54bnxvq surviving past step 500)
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3100 steps (new local best); public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3100 steps, val/loss 3.267696 (n=2 mean)** — PR #94 (g1r1-askeladd, PMuon + Skylight u/w-floor, TARGET_UW=0.35).
W&B runs: `yeyewcj6` (n=1) + `205sycku` (n=2 confirm). Merged 2026-05-16.

n=2 stat-sig margin: (3.28 − 3.267696)·√2 = 0.01740 ✓

**Key property:** u/w-floor fires at 100% of eligible params every step — the floor acts as a universal update magnitude multiplier, not a targeted safety catch. γ and TARGET_UW are coupled hyperparameters for the new base.

## Active experiments (status:wip) — Wave 4

| PR  | Student     | Mechanism on PMuon + u/w-floor base                                  | Status |
| --- | ----------- | --------------------------------------------------------------------- | ------ |
| #110 | thorfinn   | + **PMuon γ-scan** (γ=0.25 arm A, γ=0.35 arm B)                     | arm A `hehdzpld` FINISHED val 3.2729 (vs new baseline: neutral); arm B `2ipgcjyn` step 1725/3250 val 3.49 |
| #83 | tanjiro     | + **SOAP-MLP** on PMuon                                              | full run `il6j69lr` step 2500/3250 val 3.36, ETA ~10:00 UTC, **tracking 0.03-0.04 BELOW PMuon+u/w baseline** |
| #93 | fern        | + **NorMuon row-wise** retry                                         | `63c3s1sl` step 1600/3250 val 3.51, stable after 3 prior crashes |
| #118 | edward     | + **cooldown_frac scan** (0.5 vs 0.8, default 0.7)                  | arm A `6fpu600z` FINISHED sr=3175 val=3.27493 (passes 3.28 but worse than new baseline); arm B `dvjzqltr` running step 675/3250 |
| #119 | alphonse   | + **Measured-scale Contra-Muon** arm B coeff=0.05 warmup=500        | arm B `q54bnxvq` SURVIVING past step 800 val 3.76 (warmup completed at step 500, no re-explosion) |
| #129 | frieren    | + **PMuon β_cov scan** (0.90/0.95/0.99) on u/w-floor base           | arm A bcov=0.90 `7gfef9tv` CRASHED at step 625, advisor alert posted; student to diagnose + relaunch |
| #131 | askeladd   | + **TARGET_UW sweep** {0.25, 0.30, 0.40, 0.45}                      | arm 0p40 `imf0s97n` step 850/3250 val 3.75; arms 0p25/0p30/0p45 sequential |
| #137 | nezuko     | + **Stack power-law cooldown γ=1.2 on u/w-floor base** (n=1)        | newly assigned Wave 4; tests mechanism orthogonality |

## Closed this session

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| #94 | askeladd | u/w-floor: sr=3100 val=3.267696 n=2 ✓ | **MERGED** — new baseline |
| #85 | nezuko   | Power-law γ=1.2 (n=2): sr=3125 val=3.27505, margin 0.0070 ✓ | Closed: n=2 confirmed but loses to new baseline (sr+25, val+0.0074) |
| #65 | frieren  | MuonH hyperball: val=3.3302, target never reached, −1 sr | Closed negative; PMuon whitening incompatible with hyperball |
| #89 | thorfinn | Per-module init on PMuon: sr=3175 (+25 worse), margin 0.00361 fails | Closed negative |
| #88 | edward   | Soft-Muon p=0.1 cooldown: sr=3150 (same as baseline), null | Closed null |
| #95 | alphonse | Contra-Muon coeff=0.2 and 0.1: both catastrophically diverge | Closed negative; dir_norm_ratio=1.59 root cause → PR #119 |
| #59 | alphonse | Vanilla Muon: 3350 steps, val 3.29743 (target NOT reached) | Attribution anchor |
| #61 | askeladd | NorMuon standalone: sr=3275, val 3.27920 (n=1) | Mechanism validated; stacking attempt in #93 |
| #63 | edward   | u/w floor: 1/2 hit at sr=3275 val 3.278 | Mechanism returns in #94 |
| #67 | nezuko   | SOAP-MLP standalone: sr=3200, val 3.27705 | Mechanism returns in #83 |
| #69 | thorfinn | KL-SOAP-H: projected ~3.9 at step 3150 | Clean negative; NS polar essential |
| #84 | askeladd | NorMuon on broken Aurora+Contra+u/w base: divergent | Base was the problem |

## Key cross-cutting issues

1. **`sample_tensor` linspace bug** — FIXED in PR #64 merge (fp64+clamp variant).

2. **Inductor compile bug — KNOWN, workaround applied.** `torch.compile(model, dynamic=False)` NaNs `blocks.0.attn.proj.bias` grad at step 1 on RTX PRO 6000 Blackwell.
   - **Vanilla Muon / PMuon**: `dynamic=True` fixes it
   - **Aurora+Contra+u/w**: `dynamic=True` alone NOT sufficient — PR #68 was unreproducible

3. **bf16 vs fp32 in NS** — frieren's finding: NS in raw bf16 triggers NaN; explicit fp32 cast required before NS.

4. **Contra-Muon × PMuon fundamental incompatibility** — even with correct measured-scale calibration and linear warmup ramp (200 steps), Contra-Muon at coeff=0.10 re-destabilizes PMuon's bilateral covariance at step ~500 when warmup completes. Arm B (coeff=0.05, warmup=500) is the final attempt (PR #119).

5. **u/w-floor fires universally** — PMuon's whitening always shrinks below 0.35·‖w‖, making TARGET_UW a de facto update magnitude multiplier. This couples β_cov and TARGET_UW: PR #129 β_cov scan may reveal the optimal covariance tracking rate for this combined system.

## Wave 4 priorities (after pending Wave 3 results)

1. **PR #85 nezuko n=2 power-law cooldown** — trial 2 in progress. Even if it clears stat-sig at n=2, must beat new sr=3100 baseline to merge.
2. **PR #129 frieren β_cov scan** {0.90, 0.95, 0.99} — highest-value unexplored HP on new base.
3. **TARGET_UW sweep** {0.25, 0.30, 0.40, 0.45} — since floor fires 100%, 0.35 may not be optimal. Assign to askeladd (newly idle).
4. **PMuon γ-scan arm B (γ=0.35)** — thorfinn `2ipgcjyn` just launched; result in ~4h.
5. **Stack PR #85 winner (if any) + u/w-floor** — if power-law cooldown beats new baseline, stack.
6. **MuLoCo / Lookahead outer Nesterov** — sync_interval=30 outer copy on PMuon+u/w-floor. Assign when portfolio empties.
7. **n≥4 seed batch on new local best** when frontier stabilizes.

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004` required for final claims. **New baseline is sr=3100, val=3.267696** (n=2 PR #94). At n=1, val ≤ 3.276 is required to even approach the target. Anything within 0.004 of 3.267696 at n=1 needs n=2 confirmation before merge.
