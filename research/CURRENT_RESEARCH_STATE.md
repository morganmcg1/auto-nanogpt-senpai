# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 05:55 UTC (boot 76)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** — Issue #164 silent ~11h since last operator update.
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

## Active experiments (boot 76 — 05:55 UTC 2026-05-17)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#207** | frieren | MuLoCo outer_lr sweep {0.3, 0.7, 1.5} | lr=0.3=3.31220 NEG; **lr=0.7=3.27569 baseline-clone** ✓; lr=1.5 step 875/3325 (26%, val=5.675 warmup) |
| **#174** | askeladd | NS5 A3 (2.5,-2.5,0.75) × MuLoCo stack n=4 | **T1=3.27739, T2=3.27615 (BELOW BASELINE!)** T3 step 2190/3325 (66%). n=2 mean=3.27677. ETA T3 ~06:30, T4 ~07:30 UTC |
| **#200** | edward | Param EMA decay sweep {0.99, 0.995, 0.999} | 0.99=3.28424 NEG; 0.995=3.28918 NEG; 0.999 step 2225/3325 (67%, terminal ~06:30 UTC) |
| **#215** | thorfinn | NS5 iter count k={8,12,16} × MuLoCo stack | **k=8 TERMINAL=3.28312 NEG-DNF**; k=12 step 270/3325 (8%); k=16 queued |
| **#217** | tanjiro | MuLoCo sync_interval sweep {10, 30, 60} | Smoke baseline=4.142 ✓; **sync=10 step 310/3325 (9%)**; sync=30, 60 queued |
| **#218** | fern | Lion aux optimizer for 1D params (lr_scale sweep) | scale=0.3 step 1410/3325 (42%); scale=1.0, 3.0 queued |
| **#222** | nezuko | MuonH-SI cooldown_frac WSD sweep {0.2, 0.4, 1.0} | Smoke baseline x2 = 4.15 ✓ (re-validated after code change); screen not launched yet |
| **#190** | alphonse | NS5 iteration count sweep k∈{8,12,16} (no MuLoCo) | **BLOCKED** — pod still NaN at step 25 (`5ctlikby` 04:33 UTC), Issue #164 silent ~11h |

**8/8 students assigned.** Closed: #182 NEG, #191 NEG, #183 NEG, #192 NEG. Fresh: #217, #218, #222.

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

## Next-priority watch points (boot 76 — 05:55 UTC)

1. **Askeladd #174 T3 terminal** (~06:30 UTC): **MOST CRITICAL** — T1=3.27739, T2=3.27615. For merge: (T3+T4)/2 ≤ 3.27493. T3 at step 2190/3325 (66%) — watch carefully.
2. **Askeladd #174 T4 terminal** (~07:30 UTC): final answer on A3 × MuLoCo merge eligibility.
3. **Frieren #207 lr=1.5 terminal** (~07:00 UTC): expected catastrophic NEG (symmetric to lr=0.3). Then close #207 → outer_lr=0.7 saturated.
4. **Thorfinn #215 k=12 terminal** (~07:50 UTC): expected baseline-clone (k=12 IS baseline); k=16 queued.
5. **Edward #200 decay=0.999 terminal** (~06:30 UTC): expected monotone-worse → close #200 NEG, Param EMA pattern firmly closed.
6. **Fern #218 Lion scale=0.3 terminal** (~07:30 UTC): then scale=1.0, scale=3.0.
7. **Tanjiro #217 sync=10 terminal** (~07:50 UTC): then sync=30 (baseline ctrl), sync=60.
8. **Nezuko #222 screen launch**: smoke gate just re-validated; screen {0.2, 0.4, 1.0} should launch soon.
9. **Issue #164**: alphonse pod still NaN at step 25 (degrading); ~11h silent from infra team.
