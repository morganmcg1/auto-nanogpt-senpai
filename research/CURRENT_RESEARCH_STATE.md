# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 17:00 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/thorfinn still broken; **esc#26 posted at 16:58 UTC 2026-05-19** — ~93.5h total operator silence. esc#27 due ~19:00 UTC.
- **Branch state:** Baseline post-PR #443 (Aux AdamW eps=1e-6, merged 13:25 UTC 2026-05-19). 🎉 **NEW BASELINE**.
- **Confirmation status:** edward PR #471 arm 1 just terminal → val=**3.27129** (Δ=+0.00010 vs 3.27119). **eps=1e-6 win replicates within seed noise.** 3 arms remaining (n=4 chain).

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

## Active experiments (17:00 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#471** | edward | **n=4 confirm eps=1e-6** | Arm 1 `7un3lhgi` TERMINAL **val=3.27129 Δ=+0.00010** ffs=3125. **Arm 2 `nyci0k7j` step 750/3325**, terminal ~18:18 UTC. |
| **#478** | askeladd | **Aux AdamW embed LR sweep** (0.2 / 0.3 ctrl / 0.4) | Arm 1 ctrl `t83qa9mt` TERMINAL **val=3.27399 Δ=+0.00280** ffs=3150. **Arm 2 `slkz2y5h` step 875/3325**, terminal ~18:18 UTC. |
| **#484** | frieren | **Aux AdamW cooldown_frac sweep** (0.25 / 0.4 ctrl / 0.6) | Arm 1 ctrl `e45o2hzp` step 1750/3325 val=3.544; terminal ~17:46 UTC. |
| **#481** | nezuko | **Aux AdamW lm_head LR sweep** (1/640 / 1/320 ctrl / 1/160) | Arm 1 ctrl `7c46dsmk` step 2750/3325 val=3.322 (contention resolved 15:51); terminal ~17:15 UTC. |
| **#475** | fern | **Aux AdamW scalars LR sweep** (0.005 / 0.01 ctrl / 0.02) | Arm 1 ctrl `yekqkcmc` TERMINAL **val=3.27296 Δ=+0.00177** ffs=3150. **Arm 2 `2tasvk8f` step 1625/3325 val=3.59**; terminal ~17:50 UTC. |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~93.5h** — silicon failure on GPU `g71b0d6`. esc#26 posted 16:58. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~93.5h** — NaN on GPU `gd125a8`. esc#26 posted 16:58. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/MERGE_CONFLICT** — `gd103cc`. esc#26 posted 16:58. |

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

**Ctrl arm noise observed**: fern ctrl Δ=+0.00177, askeladd ctrl Δ=+0.00280, edward arm 1 Δ=+0.00010. Trial-to-trial σ ≈ 0.001-0.0028 — wider than naive σ~0.0008. The eps=1e-6 win at -0.00167 sits right at the lower edge of this noise band; n=4 confirmation is essential to disambiguate.

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
