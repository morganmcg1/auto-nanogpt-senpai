# H388: AUX Weight-Decay Cooldown Ramp

**Student:** g1r3-askeladd
**Date:** 2026-06-02
**Status:** READY FOR ASSIGNMENT
**WIN probability:** ~6%
**LoC estimate:** ~22 LoC (2 CLI args + fused-flag update + WD block in set_hparams)

---

## What it is

Per-group `weight_decay` on the AUX AdamW optimizer (embed, lm_head, scalars) starts at 0 throughout the steady-state phase and linearly ramps to a peak value during the final 40% of training — the AUX cooldown phase that already begins at `int(0.6 * train_steps)`. This mirrors the existing β2 cooldown ramp infrastructure exactly.

---

## Why it might help here

AdamW weight decay during steady-state can fight useful gradient-driven updates. But during the cooldown LR decay, the effective update magnitude shrinks, so a simultaneous WD ramp can serve as a soft regularization pass — pulling embed/lm_head/scalar parameters back toward small norms at the moment when the model is being "polished" rather than learned from scratch. The AUX parameters (embed in particular) are not covered by MuonH's scale-invariant projection, so they can grow unconstrained; the ramp targets exactly that accumulation window.

The rationale parallels the β2 cooldown ramp: both are "late-phase parameter conditioning" actions, not steady-state algorithmic changes. The β2 ramp already provides a confirmed implementation template and infrastructure; the WD analog is the natural next axis along that family.

---

## Orthogonality reasoning

This is DISTINCT from every closed or in-flight axis:

- **H142** (embed static WD): constant WD throughout all training steps — no temporal component. Closed NULL.
- **H285** (per-group LR×WD static coupling): static scalar ratios at construction, noise-neutral for lm_head. Closed.
- **H228** (body WD): `scale_invariant` mode makes body WD a mathematical no-op (lines 709-716). H228 confirmed and closed. H388 targets AUX only, where scale_invariant does NOT apply.
- **H381** alphonse (MuLoCo VALUE per-group): outer optimizer. Orthogonal.
- **H382** thorfinn (MuLoCo RESET): outer optimizer. Orthogonal.
- **H383** edward (unrelated mechanism): orthogonal.
- **H384** tanjiro (MuLoCo FREQUENCY-schedule): outer optimizer. Orthogonal.
- **H385** frieren (in-flight): orthogonal.
- **H386** nezuko (in-flight): orthogonal.
- **H387** fern (MuLoCo SGDR OUTER): outer optimizer. Orthogonal.
- **β2 cooldown ramp** (existing merged infrastructure): ramps momentum, not weight decay — distinct axis within same AUX cooldown family.
- **AUX adaptive-scaling preconditioner family CANALIZED** (LaProp, Adan β₃, Sophia-H, Lion, Schedule-Free, AdEMAMix): second-moment / curvature axes. H388 is a regularization axis, not a preconditioner axis.
- **GRADIENT-LAYOUT-CENTERING** (H378 CLOSED): gradient preprocessing on BODY pre-NS5. Orthogonal layer.

No prior test of TEMPORAL/SCHEDULED WD on AUX AdamW groups exists in EXPERIMENTS_LOG.md. Axis confirmed open.

---

## Implementation (~22 LoC)

All line numbers reference `records/track_3_optimization/train_gpt_simple.py`.

### Step 1: 2 new CLI args (after existing `aux_beta2_end` arg, ~line 87)

```python
parser.add_argument("--aux_wd_schedule", type=str, default=os.environ.get("AUX_WD_SCHEDULE", "off"),
                    choices=["off", "cooldown_ramp"],
                    help="WD schedule on AUX AdamW groups. 'off' = WD=0 throughout (baseline). "
                         "'cooldown_ramp' = WD ramps 0->aux_wd_cooldown_peak linearly across AUX cooldown phase.")
parser.add_argument("--aux_wd_cooldown_peak", type=float,
                    default=float(os.environ.get("AUX_WD_COOLDOWN_PEAK", "0.0")),
                    help="Peak WD at end of AUX cooldown ramp (only used if aux_wd_schedule=cooldown_ramp).")
```

### Step 2: Update fused flag (line 934, `_aux_fused = ...`)

Current:
```python
_aux_fused = (args.aux_beta2_schedule == "constant")
```

Replace with:
```python
_aux_fused = (args.aux_beta2_schedule == "constant" and args.aux_wd_schedule == "off")
```

Rationale: PyTorch's fused AdamW reads weight_decay once at step start; per-group WD mutation on every step requires the unfused path (same reason β2 ramp already disables fused).

### Step 3: WD ramp block in `set_hparams` (insert after β2 block ending ~line 1012, before return)

```python
# H388: AUX WD cooldown ramp — 0 during steady-state, linear ramp during AUX cooldown phase
if args.aux_wd_schedule == "cooldown_ramp":
    cooldown_start = int((1.0 - aux_cooldown_frac) * train_steps)
    if step < cooldown_start:
        wd_t = 0.0
    else:
        prog = (step - cooldown_start) / max(1, train_steps - cooldown_start)
        wd_t = prog * args.aux_wd_cooldown_peak
else:
    wd_t = 0.0
for g in optimizer1.param_groups:
    g["weight_decay"] = wd_t
```

No change to the return value `(muonh_warmup, b2, mu_t)` at line 1036 — `wd_t` is already logged automatically by the existing telemetry loop at line 300:

```python
metrics[f"train/weight_decay/{group_name}"] = group.get("weight_decay", 0.0)
```

This means `train/weight_decay/adam_embed`, `train/weight_decay/adam_lm_head`, and `train/weight_decay/adam_scalars` will trace the ramp in W&B at zero additional telemetry cost.

### Total LoC: 22 lines (10 CLI + 1 fused flag + 11 WD block)

---

## 3-Arm Chain Design

### arm_a CTRL (Pattern A bit-identity verification)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --aux_wd_schedule off \
  --wandb_name "g1r3-askeladd/H388-arm_a-ctrl" \
  --wandb_group "H388-aux-wd-cooldown-ramp"
```

`--aux_wd_schedule off` is the default via `os.environ.get("AUX_WD_SCHEDULE", "off")` — but specify it explicitly to make the chain arm unambiguous.

**Required:** step-0 val loss = **10.82583 EXACT**. If this deviates, there is a code bug or config drift; stop and fix before launching arm_b/arm_c.

Expected FFS: ~3000 (H266 baseline).

### arm_b MILD (launch after arm_a verifies bit-id)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --aux_wd_schedule cooldown_ramp \
  --aux_wd_cooldown_peak 1e-3 \
  --wandb_name "g1r3-askeladd/H388-arm_b-wd1e-3" \
  --wandb_group "H388-aux-wd-cooldown-ramp"
```

Rationale for 1e-3: conservative — roughly matching standard AdamW WD for small-embedding regimes without aggressive shrinkage.

### arm_c MODERATE (launch in parallel with arm_b or after arm_b completes)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --aux_wd_schedule cooldown_ramp \
  --aux_wd_cooldown_peak 5e-3 \
  --wandb_name "g1r3-askeladd/H388-arm_c-wd5e-3" \
  --wandb_group "H388-aux-wd-cooldown-ramp"
```

Rationale for 5e-3: typical AdamW WD in transformer training. Upper bound before significant embed shrinkage risk.

---

## Decision Rules

**Gate 1 (arm_a):** step-0 val must equal 10.82583. Deviation = implementation bug; fix and re-run before proceeding.

**Primary WIN condition (arm_b or arm_c):**
- `speedrun/final_first_step_to_target` (FFS) < 3000 (strict beat of H266 baseline), AND
- Statistical rule satisfied: `(3.28 - mu) * sqrt(n) >= 0.004`
  - Single run: mu < 3.276 required
  - Two runs: mu < 3.278 sufficient

**If arm_b beats baseline but arm_c does not:** merge arm_b configuration; note that 1e-3 is the optimal region. Propose a follow-up dose-response (e.g. 5e-4, 2e-3).

**If arm_c beats baseline but arm_b does not:** merge arm_c configuration; the signal requires more aggressive WD. Propose upper-range extension (1e-2).

**If neither arm beats FFS=3000 but both produce val/loss < 3.276:** send back to student with instruction to run a second seed to attempt statistical closure.

**If both arms are worse than CTRL FFS:** close as NULL. Do not propose further WD ramp variants — this closes the AUX temporal WD axis.

**If arm_b or arm_c shows val loss divergence or FFS=-1:** close as NEG. Check W&B `train/weight_decay/adam_embed` trace to confirm ramp was active; also check `train/weight/rms` for embed shrinkage pathology.

---

## Causal story and falsification

**Mechanism targeted:** AUX parameters (embed, lm_head, scalars) accumulate unconstrained norm during training because body scale-invariance does not apply to them, and existing WD=0 leaves this growth unchecked. During the cooldown phase, LR decays but WD=0 means the optimizer cannot "clean up" this norm overhang. A ramp that coincides with the cooldown applies light regularization exactly when the model has the most capacity to absorb it without disrupting gradient-driven learning.

**Expected observable:** `train/weight_decay/adam_embed` trace should show a clean linear ramp from step ~2010 to step ~3350 in W&B. `train/weight/rms` for embed should be slightly lower at final step in arm_b/arm_c vs CTRL. If ramp is active but embed norm is identical, the optimizer is not applying WD correctly — check fused=False path.

**Falsifying result:** arm_b and arm_c FFS identical to arm_a CTRL within noise — this would indicate the AUX WD ramp has no effect on convergence speed (the embedding norm overhang hypothesis is wrong or the effect size is below the noise floor at single-run resolution).

---

## Known caveats and gotchas

1. **fused=False path:** The critical update to `_aux_fused` at line 934 must include BOTH conditions (β2_schedule AND wd_schedule). If only one condition is changed, fused AdamW will silently ignore the per-step WD mutation. The telemetry trace `train/weight_decay/adam_embed` will show all-zeros even in treatment arms, which is the diagnostic for this bug.

2. **aux_cooldown_frac variable scope:** `aux_cooldown_frac = 0.4` is set at line 957, inside the training setup block, and `set_hparams` is a nested function that closes over `train_steps` and `aux_cooldown_frac`. The WD block can use `aux_cooldown_frac` directly without passing it as a parameter, just as the β2 ramp does at line 999.

3. **Ramp start alignment:** The `cooldown_start` in the WD block should use `aux_cooldown_frac` (0.4), NOT `h_cooldown_frac` (1.0). Using the wrong fraction would start the ramp at step 0 (body cooldown fraction = 1.0 means cooldown_start = 0), which would corrupt the CTRL equivalence check at arm_a if the formula is tested.

4. **Peak value upper bound:** Do not test values above 1e-2 without verifying embed norm health. Values >= 0.1 in AdamW with AUX LR=0.3 can cause significant embed shrinkage during the cooldown phase and may produce FFS=-1 rather than a smooth late-phase improvement.

5. **β2 ramp interaction:** If both `aux_beta2_schedule=cooldown_ramp` and `aux_wd_schedule=cooldown_ramp` are active simultaneously, both ramps are applied. For H388, arm_b/arm_c should use the default `aux_beta2_schedule=constant` (i.e., do NOT stack both ramps) to keep the test clean. The existing default for `aux_beta2_schedule` is `"constant"` so no extra flag needed — but verify this in the run config.

---

## Research state update

**Current best explanation for what limits progress:** The H266 Polyak-Ruppert EMA win (decay=0.05) is the single confirmed mechanism. 236 cumulative NULL/NEG closures suggest the local optimizer-hyperparameter neighborhood of the current stack is well-explored. The dominant in-flight theme is MuLoCo outer-loop axis exploration (H381/H382/H384/H387) and AUX preconditioner alternatives (already canalized at 6 axes). H388 probes a qualitatively different axis: late-phase regularization of AUX parameters, which has not been tested in any temporal/scheduled form.

**Ruled-out paths (do not repeat):**
- Static WD on any AUX group (H142, H285 — noise-neutral)
- Body WD in scale_invariant mode (H228 — mathematical no-op)
- Lion on any of the 3 optimizer scopes (H379v2 OUTER, H260 BODY, H169/H241/H260/H369 AUX — full closure)
- GC on BODY pre-NS5 (H378 — CLOSED, polar step absorbs GC geometry)
- Lookahead outer wrapper (H377 — K-INVARIANT STRONG NEG)
- Temporal gating on outer loop (H367 — CATASTROPHIC)

**Open uncertainties:**
1. Whether the AUX embed norm accumulation during training is large enough to matter for convergence speed (H388 directly tests this).
2. Whether MuLoCo outer-loop axis exploration (H381/H382/H384/H387) will find a win that compounds with EMA.
3. Whether any combination of the above closed mechanisms has an interaction effect that was missed by the individual-axis design.

**Next discriminating experiment after H388:** If H388 closes NULL, the AUX temporal regularization axis is exhausted and the research should pivot toward initialization scaling (unembed/embed variance) or a fresh optimizer class for the outer loop.

**Stop condition for AUX WD axis:** If both arm_b (1e-3) and arm_c (5e-3) show identical FFS to arm_a CTRL, close the axis. Do not propose a third WD peak without a new mechanistic reason.

---

## Taste rubric

**Research mode:** frontier refinement (leveraging existing cooldown infrastructure to probe an untested AUX regularization axis)

| Criterion | Score | Justification |
|---|---|---|
| Mechanistic grounding | 3 | Targets a specific observed gap: AUX WD=0 throughout training, scale_invariant confirmed not to apply to AUX params (H228), β2 ramp already confirmed as working infrastructure template. Mechanism is falsifiable via WD telemetry trace. |
| Research-state value | 3 | Result will either (a) confirm AUX temporal regularization as a viable axis or (b) close it definitively, sharpening the map either way. The diagnostic (WD trace in W&B) separates implementation bugs from genuine null effects. |
| Execution value | 3 | ~22 LoC, mirrors existing β2 ramp infrastructure exactly, CTRL arm at zero extra cost, telemetry already in place, clean 3-arm design with pre-declared stop condition. |

**Overall: 3/3/3 — clean, cheap, falsifiable, mechanism-grounded.**

---

## WIN probability: ~6%

Realistic estimate given:
- Cycle ~2700, 236 cumulative NULL/NEG/TIE, 1 MERGED WIN (EMA decay=0.05)
- Base rate: ~0.4% per experiment
- Upside adjustors: (a) axis confirmed open — no prior temporal WD test; (b) strong structural analogy to β2 cooldown ramp which motivated a successful infrastructure addition; (c) AUX parameters are the one group NOT covered by scale_invariant, so WD has a real mathematical foothold; (d) 22 LoC with no architectural risk
- Downside adjustors: (a) effect size on convergence speed may be below single-run noise floor; (b) late-phase regularization may not translate to step count reduction; (c) embed norm may not be large enough at cooldown start to matter
- Net: ~6% (roughly 15× base rate — uncommon but mechanistically motivated)
