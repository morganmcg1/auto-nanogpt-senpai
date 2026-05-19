# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 22:10 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/thorfinn still broken; **escalations through esc#27 (18:27 UTC) + duplicate-numbered #25 (20:21 UTC)** — ~98.5h total operator silence. esc#28 due ~22:30 UTC.
- **Branch state:** Baseline post-PR #443 (Aux AdamW eps=1e-6, merged 13:25 UTC 2026-05-19). 🎉 **CURRENT BASELINE**.
- **edward n=4 confirmation (PR #471 CLOSED 22:02 UTC):** n=4 mean=**3.27218** (vs new baseline 3.27119, +0.00099; vs old baseline 3.27286, **−0.00068** below). eps=1e-6 effect confirmed-real-but-small. PR #443 n=1 win was a favorable-seed outlier. Conservative n=4 bar (<3.27079) NOT cleared.
- **🟢 ACTIVE WIN DIRECTION:** askeladd PR #478 embed_lr monotone improvement 0.2→0.3→0.4 = 3.27527→3.27399→**3.27213**. Extension arms 4/5/6 (0.5/0.6/0.7) running. Peak likely at 0.5–0.6.

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

## Active experiments (22:10 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#512** | edward | **H6: Aux v_t reset at cooldown onset** (`reset_frac`=1.0/0.5/0.1) | **NEWLY ASSIGNED 22:10 UTC** — ctrl + 2 mechanistic arms |
| **#510** | frieren | **Aux NAdam (Nesterov AdamW)** | Assigned 21:55 UTC — 3 arms: AdamW ctrl / NAdam decay=0 / NAdam decay=0.004 |
| **#478** | askeladd | **embed LR extension** (0.5/0.6/0.7) | Arm 4 (0.5) running. Arms 5/6 chained. |
| **#501** | fern | **per-group eps decomp** (3 arms) | ctrl running, chain continues |
| **#507** | nezuko | **embed init std** (1.0/0.1/0.02) | ctrl running, arms 2/3 chained |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~98.5h** — GPU `g71b0d6`. esc#28 due ~22:30. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~98.5h** — NaN on GPU `gd125a8`. esc#28 due ~22:30. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/MERGE_CONFLICT** — `gd103cc`. esc#28 due ~22:30. |

## Key pattern: aux per-group LR sweeps (ACTIVE WIN DIRECTION)

- **scalars LR** (PR #475 CLOSED): saturated at 0.01.
- **embed LR** (PR #478 ACTIVE extension): 0.2→0.3→0.4 monotone WIN (−0.00186 vs ctrl). 🟢 Peak likely at 0.5–0.6.
- **lm_head LR** (PR #481 CLOSED): flat at 1/320 under eps=1e-6.
- **cooldown_frac** (PR #484 CLOSED): flat at 0.4.

## Saturated levers (post-PR #443)

- **Inner LR dynamics**: MuonH-SI HPs (lr/mu/wd), cooldown shape/frac, warmup steps=100, mu warmup/cooldown ALL NEG.
- **Inner optimizer geometry**: AGC clip_ratio (insensitive [0.02, 0.10]), Nesterov outer SGDM mu (0.5 optimal).
- **Aux optimizer**: eps sweep confirms **1e-6 > 1e-10 >> 1e-8**. betas saturated.
- **NS5**: k-count blocked (alphonse pod), all polynomial families closed (PR #438).
- **Logit softsign cap**: cap=15 is local optimum.
- **MuonH inner mu**: FULLY CLOSED (PR #450). 0.95 unique optimum.
- **MuonH budget_mult**: FLAT (PR #451). Axis closed.
- **MuLoCo ALL KNOBS**: sync_interval CLOSED (PR #453) — sync=30 optimal. outer_lr=0.7 CLOSED (PR #369). outer_momentum=0.5 CLOSED. Lever fully exhausted.

## Hypothesis bank (pending assignment when students free up)

| H# | Hypothesis | Notes |
|---|---|---|
| H1 | Per-group eps decomp | PR #501 fern ACTIVE |
| H2 | Lookahead outer wrapper on aux | Pending |
| H3 | SWA averaging over aux params at cooldown | Pending |
| H4 | Nesterov AdamW (NAdam) | PR #510 frieren ACTIVE |
| H5 | Embed init std sweep | PR #507 nezuko ACTIVE |
| H6 | Decoupled second-moment reset at cooldown | PR #512 edward ACTIVE |
| H7 | Per-group weight decay re-sweep under eps=1e-6 | Pending |
| H8 | AdaBelief for aux (gradient-adapted second moment) | Pending |
| H9 | AdamW beta1/beta2 re-sweep under eps=1e-6 | axes were screened under old eps=1e-10 stack |

## Research direction (22:10 UTC)

**Primary active win directions:**
1. 🟢 **higher embed_lr** (PR #478 askeladd) — monotone −0.0015/+0.1 gradient. Extension arms 4/5/6 running at 0.5/0.6/0.7.
2. **Per-group eps decomp** (PR #501 fern) — tests whether eps=1e-6 win is driven by one specific aux group.
3. **Embed init std** (PR #507 nezuko) — std=1.0 is unusually large vs GPT-2 std=0.02; std reduction may improve early convergence.
4. **NAdam aux** (PR #510 frieren) — mechanism test: Nesterov-style first-moment in aux AdamW consistent with Nesterov in MuonH/MuLoCo.
5. **v_t reset at cooldown** (PR #512 edward) — partial second-moment reset at aux cooldown onset, re-invigorating adaptive step size at LR decay.

**Ctrl arm noise** (7 ctrl-equivalent samples): mean Δ = +0.00169, sd ≈ 0.00115. All positive — baseline `t1coza71` is a favorable-seed outlier. Any win must clear +0.0008 vs 3.27119 to be above noise.

**Operator silence Issue #164**: ~98.5h total, esc#28 due ~22:30 UTC.
