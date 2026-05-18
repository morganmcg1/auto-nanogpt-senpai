# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-18 ~10:50Z (poll #160b)
- **Current baseline:** mu=3.271362, std=0.001181, n=6 (PR #162 merged)
  - ffs_mean=3141.67, ffs_best=3125. Statsig: `(3.271362 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.269362 | n=6: mu ≤ 3.269729 | n=8: mu ≤ 3.269948

## ⭐ Active Hot Signals

1. **FRIEREN PR #346 Cell A (lr_attn=0.025) HIT P2 TRIGGER** ⭐ NEW 10:15Z:
   - `orkpejsl` FINISHED: **val=3.269674 ffs=3125** (~−1.43σ below baseline)
   - Single-trial gate met (val ≤ 3.270 AND ffs ≤ 3150)
   - Directed continuation of sequential sweep B/C/D/E before Phase 2 promotion (best cell wins)
   - ETA Cell E terminal ~14:00Z → Phase 2 decision at sweep close

2. **EDWARD PR #320 Phase 2 n=4 IN FLIGHT** ⭐:
   - Cell D (β₂=0.98) `hfn1clh2`: **val=3.268718 ffs=3125** (~2.24σ below baseline) — WINNER
   - P2 run `mo3leb2y` step 5130/13000 (T2 in progress, T1=3.270414 ffs=3125)
   - Statsig gate: n=4 mean ≤ 3.269362. T1 alone gives 3.270414 — needs T2-T4 mean ≤ 3.268678
   - ETA T4 terminal ~13:30Z

3. **FERN PR #318 Phase 2 n=4 TERMINAL IMMINENT** (**effectively locked out**):
   - `53l16b0z` step 12947/13000 (~99%) at 10:12Z — terminal within minutes
   - **T1=3.270602 / T2=3.272171 / T3=3.272746** (mean=3.271840, all above baseline)
   - T4 needs ≤ 3.261929 (~8σ below baseline) — effectively impossible
   - ETA close clean-neutral ~10:20Z

## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #349 | nezuko | AdamW aux WD sweep wd_aux ∈ {0, 0.01, 0.05, 0.10, 0.20} | Cell A ctrl `alp238rf` FINISHED: val=3.269438 ffs=3125 (clean baseline reproduction, -1.63σ). Cell B `mnbz5ep0` step 1114/3250 in flight. |
| #306 | alphonse | lm_head LR Phase 2 n=4 | Phase 2 run `7xl5rcjb` step 1243/13000, ETA terminal ~13:30Z |
| #371 | fern | Muon WD schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | JUST ASSIGNED 10:50Z. PR #318 (β₁=0.70 Phase 2) closed clean-neutral: n=4 mean=3.271540 (Δ=+0.000178, ~0.15σ), Phase 1 n=1 was favorable seed outlier. |
| #320 | edward | Adam β₂ Phase 2 n=4 | Cell D β₂=0.98 single=3.268718 ffs=3125 (winner); P2 n=4 `mo3leb2y` step 5130/13000 (T2 in progress). **T1=3.270414 ffs=3125 logged**. Statsig: needs T2-T4 mean ≤ 3.268678. |
| #353 | thorfinn | LR warmup sweep warmup_steps ∈ {0, 50, 100, 200, 400} | Cell A `4t70bt57` warmup=0 ctrl step 3036/3250 (~93%, terminal imminent). Cell B `wwbkl5ja` launched in parallel — concurrent-run advisory may apply. |
| #368 | tanjiro | Orthogonal QKV init sweep qkv_init ∈ {default, ortho_unit, ortho_scaled, ortho_v_only, ortho_qk_only} | JUST ASSIGNED 09:58Z. PR #323 (Muon mu) closed clean-neg: bowl-shape, default mu=0.95 confirmed optimal. mu=0.99 failed to reach target (+31.18σ). |
| #360 | askeladd | SOAP precond_freq sweep ∈ {4, 8, 16, 32, 64} | Cell A precond_freq=4 retry `w2mu6ddu` step 2166/3250 (~67%, past prior crash points at 477 and 6). Terminal ETA ~30 min. |
| #346 | frieren | Muon attn LR sweep lr_attn ∈ {0.025, 0.035, 0.045, 0.055, 0.075} | ⭐ Cell A (lr_attn=0.025) FINISHED: **val=3.269674 ffs=3125 (HIT P2 TRIGGER, -1.43σ)**. Sequential sweep continuing per directive — Cell B (ctrl) launching. |

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
- **AdamW aux β₁ (fern, CLOSED #318):** β₁=0.70 n=4 mean=3.271540 (Δ=+0.000178, Phase 1 signal was seed noise). Now testing **Muon WD schedule** (PR #371).
- **AdamW aux β₂ (edward):** β₂=0.85 neg, β₂=0.95 ctrl, **β₂=0.98 best (3.268718 ffs=3125) Phase 2 n=4 in flight**, β₂=0.99 mild improvement (3.270318)
- **LR cooldown_frac (thorfinn, closed):** bowl-shaped, default cd=0.70 optimal. Now testing LR **warmup_steps** sweep (PR #353).
- **lm_head LR (alphonse):** monotone improvement to lr=0.030 (near-trigger); lr=0.100 in flight ⭐
- **Muon WD (askeladd, closed):** bowl-shape, default wd=0.025 optimal (wd=0 +14.5σ, wd=0.05 +6.7σ, wd=0.10 +28σ). Now testing **SOAP precond_freq** (PR #360).
- **Muon nesterov (frieren):** nesterov=True ctrl reproduces baseline; nesterov=False (Polyak) in flight
- **Muon mu (tanjiro, CLOSED #323):** bowl-shape, default mu=0.95 optimal. mu=0.85 +3.67σ, mu=0.97 +3.56σ, mu=0.99 failed to reach target (+31.18σ). Now testing **QKV orthogonal init** (PR #368).

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
- Muon WD static sweep (askeladd, closed PR #334 clean-neg: bowl, default wd=0.025 optimal)
- Muon mu sweep (tanjiro, closed PR #323 clean-neg: bowl, default mu=0.95 optimal)
- AdamW aux β₁=0.70 (fern, closed PR #318 clean-neutral: n=4 mean=3.271540, Phase 1 n=1 was seed noise)
- Cautious-Muon, Lookahead, SWA, z-loss, gradient centralization, label smoothing, depth-init, per-head SOAP, schedule-free Muon, polynomial schedule-free Muon, SOAP β₂ cooldown annealing — all closed

**Candidate next hypotheses (queue for next idle student):**
- Adam β₂ schedule ramp over training (low→high β₂ warmup)
- Per-group lr_embed × lr_lm_head 2D joint confirm (after alphonse sweep completes)
- Muon mu × nesterov 2D joint sweep (if frieren lr_attn sweep reveals a winner)
- Per-group Muon mu (mu_mlp vs mu_attn) — student suggestion from #323 close
