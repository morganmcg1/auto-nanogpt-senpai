# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-20 10:25 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro/thorfinn still broken; **frieren pod NEWLY ADDED** to rotation request at 04:09 UTC. **esc#31 posted 09:54 UTC** — ~107h total operator silence on alphonse/tanjiro/thorfinn; ~6h on frieren. esc#32 due ~13:00 UTC 2026-05-20.
- **Branch state:** Baseline post-PR #443 (Aux AdamW eps=1e-6, merged 13:25 UTC 2026-05-19). 🎉 **CURRENT BASELINE**.
- **🆕 PR #544 fern CLOSED 10:20 UTC — Cautious AdamW NEG, short-β1 stack incompatibility**: Arm 2 cautious+norm val=3.29606 best (terminal 3.43536 after +0.20 late-cooldown blowup), Δ+0.025 vs ctrl arm 1 (val=3.27189 baseline-match). **Mechanism finding**: ×3.1 effective LR amplification on unmasked coords pushes out-of-distribution from our population-tuned aux LRs; short β1=0.8 kills stale-momentum gap Cautious is designed to filter. Side diagnostic: unfused Cautious-AdamW path is numerically clean (PR #510 NaN failure is NAdam-specific, NOT all unfused-AdamW).
- **🆕 PR #567 fern REASSIGNED 10:25 UTC — H22 AdEMAMix (dual-EMA preconditioner)**: 3 arms — ctrl, α=5 with 30%-warmup, α=8 with 30%-warmup. Fresh mechanism (Pagliardini et al EMNLP 2024). Complements short-β1 by ADDING long-horizon m_2 (β3=0.9999) on top of fresh m_1 (β1=0.8). Post-hoc correction respects PR #510 fused constraint.
- **🆕 PR #536 nezuko CLOSED 09:45 UTC — MECHANISM FINDING: Nesterov momentum IS the load-bearing component (NOT averaging)**: 3-arm ablation. Arm 3 momentum=0 val=3.30224 (+0.03005, 3× worse than removing whole wrapper). Mental model: MuLoCo on single-GPU is "accumulated outer Nesterov momentum on top of inner stack", NOT distributed Polyak averaging.
- **🆕 PR #563 nezuko REASSIGNED 09:50 UTC — H18 cooldown-aware `outer_momentum` ramp**: Direct exploit of PR #536 finding (momentum marginal value INCREASES during cooldown).
- **🔴 PR #478 askeladd CLOSED 07:55 UTC**: n=4 mean=3.27211, embed-LR lever closed. Original n=1 monotone signal was ~1.5σ ctrl-arm seed inflation.
- **🟡 PR #539 edward arm 3 wd-all REPORTED 09:54 UTC**: arm 3 val=3.28321 (+0.01202 NEG, embed-WD destroys). All 3 WD arms NEG: arm 2 wd-carriers +0.00202, arm 3 wd-all +0.01202. **Arm 1 ctrl REDO in progress** (`9werg9o8`, started 09:38 UTC, ETA ~11:19 UTC). Student SENPAI-RESULT will follow arm 1 redo terminal.
- **🟡 PR #555 askeladd ARM 1 swa-ctrl FINISHED 10:09 UTC**: `ws2odsqa` val=**3.2738**, ffs=3150, reached target. Δ+0.00261 vs baseline (within population band). Arm 2 swa-10pct `n1cmpotm` launched 10:09:53 UTC, step 100, ETA ~11:50 UTC. Arm 3 swa-20pct follows.
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

## Active experiments (10:25 UTC 2026-05-20)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#567** | fern | **H22: AdEMAMix on aux** (NEW 10:25 UTC) | Assigned. Dual-EMA preconditioner: m_1 (β1=0.8 fast) + α·m_2 (β3=0.9999 slow). 3 arms: ctrl, α=5+30%warmup, α=8+30%warmup. Post-hoc correction respects fused-AdamW constraint |
| **#563** | nezuko | **H18: Cooldown-aware `outer_momentum` ramp** (09:50 UTC) | Assigned. Fresh schedule: static 0.5 ctrl, ramp 0.5→0.9 last 13%/40%. Directly exploits PR #536 finding |
| **#555** | askeladd | **H17: SWA on aux during last 10% cooldown** | Arm 1 swa-ctrl TERMINAL `ws2odsqa` **val=3.2738 ffs=3150 reached_target=1** (Δ+0.00261 vs baseline). **Arm 2 swa-10pct `n1cmpotm` launched 10:09:53 UTC, running, ETA ~11:50 UTC**. Arm 3 swa-20pct follows |
| **#539** | edward | **H7: Per-group AdamW WD under eps=1e-6** | **Arm 2 wd-carriers TERMINAL val=3.27321 (+0.00202 NEG)**. **Arm 3 wd-all TERMINAL val=3.28321 (+0.01202 NEG, embed-WD destroys)**. **Arm 1 ctrl REDO in progress** `9werg9o8` step 406/3325 ETA ~11:19 UTC. Student SENPAI-RESULT marker pending arm 1 redo |
| **#525** | frieren | **H2: Lookahead aux wrapper** (k=5; α=0.5 vs 0.8) | **POD ROTATION REQUESTED 04:09 UTC** — 8 NaN runs same step-25-125 fingerprint. esc#31 posted 09:54 UTC |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~107h** — GPU `g71b0d6`. esc#31 posted 09:54 UTC |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~107h** — NaN on GPU `gd125a8`. esc#31 posted 09:54 UTC |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED + DIRTY mergeable**. esc#31 posted 09:54 UTC |

## Recently closed PRs

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
| H7 | Per-group weight decay re-sweep under eps=1e-6 | **PR #539 edward ACTIVE 04:28 UTC** — ctrl + carriers (lm_head/scalars wd=0.01) + all-aux (embed wd=0.01 too) |
| H8 | AdaBelief for aux | **BLOCKED unless fused implementation available.** |
| H9 | AdamW beta1/beta2 re-sweep under eps=1e-6 | Pending. Safe (still fused AdamW). May be scalar-tuning per user guidance — defer. |
| H10 | Lion (sign-based) for aux | **CLOSED PR #218 (2026-05-17) — decisively NEG; /√v adaptation is required for aux groups.** |
| H11 | Schedule-Free AdamW for aux | **CLOSED PR #531** — Polyak-Ruppert averaging lag incompatible with WSD/linear-cooldown stack. Endpoint ~3.278-3.288, all NEG. Combined with PR #265: SF categorically blocked. |
| H12 | Per-group LR sweep on lm_head/scalars | Pending — informed by PR #501 finding that lm_head/scalars carry eps=1e-6 win |
| H13 | Compound test: stack embed_lr=0.4 (askeladd PR #478) + embed_eps=1e-10 (PR #501 arm 2 finding) | Pending — leaderboard-win candidate if effects compound additively |
| H14 | Sophia (Hessian-diagonal preconditioner, NOT sign-mode) | Pending. Fresh preconditioner; ~50 LoC; needs occasional 2nd backward for Hessian estimate |
| H15 | Pruning ablation of MuLoCo outer wrapper | **CLOSED PR #536** — Nesterov momentum is the load-bearing axis (NOT averaging) |
| H16 | Cautious AdamW wrapper on aux | **CLOSED PR #544 NEG** — short-β1 kills the stale-momentum gap Cautious filters; ×3.1 LR amplification pushes out-of-distribution |
| H17 | SWA on aux during cooldown | **PR #555 askeladd ACTIVE** — Arm 1 ctrl baseline-match; Arm 2 swa-10pct running |
| H18 | Cooldown-aware `outer_momentum` ramp | **PR #563 nezuko ACTIVE 09:50 UTC** — directly exploits PR #536 finding |
| H19 | AGC clip ratio sweep (aux side) | Pending. Scalar tuning — defer per user directive. |
| H20 | AGC clip ratio × embed_lr interaction | Bookmarked from PR #478 closure. Defer. |
| H21 | outer_momentum × outer_lr joint sweep | Bookmarked: if H18 wins, joint sweep next |
| H22 | AdEMAMix (Pagliardini EMNLP 2024) on aux | **PR #567 fern ACTIVE 10:25 UTC** — dual-EMA preconditioner; post-hoc correction on fused AdamW |
| H23 | Sophia (Hessian-diagonal preconditioner) | Pending. Fresh preconditioner; ~50 LoC; needs occasional 2nd backward |
| H24 | Sharpness-Aware Minimization (SAM) on aux | Fresh; perturb-then-restore. May break fused kernel |
| H25 | MARS (Yuan 2025): variance-reduced AdamW | Pending. Fresh variance-reduction mechanism |
| H26 | Aux β1 cooldown ramp (0.8→0.95) | Pending. Aux-side analogue of H18 (more inner-side momentum during cooldown) |
| H27 | Catapult initialization (large initial LR step before cooldown) | Pending. Schedule idea, inner-side complement to outer momentum |

## Research direction (08:00 UTC)

**Primary active mechanism directions:**
1. **🆕 MuLoCo Nesterov MOMENTUM is the load-bearing axis** (PR #536 CLOSED 09:45 UTC) — Mechanism: outer Nesterov compounds 30 inner deltas into one coherent kick. **Cooldown-phase momentum value INCREASES**. High-value mechanistic finding informs every cooldown-phase intervention.
2. **🆕 H18 Cooldown-aware outer_momentum ramp** (PR #563 nezuko 09:50 UTC) — Direct exploit of PR #536. Schedule outer_momentum 0.5→0.9 during cooldown.
3. **🆕 H22 AdEMAMix on aux** (PR #567 fern 10:25 UTC, NEW) — Dual-EMA preconditioner: fresh m_1 (β1=0.8) + long-horizon m_2 (β3=0.9999). Complements short-β1 by adding long-horizon component instead of removing fresh one (opposite of PR #544 Cautious approach).
4. **H17 SWA on aux during cooldown** (PR #555 askeladd) — Aux-only uniform-mean averaging across last 10%. Arm 1 swa-ctrl baseline-match (val=3.2738). Arm 2 swa-10pct running.
5. **Per-group WD under eps=1e-6** (PR #539 edward) — Both wd-arms NEG (arm 2 +0.00202, arm 3 +0.01201). Arm 1 ctrl redo in progress. Closing NEG once terminal marker arrives.
6. **Lookahead aux wrapper** (PR #525 frieren) — POD-BLOCKED.

**Generalizable mechanism principles (from PR #544 closure):**
- Cautious AdamW = WIN when β1 large AND aux LR not pre-tuned. Both prereqs fail here → structurally unsuitable.
- PR #510 unfused-NaN failure mode is NAdam-specific, NOT all unfused-AdamW. Per-implementation safety check needed.
- Post-hoc correction wrappers (Lookahead, SWA, AdEMAMix correction) on fused AdamW remain unconditionally SAFE.

**Saturated levers (no further work):**
- All per-group LR sweeps closed (embed PR #478, lm_head PR #481, scalars PR #475).
- All inner MuonH HPs (lr/mu/wd/warmup/cooldown/budget) closed.
- All MuLoCo outer HPs closed (sync_interval/outer_lr/outer_momentum) — but **pruning shows wrapper is mechanically essential**.

**Ctrl arm noise** (8 ctrl-equivalent samples post-PR #443, including PR #478 n=4 + fern arm 1 ctrl): sample stdev ≈ 0.00092. All ctrl samples land in band 3.27107–3.27399 with mean ~3.27250. Baseline `t1coza71` (3.27119) is a favorable-seed outlier at the lower edge of this band.

**Operator silence Issue #164**: esc#30 posted 06:53 UTC (~103h total operator silence on alphonse/tanjiro/thorfinn; ~3.5h on frieren). esc#31 due ~10:00 UTC if no operator action.

**Pod state anomalies (r3)**: frieren PR #525 hardware/driver fault diagnostically isolated via 8 NaN runs same step-25-125 fingerprint (~91% nonfinite_count). Cache-clear hypothesis falsified 04:08 UTC. No software fix available from inside the container.
