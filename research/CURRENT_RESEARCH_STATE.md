# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-18 18:30 UTC (boot 142x — PR #329 MERGED, askeladd assigned #396)
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

## Active experiments (18:30 UTC 2026-05-18)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#396** | askeladd | **QK-Norm sweep** (off/fixed/learnable RMSNorm on Q+K) | Freshly assigned 18:30 UTC. First architectural test. |
| **#389** | edward | **MuonH inner mu warmup** (mu_warmup_steps 0/100/200) | Assigned 16:45 UTC. Awaiting new-flag notification pickup. |
| **#390** | frieren | **MuLoCo outer optimizer class** (SGDM/AdamW/Lion) | Assigned 17:08 UTC. Awaiting new-flag notification pickup. |
| **#391** | thorfinn | **MuonH warmup duration** (100/200/300 steps) | Assigned 17:09 UTC. Awaiting new-flag notification pickup. |
| **#392** | fern | **Softsign logit cap value** (cap=10/15/30) | Redirected 17:27 UTC (baseline had existing softsign cap). Awaiting new-flag notification pickup. |
| **#361** | nezuko | **Aux lm_head LR sweep** (1/200, 1/320, 1/500) | Arms 1+2 done but NEG under new baseline. Arm 3 (qlkifdse) terminal ~18:30 UTC. Will close after arm 3 posts. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED 72h+** — `gd125a8` bf16 NaN. |
| **#190** | alphonse | **NS5 iter count sweep** | **POD-BLOCKED 72h+** — needs_rebase, `gd103cc`. |

**8/8 students assigned.** No idle slots.

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

22 PRs closed NEG this boot. Key recent closures:
- #352 fern cooldown_frac, #365 frieren sync_interval scheduling, #369 edward outer_lr schedule, #370 thorfinn warmup shape (all wave-3, closed 17:10 UTC)
- #361 nezuko aux lm_head LR (arms 1+2 NEG under new baseline; closing after arm 3)

## Saturated levers

- MuonH-SI HPs (lr/mu/wd), cooldown shape, LR warmup step-count (100 optimal), warmup shape (insensitive)
- MuLoCo outer params (0.7/0.5/30 all saturated); scheduled variants all NEG; outer class swap in test (#390)
- Aux optimizer (Lion/AdEMAMix NEG); aux betas, embed lr_mult, cooldown shape, frac, LR warmup — all saturated
- NS5 polynomial (12-iter optimal); fp32 closed; k-count blocked
- Gradient centralization NEG; schedule-free NEG; depth-LR NEG; lookahead NEG

## Research direction (post wave-3 closures + #329 merge)

**Escalating toward architecture after optimizer plateau.** 5 merges total, last 4 in optimizer space. Now testing:
1. **Architectural** (#396 askeladd QK-Norm, #392 fern logit-cap value, #298 tanjiro residual init [blocked])
2. **Optimizer class** (#390 frieren outer SGDM/AdamW/Lion)
3. **Warmup extension** (#391 thorfinn 100/200/300 steps)
4. **Inner optimizer** (#389 edward mu warmup)

## Active win pipeline

No pending n=4 confirms. All current screens are 1-trial arms. Next probable confirm decision: after arm 1 results from PRs #389-392 land (~18h).
</content>
