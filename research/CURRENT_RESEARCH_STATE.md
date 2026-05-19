# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 19:10 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/thorfinn still broken; **esc#27 posted at 18:27 UTC 2026-05-19** — ~95.5h total operator silence. esc#28 due ~21:00 UTC.
- **Branch state:** Baseline post-PR #443 (Aux AdamW eps=1e-6, merged 13:25 UTC 2026-05-19). 🎉 **NEW BASELINE**.
- **Confirmation status:** edward n=2 mean=**3.27230** (vs new baseline 3.27119, +0.00111; vs old n=4 3.27286, -0.00056 BELOW old baseline). eps=1e-6 effect REAL but smaller than lucky-seed result. Arms 3+4 pending.
- **Hypothesis bank ready:** `research/RESEARCH_IDEAS_2026-05-19_18:30.md` — 8 fresh mechanism ideas (H1 per-group eps decomp top priority).

## ⭐ Current baseline (post-PR #443 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27119** (n=1 trial, passes n=1 bar < 3.27206) |
| `ffs` (primary) | **3100** (n=1; beats prior best 3125) |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| **Aux AdamW eps** | **`--aux_adamw_eps 1e-6`** (new flag; was hardcoded 1e-10) |
| MuonH inner AGC | `--muonh_agc_clip_ratio 0.05` |
| MuonH LR warmup | warmup_steps=100, shape=linear |
| Outer wrapper | MuLoCo Nesterov-SGDM (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| Aux AdamW | betas=(0.8, 0.95), **eps=1e-6**, AGC clip_ratio=0.05, weight_decay=0 |
| Cooldown | MuonH=cosine frac=1.0, aux=linear frac=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| W&B run | `t1coza71` (n=1 single trial) |
| Baseline PR | [#443](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/443) |

**Merge bar (against new baseline 3.27119):**
- **n=1 promotion bar**: val < **3.27039** (Δ ≤ −0.0008 vs 3.27119)
- **Conservative n=4 bar**: μ < **3.27079**

**⚠️ CRITICAL — ALL new experiment commands must include:**
```
--aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --muonh_cooldown_shape cosine --muonh_warmup_steps 100 --aux_adamw_eps 1e-6
```

**Note**: n=4 confirmation of eps=1e-6 in progress via PR #471 (edward). **Arm 1 TERMINAL at val=3.27129 (Δ=+0.00010)**. Arm 2 launched at 16:30 UTC (`nyci0k7j`), terminal ~18:18 UTC. 2 more arms after.

## Active experiments (19:10 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#471** | edward | **n=4 confirm eps=1e-6** | arm 1 `7un3lhgi` **3.27129** ffs=3125. arm 2 `nyci0k7j` **3.27331** ffs=3150. n=2 mean=**3.27230** (below old baseline). **arm 3 running**, terminal ~20:06 UTC. arm 4 chained. |
| **#478** | askeladd | **embed LR** (0.2/0.3/0.4) | ctrl `t83qa9mt` **3.27399** ffs=3150. arm 2 (0.2) `slkz2y5h` **3.27527** ffs=3175 (LOSS). **arm 3 (0.4) running**, terminal ~19:59 UTC. |
| **#484** | frieren | **cooldown_frac** (0.25/0.4/0.6) | ctrl `e45o2hzp` **3.27400** ffs=3150. **arm 2 (0.25) `3hds5b19` running** step 1750, terminal ~19:55 UTC. arm 3 (0.6) chained. |
| **#481** | nezuko | **lm_head LR** (1/640/1/320/1/160) | ctrl `7c46dsmk` **3.27172** ffs=3125. arm 2 (1/640) `42ixzfcf` **3.27297** ffs=3150 (LOSS). **arm 3 (1/160) running**, terminal ~20:50 UTC. |
| **#475** | fern | **scalars LR** (0.005/0.01/0.02) | ctrl `yekqkcmc` **3.27296** ffs=3150. arm 2 (0.005) `2tasvk8f` **3.27722** ffs=3200 (CLEAR LOSS). **arm 3 (0.02) `et18r49k` running** step 2375, terminal ~19:35 UTC. |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~95.5h** — silicon failure on GPU `g71b0d6`. esc#27 posted 18:27. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~95.5h** — NaN on GPU `gd125a8`. esc#27 posted 18:27. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/MERGE_CONFLICT** — `gd103cc`. esc#27 posted 18:27. |

## Key pattern across aux per-group LR sweeps (3 in flight)

Lower-LR arms have all lost vs ctrl across **3 independent groups**:
- **scalars LR** (fern): 0.005 vs 0.01 ctrl → +0.00426 (CLEAR LOSS)
- **embed LR** (askeladd): 0.2 vs 0.3 ctrl → +0.00128 (mild LOSS)
- **lm_head LR** (nezuko): 1/640 vs 1/320 ctrl → +0.00125 (mild LOSS)

**Consistent direction**: aux LRs are NOT too high under eps=1e-6. Awaiting higher-LR (×2) arms across all 3 groups to determine if optima are upward or already saturated.

## Saturated levers (post-PR #443)

- **Inner LR dynamics**: MuonH-SI HPs (lr/mu/wd), cooldown shape/frac, warmup steps=100, mu warmup/cooldown ALL NEG.
- **Inner optimizer geometry**: AGC clip_ratio (insensitive [0.02, 0.10]), Nesterov outer SGDM mu (0.5 optimal, drop/increase both NEG).
- **Aux optimizer**: eps sweep confirms **1e-6 > 1e-10 >> 1e-8**. betas saturated (PR #183 under old eps).
- **NS5**: k-count blocked (alphonse pod), all polynomial families closed (PR #438).
- **Logit softsign cap**: cap=15 is local optimum.
- **MuonH inner mu**: FULLY CLOSED (PR #450). Strong asymmetric U-shape — 0.90 mild NEG, **0.98 catastrophic (failed target)**. 0.95 unique optimum.
- **MuonH budget_mult**: FLAT (PR #451). All values [0.9, 1.0, 1.1] within ±0.00054. Axis closed.
- **MuLoCo ALL KNOBS**: sync_interval CLOSED (PR #453) — sync=30 optimal (15 ~10σ NEG, 60 within noise). outer_lr=0.7 CLOSED (PR #369). outer_momentum=0.5 CLOSED. outer class=SGDM CLOSED. MuLoCo lever fully exhausted.

## Key recent results (this round)

| PR | Lever | Arm results | Decision |
|---|---|---|---|
| #443 MERGED | Aux eps | ctrl=+0.00091, 1e-8=+0.00103, **1e-6=−0.00167 WIN** | **MERGED. New baseline 3.27119** |
| #450 CLOSED | MuonH mu | ctrl +0.00230, mu=0.90 ~10σ NEG, **mu=0.98 CATASTROPHIC** | **CLOSED — 0.95 unique optimum** |
| #451 CLOSED | budget_mult | ctrl/0.9/1.1 all within ±0.00054, FLAT | **CLOSED — axis insensitive** |
| #438 CLOSED | NS5 polynomial | ctrl +0.00177, classical ~5σ NEG, sharper ~3σ NEG | **CLOSED** |
| #453 CLOSED | MuLoCo sync_interval | ctrl +0.00268, sync=15 ~10σ NEG, sync=60 within noise | **CLOSED — sync=30 confirmed optimal, MuLoCo fully exhausted** |

## Research direction (17:00 UTC)

**WIN: eps=1e-6 on aux AdamW (n=4 confirmation in flight, arm 1 ✅ replicates).** Active follow-up thread: aux-side HP sweeps under new eps=1e-6.

**Ctrl arm noise observed (5 ctrl + edward arm 1 = 6 baseline-equivalent samples)**:
- edward arm 1: +0.00010
- nezuko ctrl: +0.00053
- fern ctrl: +0.00177
- edward arm 2: +0.00212
- frieren ctrl: +0.00281
- askeladd ctrl: +0.00280

Empirical mean Δ = +0.00169, sd = 0.00114. **All positive** — suggests baseline `t1coza71` was a favorable-seed outlier. The eps=1e-6 "win" relative to old n=4 baseline (3.27286) at n=2 mean=3.27230 is **-0.00056** — real but smaller than the lucky-seed -0.00167 suggested.

**Active aux-side sweep suite** (5 in flight):
1. **n=4 eps confirm** (PR #471 edward) — arm 1 ✅, arm 2 in flight
2. **Embed LR** (PR #478 askeladd) — ctrl ✅, arm 2 (0.2) in flight, arm 3 (0.4) chained
3. **Scalars LR** (PR #475 fern) — ctrl ✅, arm 2 (0.005) in flight, arm 3 (0.02) chained
4. **lm_head LR** (PR #481 nezuko) — arm 1 ctrl in flight, terminal ~17:15 UTC
5. **Aux cooldown_frac** (PR #484 frieren) — arm 1 ctrl in flight, terminal ~17:46 UTC

**Pending next hypotheses** (when students free up):
- Per-group eps decomposition (identify which group carries the eps=1e-6 win): test aux_adamw_eps per group (embed only, scalars only, lm_head only)
- AdamW beta1/beta2 re-sweep under eps=1e-6 (axes were screened under old eps=1e-10 stack — may have shifted)
- Architectural axes (residual init, NS5 k-count) — blocked on pod replacements

**Operator silence Issue #164**: **esc#26 posted 16:58 UTC, ~93.5h total**. esc#27 due ~19:00 UTC.
