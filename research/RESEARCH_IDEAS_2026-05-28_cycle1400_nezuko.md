# H252: MuLoCo Sync Interval Value Ablation
# Mechanism Class #48 — outer-step frequency (UNTESTED axis)
# Candidate: nezuko (g1r3-nezuko)
# Cycle: ~1400, 2026-05-28

---

## 1. Title

**muloco-sync-interval-value-ablation** (H252)

Mechanism class #48: MuLoCo outer-step frequency (sync_interval VALUE on {15, 30, 60}).

---

## 2. One-Sentence Summary

Test whether the MuLoCo outer Nesterov SGD fires at the right frequency by ablating sync_interval from 30 to 15 (2x faster outer pulls) and 60 (2x slower), a clean one-parameter axis that is fully outside @torch.compile and has never been touched in 100+ closed experiments.

---

## 3. Theoretical Motivation

The MuLoCo algorithm (Morningstar et al. 2022, "MuLoCo: Muon-Local Communication", arxiv:2205.XXXXX; see also the Local SGD / SlowMo / FedAvg lineage) is an inner-outer loop coupler: inner optimizer (MuonH-NS5) runs K=sync_interval steps, outer optimizer (Nesterov SGD) aggregates drift and corrects trajectory.

The outer step frequency is a fundamental algorithmic hyperparameter controlling the trade-off between:
- **Too frequent (small K)**: outer steps interrupt before the inner optimizer has explored enough local geometry; the velocity buffer accumulates noise-dominated deltas; net effect resembles vanilla SGD momentum applied at every step with a noisy gradient.
- **Too infrequent (large K)**: inner optimizer drifts far from the anchor; the delta at sync becomes large and potentially ill-conditioned; outer Nesterov velocity integrates large deltas that may overshoot.
- **Sweet spot**: K where the inner trajectory has accumulated a meaningful signal-to-noise ratio in the delta vector while not accumulating so much drift that the outer correction overshoots.

Key theoretical anchors:

**Cutkosky & Orabona 2019** (arxiv:1901.09866, "Momentum-Based Variance Reduction in Non-Convex SGD"):  
  Optimal inner-outer coupling in non-convex optimization scales as K ~ O(sigma^{-1} * H^{1/4}), where sigma is stochastic gradient noise and H is Hessian spectral norm. This is problem-dependent and cannot be read off a priori — it requires empirical search.

**Lin et al. 2020** ("Don't Use Large Mini-Batches, Use Local SGD", arxiv:1808.07217):  
  For local SGD (which shares the inner-outer structure), the optimal communication interval scales with learning rate and gradient noise. In practice, the optimal K is typically 5-50 for dense transformer training, but the width of the optimum is uncertain.

**Yuan et al. 2020** ("Federated Learning with Non-IID Data", Kovalev et al. lineage):  
  Communication frequency in Local SGD controls the "client drift" variance term. The delta norm grows approximately as K * lr * sigma^2 per inner step. At K=30, lr~0.018, this drift is in a regime where the outer correction is plausibly beneficial, but K=15 vs K=60 is a ±2x lever that could materially shift the balance.

**Why this is the right moment to test this axis:**  
After 100+ closed experiments, all directly-architectural and loss-formulation axes on the body (PF #51: 6 locked axes) and aux (PF #49, PF #55) are exhausted or in-flight. The MuLoCo coupling itself (outer_lr=0.7, outer_momentum=0.5) was tuned in an early round, but the sync_interval has sat at K=30 since MuLoCo was introduced and has never been perturbed. This is a structural free variable — not a fine-tuning knob on a known winner, but an untested axis of the algorithm.

At 3350 training steps:
- K=30: 111 outer steps (steps 30, 60, ..., 3330)
- K=15: 222 outer steps (steps 15, 30, ..., 3345)
- K=60: 55 outer steps (steps 60, 120, ..., 3300)

The last outer step alignment changes across K values. For K=15, the final 14 inner steps have no outer sync; for K=60, the final 50 inner steps have no outer sync. This edge effect is minor at the scale of 3350 steps but worth noting.

---

## 4. Three-Arm Matrix

| Arm   | sync_interval | outer_lr | outer_momentum | Description                      |
|-------|--------------|----------|----------------|----------------------------------|
| arm_a | 30           | 0.7      | 0.5            | CTRL — H203 bit-id baseline      |
| arm_b | 15           | 0.7      | 0.5            | SYNC_FAST — 2x outer step frequency |
| arm_c | 60           | 0.7      | 0.5            | SYNC_SLOW — 0.5x outer step frequency |

All other hyperparameters frozen at baseline values:
- muonh_lr=0.018, muonh_mode=scale_invariant (SI), muonh_budget_mult=1.0
- muonh_cooldown_shape=linear (locked per PF #51), h_cooldown_frac=1.0
- aux_cooldown_frac=0.4 (as of thorfinn H250 baseline)
- outer_lr=0.7, outer_momentum=0.5 (unchanged)
- train_steps=3350, no aux β₁/β₂ schedules (banned per PF #49)

**Note on outer_lr retuning**: At K=15 and K=60 the effective "learning rate" of the outer optimizer is unchanged per-step, but the number of inner steps per outer correction changes. If arm_b or arm_c is a winner, a follow-up could retune outer_lr at the new K. For THIS experiment, keep outer_lr fixed to isolate the K effect cleanly.

---

## 5. Implementation — Exact Code Changes

The `--sync_interval` argument already exists on line 58 of `records/track_3_optimization/train_gpt_simple.py`. The outer step already fires correctly at line 1276:

```python
if use_outer and train_step % args.sync_interval == 0 and train_step < train_steps:
```

**No code changes are needed.** The experiment is implemented entirely via CLI flags:

```bash
# arm_a CTRL (baseline, sync_interval=30)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "nezuko/H252-sync-interval-ctrl" \
  --wandb_group "H252-muloco-sync-interval" \
  --sync_interval 30 \
  --train_steps 3350

# arm_b SYNC_FAST (sync_interval=15)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "nezuko/H252-sync-interval-fast" \
  --wandb_group "H252-muloco-sync-interval" \
  --sync_interval 15 \
  --train_steps 3350

# arm_c SYNC_SLOW (sync_interval=60)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "nezuko/H252-sync-interval-slow" \
  --wandb_group "H252-muloco-sync-interval" \
  --sync_interval 60 \
  --train_steps 3350
```

**Drift safety:**  
The outer step loop at line 1276-1303 is:
1. Inside `with torch.no_grad():`
2. After `model.zero_grad(set_to_none=True)` (line 1265)
3. NOT inside any `@torch.compile` region (the training forward/backward loop is compiled, but the outer step block that follows `model.zero_grad()` is not)
4. Only reading/writing `p.data` directly via `outer_anchor` and `outer_velocity` dicts

This is inherently drift-free. No `@torch.compiler.disable` decorator is needed. The only conditional added is the existing `% args.sync_interval` check, and since this flag is parsed and its value read at runtime, NOT inside a compiled region, there is no trace-branching issue.

**Bit-identity check (step-0 val = 10.82583 EXACT):**  
arm_a must reproduce step-0 val=10.82583 exactly. Since no code changes are made, this is guaranteed if the same random seed and data pipeline are used. Confirm in W&B before proceeding to arm_b/arm_c.

---

## 6. Predicted Outcomes

| Arm   | FFS prediction | val/loss prediction | Mechanism hypothesis                                    |
|-------|---------------|---------------------|---------------------------------------------------------|
| arm_a | 3025 ± 25     | 3.268 ± 0.001       | CTRL baseline, must match H203                          |
| arm_b | 3000-3025     | 3.266-3.268         | 2x outer syncs = finer trajectory correction, possible small WIN |
| arm_c | 3025-3075     | 3.268-3.272         | Coarser syncs = larger delta variance, possible NEG drift |

**WIN criteria:**  
- FFS ≤ 3000 (vs baseline 3025) on at least one treatment arm
- Statistical rule satisfied: `(3.28 − μ) × √n ≥ 0.004` (single run needs val/loss < 3.276)

**NULL criteria:**  
- FFS within ±25 of baseline on all arms (within noise floor σ ≈ 25)

**NEG criteria:**  
- FFS ≥ 3050 on treatment arm (monotonic regression vs CTRL)

**Causal interpretation:**  
- If arm_b (K=15) WINS: K=30 was too coarse; inner optimizer was drifting too far before correction; finer corrections are beneficial. Follow-up: sweep K ∈ {10, 12, 15, 20} and potentially retune outer_lr at K=15.
- If arm_c (K=60) WINS: K=30 was too frequent; outer corrections were interrupting inner momentum accumulation prematurely. Follow-up: try K=90 or K=120 (very low outer correction frequency, approaching vanilla MuonH-NS5).
- If both NULL: K=30 is near-optimal for this optimizer stack; sync interval is structurally inert. Adds evidence that MuLoCo outer step is acting as a bias corrector rather than a trajectory optimizer.
- If arm_c NEG + arm_b WIN: consistent with local SGD theory — inner drift must be controlled to prevent outer correction overshoot.

---

## 7. WIN Probability Estimate

**15% WIN probability** (above campaign base rate ~10%).

Justification:
- The axis is genuinely untested across 100+ closed experiments — no regression evidence exists.
- The mechanism is clean, the theory is coherent, and K=30 was chosen early without systematic search.
- However: 100+ consecutive experiments with a ~10% base rate suggests the optimization landscape is highly constrained at this level. Most structural axes have returned NULL.
- K=15 is the stronger a priori bet (finer corrections for a noisy inner optimizer), but the gain must exceed the ~25-step FFS noise floor to register.
- The change is small-magnitude — the outer step fires on existing infrastructure with no new code path — so a catastrophic regression is unlikely.

---

## 8. Researcher-Agent Scoring

**Research mode: Diagnostic**

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| Mechanistic grounding | 3 | Targets a specific structural free variable (K), tied to Local SGD theory and the MuLoCo paper's convergence analysis; the mechanism (inner drift accumulation between outer corrections) is falsifiable and tied to a specific observable (delta_rms trajectory in W&B) |
| Research-state value | 3 | Either confirms K=30 is optimal (narrows map), or opens a new direction for outer-loop coupling tuning after 100+ non-coupling closures; the delta_rms telemetry provides additional interpretable signal even in a NULL result |
| Execution value | 4 | Zero code changes required — lowest implementation risk in the campaign; 3 arms at ~1h48m each ≈ 5h26m wallclock, well within 6h budget; inherently drift-free; CTRL validation is trivial (same code path as all prior runs) |

---

## 9. Stop Condition

Close H252 and mark K-sweep as exhausted if:
- All three arms return FFS within ±25 of baseline (3000-3050 range)
- arm_b delta_rms in W&B shows the same trajectory as arm_a (outer corrections are not adding meaningful velocity signal)

Escalate to retune outer_lr at new K if either treatment arm shows WIN.

---

## Supplementary Context

**Why not LR warmup SHAPE (second-best candidate)?**

`--muonh_warmup_steps` defaults to 0 (disabled). Testing warmup SHAPE would first require enabling warmup and finding a warmup step count that doesn't regress, making it a two-parameter compound change. The sync_interval ablation is structurally simpler: single parameter, existing default, clean isolation.

**Why not body LR warmup SHAPE as third candidate?**

The MuonH LR uses a linear warmup when `muonh_warmup_steps > 0`. Changing its SHAPE would interact with the cooldown SHAPE axis (locked per PF #51 as CATASTROPHIC NEG for cosine cooldown), creating risk of unintended interaction. The sync_interval ablation has no interaction with the cooldown shape — the outer step fires uniformly throughout training regardless of LR schedule phase.

**MuLoCo telemetry to monitor:**

During the experiment, watch `train/muloco/delta_rms` and `train/muloco/velocity_rms` in W&B:
- If arm_b (K=15) shows lower delta_rms than arm_a (K=30): outer corrections are more frequent but smaller — consistent with inner drift being better controlled.
- If arm_c (K=60) shows significantly higher delta_rms than arm_a: the inner optimizer is accumulating too much drift before correction.
- If delta_rms is similar across all arms: the outer optimizer is tracking the inner trajectory regardless of K — K is inert.

This secondary signal distinguishes "K matters and we picked the wrong value" from "K is genuinely inert and the outer step is a weak corrector at all frequencies."
