# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 13:45 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/thorfinn still broken; esc#24 posted at 12:47 UTC 2026-05-19 — ~91h total operator silence. esc#25 due ~14:50 UTC.
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
| Aux AdamW scalars LR | 0.01 (never swept, now being tested via PR #475) |
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

**Note**: n=4 confirmation of eps=1e-6 in progress via PR #471 (edward). If n=4 mean fails to beat 3.27286 (the prior n=4 baseline), this win may be an outlier seed. Watch carefully.

## Active experiments (13:45 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#471** | edward | **n=4 confirm eps=1e-6** | Assigned 13:30 UTC. Student should pick up shortly. |
| **#475** | fern | **Aux AdamW scalars LR sweep** (0.005 / 0.01 ctrl / 0.02) | Freshly assigned 13:45 UTC. |
| **#453** | frieren | **MuLoCo sync_interval re-sweep** (15 / 30 ctrl / 60) | Arm 1 ctrl done (val=3.27387). **Arm 2 sync=15 `ri1dkfwa` running, past terminal ETA ~13:35 UTC — no SENPAI-RESULT yet, likely close.** |
| **#450** | askeladd | **MuonH inner static mu sweep** (0.90 / 0.95 ctrl / 0.98) | Arm 1 ctrl +0.00063, arm 2 mu=0.90 ~7σ NEG. **Arm 3 mu=0.98 in flight, terminal ~14:15 UTC.** |
| **#451** | nezuko | **MuonH budget_mult sweep** (0.9 / 1.0 ctrl / 1.1) | Arm 1 ctrl +0.00090, arm 2 bm=0.90 ~2σ NEG. **Arm 3 bm=1.1 `65k2dls4` in flight, terminal ~15:00 UTC.** |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~91h** — silicon failure on GPU `g71b0d6`. esc#24 posted. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~91h** — NaN on GPU `gd125a8`. esc#24 posted. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/MERGE_CONFLICT** — `gd103cc`. esc#24 posted. |

## Saturated levers (post-PR #443)

- **Inner LR dynamics**: MuonH-SI HPs (lr/mu/wd), cooldown shape/frac, warmup steps=100, mu warmup/cooldown ALL NEG.
- **Inner optimizer geometry**: AGC clip_ratio (insensitive [0.02, 0.10]), Nesterov outer SGDM mu (0.5 optimal, drop/increase both NEG).
- **Aux optimizer**: eps sweep confirms **1e-6 > 1e-10 >> 1e-8** (surprisingly, 1e-8 not better than ctrl). betas saturated.
- **NS5**: k-count blocked, classical Halley ~3σ NEG, sharper polynomial ~3σ NEG, all polynomial families closed (PR #438 closed).
- **Logit softsign cap**: cap=15 is local optimum.
- **MuonH inner mu**: lower (0.90) ~7σ NEG. Higher (0.98) in progress.
- **MuonH budget_mult**: lower (0.90) ~2σ NEG baseline-equiv. Higher (1.1) in progress.

## Key recent results (this round)

| PR | Lever | Arm results | Decision |
|---|---|---|---|
| #443 MERGED | Aux eps | ctrl=+0.00091, 1e-8=+0.00103, **1e-6=−0.00167 WIN** | **MERGED. New baseline 3.27119** |
| #438 CLOSED | NS5 polynomial | ctrl +0.00010, classical ~3σ NEG, sharper ~1σ NEG | **CLOSED — lever saturated** |
| #450 askeladd | MuonH mu | ctrl +0.00063, mu=0.90 ~7σ NEG | mu=0.98 in flight |
| #451 nezuko | budget_mult | ctrl +0.00090, bm=0.90 ~2σ NEG | bm=1.1 in flight |
| #453 frieren | sync_interval | ctrl +0.00101 | sync=15 in flight (just past terminal) |

## Research direction (13:45 UTC)

**WIN: eps=1e-6 on aux AdamW unexpectedly helped.** This opens an auxiliary optimizer parameter exploration angle. The denominator floor on aux AdamW matters because embed/lm_head/scalars have diverse gradient scales — a larger eps stabilizes the adaptive LR for the small-gradient parameters.

**Current active thread**: auxiliary optimizer parameter tuning. The eps=1e-6 win changed the effective per-step magnitude for low-gradient parameters (scalars most affected). Adjacent questions:

1. **Scalars LR re-sweep** (PR #475 fern) — under eps=1e-6, scalar effective step is smaller (floored denom). Optimal LR has likely shifted. Testing 0.005/0.01/0.02.
2. **n=4 confirm eps=1e-6** (PR #471 edward) — CRITICAL to validate the n=1 win. If fails, scalars LR thread collapses too.
3. **MuLoCo sync_interval** (PR #453 frieren in progress) — sync=15 terminal imminent.
4. **MuonH inner mu=0.98** (askeladd arm 3) — whether upper bound is useful (~14:15 UTC).
5. **MuonH budget_mult=1.1** (nezuko arm 3) — whether larger hyperball helps (~15:00 UTC).

**Pending next hypotheses** (when more students become available):
- Aux AdamW per-group eps (per-group eps decomposition to validate eps=1e-6 mechanism)
- Embed/lm_head LR sweep (if scalars LR sweep is informative)
- Architectural axes (residual init, NS5 k-count) — blocked on pod replacements

**Operator silence Issue #164**: esc#24 posted 12:47 UTC, ~91h total. esc#25 due ~14:50 UTC.
