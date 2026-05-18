# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-18 18:43 UTC (boot 142x — PR #361 CLOSED NEG, nezuko reassigned #397)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse (`gd103cc`) + tanjiro (`gd125a8`) still broken. Issue #164 esc#15 posted 17:00 UTC. Operator silent ~72h+.
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

## Active experiments (19:00 UTC 2026-05-18)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#397** | nezuko | **Aux lm_head weight decay sweep** (wd=0/0.01/0.05 on lm_head only) | Assigned 18:43 UTC after #361 closed NEG. Reuses lm_head-specific plumbing. |
| **#396** | askeladd | **QK-Norm sweep** (off/fixed/learnable RMSNorm on Q+K) | Redirected 19:00 UTC — baseline already has F.rms_norm; arm semantics revised: off=remove, fixed=baseline-equiv, learnable=add scale. head_dim=128 (not 64). Smoke `ympej1dq` done step 300. |
| **#389** | edward | **MuonH inner mu warmup** (mu_warmup_steps 0/100/200) | Active — `va3dm8i1` arm-1 ctrl at step 675 w/ AGC flag (18:59 UTC). Stale `keybcdow` confirmed killed. |
| **#390** | frieren | **MuLoCo outer optimizer class** (SGDM/AdamW/Lion) | Stale-run cleanup requested 19:00 UTC — `pakw25ll` (step 870) launched pre-#329 without `--muonh_agc_clip_ratio`. |
| **#391** | thorfinn | **MuonH warmup duration** (100/200/300 steps) | Active — `a05x4jp0` arm-1 step 425 w/ AGC flag (18:59 UTC). |
| **#392** | fern | **Softsign logit cap value** (cap=10/15/30) | Active — `bwjjfmts` arm-1 launched step 0 w/ AGC flag (18:59 UTC). Earlier smoke crashed (no AGC). |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED 72h+** — `gd125a8` bf16 NaN. |
| **#190** | alphonse | **NS5 iter count sweep** | **POD-BLOCKED 72h+** — needs_rebase, `gd103cc`. |

**8/8 students assigned.** No idle slots. 3 of 5 fresh PRs (#389/391/392) confirmed running with new `--muonh_agc_clip_ratio 0.05` flag. Edward leads at step 675.

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

No pending n=4 confirms. All current screens are 1-trial arms. Edward's `va3dm8i1` is the first arm-1 run with the new AGC flag (step 120 at 18:40 UTC; ETA ~20:30 UTC). Other students still ramping up after baseline-shift notice. Next probable confirm decision: after arm 1 results from PRs #389-392, #396 land (~22:00-23:00 UTC).
</content>
