# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~22:50Z (poll #313)
- **🆕🆕 NEW BASELINE (PR #497 MERGED):** mu=3.266120, std=0.001747, n=6, ffs_mean=3087.5
  - **Mechanism: ns_iter=6 (Newton-Schulz 6 iterations) + soap_attn + lr_mlp=0.055 + WD ramp_down**
  - **New statsig rule:** `(3.266120 - mu) × √n ≥ 0.004`
  - n=4 gate: mu ≤ **3.264120** | n=6 gate: mu ≤ **3.264488** | n=8 gate: mu ≤ **3.264707**
  - *NOTE: all future PRs must include `--ns_iter 6` to compare against this baseline*
- **Previous baseline (PR #371):** mu=3.267948, std=0.000823 — still used for old Δσ comparisons on in-flight PRs


## 🔥🔥 Three gate-beating single-seed signals across orthogonal axes — TWO NOW IN P2

P2 status across the portfolio:

| PR | Cell | Config | val/loss | Δσ_n6 (σ=0.001747) | Margin vs n=4 gate | P2 Status |
|----|------|--------|---------:|--------------------:|--------------------:|-----------|
| #571 | D | lr_scalars=0.03 | **3.262962** | **−1.81σ** | beats gate by **0.001158** 🔥🔥 | **🔬 P2 n=4 IN-FLIGHT** |
| #565 | B | init_var_scale=1.0 (xavier) | 3.263870 | −1.29σ | beats gate by 0.000250 | **🔬 P2 n=4 IN-FLIGHT** (just sent back) |
| #556 | C | adam_eps=1e-6 | 3.263690 | −1.39σ | beats gate by 0.000430 | **🔬 P2 n=4 IN-FLIGHT** (Trial 0=3.26770 +0.90σ; Trials 1-3 pending) |

Under pure null with σ=0.001747, single-seed P(val ≤ 3.264120) ≈ 12.5%. Across ~30 cells tested in the current portfolio, expected gate-passers under null ≈ 3.8 — so 3 hits is **not surprising under noise alone**. But each lives on a mechanistically distinct axis (eps, init, scalar LR), with theoretical motivation. **All three now have P2 confirmations running concurrently.** Early signal from frieren P2 Trial 0 (3.26770, +0.90σ) suggests its single-seed signal was lucky-side noise — n=4 mean unlikely to clear gate.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status (poll #310) |
|------|---------|-----------|--------|
| #600 | alphonse | LM-head AdamW LR sweep (1/640/1/320ctrl/1/160/0.01/0.03) — 3rd hardcoded AdamW LR | **Cell A ctrl terminal at 3.26574** (−0.30σ, within ctrl noise — refactor no-op confirmed). Chain B→E should be running. |
| #620 | tanjiro | **NEW** Attention softmax scale sweep (0.0884/0.10/0.12ctrl/0.14/0.18) — hardcoded, never ablated | Just assigned (poll #313). SDPA scale=0.12 at line 414; standard 1/√128=0.0884. Tests whether softmax temperature is correctly tuned. |
| #571 | askeladd | AdamW scalar param LR sweep (RMSNorm gains) | **🔥🔥 ALL 5 CELLS TERMINAL. Cell D (0.03) = 3.262962 = STRONGEST single-seed in portfolio.** Sent back for P2 n=4 confirmation on Cell D. Full hump: A(0.01)=3.26523 −0.51σ, B(0.003)=+7σ, C(0.001)=+13σ DNF, D(0.03)=−1.81σ ✓gate, E(0.1)=+3.38σ. RMSNorm gains were under-tuned at 0.01. |
| #614 | nezuko | **NEW** Logit softcap value sweep (7.5/10/15ctrl/22.5/30) — hardcoded, never ablated | Just assigned (poll #311). Softcap at line 459 bounds logits to ±15; value untested. "Less intensity" theme predicts looser cap may help. |
| #565 | thorfinn | Init variance scale sweep — **P2 CONFIRMATION IN-FLIGHT** | All 5 cells terminal. Cell B (xavier var=1.0)=3.26387 beats n=4 gate by 0.000250 (narrowest of 3 P2s). Shape: D(0.10)=+3.31σ catastrophic, A(0.33)=−0.14σ ctrl, E(0.50)=+0.39σ, **B(1.0)=−1.29σ winner**, C(2.0)=+0.13σ. P2 n=4 fresh confirmation requested at var=1.0. |
| #556 | frieren | AdamW epsilon sweep — **P2 CONFIRMATION IN-FLIGHT** | P2 Trial 0 (`bfq43l07` --num_trials 4) terminal at val=3.26770 (+0.90σ). 3 more trials sequential. For n=4 mean to clear gate, remaining 3 must avg ≤3.26293 — unlikely given Trial 0. ETA terminal Trial 3: ~02:20 UTC May 21. |
| #581 | edward | Lookahead optimizer wrapper | **⚠️ Cell C terminal at 3.28116 (+8.6σ)** — Lookahead failing across all variants. A ctrl=3.26801, B(α=0.5 k=5)=3.27956 +10.5σ, C(α=0.5 k=10)=3.28116 +8.6σ. Cell D (α=0.3 k=5 gentler) running at ~9%. Pattern: every time-averaging wrapper fails on 3250-step horizon. Likely to close clean-NEG after D/E. |
| #594 | fern | Peak WD multiplier sweep (1.0/1.5/2.0ctrl/2.5/3.0) | A(ctrl 2.0)=3.26621 no-op, **B(peak_wd=1.0)=3.26874 +0.43σ** (slightly worse, within noise — lower peak WD doesn't help). Cell C (1.5) likely running. |


## Recent Closures

- **#566 nezuko embed_lr sweep** — CLOSED clean-neutral (poll #311). Cell E (1.0) at −0.62σ doesn't beat n=4 gate; plateau 0.3→1.0 is flat. Lower direction (0.05) catastrophic (+8.1σ), confirming sparse-gradient hypothesis for lower bound. embed_lr ctrl=0.3 confirmed robustly tuned. Cross-PR insight: askeladd #571 (scalars 3×) + this (embed hint 3.3×) both suggest AdamW group LRs slightly conservative; compound test post P2.
- **#552 alphonse LR warmup sweep** — CLOSED clean-NEG (poll #306). Monotonic worsening: even 2% warmup (~65 steps) costs +5.3σ vs new baseline. ffs slips 50 steps. Mechanism: Muon NS orthogonalization structurally caps update magnitude so warmup provides no safety; 3250-step horizon makes every early high-LR step load-bearing. LR-warmup axis closed.
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

**Key analytical questions for in-flight PRs:**
- **askeladd #571 scalar LR** 🔥🔥 **P2 IN-FLIGHT** (just sent back): Cell D (lr_scalars=0.03) at 3.262962 (Δ=−1.81σ, beats n=4 gate by 0.001158). All 5 cells terminal; P2 n=4 fresh confirmation requested on Cell D. 7.3 GPU-hours wall. Mechanism: RMSNorm gain LR was under-tuned at 0.01 → 3× higher allows gains to find optimal per-layer output scale faster. If P2 confirms: this would be the strongest single-axis improvement on the new baseline since the merge.
- **frieren #556 Adam eps P2** 🔬 IN-FLIGHT: P2 Trial 0 terminal at val=3.26770 (+0.90σ above baseline — NOT a strong showing). 3 remaining trials sequential within same `bfq43l07` (--num_trials 4). For n=4 mean to clear gate, trials 1-3 must average ≤3.26293; given Trial 0 was lucky-side of baseline rather than tracking the original Phase 1 Cell C (3.26369), full P2 likely falsifies the gate. Expected terminal: ~02:20 UTC May 21.
- **thorfinn #565 init variance** 🔬 P2 IN-FLIGHT: All 5 cells terminal; Cell B (xavier var=1.0) at 3.26387 passes gate by 0.000250 (narrowest margin). P2 n=4 confirmation requested. Lower bound D(0.10)=+3.31σ catastrophic firmly closes < 0.2.
- **tanjiro #620 attn scale** NEW: 5-cell sweep of attention softmax scale (hardcoded 0.12 at line 414, never ablated). Standard 1/√128=0.0884. Tests softmax temperature; interaction with "less optimizer intensity" theme (sharper = more intense). Assigned poll #313.
- **alphonse #600 lm_head LR**: Cell A ctrl terminal at 3.26574 (refactor no-op). Cells B-E chain (1/640, 1/160, 0.01, 0.03). **Pairs naturally with askeladd #571 Cell D win**: if scalar LR wants 3× more, lm_head LR may also benefit from 3-10× more.
- **nezuko #614 logit softcap** NEW: 5-cell sweep of softcap value (hardcoded 15 at line 459, never ablated). Tests "less optimizer-side intensity" (looser cap = more gradient signal at confident predictions) vs stability. Assigned poll #311. PR #614.
- **edward #581 Lookahead**: ⚠️ Failing across all variants. A ctrl=3.26801, B(α=0.5 k=5)=3.27956 +10.5σ, C(α=0.5 k=10)=3.28116 +8.6σ. Cell D (α=0.3 k=5) at step 1500 val=3.56 (clearly worse than ctrl at same point). Time-averaging mechanism axis closing clean-NEG.
- **fern #594 peak-WD**: A(2.0 ctrl)=3.26621, B(1.0)=3.26874 (+0.43σ slightly worse, within noise — lower peak WD doesn't help). Cell C (1.5) likely running. Axis looks ctrl-optimal so far.

**Emerging cross-PR insight — three orthogonal axes hitting the gate at n=1:**
1. **Adam eps** (frieren #556 Cell C: eps=1e-6 → 3.26369) — **P2 IN-FLIGHT**
2. **Init scale** (thorfinn #565 Cell B: xavier var=1.0 → 3.26387)
3. **Scalar LR** (askeladd #571 Cell D: lr_scalars=0.03 → 3.262962, **strongest**)

If two or more confirm at P2, a compound test becomes the next priority: do these axes stack additively, or do they overlap (e.g., higher scalar LR + higher eps both ease the AdamW Q regularization but redundantly)?

**What comes after current in-flight:**
- **Compound P2** — if askeladd #571 Cell D AND thorfinn #565 Cell B both confirm at P2, test joint setting (xavier var=1.0 + lr_scalars=0.03) as compound P2.
- **Muon momentum warmup** — separate from current mu=0.95 (ramp from 0 across run).
- **Depth-aware init (μP-style)** — extends thorfinn #565 init axis if global constant matters.
- **Tied embedding follow-up** — if tanjiro #596 finds a sweet spot LR, refine.
- **Lookahead wrapper mechanism likely closing** — edward #581 will join #517 as time-averaging closure.
- **LR schedule shape** — main-phase LR shape (cosine vs linear vs step) is the only unexplored schedule dimension.
- **NS axis is closed** (PR #518 mapped it) — don't return here.

**Key insights:**
- **New n=4 gate 3.264120 is very hard** — but the portfolio is generating gate-beating cells at the expected null rate, with several theoretically motivated.
- **In-flight PRs spanning multiple optimizer-internal axes** — eps, init, per-group LR — give us a natural compound experiment if two or more confirm.
- **"Less optimizer intensity" is not a universal theme** — askeladd #571 Cell D shows 3× HIGHER scalar LR helps. The theme applies to globally-coupled regularization (WD, NS), not per-parameter-group LR. Need to be precise.
- **Single-seed signals can be misleading**: 3 of ~30 cells beating the n=4 gate is consistent with pure noise (~12.5% per cell rate). P2 confirmation is essential before merging any.
- **lr_mlp axis fully mapped**: 0.050–0.075 sweep closed.
