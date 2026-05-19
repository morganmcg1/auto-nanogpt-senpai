# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 03:35 UTC (esc#19 posted 03:30 UTC; edward arm 1 ctrl baseline-reproduces; fern cap=10 NEG; cap=30 chaining)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse (`gd103cc`) + tanjiro (`gd125a8`) + thorfinn (`g71b0d6`) still broken. esc#19 posted at 03:30 UTC 2026-05-19 — ~80h total operator silence.
- **Branch state:** Baseline post-PR #329 (AGC inner MuonH clip=0.05, merged 18:26 UTC 2026-05-18).

## ⭐ Current baseline (post-PR #329 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27286** (n=4 mean; trials: 3.27209/3.27264/3.27365/3.27305) |
| `ffs` (primary) | **3125** (best); mean 3137.5 |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| **MuonH inner AGC** | **`--muonh_agc_clip_ratio 0.05`** |
| MuonH LR warmup | warmup_steps=100, shape=linear |
| Outer wrapper | MuLoCo Nesterov-SGDM (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| Aux AdamW | betas=(0.8, 0.95), eps=1e-10, AGC clip_ratio=0.05 |
| Cooldown | MuonH=cosine frac=1.0, aux=linear frac=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| Logit cap | softsign at ±15 (hardcoded; cap=10 NEG, cap=30 in flight) |
| W&B confirm | `dpabql6o` (n=4 multi-trial) |

**Merge bar**: μ_val < 3.27286 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004.
- **n=1 promotion bar**: val < **3.27206** (Δ ≤ −0.0008 vs 3.27286)
- **Conservative n=4 bar**: μ < **3.27246**

**⚠️ CRITICAL — ALL new experiment commands must include:**
```
--aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --muonh_cooldown_shape cosine --muonh_warmup_steps 100
```

## Active experiments (03:35 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#417** | edward | **MuonH inner cooldown_frac sweep** (1.0/0.7/0.5) | **Arm 1 ctrl `zu2yy4jn` TERMINAL val=3.27236, ffs=3125** (Δ=-0.00050, clean baseline reproduction, within σ). Arm 2 `u88kyal5` (cooldown_frac=0.7) running step 725/3325. ETA arm 2 terminal ~05:35 UTC; arm 3 chains after. |
| **#421** | nezuko | **MuonH inner AGC clip ratio sweep** (0.02/0.05/0.10) | Nudged at 03:06 UTC. Ctrl arm `ndt56ttp` (clip=0.05) launched, step 575 val=3.91 (on baseline pace). ETA ctrl terminal ~05:30 UTC; arms 0.02 + 0.10 chain after. |
| **#424** | askeladd | **MuLoCo outer SGDM Nesterov sweep** (drop_nest / keep_nest mu=0.5 / nest mu=0.8) | Smoke arm2 `dwliwjxr` finished val=4.22 (passed gate). Ctrl arm `1qq8lbpn` (arm2 nest mu=0.5) running step 250 val=4.22 (on baseline pace). Note: zombie wandb run `n0ok0cgj` also showing same arm. Arm 1 smoke `vx59qcr2` failed step 0 (relaunch needed). |
| **#425** | frieren | **MuonH-SI inner mu cooldown sweep** (0.95→0.70/0.50) | **Concerning** — student has launched 4 ctrl runs (ohv95v1v, 4pu30gxj, 3rcd7c6v, o8zyjowj) with same config. Currently `o8zyjowj` at step 120. No commits yet to remote. Implementation may be unstable. |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED** — confirmed silicon failure on GPU `dc8b1158`. ~2h blocked. In esc#19. |
| **#392** | fern | **Softsign logit cap value** (cap=10/15/30) | Cap=15 ctrl confirmed Δ=+0.00110 within σ. **Cap=10 `7ap085t3` TERMINAL val=3.27933, ffs=3275 (Δ=+0.00647 NEG)** — tighter cap harmful. Cap=30 `ahgrgeub` running step 140 (on pace). ETA arm 3 terminal ~05:30 UTC. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED 80h+** — `gd125a8` bf16 NaN. In esc#19. |
| **#190** | alphonse | **NS5 iter count sweep** | **POD-BLOCKED 80h+** — needs_rebase, `gd103cc`. In esc#19. |

**8/8 students assigned.** 3 pods broken (alphonse + tanjiro + thorfinn) = 37.5% research capacity lost.

## Recent terminal results (03:35 UTC wave)

| PR | Student | Result |
|---|---|---|
| **#417 arm 1** | edward | **Ctrl cooldown_frac=1.0**: val=**3.27236**, ffs=3125 (Δ=-0.00050, baseline-equivalent). Run `zu2yy4jn`. |
| **#392 arm cap=10** | fern | **Tighter cap=10**: val=**3.27933**, ffs=3275 (Δ=+0.00647 NEG). Logit_max_pre_cap saturates fast, cap restricts useful headroom. Run `7ap085t3`. |

## Recent closures (01:37 UTC wave)

| PR | Student | Result | Closed |
|---|---|---|---|
| **#390** | frieren | **MuLoCo outer optimizer class (SGDM/AdamW/Lion) — ALL NEG.** SGDM ctrl +0.00106; AdamW Δ=+0.08388; Lion Δ=+0.44774. Outer optimizer CLASS saturated. | 01:33 UTC |
| **#396** | askeladd | **QK-Norm sweep (off/fixed/learnable) — ALL NEG.** off catastrophic; learnable +0.00331. Fixed F.rms_norm is essential. | 01:17 UTC |
| **#397** | nezuko | **Aux lm_head weight decay (wd=0/0.01/0.05) — ALL NEG.** Non-monotonic; wd=0.01 worst. | 01:20 UTC |

## MERGED this round (chronological)

| PR | Student | Result |
|---|---|---|
| **#114** | frieren | MuLoCo × MuonH-SI MERGED — val=3.27585 (n=4) |
| **#237** | edward | AGC aux clip=0.05 MERGED — val=3.27469 (n=4) |
| **#243** | frieren | MuonH-SI cosine cooldown MERGED — val=3.27415 (n=4) |
| **#310** | thorfinn | MuonH inner LR warmup=100 MERGED — val=3.27315 (n=4) |
| **#329** | askeladd | **AGC inner MuonH clip=0.05 MERGED** — val=**3.27286** (n=4). **Current baseline.** |

**Total improvement since start**: 3.27585 → 3.27286 = **−0.00299** over 5 merged PRs.

## Saturated levers

- MuonH-SI HPs (lr/mu/wd), cooldown shape, LR warmup step-count (100 optimal), warmup shape (insensitive), mu warmup (PR #389 NEG)
- MuLoCo outer params (0.7/0.5/30 all saturated); scheduled variants all NEG; outer CLASS (Nesterov-SGDM/AdamW/Lion) all NEG except Nesterov-SGDM. **Code note**: The current outer SGDM is actually **Nesterov SGDM** (the `lr*(mu*v + delta)` form at lines 1093-1095) — confirmed by askeladd's code reading on PR #424.
- Aux optimizer (Lion/AdEMAMix NEG); aux betas, embed lr_mult, cooldown shape, frac, LR warmup, lm_head wd — all saturated
- NS5 polynomial (12-iter optimal, polynomial coefficients neutral at k=12 per PR #174); fp32 closed; k-count blocked
- Gradient centralization NEG; schedule-free NEG; depth-LR NEG; lookahead NEG; EMA tail averaging NEG
- QK-Norm (removing or learning: both NEG; fixed F.rms_norm is optimal)
- Outer optimizer class (Nesterov-SGDM-only; AdamW/Lion catastrophic)
- **Logit soft-cap** (cap=15 baseline; cap=10 tighter NEG +0.00647; cap=30 pending)

## Research direction (03:35 UTC)

**Optimizer space broadly exhausted.** Inner LR dynamics and inner geometry are the remaining live directions. Architecture levers like logit cap probe the model's ceiling rather than the optimizer.

**Remaining live directions:**

1. **Inner LR dynamics** (#417 edward arm 2/3: cooldown_frac; #425 frieren: mu cooldown during LR decay) — most likely to find headroom
2. **Inner optimizer geometry** (#424 askeladd: Nesterov outer SGDM ablation; #421 nezuko: AGC clip ratio)
3. **Architecture levers** (#392 fern: cap=30 looser logit cap — directional gradient (cap=10 worse than cap=15) suggests cap=30 may show improvement)
4. **Pod-blocked** (#298 tanjiro residual init, #190 alphonse NS5 iter, #412 thorfinn aux warmup) — esc#19 posted at 03:30 UTC

**Operator silence on Issue #164**: 80h total, 3 broken pods. esc#19 posted at 03:30 UTC. esc#20 would be due ~06:00 UTC if no response.

**Key mechanism findings:**
- Thorfinn diagnostic (PR #412): 3 consecutive NaNs at step 125 on GPU `dc8b1158`, P=0.05% → silicon damage confirmed. AGC NaN pass-through is a known code-level issue.
- Fern cap=10 (PR #392): Logit_max_pre_cap grows to 223 (15× the cap). Tighter cap saturates earlier and harms learning. cap=30 may benefit from headroom.
- Frieren ctrl noise: 4 wandb runs for the same ctrl arm — student appears to be iterating on implementation without pushing commits. Will let it ride; flag if no useful result by 05:00 UTC.

## Active win pipeline

No pending n=4 confirms. Cap=30 (fern), arms 2/3 (edward), and ctrl_2/3 arms (nezuko, askeladd, frieren) are the in-flight 1-trial screens. No arm so far has passed n=1 promotion bar (<3.27206).

**Ctrl reproductions** (this wave): edward ctrl 3.27236 (n=1), nezuko ctrl 3.27281 (prior wave), frieren SGDM ctrl 3.27392 (prior wave), fern cap=15 3.27396 (n=2 mean). **Estimated σ ≈ 0.0006–0.0008.**
