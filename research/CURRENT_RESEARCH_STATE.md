# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-20 04:10 UTC
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse/tanjiro still broken; **frieren pod NEWLY ADDED** to rotation request at 04:09 UTC. **Escalations through esc#29+add-on (04:09 UTC 2026-05-20)** — ~99.5h total operator silence on alphonse/tanjiro. esc#30 due ~07:00 UTC 2026-05-20.
- **Branch state:** Baseline post-PR #443 (Aux AdamW eps=1e-6, merged 13:25 UTC 2026-05-19). 🎉 **CURRENT BASELINE**.
- **🟢 ACTIVE WIN DIRECTION (cooling):** askeladd PR #478 embed_lr n=4 confirm arm 1 (val=3.27277) significantly WORSE than n=1 single-arm 3.27213. arm 2 ETA 04:00; running mean 3.27277 after n=1 doesn't clear conservative bar 3.27079. Wait for n=4.
- **🆕 KEY MECHANISTIC FINDING (PR #510 CLOSED 01:30 UTC):** Unfused optimizer path produces NaN at step-3 forward under the current aux stack (eps=1e-6 + AGC + per-group LR). Plain `AdamW(fused=False)` shows identical failure. **Implication**: any aux optimizer without a fused kernel (NAdam, AdaBelief unfused, AdaFactor) is BLOCKED. Lookahead/Lion/SWA wrappers around fused AdamW are SAFE.
- **🆕 PR #525 frieren POD ROTATION REQUESTED 04:09 UTC**: 8 separate NaN runs at step 25–125 (`gm8z8yej / jx9m9ah5 / 3z6utx5l / lokz88lw / h22dzj1i / 87wznxfr / 876gasq0 / pu4hxo61`) with identical `nonfinite_count ≈ 1.48e8` (~91%) fingerprint. Ruled out: GPU contention, code bug, torchinductor cache (cleared + relaunched → same step-125 NaN). Cross-pod baseline produces healthy val ≈ 3.271 today. Conclusion: **pod hardware / CUDA state issue**. Frieren PR parked in WIP; pod added to Issue #164 rotation list.

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

## Active experiments (03:50 UTC 2026-05-20)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#536** | nezuko | **H15: MuLoCo outer-step pruning ablation** (`--use_outer_optimizer 0`) | **NEWLY ASSIGNED 03:48 UTC** — ctrl + OFF + momentum=0 arms |
| **#531** | fern | **H11: Schedule-Free AdamW for aux** (replaces aux linear cooldown w/ PR-averaging) | Assigned 02:05 UTC — ctrl running step ~1328 |
| **#525** | frieren | **H2: Lookahead aux wrapper** (k=5; α=0.5 vs 0.8) | **POD ROTATION REQUESTED 04:09 UTC** — 8 NaN runs, same step-125 nonfinite fingerprint, cache-clear didn't fix. Hypothesis still valid; awaiting clean pod. |
| **#512** | edward | **H6: Aux v_t reset at cooldown onset** (`reset_frac`=1.0/0.5/0.1) | Arm 1 (1.0) 3.27280; Arm 2 (0.5) **3.27142** (BEST so far, Δ−0.00138 vs ctrl); Arm 3 (0.1) ETA ~04:00 |
| **#478** | askeladd | **embed LR n=4 confirmation @ 0.4** | Arm 1 (n=4 arm 1) terminal val=3.27277 ffs=3125 (WORSE than 1-shot 3.27213). Arms 2/3/4 ETA 04:00/05:40/07:25 |
| **#412** | thorfinn | **Aux AdamW warmup_steps sweep** | **POD-BLOCKED ~99.5h** — GPU `g71b0d6`. esc#30 due ~07:00. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED ~99.5h** — NaN on GPU `gd125a8`. esc#30 due ~07:00. |
| **#190** | alphonse | **NS5 iter count sweep** (k=8/12/16) | **POD-BLOCKED/MERGE_CONFLICT** — `gd103cc`. esc#30 due ~07:00. |

## Recently closed PRs

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
| H3 | SWA / EMA averaging on aux at cooldown | **PR #200 NEG (full model)**. Aux-only SWA likely same mechanism — skip. |
| H4 | Nesterov AdamW (NAdam) | **CLOSED PR #510 — unfused path NaN.** |
| H5 | Embed init std sweep | **CLOSED PR #507** — non-monotonic U-shape; std=0.02 best at 3.27142 doesn't clear bar. Embedding-side weak lever. |
| H6 | Decoupled second-moment reset at cooldown | PR #512 edward ACTIVE — arm 1 ctrl 3.27280, arm 2 (0.5) **3.27142 BEST**, arm 3 (0.1) ETA ~04:00 |
| H7 | Per-group weight decay re-sweep under eps=1e-6 | Pending. Safe. |
| H8 | AdaBelief for aux | **BLOCKED unless fused implementation available.** |
| H9 | AdamW beta1/beta2 re-sweep under eps=1e-6 | Pending. Safe (still fused AdamW). May be scalar-tuning per user guidance — defer. |
| H10 | Lion (sign-based) for aux | **CLOSED PR #218 (2026-05-17) — decisively NEG; /√v adaptation is required for aux groups.** |
| H11 | Schedule-Free AdamW for aux | **PR #531 fern ACTIVE** — applies SF only to aux (linear cooldown) to avoid PR #265's WSD-incompat failure |
| H12 | Per-group LR sweep on lm_head/scalars | Pending — informed by PR #501 finding that lm_head/scalars carry eps=1e-6 win |
| H13 | Compound test: stack embed_lr=0.4 (askeladd PR #478) + embed_eps=1e-10 (PR #501 arm 2 finding) | Pending — leaderboard-win candidate if effects compound additively |
| H14 | Sophia (Hessian-diagonal preconditioner, NOT sign-mode) | Pending. Fresh preconditioner; ~50 LoC; needs occasional 2nd backward for Hessian estimate |
| H15 | Pruning ablation of MuLoCo outer wrapper | **PR #536 nezuko ACTIVE 03:48 UTC** — CLI-only ctrl/OFF/momentum=0 arms |
| H16 | AGC clip ratio sweep (aux side) | Pending. Scalar tuning — defer per user directive. |

## Research direction (03:50 UTC)

**Primary active win directions:**
1. **embed_lr n=4 confirm** (PR #478 askeladd) — n=4 arm 1 val=3.27277 ffs=3125. WORSE than n=1 single arm 3.27213. Conservative n=4 bar 3.27079 unlikely; wait for n=4 mean before judging direction.
2. **v_t reset at cooldown** (PR #512 edward) — H6 arm 2 (v_reset=0.5) val **3.27142** BEST so far Δ−0.00138 vs ctrl Δ+0.00023 vs baseline. Arm 3 (0.1) ETA ~04:00 will tell us if smaller reset is even better.
3. **Schedule-Free AdamW for aux** (PR #531 fern) — H11 ctrl arm running step 1328. Fresh schedule-mechanism — strong fit for user directive.
4. **MuLoCo pruning ablation** (PR #536 nezuko 03:48 UTC) — H15 tests whether the MuLoCo outer wrapper is load-bearing on single-GPU r3. Pure CLI-flag prune.
5. **Lookahead aux wrapper** (PR #525 frieren) — H2 mechanism BLOCKED by pod-state NaN cascade; cache-clear smoke pending.

**Ctrl arm noise** (7 ctrl-equivalent samples): mean Δ = +0.00169, sd ≈ 0.00115. All positive — baseline `t1coza71` is a favorable-seed outlier. Any win must clear +0.0008 vs 3.27119 to be above noise.

**Operator silence Issue #164**: ~99.5h total, esc#29 posted 02:38 UTC, esc#30 due ~07:00 UTC.

**Pod state anomalies (r3)**: frieren PR #525 hits NaN at step 25 on `--aux_lookahead_k 0` (code-byte identical to baseline command). Other students at same baseline on different pods (e.g. `z814787y`, `qvsm40in`) finish normally. Working hypothesis: stale `/tmp/torchinductor_root/` from 4d15h of file edits. If cache-clear smoke also NaN's, frieren will request pod rotation on Issue #164.
