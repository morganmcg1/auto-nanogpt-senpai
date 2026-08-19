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
- `eval/trial_results` - one row per completed seed with its final and best
  validation losses, selected steps, and first target crossing.
- W&B config records the authoritative group, evaluation trial index and seed,
  wall-clock limit, exact source and Git revisions, shard names and sizes, and
  the fixed metric contract.
- A run is ranking-eligible only when it consumes and validates exactly
  `fineweb_train_000001.bin` through `fineweb_train_000020.bin` and
  `fineweb_val_000000.bin`; every shard has the benchmark header, 100 million
  tokens, and exact byte size; every configured seed reaches the target; and
  the recomputed fixed-step mean passes the statistical rule.

Use the telemetry to understand failures and interactions. Preserve or extend
these metric names when possible so the advisor can compare runs across PRs.

## Experiment Length

The launch limits are hard ceilings, not recommended run lengths. This
benchmark is step-count based, so choose `train_steps` inside the training
script according to the evidence needed:

`SENPAI_TIMEOUT_MINUTES` must be positive and finite. Every rank arms a process
watchdog and exits with status 124 at that wall-clock limit. The outer Senpai
supervisor remains the authoritative process-group cutoff.

When the evaluation harness sets `WANDB_RUN_GROUP`, it overrides
`--wandb_group`. `SENPAI_TRIAL_INDEX` identifies the parallel evaluation branch,
and `SENPAI_TRIAL_SEED` sets and records its reproducible seed. Leave
`--num_trials` at `1` for a harness trial. A scored run must
execute from a clean committed worktree, and the submitted result commit must
equal its W&B `git_commit`. Put any later cleanup in a separate PR.

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

Submit the terminal result through Senpai's typed `submit_experiment_result`
workflow. Report:

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
- Use the benchmark snapshot present in this repository. Do not refresh,
  browse, fetch, or mine new upstream PRs, branches, records, issues, or
  post-launch updates during this run.
- Reserve some capacity for genuinely new optimizer mechanisms, but require the
  same fixed benchmark contract and statistical reporting.
- The following Prime Intellect sources are explicitly banned for agents during
  this launch. Do not open, fetch, browse, search within, clone, cite, summarize,
  or use them for implementation ideas:
  `https://www.primeintellect.ai/auto-nanogpt`,
  `https://github.com/PrimeIntellect-ai/experiments-autonomous-speedrunning`,
  and any raw GitHub URLs, files, branches, issues, pull requests, or archives
  under that repository. They are external comparison artifacts for humans after
  the run, not part of the active experimental context.

The target is not complete when a run beats a previous baseline. A new best
result should immediately become the base for the next wave.
