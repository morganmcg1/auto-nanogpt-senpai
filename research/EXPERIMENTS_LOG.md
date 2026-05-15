# SENPAI Research Results — auto-nanogpt-1gpu-r3

Per-PR record of experiment outcomes. New entries prepended (newest first).
Each entry summarizes the hypothesis, the result(s), and the conclusion that
drives the next-wave assignment.

---

## 2026-05-15 15:35 — Wave 1 in-flight snapshot (no merges yet)

Wave 1 launched at ~12:35 UTC. By ~15:35 UTC the following observations:

### PR #51 g1r3-alphonse — NorMuon (Muon NS + Adafactor row/col precond)
- 4 smoke runs all finish at step 300 with `val/loss = NaN`.
- Root cause: assignment spec had an EMA bug
  (`row_var.add_(g², alpha=1-beta2)` without `.mul_(beta2)` first → row/col
  variances accumulate monotonically, producing zero entries in `precond`
  for dead rows/cols → `1/sqrt(1e-30)` blowup).
- **Sent**: corrected EMA spec + rebase pointer + kill gates + step budget.
- Awaiting rerun.

### PR #52 g1r3-askeladd — MuonH + per-module init std
- Smoke clean. `train/muonh/active_fraction = 0.944–1.000` confirms clip
  fires on ~99% of hidden tensors every step.
- `norm_to_radius_max = 1.00002–1.00689` — projection is doing real work.
- Independently caught `sample_tensor` OOB-index bug; clean writeup; fix
  cherry-picked into advisor branch (commit cc1c710).
- **Sent**: ack of clip-only-vs-always-active decision + rebase pointer.
- Screening 3350-step run in flight.

### PR #53 g1r3-edward — Contra-Muon
- Screen run `g1r3-edward/contra-muon-screen-s0` reached `val/loss = 3.281`
  at step 3350 (single seed; misses `< 3.28` line by 0.001).
- Independently caught `sample_tensor` OOB-index bug.
- **Sent**: rebase pointer; proceed to `train_steps=3225 × --num_trials 4`
  confirmation; if no clear, sweep `contra_alpha ∈ {0.25, 0.5, 0.75}`.
- Awaiting confirmation run.

### PR #54 g1r3-fern — SOAP-on-MLP precond before Muon NS
- Smoke runs NaN by step 20–140 across multiple versions.
- Likely root cause: assignment spec underspecified `_matrix_power`
  numerical stability + no preconditioner warmup (first refresh at step 32
  hits the run with a sharp ill-conditioned precond).
- **Sent**: defensive `_matrix_power` (symmetrize + relative+absolute eigval
  clamp), 50-step precond warmup (use plain `g` for first 50 steps), float64
  preconditioner state, eigenvalue telemetry, kill gates.
- Awaiting rerun.

### PR #55 g1r3-frieren — MuLoCo outer Nesterov around plain Muon
- Screen `g1r3-frieren/muloco-outer-screen-s0` at step 3125 with
  `val/loss = 3.300`. Run still has ~225 steps to go.
- Run looks healthy; loss converging on target. No advisor action needed
  this iteration.

### PR #56 g1r3-nezuko — Lion replacing AdamW + Muon everywhere
- LR sweep `g1r3-nezuko/lion-everywhere-lr-sweep` at step 2100 with
  `val/loss = 5.37`. Far from target.
- Lion at this scale doesn't appear competitive; expect to close as a
  negative-result PR once the LR sweep finishes.
- No advisor action this iteration — let the screen run complete so we have
  the full 4-arm LR signal before closing.

### PR #57 g1r3-tanjiro — Per-module init std on plain Muon
- Screen run `g1r3-tanjiro/per-module-init-screen-s0` finished at step 3350
  with `val/loss = 3.2858` (`speedrun/final_first_step_to_target = -1`,
  i.e. target not reached).
- 1-seed result is consistent with baseline expectation (~3.279 from public
  #12) within noise — per-module init alone is **not a step-count lever**
  for plain Muon at our scale.
- Awaiting student to post terminal results and SENPAI-RESULT marker.
- Likely outcome: close PR (no improvement) and route the per-module init
  forward as a free-rider on the next algorithmic winner.

### PR #58 g1r3-thorfinn — Cooldown shape × cooldown_frac sweep
- Blocked by 1-GPU plain-Muon NaN instability: starter NaNs by step 25
  (with `@torch.compile`) or step 1525 (without). Cooldown change is not
  the root cause; pre-existing instability of plain Muon at 1 GPU.
- Student also caught `sample_tensor` OOB bug — third independent report.
- Student requested guidance before burning ~30h compute.
- **Sent**: accept warmup option (100-step linear LR warmup applied to all
  12 arms identically, preserving the cooldown-shape isolation); rebase
  pointer; hard kill gates (≥3 NaN arms → stop the sweep); hold
  confirmation until I review the screening table.
- Awaiting screening sweep.

### Operational learnings this iteration

- **`sample_tensor` OOB-index** in the starter telemetry was a real
  starter-code bug (float32 linspace endpoint overshoots for `n > 2^24`).
  Caught independently by 3 students. Cherry-picked into advisor branch
  as commit cc1c710 so wave 2 inherits a clean starter.
- **Plain Muon at world_size=1 with default init is NaN-unstable.** Every
  successful 1-GPU run in W&B uses either non-default init (smaller std)
  or an adaptive preconditioner (NorMuon, SOAP, MuonH). Operational rule
  for any future plain-Muon 1-GPU run: add a 100-step LR warmup.
- **My NorMuon and SOAP assignments had bugs.** Both have been corrected
  in PR comments. Future assignments should reference canonical
  reference impls in `records/track_3_optimization/results/<date>_<name>/`
  more explicitly — at minimum quote line ranges from the reference logs.
