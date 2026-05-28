# Research Ideas — edward fresh axis — 2026-05-28

## RECOMMENDATION SUMMARY (for senpai:assign-experiment)

**Student:** g1r5-edward
**Slug:** mu-mlp-attn-decouple
**Axis:** Decouple Muon body momentum — separate `--mu_mlp` and `--mu_attn` scalars replacing the single shared `mu=0.95`.
**Recommended primary cell:** B = `--mu_mlp 0.95 --mu_attn 0.85`
**Rationale:** Attn SOAP cos_sim ~0.798 < MLP ~0.884. Lower attn momentum lets SOAP corrections dominate more on each step where cos_sim is weaker. Exact structural analogue to edward's own winning PR #162 (lr_mlp vs lr_attn). Fresh axis — not closed, not in-flight.
**Gate (FFS-primary directive #1262):** Cell B FFS ≤ 2975 at n=1 before any n=4 confirm. Merge gate: μ_4(FFS) ≤ 2918.75.

---

## Hypothesis Title

**Per-group Muon body momentum: decouple `mu_mlp` and `mu_attn` to exploit differential SOAP-alignment between MLP and attention matrices**

---

## Mechanism

Muon currently applies a single `mu=0.95` to all body matrices. This means the MLP fc/proj weights and the attention Q/K/V/proj weights share the same exponential moving-average decay for the momentum buffer. However, the two groups sit at different positions in the SOAP alignment landscape: from PR #116 baseline diagnostics, SOAP-Muon cosine similarity is ~0.884 for MLP matrices and ~0.798 for attn matrices. The weaker alignment in attn means that on each step the SOAP-preconditioned direction and the NS-orthogonalized direction diverge more — a higher momentum buffer in that context accumulates directional error over more steps before the SOAP correction can redirect it. Reducing attn momentum (e.g., from 0.95 to 0.85) shortens the effective look-back window on attn gradients, giving the per-step SOAP preconditioner more influence relative to the stale accumulated direction, which may improve the sharpness and responsiveness of attn weight updates especially in the late cooldown phase when curvature shifts most rapidly.

The structural analogue is exact: edward's PR #162 found that splitting lr_mlp=0.055 and lr_attn=0.035 (vs. a shared default) was a win. Momentum and learning rate are both first-order scale knobs on the Muon update; decoupling momentum is the natural companion experiment. The Muon class already supports per-group `mu` via the dict-of-groups interface — this is a two-flag addition with zero structural risk.

---

## 5-Cell Sweep Specification

All cells use the full R5 mandatory stack:
`--ns_iter 6 --soap_attn --lr_mlp 0.055 --lr_attn 0.035 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine`

The new flags added by this PR: `--mu_mlp` and `--mu_attn`.
Control baseline must confirm `mu_mlp=0.95 mu_attn=0.95` matches FFS ~2943.75.

| Cell | --mu_mlp | --mu_attn | Role |
|------|----------|-----------|------|
| A | 0.95 | 0.95 | Control — reproduces baseline, gate-check |
| B | 0.95 | 0.85 | Primary — attn momentum reduced, MLP held |
| C | 0.95 | 0.90 | Intermediate — half-step reduction |
| D | 0.90 | 0.85 | Both reduced — tests whether MLP also benefits |
| E | 0.85 | 0.95 | Falsifier — opposite direction: MLP reduced only |

**Reading order:**
- If B is FFS-alive (≤2975): run to n=4 for B; run C, D, E for mechanism read.
- If B is FFS-dead (>2975) and E is FFS-alive: momentum decoupling effect is real but direction is inverted — update research map, MLP momentum may be the lever.
- If B, C, D, E all FFS-neutral (within σ=12.5 of 2943.75): momentum decoupling is FFS-cosmetic at this granularity; close axis.
- If D beats B: both groups benefit from lower mu, consider extending to a global mu sweep (e.g., mu=0.90 across both).

**Predeclared merge gate:** μ_4(FFS) ≤ 2918.75 (= μ_4_baseline − 2σ_4 = 2943.75 − 25.0). σ_4 budget: ≤ 12.5. Both conditions required simultaneously.

---

## Implementation Notes

### New argparse flags

Add these two lines immediately after the existing `--wd_attn` argument (around line 58 in the current file):

```python
parser.add_argument("--mu_mlp", type=float, default=0.95,
                    help="Muon momentum for MLP body weights (.mlp.fc.weight / .mlp.proj.weight)")
parser.add_argument("--mu_attn", type=float, default=0.95,
                    help="Muon momentum for attention body weights (.attn.q/k/v/proj.weight)")
```

### Optimizer construction patch

File: `records/track_3_optimization/train_gpt_simple.py`, around line 865.

Current code:
```python
optimizer2 = Muon(
    [
        dict(named_params=mlp_named,  lr=args.lr_mlp,  weight_decay=args.wd_mlp,  name="muon_mlp"),
        dict(named_params=attn_named, lr=args.lr_attn, weight_decay=args.wd_attn, name="muon_attn"),
    ],
    soap_attn=args.soap_attn, trust_threshold=args.soap_trust_threshold,
)
```

Patched code:
```python
optimizer2 = Muon(
    [
        dict(named_params=mlp_named,  lr=args.lr_mlp,  weight_decay=args.wd_mlp,  mu=args.mu_mlp,  name="muon_mlp"),
        dict(named_params=attn_named, lr=args.lr_attn, weight_decay=args.wd_attn, mu=args.mu_attn, name="muon_attn"),
    ],
    soap_attn=args.soap_attn, trust_threshold=args.soap_trust_threshold,
)
```

That is the complete change. The `Muon.__init__` already reads `g.get("mu", mu)` when building param groups (line ~619), so the per-group `mu` key is natively supported and will propagate correctly to `group["mu"]` inside `step()` (lines 651-652, 666). No changes to the Muon class itself are required.

### Verification

After patching, confirm `optimizer2.param_groups[0]["mu"]` == `args.mu_mlp` and `optimizer2.param_groups[1]["mu"]` == `args.mu_attn` with a quick print before training starts.

### Known gotcha

The `Muon` constructor's `defaults` dict is set with the top-level `mu` kwarg (default 0.95), but per-group `mu` overrides it at group construction time. Because `args.mu_mlp` and `args.mu_attn` default to 0.95, Cell A (control) will be bit-for-bit identical to the unpatched baseline — no seed drift.

---

## Reproduce Commands

All cells share the same R5 base command. Replace `<CELL_X_FLAGS>` with the per-cell values below.

```bash
# R5 base
BASE="--ns_iter 6 --soap_attn --lr_mlp 0.055 --lr_attn 0.035 \
      --wd_schedule ramp_down --lr_scalars 0.03 \
      --depth_init_mode musoft --lr_cooldown_shape cosine"

# Cell A — control
python train_gpt_simple.py $BASE --mu_mlp 0.95 --mu_attn 0.95 \
  --wandb_group mu-mlp-attn-decouple --wandb_name cell-A-ctrl

# Cell B — primary (attn reduced)
python train_gpt_simple.py $BASE --mu_mlp 0.95 --mu_attn 0.85 \
  --wandb_group mu-mlp-attn-decouple --wandb_name cell-B-mu_attn0p85

# Cell C — intermediate
python train_gpt_simple.py $BASE --mu_mlp 0.95 --mu_attn 0.90 \
  --wandb_group mu-mlp-attn-decouple --wandb_name cell-C-mu_attn0p90

# Cell D — both reduced
python train_gpt_simple.py $BASE --mu_mlp 0.90 --mu_attn 0.85 \
  --wandb_group mu-mlp-attn-decouple --wandb_name cell-D-mu_mlp0p90_attn0p85

# Cell E — falsifier (MLP reduced only)
python train_gpt_simple.py $BASE --mu_mlp 0.85 --mu_attn 0.95 \
  --wandb_group mu-mlp-attn-decouple --wandb_name cell-E-falsifier-mu_mlp0p85
```

---

## Predeclared FFS Gates (directive #1262)

**FFS-alive threshold (n=1 screen):** Cell B FFS ≤ 2975
- If Cell B FFS > 2975: axis is FFS-dead at this value. Inspect C and E before closing.
- If Cell B FFS ≤ 2975: proceed to n=4 confirm for Cell B.

**n=4 merge gate:** μ_4(FFS) ≤ 2918.75 AND σ_4(FFS) ≤ 12.5
- Current baseline: μ_4 = 2943.75, σ_4 = 12.5
- Required improvement: ≥ 25 FFS steps (2σ below baseline mean)

**Mechanism read (secondary):**
- Report val/loss for best-FFS checkpoint alongside FFS for each cell.
- Log `train/lr/muon_mlp`, `train/lr/muon_attn` to confirm per-group LR is still tracked correctly post-patch.

**Stop condition:** If A=B=C=D=E all within ±12.5 FFS of 2943.75 (i.e., all within 1σ of baseline), close axis as FFS-cosmetic. Do not extend to finer mu grid without new mechanistic evidence.
