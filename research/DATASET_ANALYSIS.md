# Dataset & Benchmark Notes — Track 3 Optimizer Speedrun

This is **not** a CFD/physical AI dataset. It is the modded-nanogpt track-3
optimization benchmark on FineWeb tokens. We summarize the fixed contract here
so first-principles thinking about the optimizer landscape stays grounded.

## Data

- **Corpus**: FineWeb 10B-token shards loaded via `data/cached_fineweb10B.py`.
  Default download is 20 chunks ≈ 4B tokens, enough for up to ~7600 training
  steps at the current batch size. Validation slice is 20 × 524288 = 10.49M
  tokens held out as `fineweb_val_*.bin`.
- **Batch size**: `batch_size = 8 * 64 * 1024 = 524288` tokens per optimizer
  step; `mbs = 64` sequences per microbatch, sequence length 1024 (from how
  inputs/targets are sliced). Fixed by contract.
- **One forward-backward per optimizer step**: contract forbids
  gradient accumulation tricks. Loss is summed cross-entropy averaged by
  `batch_size` for telemetry.

## Model

- **GPT**: `vocab_size=50304`, `num_layers=12`, `model_dim=768`. RMSNorm gains,
  Linear biases enabled, causal attention over a fixed 1024-token context,
  rotary positions, no value embeddings or learnable skip lambdas. Fixed by
  contract.
- **Logit squash**: final logits use `15 * x / sqrt(x^2 + 225)`. This is part
  of the architecture and should not be removed.
- **Initialization** is editable: by default `proj` weights zero-init, embed
  default normal, all other weights `N(0, sqrt(0.33)/sqrt(fan_in))`, biases
  zero, RMSNorm `gains` initialized to 1.

## Optimizer surface

- **Muon block params** (12 transformer blocks, qkv / proj / fc / weight in
  `ndim>=2`): lr=0.035, wd=0.025, mu=0.95, 12 Newton–Schulz iterations with
  fixed (a,b,c) = (2, -1.5, 0.5), bfloat16 NS, scaled by
  `max(1, fan_in/fan_out)**0.5`. Distributed via gather across ranks.
- **AdamW aux groups** (embed lr=0.3, lm_head lr=1/320, scalar params lr=0.01,
  betas=(0.8, 0.95), eps=1e-10, wd=0): handles embedding, output projection,
  and `ndim<2` scalar params (norm gains, biases). Fused AdamW.
- **Schedule**: `set_hparams(step)` linearly decays each group's lr from
  `initial_lr` over the last `cooldown_frac=0.7` of training.

## Metric levers worth pulling

Available without breaking the benchmark contract:

- **Optimizer algorithm**: replace Muon and/or aux Adam with anything that uses
  one forward-backward per step.
- **Optimizer hyperparameters and their schedules**: lr, momentum (`mu`),
  betas, eps, weight decay, NS iter count and coefficients, cooldown fraction,
  schedule shape (cosine/wsd/trapezoid/restarting/Polyak), aux/main group split.
- **Initialization**: per-module std (e.g. MuonH's per-proj/fc/mlp init),
  alternative spectral inits, mup/μ-transfer width-scaled init.
- **Preconditioning**: SOAP (Shampoo eigen on grads then Adam), KL-SOAP,
  hyperball constraint, NorMuon's Adafactor row/col precond, PMuon's bilateral
  streaming covariance, activation-covariance right-precond (Newton-Muon),
  Aurora, signSGD-Muon, Lion.
- **Outer-loop wrappers**: MuLoCo (outer Nesterov), Polyak/EMA averaging, SWA,
  Lookahead. Each requires the same single fwd-bwd per inner step.
- **Statistical rule**: predeclare step count, run multiple seeds before
  inspecting val loss, never per-run early-stop on val.

## Telemetry available

`val/loss`, `speedrun/first_step_to_target`,
`speedrun/final_first_step_to_target`, `train/loss`,
`train/slope/loss_per_step`, `val/slope/loss_per_step`, per-group lr/wd,
gradient/weight norm aliases, per-type and per-param gradient/weight stats and
histograms, optimizer-specific diagnostics. Extend (don't break) these when
adding a new mechanism.
