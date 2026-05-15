# Auto-nanoGPT Optimizer Speedrun Target

This repository is a Senpai target package for the `modded-nanogpt` track 3
optimization benchmark. It is not a physical AI or CFD task.

## Mission

Find optimizer, schedule, initialization, and optimizer-hyperparameter changes
that reduce the number of optimizer steps needed for the fixed nanoGPT training
setup to reach FineWeb validation cross-entropy loss below `3.28`.

The primary objective is lower `speedrun/final_first_step_to_target`, where
`-1` means the run never reached the target. Validation loss is lower-is-better,
but final claims must use the benchmark's statistical rule:

```
(3.28 - mu) * sqrt(n) >= 0.004
```

Here `mu` is the mean validation loss across `n` non-cherry-picked runs at the
same chosen step count. For example, a single run needs loss below `3.276`; four
runs need an average below `3.278`.

The checked-in public track history and `records/` directory are useful
context, but the research goal is to keep improving from the strongest known
benchmark evidence rather than merely beating the starter script.

## Benchmark Contract

Keep the benchmark equivalent to track 3:

- Keep the dataset fixed to FineWeb token shards loaded by the existing data
  scripts.
- Keep the model architecture fixed.
- Keep the batch size fixed.
- Do not add multiple forward-backward passes per optimizer step.
- Do not use per-run early stopping or val-loss peeking to cherry-pick seeds.
- Include all optimizer code needed to reproduce a run directly in the training
  script or PR. Do not depend on third-party optimizer packages for final
  benchmark claims.

Allowed research levers:

- Optimizer algorithm.
- Optimizer hyperparameters and schedules.
- Learning-rate, momentum, weight-decay, and cooldown schedules.
- Model initialization.
- Validation/logging telemetry that does not change the benchmark semantics.

Do not let the research collapse into only learning-rate and weight-decay
hill-climbing. Exploitation matters, especially when retuning a new method, but
the biggest wins are likely to come from fresh optimizer mechanisms, clever
preconditioners, schedule ideas, parameterization tricks, and principled
ablations of complex stacks.

## Codebase

- `records/track_3_optimization/train_gpt_simple.py` - primary editable
  training script for track 3 experiments.
- `records/track_3_optimization/README.md` - official optimization benchmark
  rules, history, and guidance. Treat as read-only unless correcting local
  target-package documentation.
- `records/track_3_optimization/results/` - historical logs and scripts. Read
  for ideas and baselines; do not edit normal experiment PRs.
- `data/cached_fineweb10B.py` - downloads FineWeb token shards. Read-only
  during normal optimizer experiments.
- `data/fineweb.py` and cached shard files - data pipeline and data. Read-only.
- `requirements.txt` - runtime dependencies. Add packages only when a PR truly
  requires them.
- `program.md`, `instructions/prompt-advisor.md`,
  `instructions/prompt-student.md` - Senpai target contract and role prompts.
  Read-only during normal experiment PRs.

## Running

Use the same structure as the public speedrun quickstart, with W&B args added.
Install dependencies, prepare the default token cache, then launch `torchrun`:

```bash
pip install -r requirements.txt
python data/cached_fineweb10B.py 20
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/<short-description>" \
  --wandb_group "<hypothesis-or-pr>"
```

On Senpai pods, `python data/cached_fineweb10B.py 20` automatically uses the
shared PVC cache at `$PVC_MOUNT_PATH/datasets/fineweb10B` when the PVC is
mounted. It symlinks that cache to `data/fineweb10B`, so the `torchrun` command
stays identical to the public benchmark command apart from the W&B flags.

The script remains backward-compatible with the public benchmark's positional
trial count:

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py 4
```

## W&B Metrics

The starter script logs rich telemetry on rank 0:

- `val/loss` - FineWeb validation cross-entropy.
- `speedrun/first_step_to_target` - earliest validation event in the run with
  `val/loss <= 3.28`, or `-1` if not reached yet.
- `speedrun/final_first_step_to_target` - final value of the previous metric.
- `speedrun/final_best_val_loss` and `speedrun/final_best_val_step`.
- `val/target_margin` and `val/single_run_stat_sig_margin`.
- `train/loss` - training cross-entropy for the just-completed optimizer step.
- `train/slope/loss_per_step` and `train/slope/loss_per_100_steps` - least
  squares training-loss slope over the trailing 10% of total steps, logged at
  every 10% of the run and at the final step.
- `val/slope/loss_per_step` and `val/slope/loss_per_100_steps` - matching
  validation-loss slope at validation events when enough points are available.
- `train/lr/*` and `train/weight_decay/*` - optimizer group schedules.
- `train/grad/global_norm`, `train/grad/rms`, `train/grad/max_abs`, and
  `train/grad/grad_to_weight_norm` - high-level gradient health aliases.
- `train/weight/global_norm`, `train/weight/rms`, and `train/weight/max_abs` -
  high-level parameter health aliases.
- `train/grad/all/*`, `train/grad_type/*`, and `train/grad_param/*` - gradient
  norms, RMS, mean, mean absolute value, standard deviation, extrema,
  zero-fraction, and non-finite counts.
- `train/weight/all/*`, `train/weight_type/*`, and `train/weight_param/*` -
  matching parameter statistics after optimizer updates.
- `train/grad_hist/*` and `train/weight_hist/*` - sampled aggregate and large
  parameter histograms.

Use the telemetry to understand failures and interactions. Preserve or extend
these metric names when possible so the advisor can compare runs across PRs.

## Experiment Length

The launch limits are hard ceilings, not recommended run lengths. This
benchmark is step-count based, so choose `train_steps` inside the training
script according to the evidence needed:

- Tiny debug runs: verify code, memory, W&B logging, and finite gradients.
- Short screening runs: tune uncertain optimizer-specific hyperparameters.
- Longer confirmation runs: evaluate promising ideas at a predeclared step
  count and seed count.

When screening, shorter runs can be useful even if they do not reach 3.28, but
do not kill promising schedules before the cooldown can matter. For final
claims, choose the step count before running the seed batch and report all
non-cherry-picked runs at that step.

Early kill gates are acceptable for obvious crashes, non-finite losses,
exploding gradients, or hopeless debug runs. They are not acceptable as a way to
select the best validation step per seed.

## Results Contract

Student result comments must include a single-line marker:

```markdown
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<run-id>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<steps_or_minus_one>},"test_metric":{"name":"val/loss","value":<loss>}}
```

Also report:

- Exact command used.
- W&B run IDs.
- Step count, number of seeds/trials, mean validation loss, and statistical
  margin.
- Whether the result satisfies `(3.28 - mu) * sqrt(n) >= 0.004`.
- Any changes to optimizer, schedules, initialization, or hyperparameters.
- Known caveats and suggested follow-ups.

## Advisor Guidance

Assign one hypothesis per PR. Keep a balanced portfolio:

- Build directly on the strongest public and in-repo records.
- Spend part of the portfolio exploiting strong records through retuning and
  cleanup, but reserve serious capacity for new optimizer techniques and
  mechanisms. A wave of only scalar hyperparameter tweaks is too conservative.
- Retune learning rate and weight decay when testing a new optimizer idea; this
  is support work for a technique, not a substitute for technique search.
- Run pruning/removal experiments when a stack accumulates components.
- Periodically refresh upstream PRs and records for new public optimizer ideas.
- Reserve some capacity for genuinely new optimizer mechanisms, but require the
  same fixed benchmark contract and statistical reporting.
- Do not mine Prime Intellect's released autonomous-run scratchpads, run
  archive, or blog-post recipe summaries as direct implementation sources for
  this launch. They are useful external comparison material after the run, but
  the active research loop should use the public benchmark repo, upstream public
  PRs, papers/blogs about optimizer ideas, and its own Senpai run history.

The target is not complete when a run beats a previous baseline. A new best
result should immediately become the base for the next wave.
