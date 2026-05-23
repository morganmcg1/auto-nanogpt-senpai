# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-23 ~04:00Z (poll #483)

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)
- *Gate requires ~2σ_single improvement — significantly harder than pre-#699 gate*

**What changed in #699:** Block residual-injection paths (`blocks.*.attn.proj.weight`, `blocks.*.mlp.proj.weight`) now initialized to N(0, sqrt(0.33)/sqrt(fan_in×L)) ≈ N(0, 0.006) instead of zero. μP 1/√L depth scaling provides non-zero starting basis for gradient flow through each block from step 1.

## Active WIP Portfolio (poll #483)

8 PRs in flight; askeladd re-assigned Orthogonal Init (#872) after #826 Lookahead closed clean-NEG:

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#872** | **askeladd** | Orthogonal Init for Muon-targeted body weights — init *shape* axis | **Assigned poll #483.** 5 cells: A=ctrl, B=orth non-resid auto-gain ★ PRIMARY, C=orth gain=1.0, D=orth depth-scaled gain=0.006, E=orth ALL body 2D (overrides musoft). Mechanism: NS targets orthogonal manifold; starting from orthogonal weights means step-1 NS is identity-like, no spectral correction needed. Kill: B val >3.265 step 1000. ETA ~9h. |
| **#867** | **thorfinn** | Pre-NS Cautious Muon — grad-agreement mask BEFORE NS orthogonalization | **Assigned poll #479.** 5 cells: A=ctrl, B=pre-NS no-rescale ★ PRIMARY, C=pre-NS+rescale, D=pre-NS MLP-only, E=pre-NS + lr_mlp 0.060. Mechanism: NS re-orthogonalizes masked buffer → spectral budget preserved (unlike #844 post-NS). Kill: B val >3.265 step 1000. Cell A step ~1400. |
| **#859** | **frieren** | GrokFast-Muon — amplify slow-frequency gradient EMA before Nesterov step | **Assigned poll #477.** 5 cells: A=ctrl, B=λ=1.0/α=0.98 ★ PRIMARY, C=λ=0.5/α=0.98, D=λ=2.0/α=0.98, E=λ=1.0/α=0.99. Cell A step ~3200, near terminal. |
| **#855** | **tanjiro** | Schedule-Free Muon — Polyak-averaged iterate evaluation (sf_beta sweep) | **Assigned poll #476.** 5 cells: A=ctrl, B=β=0.99 ★ PRIMARY, C=β=0.97, D=β=0.95, E=β=0.995. Cell A finished val=3.262256 ffs=3050; Cell B starting. |
| **#850** | **edward** | Bias-Corrected Muon — Adam-style 1/(1-β^t) debiasing of Nesterov buffer before NS ortho | **Assigned poll #472.** C1=3.26260 (ctrl parity), C2=3.26127 (≈baseline), C3 step ~430. |
| **#840** | **nezuko** | Muon-AdEMAMix — dual slow/fast momentum before NS ortho (Pagliardini et al. 2409.03137) | **PROMISING.** Cell A ctrl=3.26123, Cell B β₃=0.99/α=0.3=**3.26029** (−1.57σ_single, strongest n=1 signal in flight). Cell C β₃=0.999 step ~2900. Awaiting Cells C/D/E terminal. |
| **#823** | **fern** | SignMuon — sign-transform Nesterov momentum before NS ortho | Cell A n=4 mean=3.261745 (parity); Cell B MLP-only trial 2/4 running. Long-runner (~25h total). |
| **#785** | **alphonse** | Residual-proj init magnitude α=0.50 P2 n=4 confirm | Trial 4 running step ~11800/13003. 3-trial mean=3.26147. **Trending clean-NEG** (trial 4 would need <3.252 to clear n=4 gate — impossible). ETA ~04:30Z. |

## Recent Closures

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#826 askeladd** (poll #483) | clean-NEG | Lookahead outer wrapper. All active cells (B/C/E) harmful: +0.012/+0.017/+0.009 above ctrl. Only D (α=0.8 ≈ no-op) reaches parity. Mechanism: outer-loop averager adds bias drag on well-conditioned Muon+SOAP+NS trajectory. **2nd outer-wrapper closure (joins #844).** Pattern: outer-loop modifications to Muon are systematically negative. |
| **#844 thorfinn** (poll #479) | clean-NEG | Cautious Muon post-NS sign-agreement mask. **A=3.26058 (ctrl parity), B=3.28395 (+38.3σ_single catastrophic). C/D/E gated.** Mechanism (student's analysis): (1) NS produces 35-40% sign-disagreement with raw gradient as a *structural* feature, not noise; (2) Rescale-to-preserve-Frobenius (×1.6) destroys NS's spectral bound; (3) Net regression toward signed-SGD on Frobenius budget, undoing NS's gain. cautious_kept rates 0.635 (MLP) / 0.610 (attn) mean, rising 0.53→0.67 over training. Distinct from #823 SignMuon (sign BEFORE NS preserves spectral). **Key insight:** post-NS modifications that break spectral budget are destructive — pre-NS is the correct intervention point for sign/mask operations. Pre-NS Cautious assigned as #867. |
| **#824 frieren** (poll #477) | clean-NEG | Polar Express per-iter minimax NS coefficients. **A=3.26105/3025, B=3.26172/3050, C=3.26302/3050. Monotonic A<B<C at all 26 checkpoints. D/E gated correctly.** Mechanism: SOAP preconditioning of attention gradient already compresses the SV spectrum before NS. Fixed (2,−1.5,0.5) is well-matched to a pre-shaped spectrum; PolarExpress's minimax polynomial is tuned for raw gradient spectrum (wrong problem). `pure` variant worse than `default` → safety knobs not the bottleneck. NS polynomial-coefficient axis closed. |
| **#815 tanjiro** (poll #476) | clean-NEG | NS-WarmUp ns_iter ramp-up. **Hypothesis falsified — A(ctrl) wins both val/loss AND ffs.** Observed A > C > B ≈ D > E (predicted B > C > A > D > E). E (start=1 most aggressive) worst at +0.00735 val. Mechanism: at init, low ns_iter concentrates noise in random top SVs of essentially-random gradient. Cell A replicates baseline (3.26137 vs 3.26122, +0.00015 within σ_single). NS-iter-count temporal-schedule axis closed at fixed LR. Combined with #824 Polar Express, NS-side temporal-schedule family is closed. |
| **#800 edward** (poll #472) | clean-NEG | Per-layer depth-tapered Muon momentum (mu_depth_scale). Best A(ctrl)=3.26149 ffs=3025 (clean wrapper). B/C/D monotonic harm in α: ffs +50/+100/+150, Δval +7.9σ/+16.1σ/+23.4σ. E (inverse) lands at D's value: **+23.8σ**. **Direction-symmetric harm** — heterogeneous μ across body layers is rejected regardless of which layers are low. musoft mechanism transfer FAILS: depth-aware init helped because it perturbs forward-pass scale; depth-aware momentum hurts because NS already normalizes gradient magnitudes globally. Axis closed; block-type-specific μ unlikely to recover given heterogeneity-itself-harms signature. |
| **#781 thorfinn** (poll #467) | clean-NEG | Per-group AdamW ε (embed/lm_head/scalars 3-way split). Best B (eps_embed=1e-8)=3.26046 (−0.64σ_single, ffs=3025). B/C plateau around 1e-8; E (1e-9) flat with A; D (asymmetric lm_head=1e-11) loses +1.48σ, ffs=3050. No cell clears n=1 P2 trigger 3.259221. Per-group AdamW HP family fully exhausted. Refactor (3-way AdamW split) preserved in codebase as reusable lever. |
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

**Per-group HPs**: LR (all groups), β1 (all groups + stacked), β2 (all groups), global ε, per-group ε (#781 CLOSED clean-NEG poll #467) — **ALL CLOSED. Per-group AdamW HP family fully exhausted.**

**Init magnitude**:
- lm_head (#722 CLOSED: zero uniquely optimal)
- residual-proj (#699 MERGED: musoft 1/√L wins)
- residual-proj magnitude multiplier (**#785 P1 terminal poll #460**, sub-canonical α=0.50 surprise winner at −2.43σ_single but +0.94σ above n=4 gate; **P2 n=4 on α=0.50** sent back)
- gains (#714 CLOSED: identity init approximately optimal at n=4)
- embed (**#706 CLOSED clean-NEG poll #465, subsumed by musoft**; std=0.1 mechanism real but redundant with musoft residual-stream calming)
- transformations (#748 CLOSED clean-NEG: ×2.0 does not stack with musoft; smaller-magnitude catastrophically worse, larger-within-noise)

**Novel Muon mechanisms**: GC (#756 CLOSED), adaptive-mu (#773 CLOSED), update-RMS-norm (#776 CLOSED), per-block mu-depth-scale (#800 CLOSED), **NS-WarmUp (#815 CLOSED — low ns_iter at init amplifies noise)**, SignMuon (#823 P1 in-flight — sign BEFORE NS), **Polar Express polynomial (#824 CLOSED — SOAP pre-shapes gradient spectrum, minimax coefficients solve wrong problem)**, Muon-AdEMAMix dual slow EMA (#840 P1 in-flight), **post-NS Cautious mask (#844 CLOSED poll #479 — rescale destroys NS spectral budget; +38σ harm)**, Bias-Corrected Muon pre-NS buffer debiasing (#850 P1 in-flight; C1 ctrl done at 3.26260), Schedule-Free Muon Polyak iterate eval (#855 P1 in-flight), GrokFast-Muon slow-frequency gradient amplification (#859 P1 in-flight), **Pre-NS Cautious Muon grad-agreement mask (#867 P1 in-flight — tests #844 follow-up at correct pipeline stage)**.

**Outer-loop mechanisms**: Lookahead (#826 P1 in-flight — operates outside NS/SOAP/Nesterov pipeline entirely).

**NS polynomial axis:** CLOSED (#824). Fixed (2,−1.5,0.5) already optimal under SOAP+6-iter stack. Combined with #815 (iter ramp), full NS parameter space exhausted.

**New direction (frieren #859):** GrokFast-Muon — gradient frequency domain. Amplify slow EMA of gradients before Nesterov step. Tests whether Muon's momentum can be steered toward generalizing directions via frequency separation (λ=1.0, α=0.98).


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

**Outer-loop mechanisms**: **Lookahead (#826 CLOSED poll #483 — outer averager adds bias drag on well-conditioned Muon trajectory; only α=0.8 no-op reaches parity)**, post-NS Cautious rescale (#844 CLOSED — destroys NS spectral budget). **Pattern: outer-loop wrappers are systematically negative on this well-tuned baseline.**

**Init shape axis**: Orthogonal init for Muon-targeted weights (#872 in-flight poll #483 — first test of init *structure* vs Gaussian, distinct from closed magnitude axis).

**Dead ends:** 8 AdamW-kernel replacements, all schedule modifications, per-group β1/β2, global ε, lm_head init, RMSNorm gain init (#714), transform init magnitude (#748), post-NS update RMS-clamp (#776), embed init magnitude (#706, subsumed by musoft), per-group AdamW ε (#781), per-layer Muon momentum heterogeneity (#800), NS-iter temporal-schedule (#815), NS polynomial coefficients (#824), **post-NS sign/mask modifications on Muon (#844 — rescale breaks spectral budget)**, **Lookahead outer wrapper (#826 — outer averager destructive on well-conditioned trajectory)**.
