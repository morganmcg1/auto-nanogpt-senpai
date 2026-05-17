# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 20:38 UTC (boot 114)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** — Issue #164 re-escalation #6 posted 19:30 UTC (~24h since last operator update).
- **Branch state:** PR #114 MuLoCo × MuonH-SI MERGED. **Baseline: val=3.27585, ffs=3275 (n=4 mean).**

## ⭐ Current baseline (post-PR #237 merge — 2026-05-17 20:32 UTC)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27469** (n=4 mean) |
| `ffs` | **3262** (n=4 mean) |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| Outer wrapper | MuLoCo (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| **Aux AdamW** | betas=(0.8, 0.95), eps=1e-10, **AGC clip_ratio=0.05** |
| Cooldown | MuonH=1.0 (full linear), aux=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| W&B | `efgqupvv`, `hzxm8aaj`, `9l9le6dc`, `pwbrxwez` |

**Merge bar**: μ_val < 3.27469 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004.

**⚠️ CRITICAL**: `--aux_agc_clip_ratio 0.05` must be included explicitly in ALL new experiment commands — it defaults to 0.0.

## ⚠ Operational gotcha: muonh_mode default is `clip`, not `scale_invariant`

All active screens must use `--muonh_mode scale_invariant`. Default is `clip`.

## ⭐⭐ WIN CANDIDATE in-flight (n=4 confirm)

1. **Frieren cosine cooldown** (#243): trial 1=**3.2731** ✓ (Δ=-0.00159 vs NEW baseline 3.27469). Trial 3 in progress `qupprvwc` step 8152/13300. ETA terminal ~22:00 UTC. **Note: trial 1 beats new AGC baseline by 0.00159 — still a clear win if remaining trials hold.**

## Active experiments (boot 114 — 20:38 UTC 2026-05-17)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#308** | edward | **MuonH momentum β decay during cooldown** (muonh_mu_final∈{0.0, 0.5, 0.95}) | Newly assigned 20:35 UTC. Smoke pending. |
| **#298** | tanjiro | **Residual branch init rescale** (1/sqrt(2L) GPT-3 style) | Smoke broken 6× (val=10.82 NaN even on baseline-pure-smoke); second diagnostic posted 20:01 UTC. Pod may have corrupted state. |
| **#296** | askeladd | **Outer Lookahead** (k-step slow-snap, k∈{10,20}, α∈{0.5,0.9}) | k=10/α=0.5 `zp2yu879` running step 1025 val=3.77 healthy; k=5 arms CRASHED twice; advisor rerouted to k=10/α=0.9 + k=20/α=0.5 |
| **#294** | nezuko | **NS5-outer velocity** (NS5-orthogonalize outer velocity direction) | Screen `96zv1q8h` launched, early steps, val≈4.0 |
| **#292** | fern | **Per-layer depth-scaled MuonH LR** (sqrt/linear/inv_sqrt) | sqrt TERMINAL=3.2825 NEG; linear + inv_sqrt arms queued |
| **#284** | thorfinn | **AGC-outer** (clip_frac∈{0.02, 0.05, 0.10}) | clip=0.02 CRASHED 3.60; clip=0.05 `kjvo1gep` step 3125 val=3.4205 — near terminal, likely NEG |
| **#243** | frieren | MuonH-SI cosine cooldown n=4 confirm | trial 1=**3.2731** (Δ=-0.00159 vs new baseline ✓); trial 3 in progress step 8152/13300 |
| **#190** | alphonse | NS5 iter count sweep | **BLOCKED** — Issue #164 (pod `gd103cc` broken, re-escalation #6 at 19:30 UTC) |

**8/8 students assigned.** No idle slots.

## MERGED this round (chronological)

| PR | Student | Result |
|---|---|---|
| **#114** | frieren | **MuLoCo × MuonH-SI MERGED** — val=3.27585 (n=4), Δ=-0.00152 vs prior. Outer Nesterov SGD wrapper. |
| **#237** | edward | **AGC aux clip=0.05 MERGED** — val=**3.27469** (n=4), Δ=-0.00116 vs #114. AGC on aux AdamW. New baseline. |

## Closed this round (NEG)

| PR | Student | Result |
|---|---|---|
| **#265** | nezuko | **SF MuonH CLOSED NEG** — WSD × Schedule-Free fundamentally incompatible. |
| **#257** | fern | **AdEMAMix aux CLOSED NEG** — alpha=2/5/8 all NEG. Monotonic worsening. |
| **#282** | askeladd | **EMA tail averaging CLOSED NEG** — decay=0.999 val=3.368 (+0.092). WSD × averaging incompatible. |
| **#260** | tanjiro | **outer_momentum sweep CLOSED NEG** — 0.3=3.2776 NEG, 0.9=DIVERGED val=7.68. 0.5 confirmed optimal. |
| **#253** | thorfinn | **NS5 fp32 CLOSED NEG** — bf16 noise-floor hypothesis FALSIFIED. |
| **#247** | askeladd | Gradient Centralization CLOSED NEG — tensor+row both NEG. |
| **#222** | nezuko | cooldown_frac sweep CLOSED NEG — frac=1.0 optimal. |
| **#217** | tanjiro | sync_interval sweep CLOSED NEG — sync=30 optimal. |

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
