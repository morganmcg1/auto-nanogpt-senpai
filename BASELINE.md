# auto-nanogpt-r1 Baseline

Track-3 optimizer speedrun benchmark on FineWeb. Primary metric:
`speedrun/final_first_step_to_target` (lower is better; `-1` = target not reached).
Statistical rule for final claims: `(3.28 - mu) * sqrt(n) >= 0.004`.

## Current advisor-branch baseline

- **Source**: `records/track_3_optimization/train_gpt_simple.py` as checked in.
- **Optimizer**: Muon (lr=0.035, wd=0.025, mu=0.95, 12 NS iters) on block `ndim>=2`
  params; AdamW aux on embed/lm_head/scalars (betas=(0.8, 0.95), eps=1e-10).
- **Schedule**: trapezoidal `cooldown_frac=0.7` (stable 30%, linear decay 70%).
- **Init**: zero-init for `proj`, default normal for `embed`, `std=sqrt(0.33)/sqrt(fan_in)` elsewhere.
- **Steps**: 3350 (in-script `train_steps`).
- **Predicted regime**: roughly result #6/#12 territory (~3325–3375 steps in
  public history) but at fixed 3350 steps. No PRs merged yet on this branch.

## Public records to beat

From `records/track_3_optimization/README.md` (snapshot):

| Rank | Steps | Method                                              |
| ---- | ----- | --------------------------------------------------- |
| 1    | 3030  | Contra-Soft-Muon + SOAP attn/MLP (record #20)       |
| 2    | 3125  | KL-SOAP with hyperball (#19); SOAP attn trust (#16) |
| 4    | 3150  | Contra-Muon + SOAP MLP (#14)                        |
| 5    | 3175  | Setup #11 + Aurora (#17)                            |
| 6    | 3210  | MuLoCo outer-Nesterov + NorMuonH (#13)              |
| 7    | 3225  | NorMuon + u/w-floor + Contra-Muon (#11); PMuon (#18)|
| 9    | 3250  | NorMuon (#8/#9/#10)                                 |
| 12   | 3275  | Newton-Muon (#15)                                   |
| 13   | 3325  | MuonH (#5); Muon² (#7); Muon retune (#6/#12)        |
| 16   | 4875  | AdamH (#4)                                          |

## Working policy

- Every PR is one optimizer / schedule / init / preconditioner change on top of
  the in-repo baseline.
- Screening runs: 1 trial at the in-script `train_steps` (or shorter when
  uncertain) to gate before confirmation.
- Confirmation runs: predeclare step count and trial count; report
  `(3.28 - mu) * sqrt(n)` from non-cherry-picked trials.
- Merge whenever the new method strictly beats the prior baseline by the
  benchmark's statistical rule; treat new winners as the next baseline.
