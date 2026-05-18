# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-18 23:14 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2975 steps (just BEAT previous record of 3030 — new local n=2 sr=2975). Public record was 3030 steps (Record #20).

## Current local baseline

**sr=2975, val/loss=3.26722 (n=2)** — PR #367 (g1r1-frieren, lm_head_lr=1/160). **NEW RECORD BEAT — sr=2975 < public 3030.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 + aux AdamW embed_lr=0.3, **lm_head_lr=1/160**, scalar_lr=0.01, betas=(0.8, 0.95), eps=1e-10.

W&B runs: `7xub16ua` (seed-1), `f9nyqjxn` (seed-2).

Win conditions: sr<2975 OR (sr=2975 AND val<3.26722). Marginal (Δsr≤25 OR Δval≤0.001) → n=2 required.

**KEY STATUS: We have BEATEN the public record (3030 steps → our 2975). Next target: push sr below 2975 (sub-2975).**

## Pending confirmation (unmerged n=1 wins)

None at this time.

**Infrastructure:** Stable. Cold-start crash storm fully abated.

## Active experiments (8 students)

| PR | Student | Mechanism | Status (23:14 UTC) |
|---|---|---|---|
| **#387** | **nezuko** | Role-based Muon LR: attn vs MLP {0.7×, 0.4×} | Arm A 0.7× DONE sr=3000 val=3.2704 (NULL vs new baseline). Arm B 0.4× `0aay0p7y` step 2800/3250 mid-flight. ETA terminal ~23:30 UTC. |
| **#401** | **tanjiro** | Muon WD downward scan {0.020, 0.015} | Arm A WD=0.020 `o5z8a5n3` running. ETA ~23:50 UTC. |
| **#410** | **frieren** | lm_head_lr fine-scan {1/120, 1/100, 1/80} vs new baseline 1/160 | Just assigned (23:14 UTC). Arm A 1/120 to launch. |
| **#386** | **alphonse** | PMuon γ_power continuation {0.5, 0.6} | γ=0.5 DONE val=3.2800 NULL. γ=0.6 `yhfo48gj` step 3175/3250 near terminal. ETA terminal <5 min. |
| **#395** | **fern** | NS_ITERS cooldown schedule {14, 18 vs const=12} | Arm A DONE sr=3025 val=3.2699 (NULL). Arm B cooldown=18 launching. |
| **#400** | **edward** | AGC on aux AdamW per-row λ ∈ {0.04, 0.02} | Arm A λ=0.04 `2y0ewtlb` step 2525/3250 mid-flight. ETA ~00:10 UTC. |
| **#403** | **askeladd** | Curriculum COOLDOWN_POWER: linear ramp p_start → p_end | Arm A 1.2→1.6 `jq5rgqb7` step 950/3250 running. ETA ~01:00 UTC. |
| **#404** | **thorfinn** | Aux CP extend: CP=1.0 n=2 confirm + CP=0.5 extend | Arm A CP=1.0 seed2 `jv2oi3fv` step 575/3250 running (prior crashes). ETA ~01:30 UTC. |

## Recently merged (current round)

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#367** | frieren | lm_head_lr=1/160: n=2 mean sr=2975 val=3.26722 (Δsr=−25, Δval=−0.00128, both seeds independently 2975) | **MERGED** — new baseline sr=2975 val=3.26722. lm_head_lr axis open for fine-scan {1/120, 1/100, 1/80}. |

## Recently closed (current round)

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#364** | askeladd | Muon momentum reset at cooldown {hard, soft}: Arm A hard ×0.0 val=3.26922 (Δval=+0.0007 NULL), Arm B soft ×0.3 n=2 mean val=3.26911 sr=3012.5 (Δval=+0.0006 NULL) — n=1 marginal WIN (val=3.2680 Δval=-0.0005) FALSIFIED at n=2 | CLOSED — n=2 falsified marginal. Reset fired correctly (`momentum_norm_ratio=0.3000`). Seed variance ~0.002 dwarfs effect. **Cooldown momentum-reset axis CLOSED.** |
| **#366** | thorfinn | Aux-AdamW cooldown power {1.0, 2.0}: Arm A val=3.2662 sr=3000 (Δval=-0.0023, marginal n=1 unconfirmed); Arm B val=3.2727 sr=3050 (clear NULL, opposite direction) | CLOSED at n=1 — cold-start crash storm prevented 10+ n=2 retries. Strong monotone directional signal (lower aux CP helps). **Direction preserved in PR #404 with clean n=2 confirm + extension to CP=0.5.** |
| **#350** | edward | Residual-proj init {1/√(2N), 1/N}: Arm A val=3.26966 sr=3000 (Δval=+0.00116 NULL), Arm B val=3.26866 sr=3000 (Δval=+0.00016 NULL-tied) | CLOSED — both arms NULL. Zero-init confirmed optimal. GPT-2 residual-proj scaling trick doesn't transfer to Muon stack (orthogonalization resets gradient direction). **Residual-init axis CLOSED at zero.** |
| **#362** | tanjiro | GC column-only val@3250=3.27043 sr=3025 (NULL), GC both val@3250=3.29637 sr=-1 (NULL) | CLOSED — PMuon's cov-EMA whitening already absorbs drift GC removes; row-centering over-constrains transformer linear weights. **GC axis CLOSED on Muon body.** |
| **#332** | fern | COOLDOWN_POWER continuation {1.5, 1.8}: Arm A n=3 mean sr=2991.67 val=3.27021 (Δsr=-8.3, Δval=+0.0017 — noise floor); Arm B n=1 sr=2975 val=3.27464 (Δsr=-25, Δval=+0.0061 — val regression) | CLOSED — both arms NULL. Per-seed Arm A sr={3000,3000,2975}; 2/3 tied at baseline. **Body-side COOLDOWN_POWER axis CLOSED at 1.4.** Aux-side variant (#366 thorfinn) still open. |
| **#347** | nezuko | LLRD per-depth {0.95, 0.85}: Arm A val=3.2804 sr=-1, Arm B val=3.3136 sr=-1 | CLOSED — monotone signal (more aggressive decay → worse). ULMFiT prior inverted for pretraining-from-scratch; NS orthogonalization already normalizes per-tensor. **Depth-based LR decomposition CLOSED.** |
| **#311** | thorfinn | Lookahead α ∈ {0.5, 0.8}, k=5: Arm A val=3.299 sr=never; Arm B val=3.271 sr=3050 | CLOSED — mechanism active (slow-fast ratio 0.005–0.05) but unhelpful. PMuon's own whitening already produces clean updates; averaging via pullback discards genuine progress. Third closure confirming "PMuon warm-up dynamics axis CLOSED." |
| **#327** | askeladd | Adan aux {lr_mult=1.0, lr_mult=0.33}: both NULL sr=-1 val=3.288/3.312 | CLOSED — **aux optimizer-mechanism axis CLOSED.** Lion, AdEMAMix, Adan all NULL. Aux uniformly wants fast-EMA AdamW (β1=0.8). β1=0.98 Adan stales sparse vocab rows. |
| **#307** | tanjiro | PMuon EMA bias-correct {FULL, SQRT}: both NULL sr=3050 val≈3.268 | CLOSED — cold-start un-corrected EMA IS the implicit whitening warmup; bias-correct perturbs it without benefit. Pairs with PR #261 closure. |
| **#305** | frieren | AdEMAMix dual-EMA α ∈ {4, 8}: dose-response NULL (α=4 val=3.286, α=8 val=3.317) | CLOSED — BF16 m_slow fix confirmed correct; mechanism still NULL on this stack. |
| **#331** | edward | Per-tensor embed clip {clip=10, clip=100}: both NULL | CLOSED — per-tensor embed clip axis closed. |
| **#317** | nezuko | Lion optimizer on aux {lr=0.03, lr=0.10}: both NULL, slow convergence | CLOSED — aux uniformly wants AdamW. |
| **#314** | alphonse | embed_lr scan {0.2, 0.4}: both NULL | CLOSED — embed_lr=0.3 optimal. |

## Key structural findings (current program state)

1. **PMuon hyperparameter axes ALL CLOSED**: NS_ITERS (flat 6–18 uniform — schedule variant in flight #395), NS_coef (a,b) (closed at 1.5,-0.5), NS_coef c-axis (closed at c=0), Muon base LR (closed at 0.035), γ_power (closed at 0.4 — continuation in flight #386), β_cov (closed at 0.95), mu (closed at 0.95), TARGET_UW (closed at 0.35), LR warmup (closed).

1a. **Body LR decomposition axes**: Depth (LLRD, PR #347) CLOSED — uniform optimal. Role-based (attn vs MLP, PR #387) in-flight.

2. **Aux optimizer-mechanism axis CLOSED**: AdamW β1 (closed at 0.8), β2 (closed at 0.95), eps (closed at 1e-10). Alternative optimizers (Lion, AdEMAMix, Adan) all NULL. Aux groups uniformly want fast-EMA AdamW (β1=0.8). **lm_head_lr=1/320 → 1/160 MERGED (PR #367)**; fine-scan in flight (PR #408). Aux gradient clipping (AGC per-row) in flight #400.

3. **Weight-averaging axis CLOSED**: Polyak/Ruppert (PR #293), Lookahead k=5 (PR #311) both NULL. Power-law cooldown makes late-phase params much better than mid-phase; any averaging backward in time is counterproductive.

4. **PMuon EMA dynamics axis CLOSED**: LR warmup (PR #261), bias-correction (PR #307) both NULL. Cold-start un-corrected EMA IS the implicit whitening warmup — load-bearing, do not modify.

5. **Schedule axis**: Body-side COOLDOWN_POWER=1.4 merged (PR #274), continuation {1.5, 1.8} CLOSED (PR #332) — local optimum at 1.4. Aux-group cooldown power CLOSED at n=1 (PR #366, Arm A marginal val WIN unconfirmed due to crash storm, but direction preserved in PR #404). NS_ITERS cooldown schedule in flight (PR #395 fern). Curriculum cooldown power in flight (PR #403 askeladd).

6. **WD, clip, z-loss**: Muon WD closed at 0.025; z-loss closed at 0 (existing logit soft-clamp sufficient); global grad-clip closed; per-tensor embed-clip NULL (PR #331).

7. **Init axis**: Residual-proj init scaling {1/√(2N), 1/N} — CLOSED at zero-init (PR #350). GPT-2 trick doesn't transfer; Muon orthogonalization resets gradient direction per-step.

## Current research focus

Three themes active simultaneously:

1. **Cooldown-phase precision** (fern #395 NS_ITERS schedule, askeladd #403 curriculum cooldown power): Do cooldown-phase updates benefit from higher-quality direction or time-varying power-law concavity? Both target the ~2275 cooldown steps where LR is tiny and direction quality matters most.
2. **Aux AdamW optimization** (frieren #367 lm_head_lr, edward #400 AGC, thorfinn #404 aux CP extend): Aux side has multiple marginal-WIN signals — at least one may stack. Thorfinn #404 confirms direction from #366 + extends to CP=0.5.
3. **Closing remaining body-side dimensions** (nezuko #387 role-based LR, tanjiro #401 Muon WD downward, alphonse #386 γ_power): Likely NULL but needed to confirm axes are exhausted.

## Open unexplored axes (for future assignment)

- NS adaptive threshold: stop NS iterations when ||X²-I||_F < ε (convergence criterion vs fixed count)
- Inverse LLRD: bottom layers get HIGHER LR (contradicts ULMFiT prior but may hold for pretraining-from-scratch)
- Spectral normalization of weight matrices (complement to polar decomp)
- NS_ITERS fine-scan continuation — after fern #395 indicates direction
- Aux β1 continuation {0.7, 0.85} — once aux AGC/lm_head signals clarify
- Per-layer NS_ITERS schedule (more iterations for deeper layers)
- Body warmup duration scan {fast, slow} — currently using single warmup schedule

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`.
n=1 win: sr < 2975 OR (sr=2975 AND val < 3.26722).
Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). *(unchanged — rule anchored at 3.28, not baseline)*
Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
