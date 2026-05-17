# SENPAI Research State

- 2026-05-17 ~06:45 UTC — Cycle 44
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Merge bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

## 🚀 PROMOTED — n=4 CONFIRMATION RUNNING

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 IN PROGRESS 🔥🔥🔥
- **Screen B (`5g7k1w3q`, T=0.85): val=3.27475 (−0.00173), ffs=3100 (−18.75)** — BOTH BARS CLEARED
- Trust-gate at T=0.85: v on 50%, proj on 100%, overall 87.5% — vs T=0.9 (v 0%, proj 17%, 35%)
- **n=4 confirm trial 1 running** (`3xn3ox1c`); ETA full n=4 ~12:50 UTC
- Trial 1 healthy: no NaN, on convergence trajectory
- This is the strongest signal of the round — MERGE CANDIDATE

## Critical in-flight experiments

### THORFINN #219 — Annealed Muon momentum μ schedule
- **Arm A `uh2vhuu9` (MU_START=0.90→MU_END=0.97)**: ~80% done (step 2500/3175), val=3.3759
- ETA Arm A terminal ~07:30 UTC
- Arm B (0.97→0.90) will run sequentially after

### FERN #208 — Power-law LR (LR_POWER=2.0 arm)
- `drhk18xa` (LR_POWER=2.0 + CM=0.5): ~53% done (step 1700/3175), val=3.4738
- ETA terminal ~07:15 UTC
- LR_POWER=1.5 MISSED by +0.006 val. 2.0 is opposite curvature (front-loaded)

### ALPHONSE #223 — SOAP_BETA2 retune — TROUBLE
- SOAP_BETA2=0.85 NaN cascade: `67w5zyph` NaN step 318, `6gsl9ljw` NaN step 1175
- n=4 retry `grpcqmun` at step 1525, NaN (trial 1 still running)
- **Key concern**: NaN at step 1175+ suggests HP-induced instability, not just seed-0 NaN
- HYPOTHESIS: SOAP_BETA2=0.85 is too fast-tracking for the merged stack; skip to 0.92

### TANJIRO #214 — TARGET_UW retune — TROUBLE  
- 0.30 arm: 3+ NaN crashes at trial_idx=0 (8mz9zmp9, multiple others)
- n=4 retry `y3lccflx` at step 1625, NaN (trial 1 still running)
- Wait for trial 2 to start; if also NaN → TARGET_UW=0.30 genuinely destabilizes

## New assignments this cycle

### FRIEREN #238 — Cosine LR cooldown shape 🆕
- Replace linear cooldown with cosine: `eta = 0.5*(1+cos(π*t_frac))`
- Cooldown duration (cooldown_frac=0.70) settled; this is the orthogonal SHAPE axis
- Concentrates LR 14% higher in steep-descent early-cooldown window
- Predeclared single-arm screen: `COOLDOWN_SHAPE=cosine CONTRA_MUON=0.5`

### ASKELADD #239 — Lion optimizer on aux groups 🆕
- Replace AdamW (embed, lm_head, scalars) with Lion sign-based optimizer
- LRs calibrated: embed=3e-4 (vs AdamW 0.3), lm_head=3e-5 (vs 1/320), scalars=1e-2
- 200-step smoke REQUIRED first; Lion has no second moment → low NaN cascade risk
- Mechanism: sign normalization uniform across token frequencies → faster early embedding

### EDWARD #240 — Adaptive NS5 iteration schedule 🆕
- Schedule: 16 iters steps 0-499, 12 iters steps 500-1999, 8 iters steps 2000+
- Better early-training orthogonalization → more equal step sizes → FFS improvement
- Optional diagnostic: log ||X X^T - I||_F at iters 8, 12, 16 at step 100 to verify mechanism
- Orthogonal to all current axes; very low NaN risk

## Closed this session (cycles 41-44)

| PR | Description | Result |
|---|---|---|
| #178 | Thorfinn cooldown_frac sweep | 0.70 local optimum |
| #177 | Frieren soft-muon-anneal | structural ffs miss |
| #205 | Alphonse CONTRA_MUON sweep | 0.5 bowl optimum |
| #213 | Askeladd per-module init zero-init | MISS by 0.004 |
| #199 | Edward AdEMAMix aux groups | multi-seed NaN, no clean trial |
| #221 | Frieren bias-corr Muon momentum | MISS val=3.279 |
| #224 | Askeladd proj-init Variant B | MISS val=3.280 |

## CONTRA_MUON axis — EXHAUSTED ⛔
- 0.4 (PR #78): merged, beaten
- **0.5 (PR #139): current baseline**
- 0.6: rising shoulder
- 0.7: NaN at step 25
- Do NOT sweep CONTRA_MUON further.

## Per-module init axis — EXHAUSTED ⛔
- Standard fan-in: baseline behavior
- Zero-init (PR #213): MISS by 0.004
- Small non-zero std=0.00221 (PR #224): MISS by 0.003
- SOAP+NS5 absorbs all init-scale benefits on this stack.

## Key patterns observed

1. **CONTRA_MUON bowl**: 0.5 = optimum. EXHAUSTED.
2. **Per-module init absorbed by SOAP+NS5**: all variants miss by 0.003-0.004. EXHAUSTED.
3. **Attn-SOAP+trust T=0.85 strong WIN**: val=3.27475, ffs=3100. n=4 pending.
4. **Muon bias correction miss**: 1/(1-μ^t) doesn't compose with NS5+contra pipeline.
5. **AdEMAMix amplifies early-training NaN cascade**: mechanism interaction with high-LR embed.
6. **Step-2 NaN seed-deterministic**: trial_idx=0. Use `--num_trials 4` for uncertain mechanisms.
7. **Multi-seed NaN cascade** (SOAP_BETA2=0.85, TARGET_UW=0.30): some HPs destabilize across ALL seeds. Distinguishable by NaN step > 100 (vs baseline NaN at step 25).
8. **cooldown_frac=0.70**: confirmed local optimum.
9. **Power-law LR=1.5**: MISS (+0.006 val). Testing 2.0.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~07:15 | Fern | LR_POWER=2.0 `drhk18xa` terminal | Likely MISS (1.5 missed by 0.006) |
| ~07:30 | Thorfinn | Annealed μ Arm A `uh2vhuu9` terminal | Mechanism-level early-training test |
| ~12:50 | Nezuko | Attn-SOAP T=0.85 n=4 confirm | KEY: MERGE if all 4 bars clear |
| TBD | Alphonse | SOAP_BETA2=0.85 n=4 trial 2 status | Expect more NaN → skip to 0.92 |
| TBD | Tanjiro | TARGET_UW=0.30 n=4 trial 2 status | Expect NaN → switch to 0.40 |
| TBD | Frieren | Cosine cooldown screen | FFS-targeting via early-cooldown LR |
| TBD | Askeladd | Lion aux smoke then screen | Aux optimizer family swap |
| TBD | Edward | Adaptive NS iters screen | Early-training orthogonalization quality |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.

**If nezuko n=4 merges** (~12:50 UTC): new ffs baseline ~3100, gap to record shrinks to ~70 steps / ~2.3%.

Most promising paths (ranked):
1. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — RUNNING. Likely merge candidate.
2. **Adaptive NS5 iters** (edward #240) — directly targets FFS via orthogonalization quality
3. **Lion aux groups** (askeladd #239) — optimizer family swap, sign-based early training
4. **Cosine cooldown shape** (frieren #238) — schedule shape, pure-FFS mechanism
5. **Annealed μ schedule** (thorfinn #219) — Arm A terminal soon
6. **SOAP_BETA2 retune** (alphonse #223) — 0.85 destabilizing; 0.92 needed
7. **TARGET_UW retune** (tanjiro #214) — 0.30 destabilizing; 0.40 needed
8. **Power-law LR** (fern #208) — 2.0 final arm, likely to close axis

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **CONTRA_MUON axis: EXHAUSTED.** Do not assign further sweeps.
- **Per-module init axis: EXHAUSTED.** Do not assign init variants.
- **Step-2 NaN**: seed-0 deterministic. Use `--num_trials 4` for uncertain mechanisms.
- **Multi-seed NaN** (SOAP_BETA2=0.85 etc.): HP-induced, NaN at steps 100-1200, not baseline issue.
- **Power-law LR axis**: 1.5 missed, 2.0 testing. Close after 2.0 if also miss.
