# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-16 01:35 UTC (wave 2 in execution; tanjiro pivoted to bias correction)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best (branch baseline):** 3275 steps, val=3.2766 (n=2) — alphonse Muon² merged 2026-05-15
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Merged baseline — alphonse Muon² (#60)

**Mechanism:** Adam v-EMA applied to raw momentum BEFORE Newton-Schulz orthogonalization.
- 2 seeds, both first_step_to_target=3275, val≈3.2766
- n=2 stat-sig: mu=3.276565, margin=0.004859 ≥ 0.004 ✓
- Bundled: `sample_tensor` float64 precision fix, `NANOGPT_NS_ITERS` env var
- **Known mechanism flaw (diagnosed by tanjiro #97):** no Adam-style bias correction → first-step preconditioner is unstable across beta2 values. PR #108 fixes this.

## Closed PRs

| PR | Student | Result |
|----|---------|--------|
| #60 | alphonse | **MERGED** — Muon² NS=12, 3275 steps, n=2 stat-sig |
| #62 | askeladd | CLOSED — SF-Muon failed (3.3638). Cooldown is load-bearing. |
| #66 | edward | CLOSED — Cosine/linear baseline both NaN/diverged. Branch corruption. |
| #70 | fern | CLOSED — frac=0.5 n=4 mean=3.27924, margin=0.00152 NOT stat-sig |
| #72 | frieren | CLOSED — Nesterov mu=0.92 full-length val=3.2811, worse than baseline |
| #73 | nezuko | CLOSED — WD warmup n=2 mean=3.27919, margin=0.00114 NOT stat-sig |
| #75 | tanjiro | CLOSED — NS=8 safe (within noise), NS=6 fails. Wall-clock savings < 1%. |
| #77 | thorfinn | CLOSED — Lion aux groups failed (3.3109). |
| #91 | thorfinn | CLOSED — aspect-ratio formula NaN cascade, branch corruption. |
| #97 | tanjiro | CLOSED INCONCLUSIVE — pod-level GPU divergence; surfaced Muon² bias-correction flaw |

## Active PRs (wave 2)

| PR | Student | Hypothesis | Status |
|----|---------|-----------|--------|
| #90 | askeladd | muP LR sweep on vanilla Muon | arm-A=3.2807; blocked on rebase (commented) |
| #92 | edward | Orthogonal QKV init | arm-A finished (~3.34 @ 2750); arm-B normal-init queued |
| #96 | alphonse | Muon² LR retune | arm-A=3.27815, arm-B=3.27709 (both marginally worse than 3.2766); arm-C (lr=0.040) running, ETA ~02:55 |
| #102 | fern | LR warmup sweep | Just assigned, no runs yet |
| #104 | frieren | Polyak EMA model weight averaging | Just assigned, no runs yet |
| #105 | thorfinn | Gradient clipping sweep | Just assigned, no runs yet |
| #106 | nezuko | Muon² cooldown_frac sweep | Just assigned, no runs yet |
| **#108** | **tanjiro** | **Muon² + Adam-style bias correction (pod smoke-test gated)** | **JUST ASSIGNED — fixes mechanism flaw from #97** |

## Pod health watch

**tanjiro pod (GPU UUID 7998cef9-...)**: Reproducibly NaNs the merged Muon² baseline. Bf16 tensor-core or NS polynomial accumulator likely affected by silicon-binning. PR #108 includes a mandatory smoke-test gate; if it fails, escalate to infra.

**alphonse pod (GPU UUID a808f13a-...)**: Running merged baseline cleanly (val=3.2766 confirmed). Currently on arm-C of #96.

**Other student pods**: No anomalies yet — but if any of (askeladd, edward, fern, frieren, thorfinn, nezuko) start showing step-25 NaN, suspect the same silicon issue.

## Wave 2 emerging picture

Wave 2 LR retune (alphonse #96): Muon² LR is **at or near the 0.035 peak**. lr=0.030 → 3.27815 (worse), lr=0.0375 → 3.27709 (marginally worse), lr=0.040 awaiting. **Likely outcome: no LR retune gain.** Diagnostic: Muon²'s 2nd-moment preconditioning sharpens the update direction, and 0.035 was already at the peak inherited from vanilla Muon — preconditioning doesn't shift the LR optimum.

Wave 2 still in flight:
- **Muon² bias correction** (tanjiro #108) — most likely to fix a known mechanism flaw
- **Standard practices** (fern #102 warmup, thorfinn #105 clip, frieren #104 EMA) — likely small gains if any
- **Cooldown shape** (nezuko #106) — extending fern's positive vanilla-Muon signal onto Muon²

## Potential next research directions (wave 3 candidates)

**If bias correction (PR #108) succeeds**:
1. **Muon² + bias correction + retuned (lr, beta2) combined** — apply all wave-2 findings
2. **Muon² + bias correction + Contra-Soft / SOAP-MLP stack** — bigger ceiling

**Independent of bias correction**:
3. **Trust-region Muon** — per-layer update norm cap, complementary to NS orthogonalization
4. **Schedule-free Muon with Polyak averaging** — combine #104 EMA's eval-only smoothing with on-policy training
5. **SOAP-MLP for AdamW aux groups** — record #20 mechanism, complex port but highest leaderboard headroom

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials.
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.
- Merged baseline includes `sample_tensor` float64 fix + `NANOGPT_NS_ITERS` env var.
- 1 GPU per student node — sequential arm execution required.
- **NEW pattern**: Future Muon²-touching PRs should include a 100-step smoke test of the merged baseline before launching long arms, given the tanjiro pod precedent.
- GitHub rate limit: ~4000/5000 remaining at 01:35 UTC.
