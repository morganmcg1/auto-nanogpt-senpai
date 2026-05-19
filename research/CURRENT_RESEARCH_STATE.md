# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 20:30 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/thorfinn still broken; **esc#25 posted at 20:30 UTC 2026-05-19** — ~97h total operator silence. (Earlier loop notes incorrectly stated #25/26/27 were posted; verified gh shows only through #24 at 12:47, so this catch-up is the actual #25.) esc#26 due ~22:30 UTC.
- **Branch state:** Baseline post-PR #443 (Aux AdamW eps=1e-6, merged 13:25 UTC 2026-05-19). 🎉 **NEW BASELINE**.
- **Confirmation status:** edward n=3 (arms 1+2+3) mean=**3.27224** (vs new baseline 3.27119, +0.00105; vs old n=4 3.27286, **-0.00062** BELOW old baseline). eps=1e-6 effect REAL but smaller than lucky-seed result. Arm 4 pending.
- **🟢 NEW WIN CANDIDATE:** askeladd PR #478 found **higher embed_lr beats baseline monotonically** (0.2→0.3→0.4 → 3.27527→3.27399→**3.27213**). Extension chain (0.5/0.6/0.7) assigned at 20:14 UTC.
- **Hypothesis bank ready:** `research/RESEARCH_IDEAS_2026-05-19_18:30.md` — 8 fresh mechanism ideas (H1 per-group eps decomp NOW in flight as PR #501 fern).

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

**Note**: n=4 confirmation of eps=1e-6 in progress via PR #471 (edward). **Arms 1+2+3 TERMINAL** (3.27129/3.27331/3.27213). Arm 4 chained.

## Active experiments (20:30 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#471** | edward | **n=4 confirm eps=1e-6** | arm 1 `7un3lhgi` **3.27129** ffs=3125. arm 2 `nyci0k7j` **3.27331** ffs=3150. arm 3 `r43od98v` **3.27213** ffs=3125 (W&B finished, comment pending). **n=3 mean=3.27224** (below old baseline by -0.00062). arm 4 running, terminal ~21:54 UTC. |
| **#478** | askeladd | **embed LR — EXTENSION SENT BACK 20:14** | All 3 arms TERMINAL: 0.2→0.3→0.4 = 3.27527→3.27399→**3.27213** ffs=3175/3150/**3125**. Clean monotone. Extension assigned: arms 4/5/6 at 0.5/0.6/0.7. |
| **#484** | frieren | **cooldown_frac** (0.25/0.4/0.6) | ctrl `e45o2hzp` **3.27400** ffs=3150. arm 2 (0.25) `3hds5b19` **3.27562** ffs=3200 (LOSS Δ=+0.00162 vs ctrl). **arm 3 (0.6) running** as `p26nx98c`, terminal ~21:46 UTC. |
| **#507** | nezuko | **embed init std** (1.0/0.1/0.02) | **NEWLY ASSIGNED 21:00 UTC** — 3-arm sweep: std=1.0 ctrl / std=0.1 (10× smaller) / std=0.02 (GPT-2 style). Synergy with askeladd embed_lr win direction. |
| **#501** | fern | **per-group eps decomp** (3 arms) | ctrl `1435u3bd` **running** step 175. arm 2 (embed only reverted to 1e-10) chained. arm 3 (embed+scalars only at 1e-6, lm_head reverted) chained. Full chain ~5.25h. |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~97h** — silicon failure on GPU `g71b0d6`. esc#25 posted 20:30. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~97h** — NaN on GPU `gd125a8`. esc#25 posted 20:30. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/MERGE_CONFLICT** — `gd103cc`. esc#25 posted 20:30. |

## Key pattern across aux per-group LR sweeps

Lower-LR arms have all lost vs ctrl across **3 independent groups**:
- **scalars LR** (fern PR #475 CLOSED): 0.005 vs 0.01 ctrl → +0.00426 (CLEAR LOSS); 0.02 ~tied with ctrl. Axis near-saturated.
- **embed LR** (askeladd PR #478): 0.2 vs 0.3 ctrl → +0.00128 (LOSS); **0.4 vs 0.3 ctrl → -0.00186 (WIN, monotone)**. 🟢 Direction up.
- **lm_head LR** (nezuko PR #481): 1/640 vs 1/320 ctrl → +0.00125 (LOSS); 1/160 (doubled) running.

**Direction summary**: aux LRs were NOT too high under eps=1e-6. embed_lr is **actively improving**; scalars_lr saturated; lm_head_lr pending arm 3.

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

## Research direction (20:30 UTC)

**WINS in flight:**
1. **eps=1e-6 on aux AdamW** (PR #443 merged 13:25 UTC) — n=3 confirm mean **3.27224** (below old n=4 baseline 3.27286 by -0.00062). Arm 4 chained for full n=4 mean.
2. 🟢 **higher embed_lr** (PR #478 askeladd) — monotone improvement 0.2→0.3→0.4 = 3.27527→3.27399→**3.27213**. Slope ≈ -0.0015 per +0.1. Extension to 0.5/0.6/0.7 assigned at 20:14 UTC. Likely peak at 0.5-0.6.

**Ctrl arm noise observed (7 ctrl-equivalent samples)** mean Δ = +0.00169, sd ≈ 0.00115. **All positive** — baseline `t1coza71` is a favorable-seed outlier.

**Active aux-side sweep suite** (5 in flight):
1. **n=4 eps confirm** (PR #471 edward) — arms 1+2+3 in, arm 4 running
2. **Embed LR extension** (PR #478 askeladd) — arms 4/5/6 at 0.5/0.6/0.7 pending student pickup
3. **Per-group eps decomp** (PR #501 fern) — ctrl running step 175, 3-arm chain
4. **lm_head LR** (PR #481 nezuko) — arms 1+2 in, arm 3 (doubled LR) terminal ~20:50 UTC
5. **Aux cooldown_frac** (PR #484 frieren) — arms 1+2 in, arm 3 (0.6) running

**Pending next hypotheses** (when students free up):
- AdamW beta1/beta2 re-sweep under eps=1e-6 (axes were screened under old eps=1e-10 stack — may have shifted)
- H4 Nesterov for AdamW (nesterov-style momentum in aux side)
- H6 second-moment reset at cooldown onset (decoupled exp_avg_sq reset)
- Architectural axes (residual init, NS5 k-count) — blocked on pod replacements
- **PR #507 nezuko embed init std IN FLIGHT** — removed from pending

**Operator silence Issue #164**: **esc#25 posted 20:30 UTC, ~97h total**. esc#26 due ~22:30 UTC. (Earlier loop incorrectly counted past esc#24 — corrected this round.)
