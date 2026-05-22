# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-22 ~10:45Z (poll #378)

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)
- *Gate requires ~2σ_single improvement — significantly harder than pre-#699 gate*

**What changed in #699:** Block residual-injection paths (`blocks.*.attn.proj.weight`, `blocks.*.mlp.proj.weight`) now initialized to N(0, sqrt(0.33)/sqrt(fan_in×L)) ≈ N(0, 0.006) instead of zero. μP 1/√L depth scaling provides non-zero starting basis for gradient flow through each block from step 1.

## Active WIP Portfolio (poll #378)

8 PRs in flight; alphonse idle pending new assignment:

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#706** | **nezuko** | Embedding init magnitude (std=0.1) | **P2 n=4 in-flight** — T1=3.259679 (ABOVE new gate by +0.000458; was below old gate). T2/T3/T4 must avg ≤3.258893. Notified. ~3.6h to terminal. |
| **#714** | **edward** | RMSNorm gain init magnitude (mean=0.9) | **P2 n=4 in-flight** — T1=3.263181 (ABOVE new gate by +0.003960). Clean-NEG trajectory vs new baseline. Notified. |
| **#748** | **frieren** | Q/K/V + MLP fc_in transform ×2.0 | **P2 n=4 in-flight (just pivoted)** — T1=3.261066 (ABOVE new gate by +0.001845). Very hard vs new gate. Notified. ~7.2h to terminal from pivot. |
| **#756** | **tanjiro** | Gradient centralization on Muon (pre-NS) | **P1 in-flight** — A=3.264227, B=3.263437 (both above new baseline μ). C running. Trending strongly clean-NEG vs new baseline. |
| **#773** | **fern** | Signal-driven adaptive Muon mu (grad cosine) | **P1 in-flight** — Cell A (alpha=0) ctrl=3.261805. Cell B (alpha=0.02) running ~step 334. Cells C/D/E queued. |
| **#776** | **askeladd** | Muon/SOAP update RMS normalization | **P1 in-flight** — Cell A ctrl=3.2628. Cell B (rms_target=0.25) running. Stale flag cleared poll #377. |
| **#781** | **thorfinn** | Per-group AdamW ε sweep (sparsity asymmetry) | **P1 in-flight** — Just assigned poll #375. 5-cell eps_embed/eps_lm_head sweep. |
| *(pending)* | **alphonse** | Fresh hypothesis (TBD — researcher-agent in flight) | **NEW ASSIGNMENT PENDING** — idle since #699 merged. |


## Critical context: gate has moved

The merge of #699 (musoft, +2mNat) shifted the n=4 gate from **3.261265 → 3.259221**. This 2mNat shift makes the gate significantly harder:

- **nezuko #706**: T1=3.259679 was −0.000586 below OLD gate but +0.000458 ABOVE NEW gate. Merge requires T2/T3/T4 avg ≤ 3.258893 — needs ~−2σ_single improvement across remaining 3 trials.
- **frieren #748**: T1=3.261066 was −0.000200 below OLD gate but +0.001845 ABOVE NEW gate.
- **edward #714**: T1=3.263181 was above both gates; same trajectory.

All P2s notified of gate change. Continue to terminal for characterization value.


## Recent Closures (poll #378 and prior)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#699 alphonse** (poll #378) | **MERGED** ✅ | μ_n=4=3.261221, −2.044mNat vs #571. Statsig 0.004088. ffs_mean=3025 (all 4 trials). μP 1/√L depth scaling for residual-proj wins. First post-#571 init-magnitude merge. New mandatory flag: --depth_init_mode musoft. |
| **#691 thorfinn** (poll #375) | clean-NEG | Per-group β1 stacked P2 μ_n=4=3.26246 (+0.001195 above old gate). Additive stacking non-linear. |
| **#687 askeladd** (poll #373) | clean-NEG | Atan2-AdamW P2 μ_n=4=3.264213. 6th/6 AdamW-kernel mechanisms exhausted. |
| **#722 fern** (poll #371) | clean-NEG | lm_head zero-init optimal. |


## Closed Axis Map (updated post-#699 merge)

**Optimizer algorithms** (8/8 AdamW-kernel modifications): all CLOSED.

**Schedule layer** (all 5 dims): ALL CLOSED.

**Per-group HPs**: LR (all groups), β1 (all groups + stacked), β2 (all groups), global ε — CLOSED. Per-group ε (#781) in-flight.

**Init magnitude**:
- lm_head (#722 CLOSED: zero uniquely optimal)
- embed (#706 P2 in-flight — T1 below old gate, above new gate)
- residual-proj (#699 MERGED: musoft 1/√L wins)
- gains (#714 P2 in-flight — T1 above both gates)
- transformations (#748 P2 in-flight — T1 below old gate, above new gate)

**Novel Muon mechanisms**: GC (#756 P1, trending clean-NEG), adaptive-mu (#773 P1), update-RMS-norm (#776 P1 in-flight).


## Research Themes

**Post-#699 dominant theme:** μP depth scaling for residual paths is real and load-bearing. First post-#571 init-magnitude merge establishes that the model was under-initialized for residual paths at zero-init. With musoft merged, two open questions:
1. Is there additional headroom ABOVE musoft (higher std multiplier)? The P1 didn't probe above 1.0× of the musoft formula.
2. Is depth-aware init additive with transform-init improvements (frieren #748) and embed init (nezuko #706)?

**New gate reality check (3.259221):** All in-flight P2s were designed against the old 3.261265 gate. The new gate is ~2mNat harder. Nezuko's embed-std T1=3.259679 is still competitive. The transform-init T1=3.261066 needs strong remaining trials. Edward's gain-init P2 is likely clean-NEG vs new baseline.

**Next direction post-musoft merge:**
1. **Alphonse**: probe above musoft — find the true optimal magnitude multiplier for 1/√L residual-proj init (is 1.0× optimal, or is 1.5× or 2.0× better?). Fresh 5-cell sweep.
2. When nezuko/frieren/edward P2s resolve: determine which init axes add value ON TOP OF the new musoft baseline. If any merges, compound with next layer.
3. **Longer term**: if 3+ init axes merge, systematically characterize cross-axis interactions (embed × residual × transform) with a compound experiment.
4. Novel Muon mechanisms (#756, #773, #776) remain live but will need to re-gate vs 3.259221 — harder bar now.

**Dead ends to avoid:** All 8 AdamW-kernel replacements (closed), all schedule modifications (closed), per-group β1/β2 (closed), global ε (closed), lm_head init (closed).
