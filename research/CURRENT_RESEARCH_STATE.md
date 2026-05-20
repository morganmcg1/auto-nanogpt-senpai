# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~16:50Z (poll #305)
- **🆕🆕 NEW BASELINE (PR #497 MERGED):** mu=3.266120, std=0.001747, n=6, ffs_mean=3087.5
  - **Mechanism: ns_iter=6 (Newton-Schulz 6 iterations) + soap_attn + lr_mlp=0.055 + WD ramp_down**
  - **New statsig rule:** `(3.266120 - mu) × √n ≥ 0.004`
  - n=4 gate: mu ≤ **3.264120** | n=6 gate: mu ≤ **3.264488** | n=8 gate: mu ≤ **3.264707**
  - *NOTE: all future PRs must include `--ns_iter 6` to compare against this baseline*
- **Previous baseline (PR #371):** mu=3.267948, std=0.000823 — still used for old Δσ comparisons on in-flight PRs


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status (poll #305) |
|------|---------|-----------|--------|
| **#596** | **tanjiro** | **Tied input/output embedding sweep (untied ctrl/tied lr=0.3/0.1/0.03/0.01) — structural axis, never tested** | **NEW assignment** — fresh structural pivot after 3× NEG regularization closures |
| #571 | askeladd | AdamW scalar param LR sweep (0.001/0.003/0.01ctrl/0.03/0.1) — RMSNorm gains LR | In progress — cells running |
| #566 | nezuko | embed_lr sweep (0.05/0.15/0.3ctrl/0.6/1.0) — fresh AdamW axis | In progress — cells running |
| #565 | thorfinn | Init variance scale sweep (0.1/0.33ctrl/0.5/1.0/2.0) | In progress — interim: Cell B (xavier=1.0) at 3.26387 (-0.99σ, watch) |
| #556 | frieren | AdamW epsilon sweep (1e-12/1e-10ctrl/1e-8/1e-6/1e-4) | In progress — interim: Cell C (eps=1e-6) at 3.26369 (-1.09σ, watch) |
| #581 | edward | Lookahead optimizer wrapper (α=0.0ctrl/0.3/0.5 × k=5/10) — fresh mechanism | In progress — Cell B (standard Lookahead α=0.5 k=5) running |
| #552 | alphonse | LR warmup curve sweep | In progress — Cell D running |
| #594 | fern | Peak WD multiplier sweep (1.0/1.5/2.0ctrl/2.5/3.0) | In progress — cells running |


## Recent Closures

- **🆕 #558 tanjiro Z-loss regularizer sweep** — CLOSED clean-NEG (poll #305). Monotonic worsening across 3 decades (1e-5 → 1e-4 → diverged). Mechanism: existing logit softcap (`15 * logits * (logits.square() + 15**2).rsqrt()`) already bounds logits to ±15, making z-loss fully redundant — stacks suppression on top of softcap, over-regularizes output distribution. Z-loss axis closed. **Tanjiro has now closed 3× on regularization/loss axis (#473, #517, #558) — pivoting to structural axis.**
- **#548 fern WD floor in cooldown** — CLOSED clean-neutral (poll #303). WD floor=0 NOT load-bearing (B/C/D within ctrl noise; E=+2.60σ mild at 0.50 floor). Cross-axis: LR-floor=0.20 is +29.46σ catastrophic; WD-floor=0.20 is +0.95σ — WD axis 30× more forgiving. Mechanism: LR=0 terminal is structurally load-bearing; WD=0 is incidental. Closes one half of cooldown mechanism (LR=0 critical, WD=0 incidental).
- **#537 edward Adam β1/β2 sweep** — CLOSED clean-neutral (poll #302). U-shaped response: A=(0.8,0.95) ctrl is locally optimal; both directions worse. Canonical AdamW (0.95,0.999) catastrophic (+8.86σ vs OLD — ~1000-step β2 window too slow for 3250-step run). β1=0.8 (5-step window) and β2=0.95 (20-step window) confirmed optimal. Adam β axis closed.
- **#551 askeladd Muon nesterov toggle** — CLOSED clean-NEG (poll #299). Cell B (nesterov=False) = 3.273293 (+4.10σ vs NEW baseline). The `grad.lerp_(momentum, mu)` correction (~5% current grad + 95% EMA before NS orthogonalization) is load-bearing — orthogonalizing pure EMA discards informative current-step delta, leaves NS with stale direction. Theme clarification: "less intensity" does NOT mean removing gradient correction. nesterov=True axis closed.
- **#521 nezuko gradient clipping** — CLOSED clean-NEG (poll #298). Monotonic worsening: tighter clip = strictly worse. A (no clip) = 3.26439 BEST; B (400K) = 3.26635; C (200K) = 3.26712; D (100K) = 3.26927; E (50K) much worse. A→E span ≈ +10σ_single. Mechanism: NS orthogonalization is scale-invariant on Muon path, so clipping damage falls entirely on Adam path (embed/lm_head/scalars) where it kills useful gradient magnitude. No-clip remains the right default. Grad-clip axis closed.
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
- **tanjiro #596 tied embedding**: structural axis — share `embed.weight` and `proj.weight` (standard in GPT-2/T5/BERT, never tested here). 5 cells: untied ctrl + tied at lr∈{0.3, 0.1, 0.03, 0.01}. Key question: does the per-group LR asymmetry (embed=0.3 vs lm_head=0.003) reflect untied needing differential pressure, or is it an arbitrary artifact? Winner candidate if correct LR found.
- **nezuko #566 embed_lr sweep**: fresh AdamW axis. 5 cells: 0.05/0.15/0.3ctrl/0.6/1.0. embed.weight (38M params) is the biggest single Adam-managed param. If 0.15 wins: "less optimizer intensity" extends to embed; if 0.6 wins: rare-token gradients need more push.
- **edward #581 Lookahead**: fresh mechanism wrapper — slow/fast param sync every k steps. Cells: ctrl (off), α=0.5 k=5 (standard), α=0.5 k=10, α=0.3 k=5, α=0.5 k=5 cooldown-disabled. Cell B (standard Lookahead) running. Risk: EMA-like behavior at cooldown (cf. tanjiro #517); Cell E tests cooldown-disable workaround.
- **askeladd #571 scalar LR**: fresh AdamW axis — lr=0.01 for RMSNorm gains never ablated. 5 cells ±1 decade. Cells running.
- **frieren #556 Adam eps**: WATCH — Cell C (eps=1e-6) interim at 3.26369 (−1.09σ vs OLD baseline), ~step 2600/3250. If terminal ≤ 3.264120 → P2 gate hit. eps-axis: larger eps softens small-`v` updates ("less intensity" theme connection).
- **thorfinn #565 init variance scale**: WATCH — Cell B (xavier=1.0 scale, no depth adjustment) interim at 3.26387 (−0.99σ vs OLD baseline), ~step 3225/3250 — near terminal. If terminal ≤ 3.264120 → P2 gate hit. Fresh structural axis.
- **alphonse #552 LR warmup**: first ever warmup PR. Cell D running. 5 curve shapes tested.
- **fern #594 peak-WD**: fresh schedule axis — peak multiplier 2.0 hardcoded, never ablated. 5 cells: 1.0/1.5/2.0ctrl/2.5/3.0. Follow-up to #548 (WD floor=0 incidental; real lever is peak/mean WD profile).

**What comes after current in-flight:**
- **lm_head LR sweep** — pair to nezuko #566 (embed_lr) and askeladd #571 (scalars); proj lr=1/320 hardcoded, never swept independently. Now especially relevant as counterpart to tanjiro #596 tied embedding.
- **Muon momentum warmup** — separate from current mu=0.95 (ramp from 0 across run)
- **Depth-aware init (μP-style)** — extends thorfinn #565 init axis if global constant matters
- **Tied embedding follow-up** — if tanjiro #596 finds a sweet spot LR, refine with finer scan and test interaction with embed_lr findings
- **NS axis is closed** (PR #518 mapped it) — current (2, −1.5, 0.5) + ns_iter=6 ✓; don't return here

**Key insights:**
- **New n=4 gate 3.264120 is very hard**: ~2.44σ below the OLD n=4 gate. Future winners need substantial improvement over the new baseline.
- **In-flight PRs were designed on OLD baseline (3.267948)**. Their results will still be interpretable but compare against OLD baseline for Δσ, and against NEW baseline (3.266120) for merge decision.
- **ns_iter=6 + Muon coefs (thorfinn Cell C) compound potential**: the −1.35σ vs OLD baseline = ~0.00111 above the NEW baseline mean. Not a winner on its own, but could contribute to a compound approach.
- **Single-seed variance at new baseline**: NEW std=0.001747 (dominated by T2 outlier). For practical purposes, any single-seed signal ≥ 1.5σ (vs OLD σ=0.000823) should be investigated; gate calculations use the fixed margin formula.
- **lr_mlp axis fully mapped**: 0.050–0.075 sweep closed. Best single-seed at 0.050 (−1.13σ OLD) but not actionable vs new baseline. No upward headroom from SOAP-MLP hypothesis.
