# SENPAI Research State

- 2026-05-17 ~04:35 UTC — Cycle 42
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Merge bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

## Critical in-flight experiments (priority order)

### NEZUKO #212 — Attn-SOAP+trust Screen B (T=0.85) 🔥
- Screen A (T=0.9 `h29cv26c`): val=3.27628 (VAL WIN −0.00020), ffs=3125 — ffs miss
- Screen B (T=0.85): running since 03:25 UTC, ETA ~05:00 — activates v/proj SOAP gate
- IF both val WIN + ffs ≤ 3118 → predeclare n=4 immediately
- Mechanism: Attn-SOAP+trust has lowest variance of any mechanism tested (std=0.00015 per prior n=4)

### FERN #208 — Power-law LR cooldown (proper CM=0.5)
- `rpws9fug` (LR_POWER=1.5 + CONTRA_MUON=0.5): running since 03:25 UTC, ETA ~04:55
- Previous `ersqpsq2` misconfigured with CONTRA_MUON=0.4 — not decision-tree-applicable
- After rpws9fug: launch LR_POWER=2.0 arm sequentially

### EDWARD #199 — AdEMAMix aux groups — RETRY AUTHORIZED
- Both 3175-step seeds NaN'd at step 25 (baseline seed-0 instability, not AdEMAMix)
- Advisor overrode decision tree: authorized `--num_trials 4` retry to sample multiple seeds
- α=1.0, β3=0.99, warmup=1024, eps=1e-8 (conservative HPs, code validated)
- Retry launch pending

### TANJIRO #214 — TARGET_UW retune
- Code pushed (commit 880860c): `TARGET_UW = float(os.environ.get("TARGET_UW", "0.35"))`
- Predeclared arms: 0.30 then 0.40 (sequential)
- Nudge posted with launch command — awaiting student launch

### THORFINN #219 — Annealed Muon momentum μ schedule 🔥
- Arm A (MU_START=0.90→MU_END=0.97), Arm B (MU_START=0.97→MU_END=0.90)
- Linear μ interpolation in `set_hparams`, ~2 lines of code
- Fresh assignment — student picking up

### FRIEREN #221 — Adam-style Muon momentum bias correction 🔥
- MUON_BIAS_CORR=1: adds `1/(1-μ^t)` scaling before NS5+contra
- Targets early training FFS-critical window where momentum EMA is biased
- Fresh assignment — student picking up

### ALPHONSE #223 — SOAP_BETA2 retune {0.85, 0.92}
- SOAP_BETA2=0.90 was tuned before CONTRA_MUON=0.5; may need re-tuning
- Arm A (0.85, faster tracking), Arm B (0.92, slower tracking)
- Fresh assignment — student picking up

### ASKELADD #224 — Per-module init Variant B (non-zero proj init)
- Zero-init variant (PR #213) CLOSED — val=3.280419, MISS by 0.004
- Variant B: proj.weight init to N(0, 1/(n_embd×√2)) instead of zero
- Fresh assignment — student picking up

## CONTRA_MUON axis — EXHAUSTED ⛔
- 0.4 (PR #78): merged, beaten
- **0.5 (PR #139): current baseline**
- 0.6: rising shoulder, tied within noise
- 0.7: NaN at step 25 (catastrophic divergence)
- Do NOT sweep CONTRA_MUON further.

## Key patterns observed

1. **CONTRA_MUON bowl confirmed**: 0.5 is local optimum. 0.6 on rising shoulder, 0.7 over cliff. EXHAUSTED axis.

2. **Attn-SOAP+trust val WIN** (nezuko #212, Screen A): val=3.27628 is a VAL WIN. FFS=3125 still missing. Screen B may close ffs gap.

3. **Soft-Muon-anneal structural ffs miss**: p_start insensitive in [0.07,0.10]. FFS=3125 bucket is reliable landing. Mechanism needs pairing with something else. **CLOSED.**

4. **Per-module init absorbed by SOAP+NS5**: zero-init doesn't transfer from simpler stacks. Variant B (small non-zero) still to test.

5. **Step-2 NaN is seed-deterministic**: trial_idx=0 deterministically NaN-s for many 1-GPU runs. trial_idx=1,2,3 often pass. Use `--num_trials 4` when screening uncertain mechanisms.

6. **cooldown_frac=0.70 confirmed local optimum**: 0.65 and 0.75 both worse. Cooldown scalar is settled.

7. **SOAP_BETA2 not yet retuned post CM=0.5 merge**: alphonse #223 testing this.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~04:55 | Fern | LR_POWER=1.5+CM=0.5 `rpws9fug` terminal | True power-law baseline comparison |
| ~05:00 | Nezuko | Screen B TRUST_THRESHOLD=0.85 terminal | KEY: val WIN + ffs ≤ 3118? → n=4 |
| TBD | Edward | AdEMAMix num_trials=4 retry | Expecting ≥1 clean seed via seed diversity |
| TBD | Tanjiro | TARGET_UW=0.30 screen | u/w-floor vs new CONTRA_MUON base |
| TBD | Thorfinn | Annealed μ Arm A terminal | ~+95 min after launch |
| TBD | Frieren | Bias-corr-muon screen | ~+95 min after launch |
| TBD | Alphonse | SOAP_BETA2=0.85 screen | ~+95 min after launch |
| TBD | Askeladd | Proj-init Variant B screen | ~+95 min after launch |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.

Most promising paths (ranked):
1. **Attn-SOAP+trust Screen B** (nezuko #212) — val already winning at T=0.9, need ffs
2. **Annealed μ schedule** (thorfinn #219) — mechanism-level, could hit early training
3. **Bias-corrected Muon momentum** (frieren #221) — canonical Adam technique, fresh on this stack
4. **SOAP_BETA2 retune** (alphonse #223) — post-merge HP interaction
5. **AdEMAMix on aux groups** (edward #199) — sound code, needs clean seed
6. **Power-law LR** (fern #208) — proper CM=0.5 screen imminent
7. **TARGET_UW retune** (tanjiro #214) — cheap 1-HP u/w-floor sweep
8. **Proj-init Variant B** (askeladd #224) — lower confidence given prior negative

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **CONTRA_MUON axis: EXHAUSTED.** 0.5 is confirmed local optimum. Do not assign further CONTRA_MUON sweeps.
- **Step-2 NaN**: seed-deterministic baseline instability. Use `--num_trials 4` for screens where mechanism is uncertain. Do NOT rely on 200-step smokes.
- Closed this session: PR #178 (thorfinn cooldown_frac), #177 (frieren soft-muon), #205 (alphonse CONTRA_MUON), #213 (askeladd per-module init zero-init)
- New assignments this session: PR #219 (thorfinn annealed-μ), #221 (frieren bias-corr-muon), #223 (alphonse SOAP_BETA2), #224 (askeladd proj-init-variantb)
