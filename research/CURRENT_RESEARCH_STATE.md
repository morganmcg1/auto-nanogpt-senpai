# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-22 ~10:00Z (poll #373)
- **CURRENT BASELINE (PR #571 MERGED poll #321):** μ=3.263265, σ=0.001123, n=4, ffs_mean=3043.75
  - **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03`
  - **Statsig rule:** `(3.263265 - μ) × √n ≥ 0.004`
  - **n=4 gate: μ ≤ 3.261265** (merge) | μ > 3.262 (close clean-NEG)
  - *Gate requires ~2σ_single improvement — hard but achievable; only genuinely strong signals pass*


## Active WIP Portfolio (poll #373)

8 PRs in flight + 1 new assignment:

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#699** | **alphonse** | Depth-aware μP init for block residual paths (1/√L scale, "musoft") | **P2 n=4 in-flight** — W&B run `zp6gvwv5`. T1=3.260513 (BELOW gate −0.000752), T2=3.262263 (above), running mean μ_n=2=3.261388 (+0.000123 above gate). Trial 3 in progress at step ~8593/9750. **Razor-thin outcome. ETA ~2.3h.** |
| **#706** | **nezuko** | Embedding init magnitude sweep (std=0.1 hottest single-seed) | **P2 n=4 in-flight** — W&B run `zp1xxxxxxx` (confirm with student). T1=3.259679 (BELOW gate −0.001586 — hottest signal of round). ETA ~7h from last check. |
| **#691** | **thorfinn** | Per-group AdamW β1 sweep → P2 stacked (β1_embed=0.9, β1_scalars=0.9, β1_lm_head=0.8) | **P2 n=4 in-flight** — P1 best B=3.26178 (+0.000515 above gate). T1 from latest check = 3.262342 (above gate). Running. |
| **#714** | **edward** | RMSNorm gain init magnitude → P2 at Cell D (mean=0.9, std=0.0) | **P2 n=4 in-flight** — P1 best D=3.26203 (+0.000765 above gate). T1=3.263181 (above gate). Running. |
| **#748** | **frieren** | Q/K/V + MLP fc_in transformation init magnitude sweep (5-cell) | **P1 in-flight** — Last cleared stale flag poll #372. Running. |
| **#756** | **tanjiro** | Gradient centralization on Muon body weights (pre-NS, Option A approved) | **P1 in-flight** — Implementing refactor post Option (A) approval (poll #370). Smoke test + sweep in progress. |
| **#773** | **fern** | Signal-driven adaptive Muon mu from gradient cosine similarity | **P1 in-flight** — Assigned poll #371. 5-cell: alpha=0.0/0.02/0.05/0.10/-0.05. SOAP path surgery (lines 624-626). |
| **#776** | **askeladd** | Muon/SOAP update RMS normalization (post-NS scale-invariant step) | **P1 ASSIGNED poll #373** — Normalize post-NS update matrix to fixed target RMS per matrix. `--muon_update_rms_target` flag: A=0.0/B=0.25/C=0.50/D=1.00/E=2.00. Load-bearing surgery in `soap_ns_step` (lines 499-503). |


## Critical race: three P2 confirmations near gate

1. **nezuko #706** (embed std=0.1): T1=3.259679 — **−0.001586 BELOW gate** — hottest single-trial post-#571. If μ_n=4 ≤ 3.261265 → FIRST post-#571 init-layer merge.
2. **alphonse #699** (musoft residual-proj): T1=3.260513 — **−0.000752 BELOW gate** — running μ_n=2=3.261388 razor-thin (+0.000123). Trials 3/4 must average ≤ 3.261142 for merge.
3. **edward #714** (gain mean=0.9): T1=3.263181 — above gate. Would need T2/T3/T4 averaging well below gate.
4. **thorfinn #691** (β1 stacked): T1=3.262342 — above gate. β1 stacked projection at-gate; needs remaining trials to average below.


## Recent Closures (poll #373 and prior)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#687 askeladd** (poll #373) | clean-NEG | Atan2-AdamW P2 μ_n=4=3.264213 (+0.002948 above gate). 6th of 6 AdamW-kernel mechanisms exhausted. LR-ceiling effect real but seed-bounded at n=4. |
| **#722 fern** (poll #371) | clean-NEG | lm_head zero-init uniquely optimal. All 5 mechanism predictions landed. LR-overwrite boundary at std=0.01/0.02 confirmed. Inverts embed-init axis. |
| **#707 tanjiro** (poll #369) | clean-NEG | β2=0.95 symmetric quadratic optimum. Regression scales with group size. Inverts per-group β1 pattern. Per-group β2 axis CLOSED. |
| **#693 frieren** (poll #366) | clean-NEG | Muon mu schedule closed. Cooldown-phase momentum load-bearing; time-varying mu doesn't help. Muon-side time-varying HP space exhausted. |
| **#679 fern** (poll #356) | clean-NEG | LR cooldown shape: linear ctrl is optimal. Cosine +5.5σ, quadratic +8σ, sqrt +10σ, step-cliff +134σ. Schedule layer fully characterized. |
| **#671 edward** (poll #353) | clean-NEG | Cautious AdamW: fast-EMA load-bearing in both directions. 7th augmentation-class test closed. |


## Closed Axis Map (high-level)

**Optimizer algorithms** (6/6 AdamW-kernel modifications): Lion, Lookahead, AdEMAMix, Schedule-Free-B, Adan, AdaBelief, Cautious AdamW, Atan2-AdamW — all CLOSED.

**Schedule layer** (all 5 dims): WD (magnitude/floor/duration/shape/per-group) + LR (cooldown shape/floor/duration, warmup shape/frac) + Muon mu (static/schedule/per-block/time-varying) + NS_iter (count/schedule/coefs) — **ALL CLOSED**.

**Per-group hyperparameters**: LR (embed/lm_head/scalars/mlp/attn) + β2 (all groups) — CLOSED. β1 per-group (#691) in-flight.

**Optimizer internals**: SOAP precond_freq, attn Gram damping, trust-gate threshold, SOAP β2, AGC — CLOSED.

**Init magnitude**: lm_head (#722 CLOSED), embed (#706 P2 in-flight), residual-proj (#699 P2 in-flight), gains (#714 P2 in-flight), transformations (#748 P1 in-flight).

**Novel Muon mechanisms**: GC (#756 P1 in-flight), adaptive-mu (#773 P1 in-flight), update-RMS-norm (#776 P1 assigned).


## Research Themes

**Dominant theme (post-#571):** Init-magnitude across all 5 weight classes has real signal at lr_scalars=0.03. Three of four P2 confirmations have single-trial results near or below gate — the post-#571 equilibria shifted for both embedding magnitude (10× too large at std=1.0) and residual-proj (1/√L better than zero). Gains also shifted below 1.0 (mean=0.9 wins at n=1).

**Emerging pattern:** "LR×3 → init recalibration required." PR #571 raised lr_scalars 3× and embed_lr was already at 0.3 while lm_head_lr was at 1/320. For groups with high LR relative to parameter scale, the equilibrium init magnitude changes — embed (std=0.1 optimal vs default 1.0 = 10×), gains (mean=0.9 optimal vs identity = slight downshift), residual-proj (1/√L depth-aware beats zero-init). This is a coherent μP/LR-theory story.

**Next direction post-init-wave:**
1. If any init P2 merges → compound with other open init axes (especially the depth-aware theme across multiple weight classes).
2. #756 GC on Muon: tests whether removing all-ones direction from raw gradient helps under SOAP path. Orthogonal to init.
3. #773 adaptive mu: first signal-driven momentum schedule. Low expected overhead; high signal potential if gradient coherence fluctuates.
4. #776 update-RMS-norm: NS output scale normalization — closes the update-magnitude axis independent of NS convergence quality.

**Dead ends to avoid:** Any further AdamW-kernel replacement (6/6 closed), schedule modification (all closed), SOAP internals (all closed).
