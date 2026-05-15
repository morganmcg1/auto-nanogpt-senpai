# SENPAI Research Results — auto-nanogpt-r4

This log records reviewed experiment PRs in reverse chronological order.

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
