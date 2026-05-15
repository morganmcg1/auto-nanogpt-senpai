# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-15 (afternoon, post-merge)
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3175 steps (local best) toward the public record of 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3175 steps, val/loss 3.274438** — PR #68 (g1r1-tanjiro, Aurora + Contra-Muon + Skylight u/w floor, n=1, margin +0.005562 ✓).
W&B run: `lg4xdlkt`. Merged 2026-05-15.

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                      | Wave | Note |
| --- | ----------- | ---------------------------------------------- | ---- | ---- |
| #83 | tanjiro     | Aurora + Contra-Muon + **SOAP-MLP** (target sub-3150) | 2 | just assigned |
| #84 | askeladd    | Aurora + Contra-Muon + u/w + **NorMuon short-axis** | 2 | just assigned |
| #63 | edward      | u/w floor only (Skylight) — needs n=3 seed batch | 1 | 3275 steps n=1, margin too thin |
| #64 | fern        | PMuon streaming covariance preconditioning      | 1 | in training |
| #65 | frieren     | MuonH hyperball — diverged, sent back for debug | 1 | awaiting response |
| #67 | nezuko      | SOAP-MLP only (isolation, no Aurora/Contra)     | 1 | restarted, step ~75 |
| #69 | thorfinn    | KL-SOAP-H (full SOAP replacing NS)             | 1 | step 1890, val 5.68 (concerning) |
| #59 | alphonse    | Vanilla baseline — diverged, sent back for debug | 1 | awaiting response |

## Closed this session

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| #61 | askeladd | NorMuon standalone: 3275 steps, val 3.27920 (n=1, doesn't beat 3175 baseline) | Closed; NorMuon confirmed on hardware, now stacking in #84 |

## Current focus and themes

**Wave 2 stacking strategy** — build on the Aurora+Contra+u/w foundation (PR #68) by adding one mechanism at a time:
- #83: + SOAP-MLP (targets sub-3150, ~75-step gain expected based on #11→#14 public trajectory)
- #84: + NorMuon short-axis (targets ~3125–3150, stacking on confirmed NorMuon signal)

**Wave 1 completions still pending:** edward (n=3 seeds), fern (PMuon), nezuko (SOAP-MLP isolation), thorfinn (KL-SOAP-H), alphonse/frieren (debug). Only edward and potentially nezuko/fern are expected to reach target; thorfinn may not.

## Key cross-cutting issues

1. **`sample_tensor` linspace bug** — FIXED in PR #68 merge. The `.clamp_(max=values.numel()-1)` patch is now on `auto-nanogpt-1gpu-r1`. All future runs on this branch are safe.

2. **Muon weight_decay gotcha in BASELINE.md** — INCORRECT. The baseline `Muon.step` **does** apply WD via `p.mul_(1 - lr*wd)` (confirmed by askeladd PR #61). BASELINE.md will need a correction. The practical effect: effective WD at lr=0.035, wd=0.025 is 0.035×0.025=0.000875 per step — very small but not zero.

3. **Step-1 gradient explosion** — PRs #59 (alphonse) and #65 (frieren) diverged (gnorm ~10^5, NaN by step 25). The same code trains fine for 6 other students. Sent back with diagnostic plans. Likely pod-specific bf16/precision environment issue.

4. **thorfinn #69 val 5.68 at step 1890** — KL-SOAP-H is dramatically above target. Either the eigenbasis isn't stabilized yet or the approach needs a different lr. Monitor for natural convergence; may need to send back with lr scan instructions if still high at step 2500.

## Wave 2 stacking roadmap (priority order)

1. **Aurora+Contra+SOAP-MLP** (tanjiro #83) — highest expected gain, aligns with #11→#14 progression
2. **Aurora+Contra+NorMuon** (askeladd #84) — NorMuon confirmed locally, clean stacking test
3. **Aurora+Contra+NorMuon+SOAP-MLP** (Wave 3) — full Record #14 analog on the Aurora base; assign once #83/#84 confirm
4. **Power-law cooldown** `c*(t_end-step)^1.2` — Record #20 uses this; assign when cooldown schedule becomes the next bottleneck
5. **Soft-Muon** (singular-value shrinkage p=0.1 in cooldown) — Record #20 component
6. **n=4 seed batch for 3175 baseline hardening** — low priority while frontier is being pushed; assign once a Wave 2 result either confirms or supersedes

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004` required for final claims. All current Wave 2 assignments are single-trial screening runs (n=1). Winners need n>=3 (ideally n>=4) seed confirmation before paper-grade claims.
