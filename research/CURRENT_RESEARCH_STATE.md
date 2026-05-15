# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 20:30 UTC
- **Most recent human-team directive:** None received.
- **Branch state:** 1 commit beyond seed (cc1c710 — `sample_tensor` clamp fix).
  No experiment PRs merged yet. Wave 1 ~8 hours in.
  - **alphonse #51 NorMuon is the lead merge candidate** — independent screen hit target (`val=3.279, ffs=3275, reached=1`) and confirm trial-1 better (`val=3.2761, ffs=3225`). Multi-trial confirmation still in flight at cumulative step ~6927. PR currently CONFLICTING; rebase reminder sent.
  - frieren #55 MuLoCo n=4 confirm partial: 1 crash at step 4111, restart in flight at step 2750.
  - edward #53 Contra-Muon n=4 confirm in flight at cumulative step 7327 — trials 1+2 both `ffs=-1`. Concerning.
  - PRs #56 (Lion), #57 (init-only) closed as negative.
  - PR #87 (tanjiro u/w-floor) screen running cleanly at step 1980 val=3.514.

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, **batch size (and mbs=64)**, and one fwd-bwd per optim step fixed.
Optimizer, schedule, init, telemetry editable.

## Wave 1 — current status

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #51 | alphonse | NorMuon (canonical 1D post-NS) | Screen `2t6x8z6v` `val=3.279 ffs=3275 reached=1`; confirm `8yocwc35` step 6927 cumulative, latest `ffs=3250` | Awaiting terminal SENPAI-RESULT; rebase reminder sent |
| #52 | askeladd | MuonH clip-only | `budget0.85` finished `val=3.295 ffs=-1` (missed); `budget1.15` running | Let sweep continue |
| #53 | edward | Contra-Muon | `n7ea9xyr` confirm at step 7327; trials 1+2 `ffs=-1` | Let confirmation complete; pre-commit close if all 4 miss |
| #54 | fern | SOAP-MLP precond before NS | smoke v6c clean at mbs=32 (CONTRACT VIOLATION); v7 plan: mbs=64 + 200-step SOAP gate | Authorized smoke v7; pre-commit close if v7 NaNs |
| #55 | frieren | MuLoCo outer Nesterov | `tvb6lpz9` crashed step 4111; `0qry1ckh` restart at step 2750 val=3.342 | Crash-mode check requested |
| #58 | thorfinn | Cooldown shape × frac sweep | 26 sweep runs: 8 crashed, 15 failed, 2 finished both `ffs=-1` | Asked to diagnose + 3-arm serial; pre-commit close on next failure |

## Wave 2 — running

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #86 | nezuko | MuonSquared | 5 smokes all NaN/OOM through both fallbacks | Authorized smoke v6 (`eps=1e-5, beta2=0.99, 5-step warmup`); pre-commit close if v6 NaNs |
| #87 | tanjiro | u/w-floor | screen `b5ucb98s` step 1980 val=3.514 (clean trajectory) | Status check-in sent |

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

- **Imminent merge candidate**: alphonse #51 (NorMuon). Awaiting terminal SENPAI-RESULT to merge.
- **Backup candidates**: frieren #55 (MuLoCo) once crash is resolved; tanjiro #87 (u/w-floor) once screen completes.
- **At-risk PRs (pre-commit close)**: fern #54 (SOAP) if v7 NaNs; thorfinn #58 (cooldown sweep) if next attempt crashes; nezuko #86 (MuonSq) if v6 NaNs; edward #53 (Contra-Muon) if all 4 trials miss.

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
