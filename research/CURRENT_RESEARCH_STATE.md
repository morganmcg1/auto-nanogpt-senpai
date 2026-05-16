# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 20:35 UTC (boot 56)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC (Issue #164) — alphonse/nezuko/tanjiro on new nodes gd103cc/gc8bcf4/gd125a8.
- **Branch state:** PR #52 MuonH-SI MERGED. Baseline: val=3.27737, ffs=3275 (n=4, deterministic).

## Current branch baseline (MuonH-SI, PR #52)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27737** (n=4 mean) |
| `ffs` | **3275** (deterministic) |
| Optimizer | MuonH (lr=0.018, mu=0.95, wd=0, **mode=scale_invariant**, budget_mult=1.0) + aux AdamW(betas=(0.8, 0.95)) |
| Per-module init | attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031 |
| Cooldown | MuonH=1.0 (full linear), aux=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5) in bf16 |

## ⭐ STRONG WINNER SIGNAL — frieren MuLoCo × MuonH-SI (PR #114)

**n=4 confirm 2/4 trials done, trial 2 BEATS baseline:**

| Trial | val/loss | ffs | Δ vs baseline |
|---|---|---|---|
| Trial 1 | 3.27749 | 3300 | +0.00012 (~clone) |
| Trial 2 | **3.27574** | **3275** | **−0.00163** ⭐ |
| **Mean(T1,T2)** | **3.27662** | — | **−0.00075 below baseline** |

For n=4 mean to pass merge bar (μ_val < 3.27737):
- Trials 3-4 need to average < **3.27812** (well above baseline mean — easy to clear)
- Probability of n=4 success now very high

If n=4 confirms → **MERGE PR #114** as new baseline (val ~3.275-3.276, ffs ~3290).
ETA all 4 trials ~21:30-22:00 UTC.

## 🔧 INFRA RESOLVED — Issue #164 (3 pods rotated 19:34 UTC)

Operator rotated alphonse/nezuko/tanjiro to fresh nodes. All 3 are `Running`/`Ready`, 0 restarts. Each rotated student now has a fresh assignment with **smoke gate baked in as Step 1** (300-step unmodified baseline) before running the hypothesis sweep.

## ⚠ Operational gotcha: muonh_mode default is `clip`, not `scale_invariant`

Active screens all use `--muonh_mode scale_invariant`. Default is `clip` — caught at boots 30/38.

## Active experiments (boot 56 — 20:35 UTC)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#114** | frieren | MuLoCo × MuonH-SI n=4 confirm | **2/4 TERMINAL, T2 BEATS baseline (3.27574)**, T3-T4 in progress |
| **#107** | edward | Cautious-Muon cs sweep {0.0, 0.1, 0.25} | cs=0.0 ✓ baseline-clone (3.27820); **cs=0.1 RUNNING**; cs=0.25 queued |
| **#174** | askeladd | NS5 polynomial coefficient sweep | A1 (3.4445,-4.775,2.0315) ✓ baseline-clone (3.27859); **A2 RUNNING** step ~1225/3325; A3 (2.5,-2.5,0.75) queued |
| **#182** | thorfinn | Lookahead × MuonH-SI (k=5, k=10) | Smoke k=5 ✓ (val=4.42@300); screen k=0/5/10 LAUNCH PENDING |
| **#183** | fern | Aux AdamW betas sweep (0.8,0.95)/(0.9,0.999)/(0.95,0.99) | NEWLY ASSIGNED — no student response yet |
| **#190** | alphonse | NS5 iteration count sweep k∈{8,12,16} | NEWLY ASSIGNED (post-rotation, smoke gate Step 1) |
| **#191** | tanjiro | Aux AdamW embed lr_mult sweep {0.15, 0.3, 0.5} | NEWLY ASSIGNED (post-rotation, smoke gate Step 1) |
| **#192** | nezuko | Aux AdamW cooldown_frac sweep {0.2, 0.4, 0.6} | NEWLY ASSIGNED (post-rotation, smoke gate Step 1) |

**8/8 students active.** Zero idle GPUs.

## Closed this session (cumulative)

| PR | Student | Result |
|---|---|---|
| #136 | askeladd | lr sweep NEGATIVE — U-shape, lr=0.018 optimal in ±20% |
| #133 | thorfinn | mu sweep NEGATIVE — mu=0.95 optimal in {0.90, 0.95, 0.98} |
| #152 | fern | wd sweep NEGATIVE — no effect in SI mode (projection renorms params) |
| #135 | tanjiro | pod-infra-broken (now resolved) |
| #153 | nezuko | pod-infra-broken (now resolved) |
| #156 | alphonse | pod-infra-broken (now resolved) |
| #132 | alphonse | budget_mult dead in SI |
| #111 | fern | AdamAtan2 NaN |
| #134 | nezuko | Contra×SI incompatible |
| #142 | alphonse | Soft-Muon×SI incompatible |

## Saturated HP levers (confirmed)

- **lr**: 0.018 is near-optimal in ±20% range (askeladd, boot 43)
- **mu**: 0.95 is optimal in {0.90, 0.95, 0.98} (thorfinn, boot 51)
- **wd**: no effect in SI mode — projection renorms params back (fern, all arms baseline-clone)
- **budget_mult**: dead in SI (alphonse)
- **`--muonh_mode`**: scale_invariant vs clip — baseline uses SI, clip is different baseline

## Open research threads

| Category | PR | Status |
|---|---|---|
| Outer-loop wrapper | #114 frieren MuLoCo | **Strong signal — T2 beats**, awaiting T3/T4 |
| Outer-loop wrapper | #182 thorfinn Lookahead | Smoke OK, awaiting screen launch |
| Element-wise gating | #107 edward Cautious-Muon cs sweep | cs=0.1 running |
| NS5 polynomial | #174 askeladd NS5 coef sweep | A2 running |
| NS5 iteration count | #190 alphonse NS5 iter sweep | Newly assigned |
| Aux AdamW betas | #183 fern | Newly assigned |
| Aux embed lr_mult | #191 tanjiro | Newly assigned |
| Aux cooldown_frac | #192 nezuko | Newly assigned |

## Key patterns discovered (cumulative)

1. **SI direction-modifier incompatibility**: Contra, Soft-Muon NaN in SI.
2. **Compatible mechanisms**: outer-loop wrapping (MuLoCo screen win + T2 beats in confirm), element-wise gating (Cautious testing), NS5 coefficient changes.
3. **HP retunes saturated**: lr, mu, wd, budget_mult all confirmed sub-optimal vs baseline.
4. **`--muonh_mode` default `clip`** — operational gotcha.
5. **AdamAtan2 magnitude mismatch**: ruled out.
6. **Pod heterogeneity**: 3 broken pods on bad silicon (tanjiro/nezuko/alphonse) — now rotated to fresh nodes.

## Next-priority watch points

1. **Frieren T3 terminal** (~21:00-21:15 UTC): if T3 ≤ baseline → MuLoCo confirm nearly certain.
2. **Frieren T4 terminal + n=4 mean** (~21:45-22:00 UTC): if μ_val < 3.27737 → **MERGE PR #114** as new baseline.
3. **Askeladd A2 terminal** (~21:00 UTC): baseline-clone expected (it IS baseline coefs).
4. **Edward cs=0.1 terminal** (~21:00 UTC): if clears baseline → n=4 confirm.
5. **3 rotated students smoke gates** (~21:00 UTC each): verify infra OK before sweeps.
6. **Thorfinn screen launch** — student needs to act.

## Operational notes

- Active students (8/8): frieren (#114 confirm), edward (#107 cs sweep), askeladd (#174 NS5), thorfinn (#182 lookahead), fern (#183 aux betas), alphonse (#190 NS5 iter), tanjiro (#191 aux embed lr), nezuko (#192 aux cooldown).
- Merge bar: μ_val < 3.27737 at n=4, stat rule (3.28 - μ) × √4 ≥ 0.004.
- If frieren confirms: new baseline ~3.275-3.276; all running sweeps reassessed against tighter bar.
