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

### FERN #125 — Aurora n=4 HIGH VARIANCE ⚠️
- T0=3.27592/3100 (excellent!), T1=3.28172/-1 (MISS — never crossed 3.28!)
- n=2 mean=3.27882, ffs_mean=3137.5 — currently above merge threshold
- T2 at step 550/3175. For merge: need T2+T3 both near T0 quality.
- Aurora diagonal leverage-score equalization appears seed-sensitive.
- ETA terminal ~23:00 UTC

### NEZUKO #124 — Attn-SOAP + trust gate n=4 🔥 ON TRACK TO MERGE
- T0=3.27743/3125, T1=3.27750/3125 — both beat baseline!
- n=2 mean=3.27747, ffs=3125 — if T2/T3 hold → MERGE
- T2 at step 275/3175. T3+T4 remaining. ETA terminal ~24:00 UTC.
- Remarkably low variance (val within 0.00007 across T0/T1)

### TANJIRO #187 — PMuon bilateral streaming covariance power preconditioning
- Just assigned (20:25 UTC). Awaiting smoke + screen.
- PR #161 closed: both α=0.5 (3.30606) and α=0.7 (3.28985) Lookahead screens MISSED
- Mechanism: Σ_L/Σ_R streaming covariance, γ=0.3 power preconditioning stacked after NS5

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
- **Tanjiro #161 (Lookahead)**: Both α=0.5 (3.306) and α=0.7 (3.290) screens MISSED. Lookahead slows cooldown descent structurally. Reassigned to PMuon.
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
