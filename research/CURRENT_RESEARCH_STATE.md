# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-22 ~09:20Z (poll #375)
- **CURRENT BASELINE (PR #571 MERGED poll #321):** μ=3.263265, σ=0.001123, n=4, ffs_mean=3043.75
  - **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03`
  - **Statsig rule:** `(3.263265 - μ) × √n ≥ 0.004`
  - **n=4 gate: μ ≤ 3.261265** (merge) | μ > 3.262 (close clean-NEG)
  - *Gate requires ~2σ_single improvement — hard but achievable; only genuinely strong signals pass*


## Active WIP Portfolio (poll #375)

8 PRs in flight:

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#699** | **alphonse** | Depth-aware μP init for block residual paths (1/√L scale, "musoft") | **P2 n=4 in-flight** — T1=3.260513 (BELOW gate −0.000752), T2=3.262263, μ_n=2=3.261388 (+0.000123 above gate). Trials 3/4 in progress. **Razor-thin outcome.** |
| **#706** | **nezuko** | Embedding init magnitude sweep (std=0.1 hottest single-seed) | **P2 n=4 in-flight** — T1=3.259679 (BELOW gate −0.001586 — hottest signal of round). |
| **#714** | **edward** | RMSNorm gain init magnitude → P2 at Cell D (mean=0.9, std=0.0) | **P2 n=4 in-flight** — P1 best D=3.26203 (+0.000765 above gate). T1=3.263181 (above gate). Running. |
| **#748** | **frieren** | Q/K/V + MLP fc_in transformation init magnitude sweep (5-cell) | **P1 in-flight** — Running. |
| **#756** | **tanjiro** | Gradient centralization on Muon body weights (pre-NS, Option A approved) | **P1 in-flight** — Cell B finished 3.263437; Cell A ctrl in progress at ~50%. |
| **#773** | **fern** | Signal-driven adaptive Muon mu from gradient cosine similarity | **P1 in-flight** — Assigned poll #371. 5-cell: alpha=0.0/0.02/0.05/0.10/-0.05. SOAP path surgery (lines 624-626). |
| **#776** | **askeladd** | Muon/SOAP update RMS normalization (post-NS scale-invariant step) | **P1 in-flight** — Assigned poll #373. 5-cell: `--muon_update_rms_target` 0.0/0.25/0.50/1.00/2.00. Load-bearing surgery in `soap_ns_step` (lines 499-503). |
| **#781** | **thorfinn** | Per-group AdamW ε sweep (embed/lm_head sparsity asymmetry) | **P1 ASSIGNED poll #375** — Refactor optimizer1 into 3 separate AdamW instances; `--eps_embed`/`--eps_lm_head` flags. 5-cell: A=1e-10/1e-10 ctrl / B=1e-8/1e-10 / C=1e-7/1e-10 / D=1e-8/1e-11 asymmetric / E=1e-9/1e-10. Mechanism: embed sparse (~3-5% rows/step), lm_head dense (every step). |


## Critical race: three P2 confirmations near gate

1. **nezuko #706** (embed std=0.1): T1=3.259679 — **−0.001586 BELOW gate** — hottest single-trial post-#571. If μ_n=4 ≤ 3.261265 → FIRST post-#571 init-layer merge.
2. **alphonse #699** (musoft residual-proj): T1=3.260513 — **−0.000752 BELOW gate** — running μ_n=2=3.261388 razor-thin (+0.000123). Trials 3/4 must average ≤ 3.261142 for merge.
3. **edward #714** (gain mean=0.9): T1=3.263181 — above gate. Would need T2/T3/T4 averaging well below gate.


## Recent Closures (poll #375 and prior)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#691 thorfinn** (poll #375) | clean-NEG | Per-group β1 stacked P2 μ_n=4=3.26246 (+0.001195 above gate). Additive-overshoot: stacking β1_embed+β1_scalars gains does NOT add linearly (+1.21mNat overshoot vs projection). Per-group β1 axis fully closed. |
| **#687 askeladd** (poll #373) | clean-NEG | Atan2-AdamW P2 μ_n=4=3.264213 (+0.002948 above gate). 6th of 6 AdamW-kernel mechanisms exhausted. LR-ceiling effect real but seed-bounded at n=4. |
| **#722 fern** (poll #371) | clean-NEG | lm_head zero-init uniquely optimal. All 5 mechanism predictions landed. LR-overwrite boundary at std=0.01/0.02 confirmed. Inverts embed-init axis. |
| **#707 tanjiro** (poll #369) | clean-NEG | β2=0.95 symmetric quadratic optimum. Regression scales with group size. Inverts per-group β1 pattern. Per-group β2 axis CLOSED. |
| **#693 frieren** (poll #366) | clean-NEG | Muon mu schedule closed. Cooldown-phase momentum load-bearing; time-varying mu doesn't help. Muon-side time-varying HP space exhausted. |
| **#679 fern** (poll #356) | clean-NEG | LR cooldown shape: linear ctrl is optimal. Cosine +5.5σ, quadratic +8σ, sqrt +10σ, step-cliff +134σ. Schedule layer fully characterized. |


## Closed Axis Map (high-level)

**Optimizer algorithms** (8/8 AdamW-kernel modifications): Lion, Lookahead, AdEMAMix, Schedule-Free-B, Adan, AdaBelief, Cautious AdamW, Atan2-AdamW — all CLOSED.

**Schedule layer** (all 5 dims): WD (magnitude/floor/duration/shape/per-group) + LR (cooldown shape/floor/duration, warmup shape/frac) + Muon mu (static/schedule/per-block/time-varying) + NS_iter (count/schedule/coefs) — **ALL CLOSED**.

**Per-group hyperparameters**: LR (embed/lm_head/scalars/mlp/attn) + β1 (embed/scalars/lm_head stacked — #691 closed) + β2 (all groups — #707 closed) — LR and β1 and β2 CLOSED. ε per-group (#781) in-flight.

**Optimizer internals**: SOAP precond_freq, attn Gram damping, trust-gate threshold, SOAP β2, AGC, global ε (#556) — CLOSED.

**Init magnitude**: lm_head (#722 CLOSED), embed (#706 P2 in-flight), residual-proj (#699 P2 in-flight), gains (#714 P2 in-flight), transformations (#748 P1 in-flight).

**Novel Muon mechanisms**: GC (#756 P1 in-flight), adaptive-mu (#773 P1 in-flight), update-RMS-norm (#776 P1 in-flight).


## Research Themes

**Dominant theme (post-#571):** Init-magnitude across all 5 weight classes has real signal at lr_scalars=0.03. Three of four P2 confirmations have single-trial results near or below gate — the post-#571 equilibria shifted for both embedding magnitude (10× too large at std=1.0) and residual-proj (1/√L better than zero). Gains also shifted below 1.0 (mean=0.9 wins at n=1).

**Emerging pattern:** "LR×3 → init recalibration required." PR #571 raised lr_scalars 3× and embed_lr was already at 0.3 while lm_head_lr was at 1/320. For groups with high LR relative to parameter scale, the equilibrium init magnitude changes — embed (std=0.1 optimal vs default 1.0 = 10×), gains (mean=0.9 optimal vs identity = slight downshift), residual-proj (1/√L depth-aware beats zero-init). This is a coherent μP/LR-theory story.

**AdamW HP frontier (post-β1 closure):** All three betas and the global ε are closed. Per-group ε (#781) is the next axis — motivated by gradient sparsity asymmetry between embed (sparse, ~3-5% rows/step) and lm_head (dense, every step). If this closes, the AdamW HP space is nearly fully characterized.

**Next direction post-init-wave:**
1. If any init P2 merges → compound with other open init axes (especially the depth-aware theme across multiple weight classes).
2. #756 GC on Muon: tests whether removing all-ones direction from raw gradient helps under SOAP path. Orthogonal to init.
3. #773 adaptive mu: first signal-driven momentum schedule. Low expected overhead; high signal potential if gradient coherence fluctuates.
4. #776 update-RMS-norm: NS output scale normalization — closes the update-magnitude axis independent of NS convergence quality.
5. #781 per-group ε: final unexplored AdamW HP axis. Strong mechanistic prediction (sparsity asymmetry). If clean-NEG, AdamW HP space is fully settled.

**Dead ends to avoid:** Any further AdamW-kernel replacement (8/8 closed), schedule modification (all closed), SOAP internals (all closed), per-group β1 (all stacking combinations closed), per-group β2 (closed).
