# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 12:35 UTC
- **Most recent human-team directive:** None received as of this writing.
- **Branch state:** fresh; no merged PRs yet on `auto-nanogpt-1gpu-r3`. Starter
  `records/track_3_optimization/train_gpt_simple.py` is unmodified and
  configured for plain Muon + aux AdamW at result #12 hyperparameters, 3350
  steps. See `BASELINE.md` for details.

## Research goal

Reduce `speedrun/final_first_step_to_target` (lowest step where `val/loss <=
3.28`) on the fixed modded-nanogpt track 3 setup, satisfying the
`(3.28 - mu) * sqrt(n) >= 0.004` statistical rule. Architecture, data, and
batch size are fixed; we may modify optimizer, schedules, init, and logging.

## Current focus and themes

The starting baseline is vanilla Muon (≈ public result #12, 3350 steps). The
public history shows ample headroom — best known is result #20 at 3030 steps.
We open the program by spreading 8 student slots across:

1. **Exploitation of strong public mechanisms** — confirm and rebuild the
   strongest mechanisms in our own clean PRs, so future waves can stack:
   - NorMuon (Muon NS + Adafactor row/col preconditioning)
   - MuonH / hyperball constraint on hidden weights
   - Contra-Muon coordinated-update mechanism
   - SOAP-Muon for MLP weights (light precond before NS)
   - MuLoCo-style outer Nesterov wrapper

2. **Bold optimizer probe** — a fresh, well-known optimizer not represented in
   the public records (Lion) to see whether it can clear `<3.28` at the
   benchmark step budget.

3. **Clean isolated levers** — per-module init std sweep and cooldown schedule
   shape sweep, both on top of plain Muon, so we can compose them with the
   algorithmic winners later.

## Wave 1 assignments (idle students)

| Student | Slug | Lever | Type |
| --- | --- | --- | --- |
| alphonse | normuon-impl | NorMuon (Muon + Adafactor row/col precond) | algorithmic exploit |
| askeladd | muonh-hyperball | MuonH (Muon + Frobenius-ball constraint on hidden W) | algorithmic exploit |
| edward | contra-muon | Contra-Muon coordinated updates | algorithmic exploit |
| fern | soap-mlp-muon | SOAP preconditioning for MLP weights before NS | algorithmic exploit |
| frieren | muloco-outer | MuLoCo-style outer Nesterov SGD wrapper | algorithmic explore |
| nezuko | lion-everywhere | Lion replacing Muon+AdamW everywhere | bold optimizer probe |
| tanjiro | per-module-init-std | Per-module init std (attn.proj=.026, mlp.proj=.031, mlp.fc=.031) on Muon | init lever |
| thorfinn | cooldown-shape | Cosine/sqrt/linear cooldown @ frac={0.5,0.7,0.85,1.0} on Muon | schedule lever |

## Next research directions to consider (post wave 1)

- **Stack winners:** Take the strongest of wave 1 and combine — e.g. NorMuon ×
  MuonH × Contra-Muon × tuned init × tuned cooldown.
- **Preconditioner search:** Beyond SOAP — Shampoo with power tuning, KL-SOAP,
  PSGD-Kron, Sophia diagonal Hessian, Adafactor-Muon hybrid.
- **Schedule innovation:** Schedule-free Muon, two-phase (warmup→cosine→linear
  tail), trapezoidal cooldown, μP-style LR per group.
- **Update-rule innovation:** Muon² (squared NS update), Soft-Muon
  interpolation, Newton-Muon (activation-covariance right precond).
- **Architecture-init coupling:** Re-derive per-module init std for each new
  optimizer; init+optimizer are joint.
- **u/w-floor and trust-region variants:** Track-3 result #9 used u/w-floor in
  place of weight decay; trust-region clamping was used in #16.

## Operational notes

- Each student has 1 H100 (96GB). The starter script handles 1–8 GPUs by
  microbatching `8 * 64 * 1024 = 524288` tokens per optimizer step.
- Step budgets: tiny (≤300) for code/memory smoke; short (1500–2500) for new
  optimizer screening; full (≥3000) for confirmation runs at predeclared step
  count and seed count.
- The bundled public records (especially `20260430_muonh/train_gpt_simple_muonh.py`,
  `20260501_contra_muon/train_gpt_simple_contra_muon_2.py`) contain reference
  implementations of common mechanisms — students can use these as templates,
  but each PR must be self-contained.
- Banned reference sources: any Prime Intellect autonomous-run material. Stick
  to the bundled `records/track_3_optimization/` history and public papers.
