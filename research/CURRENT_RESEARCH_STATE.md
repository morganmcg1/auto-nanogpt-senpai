# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 12:55 UTC (boot 93)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** — Issue #164 silent ~16h, re-escalated 10:40 UTC.
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

## Active experiments (boot 93 — 12:55 UTC 2026-05-17)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#265** | nezuko | Schedule-Free MuonH-SI (primal-dual averaging, β∈{0.85, 0.9, 0.95}) | Assigned 12:55 UTC — smoke pending |
| **#260** | tanjiro | MuLoCo outer_momentum sweep {0.3, 0.5, 0.9} at outer_lr=0.7 sync=30 | Smoke ✓ 4.13998; mom=0.3 dpihyfo7 ~13% |
| **#257** | fern | AdEMAMix for aux (slow-EMA α sweep {2,5,8}) | Smoke ✓; alpha=5 woz337i3 ~51% (3.584); alpha=2/8 queued |
| **#253** | thorfinn | NS5 fp32 accumulation (bf16 noise-floor hypothesis) | Smokes ✓; bf16 ctrl 14g9fw3a ~46% (3.607); fp32 arm queued |
| **#247** | askeladd | Gradient Centralization for MuonH-SI inner (off/tensor/row) | off-ctrl TERMINAL=3.27554 ✓; tensor 0zqenfv8 ~82% (3.387) — dead arm, kill-gate at step 3000 imminent |
| **#243** | frieren | MuonH-SI cooldown SHAPE: linear vs cosine vs sqrt | linear=3.27755 baseline-clone ✓; cosine xw81lpch ~58% (3.513) tracking NEG; sqrt queued |
| **#237** | edward | AGC aux clip ratio sweep {0.05, 0.2, 1.0} | ⭐ **clip=0.05 TERMINAL=3.27382 (n=1, Δ=-0.00203)**; clip=0.2=3.27618 NEG; clip=1.0 ~70% (3.467) clearly NEG |
| **#190** | alphonse | NS5 iteration count sweep k∈{8,12,16} (no MuLoCo) | **BLOCKED** — pod NaN on gd103cc, Issue #164 ~18h silent, re-escalated 10:40 |

**8/8 students assigned.** Closed: #222 NEG (cooldown_frac=1.0 optimal), #217 NEG, #218 NEG, #215 NEG, #174 NEG, #207 NEG, #200 NEG, #182-192 NEG.

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

## Saturated HP levers (confirmed as of boot 85)

- **lr**: 0.018 optimal in ±20%
- **mu**: 0.95 optimal in {0.90, 0.95, 0.98}
- **wd**: no effect in SI mode
- **budget_mult**: dead in SI
- **Direction-modifiers** (Contra, Soft-Muon, Cautious, Lookahead k=5, k=10): all NEGATIVE/NaN under SI
- **Aux embed lr_mult**: 0.3 optimal (0.15 DNF, 0.5 baseline-clone) — PR #191 closed
- **Aux betas**: (0.8, 0.95) optimal; higher betas hurt in short-horizon regime — PR #183 closed
- **Aux cooldown_frac**: 0.4 looks optimal (0.2 NEG; 0.6 in flight)
- **NS5 polynomial (A1/A2/A3)**: A3=(2.5,-2.5,0.75) in-noise vs baseline A2=(2,-1.5,0.5) — n=4 mean 3.27625 missed bar by 0.0004
- **MuLoCo outer_lr**: 0.7 saturated (0.3 NEG, 1.5 catastrophic)
- **Param EMA**: all decay values NEG (monotone worse 0.99-0.999)

## Saturated/closed levers (additional, boot 87)

- **NS5 iter count**: k=12 optimal in bf16; k=8 NEG-DNF; k=16 in-noise vs k=12 (delta=0.00025 < trial spread) — PR #215 CLOSED
- **NS5 polynomial A3**: n=4 mean 3.27625 vs baseline 3.27585 — in-noise — PR #174 CLOSED
- **MuLoCo sync=10**: 3.2794 NEG; sync=30 baseline-clone 3.2742 confirmed; sync=60 in-flight
- **WSD frac=0.2**: 3.3831 NEG; frac=0.4 in-flight; frac=1.0 queued
- **Lion aux scale=0.3**: 3.3102 NEG; **scale=1.0**: 3.3232 NEG; scale=3.0 in-flight

## Key emerging pattern (boot 87)

Both NS5 quality levers (polynomial coefficients #174, iter count #215) closed NEG/in-noise. **Hypothesis: bf16 numerical noise floor is the actual NS5 ceiling**, not algorithmic design. This drives PR #253 (NS5 fp32) as the direct next test. If NS5 fp32 beats baseline, it reopen the polynomial + iter design space for follow-up — A3 and k=16 might benefit too.

## ⭐ Top result this round

**#237 edward AGC clip=0.05 = 3.27382 (n=1) — Δ=-0.00203 vs baseline 3.27585**. Real mechanism change (per-param adaptive grad clip on aux groups), not a baseline-clone. Single-trial below baseline mean; n=4 confirm needed. Awaiting clip=0.2 and clip=1.0 to complete the screen, then n=4 at best arm.

## Saturated — aux optimizer alternatives

- **Lion aux** (#218 ALL NEG monotonic): scale=0.3 (+0.034), scale=1.0 (+0.047), scale=3.0 (+0.152). Sign-only updates structurally incompatible with aux groups' gradient-scale heterogeneity.
- Pattern confirms aux groups specifically require /√v scale adaptation — next: AdEMAMix (#257 fern) keeps /√v + adds long-horizon momentum.

## Next-priority watch points (boot 93 — 12:55 UTC)

1. ⭐ **Edward #237 — clip=1.0 terminal imminent (~13:15 UTC)**: val=3.467 at 70% → clearly NEG. After terminal: edward should self-launch n=4 confirm at clip=0.05. Decision: n=4 μ < 3.27585, stat rule (3.28 − μ) × 2 ≥ 0.004.
2. **Frieren #243 cosine arm** (~58%, val=3.513 trending NEG): terminal ~14:00 UTC. Cosine tracking ~3.51 at 58% → likely to close NEG. sqrt arm queued — may cancel if cosine is clearly worse.
3. **Askeladd #247 tensor-GC kill gate**: at step 2730 val=3.387 >> kill threshold 3.285. Kill-gate at step 3000 imminent (~13:00). Expect student to kill. If not killed: ping. Row arm should follow (GC=off ctrl was baseline-clone; row-GC worth running).
4. **Tanjiro #260 mom=0.3** (~13%): converging normally. mom=0.5/0.9 follow sequentially.
5. **Nezuko #265 smoke** (just assigned): expected ~1h from now.
6. **Fern #257 alpha=5** (~51%): improving (3.584). alpha=2/8 queued.
7. **Thorfinn #253 bf16 ctrl** (~46%): fp32 arm queued after ctrl terminal.
8. **Issue #164 alphonse pod**: ~18h infra silence. Critical. Will re-escalate if no response by next boot.

## Saturated levers (full list)

- **MuonH-SI HPs**: lr=0.018, mu=0.95, wd=0 — all confirmed optimal
- **Direction-modifiers**: Contra, Soft-Muon, Cautious, Lookahead k=5/k=10 — all NEG/NaN
- **budget_mult**: dead in SI mode
- **NS5 polynomial**: A3 vs A2 in-noise (n=4 mean 3.27625 vs 3.27585) — closed
- **NS5 iter count**: k=12 optimal in bf16; k=8 DNF, k=16 in-noise — closed
- **MuLoCo outer_lr**: 0.7 optimal (0.3 NEG, 1.5 catastrophic)
- **MuLoCo sync_interval**: 30 optimal (10 NEG +0.00351, 60 NEG +0.00137) — PR #217 CLOSED
- **Aux optimizer Lion**: all scale values NEG monotonic — structural mismatch confirmed
- **Aux embed lr_mult**: 0.3 optimal
- **Aux betas**: (0.8, 0.95) optimal
- **Aux cooldown_frac**: 0.4 looks optimal (0.2 NEG); frac=1.0 in flight for final confirmation
- **Param EMA**: all decay values NEG
- **MuLoCo outer_momentum**: untested — being tested now (#260)

## Open research threads (ranked priority)

| Rank | Lever | PR | Rationale |
|---|---|---|---|
| 1 | ⭐ AGC aux clip=0.05 n=4 confirm | #237 edward | AWAITING clip=1.0 terminal then n=4 launch — best n=1 result in this round |
| 2 | NS5 fp32 precision | #253 thorfinn | bf16 noise-floor hypothesis; last NS5 lever untested |
| 3 | AdEMAMix aux | #257 fern | slow-EMA momentum for aux; keeps /√v, adds long-horizon info |
| 4 | MuLoCo outer_momentum | #260 tanjiro | {0.3, 0.5, 0.9}; never jointly tuned with outer_lr=0.7 |
| 5 | Schedule-Free MuonH-SI | #265 nezuko | paradigm shift: eliminate cooldown via primal-dual averaging |
| 6 | GC row mode | #247 askeladd | ctrl+tensor screens running; row is final arm |
| 7 | Cooldown SHAPE cosine/sqrt | #243 frieren | linear ctrl 3.2776 ✓; cosine tracking NEG; sqrt queued |
