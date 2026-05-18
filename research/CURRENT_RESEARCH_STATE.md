# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-18 02:55 UTC (boot 142c)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) initially healthy; **alphonse (`gd103cc`) broken since boot 130** + tanjiro (`gd125a8`) broken since boot 137. Issue #164 escalations #7/#8/#9/#10 posted. Operator silent ~54h since 19:34 UTC 2026-05-16.
- **Branch state:** Baseline post-PR #243 (MuonH-SI cosine cooldown, merged boot 142).

## ⭐ Current baseline (post-PR #243 merge)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27415** (n=4 mean) |
| `ffs` | **3150** (n=4 primary metric) |
| Optimizer | MuonH-SI (lr=0.018, mu=0.95, wd=0, mode=scale_invariant) |
| Outer wrapper | MuLoCo (outer_lr=0.7, outer_momentum=0.5, sync_interval=30) |
| **Aux AdamW** | betas=(0.8, 0.95), eps=1e-10, **AGC clip_ratio=0.05** |
| Cooldown | MuonH=**cosine** frac=1.0, aux=linear frac=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5), bf16 |
| W&B confirm | `5ehqbmwb`, `xw81lpch`, `7z72ffcj`, `qupprvwc` (n=4), `47cp8wal` (rebase-confirm) |

**Merge bar**: μ_val < 3.27415 at n=4. Stat rule: (3.28 − μ) × √4 ≥ 0.004.

**⚠️ CRITICAL**: ALL new experiment commands must include `--aux_agc_clip_ratio 0.05 --muonh_cooldown_shape cosine`.

## Active experiments (boot 142c — 02:55 UTC 2026-05-18)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#310** | thorfinn | **MuonH inner LR warmup** (∈{0, 100, 300}) | arm 2 (warmup=100) `qwl44doy` terminal=**3.27340** WIN candidate (Δ=-0.00075); arm 3 crashed NEG; smoke `zslelsf7` done (val=4.17 ✓) — **n=4 confirm pending (not yet launched)** |
| **#338** | edward | **Aux AdamW LR warmup** (aux_warmup_steps ∈{0, 100, 200}) | **newly assigned boot 142c** (after #308 closed NEG) |
| **#325** | fern | **Aux AdamW cooldown shape sweep** (linear/cosine/sqrt) | cosine-rebase screen `ij7osycz` step 1770, early (val_best 3.54); v2 `ajk7avas` crashed step 180 |
| **#329** | askeladd | **AGC on inner MuonH gradient** (clip_ratio∈{0.10, 0.05, 0.01}) | smoke phase (4 smokes, no code push yet); nudge posted |
| **#328** | frieren | **MuLoCo outer_momentum cosine decay** (final∈{0.5, 0.25, 0.0}) | arm 1 (final=0.50 control) `u1dk4lxx` step 825 (early); restart `hch0psw6` step 210 |
| **#326** | nezuko | **Muon-update-style NS5 + outer_lr retune** | arm 1 `9oqdj9fp` step 840 (early); restart `cfe9qh3k` step 275 |
| **#298** | tanjiro | **Residual branch init rescale** (1/sqrt(2L)) | **POD-BLOCKED** — bf16 NaN pathology `gd125a8`, Issue #164 esc #10 posted 02:55 UTC |
| **#190** | alphonse | NS5 iter count sweep | **POD-BLOCKED 54h+** — CONFLICTING (needs rebase), Issue #164 esc #10 posted 02:55 UTC |

**8/8 students assigned.** No idle slots.

## MERGED this round (chronological)

| PR | Student | Result |
|---|---|---|
| **#114** | frieren | **MuLoCo × MuonH-SI MERGED** — val=3.27585 (n=4), Δ=-0.00152 vs prior. Outer Nesterov SGD wrapper. |
| **#237** | edward | **AGC aux clip=0.05 MERGED** — val=3.27469 (n=4), Δ=-0.00116 vs #114. AGC on aux AdamW. |
| **#243** | frieren | **MuonH-SI cosine cooldown MERGED** — val=**3.27415** (n=4), Δ=-0.00054 vs #237. **Current baseline.** |

## Closed this round (NEG)

| PR | Student | Result |
|---|---|---|
| **#308** | edward | MuonH mu_final decay CLOSED NEG — full-training mu decay destroys variance reduction (0.0→3.3333, 0.5→3.2940, 0.95 control→3.276 OK) |
| **#296** | askeladd | Outer Lookahead CLOSED NEG — k=5 both CRASH; k10/α0.5=3.3236 NEG; k10/α0.9=3.7106 DIVERGED |
| **#292** | fern | depth-LR scaling CLOSED NEG — sqrt=3.2825, linear=3.3041, inv_sqrt=3.2915 |
| **#294** | nezuko | NS5-outer blocks-only CLOSED NEG — blocks-only=3.27658 (+0.00189) |
| **#284** | thorfinn | AGC-outer CLOSED NEG — scope mismatch |
| **#265** | nezuko | SF MuonH CLOSED NEG — WSD × Schedule-Free incompatible |
| **#257** | fern | AdEMAMix aux CLOSED NEG — alpha=2/5/8 all NEG |
| **#282** | askeladd | EMA tail averaging CLOSED NEG — decay=0.999 val=3.368 |
| **#260** | tanjiro | outer_momentum sweep CLOSED NEG — 0.3=NEG, 0.9=DIVERGED, 0.5 optimal |
| **#253** | thorfinn | NS5 fp32 CLOSED NEG — bf16 noise-floor hypothesis falsified |
| **#247** | askeladd | Gradient Centralization CLOSED NEG |
| **#222** | nezuko | cooldown_frac sweep CLOSED NEG — frac=1.0 optimal |
| **#217** | tanjiro | sync_interval sweep CLOSED NEG — sync=30 optimal |

## Saturated levers (confirmed, do not re-test)

- **MuonH-SI HPs**: lr=0.018, mu=0.95, wd=0 — confirmed optimal
- **MuonH cooldown**: cosine frac=1.0 now BASELINE (linear closed)
- **MuonH mu_final decay**: mu_final=0.0/0.5 catastrophic NEG — full-training decay closed; cooldown-window-only variant (PR #308.5) not yet assigned
- **Direction-modifiers**: Contra, Soft-Muon, Cautious, Lookahead k=5/10/20 — all NEG/NaN
- **NS5 polynomial**: A2=(2,-1.5,0.5) — closed; fp32 also closed
- **NS5 iter count**: k=12 optimal in bf16
- **MuLoCo outer_lr/momentum/sync**: 0.7 / 0.5 / 30 confirmed optimal (fixed values; scheduled decay untested)
- **Aux optimizer Lion / AdEMAMix**: all NEG
- **Aux embed lr_mult**: 0.3 optimal
- **Aux betas**: (0.8, 0.95) optimal
- **Aux cooldown_frac**: 1.0 optimal for MuonH; 0.4 for aux
- **Gradient Centralization**: tensor + row both NEG
- **Schedule-Free MuonH**: incompatible with WSD
- **Per-layer depth-scaled LR**: sqrt + linear + inv_sqrt all NEG
- **NS5-outer-velocity**: blocks-only parity; muon_update_style variant untested (nezuko #326 in-flight)

## Patterns discovered (running)

1. **Outer-loop wrappers work**: MuLoCo × MuonH-SI MERGED (−0.00152), AGC aux MERGED (−0.00116), cosine cooldown MERGED (-0.00054)
2. **Cooldown SHAPE matters; momentum decay doesn't**: cosine LR cooldown beats linear; but β momentum decay (mu_final<0.95) catastrophically hurts
3. **MuLoCo-outer slow-snap saturates**: layering another lookahead on outer-θ NEG (askeladd #296); outer_momentum scheduled decay in-flight (frieren #328)
4. **Per-layer depth-LR all NEG**: Architecture's per-layer LR allocation already near-optimal under SI mode
5. **NS5-outer-velocity ~parity**: blocks-only variation +0.00189 (within noise)
6. **LR warmup promising**: thorfinn arm 2 (warmup=100) n=1 = 3.27340 (Δ=-0.00075) — awaiting n=4 confirm

## Potential next research directions (boot 142c+)

1. **Thorfinn n=4 confirm** (warmup=100 on cosine baseline) — highest priority pending
2. **Aux warmup** → edward #338 in-flight — if both warmups (MuonH + aux) confirm, compound them
3. **Stack: cosine cooldown + warmup** — compound two LR-shape wins after thorfinn n=4 confirms
4. **Aux cosine shape** → fern #325 actively screening — compound with MuonH cosine if wins
5. **MuLoCo outer_momentum decay** → frieren #328 actively screening
6. **AGC on inner MuonH gradient** → askeladd #329 (smoke phase)
7. **NS5 outer muon_update_style** → nezuko #326 (screen phase)
8. **MuonH warmup shape sweep** — cosine vs linear warmup at fixed 100 steps (after #310 merges)
9. **Cooldown-only mu decay** (PR #308.5) — β decay gated to LR cooldown window only
10. **Compound run** — after 2-3 more wins, n=4 confirm full stack
