# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-18 21:30 UTC (boot 143x — arm-1 ctrl wave landing: thorfinn/nezuko/edward all confirm baseline reproduction, askeladd off-arm NEG by 0.024)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse (`gd103cc`) + tanjiro (`gd125a8`) still broken. Issue #164 esc#16 posted 19:48 UTC. Operator silent ~73h+ (esc#17 due ~22:30 UTC).
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

## Active experiments (21:30 UTC 2026-05-18)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#397** | nezuko | **Aux lm_head weight decay sweep** (wd=0/0.01/0.05 on lm_head only) | **Arm 1 (wd=0 ctrl) terminal `y7q4vanw` val=3.27281, Δ=−0.00005 (reproduces baseline)**. Arm 2 (wd=0.01) starting. |
| **#396** | askeladd | **QK-Norm sweep** (off/fixed/learnable RMSNorm on Q+K) | **Arm 1 (off) terminal `o20httom` val=3.29716, Δ=+0.02430 — clean NEG (24σ regression).** Confirms F.rms_norm load-bearing. Arm 2 (fixed) `xwml6u2c` step 30 — ETA terminal ~22:55 UTC. |
| **#389** | edward | **MuonH inner mu warmup** (mu_warmup_steps 0/100/200) | **Arm 1 (mu_warmup=0 ctrl) terminal `va3dm8i1` val=3.27264, Δ=−0.00022 (reproduces baseline)**. Arm 2 (mu_warmup=100) `xdqpdnvd` step 1650 — ETA terminal ~22:40 UTC. |
| **#390** | frieren | **MuLoCo outer optimizer class** (SGDM/AdamW/Lion) | Arm 1 (SGDM ctrl) `jgltipi3` step 2600/3325 mid-cooldown — ETA terminal ~21:47 UTC. Auto-chain queued for arms 2+3 (AdamW lr=0.014, Lion lr=0.001). |
| **#391** | thorfinn | **MuonH warmup duration** (100/200/300 steps) | **Arm 1 (warmup=100 ctrl) terminal `a05x4jp0` val=3.27325, Δ=+0.00039 (reproduces baseline)**. Arm 2 (warmup=200) starting. |
| **#392** | fern | **Softsign logit cap value** (cap=10/15/30) | **STUCK** — bit-identity smokes pass (`uqsd7wuz`=4.225, `6d7vgks3`=4.217) but full cap=15 control `4bj0dk3c` crashed step 725 val 3.83. Pinged 21:25 UTC for status; 23:00 UTC time-box. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED 73h+** — `gd125a8` bf16 NaN, no operator rotation. |
| **#190** | alphonse | **NS5 iter count sweep** | **POD-BLOCKED 73h+** — needs_rebase, `gd103cc`, no operator rotation. |

**8/8 students assigned.** No idle slots. **First wave of arm-1 ctrl results validates baseline reproducibility across thorfinn/nezuko/edward.** Askeladd's off arm is a clean NEG. Fern stuck on smoke debug.

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

No pending n=4 confirms. All current screens are 1-trial arms.

**Arm-1 results landed 21:30 UTC** — all 3 control arms reproduce baseline within σ noise (thorfinn +0.00039, nezuko −0.00005, edward −0.00022). Askeladd off-arm is a clean NEG. None pass n=1 promotion bar (<3.27206).

**Next terminal wave (~21:47–22:55 UTC):**
- 21:47 UTC: frieren SGDM ctrl (`jgltipi3`)
- 22:40 UTC: edward arm 2 mu_warmup=100 (`xdqpdnvd`)
- 22:55 UTC: askeladd arm 2 fixed (`xwml6u2c`) — control, expect ~baseline

**Pattern check:** Multi-student baseline reproduction within ±0.0004 is healthy variance. Suggests true σ on the post-#329 baseline is ~0.0003–0.0005 per trial. n=1 bar 3.27206 (−0.0008 vs mean) likely needs ~2× σ improvement signal to merit n=4 confirm.
</content>
