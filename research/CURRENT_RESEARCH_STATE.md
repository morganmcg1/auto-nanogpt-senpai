# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-18 (~07:30 UTC, poll #137)
- **Current baseline:** mu=3.271362, std=0.001181, n=6 (PR #162 merged 12:42Z)
  - ffs_mean=3141.67, ffs_best=3125. Statsig: `(3.271362 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.269362 | n=6: mu ≤ 3.269729 | n=8: mu ≤ 3.269948

## ⭐ Active Hot Signals

1. **FERN PR #318 Phase 2 n=4 IN FLIGHT** ⭐ (highest-priority experiment):
   - Cell A (β₁=0.70 n=1): val=3.269202 ffs=3125 (Δ=-0.002160, ~1.83σ below baseline)
   - Cell B ctrl (β₁=0.80): val=3.272008 ffs=3150 (clean baseline reproduction)
   - Phase 2 run `53l16b0z` (group `g1r5-fern/adam-beta1-confirm`): step ~1640/13000 at 07:30Z (~13% complete)
   - ETA Phase 2 n=4 terminal: ~11:00-12:00Z May 18
   - **Statsig target (n=4):** mean ≤ 3.269362

## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #283 | nezuko | AGC Phase 2 n=4 λ=0.03 | **Mathematically locked out**: trial 0=3.27193, trial 1=3.27313, 2-mean=3.272530. Even if remaining 2 hit ever-best (3.269534), n=4 mean=3.271032 > gate 3.269362. Trial 2 in flight; close at terminal ~08:30Z |
| #306 | alphonse | lm_head LR sweep | Cell D (`29s9g1k2`, lr=0.030) step 2536/3250 ~07:30Z; Cell E pending |
| #318 | fern | Adam β₁ Phase 2 n=4 confirm | Run `53l16b0z` β₁=0.70 step 1640/~13000; ETA ~11-12Z |
| #320 | edward | Adam β₂ aux sweep | Cell A retry (β₂=0.85) **clean-neg val=3.27993 ffs=3250**; Cell C ctrl val=3.27101; Cell D (`378`, β₂=0.98) just launched |
| #321 | thorfinn | cooldown_frac sweep | Cell A retry (`4r1l7rhv`, cd=0.50) step 2906/3250 ~07:30Z; Cell C ctrl val=3.271924; Cell B→D→E pending |
| #323 | tanjiro | Muon mu sweep | Cell A val=3.27569 (mu=0.85 clean-negative); Cell B (`tmt9xxnc`, mu=0.90) step 3242/3250 val=3.2732 ffs=3150 (essentially terminal); Cell D→E pending |
| #334 | askeladd | Muon WD sweep (wd ∈ {0,0.01,0.025,0.05,0.10}) | Cell A (`pf30m69f`, wd=0) step 2545/3250 ~07:30Z |
| #337 | frieren | Muon nesterov ablation (True ctrl vs False/Polyak) | Cell A (`09d0v5j2`, nesterov=True) step 1793/3250 — recovered from concurrent-runs incident at 05:35Z |

## Closed This Session (poll #127-130)

- **PR #228 (frieren lr_embed=0.80 n=6 extension): CLOSED clean-neutral ~03:15Z May 18**
  - 6-trial results: (3.270223, 3.269885, 3.270447, 3.270973, 3.269534, 3.271443) mean=3.270251
  - Gate fails by 0.000522 (~0.45σ). p(n=8 pass)≈2%. lr_embed=0.80 mechanism exhausted.

- **PR #301 (askeladd NS5 polynomial): CLOSED clean-neutral ~02:45Z May 18**
  - Best: Cell D (1.7,-1.1,0.4) val=3.27073 ffs=3125 (Δ=-0.00063, ~0.5σ within noise)
  - Phase 2 gate NOT met. NS5 polynomial space flat around current settings.

- **PR #289, #264, #270** — closed earlier this session (see experiments log)

## Upcoming Decisions (~next 4-8h)

- ~07:35Z: tanjiro Cell B (mu=0.90) terminal → val=3.2732 ffs=3150 modest clean-neutral (mu=0.85 was neg, mu=0.90 is similar — sweep is curve-flat); direct tanjiro to remaining cells D,E
- ~07:45Z: thorfinn Cell A retry (cd=0.50) terminal → if good, sequential B→D→E
- ~08:00-08:30Z: askeladd Cell A (wd=0) terminal → sequential B→E
- ~08:00-08:30Z: alphonse Cell D (lr=0.030) terminal → trend A=3.276→B=3.272→C=3.271 monotone; D will reveal turning point
- ~08:30Z: frieren Cell A nesterov=True (ctrl) terminal → launch Cell B nesterov=False
- ~08:30Z: nezuko Phase 2 n=4 terminal → close clean-neutral (gate mathematically locked out)
- ~09:30Z: edward Cell D (β₂=0.98) terminal → Cell E (β₂=0.99) sequential
- ~11:00-12:00Z: fern Phase 2 n=4 terminal → MERGE DECISION on β₁=0.70 mechanism
- ~11:00-12:00Z: fern Phase 2 n=4 terminal → merge if statsig passes

## Research Themes

**Primary goal:** Stack orthogonal mechanisms onto lr_mlp=0.055 base to push below ffs=3125. Target: ffs=3100 → 3075 → beyond.

**Active mechanism threads:**
- **AdamW aux β₁ (fern):** β₁=0.70 shows 1.8σ signal → Phase 2 confirm in flight ⭐ highest priority
- **AdamW aux β₂ (edward):** β₂ sweep in progress
- **LR schedule (thorfinn):** cooldown_frac sweep — first-ever on this stack
- **lm_head LR (alphonse):** slight favorable trend at lr=0.010; 0.030 pending
- **Muon WD (askeladd):** fresh sweep, wd never touched; Cell A in flight
- **Muon nesterov (frieren):** JUST ASSIGNED — hardcoded True never ablated; 2-cell decisive test
- **Muon mu (tanjiro):** mu=0.85 clean-negative; mu=0.90 in flight

**Exhausted mechanism slots:**
- lr_embed=0.80 (frieren, clean-neutral, mean=3.270251 n=6)
- NS5 polynomial space (askeladd, clean-neutral, flat around (2,-1.5,0.5))
- SOAP attn eigvec smoothing (thorfinn, clean-neutral)
- SOAP β₂ cold-start warmup (edward, clean-neutral)
- Q/K shared Gram (fern, clean-neutral)
- AdamW eps sweep (alphonse, clean-neutral)
- Per-layer LR decay (nezuko, clean-negative)
- NS5 iteration count (askeladd, clean-neutral)
- SOAP attn Gram damping (fern, clean-neutral)
- AGC λ=0.03 (nezuko, Phase 2 trial 0/1 both ~3.272, effectively dead)
- Cautious-Muon, Lookahead, SWA, z-loss, gradient centralization, label smoothing, depth-init, per-head SOAP, schedule-free Muon, polynomial schedule-free Muon, SOAP β₂ cooldown annealing — all closed

**Candidate next hypotheses (unassigned):**
- Separate lr_attn sweep on new stack (PR #209 was clean-negative at old baseline)
- Spectral/orthogonal QKV weight init
- Adam β₂ schedule ramp over training
- Per-group lr_embed × lr_lm_head 2D joint confirm (after alphonse sweep completes)
- NS5 + AGC compound (if both β₁ and AGC confirm)
- Muon mu sweep under Polyak (if frieren Cell B nesterov=False wins, pair with tanjiro results)
