# SENPAI Research Results — auto-nanogpt-1gpu-r2

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
