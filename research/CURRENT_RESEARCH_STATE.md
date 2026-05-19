# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~23:25Z (poll #280)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ ACTIVE WINNER CANDIDATE — askeladd P2 #497 (n=4 ns_iter=6 confirmation)

- **T1 TERMINAL**: val=**3.26566**, ffs=**3075** — already 0.000288 BELOW n=4 gate as single trial
- **T2 IN PROGRESS**: step 2750/3250 (~85%), val=3.3292 mid-cooldown, train_seconds=5182. ETA T2 terminal ~23:40 UTC.
- **T3, T4** sequential. n=4 verdict ~04:00 UTC May 20.
- **If T2-T4 mean ≤ 3.265948** → NEW BASELINE WINNER.

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
| **#497** | **askeladd** | **P2 n=4 confirmation of ns_iter=6** | 🔥 T1 TERMINAL val=3.26566 below gate. **T2 step 2750/3250 (~85%)**, ETA ~23:40 UTC |
| #496 | edward | NS iter LOW sweep (12 / 5 / 4 / 3 / 2) | **Cell A ctrl (ns=12) TERMINAL val=3.26793** (baseline match); **Cell B (ns=5) TERMINAL val=3.26754** (−0.49σ, comment pending); Cells C/D/E (ns=4, 3, 2) pending |
| #508 | alphonse | Muon momentum (mu) static value sweep (0.85/0.90/0.95/0.97/0.99) | First static mu sweep ever — running |
| #509 | frieren | lr_mlp fine-scan (0.050/0.055/0.060/0.065/0.075) | NEW (poll #278) — SOAP-MLP carries 2.6× more lift; tests lr_mlp headroom |
| #517 | tanjiro | EMA / Polyak averaging for eval (0.0/0.99/0.999/0.9999/+cooldown-only) | NEW (poll #279) — fresh mechanism; eval-only weight averaging |
| **#518** | **thorfinn** | **NS polynomial coefficient sweep — current / Muon paper / analytical quintic** | **NEW (poll #280)** — fresh axis; tests if (3.4445, -4.7750, 2.0315) Muon paper coefs at ns_iter=6 beats current (2, -1.5, 0.5). Within-PR ctrl includes ns_iter=6 with current coefs for clean comparison |
| #504 | fern | LR floor in cooldown sweep (0.0/0.05/0.10/0.20/0.40) | **Cell A ctrl (0.0) TERMINAL val=3.26617** ffs=3075 (refactor no-op confirmed); **Cell B (0.05) running step 375/3250** |
| #467 | nezuko | SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8) | Trust threshold axis FLAT; cells A/B/C terminal, D `f6ju7rdq` running; E pending. **No winner expected** |


## Recent Closures (polls #273–280)

- **#461 thorfinn NS iter sweep {6,8,10,12,14}** — CLOSED exploratory complete (poll #280). Cell B (ns=6) −2.94σ best; range 4× σ of seed noise. P2 confirmation already in flight via askeladd #497. Step-time analysis ~7 ms/iter (debiased) is the cleanest data point.
- **#473 tanjiro adam_embed_lr** — CLOSED clean-neutral (poll #279). Wide flat bowl [0.3, 0.6]; axis closed.
- **#472 frieren SOAP scope ablation** — CLOSED clean-neutral (poll #278). D (no SOAP) +10.3σ refutes eliminability. SOAP-MLP 2.6× more lift than SOAP-ATTN.
- **#455 alphonse AdamW aux WD** — CLOSED clean-neutral (poll #277).
- **#457 fern cooldown_frac** — CLOSED clean-neutral (poll #276).
- **#437 askeladd SOAP precond_freq schedule** — CLOSED (poll #275). P2 failed by 0.001696.
- **#422 edward Muon WD shape variants** — CLOSED (poll #273). P2 failed by 0.000223.


## Research Themes

**Primary goal:** Push below n=4 gate mu ≤ 3.265948. **askeladd P2 #497 is the headline experiment — T2 terminal within 15 minutes will be the next major datapoint.**

**🆕 Updated ns_iter axis interpretation (after edward Cell B):**
- ns_iter=6 (thorfinn B + askeladd T1): val ≈ 3.2655–3.2657 (strong signal)
- ns_iter=5 (edward B): val = 3.26754 (weak signal, −0.5σ)
- ns_iter=12 ctrl (thorfinn A + edward A): val ≈ 3.266–3.268 (baseline match)
- **The strong ns_iter=6 signal does NOT continue downward.** Either ns_iter=6 is a sharp local optimum, or ns_iter=6's −2.9σ is partially lucky variance.
- askeladd P2 n=4 will resolve which. If T2-T4 all land near 3.2655, ns=6 is a real local optimum mechanism. If T2-T4 land near 3.267, the original T1 was lucky.

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

**Candidate next hypotheses (queue after askeladd P2 result):**
- **If askeladd P2 PASSES**: NEW WINNER ns_iter=6. Compound with NS coefs (thorfinn #518 results), try ns_iter schedules
- **If askeladd P2 FAILS**: ns_iter=6 is variance, not mechanism. Move to gradient clipping, init scheme, Z-loss
- **Gradient clipping for Muon** — currently no clip; could stabilize the seed variance we keep seeing
- **Z-loss regularizer** — softmax stability
- **stable_only WD fresh n=4** — edward #422 mechanism could still be real; T3 was the outlier

**Key insights:**
- **Mid-training val gap does NOT predict terminal val** — edward Cell B had −0.005 gap throughout training, terminal landed only −0.005 below baseline mean (much less impressive than tracked). Cooldown dynamics dominate the terminal value.
- **n=1 noise ≈ 2σ** — askeladd T1 (3.26566) and thorfinn Cell B (3.26553) being within 0.0002 of each other is striking; n=4 will tell if this is mechanism or coincidence.
