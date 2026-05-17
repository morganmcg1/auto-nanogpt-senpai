# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 17:22 UTC (boot 110)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** — Issue #164 re-escalation #5 posted 17:22 UTC. Pod degrading (NaN at step 25).
- **Branch state:** PR #114 MuLoCo × MuonH-SI MERGED. **Baseline: val=3.27585, ffs=3275 (n=4 mean).**

## ⭐ Current baseline (post-PR #114 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27585** (n=4 mean) |
| `ffs` | **3275** (n=4 mean) |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| Outer wrapper | MuLoCo (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| Aux AdamW | betas=(0.8, 0.95), eps=1e-10 |
| Cooldown | MuonH=1.0 (full linear), aux=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| W&B | `22tmupqh` |

**Merge bar**: μ_val < 3.27585 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004.

## ⚠ Operational gotcha: muonh_mode default is `clip`, not `scale_invariant`

All active screens must use `--muonh_mode scale_invariant`. Default is `clip`.

## ⭐⭐ Strong WIN candidates in-flight (n=4 confirm)

1. **Edward AGC clip=0.05** (#237): n=1=**3.27382**, trial 1=**3.2738** ✓, trial 2=**3.2757** ✓. Trial 3 in-progress (~step 7400). Interim n=2 mean=**3.27475** — already passes stat rule (Δ=-0.00110, (3.28-3.27475)×√2=0.0074 ≥ 0.004). ETA full n=4 ~20:15 UTC.
2. **Frieren cosine cooldown** (#243): n=1=**3.2746** (Δ=-0.00125 vs baseline). n=4 confirm `qupprvwc` at step ~3125/3325 (trial 1 near terminal). ETA trial 1 terminal ~17:25 UTC.

If BOTH confirm at n=4: stacks cleanly (AGC=aux gradient clip; cosine=MuonH LR shape — orthogonal mechanisms). Combined Δ ≈ -0.002 to -0.003 vs baseline.

## Active experiments (boot 110 — 17:22 UTC 2026-05-17)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#294** | nezuko | **NS5-outer velocity** (NS5-orthogonalize outer velocity direction before MuLoCo pull) | Newly assigned 17:22 UTC |
| **#292** | fern | **Per-layer depth-scaled MuonH LR** (sqrt/linear/inv_sqrt, normalized mean=1.0) | Newly assigned 17:18 UTC |
| **#284** | thorfinn | **AGC-outer** (Trust-region clip on MuLoCo outer update, clip_frac∈{0.02, 0.05, 0.10}) | clip=0.02 `pkjdpomh` step 1650 val=4.08 — likely hitting kill gate at step 3000 (~17:50) |
| **#282** | askeladd | EMA tail averaging (Polyak-Ruppert, decay∈{0.999, 0.9995, 0.9999}) | decay=0.999 `g3qng1yg` ~terminal, val=3.38 mid-cooldown; arms 2+3 pending |
| **#260** | tanjiro | MuLoCo outer_momentum sweep {0.3, 0.5, 0.9} | mom=0.3=3.2776 NEG; mom=0.5=3.2750 (baseline clone); **mom=0.9 `me1zrslw` DIVERGED** (val=6.59 step 2370) — kill gate ~17:35 |
| **#243** | frieren | MuonH-SI cooldown shape cosine n=4 confirm | `qupprvwc` trial 1 near terminal (~17:25) |
| **#237** | edward | AGC aux clip=0.05 n=4 confirm | trial 1=3.2738, trial 2=3.2757, trial 3 in-progress |
| **#190** | alphonse | NS5 iter count sweep | **BLOCKED** — Issue #164 (pod `gd103cc` broken, degrading, re-escalation #5 at 17:22 UTC) |

**8/8 students assigned.** No idle slots.

## Closed this round

| PR | Student | Result |
|---|---|---|
| **#265** | nezuko | **SF MuonH CLOSED NEG** — WSD × Schedule-Free fundamentally incompatible. Option (1) terminal=3.5171; option (2) smoke=4.63 (worse than baseline 4.14). Polyak averaging dilutes WSD final-phase descent. |
| **#257** | fern | **AdEMAMix aux CLOSED NEG** — alpha=2/5/8 all NEG (3.2891/3.3112/3.3362). Monotonic worsening. Slow-EMA mixing counterproductive under rapid MuonH convergence. |
| **#253** | thorfinn | **NS5 fp32 CLOSED NEG** — bf16 noise-floor hypothesis FALSIFIED. Entire NS5-quality lever bank closed. |
| **#247** | askeladd | Gradient Centralization CLOSED NEG — tensor+row both NEG. NS5 already neutralizes the lever. |
| **#222** | nezuko | cooldown_frac sweep CLOSED NEG — frac=1.0 optimal (saturated) |
| **#217** | tanjiro | sync_interval sweep CLOSED NEG — sync=30 optimal (saturated) |

## Saturated levers (confirmed, do not re-test)

- **MuonH-SI HPs**: lr=0.018, mu=0.95, wd=0 — confirmed optimal
- **Direction-modifiers**: Contra, Soft-Muon, Cautious, Lookahead k=5/10 — all NEG/NaN
- **budget_mult**: dead in SI mode
- **NS5 polynomial**: A2=(2,-1.5,0.5) — closed; fp32 also closed
- **NS5 iter count**: k=12 optimal in bf16
- **MuLoCo outer_lr**: 0.7 optimal (0.3 NEG, 1.5 catastrophic)
- **MuLoCo sync_interval**: 30 optimal (10 NEG, 60 NEG)
- **MuLoCo outer_momentum**: 0.5 optimal (0.3 NEG, 0.9 DIVERGES)
- **Aux optimizer Lion**: all scale values NEG — structural mismatch
- **Aux embed lr_mult**: 0.3 optimal
- **Aux betas**: (0.8, 0.95) optimal
- **Aux cooldown_frac**: 1.0 optimal for MuonH; 0.4 for aux
- **Aux AdEMAMix (alpha=2/5/8)**: all NEG
- **Gradient Centralization**: tensor + row both NEG
- **Schedule-Free MuonH**: fundamentally incompatible with WSD

## Key patterns discovered

1. **SI direction-modifier incompatibility**: Contra, Soft-Muon, Cautious, Lookahead — all NEG/NaN
2. **Outer-loop wrappers work**: MuLoCo × MuonH-SI MERGED (−0.00152)
3. **AGC on aux works** (n=4 partial, 2 trials: mean=3.27475 — already stat-significant)
4. **Cooldown SHAPE matters**: cosine=−0.00125 vs linear ctrl (n=4 confirm in-progress)
5. **NS5 quality levers exhausted**: polynomial + iter count + fp32 all closed
6. **MuLoCo outer_momentum = 0.5 confirmed optimal**: 0.3 NEG, 0.9 catastrophically diverges
7. **WSD × Schedule-Free incompatible**: Polyak-Ruppert average is antithetical to WSD final-phase descent

## Potential next research directions (post-current round)

1. **Stack AGC + cosine cooldown** if both confirm — first compound-baseline run (~17:25 UTC trial-1 frieren; ~20:15 UTC edward n=4)
2. **AGC-outer** (#284 thorfinn) — in-flight; clip=0.05 predicted best arm after clip=0.02 likely killed
3. **NS5-outer velocity** (#294 nezuko) — in-flight; single-arm screen
4. **Per-layer depth-scaled LR** (#292 fern) — in-flight; sqrt/linear/inv_sqrt
5. **EMA tail with faster decay** (decay=0.99/0.995) — if current askeladd screen NEG, faster EMA may focus on late-cooldown phase only
6. **SGDR warm restarts** — only pursue if frieren cosine confirms (it's the natural extension)
7. **Compound baseline run** — stack all confirmed wins once AGC+cosine merge
