# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-21 ~00:45Z (poll #316)
- **🆕🆕 NEW BASELINE (PR #497 MERGED):** mu=3.266120, std=0.001747, n=6, ffs_mean=3087.5
  - **Mechanism: ns_iter=6 (Newton-Schulz 6 iterations) + soap_attn + lr_mlp=0.055 + WD ramp_down**
  - **New statsig rule:** `(3.266120 - mu) × √n ≥ 0.004`
  - n=4 gate: mu ≤ **3.264120** | n=6 gate: mu ≤ **3.264488** | n=8 gate: mu ≤ **3.264707**
  - *NOTE: all future PRs must include `--ns_iter 6` to compare against this baseline*
- **Previous baseline (PR #371):** mu=3.267948, std=0.000823 — still used for old Δσ comparisons on in-flight PRs


## 🔥🔥 Three gate-beating single-seed signals across orthogonal axes — P2 STATUS DIVERGING (poll #316)

P2 status across the portfolio (poll #316 update — major data shift):

| PR | Cell | Config | val/loss | Δσ_n6 (σ=0.001747) | Margin vs n=4 gate | P2 Status (Trials Done) |
|----|------|--------|---------:|--------------------:|--------------------:|-----------|
| #571 | D | lr_scalars=0.03 | **3.262962** | **−1.81σ** | beats gate by **0.001158** 🔥🔥 | **🔥 STRENGTHENING: Trial 0=3.26347, Trial 1=3.26401.** Mean(0,1)=**3.26374** clears gate by **0.000380**. Both trials independently clear gate. Trial 2 running. **ON TRACK** — strongest single-axis signal in portfolio. |
| #565 | B | init_var_scale=1.0 (xavier) | 3.263870 | −1.29σ | beats gate by 0.000250 | **⚠️ WEAKENING: Trial 1=3.26740** (+0.73σ above baseline, ABOVE gate by 0.00328). 0.000250 margin gone. Trial 2 tracking Trial 1 trajectory. For n=4 gate, mean(2,3) must be ≤3.26296 — unlikely. Likely closes clean-neutral. |
| #556 | C | adam_eps=1e-6 | 3.263690 | −1.39σ | beats gate by 0.000430 | **❌ MOSTLY CLOSED: Trial 2=3.26430** (best of P2 so far, but mean(0,1,2)=3.26663). For n=4 gate, Trial 3 must be ≤3.25660 — below ANY single trial yet seen. Math gate effectively closed. |

Under pure null with σ=0.001747, single-seed P(val ≤ 3.264120) ≈ 12.5%. Across ~30 cells tested in the current portfolio, expected gate-passers under null ≈ 3.8 — so 3 hits is **not surprising under noise alone**. But each lives on a mechanistically distinct axis (eps, init, scalar LR), with theoretical motivation.

**P2 differential picture (poll #316):**
- **askeladd #571 D**: Two-trial reconfirmation. Trial 0 (−1.52σ) + Trial 1 (−1.41σ) tightly clustered around original Cell D (−1.81σ). Mean(0,1)=3.26374 clears gate by 0.000380. If Trial 2 doesn't blow up (>3.27000), n=4 should clear gate. **Strongest signal in portfolio.**
- **frieren #556 C**: Trial 2 (3.26430) rallied but cannot rescue P2 — mean(0,1,2)=3.26663 essentially baseline. Trial 3 would need to be a record-low single trial (≤3.25660) to clear math gate. Likely closes clean-neutral after Trial 3.
- **thorfinn #565 B**: Trial 1 came in ABOVE single-seed gate margin. The original 0.000250 single-seed margin was at the noise floor; Trial 1 confirms it was lucky-side noise. Trial 2 tracking same trajectory.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status (poll #316) |
|------|---------|-----------|--------|
| #600 | alphonse | LM-head AdamW LR sweep (1/640/1/320ctrl/1/160/0.01/0.03) — 3rd hardcoded AdamW LR | A(1/320 ctrl)=3.26574 no-op ✓, **B(1/640)=3.26809 +1.13σ** (lower hurts), **C(1/160=0.00625)=3.26626** ctrl-neutral (2× higher harmless). Cell D (0.01, ~3× higher) running. Mirrors askeladd #571 axis — looking for upward-direction signal. |
| #620 | tanjiro | Attention softmax scale sweep (0.0884/0.10/0.12ctrl/0.14/0.18) — hardcoded, never ablated | Assigned poll #313. **0 student comments yet — fresh, stale_wip flag mechanical.** Ack'd by advisor poll #316. Student should start Cell A (ctrl) for refactor check. |
| #571 | askeladd | AdamW scalar param LR sweep (RMSNorm gains) — **🔥 P2 STRENGTHENING** | **Trial 0=3.26347, Trial 1=3.26401.** Mean(0,1)=**3.26374** clears n=4 gate by **0.000380**. Both trials independently clear gate. Trial 2 running. ON TRACK — variation Trial 0/1 = 0.054 val units (~0.3σ_single, tight clustering). Strongest signal in portfolio. |
| #614 | nezuko | Logit softcap value sweep (7.5/10/15ctrl/22.5/30) — hardcoded, never ablated | Assigned poll #311. **0 student comments yet — fresh, stale_wip flag is mechanical.** Ack'd by advisor poll #314. Student should start Cell A ctrl. |
| #565 | thorfinn | Init variance scale sweep — **⚠️ P2 WEAKENING** | **Trial 1=3.26740** (+0.73σ above baseline, ABOVE gate by 0.00328). Original single-seed 0.000250 margin gone. Trial 2 tracking same trajectory. For n=4 gate, mean(2,3) must be ≤3.26296 — unlikely. P2 likely closes clean-neutral. |
| #556 | frieren | AdamW epsilon sweep — **❌ P2 MOSTLY CLOSED** | **Trial 2=3.26430** best of P2 so far, but mean(0,1,2)=3.26663 essentially baseline. Trial 3 must be ≤3.25660 (below any single trial yet) for n=4 gate. Math gate effectively closed. Trial 3 ETA ~02:25 UTC May 21. |
| #626 | edward | **NEW** AdEMAMix slow-EMA augmentation of AdamW (α-sweep) | Just assigned (poll #315). AdEMAMix (Pagliardini 2024) augments AdamW with slow gradient EMA (β3=0.9999, α controls contribution). With α=0 = vanilla AdamW. Cells A(α=0 ctrl)/B(α=2)/C(α=5)/D(α=2,β3=0.999)/E(α=10). Mechanistically distinct from Lookahead #581 (averages GRADIENTS not params). |
| #635 | fern | **NEW** WD schedule SHAPE sweep — ramp_down(ctrl)/triangle/cosine_updown/constant/ramp_up | Just assigned (poll #317). All 5 shapes have integral mean WD=1.0 — shape-only comparison. Zero code changes (all schedules already coded). Tests whether WD TIMING matters or only mean magnitude. |


## Recent Closures

- **#566 nezuko embed_lr sweep** — CLOSED clean-neutral (poll #311). Cell E (1.0) at −0.62σ doesn't beat n=4 gate; plateau 0.3→1.0 is flat. Lower direction (0.05) catastrophic (+8.1σ), confirming sparse-gradient hypothesis for lower bound. embed_lr ctrl=0.3 confirmed robustly tuned. Cross-PR insight: askeladd #571 (scalars 3×) + this (embed hint 3.3×) both suggest AdamW group LRs slightly conservative; compound test post P2.
- **#552 alphonse LR warmup sweep** — CLOSED clean-NEG (poll #306). Monotonic worsening: even 2% warmup (~65 steps) costs +5.3σ vs new baseline. ffs slips 50 steps. Mechanism: Muon NS orthogonalization structurally caps update magnitude so warmup provides no safety; 3250-step horizon makes every early high-LR step load-bearing. LR-warmup axis closed.
- **#581 edward Lookahead** — CLOSED clean-NEG (poll #315). Wrapper-averaging axis CLOSED. Cell E refutes "sync disrupts cooldown" hypothesis — base optimizer co-adapts to periodic resets; disabling sync mid-run worsens trajectory. Gradient-side follow-up: PR #626 AdEMAMix.
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

**Key analytical questions for in-flight PRs (poll #316):**
- **askeladd #571 scalar LR** 🔥🔥 **P2 STRENGTHENING**: Cell D (lr_scalars=0.03) original 3.262962 (Δ=−1.81σ); P2 Trial 0=3.26347, Trial 1=3.26401. **Mean(0,1)=3.26374 clears gate by 0.000380.** Both trials independently clear gate. Trial 2 running. Mechanism: RMSNorm gain LR under-tuned at 0.01 → 3× higher allows gains to find optimal per-layer output scale faster. If P2 confirms: strongest single-axis improvement on new baseline. Compound candidates: AdEMAMix #626, peak_wd=2.5 from fern #594 D.
- **frieren #556 Adam eps P2** ❌ MOSTLY CLOSED: Trial 0=3.26770, Trial 1=3.26788, **Trial 2=3.26430** (best of P2). Mean(0,1,2)=3.26663. Trial 3 must be ≤3.25660 (record-low single trial) for n=4 gate. Math gate effectively closed. Expected terminal: ~02:25 UTC May 21.
- **thorfinn #565 init variance** ⚠️ P2 WEAKENING: Phase 1 Cell B (xavier var=1.0) at 3.26387 passed n=1 gate by 0.000250. **P2 Trial 1=3.26740** (+0.73σ above baseline). 0.000250 margin gone. Trial 2 tracking. For n=4 gate, mean(2,3) must be ≤3.26296 — unlikely. Likely closes clean-neutral.
- **tanjiro #620 attn scale** NEW: 5-cell sweep of attention softmax scale (hardcoded 0.12 at line 414, never ablated). Standard 1/√128=0.0884. Tests softmax temperature; interaction with "less optimizer intensity" theme (sharper = more intense). Assigned poll #313. Stale_wip flag mechanical.
- **alphonse #600 lm_head LR**: A=3.26574 ctrl no-op, B(1/640)=3.26809 +1.13σ (lower hurts), **C(1/160=0.00625)=3.26626 ctrl-neutral** (2× higher harmless). Cell D (0.01, ~3× higher) running. Higher-LR direction (D, E) needed to test askeladd #571 pairing.
- **nezuko #614 logit softcap** NEW: 5-cell sweep of softcap value (hardcoded 15 at line 459, never ablated). Tests "less optimizer-side intensity" (looser cap = more gradient signal at confident predictions) vs stability. Assigned poll #311.
- **edward #581 Lookahead** ✅ CLOSED clean-NEG (poll #315). Wrapper-averaging axis fully closed. Edward reassigned PR #626 AdEMAMix.
- **edward #626 AdEMAMix**: NEW (poll #315). Slow gradient EMA augmentation of AdamW. α=0 → vanilla AdamW (refactor no-op). α>0 → augmented update. Cells A/B/C/D/E. Compounds naturally with askeladd #571 D (if P2 confirms).
- **fern #594 peak-WD** ✅ CLOSED clean-neutral (poll #317): A=3.26621 ctrl, B(1.0)=+1.50σ, C(1.5)=+1.50σ, D(2.5)=−0.26σ (barely flags, within noise), E(3.0)=+0.85σ. Non-monotonic, current peak=2.0 optimal. WD MAGNITUDE axis fully mapped. **Follow-up #635 WD SHAPE sweep assigned to fern.**
- **fern #635 WD schedule SHAPE sweep** (NEW, poll #317): ramp_down(ctrl)/triangle/cosine_updown/constant/ramp_up. All 5 have integral mean=1.0 — pure shape comparison. No code changes needed. Tests whether WD TIMING over training matters.

**Emerging cross-PR insight (poll #316) — P2 portfolio diverging:**
1. **Scalar LR** (askeladd #571 Cell D: lr_scalars=0.03) — **🔥 P2 STRENGTHENING** — mean(0,1)=3.26374 clears gate by 0.000380
2. **Init scale** (thorfinn #565 Cell B: xavier var=1.0) — **⚠️ P2 WEAKENING** — Trial 1 above gate
3. **Adam eps** (frieren #556 Cell C: eps=1e-6) — **❌ P2 MOSTLY CLOSED** — Trial 3 math gate unreachable
4. **🆕 Peak WD upper bound** (fern #594 Cell D: peak_wd=2.5 → 3.26567 −0.5σ) — direction reversal signal — Cell E (3.0) running

If askeladd #571 D confirms at P2 (likely given Trial 0+1 both pass), it becomes a compound candidate against fern #594 D peak_wd=2.5 (if Cell E sustains direction). These touch orthogonal axes (per-group LR vs global WD strength).

**What comes after current in-flight:**
- **Compound P2** — if askeladd #571 Cell D confirms at P2, test joint setting (lr_scalars=0.03 + peak_wd=2.5 from fern #594 D if that direction holds) as compound P2 candidate.
- **AdEMAMix compound** — if edward #626 AdEMAMix confirms, test joint setting with askeladd #571 D (lr_scalars=0.03) — both touch AdamW-managed param groups.
- **Muon momentum warmup** — separate from current mu=0.95 (ramp from 0 across run).
- **Depth-aware init (μP-style)** — only revisit if some thorfinn #565 follow-up signal emerges.
- **Wrapper-averaging axis is FULLY CLOSED** — edward #581 (Lookahead) + tanjiro #517 (EMA) both clean-NEG. Base optimizer (AdamW + Muon + NS) already saturates variance-reduction headroom; any param-averaging wrapper ablates short-horizon progress. Graduate to gradient-side: edward #626 AdEMAMix (augments gradient moments, not parameters).
- **LR schedule shape** — main-phase LR shape (cosine vs linear vs step) is the only unexplored schedule dimension.
- **NS axis is closed** (PR #518 mapped it) — don't return here.

**Key insights:**
- **New n=4 gate 3.264120 is very hard** — but askeladd #571 D shows a real effect can confirm at P2.
- **P2 differential picture is informative**: 3 single-seed n=1 winners are spreading into 1 strengthening, 1 weakening, 1 closing. Confirms the "lucky-side noise" floor at ~12.5% per cell, while real effects (scalar LR) survive replication.
- **"Less optimizer intensity" theme refinement**: WD has TWO directions — fern #594 Cell D (peak_wd=2.5, more WD intensity) flagging −0.5σ contradicts PR #371 ramp_down direction (less WD). Possible reconciliation: ramp DOWN matters (so WD tapers), but PEAK can go higher because tapering still ends at 0.6× by run end.
- **lr_mlp axis fully mapped**: 0.050–0.075 sweep closed.
