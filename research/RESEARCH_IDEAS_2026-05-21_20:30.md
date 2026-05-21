# Research Ideas — 2026-05-21 20:30

## Hypothesis: MUON_COOLDOWN_SHAPE — Per-group cosine decay for Muon LR only

### One-sentence summary

Apply cosine (or sqrt-concave) cooldown decay to the Muon LR group while leaving AdamW groups on the current linear schedule, exploiting the geometric difference between orthogonalized updates (Muon) and per-element adaptive updates (AdamW).

---

### Mechanism

The current `set_hparams` function computes a single scalar `eta` from the linear formula `(1 - progress) / cooldown_frac` and applies it to **all** parameter groups uniformly (line 936). This is correct for AdamW groups (embed, lm_head, scalars) which use per-element second-moment preconditioning that implicitly handles curvature. It is not obviously correct for Muon.

Muon applies NS5 orthogonalization before the update step: the effective update direction is the closest orthogonal matrix to the raw gradient. This means the update magnitude is more tightly bounded (by the singular value structure of W), but the directional signal is preserved more aggressively than Adam. Because the geometry is different, the optimal cooldown shape may also differ:

- **Linear decay** (current): LR drops at constant rate. At the midpoint of cooldown (t=0.5), LR is at 50% of peak.
- **Cosine decay**: Stays higher in the early cooldown phase (t=0.25 → LR 85% of peak) and falls faster near the end. This allows more "exploration" in the critical steps just after cooldown begins, then a harder landing.
- **Concave sqrt decay**: `eta = sqrt(1 - t)`. Opposite profile: drops faster early, flatter near end. Mechanistically distinct — preserves more momentum near the terminal steps.

The targeted failure mode is "Muon gets a too-aggressive early-cooldown cut, causing the orthogonalized gradient to under-update in the window where inter-layer representation consolidation matters most." If true, cosine Muon should show a lower ffs by ~25–75 steps.

---

### Anti-duplication check

| PR | What it tested | Outcome | Why it doesn't cover this |
|---|---|---|---|
| #238 | **Global** cosine cooldown (ALL groups) | Catastrophic MISS, never hit 3.28 | ALL-groups cosine known dead; per-group shape untested |
| #276 | **AdamW cosine, Muon linear** (inverse direction) | WIP / partial MISS | REVERSE of target direction; Muon was kept linear |
| #464 | All-groups polynomial power=0.5/2.0 | Both killed early | All-groups power dead; per-group untested |
| #485 | All-groups sqrt (power=0.5) | Kill at step T0, val=3.46616 | All-groups sqrt dead; per-group untested |
| #549 | `MUON_COOLDOWN_FRAC` — different start timing | ffs=3075 MISS | Changed FRACTION, not SHAPE of decay curve |
| #615 | Muon LR floor `eta_min` | ffs=3025 floor, no improvement | Changed floor level, not curve shape |
| #657 | Global `SCHEDULE_SHAPE` ∈ {cosine, quadratic} | Catastrophic / not reached | All-groups shape; per-group shape not covered |
| #678 | Per-group `cooldown_frac` (Muon vs AdamW different FRACTION) | ffs=3075 MISS | Changed per-group START TIMING, not decay SHAPE |

**In-flight PRs** (#703, #713, #715, #718, #705, #701, #702): None test per-group cooldown shape.

**Conclusion**: "Muon-only cosine cooldown shape while AdamW stays linear" is a fresh axis.

---

### Exact code diff

File: `records/track_3_optimization/train_gpt_simple.py`

**Add env-var read near line 440–470 (after other HP reads):**

```python
# NEW — line ~457 (after NS5_ITERS read)
MUON_COOLDOWN_SHAPE = os.environ.get("MUON_COOLDOWN_SHAPE", "linear")  # "linear", "cosine", "sqrt"
```

**Modify `set_hparams` function (lines 916–938):**

```python
    def set_hparams(step, cooldown_frac=0.7):
        import math
        progress = step / train_steps
        assert 0 <= progress < 1
        if progress < 1 - cooldown_frac:
            eta = 1.0
            eta_muon = 1.0
        else:
            t = (progress - (1 - cooldown_frac)) / cooldown_frac  # 0→1 over cooldown
            eta = (1 - progress) / cooldown_frac                   # linear (unchanged for AdamW)
            if MUON_COOLDOWN_SHAPE == "cosine":
                eta_muon = 0.5 * (1.0 + math.cos(math.pi * t))
            elif MUON_COOLDOWN_SHAPE == "sqrt":
                eta_muon = math.sqrt(max(1.0 - t, 0.0))
            else:
                eta_muon = eta  # default: same linear as AdamW
        if MU_COOLDOWN_ENABLED:
            if step < MU_WARMUP_STEPS:
                w = step / MU_WARMUP_STEPS
                cur_mu = MU_WARMUP_START + (MU_COOLDOWN_START - MU_WARMUP_START) * w
            elif progress < 1 - cooldown_frac:
                cur_mu = MU_COOLDOWN_START
            else:
                t_mu = (progress - (1 - cooldown_frac)) / cooldown_frac
                cur_mu = MU_COOLDOWN_START + (MU_COOLDOWN_END - MU_COOLDOWN_START) * t_mu
        else:
            cur_mu = MU + (MU_END - MU) * progress
        for opt in optimizers:
            for group in opt.param_groups:
                if group.get("name") == "muon_blocks":
                    group["lr"] = group["initial_lr"] * eta_muon
                    group["mu"] = cur_mu
                else:
                    group["lr"] = group["initial_lr"] * eta
```

Total delta: ~12 lines changed. No new parameters beyond the single env-var.

**Note**: `t` is reused for `eta_muon` and `t_mu` in the original code. Rename the old `t` in the `MU_COOLDOWN_ENABLED` block to `t_mu` to avoid shadowing (shown above).

---

### Two arms

**Arm A — Cosine Muon** (`MUON_COOLDOWN_SHAPE=cosine`):
- At t=0.25 into cooldown: eta_muon = 0.854 vs eta_linear = 0.750 (+14% higher)
- At t=0.50: eta_muon = 0.500 vs eta_linear = 0.500 (equal at midpoint)
- At t=0.75: eta_muon = 0.146 vs eta_linear = 0.250 (-42% lower near end)
- Mechanism: more aggressive Muon steps in the early cooldown window; harder landing at end.

**Arm B — Sqrt Muon** (`MUON_COOLDOWN_SHAPE=sqrt`):
- At t=0.25: eta_muon = 0.866 vs eta_linear = 0.750 (+15% higher early)
- At t=0.50: eta_muon = 0.707 vs eta_linear = 0.500 (+41% higher mid)
- At t=0.75: eta_muon = 0.500 vs eta_linear = 0.250 (+100% higher late)
- Mechanism: concave profile keeps Muon LR higher throughout cooldown; tests whether Muon benefits from sustained large steps right to the end.

These arms are mechanistically opposite at t=0.75: cosine collapses fast, sqrt remains high. If Arm A wins, it suggests the early-cooldown window is critical. If Arm B wins, it suggests Muon needs sustained magnitude near convergence.

---

### Decision tree

```
Arm A (cosine) AND Arm B (sqrt) both run
│
├── Arm A (cosine) beats ffs=3025 AND Arm B does not
│   → Cosine shape is the winner; merge Arm A
│   → Follow-up: try Arm A + cosine mu cooldown (currently mu cooldown is linear)
│
├── Arm B (sqrt) beats ffs=3025 AND Arm A does not
│   → Muon needs sustained LR near convergence; merge Arm B
│   → Follow-up: try MUON_COOLDOWN_SHAPE=sqrt with eta_min floor 0.1 to avoid zero-crossing
│
├── BOTH beat ffs=3025
│   → Merge the better one; test the second as a separate PR
│   → Strong evidence the per-group shape axis is live; try quadratic as Arm C
│
├── NEITHER beats ffs=3025
│   → Per-group shape is also dead (joins #238/#276/#657 in ruled-out)
│   → This axis is fully closed: linear shape is optimal for both groups
│   → Move to a different level: per-layer Muon LR (depth-differentiated like #713's NS5 iters)
│
└── One arm MISS by small margin (≤30 steps from 3025)
    → Investigate LR curve midpoint by trying MUON_COOLDOWN_SHAPE=cosine with
      cooldown_frac=0.8 (start cooldown earlier, same cosine shape)
```

---

### Expected observables

- If mechanism is alive: ffs should move by 25–100 steps (1–3% of 3100). Smaller moves are noise.
- Check val_loss trajectory at step ~955 (cooldown start) for divergence between arms.
- If both arms are significantly worse (>3050), per-group shape interacts adversely with CONTRA_MUON correction — likely because Contra uses a momentum-normalized subtraction that implicitly assumes the LR scale.

---

### Stop condition

Close this axis if both arms return ffs ≥ 3025. Do not retry with intermediate shape variants — the #238/#276/#657 global shape results plus this per-group test would constitute full coverage of the schedule-shape space.

---

### Kill gates (derive from baseline trajectory)

The current baseline reaches val_loss ≈ 3.330 at step ~600 (start of the stable phase). Use this trajectory for early kill gates:
- Step 300: val_loss > 3.42 → kill
- Step 600: val_loss > 3.38 → kill
- Step 1200: val_loss > 3.34 → kill

These gates are loose enough to catch shape differences that only manifest in mid-training without killing experiments prematurely.

---

### Taste rubric

| Criterion | Score | Rationale |
|---|---|---|
| Mechanistic grounding | 3 | Targets the geometric mismatch between NS5-constrained and per-element updates; PR #238/#276 provide directional evidence that global shape is bad but per-group is uncharted |
| Research-state value | 3 | Two arms with opposite profiles at t=0.75 sharply separate "early cooldown matters" vs "late cooldown matters" for Muon; any outcome updates the map |
| Execution value | 4 | ~12-line change, single env-var, n=2 arms fit in one student assignment, directly targets ffs metric |

**Mode**: Frontier refinement (exploiting a specific untested variant within a well-scoped HP axis).

**Confidence**: Moderate. There is strong prior that global shape is harmful, which makes per-group shape a logical next test but also raises the prior that shape doesn't matter much for Muon either. The cosine vs linear divergence at t=0.75 is a real geometric difference in the update schedule and worth one test.
