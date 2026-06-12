# Research Ideas — Open-Context SOTA Composition (2026-06-12 17:00 UTC)

**Prep work done during idle wait for human pick on Issue #2447 option A/B/C.** If human picks B (resume broader Open-Context Auto-nanoGPT SOTA arc per launch reminder), these are the first wave of concrete probes.

## Key references survey (gh CLI on KellerJordan/modded-nanogpt + morganmcg1/modded-nanogpt-senpai)

### KellerJordan #305 — Current public merged record (2925, n=8, val 3.27812750)

- **Builds on #300** stack (no main-trajectory changes)
- **Adds: Reduced Rank Extrapolation (RRE) overlay** near end of training
- Params: `extrap_start_step=2820`, `extrap_every=5`, RRE history k=4, `extrap_damping=0.875`, `extrap_max_rel=0.001`, `extrap_reset_momentum=False`, `extrap_stop_step=2925`
- Score: `(3.28 − 3.27812750) × √8 = 0.005296` ≥ 0.004 threshold

### KellerJordan #300 — Predecessor (2930, n=16, val 3.27844375)

- **Builds on #294** (radial brake)
- Adds: (1) **Aurora row-balanced polar on mlp.proj** — Tilde Research May 2026, K=3 outer iterations, β=0.25, ε=1e-7, applied only on the 12 wide `mlp.proj` 768×3072 matrices in `zeropower_via_newtonschulz5`; (2) Soft-Muon disabled (SOFT_MUON_CEIL: 0.80→0.00); (3) NorMuon-lite disabled (NOR_BETA2: 0.95→1.0); (4) Contra-Muon → normal ramp extended (CONTRA_TO_NORMAL_END_STEP: 2000→2500)
- Schedule: `train_steps=3020`, `schedule_steps=3050`, FINAL_LR_POWER=1.2

### Senpai #1532 — Audited 2905 (n=32, val 3.279022, margin 0.005531)

- **Mechanism: Aux Adam β₂ transient-INCREASE pulse @ cooldown onset (step 975), target β₂=0.99**
- Rationale: v buffer is load-bearing; optimizer wants MORE smoothing during cooldown (not less); slow decay so cooldown gradients get more weight in running mean
- Same-axis NULLs avoided: ≠ aux β2 transient-DECREASE (#1407), ≠ m/v zero-reset (#1487), ≠ aux LR phase-pulse (#1399/#1400/#1452), ≠ pEMA refresh (#1429)

### Senpai #1614 — Cleanup: aux β₂ pulse as canonical default

- Sets `--aux_b2_pulse_step=975`, `--aux_b2_pulse_target=0.99` as defaults

## Current Senpai rank-1 stack (per CURRENT_RESEARCH_STATE.md)

- NS5 inner iterations = 12 (H-FU optimal)
- Sinkhorn Arbor: load-bearing
- EMA-Nesterov: load-bearing
- **β₂ pulse 0.95→0.995 @ step 820** (= f=0.284 of T=2890) — note this is TIGHTER target & DIFFERENT step than the audited #1532 (which used 0.99 @ 975)
- RI capture step 2375, γ = −0.075
- AdamW eps = 1e-12
- Muon mu_warmup = 500 steps
- Rational logit soft-cap `15·x/√(x²+225)`

## Compositional gap analysis: what KellerJordan #305 has that Senpai doesn't

| Mechanism | KellerJordan #305 stack | Senpai rank-1 | Composition value |
|---|:-:|:-:|---|
| **RRE overlay near end** (#305 contribution) | ✓ | ✗ | **HIGH** — overlay, doesn't change main trajectory, 1-pass code |
| **Aurora row-balanced polar on mlp.proj** (#300) | ✓ | ✗ | **HIGH** — wide-matrix-only NS modification |
| **Radial brake** (#294, upstream of #300) | ✓ | ✗ | UNKNOWN — need to read #294 |
| **Contra-Muon ramp extended 2000→2500** (#300) | ✓ | ✗ | UNKNOWN — Senpai uses different Muon variant |
| Aux β₂ pulse @ cooldown (Senpai #1532) | ✗ (KellerJordan doesn't have) | ✓ | Already in Senpai stack |
| Sinkhorn Arbor (Senpai-original) | ✗ | ✓ | Already validated H-GH load-bearing |
| EMA-Nesterov (Senpai-original) | ✗ | ✓ | Already validated H-GH load-bearing |
| RI tail interpolation γ=−0.075 (Senpai-original) | ✗ | ✓ | Already in stack |

**The two highest-EV additions are RRE overlay (#305) and Aurora-on-mlp.proj (#300).** Both are minimally-invasive — RRE is an end-of-training overlay; Aurora applies only to wide matrices.

## First-wave probes (for 8 idle students if human picks option B)

### Wave 1 — pure composition adds (one mechanism per student, n=4 per probe)

**Probe 1 (alphonse, edward)**: **+RRE overlay** on rank-1 stack.
- Add RRE overlay starting at `extrap_start_step = train_steps × (2820/2925) ≈ 2790` (scaled to our T=2890), `extrap_every=5`, k=4, damping=0.875, max_rel=0.001, stop=2890 (training end).
- Hypothesis: RRE is post-trajectory acceleration; should compose multiplicatively with our pulse rule.
- 2 students × 2 seeds each = n=4.

**Probe 2 (askeladd, fern)**: **+Aurora-on-mlp.proj** in NS5 (K=3, β=0.25, ε=1e-7), gated on wide matrices only.
- Hypothesis: Aurora improves wide-matrix polar projection at zero forward/backward cost; orthogonal to β₂ pulse axis.
- n=4 across 2 students × 2 seeds.

### Wave 2 — reduction probes (after Wave 1, if Wave 1 wins)

**Probe 3 (frieren, nezuko)**: **rank-1 stack − Sinkhorn Arbor, + Aurora-on-mlp.proj**.
- Hypothesis: Aurora may dominate Sinkhorn Arbor mechanistically (both project the optimizer step); Occam check.

**Probe 4 (tanjiro, thorfinn)**: **rank-1 stack + RRE + Aurora** (Wave 1 winners stacked).
- Hypothesis: if both pure adds win, do they compose?

### Step budget for first-wave promotion

- Screen each probe at T=2890 (current rank-1 budget) — this is where our pulse rule is calibrated.
- Promotion threshold: same-step val/loss ≤ baseline mean − 0.0003 (strong) or − 0.0001 (weak) at n=4.
- For promotion to fixed-step Track-3 evaluation: re-run at predeclared fixed step (start with 2880, then 2860).

### Mechanism-orthogonality notes

- **RRE + β₂ pulse**: separately motivated, different layers. Pulse changes preconditioner adaptation rate during cooldown (steps 820-2890). RRE is an end-of-training parameter-space overlay (steps 2790-2890). They overlap in the late phase but at different abstraction layers.
- **Aurora + NS5 inner iterations**: Aurora replaces 12-iter Newton-Schulz on wide matrices with K=3 outer Aurora iterations (each containing NS internally). The Senpai-validated NS5_inner=12 may not be the optimal inner setting under Aurora; recommend testing inner_iters ∈ {12, 8} for Aurora variant separately.

## What NOT to do (held / declined)

- Don't re-tune scalar HPs (LR, WD, betas) as the first probe — launch reminder explicitly says "Do not spend the whole run on scalar hyperparameter tuning." Re-tune ONLY if a probe needs it for fair comparison.
- Don't add Contra-Muon ramp blindly — Senpai uses NS5_inner=12 + Sinkhorn Arbor + EMA-Nesterov; Contra-Muon's interaction with our Muon variant is unclear without reading #294.
- Don't combine RRE + Aurora + Sinkhorn-Arbor-removed in Wave 1 — too many variables at once. Sequential composition only.

## Open questions to resolve via reading more PRs (if time permits)

1. **What is "radial brake" (#294)?** Mentioned as upstream of #300. Could be load-bearing.
2. **What is "Contra-Muon"?** Mentioned in #300; not in Senpai stack. Could be a Senpai-specific Muon variant.
3. **What does Senpai's RI do mechanistically vs. KellerJordan's late-trajectory tools?** Both are end-of-trajectory adjustments; do they compete or compose?

## Operational notes for option B handoff

- T=4500 schedule bug remains uneresolved; if the human picks A (repair via `--final_schedule_steps`), the same probes can run at fixed budget.
- All probes should declare `--wandb_group "open-sota-v2-composition-wave1"` so the matrix is queryable later.
- Strict serial execution per student (no duplicate torchruns); same anti-duplication discipline as the just-closed protocol matrix.
- All probes require terminal SENPAI-RESULT marker.

**Status: PREP COMPLETE.** This doc is positioned as ready-to-execute IF human picks B. No PRs assigned without explicit re-authorization.
