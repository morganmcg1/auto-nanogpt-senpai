# Modded-NanoGPT Track 3 Optimizer Speedrun — Local Baseline

Primary metric: `speedrun/final_first_step_to_target` (lower is better, `-1` means
target not reached).
Target: FineWeb validation cross-entropy `<= 3.28`.
Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.

## Local baseline (auto-nanogpt-1gpu-r1)

### 2026-05-15 — PR #68: Aurora + Contra-Muon + u/w floor (g1r1-tanjiro)

- **speedrun/final_first_step_to_target:** 3175
- **val/loss:** 3.274438 (margin +0.005562 ≥ 0.004 ✓, n=1)
- **W&B run:** `lg4xdlkt`
- **Key config:** Muon lr=0.0375, weight_decay=0, Aurora pp_iterations=2 pp_beta=0.5, CONTRA_COEFF=0.2, TARGET_UW=0.35, train_steps=3250, cooldown_frac=0.7
- **Reproduce:**
  ```bash
  cd target
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
    records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
    --wandb_name "g1r1-tanjiro/aurora-contra" \
    --wandb_group "g1r1-tanjiro/aurora"
  ```
- **Notes:** n=1 single-trial result; margin clears the 0.004 floor. Matches public Record #17 mechanism (3175 steps, n=20 mean 3.2789). `sample_tensor` linspace fp32 bug patched (`.clamp_(max=values.numel()-1)`). Full Aurora + Contra-Muon + Skylight u/w floor variant confirmed locally.

Prior to first winner: local anchor was unconfirmed (alphonse vanilla run diverged).

## Public records to beat (track 3 official, snapshot in repo)

These are the strongest known public results, included here as target
references. Our portfolio aims to reproduce the mechanisms and combine them.

| Rank | Steps to 3.28 | Mean val_loss | n | Method | Key levers |
| ---- | ------------- | ------------- | - | ------ | ---------- |
| #20 | 3030 | 3.2790 | 30 | Contra-Muon + Soft-Muon + SOAP-MLP + SOAP-attn trust gate + NorMuon-lite + u/w floor + power-law cooldown | All-in stack |
| #19 | 3125 | 3.2780 | 6 | KL-SOAP-H (full SOAP replacing NS, beta1=0.95, shampoo_beta=0.90) | lr=0.018 |
| #16 | 3125 | 3.2784 | 8 | NorMuonH + SOAP-MLP + SOAP-attn trust gate (Trustlight) | lr=0.0375 |
| #14 | 3150 | 3.2776 | 4 | Contra-Muon + NorMuon + SOAP-MLP | lr=0.0375 |
| #17 | 3175 | 3.2789 | 20 | Aurora + Contra-Muon + u/w floor | lr=0.0375 |
| #13 | 3210 | 3.2785 | 10 | MuLoCo (outer Nesterov) + NorMuonH | sync_interval=30 |
| #11 | 3225 | 3.2785 | 16 | Contra-Muon + NorMuon + u/w floor | lr=0.0375 |
| #18 | 3225 | 3.2776 | 9 | PMuon (streaming covariance preconditioning) | lr=0.035, gamma=0.3 |
| #9  | 3250 | 3.2771 | 8 | Skylight (NorMuon long-axis + u/w floor) | lr=0.0375 |
| #10 | 3250 | 3.2789 | 20 | NorMuon (short-axis) | lr=0.035 wd=0.025, end 50 early |
| #8  | 3250 | 3.2778 | 10 | NorMuonH (short-axis NorMuon + hyperball) | lr=0.018 |
| #6  | 3375 | 3.2788 | 20 | Muon + aux Adam | lr=0.025 wd=0.025 |
| #12 | 3325 | 3.2790 | 20 | Muon + aux Adam, lr=0.035 wd=0.025, end 25 early | similar to #10 |

## Common-to-all configuration (do not change)

- Dataset: FineWeb shards loaded by `data/cached_fineweb10B.py`.
- Architecture: `vocab_size=50304, num_layers=12, model_dim=768`, head_dim=128.
- Batch size: `8 * 64 * 1024 = 524288` tokens per optimizer step.
- One forward-backward per optimizer step.
- AdamW auxiliary groups (embed lr=0.3, lm_head lr=1/320, scalars lr=0.01,
  betas=(0.8, 0.95), eps=1e-10, wd=0).
- Newton-Schulz iterations: 12 (quintic a=2, b=-1.5, c=0.5).
- Schedule: stable then linear cooldown with `cooldown_frac=0.7` unless an
  experiment specifies otherwise.
- Per-run early stopping based on val loss is forbidden.

## Important gotcha

`MUON_WEIGHT_DECAY=0.025` appears in param groups but the baseline `Muon.step`
does not consume it — effective Muon weight decay is 0. If a hypothesis depends
on weight decay being applied, add the `p.mul_(1 - lr*wd)` line explicitly.
