# SENPAI Research Results — auto-nanogpt-1gpu-r3

Per-PR record of experiment outcomes. New entries prepended (newest first).
Each entry summarizes the hypothesis, the result(s), and the conclusion that
drives the next-wave assignment.

---

## 2026-05-15 19:05 — Wave 1 fern PR #54 root-cause checkpoint

Fern delivered a clean root-cause analysis of the SOAP NaN. Headline:
**SOAP-MLP-Muon code is correct**; the NaN cascade originates upstream of
SOAPMuon, in plain Muon at default init on 1 GPU. This matches the
operational pattern we already had: every plain-Muon-on-1-GPU run on this
branch NaNs unless an experimental clamp / smaller init / preconditioner
is in place.

### What fern proved (W&B runs `dlv7rkck`, `tce8dakn`, `zoqo0l97`)

| Step | `train/loss` | `grad/global_norm` | `grad/all/nonfinite_count` |
| --- | --- | --- | --- |
| 1 | 10.826 | **235,491** | 0 |
| 25 | NaN | 0 | **147,758,208** (≈100%) |
| 50 | NaN | 0 | 148,010,880 |

Three isolation runs reproduce the same signature:
- v4 with full SOAPMuon (`dlv7rkck`) — NaN by step 125, all 24 attempted
  eigh refreshes silently caught (warmup gate kept SOAP off till step 50).
- Split params, plain Muon on both groups (`tce8dakn`) — NaN by step 25.
- Single Muon on all block params (baseline-equivalent) (`zoqo0l97`) — NaN
  by step 25, identical 147M nonfinite-grad signature.

Fern's cross-reference: matches alphonse's PR #59 on `auto-nanogpt-1gpu-r1`
which root-caused a `torch.compile` Inductor kernel-emission bug producing
NaN in `blocks.0.attn.proj.bias.grad` at step 1, then propagating via
`dist.all_reduce(SUM)` to every rank and through Muon's NS matmuls to all
params by step ~25.

### Stable counter-example on our branch

`g1r3-tanjiro/per-module-init-screen-s0` runs plain Muon at 1 GPU with
**per-module init std** (no LR warmup, no compile change, no internal
clamp). It trained 3350 steps stably to `val/loss = 3.2858`. Compared to
fern's three NaN-by-step-25 runs, the only differentiator is the init.

### Conclusion + operational rule

**Per-module init std is mandatory for any plain-Muon-on-1-GPU experiment
on this branch.** Specifically:
- `attn.proj.weight.std = 0.026`
- `mlp.proj.weight.std = 0.031`
- `mlp.fc.weight.std = 0.031`
- (qkv stays at the current default, proj weights stay zero-initialized
  as in the starter)

This supersedes my earlier "add 100-step LR warmup" rule — warmup alone
doesn't fix it (thorfinn's warmup-100 also failed at step 3).

### Advisor action on PR #54

- Reset label `status:review → status:wip` (PR is asking a question, not
  proposing a merge).
- Sent: apply per-module init std on top of v2 SOAPMuon; re-run smoke v5
  at 300 steps. Fallback if smoke still NaNs: disable `@torch.compile` on
  `train_step` (justifiable since the comparison axis is step count, not
  wallclock).
- Declined: `nan_to_num` mask before `all_reduce` (two reasons — masks a
  real numerical failure mode for SOAP-specific bugs; and the right-layer
  fix is init).

### What this means for other PRs

- **thorfinn #58** (cooldown sweep): my prior advice was Smoke A
  (per-module init only) and Smoke B (init + warmup) before the 12-arm
  sweep. The operational rule now strengthens this — Smoke A IS the path,
  warmup is a secondary lever.
- **alphonse #51** (NorMuon, after EMA fix): NorMuon's row/col variance
  preconditioner inherently damps NaN-tinged gradients (1/sqrt(var)
  collapses toward zero on a NaN row), so it may run without per-module
  init. The new `confirm3300` run is at step ~25 — let it reach step 300+
  before deciding.
- **frieren #55** (MuLoCo): the screen ran cleanly — either MuLoCo's
  outer Nesterov averaging masks the upstream NaN, or frieren got a
  lucky seed. n=4 confirmation will surface intermittent failures.
- **askeladd #52, edward #53**: both screens ran cleanly without
  per-module init — their experimental code (MuonH clip, Contra-Muon
  coordinated update) effectively damps the cascade.

---

## 2026-05-15 18:35 — Wave 1 second-checkpoint snapshot

Roughly 6 hours into wave 1 (launched ~12:35 UTC). W&B audit of all 8 PRs.
Headline: **frieren MuLoCo** is the first PR with a clean target-reaching
single-seed run, but `ffs=3325` is not yet a statistical winner so it's in
n=4 confirmation. **askeladd MuonH** screen finished sub-target.
**nezuko Lion** is a confirmed dead end and being asked to close.

### PR #51 g1r3-alphonse — NorMuon (after EMA fix)
- New run `g1r3-alphonse/normuon-clean-confirm3300` launched at ~16:26 UTC,
  currently step ~25 with initial loss (10.83) — too early to read.
- Prior smoke runs (pre-EMA-fix) all NaN at step 300; the latest one is
  `normuon-impl-smoke-canonical`, finished NaN, confirming the bug
  signature.
- **Advisor action this iteration**: none — let the corrected rerun reach
  step 300+ before assessing.

### PR #52 g1r3-askeladd — MuonH clip-only
- Screen `g1r3-askeladd/muonh-hyperball-screen-s0` finished at step 3350
  with `val/loss = 3.2917`, `ffs = -1`. **Did not reach target.**
- Public #5 (always-active variant + per-module init, n=10) hit
  `val=3.2782, ffs=3325`. Our clip-only n=1 missed by ~0.014 in val and
  the target line entirely.
- Diagnosis: clip-only damps norms back to `R` (active_fraction ~0.99) but
  doesn't actively pull them below `R` like `scale_invariant_update_`; no
  per-module init compounds the miss.
- **Sent**: Option 1 — budget_mult ∈ {0.85, 1.0, 1.15} sweep + per-module
  init; Option 2 — always-active variant + per-module init. Run Option 1
  first (cheaper).

### PR #53 g1r3-edward — Contra-Muon
- 4-seed confirmation `g1r3-edward/contra-muon-confirm-3225-n4` launched
  at ~16:26 UTC, currently step 1 (initial loss). In flight.
- Prior screen had landed at `val=3.2808, ffs=-1` (n=1 miss by 0.0008).
- **Advisor action this iteration**: none — let confirmation run.

### PR #54 g1r3-fern — SOAP-on-MLP precond before Muon NS
- Latest g1r3-fern run `soap-mlp-smoke` still NaN at step 200 even after
  the corrected `_matrix_power` + 50-step precond warmup + float64 state.
- Two fresh smoke launches running: `soap-mlp-smoke-v4` (just started),
  `g1r2-fern/contra-soap-mlp-smoke-fix` (just started).
- **Advisor action this iteration**: none — give the new smokes a chance.
  If both NaN, escalate with float64-precision eigenvalue traces.

### PR #55 g1r3-frieren — MuLoCo outer Nesterov around plain Muon
- Screen `g1r3-frieren/muloco-outer-screen-s0` **finished** at step 3350:
  `val/loss = 3.2793`, **`ffs = 3325`** (reached target).
- n=1 result doesn't satisfy the statistical rule
  (`(3.28 - 3.2793) * sqrt(1) = 0.0007 < 0.004`), and `ffs=3325` is
  slightly worse than the public #12 plain-Muon expectation (~3300).
- **Sent**: n=4 confirmation at `train_steps=3300`; if mean misses, sweep
  `outer_lr ∈ {0.5, 0.7, 1.0}` × `outer_momentum ∈ {0.3, 0.5, 0.7}` at n=1
  before re-confirming. Public #13 NorMuonH-in-MuLoCo hit `ffs=3210` at
  n=10 so the wrapper has more headroom.

### PR #56 g1r3-nezuko — Lion replacing AdamW + Muon
- `g1r3-nezuko/lion-everywhere-lr-sweep` at step 3686 with `val/loss = 6.6365`. Diverged. Best Lion-flavored arm anywhere in the project is `g1r4-thorfinn/lion-aux-arm-a` at `val=3.3144, ffs=-1` (worse than baseline; Lion only on aux slots).
- **Confirmed negative result.** Lion-everywhere at this scale is not competitive.
- **Sent**: stop the running smoke, post terminal `SENPAI-RESULT` with
  `status="negative"` + LR-sweep table, swap to `status:review`. I'll
  close and reassign from the wave-2 queue (PSGD-Kron or Muon²).

### PR #57 g1r3-tanjiro — Per-module init std on plain Muon
- Run history: `screen-s0` (n=1) finished at `val=3.2858, ffs=-1`;
  second seed `screen-s0` instance running, currently step ~1775 with
  `val=3.4949` (mid-run).
- Init-only is a weak lever for plain Muon at this scale.
- **Sent**: recommended path A — let s1 finish, post 2-seed table,
  `status="negative"`, close. Init forward-rides onto wave-1 algorithmic
  winners. (Option B = run 4 seeds was offered but discouraged.)

### PR #58 g1r3-thorfinn — Cooldown shape × cooldown_frac sweep
- 100-step warmup fix failed: `g1r3-thorfinn/smoke-warmup100-linear-0.7`
  crashed at step 3.
- Diagnostic cross-PR fact: tanjiro's plain-Muon-WITH-per-module-init
  (no warmup, no compile change) is the only stable 1-GPU plain-Muon
  config on this branch.
- **Sent**: revised plan — Smoke A (per-module init only) and Smoke B
  (per-module init + warmup) as 300-step diagnostics before committing
  the 12-arm sweep. Escalate if both NaN; try lower Muon `mu=0.85` or
  disable `@torch.compile` next.

### Operational learnings this iteration

- **frieren MuLoCo screen reaching the 3.28 line** is the first wave-1
  signal that wrapping plain Muon in an outer Nesterov SGD actually
  works on 1 GPU — encouraging, but needs multi-seed.
- **askeladd's clip-only MuonH miss** suggests the clip-only/always-active
  distinction is doing more work than I assumed when I wrote the
  hypothesis. The bundled reference uses always-active; we should
  default to always-active for any future Frobenius-ball variant.
- **The 1-GPU plain-Muon NaN instability is tied to init std, not LR.**
  thorfinn's warmup-100 fix failing at step 3 + tanjiro's per-module
  init running cleanly with no warmup + no public 1-GPU runs using
  default init = strong evidence the init lever is mandatory for any
  plain-Muon-derived experiment at world_size=1.
- **Per-module init is a free-rider lever.** It doesn't move the needle
  in isolation but appears to be the stability prerequisite for plain
  Muon at 1 GPU. Future PRs touching plain Muon at 1 GPU should fold
  it in by default.

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
