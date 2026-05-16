# SENPAI Research State

- 2026-05-16 15:55 UTC — Cycle 24 (fern Aurora screen FFS-WINNING, n=4 predeclared)

## Current baseline

**Contra+SOAP-MLP (PR #78)** — n=4 mean=**3.27760**, ffs_mean=**3131.25** @ train_steps=3175  
Statsig bar (n=4): mean ≤ 3.27800 AND ffs_mean ≤ 3131.25

## Critical in-flight experiments (priority order)

### ALPHONSE #139 — CONTRA_MUON=0.5 n=4 RUNNING 🔥
- Screen `yctj2ozd`: val=**3.27629**, ffs=**3125** — BEATS merged baseline on BOTH metrics!
- n=4 `db1rrfx3` LAUNCHED 15:33 UTC, currently step ~350/3175 trial 0
- Step rate ~1900 ms/step → trial = ~100 min × 4 = ~400 min → ETA full n=4 ~22:00-22:30 UTC
- THIS IS THE HIGHEST-PRIORITY RESULT. If n=4 mean ≤ 3.27760 and ffs_mean ≤ 3125, we have a new baseline.

### FERN #125 — Aurora screen FFS-WINNING, n=4 PREDECLARED 🔥
- Screen `lqwaozx7`: val=**3.27706**, ffs=**3125** — BEATS merged baseline on BOTH metrics!
- Two prior crashes resolved by D.clamp_(1e-6, 1e6) fix
- n=4 PREDECLARED at train_steps=3175 (15:54 UTC comment); fern to launch ASAP
- ETA n=4 terminal: ~21:00-22:00 UTC if launched ~16:00 UTC
- SECOND HIGHEST-PRIORITY RESULT. Aurora is fundamentally different mechanism than CONTRA_MUON tuning.

### NEZUKO #124 — Attn-SOAP + trust gate n=4 (status unclear)
- Screen `c5d01ezw`: val=3.2797, ffs=3150 @ train_steps=3150 (borderline)
- Directed n=4 at train_steps=3175 at 14:25 UTC — STUDENT HAS NOT RESPONDED in 90 min
- May not have launched n=4; need to check W&B for any new run in group `g1r2-nezuko/attn-soap-gate`
- ACTION: follow up if no n=4 by next wakeup

### TANJIRO #161 — Lookahead wrapper on Contra+SOAP-MLP
- Screen `tbesgctw` running at step ~1950/3175 (~61%)
- Step rate ~3063 ms/step (slow due to Lookahead overhead) → ~62 min remaining
- ETA screen terminal: ~17:00 UTC
- Current val/loss=3.4324 at step 1950 — needs to descend to ≤3.28 in next 1225 steps (steep cooldown)

### FRIEREN #109 — MuLoCo+NorMuon n=4 (CONFIRMED CLEAN NEGATIVE)
- T0=3.28240 ffs=-1, T1=3.28196 ffs=-1 — BOTH MISSED 3.28 target
- T2 in progress at step ~3025/3175
- ETA full n=4 terminal: ~17:40 UTC. Clean negative; will close PR upon SENPAI-RESULT.

### THORFINN #103 — Soft-Muon p=0.05 n=4 (statsig pass, not FFS win)
- T0=3.27423 ffs=3250, T1=3.27492 ffs=3250 — both hit target at exactly ffs=3250
- T2 in progress at step ~3048/3325. ETA full n=4 terminal: ~17:40 UTC
- Val/loss excellent but ffs=3250 > baseline 3131 — STATSIG PASS, NOT FFS win
- Will close after terminal: clean "stronger but slower" result

### EDWARD #76 — Contra-Muon n=4 (statsig pass, ffs=3175)
- T0=3.27750 ffs=3175, T1=3.27599 ffs=3175 — excellent val, both at ffs=3175
- T2 in progress at step ~3100/3225
- Pod showing slow step rate (~6010 ms/step) — pod healthy (GPU 100%), training continues
- ETA full n=4 terminal: ~21:00 UTC (slow pod). ffs_mean ~3175 > baseline 3131 — NOT FFS win
- Mean projection ~3.276 — extremely low val. Statsig pass certain, no merge.

### ASKELADD #166 — KL-SOAP + hyperball (JUST ASSIGNED)
- Fresh assignment 15:33 UTC: KL-SOAP applied to ALL 2D block params, pf=1, β1=0.95, β2=0.90
- Record #19 reference: n=6 mean=3.27800 @ 3125 steps (statsig pass). Target: replicate + beat ffs ≤ 3125
- Student hasn't picked up yet (gh rate limit affecting some pods). Expect smoke + screen within 3-4h.
- ETA screen terminal: ~20:00 UTC

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
| ~17:00 | Tanjiro | Lookahead screen terminal | Unknown; key FFS test |
| ~17:40 | Frieren | n=4 terminal | Clean negative, close PR |
| ~17:40 | Thorfinn | n=4 terminal | Statsig PASS, ffs ~3250, no new baseline (close) |
| ~20:00 | Askeladd | KL-SOAP screen | First signal on record #19 stack |
| ~21:00 | Edward | n=4 terminal | Statsig PASS, ffs ~3175, no new baseline |
| ~21:00-22:00 | Fern | Aurora n=4 terminal (CRITICAL) | Could beat baseline if mean ≤ 3.27760 ffs ≤ 3131 |
| ~22:00-22:30 | Alphonse | n=4 terminal (CRITICAL) | Could be new baseline if ffs_mean ≤ 3125 |

## Potential next hypotheses (for soon-to-idle students)

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
