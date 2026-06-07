# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~16:30 UTC (launch day +3)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (unchanged since H-W merge)

**PR #2317 (nezuko H-W): NC × Arbor + EMA-Nesterov + RI = 3.276193 at 2890 steps**
- Stack: Cautious-Muon (NC) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075)
- W&B: `vk0jtb3z`. Contract margin: 0.007615.

## Active assignments (~16:30 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~35h. |
| **#2346** | open2-edward | H-AW: EN REST_STEPS=2300 | **n=4 confirm in flight** — `479jhxyf` step 3541/5780 (~61%). T1 (seed 2) `best_val_loss = 3.2748` (need ri_loss). Terminal ETA ~17:15 UTC. PRIMARY MERGE CANDIDATE. |
| **#2349** | open2-frieren | H-AY: AdamW eps sweep | **Arm A INCONCLUSIVE** at n=2 mean 3.276584 (T0=3.277593, T1=3.275574, spread=0.002019 = 4× noise floor). Just above FALSIFIED threshold. **Student launching Arm B (eps=1e-12) per spec.** Arm B n=2 ETA ~19:25 UTC. |
| **#2351** | open2-fern | H-BC: Spectral radius norm | Arm A `v65l1o11` T0 done (best_val_loss 3.2808 — need student's ri_loss SENPAI-RESULT), T1 in progress at step 2892/5780. n=2 ETA ~17:45 UTC. |
| **#2352** | open2-nezuko | H-BF: SNR-adaptive AdamW LR | **Arm A `5d6pyw54` step 450/2890 (~16%)**. Smoke showed SNR clip saturates at 3× for ALL AdamW groups → effectively a flat 3× LR boost. Advisor authorized continue with early-abort rule (T0 ≥ 3.29 → abort). |
| **#2353** | open2-thorfinn | H-BG: PMuon + β₂-pulse | **Arm A `q9y1953e` step 1250/2890 (~43%)**. Launched 15:30 UTC. ETA ~18:55 UTC. |
| **#2354** | open2-askeladd | H-BH: GC on Muon momentum buffer | **Pending pod pickup** (assigned 15:20 UTC). Variance escalation rule built in. |
| **#2355** | open2-tanjiro | H-BI: Depth-wise Muon LR (NEW) | **JUST ASSIGNED 16:25 UTC** after H-BA closed FALSIFIED at 29th lever. Arm A decay=0.85, Arm B inverted decay=0.90. |

## Recent closures (last 90 min, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 16:15 | #2350 (tanjiro H-BA) | Sophia-G diagonal Hessian | **CLOSED FALSIFIED** | T0=3.35478 = **+0.07859** (157× noise floor). SNR mechanism: 46% clip_fraction, ratio_mean_abs 4.27e8 — embed/lm_head sparse-row gradients collapse the GNB Hessian estimator. **29th saturated lever** (AdamW-side preconditioner family closed for sparse-gradient param groups). |
| 2026-06-07 14:50 | #2343 (askeladd H-AT) | GC on raw Muon gradient (n=4) | **CLOSED FALSIFIED** | n=4 mean 3.277174 = +0.000981, σ=0.000911 variance blow-out (~2× noise floor). **28th saturated lever** (per-channel mean subtraction × NC mask conflict). H-BH on momentum buffer is mechanism isolation. |
| 2026-06-07 14:13 | #2348 (thorfinn H-AZ) | Lookahead Muon k=6 α=0.5 | **CLOSED FALSIFIED** | T0=+0.0158 (32× noise floor). **27th saturated lever** (wrapper augmentations on Muon dead). |
| 2026-06-07 14:00 | #2341 (nezuko H-AR) | EN γ warmup | **CLOSED FALSIFIED** | Both arms +0.0022-+0.0033. **26th saturated lever.** |
| 2026-06-07 13:50 | #2340 (fern H-AQ) | AdamW β₁ warmup | **CLOSED FALSIFIED** | Both arms +0.0022-+0.0030. **25th saturated lever.** |

## Saturated levers count: 29 (+ 2 failed direction families)

(Levers 1-25 unchanged. Recently added:)

26. **EN γ warmup (H-AR)** — both arms FALSIFIED.
27. **Lookahead Muon wrapper (H-AZ)** — catastrophic +0.0158.
28. **GC on raw Muon gradient (H-AT)** — n=4 mean +0.001 with variance blow-out. H-BH (GC on momentum) is mechanism follow-up.
29. **Sophia-G on AdamW (H-BA)** — T0 catastrophic +0.079. AdamW-side preconditioner family closed for sparse-gradient param groups (embed/lm_head). GNB Hessian estimator collapses on rows with no token signal.

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |

## Strategic context (deep plateau)

We are now **29 saturated levers and 2 failed direction families** into a deep plateau. The rank-1 3.276193 stack is highly optimized.

**Two key positive signals visible at INCONCLUSIVE level (need confirms to merge):**
1. **edward H-AW REST=2300**: n=2 mean 3.276274 with T1 BELOW rank-1. n=4 confirm running, ETA ~17:15 UTC.
2. **frieren H-AY eps=1e-8**: n=2 mean 3.276584 with T1 BELOW rank-1. Just above FALSIFIED threshold. Arm B (eps=1e-12) next.

**KEY PENDING (next 1-3 hours):**
1. **edward H-AW n=4 SENPAI-RESULT** ~17:15 UTC — strongest merge candidate.
2. **fern H-BC T0+T1 n=2 SENPAI-RESULT** ~17:45 UTC — spectral norm mechanism test.
3. **nezuko H-BF T0** with saturation finding ~17:30 UTC.
4. **thorfinn H-BG PMuon+β₂-pulse Arm A T0** ~17:50 UTC (~halfway through trial 1).
5. **askeladd H-BH pod pickup** + smoke.
6. **tanjiro H-BI pod pickup** + smoke.
7. **frieren H-AY Arm B (eps=1e-12) n=2** ~19:25 UTC.

**Plateau Protocol wave 2-3 in flight:**
- Wave 2: H-BC spectral norm (fern), H-BF SNR-LR (nezuko)
- Wave 3: H-BG PMuon+β₂-pulse (thorfinn), H-BH GC-on-momentum (askeladd), H-BI depth-wise LR (tanjiro)
- Queued: H-BJ NS-iter × LR coupling

## Saturation finding (nezuko H-BF smoke)

Important mechanism insight from nezuko's smoke (`pw1mydik`, 60 steps): **SNR clip saturates at 3× for all three AdamW groups (embed, lm_head, scalars) across the entire post-warmup window**. Mechanism: with β₂=0.95 in early training, consecutive gradients are highly correlated → `v_t ≈ m_t²` → `noise_var = v_t − m_t²` ≈ 0 → SNR → ∞. The `1e-10 clamp_min` is the active floor.

This means **SNR-adaptive LR at snr_target=1.0/clip=3 degenerates to a flat 3× LR multiplier** on all AdamW groups. The full Arm A run will therefore test "what if AdamW LRs are 3× higher than the merged calibration?" — an orthogonal but interesting question. Closing-direction: if T0 ≥ 3.29 (catastrophic), abort early.

## Next-wave hypotheses (queued)

1-5. ✓ All wave 2-3 assigned (H-BA through H-BI in flight or closed).
6. **H-BJ: NS-iter × LR coupling** — Arm A NS8+LR×1.04, Arm B NS16+LR×0.97.
7. **H-BK: Warm-restart LR at step 2000** — single cosine restart.
8. **H-BL: Embed LR decoupling** — Arm A embed_lr=0.4, Arm B embed_lr=0.2.

## Open Operational Items

- **Alphonse pod broken** (Issue #2319 ~35h).
- **Nezuko H-BF saturation finding** — student to continue Arm A under early-abort rule.
- **Fern + edward** — waiting on student SENPAI-RESULT with proper ri_loss numbers (current W&B fetch only had `best_val_loss`, not the RI metric).
