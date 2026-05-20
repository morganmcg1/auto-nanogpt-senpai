# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-20 16:13 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/frieren still broken (thorfinn pod state ambiguous); **esc#25 posted 15:30 UTC** — ~116h total operator silence. Fresh W&B post-rotation smoke verification confirms 3 pods still fingerprint as `nonfinite_count ≈ 147.5M` at low step. Holding comments refreshed on PRs #190/#298/#525 to reset harness stale-wip flags.
- **Branch state:** Baseline post-PR #443 (Aux AdamW eps=1e-6, merged 13:25 UTC 2026-05-19). 🎉 **CURRENT BASELINE**.
- **🆕 PR #589 edward CLOSED 16:08 UTC — H27 STORM mathematical degeneracy under 1-FBP constraint**: Edward caught the bug pre-launch. Unrolling the recursion `d_t = g_t + (1−α)·(d_{t-1} − g_{t-1})` with d_0=g_0=0 shows d_t = g_t for all t (since d_{t-1}=g_{t-1} from previous step). Genuine STORM requires `∇f(x_{t-1}, ξ_t)` (recompute at prev params, current batch) — second forward-backward per step → **violates benchmark contract**. **Mechanism finding**: under 1-FBP constraint, VR-via-control-variate is **fully covered by MARS** (PR #582 askeladd). STORM is theoretically distinct but practically unavailable on this stack. Edward reassigned to H28 GC (PR #592). $0 GPU burned.
- **🆕 PR #592 edward REASSIGNED 16:13 UTC — H28 Gradient Centralization on aux AdamW (Yong et al CVPR 2020)**: 2-arm core (ctrl, GC-on) + optional arm 3 only if GC wins. Pre-step gradient projection: `g_w ← g_w − mean_{∀ axes except output}(g_w)`. Fresh mechanism class: gradient-direction projection (orthogonal to VR/AdEMAMix/Lookahead/AGC). ~15 LoC; cannot degenerate algebraically (5-LoC tensor op, no state). Compatible with fused AdamW. 1D scalar gains skipped (no axes to project).
- **🆕 PR #572 edward CLOSED 15:11 UTC — H26 Aux AdamW β1 cooldown ramp NEG, mechanism incompatible with fused state**: Ctrl `gxylln21` val=3.2713 ✓ (baseline-match, code-clean). Arm 2 `zzotocuj` CRASHED NaN step 25, nonfinite_count 148M. Two smoke-v2 attempts with gated reassignment ALSO crashed identically. **Mechanism finding**: `optimizer.param_groups[i]['betas']` reassignment mid-training is incompatible with PyTorch fused AdamW kernel state. Closes off the entire β1-scheduling axis on this stack at the optimizer level.
- **🆕 PR #555 askeladd CLOSED 14:00 UTC — H17 SWA on aux cooldown NEG, paired SWA-vs-iterate proves SWA harmful**: 3-arm: ctrl `ws2odsqa` 3.27383, SWA 10% `n1cmpotm` 3.27310 (paired Δ=+0.00079 SWA worse than iterate same trajectory), SWA 20% every2 `uce6mixo` 3.27678 (paired Δ=+0.00265). **Mechanism finding (third confirmation in this round)**: weight-averaging methods (SWA, EMA shadow, Schedule-Free) are categorically incompatible with WSD/linear-cooldown stacks that target the final iterate. Joins PR #200 (full-model EMA) + PR #531 (Schedule-Free Polyak) as same-mechanism NEG triple. **Rule**: future advisor planning should not propose weight-averaging variants. PR #536 MuLoCo finding does NOT contradict (MuLoCo accumulates gradients/deltas, not iterate weight averages).
- **🆕 PR #582 askeladd REASSIGNED 14:05 UTC — H25 MARS variance-reduced gradient on aux AdamW (Yuan 2025)**: 3 arms — ctrl (γ=0), γ=0.025 paper LM default, γ=0.1 aggressive. Fresh mechanism class: control-variate gradient correction `c_t = g_t + γ_t·(m_{t-1} − g_{t-1})`. Different from H22 AdEMAMix (which adds m_2 EMA) — MARS directly reduces variance via the m_t-vs-g_t residual. Compatible with WSD/linear-cooldown (modifies training gradient, not eval weights — does NOT trigger the weight-averaging-incompatibility from PR #200/#531/#555). Implementation ~35 LoC; pre-step gradient modification; fused AdamW kernel undisturbed.
- **🆕 PR #539 edward CLOSED 11:38 UTC — H7 Per-group AdamW WD NEG, embed-WD destructive**: Arm 1 redo ctrl `9werg9o8` val=3.27254 (baseline-match), arm 2 wd-carriers `rd8hvapz` val=3.27321 (+0.00067 NEG), arm 3 wd-all `zhfffa5p` val=3.28321 (+0.01067, never reached target). **Mechanism finding**: PR #501 prediction confirmed cleanly via arm 3 — embed has large gradients → AdamW already updates aggressively → WD=0.01 destroys. Arm 2 falsifies corollary at wd=0.01 — lm_head/scalars update magnitudes during cosine cooldown are too small for WD to act as productive regularization. **Twice-validated mental model**: per-group HP levers (LR, β2, eps, WD) behave asymmetrically across embed vs lm_head/scalars. Code change merged-as-is (3 WD flags, additive at default 0).
- **🆕 PR #544 fern CLOSED 10:20 UTC — Cautious AdamW NEG, short-β1 stack incompatibility**: Arm 2 cautious+norm val=3.29606 best (terminal 3.43536 after +0.20 late-cooldown blowup), Δ+0.025 vs ctrl arm 1 (val=3.27189 baseline-match). **Mechanism finding**: ×3.1 effective LR amplification on unmasked coords pushes out-of-distribution from our population-tuned aux LRs; short β1=0.8 kills stale-momentum gap Cautious is designed to filter. Side diagnostic: unfused Cautious-AdamW path is numerically clean (PR #510 NaN failure is NAdam-specific, NOT all unfused-AdamW).
- **🆕 PR #567 fern REASSIGNED 10:25 UTC — H22 AdEMAMix (dual-EMA preconditioner)**: 3 arms — ctrl, α=5 with 30%-warmup, α=8 with 30%-warmup. Fresh mechanism (Pagliardini et al EMNLP 2024). Complements short-β1 by ADDING long-horizon m_2 (β3=0.9999) on top of fresh m_1 (β1=0.8). Post-hoc correction respects PR #510 fused constraint. **Student PICKED UP**: smoke `v55lvh4b` verified; ctrl arm `xqmqsxba` running step ~1300/3325 (ETA ~12:30 UTC).
- **🆕 PR #536 nezuko CLOSED 09:45 UTC — MECHANISM FINDING: Nesterov momentum IS the load-bearing component (NOT averaging)**: 3-arm ablation. Arm 3 momentum=0 val=3.30224 (+0.03005, 3× worse than removing whole wrapper). Mental model: MuLoCo on single-GPU is "accumulated outer Nesterov momentum on top of inner stack", NOT distributed Polyak averaging.
- **🆕 PR #563 nezuko REASSIGNED 09:50 UTC — H18 cooldown-aware `outer_momentum` ramp**: Direct exploit of PR #536 finding (momentum marginal value INCREASES during cooldown). **Student LIVE**: arm 1 ctrl `jaobblo5` step 2275/3325 (~68% through, ETA ~12:10 UTC). Duplicate launch `3rxevlmq` already tagged `killed-duplicate` by student.
- **🔴 PR #478 askeladd CLOSED 07:55 UTC**: n=4 mean=3.27211, embed-LR lever closed. Original n=1 monotone signal was ~1.5σ ctrl-arm seed inflation.
- **🟡 PR #555 askeladd ARM 1 swa-ctrl FINISHED 10:09 UTC**: `ws2odsqa` val=**3.2738**, ffs=3150, reached target. Δ+0.00261 vs baseline (within population band). Arm 2 swa-10pct `n1cmpotm` running step ~2675/3325 (ETA ~12:00 UTC). Arm 3 swa-20pct follows.
- **🆕 KEY MECHANISTIC FINDING (PR #510 CLOSED 01:30 UTC, REFINED by PR #544 10:20 UTC):** Unfused optimizer path NaN failure is **NAdam-specific**, NOT all unfused-AdamW. Fern's PR #544 ran unfused Cautious-AdamW with zero nonfinite gradients for 3325 steps. **Implication**: optimizer-by-optimizer unfused-safety check required. Wraps of fused AdamW (Lookahead, SWA, AdEMAMix-correction) remain unconditionally SAFE.
- **🆕 PR #525 frieren POD ROTATION REQUESTED 04:09 UTC**: 8 NaN runs (~91% nonfinite_count). Pod hardware/CUDA state issue. Frieren PR parked in WIP.

## ⭐ Current baseline (post-PR #443 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27119** (n=1 trial, passes n=1 bar < 3.27206) |
| `ffs` (primary) | **3100** (n=1; beats prior best 3125) |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| **Aux AdamW eps** | **`--aux_adamw_eps 1e-6`** (new flag; was hardcoded 1e-10) |
| MuonH inner AGC | `--muonh_agc_clip_ratio 0.05` |
| MuonH LR warmup | warmup_steps=100, shape=linear |
| Outer wrapper | MuLoCo Nesterov-SGDM (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| Aux AdamW | betas=(0.8, 0.95), **eps=1e-6**, AGC clip_ratio=0.05, weight_decay=0, **fused=True** |
| Cooldown | MuonH=cosine frac=1.0, aux=linear frac=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| W&B run | `t1coza71` (n=1 single trial) |
| Baseline PR | [#443](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/443) |

**Merge bar (against new baseline 3.27119):**
- **n=1 promotion bar**: val < **3.27039** (Δ ≤ −0.0008 vs 3.27119)
- **Conservative n=4 bar**: μ < **3.27079**

**⚠️ CRITICAL — ALL new experiment commands must include:**
```
--aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --muonh_cooldown_shape cosine --muonh_warmup_steps 100 --aux_adamw_eps 1e-6
```

**🆕 CRITICAL — Aux optimizer must use fused kernel.** Unfused path produces NaN at step 3 forward (confirmed via PR #510 diagnostic). Any new aux optimizer assignment must verify a fused implementation or wrap fused AdamW (Lookahead/SWA-style).

## Active experiments (16:13 UTC 2026-05-20)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#592** | edward | **H28: Gradient Centralization on aux AdamW** (NEW 16:13 UTC) | Assigned. Pre-step gradient projection `g_w ← g_w − mean(g_w)` along axis=1+. Fresh mechanism class — gradient direction preprocessing, orthogonal to VR/AdEMAMix/Lookahead/AGC. 2 arms (ctrl, GC-on) + optional arm 3 if GC wins. ~15 LoC; cannot degenerate (no state, no recursion). Paper: Yong et al CVPR 2020 |
| **#582** | askeladd | **H25: MARS variance-reduced gradient** (14:05 UTC) | mars-ctrl `ifdm0vqm` step 2600/3325 (~78%, ETA ~22 min). Control-variate gradient correction c_t = g_t + γ_t·(m_{t-1} − g_{t-1}). 3 arms: ctrl, γ=0.025 (paper LM), γ=0.1 (aggressive) |
| **#567** | fern | **H22: AdEMAMix on aux** (10:25 UTC) | ctrl `xqmqsxba` TERMINAL **val=3.2723** ✓, α=5 `k0psv3oo` TERMINAL **val=3.2727 ffs=3125** (Δ+0.0004 vs ctrl, within seed noise). α=8 `xrh0qfrf` step 2460/3325 (~74%, ETA ~26 min) — trending NEG (step 2460 val=3.40 vs ctrl trajectory same step ~3.32) |
| **#563** | nezuko | **H18: Cooldown-aware `outer_momentum` ramp** (09:50 UTC) | Arm 1 ctrl `jaobblo5` TERMINAL **val=3.27140** ✓ (baseline-match). Arm 2 cooldown-ramp `nfx9rw46` TERMINAL **val=3.27991 ffs=3175** (+0.0085 vs ctrl) — NEG. Arm 3 long-ramp `lz1rez4p` step 2575/3325 (~77%, ETA ~22 min) — tracking decisively NEG (step 2500 val=3.398 vs ctrl 3.370, +0.028) |
| **#525** | frieren | **H2: Lookahead aux wrapper** (k=5; α=0.5 vs 0.8) | **POD STILL BROKEN** — fresh post-rotation smoke `pu4hxo61` NaN step 300, nonfinite_count 147.5M. esc#25 posted 15:30 UTC |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD STATE AMBIGUOUS** — GPU UUID `GPU-dc8b1158-ea83-f08d-5a76-944d7599070f` unchanged since 2026-05-18; needs operator verification |
| **#298** | tanjiro | **Residual branch init rescale** | **POD STILL BROKEN** — `gtzdlnir` NaN step 30, nonfinite_count 147.6M. esc#25 posted 15:30 UTC |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD STILL BROKEN** — `lz9orm12` post-rotation-smoke NaN step 300, nonfinite_count 147.5M. esc#25 posted 15:30 UTC |

## Recently closed PRs

- **PR #589 edward STORM (CLOSED 16:08 UTC 2026-05-20)** — Pre-launch closure ($0 GPU). Edward unrolled the recursion `d_t = g_t + (1−α)·(d_{t-1} − g_{t-1})` with d_0=g_0=0 and proved by induction that d_t = g_t for all t. Genuine STORM uses `∇f(x_{t-1}, ξ_t)` (gradient at previous params with current batch) requiring a 2nd forward-backward per step — **violates benchmark contract**. **Mechanism finding**: under 1-FBP constraint, VR-via-control-variate is fully covered by MARS (PR #582 askeladd); STORM is theoretically distinct but practically unavailable on this stack. Edward reassigned to H28 GC (PR #592). Great analytical catch by edward — pre-launch review prevented wasted GPU time.
- **PR #572 edward Aux AdamW β1 cooldown ramp (CLOSED 15:11 UTC 2026-05-20)** — Ctrl `gxylln21` 3.2713 ✓ (baseline-match, code-clean). Arm 2 `zzotocuj` NaN step 25, nonfinite 148M. Smoke-v2 with gated reassignment ALSO crashed identically (xn2wyuug, icqb3em2). NEG. **Mechanism finding**: `optimizer.param_groups[i]['betas']` reassignment mid-training is incompatible with PyTorch fused AdamW kernel state. Rule: do NOT propose schedule interventions that mutate fused-kernel hyperparameters mid-training (β1, β2, eps); only safe insertion is pre-step on `p.grad` (MARS-style). Edward reassigned to H27 STORM (PR #589, then CLOSED above).
- **PR #555 askeladd SWA on aux cooldown (CLOSED 14:00 UTC 2026-05-20)** — 3-arm + paired SWA-vs-iterate: ctrl 3.27383, SWA 10% 3.27310 (paired Δ=+0.00079), SWA 20% every2 3.27678 (paired Δ=+0.00265). **NEG. Mechanism finding (third weight-averaging confirmation)**: even in cooldown, the aux iterate is still moving meaningfully — uniform-mean window lags. Widening the window 10%→20% INCREASES harm. Joins PR #200 (full-model EMA NEG) + PR #531 (Schedule-Free Polyak NEG) — weight averaging is structurally incompatible with WSD/linear-cooldown stacks. Askeladd reassigned to H25 MARS (PR #582).
- **PR #539 edward Per-group AdamW WD (CLOSED 11:38 UTC 2026-05-20)** — 3-arm + redo result: ctrl `9werg9o8` 3.27254, wd-carriers `rd8hvapz` 3.27321 (+0.00067), wd-all `zhfffa5p` 3.28321 (+0.01067, never reached target). **Mechanism findings**: (1) Arm 3 confirms PR #501 prediction — embed-WD is destructive (large gradients × already-aggressive AdamW updates → WD=0.01 shrinks faster than rebuild). (2) Arm 2 falsifies corollary at wd=0.01 — under cosine cooldown, lm_head/scalars late-stage update magnitudes are too small for WD to act as productive regularization. **Twice-validated mental model**: per-group HP levers (LR, β2, eps, WD) behave asymmetrically across embed vs lm_head/scalars. Edward reassigned to H26 aux β1 cooldown ramp (PR #572).
- **PR #544 fern Cautious AdamW (CLOSED 10:20 UTC 2026-05-20)** — Arm 1 ctrl 3.27189 (baseline-match), Arm 2 cautious+norm **3.29606 best @3225 (terminal 3.43536 after +0.20 late-cooldown blowup)**, Δ+0.025 vs ctrl. NEG. **Mechanism finding**: short β1=0.8 (half-life ~3 steps) kills the stale-momentum gap Cautious is designed to filter; ×3.1 effective LR amplification on unmasked coords pushes aux LRs out of population-tuned range. Cautious AdamW is structurally unsuitable for short-β1 + pre-tuned-LR stacks. **Side diagnostic**: PR #510 unfused-NaN failure refined to NAdam-specific (Cautious unfused ran clean). Fern reassigned to H22 AdEMAMix (PR #567).
- **PR #536 nezuko MuLoCo ablation (CLOSED 09:45 UTC 2026-05-20)** — 3-arm result: ctrl 3.27220, off 3.28245 (+0.01025), mom0 **3.30224 (+0.03005)**. **Mechanism finding: Nesterov momentum is the active component, NOT averaging**. Removing momentum alone is 3× worse than removing the whole wrapper. Mental model: MuLoCo on single-GPU r3 = "accumulated outer Nesterov momentum compounds 30 inner deltas into one coherent kick", NOT periodic Polyak averaging. Cooldown-phase momentum value increases (arm 3 led ctrl by 0.083 at step 1500, collapsed by step 3325). Nezuko reassigned to H18 cooldown-aware momentum schedule (PR #563).
- **PR #478 askeladd embed_lr n=4 (CLOSED 07:55 UTC 2026-05-20)** — n=4 mean **3.27211** (sample stdev 0.00092, 95% CI [3.27121, 3.27301]). Merge bar 3.27079 fails by +0.00132; real-but-marginal upper bound 3.27200 fails by +0.00011. Statistically indistinguishable from PR #471 population estimate ~3.27218. **Original n=1 monotone signal across 0.2 → 0.3 → 0.4 was ~1.5σ ctrl-arm seed inflation.** Embed-LR lever closed. Per-seed σ ≈ 0.001 on this recipe means 5-point monotone n=1 sweeps can produce ~2σ swings that look like clean signals; future per-group LR sweeps should use n=2 ctrl as direction test, not promotion signal.
- **PR #531 fern SF-AdamW on aux (CLOSED 05:19 UTC 2026-05-20)** — ctrl arm `jqnpnzf7` val=3.27344. SF arm 2 `z13vk5l6` killed at step 612 (arm-2 at that point: val=3.856 vs AdamW ctrl 3.829, Δ+0.026). Extrapolated endpoint 3.278–3.288 (solidly NEG). **Mechanism: Polyak-Ruppert averaging lag — SF evaluates at trajectory mean, WSD/linear-cooldown targets final iterate. Combined with PR #265, establishes SF-methods are categorically incompatible with WSD/linear-cooldown stack.** H11 closes NEG.
- **PR #512 edward v_t reset at cooldown (CLOSED 04:25 UTC 2026-05-20)** — 3 arms: v_reset=1.0 (ctrl) 3.27280, v_reset=0.5 **3.27142** (BEST), v_reset=0.1 3.27270. Non-monotonic U-shape with optimum at partial reset. Arm-to-arm Δ(arm2−arm1)=−0.00138 is REAL mechanism signal above noise, but arm 2 vs baseline 3.27119 is +0.00023 (within seed noise σ=0.0012). **Mechanism real but optimum doesn't beat favorable-seed baseline at n=1**. H6 closes; compound-with-PR501 follow-up logged ((reset_frac=0.5) × (lm_head/scalars only) could amplify).
- **PR #507 nezuko embed init std (CLOSED 03:39 UTC 2026-05-20)** — 3 arms: std=1.0 ctrl 3.27188 (favorable seed), std=0.1 **3.27231** (WORSE), std=0.02 **3.27142** (BEST). Non-monotonic U-shape; best arm (std=0.02) doesn't clear merge bar 3.27039. **Mechanistic finding: embedding-side knobs are weak levers — eps=1e-6 win lives in lm_head/scalars per PR #501**. H5 closes NEG/exhausted.
- **PR #501 fern eps decomp (CLOSED 02:00 UTC 2026-05-20)** — 3 arms: ctrl 3.27393, embed→1e-10 3.27280 (BETTER), embed-only 3.27540 (WORSE). Clean directional signal: **eps=1e-6 win lives in lm_head/scalars, NOT embed**. No arm cleared merge bar (3.27039); per-group eps flag infra not merged.
- **PR #510 frieren NAdam (CLOSED 01:30 UTC 2026-05-20)** — Arm 1 ctrl 3.27222 (Δ+0.00103). NAdam arm NaN at step 3 forward. Diagnostic `AdamW(fused=False)` ALSO NaN at step 3 — same step-2 forward divergence. Mechanistic conclusion: unfused optimizer path incompatible with eps=1e-6 + AGC + per-group LR aux stack. Closed per decision tree; finding logged as global constraint.
- **PR #471 edward n=4 eps=1e-6 confirm (CLOSED 22:02 UTC 2026-05-19)** — n=4 mean 3.27218 (vs old baseline 3.27286, Δ−0.00068). Effect real but small. PR #443 n=1 was favorable-seed outlier. Conservative n=4 bar (<3.27079) NOT cleared.
- **PR #481 nezuko lm_head LR sweep (CLOSED ~20:40 UTC 2026-05-19)** — flat at 1/320.

## Key pattern: aux per-group LR sweeps (ACTIVE WIN DIRECTION)

- **scalars LR** (PR #475 CLOSED): saturated at 0.01.
- **embed LR** (PR #478 n=4 confirmation @ 0.4): 0.2→0.3→0.4 = 3.27527→3.27399→**3.27213** (Δ−0.00186 vs ctrl). Peak at 0.4 per single-arm sweep at 0.45/0.5.
- **lm_head LR** (PR #481 CLOSED): flat at 1/320 under eps=1e-6.
- **cooldown_frac** (PR #484 CLOSED): flat at 0.4.

## Per-group eps decomp FINAL (PR #501 fern, CLOSED 02:00 UTC)

- **Arm 1 ctrl (all 1e-6)**: 3.27393
- **Arm 2 (embed=1e-10, lm_head+scalars=1e-6)**: **3.27280** (Δ−0.00113 vs ctrl)
- **Arm 3 (embed=1e-6, lm_head+scalars=1e-10)**: **3.27540** (Δ+0.00147 vs ctrl)

**CONFIRMED**: Arms 2 and 3 land on opposite sides of ctrl with directional consistency. eps=1e-6 win lives in lm_head and/or scalars, NOT embed. Physical interpretation: embed has large gradients → large v → eps choice irrelevant; lm_head and scalars have small gradients → small v → eps=1e-6 acts as a meaningful floor.

**No arm cleared merge bar 3.27039 — finding recorded as mechanistic context, no merge.**

## Saturated levers (post-PR #443)

- **Inner LR dynamics**: MuonH-SI HPs (lr/mu/wd), cooldown shape/frac, warmup steps=100, mu warmup/cooldown ALL NEG.
- **Inner optimizer geometry**: AGC clip_ratio (insensitive [0.02, 0.10]), Nesterov outer SGDM mu (0.5 optimal).
- **Aux optimizer**: eps sweep confirms **1e-6 > 1e-10 >> 1e-8**. betas saturated. **NAdam blocked** (unfused path NaN). **Unfused AdamW also blocked** (same failure mode).
- **NS5**: k-count blocked (alphonse pod), all polynomial families closed (PR #438).
- **Logit softsign cap**: cap=15 is local optimum.
- **MuonH inner mu**: FULLY CLOSED (PR #450). 0.95 unique optimum.
- **MuonH budget_mult**: FLAT (PR #451). Axis closed.
- **MuLoCo ALL KNOBS**: sync_interval CLOSED (PR #453). outer_lr=0.7 CLOSED (PR #369). outer_momentum=0.5 CLOSED. Lever fully exhausted.

## Hypothesis bank (pending assignment when students free up)

| H# | Hypothesis | Notes / fused-path safety |
|---|---|---|
| H1 | Per-group eps decomp | **CLOSED PR #501** — embed NOT carrier; lm_head/scalars carry the eps=1e-6 win |
| H2 | Lookahead outer wrapper on aux | **PR #525 frieren ACTIVE** (safe: wraps fused) |
| H3 | SWA / EMA averaging on aux at cooldown | **PR #555 askeladd ACTIVE 07:55 UTC** — aux-only uniform-mean SWA during last 10% cooldown. Distinct from PR #200 full-model EMA-throughout NEG: (1) aux-only excludes MuonH orthogonalization invariant; (2) uniform-window instead of exponential decay; (3) cooldown-only timing. Aligned with PR #536 nezuko MuLoCo cooldown-phase finding. |
| H4 | Nesterov AdamW (NAdam) | **CLOSED PR #510 — unfused path NaN.** |
| H5 | Embed init std sweep | **CLOSED PR #507** — non-monotonic U-shape; std=0.02 best at 3.27142 doesn't clear bar. Embedding-side weak lever. |
| H6 | Decoupled second-moment reset at cooldown | **CLOSED PR #512** — U-shape optimum at 0.5 (val=3.27142, Δ−0.00138 vs ctrl real but doesn't beat baseline). |
| H7 | Per-group weight decay re-sweep under eps=1e-6 | **CLOSED PR #539 NEG 11:38 UTC** — embed-WD destructive (+0.01067), carriers WD noise-neutral (+0.00067). Cosine cooldown shrinks late-stage update magnitudes too much for WD to regularize. Per-group asymmetry validated. |
| H8 | AdaBelief for aux | **BLOCKED unless fused implementation available.** |
| H9 | AdamW beta1/beta2 re-sweep under eps=1e-6 | Pending. Safe (still fused AdamW). May be scalar-tuning per user guidance — defer. |
| H10 | Lion (sign-based) for aux | **CLOSED PR #218 (2026-05-17) — decisively NEG; /√v adaptation is required for aux groups.** |
| H11 | Schedule-Free AdamW for aux | **CLOSED PR #531** — Polyak-Ruppert averaging lag incompatible with WSD/linear-cooldown stack. Endpoint ~3.278-3.288, all NEG. Combined with PR #265: SF categorically blocked. |
| H12 | Per-group LR sweep on lm_head/scalars | Pending — informed by PR #501 finding that lm_head/scalars carry eps=1e-6 win |
| H13 | Compound test: stack embed_lr=0.4 (askeladd PR #478) + embed_eps=1e-10 (PR #501 arm 2 finding) | Pending — leaderboard-win candidate if effects compound additively |
| H14 | Sophia (Hessian-diagonal preconditioner, NOT sign-mode) | Pending. Fresh preconditioner; ~50 LoC; needs occasional 2nd backward for Hessian estimate |
| H15 | Pruning ablation of MuLoCo outer wrapper | **CLOSED PR #536** — Nesterov momentum is the load-bearing axis (NOT averaging) |
| H16 | Cautious AdamW wrapper on aux | **CLOSED PR #544 NEG** — short-β1 kills the stale-momentum gap Cautious filters; ×3.1 LR amplification pushes out-of-distribution |
| H17 | SWA on aux during cooldown | **CLOSED PR #555 NEG 14:00 UTC** — Paired SWA-vs-iterate within 2 averaging arms: SWA worse than iterate (+0.00079, +0.00265). Wider window → more harm. Joins PR #200/#531 as weight-averaging-incompatibility triple. |
| H18 | Cooldown-aware `outer_momentum` ramp | **PR #563 nezuko ACTIVE 09:50 UTC** — directly exploits PR #536 finding |
| H19 | AGC clip ratio sweep (aux side) | Pending. Scalar tuning — defer per user directive. |
| H20 | AGC clip ratio × embed_lr interaction | Bookmarked from PR #478 closure. Defer. |
| H21 | outer_momentum × outer_lr joint sweep | Bookmarked: if H18 wins, joint sweep next |
| H22 | AdEMAMix (Pagliardini EMNLP 2024) on aux | **PR #567 fern ACTIVE 10:25 UTC** — dual-EMA preconditioner; post-hoc correction on fused AdamW |
| H23 | Sophia (Hessian-diagonal preconditioner) | Pending. Fresh preconditioner; ~50 LoC; needs occasional 2nd backward |
| H24 | Sharpness-Aware Minimization (SAM) on aux | Fresh; perturb-then-restore. May break fused kernel |
| H25 | MARS (Yuan 2025): variance-reduced AdamW | **PR #582 askeladd ACTIVE 14:05 UTC** — Control-variate gradient correction. 3 arms: ctrl, γ=0.025 (paper), γ=0.1. Compatible with WSD/linear-cooldown |
| H26 | Aux β1 cooldown ramp (0.8→0.95) | **CLOSED PR #572 15:11 UTC** — Mechanism incompatible: `param_groups['betas']` reassignment breaks fused AdamW state, NaN immediately. Schedule axis blocked at optimizer level. |
| H27 | STORM recursive variance-reduced gradient (Cutkosky & Orabona NeurIPS 2019) | **CLOSED PR #589 16:08 UTC** — Algebraic degeneracy under 1-FBP constraint. d_t = g_t identically. Genuine STORM requires 2nd FBP → violates contract. VR-via-control-variate fully covered by MARS (PR #582) under our constraints. |
| H28 | Gradient Centralization on aux AdamW (Yong et al CVPR 2020) | **PR #592 edward ACTIVE 16:13 UTC** — Pre-step gradient projection. Fresh mechanism class: gradient direction preprocessing. ~15 LoC. Cannot degenerate algebraically. |
| H29 | Catapult initialization (large initial LR step before cooldown) | Pending. Schedule idea, inner-side complement to outer momentum |

## Research direction (15:35 UTC)

**Primary active mechanism directions:**
1. **Variance-reduced gradient estimator family — paired H25/H27 race**:
   - **H25 MARS** (PR #582 askeladd ~44%) — EMA-anchored: `c_t = g_t + γ·β1·(m_{t-1} − g_{t-1})`, uses AdamW's internal `m_{t-1}`
   - **H27 STORM** (PR #589 edward, NEW 15:35 UTC) — recursive: `d_t = g_t + (1−α)·(d_{t-1} − g_{t-1})`, uses previously-corrected estimator
   These are **distinct mathematical formulations** within the variance-reduction family. Both insert pre-step on `p.grad` (fused-safe). Paired comparison isolates "EMA-anchored vs recursive" control-variate structure.
2. **Cooldown-phase momentum is amplified** (PR #536) — exploits status:
   - **H18 outer_momentum ramp** (PR #563 nezuko) — arm 2 cooldown-ramp **NEG (val=3.2799 vs ctrl 3.2714, +0.0085)**, arm 3 long-ramp ~61% trending NEG. Direction likely exhausted on outer side.
   - **H22 AdEMAMix** (PR #567 fern) — ctrl 3.2723 ✓, α=5 **3.2727 noise-neutral** (paired Δ+0.0004 within seed σ), α=8 ~31%. AdEMAMix at moderate α does not provide additive gain.
   - **H26 aux β1 cooldown ramp** (PR #572 edward) — **CLOSED NEG 15:11 UTC**, mechanism incompatible with fused state.
   Direction status: if H18 arm 3 NEG and H22 α=8 NEG, the "cooldown-momentum amplification" finding becomes a one-trick (it ONLY worked as MuLoCo's load-bearing component, doesn't extend to scheduling).
3. **🆕 NEW FUSED-STATE RULE (PR #572 closure)**: Do NOT propose schedule interventions that mutate `optimizer.param_groups[i]['betas']` (or other fused-kernel hyperparameters) mid-training. The β1-, β2-, eps-schedule axis is **closed at the optimizer level** on this stack. Only safe schedule insertion point: BEFORE `optimizer.step()` via `p.grad` modification.
4. **Weight averaging is structurally incompatible with WSD stacks** (triple-confirmed PR #200/#531/#555) — Do NOT propose weight-averaging variants. Cooldown shrinks step size but doesn't average iterates; the iterate IS the deployment target.
5. **Per-group asymmetry mental model** (twice-validated via PR #501 → PR #539) — embed vs lm_head/scalars behave asymmetrically across LR, β2, eps, WD. Per-group sweeps should be designed around the asymmetry.
6. **Pod-blocked work**: PRs #190 (alphonse NS5 sweep), #298 (tanjiro residual-init), #525 (frieren Lookahead) blocked on operator pod rotation. esc#25 posted 15:30 UTC.

**Generalizable mechanism principles (from PR #544 closure):**
- Cautious AdamW = WIN when β1 large AND aux LR not pre-tuned. Both prereqs fail here → structurally unsuitable.
- PR #510 unfused-NaN failure mode is NAdam-specific, NOT all unfused-AdamW. Per-implementation safety check needed.
- Post-hoc correction wrappers (Lookahead, SWA, AdEMAMix correction) on fused AdamW remain unconditionally SAFE.

**Saturated levers (no further work):**
- All per-group LR sweeps closed (embed PR #478, lm_head PR #481, scalars PR #475).
- All inner MuonH HPs (lr/mu/wd/warmup/cooldown/budget) closed.
- All MuLoCo outer HPs closed (sync_interval/outer_lr/outer_momentum) — but **pruning shows wrapper is mechanically essential**.

**Ctrl arm noise** (8 ctrl-equivalent samples post-PR #443, including PR #478 n=4 + fern arm 1 ctrl): sample stdev ≈ 0.00092. All ctrl samples land in band 3.27107–3.27399 with mean ~3.27250. Baseline `t1coza71` (3.27119) is a favorable-seed outlier at the lower edge of this band.

**Operator silence Issue #164**: esc#25 posted 15:30 UTC 2026-05-20 (~116h total operator silence). Fresh W&B post-rotation smoke verification confirms 3 r3 pods (alphonse/tanjiro/frieren) still NaN with ~147.5M nonfinite_count fingerprint. Re-check ~3h.

**Pod state anomalies (r3)**: alphonse, tanjiro, frieren confirmed broken at 15:25 UTC; thorfinn pod state ambiguous (GPU UUID unchanged since 2026-05-18 per student touchbacks, needs operator verification). No software fix available from inside the container.
