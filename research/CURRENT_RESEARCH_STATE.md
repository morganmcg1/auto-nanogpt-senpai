# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 19:20 UTC (boot 51)
- **Most recent human-team directive:** None.
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

## INFRA ESCALATION: 3 broken pods (Issue #164)

**3 of 8 student pods (37.5%) are broken** — tanjiro, nezuko, alphonse — all NaN cascade on bare baseline (grad=0, NaN from step 25-125). No human response on Issue #164. Holding all 3 idle.

## ⚠ Operational gotcha: muonh_mode default is `clip`, not `scale_invariant`

Active screens all use `--muonh_mode scale_invariant`. Default is `clip` — caught at boots 30/38.

## ⭐ UNCERTAIN CONFIRM (boot 51) — frieren MuLoCo × MuonH-SI n=4

**n=4 confirm in progress** (run 22tmupqh):
- Trial 1 (DONE): val=**3.27749**, ffs=3300 — **marginally above baseline mean** (+0.00012)
- Trial 2 in progress: step ~2161/3325

For n=4 mean to pass merge bar (μ < 3.27737): trials 2-4 must average ≤ 3.27733.

The screen result was 3.27566 but trial 1 landed at 3.27749 — possible seed variance or optimistic screen. **Outcome uncertain**. ETA all 4 trials ~21:30 UTC.

## Active experiments (boot 51 — 19:20 UTC)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#114** | frieren | MuLoCo × MuonH-SI n=4 confirm | **RUNNING trial 2/4**, ETA ~21:30 UTC |
| **#107** | edward | Cautious-Muon cs sweep {0.0, 0.1, 0.25} | cs=0.0 ✓ baseline-clone; **cs=0.1 RUNNING** (step ~1350); cs=0.25 queued |
| **#152** | fern | MuonH wd sweep {1e-5, 5e-5, 1e-4} | wd=1e-5 baseline-clone; wd=5e-5 baseline-clone; **wd=1e-4 RUNNING step 3200 (~terminal)** |
| **#174** | askeladd | NS5 polynomial coefficient sweep A1-A3 | **A1 (3.4445,-4.775,2.0315) RUNNING step 2750** (~15 min to A1 terminal) |
| **#182** | thorfinn | Lookahead × MuonH-SI (k=5, k=10) | **NEWLY ASSIGNED** — smoke k=5, α=0.5 first |

## Closed this session (cumulative)

| PR | Student | Result |
|---|---|---|
| #136 | askeladd | lr sweep NEGATIVE — U-shape, lr=0.018 optimal in ±20% |
| #133 | thorfinn | mu sweep NEGATIVE — mu=0.95 optimal in {0.90, 0.95, 0.98} |
| #135 | tanjiro | pod-infra-broken |
| #153 | nezuko | pod-infra-broken |
| #156 | alphonse | pod-infra-broken |
| #132 | alphonse | budget_mult dead in SI |
| #111 | fern | AdamAtan2 NaN |
| #134 | nezuko | Contra×SI incompatible |
| #142 | alphonse | Soft-Muon×SI incompatible |

## Saturated HP levers (confirmed)

- **lr**: 0.018 is near-optimal in ±20% range (askeladd, boot 43)
- **mu**: 0.95 is optimal in {0.90, 0.95, 0.98} (thorfinn, boot 51)
- **wd**: no effect in SI mode — projection renorms params back (fern, 2/3 arms confirmed)
- **budget_mult**: dead in SI (alphonse)
- **`--muonh_mode`**: scale_invariant vs clip — baseline uses SI, clip is different baseline

## Open research threads

| Category | PR | Status |
|---|---|---|
| Outer-loop wrapper | #114 frieren MuLoCo | Confirm in progress (uncertain) |
| Outer-loop wrapper | #182 thorfinn Lookahead | Newly assigned |
| Element-wise gating | #107 edward Cautious-Muon cs sweep | cs=0.1 running |
| NS5 polynomial | #174 askeladd NS5 coef sweep | A1 running |
| wd ablation | #152 fern wd sweep | wd=1e-4 running (~terminal) |

## Key patterns discovered (cumulative)

1. **SI direction-modifier incompatibility**: Contra, Soft-Muon NaN in SI.
2. **Compatible mechanisms**: outer-loop wrapping (MuLoCo screen win), element-wise gating (Cautious testing), NS5 coefficient changes.
3. **HP retunes saturated**: lr, mu, wd, budget_mult all confirmed sub-optimal vs baseline.
4. **`--muonh_mode` default `clip`** — operational gotcha.
5. **AdamAtan2 magnitude mismatch**: ruled out.
6. **Pod heterogeneity**: 3 broken pods (tanjiro/nezuko/alphonse), same NaN signature.

## Next-priority watch points

1. **Fern wd=1e-4 terminal** (~19:24 UTC): expected baseline-clone or mildly negative → close #152.
2. **Askeladd NS5 A1 terminal** (~19:35 UTC): if A1 beats baseline-clone → interesting.
3. **Frieren n=4 trial 2 terminal** (~20:00 UTC): critical signal for MuLoCo confirm.
4. **Frieren n=4 all 4 trials** (~21:30 UTC): if μ < 3.27737 → MERGE; else close.
5. **Edward cs=0.1/0.25** (~20:30/21:00 UTC): cautious gating test.
6. **Thorfinn Lookahead smoke** (~19:45 UTC): new mechanism.

## Operational notes

- Active students (5): frieren (#114 confirm), edward (#107 cs sweep), askeladd (#174 NS5), thorfinn (#182 lookahead), fern (#152 wd=1e-4 terminal).
- Idle (broken pods): tanjiro, nezuko, alphonse — no infra response yet.
- Merge bar: μ_val < 3.27737 at n=4, stat rule (3.28 - μ) × √4 ≥ 0.004.
