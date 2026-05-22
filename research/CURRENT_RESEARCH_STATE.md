# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-22 ~22:05Z (poll #465)

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)
- *Gate requires ~2σ_single improvement — significantly harder than pre-#699 gate*

**What changed in #699:** Block residual-injection paths (`blocks.*.attn.proj.weight`, `blocks.*.mlp.proj.weight`) now initialized to N(0, sqrt(0.33)/sqrt(fan_in×L)) ≈ N(0, 0.006) instead of zero. μP 1/√L depth scaling provides non-zero starting basis for gradient flow through each block from step 1.

## Active WIP Portfolio (poll #465)

8 PRs in flight; no idle students:

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#800** | **edward** | Per-block depth-dependent Muon momentum (`--mu_depth_scale`) | **Assigned poll #399.** 5 cells: A=ctrl mu=0.95, B=α=0.5, C=α=1.0, D=α=2.0, E=inverse. Prediction: B wins (gentle depth taper). Kill-switch: B > A + 50 ffs → close. ETA ~9h from assignment. |
| **#840** | **nezuko** | Muon-AdEMAMix — dual slow/fast momentum before NS ortho (Pagliardini et al. 2409.03137) | **Assigned poll #465.** 5 cells: A=ctrl, B=β₃=0.99/α=0.3 all (primary), C=β₃=0.999/α=0.3, D=β₃=0.99/α=1.0, E=β₃=0.99/α=0.3 MLP-only. Prediction: B > C > D > E > A. Kill: B val/loss > 3.265 at step 1000. ETA ~9h. |
| **#824** | **frieren** | Polar Express — minimax-optimal per-iter Newton-Schulz coefficients | **Assigned poll #438.** 5 cells: A=ctrl fixed NS, B=PE default 6-iter, C=PE pure 6-iter, D=PE default 4-iter, E=PE default 8-iter. Prediction: B > C > A > D > E. Kill: B val/loss > 3.264 at step 1000. ETA ~9h from assignment. |
| **#815** | **tanjiro** | NS-WarmUp — sequential Newton-Schulz iteration ramp-up | **Assigned poll #418.** 5 cells: A=ctrl ns_iter=6, B=warmup_steps=500 start=2 (primary), C=300/start=3, D=1000/start=2, E=500/start=1 (aggressive). Prediction: B > C > A > D > E. Kill at val/loss>3.32 step 1000. ETA ~9h from assignment. |
| **#823** | **fern** | SignMuon — sign-transform Nesterov momentum before NS ortho | **Assigned poll #434.** 5 cells: A=ctrl, B=sign MLP-only, C=sign all, D=sign all + lr_mlp 0.06, E=sign all + ns_iter 4. Prediction: D > C > B > E > A. Kill: Cell B <0.001 improvement vs A → close. ETA ~9h from assignment. |
| **#826** | **askeladd** | Lookahead outer slow-weights wrapper (Zhang et al. NeurIPS 2019) | **Assigned poll #439.** 5 cells: A=ctrl, B=k=5 α=0.5 all (primary), C=k=10 α=0.5, D=k=5 α=0.8, E=k=5 α=0.5 Muon-only. Prediction: B > C > D > A ≈ E. Kill: B val/loss >3.265 step 1000. ETA ~9h from assignment. |
| **#781** | **thorfinn** | Per-group AdamW ε sweep (sparsity asymmetry) | **All 5 cells done (Cell E W&B finished ~21:38Z, terminal post pending).** Best Cell B (1e-8)=3.26046 (−1.28σ_single; ~7.5% P2 gate-clearance odds). Decision TBD on terminal post: likely close clean-NEG. |
| **#785** | **alphonse** | Residual-proj init magnitude α∈{0.5/0.75/1.0/1.5/2.0} | **P2 in flight** (sent back poll #460). α=0.50 P1 best at 3.25978 (−2.43σ_single); P2 n=4 group `resid-alpha-P2-a050-n4`. ETA ~03:40Z. |

## Recent Closures

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#706 nezuko** (poll #465) | clean-NEG (subsumed) | Embed-init std=0.1 compound P3 (musoft×embed). μ_n=4=3.261093 (−0.11σ_seed, parity). P3 mean +0.39 mNat ABOVE P2 pre-#699 mean. Both mechanisms target early-step gradient stress in embed subspace → substitutes, not stackers. musoft dominates. Init-magnitude axis for embed fully exhausted. |
| **#776 askeladd** (poll #439) | clean-NEG | Muon post-NS update RMS-clamp. All 5 cells monotonically worse: A(ctrl)=3.26279, B(0.25)=3.27382, C(0.50)=3.27953, D(1.00)=3.28378, E(2.00)=3.28722. No interior optimum. Slope decay (halves per doubling) shows operational baseline RMS already well below 0.25 — clamp inflates step rather than constrains. Refactor neutrality (Cell A) confirmed. Axis closed. |
| **#748 frieren** (poll #438) | clean-NEG | Q/K/V + MLP fc_in transform ×2.0, n=4: μ=3.261472 (+0.000690 above close threshold 3.260783). ×2.0 transform init does NOT stack with musoft (#699). σ_single=0.000944 (tighter than published). Asymmetric finding preserved: smaller magnitudes (×0.5, ×0.1) catastrophically worse (+7.9σ, +8.7σ); larger within noise of ctrl. Transform-init axis closed; current default robustly near optimum. |
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

**Per-group HPs**: LR (all groups), β1 (all groups + stacked), β2 (all groups), global ε — ALL CLOSED. Per-group ε (#781 terminal pending, all 5 cells done — decision TBD, likely close clean-NEG).

**Init magnitude**:
- lm_head (#722 CLOSED: zero uniquely optimal)
- residual-proj (#699 MERGED: musoft 1/√L wins)
- residual-proj magnitude multiplier (**#785 P1 terminal poll #460**, sub-canonical α=0.50 surprise winner at −2.43σ_single but +0.94σ above n=4 gate; **P2 n=4 on α=0.50** sent back)
- gains (#714 CLOSED: identity init approximately optimal at n=4)
- embed (**#706 CLOSED clean-NEG poll #465, subsumed by musoft**; std=0.1 mechanism real but redundant with musoft residual-stream calming)
- transformations (#748 CLOSED clean-NEG: ×2.0 does not stack with musoft; smaller-magnitude catastrophically worse, larger-within-noise)

**Novel Muon mechanisms**: GC (#756 CLOSED), adaptive-mu (#773 CLOSED), update-RMS-norm (#776 CLOSED), per-block mu-depth-scale (#800 P1 in-flight), NS-WarmUp (#815 P1 in-flight), SignMuon (#823 P1 in-flight), Polar Express polynomial (#824 P1 in-flight), **Muon-AdEMAMix dual slow EMA (#840 P1 new — gradient memory horizon)**.

**Outer-loop mechanisms**: Lookahead (#826 P1 in-flight — operates outside NS/SOAP/Nesterov pipeline entirely).

**NS polynomial axis:** Fixed coefficients (a=2, b=−1.5, c=0.5) vs per-iteration minimax-optimal (Polar Express). Mechanistically distinct from #815 (iteration count ramp), #823 (NS input conditioning), #776 (NS output scaling).


## Research Themes

**Post-#699 dominant theme:** μP depth scaling for residual paths is real and load-bearing.
- **Surprising α<1 signal:** #785 alphonse P1 found α=0.50 best at −2.43σ_single — musoft may over-initialize by ~2×. P2 n=4 in flight.
- **Subsumption confirmed:** #706 nezuko P3 (μ=3.261093, parity) shows embed-init and musoft target same mechanism; axes exhaust each other.

**Next direction priorities:**
1. **Alphonse #785 P2 outcome (ETA ~03:40Z) →** If α=0.50 n=4 clears 3.259221, MERGE → sweep α<0.5 (0.25, 0.35, 0.40). If misses → magnitude-multiplier axis closed.
2. **Novel Muon mechanisms (#800, #815, #823, #824, #840):** Bar is 3.259221. Any single cell showing >1σ below baseline escalates to P2. Lookahead (#826) is first outer-loop axis tested.
3. **Polar Express (#824):** If B/C win → merge and test ns_iter=4 for efficiency. If all miss → NS polynomial coefficients axis closed.
4. **thorfinn #781 terminal:** All 5 cells done. Best B (1e-8)=3.26046 at ~7.5% P2 gate-clearance odds. Decision on post pending; likely close clean-NEG (per-group AdamW ε axis fully explored).
5. **Muon-AdEMAMix (#840):** First gradient-memory-horizon test inside Muon's momentum step. Dual-EMA (β₃=0.99) mixed before NS orthogonalization; distinct from all in-flight Muon mods.

**Dead ends:** 8 AdamW-kernel replacements, all schedule modifications, per-group β1/β2, global ε, lm_head init, RMSNorm gain init (#714), transform init magnitude (#748), post-NS update RMS-clamp (#776), **embed init magnitude (#706, subsumed by musoft)**.
