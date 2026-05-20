# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~01:55Z (poll #286)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ ACTIVE WINNER CANDIDATE — askeladd P2 #497 (n=4 ns_iter=6 confirmation) — **back in contention**

- **T1 TERMINAL**: val=**3.26566**, ffs=**3075** (−2.78σ single-seed)
- **T2 TERMINAL**: val=**3.26957**, ffs=**3125** (+1.97σ outlier)
- **🆕 T3 TERMINAL**: val=**3.26493**, ffs=**3075** (−**3.67σ**, new best single)
- **n=3 mean = 3.266720** (−1.49σ vs baseline mu 3.267948); ffs_mean = 3091.67
- **T4 IN PROGRESS**: step 115/3250 (~3.5%); ETA terminal ~02:55 UTC May 20
- **T4 decision matrix:**
  - **T4 ≤ 3.263632 (~−5.2σ single-seed)** → n=4 outright WIN, MERGE as NEW BASELINE
  - **3.263632 < T4 ≤ 3.265104** → borderline (mu_n4 ≤ 3.266316); **propose n=6 extension** (modal expectation)
  - **T4 > 3.265104** → variance-eaten; close
- **Key insight**: 2-of-3 trials both at 3.265 range with ffs=3075 — pattern more consistent with real mechanism + variance than pure noise. T2 outlier resembles edward #422 P2 bad-T3 pattern.

### Supporting evidence on the ns_iter axis (now MIXED, not all positive):

- **thorfinn #461 (CLOSED poll #280) Cell B ns_iter=6 (n=1):** val=3.26553 −2.94σ. Full sweep {6,8,10,12,14} val-flat within seed noise (range ~4× σ). Wall-clock cost ~7ms/iter — going to ns=6 saves ~42 ms/step. Mechanism for val/loss appears noise-limited; mechanism for wall-clock is real but doesn't help speedrun step-count metric.
- **🆕 edward #496 Cell B ns_iter=5 (W&B finished, awaiting student comment):** val=**3.26754**, ffs=3075 (−0.49σ). **Mid-training gap of −0.005 vs Cell A did NOT hold through cooldown.** This means:
  - Going BELOW ns_iter=6 does NOT reliably improve val
  - The trajectory advantage of fewer NS iters dissipates by terminal step
  - **Reframes the ns_iter mechanism narrative:** ns_iter=6 may be locally optimal in [5, 6, 7] range, not a downward trend

This is **critical new information** — if ns_iter=5 doesn't beat ns_iter=12, then the "less iter = better" simple interpretation breaks. The ns_iter=6 signal may be a sharp local optimum or just lucky variance at the specific value 6.


## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| **#497** | **askeladd** | **P2 n=4 confirmation of ns_iter=6** | T1 val=3.26566 ffs=3075; **T2 TERMINAL val=3.26957 ffs=3125** (variance ate signal). T3 ~4%, T4 pending. n=2 mean=3.26762, **needs T3+T4 mean ≤ 3.264281 for n=4 gate** — lean failing |
| #496 | edward | NS iter LOW sweep (12 / 5 / 4 / 3 / 2) | A=3.26793 (ctrl), B=3.26754 (−0.49σ), **C (ns=4) TERMINAL val=3.27342 (+6.65σ, bf16 sat threshold)**; **Cell D (ns=3) launching**. Advisor suggested skipping E if D confirms trajectory |
| #508 | alphonse | Muon momentum (mu) static value sweep (0.85/0.90/0.95/0.97/0.99) | A (mu=0.95) val=3.26763 ffs=3100; **Cell B (mu=0.85) step 3234/3250 (~99.5%) val=3.274621 ffs=3150 — terminal imminent** (mu=0.85 worse than baseline) |
| #509 | frieren | lr_mlp fine-scan (0.050/0.055/0.060/0.065/0.075) | A (0.055) TERMINAL val=3.267302; **Cell B (0.050) step 1888/3250 (~58%)** |
| #517 | tanjiro | EMA / Polyak averaging for eval (0.0/0.99/0.999/0.9999/+cooldown-only) | A ctrl (decay=0) TERMINAL val=3.267758 ffs=3100 (refactor ok); **Cell B (decay=0.99) step 857/3250 (~26%)** |
| #518 | thorfinn | NS polynomial coefficient sweep — current / Muon paper / analytical quintic | **Cell A ctrl `1e5dtrfm` step 2547/3250 (~78%) val=3.362694 mid-cooldown — terminal ~30 min**. Smoke ok. Advisor nudged for interim comments |
| #504 | fern | LR floor in cooldown sweep (0.0/0.05/0.10/0.20/0.40) | A (0.0) val=3.26617; B (0.05) val=3.2692 (+1.52σ); **Cell C (0.10) `nukwy18x` step 1310/3250 (~40%)** |
| #521 | nezuko | Gradient clipping sweep (anchored 0/50K/100K/200K/400K — corrected from advisor's wrongly-scaled 0–2 ladder) | **Cell A ctrl (no-clip) `1kiauw9h` step 1983/3250 (~61%)**; B–E sequential after with corrected anchored thresholds |


## Recent Closures (polls #273–283)

- **#467 nezuko SOAP trust threshold {0.0/0.1/0.3/0.5/0.8}** — CLOSED clean-neutral (poll #283). cos_sim distribution tight (0.78–0.91); thresholds ≤0.5 are mechanical no-ops; threshold=0.8 fires 20.6% but val matches baseline. Key diagnostic: SOAP and Muon updates are nearly interchangeable at their moments of maximum disagreement.
- **#461 thorfinn NS iter sweep {6,8,10,12,14}** — CLOSED exploratory complete (poll #280). Cell B (ns=6) −2.94σ best; range 4× σ of seed noise. P2 confirmation via askeladd #497 (T1 looks lucky, T2 baseline-match).
- **#473 tanjiro adam_embed_lr** — CLOSED clean-neutral (poll #279). Wide flat bowl [0.3, 0.6]; axis closed.
- **#472 frieren SOAP scope ablation** — CLOSED clean-neutral (poll #278). D (no SOAP) +10.3σ refutes eliminability. SOAP-MLP 2.6× more lift than SOAP-ATTN.
- **#455 alphonse AdamW aux WD** — CLOSED clean-neutral (poll #277).
- **#457 fern cooldown_frac** — CLOSED clean-neutral (poll #276).
- **#437 askeladd SOAP precond_freq schedule** — CLOSED (poll #275). P2 failed by 0.001696.
- **#422 edward Muon WD shape variants** — CLOSED (poll #273). P2 failed by 0.000223.


## Research Themes

**Primary goal:** Push below n=4 gate mu ≤ 3.265948. **askeladd P2 #497 T3 landed val=3.26493 (−3.67σ, new best) — P2 is back in contention.**

**🆕 Updated ns_iter axis interpretation (after askeladd T3):**
- ns_iter=6 single-seed values now: thorfinn #461 B (3.26553), askeladd T1 (3.26566), askeladd T2 (3.26957), askeladd T3 (3.26493). **3 of 4 cluster in 3.2649-3.2657; T2 the lone outlier at 3.26957.**
- ns_iter=5 (edward B): val = 3.26754 (weak, −0.5σ)
- ns_iter=12 ctrl: val ≈ 3.266–3.268 (baseline)
- **Working hypothesis updated**: ns_iter=6 likely has a real mean shift downward of ~0.001 vs ns_iter=12, but variance is high enough that single-seed outliers (like T2) can mask the signal. T4 is decisive.
- ffs pattern: both T1 and T3 hit ffs=3075 (−25 steps vs baseline) — reproducible wall-clock benefit even if val gate is uncertain.

**"Less optimizer intensity" principle — partially extended:**
- PR #371 winner: Muon WD ramp_down (cooldown axis)
- ns_iter axis: 6 might be optimal but lower not better; partial support
- Two failed P2s (edward #422, askeladd #437): mechanism showed in P1 but variance ate the gate

**Fresh mechanism threads:**
- **thorfinn #518 NS poly coefficient (NEW):** First test of Muon paper coefs vs current; orthogonal to ns_iter
- **tanjiro #517 EMA / Polyak (NEW):** cooldown noise-floor reduction; eval-only
- **frieren #509 lr_mlp fine-scan:** tests SOAP-MLP headroom
- **fern #504 LR floor in cooldown:** Cell A confirms refactor, Cell B running
- **alphonse #508 Muon mu static sweep:** first static sweep ever

**Candidate next hypotheses (queue after current wave resolves):**
- **If askeladd P2 PASSES**: NEW WINNER ns_iter=6. Compound with NS coefs (thorfinn #518 results), try ns_iter schedules
- **If askeladd P2 FAILS**: ns_iter=6 is variance, not mechanism. Pivot to fresh mechanisms below
- **Gradient clipping** ← ASSIGNED to nezuko #521. First gradient clip sweep; targets variance
- **Adam β1/β2 sweep** — currently hardcoded (0.8, 0.95); never ablated. Could matter for embed/lm_head training.
- **Adam epsilon sweep** — eps=1e-10 is very small (PyTorch default is 1e-8); first ablation.
- **Z-loss regularizer** — softmax stability; fresh mechanism
- **stable_only WD fresh n=4** — edward #422 mechanism could still be real; T3 was the outlier
- **Muon nesterov toggle** — nesterov=True hardcoded at line 482; never tested False
- **LR warmup curve shape** — currently linear; test cosine warmup. Fresh schedule axis.

**Key insights:**
- **Mid-training val gap does NOT predict terminal val** — edward Cell B had −0.005 gap throughout training, terminal landed only −0.005 below baseline mean (much less impressive than tracked). Cooldown dynamics dominate the terminal value.
- **n=1 single-seed noise is ~σ ≈ 0.0008; range over 3 ns_iter=6 samples is 0.00404 ≈ 5σ** — variance is the dominant signal at single-seed, not mechanism. This reinforces the need to gate every "winner" on n=4 P2.
- **askeladd T1+T2 sequencing is a textbook noise demo**: T1 was −2.9σ "amazing"; T2 was +0.1σ baseline-match. Same hyperparams, same seed schedule, different luck per trial. Single-seed P1 results should be discounted accordingly.
