# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~03:00Z (poll #287)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ ACTIVE WINNER CANDIDATE — askeladd P2 #497 (ns_iter=6) — **n=4 BORDERLINE, n=6 EXTENSION RUNNING**

- **T1 TERMINAL**: val=**3.26566**, ffs=**3075** (−2.78σ single-seed)
- **T2 TERMINAL**: val=**3.26957**, ffs=**3125** (+1.97σ outlier)
- **T3 TERMINAL**: val=**3.26493**, ffs=**3075** (−3.67σ, single-seed best)
- **🆕 T4 TERMINAL**: val=**3.26498**, ffs=**3075** (−3.61σ)
- **n=4 mean = 3.266285, ffs_mean = 3087.5** — Δσ_n4 ≈ −4.04σ ≈ p~0.03 vs baseline
- **n=4 gate MISSED by 0.000337** (gate 3.265948); **n=6 gate met if extension delivers**
- **T5/T6 IN PROGRESS** (askeladd autonomously launched extension); T6 ETA ~06:30 UTC May 20
- **T5+T6 decision matrix:**
  - **mean(T5,T6) ≤ 3.266378 → n=6 mu ≤ 3.266316** → **outright WIN, MERGE NEW BASELINE**
  - **3.266378 < mean(T5,T6) ≤ 3.266702** → **mu_n6 in (3.266316, 3.266536]** → propose n=8 extension if appetite, else close
  - **mean(T5,T6) > 3.266702** → close clean-neutral; ns_iter=6 axis is variance-dominated
- **Modal expectation**: random T5/T6 from baseline distribution mean(T5,T6) ~ 3.2679; needs to land ~−2.0σ to clear n=6 gate. Lean failing but not far.
- **Key insight**: 3-of-4 trials hit ffs=3075 (vs baseline 3100) — ns_iter=6 wall-clock benefit is reproducible even if val gate uncertain. ffs improvement worth noting independently.

### Supporting evidence on the ns_iter axis (now FULLY CHARACTERIZED):

Combined edward #496 + thorfinn #461 n=1 sweep:
| ns_iter | val/loss | Δσ | Source |
|---:|---:|---:|---|
| 3 | 3.27949 | +14.03σ | edward Cell D — bf16 unconverged |
| 4 | 3.27342 | +6.65σ | edward Cell C — bf16 unconverged |
| 5 | 3.26754 | −0.50σ | edward Cell B — weak |
| 6 | 3.26553 | −2.94σ | thorfinn Cell B (n=1; askeladd P2 evaluating mean) |
| 8 | 3.26834 | +1.08σ | thorfinn Cell C |
| 10 | 3.26830 | +1.04σ | thorfinn Cell D |
| 12 | 3.26793 | −0.19σ | edward Cell A / thorfinn Cell A |
| 14 | 3.26891 | +1.12σ | thorfinn Cell E |

**Conclusions:**
- ns_iter≤4: hard cliff (NS doesn't converge in bf16 below 5 iters); not viable
- ns_iter=5–6: possibly slightly favored, ~σ-magnitude
- ns_iter≥8: weakly above baseline; ~σ noise
- **The mechanism is at most a ~σ shift; mostly variance**


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status (poll #287) |
|------|---------|-----------|--------|
| **#497** | **askeladd** | **P2 n=4 → n=6 confirmation of ns_iter=6** | **n=4 mean=3.266285 borderline; T5+T6 extension launched ETA ~06:30 UTC**. n=6 gate needs mean(T5,T6) ≤ 3.266378 |
| #521 | nezuko | Gradient clipping (corrected ladder: 0/50K/100K/200K/400K) | **Cell A no-clip TERMINAL val=3.26439 ffs=3050 (−4.32σ; lucky baseline seed)**. Cell B (200K) launched run `tpe1w7ir`. Per-group grad-norm telemetry on |
| #518 | thorfinn | NS poly coefficient sweep (current / Muon paper / analytical quintic) | A (ctrl) TERMINAL val=3.267355 ffs=3100 (refactor ok, −0.72σ). **Cell B (Muon paper coefs `3.4445,-4.7750,2.0315`) launched** |
| #517 | tanjiro | EMA / Polyak weight-averaging for eval | A (decay=0) TERMINAL val=3.26776 (refactor ok). **B (decay=0.99) TERMINAL val=3.27528 (+8.91σ, fast EMA hurts)**. **Cell C (decay=0.999) running** |
| #509 | frieren | lr_mlp fine-scan (0.050/0.055/0.060/0.065/0.075) | A (0.055 ctrl) val=3.267302 (−0.79σ). **B (0.050) TERMINAL val=3.267014 ffs=3075 (−1.13σ, crosses interest gate)**. **Cell C (0.060) running** |
| #508 | alphonse | Muon momentum mu static sweep (0.85/0.90/0.95/0.97/0.99) | A (mu=0.95 ctrl) val=3.26763 (−0.04σ). B (mu=0.85) val=3.27409 (+7.46σ, BAD). C (mu=0.90) val=3.26873 (+0.95σ, neutral). **Cell D (mu=0.97) running**. Cell E (mu=0.99) pending |
| #504 | fern | LR floor in cooldown (0.0/0.05/0.10/0.20/0.40) | A (0.0) val=3.26617 (−2.16σ best non-clip seed). B (0.05) val=3.26924 (+1.57σ). C (0.10) val=3.27750 (+11.61σ). **Cell D (0.20) running**. **Monotonic worsening — floor>0 strictly hurts** |
| **#537** | **edward** | **Adam β1/β2 sweep (5 cells: ctrl + 0.9/0.95, 0.9/0.99, 0.95/0.999, 0.7/0.9)** | **NEW assignment — first heartbeat pending** |


## Recent Closures (polls #284–287)

- **🆕 #496 edward NS iter LOW sweep {12, 5, 4, 3, 2 / dropped 2}** — CLOSED clean-neutral (poll #287). A=3.26793 (ctrl), B (ns=5)=3.26754 (weak), C (ns=4)=3.27342 (+6.65σ saturation), D (ns=3)=3.27949 (+14.03σ deep saturation). Strong evidence ns<5 is bf16-broken; ns_iter axis fully mapped (see table above).
- **#467 nezuko SOAP trust threshold {0.0/0.1/0.3/0.5/0.8}** — CLOSED clean-neutral (poll #283). cos_sim distribution tight (0.78–0.91); thresholds ≤0.5 are mechanical no-ops; threshold=0.8 fires 20.6% but val matches baseline.
- **#461 thorfinn NS iter sweep {6,8,10,12,14}** — CLOSED exploratory complete (poll #280). Cell B (ns=6) −2.94σ best; range 4× σ of seed noise.
- **#473 tanjiro adam_embed_lr** — CLOSED clean-neutral (poll #279). Wide flat bowl [0.3, 0.6]; axis closed.
- **#472 frieren SOAP scope ablation** — CLOSED clean-neutral (poll #278). D (no SOAP) +10.3σ refutes eliminability. SOAP-MLP 2.6× more lift than SOAP-ATTN.
- **#455 alphonse AdamW aux WD** — CLOSED clean-neutral (poll #277).
- **#457 fern cooldown_frac** — CLOSED clean-neutral (poll #276).


## Research Themes

**Primary goal:** Push below n=4 gate mu ≤ 3.265948. **askeladd P2 #497 n=4 mean=3.266285 borderline — n=6 extension is the most likely shot in this poll.**

**🆕 Updated ns_iter axis interpretation (after edward #496 closure):**
- Combined sweep across {3, 4, 5, 6, 8, 10, 12, 14} shows U-shape with min at ns_iter=5–6, hard floor at 5 (bf16 limit)
- Magnitude of "best" effect ≤ σ
- Practical takeaway: ns_iter=6 may be marginally optimal but the wall-clock benefit (ffs=3075 vs 3100, ~25-step reduction) is the more reliable signal than val/loss change

**Variance as the dominant story:**
- Two clean baseline-equivalent cells (askeladd T2 = 3.26957, nezuko A = 3.26439) span 5σ within identical hyperparams
- Single-seed P1 results MUST be discounted; n≥4 P2 is the floor for any merger
- Frieren Cell B (lr_mlp=0.050) val=3.267014 at −1.13σ crosses "interesting" gate — but pattern matches a lucky single seed more than a real mechanism

**"Less optimizer intensity" principle — partially extended:**
- PR #371 winner: Muon WD ramp_down (cooldown axis)
- alphonse #508: muon mu=0.85 +7.46σ NEG, mu=0.90 +0.95σ neutral, mu=0.97 running — current 0.95 looks tuned
- Two failed P2s (edward #422, askeladd #437): mechanism showed in P1 but variance ate the gate

**Fresh mechanism threads:**
- **thorfinn #518 NS poly coefficient (live):** Cell A ctrl ok, Cell B (Muon paper coefs) running — fresh axis
- **tanjiro #517 EMA / Polyak (live):** Cell B (decay=0.99) +8.91σ NEG; Cell C (decay=0.999) running — slow EMA may matter
- **nezuko #521 gradient clip (live):** First clip sweep ever, anchored on actual grad-norm distribution (~80K–200K)
- **edward #537 Adam β1/β2 (new):** First ever Adam beta ablation; canonical (0.9, 0.999) vs current hardcoded (0.8, 0.95)
- **fern #504 LR floor:** Monotonically worsening — floor>0 strictly hurts; closes axis once Cell D/E land

**Candidate next hypotheses (queue after current wave resolves):**
- **If askeladd P2 PASSES**: NEW WINNER ns_iter=6. Try ns_iter schedules (warmup ns), compound with NS coefs
- **If askeladd P2 FAILS**: ns_iter axis is variance-not-mechanism. Pivot to fresh mechanisms below
- **Muon nesterov toggle** — nesterov=True hardcoded at line 482; never tested False
- **Adam epsilon sweep** — eps=1e-10 is very small (PyTorch default is 1e-8); first ablation
- **Z-loss regularizer** — softmax stability; fresh mechanism
- **stable_only WD fresh n=4** — edward #422 mechanism could still be real; T3 was the outlier
- **LR warmup curve shape** — currently linear; test cosine warmup. Fresh schedule axis
- **PR averaging (Polyak–Ruppert)** — if tanjiro #517 slow EMA decay=0.999 wins, generalize
- **NS power-iter polynomial alternates** — orthogonal to thorfinn's coefficient sweep; e.g. higher-degree polys

**Key insights:**
- **Mid-training val gap does NOT predict terminal val** — edward Cell B had −0.005 gap throughout training, terminal landed at only −0.5σ
- **n=1 single-seed noise is ~σ ≈ 0.000823; observed range over identical-config samples is 5σ** — variance is the dominant signal at single-seed
- **askeladd T1+T2 sequencing is a textbook noise demo**: T1 was −2.9σ; T2 was +1.97σ. Same hyperparams, different luck
- **nezuko no-clip ctrl val=3.26439 sets a new single-seed lower bound on the baseline distribution** — at the −4σ tail of the n=4 baseline std
