# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-18 (poll #126, ~00:05 UTC)
- **Current baseline:** mu=3.271362, std=0.001181, n=6 (PR #162 merged 12:42Z)
  - ffs_mean=3141.67, ffs_best=3125. Statsig: `(3.271362 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.269362 | n=6: mu ≤ 3.269729 | n=8: mu ≤ 3.269948

## ⭐ Active Hot Signals

1. **FRIEREN PR #228 n=6 extension in-flight** (`3704tjm5`):
   - n=4 complete: t0=3.270223, t1=3.269885, t2=3.270447, t3=3.270973, **mean=3.270382** ffs=3125 4/4
   - n=4 merge gate FAILS (mu=3.270382 > n=4 gate 3.269362)
   - n=6 extension `3704tjm5` launched ~22:50Z, step 1272 at 23:22Z
   - **For n=6 merge:** need t4+t5 mean ≤ 3.268423 (~4.3σ below current 4-trial mean — tough but possible)
   - If n=6 fails: extend to n=8 (gate ≤ 3.269948, ~1.6σ gap from 4-trial mean)
   - ETA terminal ~02:30Z May 18

2. **NEZUKO PR #283 Phase 2 n=4 AGC λ=0.03 launched** (~23:37Z):
   - Phase 1 sweep: A=3.27208, B=3.27226, **C=3.27002 ⭐ ffs=3125**, D=3.27075 ffs=3125
   - Both C (λ=0.03) and D (λ=0.1) beat baseline mu at n=1; plateau at λ∈{0.03,0.1}
   - **Phase 2 n=4 at λ=0.03** (W&B group `g1r5-nezuko/agc-confirm`) running
   - ETA terminal ~07:00Z May 18
   - **Statsig target:** mu ≤ 3.269362. Cell C n=1=3.27002 sits 0.00066 above threshold — plausible
   - If n=4 lands borderline: extend to n=6 (gate 3.269729)

3. **ASKELADD PR #301 NS5 polynomial sweep continuing**:
   - Cell A ctrl: val=3.27235 ffs=3150 | Cell B Muon-paper: val=3.27189 ffs=3150
   - Cell C `uia9awwp` (~step 2427 at 23:22Z, ETA ~00:15Z)
   - Phase 2 trigger: val ≤ 3.270 AND ffs ≤ 3150

## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #228 | frieren | lr_embed=0.80 n=6 extension (`3704tjm5`) | Running step 1272 (~02:30Z) |
| #283 | nezuko | AGC Phase 2 n=4 λ=0.03 | Running ~07:00Z May 18 |
| #301 | askeladd | NS5 polynomial coeff sweep | Cell C step 2949 (~00:15Z) |
| #306 | alphonse | lm_head LR sweep | Cell B `pvk9u2pg` step 1866, ETA ~01:00Z |
| #318 | fern | Adam β₁ sweep (β₁=0.80 ctrl) | Cell A `bmiour40` step 1019, ETA ~02:00Z |
| #320 | edward | Adam β₂ sweep for AdamW aux groups | Cells A+C both in flight (~23:50Z launch; parallel issue flagged) |
| #321 | thorfinn | LR cooldown fraction sweep (cooldown_frac) | Cell C ctrl just started ~23:55Z |
| #323 | tanjiro | Muon momentum (mu) sweep | **JUST ASSIGNED** ~00:05Z |

## Closed This Polling Window (poll #125-126)

- **PR #289 (tanjiro combo n=4): CLOSED clean-neutral 00:03Z May 18**
  - n=4 mean=3.271485 (Δ=+0.000123, ~0.4σ within noise). Combo gain fully absorbed by lr_mlp=0.055.
  - → Tanjiro reassigned PR #323 (Muon mu sweep)
- **PR #270 (edward SOAP β₂ warmup): CLOSED clean-neutral 23:40Z May 17**
  - Best: Cell C (0.50/500) val=3.27154 ffs=3150 (Δ=+0.00018). No Phase 2 trigger.
  - → Edward reassigned PR #320 (Adam β₂ aux sweep)
- **PR #264 (thorfinn SOAP eigvec EMA): CLOSED clean-neutral 23:38Z May 17**
  - Best: Cell B (α=0.3) val=3.27263 ffs=3125 (Δ=+0.00127, within 1σ). No Phase 2 trigger.
  - Inverted-U around α=0.3 confirmed. Mechanism exhausted.
  - → Thorfinn reassigned PR #321 (cooldown_frac sweep)

## New Assignments (poll #125)

- **PR #320 edward — Adam β₂ aux sweep:**
  - 5 cells: β₂ ∈ {0.85, 0.90, 0.95 ctrl, 0.99, 0.999}
  - Companion to fern PR #318 (β₁ sweep) — together map the AdamW 2D momentum surface
  - Phase 2 trigger: val ≤ 3.270 AND ffs ≤ 3150

- **PR #321 thorfinn — LR cooldown_frac sweep:**
  - 5 cells: cooldown_frac ∈ {0.5, 0.6, 0.7 ctrl, 0.8, 0.9}
  - cooldown_frac=0.7 inherited from original record, never swept. High prior on signal.
  - Mechanism: controls when ffs can first hit 3.28 → direct connection to speedrun metric
  - Phase 2 trigger: val ≤ 3.270 AND ffs ≤ 3150

## Pending Closures (awaiting SENPAI-RESULT then close)

- **PR #289 (tanjiro combo n=4):** Trial 3 at step 12566 (ETA ~00:45Z). Close clean-neutral after. 3-trial mean=3.271603 → n=4 merge dead.

## Upcoming Decisions (~next 2-4h)

- ~00:15Z: askeladd Cell C terminal → if val ≤ 3.270, Phase 2 trigger
- ~00:45Z: tanjiro trial 3 terminal → close PR #289 clean-neutral, reassign tanjiro
- ~01:00Z: alphonse Cell B terminal → Cell C (lr_lm_head=0.010) launches; sweep continues
- ~02:00Z: fern Cell A terminal → Cell B (β₁=0.80 ctrl) launches
- ~02:30Z: frieren n=6 extension terminal → apply statsig math, decide n=8 if needed
- ~07:00Z: nezuko Phase 2 n=4 terminal → merge if statsig passes, else extend to n=6

## Research Themes

**Primary goal:** Stack orthogonal mechanisms onto lr_mlp=0.055 base to push below ffs=3125. Target trajectory: ffs=3100 → 3075 → beyond.

**Active mechanism threads:**
- **AdamW aux hyperparams:** β₁ (fern), β₂ (edward) — mapping full 2D momentum space
- **LR schedule:** cooldown_frac (thorfinn) — first-ever cooldown boundary sweep
- **AdamW lm_head LR:** alphonse — last per-group LR axis after embed (frieren) and MLP (edward PR #162)
- **AGC clipping:** nezuko Phase 2 — best n=1 signal in portfolio (Δ=-0.00134)
- **NS5 polynomial:** askeladd — characterizing polynomial space at fixed iters=12

**Exhausted mechanism slots:**
- SOAP attn eigvec smoothing (thorfinn, clean-neutral)
- SOAP β₂ cold-start warmup (edward, clean-neutral)
- Q/K shared Gram (fern, clean-neutral)
- AdamW eps sweep (alphonse, clean-neutral)
- Per-layer LR decay (nezuko, clean-negative)
- NS5 iteration count (askeladd, clean-neutral)
- SOAP attn Gram damping (fern, clean-neutral)
- Cautious-Muon, Lookahead, SWA, z-loss, gradient centralization, label smoothing, depth-init, per-head SOAP, schedule-free Muon, polynomial schedule-free Muon, SOAP β₂ cooldown annealing — all closed

**What hasn't been tried (candidate next hypotheses):**
- Muon momentum (mu) sweep — mu=0.95 default, never swept on this stack
- Separate lr_attn sweep was done at old baseline (PR #209 clean-negative); but not re-tested with lr_mlp=0.055 stack (inference from that result: lr_attn=0.035 stays)
- Cooldown SHAPE on new stack (PR #48 on old Muon — retesting with SOAP could differ)
- Spectral/orthogonal init for QKV weights
- Adam β₂ schedule (ramp over training, complementing thorfinn's SOAP β₂ idea)
- lm_head LR result may suggest per-group lr_embed × lr_lm_head 2D joint confirm
