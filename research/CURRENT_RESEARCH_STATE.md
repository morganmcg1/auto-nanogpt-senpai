# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 22:45 UTC (boot 12)
- **Most recent human-team directive:** None received. (GitHub REST rate-limited; full issue check deferred to next boot after 23:19 UTC reset.)
- **Branch state:** 1 commit beyond seed (cc1c710 — `sample_tensor` clamp fix).
  No experiment PRs merged yet. Wave 1 ~9.5 hours in. Boot 11 closed 3 PRs as negative and assigned 3 fresh hypotheses.
  - **Boot 12 audit at 22:40 UTC**: GitHub REST API rate limit hit (resets 23:19 UTC) — affects both advisor and student pods. fern/nezuko/thorfinn show "No assigned PRs" in pod logs because their `gh` polls are failing. Wave-2 PRs (#99/#100/#101) will be picked up automatically once limit resets.
  - **alphonse #51 NorMuon**: `40g9f47i` top-up running clean at step 2350 (~975 steps to go). n=4 ETA ~01:00 UTC. Still need terminal SENPAI-RESULT before merge.
  - **askeladd #52 MuonH SI screen**: `5tecoakm` running step 2325/3350. **Grad norm 103,929 anomalous** (vs 30-70k for 3 prior SI arms). No NaN yet; watch flag. ETA ~23:04 UTC. Prior 3 arms (`dn2n29yi`, `pg5tves8`, `t4zxp2sf`) all val=3.29x, ffs=-1 (missed).
  - **edward #53 Contra-Muon confirm**: `n7ea9xyr` step 11603/13300 = trial 4 of 4 in progress. Trials 1+2 already ffs=-1. Pre-commit close as negative when terminal.
  - **frieren #55 MuLoCo**: `0qry1ckh` step 7277, currently in trial 3. **ffs=3275 reported ✓** — trial 1 of 0qry1ckh may have hit target. Per-trial breakdown needed at terminal. If n=4 mean ≤ 3.278, this becomes a SECOND merge candidate. tvb6lpz9 (older run) crashed at step 4111 (lost).
  - **tanjiro #87 u/w-floor**: arm 1 (`qduieg8g`) running step 900/3350. Arm 2 not launched yet (sequential — ETA arm 2 launch ~00:30 UTC).
  - **PRs CLOSED as negative (boot 11)**: #54 fern SOAP-MLP (smoke v7 NaN), #58 thorfinn cooldown sweep (both arms missed), #86 nezuko MuonSquared (smoke v6 NaN at step 50).
  - **PRs NEW (boot 11)**: #99 fern Adafactor aux, #100 nezuko Sign-Muon, #101 thorfinn Polyak EMA. All 3 fresh wave-2 hypotheses, orthogonal to NorMuon, can run immediately without waiting for alphonse merge. **Not yet picked up by student pods (gh rate limit, expected to resolve after 23:19 UTC).**
  - edward #53 Contra-Muon: still running confirmation. Pre-commit close if all 4 trials miss.
  - tanjiro #87 u/w-floor: 4-arm corners sweep launched 22:23 UTC. ETA ~02:00 UTC.
  - askeladd #52 MuonH: launched SI variant (Option A) `5tecoakm` at 21:38 UTC. Held deadline close; audit confirms healthy progress.
  - PRs #56 (Lion), #57 (init-only) closed as negative previously.

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, **batch size (and mbs=64)**, and one fwd-bwd per optim step fixed.
Optimizer, schedule, init, telemetry editable.

## Wave 1 — current status (boot 12 audit at 22:40 UTC)

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #51 | alphonse | NorMuon (canonical 1D post-NS) | n=2 confirmed `mu=3.27706 ffs=3237.5` (stat 0.00416). `40g9f47i` top-up step 2350, ~975 to go | **Wait for n=4** terminal SENPAI-RESULT; do not merge on n=2 |
| #52 | askeladd | MuonH (Option A: SI always-active) | `5tecoakm` step 2325/3350. Grad norm 103,929 anomalous (vs 30-70k prior arms), no NaN yet | Audit at terminal (~23:04 UTC); 3 prior SI arms `dn2n29yi/pg5tves8/t4zxp2sf` all val=3.29x ffs=-1 |
| #53 | edward | Contra-Muon | `n7ea9xyr` step 11603/13300 = trial 4 of 4. Trials 1+2 already ffs=-1 | Pre-commit close as negative when terminal (n=4 will not clear) |
| #55 | frieren | MuLoCo outer Nesterov | `0qry1ckh` step 7277 (trial 3 mid), **ffs=3275 ✓ reported** for trial 1 of fresh run; `tvb6lpz9` crashed at 4111 (lost arm) | Audit per-trial table when terminal; **possible merge candidate if n=4 mean ≤ 3.278** |
| #54 fern, #58 thorfinn, #86 nezuko | — | (CLOSED) | All closed as negative this boot 11 | See `EXPERIMENTS_LOG.md` boot-11 entry |

## Wave 2 — running

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #87 | tanjiro | u/w-floor | arm 1 `qduieg8g` step 900/3350. Arm 2 not yet launched (sequential) | Sweep ETA ~04:00 UTC at current pace; audit per-arm table when all 4 finish |
| #99 | fern | Adafactor aux for embed/lm_head/scalars | NO smoke run yet (pod blocked on gh rate limit) | Auto-resolves after 23:19 UTC reset; check next boot |
| #100 | nezuko | Sign-Muon (sign before NS5) | NO smoke run yet (pod blocked on gh rate limit) | Auto-resolves after 23:19 UTC reset; check next boot |
| #101 | thorfinn | Polyak EMA weights at val time | NO smoke run yet (pod blocked on gh rate limit) | Auto-resolves after 23:19 UTC reset; check next boot |

**Op note:** GitHub REST API rate-limited fleet-wide at 22:40 UTC (resets 23:19 UTC). Student pods retry every 5 min, so smoke runs will start ~23:25 UTC automatically. No advisor action required.

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

- **Imminent merge candidate**: alphonse #51 (NorMuon). n=2 passes already; waiting for n=4 terminal SENPAI-RESULT after `40g9f47i` top-up completes (~2.3h, ETA ~01:00 UTC).
- **Surprise possible second candidate**: frieren #55 (MuLoCo) — `0qry1ckh` reporting ffs=3275 ✓ for trial 1, contradicting earlier negative-leaning trajectory. Need per-trial table at terminal to make call.
- **Backup candidates**: tanjiro #87 (u/w-floor) if a corner of 4-arm sweep clears target; askeladd #52 SI variant if `5tecoakm` clears target despite grad-norm spike.
- **At-risk PRs (pre-commit close)**:
  - **#53 edward** (Contra-Muon) — trials 1+2 missed; close as negative when trial 4 terminal.
  - **#52 askeladd** (MuonH SI) — if `5tecoakm` also misses, close as `negative: MuonH at 1 GPU misses with both clip-only and SI variants`.
- **Wave-2 fresh hypotheses (just assigned, boot 11; auto-pickup pending after gh rate limit reset 23:19 UTC)**:
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
