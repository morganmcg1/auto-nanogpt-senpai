# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 09:35 UTC (boot 87)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** — Issue #164 silent ~13h, re-escalated 08:40 UTC.
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

## Active experiments (boot 87 — 09:35 UTC 2026-05-17)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#253** | thorfinn | NS5 fp32 accumulation (bf16 noise-floor hypothesis) | **NEWLY ASSIGNED** — follow-up to #215 NS5 iter saturated |
| **#247** | askeladd | Gradient Centralization for MuonH-SI inner (off/tensor/row) | Screen pr41c8ir off-mode step 30/3325 (1%) — just started |
| **#243** | frieren | MuonH-SI cooldown SHAPE: linear vs cosine vs sqrt | cosine arm jlnc9w1y terminal soon (~09:15 UTC); linear + sqrt arms pending; watching closely |
| **#237** | edward | AGC aux clip ratio sweep {0.05, 0.2, 1.0} | clip=0.05 efgqupvv step 3025/3325 (91%) val=3.310 — terminal ~09:15; clip=0.2 + 1.0 queued |
| **#217** | tanjiro | MuLoCo sync_interval sweep {10, 30, 60} | sync=10 TERMINAL=3.2794 NEG; sync=30 ctrl b56g5pss TERMINAL=3.2742 (baseline-clone); sync=60 grckndpv step 780/3325 (23%) |
| **#218** | fern | Lion aux optimizer for 1D params (lr_scale sweep) | scale=0.3 TERMINAL=3.3102 NEG; scale=1.0 TERMINAL=3.3232 NEG; scale=3.0 (bhpgxxp4) step 1920/3325 (58%) val=3.72 |
| **#222** | nezuko | MuonH-SI cooldown_frac WSD sweep {0.2, 0.4, 1.0} | frac=0.2 TERMINAL=3.3831 NEG; frac=0.4 zo06rxgl step 1328/3325 (40%); frac=1.0 queued |
| **#190** | alphonse | NS5 iteration count sweep k∈{8,12,16} (no MuLoCo) | **BLOCKED** — pod NaN on gd103cc, Issue #164 re-escalated 08:40 |

**8/8 students assigned.** Closed: #215 NEG-saturated (NS5 iter), #174 NEG (A3 polynomial), #207 NEG, #200 NEG, #182-192 NEG.

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

## Next-priority watch points (boot 87 — 09:35 UTC)

1. **Frieren #243 cosine cooldown terminal**: jlnc9w1y at 88%+ — terminal imminent. Cosine well-known to outperform linear in LM pretraining. Watch closely. If < 3.27585 single-trial, n=4 confirm before merge.
2. **Edward #237 AGC clip=0.05 terminal** (~09:15 UTC): step 91% val=3.31 — trending above baseline; then clip=0.2 and 1.0.
3. **Tanjiro #217 sync=60** (grckndpv step 23%): the interesting arm — if sync=60 < sync=30 (baseline), worth n=4.
4. **Nezuko #222 frac=0.4** (zo06rxgl step 40%): the critical arm — frac=0.4 IS the baseline config. Should reproduce 3.275. Then frac=1.0 (full WSD = full linear from warmup-end).
5. **Fern #218 Lion scale=3.0** (~11:00 UTC): last hope for Lion aux. Both 0.3 and 1.0 NEG; 3.0 running.
6. **Askeladd #247 grad-centralization**: pr41c8ir screen-off just started; expected terminal ~noon UTC.
7. **Thorfinn #253 NS5 fp32**: newly assigned, smoke gate pending.
8. **Issue #164**: alphonse pod still broken on gd103cc, re-escalated 08:40 UTC.
