# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-21 ~16:53Z (poll #345)
- **🆕🆕🆕 NEW BASELINE (PR #571 MERGED poll #321):** mu=3.263265, std=0.001123, n=4, ffs_mean=3043.75
  - **Mechanism: lr_scalars=0.03 + ns_iter=6 + soap_attn + lr_mlp=0.055 + WD ramp_down**
  - **New statsig rule:** `(3.263265 - mu) × √n ≥ 0.004`
  - n=4 gate: mu ≤ **3.261265** | n=6 gate: mu ≤ **3.261633** | n=8 gate: mu ≤ **3.261852**
  - *NOTE: all future PRs must include `--ns_iter 6 --lr_scalars 0.03` to compare against this baseline*
  - *GATE IS HARD: requires ~2σ improvement from new mu=3.263265 at n=4*
- **Previous baseline (PR #497):** mu=3.266120, std=0.001747, n=6 — used for old Δσ comparisons on in-flight PRs
- **Previous-previous baseline (PR #371):** mu=3.267948, std=0.000823


## P2 STATUS (poll #322)

⚠️ **New baseline (mu=3.263265) shifts the n=4 gate from 3.264120 → 3.261265 — a shift of ~1.6σ_new. All prior n=1 P1 winners except #571 now closed or below new gate.**

P2 status across the portfolio:

**vs new baseline (mu=3.263265, n=4 gate=3.261265):**

| PR | Cell | Config | val/loss (vs old) | vs NEW baseline (3.263265) | P2 Status |
|----|------|--------|---------:|---------------------------:|-----------|
| **#571** | **D** | **lr_scalars=0.03** | **3.263265 (n=4 mean, −1.63σ_old)** | **= new baseline** | **✅ MERGED (poll #321) — IS the new baseline** |
| #565 | B | init_var_scale=1.0 | 3.263870 (n=1, −1.29σ_old) | **+0.000605 ABOVE new baseline** | **❌ CLOSED clean-neutral (poll #322) — P2 math impossible** |
| #556 | C | adam_eps=1e-6 | 3.263690 (n=1, −1.39σ_old) | **+0.000425 above new baseline** | **❌ CLOSED clean-neutral (poll #318)** |

**Key implication:** New n=4 gate (3.261265) is ~2.0σ_new below new mu. For a single-seed n=1 result to be worth P2 confirmation, it must land near 3.260 or lower. This is a hard gate — screens only genuinely strong signals. No P2 confirms currently in flight — all attention is on P1 mechanism tests + targeted hyperparameter sweeps.


## Active WIP Portfolio (poll #345 — baseline mu=3.263265)

⚠️ **Gate reminder: all future PRs need ctrl cell ≈ 3.263265. n=4 gate = 3.261265. Strong P1 signals must land ≤ 3.260 to be worth P2 confirmation.**

| PR # | Student | Hypothesis | Status (poll #345) |
|------|---------|-----------|--------|
| **#699** | **alphonse** | **NEW (poll #345)** Depth-aware μP init for block residual paths — 5-cell: ctrl (zero-init) / μP soft (1/√L) / μP medium (1/L) / μP everywhere (all block 2D weights) / small-constant (1e-3) | Just assigned. Fresh INIT axis. Only prior init test was #565 (global magnitude). Residual-injection paths currently zero-init; this tests whether μP-style 1/√L or 1/L scaling is at least as good, or whether zero-init is uniquely load-bearing. Interacts with Muon spectral orthogonalization (init sets basin, Muon constrains update direction). |
| **#693** | **frieren** | **NEW (poll #343)** Muon momentum (mu) schedule sweep — cooldown decay | Assigned poll #343. Third time-varying Muon hyperparameter axis. Static mu=0.95 confirmed optimal in #508; time-varying never tested. 5-cell: A=const 0.95 ctrl / B=static 0.90 / C=static 0.98 / D=ramp_down 0.95→0.5 / E=ramp_down 0.95→0.0. |
| **#691** | **thorfinn** | **NEW (poll #342)** Per-group AdamW β1 sweep (embed/lm_head/scalars) | Assigned poll #342. First per-group β1 test since global mapping #537. 5-cell: A=global 0.8 ctrl / B=scalars 0.9 / C=scalars 0.7 / D=embed 0.9 / E=lm_head 0.9. |
| **#687** | **askeladd** | **NEW (poll #341)** Atan2-AdamW bounded SNR normalization (StableAdamW, Wortsman 2023) | Assigned poll #341. Cell A ctrl finished at 3.2632; Cell B running (step ~216). Replaces AdamW update with `(2/π)*atan2(m_hat, sqrt(v_hat))` — smooth-bounded [-1,+1]. Structurally orthogonal to all closed augmentation classes. |
| #659 | nezuko | Schedule-Free AdamW (Defazio 2024) — Polyak iterate averaging removes LR cooldown | 4 cells terminal: A=3.2615 (best, −1.47σ), B=3.3270 (+57σ), C=3.3321 (+59σ), D=3.3130 (+49σ). Cell E (no warmup) running. All terminal cells confirm clean-NEG. E still to confirm. |
| #671 | edward | Cautious AdamW (Liang 2024, arXiv:2411.16085) — mask updates where Adam step disagrees with current gradient | Assigned poll #333. 5-cell: A=ctrl / B=boolean / C=normalized / D=soft sigmoid / E=scalars-only. |
| #665 | tanjiro | NS iter SCHEDULE sweep — time-varying Newton-Schulz iteration count (5-cell) | Assigned poll #330. First time-varying NS schedule ever tested. |
| **#679** | **fern** | **NEW (poll #336)** LR cooldown SHAPE sweep (linear ctrl/cosine/quadratic/sqrt/step, fixed LR peak) | Assigned poll #336. 5-cell: linear(ctrl)/cosine/quadratic/sqrt/step. First LR cooldown shape axis test. |


## Recent Closures

- **#641 alphonse AdaBelief (Zhuang 2020, variance of g−m)** — CLOSED clean-NEUTRAL (poll #345). All 4 AdaBelief variants within ±1.5σ of AdamW ctrl (A=3.26388, B=3.26344, C=3.26438, D=3.26442, E=3.26491). B (eps=1e-10) nominally best at −0.4σ_single vs A — pure seed noise. Key findings: (1) variance-estimator (g² vs (g−m)²) is interchangeable at L=12 with Muon on 2D paths; (2) eps minimum at 1e-10 (paper default), not 1e-16 — fp32 clips at ~1e-12 so deeper eps gives no benefit; (3) eps=1e-6 monotonically worse (denominator dominates), confirming "denominator loosening" is a saturated axis. **6th augmentation-class closure** (and first clean-NEUTRAL, not clean-NEG). Alphonse reassigned #699 depth-aware μP init.

- **#649 frieren wd_scalars sweep** — CLOSED clean-NEUTRAL (poll #343). A/C/D/B cluster within ±1.8σ (wd=0 to 1e-2 all flat); E (wd=1e-1) catastrophic +8.59σ. Cooldown LR decay dominates mid-training WD shrinkage — D's mid-trajectory looked +5–15σ but terminal +1.02σ. **5-dimensional WD axis fully closed** (magnitude/floor/duration/shape/per-group). Frieren reassigned #693 Muon mu schedule.

- **#648 thorfinn per-block LR sweep** — CLOSED clean-NEUTRAL (poll #342). All 4 depth-aware schedules (B decay/C growth/D bottom_heavy/E top_heavy) underperform uniform LR (Cell A). Key findings: B≈C symmetry (+1.13σ vs +1.17σ) — bidirectionally bad, uniform LR is optimal. E (top_heavy) uniquely catastrophic (+3.32σ above baseline) vs D (bottom_heavy, +0.24σ) — boosting LR on late blocks destabilizes propagation hierarchy. Cell A = strongest post-#571 ctrl single-seed on record (3.26167, −1.42σ below baseline μ). Per-block LR axis CLOSED. Thorfinn reassigned #691 per-group AdamW β1 sweep.

- **#645 askeladd Adan (Xie 2022, gradient-difference 3-buffer)** — CLOSED clean-NEG (poll #341). Final ranking: A=3.26231 (ctrl) > E=3.26822 (+4.4σ_single) > B=3.27603 ≈ D=3.27611 (+11.4σ_single) > C=3.29233 (+25.9σ_single). Student caught 2 mechanism-changing bugs in original spec (β2 vs 1-β2 coefficient, step-1 prev_g init) via cross-check against sail-sg/Adan — rigor that kept the sweep interpretable. Cell-E diagnostic was clinical: tighter β1=0.90 (vs paper's 0.98) recovers most of the gap, confirming slow-EMA-horizon mismatch as dominant failure mode, not the gradient-difference mechanism itself. Cell-D (LR×2.0 ≈ Cell-B at LR×1.0) confirms Adan's `n_hat` denominator self-normalizes step magnitude — paper's "5-10× higher LR" regime cannot be reached by simple LR scaling at this horizon. **5th augmentation-class optimizer to fail clean-NEG** at 3250-step horizon (Lion #638, Lookahead #581, AdEMAMix #626, Schedule-Free-B #659, Adan #645). Askeladd reassigned #687 Atan2-AdamW — structurally orthogonal mechanism (bounded SNR normalization, not augmentation).

- **#635 fern WD schedule SHAPE sweep** — CLOSED clean-NEUTRAL (poll #336). Ranking: A ramp_down (3.26719) > D constant (3.27126, +2.33σ) > E ramp_up (3.27722, +5.74σ) ≈ B triangle (3.27746, +5.88σ) > C cosine_updown (3.28164, +8.27σ). Three key findings: (1) **Early WD is the dominant lever** (+5σ): schedules with zero WD during first ~30% (B, C, E) all fail; (2) **Time-decay vs flat (+2.3σ)**: ramp_down beats constant within the "have-early-WD" family; (3) **Mid-peak is WORST**: B/C both lose to E despite E having zero WD until later — peak-WD coinciding with LR-cooldown-transition is uniquely bad. Pre-sweep prediction that E (ramp_up) would be catastrophic (+15σ) was wrong; E tied triangle. All cells at OLD lr_scalars=0.01 (no merge candidate vs new baseline). **WD axis now fully closed** (magnitude #594 + floor #548 + duration #321 + shape #635). Fern reassigned LR cooldown SHAPE sweep (#679).
- **#626 edward AdEMAMix slow-EMA augmentation** — CLOSED clean-NEG (poll #333). All 5 cells monotonically hurt: A (α=0 ctrl no-op) +0.11σ_single vs old baseline 3.266120 (matches); B (α=2, β3=0.9999 paper defaults) +1.88σ_single vs A; C (α=5) +14.34σ_single; D (α=2, β3=0.999 faster slow-EMA) +32.65σ_single; E (α=10) +37.26σ_single. α-axis monotonic worsening (0→2→5→10); β3-axis hurts when faster (more slow-EMA contribution = more harm). **Joint closure with PR #581 Lookahead**: both "slow-signal" mechanisms — gradient-side (AdEMAMix) and parameter-side (Lookahead) — fail clean-NEG at this 3250-step horizon. AdamW dynamics here are robustly well-tuned and resistant to slow-signal augmentation; paper's claimed +20-50% sample efficiency requires the million-step horizon for slow-EMA accumulation to express. All cells used OLD lr_scalars=0.01 (Cell A at 3.26631 vs new baseline 3.263265 = +2.7σ_new gap explained). 3rd augmentation-based optimizer to fail clean-NEG (Lion #638, Lookahead #581, AdEMAMix #626). Edward reassigned Cautious AdamW (#671) — mechanistic *inverse*: instead of adding slow-EMA, REMOVES wrong-direction updates.
- **#620 tanjiro attention softmax scale sweep** — CLOSED clean-NEUTRAL (poll #330). Clean U-shape: ctrl=0.12 locally optimal in BOTH directions. Cells: A=0.12 ctrl 3.26518, B=0.0884 3.26888 (+3.3σ_new), C=0.10 3.26814 (+2.6σ_new), D=0.14 3.26799 (+2.5σ_new), E=0.18 3.26815 (+2.6σ_new). Symmetric regression confirms attn_scale=0.12 is a true local optimum on the attention-sharpness axis. Mechanistically tight: softer attention loses temperature precision; sharper attention saturates earlier and loses gradient flow. **Cross-axis read:** the "less optimizer intensity" theme that won on LR-scalars (PR #571) does NOT extend to attention temperature — attention-side scaling is qualitatively different from optimizer-side intensity. Refactor introducing the scaling parameter confirmed as a no-op at ctrl=0.12 (Cell A matches pre-refactor baseline within seed noise). Note: all cells predate PR #571 merge (lr_scalars=0.01 at launch) so all sit 1.7–3σ_new above current baseline 3.263265. attn_scale axis CLOSED. Tanjiro reassigned NS iter SCHEDULE sweep (#665).
- **#614 nezuko logit softcap value sweep** — CLOSED clean-NEG (poll #323). All 5 cells regress vs ctrl (softcap=15). Tight axis catastrophic (B=7.5 at +22σ_old, never reached target); upper axis plateau-shaped mild-NEG (C/D/E all ~+3σ_old). B→C ratio (~14×) is the nonlinear saturation signature — once cap < typical logit magnitudes, gradient clipping at confident logits collapses learning capacity. Loose axis benign-but-flat: no inflection from 22.5→30 means there's no looser regime that recovers ground. Softcap=15 is robustly tuned end-to-end. Cross-axis observation: "less optimizer intensity" theme does NOT transfer from optimizer-side levers (WD, NS) to loss-side levers (softcap) — different sensitivity classes. Logit softcap axis CLOSED. Nezuko reassigned Schedule-Free AdamW (#659).
- **#565 thorfinn init variance scale** — CLOSED clean-neutral (poll #322). P2 mathematically impossible vs new baseline mu=3.263265. Trial 0+1 mean was 3.265280; Trial 3 would have needed val/loss ≤ 3.249940 to clear new n=4 gate (3.261265) — that is ~11.9σ_new below new mu, impossible by any rational seed. Init variance magnitude axis CLOSED. Thorfinn reassigned to depth-aware per-block LR (#648).
- **#638 frieren Lion optimizer** — CLOSED clean-NEG (poll #322). Two independent failures: Cell C (lion_lr_scale=0.10) grad-norm=235k at step 16; Cell B (lion_lr_scale=0.01, 10× lower) FAILED at step 0 / relaunch grad-norm=233,763 at step 15. Lion is fundamentally incompatible with this architecture at any viable LR scale — sign-based update + embed_lr=0.3 produces unstable gradients regardless. Per Chen 2023 recipe Lion needs ~1000× lower LR + non-zero WD; that scale of retuning is outside the optimizer-replacement budget here. Lion axis CLOSED. Frieren reassigned to wd_scalars sweep (#649).
- **#571 askeladd lr_scalars sweep** — ✅ **MERGED NEW BASELINE (poll #321)**. n=4 mean=3.263265. All 4 seeds clear n=4 gate. Mechanism: RMSNorm gain LR under-tuned at 0.01 → 3× to 0.03 allows faster layer-scale convergence. New gate = 3.261265 (n=4). Follow-up: askeladd reassigned to Adan (#645).
- **#566 nezuko embed_lr sweep** — CLOSED clean-neutral (poll #311). Cell E (1.0) at −0.62σ doesn't beat n=4 gate; plateau 0.3→1.0 is flat. Lower direction (0.05) catastrophic (+8.1σ), confirming sparse-gradient hypothesis for lower bound. embed_lr ctrl=0.3 confirmed robustly tuned. Cross-PR insight: askeladd #571 (scalars 3×) + this (embed hint 3.3×) both suggest AdamW group LRs slightly conservative; compound test post P2.
- **#552 alphonse LR warmup sweep** — CLOSED clean-NEG (poll #306). Monotonic worsening: even 2% warmup (~65 steps) costs +5.3σ vs new baseline. ffs slips 50 steps. Mechanism: Muon NS orthogonalization structurally caps update magnitude so warmup provides no safety; 3250-step horizon makes every early high-LR step load-bearing. LR-warmup axis closed.
- **#581 edward Lookahead** — CLOSED clean-NEG (poll #315). Wrapper-averaging axis CLOSED. Cell E refutes "sync disrupts cooldown" hypothesis — base optimizer co-adapts to periodic resets; disabling sync mid-run worsens trajectory. Gradient-side follow-up: PR #626 AdEMAMix.
- **#556 frieren AdamW eps P2** — CLOSED clean-neutral (poll #318). n=4 mean=3.265823 (−0.17σ) fails both n=4 and +0.5σ borderline gates. Bimodal trial split (0/1 at +1σ, 2/3 at −1σ) averages to baseline. Adam eps axis flat across 8 decades. Follow-up: PR #638 Lion optimizer replacement.
- **#594 fern peak_wd_mult sweep** — CLOSED clean-neutral (poll #317). WD magnitude axis fully mapped. D (peak=2.5) barely flags −0.26σ (within noise). Lower peak hurts +1.5σ; current peak=2.0 is optimal. Follow-up #635 WD shape sweep assigned.
- **#596 tanjiro tied embedding** — CLOSED clean-NEG (poll #313). All 4 tied cells killed (lr 0.3→0.01). Root cause: init mismatch — tied uses embed's std=1 init for LM head → step-0 val≈23 vs untied zero-init → val≈10.8. Optimizer never recovers in 3250 steps. Tied axis closed at this budget/init.
- **#558 tanjiro Z-loss regularizer sweep** — CLOSED clean-NEG (poll #305). Monotonic worsening across 3 decades (1e-5 → 1e-4 → diverged). Mechanism: existing logit softcap already bounds logits to ±15, making z-loss fully redundant. Z-loss axis closed.
- **#548 fern WD floor in cooldown** — CLOSED clean-neutral (poll #303). WD floor=0 NOT load-bearing. LR=0 terminal is structurally load-bearing; WD=0 is incidental.
- **#537 edward Adam β1/β2 sweep** — CLOSED clean-neutral (poll #302). U-shaped response. Canonical AdamW (0.95,0.999) catastrophic. β1=0.8 / β2=0.95 confirmed optimal.
- **#551 askeladd Muon nesterov toggle** — CLOSED clean-NEG (poll #299). The `grad.lerp_(momentum, mu)` correction is load-bearing — orthogonalizing pure EMA discards informative current-step delta.
- **#521 nezuko gradient clipping** — CLOSED clean-NEG (poll #298). Monotonic worsening: tighter clip = strictly worse. NS is scale-invariant on Muon path; clipping kills Adam-path gradient magnitude.
- **#518 thorfinn NS poly coefs** — CLOSED clean-neutral (poll #297). NS-internal axis fully mapped; current (2, −1.5, 0.5) + ns_iter=6 is the optimum.
- **#517 tanjiro EMA / Polyak eval** — CLOSED — mechanism rejected (poll #294). Post-hoc eval averaging axis closed for 3250-step regime.
- **#509 frieren lr_mlp fine-scan** — CLOSED clean-neutral (poll #293). SOAP's preconditioner already saturates the headroom.
- **#508 alphonse Muon mu static sweep** — CLOSED clean-neutral (poll #291). Muon mu axis closed.
- **#504 fern LR floor sweep** — CLOSED clean-NEG (poll #289).
- **#497 askeladd P2 ns_iter=6** — ✅ **MERGED NEW BASELINE** (poll #290). mu=3.266120 (n=6).
- **#496 edward NS iter LOW sweep** — CLOSED clean-neutral (poll #287). Hard bf16 cliff below ns_iter=5.


## Research Themes

**NEW BASELINE: mu=3.266120 (PR #497 ns_iter=6). New n=4 gate: 3.264120.**

**"Less optimizer intensity" theme** confirmed on multiple axes:
- PR #371: WD ramp_down → 0 (less WD pressure at cooldown)
- PR #497: ns_iter=6 (fewer NS iters = less orthogonalization work per step)
- Both point to: reducing optimizer micro-aggression at the late/cooldown phase helps.

**Counter-evidence** — *not* every parameter wants less:
- askeladd #571 Cell B/C (lr_scalars=0.001, 0.003): catastrophic +7–13σ. RMSNorm gains NEED their current LR.
- askeladd #571 Cell D (lr_scalars=0.03): **3× HIGHER than ctrl beats baseline**. Some optimizer dials want MORE intensity, not less. The "less" theme is specific to globally-coupled regularization (WD, NS), not per-group LR.

**Key analytical questions for in-flight PRs (poll #333 — new baseline mu=3.263265):**

⚠️ **Gate recalibration:** With new baseline mu=3.263265, only results landing near 3.260 or below are worth P2 confirmation. The ctrl cell for all future PRs should be compared against 3.263265, not 3.266120.

- **edward #671 Cautious AdamW (NEW)**: 5-cell sweep. Mask updates where Adam step direction disagrees with current gradient (Liang 2024). Mechanistic *inverse* of AdEMAMix #626 (closed clean-NEG): instead of adding slow-EMA info, removes wrong-direction info. Cells: A=AdamW ctrl / B=boolean mask / C=normalized boolean / D=soft sigmoid / E=scalars-only. Tests whether filtering noisy disagreement coordinates helps at speedrun horizons.
- **tanjiro #665 NS iter SCHEDULE**: 5-cell sweep. First time-varying NS schedule ever tested: const6 ctrl / decay 6→3 / growth 3→6 / step-at-cooldown 6→3 / aggressive decay 6→2. Extends "less optimizer intensity late" theme to Muon polynomial depth.
- **nezuko #659 Schedule-Free AdamW**: 5-cell sweep. SF-AdamW removes LR cooldown via Polyak iterate averaging (Defazio 2024). Cell A AdamW ctrl crashed (infra). Cell B running at step 2101 with val/loss=3.629 — flagged eval-mode swap concern for student to verify.
- **thorfinn #648 per-block LR**: 5-cell static depth-aware LR multipliers on Muon-managed 2D weights (12 blocks): const ctrl / decay / growth / bottom_heavy / top_heavy. Cells running cleanly after shared-GPU contention cleared.
- **frieren #649 wd_scalars**: 5-cell sweep on per-group WD for scalar group: 0.0(ctrl) / 0.0001 / 0.001 / 0.01 / 0.1. Cell A ctrl done at 3.262853 (matches new baseline). Cell B (1e-4) running at step ~1555.
- **alphonse #641 AdaBelief**: AdaBelief variance of (g − m)² instead of g² (Zhuang 2020). Student caught baseline-drift issue and wired `--lr_scalars 0.03` into both ctrl and AdaBelief paths. AdamW ctrl arm crashing repeatedly (3 crashes at steps 450/603/1701) — student in crash-debug loop.
- **askeladd #645 Adan**: 3-buffer optimizer (Xie 2022). Student caught 2 mechanism-changing bugs in PR spec (β2 vs 1-β2 coefficient, step-1 prev_g init) via cross-check against official sail-sg/Adan code. Cell A AdamW ctrl ~91% done.
- **fern #635 WD shape**: A (ramp_down ctrl) 3.26719, B (triangle) 3.27746 +5.9σ_old, C (cosine_updown) 3.28164 +8.3σ_old, D (constant) running, E (ramp_up) queued. Within-PR ramp_down robustly dominant; all cells at OLD lr_scalars=0.01.

**Emerging cross-PR insight (poll #336) — #571 MERGED, 4 fresh-mechanism + 3 targeted-hp tests + LR cooldown shape (fern #679):**
1. **✅ Scalar LR** (askeladd #571, lr_scalars=0.03) — **MERGED NEW BASELINE (poll #321)** — n=4 mean=3.263265
2. **❌ Init scale** (thorfinn #565) — CLOSED poll #322; P2 math-impossible
3. **❌ Lion** (frieren #638) — CLOSED poll #322; twice-failed crashes
4. **❌ Logit softcap** (nezuko #614) — CLOSED poll #323; clean-NEG; tight catastrophic, loose plateau-flat
5. **❌ attn_scale** (tanjiro #620) — CLOSED poll #330; clean U-shape, ctrl=0.12 locally optimal both directions; "less intensity" theme doesn't extend to attention sharpness
6. **❌ AdEMAMix** (edward #626) — CLOSED poll #333; α-axis monotonic worse; joint closure with #581 Lookahead (slow-signal mechanisms fail at speedrun horizon)
7. **❌ Adam eps** (frieren #556) — CLOSED clean-neutral
8. **❌ Peak WD** (fern #594) — CLOSED clean-neutral
9. **❌ lm_head LR** (alphonse #600) — CLOSED clean-neutral (asymmetry: scalars take 3× but lm_head rejects 3×)
10. **❌ WD shape** (fern #635) — CLOSED clean-NEUTRAL (poll #336); ramp_down dominant; WD axis fully closed

**Active fresh-mechanism optimizer tests (poll #345 — 6 augmentation classes closed, 1 remain in flight + 1 new orthogonal mechanism + new INIT axis):**
- **#659 nezuko Schedule-Free AdamW** — Polyak iterate averaging (Defazio 2024) — Cells A/B/C/D all terminal (3.2615/3.3270/3.3321/3.3130); Cell E (no warmup) running. Clean-NEG outcome expected for all cells.
- **#671 edward Cautious AdamW** (poll #333) — masks updates where Adam step disagrees with current gradient (Liang 2024) — mechanistic *inverse* of AdEMAMix: removes wrong-direction info rather than adding slow-EMA info
- **#687 askeladd Atan2-AdamW** (poll #341) — smooth bounded normalization via `(2/π)*atan2(m_hat, sqrt(v_hat))` — STRUCTURALLY ORTHOGONAL to all 6 closed augmentation classes; replaces normalization kernel, not adds buffers
- **#699 alphonse Depth-aware μP init** (NEW poll #345) — μP-style 1/√L or 1/L init on block residual-injection paths — FRESH INIT AXIS (only #565 global magnitude tested before)

**Targeted hyperparameter sweeps on the new baseline:**
- **#665 tanjiro NS iter SCHEDULE** — time-varying ns_iter across training (decay/growth/step variants); extends "less optimizer intensity late" theme to Muon polynomial depth
- **#691 thorfinn per-group β1** — per-group AdamW β1 for embed/lm_head/scalars (5-cell: ctrl/scalars-0.9/scalars-0.7/embed-0.9/lmhead-0.9); first per-group β1 test since global mapping in #537; builds on post-#571 tripled-scalar-LR baseline
- **#693 frieren Muon mu schedule** — time-varying Muon mu during cooldown (5-cell: const-0.95 ctrl / static-0.90 / static-0.98 / ramp_down 0.95→0.5 / ramp_down 0.95→0.0); third time-varying Muon hyperparameter axis

**Mechanism class joint-closure — 6 AUGMENTATION-CLASS optimizers tested, 5 clean-NEG + 1 clean-NEUTRAL:**
| # | PR | Mechanism | Closure |
|---|----|-----------|----|
| 1 | #638 Lion | Sign-based momentum replacement | clean-NEG — incompatible at any viable LR |
| 2 | #581 Lookahead | Parameter-side slow averaging | clean-NEG — cooldown disrupted |
| 3 | #626 AdEMAMix | Gradient-side slow EMA | clean-NEG — slow EMA half-life >> training length |
| 4 | #659 SF AdamW | Polyak iterate averaging (LR removed) | clean-NEG (terminal) — cooldown is load-bearing (+49–60σ) |
| 5 | #645 Adan | Gradient-difference 3-buffer | clean-NEG — slow-EMA-horizon mismatch |
| **6** | **#641 AdaBelief** | **Variance estimator (g−m)²** | **clean-NEUTRAL — interchangeable with g² at L=12** |

**The pattern:** AdamW + WSD linear cooldown is well-tuned for 3250 steps. "Improved AdamW" variants from literature fail or are neutral. Cautious AdamW #671 tests the mechanistic inverse (filter wrong-direction updates). Atan2-AdamW #687 exits augmentation paradigm (replaces normalization kernel). Depth-aware init #699 exits optimizer axis entirely (INIT axis).

Cross-PR insight: AdamW per-group LR landscape **fully mapped** — embed (#566 flat), lm_head (#600 flat), scalars (#571 3× wins → MERGED). Per-group LR asymmetry: small 20K scalar group can take aggressive LR; 39M lm_head proj cannot. Init magnitude axis CLOSED. Lion axis CLOSED. If any of the 3 mechanism tests beats the new hard gate (3.261265), compound with lr_scalars=0.03 (already in baseline) becomes natural next step.

**What comes after current in-flight:**
- **LR cooldown shape** — fern #679 (poll #336). Most likely winner: cosine. If wins → P2 confirm. If linear dominates → LR schedule shape axis closed.
- **Mechanism compound** — if any of {SF #659 Cell E, Cautious #671, Atan2-AdamW #687} beats new gate 3.261265, compound with lr_scalars=0.03 (already in baseline).
- **Fine lr_scalars scan** — {0.015, 0.02, 0.025, 0.03ctrl, 0.04, 0.05} to check if 0.03 is the true optimum.
- **Depth-aware init follow-up** — if #699 closes neutral: next is embedding init magnitude (currently N(0,1) unscaled, vs GPT-2's 0.02 — never tested). If #699 shows any non-ctrl cell > 0.5σ better: finer sweep of the winning depth scale.
- **Per-group β1** — thorfinn #691 in flight. After closure: next per-group axis candidate is β2 (currently uniform 0.95 across all 3 AdamW groups).
- **Muon mu schedule** — frieren #693 in flight. Third time-varying Muon hp axis.
- **NS iter schedule** — tanjiro #665 in flight.
- **Cooldown_frac axis CLOSED** — PR #457 confirmed U-shape minimum at 0.7.
- **NS axis is closed** — PR #518 mapped it, PR #461 confirmed ns_iter=6 is optimal.
- **Muon mu axis is closed** — PR #508 confirmed mu=0.95 optimal.
- **Init variance magnitude axis CLOSED** — thorfinn #565 (poll #322).
- **Lion optimizer axis CLOSED** — frieren #638 (poll #322), incompatible at viable LR scale.
- **Logit softcap axis CLOSED** — nezuko #614 (poll #323); tight catastrophic, loose flat-plateau, ctrl=15 robustly tuned.
- **Attention softmax scale (constant) axis CLOSED** — tanjiro #620 (poll #330); clean U-shape, ctrl=0.12 locally optimal both directions.
- **AdEMAMix slow-EMA augmentation axis CLOSED** — edward #626 (poll #333); all α∈{0,2,5,10} monotonically worse; joint closure with PR #581 Lookahead (slow-signal mechanisms structurally incompatible with 3250-step regime).
- **WD axis FULLY CLOSED** — magnitude #594 (peak=2.0) + floor #548 (floor=0.0) + duration #321 (cooldown_frac=0.7) + shape #635 (ramp_down dominant, poll #336). All four WD dimensions mapped. ramp_down is robustly optimal.

**Key insights:**
- **New n=4 gate 3.264120 is very hard** — but askeladd #571 D shows a real effect can confirm at P2.
- **P2 differential picture is informative**: 3 single-seed n=1 winners are spreading into 1 strengthening, 1 weakening, 1 closing. Confirms the "lucky-side noise" floor at ~12.5% per cell, while real effects (scalar LR) survive replication.
- **"Less optimizer intensity" theme refinement**: WD has TWO directions — fern #594 Cell D (peak_wd=2.5, more WD intensity) flagging −0.5σ contradicts PR #371 ramp_down direction (less WD). Possible reconciliation: ramp DOWN matters (so WD tapers), but PEAK can go higher because tapering still ends at 0.6× by run end.
- **lr_mlp axis fully mapped**: 0.050–0.075 sweep closed.
