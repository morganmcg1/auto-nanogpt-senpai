# SENPAI Research State

- 2026-05-16 22:25 UTC — Cycle 31 cont (edward closed+reassigned AdEMAMix; askeladd SFM MISS → c_const=0.01 fallback launched; nezuko T3 started with merge near-certain; fern T3 started but merge nearly dead; alphonse T3 ~45min from terminal)

## Current baseline

**Contra+SOAP-MLP (PR #78)** — n=4 mean=**3.27760**, ffs_mean=**3131.25** @ train_steps=3175
Statsig bar (n=4): mean ≤ 3.27800 AND ffs_mean ≤ 3131.25

## Critical in-flight experiments (priority order)

### ALPHONSE #139 — CONTRA_MUON=0.5 n=4 (`db1rrfx3`) 🔥 MERGE NEAR-CERTAIN
- T0=3.27830/3150, T1=3.27634/3125, T2=**3.27551/3100** (best n=4 trial of session)
- n=3 mean=**3.27672**, ffs=**3125** — both bars BEATEN by margin
- T3 in progress at step ~2603/3175. ETA terminal **~45 min**.
- For n=4 merge: T3 ≤ 3.27884 on val (very loose), ffs ≤ 3175 keeps mean ≤ 3131.25
- **Highest-confidence merge path. Watching closely.**

### NEZUKO #124 — Attn-SOAP + trust gate n=4 (`790h1llo`) 🔥 MERGE NEAR-CERTAIN
- T0=3.27743/3125, T1=3.27750/3125, T2=**3.27758/3125** — remarkable 0.00015 range across 3 trials
- n=3 mean=**3.27750**, ffs=**3125** — well clear of both bars
- T3 at step ~553/3175. ETA terminal **~3h**.
- For n=4 merge: T3 ≤ 3.27852 on val (generous). Trust-gate mechanism absorbs seed noise.

### FERN #125 — Aurora n=4 (`5kr7d0i5`) ⚠️ MERGE PATH NEARLY CLOSED
- T0=3.27592/3100, T1=3.28172/-1 (MISS), T2=3.27768/3125
- n=3 mean=**3.27844** — exceeds 3.27800 statsig bar
- For n=4 merge: T3 needs val ≤ 3.27668 AND ffs ≤ 3125. T1's -1 ffs also makes ffs_mean borderline even with perfect T3.
- T3 at step ~878/3175. ETA terminal ~3h. Run to completion — record the data.

### EDWARD #199 — AdEMAMix dual-EMA on AdamW aux groups (NEW)
- Just assigned. Awaiting smoke + screen.
- Mechanism: replace AdamW on embeddings+lm_head with dual-EMA (fast β1=0.9, slow β3=0.999, α=5.0 mixing)
- Orthogonal to Muon stack — first time aux groups have been targeted
- Paper (NeurIPS 2024): 1.5-2× faster LM convergence vs AdamW

### ASKELADD #181 — Schedule-Free Muon fallback: c_const=0.01
- Fallback screen `k3wkjy84` running at step 100 val=10.83 (warmup)
- Original uniform c_t screen MISSED badly (val=4.605, ||y−z||=2.2e9 divergence)
- Root cause confirmed: 1/(t+1) weighting assigns near-equal weight to random-init iterates
- c_const=0.01 = EMA with ~100-step window; tracks recent trajectory properly
- Pre-approved — no additional action needed. ETA screen terminal ~4-5h.

### FRIEREN #177 — Soft-Muon annealing screen (`dhqwygng`)
- Step 2475/3175 val=3.387 — in cooldown, healthy descent
- ETA terminal **~1.5h**

### THORFINN #178 — cooldown_frac retune sweep
- Screen `5z6cau3h` (frac=0.70 ref arm) at step 1275 val=3.607 — early training
- Other arms (0.65, 0.75) expected to follow. ETA screens ~3-4h.

### TANJIRO #187 — PMuon bilateral streaming covariance screen (`eafhrglu`)
- Step 900/3175 val=3.687 — early training, healthy descent
- ETA terminal ~3h

## Key patterns observed

1. **"Stronger but slower"** — Confirmed 3× this session (Soft-Muon p=0.05 n=4, Newton-Muon n=4, Contra-Muon-only n=4). Mechanisms that lower terminal val consistently hit ffs > 3131.25. Only mechanisms reducing effective update constraints or adding variance reduction improve FFS.

2. **CONTRA_MUON=0.5 sweep** (alphonse #139): n=3 mean=3.27672/3125. Best per-trial val of session (3.27551). MERGE NEAR-CERTAIN.

3. **Trust-gate variance suppression** (nezuko #124): T0/T1/T2 range = 0.00015. Unprecedented consistency across seeds. Mechanism absorbs init noise via gating.

4. **Aurora seed-sensitivity**: T0=3.27592/3100 (stunning), T1 MISSED, T2=3.27768/3125. Diagonal leverage-score equalization is sensitive to random initialization direction.

5. **Uniform Polyak averaging failure**: SFM with c_t=1/(t+1) assigns ~50% weight to the first t/2 iterates. At t=3175, those early iterates dominated the eval point y, giving val=4.6 (near-random). EMA-style c_const=0.01 should fix this by exponentially downweighting old iterates.

## Closed this session

- **Edward #76 (Contra-Muon n=4)**: mean=3.27652/ffs=3175. Statsig PASS, FFS MISS. Superseded by merged baseline #78. Reassigned to AdEMAMix-aux (#199).
- **Thorfinn #103 (Soft-Muon p=0.05)**: stronger-but-slower. Reassigned to cooldown_frac (#178).
- **Frieren #109 (MuLoCo+NorMuon)**: mean=3.28095. Reassigned to Soft-Muon annealing (#177).
- **Askeladd #166 (KL-SOAP+H)**: val=3.295 MISS. Reassigned to SFM (#181).
- **Tanjiro #161 (Lookahead α=0.5 and 0.7)**: both MISSED. Reassigned to PMuon (#187).
- **Tanjiro #81 (Newton-Muon)**: stronger-but-slower. Closed earlier.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~23:10 | Alphonse | T3 terminal | **MERGE EXPECTED** — n=3 mean already 3.27672/3125 |
| ~01:30 | Frieren | Screen terminal | Aggressive mechanism — could be FFS-winning |
| ~01:30 | Nezuko | T3 terminal | **MERGE EXPECTED** — n=3 mean 3.27750/3125, consistent seeds |
| ~01:30 | Fern | T3 terminal | Merge path nearly closed (need val ≤ 3.27668) |
| ~02:00 | Tanjiro | PMuon screen | Open — bilateral power preconditioning |
| ~02:00 | Thorfinn | cooldown-frac screens | 3 comparison arms (0.65/0.70/0.75) |
| ~03:00 | Askeladd | SFM c_const=0.01 | Should recover vs uniform; borderline FFS uncertain |

## Research programme direction

No human-researcher directives received this session.

Primary goal: beat record #20 (3030 steps). Current best is 3131 steps. Gap = 101 steps / ~3.2%.

Most promising path:
1. **Alphonse T3 terminal** (~45min) — merge imminent → new baseline ffs ~3125
2. **Nezuko T3** (~3h) — second independent merge candidate
3. **Frieren Soft-Muon-anneal screen** — mechanism directly matching record #20's design philosophy
4. **Thorfinn cooldown_frac** — if shifting ffs 50+ steps, cheap and fast signal
5. **Tanjiro PMuon** — bilateral power preconditioning, novel mechanism class
6. **Edward AdEMAMix-aux** — aux-group momentum upgrade, orthogonal direction

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Group naming: `g1r2-nezuko/attn-soap-gate`; `g1r2-fern/aurora-r17`; `g1r2-askeladd/sfm`
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800; ffs_mean ≤ 3131.25
- For ffs_mean when a trial missed: count -1 trials as train_steps for mean calc (conservative)
