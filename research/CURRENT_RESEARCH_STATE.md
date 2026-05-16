# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-16 11:30 (PR #110 thorfinn CLOSED — γ-scan null; PR #143 thorfinn ASSIGNED — Lookahead outer optimizer; edward dup killed; fern approaching target at step 2975 val 3.30)
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3100 steps (new local best); public record is 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3100 steps, val/loss 3.267696 (n=2 mean)** — PR #94 (g1r1-askeladd, PMuon + Skylight u/w-floor, TARGET_UW=0.35).
W&B runs: `yeyewcj6` (n=1) + `205sycku` (n=2 confirm). Merged 2026-05-16.

n=2 stat-sig margin: (3.28 − 3.267696)·√2 = 0.01740 ✓

**Key property:** u/w-floor fires at 100% of eligible params every step — the floor acts as a universal update magnitude multiplier, not a targeted safety catch. γ and TARGET_UW are coupled hyperparameters for the new base.

## Active experiments (status:wip) — Wave 4

| PR  | Student     | Mechanism on PMuon + u/w-floor base                                  | Status (as of 11:30) |
| --- | ----------- | --------------------------------------------------------------------- | ------ |
| #143 | thorfinn   | + **Lookahead outer optimizer** (k=5 arm A, k=10 arm B)              | just assigned, awaiting pod pickup |
| #140 | tanjiro     | + **SOAP-MLP + u/w-floor stack** on PMuon                           | assigned ~10:40 UTC, awaiting pod pickup |
| #93 | fern        | + **NorMuon row-wise** retry                                         | `63c3s1sl` step 2975/3250 val **3.2997** ⚠️ approaching target — ETA crossing ~11:35 UTC |
| #118 | edward     | + **cooldown_frac scan** (0.5 vs 0.8, default 0.7)                  | arm A `6fpu600z` FINISHED sr=3175 val=3.27493; arm B `dvjzqltr` step 2125/3250, dup `tjy6hfpm` KILLED, ETA ~12:35 UTC |
| #119 | alphonse   | + **Measured-scale Contra-Muon** arm B coeff=0.05 warmup=500        | `q54bnxvq` step 2625/3250 val 3.385, descending, ETA ~13:00 UTC |
| #129 | frieren    | + **PMuon β_cov scan** (0.90/0.95/0.99) on u/w-floor base           | ALL 0p90 arms crashed (5 total); `86t9bo8l` bcov=0.95 running step 775; 0p99 arm needed after 0p95 finishes |
| #131 | askeladd   | + **TARGET_UW sweep** {0.25, 0.30, 0.40, 0.45}                      | arm 0p40 `imf0s97n` step 2650/3250 val 3.359, ETA ~12:00 UTC; arms 0p25/0p30/0p45 sequential |
| #137 | nezuko     | + **Stack power-law cooldown γ=1.2 on u/w-floor base** (n=1)        | `8quuvdrj` step 1500 val 3.54, ETA ~14:00 UTC; dup `o333ajw3` CRASHED |

## Closed this session

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| #110 | thorfinn | γ-scan: arm A γ=0.25 sr=3150 val=3.27286, arm B γ=0.35 sr=3150 val=3.27380 | Closed null; γ=0.30 is optimal; → PR #143 Lookahead |
| #83 | tanjiro  | SOAP-MLP on bare PMuon: sr=3150 val=3.27419, null vs PR #64 (Δval=−0.00028) | Closed null; u/w-floor not substitutable by SOAP; → PR #140 SOAP+u/w stack |
| #94 | askeladd | u/w-floor: sr=3100 val=3.267696 n=2 ✓ | **MERGED** — new baseline |
| #85 | nezuko   | Power-law γ=1.2 (n=2): sr=3125 val=3.27505, margin 0.0070 ✓ | Closed: n=2 confirmed but loses to new baseline (sr+25, val+0.0074) |
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

4. **Contra-Muon × PMuon fundamental incompatibility** — even with correct measured-scale calibration and linear warmup ramp (200 steps), Contra-Muon at coeff=0.10 re-destabilizes PMuon's bilateral covariance at step ~500 when warmup completes. Arm B (coeff=0.05, warmup=500) is the final attempt (PR #119 q54bnxvq — surviving stably past step 1775 as of 10:40 UTC).

5. **u/w-floor fires universally** — PMuon's whitening always shrinks below 0.35·‖w‖, making TARGET_UW a de facto update magnitude multiplier. This couples β_cov and TARGET_UW: PR #129 β_cov scan may reveal the optimal covariance tracking rate for this combined system.

6. **Silent-fail rate-limit duplicate launch pattern** — confirmed across frieren PR #129 (4 arm relaunches), nezuko PR #137, edward PR #118, thorfinn PR #110. Root cause: pod's assignment poller raises JSONDecodeError on rate-limited 403s and silently sleeps; on wake it doesn't see a recent PR comment and re-launches. Intervention: add `pgrep -f train_gpt_simple` guard before any torchrun call.

7. **SOAP-MLP vs u/w-floor substitutability** — PR #83 closed this: SOAP's mid-training advantage (0.03–0.04 val/loss below baseline through step 1875) evaporates during cooldown. u/w-floor's late-phase magnitude inflation is mechanistically distinct from SOAP's second-moment normalization. The two should compose orthogonally (PR #140 tests this).

## Wave 4 priorities

1. **PR #93 fern NorMuon row-wise** — URGENT: step 2975 val 3.2997, on track to cross 3.28 by step ~3075-3100. If it beats baseline, request n=2 immediately.
2. **PR #129 frieren β_cov scan** — bcov=0.90 definitively broken (5 crashes); 0p95 `86t9bo8l` step 775 running, 0p99 arm needed after.
3. **PR #131 askeladd TARGET_UW sweep** — arm 0p40 finishing ~12:00 UTC; sequential arms 0p25/0p30/0p45 follow.
4. **PR #118 edward cooldown_frac=0.8** — arm B `dvjzqltr` finishing ~12:35 UTC.
5. **PR #140 tanjiro SOAP-MLP + u/w-floor stack** — awaiting pickup.
6. **PR #143 thorfinn Lookahead (k=5/10)** — awaiting pickup (just assigned).
7. **PR #137 nezuko power-law cooldown** — `8quuvdrj` step 1500 val 3.54, finishing ~14:00 UTC.
8. **PR #119 alphonse Contra-Muon arm B** — `q54bnxvq` step 2625 val 3.385, likely not crossing but let it finish cleanly.
9. **n≥4 seed batch on new local best** when frontier stabilizes.

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004` required for final claims. **New baseline is sr=3100, val=3.267696** (n=2 PR #94). At n=1, val ≤ 3.276 is required to even approach the target. Anything within 0.004 of 3.267696 at n=1 needs n=2 confirmation before merge.
