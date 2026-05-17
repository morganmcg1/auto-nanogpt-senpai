# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 03:35 UTC (boot 72)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** — Issue #164 silent ~5h since last escalation.
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

## Active experiments (boot 72 — 03:35 UTC 2026-05-17)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#207** | frieren | MuLoCo outer_lr sweep {0.3, 0.7, 1.5} | lr=0.3 = 3.31220 **catastrophic NEG (+0.036)**; lr=0.7 (ctrl) running step 425/3325 (~05:00 UTC terminal); lr=1.5 queued. Duplicate `vbrd1fpp` crashed/killed at 03:14 UTC. |
| **#174** | askeladd | NS5 A3 (2.5,-2.5,0.75) × MuLoCo stack n=4 | Trial 1 TERMINAL val=3.2774, ffs=3300 (matches PR#114 t0); trial 2 step 1876/3325 (56%); full ETA ~05:30-06:00 UTC |
| **#200** | edward | Param EMA decay sweep {0.99, 0.995, 0.999} | decay=0.99 TERMINAL final=3.28424 (best=3.2781 mid-run) **NEG-on-final**; decay=0.995 running step 1750 (~04:15 UTC terminal); 0.999 queued |
| **#183** | fern | Aux AdamW betas sweep | All 3 arms TERMINAL — (0.8,0.95)=3.27848 ctrl, (0.9,0.999)=3.28250 NEG, (0.95,0.99)=3.28020 NEG. **NEG saturated**, awaiting SENPAI-RESULT marker. |
| **#215** | thorfinn | NS5 iter count k={8,12,16} × MuLoCo stack | Smoke `uwiuzv1j` PASS (val=4.145 at step 300). **DUPLICATE smokes detected 03:24/03:31 UTC — pinged student to kill and proceed to screen.** |
| **#191** | tanjiro | Aux embed lr_mult sweep {0.15, 0.3, 0.5} | All 3 arms TERMINAL — mult=0.15=3.28100 NEG, mult=0.30=3.27840 ctrl, mult=0.50=3.27850 ctrl. **NEG saturated**, awaiting SENPAI-RESULT marker. |
| **#192** | nezuko | Aux AdamW cooldown_frac sweep {0.2, 0.4, 0.6} | frac=0.2 NEG; frac=0.4 = 3.27830 baseline-clone; frac=0.6 running step 2250/3325 (68%, ~04:05 UTC terminal) |
| **#190** | alphonse | NS5 iteration count sweep k∈{8,12,16} (no MuLoCo) | **BLOCKED** — pod still NaN on broken node `gd103cc`, Issue #164 silent ~5h |

**8/8 students assigned.** #182 closed NEGATIVE. Thorfinn reassigned to #215. Pending closes: #191 tanjiro (NEG), #183 fern (NEG) — both awaiting student SENPAI-RESULT marker.

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

## Next-priority watch points (boot 72 — 03:35 UTC)

1. **Tanjiro/Fern SENPAI-RESULT markers** (any moment): all 3 arms NEG for each → close NEG-informative, assign fresh hypothesis to each
2. **Thorfinn #215 duplicate cleanup**: kill duplicate smokes, proceed to 3-arm screen k∈{8,12,16}
3. **Edward decay=0.995 terminal** (~04:15 UTC): if also NEG-on-final, close #200 after 0.999
4. **Nezuko frac=0.6 terminal** (~04:05 UTC): expected ~3.276-3.277 baseline-clone; close #192 NEG
5. **Frieren lr=0.7 terminal** (~05:00 UTC): expected baseline-clone (this IS PR #114 baseline); then launch lr=1.5
6. **Askeladd n=4 full confirm terminal** (~05:30-06:00 UTC): decisive test of A3 × MuLoCo. Trial 1 = 3.2774 — needs μ < 3.27585 to merge
7. **Issue #164 response**: alphonse pod still broken, ~5h silent

## Pending student responses (no action required from advisor)

- #191 tanjiro: needs to post SENPAI-RESULT marker
- #183 fern: needs to post SENPAI-RESULT marker
- #215 thorfinn: needs to kill duplicate smokes and start screen
- #207 frieren: duplicate already killed ✓ (vbrd1fpp crashed); lr=0.7 progressing
