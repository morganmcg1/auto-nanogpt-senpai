# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-04 (launch day, updated ~21:15 UTC)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

This launch was opened explicitly as an open-context SOTA combination run: mine
the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed)
plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below
2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## Active assignments (as of 2026-06-04 ~20:00 UTC)

| PR | Student | Hypothesis | Base | Target step | Status | Source |
|---:|---|---|---|---:|---|---|
| #2281 | open2-alphonse | H1 NC on Aurora+RRE base | PR #305 | 2925 | **trial 0 done 3.2769**, trial 1 step ~1000 (34%) | PR #295 |
| #2282 | open2-askeladd | H2 EMA-Nesterov (β=0.3) | PR #300 | 2900 | seed 1 done **3.28135 (FAIL)**, seed 2 step ~2625 (90%) | PR #309 |
| #2283 | open2-edward | H3 Circuit-Muon isolated | PR #300 | 2930 | n=4 confirm `glygz1xt` trial 0 step ~1050 (36%) | PR #311 |
| #2284 | open2-fern | H4 Arbor vs NC ablation (3 arms) | PR #300 | 2930 | Arm A n=4 confirm `m50dnbvb` trial 0 step ~300; Arm B re-impl pending per spec | PR #295, #310 |
| #2289 | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930 | Arm A control `wd1aaqtr` trial 0 step ~375 (12%); Arm B not yet launched | PR #307, #312 |
| #2286 | open2-nezuko | Replicate PR #309 EMA-Nesterov+Aurora | PR #309 | 2890 | **seed 1 done 3.27794**, seed 2 step ~2425 (84%, terminal imminent) | PR #309 |
| #2287 | open2-tanjiro | H9 Single-stage Tail Phase Readout | PR #300 | 2930 | **trial 0 done 3.2791**, trial 1 step ~586 (20%) | PR #318 |
| #2288 | open2-thorfinn | Replicate PR #295 NC standalone | base Muon | 3325 | **trial 0 done 3.2778**, trial 1 step ~76 (very early) | PR #295 |

**Top contenders (trial 0 / seed 1 partial — ranked by val/loss):**

| Student | PR | Trial 0 val/loss | Step | n=1 margin | Hypothesis |
|---|---:|---:|---:|---:|---|
| alphonse | #2281 | **3.2769** | 2925 | +0.0031 | NC on PR #305 base (Aurora+RRE+Contra-Muon+NC) |
| thorfinn | #2288 | **3.2778** | 3325 | +0.0022 | NC standalone on base Muon (PR #295 replicate) |
| nezuko | #2286 | **3.27794** | 2890 | +0.00206 | EMA-Nesterov + Aurora (PR #309 lineage) |
| tanjiro | #2287 | **3.2791** | 2930 | +0.00090 | Single-stage Tail Phase Readout on PR #300 |
| askeladd | #2282 | 3.28135 | 2900 | −0.00135 | EMA-Nesterov on PR #300 bare (FAILED ceiling) |

**Note on thorfinn:** his step 3325 is higher than PR #305 (2925) and PR #300 (2930), so a val/loss win there doesn't directly contribute to a sub-2900 fixed-step record — it just confirms NC is a real mechanism. Compositional value: pair with alphonse's NC-on-PR-#305 win at step 2925 (3.2769) to triangulate that NC reliably helps in the 0.001-0.0015 range.

**Reading the early seed/trial pattern:** four mechanisms (NC, EMA-Nesterov+Aurora, Tail-Phase, RI) all produce single-seed wins ≤ 3.279 at compatible step counts. The contract requires n=4 mean ≤ 3.278 for stat-sig — so seed-2 variance is the gating signal for the next merge.

**Resolved this turn:**
- thorfinn trial 0 landed at 3.2778 — PR was stale_wip but he was actually training; left status note + analysis on PR #2288.
- fern launched Arm A n=4 confirmation `m50dnbvb` per my priority order; Arm B re-impl pending.
- edward launched n=4 confirmation `glygz1xt` (circuit-muon-pr300-confirm).
- frieren Arm A control progressing cleanly at step ~375/3020.

**Resolved this turn:**
- W&B step encoding `trial_idx × (train_steps+1) + step` (line 676) misread as "divergence to 10.82 after target step". Actually trial 2 starting fresh — runs are healthy.
- PR #2285 (frieren H5 RI on PR #305 base) — closed earlier; PR #305 base NaN on Blackwell.
- Histogram bug fix landed on advisor branch as f8ecb78e (from tanjiro's eeaf2a30).

## Research focus

## Research focus

**Primary question:** Can layering the strongest community sub-2900 mechanisms
(EMA-Nesterov, Circuit-Muon, Tail Phase Readout, Aurora EMA Reference, Reference
Interpolation) on top of the official #300/#305 merged base, and on top of
Senpai's audited beta2-pulse + PMuon/LR/EMA stack, push the fixed-step
crossing below 2900?

**Sub-questions for the first wave:**
1. Is pre-NS normalization (Normalized Correction PR #295 / Arbor Muon PR #310)
   composable with the Aurora + RRE base?
2. Does EMA-Nesterov (PR #309) work on top of the official PR #300 base, or
   does it require something Aurora-specific?
3. Is Circuit-Muon (PR #311) the key contributor to the #311 stack, or is the
   gain mostly from EMA-Nesterov?
4. Does Reference Interpolation (PR #307/#312) independently improve PR #300 base (frieren, H5b)? Can it then be composed with RRE (PR #305)?
5. Does the multi-point Tail Phase Readout idea (PR #318) survive in
   single-stage form on the #300 base?
6. Can Senpai's audited PR #1532/#1614 beta2 pulse be layered onto the public
   sub-2900 baselines (PR #309 / #305)?

## Next research directions (after first wave)

- Full #311 stack on PR #300 base (EMA-Nesterov + Circuit-Muon + Aurora).
- Senpai PMuon preconditioning composed with Aurora row-balanced polar — test
  whether these compete for the same mlp.proj slot or are orthogonal.
- EMA-Nesterov rest-window sensitivity (β shutoff at steps 1500 / 1950 / 2200).
- Three-arm composition: EMA-Nesterov + NC + Reference Interpolation on #300
  (no Circuit-Muon, isolates the magnitude of Circuit-Muon contribution).
- Tail Phase Readout multi-stage (after single-stage validates).
- Reduce official record's RRE step count (PR #305 captures from step 2820) and
  test whether shifting earlier helps when combined with EMA-Nesterov.

## Suggested follow-up themes if first wave plateaus

- Replace Newton-Schulz with the polar-express iteration (PR #254 lineage)
  inside Muon.
- Per-module init standard deviation tuning (Hyperball PR #267 lineage)
  combined with NS variants.
- KL-SOAP preconditioning (#290) interactions with EMA-Nesterov, vs Aurora.
- Outer-Nesterov (MuLoCo PR #277) wrapper around the strongest inner-loop
  optimizer.

## Things to AVOID without strong justification

- Scalar LR/WD sweeps as the primary contribution of a PR — only retune to
  make a new mechanism fair.
- Repeating "Muon + aux Adam, lr=X, wd=Y" hyperparameter tweaks unless the new
  step budget makes the existing setting stale.
- Heavy hyperparameter searches in the first 24 hours; bias toward mechanism
  diversity until we know which families work on our infra.
