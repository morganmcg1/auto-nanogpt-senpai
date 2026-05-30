# HYPOTHESIS — thorfinn — Body PMuon L_cov vs R_cov per-side ZERO RESET @ step 1100

**Branch:** `g1r1-thorfinn/body-l-vs-r-cov-reset`
**Assigned:** 2026-05-30 16:10 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state reset at phase boundaries + (b) per-layer/per-block (here per-SIDE) optimizer behavior + (d) preconditioner state handling

## Why this hypothesis

frieren #1780 tested body PMuon **L_cov AND R_cov BILATERAL zero reset** at step 1100 — Arm B (cov-reset@1100) seed-1 produced the strongest body-side signal in the programme: sr=2875, val_ema=3.262685 (−0.169 mnat below gate). Seed-2 is in flight (tracking toward NULL on speedrun clause, n=2 mean likely fails).

**Independently, nezuko #1815 just established the asymmetric-primitive paradigm pays off on aux Adam:** m-only ZERO RESET @ step 975 produced an even STRONGER signal — sr=2875, val_ema=3.262238 (−0.616 mnat below gate, 3.6× larger margin than frieren). The asymmetric (m-only) primitive WORKS where the symmetric (m+v full reset, #1770) FAILED.

**This PR transfers the asymmetric-primitive paradigm from aux Adam to body PMuon's L/R covariance preconditioners at step 1100.**

The body PMuon update is `L^{-γ} · g · R^{-γ} · NS5(g)`. L_cov and R_cov are independent EMAs of left and right covariance statistics:
- **L_cov** tracks the row-space (activation/input-side) covariance: `L ← β_cov · L + (1-β_cov) · g · gᵀ`
- **R_cov** tracks the column-space (gradient/output-side) covariance: `R ← β_cov · R + (1-β_cov) · gᵀ · g`

At step 1100 (175 steps into cooldown, post β₂ pulse @ 975), L and R carry pre-cooldown covariance statistics that may be out-of-distribution relative to the cooldown gradient regime. frieren #1780 wiped BOTH and got close-miss. This PR isolates which side carries the signal — analogous to nezuko separating m from v.

**Mechanistic priors:**

- **L_cov ONLY reset:** input-space preconditioner re-accumulates from cooldown statistics; R preserves warmup output-side curvature. If activations distribution shifts more than gradients at cooldown, L-reset is the load-bearing side.
- **R_cov ONLY reset:** gradient-space preconditioner re-accumulates from cooldown statistics; L preserves activation-side history. If gradient magnitudes shift more than activations (likely, given LR decay), R-reset is the load-bearing side.
- **Prediction:** R-only reset is more likely to carry the signal — gradient magnitudes change visibly under cooldown LR decay, while activations (driven by stable weight EMA) shift less. If neither matches frieren #1780 bilateral, the close-miss requires JOINT reset.

## Distinct from in-flight and closed work

- **frieren #1780** (HOT seed-2 in flight): L_cov AND R_cov BILATERAL zero reset @ step 1100 — this PR splits that into the per-side asymmetric primitive
- **nezuko #1726** (CLOSED): L_cov + R_cov BILATERAL reset @ step 2750 — different boundary, different mechanism (failed at pre-target)
- **askeladd #1730** (CLOSED): momentum ZERO @ step 2750 — different STATE (momentum, not cov), different boundary
- **thorfinn #1797** (just CLOSED): momentum SCALE @ 975 — momentum state axis closed at this boundary
- **nezuko #1815** (running, Arm A WIN): aux Adam m/v asymmetric split — different OPTIMIZER (aux not body), different state (moment not cov)
- No prior per-side L vs R asymmetric reset.

## Experiment design

**Bilateral on which side resets (step 1100 fixed):**

- **Arm A — L_cov ONLY zero reset** @ step 1100 (R_cov preserved)
- **Arm B — R_cov ONLY zero reset** @ step 1100 (L_cov preserved)

Both arms preserve canonical β₂ pulse @ 975 and pEMA refresh @ 2600.

## Implementation guidance

frieren #1780 added the bilateral cov-reset flags. Inspect `records/track_3_optimization/train_gpt_simple.py` for:
- `--body_muon_cov_reset_step` (existing from #1780)
- The L/R reset block (look for `state["L"].zero_()` and `state["R"].zero_()`)

**Step 1: Add per-side scope flag**

```python
parser.add_argument(
    "--body_muon_cov_reset_scope", type=str, default="both",
    choices=["both", "L", "R"],
    help="Which cov state(s) to zero at the reset step (default 'both' matches frieren #1780)",
)
```

**Step 2: Modify existing cov-reset block to honor scope**

Find the existing block (from frieren #1780) and change the zero-call to be scope-gated:

```python
if (args.body_muon_cov_reset_step > 0
        and step == args.body_muon_cov_reset_step):
    n_L = n_R = 0
    for group in optimizer2.param_groups:
        for p in group["params"]:
            state = optimizer2.state.get(p, None)
            if state is None:
                continue
            if args.body_muon_cov_reset_scope in ("both", "L") and "L" in state:
                state["L"].zero_()
                n_L += 1
            if args.body_muon_cov_reset_scope in ("both", "R") and "R" in state:
                state["R"].zero_()
                n_R += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] body PMuon cov reset scope={args.body_muon_cov_reset_scope} "
               f"(L zeroed: {n_L}, R zeroed: {n_R})", console=True)
        if wandb.run is not None:
            wandb.log({
                "body_cov_reset/scope": args.body_muon_cov_reset_scope,
                "body_cov_reset/n_L": n_L,
                "body_cov_reset/n_R": n_R,
            }, step=step)
```

**CRITICAL:** The default scope must be `"both"` so legacy frieren #1780 invocations don't change behavior.

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_reset_step 50 --body_muon_cov_reset_scope L
```

Assert:
1. Sentinel `[step 50] body PMuon cov reset scope=L (L zeroed: N, R zeroed: 0)` where N matches the number of body PMuon params (likely 72 — same as thorfinn #1797's momentum count, or whatever frieren #1780's smoke showed).
2. `body_cov_reset/n_R=0` for scope=L; `body_cov_reset/n_L=0` for scope=R.
3. No NaN, no loss spike at the reset step.

## Reproduce commands

**Arm A (L_cov ONLY reset @ step 1100):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_reset_step 1100 --body_muon_cov_reset_scope L \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-thorfinn-body-l-vs-r-cov-reset \
  --wandb_name g1r1-thorfinn/L-only-cov-reset-1100-armA
```

**Arm B (R_cov ONLY reset @ step 1100):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_reset_step 1100 --body_muon_cov_reset_scope R \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-thorfinn-body-l-vs-r-cov-reset \
  --wandb_name g1r1-thorfinn/R-only-cov-reset-1100-armB
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT change reset step from 1100** — frieren #1780's signal localized this boundary
- **Do NOT scope to "both"** — that is #1532 baseline + frieren #1780 territory; both arms test single-side scopes
- **Do NOT touch β₂ pulse, paramEMA refresh** — preserve all canonical interventions
- **Do NOT modify L/R cov BUFFER computation** (β_cov, eps_cov) — only the zero-reset side selection changes
- **Do NOT modify body PMuon momentum** — that's thorfinn #1797 territory (CLOSED)

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate (L-only carries signal)** | Input-side preconditioner is load-bearing at cooldown boundary; activations shift more than gradients. Request seed-2. Follow-up: depth-stratified L-reset. |
| **Arm B WIN merge gate (R-only carries signal)** | Output-side / gradient preconditioner is load-bearing; gradient magnitudes' cooldown shift is the mechanism. Request seed-2. Follow-up: depth-stratified R-reset, OR R-reset at multiple cooldown boundaries. |
| **Both NULL but close-miss** | Per-side reset insufficient; signal requires JOINT bilateral (frieren #1780 finding) and per-side decomposition cannot recover it. |
| **Both NULL deep (sr ≥ 2950)** | L/R state at step 1100 is mutually load-bearing; partial reset destabilizes update. Closes per-side primitive. |
| **One arm crashes / diverges** | Asymmetric preconditioner update is structurally unstable. Likely R-only (output gradient blow-up). |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
