# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-18 17:10 UTC (boot 142x — wave-3 harvest + new assignments)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Alphonse (`gd103cc`) + tanjiro (`gd125a8`) still broken since. Issue #164 esc#15 posted 17:00 UTC. Operator silent ~70h+.
- **Branch state:** Baseline post-PR #310 (MuonH inner LR warmup=100, merged boot 142w).

## ⭐ Current baseline (post-PR #310 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27315** (n=4 mean) |
| `ffs` (primary) | **3125** (best trial; mean 3143.75) |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| MuonH LR warmup | warmup_steps=100, shape=linear |
| Outer wrapper | MuLoCo (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| Aux AdamW | betas=(0.8, 0.95), eps=1e-10, AGC clip_ratio=0.05 |
| Cooldown | MuonH=cosine frac=1.0, aux=linear frac=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| W&B confirm | `w6xgiqzl` (n=4 multi-trial) |

**Merge bar**: μ_val < 3.27315 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004. Conservative bar: μ < 3.27275.

**⚠️ CRITICAL**: ALL new experiment commands must include `--aux_agc_clip_ratio 0.05 --muonh_cooldown_shape cosine --muonh_warmup_steps 100`.

## Active experiments (boot 142x — 17:10 UTC 2026-05-18)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#329** | askeladd | **AGC inner MuonH clip=0.05 n=4 confirm** | `dpabql6o` trial 3/4 mid-flight (step ~10848/13300 at 16:54 UTC). n=2 mean ≈ 3.27237 (trial 0=3.27209, trial 1=3.27264). **ETA ~18:08 UTC**. Conservative bar μ<3.27275 needs last 2 trials to average ≤ 3.27311. Strong candidate for merge. |
| **#361** | nezuko | **Aux lm_head LR sweep** (1/200, 1/320, 1/500) | Arms 1+2 done: 1/200=3.27234, 1/320=3.27226. Arm 3 (1/500, qlkifdse) running step ~207/3325 at 16:59 UTC. **ETA ~18:30 UTC**. Arms 1+2 borderline-pass n=1 (Δ≈−0.0009), but also "control" (1/320=default aux lr) matches arm 1 — suggests sensitivity is flat in this range. Await arm 3 before decision. |
| **#389** | edward | **MuonH inner mu warmup** (0/100/200 steps) | Freshly assigned 16:45 UTC. Student will pick up on next poll. |
| **#390** | frieren | **MuLoCo outer optimizer class swap** (SGDM/AdamW/Lion) | Freshly assigned 17:10 UTC. Bold direction after saturating all 3 MuLoCo knobs. |
| **#391** | thorfinn | **MuonH warmup duration sweep** (100/200/300 steps) | Freshly assigned 17:10 UTC. Natural extension of PR #310 win. |
| **#392** | fern | **Logit soft-cap** (off/cap=15/cap=30) | Freshly assigned 17:10 UTC. First architectural change for fern; Gemma/Llama-style. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED 70h+** — `gd125a8` bf16 NaN. Esc#15 posted 17:00 UTC. |
| **#190** | alphonse | **NS5 iter count sweep** | **POD-BLOCKED 70h+** — needs_rebase, `gd103cc`. Esc#15 posted 17:00 UTC. |

**8/8 students assigned.** No idle slots.

## Wave-3 harvest summary (16:52–17:10 UTC 2026-05-18)

Closed 4 NEG PRs this wave:

| PR | Student | Best arm | Δ vs baseline 3.27315 | n=1 bar cleared? | Verdict |
|---|---|---|---|---|---|
| **#369** edward | MuLoCo outer_lr schedule | fixed 0.7 (ctrl)=3.27195 | n/a | Decay=+0.003, Grow missed target | **CLOSED NEG** |
| **#365** frieren | sync_interval scheduling | fixed 30 (ctrl)=3.27352 | Δ=+0.00037 vs baseline | No | **CLOSED NEG** |
| **#370** thorfinn | warmup shape | sqrt=3.27307 | Δ=−0.00008 | No | **CLOSED NEG** |
| **#352** fern | cooldown_frac | frac=0.4=3.27253 | Δ=−0.00062 | No | **CLOSED NEG** |

Key mechanistic insight from this wave: **MuLoCo's {outer_lr, outer_momentum, sync_interval} 3-knob space is fully saturated.** Both the outer_lr scheduling (PR #369) and sync_interval scheduling (PR #365) are NEG — the predicted mechanism (more drift integration late) was confirmed by delta_rms traces, but fixed outer_lr=0.7 at 2× larger Δ overshoots the cooldown attractor. The co-optimized {0.7, 30, 0.5} triplet appears to be a tight local minimum resistant to one-knob perturbation.

### Current win pipeline

| Source | Best result | n=4 ETA | Status |
|---|---|---|---|
| **Askeladd AGC inner clip=0.05** `dpabql6o` | n=2 mean ≈ 3.27237 | ~18:08 UTC | **ACTIVE n=4 confirm, trial 4 in flight** |
| **Nezuko lm_head LR sweep** | Arm 2 1/320=3.27226, arm 1 1/200=3.27234 | ~18:30 UTC (arm 3) | Arms 1+2 borderline-pass but control also near-baseline; likely flat |

## MERGED this round (chronological)

| PR | Student | Result |
|---|---|---|
| **#114** | frieren | MuLoCo × MuonH-SI MERGED — val=3.27585 (n=4) |
| **#237** | edward | AGC aux clip=0.05 MERGED — val=3.27469 (n=4) |
| **#243** | frieren | MuonH-SI cosine cooldown MERGED — val=3.27415 (n=4) |
| **#310** | thorfinn | **MuonH inner LR warmup=100 MERGED** — val=**3.27315** (n=4). **Current baseline.** |

## Closed this round (NEG, chronological)

| PR | Student | Result |
|---|---|---|
| #222 nezuko | cooldown_frac sweep | NEG |
| #217 tanjiro | sync_interval sweep | NEG |
| #247 askeladd | Gradient Centralization | NEG |
| #253 thorfinn | NS5 fp32 | NEG |
| #257 fern | AdEMAMix aux | NEG |
| #260 tanjiro | outer_momentum sweep | NEG |
| #265 nezuko | SF MuonH | NEG |
| #282 askeladd | EMA tail averaging | NEG |
| #284 thorfinn | AGC-outer | NEG |
| #292 fern | depth-LR scaling | NEG |
| #294 nezuko | NS5-outer blocks-only | NEG |
| #296 askeladd | Outer Lookahead | NEG |
| #308 edward | MuonH mu_final decay | NEG |
| #325 fern | aux cooldown shape | NEG |
| #326 nezuko | NS5-outer muon_update_style | STRONG NEG |
| #328 frieren | outer_momentum cosine decay | NEG |
| #338 edward | Aux AdamW LR warmup | STRONG NEG |
| **#352 fern** | aux cooldown_frac sweep | **NEG (this round)** |
| **#365 frieren** | sync_interval scheduling | **NEG (this round)** |
| **#369 edward** | outer_lr schedule (decay/grow) | **NEG (this round)** |
| **#370 thorfinn** | MuonH warmup shape | **NEG (this round)** |

## Saturated levers (confirmed, do not re-test)

- **MuonH-SI HPs**: lr=0.018, mu=0.95, wd=0 — confirmed optimal
- **MuonH cooldown**: cosine frac=1.0 now BASELINE
- **MuonH LR warmup**: linear warmup=100 now BASELINE; shape (linear/cosine/sqrt) insensitive; warmup=300 diverges; warmup=200/300 in test (PR #391)
- **MuonH mu_final decay**: catastrophic NEG
- **Direction-modifiers**: Contra, Soft-Muon, Cautious, Lookahead — all NEG/NaN
- **NS5 polynomial**: (2,-1.5,0.5), 12 iter — confirmed; fp32 closed; k=8/12/16 blocked (alphonse #190 pod)
- **NS5 outer family**: blocks-only NEG; muon_update_style STRONG NEG
- **MuLoCo outer params**: 0.7/0.5/30 — ALL saturated (fixed optimal); scheduled variants all NEG
- **Aux optimizer Lion / AdEMAMix**: all NEG
- **Aux embed lr_mult**: 0.3 optimal
- **Aux betas**: (0.8, 0.95) optimal
- **Aux cooldown**: linear shape optimal; frac=0.4 baseline; frac range [0.3,0.5] flat
- **Aux LR warmup**: ALL groups uniform warmup CLOSED NEG
- **Gradient Centralization**: tensor + row both NEG
- **Schedule-Free MuonH**: incompatible with WSD
- **Per-layer depth-scaled LR**: sqrt + linear + inv_sqrt all NEG

## Research direction for next wave

**Plateau depth**: 4+ consecutive experiment rounds with no new merge after PR #310 (~6h ago). 20+ NEG PRs this boot. Plateau protocol escalation active.

**Direction pivot**: Move from optimizer-knob tuning to:
1. **Outer optimizer class** (frieren PR #390) — SGD-mom → AdamW/Lion
2. **Warmup duration extension** (thorfinn PR #391) — 100 → 200/300 steps
3. **Architectural changes** (fern PR #392, tanjiro PR #298, alphonse PR #190 when pods fixed) — logit soft-cap, residual rescaling, NS5 iter count
4. **Pending confirmation** — askeladd #329 (AGC inner n=4, ~18:08 UTC)

**Upcoming critical path**:
- ~18:08 UTC: askeladd dpabql6o terminal — merge candidate if n=4 mean < 3.27275
- ~18:30 UTC: nezuko arm 3 (1/500) terminal — close #361 if flat; consider 1/320-only n=4 confirm
- Fresh hypothesis wave needed for next boot: QK-Norm, outer AdamW fine-tuning, NS polynomial coefficient sweep, SAM/sharpness-aware inner, learnable position encoding
