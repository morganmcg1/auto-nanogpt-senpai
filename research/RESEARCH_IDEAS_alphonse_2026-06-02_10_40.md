# Research Ideas for Alphonse — 2026-06-02 10:40

**Context:** Plateau protocol engaged. 5+ consecutive bilateral NULL closures. alphonse's current PR #2219 (NS polynomial coeff phase-switch @2600) is finishing (~10:50Z, step 2700). This batch targets pristine, phase-specific axes that match directive #1252.

**Current baseline:** sr=2875, val_ema=3.262854 (PR #1532). Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`.

**Baseline reproduce command stack (must be included in all experiments):**
```
--muon_lr 0.040 --muon_block_lr_pattern late-higher \
--ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
--paramema_refresh_only --paramema_refresh_step 2600 \
--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99
```

---

## Idea 1 (TOP RECOMMENDATION): PMuon Bilateral Whitening Exponent Phase Schedule

### Mechanism

`PMUON_GAMMA = 0.4` is a global constant controlling the bilateral whitening exponent in `pmuon_update`: `update = (L^{-γ} @ nesterov_momentum @ R^{-γ})`, where `L_neg = L_cov_neg_power` computed via `matrix_neg_power(..., gamma)`. This exponent is fixed for the entire 3250-step run — pre-cooldown and cooldown use identical whitening strength.

The hypothesis: the optimal whitening exponent differs between the loss-descent phase (steps 0–975) and the cooldown/convergence phase (steps 975–3250). During the descent phase, moderate whitening (γ=0.4) appropriately balances the contribution of small-variance and large-variance gradient directions. But in the cooldown phase, the learning rate is decaying rapidly and the model is refining rather than exploring. In this regime, stronger whitening (γ→0.5 or 0.6) amplifies the low-variance gradient directions more aggressively — precisely those directions that are systematically undersampled and most informative for final convergence. Alternatively, weaker whitening (γ→0.3) may be better if the covariance structure has shifted significantly and the prior EMA-based factorization is stale.

The switch follows the same phase-boundary pattern as the winning `aux_b2_pulse` (@step 975, coinciding with cooldown start). Implementation: add `--pmuon_cooldown_gamma` and `--pmuon_gamma_switch_step` flags. At the switch step, update `group["gamma"]` in all `optimizer2.param_groups`. The `matrix_neg_power` call reads `gamma` from the param group at each step, so the switch takes effect immediately. Note: `pmuon_spectral_diag` uses the hardcoded `PMUON_GAMMA` constant for telemetry only (not for the actual update), so no correctness issue arises — the live update uses `group["gamma"]`.

This is directive #1252(c) phase-specific mechanism + (d) preconditioner state handling. PR #444 in the experiment log never ran.

### Why it might break the plateau

The whitening exponent controls how aggressively the optimizer corrects for spectral imbalance. Every other phase-boundary switch that won (aux_b2_pulse, paramEMA refresh, block-LR late-higher) exploited a different effective geometry for the descent vs. convergence phases. The γ exponent has never been scheduled. The covariance matrices L_cov and R_cov are built up over the entire run and represent accumulated gradient statistics; as the run transitions to cooldown and the gradient distribution changes, using the same exponent means applying a preconditioner calibrated for a different phase. This is a structural mismatch that should be addressable.

The bilateral test (γ→0.3 tighter vs. γ→0.5 looser) separates the two competing hypotheses cleanly: if the cooldown needs amplified low-variance directions, Arm B (γ=0.5) should win; if the covariance is stale and over-fitted to earlier statistics, Arm A (γ=0.3) should win. Either result updates the research map sharply.

### Prior art check

- PR #444 in the experiment log: "PMuon γ_power phase schedule" — **confirmed never ran** (results_table_2026-06-02_10-40.md, never-ran section).
- All prior γ experiments used a fixed global γ value (γ=0.3 Frobenius ceiling, frieren #2226 — in-flight). This is structurally distinct: a fixed alternate value vs. a phase-schedule switch.
- NS_ITERS phase schedules (edward #2239, in-flight) target a different component of the pmuon pipeline (polar projection iterations, not whitening exponent).

### Implementation sketch

Add two CLI args:

```python
parser.add_argument("--pmuon_cooldown_gamma", type=float, default=0.0)
parser.add_argument("--pmuon_gamma_switch_step", type=int, default=0)
```

In the training loop (alongside the aux_b2_pulse block, ~line 1073):

```python
if (args.pmuon_gamma_switch_step > 0
        and args.pmuon_cooldown_gamma > 0.0
        and step == args.pmuon_gamma_switch_step):
    old_gamma = optimizer2.param_groups[0]["gamma"]
    for group in optimizer2.param_groups:
        group["gamma"] = args.pmuon_cooldown_gamma
    print0(
        f"[step {step}] pmuon_gamma_switch: γ {old_gamma:.3f} → {args.pmuon_cooldown_gamma:.3f}",
        console=True,
    )
```

Delta: ~12 LOC + 2 CLI args. No changes to `pmuon_update` itself. The `group["gamma"]` field is already read live by `pmuon_update` at every call.

### Bilateral arm design

- **Arm A** (`--pmuon_cooldown_gamma 0.3 --pmuon_gamma_switch_step 975`): Tighter whitening in cooldown. γ 0.4→0.3. Tests the hypothesis that the late-phase covariance structure is stale and reduced whitening is safer.
- **Arm B** (`--pmuon_cooldown_gamma 0.5 --pmuon_gamma_switch_step 975`): Looser whitening (more aggressive spectral amplification) in cooldown. γ 0.4→0.5. Tests the hypothesis that the convergence phase needs harder spectral correction in the under-represented directions.

Switch at step 975 aligns with cooldown start and the existing aux_b2_pulse boundary — this is the established phase-boundary in this stack.

### Reproduce commands

```bash
# Arm A — γ 0.4→0.3 at cooldown start
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --muon_block_lr_pattern late-higher \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --pmuon_cooldown_gamma 0.3 --pmuon_gamma_switch_step 975 \
  --wandb_name "alphonse/pmuon-gamma-phase-arm-a" --wandb_group "pr-pmuon-gamma-phase"

# Arm B — γ 0.4→0.5 at cooldown start
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --muon_block_lr_pattern late-higher \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --pmuon_cooldown_gamma 0.5 --pmuon_gamma_switch_step 975 \
  --wandb_name "alphonse/pmuon-gamma-phase-arm-b" --wandb_group "pr-pmuon-gamma-phase"
```

### Falsifying result

If both arms land at sr=2925 with val_ema > 3.263, the γ phase schedule at the cooldown boundary is inert and this axis is closed. If one arm moves, the winning direction informs whether a sharper (γ=0.25) or more gradual (γ=0.55) value should be explored in the next round.

---

## Idea 2: Post-Polar Aspect-Ratio Exponent Ablation

### Mechanism

After Newton-Schulz polar projection, `pmuon_update` applies aspect-ratio scaling:

```python
update = polar * (max(1, grad.size(-2) / grad.size(-1)) ** 0.5)
```

The exponent `0.5` is hardcoded and applies a square-root correction to tall matrices (more rows than columns) to account for the operator norm difference between the gradient and polar-projected form. This scaling was introduced as a heuristic to maintain consistent effective learning rates across layers with different aspect ratios (e.g., 768×3072 MLP vs. 768×768 attention). The value `0.5` has never been ablated — it could be optimal, suboptimal, or irrelevant depending on the effective loss landscape geometry for this architecture.

Test whether the exponent 0.5 is correct by contrasting against 0.0 (remove scaling entirely) and 1.0 (full linear correction). This is directive #1252(b) per-layer optimizer behavior — different layers have different aspect ratios and the scaling differentially affects them.

PR #1129 in the experiment log: "Post-polar aspect-ratio exponent ablation" — confirmed never ran.

### Implementation sketch

In `pmuon_update` (~line where `update = polar * ...` appears):

```python
# Replace:
update = polar * (max(1, grad.size(-2) / grad.size(-1)) ** 0.5)

# With:
update = polar * (max(1, grad.size(-2) / grad.size(-1)) ** group.get("aspect_exp", 0.5))
```

Add CLI arg `--pmuon_aspect_exp` (default 0.5 = current behavior, no-change baseline) and pass to optimizer2 param groups as `aspect_exp=args.pmuon_aspect_exp`.

Delta: ~8 LOC + 1 CLI arg.

### Bilateral arm design

- **Arm A** (`--pmuon_aspect_exp 0.0`): Removes aspect-ratio scaling entirely. All layers get equal post-polar update magnitude regardless of shape. Tests whether the scaling is harmful.
- **Arm B** (`--pmuon_aspect_exp 1.0`): Full linear correction. Tall layers get larger updates proportional to their aspect ratio. Tests whether stronger correction is better.

### Reproduce commands

```bash
# Arm A — no aspect-ratio scaling
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --muon_block_lr_pattern late-higher \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --pmuon_aspect_exp 0.0 \
  --wandb_name "alphonse/pmuon-aspect-arm-a" --wandb_group "pr-pmuon-aspect-exp"

# Arm B — full linear aspect-ratio scaling
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --muon_block_lr_pattern late-higher \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --pmuon_aspect_exp 1.0 \
  --wandb_name "alphonse/pmuon-aspect-arm-b" --wandb_group "pr-pmuon-aspect-exp"
```

### Falsifying result

Both arms significantly worse than baseline → the 0.5 exponent is well-calibrated. One arm matching baseline → scaling is inert. If Arm A (0.0) is slightly better, aspect-ratio scaling is actively hurting. If Arm B (1.0) is better, the current correction is under-scaled.

---

## Idea 3: PMuon Gamma Role-Split (Attention vs. MLP Blocks)

### Mechanism

The current `PMUON_GAMMA = 0.4` applies uniform bilateral whitening to all matrix parameters in `optimizer2`: attention Q/K/V/proj and MLP fc1/fc2. These parameter classes have structurally different spectral profiles. Attention weight matrices operate in a lower-effective-rank subspace (attention heads constrain the gradient structure) while MLP matrices span a denser spectral distribution. Applying the same whitening exponent to both may be suboptimal — the correction that stabilizes attention learning may over-whiten MLP gradients or vice versa.

This is directive #1252(b) per-layer/per-block optimizer behavior. Concretely: split `optimizer2` into two param groups (attention weights vs. MLP weights), each with its own `gamma`. The bilateral test swaps which role gets the tighter (0.3) vs. looser (0.5) whitening.

### Implementation sketch

In the optimizer construction block, instead of one Muon group:

```python
# Split by parameter name: attention = ["attn.qkv", "attn.proj"], mlp = ["mlp.fc1", "mlp.fc2"]
attn_params = [p for name, p in model.named_parameters() if "attn" in name and p.ndim >= 2]
mlp_params  = [p for name, p in model.named_parameters() if "mlp"  in name and p.ndim >= 2]

optimizer2 = Muon(
    [{"params": attn_params, "lr": args.muon_lr, "gamma": args.pmuon_attn_gamma},
     {"params": mlp_params,  "lr": args.muon_lr, "gamma": args.pmuon_mlp_gamma}],
    ...
)
```

Add `--pmuon_attn_gamma` and `--pmuon_mlp_gamma` CLI args (defaults 0.4 each = current behavior).

Delta: ~20 LOC + 2 CLI args. More invasive than Idea 1 (requires param-name inspection at optimizer construction time).

### Bilateral arm design

- **Arm A** (`--pmuon_attn_gamma 0.3 --pmuon_mlp_gamma 0.5`): Tighter whitening for attention, looser for MLP. Theory: attention's lower effective rank benefits from stronger low-variance amplification.
- **Arm B** (`--pmuon_attn_gamma 0.5 --pmuon_mlp_gamma 0.3`): Inverted. Tests the alternative.

### Reproduce commands

```bash
# Arm A — tighter attention whitening
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --muon_block_lr_pattern late-higher \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --pmuon_attn_gamma 0.3 --pmuon_mlp_gamma 0.5 \
  --wandb_name "alphonse/pmuon-role-gamma-arm-a" --wandb_group "pr-pmuon-role-gamma"

# Arm B — inverted role gamma
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --muon_block_lr_pattern late-higher \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --pmuon_attn_gamma 0.5 --pmuon_mlp_gamma 0.3 \
  --wandb_name "alphonse/pmuon-role-gamma-arm-b" --wandb_group "pr-pmuon-role-gamma"
```

### Falsifying result

Both arms NULL → attention and MLP do not benefit from differentiated whitening. Note this is mechanistically overlapping with frieren's in-flight PR #2226 (γ=0.3 Frobenius ceiling, uniform) — if #2226 returns NULL, this role-split hypothesis loses prior support. If #2226 returns a win, it becomes the strongest case for testing role-split differentiation. Recommend treating Idea 3 as contingent on #2226 outcome.

---

## Priority Ranking

| Rank | Idea | Directive | LOC | Risk | Novelty | Recommended? |
|------|------|-----------|-----|------|---------|--------------|
| 1 | PMuon γ phase schedule (@975) | #1252(c)+(d) | ~12 | Low | Confirmed pristine (PR #444 never ran) | **YES — assign now** |
| 2 | Post-polar aspect-ratio exponent | #1252(b) | ~8 | Low | Confirmed pristine (PR #1129 never ran) | YES — if #1 closes quickly |
| 3 | PMuon γ role-split (attn vs MLP) | #1252(b) | ~20 | Medium | Novel but contingent on frieren #2226 | Conditional — wait for #2226 result |

---

## Taste Rubric

| Idea | Research mode | Mechanistic grounding | Research-state value | Execution value | Score |
|------|--------------|----------------------|---------------------|-----------------|-------|
| 1: γ phase schedule | Frontier refinement | 4 — Precise mechanism (γ controls whitening strength; phase boundary at step 975 already proven as leverage point; `group["gamma"]` confirmed live-readable); bilateral test separates tighter vs. looser cooldown whitening | 4 — Either direction sharpens the map; NULL closes the phase-γ axis entirely; win cascades to finer γ search | 4 — ~12 LOC, follows known template, no architectural risk, runs at full 3250 steps | **4/4/4** |
| 2: Aspect-ratio exp | Diagnostic | 3 — 0.5 exponent is heuristic with no ablation history; mechanism is well-scoped (post-polar scaling) | 3 — NULL confirms 0.5 is well-calibrated; win opens a new tuning axis | 3 — ~8 LOC, cheap, runs at full steps | **3/3/3** |
| 3: γ role-split | Tier shift | 2 — Mechanism plausible but no direct evidence that attn/MLP whitening requirements differ; contingent on #2226 | 2 — Harder to interpret if one direction wins; depends on #2226 framing | 2 — ~20 LOC, more complex, overlaps with in-flight #2226 | **2/2/2** |

---

## Research State Update

**Current best explanation for plateau:** The PMuon whitening exponent (γ) has never been treated as a schedule parameter. All phase-boundary wins (aux_b2_pulse, paramEMA refresh, block-LR late-higher) exploited the geometry change at step 975. The γ axis has zero coverage at this boundary. The most direct untested mechanism is: apply the phase-boundary lever to the whitening exponent itself.

**Evidence:** PR #444 in the experiment log is confirmed never-ran. `group["gamma"]` is confirmed live-readable. `aux_b2_pulse` template at lines 1065-1073 provides the exact implementation pattern. Cooldown start at step 975 aligns with existing phase boundary.

**Ruled-out paths:** paramEMA family (all), Body PMuon momentum state (all), aux Adam state perturbations (β₁ all, β₂ only @975 optimal), Block-LR magnitude/shape, NS_ITERS schedules. Do not revisit without new evidence.

**Open uncertainties:**
1. Whether the direction of γ change at cooldown matters more than the magnitude: 0.4→0.3 vs 0.4→0.5 vs 0.4→0.6 may have a non-monotone response.
2. Whether aspect-ratio scaling is actually hurting or merely neutral — if Arm A (exp=0.0) matches baseline, the per-layer effective LR consistency argument breaks down.
3. Whether frieren #2226 (γ=0.3 fixed, whole run) will show a benefit that would motivate γ role-split.

**Next discriminating experiment:** Idea 1 (γ phase schedule). Run both arms to 3250 steps. If either arm reaches sr≤2875 with val_ema < 3.262854, merge and escalate to a finer grid (0.4→0.25 or 0.4→0.6). If both are NULL, the γ-switch-at-cooldown-boundary axis is closed and the phase-scheduling lever is exhausted for this component.

**Stop condition for γ axis:** All four tested γ pairs (including frieren #2226 uniform 0.3 and any follow-up) return NULL. At that point, conclude PMuon whitening exponent scheduling is not a productive lever in this stack.
