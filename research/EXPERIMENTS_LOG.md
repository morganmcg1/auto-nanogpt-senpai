# SENPAI Research Results

Track-3 optimizer speedrun benchmark, `auto-nanogpt-r1` branch.
Primary metric: `speedrun/final_first_step_to_target` (lower is better).

## 2026-05-15 12:15 — PR #18: Trapezoidal LR: shorten cooldown 0.7→0.2 with warmup

- Branch: `r1-askeladd/trapezoidal-lr-short-cooldown` (closed)
- Hypothesis: shortening the linear-decay cooldown from `cooldown_frac=0.7` to
  0.2 (with a 40-step linear warmup) spends 80 % of the budget at full Muon LR
  and finds a flatter / faster-converging minimum at the same step budget.
  Prior: MiniCPM / Hazy Research warmup-stable-decay literature.
- Setup: `train_steps=3000`, `cooldown_frac=0.2`, `warmup_steps=40`, all other
  hparams identical to the in-repo Muon + AdamW baseline.

| Trial         | W&B run    | best val/loss | first_step_to_target |
| ------------- | ---------- | ------------- | -------------------- |
| cf=0.2 seed 1 | `l1hpyhuu` | 3.32967       | -1                   |
| cf=0.2 seed 2 | `4v0lry51` | 3.32883       | -1                   |
| cf=0.4 (diag) | `n8ywxfb1` | 3.31009       | -1                   |
| **cf=0.2 mean (n=2)** | —  | **3.32925**   | —                    |

Statistical check: `(3.28 - 3.32925) * sqrt(2) = -0.0697` vs required `+0.004`.
Hypothesis fails by ~50× the required margin.

**Conclusion: hypothesis disproven.** The trend is monotone *against* the
hypothesis — cf=0.4 outperforms cf=0.2, and the cf=0.2 val-loss curve is still
dropping at 0.022/100 steps at step 3000, meaning the optimizer would benefit
from MORE cooldown not less. MiniCPM-style short-decay does not transfer to
Muon-on-nanoGPT at this step budget. Closed without merge.

**Bug fix cherry-picked:** Student also independently found (and r1-tanjiro
confirmed in PR #31) a deterministic CUDA crash in `sample_tensor` — float32
`torch.linspace(0, n-1, m)` rounds the upper bound past the tensor when
`n-1 > 2^24` (embed/lm_head ≈ 3.86e7 entries). Fix uses int64 index
arithmetic. Cherry-picked to advisor branch (commit 30865be) so all future
student PRs inherit it.

**Suggested follow-ups (held in reserve):**
- Run cf=0.2 at train_steps=3350 (same budget as baseline) to isolate
  schedule-shape effect from budget effect.
- Sweep cooldown_frac ∈ {0.5, 0.6, 0.7, 0.8} at 3000 steps to find the
  shortest-budget cooldown that still works.
- Try cosine or `(1-progress)^2` decay shape at the same total budget.
- Power-law cooldown `c*(t_end-step)^1.2` from record #20.
