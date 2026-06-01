# Aux Adam β₂ pulse PARAM-GROUP DECOMPOSITION — embed-only vs lm_head-only @ step 975 (decomposing the baseline #1532 WIN)

**Hypothesis owner:** askeladd (idle after #2025 SCALE-UP bilateral NULL closure)
**Date:** 2026-06-01 07:40 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux Adam β₂ pulse 0.95→0.99 @ step 975, ALL aux groups)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priority (d) momentum/preconditioner state handling. The current baseline #1532 applies the β₂ pulse to all 3 aux Adam param groups simultaneously: `embed`, `lm_head`, and `scalars` (gain/bias). The pulse is treated as a single atomic mechanism. **We have never decomposed it.**

Three plausible decompositions of the WIN:
1. The embed group is the load-bearing component — extending its variance memory at cooldown onset stabilizes token-direction representations that downstream blocks consume.
2. The lm_head group is the load-bearing component — extending its variance memory stabilizes logit calibration which directly controls val_loss.
3. The mechanism is JOINT — all groups contribute additively and partial pulses regress.

Each interpretation makes a falsifiable prediction. This is a **mechanistic decomposition experiment**, not an optimization sweep — high paper-narrative value regardless of outcome (positive: localizes the mechanism; null: validates the joint-pulse necessity).

## Distinguishing from prior closures

| PR | Mechanism | Scope | Result |
|---|---|---|---|
| #1532 (baseline WIN) | β₂ pulse 0.95→0.99 @ 975 | ALL aux groups (embed+lm_head+scalars) | WIN |
| #1592 / #1639 | β₁ pulse DOWN (→0.6) @ 975 | ALL aux groups | bilateral NULL |
| #1850 | aux scalar_lr boost @ 975 | scalars-only LR perturbation | bilateral NULL |
| #1787 | aux eps pulse co-located | ALL aux groups | bilateral NULL |
| #1785 | aux m+v reset @ 2600/2750 | ALL aux groups | bilateral NULL |
| **this PR** | **β₂ pulse 0.95→0.99 @ 975 LOCALIZED to embed-only / lm_head-only** | **subset of aux groups** | **DECOMPOSITION** |

This is the first experiment to test the canonical WIN's mechanism on aux-Adam SUBSETS rather than the full group.

## Mechanism

At step 975, instead of pulsing β₂ on all 3 aux Adam param groups simultaneously, we pulse β₂ on EXACTLY ONE group while leaving the others at the canonical β₂=0.95. Concretely:

- Aux Adam `optimizer1` has 3 param groups with explicit names (verified at line 800 of `records/track_3_optimization/train_gpt_simple.py`):
  - `adam_embed` — `model.embed.weight`
  - `adam_lm_head` — `model.proj.weight`
  - `adam_scalars` — all params with `ndim < 2` (gain/bias tensors)
- Each group has its own `betas=(β₁, β₂)` tuple in `group["betas"]`
- The existing `--aux_b2_pulse_step` mechanism (lines 1065-1073) iterates all groups; we add a scoping flag

If embed-only pulse matches baseline → the embed group is doing the work. The mechanism is about stabilizing token embeddings' variance estimator during cooldown.

If lm_head-only pulse matches baseline → the lm_head group is doing the work. The mechanism is about stabilizing the output projection's variance estimator (most directly val_loss-coupled).

If both regress vs baseline → the mechanism requires JOINT pulse; cross-group interaction is load-bearing.

If both improve vs baseline → JOINT pulse has destructive interference; one alone is better. Indicates the baseline is sub-optimal and we can improve further.

## Arms

**Arm A — β₂ pulse 0.95→0.99 LOCALIZED to `adam_embed` group only @ step 975**
- Other aux groups (`adam_lm_head`, `adam_scalars`) keep β₂=0.95
- Body PMuon unchanged
- Tests: is the embed group the load-bearing component?

**Arm B — β₂ pulse 0.95→0.99 LOCALIZED to `adam_lm_head` group only @ step 975**
- Other aux groups (`adam_embed`, `adam_scalars`) keep β₂=0.95
- Body PMuon unchanged
- Tests: is the lm_head group the load-bearing component?

## Implementation

Add a scoping flag to the existing aux β₂ pulse mechanism. The active script `records/track_3_optimization/train_gpt_simple.py` already has `--aux_b2_pulse_step` and `--aux_b2_pulse_target` flags; we add a group filter.

```python
parser.add_argument("--aux_b2_pulse_scope", type=str, default="all",
                    choices=["all", "adam_embed", "adam_lm_head", "adam_scalars"],
                    help="Restrict aux Adam β2 pulse to a single named param group (default: all)")
```

Refactor the existing pulse block (lines 1065-1073) to filter by `group["name"]`:

```python
if (args.aux_b2_pulse_step > 0
        and args.aux_b2_pulse_target > 0.0
        and step == args.aux_b2_pulse_step):
    pulse_count = 0
    for group in optimizer1.param_groups:
        group_name = group.get("name", "?")
        if args.aux_b2_pulse_scope != "all" and group_name != args.aux_b2_pulse_scope:
            continue
        old_b2 = group["betas"][1]
        group["betas"] = (group["betas"][0], args.aux_b2_pulse_target)
        pulse_count += 1
        print0(f"[step {step}] aux_b2_pulse({args.aux_b2_pulse_scope}): group={group_name} β2 {old_b2} → {args.aux_b2_pulse_target}", console=True)
    print0(f"[step {step}] aux_b2_pulse total: {pulse_count} group(s) pulsed", console=True)
```

Verification sentinel (Arm A): `[step 975] aux_b2_pulse(adam_embed): group=adam_embed β2 0.95 → 0.99` followed by `[step 975] aux_b2_pulse total: 1 group(s) pulsed`. For Arm B substitute `adam_lm_head` in both lines.

## Reproduce commands

### Arm A — adam_embed-only β₂ pulse @ step 975
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_b2_pulse_scope adam_embed \
  --wandb_group g1r1-askeladd-aux-b2-pulse-scope \
  --wandb_name g1r1-askeladd/aux-b2-pulse-975-arm-a-embed
```

### Arm B — adam_lm_head-only β₂ pulse @ step 975
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_b2_pulse_scope adam_lm_head \
  --wandb_group g1r1-askeladd-aux-b2-pulse-scope \
  --wandb_name g1r1-askeladd/aux-b2-pulse-975-arm-b-lm_head
```

**Chain rule:** Single-GPU chain. Run Arm A first. If sr=2875 with val_ema within 0.5 mnat of gate (val_ema < 3.263354), STOP and chain seed-2 of Arm A for n=2 confirmation BEFORE launching Arm B.

## Expected outcomes & paper-narrative interpretation

**Arm A WIN (embed pulse alone matches/beats baseline):** "The aux Adam β₂ pulse mechanism localizes to the token embedding group; lm_head and scalars do not contribute."

**Arm B WIN (lm_head pulse alone matches/beats baseline):** "The aux Adam β₂ pulse mechanism localizes to the output projection group; embedding stability does not require it."

**Both regress (~+1-3 mnat above baseline):** "The β₂ pulse mechanism requires joint application across all aux groups; partial pulses cannot recover the WIN. The baseline mechanism is irreducible."

**Both improve over baseline:** Surprising. Indicates destructive interference between groups when pulsed jointly. Follow-up: try embed + lm_head joint pulse with scalars excluded.

## Constraints

- Use the unmodified baseline stack (muon_lr=0.040, ema_beta=0.97, late-higher, paramEMA refresh @2600).
- The pulse step (975) and target (0.99) MUST match the canonical baseline.
- DO NOT include `--aux_b2_pulse_scope all` in any arm — that would just reproduce the baseline.
- Param groups are explicitly named at line 800 of `records/track_3_optimization/train_gpt_simple.py` (`adam_embed`, `adam_lm_head`, `adam_scalars`); use `group["name"]` for filtering.
- Post SENPAI-RESULT marker only after both arms terminate (or after Arm A wins decisively with n=2 confirmation).
