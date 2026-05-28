# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-28 (cycle 458 — 1 review #1466 nezuko NS_COOLDOWN_SHAPE **CLOSED Row 4 productive-NULL absorption** + 1 new assignment #1515 nezuko NM_PERIOD phase-split. **🎯 #1466 CLOSED**: All 4 arms TERMINAL. Best Arm C `linear_ramp` val=3.26454 (+0.00144 NEG vs baseline 3.26310); all fs=3175 (+25 NEG vs baseline 3150). Within-chain |Δ_paired| ≤ 0.0015 for all 3 perturbation arms = Row 4 NULL band. R_cond 3.7× ladder with invariant val confirms R-buffer EMA absorption mechanism. **🎯 11th cross-axis catalog finding — NS-axis triple-NULL convergence COMPLETE**: NS_ITERS_COOLDOWN (#1438) + NS_COEF_SCHEDULE (#1440) + NS_COOLDOWN_SHAPE (#1466) all NULL-absorbed. **🎯 #1515 NEW ASSIGNMENT nezuko NM_PERIOD phase-split**: tests phase-dependent NM_UPDATE_PERIOD (body vs cooldown). Arms A ctrl BODY=2 COOLDOWN=2 / B BODY=2 COOLDOWN=1 (cooldown-amplify) / C BODY=4 COOLDOWN=2 (body-save) / D BODY=4 COOLDOWN=1 (compound). Directly addresses H1261 directive #4 (period/coverage tuning for late-training window) AND tests whether c456 precond_ratio<1 dip mechanism can be addressed by phase-conditional R-buffer refresh frequency. Hypothesis convergence: #1421 period=2 MERGED FAV (R freshness load-bearing) + #1469 cooldown-disproportionate NEG (cooldown-phase NM more load-bearing than body) + c456 mid-training precond<1 dip = phase-dependent period schedule could compound BOTH mechanisms. Modal: 35% Row 4 NULL / 25% Row 3 mild-FAV / 15% Row 5 NEG-monotone / 12% Row 2 PP-MARGINAL / 8% Row 1 strong-FAV / 5% Row 6 non-monotone. ETA ~8h sequential. **Cross-axis catalog post-c458 = 11 findings 6 classes**: 5 magnitude-NULL + 3 NS-axis-NULL + 1 timing-NEG (#1383) + 1 freshness-FAV-MERGED (#1421) + 1 state-continuity-NEG (#1431) + 1 temporal-coverage-NEG (#1469 pending). **No new human GH issues** (H1261 directive already incorporated). **0 idle students** — 8 chains active. **Cross-chain status cycle 458 (8 chains active, 0 idle)**: #1499 tanjiro period=1 screen c455 5-point status request awaiting / #1447 fern β=0.99 PP n=3 Run 6 arm B2 ~8% trending PP-COLLAPSE / **#1515 (NEW) nezuko NM_PERIOD phase-split** / #1469 alphonse NM_STOP_STEP Arm D STOP=1500 ~10% / #1478 frieren LR_SCALE=0.80 PP n=3 on period=2 stack Run 1 ~90% near-terminal / #1484 edward β low-screen / #1486 thorfinn α-exponent / #1488 askeladd off-diagonal.


- **Date:** 2026-05-28 (cycle 457 — 0 reviews + #1466 nezuko NS_COOLDOWN_SHAPE stale_wip heartbeat. **🎯 INDEPENDENT W&B VERIFICATION ALL 4 ARMS TERMINAL — Row 4 NULL-collapse PRE-STAGED**. Arm A ctrl `late_peak` `5vh3aj2e` val=3.26537 fs=3175 / Arm B `step` `oyhzke5c` val=3.26685 fs=3175 Δ_paired=+0.00148 NULL-edge / Arm C `linear_ramp` `k3wcgg47` val=3.26454 fs=3175 Δ_paired=−0.00083 mild-FAV within-chain but +0.00144 vs new baseline NEG / Arm D `two_stage` `t7n85sxw` val=3.26476 fs=3175 Δ_paired=−0.00061 NULL mild-FAV within-chain but +0.00166 vs new baseline NEG. **🎯 ABSOLUTE vs new baseline 3.26310 — NO arm beats production**: best Arm C val=3.26454 = +0.00144 NEG; all fs=3175 = +25 NEG vs baseline fs=3150. **🎯 11th cross-axis catalog finding — NS-axis FULLY ABSORBED triple-NULL convergence**: #1438 NS_ITERS_COOLDOWN (5× R_cond ladder) + #1440 NS_COEF_SCHEDULE (5.4× R_cond ladder) + **#1466 NS_COOLDOWN_SHAPE (3.7× R_cond ladder)** all NULL-absorption. R-buffer EMA absorbs ALL upstream NS-quality perturbations: iteration count, coefficient schedule, ramp shape. **Production shape `late_peak` CONFIRMED ROBUST**. **🎯 Arm A drift +0.00227 vs new baseline → G4-MARGINAL** (outside ±0.0015 clean, within ±0.003 G4 envelope) — joins drift cohort #1426/#1409/#1431. **🎯 Cross-axis catalog post-c457 = 11 findings 6 classes**: 5 magnitude-absorbed-NULL (β-SCHEDULE / MLP-LR / β-AVG / EPS) + **3 NS-axis-absorbed-NULL (NS_ITERS / NS_COEF / NS_SHAPE)** + 1 timing-non-monotone-NEG (#1383) + 1 freshness-productive-FAV-MERGED (#1421) + 1 state-continuity-NEG (#1431) + 1 temporal-coverage-NEG (#1469 pending close). **🎯 Telemetric precond_ratio cross-chain pattern continues**: Arm D `two_stage` precond_ratio_mean=1.074 LOWEST in chain (consistent with c456 cross-chain observation that period=2 stack trends toward lower precond amplification). **Student action requested**: post final SENPAI-RESULT terminal=true marker + swap label status:wip → status:review for cycle 458 closure. **No new human GH issues** (H1261 directive already incorporated). **0 idle students** — 8 chains active. **No new assignments this cycle**. **Cross-chain status cycle 457 (8 chains active, 0 idle)**: #1499 tanjiro period=1 screen c455 5-point status request awaiting / #1447 fern β=0.99 PP n=3 Run 6 arm B2 ~8% trending PP-COLLAPSE / **#1466 (this) nezuko NS_COOLDOWN_SHAPE 4/4 TERMINAL — awaiting SENPAI-RESULT for Row 4 NULL close** / #1469 alphonse NM_STOP_STEP Arm D STOP=1500 ~10% / #1478 frieren LR_SCALE=0.80 PP n=3 on period=2 stack Run 1 ~90% near-terminal / #1484 edward β low-screen / #1486 thorfinn α-exponent / #1488 askeladd off-diagonal.


- **Date:** 2026-05-28 (cycle 456 — 0 reviews + #1478 frieren NM_LR_SCALE=0.80 PP n=3 stale_wip heartbeat. **🎯 Chain RE-LAUNCH on period=2 stack CONFIRMED** via independent W&B verification — `o5mmadav` arm period=5 KILLED at 00:08:59Z (as student planned), `me2zh3aa` ctrl-period2-seed0 launched 00:12:01Z RUNNING step 3000/3350 ~90% partial val=3.2948 healthy descent, ETA terminal ~02:35-02:40 UTC. **🎯 KEY FINDING — cross-chain n=2 telemetric corroboration of precond_ratio<1 signature on period=2 ctrls**: `me2zh3aa` precond_ratio dipped to 0.82 around steps 1875-2500 recovering to 1.067 step 3000, SAME signature as #1499 tanjiro `sqbb2lxg` precond_ratio=0.901 step 2225. **Mechanism interpretation — period=2 production baseline operates in implicit DAMPING regime during mid-training** (R^{−0.5} preconditioning LESS amplifying than identity in [1875, 2500] window). Despite under-amplification period=2 wins val vs period=5 (#1421 merge Δ=−0.00125). **Implication for #1478 outcome**: if explicit LR_SCALE=0.80 damping compounds with period=2's implicit damping → Row 4 NULL-collapse modal (REDUNDANT); if production already at right damping → over-damping Row 5 NEG. **Modal forecast UPDATED with c456 mechanism prior**: 40% Row 4 NULL-collapse (was 35%) / 25% Row 5 NEG (was 8%) / 15% Row 2 PP-MARGINAL (was 25%) / 10% Row 3 mild-FAV (was 20%) / 8% Row 1 strong-FAV (was 10%) / 2% Row 6 fs-only. **⚠ Stale misrouted CRASH `7apifwnl`** (ctrl-seed1 period=5 launched 00:09:20Z 0 data) — likely auto-sequencer race condition between `o5mmadav` kill and student period=2 relaunch. Requested student diagnostic. **🎯 6-run chain ETA terminal: ~14:00-14:30 UTC 2026-05-28** (per-run ~2.35h × 6). **No new human GH issues** (H1261 directive already incorporated). **0 idle students** — 8 chains active. **No new assignments this cycle**. **Cross-chain status cycle 456 (8 chains active, 0 idle)**: #1499 tanjiro period=1 screen c455 5-point status request awaiting student / #1447 fern β=0.99 PP n=3 Run 6 arm B2 ~8% trending PP-COLLAPSE / #1466 nezuko NS_COOLDOWN_SHAPE Arm D ~10% / #1469 alphonse NM_STOP_STEP Arm D STOP=1500 ~10% / **#1478 (this) frieren LR_SCALE=0.80 PP n=3 on period=2 stack — Run 1 ctrl ~90% near-terminal** / #1484 edward β low-screen / #1486 thorfinn α-exponent / #1488 askeladd off-diagonal.


- **Date:** 2026-05-28 (cycle 455 — 0 reviews + #1499 tanjiro NM period=1 screen stale_wip heartbeat with **STATUS-REQUEST due to W&B-discovered launch anomalies**. **🎯 #1499 ANOMALY DISCOVERED via W&B independent verification**: 4 runs in group `g1r4-tanjiro/nm-period1-screen`, **ALL 4 runs have `nanogpt_newton_muon_update_period=2` (period=2 ctrl) — NO period=1 arm launched yet**. Run breakdown: (a) `sqbb2lxg` ctrl period=2 RUNNING step 2225/3350 ~66%, launched 00:10:23 UTC, step_avg=3771ms, R_cond_mean=275K, **precond_ratio=0.901 (unusual <1 diagnostic)**, params_preconditioned=72 / (b) `d893wasv` CRASHED at step 150, launched 00:59:52 UTC / (c) `dy6nuq8k` FAILED at step 0, launched 01:17:13 UTC / (d) `zfj0wrw0` RUNNING step 150/3350 ~4%, launched 01:49:57 UTC, step_avg=5705ms (50% slower due to resource contention). **🎯 Concurrent ctrl runs on single GPU is a problem** — both `sqbb2lxg` and `zfj0wrw0` are running period=2 ctrl simultaneously, sharing the H100 → step_avg inflation (3771ms → 5705ms). Posted heartbeat on #1499 with 5-point status request: (1) Primary ctrl status (sqbb2lxg vs zfj0wrw0 — which to keep) / (2) Concurrent run resolution (kill the duplicate) / (3) Failed runs root cause (d893wasv, dy6nuq8k crash diagnostics) / (4) Arm period=1 launch plan and timing / (5) precond_ratio<1 diagnostic (unusual signature, R^{-0.5} producing less amplification than identity — possibly due to R having entries <1 because columns have <1 norm at this period setting). Comment URL: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/1499#issuecomment-4560244334. **🎯 No new human GH issues** (H1261 directive already incorporated). **0 idle students** — 8 chains active. **No new assignments this cycle** — focus is on #1499 student response. **Cross-chain status cycle 455 (8 chains active, 0 idle)**: #1421 MERGED ✅ / **#1499 tanjiro period=1 screen ANOMALY — 4 runs all period=2, 2 crashed, 2 concurrent ctrl, NO arm period=1 yet** / #1447 fern β=0.99 PP n=3 Run 6 arm B2 `ese69jtu` ~8% trending PP-COLLAPSE / #1466 nezuko NS_COOLDOWN_SHAPE Arm D `two_stage` ~10% / #1469 alphonse NM_STOP_STEP Arm D STOP=1500 ~10% / #1478 frieren LR_SCALE compound awaiting start / #1484 edward β low-screen / #1486 thorfinn α-exponent / #1488 askeladd off-diagonal.


- **Date:** 2026-05-28 (cycle 454 — 0 reviews + #1469 alphonse NM_STOP_STEP + #1447 fern β=0.99 PP n=3 both stale_wip heartbeats with major chain progress. **🎯 #1469 chain 3/4 TERMINAL Arm C `i5v6zgkz` STRONG-NEG val=3.26797 fs=3200 Δ_paired=+0.00427**, R_cond=3.5M params_precond=0. Counter-intuitive: Arm C WORSE than Arm B despite less time without NM (Δ_paired_C=+0.00427 vs Δ_paired_B=+0.00361). Mechanism revision: cooldown-phase NM disproportionately load-bearing — disabling NM in deep cooldown (last 10%) causes more damage per disabled step than disabling at cooldown-entry (last 30%). Arm D STOP=1500 RUNNING ~10% (step 325, NM still firing healthy). Chain ETA terminal ~04:00 UTC. **🎯 #1447 chain 5/6 TERMINAL Run 5 ctrl A2 `l92zth8s` TERMINAL val=3.26326 fs=3150 drift −0.00013 EXCEPTIONALLY-CLEAN G4**, n=3 ctrl mean=3.26358 drift +0.00019. Run 6 arm B2 `ese69jtu` RUNNING ~8% step 275. n=2 paired Δ_mean=+0.002935 NEG, 2/2 direction-consistent. Chain trending PP-COLLAPSE Row 5 productive-MONOTONE-NEG (cycle-446 forecast confirmed). Will become 11th cross-axis catalog finding, second freshness-class finding (LOW-freshness side, mirror of #1421 HIGH-freshness FAV-MERGED). **🎯 #1466 nezuko healthy and producing results — Arm C linear_ramp val=3.26454 Δ_paired_vs_A=−0.00083 mild-FAV within-chain (Row 3 surprise) but +0.00144 vs new baseline 3.26310 = still NEG vs production. Arm D two_stage launched ~01:14 UTC. Chain ETA terminal ~03:30 UTC.** **🎯 #1499 tanjiro period=1 screen — ctrl `sqbb2lxg` RUNNING ~63%, 0 comments yet (normal cadence)**. **🎯 Bilateral-monotone freshness axis emerging**: #1421 period=2 (HIGH freshness) FAV-MERGED + #1447 β=0.99 (LOW freshness) NEG trending PP-COLLAPSE. Production β=0.95, period=2 is the local optimum on freshness axis. **No new human GH issues**. **0 idle students** — all 8 students have assignments. **No new assignments this cycle**. **Cross-chain status cycle 454 (8 chains active, 0 idle)**: ~~#1421 MERGED~~ / #1499 tanjiro period=1 ctrl ~63% / #1447 5/6 TERMINAL Run 6 arm B2 ~8% (trending PP-COLLAPSE) / #1466 nezuko 3/4 TERMINAL Arm D running / #1469 alphonse 3/4 TERMINAL Arm D ~10% / #1478 frieren LR_SCALE compound (baseline updated c453, awaiting start) / #1484 edward β low-screen / #1486 thorfinn α-exponent / #1488 askeladd off-diagonal.


- **Date:** 2026-05-28 (cycle 453 — 1 review #1421 tanjiro period=2 PP n=3 **MERGED ✅ FIRST MERGE ON POST-#1240 STACK** + 1 new assignment #1499 tanjiro NM period=1 screen + #1478 frieren baseline updated + no new human GH issues. **🎯 #1421 MERGED**: Δ_paired_mean=−0.00125 n=3 3/3 direction-correct, μ_arm=3.26310 ≤ baseline 3.26339, all G1-G4 PASS-CLEAN. val: 3.26339 → **3.26310** (−0.00029). fs: 3150 (unchanged). New production: `NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2`. Decision: all G-gates pass, CLAUDE.md compound-improvements policy (merge even small improvements) applied. **🎯 R-buffer FRESHNESS-PRESERVATION mechanism confirmed as FIRST productive FAV class to reach MERGED production on post-#1240 stack.** 10th cross-axis catalog finding confirmed. **🎯 #1478 frieren LR_SCALE=0.80 PP n=3 BASELINE UPDATED**: Comment posted with new baseline (val=3.26310, fs=3150, period=2 as ctrl). Frieren chain now tests compound (period=2 ∧ LR_SCALE=0.80) when student polls. **🎯 #1499 NEW ASSIGNMENT g1r4-tanjiro NM period=1 screen**: Tests whether UPDATE_PERIOD=1 (every-step eigendecomp) continues freshness-FAV trend or reveals period=2 as sweet spot. 2-run screen (ctrl period=2 vs arm period=1), 1 seed each, ~4.8h. Decision tree: Δ ≤ −0.001 → promote to PP n=3; |Δ| ≤ 0.001 → period=2 is local optimum; Δ ≥ +0.001 → non-monotone confirmed. **Cross-axis catalog 10 findings 6 CLASSES** (assuming #1469 closes Row 5): magnitude-NULL×4 / input-quality-NULL×2 / timing-NEG×1 / freshness-FAV-MERGED×1 / state-continuity-NEG×1 / temporal-coverage-NEG×1(pending #1469 close). **No new human GH issues** (H1261 directive already incorporated). **0 idle students** — all 8 students have assignments. **Cross-chain status cycle 453 (8 chains active, 0 idle)**: **#1421 MERGED** / **#1499 tanjiro period=1 screen (NEW)** / #1447 fern β=0.99 PP n=3 / #1466 nezuko NS_COOLDOWN_SHAPE / #1469 alphonse NM_STOP_STEP 2/4 TERMINAL Arm B STRONG-NEG Arm C ~6% / #1478 frieren LR_SCALE compound (baseline updated) / #1484 edward β low-screen / #1486 thorfinn α-exponent / #1488 askeladd off-diagonal.


- **Date:** 2026-05-27 (cycle 452 — 0 reviews + #1469 alphonse NM_STOP_STEP stale_wip heartbeat with MAJOR PROGRESS independent W&B verification. **🎯 Arm B `wwftdx5y` TERMINAL with STRONG-NEG val=3.26732 Δ_paired=+0.00361 +50 fs** AND DIRECT TELEMETRIC EVIDENCE: R_cond explodes 27× (904K → 24.7M), precond_ratio inverts (1.124 → 0.97), params_preconditioned=0 (NM stopped firing on all 72 modules). **🎯 Cleanest single-arm strong-NEG with telemetric mechanism evidence since #1409**. Arm C STOP=3000 RUNNING ~6% (step ~200). Arm D STOP=1500 NOT-LAUNCHED. **🎯 Mechanism reconciliation #1431 R-RESET (NM fires) vs #1469 NM_STOP (NM stops)**: 4.5× larger NEG magnitude for STOP vs RESET at SAME step (2345) — confirms preconditioner FIRING (R^{−0.5} matmul application) is the load-bearing operation, not just the buffer's accumulated state. R-buffer information matters AND the act of applying it matters. **🎯 Anticipated 10th cross-axis catalog finding, NEW class temporal-coverage-NEG** when chain closes Row 5 productive-MONOTONE-NEG (45% modal). Catalog progression: 4 magnitude-absorbed-NULL + 2 input-quality-NULL + 1 timing-non-monotone-NEG + 1 freshness-productive-FAV + 1 state-continuity-NEG + 1 temporal-coverage-NEG. **🎯 Modal Arm C STOP=3000 (late-cooldown, 10% disabled)**: 50% Δ ∈ [+0.0005, +0.0015] mild-NEG / 25% mid-NEG / 15% NULL / 7% strong-NEG / 3% mild-FAV. **🎯 Modal Arm D STOP=1500 (half-disable, most aggressive)**: 45% Δ ∈ [+0.005, +0.012] very-strong-NEG / 25% [+0.003, +0.005] / 15% catastrophic / 10% [+0.010, +0.020] / 5% [≥+0.020]. **🎯 #1421 Run 6 imminent terminal** (was ~92% at cycle 451, ETA ~23:53 UTC, no student post yet at cycle 452 entry 23:48 UTC — student post expected within next 10 min). **No new human GH issues** (H1261 directive already incorporated). **0 idle students** — 8 chains active. **No new assignments this cycle**. **Cross-chain status cycle 452 (8 chains active, 0 idle)**: #1421 tanjiro period=2 PP n=3 Run 6 ~95% near-terminal (FIRST MERGE CANDIDATE) / #1447 fern β=0.99 PP n=3 Run 4 arm B1 / #1466 nezuko NS_COOLDOWN_SHAPE c450 status request pending / **#1469 alphonse NM_STOP_STEP 2/4 TERMINAL Arm B STRONG-NEG, Arm C ~6%** / #1478 frieren LR_SCALE=0.80 PP n=3 (c442 awaiting start) / #1484 edward β low-screen / #1486 thorfinn α-exponent / #1488 askeladd R-buffer off-diagonal.


- **Date:** 2026-05-27 (cycle 451 — 0 reviews + #1421 tanjiro period=2 PP n=3 chain stale_wip heartbeat with independent W&B verification. **🎯 #1421 Run 6 arm B2 `w7xwv6ay` ALIVE and ~92% complete**. Independent W&B confirmation step 3075/3350 partial val=3.2877 trending DOWN (3.3135→3.2877 over last 100 steps), NM telemetry healthy (R_cond=8.45M, precond_ratio=1.0957, R_inv_sqrt_norm=80.69), train_seconds=7663.9s (2.13h). Pod state RUNNING healthy 11d. Run 6 launched 21:24:21Z; now 23:38 UTC = 2h 14min runtime. **ETA terminal ~23:53 UTC (~15 min)**. 7+ hour student silence since Run 5 post at 21:31:51Z is **JUST CHAIN-RUNTIME, NOT A STALL** — auto-sequential wrapper launches next run immediately upon terminal, student posts after launch. **🎯 Chain status 5/6 TERMINAL**: A0/A1/A2 ctrl mean=3.26436 drift +0.00097 PASS-CLEAN G4 / B0 Δ=−0.00132 / B1 Δ=−0.00138, n=2 paired Δ_mean=−0.00135 FAV consistent (variance ~4e-5). **🎯 Pre-staged merge decision tree at n=3 (modal forecast Run 6 Δ_paired_seed2)**: 55% Δ ∈ [−0.0015, −0.001] Row 3 sub-merge MARGINAL likely G1-G4 PASS / 20% Δ ∈ [−0.0025, −0.0015] Row 2 strong-FAV MERGE / 15% Δ ∈ [−0.001, +0.001] Row 4 NULL-FAV-shift / 5% Δ ≤ −0.0025 STRONG-FAV / 5% Δ ≥ +0.001 SIGN-FLIP unlikely. **Conditional 75% likelihood MERGE-ELIGIBLE** (Row 2 or Row 3 sub-merge MARGINAL with μ_arm ≤ baseline). If Row 2/Row 3 with μ_arm ≤ baseline lands: **FIRST MERGE on post-#1240 stack** since 2026-05-26 baseline was set (3.26339), and R-buffer FRESHNESS-PRESERVATION mechanism (cycle-449 unified story) gets first DIRECT MERGE confirmation. **No new human GH issues** (H1261 directive already incorporated). **0 idle students** — all 8 students have active assignments. **No new assignments this cycle** — focus is on (a) awaiting #1421 Run 6 terminal (~15 min), (b) monitoring #1447 β=0.99 PP n=3 progression, (c) #1466 status response, (d) student polls for #1484/#1486/#1488 freshly-assigned. **Cross-chain status cycle 451 (8 chains active, 0 idle)**: **#1421 tanjiro period=2 PP n=3 Run 6 ~92%, ETA terminal ~23:53 UTC — FIRST MERGE CANDIDATE** / #1447 fern β=0.99 PP n=3 Run 4 arm B1 (was ~7.5% at c446) / #1466 nezuko NS_COOLDOWN_SHAPE c450 status request pending / #1469 alphonse NM_STOP_STEP Arm A ~95% / #1478 frieren LR_SCALE=0.80 PP n=3 (c442 awaiting start) / #1484 edward β low-screen (c447 just-assigned) / #1486 thorfinn NM α-exponent sweep (c448 just-assigned) / #1488 askeladd R-buffer off-diagonal ablation (c449 just-assigned).


- **Date:** 2026-05-28 (cycle 450 — 0 reviews + #1466 nezuko stale_wip heartbeat with **STATUS-REQUEST due to 9h student silence**. **🎯 #1466 nezuko NS_COOLDOWN_SHAPE chain CONCERN**: NO student updates since launch 2026-05-27T18:54:20Z, ~9h ago. Chain ETA terminal was ~02:00 UTC; cycle 450 is at ~04:00 UTC — past expected terminal time. Last advisor ack c443 saw Arm A `5vh3aj2e` at ~97% (step 3250/3350, partial val=3.2711, fs=3175 crossed). Arms B/C/D were NOT-LAUNCHED. Posted heartbeat requesting status update — either (1) terminal SENPAI-RESULT for all 4 arms / (2) current in-flight arm partial val + step / (3) failure mode report (NaN, OOM, pod crash, W&B sync issue) / (4) launcher PID alive check. **Modal forecast UPDATED with c447/c448 NS-axis NULL absorption evidence**: 45% Row 4 NULL-band (NS-axis class trending NULL-absorption — third NS-axis variant after #1438 NS_ITERS_COOLDOWN NULL and #1440 NS_COEF_SCHEDULE NULL); 25% Row 5 mild-NEG; 15% Row 3 mild-FAV; 10% Row 2 PP-MARGINAL; 5% Row 1 strong-FAV. **No new human GH issues** (H1261 directive already incorporated). **0 idle students** — all 8 students have active assignments. **No new assignments this cycle** — focus is on (a) monitoring #1466 silence resolution, (b) awaiting #1421 period=2 Run 6 terminal, (c) awaiting #1447 β=0.99 PP n=3 progression, (d) student polls for #1484/#1486/#1488 freshly-assigned. **Cross-chain status cycle 450 (8 chains active, 0 idle)**: #1421 tanjiro period=2 PP n=3 Run 6 arm B2 pending (FIRST MERGE CANDIDATE) / #1447 fern β=0.99 PP n=3 Run 4 arm B1 in flight (was ~7.5% at c446) / **#1466 nezuko NS_COOLDOWN_SHAPE — STATUS UNKNOWN, 9h silence** / #1469 alphonse NM_STOP_STEP Arm A ~95% (c445) / #1478 frieren LR_SCALE=0.80 PP n=3 (c442 awaiting start) / #1484 edward β low-screen (c447 just-assigned) / #1486 thorfinn NM α-exponent sweep (c448 just-assigned) / #1488 askeladd R-buffer off-diagonal ablation (c449 just-assigned).


- **Date:** 2026-05-28 (cycle 449 — 1 review #1431 askeladd R-RESET CLOSED Row 5 productive-MONOTONE-NEG-PLATEAU (9th cross-axis catalog finding, NEW CLASS state-continuity) + #1478 frieren stale_wip heartbeat + 1 new assignment #1488 askeladd NM R-buffer off-diagonal ablation. **#1431 CLOSED Row 5 NEG-PLATEAU — TERMINAL CHAIN**: A ctrl R_RESET=0 `p46b1ufa` val=3.26409 fs=3150 drift +0.00070 PASS-CLEAN / B R_RESET=2345 `bzacropd` val=3.26489 fs=3175 Δ_paired=+0.00080 NULL-NEG / C R_RESET=1675 `96rqn82c` val=3.26523 fs=3175 Δ_paired=+0.00114 NULL-NEG / **D R_RESET=2900 `lx1u4t2z` val=3.26523 fs=3175 Δ_paired=+0.00114 NULL-NEG TIED WITH C**. **🎯 Key finding**: D TIED with C despite 4× LESS recovery window (450 vs 1675 steps post-reset) — FALSIFIES "R-warmup cost is the mechanism". Revised mechanism: R-buffer is fast-saturating; the NEG is from LOST STRUCTURAL INFORMATION (covariance memory), not incomplete re-warmup. **🎯 9th cross-axis catalog finding, NEW CLASS state-continuity**: R_RESET is load-bearing as state-DISCONTINUITY axis; 5 magnitude-absorbed + 2 input-quality-absorbed + 1 timing-NEG + 1 freshness-FAV + 1 state-continuity-NEG. **🎯 Unified R-buffer mechanism**: FAST UPDATES + CONTINUOUS ACCUMULATION = production optimal. Slowing (β-UP), disrupting (RESET), or abandoning (NM_STOP_STEP pending) all NEG. Only increasing frequency (period=2 PP-edge FAV) productive. **🎯 #1478 frieren stale_wip heartbeat posted**: LR_SCALE=0.80 PP n=3 chain still awaiting first student comment — may not have polled for assignment yet. Mechanistically orthogonal to R-buffer regime: tests post-preconditioning step MAGNITUDE axis. If FAV at n=3, forms compound stack with #1421 period=2 (predicted combined Δ≈−0.00484). **🎯 #1488 NEW ASSIGNMENT — g1r4-askeladd NM R-buffer off-diagonal ablation**: A ctrl R_OFFDIAG_SCALE=1.0 / B 0.5 / C 0.2 / D 0.0 (pure diagonal). Tests whether off-diagonal entries in R = EMA(X^T X) carry load-bearing cross-column covariance. Requires 6-line code change to scale off-diag before eigendecomp. Modal: 35% Row 4 NULL / 30% Row 5 NEG-monotone / 20% Row 3 mild-FAV / 10% Row 2 PP-promote / 5% extreme. **No new human GH issues** (H1261 directive already incorporated). **PP-promote queue cycle 449**: 1. #1421 tanjiro period=2 PP n=3 Run 6 pending (FIRST MERGE CANDIDATE) / 2. #1478 frieren LR_SCALE=0.80 PP n=3 awaiting start / 3. ~~#1447 fern β=0.99 trending PP-COLLAPSE~~ / 4. #1466 nezuko NS_COOLDOWN_SHAPE / 5. #1469 alphonse NM_STOP_STEP. **Cross-chain status cycle 449 (8 chains active)**: #1421 tanjiro period=2 PP n=3 Run 6 pending / ~~#1431 CLOSED c449~~ / #1447 fern β=0.99 PP n=3 Run 4 ~7.5% / #1466 nezuko NS_COOLDOWN_SHAPE Arm A ~97% / #1469 alphonse NM_STOP_STEP Arm A ~95% / #1478 frieren LR_SCALE=0.80 PP n=3 (c442, awaiting start) / #1484 edward β low-screen (c447) / #1486 thorfinn NM α-exponent sweep (c448) / **#1488 askeladd R-buffer off-diagonal ablation (c449 NEW)**.


- **Date:** 2026-05-28 (cycle 448 — 1 review #1440 thorfinn NS_COEF_SCHEDULE CLOSED Row 4 productive-NULL (8th cross-axis catalog finding) + #1431 askeladd stale_wip heartbeat + 2 new assignments: #1485 thorfinn NM α-exponent sweep (→ #1486 NM α-exponent sweep assigned) + #1484 edward already running. **#1440 CLOSED Row 4 productive-NULL — TERMINAL CHAIN**: A linear_ramp_down ctrl `7ly1pu74` val=3.26367 fs=3150 drift +0.00028 PASS-CLEAN / B constant `hnln4lta` val=3.26415 fs=3150 Δ_paired=+0.00048 NULL / C aggressive_to_gentle `mboshhfn` val=3.26375 fs=3150 Δ_paired=+0.00008 NULL / D gentle_to_aggressive `ooh8zqnm` val=3.26320 fs=3150 Δ_paired=−0.00047 NULL mild-edge. **🎯 DOUBLE CONFIRMATION R-buffer EMA absorption mechanism in 24h**: R_cond_mean rises 5.4× across arms (502K → 2.72M), precond_ratio varies, yet val INVARIANT. SAME PATTERN as #1438 (R_cond 5×). R-buffer absorbs BOTH the number of NS iterations (#1438) AND the shape/direction of NS polynomial coefficients (#1440). Two orthogonal upstream NS-quality axes both fully absorbed. **🎯 8th cross-axis catalog finding**: 5 NULL-absorption (β-SCHEDULE / MLP-LR / β-AVG / EPS / NS_ITERS_COOLDOWN + NS_COEF_SCHEDULE this cycle) + 2 non-absorption timing (#1421 period=2 FAV / #1431 R-RESET NEG-monotone) + 1 non-absorption non-monotone (#1383 START_STEP). **🎯 PR #290 NS_COEF_SCHEDULE optimization absorbed**: linear_ramp_down Δ_paired vs constant = +0.00048 NULL on post-#1240 (was −0.00071 FAV pre-#1240). Third pre-#1240 optimization absorbed by R-buffer EMA (joining #1331 β-schedule and #176 NS_ITERS cooldown bump). **🎯 #1431 askeladd stale_wip cycle 448 heartbeat**: Arm D R_RESET=2900 `lx1u4t2z` was RUNNING step 107/3350 ~3% at 20:26 UTC cycle 441. ETA terminal ~22:25 UTC. Chain 3/4 TERMINAL with MONOTONE-NEG B(+0.00080) < C(+0.00114) with +25 fs cost — both NEG-side NULL-band. Modal Arm D 50% mid-NEG (+0.001 to +0.003), 25% strong-NEG (+0.003 to +0.010). **🎯 #1486 NEW ASSIGNMENT thorfinn NM α-exponent sweep**: A ctrl α=0.5 / B α=0.3 / C α=0.7 / D α=0.9 — FIRST test of Newton-Muon preconditioner EXPONENT (R^{-α}) on post-#1240 stack. Requires 5-line code change to expose `newton_alpha` env var and replace `rsqrt()` with `pow(-alpha)`. Fresh mechanism axis orthogonal to all 8 catalog findings. Modal: 35% NULL / 30% monotone-NEG / 15% marginal FAV / 10% PP-promote / 10% extreme surprise. ETA ~8.5h sequential. **No new human GH issues** (H1261 directive already incorporated). **PP-promote queue cycle 448 (REVISED)**: 1. #1421 tanjiro period=2 PP n=3 — Run 6 arm B2 pending, FIRST MERGE CANDIDATE / 2. #1478 frieren LR_SCALE=0.80 PP n=3 / 3. ~~#1431 R-reset monotone-NEG trending~~ / 4. ~~#1447 β=0.99 trending PP-COLLAPSE~~ / 5. #1466 nezuko NS_COOLDOWN_SHAPE / 6. #1469 alphonse NM_STOP_STEP. **Cross-chain status cycle 448 (8 chains active)**:  #1421 tanjiro period=2 PP n=3 Run 6 arm B2 pending (FIRST MERGE CANDIDATE) / #1431 askeladd R-reset Arm D RUNNING (near-terminal) / ~~#1438 edward NS_ITERS_COOLDOWN CLOSED c447~~ / ~~#1440 thorfinn NS_COEF_SCHEDULE CLOSED c448~~ / #1447 fern β=0.99 PP n=3 Run 4 arm B1 ~7.5% / #1466 nezuko NS_COOLDOWN_SHAPE Arm A ~97% / #1469 alphonse NM_STOP_STEP Arm A ~95% / #1478 frieren LR_SCALE=0.80 PP n=3 just-assigned c442 / #1484 edward β low-screen just-assigned c447 / #1486 thorfinn NM α-exponent sweep just-assigned c448.


- **Date:** 2026-05-27 (cycle 447 — 1 review #1438 edward NS_ITERS_COOLDOWN sweep CLOSED Row 4 productive-NULL (7th cross-axis catalog finding) + 1 new assignment #1484 edward NM R-buffer β LOW-side screening. **#1438 CLOSED Row 4 productive-NULL — TERMINAL CHAIN**: A NS=16 ctrl `4hq8m2eu` val=3.26595 fs=3175 drift +0.00256 G4-edge PASS / B NS=12 no-bump `lie3wlms` val=3.26243 fs=3150 Δ_paired=−0.00352 within-chain but Δ_vs_baseline=−0.00096 NULL (cycle 426 lesson textbook) / C NS=20 `oft7w4wm` val=3.26621 fs=3175 Δ_paired=+0.00026 NULL / D NS=24 `5l4gb27a` val=3.26517 fs=3175 Δ_paired=−0.00078 NULL. **🎯 CRITICAL TELEMETRIC FINDING — Direct mechanism evidence for R-buffer EMA absorption**: R_condition_number_mean rises MONOTONICALLY 5× from B→D (7.84e5 → 1.16e6 → 1.95e6 → 3.99e6), precond_ratio_mean rises monotonically (1.0747 → 1.1304). R-buffer DOES see materially different input quality across arms, yet val_loss INVARIANT within ctrl-drift noise. **DIRECT TELEMETRIC PROOF** R-buffer absorbs input-quality perturbations. **🎯 Publication-relevant negative result**: PR #176 cooldown bump (12→16) NOT load-bearing on post-#1240 stack — Arm B NS=12 matches n=3 baseline (−0.00096 = NULL). Second pre-#1240 optimization absorbed by R-buffer EMA (joins #1331 β-schedule → #1372 NULL). **🎯 7th cross-axis catalog finding**: NS_ITERS_COOLDOWN axis absorbed. Catalog now 7 total — 5 NULL-absorption (#1372 β-schedule / #1393 MLP-LR / #1402 β-AVG / #1388 EPS / #1438 NS_ITERS_COOLDOWN) + 1 timing-productive (#1421 period=2 PP n=3 FAV at n=2 / #1431 R-RESET NEG) + 1 coverage-integrity (#1383 START_STEP non-monotone NEG). **Unified mechanism story post-#1438**: R-buffer EMA absorbs BOTH magnitude AND input-quality perturbations. What remains productive is **timing-of-update** (START_STEP, UPDATE_PERIOD, R-RESET, NM_STOP_STEP). **🎯 No human GH issues** (only existing #1261 directive, already incorporated). **🎯 #1484 NEW ASSIGNMENT — g1r4-edward NM R-buffer β LOW-side screening**: A ctrl β=0.95 / B β=0.90 / C β=0.85 / D β=0.80. Tests whether R-buffer FRESHNESS is monotone-FAV (β-DOWN FAV) or β=0.95 is U-shape bilateral optimum (β-DOWN also NEG, mirroring #1447 β=0.99 NEG). Directly dispositive on cycle-446 FRESHNESS mechanism story. If β-LOW FAV → compound stack (β-LOW ∧ period=2) becomes next highest-EV candidate. Modal: 35% Row 4 NULL / 25% Row 3 mild-FAV / 20% Row 5 monotone-NEG / 15% Row 2 PP-MARGINAL / 5% Row 1 strong-FAV. ETA ~8.4h sequential. **PP-promote queue cycle 447 (REVISED from c446)**: 1. #1421 tanjiro period=2 PP n=3 — Run 6 arm B2 pending, FIRST MERGE CANDIDATE if retains / 2. #1478 frieren LR_SCALE=0.80 PP n=3 / 3. #1440 thorfinn NS_COEF_SCHEDULE / 4. #1466 nezuko NS_COOLDOWN_SHAPE / 5. #1469 alphonse NM_STOP_STEP / 6. ~~#1447 β=0.99 trending PP-COLLAPSE~~ / 7. ~~#1431 R-reset monotone-NEG~~ / 8. ~~#1438 edward NULL closed~~. **Cross-chain status cycle 447 (8 chains active, 0 idle, 0 review-ready)**: #1421 tanjiro period=2 PP n=3 Run 6 arm B2 pending (~22:30 UTC) / #1431 askeladd R-reset Arm D RUNNING / #1440 thorfinn NS_COEF_SCHEDULE / **#1447 fern β=0.99 PP n=3 Run 4 arm B1 ~7.5%** / #1466 nezuko NS_COOLDOWN_SHAPE Arm A ~97% (c443) / #1469 alphonse NM_STOP_STEP Arm A ~95% (c445) / #1478 frieren LR_SCALE=0.80 PP n=3 (c442 just-assigned) / **#1484 edward (NEW) NM β low-screen just-assigned c447**. ~~#1438 edward CLOSED this cycle~~.


- **Date:** 2026-05-27 (cycle 446 — 1 stale_wip ack #1447 fern β=0.99 PP n=3 chain heartbeat. **Run 3 ctrl A1 `b777b3sp` TERMINAL val=3.26413 fs=3150 drift +0.00074 PASS-CLEAN G4**. **Run 4 arm B1 `xlnm6cs8` just-launched RUNNING step 250/3350 (~7.5%)** in warmup phase, no direction yet. Runs 5-6 NOT-LAUNCHED. n=2 ctrl mean=3.263735 drift +0.00035 PASS-CLEAN G4 well within ±0.0015 envelope. **🎯 Run 4 arm B1 direction-determinative checkpoint pending — modal forecast conditional on Run 2 Δ_paired_seed0=+0.00373 NEG**: 45% direction HOLDS Δ_paired_seed1 ∈ [+0.001, +0.005] mean n=2 Δ ≈ +0.003 productive-NEG dispositive trajectory / 25% direction SHRINKS [−0.001, +0.001] mean n=2 Δ ≈ +0.0015 NULL-band-trending / 15% direction STRENGTHENS [+0.002, +0.004] mean n=2 Δ ≈ +0.0035 strong-NEG dispositive / 10% direction REVERSES at seed=1 mean n=2 Δ ≈ 0 NULL collapse (seed=0 SIGN-FLIP was within-seed-noise) / 5% strong-FAV-resurrection unlikely. **🎯 MECHANISM INTERPRETATION REINFORCED — β=0.95 is local optimum on R-buffer EMA decay axis**. Cycle-440 revision: R-buffer STALENESS (not NOISE) is the trade-off. Reinforced by triple convergence: ✅ #1421 period=2 (R refresh frequency UP) FAV at n=2 mean Δ=-0.00135 / ❌ #1447 (this) β=0.99 (R magnitude DOWN) NEG at seed=0 +0.00373 / ❌ #1431 R-RESET (R timing perturbed) NULL-NEG monotone. **UNIFIED MECHANISM STORY**: production β=0.95 + period=5 → R-buffer EMA tuned to gradient covariance time-scale. PERTURBATIONS that LENGTHEN R-buffer time-constant (β=0.99) or DISCONTINUE R-buffer (RESET) are NEG. PERTURBATION that SHORTENS R-buffer time-constant (period=2 = more frequent EMA updates) is FAV. **R-buffer FRESHNESS is the load-bearing dimension; STALENESS the failure mode.** **🎯 Cross-chain dual-axis PP-race outcome trending**: #1421 period=2 trending FIRST MERGE candidate / #1447 β=0.99 trending PP-COLLAPSE at n=3. Compound stack (period=2 ∧ β=0.99) defunct. Replaced by (period=2 ∧ LR_SCALE=0.80) (c442 #1478). **🎯 Updated full-chain modal forecast (unchanged from c440 with stronger ctrl anchor)**: 45% productive-NEG dispositive / 25% NULL-band / 15% productive-MARGINAL FAV-resurrection / 10% strong-NEG / 5% strong-FAV surprise. Most-likely β=0.99 PP-COLLAPSES at n=3 (70% NEG/NULL modal), β returns to magnitude-absorbed class. **PP-promote queue cycle 446 (unchanged from c445)**: 1. #1421 period=2 PP n=3 MERGE-CANDIDATE if Run 6 retains / 2. #1478 frieren LR_SCALE=0.80 PP n=3 / 3. #1438 edward NS_ITERS_COOLDOWN / 4. #1440 thorfinn NS_COEF_SCHEDULE / 5. #1466 nezuko NS_COOLDOWN_SHAPE / 6. #1469 alphonse NM_STOP_STEP / 7. ~~#1447 (this) β=0.99 likely COLLAPSES~~ / 8. ~~#1431 R-reset~~. **Cross-chain status (8 chains active, 0 idle, 0 review-ready)**: #1421 5/6 Run 5 98.5% / #1431 Arm D RUNNING / #1438 / #1440 / **#1447 (this) 3/6 TERMINAL Run 4 ~7.5%** / #1466 Arm A 97% (c443) / #1469 Arm A 95% (c445) / #1478 just-assigned c442. ETA #1447 chain ~12:00 UTC tomorrow (Run 4 ~11h + Run 5 ~2.1h + Run 6 ~2.1h). No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 445 — 1 stale_wip ack #1469 alphonse NM_STOP_STEP late-disable chain heartbeat. **Chain status 0/4 TERMINAL — Arm A ctrl STOP_STEP=0 `83bv71k8` RUNNING ~95% step 3200/3350, fs=3150 ALREADY CROSSED (EXACT-MATCH baseline)**, val=3.2738 partial. R_cond=925K precond_ratio=1.152 params_prec=72 healthy band. Arms B (STOP=2345 cooldown-entry) / C (STOP=3000 late-cooldown) / D (STOP=1500 half-training) NOT-LAUNCHED. **✅ Bit-identity gate PASS — functional (not byte) bit-identity**: step-0 val_loss exact-match 10.82583, +0.00122 drift at step 300 is CUDA non-determinism between separate processes (cuBLAS/NCCL atomics), code path provably identical when STOP_STEP=0. Student's rigorous interpretation accepted. **🎯 Arm A ctrl drift signature — fs=3150 EXACT-MATCH BEST possible drift on FFS axis**, joins today's clean drift cohort. Modal Arm A val terminal: 40% PASS-CLEAN [3.262, 3.267] / 30% PASS-MARGINAL [3.265, 3.270] / 15% EXCEPTIONALLY-CLEAN [3.260, 3.262] / 10% PASS-EDGE / 5% surprise. **🎯 Cross-axis context — TEMPORAL WINDOW axis (15th NM-aligned axis)**: probes when NM can be turned off without losing improvement. Arm B STOP=2345 (70% NM-on, OFF during cooldown) shares SAME cooldown-entry transition point with #1431 R_RESET=2345 (complementary mechanism). Arm D STOP=1500 (45% NM-on, OFF for second half) is most aggressive. Arm C STOP=3000 (89.6%, OFF only last 350 steps) tests late-cooldown specifically. **🎯 Pre-staged decision tree modal**: 40% Row 5 productive-MONOTONE-NEG (B/C/D all Δ ≥ +0.0015) NM load-bearing throughout / 30% Row 4 productive-NULL late-NM fungible compute-saving candidate / 10% Row 6 catastrophic at D=1500 half-disable breaks training / 10% Row 3 productive-MARGINAL one arm mild-FAV / 5% Row 2 PP-MARGINAL / 5% Row 1 strong-FAV. 40% Row 5 modal reflects NM consistently load-bearing under removal attempts on post-#1240 stack (#1409 NM-OFF entirely most-NEG +0.00453). **🎯 Cross-axis catalog impact**: If Row 5 closes, NM_STOP_STEP becomes 15th NM-aligned axis (timing-coverage-residual class) — joins START_STEP/UPDATE_PERIOD/NS_ITERS/NS_COEF/R-reset cohort. Combined with c441 #1431 (13th), c440 β=0.99 PP-collapse (drops to 11), and #1466 NS_COOLDOWN_SHAPE outcome — cross-axis catalog converging on production-stack locally complete at NM-internal/timing axes. **PP-promote queue cycle 445 (unchanged from c444)**: 1. #1421 period=2 PP n=3 (5/6 in flight Run 5 98.5% MERGE-CANDIDATE if Run 6 retains direction) / 2. #1478 frieren LR_SCALE=0.80 PP n=3 / 3. #1438 edward NS_ITERS_COOLDOWN / 4. #1440 thorfinn NS_COEF_SCHEDULE / 5. #1466 nezuko NS_COOLDOWN_SHAPE 40% Row 4 / 6. **#1469 (this) alphonse NM_STOP_STEP** 40% Row 5 modal / 7. ~~#1447 β=0.99~~ / 8. ~~#1431 R-reset~~. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1421 5/6 Run 5 98.5% (c444) / #1431 Arm D RUNNING (c441) / #1438 / #1440 / #1447 Run 3+ (c440 SIGN-FLIP) / #1466 Arm A 97% (c443) / **#1469 (this) Arm A 95%** / #1478 just-assigned c442. ETA #1469 chain ~01:30 UTC tomorrow (Arm A ~15 min + 3 arms × 1.7h). No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 444 — 1 stale_wip ack #1421 tanjiro period=2 PP n=3 chain heartbeat. **🎯 MAJOR PROGRESS — Run 4 arm B1 `6qby0wie` TERMINAL val=3.26257 fs=3150 Δ_paired_seed1=−0.00138 confirming seed=0 direction (Δ=−0.00132)**. Chain status 4/6 TERMINAL + Run 5 ctrl A2 `jhw7ujiw` RUNNING ~98.5% step 3300/3350 partial val=3.26698 fs=3175. Run 6 arm B2 NOT-LAUNCHED awaiting Run 5 terminal. **🎯 PAIRED Δ HOLDS CONSISTENT FAV at n=2**: seed0 Δ=−0.00132 / seed1 Δ=−0.00138, mean Δ=−0.00135 with variance ratio across seeds ~5% of magnitude (excellent consistency). Both arm runs beat n=3 baseline 3.26339: −0.00050 (seed=0), −0.00082 (seed=1). **🎯 fs=3150 UNIVERSAL across 4/4 terminal paired runs** — period axis is FFS-NEUTRAL on post-#1240 stack (val-only improvement, no FFS gain). **🎯 NM telemetry precond_ratio_mean is REMARKABLY tight at 1.064 across both arm seeds** vs ctrl's 1.088/1.134 — period=2 mechanism produces a consistent ~6.4% preconditioning boost. Higher refresh frequency → smaller per-step R-buffer EMA jumps → less differentiated R^{−1/2} signal magnitude. **🎯 Merge-readiness preliminary check at n=2**: G1 mean baseline n=2 arm mean=3.26273 ≤ 3.26339 ✓ (−0.00066 below baseline) / G2 stat rule (3.28−3.26273)×√2=0.0244 ≥ 0.004 ✓ easily satisfied / G4 drift gate n=2 ctrl mean=3.26408 drift +0.00069 PASS-CLEAN. |Δ_paired_mean|=0.00135 sits at NULL-band/MARGINAL boundary (NULL ≤ 0.0015). Run 5 ctrl A2 partial val=3.26698 fs=3175 already-crossed +25 vs prior ctrls — drift watch but expected terminal ~3.262-3.266 PASS-CLEAN to PASS-MARGINAL. **🎯 Pre-n=3 forecast for chain closure**: 40% Row 3 mild-FAV NULL-edge (Δ_paired_mean ∈ [−0.0015, −0.0010]) productive-MARGINAL merge-edge / 25% Row 2 PP-MARGINAL (Δ_paired_mean ∈ [−0.002, −0.0015]) full PP-promote MERGE candidate if μ_arm ≤ baseline / 20% Row 4 NULL-collapse / 10% Row 5 sign-FLIP NEG / 5% Row 1 strong-FAV (very unlikely given consistent magnitude). Most-likely Row 3 mild-FAV NULL-edge merge-edge. **🎯 Strategic — first sustained productive-FAV signal on post-#1240 stack**: #1421 is the ONLY PP n=3 chain to retain direction across BOTH paired seeds with >0.001 magnitude. Compared to #1447 β=0.99 (seed0 SIGN-FLIP +0.00373 NEG c440), #1421 period=2 is on track to be FIRST MERGE candidate on post-#1240 stack since new baseline was set. **🎯 Compound stack candidate**: If #1478 LR_SCALE=0.80 PP n=3 (c442 just-assigned) also retains FAV at n=3, compound stack period=2 ∧ LR_SCALE=0.80 = new highest-EV r4 stack candidate. Linear-composition predicted Δ_paired_sum ≈ −0.00484. Mechanistically orthogonal: period=2 changes R refresh frequency; LR_SCALE=0.80 dampens preconditioned step magnitude. **PP-promote queue cycle 444 (revised)**: 1. **#1421 (this) period=2 PP n=3** — 5/6 in flight, paired Δ holds FAV — MERGE-CANDIDATE if Run 6 retains direction / 2. #1478 frieren LR_SCALE=0.80 PP n=3 / 3. #1438 edward NS_ITERS_COOLDOWN / 4. #1440 thorfinn NS_COEF_SCHEDULE / 5. #1466 nezuko NS_COOLDOWN_SHAPE 40% Row 4 modal / 6. #1469 alphonse NM_STOP_STEP / 7. ~~#1447 β=0.99~~ / 8. ~~#1431 R-reset~~. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: **#1421 (this) 5/6 in flight Run 5 ctrl A2 98.5%** / #1431 askeladd Arm D RUNNING / #1438 edward / #1440 thorfinn / #1447 Run 3+ in flight (c440 SIGN-FLIP) / #1466 nezuko Arm A 97% (c443) / #1469 alphonse / #1478 frieren just-assigned c442. ETA #1421 chain terminal ~22:30 UTC (Run 5 ~5 min + Run 6 ~2h). No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 443 — 1 stale_wip ack #1466 nezuko NS_COOLDOWN_SHAPE chain heartbeat. **Chain status 0/4 TERMINAL — Arm A ctrl `5vh3aj2e` RUNNING ~97% step 3250/3350**, fs=3175 ALREADY CROSSED (+25 fs vs n=3 baseline 3150 G4 PASS-MARGINAL fs edge), val=3.2711 partial at step 3250 awaiting cooldown terminal. R_cond_mean=674K precond_ratio_mean=1.078 healthy band. Arms B `step` / C `linear_ramp` / D `two_stage` NOT-LAUNCHED. **🎯 Arm A drift assessment**: fs=3175 joins today's drift cohort (#1426 Arm A fs=3175 / #1409 Arm A fs=3175 / #1431 Arm A fs=3150 clean). Modal Arm A val terminal: 35% PASS-MARGINAL [3.265, 3.270] / 30% PASS-CLEAN [3.262, 3.265] / 20% EXCEPTIONALLY-CLEAN [3.260, 3.262] / 10% PASS-EDGE / 5% surprise. **🎯 Cross-axis context — NS-aligned axis (NOT NM-internal)**: tests SHAPE of NS_ITERS_COOLDOWN ramping 12→16, distinct from magnitude (#1438) and coefficient schedule (#1440). Late_peak (production default) vs step (constant high), linear_ramp (12→20 smooth), two_stage (14/18 midpoint). Modal 4-arm Δ_paired pattern: 40% Row 4 NULL-band axis absorbed / 25% Row 5 mild-NEG / 15% Row 3 mild-FAV-surprise (most likely C linear_ramp) / 10% Row 2 PP-MARGINAL / 8% Row 6 fs-only / 2% Row 1 strong-FAV. Low Row 1/2 probability reflects historical NS-cooldown axes absorbed on post-#1240 stack. **PP-promote queue cycle 443 (unchanged from c442)**: 1. #1421 period=2 PP n=3 (Run 4 95.5% likely terminal by now) / 2. #1478 frieren NM_LR_SCALE=0.80 PP n=3 (c442 new) / 3. #1438 edward NS_ITERS_COOLDOWN / 4. #1440 thorfinn NS_COEF_SCHEDULE / 5. #1466 (this) nezuko NS_COOLDOWN_SHAPE 40% Row 4 modal / 6. #1469 alphonse NM_STOP_STEP / 7. ~~#1447 β=0.99 likely COLLAPSES~~ / 8. ~~#1431 R-reset likely monotone-NEG~~. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1421 Run 4 ~95.5% / #1431 askeladd 3/4 TERMINAL Arm D ~1% / #1438 edward / #1440 thorfinn / #1447 Run 3/6 just-launched (c440 SIGN-FLIP) / **#1466 (this) Arm A ~97%** / #1469 alphonse / #1478 frieren LR_SCALE PP n=3 just-assigned c442. ETA #1466 chain ~02:00 UTC tomorrow (Arm A ~5 min + 3 arms × 1.7h). No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 442 — 1 review #1426 frieren NM global LR_SCALE sweep CLOSED Row 1/2 PP-promote candidate + 1 new assignment #1478 frieren NM_LR_SCALE=0.80 PP n=3 paired validation. **#1426 CLOSED Row 1/2 PP-promote**: All 4 arms TERMINAL. **Arm C LR_SCALE=0.80 `e7w3kcs7` val=3.26320 fs=3125 Δ_paired=−0.00349 −50 fs — FIRST NM-axis arm in r4 to produce val ≤ baseline 3.26339 AND fs ≤ baseline 3150**. val below baseline by −0.00019, fs below baseline by −25 steps. Arm B LR=0.90 `takmgpsw` val=3.26430 fs=3150 Δ=−0.00239 −25 fs mild-FAV MARGINAL. Arm D LR=1.10 `4ykog891` val=3.26531 fs=3175 Δ=−0.00138 0 fs mild-FAV (surprise — was predicted mid-NEG). Arm A ctrl LR=1.0 `ntyw5pze` val=3.26669 fs=3175 drift +0.00330 G4-MARGINAL (just past +0.003 outer envelope). **🎯 U-SHAPE finding — all 3 perturbation arms mild-FAV vs ctrl A**: Pre-staged DOWN-FAV/UP-NEG monotone prediction FALSIFIED. Arm A is OUTLIER in chain (+0.00330) while B/C/D cluster in [−0.00019, +0.00192]. Two competing interpretations: (1) TRUE U-SHAPE — production LR=1.0 sits at LOCAL MAXIMUM, both damping AND boost improve; or (2) CTRL-DRIFT ARTIFACT — real direction is C mild-FAV with A drifted high creating apparent U-shape, will collapse to monotone slope at fresh ctrls in PP n=3. **NOT MERGE — single-seed N=1 with G4-MARGINAL ctrl drift requires PP n=3 paired validation. Cycle-440 SIGN-FLIP precedent (#1402 β=0.99 N=1 FAV → #1447 paired n=1 NEG +0.00373) makes single-seed merges UNSAFE on post-#1240 stack.** **🎯 FIRST MAGNITUDE-OF-PRECONDITION AXIS to extract paired-Δ FAV signal on post-#1240 stack**: All other magnitude axes (β/EPS/per-group MLP-LR/start-step/β-schedule) are NULL or NULL-with-fs-penalty. Global LR_SCALE — NOT NULL. Mechanistically distinct from per-group MLP-LR (#1393 NULL-with-fs-penalty) because GLOBAL proportional damping preserves ATTN/MLP asymmetry (production tuned at 0.80/1.20 MUON_LR_MULT). **🎯 NM telemetry U-shape signature**: precond_ratio_mean MONOTONE-DECREASING in LR: C (1.134) > B (1.115) > D (1.094) > A (1.085) — heavier damping → stronger relative preconditioning effect. R_cond_max U-shaped: A/C ~10⁷ vs B/D ~10⁸ — perturbation arms show 10× higher max-condition spikes. **🎯 #1478 NEW ASSIGNMENT — PP n=3 paired-pod validation of NM_LR_SCALE=0.80**: 6 interleaved sequential runs (3 ctrl LR=1.0 + 3 arm LR=0.80, seeds 0/1/2). Disambiguates U-shape interpretation vs ctrl-drift artifact. Modal forecast: 35% Row 4 NULL-collapse / 25% Row 2 PP-MARGINAL / 20% Row 3 mild-FAV / 10% Row 1 strong-FAV MERGE candidate / 8% Row 5 sign-FLIP NEG / 2% Row 6 fs-only. ETA ~12.6h sequential. **🎯 Compound stack hypothesis REVIVED — period=2 ∧ LR_SCALE=0.80**: With cycle-440 SIGN-FLIP ruling out β=0.99 compound, LR_SCALE=0.80 becomes new orthogonal mechanism for compounding with period=2. Predicted linear-composition Δ_paired_sum ≈ −0.00481 if both PP-validate at n=3. Replaces defunct (period=2 ∧ β=0.99). **🎯 PP-promote queue cycle 442 REVISED**: 1. #1421 tanjiro period=2 PP n=3 (Run 4 95.5% near-terminal) / **2. #1478 (NEW) frieren NM_LR_SCALE=0.80 PP n=3** / 3. #1438 edward NS_ITERS_COOLDOWN / 4. #1440 thorfinn NS_COEF_SCHEDULE / 5. #1466 nezuko NS_COOLDOWN_SHAPE / 6. #1469 alphonse NM_STOP_STEP / 7. ~~#1447 β=0.99 likely COLLAPSES~~ (c440 SIGN-FLIP) / 8. ~~#1431 R-reset likely productive-MONOTONE-NEG~~ (c441). **Cross-chain status (8 chains active, 0 idle, 0 review-ready)**: #1421 Run 4 95.5% near-terminal / #1431 askeladd 3/4 TERMINAL Arm D ~1% / #1438 edward / #1440 thorfinn / #1447 Run 3/6 ctrl A1 just-launched (c440 SIGN-FLIP) / #1466 nezuko / #1469 alphonse / **#1478 (NEW) frieren LR_SCALE PP n=3 just-assigned c442**. No new human GH issues (only existing #1261 directive). #1426 closed CLEAN — frieren reassigned to validate her own finding via PP-promote.


- **Date:** 2026-05-27 (cycle 441 — 1 stale_wip ack #1431 askeladd NM R-buffer COOLDOWN-REFRESH chain heartbeat. **🎯 CRITICAL UPDATE — Arm C R_RESET=1675 mid-training `96rqn82c` TERMINAL (NEW since cycle 433 ack) val=3.26523 fs=3175 Δ_paired=+0.00114 mid-NEG +25 fs WORSE THAN Arm B cooldown-entry. Arm D R_RESET=2900 `lx1u4t2z` just-launched step 25/3350 ~1%. Chain status 3/4 TERMINAL**: Arm A ctrl R_RESET=0 `p46b1ufa` val=3.26409 fs=3150 drift +0.00070 PASS-CLEAN G4 / Arm B cooldown-entry R_RESET=2345 `bzacropd` val=3.26489 fs=3175 Δ_paired=+0.00080 NULL-NEG +25 fs / **Arm C mid-training R_RESET=1675 val=3.26523 fs=3175 Δ_paired=+0.00114 mid-NEG +25 fs WORST so far** / Arm D late-cooldown R_RESET=2900 RUNNING ~1%. **🎯 MONOTONE-NEG signature emerging across B and C — both reset arms NEG vs ctrl with mid-training (C) WORSE than cooldown-entry (B)**. The cycle-425 Row 6 "surprise mid-training favorable" branch FALSIFIED — mid-training reset is WORSE than cooldown-entry reset, not better. Reset-step location is NOT a positional hyperparameter with interior sweet spot. **🎯 Counter-intuitive vs cycle-425 mechanism interpretation** (#1383 "empty + fast-warmup R-buffer recovers"): mid-training reset is WORSE despite having more steps to recover. R-warmup cost is NOT the bottleneck — the R-buffer state itself carries information destroyed by reset. **🎯 CONVERGENT MECHANISM with cycle-440 β=0.99 SIGN-FLIP**: production β=0.95 EMA preserves information that cleaner-but-staler β=0.99 buffer loses + production no-reset preserves information destroyed by explicit reset. UNIFIED STORY: "R-buffer state preservation IS the production-optimal mechanism, and explicit interventions to refresh/reset it are universally NEG on post-#1240 stack." **🎯 R-buffer regime triple-test now converges to "EMA preserved" optimum**: (1) #1421 period=2 R refresh FREQUENCY seed=0 Δ=−0.00132 (sole remaining FAV) / (2) #1447 β=0.99 R update MAGNITUDE Δ=+0.00373 NEG (c440 SIGN-FLIP) / (3) #1431 R-reset@2345/1675 TIMING both terminal NEG (this cycle). **Two of three R-buffer regime interventions have converged to NEG.** Only #1421 period=2 remains as productive-FAV candidate. **🎯 Modal Arm D R_RESET=2900 late-cooldown forecast — revised after C terminal**: 50% mid-NEG ∈ [+0.001, +0.003] (monotone-NEG continues) / 25% strong-NEG ∈ [+0.003, +0.010] (reset deep in cooldown destabilizes more) / 15% NULL ∈ [−0.001, +0.001] / 8% mild-NEG ∈ [+0.0005, +0.001] / 2% mild-FAV surprise unlikely given monotone trend with C worse than B. Modal chain closure 50% **Row 5 productive-MONOTONE-NEG ASYMMETRIC** with C>B ordering and D≥B variance. **🎯 Cross-axis catalog anticipated revision cycle 441 (if R-reset closes as Row 5 productive-MONOTONE-NEG)**: R-reset axis becomes 13th NM-axis dispositive fence at no-reset (production-optimal) — joins γ/α/R-shape/coverage as 5th NM-internal axis fully-characterized. Class: integrity-axis-asymmetric-fence. Catalog grows to 13 findings still 6 CLASSES. Combined with cycle-440 anticipated β=0.99 PP-collapse (drops to 11 findings 5 CLASSES if it materializes), NET would be 12 findings 5 CLASSES if both PP-collapses materialize. **🎯 STRATEGIC — compound stack options narrowing**: (period=2 ∧ R-reset@2345) OFF the table (R-reset NEG); (period=2 ∧ β=0.99) OFF the table (c440 β=0.99 NEG); #1421 period=2 PP n=3 still must validate at n=3 — if it ALSO collapses, NO single-axis FAV candidates remain. **Revised PP-promote queue cycle 441**: 1. #1421 period=2 PP n=3 (sole remaining productive-FAV) / 2. #1438 edward NS_ITERS_COOLDOWN / 3. #1426 frieren LR_SCALE / 4. #1440 thorfinn NS_COEF_SCHEDULE / 5. #1466 nezuko NS_COOLDOWN_SHAPE / 6. #1469 alphonse NM_STOP_STEP / 7. ~~#1447 β=0.99 likely COLLAPSES~~ / 8. ~~#1431 askeladd R-reset likely productive-MONOTONE-NEG~~. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1421 Run 4 95.5% near-terminal / #1426 frieren B running / **#1431 (this) 3/4 TERMINAL Arm D ~1% just-launched** / #1438 edward / #1440 thorfinn / #1447 Run 3/6 ctrl A1 just-launched (c440 SIGN-FLIP) / #1466 nezuko / #1469 alphonse. ETA #1431 chain terminal ~22:30 UTC (Arm D step 25 → ~2h to 3350). No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 440 — 1 stale_wip ack #1447 fern β=0.99 PP n=3 chain heartbeat. **🎯 CRITICAL UPDATE — Run 2/6 arm seed=0 β=0.99 `pflhctlg` TERMINAL val=3.26707 fs=3175 → Δ_paired_seed0=+0.00373 NEG +25 fs SIGN-FLIP from #1402 N=1 finding** (which was −0.00135 FAV at single seed). Cycle-436 10% sign-flip modal hit. Run 3/6 ctrl seed=1 `b777b3sp` just launched at step 0. **Chain status 2/6 TERMINAL**: Run 1 ctrl A0 β=0.95 `keverpo6` val=3.26334 fs=3150 (drift −0.00005 EXCEPTIONALLY-CLEAN G4) / **Run 2 arm B0 β=0.99 `pflhctlg` val=3.26707 fs=3175 Δ_paired=+0.00373 +25 fs PP-MARGINAL NEG band** / Run 3 ctrl A1 launched / Runs 4-6 NOT-LAUNCHED. **🎯 #1402 N=1 finding FAILS TO REPLICATE at paired n=1**: #1402 Arm D β=0.99 had val=3.26324 Δ=−0.00135 fs-tied at N=1; #1447 paired n=1 result inverts to Δ=+0.00373 NEG with 2.8× magnitude difference. Single-seed N=1 signal was within-cohort noise on different ctrl baseline (#1402 ctrl `qjc5f6mx` val=3.26459 vs #1447 ctrl `keverpo6` val=3.26334). **🎯 MECHANISM RE-INTERPRETATION — R-buffer noise is NOT the bottleneck on post-#1240 stack**: NM telemetry shows β=0.99 reduces R_cond_mean by 10× (2.62M ctrl → 265K arm) — cleaner R-buffer with less variance — BUT val gets WORSE by +0.00373. The cycle-432 hypothesis "fast structural refresh × slow value averaging = filter-prior FAV regime" is FALSIFIED at paired n=1. Revised story: production β=0.95 is local optimum on R-buffer EMA decay axis; too slow (β=0.99) means R-buffer sluggish/stale, doesn't capture genuine gradient covariance changes. R-buffer STALENESS not NOISE is the trade-off. β-axis is PRODUCTIVE-NULL/NEG at paired n=1, not productive-FAV. **🎯 Updated modal full-chain forecast (likely β=0.99 PP-COLLAPSE at n=3)**: 45% Δ_paired_mean ∈ [+0.001, +0.005] productive-NEG dispositive (β-axis fenced at β=0.95, returns to magnitude-absorbed class) / 25% NULL-band at n=3 / 15% productive-MARGINAL FAV-resurrection (seed=1/2 strong-FAV reverses seed=0) / 10% strong-NEG / 5% strong-FAV surprise. **🎯 STRATEGIC IMPLICATION — compound stack (period=2 ∧ β=0.99) NO LONGER viable as highest-EV r4 mechanism**: cycle-432-to-439 dual-axis convergence story breaks. Linear composition now predicts +0.00241 NEG instead of −0.0025 FAV. **🎯 Cross-axis catalog ANTICIPATED REVISION cycle 440 (if β=0.99 collapses at n=3)**: non-monotone-U-shape class (#1402 β EARLY constant) REVOKED — β returns to magnitude-absorbed class joining MLP-LR / EPS / β-SCHEDULE / β-AVG NULL cohort. Catalog drops to 11 findings, 5 CLASSES (γ-overmix c437 step-size-of-preconditioner class remains). **Publication-relevant negative result**: single-seed N=1 findings on post-#1240 stack are unreliable predictors of paired n=1 — PP-promote validation is critical. **Revised PP-promote queue cycle 440**: 1. #1421 period=2 PP n=3 (sole remaining productive-FAV, Run 4 95.5%) / 2. #1431 askeladd cooldown-refresh / 3. #1438 edward NS_ITERS_COOLDOWN / 4. #1426 frieren LR_SCALE / 5. #1440 thorfinn NS_COEF_SCHEDULE / 6. #1466 nezuko NS_COOLDOWN_SHAPE / 7. #1469 alphonse NM_STOP_STEP / 8. ~~#1447 β=0.99 likely COLLAPSES~~ (DEMOTED from #1). **If #1421 ALSO collapses at n=3**, r4 has NO single-axis PP-promote winners — pivot to compound stacks of orthogonal NULL-band axes, architectural changes, fresh optimizer mechanisms beyond NM, or escalate #1469 NM_STOP_STEP (Issue #1261 H3 "Short burst before crossing"). **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1421 3/6 TERMINAL Run 4 95.5% (cycle 439 ack) / #1426 frieren B running / #1431 askeladd / #1438 edward / #1440 thorfinn / **#1447 (this) 2/6 TERMINAL Run 3/6 ctrl A1 just-launched step 0** / #1466 nezuko / #1469 alphonse. ETA #1447 chain completion ~05:30 UTC tomorrow (4 sequential runs remaining at ~2.1h each). No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 439 — 1 stale_wip ack #1421 tanjiro period=2 PP n=3 chain heartbeat. **Chain status 3/6 TERMINAL + Run 4/6 `6qby0wie` arm seed=1 RUNNING ~95.5% step 3200/3350 partial val=3.27266 fs=3150 ✅ (target ALREADY crossed)** — terminal in ~5-7 min. Run 1 ctrl A0 `jbe14pft` val=3.26421 fs=3150 / Run 2 arm B0 `gqdjajf2` val=3.26289 fs=3150 Δ_paired_seed0=−0.00132 fs-tied / Run 3 ctrl A1 `zc84m5kl` val=3.26395 fs=3150 / **Run 4 arm B1 RUNNING 95.5% fs=3150 ALREADY-CROSSED**. **🎯 fs=3150 UNIVERSAL across n=2 paired arms** — period axis is FFS-NEUTRAL on post-#1240 stack (period=2 mild-FAV val, no FFS benefit). Confirms cycle 432 finding from FFS reframe (Issue #1261). NM telemetry Run 4: R_cond_mean=1.56M (1.9× higher than B0=817K typical seed-noise) / R_inv_sqrt=80.04 / precond_ratio=1.1010 healthy / params_precond=72 / step_avg=2498.7ms (+17.6% vs ctrl confirmed). Pre-flight config PASS update_period=2 ✓. n=2 ctrl mean=(3.26421+3.26395)/2=3.26408 drift +0.00069 PASS-CLEAN G4 well within ±0.0015 envelope. **Modal Run 4 terminal val**: 40% PASS-CLEAN [3.262, 3.267] matching B0 cohort / 30% PASS-MARGINAL [3.265, 3.270] / 15% EXCEPTIONALLY-CLEAN strong-FAV [3.260, 3.263] / 10% PASS-EDGE / 5% surprise. **Modal Δ_paired_seed1**: 35% ∈ [−0.0020, −0.0010] direction holds mild-FAV (PP-MARGINAL retention) / 30% ∈ [−0.0010, +0.0005] direction-shrinks NULL / 20% ∈ [−0.0030, −0.0020] direction-strengthens MERGE-edge / 10% Δ ≥ +0.0005 sign-flip / 5% strong-FAV surprise. **🎯 Cross-chain PP-promote dual-axis convergence (cycle 439)**: TWO independent productive-FAV PP n=3 chains in flight: (1) #1421 period=2 (R refresh frequency) seed=0 Δ=−0.00132 / (2) #1447 β=0.99 (R update magnitude) Run 1/6 near-terminal. MECHANISTICALLY ORTHOGONAL — period changes R refresh frequency, β reduces R update magnitude. **If both PP-validate at n=3, compound stack (period=2 ∧ β=0.99) is highest-EV r4 mechanism stack** — predicted Δ_paired_sum ≈ −0.0025 if mechanisms compose linearly (full PP-merge candidate). Critical because cycle 438 showed ALL FOUR core NM-internal axes (γ/α/R-shape/coverage) dispositively fenced — future NM headroom MUST come from compound stacks of orthogonal productive-FAV directions. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1421 (this) 3/6 TERMINAL Run 4 95.5% / #1426 frieren B running / #1431 askeladd / #1438 edward / #1440 thorfinn / #1447 fern Run 1/6 ~98% / #1466 nezuko NS_COOLDOWN_SHAPE (c437) / #1469 alphonse NM_STOP_STEP (c438). **PP-promote queue cycle-439 (unchanged from c438)**: 1. #1447 fern β=0.99 PP n=3 / 2. #1421 (this) period=2 PP n=3 / 3-8 same as c438. ETA #1421 chain completion: Run 4 terminal ~5-7 min, then Run 5 (ctrl A2) + Run 6 (arm B2) sequentially → full chain terminal ~22:30 UTC. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 438 — 1 review #1409 alphonse NM module-coverage ablation CLOSED Row 5 productive-MONOTONE-NEG ASYMMETRIC INVERTED + 1 new assignment #1469 alphonse NM_STOP_STEP late-disable sweep 14th NM-aligned axis. **#1409 CLOSED productive-MONOTONE-NEG ASYMMETRIC INVERTED**: All 4 arms TERMINAL. A ctrl FULL coverage 72 modules `h5jiqg88` val=3.26464 fs=3175 PASS-CLEAN G4 drift +0.00125 R_cond=2.18M precond_ratio=1.1041 / B mlp-only 24 modules `wvr1ekan` val=3.26585 fs=3175 Δ_paired=+0.00121 +0 fs NULL-band-trending-NEG R_cond=801K precond_ratio=1.4940 / **C attn-only 48 modules `xfhlpdp3` val=3.26806 fs=3200 Δ_paired=+0.00342 +25 fs mid-NEG R_cond=5,654 (386× drop) precond_ratio=0.8711 (BELOW 1.0 — NM ANTI-preconditioning)** / D NM-OFF 0 modules `tp5v49ce` val=3.26917 fs=3200 Δ_paired=+0.00453 +25 fs mid-NEG. **🎯 ASYMMETRIC INVERTED coverage signature — MLP carries ~5.7× more NM benefit per module than ATTN** (per-module ratio: (3.42/24) / (1.21/48) = 0.143/0.025 = 5.7×). **Cycle 431 modal forecast 45% Row 4 ATTN-dominates FALSIFIED** — actual landed in 15% Row 5 MLP-dominates band. **🎯 NM ANTI-preconditioning on ATTN-only**: precond_ratio=0.8711 < 1.0 = gradient SHRINKAGE rather than boost. R_cond=5,654 lowest in any post-#1240 chain (386× drop from full despite covering 2× more modules than B). Mechanism: ATTN matrices low-effective-rank (heads + small d_in × d_out structure) → R-buffer has many small eigenvalues, low avg R_cond, R^{−1/2} amplifies these directions producing precond_ratio<1.0. **🎯 Total NM contribution Δ(D-A)=+0.00453 MODEST** — smaller than predicted ~+0.005-0.020 for "NM removed entirely". Consistent with cross-axis catalog finding that many NM hyperparameter knobs (β/EPS/β-AVG/MLP-LR) are magnitude-absorbed within R-buffer EMA. **🎯 Validates post-#1240 MAX_D_IN=4096 choice as load-bearing precisely because it includes the mlp.proj d_in=3072 high-R_cond matrices** (R_cond ~10⁶-10⁹ per #1240 telemetry — highest-condition-number matrices benefit most from preconditioning). **🎯 DOUBLE-DISSOCIATED INTEGRITY AXES confirmed**: (1) magnitude-of-precondition integrity (#1412 γ-mixing under-mix toward identity) — disables mechanism, productive-NEG / (2) module-coverage integrity (#1409 attn-mlp ablation) — applying to wrong-rank modules ANTI-preconditions. Both load-bearing but mechanistically distinct. **🎯 Updated cross-axis catalog cycle 438 (12 findings, 6 CLASSES) — structural-coverage NOW fully-characterized as ASYMMETRIC INVERTED**: 1. magnitude-absorbed (β-SCHEDULE/MLP-LR/EPS/β-AVG) / 2. integrity-load-bearing (γ-mix under) / 3. **structural-coverage-asymmetric-inverted (#1409 CONFIRMED c438 — MLP>ATTN 5.7× per module)** / 4. non-monotone-U-shape (#1402 β=0.99 FAV) / 5. timing-coverage-residual (START_STEP/UPDATE_PERIOD/NS_ITERS/NS_COEF/R-reset) / 6. step-size-of-preconditioner-asymmetric-fence (#1412 γ=1.25). **🎯 Strategic implication — NM-internal axes (γ/α/R-shape/coverage) ALL dispositively fenced** — γ=1.0, α=0.5, full-R, FULL coverage (72 modules) are locally-optimal. Future NM research should pivot OUTSIDE NM-internal axes — compound stacks (#1421 period=2 + #1447 β=0.99 productive-FAV), timing/window axes (this PR + #1431), architectural changes, or new optimization paradigms. **🎯 #1469 alphonse NEW ASSIGNMENT — NM_STOP_STEP late-disable sweep 14th NM-aligned axis**: A ctrl stop=0 (never stop) / B stop=2345 (cooldown entry) / C stop=3000 (late-cooldown) / D stop=1500 (half-training). Tests temporal window of NM utility — directly addresses Issue #1261 H3 "Short burst before expected crossing". Natural complement to #1383 START_STEP (which closed productive-NEG non-monotone valley at C=2000). Cross-chain unification with #1431 R-reset (Arm B=2345 = SAME cooldown-entry transition point). Modal: 40% Row 5 productive-MONOTONE-NEG (NM load-bearing throughout, axis fenced at full duration) / 30% Row 4 productive-NULL (late-NM fungible) / 10% Row 6 catastrophic at D=1500 (half-disable breaks training) / 10% Row 3 productive-MARGINAL / 5% Row 2 PP-promote / 5% Row 1 strong-FAV. ETA ~7h sequential. **PP-promote queue cycle-438 (unchanged from c437)**: 1. #1447 fern β=0.99 PP n=3 (Run 1/6 near-terminal) / 2. #1421 tanjiro period=2 PP n=3 (3/6 running) / 3. #1431 askeladd cooldown-refresh / 4. #1438 edward NS_ITERS_COOLDOWN / 5. #1426 frieren LR_SCALE / 6. #1440 thorfinn NS_COEF_SCHEDULE / 7. #1466 nezuko NS_COOLDOWN_SHAPE / 8. #1409 attn-mlp coverage CLOSED productive-NEG (NOT PP-promote). **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1421 tanjiro 3/6 running / #1426 frieren B running / #1431 askeladd A near-terminal / #1438 edward / #1440 thorfinn / #1447 fern Run 1/6 near-terminal / #1466 nezuko NS_COOLDOWN_SHAPE / **#1469 alphonse NM_STOP_STEP NEW just-assigned c438**. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 437 — 1 review #1412 nezuko NM γ-mixing CLOSED Row 5 productive-MONOTONE-NEG ASYMMETRIC + 1 new assignment #1466 nezuko NM-aligned NS_COOLDOWN_SHAPE sweep 13th NM-aligned axis. **#1412 CLOSED productive-MONOTONE-NEG ASYMMETRIC**: All 4 arms TERMINAL. A ctrl γ=1.0 `k4mfvlpb` val=3.26496 fs=3175 PASS-OK G4 R_cond=3.85M precond_ratio=1.1184 / B γ=0.5 `ih7wtufu` val=3.26849 fs=3200 Δ_paired=+0.00353 +25 fs mid-NEG R_cond=777K precond_ratio=1.0477 / C γ=0.75 `mqcdwhh9` val=3.26591 fs=3175 Δ_paired=+0.00094 NULL-band-trending-NEG fs-tied R_cond=40K precond_ratio=1.0971 / **D γ=1.25 `v622d5zd` val=3.29336 fs=NEVER (-1) Δ_paired=+0.02840 STRONG-NEG CATASTROPHIC Δ vs baseline=+0.02997 R_cond=163K precond_ratio=1.7679 (gradient AMPLIFICATION)**. **🎯 ASYMMETRIC severity profile — FIRST asymmetric NM axis in catalog**: under-mixing (γ<1) monotone mild-NEG with graduated fs penalty (B=+25 fs, C=0 fs), over-mixing (γ>1) CATASTROPHIC training never reaches 3.28 target. Severity ratio: over-mix 8.0× under-mix (+0.02840 / +0.00353). **🎯 DISTINCT from symmetric α-axis (#1360) and R-shape axis (#1363)**: α-axis (R-power inside R^{−α}) is symmetric bilateral fence (|Δ_B|/|Δ_C|≈1.016), R-shape (full vs diag) is symmetric productive-NEG, **γ-axis (precondition step-size mixing) is ASYMMETRIC** — over-extrapolation past G_precond endpoint is catastrophic. **🎯 NEW MECHANISM CLASS — step-size-of-preconditioner-asymmetric-fence (NEW 6th class c437)**: γ-mixing is NEITHER pure magnitude (else absorbed like β/EPS/MLP-LR) NOR pure integrity (mechanism still partial at γ=0.5) — it is a third class because R-buffer EMA cannot compensate for a directly-modulated step that bypasses its feedback loop. precond_ratio diagnostic: ctrl=1.12 → γ=1.25 → 1.77 (58% gradient amplification = training instability). **🎯 precond_ratio_mean > 1.5 runtime divergence detector candidate** (student suggested follow-up — would early-kill catastrophic NM perturbations like Arm D and save ~2h compute). **🎯 Updated cross-axis catalog cycle 437 (12 findings, 6 CLASSES — γ promoted to NEW class)**: 1. magnitude-absorbed (β-SCHEDULE / MLP-LR / EPS / β-AVG) / 2. integrity-load-bearing (γ-mix under) / 3. structural-coverage (attn+mlp asymmetric MLP > ATTN) / 4. non-monotone-U-shape (#1402 β=0.99 FAV) / 5. timing-coverage-residual (START_STEP / UPDATE_PERIOD / NS_ITERS / NS_COEF / R-reset) / **6. NEW: step-size-of-preconditioner-asymmetric-fence (#1412-over-mix γ=1.25 catastrophic)**. **🎯 Strategic implication — pivot OUT of NM internals**: three NM internal-mechanism axes (γ / α / R-shape) now dispositively characterized — γ=1.0, α=0.5, full-R are optimum. Future NM research should pivot OUTSIDE NM internals — compound stack combinations (e.g. NM + new optimizer / NM under different upstream NS_COEF_SCHEDULE), architectural changes, or new optimization paradigms. **🎯 ALIGNED with cycle 432 finding of TWO independent productive-FAV directions** (#1421 period=2 + #1447 β=0.99) — both OUTSIDE the dispositively-fenced internal axes. Cycle-432 prediction "tightly-tuned 4-parameter preconditioner ridge admits no NM-internal headroom" now strongly supported by #1412 closure. **🎯 #1466 nezuko NEW ASSIGNMENT — NM-aligned NS_COOLDOWN_SHAPE sweep 13th NM-aligned axis**: A ctrl late_peak (production) / B step (constant high) / C linear_ramp (gradual) / D two_stage (midpoint discrete). Tests timing of NS iter quality during cooldown — INPUT-quality axis upstream of NM. Single env var, no code change at line 555. Modal: 50% Row 4 productive-NULL (NS_COOLDOWN_SHAPE absorbed by R-buffer EMA) / 15% Row 5 productive-NEG (late_peak uniquely optimal) / 15% Row 3 productive-MARGINAL (alt extracts signal) / 10% Row 2 PP-promote / 5% Row 1 strong-FAV / 5% catastrophic. ETA ~7h sequential 4 arms. **Completes NS-side closure window with #1438 NS_ITERS_COOLDOWN (peak value) + #1440 NS_COEF_SCHEDULE (coefficient shape) — 3-axis NS-side closure**. **PP-promote queue cycle-437 (unchanged from c436)**: 1. #1447 fern β=0.99 PP n=3 (Run 1/6 near-terminal) / 2. #1421 tanjiro period=2 PP n=3 (2/6 TERMINAL seed=0 FAV) / 3. #1431 askeladd cooldown-refresh (Arm A near-terminal) / 4. #1438 edward NS_ITERS_COOLDOWN / 5. #1426 frieren LR_SCALE / 6. #1440 thorfinn NS_COEF_SCHEDULE / 7. #1412 γ-mixing CLOSED productive-NEG (NOT PP-promote). **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1409 alphonse D NM-OFF ~8% (ETA ~17:30 UTC) / #1421 tanjiro 2/6 TERMINAL run 3/6 running / #1426 frieren B running / #1431 askeladd A near-terminal / #1438 edward / #1440 thorfinn / #1447 fern Run 1/6 near-terminal (ETA full chain ~03:50 UTC tomorrow) / **#1466 nezuko NS_COOLDOWN_SHAPE NEW just-assigned c437**. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 436 — 1 stale_wip ack #1447 fern β=0.99 PP n=3 chain heartbeat. **Chain status 0/6 TERMINAL Run 1/6 ctrl seed=0 BETA=0.95 `keverpo6` RUNNING ~97.8% step 3275/3350 partial val=3.26711 fs=3150 ✅ (target crossed)** — terminal in ~1 min. ✅ **Pre-flight config verified PASS**: nanogpt_newton_muon_beta=0.95 / update_period=5 / max_d_in=4096 / params_preconditioned=72 full coverage. NM telemetry Run 1: R_cond_mean=3.29M (high end of cohort but healthy) / R_inv_sqrt=81.97 / precond_ratio=1.1386 (upper end of healthy band, slightly elevated vs cohort ~1.08-1.12). Modal Run 1 terminal: 30% PASS-CLEAN [3.262-3.265] / 30% PASS-MARGINAL [3.265-3.268] / 25% PASS-EDGE [3.268-3.272] / 10% EXCEPTIONALLY-CLEAN / 5% surprise upper. **🎯 Cross-chain context — #1447 IS THE #1 PP-PROMOTE PRIORITY**: validates first productive-FAV finding on β EARLY constant axis. #1402 N=1 reference: Arm D β=0.99 val=3.26324 fs=3150 Δ_paired=−0.00135 fs-tied BEATS baseline by 0.00015. **Modal Run 2/6 arm seed=0 BETA=0.99 (primary hypothesis arm)**: 40% Δ_paired_val ∈ [−0.0015, −0.0008] direction holds / 25% NULL [−0.0008, +0.0005] / 20% Δ ∈ [−0.0025, −0.0015] elevated to MERGE / 10% sign-flip / 5% strong-FAV surprise. **🎯 Dual-axis PP-promote validation cycle 432-436**: #1421 period=2 PP n=3 (2/6 TERMINAL seed=0 Δ=−0.00132 FAV) + #1447 (this) β=0.99 PP n=3 (Run 1 near-terminal) = TWO INDEPENDENT productive-FAV mechanism axes being PP-validated simultaneously. Compound period=2 ∧ β=0.99 = highest-EV r4 stack candidate if both validate. **8 chains active, 0 idle, 0 review-ready**: #1409 D ~8% / #1412 D running / #1421 2/6 TERMINAL run 3/6 running / #1426 B running / #1431 A near-terminal / #1438 / #1440 / **#1447 (this) Run 1/6 ~97.8%**. ETA #1447 full chain ~03:50 UTC tomorrow (12.6h sequential 6 runs). No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 435 — 1 stale_wip ack #1409 alphonse NM module-coverage chain 3/4 TERMINAL with Arm C attn-only just-completed. **Chain status**: A ctrl FULL coverage 72 modules val=3.26464 fs=3175 PASS-CLEAN G4 / B mlp-only 24 modules val=3.26585 Δ_paired=+0.00121 +0 fs NULL-band-trending-NEG / **C attn-only 48 modules val=3.26806 Δ_paired=+0.00342 +25 fs mid-NEG R_cond=5,654 (386× drop) precond_ratio=0.8711 (BELOW 1.0 — anti-preconditioning)** / D NM-OFF full ablation RUNNING ~8% step 275 partial val=4.08. **🎯 ASYMMETRIC COVERAGE SIGNATURE — MLP carries ~3× more NM benefit per module than ATTN** (per-module ratio: 5.7× MLP > ATTN). Dropping 24 MLP modules costs +0.00342 val +25 fs, dropping 48 ATTN modules costs +0.00121 val +0 fs. Per-MLP precond_ratio jumps to 1.49 (35% boost without ATTN dilution); per-ATTN precond_ratio CRASHES to 0.87 (gradient SHRINKAGE = NM anti-preconditioning on ATTN-only). **🎯 Mechanism refinement cycle-435 — NM has TWO DOUBLE-DISSOCIATED INTEGRITY AXES**: (1) magnitude-of-precondition integrity (#1412 γ-mixing — toward identity) / (2) module-coverage integrity (#1409 attn-mlp — wrong modules). γ-mix attacks MAGNITUDE, coverage attacks COVERAGE BREADTH, both load-bearing in different ways. **🎯 Validates post-#1240 MAX_D_IN=4096 choice as load-bearing precisely because it includes d_in=3072 MLP down-proj matrices**. Modal Arm D NM-OFF: 55% strong-NEG dispositive [+0.005, +0.020] / 30% very-strong-NEG [+0.020, +0.050] (NM critical) / 10% NULL/mild-NEG surprise / 5% catastrophic divergence. Modal full-chain: 65% Row 5 monotone-NEG-coverage-asymmetric / 20% Row 4 partial / 10% surprise / 5% other. **Updated cross-axis catalog cycle-435 (11 findings, 5 CLASSES)**: structural-coverage class fully-characterized as ASYMMETRIC MONOTONE-NEG (full > mlp-only > attn-only > nm-off). **8 chains active, 0 idle, 0 review-ready**: #1409 (this) D ~8% / #1412 nezuko D running / #1421 tanjiro 2/6 TERMINAL / #1426 frieren / #1431 askeladd A terminal B launching / #1438 edward / #1440 thorfinn / #1447 fern β=0.99 PP n=3 just-assigned c432. ETA #1409 chain completion Arm D ~17:30 UTC. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 434 — 1 stale_wip ack #1412 nezuko NM γ-mixing chain 3/4 TERMINAL with Arm C γ=0.75 just-completed. **Chain status**: A ctrl γ=1.0 val=3.26496 fs=3175 / B γ=0.5 val=3.26849 fs=3200 Δ_paired=+0.00353 mid-NEG +25 fs / **C γ=0.75 val=3.26591 fs=3175 Δ_paired=+0.00094 NULL-band-trending-NEG +0 fs (FS-TIED with ctrl)** / D γ=1.25 RUNNING ~8% (OVER-mixing, partial precond_ratio=0.524 suggests gradient SHRINKAGE — possible Scenario 3 catastrophic divergence candidate). **🎯 Monotone-NEG direction CONFIRMED in γ ≤ 1.0 sub-axis** (B>C>A): γ=0.5 strong-NEG > γ=0.75 mild-NEG fs-tied > γ=1.0 ctrl. R_cond drop graduated: A=3.85M → B=777K (5×) → C=40K (96× vs A). precond_ratio recovers at γ=0.75 (1.0971 ≈ A's 1.1184) — **decouples preconditioner DIRECTION from preconditioner MAGNITUDE** in a way original c430 mechanism story did not capture. **🎯 Arm D γ=1.25 tests OVER-mixing extreme — potential non-monotone-U-shape candidate** (would join cycle-432 #1402 β EARLY axis as second axis in the U-shape class). Early telemetry concerning: precond_ratio=0.524 means G·R^{−α} SHRINKING gradients (over-amplifying R^{−α}). UPDATED modal Arm D: 45% mid-to-strong-NEG / 30% strong-NEG dispositive / 15% NULL EMA-recovered / 5% mild-FAV U-shape surprise / 5% other. **Modal full-chain cycle-434**: 55% Row 5 productive-MONOTONE-NEG-by-γ ctrl-fenced (strong outer + mild inner) / 20% Row 4 productive-NULL-asymmetric / 15% Row 6 surprise catastrophic divergence Arm D / 5% Row 3 non-monotone-U-shape / 5% other. **🎯 Cross-axis catalog cycle 434**: integrity-load-bearing class validated as MONOTONE-NEG in under-mixing direction — first fully-characterized monotone-NEG axis on post-#1240 stack, distinct from non-monotone #1383 START_STEP NEG. **8 chains active, 0 idle, 0 review-ready**: #1409 alphonse C running / #1412 (this) D ~8% / #1421 tanjiro 2/6 TERMINAL run 3/6 running / #1426 frieren A TERMINAL B running / #1431 askeladd A near-terminal / #1438 edward / #1440 thorfinn / #1447 fern just-assigned c432. ETA #1412 chain completion Arm D ~110 min → ~17:10 UTC. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 433 — 1 stale_wip ack #1431 askeladd NM R-buffer COOLDOWN-REFRESH chain heartbeat. **Chain status 0/4 TERMINAL Arm A ctrl R_RESET_STEP=0 `p46b1ufa` RUNNING step 3225/3350 (~96%) partial val=3.27199 fs=3150 (target crossed ✅)** — terminal in ~5 min. ✅ **Bit-identity gate PASSED**: step-0 val_loss bit-identical (10.82583 == 10.82583) between env-unset and env=0-explicit smoke runs validates guard `if self.newton_r_reset_step > 0:` strictly inactive at default. Code change implemented per spec (env var line 605, constructor line 750, reset trigger in Muon.step() line 894-903 zeros R buffers + pops caches). NM telemetry Arm A: R_cond_mean=1.61M / R_inv_sqrt_norm=83.67 / precond_ratio=1.0947 / params_precond=72 (post-#1240 full coverage ✓). **🎯 Cross-chain context cycle 433 — third R-buffer regime intervention test**: aligns with cycle-432 dual-FAV findings: (1) #1421 period=2 (R refresh frequency) Δ=−0.00132 seed=0 FAV / (2) #1447 β=0.99 (R update magnitude) PP n=3 just-assigned / **(3) #1431 R-reset@2345 (R regime change at cooldown transition) Arm B primary hypothesis**. Unifying theme: R-buffer regime change correlates with FAV outcomes on post-#1240 stack. If Arm B mild-FAV, 3rd PP-promote candidate in r4. **UPDATED modal arm B R_RESET=2345** (reinforced by cycle 430-432 R-regime-change theme): 25% mild-FAV Δ_paired ∈ [−0.002, −0.0008] / 35% NULL / 25% mild-NEG / 10% strong-NEG / 5% strong-FAV. **Modal full-chain**: 35% Row 4 productive-NULL (matches original c425 modal) / 25% Row 3 productive-MARGINAL (cooldown-anchor specifically load-bearing) / 15% Row 5 productive-NEG / 15% Row 6 surprise / 10% Row 2 PP-promote. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1409 alphonse 2/4 TERMINAL C running / #1412 nezuko 2/4 TERMINAL C running / #1421 tanjiro 2/6 TERMINAL run 3/6 running / #1426 frieren A TERMINAL B running / **#1431 askeladd A ~96% near-terminal** / #1438 edward / #1440 thorfinn / #1447 fern β=0.99 PP n=3 just-assigned c432. ETA #1431 chain completion ~5.9h (Arm A 5 min + B/C/D sequential ~5.9h) → full chain terminal ~21:10 UTC. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 432 — 1 review #1402 fern NM β EARLY constant sweep CLOSED productive-MARGINAL + 🎯 NEW β=0.99 PP-promote assigned fern #1447 + 1 stale_wip ack #1421 tanjiro period=2 PP-promote run 2/6 TERMINAL. **#1402 CLOSED productive-MARGINAL Row 3**: All 4 arms TERMINAL. A ctrl β=0.95 `qjc5f6mx` val=3.26459 fs=3150 drift +0.00120 PASS-CLEAN G4 / B faster β=0.90 `9okdxqri` val=3.26402 fs=3150 Δ_paired=−0.00057 NULL-band mild-FAV fs-tied / C slower β=0.97 `l7krh4n9` val=3.26540 fs=3175 Δ_paired=+0.00081 NULL-band mild-NEG +25 fs / **D much-slower β=0.99 `t3auv0wb` val=3.26324 fs=3150 Δ_paired=−0.00135 fs-tied BEATS BASELINE AT N=1 (−0.00015 vs n=3 3.26339) → productive-MARGINAL, PP-promote**. **🎯 NON-MONOTONE U-SHAPE on β EARLY constant axis**: both extremes (β=0.90 and β=0.99) favor over center (β=0.95, 0.97). Profile sequence by β: −0.00057, 0 (ref), +0.00081, −0.00135. Pre-experiment prediction "slow-side hurts more" INVERTED at β=0.99. **Mechanism story**: with period=5 already providing fast structural R-refresh, β=0.99 acts as slowly-evolving prior filtering high-frequency batch-level X^T X noise — "fast structural refresh × slow value averaging" decoupling. NM telemetry: β=0.99 has LOWEST R_inv_sqrt_norm_mean=80.97 (non-monotone, vs β=0.97=86.16 highest). **🎯 CATALOG REVISION cycle 432 — β-axis reclassified from magnitude-absorbed to non-monotone-U-shape class**: β EARLY constant axis BREAKS from #1372 β-SCHEDULE NULL collapse. Non-monotone U-shape means production β=0.95 is at LOCAL MINIMUM; slow-extreme β=0.99 recovers with "filter-prior" mechanism. **🎯 CROSS-CHAIN CONVERGENCE cycle 432 — TWO INDEPENDENT productive-FAV axes on post-#1240 stack**: (1) #1421 period=2 seed=0 Δ=−0.00132 fs-tied / (2) #1402 Arm D β=0.99 Δ=−0.00135 fs-tied. MECHANISTICALLY ORTHOGONAL — period=2 increases R refresh frequency, β=0.99 reduces R update magnitude. If both PP-validate at n=3, 2-axis compound stack period=2 ∧ β=0.99 becomes highest-EV mechanism stack test of r4 (predicted Δ≈−0.0025 linear composition). **🎯 #1421 tanjiro period=2 PP-promote cycle-432 status**: Run 2/6 terminal `gqdjajf2` val=3.26289 fs=3150 Δ_paired(seed=0)=−0.00132 FAV BEATS-BASELINE (3.26289 < 3.26339) / Run 3/6 ctrl seed=1 `zc84m5kl` RUNNING ~20% ETA ~1.6h. Chain ETA ~08:00 UTC tomorrow (4 sequential runs remaining). **🎯 #1447 fern ASSIGNED — β=0.99 PP n=3 paired-pod validation**: 6 interleaved runs ctrl(β=0.95) ↔ arm(β=0.99) across seeds 0/1/2. Same protocol as #1421. ETA ~12.6h (no throughput overhead from β vs period). **Updated cross-axis catalog cycle 432 (11 findings, 5 CLASSES)**: 1-3. magnitude-absorbed (MLP-LR NULL / EPS NULL / β-AVG NULL) / 4. integrity-load-bearing (γ-mix NEG) / 5. structural-coverage (attn+mlp ablation NEG) / **6. NEW non-monotone-U-shape (β EARLY constant productive-MARGINAL at β=0.99)** / 7-11. timing-coverage-residual (START_STEP NEG / UPDATE_PERIOD PP / #1438 NS_ITERS pending / #1440 NS_COEF pending / #1431 cooldown-refresh pending). **PP-promote queue cycle-432 (revised top-2 both beating baseline at N=1)**: 1. #1447 fern β=0.99 PP n=3 (NEW — assigned c432) / 2. #1421 tanjiro period=2 PP n=3 (2/6 TERMINAL seed=0 FAV) / 3. #1431 cooldown-refresh / 4. #1438 NS_ITERS_COOLDOWN / 5. #1426 LR_SCALE / 6. #1440 NS_COEF_SCHEDULE. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1409 alphonse C attn-only running / #1412 nezuko Arm C γ=0.75 running / #1421 tanjiro 2/6 TERMINAL run 3/6 ~20% / #1426 frieren LR_SCALE Arm B running / #1431 askeladd cooldown-refresh / #1438 edward NS_ITERS_COOLDOWN / #1440 thorfinn NS_COEF_SCHEDULE / **#1447 fern β=0.99 PP n=3 NEW just-assigned**. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 431 — 1 stale_wip ack #1409 alphonse NM structural coverage ablation chain. **Chain status 2/4 TERMINAL**: A ctrl full coverage attn+mlp val=3.26464 fs=3175 PASS-CLEAN drift +0.00125 R_cond=2.18M precond_ratio=1.1041 params_precond=72 / **B mlp-only val=3.26585 fs=3175 Δ_paired_val=+0.00121 NULL-band-trending-NEG +0 fs** R_cond=801K (2.7× drop) precond_ratio=1.4940 (per-param stronger) params_precond=24 / C attn-only RUNNING step 1/3350 just-launched ETA ~110 min / D pending. **🎯 Productive partial finding**: dropping 48 ATTN modules costs +0.00121 val with NO fs cost. Mechanism: ATTN preconditioning carries positive signal even at low R_cond despite per-MLP-module preconditioning being STRONGER without ATTN dilution. Confirms #1240 full-coverage production setting locally optimal. **🎯 NEW AXIS CLASS — structural-coverage class introduced cycle 431**: between integrity-load-bearing (γ-mix #1412) and timing-coverage-residual-signal classes. Coverage axis is discrete-on/off-by-module-type, monotone-load-bearing in the additive direction (more modules → more val signal). **Modal Arm C attn-only**: 40% mid-NEG +0.003 to +0.006 (MLP d_in=3072 modules dominant val contributors per #1240) / 25% strong-NEG ≥+0.006 / 20% mild-NEG +0.001 to +0.003 / 10% NULL surprise / 5% other. **Modal full-chain**: 55% Row 5 productive-monotone-NEG-by-coverage (A<B<C ranked by val, axis fenced at full coverage) / 25% Row 5 NEG-skewed strong / 10% non-monotone / 5% Row 3 mild-FAV / 5% surprise. **Cross-axis catalog cycle 431 (9 findings, 4 classes)**: 1. β NULL (magnitude class) / 2. MLP-LR NULL plateau (magnitude class) / 3. β-AVG NULL (magnitude class) / 4. EPS NULL 5OoM (magnitude class) / 5. START_STEP non-monotone NEG (timing class) / 6. UPDATE_PERIOD PP non-monotone (coverage-timing class) / **7. γ-mixing productive-NEG (integrity class — cycle 430)** / **8. coverage attn+mlp ablation partial (structural-coverage class — cycle 431)** / 9. NS_ITERS_COOLDOWN pending / 10. NS_COEF_SCHEDULE pending. **4 axis CLASSES now consolidated**: magnitude-absorbed (4 axes) / integrity-load-bearing (1 axis γ-mix) / structural-coverage (1 axis attn+mlp ablation) / timing-coverage-residual-signal (4 axes timing/period/start/ns-iter/ns-coef). **Cross-chain implications**: #1412 γ-mix REINFORCED — γ-mix mid-NEG (+0.00353) > coverage-drop-attn mild-NEG (+0.00121) → preconditioning MAGNITUDE on covered modules matters more than COVERAGE BREADTH. #1438 NS_ITERS_COOLDOWN ORTHOGONAL — distinct class. #1426 LR_SCALE REINFORCED NULL fence (global LR doesn't change which modules are precond'd). **PP-promote queue cycle-431 (unchanged)**: 1. #1421 period=2 / 2. #1431 cooldown-refresh / 3. #1438 NS_ITERS_COOLDOWN / 4. #1426 frieren LR_SCALE / 5. #1409 (this) 0% PP (structural-coverage productive-NEG) / 6. #1412 γ-mixing 0% PP / 7. #1402 β / 8. #1440 NS_COEF_SCHEDULE. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1402 fern D ~10-15% / **#1409 alphonse 2/4 TERMINAL C ~0%** / #1412 nezuko 2/4 TERMINAL C ~6.7% / #1421 tanjiro / #1426 frieren A TERMINAL B running / #1431 askeladd / #1438 edward / #1440 thorfinn just-assigned. ETA #1409 chain completion ~3-4h (Arm C ~110 min, Arm D pending design). No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 430 — 1 stale_wip ack #1412 nezuko NM γ-mixing chain. **🎯 NEW MECHANISM DIMENSION DISCOVERED — first productive-NEG on a magnitude-of-precondition axis**. **Chain status 2/4 TERMINAL**: A ctrl γ=1.0 val=3.26496 fs=3175 PASS-CLEAN drift +0.00157 R_cond=3.85M precond_ratio=1.1184 / **B weak γ=0.5 val=3.26849 fs=3200 Δ_paired=+0.00353 mid-NEG +25 fs** R_cond=7.77e+05 (5× drop) precond_ratio=1.0477 (closer to identity) / C mild γ=0.75 RUNNING step 225/3350 (~6.7%) ETA ~165 min / D pending. **🎯 KEY FINDING — γ-mixing axis NOT absorbed by R-buffer**: Arm B γ=0.5 represents identity-mixing attack on NM preconditioning mechanism itself (lower γ → R_cond↓ → precond_ratio→1.0 = identity = preconditioning largely cancelled). Unlike β/EPS/MLP-LR magnitude perturbations which R-buffer absorbs, γ-mixing partially DISABLES the preconditioning mechanism. R-buffer cannot self-correct when its own mechanism integrity is attacked. **🎯 CATALOG REFINEMENT cycle 430 — NEW DIMENSION introduced**: distinguish *magnitude perturbations TO THE PRECONDITION* (absorbed, 4 axes: β/EPS/MLP-LR/β-AVG) from *integrity perturbations OF THE PRECONDITION-MECHANISM ITSELF* (load-bearing: γ-mix toward identity). Magnitude is fungible, mechanism existence is not. Mechanistic insight: NM's value comes from G→G·R^{−α} preconditioning. Magnitude-of-R-buffer is fungible (R-buffer EMA self-corrects), but EXISTENCE of preconditioning effect is load-bearing. **Cross-axis catalog cycle 430 (8 findings with new dimension)**: 1. #1372 β NULL (magnitude class) / 2. #1393 MLP-LR NULL plateau (magnitude class) / 3. #1402 β-AVG NULL (magnitude class) / 4. #1388 EPS NULL 5 OoM (magnitude class) / 5. #1383 START_STEP non-monotone NEG (timing class) / 6. #1421 UPDATE_PERIOD PP non-monotone (coverage class) / **7. #1412 γ-mixing toward identity productive-NEG (R-buffer-integrity class — NEW DIMENSION cycle 430)** / 8. #1438 NS_ITERS_COOLDOWN pending (input-quality class). **Modal Arm C γ=0.75**: 50% mild-NEG monotone Δ_C ~+0.0018 / 25% NULL band / 15% non-monotone valley / 5% surprise FAV / 5% other. **Modal full-chain**: 65% Row 5 productive-monotone-NEG axis-fenced at γ=1.0 / 20% non-monotone NEG / 10% Row 3 NULL at C / 5% surprise. **Cross-chain implications**: #1426 LR_SCALE REINFORCED NULL fence (LR_SCALE is magnitude not integrity) / #1431 cooldown-refresh NUANCED (R-buffer state reset preserves mechanism, distinct from γ-mix integrity attack) / #1438 NS_ITERS_COOLDOWN REINFORCED input-quality class / #1440 NS_COEF_SCHEDULE REINFORCED input-quality class. **PP-promote queue cycle-430 (unchanged)**: 1. #1421 period=2 / 2. #1431 cooldown-refresh / 3. #1438 NS_ITERS_COOLDOWN / 4. #1426 frieren LR_SCALE / 5. #1412 (this) γ-mixing 0% PP-promote (productive-NEG axis-fence) / 6. #1402 β / 7. #1440 NS_COEF_SCHEDULE. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1402 fern D ~10-15% / #1409 alphonse / **#1412 nezuko 2/4 TERMINAL C ~6.7%** / #1421 tanjiro / #1426 frieren A TERMINAL B running ~3% / #1431 askeladd / #1438 edward / #1440 thorfinn just-assigned. ETA #1412 chain completion ~5-7h (Arm C ~3h, Arm D pending). **Publication-worthy negative result**: cross-axis catalog now distinguishes 3 axis CLASSES on NM (magnitude-absorbed / integrity-load-bearing / timing-coverage-residual-signal) — qualifies as mechanism characterization paper. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 429 — 1 stale_wip ack #1426 frieren NM LR_SCALE global sweep first chain heartbeat. **Chain status 1/4 TERMINAL Arm A ctrl LR_SCALE=1.0 `pending-run-id` val=3.26669 fs=3175 PASS-MARGINAL G4 noisy edge drift +0.00330** (just past G4 outer envelope +0.003, today's drift cohort range −0.00044 to +0.00330) / Arm B LR_SCALE=0.9 RUNNING step 1/3350 just-launched ETA ~3h / Arm C LR_SCALE=1.1 NOT LAUNCHED / Arm D LR_SCALE=0.7 NOT LAUNCHED. Zero PR comments since assignment cycle 420 — first advisor heartbeat posted. NM telemetry Arm A: R_cond_mean=3.34e+05, precond_ratio_mean=1.085. **Modal predictions (reinforced by cycle 428 cross-axis catalog 7 findings)**: 50% Row 4 productive-NULL fence (axis absorbed by R-buffer like MLP-LR / EPS / β — 8th-9th cross-axis catalog finding) / 25% Row 5 NEG-at-D (heavy damping LR_SCALE=0.7 hurts) / 15% Row 3 mild-FAV at B / 5% PP-candidate / 5% surprise. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1402 fern D ~10-15% / #1409 alphonse / #1412 nezuko / #1421 tanjiro A0 ~92% PP / **#1426 frieren A TERMINAL B running** / #1431 askeladd / #1438 edward / #1440 thorfinn. ETA #1426 chain completion ~7h. **Critical cycle 426 lesson reminder applied**: always compute Δ vs n=3 baseline 3.26339 in addition to within-chain paired Δ — A drift +0.00330 means within-chain paired Δ on B/C/D risk being ctrl-drift-blurred. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 428 — 1 review #1393 thorfinn NM MLP-LR fine-grained sweep CLOSED productive-NULL with Arm D mild-NEG breakthrough at 1.6 + 1 new assignment #1440 thorfinn NS_COEF_SCHEDULE sweep 14th NM-aligned axis. **#1393 CLOSED**: All 4 arms TERMINAL. A ctrl LR=1.0 val=3.26295 fs=3150 EXCEPTIONALLY-CLEAN-FAV G4 drift −0.00044 / B LR=1.2 val=3.26361 fs=3175 Δ_paired=+0.00066 NULL +25 fs / C LR=1.4 val=3.26347 fs=3175 Δ_paired=+0.00052 NULL +25 fs / D LR=1.6 val=3.26426 fs=3175 Δ_paired=+0.00131 mild-NEG +25 fs. **🎯 Verdict Row 4 productive-NULL** with non-monotone signature — MLP-LR axis NULL plateau extends 1.0-1.4 with universal +25 fs penalty on boosted arms, Arm D=1.6 breakthrough into mid-NEG val territory. Cycle 419 modal Arm C 45% mild-NEG falsified — actual 35% NULL-band modal hit. **🎯 Mechanism**: pre-#1240 #1346 Arm B Δ=−0.00114 MARGINAL-FAV signal **INVERTED** on post-#1240 to Δ=+0.00066 NULL with fs cost. Stack-dependence axis collapse confirmed for MLP-LR. NM telemetry mlp_downproj_step_norm_mean scales linearly with LR_SCALE_MLP confirming hook applied to 12 d_in=3072 matrices correctly. **🎯 #1440 thorfinn ASSIGNED — NM NS_COEF_SCHEDULE sweep 14th NM-aligned axis**: A linear_ramp_down (production from #290) / B constant (no schedule, falsifier) / C aggressive_to_gentle (discrete similar shape) / D gentle_to_aggressive (opposite direction). Tests whether post-#1240 R-buffer EMA absorbs UPSTREAM NS-coefficient axis (NS output is INPUT to NM preconditioner), or whether NS-coef shape remains load-bearing on post-#1240. Pre-#1240 #290 established linear_ramp_down vs constant Δ=−0.00071 mild-FAV. Modal: 35% Row 4 NULL fence (axis absorbed, 8th cross-axis catalog finding) / 30% Row 5 NEG-at-B/D (linear_ramp_down still load-bearing) / 15% Row 3 productive-MARGINAL (C aggressive_to_gentle single-arm FAV) / 10% Row 2 PP-promote (one arm Δ ≤ −0.002) / 5% Row 1 strong-FAV / 5% surprise. **Cross-axis catalog 7 findings consolidated cycle 428** (now waiting for #1438 NS_ITERS_COOLDOWN + #1440 NS_COEF_SCHEDULE to complete the catalog to 9): 1. #1372 β-SCHEDULE NULL c420 / 2. #1393 MLP-LR NULL plateau 1.0-1.4 + Arm D mild-NEG (CLOSED c428) / 3. #1383 START_STEP non-monotone NEG / 4. #1421 UPDATE_PERIOD non-monotone PP / 5. #1402 β-AVG NULL / 6. #1388 EPS NULL / 7. #1438 NS_ITERS_COOLDOWN pending / **8. #1440 NS_COEF_SCHEDULE pending (just-assigned)**. **Unified mechanism story strengthens**: post-#1240 R-buffer EMA absorbs magnitude-of-precondition perturbations (β, EPS, LR-scale, MLP-LR-scale). #1440 tests whether absorption extends to UPSTREAM NS-coefficient-schedule axis (R-buffer's input quality). If yes, R-buffer absorbs both downstream and upstream perturbations → unified absorbing-buffer hypothesis confirmed. If no (Arm B constant NEG), refines story to "R-buffer absorbs DOWNSTREAM magnitude but is SENSITIVE to UPSTREAM input quality". **PP-promote queue cycle-428 (revised)**: 1. #1421 period=2 (sole remaining PP n=3) / 2. #1431 cooldown-refresh (just-assigned c425) / 3. #1438 NS_ITERS_COOLDOWN (just-assigned c427) / 4. #1426 frieren LR_SCALE (running c420) / 5. #1412 γ-mixing / 6. #1402 β / 7. **#1440 NS_COEF_SCHEDULE (just-assigned, 20% PP-edge)**. **Cross-chain implication for #1438 edward NS_ITERS_COOLDOWN**: STRENGTHENED prediction of +25 fs penalty pattern (universal across #1393 B/C/D) appearing in #1438 too even if val absorbs. Cross-chain implication for #1426 frieren LR_SCALE global: REINFORCED 65% Row 4 NULL fence prediction. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1402 fern D ~10-15% / #1409 alphonse A ~96% B/C/D pending / #1412 nezuko B ~5% / #1421 tanjiro A0 ~92% PP / #1426 frieren just-assigned c420 / #1431 askeladd just-assigned c425 / #1438 edward just-assigned c427 / **#1440 thorfinn NEW just-assigned c428**. ETA #1440 ~7h sequential. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 427 — 1 review #1388 edward NM EPS sweep CLOSED productive-NULL on advisor cycle-426 ctrl-drift-artifact reinterpretation + 1 stale_wip ack #1393 thorfinn NM MLP-LR with Arm C SURPRISE NULL-band + 1 new assignment #1438 edward NM NS_ITERS_COOLDOWN sweep 7th cross-axis catalog candidate. **#1388 CLOSED**: All 4 arms TERMINAL within ±0.001 of n=3 baseline 3.26339 across 5 orders of magnitude EPS (1e-2 → 1e-8). Verdict Row 4 productive-NULL on post-#1240 stack. EPS=1e-8 PP-promote cycle 418 candidate CANCELLED — ctrl drift artifact (Arm A +0.00267 on G4 PASS-OK edge) inflated within-chain paired Δ. **#1393 surprise**: Arm C LR_SCALE_MLP=1.4 TERMINAL val=3.26347 fs=3175 Δ_paired=+0.00052 NULL-band — cycle 419 modal forecast 45% mild-NEG, actual landed in 35% NULL-band band. MLP-LR axis NULL plateau extends 1.0-1.4 (NOT just at 1.2 as cycle 419 thought) with +25 fs penalty at boosted arms B/C. Arm D LR=1.6 running ~98% partial val=3.26893. **Updated cross-axis catalog finding #2**: #1393 MLP-LR NULL plateau extends across 40% range (not "NULL-with-fs-penalty axis collapse" at single arm). **🎯 PP-promote queue revision cycle-427**: #1388 EPS=1e-8 PP-promote CANCELLED (was queued cycle 418-426). Revised queue: 1. #1421 tanjiro period=2 (running 1/6 PP, sole remaining n=3 PP-promote candidate) / 2. #1431 askeladd cooldown-refresh (just-assigned c425, 25% PP-edge) / 3. ~~#1388 EPS=1e-8 CANCELLED~~ / 4. #1426 frieren LR_SCALE (running cycle 420) / 5. #1412 nezuko γ-mixing / 6. #1402 fern β-axis (5% modal eliminates) / 7. #1438 edward NS_ITERS_COOLDOWN (just-assigned, 25% PP-edge or NULL collapse). **🎯 #1438 edward ASSIGNED — NM NS_ITERS_COOLDOWN sweep 13th NM-aligned axis**: A ctrl=16 (production bump from base 12) / B=12 no-bump (falsifies cooldown bump load-bearing) / C=20 modest+ (retests PR #176 saturation on post-#1240) / D=24 aggressive+ (virgin territory). Mechanism: NS-iter cooldown bump is upstream of NM (modifies INPUT to R-buffer estimation during cooldown). Tests whether R-buffer EMA absorbs NS-coverage axis like it does MLP-LR (#1393), EPS (#1388), β (#1372/#1402). PR #176 pre-#1240 established NS=16 saturation point; this chain probes post-#1240 stack-dependence. Modal: 40% Row 4 NULL (axis absorbed like cross-axis catalog #1-6) / 25% Row 5 NEG-at-no-bump (#176 finding replicates, cooldown bump load-bearing) / 15% Row 3 productive-MARGINAL / 10% Row 2 PP-candidate / 5% Row 1 strong-FAV / 5% surprise. Cross-axis catalog update (7 findings consolidated): 1. #1372 β-SCHEDULE NULL c420 / 2. #1393 MLP-LR NULL plateau widened (revised c427) / 3. #1383 START_STEP non-monotone NEG c425 / 4. #1421 UPDATE_PERIOD non-monotone PP / 5. #1402 β-AVG NULL convergence / 6. #1388 EPS NULL c427 / 7. **#1438 (just-assigned) NS_ITERS_COOLDOWN — pending**. **Unified mechanism story strengthens further**: post-#1240 R-buffer EMA absorbs late-phase responsiveness perturbations across magnitude-of-precondition axes (β, EPS, LR-scale, MLP-LR-scale span). Coverage/timing/refresh-rate axes carry residual signal (#1383/#1421/#1431/#1438 testing this hypothesis). **Cross-chain implication for #1426 LR_SCALE**: REINFORCED modal updated 60% Row 4 NULL fence / 20% mild-FAV at 0.90 / 15% Row 4 monotone-NEG / 5% surprise. The MLP-LR axis NULL plateau finding here strengthens prediction that global LR_SCALE will fence similarly. **Cross-chain implication for #1431 cooldown-refresh**: ORTHOGONAL strengthen — magnitude axes (#1388/#1393/#1402) all converge on NULL, so timing-of-R-reset is the strongest remaining differentiation candidate. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1393 thorfinn Arm D ~98% ETA terminal ~5-10 min / #1402 fern D ~10% / #1409 alphonse A ~96% B/C/D pending / #1412 nezuko B ~3.7% / #1421 tanjiro A0 ~92% / #1426 frieren / #1431 askeladd / **#1438 edward NEW just-assigned**. ETA #1438 ~7h sequential. No new human GH issues (only existing #1261 directive).


- **Date:** 2026-05-27 (cycle 426 — 1 stale_wip ack on #1388 edward NM EPS sensitivity sweep. 🎯 **MAJOR REVISION TO CYCLE 418 FINDING — Arm D EPS=1e-2 TERMINAL `ki0a3tkk` val=3.26312 fs=3150 Δ_paired_val=−0.00294 STRONG-FAV by within-chain paired**. Contradicts cycle 418 40% strong-NEG modal — 5% surprise FAV modal hit. **Full 4-arm terminal**: A 1e-4 val=3.26606 fs=3175 drift +0.00267 / B 1e-6 val=3.26377 fs=3150 Δ_paired=−0.00229 / C 1e-8 val=3.26263 fs=3150 Δ_paired=−0.00343 / D 1e-2 val=3.26312 fs=3150 Δ_paired=−0.00294. **🎯 CTRL DRIFT ARTIFACT IDENTIFIED**: when measured against n=3 baseline 3.26339 (not within-chain paired Δ vs noisy Arm A), all 4 arms land within ±0.001 of baseline — Arm A is the noisy outlier (+0.00267 on G4 PASS-OK edge). EPS=1e-8 "STRONG-FAV" claim from cycle 418 was **CTRL DRIFT ARTIFACT, NOT REAL SIGNAL**. **🎯 Mechanism re-interpretation**: NM precondition magnitude NOT LOAD-BEARING on val/loss — R_cond_mean varies 5 orders of magnitude (4.4e4 to 1.1e9) and precond_ratio_mean 1.019-1.109 yet val spread only 0.003. R-buffer EMA self-corrects across full EPS regime, late-phase R-buffer state IS load-bearing, magnitude of inversion IS NOT. Consistent with #1372 β-NULL collapse, #1402 β-AVG convergence, #1393 MLP-LR NULL-with-fs-penalty. **🎯 PP-PROMOTE QUEUE REVISION**: #1388 EPS=1e-8 PP-promote CANCELLED. Revised queue: 1. #1421 period=2 (sole remaining PP n=3) / 2. #1431 askeladd cooldown-refresh (just-assigned c425, 25% PP-edge) / 3. ~~#1388 EPS=1e-8~~ CANCELLED / 4. #1426 frieren LR_SCALE (running) / 5. #1412 γ-mixing / 6. #1402 β. **🎯 Cross-axis stack-dependence catalog update (6 findings)**: 1. #1372 β-SCHEDULE NULL c420 / 2. #1393 MLP-LR NULL-with-fs-penalty / 3. #1383 START_STEP non-monotone NEG c425 / 4. #1421 UPDATE_PERIOD non-monotone PP / 5. #1402 β-AVG NULL convergence / 6. **#1388 EPS axis NULL on n=3 baseline (REVISED c426)**. Unified story: post-#1240 R-buffer load-bearing, magnitude-of-precondition axes (EPS, β, LR-scale) all collapse to NULL. **Cross-chain implication for #1431 askeladd cooldown-refresh**: REINFORCED — "R-buffer EMA load-bearing" finding from #1388 strengthens #1431's hypothesis that explicit R-reset TIMING matters more than EPS magnitude. **Cross-chain implication for #1426 LR_SCALE**: modal updated 50% NULL fence / 25% mild-FAV at 0.90 / 15% monotone-NEG / 10% surprise — more confident in NULL fence prediction. **Verdict**: pending student SENPAI-RESULT submission. Once submitted I CLOSE productive-NULL. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1388 (this) all 4 arms TERMINAL pending closure / #1393 thorfinn / #1402 fern Arm D ~10% / #1409 alphonse A ~96% B/C/D pending / #1412 nezuko B ~3.7% / #1421 tanjiro A0 ~92% / #1426 frieren just-assigned c420 / #1431 askeladd just-assigned c425. Exceptional NM telemetry diagnostic across 5 orders of magnitude EPS — publication-worthy null-result finding. No new human GH issues (only existing #1261 directive).

- **Date:** 2026-05-27 (cycle 425 — 1 review #1383 askeladd START_STEP sweep CLOSED productive-NEG non-monotone surprise + 1 new assignment #1431 askeladd NM R-buffer COOLDOWN-REFRESH 12th NM axis aligned with human directive #1261 H2. **#1383 CLOSED**: All 4 arms TERMINAL NEG. A ctrl always-on val=3.26533 fs=3175 PASS-MARGINAL G4 drift +0.00194 (EPS=1e-8 confound). B START=1500 Δ_paired=+0.00200 +0 fs / **C START=2000 Δ_paired=+0.00403 +25 fs WORST valley** / D START=2400 Δ_paired=+0.00298 +25 fs **better than C despite less coverage** = NON-MONOTONE Δ_B<Δ_D<Δ_C. **🎯 Mechanism finding**: valley at C ≈ NS_COOLDOWN_START_FRAC=0.7 step 2345. Arm B 845 pre-cooldown / Arm C 345 pre-cooldown / Arm D 0 pre-cooldown. Arm D's empty + fast-warmup R-buffer beats Arm C's partial + stale R-buffer in cooldown. **Hypothesis born from #1383 closure**: explicit R-buffer RESET at cooldown entry should outperform continuous EMA. Verdict productive-NEG axis FENCED at START_STEP=0 always-on. **Cross-axis catalog update (5 findings consolidated)**: 1. #1372 β-SCHEDULE NULL collapse / 2. #1393 MLP-LR NULL-with-fs-penalty / 3. **#1383 START_STEP NON-MONOTONE NEG valley at cooldown anchor** / 4. #1421 UPDATE_PERIOD NON-MONOTONE period=2 PP / 5. #1402 β-AVG NULL-FAV edge. **🎯 #1431 askeladd ASSIGNED — NM R-buffer COOLDOWN-REFRESH 4-arm chain**: A ctrl R_RESET=0 / **B cooldown-entry R_RESET=2345 (primary hypothesis from #1383 mechanism)** / C mid-training R_RESET=1675 (sanity for cooldown-anchor specificity) / D late-cooldown R_RESET=2900 (tests late-reset). Code change with bit-identity gate, single env var NANOGPT_NEWTON_MUON_R_RESET_STEP. Reset zeros R-buffer and discards R_inv_sqrt cache, EMA restarts from scratch. Modal: 35% Row 4 NULL fence / 20% Row 5 NEG cooldown-EMA stable / 15% Row 3 mild-FAV / 15% Row 2 PP-promote / 10% Row 1 strong-FAV / 5% surprise. **If Arm B mild-FAV, validates empty-R mechanism interpretation AND becomes 3rd PP-promote candidate joining #1421 period=2 and #1388 EPS=1e-8**. Cross-axis dependency: #1421 (refresh frequency period=2) and #1431 (refresh timing single reset) probe SAME mechanism (R-buffer staleness in cooldown) from different angles. 2-axis compound stack period=2 + R-reset@2345 natural follow-up if both PP-validate. **PP-promote queue cycle-425 (revised)**: 1. #1421 period=2 (running 1/6, ~92% A0) / 2. #1388 EPS=1e-8 (queued, pending D) / 3. #1431 R-reset (just-assigned, 25% PP-edge modal) / 4. #1426 LR_SCALE (just-assigned c420) / 5. #1412 γ-mixing (monitoring) / 6. #1402 β-axis (5% modal eliminates). **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1383 CLOSED / #1388 D ~5% / #1393 / #1402 D ~5-15% / #1409 alphonse A ~96% / #1412 nezuko B ~3.7% / #1421 tanjiro A0 ~92% / #1426 frieren / **#1431 askeladd NEW just-assigned**. ETA #1431 ~7h sequential. No new human GH issues (only existing #1261 directive).

- **Date:** 2026-05-27 (cycle 424 — 1 stale_wip ack on #1402 fern NM β EARLY constant sweep. **Chain status (3/4 arms TERMINAL, Arm D running ~5%)**: A ctrl β=0.95 `qjc5f6mx` val=3.26459 fs=3150 drift +0.00120 PASS-CLEAN G4 / **B faster β=0.90 `9okdxqri` val=3.26402 fs=3150 Δ_paired_val=−0.00057 +0 fs NULL-band mild-FAV val + fs-tied** / **C slower β=0.97 `l7krh4n9` val=3.26540 fs=3175 Δ_paired_val=+0.00081 +25 fs NULL-band mild-NEG + fs cost** / D much-slower β=0.99 `t3auv0wb` RUNNING step 175/3350 (~5%) ETA ~100 min. NM telemetry: precond_ratio_mean B=1.057 < A=1.090 ≈ C=1.094 confirms β-mechanism; R_cond_mean A=134K << B=5.07M >> C=1.02M (Arm B 38× higher R_cond_mean because β=0.90 faster EMA decay produces less-stable R-buffer, but condition number does NOT translate to val degradation — paired Δ mildly FAV). **🎯 Mechanism finding β-monotone trend confirmed (3-arm partial)**: β↓ NULL-FAV / β= clean / β↑ NULL-NEG with fs cost — ASYMMETRIC slow-side hurts more than fast-side helps. **🎯 CROSS-CHAIN CONVERGENCE with #1372 β-SCHEDULE step-down (CLOSED productive-NULL c420)**: #1372 step-down β=0.95→0.85@2000 (late-phase β-AVG ≈ 0.92) full-chain Δ_paired=+0.00099 NULL fs-tied / #1402 constant β=0.90 (β-AVG=0.90) Δ_paired_val=−0.00057 NULL fs-tied — **schedule shape doesn't matter — late-phase β AVERAGE matters**. Cycle 417 hypothesis "AVERAGE β not schedule transition" VINDICATED by 2-chain triangulation. **5th cross-axis finding** in r4 launch joining #1372 NULL collapse / #1393 NULL-with-fs-penalty / #1383 monotone-NEG / #1421 NON-MONOTONE PP-promote / **#1402-#1372 β-AVERAGE convergence**. **Virgin extension β=0.85 constant**: extrapolation predicts Δ_paired_val ~ −0.001 to −0.002 (PP-edge), NOT in chain; 10-15% chance of PP-promote signal at single-seed if tested. Not high-priority follow-up given #1372 schedule transition already at β-AVG ≈ 0.92 NULL. **Modal Arm D (β=0.99)**: 55% mid-NEG-to-NEG dispositive monotone-NEG slow-side fence / 25% mild-NEG / 10% strong-NEG / 5% NULL surprise / 5% other. **Modal full-chain**: 50% Row 4 productive-MONOTONE optimum near β=0.90 NULL-FAV edge slow-side dispositive / 25% Row 5 productive-NULL wide shoulder / 15% Row 4 monotone-NEG deeper / 5% Row 3 PP-promote candidate / 5% surprise. **Cross-chain implication for #1426 frieren LR_SCALE global**: post-#1240 stack has WIDE NULL-band shoulders along ALL magnitude axes (β/MLP-LR/β-schedule). LR_SCALE expected modal: 40% Row 4 NULL fence / 25% Row 3 mild-FAV at 0.90 PP-candidate (slope toward damping ≈ slope toward faster β). Reinforces cycle 420 LR_SCALE prediction. **Cross-chain implication for #1421 period=2 PP**: β=0.90 modestly favorable with period=5 → period=2 + β=0.90 stack might compound (future 2-axis stack queue candidate if both standalone PP-validate). **PP-promote queue cycle-424 (unchanged)**: 1. #1421 period=2 (~92% A0) / 2. #1388 EPS=1e-8 (pending D) / 3. #1426 LR_SCALE / 4. #1412 γ-mixing / 5. #1402 (this) 5% modal eliminates. **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1383 Arm D ~66% / #1388 D ~5% / #1393 thorfinn / #1402 (this) 3/4 TERMINAL D ~5% / #1409 alphonse A ~96% / #1412 nezuko B ~3.7% / #1421 tanjiro A0 ~92% / #1426 frieren just-assigned. ETA #1402 Arm D terminal ~100 min. No new human GH issues (only existing #1261).

- **Date:** 2026-05-27 (cycle 423 — 1 stale_wip ack on #1409 alphonse NM module coverage ablation. **Bit-identity gate verified ✓** (cycle 410 student gate verification: pair-1 A_new vs A_baseline Δ_paired=+0.00248 step-300, MUON_PARAM_COUNTS attn=48 mlp=24 = 72 modules; pair-2 NM=0-via-flags = NM=0 path confirmed). **Chain status (Arm A ctrl ~96%, B/C/D pending sequential)**: A ctrl full `h5jiqg88` RUNNING step 3225/3350 (~96%) partial val=3.27250 fs=pending NM telemetry R_cond_mean=5.06M precond_ratio_mean=1.124 (typical post-#1240 with 12 mlp.proj d_in=3072 high-R_cond matrices), EPS=1e-4 ✓ correct stack. B/C/D not yet started. ETA Arm A0 terminal ~5-10 min then sequential B/C/D ~6h remaining. **🎯 Mechanism context — 11th NM axis structural coverage location**: joins #1363 DIAG R-SHAPE / #1360 R-POWER α / #1412 γ-MIXING. Triangulation: if MODULE-COVERAGE + γ-MIXING both fence at canonical values, NM internal mechanism dispositively characterized. **Modal Arm B (MLP-only, 24 modules)**: 35% mid-NEG ATTN dominates / 25% NULL-mild-NEG MLP coverage substitutable / 20% mild-FAV mlp.proj high-R_cond load-bearing / 15% strong-NEG / 5% surprise. **Modal Arm C (ATTN-only, 48 modules)**: 45% NULL-mild-NEG ATTN dominates / 25% mild-FAV substitutable / 15% mild-NEG mlp.proj also contributes / 10% mid-NEG / 5% surprise. **Modal Arm D (NM-off via flags, 0 modules)**: 90% pre-#1240 territory +0.005-0.015 sanity / 8% hook-leftover divergence / 2% surprise. **Modal full-chain outcome**: 45% Row 4 ATTN dominates / 25% Row 3 substitutable (REDUCTION finding) / 15% Row 5 MLP.proj dominates despite 4× fewer / 10% Row 4 deeper NEG / 5% Row 1/2 surprise. **Cross-chain implication for #1426 frieren LR_SCALE global**: ATTN-dominance (45%) → focus on ATTN per-group scaling (subsumed by global); MLP-dominance (15%) → decoupled per-group preferred. Either way provides directional Bayesian update for LR_SCALE prediction. **PP-promote queue cycle-423 (unchanged)**: 1. #1421 period=2 / 2. #1388 EPS=1e-8 / 3. #1426 LR_SCALE / 4. #1412 γ-mixing / 5. #1409 (45% modal eliminates from queue). **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1383 Arm D ~66% / #1388 Arm D EPS=1e-2 ~5% / #1393 thorfinn / #1402 fern / #1409 (this) Arm A ~96% / #1412 nezuko Arm B ~3.7% / #1421 tanjiro A0 ~92% / #1426 frieren just-assigned. ETA Arm A terminal ~5-10 min. No new human GH issues (only existing #1261 directive).

- **Date:** 2026-05-27 (cycle 422 — 1 stale_wip ack on #1383 askeladd NM START_STEP sweep. **Chain status 3/4 arms TERMINAL, Arm D running ~66%**: A always-on `19vdad68` val=3.26533 fs=3175 (EPS=1e-8 confound — paired-only valid) / **B START=1500 `dznqnq8e` val=3.26733 fs=3175 Δ_paired_val=+0.00200 +0 fs mild-NEG val fs-tied (just outside NULL-band)** / **C START=2000 `e8dmz0fm` val=3.26936 fs=3200 Δ_paired_val=+0.00403 +25 fs MID-NEG val + fs cost** / D START=2400 `c6w43lk5` RUNNING step 2200/3350 (~66%) partial val=3.41693 (pre-cooldown). 🎯 **Monotone-NEG by START_STEP↑ signature confirmed at 3-arm level**: ratio +0.00200 → +0.00403 = 2.0× val acceleration with +25 fs penalty emerging at START=2000. **Mechanism**: delayed NM activation eliminates R-buffer warmup AND early-phase NM-precondition benefit. Last ~1350 steps insufficient to recover val deficit. **Modal Arm D terminal**: 50% strong-NEG Δ ≥ +0.006 +25-50 fs / 30% mid-NEG / 15% mild-NEG / 5% surprise. **Closure decision tree pending Arm D**: 65% Row 4 monotone-NEG dispositive START_STEP=0 always-on confirmed locally optimal / 30% plateau at B-C / 5% Row 5 surprise NULL late-only. **🎯 Cross-axis catalog update (4 findings)**: 1. #1372 β-SCHEDULE step-down CLOSED productive-NULL fully-fenced c420; 2. #1393 MLP-LR-SCALE NULL-with-fs-penalty axis collapse; 3. #1383 (this) START_STEP monotone-NEG temporal-gate; 4. #1421 UPDATE_PERIOD NON-MONOTONE period=2 PP. **Unified story**: post-#1240 PERIOD=5 + MAX_D_IN=4096 R-buffer load-bearing. Temporal axes (START_STEP, β-schedule) require CONTINUOUS preconditioning; magnitude axes (#1393 MLP-LR, #1426 LR_SCALE, #1412 γ-mixing) test perturbations OF precondition; period axis only one with non-monotone FAV potential. **Cross-chain implication for #1421 period=2 PP**: if #1383 fences temporal-axis dispositively at START_STEP=0, period=2 PP reinforced as SINGLE-AXIS perturbation worth promoting; refresh-frequency and temporal axes independent levers but only refresh-frequency has FAV potential. **PP-promote queue cycle-422 (unchanged)**: 1. #1421 tanjiro period=2 (1/6) / 2. #1388 EPS=1e-8 (queued) / 3. #1426 frieren LR_SCALE (just-assigned) / 4. #1412 nezuko γ-mixing (monitoring). **Cross-chain status (8 chains, 0 idle, 0 review-ready)**: #1383 (this) Arm D ~66% / #1388 edward Arm D EPS=1e-2 ~5% / #1393 thorfinn Arm C ~97% / #1402 fern Arm B ~98% / #1409 alphonse / #1412 nezuko Arm A TERMINAL B ~3.7% / #1421 tanjiro A0 ~92% / #1426 frieren LR_SCALE just-assigned. ETA Arm D terminal ~30-50 min. No new human GH issues (only existing #1261).

- **Date:** 2026-05-27 (cycle 421 — 2 stale_wip acks on #1421 tanjiro period=2 PP-promote and #1412 nezuko γ-mixing. **#1421 status**: Arm A ctrl seed=0 period=5 `jbe14pft` RUNNING step 3075/3350 (~92%) partial val=3.28541 fs=-1 not-yet-crossed (cooldown expected to cross step 3150-3175). NM telemetry: R_cond_mean=525K precond_ratio_mean=1.0976 typical post-#1240 ctrl signature. EPS=1e-4 ✓ no cross-chain confound. Single ctrl seed=0 in flight after 3.75h since assignment cycle 415 — pace ~2.5h/run sequential. Run 1 of 6 interleaved (A0→B0→A1→B1→A2→B2). On-track 12.5h total. ETA Arm A0 terminal ~15-25 min. **#1412 status**: **Arm A ctrl γ=1.0 `k4mfvlpb` TERMINAL val=3.26496 fs=3175 drift +0.00157 PASS-OK G4 (noisy side of EXCEPTIONALLY-CLEAN band) +25 paired fs**. NM telemetry: R_cond_mean=3.85M precond_ratio_mean=1.1184 typical post-#1240 stack with 12 mlp.proj d_in=3072 matrices. EPS=1e-4 ✓ no confound. Bit-identity gate ✓ verified cycle 411. Arm B weak-mix γ=0.5 `ih7wtufu` RUNNING step 125/3350 (~3.7%). 4-arm chain ~5h remaining for B/C/D sequential. **🎯 γ-axis context**: 4th magnitude-axis NM mechanism test in r4 — joins #1360 R-POWER α (CLOSED bilateral fence at α=0.5), #1363 DIAG (CLOSED off-diag load-bearing), #1409 alphonse MODULE-COVERAGE in flight. γ-MIXING is MAGNITUDE of NM transform itself outside the inverse-sqrt. If Row 4 bilateral fence at γ=1.0 mirrors #1360, 4-axis dispositive characterization complete. **Modal Arm B (γ=0.5)**: 35% mid-NEG / 25% mild-NEG / 20% NULL / 15% mid-NEG-to-NEG / 5% surprise FAV. **Modal Arm C (γ=0.75)**: 35% mild-NEG / 30% NULL / 20% mild-FAV / 10% mid-NEG / 5% surprise. **Modal Arm D (γ=1.25 over-extrapolation)**: 45% mid-NEG-to-NEG anti-monotone vs Arm B / 25% NULL / 15% strong-NEG dispositive / 10% mild-FAV / 5% surprise. **Modal full-chain**: 50% Row 4 bilateral fence at γ=1.0 dispositive (mirrors #1360 α=0.5) / 20% Row 5 asymmetric (B NEG D NULL/FAV or vice versa) / 15% Row 3 productive-NULL γ-shoulder wide / 10% Row 2 PP-promote / 5% Row 1 STRONG-FAV surprise. **🎯 Cross-chain implication for #1426 frieren LR_SCALE global sweep (just-assigned cycle 420)**: γ-mixing modulates PRECONDITIONER STRENGTH, LR_SCALE modulates EFFECTIVE LR post-precondition — MULTIPLICATIVELY COUPLED through NM update equation. If γ-axis bilateral-fences at γ=1.0 (50% modal), LR_SCALE bilateral fence at 1.0 confidence INCREASES; if γ<1 FAV (5%), LR_SCALE below-1.0 virgin direction prediction strengthens significantly. **PP-promote queue priority cycle-421**: 1. #1421 tanjiro period=2 (running 1/6, sequential) | 2. #1388 edward EPS=1e-8 (queued, pending Arm D EPS=1e-2) | 3. #1426 frieren LR_SCALE (just-assigned, contingent on B/C) | 4. #1412 nezuko γ-mixing (monitoring, 50% modal NULL/fence eliminates from queue, 10% modal puts it on). **Cross-chain GPU utilization status (8 chains active, 0 idle, 0 review-ready)**: #1372 CLOSED productive-NULL c420 / #1383 askeladd Arm C ~62% / #1388 edward Arm D EPS=1e-2 ~5% / #1393 thorfinn Arm C ~97% / #1402 fern Arm B ~98% / #1409 alphonse module coverage / #1412 nezuko Arm A TERMINAL Arm B ~3.7% / #1421 tanjiro Arm A0 ~92% / #1426 frieren LR_SCALE just-assigned. No new human GH issues (only existing #1261 directive).

## Cycle 420 — 2026-05-27 11:55 UTC

🎯 **#1372 frieren CLOSED productive-NULL, #1426 NM global LR_SCALE virgin axis assigned (12th NM axis).** β-schedule axis FULLY FENCED on post-#1240 stack — Arm D depth-only TERMINAL Δ_paired=+0.00099 +0 fs NULL-band fs-tied. All 3 treatment arms (B compound +0.00065 / C timing-only +0.00108 / D depth-only +0.00099) land NULL-band fs-tied with ctrl drift +0.00005 EXCEPTIONALLY-CLEAN G4 PASS. Hits cycle 414 modal Arm D 65% Row 4 productive-NULL pre-stage cleanly.

🎯 **Cross-stack stack-dependence finding consolidated (β-schedule axis)**:
| Variant | Pre-#1240 stack (#1331) | Post-#1240 stack (this) | Δ shift |
|---|:---:|:---:|:---:|
| β=0.90 @ 2000 timing | Δ=−0.00202 MARGINAL-FAV | Δ=+0.00108 NULL | +0.00310 collapsed |
| β=0.85 @ 2345 depth | Δ=−0.00142 MARGINAL-FAV | Δ=+0.00099 NULL | +0.00241 collapsed |
| β=0.85 @ 2000 compound | not tested | Δ=+0.00065 NULL | n/a NULL |

**Mechanism (consolidated)**: Post-#1240 `UPDATE_PERIOD=5` (vs pre-#1240 `=10`) provides 2× more responsive R-buffer refresh, **fully absorbing** the late-phase responsiveness benefit that explicit β step-down recovered on pre-#1240. β-schedule and period axes are NOT independent — coupled through late-phase preconditioner responsiveness mechanism. Eleventh NM axis characterized productive-NULL on post-#1240 stack. Joins period=3 over-refresh CLEAR-NEG, R-power α=0.333 CLEAR-NEG, DIAG-ONLY CLEAR-NEG.

🎯 **Cross-axis stack-dependence catalog now 4 findings**: (1) #1372 β-SCHEDULE pre→post NULL collapse dispositive; (2) #1393 MLP-LR-SCALE NULL-with-fs-penalty; (3) #1383 START_STEP gate mild-NEG fs-tied; (4) #1421 UPDATE_PERIOD axis NON-MONOTONE period=2 single-seed FAV Δ=−0.00223 PP-promote candidate. Unified mechanism story converging: responsive R-buffer (period=5/MAX_D_IN=4096) absorbs late-phase optimizer responsiveness; PERIOD axis itself non-monotone — even more responsive (period=2) extracts FURTHER mechanism.

**NM telemetry mechanism note**: Arm C (β=0.90 timing-only) showed 13.6% higher `precond_ratio_mean` (1.2441 vs ctrl 1.0951) yet landed NULL on val — only arm with preconditioner-ratio divergence. Useful diagnostic for future axis-survival monitoring. Arm B/D R_inv_sqrt_norm_mean 2-2.6× ctrl, but larger R-buffer magnitudes do NOT correlate with favorable val — confirms refresh frequency (period) is load-bearing, not R-buffer magnitude.

**🎯 #1426 frieren NEW ASSIGNMENT: NEWTON_MUON_LR_SCALE global sweep** — virgin axis on post-#1240 stack (12th NM axis test). 4 arms {0.80, 0.90, 1.0 ctrl, 1.10}. Single env var, no code changes. Production has implicitly run NM with LR_SCALE=1.0 since #1240 merged; default never confirmed locally optimal. Mechanism question: "Does NM preconditioning need a global LR re-tune?" Cross-axis prediction: above-1.0 likely NEG (matches #1393 per-group MLP=1.2 NULL-with-fs-penalty), below-1.0 is virgin direction.

**Modal full-chain forecast**:
- 40% Row 4 productive-NULL all 3 treatment arms NULL-band → axis fenced (12th axis)
- 25% Row 3 mild-FAV at 0.90 → PP-promote MARGINAL band
- 20% Row 4 dispositive monotone-NEG → production 1.0 is local optimum (any direction hurts)
- 10% Row 5 NULL-with-fs-penalty mirroring #1393
- 5% Row 1 surprise strong-FAV at 0.80 → aggressive damping reveals NM over-amplification

EPS=1e-4 default (NOT 1e-8) — chain remains bit-comparable with new baseline 3.26339.

**Cross-chain status cycle-420 (8 chains active, 0 idle, 0 review-ready)**:
- #1383 askeladd START_STEP Arm C running (EPS=1e-8 within-chain valid)
- #1388 edward EPS sensitivity Arm D 1e-2 running
- #1393 thorfinn MLP-LR sweep Arm C ~97% near-terminal, Arm D pending
- #1402 fern β EARLY constant Arm B ~98% near-terminal
- #1409 alphonse NM module coverage running
- #1412 nezuko NM γ-mixing running
- #1421 tanjiro UPDATE_PERIOD=2 PP-promote n=3 running (priority PP)
- **#1426 frieren NM global LR_SCALE sweep just-assigned** (this)

**PP-promote queue priority**:
1. #1421 period=2 (n=3 paired-pod running)
2. #1388 EPS=1e-8 (queued — pending #1388 Arm D dispositive completion)
3. Future: if #1426 Arm B/C Δ ≤ −0.002 FAV, becomes 3rd PP-promote queue priority

ETA #1426 chain completion: ~8h sequential. ETA next decision point: ~1-2h for #1393 Arm C terminal, #1402 Arm B terminal, #1388 Arm D ~107 min, then #1421 PP-promote Arm s0-C ~107 min from now.

No new human GH issues.

---

- **Date:** 2026-05-27 (cycle 419 — 1 stale_wip ack on #1393 thorfinn NM MLP-LR fine sweep. **🎯 Arm B LR_SCALE_MLP=1.2 TERMINAL val=3.26361 fs=3175 Δ_paired_val=+0.00066 +25 fs NULL-band-with-fs-penalty** (val=NULL, fs=mild-NEG) + Arm C LR_SCALE_MLP=1.4 RUNNING step 3250/3350 (~97%) partial val=3.27013 fs=3175 already crossed step 3175 — terminal in ~5-10 min). **#1393 chain status** (group `g1r4-thorfinn/nm-mlp-lr-sweep`): A ctrl LR=1.0 `0jn8dcap` TERMINAL val=3.26295 fs=3150 drift −0.00044 EXCEPTIONALLY-CLEAN-FAV (4th clean-FAV ctrl, EPS=1e-4 ✓ correct production replication) / **B LR=1.2 `xbhuh24l` TERMINAL val=3.26361 fs=3175 Δ_paired_val=+0.00066 +25 fs (val NULL fs +25 paired penalty)** / **C LR=1.4 `d8k7tdi0` RUNNING ~97% partial 3.27013 fs=3175** / D LR=1.6 pending. **Arm B finding**: NULL-band on val (+0.00066 within [−0.0005, +0.002]) + 25 fs paired penalty — axis-collapse with fs-cost signature. **Mechanism**: post-#1240 stack already extracts MLP-LR responsiveness via period=5 + MAX_D_IN=4096 R-buffer responsiveness; additional NM-specific LR boost (1.2× on top of production `NANOGPT_MUON_MLP_LR_MULT=1.2`) creates marginal over-stretch on 12 high-R_cond mlp.proj matrices — enough to delay one validation interval (+25 fs) but not enough to push val above NULL boundary. **Distinction from pre-#1240 #1346 Arm B Δ=−0.00114 MARGINAL-FAV**: pre-#1240 stack used period=10, axis had headroom; post-#1240 stack absorbs the axis. **Arm C modal** (100 steps remaining, slope ~−0.003/25 steps decelerating): 35% NULL Δ ∈ [−0.001, +0.001] / 30% mild-NEG / 20% mild-FAV / 10% mid-NEG / 5% surprise. **Arm D modal** LR=1.6: 45% mid-NEG / 25% mild-NEG / 15% similar-to-C / 10% strong-NEG / 5% surprise. **🎯 Cross-axis stack-dependence catalog (3 findings in r4 launch)**: (1) #1372 β-SCHEDULE step-down pre→post NULL collapse (cycle 414 dispositive); (2) #1393 (this) MLP-LR-scale pre→post NULL-with-fs-penalty (cycle 419 confirming axis collapse with +25 fs cost); (3) #1383 START_STEP Arm B mild-NEG fs-tied (different mechanism, temporal gate). **Mechanism story converging**: responsive R-buffer (period=5 / MAX_D_IN=4096) absorbs late-phase optimizer responsiveness that pre-#1240 required explicit LR/β scaling. Both LR-scale and β-schedule become redundant on new stack. **Cross-chain implications for #1421 period=2 PP**: if period=2 PP-validates, deeper R-buffer responsiveness may absorb axis effects even further (LR-MLP axis deeper to NULL, EPS=1e-8 FAV might attenuate or invert) — strictly hypothetical. **Modal full-chain outcome**: 45% Row 4 monotone-NEG axis saturation / 25% Row 5 NULL-with-fs-penalty / 15% Row 4 monotone-NEG dispositive / 10% Row 3 productive-MARGINAL / 5% Row 1/2 surprise. **Cross-chain status cycle-419 (8 chains, 0 idle, 0 review-ready)**: #1372 Arm D ETA 30-60 min / #1383 Arm C ~62% / #1388 edward EPS A/B/C TERMINAL Row 1 STRONG-FAV at C / Arm D ~5% / **#1393 (this) Arm A/B TERMINAL / Arm C ~97% / Arm D pending** / #1402 fern β EARLY Arm A clean / Arm B near-terminal / #1409 alphonse / #1412 nezuko / **#1421 tanjiro period=2 PP-promote**. No new human GH issues.
- **Date:** 2026-05-27 (cycle 418 — 1 stale_wip ack on #1388 edward NM EPS sensitivity sweep. **🎯 MAJOR FINDING: monotone-FAV with EPS↓**, **Arm C EPS=1e-8 single-seed Δ_paired_val=−0.00343 −25 fs STRONG-FAV Row 1 territory val=3.26263 ≤ baseline 3.26339**, **Arm B EPS=1e-6 Δ=−0.00229 −25 fs MARGINAL-FAV**. Arm D EPS=1e-2 just-launched step 25/3350 (~0.7%) ETA ~107 min. **#1388 chain status** (group `g1r4-edward/nm-eps-sweep`): A ctrl EPS=1e-4 `0v9rzbbc` TERMINAL val=3.26606 fs=3175 drift +0.00267 +25 fs (noisy ctrl) / **B EPS=1e-6 `skhqe63r` TERMINAL val=3.26377 fs=3150 Δ_paired=−0.00229 −25 fs MARGINAL-FAV** / **C EPS=1e-8 `56nkipuf` TERMINAL val=3.26263 fs=3150 Δ_paired=−0.00343 −25 fs STRONG-FAV Row 1** / D EPS=1e-2 `ki0a3tkk` RUNNING ~0.7%. **NM telemetry shows mechanism**: R_inv_sqrt_norm 81.5→111.9 (+37% at 1e-6), R_cond_max 14.1M→3.45G (245× at 1e-6), precond_ratio +3pp — tighter EPS faithfully inverts tiny eigenvalues on 12 post-#1240 mlp.proj matrices (R_cond up to 10⁹), less regularization → more aggressive per-direction scaling. **⚠️ CROSS-CHAIN EPS CONFOUND DISCOVERY**: audit of 6 recent chain ctrls reveals #1372 frieren and #1383 askeladd ctrls inadvertently used EPS=1e-8 (favorable direction) instead of script default 1e-4. Within-chain Δ_paired comparisons remain VALID (paired comparison cancels confound) but absolute val of #1372 Arm A drift +0.00005 and #1383 Arm A drift +0.00194 are confounded ~−0.003 FAV by EPS axis. #1356/#1393/#1402/#1388 ctrls all correctly use EPS=1e-4. **β-schedule NULL collapse and START_STEP mild-NEG findings remain valid as MECHANISM characterization within chain; cannot claim ABSOLUTE val replication of #1240 baseline for those two chains**. All future post-#1240 chains should verify EPS=1e-4 in reproduce env. **PP-promote priority sequencing**: #1421 tanjiro period=2 PP-promote already running (assigned cycle 415, ~12.5h sequential ETA). If #1388 Arm D confirms inverse-U axis fence (modal 40% strong-NEG / 25% mid-NEG / 20% divergence / 10% mild-NEG / 5% NULL), **EPS=1e-8 becomes 2nd PP-promote queue priority** for next idle student. Period and EPS axes are INDEPENDENT — modal stacking benefit if both PP-validate. Future aggressive PP-stack: `period=2 ∧ EPS=1e-8` 2-axis stack confirmation. **Modal full-chain**: 50% Row 1 monotone-FAV-by-EPS↓ dispositively fenced EPS=1e-8 PP-candidate / 25% Row 1 with surprise / 15% Row 2 PP-promote Arm B sweet spot / 5% Row 5 noise / 5% surprise. **Cross-chain status cycle-418 (8 chains, 0 idle, 0 review-ready)**: #1372 Arm D depth-only ETA 30-60 min (EPS confound noted) / #1383 Arm C ~62% (EPS confound noted) / **#1388 (this) A/B/C TERMINAL, Arm D ~0.7%** / #1393 thorfinn Arm B ~95% / #1402 fern Arm A clean / Arm B likely terminal by now / #1409 alphonse module coverage / #1412 nezuko γ-mixing / **#1421 tanjiro period=2 PP-promote n=3**. Today's strongest single-seed FAV signal (Δ=−0.00343 val ≤ baseline). No new human GH issues.
- **Date:** 2026-05-27 (cycle 417 — 1 stale_wip ack on #1402 fern NM β EARLY constant sweep. **Arm A ctrl β=0.95 `qjc5f6mx` TERMINAL val=3.26459 fs=3150 drift +0.00120 PASS-CLEAN G4** + **Arm B β=0.90 `9okdxqri` RUNNING ~98% step 3275/3350 partial val=3.26771 fs=3150 (target crossed step 3150 = same as Arm A, paired-fs=0)** — terminal in ~5-8 min). **#1402 chain status** (group `g1r4-fern/nm-beta-early-sweep`): A `qjc5f6mx` TERMINAL drift +0.00120 (5th clean-FAV ctrl in today's cohort, cleaner half) / **B `9okdxqri` RUNNING ~98% partial val=3.26771 trajectory implies modal terminal ∈ [3.260, 3.265]** / C β=0.97 / D β=0.99 NOT-LAUNCHED. **Cooldown completion slope ~−0.002 per 25 steps decelerating, 75 steps remaining**. **Modal Arm B terminal**: 30% mild-FAV/NULL Δ ∈ [−0.0025, +0.0005] / 30% NULL-band [−0.0005, +0.0025] / 25% mild-FAV [−0.005, −0.0015] / 10% mild-NEG / 5% strong-FAV PP-candidate. **🎯 Critical mechanism question**: β=0.90 EARLY constant might OUTPERFORM β=0.95 because (1) post-#1240 period=5 stack uses 2× more responsive R-buffer, faster EMA decay β=0.90 gives 50-step EMA window (vs 100-step at β=0.95) better matched to fast cooldown eigenstructure rotation; (2) MAX_D_IN=4096 added 12 high-R_cond mlp.proj matrices benefiting from faster R turnover. **Cross-chain implication**: if Arm B mild-FAV, CONTRADICTS #1372 β-SCHEDULE NULL-collapse finding — what matters could be AVERAGE β during late-phase NOT schedule transition itself. Distinguishes schedule-shape from constant-β mechanism. **Modal Arms C/D**: Arm C β=0.97 40% mild-NEG / Arm D β=0.99 55% mid-NEG-to-NEG (asymmetric — much-slower hurts more than faster helps). **Modal full-chain outcome**: 35% Row 3 productive-MARGINAL Arm B mild-FAV / 25% Row 4 monotone-by-β with sweet-spot LOWER than 0.95 / 20% Row 5 productive-NULL β-axis fully fenced / 10% Row 2 PP-promote (Arm B Δ ≤ −0.0025) / 10% Row 4 monotone-NEG ceiling. **Cross-chain status cycle-417 (8 chains, 0 idle, 0 review-ready)**: #1372 frieren Arm D mid-chain (now 80%+) / #1383 askeladd Arm C ~62% / #1388 edward EPS Arm A near-terminal / #1393 thorfinn MLP-LR Arm B ~95% / **#1402 (this) Arm A clean / Arm B ~98%** / #1409 alphonse module coverage / #1412 nezuko γ-mixing / **#1421 tanjiro period=2 PP-promote n=3**. ETA Arm B terminal ~5-8 min. No new human GH issues.
- **Date:** 2026-05-27 (cycle 416 — 1 stale_wip ack on #1383 askeladd NM START_STEP gate sweep. **🎯 Arm B START=1500 TERMINAL Δ_paired_val=+0.00200 +0 fs MILD-NEG fs-tied** confirms cycle 408 modal "30% mild-NEG band" cleanly hits). **#1383 chain status** (group `g1r4-askeladd/nm-start-step-sweep`): A always-on ctrl `19vdad68` TERMINAL val=3.26533 fs=3175 drift +0.00194 +25 fs (G4 outer envelope) / **B late-start START=1500 `dznqnq8e` TERMINAL val=3.26733 fs=3175 Δ_paired_val=+0.00200 +0 fs MILD-NEG fs-tied** / C cooldown-warmup START=2000 `e8dmz0fm` RUNNING step 2075/3350 (~62%) / D cooldown-only START=2400 NOT-LAUNCHED next sequential. **Arm B decomposition**: val penalty +0.00200 above NULL (+0.0015) below dispositive-NEG (+0.003), fs-tied means deficit is POST-target-crossing in cooldown tail. **Mechanism**: skipping first 1500 steps deprives R-buffer of warm-up samples for late-phase preconditioner quality, but partial pickup from step 1500 captures ~80% benefit (coverage-essential mild flavor). **Modal Arm C forecast given Arm B**: 40% mild-NEG monotone Δ_C ∈ [+0.0015, +0.004] / 25% mild-NEG-similar / 20% mid-NEG / 10% NULL / 5% surprise-FAV. **Modal Arm D forecast**: 45% mid-NEG Δ_D ∈ [+0.003, +0.006] / 25% strong-NEG / 20% mild-NEG saturation / 10% NULL. **Modal full-chain**: 45% Row 4 coverage-essential monotone-NEG (dispositive) / 20% Row 5 saturation / 15% Row 3 late-only mild-NEG-saturation / 15% Row 5 non-monotone / 5% Row 1/2 surprise. **Cross-axis indicator**: #1383 Arm B mild-NEG fs-tied joins #1393 Arm B (MLP-LR +25 fs paired likely NULL/mild-NEG) as second cross-axis evidence that post-#1240 stack TIMING axes have small-but-real mild-NEG signals; distinct from β-schedule which fully collapses NULL (#1372). **Cross-chain status cycle-416 (8 chains, 0 idle, 0 review-ready)**: #1372 frieren Arm D depth-only mid-chain ~50%+ terminal in ~30-45 min / **#1383 (this) Arm A TERMINAL / Arm B TERMINAL mild-NEG / Arm C ~62% / Arm D pending** / #1388 edward EPS Arm A near-terminal / #1393 thorfinn MLP-LR Arm B ~95% (likely near-terminal) / #1402 fern β EARLY Arm A ~93% / #1409 alphonse NM module coverage / #1412 nezuko NM γ-mixing / **#1421 tanjiro period=2 PP-promote n=3 just-assigned (cycle 415)**. ETA #1383 Arm C terminal ~45-50 min, Arm D sequential ~2h. No new human GH issues (r4-relevant); #1259/#1260 are r2/r3 branches not r4.
- **Date:** 2026-05-27 (cycle 415 — #1356 tanjiro NM period sweep CLOSED productive-MARGINAL, **🎯 FIRST PP-PROMOTE CANDIDATE in r4 launch**: #1421 tanjiro nm-period2-pp-promote n=3 paired-pod validation for `UPDATE_PERIOD=2` assigned). **#1356 full chain** (group `g1r4-tanjiro/nm-period-sweep-new-stack`): A ctrl period=5 `m2i9s3k4` val=3.26276 fs=3150 drift −0.00063 EXCEPTIONALLY-CLEAN / B period=3 `792x4704` val=3.26613 fs=3175 Δ=+0.00337 +25 fs CLEAR-NEG / **C period=2 `4uo4hl9w` val=3.26053 fs=3125 Δ_paired=−0.00223 −25 fs FAVORABLE PP-promote MARGINAL** / D period=10 `zzton5yp` val=3.26484 fs=3175 Δ=+0.00208 +25 fs NEG. Student SENPAI-RESULT terminal=true, pending_arms=false, primary_metric fs=3125, test_metric val=3.26053. **Three dispositive findings in #1356**: (1) Period axis is NON-MONOTONE on post-#1240 stack — period=3 WORST, period=2 FAV, period=5 ctrl, period=10 NEG. Contradicts cycle 406 modal "55% NEG-monotone" prediction (5% pre-staged surprise probability landed). (2) Period=5 ≠ R-buffer refresh optimum — post-#1240 stack has a second favorable basin at period=2 previously unsampled; prior #1240 period 10→5 comparison confounded with MAX_D_IN coverage extension (disambiguated by this chain at fixed MAX_D_IN=4096). (3) Period=3 lies in a noisy middle zone between two EMA-window regimes — period=3 (60-step EMA window) samples insufficient to settle EMA, period=2 (40-step window) re-stabilises at very-fast refresh with full-R eigenstructure tracking cooldown rotation. Mechanism hypothesis: 12 high-R_cond mlp.proj matrices (d_in=3072, R_cond~10⁶) added by #1240 benefit from faster R refresh; period=2 better resolves their dominant eigenstructure rotation during cooldown. **PP-promote #1421 design**: 6 interleaved sequential runs (3 ctrl period=5 + 3 arm period=2) with SENPAI_SEED ∈ {0,1,2}, single env var change `NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2` vs post-#1240 ctrl. Merge gates: G1 mean_arm ≤ 3.26339 / G2 (3.28−μ)×√3 ≥ 0.004 / G3 sign consistent ≥2/3 / G4 mean_ctrl within ±0.003. Worst-case 50% attenuation: final μ=3.26228 still G1+G2 PASS. **Modal PP outcome**: 40% MERGE (3/3 direction-correct, mean Δ ∈ [−0.0025, −0.0015]) / 25% sub-merge MARGINAL (2/3) / 20% NULL (cohort-reversal) / 10% NEG-flip (sign artifact) / 5% STRONG-MERGE (mean ≤ −0.0025). **Cross-chain status cycle-415 (8 chains, 0 idle, 0 review-ready)**: **#1421 tanjiro PP-promote period=2 just-assigned** / #1372 frieren β-schedule Arm D ~11% (ETA ~1.4h) / #1383 askeladd START_STEP multi-arm running / #1388 edward EPS broad sweep / #1393 thorfinn MLP-LR Arm B 1.2 / #1402 fern β EARLY constant / #1409 alphonse NM module coverage / #1412 nezuko NM γ-mixing. No new human GH issues. **Period axis update to post-#1240 NM ridge characterization**: prior understanding "post-#1240 stack at TIGHTLY-TUNED 4-parameter ridge α=0.5/FULL-R/period=5/EPS=1e-4" must be revised if PP validates — period=5 is NOT the optimum, period=2 is a second favorable basin. This is the most significant open PP-promote candidate since #1240 merge.
- **Date:** 2026-05-27 (cycle 414 — 1 stale_wip ack on #1372 frieren NM β-schedule compound retest, **🎯 Arm C timing-only TERMINAL Δ_paired=+0.00107 +0 fs NULL-band fs-tied confirms β-schedule timing-shift axis collapsed on post-#1240 stack** matches Arm B compound +0.00065 NULL). **#1372 chain status** (group `g1r4-frieren/nm-beta-schedule-compound`): A ctrl `lwi7w7mt` TERMINAL val=3.263445 fs=3150 drift +0.00005 EXCEPTIONALLY-CLEAN / B compound β=0.85 @ 2000 `94g7qceq` TERMINAL val=3.264093 fs=3150 Δ=+0.00065 NULL fs-tied / **C timing-only β=0.90 @ 2000 `mityxr0d` TERMINAL val=3.264519 fs=3150 Δ=+0.00107 NULL fs-tied** / D depth-only β=0.85 @ 2345 `drqjwc86` RUNNING step 375/3350 (~11%) just-launched. **Combined finding 3/4 arms terminal**: B compound NULL fs-tied / C timing-only NULL fs-tied / A ctrl exceptionally-clean → **β-schedule axis FULLY COLLAPSED on post-#1240 stack regardless of (depth, timing) decomposition**. Cycle 407 modal Arm C forecast "50% NULL-band axis collapsed" cleanly hits. **Cross-stack stack-dependence finding consolidates**: pre-#1240 #1331 β step-down Arm D Δ=−0.00202 MARGINAL-FAV / Arm C Δ=−0.00142 MARGINAL-FAV → post-#1240 both timing and depth changes individually collapse to NULL. Mechanism: post-#1240 period=5 vs pre-#1240 period=10 provides 2× more responsive R-buffer refresh, extracting late-phase NM responsiveness previously requiring explicit β schedule. **Arm D modal forecast** (updated given B+C NULL): 65% NULL-band axis fully collapsed mirrors B/C / 15% mild-NEG depth at late-timing destabilizes / 15% mild-FAV depth at correct timing minor benefit / 5% surprise FAV PP-candidate depth-at-LATE-TIMING load-bearing. **Modal full-chain outcome updated**: 65% Row 4 productive-NULL all-arms β-schedule dispositively fenced / 15% Row 5 mixed / 15% Row 3 productive-MARGINAL D depth-axis headroom / 5% Row 1/2 surprise. **🎯 Cross-chain context — period axis development MAY INVERT β-schedule story**: if #1356 Arm C period=2 PP-validates, then further-post-#1240 period=2 stack might NEED replayed β-schedule since period and schedule axes might re-couple at different period scales — follow-up β-schedule retest on period=2 stack potentially valuable, strictly hypothetical until #1356 PP-validates. **Cross-chain status cycle-414 (8 chains, 0 idle, 0 review-ready)**: **#1356 tanjiro Arm C period=2 TERMINAL FAV PP-promote candidate / Arm D ~83% near-terminal** (🎯 today's first single-seed FAV) / **#1372 (this) Arm C NULL fs-tied / Arm D depth-only just-launched ~11%** / #1383 askeladd Arm A TERMINAL Arm B ~60% / #1388 edward EPS Arm A ~98% / #1393 thorfinn Arm A TERMINAL FAV / Arm B 1.2 ~95% +25 fs paired / #1402 fern Arm A ~93% / #1409 alphonse NM module coverage just-assigned (correction comment) / #1412 nezuko NM γ-mixing magnitude axis just-assigned. ETA Arm D terminal ~1.5-1.6h, full chain closure decision next cycle (modal productive-NULL β-axis fence). No new human GH issues.

- **Date:** 2026-05-27 (cycle 413 — 1 stale_wip ack on #1356 tanjiro NM period sweep, **🎯 MAJOR FINDING: Arm C period=2 TERMINAL val=3.26053 fs=3125 Δ_paired=−0.00223 −25 fs FAVORABLE — non-monotone period response, first single-seed FAV result in 5+ chains of post-#1240 characterization, PP-promote candidate at MARGINAL threshold**). **#1356 chain status** (group `g1r4-tanjiro/nm-period-sweep-new-stack`): A ctrl period=5 `m2i9s3k4` TERMINAL val=3.262759 fs=3150 drift −0.00063 EXCEPTIONALLY-CLEAN-FAV / B period=3 `792x4704` TERMINAL val=3.266128 fs=3175 Δ=+0.00337 +25 fs CLEAR-NEG / **C period=2 `4uo4hl9w` TERMINAL val=3.260533 fs=3125 Δ_paired=−0.00223 −25 fs FAVORABLE** / D period=10 `zzton5yp` RUNNING step 2775/3350 (~83%). **🎯 NON-MONOTONE PERIOD RESPONSE — contradicts cycle 406 modal**: period=2 FAV / period=3 NEG / period=5 ctrl / period=10 pending. Arm C 5% pre-staged "surprise" probability landed. Qualitatively different from #1363 DIAG anti-monotone refresh trend (UP=1 worst on DIAG, period=2 FAV on full-R). **Statistical signal**: Δ_paired sits in PP-promote MARGINAL band [−0.0025, −0.002], val 3.26053 ≤ baseline 3.26339 G1 PASS, (3.28−3.26053)×√1=0.01947≥0.004 G2 PASS for n=1 screening, both val and fs improve together coherent signal not noise. PP-promote viability: worst-case 50% attenuation → final mean Δ=−0.00111 still G1 PASS μ=3.26228≤3.26339 merge-eligible. **Mechanism interpretations** (await PP validation): 1) bimodal sweet spot at period=5 and period=2 milestone alignment / 2) high-refresh advantage at cooldown rapid late-phase distribution shift / 3) eigenvalue resolution shift period=2 ~40-step EMA window saturation / 4) MAX_D_IN=4096 coverage interaction 12 high-R_cond mlp.proj matrices need faster refresh / 5) single-seed noise artifact need PP. **Today's overall results overwhelmingly NEG-cohort, Arm C is meaningful exception** — first single-seed FAV result in 5+ chains. **Cross-chain implication if PP-validates**: post-#1240 stack has untapped headroom on UPDATE_PERIOD axis — counter-intuitive given #1240 already extended period 10→5, "tightly-tuned 4-parameter preconditioner ridge" characterization needs revision and optimum may be at period=2 not period=5. **Arm D modal forecast** (sanity check pending): 40% NEG period=10 stale R-buffer / 30% NULL axis saturation / 20% mild-FAV / 10% mild-NEG monotone. **Next steps sequential**: 1) await Arm D terminal ~30-45min / 2) student SENPAI-RESULT submission / 3) if Arm C FAV holds → PP-promote to n=3 paired-pod for period=2 (single env var change UPDATE_PERIOD=5→2, rest of post-#1240 stack identical, 6 interleaved sequential runs ctrl+arm × seeds {0,1,2}). **Cross-chain status cycle-413 (8 chains, 0 idle, 0 review-ready)**: **#1356 (this) Arm C TERMINAL FAV PP-promote candidate / Arm D ~83%** / #1372 frieren Arm A PASS Arm B compound NULL Arm C ~12% / #1383 askeladd Arm A TERMINAL Arm B ~60% / #1388 edward EPS Arm A ~98% / #1393 thorfinn Arm A TERMINAL FAV / Arm B 1.2 ~95% +25 fs paired / #1402 fern Arm A ~93% / #1409 alphonse NM module coverage just-assigned (correction comment) / #1412 nezuko NM γ-mixing magnitude axis just-assigned. **🎯 Today's first FAV result** — first single-seed merge candidate since #1240. PP-promote pending Arm D + SENPAI-RESULT. No new human GH issues.

- **Date:** 2026-05-27 (cycle 412 — 1 stale_wip ack on #1393 thorfinn NM MLP-LR fine-grained sweep, **🎯 Arm A ctrl LR_SCALE_MLP=1.0 TERMINAL drift −0.00044 EXCEPTIONALLY-CLEAN FAV (4th clean-FAV ctrl in today's 6-clean-ctrl post-#1240 cohort) + Arm B LR_SCALE_MLP=1.2 RUNNING step 3175/3350 (~95%) partial val=3.2773 paired fs=3175 +25 fs penalty already**). **#1393 chain status** (group `g1r4-thorfinn/nm-mlp-lr-sweep`): A ctrl LR_SCALE_MLP=1.0 `0jn8dcap` TERMINAL val=3.262955 fs=3150 drift −0.00044 FAV / **B fine-boost LR_SCALE_MLP=1.2 `xbhuh24l` RUNNING step 3175/3350 (~95%) partial 3.2773 paired fs=3175 +25 fs paired penalty already established** / C optimum-band LR_SCALE_MLP=1.4 NOT YET LAUNCHED / D over-boost LR_SCALE_MLP=1.6 NOT YET LAUNCHED. **🎯 Arm A drift commentary**: today's 6-clean-ctrl post-#1240 envelope #1356 −0.00063 / #1372 +0.00005 / #1363 +0.00033 / **#1393 (this) −0.00044 FAV** / #1360 +0.00091 / #1383 +0.00194 / #1346 +0.00220 pre-#1240. #1393 Arm A drift puts it in FAV cluster alongside #1356, only #1356 more favorable. **Modal Arm B terminal val** (applying cycle 354 lesson, partial 3.2773 at step 3175 + 175 steps cooldown remaining): 35% [3.265, 3.268] mild-NEG Δ_B ∈ [+0.002, +0.005] / 30% [3.268, 3.272] mid-NEG Δ_B ∈ [+0.005, +0.009] / 20% [3.262, 3.265] NULL-band axis-absorbed / 10% [3.272, 3.280] strong-NEG / 5% surprise FAV ≤ −0.001 retains pre-#1240 #1346 MARGINAL-FAV signal. +25 fs paired penalty at step 3175 strongly suggests **at least mild-NEG outcome** — paired fs penalties rarely close in final cooldown. **🎯 Cross-chain mechanism context — second stack-dependence finding today**: #1372 β-SCHEDULE pre-#1240 #1331 Δ=−0.00202 MARGINAL-FAV → post-#1240 #1372 compound NULL +0.00065 axis-collapsed / #1393 (this) MLP-LR pre-#1240 #1346 Δ=−0.00114 MARGINAL-FAV → post-#1240 #1393 Arm B fs=+25 → likely NULL/mild-NEG axis-collapse OR shifted-optimum. **Mechanism hypothesis**: post-#1240 R-buffer responsiveness (period=5 vs pre-#1240 period=10) extracts late-phase MLP-LR responsiveness previously requiring explicit LR scaling — axis becomes REDUNDANT when R-buffer refresh 2× more responsive. **Modal arm-wise predictions** on post-#1240 stack given Arm B fs+25 axis-collapse signature: C 1.4 45% mild-NEG monotone over-boost / 30% mid-NEG saturation / 15% similar-to-B / 10% surprise FAV; D 1.6 50% strong-NEG clear over-boost / 25% mid-NEG saturation / 15% similar-to-C / 10% surprise FAV. **Modal full-chain outcome**: 45% Row 4 monotone-NEG by LR_SCALE B→C→D progressively worse → joins #1372 β-schedule axis-collapse finding as **second stack-dependence finding today** / 25% Row 5 saturation-NEG axis-redundant / 15% Row 3 productive-MARGINAL sub-merge / 10% Row 2 PP-promote / 5% Row 1 strong-FAV MERGE. **Cross-chain status cycle-412 (8 chains, 0 idle, 0 review-ready)**: #1356 tanjiro Arm B period=3 CLEAR-NEG Arm C ~81% / #1372 frieren Arm A PASS Arm B compound NULL Arm C ~12% / #1383 askeladd Arm A TERMINAL Arm B ~60% / #1388 edward EPS Arm A ~98% / **#1393 (this) Arm A TERMINAL FAV / Arm B 1.2 ~95% +25 fs paired** / #1402 fern Arm A ~93% / #1409 alphonse NM module coverage (correction comment posted cycle 411) / **#1412 nezuko NM γ-mixing magnitude axis just assigned cycle 411**. ETA Arm B terminal ~10-15 min, full chain ~3.5h remaining. **11th NM characterization axis chain** — scale-dimension axis joins post-#1240 stack characterization cohort. No new human GH issues.

- **Date:** 2026-05-27 (cycle 411 — **🎯 #1363 nezuko closed productive-NEG Row 5 dispositive STRUCTURAL finding (55th no-merge, 11th NM mechanism axis closed, FIRST STRUCTURAL ablation in r4 launch) + nezuko reassignment #1412 NM γ-mixing coefficient sweep (12th NM mechanism axis — preconditioner MAGNITUDE virgin axis) + #1409 correction comment posted (MAX_D_IN production=4096 not 1024, mlp.proj IS preconditioned not skipped, full env stack required)**). **#1363 CLOSED** (group `g1r4-nezuko/nm-diagonal-ablation`): 4-arm chain A FULL-R ctrl 3.26372/3150 drift +0.00033 PASS / **B DIAG-ONLY UP=5 3.26808/3200 Δ=+0.00436 +50 fs NEG (best of diag)** / **C DIAG-ONLY UP=1 3.27145/3225 Δ=+0.00773 +75 fs NEG WORST (anti-monotone refresh)** / **D DIAG-ONLY UP=3 3.27092/3225 Δ=+0.00720 +75 fs NEG**. **🎯 Three dispositive structural findings**: 1) off-diagonal R correlations LOAD-BEARING +0.00436 penalty at matched UP=5 / 2) anti-monotone refresh trend faster diagonal refresh HURTS (UP=1 WORST, dispositively rules out "diagonal sufficient if refreshed fast enough") / 3) compute trade-off explicitly unfavorable diag saves 12% per-step but ~7% net wall-clock SLOWER. **K-FAC / Shampoo / Newton-full lineage validated over AdaGrad / RMSProp / Adam diagonal lineage**. **🎯 Joins #1360 in FUNDAMENTAL NM characterization**: #1360 fences α=0.5 (preconditioner POWER), #1363 fences full-R (preconditioner STRUCTURE). Together with #1356 (period=5 robust) these three findings characterize the canonical Newton-Muon parametrization as empirically optimal. **🎯 5 dispositive structural findings within 24h**: #1360 R-power bilateral fence / #1363 (this) DIAG-ONLY structural NEG / #1356 period=3 lower-NEG / #1372 β-schedule NULL collapse / #1409 module coverage in flight. **#1412 nezuko new assignment** (group `g1r4-nezuko/nm-mixing-gamma-sweep`): tests preconditioner MAGNITUDE axis (γ-mixing) — `G_mixed = (1−γ)·G + γ·G_precond`. γ=0 vanilla Muon / γ=1 current full NM (ctrl) / γ ∈ (0,1) partial NM mixing / γ>1 over-extrapolated NM. 4-arm sweep on post-#1240 stack: A γ=1.0 ctrl / B γ=0.5 weak-mix / C γ=0.75 mild-mix / D γ=1.25 over-mix. **Mechanism story**: probes whether NM transform is BINARY (γ ∈ {0,1}) or CONTINUOUS (γ < 1 sweet spot from damped Newton step regularization theory). Cross-axis triangulation: #1363 DIAG fences R-SHAPE / #1360 R-POWER α fences R-POWER inside inverse-sqrt / #1409 alphonse coverage tests WHERE NM applies / **#1412 (this) tests preconditioner step MAGNITUDE outside the inverse-sqrt**. If γ-axis fences at γ=1.0 (Row 4 modal bilateral fence mirroring #1360), all 4 NM-fundamental axes dispositively characterized → "tightly-tuned 4-parameter preconditioner ridge" claim dispositively confirmed and future research must look OUTSIDE NM internals (compound stacks, new optimization paradigms, architectural changes). **Modal full-chain outcome**: 5% Row 1 strong-FAV / 5% Row 2 PP-promote / 25% Row 3 productive-NULL γ-axis fully fenced / **50% Row 4 bilateral fence at γ=1.0 robust mirroring #1360 R-power finding** / 10% Row 5 asymmetric / 5% Row 6 surprise non-canonical optimum. **#1409 correction comment posted**: production stack MAX_D_IN=4096 not 1024 → mlp.proj d_in=3072 IS preconditioned (24 MLP modules total: 12 fc + 12 proj, not 12 fc only) → ATTN:MLP module count ratio revised 48:24 = 2:1 not 4:1 → modal predictions adjusted (Row 5 INVERTED MLP-dominates probability raised given mlp.proj R_cond ~10⁶ vs ~5×10³ for d_in=768 modules per #1240 mechanism story). Full post-#1240 env stack required for reproduce (15 env vars, not just 2). ETA #1412 full 4-arm chain ≈7h sequential. **Cross-chain status cycle-411 (8 chains, 0 idle, 0 review-ready)**: #1356 tanjiro Arm B period=3 CLEAR-NEG Arm C ~81% / #1409 alphonse NM module coverage NEW (correction comment posted) / **#1412 (this) NEW nezuko γ-mixing magnitude axis** / #1372 frieren Arm A PASS Arm B compound NULL Arm C ~12% / #1383 askeladd START_STEP Arm A TERMINAL Arm B ~60% / #1388 edward EPS Arm A ~98% / #1393 thorfinn MLP-LR Arm A ~98% / #1402 fern β EARLY Arm A ~93%. **6 dispositive structural findings within 24h** including #1363 (this) closure. **11th NM mechanism axis closed** with 4 NM-fundamental axes (POWER, SHAPE, COVERAGE in flight, MAGNITUDE in flight) all in characterization. No new human GH issues.

- **Date:** 2026-05-27 (cycle 410 — **🎯 #1360 alphonse closed productive-NEG Row 5 BILATERAL FENCE finding (54th no-merge, 10th NM mechanism axis closed)** + **alphonse reassignment #1409 NM structural coverage ablation MLP vs ATTN — 11th NM mechanism axis virgin structural coverage**). **#1360 CLOSED** (group `g1r4-alphonse/nm-rpower-sweep`): comprehensive 4-arm closure with three dispositive structural findings (bilateral symmetry |Δ_B|/|Δ_C|=1.016 classical near-optimum quadratic sensitivity / R_inv_sqrt_norm monotone scaling with α validates mechanism gate / Newton canonical R^{−1/2} empirically validated). Joins #1363 DIAG-ONLY ablation in dispositively characterizing preconditioner STRUCTURE (full vs diagonal) AND POWER (α=0.5). **#1409 alphonse new assignment** (group `g1r4-alphonse/nm-module-coverage-ablation`): tests STRUCTURAL COVERAGE by module type — distinct from #1363 DIAGONAL (R-shape ablation) and #1360 R-power (α exponent). **Architectural context**: with MAX_D_IN=1024 default, NM currently applied to 48 ATTN modules (q,k,v,proj all d_in=768) + 12 MLP.fc modules (d_in=768, mlp.proj d_in=3072 SKIPPED). 4-arm sweep: A=(MLP=1, ATTN=1) ctrl full coverage / B=(MLP=1, ATTN=0) MLP-only 12 modules / C=(MLP=0, ATTN=1) ATTN-only 48 modules / D=(MLP=0, ATTN=0) NM-off via flags = pre-#1240 sanity. **Mechanism gate**: skipping hook registration → no R-buffer → preconditioning becomes identity for that module type, global newton_precond=True unchanged → minimal-diff structural ablation. **Implementation requires 2 new env vars** `NANOGPT_NEWTON_MUON_MLP_ENABLED` and `NANOGPT_NEWTON_MUON_ATTN_ENABLED` + bit-identity gates (Arm A bit-identical to current code, Arm D bit-identical to `NANOGPT_NEWTON_MUON=0`). **Modal full-chain outcome** (45% Row 4 ATTN-dominates monotone-NEG B then C then A): 5% Row 1 strong-FAV B or C MERGE / 5% Row 2 PP-promote MARGINAL / 25% Row 3 productive-NULL both substitutable / **45% Row 4 ATTN dominates** (48-module count + activation-decorrelation dominance) / 15% Row 5 INVERTED MLP.fc dominates despite 4× fewer modules / 5% Row 6 mixed/anomaly. **🎯 If Arm B shows ANY favorable signal**, follow-up extends MAX_D_IN to include mlp.proj (d_in=3072, currently skipped, 12 more MLP modules). **🎯 If Arm C dominates A**, MLP NM is wasted compute → reallocate. **🎯 Cross-chain disambiguation**: #1363 nezuko DIAG-ONLY tests R-SHAPE structural / #1409 (this) tests COVERAGE LOCATION structural — both target preconditioner structure but on orthogonal axes. ETA full 4-arm chain ≈7h sequential. **Cross-chain status cycle-410 (8 chains, 0 idle, 0 review-ready)**: #1356 tanjiro Arm B period=3 CLEAR-NEG Arm C ~81% / **#1409 (this) NEW alphonse assignment NM module coverage MLP vs ATTN** / #1363 nezuko Arm B DIAG-ONLY CLEAR-NEG Arm C ~25% / #1372 frieren Arm A PASS Arm B compound NULL Arm C ~12% / #1383 askeladd START_STEP Arm A TERMINAL Arm B ~60% / #1388 edward EPS Arm A ~98% / #1393 thorfinn MLP-LR Arm A ~98% / #1402 fern β EARLY Arm A ~93%. **5 dispositive structural findings within 24h** on post-#1240 stack validating tightly-tuned 4-parameter preconditioner ridge (α=0.5 / FULL-R / period=5 / EPS=1e-4) + #1409 11th NM mechanism axis virgin structural coverage. No new human GH issues.

- **Date:** 2026-05-27 (cycle 409 — 2 stale_wip acks on #1402 fern β EARLY constant sweep (Arm A ~93% near-terminal) + #1360 alphonse NM R-power **FULL CHAIN TERMINAL 4/4, 🎯 Row 5 BILATERAL FENCE finding — α=0.5 ROBUST OPTIMUM, R-power axis DISPOSITIVELY FENCED both sides, Newton canonical R^{−1/2} empirically validated**). **#1360 FULL CHAIN TERMINAL** (group `g1r4-alphonse/nm-rpower-sweep`): A ctrl α=0.5 `gedqercc` 3.264300/3150 drift +0.00091 PASS / **B weaker α=0.333 `fzhgh0lg` 3.266852/3175 Δ=+0.00255 +25 fs CLEAR-NEG** / **C stronger α=0.667 `ebmkb1lr` 3.266810/3175 Δ=+0.00251 +25 fs CLEAR-NEG** / **D strongest α=0.75 `q8hq1b1x` 3.270819/3225 Δ=+0.00652 +75 fs STRONGEST-NEG**. **🎯 BILATERAL SYMMETRY**: |Δ_B|/|Δ_C| = +0.00255/+0.00251 = 1.016 within noise — classical near-optimum quadratic sensitivity signature around α=0.5. Δ_D/Δ_C = 2.60 (predicted 2.24 from pure quadratic-distance scaling, 15% deviation consistent with R-buffer noise amplification at higher α). **Mechanism interpretation**: α<0.5 R-eigenvalue dynamic range R_cond^α insufficient under-corrects MLP down-proj matrices / α>0.5 amplifies R-buffer EMA noise on small eigenvalues / α=0.5 optimum balance. **Validates Shampoo/K-FAC/Newton lineage choice**. Joins #1363's DIAG-ONLY ablation in dispositively characterizing preconditioner STRUCTURE (full vs diagonal) AND POWER (α=0.5). **🎯 4 dispositive structural findings within 24h on post-#1240 stack** validating tightly-tuned 4-parameter preconditioner ridge (α=0.5 / FULL-R / period=5 / EPS=1e-4): #1360 R-power bilateral fence / #1356 period lower-NEG / #1363 DIAG-ONLY NEG / #1372 β-schedule NULL-collapse. **No merge** all 4 arms above baseline G1 FAIL; 10th NM mechanism axis closed productive-NEG (54th no-merge in r4 launch). **Pending SENPAI-RESULT submission and label-swap to status:review for formal closure** then alphonse reassignment. **#1402 fern Arm A ctrl β=0.95 `qjc5f6mx` RUNNING step 3125/3350 (~93%) partial val=3.283 mid-cooldown** FFS not yet reached (first_step_to_target=-1, slightly noisy ctrl trajectory). Modal Arm A terminal val: 35% [3.262, 3.270] PASS-CLEAN / 30% [3.270, 3.275] PASS-MARGINAL / 20% [3.275, 3.280] expanded MARGINAL / 15% [3.280, 3.285] EDGE FFS-shift. **🎯 Cross-chain disambiguation**: #1372 frieren just confirmed β-SCHEDULE NULL collapse on post-#1240 stack (Arm B compound β=0.85@2000 Δ=+0.00065 NULL); if #1402 Arm B β=0.90 EARLY constant lands NULL then β-AXIS fully redundant (saturation), if shows favorable then constant-β axis has untapped headroom — mechanism story: what matters is AVERAGE β during late-phase, not schedule shape. β is the LAST core preconditioner-parameter not yet fenced on post-#1240 stack. Modal full-chain: 40% Row 5 productive-NULL β=0.95 robust both axes fenced / 30% Row 4 monotone-by-β / 20% Row 3 productive-MARGINAL constant-β axis-headroom / 5% Row 2 PP-promote / 5% Row 1 surprise. ETA Arm A terminal ~15-20 min, full chain B/C/D sequential ~6h. **Cross-chain status cycle-409 (8 chains, 0 idle, 0 review-ready but #1360 TERMINAL pending student-submission)**: #1356 tanjiro Arm B period=3 CLEAR-NEG Arm C ~81% / **#1360 (this) FULL CHAIN TERMINAL 4/4 Row 5 BILATERAL FENCE pending submit** / #1363 nezuko Arm B DIAG-ONLY CLEAR-NEG Arm C ~25% / #1372 frieren Arm A PASS Arm B compound NULL Arm C ~12% / #1383 askeladd START_STEP Arm A TERMINAL Arm B ~60% / #1388 edward EPS Arm A ~98% / #1393 thorfinn MLP-LR Arm A ~98% / **#1402 (this) Arm A ~93% near-terminal**. No new human GH issues.

- **Date:** 2026-05-27 (cycle 408 — 1 stale_wip ack on #1383 askeladd H1 NM START_STEP gating chain, **Arm A always-on ctrl TERMINAL val=3.26533 fs=3175 drift +0.00194 +25 fs PASS-MARGINAL G4 + Arm B START=1500 RUNNING ~60% partial val=3.4287 mid-pre-cooldown**). **#1383 chain status** (group `g1r4-askeladd/nm-start-step-sweep`): A always-on ctrl `19vdad68` TERMINAL val=3.26533 fs=3175 drift +0.00194 +25 fs / **B late-start=1500 `dznqnq8e` RUNNING step 2025/3350 (~60%) partial 3.4287 mid-pre-cooldown** / C step=2000 NOT YET LAUNCHED / D step=2400 NOT YET LAUNCHED. **🎯 Arm A drift commentary**: at upper end of today's 6-clean-ctrl envelope (#1356 −0.00063 / #1372 +0.00005 / #1363 +0.00033 / #1360 +0.00091 / **#1383 +0.00194 +25 fs ← noisiest of cohort** / #1346 +0.00220 pre-#1240). +25 fs suggests run-level noise inflated ctrl by ~0.001; paired Δ within-chain bit-identical-comparable so mechanism signal intact. **Modal Arm B terminal val** (partial 3.4287 at step 2025 normal pre-cooldown range, val drops 0.08-0.12 in final 1000 steps): 35% NULL-band Δ_B ∈ [−0.0015, +0.0015] (skip-early-NM viable compute simplification ~45%) / 30% mild-NEG Δ_B ∈ [+0.001, +0.003] (R-buffer warm-up partially needed) / 25% mild-FAV Δ_B ∈ [−0.0015, −0.0005] (skip noisy early-training NM beneficial, early gradient outer products noise-dominated corrupt R-buffer EMA) / 10% strong-NEG Δ_B ≥ +0.003. **Modal Arms C/D pending**: Arm C step=2000 (aligns with #1331 β=2000 timing-winner) 35% mild-NEG / 35% NULL / 20% mild-FAV / 10% strong-NEG; Arm D step=2400 (aligns with #1286 PP late-only NULL-collapse finding & NS_COOLDOWN_START step 2345) **40% mild-NEG R-buffer warm-up essential** (mirrors #1286 12 MLP down-proj matrices need R-buffers populated EARLY) / 30% NULL / 20% mild-FAV / 10% strong. **Modal full-chain outcome**: 35% Row 4 coverage-essential (monotone-NEG R-buffer warm-up across pre-cooldown necessary, mirrors #1286 PP late-only NULL-collapse, dispositively fences gating axis) / 30% Row 3 late-only-sufficient (B/C/D NULL → compute simplification ~45-71% NM compute reduction direct merge candidate) / 20% Row 5 mixed / 10% Row 2 mid-gate sweet-spot (Arm C step=2000 matches #1331 timing-winner independent confirmation) / 5% Row 1 strong-FAV. **🎯 Cross-chain mechanism dependency on #1372**: frieren compound-β arm B compound = NULL on post-#1240 stack (β-schedule axis collapses) — if Arm C START=2000 ≈ Arm B on this chain, β-schedule fully redundant consistent finding; if Arm C significantly different from B, then START_STEP gates SOMETHING β-schedule doesn't. **Cross-chain status cycle-408 (8 chains, 0 idle, 0 review-ready)**: #1356 tanjiro Arm B period=3 CLEAR-NEG Arm C ~81% / #1360 alphonse Arm B α=0.333 CLEAR-NEG Arm C ~97% / #1363 nezuko Arm B DIAG-ONLY CLEAR-NEG Arm C ~25% / #1372 frieren Arm A PASS Arm B compound NULL Arm C ~12% / **#1383 (this) Arm A TERMINAL Arm B ~60% partial** / #1388 edward EPS Arm A ~98% / #1393 thorfinn MLP-LR Arm A ~98% / #1402 fern β EARLY constant sweep. ETA full chain ~5-6h remaining. **11th NM mechanism axis (virgin temporal gate)** when chain closes. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 407 — 1 stale_wip ack on #1372 frieren NM β-schedule compound retest, **🎯 Arm A TERMINAL drift +0.00005 EXCEPTIONALLY-CLEAN PASS (EPS=1e-8 confound EFFECTIVELY RESOLVED ≈ NULL vs default 1e-4) + Arm B COMPOUND TERMINAL Δ_paired=+0.00065 NULL-band fs unchanged: β-schedule mechanism COLLAPSED on post-#1240 stack (saturation scenario 30% prior actualizes)**). **#1372 chain status** (group `g1r4-frieren/nm-beta-schedule-compound`): A ctrl `lwi7w7mt` TERMINAL val=3.26344 fs=3150 drift +0.00005 PASS-CLEAN / **B COMPOUND β=0.85 @ 2000 `94g7qceq` TERMINAL val=3.26409 fs=3150 Δ_paired=+0.00065 NULL fs-tied** / C timing-only β=0.90 @ 2000 `mityxr0d` RUNNING ~12% mid-pre-cooldown / D depth-only β=0.85 @ 2345 NOT YET LAUNCHED. **🎯 EPS=1e-8 confound resolved**: Arm A drift +0.00005 vs 3.26339 with EPS=1e-8 BASE is 60× margin within G4 — cross-chain G1 against baseline now valid without #1388 Arm C dependency. Joins today's 6-clean-ctrl cohort (5 of 6 within ±0.00091 envelope exceptional reproducibility). **🎯 Arm B compound = NULL (saturation actualized)**: G1 val_B=3.26409 vs baseline 3.26339 gap=+0.00070 FAIL above-baseline / fs tied. **Stack-dependence finding**: pre-#1240 #1331 Arm D β=0.90@2000 Δ=−0.00202 / Arm C β=0.85@2345 Δ=−0.00142 MARGINAL-FAV → **post-#1240 compound Δ=+0.00065 NULL** — β-schedule axis-winners DO NOT replicate on new stack. **Mechanism interpretation**: period=5 (post-#1240) already extracts late-phase R-buffer responsiveness that β-schedule provided on pre-#1240 (period=10) stack — β-schedule axis BECOMES REDUNDANT when R-buffer refresh is 2× more responsive. **🎯 Joins today's broader cohort**: post-#1240 stack is at tightly-tuned preconditioner ridge (α=0.5 / FULL-R / period=5 / EPS=1e-4) where parameter perturbations are NULL or NEG: β-schedule axis collapses NULL / period=3 +0.00337 / α=0.333 +0.00255 / DIAG-ONLY +0.00436. **Modal Arm C timing-only**: 50% NULL-band Δ_C ∈ [−0.001, +0.001] (axis collapsed) / 25% mild-FAV / 15% mild-NEG / 10% surprise. **Modal Arm D depth-only**: 50% NULL-band / 20% mild-FAV / 20% mild-NEG / 10% surprise. **Modal full-chain outcome**: 55% Row 4 productive-NULL stack-dependence (β-schedule axis absorbed by period=5 R-buffer responsiveness) / 25% Row 3 productive-MARGINAL (sub-merge axis-survival) / 15% Row 5 mixed / 5% Row 1/2 surprise super-additive. **11th NM mechanism axis** when chain closes (joins period=3, R-power α=0.333, DIAG-ONLY characterizing post-#1240 ridge geometry). ETA Arm C terminal ~2-2.5h, full chain ~4.5h remaining. **Cross-chain status cycle-407 (8 chains, 0 idle, 0 review-ready)**: #1356 tanjiro Arm B period=3 CLEAR-NEG Arm C ~81% / #1360 alphonse Arm B α=0.333 CLEAR-NEG Arm C ~97% / #1363 nezuko Arm B DIAG-ONLY CLEAR-NEG Arm C ~25% / **#1372 (this) Arm A PASS Arm B NULL Arm C ~12%** / #1383 askeladd START_STEP Arm A ~60% / #1388 edward EPS Arm A ~98% / #1393 thorfinn MLP-LR Arm A ~98% / #1402 fern β EARLY constant sweep. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 406 — 1 stale_wip ack on #1356 tanjiro NM period sweep, **🎯 Arm B period=3 TERMINAL ADVERSE Δ_paired=+0.00337 +25 fs Row 5 dispositive structural finding — PERIOD AXIS HAS NO HEADROOM BELOW period=5**). **#1356 chain status** (group `g1r4-tanjiro/nm-period-sweep-new-stack`): Arm A ctrl period=5 `m2i9s3k4` TERMINAL val=3.26276 fs=3150 drift −0.00063 EXCEPTIONALLY-CLEAN-FAV / **Arm B period=3 `792x4704` TERMINAL val=3.26613 fs=3175 Δ_paired=+0.00337 +25 fs CLEAR-NEG** / Arm C period=2 `4uo4hl9w` RUNNING ~81% partial val=3.34182 mid-trajectory / Arm D period=10 sanity NOT YET LAUNCHED. **🎯 Arm B Δ exceeded pre-staged thresholds**: Row 5 ≥ +0.0015 confirmed and exceeded 2.2× / pre-staged modal "5% strong-NEG" outcome lands here. **🎯 Joins today's CLEAR-NEG paired-delta cohort**: #1360 Arm B α=0.333 Δ=+0.00255 / #1363 Arm B DIAG-ONLY Δ=+0.00436 / #1356 Arm B period=3 Δ=+0.00337 — 3 dispositive NEG arms within 24h validate post-#1240 stack mechanisms are tightly tuned at preconditioner sweet-spot. **🎯 Mechanism interpretation**: R-buffer EMA needs sufficient sample window to develop coherent second-order statistics. Period=3 (1.67× denser refresh) leaves R-buffer EMA INSUFFICIENTLY SMOOTHED — noise from individual gradient outer products dominates true second-order signal, preconditioner overcorrects. Period=5 sufficient EMA smoothing, sample window captures dominant eigenvector rotation rate. **Cross-mechanism convergence**: α=0.333 weaker power +0.00255 / DIAG-ONLY UP=5 +0.00436 / period=3 over-refresh +0.00337 → post-#1240 stack at preconditioner sweet-spot tightly, α=0.5 / FULL-R / period=5 / EPS=1e-4 form robust 4-parameter ridge. **Modal Arm C period=2**: 55% strong-NEG Δ_C ≥ +0.005 (continues monotone-by-period-low trend over-refresh × 2.5 worse) / 30% mild-NEG Δ_C ∈ [+0.002, +0.005] saturation / 10% NEG-similar / 5% surprise NULL. **Modal Arm D period=10** (sanity): 50% mild-NEG Δ_D ∈ [+0.001, +0.002] confirms period=5 > period=10 cleanly disambiguated / 30% NULL / 20% mild-FAV surprising. **Modal full-chain outcome**: 70% Row 5 NEG-monotone-by-low-period (period=5 local optimum on BOTH sides, axis dispositively fenced bilaterally) / 20% Row 4 saturation in NEG / 10% surprise. **10th NM mechanism axis** when chain closes (joins R-power, diagonal, period axes converging on tight 4-parameter ridge characterization). ETA Arm C terminal ~1-1.5h, full chain ~3.5h. **Cross-chain status cycle-406 (8 chains, 0 idle, 0 review-ready)**: **#1356 (this) Arm A clean / Arm B TERMINAL Row 5 NEG / Arm C ~81%** / #1360 alphonse R-power Arm A PASS Arm B CLEAR-NEG Arm C ~97% / #1363 nezuko diagonal Arm B CLEAR-NEG Arm C ~25% / #1372 frieren compound-β Arm A near-terminal EPS-confound unblock dep on #1388 / #1383 askeladd START_STEP Arm A ~60% / #1388 edward EPS Arm A ~98% near-terminal / #1393 thorfinn MLP-LR Arm A ~98% near-terminal / #1402 fern β EARLY constant sweep. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 405 — 1 stale_wip ack on #1393 thorfinn NM MLP-LR fine-grained sweep on post-#1240 stack, **Arm A ctrl `0jn8dcap` LR_SCALE_MLP=1.0 RUNNING step 3275/3350 (~98%) partial val=3.2667 mid-cooldown, FFS=3150 already reached, chain HEALTHY**). **#1393 chain status** (group `g1r4-thorfinn/nm-mlp-lr-sweep`): A ctrl LR_SCALE_MLP=1.0 ~98% ETA ≤30 min / B 1.2 NOT YET LAUNCHED / C 1.4 NOT YET LAUNCHED / D 1.6 NOT YET LAUNCHED. **🎯 Cross-chain hypothesis context from #1346 CLOSED productive-MARGINAL (pre-#1240 stack, cycle 398)**: Arm B LR_SCALE_MLP=1.2 Δ=−0.00114 MARGINAL-FAV / Arm C LR_SCALE_MLP=0.8 damping Δ=+0.00273 strongly ADVERSE / asymmetric damping cost (|Δ_C|/|Δ_B|=2.39× damping > boost) → modal MLP-LR optimum > 1.2. 12 MLP down-proj matrices (d_in=3072, R_cond ~10^6) added by #1240 coverage extension had insufficient per-matrix LR at ctrl; #1297 per-matrix MLP-leverage = 1.6× MLP-leverage on damage skew. **Modal Arm A terminal val** (cycle 354 lesson, partial 3.2667 at step 3275 can drop 0.005-0.012 in final 75 steps cooldown completion): 50% [3.262, 3.266] PASS-CLEAN joins today's 5-clean-ctrl drift cohort (#1356/#1346/#1360/#1363/#1388) / 30% [3.266, 3.269] MARGINAL / 15% [3.269, 3.275] mild-adverse / 5% ≥ 3.275 anomaly. **Modal arm-wise predictions on post-#1240 stack** (more responsive R-buffer from period=5): B 1.2 30% mild-FAV / 40% NULL stack-absorbs-axis / 25% mild-NEG saturation / 5% surprise; C 1.4 35% mild-FAV optimum near 1.4 / 30% NULL / 25% mild-NEG over-boost / 10% strong-FAV peak Δ ≤ −0.002; D 1.6 25% mild-FAV / 30% NULL / 35% mild-NEG over-boost R-buffer noise amplification / 10% strong-FAV peak. **Modal full-chain**: 40% Row 5 saturation (post-#1240 stack absorbs MLP-LR axis, ctrl 1.0 robust optimum) / 30% Row 3 productive-MARGINAL (monotone direction sub-threshold, follow-up finer sweep) / 20% Row 1/2 PP-promote MARGINAL (peak at 1.2-1.4 single-seed Δ ≤ −0.002 MERGE candidate after n=3 PP) / 5% Row 4 monotone-NEG over-boost responsive stack / 5% Row 6 surprise. **Cross-chain context**: NM mechanism core preconditioner-parameter trio (β, ε, α) all in flight (#1402 fern β EARLY / #1388 edward EPS / #1360 alphonse R-power α) + #1393 thorfinn LR-scale = scale-dimension orthogonal axis. Combined with #1346 already-closed pre-#1240 result, full LR-scale axis characterization spans both stacks. **ETA full chain ~6h sequential**. **Cross-chain status cycle-405 (8 chains, 0 idle, 0 review-ready)**: #1356 tanjiro period sweep Arm B period=3 near-terminal / #1360 alphonse R-power Arm A PASS Arm B CLEAR-NEG Arm C ~97% / #1363 nezuko diagonal Arm B CLEAR-NEG Arm C ~25% / #1372 frieren compound-β Arm A near-terminal EPS-confound unblock dep on #1388 / #1383 askeladd START_STEP gating Arm A ~60% / #1388 edward EPS sweep Arm A ~98% near-terminal / **#1393 (this) Arm A ~98% near-terminal** / #1402 fern β EARLY constant sweep. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 404 — 1 stale_wip ack on #1388 edward NM EPS sensitivity sweep, **Arm A ctrl `0v9rzbbc` RUNNING step 3300/3350 (~98%) partial val=3.2681 mid-cooldown heartbeat 07:00:58Z chain HEALTHY**). **#1388 chain status** (group `g1r4-edward/nm-eps-sweep`): Phase 0 verified at 04:54Z baseline EPS = 1e-4 (script default at train_gpt_simple.py:603, BASELINE.md reproduce does NOT set EPS), Arm A bit-identity baseline replication. A ctrl `0v9rzbbc` ~98% partial 3.2681 mid-cooldown ETA ≤30 min / B 1e-6 (−2 dex tighter) NOT YET LAUNCHED / C 1e-8 (−4 dex much-tighter) NOT YET LAUNCHED / D 1e-2 (+2 dex looser) NOT YET LAUNCHED. **🎯 Cross-chain dependency — #1388 Arm C (EPS=1e-8) directly unblocks #1372 frieren cross-chain G1 confound** (frieren's BASE env sets EPS=1e-8 vs baseline script-default 1e-4): if #1388 Arm C terminal within G4 (±0.003) of baseline 3.26339, #1372 cross-chain G1 unconfounded directly; if Arm C significantly diverges, #1372 cross-chain comparisons must re-anchor against #1388 Arm C. **12th NM mechanism axis** when chain closes — completes core preconditioner-parameter trio (β, ε, α) alongside in-flight #1402 fern β EARLY constant / #1360 alphonse R-power α (Arm B α=0.333 CLEAR-NEG terminal, Arm C α=0.667 near-terminal). NM mechanism space saturation approaching with 4 in-flight virgin-axis chains (β-EARLY / EPS / α / β-schedule-compound). **Modal Arm A terminal val** (cycle 354 lesson, partial 3.2681 at step 3300 mid-cooldown can drop 0.005-0.012 in final 50 steps): 40% [3.262, 3.266] PASS-CLEAN / 30% [3.266, 3.270] MARGINAL within G4 outer / 20% [3.270, 3.275] mild-adverse ctrl drift / 10% ≥ 3.275 anomaly would flag EPS-default mismatch. **Modal full-chain prediction**: 45% Row 4 productive-NULL (EPS sensitivity-monotone, default near-optimum, axis fenced) / 25% Row 3 productive-MARGINAL (monotone-by-EPS direction sub-threshold — follow-up at finer resolution e.g. 1e-3, 1e-5, 1e-7) / 20% Row 2 PP-promote MARGINAL (tighter Arm B/C OR looser Arm D wins direction-characterized) / 5% Row 1 PP-promote landmark / 5% Row 5 mixed/surprise R-buffer noise sweet-spot. **Arm-wise modal predictions**: B 1e-6 30% mild-FAV (sharper preconditioning unlocks ill-conditioned MLP correction) / 40% NULL / 25% mild-NEG (R-buffer noise amplification) / 5% surprise; C 1e-8 25% mild-FAV / 25% NULL / 35% mild-NEG (R-buffer noise dominates) / 15% strong-NEG (numerical instability on rank-deficient blocks); D 1e-2 35% NULL (preconditioner near-identity for small λ retains coarse NM benefit) / 35% mild-NEG (loses NM benefit on ill-conditioned MLP matrices) / 20% mild-FAV (current is over-aggressive at small λ) / 10% surprise. **ETA**: Arm A terminal ≤30 min, B/C/D sequential ≈3×107 min ≈ 5.5h, full chain ≈6h. **Cross-chain status cycle-404 (8 chains, 0 idle, 0 review-ready)**: #1356 tanjiro period sweep Arm B period=3 near-terminal / #1360 alphonse R-power Arm A bit-identity PASS Arm B clear-NEG Arm C ~97% near-terminal / #1363 nezuko diagonal Arm B clear-NEG Arm C ~25% / #1372 frieren compound-β Arm A near-terminal EPS-confound unblock dependency on #1388 / #1383 askeladd START_STEP gating Arm A ~60% / **#1388 (this) Arm A ~98% near-terminal** / #1393 thorfinn MLP-LR fine-grained sweep / #1402 fern β EARLY constant sweep. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 403 — **#1286 fern PP CLOSED productive-NULL (53rd no-merge, 4th PP attenuation pattern dispositively cataloged)** + fern REASSIGNED **#1402 NM β EARLY constant sweep on post-#1240 stack** + 1 stale_wip ack on #1360 alphonse R-power chain). **#1286 PP terminated** 6/6 runs on pre-#1240 stack: s0-A `qzuvy6wa` 3.266322/3175 / s0-C `957t6w8u` 3.265627/3175 Δ=−0.000695 NULL-FAV / s1-A `9it76841` 3.265393/3175 / s1-C `bkl9s3yi` 3.265921/3175 Δ=+0.000528 NULL-ADV / s2-A `g1iuhcu8` 3.266273/3175 / **s2-C `8fw447mr` TERMINAL val=3.265704 fs=3175 Δ_s2=−0.000569 NULL-FAV (returns to favorable direction)**. **n=3 mean Δ_paired=−0.000245 NULL-band-FAV** (within |Δ|≤0.0015 by 6× margin), sign distribution 2/3 favorable 1/3 adverse. FFS uniformly stable at fs=3175 across all 6 runs. **🎯 4th PP attenuation pattern dispositively cataloged — NULL-collapse (95% attenuation)** from screening Δ=−0.00188 → terminal Δ=−0.000245. PP catalog complete: #1240 enhancement (−18% strengthens) / #1281 cohort-reversal (+153%) / **#1286 NULL-collapse (95%)** / #1318 cohort-absorption. **🎯 PP noise-floor insight**: 3 of 4 PP-escalated single-seed screening signals collapsed to NULL or reversed at terminal — single-seed Δ ∈ [−0.002, +0.002] should NOT be treated as definitive direction, requires PP n=3 confirmation; only signals Δ ≤ −0.003 (#1240 magnitude class) robust under PP escalation. **🎯 Late-vs-always-on coverage dissociation finding confirmed**: 12 MLP down-proj matrices need R-buffers populated EARLY (across pre-step-2400, ~71% of training) to develop coherent preconditioning statistics — late-only coverage activations dead-end for future experiments. **No merge**: mean val_C 3.265751 = +0.002361 over post-#1240 baseline G1 FAIL by wide margin; Row 3 productive-NULL dispositively closes late-only coverage axis. **fern REASSIGNED #1402 NM β EARLY constant sweep on post-#1240 stack** (`g1r4-fern/nm-beta-early-sweep`): 4-arm A=0.95 ctrl / B=0.90 faster EMA / C=0.97 slower / D=0.99 much-slower. No code changes (env var `NANOGPT_NEWTON_MUON_BETA` already exists at train_gpt_simple.py:603). **Distinct from β-SCHEDULE work** — keeps β constant throughout training, tests EARLY-β optimum on responsive post-#1240 stack (2× more responsive R-buffer from period=5). Pre-staged 6-row decision tree. Modal: 35% Row 5 productive-NULL (β=0.95 EARLY robust optimum) / 30% Row 4 monotone-by-β / 25% Row 3 productive-MARGINAL / 5% Row 2 PP-promote / 5% Row 1 MERGE. ETA full chain ~7h sequential. **#1360 chain status** (group `g1r4-alphonse/nm-rpower-sweep`): A ctrl α=0.5 `gedqercc` TERMINAL 3.264300/3150 drift +0.00091 PASS / **B weaker α=0.333 `fzhgh0lg` TERMINAL val=3.266852 fs=3175 Δ_paired=+0.002552 +25 fs CLEAR-NEG confirms weaker-α direction destructive** (less adverse than partial extrapolation +0.00623 — cycle 354 lesson applied) / C stronger α=0.667 `ebmkb1lr` RUNNING ~97% partial val=3.2726 mid-cooldown terminal in ~minutes / D strongest α=0.75 NOT YET LAUNCHED. **Mechanism interpretation**: R^{−0.333} dynamic range (R_cond)^0.333 ~ 100 vs canonical (R_cond)^0.5 ~ 1000 for R_cond~10^6 — preconditioner insufficiently sharp on 12 MLP down-proj matrices (d_in=3072). Modal Arm C: 40% NULL-band (α=0.5 robust optimum) / 30% mild-NEG / 20% mild-FAV (optimum at α≈0.6) / 10% surprise. **Cross-chain status cycle-403 (8 chains, 0 idle, 0 review-ready)**: **#1286 (CLOSED) #1402 fern just-assigned** / #1356 tanjiro Arm B period=3 ~94% near-terminal / **#1360 (this) Arm B clear-NEG Arm C ~97% near-terminal** / #1363 nezuko diagonal 2/4 terminal Arm B clear-NEG Arm C ~25% / #1372 frieren compound-β Arm A near-terminal / #1383 askeladd START_STEP gating Arm A ~60% / #1388 edward EPS sensitivity sweep / #1393 thorfinn MLP-LR fine-grained sweep. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 402 — 1 stale_wip ack on #1383 askeladd H1 NM step-gated activation timing sweep, **Arm A always-on ctrl `19vdad68` RUNNING step 2025/3350 (~60%) partial val=3.4313 mid-pre-cooldown**). **#1383 chain status** (group `g1r4-askeladd/nm-start-step-sweep`): A always-on ctrl RUNNING ~60% ETA terminal ~2-2.5h / B START=1500 NOT YET LAUNCHED / C START=2000 NOT YET LAUNCHED / D START=2400 NOT YET LAUNCHED. **Directly addresses Issue #1261 H1 directive bullet** ("Newton-Muon only after step X") — virgin axis distinct from RESET (clears R-buffer) and BETA-schedule (changes EMA decay). Adds `NANOGPT_NEWTON_MUON_START_STEP` env var gating entire NM mechanism on/off by step. **Tests competing hypotheses**: (1) late-only-NM-sufficient → Row 3 simplification ~71% NM compute reduction with no quality loss if Arm D NULL (~25% prior, direct merge candidate compute+quality preserving) / (2) coverage-essential → Row 4 monotone-NEG R-buffer warm-up necessary mirrors #1286 fern PP late-only NULL-collapse finding (~30% prior) / (3) mid-gate sweet-spot → Row 2 marginal-FAV at Arm C START=2000 aligns with #1331 β=2000 timing-winner from frieren chain — independent confirmation step ~2000 mechanism-relevant (~10% prior) / (4) mixed → Row 5 ambiguous (~20% prior) / (5) strong-FAV → Row 1 surprise (~5% prior). **Modal Arm A terminal val**: 50% [3.262, 3.266] PASS-CLEAN / 30% [3.266, 3.270] PASS-MARGINAL / 15% [3.270, 3.275] expanded MARGINAL / 5% ≥ 3.275 noise. **Cross-chain mechanism dependency**: #1372 frieren compound-β has LATE_START_STEP=2000 (β-schedule transition point) — this START_STEP axis tests whether entire NM mechanism activates at step X vs only β-schedule transition activates at step X. Same step-2000 anchor on both should give consistent direction signals. **11th NM mechanism axis** when chain closes (virgin temporal gate). ETA Arm A terminal ~2-2.5h, B+C+D ~6h sequential → total chain ~8h remaining. **Cross-chain status cycle-402 (8 chains, 0 idle)**: #1286 fern PP 5/6 terminal s2-C pending NULL-collapse / #1356 tanjiro Arm B period=3 ~94% near-terminal / #1360 alphonse R-power Arm A PASS Arm B near-terminal ADVERSE / #1363 nezuko diagonal 2/4 terminal Arm B clear-NEG Arm C ~25% / #1372 frieren compound-β Arm A near-terminal / **#1383 (this) Arm A ~60% terminal in ~2-2.5h** / #1388 edward EPS sensitivity sweep / #1393 thorfinn MLP-LR sweep just-assigned. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 401 — 1 stale_wip ack on #1363 nezuko NM diagonal preconditioning ablation, **🎯 Arm B DIAG-ONLY UP=5 TERMINAL ADVERSE Δ_paired=+0.00436 +25 fs CLEAR NEG confirms off-diagonal R terms ARE LOAD-BEARING — first dispositive structural ablation in r4 launch, 10th NM mechanism axis structural finding emerging**). **#1363 chain status** (group `g1r4-nezuko/nm-diagonal-ablation`): Arm A FULL-R ctrl `lfa0hjlp` TERMINAL val=3.263724 fs=3150 drift +0.000334 EXCEPTIONALLY-CLEAN / **Arm B DIAG-ONLY UP=5 `6bpz5f0d` TERMINAL val=3.268082 fs=3200 Δ_paired_val=+0.00436 Δ_paired_fs=+25 CLEAR NEG** / Arm C DIAG-ONLY UP=1 `je4i9gh1` RUNNING step 825/3350 (~25%) val=3.692 mid-warmup pending / Arm D DIAG-ONLY UP=3 NOT YET LAUNCHED. **🎯 Schmidhuber-style "old idea" disambiguation finding**: off-diagonal R terms encode load-bearing parameter coupling that diagonal-only preconditioning cannot capture. 12 MLP down-proj matrices (d_in=3072, R_cond ~10^6) have off-diagonal R structure encoding gradient correlations across input dimensions; diagonal-only collapses to AdaGrad-style per-dimension reciprocal-magnitude scaling, under-resolving dominant parameter manifold directions. **Mechanism axis distinction**: K-FAC / Shampoo / Newton-full lineage VALIDATED vs AdaGrad / RMSProp / Adam diagonal lineage RULED OUT for this regime. Rules out a major simplification path (diagonal-only would have been 60× cheaper per update on a 3072×3072 matrix). **Modal forecast Arm C DIAG-ONLY UP=1** (5× faster refresh): 50% mild-NEG Δ_C ∈ [+0.002, +0.003] (faster refresh partial compensation) / 25% NEG-similar to Arm B / 15% mild-FAV vs Arm B / 10% strong-NEG worse. **Modal forecast Arm D DIAG-ONLY UP=3**: 50% NEG between B and C monotone-by-refresh / 25% similar to B / 15% similar to C / 10% surprise. **Modal full-chain outcome**: 60% Row 5 productive-NEG full-chain (DIAGONAL always worse than full-R regardless of refresh rate, dispositive structural finding justifies full-NM lineage) / 25% Row 4 monotone-by-refresh partial substitutability / 10% Row 3 surprise productive-NULL if C/D recovers / 5% mixed. ETA Arm C terminal ~3.5h, full chain ~5h remaining. **10th NM mechanism axis** when chain closes (first virgin structural ablation in r4 launch beyond hyperparameter sweeps). **Cross-chain status cycle-401 (8 chains, 0 idle)**: #1286 fern PP 5/6 terminal s2-C pending NULL-collapse / #1356 tanjiro Arm B period=3 ~94% near-terminal / #1360 alphonse R-power Arm A PASS Arm B near-terminal ADVERSE / **#1363 (this) 2/4 terminal Arm B clear-NEG Arm C ~25%** / #1372 frieren compound-β Arm A near-terminal / #1383 askeladd START_STEP / #1388 edward EPS / #1393 thorfinn MLP-LR sweep just-assigned. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 400 — 1 stale_wip ack on #1356 tanjiro NM period sweep on new stack, **Arm A TERMINAL exceptionally-clean drift, Arm B period=3 RUNNING ~94% near-terminal**). **#1356 chain status** (group `g1r4-tanjiro/nm-period-sweep-new-stack`): A ctrl period=5 `m2i9s3k4` TERMINAL val=**3.26276** fs=**3150** drift **−0.00063 EXCEPTIONALLY-CLEAN-FAVORABLE-COHORT** vs post-#1240 baseline 3.26339 (5× margin within G4 envelope) / **B period=3 `792x4704` RUNNING step 3150/3350 (~94%)** partial val=3.281424 mid-cooldown cycle-354-lesson-applied modal terminal val ∈ [3.265, 3.275] / C period=2 NOT YET LAUNCHED / D period=10 sanity NOT YET LAUNCHED. **🎯 Bit-identical replication of post-#1240 baseline already established**: Arm A is THE post-#1240 baseline config (period=5, MAX_D_IN=4096) — joins today's 4-clean-ctrl drift envelope (#1356 −0.00063 / #1346 +0.00220 / #1360 +0.00091 / #1363 +0.00033). **Cleanest direct period-axis sweep on post-#1240 stack** — #1240's period=5 vs period=10 finding was confounded with coverage; #1356 cleanly disambiguates period axis alone at fixed coverage=4096. **Modal forecast Arm B period=3**: 35% NULL-FAV Δ_B ∈ [−0.001, +0.0005] marginal improvement / 25% mild-FAV Δ_B ∈ [−0.0015, −0.001] monotone-by-period continues / 25% NULL flat (period=5 already optimal) / 10% mild-NEG over-refresh / 5% surprise. **Arms C/D modal**: Arm C period=2 40% NEG over-refresh / 30% NULL / 20% mild-FAV / 10% surprise; Arm D period=10 sanity 50% mild-NEG (validates period=5 > period=10 transition cleanly) / 30% NULL / 20% mild-FAV. **Modal full-chain outcome**: 40% Row 3 productive-NULL period=5 robust optimum / 30% Row 2 marginal-FAV monotone / 20% Row 4/5 NEG-monotone-by-low-period / 10% Row 1 MERGE candidate. ETA Arm B terminal ~minutes, full chain ~3.5h remaining. **Cross-chain mechanism context**: combined with #1346 LR-scale (closed cycle 398, MLP-only headroom) and #1331/#1372 β-schedule mechanism, characterizes whether post-#1240 stack has additional NM-internal mechanism headroom on period/coverage/LR axes. **Cross-chain status cycle-400 (8 chains, 0 idle)**: #1286 fern PP 5/6 terminal s2-C pending NULL-collapse / **#1356 (this) Arm A clean Arm B near-terminal** / #1360 alphonse R-power Arm A PASS Arm B near-terminal ADVERSE / #1363 nezuko diagonal Arm B running / #1372 frieren compound-β Arm A near-terminal / #1383 askeladd START_STEP / #1388 edward EPS / #1393 thorfinn MLP-LR sweep just-assigned. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 399 — 1 stale_wip ack on #1372 frieren NM β-schedule compound retest on post-#1240 stack, **Arm A ctrl `lwi7w7mt` RUNNING step 3075/3350 (~92%) partial val=3.2875 mid-cooldown, terminal in minutes**). **#1372 chain status** (group `g1r4-frieren/nm-beta-schedule-compound`): A ctrl RUNNING ~92% partial val=3.2875 cycle-354-lesson-applied (val can drop 0.005-0.012 in final 275 steps) modal terminal val ∈ [3.262, 3.272] / B COMPOUND β=0.85 @ 2000 PRIMARY NOT YET LAUNCHED / C timing-only β=0.90 @ 2000 NOT YET LAUNCHED / D depth-only β=0.85 @ 2345 NOT YET LAUNCHED. **⚠️ EPS=1e-8 confound noted in ack**: base env sets `NANOGPT_NEWTON_MUON_EPS=1e-8` (PR body) but post-#1240 baseline reproduce does NOT set EPS (uses script default 1e-4 at train_gpt_simple.py:603). Within-chain B/C/D−A paired deltas BIT-IDENTICAL-COMPARABLE under EPS=1e-8, but cross-chain G1 vs 3.26339 NOT directly merge-eligible without either (a) Arm B retest with EPS=1e-4 or (b) waiting on #1388 EPS sweep to confirm 1e-8 at-or-favorable vs 1e-4. **🎯 If Arm B compound shows super-additive Δ ≤ −0.003**: surprise scenario (10% PR-body prior), validates β-schedule axis robust to UPDATE_PERIOD=5 AND compounds with timing/depth winners → direct G1 candidate after EPS retest. **🎯 If Arm B compound shows Δ ≈ component values (Arms C/D)**: saturation scenario (30% prior), period=5 already extracts late-responsiveness, β-schedule axis partially redundant on new stack. Modal terminal Arm A val 40% [3.262, 3.266] PASS-CLEAN / 30% [3.266, 3.270] MARGINAL EPS=1e-8 NULL-effect / 20% [3.270, 3.275] EPS=1e-8 mild-adverse / 10% ≥ 3.275 stronger adverse. ETA Arm A terminal ~minutes, full chain ~6h sequential. **Cross-chain mechanism context**: today's marginal-FAV cohort spans 3 NM axes — #1331 Arm C β=0.85 / **#1346 Arm B MLP-boost (CLOSED productive-MARGINAL cycle 398, 9th NM axis)** / #1372 Arm B compound pending. **Cross-chain status cycle-399 (8 chains, 0 idle)**: #1286 fern PP 5/6 terminal s2-C pending NULL-collapse / #1356 tanjiro period sweep / #1360 alphonse R-power Arm A bit-identity PASS Arm B near-terminal ADVERSE / #1363 nezuko diagonal Arm B running / **#1372 (this) Arm A ~92% near-terminal** / #1383 askeladd START_STEP / #1388 edward EPS / #1393 thorfinn MLP-LR sweep just-assigned. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 398 — **#1346 thorfinn NM per-group LR-scale CLOSED productive-MARGINAL (52nd no-merge, 9th NM mechanism axis closed)** + thorfinn REASSIGNED **#1393 NM MLP-LR fine-grained sweep on post-#1240 stack {1.2, 1.4, 1.6, 1.8}** + 1 stale_wip ack on #1286 fern PP 5/6 terminal s2-A favorable-cohort signature complete). **#1346 chain terminated** 4/4 arms on pre-#1240 stack: A ctrl `hikw4tzr` 3.26558/3175 / **B mlp-boost (1.0, 1.2) `rxkm9jwm` 3.26444/3175 Δ=−0.00114 MARGINAL-FAV** / C mlp-damp (1.0, 0.8) `jgzj5ala` 3.26831/3200 Δ=+0.00273 ADVERSE +25 fs / D attn-boost (1.2, 1.0) `wfsqbt23` 3.26828/3200 Δ=+0.00270 ADVERSE +25 fs. **🎯 Three mechanism findings**: (1) MLP-LR monotone-favorable with asymmetric damping cost — |Δ_C|/|Δ_B|=2.39× damping 2.4× more damaging than boost helps, indicates optimum > 1.2 / (2) Attn-LR ADVERSE on boost → RULES OUT joint headroom hypothesis / (3) Striking symmetry |Δ_C|/|Δ_D|=0.989 — production below MLP optimum and above attn optimum by equivalent amounts. **🎯 Validates #1297 per-matrix MLP-leverage direction** (1.6× MLP leverage). **No merge** under post-#1240 baseline 3.26339 (Arm B +0.00105 over G1 FAIL at n=1, PP attenuation modal ~50% P(MERGE) ~15-20%). Row 5 NEG-D variant (MLP-only headroom, joint ruled out). **Cross-chain convergence — 3 marginal-FAV NM signals today**: #1331 β=0.85 deeper Δ=−0.00142 / #1346 Arm B MLP-boost Δ=−0.00114 / #1372 compound-β in-flight. **9th NM mechanism axis closed productive-MARGINAL**. **thorfinn REASSIGNED #1393 NM MLP-LR fine-grained sweep on post-#1240 stack** (`g1r4-thorfinn/nm-mlp-lr-sweep`): 4-arm sequential A=1.0/B=1.2/C=1.4/D=1.6 testing where MLP-LR optimum peaks on production stack with 12 additional MLP down-proj matrices (d_in=3072, R_cond ~10^6). Direct G1 comparable to new baseline 3.26339 — any arm at val ≤ 3.26339 = direct merge candidate. Phase 0 verifies post-#1240 stack config first. Pre-staged 7-row decision tree. Modal: 40% Row 5 saturation-localized peak / 30% Row 3 productive-MARGINAL / 15% Row 4 monotone (optimum > 1.6) / 10% Row 6 productive-NULL (stack absorbs axis) / 5% Row 1/2 MERGE-eligible. ETA full chain ~7h sequential. **#1286 fern PP 5/6 terminal**: s2-A `g1iuhcu8` TERMINAL val=3.266273 fs=3175 favorable-cohort consistent / s2-C `8fw447mr` RUNNING ~36% pre-LATE_START=2400 (~1200 steps away). **n=3 ctrl envelope mean 3.265996** drift vs OLD baseline −0.000144 PASS-CLEAN with 20× margin. Modal s2-C 50% NULL-band collapse continued / 25% mild-FAV partial recovery / 15% mild-ADV / 10% strong-FAV — Row 3 productive-NULL ~65% MOST LIKELY (late-only coverage dispositively non-productive). 4th PP attenuation pattern (95% collapse) catalog complete regardless. ETA s2-C terminal ~3-3.5h. **Cross-chain status cycle-398 (8 chains, 0 idle)**: #1286 5/6 terminal s2-C pending NULL-collapse / **#1346 (this) CLOSED 52nd no-merge** / #1356 tanjiro period sweep / #1360 alphonse R-power / #1363 nezuko diagonal / #1372 frieren compound-β / #1383 askeladd START_STEP / #1388 edward EPS / **#1393 thorfinn just-assigned**. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 397 — **#1281 edward PP n=3 H2 RESET=2345 CLOSED productive-NULL (51st no-merge)** + edward REASSIGNED **#1388 NM EPS sensitivity sweep on post-#1240 stack, 12th NM mechanism axis when chain closes**). **#1281 chain terminated** 6/6 PP runs on pre-#1240 stack: s0-A `kf70xdzx` 3.264243 / s0-B `pqafib4r` 3.266409 Δ=+0.002166 ADVERSE / s1-A `j4ubgeo6` 3.265288 / s1-B `cdg0o0eg` 3.266908 Δ=+0.001620 mild-ADVERSE / s2-A `jt1lv9b0` 3.265675 / **s2-B `ltmfvkrf` TERMINAL val=3.265469 Δ_s2=−0.000206 NULL-FAV (DIRECTION FLIPS at n=3)**. **🎯 n=3 mean Δ_paired = +0.001193 NULL-band** (within |Δ|≤0.0015): n=2→n=3 reversal collapses prior ADVERSE signal — **4th "cohort-reversal" PP attenuation pattern** added to PP behavior catalog (joins #1240 enhancement / #1286 NULL-collapse / #1318 cohort-absorption). **🎯 6-replication cross-chain RESET=2345 consolidation**: #1281 n=3 + #1338 1-shot + 3 anchor ctrls → mean Δ ~+0.000350 NULL → **RESET=2345 single-shot DISPOSITIVELY FENCED productive-NULL** across r4 launch. **No merge** ctrl mean 3.265742 ≈ OLD baseline 3.26614 within G4, reset mean 3.266935; cross-stack G1 vs post-#1240 baseline 3.26339 confounded. Productive-NULL. **Statistical capstone of H2 directive cluster RESET_STEP axis** — Issue #1261 H2 single-shot/multi-shot/H5 sub-window all dispositively fenced. **edward REASSIGNED #1388 NM EPS sensitivity sweep** (`g1r4-edward/nm-eps-sweep`): tests script-default ε=1e-4 (verified train_gpt_simple.py:603) is near-optimum on post-#1240 stack with ill-conditioned MLP down-proj matrices (R_cond ~10^6). 4-arm post-#1240 chain: A=1e-4 baseline replication ε-default-control / B=1e-6 (less floor → larger preconditioner correction, more aggressive but tail eigenvalues amplify noise) / C=1e-8 (most aggressive, ill-conditioning concern) / D=1e-2 (much higher floor → smaller correction, blunts preconditioner). Phase 0 instructs student to verify baseline EPS first. Virgin axis controlling preconditioning aggressiveness vs numerical stability — orthogonal to all 11 prior NM axes. Modal: 40% Row 3 productive-NULL ε=1e-4 robust optimum / 25% Row 4 monotone-by-ε-low / 20% Row 2 marginal-FAV B=1e-6 ε-lowering / 10% Row 1 / 5% Row 5 ε-too-low NEG. ETA full chain ~7h sequential. **12th NM mechanism axis when chain closes**. **Cross-chain status cycle-397 (8 chains, 0 idle)**: **#1281 (this) CLOSED 51st no-merge** / #1286 fern PP s2 pending NULL-collapse / #1346 thorfinn Arm D attn-boost running / #1356 tanjiro Arm B period=3 running / #1360 alphonse NM R-power Arm A TERMINAL bit-identity gate PASS Arm B near-terminal ADVERSE / #1363 nezuko diagonal Arm B running / #1372 frieren compound-β running / #1383 askeladd H1 START_STEP running / **#1388 edward EPS sweep JUST ASSIGNED**. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 396 — 1 stale_wip ack on #1360 alphonse NM R-power preconditioning sweep, **Arm A α=0.5 ctrl TERMINAL with bit-identity gate PASS, Arm B α=0.333 weaker-exponent near-terminal strongly ADVERSE**). **#1360 chain status** (group `g1r4-alphonse/nm-rpower-sweep`): A α=0.5 ctrl `gedqercc` TERMINAL val=**3.264300** fs=**3150** drift **+0.000910 BIT-IDENTITY GATE PASS** vs post-#1240 baseline 3.26339 (3.3× margin within G4 envelope) — `pow(-self.newton_power)` substitution introduces **no numerical-path divergence** vs `rsqrt()`, unlocks credible interpretation of Arms B/C/D Δ as true α-mechanism signal not implementation noise / **B α=0.333 `fzhgh0lg` RUNNING step 3275/3350 (~98%)** ETA ~3 min partial val=3.270529 partial Δ_B ≈ +0.00623 strongly ADVERSE direction confirmed at near-terminal / C α=0.667 NOT YET LAUNCHED / D α=0.75 NOT YET LAUNCHED. **🎯 4th CLEAN DRIFT ON POST-#1240 STACK TODAY** (Arm A joins #1356 Arm A −0.00063, #1346 Arm A +0.00220, #1363 Arm A +0.00033) — favorable-cohort signature reproducible across 4 independent chain ctrls today, statistically robust drift envelope. **🎯 Mechanism interpretation Arm B**: weaker α=0.333 leaves small R eigenvalues too uncorrected (R^{−α} dynamic range R_cond^0.333 ~ 100 vs canonical R_cond^0.5 ~ 1000 for α=0.5 on post-#1240 stack R_cond ~10^6 MLP matrices), preconditioner insufficiently sharp. **Pending Arms C/D modal**: Arm C α=0.667 35% mild-NEG (over-corrects small eigenvalues amplifies R-buffer noise) / 30% NULL / 25% mild-FAV / 10% strong-FAV; Arm D α=0.75 50% mild-NEG to NEG / 25% NULL / 20% mild-FAV / 5% strong-FAV. **Decision tree pre-staged**: Row 1 any Δ ≤ −0.002 PP-promote n=3 / Row 2 marginal FAV / **Row 3 monotone-α-NEG close productive-NULL α=0.5 robust optimum (modal 50%)** / Row 4 non-monotone (C FAV D NEG → optimum at ~0.6) follow-up finer sweep / Row 5 mixed NULL fence axis. Modal full-chain: 50% Row 3 productive-NULL α=0.5 robust optimum / 25% Row 4 tighter follow-up / 15% Row 2 marginal FAV α=0.667 / 10% Row 1. **9th NM mechanism axis characterized**; R-power orthogonal to today's marginal-FAV signals (#1346 LR-scale, #1331 β-schedule). ETA Arm B terminal ~3 min, full chain ~4-6h. **Cross-chain status cycle-396 (8 chains, 0 idle)**: #1281 s2-B running pre-reset / #1286 s2 pending NULL-collapse / **#1346 thorfinn Arm D attn-boost running ~50%+** / #1356 tanjiro Arm B period=3 running / **#1360 (this) Arm A TERMINAL bit-identity PASS Arm B near-terminal ADVERSE** / #1363 nezuko Arm B DIAG running ~50%+ / #1372 frieren compound-β just-assigned / #1383 askeladd H1 START_STEP just-assigned. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 395 — **#1338 askeladd NM multi-shot RESET CLOSED productive-MARGINAL (50th no-merge)** + askeladd REASSIGNED **#1383 H1 NM step-gated activation timing sweep — directly addresses Issue #1261 H1 directive, 11th NM mechanism axis virgin temporal gate**). **#1338 chain terminated** 4/4 arms on PRE-#1240 stack: A `e71gh1pq` 3.26676/3175 drift +0.00062 PASS / B 1-shot `bbaiv26k` 3.26666/3175 Δ=−0.00010 NULL-noise / **C 2-shot `rhebjf25` 3.26612/3175 Δ=−0.00064 NULL-FAV-noise** / **D 3-shot `axoe38ds` 3.26769/3200 Δ=+0.00093 NULL-ADV-band +25 fs**. **🎯 4-point U-shape: 2-shot optimum, 3-shot destructive**: per-reset Δ 0→1 zero / 1→2 mild-FAV (−0.00054) / 2→3 clear ADVERSE (+0.00157). **Mechanism story** R-staleness window roughly [2345, 2700]; resetting *past* that window destroys load-bearing late-phase R covariance, forces 14-step re-warm at the costliest point. **6th cross-chain RESET=2345 single-shot anchor** added (mean Δ now ~+0.00099 NULL-mild-adverse with 6 datapoints, fence consolidated). Cross-chain convergence with #1319 H5 sub-window middle-segment NEG finding — confirms late-cooldown R-buffer interventions damaging. **No merge** pre-#1240 stack, best Arm C +0.00273 above post-#1240 baseline 3.26339. Row 6 close productive-MARGINAL with mechanism characterization. **askeladd REASSIGNED #1383 H1 NM step-gated activation timing sweep** (`g1r4-askeladd/nm-start-step-sweep`): Issue #1261 H1 directive explicitly requests "NM only after step X" variants — virgin axis distinct from RESET (clears R-buffer) and BETA-schedule (changes EMA decay). Adds `NANOGPT_NEWTON_MUON_START_STEP` env var gating entire NM mechanism on/off by step (default 0=always-on). 4-arm sweep on post-#1240 stack: A START=0 ctrl always-on / B 1500 (skip ~45% early) / C 2000 (skip ~60%, align with #1331 β=2000 timing winner) / D 2400 (skip ~71%, align with NS_COOLDOWN_START_FRAC × 3350 = 2345 cooldown anchor). Tests competing hypotheses: late-only-NM-sufficient (Row 3 simplification ~70% NM compute reduction with no quality loss) vs coverage-essential (Row 4 monotone-NEG R-buffer warm-up necessary, mirrors #1286 fern PP late-only coverage NULL-collapse). Pre-staged 5-row decision tree. Modal: 35% Row 3 simplification / 30% Row 4 monotone-NEG coverage-essential / 20% Row 5 mixed / 10% Row 2 marginal-FAV mid-gate sweet-spot / 5% Row 1 strong-FAV. ETA full chain ~7h sequential. **Cross-chain status cycle-395 (8 chains, 0 idle)**: #1281 edward PP s2-B running ~75% dispositive RESET=2345 fence imminent / #1286 fern PP s2 pending NULL-collapse / **#1338 CLOSED 50th no-merge** / #1346 thorfinn Arm D attn-boost running ~50%+ / #1356 tanjiro period sweep Arm B period=3 running / #1360 alphonse R-power Arm A near-terminal bit-identity gate / #1363 nezuko diagonal Arm B running ~50%+ / #1372 frieren compound-β just-assigned / **#1383 askeladd just-assigned**. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 394 — 1 stale_wip ack on #1281 edward PP n=3 H2 RESET=2345, **5/6 runs terminal, s2-A just terminal favorable-cohort consistent, s2-B `ltmfvkrf` running ~61% pre-reset firing**). **#1281 PP chain status** (group `g1r4-edward/cooldown-entry-r-refresh-pp`): s0-A `kf70xdzx` 3.264243 / s0-B `pqafib4r` 3.266409 Δ=+0.002166 ADVERSE / s1-A `j4ubgeo6` 3.265288 / s1-B `cdg0o0eg` 3.266908 Δ=+0.001620 mild-ADVERSE / **s2-A `jt1lv9b0` TERMINAL val=3.265675 fs=TBD favorable-cohort continues** / s2-B `ltmfvkrf` RUNNING step ~2050/3350 (~61%) reset pending step 2345 ~295 steps away ETA ~1.1h. **🎯 n=3 ctrl cohort tight envelope**: s0-A=3.264243 / s1-A=3.265288 / s2-A=3.265675 → mean 3.265069 drift vs OLD baseline 3.26614=−0.00107 (favorable-cohort) / vs NEW baseline 3.26339=+0.00168 PASS-CLEAN G4 (1.8× margin). All 3 seeds within tight 0.0014 envelope — cohort-favorable signature reproducible across seeds AND chains today. **n=2 paired-pod direction confirmed**: mean Δ=+0.001893 ADVERSE direction-consistent both seeds. **Modal forecast s2-B terminal**: 65% Δ_s2 ∈ [+0.0010, +0.0030] mild-ADVERSE continued n=3 mean ≈ +0.0017 dispositive / 20% NULL-band n=3 mean ≈ +0.0013 still mild-ADVERSE / 10% favorable / 5% strong. **Decision tree resolution at terminal**: Row 5 productive-NEG (P~70%) dispositive fence of RESET=2345 single-shot as mild-ADVERSE under cohort interactions on pre-#1240 stack / Row 4 productive-NULL (P~25%). **Closure context**: 4th PP attenuation pattern catalog (joins #1240 enhancement / #1286 NULL-collapse / #1318 cohort-absorption — this completes "cohort-reversal" pattern), statistical capstone for H2 directive cluster RESET_STEP axis, combined with #1338 Arm B / #1318 Arm B already-established 5-rep cross-chain consolidation (cycle 386 mean Δ=+0.001063). ETA terminal ~1.1h. **Cross-chain status cycle-394 (8 chains, 0 idle)**: **#1281 (this) 5/6 terminal s2-B ~61% P~0% direct merge / dispositive NEG fence imminent** / #1286 4/6 NULL-collapse P~0% / #1338 3/4 monotone-FAV Arm D running / #1346 3/4 monotone Arm D running / #1356 Arm B period=3 running / #1360 Arm A near-terminal bit-identity gate / #1363 Arm B DIAG-ONLY running ~16% / #1372 frieren compound-β just-assigned. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 393 — 1 stale_wip ack on #1363 nezuko NM diagonal preconditioning ablation, **Arm A FULL-R UP=5 ctrl TERMINAL exceptionally-clean drift, Arm B DIAG-ONLY UP=5 just launched post-branch-recovery, 10th NM mechanism axis structural ablation chain active**). **#1363 chain status** (group `g1r4-nezuko/nm-diagonal-ablation`): branch recovery handled (initial commit `756b616c` lost to entrypoint reset, Arm A `lfa0hjlp` unaffected via in-memory source, killed Arm B `616alz9u` ignored — re-implementation pushed cleanly). Arm A FULL-R ctrl `lfa0hjlp` TERMINAL val=**3.263724** fs=**3150** drift **+0.000334 EXCEPTIONALLY CLEAN** vs post-#1240 baseline 3.26339 (9× margin within G4 ±0.003 envelope). **🎯 3rd clean drift on post-#1240 stack today** (joins #1356 Arm A −0.00063, today's cycle ctrl envelope spans −0.00063 to +0.002195, favorable-cohort signature continues). Arm B DIAG-ONLY UP=5 `6bpz5f0d` (DIAGONAL=1, UP=5 verified ✓) RUNNING step 525/3350 (~16%) ETA ~1.5h / C DIAG-ONLY UP=1 NOT YET LAUNCHED / D DIAG-ONLY UP=3 NOT YET LAUNCHED. **Hypothesis tests**: B vs A direct (DIAG-ONLY UP=5 vs FULL-R UP=5) — if Δ_B ≈ 0 NULL-band MAJOR SIMPLIFICATION RESULT (diagonal preconditioning suffices, off-diagonals not essential, enables cheap UP=1 deployment) / if Δ_B ≥ +0.0015 NEG off-diagonals essential STRENGTHENS NM-full story / if Δ_B ≤ −0.0015 FAV surprise simplification + speedup. **Modal**: 50% B NULL simplification, 30% B mild-NEG off-diagonals essential, 15% B strong-NEG, 5% surprise FAV. **10th NM mechanism axis (virgin structural)** — Schmidhuber-style "old idea revival" comparing AdaGrad/RMSProp/Adam diagonal vs K-FAC/Shampoo/Newton full preconditioning lineages. ETA full chain ~5.5h sequential. **Cross-chain status cycle-393 (8 chains, 0 idle)**: #1281 4/6 ADVERSE P~0% / #1286 4/6 NULL-collapse P~0% / #1338 3/4 monotone-FAV Arm D running / #1346 3/4 monotone Arm D running ~28%+ / #1356 Arm B period=3 running ~few% / #1360 Arm A near-terminal bit-identity gate / **#1363 (this) Arm A TERMINAL clean drift Arm B just-launched P~25-30%** / #1372 frieren compound-β just-assigned. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 392 — 1 stale_wip ack on #1346 thorfinn NM per-group LR-scale, **3/4 arms terminal, 🎯 Arm C MLP-damp ADVERSE confirms strong MONOTONE-BY-MLP-LR PATTERN with asymmetric damping cost**). **#1346 chain status** (group `g1r4-thorfinn/nm-per-group-lr-scale`): Arm A ctrl `hikw4tzr` TERMINAL val=3.265585 fs=3175 / Arm B mlp-boost (1.0, 1.2) `rxkm9jwm` TERMINAL val=3.264444 fs=3175 Δ_paired=−0.001141 MARGINAL-FAV / **Arm C mlp-damp (1.0, 0.8) `jgzj5ala` TERMINAL val=3.268307 fs=3200 Δ_paired=+0.002722 ADVERSE +25 fs penalty** / Arm D attn-boost (1.2, 1.0) `wfsqbt23` RUNNING step ~925/3350 (~28%) ETA ~1.5h. **🎯 MONOTONE-BY-MLP-LR PATTERN ASYMMETRIC**: damp(0.8)=+0.002722 → ctrl(1.0)=0 → boost(1.2)=−0.001141. Direction monotone-favorable; **damping costs 2.4× boosting gains** (Δ_C/Δ_B = +0.002722/(−0.001141) = −2.4). Triangulates MLP-LR optimum > 1.2 (asymmetric cost means we're operating below optimum, boosting helps somewhat, damping starves preconditioned step magnitude). **Mechanism story**: 12 MLP down-proj matrices (d_in=3072 R_cond ~10^6) added by #1240 coverage extension had insufficient LR per matrix at ctrl; #1297 per-matrix damage skew (MLP +0.000195/matrix vs attn +0.000120/matrix) directly explains why this axis has so much sensitivity. **Decision tree branching on Arm D**: Row 3 PRIMARY scenario (joint headroom Arm D Δ ≈ −0.0005 to −0.0015 FAV) → highest-EV follow-up = COMBO LR_SCALE_ATTN=1.2 + LR_SCALE_MLP=1.2 simultaneously, super-additive ~Δ ≈ −0.002+ G1-eligible at n=3 PP / Row 5 NULL D → MLP-only headroom, follow-up MLP-LR sweep 1.2/1.4/1.6/1.8 / Row 5 NEG D → attn-NM at/above optimum, MLP-LR sweep only path. **Modal**: 55% NULL Arm D (MLP-leverage axis dominates), 20% mild-FAV joint-headroom, 15% mild-NEG, 10% NEG. **3rd ADVERSE-confirmed treatment in r4 launch** (Arm C joins #1281 PP s0-B reversal, #1297 attn/mlp ablation NEG arms) — validates mechanism findings on post-#1240 stack have real direction. **Cross-chain status cycle-392 (8 chains, 0 idle)**: #1281 4/6 terminal n=2 ADVERSE P~0% / #1286 4/6 terminal NULL-collapse P~0% / #1338 3/4 monotone-FAV-direction Arm D running ~50%+ / **#1346 (this) 3/4 terminal Arm C ADVERSE confirms monotone Arm D pending P~15-20%** / #1356 Arm A TERMINAL clean Arm B period=3 running / #1360 Arm A near-terminal / #1363 ~30% / #1372 frieren compound-β just-assigned. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 391 — 1 stale_wip ack on #1356 tanjiro NM period sweep, **post-GPU-contention-cleanup restart confirmed, Arm A ctrl TERMINAL exceptional-clean baseline replication, Arm B period=3 just launched**). **#1356 chain status** (group `g1r4-tanjiro/nm-period-sweep-new-stack`): 4 orphan runs ignored (`lorkjsij`/`678mj86x`/`6tq29ldr`/`gp2rr4cl` killed by student in recovery action at 01:03 UTC), clean restart sequence: A `m2i9s3k4` TERMINAL val=3.26276 fs=3150 drift **−0.00063 EXCEPTIONALLY-CLEAN-FAVORABLE-COHORT** vs post-#1240 baseline 3.26339 (5× margin within G4 ±0.003 envelope) / B period=3 `792x4704` RUNNING step ~1/3350 just launched at 03:10 UTC ETA ~2h / C period=2 NOT YET LAUNCHED / D period=10 sanity NOT YET LAUNCHED. **🎯 FIRST TRUE BIT-IDENTICAL POST-#1240 BASELINE REPLICATION**: Arm A is period=5 (the new baseline config itself), so this serves as the cleanest drift envelope test for the post-#1240 stack — −0.00063 favorable confirms today's favorable-cohort signature continues on the new stack (joins #1318 / #1346 / #1286 cycle ctrl drift envelope). **Cross-chain mechanism context**: this chain tests if period axis improvement continues past period=5 OR period=5 already extracts the optimum (cycle 377 #1240 merger established period=5 > period=10 confounded with coverage; #1356 cleanly disambiguates period axis alone). **Modal forecast**: Arm B period=3 35% NULL-FAV-noise Δ ∈ [−0.001, +0.0005] / 25% mild-FAV Δ ∈ [−0.0015, −0.001] continuous improvement (Row 2 candidate) / 25% NULL flat / 15% NEG over-refresh; Arm C period=2 40% NEG over-refresh damages R-buffer EMA / 30% NULL / 20% mild-FAV / 10% surprise strong-FAV; Arm D period=10 50% NEG (Δ ∈ [+0.001, +0.002] confirming period=5 > period=10 transition) / 30% NULL / 20% mild-FAV (would invalidate period mechanism story). ETA full chain ~6h sequential. **Cross-chain status cycle-391 (8 chains, 0 idle)**: #1281 4/6 terminal n=2 ADVERSE P~0% / #1286 4/6 terminal NULL-collapse P~0% / #1338 3/4 monotone-FAV-direction Arm D running ~50%+ / #1346 Arm B MARGINAL-FAV Arm C running / **#1356 (this) Arm A TERMINAL exceptional-clean Arm B just-launched P~25-30%** / #1360 Arm A near-terminal bit-identity gate pending / #1363 ~30% / #1372 frieren compound-β just-assigned P~25-30%. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 390 — **#1331 frieren NM β-schedule CLOSED productive-MARGINAL (49th no-merge)** + frieren REASSIGNED **#1372 NM β-schedule compound retest on post-#1240 stack**, **highest-EV follow-up combining depth-winner + timing-winner at maximum-mechanism point**). **#1331 chain terminated** 4/4 arms on PRE-#1240 stack: A ctrl `95n2u3ff` val=3.26737 fs=3200 / B β=0.90 @ 2345 `fh5mj1pe` val=3.26659 fs=3175 Δ=−0.00078 NULL-FAV-noise / C β=0.85 @ 2345 `g282e5fm` val=3.26595 fs=3175 Δ=−0.00142 MARGINAL-FAV (depth-axis winner) / **D β=0.90 @ 2000 `pxbx6d90` val=3.26535 fs=3175 Δ=−0.00202 MARGINAL-FAV strongest (timing-axis winner)**. **🎯 Two-axis monotone characterization**: depth axis at fixed timing=2345 (B→C: Δ scales −0.00078 → −0.00142, ~1.8×); timing axis at fixed depth=0.90 (B→D: Δ moves from −0.00078 to −0.00202, ~2.6×). **Timing axis dominates depth** at fixed-shallow-depth. R_inv_sqrt_norm telemetry coherence monotone 81.49 → 80.36 → 79.42 → 79.41 confirms mechanism direction. **No merge** under post-#1240 baseline (best Arm D val=3.26535 = +0.00196 over 3.26339 G1 fails wide). Arm D marginally triggers Row 1 against PRE-#1240 baseline 3.26614 (−0.00079 under) but chain-stack mismatch invalidates direct merge. **🎯 Compound point β=0.85 @ 2000 UNTESTED in #1331** — natural maximum-mechanism point combining both axis-winners. **frieren REASSIGNED #1372 NM β-schedule compound retest** (`g1r4-frieren/nm-beta-schedule-compound`): 4-arm chain on post-#1240 production stack (UPDATE_PERIOD=5, MAX_D_IN=4096) — A ctrl baseline reference / **B COMPOUND β=0.85 @ 2000 PRIMARY** (depth-winner + timing-winner) / C timing-only β=0.90 @ 2000 (replicate #1331 Arm D under new stack) / D depth-only β=0.85 @ 2345 (replicate #1331 Arm C under new stack). Tests 3 hypotheses simultaneously: (1) does β-schedule mechanism persist when R-buffer is 2× more responsive? (2) does compound super-additivity emerge? (3) which axis dominates on new stack? Pre-staged 5-row decision tree: Row 1 Δ_B ≤ −0.002 val ≤ 3.26339 fs ≤ 3175 → PP-promote n=3 / Row 2 Δ_B ∈ [−0.002, −0.001] → PP-promote with caveat / Row 3 Δ_B comparable to component arms → close productive-MARGINAL saturation / Row 4 all NULL/NEG → close productive-NULL stack-dependence / Row 5 surprise Δ_B ≤ −0.003 → high-P(MERGE). Pre-staged exact-command template with all env vars. Modal scenarios: 40% Row 2 marginal-FAV / 30% Row 3 saturation / 20% Row 4 attenuation / 10% Row 5 super-additive. ETA full chain ~7h sequential. **Cross-chain status cycle-390 (8 chains, 0 idle)**: #1281 4/6 terminal P~0% / #1286 4/6 terminal NULL-collapse P~0% / **#1331 (this) CLOSED 49th no-merge** / #1338 3/4 monotone-FAV-direction Arm D running / #1346 Arm B MARGINAL-FAV Arm C running / #1356 Arm A running / #1360 Arm A near-terminal / #1363 ~25% / **#1372 frieren JUST ASSIGNED P~25-30%**. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 389 — 1 stale_wip ack on #1286 fern PP n=3 H4 LATE-coverage chain, **4/6 runs terminal s1-C just terminated val=3.265921 Δ_paired=+0.000528 ADVERSE-NULL-band REVERSES s0's favorable** + **🎯 95% PP attenuation = 4th documented PP behavior pattern (NEW: collapse-to-NULL)** + **🎯 late-vs-always-on coverage mechanism dissociation finding**). **#1286 chain status** (group `g1r4-fern/h4-late-coverage-pp`): s0-A `qzuvy6wa` TERMINAL val=3.266322 fs=3175 / s0-C `957t6w8u` TERMINAL val=3.265627 fs=3175 Δ=−0.000695 NULL-FAV-band / s1-A `9it76841` TERMINAL val=3.265393 fs=3175 / **s1-C `bkl9s3yi` TERMINAL val=3.265921 fs=3175 Δ=+0.000528 NULL-ADVERSE-band REVERSAL** / s2-A `g1iuhcu8` RUNNING step 675/3350 (~20%) / s2-C NOT YET LAUNCHED. **n=2 paired-pod consolidation**: Δ_s0=−0.000695 / Δ_s1=+0.000528 → mean Δ_paired=**−0.0000835 essentially zero**, direction-inconsistent across seeds, near-symmetric magnitudes ~±0.0006 → variance dominates mean. **🎯 4th DOCUMENTED PP ATTENUATION PATTERN — NEW: collapse-to-NULL (95% attenuation from screening Δ=−0.00188)**: PP behavior catalog now spans enhancement → collapse — #1240 PP enhancement (−35% becomes stronger) cleanest preservation MERGED / #1281 PP reversal (−183%) cohort-reversal / **#1286 PP collapse (95%) signal-vanishing** / #1318 cohort-absorption (single-seed). Today's overall cohort-favorable signature applies to BOTH ctrl AND treatment within-seed, paired delta noise dominates at NULL-band mechanism magnitudes. **🎯 CROSS-CHAIN LATE-VS-ALWAYS-ON COVERAGE MECHANISM DISSOCIATION**: this chain's NULL-collapse on LATE-ONLY coverage (after step 2400) contrasts sharply with #1240 PP's strong signal on ALWAYS-ON coverage (entire training). **Mechanism interpretation**: coverage gain accrues across pre-step-2400 (~71%) — 12 additional MLP down-proj matrices (d_in=3072) need R-buffers populated EARLY to develop coherent preconditioning statistics; activating at step 2400 gives insufficient R-buffer mass to be useful at late stages. **High-information productive-NULL** about WHERE in training coverage mechanism is load-bearing — directly informs future mechanism design (no "late-window-only X" axis on coverage-class mechanisms). **⚠️ Chain on PRE-#1240 stack**. Under OLD baseline 3.26614: n=2 mean val_C 3.265774 = −0.000366 PASS-CLEAN G1 at n=2; n=3 mean projection 3.2655 likely PASS-MARGINAL G1 if s2-C lucky → P(MERGE) OLD baseline ~15-20%, NEW baseline ~0%. **Modal forecast s2-C**: 50% NULL Δ_s2 ∈ [−0.0005, +0.0005] / 30% mild-FAV / 20% mild-ADVERSE. **Modal full-chain Row 3 productive-NULL** (65%) late-only coverage axis dispositively fenced as no-mechanism-signal. ETA full chain ~5h. **Cross-chain status cycle-389 (8 chains, 0 idle)**: #1281 4/6 P~0% / **#1286 (this) 4/6 NULL-collapse + dissociation finding P~0% direct** / #1331 Arm C MARGINAL-FAV Arm D ~50% / #1338 3/4 monotone-FAV-direction Arm D ~25% / #1346 Arm B MARGINAL-FAV C ~30% / #1356 Arm A ~40% / #1360 Arm A near-terminal / #1363 ~20%. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 388 — 1 stale_wip ack on #1338 askeladd NM multi-shot RESET chain, **3/4 arms terminal Arm C 2-shot just terminated val=3.266116 Δ_paired=−0.000641 NULL-band-FAV-noise** + **🎯 MONOTONE-BY-FREQUENCY pattern emerging A→B→C (0→1→2 resets: Δ scales linearly at ~−0.0005 per additional reset)**). **#1338 chain status** (group `g1r4-askeladd/nm-multi-shot-reset`): A ctrl `e71gh1pq` TERMINAL val=3.266757 fs=3175 / B 1-shot RESET=2345 `bbaiv26k` TERMINAL val=3.266663 fs=3175 Δ=−0.000094 NULL-noise / **C 2-shot RESET_STEPS=2345,2700 `rhebjf25` TERMINAL val=3.266116 fs=3175 Δ=−0.000641 NULL-FAV-noise telemetry last_reset=2700 total_resets=2 ✓** / D 3-shot `axoe38ds` RUNNING step 700/3350 (~21%) pre-first-reset. **Slope analysis**: B−A=−0.000094 (minimal from 2345 single-shot at cooldown_start anchor) / C−B=−0.000547 (substantial from adding reset at 2700) → per-additional-reset contribution ~−0.0005 favorable, R-buffer continuous-freshness hypothesis partially validated. **⚠️ Partially reverses cycle 381 "RESET dispositively NULL" interpretation** for SINGLE-shot only — 5-replication cross-chain consolidation still holds (5-rep mean Δ=+0.001063 mild-adverse), but multi-shot shows continuous-favorable direction at NULL-band magnitudes. Mechanistically: more frequent reset tracks distribution shift more responsively, single 2345 reset has minimal benefit because it's already at cooldown_start where R-buffer is mid-shift. **Modal forecast Arm D 3-shot (2345,2600,2900)**: 35% continued monotone-FAV Δ_D ∈ [−0.001, −0.0015] **Row 2/3 marginal-FAV signal** validates continuous R-buffer freshness across 4 datapoints / 30% saturation at Δ_C level Row 3 productive-MARGINAL diminishing returns / 20% reversal NEG ≥+0.001 over-resetting Row 5 productive-NEG / 15% strong-FAV ≤−0.0015 super-additive Row 2 marginal-FAV PP. **Cross-chain mechanism context — 3rd partial-FAV direction signal today**: #1346 Arm B per-group LR-scale MLP-boost Δ=−0.001141 (post-#1240 stack) / #1331 Arm C β-step-down deeper Δ=−0.001413 (pre-#1240) / **#1338 (this) Arm C multi-shot 2-shot Δ=−0.000641 NULL-band monotone-direction (pre-#1240)**. All independent NM mechanism axes (LR-scale × β-schedule × reset-frequency) — could compound in future combined-axes chain. **⚠️ Chain on PRE-#1240 stack** (launched before cycle 377). Within-chain valid; cross-chain G1 vs post-#1240 baseline 3.26339 NOT apples-to-apples. **G1 OLD baseline analysis**: Arm C val=3.266116 = −0.000024 essentially AT OLD baseline (marginal-PASS at N=1, within seed-variance not statistically meaningful). **Highest-EV follow-up chains if Arm D continues monotone**: (1) dense-reset frequency sweep n=4 (4-shot every 250 / 5-shot every 200 / 6-shot every 150 / 8-shot every 125) on post-#1240 stack — tests where monotone-FAV trend saturates / (2) joint reset+coverage chain combining dense-reset with #1240 MAX_D_IN=4096 stacking. ETA Arm D terminal ~3.5h. **Cross-chain status cycle-388 (8 chains, 0 idle)**: #1281 4/6 P~0% / #1286 P~5% / #1331 Arm C MARGINAL-FAV Arm D ~45% / **#1338 (this) 3/4 terminal monotone-FAV-direction P~10% follow-up high-EV** / #1346 Arm B MARGINAL-FAV P~15-20% / #1356 P~25% / #1360 Arm A near-terminal P~30% / #1363 P~30%. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 387 — 1 stale_wip ack on #1360 alphonse NM R-power preconditioning sweep chain, **first comment on this PR — Arm A α=0.5 ctrl `gedqercc` RUNNING step 3250/3350 (~97%) near-terminal, fs=3150 secured matching post-#1240 baseline ✓, bit-identity gate pending terminal**). **#1360 chain status** (group `g1r4-alphonse/nm-rpower-sweep`): A α=0.5 ctrl `gedqercc` RUNNING step 3250/3350 partial val=3.2700 NM telemetry healthy (R_inv_sqrt_norm_mean=80.93 in today's ctrl envelope, R_cond_mean=953K, params_preconditioned=72 post-#1240 stack ✓), fs already secured at 3150 / B α=0.333 weaker / C α=0.667 stronger / D α=0.75 strongest all NOT YET LAUNCHED. **Clean implementation execution** (student commit): single-line eigendecomp change `vals_clamped.pow(-self.newton_power)` replacing `.rsqrt()` + env-var plumbing + ctor arg. **🎯 Bit-identity gate at Arm A terminal is critical**: α=0.5 via `pow(-0.5)` should be numerically equivalent to `.rsqrt()` within 1 ULP. Expected |Arm A val − post-#1240 baseline 3.26339| ≤ 0.003 G4 drift envelope → bit-identity preserved. If drift > ±0.003, indicates implementation change introduced numerical-path divergence requiring `torch.pow` vs `torch.rsqrt` reconciliation BEFORE launching α≠0.5 arms (any α-signal could otherwise be confounded by the impl change). **N=1 cycle 354 lesson applied**: no terminal forecast from partial val=3.2700, can drop 0.005-0.010 in final 100 steps cooldown. Modal terminal forecast Arm A val ∈ [3.262, 3.268]. **Cross-chain mechanism context**: 2 marginal-FAV signals already today on independent axes (#1346 Arm B per-group LR-scale Δ=−0.001141 / #1331 Arm C β-step-down deeper Δ=−0.001413 pre-#1240 stack). R-power is **orthogonal** to both — tests magnitude of correction not when/where. **Modal forecast Arms B/C/D**: Arm B α=0.333 40% NULL / 30% mild-FAV / 20% mild-NEG / 10% strong-NEG; Arm C α=0.667 35% mild-NEG / 30% NULL / 25% mild-FAV / 10% strong-FAV; Arm D α=0.75 50% mild-NEG to NEG / 25% NULL / 20% mild-FAV / 5% strong-FAV. **Modal full-chain outcome**: 40% Row 4 productive-NULL α=0.5 robust optimum / 30% Row 3 monotone-trend tighter follow-up / 20% Row 2 marginal-FAV PP / 10% Row 1 strong-FAV. ETA Arm A terminal ~5-7 min, full chain ~7h sequential. **Cross-chain status cycle-387 (8 chains, 0 idle)**: #1281 edward PP 4/6 terminal n=2 ADVERSE P~0% / #1286 fern PP s1-C ~30% s2 pending P~5% / #1331 frieren Arm C MARGINAL-FAV Arm D ~40% P~5% direct / #1338 askeladd Arm C ~30% D pending P~10% / #1346 thorfinn Arm B MARGINAL-FAV C ~22% D pending P~15-20% / #1356 tanjiro Arm A ~32% P~25% / **#1360 (this) Arm A ~97% near-terminal B/C/D pending P~30%** / #1363 nezuko NM diagonal ~10% P~30%. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 386 — 1 stale_wip ack on #1281 edward PP n=3 H2 RESET=2345 chain, **4/6 runs terminal s1-B just terminated**, n=2 paired-pod consolidation across both seeds + **🎯 5-replication cross-chain RESET=2345 dispositive NULL-to-mild-ADVERSE finding**). **#1281 PP chain status** (group `g1r4-edward/cooldown-entry-r-refresh-pp`): s0-A `kf70xdzx` TERMINAL val=3.264243 fs=3150 / s0-B `pqafib4r` TERMINAL val=3.266409 fs=3175 Δ=+0.002166 ADVERSE / s1-A `j4ubgeo6` TERMINAL val=3.265288 fs=3175 / **s1-B `cdg0o0eg` TERMINAL val=3.266908 fs=3175 Δ=+0.001620 mild-ADVERSE** / s2-A `jt1lv9b0` RUNNING step 1675/3350 (~50%) / s2-B NOT YET LAUNCHED. **n=2 paired-pod consolidation**: mean Δ_paired_val=+0.001893 mild-ADVERSE direction confirmed across BOTH seeds; mean val_A=3.264766 favorable-cohort drift −0.001374 vs OLD baseline 3.26614; mean val_B=3.266659 lands AT old baseline (+0.000519 NULL). **Telemetry definitively resolved**: `steps_since_reset=1005` at terminal step=3350 → reset fired exactly at step 2345 ✓ on both s0-B and s1-B; `reset_triggered=0` in W&B summary is latest-value-overwrites-historical-max logging artifact (cycle 374 verification holds). **🎯 5-REPLICATION CROSS-CHAIN RESET=2345 CONSOLIDATION**: #1281 screening N=1 Δ=−0.00226 favorable-noise (only fav) / #1281 PP s0-B Δ=+0.002166 ADVERSE / #1281 PP s1-B (NEW) Δ=+0.001620 mild-ADVERSE / #1318 Arm B Δ=+0.000876 NULL / #1338 Arm B Δ=−0.000094 NULL-noise → **5-rep mean Δ_paired=+0.001063 mild-adverse-NULL band**, variance ~0.00185 across N=1 replications dispositively characterizes RESET_STEP=2345 single-shot axis as **NULL-to-mild-ADVERSE**, original screening was favorable-noise. **⚠️ Chain on PRE-#1240 stack** (launched cycle 366 before #1240 merged cycle 377). Within-chain paired deltas bit-identical-comparable; cross-chain G1 against post-#1240 baseline NOT apples-to-apples. **G1 OLD baseline analysis**: n=2 mean val_B +0.000519 above 3.26614 NULL-band fail, n=3 cushion needed s2-B ≤ 3.258761 essentially impossible → P(MERGE) under OLD baseline ~0%, under NEW baseline 0% regardless. **Modal forecast s2 pair**: 65% Δ_s2 ∈ [+0.001, +0.003] mild-ADVERSE continued / 25% NULL-band / 10% reversal Δ < −0.001 (still net adverse). **Decision tree resolution most likely Row 4 productive-NULL** (n=3 mean Δ ∈ [+0.0010, +0.0020] mild-adverse direction confirmed), borderline Row 5 productive-ADVERSE (mean Δ ≥ +0.002). **Recommendation**: continue full chain for statistically-defensible n=3 verdict + 4th documented PP behavior pattern (joins #1240 4% attenuation, #1286 37% retention, #1318 cohort-absorption). ETA full chain ~3h. **Cross-chain status cycle-386 (8 chains, 0 idle)**: **#1281 (this) 4/6 terminal n=2 ADVERSE-direction P~0%** / #1286 fern PP s1-C ~25% s2 pending P~5% / #1331 frieren Arm C MARGINAL-FAV deeper-step-down Arm D ~35% P~5% direct follow-up high-EV / #1338 askeladd Arm C ~25% D pending P~10% / #1346 thorfinn Arm B MARGINAL-FAV C ~18% D pending P~15-20% / #1356 tanjiro Arm A ~28% P~25% / #1360 alphonse NM R-power ~15% P~30% / #1363 nezuko NM diagonal ~7% P~30%. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 385 — 1 stale_wip ack on #1331 frieren NM β-schedule chain, **3/4 arms terminal, 🎯 Arm C deeper β step-down (0.95→0.85 @ 2345) Δ_paired=−0.001413 MARGINAL-FAV 1.8× stronger than Arm B, monotone-by-depth pattern + R_inv_sqrt_norm telemetry coherence validates β-step-down mechanism direction**). **#1331 chain status** (group `g1r4-frieren/nm-beta-schedule`): A ctrl `95n2u3ff` TERMINAL val=3.267367 fs=3200 R_inv_sqrt_norm_mean=81.49 / B step-down moderate (0.90 @ 2345) `fh5mj1pe` TERMINAL val=3.266591 fs=3175 Δ=−0.000776 NULL-FAV-noise R_inv_sqrt=80.36 (−1.4%) / **C step-down deeper (0.85 @ 2345) `g282e5fm` TERMINAL val=3.265954 fs=3175 Δ_paired=−0.001413 MARGINAL-FAV R_inv_sqrt=79.42 (−2.5%)** / D step-down early (0.90 @ 2000) `pxbx6d90` RUNNING step 1125/3350 (~34%) pre-drop β=0.95. **🎯 MONOTONE-BY-DEPTH AT FIXED TIMING**: Δ_B (β=0.90) −0.000776 → Δ_C (β=0.85) −0.001413 (1.8× scaling) with R_inv_sqrt_norm coherently scaling (81.49 → 80.36 → 79.42 monotone). Mechanism direction confirmed: lower β_late → smaller R_inv_sqrt_norm → more responsive late-training preconditioning, consistent with #1288 telemetry observation. **🎯 SECOND MARGINAL-FAV SIGNAL TODAY** alongside #1346 Arm B MLP-boost Δ=−0.001141 — first two independent chain-internal favorable signals post-#1240. **⚠️ CRITICAL — chain ran on PRE-#1240 stack** (launched cycle 371 before #1240 merged cycle 377): production stack at launch was period=10, max_d_in=1024. Arm A drift vs OLD baseline 3.26614 = +0.001227 PASS-CLEAN; vs NEW baseline 3.26339 = +0.003977 marginally FAILS G4 envelope. **Within-chain paired deltas bit-identical-comparable**; cross-chain G1/G4 vs post-#1240 baseline NOT apples-to-apples → mechanism direction validation only, not direct merge candidate. **Modal forecast Arm D (β=0.90 @ 2000)** tests timing axis at fixed depth=0.90: 40% timing-irrelevant Δ_D ≈ Δ_B / **30% early-pre-adapt favorable Δ_D < −0.0010 PRIMARY ROW 4 trigger** → highest-EV scenario justifying post-#1240-stack follow-up combining deeper+earlier (β=0.95→0.85 @ 2000) / 20% early unfavorable / 10% NEG. **Decision tree state**: Row 2 (marginal Δ ∈ [−0.002, −0.001]) currently triggered by Arm C; Row 4 PENDING Arm D. **Highest-EV next experiment from chain findings if Arm D favorable**: post-#1240-stack retest combining deeper-step-down + earlier-timing β=0.95→0.85 @ 2000 — period=5 already 2× responsive, could compound to Δ ≈ −0.002+ G1-eligible. ETA Arm D terminal ~2.5h. **Cross-chain status cycle-385 (8 chains, 0 idle)**: #1281 edward PP s1-B ~60-65% P~5% / #1286 fern PP s1-C ~20% s2 pending P~5-10% / **#1331 (this) 3/4 terminal Arm C MARGINAL-FAV deeper-step-down** / #1338 askeladd Arm C ~20% D pending P~10% / #1346 thorfinn Arm B MARGINAL-FAV C ~17% D pending P~15-20% / #1356 tanjiro Arm A ~25% P~25% / #1360 alphonse NM R-power ~12% P~30% / #1363 nezuko NM diagonal ~5% P~30%. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 384 — 1 stale_wip ack on #1346 thorfinn NM per-group LR-scale chain, **2/4 arms terminal Arm B MLP-boost (LR_SCALE_MLP=1.2) Δ_paired=−0.001141 MARGINAL-FAV — cleanest paired-favorable signal post-#1240**). **#1346 chain status** (group `g1r4-thorfinn/nm-per-group-lr-scale`): Arm A ctrl `hikw4tzr` TERMINAL val=3.265585 fs=3175 drift +0.002195 PASS-CLEAN (1.4× margin, slightly less clean than today's other ctrls) / **Arm B MLP-boost (1.0, 1.2) `rxkm9jwm` TERMINAL val=3.264444 fs=3175 Δ_paired_val=−0.001141 MARGINAL-FAV decision tree row 2 PP-promote candidate** / Arm C MLP-damp (1.0, 0.8) `jgzj5ala` RUNNING step ~425/3350 (~13%) val=3.897 early-warmup / Arm D attn-boost (1.2, 1.0) NOT-STARTED. **🎯 Arm B MLP-boost validates #1297 finding direction**: Δ=−0.001141 directly tests #1297's per-matrix damage skew finding (MLP +0.000195/matrix vs attn +0.000120/matrix → MLP per-matrix leverage 1.6× higher). Consistent with **MLP NM having ~20% LR headroom on post-#1240 production stack** — expanded coverage (12 new MLP down-proj matrices d_in=3072, R_cond ~10^6) had insufficient LR per matrix. Beats #1297 Arm B attn-only (Δ=+0.00468) and Arm C mlp-only (Δ=+0.00578) which measured layer-group ablation; this measures within-group LR scaling. **G1 evaluation under post-#1240 baseline 3.26339**: Arm B val 3.264444 = +0.001054 over baseline → **G1 FAIL at n=1**, PP attenuation modal ~50% on this delta size → PP n=3 mean Δ ≈ −0.0006, mean val ≈ 3.265 → G1 FAIL more likely than not. **P(MERGE) at n=3 PP escalation ~15-20%** marginal band, would need favorable cohort. **Modal forecast Arm C MLP-damp**: 65% NEG-monotone-direction-validation (Δ_C ≥ +0.0010 confirms MLP-leverage hypothesis monotonically) / 20% mild-NEG NULL-band Δ_C ∈ [+0.0005, +0.0010] partial-asymmetric / 10% NULL flat / 5% surprise-FAV. **Modal forecast Arm D attn-boost**: 55% NULL Δ_D ∈ [−0.0005, +0.0005] confirms #1297 attn LR-scale flat / 20% mild-NEG over-LR'd / 15% mild-FAV joint-headroom signal **interesting follow-up** / 10% NEG. **Decision tree pre-staged**: Row 1 (strong signal) NOT TRIGGERED / **Row 2 (marginal Δ ∈ [−0.002, −0.001]): Arm B currently here at −0.001141 PP-promote candidate** if C/D pattern confirms / **Row 3 (B + D both favorable joint-headroom): MOST PROMISING SCENARIO** — would justify follow-up COMBO chain (LR_SCALE_ATTN=1.2 + LR_SCALE_MLP=1.2 simultaneously, untested combination, potentially super-additive ~0.002 → G1-eligible at n=3 PP) / Row 5 productive-NULL most likely (Arm B alone sub-threshold marginal-FAV mechanism direction confirmed). **Recommendation**: continue chain to completion, Arm D launch decision: yes, run after Arm C terminal. Arm D critical for disambiguating (a) MLP-only LR-leverage axis vs (b) joint per-group LR-headroom both under-LR'd. ETA Arm C terminal ~1.5h, Arm D ~1.5h after C → full chain ~3-4h. **Cross-chain status cycle-384 (8 chains, 0 idle)**: #1281 edward PP s1-B ~55-60% P~5% / #1286 fern PP s1-C ~17% s2 pending P~5-10% / #1331 frieren Arm C ~42% / #1338 askeladd Arm C ~17% D pending P~10% / **#1346 thorfinn (this) 2/4 terminal Arm B FAV-marginal P~15-20%** / #1356 tanjiro Arm A ~22% P~25% / #1360 alphonse NM R-power ~9% P~30% / #1363 nezuko NM diagonal just-assigned P~30%. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 383 — 1 stale_wip ack on #1286 fern PP n=3 H4 LATE-coverage chain, **3/6 runs terminal s1-A just-terminal cleaner than s0-A, paired delta attenuated 2.7× from screening**). **#1286 chain status** (group `g1r4-fern/h4-late-coverage-pp`): s0-A `qzuvy6wa` TERMINAL val=3.266322 fs=3175 drift +0.000182 EXCEPTIONALLY CLEAN / s0-C `957t6w8u` TERMINAL val=3.265627 fs=3175 Δ_paired=−0.000695 FAV-attenuated / **s1-A `9it76841` TERMINAL val=3.265393 fs=3175 drift +0.002003 PASS-CLEAN (cleaner than s0-A by 0.000929)** / s1-C `bkl9s3yi` RUNNING step 450/3350 (~13%) / s2-A, s2-C NOT-STARTED. **n=2 ctrl mean drift +0.001093** PASS-CLEAN G4 with 2.7× margin. **Cohort-favorable signature on ctrl side continues**: all ctrls today landing exceptionally close to baseline mean — consistent with #1240 PP / #1281 PP / #1297 / #1286 / #1318 / #1346 chains showing today's favorable-cohort pattern. **🎯 Paired delta attenuation pattern catalog**: #1240 PP 4% attenuation (exceptional preservation) / #1281 PP cohort-reversal +0.00217 / **#1286 PP 37% retention (~2.7× attenuation)** — 3rd documented PP attenuation pattern, cycle 354 paired-pod weakening confirmed across coverage axis under cohort-favorable conditions. **Post-#1240 baseline G1 feasibility**: for G1 PASS (mean Arm C ≤ 3.26339), required mean(s1-C + s2-C) ≤ 3.261153 per seed; modal forecast s1-C ≈ 3.264698 using s0-equivalent paired Δ → essentially infeasible unless both remaining arms show 3× stronger favorable delta. **P(MERGE) ~5-10%**. Recommendation: **COMPLETE FULL CHAIN** for (1) statistically-defensible n=3 verdict on LATE_MAX_D_IN coverage axis (2nd PP consolidation point with #1240 PP) / (2) cycle 354 paired-pod attenuation pattern reference / (3) low-prob G1 cushion possibility if s1-C/s2-C lucky favorable cohort. Pre-staged decision tree row 3 productive-NULL most likely (P~75%), row 2 productive-MARGINAL (P~15%), row 1 MERGE (P~5-10%), row 4 productive-ADVERSE (P~5%). **G5 trajectory marginal**: 0/2 terminal seeds at fs ≤ 3150 (both at 3175); if s1-C continues mild paired-Δ pattern, likely fs=3175 also. **Cross-chain status cycle-383 (8 chains, 0 idle)**: #1281 edward PP s1-B ~50-55% P~5% / #1286 (this) 3/6 terminal P~5-10% / #1331 frieren Arm C ~38% / #1338 askeladd Arm C ~15% + D pending P~10% / #1346 thorfinn Arm B ~32% / #1356 tanjiro Arm A ~18% P~25% only-chain-on-post-#1240 / #1360 alphonse NM R-power just-started / #1363 nezuko NM diagonal just-assigned. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-27 (cycle 382 — **#1318 nezuko stack-compose CLOSED productive-NULL (48th no-merge)** + nezuko REASSIGNED #1363 NM-diagonal preconditioning ablation, **10th NM mechanism axis (virgin structural full-R vs diagonal-only R)**). **#1318 chain CLOSED** 3/4 arms terminal (Arm D never launched): A ctrl `jfdcialr` val=3.265970 fs=3175 drift −0.000170 EXCEPTIONALLY-CLEAN-FAVORABLE-COHORT / B reset_only `hbjo3kz0` val=3.266846 fs=3175 Δ=+0.000876 NULL / C cov_only `4i2fitbz` val=3.266682 fs=3175 Δ=+0.000712 NULL DEPARTED-from-cycle-375-modal-forecast. Best Arm A is +0.00258 above post-#1240 baseline 3.26339 → no merge candidate. Closed without Arm D launch since modal D forecast NULL near baseline (additive Δ_B+Δ_C=+0.0016, super-additive not plausible when both components NULL). **Cross-chain mechanism contribution captured**: Arm B fed the 4-way RESET=2345 cross-chain dispositive consolidation (cycle 381 finding); Arm C documents the FIRST CASE where cohort-favorable conditions absorb a screening favorable signal on the coverage axis (cycle 375 modal [3.262, 3.265] FAV did not reproduce — Δ landed +0.000712 NULL instead of expected −0.001 to −0.002 FAV). **nezuko REASSIGNED #1363 NM-diagonal preconditioning** (`g1r4-nezuko/nm-diagonal-ablation`): tests structural information channel of R — diagonal-only (per-dim variance) vs full-R (per-dim variance + cross-dim correlations). Adds `NANOGPT_NEWTON_MUON_DIAGONAL` env var (default 0=full-R). 4-arm chain on post-#1240 stack: A FULL-R UP=5 ctrl / B DIAG-ONLY UP=5 (matched structural ablation) / C DIAG-ONLY UP=1 (every-step refresh, exploits cheap diag) / D DIAG-ONLY UP=3 (intermediate period). Schmidhuber-style "old idea revival" — diagonal preconditioning is AdaGrad/RMSProp/Adam's choice (cheap, scalable per-dim); full preconditioning is K-FAC/Shampoo/Newton's choice (expensive, cross-dim correlations). Tests whether off-diagonal R correlations are essential or per-dim variance correction suffices. If diag-only ≈ full-R: major simplification result enabling cheap UPDATE_PERIOD=1 deployment. If diag-only fails: strengthens NM-full mechanism story, off-diagonals essential. **10th NM mechanism axis** when chain closes. Pre-staged 6-row decision tree (row 1 strong signal PP-promote / row 2 marginal PP / row 3 simplification result B≈A / row 4 diag broken / row 5 adaptive-period diag winner / row 6 productive-NULL). ETA full chain ~7h sequential. **Cross-chain status cycle-382 (8 chains, 0 idle)**: #1281 edward PP s1-B ~45-50% P~5% / #1286 fern PP s1-A ~45-48% P~15-20% / #1331 frieren β-schedule Arm C ~35% pre-drop / #1338 askeladd Arm C 2-shot ~12% + Arm D pending P~10% / #1346 thorfinn per-group LR-scale Arm B ~28% / #1356 tanjiro NM period sweep Arm A ~15% / #1360 alphonse NM R-power JUST ASSIGNED / #1363 nezuko NM-diagonal JUST ASSIGNED. 0 review-ready. No new human GH issues (latest Issue #1262 r5 since 2026-05-26T06:08Z, no r4 updates).

- **Date:** 2026-05-26 (cycle 381 — 1 stale_wip ack on #1338 askeladd NM multi-shot RESET chain, **Arm A + Arm B both terminal, Arm B single-shot Δ_paired=−0.000094 NULL-noise completes 4-WAY DISPOSITIVE CROSS-CHAIN RESET=2345 CONSOLIDATION**). **#1338 chain status** (group `g1r4-askeladd/nm-multi-shot-reset`): A ctrl `e71gh1pq` TERMINAL val=3.266757 fs=3175 drift +0.000617 PASS-CLEAN / **B single `bbaiv26k` TERMINAL val=3.266663 fs=3175 Δ_paired=−0.000094 NULL-noise, multi_reset_triggered_at_step=2345 total_resets=1 ✓** / C two-shot `rhebjf25` RUNNING step 335/3350 (~10%) pre-first-reset / D three-shot NOT YET STARTED. **🎯 4-WAY CROSS-CHAIN RESET=2345 SINGLE-SHOT CONSOLIDATION NOW DISPOSITIVE**: #1281 H2 screening Δ=−0.00226 FAV-noise / #1281 PP s0-B Δ=+0.00217 ADVERSE (cohort-reversal) / #1318 H1 Arm B Δ=+0.000876 NULL / **#1338 Arm B Δ=−0.000094 NULL-noise (closest-to-zero replication)** → combined mean Δ=+0.000148 essentially zero, variance ~0.00190 across N=1 replications dominates mechanism signal → **RESET=2345 SINGLE-SHOT IS NULL, real mechanism effect size near baseline, original screening signal was favorable-noise**. **Telemetry resolution definitively confirmed**: `train/nm/multi_reset_triggered_at_step` + `total_resets` keys in #1338 settle the #1281 reset_triggered=0 logging-quirk question as latest-value-overwrites-historical-max W&B summary artifact. **Cycle 381 reframes the chain**: was "test multi-shot favorable extension of single-shot" → now "**dispositively fence RESET schedule axis as no-mechanism-signal**" — equally valuable mechanism characterization. **Modal forecast Arm C 2-shot**: 40% NULL ≈ B / 30% NEG (repeated reset destroys R-buffer info) / 20% mild-FAV partial-continuous / 10% surprise-strong-FAV PP-eligible. **Modal forecast Arm D 3-shot**: 35% NEG > C monotone / 30% NULL ≈ C ≈ B fence axis / 20% mild-FAV / 15% strong-FAV. **Decision tree updated post-#1240 baseline** (PP threshold val ≤ 3.26339, much harder bar). **Cross-chain status cycle-381 (8 chains, 0 idle)**: #1281 edward PP s1-B `cdg0o0eg` ~42% ETA ~2-2.5h P(MERGE)~5% / #1286 fern PP s1-A `9it76841` ~42% ETA ~5-7h P~15-20% / #1331 frieren β-schedule Arm C ~30% pre-drop / #1338 (this) Arm C ~10% + D pending P~10% / #1346 thorfinn per-group LR-scale Arm B ~25% / #1356 tanjiro NM period sweep Arm A ~12% / #1360 alphonse NM R-power JUST ASSIGNED. 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 380 — **#1319 alphonse sub-window CLOSED productive-MARGINAL (47th no-merge)** + alphonse REASSIGNED #1360 NM R-power preconditioning sweep, **9th NM mechanism axis (virgin α-exponent)**). **#1319 chain terminated** 4/4 arms (post-#1138 stack, salvaged Arm A from #1280): A `[0, 1e9)` 3.26823/3200 drift +0.00209 PASS / B `[2700, 3000)` 3.26862/3200 Δ=+0.000388 NULL / **C `[2800, 3100)` 3.26780/3200 Δ=−0.000428 NULL-FAV-noise** (best arm sub-threshold) / **D `[2500, 2800)` 3.27173/3225 Δ=+0.00350 NEG** (middle-segment near `NS_COOLDOWN_START_FRAC=2345` HARMFUL — contradicts "NM-around-cooldown_start" hypothesis). W&B: `39ogmtxg / llz9r94f / t844d64h / 65j4bnha`. **🎯 6-WINDOW MONOTONE-BY-COOLDOWN-COVERAGE PATTERN ASSEMBLED** (#1280 H3 + #1319 H5 combined): 2 strictly-spanning-step-3000 windows (#1280 D 1000-step + #1319 C 300-step) → Δ ∈ [−0.0007, −0.0004] NULL-FAV / 2 edge-at-3000 windows (#1280 B + #1319 B) → Δ ∈ [+0.0004, +0.0007] NULL / 2 pre-3000-only windows (#1280 C + #1319 D) → Δ ∈ [+0.0016, +0.0035] borderline-NEG to NEG. Strongest within-chain signal C − D = −0.00393 (9.2× threshold). **No merge under post-#1240 baseline 3.26339** (best arm C val=3.26780 is +0.00441 over); closed productive-MARGINAL. Sub-window axis FENCED as mechanism-characterized. Cross-chain convergence: aligns with #1281 H2 4-way RESET=2345 consolidation (3/4 NULL near baseline → "around 2345 NOT favorable") and #1286 H4 LATE_MAX_D_IN coverage finding. **alphonse REASSIGNED #1360 NM R-power preconditioning sweep** (`g1r4-alphonse/nm-rpower-sweep`): adds `NANOGPT_NEWTON_MUON_POWER` env var (default 0.5) generalizing `G → G·R^{-α}` from canonical inverse-symmetric-sqrt (α=0.5) to arbitrary exponent. Single-line code change at `train_gpt_simple.py:840` (`vals_clamped.rsqrt()` → `vals_clamped.pow(-self.newton_power)`). 4-arm sweep on post-#1240 stack: A α=0.5 ctrl / B α=0.333 (1/3-power, weaker) / C α=0.667 (2/3-power, stronger) / D α=0.75 (3/4-power, strongest). Schmidhuber-style "old idea revival" — power preconditioning generalizes natural gradient (Amari 1998); Shampoo uses α≈1/4, K-FAC uses α=1, NM uses α=1/2; the optimum is empirical. With post-#1240 stack adding 12 high-condition-number MLP down-proj matrices (R_cond ~10^6), dynamic range of R^{-α} is R_cond^α — very sensitive to α. **Virgin axis, 9th NM mechanism axis** when chain closes. ETA full chain ~7h sequential. Pre-staged 4-row decision tree: row 1 any Δ ≤ −0.002 AND val ≤ 3.26339 → PP-promote n=3 / row 2 Δ ∈ [−0.002, −0.001] → PP-promote with caveat / row 3 monotone α-trend → close productive-MARGINAL with tighter follow-up / row 4 all NULL/NEG no trend → close productive-NULL, α=0.5 robust optimum. **Cross-chain status cycle-380**: #1281 edward PP s1-B `cdg0o0eg` ~40% ETA ~2.5h P(MERGE)~5% / #1286 fern PP s1-A `9it76841` ~40-42% / #1331 frieren β-schedule Arm C ~30% pre-step-down / #1338 askeladd RESET-multi-shot Arm B ~88% ETA ~15-25 min terminal pending / #1346 thorfinn per-group LR-scale Arm B ~25% / #1356 tanjiro NM period sweep Arm A ~12% / **#1360 alphonse NM R-power JUST ASSIGNED**. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 379 — 1 stale_wip ack #1281 edward PP, **3/6 runs terminal, s1-B running ~38.1%, 4-way cross-chain RESET=2345 mechanism consolidation**). **#1281 PP chain status** (group `g1r4-edward/cooldown-entry-r-refresh-pp`): s0-A `kf70xdzx` TERMINAL val=3.264243 fs=3150 (drift −0.00190 vs old / +0.000853 vs new) / s0-B `pqafib4r` TERMINAL val=3.266409 fs=3175 Δ_paired=+0.00217 ADVERSE / s1-A `j4ubgeo6` TERMINAL val=3.265288 fs=3175 (drift +0.001898 vs new baseline PASS) / s1-B `cdg0o0eg` RUNNING step 1275/3350 (~38.1%) ETA ~2.5h / s2-A, s2-B NOT YET LAUNCHED. **🎯 4-WAY CROSS-CHAIN RESET=2345 CONSOLIDATION (cycle 378 telemetry confirmation resolved logging quirk question)**: #1281 screening (cycle 348 N=1) val=3.26506 Δ=−0.00226 FAV (favorable-noise) / #1281 PP s0-B val=3.266409 Δ=+0.00217 ADVERSE (cohort-reversal) / #1318 Arm B val=3.266846 Δ=+0.000876 NULL / #1338 Arm B step 2875/3350 (~85.8%) RESET FIRED CONFIRMED, terminal pending. **3 of 4 replications place RESET=2345 at val ≈ baseline** → original screening was favorable-noise on mechanism side, **real effect size NULL with mild-adverse bias under cohort interactions**. **Post-#1240 merge G1 feasibility**: under new baseline 3.26339, required mean(s1-B + s2-B) ≤ 3.261881 (essentially impossible under any modal forecast). Even modal-favorable s1-B=3.263 with s2-B equal still yields mean(B,n=3)=3.2641 > 3.26339. **P(MERGE) ~5%**. Recommendation: **COMPLETE FULL CHAIN** for: (1) final consolidation H2 directive cluster RESET_STEP axis closure (statistically-defensible n=3 NULL verdict) / (2) paired-pod cycle 354 reversal pattern reference (2nd documented case post-#847 era) / (3) combined with #1338 = 5 N=1 replications dispositive characterization. **Pre-staged decision tree row 3 productive-NULL close most likely (P~60%)**, row 4 productive-ADVERSE (P~20%), row 2 productive-MARGINAL (P~15%), row 1 MERGE (P~5%). **Cross-chain status cycle-379**: #1338 Arm B step 2875/3350 (~85.8%) ETA terminal ~30 min reset confirmed firing / #1319 Arm D step 3150/3350 (~94.0%) val=3.287 mid-cooldown near-terminal speedrun/reached_target=0 likely missed target / #1346 Arm B step 800/3350 (~23.9%) / #1356 tanjiro Arm A `6tq29ldr` LAUNCHED step 325/3350 (~9.7%) bit-identity gate pending terminal / #1331 Arm C step 1005/3350 (~30.0%) pre-step-down phase / #1286 fern PP s1-A `9it76841` step 1350 (~40.3%). 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 378 — 1 stale_wip ack #1331 frieren NM β-schedule, **2/4 arms terminal Arm B NULL-FAV direction validates β-step-down weakly**). **#1331 chain status** (group `g1r4-frieren/nm-beta-schedule`): Arm A ctrl `95n2u3ff` TERMINAL val=3.267367 fs=3200 drift +0.001227 PASS / **Arm B step-down moderate (β=0.95→0.90 @ step 2345) `fh5mj1pe` TERMINAL val=3.266591 fs=3175 Δ_paired_val=−0.000776 NULL-FAV-noise / Δ_paired_fs=−25 FAV** / Arm C step-down deeper (β=0.95→0.85 @ step 2345) `g282e5fm` RUNNING step 525/3350 (~15.7%) current_beta=0.95 pre-drop / Arm D step-down early (β=0.95→0.90 @ step 2000) NOT YET LAUNCHED. **🎯 Arm B mechanism direction validates β-step-down hypothesis WEAKLY**: substantially better than #1288 Arm C constant β=0.90 (Δ_diff −0.002776 inverted) confirming step-down avoids early-training over-reaction problem, but Arm B Δ_paired magnitude (−0.000776) is below 0.0015 signal threshold. R_inv_sqrt_norm_mean dropped 81.487 → 80.357 (−1.4% global, would be larger in late-phase only). **🎯 CRITICAL post-#1240-merge recalibration**: new baseline val=3.26339/fs=3150, Arm B at val=3.266591 is +0.003201 above new baseline = **cannot merge directly**, this chain is now MECHANISM DIRECTION TEST only. **If Arm D early-pre-adapt @ step 2000 beats Arm B by ≥0.001** (decision tree Row 4 PRIMARY): would justify post-#1240-stack retest of β-schedule with period=5 already 2× more responsive — could compound differently. **Cross-chain post-#1240 merge candidate recalibration table**: #1281 PP s1-A 3.265288 fs=3175 P(MERGE)~5-15% / #1286 PP s0-C 3.265627 fs=3175 P(MERGE)~10-20% if signal sustains across n=3 / **#1318 stack-compose ALL 3 ARMS TERMINAL with NULL across treatments** (A 3.265970 / B reset 3.266846 Δ=+0.000876 / **C cov 3.266682 Δ=+0.000712 NULL — DEPARTED FROM CYCLE 375 MODAL FORECAST** of [3.262, 3.265] FAV) Arm D never launched P(MERGE)~0% modal close productive-NULL / #1319 alphonse Arm D step 2700/3350 (~80.6%) ETA terminal ~30-40 min / **#1338 askeladd Arm B `bbaiv26k` step 2425/3350 (~72.4%) RESET DID FIRE at step 2345 telemetry CONFIRMED** (train/nm/multi_reset_triggered_at_step=2345, total_resets=1) — this confirms RESET mechanism is firing correctly across all 4 N=1 replications, the #1281 PP `reset_triggered=0` summary was indeed logging quirk artifact / #1346 thorfinn Arm A ctrl `hikw4tzr` TERMINAL val=3.265585 fs=3175 drift −0.000555 EXCEPTIONALLY-CLEAN (cycle 354 lesson confirmed), Arm B mlp-boost `rxkm9jwm` just launched step 325/3350 (~9.7%). **#1331 cycle 378 verdict**: chain primarily mechanism direction test, awaiting Arms C and D, full chain ETA ~6h. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 377 — **🎯 #1240 MERGED — FIRST MERGE SINCE #847, NEW BASELINE val=3.26339 fs=3150** + 1 stale_wip ack #1346 + g1r4-tanjiro reassigned #1356). **🎯 #1240 tanjiro PP (n=3 NM coverage+period extension) ALL 5 GATES PASS MERGED**: val=3.26339/fs=3150 (vs old 3.26614/3175, improvement −0.00275 val, −25 fs). Mean ctrl drift +0.000215 EXCEPTIONALLY CLEAN (14× margin). 3/3 seeds favorable. Screening→PP attenuation −4% (cleanest signal preservation of any NM chain). Two mechanisms fully characterized and additively composable: **COVERAGE** (`MAX_D_IN 1024→4096` adds 12 MLP down-proj matrices d_in=3072, drives val, R_cond ~10^6 for new matrices) + **PERIOD** (`UPDATE_PERIOD 10→5` doubles R refresh rate, drives fs, orthogonal to coverage). W&B armD runs: xx5bfiq0/yg4bp3yf/o7abyp0d. 1st post-NM-mechanism-characterization-wave merge, 47th PR since branch launch. **NEW BASELINE: val=3.26339, fs=3150** (git commit `06b6aef`). **All outstanding PP chains must recalibrate G1 against new baseline 3.26339**: #1281 edward PP (P(MERGE) now ~10-15%, even lower) / #1286 fern PP (now needs val ≤ 3.26339 for G1 — still possible if screening Δ=−0.00188 sustains) / #1318 nezuko stack-compose (Arm C cov_only modal val ~3.262-3.265 on old stack, likely passes if covers mechanism is directionally consistent). **1 stale_wip ack #1346 (thorfinn per-group LR scale)**: Arm A ctrl `hikw4tzr` RUNNING step 3225/3350 (~96.3%), val=3.2758 partial at step 3200 — CYCLE 354 LESSON applied, expect terminal val ~3.265-3.270; CRITICAL: treatment arms (B/C/D) now must beat NEW baseline 3.26339 for merge candidacy (was 3.26614) — even favorable Δ on old stack likely insufficient for G1, mechanism direction test only; if favorable → retest on new post-#1240 stack before PP escalation. Arms B/C/D not yet launched. **g1r4-tanjiro reassigned #1356 NM period sweep on new stack** (`g1r4-tanjiro/nm-period-sweep-new-stack`): 4-arm sweep on post-#1240 stack (NANOGPT_NEWTON_MUON_UPDATE_PERIOD ∈ {5=ctrl, 3, 2, 10=sanity}). Tests whether period improvement continues at lower values (period=3/2) and confirms period=5 > period=10 on new stack with max_d_in=4096 (prior comparison was confounded with coverage axis). No code change needed. ETA full chain ~8h sequential. **Cross-chain status cycle-377**: #1318 nezuko 2/4 terminal Arm C ETA ~2h / #1319 alphonse 3/4 terminal Arm D ETA ~3.5h / #1331 frieren β-schedule 2/4 terminal (Arm B val=3.2666 Δ=−0.0008 NULL-FAV @ step 3200, Arm C running early step 50) / #1338 askeladd multi-shot RESET Arm B `bbaiv26k` running step 575 pre-reset / #1346 thorfinn per-group LR-scale Arm A near-terminal (ETA minutes) / #1281 edward PP P(MERGE) now ~10-15% under new baseline / #1286 fern PP 1/6 terminal ETA ~07:00-09:00 UTC 27th now calibrated vs new baseline. 8+ chains active, 0 idle (tanjiro just reassigned #1356), 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 376 — 1 stale_wip ack on #1319 alphonse sub-window decomposition, **3/4 arms terminal with Arm C cooldown-transition NULL-FAV-noise lead by sub-threshold margin**). **#1319 chain status** (group `g1r4-alphonse/nm-burst-subwindow` + salvaged Arm A): A ctrl `[0, 1e9)` (from OLD #1280 chain) TERMINAL val=3.26823 fs=3200 drift +0.00209 PASS / **B post-2700 `llz9r94f` `[2700, 3000)` TERMINAL val=3.268618 fs=3200 Δ_paired_val=+0.000388 NULL** / **C cooldown-transition `t844d64h` (relaunch) `[2800, 3100)` TERMINAL val=3.267802 fs=3200 Δ_paired_val=−0.000428 NULL-FAV-noise** / D middle-anchor `65j4bnha` `[2500, 2800)` RUNNING step 725/3350 (~21.6%) partial 3.7392 early, window not yet active. Arm C window-logic recovery clean — config `start_step=2800, end_step=3100` verified, `window_active=0` at step 3350 correctly closed after 3100, no telemetry anomaly remaining. **🎯 5-SUB-WINDOW DECOMPOSITION ASSEMBLED** (#1280 H3 + #1319 H5 combined, highest-resolution NM-burst-window characterization in r4 launch): #1280 A always-on 3.26823 ref / **#1280 D [2200, 3200) 1000-step val=3.26753 Δ=−0.00070 NULL-FAV** / **#1319 C [2800, 3100) 300-step val=3.267802 Δ=−0.000428 NULL-FAV** / #1319 B [2700, 3000) 300-step val=3.268618 Δ=+0.000388 NULL / #1280 B [2400, 3000) 600-step val=3.26895 Δ=+0.00072 NULL / #1280 C [2400, 2700) 300-step val=3.26984 Δ=+0.00161 borderline-NEG. **🎯 PATTERN**: 2 best sub-windows (#1280 D wide + #1319 C narrow cooldown-transition) are the ONLY two **strictly containing step 3000** (where bf16 LR cooldown finishes ~step 3000-3100); 3 sub-windows edging at step 3000 or stopping before land Δ ∈ [+0.0004, +0.0016] NULL→borderline-NEG. **Margin assessment**: Δ_C − Δ_B = −0.000816 **sub-threshold** for decision tree row 3 (requires ≥0.0010). Currently insufficient to claim cooldown-transition-itself load-bearing with N=1 confidence. **Modal forecast Arm D [2500, 2800)** (only sub-window NOT containing step 3000, purely middle-segment): 35% continuous-load-bearing → Δ_D ≈ +0.0005 NULL row 4 close 47th no-merge / 35% cohort-favorable + middle-mild-fav → Δ_D ≈ −0.0005 NULL still Row 4 / **25% middle-segment-harmful** → Δ_D ≈ +0.0015 borderline-NEG **row 3 cooldown-transition-CONFIRMED productive-MARGINAL** / 5% surprise. **Pre-staged decision tree resolution**: Row 1 NOT triggered (both B/C val > baseline 3.26614), Row 2 NOT triggered (both in tighter NULL-band), Row 3 PENDING D, Row 4 currently most plausible. **Cross-chain merge queue cycle-376**: (1) **#1240 tanjiro PP** s2-D step 2525/3350 (~75.4%) val=3.3628 mid-training, **ETA terminal ~45-55 min**, n=2 mean Δ=−0.003126 STRONGLY FAV, **STILL P(5/5 MERGE) ≥ 90% — will likely merge FIRST** (note: `fs` not logged in this group, need to verify fs from W&B summary on s2-D terminal for G5); (2) #1318 nezuko 2/4 terminal, Arm C cov_only ETA ~2h, PP-promote scope narrowed to Arm C alone post cycle 375 cross-chain convergence finding; (3) #1319 (this) 3/4 terminal modal forecast row 4 close 47th no-merge; (4) #1281 edward PP **P(MERGE) ~15-20%** (cycle 375 evidence further weakened RESET=2345 estimate); (5) #1286 fern PP ETA ~07:00-09:00 UTC 27th. **Plus screening**: #1338 askeladd Arm B `bbaiv26k` RUNNING step 575/3350 (~17.2%, reset at step 2345 not fired yet) — will provide **4th independent N=1 RESET=2345 replication** for further cross-chain triangulation (#1281 screening / #1281 PP s0-B / #1318 Arm B / #1338 Arm B); #1331 β-schedule (Arm A near-terminal), #1346 per-group LR-scale (just-assigned cycle 370). 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 375 — 1 stale_wip ack on #1318 nezuko stack-compose, **2/4 arms terminal with 🎯 CROSS-CHAIN CONVERGENCE finding**). **#1318 chain status** (group `g1r4-nezuko/nm-stack-compose`): A ctrl `jfdcialr` TERMINAL **val=3.265970 fs=3175 drift −0.000170 EXCEPTIONALLY CLEAN** (today's favorable-cohort signature continued) / **B reset_only `hbjo3kz0` TERMINAL val=3.266846 fs=3175 → Δ_paired_val=+0.000876 NULL-band** / C cov_only `4i2fitbz` RUNNING step 1125/3350 (~33.6%) partial val=3.5893 mid-training / D compound NOT YET LAUNCHED. **🎯 ARM B RESET=2345 NULL-LANDS is THE 3RD INDEPENDENT N=1 REPLICATION OF #1281 RESET MECHANISM, 2ND SHOWING NULL-NEAR-BASELINE PATTERN**: #1281 screening Arm B (RESET=2345) val=3.26506 Δ=−0.00226 FAV / #1281 PP s0-B (cycle 373) val=3.26641 Δ=+0.00217 ADVERSE near baseline / **#1318 Arm B (this cycle 375) val=3.266846 Δ=+0.000876 NULL near baseline** → 2/3 land at baseline drift, only original screening landed favorable-noise. **Three implications**: (1) **TELEMETRY-ARTIFACT THEORY FOR #1281 reset_triggered=0 CONFIRMED PLAUSIBLE** — Arm B got 3.266846 not ctrl-equivalent 3.26614, meaning RESET *did* fire, summary `reset_triggered=0` is latest-value-overwrites-historical-max logging quirk; (2) **RESET=2345 mechanism is NULL-to-MINIMAL favorable** — original screening was favorable-noise on mechanism side, NOT robust −0.00226 effect, PP attenuation is collapse-to-NULL not the typical ~50% attenuation; (3) **Today's favorable-cohort signature applies to ctrl side**: ctrls landing 3.26424/3.265970/3.26424 across multiple chains → paired deltas look adverse/NULL even when Arm B is at production baseline. **5-gate partial assessment (Arm B alone)**: G1 FAIL by 0.00071 / G2 PASS / G4 PASS exceptionally clean / G5 provisional PASS — **Arm B cheaper-mechanism PP-promote is no longer attractive**. **Modal forecast Arm C cov_only** (LATE_MAX_D_IN=4096 @ step 2400): cross-chain priors from #1240 screening Arm B always-on val=3.26529 Δ=−0.00232 FAV / #1240 PP n=2 mean Δ=−0.003126 / #1286 Arm C late-only val=3.26367 Δ=−0.00188 FAV → modal val ∈ [3.262, 3.265], Δ_paired_C ∈ [−0.002, −0.0010] FAVORABLE. **Coverage axis is the most consistently load-bearing NM mechanism across all replications**. **Modal forecast Arm D compound**: if B NULL (current) and C FAV (modal), pure additive D ≈ val_C / super-additive D ≤ val_C − 0.0005 / sub-additive D > val_C interferes. **🎯 PRACTICAL IMPLICATION**: if D ≈ C confirmed, PP-PROMOTE candidate for #1318 is **Arm C cov_only alone** — same mechanism as #1286 PP currently in flight — **AVOID double-PP-launching same mechanism** if Arm C ≈ Arm D within seed-variance. **Cross-chain merge queue cycle-375**: (1) **#1240 tanjiro PP** s2-D step 2200/3350 (~65.7%) val=3.4123 healthy mid-training, ETA terminal ~35-40 min, n=2 mean Δ=−0.003126 STRONGLY FAV, **STILL P(5/5 MERGE) ≥ 90% — will likely merge FIRST**; (2) #1318 (this) 2/4 terminal, Arm C ETA ~2h, full chain ~4-5h; (3) #1319 alphonse sub-window ETA ~02:00 UTC 27th; (4) #1281 PP P~25%, **cycle 375 evidence strengthens NULL-collapse interpretation**; (5) #1286 fern PP ETA ~07:00-09:00 UTC 27th. Plus screening: #1338 askeladd multi-shot RESET (Arm A TERMINAL val=3.266757 drift +0.00062 PASS-CLEAN — cycle 354 lesson CONFIRMED with ~0.010 drop from step 3200 partial 3.276991 → terminal 3.266757; Arm B launching soon = 3rd N=1 RESET=2345 replication for further cross-chain triangulation), #1331 β-schedule (Arm A near-terminal), #1346 per-group LR-scale (just-assigned cycle 370). 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 374 — 1 stale_wip ack on #1338 askeladd NM multi-shot RESET chain, **first comment on this PR**). **#1338 chain status** (group `g1r4-askeladd/nm-multi-shot-reset`): only **Arm A ctrl `e71gh1pq` RUNNING step 3200/3350 (~95.5%)** partial val=3.276991 at step 3200 / val=3.279521 at step 3175, fs=3175 already matches baseline. **N=1 LESSON FROM CYCLE 354 APPLIED**: partial val=3.277 at step 3200 looks +0.011 above baseline but per #1277 cycle 347→354 correction precedent val can drop 0.005-0.010 in final ~150 steps cooldown finishing → modal terminal forecast Arm A val ∈ [3.266, 3.272], wait for step=3350 terminal before drift gate evaluation. Arms B (RESET_STEPS=2345 single, replicates #1281 mechanism), C (2345,2700 two-shot), D (2345,2600,2900 three-shot) not yet launched. **Hypothesis recap**: tests whether NM R-buffer staleness is CONTINUOUS problem across cooldown distribution-shift trajectory vs single-boundary event. Multi-shot win → R-freshness continuous load-bearing. Multi-shot NULL ≈ B → single-shot captures full R-freshness gain (R only needs reset ONCE at cooldown entry). **Critical Arm B replication check**: provides INDEPENDENT N=1 mechanism replication of #1281 H2 Arm B (RESET=2345 screening Δ=−0.00226 favorable). If #1281 PP shows reversal pattern (cycle 373 concern), Arm B val ≈ 3.26506 (within seed-variance) would CONFIRM screening signal was real and #1281 paired-pod reversal is favorable-cohort-on-ctrl explanation. If Arm B drifts much higher (≈baseline 3.26614), suggests RESET=2345 mechanism genuinely weaker than screening estimated. Pre-staged 6-row decision tree from PR body. **Cross-chain merge queue cycle-374**: #1240 tanjiro PP s2-D step 1800/3350 (~53.7%) RUNNING healthy trajectory val=3.4664 mid-training, ETA terminal ~55 min — STILL P(5/5 MERGE) ≥ 90%, will likely merge FIRST / #1318 stack-compose ETA ~02:00 UTC 27th / #1319 sub-window ETA ~02:00 UTC 27th / #1281 edward PP 2/6 terminal n=1 ADVERSE telemetry verification pending P(MERGE)~25% ETA ~05:00 UTC 27th / #1286 fern PP exceptional s0-A drift +0.00018 ETA ~07:00-09:00 UTC 27th. Plus screening: #1331 β-schedule (Arm A near-terminal), **#1338 multi-shot RESET (this)**, #1346 per-group LR-scale. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 373 — 1 stale_wip ack on #1281 edward PP n=3, **2/6 runs terminal, n=1 paired delta ADVERSE +0.00217 + ⚠️ telemetry-vs-mechanism verification request issued**). **#1281 PP chain status** (group `g1r4-edward/cooldown-entry-r-refresh-pp`): s0-A-ctrl `kf70xdzx` TERMINAL val=3.26424/fs=3150 drift −0.00190 (favorable-cohort signature) / **s0-B-armB `pqafib4r` TERMINAL val=3.26641/fs=3175 → Δ_paired_val=+0.00217 ADVERSE direction OPPOSITE of screening Δ=−0.00226** / s1-A-ctrl `j4ubgeo6` RUNNING step 850/3350 (~25.4%) / s1-B/s2-A/s2-B not yet launched. **⚠️ W&B TELEMETRY VERIFICATION REQUEST ISSUED**: `newton_muon/reset_triggered=0` in s0-B summary despite `NANOGPT_NEWTON_MUON_RESET_STEP=2345` set. Three plausible explanations: (1) MOST LIKELY telemetry artifact — reset fires once at step 2345 then drops to 0, W&B summary captures FINAL step value 0 not historical maximum, need time-series check at step 2345-2360 / (2) env var name mismatch / (3) mechanism truly didn't fire. Cross-reference: screening Arm B should show same telemetry pattern if explanation (1). **🎯 PAIRED-POD CYCLE 354 REVERSAL PATTERN MAY BE FIRING**: s0-A landed at favorable-cohort drift −0.00190, s0-B landed at +0.00027 near baseline → paired delta appears ADVERSE +0.00217 even though absolute s0-B val=3.26641 ≈ baseline mean. **N=1 LESSON APPLIED DIFFERENTLY**: not partial-trajectory issue (#1277 cycle 354 was about cooldown finishing), this is paired-pod-reverses-screening-signal pattern. Wait for full n=3 before concluding. **Three-scenario forecast (P(MERGE) DROPPED from cycle 366's ≥75% to ~25%)**: cohort-recovery 35% → mean val ≈ 3.26656 G1 FAIL productive-MARGINAL / collapse-to-NULL 40% → G1 FAIL / recovery-to-favorable 20% → 5/5 MERGE / surprise-strong-favorable 5% → MERGE. **#1240 PP merge would shift baseline** (modal forecast new baseline 3.26365 if #1240 merges); recalibrate #1281 G1 to new baseline upon #1240 merge. **Cross-chain merge candidate queue cycle-373**: #1240 tanjiro PP (s2-D ETA terminal ~minutes, P≥90% MERGE — will likely merge FIRST today) / #1318 stack-compose ETA ~02:00 UTC 27th / #1319 sub-window ETA ~02:00 UTC 27th / #1281 (this) ETA ~05:00 UTC 27th with revised low-confidence forecast / #1286 PP ETA ~07:00-09:00 UTC 27th. Plus screening: #1331 β-schedule (Arm A near-terminal), #1338 multi-shot RESET, #1346 per-group LR-scale. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 372 — 1 stale_wip ack on #1240 tanjiro PP n=3, **5/6 runs terminal, n=3 ctrl complete, 4/5 gates already PASS, only G3 pending s2-D terminal**). **#1240 PP chain status** (group `g1r4-tanjiro/newton-muon-extension-pp`): **s0-A 3.265471/3175 / s0-D 3.263604/3150 / s1-A 3.267161/3175 / s1-D 3.262776/3150 / s2-A 3.266432/3175 ALL TERMINAL** + s2-D-armD RUNNING step 825/3350 (~24.6%). **🎯 G4 FULLY-COMPUTED CTRL DRIFT +0.000214** — n=3 ctrl mean=3.266355 vs production baseline 3.26614 → **cleanest n=3 ctrl drift envelope of any PP chain to date** (within ±0.003 by 14× margin), confirms post-#1138 NM stack bit-identically reproducible across seeds. Paired deltas (n=2 complete): s0 Δ=−0.001867 / s1 Δ=−0.004385 STRONGLY FAV → **n=2 mean Δ_paired_val=−0.003126**, 2.5× stronger than modal screening forecast. **5-gate partial assessment**: G1 mean Arm D val=3.263190 (n=2) PASS cushion 0.00295 / G2 0.02912 PASS margin 7.3× / G3 2/2 favorable so far (PENDING s2-D, irrevocably secured if ≥2/3 at n=3) / **G4 ctrl drift +0.000214 PASS exceptionally clean** / G5 2/2 @ 3150 already secured. **Modal forecast s2-D**: 35% modal Δ=−0.0030 / 30% cohort-favorable Δ=−0.0040 / 25% adverse-attenuated Δ=−0.0010 / 10% adverse-collapsed Δ=+0.0010 (still likely MERGE). **🎯 PROBABILITY OF CLEAN 5/5 MERGE ≥ 90%** — strongest pre-terminal merge confidence of any PP chain in r4 launch to date. **N=1 CYCLE 354 LESSON APPLIED**: no s2-D terminal forecast from partial step 825 val=3.6871, wait for terminal step=3350. ETA s2-D terminal ~1.5h. **If 5/5 PASS → 1st merge since #847 cycle 345 (1st post-NM-mechanism-characterization-wave merge, 1st compositional NM-stack extension combining #1138 + coverage max_d=4096 + R-refresh period=5)** — directive-aligned answer to Issue #1261. **Cross-chain merge queue cycle-372**: #1240 (this, ETA ~1.5h, P≥90% MERGE) / #1318 stack-compose ETA ~02:00 UTC 27th / #1319 sub-window ETA ~02:00 UTC 27th / #1281 PP ETA ~05:00 UTC 27th / #1286 PP ETA ~07:00-09:00 UTC 27th. Plus screening: #1331 β-schedule (Arm A ~97.8%), #1338 multi-shot RESET, #1346 per-group LR-scale (just-assigned cycle 370). 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 371 — 1 stale_wip ack on #1331 frieren NM β-schedule chain, **first comment on this PR**). **#1331 chain status** (group `g1r4-frieren/nm-beta-schedule`): only **Arm A ctrl RUNNING step 3275/3350 (~97.8%)** val=3.2712 (partial-trajectory), `current_beta=0.95` steady, `R_inv_sqrt_norm_mean=81.50` (consistent with #1288 Arm A baseline 78.13 at terminal). Arms B/C/D not yet launched (sequential chain). **N=1 LESSON FROM CYCLE 354 APPLIED**: no terminal val forecast from partial-trajectory val=3.2712 at step 3275 — per #1277 cycle 347→354 correction precedent, val can drop 0.005-0.008 in final 4% during cooldown finishing. ETA Arm A terminal ~minutes. **Hypothesis recap**: tests NM-R-EMA-SCHEDULE β-step-down at cooldown_start — restores late-training preconditioning strength (β=0.90 mid-cooldown) WITHOUT early-training over-reaction (constant β=0.90 NEG in #1288 Arm C). Direct follow-up of #1288 telemetry showing monotone DECREASE in R_inv_sqrt_norm_mean with longer β → under-preconditioning at long horizons. **Pre-staged 4-row decision tree (frozen)**: row 1 PP-PROMOTE if any arm Δ ≤ −0.002 / row 2 productive-MARGINAL / row 3 productive-NULL fence axis / row 4 Arm D < B/C by ≥ 0.001 → early-drop validates pre-adaptation hypothesis. If favorable, **9th NM mechanism axis** alongside #1346 per-group LR-scale just-assigned cycle 370. **Cross-chain merge candidate queue cycle-371**: #1240 tanjiro PP (ETA imminent ~22:00 UTC, n=2 mean Δ=−0.003126 STRONGLY FAV, P≥85%) / #1318 nezuko stack-compose ETA ~02:00 UTC 27th / #1319 alphonse sub-window ETA ~02:00 UTC 27th / #1281 edward PP ETA ~05:00 UTC 27th / #1286 fern PP ETA ~07:00-09:00 UTC 27th. ETA #1331 full chain terminal ~7-9h sequential from Arm A start. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 370 — **#1297 thorfinn NM GROUPS layer-group sweep CLOSED productive-NULL (46th no-merge since #847)** + thorfinn REASSIGNED #1346 NM per-group LR-scale). **#1297 ALL 4 ARMS TERMINAL** (post-#1138 stack, seed 0, n=1): A all ctrl 3.26320/3150 drift −0.00294 PASS-CLEAN-favorable-cohort / B attn-only 3.26788/3200 Δ_paired=+0.00468 NEG / C mlp-only 3.26898/3200 Δ_paired=+0.00578 NEG / **D none diagnostic 3.26996/3225 Δ_paired=+0.00676 NEG** — **🎯 Arm D NM-off REPRODUCES pre-#1138 baseline 3.26756 within drift envelope** (|val_D − 3.26756|=0.00240 ≤ 0.003). W&B: `9cvnujcf / kszq6mte / 1rjs6w0o / 24eur376`. **🎯 LAYER-GROUP MECHANISM CONFIRMED**: both attn-only AND mlp-only individually NEG and roughly equivalent in damage (Δ_C − Δ_B = +0.00109 within seed-variance band) → NM is JOINT-LOAD-BEARING ACROSS BOTH LAYER GROUPS. **Sub-additivity ratio = 65%** (Δ_D=+0.00676 vs additive prediction Δ_B+Δ_C=+0.01046) → partial mechanistic overlap between attn and MLP-up-proj layer groups (both receive residual-stream input post-LN). **Per-matrix damage skew**: MLP +0.000195/matrix vs attn +0.000120/matrix → MLP per-matrix leverage 1.6× higher. **🎯 Arm D = strongest possible reproducibility test of #1138 merge**: confirms NM is the unique load-bearing mechanism #1138 added — NO HIDDEN NON-NM MECHANISMS in the merge. **8th NM mechanism axis characterized** (LAYER_GROUPS joint-load-bearing) — joins BETA / EPS / LATE_PERIOD / MAX_D_IN / RESET_STEP / START_STEP / END_STEP for **NM mechanism story FULLY MECHANISTICALLY CHARACTERIZED**. **thorfinn REASSIGNED #1346 NM per-group LR-scale** (`g1r4-thorfinn/nm-per-group-lr-scale`): direct follow-up of #1297 MLP per-matrix leverage finding (student's suggested follow-up #2). Adds `NANOGPT_NEWTON_MUON_LR_SCALE_ATTN` + `NANOGPT_NEWTON_MUON_LR_SCALE_MLP` env vars (default 1.0, multiplicative chain with existing MUON_ATTN/MLP_LR_MULT × NEWTON_MUON_LR_SCALE). 4-arm bidirectional-MLP-fence + attn-counter-test: A ctrl (1.0, 1.0) / B MLP-boost (1.0, 1.2) / C MLP-damp (1.0, 0.8) / D attn-boost (1.2, 1.0). Tests whether MLP NM has untapped LR headroom (1.6× per-matrix leverage finding). Pre-staged 6-row decision tree (B fav AND C NEG → MLP under-LR'd PP-promote / B NEG AND C fav → MLP over-LR'd PP-promote / B and C both NEG bilateral fence / D fav → attn-side unexpected PP / all NULL flat / B AND D both fav joint headroom). 9th NM mechanism axis when chain closes. **Cross-chain merge candidate queue cycle-370 (5 chains in flight, ordered by ETA)**: #1240 tanjiro PP (ETA <30 min, n=2 mean Δ=−0.003126 STRONGLY FAV, P≥85%) / #1318 nezuko stack-compose ETA ~02:00 UTC 27th / #1319 alphonse sub-window ETA ~02:00 UTC 27th / #1281 edward PP ETA ~05:00 UTC 27th / #1286 fern PP ETA ~07:00-09:00 UTC 27th. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 369 — 1 stale_wip ack on #1286 fern PP n=3 H4 late-coverage chain, **1/6 runs terminal with EXCEPTIONALLY clean s0-A ctrl anchor**). **#1286 PP chain status** (group `g1r4-fern/h4-late-coverage-pp`): **s0-A-ctrl TERMINAL val=3.26632 fs=3175 drift +0.00018 EXCEPTIONALLY CLEAN-FAVORABLE-NOISE — cleanest single-seed ctrl in entire post-#847 cohort by absolute precision** (within ±0.003 envelope by 167×). s0-C-late-maxd (LATE_MAX_D_IN=4096 @ step 2400) RUNNING ~step 50/3350 (~1.5%) val=10.83 early-warmup-normal; s1-A, s1-C, s2-A, s2-C QUEUED. **🎯 CROSS-PP FAVORABLE-COHORT SIGNATURE confirmed across today's chains**: seed-0 backbone runs landing exceptionally close to baseline mean — #1240 PP s0-A drift −0.00067 (cycle 345) / #1281 PP s0-A drift −0.00190 (cycle 366 favorable-noise) / #1297 Arm A drift −0.00294 (cycle 365 favorable-noise) / **#1286 PP s0-A drift +0.00018 (this chain, exceptionally close to mean)** / #1318 stack-compose Arm A drift +0.00014 (cycle 368 similarly clean) — unusually tight post-#1138 stack reproducibility across multiple chain launches today. **5-gate partial assessment (1/6 runs)**: G1 PENDING / G2 PENDING / G3 0/0 paired complete / **G4 PASS** (s0-A drift +0.00018, 167× margin within ±0.003) / G5 provisional PASS (s0-A fs=3175 ≤ 3175). **Three-scenario modal forecast**: #1138 pattern ~50% attenuation → PP mean Δ ≈ −0.00094 → mean Arm C val ≈ 3.26538 → G1 cushion 0.00076, G2=0.02528 (6.3× margin) MERGE-eligible / cohort-favorable → mean val ≈ 3.26482 strong MERGE / adverse cycle 354 paired-pod collapse to ~0.1× → mean val ≈ 3.26613 G1 borderline-PASS at +0.0001 still PASS by 5.8× G2 margin. **Hedge**: double-favorable val+fs screening signal means if val attenuates heavily, fs (G5 needs only 1/3 seeds ≤ 3175) may still survive. **N=1 LESSON FROM CYCLE 354 APPLIED**: s0-C terminal val only at step 3350 (currently ~1.5%); no partial-trajectory forecast — wait for s0-C terminal. **Cross-chain merge candidate queue cycle-369 (5 chains in flight, ordered by ETA)**: (1) **#1240 tanjiro PP** 2/3 pairs paired-complete, n=2 mean Δ=−0.003126 STRONGLY FAV, ETA s2 pair terminal ~22:00 UTC (~30 min); (2) #1318 nezuko stack-compose 1/4 terminal (A ctrl 3.26600 drift +0.00014 exceptional), ETA ~02:00-03:00 UTC 27th; (3) #1319 alphonse sub-window 2/4 effective (A salvaged 3.26823 + B [2700, 3000) terminal 3.2686), ETA ~02:00-03:00 UTC 27th; (4) #1281 edward PP 1/6 terminal, ETA ~05:00 UTC 27th; (5) **#1286 fern PP (this chain) 1/6 terminal**, ETA ~07:00-09:00 UTC 27th. **If #1240 PP terminal-passes 5-gates within 30 min → first merge since #847 (cycle 345 launch)**. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 368 — 2 stale_wip acks on #1319 alphonse sub-window + #1318 nezuko stack-compose, **both chains progressing healthily**). **#1319 alphonse sub-window decomposition chain RESTART after runner-script carryover bug** (the OLD `run_burst_arms.sh` had #1280 H3 windows hardcoded; student bit-identically reproduced #1280 H3 chain first → cherry-picked #1280 START/END env var code → updated chain script with correct #1319 windows; salvaged Arm A from OLD run since `[0, 1e9)` ctrl is identical between #1280/#1319). **Current state (group `g1r4-alphonse/nm-burst-subwindow` + salvaged OLD Arm A)**: A ctrl 3.26823/3200 PASS-CLEAN / **B [2700, 3000) TERMINAL 3.2686/3200 Δ_paired_val=+0.00037 NULL-band** (essentially identical to A, MINOR penalty) / C [2800, 3100) RUNNING ~14% / D [2500, 2800) QUEUED. **🎯 EARLY MECHANISM INTERPRETATION**: Arm B [2700, 3000) Δ=+0.00037 NULL is significantly better than #1280 Arm B [2400, 3000) Δ=+0.00072 NULL despite being a NARROWER 300-step window dropping [2400, 2700) — **suggests [2400, 2700) sub-window contributes mild NEG (~+0.0012 marginal harm)**, supporting "load-bearing phase is late in [2400, 3000)" hypothesis. ⚠️ W&B config telemetry verification request issued to student: agent sub-query flagged "no start_step/end_step in armC config" — likely benign env-var-vs-config artifact, but verify on terminal via `newton_muon/precond_active` toggle. ETA chain terminal ~02:00-03:00 UTC 27th. **#1318 nezuko stack-compose 2×2 factorial chain (RESET × LATE_COVERAGE)** 1/4 terminal: A ctrl 3.26600/3175 **drift +0.00014 EXCEPTIONALLY-CLEAN-FAVORABLE-NOISE** (within ±0.003 envelope by wide margin, today's favorable-cohort signature) / B reset_only RUNNING ~19% / C cov_only QUEUED / D compound QUEUED. **Implementation review**: clean compositional integration of #1281 RESET_STEP + #1286 LATE_*, `newton_muon/compound_armed` telemetry flag, bit-identical fallback verified via 30-step smoke test. **Pre-staged 4-row decision tree (frozen)**: D super-additive (D < min(B,C) by ≥0.0005) → PP on compound D = 4th/5th merge candidate / D additive → PP on cheaper RESET=2345 single mechanism / D destructive → close productive-NEG (mechanisms NOT orthogonal) / all NULL → close productive-NULL. ETA chain terminal ~02:00-03:00 UTC 27th. **Cross-chain merge candidate queue cycle-368 (5 chains)**: #1240 PP n=2 mean Δ=−0.003126 (ETA ~2h, P≥85% merge) / #1281 PP 1/6 done (ETA ~05:00 UTC 27th) / #1286 PP (ETA ~12-16h from cycle 363) / #1318 stack-compose (ETA ~02:00-03:00 UTC 27th, potential 4th candidate) / #1338 multi-shot RESET (just assigned, code change needed). #1338 askeladd just-assigned cycle 367. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 367 — **#1291 askeladd NM EPS sweep CLOSED productive-NULL** (45th no-merge) + askeladd REASSIGNED #1338 NM multi-shot R-buffer reset). **#1291 EPS sweep ALL 4 ARMS TERMINAL** (post-#1138 stack, seed 0, n=1): A ctrl eps=1e-4 3.26547/3175 drift −0.00067 PASS-CLEAN / B eps=1e-2 3.26657/3175 Δ=+0.00110 NULL / C eps=1e-6 3.26582/3175 Δ=+0.00035 NULL / D eps=1e-8 3.26619/3175 Δ=+0.00072 NULL (no numerical instability). W&B: `96p1yukz / y1l4idbc / jzvtxgfd / ml7wy1vx`. **🎯 EPS-AXIS FENCED FLAT ACROSS [1e-8, 1e-2] (6 orders of magnitude)**: Arm B (eps=1e-2) disconfirmed mechanism-suppression hypothesis (val_B closer to post-#1138 than pre-#1138 NM-off baseline → NM still fires at eps=1e-2). **Resolution**: NS5 polar decomposition's scale-invariance means R's eigenvector GEOMETRY drives NM conditioning, not absolute scale/regularization floor; eps only shifts eigenvalue floor uniformly, eigenvectors untouched, NS5 absorbs global rescaling. Cross-arm telemetry: R_cond_max=61778 (A) vs 43699 (D) — essentially identical across 6 OOM. **NM-MECHANISM-CHARACTERIZATION WAVE NOW FULLY CONSOLIDATED (7 axes)**: BETA bilateral fence at β=0.95 (#1288) / EPS flat [1e-8, 1e-2] (#1291 this) / LATE_PERIOD NULL-NEG (#1286) / MAX_D_IN LOAD-BEARING (#1240 PP) / RESET_STEP LOAD-BEARING (#1281 PP) / START_STEP monotone NEG (#1277) / END_STEP [3000, 3350) dispensable (#1280). **askeladd REASSIGNED #1338 NM multi-shot R-buffer reset** (`g1r4-askeladd/nm-multi-shot-reset`): natural extension of #1281 single-shot RESET=2345 favorable finding. Tests whether R-staleness is a CONTINUOUS problem across cooldown distribution-shift trajectory vs single-boundary event. 4-arm sequential: A ctrl no-resets / B single-shot {2345} (replicates #1281 winner, N=1 sanity check) / C two-shot {2345, 2700} / D three-shot {2345, 2600, 2900}. Requires adding `NANOGPT_NEWTON_MUON_RESET_STEPS` env var (comma-separated list). Pre-staged decision tree: D < B by ≥0.001 → multi-shot super-additive PP on D / C < B by ≥0.001 → 2-shot sweet spot PP on C / any arm Δ ≤ −0.002 AND val ≤ 3.26614 → PP escalation / multi-shot NULL ≈ B → single-shot captures full R-freshness gain / multi-shot NEG → close productive-NEG. **Cross-chain merge candidate queue cycle-367**: #1240 PP (2/3 pairs done, n=2 mean Δ=−0.003126 STRONGLY FAV, ETA terminal ~21:00-22:00 UTC) / #1281 PP (1/6 done, ETA ~05:00 UTC 27th) / #1286 PP (ETA ~12-16h from cycle 363). In-flight screening: #1318 nezuko stack-compose / #1319 alphonse sub-window / #1297 thorfinn GROUPS (Arm D running) / #1331 frieren β-schedule. **If #1240 PP and #1281 PP and #1286 PP all land favorable → first 3-merge-day of r4 launch since #847**. No new human GH issues.

- **Date:** 2026-05-26 (cycle 366 — 1 stale_wip ack on #1281 edward PP n=3 cooldown-entry R-refresh chain, **1/6 runs terminal with exceptionally clean ctrl anchor**). **#1281 PP chain status** (group `g1r4-edward/cooldown-entry-r-refresh-pp`, ~2.2h into ~11h chain): **s0-A-ctrl (RESET=0) TERMINAL val=3.26424 fs=3150 drift −0.00190 vs production baseline 3.26614** (within ±0.003 envelope on favorable-noise side, same favorable-cohort signature as #1240 PP Arm-D and #1297 Arm-A today) / s0-B-arm (RESET=2345) RUNNING step 575/3350 (~17%) val=3.80 early-normal no anomalies, RESET trigger not yet fired (engages at step 2345 ~1.8h away) / s1-A, s1-B, s2-A, s2-B QUEUED. **Tentative s0-B forecast**: if PP signal preserves at modal ~30-50% attenuation of screening Δ=−0.00225, s0-B val ~3.262-3.263 with paired Δ ∈ [−0.0011, −0.0017]. **G4 (ctrl drift ±0.003) PASS at n=1** with anchor s0-A drift −0.00190; G5 already provisional PASS with s0-A fs=3150 ≤ 3175. G1/G2/G3 PENDING n=3 mean. **3rd merge candidate** in cycle-366 merge queue: (1) #1240 tanjiro PP — 2/3 pairs complete, n=2 mean Δ=−0.003126, P(5/5)≥85%, ETA terminal ~3-4h; (2) #1286 fern H4 PP — launched cycle 363, ETA ~12-16h; (3) **#1281 edward PP — 1/6 terminal, ETA ~05:00 UTC 27th**. **If all 3 PPs land favorable, first 3-merge-day of entire r4 launch since #847**. Cross-chain mechanism story holds: #1281 H2 R-buffer-freshness-at-cooldown-boundary (this chain), #1240 NM coverage-extension max_d_in=4096 + period=5, #1286 NM late-window coverage all converge on COVERAGE + TEMPORAL + R-FRESHNESS as load-bearing axes (per cycle 364 NM-mechanism-characterization-wave consolidation). No new human GH issues. 8 chains active, 0 idle, 0 review-ready.

- **Date:** 2026-05-26 (cycle 365 — 2 stale_wip acks on #1297 thorfinn GROUPS chain + #1240 tanjiro PP chain, **both chains progressed substantially since prior acks with strong mechanism + merge-candidacy signals**). **#1297 thorfinn GROUPS chain 3/4 arms terminal** (group `g1r4-thorfinn/nm-coverage-by-layer-group`, post-#1138 stack, seed 0, n=1): A all (ctrl, NM on attn+MLP=production) TERMINAL 3.26320/3150 drift −0.00294 favorable-noise / **B attn-only (NM on 48 attn matrices only)** TERMINAL 3.26788/3200 Δ_paired_val=**+0.00469 NEG**, Δ_paired_fs=+50 NEG / **C mlp-only (NM on 24 MLP matrices only)** TERMINAL 3.26898/3200 Δ_paired_val=**+0.00578 NEG**, Δ_paired_fs=+50 NEG / **D none (NM off entirely, post-#1138-stack diagnostic)** RUNNING step 475/3350 (~14%) val=3.904 early-normal no anomalies, ETA ~1.5h. **🎯 LAYER-GROUP MECHANISM FINDING**: BOTH attn-only AND mlp-only individually NEG and roughly equivalent in damage (Δ_C − Δ_B = +0.00109 within seed-variance) → **NM is JOINT-LOAD-BEARING ACROSS BOTH LAYER GROUPS**, harm is on a per-architectural-role basis (not per-parameter-count: 24 MLP matrices ≈ 48 attn matrices in load-bearing). **6th NM mechanism axis characterized** (LAYER_GROUPS joint-load-bearing) — joins BETA / EPS / LATE_PERIOD / MAX_D_IN / RESET_STEP / START_STEP / END_STEP for **complete NM mechanism characterization**. Arm D diagnostic critical: val_D ≈ pre-#1138 baseline 3.26756 CONFIRMS NM is the unique load-bearing mechanism in post-#1138 stack; val_D ≈ current baseline 3.26614 would WEAKEN entire NM-mechanism-characterization wave's foundation. Pre-staged decision tree row 3 TRIGGERED (all B/C arms NEG → fence layer-group axis at GROUPS=all current production, Arm D used purely for mechanism characterization) — at chain terminal will close productive-NULL with mechanism characterization (45th no-merge if Arm D ≈ pre-#1138). **#1240 tanjiro PP chain 2/3 PAIRS PAIRED-COMPLETE** with **STRONGER-than-modal signal** (group `g1r4-tanjiro/newton-muon-extension-pp`, ~10h into ~12-14h chain): s0-A 3.265471/3175 + s0-D 3.263604/3150 → Δ_paired_s0=**−0.001867** FAVORABLE / s1-A 3.267161/3175 + **s1-D 3.262776/3150** → Δ_paired_s1=**−0.004385 STRONGLY FAVORABLE** (2.3× typical NM paired delta) / s2-A RUNNING step 600/3350 (~18%) val=3.795 early-normal / s2-D QUEUED. **🎯 Cumulative n=2 mean Δ_paired_val = −0.003126, 2.5× stronger than modal forecast of [−0.0010, −0.0015]**. Mean Arm D val (n=2) = 3.263190 ≤ baseline 3.26614 by 0.00295. **5-gate partial assessment**: G1 (mean ≤ 3.26614)=3.263190 PASS (cushion 0.00295) / G2 ((3.28−μ)√n ≥ 0.004)=0.02377 PASS (margin 5.9×) / **G3 (≥2/3 favorable)=2/2 already irrevocably secured at n=2** ✓ / G4 (ctrl drift ±0.003)=+0.000176 PASS exceptionally clean / **G5 (≥1/3 fs ≤ 3175)=2/2 @ 3150 already secured** ✓. **Probability of clean 5/5 merge ≥ 85%** given current trajectory. Modal n=3 forecast: mean Δ ≈ −0.0025, mean val ≈ 3.26365 → G1 cushion 0.00249, G2 = 0.0249 (6.2× margin). Even s2 adverse case (Δ≈+0.0030 NEG) lands at n=3 mean ≈ −0.00088 → still PASS 4/5 gates. ETA s2 pair terminal ~3-4h, full chain terminal ~21:00-22:00 UTC. **🎯 2nd merge candidate since #847 LIKELY** — would be 1st post-NM-mechanism-characterization-wave merge + 1st compositional NM-stack extension. **Cross-chain merge candidate queue UPDATED cycle 365**: #1240 PP terminal imminent (most-likely 1st to merge), #1281 PP n=3 in flight (ETA ~04:00 UTC 27th), #1286 PP launched cycle 363 (ETA ~12-16h), #1318 stack-compose (nezuko in flight), #1297 GROUPS resolving to productive-NULL not merge candidate, #1331 frieren β-schedule pending. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 364 — #1288 BETA bilateral fence CLOSED productive-NULL **44th no-merge** + frieren REASSIGNED #1331 NM β-schedule follow-up). **#1288 frieren BETA chain TERMINAL all 4 arms** (post-#1138 stack, seed 0, n=1): A ctrl β=0.95 3.26525/3175 drift −0.00089 PASS-CLEAN / B β=0.99 3.26837/3200 Δ=+0.00312 NEG / C β=0.90 3.26725/3200 Δ=+0.00200 NEG / D β=0.999 3.26869/3200 Δ=+0.00344 NEG. **🎯 BILATERAL FENCE with monotone-worse-with-longer-horizon** (D > B > C asymmetric, 1.5× long-side stronger). **Mechanism telemetry validates story**: R_inv_sqrt_norm_mean monotone DECREASE with longer β (A=78.13 / B=63.08 / D=46.80) → R becomes WEAKER preconditioner under long horizons → under-preconditioning in late training. precond_ratio_mean: A=1.099 (sweet spot) / B=0.990 (slightly under) / D=0.927 (clearly under). C=1.122 (over-conditioned from noise, R_cond_max=236378 ≫ A=62k). **🎯 NM-MECHANISM-CHARACTERIZATION WAVE NOW FULLY CONSOLIDATED**: BETA bilateral fence (#1288) + EPS flat (#1291) + LATE_PERIOD bilateral (#1286+#1240) + MAX_D_IN COVERAGE-LOAD-BEARING (#1240 PP + #1286 PP both FAVORABLE) + RESET_STEP R-FRESHNESS LOAD-BEARING (#1281 PP) + START_STEP monotone NEG (#1277) + END_STEP [3000, 3350) dispensable (#1280). **Combined mechanism story FINALIZED**: NM gain from COVERAGE + TEMPORAL + R-FRESHNESS, NOT from scalar HP tuning (β, ε, period all at sweet spots). **frieren REASSIGNED #1331 NM R-EMA-SCHEDULE β-step-down** (`g1r4-frieren/nm-beta-schedule`): direct follow-up of student's suggested follow-up #2, grounded in their R_inv_sqrt_norm telemetry showing under-preconditioning in late training. 4-arm chain testing β=0.95 → β_LATE step-down at cooldown_start: A ctrl β=0.95 const / B β=0.95→0.90 at step 2345 / C β=0.95→0.85 at step 2345 (deeper) / D β=0.95→0.90 at step 2000 (earlier pre-adapt). Adds `NANOGPT_NEWTON_MUON_BETA_LATE` + `NANOGPT_NEWTON_MUON_BETA_LATE_START_STEP` env vars mirroring LATE_PERIOD pattern from #1286. **Hypothesis**: preserve early-training R-buffer stability (β=0.95 sweet spot) WHILE restoring late-training preconditioning responsiveness (β=0.90 during cooldown) — counteracts the under-preconditioning failure mode without inducing early-training over-reaction noise. Pre-staged decision tree: any arm Δ ≤ −0.002 AND val ≤ 3.26614 AND fs ≤ 3175 → PP-PROMOTE (6th merge candidate); MARGINAL band [−0.002, −0.001] → productive-MARGINAL; all NULL/NEG → close productive-NULL (β-schedule axis fenced); D best by ≥ 0.001 → validates early-pre-adapt hypothesis. **Cross-chain merge candidate queue UPDATED**: 5 potential merges in flight (#1240 PP, #1281 PP, #1286 PP launched cycle 363, #1318 nezuko stack-compose, #1297 GROUPS in screening) + #1331 frieren β-schedule as POTENTIAL 6th candidate. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 363 — 🎯 #1286 H4 SCREENING TERMINAL → PP-PROMOTE LAUNCHED on Arm C late_maxd_4096 = 4th merge candidate). **#1286 fern H4 chain TERMINAL all 4 arms** (post-#1138 stack, seed 0, n=1): A ctrl LATE_START=1e9 disabled 3.26555/3175 drift −0.00059 PASS-CLEAN / B late_period_5 only 3.26707/3175 Δ_paired=**+0.00152 PRODUCTIVE-NEG** (period axis fenced) / **🎯 C late_maxd_4096 only 3.26367/3150 Δ_paired=−0.00188 DOUBLE-FAVORABLE on BOTH val and fs axes** (val ≤ production baseline 3.26614 by 0.00247, fs −25 FASTER) / D compound (period=5 + maxd=4096) 3.26660/3175 Δ_paired=**+0.00105 sub-additive NULL** (compound antagonistic: period=5 cancels coverage gain). **🎯 Pre-staged decision tree ROW 2 TRIGGERED**: D worse than C by +0.00293 → PP-PROMOTE Arm C alone, FENCE period axis. **PP-PROMOTE LAUNCHED via send-back to fern**: 6 paired-pod runs Arm C config (`LATE_START_STEP=2400, LATE_MAX_D_IN=4096`, period unchanged), 3 seeds × {A, C} interleaved, W&B group `g1r4-fern/h4-late-coverage-pp`, 5-gate merge criteria identical to #1240 PP. **Mechanism**: LATE_MAX_D_IN=4096 at step 2400 newly preconditions MLP down-proj (d_in=3072) for cooldown window — same mechanism as #1240 Arm B (always-on max_d=4096) but applied LATE-ONLY, saves ~70% NM compute cost. **PP attenuation forecast under #1138 pattern (~50%)**: Δ=−0.00188 → ~−0.00094, modal mean val ≈ 3.26520, G2 stat-sig 0.0256 ≥ 0.004 by wide margin. **Outcome distribution**: 60% MERGE / 25% productive-MARGINAL close / 15% NULL revisit. **Double-favorable val+fs hedge**: if val attenuates heavily, fs (G5 needs only 1/3 seeds ≤ 3175) may still survive. **🎯 Merge candidate queue UPDATED cycle-345 "#1240 only" → cycle-359 "#1240 + #1281 + #1297 + #1286 H4" → cycle-363 "#1240 PP in flight + #1281 PP launched 17:02 UTC + #1286 PP launching now + #1318 stack-compose pending + #1297 GROUPS pending" = up to 5 potential merges in flight in next 24-36h**. **Cross-chain coverage-axis CONFIRMED TWICE**: #1240 always-on max_d=4096 favorable (PP in flight) + #1286 Arm C late-only max_d=4096 favorable (PP launching) — COVERAGE-AXIS-LOAD-BEARING mechanism characterized across both schedules. ETA #1286 PP terminal ~12-16h sequential. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 362 — 1 stale_wip ack on #1291 + 🎯 EPS-AXIS FENCED FLAT across 4-order-of-magnitude span). **#1291 askeladd EPS chain 3/4 arms terminal**: A ctrl eps=1e-4 3.265475/3175 drift −0.00067 PASS-CLEAN / B eps=1e-2 3.266568/3175 Δ=+0.00109 NULL-band / **C eps=1e-6 3.265818/3175 Δ=+0.00034 NULL-band essentially identical to ctrl** / D eps=1e-8 RUNNING step 325/3350 (~10%) val=4.072 NORMAL early-trajectory no divergence. **🎯 EPS-AXIS FLAT NULL ACROSS [1e-6, 1e-2]**: 4-order-of-magnitude span produces only NULL-band Δ, all 3 arms land fs=3175 (baseline-matching). Mechanism implication: NS5 polar decomposition's scale-invariance dominates eps-tuning — what matters is R's eigenvector GEOMETRY (encoding X^T X structure), not its absolute scale or regularization floor. **Arm D eps=1e-8 critical numerical-stability diagnostic**: at 1e-8 << typical R eigenvalue floor ~1e-5, (R+ε·I)^{−1/2} may unmask near-zero-eigenvalue instability. If Arm D NaN/diverges → numerical stability boundary; if Arm D NULL → eps-axis fully flat across 6 orders of magnitude. ETA Arm D terminal ~21:00 UTC. **🎯 Cross-chain NM-HP-spectrum-characterization wave consolidating**: BETA bilateral fence (#1288), EPS flat (#1291), LATE_PERIOD harmful (#1286), LATE_MAX_D_IN FAVORABLE coverage-axis (#1286 + #1240), RESET_STEP FAVORABLE R-freshness-axis (#1281), START_STEP monotone NEG (#1277), END_STEP [3000, 3350) dispensable (#1280). **Combined mechanism story FINALIZED**: NM gain comes from COVERAGE (d_in expansion) + TEMPORAL (continuous in [2000, 3000)) + R-FRESHNESS (reset at cooldown entry). NOT from BETA/EPS/LATE_PERIOD scalar tuning. Post-#1138 stack's NM HPs β=0.95 / eps=1e-4 / period=10 are at sweet-spot regions. **Pre-staged decision tree #1291**: Arm D NULL/NEG → close productive-NULL 44th no-merge; FAVORABLE rare → explore small-eps; divergence → record numerical floor. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 361 — #1280 H3 pre-crossing burst NM CLOSED productive-NULL **43rd no-merge** + alphonse REASSIGNED #1319 H5 NM burst sub-window decomposition). **#1280 alphonse H3 chain TERMINAL all 4 arms** (post-#1138 stack, seed 0, n=1): A ctrl always-on 3.26823/3200 drift +0.00209 PASS-strong / B [2400, 3000) 600-step 3.26895/3200 Δ_paired=**+0.00072 NULL** (82% NM compute saved, no val/fs degradation) / C [2400, 2700) 300-step 3.26984/3225 Δ_paired=**+0.00161 borderline-NEG** (too tight, fs leaks +25) / D [2200, 3200) 1000-step 3.26753/3200 Δ_paired=**−0.00070 NULL-favorable** (sub-threshold). **🎯 Pre-staged decision tree resolution**: no signal threshold met → productive-NULL on window-axis. **🎯 KEY EMPIRICAL FINDING — minimum-sufficient pre-crossing burst is ~600 steps from step 2400**: NM benefit is **late-phase-concentrated** in [2400, 3000); sub-300-step leaks signal; widening to 1000-step gives sub-threshold favorable but no PP escalation. **🎯 Cross-chain mechanism triangulation now COMPLETE (H1 + H2 + H3 directive cluster)**: (1) #1281 H2 RESET=2345 Δ=−0.00225 FAVORABLE — R-fresh at cooldown entry; (2) #1280 H3 [2400, 3000) Δ=+0.00072 NULL — removing NM in [3000, 3350) cooldown-finishing is harmless; (3) #1277 H1 START=2000 Δ=+0.00095 NULL → START=2400 Δ=+0.00243 NEG monotone — fresh R + delayed activation harmful, more pre-cooldown NM helpful, less harmful. **Convergent mechanism story**: NM is continuously load-bearing in [2000, 3000) with R-buffer-freshness at cooldown-transition (~step 2345-3000) being the load-bearing factor; pre-2000 and post-3000 NM are dispensable. **Directive (Issue #1261) H3 bullet "short burst before expected crossing" EMPIRICALLY ANSWERED**: burst CAN substitute for always-on at [2400, 3000) with NO val/fs degradation, but CANNOT EXCEED always-on. The 'help BEFORE crossing' thesis is PARTIALLY REFUTED for window-axis: NM is not a plateau-attack mechanism per se, but a continuously-load-bearing preconditioner whose late-phase dominates. **Compute-aware downstream value**: 82% NM compute reduction could be meaningful wallclock win for longer-step runs — deferred sub-merge-eligible. **alphonse REASSIGNED #1319 H5 NM burst sub-window decomposition** (`g1r4-alphonse/nm-burst-subwindow`): tests 3 different 300-step sub-windows to localize the load-bearing phase WITHIN [2400, 3000) — Arm A ctrl always-on / Arm B [2700, 3000) post-2700 burst / Arm C [2800, 3100) cooldown-transition spanning (most novel — tests bf16 transition-itself hypothesis) / Arm D [2500, 2800) middle-segment anchor. ZERO NEW CODE (uses existing `_START_STEP` + `_END_STEP` from #1280). Pre-staged 4-row decision tree: PP-PROMOTE if any arm Δ ≤ −0.002 / productive-MARGINAL if Δ ∈ [−0.002, −0.001] / cooldown-transition-mechanism-confirmation if Arm C beats B/D by ≥0.0010 / productive-NULL if all NULL/NEG. **Cross-chain inventory unchanged**: 4 merge candidates in flight (#1240 PP, #1281 PP, #1286 H4 Arm C, #1297 GROUPS) + 1 compositionality test (#1318 nezuko) + 4 mechanism characterization chains (#1288 BETA, #1291 EPS, #1297 GROUPS, #1318 stack-compose) + 1 sub-window characterization (this #1319). 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 360 — #1277 H1 step-gated NM CLOSED productive-NEG **42nd no-merge** + #1281 H2 PP-PROMOTE LAUNCHED + nezuko REASSIGNED #1318 NM stack-compositionality 2×2 factorial). **#1277 nezuko H1 chain TERMINAL all 4 arms** (post-#1138 stack, seed 0, n=1): A ctrl START=0 3.26719/3175 drift +0.00105 PASS-CLEAN / B START=2000 3.26814/3200 Δ_paired=**+0.00095 NULL-band** / C START=2200 3.26967/3200 Δ_paired=**+0.00248 PRODUCTIVE-NEG** / D START=2400 3.26962/3200 Δ_paired=**+0.00243 PRODUCTIVE-NEG saturated with C**. **🎯 MONOTONE NEG-WITH-SATURATION pattern**: more pre-cooldown NM is HELPFUL, less is HARMFUL. **🎯 CRUCIAL CROSS-CHAIN VALIDATION**: H1 (delay) and H2 (refresh) NOT THE SAME MECHANISM — H1 monotone NEG rules out the confound 'maybe #1281 H2 wins because less NM in pre-cooldown window'. Therefore **#1281 H2's favorable signal is specifically R-buffer-freshness-at-distribution-shift**, not less-NM-in-pre-cooldown. **Directive (Issue #1261) H1 bullet "Newton-Muon only after X" EMPIRICALLY FENCED for START_STEP ≥ 2000**. Excellent student mechanism reconciliation interpreting H1 fence as high-information validator of H2 favorable. **#1281 edward PP-PROMOTE LAUNCHED 17:02 UTC** on Arm B RESET=2345 config (canonical post-#1138 NM stack + `NANOGPT_NEWTON_MUON_RESET_STEP=2345`, 6 paired-pod runs seeds 0/1/2 interleaved, ETA ~04:00 UTC 2026-05-27, group `g1r4-edward/cooldown-entry-r-refresh-pp`). PR converted to draft pending terminal SENPAI-RESULT — modal forecast PP mean Δ ∈ [−0.0011, −0.0017] → G2 stat-sig 0.0266 ≥ 0.004 by wide margin given PP attenuation 30-50% pattern. **nezuko REASSIGNED #1318 NM stack-compositionality 2×2 factorial** (`g1r4-nezuko/nm-stack-compose`): directly tests composition of two confirmed favorable mechanisms within single training run — Arm A ctrl / Arm B reset_only (RESET_STEP=2345 replicates #1281 H2 Arm B) / Arm C cov_only (LATE_START=2400 + LATE_MAX_D_IN=4096 replicates #1286 H4 Arm C) / Arm D compound (BOTH simultaneously). Pre-staged 4-row decision tree: D super-additive (val_D < val_C by ≥0.0005) → PP-PROMOTE compound (5th merge candidate); D additive (val_D ≈ min(B,C)) → PP-PROMOTE single-best cheaper-mechanism; D destructive (val_D > max(B,C)) → close productive-NEG mechanisms NOT orthogonal; mixed NULL → close productive-NULL. **Cross-chain context — merge candidate queue**: cycle-345 "#1240 only" → cycle-355 "#1240 + #1281 + #1297" → cycle-359 "#1240 PP + #1281 H2 + #1286 H4 + #1297 GROUPS" → **cycle-360 stack-compositionality test resolves whether D compound becomes 5th candidate or pick cheaper of #1281/#1286 singles**. **In-flight chain inventory**: #1240 PP (n=1 pair complete Δ=−0.001866, n=2 in progress) / #1281 PP (just launched 17:02 UTC) / #1286 H4 Arm D running ~31% / #1288 BETA Arm D running ~15% / #1291 EPS Arms C/D pending / #1297 GROUPS Arm B+running / #1318 nezuko stack-compose newly assigned. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 359 — 🎯 #1286 H4 ARM C COVERAGE-ONLY LATE-WINDOW TERMINAL FAVORABLE → 4th merge candidate emerges + #1288 BETA bilateral fence confirmed). **#1286 H4 chain progression**: A ctrl LATE_START=1e9 disabled 3.26555/3175 PASS-CLEAN / B late_period=5 only 3.26707/3175 Δ_paired=+0.00152 NULL-NEG / **🎯 C late_maxd_4096 only 3.26367/3150 Δ_paired_val=−0.00188 FAVORABLE-MARGINAL on BOTH val and fs axes** (val ≤ production baseline 3.26614 by 0.00247, fs −25 FASTER) / D compound (period=5 + maxd=4096) running ~31% pre-window. **🎯 LATE-WINDOW COVERAGE GAIN CONFIRMED**: expanding NM coverage to MLP down-proj (d_in=3072) starting at step 2400 produces Δ ≈ −0.00188 — confirms #1240 coverage-axis mechanism transfers to a LATE-ONLY schedule (saves ~70% NM compute cost while keeping val improvement). **#1288 BETA chain progression**: A ctrl β=0.95 3.26525/3175 PASS-CLEAN / B β=0.99 long 3.26837/3200 Δ=+0.00311 NULL-NEG / **C β=0.90 short 3.26725/3200 Δ=+0.00200 NULL-NEG** / D β=0.999 very-long running 15%. **🎯 BETA BILATERAL FENCE CONFIRMED at canonical β=0.95 effective memory ~20 steps** (long-side asymmetric stronger 1.5× than short-side, post-#1138 stack tolerates faster adaptation better). **MERGE CANDIDATE QUEUE EXPANSION**: cycle-345 "#1240 only" → cycle-355 "#1240 + #1281 + #1297" → **cycle-359 "#1240 PP + #1281 H2 + #1286 H4 + #1297 GROUPS" — up to 4 potential merges in flight**, ETA all complete ~24-36h. **Pre-staged PP-PROMOTE protocol frozen for #1286 candidate Arm C**: LATE_START_STEP=2400, LATE_MAX_D_IN=4096 (winning config), 6 paired-pod runs s0-A → s0-C → s1-A → s1-C → s2-A → s2-C, identical 5-gate criteria. **#1286 Arm D decision tree** (pending terminal): D super-additive → PP on D compound / D ≈ C → PP on C coverage-only (simpler) / D > C → period=5 harmful, PP on C alone + fence period. **NM-mechanism-characterization wave integration**: BETA bilateral, EPS flat, LATE_PERIOD harmful, LATE_MAX_D_IN FAVORABLE — gain comes from COVERAGE axis (confirmed twice now: #1240 always-on + #1286 late-only), NOT from BETA/EPS/PERIOD tuning. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 355 — 🎯 #1281 H2 CHAIN 3/4 ARMS TERMINAL WITH DOUBLE-FAVORABLE — PP-PROMOTE on Arm B HIGHLY LIKELY). **#1281 chain progression**: A ctrl RESET=0 3.26731/3200 drift +0.00117 PASS-CLEAN / **B RESET=2345 (exact cooldown_start) 3.26506/3175 Δ_paired_val=−0.00226 FAVORABLE-MARGINAL** / **C RESET=2400 (55 after) 3.26590/3175 Δ_paired_val=−0.00142 FAVORABLE-MARGINAL** / D RESET=2200 (145 before) running 15%. **🎯 MECHANISM DOUBLY CONFIRMED within H2 chain**: both RESET=2345 AND RESET=2400 favorable with identical fs=3175 match → R-buffer-reset-at-cooldown-entry is GENUINE not single-arm noise. Monotone strength: RESET=2345 (exact) > RESET=2400 (55 late) > ctrl. Mechanism: resetting R-buffer at cooldown_start allows fresh second-moment estimator to converge on cooldown-distribution gradient stats within ~20 effective-memory-window steps before cooldown completion at ~step 3000 → optimal preconditioning. **Pre-staged PP-PROMOTE protocol frozen**: config RESET_STEP=2345 (winning Arm B) + canonical NM env (NM=1, LR_SCALE=1.0, UPDATE_PERIOD=10, MAX_D_IN=1024); 6 paired-pod runs seeds 0/1/2 interleaved s0-A → s0-B → s1-A → s1-B → s2-A → s2-B; 5-gate merge criteria (G1 mean ≤ 3.26614 / G2 (3.28−μ)√3 ≥ 0.004 / G3 ≥ 2/3 seeds favorable / G4 ctrl drift ±0.003 / G5 ≥ 1/3 fs ≤ 3175). Expected PP attenuation 30-50% (like #1138, #1240) → PP mean Δ ∈ [−0.0011, −0.0017] → mean val ≈ 3.26464 → G2 = 0.0266 ≥ 0.004 by wide margin. **Arm D critical for R-buffer mechanism characterization** (RESET=2200 145 steps pre-cooldown): NEG → FAVORABLE region narrow at cooldown_start (RESET-too-early captures pre-cooldown stats, harmful) / NULL → FAVORABLE region wider but Arm B still best / FAVORABLE → RESET-anywhere-before-cooldown helps. **🎯 3rd merge candidate since #847 LIKELY** joining #1240 PP n=3 (in flight ~6h, seed 0 pair complete Δ=−0.001866 FAVORABLE) and possibly #1297 GROUPS. **Merge candidate queue revision**: from cycle-345 "#1240 PP only LIKELY" to cycle-355 "#1240 + #1281 PP LIKELY + #1297 POSSIBLE" — 3 potential merges since #847. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 354 — 🎯 IMPORTANT CYCLE-350 META-PATTERN REVISION + 7 stale_wip acks across cycles 351-354 + #1240 PP seed 0 pair complete). **🎯 #1277 H1 Arm B terminal val=3.26814** (NOT 3.27596 as cycle-347 partial-trajectory forecast suggested) — val dropped 0.00782 in last 4% of training during cooldown finishing → **Δ_paired_val=+0.00096 NULL-band** (NOT +0.00982 NEG). Updated H1 chain progression: A 3.26719 (PASS) → B START=2000 +0.00096 NULL → C START=2200 +0.00248 NEG → D START=2400 RUNNING. **MONOTONE NULL→NEG with later START_STEP confirmed**. **REVISED CROSS-CHAIN META-PATTERN (more precise mechanism)**: R-buffer adaptation timing across cooldown transition is load-bearing, but the optimal intervention is **RESET-AT-COOLDOWN-ENTRY** not delayed activation. (1) **#1281 H2 Arm B RESET=2345 Δ=−0.00225 FAVORABLE-MARGINAL**: R wiped clean at cooldown_start → captures pure cooldown-distribution stats within ~20 steps → optimal preconditioning. (2) **#1280 H3 Arm B [2400, 3000) Δ=+0.00072 NULL**: fresh R activated at 2400 (similar to H2 RESET) but deactivated at 3000 before cooldown completion → equivalent to H2 protection. (3) **#1277 H1 Arm B START=2000 Δ=+0.00096 NULL**: 345 steps of pre-cooldown stats accumulate in R before cooldown → R dominated by pre-cooldown distribution at cooldown entry → moderate mismatch. (4) **#1277 H1 Arm C START=2200 Δ=+0.00248 NEG**: only 145 steps adaptation → less converged R → worse. **Additional confirmations from #1288 BETA + #1286 LATE_PERIOD chains**: #1288 Arm B β=0.99 Δ=+0.00311 NULL-NEG (slower R-update at cooldown harmful); #1286 Arm B late_period=5 Δ=+0.00152 NULL-NEG (faster R-update at cooldown harmful) — **BOTH deviations from canonical β=0.95+period=10 hurt → canonical R-cadence at load-bearing optimum**. **#1240 tanjiro PP n=3 seed 0 pair COMPLETE**: s0-A 3.265471/3175 + s0-D 3.263604/3150 → **Δ_paired_val=−0.001866 FAVORABLE on BOTH axes**. All partial G-gates passing (G1 G3 G4 G5), G2 stat-sig pending n=3 mean. Projected n=3 PP mean Δ ≈ −0.00146 under modal forecast → mean val ≈ 3.26468 → G2 = 0.0266 ≥ 0.004 by wide margin. **2nd merge candidate since #847 LIKELY**, ETA ~22:30 UTC. **Lesson learned**: partial-trajectory val readings during pre-cooldown-finishing phase (>3% of training remaining) are unreliable predictors of terminal val — cooldown can drop val by 0.005-0.008 in last 100-150 steps. Avoid forecasting terminal Δ from partial-trajectory data. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 350 — 1 stale_wip ack on #1280 alphonse H3 + 🎯 **CROSS-CHAIN META-PATTERN EMERGING** across H1+H2+H3 directive cluster). **#1280 H3 chain 2/3-4 arms terminal**: A ctrl always-on TERMINAL 3.26823/3200 drift +0.00209 PASS-strong / **B window [2400, 3000) TERMINAL 3.26895/3200 Δ_paired_val=+0.00072 NULL** (essentially identical to always-on NM despite NM OFF for 83% of training) / C window [2400, 2700) running step 1000/3350 (~30%) / D not observed (chain may be 3-arm). **🎯 CROSS-CHAIN H1+H2+H3 INTEGRATION**: three independent NM-window interventions converge on **R-buffer-history-vs-gradient-distribution mismatch at bf16 cooldown transition (~step 3000) as load-bearing**: **#1281 H2 Arm B RESET_STEP=2345 Δ_paired_val=−0.00225 FAVORABLE-MARGINAL** (refreshing R-buffer at cooldown entry → fresh second-moment adapts to changing gradient distribution); **#1280 H3 Arm B window [2400, 3000) Δ=+0.00072 NULL** (deactivating NM at step 3000 BEFORE cooldown-finishing transition spares damage from stale R); **#1277 H1 Arm B START_STEP=2000 Δ=+0.00982 NEG** (fresh R-buffer at step 2000 carries pre-cooldown stats into cooldown finishing → preconditions damage). **Mechanism story**: R = EMA(X^T X) at β=0.95 has effective memory ~20 steps; during stable training, R adapts smoothly to gradient distribution. At the bf16 cooldown completion (~step 3000), the gradient distribution shifts substantially as parameters near their final values and the LR schedule completes; R-buffer that was fresh-initialized at step 2400 carries 600 steps of pre-cooldown statistics into the cooldown transition, causing NM to over-precondition. Always-on NM (Arm A baseline) avoids this because R has continuously refreshed throughout training and the cooldown transition is gradient-smooth. **Pending H1+H2 Arms C/D terminals to confirm**: if #1281 Arm C RESET_STEP=2400 and Arm D RESET_STEP=2200 ordered favorability, brackets the optimal R-reset point. If #1277 Arm C/D (later STARTs 2200/2400) show monotonically WORSE Δ, confirms fresh-activation+stale-R-into-cooldown is the harmful mechanism. **Pre-staged actions when chains terminal**: #1281 likely PP-PROMOTE on best RESET_STEP (3rd merge candidate alongside #1240 + potentially #1297 GROUPS), #1280 likely close productive-NULL (window-axis fenced), #1277 likely close productive-NEG (H1 hypothesis disconfirmed). 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 344 — #1231 thorfinn body Muon momentum bias correction post-#1138 2-arm confirmation CLOSED productive-NEG **41st no-merge** + thorfinn REASSIGNED #1297 NM coverage-by-layer-group). **#1231 2-arm chain TERMINAL (post-#1138 stack, seed 0, n=1)**: **A′ ctrl 3.26611/3175 drift −0.00003 EXCEPTIONALLY CLEAN** (cleanest single-seed in entire post-#847 cohort, within ±0.00003 of n=3 baseline 3.26614) / **C′ warmup100 3.26809/3200 Δ_paired=+0.00198 PRODUCTIVE-NEG** (above +0.0015 fence threshold AND val_C′=3.26809 > 3.26764). **Per pre-staged 4-row decision tree row 4 TRIGGERED** (both conditions satisfied). **🎯 HEADLINE: STACK-DEPENDENT SIGN-REVERSAL of bias-correction × Newton-Muon composition**: PRE-#1138 (NM=off) C warmup100 Δ=−0.00294 FAVORABLE → POST-#1138 (NM=on) C′ warmup100 Δ=+0.00198 NEG → **Δ-of-Δ = +0.00492 across stacks** (~4σ swing, far above noise envelope 2σ ≈ 0.0024). **Excellent student mechanism interpretation**: NM does `grad → R^{−1/2}·grad` (pre-EMA, right-side input precondition) + bias correction does `m_t → m_t / (1 − β^t)` (post-EMA, magnitude scaling). When NM is OFF, bias amplification (20× at step 1 → 1.4× at step 25 → 1.006× at step 100) provides genuine momentum-undersize correction; when NM is ON, R^{−1/2} already reshapes gradient magnitude into well-conditioned scale, additional bias-amplification produces **over-magnified m_t entering NS5** → perturbs polar direction during critical first-cooldown approach (cooldown_start_frac=0.7 ↔ step 2345). Telemetry validates mechanism fired correctly (correction_ratio 20.0× → 1.0060× through step 100, then off). **Hypothesis 3 (compositional NM-stack mechanism) REJECTED at this seed**; Hypothesis 1 (cooldown-boundary perturbation) consistent with +25 fs slowdown. **A′ drift −0.00003 is textbook-clean reproducibility of post-#1138 stack** — removes "favorable seed draw" confound from PRE-#1138 Arm A finding. **thorfinn REASSIGNED #1297 NM coverage-by-layer-group sweep** — adds `NANOGPT_NEWTON_MUON_GROUPS` env var (values `all|attn|mlp|none`), 4-arm at A all ctrl + B attn-only + C MLP-only + D none diagnostic. Tests where NM''s value comes from in the architecture: attn-side preconditioning (48 attn matrices d_in=768), MLP-side (24 MLP matrices, 12 with d_in=768 + 12 with d_in=3072), or both jointly. **Arm D is critical post-#1138-stack diagnostic** — if val_D matches pre-#1138 baseline ~3.26756, confirms NM is the unique load-bearing mechanism in post-#1138 stack. Joins #1288 BETA + #1291 EPS as the **NM-mechanism-characterization wave** — after all 3 close, NM fully characterized across (temporal H1/H2/H3, d_in coverage H4, R-buffer EMA horizon BETA, R-buffer regularization EPS, layer-group coverage GROUPS) axes. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 342 — #1246 askeladd Gradient Centralization Pre-NS5 CLOSED productive-MARGINAL **40th no-merge** + askeladd REASSIGNED #1291 NM eps regularization sweep). **#1246 chain TERMINAL all 4 arms (post-#1138 stack, seed 0, n=1)**: A ctrl `none` 3.26750/3200 drift +0.00136 PASS-strong (within ±0.0003 of cohort ctrls) / **B row 3.26601/3175 Δ_paired=−0.00149 PRODUCTIVE-MARGINAL** (∈ [−0.002, −0.001] band, val ≤ baseline 3.26614 by 0.00013, fs matches baseline exactly, rel_change 0.08–0.17 strong mechanism firing) / **C col 3.27273/3250 Δ=+0.00523 PRODUCTIVE-NEG** (col-mean structure weak ~0.03 rel_change, col-centering destroys useful per-column variance) / **D both 3.27465/3275 Δ=+0.00715 PRODUCTIVE-NEG** (D−B=+0.00864 NON-super-additive, col-mean post-row destroys NS5 conditioning). **Per pre-staged decision tree** (advisor stale_wip ack #3): Δ_paired ∈ [−0.002, −0.001] → productive-MARGINAL close (NOT escalating to PP n=3). **GRADIENT-CENTRALIZATION-PRE-NS5 axis 1-closure observation FAVORABLE-MARGINAL on row direction** (not a fence — direction-correct but sub-threshold). **Three findings**: (1) First non-NM-internal compositional NM-stack extension showing favorable direction even if sub-threshold; (2) body Muon gradients have strong row-mean structure but weak col-mean structure (3× rel_change asymmetry); (3) Post-#1138 stack approaching local conditioning ceiling — additional pre-NS5 GC gives diminishing returns. **Directive alignment (Issue #1261)**: fs_B=3175 matches baseline exactly → GC row-center does NOT improve FFS, only modestly improves val → NOT a "help before crossing" mechanism → close-without-escalation is directive-correct. **askeladd REASSIGNED #1291 NM eps regularization strength sweep** (`NANOGPT_NEWTON_MUON_EPS` 4-arm at A=1e-4 ctrl/B=1e-2 soft/C=1e-6 hard/D=1e-8 very-hard). **Zero new code** — env var exists at `train_gpt_simple.py:603`. Tests whether canonical NM eps=1e-4 is at sensitivity-curve sweet spot or operates in flat region. Arm B is a critical mechanism diagnostic: if val_B matches pre-#1138 baseline 3.26756, confirms eps=1e-2 fully suppresses NM (mechanism actively firing). **Joins #1288 frieren BETA sweep as the NM-internal-HP-spectrum-sweep wave** — after both close, NM mechanism characterized across (temporal H1/H2/H3, coverage H4, R-buffer EMA horizon BETA, R-buffer regularization EPS) axes. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 339 — #1243 frieren AdEMAMix-aux CLOSED productive-NEG **39th no-merge** + frieren REASSIGNED #1288 NM R-buffer EMA horizon sweep; **#1240 tanjiro screening_complete_pp_pending posted**). **#1243 chain TERMINAL all 4 arms (post-#1138 stack, seed 0, n=1)**: A ctrl 3.26688/3175 drift +0.00074 PASS-strong (fs matches baseline exactly, cleanest ctrl-fs match in cohort) / **B lm_head α=5 mech-lead 3.26921/3200 Δ=+0.00233 NULL-band-borderline** (just above +0.0015 ceiling, fs Δ=+25 slower) / **C all-aux α=5 3.27086/3225 Δ=+0.00398 PRODUCTIVE-NEG scope-monotone-regressive** (B mild→C wider; embed-anchor `EMBED_INIT_ANCHOR_LAMBDA=0.001` hostile to slow-EMA inertia on embeddings) / **D lm_head α=2 3.26658/3175 Δ=−0.00030 NULL** (α scaling kills mechanism, no useful α ∈ [2,5] window). **FIRST-MOMENT-DUAL-EMA axis CLOSED for aux groups at canonical β3=0.9999 horizon** — slow EMA effective horizon ~10k steps exceeds 3350-step training, m_slow always in early-averaging regime → no useful information beyond AdamW's single β1=0.8 EMA. **9-mechanism lm_head/aux optimizer-zoo cluster now fully characterized**: #1100 WD / #1153 Cautious / #1155 MARS / #1175 v_min / #1192 row-norm / #1210 AdaBelief / #1232 Power AdamW / #1233 Lion / #1243 AdEMAMix — all NULL or PRODUCTIVE-NEG. Excellent student craftsmanship: dual-EMA wrapper with bit-identical fallback, careful telemetry (slow_contribution ratio rising over training), honest mechanism analysis tying scope-regression to embed-anchor hostility, suggested follow-up `β3=0.999` short-horizon variant appropriately deferred per Issue #1261 directive. **frieren REASSIGNED #1288 NM R-buffer EMA horizon sweep** — uses **existing** `NANOGPT_NEWTON_MUON_BETA` env var (zero new code), 4-arm: A=0.95 ctrl + B=0.99 long horizon + C=0.90 short horizon + D=0.999 very long horizon. Tests whether canonical β=0.95 R-buffer EMA is FFS-load-bearing or whether shorter horizons (faster adaptation in cooldown) or longer horizons (more stable second-moment estimate) help. NM-mechanism-aligned per directive (extends #1240 Arm D compound mechanism characterization rather than zoo-ing on aux). **Status #1240 tanjiro**: posted `screening_complete_pp_pending` SENPAI-RESULT — Arm D compound TERMINAL screening complete; PP n=3 launch pending per pre-staged protocol (cycle 338); **2nd merge candidate since #847 still imminent**. 8 chains active, 0 idle, 0 review-ready. No new human GH issues.

- **Date:** 2026-05-26 (cycle 338 — 1 stale_wip ack + 1 pre-PP escalation forecast). **🎯 #1240 tanjiro Arm D compound TERMINAL OBSERVED IN W&B**: val=3.26474 fs=3175 (run `w7pvgda0`) → Δ_paired_val=−0.00287 STRONGEST single-arm signal of cycle 333-338 + Δ_vs_baseline=−0.00140 FAVORABLE. **Pre-staged decision tree row 2 TRIGGERED** ('D val ≤ B − 0.0005' satisfied at boundary: 3.26474 ≤ 3.26479). Compound additivity decomposition: Δ_B + Δ_C = −0.00276 ≈ Δ_D −0.00287 → **purely additive, FFS-VAL ORTHOGONALITY validated** (coverage and period are independent mechanisms). Posted pre-staged PP n=3 protocol to PR #1240 (compound config `MAX_D_IN=4096 + UPDATE_PERIOD=5`); PP attenuation cushion +0.00134 above #1138's 52% attenuation pattern → modal forecast PP mean Δ ∈ [−0.00100, −0.00150] → **2nd merge candidate since #847 imminent** (would be first compositional NM-stack extension). Waiting for student terminal SENPAI-RESULT marker before formal merge eligibility (status remains WIP per partial-prose merge rule). **#1231 thorfinn 2-arm post-#1138 confirmation chain Arm A' ctrl TERMINAL val=3.26611 drift −0.00003 EXCEPTIONALLY CLEAN** (cleanest single-seed ctrl in entire post-#847 cohort, within ±0.00010 of n=3 baseline mean 3.26614) — confirms post-#1138 stack reproduces under fresh seeds, removes any 'favorable seed draw' confound on PRE-#1138 Arm A. **Arm C' warmup100 running step ~175/3350 (~5%)** val~3.5 normal early-trajectory, chain ETA ~5-6h; pre-staged 4-row decision tree posted (≤−0.002 PP / marginal close / NULL close / NEG close). 8 chains active, 0 idle, 0 review-ready. No new human GH issues. **2 potential merges in flight**: #1240 Arm D compound (PP imminent) + #1231 thorfinn warmup100 (Arm C' pending).

- **Date:** 2026-05-26 (cycle 337 — #1233 fern Lion CLOSED productive-NEG 38th no-merge + fern REASSIGNED #1286 H4 late-window NM tune; **🎯 ALL 4 H1-H4 DIRECTIVE-ALIGNED HYPOTHESES NOW IN FLIGHT**). **#1233 fern Lion lm_head chain TERMINAL all 4 arms** (post-#1138 stack, clean re-launch after rebase): A ctrl 3.26564/3175 drift **−0.00050 PASS-strong cleanest in cohort** / B Lion LR=0.001 3.27340/3250 Δ=+0.00776 PRODUCTIVE-NEG / C Lion LR=0.0005 3.27271/3250 Δ=+0.00707 PRODUCTIVE-NEG (half-LR almost as harmful, NOT LR-tuning fence) / **D Lion-Cautious 3.28185/−1 (NEVER CROSSED 3.28) Δ=+0.01621 STRONG PRODUCTIVE-NEG** — Arm D REVERSED forecast (Cautious mask hypothesized to salvage, instead made Lion WORSE by +0.00845). Telemetry: D lion_m_norm 31% higher than B confirms 1/frac re-norm (~1.45×) scales sign-only updates → overshoots. **SIGN-BASED-OPTIMIZER-LM-HEAD axis fully fenced 3-direction** — joins #1153 Cautious in lm_head SIGN-BASED/FILTERING regression cluster (5 lm_head sign/mask arms total all NEG). Excellent student craftsmanship: clean rebase recovery via force-with-lease, proactive env var typo detection, deep mechanism telemetry, honest mechanism analysis tying failure to lm_head Zipfian magnitude-adaptation requirement. **fern REASSIGNED #1286 H4 Late-window NM coverage+period tune** per Issue #1261 directive bullet (4) "coverage/period tuned for steps 2400-3000". Adds 3 new env vars: `NANOGPT_NEWTON_MUON_LATE_PERIOD` + `NANOGPT_NEWTON_MUON_LATE_MAX_D_IN` + `NANOGPT_NEWTON_MUON_LATE_START_STEP`. 2×2 mini-factorial: A ctrl + B late_period_5 (period axis only) + C late_maxd_4096 (coverage axis only) + D late_compound (both transition at 2400). Directly tests whether FFS-VAL ORTHOGONALITY findings (#1240 cycle 333: coverage drives val, period drives FFS) are PER-WINDOW load-bearing or always-on. Requires runtime hook activation gating (more substantial code change than #1280/#1281, but fern's craftsmanship handles it). **🎯 ALL 4 H1-H4 DIRECTIVE-ALIGNED HYPOTHESES NOW IN FLIGHT**: H1 #1277 nezuko (START_STEP) + H2 #1281 edward (RESET_STEP) + H3 #1280 alphonse ([START, END]) + H4 #1286 fern (LATE_PERIOD + LATE_MAX_D_IN). Plateau-attack via Issue #1261 directive now FULLY MOBILIZED. 8 chains active, 0 idle, 0 review-ready.

- **Date:** 2026-05-26 (cycle 335 — 2 closures + 2 reassignments + 1 stale_wip ack; **3/4 directive-aligned hypotheses now in flight**). **#1244 alphonse Zipfian-LR-lm-head CLOSED productive-NEG (36th no-merge)** dual-NEG bidirectional fence: A ctrl 3.26692 drift +0.00078 PASS-strong / **B log_freq 3.28909 Δ=+0.02217 CATASTROPHIC** (frequent rows up to 4.68× LR amplification destroys Zipfian magnitude prior the canonical Adam denominator already encodes) / **C inv_sqrt_freq 3.28252 Δ=+0.01560 HARMFUL** (rare rows up to 4.75× LR amplification, less severe but still NEG); Arm D capped_log correctly self-aborted by student per Issue #1261 directive ("avoid lm_head optimizer zoo unless tied to NM"). **ZIPFIAN-AWARE-PER-ROW-LR axis FENCED bidirectionally** — joins MAGNITUDE-EQUALIZING-ACROSS-ROWS sub-cluster fence with #1192 row-norm (both directions of "modify lm_head row magnitudes" catastrophic; Zipfian magnitude prior MUST be preserved). Student mature judgment: caught env var typo at PR launch (`_PERIOD` → `_UPDATE_PERIOD`) AND self-aborted Arm D recognizing directive misalignment. **alphonse REASSIGNED #1280 H3 Pre-crossing burst NM** — window-bounded `[NM_START_STEP, NM_END_STEP]` activation sweep at 0/2000/2400/2200 with end at 10⁹/3000/2700/3200 (Arm A always-on ctrl + B burst2400_3000 600-step + C burst2400_2700 300-step minimal + D burst2200_3200 1000-step wider), directly tests Issue #1261 directive bullet (3) "short burst before expected crossing". Adds `NANOGPT_NEWTON_MUON_END_STEP` env var on top of nezuko's `_START_STEP`. **#1236 edward PER-LAYER-DEPTH-CALIBRATED-LR CLOSED productive-NEG (37th no-merge)** 3-direction fence: A ctrl 3.26835 drift +0.00221 PASS / B asc03 Δ=+0.00438 PRODUCTIVE-NEG strong / C desc03 Δ=+0.00159 PRODUCTIVE-MARGINAL / **D ushape05 Δ=+0.00576 PRODUCTIVE-NEG strongest** (combines asc+desc harms at scale=0.5, matches advisor pre-staged modal forecast [+0.003, +0.006] exactly). Severity ordering asc<desc<ushape; 2.75× asymmetry confirms NS5 already provides implicit depth calibration via `ns_iters=12→16 + late_peak` shape — manual depth-LR fights this, post-#1138 stack already near-optimal. Student honest closing analysis acknowledged this correctly. **edward REASSIGNED #1281 H2 Cooldown-entry R-buffer refresh** — single-shot reset of Newton-Muon's R = EMA(X^T X) buffer at cooldown_start (step 2345) per directive bullet (2). Adds `NANOGPT_NEWTON_MUON_RESET_STEP` env var, 4-arm: A ctrl RESET=0 (off) + B reset2345 (exact cooldown_start) + C reset2400 (55 steps after) + D reset2200 (145 steps before). Tests whether R-buffer staleness from pre-cooldown accumulation degrades post-cooldown adaptation. Ack #1243 frieren stale_wip (AdEMAMix-aux Arm B step ~1100/3350). **ALL 4 H1-H4 DIRECTIVE-ALIGNED HYPOTHESES NOW PARTIALLY IN FLIGHT** (H1 #1277 nezuko + H2 #1281 edward + H3 #1280 alphonse; H4 late-window period/coverage tune still pending — will assign when fern or frieren chain closes). 8 chains active, 0 idle, 0 review-ready.

- **Date:** 2026-05-26 (cycle 334 — #1232 nezuko Power AdamW CLOSED productive-NEG 35th no-merge + nezuko REASSIGNED #1277 H1 step-gated Newton-Muon). **#1232 chain TERMINAL** (all 4 arms): A ctrl 3.26726 drift +0.00112 PASS-strong / B p=1.5 3.27074 Δ=+0.00348 PRODUCTIVE-NEG / C p=1.0 3.27120 Δ=+0.00394 PRODUCTIVE-NEG most regressive / **D p=3.0 3.26881 Δ=+0.00155 PRODUCTIVE-NEG boundary**. **Bilateral fence at p=2.0 CONFIRMED 3-direction** — p<2 side degrades 2.3× faster than p>2 side (under-damping more harmful than over-damping). **AUX-DENOMINATOR-EXPONENT axis fully closed** — joins MAGNITUDE-PRESERVING-DENOMINATOR cluster saturation (6 mechanisms now converging on canonical Adam denominator load-bearing for lm_head: #1100 WD / #1155 MARS / #1153 D-Cautious / #1175 v_min / #1210 AdaBelief / #1232 p-fence). **nezuko REASSIGNED #1277 H1 Step-gated Newton-Muon** — `NANOGPT_NEWTON_MUON_START_STEP` sweep at 0/2000/2200/2400, first hypothesis directly testing Issue #1261 directive bullet (1) "Newton-Muon only after X". Tests whether NM does most of its useful work in cooldown/pre-crossing window (steps 2000-3350); if favorable → late-only NM saves compute and possibly improves FFS via concentration; if NULL → time-invariance confirmed, compute optimization possible; if negative → NM time-load-bearing, fences temporal-gating axis. Pre-staged decision tree frozen, 7h chain. **First NM-aligned reassignment of the lm_head-cluster-closure wave**. 8 chains active, 0 idle, 0 review-ready.

- **Date:** 2026-05-26 (cycle 333 — 1 stale_wip ack, #1240 tanjiro Arm C period5 TERMINAL with **FFS-VAL ORTHOGONALITY CONFIRMED**). **#1240 chain**: A ctrl 3.26761/3200 drift +0.00147 PASS-strong / B max_d4096 3.26529/3175 Δ=−0.00232 + fs Δ=−25 FAVORABLE both / **C period5 3.26717/3175 Δ_val=−0.00044 NULL band + Δ_fs=−25 FAVORABLE fs only** / D compound running step 375 (~11%). **🎯 CROSS-AXIS DECOMPOSITION**: coverage axis (`max_d_in`) drives val refinement (MLP down-proj d_in=3072 newly preconditioned), period axis (`PERIOD`) drives FFS acceleration only — Issue #1261's central question "how to help BEFORE crossing, not just improve final val" gets clearest empirical evidence yet. Both Arms B and C land fs=3175 (baseline-matching) via INDEPENDENT mechanism paths, strengthening claim that fs=3175 is real not single-seed noise. **Pre-staged Arm D decision tree**: D val ≈ B → PP escalate on B (simpler 1-env-var change); D val ≤ B−0.0005 → PP escalate on D (compound super-additivity); D val > B → PP escalate on B alone. PP attenuation forecast either way ∈ [−0.0005, −0.0015] → **still merge-eligible per statistical rule**, would become **2nd merge since #847** if PP confirms (first compositional NM-stack mod). Chain ETA Arm D terminal ~6h. 8 chains active, 0 idle, 0 review-ready.

- **Date:** 2026-05-26 (cycle 332 — 🎯 #1231 thorfinn body Muon bias correction TERMINAL SENT-BACK for 2-arm post-#1138 confirmation). **#1231 4-arm screening chain (PRE-#1138 stack)**: A ctrl 3.27025 / B full 3.27002 Δ=−0.00023 NULL / **C warmup100 3.26731 Δ=−0.00294 FAVORABLE** + fs=3200 / D beta099 3.27233 Δ=+0.00208 PRODUCTIVE-NEG. **Cannot merge** (val 3.26731 > production baseline 3.26614 by +0.00117, fs 3200 > baseline 3175 by +25 → G1 FAIL absolute). **Cannot close productive-NULL** (within-chain Δ_paired=−0.00294 is real above-signal-threshold on body Muon momentum axis — directive-aligned per Issue #1261). **Sent back to thorfinn**: rebase + 2-arm rerun (A' post-#1138 ctrl + C' warmup100 with Newton-Muon active) tests compositional value. Pre-staged decision tree frozen: Δ(C',A') ≤ −0.002 AND val_C' ≤ 3.26614 → PP n=3 escalation; [−0.002, −0.001] → productive-MARGINAL close (NM-attenuation); |Δ| ≤ 0.0015 → productive-NULL close (PRE-#1138 favorable was cooldown-boundary noise); ≥+0.0015 → productive-NEG close (mechanism interferes with NM). Student's own honest interpretation pre-terminal: "fragile at n=1, cooldown-boundary perturbation". Mechanism at step 100+: β^100=0.006 → correction factor 1.006 essentially identity, so favorable Δ comes from tiny cooldown-entry perturbation OR noise OR compositional NM interaction. ETA confirmation chain ~3.7h. thorfinn no longer idle (chain re-launched under same PR). 8 chains active, 0 idle, 0 review-ready.

- **Date:** 2026-05-26 (cycle 331 — 1 stale_wip ack + answered student question). **#1236 edward depth-LR body Muon Arm C desc03 TERMINAL val=3.26994 fs=3225** vs Arm A ctrl 3.26835 → **Δ_paired=+0.00159 PRODUCTIVE-MARGINAL** (just above NULL band in [+0.001, +0.0015] grey zone) + fs +25 slower. Direction asymmetry confirmed: asc Δ=+0.00438 strongly harmful vs desc Δ=+0.00159 marginally harmful (factor 2.75× asymmetry). Mechanism interpretation: NS5 polar decomp benefits MOST from balanced spectral conditioning across body Muon layers; asc boosts late-layers (already-larger activation magnitudes) → over-corrects post-cooldown, desc boosts early-layers (cleaner gradient) → milder imbalance. Arm D ushape05 step 1600 (~48%), modal forecast Δ_D ∈ [+0.003, +0.006] strongly regressive (combines asc+desc harms at scale=0.5). **Resolved student question 05:36 UTC**: confirmed Arm D=ushape05 (override PR body's `asc05`) — student had auto-defaulted to ushape05 at 06:45 UTC cutoff, correct judgment. PER-LAYER-DEPTH-CALIBRATED-LR axis closing 3-direction fence (asc/desc/ushape all regressive forecast). Closure ETA ~3-4h, will reassign edward to NM-aligned body-Muon-axis hypothesis (likely H2 cooldown-entry R-buffer refresh per Issue #1261). 8 chains active, 0 idle, 0 review-ready.

- **Date:** 2026-05-26 (cycle 330 — 2 stale_wip acks, 2 mid-chain Arm C terminals, 1 favorable NM-aligned signal). **#1232 nezuko Power AdamW Arm C p=1.0 TERMINAL val=3.27120 fs=3225 Δ_paired=+0.00394 PRODUCTIVE-NEG** — monotonic regression pattern (Arm B p=1.5 Δ=+0.00348 → Arm C p=1.0 Δ=+0.00394, deviation from canonical p=2.0 worsens further). Arm D p=3.0 step 1900 (~57%) — modal forecast bilateral fence (Δ_D≈+0.003-0.005), AUX-DENOMINATOR-EXPONENT-MODIFYING axis FENCED at p=2.0 canonical. Closure ETA ~3-4h, will reassign nezuko to **H1 step-gated Newton-Muon** per Issue #1261. **#1231 thorfinn body Muon bias correction Arm C warmup100 TERMINAL val=3.26731 fs=3200 Δ_paired=−0.00294 FAVORABLE within-chain** (above signal threshold −0.002) + fs −25 FASTER — 100-step warmup skips bias-correction-instability window (β1^t≈1 → m_corrected diverges at low t), gets benefit only when momentum mature. **PRE-#1138 stack confounding**: absolute val=3.26731 vs PRE-#1138 ref 3.26756 = Δ=−0.00025 (favorable but not strong-signal vs production baseline 3.26614). Plan at terminal: rebase + 2-arm post-#1138 confirmation rerun (A' ctrl + C' warmup100) to validate composability with Newton-Muon. NM-aligned per directive. Arm D beta099 step 2350 (~70%). 8 chains active 0 idle 0 review-ready; no human gh issues new this cycle (#1261 still acknowledged).

- **Date:** 2026-05-26 (cycle 324 — 🎯 HUMAN DIRECTIVE Issue #1261 "Try something new r4!") — **STRATEGIC PIVOT**: morganmcg1 directive shifts primary readout to **FFS (final_first_step_to_target) over final val/loss**. Plateau on val_loss minor improvements means the next wave should ask "how to help BEFORE target crossing, not just improve final val." **4 concrete directions prescribed:** (1) **Step-gated Newton-Muon** — `NANOGPT_NEWTON_MUON_START_STEP` enabling at steps 2000/2200/2400; (2) **Cooldown-entry refresh** — reset/enable Newton-Muon when LR enters cooldown @2345; (3) **Short pre-crossing burst** — Newton-Muon active only in window around steps 2400-3000; (4) **Late-window period/coverage tuning** — `NANOGPT_NEWTON_MUON_UPDATE_PERIOD` + `_MAX_D_IN` tuned specifically for steps 2400-3000. **Constraint:** "Be wary of drifting into an optimizer zoo around lm_head or aux groups unless tied to Newton-Muon." **Impact on in-flight chains:** 4 chains (nezuko Power AdamW lm_head / fern Lion lm_head / frieren AdEMAMix lm_head / alphonse Zipfian-LR lm_head) are misaligned with directive — letting them finish for fence-mechanism characterization but will REASSIGN closures to Newton-Muon-aligned hypotheses; 4 chains aligned (tanjiro Newton-Muon ext / askeladd GC-Pre-NS5 / thorfinn body Muon bias / edward depth-LR body Muon). **Acknowledged on Issue #1261**. **Next reassignment pool**: H1 step-gated NM, H2 cooldown-entry refresh NM, H3 pre-crossing burst NM (steps 2400-3000), H4 late-window period=5 NM. Will assign as lm_head chains close.

- **Date:** 2026-05-26 (cycles 302-320 monitoring + terminals batch) — **3 single-arm terminals + 4 ctrl-arm terminals + 4 arm transitions; 0 closures, 0 merges, 0 new assignments still pending full-chain SENPAI-RESULTs.** **Arm B/C terminals (mid-chain, not closure-eligible until chain end):** (1) **nezuko #1232 Arm B p=1.5 val=3.2707 fs=3225 Δ=+0.00344 PRODUCTIVE-NEG** — denominator EXPONENT deviation from p=2.0 RMS harmful, NOT PP-escalation; modal closure path locked-in pending C p=1.0 + D p=3.0 sweep completion (AUX-DENOMINATOR-EXPONENT-MODIFYING axis characterizing). (2) **thorfinn #1231 Arm B full bias correction val=3.2700 Δ=−0.00025 NULL band** — Adam-style m_t/(1-β1^t) before NS5 mechanism NOT load-bearing; Arm C warmup100 alternative timing testing. **Ctrl-arm terminals (baseline reproducibility check):** fern #1233 Arm A 3.2656 fs=3175 drift +0.00046 / tanjiro #1240 Arm A 3.2676 fs=3200 drift +0.00146 / frieren #1243 Arm A 3.2669 fs=3175 drift +0.00076 / alphonse #1244 Arm A 3.2669 fs=3175 drift +0.00076 / edward #1236 Arm A (cycle 312) 3.2683 fs=3350 drift +0.00216 / nezuko #1232 Arm A 3.26726 fs=3175 drift +0.00112 / thorfinn #1231 Arm A 3.27025 fs=3225 drift +0.00411 elevated — **6/7 ctrl drifts within ±0.003 gate, baseline reproducibility EXCEPTIONAL**, only thorfinn slightly elevated. **Arm transitions launched**: tanjiro Arm B max_d=4096 step ~1150 (Newton-Muon coverage 4× extension) / fern Arm B Lion LR=0.001 step ~1000 (SIGN-BASED-OPTIMIZER first arm) / frieren Arm B lm_head AdEMAMix step ~500 (dual-EMA first-moment) / alphonse Arm B log_freq step ~75 (Zipfian-LR amplify frequent rows) / thorfinn Arm C warmup100 step ~875 (skip-first-100-steps bias-timing) / nezuko Arm C p=1.0 step ~400 (L1-denom). **Remaining Arm A ctrls still running**: edward #1236 depth-LR Arm B asc03 step ~3275 (terminal ~next cycle) / askeladd #1246 Gradient-Centralization Arm A ctrl step ~3100 (terminal ~next cycle). **#1231 needs_rebase persistent 18 cycles** — student running locally + will rebase at terminal per workflow. **8 chains active 0 idle 0 review-ready** throughout. No human gh issues.

- **Date:** 2026-05-26 (cycle 301) — **#1203 askeladd β2 cooldown CLOSED productive-NULL 33rd no-merge**: all 4 arms NULL/mild-regress vs OLD baseline 3.26756 + above NEW baseline 3.26614 by +0.00258 to +0.00381 (best Arm C all-aux val=3.26872), runs on pre-#1138 stack (no NANOGPT_NEWTON_MUON env vars), AUX-β2-SCHEDULE-MODIFICATIONS axis NOT load-bearing; askeladd REASSIGNED **#1246 Gradient-Centralization-Pre-NS5** (Yong et al ECCV 2020 arXiv:2004.01461 — subtract gradient mean BEFORE NS5 polar decomp on body Muon matrices; 4-arm A ctrl + B row-center + C col-center + D both; mathematically orthogonal to Newton-Muon right-precondition, composes cleanly; PRE-NS5-GRADIENT-PREPROCESSING axis fresh, mentioned in unrun #944); **#1233 fern Lion needs_rebase persistent 2nd cycle** — student narrative claims rebase complete (f1f4d85f) but GitHub branch HEAD still e91d4f66ee pre-#1138, W&B Arm A ctrl b74xsrxf running step 575/3350 from 02:28:58Z post-merge so locally rebased not pushed; **#1231 thorfinn needs_rebase 1st cycle** — student pushed implementation 3a534a60ef at 02:46:25Z but conflicts with #1138 body Muon changes, Arm A ctrl finished val=3.27025 drift +0.00411 slightly above gate, Arm B running step 375/3350; both PRs running locally + will rebase at terminal; no human gh issues; **8 chains active 0 idle 0 review-ready** (active: #1231 thorfinn body Muon bias / #1232 nezuko Power AdamW / #1233 fern Lion / #1236 edward depth-LR / #1240 tanjiro Newton-Muon ext / #1243 frieren AdEMAMix-aux / #1244 alphonse Zipfian-LR / #1246 askeladd Gradient-Centralization)

- **Date:** 2026-05-26 (cycle 299) — **MAGNITUDE-PRESERVING-DENOMINATOR-MODIFIERS cluster FULLY SATURATED (5/5 NULL confirmed).** Closed #1175 frieren v_min floor (NULL cluster 5th + new baseline supersession: armB-s0 val=3.26903 = +0.00289 above new baseline 3.26614, PP s0 Δ=−0.00048 NULL band, 81% attenuation from N=1). Closed #1210 alphonse AdaBelief (NULL cluster 5th confirmed: Arm B Δ=−0.00038 NULL + Arm C all-aux CATASTROPHIC +0.028 scope-expansion). Sent back #1233 fern Lion for rebase (fresh SIGN-BASED-OPTIMIZER axis preserved, only Arm A ctrl started on old stack — will re-run on post-#1138 stack with Newton-Muon env vars). Assigned **#1243 frieren AdEMAMix-aux** (Pagliardini 2024 arXiv:2409.03137 — dual-EMA first moment β1 fast + β3=0.9999 slow blended via α=5.0; FIRST-MOMENT-DUAL-EMA axis, mechanism-distinct from entire saturated denominator cluster; 4-arm A ctrl + B lm_head AdEMAMix + C all-aux + D lm_head α=2.0 sensitivity). Assigned **#1244 alphonse Zipfian-LR-lm-head** (per-row LR scaling by token frequency — Arm B log_freq amplifies frequent rows, Arm C inv_sqrt_freq amplifies rare rows; ZIPFIAN-AWARE-PER-ROW-LR axis, mechanism-distinct from denominator cluster AND from catastrophic row-norm #1192 equalization; opposite-direction arms simultaneously test Zipfian step-asymmetry hypothesis). No human GH issues. **8 chains active 0 idle 0 review-ready.**

- **Date:** 2026-05-26 (cycle 298) — 🎯 **#1138 MERGED — FIRST MERGE SINCE #847** (25-PR plateau broken). Newton-Muon right-precondition by input activation second moment val=3.26614 fs=3175.00 mean(n=3), Δ_vs_prev_base=−0.00142 on val / −8.33 on fs, t-stat=−4.93, 3/3 direction-correct, ALL 5 MERGE GATES PASS. **NEW BASELINE: val=3.26614 / fs=3175.00 (n=3).** `NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0 NANOGPT_NEWTON_MUON_PERIOD=10 NANOGPT_NEWTON_MUON_MAX_D_IN=1024`. tanjiro REASSIGNED **#1240 Newton-Muon extension** (2×2 factorial: coverage max_d_in=1024 vs 4096 × period=10 vs 5; 4-arm A ctrl + B max_d_in=4096 + C period=5 + D compound; verifying 72/72 params_preconditioned vs 60/72 for full coverage; MLP down-proj d_in=3072 newly covered); **all subsequent PR reviews compare against NEW BASELINE val=3.26614 fs=3175.00**
- **Date:** 2026-05-26 (cycle 296) — **🎯 #1138 tanjiro Newton-Muon PP n=3 5/6 RUNS TERMINAL** s2-A-ctrl val=3.26824 drift +0.00068 EXCEPTIONALLY CLEAN; mean ctrl drift (n=3) = +0.00132 G2 PASS-STRONG; s2-B-newton running step 2345/3350 (~70%) pre-cooldown val 3.39696 normal; s2-B needs ≤ 3.27018 for G1 PASS (cushion +0.00194 above s2-A-ctrl); **modal forecast s2-B ∈ [3.26700, 3.26900] → 3/3 favorable, mean(n=3) BELOW baseline, FIRST MERGE SINCE #847** ETA terminal ~04:30 UTC May 26; **#1210 alphonse AdaBelief Arm B TERMINAL Δ=−0.00038 NULL band** mechanism fires (s/vt 0.76) but no val improvement, **5th cluster NULL outcome confirming MAGNITUDE-PRESERVING-DENOMINATOR-MODIFIERS pattern** (#1100/#1155/#1153/#1175/#1210 all NULL/productive-MARGINAL), Arm C all-aux running step 1000/3350 modal NULL forecast, chain terminal ~04:30 UTC; **#1175 frieren v_min floor s0 attenuation persists** ctrl-s1 running step 1150/3350, modal NULL closure; **#1203 askeladd β2 cooldown Arm C all-aux TERMINAL Δ=−0.00106 NULL band direction-correct** but absolute val 3.26872 above baseline by +0.00116, Arm D running step 600/3350 closure ETA ~05:30 UTC; 8 chains active 0 idle 0 review-ready; no human gh issues
- **Date:** 2026-05-26 (cycle 295) — **#1137 edward stack pruning Phase 2 CLOSED** (30th no-merge since #847) PRUNE-CONFIRM-NO-MERGE: mean Δ_paired=+0.002305 (3/3 seeds regressive) — `EMBED_COOLDOWN_SHAPE=linear_floor` (PR #235) IS LOAD-BEARING, mean μ_pruned=3.27099, embod val polisher in last 1000 steps confirmed (not load-bearing on fs — pure val-polisher); textbook PP catch (N=1 Δ=−0.00059 inside noise reversed to PP mean +0.00231 3/3 sign concordance); **design lesson: Phase 2 pruning N=1 signals inside noise should go straight to PP n=3 before drawing conclusions**; edward REASSIGNED **#1236 body Muon per-layer depth LR scaling** (4-arm ascending/descending/u-shape depth mult, scale=0.3 arms B/C, scale=0.5 arm D, per-layer Muon param groups, mechanism-distinct from all current optimizer work in flight, PER-LAYER-DEPTH-CALIBRATED-LR fresh axis); **#1175 frieren v_min floor PP n=3 s0 attenuation detected** (s0 Δ=−0.00048 NULL, 81% attenuation from N=1 −0.00257; follows MAGNITUDE-PRESERVING cluster attenuation pattern similar to #1100 76% collapse; s1-ctrl running step 775/3350; MODAL FORECAST: NULL closure unless s1+s2 recover anti-attenuation); no human gh issues on r4; 8 chains active 0 idle 0 review-ready
- **Date:** 2026-05-26 (cycle 294) — **#1192 fern row-norm CLOSED** (29th no-merge since #847) with MAGNITUDE-EQUALIZING-ACROSS-ROWS sub-axis fenced: lm_head row-norm +0.17151 CATASTROPHIC + embed row-norm +0.00270 productive-MARGINAL + compound +0.18849 CATASTROPHIC; harm scales with Zipfian row-magnitude variance in target group (lm_head strong Zipfian → catastrophic, embed weak Zipfian → mild); **cluster sub-axis boundary confirmed: MAGNITUDE-PRESERVING-RESPECTING-ROW-STRUCTURE favorable (#1100/#1155/#1175) vs MAGNITUDE-EQUALIZING-ACROSS-ROWS CATASTROPHIC (#1192)**; fern REASSIGNED **#1233 Lion-lm-head** (Chen et al. 2023 SIGN-BASED-OPTIMIZER: sign(β1·m + (1−β1)·g) with no v_t denominator, 4-arm: A ctrl + B Lion LR=0.001 β1=0.9 β2=0.99 + C Lion LR=0.0005 LR-sensitivity + D Lion-Cautious LR=0.001 with sign-agreement mask; mechanism-distinct from entire MAGNITUDE-PRESERVING cluster, clean SIGN-BASED-OPTIMIZER fresh axis); no human gh issues active on r4 branch; 8 chains active 0 idle 0 review-ready
- **Cycle 293 (01:30 UTC May 26): **#1191 thorfinn CLOSED** (27th no-merge) frequency-of-reset axis clean 3-direction: B interval=500 +0.00026 NULL benign-compositional, C interval=250 +0.00470 PRODUCTIVE-NEG (frequent reset disrupts curvature), D cooldown-start single-reset −0.00135 NULL-favorable (below PP threshold); **FREQUENCY-OF-RESET sub-axis FENCED**: more-frequent reset → more-harmful, single-timing hypothesis insufficient; **#1197 nezuko CLOSED** (28th no-merge) IMPLEMENTATION MECHANISM FAILURE: Arm B `dist_max=0` at ALL 37 logged points (slow buffer never diverged from fast weights — Lookahead lm_head no-op), Arm C all-aux peaked 24.09 then collapsed (scoping issue), does NOT fence Lookahead axis per se; **#1192 ack #3 posted** Arm C terminal +0.00270 + Arm D running step 3300 CATASTROPHIC compound pending terminal; thorfinn REASSIGNED **#1231 body Muon bias correction** (Adam-style m_t/(1-β^t) before NS5, NS5-INPUT-MAGNITUDE-CORRECTING fresh axis); nezuko REASSIGNED **#1232 Power AdamW lm_head** (generalized v_t=E[|g|^p] denominator v_t^{1/p}, 4-arm A ctrl + B p=1.5 + C p=1.0 + D p=3.0, AUX-MAGNITUDE-PRESERVING-DENOMINATOR-SHAPE-MODIFYING fresh axis, mechanism-distinct from AdaBelief/v_min/WD/MARS/row-norm); 2 STRONG POSITIVE PP CANDIDATES IN FLIGHT (#1138 Newton-Muon + #1175 v_min floor); 8 chains active 0 idle 0 review-ready
- **Cycle 292 (00:25 UTC May 26): **#1137 edward stack pruning Phase 2 PP s2-ctrl TERMINAL val=3.26752 drift −0.00004 EXCEPTIONALLY CLEAN** (cleanest single-seed ctrl in recent cohort, mean ctrl drift n=3 +0.00112 well inside G2 gate), s2-armC running step 2125/3350 mid val=3.41627 normal cooldown trajectory ETA terminal ~02:50 UTC May 26; chain mean Δ_paired(2/3)=+0.00207 productive-NEG direction holding, **3/5 gates FAIL or at-risk** (G1 FAIL mean(2)=3.27134 above baseline by +0.00378 need s2-armC ≤ 3.26000 catastrophic-favorable to clear; G3 FAIL 0/2 favorable can't reach 2/3; G4 mixed; G2 PASS strong; G5 PASS); modal forecast s2-armC ~3.270 → Δ_paired_s2 ~+0.0025 → chain mean(3) ~+0.0027 productive-NEG closure path locked in (26th no-merge if confirms); mechanism mortem: pruned component (likely `EMBED_COOLDOWN_SHAPE=linear_floor`) IS load-bearing on val (late-cooldown val polisher) but NOT on fs — informative ablation; **🎯 #1138 tanjiro Newton-Muon PP n=3 s2-A-ctrl running** step ~2700 ETA terminal ~01:00 UTC, s2-B ETA ~02:50 UTC May 26 — MOST-PROBABLE FIRST MERGE SINCE #847; **2 STRONG POSITIVE PP CANDIDATES IN FLIGHT (#1138 strong-forecast + #1175)**; **8 chains active 0 idle 0 review-ready**; no human gh issues)
- **Cycle 291 (00:05 UTC May 26): **🎯 #1138 tanjiro Newton-Muon PP n=3 SEED 1 PAIR TERMINAL: Δ_s1=−0.00385 STRONGER than s0 (−0.00206), mean Δ(2)=−0.00296, mean(armB,n=2)=3.26625 BELOW BASELINE 3.26756 by 0.00131** — anti-attenuation pattern (#1100 was 76% attenuation collapse, #1138 is OPPOSITE — getting stronger across seeds, structural mechanism evidence that input-covariance right-preconditioning before NS5 polar decomp is robust across seed variance); ALL 5 MERGE GATES TRENDING PASS at 4/6 runs terminal (G1 mean below baseline, G2 stat-rule 0.0238>>0.004, G3 2/2 favorable, G4 ctrl-drift mean +0.001645 PASS, G5 fs ≥1 favorable); s2-A-ctrl running step 2125/3350 ETA ~01:00 UTC May 26, s2-B ETA ~02:50 UTC May 26 — **MOST-PROBABLE OUTCOME: FIRST MERGE SINCE #847 (25 closures fence behind us)** s2-armB has +0.00393 cushion (can land up to 3.27018 and still keep mean(3) ≤ baseline); **#1203 askeladd β2 cooldown step Arm B TERMINAL Δ=−0.00015 NULL band** (mechanism CONFIRMED firing per β2 transition 0.99→0.999 at step 2345 telemetry, but effect within noise — β2-schedule axis NOT load-bearing for lm_head in this stack), Arm C all-aux running step 425/3350, Arm D pending chain ETA ~04:00 UTC May 26 modal outcome NULL-cluster productive-NULL closure; **#1175 frieren v_min floor PP s0-armB running** chain ETA ~07:30 UTC May 26; **#1210 alphonse AdaBelief Arm B running step ~700 mechanism firing s/vt ratio 0.76** chain ETA ~04:00 UTC May 26; **2 STRONG POSITIVE PP CANDIDATES IN FLIGHT (#1138 + #1175)**; **8 chains active 0 idle 0 review-ready**; no human gh issues)
- **Cycle 290 (23:35 UTC May 25): **#1210 alphonse AdaBelief lm_head Arm A ctrl TERMINAL val=3.27013 drift +0.00257 PASS-edge, Arm B lm_head β1=0.8 β2=0.99 running step 400/3350 mechanism CONFIRMED FIRING** per s/vt ratio ~0.76 stable across 3 checkpoints (AdaBelief denominator ~24% smaller than vanilla Adam → effective lm_head step size ~24% LARGER for well-predicted gradient directions), no numerical instability (s_max in [0.05, 0.09], g−m residual norm 3.5-4.2 non-zero); mechanism-distinct from all 5 prior MAGNITUDE-PRESERVING cluster members (REPLACES v_t with s_t = E[(g−m)²] entirely different denominator statistic, β1=0.8 vs canonical 0.9 makes m_t more responsive amplifies (g−m) belief signal); arms C all-aux + D lm_head β2=0.95 pending sequential launch; chain ETA terminal ~04:00 UTC May 26 (~4.5h remaining); pre-staged decision criteria frozen at PR body (Δ ≤ −0.002 PP escalation / ∈ [−0.002,−0.001] favorable-borderline / ∈ [−0.001,+0.001] NULL / ≥ +0.0015 productive-NEG); **2 STRONG POSITIVE PP CANDIDATES STILL IN FLIGHT (#1138 + #1175)** (#1138 Newton-Muon PP s1 pair finishing now, #1175 v_min floor PP s0-armB step ~700/3350 mechanism firing); **8 chains active 0 idle 0 review-ready**; no human gh issues) **#1137 edward stack pruning Phase 2 PP s2-ctrl TERMINAL val=3.26752 drift −0.00004 EXCEPTIONALLY CLEAN** (cleanest single-seed ctrl in recent cohort, mean ctrl drift n=3 +0.00112 well inside G2 gate), s2-armC running step 2125/3350 mid val=3.41627 normal cooldown trajectory ETA terminal ~02:50 UTC May 26; chain mean Δ_paired(2/3)=+0.00207 productive-NEG direction holding, **3/5 gates FAIL or at-risk** (G1 FAIL mean(2)=3.27134 above baseline by +0.00378 need s2-armC ≤ 3.26000 catastrophic-favorable to clear; G3 FAIL 0/2 favorable can't reach 2/3; G4 mixed; G2 PASS strong; G5 PASS); modal forecast s2-armC ~3.270 → Δ_paired_s2 ~+0.0025 → chain mean(3) ~+0.0027 productive-NEG closure path locked in (26th no-merge if confirms); mechanism mortem: pruned component (likely `EMBED_COOLDOWN_SHAPE=linear_floor`) IS load-bearing on val (late-cooldown val polisher) but NOT on fs — informative ablation; **🎯 #1138 tanjiro Newton-Muon PP n=3 s2-A-ctrl running** step ~2700 ETA terminal ~01:00 UTC, s2-B ETA ~02:50 UTC May 26 — MOST-PROBABLE FIRST MERGE SINCE #847; **2 STRONG POSITIVE PP CANDIDATES IN FLIGHT (#1138 strong-forecast + #1175)**; **8 chains active 0 idle 0 review-ready**; no human gh issues)
- **Cycle 291 (00:05 UTC May 26): **🎯 #1138 tanjiro Newton-Muon PP n=3 SEED 1 PAIR TERMINAL: Δ_s1=−0.00385 STRONGER than s0 (−0.00206), mean Δ(2)=−0.00296, mean(armB,n=2)=3.26625 BELOW BASELINE 3.26756 by 0.00131** — anti-attenuation pattern (#1100 was 76% attenuation collapse, #1138 is OPPOSITE — getting stronger across seeds, structural mechanism evidence that input-covariance right-preconditioning before NS5 polar decomp is robust across seed variance); ALL 5 MERGE GATES TRENDING PASS at 4/6 runs terminal (G1 mean below baseline, G2 stat-rule 0.0238>>0.004, G3 2/2 favorable, G4 ctrl-drift mean +0.001645 PASS, G5 fs ≥1 favorable); s2-A-ctrl running step 2125/3350 ETA ~01:00 UTC May 26, s2-B ETA ~02:50 UTC May 26 — **MOST-PROBABLE OUTCOME: FIRST MERGE SINCE #847 (25 closures fence behind us)** s2-armB has +0.00393 cushion (can land up to 3.27018 and still keep mean(3) ≤ baseline); **#1203 askeladd β2 cooldown step Arm B TERMINAL Δ=−0.00015 NULL band** (mechanism CONFIRMED firing per β2 transition 0.99→0.999 at step 2345 telemetry, but effect within noise — β2-schedule axis NOT load-bearing for lm_head in this stack), Arm C all-aux running step 425/3350, Arm D pending chain ETA ~04:00 UTC May 26 modal outcome NULL-cluster productive-NULL closure; **#1175 frieren v_min floor PP s0-armB running** chain ETA ~07:30 UTC May 26; **#1210 alphonse AdaBelief Arm B running step ~700 mechanism firing s/vt ratio 0.76** chain ETA ~04:00 UTC May 26; **2 STRONG POSITIVE PP CANDIDATES IN FLIGHT (#1138 + #1175)**; **8 chains active 0 idle 0 review-ready**; no human gh issues)
- **Cycle 290 (23:35 UTC May 25): **#1210 alphonse AdaBelief lm_head Arm A ctrl TERMINAL val=3.27013 drift +0.00257 PASS-edge, Arm B lm_head β1=0.8 β2=0.99 running step 400/3350 mechanism CONFIRMED FIRING** per s/vt ratio ~0.76 stable across 3 checkpoints (AdaBelief denominator ~24% smaller than vanilla Adam → effective lm_head step size ~24% LARGER for well-predicted gradient directions), no numerical instability (s_max in [0.05, 0.09], g−m residual norm 3.5-4.2 non-zero); mechanism-distinct from all 5 prior MAGNITUDE-PRESERVING cluster members (REPLACES v_t with s_t = E[(g−m)²] entirely different denominator statistic, β1=0.8 vs canonical 0.9 makes m_t more responsive amplifies (g−m) belief signal); arms C all-aux + D lm_head β2=0.95 pending sequential launch; chain ETA terminal ~04:00 UTC May 26 (~4.5h remaining); pre-staged decision criteria frozen at PR body (Δ ≤ −0.002 PP escalation / ∈ [−0.002,−0.001] favorable-borderline / ∈ [−0.001,+0.001] NULL / ≥ +0.0015 productive-NEG); **2 STRONG POSITIVE PP CANDIDATES STILL IN FLIGHT (#1138 + #1175)** (#1138 Newton-Muon PP s1 pair finishing now, #1175 v_min floor PP s0-armB step ~700/3350 mechanism firing); **8 chains active 0 idle 0 review-ready**; no human gh issues)
- **Cycle 289 (22:55 UTC May 25): **#1175 frieren v_min floor PP n=3 LAUNCHED CLEANLY**: s0-ctrl TERMINAL val=3.26951 drift **+0.00195 PASS** (cleaner than N=1 ctrl +0.00320 borderline-FAIL), s0-armB running step 335/3350 mechanism firing per clamped_frac telemetry (embed 0.79% + lm_head 0.87% sub-1% intervention as designed for 1e-4 sweet spot vs over-floored 1e-3 Arm C); for s0 Δ_paired ≤ −0.00257 matching N=1 magnitude armB needs val ≤ 3.26694 (BELOW baseline 3.26756 — strong-favorable draw); pre-staged 5-row PP decision tree frozen: ≤−0.0025 MERGE breaks #847 streak / [−0.0025,−0.0015] MERGE candidate / [−0.0015,−0.001] CLOSE productive-MARGINAL / [−0.001,+0.001] CLOSE productive-NULL N=1-favorable-seed-draw / Δ_s1∨Δ_s2 ≥ +0.001 CLOSE productive-NULL seed-conditionality; PP attenuation forecast from prior patterns (#1100 76%, #1138 64%) suggests #1175 PP mean Δ ∈ [−0.0008, −0.0020] mild-favor to borderline range; chain ETA ~07:30 UTC May 26 (s0-armB ~00:35 UTC / s1-ctrl ~02:20 / s1-armB ~04:00 / s2-ctrl ~05:45 / s2-armB ~07:30); **2 STRONG POSITIVE PP CANDIDATES STILL IN FLIGHT (#1138 s1-B near-terminal + #1175 s0-armB step 335)**; #1191 thorfinn body Muon reset Arm D cooldown-start running ETA ~01:30 UTC May 26; #1192 fern row-norm Arm C embed near-terminal pending Arm D both pending; #1137 edward stack pruning Phase 2 s2-ctrl running ETA full chain ~05:30 UTC May 26; #1197 nezuko Lookahead Arm C all-aux running ETA ~22:30 UTC; #1203 askeladd β2 cooldown arms B/C/D pending sequential launch; #1210 alphonse AdaBelief lm_head freshly assigned ETA TBD; **8 chains active 0 idle 0 review-ready**; no human gh issues)
- **Cycle 288 (22:35 UTC May 25): **#1191 thorfinn body Muon reset Arm B/C TERMINAL, frequency-of-reset axis characterizing**: B interval=500 Δ=+0.00025 **NULL band benign compositional candidate** (reset_count=6 mechanism firing), C interval=250 Δ=+0.00470 **PRODUCTIVE-NEG frequent-reset harmful** (reset_count=13, curvature info disrupted by too-frequent reset), D cooldown-start single-reset running step 600/3350 ETA ~01:30 UTC May 26 testing timing-not-frequency hypothesis; mechanism IS firing per body_muon/buf_norm dips to 0.44-0.87 at each reset event; sweep characterization clean linear: more-frequent reset → more-harmful, interval=500 sits at benign/harmful boundary; **forecast**: D NULL or slight-regression most likely → close FREQUENCY-OF-RESET sub-axis fenced + B NULL-band benign preserved as compositional candidate joining #1172 D scale-only and post-NS5 scale-only in "benign compositional preserved" set; if Arm D Δ≤−0.002 favorable, timing hypothesis confirmed → PP n=3 escalation candidate (body-Muon-scope compositional with #1138 Newton-Muon); chain ETA full terminal ~01:30 UTC May 26; **2 STRONG POSITIVE PP CANDIDATES STILL IN FLIGHT (#1138 + #1175)**; **8 chains active 0 idle 0 review-ready**; no human gh issues)
- **Cycle 287 (21:55 UTC May 25): **#1192 fern row-norm Arm B lm_head TERMINAL CATASTROPHIC +0.17151** (Δ vs ctrl 3.26864 → 3.44015), Arm C embed mid-trajectory +0.053 regression at step 2950, mechanism IS firing per `row_norm_active=1` telemetry (true rejection NOT bug); Arm D both pending (forecast catastrophic via lm_head inheritance); **lm_head MAGNITUDE-PRESERVING cluster sub-axis FENCED** — distinguishes between MAGNITUDE-PRESERVING-RESPECTING-ROW-STRUCTURE (favorable: #1100/#1155/#1175 preserve Zipfian magnitude prior via per-row scaling) and **MAGNITUDE-EQUALIZING-ACROSS-ROWS (CATASTROPHIC: #1192 destroys Zipfian prior, common-token gradient signal suppressed, val refinement directly harmed)**; clean structural boundary: per-row magnitude scaling OK, cross-row magnitude equalization NOT OK; 25th no-merge closure forecast at full chain terminal ~00:05 UTC May 26 — waiting for terminal SENPAI-RESULT before closing; pre/post grad mean telemetry: lm_head 0.009765→0.009765 (mean-preserved as expected, per-row magnitudes rescaled), embed 3.12e-05→1.86e-05 (40% suppression milder); excellent implementation quality (in-place row_normalize_grad_ + fp32 promotion + eps clamp + bit-identical fallback) makes result interpretable; **3 STRONG POSITIVE PP CANDIDATES STILL IN FLIGHT (#1138 Newton-Muon s1-B ETA ~21:41 UTC + #1175 v_min floor PP escalated + #1192 NOW MOVING TO CLOSURE removes one from positive list)**; **8 chains active 0 idle 0 review-ready**; no human gh issues)
- **Cycle 286 (21:30 UTC May 25): **#1197 nezuko Lookahead Arm B mechanism-failure CONFIRMED** + **#1137 edward stack pruning Phase 2 PP trending productive-NEG**, both stale_wip acked; #1197 Arm A ctrl val=3.26775 drift **+0.00019 most-favorable-in-cohort** (cleaner than #1192 +0.00108), **Arm B lm_head k=5 dist_max=0.0 at ALL 37 logged points** (full-history confirms permanent zero slow-fast separation) — implementation likely no-op for lm_head-only scoping; Arm C all-aux k=5 dist_max=24.09 alternating-pattern (mechanism IS firing correctly when group-scope works), running step 1300/3350 ETA terminal ~22:30 UTC; **Arm B regression +0.00449 NOT interpretable as Lookahead-on-lm_head harmful** until mechanism-firing verified — requested student probe `opt.lookahead_groups` membership and add one-step-offset telemetry log; #1137 edward PP n=3 stack pruning Phase 2 at 4/6 runs terminal — Δ_paired_s0=+0.00053 NULL, Δ_paired_s1=+0.00362 REGRESSION, **mean(2/3)=+0.00207 productive-NEG forecast** (above +0.0015 threshold by 0.00057), mean ctrl drift +0.00170 PASS, 3/5 gates FAIL (G1/G3/G5) — modal outcome productive-NEG closure with mechanism mortem (pruned component is load-bearing on val not fs), s2 ctrl step 1700/3350 ETA full chain ~05:30 UTC May 26; **#1138 tanjiro Newton-Muon PP n=3 s1-A-ctrl TERMINAL val=3.27038 drift +0.00282 PASS-edge**, s1-B-newton running step 1575/3350 in pre-cooldown ETA ~21:41 UTC, mean ctrl drift +0.00165 (s0+s1) within G2 gate; **#1203 askeladd β2 cooldown step Arm A ctrl TERMINAL val=3.26978 drift +0.00222 PASS-edge** (1.0σ above recent cohort mean — typical variance), arms B/C/D pending sequential launch β2 transition armed for step 2345, chain ETA ~02:15 UTC May 26; 3 STRONG POSITIVE PP CANDIDATES STILL IN FLIGHT (#1138 + #1175 + #1192); **8 chains active 0 idle 0 review-ready**; no human gh issues)
- **Cycle 285 (20:45 UTC May 25): **#1175 frieren v_min floor TERMINAL — Arm B `median_frac=1e-4` STRONGEST SINGLE-ARM SIGNAL SINCE #847 plateau** Δ=−0.00257 (clears −0.002 threshold by 0.00057) + fs −25 favorable (3225→3200) + sensitivity curve confirms mechanism real (1e-4 sweet spot, 1e-3 over-floors, max_frac=1e-6 ceiling regression); **ESCALATING TO PP n=3** on Arm B config — overrides pre-staged tree row 3 (Arm D regression) due to signal magnitude: #1175 Δ=−0.00257 stronger than #1100 (−0.00185 PP CLOSED noise-floor) and weaker than #1138 (−0.00576 PP seed-0 favorable in flight); 5-gate merge framework frozen (G1 baseline-beat 3.26756 / G2 stat-rule 0.004 / G3 ≥2/3 dir / G4 drift ±0.003 / G5 no-catastrophe |Δ|<0.0015); 6-seed interleaved sequential chain ETA ~07:30 UTC May 26; absolute val 3.26819 above baseline by +0.00063 means N=1 can't merge but PP attenuation pattern (#1100: −0.00185 → −0.00004 mean Δ) is the science PP is designed to catch; **lm_head MAGNITUDE-PRESERVING cluster strongest evidence yet** (now 6-mechanism characterized: #1100 WD CLOSED PP / #1155 MARS CLOSED / **#1175 v_min floor PP escalating** / #1192 row-norm in flight / #1153 D Cautious CLOSED / #1210 AdaBelief assigned alphonse); frieren NOT idle (PP n=3 task assigned); **8 chains active 0 idle 0 review-ready**, 3 STRONG POSITIVE PP CANDIDATES IN FLIGHT (#1138 Newton-Muon seed-1 ctrl step 1725 + #1175 v_min floor PP starting + #1192 fern row-norm Arm A ctrl favorable))
- **Cycle 284 (20:35 UTC May 25): **#1172 alphonse Muon++ μP spectral CLOSED productive-NEG with PARTIAL FENCE** (24th consecutive no-merge closure since #847) — clean 4-arm attribution decomposition: A ctrl 3.26981/3225 drift PASS edge, **B full 3.27493/3275 Δ=+0.00512 PRODUCTIVE-NEG**, C init-only 3.27209/3250 Δ=+0.00228 REGRESSION, **D scale-only 3.27048/3225 Δ=+0.00067 NULL fs identical to ctrl** — decision tree row 2 hit exactly; init μP scaling is sole load-bearing harm (double-counts with empirical per-block LR mults attn=0.80 mlp=1.20 embed=1.5), post-NS5 scale-only NULL-band benign and **compositional candidate preserved** (× Newton-Muon input-side, × body Muon momentum reset); super-additive interaction Δ_B−(Δ_C+Δ_D)=+0.00217 (74% super-additivity); **SPECTRAL-CONDITIONING-MUON axis FENCED 1-direction** on init component; alphonse REASSIGNED **#1210 AdaBelief lm_head** (Zhuang 2020 NeurIPS arXiv:2010.07468, replaces v_t=E[g²] with s_t=E[(g−m)²] tracking gradient-direction-belief rather than magnitude, mechanism-distinct from all 5 prior lm_head MAGNITUDE-PRESERVING cluster mechanisms, 4-arm: A ctrl + B lm_head stack β1=0.8 β2=0.99 mech-lead + C all-aux scope expansion + D lm_head β2=0.95 sensitivity)); **8 chains active 0 idle 0 review-ready**)
- **Cycle 283 (19:15 UTC May 25):** #1175 frieren v_min floor Arm C TERMINAL NEAR-NULL/slight regression (1e-3 over-floors), Arm D max_frac ceiling in flight; #1192 fern row-norm Arm A ctrl TERMINAL favorable drift +0.00108; stale_wip acks posted for both. See cycle 283 entries above.
- **Cycle 283-earlier (** **#1175 frieren v_min floor Arm C TERMINAL slight-regression + Arm D max_frac ceiling in flight, #1192 fern row-norm Arm A ctrl TERMINAL favorable drift** — both acked stale_wip; #1175 chain reading at ~80%: Arm A drift +0.00320 borderline-FAIL, **Arm B median_frac=1e-4 Δ=−0.00257 FAVORABLE confirmed terminal** (val 3.26819 above baseline by +0.00063), **Arm C median_frac=1e-3 Δ=+0.00141 NEAR-NULL/slight-regression** (val 3.27221 — 1e-3 OVER-FLOORS), Arm D `max_frac=1e-6` running step 850/3350 CEILING mechanism testing complementary intervention (within-spec per PR body, NOT deviation), **sensitivity curve characterized 1e-4 sweet spot 1e-3 over-floors**, decision tree pre-staged at Arm D terminal ETA ~21:30 UTC; #1192 fern row-norm Arm A ctrl FINISHED val=3.26864 drift **+0.00108 FAVORABLE** (smallest drift in recent ctrl cohort cleaner than #1100/#1155/#1175/#1191/#1172), Arm B lm_head row-norm running step 700/3350 ETA chain terminal ~23:30 UTC, excellent implementation quality (in-place row_normalize_grad_ with fp32 promotion + bit-identical fallback verified + per-25-step telemetry); **#1138 tanjiro Newton-Muon PP n=3 seed-1 ctrl running step 1725/3350** (seed-0 pair already FAVORABLE Δ=−0.00206 ✓), STRONGEST POSITIVE CANDIDATE chain ETA ~01:30 UTC May 26; **#1137 edward stack pruning seed-1 ctrl near-terminal step 3200** chain ETA ~22:00 UTC; **#1191 thorfinn body Muon reset Arm A ctrl FINISHED val=3.26945 drift +0.00189 PASS**, Arm B reset-interval-500 running step 1050; **#1197 nezuko Lookahead arm A ctrl in flight step 2825** (near-terminal newly assigned student picked up), **#1203 askeladd β2 cooldown step ctrl in flight step 200** (newly assigned student picked up); lm_head MAGNITUDE-PRESERVING cluster sensitivity granularity added (#1175 Arm B 1e-4 favorable vs Arm C 1e-3 over-floors — distinguishes magnitude-touching with light intensity from strong intensity, joins prior 5-mechanism characterization); **8 chains active 0 idle 0 review-ready, all 8 students productive**)
- **Cycle 282 (19:00 UTC May 25):** #1100 askeladd lm_head WD PP n=3 TERMINAL CLOSED productive-NULL (23rd consecutive no-merge closure since #847) — full chain Δ_s0=−0.00144 / Δ_s1=+0.00011 / Δ_s2=+0.00120+fs regression, mean Δ_paired=−0.00004 NULL, mean(armC,n=3)=3.26941 above baseline by +0.00185, 3 of 5 gates FAIL (G1/G3/G5); mechanism mortem documented 3 distinct per-seed trajectories — IS real per-seed but seed-conditional strength, N=1 −0.00185 favorable seed-1 draw; askeladd REASSIGNED #1203 AdamW β2 cooldown step (schedule mechanism, β2: 0.99→0.999 at cooldown_start); #1138 tanjiro Newton-Muon SEED 0 PAIR FAVORABLE Δ_paired=−0.00206 clears within-pod threshold + fs +25, NOW STRONGEST POSITIVE CANDIDATE.
- **Cycle 281 (17:30 UTC May 25):** #1155 nezuko MARS-AdamW CLOSED productive-NULL with mechanism (22nd consecutive no-merge closure since #847) — γ × scope 2D matrix: B γ=0.025 lm_head Δ=−0.00048 NULL-favorable (best), C γ=0.025 all-aux Δ=+0.00024 NULL (scope dilutes), D γ=0.1 lm_head Δ=−0.00001 NULL (γ=0.025 is near-optimum); lm_head-specific signal confirmed — same cross-axis pattern as #1100 WD; excellent correction_ratio telemetry (scales linearly with γ, validates MARS implementation); lm_head MAGNITUDE-PRESERVING cluster now 4-evidence-strong (WD/MARS/v_min/row-norm all favorable direction); nezuko REASSIGNED **#1197 Lookahead-AdamW aux** (Zhang 2019 arXiv:1907.08610, k-step weight-space EMA pullback k=5 α=0.5 canonical, mechanism-distinct from MARS/v_min/WD/row-norm — operates on WEIGHTS not gradients/precond, wraps AdamW preserving m/v/LR/β, 4-arm chain: A ctrl + B lm_head k=5 mech-lead + C all-aux k=5 + D lm_head k=10 horizon test); **#1175 frieren v_min floor Arm B favorable Δ=−0.00257** full chain in flight ETA ~20:30 UTC; **8 chains active 0 idle**)
- **Cycle 280 (17:00 UTC May 25):** #1153 fern Cautious CLOSED productive-NEG + NULL-marginal (21st consecutive no-merge closure since #847) — clean 2×2 chain attribution: B lm_head hard mask +0.00788, C all-aux hard mask +0.01091 (scope-monotone PRODUCTIVE-NEG), D lm_head soft mask +0.00124 NULL-marginal (soft mask salvages mechanism but no signal); excellent mask_fraction telemetry: lm_head ~0.66 sign-agreement (34% disagree — HIGHER than #1045's 25.6% prediction, attributed to post-#847 stack's NANOGPT_ADAMW_EMBED_LR_MULT=1.5 producing more aggressive momentum dynamics), embed ~0.44 (majority disagree), scalars ~0.74 (lowest disagree); **lm_head FILTERING/MASKING cluster CONFIRMED 4-direction regression fence** (#1045 LION + #1153 B/C/D); fern REASSIGNED **#1192 lm_head row-norm AdamW** (Muon-spirit magnitude-equalizing on Zipfian rows, mechanism-distinct from all prior aux-modification closures, structurally novel — preserves direction per-row + equalizes magnitude across rows, compositional with lm_head MAGNITUDE-PRESERVING cluster); **#1138 tanjiro Newton-Muon PP n=3 in flight** (ctrl-s0 terminal val=3.26803 favorable drift draw +0.00047, armB-s0 running step 525 ETA ~18:05 UTC, chain terminal ~01:00 UTC May 26); cross-axis pattern locked — **lm_head DIRECTION is load-bearing (filtering fences), lm_head MAGNITUDE is safely-modifiable** (#1100 PP at-risk, #1155 NULL-favorable, #1175 in flight, #1192 row-norm now joins the magnitude-equalizing branch of this cluster); **8 chains active 0 idle**)
- **Cycle 279 (16:30 UTC May 25):** #1163 thorfinn AggMo+Nesterov CLOSED productive-NEG/CATASTROPHIC Δ=+0.03581 (20th closure), NS5-INPUT-MODIFYING multi-buffer mean-aggregation FENCED 2-direction; thorfinn REASSIGNED #1191 body Muon momentum reset.
- **Cycle 278 (15:30 UTC May 25):** #1100 SEED 1 PAIR TERMINAL REVERSAL Δ_seed1=+0.00011 NULL, n=2 paired mean Δ=−0.00066, mean(armC)=3.26889 above baseline; G1 + G3 gates AT RISK pending seed 2.
- **Cycle 277 (14:00 UTC May 25):** #1137 edward Stack pruning Phase 2 N=1 TERMINAL Arm C PRUNE-CONFIRM Δ=−0.00059 NULL band + fs improvement 3225→3200; SENT BACK for PP n=3 confirmation on Arm C config (drop EMBED_COOLDOWN_SHAPE=linear_floor); first stack-simplification merge candidate if PP confirms.
- **Cycle 274 (13:30 UTC May 25):** #1127 frieren SF AdamW aux CLOSED productive-MARGINAL/CATASTROPHIC (19th closure); frieren REASSIGNED #1175 AdamW v_min floor (OPTIMIZER-PRESERVING mechanism-distinct from LION/Adan/SF replacement failures).
- **Cycle 273 (13:00 UTC May 25):** #1132 Shampoo body CLOSED productive-NEG/CATASTROPHIC Δ=+0.130; alphonse REASSIGNED #1172 Muon++ μP spectral control (Zhao arXiv:2601.01306, NS5-PRESERVING POST-NS5 UPDATE-MAGNITUDE-MODIFYING).
- **Cycle 272 (12:30 UTC May 25):** #1138 Newton-Muon Arm B STRONG POSITIVE SIGNAL Δ=−0.00576 (val=3.26559 BELOW baseline by −0.00197), trajectory std~0.00012 EXTRAORDINARY SNR, Arm C half-LR DISAMBIGUATES, Arm D in flight; #1137 Arm C drop-#235 PRUNE-CONFIRM Δ=−0.00059.
- **Cycle 270 (12:00 UTC May 25):** #1122 thorfinn body Muon AggMo CLOSED productive-NEG/17th consecutive no-merge closure [MULTI-BUFFER-BODY-MUON-MOMENTUM axis FENCED 1-closure, Nesterov-loss + mean-dilution interaction load-bearing]; thorfinn REASSIGNED #1163 AggMo+Nesterov hybrid 2-arm disambiguation; #1100 SEED 0 PAIR FINISHED Δ=−0.00144 mechanism reproducing.
- **Cycle 268-269 (11:30-12:00 UTC May 25):** #1100 PP seed0 paired Δ=−0.00144 confirmation; #1127 SF Arms B/C CATASTROPHIC monotone-in-β confirmed, Arm D surprise positive; #1153 Cautious Arm A drift track, #419 prior context flagged.
- **Cycle 254 (07:00 UTC May 25):** #1100 N=1 4-arm TERMINAL Arm C Δ=−0.00185 5-signal mechanism → PP n=3.
- **Cycle 253 (06:00 UTC May 25):** #1092 tanjiro per-group AdamW β1 CLOSED productive-NULL/NEG (13th closure); #1028 edward PRUNE-CONFIRM CLOSED (14th closure); tanjiro → #1138 Newton-Muon (5th plateau escalation); edward → #1137 stack pruning Phase 2.
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `val/loss` at 3350 steps (lower is better); `speedrun/final_first_step_to_target` secondary
- **Statistical merge rule:** `(3.28 − μ) × √n ≥ 0.004` AND n mean ≤ current baseline

## Cycle 254 snapshot (07:00 UTC May 25) — #1100 askeladd aux per-group WD TERMINAL Arm C lm_head wd=1e-3 Δ_vs_A=−0.00185 sub-threshold by 0.00015 but 5-mechanism support → SENT BACK FOR PP n=3 (strongest mechanism candidate since #847); #1120 nezuko GaLore divergence in Arms B (crashed)/C — student investigating SVD/buffer instability

### Activity this cycle

- **#1100 askeladd** N=1 4-arm TERMINAL `SENPAI-RESULT` marker posted. **Strongest positive signal since #847**:
  - A ctrl: 3.26962 drift PASS edge (+0.00206)
  - B lm_head wd=1e-4: 3.26856 Δ_vs_A=−0.00106 PRODUCTIVE-MARGINAL
  - **C mech-lead lm_head wd=1e-3: 3.26777 Δ_vs_A=−0.00185** (0.00015 short of −0.002 signal threshold)
  - D embed wd=1e-4: 3.26942 Δ_vs_A=−0.00020 NULL
  - **5-signal mechanism characterization** justifying PP n=3 override of strict threshold rule:
    1. Monotone-in-wd within PP: A(0)→B(1e-4)→C(1e-3) clean log-linear direction
    2. Group-specific Zipfian: lm_head wd=1e-4 5.3× stronger than embed wd=1e-4 at identical magnitude
    3. Late-cooldown widening: Δ(C−A) grows from −0.00138@step2500 → −0.00185@step3350
    4. Independent cross-axis confirmation: matches #1045 frieren LION-aux Zipfian-row finding
    5. fs-invariance signature: all arms fs=3200, mechanism is continuous shrinkage not buffer-reset
  - **PP n=3 protocol assigned**: 6 interleaved seeds 0/1/2 runs on single pod (ctrl + arm-C config), pre-staged 5-gate merge criteria frozen. ~11h chain. If PP sustains → first MERGE since #847 (would set new baseline ~3.26571 from 3.26756, ~0.00185 win). If collapses → close productive-NULL with mechanism characterization documented.

- **#1120 nezuko GaLore lm_head** divergence pattern detected:
  - Arm A ctrl `u7lyiri7`: finished val=3.27051 drift PASS edge (+0.00295, at gate edge ±0.003)
  - **Arm B mech-lead rank=8 period=200: CRASHED step 2475 val=4.81** (divergence)
  - **Arm C rank=32: running step 1000 val=4.84** (divergent trajectory; normal at step 1000 ≈3.62)
  - Probable failure modes: (1) SVD instability with V=50304 lm_head, (2) m/v buffer projection mismatch across SVD refreshes, (3) rank-8 information loss too aggressive, (4) BF16 SVD numerical precision
  - Awaiting student debug report on `lm_head/grad_norm`, projection conditioning, SVD basis state. If fundamentally unstable → close productive-NEG with mechanism characterization.

### Active chains status (cycle 254)

| Student | PR | Title | Status | Notes |
|:---:|:---:|---|:---:|---|
| nezuko | #1120 | GaLore lm_head | WIP (debugging) | Arms B crashed C diverging — SVD/buffer instability investigation |
| thorfinn | #1122 | AggMo body Muon | WIP | Escalation #2: multi-β momentum bank |
| frieren | #1127 | Schedule-Free AdamW aux | WIP | Escalation #3: replace cooldown w/ iterate-averaging |
| alphonse | #1132 | Shampoo body Muon | WIP | Escalation #4: Kronecker 2nd-order preconditioner |
| askeladd | #1100 | Aux per-group WD | WIP (PP n=3) | **STRONGEST POST-#847 MECHANISM**, 6-run interleaved confirmation |
| fern | #1113 | Adan aux optimizer | WIP | 2nd optimizer-class-aux observation |
| tanjiro | #1138 | Newton-Muon | WIP | Escalation #5: input covariance right preconditioning |
| edward | #1137 | Stack pruning Phase 2 | WIP | Phase 2: drop #393/#235/#579 flags |

**14 no-merge closures, 0 idle students this cycle.** Pending merge candidate: #1100 Arm C if PP n=3 sustains (would be first MERGE since #847 cycle 222, breaking 14-closure streak).

## Cycle 253 snapshot (06:00 UTC May 25) — #1092 CLOSED productive-NULL/NEG; #1028 CLOSED PRUNE-CONFIRM; tanjiro → #1138 Newton-Muon (5th plateau escalation); edward → #1137 Phase 2 pruning; **14 consecutive no-merge closures**

### Activity this cycle

- **#1092 tanjiro** N=1 4-arm CLOSED productive-NULL/NEG: per-group AdamW β1 asymmetric differentiation (13th closure).
  - A ctrl β1=0.8 both: 3.26832 drift PASS (+0.00076), fs=3200
  - B lm_head β1=0.70: 3.26863 Δ_vs_A=+0.00031 NULL; lmhead_step_dir_rms +24% (mechanism fires)
  - **C mech-lead embed=0.95+lm_head=0.70**: 3.27135 Δ_vs_A=**+0.00303 REGRESSION**; embed_step_dir_rms −50%, lmhead +23%
  - D embed β1=0.95: 3.26932 Δ_vs_A=+0.00100 NULL; embed_step_dir_rms −50%
  - **Mechanism fires but doesn't translate.** Diagnostic telemetry confirms all β1 overrides operating as designed. Regression in C is from INTERACTION between embed=0.95 and lm_head=0.70 simultaneously — neither alone hurts.
  - **Root cause**: lm_head `effective_aux_lr_ratio ≈ 5e-4` → massively AUX-clipped at virtually every step → changing β1 shifts direction only, not magnitude headroom.
  - **PER-GROUP ADAMW β1 FAMILY CLOSED in 2 directions**: #599 symmetric (all groups same β1) + #1092 asymmetric (this work).

- **#1028 edward PP n=3 TERMINAL** CLOSED PRUNE-CONFIRM (14th closure).
  - PP n=3 interleaved on/off seeds 0/1/2: μ_on=3.26994 vs μ_off=3.26966, |Δ|=0.00028, σ_Δ=0.00113
  - Seed pattern: 0/1 favor off (−0.00097/−0.00090), seed 2 favors on (+0.00102) — sub-noise, split direction
  - **PRUNE-CONFIRM ✓**: |Δ|=0.00028 ≤ 0.001 AND μ_off=3.26966 ≤ 3.27006
  - NOT a merge: μ_off=3.26966 doesn't beat baseline 3.26756 (pod-time drift +0.00210)
  - **EMBED_INIT_ANCHOR_LAMBDA (#847) confirmed non-load-bearing at PP n=3.** Anchor mechanism is doing observable work (embed/dist_from_init tracked, snapshot_norm=6208 reproduced), but no val/loss signal. Superseded by later composition of LR_MULT=1.5×/#708 clip tightening.
  - **Pruning methodology validated**: 4-arm subtractive sweep → PP n=3 confirmed at ~20 GPU-hours/candidate.

- **#1100 askeladd aux WD Phase 2** (mid-chain): Arm C (lm_head wd=1e-3) Δ_vs_A=−0.00185 approaching signal threshold; monotone A→B→C; Arm D (embed wd=1e-4) still in flight. Pre-staged decision framework: if D positive → PP n=3 on C; if D NULL/NEG → lm_head-specific Zipfian WD mechanism.

- **Researcher-agent completed (PLATEAU13 wave)**: 6 fresh tier-4 hypotheses generated (see `/research/RESEARCH_IDEAS_2026-05-25_PLATEAU13.md`). Highest priorities: Newton-Muon (arXiv:2604.01472, input activation second moment right preconditioning, ~6% step reduction external evidence), SOAP aux, MARS-AdamW aux, Scion body, Muon++.

- **PR #1138 tanjiro** (5th PLATEAU ESCALATION assigned this cycle): **Newton-Muon (Du & Su, arXiv:2604.01472, April 2026)** — right preconditioning by input activation second moment before NS5: `W ← W − η · NS5(G · (X^T X)^{-1/2})`. Directly addresses proven NS5 Lipschitz invariance structural finding (#1088): NS5 is Lipschitz-invariant on gradient INPUT scale; right-preconditioning by activation covariance rotates the gradient in column space (not just rescales), which IS visible to NS5. Mechanism-distinct from Shampoo #1132 (which uses gradient outer products G^T G as R proxy; Newton-Muon uses TRUE input activations X^T X). External evidence: ~6% step reduction on modded-nanoGPT at comparable settings. 4 arms: A=ctrl Muon, B=Newton lr_scale=1.0 period=10 (mech-lead), C=Newton lr_scale=0.5 period=10 (conservative LR), D=Newton lr_scale=1.0 period=50 (sparse R update).

- **PR #1137 edward** (Phase 2 pruning assigned this cycle): **Stack pruning Phase 2 — subtractive sweep of next 3 oldest still-merged flags**. Same methodology as #1028 Phase 1. Arms: A=ctrl, B=drop #393 embed LR mult (1.5→1.0), C=drop #235 embed cooldown floor (linear_floor→linear), D=drop #579 body Muon LR asymmetry (0.80/1.20→1.0/1.0). PRUNE-CONFIRM gate: |Δ|≤0.001 → trigger PP n=3 confirmation.

### Active chains status (cycle 253)

| Student | PR | Title | Status | Notes |
|:---:|:---:|---|:---:|---|
| nezuko | #1120 | GaLore lm_head | WIP | Escalation #1: Arm A complete, B/C/D chaining |
| thorfinn | #1122 | AggMo body Muon | WIP | Escalation #2: multi-β momentum bank |
| frieren | #1127 | Schedule-Free AdamW aux | WIP | Escalation #3: replace cooldown w/ iterate-averaging |
| alphonse | #1132 | Shampoo body Muon | WIP | Escalation #4: Kronecker 2nd-order preconditioner |
| askeladd | #1100 | Aux per-group WD | WIP | Mid-chain, Arm C approaching signal, Arm D in-flight |
| fern | #1113 | Adan aux optimizer | WIP | 2nd optimizer-class-aux observation |
| tanjiro | #1138 | Newton-Muon | WIP (NEW) | Escalation #5: input covariance right preconditioning |
| edward | #1137 | Stack pruning Phase 2 | WIP (NEW) | Phase 2: drop #393/#235/#579 flags |

### Plateau awareness status (cycle 253 — ESCALATION ACTIVE, 5 escalation moves assigned)

**14 consecutive no-merge closures** since #847 (cycle 222): #1028 PP, #1031, #1032, #1045, #1047, #1048, #1055, #1003, #1074, #1078, #1088, #1091, **#1092**, **#1028 PP n=3 terminal**.

**Escalation moves in flight (cumulative 4 active + 1 new as of cycle 253):**
- **#1120 nezuko GaLore lm_head** — dimensionality reduction on Zipfian-heavy lm_head (cycle 242)
- **#1122 thorfinn AggMo body Muon** — multi-β momentum bank structure (cycle 245)
- **#1127 frieren Schedule-Free AdamW aux** — replace cooldown with online iterate averaging (cycle 247)
- **#1132 alphonse Shampoo body Muon** — replace NS5 polar decomposition with Kronecker-factored 2nd-order preconditioner (cycle 249)
- **#1138 tanjiro Newton-Muon** — right preconditioning by input activation second moment (cycle 253, NEW, HIGHEST PRIORITY)

**Comprehensive closed-axis map (for future hypothesis generation):**
- Body Muon WD: 4 directions fenced (warmup NEG, cooldown NULL, constant+cooldown_only NEG, distance-from-init NULL)
- Body Muon momentum: μ scalar (#356), Nesterov (#530), LookAhead (#1047), μ temporal schedule (#1078), AggMo (#1122 in-flight), gradient noise injection NS5-input (#1088 NULL-proven Lipschitz-invariant)
- AdamW aux preconditioner: β2 (#236 merged, #967 cooldown anneal NULL), ε (#629/#929 v_t floor, #652 DOWN NEG, #1020 UP NULL), β1 symmetric (#599 NEG), β1 asymmetric (#1092 NULL/NEG, THIS WORK), all 5 COOLDOWN-WINDOW sub-axes fenced
- Optimizer class aux: LION (#1045 NEG), Adan (#1113 in-flight)
- State reset: 4 closures across both optimizer sides (#163/#711/#988/#998)
- NS5 structure: static-c (#1008 NULL), iteration schedule (#1031 NULL), Haar-init (#1032 NULL), NS5-input gradient noise (#1088 NULL-Lipschitz-proven)
- lm_head structure: 13 closures, GaLore dimensionality (#1120 in-flight), LION-aux (#1045 NEG)
- Weight averaging: SWA/EMA (#1055 NULL), init-anchor (#847 merged, #1028 PRUNE-CONFIRM non-load-bearing)
- Loss shape: CE-family 4-axis fence (#446/#441/#791/#801)

**Remaining open escalation candidates (researcher-agent PLATEAU13 wave):**
1. ~~Newton-Muon~~ → assigned #1138 tanjiro
2. SOAP for aux (lm_head+embed) — Adam in Shampoo eigenbasis
3. MARS-AdamW aux — STORM variance reduction on aux gradients
4. Scion body — nuclear-norm-ball LMO replacing body Muon
5. Muon++ — μP-style per-layer adaptive scaling
6. Stochastic rounding diagnostic

## Cycle 249 snapshot (04:55 UTC May 25) — #1091 alphonse BODY-MUON-WEIGHT-DECAY 4-arm CLOSED productive-NEG; comprehensive 4-direction fence on body Muon WD; alphonse reassigned #1132 **Shampoo body** (Anil 2018) — 4th plateau escalation REPLACING NS5 polar decomposition with Kronecker-factored 2nd-order preconditioner

### Activity this cycle

- **#1091 alphonse** N=1 4-arm complete CLOSED productive-NEG: body Muon decoupled WD.
  - A ctrl wd=0: 3.26708 drift PASS, fs=3175
  - B wd=0.001 const: 3.27111 Δ_vs_A=+0.00403 REGRESSION
  - C wd=0.01 cooldown_only (mech-lead): 3.27279 Δ_vs_A=+0.00571 PRODUCTIVE-NEG (worst!)
  - D wd=0.01 const: 3.26968 Δ_vs_A=+0.00260 REGRESSION
  - **Counter-mechanism reading**: cooldown_only-activation is WORST. fs A=3175 → C=3250 (75 steps slower). Body Muon's NS5 polar decomp produces operator-norm-bounded updates; adding wd shrinkage breaks the clean magnitude evolution structure.
  - **BODY-MUON-WEIGHT-DECAY axis comprehensively fenced (4 directions)**: #483 (warmup addition NEG), #550 (cooldown reduction NULL), #1091 (constant + cooldown_only addition NEG this work), #808 (distance-from-init WD NULL). Body Muon wd=0 is structurally optimal across all tested directions.
- **#1120 nezuko GaLore lm_head** stale_wip acked. Arm A `u7lyiri7` running step 3075/3350 mid-cooldown val=3.2945; trajectory looks plausible to converge to val~3.27 by step 3350. Arms B/C/D will chain after A completes.
- **PR #1132 alphonse** (4th PLATEAU ESCALATION axis assigned this cycle): **Shampoo body (Anil 2018) — Kronecker-factored 2nd-order preconditioner replacing NS5 polar decomposition on all body parameters**. Maintains L=E[G·Gᵀ], R=E[Gᵀ·G] Gram matrices, periodic eigendecomp for L^{-1/4}, R^{-1/4}, applies update L^{-1/4}·G·R^{-1/4}. 4 arms: A=ctrl Muon, B=Shampoo β=0.95 period=200 lr_scale=0.5 (mech-lead canonical), C=Shampoo lr_scale=1.0 (LR-sensitivity), D=Shampoo period=50 (curvature drift test). Mechanism-distinct from ALL prior body-Muon work (which preserved NS5 framework). High-info regardless of outcome.

### Plateau awareness status (cycle 249 — ESCALATION ACTIVE, 4th escalation move)

**12 consecutive no-merge closures** since #847 (cycle 222): #1028 PP, #1031 NS-adaptive, #1032 Haar-init, #1045 LION-aux, #1047 LookAhead, #1048 cooldown-shape, #1055 SWA/EMA, #1003 per-block-TYPE cooldown anneal, #1074 GC-embed, #1078 μ schedule, #1088 gradient-noise NS5 input, **#1091 body Muon WD**.

**Escalation moves in flight (cumulative 4 as of cycle 249):**
- **#1120 nezuko GaLore lm_head** — dimensionality reduction on Zipfian-heavy lm_head (cycle 242)
- **#1122 thorfinn AggMo body Muon** — multi-β momentum bank structure (cycle 245)
- **#1127 frieren Schedule-Free AdamW aux** — replace cooldown with online iterate averaging (cycle 247)
- **#1132 alphonse Shampoo body Muon** — replace NS5 polar decomposition with Kronecker-factored 2nd-order preconditioner (cycle 249, NEW)

**Remaining pre-staged escalation candidates for next idle-student cycles:**
- MuonR² / iterated NS refinement (need careful design to be mechanism-distinct from closed NS-iter axes)
- Sophia aux (Liu 2023) — deferred (violates "1 fwd-bwd per step" rule)
- New axes from researcher-agent on next plateau-escalation cycle

**Mitigation alongside escalation**: 8 active chains, 4 of which are tier-4 escalation axes targeting orthogonal mechanism slots:
- lm_head dimensionality (#1120 GaLore)
- body momentum input structure (#1122 AggMo)
- aux schedule replacement (#1127 Schedule-Free)
- body preconditioner family replacement (#1132 Shampoo)

These 4 escalations probe 4 different structural assumptions: (1) is full-rank gradient subspace needed for lm_head? (2) is single-buffer momentum optimal for body? (3) is LR cooldown structurally necessary for aux? (4) is NS5 polar decomp the right body preconditioner? Even with all-NULL outcomes, this is a comprehensive mechanism-mapping wave.

## Cycle 247 snapshot (04:45 UTC May 25) — #1088 frieren body-Muon NS5-input gradient-noise injection CLOSED productive-NULL; NS5 Lipschitz invariance empirically proven (||g_ortho||_RMS=0.0360 invariant under ±5% input perturbation, σ_min 0.35→0.99 spectrum-tightening as structural side-effect); frieren reassigned **#1127 Schedule-Free AdamW aux** (Defazio 2024) — 3rd plateau escalation move targeting load-bearing cooldown mechanism

### Activity this cycle

- **#1088 frieren** N=1 4-arm complete CLOSED productive-NULL: body Muon NS5-input gradient-noise injection.
  - A ctrl 3.26794 drift +0.00038 PASS, B σ=0.01 const +0.00064 NULL, C σ=0.05 cosine +0.00016 NULL (mech-lead), D σ=0.05 const −0.00009 NULL (ceiling).
  - **All arms inside |Δ|≤0.0015 NULL band.** No signal, no regression.
  - **Structural finding 1 — Update RMS invariance proven**: `||g_ortho||_RMS = 0.036050 ± 0.000003` across all 4 arms. NS5 polar decomposition is Lipschitz-invariant on input scale. Noise injection at NS5 input cannot reach the orthogonalized update magnitude.
  - **Structural finding 2 — Spectrum tightening**: σ_min A=0.347 → D=0.991 monotone. Higher noise on NS5 input produces *tighter* post-NS5 spectrum (stochastic Tikhonov-regularization effect on polar-decomp Hessian, Higham 2008 property). Structurally interesting but signal-blind on FineWeb LM at this scale.
  - **GRADIENT-NOISE-INJECTION (body Muon NS5 input) 1-closure observation → partial fence.** Future input-side noise sweeps at NS5 input expected NULL. Mapping signal: future regularization mechanisms must act on NS5 *output*, NOT NS5 *input*.
- **PR #1127 frieren** (3rd PLATEAU ESCALATION axis assigned this cycle): **Schedule-Free AdamW for aux groups** (Defazio 2024) — replaces load-bearing cosine-with-cooldown LR schedule on aux side with online iterate-averaging (y↔z dance, β_sf=0.9 Defazio default). Body Muon retains full schedule. 4 arms: A=ctrl AdamW+cooldown, B=SF β_sf=0.9 cooldown-off (mech-lead, canonical Defazio config), C=SF β_sf=0.95 cooldown-off, D=SF β_sf=0.9 cooldown-on (hybrid). Mechanism-distinct from all prior aux-side work (#1100 wd, #1113 Adan, #1092 β1) — directly attacks the schedule mechanism. Even NULL outcome is high-info: confirms cooldown and SF are mechanism-equivalent or that cooldown is structurally load-bearing.

### Plateau awareness status (cycle 247 — ESCALATION ACTIVE, 3rd escalation move)

**11 consecutive no-merge closures** since #847 (cycle 222): #1028 PP, #1031 nezuko NS-adaptive, #1032 thorfinn Haar-init, #1045 frieren LION-aux, #1047 tanjiro LookAhead, #1048 alphonse cooldown-shape, #1055 askeladd weight-averaging, #1003 fern per-block-TYPE cooldown anneal, #1074 nezuko GC-embed, #1078 thorfinn μ schedule, **#1088 frieren gradient-noise NS5 input**.

**Escalation moves in flight (cumulative 3 as of cycle 247):**
- **#1120 nezuko GaLore lm_head** — dimensionality reduction on Zipfian-heavy lm_head (cycle 242)
- **#1122 thorfinn AggMo body Muon** — multi-β momentum bank structure (cycle 245)
- **#1127 frieren Schedule-Free AdamW aux** — replace cooldown with online iterate averaging (cycle 247, NEW)

**Remaining pre-staged escalation candidates for next idle-student cycles:**
- Shampoo / Distributed-Shampoo body — 2nd-order block-diagonal preconditioner replacing Muon NS
- MuonR² / iterated NS refinement (NS coefficient variants beyond saturated NS-iter count axes)
- Sophia aux (Liu 2023) — deferred (HVP per K steps borderline on "1 fwd-bwd per step" rule)

**Mitigation alongside escalation**: still 8 active chains. 3 tier-4 escalation axes targeting orthogonal mechanism slots (lm_head dimensionality, body momentum structure, aux schedule replacement).

## Cycle 245 snapshot (03:15 UTC May 25) — #1078 CLOSED productive-NULL/NEG, MUON-MOMENTUM-SCHEDULE 1-closure observation; thorfinn reassigned #1122 AggMo body Muon (2nd plateau escalation move targeting multi-β momentum aggregation structure)

### Activity this cycle

- **#1078 thorfinn** N=1 4-arm complete CLOSED productive-NULL/NEG: body Muon μ schedule.
  - A ctrl μ=0.95 const: 3.26942 drift +0.00186 PASS, fs=3200
  - B linear_full 0.95→0.85: 3.27300 Δ_vs_A=+0.00358 PRODUCTIVE-NEG, fs=3225 (full-trajectory μ decay hurts)
  - C cooldown_only 0.95→0.85: 3.26895 Δ_vs_A=−0.00047 NULL (|Δ|<0.001) BUT fs=3150 (only positive signal, 50 steps faster than A, sub-NULL-band n=1 — PP-precedent #1003 says won't survive PP)
  - D linear_full 0.99→0.85: 3.27916 Δ_vs_A=+0.00974 PRODUCTIVE-NEG worst (aggressive μ=0.99 + decay catastrophic)
  - **Monotone mechanism direction**: constant > cooldown-only ≈ neutral > full-decay > aggressive-high-then-low. Body Muon μ=0.95 EMA smoothing structurally important throughout. Cooldown-only direction-consistent but val-sub-threshold. fs improvement sub-NULL-band single-seed unlikely to survive PP.
  - **MUON-MOMENTUM-SCHEDULE 1-closure observation, partial fence.** Future finer μ_end or later cooldown_only start sweeps expected NULL.
- **PR #1122 thorfinn** (2nd PLATEAU ESCALATION axis assigned this cycle): **Body Muon AggMo (Lucas 2018) — multi-β momentum bank with mean-aggregation before NS5**. 4 arms: A=ctrl K=1 β=0.95, B=K=3 β∈{0.0, 0.9, 0.99} Lucas defaults (mechanism-lead), C=K=2 β∈{0.85, 0.99} compact ladder, D=K=3 β∈{0.85, 0.95, 0.99} centered ladder. Mechanism-distinct from ALL prior single-buffer body Muon momentum work (#1047 LookAhead meta-anchor, #1048 cooldown shape, #1078 temporal μ schedule just-closed, #1088 gradient noise injection, #1091 wd, #530 Nesterov, #356 μ scalar). Tests whether NS5 benefits from multi-time-scale gradient aggregation vs single β. K=3 doubles momentum buffer memory; on 96GB H100 well within budget.

### Plateau awareness status (cycle 245 — ESCALATION ACTIVE, 2nd escalation move)

**10 consecutive no-merge closures** since #847 (cycle 222): #1028 PP, #1031 nezuko NS-adaptive, #1032 thorfinn Haar-init, #1045 frieren LION-aux, #1047 tanjiro LookAhead, #1048 alphonse cooldown-shape, #1055 askeladd weight-averaging, #1003 fern per-block-TYPE cooldown anneal, #1074 nezuko GC-embed, **#1078 thorfinn μ schedule**.

**Escalation moves in flight (cumulative 2 as of cycle 245):**
- **#1120 nezuko GaLore lm_head** — dimensionality reduction on Zipfian-heavy lm_head (cycle 242)
- **#1122 thorfinn AggMo body Muon** — multi-β momentum bank structure (cycle 245, NEW)

**Remaining pre-staged escalation candidates for next idle-student cycles:**
- Schedule-Free (Defazio 2024) — replaces load-bearing cooldown entirely
- Shampoo / Distributed-Shampoo body — 2nd-order block-diagonal preconditioner replacing Muon NS
- MuonR² / iterated NS refinement
- Sophia aux (Liu 2023) — deferred (HVP per K steps borderline on "1 fwd-bwd per step" rule)

**Mitigation alongside escalation**: still 8 active chains (now with 2 escalation-tier). Adan-on-aux #1113 in flight is a 2nd OPTIMIZER-CLASS-aux observation that approaches partial fence if it regresses (would consolidate aux-side optimizer family closure).

### Cycle 244 snapshot (03:00 UTC May 25) — #1078 thorfinn body Muon μ schedule W&B-complete; pre-staged productive-NEG closure (2/4 arms regress, mechanism-lead Arm C NULL on val with fs=3150 sub-NULL-band signal)

### Activity this cycle

- **#1078 thorfinn** W&B confirms all 4 arms `state=finished step=3350`. Student has posted per-arm acks for A/B/C but NOT yet posted Arm D ack or terminal structured-result marker. Posted stale_wip ack with full W&B verification + pre-staged closure rationale:
  - A ctrl `icrp16u8`: val=3.26942 drift +0.00186 PASS, fs=3200
  - B linear_full 0.95→0.85 `kai3a62l`: val=3.27300 Δ_vs_A=+0.00358 **PRODUCTIVE-NEG**, fs=3225 — full-trajectory μ decay hurts
  - C cooldown_only 0.95→0.85 `nrmno8j1`: val=3.26895 Δ_vs_A=−0.00047 **NULL** (|Δ|<0.001 NON-LOAD-BEARING gate), **fs=3150 50 steps faster than A** (only positive signal, n=1 sub-NULL-band — PP-collapse precedent #1003 N=1 −0.00226→PP n=3 +0.00041 suggests this signal won't survive PP)
  - D linear_full 0.99→0.85 `tmaoyc4b`: val=3.27916 Δ_vs_A=+0.00974 **PRODUCTIVE-NEG (worst)**, fs=3325 — aggressive early μ=0.99 + decay hurts most
  - **Mechanism**: constant μ=0.95 across full 3350-step trajectory is locally optimal at this stack's operating point; any deviation regresses on val; cooldown-only direction is at best neutral. MUON-MOMENTUM-SCHEDULE axis approaches 1-closure observation pending terminal marker (this would be the **10th consecutive no-merge closure**).

### Plateau awareness status (cycle 244 — ESCALATION ACTIVE)

- **9 consecutive no-merge closures formalized** as of cycle 242 (#1074); #1078 will become the 10th once student posts terminal marker.
- **Escalation already triggered cycle 242** — #1120 nezuko GaLore lm_head is first formal bigger-bet escalation in flight.
- Pre-staged escalation candidates remaining for thorfinn (next idle when #1078 closes): **Schedule-Free / Shampoo body / AggMo body / MuonR²** (Sophia deferred — HVP per K steps borderline on "1 fwd-bwd per step" rule).
- 2nd OPTIMIZER-CLASS observation pending via #1113 Adan-on-aux (Arm A `state=finished` last cycle val=3.26642 below baseline single-seed; awaiting B/C/D + terminal marker).

## Cycle 242 snapshot (02:45 UTC May 25) — **PLATEAU ESCALATION TRIGGER FIRES** — #1074 nezuko GC-on-embed CLOSED productive-NEG (clean mechanism: small col-mean DC load-bearing, row-mean null-space, non-additive interaction); 9th consecutive no-merge closure; nezuko reassigned **#1120 GaLore lm_head** (FIRST bigger-bet escalation axis — low-rank gradient subspace on Zipfian-heavy lm_head, Zhao 2024)

### Activity this cycle

- **#1074 nezuko** N=1 4-arm complete CLOSED productive-NEG: GC on embed (off/row/col/both). A=3.26773 ctrl drift PASS, B col=3.27565 (Δ=+0.00792 REGRESSION, ~5σ), C row=3.26817 (Δ=+0.00044 NON-LOAD-BEARING), D both=3.27298 (Δ=+0.00525 REGRESSION ~3.5σ). Clean mechanism finding:
  - **Col-mean small but load-bearing** (2.3e-6 absolute norm, removing it costs +0.00792).
  - **Row-mean is null-space** (2.5e-5 absolute norm — ~10× larger — but removing it has zero structural effect).
  - **Non-additive interaction**: predicted D under additivity +0.00836, actual +0.00525 (−0.00311 better than additive). Row-mean and col-mean share structure; double-centering preserves more than col-only removal.
  - **Yong 2020 standard GC (row-center) is a no-op on this stack.** Signal axis is rotated to col direction.
- **PR #1120 nezuko** (PLATEAU ESCALATION axis assigned this cycle): **GaLore low-rank lm_head gradient subspace projection** — first formal bigger-bet escalation. 4 arms: A=ctrl off, B=rank=8 period=200 mechanism-lead, C=rank=32 period=200 moderate compression, D=rank=8 period=50 frequent SVD refresh. Compresses lm_head AdamW state from V×D≈51M to ~400k (r=8, 125× compression). Tests Zipfian-low-rank assumption on lm_head gradient — if dominant singular subspace captures >95% signal at r=8, the low-rank assumption is validated and opens a new direction.

### Plateau awareness status (cycle 242 — ESCALATION ACTIVATED)

**9 consecutive no-merge closures** since #847 (cycle 222): #1028 PP, #1031 nezuko NS-adaptive, #1032 thorfinn Haar-init, #1045 frieren LION-aux, #1047 tanjiro LookAhead, #1048 alphonse cooldown-shape, #1055 askeladd weight-averaging, #1003 fern per-block-TYPE cooldown anneal, **#1074 nezuko GC-embed**.

**Escalation status — TRIGGERED**: pre-staged bigger-bet candidates now active. First escalation assigned this cycle:
- **#1120 nezuko GaLore lm_head** ✅ — dimensionality reduction on Zipfian-heavy substrate

Remaining pre-staged escalation candidates for next idle-student cycles:
- Schedule-Free (Defazio 2024) — replaces load-bearing cooldown entirely
- Shampoo / Distributed-Shampoo body — 2nd-order block-diagonal preconditioner replacing Muon NS
- AggMo body (Lucas 2018) — multi-β momentum bank with simultaneous (not temporal) β variation
- Sophia aux (Liu 2023) — Hutchinson Hessian-diag estimator (HVP per K steps — borderline on "1 fwd-bwd per step" rule; defer unless clean clarification)
- MuonR² / iterated NS refinement

**Mitigation alongside escalation**: 8 fresh axes opened across cycles 230-242 + 1 remaining PP confirmation chain (#1028 edward). Adan-on-aux #1113 in flight is itself a 2nd OPTIMIZER-CLASS-aux observation that approaches partial fence if it also regresses.

### Mechanism axes coverage (cycle 242, 8 chains active)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| **LM_HEAD-GRADIENT-SUBSPACE-PROJECTION (GaLore)** | **#1120 nezuko NEW (escalation)** | WIP fresh | First plateau escalation; low-rank dimensionality reduction on Zipfian-heavy lm_head |
| OPTIMIZER-CLASS-aux (Adan, 2nd obs) | #1113 fern | WIP fresh | Grad-difference momentum + extrapolated-grad denominator |
| AUX-WEIGHT-DECAY (per-group) | #1100 askeladd | WIP — Arm B running | Arm A finished 3.26962 drift PASS, Arm B step 275 |
| DECOUPLED-AUX-PRECONDITIONER (per-group β1) | #1092 tanjiro | WIP fresh | Option 2 corrected: lm_head 0.70 + embed 0.95 |
| BODY-MUON-WEIGHT-DECAY | #1091 alphonse | WIP — Arm A done | Arm A drift PASS, Arm B chaining |
| GRADIENT-NOISE-INJECTION (body Muon momentum) | #1088 frieren | WIP fresh | Gaussian noise on momentum NS5 input |
| MUON-MOMENTUM-SCHEDULE | #1078 thorfinn | WIP fresh | μ decay temporal: off/linear_full/cooldown_only/high-start |
| SUBTRACTIVE-PRUNING (PP) | #1028 edward | WIP — PP n=3 | ANCHOR=0 candidate, last remaining PP chain |

### Closed-axis fence status (cycle 242)

- AUX PRECONDITIONER COOLDOWN-WINDOW: 5 fences (CLOSED)
- STATE-RESET: 4 fences (CLOSED)
- LM_HEAD WEIGHT-SPACE ROW-MAGNITUDE: 8+ fences (CLOSED)
- NS-ITERATION-ALLOCATION: 4 fences (CLOSED)
- INITIALIZATION-DISTRIBUTION (body Muon): 2 fences (CLOSED)
- OPTIMIZER-CLASS (aux): 1-closure observation (#1045 LION); 2nd obs PENDING via #1113 Adan
- META-OPTIMIZER (body Muon): 1-closure observation (#1047 LookAhead)
- SCHEDULE-CURVATURE (body Muon): 1-closure observation (#1048 cooldown shape)
- WEIGHT-AVERAGING-POST-TRAINING: 1-closure observation (#1055 SWA/EMA)
- SCHEDULE-CONTINUOUS-LR-MULT (per-block-TYPE): 1-closure observation (#1003 cooldown anneal)
- **GRADIENT-LEVEL-NORMALIZATION (embed): 1-closure observation (#1074 GC) — NEW THIS CYCLE**

## Cycle 239 snapshot (00:50 UTC May 25) — #1003 fern per-block-TYPE Muon LR mult cooldown anneal CLOSED productive-NULL on PP confirmation (textbook PP collapse: N=1 −0.00226 → PP +0.00041 sign-flip; G1+G3 FAIL); SCHEDULE-CONTINUOUS-LR-MULT 1-closure observation; fern reassigned #1113 (ADAN OPTIMIZER ON AUX — fresh 2nd OPTIMIZER-CLASS-aux observation, mechanism-distinct from #1045 LION sign-based by grad-difference momentum + n-buffer extrapolated-grad squared); **8 consecutive no-merge closures — PLATEAU PROTOCOL ESCALATION TRIGGER IMMINENT**: next closure without merge = escalation to bigger bets (Schedule-Free, Shampoo, AggMo, Sophia, GaLore pre-staged).

### Activity this cycle

- **#1003 fern** PP n=3 confirmation complete CLOSED productive-NULL: Per-block-TYPE Muon LR mult cooldown anneal. A_mean=3.26852 (drift +0.00096 PASS), B_mean=3.26893 (+0.00137 vs baseline — slight regression). Paired Δ_mean=+0.00041, 1/3 pods direction-correct. 4-gate eval: G1 FAIL (B>baseline), G3 FAIL (1/3 dir-correct). N=1 signal −0.00226 sign-flipped to PP +0.00041 — full sign-flip past zero into mild regression, worse than typical ~0.1× PP collapse. Mechanism interpretation: body-Muon attn=0.80/mlp=1.20 asymmetry is structurally locked into cooldown phase, annealing toward 1.0 during cooldown loses the per-matrix-type advantage where late_peak NS=20 precision most needs it.
- **PR #1113 fern** (assigned this cycle): **Adan optimizer on AUX groups** — fresh OPTIMIZER-CLASS-aux 2nd observation. 4 arms: A=ctrl AdamW, B=Adan default betas (0.98, 0.92, 0.99) mechanism-lead, C=more-responsive betas (0.95, 0.90, 0.99), D=smoother betas (0.98, 0.95, 0.999). Adan's grad-difference 2nd buffer (v_diff) + extrapolated-grad squared (n) buffer give Nesterov-like extrapolation at optimizer level. Mechanism-distinct from #1045 LION (sign-based no per-coord normalization), #1100 askeladd aux wd (post-step shrinkage on AdamW, not optimizer replacement), #1092 tanjiro per-group β1 (HP differentiation within AdamW). Tests if grad-difference momentum reduces lm_head sign-flip rate vs AdamW's 25.6% LR-invariant structural rate (#1045 finding).

### Plateau awareness status (cycle 239 — ESCALATION IMMINENT)

**8 consecutive no-merge closures** since #847 (cycle 222): #1028 PP, #1031 nezuko NS-adaptive, #1032 thorfinn Haar-init, #1045 frieren LION-aux, #1047 tanjiro LookAhead, #1048 alphonse cooldown-shape, #1055 askeladd weight-averaging, #1003 fern per-block-TYPE cooldown anneal.

**Mitigation in place**: 7 fresh axes opened in 7 cycles (#1074 GC, #1078 μ schedule, #1088 noise injection, #1091 body wd, #1092 per-group β1 [Option 2], #1100 aux wd, #1113 Adan-aux) + 1 remaining PP confirmation chain (#1028 edward prune). Breadth strategy compensating.

**Escalation trigger**: If next 1 closure lands without merge, total = 9 consecutive no-merge → ESCALATE. Pre-staged bigger bets:
- **Schedule-Free** (Defazio 2024) — replaces load-bearing cooldown entirely
- **Shampoo / Distributed-Shampoo body** — 2nd-order block-diagonal preconditioner replacing Muon NS
- **AggMo body** (Aggregated Momentum, Lucas 2018) — multi-β momentum bank
- **Sophia aux** (Hutchinson Hessian-diag, Liu 2023) — 2nd-order info on aux
- **GaLore lm_head** (Zhao 2024) — low-rank gradient subspace on Zipfian-heavy lm_head
- **MuonR² / Muon-via-majorization-minimization** — iterated NS refinement

Note: #1113 Adan-aux is itself a 2nd OPTIMIZER-CLASS-aux observation — if it lands productive, it opens new optimizer-family direction; if it regresses, it tightens the fence toward closure.

### Mechanism axes coverage (cycle 239, 8 chains active)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| **OPTIMIZER-CLASS-aux (Adan, 2nd obs)** | **#1113 fern NEW** | WIP fresh | Grad-difference momentum + extrapolated-grad denominator; mechanism-distinct from #1045 LION |
| AUX-WEIGHT-DECAY (per-group) | #1100 askeladd | WIP fresh | First per-group wd differentiation on AdamW aux; lm_head mechanism-lead |
| DECOUPLED-AUX-PRECONDITIONER (per-group β1) | #1092 tanjiro | WIP fresh | Option 2 corrected: lm_head 0.70 + embed 0.95 (faster lm_head Zipfian) |
| BODY-MUON-WEIGHT-DECAY | #1091 alphonse | WIP fresh | Arm A drift PASS, Arm B chaining |
| GRADIENT-NOISE-INJECTION (body Muon momentum) | #1088 frieren | WIP fresh | Gaussian noise on momentum NS5 input |
| MUON-MOMENTUM-SCHEDULE | #1078 thorfinn | WIP fresh | μ decay temporal: off/linear_full/cooldown_only/high-start |
| GRADIENT-LEVEL-NORMALIZATION | #1074 nezuko | WIP fresh | GC on embed (Yong 2020) |
| SUBTRACTIVE-PRUNING (PP) | #1028 edward | WIP — PP n=3 | ANCHOR=0 candidate, last remaining PP chain |

### Closed-axis fence status (cycle 239)

- AUX PRECONDITIONER COOLDOWN-WINDOW: 5 fences (CLOSED)
- STATE-RESET: 4 fences (CLOSED)
- LM_HEAD WEIGHT-SPACE ROW-MAGNITUDE: 8+ fences (CLOSED)
- NS-ITERATION-ALLOCATION: 4 fences (CLOSED)
- INITIALIZATION-DISTRIBUTION (body Muon): 2 fences (CLOSED)
- OPTIMIZER-CLASS (aux): 1-closure observation (#1045 LION); **2nd obs PENDING via #1113 Adan**
- META-OPTIMIZER (body Muon): 1-closure observation (#1047 LookAhead)
- SCHEDULE-CURVATURE (body Muon): 1-closure observation (#1048 cooldown shape)
- WEIGHT-AVERAGING-POST-TRAINING: 1-closure observation (#1055 SWA/EMA)
- **SCHEDULE-CONTINUOUS-LR-MULT (per-block-TYPE): 1-closure observation (#1003 cooldown anneal) — NEW THIS CYCLE**

## Cycle 236 snapshot (23:45 UTC May 24) — #1055 askeladd weight-averaging CLOSED productive-NEG (WEIGHT-AVERAGING-POST-TRAINING 1-closure observation; structural cooldown-vs-averaging mismatch); askeladd reassigned #1100 (AUX-WEIGHT-DECAY axis — first per-group wd differentiation on aux AdamW); 7 consecutive no-merge closures — PLATEAU PROTOCOL ESCALATION: 6 fresh axes opened in 6 cycles + 2 PP chains in flight, but if next 2 closures land without merge, ESCALATE to bigger architectural/optimizer-class swings (Shampoo, Schedule-Free, AggMo, etc.)

### Activity this cycle

- **#1055 askeladd** N=1 4-arm complete CLOSED productive-NEG: Post-training Polyak weight averaging (off/SWA/EMA-0.999/EMA-0.9999) over cooldown window (start_frac=0.7). Arms A=3.27077 ctrl, B=3.28271 val_loss_avg (Δ=+0.01194 SWA), C=3.30021 (Δ=+0.02944 EMA-0.999), D=3.37131 (Δ=+0.10054 EMA-0.9999). Mechanism reading clean and load-bearing:
  - **Monotone-with-decay ordering D>C>B**: slower decay = averaged buffer barely moves from step-2345 init where val/loss≈3.40; val/loss_avg pulls toward that ~3.40 ceiling.
  - **buffer_drift monotonically ordered** (B=15646 < C=23139 < D=23933): slower decay lags further behind live model.
  - **Training trajectory orthogonality holds**: B/C/D unaveraged val tracks A within ±0.003 (within seed-noise σ≈0.00134); the averaging buffer is a side-channel with zero feedback into the optimizer. Mechanism-distinct from #1047 LookAhead (which fed back and disrupted cooldown).
  - **None reach 3.28 on averaged metric**: avg_first_step_to_target=-1 for all 3 arms, while unaveraged twins reach 3.28 at step 3200-3225.
- **#1055 structural diagnosis**: Polyak/SWA averaging is theoretically optimal in the stochastic-gradient-near-convergence regime (small-LR Brownian motion around minimum). The cooldown window is NOT that regime — it's the LR-driven monotonic descent (val/loss drops ~0.08 nats over cooldown: 3.35→3.27). Averaging over a monotonically-descending trajectory pulls the averaged iterate BACK toward higher-loss start of window. The cooldown LR schedule itself does the variance-reduction work SWA was designed for. WEIGHT-AVERAGING-POST-TRAINING axis 1-closure observation (NOT full fence — SWA-with-constant-LR-phase, last-5%-window averaging, EMA on optimizer internals remain mechanistically distinct but deferred as low-ROI on this cooldown-heavy stack).
- **PR #1100 askeladd** (assigned this cycle): **Decoupled AdamW per-group weight decay (AUX-WEIGHT-DECAY)** — fresh axis. Currently `weight_decay=0` flat across all 3 AdamW groups (adam_embed/adam_lm_head/adam_scalars). 4 arms: A=ctrl (all 0), B=lm_head wd=1e-4 (mild), C=lm_head wd=1e-3 (mechanism-lead), D=embed wd=1e-4 (group-specificity test). Motivated by #1045 frieren LION closure finding (AdamW v-buffer LOAD-BEARING for Zipfian lm_head, structural sign-flip 25.6% LR-invariant): wd provides magnitude-control orthogonal to v-buffer per-coord normalization. Mechanism-distinct from #1091 alphonse body-Muon wd (different param group + optimizer family). Distinct from STATE-RESET fence (continuous proportional shrinkage, not buffer reset) and LM_HEAD WEIGHT-SPACE ROW-MAGNITUDE fence (uniform shrinkage, not row-level constraint).
- **Workflow improvement (cycle 236)**: askeladd found and fixed `senpai-pr-guard.py::result_markers()` parser bug at line 25 (`if not raw:` → `if not raw.startswith("{"):`) that blocked `mark_ready_for_review` when advisor comments contained the literal marker token in markdown formatting. Root cause was advisor (me) using the literal token inside a bolded directive in cycle 235 ack. Defensive parser guard against non-JSON-object content after the marker prefix — purely workflow improvement. Advisor templates updated to use "structured-result line" / "terminal results marker" in narrative text going forward.

### Plateau awareness status (cycle 236)

7 consecutive no-merge closures since #847 (cycle 222): #1028 PP (sent for confirmation), #1031 nezuko NS-adaptive, #1032 thorfinn Haar-init, #1045 frieren LION-aux, #1047 tanjiro LookAhead, #1048 alphonse cooldown-shape, #1055 askeladd weight-averaging.

**Mitigation in place**: 6 fresh axes opened in 6 cycles (#1074 GC, #1078 μ schedule, #1088 noise injection, #1091 body wd, #1092 per-group β1, #1100 aux wd) + 2 PP confirmation chains still in flight (#1003 fern winner, #1028 edward prune). Breadth strategy compensating for closure rate.

**Escalation trigger**: if 2 more closures land without merge (i.e. 9 consecutive no-merge), escalate to BIGGER BETS:
- **Schedule-Free** (Defazio 2024) — replaces the load-bearing cooldown entirely, tests if iterate-interpolation can do variance reduction in training rather than post-training
- **Shampoo / Distributed-Shampoo body** — 2nd-order block-diagonal preconditioner replacing Muon NS poly
- **AggMo body** (Aggregated Momentum) — multi-β momentum bank distinct from #1078 schedule
- **Sophia** (Hutchinson-trace Hessian) — implicit 2nd-order on aux
- **GaLore lm_head** — low-rank gradient subspace projection on Zipfian-heavy output projection

### Mechanism axes coverage (cycle 236, 8 chains active)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| **AUX-WEIGHT-DECAY (per-group)** | **#1100 askeladd NEW** | WIP fresh | First per-group wd differentiation on AdamW aux; lm_head mechanism-lead |
| DECOUPLED-AUX-PRECONDITIONER (per-group β1) | #1092 tanjiro | WIP fresh | Spatial AdamW β1 by aux group (sent back cycle 234 with Option 2 corrected arm config) |
| BODY-MUON-WEIGHT-DECAY | #1091 alphonse | WIP fresh | Decoupled post-step shrinkage; wd × {const, cooldown_only} |
| GRADIENT-NOISE-INJECTION (body Muon momentum) | #1088 frieren | WIP fresh | Gaussian noise on momentum NS5 input |
| MUON-MOMENTUM-SCHEDULE | #1078 thorfinn | WIP fresh | μ decay temporal: off/linear_full/cooldown_only/high-start |
| GRADIENT-LEVEL-NORMALIZATION | #1074 nezuko | WIP fresh | GC on embed (Yong 2020) |
| SCHEDULE-CONTINUOUS-LR-MULT (PP) | #1003 fern | WIP — PP n=3 | Arm B tripped threshold |
| SUBTRACTIVE-PRUNING (PP) | #1028 edward | WIP — PP n=3 | ANCHOR=0 candidate |

### Closed-axis fence status (cycle 236)

- AUX PRECONDITIONER COOLDOWN-WINDOW: 5 fences (CLOSED)
- STATE-RESET: 4 fences (CLOSED)
- LM_HEAD WEIGHT-SPACE ROW-MAGNITUDE: 8+ fences (CLOSED)
- NS-ITERATION-ALLOCATION: 4 fences (CLOSED)
- INITIALIZATION-DISTRIBUTION (body Muon): 2 fences (CLOSED)
- OPTIMIZER-CLASS (aux): 1-closure observation (#1045 LION)
- META-OPTIMIZER (body Muon): 1-closure observation (#1047 LookAhead)
- SCHEDULE-CURVATURE (body Muon): 1-closure observation (#1048 cooldown shape)
- **WEIGHT-AVERAGING-POST-TRAINING: 1-closure observation (#1055 SWA/EMA) — NEW THIS CYCLE**

## Cycle 231 snapshot (23:00 UTC May 24) — DUAL CLOSE cycle: #1047 tanjiro LookAhead CLOSED productive-NEG (3 arms regress, slow-anchor disrupts cooldown NS — clean mechanism finding); #1048 alphonse cooldown-shape CLOSED productive-NEG/mixed (Arm B sub-threshold by 61%, C/D productive-NEG); META-OPTIMIZER + SCHEDULE-CURVATURE both 1-closure observations; alphonse reassigned #1091 (BODY-MUON-WEIGHT-DECAY), tanjiro reassigned #1092 (DECOUPLED-AUX-PRECONDITIONER per-group β1)

### Activity this cycle

- **#1047 tanjiro** N=1 4-arm complete CLOSED productive-NEG: LookAhead body Muon (K∈{5,10}, α∈{0.2,0.5}). Arms A=3.26947 ctrl (fs=3200, drift +0.00191 PASS), B=3.28532 K=5/α=0.5 (+0.01585 PRODUCTIVE-NEG), C=3.28055 K=10/α=0.5 (+0.01108 PRODUCTIVE-NEG), D=3.33008 K=5/α=0.2 (+0.06061 PRODUCTIVE-NEG worst). None reached 3.28.
- **#1047 mechanism finding (high-info, headline):** LookAhead is HELPFUL pre-cooldown (B/C ahead through step 2500–2750, Δ@2500: B=−0.00759, C=−0.01586) but HARMFUL during cooldown. Crossover at ~step 3000. Slow-weight anchor pulls fast back toward older preconditioned trajectory, undoing aggressive late-stage NS=20 corrections. α=0.2 worst because smaller α = LARGER pullback (fast loses (1−α)·100% of drift per sync, so 0.2 wipes 80%). K predicts slow_fast L2 ~3.6× B→C (matches scaling); α does not (B/D nearly identical L2). META-OPTIMIZER (body Muon) axis 1-closure observation.
- **#1048 alphonse** N=1 4-arm complete CLOSED productive-NEG/mixed: body Muon cooldown shape sweep (linear/cosine/sqrt/linear_floor). Arms A=3.27043 ctrl (linear, fs=3225, drift +0.00287 PASS just within ±0.003 gate), B=3.26966 (cosine, fs=3075 Δ_fs=−150, **Δ=−0.00077 SUB-THRESHOLD by 61%**), C=3.28454 (sqrt, +0.01411 PRODUCTIVE-NEG), D=3.28483 (linear_floor, +0.01440 PRODUCTIVE-NEG).
- **#1048 mechanism finding:** Body Muon needs FULL linear LR decay to zero. NS=20 late-peak precision consumed by residual error reduction, NOT by larger steps. linear_floor merged for adam_embed (#235) HURTS body Muon — asymmetric param-group geometry (embed has smaller base LR boosted 1.5×, starved without floor; body already has effective LR boost 0.80/1.20 mults, non-starved). SCHEDULE-CURVATURE (body Muon) axis 1-closure observation.
- **PR #1091 alphonse** (assigned this cycle): **Body Muon decoupled weight decay** — fresh BODY-MUON-WEIGHT-DECAY axis. Multiplicative post-step shrinkage `w ← (1 − lr · wd) · w` on muon_attn + muon_mlp only. 4 arms: A=ctrl wd=0, B=wd=0.001 constant, C=wd=0.01 cooldown_only (mechanism-lead: wd activates during cooldown where weight magnitudes inflate), D=wd=0.01 constant. Lit: Loshchilov 2017 AdamW, Lewkowycz & Gur-Ari 2020.
- **PR #1092 tanjiro** (assigned this cycle): **Per-group AdamW β1 differentiation across aux groups (DECOUPLED-AUX-PRECONDITIONER)** — fresh axis. Per-group β1 override for embed/lm_head/scalars in aux AdamW. 4 arms: A=ctrl (uniform β1=0.9), B=lm_head β1=0.85 only (Zipfian rare-token responsiveness), C=embed β1=0.95 + lm_head β1=0.85 (mechanism-lead: asymmetric exploiting Zipfian gradient distribution), D=embed β1=0.95 only. Motivated by #1045 LION closure finding (aux gradient asymmetry is structural). Distinct from AUX PRECONDITIONER COOLDOWN-WINDOW fence (temporal β2) — this is spatial β1 differentiation.

### Mechanism axes coverage (cycle 231, 8 chains active)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| **DECOUPLED-AUX-PRECONDITIONER (per-group β1)** | **#1092 tanjiro NEW** | WIP fresh | Spatial AdamW β1 by aux group (embed/lm_head/scalars) |
| **BODY-MUON-WEIGHT-DECAY** | **#1091 alphonse NEW** | WIP fresh | Decoupled post-step shrinkage; wd × {const, cooldown_only} |
| GRADIENT-NOISE-INJECTION (body Muon momentum) | #1088 frieren | WIP fresh | Gaussian noise on momentum NS5 input |
| MUON-MOMENTUM-SCHEDULE | #1078 thorfinn | WIP fresh | μ decay temporal: off/linear_full/cooldown_only/high-start |
| GRADIENT-LEVEL-NORMALIZATION | #1074 nezuko | WIP fresh | GC on embed (Yong 2020) |
| WEIGHT-AVERAGING-POST-TRAINING | #1055 askeladd | WIP | SWA / EMA Polyak |
| SCHEDULE-CONTINUOUS-LR-MULT (PP) | #1003 fern | WIP — PP n=3 | Arm B tripped threshold |
| SUBTRACTIVE-PRUNING (PP) | #1028 edward | WIP — PP n=3 | ANCHOR=0 candidate |

All 8 mechanism axes active, 0 idle. **Four fresh axes opened in last 4 cycles** (#1074 GC, #1078 Muon-μ, #1088 grad-noise, #1091 body-Muon-WD, #1092 per-group-β1). Two in PP confirmation (#1003 winner-confirm, #1028 prune-confirm).

### Closed-axis fences summary (cycle 231 — 2 new 1-closure observations)

| Class | Closures | Notes |
|---|---|---|
| AUX PRECONDITIONER COOLDOWN-WINDOW | 5 closures | Temporal aux-side β2 schedule |
| STATE-RESET | 4 closures | Parameter reset techniques |
| LM_HEAD WEIGHT-SPACE ROW-MAGNITUDE | 8+ closures | Direct lm_head weight modification |
| NS-ITERATION-ALLOCATION | 4 closures | Per-depth/block-type/layer/per-matrix |
| INITIALIZATION-DISTRIBUTION (body Muon) | 2 closures | Scale + distribution variants |
| OPTIMIZER-CLASS (aux) | 1 obs (#1045) | Sign-only-class insufficient; v-buffer LOAD-BEARING |
| **META-OPTIMIZER (body Muon)** | **1 obs (#1047)** | **Slow-anchor disrupts late_peak cooldown NS corrections** |
| **SCHEDULE-CURVATURE (body Muon cooldown shape)** | **1 obs (#1048)** | **Body needs full linear LR decay to zero; asymmetric vs adam_embed** |

### Decision-rule pattern across cycles 222–231 (11 N=1 outcomes — 9 closures, 2 PP escalations)

| Cycle | PR | Best Δ_vs_A | Decision | Confirmation |
|---|---|---|---|---|
| 222 | #1008 alphonse | −0.00044 | CLOSE NULL | n/a |
| 222 (older) | #988 tanjiro | −0.00168 (16% short) | CLOSE NULL/borderline | n/a |
| 223 | #1003 fern | **−0.00226 (cross by 13%)** | **PP n=3** | in flight |
| 224 | #1020 askeladd | −0.00182 (9% short) | CLOSE NULL/marginal | n/a |
| 227 | #1028 edward | +0.00018 (deep NON-LOAD-BEARING) | **PP n=3 of null** | in flight |
| 228 | #1031 nezuko | −0.00093 (53% short) | CLOSE productive-marginal | n/a |
| 229 | #1032 thorfinn | +0.00245 monotone REG | CLOSE productive-NEG | n/a |
| 230 | #1045 frieren | +0.01871 monotone PRODUCTIVE-NEG | CLOSE productive-NEG | n/a |
| **231** | **#1047 tanjiro** | **+0.01108 (best of 3 PRODUCTIVE-NEG)** | **CLOSE productive-NEG** | n/a |
| **231** | **#1048 alphonse** | **−0.00077 (sub-thresh) + 2× PRODUCTIVE-NEG** | **CLOSE no PP** | n/a |

Six consecutive closures (cycle 228–231: nezuko marginal, thorfinn REG, frieren PRODUCTIVE-NEG, tanjiro PRODUCTIVE-NEG, alphonse mixed). Five mechanism-lead arms negative or sub-threshold across screens. Pattern: **the −0.002 threshold is robust as winner-vs-close boundary**; monotone-with-dose and pre-cooldown-but-cooldown-disrupting patterns are clean mechanism rejections. Two PP chains in flight as the only path to baseline-shift in this batch.

### Plateau awareness (cycles 228–231 = 5 sequential closures, no merge)

Per plateau protocol: 5+ consecutive no-improvement is escalation signal. Currently mitigated by:
- **2 PP confirmation chains** in flight (#1003 winner candidate, #1028 prune candidate) — either could deliver a baseline shift
- **5 fresh mechanism axes** opened in 5 cycles (GC, Muon-μ, grad-noise, body-Muon-WD, per-group-β1) — strategy tier broadened across axes
- Mechanism findings from screens (LION sign-flip = structural, LookAhead slow-anchor breaks cooldown, body-Muon needs LR→0 with floor asymmetry, Haar regression) deliver mechanism diagnostics that are themselves high-info even when they don't merge

If next 2 cycles add 2 more closures with no merge, escalate to BIGGER bets: GaLore/Shampoo per-block preconditioners, schedule-free optimizers, or revisit data-side levers within constraint (tokenization, sequence-packing).

### Operational pattern (cycle 231)

- **W&B subagent verification per closure**: 0 discrepancies in 5 consecutive cycles. Today's cycle 8/8 values match on #1048; #1047 Arm D rms minor transcription nit (6.05e-6 vs 1.0e-5) but doesn't affect decision.
- **DUAL CLOSE in one cycle** — 2 PRs reviewed + 2 fresh axes assigned in single round. First time this round, executes cleanly with mechanism-distinctness tables.
- **Assign fresh axis on closure** continues to compound coverage. 5 fresh axes opened in 5 cycles. All mechanism-distinct from each other + fenced classes.

## Cycle 230 snapshot (22:30 UTC May 24) — #1045 frieren CLOSED productive-NEG (LION on aux all 3 arms regress, sign-flip ~26% LR-invariant = structural); OPTIMIZER-CLASS axis 1-closure observation (not full fence); frieren reassigned #1088 (Body Muon gradient noise — fresh GRADIENT-NOISE-INJECTION axis)

### Activity this cycle

- **#1045 frieren** N=1 4-arm complete CLOSED productive-NEG: LION optimizer on aux (embed, lm_head, scalars) at 3 LR ratios. Arms A=3.26926 (ctrl AdamW, drift +0.00170 PASS), B=3.29644 (lion 0.10× paper, +0.02718 PRODUCTIVE-NEG), C=3.30581 (lion 0.05× conservative, +0.03655 PRODUCTIVE-NEG), D=3.28797 (lion 0.20× aggressive, +0.01871 PRODUCTIVE-NEG best LION). All LION arms miss val_loss≤3.28 target. Monotone in LR ratio (C<B<D — more LR is better but ceiling is +0.019). Sign-flip rate ~25.6–25.8% LR-invariant — structural property of aux gradients, not tunable. W&B verified all 4 runs exact match.
- **Mechanism interpretation (high info):** AdamW v-buffer (RMS-shaping via exp_avg_sq) is LOAD-BEARING on aux for this stack. Zipfian lm_head (50304 output dim) demands per-coordinate magnitude shaping that LION's uniform ±lr cannot express. The sign-only update class is structurally insufficient on this aux setup regardless of LR tuning.
- **OPTIMIZER-CLASS axis 1-closure observation (not full fence).** Other optimizer classes (Adafactor, Sophia, Adan, Tiger, schedule-free) remain mechanistically distinct and unexplored — but the structural insight constrains the family: aux optimizers MUST preserve coordinate-wise magnitude info from gradients. Variants without v-buffer-like component unlikely to recover.
- **PR #1088 frieren** (assigned this cycle): **Body Muon momentum-buffer gradient-noise injection** — fresh GRADIENT-NOISE-INJECTION axis. Hypothesis: inject Gaussian noise into body Muon momentum buffer (post-EMA, pre-NS5) as SGLD-style exploration. The β1=0.95 EMA gives ~20-step smoothing — may over-dampen exploration. RMS-scaled noise on NS5 input each step, momentum buffer never written-back with noise. 4 arms: A=ctrl, B=σ=0.01 constant, C=σ=0.05 cosine-decayed (mechanism-lead — aligns with late_peak NS cooldown), D=σ=0.05 constant. Mechanism-distinct from #1074 (deterministic GC on embed, stochastic noise on body) and #1078 (β1 schedule, separate from buffer-input perturbation).

### Mechanism axes coverage (cycle 230, 8 chains active)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| **GRADIENT-NOISE-INJECTION (body Muon)** | **#1088 frieren NEW** | WIP fresh | Gaussian noise on momentum buffer NS5 input |
| MUON-MOMENTUM-SCHEDULE | #1078 thorfinn | WIP fresh | μ decay: off/linear_full/cooldown_only/high-start |
| GRADIENT-LEVEL-NORMALIZATION | #1074 nezuko | WIP fresh | GC on embed (Yong 2020) |
| WEIGHT-AVERAGING-POST-TRAINING | #1055 askeladd | WIP | SWA / EMA Polyak |
| SCHEDULE-CURVATURE (body Muon cooldown shape) | #1048 alphonse | WIP | linear/cosine/sqrt/linear_floor |
| META-OPTIMIZER (body Muon LookAhead) | #1047 tanjiro | WIP | Zhang et al. 2019 |
| SCHEDULE-CONTINUOUS-LR-MULT (PP) | #1003 fern | WIP — PP n=3 | Arm B tripped threshold |
| SUBTRACTIVE-PRUNING (PP) | #1028 edward | WIP — PP n=3 | ANCHOR=0 candidate |

All 8 mechanism axes active, 0 idle. Three fresh axes started in last 3 cycles (#1074 GC, #1078 Muon-μ, #1088 grad-noise). Two in PP confirmation (#1003 winner-confirm, #1028 prune-confirm).

### Closed-axis fences summary (cycle 230)

| Class | Closures | Notes |
|---|---|---|
| AUX PRECONDITIONER COOLDOWN-WINDOW | 5 closures | Temporal aux-side schedule |
| STATE-RESET | 4 closures | Parameter reset techniques |
| LM_HEAD WEIGHT-SPACE ROW-MAGNITUDE | 8+ closures | Direct lm_head weight modification |
| NS-ITERATION-ALLOCATION | 4 closures | Per-depth/block-type/layer/per-matrix |
| INITIALIZATION-DISTRIBUTION (body Muon) | 2 closures | Scale + distribution variants |
| OPTIMIZER-CLASS (aux) | 1 obs (#1045) | Sign-only-class insufficient; axis open for v-buffer-preserving variants |

### Decision-rule pattern across cycles 222–230 (9 N=1 outcomes)

| Cycle | PR | Best Δ_vs_A | Decision | Confirmation |
|---|---|---|---|---|
| 222 | #1008 alphonse | −0.00044 (sub-noise) | CLOSE NULL | n/a |
| 222 (older) | #988 tanjiro | −0.00168 (miss by 16%) | CLOSE NULL/borderline | n/a |
| 223 | #1003 fern | **−0.00226 (cross by 13%)** | **PP n=3** | in flight |
| 224 | #1020 askeladd | −0.00182 (miss by 9%) | CLOSE NULL/marginal | n/a |
| 227 | #1028 edward | +0.00018 (deep NON-LOAD-BEARING) | **PP n=3 of null** | in flight |
| 228 | #1031 nezuko | −0.00093 (sub-threshold by 53%) | CLOSE productive-marginal | n/a |
| 229 | #1032 thorfinn | +0.00245 (monotone REGRESSION) | CLOSE productive-NEG | n/a |
| **230** | **#1045 frieren** | **+0.01871 (monotone PRODUCTIVE-NEG)** | **CLOSE productive-NEG** | n/a |

Three consecutive productive-NEG closures (#1031 marginal, #1032 REG, #1045 PRODUCTIVE-NEG). Pattern confirmed: the −0.002 threshold remains a robust winner-vs-close boundary; |Δ|≤0.0005 prune boundary; ≥+0.005 productive-NEG band; monotone-with-dose REGRESSION (#1032, #1045) cleanly identifies mechanism-rejection.

### Operational pattern (cycle 230)

- **Stale_wip ack-with-W&B-check** workflow still standard. W&B subagent verification of all 4 student-reported numbers each closure — 0 discrepancies in 3 consecutive closures.
- **Assign fresh axis on closure** continues to compound mechanism-axis coverage. Three fresh axes opened in 3 cycles (228 GC, 229 Muon-μ, 230 grad-noise). All mechanism-distinct from each other + from fenced classes.
- **PP confirmation chains** (#1003 winner, #1028 prune) still in flight — provides decision-rule calibration data once they land.

## Cycle 229 snapshot (21:30 UTC May 24) — #1032 thorfinn CLOSED productive-NEG (Haar-orthogonal init REGRESSION, monotone A<C<B<D, Arm D never reaches 3.28); thorfinn reassigned #1078 (Body Muon momentum schedule — fresh MUON-MOMENTUM-SCHEDULE axis)

### Activity this cycle

- **#1032 thorfinn** N=1 4-arm complete CLOSED productive-NEG: Haar-measure orthogonal init for body Muon matrices, 4-arm gain sweep. Arms A=3.26854 (ctrl drift PASS), B=3.27364 (gain=1.0, +0.00510), C=3.27099 (gain=0.5, +0.00245), D=3.28018 (gain=2.0, +0.01164, **never reaches 3.28**). Monotone regression A < C < B < D. sv_std~1e-7 across B/C/D = machine-epsilon, Haar init landed cleanly — the regression is mechanistic. Student analysis correct: Kaiming's per-shape Marchenko-Pastur spectral norms (attn~0.82, mlp.fc~1.63, mlp.proj~0.41) are empirically near-optimal; uniform-spectrum Haar destroys shape-aware variance. NS "early compression cost" is essentially zero in practice. W&B verified all 4 runs exact match.
- **INITIALIZATION-DISTRIBUTION (body Muon) axis CLOSED.** Scale variants (#452, #163) + distribution variants (this PR) both fenced. Kaiming-uniform is locally optimal for body Muon. Unexplored: embed/lm_head init (different param group, different optimizer — explicitly flagged by student in follow-up notes).
- **PR #1078 thorfinn** (assigned this cycle): **Body Muon momentum (μ) decay schedule** — fresh MUON-MOMENTUM-SCHEDULE axis. Hypothesis: optimal μ is phase-dependent (high early, lower during cooldown). Baseline has constant μ=0.95. 4 arms: A=ctrl (constant μ=0.95), B=linear_full (0.95→0.85), C=cooldown_only (0.95→0.85 during steps 2345–3350), D=linear_full (0.99→0.85 start higher). Arm C is mechanism-lead (cooldown-only annealing, aligned with late_peak NS and stochastic NS cooldown already in stack). Implementation: `get_muon_mu()` helper + `optimizer2.defaults["mu"] = mu_this_step` before `optimizer2.step()`. Mechanism-distinct from all in-flight and fenced classes.

### Mechanism axes coverage (cycle 229, 8 chains active)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| **MUON-MOMENTUM-SCHEDULE** | **#1078 thorfinn NEW** | WIP fresh | μ decay: off/linear_full/cooldown_only/high-start |
| GRADIENT-LEVEL-NORMALIZATION | #1074 nezuko | WIP fresh | GC on embed (Yong 2020) |
| WEIGHT-AVERAGING-POST-TRAINING | #1055 askeladd | WIP | SWA / EMA Polyak |
| SCHEDULE-CURVATURE (body Muon cooldown shape) | #1048 alphonse | WIP | linear/cosine/sqrt/linear_floor |
| META-OPTIMIZER (body Muon LookAhead) | #1047 tanjiro | WIP | Zhang et al. 2019 |
| OPTIMIZER-CLASS (aux replacement) | #1045 frieren | WIP | LION vs AdamW |
| SCHEDULE-CONTINUOUS-LR-MULT (PP) | #1003 fern | WIP — PP n=3 | Arm B tripped threshold |
| SUBTRACTIVE-PRUNING (PP) | #1028 edward | WIP — PP n=3 | ANCHOR=0 candidate |

All 8 mechanism axes active, 0 idle. Two fresh axes started this + last cycle (#1074, #1078). Two in PP confirmation (#1003, #1028).

### Closed-axis fences summary (cycle 229)

| Class | Closures |
|---|---|
| AUX PRECONDITIONER COOLDOWN-WINDOW | 5 closures (#1020+#652+#629+#929+#919+#967) |
| STATE-RESET | 4 closures (#988+#998+#163+#711) |
| LM_HEAD WEIGHT-SPACE ROW-MAGNITUDE | 8+ closures |
| NS-ITERATION-ALLOCATION | 4 closures (#710+#724+#145+#1031) |
| **INITIALIZATION-DISTRIBUTION (body Muon)** | **scale: #452/#163; distribution: #1032 (this cycle)** |

## Cycle 228 snapshot (20:00 UTC May 24) — #1031 nezuko CLOSED productive-marginal (NS-ALLOCATION CLASS FENCED); nezuko reassigned #1074 (Gradient Centralization on embed — fresh GRADIENT-LEVEL-NORMALIZATION axis)

### Activity this cycle

- **#1031 nezuko** N=1 4-arm complete CLOSED productive-marginal: NS adaptive residual stopping. Arms A=3.26852 (ctrl, drift PASS), B=3.26912 (expanded MAX=16/20, +0.00060), C=**3.26759** (iso-budget MAX=12/16, **Δ_vs_A=−0.00093 sub-MARGINAL**), D=3.27056 (τ=0.02 tighter, +0.00204 REGRESSION). Arm C is best (iso-budget τ=0.05 MAX=12); dose-response monotone in mean_ns_actual (11.18 < 11.92 < 13.41 = better to worse); mechanism fires (heterogeneous std=2.88–4.18 per step) but allocation-pattern signal is sub-threshold by 53%. Student explicitly recommended against PP escalation. Closed per pattern from cycles 222–227: borderline N=1 misses <−0.002 → close productive-marginal. W&B confirmed all 4 runs exact match.
- **NS-ITERATION-ALLOCATION CLASS FENCED** across 4 closures: #710 per-depth static (NEG) + #724 per-block-type static (NEG) + #145 per-layer sigmoid (bug) + **#1031 per-matrix dynamic residual-stop (marginal this PR)**. NS iteration count is a low-leverage axis at current operating point. Future NS work must target algorithm (#290 domain, coefficient form) or orthogonalization *method* — not iteration budget allocation.
- **Cooldown ceiling over-budgeted finding from #1031:** NS_ITERS_COOLDOWN=16 is over-budgeted — binding rate 0–50% in adaptive arms, never saturating. Candidate for future subtractive probe via edward's #1028 path.
- **PR #1074 nezuko** (assigned this cycle): **Gradient Centralization on embed group** — fresh GRADIENT-LEVEL-NORMALIZATION axis (Yong et al. 2020 ECCV). Mechanism: subtract per-row or per-column mean from embed gradient before AdamW step, forcing embed updates to have zero mean along that axis. Column-centering (Arm B) is the mechanism-lead: removes the per-embedding-dim systematic gradient shared across all in-batch tokens (the LM head's output bias), leaving only per-token differential gradient signal. 4 arms: A=ctrl, B=col-center (dim=0), C=row-center (dim=1), D=both. Implementation: ~8 lines around `optimizer1.step()`, `NANOGPT_EMBED_GRAD_CENTRING={0,1,2,3}`. Mechanism-distinct from all in-flight and all fenced classes.

### Mechanism axes coverage (cycle 228, 8 chains active)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| **GRADIENT-LEVEL-NORMALIZATION** | **#1074 nezuko NEW** | WIP fresh | GC on embed (Yong 2020); col-center dim=0 is mechanism-lead |
| WEIGHT-AVERAGING-POST-TRAINING | #1055 askeladd | WIP | SWA / EMA Polyak |
| SCHEDULE-CURVATURE (body Muon cooldown shape) | #1048 alphonse | WIP | linear/cosine/sqrt/linear_floor |
| META-OPTIMIZER (body Muon LookAhead) | #1047 tanjiro | WIP | Zhang et al. 2019 |
| OPTIMIZER-CLASS (aux replacement) | #1045 frieren | WIP | LION vs AdamW |
| INITIALIZATION-DISTRIBUTION (body) | #1032 thorfinn | WIP | Haar orthogonal |
| SCHEDULE-CONTINUOUS-LR-MULT (PP) | #1003 fern | WIP — PP n=3 phase | Arm B tripped threshold |
| SUBTRACTIVE-PRUNING (PP) | #1028 edward | WIP — PP n=3 phase | ANCHOR=0 candidate (#847 prune) |

All 8 mechanism axes active; none idle. Two in PP confirmation phase (#1003 winner-confirm, #1028 prune-confirm). One fresh axis just started (#1074 nezuko GC).

### Closed-axis fences summary (cycle 228)

| Class | Closures |
|---|---|
| AUX PRECONDITIONER COOLDOWN-WINDOW | 5 closures (#1020+#652+#629+#929+#919+#967) |
| STATE-RESET | 4 closures (#988+#998+#163+#711) |
| LM_HEAD WEIGHT-SPACE ROW-MAGNITUDE | 8+ closures |
| **NS-ITERATION-ALLOCATION** | **4 closures (#710+#724+#145+#1031)** |

## Cycle 227 snapshot (18:00 UTC May 24) — #1028 edward N=1 4-arm pruning ablation TERMINAL; SENT BACK for PP n=3 of Arm C (drop EMBED_INIT_ANCHOR — first SUBTRACTIVE candidate identified)

### Activity this cycle

- **#1028 edward** N=1 4-arm subtractive sweep complete: pruning ablation of merged stack (NS_STOCHASTIC #787, EMBED_INIT_ANCHOR #847, EMBED_COOLDOWN_SHAPE #235). Arms A=3.26810 (ctrl, drift +0.00054 PASS), B=3.27051 (NS_STOCH=0, +0.00241 STILL LOAD-BEARING), C=**3.26828 (ANCHOR=0, +0.00018 NON-LOAD-BEARING ⚠️)**, D=3.26974 (COOLDOWN_SHAPE=linear, +0.00164 STILL LOAD-BEARING just barely). Same pod, same seed=0, sequential runs — asymmetric Δ across B/C/D structurally convincing against pod-drift. **Best treatment arm C (3.26828) is +0.00072 above baseline mean; not merge-eligible as-is.** SENT BACK for **PP n=3 confirmation of Arm C** (interleaved 6 runs at seeds {0,1,2} × {ANCHOR=0.001, ANCHOR=0.0}). Pre-staged decision rules: PRUNE-CONFIRM (`|Δ|≤0.001` AND `μ_off≤3.27006`) → follow-up PR to remove ANCHOR; WIN (`Δ≤−0.002` AND statistical-significance) → merge as new baseline; REGRESS (`Δ≥+0.001`) → close productive-NEG; AMBIGUOUS → judgment call. ETA ~12 GPU-hours.
- **Headline finding (n=1):** EMBED_INIT_ANCHOR_LAMBDA (#847, the most recent merge) appears NON-LOAD-BEARING in the current post-#847 stack composition. This is the high-information outcome the pruning ablation was designed to detect. Methodology validated: 7.5h single-pod compute produced 3-of-3 distinct outcomes across 3 different aux-side mergers, clean separation between LOAD-BEARING and NON-LOAD-BEARING signals.
- **Second PP confirmation chain in flight this round.** First was #1003 fern (PP of a winner candidate). #1028 edward is PP of a null/prune candidate. The decision-rule pattern (cycles 222-227) now spans both directions: winner-confirmation and prune-confirmation.

### Decision-rule pattern across cycles 222-227

Last 6 cycles of N=1 sweep outcomes:

| Cycle | PR | Best Δ_vs_A | Decision | Confirmation status |
|---|---|---|---|---|
| 222 | #1008 alphonse | −0.00044 (sub-noise) | CLOSE NULL | n/a (closed) |
| 222 (older) | #988 tanjiro | −0.00168 (miss by 16%) | CLOSE NULL/borderline | n/a (closed) |
| 223 | #1003 fern | **−0.00226 (cross by 13%)** | **PP n=3** | in flight |
| 224 | #1020 askeladd | −0.00182 (miss by 9%) | CLOSE NULL/marginal | n/a (closed) |
| 227 | **#1028 edward** | +0.00018 (deep NON-LOAD-BEARING) | **PP n=3 of null** | in flight |

The −0.002 signal threshold continues to function as the meaningful winner-vs-close boundary; **separately, the |Δ|≤0.0005 NON-LOAD-BEARING boundary now functions as the prune-vs-close boundary**. Both PP confirmation chains (#1003 winner + #1028 prune) will land in the next ~24h and inform threshold calibration.

### Mechanism axes coverage (cycle 227, 8 chains active — edward back to WIP for PP phase)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| WEIGHT-AVERAGING-POST-TRAINING | #1055 askeladd | WIP — Arm A 90% | SWA / EMA Polyak |
| SCHEDULE-CURVATURE (body Muon cooldown shape) | #1048 alphonse | WIP | linear/cosine/sqrt/linear_floor |
| META-OPTIMIZER (body Muon LookAhead) | #1047 tanjiro | WIP — Arm A nearing complete | Zhang et al. 2019 |
| OPTIMIZER-CLASS (aux replacement) | #1045 frieren | WIP | LION vs AdamW |
| INITIALIZATION-DISTRIBUTION (body) | #1032 thorfinn | WIP | Haar orthogonal |
| PRECONDITIONER-ADAPTIVE (NS) | #1031 nezuko | WIP | NS adaptive residual stop |
| SCHEDULE-CONTINUOUS-LR-MULT (PP) | #1003 fern | WIP — PP n=3 phase | Arm B tripped threshold |
| **SUBTRACTIVE-PRUNING (PP)** | **#1028 edward** | **WIP — PP n=3 phase** | **Arm C ANCHOR=0 candidate (#847 prune) — sent back this cycle** |

All 8 mechanism axes still active. Two of them (#1003 fern, #1028 edward) are now in PP confirmation phase.

## Cycle 226 snapshot (15:30 UTC May 24) — #1055 askeladd stale_wip acked (Arm A 90% complete, control config validated); no idle students, no review-ready PRs

### Activity this cycle

- **#1055 askeladd stale_wip acked**: Post-training weight averaging (SWA/EMA Polyak) 4-arm sweep — PR assigned at 14:14 UTC, stale_wip flagged ~45-60min later. W&B check on `g1r4-askeladd/weight-averaging-swa-ema` group found one run active: `9cgbsvpo` arm-A control (`nanogpt_weight_avg_mode=off`), step 3015/3350 (90%), val/loss=3.3045, runtime 101min. Config validated against assignment template (mode=off for Arm A control; B/C/D will set mode=swa/ema with start_frac=0.7 and decay=0.999/0.9999 respectively).
- **SWA/EMA-specific diagnostic asks** posted in ack: required terminal SENPAI-RESULT telemetry is `val/loss_avg` (averaged-model val pass — the headline mechanism check), `avg_first_step_to_target`, averaging start step, EMA effective lookback (decay=0.999 ⇒ ~1000-step horizon ≈ averaging window of ~1005 steps; decay=0.9999 ⇒ ~10000-step horizon, expected to barely update), and L2/cosine distance between training and averaged weights at end of training. Comparison rule: arm B/C/D `val/loss_avg` vs arm A `val/loss` (averaging is the mechanism; live-model val/loss is unchanged across arms by mechanism-distinctness). Mechanism-class boundary check restated: if any feedback from averaged weights to live optimizer, shifts into LookAhead class.
- **No idle students, no review-ready PRs**: all 8 chains active.

### Operational pattern: stale_wip flagged for 5 consecutive cycles (222-226)

| Cycle | PR | Student | Mechanism | Pattern observed |
|---|---|---|---|---|
| 222b | #1032 | thorfinn | Haar orthogonal init | Arm A ~80% complete + duplicate Arm B race |
| 223 | #1031 | nezuko | NS adaptive residual stop | Arm A done, Arm B running, no per-arm acks |
| 224b | #1045 | frieren | LION aux | Arm A running, no per-arm acks |
| 225 | #1047 | tanjiro | LookAhead body Muon | Arm A 90% + duplicate Arm A restart |
| 226 | #1055 | askeladd | SWA/EMA Polyak | Arm A 90% complete, 45-60min post-assignment |

**Pattern: 5 cycles in a row, the only advisor action is acking a healthy stale_wip.** The harness's stale_wip threshold appears to be ~45-60min of silence, which fires on every newly-assigned PR before the first arm completes (~80-100min). It also fires on between-arm silence on multi-arm sweeps. The flag is doing its operational job (would catch real stuck pods) but is producing a high false-positive rate against the current student behavior (post terminal not per-arm). **Decision: continue acking with W&B-check pattern** — costs ~5min per cycle, no policy change. The per-arm-ping reminder is now standard boilerplate; whether students adopt it is up to them.

### Mechanism axes coverage (cycle 226, 8 chains active — unchanged from cycle 224-225)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| WEIGHT-AVERAGING-POST-TRAINING | **#1055 askeladd** | WIP — Arm A 90% | SWA / EMA Polyak (Izmailov 2018, Polyak 1992); stale_wip acked this cycle |
| SCHEDULE-CURVATURE (body Muon cooldown shape) | #1048 alphonse | WIP | linear/cosine/sqrt/linear_floor |
| META-OPTIMIZER (body Muon LookAhead) | #1047 tanjiro | WIP — Arm A nearing complete | Zhang et al. 2019 |
| OPTIMIZER-CLASS (aux replacement) | #1045 frieren | WIP | LION vs AdamW |
| INITIALIZATION-DISTRIBUTION (body) | #1032 thorfinn | WIP | Haar orthogonal |
| PRECONDITIONER-ADAPTIVE (NS) | #1031 nezuko | WIP | NS adaptive residual stop |
| SCHEDULE-CONTINUOUS-LR-MULT (PP) | #1003 fern | WIP — PP n=3 phase | Arm B tripped threshold, PP requested |
| SUBTRACTIVE-PRUNING | #1028 edward | WIP | merged stack flag removal |

## Cycle 225 snapshot (14:45 UTC May 24) — #1047 tanjiro stale_wip acked (Arm A near complete + duplicate restart flagged); no idle students, no review-ready PRs

### Activity this cycle

- **#1047 tanjiro stale_wip acked**: LookAhead body Muon 4-arm sweep. W&B check on `g1r4-tanjiro/lookahead-body-muon` group found two Arm A runs simultaneously active:
  - `osqg264j` arm-A-ctrl, step 3015/3350 (90%), val/loss=3.3033, runtime 106m — on track to finish soon
  - `06yf866l` arm-A-ctrl, step 125/3350, val/loss=4.6119, runtime 11m — duplicate restart launched ~14:32 UTC
  - Both runs have `nanogpt_lookahead_k=0` (control config), `senpai_seed=0`. Same duplicate-control pattern as #1032 thorfinn earlier this round.
  - Stale_wip comment asks: (1) duplicate-Arm-A resolution, (2) confirm B/C/D will run sequentially after A, (3) per-arm terminal pings, (4) `lookahead/slow_fast_rms` telemetry for B/C/D — the mechanism-check is the PR's headline contribution beyond val/loss numbers. Diagnostic asks tuned to LookAhead specifics: slow-fast L2 should scale ~2x with K (5→10) at fixed α=0.5; α=0.2 (Arm D) should show larger steady-state drift than α=0.5 (Arm B) at same K.
- **No idle students, no review-ready PRs**: all 8 chains active, no new assignments.

### Mechanism axes coverage (cycle 225, 8 chains active — unchanged from cycle 224)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| WEIGHT-AVERAGING-POST-TRAINING | #1055 askeladd | WIP fresh | SWA / EMA Polyak (Izmailov 2018, Polyak 1992) |
| SCHEDULE-CURVATURE (body Muon cooldown shape) | #1048 alphonse | WIP | linear/cosine/sqrt/linear_floor |
| META-OPTIMIZER (body Muon LookAhead) | **#1047 tanjiro** | WIP — Arm A near complete | Zhang et al. 2019; stale_wip acked this cycle |
| OPTIMIZER-CLASS (aux replacement) | #1045 frieren | WIP | LION vs AdamW |
| INITIALIZATION-DISTRIBUTION (body) | #1032 thorfinn | WIP | Haar orthogonal |
| PRECONDITIONER-ADAPTIVE (NS) | #1031 nezuko | WIP | NS adaptive residual stop |
| SCHEDULE-CONTINUOUS-LR-MULT (PP) | #1003 fern | WIP — PP n=3 phase | Arm B tripped threshold, PP requested |
| SUBTRACTIVE-PRUNING | #1028 edward | WIP | merged stack flag removal |

### Operational pattern: stale_wip cycles 222-225

Four consecutive cycles flagged stale_wip on a student PR (#1032 thorfinn, #1031 nezuko, #1045 frieren, #1047 tanjiro). In every case the W&B health check found Arm A (or earlier arm) running normally, one or more duplicate runs from race-condition during arm launch, and zero post-launch comments from the student. **The stale_wip flag is functioning correctly** (catches idle students if real) but is firing on healthy chains because students complete arms without posting per-arm acks until terminal SENPAI-RESULT. **Decision: continue ack-with-W&B-check pattern** — the cost of acking a healthy run is small vs. the cost of missing a stuck run. Per-arm-ping reminder is now standard across these cycles.

## Cycle 224 snapshot (14:30 UTC May 24) — #1020 askeladd CLOSED productive-NULL/marginal; askeladd reassigned #1055 (Post-training weight averaging — fresh WEIGHT-AVERAGING-POST-TRAINING axis)

### Activity this cycle

- **#1020 askeladd** CLOSED productive-NULL/marginal: AdamW ε UP-ramp 4-arm magnitude sweep. Arms A=3.26959 (1e-10 ctrl, drift +0.00203 PASS), B=**3.26777** (1e-8, Δ_vs_A=**−0.00182 MARGINAL**), C=3.27249 (1e-6, +0.00290 REGRESSION), D=aborted (1e-4). Clean monotonic reversal-shaped curve; mechanism directionally confirmed (small ε floor at cooldown end useful, +4 orders oversoftens adaptive step). B misses signal threshold (−0.002) by 9%; B's val/loss = baseline + 0.00021, essentially recovers Arm A drift not improving on baseline. **Closed rather than escalated to PP**: distinct from #1003 fern's −0.00226 (which crossed threshold and was sent for PP).
- **Cross-PR axis closure language:** AUX PRECONDITIONER COOLDOWN-WINDOW CLASS FENCED across 5 independent closures: #1020 ε UP-ramp + #652 ε DOWN-ramp NEG + #629 + #929 v_t floors + #919 β₁ anneal + #967 β₂ anneal. Post-#847 AdamW (β₂=0.99, ε=1e-10) is at the right preconditioner-adaptivity operating point. Future cooldown-window work must target other mechanisms or use structural changes (per-group ε, post-step averaging, different optimizer class).
- **PR #1055 askeladd** (assigned this cycle): **Post-training weight averaging (SWA / EMA Polyak)** — fresh WEIGHT-AVERAGING-POST-TRAINING axis. Theoretical motivation: Polyak & Juditsky 1992; Izmailov et al. 2018 SWA. Mechanism-distinct from #1047 tanjiro LookAhead (LookAhead writes averaged weights back to fast optimizer, modifies training trajectory; SWA/EMA averages in separate buffer with no feedback, training unchanged) and from #711 Muon EMA structural mods (EMA inside momentum buffer; this is EMA of model weights). 4 arms: A=off ctrl, B=SWA uniform last-30%, C=EMA decay=0.999 last-30%, D=EMA decay=0.9999 last-30%.

### Mechanism axes coverage (cycle 224, 8 chains active)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| **WEIGHT-AVERAGING-POST-TRAINING** | **#1055 askeladd NEW** | WIP fresh | SWA / EMA Polyak (Izmailov 2018, Polyak 1992) |
| SCHEDULE-CURVATURE (body Muon cooldown shape) | #1048 alphonse | WIP | linear/cosine/sqrt/linear_floor |
| META-OPTIMIZER (body Muon LookAhead) | #1047 tanjiro | WIP | Zhang et al. 2019 |
| OPTIMIZER-CLASS (aux replacement) | #1045 frieren | WIP | LION vs AdamW |
| INITIALIZATION-DISTRIBUTION (body) | #1032 thorfinn | WIP | Haar orthogonal |
| PRECONDITIONER-ADAPTIVE (NS) | #1031 nezuko | WIP | NS adaptive residual stop |
| SCHEDULE-CONTINUOUS-LR-MULT (PP) | #1003 fern | WIP — PP n=3 phase | Arm B tripped threshold, PP requested |
| SUBTRACTIVE-PRUNING | #1028 edward | WIP | merged stack flag removal |

Eight mechanism axes in flight, all mutually mechanism-distinct. Weight-averaging-post-training is a genuinely fresh mechanism class — first time any model-output aggregation technique has been tested on this stack.

### Decision-rule pattern reflection (cycles 222-224)

Last 3 cycles closed three borderline N=1 results without PP escalation:
- #1008 alphonse: max Δ_vs_A = −0.00044 (sub-noise) → closed NULL
- #988 tanjiro: best Δ_vs_A = −0.00168 (misses by 16%) → closed NULL/borderline
- #1020 askeladd: best Δ_vs_A = −0.00182 (misses by 9%) → closed NULL/marginal

And sent one to PP:
- #1003 fern: best Δ_vs_A = −0.00226 (crosses threshold by 13%) → PP n=3 requested

**Pattern: the −0.002 signal threshold is functioning as the meaningful decision boundary** between close-vs-PP. Borderline misses by single-digit percent are closing without PP regardless of mechanism plausibility — this preserves GPU budget for fresh mechanism axes (which is the highest-EV use of student time per directive). #1003's PP is the first confirmation chain since the round started — its result will inform whether the threshold calibration is well-tuned.

## Cycle 223 snapshot (14:00 UTC May 24) — #1003 fern N=1 4-arm complete (Arm B Δ_vs_A=−0.00226 tripped signal threshold); SENT BACK for PP n=3 confirmation; #1031 nezuko stale_wip acked (chain healthy)

### Activity this cycle

- **#1003 fern** N=1 4-arm screen complete: per-block-TYPE Muon LR mult cooldown anneal. Arms A=3.27042 (off ctrl, drift +0.00286 — right at ±0.003 edge), B=**3.26816 (Δ_vs_A=−0.00226, both anneal — TRIPS signal threshold)**, C=3.26949 (mlp_only, −0.00093 NULL), D=3.26875 (attn_only, −0.00167 just outside NULL). Student mechanism reading: attn LR mult release (0.80→1.0) during cooldown carries 74% of B's signal magnitude; mlp release contributes weakly. **Sent back for PP n=3 confirmation of Arm B (target=both)**. Pre-staged merge gates: G1 ∧ G2 ∧ G3 required. Even under 90% PP collapse, B_PP_mean ≈ 3.26733 still clears G1 if A_PP reproduces baseline — within-chain structure is robust to magnitude collapse. ETA ~18 GPU-hours.
- **#1031 nezuko stale_wip acked**: NS adaptive residual stopping chain. Arm A finished (3.2685, fs=3200, drift +0.00094 PASS), Arm B running (heartbeat 32min stale but state=running). Comment requested per-arm pings + NS adaptive-stop telemetry (mean_actual_iters, std_actual_iters, τ-binding rate) on terminal.
- **No new assignment this cycle**: fern's PR is back in WIP for PP confirmation, all 8 students productive.

### Mechanism axes coverage (cycle 223, 8 chains active)

| Axis | Active PR | Status | Notes |
|---|:---:|:---:|---|
| SCHEDULE-CURVATURE (body Muon cooldown shape) | #1048 alphonse | WIP fresh | linear/cosine/sqrt/linear_floor |
| META-OPTIMIZER (body Muon LookAhead) | #1047 tanjiro | WIP | Zhang et al. 2019 |
| OPTIMIZER-CLASS (aux replacement) | #1045 frieren | WIP | LION vs AdamW |
| INITIALIZATION-DISTRIBUTION (body) | #1032 thorfinn | WIP active | Arm A done 3.2685, Arm B running |
| PRECONDITIONER-ADAPTIVE (NS) | #1031 nezuko | WIP active | Arm A done 3.2685, Arm B running |
| **SCHEDULE-CONTINUOUS-LR-MULT (per-block-TYPE)** | **#1003 fern PP** | **WIP — PP n=3 phase** | **Arm B tripped threshold, PP requested** |
| SCHEDULE-CONTINUOUS (ε) | #1020 askeladd | WIP | AdamW ε UP-ramp cooldown |
| SUBTRACTIVE-PRUNING | #1028 edward | WIP | merged stack flag removal |

Eight mechanism axes in flight, all mutually mechanism-distinct. **First PP confirmation chain of this round** is in progress (#1003 fern).

### Notable pattern this cycle

- **Multiple Arm A drift gate PASS readings** across recent chains: #1031 nezuko (+0.00094), #1032 thorfinn (+0.00094), #1003 fern (+0.00286). The nezuko/thorfinn replications at +0.00094 are remarkably consistent — may be a structural drift floor on the post-#847 stack at seed-1, while fern's +0.00286 at a different seed shows the wider envelope of seed-drift on this stack. Useful prior for future drift-gate calibration: **expect roughly +0.0009 systematic drift in N=1 paired-seed Arm A reproductions, with seed-drift envelope up to ±0.003.**
- **Stale_wip pattern across cycles 222→223**: Three PRs flagged stale_wip in two consecutive cycles (#1032, #1031, plus earlier #1008/#1020) — all turned out to have healthy training chains with terminated Arm A controls; the common failure mode is students not posting per-arm acks. The post-#998/#1008 process discipline (per-arm pings) appears to need restating in each assignment template.

## Cycle 222 snapshot (13:25 UTC May 24) — #1008 closed productive-NULL; alphonse reassigned #1048 — body Muon LR cooldown shape sweep (fresh SCHEDULE-CURVATURE axis)

### Activity this cycle

- **#1008 alphonse** CLOSED productive-NULL: NS static-c operating-point sweep. Drift gate Arm A PASS (3.26887, +0.00131). Arms A=3.26887 (linear_ramp_down ctrl), B=3.26886 (static_c065, −0.00001 tied), C=3.26895 (static_c070, +0.00008), D=**3.26843** (static_c040, **−0.00044**). All arms inside productive-NULL ±0.0015 band; max |Δ| = 0.00044 ≈ 0.09σ (single-seed σ≈0.005 from #998 insight); all arms identical fst=3200. **NS polynomial coefficient operating point within [0.28, 0.70] is NOT load-bearing at trajectory granularity.** Student mechanism reading: #290's linear_ramp_down win was **endpoint-driven** (c=0.28 in cooldown), not trajectory-driven — static-c=0.65 and 0.70 match the ramp's averaging-over-time to within 0.00008. The cooldown LR schedule + NS iteration count schedule together absorb NS-coef variations in this range.
- **Cross-PR axis closure language:** NS polynomial coefficient operating point within [0.28, 0.70] CLOSED productive-NULL on this stack. NS *iteration count* axis (#1031 in-flight, adaptive residual stop) remains open and mechanism-distinct. Future NS-precision work should pivot to: (a) endpoint-driven static c=0.28 test, or (b) paired NS-coef × Muon-LR coupling retune (Shulgin et al. 2026 precision-LR coupling).
- **PR #1048 alphonse** (assigned this cycle): **Body Muon LR cooldown shape sweep** — fresh SCHEDULE-CURVATURE axis. Body Muon (`muon_attn` + `muon_mlp`) currently uses hardcoded linear cooldown (`(1 − progress) / cooldown_frac` at lines 984-1010 of train_gpt_simple.py); only embed has configurable shape (`NANOGPT_EMBED_COOLDOWN_SHAPE` envvar). Mirror image of #235 merged (embed-only linear_floor). Hypothesis: shape interacts with NS=20 cooldown precision and `late_peak` NS shape — sqrt/cosine hold higher LR through late cooldown (e.g., at progress=0.85, NS late-peak transition, sqrt eta≈0.46 vs linear eta≈0.21 = 2.2× higher). Mechanism-distinct from #1003 fern (LR-MULT-MULT per-block-type anneal), #1031 nezuko (NS precision not LR), #235 merged (embed-only floor). 4 arms: A=linear ctrl, B=cosine, C=sqrt (slower-decay), D=linear_floor at 0.15.

### Mechanism axes coverage (cycle 222, 8 chains)

| Axis | Active PR | Notes |
|---|:---:|---|
| **SCHEDULE-CURVATURE (body Muon cooldown shape)** | **#1048 alphonse NEW** | linear/cosine/sqrt/linear_floor |
| META-OPTIMIZER (body Muon LookAhead) | #1047 tanjiro | Zhang et al. 2019 |
| OPTIMIZER-CLASS (aux replacement) | #1045 frieren | LION vs AdamW |
| INITIALIZATION-DISTRIBUTION (body) | #1032 thorfinn | Haar orthogonal |
| PRECONDITIONER-ADAPTIVE (NS) | #1031 nezuko | NS adaptive residual stop |
| SCHEDULE-CONTINUOUS (LR-MULT) | #1003 fern | per-block-TYPE LR mult anneal |
| SCHEDULE-CONTINUOUS (ε) | #1020 askeladd | AdamW ε UP-ramp cooldown |
| SUBTRACTIVE-PRUNING | #1028 edward | merged stack flag removal |

Eight mechanism axes simultaneously in flight, all mutually mechanism-distinct.

## Cycle 221 snapshot (12:55 UTC May 24) — #988 closed productive-NULL/borderline; tanjiro reassigned #1047 — LookAhead body Muon (fresh META-OPTIMIZER axis)

### Activity this cycle

- **#988 tanjiro** CLOSED productive-NULL/borderline: AdamW state reset at cooldown boundary (4-arm scope sweep). Drift gate Arm A PASS (+0.00142). Arms A=3.26898, B=3.26905 (+0.00007), C=3.27005 (+0.00107), D=**3.26730 (−0.00168)**. D crosses productive-NULL band edge but misses pre-staged signal threshold (≤−0.002) by 0.00032 (16% short). All deltas within 1σ of zero (σ≈0.005 from #998 insight) — monotone D>B>A>C pattern mechanism-plausible but not statistically distinguishable from noise at N=1. Expected paired-pod magnitude collapse implies n=3 confirmation would not clear merge gate.
- **Strengthening cross-PR meta-prior:** #988 + #998 + #163 (DMR periodic) + #711 (Muon EMA structural mods) = FOUR independent state-reset-class closures across both AdamW and Muon optimizer sides. **STATE-RESET CLASS FENCED on this stack.** Future state-touching ideas should be **continuous** (decay schedules, adaptive parameters, partial-rescaling) rather than event-style discrete resets.
- **PR #1047 tanjiro** (assigned this cycle): **LookAhead optimizer wrapper on body Muon** (Zhang et al. 2019). Fresh META-OPTIMIZER axis: inner-loop Muon fast weights + outer-loop slow weights `slow ← (1−α)·slow + α·fast; fast ← slow` every K steps. Mechanism-distinct from all closures and in-flight: not a hyperparameter, not a state reset, not a preconditioner change — adds a *temporal averaging mechanism* on top of NS preconditioning. 4 arms: A=ctrl K=0; B=K=5/α=0.5 (paper default); C=K=10/α=0.5 (slower outer loop); D=K=5/α=0.2 (smaller pullback). Tests whether outer-loop weight averaging benefits NS-preconditioned trajectories.

## Cycle 220 snapshot (12:25 UTC May 24) — #998 closed productive-NULL/mild-NEG; frieren reassigned #1034 (first OPTIMIZER-CLASS axis: LION on aux groups)

### Activity this cycle

- **#998 frieren** CLOSED productive-NULL/mild-NEG: Muon body momentum buffer one-shot reset (4-arm timing sweep). Drift gate Arm A PASS (3.26655, Δ_vs_baseline −0.00101). All 3 reset arms positively regress in monotone-ordered pattern A < B (+0.00226) < C (+0.00308) < D (+0.00417). NO arm in productive-NULL ±0.0015 band, NO arm crossed productive-NEG +0.0050 ceiling — soft mild-NEG axis closure. Mechanism: body Muon pre-NS momentum is load-bearing across LR transitions (no "post-reset re-orientation" benefit; if stale-LR-regime momentum were the issue, Arm B at cooldown boundary should be best, but it's not). **Body Muon momentum DISCRETE RESET interventions FULLY FENCED** combined with #163 (DMR periodic) + #711 (structural EMA mods: AggMo/Muon²/AdEMAMix).
- **Critical empirical insight from #998:** Arm D had +0.00394 drift vs Arm A *pre-reset* (reset fired at step 2847; measured at step 2500). Evidence of **single-seed σ ≈ 0.005 noise floor on this stack**. Strengthens future N=1 noise calibration.
- **Cross-mechanism meta-prior emerging (from #988 + #998):** boundary-aligned discrete state resets fail on both AdamW v-buffer (#988 mid-flight, regressive signal) and Muon momentum (#998 closed). Future state-/momentum-touching ideas should be **continuous** (decay schedules, adaptive parameters) rather than **discrete event-style**.
- **PR #1045 frieren** (assigned this cycle): **LION optimizer for aux groups** — first OPTIMIZER-CLASS axis test on this stack. Mechanism-distinct from #984 (Schedule-Free, an averaging wrapper around AdamW) and #919/#967 (β-schedules on AdamW): this fully replaces the aux optimizer with Lion (Chen et al. 2023), changing update *class* from RMS-normalized direction (AdamW: `m̂/√v̂ + ε`) to sign-bounded direction (`sign(βm + (1−β)g)`). 4 arms: A=ctrl AdamW; B=LION at LR_ratio=0.1× (paper default); C=LION at LR_ratio=0.05× (conservative); D=LION at LR_ratio=0.20× (aggressive). Per-group base LRs preserved; only the LR is rescaled by `NANOGPT_LION_LR_RATIO`. Tests whether the aux update class is interchangeable with sign-based mechanism.

### Mechanism axes coverage (cycle 220, 8 chains)

| Axis | Active PR | Notes |
|---|:---:|---|
| **OPTIMIZER-CLASS (aux replacement)** | **#1045 frieren NEW** | LION vs AdamW |
| INITIALIZATION-DISTRIBUTION (body) | #1032 thorfinn | Haar orthogonal |
| PRECONDITIONER-ADAPTIVE (NS) | #1031 nezuko | NS adaptive residual stop |
| PRECONDITIONER-STATIC (NS) | #1008 alphonse | NS static-c sweep |
| SCHEDULE-CONTINUOUS (LR-MULT) | #1003 fern | per-block-TYPE LR mult anneal |
| SCHEDULE-DISCRETE-RESET (AdamW) | #988 tanjiro | AdamW state reset at cooldown |
| SCHEDULE-CONTINUOUS (ε) | #1020 askeladd | AdamW ε UP-ramp cooldown |
| SUBTRACTIVE-PRUNING | #1028 edward | merged stack flag removal |

Eight mechanism axes simultaneously in flight, all mutually mechanism-distinct.

## Cycle 217 snapshot (11:10 UTC May 24) — #984 closed productive-NEG; thorfinn reassigned #1032 (first INITIALIZATION-axis distribution test on body Muon)

### Activity this cycle

- **#984 thorfinn** CLOSED productive-NEG: Schedule-Free AdamW on aux groups. All 3 SF-active arms regress; Arm D (lm_head_scalars, both aux SF) catastrophic (+0.01199, never crossed 3.28). Regression hierarchy D > B (lm_head, +0.00943) > C (scalars, +0.00474) consistent with cooldown-mismatch surface size. **SF averaging-replacement-of-cooldown not transferable to aux scopes on this stack** — late-cooldown phase mismatch between SF-scoped groups and the rest (body Muon + embed still cooling) compounds in final 10% of training. Schedule-Free family on aux scopes closed.
- **PR #1032 thorfinn** assigned: **WAVE5-3 Haar-measure orthogonal init for body Muon matrices** (`blocks[i].attn.{q,k,v,proj}.weight` + `blocks[i].mlp.{fc,proj}.weight`). First INITIALIZATION-axis distribution test on body Muon params on this stack. 4 arms: A=ctrl (Kaiming default), B=gain 1.0 (Saxe convention), C=gain 0.5, D=gain 2.0. Mechanism-distinct from #452/#163 (scale variants, not distribution). NS-Stiefel-manifold theoretical motivation: NS spends early steps compressing Marchenko-Pastur tail toward orthogonality; starting on the manifold should remove that overhead. Diagnostic W&B telemetry logs init singular value mean/std at step 0 (sanity check: should be ≈gain / ≈0 for ortho-active arms).
- **Cross-cycle insight from #984:** Cooldown phase is more load-bearing than appreciated. Third recent PR (#787, #847, #984) where late-cooldown behavior dominates terminal val/loss. Useful prior: any future "no-cooldown / alternative-cooldown" hypothesis must model body+aux cooldown alignment cost explicitly.

### Live chain state (11:10 UTC May 24) — 8 chains active

| PR | Student | Hypothesis | Status | Note |
|:---:|:---:|---|:---:|---|
| #984 | thorfinn | SF-AdamW aux | **CLOSED productive-NEG** | all 3 SF arms regress, D catastrophic |
| #988 | tanjiro | AdamW state reset at cooldown | mid-flight | Arm B terminal 3.26905 (+0.00007), more arms pending |
| #998 | frieren | Muon body momentum buffer one-shot RESET | mid-flight | Arm B terminal 3.26881 (+0.00226), Arm C `nioj7kvn` running |
| #1003 | fern | Per-block-TYPE Muon LR mult cooldown anneal | mid-flight | post race-condition cleanup; arms re-spawning |
| #1008 | alphonse | NS static-c op-point sweep | mid-flight | Arm B terminal 3.26886 (−0.00001 tied), Arm C `7t99gpnm` running |
| #1020 | askeladd | AdamW ε UP-ramp cooldown | running | GPU 100%, Arm A still in progress (stale_wip flag is false-positive) |
| #1028 | edward | Merged-stack pruning ablation (SUBTRACTIVE) | running | Arm-by-arm chain in progress |
| #1031 | nezuko | NS adaptive residual stopping | running | just assigned cycle 216 |
| **#1032** | **thorfinn** | **Haar-measure orthogonal init for body Muon** | **just assigned** | first INITIALIZATION-axis distribution test |

### Mechanism axes backlog post-cycle 217

- **CLOSED (recent):** β-schedule on AdamW aux (full family); Muon body μ cooldown DOWN-anneal (#980); per-block-TYPE Muon μ bidirectional (#982 + #674); AdamW ε DOWN-ramp (#652); per-depth static NS_ITERS (#710); per-block-TYPE static NS_ITERS_COOLDOWN (#724); per-layer sigmoid-adaptive NS (#145); Schedule-Free AdamW on aux scopes (#984); init-scale variants (#452, #163).
- **IN FLIGHT (8):** NS static-c sweep (#1008); NS adaptive residual stopping (#1031); pruning ablation (#1028); AdamW ε UP-ramp (#1020); per-block Muon LR mult anneal (#1003); Muon momentum buffer one-shot reset (#998); AdamW state reset (#988); body Muon orthogonal init (#1032, NEW).
- **Likely terminals next 3-6 hours:** #988 multi-arm chain, #998 Arm C terminal, possibly #1003 if recovery clean, #1008 Arm C terminal.

### Open mechanism axes to consider for next cycles

- **Preconditioner shape**: Shampoo/KFAC partial application (head or first-layer only); AdamW v_min multiplicative second-moment floor (distinct from #1020 additive ε); per-tensor adaptive Frobenius LR (LARS-style on body Muon).
- **Initialization (additional, post-#1032)**: layer-wise LSUV calibration (Mishkin-Matas 2015); near-zero residual init for deep blocks; identity-plus-noise init for attn projections.
- **Schedule shape**: WSD with non-linear stable→decay curvature; cyclic re-warmup mid-training; AdamW LR-mult-by-curvature.
- **Loss-side** (broader exploration if optimizer space saturates): WAVE5-1 Zipf-frequency-weighted CE; WAVE5-6 path-norm regularization.

## Cycle 216 snapshot (10:40 UTC May 24) — #982 closed productive-NULL/NEG; nezuko reassigned #1031 (first PRECONDITIONER-axis adaptive-iteration test)

### Activity this cycle

- **#982 nezuko** CLOSED productive-NULL/NEG bidirectional: Per-block-TYPE Muon μ — μ_attn vs μ_mlp 4-arm sweep. Arm A=3.26802 (drift +0.00046 PASS); B (μ_attn=0.90)=3.27016 (Δ+0.00214); C (μ_mlp=0.90 — the novel test)=**3.27234 (Δ+0.00432)**; D (both 0.90)=3.27270 (Δ+0.00468). Combined with #674 (μ_mlp=0.99 regressed +0.00863), **per-block-TYPE static Muon μ axis CLOSED BIDIRECTIONAL** on post-#847 stack: shared μ=0.95 at/near optimum both attn and mlp; faster-mlp (0.90) and slower-mlp (0.99) both regress, ruling out window-size sensitivity in either direction. Cross-stack Arm-B sign-flip vs #674 inside ±0.003 noise — validates n≥3 requirement for future μ work.
- **PR #1031 nezuko** assigned: **NS adaptive residual stopping** — per-matrix early-stop on `‖XX^T − I‖_F / √m < τ`. First PRECONDITIONER-axis adaptive-iteration count test on this stack. Mechanism-distinct from #710 (per-depth static), #724 (per-type static), #145 (sigmoid-collapse via denom-scaling bug — different mechanism class). 4 arms: A=ctrl (NS_ADAPTIVE=0); B=adaptive τ=0.05 / MAX={16,20}; C=adaptive τ=0.05 / MAX={12,16} **iso-budget** (pure allocation rebalancing); D=adaptive τ=0.02 / MAX={16,20} (tighter threshold). Arm C is load-bearing mechanism arm. Includes diagnostic W&B telemetry (`mean_actual / std_actual` per step) — interprets τ activation regardless of outcome.
- **Muon momentum mechanism axes summary post-#982:** static per-block-TYPE μ split CLOSED bidirectional (#982 + #674); temporal μ cooldown anneal DOWN CLOSED productive-NEG (#980). Muon momentum coefficient no longer productive at static-split or DOWN-anneal mechanism granularity → future Muon work must target NS polynomial coefficients (#1008 in flight), NS iteration counts (#1031 now in flight), NS shape schedules, momentum-buffer one-shot ops (#998 in flight), or fundamentally new preconditioner shapes — NOT momentum coefficient values.

### Live chain state (10:40 UTC May 24) — 8 chains active

| PR | Student | Hypothesis | Status | Note |
|:---:|:---:|---|:---:|---|
| #982 | nezuko | Per-block-TYPE Muon μ | **CLOSED productive-NULL/NEG** | bidirectional with #674 |
| #984 | thorfinn | SF-AdamW aux | mid-flight | Arm C terminal 3.27396 (+0.00474), Arm D pending |
| #988 | tanjiro | AdamW state reset at cooldown | mid-flight | Arm B terminal 3.26905 (+0.00007), more arms pending |
| #998 | frieren | Muon body momentum buffer one-shot RESET | mid-flight | Arm B terminal 3.26881 (+0.00226), Arm C `nioj7kvn` early |
| #1003 | fern | Per-block-TYPE Muon LR mult cooldown anneal | mid-flight | post race-condition cleanup; arms re-spawning |
| #1008 | alphonse | NS static-c op-point sweep | mid-flight | Arm B terminal 3.26886 (−0.00001 tied), Arm C `7t99gpnm` running |
| #1020 | askeladd | AdamW ε UP-ramp cooldown | running | Arm A in progress, GPU 100% |
| #1028 | edward | Merged-stack pruning ablation (SUBTRACTIVE) | running | picked up 10:15Z |
| **#1031** | **nezuko** | **NS adaptive residual stopping** | **just assigned** | first PRECONDITIONER adaptive-iter test |

### Mechanism axes backlog post-cycle 216

- **CLOSED (recent):** β-schedule on AdamW aux (full family via #967, #514, #599, #919, #236); Muon body μ cooldown DOWN-anneal (#980); per-block-TYPE Muon μ bidirectional (#982 + #674); AdamW ε DOWN-ramp (#652); per-depth static NS_ITERS (#710); per-block-TYPE static NS_ITERS_COOLDOWN (#724); per-layer sigmoid-adaptive NS (#145, bug-mode).
- **IN FLIGHT (8):** NS static-c sweep (#1008); NS adaptive residual stopping (#1031, NEW); pruning ablation (#1028); AdamW ε UP-ramp (#1020); per-block Muon LR mult anneal (#1003); Muon momentum buffer one-shot reset (#998); AdamW state reset (#988); SF-AdamW aux (#984).
- **Likely terminals next 3-6 hours:** #984 (Arm D pending), #988 (multi-arm chain still progressing), #998 (Arm C early), several others.
- **Mu UP-anneal during cooldown (inverse of #980):** deprioritized (scalar HP search per directive); axis closed in the load-bearing direction.

### Open mechanism axes to consider for future assignments

- **Preconditioner shape**: Shampoo/KFAC partial application (head or first layer only — compute budget permitting); Compass/Lion-style sign-aware updates; AdamW v_min multiplicative second-moment floor (distinct from #1020 additive ε floor).
- **Initialization** (under-explored per directive): WAVE5-3 Haar-measure orthogonal init for body Muon matrices; LSUV-style layer-wise scaling; near-zero residual init for deep blocks.
- **Schedule shape**: WSD with non-linear stable→decay curvature; cyclic re-warmup mid-training; AdamW LR-mult-by-curvature.
- **Loss-side** (not yet attempted broadly): WAVE5-1 Zipf-frequency-weighted CE; WAVE5-6 path-norm regularization (loss-form, mechanism distinct from focal/PWCE which closed).



### Activity this cycle

- **#980 edward** CLOSED productive-NEG monotone-regressive: Muon body μ DOWN-cooldown anneal. Δ_vs_A: +0.00173 → +0.00869 → +0.01214 across mu→{0.85, 0.70, 0.50}. Arm D never crossed 3.28. NS-on-body relies on momentum-smoothed direction; reducing μ in late cooldown injects raw-gradient noise that NS propagates. **Body-Muon momentum cooldown DOWN-anneal axis closed on post-#847 stack.**
- **PR #1028 edward** assigned: **Merged-stack pruning ablation** — the **first SUBTRACTIVE experiment** in the run. All in-flight PRs test additive changes; this tests whether 3 merged levers (NS_STOCHASTIC_COOLDOWN=2 from #787, EMBED_INIT_ANCHOR_LAMBDA=0.001 from #847, EMBED_COOLDOWN_SHAPE=linear_floor from #235) remain load-bearing in current composition. Zero code changes; pure env-var ablation. Directive-mandated category ("pruning ablations of complex stacks").
- **Mirror-image asymmetry validated:** Aux-side momentum cooldown anneals work (#919 productive-NULL via PP collapse, #514 closed); body-side Muon momentum cooldown anneals don't (#980 monotone-regressive). NS orthogonalization is the asymmetry source — body has it (absorbs noise); aux doesn't.

## Cycle 211 snapshot (08:07 UTC May 24) — #967 closed NULL; askeladd reassigned #1020

### Activity that cycle

- **#967 askeladd** CLOSED productive-NULL: AdamW aux β₂ cooldown anneal. All 4 arms |Δ_vs_A| ≤ 0.00017. Symmetric tie B(+0.00008) vs C(+0.00014) testing opposite directions is the canonical non-load-bearing signal. **β-schedule axis on AdamW aux now fully exhausted.** Mechanism insight: v_t already converged by cooldown start; ε floor more likely the active lever → motivates PR #1020.
- **PR #1020 askeladd** assigned: **AdamW ε UP-ramp cooldown** — linear ramp eps from 1e-10 → {1e-8, 1e-6, 1e-4} over cooldown window. Fresh axis: #652 (DOWN direction, closed NULL) tested opposite; ε UP-ramp at cooldown is genuinely untested.
- **Mechanism insight from #967:** β₂ NULL suggests aux v_t is converged by step 2345 (cooldown start) — the denominator floor ε is the active lever, not EMA rate. This insight directly motivated #1020 hypothesis design.

### Cycle 209 (carryover — chains all mid-flight)

- **#1008 alphonse** stale_wip ack + probe. Arm A `lp81hhew` finished at val=3.2689 (n=1, +0.00134 drift PASS); Arm B `u4jdeu7l` running at step 200. Chain healthy.
- **W&B chain survey** confirmed all 7 other students have active arms. No idle GPU, no stalls.

### Live chain state (08:07 UTC May 24) — Arm-A controls + last-known-running arms

Most Arm A controls reproduce baseline well (n=1 noise envelope ~±0.002-0.003). **Notable Arm-A reproductions:** frieren=3.2665, edward=3.2678, nezuko=3.2680, askeladd=3.2685, alphonse=3.2689, tanjiro=3.2690, thorfinn=3.2692. fern Arm-A still mid-chain at step 3225 val=3.2783 (terminal pending).

| PR | Student | Hypothesis | Arm A (ctrl) val | Latest arm | Run | Step (last) | Val |
|:---:|:---:|---|:---:|:---:|---|:---:|:---:|
| #967 | askeladd | AdamW aux β₂ cooldown anneal | 3.2685 | **CLOSED NULL** | — | all 4 arms done | — |
| #980 | edward | Muon μ cooldown anneal | 3.2678 | C (mu0.70) | `iemv695q` | ~2300 | 3.375 |
| #982 | nezuko | Per-block-type Muon μ FASTER mlp | 3.2680 | C (attn0.95/mlp0.90) | `qurezx9d` | ~1975 | 3.455 |
| #984 | thorfinn | SF-AdamW aux | 3.2692 | C (scope-scalars) | `pctoxsoc` | ~400+ | early |
| #988 | tanjiro | AdamW state reset at cooldown | 3.2690 | B (lm_head_scalars) | `xlzd0p2g` | ~1375+ | 3.541 |
| #998 | frieren | Muon body momentum one-shot reset | **3.2665** | B (mom-reset) | `23xkxrwz` | ~1250+ | 3.565 |
| #1003 | fern | Per-block-TYPE Muon LR mult cooldown anneal | 3.2783 mid | A (ctrl) | `qcwdptmu` | ~3350 | terminal |
| #1008 | alphonse | NS static-c op-point sweep | 3.2689 | B (static_c=0.65) | `u4jdeu7l` | ~200+ | early |
| **#1020** | **askeladd** | **AdamW ε UP-ramp cooldown** | — | running | — | — | — |
| #980 | edward | Muon μ cooldown anneal DOWN | 3.2678 | **CLOSED productive-NEG** | — | terminal | monotone-regressive all 4 arms |
| **#1028** | **edward** | **Merged-stack pruning ablation (NEW, SUBTRACTIVE)** | — | pending pickup | — | — | — |

### Notable observations

- **frieren #998 Arm A = 3.2665** is the only Arm-A control below the merged baseline 3.26756 (n=1, -0.00106). Could be noise, but worth watching whether Arm B (mom-reset treatment) sustains or improves on this.
- **edward #980 Arm-B (mu0.85) terminal = 3.2695**. Arm-B (treatment) drift +0.00194 vs Arm-A (ctrl) 3.2678. Direction-wrong N=1 for mu0.85 (will need full chain context).
- **Crash recoveries on tanjiro #988 (Arm A: 3 crashes before clean 3.2690), thorfinn #984 (Arm A: 1 crash + retry → 3.2692), fern #1003 (smoke test + Arm A retry).** All chains stabilized post-recovery.

### Cycle 208 carryover (probe-only since 204)

### Activity since cycle 204

Cycles 205-208 are **probe-only** — no PRs closed, no PRs merged, no new assignments. All actions have been stale_wip false-positive acks + process probes on student PRs whose latest activity is the advisor's own comment (own-comment recency trips the heuristic).

| Cycle | Probe target | Reason |
|:---:|---|---|
| 205 | #982 nezuko | per-block-type Muon μ FASTER mlp pickup confirmation |
| 206 | #988 tanjiro | watchdog said \"no train.py 22 min\" but W&B confirmed `1kach4zq` advancing — orphaned-but-progressing torchrun |
| 207 | #980 edward + #967 askeladd | W&B agent visibility lag on newly-launched arms (lesson: don't flag chain death from W&B lag when pod is healthy) |
| 208 | #998 frieren | Arm A `m93rch9c` ~98% done at val=3.2686 (strong) but Arms B/C/D not launched after 24+ hrs; requested chain plan confirmation |

### Live chain state (06:40 UTC May 24)

| PR | Student | Hypothesis | Latest run | step | val/loss | ETA / note |
|:---:|:---:|---|---|:---:|:---:|---|
| #967 | askeladd | AdamW aux β₂ anneal | Arm D `rmepa75y` | 1125+ | running | terminal ~07:38 UTC, chain end ~10:30 UTC |
| #980 | edward | Muon μ cooldown anneal | Arm C `iemv695q` | 991+ | running | C ~07:44 UTC, D ~09:35 UTC |
| #982 | nezuko | Per-block-type Muon μ FASTER mlp | pickup confirmed | — | — | chain ETA TBD |
| #984 | thorfinn | SF-AdamW for aux | Arm B `uyh8tiou` | running | — | chain ~10:00 UTC |
| #988 | tanjiro | AdamW state reset at cooldown | Arm A `1kach4zq` | 1784+ | running | chain ETA ~13:00 UTC |
| #998 | frieren | Muon body momentum reset timing | Arm A `m93rch9c` | 3300 | **3.2686** | Arm A ~98% done; Arms B/C/D **not launched** (probe pending) |
| #1003 | fern | Per-block-TYPE Muon LR mult cooldown anneal | pickup TBD | — | — | chain ETA TBD |
| #1008 | alphonse | NS static-c op-point sweep | pickup TBD | — | — | chain ETA TBD |

### Operational learnings (apply next cycles)

1. **W&B visibility lag** can show "no Arm X" for newly-launched arms even when the chain is progressing — never flag chain death from W&B alone when pod is healthy at high GPU util.
2. **Orphaned-but-progressing torchrun:** Watchdog `no train.py for N min` can be a false positive if the parent torchrun was orphaned but child python procs are still iterating (#988 case). Cross-check W&B step advancement before flagging.
3. **stale_wip own-comment recency:** Each probe I post triggers the heuristic on the next cycle because my comment becomes the most recent activity. Pattern is benign; treat as routine ack + probe unless multiple cycles pass with zero student response.

### Next-cycle expectations (cycle 209)

- **Likely terminals to review:** #967 askeladd Arm D + chain end (~07:38-10:30 UTC), #980 edward Arm C (~07:44 UTC).
- **Pending probes to follow up:** #998 frieren response on Arm B/C/D launch plan.
- **No idle students expected** unless a chain closes in next cycle.

---

## Current merged baseline — post-#847

**val=3.26756 / fs=3183.33 (n=3 paired-pod mean)**

Merged recipe:
```
NANOGPT_GRAD_CLIP=10.0
NANOGPT_GRAD_CLIP_BODY=10.0
NANOGPT_GRAD_CLIP_AUX=5.0
NANOGPT_NS_ITERS=12
NANOGPT_NS_ITERS_COOLDOWN=16
NANOGPT_NS_COOLDOWN_START_FRAC=0.7
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
NANOGPT_ADAMW_BETA2=0.99
NANOGPT_NS_COOLDOWN_SHAPE=late_peak
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
NANOGPT_ADAMW_EMBED_LR_MULT=1.5
NANOGPT_MUON_ATTN_LR_MULT=0.80
NANOGPT_MUON_MLP_LR_MULT=1.20
NANOGPT_NS_STOCHASTIC_COOLDOWN=2
NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001   ← NEW post-#847: post-AdamW hook, embed init-snapshot anchor
```

### Merged stack history

| PR | Change | val (n) | Cumulative baseline |
|----|--------|---------|---------------------|
| #60 | Muon² | 3.2766 (2) | 3.2766 |
| #105 | clip=5.0 | 3.27527 (3) | 3.27527 |
| #165 | clip=10.0 | 3.27474 (3) | 3.27474 |
| #176 | NS=12→16@70% | 3.27461 (3) | 3.27461 |
| #235 | embed linear_floor=15% | 3.27434 (3) | 3.27434 |
| #236 | AdamW β₂=0.99 | 3.27407 (3) | 3.27407 |
| #285 | NS cooldown SHAPE=late_peak | 3.27352 (2) | 3.27352 |
| #290 | NS coef schedule=linear_ramp_down | 3.27200 (3) | 3.27200 |
| #393 | AdamW embed LR mult=1.5× | 3.27174 (3) | 3.27174 |
| #579 | Body-Muon attn=0.80× mlp=1.20× LR asymmetry | 3.27070 (3) | 3.27070 |
| #708 | Per-group grad-clip BODY=10/AUX=5 | 3.27036 (3) | 3.27036 |
| #787 | Stochastic NS cooldown spread=2 | 3.26944 (3) | 3.26944 |
| **#847** | **Embed init-anchor WD λ=0.001** | **3.26756 (3)** | **3.26756** ← CURRENT |

---

## Cycle 204 snapshot (05:05 UTC May 24)

### Closed this cycle (1)

- **#956 alphonse** CLOSED productive-NEG: lm_head per-row max-norm soft-clamp 4-arm cap sweep terminal. **Monotone-regressive axis across full cap range, no window of improvement, right-tail rows load-bearing.** Arm A `kjrd1usm` 3.26765 (drift PASS +0.00009); Arm B `2c9pm03k` cap=1.0 catastrophic +0.387 killed @ step 1150 (cap fired on 90.4% rows); Arm C `pfusx38h` cap=4.0 direction-wrong +0.00071 (20.4% rows clipped, cap LOAD-BEARING but wrong direction); Arm D `1xyvay46` cap=16.0 inactive (cap above natural max 12.70). Mechanism: natural row-norm distribution (mean=3.70 std=0.73 max=12.70) is healthy NOT pathological; right-tail rows carry signal. **lm_head weight-space row-magnitude constraint family CLOSED.** Joins #618/#663/#668/#322/#652/#408/#477.

### New assignments this cycle (1)

- **PR #1008 alphonse** — **NS static-c operating-point sweep (4-arm: off/c0.65/c0.70/c0.40)**. Tests whether a fixed static c value (the one-parameter NS polynomial family: a=1.5+c, b=-0.5-2c) at a different operating point outperforms the merged `linear_ramp_down` schedule. Fresh axis: #290 only tested constant (c=0.5) vs ramp schedule shapes; static c=0.65/0.70/0.40 as sustained constants across all 3350 steps are genuinely untested. Theoretical grounding: Shulgin et al. (CPAL 2026) shows NS precision coupled with LR/momentum on nanoGPT scale; Kim & Oh (ICLR 2026) shows convergence improves doubly-exponentially with polynomial precision. Mechanism-distinct from all closed NS-schedule axes (#290 ramp-down merged, #787 stochastic-spread merged). Cheap implementation: 3 elif branches in `get_ns_coef_at_iter`.

### Active chains (as of 05:05 UTC May 24, cycle 204)

| PR | Student | Hypothesis | Run | state | step | val/loss | ETA |
|:---:|:---:|---|---|:---:|:---:|:---:|:---:|
| **#1008** | **alphonse** | **NS static-c op-point sweep** | pending pickup | — | — | — | — |
| #967 | askeladd | AdamW aux β₂ anneal | `pd25zsdp` | **finished** Arm B | 3350 | **3.2686** | C+D sequential thereafter |
| #980 | edward | Muon μ cooldown anneal Arm B | `344uvcwt` | running | ~335 | 4.08 early | B ~07:00, C+D thereafter |
| #982 | nezuko | Per-block-type Muon μ FASTER mlp | pending pickup | — | — | — | — |
| #984 | thorfinn | SF-AdamW for aux Arm A retry | `hz7n0ex8` | running | ~3150 | ~3.28 | terminal ~05:25 UTC |
| #988 | tanjiro | AdamW state reset at cooldown boundary | pending pickup | — | — | — | — |
| #998 | frieren | Muon body momentum reset timing | pending pickup | — | — | — | — |
| #1003 | fern | Per-block-TYPE Muon LR mult cooldown anneal | pending pickup | — | — | — | — |

### Mechanism axes CLOSED through cycle 204

Adds **#956 (lm_head per-row max-norm soft-clamp, productive-NEG monotone-regressive)** to closed list. lm_head weight-space row-magnitude constraint family fully exhausted. Cumulative closed in this run still relevant: same as cycle 203 plus #956.

### Mechanism axes EXPLICITLY UNTESTED (durable backlog after cycle 204)

- D-Adaptation (Muon-side theoretical baggage)
- Prodigy adaptive LR
- NS coefficient static-c value sweep → **#1008 IN FLIGHT** (alphonse)
- Per-tensor adaptive NS iteration count based on spectral residual ← candidate
- Alternative NS polynomial families (Chebyshev-derived, higher-order) ← fresh structural axis
- LR-coupled momentum decay (μ ∝ lr(t))
- AdamW eps cooldown anneal UP → **#1020 IN FLIGHT** (askeladd) — linear ramp 1e-10 → {1e-8/1e-6/1e-4}
- Lion/Tiger for embed-only group (Lion-on-embed never specifically isolated)
- Pruning ablations of merged stack → **#1028 IN FLIGHT** (edward) — first SUBTRACTIVE experiment, 4-arm minus-stochNS / minus-anchor / minus-floor
- Mu UP-anneal during cooldown (inverse of closed #980) — deprioritized (scalar HP search per directive)

### Closed prior cycles (still relevant context)

- **#929 edward** CLOSED productive-NULL. Reassigned → #980.
- **#845 askeladd** CLOSED productive-NULL. Reassigned → #967.
- **#933 nezuko** CLOSED productive-NULL. Reassigned → #982.
- **#880 thorfinn** CLOSED productive-NULL with canonical magnitude-collapse. Reassigned → #984.
- **#944 tanjiro** CLOSED productive-NEG. Reassigned → #988.
- **#963 frieren** CLOSED productive-NEG (monotone-worsening). Reassigned → #998.
- **#919 fern** CLOSED productive-NULL (canonical N=1→PP magnitude collapse). Reassigned → #1003.
- **#956 alphonse** [this cycle] CLOSED productive-NEG (monotone-regressive). Reassigned → **PR #1008** NS static-c op-point sweep.

---

## Cycle 203 snapshot (04:50 UTC May 24)

### Closed this cycle (1)

- **#919 fern** CLOSED productive-NULL via canonical N=1→PP magnitude collapse: AdamW aux-group β₁ cooldown anneal Arm D paired-pod n=3 terminal. mean(n=3)=3.26947, +0.00191 vs baseline. All 3 pods direction-WRONG (3.26880, 3.27077, 3.26883). N=1 D-arm Δ_D_vs_A=−0.00168 → PP n=3 Δ_vs_baseline=+0.00191 (full collapse + sign-flip). Joins the canonical N=1→PP collapse precedent line (#880, #845). **AdamW aux β₁ cooldown anneal axis CLOSED.**

### Ack-only this cycle (1)

- **#984 thorfinn stale_wip ACK**: Arm A first attempt `2x1nrg9w` crashed at step 600 (mode TBD). Retry `hz7n0ex8` launched 33min later, running step 2450/3350 val=3.383 (healthy descent). ETA Arm A terminal ~05:25 UTC. Requested student post crash mode + Arm A terminal + sequential B/C/D launch confirmations.

### New assignments this cycle (1)

- **PR #1003 fern** — **Per-block-TYPE Muon LR mult cooldown anneal (4-arm sweep)**. Genuinely fresh axis (grep-verified untested) — tests whether the merged #579 per-TYPE asymmetry (attn=0.80×, mlp=1.20×) should collapse toward 1.0 during cooldown. Mechanism conjecture: per-TYPE asymmetry helpful mid-training (block-differential dynamics) but sub-optimal in late convergence (uniform LR may be better). 4 arms: A=off, B=both anneal, C=mlp_only, D=attn_only. Mechanism-distinct from #674 (per-TYPE μ closed NULL), #724 (per-TYPE NS_ITERS_COOLDOWN closed NEG), #980 (global Muon μ cooldown anneal in flight), #919 (just-closed aux β₁ cooldown anneal).

### Active chains (as of 04:50 UTC May 24, cycle 203)

| PR | Student | Hypothesis | Run | state | step | val/loss | ETA |
|:---:|:---:|---|---|:---:|:---:|:---:|:---:|
| #956 | alphonse | lm_head max-norm Arm D | `1xyvay46` | running | ~870 | 3.79 | D ~04:42 UTC (overdue, check) |
| #967 | askeladd | AdamW aux β₂ anneal Arm B (re-parented) | `pd25zsdp` | running | ~2400 | 3.38 | B ~05:00 UTC, C+D thereafter |
| #980 | edward | Muon μ cooldown anneal Arm B | `344uvcwt` | running | early | initializing | B ~05:55, C ~07:45, D ~09:35 UTC |
| #982 | nezuko | Per-block-type Muon μ | pending | — | — | — | pickup imminent |
| **#984** | **thorfinn** | **SF-AdamW for aux Arm A retry** | `hz7n0ex8` | running | ~2450 | 3.38 | A ~05:25 UTC, chain ~10:00 UTC |
| **#988** | **tanjiro** | **AdamW state reset at cooldown** | pending | — | — | — | pickup imminent |
| **#998** | **frieren** | **Muon body momentum reset timing** | pending | — | — | — | pickup imminent |
| **#1003** | **fern** | **Per-block-TYPE Muon LR mult cooldown anneal (NEW)** | pending | — | — | — | pickup imminent |

### Imminent terminals (next ~3h)

- **#967 Arm B** `pd25zsdp` step ~2400 → ETA terminal ~05:00 UTC. β₂ cooldown anneal direction-gate.
- **#984 Arm A retry** `hz7n0ex8` step ~2450 → ETA terminal ~05:25 UTC. SF-AdamW Arm A drift gate.
- **#956 Arm D** `1xyvay46` step ~870 → may finish or be overdue; check W&B.
- **#980 Arm B** terminal ~05:55 UTC.

### Mechanism axes CLOSED through cycle 203

Adds **#919 (AdamW aux β₁ cooldown anneal, productive-NULL via PP magnitude collapse)** to closed list. Cumulative closed in this run still relevant: body-Muon GC (#944 NEG), path-norm body velocity (#933), Muon² body v_t β₂ (#880), post-NS v_post (#963 NEG monotone-worsening), AdamW v_t multiplicative floor (#929), embed-grad freq-rescale (#845), per-block-DEPTH Muon LR (#753), NS_ITERS per-DEPTH/TYPE/COOLDOWN (#710/#724), per-block-TYPE Muon WD/β₂/μ (#669/#632/#674), Schedule-Free MUON (#62), Lion/Adafactor/Yogi for aux (#77/#180/#516), AggMo/AdaBelief (#711), AdamW eps cooldown DOWN (#652), AdamW β₁ warmup (#514) + cooldown anneal (#919), per-group β₁ (#599), Cautious AdamW/sign-mask, init scaling (#374), lm_head init-anchor (#938), NS-on-lm_head-grad (#618), Polyak weight-EMA (#104, #436), Lookahead (#120, #434), AdEMAMix (#399), DMR periodic (#163), LARS trust-ratio (#755), ratio-EMA magnitude (#688), cos-EMA direction (#628), body Muon LR cooldown shape (#520, #335), per-group cooldown_frac decoupling (#568).

### Mechanism axes EXPLICITLY UNTESTED (durable backlog after cycle 203)

- D-Adaptation (Muon-side theoretical baggage)
- Prodigy adaptive LR
- AdamW state reset at cooldown boundary → **#988 (in flight)**
- SF-AdamW for aux → **#984 (in flight)**
- Per-block-TYPE Muon μ with FASTER mlp → **#982 (in flight)** (#674 tested slower-mlp NULL)
- Muon body momentum one-shot reset timing → **#998 (in flight)** (#163 periodic-DMR closed)
- Per-block-TYPE Muon LR mult cooldown anneal → **#1003 (in flight)** (just assigned)
- NS coefficient static value sweep (only schedule ramp-down tested in #290)
- Adaptive NS iteration count based on per-matrix spectral residual
- LR-coupled momentum decay (μ ∝ lr(t))
- AdamW eps cooldown anneal UP (opposite of closed #652 DOWN)

### Closed prior cycles (still relevant context)

- **#929 edward** CLOSED productive-NULL. Reassigned → #980.
- **#845 askeladd** CLOSED productive-NULL. Reassigned → #967.
- **#933 nezuko** CLOSED productive-NULL. Reassigned → #982.
- **#880 thorfinn** CLOSED productive-NULL with canonical magnitude-collapse. Reassigned → #984.
- **#944 tanjiro** CLOSED productive-NEG. Reassigned → #988.
- **#963 frieren** CLOSED productive-NEG (monotone-worsening). Reassigned → #998.
- **#919 fern** [this cycle] CLOSED productive-NULL (canonical N=1→PP magnitude collapse). Reassigned → #1003.

---

## Cycle 202 snapshot (04:30 UTC May 24)

### Closed this cycle (1)

- **#963 frieren** CLOSED productive-NEG: post-NS element-wise variance normalization (v_post) 4-arm β₂_post sweep terminal. **Monotone-worsening across full sweep range** — every higher β₂_post is strictly worse at every matched step. Arm A `5vzq0lob` 3.26958 drift PASS upper edge. Arms B+C early-killed for regression (catastrophic), Arm D aborted on advisor recommendation. Mechanism: post-NS v_post EMA competes destructively with NS's unit-spectrum normalization. Axis closure: post-NS adaptive per-coordinate scaling family ruled out on r4 post-#847 stack.

### Student response cycle (1) — #967 askeladd gate-bug catch

Cycle 201: Askeladd identified an early-kill gate spec error in PR #967 (val ≥ 3.300 at step 2500 fires on healthy Arm A which lands 3.366 at that step). Took correct rescue action (re-parented torchrun, disabled bad gate, launching C/D manually). Advisor blessed recovery + adopted student-proposed **relative gate** `Δ_vs_A_at_step_2500 ≥ +0.10` as canonical for future PRs.

### New assignments this cycle (1)

- **PR #998 frieren** — **Muon body momentum buffer one-shot reset 4-arm timing sweep**. Mirror image of #988 (AdamW state reset, scope axis); this PR tests Muon-side reset with TIMING axis. Arms: A(off ctrl)/B(reset@0.7=cooldown start)/C(reset@0.5=mid-train)/D(reset@0.85=deep cooldown). Bold mechanism-distinct swing — tests whether body Muon momentum continuity is load-bearing across boundary transitions. Mechanism-distinct from #163 (periodic DMR closed) and from #711 (structural EMA modifications "fully fenced"). Trivial implementation (~15 LOC).

### Active chains (as of 04:30 UTC May 24, cycle 202)

| PR | Student | Hypothesis | Run | state | step | val/loss | ETA |
|:---:|:---:|---|---|:---:|:---:|:---:|:---:|
| #919 | fern | β₁ cooldown PP seed 3 | `89l7tmds` | running | ~3000 | 3.32 | terminal ~04:31 UTC |
| #956 | alphonse | lm_head max-norm Arm D | `1xyvay46` | running | ~600 | 3.85 | D ~04:42 UTC |
| #967 | askeladd | AdamW aux β₂ anneal Arm B (re-parented) | `pd25zsdp` | running | ~2196 | 3.42 | B ~03:50 UTC (overdue), C/D thereafter |
| #980 | edward | Muon μ cooldown anneal Arm B | `344uvcwt` | running | early | initializing | B ~05:55, C ~07:45, D ~09:35 UTC |
| #982 | nezuko | Per-block-type Muon μ | pending | — | — | — | pickup imminent |
| #984 | thorfinn | SF-AdamW for aux | pending | — | — | — | pickup imminent (smoke-test gate) |
| #988 | tanjiro | AdamW state reset at cooldown | pending | — | — | — | pickup imminent |
| **#998** | **frieren** | **Muon body momentum reset timing (NEW)** | pending | — | — | — | pickup imminent |

### Imminent terminals (next ~2h)

- **#919 seed 3** `89l7tmds` ~step 3000 → ETA ~04:31 UTC. Chain projects close productive-NULL (seeds 1 + 2 both direction-wrong: 3.26880, 3.27080; need seed 3 ≤ 3.26308 to clear G1 which is effectively unachievable).
- **#956 Arm D** `1xyvay46` ~step 600 → ETA ~04:42 UTC.
- **#967 Arm B** `pd25zsdp` ~step 2196 → ETA ~05:00 UTC (re-parented torchrun).

### Mechanism axes CLOSED through cycle 202

Adds **#963 (post-NS v_post, productive-NEG, monotone-worsening)** to closed list. Other closures still relevant from cycles 197-201: body-Muon GC (#944), path-norm body velocity (#933), Muon² body v_t β₂ (#880), AdamW v_t multiplicative floor (#929), embed-grad freq-rescale (#845), per-block-DEPTH Muon LR (#753), NS_ITERS (#710), per-block-TYPE Muon WD/β₂ (#669/#632), Schedule-Free MUON (#62), Lion/Adafactor/Yogi for aux (#77/#180/#516), AggMo/AdaBelief (#711), AdamW eps cooldown (#652), Cautious AdamW/sign-mask, init scaling (#374), lm_head init-anchor (#938 zero-init degeneracy), NS-on-lm_head-grad (#618), Polyak weight-EMA (#104, #436), Lookahead (#120, #434), AdEMAMix (#399), DMR periodic (#163), LARS trust-ratio per-matrix (#755), ratio-EMA magnitude (#688), cos-EMA direction (#628).

### Mechanism axes EXPLICITLY UNTESTED (durable backlog after cycle 202)

- D-Adaptation (Muon-side theoretical baggage)
- Prodigy adaptive LR
- Per-block-DEPTH Muon μ (depth-stratified momentum, vs DEPTH-LR closed but DEPTH-MU untested)
- AdamW state reset at cooldown boundary → **#988 (in flight)**
- SF-AdamW for aux → **#984 (in flight)**
- Per-block-TYPE Muon μ with FASTER mlp → **#982 (in flight)** (#674 tested slower-mlp NULL)
- Muon body momentum one-shot reset timing → **#998 (in flight)** (#163 closed periodic-reset)
- NS coefficient static value sweep (only schedule tested via #290)
- Adaptive NS iteration count based on per-matrix spectral residual
- LR-coupled momentum decay (μ ∝ lr(t))

### Closed prior cycles (still relevant context)

- **#929 edward** CLOSED productive-NULL (AdamW aux v_t floor). Reassigned → #980.
- **#845 askeladd** CLOSED productive-NULL (embed-grad freq rescale). Reassigned → #967.
- **#933 nezuko** CLOSED productive-NULL (path-norm body velocity). Reassigned → #982.
- **#880 thorfinn** CLOSED productive-NULL with canonical magnitude-collapse. Reassigned → #984.
- **#944 tanjiro** CLOSED productive-NEG (body-Muon grad centralization, all 3 mechanism arms direction-wrong). Reassigned → #988.
- **#963 frieren** [this cycle] CLOSED productive-NEG (post-NS v_post, monotone-worsening). Reassigned → #998.

---

## Cycle 199 snapshot (03:05 UTC May 24)

### Closed this cycle (1)

- **#944 tanjiro** CLOSED productive-NEG: body-Muon grad centralization 4-arm sweep terminal. Arm A `6ht4oj5l` val=3.26656 drift PASS (Δ=−0.00100, bit-clean codepath). Mechanism arms all direction-wrong:

| arm | gc_mode | val/loss | Δ_vs_A | reading |
|:---:|---|:---:|:---:|---|
| A | none (ctrl) | 3.26656 | — | drift PASS |
| B | col | 3.27594 | **+0.00938** | catastrophic-NEG |
| C | row | 3.26955 | **+0.00299** | mild-NEG |
| D | both | 3.27673 | **+0.01017** | catastrophic-NEG (sub-additive vs B+C) |

  **Mechanism reading**: gc=col asymmetrically worst (~3× row magnitude). Composition D ≈ B+C −0.00220 (sub-additive: row and col gc interfere on Muon body since both project against orthogonal subspaces of NS pre-image). All 3 mechanism arms NEG. Closure: **body-Muon grad centralization axis exhaustively negative** — both axes wrong, composition does not rescue. Pre-NS DC removal on body Muon is mechanism-direction-inverted. tanjiro reassigned → #988.

### Ack-only this cycle (2)

- **#956 alphonse** stale_wip flag ACK: false-positive. Arm C `pfusx38h` terminal 3.26841 (Δ=+0.00075 within drift gate, productive-NULL on this arm). Arm D `1xyvay46` started 02:50 UTC ETA terminal ~04:42 UTC. Chain still active.
- **#967 askeladd** stale_wip flag ACK: false-positive. Arm A terminal 3.26850 ✓; Arm B `pd25zsdp` running step ~775 ETA ~03:50 UTC.

### New assignments this cycle (1)

- **PR #988 tanjiro** — **AdamW state reset at cooldown boundary** (4-arm scope sweep). Bold mechanism-distinct swing: at step `int(0.7 * train_steps)` zero out `exp_avg` and `exp_avg_sq` for scoped aux groups, forcing v_t re-estimation under cooldown LR regime. Arms: A(off ctrl)/B(lm_head_scalars)/C(scalars)/D(lm_head). Embed EXCLUDED from every scope to preserve init-anchor coupling (#847). Untested per EXPERIMENTS_LOG.md grep; mechanism-distinct from all active cooldown-anneals (#919 β₁, #967 β₂, #980 Muon-μ) which smoothly modulate hyperparameters — this is a discrete state reset. Pre-stage signal threshold Δ_vs_A ≤ −0.0020 → PP escalation; regression threshold Δ_vs_A ≥ +0.0050 → close NEG.

### Active chains (as of 03:05 UTC May 24, cycle 199)

| PR | Student | Hypothesis | Run | state | step | val/loss | ETA |
|:---:|:---:|---|---|:---:|:---:|:---:|:---:|
| #919 | fern | β₁ cooldown PP seed 2 | `ofm1da08` | running | ~1450 | 3.51 | full chain ~05:30 UTC |
| #956 | alphonse | lm_head max-norm Arm D | `1xyvay46` | running | ~210 | early | D ~04:42 UTC |
| #963 | frieren | post-NS v_post Arm B | `355k8llh` | running | ~1500 | 3.65 | full chain ~07:30 UTC |
| #967 | askeladd | AdamW aux β₂ anneal Arm B | `pd25zsdp` | running | ~775 | 3.69 | B ~03:50 UTC, C/D thereafter |
| #980 | edward | Muon μ cooldown anneal | pending | — | — | — | pickup imminent |
| #982 | nezuko | Per-block-type Muon μ | pending | — | — | — | pickup imminent (#674 partial coverage caveat posted) |
| #984 | thorfinn | SF-AdamW for aux | pending | — | — | — | pickup imminent (smoke-test gate) |
| **#988** | **tanjiro** | **AdamW state reset at cooldown (NEW)** | pending | — | — | — | pickup ~03:30 UTC |

### Imminent terminals (next ~2h)

- **#967 Arm B** (β₂→0.95 all-aux) `pd25zsdp` → ETA ~03:50 UTC. β₂ cooldown anneal mechanism gate.
- **#956 Arm D** (cap=ramped) `1xyvay46` → ETA ~04:42 UTC. Closes lm_head max-norm 4-arm screen.
- **#919 PP seed 2** (β₁ cooldown) `ofm1da08` → ETA ~05:30 UTC. G1 budget tight.

### Mechanism axes CLOSED through cycle 199

Closed in this run (still relevant context): body-Muon GC (#944 productive-NEG all-arms), path-norm body velocity (#933 NULL), Muon² body v_t β₂ (#880 NULL magnitude-collapse), AdamW v_t multiplicative floor (#929 NULL), embed-grad freq-rescale (#845 NULL), per-block-DEPTH Muon LR (#753), NS_ITERS (#710), per-block-TYPE Muon WD/β₂ (#669/#632), Schedule-Free MUON (#62), Lion/Adafactor/Yogi for aux (#77/#180/#516), AggMo/AdaBelief (#711), Zipf weighting (multiple), AdamW eps cooldown (#652), Cautious AdamW/sign-mask, init scaling embed/lm_head (#374), lm_head init-anchor (#938 zero-init degeneracy), NS-on-lm_head-grad (#618 NEG).

### Mechanism axes EXPLICITLY UNTESTED (durable backlog)

- D-Adaptation (Muon-side theoretical baggage)
- Prodigy
- Per-block-DEPTH Muon μ (depth-stratified, vs DEPTH-LR closed but DEPTH-MU untested)
- AdamW state reset at cooldown boundary → **just assigned #988**
- SF-AdamW for aux → **just assigned #984**

### Closed prior cycles (still relevant context)

- **#929 edward** CLOSED productive-NULL (AdamW aux v_t floor). Reassigned → #980.
- **#845 askeladd** CLOSED productive-NULL (embed-grad freq rescale composition-overlap with init-anchor). Reassigned → #967.
- **#933 nezuko** CLOSED productive-NULL (path-norm body velocity). Reassigned → #982.
- **#880 thorfinn** CLOSED productive-NULL with canonical magnitude-collapse (Muon² body v_t β₂=0.9999). Reassigned → #984.
- **#944 tanjiro** [this cycle] CLOSED productive-NEG (body-Muon grad centralization, all 3 mechanism arms direction-wrong). Reassigned → #988.

---

## Cycle 198 snapshot (02:28 UTC May 24)

### Closed this cycle (2)

- **#933 nezuko** CLOSED productive-NULL: path-norm body-velocity penalty 4-arm sweep. Best arm D (λ=1e-5, w=50) Δ_vs_A=−0.00052 (26% of PP escalation threshold). Window axis is load-bearing if any (Δ_D_vs_B=−0.00122); λ axis inert. Mechanism direction-correct but sub-noise. Magnitude-collapse precedent from #880 makes PP confirmation unlikely to recover gate-clearing magnitude. nezuko reassigned → #982.
- **#880 thorfinn** CLOSED productive-NULL with canonical magnitude-collapse: Muon² body v_t β₂=0.9999 paired-pod n=3. Within-pod Δ went −0.00243 (N=1) → −0.00165 (Pod 0) → −0.00061 (Pod 1) → +0.00009 (Pod 2 sign flip), mean n=3 = −0.00072 (36% of Gate 1 threshold). Gates 1+2 FAIL. Mechanism real-in-direction but baseline-shift-sensitive; not robust. thorfinn reassigned → #984.

### New assignments this cycle (2)

- **PR #982 nezuko** — Per-block-TYPE Muon momentum (μ_attn ≠ μ_mlp) 4-arm sweep. Complements merged per-block-type LR mults (#579). Mechanism-distinct from #980 (global μ cooldown anneal). Arms: A(0.95,0.95)/B(0.90,0.95)/C(0.95,0.90)/D(0.90,0.90). Single-pod N=1 screening; PP escalation if best |Δ_vs_A| ≤ −0.0020.
- **PR #984 thorfinn** — Schedule-Free AdamW (Defazio NeurIPS 2024) for lm_head + scalars (embed EXCLUDED to preserve init-anchor coupling). Bold swing per plateau protocol — explicitly untested mechanism on EXPERIMENTS_LOG line 1487. Arms: A(off ctrl)/B(lm_head)/C(scalars)/D(lm_head_scalars). Requires inline `ScheduleFreeAdamW` class (~80 LOC), train/eval mode-switch in loop, SF groups skip the LR cooldown. Smoke-test required before full arms.

### Active chains (as of 02:28 UTC May 24, cycle 198)

| PR | Student | Hypothesis | Run | state | step | val/loss | ETA |
|:---:|:---:|---|---|:---:|:---:|:---:|:---:|
| #919 | fern | β₁ cooldown PP seed 2 | `ofm1da08` | running | ~1150 | 3.60 | full chain ~05:30 UTC |
| #944 | tanjiro | gc Arm D (both) | `g32ouqhe` | running | ~825 | 3.71 | D ~02:47 UTC (decides axis) |
| #956 | alphonse | lm_head max-norm Arm C (cap=4.0) | `pfusx38h` | running | ~850 | 3.69 | C ~02:47 UTC, D ~04:30 UTC |
| #963 | frieren | post-NS v_post Arm B | `355k8llh` | running | ~1340 | 3.71 | full chain ~07:30 UTC |
| #967 | askeladd | AdamW aux β₂ anneal Arm B (all→0.95) | `pd25zsdp` | running | ~775 (23%) | 3.69 | Arm A finished 3.26850 ✓; B ~03:50 UTC, C/D thereafter |
| #980 | edward | Muon μ cooldown anneal | pending | — | — | — | pickup imminent |
| **#982** | **nezuko** | **Per-block-type Muon μ (NEW)** | pending | — | — | — | pickup ~02:30 UTC |
| **#984** | **thorfinn** | **SF-AdamW for aux (NEW)** | pending | — | — | — | pickup ~02:30 UTC (smoke-test then full arms) |

### #944 grad-centralization chain — 3/4 terminal (asymmetric pattern)

| arm | run_id | gc_mode | val/loss | Δ_vs_A (3.26656) | Δ_vs_baseline 3.26756 |
|:---:|---|---|:---:|:---:|:---:|
| A (ctrl) | `6ht4oj5l` | none | 3.26656 | — | −0.00100 (drift PASS) |
| B | `fd5nszpw` | col | 3.27594 | **+0.00938** | **+0.00838 (productive-NEG)** |
| C | `2hymudml` | row | **3.26955** | **+0.00299** | **+0.00199 (drift edge NULL/mild-NEG)** |
| D | `g32ouqhe` | both | pending | pending | pending |

**Reading**: gc=col catastrophic-NEG, gc=row mild-NEG/within-drift. Asymmetric outcome confirmed — col mechanism worse than row mechanism. Arm D (both) is the deciding arm; if both-arm ≥ +0.005 vs A, axis closes productive-NEG. If both arm > B (compositional worsening), interference effect. If both arm ~ row-only (~+0.003), composition is row-dominant.

### #956 alphonse — Arm B early-killed (cap=1.0 too aggressive)

Arm A `kjrd1usm` finished val=**3.26765** (drift PASS Δ=+0.00009 essentially baseline parity, hook cap=0.0 bit-clean). Arm B (cap=1.0) early-killed at step 1125: cap fired on 90.4% of rows, val/loss=3.65469, conclusive divergence per midpoint kill gate. Student launched Arm C (cap=4.0) at 00:58 UTC. Arm C is the most likely "Goldilocks" cap given natural lm_head row-norm distribution (mean=3.70, p50=3.60, max=12.70).

### Next imminent terminal

- **#944 Arm D** (both gc) `g32ouqhe` step ~825 → ETA ~02:47 UTC. Decides axis: D~A → axis closes asymmetric-NEG (col-only); D>B → compositional worsening; D∈(C,B) → row-dominant composition.
- **#956 Arm C** (cap=4.0) `pfusx38h` step ~850 → ETA ~02:47 UTC. Decides Goldilocks cap viability.
- **#967 Arm B** (β₂→0.95 all-aux) `pd25zsdp` step ~775 → ETA ~03:50 UTC.
- **#919 PP seed 2** (β₁ cooldown) `ofm1da08` step ~1150 → ETA ~05:30 UTC. G1 budget tight.

### Closed prior cycles (still relevant context)

- **#929 edward** CLOSED productive-NULL with regression tail (AdamW aux v_t floor: inert at low floor, regression-harmful at binding floor). Reassigned to #980 Muon μ cooldown anneal.
- **#845 askeladd** CLOSED productive-NULL (composition-overlap with init-anchor WD). Reassigned to #967.
- **#933 nezuko** [this cycle] CLOSED productive-NULL (path-norm body velocity, longer-window sub-threshold). Reassigned to #982.
- **#880 thorfinn** [this cycle] CLOSED productive-NULL (Muon² body v_t β₂=0.9999 paired-pod n=3, canonical magnitude-collapse sign-flip at Pod 2). Reassigned to #984.

---

## Cycle 177 snapshot (23:25 UTC)

### Terminals landed since cycle 175

**#944 tanjiro grad-centralization chain — 2/4 arms terminal, col mechanism-NEG**

| arm | run_id | gc_mode | val/loss | Δ_vs_A | drift_vs_baseline 3.26756 |
|:---:|---|---|:---:|:---:|:---:|
| A (ctrl) | `6ht4oj5l` | none | **3.26656** | — | −0.00100 (drift PASS, control bit-clean) |
| B | `fd5nszpw` | col | **3.27594** | **+0.00938** | **+0.00838 (catastrophic NEG)** |

Arm B's pre-NS column-mean DC removal regresses the body Muon by ~0.009 vs control. Within-arm direction-WRONG (steady gap +0.011→+0.009 across steps 1000→3275). No NaN/divergence — clean mechanism-negative signal on this stack. Arm C (row) started 23:07 UTC ETA terminal ~01:00 UTC May 24; Arm D (both) ETA ~02:53 UTC. Awaiting full 4-arm SENPAI-RESULT before close decision (col-NEG already known; row + both decide whether axis closes as productive-NEG or asymmetric-NEG).

### Active chains (as of 23:25 UTC)

| PR | Student | Hypothesis | Run | step | val/loss | ETA |
|:---:|:---:|---|---|:---:|:---:|:---:|
| #944 | tanjiro | gc Arm C (row) | (new run, name pending) | ~50 | early | C ~01:00 UTC, D ~02:53 UTC |
| #845 | askeladd | embed-grad freq rescale v2 Pod 3 | `4d5fuxdk` | 2300 | 3.4347→3.28 | ~01:00 UTC (slower than original ETA) |
| #880 | thorfinn | Muon² body v_t Pod 2 A | `m0jdlx6u` | 1850 | 3.5121→3.28 | Pod 2 A ~00:50 UTC; Pod 2 D ~02:50 UTC |
| #956 | alphonse | lm_head per-row max-norm Arm A | `kjrd1usm` | 1225 | early | full chain ~05:30 UTC |
| #963 | frieren | post-NS v_post Arm A | `5vzq0lob` | 475 | early | full chain ~08:00 UTC |
| #919 | fern | β₁ cooldown anneal paired-pod n=3 Arm D seed 1 | `64ye4aib` | 325 | early | full chain ~04:30 UTC |
| #929 | edward | AdamW aux v_t floor (Arms C, D pending) | — | — | Arm B done 3.26990 | ~03:00 UTC |
| #933 | nezuko | path-norm body-weight velocity (Arms C, D pending) | — | — | Arm B done 3.27009 | ~03:50 UTC |

### Imminent terminal cluster (next ~3h)

- **#880 Pod 2 A** `m0jdlx6u` ~00:50 UTC — paired-pod control terminal. Pod 2 D follows ~02:50 UTC closing the n=3 chain.
- **#944 Arm C (row)** ~01:00 UTC — decides whether gc axis is productive-NEG (both axes wrong) or asymmetric.
- **#845 Pod 3 v2** `4d5fuxdk` ~01:00 UTC — final pod of n=3 v2 chain. Current partial n=2 mean=3.26747 (marginal vs 3.26756 baseline). Pod 3 v2 value will be binding for the merge gate.

### Sticky advisor-action flags (still no-op)

- **#880** `needs_rebase` — from prior conditional-rebase comment, student already addressed in Pod 1 D launch. No action.
- **#845** `merge_conflict_comment` — stale 17:54 UTC comment, student already responded. No action.

### Operational notes

- Zero idle GPUs, all 8 students productively training.
- #944 col-gc mechanism-NEG result is the first cycle-177 terminal-flavor data. Aligns with general pattern that "pre-NS DC removal" disturbs Muon stack updates more than it helps.
- No human GH issues this cycle.
- Quiet polling cycle expected for ~85 min until first cluster terminals (Pod 2 A, #944 Arm C, #845 Pod 3 v2 all ~00:50-01:00 UTC).

---

## Cycle 171 snapshot (21:58 UTC)

### Terminals landed since cycle 170

| PR | Arm/Pod | Run ID | val/loss | Δ vs baseline 3.26756 | direction | first_step_to_target |
|:---:|:---:|---|:---:|:---:|:---:|:---:|
| #845 | Pod 2 v2 | `y9g5c6v5` | **3.26877** | +0.00121 | drift PASS ±0.003 | 3200 |
| #938 | Arm B (compound) | `xsikeso6` | **3.29771** | +0.03015 | **regression** | −1 (never) |

### #845 — embed-grad freq rescale v2 chain partial n=2 favorable

- Pod 1 v2 (`s5mjy5vw`): 3.26617 (−0.00139, favorable)
- Pod 2 v2 (`y9g5c6v5`): 3.26877 (+0.00121, drift PASS)
- **n=2 mean: 3.26747** — Δ=−0.00009 vs baseline 3.26756 (marginal, technically passes both merge gates)
- Pod 3 v2 (`4d5fuxdk`): RUNNING step 150, started 21:50 UTC, ETA ~23:45 UTC
- **Action**: posted favorable ack on Pod 2 v2 + Pod 3 v2 visibility. Holding merge decision for n=3 terminal. If Pod 3 v2 lands in 3.265-3.270 range, this becomes a clean marginal-favorable merge candidate.

### #938 — lm_head init-anchor compound REGRESSION — CLOSED (aborted_early_kill)

- Arm A (control, embed-only λ=0.001): 3.27080 (drift +0.00324, ~2σ borderline)
- Arm B (compound, embed+lm_head both λ=0.001): **3.29771 — Δ_B_vs_A = +0.02691 within-pod** (CATASTROPHIC)
- Arms C/D: aborted per student's own early-kill gate (val ≥ 3.275 → mandatory abort)
- **Root cause**: `model.proj.weight` is zero-initialized; init-anchor degenerates to `W←W·(1−λ)` (pure decay toward zero). Not a mechanism failure — a degenerate initialization architecture.
- **Axis status**: lm_head init-anchor axis CLOSED. lm_head is NOT untouchable — future constraints (max-norm cap #956, spectral norm, LR scaling) avoid the zero-init degeneracy.
- **alphonse REASSIGNED to #956 (lm_head per-row max-norm soft-clamp)**

### Active chains (still running)

| PR | Student | Hypothesis | Run | step | val/loss | ETA |
|:---:|:---:|---|---|:---:|:---:|:---:|
| #845 | askeladd | embed-grad freq rescale v2 Pod 3 | `4d5fuxdk` | 925 | 3.6562 | ~23:45 |
| #956 | alphonse | lm_head per-row max-norm soft-clamp (NEW) | — | poll-pending | — | ~03:30 |
| #933 | nezuko | path-norm body-weight velocity (Arms C, D pending) | (queued Arms C, D) | — | Arm B done 3.27009 | ~01:50 |
| #929 | edward | AdamW aux v_t floor (Arms C, D pending) | (queued Arms C, D) | — | Arm B done 3.26990 | ~01:00 |
| #963 | frieren | post-NS v_post (NEW, 4-arm β₂_post) | — | poll-pending | — | ~06:30 |
| #880 | thorfinn | Muon² body v_t β₂=0.9999 Pod 2 A | `m0jdlx6u` | 30 | early | ~23:55 / Pod 2 D ~01:50 |
| #919 | fern | β₁ cooldown anneal **paired-pod n=3 Arm D (rebase pending)** | (sent back 23:00 UTC) | — | N=1 D done 3.26748 | ~04:30 |
| #944 | tanjiro | Muon body grad centralization Arm B | `fd5nszpw` | 2025 | 3.4430 | ~01:00 (+1d) |

### Cycle 175 terminals digest (#919 fern + cycle 173 carryover below)

**#919 fern — AdamW aux β₁ cooldown annealing N=1 chain TERMINAL (sent back for paired-pod n=3 on Arm D)**

| Arm | env | val_loss | Δ_vs_A | Δ_vs_baseline 3.26756 |
|:---:|:---|:---:|:---:|:---:|
| A (ctrl, sentinel disabled) | β₁=0.80 throughout | 3.26916 | — | +0.00160 |
| B (FINAL=0.70 SCOPE=all) | anneal β₁: 0.80→0.70 last 30%, all aux | 3.26815 | −0.00101 | +0.00059 |
| C (FINAL=0.50 SCOPE=all) | anneal β₁: 0.80→0.50 last 30%, all aux | 3.26928 | +0.00012 | +0.00172 |
| **D (FINAL=0.70 SCOPE=embed)** | **anneal β₁: 0.80→0.70 last 30%, embed-only** | **3.26748** | **−0.00168** | **−0.00008** |

**Scope finding**: D > B at same FINAL=0.70, Δ_D_vs_B=−0.00067 within-pod. Embed-group β₁ anneal is the load-bearing piece.

**Decision**: send-back for paired-pod n=3 on Arm D. Rationale: absolute val parity with baseline at N=1 + drift-adjusted Δ_D_vs_baseline=−0.00168 + clean scope finding → projects to merge-eligible n=3 mean even with 50% magnitude compression.

### Cycle 173 terminals digest

| PR | Arm | Run | val/loss | Δ vs ctrl | direction |
|:---:|:---:|---|:---:|:---:|:---:|
| #933 | Arm B (λ=1e-5/k=10) | `puhd26f3` | 3.27009 | +0.00070 (vs `2ejxjr5g` 3.26939) | productive-NULL |
| #929 | Arm B | `gea1rxoq` | 3.26990 | +0.00009 (vs `tm15vkbl` 3.26981) | noise-floor NULL |
| #880 | Pod 1 D | `5uj9nwv9` | 3.26876 | −0.00061 (vs Pod 1 A `it83u13l` 3.26937) | sub-threshold ✓ |
| #923 | Arm B (α=0.50) | `fi8angie` | **3.33335** | **+0.06460** (vs `43z88t0h` 3.26875) | **CATASTROPHIC — abort C/D** |

### Sticky advisor-action flags

- **#880** `needs_rebase`: from my own prior conditional-rebase comment; student already addressed in Pod 1 D launch. No action needed.
- **#845** `merge_conflict_comment`: from old 17:54 UTC advisor comment that student already responded to. No action needed.

### Operational notes

- Zero idle GPUs — all 8 students productively training.
- #938 CLOSED (cycle 172). alphonse reassigned to #956 (lm_head per-row max-norm soft-clamp); pod has not yet polled (PR assigned 22:15 UTC).
- Cycle 173 (22:30 UTC): 4 acks posted (#923 abort/back, #933 ack, #929 ack, #880 ack).
- Next imminent terminal cluster (22:50-23:55 UTC): #919 Arm D (3025/3350, val=3.2976 trending NEG), #845 Pod 3 v2, #880 Pod 2 A.
- #923 CLOSED (cycle 174). frieren reassigned to #963 (post-NS v_post, β₂_post ∈ {0.95,0.99,0.999} sweep on body Muon).
- #919 cycle 175: N=1 chain terminal landed. Sent back for paired-pod n=3 on Arm D (FINAL=0.70 SCOPE=embed). ETA ~04:30 UTC May 24.
- alphonse #956 and frieren #963 pods polled and started chains. alphonse running step 725, frieren initializing.
- #944 tanjiro Arm B currently at step 2875 val=3.3271 — trajectory tracking baseline-rate descent, projected terminal ~3.27-3.28 range. Marginal vs target.

---

## Cycle 131-132 snapshot (14:55 UTC)

### Closures & assignments this cycle
- **#883 fern CLOSED 14:46 UTC productive-NULL** — Goldilocks spread sweep on stochastic NS cooldown. Arm B (spread=1) Δ_vs_A=−0.00184 best; full bracket terminal A=3.26965, B=3.26781, C=3.26864, D=3.26958. Sharp peak at spread=1, monotone falloff on broad side (C→D), flat plateau on tight side (B≈merged spread=2). Goldilocks band [1,2] characterized. Student-recommended no paired-pod given OLD-stack chain + best-arm spread already adjacent to merged spread=2. Durable finding: stochastic NS cooldown Goldilocks band is [1,2] with both spreads producing sub-noise gains; spread=2 confirmed as merged default optimal corner.
- **#919 fern ASSIGNED 14:46 UTC AdamW aux-group β₁ cooldown annealing (4-arm)** — fresh schedule axis. Linearly anneals β₁ from 0.95 base → {0.70 all, 0.50 all, 0.70 embed-only} during last 30% of training. Mechanism-distinct from closed #514 β₁ warmup (NEG, opposite-window) and #599 per-group fixed β₁ (NEG). Opposite-direction schedule axis. ETA ~7.2h chain.

### #900 frieren — CATASTROPHIC NEG diagnosis 14:51 UTC, abort recommendation posted
Arm A (`wr4gljm4`) terminal val=3.26811 drift PASS −0.00133. **Arm B `j141b0z2` TERMINAL val=3.41640 Δ_vs_A=+0.14829 — catastrophic NEG (~100× productive-NEG threshold)**. Trajectory descended steadily but never converged near 3.28 by step 3350. Pre-staged early-kill gate (val>3.30 at step 1675) fired retrospectively — student's `noise_scale_t > 0.0` guard bypassed the kill.

Arm C `odlsljxy` (scope=all noise=0.005) launched 14:45 UTC step 275/3350 — already tracking Arm B trajectory at val=4.67 (matches B step 250 val=4.66). Will be catastrophic with body Muon noise added on top. Arm D (n=0.010, anneal=0.30) would be worse.

**Mechanism reading**: anisotropic noise `noise_std ∝ sqrt(v_t/mean(v_t))` is **direction-inverted at this maturity** — high v_t coordinates (well-trained, common-token directions) get MORE noise than rare (small v_t) coordinates, inverting the intended Zipf-tail effect. Mechanism fundamentally direction-wrong, not tunable.

**Action**: posted advisor abort recommendation 14:51 UTC. Awaiting student confirmation + terminal SENPAI-RESULT. PR converted to draft, label swapped review→wip (preflight ack: already in draft).

**Save value**: aborting C+D saves ~3.4 GPU-hours.

**Pre-staged outcome #4 fires**: anisotropic noise harmful at this baseline → close axis. Curvature-matched noise injection family CLOSED via #411 (isotropic null) + #900 (anisotropic NEG catastrophic).

### #789 tanjiro v2 paired-pod 5/6 terminal (cubic NS @ FLOP-eq, post-#787 stack)

| Pod | seed | A (quintic) | B (cubic) | Δ_within | direction |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | 0 | 3.26929 | 3.26961 | +0.00032 | INcorrect (mild) |
| 1 | 1 | 3.27016 | 3.26984 | −0.00032 | correct (mild) |
| 2 | 2 | A live `m9u912jc` step 1 | not started | TBD | TBD |
| mean(n=2) | — | 3.26973 | 3.26973 | **0.00000** | — |

Partial means within-Δ exactly zero at noise floor. Pod 2 A launched 14:56 UTC, terminal ~16:44 UTC; Pod 2 B ~18:30 UTC. Final n=3 ETA ~18:30 UTC. **Pattern**: post-#787 stack absorbs cubic-NS mechanism gain. Original OLD-stack mean Δ_vs_A=−0.00056 retained even more weakly (~0% retention) under new stochastic NS noise.

### Rebased chain progress (cycle 132)

| PR | Student | Branch | Status |
|:---:|:---:|---|---|
| #847 | alphonse | rebased post-#787 | s1=3.26642 STRONG TERMINAL Δ_vs_new=−0.00302; s2 `1zjpifpb` step 1750/3350 (52%) val=3.47; s3 ETA ~17:30 UTC |
| #845 | askeladd | rebased post-#787 | s1=3.26950 marginal +0.00006; s2 `z85uh78i` step 1950/3350 (58%) val=3.45; s3 ETA ~17:00 UTC |
| #880 | thorfinn | rebased paired-pod n=3 | LAUNCHED 14:39 UTC. Pod 0 A `5y792dxt` step 500/3350 (15%). Full chain ETA ~01:30 UTC (next day) |
| #874 | edward | (no rebase needed) | Arm D `t6kzt6lx` step 2525/3350 (75%) val=3.37 — ETA terminal ~15:25 UTC |

**#847 alphonse n=3 merge math** (frozen vs 3.26944): s1=3.26642 STRONG → seeds 2+3 mean must ≤ 3.27095. Even worst-case (3.27094 each from OLD-stack baseline) → final mean=3.26943, just under threshold. **MERGE outcome substantially elevated.** Mechanism: weight-side init-anchor at λ=0.001 composes favorably with stochastic NS cooldown.

**#845 askeladd n=3 merge math** (frozen vs 3.26944): s1=3.26950 above ceiling by +0.00006 → seeds 2+3 must average ≤ 3.26941 (tighter than original chain's 3.26920). **Gradient-side mechanism attenuates under new stack.** Two-mechanism cross-axis disambiguation: weight-side AUX composes (#847), gradient-side AUX attenuates (#845).

### #825 nezuko Pod 2 progress
- Pod 2 A (`gq3yhvvj`) finished 3.26910 (Δ vs baseline −0.00126, drift PASS)
- Pod 2 B (`u8nbz3og`-ish) finished 3.27196 (Δ_vs_A=+0.00286 regression)
- Pod 2 C (`x4oop63a`) finished 14:54 UTC val=3.27844 (Δ_vs_A=+0.00934 strong regression — matches Pod 1 C=3.27859, replicating)
- Pod 2 D pending launch

Bilateral closure pattern: Cautious AdamW per-aux-group consistently regresses across all 6 paired-pod measurements (2 pods × 3 arms B/C/D each). lm_head Cautious adds most damage (+0.009-0.010 across both Pod 1 C, Pod 2 C). Awaiting Pod 2 D for full chain terminal.

### Other in-flight (no SENPAI-RESULT pending)
- #880 thorfinn rebased paired-pod chain LIVE
- #874 edward Arm D in cooldown (no rebase needed — chain on post-#787)
- #919 fern β₁ cooldown anneal chain — student picking up assignment on next poll
- #847 + #845 alphonse + askeladd rebased seeds 2/3

### Zero idle students (cycle 132). Eight active WIP PRs (#847 #845 #880 #874 #825 #789 #900 #919).

---

## Cycle 133 snapshot (15:15 UTC)

### Closures & assignments this cycle
- **#900 frieren CLOSED 15:09 UTC productive-NEG** — Anisotropic grad noise (Adam-variance-matched). Pre-staged outcome #4 fired: all arms Δ ≥ +0.0015. Arm A drift PASS (−0.00133); Arm B val=3.41640 **Δ_vs_A=+0.14829 catastrophic**; Arm C killed at step 375 (trajectory matching B); Arm D aborted. Mechanism: `noise_std ∝ sqrt(v_t/mean(v_t))` is direction-inverted at this maturity — high v_t (common-token) coordinates get MORE noise, inverting the intended Zipf-tail boost. ~3.4 GPU-hours saved by early abort. **Curvature-matched noise injection family fully closed** (axis-fencing): isotropic #411 NULL + anisotropic #900 catastrophic-NEG. 89th productive-null/negative.
- **#923 frieren ASSIGNED 15:15 UTC Zipf-freq-weighted CE loss (WAVE5-1)** — Redistribute gradient mass toward rare-token long tail by multiplying per-token CE by `w(v) ∝ 1/freq(v)^α` (normalized mean=1.0). 4-arm α sweep: A=0 (ctrl), B=0.50 (1/sqrt), C=0.33 (softer), D=0.75 (aggressive).

## Cycle 135 snapshot (15:35 UTC)

### Closures & assignments this cycle
- **#874 edward CLOSED 15:31 UTC productive-NULL** — Embed init magnitude sweep (N(0,1) scale ∈ {1.0 ctrl, 0.5, 0.7, 1.5}). All 3 non-ctrl arms direction-correct vs Arm A but ALL absolute values ≥ baseline 3.26944. De-biased read: Arm A drift +0.00173 unfavorable absorbs all apparent within-pod signal. Best arm D=3.26957 fails Gate 1 by +0.00013. No arm clears stat-rule range (0.00160 < 0.004). Student's NULL verdict accepted — embed init magnitude is robust to ±50% at merged hp cocktail. 90th productive-null/negative.
- **#929 edward ASSIGNED 15:35 UTC AdamW aux v_t second-moment floor (WAVE5-2)** — Multiplicative floor `v_eff = max(v_t, v_floor_frac × median(v_t))` on aux groups (embed + lm_head + scalars). Mechanism-distinct from #652 eps NEG (additive constant inert). Targets Zipf-structured v_t distribution: rare-token rows have tiny v_t → step-size blowup risk. 4-arm: A=ctrl, B=1e-4 median, C=1e-3 median, D=1e-6 max_frac. AMSGrad-inspired softer variant.

### Active chains at cycle 135
| PR | Student | Status | ETA |
|:--:|:-------:|--------|-----|
| #929 | edward | ASSIGNED AdamW aux v_min floor | student polling |
| #923 | frieren | ASSIGNED Zipf-freq-CE | student polling |
| #919 | fern | Arm A `7nvjseq2` ~13% live | terminal ~16:37 UTC |
| #847 | alphonse | rebased s2 `1zjpifpb` ~76% | terminal ~16:00 UTC |
| #845 | askeladd | rebased s2 `z85uh78i` ~81% | terminal ~15:55 UTC |
| #880 | thorfinn | Pod 0 A `5y792dxt` ~39% | full chain ~01:30 UTC |
| #789 | tanjiro | Pod 2 A `m9u912jc` ~24% | terminal ~18:30 UTC |
| #825 | nezuko | Pod 2 D pending launch | ~end of day |

### Zero idle students (cycle 135). Eight active WIP PRs (#929 #923 #919 #847 #845 #880 #789 #825).

## Cycle 159 snapshot (20:15 UTC) — three in-flight terminals, all chains continuing

### Advisor actions this cycle
- **#845 askeladd** (Pod 1 v2 favorable, stale_wip false-positive): Pod 1 v2 `s5mjy5vw` terminal val=**3.26617** (Δ_vs_new_base=−0.00139 favorable). Pod 2 v2 `y9g5c6v5` launched 19:55 UTC step ~400. Posted advisor interim ack confirming favorable + chain continues; mean(n=3) target ≤ 3.26756 for merge.
- **#938 alphonse** (Arm A drift marginal, stale_wip false-positive): Arm A control `f2aixnq9` finished val=**3.27080** (Δ_vs_new_base=+0.00324 — just outside ±0.003 drift gate). Arm B `xsikeso6` launched 20:00 UTC step ~250. Posted advisor visibility ack noting drift is borderline (~2σ above n=3 mean) and absolute mean(B/C/D) ≤ 3.26756 still required for merge.
- **#880 thorfinn** (needs_rebase): Pod 0 paired done (A=3.26951, D=3.26786, Δ_within=−0.00165 sub-threshold). Pod 1 Arm A `it83u13l` at step 3300/3350 val=**3.27145** (Δ_vs_new_base=+0.00389, outside drift gate). Pod 1 Arm A drifting +0.00194 higher than Pod 0 Arm A — chain integrity at risk. Posted advisor decision-branch comment: continue if drift holds, pre-stage rebase if drift deepens, early-stop + rebase+rerun on post-#847 stack with Arm D only if Pod 1 Arm A > 3.275.

### Active chains at cycle 159
| PR | Student | Status | ETA |
|:--:|:-------:|--------|-----|
| #845 | askeladd | Pod 1 v2 favorable 3.26617; Pod 2 v2 running step 400 | full chain ~22:50 UTC for n=3 |
| #938 | alphonse | Arm A done 3.27080 drift marginal; Arm B running step 250 | Arm B terminal ~21:50 UTC |
| #880 | thorfinn | Pod 0 done; Pod 1 Arm A running step 3300 drift unfavorable; rebase pre-stage advised | Pod 1 A terminal imminent (~5 min) |
| #919 | fern | Arm 1 done 3.26815 (+0.00059), Arm 2 `fivhmphf` step 2350 running | Arm 2 terminal ~20:30 UTC |
| #923 | frieren | Arm 1 done 3.26875 (+0.00119), Arm 2 crashed at step 1375; current arm not visible in expected group | check next cycle |
| #929 | edward | Arm 1 crashed at step 1075; pod GPU 100% — recovering/retrying | check next cycle |
| #933 | nezuko | Arm 1 done 3.26939 (+0.00183), Arm 2 `puhd26f3` just started (step 0) | Arm 2 terminal ~22:00 UTC |
| #944 | tanjiro | grad-centralization Arm A `6ht4oj5l` step 1375 val 3.538 normal | Arm A terminal ~21:15 UTC |

### Zero idle students (cycle 159). Eight active WIP PRs (#845 #938 #880 #919 #923 #929 #933 #944).

### Operational notes
- **stale_wip false-positives** on #845 and #938 are silent-progression artifacts: W&B runs are progressing normally but no fresh PR comment between SENPAI-RESULT posts.
- **#880 Pod 1 Arm A drift +0.00194** beyond Pod 0 Arm A is the cycle's most concerning operational signal. If pattern continues into Pods 1/2, the chain on OLD stack is no longer representative and merge-gate evaluation moves to rebased-only.
- **Three arm-1 results landed within ±0.0007** of merged baseline (#845 v2=3.26617, #919=3.26815, #923=3.26875, #938=3.27080, #933=3.26939) — most n=1 single-seed variance is within normal range.
- **#929 edward crashed at step 1075 + #923 frieren arm 2 crashed**: 2 of 8 active chains had a crashed early-step run. Within tolerance for n=1 screening (transient pod failures) but worth monitoring next cycle.

## Cycle 158 snapshot (18:45 UTC) — #789 closed, tanjiro idle

### Closures this cycle
- **#789 tanjiro CLOSED 18:42 UTC productive-NULL** — Cubic NS @ FLOP-equivalence (NS_DEGREE=3, iters=18 hot, 24 cooldown) paired-pod v2 on post-#787 stack. mean(B,n=3)=3.26930, mean(A,n=3)=3.26936, Δ_within=−0.00006 (89% collapse from v1's −0.00056), paired t=−0.324, 2/3 dir-correct. vs OLD baseline 3.26944 all gates pass (slim), but Gate 1 FAIL vs NEW baseline 3.26756 by +0.00174. Wall-clock sign-flipped (−0.28% faster on v1 → +0.58% slower on v2) confirming timing-variance interaction. **Mechanism interpretation accepted**: cubic-NS@FLOP-eq targets the same cooldown-phase NS dynamics as merged stochastic-NS-cooldown (iter-count variance vs polynomial-shape change) — orthogonality conjecture REJECTED, same-substrate competition. 12th paired-pod outcome since #708. Axis-fencing result: NS-polynomial-degree axis at FLOP-eq absorbed by stochastic-NS-cooldown variance. `NANOGPT_NS_DEGREE` env flag stays as opt-in cubic path; default remains quintic.

### Active chains at cycle 158
| PR | Student | Status | ETA |
|:--:|:-------:|--------|-----|
| **#919** | fern | Arm A=3.26916, Arm B `5mkteulp`=3.26815 (Δ_within=−0.00101, sub-threshold favorable productive-NULL); Arm C `1416294` LIVE | C terminal ~20:43 UTC, D ~22:35 UTC |
| #845 | askeladd | rebased onto post-#847 (`a741e3eb`), chain v3 running | full chain ~01:30 UTC |
| #847 | alphonse | MERGED — student now WIP on #938 lm_head init-anchor | — |
| #938 | alphonse | lm_head init-anchor 4-arm (A=ctrl/B=embed+lm_head 0.001/C=lm_head only/D=embed 0.001+lm_head 0.003) | implementing |
| #880 | thorfinn | Pod 0 paired terminal ArmA=3.26951 ArmD=3.26786 Δ_within=−0.00165 sub-threshold; continuing on OLD stack | full chain ~01:30 UTC |
| #929 | edward | rebased onto post-#787 (`f819bab5`) → still CONFLICTING after #847 merge; needs second rebase | NEEDS REBASE post-#847 |
| #923 | frieren | rebased onto post-#787 (`315c332`); CLEAN post-#847 | full ETA ~01:00 UTC |
| #933 | nezuko | rebased onto post-#787; CLEAN post-#847 — EMBED_INIT_ANCHOR + PATH_NORM both active | full ETA ~01:00 UTC |
| **tanjiro** | — | **IDLE** — needs new assignment | — |

### Tanjiro's next axis — lm_head LR multiplier
- Embed-LR-mult is merged at 1.5× (#393); lm_head has been left at 1.0×.
- 4-arm sweep over `NANOGPT_ADAMW_LM_HEAD_LR_MULT`: A=1.0× (ctrl, no env), B=0.7×, C=1.5× (mirror embed), D=2.0× (aggressive).
- Mechanistically distinct from #938 alphonse lm_head init-anchor (WD-space) — this is LR-space.

### Outstanding rebase needs
- **#929 edward** — was on `f819bab5` (post-#787), now CONFLICTING vs `85050ef`. Need to send back for rebase onto current advisor tip.
- **#880 thorfinn** — intentionally on OLD pre-#787 stack (Pod 0 paired showing sub-threshold signal). The CONFLICTING flag is expected; stack-version routing plan in place.

## Cycle 152 snapshot (17:52 UTC) — DOUBLE MERGE WINDOW

### Baseline update: PR #847 MERGED — new baseline val=3.26756 / fs=3183.33

**New merged baseline — post-#847:**
```
...all prior flags unchanged...
NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001   ← NEW: post-AdamW hook, embed init-snapshot anchor
```

| PR | Change | val (n) | Cumulative baseline |
|----|--------|---------|---------------------|
| ... (prior entries) | | | |
| **#847** | **Embed init-anchor WD λ=0.001** | **3.26756 (3)** | **3.26756** ← CURRENT |

Key signal: composition with #787 stochastic-NS-cooldown produced +1.74 mUE vs pre-rebase. Mechanisms on disjoint substrates. fs=3183.33 (−25 steps vs prior 3208.33).

### Closures & assignments this cycle
- **#847 alphonse MERGED 17:51 UTC** — embed init-anchor WD λ=0.001. mean=3.26756, Δ=−0.00188, t=2.49, 3/3 dir-correct. Post-rebase composition gain confirmed. **New baseline val=3.26756 / fs=3183.33**. Alphonse now idle.
- **#845 askeladd sent back for second rebase** — mean(post-#787)=3.26850 now above new baseline 3.26756 by +0.00094. Sent back for rebase+re-run on post-#847 stack to test composition (freq-rescale gradient-space ↔ init-anchor weight-space). askeladd now WIP.
- **alphonse ASSIGNED new experiment** (see below)

### Active chains at cycle 152
| PR | Student | Status | ETA |
|:--:|:-------:|--------|-----|
| new | alphonse | ASSIGNING lm_head init-anchor extension | student polling |
| #845 | askeladd | sent back for rebase post-#847 | rebasing |
| #919 | fern | Arms B/C/D sequential (Arm B `5mkteulp` ~3350) | terminal ~18:40 UTC |
| #789 | tanjiro | Pod 2 ArmB `e55k3ngb` running | terminal ~18:39 UTC |
| #880 | thorfinn | Pod 0 ArmD `v3k18lkf` running (~65%) | full chain ~01:50 UTC |
| #933 | nezuko | path-norm body reg — student implementing | — |
| #929 | edward | AdamW aux v_min floor — student implementing | — |
| #923 | frieren | Zipf-freq-CE — student implementing | — |

### Research portfolio at cycle 152
- **Embed group** extensively explored: LR mult (+), linear_floor cooldown (+), clip asymmetry (+), init-anchor WD (+merged), freq-rescale (rebasing)
- **Body-Muon** axis: attn/mlp LR asymmetry (+), stochastic NS cooldown (+), NS schedule (+), β₁ cooldown anneal (in-flight #919)
- **Loss function**: Zipf-CE (in-flight #923), focal/smoothing/z-loss (closed prior rounds)
- **Preconditioner**: v_min floor (in-flight #929), eps NEG (#652)
- **Regularization**: path-norm body reg (in-flight #933), Cautious AdamW (NEG), sign-aware masks (NEG), gradient noise (NEG/NULL)
- **lm_head**: relatively unexplored — init-anchor extension is the next probe

## Cycle 142 snapshot (16:45 UTC)

### Closures & assignments this cycle
- **#825 nezuko CLOSED 16:43 UTC productive-NEG** — Cautious AdamW aux sub-group ablation (12 runs, n=3 paired-pod × 4 arms). All 9 treatment diffs positive (regression). Mean Δ: embed +0.00336, lm_head +0.00913, all +0.01193. Harms compose additively. Drift gate passed on all 3 controls. **lm_head is dominant locus of aux-Cautious harm (~92% of #751 all-aux regression).** Sign-aware update-mask family fully exhausted at all granularities (#126 elem, #629 layer, #751 all-aux, #825 sub-group). 91st productive-null/negative.
- **#933 nezuko ASSIGNED 16:44 UTC path-norm body regularization (WAVE5-6)** — penalizes body parameter velocity `‖θ_t − θ_{t-k}‖²` over sliding window. Mechanism-distinct from L2 WD (distance-from-zero) and #847 init-anchor WD (distance-from-init). Targets oscillatory trajectories in body weight space. 4-arm: A=ctrl, B=λ1e-5/k10, C=λ1e-4/k10, D=λ1e-5/k50. Early-kill gate at step 1000 if Arm C val ≥ 3.30.

### Key in-flight merge candidates (cycle 142)
| PR | Student | s1 | s2 | Mean(n=2) | s3 ETA | Merge likelihood |
|:--:|:-------:|:--:|:--:|:---------:|:------:|:---------------:|
| #847 | alphonse | 3.26642 | 3.2673 | 3.26686 | ~19:15 UTC | **VERY HIGH** |
| #845 | askeladd | 3.26950 | 3.2680 | 3.26875 | ~17:35 UTC | HIGH (~50-60%) |

### Active chains at cycle 142
| PR | Student | Status | ETA |
|:--:|:-------:|--------|-----|
| #933 | nezuko | ASSIGNED path-norm body reg | student polling |
| #929 | edward | ASSIGNED AdamW aux v_min floor | student polling |
| #923 | frieren | ASSIGNED Zipf-freq-CE | student polling |
| #919 | fern | Arm A `7nvjseq2` ~85% | terminal ~17:14 UTC |
| #847 | alphonse | s3 `l35g6tlk` early | terminal ~19:15 UTC |
| #845 | askeladd | s3 `5z4wy3k6` ~7% | terminal ~17:35 UTC |
| #880 | thorfinn | Pod 0 A `5y792dxt` ~56% | full chain ~01:30 UTC |
| #789 | tanjiro | Pod 2 A `m9u912jc` ~41% | terminal ~18:30 UTC |

### Zero idle students. Eight active WIP PRs (#933 #929 #923 #919 #847 #845 #880 #789).

---

## Active experiments (all on r4)

### ✅ fern #408 — Adaptive Gradient Clipping (AGC) — CLOSED 14:15 UTC productive-null

Paired-pod confirmation collapsed pod-0 signal. Final n=3 pooled: mean(val_B)=3.27271 > baseline 3.27200 → pre-staged rule triggers CLOSE. Pod-0 Δ=−0.00252 was favorable-seed luck. AGC mechanism consistent (99.4% trigger rate) but val benefit not reproducible. **16th productive-null this cycle.**
**Follow-up**: fern assigned **#477 OrthoGrad for aux groups**.

### ✅ fern #477 — OrthoGrad for aux AdamW groups — CLOSED 21:35 UTC productive-null

Arms B (embed: +0.00163), C (lm_head: +0.00285) regress; D (embed+lm_head: −0.00080) recovers. Non-monotonic: single-group breaks embed/lm_head magnitude balance; combined restores it. D Δ=−0.00080 passes stat-rule on absolute baseline but well short of −0.002 within-pod threshold — productive-null. **22nd productive-null/negative this cycle.** Key finding: aux groups co-evolve as a coupled system, resist single-axis gradient intervention.
**Follow-up**: fern assigned **#514 β₁ warmup on aux AdamW groups** — first-moment smoothing-rate schedule axis.

### ✅ fern #514 — AdamW β₁ warmup on aux groups — CLOSED 06:15 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS): A=3.27279, B=+0.00135 (null edge), C=+0.00162 (regression), D=+0.00252 (regression). Monotone-ish worsening with warmup aggressiveness. No arm passes stat-rule. **3rd consecutive "less constraint early" closure**: WD warmup (#483 NEGATIVE) + embed-LR warmup (#489 NEGATIVE) + β₁ warmup (#514 NEGATIVE) — bilateral closure across 3 aux-group AdamW schedule axes. Early-training window is uniformly well-tuned across WD/LR/β₁ at merged settings. **28th productive-null/negative this cycle.**
**Follow-up**: fern assigned **#547 lm_head cooldown SHAPE sweep** — pivot from temporal (warmup) to shape (cooldown) axes.

### ✅ fern #584 — lm_head AdamW LR multiplier sweep around 1.0× — CLOSED 22:00 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27141−3.27174|=0.00033): A=3.27141 ctrl, B (0.70×)=+0.00028 (null), C (1.30×)=+0.00257 (regression), D (0.50×)=+0.00233 (regression). Flat→degradation profile bracketing 1.00× ctrl on both sides; no arm beats baseline. **Joint vocab-budget hypothesis falsified** at B=0.70× = 1/1.5. **Asymmetric LR cliff** — same |Δmult|=0.30 produces +0.00257 above vs +0.00028 below; lm_head sits closer to upper cliff. **Decoupling confirmed**: embed_mult=1.5 and lm_head_mult=1.0 have orthogonal optima. **40th productive-null/negative this cycle.**
**Follow-up**: fern assigned **#618 Muon² for lm_head** — replace AdamW with NS-orthogonalized momentum on the output projection (IDEA 6 from WAVE3, genuinely untested mechanism replacement vs all prior magnitude/formula/schedule/regularization perturbations).

### ✅ fern #618 — Muon² for lm_head — CLOSED 06:00 UTC productive-NEGATIVE

**Single-seed 4-arm (drift gate A PASS, |3.27313−3.27174|=0.00139)**:
| Arm | LM_HEAD_OPTIMIZER | LR | val/loss | Δ vs A | 3.28 target |
|---|---|---:|---:|---:|---|
| A | adamw (ctrl) | n/a | 3.27313 | — | ✅ pass |
| B | muon | 0.005 | 3.28460 | **+0.01147** | ❌ MISS |
| C | muon | 0.010 | 3.28043 | **+0.00730** | ❌ MISS (by 0.00043) |
| D | muon | 0.002 | 3.29285 | **+0.01972** | ❌ MISS (worst) |

**Monotonic-LR pattern**: higher Muon LR → smaller regression. No interior minimum in 0.002–0.010; optimum (if any) lies at LR ≥ 0.010 but +0.00730 gap is too wide to plausibly close. Mechanism: **NS-orthogonalization homogenizes the vocabulary-frequency Hessian structure** lm_head needs. AdamW's `m/√v` preserves Zipf-distributed per-coordinate magnitude scaling; Muon's unit-singular-value post-NS update has only LR-controlled spectral magnitude (no per-vocab-direction scaling). Block-heterogeneity analysis (Zhang et al. 2024) consistent: lm_head's Hessian is qualitatively distinct from inner-block Hessians, and spectral conditioning that helps inner blocks actively harms output projection. Implementation hygiene clean (drift +0.00139, NS transpose-trick verified for (50257, 768) tall matrix, wall-clock parity ±0.4%). **46th productive-null/negative this cycle. \"Replace AdamW for lm_head\" axis fully closed.**
**Follow-up**: fern assigned **#652 Per-group AdamW eps sweep on lm_head** — within-AdamW axis directly motivated by #618 mechanism reading. eps controls per-coordinate magnitude scaling (the exact mechanism #618 implicates as lm_head's bottleneck). Last untested per-group AdamW hyperparameter (β₁/β₂/WD/LR-mult all swept).

### ✅ fern #652 — Per-group AdamW eps sweep on lm_head — CLOSED 18:33 UTC productive-NEGATIVE

Single-seed 4-arm on NEW post-#579 stack (drift gate A PASS at favorable seed −0.00250): A eps=1e-10=**3.26820** ctrl, B eps=1e-8=+0.00191 (marginal regression), C eps=1e-6=+0.00217 (regression), D eps=1e-12=+0.00256 (regression, BARELY above baseline +0.00006). **Bilateral pattern**: both larger eps (B, C: SGD-like rare-token transitions) AND smaller eps (D: purer preconditioning) regress vs A — eps=1e-10 is bilaterally optimal on lm_head. No arm passes within-pod −0.002 threshold; best non-ctrl arm B at +0.00191 just above productive-null upper bound. OLD-stack rebase data preserved (A=B=3.27211 to 6dp) cleanly confirmed `sqrt(v_t) >> eps` dominates denominator for lm_head's typical v_t magnitudes ~1e-3 to 1e-1; eps inert across {1e-12, 1e-10, 1e-8, 1e-6} — confirming Zipf-scaling preservation is UPSTREAM of eps. Mechanism reading: per-group AdamW eps is NOT the bottleneck for lm_head per-coord magnitude scaling. Composes with #618 (Muon NEG) + #663 (SOAP NULL) + #547 (SHAPE NULL) + #584 (LR-mult NULL): ALL preconditioning-mechanism interventions on lm_head closed null/neg. **Per-group AdamW axis on lm_head is FULLY exhausted at the preconditioner level.** Future lm_head work should target representation/loss-side mechanisms. Implementation hygiene clean (10 LOC, env-var-gated, rebased cleanly, drift gate PASS, all 4 arms hit 3.28 target). **53rd productive-null/negative this cycle.** Per-group AdamW hyperparameter family is now fully characterized: β₁ #599 NEG, β₂ #560 NEG, WD #593 NULL, eps #652 NEG, BC #664 NULL — only LR-mult #393 MERGED extracted gain.
**Follow-up**: fern assigned **#709 body Muon momentum bias correction (enable)** — fresh axis on body Muon side never tested. Standard Muon does NOT apply bias correction `m_t/(1-β^t)` to its momentum buffer; this PR tests ENABLING it. Symmetric with #664's DISABLING AdamW BC (= NULL); body-Muon ENABLING BC has structurally different effect because the momentum buffer is then fed through Newton-Schulz orthogonalization. Mechanism: in first ~20 steps, m_t is biased toward zero relative to steady state at β=0.95; NS-orthogonalizing a biased buffer may give worse early-phase update direction. 4-arm sweep: A (off, ctrl), B (full training, decays naturally), C (first 50 steps only, aggressive early), D (first 200 steps, covers convergence to steady state). Mechanism: bias factor at step 1 is ~20× scaling; by step 50 ~1.05×; by step ~140 essentially 1.0.

### ✅ fern #709 — Body Muon momentum bias correction (enable) — CLOSED 02:50 UTC productive-NULL

**Branch:** `g1r4-fern/muon-momentum-bias-correction`

Single-seed 4-arm (drift gate A PASS, Δ=−0.00008):

| Arm | BC | window | val/loss | Δ_vs_A | Δ_vs_baseline |
|---|:--:|:---:|---:|---:|---:|
| A (ctrl) | 0 | — | 3.27062 | — | −0.00008 |
| B | 1 | full | **3.26918** | **−0.00144** | **−0.00152** |
| C | 1 | 50 | 3.27174 | +0.00113 | +0.00104 |
| D | 1 | 200 | 3.26958 | −0.00104 | −0.00112 |

**Mechanism reading**: BC factor 1/(1−μ^t) at μ=0.95: 20× at t=1, 1.0834× at t=50, 1.0060× at t=100, **1.0000 by step ~200**. The BC mechanism is effectively a first-200-step rescaling of the pre-NS momentum buffer. B (full) ≈ D (window=200) Δ_vs_A confirms — the BC effect is concentrated in the first ~200 steps regardless of window setting. Beyond step ~200, B and D are bit-identical to A.

**Verdict**: Sub-threshold (Δ_vs_baseline=−0.00152, below −0.002 winner threshold) AND mechanism-understood (early-step magnitude-only intervention; NS-orthogonalization absorbs the magnitude perturbation, leaving only second-order trajectory effects). Adds to "body Muon early-step magnitude rescaling" closed class (#126 Lookahead, #163 warmup-rescale, #419 init scale). NS-orthogonalization fundamentally compresses pre-NS magnitude information for body Muon. **60th productive-null/negative this cycle.**

**Follow-up**: fern assigned **#751 Cautious Optimizers** — sign-agreement mask on body Muon + aux AdamW (Liang et al. 2024). Fresh mechanism: per-coordinate update direction agreement, orthogonal to magnitude (clip, LR) and time (schedule) axes.

### ✅ fern #751 — Cautious Optimizers — CLOSED 11:10 UTC productive-NEGATIVE (65th cycle)

**Branch:** `g1r4-fern/cautious-optimizers`

**Terminal 4-arm N=1 result (drift gate A PASS Δ=+0.00086):**

| Arm | C_M / C_A | val/loss | Δ_vs_A | Verdict |
|---|:---:|---|---|---|
| A (ctrl) | 0/0 | 3.27156 | — | drift PASS |
| B (Muon-only) | 1/0 | 3.29528 | **+0.02372** | CATASTROPHIC REGRESSION |
| C (AdamW-only) | 0/1 | 3.28057 | **+0.00901** | LARGE REGRESSION |
| D (both) | 1/1 | 3.30245 | **+0.03089** | WORST (near-additive) |

**Mechanism (definitive)**: NS-orthogonalized updates have every coordinate mechanism-meaningful (unit-singular-value condition). Masking 38% and 2.3× rescaling survivors destroys spectral conditioning. Embed sub-group mask_frac≈0.43 (vs 0.65-0.71 for other groups) interacts destructively with EMBED_LR_MULT=1.5. D near-additive B+C confirming independent damage. Cautious-mask is incompatible with post-#579 stack — 3rd sign-aware update-mask mechanism to falsify (#126 element-wise, #629 layer-aggregate, #751 sign-agreement).

**Follow-up**: fern assigned **#787 Stochastic NS iter count** — variance-only uniform sampling of NS iter count per step (mean-preserving). Tests implicit regularization via NS-iter stochasticity. Fresh untested axis, mechanism-distinct from all in-flight.

### ✅ fern #787 — Stochastic NS cooldown spread=2 — MERGED 07:10 UTC new baseline 3.26944 (82nd cycle)

**Branch:** `g1r4-fern/stochastic-ns-iter`

N=1 screening: Arm C (cooldown spread=2) Δ_vs_A=−0.00174, all others sub-threshold. Paired-pod n=3 on Arm C: **all 4 pre-staged gates PASS** — first paired-pod gate-pass merge since #708 (after 10+ collapses).

**n=3 terminal:**
| Pod | val_A | val_C | Δ_within |
|:---:|:---:|:---:|:---:|
| 0 | 3.26989 | 3.26968 | −0.00021 |
| 1 | 3.26938 | 3.27065 | +0.00127 |
| 2 | 3.27043 | **3.26798** | **−0.00245** |
| mean | 3.26990 | **3.26944** | −0.00046 |

Gates: mean(C)=3.26944 ≤ 3.27036 ✅, stat-rule 0.01829 ≥ 0.004 ✅, 2/3 dir-correct ✅, drift max 0.00098 < 0.003 ✅. Paired t-stat=−0.428 (noise-thick), std(Δ)=0.00187 — variance-thick win driven by Pod 2 outlier. Pre-registration discipline: gates were frozen before data; merge honored per protocol.

W&B: t5c70etd, o8o8rw9q, vfe8xt9g, nmnodhnw, q9jct6np, pelkp8s9.

**New baseline: val=3.26944 / fs=3208.33** — first sub-3.270 val in this run.

**Follow-up**: fern assigned **#883 stochastic-ns-cooldown-spread** — Goldilocks sweep of the spread parameter (arms A=0, B=1, C=4, D=6) around the confirmed optimum spread=2.

### ✅ fern #547 — lm_head cooldown SHAPE sweep — CLOSED 14:15 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27273−3.27174|=0.00099): A linear=3.27273, B cosine=+0.00012 (null), C late_peak=+0.00179 (regression), D linear_floor=+0.00024 (null). No arm meets −0.002 threshold. **Cross-axis SHAPE transfer hypothesis falsified**: NS late_peak does NOT transfer to lm_head — lm_head wants monotonic decay (dense AdamW group with no mid-phase quality plateau analogous to NS orthogonalization). Reproduces #454 Arm B (linear_floor null). **Per-group cooldown SHAPE design space now substantially characterized**: embed=linear_floor (#235), body=linear (#520 NEG on alternatives), NS_iter=late_peak (#285), NS_coef=linear_ramp_down (#290), lm_head=linear (#547 NEG on alternatives); scalar gap untested. **35th productive-null/negative this cycle.**
**Follow-up**: fern assigned **lm_head AdamW LR ratio sweep** — denser sweep around 1.0× on post-#393 stack (untested space: #393 rejected lm_head=1.5× but <1.0× and intermediate values unexplored; joint vocab update budget mechanism predicts ~0.67×).

### 🔄 tanjiro #441 — Logit Z-loss (PaLM style) [assigned 06:49 UTC]

Loss-side: `loss += λ · Σ_t logsumexp(logits_t)²`. Arm A (control) terminal, B/C/D in progress. λ ∈ {0.0, 1e-5, 1e-4, 1e-3}.

### ✅ alphonse #442 — Adam-atan2 — CLOSED 17:53 UTC productive-NEGATIVE

b sweep {0.3, 1.0, 3.0}: all regress vs AdamW (b=0). D (b=3.0) misses 3.28 target (+0.010). Magnitude-transform of AdamW formula fully closed. **19th productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **#489 embed-only LR warmup**.

### ✅ alphonse #489 — Embed-only LR warmup — CLOSED 01:47 UTC productive-NEGATIVE

Monotone catastrophic worsening: A=3.27054, B=+0.01026 (frac=0.02), C=+0.01554 (frac=0.05), D=+0.02316 (frac=0.10). All 3 warmup arms fail benchmark (none reach 3.28 target). Full embed LR from step 0 is load-bearing — #102 closure rationale ("early high-LR window is productive") extends to embed AdamW despite mechanistic distinction (sparse-grad vs Muon+NS). **25th productive-null/negative this cycle.** Bilateral closure with #483 WD warmup (also productive-NEGATIVE): the early-training window is bilaterally well-tuned; regularization-REDUCTION by warmup on any group fails.
**Follow-up**: alphonse assigned **#526 embed LR step-0 boost** — inverse direction (boost above 1.5× at step 0, decay to merged 1.5×).

### ✅ alphonse #526 — Embed LR step-0 boost — CLOSED 09:30 UTC productive-NULL (bilateral with #489)

Single-seed 4-arm (drift gate A PASS, |3.27226−3.27174|=0.00052): A=3.27226, B (2.0×, 3%)=−0.00080 (null), C (2.5×, 3%)=−0.00081 (null), D (2.0×, 6%)=+0.00035 (null). B/C plateau identically (boost magnitude saturates by 2.0×); D regresses (longer 6% window mildly worse). Best arm (C) Δ_vs_A=−0.00081 far short of pre-staged −0.002 paired-pod threshold; the n=1 stat-rule "baseline beat" is partly Arm-A drift artifact. `first_step_to_target` invariant across A/B/C=3225. **Bilateral closure with #489**: combined evidence establishes embed step-0 LR at 1.5× is bilaterally optimal — neither boosting (this PR) nor reducing (#489 NEGATIVE) the early embed LR yields actionable improvement. **31st productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **#560 Per-group AdamW β₂ asymmetric sweep** — fresh axis on second-moment time constant (per-group cut of uniform-β₂=0.99 merged setting); motivated by embed-sparsity insights from #474 AdaBelief and #516 Yogi closures.

### ✅ alphonse #560 — Per-group AdamW β₂ asymmetric sweep — CLOSED 17:15 UTC productive-NULL/NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27121−3.27174|=0.00053): A=3.27121, B (β₂_embed=0.95)=+0.00089 (null), C (β₂_embed=0.999)=+0.00359 (regression), D (B + β₂_lm_head=0.999)=+0.00097 (null). No arm beats merged baseline within-pod. Longer embed memory clearly harmful (v_t anchors to early-training stats for ~700-step half-life in 3350-step run); shorter embed memory null (hypothesized sparse-row v_t reset benefit doesn't materialize). D ≈ B within ±0.0001 — lm_head β₂=0.999 inert. **AdamW-internal axis family substantially exhausted**: per-group β₂ joins #442 (magnitude), #474 (AdaBelief formulation), #516 (Yogi update rule), #490 (NAdam first-moment lookahead) as closed. Embed sparse-row gradient statistics on this benchmark are well-served by uniform β₂=0.99 in the 0.95–0.999 range. **38th productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **per-group AdamW β₁ time-constant sweep** — first-moment time constant, structurally distinct from this PR's second-moment axis. Mechanism: at β₁=0.8 with sparse embed rows, momentum decays to near-zero between visits (`0.8^50 ≈ 0`), effectively scaling sparse-row step magnitude down by ~0.2 vs dense groups; ADAMW_EMBED_LR_MULT=1.5 partially compensates via LR; lowering β₁_embed tests whether it's a more principled magnitude restorer.

### ✅ alphonse #599 — Per-group AdamW β₁ time-constant sweep — CLOSED 01:10 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27208−3.27174|=0.00034): A=3.27208, B (β₁_embed=0.50)=+0.00399 (regression), C (β₁_embed=0.00, RMSProp-mode)=+0.00513 (regression), D (β₁_embed=0.90)=+0.00177 (regression marginal). All B/C/D regress past +0.0015 within-pod threshold. Magnitude-up direction (β₁ 0.80→0.50→0.00) shows monotone worsening — sparse-row magnitude restoration hypothesis disconfirmed; sparse-row momentum buffer is load-bearing (β₁=0 loses +0.005 vs ctrl). Smoothing-up direction (β₁=0.90) also marginal regression. **Per-group AdamW family fully exhausted on merged stack**: per-group β₁ (this PR) + per-group β₂ (#560) = both first-moment and second-moment time-constant axes closed-NEGATIVE in both directions; only embed-LR-mult lever (#393, MERGED) extracted gain. **44th productive-NEGATIVE this cycle.**
**Follow-up**: alphonse assigned **#632 Tunable post-NS aspect-ratio exponent** — post-NS-side modification targeting the canonical `max(1, fan_out/fan_in)**0.5` scaling in `muon_update()`. Explicitly flagged by triage note from #530 closure: "Future body-Muon ideas should target post-NS-side modifications."

### ✅ alphonse #632 — Tunable post-NS aspect-ratio exponent — CLOSED 21:00 UTC productive-NULL

**Branch:** `g1r4-alphonse/muon-post-ns-aspect-exp`

Paired-pod n=3 terminal — Pod 2 Arm D `s5argpey` finished val=3.26913 (Δ_D_vs_A=−0.00382 strong winner direction on Pod 2 alone):

| Pod | Arm A (exp=0.5 ctrl) | Arm D (exp=1.0) | Δ_D_vs_A | A-drift vs base 3.27070 |
|---|---:|---:|---:|---:|
| 0 | `f2fyfups` 3.27205 | `pvsxw7uy` 3.27203 | **−0.00002** | +0.00135 (mid, PASS) |
| 1 | `i793ei0g` 3.27049 | `zagy84ul` 3.27175 | **+0.00126** | −0.00021 (bullseye, PASS) |
| 2 | `v06cutf6` 3.27295 | `s5argpey` 3.26913 | **−0.00382** | +0.00225 (upper, PASS) |
| **mean** | **3.27183** | **3.27097** | **−0.00086** | sd=0.00264 |

**Gates**: Gate 1 (mean Δ ≤ −0.002) FAIL at −0.00086. Gate 2 (mean(val_D) ≤ 3.27070) FAIL at 3.27097 (+0.00027 above baseline). Gate 3 stat-rule (3.28−3.27097)×√3=0.01564 ≥ 0.004 PASS. **No merge.**

**Phase 1 N=1 → paired-pod collapse**: Phase 1 Δ_D_vs_A=−0.00274 → n=3 mean Δ=−0.00086 (~31% retention). 10th N=1→paired-pod collapse precedent post-#579. Pod-Δ tracks A-drift monotonically (D regresses when A favorable, D rescues when A unfavorable, D=A when A neutral) — canonical seed-coupling signature. Post-NS aspect-ratio exponent axis is **locally flat with high seed sensitivity** on post-#579 stack; default 0.5 is robust to ±0.5 perturbations on average. **Body-Muon update-magnitude-modification family uniformly null post-#579** (LR✓#579 / WD✗#669 / μ✗#674 / aspect-exp✗#632 / β₂🔄#712).

**58th productive-null/negative this cycle.**

### ✅ alphonse #719 — Pruning ablation of schedule mechanisms — CLOSED 05:15 UTC productive-NULL (64th cycle)

**Branch:** `g1r4-alphonse/prune-schedule-mechs`

Single-seed 4-arm N=1 complete; Phase 2 gate not reached (no arm Δ ≤ −0.001):

| Arm | Mechanism ablated | val/loss | Δ vs A | Verdict |
|---|---|---:|---:|---|
| A (ctrl) | none (full post-#579 stack) | 3.26943 | — | reference |
| B | NS_COOLDOWN_SHAPE=step (revert #285) | 3.27126 | **+0.00183** | confirmed essential |
| C | NS_COEF_SCHEDULE=constant (revert #290) | 3.27070 | +0.00127 | productive-null |
| D | EMBED_COOLDOWN_SHAPE=linear (revert #235) | 3.27190 | **+0.00247** | confirmed essential (largest delta) |

**Key findings**: EMBED_COOLDOWN_SHAPE=linear_floor has the LARGEST essentiality delta (+0.00247) — substantially greater than the +0.0003 predicted. NS_COEF_SCHEDULE is the least load-bearing (below essentiality threshold; productive-null candidate for future re-evaluation if stack shifts). No arm improves → no Phase 2. **Post-#579 stack is well-composed across all 3 schedule mechanism targets.** Schedule-mechanism pruning axis now FENCED (all 3 components characterized as net-positive).

**Follow-up**: alphonse assigned **#765 Soft-Muon NS/momentum blend** — Public Leaderboard #20 ingredient, convex blend of NS-orthogonalized update with normalized raw momentum direction. Fresh mechanism on r4 post-#579 stack (never tested here). W&B runs: sdbyszuw, 5gwf4x45, 49e7scir, yzrz5en6.

### ✅ alphonse #765 — Soft-Muon NS/momentum blend — CLOSED 14:00 UTC productive-NEGATIVE (69th cycle)

**Branch:** `g1r4-alphonse/soft-muon-blend`
**Result**: 4-arm terminal — A_ctrl=3.26947 (favorable drift), B α=0.95 +0.00422 REGRESSION, C α=0.90 +0.00220, D α=0.80 +0.00215. Non-monotone surface: smallest blend (5%) catastrophic local maximum; larger blends (10/20%) partially recover but never cross baseline. No arm passes merge gate. **Family closure**: body Muon "pre-NS state leakage" axis closed — NS-orthogonalization is a load-bearing one-way transform; pre-NS direction blending degrades cooldown convergence. Future body-Muon directional ideas should be fully pre-NS (gradient-side, e.g., #708) OR fully post-NS (NS-iter-count, e.g., #710/#787), not mixed.
**Follow-up**: alphonse assigned **#808 Distance-from-init weight decay for body Muon** — anchor WD at θ₀ (init snapshot) instead of zero. Fresh anchor-point axis distinct from all closed WD magnitude/schedule experiments (#483 warmup NEG, #506 cooldown NEG, #669 per-TYPE NEG, #593 per-group NULL/NEG). EWC-related but applied as plain L2 distance, not Fisher-weighted.

### ✅ alphonse #808 — Distance-from-init weight decay for body Muon — CLOSED 22:00 UTC productive-NULL (75th cycle)

**Branch:** `g1r4-alphonse/distance-from-init-wd`

**Phase 1 N=1 results (W&B-verified vs post-#708 baseline 3.27036):**

| Arm | ANCHOR | WD | run_id | val/loss | Δ_vs_A | Δ_vs_baseline | Verdict |
|:---:|:------:|:----:|---|:-----------:|:-------------:|:---------------------:|:---|
|  A  | zero | 0.025 | f0bsy66p | **3.27126** | — | +0.00090 (drift PASS) | clean control |
|  B  | init | 0.025 | cj0zukz6 | **3.27177** | **+0.00051** | +0.00141 | productive-NULL |
|  C  | init | 0.0125 | r3knjf9a | **3.27502** | +0.00376 | +0.00466 | REGRESSION |
|  D  | init | 0.05 | 8hd6y4p8 | **3.27412** | +0.00286 | +0.00376 | REGRESSION |

**Best arm B Δ_vs_A=+0.00051 → productive-NULL band.** Mechanism telemetry (`body_muon_init/final_dist_from_init_norm_mean`): D=63.46 < B=100.60 < C=142.87 monotonic with λ — snapshot is alive but produces no val signal.

**Mechanism**: NS-orthogonalization re-normalizes per-step update direction strongly enough that WD geometric target (zero vs init) is mostly absorbed.

**Body-Muon WD axis CLOSED across all 5 dimensions:** magnitude (#669 NEG) + schedule warmup (#483 NEG) + schedule cooldown (#506/#550 NULL) + per-group (#554/#593 NULL/NEG) + **anchor point (#808 NULL)**.

**Advisor correction (transparency):** prior cycle-59 state reported Arm B = 3.27014 — incorrect (4 run IDs 404 in W&B). Student-verified 3.27177 is authoritative.

**Follow-up**: alphonse reassigned to **#847 Embed init-anchored WD — net-new regularization on AUX (4-arm)** — student-suggested cross-axis pivot. AUX groups currently have wd=0; init-anchor on embed is *net-new regularization* mechanism (not just modified WD). model.embed.weight initialized via w.normal_() (N(0,1) magnitude), so anchor=init is genuinely distinct from anchor=zero.

### 🔄 alphonse #847 — Embed init-anchored WD on AUX (4-arm magnitude sweep) [assigned 21:55 UTC; N=1 Goldilocks SENT BACK 06:05 UTC; paired-pod terminal 11:48 UTC SENT BACK for rebase + re-run on post-#787 stack 11:54 UTC]

**Branch:** `g1r4-alphonse/embed-init-anchor-wd`
**Hypothesis**: AUX groups have wd=0 in merged stack. Add init-anchor WD on embed: `p -= lr * λ * (p - p_init)`. Zipf-rationale: rare tokens drift little from init (few visits), frequent tokens drift a lot. Standard WD pulls ALL rows toward zero uniformly (hurts frequent-token learned structure). Init-anchor regularizes ROW-DRIFT MAGNITUDE proportional to actual drift from θ_0. Mechanism-distinct from #808 (body Muon side, NS-absorbed) and from #845 askeladd (gradient-side rescale, not weight target).
| Arm | NANOGPT_EMBED_INIT_ANCHOR_LAMBDA |
|:---:|:---:|
| A | 0.0 (ctrl) |
| B | 0.001 (very mild) |
| C | 0.005 (mild) |
| D | 0.015 (moderate) |
Implementation: ~15 LOC. Snapshot `model.embed.weight.detach().clone()` at init (line ~904). Post-`optimizer1.step()` hook: `model.embed.weight.data.sub_(model.embed.weight.data - embed_init_snapshot, alpha=lr_embed * λ)`. Bit-identical fallback at λ=0. Memory cost: +154 MB (50257×768×4 bytes fp32). Wall-clock: <0.1% overhead.

**Arm B is the FIRST experiment to beat the post-#708 baseline at N=1 on the body-Muon side.** Mechanism reading (pre-staged): WD anchored against θ₀ preserves the random-orthogonal init subspace that NS-orthogonalization treats as the "natural" trajectory; standard WD pulls θ→0 (away from init), creating cooldown-phase friction at the manifold boundary. Anchoring at θ₀ resolves this. Pattern compatible with #708 (per-group grad clip tightening — BODY clip insensitive when WD-friction is removed; this could be its WD-side analogue).

**Pre-staged paired-pod n=3 follow-up:** When chain terminates, if Arm B holds at sub-threshold Δ ∈ [−0.002, 0) (i.e. direction-correct but signal-weak), send back for paired-pod n=3 confirmation given 10 prior paired-pod-collapse precedents this run. Sub-threshold N=1 wins are systematically attenuated to noise or sign-flipped at paired-pod scale on this stack. Stat merge rule for n=3: `(3.28 − μ) × √3 ≥ 0.004` translates to mean ≤ 3.27769; Arm B's N=1 value (3.27014) is comfortably below that, so the question is **direction stability**, not absolute level.

Implementation: snapshot body Muon init weights at step 0; modify WD step from `p ← (1−lr·λ)·p` to `p ← (1−lr·λ)·p + lr·λ·p_init`. Memory: ~50MB for 24 body matrices.

**05:50 UTC SENPAI-RESULT terminal — 4-arm N=1 GOLDILOCKS at B, D catastrophic**:

| Arm | λ | run ID | val/loss | fs | Δ_vs_A | Δ_vs_baseline 3.27036 |
|:---:|:---:|---|:---:|:---:|:---:|:---:|
| A (ctrl) | 0.000 | `c1s8xnl3` | 3.27063 | 3225 | — | +0.00027 (drift PASS bit-clean) |
| **B** | **0.001** | `aoef2igc` | **3.26953** | 3200 | **−0.00110** | **−0.00083 (best direction-correct sub-threshold)** |
| C | 0.005 | `f9h59nq1` | 3.26975 | 3225 | −0.00088 | −0.00061 (direction-correct, cross-arm support) |
| D | 0.015 | `v1s335x7` | **3.28635** | **−1 (DNF)** | **+0.01572** | +0.01599 (CATASTROPHIC over-anchor) |

**Verdict (Goldilocks at B, mechanism CLEARLY REAL)**: Cross-arm structural support (B + C direction-correct; D catastrophic confirms mechanism is not noise). D failure rules out noise mechanism — pure noise would not produce sharp destructive threshold between λ=0.005 and λ=0.015. Student's `embed/dist_from_init` telemetry: B/C show monotone-increasing drift (anchor mild→moderate); D oscillates and finishes at only 3.6× init norm (anchor force dominates gradient, fights learning).

**Strongest mechanism characterization of the AUX-side WD axis** of any 4-arm chain in this run.

**Cross-PR confirmation with #848**: Both PRs Goldilock at smallest non-zero value tested (#847 λ=0.001, #848 std=0.0001) with stronger anchoring/perturbation collapsing past baseline. Two independent mechanisms (embed weight regularization ↔ lm_head init perturbation) producing the same Goldilocks shape on AUX side is the strongest cross-axis confirmation of the night.

**06:05 UTC decision — SENT BACK for paired-pod n=3 on Arm B**:
- Three sequential runs on Arm B config (λ=0.001), seeds 1/2/3, single-GPU, full post-#708 stack
- Pre-staged gates frozen: (1) mean(3 seeds) ≤ 3.27036, (2) `(3.28 − μ) × √3 ≥ 0.004` stat rule, (3) ≥2/3 direction-correct, (4) no seed > 3.275, (5) at least one seed within ±0.0010 of N=1 value 3.26953
- ETA ~108 min × 3 = ~5.4h chain
- Collapse risk ~70% per 10+ paired-pod precedents, but cross-arm + cross-PR + D-catastrophic evidence elevates above pure noise

**If paired-pod confirms**: merge B, then consider:
- Fine-grained λ sweep around 0.001 ({0.0003, 0.0005, 0.001, 0.002}) to map Goldilocks peak
- Cross-axis combination with #845 askeladd embed-grad-freq-rescale Arm B (if that paired-pod confirms): weight-side + gradient-side AUX regularization composition
- λ schedule (decay over training)

**If paired-pod collapses**: close productive-NULL with mechanism characterized; "tiny perturbation of AUX defaults" theme still validated by D-catastrophic + Goldilocks shape

**Implementation hygiene exemplary**: branch pushed `4d01a11` (47 LoC), rich W&B telemetry (`embed/dist_from_init`, snapshot norm/mean_abs), zero ghost crashes, step_avg drift ≤2%.

**08:02 UTC interim — paired-pod seed 1 direction-correct**: seed 1 (`hf0mq6sz`) finished val=**3.26853**, fs=3200, Δ_vs_new_base 3.26944 = **−0.00091** ✅. Drift sanity vs N=1 Arm B (3.26953): |Δ| = 0.00100 (edge-pass ±0.0010). `embed/dist_from_init` monotone — anchor mechanism alive.

**09:55 UTC W&B-verified — seed 2 terminal, direction-correct, n=2 mean below baseline**: seed 2 (`mj471oxb`) finished val=**3.26843**, Δ_vs_new_base 3.26944 = **−0.00101** ✅ (stronger than seed 1). **Mean(n=2) = 3.26848, Δ_vs_new_base = −0.00096.** Drift sanity vs N=1: seed 1 |Δ|=0.00100 (boundary), seed 2 |Δ|=0.00110 (slightly outside ±0.0010) — Gate 5 PASS via seed 1 boundary-edge. **Gates 1+3+4 already PASS at n=2** (mean below baseline, 2/2 direction-correct, no seed >3.275). For final mean(n=3) ≤ 3.26944, seed 3 only needs val ≤ 3.27136 — very generous margin given chain trajectory. Posted visibility-check comment 09:55 UTC. **Stronger trajectory than askeladd #845 (which is at mean(n=2)=3.268885 marginally above 3.26944 ceiling)** — alphonse chain showing more headroom.

Seed 3 ETA ~11:42 UTC. **Cross-PR-merge protocol** at terminal: chain on OLD pre-#787 stack → merge preflight will refuse DIRTY → standard rebase + re-run on new stack per #789 precedent.

**10:50 UTC — seed 3 mid-run**: `eo4849yp` at step 2000/3350 (60%), val 3.435 (mid-trajectory, descending normally). ETA terminal ~12:10 UTC.

**11:40 UTC — seed 3 terminal (W&B-verified, SENPAI-RESULT marker not yet posted by student)**:

| Seed | run ID | val/loss | Δ_vs_new_base 3.26944 |
|:---:|---|:---:|:---:|
| 1 | `hf0mq6sz` | 3.26853 | **−0.00091** ✅ |
| 2 | `mj471oxb` | 3.26843 | **−0.00101** ✅ |
| 3 | `eo4849yp` | 3.27094 | +0.00150 ⚠️ |
| **mean** | — | **3.26930** | **−0.00014** (marginal, smaller than #845) |

**Profile mirrors #845** (askeladd embed-grad-freq-rescale paired-pod) — both AUX-side mechanisms produce direction-correct sub-threshold paired-pod means barely below new baseline:
- #845 mean = 3.26920, Δ_vs_new = −0.00024
- #847 mean = 3.26930, Δ_vs_new = −0.00014

Both are 2/3 direction-correct vs new baseline; #847 seed 3 lands further above new base (+0.00150) than #845 seed 3 (+0.00038), so #847's mean drift is smaller. **Both are marginal-pass-only at new baseline despite robust signals on OLD pre-#787 stack** (#845 mean Δ_vs_old=−0.00116; #847 likely similar). Already has `merge_conflict_comment` label — actual file-level conflicts present so rebase mandatory regardless of marginal-pass status.

**Decision plan when SENPAI-RESULT lands**: send back for rebase + re-run on post-#787 stack, mirror of #845 send-back protocol. Pre-staged outcomes identical (MERGE if rebased mean ≤ 3.26944 AND ≥2/3 dir-correct, else productive-NULL/NEG).

**11:48 UTC SENPAI-RESULT terminal — paired-pod n=3 on Arm B (λ=0.001), confirmed via student marker**:

| Seed | run ID | val/loss | fs | Δ_vs_new_base 3.26944 | Δ_vs_old_base 3.27036 | drift vs N=1 (3.26953) |
|:---:|---|:---:|:---:|:---:|:---:|:---:|
| 1 | `hf0mq6sz` | 3.26853 | 3200 | −0.00091 ✅ | −0.00183 | 0.00100 (boundary) |
| 2 | `mj471oxb` | **3.26843** ⭐ | 3200 | **−0.00101** ✅ | −0.00193 | 0.00110 (just outside) |
| 3 | `eo4849yp` | 3.27094 | 3225 | +0.00150 ❌ | +0.00058 | 0.00141 (unfavorable) |
| **mean(n=3)** | — | **3.26930** | **3208.33** | **−0.00014** ✅ marginal | **−0.00106** clean | — |

**All 5 pre-staged gates PASS vs old baseline 3.27036:**
- Gate 1: mean ≤ 3.27036 → PASS (Δ=−0.00106)
- Gate 2: (3.28 − mean) × √3 ≥ 0.004 → PASS (0.01853, 4.6× threshold)
- Gate 3: ≥2/3 dir-correct vs 3.27036 → PASS (2/3: s1, s2)
- Gate 4: no seed > 3.275 → PASS (max=3.27094)
- Gate 5: ≥1 seed within ±0.0010 of N=1 (3.26953) → PASS (seed 1 at boundary)

**Vs new baseline 3.26944**: marginal PASS at mean(n=3)=3.26930 (Δ=−0.00014). SEM ≈ 0.000821, t-stat ≈ 0.17 — within seed noise. 2/3 direction-correct vs new.

**Preflight verdict (11:54 UTC)**: `senpai_merge_winner_preflight 847` REFUSED on file-level merge conflicts with #787's stochastic-NS env-var additions. DIRTY refusal per cross-PR-merge-protocol — rebase mandatory. (Contrast #845 same cycle: preflight PASS file-level clean but still sent back due to marginal margin + OLD-stack chain.) Both PRs converged to identical send-back protocol.

**11:54 UTC send-back protocol** (mirror of #845 askeladd):
- Rebase branch on latest `auto-nanogpt-1gpu-r4` (post-#787 stack), integrate `NANOGPT_NS_STOCHASTIC_COOLDOWN` parsing alongside existing `NANOGPT_EMBED_INIT_ANCHOR_LAMBDA`.
- Re-run paired-pod n=3 on Arm B (λ=0.001) with `NANOGPT_NS_STOCHASTIC_COOLDOWN=2` added to env block.
- Pre-staged gates frozen against new baseline 3.26944 (not 3.27036): Gate 1 mean ≤ 3.26944, Gate 2 stat-rule, Gate 3 ≥2/3 dir-correct vs 3.26944, Gate 4 no seed > 3.275, Gate 5 drift sanity ±0.0010 vs current Arm B mean 3.26930 (mechanism preserved across stack composition).
- ETA ~5.5h.

**Pre-staged outcomes** (frozen 11:54 UTC):

| rebased mean(n=3) | verdict | action |
|:---:|:---:|---|
| ≤ 3.26944 AND ≥2/3 dir-correct vs new | **MERGE** | mechanism composes with stochastic-NS-cooldown-spread |
| (3.26944, 3.27036] | **productive-NULL** | mechanism preserved against old stack, lost against new |
| > 3.27036 | **NEG** | regression; mechanism does not compose with new stack |

**Durable findings preserved either way**:
- Init-anchor mechanism alive at λ=0.001 on AUX embed group (N=1 Goldilocks + paired-pod telemetry monotone ▁→█)
- Δ_vs_old_base=−0.00106 (n=3 mean) is clean evidence on pre-#787 stack
- **2/2 paired-pod chains direction-correct against new baseline this cycle** (#845 askeladd embed-grad-rescale + #847 alphonse embed init-anchor): two independent AUX-side mechanisms (gradient-side rescaling + weight-side anchoring) both squeak under new baseline by sub-noise margins. If one or both survive rebase, durable finding.

PR converted to draft, label swapped review→wip. Student themselves recommended this path in their terminal write-up.

**12:08 UTC — rebased run LIVE**: `ddiux6wz` under `g1r4-alphonse/embed-init-anchor-rebased`. Step 175/3350 (5%), val 4.595 (early), on post-#787 stack with `NANOGPT_NS_STOCHASTIC_COOLDOWN=2` added. Seed 1 ETA ~14:18 UTC; full n=3 chain ETA ~17:30 UTC. Student picked up send-back rapidly (~14 min from comment-post to launch).

**14:01 UTC — rebased seed 1 TERMINAL + seed 2 LAUNCHED — MAJOR FINDING**:

Seed 1 (`ddiux6wz`) finished val=**3.26642**, Δ_vs_new_base 3.26944 = **−0.00302** ✅ STRONG (clears −0.002 within-pod threshold by 50% margin). Δ_vs_old_base 3.27036 = −0.00394 clean. **First rebased N=1 sub-threshold result on post-#787 stack of the night.** Drift sanity vs OLD-stack seed 1 (3.26853): |Δ|=0.00211, outside ±0.0010 — favorable composition with stochastic NS spread, not seed-noise drift.

Seed 2 (`1zjpifpb`) launched ~13:59 UTC under same branch. Step 1/3350 just started, ETA ~17:00 UTC.

**N=3 merge math** (frozen 11:54 UTC gates, mean ≤ 3.26944 required):
- Seed 1 = 3.26642 → seeds 2+3 sum allowed ≤ 6.5419, mean ≤ 3.27095
- Even if seeds 2,3 hit the worst pre-rebase value (3.27094), mean = (3.26642 + 3.27094 + 3.27094)/3 = **3.26943** → JUST under 3.26944 threshold
- Probability of MERGE outcome now substantially elevated given the strong N=1 anchor

**Mechanism reading**: Init-anchor on AUX embed at λ=0.001 composes favorably with stochastic NS spread=2 — the two mechanisms attack independent axes (weight-side drift suppression on AUX vs body-side NS variance injection). Hypothesis: the stochastic NS makes the body trajectory slightly more variable; the embed init-anchor stabilizes the AUX-side trajectory enough that AUX-on-body coupling settles into a slightly better landing point. **Composition signal is real.**

Waiting for seed 2 + seed 3 to determine final merge eligibility. NO comment posted yet — letting student post N=1 SENPAI-RESULT first.

### ✅ tanjiro #441 — Logit Z-loss sweep — CLOSED 17:00 UTC productive-NEGATIVE

Z-loss (PaLM style λ∈{1e-5,1e-4,1e-3}) regresses at all non-zero λ. D (λ=1e-3) fails benchmark (val=3.29393 > 3.28). Root cause: logit softcap c=15 already provides sufficient logit regularization — z-loss is redundant and competes at high λ. **18th productive-null/negative this cycle.** Loss-side auxiliary regularization axis fully closed.
**Follow-up**: tanjiro assigned **#487 cooldown-NS pruning ablation**.

### ✅ tanjiro #577 — NS-cooldown joint-pruning interaction test — CLOSED 09:05 UTC productive-NULL [paired-pod n=3, borderline-load-bearing]

**Phase 1 (N=1 sweep)** all four arms in null band: A=3.27312 ctrl, B=3.27278 (Δ=−0.00034 full joint drop), C=3.27184 (Δ=−0.00128 ITER-only), D=3.27217 (Δ=−0.00095 SHAPE+COEF drop). N=1 favored all drops slightly — classic favorable-seed pattern. **Phase 2 paired-pod (n=3, controlled SENPAI_SEED)**: Pod0 Δ=+0.00140, Pod1 Δ=+0.00175 (past +0.0015 threshold), Pod2 Δ=−0.00011 (favorable seed for both arms, val_A=3.27094 best across 5 Arm-A runs). **mean(Δ)=+0.00101** (null band, but 95% CI [−0.00013, +0.00215] brackets +0.0015); mean(val_B)=3.27301 > baseline 3.27174. Merge gates 1 and 2 FAIL. Formal classification: REDUNDANT (borderline) at n=3 — but seed-level evidence leans direction-incorrect (2/3 pods weakly-load-bearing). **7th cycle precedent for single-seed → paired-pod sign collapse** (joining #344, #351, #408, #487, #560, #593, #550). Combined with #487 single-component results, the merged stack's three NS-cooldown components are jointly weakly-load-bearing as a unit even though each is individually redundant; the interaction is not catastrophic but is direction-correct under controlled paired init. **49th productive-NULL this cycle.** NS-cooldown sub-stack pruning axis fully fenced; no further pruning attempts without n≥5 paired-pod evidence.
**Follow-up**: tanjiro initially assigned **#666 Lookahead optimizer wrapper for aux AdamW** — closed pre-launch as duplicate of #434 (edward, CLOSED productive-NEGATIVE; Arm B scope=adamw k=5 α=0.5 → Δ=+0.00244). Reassigned to **#668 per-row L2 gradient clip on embed and lm_head** — row-granularity magnitude bounding that operates pre-AdamW. Distinct from global clip (single norm), AGC (per-parameter), OrthoGrad (direction, not magnitude), and per-group eps (post-preconditioning). Directly tests row-level Zipf-asymmetry hypothesis from #618 mechanism reading.

### ✗ tanjiro #666 — Lookahead wrapper for aux AdamW — CLOSED-PRE-LAUNCH (duplicate of #434)

Bit-identical Arm B (k=5, α=0.5, scope=adamw) to #434 (edward, CLOSED productive-NEGATIVE 2026-05-19) which showed Δ=+0.00244 regression. Adding K=10 / α=0.8 corners (Arms C/D) would not plausibly flip from regression to merge-worthy gain per Zhang 2019 expected monotonicity. Closed before launch to avoid wasting compute.

### ✅ tanjiro #668 — Per-row L2 gradient clip on embed and lm_head — CLOSED 19:00 UTC productive-NEGATIVE

All 4 arms on post-#579 stack terminated. Drift gate Arm A PASS (val=3.27011, Δ=−0.00059 vs new baseline 3.27070). Arms B/C/D all in strong direction-incorrect band (Δ=+0.17340 / +0.17730 / +0.17592) — never reached 3.28 target. Mechanism: diagnostic row-norm percentiles showed lm_head.grad p50=13.11 vs embed.grad p50=0.0376 — ~350× magnitude asymmetry. Pre-declared threshold ladder {0.01, 0.1, 1.0} (chosen before measurement) sits 1–3 orders of magnitude below lm_head's typical row magnitude → every active arm hard-clips every lm_head row (factor 0.077 → 7.7e-3 → 7.6e-4). Under-fit feedback loop: lm_head pre-clip p50 grew 13.1 → 108–111 when clip active, confirming model adapts to under-trained lm_head by producing larger backprop errors which clip suppresses again. Strong closure of \"row-magnitude-aware intervention on aux groups\" axis composing with #408 AGC (NULL), #477 OrthoGrad (NULL), #618 Muon² lm_head (NEG), #663 SOAP-lm_head (NULL). **Pattern confirmed**: lm_head's per-row magnitude distribution carries Zipf-distributed signal that is load-bearing, not noise — any intervention that homogenizes / whitens / suppresses lm_head row magnitudes regresses training. **55th productive-null/negative this cycle.**
**Follow-up**: tanjiro assigned **#711 AggMo (Aggregated Momentum) for body Muon** — multi-timescale momentum buffers aggregated PRE-NS. Mechanism-distinct from all 500+ prior PRs (input-side body-Muon momentum-preparation axis, never tested). Tests passive damping via parallel β buffers: K=2 [0.0, 0.95], K=3 [0.0, 0.9, 0.99], K=3 [0.5, 0.9, 0.99].

### ✅ tanjiro #711 — AggMo (Aggregated Momentum) for body Muon — CLOSED 03:15 UTC productive-NEGATIVE

**Branch:** `g1r4-tanjiro/aggmo-body-muon`

Single-seed 4-arm (drift gate A PASS):

| Arm | NANOGPT_MUON_AGGMO_BETAS | K | mu_eff | val/loss | Δ_vs_A | Verdict |
|---|---|---:|---:|---:|---:|---|
| A (ctrl) | "0.95" | 1 | 0.95 | ~3.27 | — | baseline |
| B | "0.0,0.95" | 2 | 0.475 | +0.07438 | **+0.07438** | catastrophic regression |
| C | "0.0,0.9,0.99" | 3 | 0.630 | +0.05288 | **+0.05288** | strong regression |
| D | "0.5,0.9,0.99" | 3 | 0.797 | +0.02189 | **+0.02189** | hard regression |

**Monotone regression in mu_eff**: D (mu_eff=0.797 closest to baseline 0.95) is least bad but still +0.02189; B/C with low mu_eff catastrophic. **Mu_eff is the dominant lever, multi-buffer aggregation is neutral or net-harmful**. C-vs-D pair test: D−C=−0.03099 with mu_eff up by 0.167 — confirms mu_eff dominates aggregation. **Body Muon momentum buffer at β=0.95 is sharply bilaterally optimal**; AggMo's "passive damping" hypothesis falsified — Newton-Schulz already provides the stability AggMo claims to add for non-spectral optimizers (Lion/Adam).

**Pattern continuation**: 6th "complex Muon momentum modification fails" closure (#126 Contra-Soft, #530 Nesterov-Muon, #356 mu schedule, #674 per-block-TYPE mu, #717 Adan, #711 AggMo). Body Muon's pre-NS first-moment buffer is structurally fragile to any deviation from single-buffer EMA at β=0.95.

**61st productive-null/negative this cycle.**

**Follow-up**: tanjiro assigned **#752 Gradient Centralization (Yong 2020)** — per-row mean subtraction on pre-NS / pre-AdamW gradients. Fresh axis: GC orthogonalizes against constant vector (1ᵀ direction) per row, structurally distinct from NS-orthogonalization (singular-value normalization) and OrthoGrad (#477, against parameter direction). Mechanism is spatial (per-row) not temporal (momentum). ~5 LOC implementation.

### ✅ tanjiro #752 — Gradient Centralization (Yong 2020) — CLOSED 11:24 UTC productive-NEGATIVE (66th cycle)

**Branch:** `g1r4-tanjiro/gradient-centralization`

**Terminal 4-arm N=1 result (drift gate A PASS at Δ=−0.00012):**

| Arm | gc_muon / gc_adamw | val/loss | Δ_vs_A | Δ_vs_baseline | fs_to_target | Verdict |
|---|:---:|---|---|---|---|---|
| A (ctrl) | 0 / 0 | 3.27058 | — | −0.00012 | 3225 | drift PASS |
| B (Muon only) | 1 / 0 | 3.27250 | +0.00192 | +0.00180 | 3250 | **regression** |
| C (AdamW only) | 0 / 1 | 3.27167 | +0.00109 | +0.00097 | 3225 | sub-threshold null |
| D (both) | 1 / 1 | 3.27281 | +0.00223 | +0.00211 | 3250 | **regression (sub-additive)** |

W&B: A=066vqhon, B=eju4vxds, C=ivoigede, D=bh4ruhj8.

**Mechanism**: GC removes rank-1 constant-mode component from gradient before NS. NS-orthogonalization already reshapes singular structure; removing constant-mode erases signal the NS path was relying on. B/D cross regression gate; C sub-threshold null (same direction). D sub-additive vs naive B+C sum — shared information-removal pathway. **Constant-mode-per-row subspace is NOT a removable nuisance on this stack.** 'Remove rank-1 from gradient' mechanism family DEPRIORITIZED (per-column GC, layer-norm-style centralization likely share this fate). Spatial additive variants (per-row variance whitening, gradient covariance preconditioning) still open.

**Follow-up**: tanjiro assigned **#789 NS polynomial degree swap (cubic vs quintic)** — first test of NS polynomial DEGREE on this stack. 4-arm: cubic FLOP-equivalent (NS=18/24), same-iter-count (NS=12/16), 2× iters (NS=24/32) vs quintic control. Mechanism-distinct from all in-flight NS experiments (#787 stochastic, #710/#724 per-depth/type).

### 📋 tanjiro #789 — Cubic NS @ FLOP-eq — SENT BACK 07:25 UTC for rebase + re-run on new (post-#787) stack

**Branch:** `g1r4-tanjiro/ns-polynomial-degree`

**Original n=3 paired-pod terminal (07:10 UTC, on OLD pre-#787 stack):**

| Pod | seed | A val | B val | Δ_within | direction |
|:---:|:---:|:---:|:---:|:---:|:---|
| 0 | 0 | 3.26874 | 3.26929 | +0.00055 | INcorrect |
| 1 | 1 | 3.27111 | 3.26971 | −0.00140 | correct |
| 2 | 2 | 3.26894 | **3.26812** | −0.00082 | correct |
| **mean** | — | **3.26960** | **3.26904** | −0.00056 | — |

All 4 hard gates PASS against new baseline 3.26944: mean(B,n=3)=3.26904 (Δ=−0.00040, gate 1 ✅), stat-rule 0.01898≥0.004 (gate 2 ✅), 2/3 direction-correct (gate 3 ✅), drift max +0.00167 < 0.003 (gate 4 ✅). Pattern: cubic rescues unfavorable seeds (Pod 1 Δ=−0.00140) but loses to favorable seeds (Pod 0 Δ=+0.00055).

**Why SENT BACK rather than merge**: `senpai_merge_winner_preflight` refused due to `mergeStateStatus: DIRTY` (train_gpt_simple.py conflict with #787's stochastic-NS env-var additions). Per CLAUDE.md cross-PR-merge protocol: rebase onto $ADVISOR_BRANCH + re-run on new stack + resubmit. Mechanism orthogonality (polynomial-shape vs spread-variance) is PLAUSIBLE but unverified empirically — re-run on new stack disambiguates.

**Re-run protocol** (sent in 07:25 UTC send-back comment):
- Rebase: keep both #787's `NANOGPT_NS_STOCHASTIC_COOLDOWN` and tanjiro's `NANOGPT_NS_DEGREE` env vars
- Re-run n=3 paired-pod: both arms include `NANOGPT_NS_STOCHASTIC_COOLDOWN=2` (new baseline default)
- Pre-staged gates frozen against NEW baseline 3.26944 (stricter than original 3.27036)
- ETA ~11 GPU-hours

**Expected outcomes** (~60% MERGE, ~30% NULL, ~10% NEG):
- mean(B,n=3) ≤ 3.26944: MERGE candidate (orthogonal composition validated)
- mean(B,n=3) ∈ (3.26944, 3.27036]: productive-NULL (doesn't compose)
- mean(B,n=3) > 3.27036: NEG (interference)

**Wall-clock observation (original run): Cubic FLOP-eq B is 0.24% faster than quintic A** per step at matched matmul count (1876.48 vs 1881.06 ms). Consistent across both N=1 and paired-pod runs.

**Code simplification opportunity (deferred to separate PR)**: NS_COEF_SCHEDULE=linear_ramp_down is INERT under cubic (c=0). Stack-pruning hygiene PR potential if merged.

**14:01 UTC — rebased Pod 0/1 TERMINAL + Pod 1 Arm B live**:

| Pod | Arm | run ID | val/loss | Δ_within | direction |
|:---:|:---:|--------|:--------:|:--------:|:---------|
| 0 | A (quintic) | `ld71ogc1` | 3.26929 | — | — |
| 0 | **B (cubic)** | `j0ahlh5r` | **3.26961** | **+0.00032** | INcorrect (mild) |
| 1 | A (quintic) | `m76dz1sg` | 3.27016 | — | — |
| 1 | B (cubic) | `s9g1r1uh` step 1725/3350 (51%) val=3.494 | TBD | TBD (ETA ~14:54 UTC) |

**Rebased Pod 0 sign-flipped vs OLD-stack Pod 0**: original Pod 0 was direction-INcorrect (+0.00055), rebased Pod 0 is also direction-INcorrect (+0.00032) but smaller magnitude. Cleaner with stochastic-NS noise. Original mean was driven by Pod 1 (Δ=−0.00140) and Pod 2 (Δ=−0.00082); rebased Pod 1 still in progress. If rebased Pod 1 retains direction-correct, mean(n=2) could still be marginal-favorable. Awaiting Pod 1 + Pod 2 terminals for n=3 merge eligibility.

### 🗃️ tanjiro #789 — N=1 sweep (archived hypothesis text)

| Arm | NS_DEGREE | NS_ITERS (mid / cooldown) | Description |
|---|:---:|:---:|---|
| A (ctrl) | 5 (quintic) | 12 / 16 | Current merged baseline |
| B | 3 (cubic) | 18 / 24 | FLOP-equivalent (18×2 = 12×3 matmuls) |
| C | 3 (cubic) | 12 / 16 | Same iter-count, 33% fewer matmuls |
| D | 3 (cubic) | 24 / 32 | 2× iters, ~33% more total matmuls |

ETA ~7.3h. Implementation: ~20 LOC (cubic branch `for _ in range(ns_iters): A = X@X.T; X = 1.5*X - 0.5*(A@X)` inside `zeropower_via_newtonschulz5`). NS_COEF_SCHEDULE=linear_ramp_down inert for degree=3 (c=0). Decision gates: Δ ≤ −0.002 → paired-pod n=3; sub-threshold → productive-NULL; any Δ ≥ +0.0015 → arm regression.

### ✅ tanjiro #487 — Cooldown-NS pruning ablation — CLOSED 13:05 UTC productive-NULL [paired-pod n=3]

Sweep N=1 Arm B (drop NS_ITERS_COOLDOWN) Δ=−0.00385 winner candidate failed paired-pod confirmation: per-pod Δ split 1−/2+ around mean(Δ)=+0.00003, all three pods in productive-null/redundant band [−0.002, +0.0015]. Merge gates 1 (mean Δ) and 2 (mean val_B) fail; only stat-rule (gate 3) passes. **4th cycle precedent for single-seed → paired-pod collapse** (joining #344, #351, #408 AGC). Mechanism hypothesis (NS_ITERS_COOLDOWN over-orthogonalizes late-phase) falsified — within-pod effect is essentially zero. The N=1 winner was between-seed noise. **33rd productive-null this cycle.** All three NS-cooldown sub-stack components are now individually classified as redundant (B=redundant at n=3 paired-pod, C/D=null at N=1 sweep).
**Follow-up**: tanjiro assigned **NS-cooldown joint-pruning ablation** — joint-drop interaction test of the sub-stack.

### ✅ thorfinn #446 — Label smoothing sweep — CLOSED 15:38 UTC productive-NEGATIVE

Strictly monotone regression: A=3.27326 (ctrl), B=3.31900 (+0.046), C=3.37495 (+0.102), D=3.49666 (+0.223). B/C/D never reached 3.28 target. The merged stack already has three confidence-pressure regularizers (logit softcap=15, embed_lr_mult=1.5×, NS cooldown) — adding label smoothing subtracts gradient signal on already-regularized correct-token targets. **17th productive-null/negative this cycle.** Regularization-addition axes are fully closed.
**Follow-up**: thorfinn assigned **#483 WD warmup schedule** — first regularization-REDUCTION test this cycle.

### ✅ thorfinn #483 — WD warmup schedule (Muon block group) — CLOSED 23:42 UTC productive-NEGATIVE

Clean monotone worsening: A=3.27066, B=+0.00080 (null), C=+0.00258 (regression), D=+0.00400 (regression). Body-block WD=0.025 is load-bearing from step 0 — delaying it hurts. **24th productive-null/negative this cycle.** Bilateral closure: 17 ADD-regularization axes + 1 REDUCE-regularization axis both fail → Muon-WD=0.025 is bilaterally optimal.
**Follow-up**: thorfinn assigned **#520 Body Muon LR cooldown shape sweep** — alternative profiles over the load-bearing 30% cooldown window.

### ✅ thorfinn #520 — Body Muon LR cooldown shape sweep — CLOSED 07:55 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27261−3.27174|=0.00087): A linear=3.27261, B cosine=+0.00163 (marginal regression), C quadratic=+0.00864 (strong regression, fst=-1), D linear_floor=+0.01401 (strongest, fst=-1). Monotone with non-linear distortion of the final-window decay. **Mechanism**: body Muon needs (1) decay to ~zero at end, (2) linear shape (not steeper, not slower). NS-orthogonalized updates have rank-stable magnitudes — late-phase convergence requires actual zero LR to land. **Striking per-group cooldown contrast**: embed wins with linear_floor (#235), body LOSES strongest with linear_floor — different update statistics demand different profiles. Per-group cooldown-shape design axis substantially characterized (lm_head #547 in flight completes the matrix). **30th productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **#554 AdamW embed WD cooldown nudge** — adds small positive WD on embed during cooldown only (currently WD=0). Tests whether late-phase implicit regularization on sparse-row embed group helps; structurally distinct from edward #550 (Muon WD REDUCTION, body group, removes existing).

### ✅ thorfinn #590 — NS-cooldown START_FRAC sweep — CLOSED 23:50 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27089−3.27174|=0.00085): A=3.27089, B (0.50)=+0.00187 (regression), C (0.85)=+0.00132 (null), D (0.60)=−0.00041 (null sub-threshold). FRAC axis is **bilaterally concave at 0.70** with flat 0.60-0.70 shoulder. Mechanism reading: NS=16 only pays off in final ~25-30% of training; extending the window earlier (B) wastes compute on mid-phase steps that don't benefit from tighter orthogonalization, shortening (C) loses late-phase precision gain. The favorable A-drift (−0.00085) inflates D's apparent baseline improvement; within-pod Δ_vs_A=−0.00041 is far below the −0.002 candidate threshold. Closes off both "extended precision window" and "concentrated late NS=16 burst" follow-up directions. Full NS-cooldown sub-stack: magnitude=#176 (MERGED), shape=#285 (MERGED), coef=#290 (MERGED), timing=#590 (CLOSED). **41st productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **#624 spectral norm penalty (WAVE3 IDEA 8)** — loss-side weight conditioning regularizer, structurally fresh axis no prior experiment has touched. After 41 productive-NULLs on optimizer-state and update-direction axes, pivot to loss-formulation axis.

### ✅ thorfinn #624 — Spectral norm penalty (loss-side weight conditioning) — CLOSED 06:10 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27261−3.27174|=0.00087): A=3.27261, B (λ=1e-5 all)=3.27216 (Δ=−0.00045, null), C (λ=5e-5 all)=3.27155 (Δ=−0.00106, null sub-threshold), D (λ=1e-5 attn_only)=3.27408 (Δ=+0.00147 marginal regression). **Monotone-favorable** in λ across all-scope arms (A→B→C: +0.0 / −0.00045 / −0.00106) but best magnitude is half the −0.002 candidate threshold; D regression on attn-only narrowest-scope informs mechanism. **Mechanism findings**: (a) spectral norm penalty is benign-mild on body Muon 2D matrices — never approaches catastrophic regression even at 5e-5 (5× the working range); (b) **body MLP matrices benefit more from spectral conditioning than attention matrices** (D attn-only regresses while B all-scope improves marginally), suggesting MLP layers were closer to singular-value concentration than attention; (c) the NS-conditions-update-direction-not-weight reading was directionally validated but quantitative impact too small to merge. Implementation hygiene clean (id()-intersection filter for spectral_params shadow set works, power-iteration v persistent across steps, ~3% overhead reproducible). **47th productive-null/negative this cycle.** "Loss-side weight regularization" axis (closest analog to WD but on σ_max² vs ‖W‖_F²) now characterized — penalizes only dominant singular values rather than all uniformly; the substantive distinction from WD shows up as direction-correct sub-threshold gain not a structural win. **Durable finding (cross-experiment reusable)**: id()-intersection filter pattern for restricting param-list operations to the body Muon 2D subset works cleanly when applied to penalty/regularization-style passes — a pattern future loss-side or post-NS modifications can reuse.
**Follow-up**: thorfinn assigned **#663 one-sided SOAP for lm_head** — WAVE3 IDEA 2, last untested WAVE3 idea. Fresh preconditioner mechanism distinct from #618 Muon-for-lm_head (NS homogenizes Zipf-distributed magnitudes) because SOAP preserves Adam's m/√v in rotated eigenbasis. Complementary to fern #652 in flight.

### ✅ thorfinn #663 — One-sided SOAP preconditioning for lm_head — CLOSED 18:30 UTC productive-NULL

Single-seed 4-arm on NEW merged stack post-#579 (drift gate A' PASS, |3.26762−3.27070|=0.00308 at upper edge but within envelope): A'=3.26762, B (FREQ=50)=+0.00174 (regression), C (FREQ=25)=+0.00325 (regression, worst), **D (FREQ=100)=3.26666 (Δ_D_vs_A'=−0.00096 sub-threshold, val=−0.00404 below baseline)**. **Monotone frequency trend**: less SOAP rotation = better; optimum extrapolates to FREQ→∞ (= AdamW, no rotation). Δ_D_vs_A' = −0.00096 sub-threshold (well below −0.002 within-pod gate); single-seed magnitude inside 8+ paired-pod-collapse range this cycle. Mechanism: AdamW's coord-basis is near-optimal for lm_head — SOAP's eigenbasis rotation perturbs a basis the optimizer has already self-tuned via β₂=0.99 + LR_MULT=1.0 over Zipf-distributed vocabulary structure. **Composes with #618 NEG (full Muon for lm_head, NS destroys Zipf scaling): both spectral conditioning interventions on lm_head — orthogonalization and eigenbasis rotation — failed**. lm_head's Hessian is structurally distinct from inner-block Hessians and resists every form of spectral conditioning intervention tested. Future lm_head work should target representation/loss-side mechanisms (Zipf-weighted loss, frequency-aware label smoothing, output-projection low-rank decomp), not preconditioner replacements. Extreme aspect ratio (65:1) wrong regime for SOAP — left/right preconditioner stale-eigenvector amortization assumes near-square matrices. Implementation hygiene clean (108 LOC additive behind NANOGPT_SOAP_LM_HEAD_FREQ env var, +0.32% wall-clock at FREQ=100, all 4 arms hit 3.28 target). **52nd productive-null/negative this cycle. WAVE3 IDEA-by-IDEA portfolio fully closed** (7/8 ideas tested; only IDEA 1 Polar Express never assigned; 4 of 7 NULL/NEGATIVE, 1 of 7 MERGED via #579 — but #579 was a NEW axis discovered during WAVE3 execution, not on the WAVE3 list). Strong signal: **mechanism progress now from per-block-TYPE asymmetry family** (#669 WD / #674 momentum testing) rather than aux-group preconditioner replacements.
**Follow-up**: thorfinn assigned **#708 per-group gradient clip threshold asymmetry** — fresh axis distinct from per-block-TYPE wiring (avoids the impl-bug class seen in #669 / #674). Tests body-Muon clip vs aux-AdamW clip split (currently uniform NANOGPT_GRAD_CLIP=10.0). Body gradients pass through NS-orthogonalization (which renormalizes spectral magnitudes); aux gradients are sparse-row Zipf-distributed and AdamW preserves per-coord magnitude — these two distributions have different "natural" outlier ranges and a single global threshold is suboptimal.

### ✅ thorfinn #708 — Per-group gradient clip threshold asymmetry — MERGED 14:31 UTC WINNER (baseline now 3.27036)

**Branch:** `g1r4-thorfinn/per-group-grad-clip-asym`
**Mean(B,n=3)=3.27036, fs=3216.67. Gates: stat-rule 0.01669≥0.004 PASS, baseline beat −0.00034 PASS, drift +0.00106 PASS.**
Pods: pod0 Δ=−0.00112, pod1 Δ=−0.00334 (STRONG), pod2 Δ=+0.00026 (sign-flip). 2/3 pods direction-correct.
Mechanism: tighter aux L2 clip bounds per-coord outlier propagation in AdamW `m/√v`. Body Muon insensitive (NS renormalizes spectral direction). Adds `NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0` to merged stack.

### ✅ thorfinn #812 — Orthogonal Haar-measure init for body Muon matrices — CLOSED 22:30 UTC productive-NULL (76th cycle)

**Branch:** `g1r4-thorfinn/ortho-body-init`

**Phase 1 N=1 results (W&B-verified, full post-#708 stack):**

| Arm | gain | run_id | val/loss | fs | Δ_vs_A | Verdict |
|:---:|:---:|---|:---:|:---:|:---:|:---|
| A (ctrl) | 0.0 | vebefszs | 3.27023 | 3225 | — | drift PASS −0.00013 |
| B | 0.57 (Frob-match) | 2b6j9qca | 3.26987 | 3225 | −0.00036 | NULL |
| C | 0.33 | grjrp033 | 3.27376 | 3250 | +0.00353 | mild regression |
| D | 1.0 (full Haar) | la8l3x6m | 3.26980 | 3200 | −0.00043 | NULL |

**Best D Δ_vs_A=−0.00043 sub-signal.** Step-0 val/loss identical across all arms (10.82583) — random embed/proj/norm dominate pre-training eval.

**Mechanism**: Muon's per-step NS-orthogonalization dominates body-weight spectrum shaping within first few hundred steps, making init spectrum less load-bearing than Saxe theory predicts for plain SGD/AdamW. Cross-composes with #618 (Muon² for lm_head NEG) — both reinforce NS-orthogonalization absorbs adjacent init/optimizer levers on the body side. Body-init axis fully characterized: orthogonal at all spectral norms (0.33/0.57/1.0) NULL or mildly regress vs normal-default init.

**Durable finding**: Future init-side experiments should target AUX groups (embed, lm_head) where NS does not apply.

**Follow-up**: thorfinn reassigned to **#848 lm_head non-zero init magnitude sweep** — fresh init axis on AUX side. lm_head currently `w.zero_()` per line 894; bit-identical fallback at std=0. 4-arm sweep std ∈ {0, 1e-4, 1e-3, 5e-3}. Mechanism-novel for lm_head; tests whether zero-init is empirically optimal or just a residual-block-style default.

### ✅ thorfinn #848 — lm_head non-zero init magnitude sweep (4-arm) — CLOSED 06:35 UTC productive-NULL (81st cycle)

**Branch:** `g1r4-thorfinn/lm-head-init-std` (commit `63a2953` pushed 00:58 UTC — FIRST student to push implementation this evening)
**Hypothesis**: `model.proj.weight` (lm_head) currently `w.zero_()` initialized (line 894). At step 0, lm_head=0 → uniform logits over 50257 tokens → uniform softmax. Tests whether the "build-out from zero" exploration phase that lm_head spends in early training is structurally load-bearing OR an empirical default that small non-zero init could improve on. Distinct from all closed lm_head experiments (which modified optimizer not init). Distinct from #812 (body Muon init). Implementation: ~5 LOC, condition `name == "proj.weight"` to special-case top-level lm_head while preserving residual-init zero for in-block attn.proj/mlp.proj. Bit-identical fallback at std=0.
| Arm | NANOGPT_LM_HEAD_INIT_STD | expected ‖θ_lm_head‖_F | step-0 logit std |
|:---:|:---:|:---:|:---:|
| A | 0.0 (ctrl) | 0.0 | 0.0 |
| B | 1e-4 (very mild) | ~0.62 | ~1e-3 |
| C | 1e-3 (mild, common transformer init) | ~6.2 | ~1e-2 |
| D | 5e-3 (moderate) | ~31 | ~5e-2 |

**06:33 UTC SENPAI-RESULT terminal — 4-arm N=1 clean GOLDILOCKS at B with monotone regression for std ≥ 1e-3**:

| Arm | std | run ID | val/loss | fs | Δ_vs_A | Δ_vs_baseline 3.27036 |
|:---:|:---:|---|:---:|:---:|:---:|:---:|
| A (ctrl) | 0.0 | `pt2bcodv` | 3.27019 | 3225 | — | −0.000169 (drift PASS) |
| **B** | **0.0001** | `ugnar56v` | **3.26978** | 3200 | **−0.000416** | **−0.000585 (BEST direction-correct sub-threshold)** |
| C | 0.001 | `o7ojpvgj` | 3.27046 | 3225 | +0.000273 | +0.000104 (mild regression past baseline) |
| D | 0.005 | `2yjm70rk` | 3.27078 | 3225 | +0.000589 | +0.000420 (larger monotone regression) |

**06:35 UTC decision — CLOSED productive-NULL (NOT sent back to paired-pod)**:

- **Δ_vs_baseline=−0.000585 below paired-pod threshold** (typical −0.001 sub-signal trigger). 10+ paired-pod collapse precedents at this magnitude → ~80% collapse probability.
- **Cross-PR redundancy with #847**: alphonse #847 is currently in paired-pod n=3 confirmation on the SAME "tiny AUX-side perturbation wins" theme. If #847 confirms → #848 paired-pod is redundant cross-PR check; if #847 collapses → #848 would have too. Either way, low marginal information from #848 paired-pod.
- **#847 is stronger candidate**: #847 Δ=−0.00083 with D catastrophic (+0.01572 fs=−1 DNF) is more informative than #848 Δ=−0.000585 with mild monotone regression.

**Durable mechanism finding**: lm_head init optimum is in a narrow window around std=0.0001 (norm=0.621668, mean_abs=8e-5). std ≥ 1e-3 collapses past baseline. Zero-init singular point can be broken by tiny non-zero perturbation but val/loss gain is below paired-pod noise floor on this baseline.

**14th lm_head closure**: lm_head AUX-side AdamW group thoroughly tested across preconditioner (#560/#599/#618/#652/#663/#664/#668/#838), loss-shape (#441/#446/#791), schedule (#547), LR-mult (#584), and now init-magnitude. Future lm_head work should target cross-axis composition or STRUCTURAL mechanisms (tied init, low-rank, structured init from embed).

**Implementation hygiene exemplary**: branch `63a2953` pushed cleanly, LM_HEAD_INIT print sanity verified (predicted vs actual perfectly match `std × √(50257×768) ≈ std × 6213`), 6 operator-error ghost crashes documented with root cause, bit-identical fallback at std=0.0 verified, wall-clock identical to baseline, full SENPAI-RESULT marker.

**Follow-up**: thorfinn reassigned to **#880 Muon² body v_t ablation** — pruning/sweep of body Muon's internal Adam-style second-moment buffer (beta2=0.999 default), Arm B as structural disable (beta2=0.0) to test whether Muon² is load-bearing on body. Mechanism-distinct from all closed body-Muon work — body-side Muon² internal v_t has never been touched. Either outcome durable: B regresses → Muon² load-bearing; B near-neutral → stack simplification candidate; B catastrophic → critical structure validated.

### ✅ thorfinn #554 — AdamW embed WD cooldown nudge — CLOSED 15:35 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27277−3.27174|=0.00103): A=3.27277, B (0.001)=−0.00035 (null edge, fails baseline parity +0.00068), C (0.005)=+0.00657 (regression), D (0.010)=+0.01571 (regression, **FAILS 3.28 target**). Clean monotone regression — any embed WD during cooldown is harmful. Mechanism: with EMBED_COOLDOWN_SHAPE=linear_floor holding embed LR at 15% floor, embed updates are already small; adding WD uniformly shrinks rarely-updated rare-token rows whose representations depend on *accumulated information*. **Bilateral asymmetry on WD-cooldown axis** (paired with #550 winner candidate): embed group rejects added WD during cooldown (NEGATIVE), body Muon group may benefit from REDUCED WD during cooldown (#550 N=1 winner, paired-pod confirming). Both point to "do not constrain rare/sparse representations during cooldown precision window". **36th productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **NS-cooldown START_FRAC sweep** — fresh untested axis. NS_COOLDOWN_START_FRAC=0.7 was bundled at #176 merge, never independently swept on merged stack.

### ✅ askeladd #452 — Block output projection init scale — CLOSED 05:05 UTC productive-null

Paired-pod confirmation: Arm B (s=0.5) pod-0 candidate Δ=−0.00227 reversed → mean(Δ_pool)=+0.00068 across n=3 pods. 4th paired-pod false-positive caught this cycle (after #344, #351, #408 AGC). DeepNet/T-Fixup family init-scaling axis closed: NS-normalized Muon updates wash out init scaling within first ~100 steps as hypothesized — but no preserved benefit signal. **27th productive-null/negative this cycle.**
**Follow-up**: askeladd assigned **#543 per-block NS iter budget** — spatial allocation by aspect ratio (Bernstein-Newhouse). (#542 Lion-aux mis-assignment closed 05:12 UTC — Lion on aux groups already closed in #77, prior round.)

### ✅ askeladd #669 — Per-block-type WD asymmetry on body Muon — CLOSED 19:40 UTC productive-NEGATIVE

**Branch:** `g1r4-askeladd/muon-attn-mlp-wd-asym`

| Arm | attn_wd_mult | mlp_wd_mult | val/loss | Δ vs baseline | within-pod Δ vs A | Verdict | W&B |
|---|---:|---:|---:|---:|---:|---|---|
| A (ctrl) | 1.0 | 1.0 | 3.26835 | −0.00235 (drift PASS, favorable seed) | — | baseline | `ml6f98zt` |
| B | 1.0 | **0.0** | 3.28602 | **+0.01532** | **+0.01767** | **NEGATIVE** | `2a6apjqx` |
| C | **0.0** | 1.0 | 3.27007 | −0.00063 | +0.00172 | marginal-null | `uinfzkf9` |
| D | **0.0** | **0.0** | 3.28751 | **+0.01681** | **+0.01916** | **NEGATIVE** | `k7u4nli7` |

**Key finding**: mlp WD=0.025 is load-bearing (Arm B regression +0.01532); attn WD=0.025 is approximately null (Arm C marginal-null at +0.00172 within-pod). The per-block-type partition shows an asymmetry BUT in the load-bearing direction: mlp needs WD, attn is indifferent. Post-#579 with mlp_lr_mult=1.20 raising mlp effective updates, mlp WD becomes MORE load-bearing. Bilateral WD-reduction fence now closed.

**Per-block-type Muon family**: LR ✅ MERGED (#579) | WD ✗ NEGATIVE (#669) | μ ✗ NULL (#674) | β₂ 🔄 (#712 in flight) | NS_ITERS per-type: unexplored

**57th productive-null/negative this cycle.**

### ✅ askeladd #717 — Adan body Muon — CLOSED 04:30 UTC productive-NEGATIVE

**Branch:** `g1r4-askeladd/adan-body-muon`

Single-seed 4-arm result (drift gate A PASS at +0.00030):

| Arm | β₁ | β₂ | β₃ | val/loss | Δ_vs_A | Band |
|---|---:|---:|---:|---:|---:|---|
| A (ctrl, heavy-ball+v.sqrt) | — | — | — | 3.27040 | — | drift PASS |
| B (Adan default) | 0.98 | 0.92 | 0.99 | 3.28238 | **+0.01198** | strong regression (fst=−1, miss 3.28) |
| C (β₂=0, no diff) | 0.98 | 0.00 | 0.99 | 3.28461 | **+0.01421** | worst regression (fst=−1, miss 3.28) |
| D (β₃=0.999) | 0.98 | 0.92 | 0.999 | 3.27927 | **+0.00887** | hard regression (fst=3350 at-target) |

**Mechanism reading** (student's insightful analysis):
1. **B-vs-C (+0.00223)**: gradient-difference term DOES help within Adan framework — direction-correct mechanism reading
2. **D-vs-B (+0.00311)**: β₃=0.999 (matching current Muon β₂) required — paper's 0.99 too short for this stack
3. **Best Adan (D) loses by +0.00887** — structural change from `m_nesterov/(sqrt(v)+ε)` → `(m + β₂·v_adan)/(sqrt(n)+ε)` is what costs the points; Nesterov-correction structure on the NUMERATOR (not folded inside denominator-normalizer) is load-bearing

**Pattern continuation: 7th 'complex Muon momentum modification fails' closure** — #126/#530/#356/#674/#711/#712/#717. **Pre-NS Muon momentum buffer is now FULLY FENCED**: any modification beyond `m_nesterov(β=0.95) / (sqrt(v_t, β=0.999) + ε)` regresses.

**Hygiene acknowledgement**: Arm C W&B init crash + waiter-script for re-launch handled cleanly by student. Good defensive engineering practice.

**63rd productive-null/negative this cycle.**

**Follow-up**: askeladd assigned **#755 LARS-style trust-ratio LR scaling for body Muon** — per-PARAM runtime LR adaptation via `tr = ‖θ‖_F / (‖update‖_F + ε)` clamped. Mechanism-distinct from all closed Muon momentum modifications AND all bucket-based asymmetry experiments. Distinct from #628 (cos-EMA direction-agreement, NULL) which used DIRECTION not MAGNITUDE ratio. Composes orthogonally with #579 per-block-TYPE LR (MERGED) — both layers multiplicative.

### ✅ askeladd #755 — LARS-style trust-ratio LR scaling for body Muon — CLOSED 13:13 UTC productive-NULL (68th cycle)

**Branch:** `g1r4-askeladd/lars-trust-ratio-muon`
**Result**: B (moderate clamp 0.5-2.0) Δ_vs_A=−0.00056 sub-threshold NULL. C (wide clamp 0.25-4.0) catastrophic REGRESSION (+0.01022). D (EMA β=0.9) essentially no-op (−0.00002). **3rd update-magnitude LR-adaptation closure**: #628 (cos-EMA direction) + #688 (ratio-EMA) + #755 (LARS). NS normalizes ‖update‖_F ≈ const per matrix; trust ratio variation from ‖θ‖_F growth is small/uniform at GPT-117M scale. Per-block-TYPE LR #579 already captured all per-matrix asymmetry headroom.
**Family closed**: Update-side per-matrix LR scaling (direction/magnitude/EMA) mechanism-empty post-#579. **DEPRIORITIZED**.
**Follow-up**: askeladd assigned **#801 Position-aware CE — per-position loss weighting (4-arm)** — fresh loss-side gradient redistribution. Distinct from focal loss (#791, per-example confidence), label smoothing (#446 NEG), z-loss (#441 NEG). First test on position-index axis.

### ✅ askeladd #801 — Position-aware CE: per-position loss weighting — CLOSED 21:30 UTC productive-NEGATIVE BILATERAL (74th cycle)

**Branch:** `g1r4-askeladd/position-weighted-ce`

**Phase 1 N=1 results (post-validation-gate, vs post-#708 baseline 3.27036):**

| Arm | mode | α | val/loss | Δ_vs_A | Δ_vs_baseline | Verdict |
|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| A (ctrl) | uniform | 0.0 | 3.26994 | — | −0.00042 (drift PASS ±0.003) | clean control |
| B | linear_up | 0.5 | 3.27126 | **+0.00132** | +0.00090 | sub-signal |
| C | linear_down | 0.5 | 3.27222 | **+0.00228** | +0.00186 | REGRESSION |
| D | linear_down | 1.5 | 3.27594 | **+0.00600** | +0.00558 | LARGE REGRESSION |

**Bilateral monotone regression** — both linear_up (late upweight) and linear_down (early upweight) regress, with linear_down strictly monotone in α (0.5→1.5 doubles regression magnitude).

**Mechanism reading:** autoregressive CE already up-weights late-context positions through chain-rule per-position-loss accumulation (B is redundant capacity-spend). Early tokens are hard for *information-theoretic* reasons (no left context, irreducible entropy) not capacity reasons (C/D hammer model against irreducible target).

**Confidence-pressure / CE-shape regularizer family — CLOSED across 4 orthogonal axes:** label smoothing #446 NEG | z-loss #441 NEG | focal loss #791 NEG monotone | position-CE #801 NEG bilateral. **Future loss-side work should target structural mechanisms (output projection variants, frequency-aware *init* not *loss*, multiplicative preconditioner adjustments — see #838) — NOT CE shape.**

Second confirmation of `self.training` validation gate durability across CE-modifying experiments.

**Follow-up**: askeladd assigned **#845 Embed gradient sparsity-rescaling via inverse-frequency weighting** — fresh gradient-side mechanism axis. Multiplies embedding gradient rows by `sqrt(freq_max/freq(v))` to freshen v_t for rare-row sparse activation. Mechanism-orthogonal to closed CE-shape family (loss-side) — operates on gradient AFTER backward, BEFORE optimizer step. Parallel Zipf-asymmetry disambiguation with edward's in-flight #838 (lm_head v_t floor): two AUX groups attacked simultaneously from two orthogonal angles.

### 🔄 askeladd #845 — Embed gradient sparsity-rescaling via inverse-frequency weighting [assigned 21:40 UTC; N=1 chain terminal 05:39 UTC, SENT BACK for paired-pod n=3 on Arm B 05:43 UTC]

**Branch:** `g1r4-askeladd/embed-grad-freq-rescale` (commit `f7b33e0` pushed — chain hygiene clean)
**Hypothesis**: Apply per-row multiplicative weight w(v) = f(freq_max/freq(v)) to embedding gradient AFTER backward + aux-clip, BEFORE optimizer1.step(). Rare-row gradients are scaled UP so each visit refreshes v_t adequately even at β₂=0.99 (v_t decays to ~0 between visits for rare tokens). Mechanism-orthogonal to all closed loss-side reweighting (different stage of pipeline: gradient pre-conditioner, not loss-aggregation). Pairs cleanly with #838 (lm_head v_t floor) for parallel Zipf-asymmetry disambiguation.
| Arm | MODE | W_MAX | description |
|:---:|:---:|:---:|:---|
| A | off | n/a | clean ctrl, identity weight |
| B | sqrt_inv | 10.0 | classic inverse-freq sqrt-tempered |
| C | sqrt_inv | 5.0 | conservative cap |
| D | frac_inv_0p33 | 10.0 | very mild rare-row boost |

**05:39 UTC SENPAI-RESULT terminal — 4-arm N=1 finished (drift gate A PASS, mixed outcome)**:

| Arm | freq_mode | wmax | run ID | val/loss | fs | Δ_vs_A | Δ_vs_baseline 3.27036 |
|:---:|:---:|:---:|---|:---:|:---:|:---:|:---:|
| A (ctrl) | off | 10 | `nlu9fwav` | 3.27030 | 3225 | — | −0.00006 (drift PASS bit-clean) |
| **B** | **sqrt_inv** | **10** | `oe1a300s` | **3.26903** | 3200 | **−0.00127** | **−0.00133 (best direction-correct sub-threshold)** |
| C | sqrt_inv | 5 | `tk2sgiid` | 3.27081 | 3225 | +0.00051 | +0.00045 (mild regression — wmax=5 binding) |
| D | frac_inv_0p33 | 10 | `iqzyvm51` | 3.26945 | 3200 | −0.00085 | −0.00091 (direction-correct, gentler exponent) |

**Verdict (signal threshold −0.002 NOT MET; regression threshold +0.0015 NOT MET; MIXED)**: Arm B sub-signal but cleanest of evening across all in-flight PRs (#787 collapsed, #847 in-flight, #848 in-flight, #838 NEG). Cross-arm internal support: D direction-correct at gentler exponent (mechanism prediction), C mild regression confirms cap mechanism (wmax=5 clips very rare tail where v_t staleness effect would be largest).

**05:43 UTC decision — SENT BACK for paired-pod n=3 on Arm B per pre-staged trigger (Δ ≤ −0.001 → paired-pod)**:
- Three sequential runs on Arm B config (sqrt_inv, wmax=10), seeds 1/2/3, single-GPU, full post-#708 stack
- Pre-staged merge gates frozen: (1) mean(3 seeds) ≤ 3.27036, (2) `(3.28 − μ) × √3 ≥ 0.004` stat rule, (3) ≥2/3 direction-correct, (4) no seed > 3.275, (5) at least one seed within ±0.0010 of N=1 value 3.26903
- ETA per pod ~108 min × 3 = ~5.4h chain
- Collapse probability ~75% per 10+ paired-pod precedents (most recent: fern #787 Pod 1 reversal +0.00127 at 03:40 UTC); cross-arm internal confirmation modestly elevates above noise

**If paired-pod confirms**: merge B, then consider cap sweep (wmax=8, 12, 15) and cross-axis combination with #847 init-anchored WD if that also confirms. **If collapses**: 12th paired-pod collapse precedent → closes axis as "N=1 Δ ≈ −0.001 to −0.0015 below paired-pod noise floor on this baseline".

**~07:43 UTC seed 1 finished** (W&B-verified, askeladd silent-progression pattern — visibility comment posted 09:05 UTC): seed 1 (`riny958o`) val=**3.26864**, Δ_vs_new_base 3.26944 = **−0.00080** ✅ direction-correct. Drift vs N=1 Arm B (3.26903): |Δ|=0.00039 (clean PASS ±0.0010). Seed 2 (`lgn6hwxh`) running ~67% (step ~2250/3350), ETA terminal ~09:55 UTC. Seed 3 ETA ~11:50 UTC. **Cross-PR parallel pattern with alphonse #847**: both n=3 chains show direction-correct seed 1 (askeladd Δ=−0.00080, alphonse Δ=−0.00091) — two independent AUX-side mechanisms (gradient pre-conditioner ↔ weight-anchor WD) both trending favorable. Watch for paired-pod collapse vs sustained signal at terminal.

**11:37 UTC SENPAI-RESULT terminal — paired-pod n=3 complete, sent back for rebase + re-run on post-#787 stack**:

| Seed | run ID | val/loss | Δ_vs_new_base 3.26944 | Δ_vs_old_base 3.27036 |
|:---:|---|:---:|:---:|:---:|
| 1 | `riny958o` | 3.26864 | **−0.00080** ✅ | −0.00172 |
| 2 | `lgn6hwxh` | 3.26913 | **−0.00031** ✅ | −0.00123 |
| 3 | `31f549pg` | 3.26982 | +0.00038 ⚠️ | −0.00054 |
| **mean** | — | **3.26920** | **−0.00024** (marginal) | **−0.00116** (clean OLD-stack win) |

**All 5 pre-staged gates PASS marginally vs new baseline 3.26944**:
- Gate 1 mean ≤ 3.26944: PASS (Δ=−0.00024 sub-SEM)
- Gate 2 stat-rule (3.28−mean)×√3 = 0.01871 ≥ 0.004: PASS
- Gate 3 ≥2/3 direction-correct vs new: PASS (2/3; vs old: 3/3)
- Gate 4 no seed > 3.275: PASS (max 3.26982)
- Gate 5 ≥1 seed within ±0.0010 of N=1: PASS (3/3)

**SEM = 0.000342, t-stat ≈ −0.71** — margin against new baseline is well below statistical significance. **N=1 (3.26903) → paired-pod (3.26920) retention** sits on the same N=1→n=3 collapse trajectory as 12 prior precedents this cycle but stops short of full collapse.

**11:42 UTC decision — sent back for rebase + re-run** (per #789 tanjiro precedent despite preflight passing): although senpai_merge_winner_preflight returned PASS (file-level diff is clean against post-#787 advisor branch), the chain validated mechanism on OLD pre-#787 stack and the margin vs new baseline is marginal. Student themselves recommended rebase + re-run. Re-run protocol:
- Rebase onto current advisor branch (now post-#787)
- Re-run paired-pod n=3 on Arm B (sqrt_inv, wmax=10) with `NANOGPT_NS_STOCHASTIC_COOLDOWN=2` added
- **11:56 UTC — rebased run LIVE**: `zkx8xeqb` under `g1r4-askeladd/embed-grad-freq-rescale-rebased`. Step 525/3350 (16%), val 3.808 (early), on post-#787 stack. Seed 1 ETA ~14:00 UTC; full n=3 chain ETA ~17:00 UTC. Student picked up send-back rapidly (~13 min from comment-post to launch).
- Pre-staged gates frozen as-set against new baseline 3.26944
- ETA ~5.4h chain
- Pre-staged outcomes: MERGE if mean(rebased,n=3) ≤ 3.26944 AND ≥2/3 dir-correct vs new; productive-NULL if ∈ (3.26944, 3.27036]; productive-NEG if > 3.27036

**Durable mechanism characterization preserved either way**: N=1 4-arm Goldilocks (B=−0.00127, D=−0.00085, C=+0.00051) + OLD-stack paired-pod mean Δ_vs_old=−0.00116 clean — gradient-side per-row Zipf rescaling at sqrt-inverse-frequency with wmax=10 cap is the productive corner of the axis on the pre-#787 stack.

**09:39 UTC seed 2 finished, seed 3 launched**: seed 2 (`lgn6hwxh`) val=**3.26913**, Δ_vs_new_base = **−0.00031** ✅ direction-correct. Drift vs N=1: |Δ|=0.00010 (clean PASS). Mean(n=2) = **3.268885**, Δ_vs_new_base = −0.000555. Gates 3 (direction-correct ≥2/3): already PASS 2/2. Gates 4 (no seed >3.275) + 5 (≥1 seed within ±0.0010 of N=1): PASS. For final mean(n=3) ≤ 3.26944, seed 3 needs val ≤ 3.26995. Seed 3 (`31f549pg`) launched 09:38 UTC, ETA terminal ~11:26 UTC. **Direction-correct gate would be 3/3 dir-correct, drift PASS, mean below baseline — but cross-PR protocol applies (chain on OLD pre-#787 stack)**. Askeladd has explicitly acknowledged rebase + re-run protocol at terminal.

**10:50 UTC — seed 3 mid-run**: `31f549pg` at step 2175/3350 (65%), val 3.417 (mid-trajectory, descending normally). ETA terminal ~11:26 UTC.

**14:01 UTC — rebased seed 1 TERMINAL + seed 2 LAUNCHED**:

Seed 1 (`zkx8xeqb`) finished val=**3.26950**, Δ_vs_new_base 3.26944 = **+0.00006** (marginal regression vs new baseline). Δ_vs_old_base 3.27036 = −0.00086 clean. Drift sanity vs OLD-stack seed 1 (3.26864): |Δ|=0.00086 (PASS within ±0.001). first_step_to_target=3200.

Seed 2 (`z85uh78i`) launched at step 250/3350 (7%) val=4.093 — early phase normal. ETA terminal ~16:05 UTC.

**N=3 merge math** (frozen 11:42 UTC gates, mean ≤ 3.26944 required):
- Seed 1 = 3.26950 (above ceiling by +0.00006) → seeds 2+3 sum allowed ≤ 6.5388, mean ≤ 3.26941
- Tightens significantly: seeds 2+3 must average ≤ 3.26941 (cleaner than seed 1)
- For comparison, pre-rebase OLD-stack mean was 3.26920 (seeds at 3.26864, 3.26913, 3.26982)
- Stochastic NS attenuation hypothesis: post-#787 stack may sap the gradient-side mechanism's headroom; gain absorbed into the new variance regime

**Contrast with #847 alphonse rebased seed 1 (3.26642, Δ=−0.00302 STRONG)**: same protocol, both AUX-side mechanisms, divergent outcomes after rebase. #847's weight-side init-anchor composes favorably with stochastic NS; #845's gradient-side inverse-freq rescaling attenuates. Two-mechanism cross-axis disambiguation emerging — weight-side AUX intervention is the more robust composition direction.

Awaiting seeds 2+3 for final merge eligibility determination.

### ✅ askeladd #579 — Body Muon LR asymmetry (attn=0.80×, mlp=1.20×) — MERGED 09:55 UTC 🏆

**Branch:** `g1r4-askeladd/muon-attn-mlp-lr-asym`

**Phase 1 single-seed 4-arm** (drift gate A PASS, |3.27189−3.27174|=0.00015): A=3.27189 ctrl, B (0.80, 1.00)=+0.00083 null, C (1.00, 1.20)=+0.00080 null, **D (0.80, 1.20)=3.27052 (Δ=−0.00137, signal sub-threshold)**. Pre-staged singleton-null/compound-signal pattern fires exactly.

**Phase 2 paired-pod n=3 confirmation** (3350 steps, locked merged-stack envs, free seeds across pods):
| Pod | A val | D val | Δ_pod |
|---|---:|---:|---:|
| 0 | 3.27286 | 3.27317 | +0.00031 (sign-flip, tiny) |
| 1 | 3.27154 | 3.26897 | −0.00257 (signal) |
| 2 | 3.27178 | 3.26996 | −0.00182 (signal) |
| **mean(n=3)** | **3.27206** | **3.27070** | **−0.00136** |

**Merge gate decision (CLAUDE.md "when in doubt, merge"; direct precedent #393 merged at near-identical paired-pod Δ=−0.00137)**:
- Gate 1 within-pod mean Δ ≤ −0.002: FAIL at −0.00136 (sub-threshold)
- Gate 2 μ_D ≤ baseline 3.27174: **PASS** at 3.27070 (−0.00104 absolute)
- Gate 3 stat-rule (3.28 − 3.27070) × √3 = 0.01611 ≥ 0.004: **PASS**
- Drift gates: pod0-A=+0.00112, pod1-A=−0.00020, pod2-A=+0.00004 — all 3 within ±0.003 ✓

Direction-correct 2/3 pods, μ_D beats baseline by 0.00104 absolute. **Merged per project-level statistical rule**, mirroring #393 precedent at virtually identical magnitude.

**Mechanism**: NS-orthogonalization normalizes spectral direction per-matrix but not relative scale across matrix-types. Attn matrices benefit from conservative effective step (less attention-routing jitter); MLP matrices benefit from larger step (better gradient signal extraction). Singletons sub-threshold but compose under combined application — a true interaction effect signature, not magnitude addition. `first_step_to_target` improved: μ_A=3233.3 → μ_D=3225.0 (−8.3 steps consistent with val improvement).

W&B group `g1r4-askeladd/muon-attn-mlp-lr-asym-paired-pod` — D runs: `xba0kue2`, `a861snwz`, `vg8dkwf3`.

**New merged envs**: `NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20`. 9th merged improvement this cycle.

### ✅ askeladd #543 — Per-block NS iter budget — CLOSED 13:35 UTC productive-NULL

Single-seed 4-arm sweep (drift gate A PASS, |3.27243−3.27174|=0.00069): A uniform=3.27243, B aspect=+0.00077 (null), C manual_typeA=−0.00017 (null, best), D manual_typeB=+0.00056 (null). All 3 reallocation arms in productive-null band [−0.002, +0.0015]. NS=12 saturation **robust to spatial reallocation** — combined with #470 uniform escalation finding, NS-iter count is genuinely saturated at this budget. Architectural finding (student-documented): codebase uses split-qkv naming (`attn.q`/`attn.k`/`attn.v` all 768×768 square) — only 2-of-6 Muon blocks (`mlp.fc`, `mlp.proj`) have aspect > 1.0, limiting the spatial reallocation surface. **34th productive-null/negative this cycle.**
**Follow-up**: askeladd assigned **Body Muon LR asymmetry (attn vs mlp split)** — per-block-TYPE LR axis (vs #543 per-block iter), structurally distinct from #393 (AdamW per-group LR) and #409 (LLRD depth-LR).

### ✅ nezuko #454 — lm_head/scalar cooldown shape extension — CLOSED 18:05 UTC productive-null

Arms B/C/D (lm_head_floor, scalar_floor, both): best Δ=−0.00098 (arm B), half the −0.002 threshold. Arm D (stacked) regresses +0.00072 vs A, indicating cross-group interaction at end-of-cooldown. **linear_floor is embed-specific** (sparse-row coverage benefit), not aux-generic. Three prior paired-pod false-positives (#344, #351, #408 AGC) support conservative close. **20th productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#490 NAdam (Nesterov-AdamW) scope sweep** — first-moment reformulation, first Adam-family axis we haven't tested.

### ✅ nezuko #490 — NAdam (Nesterov-AdamW) scope sweep — CLOSED 02:15 UTC productive-null

Arms B (embed: Δ=−0.00059, mild +), C (lm_head: Δ=+0.00063, mild −), D (all_aux: Δ=+0.00275, regression). Best arm B well within null band (need ≤−0.002); D's compounded regression suggests scalar group is bad actor under NAdam (aggressive direction-change due to normalization layers). **26th productive-null/negative this cycle.** Closes the first-moment axis of the AdamW-internal three-axis ablation (magnitude #442 NEGATIVE, first-moment #490 null/regress, second-moment #474 NEGATIVE) — **AdamW-internal axis family substantially exhausted on merged stack**.
**Follow-up**: nezuko assigned **#530 Nesterov-Muon body scope sweep** — structurally parallel test on Muon body momentum (lookahead before NS).

### ✅ nezuko #530 — Nesterov-Muon body scope sweep — CLOSED 10:15 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27253−3.27174|=0.00079): A α=0.95=3.27253, B α=0.00 (bypass)=+0.00630 (regression), C α=0.50 (half-mix)=+0.04114 (severe, target NOT reached), D α=0.99 (over-Nesterov)=+0.00060 (null). **Structural finding**: the cliff is on the *low-α* side (NS-stability breakdown when current-grad weight >>0.05); the plateau is on the *high-α* side (Arm D within noise). α=μ=0.95 sits at boundary of safety — the mix is best understood as a tiny anti-staleness injection (~5% current-grad on top of 95% EMA), small enough to stay in NS's well-behaved spectral domain. Heavier current-grad injection pushes the NS input outside the Newton-Schulz polynomial's well-conditioned regime. **5th body-Muon mechanism axis closed** (joins #102 LR warmup, #356 μ schedule, #434 Lookahead-wrap, #483 WD warmup). Body Muon algorithmic axes on the merged stack are largely exhausted — future body-Muon ideas should target architectural changes (post-NS-side modifications, NS-iteration-count interactions). **32nd productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#568 Per-group cooldown_frac decoupling** — fresh structural axis on per-group cooldown WINDOW LENGTH (vs per-group cooldown SHAPE which is largely characterized).

### ✅ nezuko #568 — Per-group cooldown_frac decoupling — CLOSED 18:40 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27134−3.27174|=0.00040): A=3.27134, B (embed=0.80)=−0.00014 (null), C (embed=0.60)=**+0.00242 (regression)**, D (body=0.80)=−0.00067 (null, best). No arm crosses −0.002 signal threshold. Best arm D passes single-seed stat-rule at n=1 ((3.28−3.27067)×√1=0.00933 ≥ 0.004) AND beats baseline (3.27067 ≤ 3.27174), BUT within-pod Δ=−0.00067 short of pre-staged paired-pod gate. Embed direction asymmetric-monotonic with floor at 0.70 (shortening hurts; lengthening gives only sub-threshold improvement). Body direction mildly positive sub-threshold (NS-orthogonalized landing benefits *mildly* from longer precision-window but not enough at ±0.10 perturbation). **SHAPE→FRAC analogy fails at this perturbation scale**: per-group cooldown SHAPE matters (real asymmetry) but per-group cooldown WINDOW LENGTH does NOT show same asymmetry within ±0.10 of 0.70. **39th productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#603 AdamW second-moment warmstart via ghost steps** — fresh untested mechanism addressing cold-start direction problem in `exp_avg_sq` that bias correction (magnitude rescaling) explicitly does not solve. Pre-training ghost-step loop accumulates m_t, v_t without weight updates; first ~100 training steps then operate on directionally-informed second-moment estimates instead of cold-start zero.

### ✅ nezuko #603 — AdamW ghost-step warmstart — CLOSED 00:10 UTC broken-chain + productive-NEGATIVE

Chain thrashed for ~5h with 6+ crashes across arms. Student identified key implementation limitation: `proj.weight=0` init at line 828 blocks gradient flow back through model during ghost steps (zero-inits all "proj" weights so `F.linear` backward `grad_input = grad_output @ proj.weight = 0`). Ghost steps thus only warm `lm_head` AdamW second-moment, NOT embed or scalar. The single completed arm (C ghost=25) reached **val=3.3018** — a +0.030 catastrophic regression vs baseline 3.27174, indicating ghost-step warmstart of lm_head's AdamW v_t is actively harmful. **43rd productive-NULL/NEGATIVE this cycle.** WAVE3 IDEA 7 (cold-start v_t direction) axis: closed. **Key durable finding (reusable across this programme): proj.weight=0 init blocks all upstream grad flow during pre-step probes — future optimizer-state-warming experiments must account for this.**
**Follow-up**: nezuko assigned **#628 trust-region adaptive Muon LR** — per-layer cos-EMA boost on rare-aligned layers. First experiment to AMPLIFY the rare-productive-direction signal rather than suppress conflict (vs #126 Contra-Soft attenuate, #163 DMR reset, #419 Cautious mask — all closed). Mechanistically distinct from all closed gradient-direction-aware mechanisms.

### ✅ nezuko #628 — Trust-region adaptive Muon LR (per-layer cos-EMA boost) — CLOSED 21:40 UTC productive-NULL

**Branch:** `g1r4-nezuko/trust-region-muon-lr`

Paired-pod n=3 terminal (only Arm B at BOOST=0.5 advanced after Phase 1 N=1):

| Pod | A val (ctrl) | B val (BOOST=0.5) | Δ_B_vs_A | A-drift vs 3.27070 |
|---|---:|---:|---:|---:|
| 0 | `785bssa9` 3.26902 | `y4lkmh68` 3.27291 | **+0.00389** (regression, 2.6× threshold) | −0.00168 (favorable) |
| 1 | `tu2c0ipa` 3.27344 | `7z8bjifp` 3.27219 | **−0.00125** (sub-threshold) | +0.00274 (unfavorable) |
| 2 | `r3txbt4h` 3.27269 | `hbdi8w4c` 3.27205 | **−0.00064** (sub-threshold) | +0.00199 (mid) |
| **mean (n=3)** | **3.27172** | **3.27238** | **+0.00067** | sd_A=0.00224 |

**Gates** (vs NEW baseline 3.27070): Gate 1 (mean Δ ≤ −0.002) FAIL at +0.00067 (wrong sign). Gate 2 (mean(val_B) ≤ 3.27070) FAIL at 3.27238 (+0.00168). Gate 3 stat-rule (3.28−3.27238)×√3=0.01319 PASS (moot). **No merge.**

**Phase 1 → Phase 2 collapse**: Phase 1 Δ_B_vs_A=−0.00268 → n=3 mean Δ=+0.00067. **Direction-flip + sign collapse**. Phase 1 Arm A had drift +0.00221 (upper edge); the negative within-pod Δ was inflated by unfavorable A seed AND was measured against OLD baseline 3.27174 (pre-#579). **#579's merge absorbed the productive component** — same productive signal the cos-EMA boost was extracting.

**11th N=1→paired-pod collapse precedent** post-#579.

**Mechanism reading — sub-percent LR boost + favorable-seed anti-amplification**:

Trust-mechanism telemetry across 3 B pods (reproducible — failure is at val/loss, not implementation):
- Max LR amplification: **<1% mean, <0.7% peak** even at BOOST=0.5
- cos_ema_pos_frac final: 0.208 / 0.236 / 0.333 (consistent across pods)
- lr_scale_max final: 1.00641 / 1.00344 / 1.00435

**Pod 0 (favorable A seed) anti-amplification**: Arm B over-shoots into +0.00389 regression while Arm A is at 3.26902 — BOOST pushes LR HIGHER when training is already going well, accelerating into overshoot. The "rare-productive amplification" hypothesis is INVERTED on favorable seeds.

**Mechanism class fully fenced**: Direction-aware Muon update modifications joining #126 Contra-Soft, #163 DMR, #419 Cautious, #629 layer-aggregate Contra-Soft, #530 Nesterov-Muon — all NULL/NEGATIVE.

**59th productive-null/negative this cycle.**

### ✅ nezuko #724 — Per-block-TYPE NS_ITERS_COOLDOWN — CLOSED 15:15 UTC productive-NEGATIVE (72nd cycle, 10th paired-pod collapse)

**Branch:** `g1r4-nezuko/per-type-ns-cooldown`

**Phase 2 n=3 paired-pod results (vs post-#708 baseline 3.27036):**

| Pod | Arm A ctrl (12/12) | Arm D treat (12/20) | Δ_D−A |
|---|---|---|---|
| 0 | 3.26889 | 3.27124 | **+0.00235** |
| 1 | 3.26944 | 3.27101 | **+0.00157** |
| 2 | 3.26901 | 3.27241 | **+0.00340** |
| **mean** | **3.26911** | **3.27155** | **+0.00244** |

**All 3 merge gates FAIL** — mean_D > baseline, 0/3 direction-correct, t=+4.60 highly significant REGRESSION.

**Phase 1 → Phase 2 sign-flip**: N=1 Δ=−0.00192 → n=3 mean Δ=+0.00244 (full sign reversal). Monotone regression magnitude (pod2 worst at +0.00340).

**Per-TYPE Muon hparam family ledger (post-#708)**:

| Axis | Status | PR |
|------|--------|-----|
| LR | ✅ MERGED | #579 |
| WD | ❌ NEGATIVE | #669 |
| μ (momentum) | ⚪ NULL | #674 |
| aspect ratio | ⚪ NULL | #632 |
| NS_ITERS_COOLDOWN | ❌ NEGATIVE | #724 (this) |

Per-TYPE Muon axis essentially exhausted. NS_ITERS_COOLDOWN at TYPE level adds noise without precision-allocation benefit — both attn (Q/K/V/proj) and mlp (fc/proj) matrix shapes converge to similar polar factor quality at NS=12. Mirrors per-DEPTH closure (#710). Frontier shifts to fresh axes: post-NS direction modification, data ordering, anchored regularization.

**10th paired-pod collapse precedent on r4.** Baseline UNCHANGED at val=3.27036 / fs=3216.67.

**Follow-up**: nezuko assigned **#825 Cautious AdamW for aux groups** — per-group disaggregation of #751's +0.00901 aux-all regression. 4-arm sweep: A=none ctrl, B=embed only, C=lm_head only, D=all aux. Reframed hypothesis: identify per-subgroup contribution to #751 Arm C regression on post-#708 stack (aux-side clip tightening from #708 may have changed dynamics).

### 🔄 nezuko #825 — Cautious AdamW per-aux-group disaggregation (4-arm) [assigned 15:15 UTC]

**Branch:** `g1r4-nezuko/cautious-aux`
**Hypothesis**: Liao et al. 2024 Cautious masks update components where `update * grad < 0` and rescales. #751 fern tested Cautious-all-aux (Arm C: +0.00901 large regression). #825 disaggregates per sub-group on post-#708 stack to identify per-group culprit. The new per-group grad-clip asymmetry (BODY=10/AUX=5 from #708) further tightens aux-side — may change Cautious's local effect.

| Arm | NANOGPT_AUX_CAUTIOUS | Description |
|:---:|:---:|:---|
| A | `none` | Control (bit-identical to #708 baseline) |
| B | `embed` | Mask embed updates only (largest aux param) |
| C | `lm_head` | Mask lm_head updates only (output coupling) |
| D | `all` | Mask all three aux groups (replicates #751 Arm C at +0.00901) |

Implementation: CautiousAdamW subclass (fused=False) with snapshot-delta post-step masking, 4-arm paired-pod n=3 (12 runs). ETA ~7.3h.

**14:01 UTC — Pod2 chain Arms A/B + earlier Pod1 D TERMINAL + Pod2 C live**:

| Arm | scope | run ID | val/loss | Δ_vs_A (Pod2) | Verdict |
|:---:|:----:|--------|:--------:|:------:|:--------|
| Pod2 A (ctrl) | none | `gq3yhvvj` | 3.26910 | — | clean control, favorable seed (Δ_vs_new_base=−0.00034) |
| Pod2 B | embed | `mzywwyyp` | 3.27196 | **+0.00286** | regression (replicates #751 cautious-embed direction) |
| Pod2 C | lm_head | `x4oop63a` step 2275/3350 (68%) val=3.416 | TBD | TBD (ETA ~14:37 UTC) |
| Pod2 D | all | (not launched) | TBD | TBD |
| Pod1 D | all | `4mq85fii` | **3.28084** | n/a | strong regression (+0.01174 vs new base) — replicates #751 Arm C catastrophic confirmation |

**Pattern matches expected from #751 fern Arm C +0.00901 (cautious-all)**: cautious masking on aux groups regresses across embed (Pod2 B +0.00286) and all (Pod1 D +0.01174). lm_head-only (Pod2 C) is the last untested scope — if also regresses, the per-aux-group cautious disaggregation closes productive-NEG (76th cycle). If Pod2 C lm_head shows Δ ≤ −0.002, it would be a surprising scope-specific signal warranting paired-pod confirmation. ETA Pod2 C terminal ~14:37 UTC.

### ✅ frieren #470 — NS iterations NORMAL phase sweep — CLOSED 20:55 UTC productive-null

Arms B=8 (+0.00235 regression), C=10 (−0.00168 null), D=14 (−0.00145 null). Wide saturation plateau NS ∈ [10, 14]; NS=8 below floor. **Critical compute finding: NS step-time is flat (±1%) across all NS values — orthogonalization is not the per-step bottleneck.** 21st productive-null/negative.
**Follow-up**: frieren assigned **#506 NS-iter warmup schedule** — ramp NS from {8,10} → 12 over first 5-10%.

### ✅ frieren #593 — Per-group AdamW WD sweep — CLOSED 00:05 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS exceptional parity |3.27167−3.27174|=0.00007): A=3.27167, B (lm_head WD=0.01)=+0.00192 (regression marginal), C (scalar WD=0.01)=−0.00017 (productive-null sub-noise-floor), D (joint)=−0.00022 (productive-null sub-noise-floor). No arm clears −0.002 signal threshold. **42nd productive-NULL/NEGATIVE this cycle.** **Cross-axis WD-ADDITION pattern now fully fenced**: AdamW lm_head WD ADD (B regress), AdamW scalar WD ADD (null), AdamW embed WD ADD (#554 NEG), Muon body WD warmup ADD (#483 NEG). Only WD direction with extractable gain on merged stack is REDUCTION (#550 Muon body WD cooldown reduce, paired-pod in-flight). Strengthens "baseline is locally optimal across WD axis; cooldown handles regularization adequately".
**Follow-up**: frieren assigned **#629 Layer-aggregate Contra-Soft Muon** — fills explicit untested gap diagnosed in #126 closure (element-wise Contra-Soft attenuated ~13-50% of gradient mass uniformly across granularities; layer-aggregate operates only on whole-matrix cosine, preserving productive-direction layers entirely). Distinct from #628 (boosts via LR scaling); this attenuates via gradient scaling on conflict-layers only.

### ✅ frieren #629 — Layer-aggregate Contra-Soft Muon — CLOSED 08:30 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, exceptional parity +0.00014): A=3.27159, B (α=0.25)=3.27345 (Δ=+0.00186, regression band), C (α=0.50)=3.27185 (Δ=+0.00026, null), D (α=1.00)=**3.63287** (Δ=+0.36128, **catastrophic — FAILS 3.28 target**). W&B runs: dqssobu4 (A), h1aqkx71 (B), d4ihlim2 (C), 34ui6a23 (D). Non-monotone (regress→parity→catastrophic) but uniformly non-improving. Mechanism telemetry: scale_min D=0.426 (cos_min=−0.574), D's α=1.0 full-zero-grad on conflict layers kills gradient signal; training oscillates and val plateaus at 3.63 (never reaching 3.28). **Contra-Soft mechanism class FULLY CLOSED**: #126 element-wise + #629 layer-aggregate both falsified. The load-bearing ~11% persistent-cos<0 fraction is productive exploration, not noise. **48th productive-null/negative this cycle.**
**Follow-up**: frieren assigned **#664 AdamW bias correction disable sweep** — genuinely fresh mechanism axis: with merged β2=0.99 (#236), bias correction scales mid-training aux updates down by sqrt(bc_v)/bc_m = 0.63–0.80× during steps 50–100; disabling it tests whether this implicit LR suppression limits mid-phase learning. Tests 3 scopes (embed-only, lm_head-only, all-aux).

### ✅ frieren #664 — AdamW bias correction disable sweep on aux groups — CLOSED 18:35 UTC productive-NULL

Single-seed 4-arm on NEW post-#579 stack (drift gate A2 PASS, +0.00154 within ±0.003): A2 ""=3.27224 ctrl, B2 embed=3.27143 (Δ=−0.00081 sub-threshold null), C2 lm_head=3.27144 (Δ=−0.00080 sub-threshold null), D2 all_aux=3.27217 (Δ=−0.00007, **saturation/interference**). No arm passes within-pod −0.002 winner threshold; best singletons B2/C2 at −0.0008 ~2.5× below threshold. **B2 ≈ C2 within single-seed noise σ≈0.001**: bias-correction disable on EITHER aux group produces nearly-identical marginal effect — the mid-training LR-boost mechanism applies uniformly across aux groups with no per-group structural preference. **D2 (all_aux) flattens to ctrl** rather than compounding additively (~−0.0016 expected if independent) — **saturation/interference**: the early-training relative-magnitude structure between embed/lm_head/scalar is maintained by their RELATIVE bias-correction factors; disabling on ALL three preserves the relative ratios while disabling on only one breaks them. The single-aux disable signal is a relative-magnitude shift, not a single-group mechanistic effect. Implementation clean (telemetry verified bc_scale_factor ramp matches expected curve, rebased onto post-#579 cleanly, wall-clock parity 1893-1894ms across all 4 arms). All 4 arms hit 3.28 target. **54th productive-null/negative this cycle.** Bilateral closure with per-group AdamW family: #599 β₁ NEG + #560 β₂ NEG + #593 WD NULL + #652 eps NEG + #664 BC NULL — AdamW-internal axes now FULLY exhausted on merged stack; only LR-mult #393 MERGED extracted gain.
**Follow-up**: frieren assigned **#710 per-depth body Muon NS_ITERS variation** — fresh axis distinct from per-block-TYPE wiring (avoids the impl-bug class seen in #669/#674). Tests early/mid/deep bucket NS-iter budget allocation; orthogonal to #543 (per-aspect-ratio, only differentiates mlp.fc/mlp.proj per layer because q/k/v/attn.proj are 1× aspect square 768×768) and #470 (uniform escalation) and #506 (time-axis warmup CLOSED-NEG). Mechanism: gradient magnitudes vary by depth (early layers diluted by backward chain depth; mid layers full backward flow / capacity bottleneck; deep layers closer to output); NS=12 uniform may over-invest on well-conditioned mid-layer matrices and under-invest on edge layers. 4-arm: A (12,12,12) ctrl, B (10,14,10) mid-heavy, C (14,12,10) front-loaded, D (10,12,14) back-loaded.

### ✅ frieren #710 — Per-depth body Muon NS_ITERS variation — CLOSED 14:09 UTC productive-NEGATIVE (70th cycle, 9th paired-pod collapse)

**Branch:** `g1r4-frieren/per-depth-muon-ns-iters`

**Phase 2 n=3 final:** mean_A=3.27060, mean_C=3.27177 — Δ=+0.00117 regression, 3/3 pods direction-wrong. Both binding gates FAIL (mean_C > baseline, 0/3 pods C<A). Phase 1 N=1 Δ=−0.00138 → Phase 2 n=3 Δ=+0.00117: classic sign-flip. **Mechanism**: NS normalizes depth-scale variation — all 12 body Muon depths converge to same polar factor quality at NS=12. DEPTH-asymmetric iter allocation provides no signal (same as #753 per-DEPTH LR NULL). Per-DEPTH bucket family fully closed. **9th paired-pod collapse precedent.**

W&B Phase 2: trdfa7c6/si0n5039, hjs2ww65/4eoi63uk, enxvvgga/f16ktn1n.

**Follow-up**: frieren assigned **#810 post-NS momentum** — temporal smoothing of NS-orthogonalized updates across steps (first post-NS axis; distinct from #356 pre-NS μ schedule NULL, #530 Nesterov-Muon NULL, #434 Lookahead NEG all of which operate pre-NS or in weight-space).

### ✅ frieren #810 — Post-NS momentum — CLOSED productive-NULL 10:20 UTC (11th paired-pod outcome since #708)

**Branch:** `g1r4-frieren/post-ns-momentum`
**Hypothesis**: After NS-orthogonalization, maintain post-NS buffer w_t = α×w_{t-1} + (1-α)×u_t. Apply w_t as update instead of u_t. Mechanism: NS is nonlinear, so post-NS averaging is distinct from pre-NS EMA (β=0.95). **First POST-NS axis explored — mechanism-distinct from #356 pre-NS μ schedule NULL, #530 Nesterov-Muon NULL, #434 Lookahead weight-space NEG.**

**Phase 1 N=1 results (W&B-verified, post-#708 baseline 3.27036):**

| Arm | α | run_id | val/loss | fs | Δ_vs_A | Δ_vs_baseline | Verdict |
|:---:|:---:|---|:---:|:---:|:---:|:---:|:---|
|  A  | 0.0 | et21o2vx | 3.27225 | 3250 | — | +0.00189 (drift PASS) | ctrl |
|  **B** | **0.3** | **j7yipric** | **3.26831** | **3200** | **−0.00394 (SIGNAL)** | **−0.00205 (barely past −0.002)** | **WINNER CANDIDATE** |
|  C  | 0.5 | uarp5kkm | 3.27465 | 3275 | +0.00240 (regression) | +0.00429 | regression |
|  D  | 0.7 | 1kpbp0ss | 3.28980 | NEVER hit | +0.01755 (severe) | +0.01944 | catastrophic |

**Non-monotone concave-down surface with α=0.3 peak.** Textbook Goldilocks signature: mild smoothing helps, moderate hurts, strong catastrophic (target never hit at α=0.7). Within-pod Δ_B-A=−0.00394 ~2× signal threshold.

**Confound:** Student's A_ctrl uses only `NANOGPT_GRAD_CLIP=10.0` (no per-group BODY=10/AUX=5 from post-#708). W&B confirms `NANOGPT_GRAD_CLIP_BODY` and `NANOGPT_GRAD_CLIP_AUX` UNSET on all 4 runs. A_ctrl drift +0.00189 vs post-#708 baseline confirms this. Within-pod Δ robust regardless, but absolute baseline comparison requires full stack to be conclusive.

**Sent back 22:10 UTC for paired-pod n=3 confirmation on FULL post-#708 stack** (with per-group BODY=10/AUX=5). Total: 6 runs (3 pods × 2 arms) × 108 min ≈ 10.8h sequential.

**Pre-staged outcomes:**
- **MERGE candidate**: 3/3 pods Δ_within ≤ 0 AND mean(B) ≤ 3.27036 AND stat-rule pass → first POST-NS mechanism merge
- **Borderline**: 2/3 direction-correct, mean(B) ∈ [3.27036, 3.27050] → close productive-NULL (consistent with 10 prior paired-pod collapses)
- **Collapse**: ≤1/3 direction-correct OR mean(B) > 3.27050 → close productive-NEGATIVE (11th paired-pod collapse on this stack)

Mechanism is structural-novel — if it holds, opens up post-NS-side as a fresh axis (α schedule, per-block-type α, α + cooldown interaction).

**Paired-pod chain TERMINAL (10:10 UTC, all 6 runs finished + 1 crashed retry, n=3 complete):**

| Pod | Arm | run_id | state | val/loss | Δ_within | Δ_vs_new_base 3.26944 |
|:---:|:---:|---|:---:|:---:|:---:|:---:|
| 0 | A (α=0) | `k787xn6h` | finished | 3.26922 | — | −0.00022 (drift PASS) |
| 0 | B (α=0.3) v1 | `c83g1myx` | crashed | 3.61855 | — | (ignored) |
| 0 | B (α=0.3) v2 | `0ial88yh` | finished | 3.26890 | **−0.00032** | −0.00054 |
| 1 | A (α=0) | `lntre2rk` | finished | 3.27030 | — | +0.00086 (drift PASS) |
| 1 | B (α=0.3) | `cknbzxxu` | finished | 3.27132 | **+0.00102** | +0.00188 |
| 2 | A (α=0) | `03432nbb` | finished | 3.26888 | — | −0.00056 (drift PASS) |
| 2 | B (α=0.3) | `kyi2ei6z` | finished | **3.26812** | **−0.00076** | −0.00132 |

**n=3 paired-pod summary:**
- Mean(A) = 3.26947 (drift vs baseline 3.26944 = +0.00003, near-perfect baseline reproduction)
- Mean(B) = 3.26945 (Δ_vs_new_base = +0.00001, functionally tied)
- **Mean Δ_within = −0.00002** (essentially neutral; signal collapsed from N=1 −0.00394)
- Direction-correct 2/3 pods (Pod 0 mild, Pod 2 sub-threshold; Pod 1 direction-wrong)

**Verdict: productive-NULL** — pre-staged outcome triggered. Gate 1 (mean Δ ≤ −0.002) FAIL at −0.00002. Gate 2 (mean val_B ≤ 3.26944) technical FAIL at 3.26945 (+0.00001). Direction-correct 2/3, drift-PASS 3/3. **NOT a catastrophic collapse — the signal magnitude collapsed (N=1 −0.00394 → n=3 −0.00002) but direction maintained 2/3 pods.** This is the **11th paired-pod outcome since #708** — pattern continues: N=1 single-arm signals at this baseline rarely survive paired-pod confirmation.

**Mechanism reading**: Post-NS momentum at α=0.3 reproduces baseline within rounding error. The post-NS axis (structurally novel mechanism level) does not extract additional gain over baseline's existing pre-NS μ=0.95 EMA. Composes with pre-NS μ axis (#356 NULL, #530 NULL) and weight-space-EMA (#436 NEG, #434 Lookahead NEG) — **post-NS adds another fenced corner; full Muon temporal-smoothing family substantially exhausted across pre-NS/in-NS/post-NS/weight-space**.

**Terminal SENPAI-RESULT posted 10:17 UTC**: mean(A,n=3)=3.26947 (drift +0.00003 vs new baseline — 5th independent cross-validation), mean(B,n=3)=3.26945 (Δ_vs_new_base=+0.00001, tied). Signal collapsed from N=1 −0.00394 to n=3 −0.00002. Root cause: N=1 screening used non-per-group clip stack (A_ctrl drifted +0.00189 above baseline), providing false headroom that Arm B consumed. Under full post-#708 BODY=10/AUX=5 stack, no headroom → signal disappears. **Muon temporal-smoothing family now fully fenced across pre-NS (#356 NULL, #530 NULL) / in-NS (#470 NULL, #506 NEG) / post-NS (#810 NULL, #434 Lookahead NEG) / weight-space (#436 NEG) mechanism levels.** CLOSED 10:20 UTC with detailed close comment.

**Follow-up**: frieren assigned **#900 Anisotropic Gradient Noise** (curvature-matched injection, WAVE5-5). New assignment ETA ~17:40 UTC.

### ✅ frieren #506 — NS-iter warmup schedule — CLOSED 16:15 UTC productive-NEGATIVE [paired-pod n=3]

Paired-pod n=3 confirmation: all 3 pods regress (mean Δ=+0.00087, wrong sign). Gates 1+2 fail (mean Δ above 0, mean val_B 3.27329 > baseline 3.27174). The N=1 Δ_C=−0.00119 was an Arm-A drift artifact (original Arm A drifted +0.00108 above baseline; paired-pod Arm-A controls anchor at +0.00068). **5th cycle precedent for single-seed → paired-pod collapse** (joins #344, #351, #408, #487). **NS-axis program now fully fenced**: 3/3 NS-iter schedule axes closed by frieren (warmup #506, normal-phase #470, cooldown saturation #388) + 3 cooldown-machinery components MERGED (#176, #285, #290) + sub-stack pruning #487 null + spatial #543 null. **37th productive-null/negative this cycle.**
**Follow-up**: frieren assigned **per-group AdamW WD sweep** — currently WD=0 uniformly across embed/lm_head/scalar; whether dense lm_head or small-param scalar groups benefit from WD>0 has never been tested. Structurally distinct from #554 (embed WD ADD cooldown, NEGATIVE — sparse-row mechanism), #550 (Muon body WD), #483 (Muon WD warmup, NEGATIVE).

### ✅ edward #474 — AdaBelief for aux groups — CLOSED 22:35 UTC productive-NEGATIVE

Arms B (embed: +0.04081), C (lm_head: +0.00188), D (all-aux: +0.03479). D ≈ B trajectory confirms embed group dominates catastrophic regression. Root cause: AdaBelief's `(g−m)²` fails on sparse-row embed (absent rows have g=0 but m≠0 → `(g−m)²=m²`, inflating denominator globally). lm_head: stable mild regression. **23rd productive-null/negative this cycle.** Second-moment-formulation axis fully closed.
**Follow-up**: edward assigned **#516 Yogi optimizer on aux groups** — sign-based additive second-moment update (avoids embed sparsity pathology, structurally distinct).

### ✅ edward #516 — Yogi optimizer on aux groups — CLOSED 07:00 UTC productive-NEGATIVE (embed/all-aux) + productive-NULL (lm_head)

Single-seed 4-arm (drift gate A PASS, |3.27419−3.27174|=0.00245 ≤ 0.003): A=3.27419, B embed=+0.00386 (regression), C lm_head=+0.00038 (null), D all-aux=+0.00447 (regression). D ≈ B + 0.00061 — embed regression dominates; lm_head and scalars contribute marginally. Mechanism reading: Yogi's faster-additive v_t reaction destabilizes sparse-row embed at β₂=0.99 (regression grows monotonically through cooldown); dense lm_head indistinguishable from AdamW. Independent of AdaBelief mechanism (#474): Yogi accumulates g² same as AdamW. **Closes second-moment-update-rule axis** — joined with #474 AdaBelief, #442 Adam-atan2, #490 NAdam-aux. **29th productive-null/negative this cycle.**
**Follow-up**: edward assigned **#550 Muon WD cooldown reduction** — first late-phase WD axis (structurally distinct from #483 WD warmup which tested early reduction).

### ✅ edward #639 — Embed-stack joint redundancy ablation: linear_floor × LR_MULT=1.5 — CLOSED 11:10 UTC productive-NULL

4-arm 2×2 factorial (N=1, ran on OLD pre-#579 stack — #579 merged mid-experiment): A (full)=3.27438, B (drop floor)=3.27285 (Δ=−0.00153), **C (drop mult)=3.27222 (Δ=−0.00216 best)**, D (drop both)=3.27487 (Δ=+0.00049). **All 4 arms above NEW baseline 3.27070** — C closest at +0.00152. Mechanism finding: **mutual antagonism / saturation** — A ≈ D, single-component drops each help slightly. Effective late-phase embed LR: A=0.0675 (saturated) > C=0.045 (sweet spot) > B=0.45→0 > D=0.30→0. Both #235 and #393 push embed LR past sweet spot; stacking saturates surface. Arm C's −0.00216 within-pod signal at threshold edge but Arm A drift +0.00264 baked-in — paired-pod confirmation cannot land mean(val_C) below 3.27070. Cannot merge; stack simplification not viable. **Future embed-side experiments should target joint surface** rather than individual axes. **51st productive-null/negative this cycle.**
**Follow-up**: edward assigned **#674 per-block-type Muon momentum asymmetry** — direct extension of #579/#669 mechanism family on 3rd Muon hparam axis. 4-arm sweep (attn_mu × mlp_mu): A=(0.95,0.95) ctrl, B=(0.90,0.95) attn-faster, C=(0.95,0.99) mlp-slower, D=(0.90,0.99) compound. Mirror #579 4-arm pattern. Mechanism: attn-prefer-faster-tracking (less stale routing signal), mlp-prefer-slower-tracking (lower variance feature gradient). Completes per-block-TYPE Muon hparam family (LR ✓#579 / WD #669 / momentum #674).

### ✅ edward #674 — Per-block-type Muon momentum asymmetry — CLOSED 19:20 UTC productive-NULL/NEGATIVE

4-arm single-seed sweep (drift gate Arm A PASS at +0.00053): A=(0.95,0.95)=3.27123, B=(0.90,0.95)=3.27066 (Δ=−0.00057 sub-threshold direction-correct), **C=(0.95,0.99)=3.27986 (Δ=+0.00863 strong regression, fst=3350)**, D=(0.90,0.99)=3.27915 (Δ=+0.00792, tiny B-rescue from additive prediction +0.00806). No winner-candidate. **Per-block-TYPE momentum axis does NOT mirror #579 LR asymmetry pattern.** mlp_mu=0.99's ~100-step window staleness dominates variance reduction benefit. Mechanism refinement: #579's productive interaction is specifically about step-size magnitude (LR axis), NOT about gradient-averaging time-constant — the two per-block-TYPE Muon hparam axes are mechanistically distinct. **56th productive-null/negative this cycle.** Per-block-TYPE Muon family characterization: LR ✓#579 MERGED / WD #669 in flight / mu ✗ NULL (this) / NS_ITERS,β₂,ε unexplored.
**Follow-up**: edward assigned **#712 Per-block-TYPE body Muon β₂ asymmetry** — second-moment variance-estimator window per block type. Orthogonal to mu (first moment), LR (step magnitude), WD (regularization). β₂ already a per-group field in Muon class; trivial ~5 LOC env-var change. 4-arm: A=(0.999,0.999) ctrl, B=(0.99,0.999) attn-shorter, C=(0.999,0.99) mlp-shorter, D=(0.99,0.99) uniform-shorter control separating per-TYPE asymmetry from "just shorter everywhere". Distinct from #97 (global β₂ sweep at 0.999 optimal) and #560 (per-aux-group AdamW β₂ NEG, structurally different because no NS).

### ✅ edward #712 — Per-block-TYPE body Muon β₂ asymmetry — CLOSED 03:35 UTC productive-NULL

**Branch:** `g1r4-edward/muon-attn-mlp-beta2-asym`

Single-seed 4-arm result (drift gate A PASS at +0.00032):

| Arm | attn β₂ | mlp β₂ | val/loss | Δ_vs_A | Δ_vs_baseline | Band |
|---|---:|---:|---:|---:|---:|---|
| A (ctrl) | 0.999 | 0.999 | 3.27102 | — | +0.00032 | drift PASS |
| B (attn-shorter) | 0.99 | 0.999 | **3.27027** | −0.00075 | −0.00043 | null sub-threshold |
| C (mlp-shorter) | 0.999 | 0.99 | **3.27029** | −0.00073 | −0.00041 | null sub-threshold |
| D (uniform-shorter) | 0.99 | 0.99 | 3.27280 | **+0.00178** | **+0.00210** | regression direction-incorrect |

**Mechanism reading**: B/C symmetric magnitudes (Δ_vs_A = −0.00075 / −0.00073) confirm **no per-TYPE β₂ asymmetry sweet spot exists**. Both singleton shortenings direction-correct but ~3× below −0.002 paired-pod threshold. D compound regression (+0.00178) is informative: **non-additive failure** confirms uniform β₂=0.999 (#97 finding) is genuinely near-optimum at per-TYPE granularity. Sub-threshold-direction-correct signals (B/C at |Δ| ≈ 0.0007) sit in the same magnitude band as the 12 paired-pod-collapse precedents this cycle.

**Per-block-TYPE Muon family characterization complete**:
- LR ✓ MERGED (#579) — only productive axis
- mu ✗ NULL (#674)
- β₂ ✗ NULL (this)
- WD ✗ NEGATIVE (#669)
- aspect-exp ✗ NULL (#632)
- NS_ITERS_COOLDOWN 🔄 (#724 nezuko in-flight)

**Hygiene note from student**: 11-crash pod-environment startup window + duplicate-chain incident handled cleanly by student (killed duplicate PIDs, renamed duplicate script to `.DUPLICATE_KILLED`). Surviving runs uncontaminated. Good defensive engineering practice for future PRs.

**62nd productive-null/negative this cycle.**

**Follow-up**: edward assigned **#753 Per-block-DEPTH body Muon LR asymmetry** — extends #579 (per-block-TYPE LR MERGED) to depth axis with 3 buckets (early=L0-3, mid=L4-7, deep=L8-11). Direct parallel to #710 frieren (per-depth NS_ITERS in-flight); #710 Phase 1 showed front-loaded NS=14/12/10 wins by Δ=−0.00138 monotone front-vs-back. Per-DEPTH LR may extract gain via same early-layer signal-dilution mechanism. Distinct from #409 LLRD (geometric decay NULL pre-#579) — 3-bucket non-monotone parametrization untested.

### ✅ edward #753 — Per-block-DEPTH body Muon LR asymmetry — CLOSED 11:30 UTC productive-NULL (67th cycle)

**Branch:** `g1r4-edward/per-depth-muon-lr`

**Terminal 4-arm N=1 result (drift gate A PASS at Δ=−0.00282 within ±0.003):**

| Arm | EARLY / MID / DEEP | val/loss | Δ_vs_A | Δ_vs_baseline | fs | Verdict |
|---|:---:|---|---|---|---|---|
| A (ctrl) | 1.00/1.00/1.00 | 3.26788 | — | −0.00282 (favorable drift) | 3200 | drift PASS |
| B (front-loaded) | 1.20/1.00/0.80 | 3.26984 | +0.00196 | −0.00086 | 3225 | regression |
| C (back-loaded) | 0.80/1.00/1.20 | 3.27610 | **+0.00822** | +0.00540 | 3275 | strong regression |
| D (mid-heavy) | 0.90/1.20/0.90 | 3.27073 | +0.00285 | +0.00003 | 3225 | regression |

W&B: A=7tjjqyyl, B=7qy4wygv, C=ryghtm6f, D=j2lieopv (clean relaunch; duplicates n43vfv7y/rftykq3p disregarded).

**Mechanism (definitive closure)**: NS-orthogonalization rescales each weight matrix's update to unit spectral norm, **normalizing scale across depths**. Cross-DEPTH asymmetry does NOT survive NS because depth doesn't change matrix shape. Cross-TYPE (#579 MERGED) DOES survive NS because shape differs (768×768 square attn vs 4·768 rectangular mlp). This validates #409 LLRD closure logic on post-#579 stack with 3-bucket non-monotone parametrization. Striking contrast: front-loaded NS-iter budget (#710 Arm C Δ=−0.00138 winner) vs front-loaded LR (Arm B +0.00196 regression) — OPPOSITE directions despite analogous parametrization, confirming NS-precision and post-NS-step-size are mechanistically separate. **Per-DEPTH Muon LR axis fully closed** across both #409 geometric and #753 3-bucket parametrizations. **67th productive-null/negative this cycle.**

**Follow-up**: edward assigned **#791 Focal loss γ sweep** — pivoting to loss-side axis, first gradient-reweighting-by-difficulty mechanism on this stack.

### ✅ edward #791 — Focal loss γ sweep — gradient reweighting by token difficulty — CLOSED 20:50 UTC productive-NEGATIVE (73rd cycle)

**Branch:** `g1r4-edward/focal-loss-gamma-sweep`
**Hypothesis**: Focal loss reweights per-token gradient by `(1−p_correct)^γ`. First gradient-reweighting-by-difficulty mechanism on this stack.

**Final 4-arm results (post-validation-fix, vs baseline 3.27036):**

| Arm | γ | run_id | val/loss | fs | Δ_vs_A | Δ_vs_baseline | Verdict |
|:---:|:---:|---|:---:|:---:|:---:|:---:|:---|
| A | 0.0 | uvkvd0ze | 3.27076 | 3225 | — | +0.00040 (drift PASS) | control |
| B | 0.5 | jrhd7y1v | 3.27416 | 3250 | +0.00340 | +0.00380 | REGRESSION |
| C | 1.0 | oo4kq11k | 3.27634 | 3300 | +0.00558 | +0.00598 | REGRESSION |
| D | 2.0 | q5qg23wb | 3.29199 | NEVER hit 3.28 | +0.02123 | +0.02163 | LARGE REGRESSION |

**Monotone γ → regression across 4/4 arms; super-linear B→C→D.** Arm D doesn't merely regress on val/loss — it actively fails to reach 3.28 by step 3350, indicating common-token anchor signal starvation under aggressive focal focusing.

**Confidence-pressure regularizer family ledger (closing):** #446 label smoothing NEG | #441 z-loss NEG | #801 position-CE bilateral NEG (B linear_up +0.00090, C linear_down +0.00228) | **#791 focal-loss monotone NEG (this)**. **Loss-side reweighting on this LM-CE stack is universally net-harmful or sub-threshold.**

**Mid-chain validation-fix:** Original implementation routed validation through focal-weighted forward; advisor directed Option 1 (gate via `self.training`). Student killed Arm B at step ~620 (~10 min sunk cost), re-ran B/C/D with fix. Arm A retained (γ=0 already on CE branch).

**Follow-up:** edward assigned **#838 AdamW multiplicative v_t floor for lm_head** — same Zipf-distributional intuition but at the preconditioner level. Mechanism-distinct from #652 (additive ε NEG): multiplicative floor caps the ratio between rare-row and frequent-row step sizes via `v_eff = max(v_t, α × v_t.median())`.

### ✅ edward #838 — AdamW multiplicative v_t floor for lm_head — CLOSED 05:25 UTC productive-NEGATIVE (77th cycle)

**Branch:** `g1r4-edward/adamw-vmin-floor` (commit `1271aa73` pushed 23:30 UTC — my earlier "branch not pushed" claim was stale view)

**Terminal 4-arm N=1 result (drift gate A PASS edge, favorable seed Δ=−0.00212):**

| Arm | mode | frac | run_id | val/loss | fs | Δ_vs_A | Δ_vs_baseline 3.27036 | Verdict |
|:---:|:---:|:---:|---|:---:|:---:|:---:|:---:|:---|
| A (ctrl) | none | 0 | 67w8k970 | 3.26824 | 3200 | — | −0.00212 (favorable seed) | drift PASS edge |
| B | median_frac | 1e-4 | zxxxagn7 | 3.26983 | 3200 | **+0.00159** | −0.00053 | marginal regression |
| C | median_frac | 1e-3 | xayaoxhz | 3.26942 | 3200 | **+0.00118** | −0.00094 | sub-threshold regression |
| D | max_frac | 1e-6 | ku2ihasf | 3.27483 | 3275 | **+0.00659** | +0.00447 | **strong regression** |

**Durable mechanism finding (Edward's terminal observation)**: For Zipf-distributed v_t on lm_head, `max(v)/median(v) > 1000` → **`max_frac=1e-6` is stronger in absolute floor magnitude than `median_frac=1e-3`**. PR's "very mild reference" label for Arm D was wrong; Arm D was actually most aggressive floor. Reading B→C→D in absolute floor magnitude (not nominal labels) gives monotone direction-incorrect: weak (A 0) → mild (C 32× median) → mildly-stronger (B 100× median) → strongest (D > 1e-3 median in absolute units). The Zipf-distributed v_t carries legitimate per-token signal; compressing strips signal.

**Composition with lm_head closed-axes ledger (13 closures)**: #441 z-loss NEG + #446 label smoothing NEG + #547 cooldown NULL + #560 β₂ NULL + #584 LR-mult NULL + #599 β₁ NEG + #618 Muon² NEG + #652 ε NEG + #663 SOAP NULL + #664 BC NULL + #668 per-row clip NEG + #791 focal NEG + **#838 multiplicative floor NEG**. **Pattern**: lm_head's optimizer-side preconditioner is structurally distinct from inner-block Hessians; AdamW with merged defaults extracts available signal. Future lm_head work should NOT target preconditioner replacements/magnitude interventions — pivot to representational mechanisms (architecture changes out of scope per launch isolation).

**Ghost-crash post-mortem**: 4 spurious concurrent `torchrun` launches by prior CC iterations not detecting still-live PID 1246502; mitigated via `wait_then_run_BCD.sh` PID-checking shim. All duplicates had `mode=none` (Arm A config) → not implicated by FloorAdamW.

**Follow-up**: edward reassigned to **#874 Embed weight init magnitude sweep** — fresh AUX-side init axis parallel to thorfinn #848 (lm_head init perturbation). Bilateral test of "init magnitude on AUX side is load-bearing".

### 🔄 frieren #900 — Anisotropic Gradient Noise: curvature-matched exploration injection [assigned 10:25 UTC]

**Branch:** `g1r4-frieren/anisotropic-grad-noise`
**Hypothesis**: Inject gradient noise with per-coordinate variance proportional to curvature (v_t for AdamW aux; NS-update RMS for body Muon). Isotropic noise (#411, CLOSED NULL) adds equal noise in all directions, disrupting sharp directions. Anisotropic variant injects MORE noise in flat (small-v_t) coordinates and LESS in sharp ones — curvature-aware exploration that anneals to zero over first 50% of training. Mechanistically distinct from #411 (isotropic), #530 (Nesterov, pre-NS), #810 (post-NS averaging, just closed), all loss-side regularization axes. The v_t-proportional noise incidentally amplifies rare-token embed coordinates (small v_t → larger noise) — orthogonal to #845 askeladd gradient pre-conditioning.

| Arm | NANOGPT_GRAD_NOISE_MAX | NANOGPT_GRAD_NOISE_ANNEAL_FRAC | NANOGPT_GRAD_NOISE_SCOPE |
|:---:|:---:|:---:|:---:|
| A | 0.0 | n/a | none (bit-clean ctrl) |
| B | 0.005 | 0.50 | aux (AdamW groups only) |
| C | 0.005 | 0.50 | all (aux + body Muon) |
| D | 0.010 | 0.30 | all (more aggressive + faster anneal) |

Signal threshold: Δ_within_vs_A ≤ −0.002 → paired-pod n=3 on best arm. ETA ~7.2h chain (A→D sequential). W&B group: `g1r4-frieren/anisotropic-grad-noise`.

**10:50 UTC — launch verified**: Arm A (`fm6v2myz`) running at step ~250/3350, val ~4.085 (early phase normal). Launch delay (assignment 10:25 UTC → first W&B logging ~10:42 UTC) resolved without intervention; frieren's silent-modus startup pattern confirmed. ETA terminal ~17:40 UTC.

**11:11 UTC — Arm A crash + clean restart on same pod**: Original Arm A run `fm6v2myz` (created 10:42 UTC) crashed at step 475 (val 3.9077). Replacement `wr4gljm4` (created 10:52 UTC, same pod `...-g1r4-frieren-5cfc58bd5b-qd9f4`) launched cleanly and is now the sole active Arm A. Running at step 400, val 3.9115 — early-phase normal. **NOT a live ghost-crash duplicate** (no concurrent torchruns); benign sequential restart pattern (mirrors thorfinn cycle 86 shape). ETA terminal still ~17:40 UTC accounting for ~10-min restart drift.

**14:01 UTC — Arm A TERMINAL + Arm B live**:

| Arm | scope | params | run ID | val/loss | Δ_vs_new_base 3.26944 | Verdict |
|:---:|:----:|:------:|--------|:--------:|:---------------------:|:--------|
| A (ctrl) | none | noise=0 | `wr4gljm4` | **3.26811** | **−0.00133** ✅ | **strong absolute below baseline** |
| B | aux | noise=0.005, anneal=0.50 | `j141b0z2` step 2050/3350 (61%) val=3.633 | TBD | TBD |
| C | all | noise=0.005, anneal=0.50 | (not launched) | TBD | TBD |
| D | all | noise=0.010, anneal=0.30 | (not launched) | TBD | TBD |

**Arm A is ctrl (noise=0 = bit-clean baseline). val=3.26811 represents favorable seed for frieren — drift sanity: Δ_vs_new_base=−0.00133 outside ±0.001 favorable-seed envelope.** This makes within-pod Δ_vs_A the load-bearing comparison; absolute baseline numbers are seed-luck biased. If Arm B (aux noise) shows Δ_vs_A ≤ −0.002, that would extract a real anisotropic-noise signal on top of an already-favorable seed. ETA Arm B terminal ~14:44 UTC.

### 🔄 fern #883 — Stochastic NS cooldown spread Goldilocks sweep (4-arm) [assigned 07:10 UTC]

**Branch:** `g1r4-fern/stochastic-ns-cooldown-spread`
**Hypothesis**: spread=2 confirmed in n=3 paired-pod (#787 merged). Goldilocks profile of the spread parameter unmapped — only spread=2 tested. Spread=1 (tighter window), spread=4, spread=6 (broader) could improve further or confirm 2 is optimal. Given mechanism conjecture (stochasticity helps when `late_peak` is locally suboptimal), there may be a sharper/flatter Goldilocks.

**4-arm matrix:**
| Arm | NANOGPT_NS_STOCHASTIC_COOLDOWN | NS range in cooldown |
|:---:|:---:|:---|
| A | 0 | Deterministic (control, old pre-#787 baseline) |
| B | 1 | {15,16,17} — tighter than merged |
| C | 4 | {12,13,...,20} — wider |
| D | 6 | {10,11,...,22} — very wide |

Signal threshold: Δ_vs_A ≤ −0.002 (note: new baseline 3.26944 is stricter than old 3.27036; any winning arm needs to beat 3.26944 in paired-pod). ETA ~7.2h. W&B group: `g1r4-fern/stochastic-ns-cooldown-spread`.

**Baseline update note**: New baseline is 3.26944 / fs=3208.33 (post-#787). In-flight chains #845 and #847 notified — their pre-staged gates remain frozen but terminal evaluation uses new baseline 3.26944.

**10:50 UTC — Arms A + B terminal (W&B verified)**:

| Arm | spread | NS range | run ID | val/loss | fs | Δ_vs_A | Δ_vs_new_base 3.26944 | Verdict |
|:---:|:-----:|:--------:|--------|:--------:|:--:|:------:|:---------------------:|:--------|
| A (ctrl) | 0 | {16} | `0um20r47` | 3.26965 | 3225 | — | +0.00021 (drift PASS edge) | clean control |
| **B** | **1** | **{15,16,17}** | `19soufaw` | **3.26781** | 3200 | **−0.00185** | **−0.00163 (sub-signal direction-correct)** | **best in group** |
| C | 4 | {12..20} | `1dv7vuty` | (in progress, step ~250) | — | — | — | TBD |
| D | 6 | {10..22} | (not launched yet) | — | — | — | — | TBD |

**Arm B verdict — sub-signal direction-correct just shy of −0.002 threshold**: Δ_vs_A=−0.00185 (within-pod) is 92% of the −0.002 candidate gate. Δ_vs_new_base=−0.00163 (absolute below merged 3.26944). spread=1 (tighter window {15,16,17}) outperforms merged spread=2 ({14,15,16,17,18}) numerically in N=1. Mechanism reading: even tighter stochasticity around the late_peak NS=16 may extract more gain than broader spread.

**Goldilocks profile shape** (preliminary, awaiting C/D):
- spread=0 (deterministic) → 3.26965 (ctrl)
- spread=1 → **3.26781 (best)**
- spread=2 → 3.26944 (merged baseline, from #787 paired-pod n=3 mean)
- spread=4 → TBD
- spread=6 → TBD

**Critical caveat**: chain on **OLD pre-#787 stack** (#883 was assigned 07:10 UTC before #787 merge propagation). N=1 Δ_vs_A=−0.00185 is a within-arm comparison so robust to stack version, but the absolute val numbers are NOT directly comparable to merged baseline 3.26944 (different recipe). The paired-pod n=3 confirmation post-rebase will be the dispositive test.

**Pre-staged outcomes**:
1. Arm B confirmed at paired-pod (Δ ≤ −0.001 within-pod, mean ≤ 3.26944): **merge candidate** — spread=1 replaces spread=2 in merged stack as a "tighter Goldilocks"
2. Arm B collapses at paired-pod (Δ → 0 or positive): productive-NULL closure of spread axis; spread=2 confirmed as merged Goldilocks peak; cross-PR-merge protocol applies (rebase + re-run on new stack)
3. Arm C ≤ Arm B at terminal (broader wins): would falsify "tighter is better" reading; suggests spread axis has different shape than predicted

Awaiting Arm C terminal (~13:00 UTC if launched ~10:50 UTC) and Arm D launch.

**14:01 UTC — Arms A/B/C TERMINAL + Arm D live**:

| Arm | spread | NS range | run ID | val/loss | Δ_vs_A | Verdict |
|:---:|:-----:|:--------:|--------|:--------:|:------:|:--------|
| A (ctrl) | 0 | {16} | `0um20r47` | 3.26965 | — | clean control |
| **B** | **1** | **{15,16,17}** | `19soufaw` | **3.26781** | **−0.00184** | sub-signal direction-correct best |
| C | 4 | {12..20} | `1dv7vuty` | **3.26864** | **−0.00101** | direction-correct sub-threshold |
| D | 6 | {10..22} | `fdhuymy2` step 2600/3350 (78%) val=3.368 | TBD | TBD |

**B < C < A ordering confirmed**: tighter spread (B, spread=1) is best, broader spread (C, spread=4) is intermediate, deterministic (A, spread=0) is worst — clear monotone pattern in direction of stochasticity scope. Goldilocks profile shape emerging:
- spread=0 → 3.26965 (worst, ctrl)
- spread=1 → **3.26781 (best so far)** Δ_vs_A=−0.00184
- spread=2 → 3.26944 (merged baseline from #787 n=3)
- spread=4 → 3.26864 Δ_vs_A=−0.00101
- spread=6 → TBD (Arm D, ETA ~14:26 UTC)

If Arm D continues the monotone trend (worse than C at spread=6 i.e. broader-than-optimal), this would close the bracket and confirm spread=1 as the Goldilocks peak (vs current spread=2). Important caveat: chain still on OLD pre-#787 stack — within-arm Δ robust, but absolute val numbers and rebase-required for merge consideration. Pre-staged outcomes unchanged.

---

### 🔄 thorfinn #880 — Muon² body v_t ablation (4-arm beta2 sweep + structural disable) [assigned 06:35 UTC]

**Branch:** `g1r4-thorfinn/muon-v2-body-ablation`
**Hypothesis**: Body Muon already runs Muon² (Adam-style v_t pre-NS preconditioning) with `beta2=0.999`, `eps=1e-8` — never independently swept or ablated on this stack. Two sub-questions: (1) **Is the body Muon² v_t denominator load-bearing on the post-#708 stack?** (Arm B disable test), (2) **If load-bearing, is `beta2=0.999` the right time constant?** (Arms C, D bracket).
| Arm | NANOGPT_MUON_BODY_BETA2 | mechanism interpretation |
|:---:|:---:|:---|
| A | 0.999 (ctrl) | bit-identical at default; current Muon² active |
| B | 0.0 | **disable Muon² entirely** — pure momentum-then-NS, structural pruning ablation |
| C | 0.99 | 10× faster v_t adaptation |
| D | 0.9999 | 10× slower v_t adaptation |
Implementation: ~10 LOC — env var + 3-line guard around v_t block (`if beta2 > 0.0:`) + Muon constructor kwarg + sanity print + W&B config. Bit-identical fallback at beta2=0.999.

**Mechanism-distinctness**: #618 closed Muon² for **lm_head** (different parameter family); #560 closed AdamW β₂ for **AUX** (different optimizer); #810 frieren in-flight is **post-NS** momentum (different mechanism level); #789 tanjiro in-flight is NS polynomial **degree** (NS internals). This PR's mechanism (body v_t **pre-NS** denominator) is orthogonal to all of these.

**Pre-staged outcomes (most informative)**:
1. **B catastrophic (Δ ≥ +0.005)**: Muon² is structurally essential — close + tighter beta2 sweep
2. **B near-neutral (|Δ| ≤ 0.0015)**: **STRUCTURAL SIMPLIFICATION CANDIDATE** — Muon² redundant on body, can be pruned. Productive-positive close with stack simplification finding.
3. **B mild regression + C/D bracket A**: partial-redundancy finding (parallels #487 NS-cooldown joint-pruning)
4. **C or D best with Δ ≤ −0.002**: positive signal on beta2 axis → paired-pod n=3 on winner

**Risk class**: LOW. Pre-NS guard around existing v_t block; cannot affect NS dynamics, model architecture, eval. Worst case (B catastrophic) is itself a durable finding (validates Muon² body structure).

ETA ~7h chain. Edward #874 (embed init magnitude) and #880 thorfinn are both stack-tuning/ablation 4-arms running in parallel — orthogonal axes (AUX init scale vs body Muon² internals).

**10:50 UTC — Arms A + B terminal (W&B verified)**:

| Arm | beta2 | run ID | val/loss | fs | Δ_vs_A | Δ_vs_new_base 3.26944 | Verdict |
|:---:|:-----:|--------|:--------:|:--:|:------:|:---------------------:|:--------|
| A (ctrl) | 0.999 | `tg80f0tp` | 3.26984 | 3225 | — | +0.00040 (drift PASS) | clean control |
| **B** | **0.0** | `5xxedhqp` | **3.27022** | 3225 | **+0.00038** | +0.00078 | **near-neutral — STRUCTURAL SIMPLIFICATION CANDIDATE edge** |
| C | 0.99 | `3ursyjua` | (in progress, step ~400) | — | — | — | TBD |
| D | 0.9999 | (not launched yet) | — | — | — | — | TBD |

**Arm B verdict — pattern 2 (NEAR-NEUTRAL)**: Δ_vs_A=+0.00038 falls in the pre-staged "near-neutral |Δ| ≤ 0.0015: STRUCTURAL SIMPLIFICATION CANDIDATE" band. Body Muon² v_t (Adam-style pre-NS preconditioning at β₂=0.999) is **NOT load-bearing on the post-#787 stack** — disabling it entirely costs only +0.00038 within-pod, well within drift noise. Major durable finding if confirmed: Muon² body machinery could be pruned without measurable val regression.

**Implications**:
1. **Stack-simplification candidate**: removing body Muon² v_t saves ~3 LOC + 1 buffer (per-matrix `exp_avg_sq`) without measurable cost.
2. **C/D interpretation gates**: if C (β₂=0.99) or D (β₂=0.9999) also ≈ A, confirms body v_t denominator is fully inert across reasonable β₂. If either bracket beats A (Δ ≤ −0.002), the β₂=0.999 default is suboptimal and there's an extractable time-constant axis.
3. **Cross-axis fence**: composes with #560 (per-AUX β₂ NEG/NULL), #712 (per-TYPE body β₂ NULL), #97 (global β₂ at 0.999 optimal) — all point to "AdamW/Muon² β₂ axis is essentially flat on this stack". Arm B simplification is the most informative new datum because it tests **structural presence**, not magnitude tweaks.

Awaiting Arm C terminal (~12:30 UTC if launched ~10:50 UTC) and Arm D launch.

**14:01 UTC — Arms A/B/C TERMINAL + Arm D live — STRUCTURAL SIMPLIFICATION CANDIDATE CONFIRMING**:

| Arm | beta2 | run ID | val/loss | Δ_vs_A | Verdict |
|:---:|:-----:|--------|:--------:|:------:|:--------|
| A (ctrl) | 0.999 | `tg80f0tp` | 3.26984 | — | clean control |
| B | 0.0 | `5xxedhqp` | 3.27022 | +0.00038 | near-neutral |
| C | 0.99 | `3ursyjua` | **3.26999** | **+0.00015** | **near-neutral confirms** |
| D | 0.9999 | `w9afvz9a` step 2750/3350 (82%) val=3.333 | TBD | TBD |

**Arms A/B/C all clustered within ±0.00038 of each other** (Δ_vs_A: B +0.00038, C +0.00015). Cross-axis confirmation: not only is disable (B=0.0) near-neutral, but 10× faster v_t adaptation (C=0.99) is also near-neutral. **Body Muon² v_t preconditioning is structurally inert across reasonable β₂ values on post-#787 stack.** If Arm D (β₂=0.9999, 10× slower) also lands within ±0.001 of A, this MERGES the structural simplification candidate: remove body Muon² v_t buffer entirely (~3 LOC, ~12MB GPU memory savings on body matrices). ETA Arm D terminal ~14:21 UTC.

**14:21 UTC — Arm D TERMINAL — PATTERN 4 SIGNAL (NOT structural simplification, slow-adapt winner)**:

| Arm | β₂ | run ID | val/loss | Δ_vs_A (3.26984) | Δ_vs_new_base 3.26944 | Verdict |
|:---:|:---:|---|:---:|:---:|:---:|:---:|
| A (ctrl) | 0.999 | `tg80f0tp` | 3.26984 | — | +0.00040 (drift PASS) | clean control |
| B | 0.0 | `5xxedhqp` | 3.27022 | +0.00038 | +0.00078 | near-neutral (disable inert) |
| C | 0.99 | `3ursyjua` | 3.26999 | +0.00015 | +0.00055 | near-neutral (faster v_t inert) |
| **D** | **0.9999** | **`w9afvz9a`** | **3.26741** | **−0.00243** ✅ | **−0.00203** ✅ | **SIGNAL — clears −0.002 within-pod threshold AND new baseline by 0.00203** |

**Re-reading of pre-staged outcomes**: Pattern 4 fires ("C or D best with Δ ≤ −0.002 → positive signal on beta2 axis → paired-pod n=3 on winner"). The bracket reveals:
- **Disable (B) is structurally redundant on its own** — still a legitimate simplification candidate at +0.00038
- **Faster adaptation (C) is also inert** at +0.00015
- **Slower adaptation (D) at β₂=0.9999 is the actual extractable signal**, suggesting body Muon² v_t benefits from a long-time-constant denominator stabilization rather than the merged β₂=0.999

**Mechanism reading**: At β₂=0.9999, v_t half-life ~6900 steps >> training length 3350 — effectively a running global denominator that doesn't track local gradient magnitude shifts. This is closer to "pure SGD-style preconditioning with a slowly-evolving denominator" than to "adaptive preconditioning". The denominator stabilization benefits body Muon² body-of-NS-input rather than tracking per-coordinate magnitude (which NS would orthogonalize away anyway).

**Posted #880 visibility comment 14:20 UTC**: requested student to (1) confirm stack version (post-#787 or OLD), (2) post terminal SENPAI-RESULT, (3) proceed to paired-pod n=3 on Arm D vs Arm A. Pre-staged paired-pod gates frozen against new baseline 3.26944. Awaiting student SENPAI-RESULT.

**Composability with structural-simplification reading**: Both findings are durable. If Arm D collapses at paired-pod n=3 (consistent with 12 prior precedent paired-pod collapses), the disable simplification candidate (B near-neutral) is still merge-discussable on code-pruning grounds (~3 LOC, ~12MB memory). If Arm D holds, β₂=0.9999 becomes the new merged default and disable is moot.

### 🔄 edward #874 — Embed weight init magnitude sweep (4-arm) [assigned 05:25 UTC]

**Branch:** `g1r4-edward/embed-init-magnitude`
**Hypothesis**: `model.embed.weight` initialized via `w.normal_()` = N(0,1) (line 896). Tonight's emerging "tiny perturbation of AUX defaults wins" theme (#847 Goldilocks at λ=0.001 + #848 Goldilocks at std=0.0001) suggests N(0,1) embed default may not be empirically optimal. Mechanism: embed init magnitude affects first-layer activation scale → body Muon gradient backflow → step-0 trajectory. NS-orthogonalization (body Muon) absorbs body init magnitude effect within ~100 steps (#812 NULL), but embed is AdamW-managed (NOT NS-absorbed) — different mechanism class.
| Arm | NANOGPT_EMBED_INIT_SCALE | expected ‖embed‖_F |
|:---:|:---:|:---:|
| A | 1.0 (ctrl) | 6213 |
| B | 0.5 | 3107 |
| C | 0.7 | 4349 |
| D | 1.5 | 9320 |
Implementation: ~3 LOC, `w.normal_()` followed by `if scale != 1.0: w.mul_(scale)`. Bit-identical fallback at scale=1.0. Mechanism-orthogonal to #812 (body), #847 (drift-suppression-from-init), #848 (lm_head zero-perturbation). Symmetric to #393 ADAMW_EMBED_LR_MULT=1.5 MERGED but on init axis.

ETA terminal ~12-14h sequential.

**07:39 UTC relaunch on new stack**: Arm A on OLD code (val=3.26845, fs=3200, W&B `wccdjzbz`) correctly INVALIDATED by edward — pre-#787 stack, no stochastic NS cooldown. Hard-reset to advisor branch + cherry-picked single embed-init commit → clean rebase. All 4 arms now include `NANOGPT_NS_STOCHASTIC_COOLDOWN=2`. Drift gate now |Δ vs 3.26944| ≤ 0.003. OLD-code Arm A drift sanity passes (Δ=−0.00191 vs OLD baseline 3.27036).

**07:58 UTC re-launch CORRECTION (edward self-discovery + recovery)**: Edward's 07:39 UTC cherry-pick happened on detached HEAD; named branch was never moved. The chain re-launch at 07:39 UTC was therefore on OLD code (W&B `s8nf2rg9` reached step ~440/3350 before discovery, killed 07:53 UTC). Edward correctly hard-reset `g1r4-edward/embed-init-magnitude` to `62e156f5`, cherry-picked single embed-init commit → `b48725b6`, force-pushed, and re-launched 4-arm chain at 07:55 UTC. Verified via `grep STOCHASTIC|EMBED_INIT_SCALE train_gpt_simple.py` returning all expected lines on the new checkout. Arm A live: W&B `wxfyjif6`, step 12/3350. **New ETA ~15:00 UTC.** GPU cost ~26 min on invalid runs (<1% of chain budget). Detached-HEAD cherry-pick trap noted as a future-launch hazard.

**09:55 UTC W&B-verified — Arm A terminal, direction-WRONG but within drift**: Arm A (`wxfyjif6`) finished val=**3.27117**, Δ_vs_new_base 3.26944 = **+0.00173** (drift PASS ±0.003). Arm A is the ctrl (init_scale=1.0 = N(0,1) default) — direction-wrong is unfavorable seed, NOT mechanism (Arm A by construction is bit-clean to merged stack at the pre-`mul_` gate). Mid-trajectory chain on Arms B/C/D will produce within-pod Δ_vs_A comparisons; absolute baseline comparison less reliable given +0.00173 drift. Chain continues; Arm B in flight.

**10:08 UTC — Arm B (`kjqev5sg`, scale=0.5) launched 09:49 UTC, running step 475/3350 (14%)**. Stale_wip auto-flag posted, addressed as false-positive — chain progressing per normal silent modus operandi. Posted #874 visibility-check comment. ETA Arm B terminal ~12:35 UTC, full chain (A→D sequential) ETA ~15:00 UTC. Chain on NEW post-#787 stack already — no cross-PR rebase needed at terminal if gates pass.

**12:38 UTC — Arm B TERMINAL + Arm C live**:

| Arm | scale | run ID | val/loss | Δ_vs_A (ctrl 3.27117) | Δ_vs_new_base 3.26944 |
|:---:|:---:|---|:---:|:---:|:---:|
| A (ctrl) | 1.0 | `wxfyjif6` | 3.27117 | — | +0.00173 (unfavorable seed) |
| B | 0.5 | `kjqev5sg` | **3.26978** | **−0.00139** ✅ direction-correct sub-threshold | +0.00034 marginal |
| C | 0.7 | `swk8ntvs` | running step 1000/3350 (30%) | TBD | TBD |
| D | 1.5 | pending | — | — | — |

Arm B Δ_vs_A=−0.00139: direction-correct but sub-signal (below −0.002 within-pod threshold). Mechanism reading at half-scale init: ‖embed‖_F ≈ 3107 (half of N(0,1) default 6213) → smaller initial activation magnitude → mildly different early-trajectory body gradient profile. Matches pre-staged interpretation #2 ("monotone-favorable in inverse-scale"). Arm C terminal ETA ~14:55 UTC, Arm D ~17:00 UTC. Posted #874 stale_wip false-positive ack comment. **Second stale_wip false-positive on this PR** (10:08 + 12:38) — flag fires whenever chain progresses silently between SENPAI-RESULT markers; expected modus operandi for sequential 4-arm chains.

**14:01 UTC — Arm C TERMINAL + Arm D live**:

| Arm | scale | run ID | val/loss | Δ_vs_A (ctrl 3.27117) | Δ_vs_new_base 3.26944 |
|:---:|:---:|---|:---:|:---:|:---:|
| A (ctrl) | 1.0 | `wxfyjif6` | 3.27117 | — | +0.00173 (unfavorable seed) |
| B | 0.5 | `kjqev5sg` | 3.26978 | −0.00139 ✅ direction-correct sub-threshold | +0.00034 marginal |
| C | 0.7 | `swk8ntvs` | **3.27057** | **−0.00060** direction-correct sub-threshold | +0.00113 above baseline |
| D | 1.5 | `t6kzt6lx` step 800/3350 (24%) val=3.694 | TBD | TBD |

**Pattern emerging in inverse-scale direction**: Arm B (scale=0.5) Δ_vs_A=−0.00139 > Arm C (scale=0.7) Δ_vs_A=−0.00060 — modestly monotone-favorable, with B best at half-scale. Arm D (scale=1.5, ‖embed‖_F ≈ 9320) is the upper-scale arm and would close the bilateral profile; pre-staged interpretation #1 (D worse than A) likely. ETA Arm D terminal ~15:29 UTC.

### 🗃️ edward #838 — assignment text (archived)

**Branch:** `g1r4-edward/adamw-vmin-floor`
**Hypothesis**: lm_head AdamW `v_t` is Zipf-distributed across vocab rows. ε=1e-10 doesn't practically floor rare rows → extreme per-coord step magnitude variance. Multiplicative floor `v_eff = max(v_t, α × v_t.median())` compresses this variance at sqrt-time (without mutating state buffer). Mechanism-distinct from #652 (additive ε in denom — irrelevant to frequent rows; doesn't cap rare-vs-frequent step-size ratio).
**4-arm matrix** (single-seed Phase 1):
- A: mode=none, frac=0.0, lm_head (control, fused=False)
- B: median_frac=1e-4, lm_head (mild floor — caps rare rows at 100× median step)
- C: median_frac=1e-3, lm_head (stronger — caps at ~32× median step)
- D: max_frac=1e-6, lm_head (max-anchored — caps at 1000× max-row step)
**Risk class:** LOW (AdamW aux only; cannot affect body Muon or NS). Worst case: fused→non-fused ~1-2% step time overhead.
**Decision gate:** Arm A drift ≤ 0.003 vs baseline (verifies fused/non-fused equivalence) → proceed. Best arm Δ_vs_A ≤ −0.002 AND vs baseline → positive signal, paired-pod n=3 follow-up.
**23:06 UTC status-check** (PR was flagged stale_wip at 2h7m post-assignment): Pod alive, GPU 100%, run `67w8k970` Arm A at step 2900/3350 val=3.318, **3 ghost crashes** (`sd072zai`/`nbk1nc3l`/`qpb3n12z`) all logged Arm A config. Branch had only assignment commit; local edits unpushed. Posted advisor comment requesting push + ghost-crash explanation + drift-gate check.

**04:01 UTC progress refresh #3** (W&B-verified; 3/4 arms finished, Arm D running):

| Arm | mode | frac | run ID | state | step | val/loss | Δ_within_vs_A | Δ_vs_baseline 3.27036 |
|:---:|:---:|:---:|---|:---:|:---:|:---:|:---:|:---:|
| A (ctrl) | none | 0 | `67w8k970` | finished | 3350 | 3.26820 | — | **−0.00216 favorable seed** (drift PASS edge) |
| B | median_frac | 1e-4 | `zxxxagn7` | finished | 3350 | 3.26980 | +0.00160 | −0.00056 (mild regression vs A; beats baseline) |
| C | median_frac | 1e-3 | `xayaoxhz` | **finished** | 3350 | **3.26942** | **+0.00122** | **−0.00094** |
| D | max_frac | 1e-6 | `ku2ihasf` | running | 1340/3350 (~40%) | 3.568 in-prog | TBD | TBD |

**Within-pod direction-incorrect pattern (3-arm)**: Both floored arms regress vs Arm A by Δ_within > 0 (B=+0.00160, C=+0.00122). C is mildly non-monotone (10× stronger median floor is *less* destructive than 10× weaker median floor). The apparent Δ_vs_baseline=−0.00216 on Arm A is favorable-seed luck, not mechanism: B/C running at the "true" A-equivalent level, A drifted ~0.0012 below it within ±0.003 envelope.

**Mechanism reading (3-arm, leans productive-NEG)**: v_t floors on lm_head interfere with normal AdamW preconditioning rather than helping. Arms B/C both direction-incorrect vs Arm A. The Zipf step-size variance compression hypothesis is currently disconfirmed for median-anchored floors — the variance is load-bearing, not noise to suppress.

**Arm D pre-staged interpretations** (max_frac=1e-6 — distinct geometry: caps max instead of clamping median):
1. **D ≈ A or D < A within-pod (Δ_within ≤ 0)**: max-frac at 1e-6 genuinely beneficial → paired-pod n=3 candidate
2. **D > A but < B**: max-frac geometry better than median-frac → null/marginal with mechanism comment
3. **D ≈ B/C** (most likely given pattern): productive-NEG closure of "Zipf-direction v_t floor" mechanism family

**Implementation hygiene — branch STILL NOT PUSHED** (verified via 300 remote branches scanned): only PR tonight where this is happening — askeladd #845 pushed `f7b33e0`, thorfinn #848 pushed `63a2953`, but edward #838 branch only has assignment commit `0e92d05`. Requested student to push implementation in advisor comment.

**Ghost crashes**: 4 confirmed Arm A retries (`sd072zai`/`nbk1nc3l`/`qpb3n12z`/`pdi1ao34`). All config frac=0/mode=none = identical to Arm A. Infrastructure retries, not new experimental arms.

ETA terminal ~06:00-06:30 UTC. Posted #838 progress refresh #3 comment.

### ✅ edward #550 — Muon WD cooldown reduction — CLOSED 02:50 UTC productive-NULL (paired-pod collapse)

**Single-seed N=1 winner** (Arm D WD=0 Δ=−0.00337) **collapsed to paired-pod sub-threshold**:

| Pod | Arm A (WD=0.025) | Arm D (WD_final=0) | Δ |
|---|---:|---:|---:|
| pod0 | 3.27328 | 3.27238 | −0.00090 |
| pod1 | 3.27247 | 3.27119 | −0.00127 |
| pod2 | 3.27138 | 3.27085 | −0.00054 |
| **mean (n=3)** | **3.27238** | **3.27147** | **−0.00090** |

**Gates**: Gate 1 (within-pod mean Δ ≤ −0.002) **FAIL** at −0.00090 (half threshold). Gate 2 (mean val_D ≤ 3.27174) PASS at 3.27147. Gate 3 (stat-rule (3.28 − 3.27147) × √3 = 0.01477 ≥ 0.004) PASS. Drift gates: A mean 3.27238 vs baseline 3.27174 = +0.00064 (sub-drift PASS). Direction-correct 3/3 pods — real mechanism, not seed luck — but magnitude insufficient. **6th cycle precedent for single-seed→paired-pod collapse** (#344, #351, #408, #487, #506, #550). **WD-axis now bilaterally fenced** on this stack: ADDITION (#554 embed, #593 lm_head/scalar/joint, #483 Muon warmup) all NEG; REDUCTION (#550) sub-threshold NULL. Cooldown-window precision is structural, not WD-friction-bound. **45th productive-null/negative this cycle.**
**Follow-up**: edward assigned **#639 Embed-stack joint redundancy ablation** — joint ablation of EMBED_COOLDOWN_SHAPE=linear_floor (#235 merged) and ADAMW_EMBED_LR_MULT=1.5 (#393 merged); both raise late-phase embed effective LR via different mechanisms, one may be redundant given the other. Pure env var permutation (no code).

---

## Research theme — current cycle

**51 productive-null/negative results + 10 merged improvements**. The 10th merge is **#708 per-group grad-clip BODY=10/AUX=5** (paired-pod n=3 mean Δ=−0.00140; mean(B,n=3)=3.27036 beats baseline 3.27070 by 0.00034; fs improved 3225→3216.67). Aux-side mechanism confirmed: tighter aux L2 clip bounds per-coord outlier propagation in AdamW `m/√v`; body Muon insensitive (NS absorbs). The strongest confirmed findings:
1. **The cooldown phase is load-bearing signal, not noise.** Any mechanism that blends, averages, or smooths parameters/gradients during the cooldown window hurts:
   - #436 weight-EMA → productive-NEGATIVE
   - #434 Lookahead → productive-NEGATIVE (Muon wrapping 4.5× worse)
   - #399 AdEMAMix → productive-null
   - #419 Cautious AdamW → productive-null
2. **Loss-side auxiliary regularization is exhausted.** Softcap c=15 is optimal (#354) and already bounds the logit-distribution axes that z-loss (#441) and label smoothing (#446) target. Both regress monotonically.
3. **Additive regularization always fails on this stack.** AGC, GC, gradient noise, label smoothing, z-loss — all hurt.

**Current open questions** (in-flight):
1. ~~Does NS-iter warmup (low → 12 over first N%) extract benefit from early gradient noise?~~ **#506 CLOSED productive-NEGATIVE** — all 3 pods regress, 5th single-seed→paired-pod collapse precedent; NS-axis program fully fenced.
2. ~~Does per-block NS iter allocation (by aspect ratio) help over uniform NS=12?~~ **#543 CLOSED productive-NULL** — NS=12 saturation robust to spatial reallocation; codebase has limited surface (only 2-of-6 Muon blocks non-square).
3. ~~Does lm_head cooldown SHAPE (cosine / late_peak / linear_floor) matter vs default linear?~~ **#547 CLOSED productive-NULL** — lm_head wants monotonic linear; late_peak doesn't cross-axis transfer from NS.
4. Does Muon WD reduction during cooldown extract precision-window gain? (**#550, edward — N=1 Arm D WD=0 Δ=−0.00337 strong winner candidate; sent back for paired-pod n=3 confirmation, identical protocol to #487; non-linear axis response (only WD=0 extracts gain) is structurally novel; either fresh merge candidate or 5th single-seed→paired-pod collapse**)
5. ~~Does adding small WD on AdamW embed during cooldown help?~~ **#554 CLOSED productive-NEGATIVE** — clean monotone regression; embed group rejects added WD during cooldown; bilateral asymmetry with #550 (body benefits from REDUCED WD, embed rejects ADDED WD).
6. ~~Does per-group AdamW β₂ asymmetry extract per-group second-moment time-constant gains?~~ **#560 CLOSED productive-NULL/NEGATIVE** — embed β₂=0.999 regression (+0.00359), β₂=0.95 null (+0.00089), D inert; AdamW-internal axis family substantially exhausted.
7. Does per-group cooldown WINDOW LENGTH asymmetry around 0.70 baseline extract gains? (#568, nezuko — fresh structural axis paralleling SHAPE work)
8. Is the *entire* NS-cooldown sub-stack jointly load-bearing even though each component is individually redundant? (#487 follow-up, tanjiro — joint-pruning ablation, structurally novel compound subtraction)

**Stack convergence signal**: 28 productive-null/negative results. The baseline at 3.27174 is well-tuned. New wins will likely come from:
1. **"Less constraint early" schedule cluster** (in flight): NS-iter warmup (#506), β₁ warmup (#514) — early-phase schedule axes. WD warmup (#483) and embed-LR warmup (#489) both closed productive-NEGATIVE — bilateral structural finding.
2. **Late-phase cooldown shape**: body Muon LR cooldown shape (#520 thorfinn) — targeting the load-bearing 30% cooldown window.
3. **Stack simplification** — #487 paired-pod n=3 CLOSED productive-NULL (Arm B drop NS_ITERS_COOLDOWN: mean Δ=+0.00003, classified redundant but not improved). All three sub-stack components (NS_ITERS_COOLDOWN, NS_COOLDOWN_SHAPE=late_peak, NS_COEF_SCHEDULE=linear_ramp_down) are individually classified as redundant under their respective single-drop tests; **joint-drop interaction is untested** — that's the natural next step (follow-up assigned to tanjiro). If joint-drop ≈ baseline, the entire NS-cooldown machinery can be retired.
4. **Non-AdamW body-Muon mechanism axis** — Nesterov-Muon (#530, nezuko new) targets lookahead-before-NS, complementing pre-stage NS scheduling (#506) and shape (#520). The AdamW-internal three-axis ablation is closing (#442 NEGATIVE + #474 NEGATIVE + #490 null = body-side is the natural pivot).
5. **Bilateral regularization closure (from #483 + #489)**: both ADD (17 axes) and REDUCE-by-warmup (Muon-WD, embed-LR) regularization fail → early-training window is bilaterally well-tuned.
6. **Aux-group coupled system insight (from #477)**: future aux-group mechanism experiments should default to "all aux" scope; single-group regresses.
7. **Embed sparsity structural insight (from #474)**: `(g − m)²`-based second moments fail on embed group; `g²`-only formulations (AdamW, Yogi) are safe.

---

## Recently closed experiments

| PR | Student | Hypothesis | Outcome |
|---|---|---|---|
| #812 | thorfinn | Orthogonal Haar-measure init for body Muon matrices | CLOSED productive-NULL (76th cycle; full post-#708 stack; A=3.27023 drift PASS, B Frob-match gain=0.57=−0.00036 NULL, C gain=0.33=+0.00353 mild regression, D full Haar gain=1.0=−0.00043 NULL; step-0 val/loss identical across arms confirming init affects only body spectrum; NS-orthogonalization dominates body weight spectrum shaping within first few hundred steps; body-init axis fully characterized; future init work pivots to AUX side via #848 lm_head non-zero init) |
| #808 | alphonse | Distance-from-init WD for body Muon (anchor θ₀ vs zero) | CLOSED productive-NULL (75th cycle; A=3.27126 ctrl drift PASS, B λ=0.025 init=+0.00051 NULL, C λ/2=+0.00376 regression, D 2λ=+0.00286 regression; mechanism alive but val signal absorbed by NS-orthogonalization; body-Muon WD axis CLOSED across all 5 dimensions; pivots to AUX side via #847) |
| #801 | askeladd | Position-weighted CE (per-position loss aggregation) | CLOSED productive-NEGATIVE BILATERAL (74th cycle; A=3.26994 ctrl drift PASS, B linear_up α=0.5=+0.00132 sub-signal, C linear_down α=0.5=+0.00228 regression, D linear_down α=1.5=+0.00600 large regression; both directions regress; CE-shape regularizer family CLOSED across 4 orthogonal axes #446 #441 #791 #801; future loss-side work should target STRUCTURAL mechanisms not CE shape) |
| #791 | edward | Focal loss γ sweep — gradient reweighting by token difficulty | CLOSED productive-NEGATIVE monotone (73rd cycle; A=3.27076 ctrl drift PASS, B γ=0.5=+0.00340, C γ=1.0=+0.00558, D γ=2.0=+0.02123 NEVER hit 3.28 target; super-linear regression; loss-side reweighting universally net-harmful on LM-CE; confidence-pressure family closure) |
| #719 | alphonse | Pruning ablation of schedule mechanisms (NS_COOLDOWN_SHAPE / NS_COEF_SCHEDULE / EMBED_COOLDOWN_SHAPE) | CLOSED productive-NULL (64th cycle; no arm Δ ≤ −0.001; B=+0.00183 NS_COOLDOWN_SHAPE essential, C=+0.00127 NS_COEF_SCHEDULE null-band, D=+0.00247 EMBED_COOLDOWN_SHAPE most essential; post-#579 stack well-composed; schedule-mechanism pruning axis fenced) |
| #618 | fern | Muon² for lm_head (replace AdamW) | CLOSED productive-NEGATIVE (3/3 Muon arms MISS 3.28 target; monotonic-LR pattern, no interior minimum; mechanism: NS homogenizes Zipf-distributed vocab-freq Hessian structure lm_head needs; "Replace AdamW for lm_head" axis fully closed; 46th this cycle) |
| #550 | edward | Muon WD cooldown reduction (paired-pod) | CLOSED productive-NULL (mean Δ=−0.00090 FAIL Gate 1, val=3.27147 PASS Gate 2, stat-rule=0.01477 PASS Gate 3; direction-correct 3/3 pods but magnitude insufficient; 6th cycle paired-pod collapse precedent; WD-axis bilaterally fenced; 45th this cycle) |
| #599 | alphonse | Per-group AdamW β₁ time-constant sweep | CLOSED productive-NEGATIVE (B=+0.00399 regression, C β₁=0=+0.00513, D β₁=0.90=+0.00177; both directions regress; per-group AdamW family fully exhausted; 44th this cycle) |
| #560 | alphonse | Per-group AdamW β₂ asymmetric sweep (embed/lm_head decoupling) | CLOSED productive-NULL/NEGATIVE (B=+0.00089 null, C β₂_embed=0.999=+0.00359 regression, D inert; AdamW-internal family exhausted; 38th this cycle) |
| #483 | thorfinn | Muon WD warmup frac∈{0.05,0.10,0.20} | CLOSED productive-NEGATIVE (monotone: +0.00080/+0.00258/+0.00400; body WD=0.025 is load-bearing from step 0; bilateral WD-level closure) |
| #474 | edward | AdaBelief aux scope sweep | CLOSED productive-NEGATIVE (B=+0.041/D=+0.035 catastrophic embed sparsity; C=+0.002 mild; second-moment-formulation axis closed) |
| #477 | fern | OrthoGrad aux scope sweep | CLOSED productive-null (D=−0.00080 short of −0.002; non-monotonic: singles regress, combined recovers; aux groups coupled system) |
| #470 | frieren | NS iterations normal phase NS∈{8,10,12,14} | CLOSED productive-null (wide plateau [10,14]; NS=8 below floor; NS step-time flat ±1%) |
| #454 | nezuko | lm_head/scalar linear_floor cooldown | CLOSED productive-null (best Δ=−0.00098, half threshold; embed-specific mechanism, not aux-generic) |
| #442 | alphonse | Adam-atan2 b∈{0.3,1.0,3.0} | CLOSED productive-NEGATIVE (D=+0.010 missed 3.28; all worse than ε-based AdamW; magnitude-transform axis closed) |
| #441 | tanjiro | Logit Z-loss λ∈{1e-5,1e-4,1e-3} | CLOSED productive-NEGATIVE (B=+0.00211/C=+0.00151/D=+0.022 missed 3.28; softcap c=15 already bounds logits, z-loss redundant) |
| #446 | thorfinn | Label smoothing α∈{0.05,0.1,0.2} | CLOSED productive-NEGATIVE (monotone: +0.046/+0.102/+0.223; stack already well-regularized) |
| #434 | edward | Lookahead scope sweep | CLOSED productive-NEGATIVE (all arms regression-monotone; Muon wrapping 4.5× worse) |
| #436 | frieren | Weight-EMA (Polyak averaging) | CLOSED productive-NEGATIVE (damage monotone with window; cooldown is signal not noise) |
| #419 | askeladd | Cautious AdamW (all scopes) | CLOSED productive-null (regression all scopes; β₁=0.80 leaves little room for cautious mask) |
| #409 | thorfinn | Per-block LR decay (LLRD for Muon) | CLOSED productive-null (NS normalizes depth-dependent LR) |
| #411 | alphonse | Gradient noise injection | CLOSED productive-null (noise clearly hurts; stack already near noise floor) |
| #407 | tanjiro | AdamW β₂ sensitivity | CLOSED productive-null (symmetric valley around β₂=0.99) |
| #402 | frieren | Gradient Centralization scope | CLOSED productive-null (NS already mean-centers block gradients) |
| #399 | edward | AdEMAMix on AdamW groups | CLOSED productive-null (slow-EMA redundant with β₂=0.99) |

---

## Closed axes (do not re-assign)

**Optimizer-internal / Adam-family**:
- **β₁ per-group: CLOSED productive-NEGATIVE** (#599; B=+0.00399/C=+0.00513/D=+0.00177; both directions; **per-group AdamW family fully exhausted** — β₁ + β₂ + WD all closed-NEGATIVE; only embed-LR-mult #393 extracted gain)
- β₂ per-group asymmetry (embed swept 0.95/0.999, lm_head 0.999): CLOSED productive-NULL/NEGATIVE (#560; embed β₂=0.999 +0.00359 regression, β₂=0.95 +0.00089 null, D inert; AdamW-internal family substantially exhausted)
- ε per-group: all swept, β₂=0.99/ε=1e-10 confirmed
- WD per-group: **bilaterally fenced — ADDITION (#554/#593/#483) all NEG; REDUCTION (#550, n=3 paired) sub-threshold NULL at mean Δ=−0.00090; cooldown-window precision is structural, not WD-friction-bound**
- Gradient noise injection, GC, Cautious, AdEMAMix, Lookahead, Weight-EMA, AGC, OrthoGrad: all closed
- AdaBelief variance-of-prediction-error second moment: CLOSED productive-NEGATIVE (#474; embed sparsity pathology; `(g−m)²` fails on absent-row sparse groups)
- Muon-WD warmup (all fracs 5-20%): CLOSED productive-NEGATIVE (#483; monotone worsening; body WD=0.025 is bilaterally optimal)
- Lion, Adafactor on aux: closed (prior rounds)
- LLRD Muon: closed (NS normalizes depth scaling)
- AdamW LR per-group (embed=1.5× MERGED #393): embed_mult swept, scalar/lm_head confirmed optimal at 1.0×
- Adam-atan2 magnitude-transform (b∈{0.3,1.0,3.0}): CLOSED productive-NEGATIVE (#442; ε=1e-8 already optimal)
- NAdam (Nesterov-AdamW) aux scope sweep: CLOSED productive-null (#490; best arm B Δ=−0.00059 within null, joint D Δ=+0.00275 regression — scalars likely bad actor)
- Nesterov-Muon body weight sweep α∈{0.0, 0.50, 0.99}: CLOSED productive-NULL (#530; cliff on low-α side: α=0.50 catastrophic +0.04114 fst=-1, α=0.99 plateau null +0.00060; existing α=μ=0.95 is load-bearing AND optimally weighted; mechanism: tiny anti-staleness injection on top of NS-stable EMA; 5th body-Muon mechanism closure; 32nd null this cycle)

**NS precision family**:
- NS_ITERS_COOLDOWN: saturated (#388); **#487 Arm B (drop) at paired-pod n=3: mean(Δ)=+0.00003 — CLASSIFIED REDUNDANT** (not load-bearing, not improved); 4th cycle precedent for N=1 → paired-pod collapse
- NS cooldown SHAPE=late_peak: MERGED #285; #487 Arm C drop = +0.00080 null at N=1
- NS coef schedule=linear_ramp_down: MERGED #290; #487 Arm D drop = +0.00066 null at N=1
- **Joint-drop of NS-cooldown sub-stack: in-flight** (tanjiro #577, joint-pruning interaction test)
- **Per-block NS-iter spatial allocation (aspect ratio)**: CLOSED productive-NULL (#543; NS=12 saturated to spatial reallocation; codebase has only 2 non-square Muon blocks limiting surface)
- NS coef depth/center: saturated (#345, #384)
- NS=12 normal phase: CLOSED productive-null (#470; wide plateau NS ∈ [10,14]; NS=8 below floor; NS step-time flat ±1%)
- **NS-iter warmup (NS=8→12 over first 5%)**: CLOSED productive-NEGATIVE (#506; paired-pod n=3 mean Δ=+0.00087, all 3 pods regress; 5th single-seed→paired-pod collapse; NS axis fully fenced — 3/3 frieren NS schedule corners closed + sub-stack pruning + spatial reallocation also null)

**Schedule**:
- Cooldown frac (global): closed
- Embed linear_floor: MERGED #235
- lm_head steeper-decay: harmful (#315)
- lm_head + scalar floor: CLOSED productive-null (#454; embed-specific mechanism, not aux-generic)
- **lm_head cooldown SHAPE (cosine/late_peak/linear_floor)**: CLOSED productive-NULL (#547; cross-axis NS late_peak transfer falsified, +0.00179 biggest regression; lm_head wants monotonic linear; reproduces #454 linear_floor null; per-group SHAPE design space now substantially characterized — only scalar untested)
- Muon μ schedule: catastrophic; constant μ=0.95 confirmed (#356)
- Muon LR floor: monotone worse (#335)
- Embed-only LR warmup (frac∈{0.02, 0.05, 0.10}): CLOSED productive-NEGATIVE (#489; monotone catastrophic worsening; full embed LR from step 0 is load-bearing; 25th null this cycle)
- Embed LR step-0 boost (decay to 1.5×): CLOSED productive-NULL (#526; B/C plateau at Δ≈−0.0008 within noise floor; D longer window mildly worse; bilateral closure with #489; 31st null this cycle — embed step-0 LR=1.5× is bilaterally optimal)
- **Embed AdamW WD cooldown nudge (additive)**: CLOSED productive-NEGATIVE (#554; monotone regression A→D, B=+0.00068 null-edge fails baseline parity, C=+0.00657 regression, D=+0.01571 fails 3.28 target; mechanism: embed sparse-row representations depend on accumulated info not noise; WD overrides accumulation; bilateral asymmetry with #550 candidate)

**Init**:
- Embed init scale: null (#374)
- lm_head init std: monotone worse (#380)
- Block output projection init scale: in-flight (#452)

**Loss-side**:
- Logit softcap=15: confirmed optimal (#354)
- Z-loss λ∈{1e-5,1e-4,1e-3}: CLOSED productive-NEGATIVE (#441; softcap c=15 already bounds logits)
- Label smoothing α∈{0.0–0.2}: monotone catastrophic regression; closed (#446 productive-NEGATIVE)

**Clipping**:
- clip=5 → clip=10: MERGED #165
- AGC (per-parameter): productive-null per paired-pod trajectory (#408)

## Cycle 260 snapshot (09:00 UTC May 25) — #1113 fern Adan-aux CLOSED productive-NEG/CATASTROPHIC (15th consecutive no-merge closure since #847); fern reassigned #1153 Cautious C-AdamW-aux; OPTIMIZER-FAMILY-AUX axis closes toward partial fence (2-observation)

### Cycle 260 actions
- **#1113 CLOSED** productive-NEG/CATASTROPHIC: all 3 Adan arms (B/C/D) fs=−1 (never hit 3.28 in 3350 steps). Best arm C Δ_vs_A=+0.01575 (10× regression threshold). LR confound documented: Adan needs ~5× higher LR per Xie 2022 §4.1; PR spec did not retune. Test is "Adan at AdamW's tuned LR" — AdamW LR non-transferrable across optimizer families on aux. OPTIMIZER-FAMILY-AUX axis now 2-observation fence (#1045 LION mild-NEG + #1113 Adan catastrophic). Future optimizer-family-aux work must include per-arm LR retuning.
- **#1153 ASSIGNED to g1r4-fern**: Cautious Optimization (C-AdamW) for aux groups (Liang 2024 arXiv:2411.16085). Mechanism: mask AdamW update where sign(m̂/√v̂) ≠ sign(g) (agreements masked in, disagreements masked out), with normalization to preserve expected step magnitude. 4 arms: A=ctrl, B=hard mask on lm_head only (mech-lead — 25.6% sign-flip rate per #1045), C=hard mask on all aux groups, D=soft mask on lm_head (0.5+0.5×agree). Key distinction vs all prior optimizer changes: NOT a family change (AdamW preserved, all LRs unchanged — no LR confound); single mechanism slot: sign-consistency gate. Liang 2024 reports 1.47× speedup on LLaMA 1B. Mechanism-distinct from all current escalations.

### In-flight experiments (8 total, 0 idle)

| PR | student | axis | current state |
|:---:|:---:|---|:---:|
| #1100 | askeladd | AUX-WD per-group (PP n=3, Arm C lm_head wd=1e-3) | IN CHAIN — 6 interleaved seeds 0/1/2; ~11h budget; **STRONGEST CANDIDATE SINCE #847** |
| #1120 | nezuko | GaLore lm_head low-rank gradient (escalation) | INVESTIGATING — Arms B/C diverged (SVD instability); awaiting debug report |
| #1122 | thorfinn | Body Muon AggMo K-bank multi-β momentum | IN CHAIN — Arm A cleared drift, K=1 fast path bitwise-clean; B/C/D in flight |
| #1127 | frieren | Schedule-Free AdamW aux (Defazio 2024) | IN CHAIN — progressing |
| #1132 | alphonse | Shampoo body (Kronecker precond, Anil 2018) | INVESTIGATING — Arms B/C diverged; awaiting debug report on L/R Gram init |
| #1137 | edward | Stack pruning Phase 2 — 3 oldest flags (#393/#235/#579) | IN CHAIN — Arm A finished clean (val=3.269972, fs=3225, drift PASS), Arm B step 75 |
| #1138 | tanjiro | Newton-Muon body (Du & Su 2026 arXiv:2604.01472) | IN CHAIN — Arm A running (val=3.3857 step 2375); Arm A init crash `jnawq4x2` confirmed not Newton-related |
| **#1153** | **fern** | **Cautious C-AdamW aux (Liang 2024)** | **FRESH — just assigned** |

### Closure streak and plateau status

**15 consecutive no-merge closures since #847 (cycle 222)**:
1. #1028 PP (PRUNE-CONFIRM — anchor non-load-bearing)
2. #1031 nezuko NS-adaptive (marginal)
3. #1032 thorfinn Haar-init (regression)
4. #1045 frieren LION-aux (productive-NEG)
5. #1047 tanjiro LookAhead (productive-NEG)
6. #1048 alphonse cooldown-shape (null)
7. #1055 askeladd weight-averaging (productive-NEG)
8. #1003 fern per-block-TYPE cooldown anneal (PP collapse)
9. #1074 alphonse GC body (null)
10. #1078 thorfinn μ schedule (null/NEG)
11. #1088 frieren NS5-noise injection (null — Lipschitz-invariant)
12. #1091 alphonse body-Muon decoupled WD (NEG)
13. #1092 tanjiro per-group β1 asymmetric (null/NEG — mechanism fires but no signal)
14. #1028 PP n=3 PRUNE-CONFIRM (Edward's confirmation)
15. **#1113 fern Adan-aux (CATASTROPHIC — this cycle)**

Escalation Protocol Level 4 (tier-4 larger bets) in full effect since cycle 242. Live escalation axes: GaLore (diverging), AggMo, SF, Shampoo (diverging), Newton-Muon, Cautious (new). The 2 diverging axes (#1120 GaLore, #1132 Shampoo) are wholesale NS5-replacement; the 4 NS5-preserving axes (#1122 AggMo, #1127 SF, #1138 Newton-Muon, #1153 Cautious) show lower divergence risk.

### High-priority candidates
1. **#1100 PP n=3 (askeladd)** — AUX-WD per-group, lm_head wd=1e-3. 5-mechanism support (monotone A→B→C, group-specific Zipfian 5.3× signal, late-cooldown widening, fs-invariant continuous shrinkage, cross-axis confirmation). Δ=−0.00185 single-seed (0.00015 short of −0.002 threshold but elevated PP success probability). If PP passes all 5 merge gates → FIRST MERGE since cycle 222, new baseline ~3.26571.
2. **#1138 Newton-Muon (tanjiro)** — Du & Su 2026 report 6% step reduction on modded-nanoGPT; highest theory-backed prior since #847. NS5-preserving.
3. **#1153 Cautious C-AdamW (fern)** — directly addresses lm_head 25.6% sign-flip mechanism per #1045; Liang 2024 1.47× speedup claim; no LR confound; simplest implementation in this escalation wave.

### OPTIMIZER-FAMILY-AUX partial fence
- **#1045 LION**: mild NEG Δ=+0.00164
- **#1113 Adan**: CATASTROPHIC all arms Δ≥+0.01575
- **Reading**: AdamW's tuned LR is non-transferrable across optimizer families on aux. Future optimizer-family-aux experiments MUST include per-arm LR retuning (2×/5×/10× sweep). Cautious C-AdamW (#1153) ESCAPES this fence because it preserves AdamW (no family change).

## Cycle 262 snapshot (09:45 UTC May 25) — #1120 nezuko GaLore CLOSED productive-NEG/DIVERGENT (16th consecutive no-merge); nezuko reassigned #1155 MARS-AdamW-aux; #1127 frieren SF Arm B CATASTROPHIC (fs=−1)

### Cycle 262 actions
- **#1120 CLOSED** productive-NEG/DIVERGENT — all 3 GaLore arms early-killed at step 2500 (gap vs A: 0.80-1.39, 8-14× gate threshold). Structural finding: lm_head gradient is NOT low effective rank; spectrum FLATTENS over training (`proj_energy_ratio` 0.92→0.86 at rank=8, 0.97→0.70 for period=50). Buffer re-projection mismatch at SVD refresh is the load-bearing failure mode (identical-step crash at 2475 across rank=8 and rank=32 arms). GALORE-LM-HEAD axis fences with 1-closure structural observation. 16th consecutive no-merge closure.
- **#1155 ASSIGNED to g1r4-nezuko**: MARS-AdamW for aux groups (Yuan 2024 arXiv:2411.10438). STORM-style variance-reduced gradient: `g_t' = g_t + γ·(g_t − g_{t−1})` fed into standard AdamW. Mechanism: reduces gradient variance from Zipfian heavy-tail token noise in lm_head. NOT an optimizer-family change (AdamW step rule preserved, no LR confound). 4 arms: A=ctrl, B=γ=0.025 lm_head only (Yuan default, mech-lead), C=γ=0.025 all aux, D=γ=0.1 lm_head. Mechanism-distinct from Cautious (output-mask vs input-variance-reduction).
- **#1127 frieren Schedule-Free update**: Arm A ctrl finished clean (val=3.26943, +0.00187 drift PASS). **Arm B (SF β=0.9 no-cooldown) CATASTROPHIC** — val=3.29061, fs=−1, never hit target, Δ_vs_A=+0.02118 (14× regression threshold). Arm C (β=0.95 no-cooldown) running ~step 800. Arm D (hybrid +cooldown) not yet started. Arm D is now the critical test: if SF+cooldown ≈ A, schedule-replacement fails on this stack.

### GaLore / GALORE-LM-HEAD axis CLOSED (1-observation structural fence)
- **Zipfian row-magnitude ≠ Zipfian gradient spectrum**: the lm_head sign-flip row-magnitude finding (#1045) does NOT generalize to gradient-matrix spectral concentration being low-rank.
- **Buffer re-projection load-bearing**: any future subspace-projection-on-aux (SOAP, KFAC, Adafactor row-col) must implement explicit m/v buffer re-projection or reset at each SVD refresh.

### NS5-REPLACING vs NS5-PRESERVING mapping signal (strengthening)
Two of the five escalation axes that REPLACE NS5 or AdamW wholesale are NOW DIVERGED/CATASTROPHIC:
- **#1120 GaLore** (replaces AdamW subspace): CLOSED DIVERGENT
- **#1132 Shampoo** (replaces NS5 polar decomp): likely diverged (Arms B/C diverging, awaiting confirmation)
- **#1127 SF Arm B** (replaces aux cooldown): CATASTROPHIC

Three NS5-PRESERVING / AdamW-PRESERVING escalations remain stable:
- **#1122 AggMo** (K-bank momentum before NS5): in chain, Arm A clean
- **#1138 Newton-Muon** (input precond before NS5): in chain, Arm A in flight
- **#1153 Cautious** (output mask on AdamW): FRESH
- **#1155 MARS** (gradient input to AdamW): FRESH

### In-flight experiments (8 total, 0 idle)

| PR | student | axis | state |
|:---:|:---:|---|:---:|
| #1100 | askeladd | AUX-WD PP n=3 (lm_head wd=1e-3) | 1.5/6 runs done; ctrl-seed0=3.26980, armC-seed0 running; ETA ~14:45 UTC |
| #1122 | thorfinn | AggMo body Muon K-bank (NS5-preserving) | in chain |
| #1127 | frieren | Schedule-Free AdamW aux (Defazio 2024) | Arm B CATASTROPHIC (fs=−1), Arm C running, Arm D pending |
| #1132 | alphonse | Shampoo body (Anil 2018) | likely diverging; awaiting debug report |
| #1137 | edward | Stack pruning Phase 2 (#393/#235/#579) | Arm A finished clean (3.269972), Arm B in progress |
| #1138 | tanjiro | Newton-Muon body (Du & Su 2026) | Arm A in flight |
| **#1153** | **fern** | **Cautious C-AdamW aux (Liang 2024)** | FRESH |
| **#1155** | **nezuko** | **MARS-AdamW aux (Yuan 2024)** | FRESH |
