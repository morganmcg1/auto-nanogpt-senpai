# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-22 00:25 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Active experiments (8 students, 23:40 UTC — 0 idle)

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| **#697** | alphonse | QHM body-Muon ν=0.20 β=0.95 (Arm B) | **Arm A TERMINAL NULL** val=3.27137 sr=3025. Mid-run −40/−50 mnat advantage eroded during cooldown — 2nd cooldown-erosion instance. Arm B terminal ETA ~00:24 UTC. |
| **#698** | nezuko | NAdam-Aux Nesterov-AdamW (Arm B β₁=0.9 retuned) | **Arm A TERMINAL NULL** val=3.26811 sr=3000. Cross-family Nesterov NULL. Arm B retuned β₁=0.9. Terminal ETA ~01:00 UTC. |
| **#695** | thorfinn | Polyak EMA β=0.95 warmup=2250 (Arm B) | **Arm A TERMINAL NULL** val=3.26648 sr=2950. Peak EMA −5.02 mnat (12× predicted reduction). Arm B terminal ETA ~00:09 UTC. |
| **#736** | tanjiro | PMuon per-block-TYPE γ_power asymmetry (Arm A attn=0.3/mlp=0.5, Arm B attn=0.5/mlp=0.3) | **NEWLY ASSIGNED 00:25 UTC.** Tests whether attn and MLP layers have different optimal whitening intensity. Arm B is the stronger prior (higher γ for attn, lower for MLP). |
| **#725** | askeladd | PMuon cov buffer reset at cooldown_start (Arm B=full, Arm A=partial re-launch) | Arm A disrupted at step 543; Arm B (cov_scale=0.0) running ETA ~02:14 UTC. Arm A re-launch after. |
| **#723** | frieren | Body-Muon momentum reset at cooldown_start (Arm A=0.5, Arm B=0.0) | Arm A running, ETA ~01:51 UTC. First direct cooldown-mechanism intervention (step 975 event). |
| **#727** | fern | Body-Muon WD cooldown schedule UP (0.025→0.050) vs DOWN (0.025→0.000) | Implementation phase. WD ramp tests WD-impulse trajectory optimality. |
| **#730** | edward | Body-Muon SWA reset at cooldown_start (K=100 / K=200) | **NEWLY ASSIGNED 23:35 UTC.** Parameter-space centroid initialization. Tests whether stable-phase weight drift causes cooldown-erosion. |

## Recently closed (since session start)

| PR | Axis # | Verdict | Mechanism |
|---|---|---|---|
| **#696** tanjiro | 58th | Contra-Muon NULL/NULL (val=3.276/3.269, sr=3125/3000) | PMuon whitening compresses slow EMA ~6× in polar space → effective sub 1.5-3% vs design 15-25%. Monotone dose-response in wrong direction. Post-NS perturbation family adds to spectral absorption pattern. |
| **#690** edward | 57th | SGDR NULL/NULL (val=3.306/3.323, sr=-1/-1) | Restart spike +0.13-0.17 unrecoverable in cycle budget. More restarts → worse. 3rd cooldown-erosion instance: mid-cycle advantage eroded at terminal. LR schedule SHAPE closed (non-monotone direction). |
| **#686** fern | 56th | β_cov schedule SYMMETRIC NULL | Arm A (0.90→0.95) and Arm B (0.95→0.98) produce IDENTICAL regression in opposite directions = canonical static-optimum. β_cov axis FULLY CLOSED (scalar + schedule). |
| **#682** askeladd | 55th | mu schedule NULL/inconclusive | Arm A (cooldown ramp) sr=2925 but val=3.26985 regression fails win rule. Arm B (warmup ramp) NULL sr=3050. Body-Muon mu PINNED at static across 4 sub-axes. |
| **#684** frieren | 54th | Langevin noise NULL/NULL | 5× noise difference, identical sr=2975. PMuon polar map already flat — SGLD has no sharp basin to escape. Gradient-domain perturbation family FULLY CLOSED (4 sub-axes). |
| **#667** nezuko | 53rd | Cosine schedule NULL/NULL | Stable plateau REQUIRED; WSD power-1.4 tail beats cosine by +62.5 sr. Schedule family WSD-LOCKED across 7 sub-axes. |
| **#660** alphonse | 52nd | Nesterov ON/OFF NULL | mu=0.95 AND nesterov=True both independently load-bearing. Cross-term coupling (μ²·m_prev + (1-μ²)·g) non-trivial. |
| **#662** thorfinn | 50th | Polyak EMA β=0.99 NULL | Peak −63 mnat mid-cooldown REAL but centroid-lag flips sign as LR→0. Terminal EMA slightly worse than live. |

## KEY MECHANISM: Cooldown-erosion pattern (3 confirmed instances)

Mid-run optimizer-mechanism advantages compress to zero during WSD cooldown:
1. **#690 SGDR** — cycle-1 advantage −0.019 at step 2125 → +0.058 final regression
2. **#697 QHM** — −40/−50 mnat advantage at steps 1000-1750 → +0.0071 val terminal
3. **#686 β_cov schedule** — symmetric NULL (opposite directions, same regression)

**Mechanism hypothesis:** WSD cooldown (steps 975-3250, 70% of training) is rate-limiting; optimizer differences compress toward zero as LR → 0. The monotone decay is already near-optimal for final refinement. **Implication:** Better targets are step 975 initialization or cooldown-phase buffer state. Current experiments directly test this:
- **#723 frieren**: momentum reset at step 975 (direct event)
- **#725 askeladd**: covariance reset at step 975 (direct event)
- **#727 fern**: WD ramp during cooldown (continuous modification)
- **#730 edward**: SWA weight reset at step 975 (weight-space centroid)

## Current research focus

**Primary frontier: Cooldown-mechanism interventions.** After 57 closed axes, the WSD schedule itself is pinned and optimizer mid-run differences erode in cooldown. The four running experiments (#723/#725/#727/#730) directly attack the cooldown-start initialization and cooldown-trajectory optimality.

**Secondary frontier: Mechanism completion.** Five near-terminal PRs (#697/#698/#695/#696/#690-closed) complete the QHM/NAdam/Polyak/Contra-Muon axis survey. Expected: all NULL (consistent with cooldown-erosion pattern).

**Portfolio balance:** 4/8 slots on novel cooldown interventions (momentum/cov/WD/SWA reset) + 4/8 on terminal completions. When terminal cluster completes (00:00-01:00 UTC), next batch should diversify toward non-cooldown angles: fresh preconditioners, structural inits, or cross-family mechanism tests.

## Axes still untested (high priority)

- Contra-Muon at designed regime (coeff=1.0 to reach 15-25% subtraction magnitude — #696 Arm A gave only 3% due to PMuon whitening compression). Follow-up pending #696 closure.
- Aux β2 ramp (never tested as schedule; static tested at #433)
- Spectral normalization / Frobenius-normalized NS output
- PSGD / Shampoo as body-Muon replacement
- SWA w/ alpha blend (partial weight replace) — #730 tests full replace; blend arm not included

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Closed axes reference (57 total)

*PMuon scalars COMPLETE (all 5 pinned):* γ_power=0.4, β_cov=0.95 (scalar+schedule CLOSED #686), NS_ITERS=12, NS coeff cubic (1.5,-0.5,0), ε=1e-12, mu=0.95 (schedule CLOSED #682).

*Body-Muon LR partition FULLY CLOSED:* per-type (#499), sub-MLP (#535), depth-based (#532).

*Body-Muon scalars/wrappers:* WD partition (#482), WD schedule (#503), grad clipping (#513), γ_power ramp (#444), lr fine-scan (#465), Lookahead (#505).

*Body-Muon LR schedule shape FULLY CLOSED:* WSD pinned across 7 sub-axes (shorter/longer cf, LR floor, NS_ITERS ramp, decoupled aux, warmup); cosine NULL (#667 53rd); SGDR restarts NULL (#690 57th). All non-monotone and shape-variation directions closed.

*Post-NS body-Muon perturbations CLOSED:* Contra-Muon post-NS subtraction (#696 58th) — bilateral whitening compresses slow EMA ~6× in polar space → designed regime unreachable. Full perturbation axis (pre-NS: winsorization/tanh-squash/per-block-norm/Langevin; post-NS: contra-momentum) CLOSED.

*Body-Muon operator ordering CLOSED:* post-NS momentum (#658 49th), Nesterov (#660 52nd).

*Body-Muon parameter-space averaging:* Lookahead (#505), Polyak EMA β=0.999 (LMC failure), β=0.99 centroid-lag (#662 50th), β=0.9 short-window (#695 Arm A NULL), β=0.95 (#695 Arm B in flight).

*Aux AdamW update-rule FULLY CLOSED (9 families):* AdaBelief (#545), NadamW (#575), AdEMAMix (#585), AMSGrad (#578), Adamax (#583), LAMB (#609), Lion (#604), Lookahead (#617), Schedule-Free Adam (#623).

*Aux scalars/static:* scalar_lr (#460), β1 (#416), β2 by-group (#433), embed eps (#463), aux WD (#466).

*Skylight u/w-floor:* magnitude (#486), phase-out (#522). TARGET_UW=0.35 confirmed.

*Gradient transformation body-Muon FULLY CLOSED (all families):* GC subtract (#553), column-mean amplify (#588), clipping (#513), per-block grad-norm (#627 45th), tanh-squash (#622 47th), winsorization (#644 48th), Langevin noise (#684 54th).

*Other:* z-loss (#476), embed init (#440), attn-scale (#480), logit soft-cap (#439), NS adaptive threshold (#447).
