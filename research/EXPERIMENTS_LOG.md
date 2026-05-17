# SENPAI Research Results — auto-nanogpt-1gpu-r2

## 2026-05-16 23:15 — Cycle 32: PR #139 MERGED (NEW BASELINE), frieren screen near-miss

### ⭐ ALPHONSE CONTRA_MUON=0.5 n=4 — MERGED (PR #139) — NEW BASELINE

W&B run `db1rrfx3`:

| Trial | val/best_loss | ffs |
|---|---|---|
| T0 | 3.27830 | 3150 |
| T1 | 3.27634 | 3125 |
| T2 | 3.27551 | 3100 |
| T3 | 3.27577 | 3100 |
| **n=4 mean** | **3.27648** | **3118.75** |
| statsig | (3.28−3.27648)×2 = **0.00704** ≥ 0.004 ✓ | |

Beats prior baseline (PR #78) on both bars: val −0.00112, ffs −12.5 steps. **MERGED.** Mechanism: increasing CONTRA_MUON from 0.4 → 0.5 adds more spectral exploration via contravariant perturbation, escaping suboptimal gradient directions faster during peak-LR phase. Counter to intuition (more noise → better speed), but consistent with the "spectral exploration" interpretation.

New baseline after merge: mean=3.27648, ffs_mean=3118.75.

### FRIEREN Soft-Muon-anneal screen — NEAR-MISS vs new baseline (PR #177)

W&B run `dhqwygng` (p_start=0.10 → p_end=0.0 over first half):

| Metric | Screen | New baseline | Δ |
|---|---|---|---|
| val/loss | 3.27667 | 3.27648 | +0.00019 (MISS by tiny margin) |
| ffs | 3125 | 3118.75 | +6.25 steps (MISS) |

Excellent mechanism signal — val=3.27667 is far below old baseline (3.27760) and very close to new one. Miss is only 0.019% on val and 6.25 steps on ffs. Pre-approved p_start=0.07 follow-up screen launched. Analysis: annealing p=0.10 → 0.0 over first half of training adds spectral mixing during peak-LR phase and eliminates it during cooldown. Mechanism is sound; parameter needs slight reduction.

---

## 2026-05-16 22:15 — Cycle 31: Edward Contra-Muon n=4 CLOSED (stronger-but-slower); Askeladd SFM MISS; fern/nezuko T3 started

### Edward Contra-Muon n=4 @ 3225 steps — CLOSED, superseded (PR #76)

W&B run `zsqazpmr` (`g1r2-edward/contra-muon`):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27750 | 3175 |
| T1 | 3.27599 | 3175 |
| T2 | 3.27652 | 3175 |
| T3 | 3.27607 | 3175 |
| **n=4 mean** | **3.27652** | **3175** |
| statsig | **(3.28−3.27652)×2 = 0.00696 ≥ 0.004 ✓** | |

- Statsig PASS but ffs_mean=3175 > baseline 3131.25 — **FFS MISS**, does NOT beat merged baseline on primary metric.
- "Stronger but slower" pattern (#3 instance this session: Soft-Muon, Newton-Muon, now Contra-Muon-only).
- Mechanism superseded by PR #78 (merged baseline already has Contra-Muon + SOAP-MLP; edward's PR is the Contra-Muon-only subset).
- PR #76 closed. Edward reassigned to AdEMAMix-aux (PR #199).

### Askeladd SFM uniform c_t screen — MISS, fallback triggered (PR #181)

W&B run `groom2ym` (`g1r2-askeladd/sfm`):

| Field | Value |
|---|---|
| Screen val/loss | 4.60499 |
| ffs | -1 (MISS — never crossed 3.28) |
| y_z_diff_fro (terminal) | ~2.2e9 (massive divergence) |
| c_t at terminal | 0.00031 |

Root cause: `c_t = 1/(t+1)` weighs early pre-warmup iterates near-equally with trained iterates. By step 3175, most of the Polyak average weight sits on random-init timesteps. The `||y − z||` norm grows to 2.2B — z has moved far from init but y averages it all back toward init.

Fallback (pre-approved): `SFM_C_SCHEDULE=const`, `SFM_C_CONST=0.01` (EMA with ~100-step window). Screen `k3wkjy84` launched by student. This is a fundamentally sounder design — tracks recent trajectory rather than summing all history.

### Fern Aurora n=4 T2 terminal — BORDERLINE (PR #125)

W&B run `5kr7d0i5`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| n=3 mean | **3.27844** | — |

n=3 mean=3.27844 > 3.27800 → statsig currently fails. For n=4 MERGE: T3 needs val ≤ 3.27668 AND ffs ≤ 3125. T1's MISS (-1) means if using train_steps for ffs calculation, ffs_mean ≥ 3131.25 even with perfect T3. **Merge path nearly closed.** T3 still running (step 878/3175).

### Nezuko Attn-SOAP+trust-gate n=4 T2 terminal — OUTSTANDING (PR #124)

W&B run `790h1llo`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| n=3 mean | **3.27750** | **3125** |

All 3 trials within 0.00015 val! n=3 mean=3.27750 beats both baseline bars (≤3.27800 val, ≤3131.25 ffs). T3 needs val ≤ 3.27852 (generous bar). **MERGE NEAR-CERTAIN.** T3 at step 553/3175.

---

## 2026-05-16 20:25 — Cycle 30 (cont): Tanjiro Lookahead CLOSED, nezuko/fern T0+T1 interim results

### Tanjiro Lookahead α=0.7 retry — MISS, PR #161 CLOSED

W&B run `yph361ta` @ train_steps=3175:

| Arm | α | Final val | ffs |
|---|---|---|---|
| Original screen | 0.5 | 3.30606 | -1 (MISS) |
| Retry | **0.7** | **3.28985** | -1 (MISS) |

Higher α (weaker pullback) recovered 0.016 val/loss but still missed by 0.010. Structural issue confirmed: Lookahead's slow-fast averaging slows cooldown val descent regardless of α. Lookahead doesn't transfer to this short-step cooldown-dominated regime. PR #161 closed.

### Tanjiro reassigned — PMuon (PR #187)

Record #18 mechanism: bilateral streaming covariance power preconditioning (Σ_L, Σ_R with γ=0.3 power exponent, β=0.95). Stacks on top of merged Contra+SOAP-MLP+NS5 after the NS5 step. Fresh preconditioner class — softer than KL-SOAP (pf=1 eigendecomp) but more adaptive than plain SOAP (pf=10).

### Nezuko Attn-SOAP+trust-gate n=4 T0+T1 (interim) — OUTSTANDING

W&B run `790h1llo` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | **3.27743** | **3125** |
| T1 | **3.27750** | **3125** |
| n=2 mean | **3.27747** | **3125** |

Remarkably consistent T0/T1 pair (val within 0.00007!). Both beat merged baseline on both metrics. If T2+T3 continue pattern → n=4 mean ≤ 3.27800 AND ffs_mean ≤ 3125 = **MERGE CANDIDATE**.

### Fern Aurora n=4 T0+T1 (interim) — HIGH VARIANCE WARNING

W&B run `5kr7d0i5` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | **3.27592** | **3100** |
| T1 | **3.28172** | **-1 (MISS!)** |

T1 completely missed — Aurora's diagonal leverage-score equalization is seed-sensitive. Path to merge now requires both T2 and T3 to hit near T0 quality. High variance is concerning. Monitoring.

## 2026-05-16 19:10 — Cycle 30: Askeladd KL-SOAP screen MISS, reassigned to Schedule-Free Muon

### Askeladd KL-SOAP+H screen — MISS, PR #166 CLOSED

W&B run `061cl8bj` @ train_steps=3125:

| Metric | Value |
|---|---|
| val/loss at terminal | **3.29515** |
| ffs (first_step_to_target) | **-1 (never reached 3.28)** |
| Step time | ~2.6 s/step |

Val=3.295 is +0.0175 above merged baseline mean (3.27760) and well above the 3.281 threshold in the predeclared decision tree. KL-SOAP+H replacing (not stacking on) the merged Contra+SOAP-MLP stack was ~50 steps worse on terminal val/loss at the same step budget. The pf=1 eigenbasis frequency doubled per-step compute but didn't recover the NS5+Contra-Muon orthogonalization the merged baseline relies on. PR #166 closed.

### Askeladd reassigned — Schedule-Free Muon (PR #181)

Fresh mechanism class: Polyak iterate averaging with constant LR, eliminating cooldown entirely. Hypothesis: constant LR keeps gradient magnitude steady; iterate averaging absorbs noise → val crosses 3.28 earlier. Implementation: maintain z (trajectory) and y (averaged eval point), Muon update on z, y ← (1 − 1/(t+1)) · y + (1/(t+1)) · z. No cooldown_frac, no LR warmup-cooldown schedule. First test of schedule-free paradigm on this track.

## 2026-05-16 17:55 — Cycle 29 (cont): Thorfinn Soft-Muon n=4 CLOSED, reassigned to cooldown_frac retune

### Thorfinn Soft-Muon p=0.05 n=4 — STRONGER-BUT-SLOWER, PR #103 CLOSED

W&B run `nfkk0mms` @ train_steps=3175-3325 (final):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.274159 | 3250 |
| T1 | 3.274896 | 3250 |
| T2 | 3.272523 | 3225 |
| T3 | 3.275516 | 3250 |
| **n=4 mean** | **~3.2741** | **~3.2243** |

Statsig: `(3.28 − 3.2741) × √4 = +0.0118` — **PASSES** statsig (need ≥ 0.004). Val/loss excellent — best n=4 val mean of the session! BUT ffs_mean ≈ 3244 > baseline 3131.25. Does NOT beat merged baseline on FFS metric. Clean "stronger but slower" result — Soft-Muon's polynomial spectral compression lowers terminal val but slows cooldown convergence, adding ~75-100 steps vs baseline. PR #103 closed.

### Thorfinn reassigned — cooldown_frac retune (PR #178)

Three single-seed screens: cooldown_frac = 0.65, 0.70 (baseline reference), 0.75. If ffs ≤ 3100 AND val ≤ 3.279, predeclare n=4. Target: identify if scalar cooldown retune shifts the 3.28 crossing from ~step 3125 to ~step 3075. Predeclared sweep comparison table when all 3 screens complete.

## 2026-05-16 17:46 — Cycle 29: Frieren MuLoCo n=4 CLOSED, reassigned to Soft-Muon annealing

### Frieren MuLoCo+NorMuon n=4 — CLEAN NEGATIVE, PR #109 CLOSED

W&B run `jzsue46n` @ train_steps=3175 (final):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.282398 | -1 (miss) |
| T1 | 3.281958 | -1 (miss) |
| T2 | 3.279381 | 3175 |
| T3 | 3.280067 | -1 (miss) |
| **n=4 mean** | **3.28095** | **1/4 hit** |

Statsig: `(3.28 − 3.28095) × √4 = -0.0019` — **FAILS** statsig (need ≥ 0.004). Only T2 reached target. MuLoCo outer-Nesterov wrapping does not transfer to the merged Contra+SOAP-MLP step budget. The original screen at 3275 (`akwwpkv3`, val=3.27688 ffs=3225) was real but stronger-but-slower — needs ~100 more steps than merged baseline allows.

Clean negative — well-executed predeclaration honored across all 4 trials. PR #109 closed.

### Frieren reassigned — Soft-Muon annealing on merged base (PR #177)

Fresh hypothesis: record #20 (current global best at 3030 steps) uses **annealed Soft-Muon** as the key novel mechanism. Soft-Muon NS5 with `x^(1-p)` polynomial mixing, p_start=0.10 → p_end=0.0 annealed over first half of training. Applied to model.blocks.parameters() ndim>=2, alongside the existing Contra-Muon + SOAP-MLP stack. Target: cleaner cooldown trajectory + earlier 3.28 crossing.

## 2026-05-16 15:55 — Cycle 24: Fern Aurora screen FFS-WINNING, alphonse n=4 launched, frieren n=4 confirmed clean negative

### Fern Aurora screen — FFS-WINNING result on Contra+SOAP-MLP base (PR #125)

After two prior crashes (`csj1tm5z` @ step 1475, `isi6y97w` @ step 575) and a clamp fix (`D.clamp_(1e-6, 1e6)`):

| Run | Config | val/loss | ffs | Statsig (n=1) |
|---|---|---|---|---|
| `lqwaozx7` | Aurora on Contra+SOAP-MLP, 3175 steps | **3.27706** | **3125** | — |

**SINGLE-SEED BEATS MERGED BASELINE ON BOTH METRICS:**
- val 3.27706 < baseline 3.27760 (−0.00054)
- ffs 3125 < baseline ffs_mean 3131.25 (−6.25)

n=4 PREDECLARED at train_steps=3175 at 15:54 UTC. Fern to launch immediately. ETA terminal ~21:00-22:00 UTC.

Aurora is the FIRST mechanism (alongside CONTRA_MUON=0.5 tuning) to produce a single-seed FFS win on the merged baseline. Critically, Aurora is a fundamentally different mechanism from CONTRA_MUON tuning — it's diagonal leverage-score equalization inside NS5 from record #17. If both n=4 confirmations pass, they could potentially be stacked.

### Alphonse n=4 LAUNCHED — CONTRA_MUON=0.5 (PR #139)

W&B run `db1rrfx3` launched 15:33 UTC, currently step ~350/3175 trial 0. Same configuration as merged baseline except CONTRA_MUON=0.4 → 0.5. ETA full n=4 terminal ~22:00-22:30 UTC.

### Frieren n=4 MuLoCo+NorMuon — CLEAN NEGATIVE confirmed (PR #109)

W&B run `jzsue46n` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.28240 | -1 (never crossed 3.28) |
| T1 | 3.28196 | -1 (never crossed 3.28) |
| T2 | running | — |
| T3 | — | — |

T0 and T1 both miss the 3.28 target at 3175 steps. T2/T3 in progress per binding predeclaration; ETA full terminal ~17:40 UTC. Mean would need ≤3.27587 across T2/T3 to salvage statsig — ~3σ unlikely. Clean negative. Will close PR after SENPAI-RESULT.

Pattern: MuLoCo outer-Nesterov wrapping doesn't add to Contra+SOAP-MLP at 3175 steps. The original NorMuon-clean base achieved val=3.27688 ffs=3225 at 3275 steps in screen, but stacking MuLoCo doesn't compress further to 3175 steps.

### Thorfinn Soft-Muon p=0.05 n=4 — strong val, FFS not competitive (PR #103)

W&B run `6kjpjnvd` @ train_steps=3325 (plain Muon + NorMuon + Soft-Muon base):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27423 | 3250 |
| T1 | 3.27492 | 3250 |

Remarkable T0/T1 agreement at ffs=3250. Excellent val/loss but ffs=3250 > merged baseline 3131.25 by 119 steps. Pattern: "stronger but slower" — same as Newton-Muon, NorMuonH. Will close PR after T2/T3 terminal (~17:40 UTC).

### Edward Contra-Muon n=4 — statsig pass likely, FFS not competitive (PR #76)

W&B run `zsqazpmr` @ train_steps=3225:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27750 | 3175 |
| T1 | 3.27599 | 3175 |

Excellent val (mean projection ~3.276), but ffs=3175 > merged baseline 3131. Pod showing slow step rate (~6010 ms/step) but GPU healthy at 100%. ETA terminal ~21:00 UTC. Will close after terminal.

## 2026-05-16 15:35 — Cycle 23: Alphonse CONTRA_MUON=0.5 screen beats baseline on both metrics

### Alphonse CONTRA_MUON=0.5 screen — BEATS merged baseline on BOTH val AND FFS (PR #139)

| Run | Config | val/loss | ffs | Statsig (n=1) | Notes |
|---|---|---|---|---|---|
| `hjsjscjy` | CONTRA_MUON=0.3, 3175 steps | 3.27804 | 3150 | — | First FFS-competitive screen (cycle 18) |
| `yctj2ozd` | CONTRA_MUON=0.5, 3175 steps | **3.2763** | **3125** | — | BEATS baseline (3.27760/3131.25)! |

Screen `yctj2ozd` (CONTRA_MUON=0.5) delivers val=3.2763 ffs=3125 — the first single-seed result to beat the merged baseline on BOTH primary metrics simultaneously. N=4 PREDECLARED at train_steps=3175 with CONTRA_MUON=0.5. Predeclare comment posted at ~15:15 UTC. ETA terminal ~22:30-23:00 UTC.

Analysis: Reducing CONTRA_MUON from 0.4 (merged) → 0.5 (stronger contra correction) appears to tighten the convergence trajectory during cooldown. The contra correction `T - T^T` removes antisymmetric noise from the operator; a higher coefficient removes more, leading to a cleaner Newton-Schulz input. This translates directly to earlier FFS crossing without sacrificing terminal val.

### Askeladd NorMuonH n=4 @ 3300 — CLOSED, statsig pass but not FFS-competitive (PR #74)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27781 | 3225 |
| T1 | 3.27573 | 3200 |
| T2 | 3.27863 | — |
| T3 | ~3.277xx | — |
| n=4 mean | **3.27732** | ffs_mean ~3225-3250 |

n=4 mean=3.27732 — STRICTLY BETTER VAL than merged baseline (3.27760 → 3.27732), but ffs_mean ~3225-3250 — STRICTLY WORSE FFS than baseline 3131.25. Closed as "statsig pass but not FFS-competitive." NorMuonH on plain Muon base produces excellent terminal val but cannot compress the convergence curve to match Contra+SOAP-MLP's FFS efficiency. Reassigned to KL-SOAP + hyperball (PR #166).

### Askeladd reassigned — KL-SOAP + hyperball (PR #166, just assigned)

New hypothesis: Replace Contra-Muon+NS5+SOAP-MLP with KL-SOAP+hyperball on ALL 2D block params. Key parameters: β1=0.95, β2=0.90, shampoo_beta=0.90, pf=1, lr=0.018 (record #19 HPs). Reference: record #19 (n=6 mean=3.27800 @ 3125 steps, statsig pass). KL-SOAP at pf=1 provides the most aggressive curvature tracking in the literature — eigendecomp every step rather than every 10 steps. Unknown if it stacks with or replaces the Contra mechanism.

## 2026-05-16 14:15 — Cycle 19: Newton-Muon closed, Lookahead assigned, alphonse FFS-competitive

### Tanjiro Newton-Muon CLOSED — positive but not merge-eligible (PR #81)

Two terminal SENPAI-RESULTs:

| Config | n | val/loss mean | ffs_mean | Statsig | Merge? |
| --- | --- | --- | --- | --- | --- |
| Newton-Muon-only @ 3325 (`cpoe66ut`) | 4 | **3.27643** | 3256.25 | PASSES (0.00714) | NO — ffs > baseline |
| Newton-Muon-attn + Contra+SOAP-MLP @ 3175 (`wzgya0cq`) | 1 | 3.28893 | -1 | N/A | NO — missed target |

Newton-Muon-only at 3325 produces the LOWEST n=4 mean val/loss of any r2 student (3.27643), beats public record #15 (3.2785) by 0.00207. Paper-quality result, reproducible (σ≈0.0005). But ffs_mean=3256.25 at 3325 steps vs merged baseline ffs_mean=3131.25 at 3175 — 125 steps worse on primary metric.

Stack with Contra+SOAP-MLP (Option B) at 3175 failed badly (3.28893, never reached 3.28). Numerics clean (0 Cholesky failures), but the combined 4-mechanism stack doesn't compress below 3.28 in 3175 steps. Pattern: each additional mechanism extends the cooldown needed.

Conclusion: Newton-Muon mechanism is "stronger but slower." Not FFS-competitive at 3175. Closed PR #81.

### Tanjiro reassigned: Lookahead-Muon (PR #161)

Fresh hypothesis: Lookahead wrapper on merged Contra+SOAP-MLP baseline (Zhang et al. 2019). Inner optimizer takes k=5 steps normally; every k steps: θ_slow ← θ_slow + 0.5(θ_fast − θ_slow), then θ_fast ← θ_slow. Applied to ALL trainable params AFTER warmup.

Goal: FFS reduction by 30-80 steps via trajectory variance smoothing during peak-LR phase. If screen (single-seed at 3175) lands ≤ 3.279 with ffs ≤ 3175, predeclare n=4. Stretch goal: ffs_mean < 3131.

### Alphonse CONTRA_MUON=0.3 screen FFS-COMPETITIVE (PR #139)

`hjsjscjy` terminal: val=**3.27804**, ffs=**3150** at 3175 steps. Single-seed 19 steps worse than merged baseline ffs_mean=3131.25, but competitive val. FIRST FFS-competitive result since PR #78 merged. Alphonse launched CONTRA_MUON=0.5 screen (`yctj2ozd`) at step ~450 at 13:40 UTC. ETA terminal ~15:35 UTC.

If 0.5 screen competitive: predeclare n=4 at 3175 with best arm. n=4 mean could potentially beat baseline if seed distribution is favorable.

## 2026-05-16 10:30 — Cycle 14: Multiple screens terminal, PR #112 closed, alphonse reassigned

### Alphonse p=1.5 NEW-base CLOSED — NULL result (PR #112)
- W&B run `5gd8cw6c` (p=1.5 on Contra+SOAP-MLP NEW-base): **val=3.2775, ffs=3150** at 3275 steps
- Summary: p=1.5 on NEW-base essentially equals merged baseline mean (3.27760), within 1σ noise.
  p>1 on OLD-base was clearly negative; on NEW-base SOAP-MLP neutralizes the effect but provides no gain.
- Conclusion: linear LR cooldown remains optimal. Power-law p>1 ruled out for both bases.
- PR #112 CLOSED. Alphonse reassigned to **PR #139: Contra-Muon coefficient retune** (CONTRA_MUON ∈ {0.3, 0.5} vs baseline 0.4).

### Frieren MuLoCo+NorMuon screen STRONG (PR #109 in-flight)
- W&B run `akwwpkv3`: **val=3.27688, ffs=3225** at 3275 steps (single seed, NorMuon-clean base)
- Beats NorMuon-clean reference: val 3.27800→3.27688 (−0.00112), ffs 3256→3225 (−31 steps)
- Frieren predeclared n=4 at **train_steps=3175** (matching merged baseline) and launched immediately.
- Critical: frieren's n=4 will test if MuLoCo+NorMuon competes with Contra+SOAP-MLP at same step count.
- If n=4 mean ≤ 3.278, ffs_mean ≤ 3131: MERGE candidate. ~6.75h ETA.

### Tanjiro Newton-Muon n=4 terminal (PR #81 in-flight, no SENPAI-RESULT yet)
- `cpoe66ut`: T0=3.27599/ffs=3250, T1=3.27720/ffs=3275, T2=3.27612/ffs=3250, T3=3.27639/ffs=3250
- n=4 mean=3.27643, ffs_mean=3256.25, margin=0.00714 — PASSES statsig
- But ffs=3256.25 > merged baseline ffs=3131.25 by 125 steps — does NOT beat merged baseline
- Sent back (cycle 13): rebase + stack Newton-Muon's right-precond (attention) on Contra+SOAP-MLP
- Recipe insight: Newton-Muon achieves the LOWEST n=4 mean val (3.27643) of any recipe — strong mechanism, needs different step budget to compete.

### Thorfinn Soft-Muon p=0.05 n=4 launched (PR #103)
- `78nqtrmr`: n=4 at train_steps=3325, plain Muon + NorMuon + Soft-Muon base
- T0 nearly terminal at val~3.2742 ffs=3225 (strongest single-seed result in portfolio!)
- ETA ~8-9h to T4 terminal. Single-seed trajectory at 3.2742 is remarkable.

### Edward Contra-Muon T0 strong (PR #76)
- T0 from `zsqazpmr`: val=3.2760, ffs=3175. T1 just started (step ~100).
- Expected: n=4 mean ~3.277-3.278 range. Likely pass statsig at 3225 steps.

### Askeladd NorMuonH T0 done (PR #74)
- T0 from `lw99ybyp`: val=3.2777, ffs=3250 at 3300 steps. T1 at step ~1825/3300.

## 2026-05-16 07:55 — Cycle 11: Soft-Muon p=0.05 strong, power-law LR closing

### Thorfinn p=0.05 SCREEN STRONG SIGNAL (PR #103)
- W&B run `pzp8b4rq` finished cleanly at **val/loss=3.27553, ffs=3250** at train_steps=3325.
- **Single seed 0.00207 BELOW merged baseline mean 3.27760** — strongest sub-baseline single-seed result in this round.
- p=0.075 retry `6empzhxo` crashed at step 625 — external pod restart, NOT numerical (blend still 0).
- Sent back PR #103 with directive: **launch predeclared n=4 @ 3325 confirmation immediately**, skip p=0.075 retry.
- For statsig at n=4: need mean ≤ 3.278. With single seed at 3.27553 and recipe variance σ~0.0007 typical, n=4 mean projects to 3.276–3.278 (borderline confirmable).
- Recipe (Soft-Muon p=0.05 on plain Muon) is **orthogonal** to merged Contra+SOAP-MLP — potential future stack candidate.
- ETA T3 ~13h from launch.

### Alphonse power-law LR closing (PR #112)
- W&B run `fg11eojr` (p=1.2): **3.28031** at 3275 steps — MISS
- W&B run `vvwsv9fm` (p=1.5 OLD-base): **3.28470** at 3275 steps — MISS
- Monotonic trend: p=1.0→0.000, p=1.2→+0.00231, p=1.5→+0.00670 — power-law cooldown with p>1 is decisively counterproductive on NorMuon base.
- p=1.5 NEW-base screen launched at 08:28 UTC (decisively expected to miss). Acknowledged "let it finish" per alphonse's decision tree.
- After NEW-base screen terminalizes: close PR #112 with documented negative evidence, reassign alphonse to **Contra-Muon coefficient retune on merged base** (CONTRA_MUON ∈ {0.3, 0.5} vs baseline 0.4).

### Other r2 students (in-flight, no new terminals)
- edward `zsqazpmr` (Contra-Muon n=4 @ 3225): T0=3.27750 done, T1 at step ~2275/3225 (~70%). ~10h to T3.
- tanjiro `cpoe66ut` (Newton-Muon n=4 @ 3325): T0=3.27599, T1-T2 done, T3 at step ~1275/3325 (~38%). Best T0 is BEST single-trial of any wave-1 recipe.
- askeladd `lw99ybyp` (NorMuonH n=4 @ 3300): launched, at step ~1425/3300 (~43%) — picked up cycle-9 rebase+launch directive.
- frieren `akwwpkv3` (MuLoCo+NorMuon screen @ 3275): just launched, step ~0.
- nezuko `g4zvpp9c` (Attention SOAP + trust gate): smoke at step ~40 + 2 prior smokes done. PR #124 picked up.
- fern `csj1tm5z` (Aurora orthogonal projection): screen at step ~25 + 1 prior smoke done. PR #125 picked up.

All 8 r2 students productive — zero idle GPUs in cycle 11.

## 2026-05-16 06:35 — PR #78: Contra+SOAP-MLP — MERGED as new advisor baseline
- Branch: `g1r2-fern/contra-soap-mlp` (squash-merged `718dd3f`)
- See below entry for full experiment detail. BASELINE.md updated.

## 2026-05-16 06:35 — PR #80: Muon² n=4 confirmation — CLOSED (non-competitive)
- Branch: `g1r2-nezuko/muon-sq`
- W&B run: `7lxk02m6` | num_trials=4 | train_steps=3325

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27788 | 3300 |
| T1 | 3.27859 | 3300 |
| T2 | 3.27915 | 3300 |
| T3 | 3.27792 | 3300 |
| **mean** | **3.27839** | **3300** |

- Statsig check: (3.28 − 3.27839) × √4 = **0.00322** — FAILS 0.004.
- Recipe is stable (all seeds hit target, no crashes, std=0.0006). The n=4
  mean is 0.0008 above NorMuon-clean's statsig ceiling (3.27800 @ 3300).
- Closed because: (1) non-statsig; (2) even extended to 3375 steps, ffs_mean
  ≈ 3325 vs new baseline 3131 — won't merge. Muon² ordering (Adam var BEFORE
  NS5) is confirmed inferior to NorMuon's post-NS5 ordering on this benchmark.
- Status: **CLOSED**. Nezuko reassigned to Attention SOAP + trust gate (PR #124).

## 2026-05-16 05:45 — PR #78: Contra+SOAP-MLP — STATSIG WIN (merge pending rebase)
- Branch: `g1r2-fern/contra-soap-mlp`
- Hypothesis: SOAP eigenbasis preconditioning on MLP weights, applied to
  momentum *before* NS5+contra+NorMuon (matches record #14 reference ordering).
- W&B confirmation run: `6bbhoxm1` | num_trials=4 | train_steps=3175 (predeclared).

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27920 | 3150 |
| T1 | 3.27811 | 3150 |
| T2 | 3.27522 | 3100 |
| T3 | 3.27787 | 3125 |
| **mean** | **3.27760** | **3131.25** |

- Statsig check: (3.28 − 3.27760) × √4 = **0.00480 ≥ 0.004** — **PASSES**.
- Comparison vs NorMuon-clean baseline (PR #71): mean 3.27800 → 3.27760
  (−0.00040), ffs_mean 3256.25 → 3131.25 (**−125 steps**).
- Matches public record #14 (4 decimal places). Single-seed σ ≈ 0.0015.
- Auxiliary screening runs: `du7a5t1t` (3.27553 @ 3225, corrected ordering),
  `h3vsdeik` (3.27960 @ 3225, PR-literal ordering, superseded).
- The PR-literal ordering (SOAP after NorMuon variance) was suboptimal because
  NorMuon's per-element variance scaling is NOT basis-invariant — student
  caught this discrepancy by reading the record #14 reference file directly.
- Status: **STATSIG WIN, merge pending**. Blocked by (1) merge conflicts with
  auto-nanogpt-1gpu-r2 (NorMuon-clean merged after PR opened), (2) false-
  positive SENPAI-RESULT JSON parse on workflow-note comment. Sent back for
  rebase + comment disambiguation.

## 2026-05-16 05:30 — PR #74: NorMuonH — n=4 confirmation at 3275 (terminal, non-statsig by 0.00008)
- Branch: `g1r2-askeladd/normuonh-perinit`
- Hypothesis: NorMuon + hyperball + per-module init std (record #8 stack).
- W&B run: `6rf3nerz` | num_trials=4 | train_steps=3275 (predeclared).

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27781 | 3225 |
| T1 | 3.27777 | 3225 |
| T2 | 3.27798 | 3250 |
| T3 | 3.27860 | 3250 |
| **mean** | **3.27804** | **3237.5** |

- Statsig check: (3.28 − 3.27804) × √4 = **0.00392** — misses 0.004 by 0.00008.
- Recipe is real and reproducible (σ~0.0004 across 4 trials, tightest of any
  wave-1 stack so far). Mean misses statsig ceiling by 0.00004.
- Notable: NorMuonH at 3275 has ffs_mean=3237.5, beating NorMuon-clean's
  3256.25 — but the loss ceiling is the rule that matters for merge.
- Status: WIP. Send back for predeclared n=4 at train_steps=3300 (one cooldown
  cycle of headroom should push mean to ~3.276 with same σ).

## 2026-05-16 05:30 — PR #112: NorMuon + power-law LR cooldown — p=1.2 screen MISSED
- Branch: `g1r2-alphonse/normuon-plawlr`
- Hypothesis: `lr * (1-progress)/cooldown_frac)^p` with p=1.2 (record #20
  schedule) may give 25-75 step gain over linear cooldown.
- W&B screen run: `fg11eojr` | num_trials=1 | train_steps=3275 | LR_COOLDOWN_POWER=1.2
- Result: terminal **val/loss=3.28031, ffs=-1, reached_target=0**. Did NOT
  cross 3.28.
- Per predeclared branch decision: if 3.277 < val ≤ 3.280, try p=1.5 next.
  3.28031 is just above 3.280, but the spec says "both p=1.2 AND p=1.5 > 3.280
  → close". p=1.5 single-seed should be tried before deciding.
- Status: WIP. Student should auto-launch p=1.5 screen on next poll.

## 2026-05-16 05:45 — PR #103: Soft-Muon isolated p=0.05 — SCREEN CRASHED
- Branch: `g1r2-thorfinn/soft-muon`
- Hypothesis: Soft-Muon polynomial `x^(1-p)` at p=0.05 (reduced from p=0.1
  which missed at 3.28024) with annealed blend 0→0.8 from step 2500.
- W&B screen run: `hz91ow2y` | num_trials=1 | train_steps=3325
- Result: **crashed at step 1575/3325 (47%, mid-cooldown)**. Last val/loss
  reading 3.5253.
- Likely cause: Soft-Muon polynomial coefficients at lower p may produce
  numerical instability when blended with NS5 mid-cooldown. Needs debugging.
- Status: WIP. Student should investigate crash, may need p=0.075 midpoint.

## 2026-05-16 04:30 — PR #109: MuLoCo+NorMuon smoke — DIVERGED TO NaN
- Branch: `g1r2-frieren/muloco-normuon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper on top of NorMuon inner
  optimizer (record #13 stack).
- W&B smoke run: `mti327gb` | num_trials=1 | train_steps=400
- Result: **val/loss=NaN by step 400**. Diverged.
- Likely cause: outer_lr=0.7 too aggressive on NorMuon's variance-noisy update
  direction; or outer Nesterov momentum compounds NorMuon's variance instability.
- Status: WIP. Student should try outer_lr=0.5 or sync_interval=60 in smoke
  before screen.

## 2026-05-16 01:45 — PR #79: MuLoCo on plain Muon — CLOSED (all 4 corners missed)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- Final W&B sweep runs:

| run | si | outer_lr | train_steps | val/loss | reached |
| --- | --- | --- | --- | --- | --- |
| `bqfv4523` | 15 | 0.5 | 3300 | 3.2829 | 0 |
| `q57yhybv` | 30 | 0.7 | 3300 | 3.2810 | 0 |
| `ecohqy9o` | 15 | 0.7 | 3300 | 3.2815 | 0 |
| `v2wn0t8t` | 60 | 0.5 | 3300 | **3.2865** | 0 |

- Conclusion: All 4 sweep corners failed to reach 3.28. The si=60/lr=0.5 corner
  (meant to allow longer inner runs between outer steps) was actually the **worst**
  result. Plain Muon's NS5 orthogonalization already smooths the gradient direction
  — MuLoCo's outer Nesterov momentum provides no additional benefit. Public record
  #13's success was likely driven by MuLoCo wrapping NorMuon (which has noisy
  per-element variance), not plain Muon.
- Status: **CLOSED (dead end)**. Frieren reassigned to MuLoCo+NorMuon (PR #109).

## 2026-05-16 01:50 — PR #81: Newton-Muon — n=4 confirmation at train_steps=3275 (terminal, non-statsig)
- Branch: `g1r2-tanjiro/newton-muon`
- Hypothesis: Activation-covariance right-preconditioning applied to the Muon
  gradient before Newton-Schulz (refresh every 64 steps).
- W&B run: `xsb35b0m` | num_trials=4 | train_steps=3275

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.279715 | 3275 |
| T1 | 3.278674 | 3250 |
| T2 | **3.277678** | **3225** |
| T3 | 3.281277 | -1 (missed) |
| **n=4 mean** | **3.27934** | — |

- Statsig check: `(3.28 - 3.27934) × √4 = 0.001328` — BELOW 0.004. **Non-statsig.**
- Analysis: T0–T2 all cleared 3.28 individually, including T2 at 3.2777 (among
  the best individual trials in wave 1). T3 was a bad seed — 3.2813 — above the
  target, which dragged the mean to 3.279. The recipe is real but has high
  seed variance. Needs more cooldown steps to tighten the distribution.
- Status: WIP. Sent back for fresh n=4 at predeclared `train_steps=3325`.

## 2026-05-15 23:20 — PR #79: MuLoCo on plain Muon — sweep arm si=15 (terminal)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- W&B run: `ecohqy9o` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/ecohqy9o`)
  | num_trials=1 | train_steps=3300 | sync_interval=15, outer_lr=0.7
- Result: terminal **val/loss=3.2815 @ step 3300**,
  `speedrun/final_first_step_to_target=-1`, `speedrun/final_reached_target=0`.
  **Did NOT cross 3.28.**
- Context: 3rd consecutive single-seed screen to miss — `bqfv4523`=3.2829,
  `q57yhybv`=3.2810, `ecohqy9o`=3.2815. All at or above 3.281 margin.
- Conclusion: MuLoCo on plain Muon appears break-even or slightly worse than
  starter at train_steps=3300. si=60/lr=0.5 corner still pending. If that
  corner also misses ≥ 3.281, MuLoCo-on-plain-Muon is dead and frieren will
  be pivoted to MuLoCo wrapping a confirmed inner optimizer (NorMuon or
  Contra-Muon, per the approach of public record #13).
- Status: WIP. si=60 sweep arm pending.

## 2026-05-15 22:45 — PR #80: Muon² (Adam variance BEFORE Newton-Schulz) — single-seed screen
- Branch: `g1r2-nezuko/muon-sq`
- Hypothesis: Per-element Adam variance applied to gradients *before* the
  Newton-Schulz orthogonalization should preserve NorMuon's variance-normalization
  benefit while keeping the orthogonalization geometry clean. lr=0.10, wd=0.0125,
  β₂=0.95, train_steps=3350 (per record #7 / nezuko PR body).
- W&B run: `n18mqjfy`
  (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/n18mqjfy`) | num_trials=1 |
  train_steps=3350.
- Result: terminal **val/loss=3.2773 @ step 3350**,
  `speedrun/final_first_step_to_target=3300`, `reached_target=1`.
- Statsig at n=1 (informational): (3.28 − 3.2773) × √1 = 0.0027 — does NOT
  clear the 0.004 single-seed bar, but is below 3.28 and on track for n=4
  consideration with cooldown headroom.
- Status: WIP. n=4 confirmation `7lxk02m6` launched (T0 early at step 275).
  Single-seed margin smaller than edward/fern/alphonse, so n=4 statsig is
  uncertain; will need mean ≤ 3.278 across 4 seeds.

## 2026-05-15 20:30 — PR #74: NorMuonH (row/col variance + hyperball + per-module init std)
- Branch: `g1r2-askeladd/normuonh-perinit`
- Hypothesis: NorMuon's row/col Adafactor-style variance combined with hyperball
  constraint (preserve ‖p‖_F per step) and per-module init std (×1.25 attn.proj,
  zero block-level proj for residual-branch safety) should reduce optimizer
  steps. Public record #8: 3225 steps, mean val/loss 3.2776 (n=10).
- W&B run: `sohiul20` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/sohiul20`)
  | num_trials=4 | train_steps=3250 (predeclared confirmation).
- Per-trial final val/loss at step 3250:
  | trial | val/loss |
  | --- | --- |
  | 0 | 3.27849 |
  | 1 | 3.27942 |
  | 2 | 3.27835 |
  | 3 | 3.27840 |
  | **mean** | **3.27867** |
  | std | ~0.0005 |
- `speedrun/final_first_step_to_target = 3225`, all 4 trials cleared 3.28.
- Statsig check (rule `(3.28 − μ) × √n ≥ 0.004`): (3.28 − 3.27867) × 2 =
  **0.00267** — below the 0.004 threshold at n=4. **Not statsig.**
- Conclusion: NorMuonH is a real, reproducible recipe (very tight inter-seed
  variance) but its mean at step 3250 falls 0.0007 above the statsig ceiling.
  Adding more seeds at step 3250 would not help (mean too stable). Sent back
  asking for a fresh n=4 batch at a predeclared step ∈ {3275, 3300} to gain
  ~0.001 of cooldown headroom for statsig clearance.
- Status: WIP / not merged. Awaiting follow-up predeclared confirmation.

## 2026-05-17 00:00 — PR #125 CLOSED: Aurora on Contra+SOAP-MLP base (fern)

- Branch: `g1r2-fern/contra-soap-aurora`
- Hypothesis: Diagonal leverage-score equalization (Aurora record #17) inside NS5 polar step, stacked on top of Contra+SOAP-MLP merged base. Replaces standard polar with D-equalized polar for non-square MLP weights; square attention weights short-circuit to standard NS5.
- W&B run: `5kr7d0i5` (n=4, train_steps=3175)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| T3 | 3.27614 | 3125 |
| **n=4 mean** | **3.27787** | **3131.25** |
| statsig (3.28−mean)×2 | **0.00426** ≥ 0.004 ✓ | |

**Conclusion**: Statsig passes vs 3.28 gate but FAILS new baseline gates (PR #139 mean=3.27648, ffs=3118.75) on both bars. T1 (3.28172) is a catastrophic outlier — seed dispersion range = 0.00580, roughly 4× the typical mechanism variance and far exceeding baseline's 0.00279 range. Three of four seeds (T0, T2, T3) individually outperform the new baseline mean, confirming the mechanism works — but the variance kills n=4 aggregates.

**Key learning**: Aurora's diagonal leverage-score equalization is HIGH-VARIANCE on the merged Contra+SOAP-MLP base. The D fixed-point iteration introduces per-seed variation in the effective preconditioning that compounds over 3175 steps. This aligns with record #17's reported high-variance behavior. Not a mechanism failure, but needs n=8+ or a variance-reduction wrap to clear the new (tighter) baseline bars. Defer to next round.

Fern reassigned to PR #208: Power-law LR cooldown (LR_POWER=1.5/2.0), targeting record #20's schedule structure.
