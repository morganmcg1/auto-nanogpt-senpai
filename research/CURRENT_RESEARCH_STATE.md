# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-19 01:37 UTC (PR #390 frieren closed NEG; PR #425 frieren assigned; PR #424 askeladd assigned; thorfinn pod broken — 3rd broken pod escalated to operator)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse (`gd103cc`) + tanjiro (`gd125a8`) still broken. Issue #164 esc#18-addendum posted 01:30 UTC adding thorfinn's pod. esc#19 due ~03:30 UTC.
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

## Active experiments (01:37 UTC 2026-05-19)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#417** | edward | **MuonH inner cooldown_frac sweep** (1.0/0.7/0.5) | Arm 1 ctrl `zu2yy4jn` running, step ~875/3325. ETA terminal ~02:40 UTC. Smoke `lfna200y` also running. |
| **#421** | nezuko | **MuonH inner AGC clip ratio sweep** (0.02/0.05/0.10) | Smoke `uyga9woi` finished val=4.23 (passed gate). Ctrl arm launching soon. |
| **#424** | askeladd | **MuLoCo outer SGDM Nesterov sweep** (std vs Nesterov mu=0.5/0.8) | **NEWLY ASSIGNED** — requires `--muloco_outer_nesterov` flag. ETA launch ~02:00 UTC. |
| **#425** | frieren | **MuonH-SI inner mu cooldown sweep** (0.95→0.70/0.50 during LR decay) | **NEWLY ASSIGNED** — requires `--muonh_mu_final` flag + dynamic mu scheduling. ETA launch ~02:00 UTC. |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED** — 3rd consecutive NaN at step 125 on GPU `dc8b1158`, P=0.05%. Escalated in Issue #164. Standing by for operator rotation. |
| **#392** | fern | **Softsign logit cap value** (cap=10/15/30) | Cap=15 ctrl `6hideyt9` **TERMINAL val=3.2734, ffs=3150** (Δ=+0.00054, baseline-equiv). Cap=10 and cap=30 arms auto-chaining. ETA arm2+3 terminal ~04:00–05:00 UTC. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED 79h+** — `gd125a8` bf16 NaN, no operator rotation. |
| **#190** | alphonse | **NS5 iter count sweep** | **POD-BLOCKED 79h+** — needs_rebase, `gd103cc`, no operator rotation. |

**8/8 students assigned.** 3 pods broken (thorfinn + tanjiro + alphonse) = 37.5% research capacity lost.

## Recent closures (01:37 UTC wave)

| PR | Student | Result | Closed |
|---|---|---|---|
| **#390** | frieren | **MuLoCo outer optimizer class (SGDM/AdamW/Lion) — ALL NEG.** SGDM ctrl +0.00106; AdamW Δ=+0.08388 (catastrophic, update_rms 70× too small); Lion Δ=+0.44774 (catastrophic). Outer optimizer CLASS saturated. | 01:33 UTC |
| **#396** | askeladd | **QK-Norm sweep (off/fixed/learnable) — ALL NEG.** off catastrophic (+0.02430); fixed=baseline (ctrl); learnable +0.00331 (~3σ). Removing fixed F.rms_norm is essential. | 01:17 UTC |
| **#397** | nezuko | **Aux lm_head weight decay (wd=0/0.01/0.05) — ALL NEG.** Non-monotonic: wd=0.01 worst (+0.00254), wd=0.05 slightly better (+0.00080), wd=0 baseline-equiv. Bad zone at small wd. | 01:20 UTC |

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
- MuLoCo outer params (0.7/0.5/30 all saturated); scheduled variants all NEG; outer CLASS (Nesterov-SGDM/AdamW/Lion) all NEG except Nesterov-SGDM. **Code note**: The current outer SGDM is actually **Nesterov SGDM** (the `lr*(mu*v + delta)` form at lines 1093-1095) — confirmed by askeladd's code reading on PR #424. frieren's "SGDM ctrl" in PR #390 was therefore Nesterov-SGDM.
- Aux optimizer (Lion/AdEMAMix NEG); aux betas, embed lr_mult, cooldown shape, frac, LR warmup, lm_head wd — all saturated
- NS5 polynomial (12-iter optimal, polynomial coefficients neutral at k=12 per PR #174); fp32 closed; k-count blocked
- Gradient centralization NEG; schedule-free NEG; depth-LR NEG; lookahead NEG; EMA tail averaging NEG
- QK-Norm (removing or learning: both NEG; fixed F.rms_norm is optimal)
- Outer optimizer class (SGDM-only; AdamW/Lion catastrophic)

## Research direction (01:37 UTC)

**Optimizer space broadly exhausted. Remaining live directions:**

1. **Inner LR dynamics** (#417 edward: cooldown_frac; #425 frieren: mu cooldown during LR decay)
2. **Inner optimizer geometry** (#424 askeladd: Nesterov outer SGDM; #421 nezuko: AGC clip ratio)
3. **Architecture levers** (#392 fern: logit cap value — ctrl baseline; cap=10/cap=30 chaining)
4. **Pod-blocked** (#298 tanjiro residual init, #190 alphonse NS5 iter) — 79h+ infra block

**3rd broken pod (thorfinn #412)** confirmed silicon failure at 01:30 UTC. Operator has not responded to esc#18 (00:50 UTC). esc#19 due ~03:30 UTC.

**Key mechanism finding** (thorfinn diagnostic, PR #412): ~8% baseline stochastic NaN at step 125. 3rd NaN on same GPU UUID (`dc8b1158`) with P=0.0005 → silicon damage confirmed. AGC NaN pass-through (`NaN > clip_ratio = False`) is a known code-level issue; AGC hardening (NaN-safe clip) remains a future lever.

**Fern logit-cap** is the highest-EV current test: cap=15 (baseline softsign) confirmed as ctrl at 3.2734 (Δ=+0.00054 vs baseline — within σ). Cap=10 (tighter) and cap=30 (looser) will determine if logit scale is a lever. Attention logits run at mean 4.3 with fixed QK-norm, well below the ±15 cap — cap=10 will saturate much earlier.

## Active win pipeline

No pending n=4 confirms. All current screens are 1-trial arms. No arm so far has passed n=1 promotion bar (<3.27206).

**Ctrl reproductions** (all current wave): edward ctrl 3.27264, nezuko ctrl 3.27281, frieren SGDM ctrl 3.27392. **Estimated σ ≈ 0.0006–0.0008.**
