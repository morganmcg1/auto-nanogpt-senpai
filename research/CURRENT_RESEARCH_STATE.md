# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~23:15Z (poll #314)
- **🆕🆕 NEW BASELINE (PR #497 MERGED):** mu=3.266120, std=0.001747, n=6, ffs_mean=3087.5
  - **Mechanism: ns_iter=6 (Newton-Schulz 6 iterations) + soap_attn + lr_mlp=0.055 + WD ramp_down**
  - **New statsig rule:** `(3.266120 - mu) × √n ≥ 0.004`
  - n=4 gate: mu ≤ **3.264120** | n=6 gate: mu ≤ **3.264488** | n=8 gate: mu ≤ **3.264707**
  - *NOTE: all future PRs must include `--ns_iter 6` to compare against this baseline*
- **Previous baseline (PR #371):** mu=3.267948, std=0.000823 — still used for old Δσ comparisons on in-flight PRs


## 🔥🔥 Three gate-beating single-seed signals across orthogonal axes — ALL THREE NOW IN P2 WITH TRIAL DATA

P2 status across the portfolio (poll #314 update):

| PR | Cell | Config | val/loss | Δσ_n6 (σ=0.001747) | Margin vs n=4 gate | P2 Status (Trials Done) |
|----|------|--------|---------:|--------------------:|--------------------:|-----------|
| #571 | D | lr_scalars=0.03 | **3.262962** | **−1.81σ** | beats gate by **0.001158** 🔥🔥 | **🔬 P2 Trial 0 = 3.26347 (−1.52σ, clears gate by 0.000650)** — Trial 1 running ~step 200. ON TRACK. |
| #565 | B | init_var_scale=1.0 (xavier) | 3.263870 | −1.29σ | beats gate by 0.000250 | **🔬 P2 Trial 1 running at step 1454**, val trajectory tracks original Cell B exactly. Healthy. |
| #556 | C | adam_eps=1e-6 | 3.263690 | −1.39σ | beats gate by 0.000430 | **🔬 Trial 0=3.26770 (+0.90σ), Trial 1=3.26788 (+1.01σ), Trial 2 running.** Mean(0,1)=3.26779. For n=4 gate, mean(2,3) must be ≤ 3.26045 — mathematically very unlikely. Likely close clean-neutral. |

Under pure null with σ=0.001747, single-seed P(val ≤ 3.264120) ≈ 12.5%. Across ~30 cells tested in the current portfolio, expected gate-passers under null ≈ 3.8 — so 3 hits is **not surprising under noise alone**. But each lives on a mechanistically distinct axis (eps, init, scalar LR), with theoretical motivation.

**P2 differential picture emerging:**
- **askeladd #571 D**: Trial 0 reproduces single-seed signal (−1.52σ vs −1.81σ original); 0.29σ_single seed variation, consistent with real underlying effect. If trials 1-3 maintain similar performance, P2 mean clears gate.
- **frieren #556 C**: Trial 0+1 both regressing toward baseline mean (+0.96σ avg). The W-shaped Phase 1 profile (C wins, but D=1e-12 also wins; B=1e-8 between them loses) was classic noise pattern; P2 likely confirms axis is flat clean-neutral.
- **thorfinn #565 B**: Trial 1 in progress, no terminal yet. Margin is the narrowest (0.000250 vs gate), most sensitive to seed variation. Wait for terminal.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status (poll #314) |
|------|---------|-----------|--------|
| #600 | alphonse | LM-head AdamW LR sweep (1/640/1/320ctrl/1/160/0.01/0.03) — 3rd hardcoded AdamW LR | A(1/320 ctrl)=3.26574 no-op ✓, **B(1/640)=3.26809 +1.13σ** (lower LR hurts). Cell C (1/160=0.00625) running ~step 110/3250. D (0.01) and E (0.03) pending. Pairs with askeladd #571 D win — if upward direction wins here too, AdamW group LR theme strengthens. |
| #620 | tanjiro | Attention softmax scale sweep (0.0884/0.10/0.12ctrl/0.14/0.18) — hardcoded, never ablated | Assigned poll #313. **0 student comments yet — fresh.** Student should start Cell A (ctrl) for refactor check. |
| #571 | askeladd | AdamW scalar param LR sweep (RMSNorm gains) — **🔬 P2 IN-FLIGHT** | **P2 Trial 0 = 3.26347 (−1.52σ, clears gate by 0.000650).** Trial 1 running step ~200. ON TRACK — variation between Cell D (−1.81σ) and Trial 0 (−1.52σ) is 0.29σ_single, well within seed noise; real effect tracking. If trials 1-3 maintain, P2 confirms strongest signal in portfolio. |
| #614 | nezuko | Logit softcap value sweep (7.5/10/15ctrl/22.5/30) — hardcoded, never ablated | Assigned poll #311. **0 student comments yet — fresh, stale_wip flag is mechanical.** Ack'd by advisor. Student should start Cell A ctrl. |
| #565 | thorfinn | Init variance scale sweep — **🔬 P2 IN-FLIGHT** | P2 Trial 1 (`dp592oyk`) running at step 1454/3250, val trajectory matches original Cell B exactly at every milestone. Healthy. ETA Trial 1 terminal ~23:25 UTC; full P2 terminal ~04:25 UTC May 21. Margin is narrowest (0.000250 vs gate). |
| #556 | frieren | AdamW epsilon sweep — **🔬 P2 IN-FLIGHT** | **Trial 0=3.26770 (+0.90σ), Trial 1=3.26788 (+1.01σ), Trial 2 running step ~200.** Mean(0,1)=3.26779. For n=4 gate, mean(2,3) must be ≤3.26045 — math gate effectively closed. Likely closes clean-neutral after Trial 3 (ETA ~02:20 UTC May 21). |
| #581 | edward | Lookahead optimizer wrapper | **Cell E running at step 1500 = 3.52713 (tracking A ctrl).** All 4 prior cells terminal: A ctrl=3.26801, B(α=0.5 k=5)=3.27956 +7.7σ, C(α=0.5 k=10)=3.28116 +8.6σ DNF, D(α=0.3 k=5)=3.30526 +22.4σ catastrophic DNF. Cell E (cooldown_disable) is last chance to salvage; if E lands near A (~3.265-3.270), confirms "sync disrupts cooldown" mechanism but no improvement. ETA terminal ~23:30 UTC. PR will be terminal then. |
| #594 | fern | Peak WD multiplier sweep (1.0/1.5/2.0ctrl/2.5/3.0) | A(ctrl 2.0)=3.26621 no-op, **B(peak_wd=1.0)=3.26874 +1.45σ** (worse), **C(peak_wd=1.5)=3.26875 +1.45σ** (worse). Cell D (2.5) running ~step 87. Lower peak WD doesn't help; current 2.0 looks robustly tuned. Upper direction (D, E) will close axis. |


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
