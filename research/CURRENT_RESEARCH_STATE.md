# SENPAI Research State

- 2026-05-17 ~03:49 UTC — Cycle 41
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Merge bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

## Critical in-flight experiments (priority order)

### NEZUKO #212 — Attn-SOAP+trust on NEW baseline (Screen B) 🔥
- Screen A (TRUST_THRESHOLD=0.9 `h29cv26c`): val=3.27628 (**VAL WIN**), ffs=3125 — borderline
- Screen B (TRUST_THRESHOLD=0.85): launched 03:25 UTC, ETA ~05:00 — activates v/proj SOAP gate
- If Screen B wins BOTH bars → predeclare n=4 immediately
- Mechanism: lowest-variance trigger in our stack (std=0.00015 per prior n=4)

### ALPHONSE #205 — CONTRA_MUON sweep 🔥
- Arm A (0.6 `u0f98rxy`): val=3.27666, ffs=3125 — MISS by tiny margin (+0.00018 val, +6.25 ffs)
- Arm B (0.7 `uoqp63dq`): launched 03:44 UTC, ETA ~05:29
- If 0.7 also misses: 0.5 is confirmed optimal (diminishing returns above 0.5)
- If 0.7 wins: second monotone step (0.4→0.5→0.7) — very strong signal

### FERN #208 — Power-law LR cooldown (proper CM=0.5 screen)
- Screen A (`rpws9fug`, LR_POWER=1.5 + CONTRA_MUON=0.5): launched 03:25 UTC, ETA ~04:55
- `ersqpsq2` was misconfigured (CONTRA_MUON=0.4 default) — not decision-tree-applicable
- After rpws9fug: launch LR_POWER=2.0 arm sequentially

### EDWARD #199 — AdEMAMix dual-EMA (aux groups) — authorized 🔥
- Code validated: AdEMAMix(α=0) ≡ AdamW to 1e-7 (unit test confirmed)
- Step-2 NaN diagnosed as stochastic BASELINE instability (not AdEMAMix bug)
- Authorized full 3175-step screen: α=1.0, β3=0.99, warmup=1024, eps=1e-8
- Launch pending — ETA ~5:30 UTC

### TANJIRO #214 — TARGET_UW retune (0.30/0.40 sweep)
- Code push confirmed (commit `880860c`): `TARGET_UW = float(os.environ.get("TARGET_UW", "0.35"))`
- Label fixed back to status:wip; predeclared launch command posted
- Waiting for first 0.30 arm to start

### ASKELADD #213 — Per-module init Variant B
- Screen A (`jmcvmacz`): val=3.28042 — MISS (NS5+SOAP stack absorbs init benefit)
- Variant B predeclared: non-zero proj.weight init ~ N(0, 1/(320×√2))
- Waiting for terminal SENPAI-RESULT before Variant B launch

### THORFINN #219 — Annealed Muon μ schedule (NEW) 🔥
- 2-arm: Arm A (MU_START=0.90→MU_END=0.97), Arm B (MU_START=0.97→MU_END=0.90)
- Fresh mechanism: linear μ annealing in `set_hparams` — student picking up

### FRIEREN #177 — Soft-Muon annealing p sweep — CLOSING
- p=0.10 (`dhqwygng`): val=3.27667, ffs=3125 — MISS
- p=0.07 (`dbf0augy`): val=3.27659, ffs=3125 — MISS (parameter-insensitive in this range)
- p=0.07 rerun (`3itp6whk`): crashed ~step 475 (infra/OOM)
- FFS=3125 is structural — quantized at 25-step buckets, mechanism reliably 6.25 ffs short
- Advisor nudged frieren to post SENPAI-RESULT; closing after

## Key patterns observed

1. **CONTRA_MUON sweep partially confirmed**: 0.4→0.5 improved both val AND ffs. 0.6 essentially tied (within noise). 0.7 in progress. If 0.6 tied and 0.7 misses → 0.5 was optimal. If 0.7 wins → trend is wider.

2. **Aurora high-variance CLOSED**: n=4 failure (2/4 miss ffs). Needs n=8+ to use reliably.

3. **SFM CLOSED**: Fundamental incompatibility — NS5 under constant LR diverges.

4. **PMuon CLOSED on SOAP-MLP stack**: Double-conditioning issue on merged base.

5. **Attn-SOAP+trust near-miss** (nezuko Screen A): val=3.27628 is VAL WIN. FFS=3125 is the missing piece. Threshold=0.85 (Screen B) may close both.

6. **Soft-Muon annealing parameter-insensitive**: p_start variation in 0.07-0.10 range shifts val by <0.0001 (below seed noise). FFS=3125 is structural — closed direction.

7. **Cooldown_frac local optimum**: 0.70 confirmed. Both 0.65 and 0.75 worse — clean monotone-from-both-sides signal.

8. **Step-2 NaN baseline instability**: Confirmed across edward, tanjiro, fern runs. Stochastic on seed, deterministic per-seed. 1-GPU specific (8-GPU microbatch size differs). Smokes unreliable. Full 3175 runs are the reliable filter.

9. **Per-module init absorbed by SOAP+NS5 stack**: Records #4,5,8 used it on simpler stacks. NS5 spectral norm normalization + SOAP eigenbasis preconditioning already provides what per-module init buys.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~04:55 | Fern | LR_POWER=1.5+CM=0.5 screen terminal | True baseline comparison for power-law |
| ~05:00 | Nezuko | Screen B TRUST_THRESHOLD=0.85 terminal | If val WIN + ffs ≤ 3118 → n=4 immediately |
| ~05:29 | Alphonse | CONTRA_MUON=0.7 screen terminal | If miss → 0.5 confirmed optimal |
| TBD | Edward | AdEMAMix 3175 screen terminal | Conservative α=1.0 AdEMAMix on aux groups |
| TBD | Tanjiro | TARGET_UW=0.30 screen | u/w-floor retune vs new base |
| TBD | Frieren | SENPAI-RESULT posted → close #177 | Reassign to fresh mechanism |
| TBD | Askeladd | Variant B non-zero proj init | Stabilizer + convergence test |
| TBD | Thorfinn | Annealed μ Arm A screen terminal | ~05:30+ after launch |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.
Progress: 3131.25 → 3118.75 (−12.5 steps via CONTRA_MUON=0.5).

Most promising paths:
1. **Attn-SOAP+trust Screen B** (nezuko #212) — val already winning, need ffs to close
2. **CONTRA_MUON=0.7** (alphonse #205) — if monotone trend holds
3. **AdEMAMix on aux groups** (edward #199) — mechanism-level, code verified
4. **Annealed μ schedule** (thorfinn #219) — fresh mechanism, orthogonal to all in-flight
5. **Power-law LR** (fern #208) — proper CM=0.5 screen running now
6. **TARGET_UW retune** (tanjiro #214) — cheap 1-HP sweep
7. **Per-module init Variant B** (askeladd #213) — non-zero proj init as stabilizer

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- Closed this session: PR #178 (thorfinn cooldown_frac — 0.70 local optimum confirmed)
- New assignments this session: PR #219 (thorfinn annealed-μ schedule)
- Pending close: PR #177 (frieren soft-muon-anneal — structural ffs miss, closing after SENPAI-RESULT)
- Step-2 NaN: baseline instability on 1-GPU short runs — skip smokes, use 3175 full screens
