# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 00:55 UTC (boot 143x — edward arm 3 mu_warmup=200 NEG Δ=+0.00394, frieren AdamW catastrophic NEG Δ=+0.08388, thorfinn #412 blocked on plumbing bug)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse (`gd103cc`) + tanjiro (`gd125a8`) still broken. Issue #164 esc#18 posted 00:50 UTC. Operator silent ~77h+ (esc#19 due ~03:30 UTC).
- **Branch state:** Baseline post-PR #329 (AGC inner MuonH clip=0.05, merged 18:26 UTC).

## ⭐ Current baseline (post-PR #329 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27286** (n=4 mean; trials: 3.27209/3.27264/3.27365/3.27305) |
| `ffs` (primary) | **3125** (best); mean 3137.5 |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| **MuonH inner AGC** | **`--muonh_agc_clip_ratio 0.05`** ← NEW |
| MuonH LR warmup | warmup_steps=100, shape=linear |
| Outer wrapper | MuLoCo (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| Aux AdamW | betas=(0.8, 0.95), eps=1e-10, AGC clip_ratio=0.05 |
| Cooldown | MuonH=cosine frac=1.0, aux=linear frac=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| Logit cap | softsign at ±15 (hardcoded) |
| W&B confirm | `dpabql6o` (n=4 multi-trial) |

**Merge bar**: μ_val < 3.27286 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004.
- **n=1 promotion bar**: val < **3.27206** (Δ ≤ −0.0008 vs 3.27286)
- **Conservative n=4 bar**: μ < **3.27246**

**⚠️ CRITICAL — ALL new experiment commands must include:**
```
--aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --muonh_cooldown_shape cosine --muonh_warmup_steps 100
```

## Active experiments (00:55 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#397** | nezuko | **Aux lm_head weight decay sweep** (wd=0/0.01/0.05 on lm_head only) | Arm 1 ctrl `y7q4vanw` val=3.27281 (Δ=−0.00005); **Arm 2 wd=0.01 `p9csxg1v` val=3.27540 (Δ=+0.00254, 5σ NEG)**; Arm 3 wd=0.05 `0to00mja` step ~2050 — ETA ~01:25 UTC. |
| **#396** | askeladd | **QK-Norm sweep** (off/fixed/learnable RMSNorm on Q+K) | Arm 1 off `o20httom` val=3.29716 (Δ=+0.02430 NEG); **Arm 2 fixed `xwml6u2c` val=3.27393 (Δ=+0.00107 ~baseline)**; Arm 3 learnable `53f944z1` step ~1550 — ETA ~01:40 UTC. |
| **#389** | edward | **MuonH inner mu warmup** (mu_warmup_steps 0/100/200) | **ALL ARMS TERMINAL.** Arm 1 ctrl val=3.27264; Arm 2 val=3.27506 (Δ=+0.00220); **Arm 3 mu_warmup=200 `m8agfmr2` val=3.27680 (Δ=+0.00394).** Monotonic regression. **Awaiting SENPAI-RESULT marker, will close NEG.** |
| **#390** | frieren | **MuLoCo outer optimizer class** (SGDM/AdamW/Lion) | Arm 1 SGDM ctrl `jgltipi3` val=3.27392 (Δ=+0.00106 ~baseline); **Arm 2 AdamW `6znrpsli` val=3.35674 (Δ=+0.08388, CATASTROPHIC NEG ~100σ)**; Arm 3 Lion `3jywc3d4` step 825 val 5.297 — ETA ~01:40 UTC, likely catastrophic too. |
| **#391** | thorfinn | **MuonH warmup duration** (100/200/300 steps) | **CLOSED NEG.** Arm 1 warmup=100 reproduces baseline; arms 2+3 deterministic NaN at step 125 across 4 retries each. **warmup=100 is stable maximum.** |
| **#412** | thorfinn | **Aux AdamW warmup duration** (0/100/200 steps) — addresses thorfinn's mechanism finding | **PLUMBING BUG.** Arm 1 control (aux_warmup_steps=0, should be no-op) `i4mhhehj` NaN at step 125 — same cascade signature as #391. 3 candidate bugs flagged (elif placement, divide-by-zero default, opt swap). Held for student debugging (kill instruction follow-up posted 00:48 UTC). |
| **#392** | fern | **Softsign logit cap value** (cap=10/15/30) | Smoke clean; cap=15 control `6hideyt9` step 775 val 3.820 — ETA terminal ~01:30 UTC. cap=10/cap=30 arms auto-chained. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED 77h+** — `gd125a8` bf16 NaN, no operator rotation. |
| **#190** | alphonse | **NS5 iter count sweep** | **POD-BLOCKED 77h+** — needs_rebase, `gd103cc`, no operator rotation. |

**8/8 students assigned.** Two PRs awaiting student SENPAI-RESULT close-out (#389 edward, #391 thorfinn). One PR held for plumbing fix (#412 thorfinn).

## MERGED this round (chronological)

| PR | Student | Result |
|---|---|---|
| **#114** | frieren | MuLoCo × MuonH-SI MERGED — val=3.27585 (n=4) |
| **#237** | edward | AGC aux clip=0.05 MERGED — val=3.27469 (n=4) |
| **#243** | frieren | MuonH-SI cosine cooldown MERGED — val=3.27415 (n=4) |
| **#310** | thorfinn | MuonH inner LR warmup=100 MERGED — val=3.27315 (n=4) |
| **#329** | askeladd | **AGC inner MuonH clip=0.05 MERGED** — val=**3.27286** (n=4). **Current baseline.** |

**Total improvement since start**: 3.27585 → 3.27286 = **−0.00299** over 5 merged PRs.

## Closed this round (NEG summary)

23 PRs closed NEG this boot. Key recent closures:
- #352 fern cooldown_frac, #365 frieren sync_interval scheduling, #369 edward outer_lr schedule, #370 thorfinn warmup shape (all wave-3, closed 17:10 UTC)
- #361 nezuko aux lm_head LR (arms 1+2 fail new bar 3.27206; arm 3 terminal 3.27415 NEG; closed 18:42 UTC)
  - Mechanism: aux lm_head LR is flat in [1/320, 1/200], degrading below; PR #329 baseline tightening absorbed arms 1+2 apparent signal that was n=1 noise on old baseline

## Saturated levers

- MuonH-SI HPs (lr/mu/wd), cooldown shape, LR warmup step-count (100 optimal), warmup shape (insensitive)
- MuLoCo outer params (0.7/0.5/30 all saturated); scheduled variants all NEG; outer class swap in test (#390)
- Aux optimizer (Lion/AdEMAMix NEG); aux betas, embed lr_mult, cooldown shape, frac, LR warmup — all saturated
- NS5 polynomial (12-iter optimal); fp32 closed; k-count blocked
- Gradient centralization NEG; schedule-free NEG; depth-LR NEG; lookahead NEG

## Research direction (post wave-3 closures + #329 merge + #361 NEG closure)

**Escalating toward architecture after optimizer plateau.** 5 merges total, last 4 in optimizer space. Now testing:
1. **Architectural** (#396 askeladd QK-Norm, #392 fern logit-cap value, #298 tanjiro residual init [blocked])
2. **Optimizer class** (#390 frieren outer SGDM/AdamW/Lion)
3. **Warmup extension** (#391 thorfinn 100/200/300 steps)
4. **Inner optimizer** (#389 edward mu warmup)
5. **Param-group regularization** (#397 nezuko lm_head weight decay) ← NEW 18:43 UTC

## Active win pipeline

No pending n=4 confirms. All current screens are 1-trial arms. No arm so far has passed n=1 promotion bar (<3.27206).

**Arm-1 ctrl reproductions** validated baseline within ±0.0011: thorfinn +0.00039, nezuko −0.00005, edward −0.00022, frieren SGDM +0.00106, askeladd fixed +0.00107. **Estimated σ ≈ 0.0006–0.0008.**

**Arm-2/3 wave summary (00:55 UTC):**
- ❌ thorfinn warmup=200/300 (#391): deterministic NaN — closed NEG (mechanism documented)
- ❌ edward mu_warmup=100/200 (#389): monotonic regression Δ=+0.00220 → +0.00394 — **all terminal, awaiting SENPAI-RESULT marker**
- ❌ nezuko wd=0.01 (#397): Δ=+0.00254 (5σ NEG); arm 3 wd=0.05 step ~2050
- ❌ frieren AdamW (#390): Δ=+0.08388 CATASTROPHIC ~100σ; Lion arm running at val 5.297 step 825 (likely catastrophic too)
- 🟰 askeladd fixed ctrl (#396): Δ=+0.00107; arm 3 learnable running
- 🟰 fern cap=15 ctrl (#392): step 775 val 3.820 on baseline pace

**Next terminal wave (all ~01:25–01:45 UTC):**
- nezuko arm 3 wd=0.05 (`0to00mja`)
- fern cap=15 control (`6hideyt9`) → cap=10/cap=30 auto-chain
- frieren Lion (`3jywc3d4`)
- askeladd arm 3 learnable (`53f944z1`)

**Held**: #412 thorfinn aux-warmup plumbing bug — arm 1 ctrl NaN at step 125 (same signature as #391 cascade) despite aux_warmup_steps=0 being intended as no-op. Kill follow-up posted 00:48 UTC.

**Cross-PR mechanism finding (thorfinn 22:56 UTC):** Aux AdamW (embed/lm_head/scalars at lr=0.30 from step 1) drives the early-step stability budget. MuonH-SI inner LR warmup_steps=100 is at the cliff — longer warmup → aux outruns inner → NaN cascade before AGC engages → AGC silently passes NaN. Implications: (a) **aux warmup may be a real new lever** (currently testing via PR #412 once bug fixed), (b) AGC hardening (NaN-safe clip) is a future stability lever.

**Reading from the wave**: 5+ levers all flat-or-NEG vs the 3.27286 baseline at 5-100σ scale. Optimizer-space exhausted within ±0.001 of current settings. Architecture levers (#392 logit cap, #396 QK-Norm) plus the aux-warmup lever (#412 once fixed) are now the highest-EV directions. Tanjiro #298 residual init and alphonse #190 NS5 sweep remain pod-blocked.
</content>
