# Baseline — auto-nanogpt-1gpu-r3

## Primary metric

`speedrun/final_first_step_to_target` — lowest training step at which the run
first reached `val/loss <= 3.28`. Direction: **lower is better** (`-1` means the
run never reached the target).

Final-claim statistical rule (from `program.md` and the track 3 README):

```
(3.28 - mu) * sqrt(n) >= 0.004
```

So a single non-cherry-picked run needs `mu < 3.276`; `n=4` runs need
`mean < 3.278`; `n=10` runs need `mean < 3.27873`.

## Current baseline (this branch)

**Merged 2026-05-27 ~11:35 UTC — PR #1398 tanjiro H203 MuonH body cooldown SHAPE = cosine.** Swaps the MuonH inner LR cooldown shape from `linear` back to `cosine` on the fully-stacked H148 baseline. Cosine concentrates LR near peak for the first ~70% of cooldown, then collapses aggressively in the final 30% — at step 3100 cosine LR is 6× lower than linear, precipitating target crossing **125 steps earlier (FFS 3025 vs 3150 for CTRL)**. The cosine vs linear comparison from H133 was run WITHOUT the H148 orthogonal-init + µ-schedule stack; the stacked H148 configuration sits closer to the convergence basin, making faster late-LR collapse beneficial now where it was harmful pre-stack. Terminal val/loss (3.26830) is a slight regression vs H148 terminal (3.26364) because cosine nearly stops learning after step ~3100 (LR ≈ 0.0002) while linear keeps gradients flowing — future follow-ups (cosine_squared, quad, cosine × reduced h_cooldown_frac) may recover the terminal val/loss while preserving or improving FFS. arm_c sqrt catastrophic FAIL (val=3.29370, never reached target) confirms slow late decay is universally harmful. **First cooldown-shape axis win since H133** (H133 flipped linear→cosine; H203 flips it back on a stronger stack).

| Field | Value |
| --- | --- |
| `train_steps` | 3325 |
| Architecture | GPT-768/12L, vocab 50304, ctx 1024 — fixed |
| Batch size | `8 * 64 * 1024 = 524288` tokens/step — fixed |
| Main optimizer | `MuonH(lr=0.018, weight_decay=0, mode='scale_invariant')` on blocks ndim≥2 |
| Body init | `--body_init orthogonal_fnorm_matched` |
| **MuonH inner cooldown shape** | **`--muonh_cooldown_shape cosine`** (was `linear` in H148) |
| MuonH µ schedule | `--muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90` |
| Aux AdamW β2 | `--aux_beta2_schedule constant --aux_beta2_start 0.99` |
| Aux AdamW eps | `--aux_adamw_eps 1e-6` |
| MuonH AGC | `--muonh_agc_clip_ratio 0.05` |
| Aux AGC | `--aux_agc_clip_ratio 0.05` |
| MuonH warmup | `--muonh_warmup_steps 100` |
| Outer wrapper | `MuLoCo(outer_lr=0.7, outer_momentum=0.5, sync_interval=30)` |
| `val/loss` | **3.26830** (n=1 trial; slight regression from H148 3.26364, FFS is the primary metric) |
| `speedrun/final_first_step_to_target` | **3025** (n=1; **−100 steps vs H148 baseline 3125**) |
| stat margin | `(3.28 − 3.26830) × √1 = 0.01170` ≥ 0.004 ✓ |
| Baseline W&B run | `pyea3zd1` |
| Baseline PR | [#1398](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/1398) |

### Reproduce cosine cooldown + orthogonal body init + AGC + MuLoCo × MuonH-SI baseline

```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --wandb_name "g1r3-<student>/h203-baseline-confirm" \
  --wandb_group "g1r3-h203-baseline-confirm"
```

---

## Previous baseline — PR #1157 edward H148 Body init orthogonal (F-norm matched) (2026-05-25 ~16:15 UTC)

**Merged 2026-05-25 ~16:15 UTC — PR #1157 edward H148 Body init orthogonal (F-norm matched).** Replaces random Gaussian body init (`normal_(std=0.026–0.031)`) with `torch.nn.init.orthogonal_` rescaled to preserve each weight's default F-norm exactly. Persistent −0.00164 val/loss advantage holds at every single checkpoint after step 1250. val/loss=3.26364, FFS=3125. Superseded by PR #1398.

| Field | Value |
| --- | --- |
| `val/loss` | **3.26364** (n=1) |
| `speedrun/final_first_step_to_target` | **3125** (n=1) |
| Baseline W&B run | `jg6p3l50` |
| Baseline PR | [#1157](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/1157) |

---

## Previous baseline — PR #1097 fern H133 Inner MuonH LR cooldown SHAPE = linear (2026-05-25 ~06:20 UTC)

**Merged 2026-05-25 ~06:20 UTC — PR #1097 fern H133 Inner MuonH LR cooldown SHAPE = linear (frac=1.0).** Swaps inner LR cooldown shape from cosine to **linear** via `--muonh_cooldown_shape linear`. The first programme-level **shape** finding since the baseline was set at H117 — breaks a 14+ consecutive non-merging closure plateau. Mechanism: cosine cooldown's `eta = 0.5(1 − cos(πc))` derivative goes to zero as c→0 (LR drops too steeply at end), while linear cooldown's constant slope preserves useful gradient signal through the last ~325 steps. U-shaped lead profile observed (arm_b LEADS through step 1500, deficits step 2000–3000, recovers and overtakes for terminal WIN). Falsifies H125 mid-training-lead-erosion generalization to the SHAPE axis (sqrt's higher mid-training LR actively destroys trajectory). Composes with H117 µ-schedule baseline. Stacks on top of all previous wins: MuLoCo × MuonH-SI + dual AGC + LR warmup + aux eps=1e-6 + aux β2=0.99 + µ-schedule (0.95→0.90).

| Field | Value |
| --- | --- |
| `train_steps` | 3325 |
| Architecture | GPT-768/12L, vocab 50304, ctx 1024 — fixed |
| Batch size | `8 * 64 * 1024 = 524288` tokens/step — fixed |
| Main optimizer | `MuonH(lr=0.018, weight_decay=0, mode='scale_invariant')` on blocks ndim≥2 |
| **MuonH inner cooldown shape** | **`--muonh_cooldown_shape linear`** (was cosine) |
| MuonH µ schedule | `--muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90` |
| Aux AdamW β2 | `--aux_beta2_schedule constant --aux_beta2_start 0.99` |
| Aux AdamW eps | `--aux_adamw_eps 1e-6` |
| MuonH inner AGC | `--muonh_agc_clip_ratio 0.05` |
| MuonH LR warmup | `--muonh_warmup_steps 100` |
| Outer wrapper | `MuLoCo(outer_lr=0.7, outer_momentum=0.5, sync_interval=30)` |
| Aux AdamW | `betas=(0.8, 0.99), eps=1e-6, weight_decay=0` + AGC `clip_ratio=0.05` |
| LR schedule | **Linear** cooldown for MuonH (`cooldown_frac=1.0`); linear cooldown for aux (`cooldown_frac=0.4`) |
| `val/loss` | **3.26547** (n=1 trial; passes n=1 bar < 3.27206) |
| `speedrun/final_first_step_to_target` | **3150** (n=1) |
| stat margin | `(3.28 - 3.26547) * sqrt(1) = 0.01453` ≥ 0.004 ✓ |
| Baseline W&B run | `n21sh37z` (arm_b LINEAR); full group: `58wedojq` (arm_a CTRL cosine 3.26902), `xk5gmtnq` (arm_c SQRT 3.29121) |
| Baseline PR | [#1097](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/1097) |

### Reproduce H133 linear cooldown + µ-schedule (0.95→0.90) + Aux β2=0.99 + eps=1e-6 + AGC inner + MuonH warmup + AGC aux + MuLoCo × MuonH-SI baseline

```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape linear \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
```

---

## Previous baseline — PR #1027 fern H117 Inner MuonH µ DECREASING Schedule 0.95→0.90 (2026-05-24 ~16:00 UTC)

**Merged 2026-05-24 ~16:00 UTC — PR #1027 fern H117 Inner MuonH µ DECREASING Schedule (0.95→0.90).** Linear µ schedule decreasing from 0.95 to 0.90 over 3325 steps via `--muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90`. Lower µ throughout training reduces momentum smoothing of the NS5-orthogonalized update direction, improving gradient-tracking responsiveness without relying on Sutskever effective-step amplification. arm_c BOLD (0.95→0.90) winner at val/loss=3.26706, ffs=3025. Baseline W&B run `dmvm8eat`. Superseded by PR #1097.

---

## Previous baseline — PR #888 frieren H87 Aux AdamW β2=0.99 constant (2026-05-23 ~14:20 UTC)

**Merged 2026-05-23 ~14:20 UTC — PR #888 frieren H87 Aux AdamW β2=0.99 constant.** Increases aux AdamW β2 from 0.95 to 0.99 (constant throughout training) via new `--aux_beta2_schedule constant --aux_beta2_start 0.99` CLI flags. Longer second-moment EMA window stabilizes aux grad estimates globally — terminal global_norm 6% lower than β2=0.95 (23,009 vs 24,500). A cooldown-ramp variant (arm_b, β2 0.95→0.99 during cooldown) landed NULL: the level matters, not the timing. Stacks on top of MuLoCo × MuonH-SI + dual AGC + cosine cooldown + LR warmup + aux eps=1e-6.

| Field | Value |
| --- | --- |
| `train_steps` | 3325 |
| Architecture | GPT-768/12L, vocab 50304, ctx 1024 — fixed |
| Batch size | `8 * 64 * 1024 = 524288` tokens/step — fixed |
| Main optimizer | `MuonH(lr=0.018, mu=0.95, weight_decay=0, mode='scale_invariant')` on blocks ndim≥2 |
| **Aux AdamW β2** | **`--aux_beta2_schedule constant --aux_beta2_start 0.99`** (was 0.95) |
| Aux AdamW eps | `--aux_adamw_eps 1e-6` |
| MuonH inner AGC | `--muonh_agc_clip_ratio 0.05` |
| MuonH LR warmup | `--muonh_warmup_steps 100` |
| Outer wrapper | `MuLoCo(outer_lr=0.7, outer_momentum=0.5, sync_interval=30)` |
| Aux AdamW | `betas=(0.8, 0.99), eps=1e-6, weight_decay=0` + AGC `clip_ratio=0.05` |
| LR schedule | Cosine cooldown for MuonH (`cooldown_frac=1.0`); linear cooldown for aux (`cooldown_frac=0.4`) |
| `val/loss` | **3.26977** (n=1 trial; passes n=1 bar < 3.27206) |
| `speedrun/final_first_step_to_target` | **3075** (n=1; improves over previous baseline 3100 by 25 steps) |
| stat margin | `(3.28 - 3.26977) * sqrt(1) = 0.01023` ≥ 0.004 ✓ |
| Baseline W&B run | `0z3c44wp` |
| Baseline PR | [#888](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/888) |

### Reproduce Aux β2=0.99 + eps=1e-6 + AGC inner + MuonH warmup + cosine cooldown + AGC aux + MuLoCo × MuonH-SI baseline

```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99
```

---

## Previous baseline — PR #443 edward Aux AdamW eps=1e-6 (2026-05-19 ~13:25 UTC)

**Merged 2026-05-19 ~13:25 UTC — PR #443 edward Aux AdamW eps=1e-6.** Increases aux AdamW epsilon from 1e-10 to 1e-6 via new `--aux_adamw_eps` CLI flag. Heavier denominator smoothing on aux params (embed, lm_head, scalars) — reduces noise in Adam's adaptive LR on low-gradient parameters, which slightly speeds early convergence. Single trial; passes n=1 promotion bar (val=3.27119 < 3.27206) and stat rule. Stacks on top of MuLoCo × MuonH-SI + dual AGC + cosine cooldown + LR warmup.

| Field | Value |
| --- | --- |
| `train_steps` | 3325 |
| Architecture | GPT-768/12L, vocab 50304, ctx 1024 — fixed |
| Batch size | `8 * 64 * 1024 = 524288` tokens/step — fixed |
| Main optimizer | `MuonH(lr=0.018, mu=0.95, weight_decay=0, mode='scale_invariant')` on blocks ndim≥2 |
| **Aux AdamW eps** | **`--aux_adamw_eps 1e-6`** (was hardcoded 1e-10) |
| MuonH inner AGC | `--muonh_agc_clip_ratio 0.05` |
| MuonH LR warmup | `--muonh_warmup_steps 100` |
| Outer wrapper | `MuLoCo(outer_lr=0.7, outer_momentum=0.5, sync_interval=30)` |
| Aux AdamW | `betas=(0.8, 0.95), eps=1e-6, weight_decay=0` + AGC `clip_ratio=0.05` |
| LR schedule | Cosine cooldown for MuonH (`cooldown_frac=1.0`); linear cooldown for aux (`cooldown_frac=0.4`) |
| `val/loss` | **3.27119** (n=1 trial; passes n=1 bar < 3.27206) |
| `speedrun/final_first_step_to_target` | **3100** (n=1; improves over baseline best 3125) |
| stat margin | `(3.28 - 3.27119) * sqrt(1) = 0.00881` ≥ 0.004 ✓ |
| Baseline W&B run | `t1coza71` |
| Baseline PR | [#443](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/443) |

### Reproduce Aux eps=1e-6 + AGC inner + MuonH warmup + cosine cooldown + AGC aux + MuLoCo × MuonH-SI baseline

```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6
```

---

## Previous baseline — PR #329 askeladd AGC on inner MuonH gradient (2026-05-18 ~18:26 UTC)

**Merged 2026-05-18 ~18:26 UTC — PR #329 askeladd AGC on inner MuonH gradient.** Applies Adaptive Gradient Clipping (`clip_ratio=0.05`) to the MuonH inner gradient path (before NS5 Newton-Schulz orthogonalization), in addition to the existing aux AGC. AGC is active on every block every step from warmup onward; the inner MuonH gradient RMS dwarfs parameter RMS by 2–4 orders of magnitude, making this a heavy but well-targeted intervention. Stacks on top of MuLoCo × MuonH-SI + aux AGC + cosine cooldown + LR warmup. All 4 n=4 trials reached the 3.28 target.

| Field | Value |
| --- | --- |
| `train_steps` | 3325 |
| Architecture | GPT-768/12L, vocab 50304, ctx 1024 — fixed |
| Batch size | `8 * 64 * 1024 = 524288` tokens/step — fixed |
| Main optimizer | `MuonH(lr=0.018, mu=0.95, weight_decay=0, mode='scale_invariant')` on blocks ndim≥2 |
| **MuonH inner AGC** | **`--muonh_agc_clip_ratio 0.05`** (clips inner gradient before NS5) |
| MuonH LR warmup | `--muonh_warmup_steps 100` (linear ramp over first 100 steps) |
| Outer wrapper | `MuLoCo(outer_lr=0.7, outer_momentum=0.5, sync_interval=30)` |
| Aux AdamW | `betas=(0.8, 0.95), eps=1e-10, weight_decay=0` + AGC `clip_ratio=0.05` |
| LR schedule | **Cosine** cooldown for MuonH (`cooldown_frac=1.0`); linear cooldown for aux (`cooldown_frac=0.4`) |
| `val/loss` | **3.27286** (n=4 mean; trials: 3.27209/3.27264/3.27365/3.27305) |
| `speedrun/final_first_step_to_target` | **3125** (best across n=4 trials; mean 3137.5) |
| stat margin | `(3.28 - 3.27286) * sqrt(4) = 0.01429` ≥ 0.004 ✓ |
| Baseline W&B runs | `dpabql6o` (n=4 multi-trial run) |
| Baseline PR | [#329](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/329) |

### Reproduce AGC inner + MuonH warmup + cosine cooldown + AGC aux + MuLoCo × MuonH-SI baseline

```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 4 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05
```

---

## Previous baseline — PR #310 thorfinn MuonH inner LR warmup (2026-05-18 ~10:31 UTC)

**Merged 2026-05-18 ~10:31 UTC — PR #310 thorfinn MuonH inner LR warmup.** 100-step linear warmup on MuonH-SI inner LR (only MuonH groups; aux AdamW unchanged). Stacks on top of MuLoCo × MuonH-SI + AGC + cosine cooldown. All 4 n=4 trials reached the 3.28 target. Passes stat rule with margin 0.01370 (3.4× margin).

| Field | Value |
| --- | --- |
| `train_steps` | 3325 |
| Architecture | GPT-768/12L, vocab 50304, ctx 1024 — fixed |
| Batch size | `8 * 64 * 1024 = 524288` tokens/step — fixed |
| Main optimizer | `MuonH(lr=0.018, mu=0.95, weight_decay=0, mode='scale_invariant')` on blocks ndim≥2 |
| **MuonH LR warmup** | **`--muonh_warmup_steps 100`** (linear ramp over first 100 steps) |
| Outer wrapper | `MuLoCo(outer_lr=0.7, outer_momentum=0.5, sync_interval=30)` |
| Aux AdamW | `betas=(0.8, 0.95), eps=1e-10, weight_decay=0` + AGC `clip_ratio=0.05` |
| LR schedule | **Cosine** cooldown for MuonH (`cooldown_frac=1.0`); linear cooldown for aux (`cooldown_frac=0.4`) |
| `val/loss` | **3.27315** (n=4 mean; trials: 3.27361/3.27308/3.27256/3.27333) |
| `speedrun/final_first_step_to_target` | **3125** (best across n=4 trials; mean 3143.75) |
| stat margin | `(3.28 - 3.27315) * sqrt(4) = 0.01370` ≥ 0.004 ✓ |
| Baseline W&B runs | `w6xgiqzl` (n=4 multi-trial run) |
| Baseline PR | [#310](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/310) |

---

## Previous baseline — PR #243 frieren MuonH-SI cosine cooldown (2026-05-18 ~01:20 UTC)

**Merged 2026-05-18 ~01:20 UTC — PR #243 frieren MuonH-SI cosine cooldown.** Replaces linear LR cooldown with cosine shape on the MuonH-SI optimizer path (`cooldown_frac=1.0`). Stacks on top of MuLoCo × MuonH-SI + AGC. All 4 n=4 trials reached the 3.28 target. Rebase-confirm n=1=3.27436 ✓. Passes stat rule with margin 0.01170.

| Field | Value |
| --- | --- |
| `train_steps` | 3325 |
| Architecture | GPT-768/12L, vocab 50304, ctx 1024 — fixed |
| Batch size | `8 * 64 * 1024 = 524288` tokens/step — fixed |
| Main optimizer | `MuonH(lr=0.018, mu=0.95, weight_decay=0, mode='scale_invariant')` on blocks ndim≥2 |
| Outer wrapper | `MuLoCo(outer_lr=0.7, outer_momentum=0.5, sync_interval=30)` |
| Aux AdamW | `betas=(0.8, 0.95), eps=1e-10, weight_decay=0` + AGC `clip_ratio=0.05` |
| LR schedule | **Cosine** cooldown for MuonH (`cooldown_frac=1.0`); linear cooldown for aux (`cooldown_frac=0.4`) |
| `val/loss` | **3.27415** (n=4 mean; trials: 3.27459/3.27306/3.27436/3.27460) |
| `speedrun/final_first_step_to_target` | **3150** (n=4 primary metric) |
| stat margin | `(3.28 - 3.27415) * sqrt(4) = 0.01170` ≥ 0.004 ✓ |
| Baseline W&B runs | `5ehqbmwb`, `xw81lpch`, `7z72ffcj`, `qupprvwc` (n=4), `47cp8wal` (rebase-confirm) |
| Baseline PR | [#243](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/243) |

### Reproduce cosine cooldown + AGC + MuLoCo × MuonH-SI baseline

```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 4 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05
```

---

## Previous baseline — PR #237 edward AGC aux clip=0.05 (2026-05-17 ~20:32 UTC)

**Merged 2026-05-17 ~20:32 UTC — PR #237 edward AGC aux clip=0.05.** Adaptive Gradient Clipping on aux AdamW parameter groups (`clip_ratio=0.05`). Stacks on top of MuLoCo × MuonH-SI. All 4 trials reached the 3.28 target. Passes stat rule with margin 0.01062.

| Field | Value |
| --- | --- |
| `train_steps` | 3325 |
| Architecture | GPT-768/12L, vocab 50304, ctx 1024 — fixed |
| Batch size | `8 * 64 * 1024 = 524288` tokens/step — fixed |
| Main optimizer | `MuonH(lr=0.018, mu=0.95, weight_decay=0, mode='scale_invariant')` on blocks ndim≥2 |
| Outer wrapper | `MuLoCo(outer_lr=0.7, outer_momentum=0.5, sync_interval=30)` |
| Aux AdamW | `betas=(0.8, 0.95), eps=1e-10, weight_decay=0` + **AGC `clip_ratio=0.05`** |
| LR schedule | Linear cooldown; `cooldown_frac=1.0` for MuonH, `0.4` for aux |
| `val/loss` | **3.27469** (n=4 mean; trials: 3.27382/3.27568/3.27408/3.27518) |
| `speedrun/final_first_step_to_target` | **3262** (n=4 mean; trials: 3250/3275/3250/3275) |
| stat margin | `(3.28 - 3.27469) * sqrt(4) = 0.01062` ≥ 0.004 ✓ |
| Baseline W&B runs | `efgqupvv`, `hzxm8aaj`, `9l9le6dc`, `pwbrxwez` |
| Baseline PR | [#237](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/237) |

### Reproduce AGC + MuLoCo × MuonH-SI baseline

```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 4 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05
```

---

## Previous baseline — PR #114 MuLoCo × MuonH-SI (2026-05-16 ~23:43 UTC)

**Merged 2026-05-16 ~23:43 UTC — PR #114 frieren MuLoCo × MuonH-SI.** Outer Nesterov SGD wrapper (MuLoCo) over MuonH-SI inner optimizer. Passes stat rule at n=4 with margin 0.0083. Consistent improvement across all 4 seeds: 3 of 4 trials individually beat the prior baseline mean.

| Field | Value |
| --- | --- |
| `train_steps` | 3325 |
| Architecture | GPT-768/12L, vocab 50304, ctx 1024 — fixed |
| Batch size | `8 * 64 * 1024 = 524288` tokens/step — fixed |
| Main optimizer | `MuonH(lr=0.018, mu=0.95, weight_decay=0, mode='scale_invariant', budget_mult=1.0)` on `model.blocks.parameters() if p.ndim >= 2` |
| Outer wrapper | `MuLoCo(outer_lr=0.7, outer_momentum=0.5, sync_interval=30)` — outer Nesterov SGD applied to all trainable params every 30 steps |
| Embed optimizer | `AdamW(lr=0.3)` on `model.embed.weight` |
| LM-head optimizer | `AdamW(lr=1/320)` on `model.proj.weight` |
| Scalar optimizer | `AdamW(lr=0.01)` on `p for p in model.parameters() if p.ndim < 2` |
| Aux AdamW shared | `betas=(0.8, 0.95), eps=1e-10, weight_decay=0` |
| Init | per-module: `attn.proj=0.026`, `mlp.proj=0.031`, `mlp.fc=0.031`; biases zero; gains 1 |
| LR schedule | Stable then linear cooldown; `cooldown_frac=1.0` for MuonH, `0.4` for aux AdamW |
| `val/loss` | **3.27585** (n=4 mean) |
| `speedrun/final_first_step_to_target` | **3275** (n=4 mean; trials: 3300/3275/3250/3275) |
| stat margin | `(3.28 - 3.27585) * sqrt(4) = 0.00830` ≥ 0.004 ✓ |
| Baseline W&B run | `22tmupqh` (n=4) |
| Baseline PR | [#114](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/114) |

**Key MuLoCo mechanism**: Every `sync_interval=30` steps, an outer Nesterov SGD step pulls all params toward the momentum-smoothed "drift" direction (`outer_lr=0.7, outer_momentum=0.5`). This acts as a second-level momentum on top of MuonH-SI's per-step Nesterov update — the outer step averages over the last 30-step trajectory rather than the last single step.

### Reproduce MuLoCo × MuonH-SI baseline

```bash
cd target/
pip install -r requirements.txt
python data/cached_fineweb10B.py 20
git checkout auto-nanogpt-1gpu-r3
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 4 --train_steps 3325 \
  --muonh_mode scale_invariant --muonh_lr 0.018 --muonh_budget_mult 1.0 \
  --muloco_use_outer_optimizer true --muloco_outer_lr 0.7 \
  --muloco_outer_momentum 0.5 --muloco_sync_interval 30 \
  --wandb_name "g1r3-<student>/muloco-muonh-si-baseline-confirm" \
  --wandb_group "g1r3-<student>/muloco-muonh-si-baseline"
```

## Previous baseline — PR #52 MuonH-SI (2026-05-16 ~08:40 UTC)

MuonH (Frobenius-ball + scale-invariant projection). Passed stat rule at n=4 with margin 0.00526. Superseded by PR #114.

| Field | Value |
| --- | --- |
| `train_steps` | 3350 |
| Main optimizer | `MuonH(lr=0.018, mu=0.95, wd=0, mode='scale_invariant', budget_mult=1.0)` |
| `val/loss` | 3.27737 (n=4 mean) |
| `speedrun/final_first_step_to_target` | 3275 (deterministic) |
| Baseline W&B run | `rwpbmxj7` (n=4) |
| Baseline PR | [#52](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/52) |

## Previous baseline — PR #51 NorMuon (2026-05-16 ~01:30 UTC)

NorMuon (1D post-NS row/col second-moment preconditioning). Passed stat rule at n=6 with margin 0.0050. Superseded by PR #52.

| Field | Value |
| --- | --- |
| `train_steps` | 3300 |
| Hidden optimizer | `NorMuon(lr=0.035, weight_decay=0.025, mu=0.95, beta2=0.95)` |
| `val/loss` | 3.27795 (n=6 mean) |
| `speedrun/final_first_step_to_target` | 3258 (n=6 mean; min 3225) |
| Baseline W&B runs | `8yocwc35` (n=4) + `40g9f47i` (n=2 top-up) |
| Baseline PR | [#51](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/51) |

## Previous baseline (pre-PR #51)

Plain Muon + aux AdamW (public result #12 equivalent). Val/loss ~3.279 at n=20, ffs ~3300. Starter script unmodified.

### Reproduce baseline

```bash
cd target/
pip install -r requirements.txt
python data/cached_fineweb10B.py 20
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py 1 \
  --wandb_name "$STUDENT_NAME/baseline-confirm" \
  --wandb_group "baseline"
```

## Strongest public records (track 3, bundled snapshot)

Public history from `records/track_3_optimization/README.md`. For ideas only —
each `results/<dir>/*.txt` log contains the full Python source needed to
reproduce. Some directories also include cleaned reference scripts
(e.g. `train_gpt_simple_muonh.py`, `train_gpt_simple_contra_muon_2.py`).

| # | Steps | Loss (n) | Description | Log dir |
| --- | --- | --- | --- | --- |
| 20 | 3030(!) | 3.2790 (n=30) | Contra-Muon + Soft-Muon interp + SOAP MLP + SOAP attn trust gate + tuned schedule | `20260509_contra_soft_muon/` |
| 19 | 3125 | 3.2780 (n=6) | KL-SOAP with hyperball, precond_freq=1 | `20260508_klsoap_h_clean_tuple_sweep/` |
| 16 | 3125(!) | 3.2784 (n=8) | #14 + SOAP precond for attention + trust gate | `20260506_trustlight/` |
| 14 | 3150(!) | 3.2776 (n=4) | Contra-Muon + SOAP-Muon for MLP | `20260504_contra_muon_mlp_soapish/` |
| 13 | 3210(!) | 3.2785 (n=10) | NorMuonH wrapped in MuLoCo-style outer Nesterov SGD | `20260504_muloco_normuonh/` |
| 11 | 3225(!) | 3.2785 (n=16) | NorMuon (#9 setup) + Contra-Muon | `20260501_contra_muon/` |
| 10 | 3250 | 3.2789 (n=20) | NorMuon lr=0.035 wd=0.025, end 50 steps early | `20260503_normuon/` |
| 9 | 3250(!) | 3.2771 (n=8) | NorMuon + u/w-floor, lr=.0375 | `20260501_skylight001/` |
| 8 | 3250 | 3.2778 (n=10) | NorMuonH + per-module init std | `20260430_normuonh/` |
| 7 | 3325 | 3.2752 (n=1) | Muon² with aux Adam, lr=.10 wd=.0125 | `20260501_muonsq/` |
| 5 | 3325(!) | 3.2782 (n=10) | MuonH (hyperball) + per-module init std | `20260430_muonh/` |
| 12 | 3325 | 3.2790 (n=20) | Plain Muon + aux Adam lr=.025 wd=.025 (= starter equiv) | `1bd8db7a-...txt` |
| 4 | 4875 | 3.2741 (n=5) | AdamH (hyperball-AdamW) + per-module init | `20260430_adamh/` |

### Useful per-100-step value gap

From the public README: lowering step count of result #12 by 200 steps moves
mean loss from 3.2790 (n=20) up to 3.2881 (n=8). That is ~0.0045 loss per 100
steps. So a method beating baseline by 0.001 in val loss is worth about
22 steps. Use this when ranking close results.

## Update policy

When a PR merges that beats this baseline on `speedrun/final_first_step_to_target`
at a satisfying step count and seed setup, update this file with the new
configuration (optimizer, lr, wd, schedule, init, train_steps) and the merged
PR/W&B run id.
