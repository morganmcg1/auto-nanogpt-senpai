# SENPAI Research State

- 2026-05-16 17:55 UTC — Cycle 29 complete (thorfinn CLOSED + reassigned to cooldown_frac retune; frieren CLOSED + reassigned to Soft-Muon annealing)

## Current baseline

**Contra+SOAP-MLP (PR #78)** — n=4 mean=**3.27760**, ffs_mean=**3131.25** @ train_steps=3175  
Statsig bar (n=4): mean ≤ 3.27800 AND ffs_mean ≤ 3131.25

## Critical in-flight experiments (priority order)

### ALPHONSE #139 — CONTRA_MUON=0.5 n=4 RUNNING (T0 result: 3.2783/3150) 🔥
- Screen `yctj2ozd`: val=**3.27629**, ffs=**3125** — single-seed beat baseline
- n=4 `db1rrfx3` **T0 terminal: val=3.2783, ffs=3150** — higher than screen, indicating screen was seed-favored
- T1 in progress (~step 450/3175). ETA full n=4 ~22:30 UTC.
- **Path to merge is narrowing**: remaining 3 trials need mean val ≤ 3.27737 AND mean ffs ≤ 3125
- Still highest-priority result, but uncertain outcome now

### FERN #125 — Aurora n=4 LAUNCHED 🔥
- Screen `lqwaozx7`: val=**3.27706**, ffs=**3125** — BEATS merged baseline on BOTH metrics!
- Two prior crashes resolved by D.clamp_(1e-6, 1e6) fix
- n=4 predeclared (locked HPs: AURORA_PP_ITERATIONS=2, AURORA_PP_BETA=0.5, CONTRA_MUON=0.4, MUON_WEIGHT_DECAY=0.01) launched 16:26 UTC via setsid nohup
- Step time ~1.93s × 3175 × 4 = ~410 min wall-clock → ETA terminal ~23:20 UTC
- SECOND HIGHEST-PRIORITY RESULT. Aurora is fundamentally different mechanism than CONTRA_MUON tuning.
- Note: MUON_WEIGHT_DECAY=0.01 deviation from merged baseline (0.025) — but matches the FFS-winning screen config.

### NEZUKO #124 — Attn-SOAP + trust gate n=4 self-corrected
- Screen `udc2950s`: val=3.27802, ffs=3125 @ train_steps=3150 (single seed)
- Initial n=4 `y7ibpvry` killed at T1 step 1148/3150 — student self-caught wrong step count
- NEW n=4 `790h1llo` LAUNCHED 16:34 UTC at train_steps=3175 (corrective). ETA terminal ~24:00 UTC.
- Prediction: borderline mean ~3.2785, ffs ~3120-3150

### TANJIRO #161 — Lookahead screen REDO (`sks2z7oe`)
- Earlier extended verification `tbesgctw` hit val=3.3042 (MISS)
- NEW screen `sks2z7oe` launched 16:33 UTC. ETA terminal ~18:20 UTC.
- If screen MISS again: close PR, reassign to **PMuon (record #18)** — bilateral streaming covariance power preconditioning, γ=0.3, β=0.95

### ASKELADD #181 — Schedule-Free Muon (SFM)
- Just assigned (19:10 UTC). Awaiting smoke + screen.
- Mechanism: constant LR + Polyak iterate averaging, no cooldown anywhere
- PR #166 (KL-SOAP+H) closed — screen MISS at val=3.295, ffs=-1 (never crossed 3.28)

### FRIEREN #177 — Soft-Muon annealing on merged base
- Just assigned (16:26 UTC). Awaiting smoke + screen.
- Mechanism: annealed Soft-Muon NS5 (p_start=0.10 → p_end=0.0 over first half of training)
- Expected smoke + screen within ~3-4h

### THORFINN #178 — cooldown_frac retune sweep
- Just assigned (17:55 UTC). Awaiting smoke + 3-screen comparison.
- Three single-seed screens: cooldown_frac = 0.65, 0.70 (baseline ref), 0.75 @ train_steps=3175
- Target: shift 3.28 crossing from step ~3125 to ~3075 for FFS improvement

### EDWARD #76 — Contra-Muon n=4 (statsig pass, ffs=3175)
- T0=3.2775 ffs=3175, T1=3.2760 ffs=3175, T2=3.2765 ffs=3175
- T3 in progress at step 225/3225 (slow pod ~6 sec/step)
- ETA T3 terminal: ~21:30 UTC. ffs_mean=3175 > baseline 3131 — NOT FFS win
- Mean projection ~3.2767 — extremely low val. Statsig pass certain, no merge.

## Key patterns observed

1. **"Stronger but slower"** — mechanisms that lower terminal val/loss (Newton-Muon, Soft-Muon, Contra-Muon-only, NorMuonH) consistently hit ffs > 3131.25. Only REDUCING effective constraints or adding variance reduction (Aurora leverage equalization, Lookahead, lower CONTRA_MUON) improves FFS.

2. **CONTRA_MUON sensitivity**: coefficient sweep 0.3→0.5 has strong FFS signal. 0.5 screen gave val=3.27629 ffs=3125 (6 steps better than baseline). N=4 currently running (`db1rrfx3`).

3. **Aurora leverage-equalization (record #17)**: First single-seed FFS-winning result via diagonal leverage-score equalization inside NS5. val=3.27706 ffs=3125. N=4 predeclared. This is a fundamentally different mechanism class than CONTRA_MUON tuning — independent path to FFS wins.

4. **SOAP-MLP on Contra+Muon baseline** (PR #78) was the right foundation — all subsequent experiments build from this. Aurora is the FIRST mechanism to stack on this base and improve FFS in screening.

5. **KL-SOAP (record #19)** succeeded without Contra+NS5 stack. Unknown if KL-SOAP + Contra-Muon stacks or if KL-SOAP alone is the right approach.

## Closed this session

- **Thorfinn #103 (Soft-Muon p=0.05 n=4)**: n=4 mean~3.2741 (BEST val!), ffs_mean~3244. Stronger-but-slower — passes statsig but NOT FFS-competitive. Reassigned to cooldown_frac retune.
- **Frieren #109 (MuLoCo+NorMuon n=4 @ 3175)**: n=4 mean=3.28095, only T2 hit target. Clean negative. Reassigned to Soft-Muon annealing.
- **Askeladd #166 (KL-SOAP+H screen)**: val=3.29515, ffs=-1. MISS — pf=1 eigendecomp doesn't recover Contra+NS5 on merged base. Reassigned to SFM.
- **Askeladd #74 (NorMuonH n=4 @ 3300)**: mean=3.27732, ffs_mean=3250. Better val, worse FFS. Reassigned to KL-SOAP+H.
- **Tanjiro #81 (Newton-Muon)**: n=4 mean=3.27643 (lowest!) at 3325 steps. Option B stack failed badly. Closed. Pivoted to Lookahead.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~18:20 | Tanjiro | Lookahead screen REDO terminal | Likely MISS (Lookahead disrupts cooldown) |
| ~18:50 | Askeladd | KL-SOAP screen | First signal on record #19 stack |
| ~21:30 | Edward | n=4 terminal | Statsig PASS, ffs ~3175, no merge |
| ~22:30 | Alphonse | n=4 terminal | Uncertain — T0=3.2783/3150 makes merge tight |
| ~23:20 | Fern | Aurora n=4 terminal (CRITICAL) | Could beat baseline if mean ≤ 3.27760 ffs ≤ 3131 |
| ~24:00 | Nezuko | n=4 terminal (corrected) | Borderline mean ~3.2785 |

## Research programme direction

No human-researcher directives received this session.

Primary goal: beat global best record #20 (3030 steps, Contra+Soft-Muon+power-law LR). Our current best is 3131 steps (Contra+SOAP-MLP). Gap: 101 steps / ~3.2% headroom.

Most promising path to close that gap:
1. **Alphonse CONTRA_MUON=0.5 n=4** (~22:30 UTC) — uncertain after T0 miss
2. **Fern Aurora n=4** (~23:20 UTC) — CRITICAL, first stack mechanism win
3. **Askeladd KL-SOAP+H screen** (~18:50 UTC) — aggressive preconditioning rethink
4. **Frieren Soft-Muon annealing** — direct replication of record #20's key mechanism
5. **Thorfinn cooldown_frac retune** — cheap scalar tune, could shift FFS by 50+ steps

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- All n=4 runs: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800
- Primary metric: `ffs_mean` (lower is better), tie-break: `val/loss mean`
- For merge: BOTH mean ≤ 3.27760 AND ffs_mean ≤ 3131.25 vs current merged baseline
