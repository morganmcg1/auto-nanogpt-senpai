# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 15:00 UTC (boot 105)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** — Issue #164 unanswered. Next re-escalation 16:30 UTC.
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

## ⭐⭐ Two parallel WIN candidates (in-flight confirmation)

1. **Edward AGC clip=0.05** (#237): n=1=**3.27382** (Δ=-0.00203). n=4 confirm `pwbrxwez` at **69% step 2300**, live. First-trial trajectory consistent with n=1 win. ETA full confirm ~17:30 UTC.
2. **Frieren cosine cooldown** (#243): n=1=**3.2746** (Δ=-0.00125 vs baseline, Δ=-0.003 vs linear ctrl). Sqrt arm `7z72ffcj` at **62% step 2070**, live, ~60 min to terminal. N=4 cosine confirm launches after sqrt arm reports.

If BOTH confirm: they stack (AGC=aux gradient clip; cosine=MuonH inner LR shape — orthogonal mechanisms). Combined Δ ≈ -0.002 to -0.003 vs baseline.

## Active experiments (boot 105 — 15:00 UTC 2026-05-17)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#282** | askeladd | **EMA tail averaging** (Polyak-Ruppert, decay∈{0.999, 0.9995, 0.9999}) | Newly assigned |
| **#265** | nezuko | Schedule-Free MuonH-SI (primal-dual, β∈{0.85, 0.9, 0.95}) | SF smoke=4.229 (explainable by averaging math); **screen β=0.85 `ofnnicf6` running** |
| **#260** | tanjiro | MuLoCo outer_momentum sweep {0.3, 0.5, 0.9} | mom=0.3=3.2776 NEG; **mom=0.5 `2r4cp0a2` at 17% step 570**; mom=0.9 queued |
| **#257** | fern | AdEMAMix aux (α sweep {2, 5, 8}) | alpha=5=3.3112 NEG; **alpha=2 `x35cudj5` at 51% step 1700**; alpha=8 queued |
| **#253** | thorfinn | NS5 fp32 accumulation (bf16 noise floor hypothesis) | bf16 ctrl=3.2762 baseline-clone ✓; **fp32 arm `dp2c1e9n` at 49% step 1620** |
| **#243** | frieren | MuonH-SI cooldown shape (linear/cosine/sqrt) | linear ctrl=3.2776 ✓; **cosine=3.2746 ⭐**; **sqrt `7z72ffcj` at 62%** |
| **#237** | edward | AGC aux clip=0.05 n=4 confirm | **n=4 `pwbrxwez` at 69% step 2300** |
| **#190** | alphonse | NS5 iter count sweep (k=8/12/16) | **BLOCKED** — Issue #164 (pod `gd103cc` broken) |

**8/8 students assigned.** No idle slots.

## Closed this round

| PR | Student | Result |
|---|---|---|
| **#247** | askeladd | Gradient Centralization (tensor/row) CLOSED NEG — off=3.27554 ctrl ✓, tensor=3.27764, row=3.27614. GC does not help MuonH-SI. |
| **#222** | nezuko | cooldown_frac sweep CLOSED NEG — frac=1.0 optimal (saturated) |
| **#217** | tanjiro | sync_interval sweep CLOSED NEG — sync=30 optimal (saturated) |

## Saturated levers (confirmed, do not re-test)

- **MuonH-SI HPs**: lr=0.018, mu=0.95, wd=0 — confirmed optimal
- **Direction-modifiers**: Contra, Soft-Muon, Cautious, Lookahead k=5/10 — all NEG/NaN
- **budget_mult**: dead in SI mode
- **NS5 polynomial**: A2=(2,-1.5,0.5) baseline — A3 in-noise; closed
- **NS5 iter count**: k=12 optimal in bf16; k=8 DNF, k=16 in-noise
- **MuLoCo outer_lr**: 0.7 optimal (0.3 NEG, 1.5 catastrophic)
- **MuLoCo sync_interval**: 30 optimal (10 NEG, 60 NEG)
- **MuLoCo outer_momentum=0.3**: NEG (sweep continuing for 0.5/0.9)
- **Aux optimizer Lion**: all scale values NEG — structural mismatch confirmed
- **Aux embed lr_mult**: 0.3 optimal
- **Aux betas**: (0.8, 0.95) optimal
- **Aux cooldown_frac**: 1.0 optimal for MuonH; 0.4 for aux
- **Gradient Centralization**: tensor + row both NEG (NS5 already neutralizes the lever)

## Key patterns discovered

1. **SI direction-modifier incompatibility**: Contra, Soft-Muon, Cautious, Lookahead — all NEG/NaN
2. **Outer-loop wrappers work**: MuLoCo × MuonH-SI MERGED (−0.00152)
3. **AGC on aux groups works** (pending n=4 confirm): clip=0.05=−0.00203 n=1
4. **Cooldown SHAPE matters** (pending sqrt + n=4): cosine=−0.00125 vs linear ctrl
5. **NS5 quality levers exhausted in bf16**: polynomial + iter count both closed; fp32 noise floor hypothesis under test (#253)
6. **Eval-side averaging untested**: Schedule-Free (nezuko #265) and EMA-eval (askeladd #282) both in flight — orthogonal approaches to same problem
7. **Pod heterogeneity**: alphonse blocked on `gd103cc` for 20+ hours

## Potential next research directions (post-current round)

1. **Stack AGC + cosine cooldown** if both confirm — first compound-baseline run
2. **AGC-outer**: extend confirmed AGC mechanism to MuLoCo outer update magnitude (H4 from research ideas)
3. **Per-layer depth-scaled Muon LR** (H3) — sqrt/linear depth scaling, orthogonal to current stack
4. **SGDR warm restarts** (H5) — after frieren's cosine vs linear closes
5. **NS5 fp32 follow-up**: if thorfinn #253 wins, revisit A3 polynomial and k=16 in fp32
6. **Outer velocity orthogonalization** (H1) — NS5 on MuLoCo outer velocity direction
