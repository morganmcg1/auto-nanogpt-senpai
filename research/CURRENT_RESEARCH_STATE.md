# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-18 ~16:30Z (poll #168)
- **Current baseline:** mu=3.271362, std=0.001181, n=6 (PR #162 merged)
  - ffs_mean=3141.67, ffs_best=3125. Statsig: `(3.271362 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.269362 | n=6: mu ≤ 3.269729 | n=8: mu ≤ 3.269948

## ⭐ Active Hot Signals

1. **FRIEREN PR #346 Cell A (lr_attn=0.025) HIT P2 TRIGGER** ⭐:
   - Cell A `orkpejsl` FINISHED: **val=3.269674 ffs=3125** (~−1.43σ below baseline)
   - Cell B ctrl `xovourxm` FINISHED: val=3.272 ffs=3150 (clean baseline reproduction)
   - DUPLICATE INCIDENT 12:25Z: `vqd4wcez` killed; Cell C `fmycgozs` (lr_attn=0.045) launched cleanly, step 403/3250
   - Sweep continuing through C/D/E before P2 promotion


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #385 | edward | AdamW aux β₁ schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | NEW ASSIGNMENT (PR #385 created). Cell A constant ctrl pending launch. |
| #383 | nezuko | Muon gradient noise injection sweep std ∈ {0, 1e-4, 1e-3} × {constant, decay, cooldown_only} | NEW ASSIGNMENT (PR #383). Cell A ctrl pending. |
| #382 | thorfinn | Per-group Muon mu sweep (mu_mlp × mu_attn ∈ {0.93, 0.95, 0.97}) | NEW ASSIGNMENT (PR #382 created). Cell A ctrl pending launch. |
| #381 | alphonse | AdamW aux β₂ schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | NEW ASSIGNMENT (PR #381 created). Cell A constant ctrl pending launch. |
| #371 | fern | Muon WD schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | Cell A constant ctrl val=3.2716 ffs=3150. Cell B `u01fl5oh` (ramp_up) FINISHED: val=3.28053 ffs=-1 (target NEVER reached, +7.6σ). Over-regularization confirmed: 2×WD at terminal prevents convergence. Cell C (ramp_down) pending. |
| #368 | tanjiro | Orthogonal QKV init sweep qkv_init ∈ {default, ortho_unit, ortho_scaled, ortho_v_only, ortho_qk_only} | Cell A ctrl: val=3.2703 ffs=3125 (-0.9σ). Cell B (ortho_unit gain=1.0): val=3.27268 ffs=3150 (+1.1σ, clean-neg). Cell C ortho_scaled pending launch. |
| #360 | askeladd | SOAP precond_freq sweep ∈ {4, 8, 16, 32, 64} | Cell A freq=4 FINISHED: val=3.2757 ffs=3175 (+3.6σ clean-neg). Cell B freq=8 FINISHED: val=3.2776 ffs=3200 (+5.3σ clean-neg). Cell C freq=16 ctrl launching. Monotone WORSE with more frequent refresh — default freq=16 is local optimum. |
| #346 | frieren | Muon attn LR sweep lr_attn ∈ {0.025, 0.035, 0.045, 0.055, 0.075} | ⭐ Cell A (0.025): val=3.26967 ffs=3125 (P2 trigger -1.43σ). Cell B ctrl (0.035): val=3.27206 ffs=3150. Cell C (0.045): val=3.27203 ffs=3150 (~baseline). Cell D (0.055), E (0.075) pending. Trend: 0.025 best so far. |


## Research Themes

**Primary goal:** Stack orthogonal mechanisms onto lr_mlp=0.055 base to push below ffs=3125. Target: ffs=3100 → 3075 → beyond.

**Active mechanism threads:**
- **AdamW aux β₁ (fern, CLOSED #318):** β₁=0.70 n=4 mean=3.271540 (Δ=+0.000178, Phase 1 signal was seed noise). Now testing **Muon WD schedule** (PR #371).
- **AdamW aux β₂ (edward):** β₂=0.85 neg, β₂=0.95 ctrl, β₂=0.98 P2 n=4 **CLOSED clean-neutral** (mean=3.27073, ~1.07σ below baseline, sub-statsig). β₂=0.99 mild (+1.4σ-ish). β₂ schedule in-flight (alphonse PR #381). β₁ schedule now testing (edward PR #385).
- **LR cooldown_frac (thorfinn, closed):** bowl-shaped, default cd=0.70 optimal. LR **warmup_steps** (PR #353, closed clean-NEG): warmup=0 is optimal; any warmup eats peak-LR budget. Now testing **per-group Muon mu** (PR #382).
- **lm_head LR (alphonse, CLOSED #306 clean-neutral):** monotone P1 inverted-U at lr=0.030 (-0.87σ n=1), but Phase 2 n=4 mean=3.2711925 misses gate. Now testing **AdamW aux β₂ time-varying schedule** (PR #381).
- **Muon WD (askeladd, closed):** bowl-shape, default wd=0.025 optimal (wd=0 +14.5σ, wd=0.05 +6.7σ, wd=0.10 +28σ). Now testing **SOAP precond_freq** (PR #360).
- **Muon nesterov (frieren):** nesterov=True ctrl reproduces baseline; nesterov=False (Polyak) in flight
- **Muon mu (tanjiro, CLOSED #323):** bowl-shape, default mu=0.95 optimal. mu=0.85 +3.67σ, mu=0.97 +3.56σ, mu=0.99 failed to reach target (+31.18σ). Now testing **QKV orthogonal init** (PR #368).

**Exhausted mechanism slots (recent additions):**
- **AdamW aux β₂=0.98 static (edward, closed PR #320 clean-neutral):** n=4 mean=3.27073, ~1.07σ below baseline, sub-statsig. Third endpoint-LR/aux-hparam pattern (with PR #228, #306). Per-trial σ=0.00154 floor limits aux-hparam improvements at n=4.
- LR warmup_steps (thorfinn, closed PR #353 clean-neg: warmup=0 optimal; any warmup eats peak-LR budget on 3250-step run)
- AdamW aux wd_aux uniform (nezuko, closed PR #349 clean-neg: A=3.26944→B=3.27403→C=3.29135/FAIL, monotone worse; embed at lr=0.30 is crushed by shrinkage; mixed-LR-scale groups cannot share wd)

**Exhausted mechanism slots:**
- lr_embed=0.80 (frieren, clean-neutral n=6)
- NS5 polynomial space (askeladd, clean-neutral)
- SOAP attn eigvec smoothing (thorfinn, clean-neutral)
- SOAP β₂ cold-start warmup (edward, clean-neutral)
- Q/K shared Gram (fern, clean-neutral)
- AdamW eps sweep (alphonse, clean-neutral)
- Per-layer LR decay (nezuko, clean-negative)
- NS5 iteration count (askeladd, clean-neutral)
- SOAP attn Gram damping (fern, clean-neutral)
- AGC λ=0.03 (nezuko, P2 confirmed dead, mean=3.272890 fails n=4 gate by ~3σ, closed PR #283)
- Muon WD static sweep (askeladd, closed PR #334 clean-neg: bowl, default wd=0.025 optimal)
- Muon mu sweep (tanjiro, closed PR #323 clean-neg: bowl, default mu=0.95 optimal)
- AdamW aux β₁=0.70 (fern, closed PR #318 clean-neutral: n=4 mean=3.271540, Phase 1 n=1 was seed noise)
- lr_lm_head=0.030 (alphonse, closed PR #306 clean-neutral: monotone Phase 1 inverted-U at lr=0.030 (-0.87σ n=1), Phase 2 n=4 mean=3.2711925 misses gate by 12×. Endpoint-LR sweeps look promising at n=1 but don't survive n=4 — pattern matches frieren lr_embed=0.80 #228)
- Cautious-Muon, Lookahead, SWA, z-loss, gradient centralization, label smoothing, depth-init, per-head SOAP, schedule-free Muon, polynomial schedule-free Muon, SOAP β₂ cooldown annealing — all closed

**Candidate next hypotheses (queue for next idle student):**
- Muon mu × nesterov 2D joint sweep (if frieren lr_attn sweep reveals a winner)
- AdamW aux ε schedule (analogous to alphonse/edward β schedule work)
- lr_attn Phase 2 n=4 at 0.025 (after frieren completes C/D/E sweep and confirms monotone)
- SOAP precond_freq upper tail {64, 128} screen (after askeladd confirms C/D/E monotone)
- Per-block LR non-monotone shapes (sinusoidal or block-pair grouping vs nezuko's rejected monotone)
