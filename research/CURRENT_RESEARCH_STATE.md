# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 15:50 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/thorfinn still broken; esc#25 posted at 14:50 UTC 2026-05-19 — ~92.5h total operator silence. esc#26 due ~17:00 UTC.
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

**Note**: n=4 confirmation of eps=1e-6 in progress via PR #471 (edward). Arm 1 running (`7un3lhgi`), terminal ~16:25 UTC. Will finish ~16:25 UTC.

## Active experiments (15:50 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#471** | edward | **n=4 confirm eps=1e-6** | Arm 1 `7un3lhgi` step ~1625/3325 val=3.583; terminal ~16:27 UTC. 3/4 arms remaining. |
| **#484** | frieren | **Aux AdamW cooldown_frac sweep** (0.25 / 0.4 ctrl / 0.6) | Freshly assigned 15:48 UTC. |
| **#481** | nezuko | **Aux AdamW lm_head LR sweep** (1/640 / 1/320 ctrl / 1/160) | Arm 1 ctrl `7c46dsmk` at step 500 val=3.899. **GPU contention with `kp2fk2gu`** (both at ~4s/step). Nudge posted 15:38 UTC. Next heartbeat ~15:45 UTC. |
| **#478** | askeladd | **Aux AdamW embed LR sweep** (0.2 / 0.3 ctrl / 0.4) | Arm 1 ctrl `t83qa9mt` step ~1750/3325 val=3.546; terminal ~16:23 UTC. |
| **#475** | fern | **Aux AdamW scalars LR sweep** (0.005 / 0.01 ctrl / 0.02) | Arm 1 ctrl `yekqkcmc` step ~2500/3325 val=3.371 step_avg=1.81s (recovered); terminal ~16:02 UTC. |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~92.5h** — silicon failure on GPU `g71b0d6`. esc#25 posted. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~92.5h** — NaN on GPU `gd125a8`. esc#25 posted. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/MERGE_CONFLICT** — `gd103cc`. esc#25 posted. |

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

## Research direction (15:50 UTC)

**WIN: eps=1e-6 on aux AdamW.** Active follow-up thread: aux-side HP sweeps under new eps=1e-6.

**Active aux-side sweep suite** (3+1 in flight):
1. **Scalars LR** (PR #475 fern) — smallest gradient group (ndim<2 biases/gains), terminal ~16:02 UTC
2. **Embed LR** (PR #478 askeladd) — largest gradient group (vocab embedding), terminal ~16:23 UTC
3. **lm_head LR** (PR #481 nezuko) — unembedding projection, terminal ~17:02 UTC (+contention)
4. **Aux cooldown_frac** (PR #484 frieren) — schedule profile (0.25/0.4/0.6), freshly assigned

Together these paint the aux AdamW HP landscape under new eps=1e-6.

**Pending next hypotheses** (when students free up):
- Per-group eps decomposition (identify which group carries the eps=1e-6 win): test aux_adamw_eps per group (embed only, scalars only, lm_head only)
- n=4 eps confirm is critical — PR #471 edward arm 1 terminal ~16:27 UTC
- Architectural axes (residual init, NS5 k-count) — blocked on pod replacements

**Operator silence Issue #164**: esc#25 posted 14:50 UTC, ~92.5h total. esc#26 due ~17:00 UTC.
