# Auto-NanoGPT R2 Baseline

**Last updated:** 2026-05-15

## Current best in this research programme (auto-nanogpt-r2)

_No validated runs yet — this is the boot state._

## Reference baseline (starter script as checked in)

`records/track_3_optimization/train_gpt_simple.py` ships with:

- Optimizers: Muon for `blocks.*` 2D weights (`lr=0.035`, `wd=0.025`, `mu=0.95`,
  Nesterov on) + AdamW for embed/proj/scalars
  (`adam_embed lr=0.3`, `adam_lm_head lr=1/320`, `adam_scalars lr=0.01`,
  `betas=(0.8, 0.95)`, `eps=1e-10`, `wd=0`).
- Init: `proj` weights zeroed; `embed` default normal; other weights
  `Normal(0, sqrt(0.33)/sqrt(fan_in))`; biases 0; RMSNorm gains 1.
- Schedule: stable then linear cooldown with `cooldown_frac=0.7`.
- `train_steps = 3350`.
- One forward-backward per optimizer step, batch = 8 * 64 * 1024 tokens.

This matches the public Muon-with-aux-Adam setup from track 3 PR #12 (3325
steps + 25-step safety margin).

## Public track-3 SOTA we are trying to beat

The strongest result in
`records/track_3_optimization/README.md` (the snapshot we are running
against) is:

| Rank | Steps | mu (n) | Description |
| - | - | - | - |
| #20 | **3030** | 3.27901 (n=30) | Contra-Muon → Soft-Muon stack with NorMuon-lite row/col preconditioning, u/w floor, MLP+V SOAP preconditioning, power-law cooldown, `lr=0.0375`, `u/w-floor=0.35`. Reference logs in `records/track_3_optimization/results/20260509_contra_soft_muon/`. |
| #16 | 3125 | 3.2784 (n=8) | TrustLight: SOAP-MLP + attn.proj SOAP with trust gate + Contra-Muon. Reference script: `records/track_3_optimization/results/20260506_trustlight/train_gpt_simple_trustlight.py`. |
| #19 | 3125 | 3.2780 (n=6) | KL-SOAP with hyperball, precondition_frequency=1, `lr=.018`, `beta1=.95`, `beta2=.9`, `shampoo_beta=.9`. |
| #14 | 3150 | 3.2776 (n=4) | Contra-Muon + SOAP-MLP. Reference script: `records/track_3_optimization/results/20260504_contra_muon_mlp_soapish/train_gpt_contra_normuon_soapish_mlp.py`. |
| #13 | 3210 | 3.2785 (n=10) | MuLoCo-wrapped NorMuonH. Reference script: `records/track_3_optimization/results/20260504_muloco_normuonh/train_gpt_simple_muloco_normuonh.py`. |
| #11 | 3225 | 3.2785 (n=16) | NorMuon u/w-floor + Contra-Muon. Reference script: `records/track_3_optimization/results/20260501_contra_muon/train_gpt_simple_contra_muon_2.py`. |
| #5  | 3325 | 3.2782 (n=10) | MuonH (Muon + hyperball constraint) + per-module init std. Reference script: `records/track_3_optimization/results/20260430_muonh/train_gpt_simple_muonh.py`. |

## Statistical significance rule

For `n` non-cherry-picked runs at a predeclared step count, mean validation
loss `mu` must satisfy `(3.28 - mu) * sqrt(n) >= 0.004`.

| n | required mu |
| - | - |
| 1 | < 3.2760 |
| 4 | < 3.2780 |
| 8 | < 3.27859 |
| 16 | < 3.27900 |
| 30 | < 3.27927 |

## Primary metric

- `speedrun/final_first_step_to_target` (lower is better; `-1` = did not
  reach target).
- Secondary: `val/loss` at the predeclared terminal step, mean across seeds.

## Conventions used in this programme

- Final claims require all seeds reported at a single predeclared step
  count, no per-run val-loss-based stopping or seed picking.
- Optimizer code is inlined in the training script (no third-party optimizer
  packages for final claims).
- Default group: `auto-nanogpt-r2`. W&B project:
  `wandb-applied-ai-team/modded-nanogpt-senpai`. Tag: `auto-nanogpt-r2`.
