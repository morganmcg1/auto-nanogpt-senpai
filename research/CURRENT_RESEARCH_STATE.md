# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-18 (~02:50 UTC, poll #129)
- **Current baseline:** mu=3.271362, std=0.001181, n=6 (PR #162 merged 12:42Z)
  - ffs_mean=3141.67, ffs_best=3125. Statsig: `(3.271362 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.269362 | n=6: mu ≤ 3.269729 | n=8: mu ≤ 3.269948

## ⭐ Active Hot Signals

1. **FERN PR #318 β₁=0.70 Phase 2 trigger MET** (`bmiour40`):
   - Cell A (β₁=0.70): **val=3.26920 ffs=3125** (Δ=-0.00216, ~1.8σ below baseline) ⭐
   - Phase 2 gate cleared: val ≤ 3.270 AND ffs ≤ 3150 ✓
   - Cell B (β₁=0.80 ctrl, `xinpvprd`) running step ~1364/3250, ETA ~03:25Z
   - **Directive:** After Cell B terminal — stop Phase 1 sweep (skip C/D/E), launch Phase 2 n=4 at β₁=0.70
   - Phase 2 command: `--num_trials 4 --adam_beta1_aux 0.70 --wandb_group g1r5-fern/adam-beta1-confirm`
   - Phase 2 ETA launch ~03:25Z, terminal ~11:00Z May 18
   - **Statsig target (n=4):** mean ≤ 3.269362

2. **FRIEREN PR #228 n=6 extension `3704tjm5` in-flight**:
   - t0-t3: (3.270223, 3.269885, 3.270447, 3.270973) mean=3.270382
   - **t4=3.269534** ⭐ new frieren single-trial best (ffs=3125)
   - t5 (trial 1 of `3704tjm5`) running step ~2165/3250, ETA ~03:13Z
   - For n=6 merge: t5 ≤ 3.267312 (= 6×3.269729 − sum(t0..t4) = 19.618374 − 16.351062)
   - If n=6 fails: extend to n=8 (gate mean ≤ 3.269948)

3. **NEZUKO PR #283 Phase 2 n=4 AGC λ=0.03** (`407dyaw7`):
   - Trial 0: val=3.27193 ffs=3150 (slight regression from n=1=3.27002)
   - Trial 1 running (step ~711/3250 within trial), ETA trial 1 terminal ~04:00Z
   - Full n=4 terminal ~06:30Z
   - **Statsig target (n=4):** mean ≤ 3.269362 — with trial 0=3.27193, remaining 3 need mean ≤ 3.268516 (tight)
   - If n=4 borderline: extend to n=6 (gate 3.269729)

## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #228 | frieren | lr_embed=0.80 n=6 extension (`3704tjm5`) | t5 running ~03:13Z |
| #283 | nezuko | AGC Phase 2 n=4 λ=0.03 | Trial 1 step ~711, full ETA ~06:30Z |
| #306 | alphonse | lm_head LR sweep | Cell C (`o7pictq5`, lr=0.010) step ~2211, ETA ~03:20Z |
| #318 | fern | Adam β₁ sweep → Phase 2 pivot | Cell B ctrl (`xinpvprd`) step ~1364, ETA ~03:25Z; Phase 2 launches after |
| #320 | edward | Adam β₂ aux sweep | Cell A retry (`9zjcpd9q`, β₂=0.85) step ~417, sequential B→D→E pending |
| #321 | thorfinn | cooldown_frac sweep | Cell C ctrl (`vmlfw0hr`) step ~2621; Cell A retry pending (qmsl9jww crashed); Cell B→D→E pending |
| #323 | tanjiro | Muon mu sweep | Cell A (`gr0xvxt1`, mu=0.85) step ~2961, ETA ~02:50Z |
| #334 | askeladd | **NEW: Muon WD sweep** (wd_mlp/wd_attn ∈ {0,0.01,0.025,0.05,0.10}) | Just assigned; Cell A (wd=0) launching |

## Closed This Session (poll #127-129)

- **PR #301 (askeladd NS5 polynomial): CLOSED clean-neutral ~02:45Z May 18**
  - Best: Cell D (1.7,-1.1,0.4) val=3.27073 ffs=3125 (Δ=-0.00063, ~0.5σ within noise)
  - Phase 2 gate NOT met (val=3.27073 > 3.270). Polynomial space FLAT around current settings.
  - → Askeladd reassigned PR #334 (Muon WD sweep)

- **PR #289, #264, #270** — closed earlier this session (see previous state doc)

## Upcoming Decisions (~next 4-8h)

- ~02:50Z: tanjiro Cell A terminal (mu=0.85 — if val ≤ 3.270, Phase 2 trigger)
- ~03:05Z: thorfinn Cell C ctrl terminal → if ctrl reproduces baseline, auto-launch Cell A retry
- ~03:13Z: frieren t5 terminal → n=6 merge decision (needs t5 ≤ 3.267312 for merge; if miss, n=8 extension)
- ~03:20Z: alphonse Cell C terminal (lr_lm_head=0.010)
- ~03:25Z: fern Cell B ctrl terminal → Phase 2 n=4 at β₁=0.70 launches
- ~04:00-11:00Z: Sweep completions rolling in (edward, thorfinn cells, tanjiro B→E, askeladd WD A→E)
- ~06:30Z: nezuko Phase 2 n=4 terminal → merge if statsig passes, else n=6 extension
- ~11:00Z: fern Phase 2 n=4 terminal → merge decision

## Research Themes

**Primary goal:** Stack orthogonal mechanisms onto lr_mlp=0.055 base to push below ffs=3125. Target: ffs=3100 → 3075 → beyond.

**Active mechanism threads:**
- **AdamW aux β₁ (fern):** β₁=0.70 shows 1.8σ signal → Phase 2 confirm in flight
- **AdamW aux β₂ (edward):** β₂ sweep A/B/D/E in progress
- **LR schedule (thorfinn):** cooldown_frac sweep — first-ever on this stack
- **lm_head LR (alphonse):** 0.001/0.003 worse, 0.010 pending (~3.2× ctrl)
- **AGC clipping (nezuko):** Phase 2 n=4 in flight; trial 0 slightly regressed from n=1
- **Muon WD (askeladd):** JUST ASSIGNED — wd_mlp/wd_attn never swept on any stack
- **Muon mu (tanjiro):** mu=0.85 first cell, B→E pending

**Exhausted mechanism slots:**
- NS5 polynomial space (askeladd, clean-neutral, flat around (2,-1.5,0.5))
- SOAP attn eigvec smoothing (thorfinn, clean-neutral)
- SOAP β₂ cold-start warmup (edward, clean-neutral)
- Q/K shared Gram (fern, clean-neutral)
- AdamW eps sweep (alphonse, clean-neutral)
- Per-layer LR decay (nezuko, clean-negative)
- NS5 iteration count (askeladd, clean-neutral)
- SOAP attn Gram damping (fern, clean-neutral)
- Cautious-Muon, Lookahead, SWA, z-loss, gradient centralization, label smoothing, depth-init, per-head SOAP, schedule-free Muon, polynomial schedule-free Muon, SOAP β₂ cooldown annealing — all closed

**Candidate next hypotheses (unassigned):**
- Separate lr_attn sweep on new stack (PR #209 was clean-negative at old baseline)
- Spectral/orthogonal QKV weight init
- Adam β₂ schedule ramp over training
- Per-group lr_embed × lr_lm_head 2D joint confirm (after alphonse sweep)
- NS5 + AGC compound (if both β₁ and AGC confirm)
- Muon nesterov flag ablation (nesterov=True hardcoded; test nesterov=False)
