# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~08:50Z (poll #294)
- **🆕🆕 NEW BASELINE (PR #497 MERGED):** mu=3.266120, std=0.001747, n=6, ffs_mean=3087.5
  - **Mechanism: ns_iter=6 (Newton-Schulz 6 iterations) + soap_attn + lr_mlp=0.055 + WD ramp_down**
  - **New statsig rule:** `(3.266120 - mu) × √n ≥ 0.004`
  - n=4 gate: mu ≤ **3.264120** | n=6 gate: mu ≤ **3.264488** | n=8 gate: mu ≤ **3.264707**
  - *NOTE: all future PRs must include `--ns_iter 6` to compare against this baseline*
- **Previous baseline (PR #371):** mu=3.267948, std=0.000823 — still used for old Δσ comparisons on in-flight PRs


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status (poll #294) |
|------|---------|-----------|--------|
| **#558** | **tanjiro** | **Z-loss regularizer sweep (0/1e-5/1e-4/1e-3/1e-2) — fresh mechanism** | **NEW assignment** — awaiting first heartbeat. 5-cell n=1; fresh softmax partition-function regularizer; never tested in this run |
| **#556** | **frieren** | **AdamW epsilon sweep (1e-12/1e-10ctrl/1e-8/1e-6/1e-4)** | NEW (poll #293) — awaiting first heartbeat. 5-cell n=1 log-scale screen |
| **#551** | **askeladd** | **Muon nesterov toggle (True/False) — first PR on ns_iter=6 baseline** | NEW (poll #291) — awaiting first heartbeat. 2-cell binary ablation |
| #537 | edward | Adam β1/β2 sweep (ctrl + 4 cells) | Cells A–B terminal; C–E in flight. Uses ns_iter=12 (old) — results interpretable vs OLD baseline |
| #521 | nezuko | Gradient clipping (0/50K/100K/200K/400K) | A=3.26439 (−4.32σ), B=3.26712 (−1.00σ), C=3.26927 (+1.61σ). Cells D/E in sequence |
| #518 | thorfinn | NS poly coefficient sweep | A=3.267355, B=3.267031, C=3.26684 (−1.35σ vs OLD best). Cells D (analytical quintic) and E (current coefs+iter6) in flight |
| **#552** | **alphonse** | **LR warmup curve sweep (none/0.05L/0.10L/0.05C/0.02L) — first warmup PR ever** | NEW (poll #291) — awaiting first heartbeat |
| **#548** | **fern** | **WD floor in cooldown (0.0/0.05/0.10/0.20/0.50) — dual of LR floor** | NEW (poll #289) — awaiting first heartbeat |


## Recent Closures

- **🆕 #517 tanjiro EMA / Polyak eval** — CLOSED — mechanism rejected (poll #294). All EMA cells catastrophic vs ctrl: B (decay=0.99) +8.91σ; C (0.999) +93.71σ; D (0.9999) +4781σ; E (cooldown-only) +41.50σ. Mechanism: cooldown already shrinks raw steps to ~0 → terminal raw weights ARE effectively averaged → EMA drags eval weights backward. Post-hoc eval averaging axis closed for this 3250-step regime.
- **#509 frieren lr_mlp fine-scan** — CLOSED clean-neutral (poll #293). Hypothesis "higher lr_mlp wins" REJECTED. Shape: B (0.050) = best at −1.13σ vs OLD but +0.51σ vs NEW baseline (not actionable). Monotonic degradation from 0.060 upward (+1.03σ/+2.35σ). lr_mlp axis closed upward; SOAP's preconditioner already saturates the headroom.
- **#508 alphonse Muon mu static sweep** — CLOSED clean-neutral (poll #291). Asymmetric response curve: mu=0.95 ctrl best; mu=0.99 catastrophic (+39.05σ, never reached target). Cleanly explains tanjiro #445 failures. Muon mu axis closed.
- **#504 fern LR floor sweep** — CLOSED clean-NEG (poll #289). Monotonic super-linear worsening; LR=0 terminal boundary load-bearing.
- **#497 askeladd P2 ns_iter=6** — ✅ **MERGED NEW BASELINE** (poll #290). mu=3.266120 (n=6, statsig +0.000478). ns_iter axis won at ns_iter=6.
- **#496 edward NS iter LOW sweep** — CLOSED clean-neutral (poll #287). Hard bf16 cliff below ns_iter=5; axis fully mapped.
- **#467 nezuko SOAP trust threshold** — CLOSED clean-neutral (poll #283).


## Research Themes

**NEW BASELINE: mu=3.266120 (PR #497 ns_iter=6). New n=4 gate: 3.264120 (was 3.265948). The bar is now significantly higher.**

**"Less optimizer intensity" theme confirmed on multiple axes:**
- PR #371: WD ramp_down → 0 (less WD pressure at cooldown)
- PR #497: ns_iter=6 (fewer NS iters = less orthogonalization work per step)
- Both point to: **reducing optimizer micro-aggression at the late/cooldown phase helps**

**Key analytical questions for in-flight PRs:**
- **nezuko #521 grad-clip**: no-clip wins so far (−4.32σ). Cells D/E (50K variants) still running. Monitoring for whether any clip level helps — unlikely given no-clip leading strongly.
- **edward #537 Adam betas**: Cell A ctrl ok, Cell B (0.9, 0.95) terminal. Cells C–E running. Interpreting vs OLD baseline (ns_iter=12).
- **thorfinn #518 Cell E** (current coefs + ns_iter=6): Cell C (Muon coefs + ns_iter=6) = 3.26684 (−1.35σ vs OLD). Cell E tests whether it's the coefs or ns_iter=6 doing the work.
- **frieren #556 Adam eps**: fresh log-scale sweep (1e-12→1e-4); ctrl 1e-10. Consistent with "less intensity" theme if larger eps (1e-8/1e-6) helps by softening small-`v` updates.
- **askeladd #551 Muon nesterov**: binary toggle; first PR on new baseline. If nesterov=False (smooth EMA) wins, consistent with less-intensity theme.
- **alphonse #552 LR warmup**: first ever warmup PR. 5 curve shapes tested. Completely fresh axis.
- **fern #548 WD floor**: dual of LR floor; WD=0 terminal as structural question.
- **tanjiro #558 Z-loss regularizer**: fresh mechanism — softmax partition-function penalty. Tests if explicit log(Z)^2 pressure helps on top of the existing logit softcap (line 459).

**What comes after current in-flight:**
- **NS coefs + ns_iter=6 compound** — pending thorfinn Cell E result before assigning
- **Initialization variance scaling** — fresh axis untouched across all PRs (line 768-772 init code)
- **Embed/lm_head LR sweep** — embed lr=0.3 and proj lr=1/320 hardcoded, never swept
- **Muon momentum warmup** — separate from current mu=0.95 (ramp from 0 across run)
- **Tied vs untied embedding** — model.embed and model.proj are independent; tying could be a structural ablation
- **Scalar param LR** — RMSNorm gains at lr=0.01, never swept

**Key insights:**
- **New n=4 gate 3.264120 is very hard**: ~2.44σ below the OLD n=4 gate. Future winners need substantial improvement over the new baseline.
- **In-flight PRs were designed on OLD baseline (3.267948)**. Their results will still be interpretable but compare against OLD baseline for Δσ, and against NEW baseline (3.266120) for merge decision.
- **ns_iter=6 + Muon coefs (thorfinn Cell C) compound potential**: the −1.35σ vs OLD baseline = ~0.00111 above the NEW baseline mean. Not a winner on its own, but could contribute to a compound approach.
- **Single-seed variance at new baseline**: NEW std=0.001747 (dominated by T2 outlier). For practical purposes, any single-seed signal ≥ 1.5σ (vs OLD σ=0.000823) should be investigated; gate calculations use the fixed margin formula.
- **lr_mlp axis fully mapped**: 0.050–0.075 sweep closed. Best single-seed at 0.050 (−1.13σ OLD) but not actionable vs new baseline. No upward headroom from SOAP-MLP hypothesis.
