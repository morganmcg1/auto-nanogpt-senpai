# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-18 ~22:50Z (poll #179)
- **Current baseline:** mu=3.271362, std=0.001181, n=6 (PR #162 merged)
  - ffs_mean=3141.67, ffs_best=3125. Statsig: `(3.271362 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.269362 | n=6: mu ≤ 3.269729 | n=8: mu ≤ 3.269948

## ⭐ Active Hot Signals

1. **🔥🔥 FERN PR #371 P2 ramp_down — TRIALS 0 AND 1 BOTH BELOW GATE** 🔥🔥:
   - P1 Cell C `yh4fzyoe`: val=3.2689 ffs=3100 (P2 trigger)
   - **P2 `okae8f06` n=4 running.**
     - **Trial 0 TERMINAL: val=3.267584, ffs=3100** ✅ (below gate by 0.001778)
     - **Trial 1 TERMINAL: val=3.269173, ffs=3100** ✅ (below gate by 0.000189)
     - Trial 2 in progress (step ~376/3250 after boundary)
   - **Running mean (T0+T1)/2 = 3.268379** — well below n=4 gate 3.269362
   - For n=4 gate: T2+T3 average ≤ 3.270345 (very generous; baseline mu+~σ would suffice)
   - **If trials 2 and 3 hold near baseline: MERGES as new baseline** — first below-baseline merge since baseline merge.

2. **FRIEREN PR #346 lr_attn=0.025 P2 — Likely Clean-Neutral Close** ⚠️:
   - Full sweep: A(0.025)=3.2697 ffs=3125 -1.43σ, B/C flat, D/E degrading
   - **P2 `85x1y4if`: T0=3.275463 ffs=3175, T1=3.270923 ffs=3125** (running mean 3.273193)
   - For n=4 gate: T2+T3 average must be ≤ 3.265531 (~−5σ; implausible)
   - **Likely closes clean-neutral.** Trial 2 in flight (boundary reset).

3. **TANJIRO PR #368 QKV ortho_qk_only P2 Trial 0 CLOSE-MISS** ⚠️:
   - Cell E `05xeeiv8` val=3.26932 ffs=3125 (-1.43σ) — P2 trigger gate
   - **P2 `899b4f5m` Trial 0 TERMINAL: val=3.270026 ffs=3125** (-1.13σ; MISSES n=4 gate by 0.000664)
   - Trial 1 in progress (boundary reset, step ~101/3250)
   - For n=4 gate: T1+T2+T3 average ≤ 3.269141 (tight; needs slight luck across 3 trials)
   - Outcome remains uncertain. Continue to terminal.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #385 | edward | AdamW aux β₁ schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | A=3.27144 ffs=3150 (+0.07σ), B ramp_up=3.27436 ffs=3175 (+2.54σ neg), C ramp_down=3.27291 ffs=3150 (+1.31σ neg). **D triangle RUNNING step 503/3250.** Clean-neg trend; mechanism likely closes after D, E. |
| #383 | nezuko | Muon gradient noise injection sweep std ∈ {0, 1e-4, 1e-3} × {constant, decay, cooldown_only} | A=3.27218 (+0.69σ), B std=1e-4=3.27108 (-0.24σ), **C std=1e-3=3.27081 ffs=3125** (-0.47σ, close-miss val gate by 0.0008). Monotone improving. **D std=1e-3 decay directive sent (poll #176).** |
| #382 | thorfinn | Per-group Muon mu sweep (mu_mlp × mu_attn ∈ {0.93, 0.95, 0.97}) | A (0.95/0.95 ctrl)=**3.269644 ffs=3125** (-1.46σ lucky seed), B (0.93/0.95)=3.271077 ffs=3125 (-0.24σ), C (0.97/0.95)=3.273785 ffs=3150 (+2.05σ neg). **D (0.95/0.93) RUNNING step 200/3250.** No P2 trigger (Cell A is ctrl). |
| #381 | alphonse | AdamW aux β₂ schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | A=3.27084 ffs=3125 (-0.44σ), **B ramp_up=3.27002 ffs=3125** (-1.14σ, just misses P2 gate by 1.5e-5), C ramp_down=3.27124 ffs=3150 (-0.10σ), D triangle=3.27130 ffs=3150 (-0.05σ). **E cos_updn RUNNING step 235/3250.** |
| #371 | fern | Muon WD schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | Cell A=3.2716, B=3.2805, **C ramp_down=3.2689 ffs=3100 → P2 TRIGGER**. **P2 `okae8f06` n=4 running: Trial 0 val=3.267584 ffs=3100 (+0.008416 margin). Trial 1 mid-flight.** |
| #368 | tanjiro | Orthogonal QKV init sweep qkv_init ∈ {default, ortho_unit, ortho_scaled, ortho_v_only, ortho_qk_only} | A=3.2703 ffs=3125, B=3.2727, C=3.2726, D=3.2735, **E ortho_qk_only=3.26932 ffs=3125 → P2 TRIGGER**. **P2 `899b4f5m`: ⚠️ Trial 0=3.270026 ffs=3125 (misses gate by 0.0007). Trial 1 mid-flight.** |
| #398 | askeladd | AdamW aux ε schedule sweep ∈ {constant, ramp_up, ramp_down, spike_cooldown, log_cosine} | Cell A constant RUNNING step 2371/3250 (~73%) after 6 prior crashes. Latest run healthy. Terminal in ~25 min. |
| #346 | frieren | Muon attn LR sweep lr_attn ∈ {0.025, 0.035, 0.045, 0.055, 0.075} | ⭐ Full sweep terminal. A(0.025)=3.2697 ffs=3125 -1.43σ, B(0.035)=3.2721, C(0.045)=3.2720, D(0.055)=3.2741, E(0.075)=3.2789. **P2 `85x1y4if` n=4 running: ⚠️ Trial 0=3.275463 ffs=3175 (+3.47σ, unfavorable). Likely close clean-neutral at terminal.** |


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
- **SOAP precond_freq static (askeladd, closed PR #360 clean-neutral):** U-bowl, apex at default freq=16. freq=4 (+3.7σ), freq=8 (+5.3σ), freq=32/64 (+0.7σ each). Default is local optimum.
- **AdamW aux β₂=0.98 static (edward, closed PR #320 clean-neutral):** n=4 mean=3.27073, ~1.07σ below baseline, sub-statsig.
- LR warmup_steps (thorfinn, closed PR #353 clean-neg: warmup=0 optimal; any warmup eats peak-LR budget on 3250-step run)
- AdamW aux wd_aux uniform (nezuko, closed PR #349 clean-neg: monotone worse; embed at lr=0.30 crushed by shrinkage)

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
