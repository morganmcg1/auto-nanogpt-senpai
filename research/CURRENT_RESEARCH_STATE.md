# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-18 ~14:40Z (poll #165)
- **Current baseline:** mu=3.271362, std=0.001181, n=6 (PR #162 merged)
  - ffs_mean=3141.67, ffs_best=3125. Statsig: `(3.271362 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.269362 | n=6: mu ≤ 3.269729 | n=8: mu ≤ 3.269948

## ⭐ Active Hot Signals

1. **EDWARD PR #320 Phase 2 n=4 — T3 REGRESSED, gate now unreachable** ⬇️:
   - P2 run `mo3leb2y` step 12011/13000 (T4 in progress, ~70%)
   - T1=3.270414 (~-0.8σ); T2=3.269201 (~-1.83σ); **T3=3.272870 (~+1.28σ regression)**
   - Sum T1+T2+T3 = 9.812485; for n=4 gate T4 needs ≤ 3.264963 (~-5.4σ — **impossible**)
   - n=3 running mean = 3.27083 (-0.6σ, sub-statsig)
   - **Will close clean-NEUTRAL at T4 terminal**. β₂=0.98 has real trial-to-trial variance σ≈0.0014, Phase 1 was favorable seed.
   - ETA T4 terminal ~15:10Z

2. **FRIEREN PR #346 Cell A (lr_attn=0.025) HIT P2 TRIGGER** ⭐:
   - Cell A `orkpejsl` FINISHED: **val=3.269674 ffs=3125** (~−1.43σ below baseline)
   - Cell B ctrl `xovourxm` FINISHED: val=3.272 ffs=3150 (clean baseline reproduction)
   - DUPLICATE INCIDENT 12:25Z: `vqd4wcez` killed; Cell C `fmycgozs` (lr_attn=0.045) launched cleanly, step 403/3250
   - Sweep continuing through C/D/E before P2 promotion


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #349 | nezuko | AdamW aux WD sweep wd_aux ∈ {0, 0.01, 0.05, 0.10, 0.20} | Cell A ctrl: val=3.26944 ffs=3125. Cell B (wd_aux=0.01): val=3.27403 ffs=3175 (+2.3σ). Cell C (wd_aux=0.05): val=**3.29135 ffs=-1 (target NEVER reached)**. MONOTONE worse. **Advisor directed SKIP D/E, submit for review** (clean-NEG close pending). |
| #381 | alphonse | AdamW aux β₂ schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | NEW ASSIGNMENT (PR #381 created). Cell A constant ctrl pending launch. |
| #371 | fern | Muon WD schedule sweep ∈ {constant, ramp_up, ramp_down, triangle, cosine_updown} | Cell A constant ctrl FINISHED: val=3.2716 ffs=3150 (+0.20σ). Cell B `u01fl5oh` (ramp_up) step 3024/3250 (~93%) val/best=3.3084 — HIGH, terminal ~8min, possible over-regularization at 2×WD endpoint. |
| #320 | edward | Adam β₂ Phase 2 n=4 | P2 `mo3leb2y` step 12011/13000 (T4 ~70%). T1=3.270414, T2=3.269201, **T3=3.272870 REGRESSED**. n=3 mean=3.27083 (-0.6σ, sub-statsig). Statsig gate unreachable. Close clean-neutral at T4 terminal ~15:10Z. |
| #353 | thorfinn | LR warmup sweep warmup_steps ∈ {0, 50, 100, 200, 400} | Cell C `nj3fqbk8` (warmup=100) FINISHED clean-NEG: val=3.2803 ffs=-1 (target never reached, +7.5σ). Advisor directed: SKIP D/E (warmup=200/400 will miss target worse); retry Cell A; close with partial data if A crashes again. |
| #368 | tanjiro | Orthogonal QKV init sweep qkv_init ∈ {default, ortho_unit, ortho_scaled, ortho_v_only, ortho_qk_only} | Cell A ctrl: val=3.2703 ffs=3125 (-0.9σ). Cell B (ortho_unit gain=1.0): val=3.27268 ffs=3150 (+1.1σ, clean-neg). Cell C ortho_scaled pending launch. |
| #360 | askeladd | SOAP precond_freq sweep ∈ {4, 8, 16, 32, 64} | Cell A freq=4 FINISHED: val=3.2757 ffs=3175 (+3.6σ clean-neg). Cell B freq=8 FINISHED: val=3.2776 ffs=3200 (+5.3σ clean-neg). Cell C freq=16 ctrl launching. Monotone WORSE with more frequent refresh — default freq=16 is local optimum. |
| #346 | frieren | Muon attn LR sweep lr_attn ∈ {0.025, 0.035, 0.045, 0.055, 0.075} | ⭐ Cell A (0.025): val=3.26967 ffs=3125 (P2 trigger -1.43σ). Cell B ctrl (0.035): val=3.27206 ffs=3150. Cell C (0.045): val=3.27203 ffs=3150 (~baseline). Cell D (0.055), E (0.075) pending. Trend: 0.025 best so far. |

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
- **lm_head LR (alphonse, CLOSED #306 clean-neutral):** monotone P1 inverted-U at lr=0.030 (-0.87σ n=1), but Phase 2 n=4 mean=3.2711925 misses gate. Now testing **AdamW aux β₂ time-varying schedule** (PR #381).
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
- lr_lm_head=0.030 (alphonse, closed PR #306 clean-neutral: monotone Phase 1 inverted-U at lr=0.030 (-0.87σ n=1), Phase 2 n=4 mean=3.2711925 misses gate by 12×. Endpoint-LR sweeps look promising at n=1 but don't survive n=4 — pattern matches frieren lr_embed=0.80 #228)
- Cautious-Muon, Lookahead, SWA, z-loss, gradient centralization, label smoothing, depth-init, per-head SOAP, schedule-free Muon, polynomial schedule-free Muon, SOAP β₂ cooldown annealing — all closed

**Candidate next hypotheses (queue for next idle student):**
- Per-group Muon mu (mu_mlp vs mu_attn) — student suggestion from #323 close
- Adam β₂ ramp schedule (ASSIGNED to alphonse PR #381 — schedule-shape question, orthogonal to edward static β₂)
- Muon mu × nesterov 2D joint sweep (if frieren lr_attn sweep reveals a winner)
- AdamW aux β₁ ramp schedule (analogous to β₂ schedule; test whether β₁ timing matters)
