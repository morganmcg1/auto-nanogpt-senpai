# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-21 ~05:10Z (poll #322)
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


## Active WIP Portfolio (poll #322 — new baseline mu=3.263265)

⚠️ **New gate reminder: all future PRs need ctrl cell ≈ 3.263265. n=4 gate = 3.261265. Strong P1 signals must land ≤ 3.260 to be worth P2 confirmation.**

| PR # | Student | Hypothesis | Status (poll #322) |
|------|---------|-----------|--------|
| #641 | alphonse | AdaBelief optimizer for AdamW groups (Zhuang 2020) | Assigned poll #319. Running. AdaBelief variance of (g − m)² instead of g². 5-cell sweep: A=AdamW ctrl / B=AdaBelief default / C/D/E vary eps. Fresh-mechanism optimizer test #1. |
| #620 | tanjiro | Attention softmax scale sweep (0.0884/0.10/0.12ctrl/0.14/0.18) — hardcoded, never ablated | Assigned poll #313. Running. No terminal yet. |
| **#648** | **thorfinn** | **NEW** Per-block LR decay/growth sweep (5-cell: const/decay/growth/bottom_heavy/top_heavy) | Just assigned (poll #322). Static per-block multipliers on Muon-managed 2D weights across 12 layers. Tests whether early-layer (raw tokens) vs late-layer (high-level features) want different step sizes — depth-aware micro-LR axis (never tried). All cells include mandatory `--lr_scalars 0.03`. |
| #614 | nezuko | Logit softcap value sweep (7.5/10/15ctrl/22.5/30) — hardcoded, never ablated | Assigned poll #311. Running. No terminal yet. |
| **#649** | **frieren** | **NEW** wd_scalars per-group WD sweep (5-cell: 0.0 ctrl / 0.0001 / 0.001 / 0.01 / 0.1) | Just assigned (poll #322). Follow-up to lr_scalars=0.03 win — RMSNorm gains now train 3× faster, so WD=0 may no longer be optimal. Targeted hyperparameter sweep, mechanistically tied to the new baseline. |
| #626 | edward | AdEMAMix slow-EMA augmentation of AdamW (α-sweep) | Assigned poll #315. Running. Dual EMA on gradients (slow β3=0.9999). Fresh-mechanism optimizer test #2. |
| #635 | fern | WD schedule SHAPE sweep (ramp_down ctrl/triangle/cosine_updown/constant/ramp_up) | Cell A (ramp_down ctrl) done at 3.267194 (ABOVE new baseline — likely missing `--lr_scalars 0.03`). Cell B (triangle) running. Cells use OLD lr_scalars; results compare to Cell A for relative shape effects only. |
| #645 | askeladd | Adan optimizer for AdamW groups (Xie 2022, gradient-difference 3-buffer) | Assigned poll #321. Adan uses 3 EMA buffers: grad (β1=0.98), gradient-difference (β2=0.92), adaptive second-moment (β3=0.99). 5-cell: A=AdamW ctrl / B=Adan defaults LR×1.0 / C=LR×0.5 / D=LR×2.0 / E=tighter betas (0.9/0.85/0.95). Fresh-mechanism optimizer test #3. |


## Recent Closures

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

**Key analytical questions for in-flight PRs (poll #322 — new baseline mu=3.263265):**

⚠️ **Gate recalibration:** With new baseline mu=3.263265, only results landing near 3.260 or below are worth P2 confirmation. The ctrl cell for all future PRs should be compared against 3.263265, not 3.266120.

- **thorfinn #648 per-block LR (NEW)**: 5-cell static depth-aware LR multipliers on Muon-managed 2D weights (12 blocks): const ctrl / decay (early>late) / growth (late>early) / bottom_heavy / top_heavy. All cells use mandatory baseline flags including `--lr_scalars 0.03`. Tests depth-aware LR axis (never tried).
- **frieren #649 wd_scalars (NEW)**: 5-cell sweep on per-group WD for the RMSNorm-gain scalar group: 0.0(ctrl) / 0.0001 / 0.001 / 0.01 / 0.1. Targeted follow-up to lr_scalars=0.03 win — if scalar gains now train 3× faster, optimal scalar WD may have shifted off zero.
- **tanjiro #620 attn scale**: 5-cell sweep, softmax scale (0.0884/0.10/0.12ctrl/0.14/0.18). Running. Ctrl should land ~3.263265 (new baseline). Promising if Cell C validates, then check ±20% cells.
- **alphonse #641 AdaBelief**: AdaBelief second-moment variance of (g − m)² instead of g². Ctrl=AdamW, 4 cells vary eps. Test whether variance of gradient-residual better adapts to the RMSNorm gain update path.
- **edward #626 AdEMAMix**: Slow gradient EMA augmentation. α=0 → vanilla AdamW ctrl (should be ~3.263265); α>0 augments with slow-EMA. Key question: does slow gradient memory provide any signal beyond what the baseline already captures?
- **askeladd #645 Adan**: 3-buffer optimizer (m for grad, v for grad-difference, n for adaptive second-moment). Mechanistically distinct from the other 3 fresh-mechanism tests in flight.
- **fern #635 WD shape**: Cell A (ramp_down ctrl) done at 3.267194 — **ABOVE new baseline mu=3.263265** by 0.003929. All cells run at lr_scalars=0.01 (old default), so results cannot be compared directly to new baseline but can compare to Cell A for relative shape effects.
- **nezuko #614 logit softcap**: 5-cell sweep (7.5/10/15ctrl/22.5/30). Running.

**Emerging cross-PR insight (poll #322) — #571 MERGED, 3 fresh-mechanism + 2 targeted-hp tests:**
1. **✅ Scalar LR** (askeladd #571, lr_scalars=0.03) — **MERGED NEW BASELINE (poll #321)** — n=4 mean=3.263265
2. **❌ Init scale** (thorfinn #565) — CLOSED poll #322; P2 math-impossible
3. **❌ Lion** (frieren #638) — CLOSED poll #322; twice-failed crashes
4. **❌ Adam eps** (frieren #556) — CLOSED clean-neutral
5. **❌ Peak WD** (fern #594) — CLOSED clean-neutral
6. **❌ lm_head LR** (alphonse #600) — CLOSED clean-neutral (asymmetry: scalars take 3× but lm_head rejects 3×)

**Three parallel fresh-mechanism optimizer tests still in flight (Lion eliminated):**
- **#626 edward AdEMAMix** — dual EMA on gradients (slow β3=0.9999, α-sweep)
- **#641 alphonse AdaBelief** — variance of (g − m)² instead of g² (Zhuang 2020)
- **#645 askeladd Adan** — gradient-difference 3-buffer (Xie 2022)

**Two targeted hyperparameter sweeps on the new baseline:**
- **#648 thorfinn per-block LR** — depth-aware LR multipliers across 12 layers (decay/growth/bottom_heavy/top_heavy)
- **#649 frieren wd_scalars** — per-group WD on scalar gains, now that lr_scalars=0.03

Cross-PR insight: AdamW per-group LR landscape **fully mapped** — embed (#566 flat), lm_head (#600 flat), scalars (#571 3× wins → MERGED). Per-group LR asymmetry: small 20K scalar group can take aggressive LR; 39M lm_head proj cannot. Init magnitude axis CLOSED. Lion axis CLOSED. If any of the 3 mechanism tests beats the new hard gate (3.261265), compound with lr_scalars=0.03 (already in baseline) becomes natural next step.

**What comes after current in-flight:**
- **Mechanism compound** — if any of {AdEMAMix, AdaBelief, Adan} beats new gate 3.261265, compound with lr_scalars=0.03 (already in baseline) as natural next step.
- **WD shape rerun on new baseline** — fern #635 is running at lr_scalars=0.01 (old). If a WD shape variation beats its ctrl, rerun on new lr_scalars=0.03 baseline to verify the effect holds.
- **AdamW β1 per-group for scalars** — after lr_scalars tripled, the optimal β1 for the scalar group may differ from global 0.8. Targeted follow-up if mechanism tests come up empty.
- **Fine lr_scalars scan** — {0.015, 0.02, 0.025, 0.03ctrl, 0.04, 0.05} to check if 0.03 is the true optimum or just the nearest tested point. Marginal but fast.
- **Depth-aware init (μP-style)** — revisit if thorfinn #648 per-block LR signals something.
- **Wrapper-averaging axis is FULLY CLOSED** — edward #581 + tanjiro #517 both clean-NEG.
- **Cooldown_frac axis CLOSED** — PR #457 confirmed U-shape minimum at 0.7.
- **NS axis is closed** — PR #518 mapped it, PR #461 confirmed ns_iter=6 is optimal.
- **Muon mu axis is closed** — PR #508 confirmed mu=0.95 optimal.
- **Init variance magnitude axis CLOSED** — thorfinn #565 (poll #322).
- **Lion optimizer axis CLOSED** — frieren #638 (poll #322), incompatible at viable LR scale.

**Key insights:**
- **New n=4 gate 3.264120 is very hard** — but askeladd #571 D shows a real effect can confirm at P2.
- **P2 differential picture is informative**: 3 single-seed n=1 winners are spreading into 1 strengthening, 1 weakening, 1 closing. Confirms the "lucky-side noise" floor at ~12.5% per cell, while real effects (scalar LR) survive replication.
- **"Less optimizer intensity" theme refinement**: WD has TWO directions — fern #594 Cell D (peak_wd=2.5, more WD intensity) flagging −0.5σ contradicts PR #371 ramp_down direction (less WD). Possible reconciliation: ramp DOWN matters (so WD tapers), but PEAK can go higher because tapering still ends at 0.6× by run end.
- **lr_mlp axis fully mapped**: 0.050–0.075 sweep closed.
