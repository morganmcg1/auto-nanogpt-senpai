# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-17 23:35 UTC (boot 131)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) healthy; **alphonse (`gd103cc`) STILL BROKEN** + tanjiro current pod showing bf16-NaN regression — Issue #164 escalation #7 posted 22:55 UTC 2026-05-17. No operator response since 19:34 UTC 2026-05-16.
- **Branch state:** Baseline post-PR #237 (AGC aux clip=0.05).

## ⭐ Current baseline (post-PR #237 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27469** (n=4 mean) |
| `ffs` | **3262** (n=4 mean) |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| Outer wrapper | MuLoCo (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| **Aux AdamW** | betas=(0.8, 0.95), eps=1e-10, **AGC clip_ratio=0.05** |
| Cooldown | MuonH=1.0 (full linear), aux=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| W&B confirm | `efgqupvv`, `hzxm8aaj`, `9l9le6dc`, `pwbrxwez` |

**Merge bar**: μ_val < 3.27469 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004.

**⚠️ CRITICAL**: `--aux_agc_clip_ratio 0.05` must be included explicitly in ALL new experiment commands.

## ⭐⭐ WIN CONFIRMED — awaiting student rebase

**Frieren cosine cooldown (#243)** — n=4 CONFIRMED at mean = **3.27415**, Δ=-0.00054 vs baseline, stat margin 0.01170 ≥ 0.004 ✓
- W&B: `5ehqbmwb`, `xw81lpch`, `7z72ffcj`, `qupprvwc`
- Trials: 3.27459 / 3.27306 / 3.27436 / 3.27460
- Sent back for rebase (advisor branch updated since branch creation). Waiting on student rebase + 1 n=1 rebase-confirm.

## Active experiments (boot 131 — 23:35 UTC 2026-05-17)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#310** | thorfinn | **MuonH inner LR warmup** (∈{0, 100, 300}) | arm 1 (warmup=0 control) terminal=**3.27636** within-noise; arm 2 (warmup=100) `qwl44doy` step 1050/3325 (~32%); arm 3 (warmup=300) queued |
| **#308** | edward | **MuonH mu_final cooldown sweep** (∈{0.0, 0.5, 0.95}) | arm 1 (mu_final=0.0) terminal=**3.3333** catastrophic NEG (Δ=+0.0586); arm 2 (mu_final=0.5) `8zf9t97s` step 630/3325 (~19%); diagnostic comment posted re: h_cooldown_frac_local=1.0 → mu decays over full training |
| **#298** | tanjiro | **Residual branch init rescale** (1/sqrt(2L)) | **POD-BLOCKED** — bf16 NaN pathology, 10/10 smoke runs NaN. Issue #164 esc #7 posted 22:55 UTC |
| **#296** | askeladd | **Outer Lookahead** (k-step slow-snap, k=5/10, α=0.5/0.9) | k=5 both arms CRASHED (pre-rebase); k=10/α=0.5 `9ikxvtih` terminal=**3.3236** NEG (Δ=+0.049); k=10/α=0.9 `3sip5vnl` just launched |
| **#294** | nezuko | **NS5-outer velocity orth.** | n=1 terminal=3.27673 (Δ=+0.00204, within seed noise). Sent back 22:16 UTC for blocks-only variation. Awaiting student rebase + `--ns5_outer_blocks_only` impl |
| **#292** | fern | **Per-layer depth-scaled MuonH LR** (sqrt/linear/inv_sqrt) | sqrt=**3.2825** NEG; linear=**3.3041** catastrophic NEG; inv_sqrt `9dzxcm9p` step 1660/3325 (~50%) |
| **#243** | frieren | **MuonH-SI cosine cooldown n=4 confirm** | **CONFIRMED WIN** (n=4 mean=3.27415, Δ=-0.00054). Awaiting rebase + n=1 rebase-confirm |
| **#190** | alphonse | NS5 iter count sweep | **POD-BLOCKED 25h+** — Issue #164 silent since 19:34 UTC 2026-05-16 |

**8/8 students assigned.** No idle slots.

## MERGED this round (chronological)

| PR | Student | Result |
|---|---|---|
| **#114** | frieren | **MuLoCo × MuonH-SI MERGED** — val=3.27585 (n=4), Δ=-0.00152 vs prior. Outer Nesterov SGD wrapper. |
| **#237** | edward | **AGC aux clip=0.05 MERGED** — val=**3.27469** (n=4), Δ=-0.00116 vs #114. AGC on aux AdamW. New baseline. |

## Closed this round (NEG)

| PR | Student | Result |
|---|---|---|
| **#284** | thorfinn | **AGC-outer CLOSED NEG** — clip=0.02 crashed val=3.60; clip=0.05 terminal=3.39 (+0.12). AGC scope mismatch. |
| **#265** | nezuko | **SF MuonH CLOSED NEG** — WSD × Schedule-Free fundamentally incompatible. |
| **#257** | fern | **AdEMAMix aux CLOSED NEG** — alpha=2/5/8 all NEG. |
| **#282** | askeladd | **EMA tail averaging CLOSED NEG** — decay=0.999 val=3.368 (+0.092). |
| **#260** | tanjiro | **outer_momentum sweep CLOSED NEG** — 0.3=NEG, 0.9=DIVERGED. 0.5 optimal. |
| **#253** | thorfinn | **NS5 fp32 CLOSED NEG** — bf16 noise-floor hypothesis FALSIFIED. |
| **#247** | askeladd | Gradient Centralization CLOSED NEG. |
| **#222** | nezuko | cooldown_frac sweep CLOSED NEG — frac=1.0 optimal. |
| **#217** | tanjiro | sync_interval sweep CLOSED NEG — sync=30 optimal. |

## Saturated levers (confirmed, do not re-test)

- **MuonH-SI HPs**: lr=0.018, mu=0.95, wd=0 — confirmed optimal
- **Direction-modifiers**: Contra, Soft-Muon, Cautious, Lookahead k=5/10 — all NEG/NaN
- **NS5 polynomial**: A2=(2,-1.5,0.5) — closed; fp32 also closed
- **NS5 iter count**: k=12 optimal in bf16
- **MuLoCo outer_lr/momentum/sync**: 0.7 / 0.5 / 30 confirmed optimal
- **Aux optimizer Lion / AdEMAMix**: all NEG
- **Aux embed lr_mult**: 0.3 optimal
- **Aux betas**: (0.8, 0.95) optimal
- **Aux cooldown_frac**: 1.0 optimal for MuonH; 0.4 for aux
- **Gradient Centralization**: tensor + row both NEG
- **Schedule-Free MuonH**: incompatible with WSD
- **Per-layer depth-scaled LR**: sqrt + linear both NEG (inv_sqrt in-flight; expected NEG)
- **MuonH mu_final cooldown decay**: mu_final=0.0 catastrophic NEG, mu schedule applied over full training not cooldown tail

## Patterns discovered (running)

1. **Outer-loop wrappers work**: MuLoCo × MuonH-SI MERGED (−0.00152), AGC aux MERGED (−0.00116), cosine cooldown CONFIRMED (-0.00054)
2. **Cooldown SHAPE matters; momentum decay doesn't**: cosine LR cooldown beats linear; but β momentum decay (mu_final=0.0) catastrophically hurts
3. **MuLoCo-outer slow-snap saturates**: layering another lookahead on outer-θ NEG (askeladd #296)
4. **Per-layer depth-LR all NEG so far**: sqrt + linear both NEG. Architecture's per-layer LR allocation already near-optimal under SI mode
5. **NS5-outer-velocity ~parity**: nezuko n=1=3.27673 within seed noise; blocks-only variation pending

## Potential next research directions (boot 131+)

After frieren cosine merges (next baseline ~3.27415):

1. **Stack: cosine + warmup** if thorfinn arm 2 (warmup=100) lands < baseline. Two orthogonal LR-shape levers may compound.
2. **MuLoCo outer-Nesterov vs heavy-ball** — current uses Nesterov, could test heavy-ball variant
3. **Aux LR shape sweep** — aux currently linear cooldown_frac=0.4; cosine on aux a fresh untouched lever
4. **MuonH-SI NS5 algorithmic variants** — different orthogonalization polynomials (e.g., Newton-Schulz-4, Newton-Schulz-7) at the same iter count
5. **AGC on inner gradient (MuonH)** — AGC scoped to MuonH inner step rather than aux; clip ratio could be different than 0.05
6. **Per-layer cooldown_frac variation** — vary cooldown_frac per layer (e.g., embed/lm_head different from blocks)
7. **NS5 (a,b,c) polynomial coefficients sweep at k=12** — fresh approach: try Higham-style alternatives like A2 vs A3 vs higher-order Padé approximations
8. **Compound run** — after another 1-2 winners, n=4 confirm compound stack to ensure no interaction surprises
