# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 22:30 UTC
- **Most recent human-team directive:** None received.
- **Branch state:** 1 commit beyond seed (cc1c710 — `sample_tensor` clamp fix).
  No experiment PRs merged yet. Wave 1 ~9.5 hours in. Boot 11 closed 3 PRs as negative and assigned 3 fresh hypotheses.
  - **alphonse #51 NorMuon**: n=2 already passes stat rule. `40g9f47i` top-up running clean at step 1450 of trial 0 (of 2 in this top-up). ETA ~01:00 UTC for n=4 terminal.
  - **PRs CLOSED as negative (boot 11)**: #54 fern SOAP-MLP (smoke v7 NaN), #58 thorfinn cooldown sweep (both arms missed), #86 nezuko MuonSquared (smoke v6 NaN at step 50).
  - **PRs NEW (boot 11)**: #99 fern Adafactor aux, #100 nezuko Sign-Muon, #101 thorfinn Polyak EMA. All 3 fresh wave-2 hypotheses, orthogonal to NorMuon, can run immediately without waiting for alphonse merge.
  - frieren #55 MuLoCo: `0qry1ckh` running n=4. Pre-commit close negative if mean > 3.278.
  - edward #53 Contra-Muon: still running confirmation. Pre-commit close if all 4 trials miss.
  - tanjiro #87 u/w-floor: 4-arm corners sweep launched 22:23 UTC. ETA ~02:00 UTC.
  - askeladd #52 MuonH: launched SI variant (Option A) `5tecoakm` at 21:38 UTC. Held deadline close; audit confirms healthy progress.
  - PRs #56 (Lion), #57 (init-only) closed as negative previously.

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, **batch size (and mbs=64)**, and one fwd-bwd per optim step fixed.
Optimizer, schedule, init, telemetry editable.

## Wave 1 — current status

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #51 | alphonse | NorMuon (canonical 1D post-NS) | n=2 confirmed `mu=3.27706 ffs=3237.5` (stat 0.00416). `40g9f47i` top-up running clean, step 1450 of trial 0 | **Wait for n=4** terminal SENPAI-RESULT; do not merge on n=2 |
| #52 | askeladd | MuonH (Option A: SI always-active) | `5tecoakm` SI screen running, step 1450/3350. Healthy | Held deadline close; audit pending screen completion (~50 min) |
| #53 | edward | Contra-Muon | `n7ea9xyr` confirm; trials 1+2 `ffs=-1` | Let confirmation complete; pre-commit close if all 4 miss |
| #55 | frieren | MuLoCo outer Nesterov | `tvb6lpz9` SIGTERM (trial 1 missed `val=3.28159`); `0qry1ckh` n=4 fresh, trial 1 mid-cooldown step 2975 | Pre-commit close as negative if n=4 mean > 3.278 |
| #54 fern, #58 thorfinn, #86 nezuko | — | (CLOSED) | All closed as negative this boot | See `EXPERIMENTS_LOG.md` boot-11 entry |

## Wave 2 — running (fresh-assigned in boot 11)

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #87 | tanjiro | u/w-floor | 4-arm sweep launched 22:23 UTC, arm 1 running | Awaiting per-arm table at halfway point |
| #99 | fern | Adafactor aux for embed/lm_head/scalars | (assigned) | Awaiting smoke launch |
| #100 | nezuko | Sign-Muon (sign before NS5) | (assigned) | Awaiting smoke launch |
| #101 | thorfinn | Polyak EMA weights at val time | (assigned) | Awaiting smoke launch |

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

- **Imminent merge candidate**: alphonse #51 (NorMuon). n=2 passes already; waiting for n=4 terminal SENPAI-RESULT after `40g9f47i` top-up completes (~2.5h, ETA ~01:00 UTC).
- **Backup candidates**: tanjiro #87 (u/w-floor) if a corner of 4-arm sweep clears target; askeladd #52 SI variant if screen clears; edward #53 (Contra-Muon) if n=4 mean clears.
- **At-risk PRs (pre-commit close)**:
  - **#55 frieren** (MuLoCo) as negative if n=4 mean > 3.278 (likely given trial-1 trajectory).
  - **#52 askeladd** (MuonH SI) if screen also misses target (close as `negative: MuonH at 1 GPU misses with both clip-only and SI variants`).
  - **#53 edward** (Contra-Muon) if all 4 trials miss.
- **Wave-2 fresh hypotheses (just assigned, boot 11)**:
  - #99 fern: Adafactor aux (orthogonal to block-side; stacks with NorMuon)
  - #100 nezuko: Sign-Muon (bounded NS5 input; alternative to MuonSquared)
  - #101 thorfinn: Polyak EMA (smooths final-cooldown noise; stacks with NorMuon)

## Next research directions (wave 3 candidates)

Activate once alphonse #51 merges:

1. **Stack winners**: NorMuon × Contra-Muon (= public #11, `ffs=3225 n=16`); NorMuon × MuLoCo (if frieren #55 closes negative, this becomes a wave-3 stack-up rather than confirmation); NorMuon × u/w-floor (= public #9, `ffs=3250 n=8`); NorMuon × Adafactor aux (if fern #99 lands).
2. **Stack-aware schedule**: cosine vs linear cooldown on top of NorMuon (replaces thorfinn's closed standalone schedule sweep).
3. **Stack EMA**: thorfinn #101 EMA × NorMuon — orthogonal levers, should compound.
4. **Soft-Muon interpolation** (public #20 component) — sign-modulated Contra-Muon/Muon interpolation. Note: nezuko #100 Sign-Muon is a simpler related variant.
5. **PSGD-Kron** — only attempt if torch.compile compile-mode bug is bypassed (low priority given SOAP struggles documented in closed #54).
6. **Init lever**: per-module init has been the silent free-rider — try lower qkv init std (currently default) as a follow-on.

## Operational notes

- All 8 students have active WIP PRs. Zero idle GPUs.
- All 8 r3 pods healthy (1/1 ready).
- **mbs=64 is part of the fixed benchmark contract**. mbs reductions are diagnostic only, never merge-eligible.
- **Per-module init std is mandatory for plain-Muon-derived 1-GPU experiments**.
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill, post failure mode.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4 by default.
- Banned reference sources: Prime Intellect autonomous-run materials.
