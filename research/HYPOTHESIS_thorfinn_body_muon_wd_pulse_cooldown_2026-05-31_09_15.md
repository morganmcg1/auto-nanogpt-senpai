# Body PMuon weight_decay PULSE @ cooldown onset step 975 — BILATERAL RELAX vs DEEPEN (PERSISTENT)

## Hypothesis

**The cooldown phase boundary at step 975 is the load-bearing axis for state-at-phase-boundary mechanisms on this branch. The canonical β₂ pulse mechanism (PR #1532 baseline WIN) lives exactly here. Pre-target body PMuon weight_decay pulse @ step 2750 is closed bilateral NULL (#1693). The cooldown-onset analog — a PERSISTENT body PMuon weight_decay step change at step 975 mirroring the baseline β₂ pulse mechanism — is UNTESTED.**

Mechanism: Body PMuon's `weight_decay=0.025` (canonical) applies decoupled L2 regularization at each step: `p ← p × (1 − lr × wd)`. At cooldown onset, body PMuon LR follows cosine decay from 0.040; the wd-driven pull-toward-zero becomes a non-trivial fraction of the per-step parameter change *only* in the late-cooldown / pre-target window. A persistent step change at 975 reshapes the entire descent through cooldown:

- **Arm A RELAX (wd 0.025 → 0.0)**: removes decoupled L2 across the entire cooldown phase → body PMuon params freely exploit the win-direction signal without regularization drag in the load-bearing window. If wd is a brake on cooldown descent, this lifts it.
- **Arm B DEEPEN (wd 0.025 → 0.05, 2× canonical)**: doubles the regularization pull throughout cooldown → forces params toward smaller-norm solutions, potentially capturing better-conditioned end states with a different loss-landscape navigation.

Persistent (not windowed) — directly mirrors the baseline β₂ pulse mechanism (PR #1532): step change at 975, no revert. This is the cooldown-onset analog of the WIN-bearing pulse.

## Why this is the natural cooldown-onset analog of #1693

| PR | Optimizer | Axis | Boundary | Scope | Status |
|---|---|---|---|---|---|
| #1693 fern | body PMuon | weight_decay | pre-target 2750-2900 | windowed pulse | bilateral NULL |
| #1532 baseline | aux Adam | β₂ | cooldown onset 975 | persistent step | **WIN** |
| **#THIS thorfinn** | **body PMuon** | **weight_decay** | **cooldown onset 975** | **persistent step** | **← UNTESTED** |

The body PMuon wd axis is closed at the PRE-TARGET boundary but UNTESTED at the COOLDOWN-ONSET boundary. The persistent (cooldown-onset, baseline-mirroring) variant is a distinct cell on the (boundary, scope) grid that has never been probed.

## Alignment with directive #1252

- (a) **Optimizer-state at phase boundaries** ✓ — step 975 is the canonical cooldown-onset boundary, exactly where baseline WIN (#1532) lives
- (d) **Momentum/preconditioner state handling** ✓ — wd pulls every step on parameters that have been preconditioned by L^{-γ}·g·R^{-γ}; changing wd reshapes the effective preconditioner-update interaction
- (e) **Schedules that steepen loss descent before step 2925** ✓ — persistent change reshapes the entire cooldown + pre-target trajectory toward target

## Two arms (bilateral direction test)

| Arm | wd_pulse | wd value @ step 975 | Direction | Hypothesis |
|---|---|---|---|---|
| **A (RELAX)** | yes | **0.0** | Remove decoupled L2 across cooldown | If WIN → wd brake suppresses cooldown descent at the moment LR + β₂ pulse arrive. STACKS with baseline β₂ pulse. |
| **B (DEEPEN)** | yes | **0.05** (2×) | Double decoupled L2 across cooldown | If WIN → stronger param-norm pull captures better-conditioned end-of-cooldown solutions. |

**If both WIN**: body PMuon wd is highly active during cooldown; direction depends on which solution-norm regime is preferred — pick winner for n=2 confirmation.
**If both NULL**: body PMuon wd is robustly invariant within ±100% across cooldown; axis CLOSED across both boundaries (975 + 2750 via #1693).
**If one WIN**: optimal direction is settled; follow up to sweep magnitude on the winning side (e.g., wd→0.0125 / wd→0.0 / wd→ −0.005 if relax wins).

## Implementation

Body PMuon canonical `weight_decay=0.025` (per #1693). Apply persistent step change at `step == args.body_muon_wd_pulse_step` by writing into `optimizer2.param_groups[0]["weight_decay"]` (mirror of baseline β₂ pulse on optimizer1).

Add two new flags:

```python
parser.add_argument('--body_muon_wd_pulse_step', type=int, default=-1,
                    help='Step at which to persistently change body PMuon weight_decay. -1 disables.')
parser.add_argument('--body_muon_wd_pulse_target', type=float, default=-1.0,
                    help='New body PMuon wd value from the pulse step onward (no revert). Use 0.0 for RELAX, 0.05 for DEEPEN.')
```

Pulse logic (place after the existing aux β₂ pulse hook, ~line 1065 of `train_gpt_simple.py`):

```python
if (args.body_muon_wd_pulse_step > 0
        and args.body_muon_wd_pulse_target >= 0.0):
    if step == args.body_muon_wd_pulse_step:
        old_wd = optimizer2.param_groups[0]["weight_decay"]
        for g in optimizer2.param_groups:
            g["weight_decay"] = args.body_muon_wd_pulse_target
        print0(f"[step {step}] body_muon_wd_pulse: wd {old_wd} -> {args.body_muon_wd_pulse_target}",
               console=True)
```

Note: cooldown onset is step 975 (matches baseline β₂ pulse step). This is a PERSISTENT change (no revert step) — mirrors baseline β₂ pulse semantics.

## Reproduce commands

Use `target/records/track_3_optimization/`. Both arms use `--wandb_group thorfinn-body-muon-wd-pulse-cooldown` so the pair is grouped in W&B.

**Arm A (RELAX, wd 0.025 → 0.0 @ step 975):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --body_muon_wd_pulse_step 975 \
  --body_muon_wd_pulse_target 0.0 \
  --wandb_group thorfinn-body-muon-wd-pulse-cooldown \
  --wandb_name thorfinn-wd-pulse-cooldown-relax \
  --seed 1
```

**Arm B (DEEPEN, wd 0.025 → 0.05 @ step 975):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --body_muon_wd_pulse_step 975 \
  --body_muon_wd_pulse_target 0.05 \
  --wandb_group thorfinn-body-muon-wd-pulse-cooldown \
  --wandb_name thorfinn-wd-pulse-cooldown-deepen \
  --seed 1
```

## Merge gate (target/program.md)

Current baseline (PR #1532): `sr=2875, val_ema=3.262854 (n=2)`.

Merge if either arm satisfies: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`.

If clause-2 thin-margin pass (val_ema improvement <0.5 mnat, sr matches), run n=2 confirmation (seed-2) before declaring WIN.

## Suggested follow-ups (write into PR `Suggested follow-ups:` section)

- If RELAX wins: sweep wd target ∈ {−0.005 (slight push-out), 0.0, 0.0125 (half)} — full magnitude grid
- If DEEPEN wins: sweep wd target ∈ {0.0375, 0.05, 0.075} — full magnitude grid
- If bilateral NULL: body PMuon wd axis CLOSED across both cooldown onset and pre-target (#1693)
- If asymmetric WIN: test block-stratified (deep vs shallow only) variant of the WIN side
