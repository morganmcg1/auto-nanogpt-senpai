# BASELINE — auto-nanogpt-1gpu-r4

Primary metric: `speedrun/final_first_step_to_target` (lower is better, `-1` if never reached).

Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.

## Current best (checked-in record history)

- **Steps-to-3.28:** 3030 (record #20)
- **Mean val/loss:** 3.2790 (n=30)
- **Recipe:** Contra-Soft-Muon + KL-SOAP (MLP+V) + attention trust gate + u/w-floor + tuned cooldown schedule
- **Source:** `records/track_3_optimization/results/20260509_contra_soft_muon/`
- **Track 3 README PR:** #291 by @nilin

Track 3 World-record progression (notable highlights):
| # | Steps | Description |
| - | -     | -           |
| 20 | 3030 | Contra-Soft-Muon + KL-SOAP attn trust gate + u/w-floor |
| 16 | 3125 | Contra-Muon + SOAP-MLP + SOAP-attn trust gate |
| 19 | 3125 | KL-SOAP-H, lr=0.018, beta1=0.95, beta2=0.9, shampoo_beta=0.9 |
| 14 | 3150 | Contra-Muon + SOAP-MLP |
| 17 | 3175 | Contra-Muon + Aurora + u/w-floor |
| 15 | 3275 | Newton-Muon (activation-covariance right precond) |
| 13 | 3210 | NorMuonH + MuLoCo outer Nesterov |
| 11 | 3225 | NorMuon + u/w-floor + Contra-Muon |
| 18 | 3225 | PMuon (bilateral covariance power precond, γ=0.3) |
| 8  | 3250 | NorMuonH |
| 10 | 3250 | NorMuon (Adafactor-style row/col precond, lr=0.035 wd=0.025) |

## Target for this advisor branch

Improve below 3030 steps on this benchmark while satisfying the statistical
rule, using the fixed track 3 contract (architecture, data, batch size,
1 fwd-bwd per step).

## Updates

| Date | PR | Steps | Mean loss (n) | Notes |
| -    | -  | -     | -             | -     |
| boot | —  | 3030  | 3.2790 (30)   | inherited from public record history |
| 2026-05-15 | #60 | 3275 | 3.2766 (2)   | Muon² (Adam v-EMA before NS, NS=12). First branch stat-sig crossing of 3.28; runs s0oq3dnx, 4hedrgf4. Bundled `sample_tensor` float64 precision fix and `NANOGPT_NS_ITERS` env var. |
| 2026-05-16 | #105 | **3266.7** | **3.27527 (3)** | Gradient clipping at 5.0 (`NANOGPT_GRAD_CLIP=5.0`). Full-time gradient rescaling on AdamW aux groups (embed/lm_head); Muon blocks unaffected (NS absorbs magnitude). n=3 seeds: arm-C 3utr1m71 (3.27415/3250), confirm-1 yfhknwar (3.27481/3250), confirm-2 j4r186ws (3.27684/3300). Stat-sig: (3.28−3.27527)×√3=0.00819≥0.004. |
| 2026-05-17 | #165 | **3258.3** | **3.27474 (3)** | Clip value raised to 10.0 (`NANOGPT_GRAD_CLIP=10.0`). Embed effective-LR ratio raised from 8.4% → 16.9% via asymmetric per-group global-norm rescaling. Single-peak sweep (clip∈{5,10,25,50}) confirmed peak at clip≈10–15; plateau between 10–25, regression above 50 (embed eff-LR 83%). Triangulated mechanism: clip effect is structurally on AdamW aux ONLY (Muon side inert per edward #206). Uniform 1.5× aux LR neutral (alphonse #188 arm-B) ⇒ clip ≠ uniform LR rescaler. n=3 seeds: arm-B 84um64gj (3.27432/3250), confirm-1 lxkp0jmx (3.27510/3275), confirm-2 efnghv0f (3.27480/3250). Stat-sig: (3.28−3.27474)×√3=0.00911≥0.004. |
