# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-15 23:25 UTC (boot 13)
- **Most recent human-team directive:** None received.
- **Branch state:** 1 commit beyond seed. No experiment PRs merged yet. **Three positive directions now confirmed at trial-level**; wave-1 ~10.5 hours in.
  - **THREE POSITIVE DIRECTIONS** (all need n=4 confirmation before merge):
    - **alphonse #51 NorMuon**: 8yocwc35 trials 0+1 + 40g9f47i trial 1 = n=3 (val 3.27609 / 3.27803 / 3.2786, ffs 3225 / 3250 / 3275). **n=3 mean=3.27757**, stat margin `(3.28-3.27757)·√3 = 0.00421 > 0.004 ✓`. Trial 2 of 40g9f47i started (step 3301). n=4 ETA ~01:00 UTC.
    - **frieren #55 MuLoCo**: 0qry1ckh trial 1 (val=3.2792 ffs=3275) + trial 2 (val=3.2785 ffs=3275). **n=2 mean=3.27885** (just over 3.278 merge bar). Trial 3 mid-cooldown. Trials 3+4 need mean ≤ 3.27715 for n=4 merge. ETA ~02:30 UTC. Comment posted at 23:22 UTC acknowledging positive.
    - **askeladd #52 MuonH SI**: 5tecoakm screen finished `val=3.2775 ffs=3300 reached=1`. **First MuonH variant to clear target.** Confirm request sent at 23:23 UTC for n=4 at train_steps=3325 (`muonh-si-confirm-3325`). ETA after launch ~3h.
  - **edward #53 Contra-Muon**: 3 of 3 trials missed (val 3.2834 / 3.2845 / 3.2831 ffs=-1). Trial 4 in progress (step 12028/13300). Pre-commit close as negative when terminal — n=4 mean cannot clear 3.278 even with a perfect trial 4.
  - **tanjiro #87 u/w-floor**: arm 1 (`qduieg8g`) step 1900/3350. Arm 2 not launched (sequential). Sweep ETA ~04:00 UTC.
  - **Wave-2 picked up at 23:21 UTC** (after gh rate limit reset 23:19 UTC):
    - #99 fern Adafactor: branch checked out `g1r3-fern/adafactor-aux`
    - #100 nezuko Sign-Muon: branch checked out `g1r3-nezuko/sign-muon` (file already modified)
    - #101 thorfinn Polyak EMA: branch checked out `g1r3-thorfinn/polyak-ema`
  - **PRs CLOSED as negative (boot 11)**: #54 fern SOAP-MLP (smoke v7 NaN), #58 thorfinn cooldown sweep (both arms missed), #86 nezuko MuonSquared (smoke v6 NaN at step 50). #56 Lion, #57 init-only previously closed.
  - edward #53 Contra-Muon: still running confirmation. Pre-commit close if all 4 trials miss.
  - tanjiro #87 u/w-floor: 4-arm corners sweep launched 22:23 UTC. ETA ~02:00 UTC.
  - askeladd #52 MuonH: launched SI variant (Option A) `5tecoakm` at 21:38 UTC. Held deadline close; audit confirms healthy progress.
  - PRs #56 (Lion), #57 (init-only) closed as negative previously.

## Research goal

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt
track 3 setup, satisfying `(3.28 - mu) * sqrt(n) >= 0.004`. Architecture,
data, **batch size (and mbs=64)**, and one fwd-bwd per optim step fixed.
Optimizer, schedule, init, telemetry editable.

## Wave 1 — current status (boot 13 audit at 23:23 UTC)

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #51 | alphonse | NorMuon (canonical 1D post-NS) | n=3 mean=3.27757 ffs mean=3250, stat 0.00421 ✓. Trial 4 of 4 just started (`40g9f47i` step 3301) | **Wait for n=4** terminal; merge after SENPAI-RESULT |
| #52 | askeladd | MuonH Option A (SI always-active) | Screen `5tecoakm` HIT TARGET: val=3.2775 ffs=3300 reached=1 | n=4 confirm requested at 23:23 UTC (train_steps=3325, group `muonh-si-confirm-3325`) |
| #53 | edward | Contra-Muon | `n7ea9xyr` trials 1+2+3 all ffs=-1 (val 3.2834/3.2845/3.2831). Trial 4 in progress | Pre-commit close as negative when trial 4 terminal |
| #55 | frieren | MuLoCo outer Nesterov | `0qry1ckh` trial 1 (val=3.2792 ffs=3275 ✓) + trial 2 (val=3.2785 ffs=3275 ✓). Trial 3 mid-cooldown | n=2 mean 3.27885; n=4 needs trials 3+4 mean ≤ 3.27715. Comment posted ack |
| #54 fern, #58 thorfinn, #86 nezuko | — | (CLOSED) | Closed boot 11 as negative | See `EXPERIMENTS_LOG.md` boot-11 entry |

## Wave 2 — running

| PR | Student | Lever | W&B signal | Advisor action |
| --- | --- | --- | --- | --- |
| #87 | tanjiro | u/w-floor | arm 1 `qduieg8g` step 1900/3350. Arm 2 not yet launched | Sweep ETA arm-1 ~01:30 UTC; per-arm table at sweep terminal |
| #99 | fern | Adafactor aux for embed/lm_head/scalars | Branch picked up at 23:21 UTC after gh rate limit reset | Awaiting smoke launch |
| #100 | nezuko | Sign-Muon (sign before NS5) | Branch picked up + file modified at 23:22 UTC | Awaiting smoke launch |
| #101 | thorfinn | Polyak EMA weights at val time | Branch picked up at 23:24 UTC | Awaiting smoke launch |

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

- **THREE positive directions confirmed at trial level — ordered by stat-rule readiness**:
  1. **alphonse #51 NorMuon** — n=3 mean=3.27757 already passes stat rule (0.00421 ≥ 0.004). Trial 4 of 4 just started in `40g9f47i`; n=4 ETA ~01:00 UTC. **First merge candidate.**
  2. **askeladd #52 MuonH SI** — single screen trial val=3.2775 ffs=3300. n=4 confirm just requested (`muonh-si-confirm-3325`). ETA ~02:30 UTC.
  3. **frieren #55 MuLoCo** — n=2 mean=3.27885 (just over bar). Trials 3+4 still need to land ≤ 3.27715 mean for n=4 merge. ETA ~02:30 UTC.
- **All 3 directions are orthogonal levers** and should stack:
  - NorMuon = block-side preconditioning (row/col second-moment EMA on POST-NS update).
  - MuonH SI = block-side update size constraint (always-active hyperball SI projection).
  - MuLoCo = outer-loop wrapper (Nesterov SGD on the slow weights).
  - Wave-3 will explore stacks of these (e.g. NorMuon×MuLoCo, NorMuon×MuonH-SI, MuonH-SI×MuLoCo, triple-stack).
- **At-risk PRs (pre-commit close)**:
  - **#53 edward** (Contra-Muon) — 3 of 3 trials missed; close as negative when trial 4 terminal. n=4 mean cannot clear 3.278 with perfect trial 4.
- **Wave-2 fresh hypotheses (just picked up by student pods at 23:21 UTC)**:
  - #99 fern: Adafactor aux (orthogonal aux optimizer; stacks with NorMuon).
  - #100 nezuko: Sign-Muon (bounded NS5 input; alternative to MuonSquared).
  - #101 thorfinn: Polyak EMA (smooths final-cooldown noise; stacks with NorMuon).

## Next research directions (wave 3 candidates)

Activate once alphonse #51 (or another wave-1 winner) merges. Updated to reflect three positive directions:

1. **Stack winners — highest priority**:
   - NorMuon × MuLoCo (if both merge as separate winners, stack on top of merged baseline).
   - NorMuon × MuonH-SI (block-side preconditioning × block-side update-size constraint — both same level but different mechanisms, may compete or compound).
   - MuonH-SI × MuLoCo (block-side constraint × outer-loop wrapper).
   - Triple-stack: NorMuon × MuonH-SI × MuLoCo.
2. **Stack with aux optimizer**: NorMuon × Adafactor aux (if fern #99 confirms), NorMuon × Sign-Muon (if nezuko #100 confirms).
3. **Stack with EMA**: thorfinn #101 EMA × NorMuon — orthogonal levers, should compound.
4. **Stack-aware schedule**: cosine vs linear cooldown on top of merged winner.
5. **Soft-Muon interpolation** (public #20 component) — sign-modulated Contra-Muon/Muon interpolation. Note: nezuko #100 Sign-Muon is a simpler related variant.
6. **PSGD-Kron** — only attempt if torch.compile compile-mode bug is bypassed (low priority given SOAP struggles documented in closed #54).
7. **Init lever**: per-module init has been the silent free-rider — try lower qkv init std (currently default) as a follow-on.

## Operational notes

- All 8 students have active WIP PRs. Zero idle GPUs.
- All 8 r3 pods healthy (1/1 ready).
- **mbs=64 is part of the fixed benchmark contract**. mbs reductions are diagnostic only, never merge-eligible.
- **Per-module init std is mandatory for plain-Muon-derived 1-GPU experiments**.
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill, post failure mode.
- Confirmation rule: `(3.28 - mu) * sqrt(n) >= 0.004`, n≥4 by default.
- Banned reference sources: Prime Intellect autonomous-run materials.
