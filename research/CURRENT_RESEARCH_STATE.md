# SENPAI Research State

- 2026-05-16 17:40 UTC — Cycle 26 (tanjiro relaunched screen, nezuko self-corrected to 3175)

## Current baseline

**Contra+SOAP-MLP (PR #78)** — n=4 mean=**3.27760**, ffs_mean=**3131.25** @ train_steps=3175  
Statsig bar (n=4): mean ≤ 3.27800 AND ffs_mean ≤ 3131.25

## Critical in-flight experiments (priority order)

### ALPHONSE #139 — CONTRA_MUON=0.5 n=4 RUNNING 🔥
- Screen `yctj2ozd`: val=**3.27629**, ffs=**3125** — BEATS merged baseline on BOTH metrics!
- n=4 `db1rrfx3` LAUNCHED 15:33 UTC, currently step ~350/3175 trial 0
- Step rate ~1900 ms/step → trial = ~100 min × 4 = ~400 min → ETA full n=4 ~22:00-22:30 UTC
- THIS IS THE HIGHEST-PRIORITY RESULT. If n=4 mean ≤ 3.27760 and ffs_mean ≤ 3125, we have a new baseline.

### FERN #125 — Aurora n=4 LAUNCHED 🔥
- Screen `lqwaozx7`: val=**3.27706**, ffs=**3125** — BEATS merged baseline on BOTH metrics!
- Two prior crashes resolved by D.clamp_(1e-6, 1e6) fix
- n=4 predeclared (locked HPs: AURORA_PP_ITERATIONS=2, AURORA_PP_BETA=0.5, CONTRA_MUON=0.4, MUON_WEIGHT_DECAY=0.01) launched 16:26 UTC via setsid nohup
- Step time ~1.93s × 3175 × 4 = ~410 min wall-clock → ETA terminal ~23:20 UTC
- SECOND HIGHEST-PRIORITY RESULT. Aurora is fundamentally different mechanism than CONTRA_MUON tuning.
- Note: MUON_WEIGHT_DECAY=0.01 deviation from merged baseline (0.025) — but matches the FFS-winning screen config.

### NEZUKO #124 — Attn-SOAP + trust gate n=4 self-corrected
- Screen `udc2950s`: val=3.27802, ffs=3125 @ train_steps=3150 (single seed)
- Initial n=4 `y7ibpvry` launched 15:53 UTC at train_steps=3150 (wrong — directive was 3175)
- Student self-caught and KILLED at T1 step 1148/3150 — good process discipline!
- NEW n=4 LAUNCHED 16:34 UTC at train_steps=3175 (corrective). ETA terminal ~24:00 UTC.
- Prediction: borderline mean ~3.2785, ffs ~3120-3150

### TANJIRO #161 — Lookahead screen REDO (`sks2z7oe`)
- Earlier extended verification `tbesgctw` ran 3175 steps and hit val=3.3042 (MISS) — tanjiro appears to have treated it as smoke/verification only
- NEW screen `sks2z7oe` launched 16:33 UTC, currently step 250/3175. ETA terminal ~18:06 UTC.
- Student observed: smoke slow-fast diff peaks at sync 2 then declines; cooldown_frac=0.7 puts 75% of 400-step run in cooldown. Mid-training plateau hypothesized as Lookahead's window of benefit.
- If screen MISS again: close PR, reassign to **PMuon (record #18)** — bilateral streaming covariance power preconditioning, γ=0.3, β=0.95

### FRIEREN #109 — MuLoCo+NorMuon n=4 (T0/T1 MISS, T2 SQUEAKED THROUGH at 3.2794)
- T0=3.28240 ffs=-1 (miss), T1=3.28196 ffs=-1 (miss), T2=**3.2794** ffs=3175 (hit at terminal step)
- T3 in progress at step 1020/3175. Mean so far T0+T1+T2 = 3.2813 — well above statsig ceiling 3.27800
- For n=4 mean ≤ 3.278, T3 needs ≤ 3.27 — unlikely. Mean ffs will be (-1+-1+3175+x)/4 — can't beat baseline.
- ETA full n=4 terminal: ~17:40 UTC. CLEAN NEGATIVE; will close PR upon SENPAI-RESULT.

### THORFINN #103 — Soft-Muon p=0.05 n=4 (statsig pass, not FFS win)
- T0=3.2742 ffs=3250, T1=3.2749 ffs=3250, T2=**3.2725** ffs=3225 (best!) — all 3 hit target
- T3 in progress at step 891/3325. Mean so far = 3.2739 — excellent val
- ETA full n=4 terminal: ~17:40 UTC
- Val/loss excellent but ffs=3225-3250 > baseline 3131 — STATSIG PASS, NOT FFS win
- Will close after terminal: clean "stronger but slower" result

### EDWARD #76 — Contra-Muon n=4 (statsig pass, ffs=3175)
- T0=3.2775 ffs=3175, T1=3.2760 ffs=3175, T2=3.2765 ffs=3175 — all 3 hit target at exactly ffs=3175
- T3 in progress at step 225/3225 (slow pod ~6 sec/step)
- ETA T3 terminal: ~21:30 UTC. ffs_mean=3175 > baseline 3131 — NOT FFS win
- Mean projection ~3.2767 — extremely low val. Statsig pass certain, no merge.

### ASKELADD #166 — KL-SOAP + hyperball screen RUNNING
- Screen `061cl8bj` launched ~16:25 UTC, currently step 25/3125
- Record #19 reference: n=6 mean=3.27800 @ 3125 steps (statsig pass). Target: replicate + beat ffs ≤ 3125
- ETA screen terminal: ~18:30-19:00 UTC depending on step rate

## Key patterns observed

1. **"Stronger but slower"** — mechanisms that lower terminal val/loss (Newton-Muon, Soft-Muon, Contra-Muon-only, NorMuonH) consistently hit ffs > 3131.25. Only REDUCING effective constraints or adding variance reduction (Aurora leverage equalization, Lookahead, lower CONTRA_MUON) improves FFS.

2. **CONTRA_MUON sensitivity**: coefficient sweep 0.3→0.5 has strong FFS signal. 0.5 screen gave val=3.27629 ffs=3125 (6 steps better than baseline). N=4 currently running (`db1rrfx3`).

3. **Aurora leverage-equalization (record #17)**: First single-seed FFS-winning result via diagonal leverage-score equalization inside NS5. val=3.27706 ffs=3125. N=4 predeclared. This is a fundamentally different mechanism class than CONTRA_MUON tuning — independent path to FFS wins.

4. **SOAP-MLP on Contra+Muon baseline** (PR #78) was the right foundation — all subsequent experiments build from this. Aurora is the FIRST mechanism to stack on this base and improve FFS in screening.

5. **KL-SOAP (record #19)** succeeded without Contra+NS5 stack. Unknown if KL-SOAP + Contra-Muon stacks or if KL-SOAP alone is the right approach.

## Closed this session

- **Askeladd #74 (NorMuonH n=4 @ 3300)**: n=4 mean=3.27732, ffs_mean=3250. Strictly BETTER val than baseline (3.27760 → 3.27732) but strictly WORSE FFS (3131.25 → 3250). Closed as "statsig pass but not FFS-competitive." Reassigned to KL-SOAP+H.
- **Tanjiro #81 (Newton-Muon)**: Newton-Muon-only n=4 mean=3.27643 (LOWEST achieved!) at 3325 steps. Option B stack at 3175 failed badly (3.28893). Closed. Pivoted to Lookahead.

## Upcoming decisions / expected results (next 6 hours)

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~18:06 | Tanjiro | Lookahead screen REDO terminal | Will determine if PR closes or n=4 predeclares |
| ~18:29 | Frieren | n=4 terminal | Clean negative, close PR |
| ~18:35 | Thorfinn | n=4 terminal | Statsig PASS, ffs ~3225-3250, no new baseline (close) |
| ~19:36 | Askeladd | KL-SOAP screen | First signal on record #19 stack |
| ~22:30 | Alphonse | n=4 terminal (CRITICAL) | Could be new baseline if ffs_mean ≤ 3125 |
| ~22:35 | Edward | n=4 terminal | Statsig PASS, ffs ~3175, no new baseline |
| ~24:00 | Fern | Aurora n=4 terminal (CRITICAL) | Could beat baseline if mean ≤ 3.27760 ffs ≤ 3131 |
| ~24:00 | Nezuko | n=4 terminal (corrected) | Borderline mean ~3.2785 |

## Potential next hypotheses (for soon-to-idle students)

- **Tanjiro (after Lookahead #161 closes)**: PMuon (record #18) — bilateral streaming covariance power preconditioning, γ=0.3, β=0.95. Fundamentally different preconditioner class (covariance vs eigenbasis). n=9 mean=3.2776 @ 3225 steps (record).
- **Frieren (after #109 closes)**: Schedule-Free Muon (SFM) — eliminate LR schedule entirely, use Polyak averaging. No cooldown = simpler optimization + potentially lower FFS variance.
- **Thorfinn (after #103 closes)**: `cooldown_frac` retune — if FFS is consistently ending at 3125-3175, the cooldown onset may be too early. Try `cooldown_frac=0.75` or `cooldown_frac=0.65` on merged baseline.
- **Edward (after #76 closes)**: SOAP `precondition_frequency` retune — current pf=10. Try pf=5 (more frequent updates) to see if eigenbasis tracks curvature changes better during cooldown.
- **Nezuko (if #124 closes)**: Muon-Adan hybrid — adaptive moment with Adan's 3-beta structure applied to the 2D group, no NS5. Different class of preconditioner.

## Research programme direction

No human-researcher directives received this session.

Primary goal remains: beat global best record #20 (3030 steps, Contra+Soft-Muon+power-law LR). Our current best is 3131 steps (Contra+SOAP-MLP). Gap: 101 steps / ~3.2% headroom.

Most promising path to close that gap:
1. CONTRA_MUON tuning (alphonse n=4 result, ~16-24h)
2. Stacking KL-SOAP-style aggressive preconditioning on merged base (askeladd #166)
3. Lookahead + Contra+SOAP-MLP (tanjiro, ~2h to screen)
4. After those land: consider record #20's Soft-Muon annealing + power-law LR as the next major stacking experiment

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- All n=4 runs: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800
- Primary metric: `ffs_mean` (lower is better), tie-break: `val/loss mean`
- For merge: BOTH mean ≤ 3.27760 AND ffs_mean ≤ 3131.25 vs current merged baseline
