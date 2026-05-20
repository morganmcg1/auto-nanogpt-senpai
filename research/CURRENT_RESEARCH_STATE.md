# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~07:30Z (poll #291)
- **🆕🆕 NEW BASELINE (PR #497 MERGED):** mu=3.266120, std=0.001747, n=6, ffs_mean=3087.5
  - **Mechanism: ns_iter=6 (Newton-Schulz 6 iterations) + soap_attn + lr_mlp=0.055 + WD ramp_down**
  - **New statsig rule:** `(3.266120 - mu) × √n ≥ 0.004`
  - n=4 gate: mu ≤ **3.264120** | n=6 gate: mu ≤ **3.264488** | n=8 gate: mu ≤ **3.264707**
  - *NOTE: all future PRs must include `--ns_iter 6` to compare against this baseline*
- **Previous baseline (PR #371):** mu=3.267948, std=0.000823 — still used for old Δσ comparisons on in-flight PRs


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status (poll #290) |
|------|---------|-----------|--------|
| **#551** | **askeladd** | **Muon nesterov toggle (True/False) — first PR on ns_iter=6 baseline** | **NEW assignment** — awaiting first heartbeat. 2-cell n=1 screen; uses `--ns_iter 6` throughout |
| #537 | edward | Adam β1/β2 sweep (ctrl + 4 cells) | Cell A ctrl val=3.26855 (+0.73σ vs OLD). **Cell B (0.9,0.95) running**. Uses ns_iter=12 (old) |
| #521 | nezuko | Gradient clipping (0/50K/100K/200K/400K) | A=3.26439 (−4.32σ), B=3.26712 (−1.00σ), C=3.26927 (+1.61σ). Cell D (50K) likely running |
| #518 | thorfinn | NS poly coefficient sweep | A=3.267355, B=3.267031, **C=3.26684 (−1.35σ vs OLD best)**. Cell D (analytical quintic) running. Cell E (current coefs+iter6) critical cross-check pending |
| #517 | tanjiro | EMA / Polyak eval (5 cells) | A=3.26776, B=3.27528 (+8.91σ), C=3.34507 (+93.71σ CATASTROPHIC). Cell D (0.9999) running. Cell E (cooldown-only EMA) is the only survivor candidate |
| #509 | frieren | lr_mlp fine-scan (0.050/0.055/0.060/0.065/0.075) | A=3.267302, B=3.267014 (−1.13σ), C=3.267256. **Cell D (0.065) running** |
| **#552** | **alphonse** | **LR warmup curve sweep (none/0.05L/0.10L/0.05C/0.02L) — first warmup PR ever** | **NEW assignment** — awaiting first heartbeat |
| **#548** | **fern** | **WD floor in cooldown (0.0/0.05/0.10/0.20/0.50) — dual of LR floor** | **NEW — awaiting first heartbeat** |


## Recent Closures

- **🆕 #508 alphonse Muon mu static sweep {0.85/0.90/0.95/0.97/0.99}** — CLOSED clean-neutral (poll #291). Asymmetric response curve: mu=0.95 ctrl best; mu=0.99 catastrophic (+39.05σ, never reached target). Cleanly explains tanjiro #445 schedule failures (both schedules crossed mu≥0.98 catastrophic regime). Muon mu axis closed; current 0.95 confirmed optimal.
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
- **thorfinn #518 Cell C** (Muon coefs + ns_iter=6): val=3.26684 (-1.35σ vs OLD baseline). If Cell E (current coefs + ns_iter=6) also lands similarly, coefs don't add on top of ns_iter=6. If Cell E is worse, Muon coefs are genuinely compound-able.
- **nezuko #521 grad-clip**: no-clip wins so far. Cells D (50K)/E (50K?) still running. Monitoring for whether any clip level actually helps.
- **tanjiro #517 Cell E** (cooldown-only EMA): all other cells catastrophic. Cell E is the only hope for EMA mechanism.
- **edward #537 Adam betas**: Cell A ctrl ok, Cells B-E running. ETA ~17:00 UTC. First Adam beta exploration.
- **alphonse #508 Cell E** (mu=0.99): all other deviations from 0.95 worse. Axis looks like current 0.95 is already optimal.
- **frieren #509 Cell B** (lr_mlp=0.050) = −1.13σ vs OLD: interesting but barely crosses gate. Cell D (0.065) running.

**What comes after the new baseline:**
- **#551 askeladd Muon nesterov toggle** — first PR on new baseline; binary ablation
- **WD floor** (#548 fern): dual of LR floor; testing whether WD=0 terminal is also structural
- **Adam epsilon sweep** — eps=1e-10 hardcoded; fresh axis
- **LR warmup curve shape** — cosine warmup vs current linear; fresh schedule axis
- **Z-loss regularizer** — softmax temperature stability; completely fresh mechanism
- **NS coefs + ns_iter=6 compound** — pending thorfinn Cell E result before assigning

**Key insights:**
- **New n=4 gate 3.264120 is very hard**: ~2.44σ below the OLD n=4 gate. Future winners need substantial improvement over the new baseline.
- **In-flight PRs were designed on OLD baseline (3.267948)**. Their results will still be interpretable but compare against OLD baseline for Δσ, and against NEW baseline (3.266120) for merge decision.
- **ns_iter=6 + Muon coefs (thorfinn Cell C) compound potential**: the −1.35σ vs OLD baseline = −1.35 × 0.000823 = 0.00111 above the NEW baseline. Not a winner on its own, but could contribute to a compound approach.
- **Single-seed variance at new baseline**: NEW std=0.001747 (dominated by T2 outlier). For practical purposes, any single-seed signal ≥ 1.5σ (vs OLD σ=0.000823) should be investigated; gate calculations use the fixed margin formula.
