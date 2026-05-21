# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-21 ~12:00Z (poll #336)
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


## Active WIP Portfolio (poll #336 — new baseline mu=3.263265)

⚠️ **New gate reminder: all future PRs need ctrl cell ≈ 3.263265. n=4 gate = 3.261265. Strong P1 signals must land ≤ 3.260 to be worth P2 confirmation.**

| PR # | Student | Hypothesis | Status (poll #333) |
|------|---------|-----------|--------|
| #641 | alphonse | AdaBelief optimizer for AdamW groups (Zhuang 2020) | Assigned poll #319. AdamW ctrl arm crashing repeatedly (3 crashes at steps 450/603/1701) — student in crash-debug loop. Student also caught baseline drift (PR launched before #571 merged) and wired `--lr_scalars 0.03` into both ctrl and AdaBelief cells for fair comparison. Fresh-mechanism optimizer test #1. |
| #648 | thorfinn | Per-block LR decay/growth sweep (5-cell: const/decay/growth/bottom_heavy/top_heavy) | Assigned poll #322. Earlier OOM diagnosed as duplicate concurrent launcher scripts (shared-GPU contention, not code bug). Cells progressing on clean runs. Depth-aware micro-LR axis (never tried). |
| #659 | nezuko | Schedule-Free AdamW (Defazio 2024) — Polyak iterate averaging removes LR cooldown | Assigned poll #323. Cell A AdamW ctrl crashed at step 297 (infra not code; val/loss trajectory normal, nonfinite_count=0). Cell B (SF defaults no-cooldown) running at step ~2101 with val/loss=3.629 — flagged for eval-mode swap verification (SF requires `optimizer.eval_mode()` before val, `train_mode()` after; without swap eval measures z not x_bar). |
| #665 | tanjiro | NS iter SCHEDULE sweep — time-varying Newton-Schulz iteration count (5-cell) | Assigned poll #330. First time-varying NS schedule ever tested. Extends "less optimizer intensity late" theme to Muon polynomial depth. Mechanistically orthogonal to all in-flight AdamW-path optimizer tests. |
| #649 | frieren | wd_scalars per-group WD sweep (5-cell: 0.0 ctrl / 0.0001 / 0.001 / 0.01 / 0.1) | Assigned poll #322. Cell A ctrl=0.0 done at 3.262853 (matches new baseline within noise). Cell B=1e-4 running at step ~1555. 5 earlier A-ctrl crashes attributed to shared-GPU OOM contention (same pattern as #648). |
| #671 | edward | Cautious AdamW (Liang 2024, arXiv:2411.16085) — mask updates where Adam step disagrees with current gradient | Assigned poll #333. 5-cell: A=AdamW ctrl / B=boolean mask / C=normalized boolean / D=soft sigmoid mask / E=scalars-only. Mechanistically inverse of AdEMAMix #626 (closed clean-NEG): instead of ADDING slow-EMA info, REMOVES wrong-direction-update info. Fresh-mechanism optimizer test replacing #626 slot. |
| #645 | askeladd | Adan optimizer for AdamW groups (Xie 2022, gradient-difference 3-buffer) | Assigned poll #321. Cell A AdamW ctrl ~91% done. Student caught 2 mechanism-changing bugs in PR spec (β2 vs 1-β2 coefficient, step-1 prev_g init) by cross-checking official sail-sg/Adan; advisor approved official-faithful implementation. Fresh-mechanism optimizer test #3. |
| **#679** | **fern** | **NEW (poll #336)** LR cooldown SHAPE sweep (linear ctrl/cosine/quadratic/sqrt/step, fixed LR peak) | Just assigned (poll #336). 5-cell analogue of fern's just-closed WD shape sweep (#635). All shapes fix LR peak; integrals vary (cosine=linear=0.5; quadratic=1/3; sqrt=2/3; step=0.9). Most likely candidate to beat: cosine (equal integral, smoother transition). LR cooldown shape axis never tested on r5. |


## Recent Closures

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

**Four parallel fresh-mechanism optimizer tests in flight (Lion + AdEMAMix eliminated):**
- **#641 alphonse AdaBelief** — variance of (g − m)² instead of g² (Zhuang 2020) — adds buffer to AdamW; AdamW ctrl crashing
- **#645 askeladd Adan** — gradient-difference 3-buffer (Xie 2022) — adds buffers to AdamW
- **#659 nezuko Schedule-Free AdamW** — Polyak iterate averaging (Defazio 2024) — **REMOVES the LR schedule**, orthogonal mechanism class
- **#671 edward Cautious AdamW** (NEW) — masks updates where Adam step disagrees with current gradient (Liang 2024) — **inverse of AdEMAMix**: removes wrong-direction information rather than adding slow-EMA information

**Three targeted hyperparameter sweeps on the new baseline:**
- **#648 thorfinn per-block LR** — depth-aware LR multipliers across 12 layers (decay/growth/bottom_heavy/top_heavy)
- **#649 frieren wd_scalars** — per-group WD on scalar gains, now that lr_scalars=0.03
- **#665 tanjiro NS iter SCHEDULE** — time-varying ns_iter across training (decay/growth/step variants); extends "less optimizer intensity late" theme to Muon polynomial depth

**Mechanism class joint-closure (3 augmentation-style optimizer mechanisms failed clean-NEG):**
- Lion #638 (sign-based momentum replacement — incompatible at any viable LR)
- Lookahead #581 (parameter-side slow averaging)
- AdEMAMix #626 (gradient-side slow EMA)

The pattern: AdamW dynamics here are robustly well-tuned for the 3250-step horizon. Slow-signal augmentations require many half-lives to express their paper-claimed benefits. **Cautious (#671) tests the inverse hypothesis: rather than ADDING signal, FILTER existing signal** — does removing wrong-direction updates help where adding slow updates hurt?

Cross-PR insight: AdamW per-group LR landscape **fully mapped** — embed (#566 flat), lm_head (#600 flat), scalars (#571 3× wins → MERGED). Per-group LR asymmetry: small 20K scalar group can take aggressive LR; 39M lm_head proj cannot. Init magnitude axis CLOSED. Lion axis CLOSED. If any of the 3 mechanism tests beats the new hard gate (3.261265), compound with lr_scalars=0.03 (already in baseline) becomes natural next step.

**What comes after current in-flight:**
- **LR cooldown shape** — fern #679 just launched (poll #336). Most likely winner: cosine (equal integral to linear, smoother transition). If wins → P2 confirm. If linear dominates → LR schedule shape axis closed.
- **Mechanism compound** — if any of {AdaBelief #641, Adan #645, Schedule-Free #659, Cautious #671} beats new gate 3.261265, compound with lr_scalars=0.03 (already in baseline) as natural next step.
- **AdamW β1 per-group for scalars** — after lr_scalars tripled, the optimal β1 for the scalar group may differ from global 0.8. Targeted follow-up if mechanism tests come up empty.
- **Fine lr_scalars scan** — {0.015, 0.02, 0.025, 0.03ctrl, 0.04, 0.05} to check if 0.03 is the true optimum or just the nearest tested point.
- **Depth-aware init (μP-style)** — revisit if thorfinn #648 per-block LR signals something.
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
