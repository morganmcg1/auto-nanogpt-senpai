# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-18 ~08:35Z (poll #155)
- **Current baseline:** mu=3.271362, std=0.001181, n=6 (PR #162 merged)
  - ffs_mean=3141.67, ffs_best=3125. Statsig: `(3.271362 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.269362 | n=6: mu ≤ 3.269729 | n=8: mu ≤ 3.269948

## ⭐ Active Hot Signals

1. **FERN PR #318 Phase 2 n=4 IN FLIGHT** (highest-priority experiment, but **gate now ~lockout**):
   - Cell A single (β₁=0.70): val=3.269202 ffs=3125
   - Phase 2 run `53l16b0z` (group `g1r5-fern/adam-beta1-confirm`): step 6974/13000 at 07:10Z (~54%)
   - **Trial 1 done: val=3.270602 ffs=3125**
   - **Trial 2 done: val=3.272171 ffs=3150** (regression continues; mean T1+T2 = 3.271387, above baseline)
   - Trial 3 in flight (~470 steps in)
   - **Remaining T3+T4 need mean ≤ 3.267338** to hit n=4 gate — that's ~3.4σ below baseline, very challenging
   - ETA Phase 2 n=4 terminal: ~11:30-12:30Z May 18

2. **EDWARD PR #320 Phase 2 n=4 IN FLIGHT** ⭐:
   - Cell D (β₂=0.98) `hfn1clh2`: **val=3.268718 ffs=3125** (~2.24σ below baseline) — WINNER
   - Cell E (β₂=0.99) `mhnv5jxr`: **val=3.270318 ffs=3125** (terminal 07:36Z) — weaker
   - Phase 2 n=4 directive posted at β₂=0.98. Statsig gate: mean ≤ 3.269362
   - Cell D single (3.268718) is -0.000644 below gate — regression-to-mean will push n=4 mean toward gate

## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #349 | nezuko | AdamW aux WD sweep wd_aux ∈ {0, 0.01, 0.05, 0.10, 0.20} | Cell A `alp238rf` step 1081/3250 in flight. **Concurrent-runs incident resolved**: duplicate `d61h2gj6` crashed/killed. |
| #306 | alphonse | lm_head LR Phase 2 n=4 | Phase 2 run `7xl5rcjb` step 1243/13000, ETA terminal ~13:30Z |
| #318 | fern | Adam β₁ Phase 2 n=4 confirm | Phase 2 `53l16b0z` β₁=0.70 step 6974/13000. T1=3.270602 (ffs=3125), T2=3.272171 (ffs=3150). Gate now needs T3+T4 mean ≤ 3.267338. ETA terminal ~11:30Z |
| #320 | edward | Adam β₂ Phase 2 n=4 | Cell D (β₂=0.98) val=3.268718 ffs=3125 ⭐ winner; Cell E (β₂=0.99) val=3.270318 ffs=3125 terminal. **Phase 2 n=4 at β₂=0.98 launched (directive posted 07:35Z).** |
| #353 | thorfinn | LR warmup sweep warmup_steps ∈ {0, 50, 100, 200, 400} | JUST ASSIGNED 08:32Z. PR #321 closed clean-neutral: bowl-shaped curve, default cd=0.70 optimal (Cell A=0.50 +2.4σ, C=ctrl, D=0.80 +1.4σ, E=0.90 +2.5σ). |
| #323 | tanjiro | Muon mu sweep | Cell A mu=0.85 neg; Cell B mu=0.90 neg; Cell C ctrl mu=0.95 done; **Cell D mu=0.97 val=3.275570 ffs=3175 clean-neg ~3.6σ**; Cell E (mu=0.99) directive posted 08:08Z |
| #334 | askeladd | Muon WD sweep | Cell A wd=0 DNR catastrophic; Cell D wd=0.05 done; Cell E (`katqhx5q`, wd=0.10) step 1001/3250, ETA ~09:00Z |
| #346 | frieren | Muon attn LR sweep lr_attn ∈ {0.025, 0.035, 0.045, 0.055, 0.075} | Cell A (`v8b4l4ed`, lr_attn=0.025) step 158/3250 launched. ETA ~07:55Z |

## Closed This Session (poll #126-137)

- **PR #228 (frieren lr_embed=0.80 n=6 extension):** CLOSED clean-neutral ~03:15Z. Mean=3.270251, gate fails by 0.000522 (~0.45σ).
- **PR #301 (askeladd NS5 polynomial):** CLOSED clean-neutral ~02:45Z. Best val=3.27073 ffs=3125 (~0.5σ within noise).
- **PR #289 (tanjiro combo n=4):** CLOSED clean-neutral, mean=3.271485.
- **PR #264, #270** — closed earlier this session.

## Upcoming Decisions (~next 4-8h from 07:10Z)

- ~~**~07:30Z:** Nezuko P2 trial 4 terminal → close PR #283 clean-neutral~~ ✓ DONE 07:35Z
- ~~**~07:30Z:** Edward Cell E (β₂=0.99) terminal~~ ✓ DONE 07:36Z → Phase 2 n=4 at β₂=0.98 launched
- **~07:55Z:** Tanjiro Cell D (mu=0.97) terminal → Cell E (mu=0.99) sequential
- **~07:55Z:** Frieren Cell A (lr_attn=0.025) terminal → Cell B (ctrl 0.035) sequential
- **~08:30Z:** Thorfinn Cell E (cd=0.90) terminal → close PR #321 with verdict
- **~09:00Z:** Askeladd Cell E (wd=0.10) terminal → close PR #334 with verdict
- **~11:30-12:30Z:** Fern P2 n=4 terminal → **MERGE DECISION** on β₁=0.70 mechanism (likely clean-neutral given current trajectory)
- **~13:30Z:** Alphonse P2 n=4 terminal → MERGE DECISION on lm_head lr_lm_head

## Research Themes

**Primary goal:** Stack orthogonal mechanisms onto lr_mlp=0.055 base to push below ffs=3125. Target: ffs=3100 → 3075 → beyond.

**Active mechanism threads:**
- **AdamW aux β₁ (fern):** β₁=0.70 single = 1.8σ signal; Phase 2 confirm in flight ⭐ highest priority
- **AdamW aux β₂ (edward):** β₂=0.85 neg, β₂=0.95 ctrl, **β₂=0.98 best (3.268718 ffs=3125) Phase 2 n=4 in flight**, β₂=0.99 mild improvement (3.270318)
- **LR cooldown_frac (thorfinn, closed):** bowl-shaped, default cd=0.70 optimal. Now testing LR **warmup_steps** sweep (PR #353).
- **lm_head LR (alphonse):** monotone improvement to lr=0.030 (near-trigger); lr=0.100 in flight ⭐
- **Muon WD (askeladd):** wd=0 catastrophic, wd=0.05 in flight, wd=0.10 pending
- **Muon nesterov (frieren):** nesterov=True ctrl reproduces baseline; nesterov=False (Polyak) in flight
- **Muon mu (tanjiro):** mu=0.85 strong neg, mu=0.90 mild neg, mu=0.95 ctrl in flight; mu=0.97, 0.99 pending

**Exhausted mechanism slots:**
- lr_embed=0.80 (frieren, clean-neutral n=6)
- NS5 polynomial space (askeladd, clean-neutral)
- SOAP attn eigvec smoothing (thorfinn, clean-neutral)
- SOAP β₂ cold-start warmup (edward, clean-neutral)
- Q/K shared Gram (fern, clean-neutral)
- AdamW eps sweep (alphonse, clean-neutral)
- Per-layer LR decay (nezuko, clean-negative)
- NS5 iteration count (askeladd, clean-neutral)
- SOAP attn Gram damping (fern, clean-neutral)
- AGC λ=0.03 (nezuko, P2 confirmed dead, mean=3.272890 fails n=4 gate by ~3σ, closed PR #283)
- Cautious-Muon, Lookahead, SWA, z-loss, gradient centralization, label smoothing, depth-init, per-head SOAP, schedule-free Muon, polynomial schedule-free Muon, SOAP β₂ cooldown annealing — all closed

**Candidate next hypotheses (queue for next idle student):**
- Spectral/orthogonal QKV weight init
- Adam β₂ schedule ramp over training (low→high β₂ warmup)
- Per-group lr_embed × lr_lm_head 2D joint confirm (after alphonse sweep completes)
- NS5 + β₁=0.70 compound (if fern P2 confirms)
- Muon mu × nesterov 2D joint sweep (if frieren Cell B winner)
- AdamW aux WD (nezuko PR #349 now testing)
