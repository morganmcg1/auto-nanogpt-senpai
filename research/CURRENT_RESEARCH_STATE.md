# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~06:30Z (poll #289)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ ACTIVE WINNER CANDIDATE — askeladd P2 #497 (ns_iter=6) — **n=6 IN PROGRESS, T6 IMMINENT**

- **T1**: val=3.26566 ffs=3075 (−2.78σ)
- **T2**: val=3.26957 ffs=3125 (+1.97σ outlier)
- **T3**: val=3.26493 ffs=3075 (−3.67σ)
- **T4**: val=3.26498 ffs=3075 (−3.61σ)
- **T5**: val=3.26611 ffs=3100 (−2.23σ)
- **T6 IN FLIGHT** (ETA 06:28 UTC — imminent as of poll #289)
- **n=5 mean = 3.266250, ffs_mean=3090.0**
- **n=6 WIN condition**: T6 ≤ **3.266646** → mu_n6 ≤ 3.266316 (statsig gate)
- **Probability**: 5/5 trials so far ≤ 3.26957; T6 ≤ 3.266646 is the modal expectation

### ns_iter axis full table (combined edward #496 + thorfinn #461 + askeladd #497 n=5 mean):
| ns | 3 | 4 | 5 | 6 (n=5 mean) | 8 | 10 | 12 | 14 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Δσ | +14.03 | +6.65 | −0.50 | **−2.06** | +1.08 | +1.04 | ctrl | +1.12 |


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status (poll #289) |
|------|---------|-----------|--------|
| **#497** | **askeladd** | **P2 n=6 confirmation of ns_iter=6** | **T6 in flight ETA ~06:28 UTC**; n=5 mean=3.266250; T6 needs ≤3.266646 for WIN |
| #537 | edward | Adam β1/β2 sweep (ctrl + 4 cells) | Cell A ctrl val=3.26855 (+0.73σ refactor ok). **Cell B (0.9,0.95) running** |
| #521 | nezuko | Gradient clipping (0/50K/100K/200K/400K) | A (no-clip)=3.26439 (−4.32σ best seed). B (200K)=3.26712 (−1.00σ). **C (100K)=3.26927 (+1.61σ)**. **Cell D (50K) likely running** |
| #518 | thorfinn | NS poly coefficient sweep | A=3.267355 (ctrl). B (Muon coefs,iter12)=3.267031 (−1.11σ). **C (Muon coefs,iter6)=3.26684 (−1.35σ BEST)**. **Cell D (analytical quintic iter12) RUNNING** ETA ~07:52 UTC |
| #517 | tanjiro | EMA / Polyak weight-averaging for eval | A=3.26776 (ctrl). B=3.27528 (+8.91σ BAD). **C=3.34507 (+93.71σ CATASTROPHIC)**. **Cell D (0.9999) running**; Cell E (cooldown-only EMA) is the critical remaining test |
| #509 | frieren | lr_mlp fine-scan (0.050/0.055/0.060/0.065/0.075) | A=3.267302 (−0.79σ ctrl). B (0.050)=3.267014 (−1.13σ, crosses interest gate). C (0.060)=3.267256 (−0.84σ). **Cell D (0.065) RUNNING** |
| #508 | alphonse | Muon momentum mu static sweep (0.85–0.99) | A=3.26763 (ctrl). B=3.27409 (+7.46σ). C=3.26873 (+0.95σ). **D=3.27048 (+3.08σ)**. **Cell E (mu=0.99) running** |
| **#548** | **fern** | **WD floor in cooldown (0.0/0.05/0.10/0.20/0.50) — dual of LR floor** | **NEW assignment** — awaiting first heartbeat |


## Recent Closures (polls #283–289)

- **🆕 #504 fern LR floor sweep {0.0/0.05/0.10/0.20/0.40}** — CLOSED clean-NEG (poll #289). All cells B–E monotonically worse. Cell A (0.0)=3.26617 (−2.16σ); Cell E (0.40)=3.32773 (+72.64σ catastrophic). **LR=0 boundary condition confirmed load-bearing.** Fern's symmetry framing with PR #371 (WD→0) is correct.
- **#496 edward NS iter LOW sweep {12,5,4,3}** — CLOSED clean-neutral (poll #287). Hard bf16 cliff below ns_iter=5; ns_iter axis fully mapped.
- **#467 nezuko SOAP trust threshold** — CLOSED clean-neutral (poll #283).
- **#461 thorfinn NS iter {6,8,10,12,14}** — CLOSED exploratory (poll #280). Cell B (ns=6) −2.94σ best.


## Research Themes

**Primary goal:** Push below n=4 gate mu ≤ 3.265948. **askeladd P2 #497 T6 is the most important single data point in this poll.**

**📌 Cooldown landing boundary:**
- **LR=0 confirmed load-bearing** (fern #504, closed): any lr_floor>0 hurts super-linearly
- **WD=0 hypothesis** (fern #548, new): testing the dual — does WD also need to land at zero?
- Both constraints together = "clean landing" theory from PR #371

**In-flight signals worth watching:**
- **thorfinn Cell C** (Muon coefs + ns_iter=6) = val=3.26684 (−1.35σ) — same territory as askeladd ns_iter=6. Cell E (current coefs + ns_iter=6) will disentangle coef vs iter effect.
- **nezuko Cell B** (clip=200K) = val=3.26712 (−1.00σ) mildly positive. Axis looks unclear — no-clip ctrl dominated by lucky seed. Cell D (50K) will clarify.
- **frieren Cell B** (lr_mlp=0.050) = val=3.267014 (−1.13σ) crosses interest gate. Cell C/D nearby. Small lr_mlp reduction might have a weak positive signal.
- **tanjiro Cell E** (cooldown-only EMA) is the only survivor after Cells B/C catastrophic. Important to await its result.

**Alphonse mu sweep status:**
- mu=0.85: +7.46σ (strongly worse)
- mu=0.90: +0.95σ (neutral)
- mu=0.95: ctrl (no-op)
- mu=0.97: +3.08σ (worse)
- mu=0.99: running
- **Pattern: current mu=0.95 appears locally optimal.** Worse in both directions.

**Adam betas (edward #537):**
- Cell A ctrl (0.8,0.95) = +0.73σ within band. Cells B–E sequential. ETA ~17:00 UTC for all 5.

**Candidate next hypotheses (queue after current wave resolves):**
- **Muon nesterov toggle** — nesterov=True hardcoded at line 482; never tested False. Single binary flip, cheap ablation.
- **Adam epsilon sweep** — eps=1e-10 very small (PyTorch default 1e-8); first ablation.
- **LR warmup curve shape** — currently linear; test cosine warmup (fresh schedule axis)
- **Z-loss regularizer** — softmax stability; completely fresh mechanism family
- **stable_only WD fresh n=4** — edward #422 mechanism; T3 was the outlier; re-confirm?
- **NS coefs + ns_iter=6 P2** — if thorfinn Cell E confirms Cell C signal, could be a combined winner candidate
- **Joint LR×WD floor matrix** — test (lr_floor=0.05, wd_floor=0.05) vs ctrl after fern #548 closes

**Key insights:**
- **LR=0 AND WD=0 terminal conditions appear jointly load-bearing** — "clean landing" hypothesis
- **Single-seed variance dominates**: n=1 range ≈ 5σ; need n≥4 P2 before any merger
- **ns_iter=6 mechanism is real on ffs (3075 vs 3100 reproducibly) but val signal borderline**
- **Cooldown dynamics dominate terminal val** — mid-training gaps do NOT predict terminal
