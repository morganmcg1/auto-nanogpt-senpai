# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-19 ~22:00Z (poll #278)
- **🆕 NEW BASELINE (PR #371 MERGED):** mu=3.267948, std=0.000823, n=4, ffs_mean=3100
  - **Mechanism: Muon WD ramp_down (linear 0.05→0 over all steps)**
  - Statsig: `(3.267948 - mu) × √n ≥ 0.004`
  - n=4: mu ≤ 3.265948 | n=6: mu ≤ 3.266316 | n=8: mu ≤ 3.266536


## ⭐ Active Winner Candidates (P2 in progress)

### 🚀 #0 THORFINN #461 — Cell B `ns_iter=6`: **NEW BEST SINGLE-SEED −2.94σ**
- **Mechanism:** Newton-Schulz iter=6 (down from default 12) for Muon orthogonalization.
- **FULL SWEEP RESULTS (Cells A–D terminal, Cell E ns_iter=14 running `zkrrgr1a`):**

| Cell | ns_iter | val/loss | ffs | Δσ vs baseline |
|------|:-------:|---------:|----:|---------------:|
| A (ctrl) | 12 | 3.26623 | 3075 | −1.61σ |
| **B** | **6** | **3.26553** | **3075** | **−2.94σ** 🚀 |
| C | 8 | 3.26834 | 3100 | +0.48σ |
| D | 10 | 3.26693 | 3075 | −1.24σ |
| E | 14 | pending (`zkrrgr1a`) | — | — |

- **Non-monotonic pattern:** B(6) ≪ D(10) < A(12) < C(8). Seed noise dominates — no clean monotonic curve. The B(ns=6) result remains the clear standout.
- **P2 status:** askeladd #497 running 4-trial confirmation (val 3.26553 already BELOW n=4 gate 3.265948).
- **Edward #496** covers the lower extension {12, 5, 4, 3, 2} — Cell A ctrl 3.26793 (baseline match); Cell B ns_iter=5 running.

---

## Active WIP Portfolio

| PR # | Student | Hypothesis | Status |
|------|---------|-----------|--------|
| **#497** | **askeladd** | **P2 n=4 confirmation of ns_iter=6** | **Trial 1 in progress** `ues3hmz1` (~7hr total from launch ~14:xx UTC; expected ~22:xx UTC terminal). n=4 gate: mu ≤ 3.265948. If passes → NEW BASELINE WINNER |
| #461 | thorfinn | NS iteration count sweep (6/8/10/12/14) | **Cells A/B/C/D all terminal**; Cell E ns_iter=14 `zkrrgr1a` launched 20:55 UTC → ETA ~22:45 UTC. Best cell: B (ns_iter=6) val=3.26553 −2.94σ. Thorfinn WIP confirmed — waiting on Cell E |
| #496 | edward | NS iter LOW sweep (12 ctrl / 5 / 4 / 3 / 2) | **Cell A (ns_iter=12) TERMINAL** val=3.26793 ffs=3100 (−0.02σ ≈ baseline ✓); **Cell B (ns_iter=5) running** `(pending run id)` launched 21:13 UTC → ETA ~22:50 UTC |
| #508 | alphonse | Muon momentum (mu) static value sweep (0.85/0.90/0.95/0.97/0.99) | **NEW (poll #277)** — first static mu sweep ever; Cell A ctrl (0.95) first |
| **#509** | **frieren** | **lr_mlp fine-scan (0.050/0.055/0.060/0.065/0.075)** | **NEW (poll #278)** — SOAP-MLP carries 2.6× more lift than SOAP-ATTN; lr_mlp=0.055 may have headroom. No code change needed (--lr_mlp already exists) |
| #504 | fern | LR floor in cooldown sweep (0.0/0.05/0.10/0.20/0.40) | **NEW (poll #276)** — probes LR=0 boundary condition; Cell A ctrl (0.0) running |
| #473 | tanjiro | adam_embed LR sweep (0.05/0.1/0.3/0.6/1.0) | A ctrl (0.3) val=3.26638 ffs=3075 (−1.88σ); **B (lr=0.1) TERMINAL val=3.27420 ffs=3150 (+7.59σ NEG)**; **C (lr=0.6) TERMINAL val=3.26608 ffs=3075 (−1.63σ — BEST in sweep)**; **D (lr=0.05) `chjq4r86` running**; E (1.0) pending. Trend: lr=0.6 mildly best, watching for pattern |
| #467 | nezuko | SOAP trust threshold sweep (0.0/0.1/0.3/0.5/0.8) | A val=3.26694 (−1.28σ); B val=3.26775 (−0.21σ); **C val=3.26693 (−1.28σ — noisy noise-tie with A)**; **D `f6ju7rdq` running**; E pending. **Trust threshold axis flat — no winner** |


## Recent Closures (polls #273–278)

- **#472 frieren SOAP scope ablation** — CLOSED clean-neutral (poll #278). 4-cell ablation: A (MLP+ATTN ctrl) −1.2σ best; B (MLP-only) +1.1σ; C (ATTN-only) +4.8σ NEG; D (no-SOAP) +10.3σ NEG. SOAP is NOT eliminable. SOAP-MLP carries 2.6× more lift than SOAP-ATTN. Current --soap_attn scope is correct. ffs degrades: 3100→3100→3125→3200.
- **#455 alphonse AdamW aux WD sweep** — CLOSED clean-neutral (poll #277). Best cell D (0.0025, ramp_down) −1.18σ within ctrl noise. Aux WD does NOT compound with Muon WD ramp_down.
- **#457 fern cooldown_frac sweep** — CLOSED clean-neutral (poll #276). U-shape with min at ctrl 0.7; both shorter and longer hurt. Cooldown_frac axis closed.
- **#437 askeladd SOAP precond_freq schedule** — CLOSED (poll #275). P2 mu=3.267644, fails gate by 0.001696.
- **#422 edward Muon WD shape variants** — CLOSED (poll #273). P2 mu=3.266171, fails gate by 0.000223.


## Research Themes

**Primary goal:** Push below ffs=3100 on the Muon WD ramp_down baseline. askeladd P2 #497 (ns_iter=6) is the headline experiment — Trial 1 expected terminal ~22:xx UTC.

**"Less optimizer intensity" principle — confirmed across multiple axes:**
- **PR #371 (WINNER):** Muon WD ramp_down → zero WD at end
- **Thorfinn ns_iter=6 (−2.94σ single-seed):** fewer Newton-Schulz iterations globally still works; cheaper Muon orthogonalization
- Edward/askeladd earlier: stable_only WD, precond_freq ramp (both failed P2 but mechanism showed in P1)

**SOAP scope axis (frieren #472 — CLOSED):** SOAP everywhere is correct; cannot reduce scope. SOAP-MLP provides 2.6× more val lift than SOAP-ATTN. This points to lr_mlp having untapped headroom → frieren #509 fine-scan.

**NS iteration axis — dominant current thread:**
- thorfinn #461: {6, 8, 10, 12, 14} — B(6) is the hot signal
- edward #496: {12 ctrl, 5, 4, 3, 2} — maps lower extension; Cell B ns_iter=5 running
- askeladd #497: P2 n=4 confirmation of ns_iter=6 — Trial 1 in progress
- Critical question: is ns_iter=6 a lucky single-seed or a genuine mechanism? P2 will answer within hours.

**lr_mlp fresh axis (frieren #509 — NEW):** First fine-scan of MLP learning rate on the NEW baseline. Motivated by SOAP scope ablation showing SOAP-MLP carries most of the optimizer lift — if the preconditioner has more headroom, a higher MLP LR may extract it.

**Candidate next hypotheses (queue):**
- **NS iter ramp_down schedule** — if thorfinn ns_iter=6 P2 confirms, try scheduling (high→low over training) as a further gain
- **stable_only WD fresh n=4** — edward #422 showed 3 of 4 trials under the gate; T3 outlier killed the mean. A second n=4 at stable_only could clear the gate.
- **Compound ns_iter=6 + WD ramp_down** — likely orthogonal axes; small gain if both are real
- **lr_mlp scheduled** — if frieren #509 shows a better static LR, test scheduled lr_mlp (peak above then decay)
- **finer lr_mlp grid** — follow-up to #509 if C/D win (grid {0.058, 0.062, 0.068})

**Key variance calibration:** Single-seed ctrl repros land ±2σ from n=4 mean. Always require P2 n=4 before claiming winner. ns_iter sweep shows all cells within ~3.4σ span (seed noise dominates at n=1).
