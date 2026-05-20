# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-20 01:35 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/thorfinn still broken; **escalations through esc#28 (22:57 UTC 2026-05-19)** — ~99h total operator silence. esc#29 due ~03:00 UTC 2026-05-20.
- **Branch state:** Baseline post-PR #443 (Aux AdamW eps=1e-6, merged 13:25 UTC 2026-05-19). 🎉 **CURRENT BASELINE**.
- **🟢 ACTIVE WIN DIRECTION:** askeladd PR #478 embed_lr monotone improvement 0.2→0.3→0.4 = 3.27527→3.27399→**3.27213**. n=4 confirmation chain at embed_lr=0.4 running (arms 02:10/03:55/05:40/07:25).
- **🆕 KEY MECHANISTIC FINDING (PR #510 CLOSED 01:30 UTC):** Unfused optimizer path produces NaN at step-3 forward under the current aux stack (eps=1e-6 + AGC + per-group LR). Plain `AdamW(fused=False)` shows identical failure. **Implication**: any aux optimizer without a fused kernel (NAdam, AdaBelief unfused, AdaFactor) is BLOCKED. Lookahead/Lion/SWA wrappers around fused AdamW are SAFE.

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
| Aux AdamW | betas=(0.8, 0.95), **eps=1e-6**, AGC clip_ratio=0.05, weight_decay=0, **fused=True** |
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

**🆕 CRITICAL — Aux optimizer must use fused kernel.** Unfused path produces NaN at step 3 forward (confirmed via PR #510 diagnostic). Any new aux optimizer assignment must verify a fused implementation or wrap fused AdamW (Lookahead/SWA-style).

## Active experiments (01:35 UTC 2026-05-20)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#525** | frieren | **H2: Lookahead aux wrapper** (k=5; α=0.5 vs 0.8) | **NEWLY ASSIGNED 01:34 UTC** — ctrl + 2 mechanism arms |
| **#512** | edward | **H6: Aux v_t reset at cooldown onset** (`reset_frac`=1.0/0.5/0.1) | Arm 1 ctrl (1.0) done 3.27280; arm 2 running |
| **#478** | askeladd | **embed LR n=4 confirmation @ 0.4** | n=4 chain running. arm 1 ETA 02:10, arm 4 ETA 07:25 |
| **#501** | fern | **per-group eps decomp** (3 arms) | Arm 1 ctrl 3.27393, Arm 2 (embed→1e-10) **3.27280 (BETTER)**, Arm 3 (inverse) running ETA ~01:35 |
| **#507** | nezuko | **embed init std** (1.0/0.1/0.02) | ctrl running, arms 2/3 chained |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~99h** — GPU `g71b0d6`. esc#29 due ~03:00. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~99h** — NaN on GPU `gd125a8`. esc#29 due ~03:00. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/MERGE_CONFLICT** — `gd103cc`. esc#29 due ~03:00. |

## Recently closed PRs

- **PR #510 frieren NAdam (CLOSED 01:30 UTC 2026-05-20)** — Arm 1 ctrl 3.27222 (Δ+0.00103). NAdam arm NaN at step 3 forward. Diagnostic `AdamW(fused=False)` ALSO NaN at step 3 — same step-2 forward divergence. Mechanistic conclusion: unfused optimizer path incompatible with eps=1e-6 + AGC + per-group LR aux stack. Closed per decision tree; finding logged as global constraint.
- **PR #471 edward n=4 eps=1e-6 confirm (CLOSED 22:02 UTC 2026-05-19)** — n=4 mean 3.27218 (vs old baseline 3.27286, Δ−0.00068). Effect real but small. PR #443 n=1 was favorable-seed outlier. Conservative n=4 bar (<3.27079) NOT cleared.
- **PR #481 nezuko lm_head LR sweep (CLOSED ~20:40 UTC 2026-05-19)** — flat at 1/320.

## Key pattern: aux per-group LR sweeps (ACTIVE WIN DIRECTION)

- **scalars LR** (PR #475 CLOSED): saturated at 0.01.
- **embed LR** (PR #478 n=4 confirmation @ 0.4): 0.2→0.3→0.4 = 3.27527→3.27399→**3.27213** (Δ−0.00186 vs ctrl). Peak at 0.4 per single-arm sweep at 0.45/0.5.
- **lm_head LR** (PR #481 CLOSED): flat at 1/320 under eps=1e-6.
- **cooldown_frac** (PR #484 CLOSED): flat at 0.4.

## Per-group eps decomp emerging signal (PR #501 fern)

- **Arm 1 ctrl (all 1e-6)**: 3.27393
- **Arm 2 (embed=1e-10, lm_head+scalars=1e-6)**: **3.27280** (Δ−0.00113 vs ctrl)
- **Arm 3 (embed=1e-6, lm_head+scalars=1e-10)**: terminal ETA ~01:35 UTC

**Interpretation if arm 3 ≫ arm 2**: eps=1e-6 win lives in lm_head/scalars, NOT embed. This would be a follow-up axis worth a dedicated sweep on lm_head and scalars eps.

## Saturated levers (post-PR #443)

- **Inner LR dynamics**: MuonH-SI HPs (lr/mu/wd), cooldown shape/frac, warmup steps=100, mu warmup/cooldown ALL NEG.
- **Inner optimizer geometry**: AGC clip_ratio (insensitive [0.02, 0.10]), Nesterov outer SGDM mu (0.5 optimal).
- **Aux optimizer**: eps sweep confirms **1e-6 > 1e-10 >> 1e-8**. betas saturated. **NAdam blocked** (unfused path NaN). **Unfused AdamW also blocked** (same failure mode).
- **NS5**: k-count blocked (alphonse pod), all polynomial families closed (PR #438).
- **Logit softsign cap**: cap=15 is local optimum.
- **MuonH inner mu**: FULLY CLOSED (PR #450). 0.95 unique optimum.
- **MuonH budget_mult**: FLAT (PR #451). Axis closed.
- **MuLoCo ALL KNOBS**: sync_interval CLOSED (PR #453). outer_lr=0.7 CLOSED (PR #369). outer_momentum=0.5 CLOSED. Lever fully exhausted.

## Hypothesis bank (pending assignment when students free up)

| H# | Hypothesis | Notes / fused-path safety |
|---|---|---|
| H1 | Per-group eps decomp | PR #501 fern ACTIVE — emerging signal: embed NOT the carrier |
| H2 | Lookahead outer wrapper on aux | **PR #525 frieren ACTIVE** (safe: wraps fused) |
| H3 | SWA averaging over aux params at cooldown | Pending. Safe (post-update averaging). |
| H4 | Nesterov AdamW (NAdam) | **CLOSED PR #510 — unfused path NaN.** |
| H5 | Embed init std sweep | PR #507 nezuko ACTIVE |
| H6 | Decoupled second-moment reset at cooldown | PR #512 edward ACTIVE (arm 1 ctrl 3.27280, arms 2/3 chained) |
| H7 | Per-group weight decay re-sweep under eps=1e-6 | Pending. Safe. |
| H8 | AdaBelief for aux | **BLOCKED unless fused implementation available.** |
| H9 | AdamW beta1/beta2 re-sweep under eps=1e-6 | Pending. Safe (still fused AdamW). |
| H10 | Lion (sign-based) for aux | Pending. Safe (bounded magnitude, fused or unfused). |
| H11 | Schedule-Free AdamW | Pending. Needs verification (depends on SF wrapper internals). |
| H12 | Per-group LR sweep on lm_head/scalars (informed by PR #501) | Pending until PR #501 arm 3 terminates. |

## Research direction (01:35 UTC)

**Primary active win directions:**
1. 🟢 **higher embed_lr** (PR #478 askeladd) — peak at 0.4; n=4 confirmation chain running. Highest-confidence win candidate.
2. **Per-group eps decomp** (PR #501 fern) — emerging signal: embed at 1e-10 may be preferred. Arm 3 will confirm where the win lives. Suggests H12 follow-up (per-group LR sweep on lm_head/scalars).
3. **Embed init std** (PR #507 nezuko) — std=1.0 is unusually large vs GPT-2 std=0.02.
4. **v_t reset at cooldown** (PR #512 edward) — partial second-moment reset; arms 2/3 chained.
5. **Lookahead aux wrapper** (PR #525 frieren) — H2 outer wrapper symmetric to MuLoCo.

**Ctrl arm noise** (7 ctrl-equivalent samples): mean Δ = +0.00169, sd ≈ 0.00115. All positive — baseline `t1coza71` is a favorable-seed outlier. Any win must clear +0.0008 vs 3.27119 to be above noise.

**Operator silence Issue #164**: ~99h total, esc#28 posted 22:57 UTC, esc#29 due ~03:00 UTC.
