# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 22:10 UTC
- **Most recent human-team directive:** None received.
- **Branch state:** 1 commit beyond seed (cc1c710 — `sample_tensor` clamp fix).
  No experiment PRs merged yet. Wave 1 ~9 hours in.
  - **alphonse #51 NorMuon**: n=2 already passes stat rule (trial 0 `val=3.2761 ffs=3225`, trial 1 `val=3.2780 ffs=3250`; margin 0.00417). Original `8yocwc35` died mid trial 2 from external SIGTERM (operational, not NaN). Student launched `40g9f47i` top-up n=2 to reach n=4 total. ETA ~3-4h. Rebased branch.
  - frieren #55 MuLoCo confirm: `tvb6lpz9` SIGTERM root-cause confirmed; trial 1 cleanly missed at val=3.28159. Restart `0qry1ckh` running n=4. Trial 1 at step 2975 val=3.31429 — trajectory matches tvb6lpz9 within 0.002. **Merge math concern**: if all 4 trials land 3.281-3.285, mean ~3.282 > 3.278 (n=4 merge bar). Pre-commit close as negative if mean > 3.278.
  - edward #53 Contra-Muon confirm: still running, trials 1+2 both missed target. No new state.
  - tanjiro #87 u/w-floor: status:review premature (sweep not done) — swapped back to status:wip. Screen miss at val=3.28266. 4-arm corners sweep still authorized; awaiting student launch.
  - thorfinn #58 cooldown sweep: status:review premature — swapped back to status:wip. Diagnostic accepted (v1 mass failures = `sample_tensor` bug + Muon-1-GPU instability, not launcher). v2 `linear-0.5` finished missed (val=3.28503); `linear-0.7` still running.
  - askeladd #52 MuonH: deadline 22:40 UTC; no student response yet.
  - PRs #56 (Lion), #57 (init-only) closed as negative.

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, **batch size (and mbs=64)**, and one fwd-bwd per optim step fixed.
Optimizer, schedule, init, telemetry editable.

## Wave 1 — current status

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #51 | alphonse | NorMuon (canonical 1D post-NS) | n=2 confirmed `mu=3.27706 ffs=3237.5` (stat 0.00416). `8yocwc35` SIGTERM'd mid trial 2; `40g9f47i` top-up n=2 running, rebased | **Wait for n=4** terminal SENPAI-RESULT; do not merge on n=2 |
| #52 | askeladd | MuonH clip-only | All r3 runs missed (budget0.85 `val=3.295`, budget1.15 missed, post-18:32 crashed) | Deadline 22:40 UTC; pre-commit close + reassign if no response |
| #53 | edward | Contra-Muon | `n7ea9xyr` confirm; trials 1+2 `ffs=-1` | Let confirmation complete; pre-commit close if all 4 miss |
| #54 | fern | SOAP-MLP precond before NS | smoke v6c clean at mbs=32 (CONTRACT VIOLATION); v7 plan: mbs=64 + 200-step SOAP gate | Authorized smoke v7; pre-commit close if v7 NaNs |
| #55 | frieren | MuLoCo outer Nesterov | `tvb6lpz9` SIGTERM (trial 1 missed `val=3.28159`); `0qry1ckh` n=4 fresh, trial 1 mid-cooldown step 2975 | Crash accounting OK; pre-commit close as negative if n=4 mean > 3.278 |
| #58 | thorfinn | Cooldown shape × frac sweep | v2 `linear-0.5` finished `val=3.28503` missed; `linear-0.7` step 1825 running | Diagnostic accepted; pre-commit close as negative if linear-0.7 misses |

## Wave 2 — running

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #86 | nezuko | MuonSquared | 5 smokes all NaN/OOM through both fallbacks | Authorized smoke v6 (`eps=1e-5, beta2=0.99, 5-step warmup`); pre-commit close if v6 NaNs |
| #87 | tanjiro | u/w-floor | screen `b5ucb98s` finished MISSED `val=3.28266 ffs=-1` (margin 0.0027 wrong side) | Authorized 4-arm corners sweep `(lr ∈ {0.035, 0.04}) × (TARGET_UW ∈ {0.30, 0.40})`; label corrected back to status:wip |

## Key learnings carried forward

1. **`sample_tensor` OOB bug** is fixed on the branch (`cc1c710`).
2. **Plain Muon at 1 GPU with default init is NaN-unstable** due to step-1 `blocks.0.attn.proj.bias.grad` spike (cross-PR diagnosis: alphonse r1 #59, fern #54). Per-module init `attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031` mitigates for some optimizers (NorMuon, Contra-Muon, MuLoCo) but NOT for SOAP-MLP or MuonSquared.
3. **`@torch.compile` disable** is no longer a free fallback — without compile, mbs=64 OOMs (12 GiB logits tensor in fp32). `mbs=32` works but violates the benchmark contract.
4. **Numerical-tightening fallback for divide-by-second-moment optimizers**: raise `eps`, raise `beta2`, add a step-warmup gate. Applied to nezuko #86 MuonSquared.
5. **Algorithm-warmup gate fallback for matrix-precond optimizers**: skip precond for first N steps (run plain Muon), engage precond from step N+1. Applied to fern #54 SOAP-MLP (N=200).
6. **alphonse NorMuon (canonical 1D post-NS) works at 1 GPU** — both screen and confirm-trial-1 hit target with margin. First confirmed wave-1 positive.
7. **MuonH clip-only is weaker than budget0.85**; askeladd's sweep is exploring the budget knob.
8. **Lion / init-only / mbs=32 are closed negative directions**.

## Current research focus and themes

- **Imminent merge candidate**: alphonse #51 (NorMuon). n=2 passes already; waiting for n=4 terminal SENPAI-RESULT after `40g9f47i` top-up completes (~3-4h).
- **Backup candidates**: tanjiro #87 (u/w-floor) if a corner of 4-arm sweep clears target; edward #53 (Contra-Muon) if n=4 mean clears.
- **At-risk PRs (pre-commit close)**:
  - **#55 frieren** (MuLoCo) as negative if n=4 mean > 3.278 (likely given trial-1 trajectory).
  - **#58 thorfinn** (cooldown sweep) as negative if `linear-0.7` also misses.
  - **#52 askeladd** (MuonH clip-only) if no student response by 22:40 UTC.
  - **#54 fern** (SOAP) if v7 NaNs.
  - **#86 nezuko** (MuonSq) if v6 NaNs.
  - **#53 edward** (Contra-Muon) if all 4 trials miss.

## Next research directions (wave 3 candidates)

Activate once alphonse #51 merges:

1. **Stack winners**: NorMuon × Contra-Muon (= public #11, `ffs=3225 n=16`); NorMuon × MuLoCo; NorMuon × u/w-floor (= public #9, `ffs=3250 n=8`).
2. **Stack-aware schedule**: cosine vs linear cooldown on top of NorMuon (replaces thorfinn's standalone schedule sweep).
3. **Adafactor aux**: replace AdamW for embed/lm_head — should be orthogonal to block-side levers.
4. **Soft-Muon interpolation** (public #20 component) — sign-modulated Contra-Muon/Muon interpolation.
5. **PSGD-Kron** — only attempt if torch.compile compile-mode bug is bypassed (low priority given SOAP struggles).

## Operational notes

- All 8 students have active WIP PRs. Zero idle GPUs.
- All 8 r3 pods healthy (1/1 ready).
- **mbs=64 is part of the fixed benchmark contract**. mbs reductions are diagnostic only, never merge-eligible.
- **Per-module init std is mandatory for plain-Muon-derived 1-GPU experiments**.
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill, post failure mode.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4 by default.
- Banned reference sources: Prime Intellect autonomous-run materials.
