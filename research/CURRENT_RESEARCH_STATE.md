# SENPAI Research State

- 2026-05-16 15:35 UTC — Cycle 23 (askeladd closed + reassigned, alphonse n=4 predeclared)

## Current baseline

**Contra+SOAP-MLP (PR #78)** — n=4 mean=**3.27760**, ffs_mean=**3131.25** @ train_steps=3175  
Statsig bar (n=4): mean ≤ 3.27800 AND ffs_mean ≤ 3131.25

## Critical in-flight experiments (priority order)

### ALPHONSE #139 — CONTRA_MUON=0.5 n=4 PREDECLARED 🔥
- Screen `yctj2ozd`: val=**3.2763**, ffs=**3125** — BEATS merged baseline on BOTH metrics!
- n=4 PREDECLARED at train_steps=3175, CONTRA_MUON=0.5, same HPs as merged baseline otherwise
- Predeclare comment posted at ~15:15 UTC; n=4 expected to launch immediately
- ETA n=4 terminal: ~22:30-23:00 UTC if launched at 15:15 UTC
- THIS IS THE HIGHEST-PRIORITY RESULT. If n=4 mean ≤ 3.27760 and ffs_mean ≤ 3125, we have a new baseline.

### NEZUKO #124 — Attn-SOAP + trust gate n=4
- Screen `c5d01ezw`: val=3.2797, ffs=3150 @ train_steps=3150 (borderline)
- Directed n=4 at train_steps=3175 at 14:25 UTC (~66 min ago); likely running now
- ETA n=4 terminal: ~16:00-16:30 UTC (if launched ~14:25 UTC)
- Prediction: mean ~3.2785, margin ~0.003 — likely FAILS statsig by ~0.001
- ffs_mean ~3120-3150 possible — IF both criteria pass, would be a MERGE candidate

### TANJIRO #161 — Lookahead wrapper on Contra+SOAP-MLP
- Screen `tbesgctw` running (was step 280/3175 at ~13:50 UTC)
- ETA screen terminal: ~17:50 UTC
- Hypothesis: k=5, α=0.5 Lookahead averaging reduces FFS by 30-80 steps via trajectory variance smoothing
- If screen val ≤ 3.279 and ffs ≤ 3175 → predeclare n=4 at 3175

### FERN #125 — Real Aurora (diagonal leverage-score equalization)
- Screen `lqwaozx7` running with D.clamp_(1e-6, 1e6) fix — past prior crash points
- ETA terminal: ~17:00 UTC
- Note: Two prior screens crashed at steps 1475 and 575; clamp fix appears to have resolved instability
- If competitive: predeclare n=4

### FRIEREN #109 — MuLoCo+NorMuon n=4 (expected CLEAN NEGATIVE)
- T0=3.28240, T1=3.28196 BOTH MISSED at 3175 steps
- All 4 trials continuing to terminal per statsig protocol (no val-peeking early-kill)
- ETA terminal: ~17:30 UTC. Will post clean SENPAI-RESULT negative and close PR.
- Implication: MuLoCo outer-Nesterov wrapping doesn't add to Contra+SOAP-MLP at 3175 steps

### THORFINN #103 — Soft-Muon p=0.05 n=4 (strong but "stronger but slower")
- n=4 `6kjpjnvd`: T0=3.27400 ffs=3250, T1=3.27400 ffs=3250 — remarkable dual-trial agreement
- T2 at step 874/3325 (~26%) at last check. ETA full n=4 terminal ~17:45-18:00 UTC
- Val/loss excellent but ffs=3250 > baseline 3131 — STATSIG PASS likely, NOT FFS win
- Will close after terminal: clean "stronger but slower" result, no new baseline

### EDWARD #76 — Contra-Muon n=4 (stronger but slower, expected)
- n=4 `zsqazpmr` @ 3225: T0=3.27750 ffs=3175, T1=3.27599 ffs=3175 (excellent!)
- T2-T3 at ~step 2477/3225 at last check. ETA full terminal ~17:00-18:00 UTC
- ffs_mean ~3175 — beats NorMuon-clean but not merged baseline ffs=3131
- Mean projection ~3.276 — very low val! But FFS not competitive. Statsig pass likely.

### ASKELADD #166 — KL-SOAP + hyperball (JUST ASSIGNED)
- Fresh assignment: KL-SOAP applied to ALL 2D block params (not just MLP), pf=1, β1=0.95, β2=0.90
- Record #19 reference: n=6 mean=3.27800 @ 3125 steps (statsig pass). Target: replicate + beat ffs_mean ≤ 3125
- Student hasn't picked up yet (assigned at 15:33 UTC). Expect smoke + screen within 3-4h.
- ETA screen terminal: ~20:00 UTC

## Key patterns observed

1. **"Stronger but slower"** — mechanisms that lower terminal val/loss (Newton-Muon, Soft-Muon, Contra-Muon, NorMuonH) consistently hit ffs > 3131.25. Only REDUCING effective constraints or adding variance reduction (Lookahead, lower CONTRA_MUON) improves FFS.

2. **CONTRA_MUON sensitivity**: coefficient sweep 0.3→0.5 has strong FFS signal. 0.5 screen gave ffs=3125 (6 steps better than baseline). Predeclared n=4 is the highest-priority current bet.

3. **SOAP-MLP on Contra+Muon baseline** (PR #78) was the right foundation — all subsequent experiments build from this. The key question is what adds to it vs. what trades val for FFS.

4. **KL-SOAP (record #19)** succeeded without Contra+NS5 stack. Unknown if KL-SOAP + Contra-Muon stacks or if KL-SOAP alone is the right approach.

## Closed this session

- **Askeladd #74 (NorMuonH n=4 @ 3300)**: n=4 mean=3.27732, ffs_mean=3250. Strictly BETTER val than baseline (3.27760 → 3.27732) but strictly WORSE FFS (3131.25 → 3250). Closed as "statsig pass but not FFS-competitive." Reassigned to KL-SOAP+H.
- **Tanjiro #81 (Newton-Muon)**: Newton-Muon-only n=4 mean=3.27643 (LOWEST achieved!) at 3325 steps. Option B stack at 3175 failed badly (3.28893). Closed. Pivoted to Lookahead.

## Upcoming decisions / expected results (next 6 hours)

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~16:00-16:30 | Nezuko | n=4 terminal | Likely FAILS statsig by ~0.001; ffs borderline |
| ~17:00 | Fern | Aurora screen terminal | Unknown; will decide predeclare or abandon |
| ~17:00-18:00 | Edward | n=4 terminal | Statsig PASS, ffs ~3175, no new baseline |
| ~17:30 | Frieren | n=4 terminal | Clean negative, close PR |
| ~17:45-18:00 | Thorfinn | n=4 terminal | Statsig PASS, ffs ~3250, no new baseline |
| ~17:50 | Tanjiro | Lookahead screen terminal | Unknown; key FFS test |
| ~20:00 | Askeladd | KL-SOAP screen | First signal on record #19 stack |
| ~22:30-23:00 | Alphonse | n=4 terminal (CRITICAL) | Could be new baseline if ffs_mean ≤ 3125 |

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
