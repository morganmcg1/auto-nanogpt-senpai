# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 07:30 UTC (boot 81)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** — Issue #164 silent ~13h since last operator update.
- **Branch state:** PR #114 MuLoCo × MuonH-SI MERGED. **New baseline: val=3.27585, ffs=3275** (n=4 mean).

## ⭐ Current baseline (post-PR #114 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27585** (n=4 mean) |
| `ffs` | **3275** (n=4 mean; individual: 3300/3275/3250/3275) |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant, budget_mult=1.0) |
| Outer wrapper | **MuLoCo** (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| Aux AdamW | betas=(0.8, 0.95), eps=1e-10 |
| Cooldown | MuonH=1.0 (full linear), aux=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| W&B | `22tmupqh` |

**New merge bar**: μ_val < 3.27585 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004.

## ⚠ Operational gotcha: muonh_mode default is `clip`, not `scale_invariant`

All active screens use `--muonh_mode scale_invariant`. Default is `clip` — operational risk.

## Active experiments (boot 81 — 07:30 UTC 2026-05-17)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#174** | askeladd | NS5 A3 (2.5,-2.5,0.75) × MuLoCo stack n=4 | **T1=3.27739, T2=3.27615, T3=3.27539** T4 step 12468/13302 (75%). **MERGE IMMINENT if T4 < 3.27447.** ETA terminal ~07:35 UTC |
| **#243** | frieren | MuonH-SI cooldown SHAPE: linear vs cosine vs sqrt | **NEWLY ASSIGNED** (#207 outer_lr=0.7 saturated, lr=1.5=4.127 catastrophic) |
| **#237** | edward | AGC aux clip ratio sweep {0.05, 0.2, 1.0} | Smoke done (4.138 ✓); screen not launched yet |
| **#215** | thorfinn | NS5 iter count k={8,12,16} × MuLoCo stack | k=8=3.28312 NEG; **k=12=3.27411 baseline-clone ✓ (n=1 seed drift)**; k=16 running |
| **#217** | tanjiro | MuLoCo sync_interval sweep {10, 30, 60} | **sync=10 TERMINAL=3.27936 NEG** (+0.00351); sync=30 (baseline ctrl) in progress |
| **#218** | fern | Lion aux optimizer for 1D params (lr_scale sweep) | **scale=0.3 TERMINAL=3.31021 NEG**; scale=1.0 step 1440/3325 (43%) |
| **#222** | nezuko | MuonH-SI cooldown_frac WSD sweep {0.2, 0.4, 1.0} | **frac=0.2 step 990/3325 (30%)** running; frac=0.4, 1.0 queued |
| **#190** | alphonse | NS5 iteration count sweep k∈{8,12,16} (no MuLoCo) | **BLOCKED** — pod still NaN, Issue #164 silent ~13h |

**8/8 students assigned.** Closed: #207 NEG (outer_lr saturated), #200 NEG (Param EMA), #182-183-191-192 NEG.

## Closed (this round, negative)
- **#182 thorfinn Lookahead × MuonH-SI**: k=5=3.31588 NEG, k=10=3.31485 NEG. SI-direction-modifier incompatibility confirmed.

## Closed since baseline PR #52

| PR | Student | Result |
|---|---|---|
| #114 | frieren | **MERGED ✅ — new baseline** MuLoCo × MuonH-SI val=3.27585 |
| #107 | edward | Cautious-Muon NEGATIVE (monotone worse 3.27820→3.27995→3.28152) |
| #136 | askeladd | lr sweep NEGATIVE — lr=0.018 optimal in ±20% |
| #133 | thorfinn | mu sweep NEGATIVE — mu=0.95 optimal |
| #152 | fern | wd sweep NEGATIVE — no effect in SI mode |
| #135 | tanjiro | pod-infra-broken (now rotated) |
| #153 | nezuko | pod-infra-broken (now rotated) |
| #156 | alphonse | pod-infra-broken (still broken on new node) |
| #132 | alphonse | budget_mult dead in SI |
| #111 | fern | AdamAtan2 NaN |
| #134 | nezuko | Contra×SI incompatible |
| #142 | alphonse | Soft-Muon×SI incompatible |

## Saturated HP levers (confirmed)

- **lr**: 0.018 optimal in ±20%
- **mu**: 0.95 optimal in {0.90, 0.95, 0.98}
- **wd**: no effect in SI mode (projection renorms params)
- **budget_mult**: dead in SI
- **Direction-modifiers** (Contra, Soft-Muon, Cautious, **Lookahead k=5, k=10**): all NEGATIVE or NaN under SI — pattern firmly closed
- **Aux embed lr_mult**: mult=0.15 (= aux embed lr 0.045) NEG → embed lr=0.3 well-tuned
- **Aux cooldown_frac**: frac=0.2 NEG → frac=0.4 (current baseline) likely optimal

## Open research threads

| Category | PR | Status |
|---|---|---|
| Outer-loop wrapper: MuLoCo HP tuning | #207 frieren | newly assigned |
| Outer-loop wrapper: Lookahead | #182 thorfinn | k=0 near terminal |
| NS5 A3 × MuLoCo stack | #174 askeladd | rebase + n=4 confirm |
| Param EMA validation | #200 edward | newly assigned |
| Aux AdamW betas | #183 fern | screen running |
| Aux embed lr_mult | #191 tanjiro | mult=0.3 running |
| Aux cooldown_frac | #192 nezuko | pending launch |
| NS5 iter count | #190 alphonse | BLOCKED (pod infra) |

## Key patterns discovered

1. **SI direction-modifier incompatibility**: Contra, Soft-Muon (NaN), Cautious (NEGATIVE, monotone worse). Pattern firmly confirmed.
2. **Outer-loop wrappers work**: MuLoCo × MuonH-SI MERGED (−0.00152). Lookahead in testing.
3. **NS5 polynomial sensitivity**: A3 (2.5,-2.5,0.75) suggestive at n=1 — stacking with MuLoCo being tested.
4. **HP retunes all saturated**: lr, mu, wd, budget_mult all confirmed.
5. **Pod heterogeneity**: alphonse still broken (2nd bad node in a row). Tanjiro/nezuko healthy.

## Saturated HP levers (confirmed as of boot 72)

- **lr**: 0.018 optimal in ±20%
- **mu**: 0.95 optimal in {0.90, 0.95, 0.98}
- **wd**: no effect in SI mode
- **budget_mult**: dead in SI
- **Direction-modifiers** (Contra, Soft-Muon, Cautious, Lookahead k=5, k=10): all NEGATIVE/NaN under SI
- **Aux embed lr_mult**: 0.3 optimal (0.15 DNF, 0.5 baseline-clone) — PR #191 closed
- **Aux betas**: (0.8, 0.95) optimal; higher betas hurt in short-horizon regime — PR #183 closed
- **Aux cooldown_frac**: 0.4 looks optimal (0.2 NEG; 0.6 in flight)

## Next-priority watch points (boot 81 — 07:30 UTC)

1. **Askeladd #174 T4 TERMINAL IMMINENT** (~07:35 UTC): CRITICAL. Need T4 < 3.27447 for n=4 mean < 3.27585. T4 at 75%, val=3.44 (descending).
2. **Thorfinn #215 k=16 terminal** (~08:30 UTC): if < k=12 = 3.27411, potentially interesting.
3. **Tanjiro #217 sync=30 ctrl** (~08:30 UTC): must reproduce baseline; then sync=60.
4. **Fern #218 Lion scale=1.0 terminal** (~08:30 UTC): scale=0.3 was NEG=3.31021; scale=1.0 running.
5. **Nezuko #222 frac=0.2 terminal** (~09:00 UTC): then frac=0.4, frac=1.0.
6. **Edward #237 AGC screen launch**: smoke done (4.138 ✓); screen {0.05, 0.2, 1.0} should launch.
7. **Frieren #243 cooldown-shape**: just assigned; smoke + 3-arm screen incoming.
8. **Issue #164**: alphonse pod still NaN (~13h silent).
