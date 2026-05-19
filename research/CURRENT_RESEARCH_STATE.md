# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-20 ~00:10Z (poll #283)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ ACTIVE WINNER CANDIDATE — askeladd P2 #497 (n=4 ns_iter=6 confirmation) — variance now playing against

- **T1 TERMINAL**: val=**3.26566**, ffs=**3075** (−2.78σ single-seed; 0.000288 below n=4 gate)
- **🆕 T2 TERMINAL (W&B history)**: val=**3.26957**, ffs=**3125** — **+0.001622 above T1** and 0.000125 above baseline mean. Cooldown ate the signal again — same pattern as edward Cell B.
- **T3 IN PROGRESS**: step ~125 (~4%), early. T4 sequential.
- **n=1+1 mean so far**: (3.26566 + 3.26957)/2 = **3.26762** (still −0.4σ vs baseline mu=3.267948, but n=2 mean ABOVE the n=2 gate of 3.265186)
- **For n=4 gate (mu ≤ 3.265948)**: T3+T4 must mean **≤ 3.264281** (each needs to land near or below T1's 3.26566 — single-seed −2.78σ territory, twice in a row)
- **Verdict ~04:00 UTC May 20.** Lean: P2 likely fails; ns_iter=6 signal looks variance-dominated.

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
| #496 | edward | NS iter LOW sweep (12 / 5 / 4 / 3 / 2) | Cell A ctrl (ns=12) TERMINAL val=3.26793; Cell B (ns=5) TERMINAL val=3.26754 (−0.49σ); **Cell C (ns=4) running step ~559/3250 (~17%)**; D/E pending |
| #508 | alphonse | Muon momentum (mu) static value sweep (0.85/0.90/0.95/0.97/0.99) | Cell A ctrl (mu=0.95) TERMINAL val=3.26763 ffs=3100 (ctrl matches baseline); **Cell B (mu=0.85) running step 551/3250 (~17%)**. Advisor nudge posted for Cell A comment |
| #509 | frieren | lr_mlp fine-scan (0.050/0.055/0.060/0.065/0.075) | **Cell A ctrl (0.055) step 3199/3250 (~98%), ffs=3100 already hit — TERMINAL IMMINENT**. Terminal val likely 3.266–3.268 |
| #517 | tanjiro | EMA / Polyak averaging for eval (0.0/0.99/0.999/0.9999/+cooldown-only) | Cell A ctrl (decay=0) running step 1124/3250 (~35%); B–E pending |
| **#518** | **thorfinn** | **NS polynomial coefficient sweep — current / Muon paper / analytical quintic** | **Cell A ctrl (ns_coefs=2,-1.5,0.5 ns_iter=12) LAUNCHED `1e5dtrfm` step 156/3250 (~5%)** |
| #504 | fern | LR floor in cooldown sweep (0.0/0.05/0.10/0.20/0.40) | Cell A ctrl (0.0) TERMINAL val=3.26617 ffs=3075 (lucky-side single-seed); **Cell B (0.05) running step ~1561/3250 (~48%)** |
| **#521** | **nezuko** | **Gradient clipping sweep (0.0/0.25/0.5/1.0/2.0) — fresh mechanism never tested** | **NEW (poll #283)** — targets single-seed variance; first ever gradient clip sweep. PR #467 CLOSED clean-neutral |


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

**Primary goal:** Push below n=4 gate mu ≤ 3.265948. **askeladd P2 #497 T2 just landed val=3.26957 — the variance verdict is leaning toward "T1 was lucky".**

**🆕 Updated ns_iter axis interpretation (after askeladd T2):**
- ns_iter=6 single-seed values now: thorfinn #461 B (3.26553), askeladd T1 (3.26566), askeladd T2 (3.26957) — **range 0.00404 ≈ 5× σ**. Two −2.9σ and one neutral. Looks like seed variance dominating, not a robust mechanism.
- ns_iter=5 (edward B): val = 3.26754 (weak, −0.5σ)
- ns_iter=12 ctrl (thorfinn A + edward A): val ≈ 3.266–3.268 (baseline match)
- **Working hypothesis (subject to T3+T4):** ns_iter=6 has the SAME val distribution as ns_iter=12; the apparent "winner" was lucky-side variance × 2. The wall-clock saving (~42 ms/step) is the only real win, but the speedrun metric is val/step-count, not wall-clock.
- T3+T4 will confirm or refute. If T3+T4 both land near 3.2655 → real local optimum. If they land near 3.267 (likely) → variance.

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
