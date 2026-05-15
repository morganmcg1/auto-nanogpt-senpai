# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-15 (evening — PR #64 PMuon MERGED as new baseline 3150 steps; PR #68 Aurora+Contra+u/w base empirically broken; Wave 2 pivoted to PMuon base; PR #59 vanilla closed at val 3.297 (target not reached))
- **Most recent direction from humans:** None (no GitHub issues open).
- **Target:** Push `speedrun/final_first_step_to_target` below 3150 steps (local best) toward the public record of 3030 steps (Record #20, Contra-Soft-Muon stack).

## Current local baseline

**3150 steps, val/loss 3.27447** — PR #64 (g1r1-fern, PMuon bilateral covariance EMA preconditioning, n=1, margin +0.00553 ✓).
W&B run: `vx0r7rp2`. Merged 2026-05-15. PMuon REPLACES the Newton-Schulz path entirely — Aurora row-norm equilibration, Contra-Muon, and u/w-floor were dropped during the rebase.

## CRITICAL FINDING: Aurora+Contra+u/w base (PR #68) is empirically unreliable

**Discovered 2026-05-15 by askeladd PR #84:** Multiple students' fresh runs of the PR #68 Aurora+Contra+u/w recipe diverge at step ~125 with `train/grad/global_norm ≈ 234K` — matching the Inductor compile bug signature from alphonse's PR #59 root cause. The original PR #68 winner W&B run `lg4xdlkt` was a lucky compile-cache draw, not a reproducible recipe.

**Confirmed divergent runs on the broken base:**
- `xakwxu84`, `761npqac` (askeladd NorMuon stack)
- `q869emek` (tanjiro/smoke3-pr68-pristine, plain PR #68 recipe re-run)
- `343520k1` (thorfinn/per-module-init)
- `n4l14w3j`, `dpfoptl8` (nezuko/power-cooldown-1p2)
- `8qkxbh7c` (alphonse/smoke-dynamic-true under aurora+contra+uw — `dynamic=True` alone is NOT sufficient for this stack)
- `liwmf3pg` (askeladd/sanity-normuon-off — NorMuon disabled, still diverges → base is the problem)

**Implication:** PR #68 baseline was an artifact. PMuon (PR #64, run `vx0r7rp2`) is the only reliably-reproducible local baseline. All Wave 2 stacks (#83, #84, #85, #88, #89) had to pivot to PMuon base.

## Active experiments (status:wip) — Wave 3 (all on PMuon base)

| PR  | Student     | Mechanism on PMuon base                       | Status |
| --- | ----------- | --------------------------------------------- | ------ |
| #93 | fern        | + **NorMuon short-axis** post-NS              | just assigned (was idle after PR #64 merge) |
| #94 | askeladd    | + **Skylight u/w-floor** (TARGET_UW=0.35)     | just assigned (PR #84 closed; reassigned here) |
| #85 | nezuko      | + **Power-law cooldown** γ=1.2                | nezuko already rebased to PMuon base 2026-05-15 20:39; in training |
| #83 | tanjiro     | + **SOAP-MLP** (pending PMuon-base pivot)     | sent back to pivot; was destabilizing on broken Aurora+Contra+u/w base |
| #88 | edward      | + **Soft-Muon** (p=0.1, cooldown-only)        | sent back to pivot; no prior activity (rate-limit silent fail earlier) |
| #89 | thorfinn    | + **Per-module init std** (attn.proj=0.026, mlp=0.031) | sent back to pivot; no prior activity |
| #65 | frieren     | MuonH hyperball + fp32-cast NS (independent diagnostic track) | resuming with bf16/fp32 fix |

## Closed this session

| PR  | Student  | Result | Decision |
| --- | -------- | ------ | -------- |
| #59 | alphonse | Vanilla Muon, dynamic=True compile fix: 3350 steps, val 3.29743 (target NOT reached at -1) | Closed; vanilla attribution: Aurora+Contra+u/w nominal advantage was ~0.023 val/loss, but PR #68 base is now known unreproducible. Alphonse's compile-bug root-cause was a major contribution. |
| #61 | askeladd | NorMuon standalone: 3275 steps, val 3.27920 (n=1, doesn't beat 3175) | Closed; stacking now in #93 (fern) |
| #63 | edward   | u/w floor seed batch: 1/2 hit at 3275 val 3.278 | Closed; u/w floor returns in #94 askeladd PMuon+u/w-floor stack |
| #67 | nezuko   | SOAP-MLP standalone: 3200 steps, val 3.27705 | Closed; SOAP-MLP returns in #83 tanjiro PMuon+SOAP-MLP (post-pivot) |
| #69 | thorfinn | KL-SOAP-H projected ~3.9 at step 3150 | Closed as clean negative result |
| #84 | askeladd | NorMuon stack on broken base — divergent | Closed; reassigned to #94 (PMuon + u/w-floor) |

## Key cross-cutting issues

1. **`sample_tensor` linspace bug** — FIXED in PR #64 merge (fp64+clamp variant).

2. **Inductor compile bug — KNOWN, partial workaround.** `torch.compile(model, dynamic=False)` NaNs `blocks.0.attn.proj.bias` grad at step 1 on RTX PRO 6000 Blackwell.
   - **Vanilla Muon**: `dynamic=True` fully fixes it (alphonse run `83qeloh9` clean throughout)
   - **PMuon**: appears robust to the bug empirically (covariance whitening damps seed-NaN amplitude); current merged baseline uses `dynamic=False` but doesn't fail
   - **Aurora+Contra+u/w**: `dynamic=True` alone is NOT sufficient (`8qkxbh7c` still diverges) — this is what makes PR #68's recipe unreproducible

3. **bf16 vs fp32 in NS** — frieren's investigation: NS in raw bf16 triggers NaN on the affected pods; explicit fp32 cast (`m32 = update.float()`) before NS is required.

4. **Muon weight_decay**: `Muon.step` applies WD via `p.mul_(1 - lr*wd)` (confirmed by askeladd PR #61). PMuon retains the same WD mechanism; at lr=0.035, wd=0.025 effective decay is ~0.000875/step.

## Wave 3 status

Wave 3 portfolio targets sub-3150 steps with single-mechanism additions on PMuon base:

| PR  | Mechanism added | Public reference | Comment |
| --- | --------------- | ---------------- | ------- |
| #93 | + NorMuon short-axis | Record #10 (3250, n=20) | PMuon pre-NS whitening + NorMuon post-NS magnitude scaling — orthogonal mechanisms |
| #94 | + Skylight u/w-floor | Record #9 (3250, n=8) | Does u/w-floor still help when PMuon already provides scale via covariance whitening? |
| #85 | + Power-law cooldown γ=1.2 | Record #20 component | Schedule lever — orthogonal to optimizer side |
| #83 | + SOAP-MLP (pending pivot) | Record #14 (3150, n=4) | Eigenbasis-Adam preconditioning on MLP weights — pending tanjiro's rebase to PMuon base |
| #88 | + Soft-Muon (pending pivot) | Record #20 component | SVD-level shrinkage in cooldown only — pending edward's rebase |
| #89 | + Per-module init std (pending pivot) | Record #5 family | Low-surface initialization tweak — pending thorfinn's rebase |

## Wave 4 roadmap (after Wave 3 winners)

1. **Stack winners.** If any Wave 3 PR lands at <3150, combine the strongest two on PMuon base.
2. **PMuon ablations**: γ scan {0.25, 0.30, 0.35}, β_cov scan {0.90, 0.95, 0.99} on the base before stacking.
3. **MuLoCo / Lookahead outer Nesterov** (Record #13) — sync_interval=30, slow-moving outer copy on PMuon.
4. **SOAP-attn trust gate** (Record #16) — apply SOAP to attn.proj with trust metric gate.
5. **n≥4 seed batch on the new local best** — stat-sig confirmation when the frontier stabilizes below 3100.

## Statistical rule reminder

`(3.28 - mu) * sqrt(n) >= 0.004` required for final claims. All current Wave 3 assignments are single-trial screening runs (n=1). Winners need n≥3 seed confirmation before paper-grade claims.
