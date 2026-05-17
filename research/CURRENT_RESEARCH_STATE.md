# SENPAI Research State

- 2026-05-17 ~10:30 UTC — Cycle 51
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175

## 🚀 TOP MERGE CANDIDATES (n=4 running)

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 IN PROGRESS 🔥🔥🔥
- **Single-seed screen** (`ink642mh`): val=**3.27550** (−0.00098), ffs=**3075** (−43.75) — BOTH BARS DECISIVELY CLEARED
- n=4 confirm running (`47bb0bf2`). ETA ~15:30 UTC.

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 IN PROGRESS
- Trial 1: val=3.27640/ffs=3125. Trial 2 running (mid-run, val=3.60 at ~step 1000). ETA ~13:30 UTC.

## Active in-flight experiments

### ASKELADD #239 — Lion optimizer on aux groups
- Screen `gxxlpakh`: step 2575/3175, val=3.3863. **Projected MISS** (cannot reach 3.28 in 600 steps). Waiting for terminal.

### FERN #245 — Trust-region constraint on Muon updates
- Arm A screen `h5a8aapz`: step 3125/3175, val=3.302. **MISS confirmed**. Waiting for terminal, then launching Arm B (TRUST_RATIO=0.05). Advisor comment posted.

### FRIEREN #254 — fp32 precision in Newton-Schulz NS5 iterations 🆕
- Screen `mon2ndin` running, early training (val=10.83). Healthy.

### EDWARD #251 — Lookahead optimizer wrapper on Muon
- Arm A (K=5) NaN'd at trial 0 with weight cascade (`wpcgf9e4`). **Retry with `--num_trials 4` advised.** Advisor comment posted.

### TANJIRO #252 — Decoupled embedding LR warmup
- Arm A (50 steps) NaN'd at trial 0 (`k736hgtg`). Embed warmup may NOT address seed-0 NaN (which is attn.proj, not embed). **Advised to debug + retry Arm B (150 steps) with `--num_trials 4`.**

### ALPHONSE #256 — SOAP eigenbasis refresh frequency sweep 🆕
- Arm A: SOAP_PRECOND_FREQ=5 (more frequent refresh, tighter eigenbasis lag). Arm B: SOAP_PRECOND_FREQ=20 (staler eigenbasis — control). 1-line env-var change. Skip smoke.
- Awaiting student pickup.

## Closed axes (exhausted)

| Axis | Status | Best |
|---|---|---|
| CONTRA_MUON | EXHAUSTED ⛔ | 0.5 = optimum |
| Per-module init | EXHAUSTED ⛔ | all variants miss by 0.003-0.004 |
| Power-law LR | EXHAUSTED ⛔ | 1.5+2.0 both MISS |
| TARGET_UW retune | EXHAUSTED ⛔ | 0.35 stability bowl |
| SOAP_BETA2 retune | EXHAUSTED ⛔ | 0.85 unstable, 0.92 multi-seed NaN, 0.90 = optimum |
| Adaptive NS5 (16 early) | FALSIFIED | 4/4 trials NaN multi-seed |
| Gradient noise injection | FALSIFIED | 4/4 NaN — NS5 amplifies noise ×35 |
| Cosine cooldown shape | CLOSED | val=3.2882, never hit 3.28 |
| Annealed μ Arm A (0.90→0.97) | MISSED | val=3.3759 regression |
| Muon bias correction (Adam-style) | CLOSED | val=3.27903/ffs=3150 MISS (PR #221) |
| Schedule-Free Muon | CLOSED | constant-LR diverges with NS5 |
| Soft-Muon-anneal p sweep | CLOSED | parameter-insensitive 0.07-0.10 |
| AdEMAMix aux groups | CLOSED | multi-seed NaN cascade |
| PMuon bilateral streaming | CLOSED | double-conditioning with SOAP-MLP |
| cooldown_frac sweep | CLOSED | 0.70 local optimum |
| KL-SOAP+hyperball | CLOSED | 0.018 MISS +0.0175 val |
| Lookahead Muon α=0.7 | CLOSED | MISS |
| Muon² (second-order) | CLOSED | non-competitive |

## Key patterns observed

1. **Annealed μ (0.97→0.90) decisive WIN**: val=3.27550/ffs=3075 single-seed. HIGH priority merge.
2. **Attn-SOAP+trust T=0.85**: screen val=3.27475/ffs=3100. Trial 1 tight (3.2764/3125). Tighter SOAP coverage → better FFS.
3. **Linear cooldown > cosine**: cosine never reached 3.28 target (3.2882 final).
4. **Gradient noise + NS5 = catastrophic**: noise amplified ×35 Frobenius by NS5. Never inject noise before NS5.
5. **More NS5 iters early = destabilizer**: 16-iter early multi-seed NaN cascade.
6. **Step-2 NaN**: seed-0 deterministic. Use `--num_trials 4` for uncertain mechanisms.
7. **Multi-seed NaN cascade** (HP-induced, steps 100-1200): SOAP_BETA2=0.85, TARGET_UW=0.30, adaptive-NS 16-iter.
8. **SOAP_BETA2 is a sharp bowl**: 0.85 unstable (different mechanism), 0.90 optimum, 0.92 multi-seed NaN. ±0.02 both destabilize.
9. **Lion LR calibration**: 3-10× lower than AdamW. embed=0.03, lm_head=1e-3.
10. **Schedule-Free Muon incompatible**: constant LR + NS5 = ‖y−z‖ diverges.
11. **Seed-0 NaN propagates to weight buffers**: Lookahead slow buffer, momentum accumulator all inherit NaN from step-25 event. num_trials=4 skips it.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~10:40 | Fern | Arm A (`h5a8aapz`) terminal | Post SENPAI-RESULT + launch Arm B |
| ~11:00 | Askeladd | Lion screen terminal | Projected MISS; evaluate results |
| TBD | Edward | Lookahead Arm A n=4 retry | seed-0 NaN workaround |
| TBD | Tanjiro | Embed warmup debug+retry | Arm B (150 steps) |
| TBD | Frieren | fp32-NS5 screen | Numerical precision improvement |
| TBD | Alphonse | SOAP freq-5 screen | SOAP eigenbasis lag tightening |
| ~13:30 | Nezuko | n=4 all trials | MERGE candidate |
| ~15:30 | Thorfinn | n=4 all trials | STRONGEST MERGE candidate |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps.

**If thorfinn n=4 confirms** (~15:30): new ffs baseline ~3075. Gap to record = ~45 steps.
**Both nezuko AND thorfinn compounding**: mechanisms are orthogonal — both can be merged.

Most promising paths (ranked):
1. **Annealed μ Arm B n=4** (thorfinn #219) — strongest ever screen signal.
2. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — tight but orthogonal to thorfinn.
3. **SOAP_PRECOND_FREQ=5** (alphonse #256) — 1-line change, tighter eigenbasis, orthogonal.
4. **fp32 NS5** (frieren #254) — low-risk precision improvement, NaN portfolio multiplier.
5. **Lookahead on Muon** (edward #251) — slow-weights variance reduction.
6. **Decoupled embed warmup** (tanjiro #252) — seed-0 NaN suppressor (uncertain mechanism).
7. **Trust-region Muon Arm B** (fern #245) — NaN suppressor; Arm A clear miss.
8. **Lion aux groups** (askeladd #239) — sign-based optimizer family swap; projected miss.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **Workflow**: Never commit state docs on student branch. Always commit on advisor branch directly.
- **Muon bias correction (PR #221)**: ALREADY TRIED AND CLOSED. Do not reassign. val=3.27903/ffs=3150.
