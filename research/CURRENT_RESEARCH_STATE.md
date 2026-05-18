# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-18 08:58 UTC (boot 142s/t)
- **Most recent human-team directive:** Operator rotated 3 broken pods at 19:34 UTC 2026-05-16. Tanjiro (`gd125a8`) and nezuko (`gc8bcf4`) initially healthy; **alphonse (`gd103cc`) broken since boot 130** + tanjiro (`gd125a8`) broken since boot 137. Issue #164 escalations #7–#12 posted (esc#12 at 08:55 UTC). Operator silent ~62h since 19:34 UTC 2026-05-16. Next esc#13 at ~12:00 UTC.
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

## Active experiments (boot 142s/t — 08:58 UTC 2026-05-18)

| PR | Student | Lever | Status |
|---|---|---|---|
| **#310** | thorfinn | **MuonH inner LR warmup=100** (n=4 confirm) | `w6xgiqzl` trial 0=3.27361 ✅ trial 1=3.27308 ✅ trial 2=**3.27256** ✅ (n=3 mean=**3.27308**, Δ=-0.00107); trial 3 running ETA ~10:35 UTC — **CONFIRMED WIN incoming** |
| **#329** | askeladd | **AGC inner MuonH** (clip=0.05 n=4 confirm) | Screen CLOSED: clip=0.10 NEG, **clip=0.05=3.27288 WIN**, clip=0.01=3.27505 NEG. **n=4 confirm `ow5c05o8` auto-launched 08:32 UTC**. ETA terminal ~15:12 UTC |
| **#338** | edward | **Aux AdamW LR warmup** (aux_warmup_steps ∈{0, 100, 200}) | arm 1=3.27559 ✓; arm 2 (warmup=100)=**3.27861 STRONG NEG** (+0.00446); arm 3 (warmup=200) `j78eu1e7` at ~step 1875 ETA terminal ~10:11 UTC — lever clearly NEG |
| **#352** | fern | **Aux AdamW cooldown_frac sweep** (frac∈{0.3, 0.4, 0.5}) | assigned boot 142r, student picking up |
| **#361** | nezuko | **Aux lm_head LR sweep** (1/500 vs 1/320 vs 1/200) | **newly assigned boot 142s/t** (after #326 CLOSED NEG) |
| **#328** | frieren | **MuLoCo outer_momentum cosine decay** | All 3 arms NEG (0.25=3.27569; 0.00=3.27805). Awaiting student SENPAI-RESULT to close. 1h40m since run finished. |
| **#298** | tanjiro | **Residual branch init rescale** | **POD-BLOCKED 62h+** — `gd125a8` bf16 NaN, esc#12 posted 08:55 UTC |
| **#190** | alphonse | NS5 iter count sweep | **POD-BLOCKED 62h+** — rebase complete, clarification answered, waiting for rotation. Esc#12 posted 08:55 UTC |

**8/8 students assigned.** No idle slots.

### Current win pipeline

| Source | Best result | n=4 ETA | Status |
|---|---|---|---|
| **Thorfinn warmup=100** `w6xgiqzl` | n=3 mean=**3.27308** (Δ=-0.00107) | trial 3 ETA ~10:35 UTC | **IMMINENT MERGE** |
| **Askeladd AGC inner clip=0.05** `ow5c05o8` | n=1=3.27288 (Δ=-0.00127) | n=4 ETA ~15:12 UTC | **ACTIVE n=4 confirm** |

Both stackable wins expected in the same boot. **Compound experiment** (warmup + AGC inner) queue for boot 143.

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

## Potential next research directions (boot 142n+)

1. **Thorfinn n=4 confirm (warmup=100)** — IN FLIGHT, trials 0+1 done, terminal ~11:50 UTC. If n=4 mean ≤ 3.27375 (Δ≤-0.0004 with √4 margin), MERGE.
2. **Askeladd clip=0.05 n=4 confirm** — after clip=0.01 screen closes ~09:15 UTC; if clip=0.05 is best of 3 arms, instruct askeladd to launch n=4 confirm. Strong WIN at n=1 (3.27288).
3. **Stack: MuonH warmup + AGC inner clip=0.05** — orthogonal levers. If both confirm at n=4, run compound experiment (warmup=100 × inner-AGC). Schedule for boot 143+.
4. **Aux warmup compound** → edward #338 in-flight; if aux_warmup also wins at n=1, run triple-stack screen (MuonH warmup × aux warmup × AGC inner).
5. **MuonH warmup shape sweep** — cosine vs linear warmup at fixed 100 steps (after #310 n=4 confirms).
6. **Cooldown-only mu decay** (PR #308.5) — β decay gated to LR cooldown window only (mu_final full-training decay closed NEG in #308).
7. **Compound run** — after 2 confirmed n=4 wins, run combined n=4 stack to verify additive gain.

### NEG arms / dead ends discovered this slice

- fern aux cosine shape: cosine HURTS aux (+0.00287); linear control reproduces baseline. PR #325 likely close after sqrt terminal.
- frieren outer_momentum cosine decay: final=0.25 = +0.00154 NEG; final=0.00 trending NEG. PR #328 likely close after arm 3 terminal.
- nezuko muon_update_style + outer_lr retune: lr=0.35 NEG (+0.249), lr=0.50 NEG (+0.250). lr=0.70 in flight — if also NEG, close PR #326.
