# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 20:00 UTC
- **Most recent human-team directive:** None received.
- **Branch state:** 1 commit beyond seed (cc1c710 — `sample_tensor` clamp fix).
  No experiment PRs merged yet. Wave 1 ~7.5 hours in.
  - PRs #56 (Lion) and #57 (per-module init only) closed as negative results.
  - PRs #86 (nezuko MuonSquared) and #87 (tanjiro u/w-floor) assigned, smokes running.
  - **alphonse #51 NorMuon is the leading merge candidate**: in-run `ffs=3225 val=3.2761` (seed 1), multi-trial confirmation in flight.
  - frieren #55 screen finished `val=3.2793 ffs=3325`; n=4 confirmation queued by student.
  - edward #53 n=4 confirmation in flight but trial 1 missed target (`ffs=-1`).

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, and batch size fixed; optimizer, schedule, init, telemetry editable.

## Wave 1 — current status

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #51 | alphonse | NorMuon (canonical 1D post-NS) | `8yocwc35`: seed 1 `ffs=3225 best_val=3.2761`, multi-trial at cumulative step 3876 | Check-in posted; awaiting terminal SENPAI-RESULT |
| #52 | askeladd | MuonH clip-only | `budget0.85` at step 1850 val=3.5834 (prior screen missed at val=3.2917) | Let run |
| #53 | edward | Contra-Muon | `n7ea9xyr` n=4 confirm @ cumulative step 3826, trial 1 `ffs=-1` | Let confirmation complete |
| #54 | fern | SOAP-MLP precond before NS | smoke v5 still NaN with per-module init | Escalated: disable `@torch.compile`, smoke v6 |
| #55 | frieren | MuLoCo outer Nesterov | screen `cbjch81g` finished `val=3.2793 ffs=3325`; n=4 not yet launched | Let student launch n=4 confirm |
| #58 | thorfinn | Cooldown shape × frac sweep | smoke A passed `val=4.0854` after pod restart | Greenlit 12-arm sweep at `train_steps=3350` |

## Wave 2 — newly running

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| #86 | nezuko | MuonSquared (Adam second-moment ⊕ NS) | smoke at step 0, running |
| #87 | tanjiro | u/w-floor (replace wd with update-norm floor) | smoke at step 125 val=4.799, running |

## Key learnings carried forward

1. **`sample_tensor` OOB bug** for tensors with `n > 2^24` is fixed on the branch (`cc1c710`).
2. **Plain Muon at 1 GPU with default init is NaN-unstable** due to a `torch.compile` Inductor kernel bug producing NaN in `blocks.0.attn.proj.bias.grad` at step 1.
   - **Primary fix**: per-module init std (`attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031`).
   - **Fallback**: disable `@torch.compile` on `train_step`. Now invoked for fern (smoke v5 NaN'd even with per-module init).
   - **LR warmup alone is insufficient** (thorfinn warmup-100 failed at step 3).
3. **NorMuon EMA bug** in original advisor spec is fixed; alphonse pivoted to canonical 1D post-NS variant per public #10.
4. **SOAP code v2** is correct (fern's root-cause analysis); the NaN is upstream `torch.compile` bug — not SOAP-specific.
5. **Per-module init in isolation doesn't beat baseline** (tanjiro #57 n=2 val=3.286 ffs=-1) — it's a stability ingredient, not a step-count lever. Compose on top of algorithmic winners.
6. **MuonH clip-only is weaker than always-active variant.** Default to `scale_invariant_update_` if revisiting Frobenius-ball.
7. **MuLoCo wrapper screens positive** but n=1 doesn't satisfy stat rule; n=4 confirmation needed.
8. **NorMuon (canonical) screens positive** — alphonse hit `ffs=3225 val=3.2761` seed 1; n-trial confirmation in flight.
9. **Lion is a confirmed negative** at this scale/budget (val=4.6171 best arm).

## Current research focus and themes

- **Imminent merges**: alphonse #51 (NorMuon) is the most likely first merge once terminal results post. Backup: frieren #55 (MuLoCo) and edward #53 (Contra-Muon).
- **Wave 2 ramping**: nezuko #86 (MuonSquared) and tanjiro #87 (u/w-floor) smokes are running fresh. Both have positive priors (public #7 and public #9 component, respectively).
- **Recovery in progress**: fern #54 SOAP escalating to compile-disable; thorfinn #58 12-arm cooldown sweep launched.

## Next research directions (wave 3 candidates)

Activate once wave 1 winners merge:

1. **Stack confirmed winners**: NorMuon × Contra-Muon = public #11 (`ffs=3225 n=16`); NorMuon × MuLoCo; Contra-Muon × MuLoCo.
2. **Always-active MuonH** with per-module init if askeladd's budget sweep continues to miss.
3. **Soft-Muon interpolation** (public #20 component) — sign-modulated Contra-Muon/Muon interpolation.
4. **PSGD-Kron** — Kronecker-factored preconditioner (lr=0.0005, wd=0.625); not yet attempted.
5. **Adafactor aux** — replace AdamW aux with Adafactor for embed/lm_head.
6. **Schedule post-thorfinn**: if cosine wins, try schedule-free Muon; if linear wins, try trapezoidal.

## Operational notes

- All 8 students have active WIP PRs. No idle GPUs.
- **Per-module init std is mandatory for any plain-Muon-1-GPU experiment**. Folded into wave-2 specs.
- **`@torch.compile` disable is the documented fallback** when per-module init alone is insufficient.
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill, post failure mode.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4 unless margin is very large at n<4.
- Banned reference sources: Prime Intellect autonomous-run materials.
