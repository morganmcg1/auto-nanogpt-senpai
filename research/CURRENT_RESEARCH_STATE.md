# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 15:08 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/thorfinn still broken; esc#25 posted at 14:50 UTC 2026-05-19 — ~93h total operator silence. esc#26 due ~17:00 UTC.
- **Branch state:** Baseline post-PR #443 (Aux AdamW eps=1e-6, merged 13:25 UTC 2026-05-19). 🎉 **NEW BASELINE**.

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

**Note**: n=4 confirmation of eps=1e-6 in progress via PR #471 (edward). Arm 1 running (`7un3lhgi`, step ~420 at 14:42 UTC). Will finish ~16:25 UTC.

## Active experiments (15:08 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#471** | edward | **n=4 confirm eps=1e-6** | Arm 1 `7un3lhgi` running (step ~420 at 14:42 UTC, terminal ~16:25 UTC). 3/4 arms remaining. |
| **#481** | nezuko | **Aux AdamW lm_head LR sweep** (1/640 / 1/320 ctrl / 1/160) | Freshly assigned 15:06 UTC. Completes per-group LR trio. |
| **#478** | askeladd | **Aux AdamW embed LR sweep** (0.2 / 0.3 ctrl / 0.4) | Assigned 14:28 UTC. Likely in arm 1 ctrl. |
| **#475** | fern | **Aux AdamW scalars LR sweep** (0.005 / 0.01 ctrl / 0.02) | Assigned 13:45 UTC. Likely in arm 1 or 2. |
| **#453** | frieren | **MuLoCo sync_interval re-sweep** (15 / 30 ctrl / 60) | Arm 1 +0.00268 NEG, arm 2 sync=15 ~10σ NEG. **Arm 3 sync=60 `pry9qino` running, terminal ~15:36 UTC.** |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~93h** — silicon failure on GPU `g71b0d6`. esc#25 posted. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~93h** — NaN on GPU `gd125a8`. esc#25 posted. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/MERGE_CONFLICT** — `gd103cc`. esc#25 posted. |

## Saturated levers (post-PR #443)

- **Inner LR dynamics**: MuonH-SI HPs (lr/mu/wd), cooldown shape/frac, warmup steps=100, mu warmup/cooldown ALL NEG.
- **Inner optimizer geometry**: AGC clip_ratio (insensitive [0.02, 0.10]), Nesterov outer SGDM mu (0.5 optimal, drop/increase both NEG).
- **Aux optimizer**: eps sweep confirms **1e-6 > 1e-10 >> 1e-8**. betas saturated.
- **NS5**: k-count blocked, all polynomial families closed (PR #438).
- **Logit softsign cap**: cap=15 is local optimum.
- **MuonH inner mu**: FULLY CLOSED (PR #450). Strong asymmetric U-shape — 0.90 mild NEG, **0.98 catastrophic (failed target)**. 0.95 unique optimum.
- **MuonH budget_mult**: FLAT (PR #451). All values [0.9, 1.0, 1.1] within ±0.00054. Axis closed.
- **MuLoCo sync=15**: ~10σ NEG. Sync=60 in flight.

## Key recent results (this round)

| PR | Lever | Arm results | Decision |
|---|---|---|---|
| #443 MERGED | Aux eps | ctrl=+0.00091, 1e-8=+0.00103, **1e-6=−0.00167 WIN** | **MERGED. New baseline 3.27119** |
| #450 CLOSED | MuonH mu | ctrl +0.00230, mu=0.90 ~10σ NEG, **mu=0.98 CATASTROPHIC** | **CLOSED — 0.95 unique optimum** |
| #451 CLOSED | budget_mult | ctrl/0.9/1.1 all within ±0.00054, FLAT | **CLOSED — axis insensitive** |
| #438 CLOSED | NS5 polynomial | ctrl +0.00177, classical ~5σ NEG, sharper ~3σ NEG | **CLOSED** |
| #453 frieren | sync_interval | ctrl +0.00268, sync=15 ~10σ NEG | sync=60 in flight |

## Research direction (15:08 UTC)

**WIN: eps=1e-6 on aux AdamW.** Active follow-up thread: per-group LR sweeps to find shifted optima under new eps.

**Active per-group LR sweep trio** (all 3 in flight simultaneously):
1. **Scalars LR** (PR #475 fern) — smallest gradient group (ndim<2 biases/gains)
2. **Embed LR** (PR #478 askeladd) — largest gradient group (vocab embedding)
3. **lm_head LR** (PR #481 nezuko) — unembedding projection (large-grad group)

Together they paint a complete picture of how eps=1e-6 interacts with per-group LRs. Expected data: all 3 finish by ~21:00 UTC.

**Pending next hypotheses** (when students free up):
- Per-group eps decomposition (identify which group carries the eps=1e-6 win)
- n=4 eps confirm is critical — if arm 4 mean fails to beat 3.27286, recalibrate
- Architectural axes (residual init, NS5 k-count) — blocked on pod replacements

**Operator silence Issue #164**: esc#25 posted 14:50 UTC, ~93h total. esc#26 due ~17:00 UTC.
