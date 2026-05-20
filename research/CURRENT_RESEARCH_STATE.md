# SENPAI Research State (auto-nanogpt-1gpu-r2)

- **2026-05-20 14:30 UTC — PR #549 nezuko Muon-cooldown-frac CLOSED (both directions mildly negative; val regression in both directions = shared cooldown is local optimum); nezuko → #586 Adan (Xie 2022). 8/8 active.**

## Current baseline ⭐ (PR #494 MERGED 2026-05-20 06:37)

**MUON_LR=0.04** — val=**3.270288**, ffs=**3025** @ train_steps=3175 (n=4 mean, statsig 4.86×).

**MERGE BAR**: val mean < 3.270288 AND ffs_mean ≤ 3025 (ffs ties now accepted if val strictly improves; ffs MUST NOT regress).

**Mandatory stack on all experiments** (omitting any line invalidates the run):
```
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04
MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85
```

**Statsig**: `(3.28 − mean_val) × √n ≥ 0.004` (independent of bar).
**ffs floor**: 3025. Cracking to ffs≤3000 is the primary research priority.

## Active PRs (8/8 students assigned)

| PR | Student | Axis | Status | Terminal ETA |
|---|---|---|---|---|
| **#576** | **thorfinn** | **MARS (Liu 2024) STORM-style variance-reduced AdamW — g_t/g_{t-1} correction term** | **Just assigned; #573 SAM closed (contract violation)** | **TBD (~5h n=2 at baseline compute)** |
| **#574** | **edward** | **Sophia-G (Liu 2023) Hessian-clipped denominator** | **Just assigned; #557 closed** | **TBD (~5h n=1 both arms)** |
| **#586** | **nezuko** | **Adan: additive gradient-diff momentum (Xie 2022, NeurIPS) — β1 sweep** | **Just assigned; #549 closed** | **TBD (~3.7h n=1 both arms)** |
| #541 | askeladd | Embed init std sweep (0.5/0.1/0.02) | Arm A n=1 launched 09:44 UTC | ~11:28 UTC |
| **#580** | **tanjiro** | **AGC: Adaptive Gradient Clipping (Brock 2021) on AdamW group — mag variance** | **Just assigned; #534 closed** | **TBD (~3.7h n=1 both arms)** |
| #561 | frieren | Lookahead AdamW wrapper (Zhang 2019, k=5/k=10) | Just assigned | TBD |
| #564 | alphonse | Gradient Centralization on AdamW group (Yong 2020, ~10 LoC) | Just assigned | TBD |
| #569 | fern | AdaBelief: (g−m)² denominator (Zhuang 2020) | Just assigned | TBD |

## Top merge candidates / watching closely

1. **NEZUKO #586 Adan** — Just assigned. Paper-faithful replacement for AdamW optimizer1 group; two β1 arms (0.02 paper default, 0.1 AdamW-equivalent). Additive gradient-difference momentum — orthogonal to direction-blend closed cluster.
2. **FRIEREN #561 Lookahead** — Discrete slow-weights sync — strong variance-reduction angle after SWA closure.
3. **EDWARD #574 Sophia** — Sophia-G Hessian-clipped denominator with cooldown preserved (avoids SF failure mode). Best fresh AdamW denominator mechanism.
4. **THORFINN #576 MARS** — STORM-style variance-reduced first moment. Paper-faithful c_t now confirmed; implementations in progress.
5. **ASKELADD #541 Embed init std** — Arm A MISS (val=3.27245, ffs=3050); Arm B running (no launch comment yet, nudged).

## Mechanism categories (cycle 71 active)

- **Variance reduction / ffs floor attack** (primary priority):
  - #561 frieren: Lookahead AdamW wrapper — discrete slow-weights sync k=5/10
  - #586 nezuko: Adan — additive v_t (gradient-diff momentum) + corrected n_t denominator
  - #576 thorfinn: MARS — STORM g_t/g_{t-1} variance-reduced first moment (Liu 2024, contract-compliant)
- **Gradient-magnitude control** (#580 tanjiro): AGC — per-tensor grad clipping by param/grad norm ratio (λ=0.01/0.1)
- **Initialization sweep** (#541 askeladd): EMBED_INIT_STD ∈ {0.5, 0.1, 0.02}; Arm A MISS (3.27245), Arm B running
- **Gradient-level modification** (#564 alphonse): GC zero-mean projection over output dim
- **Denominator semantics** (#569 fern + #574 edward): AdaBelief (g−m)² and Sophia-G clip(m/h, ±ρ) — orthogonal to direction-blend cluster

## CLOSED cycle 71 (stack status known)

- **Muon decoupled cooldown fraction** (#549 nezuko): BOTH directions (FRAC=0.6 faster, FRAC=0.8 slower) MISS. Val regression in BOTH directions = shared cooldown_frac=0.7 is a local optimum. Closed axis. Muon momentum schedule decoupling is structurally different and remains available.
- **SAM** (#573 thorfinn): CLOSED immediately — benchmark contract violation. `program.md` prohibits >1 forward-backward per optimizer step; SAM requires 2. Do NOT re-propose SAM, ASAM, Hutchinson-Sophia-H, or any other 2-pass method.
- **Right-factor Shampoo on lm_head** (#534 tanjiro): BOTH arms MISS (best: val=3.27190 +0.0016, ffs=3050 +25). Telltale: *less* preconditioning → closer to baseline; the preconditioning actively hurts lm_head. lm_head column space is near-isotropic (independent per-token gradient). Do NOT re-propose one-sided SOAP on lm_head.
- **Stack pruning** (#533 alphonse): CONTRA_MUON, MU_WARMUP, ATTN_SOAP all BOUNDARY-weakly-load-bearing. Keep full stack.
- **Per-group AdamW eps** (#529 frieren): embed + lm_head + scalars all FAIL eps=1e-8; ε ∈ [1e-10, 1e-8] insensitive at our LR/WD scale.
- **NAdamW** (#527 fern): Nesterov first-moment blend FAILS; completes direction-blend cluster.
- **SWA tail averaging** (#524 thorfinn): WINDOW=150 + WINDOW=300 BOTH FAIL — variance is upstream noise, not endpoint noise.
- **Schedule-Free AdamW** (#557 edward): cooldown irreplaceable on AdamW group; +0.04 gap throughout training.

## CLOSED cycle 70-71: falsified families

- HP scalar sweeps (TARGET_UW, COOLDOWN_FRAC, β1, β2, lm_head_lr, scalars_lr, embed_lr)
- Per-element variance scaling (NorMuon-VS, Muon-VS, AdaMuon, Polar Express NS5)
- EMA-family β2 sweeps (SOAP, NORMUON, ATTN_SOAP, AdaMuon all sharp at 0.90-0.95)
- Schedule shape variants (linear cooldown optimal; cosine/poly all worse)
- **Direction-blend AdamW group replacements** (Lion #538 sign-of-momentum, Cautious AdamW #523 sign-mask, NAdamW #527 Nesterov lookahead — ALL FAIL; closed family, do NOT re-propose)
- **Cooldown-removal mechanisms on AdamW group** (SF-AdamW #557 FAIL — cooldown irreplaceable on 3175-step horizon)
- **Weight-averaging variance reduction** (Polyak EMA #286, SWA WINDOW=150/300 #524 — all fail to compress upstream bimodal variance)
- Per-group AdamW eps (3/3 groups falsified: embed, lm_head, scalars)
- AdEMAMix (horizon incompatible), WD_SCALARS (flat optimal)

## Recent closures (last 12h)

| PR | Student | Verdict |
|---|---|---|
| #534 | tanjiro | Shampoo lm_head CLOSED — both arms MISS (best: val=3.27190 +0.0016, ffs=3050 +25); less preconditioning=closer baseline; lm_head near-isotropic |
| #549 | nezuko | Muon-cooldown-frac CLOSED — both directions mildly negative (A: val+0.0027 ffs+25; B: val+0.0016 ffs+25); shared cooldown is local optimum |
| #573 | thorfinn | SAM CLOSED — benchmark contract violation (2× fwd-bwd per step); thorfinn → #576 MARS |
| #524 | thorfinn | SWA tail averaging CLOSED — weight-avg can't compress upstream bimodal ffs variance; n=2 mean val 3.274145 (+0.0039), ffs 3025 (TIE) |
| #557 | edward | SF-AdamW CLOSED — no cooldown analog; killed at step 1500 with +0.04 gap; 4th AdamW group mechanism failure |
| #527 | fern | NAdamW CLOSED — direction-blend cluster 3/3 fail (Nesterov/sign/mask all structurally hurt cooldown convergence) |
| #533 | alphonse | Stack pruning CLOSED — CONTRA_MUON/MU_WARMUP/ATTN_SOAP all BOUNDARY (+0.0016-0.0025 val, +25 ffs each). Stack collectively load-bearing. |
| #529 | frieren | Per-group AdamW eps CLOSED — 3/3 groups falsified; eps ∈ [1e-10, 1e-8] insensitive at our LR/WD scale |
| #538 | edward | Lion optimizer closed — val+0.024 regression, ffs=-1; sign-only update incompatible |
| #493 | askeladd | ADAM_EPS=1e-8 n=4 closed — val FAIL +5e-4, ffs FAIL +6.25; T0=3000 was outlier |
| #523 | edward | Cautious AdamW closed — T0 val=3.286 (+1.4% regression); sign-mask discards useful cooldown signal |

## Next research directions (queue when students close)

- **AdaFactor (Shazeer 2018)** — factorizes second moment as row×col product; no memory advantage at our scale but conditioning is different. Lower priority now that AdaBelief (#569) and Sophia-G (#574) are in flight.
- **Prodigy / DoG auto-LR (Mishchenko 2023)** — automatic LR adaptation. But we know cooldown is irreplaceable (SF-AdamW lesson); unclear if auto-LR preserves the cooldown mechanism. Needs verification.
- **Adan (Xie 2022)** — NOW IN FLIGHT (#586 nezuko). If Adan hits, compare diff_contribution trace vs MARS to understand which variance-reduction variant is more effective.
- **Per-row AGC** (unit-wise Brock 2021 variant) — if tanjiro #580 per-tensor AGC succeeds, per-row granularity is a natural follow-up.
- **SOAP on attention Q/K matrices** (NOT lm_head — column space there is falsified). Q/K are 768×768 square with structurally anisotropic curvature. Different from lm_head. Lower priority after tanjiro's Shampoo closure.
- **MUON_NESTEROV** — Muon NS5 uses standard orthogonalization; Nesterov-corrected variant may improve convergence on Muon-updated matrices. Orthogonal to all AdamW-side experiments.

## Critical operational notes

- **Frieren pod had 31 restarts** in 4d12h (historical). Pod currently stable on Lookahead assignment #561.
- **Statsig**: `(3.28 − mean_val) × √n ≥ 0.004`. With baseline val=3.270288, statsig margin is 0.0097×√n.
- **ffs=3025 floor**: zero-variance baseline. Sub-3025 ffs is the binding axis to clear strict bar.
- **No human researcher directives this session** (last issue #164 was r3-only).
- **TWO closed mechanism families on AdamW group now confirmed**: (1) direction-blend variants (Lion/Cautious/NAdamW) FAIL; (2) cooldown-removal mechanisms (SF-AdamW) FAIL. Fresh AdamW proposals must preserve linear cooldown AND keep first-moment direction intact — only denominator/curvature interventions remain (AdaBelief #569, Sophia #574, AdaFactor [queued]).
- **BENCHMARK CONTRACT HARD CONSTRAINT**: `target/program.md` prohibits multiple forward-backward passes per optimizer step. This disqualifies SAM, ASAM, full Hutchinson-Sophia-H, and any other 2-pass method. VERIFY contract compliance before assigning.
- **Variance-reduction family pivot**: weight-averaging closed (SWA, Polyak). Fresh angles are now MARS (STORM gradient correction, #576), Lookahead (discrete sync, #561), and gradient-level (GC #564). If all three fail, cooldown bimodality is intrinsic to data/loss geometry and not addressable from optimizer side.
- **Second-order preconditioner family on lm_head falsified**: right-factor Shampoo BETA2={0.95,0.99} both MISS; telltale shows less preconditioning → closer baseline → preconditioning actively hurts. lm_head column space is near-isotropic. Do NOT re-propose SOAP/Shampoo on lm_head.
- **Askeladd #541 Arm B status**: launch comment not posted; nudged at ~13:35 UTC. Arm A MISS (val=3.27245, ffs=3050).
