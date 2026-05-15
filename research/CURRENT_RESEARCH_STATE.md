# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-15 (evening — #67 closed, nezuko reassigned to power-law cooldown)
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3175 steps (local best) toward the public record of 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3175 steps, val/loss 3.274438** — PR #68 (g1r1-tanjiro, Aurora + Contra-Muon + Skylight u/w floor, n=1, margin +0.005562 ✓).
W&B run: `lg4xdlkt`. Merged 2026-05-15.

## Active experiments (status:wip)

| PR  | Student     | Mechanism                                      | Wave | Note |
| --- | ----------- | ---------------------------------------------- | ---- | ---- |
| #83 | tanjiro     | Aurora + Contra-Muon + **SOAP-MLP** (target sub-3150) | 2 | in training |
| #84 | askeladd    | Aurora + Contra-Muon + u/w + **NorMuon short-axis** | 2 | in training |
| #85 | nezuko      | **Power-law cooldown** (γ=1.2) on Aurora+Contra+u/w base | 2 | just assigned |
| #63 | edward      | u/w floor only (Skylight) — n=2 in training, n=3 batch | 1 | seed 2 at step 1875 val 3.51 |
| #64 | fern        | PMuon streaming covariance preconditioning      | 1 | step 3025 val 3.2923 (close to crossing) |
| #65 | frieren     | MuonH hyperball — diagnostic smoke-200 run     | 1 | investigating divergence |
| #69 | thorfinn    | KL-SOAP-H (full SOAP replacing NS)             | 1 | initfix run: step 975 val 4.50 (healthy, declining) |
| #59 | alphonse    | Vanilla baseline — compile-bug debug, retry on alternate modes | 1 | sent back |

## Closed this session

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| #61 | askeladd | NorMuon standalone: 3275 steps, val 3.27920 (n=1, doesn't beat 3175 baseline) | Closed; NorMuon confirmed on hardware, now stacking in #84 |
| #67 | nezuko   | SOAP-MLP standalone: 3200 steps, val 3.27705 (n=1, margin 0.0029 < 0.004; doesn't beat 3175 baseline) | Closed; SOAP-MLP isolation confirmed (25 steps behind), now testing as stack in #83 (tanjiro) and reassigned nezuko to power-law cooldown #85 |

## Current focus and themes

**Wave 2 stacking strategy** — build on the Aurora+Contra+u/w foundation (PR #68) by adding one mechanism at a time:
- #83: + SOAP-MLP (targets sub-3150, ~75-step gain expected based on #11→#14 public trajectory)
- #84: + NorMuon short-axis (targets ~3125–3150, stacking on confirmed NorMuon signal)
- #85: + **Power-law cooldown** (γ=1.2) — schedule-lever experiment, orthogonal to optimizer stacking

**Wave 1 completions still pending:** edward (n=3 seeds), fern (PMuon), nezuko (SOAP-MLP isolation), thorfinn (KL-SOAP-H), alphonse/frieren (debug). Only edward and potentially nezuko/fern are expected to reach target; thorfinn may not.

## Key cross-cutting issues

1. **`sample_tensor` linspace bug** — FIXED in PR #68 merge. The `.clamp_(max=values.numel()-1)` patch is now on `auto-nanogpt-1gpu-r1`. All future runs on this branch are safe.

2. **Muon weight_decay gotcha in BASELINE.md** — INCORRECT. The baseline `Muon.step` **does** apply WD via `p.mul_(1 - lr*wd)` (confirmed by askeladd PR #61). BASELINE.md will need a correction. The practical effect: effective WD at lr=0.035, wd=0.025 is 0.035×0.025=0.000875 per step — very small but not zero.

3. **Step-1 gradient explosion — ROOT-CAUSED (alphonse PR #59).** `torch.compile(model, dynamic=False)` (the default in `train_gpt_simple.py`) NaNs the gradient of `blocks.0.attn.proj.bias` at step 1 *only on RTX PRO 6000 Blackwell GPUs*. All other layers compute identical, finite gradients (~2.6e+04). With compile disabled, training is healthy at ~6244 ms/step. This is an Inductor kernel bug, not a code bug.
   - **Why other students train fine:** update/weight floors (u/w floor, Frobenius renorm, Aurora equilibration) clamp out the seed NaN before it propagates through `dist.all_reduce` and NS. The bug is *present but masked* in their runs.
   - **Implication for Wave 2:** any future stack that drops floors (e.g. pure KL-SOAP-H, plain SOAP-MLP without surrounding renorm) is vulnerable on the affected pods.
   - **Workaround under investigation:** alphonse is testing `dynamic=True`, `mode="reduce-overhead"`, `mode="max-autotune"`. If any compile mode produces clean grads, we keep `train_steps=3350` and proceed.
   - **Fallback:** disable compile and truncate the run (~6244 ms/step × 1500 steps ≈ 156 min; full 3350 steps would exceed timeout).

4. **thorfinn #69 KL-SOAP-H** — initial run diverged due to zero-init `*.proj.weight` + hyperball optimizer (frozen layers). Student fixed init recipe, relaunched as `klsoap-h-initfix`. Currently step 975 val 4.50, declining monotonically (~0.05 per 100 steps, zero NaN). Healthy but unlikely to reach target 3.28 — projected ~3.7-3.8 at step 3150. Let it complete for negative-result data.

## Wave 2 stacking roadmap (priority order)

1. **Aurora+Contra+SOAP-MLP** (tanjiro #83) — highest expected gain, aligns with #11→#14 progression
2. **Aurora+Contra+NorMuon** (askeladd #84) — NorMuon confirmed locally, clean stacking test
3. **Aurora+Contra+NorMuon+SOAP-MLP** (Wave 3) — full Record #14 analog on the Aurora base; assign once #83/#84 confirm
4. **Power-law cooldown** `c*(t_end-step)^1.2` — Record #20 uses this; assign when cooldown schedule becomes the next bottleneck
5. **Soft-Muon** (singular-value shrinkage p=0.1 in cooldown) — Record #20 component
6. **n=4 seed batch for 3175 baseline hardening** — low priority while frontier is being pushed; assign once a Wave 2 result either confirms or supersedes

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004` required for final claims. All current Wave 2 assignments are single-trial screening runs (n=1). Winners need n>=3 (ideally n>=4) seed confirmation before paper-grade claims.
