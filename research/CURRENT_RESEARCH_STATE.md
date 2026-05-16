# SENPAI Research State

- 2026-05-16 21:50 UTC — Cycle 31 (edward T3 ~97 steps from terminal; askeladd SFM diverging val=5.03; alphonse/nezuko/fern all mid-T2/T3 of n=4 confirms)

## Current baseline

**Contra+SOAP-MLP (PR #78)** — n=4 mean=**3.27760**, ffs_mean=**3131.25** @ train_steps=3175
Statsig bar (n=4): mean ≤ 3.27800 AND ffs_mean ≤ 3131.25

## Critical in-flight experiments (priority order)

### ALPHONSE #139 — CONTRA_MUON=0.5 n=4 (`db1rrfx3`) 🔥 MERGE NEAR-CERTAIN
- T0=3.27830/3150, T1=3.27634/3125, T2=**3.27551/3100** (best n=4 trial of session)
- n=3 mean=**3.27672**, ffs=**3125** — both bars BEATEN by margin
- T3 in progress at step ~1128/3175. ETA terminal ~3-4h.
- For mean to still pass at n=4: T3 ≤ 3.27884 (loose). For ffs_mean: any T3 ≤ ~3175 keeps mean ≤ 3131.25.
- **Highest-confidence merge path of the session.**

### FERN #125 — Aurora n=4 (`5kr7d0i5`) ⚠️ HIGH VARIANCE
- T0=3.27592/3100 (excellent!), T1=3.28172/-1 (MISS — never crossed 3.28!)
- T2 at step ~2727/3175 mid-cooldown val=3.346. T3 not yet started.
- n=2 mean=3.27882, ffs_mean=3137.5 — currently above merge bar.
- For merge: T2+T3 mean ≤ 3.27728 AND combined ffs_mean ≤ 3131.25 (T1's -1 means combined ffs ≥ 3225/4 if convention is to fall back to train_steps — tight).
- Aurora seed-sensitivity is the key risk. ETA terminal ~3-4h.
- Side-screen `lqwaozx7` (screen3) hit val=3.27706 ffs=3125 — independent confirmation single-seed FFS works, doesn't change n=4 verdict.

### NEZUKO #124 — Attn-SOAP + trust gate n=4 (`790h1llo`) 🔥 ON TRACK TO MERGE
- T0=3.27743/3125, T1=3.27750/3125 — both beat baseline, variance ≤ 0.00007.
- T2 at step ~2402/3175 mid-cooldown val=3.386.
- n=2 mean=3.27747, ffs=3125 — if T2/T3 hold → MERGE.
- ETA terminal ~4h.

### EDWARD #76 — Contra-Muon n=4 @ train_steps=3225 (`zsqazpmr`)
- T0=3.2775/3175, T1=3.2760/3175, T2=3.2765/3175
- T3 at step ~3128/3225, val=3.283 — 97 steps from terminal. Will ffs hit?
- Mean projection ~3.2766 (statsig PASS). ffs_mean=3175 >> 3131.25 → NO MERGE (stronger but slower).
- Closes this cycle as confirmed CLOSED.

### TANJIRO #187 — PMuon bilateral streaming covariance power preconditioning
- Smoke `971z1am3` FINISHED clean (val=3.811 @ 400 steps).
- Screen `eafhrglu` running at step 150 val=4.526. ETA terminal ~4-5h.
- Mechanism: Σ_L/Σ_R streaming covariance, γ=0.3 power preconditioning stacked after NS5.

### ASKELADD #181 — Schedule-Free Muon (SFM) — DIVERGING
- Screen `groom2ym` at step 1950/3175 val=**5.029** (rising, far above baseline 3.39 at same step).
- MISS already certain; predeclared path: complete screen to terminal, then trigger pre-approved fallback `SFM_C_SCHEDULE=const`, `SFM_C_CONST=0.01` (EMA-style ~100-step window).
- Underlying issue: uniform c_t=1/(t+1) gives Polyak average dominated by random init in early iterations.

### FRIEREN #177 — Soft-Muon annealing on merged base
- Smoke clean (val=3.81 @ 400). Screen `dhqwygng` at step 1125/3175 val=3.642 — healthy descent.
- Mechanism: annealed Soft-Muon NS5 (p_start=0.10 → p_end=0.0 over first half of training).
- ETA terminal ~3-4h.

### THORFINN #178 — cooldown_frac retune sweep
- Smoke `bpzwtah0` FINISHED clean (val=3.812 @ 400).
- Screen `5z6cau3h` (cooldown_frac=0.70) running. Other arms (0.65, 0.75) launching.
- ETA terminals ~4h.

## Key patterns observed

1. **"Stronger but slower"** — Edward Contra-Muon n=4 will close as another instance (3.2766/3175). Pattern: mechanisms that lower terminal val/loss consistently hit ffs > 3131.25. Only mechanisms that ADD variance reduction OR REDUCE constraints (CONTRA_MUON tuning, Aurora leverage equalization) improve FFS.

2. **CONTRA_MUON=0.5 sweep** (alphonse #139): T0/T1/T2 all beat baseline on both bars. n=3 mean=3.27672/3125. This is the strongest merge candidate in months.

3. **Aurora leverage-equalization** (fern #125): T0 stunning (3.27592/3100) but T1 missed entirely (3.28172/-1). High seed-variance suggests the mechanism is unstable across initializations.

4. **Attn-SOAP + trust gate** (nezuko #124): T0/T1 remarkably consistent (variance 0.00007). Trust gate mechanism appears to absorb seed noise. On track to merge.

5. **Schedule-Free Muon failure mode**: Polyak averaging with c_t=1/(t+1) is dominated by random init bias for first ~100 steps. Even with warmup=100, the early bias never washes out enough by step ~2000 to recover. Need const c_t (~0.01 EMA) to match Muon's noise scale.

## Closed this session

- **Thorfinn #103 (Soft-Muon p=0.05 n=4)**: stronger-but-slower. Reassigned to cooldown_frac retune (#178).
- **Frieren #109 (MuLoCo+NorMuon n=4)**: mean=3.28095, only T2 hit target. Reassigned to Soft-Muon annealing (#177).
- **Askeladd #166 (KL-SOAP+H screen)**: val=3.295, ffs=-1 MISS. Reassigned to SFM (#181).
- **Askeladd #74 (NorMuonH n=4)**: better val, worse FFS. Reassigned earlier.
- **Tanjiro #161 (Lookahead)**: both α=0.5 and α=0.7 screens MISSED. Reassigned to PMuon (#187).
- **Tanjiro #81 (Newton-Muon)**: stronger-but-slower. Closed earlier.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~22:00 | Edward | T3 terminal | Stronger-but-slower confirmed CLOSE (ffs=3175 > 3131.25) |
| ~22:30 | Askeladd | SFM screen terminal | MISS confirmed → trigger c_const=0.01 fallback screen |
| ~01:00 | Alphonse | T3 terminal | **MERGE EXPECTED** — n=3 mean already 3.27672/3125 |
| ~02:00 | Fern | T2 terminal | Variance-driven — if T2 ≥ 3.279, merge dead |
| ~02:00 | Nezuko | T2 terminal | On track if val ≤ 3.278 |
| ~03:00 | Frieren | Screen terminal | Aggressive descent — could be FFS-winning |
| ~03:00 | Tanjiro | PMuon screen terminal | Open — record #18 single-seed strength uncertain on stack |

## Research programme direction

No human-researcher directives received this session.

Primary goal: beat global best record #20 (3030 steps, Contra+Soft-Muon+power-law LR). Our current best is 3131 steps (Contra+SOAP-MLP). Gap: 101 steps / ~3.2% headroom.

Most promising path to close that gap:
1. **Alphonse CONTRA_MUON=0.5 n=4** (~01:00 UTC) — MERGE NEAR-CERTAIN (n=3 mean 3.27672/3125)
2. **Nezuko Attn-SOAP+trust n=4** (~02:00 UTC) — high consistency, MERGE LIKELY
3. **Fern Aurora n=4** (~02:00 UTC) — variance-bound, MERGE UNCERTAIN
4. **Frieren Soft-Muon annealing** — direct mechanism class of record #20
5. **Thorfinn cooldown_frac retune** — cheap scalar tune
6. **Tanjiro PMuon** — record #18 stack test
7. **Askeladd SFM fallback** (c_const=0.01) — schedule-free with EMA averaging

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Group naming inconsistency: `g1r2-nezuko/attn-soap-gate` (not `attn-soap-trust-gate`); `g1r2-fern/aurora-r17` (not `contra-soap-aurora`); `g1r2-askeladd/sfm` (not `schedule-free-muon`).
- All n=4 runs: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800
- Primary metric: `ffs_mean` (lower is better), tie-break: `val/loss mean`
- For merge: BOTH mean ≤ 3.27760 AND ffs_mean ≤ 3131.25 vs current merged baseline
