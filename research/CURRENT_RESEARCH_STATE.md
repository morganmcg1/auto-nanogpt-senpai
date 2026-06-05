# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-05 ~14:45 UTC (launch day +1)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, then push the Track 3 fixed-step record below 2900. Prime Intellect public auto-speedrun materials are also allowed sources.

## 🏆 BASELINE (merged 2026-06-05 13:37 UTC)

**Senpai PR #2295 (fern H15 RI): n=4 mean 3.27786 at 2890 steps** — RI γ=−0.075, capture=2375, on PR #309 base.

## Active assignments (as of 2026-06-05 ~14:45 UTC)

| PR | Student | Hypothesis | Base | Target step | Status |
|---:|---|---|---|---:|---|
| **#2302** | open2-fern | H-G RI hyperparameter sweep (capture × γ, 9 arms) | PR #309 | 2890 | Assigned ~13:55 UTC, awaiting pod pickup |
| **#2298** | open2-alphonse | H-A Corrected Arbor Muon (2-iter Sinkhorn) | PR #309 | 2890 | **BLOCKED** — Blackwell torch downgrade. Torch fix posted 13:32 UTC + rebase instruction 13:43 UTC. No student response as of 14:45 UTC. Status ping sent. |
| **#2300** | open2-askeladd | H-E Polar Express NS (wall-clock gate) | PR #309 | 2890 | Gate run mxwc0v28 running, +1.99% speedup (GATE FAILING, needs ≥5%), ETA ~15:10 UTC. Student to post SENPAI-RESULT then close. |
| **#2301** | open2-edward | H-D Senpai late-higher block LR on PR #300 base | PR #300 | 2925 | Launch authorized from ad8a5492 (14:17 UTC). No rebase needed before launch. Awaiting launch confirmation. |
| **#2289** | open2-frieren | H5b RI on PR #300 base (no RRE) | PR #300 | 2930 | Arm B (RI) fvf4tu59 running, ETA ~20:45 UTC. Needs rebase after results. |
| **#2297** | open2-nezuko | H17 RI on PR #305 base (paired-gamma) | PR #305 | 2925 | T0 γ=−0.075=3.27775 (Δ=−0.00069, 2× fern's lift!). T1 running, ETA ~18:30 UTC |
| **#2299** | open2-tanjiro | H-D Senpai late-higher block LR on PR #309 base | PR #309 | 2890 | Arm A (flat control) running (wpk68f5v). No recent update. |
| **#2303** | open2-thorfinn | H-F RI + NC on bare Muon (cross-base universality test) | bare Muon | 3325 | Just assigned PR #2303 (~14:45 UTC). Needs torch reinstall + rebase before launching. |

## Closures this round

| PR | Student | Verdict | n | Key finding |
|---:|---|---|---:|---|
| #2296 | thorfinn | **FALSIFIED (n=1 abort)** | 1 | C-Muon on bare Muon: T0=3.37845, +0.10 above threshold. Stable gap from step 250 onwards. C-Muon locked OUT of composition — does not transfer to Muon ortho-gradient regime. |
| #2295 | fern | **MERGED ✅** | 4 | RI γ=−0.075: 3.27786 — new SOTA baseline |

## Key findings (current)

### RI on PR #309 — MERGED BASELINE (3.27786)

Paired Δ = −0.00033 with variance 0.00001 across 4 trials. Most reproducible mechanism on the fleet.

### Nezuko H17 RI on PR #305 — T0 EXCEPTIONAL (Δ=−0.00069, 2× fern's lift)

| Trial | γ=0 (control) | γ=−0.075 | Paired Δ |
|---|---:|---:|---:|
| T0 | 3.27844 | 3.27775 | **−0.00069** |
| T1 | running | running | — |

If T1-T3 confirm the larger Δ magnitude, nezuko H17 could beat fern's baseline. PR #305 base (with RRE damping) may allow RI larger correction room.

### Cross-base PMuon falsification (FINAL)
Both PR #300 and PR #309 bases reject PMuon. Do not revisit.

### Cautious-Muon falsification (FINAL)
C-Muon +0.10 on bare Muon. Newton-Schulz output is near-orthonormal — sign-product mask discards mass uniformly across spectrum. Does not transfer to Muon ortho-gradient regime.

### Compositional verdicts

| Mechanism | Base | Status |
|---|---|---|
| NC | bare Muon | ✅ CONFIRMED (+0.003 delta at 3325 steps) |
| NC | ALL Aurora-bearing stacks | ❌ FAILED (3 PRs) |
| **RI (γ=−0.075, paired-gamma)** | **PR #309** | **✅ MERGED — 3.27786 at 2890** |
| RI (γ=−0.075) | PR #305 | T0: Δ=−0.00069 (exceptional, T1-T3 running) |
| RI (γ=−0.075) | PR #300 | Running (frieren Arm B, ETA 20:45 UTC) |
| RI + NC | bare Muon | Assigned thorfinn H-F (PR #2303) |
| RI hyperparameter sweep | PR #309 | Assigned fern H-G (PR #2302) |
| Corrected Arbor Muon | PR #309 | BLOCKED on torch fix (alphonse) |
| Cautious-Muon (sign mask) | bare Muon | ❌ FAILED (n=1 abort, +0.10 gap) |
| late-higher block LR | PR #309 | Running (tanjiro H-D Arm A) |
| late-higher block LR | PR #300 | Launch authorized (edward H-D PR #2301) |
| PE NS (wall-clock gate) | PR #309 (H100) | ❌ FAILED gate (+1.99% vs ≥5%) |

### cuDNN SDPA fix + Blackwell torch version warning (fleet-wide)
Three Blackwell pods affected (alphonse, thorfinn, nezuko): `torch==2.10.0+cu128` silent downgrade causes NaN at step 2-3. Fix: `pip install --force-reinstall --no-deps torch==2.12.0+cu130 --index-url https://download.pytorch.org/whl/cu130`.

## Highest-priority watch items (14:45 UTC)

1. **Askeladd PR #2300 (~15:10 UTC)**: PE gate terminal. Close + assign H-I (RI direction ablation, positive γ sweep) immediately.

2. **Alphonse PR #2298 (BLOCKED)**: Ping sent at 14:45. No response since torch fix at 13:32 UTC. If no response by ~15:30 UTC, escalate.

3. **Nezuko H17 T1-T3 (ETA ~18:30 UTC)**: T0 Δ=−0.00069 (2× fern's lift). If T1-T3 hold this magnitude, nezuko H17 is a merge candidate beating fern's 3.27786.

4. **Thorfinn PR #2303 pod pickup**: Needs torch reinstall + rebase + smoke before n=4 launch.

5. **Edward PR #2301 launch**: Authorized to launch from ad8a5492 at 14:17 UTC. No response yet.

6. **Frieren PR #2289 Arm B (~20:45 UTC)**: RI on PR #300 base.

## Research focus (14:45 UTC)

**RI cross-base universality test — ongoing across 4 bases:**
1. PR #309 (Aurora+EMA-Nesterov): ✅ MERGED at 3.27786
2. PR #305 (Aurora+RRE+Contra-Muon): T0 Δ=−0.00069 EXCEPTIONAL
3. PR #300 (Aurora+Contra-Muon+SOAP): Running (frieren Arm B)
4. Bare Muon + NC: Assigned thorfinn H-F

If all 4 confirm RI lift → RI is fully universal, add to ALL future compositions.

**Hyperparameter optimization:** fern H-G sweeping 9 capture×γ combinations to find if (2375, −0.075) is truly optimal or if another combination delivers more lift.

**Mechanisms to compose with RI (upcoming):**
- Late-higher LR (tanjiro + edward H-D running now)
- Arbor Muon / tail suppression (alphonse H-A, once torch fixed)
- RI direction ablation (askeladd H-I, after PE gate closes)

## Things to AVOID

- NC on any Aurora-bearing stack (falsified 3×)
- PMuon on PR #300 or PR #309 base (falsified cross-base)
- β2-pulse on PR #309 base (falsified)
- Circuit-Muon as standalone (n=4 mean 3.27844; T1=3.27726 held only for future composition)
- Cautious-Muon on ANY base (falsified on bare Muon at +0.10, mechanism-side failure)
- Polar Express NS on H100 (gate failed +1.99% vs ≥5%, GH200-specific)
