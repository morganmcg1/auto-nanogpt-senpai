# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~03:30Z (poll #193)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536
  - OLD baseline (PR #162): mu=3.271362 (−2.89σ improvement; ffs 3100 vs 3141.67)

## ⭐ Active Hot Signals

1. **🔥 WD TIMING MECHANISM EXPLOITING IN 3 PARALLEL DIRECTIONS** 🔥:
   - **edward PR #422**: WD shape variants (lr_coupled/stable_only/early_dropoff) — Cell A ctrl ~68% step 2224 (`rb6d3w2o`)
   - **fern PR #423**: WD peak sensitivity (wd_mlp ∈ {0.0125→0.075}) — Cell A ctrl ~75% step 2434 (`lr28hw1g`)
   - **nezuko PR #427**: WD per-block decomposition (MLP vs attn contribution) — Cell A ctrl ~37% step 1210 (`t2to07q8`)

2. **LR / SOAP SCHEDULE EXPLORATION (2 active)**:
   - **thorfinn PR #426**: LR schedule shape — Cell A ctrl ~37% step 1213 (`pbz3gb1j`)
   - **frieren PR #428**: SOAP β₂ static sweep (0.80/0.85/0.90/0.95/0.98) — Cell A ctrl ~28% step 918 (`mzysmb1j`)

3. **TANJIRO PR #368 QKV ortho P2 — CLOSED clean-neutral** ✅:
   - n=4 mean=3.27250, ffs=3150 — +5.53σ vs NEW baseline. Gate failed. QKV init family closed.
   - **NEW: PR #432 tanjiro Muon nesterov ablation assigned** — testing whether nesterov=True matters after NS5.

4. **ALPHONSE PR #418 β corner sweep progressing**:
   - Cell A=3.27243 ffs=3150 (ctrl, `--wd_schedule constant`, OLD regime)
   - Cell B `2wut791f` running step ~700 (22%)
   - Any winning corner = P2 candidate requiring re-verification on NEW regime

5. **ASKELADD PR #398 ε-schedule sweep — 3 cells terminal, 2 to go**:
   - Cell A constant=3.26991 ffs=3125 (best; lucky seed)
   - Cell B ramp_up=3.27427 ffs=3175 (clean-NEG)
   - Cell C ramp_down=3.27108 ffs=3150 (clean-NEG)
   - Cell D spike_cooldown running step ~1143/3250 (35%)
   - Trend: ε schedule NOT improving. Close clean-neutral expected after D/E.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| #432 | tanjiro | Muon nesterov ablation (nesterov=True vs False after NS5) | **NEW** Cell A ctrl launching; 2-cell quick screen |
| #422 | edward | Muon WD shape variants (lr_coupled / stable_only / early_dropoff / constant-sanity) | Cell A ctrl ~95% step 3084 (); ~5 min to terminal |
| #423 | fern | WD peak sensitivity (wd_mlp ∈ {0.0125→0.075}) | **Cell A ctrl TERMINAL** val=3.265555 ffs=3075 (n=1 lucky seed −2.91σ NEW); Cell B running step 78 () |
| #427 | nezuko | Muon WD ramp_down per-block decomp (MLP vs attn contribution) | Cell A ctrl ~61% step 1981 () |
| #426 | thorfinn | LR schedule shape sweep | Cell A ctrl ~62% step 2015 () |
| #428 | frieren | SOAP β₂ static sweep (0.80/0.85/0.90/0.95/0.98) | Cell A on 4th attempt  running step 407 (13%); 3 prior kills — student briefed to commit code change |
| #418 | alphonse | AdamW aux (β₁, β₂) joint 2D corner sweep | Cell A=3.27243 terminal; Cell B () running step ~700 (22%) |
| #398 | askeladd | AdamW aux ε schedule sweep | A=3.26991, B=3.27427, C=3.27108 terminal; Cell D running step 1143 (); Cell E pending |


## Recent Closures (poll #193)

- **#368 tanjiro QKV ortho init P2** — CLOSED clean-neutral (poll #193). n=4 mean=3.27250 (+5.53σ). QKV init family closed.
- **#346 frieren lr_attn P2** — CLOSED clean-neutral. n=4 mean ~3.272631 (+5.69σ vs NEW baseline). lr_attn perturbation sub-noise.
- **#383 nezuko Muon grad noise** — CLOSED clean-negative (poll #185). Best +3.48σ.
- **#382 thorfinn per-group Muon mu** — CLOSED clean-neutral (poll #184). Default mu=0.95 optimal.


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. Target: ffs=3100 → 3075 → beyond.

**Active mechanism threads:**

- **WD schedule timing (WINNER PR #371):** Three simultaneous follow-ups testing dimensions of the breakthrough:
  - **edward #422**: shape variants (lr_coupled = stable WD + LR-coupled cooldown; stable_only = zero during cooldown; early_dropoff = reaches 0 at midpoint) — isolates which portion of ramp_down drives the win
  - **fern #423**: peak sensitivity (wd_mlp ∈ 0.0125→0.075) — is 0.05 peak optimal?
  - **nezuko #427**: per-block contribution (MLP vs attn) — which group carries the gain?

- **LR schedule shape (thorfinn #426):** New hypothesis: same "schedule shape matters" insight applied to LR axis. Tests stable_then_cosine, linear_throughout, cosine_throughout, stable_then_sq.

- **SOAP β₂ static sweep (frieren #428):** First time β₂ ∈ [0.80, 0.98] is directly swept in r5. Mechanism: preconditioner EMA half-life ranges from 3.1 to 34.3 steps; default β₂=0.90 may not be optimal for this 3250-step budget. All cells run with new WD ramp_down baseline config.

- **AdamW aux β-joint (alphonse #418):** Cell A ~65% done. Rebase before Cell B.

- **AdamW aux ε schedule (askeladd #398):** Cell C ~75% in flight, D/E auto-launching.

- **QKV ortho init (tanjiro #368 P2):** T3 ~85%, close clean-neutral imminently.

**Key insight from PR #371 breakthrough:**
WD *timing* is critically asymmetric: early-phase WD prevents bad optimization trajectories; late-phase WD (during cooldown) interferes with trajectory consolidation. A general principle: **the stable high-LR phase is the most regularization-sensitive window**. All WD follow-ups test variants of this axis; LR shape and SOAP β₂ test whether the same principle holds for those parameters.

**Exhausted mechanism slots (recent):**
- **Muon attn LR (frieren, closed PR #346 clean-neutral):** P2 n=4 mean ~3.2726 (+5.69σ vs NEW). lr_attn perturbation sub-noise at n=4.
- **Muon grad noise injection (nezuko, closed PR #383 clean-negative):** Best +3.48σ vs NEW. Mechanism direction correct but gap too large.
- **Per-group Muon mu (thorfinn, closed PR #382 clean-neutral):** Default 0.95 optimal.
- **AdamW aux β₁/β₂ schedules (edward #385, alphonse #381, closed clean-neutral)**
- **SOAP precond_freq static (askeladd #360, closed clean-neutral):** U-bowl, freq=16 optimal
- LR cooldown_frac sweep (closed, 0.70 optimal); LR warmup_steps (closed neg)
- AdamW aux wd_aux uniform (closed neg); Muon WD static sweep (closed neg)
- Cautious-Muon, SWA, z-loss, AGC, label smoothing, depth-init, per-head SOAP, schedule-free Muon — all closed (older)

**Candidate next hypotheses (queue for idle students):**
- **Muon nesterov=False screen** — untested in r5; clean ablation of a core Muon implementation choice
- **SOAP precond_freq upper tail {64, 128, 256}** — askeladd next when #398 closes
- **AdamW aux WD ramp_down coupling** — after nezuko #427 informs per-block picture
- **SOAP β₂ schedule (ramp)** — pending frieren #428 static sweep results
