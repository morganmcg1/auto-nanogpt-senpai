# Baseline Metrics — auto-nanogpt-1gpu-r2

Target: `records/track_3_optimization/train_gpt_simple.py`, modded-nanogpt
optimizer speedrun track 3. Primary metric is
`speedrun/final_first_step_to_target` — the earliest step at which validation
cross-entropy on FineWeb reaches `<= 3.28`, lower is better. Final claims
require `(3.28 - mu) * sqrt(n) >= 0.004`.

## Current advisor-branch baseline (updated)

### 2026-05-19 12:05 — PR #415: MU_WARMUP_STEPS=200 — Muon momentum warmup (squash-merged)

| Field | Value |
| --- | --- |
| `train_steps` | 3175 |
| Key change | Added explicit Muon μ warmup: `cur_mu` ramps from `MU_WARMUP_START=0.85` → `MU_COOLDOWN_START=0.95` linearly over the first 200 steps, then holds at plateau. Previously `cur_mu=0.95` from step 0. Env vars: `MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85`. |
| Contra-Muon HPs | `CONTRA_MUON=0.4`, `TARGET_UW=0.35`, `MUON_LR=0.0375` |
| Cooldown μ HPs | `MU_COOLDOWN_START=0.95`, `MU_COOLDOWN_END=0.90` |
| Warmup μ HPs | `MU_WARMUP_STEPS=200`, `MU_WARMUP_START=0.85` |
| SOAP HPs | `SOAP_BETA2=0.90`, `SOAP_PRECOND_FREQ=10`; `ATTN_SOAP_TRUST_THRESHOLD=0.85` |
| LR schedule | unified `cooldown_frac=0.7` (linear) |
| W&B run | `nh6ge2df` (n=4 confirm); `xi4d6osg` (n=2 screen) |
| **n=4 mean val/loss** | **3.273477** |
| **n=4 statsig margin** | **0.013046** ≥ 0.004 — PASSES (3.26×) |
| **ffs mean** | **3056.25** (T0=3050, T1=3050, T2=3050, T3=3075) |
| **speedup vs PR #358** | val Δ=−0.000906; ffs Δ=−12.5 |

Per-trial results:
| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.272928 | 3050 |
| T1 | 3.274003 | 3050 |
| T2 | 3.272357 | 3050 |
| T3 | 3.274621 | 3075 |

**Mechanism insight**: Muon EMA `state["momentum"]` starts at zero; applying `cur_mu=0.95` (high smoothing) while the buffer is still populating produces effectively over-smoothed early updates. With explicit warmup (0.85→0.95 over 200 steps), the optimizer follows the recent-gradient signal more faithfully during the EMA-fill window, then ramps to full plateau momentum once the buffer is meaningful. Empirical signature: step-125 val ≈4.42 (Arm A) vs ≈4.51 (baseline) — earlier loss improvement without any stability regression. Cross-trial spread 0.0023 is one of the tightest n=4 seen this cycle.

**New merge bar**: mean val < **3.273477** AND ffs_mean < **3056.25** (STRICT — both required)

**All new experiments must include**: `CONTRA_MUON=0.4 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85`

---

### 2026-05-18 20:55 — PR #358: CONTRA_MUON=0.4 (reduced from 0.5) (squash-merged)

| Field | Value |
| --- | --- |
| `train_steps` | 3175 |
| Key change | `CONTRA_MUON` reduced from 0.5 → 0.4 (first axis sweep since PR #139 which set it to 0.5). Smaller contra-gradient correction lets Muon's geometry-corrected update retain more natural momentum signal. Env var: `CONTRA_MUON=0.4`. |
| Contra-Muon HPs | `CONTRA_MUON=0.4`, `TARGET_UW=0.35`, `MUON_LR=0.0375` |
| Cooldown μ HPs | `MU_COOLDOWN_START=0.95`, `MU_COOLDOWN_END=0.90` |
| SOAP HPs | `SOAP_BETA2=0.90`, `SOAP_PRECOND_FREQ=10`; `ATTN_SOAP_TRUST_THRESHOLD=0.85` |
| LR schedule | unified `cooldown_frac=0.7` (linear) |
| W&B run | `ivvf500c` (n=4 confirmation, all 4 trials); `oeeswx8a` (n=2 screen) |
| **n=4 mean val/loss** | **3.274383** |
| **n=4 statsig margin** | **0.01123** ≥ 0.004 — PASSES (2.81×) |
| **ffs mean** | **3068.75** (T0=3075, T1=3075, T2=3075, T3=3050) |
| **speedup vs PR #288** | val Δ=−0.000967; ffs Δ=−18.75 |
| **speedup vs starter** | ~281 steps / ~8.4% |

Per-trial results:
| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27523 | 3075 |
| T1 | 3.27432 | 3075 |
| T2 | 3.27455 | 3075 |
| T3 | 3.27343 | 3050 |

**Mechanism insight**: CONTRA_MUON=0.5 was first set at PR #139 and never swept. Reducing to 0.4 (20% less counter-correction) gives consistent −0.001 val improvement. ffs concentrated at 3075 (3/4 trials) with one T3 at 3050. The gain likely reflects that baseline CONTRA_MUON was slightly over-correcting, eating into the natural momentum direction.

**New merge bar**: mean val < **3.274383** AND ffs_mean < **3068.75** (STRICT — both required)

**All new experiments must include**: `MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.4`

Reproduce (from advisor branch, single GPU):
```bash
cd target/
CONTRA_MUON=0.4 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 \
  torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3175 --num_trials 4 \
  --wandb_name 'baseline-repro-pr358' \
  --wandb_group 'baseline-verification'
```

---

### 2026-05-18 08:35 — PR #288: Cooldown-only μ anneal (MU_COOLDOWN_START=0.95→MU_COOLDOWN_END=0.90) (squash-merged)

| Field | Value |
| --- | --- |
| `train_steps` | 3175 |
| Key change | Muon momentum μ held at 0.95 through warmup+plateau, then annealed linearly from 0.95→0.90 during cooldown phase only (starts step ~952). Replaces full-training schedule from PR #219. Env vars: `MU_COOLDOWN_START=0.95`, `MU_COOLDOWN_END=0.90`. Full-run MU_START/MU_END deprecated. |
| Contra-Muon HPs | `CONTRA_MUON=0.5`, `TARGET_UW=0.35`, `MUON_LR=0.0375` |
| SOAP HPs | `SOAP_BETA2=0.90`, `SOAP_PRECOND_FREQ=10`; `ATTN_SOAP_TRUST_THRESHOLD=0.85` |
| LR schedule | unified `cooldown_frac=0.7` (linear) |
| W&B run | `qceklszn` (n=4 confirmation, all 4 trials) |
| **n=4 mean val/loss** | **3.275350** |
| **n=4 statsig margin** | **0.00930** ≥ 0.004 — PASSES (2.33×) |
| **ffs mean** | **3087.5** (T0=3075, T1=3100, T2=3100, T3=3075) |
| **speedup vs PR #219** | val Δ=−0.000485; ffs Δ=0 (tied — 25-step quantization artifact) |
| **speedup vs starter** | ~262 steps / ~7.8% |

Per-trial results:
| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27437 | 3075 |
| T1 | 3.27600 | 3100 |
| T2 | 3.27586 | 3100 |
| T3 | 3.27517 | 3075 |

**Mechanism insight**: μ-anneal benefit localizes to cooldown phase. Arm A (0.97→0.92 full-training) missed both bars; Arm B (cooldown-only 0.95→0.90) cleared val bar + tied ffs. This confirms NS5-orthogonalized Muon doesn't need warmup stabilization from high μ — the benefit is purely from reactive low μ during LR cooldown.

Reproduce (from advisor branch, single GPU):
```bash
cd target/
MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5 \
  torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3175 --num_trials 4 \
  --wandb_name 'baseline-repro-pr288' \
  --wandb_group 'baseline-verification'
```

---

### 2026-05-17 16:35 — PR #219: Annealed Muon momentum μ schedule (MU_START=0.97→MU_END=0.90) (squash-merged)

| Field | Value |
| --- | --- |
| `train_steps` | 3175 |
| Key change | Muon momentum μ annealed linearly from 0.97 (start) → 0.90 (end). Env vars: `MU_START=0.97`, `MU_END=0.90`. High μ early stabilizes the noisy CONTRA_MUON warmup; lower μ late makes Muon reactive during LR cooldown. |
| Contra-Muon HPs | `CONTRA_MUON=0.5`, `TARGET_UW=0.35`, `MUON_LR=0.0375`, `MU_START=0.97`, `MU_END=0.90` |
| SOAP HPs | `SOAP_BETA2=0.90`, `SOAP_PRECOND_FREQ=10`; `ATTN_SOAP_TRUST_THRESHOLD=0.85` (attn trust gate, from PR #212) |
| LR schedule | unified `cooldown_frac=0.7` (linear) |
| W&B run | `47bb0bf2` (n=4 confirmation, all 4 trials) |
| **n=4 mean val/loss** | **3.275835** |
| **n=4 statsig margin** | **0.00833** ≥ 0.004 — PASSES (2.08×) |
| **ffs mean** | **3087.5** (T0=3075, T1=3100, T2=3075, T3=3100) |
| **speedup vs PR #212** | **−25.0 mean ffs steps** (3112.5 → 3087.5) |
| **speedup vs starter** | ~262 steps / ~7.8% |

Per-trial results:
| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27510 | 3075 |
| T1 | 3.27697 | 3100 |
| T2 | 3.27489 | 3075 |
| T3 | 3.27638 | 3100 |

Note: n=4 confirmation ran on the pre-PR-#212 stack (without ATTN_SOAP_TRUST_THRESHOLD=0.85). Result still beats the PR-#212 bars, confirming mechanism additivity. Future experiments should run on the fully merged stack (both #212 and #219 changes active).

Reproduce (from advisor branch, single GPU):
```bash
cd target/
MU_START=0.97 MU_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5 \
  torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3175 --num_trials 4 \
  --wandb_name 'g1r2-thorfinn/annealed-mu-repro' \
  --wandb_group 'g1r2-thorfinn/annealed-mu'
```

---

### 2026-05-17 12:53 — PR #212: Attn-SOAP+trust T=0.85 on CONTRA_MUON=0.5 baseline (squash-merged)

| Field | Value |
| --- | --- |
| `train_steps` | 3175 |
| Key change | Attn-SOAP coverage extended to attention weights at `ATTN_SOAP_TRUST_THRESHOLD=0.85` (env var; code-level default is 0.9). SOAP gate fires when cosine-similarity between attn eigenbasis pre-QR and post-QR ≥ 0.85 |
| Contra-Muon HPs | `CONTRA_MUON=0.5`, `TARGET_UW=0.35`, `MUON_LR=0.0375`, `MU=0.95` (unchanged) |
| SOAP HPs | `SOAP_BETA2=0.90`, `SOAP_PRECOND_FREQ=10`; now applies to `mlp.fc.weight`, `mlp.proj.weight` **AND** attn weights at T=0.85 |
| Optimizer aux | AdamW: embed.weight lr=0.3; proj.weight lr=1/320; scalars lr=0.01; betas=(0.8, 0.95), eps=1e-10, wd=0 |
| LR schedule | unified `cooldown_frac=0.7` (linear) |
| W&B run | `3xn3ox1c` (n=4 confirmation) |
| **n=4 mean val/loss** | **3.27631** |
| **n=4 statsig margin** | **0.00738** ≥ 0.004 — PASSES |
| **ffs mean** | **3112.5** (T0=3125, T1=3100, T2=3125, T3=3100) |
| **speedup vs PR #139** | **−6.25 mean ffs steps** (3118.75 → 3112.5) |
| **speedup vs starter** | ~237 steps / ~7.1% |

Per-trial results:
| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.2764 | 3125 |
| T1 | 3.2761 | 3100 |
| T2 | 3.2775 | 3125 |
| T3 | 3.2752 | 3100 |

Reproduce (from advisor branch, single GPU):
```bash
cd target/
ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3175 --num_trials 4 \
  --wandb_name 'g1r2-nezuko/attn-soap-new-base-confirm-n4' \
  --wandb_group 'g1r2-nezuko/attn-soap-new-base'
```

---

### 2026-05-16 23:14 — PR #139: CONTRA_MUON=0.5 retune on Contra+SOAP-MLP base (squash-merged)

| Field | Value |
| --- | --- |
| `train_steps` | 3175 |
| Optimizer 2D | **Contra-Muon + SOAP-MLP**: same as PR #78 but with `CONTRA_MUON=0.5` (up from 0.4) |
| Contra-Muon HPs | `CONTRA_MUON=0.5`, `TARGET_UW=0.35`, `MUON_LR=0.0375`, `MUON_WEIGHT_DECAY=0.025`, `MU=0.95` |
| SOAP HPs | `SOAP_BETA2=0.90`, `precondition_frequency=10`; applies to `mlp.fc.weight` and `mlp.proj.weight` only |
| Optimizer aux | AdamW: embed.weight lr=0.3; proj.weight lr=1/320; scalars lr=0.01; betas=(0.8, 0.95), eps=1e-10, wd=0 |
| LR schedule | unified `cooldown_frac=0.7` (linear) |
| W&B run | `db1rrfx3` (n=4 confirmation, all 4 trials) |
| **n=4 mean val/loss** | **3.27648** |
| **n=4 statsig margin** | **0.00704** ≥ 0.004 — PASSES |
| **ffs mean** | **3118.75** (T0=3150, T1=3125, T2=3100, T3=3100) |
| **speedup vs PR #78** | **−12.50 mean ffs steps** (3131.25 → 3118.75) |
| **speedup vs starter** | ~231 steps / ~6.9% |

Per-trial results:
| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27830 | 3150 |
| T1 | 3.27634 | 3125 |
| T2 | 3.27551 | 3100 |
| T3 | 3.27577 | 3100 |

Reproduce (from advisor branch, single GPU):
```bash
cd target/
CONTRA_MUON=0.5 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3175 --num_trials 4 \
  --wandb_name 'alphonse-contra-muon-0.5-n4' \
  --wandb_group 'g1r2-alphonse/contra-muon-retune'
```

---

### 2026-05-16 06:35 — PR #78: Contra-Muon + SOAP preconditioning on MLP weights (squash-merged)

| Field | Value |
| --- | --- |
| `train_steps` | 3175 |
| Optimizer 2D | **Contra-Muon + SOAP-MLP**: NorMuon with operator-norm contra correction, u/w-floor, + SOAP eigenbasis preconditioner on MLP weights (SOAP applied to momentum BEFORE NS5) |
| Contra-Muon HPs | `CONTRA_MUON=0.4`, `TARGET_UW=0.35`, `MUON_LR=0.0375`, `MUON_WEIGHT_DECAY=0.025`, `MU=0.95` |
| SOAP HPs | `SOAP_BETA2=0.90`, `precondition_frequency=10`; applies to `mlp.fc.weight` and `mlp.proj.weight` only |
| NorMuon variance | `nm_beta2=0.95`, `nm_eps=1e-8`, `nm_renorm=frob`; Frobenius renorm post-NS5 |
| Optimizer aux | AdamW: embed.weight lr=0.3; proj.weight lr=1/320; scalars lr=0.01; betas=(0.8, 0.95), eps=1e-10, wd=0 |
| LR schedule | unified `cooldown_frac=0.7` (linear) |
| W&B run | `6bbhoxm1` (n=4 confirmation, all 4 trials) |
| **n=4 mean val/loss** | **3.27760** |
| **n=4 statsig margin** | **0.00480** ≥ 0.004 — PASSES |
| **ffs mean** | **3131.25** (T0=3150, T1=3150, T2=3100, T3=3125) |
| **speedup vs NorMuon baseline** | **−125 mean ffs steps** (3256.25 → 3131.25) |
| **speedup vs starter** | ~220 steps / ~6.5% |

Per-trial results:
| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27920 | 3150 |
| T1 | 3.27811 | 3150 |
| T2 | 3.27522 | 3100 |
| T3 | 3.27787 | 3125 |

Reproduce (from advisor branch, single GPU):
```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3175 --num_trials 1 \
  --wandb_name "$STUDENT_NAME/contra-soap-mlp-repro" \
  --wandb_group "contra-soap-mlp-repro"
```
*(Contra-Muon + SOAP-MLP HPs are baked into the merged `train_gpt_simple.py` on `auto-nanogpt-1gpu-r2`.)*

---

### 2026-05-16 01:55 — PR #71: NorMuon-clean (squash-merged, superseded)

| Field | Value |
| --- | --- |
| `train_steps` | 3300 |
| Optimizer 2D | **NorMuon**: Muon with post-NS5 Adafactor row/col variance + Frobenius renorm |
| NorMuon HPs | `nm_beta2=0.95`, `nm_eps=1e-8`, `nm_renorm=frob`, `lr=0.035`, `wd=0.025` |
| Optimizer aux | AdamW: embed.weight lr=0.3; proj.weight lr=1/320; scalars (ndim<2) lr=0.01; betas=(0.8, 0.95), eps=1e-10, wd=0 |
| Newton-Schulz | 12 iters, (a, b, c) = (2, -1.5, 0.5), bfloat16 |
| LR schedule | unified `cooldown_frac=0.7` |
| W&B run | `8yocwc35` (n=4 confirmation, all 4 trials) |
| **n=4 mean val/loss** | **3.27800** |
| **n=4 statsig margin** | **0.00401** ≥ 0.004 — PASSES |
| **ffs mean** | **3256.25** (T0=3225, T1=3250, T2=3275, T3=3275) |
| **speedup vs starter** | ~50 steps / ~1.5% |

Per-trial results:
| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.276094 | 3225 |
| T1 | 3.278030 | 3250 |
| T2 | 3.279136 | 3275 |
| T3 | 3.278725 | 3275 |

Reproduce (from advisor branch, single GPU):
```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3300 --num_trials 1 \
  --wandb_name "$STUDENT_NAME/normuon-repro" \
  --wandb_group "normuon-repro"
```
*(NorMuon HPs are baked into the merged `train_gpt_simple.py` on `auto-nanogpt-1gpu-r2`.)*

### Starter script baseline (historical reference)

| Field | Value |
| --- | --- |
| `train_steps` | 3350 |
| Optimizer 2D | Muon (lr=0.035, wd=0.025, mu=0.95) on `model.blocks.parameters() ndim>=2` |
| Optimizer aux | AdamW: embed.weight lr=0.3; proj.weight lr=1/320; scalars (ndim<2) lr=0.01; betas=(0.8, 0.95), eps=1e-10, wd=0 |
| Newton-Schulz | 12 iters, (a, b, c) = (2, -1.5, 0.5), bfloat16 |
| LR schedule | unified `cooldown_frac=0.7` |
| Val | 20 * 524288 ≈ 10.5M tokens |
| Target val/loss | ≤ 3.28 |

## Public modded-nanogpt track 3 records to beat (from `records/track_3_optimization/README.md`)

| # | Steps | Mean val loss (n) | Description |
| - | - | - | - |
| 1 | 3600 | 3.2777 (n=1) | Muon + aux Adam, lr=.02 wd=.01 |
| 2 | 5625 | 3.2790 (n=1) | AdamW lr=0.0015 wd=0.1 betas=(0.9, 0.95) warmup=250 |
| 3 | 3500 | 3.2767 (n=1) | Muon + aux Adam, lr=.025 wd=.0125 |
| 4 | 4875 | 3.2741 (n=5) | AdamH (Adam + hyperball) with per-module init std, lr=.018 |
| 5 | 3325 | 3.2782 (n=10) | MuonH (Muon + hyperball) with per-module init std, lr=.018 |
| 6 | 3375 | 3.2788 (n=20) | Muon + aux Adam, lr=.025 wd=.025 |
| 7 | 3325 | 3.2752 (n=1) | Muon² (Adam variance before NS), lr=.10 wd=.0125 β₂=.95 |
| 8 | 3250 | 3.2778 (n=10) | NorMuonH (NS + Adafactor row/col + hyperball) + per-module init, lr=.018 |
| 9 | 3250 | 3.2771 (n=8) | NorMuon + u/w-floor (wd-free), lr=.0375 |
| 10 | 3250 | 3.2789 (n=20) | NorMuon lr=0.035 wd=0.025, end 50 steps early |
| 11 | 3225 | 3.2785 (n=16) | Setup #9 + Contra-Muon |
| 12 | 3325 | 3.2790 (n=20) | Muon + aux Adam, lr=.035 wd=.025, end 25 steps early |
| 13 | 3210 | 3.2785 (n=10) | NorMuonH wrapped in MuLoCo-style outer Nesterov SGD (sync=30, outer_lr=0.7, outer_mom=0.5) |
| 14 | 3150 | 3.2776 (n=4) | Setup #11 + SOAP precond for MLP (freq=10, beta2=0.90) |
| 15 | 3275 | 3.2785 (n=15) | Newton-Muon: activation-cov right-preconditioning refresh every 64 steps |
| 16 | 3125 | 3.2784 (n=8) | Setup #14 + SOAP for attention with trust gate |
| 17 | 3175 | 3.2789 (n=20) | Setup #11 + Aurora |
| 18 | 3225 | 3.2776 (n=9) | PMuon: bilateral streaming covariance power preconditioning, γ=.3 β=.95 |
| 19 | 3125 | 3.2780 (n=6) | KL-SOAP + hyperball, precondition_frequency=1, lr=.018 beta1=.95 beta2=.9 |
| **20** | **3030** | **3.2790 (n=30)** | **Setup #16 + Contra-Muon ∪ Soft-Muon (annealed) + power-law LR. Current global best.** |
| 21 | 4100 | 3.2776 (n=4) | Shampoo(power=-1/4, lr=0.0015, betas=(.9,.95), wd=0.2, precond_freq=5) |

## Step-vs-loss conversion (from README)

200 fewer steps ≈ 0.0091 higher mean val loss (≈ 0.0045 per 100 steps). Use
this when comparing runs at different step counts for pairwise statsig.

## Reproduce command (on a single GPU)

```bash
cd target/
python data/cached_fineweb10B.py 20
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/<short-description>" \
  --wandb_group "<hypothesis-or-pr>"
```
