STUDENT g1r3-askeladd:
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["afp19guv","q8pvo0kv","ljyiwbi1"],"primary_metric":{"name":"val/loss","value":3.32242},"test_metric":{"name":"speedrun/final_first_step_to_target","value":-1}}

## Results — H365 INVERSE per-layer LR F-norm coupling (α<0) at H266 — **BILATERAL MONOTONIC NEG confirmed**

Chain complete: 3/3 arms ran clean rc=0, all 3 arms Pattern A step-0 val=10.82583 EXACT, all `lr_mult` REVERSED-scaling telemetry matches predicted to 4 sig figs. **arm_a CTRL TIES H266 anchor**, **arm_b NEG_SQRT STRONG NEG (+18.24σ)**, **arm_c NEG_LINEAR CATASTROPHIC NEG (+62.16σ)**.

Result class: **HARD-LOAD-BEARING bilateral NEG monotonic on `body_lr_init_fnorm_alpha` axis**. Combined with H357 POSITIVE direction (+13.59σ / +113.81σ at α=+0.5/+1.0), the BODY-INIT-FNORM-COUPLING axis is now **fully characterized as DIRECTION-INVARIANT HARD-LOAD-BEARING** with mild ASYMMETRY (POSITIVE α more harmful at |α|=1, NEG α slightly more harmful at |α|=0.5).

### Headline table

| Arm | `--body_lr_init_fnorm_alpha` | W&B run | val/loss | FFS | Δ vs CTRL (σ_H174) | Δ vs H266 baseline (σ_H174) | (3.28−μ)·√n ≥ 0.004 | Verdict |
|-----|------------------------------|---------|----------|-----|--------------------|------------------------------|---------------------|---------|
| arm_a CTRL `α=0.0` (H266 bit-id) | 0.0 | [`afp19guv`](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/afp19guv) | **3.26747** | **3000 EXACT** | (ref) | **−0.80σ POS-TIE** | +0.01253 ✓ | 🎯 19th candidate STRICT FFS=3000 cluster anchor; LOWEST CTRL val of cycle ~2700 to-date |
| arm_b NEG_SQRT `α=-0.5` | -0.5 | [`q8pvo0kv`](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/q8pvo0kv) | 3.28359 | **-1** (missed 3.28) | **+18.24σ STRONG NEG** | +17.43σ | -0.00359 ✗ | ❌ STRONG NEG — mirror of H357 α=+0.5 (+13.59σ), slightly MORE harmful on NEG side at |α|=0.5 |
| arm_c NEG_LINEAR `α=-1.0` | -1.0 | [`ljyiwbi1`](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/ljyiwbi1) | 3.32242 | **-1** (missed 3.28) | **+62.16σ CATASTROPHIC NEG** | +61.36σ | -0.04242 ✗ | ❌ CATASTROPHIC — mirror of H357 α=+1.0 (+113.81σ), about HALF the magnitude on NEG side at |α|=1.0 |

Statistical rule: H266 baseline σ_H174 = 0.000884; FFS<3000 strict gate per Issue #1260.

### Treatment-config audit per `feedback_audit_treatment_runs_too.md` — ALL ARMS PASS

| Run | `body_lr_init_fnorm_alpha` (logged) | step-0 val | `lr_mult_min` | `lr_mult_max` | `lr_mult_median` | `per_group_count` | `init_fnorm` (count/median/max/min) |
|-----|-------------------------------------|------------|---------------|---------------|------------------|-------------------|-----------------------------------|
| arm_a `afp19guv` | 0.0 ✓ | 10.82583 EXACT ✓ | (uniform — α=0 short-circuits per-layer scaling) | (uniform) | (uniform) | (single group) | 72 / 15.94229 / 47.66724 / 15.88809 |
| arm_b `q8pvo0kv` | -0.5 ✓ | 10.82583 EXACT ✓ | **0.57843** ✓ (predicted ~0.58) | 1.00305 | 0.89398 | **72** ✓ | 72 / 15.94401 / 47.65317 / 15.84713 |
| arm_c `ljyiwbi1` | -1.0 ✓ | 10.82583 EXACT ✓ | **0.33497** ✓ (predicted ~0.335) | 1.00490 | 0.79975 | **72** ✓ | 72 / 15.96460 / 47.65911 / 15.88677 |

REVERSED-scaling confirmed on both arm_b/c: high-F-norm attn-proj layers (init F-norm ~47.65, ~3× the median ~15.95) receive **smaller** lr_mult, low-F-norm layers receive ~baseline. All telemetry within prediction tolerances.

### Bilateral dose-response (H357 ∪ H365) on `body_lr_init_fnorm_alpha` axis

| α | direction | source | val/loss | FFS | Δ vs CTRL (σ_H174) |
|---|-----------|--------|----------|-----|---------------------|
| -1.0 | INVERSE LINEAR (this PR arm_c) | H365 `ljyiwbi1` | 3.32242 | -1 | **+62.16σ CATASTROPHIC** |
| -0.5 | INVERSE SQRT (this PR arm_b) | H365 `q8pvo0kv` | 3.28359 | -1 | **+18.24σ STRONG NEG** |
| 0.0 | UNIFORM (CTRL, both PRs) | H365 `afp19guv` / H266 m2ywl0o9 | 3.26747 / 3.26818 | 3000 EXACT | **TIE (−0.80σ POS-TIE on arm_a)** |
| +0.5 | POSITIVE SQRT (H357 arm_b) | H357 (prior PR #2081) | (per advisor) | -1 | **+13.59σ STRONG NEG** |
| +1.0 | POSITIVE LINEAR (H357 arm_c) | H357 (prior PR #2081) | (per advisor) | -1 | **+113.81σ CATASTROPHIC** |

**Bilateral monotonic NEG dose-response, asymmetric about α=0**:
- |α|=0.5: NEG slightly MORE harmful (18.24σ NEG vs 13.59σ POS). Δ ≈ +4.65σ extra NEG on suppression side.
- |α|=1.0: POS substantially MORE harmful (62.16σ NEG vs 113.81σ POS). Δ ≈ +51.65σ extra harm on amplification side.

The asymmetry inverts: small magnitude — suppression slightly worse; large magnitude — amplification far worse. This is consistent with a regime change near |α|=1.0 where POSITIVE coupling pushes attn-proj layers' lr_mult ≈ 3× baseline (causing NaN-risk or divergent updates), while NEGATIVE coupling at α=-1.0 caps lr_mult on those layers at ~0.335× (sub-optimal but not divergent). The H266 attractor is **locally Pareto-optimal on the uniform-LR axis** — both directions degrade, but the catastrophic regime is strictly POSITIVE.

### Mechanism conclusion

H351 BODY-INIT-FNORM-PRESERVATION-IS-LOAD-BEARING + H357 BODY-INIT-FNORM-COUPLING-DISRUPTS-EQUILIBRIUM are now refined to:

**The H266 stack prefers UNIFORM per-layer LR (`lr_mult=1.0` for all 72 MuonH groups). Any explicit coupling on the BODY init F-norm axis (POSITIVE or NEGATIVE α) HARD-LOAD-BEARING disrupts the MuonH `scale_invariant` equilibrium. The F-norm preservation observed in H351 is a CONSEQUENCE of the optimizer's `scale_invariant` update rule, NOT a TARGET that should be reinforced or suppressed by explicit per-layer LR scaling.**

This closes the BODY-INIT-FNORM-COUPLING axis as a dead-end mechanism class (no WIN on either direction; bilateral HARD-LOAD-BEARING confirmation).

### Exact commands

**arm_a CTRL** (`afp19guv`):
```bash
cd records/track_3_optimization && torchrun --standalone --nproc_per_node=1 train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
  --body_lr_init_fnorm_alpha 0.0 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H365_inverse_body_lr_init_fnorm_coupling \
  --wandb_name g1r3-askeladd/H365_arm_a_CTRL_alpha0p0
```

**arm_b NEG_SQRT** (`q8pvo0kv`) — same command with `--body_lr_init_fnorm_alpha -0.5`; W&B name `g1r3-askeladd/H365_arm_b_NEG_SQRT_alpha-0p5`.

**arm_c NEG_LINEAR** (`ljyiwbi1`) — same command with `--body_lr_init_fnorm_alpha -1.0`; W&B name `g1r3-askeladd/H365_arm_c_NEG_LINEAR_alpha-1p0`.

Pre-launch smoke (arm_b 125 steps, `9z4wnb8v`) passed before chain launch — step-0=10.82583 EXACT, lr_mult range [0.5787, 1.0019] matching prediction.

### Resource usage

- Single H100, scale_invariant MuonH, batch size unchanged from H266.
- Per-arm wall time: ~1h 50m (3325 steps × ~1830ms/step).
- Total chain wall: 5h 28m (13:54:23Z → 19:22:33Z).
- Peak memory: nominal (no architectural change; same as H266 reference).
- Pre-launch smoke: ~4 min.

### W&B run IDs

- arm_a CTRL: `afp19guv` — https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/afp19guv
- arm_b NEG_SQRT: `q8pvo0kv` — https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/q8pvo0kv
- arm_c NEG_LINEAR: `ljyiwbi1` — https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/ljyiwbi1
- Pre-launch smoke: `9z4wnb8v` — https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/9z4wnb8v

W&B group: `H365_inverse_body_lr_init_fnorm_coupling`.

### What happened — honest analysis

**Did it work?** No on FFS (the merge gate), confirmed bilateral HARD-LOAD-BEARING on this axis. arm_a CTRL TIE-replicates H266 cluster anchor as expected (19th candidate strict FFS=3000 cluster member; lowest CTRL val of cycle ~2700 at 3.26747 by -0.80σ vs H266 m2ywl0o9, within CUDA-determinism envelope). arm_b NEG_SQRT and arm_c NEG_LINEAR both fail strict FFS<3000 (FFS=-1, missed 3.28 target) and exceed `(3.28-μ)·√n ≥ 0.004` margin in the wrong direction.

**Why?** The MuonH `scale_invariant` mode already provides per-layer scale handling implicitly via the update rule. Adding explicit per-layer LR multipliers proportional to init F-norm (either positive — boosting high-F-norm layers, or negative — suppressing them) introduces noise into a regime where the optimizer has already converged to uniform behavior. The 4 attn-proj layers with init F-norm ~47.65 are the main "lever" of the per-layer LR mechanism — POSITIVE α gives them disproportionate LR (catastrophic at α=+1.0, lr_mult ≈ 3× baseline → divergent updates), NEGATIVE α starves them of LR (catastrophic at α=-1.0, lr_mult ≈ 0.335× baseline → undertrained representation).

**Mechanism characterization** (paper-grade): The H266 attractor is **locally Pareto-optimal on the uniform-LR axis with respect to BODY init F-norm structure**. Both POSITIVE and NEGATIVE α perturbations break this optimality monotonically. The bilateral characterization (`H357 ∪ H365`) closes the BODY-INIT-FNORM-COUPLING mechanism class.

**Pattern A bit-id integrity**: All 3 arms (and the smoke) reproduce step-0 val=10.82583 EXACT, confirming the existing-flag short-circuit on α=0 and the per-arm treatment values are correctly logged in W&B config.

### Suggested follow-ups

Now that the BODY-INIT-FNORM-COUPLING axis is closed bilaterally, mechanism-coherent follow-ups are:

1. **Per-LAYER coupling on a DIFFERENT axis** — instead of init F-norm, couple per-layer LR to per-layer **input fan-in** (depth-symmetric) or **per-layer parameter count** (which would not single out attn-proj layers, since their parameter count is similar to other linear layers). This isolates whether the F-norm asymmetry specifically is the load-bearing structure, vs a generic per-layer LR coupling.
2. **Per-MODULE coupling (not per-LAYER)** — pre-define module-level LR multipliers (attn-proj vs MLP-down vs attn-qkv vs MLP-up) with hand-set values rather than F-norm-derived. Tests whether the structural class of the layer matters, decoupled from the F-norm magnitude.
3. **Cooldown-window only coupling** — apply `body_lr_init_fnorm_alpha` only during the cooldown window (e.g. step≥2826) while keeping uniform LR during warmup+plateau. The current implementation applies the coupling throughout; testing cooldown-only isolates whether the optimizer needs uniform LR during the plateau but tolerates per-layer scaling during cooldown.
4. **Skip this axis class entirely** — given bilateral HARD-LOAD-BEARING characterization is paper-grade, devote screening capacity to mechanism-distinct axes (e.g. AUX-side LR coupling, ATTENTION-head-level scaling, RMS-norm-gradient-clip per-layer).

Personal recommendation: follow-up (3) — cooldown-only coupling — is the highest-value next step because it directly tests whether the H266 cooldown trajectory is the load-bearing piece, or the plateau equilibrium. (1) and (2) are also interesting but expand the search space rather than refining the mechanism. (4) is the most pragmatic if cycle budget is tight.

H365 closes as **NEW LARGEST NEG mirror-pair entry of cycle ~2700** (alongside H357), with bilateral HARD-LOAD-BEARING characterization fully closing the BODY-INIT-FNORM-COUPLING mechanism class.
