# SENPAI Research Results — auto-nanogpt-r4

This log records reviewed experiment PRs in reverse chronological order.

## 2026-05-15 — PR #15 sent back: cooldown shape sweep (r4-frieren)

- Branch: `r4-frieren/cooldown-sweep`
- Hypothesis: cosine cooldown beats linear for plain Muon at `lr=0.035 wd=0.025`.
  Original plan: 12-trial screen (5 shapes × 3 fracs at `train_steps=3300`,
  n=1) with predicted-best ordering and an early-stop rule.
- Result: hypothesis **rejected**. Student halted the screen after the first 3
  configs missed `val/loss ≤ 3.28` at step 3300:

  | shape | cooldown_frac | best val/loss | reached 3.28? | W&B |
  | :-- | :--: | :--: | :--: | :-- |
  | cosine | 0.7 | 3.28818 | no | `67kq3zlm` |
  | linear | 0.7 (starter shape) | **3.28268** | no (off by 0.003) | `lna7n2xy` |
  | cosine | 0.55 | 3.28634 | no | `i37g5nvo` |

  All three runs finished cleanly; W&B numbers cross-checked and match. The
  starter shape (linear 0.7) was the screen's best, narrowly missing target at
  the truncated step budget. Cosine lost at both fracs — mechanism (slower
  late-LR collapse) is the wrong direction here.
- Side discovery: real CUDA-blocking bug in `sample_tensor`. `torch.linspace`
  defaults to float32 on CUDA, and for the 50304×768 embedding (38,633,472
  elements) the right endpoint is past float32's 2²⁴ integer precision, so
  `.long()` produces an out-of-bounds index and the first
  `log_histograms` call asserts on every run. Fix: build `idx` in float64
  and `clamp_(max=N-1)`. Cherry-picked the 5-line fix to advisor branch as
  commit `25e02bd` so it's not blocked behind the schedule sweep.
- Action: sent PR back to `status:wip` with a revised plan that builds on the
  student's own follow-up suggestions:
  1. **Batch A** — confirm starter (linear 0.7 / 3350) at n=4 to lock down
     the active baseline statistically.
  2. **Batch B** — later-collapse shape screen at `train_steps=3300`: `sqrt
     0.7`, `sqrt 0.55`, `linear 0.85`, plus a new `pow1p5` (`x**1.5`) shape
     that pushes the "aggressive late-LR collapse" direction further.
     Relaxed stop rule: stop on 3 distinct *shapes* failing (not 3
     (shape, frac) pairs).
  3. **Batch C** — conditional 25-step speedup probe at `train_steps=3325`
     n=4 if Batch A confirms and any Batch-B config crosses target.
  Cosine dropped from the table.

## 2026-05-15 — PR #9 sent back: NorMuon reproduction (r4-alphonse)

- Branch: `r4-alphonse/normuon`
- Hypothesis: reproduce record #10 NorMuon at n=4.
- Result: **No training run yet.** Student (r4-alphonse) cross-checked PR
  instructions against
  `records/track_3_optimization/results/20260503_normuon/e0d0185f-...txt`
  and flagged that my section-1 described a **factored Adafactor (row+col)
  pre-NS** variant with `eps=1e-30`, but the actual record's `normuon_update`
  is **rank-1 row-only (or col-only for tall matrices) post-NS** with
  **Frobenius-norm restoration** and `eps=1e-10`. Same class of error as
  PR #10 — README prose vs in-repo source diverge.
- Action: sent PR back to `status:wip` with the verbatim `normuon_update` /
  `NorMuon` class pasted in the comment, and instructions adjusted to
  `train_steps=3300 num_trials=4`, stat-sig evaluation at step 3250.
  Dropped the retune sweep and the separate 3250 confirmation batch — one
  clean reproduction is what we need.

## 2026-05-15 — PR #10 sent back: Muon² confirmation (r4-askeladd)

- Branch: `r4-askeladd/muonsq-confirm`
- Hypothesis: reproduce record #7 (`muon_sq`) at n=6 to confirm the n=1
  result.
- Result: **No training run yet.** Student (r4-askeladd) read the PR
  instructions, cross-checked them against
  `records/track_3_optimization/results/20260501_muonsq/train_gpt_simple_muonsq.py`,
  and correctly flagged that my section-1 description of Muon² was wrong:
  the published algorithm is **g²-preconditioning of the momentum-blended
  direction before standard 12-iter NS**, not "NS twice / 24 iterations". My
  AdamW β-update was also misattributed — the `β₂=0.95 ε=1e-10` in record
  #7's header refer to MuonSq's `v_t`, not to AdamW.
- Action: sent PR back to `status:wip` with corrected instructions
  (`muon_sq_update` pasted in the comment, MuonSq group at
  `lr=0.10 wd=0.0125 mu=0.95 beta2=0.95 eps=1e-10`, AdamW unchanged).
- Lesson for future PRs that reference public records: paste the actual
  algorithm code from the in-repo `results/` snapshot rather than relying
  on the README's prose description.
