# BASELINE — Auto-nanoGPT Open SOTA v2 (launch 2026-06-04)

Primary metric: `speedrun/final_first_step_to_target` — **earliest fixed eval step at which mean val/loss across `n` non-cherry-picked seeds satisfies `(3.28 - mu) * sqrt(n) >= 0.004`**. Lower is better.

Per-`n` validity thresholds (mean val/loss must be ≤):

| n | threshold |
|---:|---:|
| 1 | 3.276000 |
| 2 | 3.277172 |
| 3 | 3.277691 |
| 4 | 3.278000 |
| 8 | 3.278586 |
| 16 | 3.279000 |
| 32 | 3.279293 |

**A result is OFFICIAL-VALID if the criterion holds at any fixed step ≤ 2890.** Eval points land at every 25 steps near the end (2825 / 2850 / 2875 / 2890). The "earliest valid step" is the speedrun score.

**Branch-rank vs official validity** are tracked separately:
- "Branch rank" = lowest final-2890 mean (useful for mechanism quality / pairwise comparison).
- "Official validity" = earliest fixed step passing the contract (the speedrun target).
- Do NOT close a direction solely because its final-2890 mean is worse than rank-1; it must also fail official at 2825 / 2850 / 2875 / 2890.

Local robustness policy: prefer n=4 confirms for any merge candidate (after PR #2393 lucky-pair failure), but n=2 / n=3 official passes are kept alive while n=4 is in flight.

## Current best to beat

| Rank | Source | Step | n | Mean val/loss | Margin | Notes |
|---:|---|---:|---:|---:|---:|---|
| 1 | **Senpai PR #2403 (tanjiro H-EH-3: STAIRCASE β₂ 0.95→0.97@820→0.99@1156, merged 2026-06-09 08:25 UTC)** | **2875** | **4** | **3.276833** | **0.006335** | Two-pulse β₂ staircase on AdamW optimizer1: init override to 0.95, pulse 1 @ step 820 → 0.97, pulse 2 @ step 1156 (cd_start, cooldown_frac=0.60) → 0.99. Layered on NC × Sinkhorn Arbor × EN × RI × eps=1e-12 stack. Earliest official-valid step = 2875 (vs PR #2349 = 2890) — **+15-step speedrun improvement**. Final-2890 mean = 3.275798. W&B: `onbpdqpa` (s1), `edls3p4y` (s2), `66nkhzby` (s3), `sj3ebdm9` (s4). Flags: `--aux_b2_rule staircase --aux_b2_low 0.95 --aux_b2_mid 0.97 --aux_b2_high 0.99 --aux_b2_pulse_step_1 820 --aux_b2_cooldown_frac 0.60`. |
| 2 | Senpai PR #2349 (frieren H-AY: AdamW eps=1e-12, merged 2026-06-07 23:30 UTC) — (previous baseline, demoted 2026-06-09 08:25 UTC) | 2890 | 4 | 3.276172 | 0.007656 | AdamW eps tightened 1e-10 → 1e-12 for all AdamW groups (embed/lm_head/scalars). Smoother second-moment normalization. Layered on NC × Sinkhorn Arbor × EN × RI stack. W&B: `521ky42j` (Arm B n=2), `nbptdumy` (Arm B seeds 2-3). |
| ~~2~~ | ~~Senpai PR #2393 (thorfinn H-EF Arm B EARLIER: aux β₂ pulse 0.95→0.99 @ step 820, merged 2026-06-09 00:35 UTC)~~ — **INVALIDATED at n=4 by PR #2404 (iblvhrvk): n=4 mean = 3.276616** (+0.000444 REGRESSION vs PR #2349). Seeds 1+2 (n=2 = 3.274835) were a lucky pair; seeds 3+4 came in at 3.275807 and 3.280989 respectively. Sample std at n=4 = 0.002958. Code merge KEPT (flags `--aux_b2_start`, `--aux_b2_target`, `--aux_b2_pulse_step` are opt-in; default `aux_b2_start=-1.0` disables the pulse), but rank-1 reverts to PR #2349. | 2890 | 2 | 3.274835 → **3.276616 at n=4** | — | n=2 was insufficient evidence; mandatory n=4 from now on. |
| 3 | Senpai PR #2317 (nezuko H-W NC × Arbor + RI, merged 2026-06-06 15:43 UTC) | 2890 | 4 | 3.276193 | 0.007615 | Cautious-Muon (NC: per-row × per-col L2 equalization before NS5) on merged Arbor+RI base (Aurora+EMA-Nesterov+Sinkhorn+RI γ=−0.075 capture=2375). W&B: `vk0jtb3z`. Best trial T3=3.275708. Paired Δ=−0.000325. |
| 3 | Senpai PR #2298 (alphonse H-A Corrected Arbor Muon, merged 2026-06-06) | 2890 | 4 | 3.27738 | 0.00524 | Sinkhorn spectrum equilibration (corrected variant, sqrt(out_dim) pin removed) on PR #309 base (Aurora+EMA-Nesterov). W&B: 5weg8d9r. |
| 3 | Senpai PR #2295 (fern H15 RI, merged 2026-06-05) | 2890 | 4 | 3.27786 | 0.00427 | Tail Reference Interpolation γ=−0.075, capture_step=2375, on PR #309 base. W&B: g32gn44z. |
| 3 | KellerJordan PR #305 (merged) | 2925 | 8 | 3.27812750 | 0.005297 | Aurora + late capped RRE + Contra-Muon extended. Previous official public record. |
| 4 | Senpai PR #1532/#1614 (internal audit) | 2905 | 32 | 3.279022187 | 0.005531 | Aux Adam beta2 pulse + PMuon/LR/EMA stack. Best internal but not on track-3-open-sota-v2 tag. |
| 5 | KellerJordan PR #300 (merged) | 2930 | 16 | 3.27844375 | — | Aurora row-balanced polar on `mlp.proj` + Contra-Muon ramp to 2500 + Muon momentum warmup/cooldown. |

The PR #305 result is treated as the launch baseline for "official, fully
auditable, fixed-step" comparisons. PR #1532/#1614 is the strongest internal
result but lives under different tags; this launch needs fresh
benchmark-valid evidence to claim parity or improvement.

Open public claims under 2900 steps (PR #318/#312/#311/#309/#307 at 2850–2900)
are valuable IDEA sources, not baselines, until we reproduce them under the
benchmark contract on our own infra.

## Update Procedure

When a PR on `auto-nanogpt-open-sota-v2-20260604` beats the baseline at a
declared fixed step with `n>=4` non-cherry-picked seeds and `(3.28 - mu) *
sqrt(n) >= 0.004`, update this file with:

- New rank-1 row pointing to the winning PR number, step, n, mean, margin,
  W&B run ids, and one-line mechanism summary.
- Demote the previous rank-1 row to rank 2 with a parenthetical "(previous
  baseline)".

Commit the update on the advisor branch.
