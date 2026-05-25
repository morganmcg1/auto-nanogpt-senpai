# SOAP eps sweep manifest (PR #1076)

Group: `g1r5-alphonse/soap-eps-sweep`

| Cell | --soap_eps | W&B name | W&B run ID | val/loss   | Δμ vs baseline | z (σ_single) | ffs  | step_avg | Status |
|------|-----------:|----------|------------|-----------:|---------------:|-------------:|-----:|---------:|--------|
| A    | 1e-8 (default) | eps_A_1e-8_ctrl    | emacq2yb | 3.261112 | +0.000891 | +1.50σ | 3050 | 1903ms | DONE (control / baseline replication) |
| B    | 1e-6 ★ PRIMARY | eps_B_1e-6_primary | 8ebopxxf | 3.261044 | -0.000177 | -0.30σ | 3025 | 1903ms | DONE — within 1σ of baseline |
| C    | 1e-4           | eps_C_1e-4_loose   | xlpbiwbm | 3.261588 | +0.000367 | +0.62σ | 3025 | 1905ms | DONE — within 1σ of baseline |
| D    | 1e-10          | eps_D_1e-10_tight  | jgbsjfzt | 3.261030 | -0.000191 | -0.32σ | 3025 | 1906ms | DONE — within 1σ of baseline (best by 0.000014 over B) |
| E    | 1e-2           | eps_E_1e-2_extreme | ufx11gga | 3.261980 | +0.000759 | +1.28σ | 3050 | 1905ms | DONE — within 1σ of baseline (just outside band) |

Cluster: mean=3.261551, stdev across cells=0.000507 (matches single-seed σ).
Pattern: NON-monotonic; tightening to 1e-10 and loosening to 1e-6 both
slightly beat default 1e-8, but 1e-4 and 1e-2 do not. Loss is effectively
flat across 8 orders of magnitude of eps for this benchmark.

Baseline (PR #699): val/loss μ=3.261221, σ=0.000593, n=4, ffs=3025.
n=1 confirm gate: val/loss ≤ 3.260628 — NONE PASS.
n=4 merge gate: μ ≤ 3.259221.

Decision: NULL result per PR decision rules ("best cell sits within ±σ of baseline").
