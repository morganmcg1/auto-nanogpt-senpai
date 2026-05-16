# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 00:00 UTC (boot 61)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** — second re-rotation requested on Issue #164.
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

## Active experiments (boot 61 — 00:00 UTC 2026-05-17)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#207** | frieren | MuLoCo outer_lr sweep {0.3, 0.7, 1.5} | **NEWLY ASSIGNED** — tune MuLoCo outer_lr at new baseline |
| **#174** | askeladd | NS5 A3 (2.5,-2.5,0.75) × MuLoCo stack n=4 | **SENT BACK** — rebase + smoke + n=4 confirm |
| **#200** | edward | Param EMA decay sweep {0.99, 0.995, 0.999} | **NEWLY ASSIGNED** (awaiting pickup) |
| **#183** | fern | Aux AdamW betas sweep (0.8,0.95)/(0.9,0.999)/(0.95,0.99) | Screen arm 1 (b1=0.8, b2=0.95) running ~step 1200/3325 |
| **#182** | thorfinn | Lookahead × MuonH-SI (k=0/5/10) | k=0 screen running ~step 2775/3325 |
| **#191** | tanjiro | Aux embed lr_mult sweep {0.15, 0.3, 0.5} | mult=0.15 ✓ NEGATIVE (3.2810, ffs=-1); mult=0.3 running ~step 775 |
| **#192** | nezuko | Aux AdamW cooldown_frac sweep {0.2, 0.4, 0.6} | No screen runs visible yet — student may be implementing CLI flag |
| **#190** | alphonse | NS5 iteration count sweep k∈{8,12,16} | **BLOCKED** — pod still NaN on rotated node `gd103cc`, re-rotation requested |

**8/8 students assigned.** Alphonse blocked by infra.

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
- **Direction-modifiers** (Contra, Soft-Muon, Cautious): all NEGATIVE or NaN under SI

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

## Next-priority watch points

1. **Thorfinn k=0 screen terminal** (~00:20 UTC): if baseline-clone, launch k=5 and k=10
2. **Fern arm 1 terminal** (~01:30 UTC): if baseline-clone, launch arm 2 (0.9, 0.999)
3. **Askeladd A3 × MuLoCo smoke** (~01:00 UTC): verify stack is stable
4. **Tanjiro mult=0.3 terminal** (~02:00 UTC): expect baseline-clone, then launch mult=0.5
5. **Issue #164 response**: alphonse pod 2nd re-rotation
