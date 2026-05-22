# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-22 ~17:10Z (poll #434)

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)
- *Gate requires ~2σ_single improvement — significantly harder than pre-#699 gate*

**What changed in #699:** Block residual-injection paths (`blocks.*.attn.proj.weight`, `blocks.*.mlp.proj.weight`) now initialized to N(0, sqrt(0.33)/sqrt(fan_in×L)) ≈ N(0, 0.006) instead of zero. μP 1/√L depth scaling provides non-zero starting basis for gradient flow through each block from step 1.

## Active WIP Portfolio (poll #398)

8 PRs in flight; no idle students:

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#800** | **edward** | Per-block depth-dependent Muon momentum (`--mu_depth_scale`) | **Assigned poll #399.** 5 cells: A=ctrl mu=0.95, B=α=0.5, C=α=1.0, D=α=2.0, E=inverse. Prediction: B wins (gentle depth taper). Kill-switch: B > A + 50 ffs → close. ETA ~9h. |
| **#706** | **nezuko** | Embed-init std=0.1 — **COMPOUND P3 (musoft × embed=0.1)** | **Sent back poll #398.** Pre-#699 P2 μ=3.260705 cleared OLD gate by 0.000560, missed NEW by 0.001484. Now testing compound on post-#699 codebase. New W&B group `embed-init-std01-musoft-compound-P3`. ETA ~6h54m from ~13:05Z. |
| **#748** | **frieren** | Q/K/V + MLP fc_in transform ×2.0 P2 | **P2 n=4 in-flight (pre-#699 codebase)** — T1=3.261066 (cleared OLD gate band, ABOVE NEW gate +0.001845). Notified poll #378. ~7.2h to terminal from 10:00Z pivot → ~17:12Z. |
| **#815** | **tanjiro** | NS-WarmUp — sequential Newton-Schulz iteration ramp-up | **Assigned poll #418.** 5 cells: A=ctrl ns_iter=6, B=warmup_steps=500 start=2 (primary), C=300/start=3, D=1000/start=2, E=500/start=1 (aggressive). Prediction: B > C > A > D > E. Kill at val/loss>3.32 step 1000. ETA ~9h. |
| **#823** | **fern** | SignMuon — sign-transform Nesterov momentum before NS ortho | **Assigned poll #434.** 5 cells: A=ctrl, B=sign MLP-only, C=sign all, D=sign all + lr_mlp 0.06, E=sign all + ns_iter 4. Prediction: D > C > B > E > A. Kill: Cell B <0.001 improvement vs A → close. ETA ~9h. |
| **#776** | **askeladd** | Muon/SOAP update RMS normalization | **P1 in-flight** — Cell A ctrl=3.2628. Cell B running. |
| **#781** | **thorfinn** | Per-group AdamW ε sweep (sparsity asymmetry) | **P1 in-flight on NEW musoft baseline** — Rebased poll #383 after duplicate-Cell-A driver bug. New W&B group `per-group-eps-musoft`. Cell A on musoft just started ~11:39Z. Sequential blocking-foreground chain (5 cells × ~1:48h = ~9h). ETA ~20:30Z. |
| **#785** | **alphonse** | Residual-proj init magnitude α∈{0.5/0.75/1.0/1.5/2.0} | **P1 in-flight** — Cell A (α=0.50) at step ~1022 of 3250 as of 11:21Z. SMOKE@α=1.0 finished clean. Primary prediction: D (α=1.5) wins. |

## Recent Closures (poll #418)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#773 fern** (poll #434) | clean-NEG | Adaptive-mu from grad cosine similarity. Mechanism falsified: both +α and −α degrade val/loss monotonically. Best A(ctrl)=3.26181 vs worst D(α=0.10)=3.27568. Sign-falsifier Cell E (−0.05) as bad as Cell C (+0.05), killing directional-coherence story. SOAP eigenbasis rotation leaves residual cos-sim as high-freq noise, not load-bearing signal. Axis closed. |
| **#756 tanjiro** (poll #418) | clean-NEG | GC on Muon body weights 5-cell. Best Cell C (row-pre-all) = 3.26223 = +0.90σ above new baseline μ. Cells: A=3.26423, B(col-pre)=3.26344, **C(row-pre)=3.26223**, D(col-post)=3.26440, E(col-pre-mlp)=3.26507. **Surprising row-vs-col INVERSION** (Δ=−1.08σ): under SOAP, col-mean direction already damped by eigenbasis rotation; row-mean targets per-output bias direction not absorbed by SOAP+RMSNorm. Three coherent contrasts: row>col, pre>post, all>mlp-only. Axis closed; mechanism note kept for future GC-on-Muon-with-different-baseline work. |
| **#714 edward** (poll #398) | clean-NEG | RMSNorm gain init mean=0.9 P2: μ_n=4=3.262818 (σ=0.001701, 1.51× ctrl variance). Misses OLD gate by +0.001553. Bimodal split (T2=3.26043 outlier good) consistent with σ_seed variance. Gain init axis closed; mean=1.0 default approximately optimal. |
| **#699 alphonse** (poll #378) | **MERGED** ✅ | μ_n=4=3.261221, −2.044mNat vs #571. Statsig 0.004088. ffs_mean=3025 (all 4 trials). μP 1/√L depth scaling for residual-proj wins. First post-#571 init-magnitude merge. New mandatory flag: --depth_init_mode musoft. |
| **#691 thorfinn** (poll #375) | clean-NEG | Per-group β1 stacked P2 μ_n=4=3.26246 (+0.001195 above old gate). Additive stacking non-linear. |
| **#687 askeladd** (poll #373) | clean-NEG | Atan2-AdamW P2 μ_n=4=3.264213. 6th/6 AdamW-kernel mechanisms exhausted. |
| **#722 fern** (poll #371) | clean-NEG | lm_head zero-init optimal. |


## Closed Axis Map (post-#714 closure)

**Optimizer algorithms** (8/8 AdamW-kernel modifications): all CLOSED.

**Schedule layer** (all 5 dims): ALL CLOSED.

**Per-group HPs**: LR (all groups), β1 (all groups + stacked), β2 (all groups), global ε — CLOSED. Per-group ε (#781) now in-flight on musoft baseline (rebased).

**Init magnitude**:
- lm_head (#722 CLOSED: zero uniquely optimal)
- residual-proj (#699 MERGED: musoft 1/√L wins)
- residual-proj magnitude multiplier (#785 P1 in-flight, alphonse α-sweep)
- gains (#714 CLOSED: identity init approximately optimal at n=4)
- embed (#706 pre-#699 P2 cleared OLD gate / missed NEW; **#706 P3 compound now in-flight**)
- transformations (#748 P2 in-flight on pre-#699 codebase)

**Novel Muon mechanisms**: GC (#756 CLOSED clean-NEG, row-vs-col inversion noted), adaptive-mu (#773 CLOSED clean-NEG, mechanism falsified), update-RMS-norm (#776 P1 in-flight), per-block mu-depth-scale (#800 P1 assigned), NS-WarmUp (#815 P1 assigned), **SignMuon (#823 P1 just assigned)**.


## Research Themes

**Post-#699 dominant theme:** μP depth scaling for residual paths is real and load-bearing. Two compound questions in flight:
1. **Magnitude axis: is musoft optimal at α=1.0 multiplier, or is α=1.5/2.0 better?** (#785 alphonse, P1 in-flight on musoft baseline)
2. **Do embed magnitude and residual musoft stack?** (#706 nezuko P3, in-flight on musoft baseline) — pre-#699 embed=0.1 was −2.5mNat below old baseline but only −0.5mNat below new baseline. Compound P3 will measure: additive / partially-redundant / competing.

**Edward closure clarifies init landscape:** With #714 closed, gain init joins lm_head init as boundary-optimum axes (default identity wins). The remaining open init axes are:
- residual-proj (merged, magnitude probe in #785)
- embed (compound P3 in #706)
- transformations (#748 P2 still in flight, pre-#699 codebase)

**Pre-#699 P2 results — generalization concern:** Two P2s (frieren #748, nezuko original) ran on stale codebase to honor the experimental contract. Pattern: if they clear OLD gate, send back for compound P3. If they miss OLD gate, close clean. Nezuko was the first such resolution (sent for P3). Frieren still pending.

**Next direction priorities (after current portfolio resolves):**
1. **Alphonse #785 outcome →** Localizes the residual-magnitude axis on musoft. If α=1.5 or α=2.0 wins, immediately compound with embed-std=0.1 (if nezuko's P3 also clears).
2. **Nezuko #706 P3 outcome →** Tells us if init-magnitude axes stack with musoft. If yes, the path forward is multi-axis stacking; if no, magnitude axes are subsumed by musoft.
3. **Novel Muon mechanisms (#776, #800, #815, #823)** all need to re-gate against 3.259221. Bar is harder. If any single cell shows >1σ below musoft baseline, escalate to P2. (#756, #773 now closed clean-NEG.)
4. **If 2+ axes merge:** assign a systematic 3-way cross-axis compound experiment (residual × embed × transform).

**Dead ends:** 8 AdamW-kernel replacements, all schedule modifications, per-group β1/β2, global ε, lm_head init, **RMSNorm gain init (NEW: #714)**.
