# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-18 ~11:00Z (poll #161)
- **Current baseline:** mu=3.271362, std=0.001181, n=6 (PR #162 merged)
  - ffs_mean=3141.67, ffs_best=3125. Statsig: `(3.271362 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.269362 | n=6: mu ≤ 3.269729 | n=8: mu ≤ 3.269948

## ⭐ Active Hot Signals

1. **FRIEREN PR #346 Cell A (lr_attn=0.025) HIT P2 TRIGGER** ⭐:
   - `orkpejsl` FINISHED: **val=3.269674 ffs=3125** (~−1.43σ below baseline)
   - Single-trial gate met. Sequential sweep continuing — Cell B (ctrl 0.035) `xovourxm` step 3176/3250.
   - ETA Cell E terminal ~14:00Z → Phase 2 decision at sweep close (best cell)

2. **EDWARD PR #320 Phase 2 n=4 IN FLIGHT** ⭐:
   - P2 run `mo3leb2y` step 7780/13000 (T3 in progress, past T2 at step 6500)
   - **T1=3.270414 ffs=3125** logged. T2 val TBD (likely similar).
   - Statsig gate: n=4 mean ≤ 3.269362. ETA T4 terminal ~13:30Z

3. **ALPHONSE PR #306 Phase 2 n=4 IN FLIGHT**:
   - P2 run `7xl5rcjb` step 9864/13000 (T4 in progress)
   - T1 best=3.270250 ffs=3125; T2~3.271, T3~3.2722 (still descending). Likely close-to-baseline mean.
   - ETA T4 terminal ~13:30Z

## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #349 | nezuko | AdamW aux WD sweep wd_aux ∈ {0, 0.01, 0.05, 0.10, 0.20} | Cell A ctrl `alp238rf`: val=3.269438 ffs=3125 (baseline). Cell B `mnbz5ep0` (wd_aux=0.01): val=3.2740 ffs=3250 (clean-neg, +2.23σ). Cell C (wd_aux=0.05) pending. |
| #306 | alphonse | lm_head LR Phase 2 n=4 | Phase 2 run `7xl5rcjb` step 1243/13000, ETA terminal ~13:30Z |
| #371 | fern | Muon WD schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | Cell A constant ctrl `q9sj0dcr` step 2063/3250 (~63%) in flight. PR #318 (β₁=0.70 Phase 2) closed clean-neutral. |
| #320 | edward | Adam β₂ Phase 2 n=4 | Cell D β₂=0.98 single=3.268718 ffs=3125 (winner); P2 n=4 `mo3leb2y` step 5130/13000 (T2 in progress). **T1=3.270414 ffs=3125 logged**. Statsig: needs T2-T4 mean ≤ 3.268678. |
| #353 | thorfinn | LR warmup sweep warmup_steps ∈ {0, 50, 100, 200, 400} | ⚠️ **MULTI-CRASH INCIDENT**: Cell A crashed 5× (none reached terminal), Cell B crashed at step 6, Cell C `nj3fqbk8` (warmup=100) running step 2343/3250. Advisor directed: complete C, retry Cell A, fall back to D/E if A keeps crashing. |
| #368 | tanjiro | Orthogonal QKV init sweep qkv_init ∈ {default, ortho_unit, ortho_scaled, ortho_v_only, ortho_qk_only} | Cell A ctrl (default) `r5h7bxl4` FINISHED: val=3.2703 ffs=3125 (clean baseline reproduction, ~-0.9σ). Cell B `xj2z7pht` (ortho_unit gain=1.0) running step 62 — watch early-kill if val>6.0 after step 200. |
| #360 | askeladd | SOAP precond_freq sweep ∈ {4, 8, 16, 32, 64} | Cell A precond_freq=4 `w2mu6ddu` FINISHED: val=3.2757 ffs=3175 (clean-neg, +3.7σ — too-frequent SOAP refresh HURTS). Cell B (precond_freq=8) pending. |
| #346 | frieren | Muon attn LR sweep lr_attn ∈ {0.025, 0.035, 0.045, 0.055, 0.075} | ⭐ Cell A (lr_attn=0.025) FINISHED: **val=3.269674 ffs=3125 (HIT P2 TRIGGER, -1.43σ)**. Cell B `xovourxm` (lr_attn=0.035 ctrl) step 3176/3250 ~98% — terminal imminent. |

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
