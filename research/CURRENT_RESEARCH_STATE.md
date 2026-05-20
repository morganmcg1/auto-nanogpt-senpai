# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~10:30Z (poll #298)
- **🆕🆕 NEW BASELINE (PR #497 MERGED):** mu=3.266120, std=0.001747, n=6, ffs_mean=3087.5
  - **Mechanism: ns_iter=6 (Newton-Schulz 6 iterations) + soap_attn + lr_mlp=0.055 + WD ramp_down**
  - **New statsig rule:** `(3.266120 - mu) × √n ≥ 0.004`
  - n=4 gate: mu ≤ **3.264120** | n=6 gate: mu ≤ **3.264488** | n=8 gate: mu ≤ **3.264707**
  - *NOTE: all future PRs must include `--ns_iter 6` to compare against this baseline*
- **Previous baseline (PR #371):** mu=3.267948, std=0.000823 — still used for old Δσ comparisons on in-flight PRs


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status (poll #297) |
|------|---------|-----------|--------|
| **#566** | **nezuko** | **embed_lr sweep (0.05/0.15/0.3ctrl/0.6/1.0) — fresh AdamW axis** | **NEW assignment** — awaiting first heartbeat. embed_lr=0.3 and lm_head_lr=1/320 hardcoded; never ablated |
| #565 | thorfinn | Init variance scale sweep (0.1/0.33ctrl/0.5/1.0/2.0) | Smoke (xavier=1.0) finished clean; Cell A ctrl launching |
| #558 | tanjiro | Z-loss regularizer sweep | Cell A ctrl at step 1319 (~40%) |
| #556 | frieren | AdamW epsilon sweep | Cell A ctrl at step 2224 (~68%); recovered from 2 early crashes |
| #551 | askeladd | Muon nesterov toggle | Cell A ctrl terminal: val=3.265755 (−0.21σ vs NEW baseline). Cell B (nesterov=False) running at step 1420 (~44%) |
| #537 | edward | Adam β1/β2 sweep | A=3.26855, B=3.26963, C=3.27063 — all WORSE than baseline (Cell C +3.26σ vs OLD). Cell D (b095_b0999 canonical) at step ~498. Uses ns_iter=12 |
| #552 | alphonse | LR warmup curve sweep | **Cell A ctrl terminal: val=3.2686** (+0.27σ vs NEW baseline — refactor no-op ✓). Cell B (linear-005) running at step 542 |
| #548 | fern | WD floor in cooldown | **Cell A (0.0) terminal: val=3.267094** (+0.56σ vs NEW baseline). Cell B (0.05) running at step 2901 — terminal imminent |


## Recent Closures

- **🆕 #521 nezuko gradient clipping** — CLOSED clean-NEG (poll #298). Monotonic worsening: tighter clip = strictly worse. A (no clip) = 3.26439 BEST; B (400K) = 3.26635; C (200K) = 3.26712; D (100K) = 3.26927; E (50K) much worse. A→E span ≈ +10σ_single. Mechanism: NS orthogonalization is scale-invariant on Muon path, so clipping damage falls entirely on Adam path (embed/lm_head/scalars) where it kills useful gradient magnitude. No-clip remains the right default. Grad-clip axis closed.
- **#518 thorfinn NS poly coefs** — CLOSED clean-neutral (poll #297). Coef family val-neutral at iter=12 (A/B/D within 0.39σ). ns_iter val-flat 6→12 in both families (≤0.23σ). Cell C signal (+0.55σ vs E) revealed as seed noise: Cell C absolute val (3.26684) is WORSE than askeladd's P2 cluster (~3.265) with same nominal config. NS-internal axis fully mapped; current (2, −1.5, 0.5) + ns_iter=6 is the optimum we can find. Vs NEW baseline: best cell (C) is +0.41σ ABOVE mean, not actionable.
- **#517 tanjiro EMA / Polyak eval** — CLOSED — mechanism rejected (poll #294). All EMA cells catastrophic vs ctrl: B (decay=0.99) +8.91σ; C (0.999) +93.71σ; D (0.9999) +4781σ; E (cooldown-only) +41.50σ. Mechanism: cooldown already shrinks raw steps to ~0 → terminal raw weights ARE effectively averaged → EMA drags eval weights backward. Post-hoc eval averaging axis closed for this 3250-step regime.
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
- **nezuko #566 embed_lr sweep**: fresh AdamW axis (PR #162 touched Muon LR only). 5 cells: 0.05/0.15/0.3ctrl/0.6/1.0; lm_head_lr held at 1/320. embed.weight (38M params) is the biggest single Adam-managed param. If 0.15 wins: "less optimizer intensity" theme extends to embed; if 0.6 wins: rare-token gradients need more push.
- **edward #537 Adam betas**: Cell A=3.268547, Cell B (0.9, 0.95)=3.269635 — both worse than baseline. Cells C/D (b09_b099) at step 2559. Uses ns_iter=12 so reads against OLD baseline.
- **askeladd #551 Muon nesterov**: Cell A ctrl = 3.265755 (refactor no-op confirmed). Cell B (nesterov=False) just started. If nesterov=False ≤ 3.264120: P2 candidate.
- **frieren #556 Adam eps**: fresh log-scale sweep (1e-12→1e-4); ctrl 1e-10. Consistent with "less intensity" theme if larger eps (1e-8/1e-6) helps by softening small-`v` updates.
- **alphonse #552 LR warmup**: first ever warmup PR. 5 curve shapes tested. Cell A at step ~2488 (~76%).
- **fern #548 WD floor**: dual of LR floor; WD=0 terminal as structural question. Cell B (0.05) running at step 1613.
- **tanjiro #558 Z-loss regularizer**: fresh mechanism — softmax partition-function penalty. Cell A ctrl just started.
- **thorfinn #565 init variance scale**: fresh structural axis — the 0.33 constant at init has never been ablated.

**What comes after current in-flight:**
- **lm_head LR sweep** — pair to nezuko #566 (embed_lr); proj lr=1/320 hardcoded, never swept independently
- **Muon momentum warmup** — separate from current mu=0.95 (ramp from 0 across run)
- **Tied vs untied embedding** — model.embed and model.proj are independent; tying could be a structural ablation
- **Scalar param LR** — RMSNorm gains at lr=0.01, never swept
- **Depth-aware init (μP-style)** — extends thorfinn #565 init axis if global constant matters
- **NS axis is closed** (PR #518 mapped it) — current (2, −1.5, 0.5) + ns_iter=6 ✓; don't return here

**Key insights:**
- **New n=4 gate 3.264120 is very hard**: ~2.44σ below the OLD n=4 gate. Future winners need substantial improvement over the new baseline.
- **In-flight PRs were designed on OLD baseline (3.267948)**. Their results will still be interpretable but compare against OLD baseline for Δσ, and against NEW baseline (3.266120) for merge decision.
- **ns_iter=6 + Muon coefs (thorfinn Cell C) compound potential**: the −1.35σ vs OLD baseline = ~0.00111 above the NEW baseline mean. Not a winner on its own, but could contribute to a compound approach.
- **Single-seed variance at new baseline**: NEW std=0.001747 (dominated by T2 outlier). For practical purposes, any single-seed signal ≥ 1.5σ (vs OLD σ=0.000823) should be investigated; gate calculations use the fixed margin formula.
- **lr_mlp axis fully mapped**: 0.050–0.075 sweep closed. Best single-seed at 0.050 (−1.13σ OLD) but not actionable vs new baseline. No upward headroom from SOAP-MLP hypothesis.
