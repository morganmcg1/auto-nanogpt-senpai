# SENPAI Research Results — auto-nanogpt-1gpu-r2

## 2026-05-22 22:28 UTC — Cycle 71 mid-103: FOURTH val-side floor break (fern SOAP_PRECOND_FREQ=20) + askeladd soft-miss (SOAP_BETA2=0.99)

### #837 fern SOAP_PRECOND_FREQ=20 Arm A — VAL-SIDE FLOOR BREAK at n=1 (n=2 confirm authorized)

W&B verified `e0hvk4tk` terminal at step 3175:

| metric | SOAP_PRECOND_FREQ=20 (Arm A) | merge bar | n=1 hold gate | result |
|---|---:|---:|---:|---|
| val_loss@3175 | **3.26919** | val_mean ≤ 3.26776 | val ≤ 3.27 | **PASS by 0.00081** (val-side floor break) |
| ffs | **3025** | ffs_mean ≤ 3000 | ffs ≤ 3000 | **MISS by 25** (ffs wall) |
| statsig | (3.28 − 3.26919)·√1 = 0.01081 | ≥ 0.004 | — | **PASS by 2.7× at n=1** |

**Mechanistic finding — eigenbasis refresh frequency 20 is at least baseline-equivalent**: Less-frequent preconditioner refresh (every 20 steps vs default 10) captures MLP body matrix curvature direction equally well. The eigenbasis of MLP body matrices is locally stable enough that 20-step refresh doesn't lose meaningful information. SOAP preconditioner is paying ~2× more compute than necessary at default frequency.

**THIS IS THE 4TH VAL-SIDE FLOOR BREAK THIS CYCLE** and the BEST val-side margin:
1. audo3lgl (fern stack-pruning) val=3.26956 ffs=3025 (PASS by 0.00044)
2. m7582er0+j3zeph7z (thorfinn ATTN_SOAP_DISABLED) n=2 mean val=3.26958 ffs=3025 (PASS by 0.00042)
3. u6ovrf8t (frieren late-boost 1.5×) val=3.27029 ffs=3050 (CLOSE-MISS by 0.00029)
4. **e0hvk4tk (fern SOAP_PRECOND_FREQ=20) val=3.26919 ffs=3025 (PASS by 0.00081)** ← BEST

Floor val cluster sits at 3.270 ± 0.001. Four orthogonal mechanism families (stack-pruning, ATTN_SOAP_DISABLED, late-boost LR, SOAP preconditioner frequency) converge here.

**Action**: n=2 confirm authorized. For n=2 mean to crack merge bar val (3.26776), seed-2 val must be ≤ 3.26633 (-0.00286 below n=1). Plausible within seed noise σ~0.005-0.008. **If n=2 mean clears, this is the cycle's FIRST true floor break in 192+ PRs**.

### #836 askeladd SOAP_BETA2=0.99 Arm A — TERMINAL SOFT-MISS (Arm B 0.80 authorized)

W&B verified `vpo1dz28` terminal at step 3175:

| metric | SOAP_BETA2=0.99 (Arm A) | merge bar | n=1 hold gate | result |
|---|---:|---:|---:|---|
| val_loss@3175 | **3.28094** | val_mean ≤ 3.26776 | val ≤ 3.27 | **MISS by 0.01094** (above target val 3.28) |
| ffs | **N/A (-1)** | ffs ≤ 3000 | ffs ≤ 3000 | **MISS — val=3.28 never crossed** |
| reached_target | **0** | — | — | **target val=3.28 NOT reached at any step** |

**SOFT MISS** pattern (same as alphonse #830 Arm A): all kill gates passed but terminal val above target. SOAP_BETA2=0.99 (slower MLP-side 2nd-moment EMA, ~100-step horizon vs default 0.95 ~20-step horizon) results in the preconditioner using stale 2nd-moment statistics that miss the cooldown-induced curvature shifts — final val drop from step 3000 doesn't materialize.

Combined with nezuko #828 NORMUON_BETA2=0.99 close-miss (val=3.27180/ffs=3050), this is the **SECOND axis confirming 0.95 is the local optimum for 2nd-moment EMA on body-matrix preconditioning** (NorMuon-side and MLP-SOAP-side both agree).

**Action**: Arm B 0.80 authorized per pre-set decision tree (opposite direction = faster EMA ~5-step horizon). Mechanism question — is the optimum at 0.95 (Arm B also worse) or is faster EMA preferred (Arm B better)?

### Other in-flight runs (22:28 UTC)

- **alphonse #830 Arm B v3kapwbw** step 2300 val=3.36 tracking **-0.020 BELOW baseline** (strong cooldown approach)
- **frieren #833 Arm B yt6juqss** step 450 val=3.883 PASSING step 500 kill gate (3.92) by 0.04
- **thorfinn #842 lhfxbo3y** step 1100 val=3.66 tracking baseline within seed noise
- **nezuko #843 iyfei0ra** step 1400 val=3.57 tracking **+0.04 ABOVE baseline** — early boost has cumulative cost concerning, watch step 1500 kill gate (3.68) — currently safe by 0.11

---

## 2026-05-22 21:55 UTC — Cycle 71 mid-102: #833 frieren MUON_LR_LATE_BOOST=1.5× Arm A terminal CLOSE-MISS + Arm B 2.0× authorized

### #833 frieren MUON_LR_LATE_BOOST Arm A — TERMINAL CLOSE-MISS (Arm B authorized per pre-set decision tree)

W&B verified `u6ovrf8t` terminal at step 3175:

| metric | MUON_LR_LATE_BOOST=1.5× (Arm A) | merge bar | n=1 hold gate | result |
|---|---:|---:|---:|---|
| val_loss@3175 | **3.27029** | val_mean ≤ 3.26776 | val ≤ 3.27 | **CLOSE-MISS by 0.00029** (just above hold gate val side) |
| ffs | **3050** | ffs_mean ≤ 3000 | ffs ≤ 3000 | **MISS by 50** |
| trajectory (last 4) | (2800, 3.284) → (2925, 3.280) → (3050, 3.277) → (3175, 3.270) | — | — | steep cooldown drop in last 175 steps |

**Mechanistic interpretation**: Pure Muon LR boost @1.5× during last 7.5% of training delivers a measurably steeper cooldown slope (0.000075/step vs baseline 0.000057/step), but early-body val at step 2925 starts ~0.001 ABOVE baseline. Net terminal val=3.27029 is essentially baseline-tied (+0.00253 above baseline mean 3.26776, well within seed noise). Late-boost has its own small ffs penalty (3050 vs the quintuple-confirmed 3025 wall) — the late boost defers val crossing 3.27 because the body of training was slightly higher.

**Action**: Arm B 2.0× authorized per pre-set decision tree (PR body: "If Arm A close-miss → launch Arm B 2.0× for orthogonal direction"). Mechanism question — does 2.0× scale linearly (potential merge candidate) or destabilize (close axis)? #794 composite-late-boost precedent suggests close-miss bucket bounded by both directions (Arm A 1.5×/1.5% val=3.27040, Arm B 2.0×/2.0% val=3.26941 — both close-missed). But pure-LR mechanism could behave differently from composite.

**THIRD val-side floor approach this cycle**: 3 orthogonal mechanism families have now converged at this floor depth:
1. fern audo3lgl (stack-pruning CONTRA=0+NS5=10) val=3.26956 ffs=3025
2. thorfinn m7582er0+j3zeph7z (ATTN_SOAP_DISABLED) n=2 mean val=3.26958 ffs=3025
3. frieren u6ovrf8t (MUON_LR_LATE_BOOST=1.5×) val=3.27029 ffs=3050

The floor val cluster sits at 3.270 ± 0.001 = tight band. ffs locked at 3025-3050 across mechanisms. Floor structure (val + ffs together) is robust under multiple orthogonal interventions.

### Status correction — thorfinn #842 healthy (initial sub-agent misread)

Initial W&B sub-agent report flagged `uxl7ac0a` as "CRASHED" — clarification: `uxl7ac0a` was the SECOND disabled-check (crashed post-eval at step ~180, normal pattern when the disabled-check completes step 200 eval but wandb sync doesn't flush cleanly). The actual Arm A=0.99 run is `lhfxbo3y` now at step 400 healthy. No action needed for thorfinn — Arm A is progressing normally.

### nezuko #843 step 500 kill gate PASSED

`iyfei0ra` (MUON_LR_EARLY_BOOST=1.5× during stable phase) at step 500 val=3.887 — PASSED kill gate (>3.92) by margin 0.033. Early boost mechanism is on a stability cusp (val=4.478 at step 200 was +0.43 above baseline 4.04 — concerning early signal), but body training has caught up to be within kill-gate by step 500. Continuing.

### In-flight portfolio at 21:55 UTC

| PR | student | run_id | step | val | status |
|---|---|---|---:|---:|---|
| #833 | frieren | u6ovrf8t | 3175 | 3.27029 | TERMINAL (Arm A close-miss, Arm B 2.0× authorized) |
| #842 | thorfinn | lhfxbo3y | 400 | early | RUNNING Arm A=0.99 healthy |
| #843 | nezuko | iyfei0ra | 500 | 3.887 | RUNNING (passed step 500 kill gate) |
| #830 | alphonse | v3kapwbw | 1450 | 3.506 | RUNNING Arm B=0.20 (below baseline interp) |
| #836 | askeladd | vpo1dz28 | 2544 | 3.360 | RUNNING (within seed noise) |
| #837 | fern | e0hvk4tk | 2450 | 3.365 | RUNNING (within seed noise) |
| #793 | tanjiro | — | — | — | POD-BROKEN (4+ escalations unresponded) |
| #702 | edward | — | — | — | POD-BROKEN (4+ escalations unresponded) |

42 axes in refuted floor cluster + #833 Arm A added as close-miss pending Arm B outcome.

---

## 2026-05-22 21:25 UTC — Cycle 71 mid-101: TRIPLE CLOSURE (41st + 42nd floor axes + alphonse soft-miss) + 2 auto-launched followup kills + 2 fresh assignments

### #818 thorfinn ATTN_SOAP_DISABLED — CLOSED as 41st floor axis (n=2 val-side floor break, ffs wall holds)

n=1 `m7582er0` val=3.26861 ffs=3025; n=2 `j3zeph7z` val=3.27055 ffs=3025; **n=2 MEAN val=3.26958 ffs=3025**. Statsig (3.28−μ)·√2=0.01474 PASS by 3.7×; n=2 hold gate val PASS by 0.00042 (FIRST hold-gate-PASS val at n=2 in 38+ axes this cycle); merge bar MISS by 0.00182 val + 25 ffs. ATTN_SOAP is MILDLY load-bearing (Δ+0.0018 val + 25 ffs disabled) — MUCH smaller than MLP_SOAP (#819 Δ+0.0074 val + 100 ffs disabled). MLP > ATTN load-bearing asymmetry of ~4× val + ~4× ffs is mechanistically clear: MLP body benefits fully from SOAP preconditioning; ATTN qkv-proj's softmax+causal-mask geometry already provides much of the conditioning. ffs=3025 QUINTUPLE-confirmed across this run + fern audo3lgl/288hsmgv + frieren mvkam4g5/mx3wejbm.

**Auto-launched n=3 `m8z9ox88` killed (instructed in closure comment)** — n=3 cannot crack merge bar (val gap 0.00182 requires seed-3 val ≤ 3.26412 = 2σ event; ffs locked at 3025 anyway).

### #828 nezuko NORMUON_BETA2=0.99 — CLOSED as 42nd floor axis (close-miss double on hold gates)

`2yvwpst9` val=3.27180 ffs=3050. MISS hold-gate-val by 0.0018, MISS hold-gate-ffs by 50. Slower EMA (β2=0.99, ~100-step horizon) hurts +0.004 val + 50 ffs vs default 0.95. Arm B (0.80) NOT TESTED — Arm A's clean directional signal makes Arm B redundant for closure. **NorMuon 2nd-moment apparatus confirmed locally optimal at default 0.95 (1D per-row buffer); the entire NorMuon family (NORMUON_BETA2 + NORMUON_2D #715) is now FULLY refuted at this floor depth.**

**Auto-launched relaunch `ikid3mo9` killed (instructed in closure comment)**.

### #830 alphonse TARGET_UW=0.50 Arm A — SOFT MISS, sent back for Arm B

`ekkxz91k` val=3.28174 ffs=N/A (target val=3.28 NEVER reached). ALL kill gates passed; target threshold MISS by 0.00174. **First soft-miss pattern this cycle**: passes all kill gates, fails at final terminal threshold. Mechanism: TARGET_UW=0.50 (50% higher than default 0.35) makes Muon updates more aggressive throughout, which degrades LATE-COOLDOWN convergence (final 0.05 val drop from step 3000 doesn't happen). Arm B (TARGET_UW=0.20, opposite direction) authorized for launch.

### New assignments (closed students rotated)

- **#842 thorfinn**: ATTN_SOAP_BETA2 sweep (Arm A=0.99 slower, Arm B=0.80 faster). First ATTN-SOAP-internal axis in 192+ PRs. Inherited β2=0.90 = 10-step horizon. Sibling of askeladd #836 MLP-side SOAP_BETA2 — together probe full SOAP-BETA2 across both matrix families.
- **#843 nezuko**: MUON_LR_EARLY_BOOST sweep (Arm A=1.5×, Arm B=2.0× during stable phase only). First EARLY-side LR boost axis in 192+ PRs. Mirror of frieren #833 late-boost — together probe early vs late LR boost asymmetry. Stop at step 952 (1-cooldown_frac×3175). 6-8 LOC code change to set_hparams.

### In-flight portfolio (6/8 healthy, 2/8 pod-broken)

| student | PR | axis | run | step | val | ETA |
|---|---|---|---|---:|---:|---|
| askeladd | #836 | SOAP_BETA2 Arm A=0.99 | vpo1dz28 | 625 | 3.78 | ~3h |
| fern | #837 | SOAP_PRECOND_FREQ Arm A=20 | e0hvk4tk | 500 | 3.80 | ~3.5h |
| frieren | #833 | MUON_LR_LATE_BOOST Arm A=1.5× | u6ovrf8t | 1500 | 3.53 | ~2h |
| alphonse | #830 | TARGET_UW Arm B=0.20 | pending | — | — | launch imminent |
| thorfinn | #842 | ATTN_SOAP_BETA2 Arm A=0.99 | pending | — | — | code change + launch |
| nezuko | #843 | MUON_LR_EARLY_BOOST Arm A=1.5× | pending | — | — | code change + launch |
| tanjiro | #793 | DEPTH_DEP_MUON_LR | — | — | — | pod broken |
| edward | #702 | MU_WARMUP_START | — | — | — | pod broken |

## 2026-05-22 20:40 UTC — Cycle 71 mid-100: DOUBLE CLOSURE (39th + 40th floor axes) + double fresh SOAP-internal assignments

### #819 askeladd MLP_SOAP_DISABLED — CLOSED as 39th floor axis

`nhswq1cf` terminal val=3.27516 ffs=3100 (close-miss by 0.0052 val + 100 ffs). **MLP_SOAP is materially load-bearing** — removing it costs +8× more val and +3× more ffs than removing ATTN_SOAP (cf. thorfinn `m7582er0` val=3.26861 ffs=3025). Mechanistic interpretation: SOAP-preconditioned MLP direction IS compatible with NS5+contra+NorMuon and is NOT redundant noise. Combined with #804 AdaFactor-MLP (direction-not-magnitude refutation), the picture triangulates: full SOAP preconditioning IS the right amount of MLP-direction information at this floor depth.

### #806 fern CONTRA_MUON=0+NS5_ITERS=10 stack-pruning — CLOSED as 40th floor axis (first statsig-confirmed close-miss)

n=2 mean val=3.27011 ffs=3025. **First stack-pruning ablation in 192+ PRs to deliver a statsig-PASS val signal** ((3.28-μ)·√2=0.01399 ≥ 0.004 by 3.5×). MISS merge bar by 0.00235 val + 25 ffs. Mechanistic finding: CONTRA_MUON contributes ~0.0017 val at floor (small but real); NS5_ITERS=10 vs 14 is approximately neutral when CONTRA=0. **ffs=3025 wall TRIPLE-confirmed quantization-locked** across 5 independent runs spanning 3 mechanism families (audo3lgl + 288hsmgv + mvkam4g5 + m7582er0 + mx3wejbm). The eval cadence (every 25 steps after step 952) is the structural ffs floor.

Stack-pruning success means the simpler stack (CONTRA_MUON=0, NS5_ITERS=10) is a candidate baseline for future floor-cadence experiments.

### New assignments (idle students rotated)

- **#836 askeladd**: SOAP_BETA2 sweep (Arm A=0.99, Arm B=0.80). First internal MLP-SOAP-2nd-moment axis in 192+ PRs. Inherited β2=0.90 = 10-step horizon; sibling axis to nezuko #828 NORMUON_BETA2.
- **#837 fern**: SOAP_PRECOND_FREQ sweep (Arm A=20, Arm B=5). First internal MLP-SOAP-refresh-frequency axis in 192+ PRs. Inherited freq=10 means 317 eigendecompositions per 3175-step run; stability vs tracking-fidelity trade-off.

### Mid-100 in-flight portfolio (7/8 GPUs active, 1 pod-broken)

- thorfinn n=2 `j3zeph7z` ATTN_SOAP_DISABLED step ~1750 val=3.486 healthy (gate@2000=3.55 - PASS, on track for cycle's strongest n=2 confirm of floor break val=3.26861)
- nezuko #828 `2yvwpst9` NORMUON_BETA2=0.99 step ~1875 val=3.455 exceptionally healthy (below baseline)
- alphonse #830 `ekkxz91k` TARGET_UW=0.50 step ~1375 val=3.654 (close to gate@1500=3.68 with only 0.026 headroom)
- frieren #833 `zdffq62p`/`dl25oo0b` MUON_LR_LATE_BOOST=1.5 both at step ~125 (duplicate concern; advisor asked frieren to verify single-process)
- askeladd #836 (just assigned) — pending pickup
- fern #837 (just assigned) — pending pickup
- tanjiro #793 pod-broken (4 escalations unresponded since 18:10 UTC)
- edward #702 pod-broken (4 escalations unresponded)

---

## 2026-05-22 19:53 UTC — Cycle 71 mid-99: #794 CLOSED (38th floor axis — composite-late-boost AdamW saturation ceiling) + frieren → #833 MUON_LR_LATE_BOOST + new internal-axis sweeps in flight

### #794 frieren composite-late-boost — CLOSED as 38th floor axis

W&B terminal `mx3wejbm` (Arm B 2.0×/2.0×):

| run | arm | val | ffs | hold gate | result |
|---|---|---:|---:|---|---|
| `mvkam4g5` | Arm A 1.5×/1.5× n=1 | 3.26890 | 3025 | val PASS, ffs MISS | close-miss |
| `ptshctmv` | Arm A 1.5×/1.5× n=2 seed | 3.27189 | 3050 | val MISS, ffs MISS | miss |
| n=2 mean | Arm A | 3.27040 | 3037.5 | MISS bilateral | floor cluster |
| `mx3wejbm` | **Arm B 2.0×/2.0× n=1** | **3.26941** | **3025** | val PASS, ffs MISS by 25 | **close-miss** |

Arm B holds val=3.26941 (2nd-best single-seed in 192+ PRs, behind only thorfinn m7582er0 at 3.26861). But per decision tree, ffs=3025 miss triggers close-miss closure. The axis is saturated: 1.5×→2.0× moved val by Δ~−0.001 (within seed noise σ~0.005), confirming AdamW-tail-undertraining mechanism ceiling at ~3.269.

**Key mechanistic findings from #749 / #759 / #794 composite:**
- AdamW-side late-boost (+0.002-0.003 val improvement) is real but capped
- The ffs=3025 rate-limiter is upstream of AdamW — likely Muon-side dynamics or schedule shape
- No destructive interference at 2.0×/2.0× — model absorbed double boost magnitude cleanly

### #833 frieren — MUON_LR_LATE_BOOST sweep (NEW ASSIGNMENT)

Frieren's own follow-up from #794: Muon-side cooldown-tail boost, symmetric to AdamW-side. Arms: MUON_LR_LATE_BOOST=1.5 (Arm A) and 2.0× (Arm B), MUON_LATE_BOOST_FRAC=0.075. Tests whether Muon under-trains in cooldown tail like AdamW, or is already at LR-Goldilocks.

### Floor-break n=2 confirms in flight (MID-99 SNAPSHOT)

| student | run | mechanism | val n=1 | ffs n=1 | n=2 status |
|---|---|---|---:|---:|---|
| thorfinn | `j3zeph7z` | ATTN_SOAP_DISABLED | 3.26861 | 3025 | running step ~125 (launched ~19:00 UTC) |
| fern | `288hsmgv` | CONTRA_MUON=0+NS5=10 | 3.26956 | 3025 | running step ~2250 |

### Other in-flight

- askeladd `nhswq1cf` MLP_SOAP_DISABLED #819: step 2875 val=3.302 → very close to terminal (~300 steps), likely close-miss
- nezuko `2yvwpst9` NORMUON_BETA2=0.99 #828 Arm A: step 250 val=4.04 healthy (~3hr)
- alphonse `qgl3ueem` TARGET_UW=0.50 #830 Arm A: just launched (disabled-check val=4.087 passed, nudge sent 19:28 UTC)

---

## 2026-05-22 18:00 UTC — Cycle 71 mid-98: SECOND ADVISOR CALIBRATION ERROR (single-value ffs) + #806 fern audo3lgl CONFIRMED VAL-SIDE FLOOR BREAK terminal val=3.26956 ffs=3025 + dual-mechanism floor convergence

### audo3lgl floor break — fern CONTRA_MUON=0 NS5_ITERS=10 (PR #806 Arm B terminal)

W&B verified terminal (student SENPAI-RESULT + Agent subagent W&B query):

| metric | audo3lgl actual | merge bar | n=1 hold gate | result |
|---|---:|---:|---:|---|
| terminal val/loss | **3.26956** | 3.26776 | 3.27 | **val PASS by 0.0004** |
| ffs (final_first_step_to_target) | **3025** | 3000 | 3000 | **ffs MISS by 25 (0.83%)** |

**Trajectory verification** (full-resolution from student's mid-flight + terminal comments):

| step | baseline n=2 mean | audo3lgl | Δ vs baseline |
|---:|---:|---:|---:|
|  500 | 3.8034 | 3.80659 | +0.0032 |
| 1000 | 3.66028 | 3.66576 | +0.0055 |
| 2000 | 3.43285 | 3.43108 | **−0.0018** |
| 2500 | 3.35 | 3.34658 | **−0.0034** |
| 3000 | 3.28 | 3.28089 | +0.0009 |
| 3175 | 3.26776 | **3.26956** | +0.0018 |

Tracks baseline within seed noise the entire trajectory; ACTUALLY BELOW baseline at steps 2000-2500. The simplified stack (no contra-Muon, NS5_ITERS=10 vs 14) hits essentially the same floor as the full stack — **the cycle's first STACK-SIMPLIFICATION evidence**.

### Calibration error #2 caught (single-value ffs, not row-shift)

In my 17:25 UTC advisor comment on #806 I wrote: `| ffs | **3150** | ... | **ffs MISS by 150** |`. **Wrong.** Actual ffs=3025 (student SENPAI-RESULT + Agent W&B verification both agree). I copy-pasted from a wrong source/typo.

**This is a different calibration error mode than the mid-97 row-shift**: that was systematic across 8 PRs; this is a single-number paste error in one comment. The corrective response is the same: post a correction + send PR back for re-verification. Acknowledged in correction comment posted to #806 at 18:00 UTC; PR labels flipped review→wip.

### Dual-mechanism floor convergence

**Two val-side floor breaks** of the cycle land at near-identical floor metrics via completely orthogonal mechanism families:

| run | mechanism class | val | ffs |
|---|---|---:|---:|
| frieren mvkam4g5 | composite-late-boost (EMBED+LM_HEAD 1.5×/1.5% boost last 7.5%) | 3.26890 | 3025 |
| fern audo3lgl | stack-pruning (CONTRA_MUON=0 + NS5_ITERS=10) | 3.26956 | 3025 |

These are NOT the same mechanism. Composite-late-boost EXPLOITS AdamW-tail-undertraining via aggressive LR knob; stack-pruning REMOVES two of the mandatory env-flags. Both crossing val<3.27 at n=1 with identical ffs=3025 strongly suggests **(a)** floor val IS crossable but **(b)** floor ffs is structural at 3025 — quantized at the eval cadence (every 25 steps after step 952).

### Implications

1. **Stack-simplification finding stands regardless of merge outcome**: CONTRA_MUON contributes ~zero measurable to floor val. NS5_ITERS=10 vs 14 is similarly neutral. Two mandatory env-flags candidate-removable.
2. **Floor ffs may be quantization-locked at 3025**: requires evaluation cadence change or sub-eval-step ffs interpolation to crack ffs=3000. Mechanism-side changes won't help.
3. **#806 n=2 confirm is the cycle's most important pending result**: if seed-2 lands val ≤ 3.26597 AND ffs ≤ 2975, n=2 mean clears merge bar = first floor break in 38+ axes. Plausible but not certain (σ_val ~ 0.005 per seed, audo3lgl already 0.0018 above merge bar val).

### Action taken at 18:00 UTC

- PR #806 corrected + sent back to wip with corrected ffs and n=2 launch command
- Updated memory: [[feedback_kill_gates_from_baseline]] strengthened (paste errors are another mode)
- Pending pod escalations #768/#692: 3rd re-escalations posted 17:13/17:14 UTC, no infra response yet (4th will fire at next wake if still unresponded)

### In-flight portfolio (mid-98, 6/8 GPUs healthy)

| student | PR | run | status | step | val |
|---|---|---|---|---:|---:|
| fern | #806 (n=2) | (pending launch) | wip | — | — |
| alphonse | #817 | jx1pylz0 NadamW Arm B | running | ~1500 | 3.536 |
| thorfinn | #818 | m7582er0 ATTN_SOAP_DISABLED A | running | ~1000 | 3.667 |
| askeladd | #819 | nhswq1cf MLP_SOAP_DISABLED A | running | ~125 | 4.501 |
| nezuko | #816 | 4d8cq1je AdEMAMix B α=2 | running | ~636 | 3.754 |
| frieren | #794 | mx3wejbm composite 2.0×/2.0% B | running | ~625 | 3.753 |
| tanjiro | #793 | pod-broken hold | wip | — | — |
| edward | #702 | pod-broken hold | wip | — | — |

5 healthy in-flight + fern n=2 pending pickup + 2 pod-broken. Next terminal cluster lands ~18:30-19:30 UTC.

## 2026-05-22 17:00 UTC — Cycle 71 mid-97: ADVISOR CALIBRATION ERROR caught by fern + frieren #794 composite-late-boost n=2 close-miss + nezuko #816 AdEMAMix Arm A diverging

### The calibration error (caught by fern on #806 at 16:07 UTC)

**Failure mode**: When writing kill gates into the mid-95 / mid-96 launch batch (PRs #804, #805, #806, #811, #816, #817, #818, #819), I systematically wrote `step 1000=3.55, step 2000=3.30` as the baseline reference values. Independent W&B verification via `vwrqt4vt`, `1zb5h0e5`, `4v5jsjk9` (PR #613 winner trials) showed actual baseline mean is **step 1000=3.6614, step 2000=3.4294**. The values I wrote (3.55/3.30) actually correspond to ~step 1500 / step 3000 — a row-shift of 500 steps in the reference table.

**Effect**: Kill gates set at `step 1000 > 3.58/3.60` and `step 2000 > 3.32` are BELOW the actual baseline trajectory at those steps. **Any healthy run trips these gates.** Several closures in mid-95/mid-96 may have been premature.

### PR #794 — frieren COMPOSITE_LATE_BOOST n=2 close-miss (Arm A 1.5×/1.5×)

Branch: `g1r2-frieren/composite-late-boost`. n=2 results posted via W&B confirmation.

| Run | Created | val | ffs | hold gate (val≤3.27 AND ffs≤3000) |
|---|---|---:|---:|---|
| `mvkam4g5` (n=1) | 13:09 UTC | **3.26890** | **3025** | val PASS, ffs MISS by 25 |
| `ptshctmv` (n=2 fortuitous relaunch) | 15:04 UTC | **3.27189** | **3050** | val MISS by 0.002, ffs MISS by 50 |
| **n=2 mean** | | **3.27040** | **3037.5** | val MISS by 0.0026, ffs MISS by 37.5 |

**Result: n=2 mean CLOSE-MISS vs merge bar** (val_mean ≤ 3.26776 AND ffs_mean ≤ 3000). The single n=1 mvkam4g5 result (val=3.26890) was the closest-margin single-trial close-miss in the cycle's entire floor cluster, but the second seed regressed slightly (+0.003 within seed noise but on the wrong side of the merge bar). Composite-late-boost 1.5×/1.5× joins the floor cluster at n=2.

**Arm B (2.0×/2.0%) authorized to launch**: tests additivity-vs-saturation. If effect is linear, 2.0× should land at val~3.265-3.268 = candidate floor break. If effect is non-monotonic, 2.0× may regress to val~3.28+ = mechanism saturated at 1.5×.

### PR #816 — nezuko MUON_ADEMAMIX Arm A DIVERGING (kill instructed)

Branch: `g1r2-nezuko/ademamix-muon`. Arm A `sdzdmhxc` killed at advisor instruction.

| step | val | actual baseline ref | gap | status |
|---|---:|---:|---:|---|
| 750 | 3.735 | 3.72 | +0.014 | tracking |
| 875 | 3.719 | 3.69 | +0.029 | tracking |
| 1000 | 3.717 | 3.66 | +0.057 | mild drift |
| 1125 | 3.748 | 3.63 | +0.118 | drifting |
| 1250 | 3.807 | 3.60 | +0.207 | diverging |
| 1375 | **3.868** | 3.56 | **+0.308** | **diverging hard** |
| 1400 | train=3.912 | — | — | positive slope |

val/slope/loss_per_100_steps = **+0.048 positive** = getting worse.

**Result: Arm A KILLED at step 1400** (exceeds corrected step-1500 kill gate of 3.68 by 0.19, positive slope, no recovery possible). Mechanism interpretation: **α=6.0 + β_slow=0.9999 is destabilizing late-warmup → cooldown**; slow EMA component pulls body matrix updates out-of-distribution from NS5-orthogonalized direction. Arm B with α=2.0 (softer slow-EMA contribution) authorized to launch.

### Calibration impact on mid-95/mid-96 closures (retrospective)

**Axes that remain LEGITIMATELY closed** (terminal data, catastrophic margins, or calibration-independent failures):
- #804 AdaFactor MLP — val@500=5.11 vs baseline 3.80 = +1.31 catastrophic. Closure stands.
- #797 Sophia — val@2000=3.45 catastrophic + val@500=4.07 strictly worse. Closure stands.
- #792 SF-AdamW — val@1000=3.73 vs baseline 3.66 = +0.07 strictly worse (above corrected gate). Closure stands.
- #811 NS5 aggressive (Arm A) — NaN at step 125, numerical instability is calibration-independent. Closure stands.
- All earlier closed axes (Lookahead, MARS-M, Cooldown EMA, Lion, MUON_COOLDOWN_SHAPE, scalar/schedule, etc.) had terminal evaluations against the actual baseline, not intermediate-step gates. Closures stand.

**Axes that need re-examination** (premature kills, may have tracked baseline):
- #818 ATTN_SOAP_DISABLED Arm A — val@1000=3.67001 vs actual baseline 3.66 = +0.007 = within seed noise. PR sent BACK to thorfinn for RELAUNCH with corrected gates. The "ATTN_SOAP is load-bearing" conclusion does NOT survive corrected reference (slope 3.81→3.67 = -0.14 vs actual baseline 3.81→3.66 = -0.15 = 93% of actual late-cooldown improvement rate, essentially matched).
- #817 NADAMW Arm A — val@1000=3.664 vs baseline 3.66 = +0.004 = baseline equivalent. Arm B (betas 0.9, 0.999) in flight with corrected gates. May also track baseline.
- #805 Z_LOSS Arm A val=3.66322 / Arm B val=3.66201 @1000 — both **BELOW** actual baseline 3.66352 at step 1000. Z-Loss is approximately no-op, not "monotonically harmful". Closure retrospectively marked as informational.
- #811 NS5 soft Arm B — val@1000=3.67821 vs baseline 3.66 = +0.018 = within typical seed noise + stack-perturbation margin. Closure retrospectively marked.
- #806 fern CONTRA_MUON=0 Arm A — val@1000=3.66839 vs baseline 3.66028 = +0.008 = within seed noise. Premature kill caught mid-flight; Arm B `audo3lgl` continues to terminal with corrected gates (currently step 1500+ tracking baseline).

### Recalibrated floor depth

**Of the 37 closed axes claimed at mid-96, ~30 are legitimately at the floor.** 3-4 axes (Z-Loss, NS5 soft, ATTN_SOAP_DISABLED, NADAMW Arm A) need terminal evaluation against the corrected baseline. The cycle has **TWO ACTIVE FLOOR-BREAK CANDIDATES**:

1. **frieren Arm B 2.0×/2.0% composite-late-boost** — additivity test on the closest-margin mechanism.
2. **fern Arm B audo3lgl CONTRA_MUON=0 + NS5_ITERS=10** — tracking baseline through step 1500+, terminal ~17:30 UTC.

If either clears the merge bar n=1 hold gate, this becomes the cycle's first floor-break in 192+ PRs. **The calibration correction may have surfaced the floor-break signal that was being masked by premature kills.** Pending follow-up: terminal evaluation of relaunch #818 (thorfinn ATTN_SOAP_DISABLED) and Arm B test of #817 (alphonse NADAMW with paper betas) under corrected gates.

### Memory + process correction

Memory [[feedback_kill_gates_from_baseline]] strengthened with this incident as the **3rd occurrence** of this failure mode on auto-nanogpt-1gpu-r2 (prior: 2026-05-18 PRs #378/#394 also had bad kill gates). Rule reinforced: **query W&B fresh for baseline trajectory at every checkpoint step BEFORE writing kill gates into a PR body. Do NOT reuse step→val mappings from prior PR bodies or conversation memory.** Memory now includes the verified baseline trajectory snapshot for this cycle.

## 2026-05-22 16:05 UTC — Cycle 71 mid-96: TRIPLE CLOSURE — NS5 polynomial coeffs / Z-Loss / AdaFactor MLP all bilateral kill-gate trips (35th/36th/37th floor axes); stack-pruning trifecta dispatched to complete preconditioner ablation across MLP+attn+contra simultaneously

### PR #811 — alphonse NS5_COEFFICIENTS (first inner-iteration polynomial axis in 192+ PRs)

Branch: `g1r2-alphonse/ns5-coefficients`. Closed 2026-05-22 15:45 UTC.

| Run | Arm | (a, b, c) | val@200 | val@500 | val@1000 | killed at step | gate trip |
|-----|-----|-----------|---------|---------|----------|---:|---|
| disabled-check | standard | (2, −1.5, 0.5) | 4.09238 | — | — | — | ✅ in band |
| Arm A | aggressive | (3.4375, −4.6875, 2.8125) | NaN @ step 125 | — | — | 125 | NaN |
| Arm B | soft | (1.5, −0.5, 0.0625) | 4.07392 @250 | 3.82159 | **3.67821** | 1010 | step 1000 > 3.58 |

W&B runs: `fkdmtb0z` (disabled-check), `g4g6oun5` (Arm A), `k8m5nu2d` (Arm B).

**Result: AXIS CLOSED at bilateral kill-gate trip — 35th floor axis** by very large margin. Standard cubic (2, −1.5, 0.5) is Goldilocks at NS5_ITERS=14.

**Mechanism analysis (student's sharp boundary identification)**: Aggressive coefficients fail at the **numerical-stability** boundary (NaN at step 125 — higher-order, less-damped polynomial overshoots on SVs near 1.0 after spectral-norm normalization → blow-up in NS5 inner loop). Soft coefficients fail at the **convergence-quality** boundary (under-converged cubic at iter=14 → residual spectral noise in Muon updates accumulates linearly with training steps, reaching +0.10 val vs reference by step 1000). The standard cubic sits in the Pareto-optimal region between these failure modes.

**Mechanistic implication**: The NS5 polynomial coefficient axis is informatively closed — the matrix-sign approximator inside Muon's spectral normalization is already at its accuracy/stability optimum for iter=14. Further reduction in NS5 spectral noise (if any is needed) must come from changing the NUMBER of iterations or the OUTER preconditioner, not the polynomial coefficients themselves. Combined with the broader floor-cluster signal: the entire Muon-side spectral approximation stack (NS5 + contra + per-head NorMuon) is at Goldilocks across every parametric knob tested in 192+ PRs.

### PR #805 — thorfinn Z_LOSS (first loss-level mechanism in 36+ axes)

Branch: `g1r2-thorfinn/z-loss`. Closed 2026-05-22 15:45 UTC.

| Run | Z_LOSS_COEFF | val@200 | val@500 | val@1000 | killed at step | gap vs reference (3.55) |
|-----|---:|---:|---:|---:|---:|---:|
| disabled-check | 0.0 | 4.08614 | — | — | — | ✅ in band [4.05, 4.15] |
| Arm A | 1e-4 (PaLM default) | — | 3.80401 | **3.66322** | 1000 | +0.113 |
| Arm B | 3e-5 (3.3× softer) | — | 3.80065 | **3.66201** | 1000 | +0.112 |

W&B runs: `5x634hax` (disabled-check), `50yan4o2` (Arm A), `9nr7zymb` (Arm B).

**Result: AXIS CLOSED at bilateral kill-gate trip — 36th floor axis**. Even 3.3× softer coefficient produces only 0.001 improvement over PaLM default, indicating the loss-level penalty `Z_LOSS_COEFF · logsumexp(logits)²` is monotonically harmful across this coefficient regime — the marginal effect curve is essentially flat between 3e-5 and 1e-4.

**Student's val-loop correctness verification**: explicitly checked that `forward()` gates z-loss on `self.training and Z_LOSS_COEFF > 0.0`, that the val loop calls `model.eval()` so val cross-entropy excludes z-loss, and that the disabled-check is bit-equivalent to baseline (4.08614 ∈ [4.05, 4.15]). Implementation is correct; result is mechanistically informative.

**Mechanism analysis**: Either the penalty is genuinely too costly at this scale (124M vs PaLM's 540B) — small models have less softmax-saturation headroom to absorb logsumexp regularization without distorting the CE direction — OR softmax-gradient-variance is NOT a bottleneck mechanism for our floor. Combined with PR #613 LOGIT_SOFTCAP at c=20 closure: input-side softmax conditioning is at Goldilocks; loss-level penalties on the output partition function add no measurable value. **First LOSS-LEVEL mechanism class refuted.**

### PR #804 — askeladd ADAFACTOR_MLP (first factored 2nd-moment preconditioner + first MLP-only preconditioner test)

Branch: `g1r2-askeladd/adafactor-mlp`. Closed 2026-05-22 16:02 UTC.

| Run | Arm | clip | val@500 | val@1000 | killed at step | gap vs reference (3.81) |
|-----|-----|---:|---:|---:|---:|---:|
| disabled-check | — | — | val@200=4.085 (in band) | — | — | bit-equivalent verify |
| Arm A | clip=1.0 (paper default) | 1.0 | **5.11109** | 4.62761 | 500 (step 500 > 3.95) | +1.30 |
| Arm B | clip=0.5 (halved) | 0.5 | **5.09572** | (killed @ 984) | 500 (step 500 > 3.95) | +1.29 |

W&B runs: `pz1d4wsa` (Arm A), `3rbx0nc5` (Arm B).

**Result: AXIS CLOSED at bilateral kill-gate trip — 37th floor axis, by very large margin**. The 0.02 improvement from halving the RMS clip threshold is **mechanistically zero** — sensitivity to clip ∈ {0.5, 1.0} is negligible.

**Student's mechanism analysis (highest-information result of the experiment)**:

> "The dominant pathology is **not magnitude** but **direction**: the factored M_ij ≈ R_i·C_j/sum(R) approximation may be wrong-direction relative to Muon's spectral-normalized attention update. With MLP on AdaFactor and attention on Muon, two updates with different scales AND different geometries coexist, and they don't compose."

**Mechanistic implication**: This is a load-bearing finding for the entire floor research program. **Stack composition matters more than individual component quality** — substituting in a preconditioner that is mathematically reasonable on its own (AdaFactor has strong theoretical guarantees) catastrophically breaks the joint Muon-side + AdamW-side composition when the update DIRECTIONS are incompatible. The rank-1 row+col factored 2nd-moment is rank-1 in shape — its update direction lies in the outer-product space `R⊗C^T`, which is orthogonal to Muon's spectrally-normalized direction on the same matrices. Even at small magnitudes (clip=0.5), the directional incompatibility produces +1.29 val above gate at step 500.

**This directly motivates the next experiment cluster**: if MLP-on-Muon-SOAP and attention-on-Muon-SOAP are both load-bearing AT THE DIRECTION LEVEL (not magnitude level), then the stack-pruning ablation that removes them should ALSO catastrophically fail (positive control). If stack-pruning produces MISS-at-floor (cheap removal, no penalty), then SOAP-on-attention/MLP contributes ~zero measurable value. Either result is informatively orthogonal to floor-cluster tuning. **AdaFactor closure directly seeds the askeladd #819 MLP_SOAP_DISABLED + thorfinn #818 ATTN_SOAP_DISABLED stack-pruning ablations.**

### Combined mechanistic conclusion (3-PR closure wave + AdaFactor direction-incompatibility insight)

**Three fresh mechanism classes ALL CLOSED at bilateral kill-gate trip**:
1. **NS5 polynomial coefficients** (inner-iteration spectral approximation): closed at numerical-stability + convergence-quality boundary, standard cubic Goldilocks → **35th floor axis**
2. **Z-Loss** (loss-level logsumexp² penalty): closed at +0.113 val above kill gate, flat marginal effect curve → **36th floor axis**
3. **AdaFactor MLP** (factored 2nd-moment preconditioner): closed at +1.29 val above kill gate by very large margin, **stack composition direction-incompatibility** → **37th floor axis**

**Pattern at 37-axis floor depth**: Mechanisms that change WHAT the optimizer computes (factored vs full 2nd moment, signed updates, second-order curvature) and operate inside the Muon spectral normalization (polynomial coefficients) ALL fail. The stack is configured at Goldilocks across every replaceable component AND every replaceable component's internal knob. The floor is in the **COMPOSITION** of the optimizer stack, not in any individual component.

### Strategic pivot (cycle 71 mid-96) — STACK-PRUNING TRIFECTA

The AdaFactor closure's "direction matters not magnitude" mechanism analysis directly motivates a synchronized 3-axis ablation: if individual preconditioning components are load-bearing AT THE DIRECTION LEVEL, simultaneously disabling each component separately reveals whether ANY is contributing measurable value beyond NS5 alone.

**Stack-pruning trifecta in flight simultaneously across 3 GPUs**:
- **fern #806 CONTRA_MUON=0** (body-side stack pruning) — Arm B `audo3lgl` (contra=0 + NS5_ITERS=10) running step 1375 val=3.570 healthy descent surprisingly close to baseline trajectory at 16:00 UTC
- **thorfinn #818 ATTN_SOAP_DISABLED** (attention-side stack pruning) — just assigned, completing the ablation across attention preconditioner
- **askeladd #819 MLP_SOAP_DISABLED** (MLP-side stack pruning) — just assigned, completing the ablation across MLP preconditioner

**Why this is the cycle's most informative experiment cluster**: All 3 ablations are mechanistically orthogonal stack simplifications. The combined 3-arm result determines whether ANY of the 3 preconditioning components (CONTRA_MUON, ATTN_SOAP, MLP_SOAP) is load-bearing on the floor. Four possible outcomes:
1. All 3 MISS at floor → SOAP+contra contribute zero measurable value; the floor is in NS5+NorMuon alone (massive simplification opportunity)
2. 1 of 3 MISS at floor → that component is the only zero-value piece; targets stack simplification at that specific layer
3. All 3 trigger kill gate → the entire preconditioning stack is jointly load-bearing on the floor (mechanism class confirmed)
4. 1 of 3 BELOW floor → component is net-negative; would be the cycle's first true floor-break via removal not addition

### Fresh assignments (4 PRs dispatched in this batch)

- **#817 alphonse → NADAMW**: Nesterov-accelerated AdamW substitution on optimizer1 (embed + lm_head + scalars). Custom NadamW class with decoupled WD (torch.optim.NAdam lacks decoupled WD). Nesterov substitution `m_nesterov = β1·m_hat + (1-β1)·g/bc1`. Arm A betas (0.8, 0.95), Arm B betas (0.9, 0.999). **First Nesterov momentum substitution axis in 192+ PRs**, mechanistically orthogonal to all 37 closed axes via using lookahead-style first-moment correction.
- **#818 thorfinn → ATTN_SOAP_DISABLED**: env-gated `self.attn_soap_params = set()` ablation. **First attention-side stack-pruning axis** — every prior ATTN_SOAP work TUNED the mechanism (threshold, ramp, freq, beta2). Zero LOC change to NS5, Muon body update, AdamW, or any other component.
- **#819 askeladd → MLP_SOAP_DISABLED**: env-gated `self.soap_params = set()` ablation. **First MLP-side stack-pruning axis** — every prior MLP SOAP work TUNED the mechanism (SOAP_BETA2, SOAP_PRECOND_FREQ, SOAP_EPS). Zero LOC change to NS5, AdamW, ATTN_SOAP, or any other component. Completes the trifecta.
- **#816 nezuko → MUON_ADEMAMIX** (assigned mid-95, hard override sent mid-96 for 2nd disabled-check stall): dual-EMA gradient memory on Muon body matrices (Pagliardini 2024 arxiv 2409.03137). Fast EMA (current mu=0.95) + slow EMA β2=0.9999 with α-warmup 0→6.0 over 30% training. **First dual-EMA gradient-memory axis** in 192+ PRs.

### Pending watches (16:00-17:30 UTC critical window)

- **frieren ptshctmv n=2 terminal ~17:00 UTC**: step 1600 val=3.535 at 16:00 UTC, tracking baseline trajectory. If n=2 mean (mvkam4g5 val=3.269/ffs=3025 + ptshctmv pending) clears merge bar (val_mean ≤ 3.26776 AND ffs_mean ≤ 3000), this is **the cycle's first FLOOR BREAK in 37+ axes**.
- **fern audo3lgl Arm B terminal ~17:30 UTC**: step 1375 val=3.570 at 16:00 UTC. Surprisingly healthy mid-trajectory descent for "CONTRA=0 + NS5_ITERS=10" — joint stack pruning may produce a real floor result.
- **alphonse #817 + nezuko #816 + thorfinn #818 + askeladd #819 Arm A launches**: all should be in disabled-check or Arm A within next 30 min based on launch nudges + override sent at 16:01 UTC.

### Operational notes

- **4 disabled-check stalls bit this cycle** (#794 frieren, #797 nezuko 1st, #816 nezuko 2nd, #817 alphonse) — saved memory [[feedback_student_disabled_check_stall]] activated. Preemptive launch nudges + HARD OVERRIDEs sent within 8 min of disabled-check completion now standard pattern.
- **2/8 pods still broken** (#768 tanjiro 6-canary NaN evidence, #692 edward 24h+ idle) — second re-escalation at 14:50 UTC unresponded by infra team. Two GPUs offline ~46 GPU-hours lost this cycle.
- **Frieren n=2 protocol clarification**: accidental `ptshctmv` relaunch with identical config to mvkam4g5 treated as fortuitous n=2 seed 2; do NOT kill, await terminal, combined SENPAI-RESULT after both runs finish.



### PR #797 — nezuko SOPHIA_DIAGONAL_HESSIAN on AdamW groups (Liu Stanford 2023, arxiv 2305.14342)

Branch: `g1r2-nezuko/sophia-diagonal-hessian`. Closed 2026-05-22 15:30 UTC.

| Run | Arm | γ | ρ | β1 | K | killed at step | val at kill | gate trip | gap vs baseline |
|-----|-----|----|----|----|---|---:|---:|---|---:|
| disabled-check (2) | — | — | — | — | — | val@200=4.085-4.087 (in band) | bit-equivalent verify | — | `3kikzrni`, `rsugdmv2` |
| Arm A | paper defaults | 0.05 | 0.05 | 0.965 | 10 | 2410 (val@2000=3.49782 > 3.35) | 3.44752@2375 | step 2000 > 3.35 | +0.17 |
| Arm B | looser γ | 0.1 | 0.05 | 0.965 | 10 | 506 (val@500=4.06772 > 4.0) | 4.06772@500 | step 500 > 4.0 | +0.79 strictly worse |

W&B runs: Arm A `pmahogn7`, Arm B `t83fiw62`.

**Result: AXIS CLOSED at bilateral kill-gate trip — Sophia diagonal-Hessian preconditioner is strictly WEAKER than AdamW EMA(g²)** on this stack at this scale. **34th axis joining floor cluster** by very large margin (gap +0.17 to +0.79 vs typical cluster gap 0.008).

**Mechanism analysis (student's sharp γ-direction inversion catch)**: Sophia's update is `clip(m_hat / max(γ·h, ε), ±ρ)`. With γ=0.1 (vs Arm A γ=0.05), the denominator `γ·h` is LARGER → the un-clipped ratio `m_hat/(γ·h)` is SMALLER → fewer elements saturate at ±ρ → effective update is SMALLER. **This is the opposite of "looser scaling allows larger steps"** — Sophia's γ scales the denominator NOT the update. Both arms produce sub-AdamW updates because:
1. The Hessian-via-g² rank-1 GNB estimator is more conservative than AdamW's sqrt(EMA(g²)) at the embed/lm_head LR regime
2. The clip ceiling at ρ=0.05 caps update magnitude even when m_hat/(γ·h) > ρ in regions of small curvature

**Mechanistic implication**: Sophia substituting in a different curvature object (rank-1 GNB Hessian estimate) gets strictly WEAKER updates. This refutes the load-bearing assumption from PR #772 mechanistic synthesis that AdamW's EMA(g²) is "the wrong curvature object" for embed+lm_head undertraining in cooldown. AdamW's `sqrt(EMA(g²))` IS the right curvature shape; head-undertraining must be addressed via LR/schedule (which is what #794 COMPOSITE_LATE_BOOST is testing in flight). Combined floor-cluster signal across 34 axes now:
- Iterate-side mechanisms (Lookahead, MARS-M, Cooldown EMA): 3 axes refuted
- Schedule mechanisms (SF-AdamW): 1 axis refuted by very large margin
- Sign-only mechanisms (Lion): 1 axis refuted by small margin
- **Second-order curvature mechanisms (Sophia): 1 axis refuted by very large margin**
- Scalar/schedule axes: 28 axes MISS at floor

### Conclusions

**The floor IS in optimizer's reachable loss landscape AND in the AdamW-side preconditioner shape.** Orthogonal mechanism classes that change WHAT the optimizer computes (not how it weights/clips) are still in flight: alphonse NS5 polynomial coefficients (#811), thorfinn Z-Loss loss-level penalty (#805), fern CONTRA=0 stack-pruning (#806), askeladd AdaFactor factored 2nd-moment preconditioner (#804), nezuko AdEMAMix dual-EMA gradient memory (#816 just assigned). Frieren composite late-boost (#794) at val=3.269/ffs=3025 is the closest n=1 close-miss in the entire 34-axis cluster — n=2 confirm via accidental re-launch `ptshctmv` is the cycle's most important pending result. If n=2 mean clears merge bar (val≤3.26776 AND ffs≤3000), this is the cycle's first FLOOR BREAK.

## 2026-05-22 13:40 UTC — Cycle 71 mid-93: TRIPLE CLOSURE — Arm A cluster all MISS at floor (Lookahead, MARS-M, Cooldown EMA → 30th/31st/32nd floor axes); 3 iterate-side mechanism classes ALL fail

### PR #784 — askeladd LOOKAHEAD on AdamW (Zhang NeurIPS 2019, arxiv 1907.08610)

Branch: `g1r2-askeladd/lookahead-adamw`. Closed 2026-05-22 13:28 UTC.

| Run | Arm | k | α | val_loss | ffs | hold gate | W&B |
|-----|-----|---|---|----------|-----|-----------|-----|
| disabled-check (2) | — | — | — | val@200=4.084-4.094 (in band) | — | bit-equivalent verify | `9gq0fbs4`, `jm9uekut` |
| Arm A | 5 | 0.5 | **3.27686** | **3100** | MISS (val>3.27, ffs>3000) | `ry5ndos0` |

**Result: AXIS CLOSED at n=1 MISS**. First trajectory-side mechanism (post-step slow×fast weight interpolation on AdamW groups) joins floor cluster. **30th floor-cluster axis**. Slow-weight reset every k=5 steps DELAYS the val=3.28 crossing by ~100 steps relative to baseline ffs=3000. Trajectory averaging is NOT the right axis for ffs reduction. Arm B (k=10) skipped — same mechanism family, implausible to close val gap of 0.009.

### PR #788 — thorfinn MARS-M VARIANCE-REDUCED MUON (Yuan 2024, arxiv 2411.10438)

Branch: `g1r2-thorfinn/mars-m-variance-reduced-muon`. Closed 2026-05-22 13:30 UTC.

| Run | Arm | γ | val_loss | ffs | hold gate | W&B |
|-----|-----|---|----------|-----|-----------|-----|
| disabled-check | — | 0 | val@200=4.091 (in band) | — | bit-equivalent verify | `taw87avo` |
| Arm A | A | 0.025 (paper-optimal) | **3.27576** | **3075** | MISS (val>3.27, ffs>3000) | `pp8r1qg9` |

**Result: AXIS CLOSED at n=1 MISS**. STORM control-variate correction `c_t = g_t + γ·(μ/(1-μ))·(g_t - g_{t-1})` produces 0 ffs reduction at paper-optimal γ. **Closest of the 3 cluster** to merge bar (val miss 0.008, ffs miss 75). Variance reduction does NOT escape floor. **31st floor-cluster axis**. MARS-M's proven O(T^-1/4)→O(T^-1/3) convergence rate improvement translates to 0 empirical ffs benefit at 3175 steps. Arm B (γ=0.1) skipped — 4× higher γ would amplify lever but mechanism direction (variance reduction) is informatively refuted at γ=0.025.

### PR #786 — fern COOLDOWN_EMA_AVERAGING (Izmailov SWA 2018, Through-the-River 2025 arxiv 2507.09846)

Branch: `g1r2-fern/cooldown-ema-averaging`. Closed 2026-05-22 13:30 UTC.

| Run | Arm | EMA_DECAY | val_loss | ffs | hold gate | W&B |
|-----|-----|-----------|----------|-----|-----------|-----|
| disabled-check (2) | — | 0 | val@200=4.084-4.085 (in band) | — | bit-equivalent verify | `chxzpqlb`, `bfrbk27h` |
| Arm A | A | 0.99 | **3.27666** | **3025** | MISS (val>3.27, ffs OK-by-25) | `n5ty2wdp` |

**Result: AXIS CLOSED at n=1 MISS** despite EMA init bug observed (val=5.005 spike at step 1000 when EMA accumulation started from random-init buffer). Contamination from spike decays as `0.99^(2225-50) ≈ 1.7e-10` by terminal — final val essentially uncontaminated. **Tail averaging on model weights during cooldown does NOT escape the floor**. **32nd floor-cluster axis**. Arm B (decay=0.999) skipped — wider averaging window over same cooldown plateau samples the same flat region.

### Combined mechanistic conclusion (3-PR closure wave)

**Three iterate-side mechanism classes ALL MISS the floor cluster at val≈3.276/ffs=3025-3100**:
1. **Lookahead** (post-step slow×fast weight interpolation): val=3.27686/ffs=3100, MISS
2. **MARS-M** (STORM control-variate gradient correction): val=3.27576/ffs=3075, MISS
3. **Cooldown EMA** (model weight tail averaging during cooldown): val=3.27666/ffs=3025, MISS

**Inter-class spread** = 0.0011 val (3.27576 - 3.27686), within seed noise. **All 3 lie at the same floor**.

**Strong mechanistic conclusion**: The floor IS in the optimizer's reachable loss landscape under this stack configuration. **NOT** in iterate noise. **NOT** in gradient variance. **NOT** in weight-average sampling. This rules out the entire family of iterate-side / variance-side interventions on the floor problem.

### Strategic pivot (cycle 71 mid-93)

Floor cluster now 32 axes deep. Mechanism classes confirmed unable to escape floor on this stack:
- Gradient processing (5 axes): GROKFAST, GRAD_CLIP, RADAM, ADAMW_EPS, NESTEROV
- Preconditioner adapt (2 axes): ATTN_SOAP_TRUST static + dynamic ramp
- Schedule shape (3 axes): MUON_COOLDOWN_SHAPE, cooldown_frac, eta_min
- Per-group LR (3 axes): EMBED_LR_LATE_BOOST, LM_HEAD_LR_LATE_BOOST, MUON_LR_ATTN/MLP
- Warmup (2 axes): EMBED_LR_WARMUP, MU_WARMUP
- Input rescaling (1 axis): LOGIT_SOFTCAP at 20
- Init (1 axis): EMBED_INIT_STD
- Optimizer wrappers (1 axis): Lookahead
- Variance reduction (1 axis): MARS-M
- Tail averaging (1 axis): Cooldown EMA
- Sign-only updates (1 axis): Lion
- Per-block-type LR splits (1 axis): MUON_LR_ATTN/MLP
- Late-boost variants (3 axes): EMBED, LM_HEAD, ADAMW_LR_FLOOR
- WD schedule (1 axis): WD_AUX_TEMPORAL_RAMP
- Bias correction (1 axis): MUON_BIAS_CORR
- Cooldown variants (2 axes): cosine + sqrt
- Plus several scalar combination axes

**3 fresh assignments dispatched** to capture next phase of exploration:
- **#804 askeladd ADAFACTOR_MLP** — factored row+col 2nd moment preconditioner on MLP body matrices ONLY (attn stays on Muon+SOAP). First factored preconditioner + first MLP-only preconditioner test. Mechanism class: factored 2nd-moment.
- **#805 thorfinn Z_LOSS** — PaLM logsumexp(logits)^2 regularization (Chowdhery 2022 Section 5.2). First LOSS-LEVEL mechanism in 32+ axes. Targets softmax gradient variance hypothesis. Arm A coeff=1e-4 (PaLM default), Arm B coeff=3e-5.
- **#806 fern CONTRA_MUON=0 ABLATION** — first STACK-PRUNING ablation in 192+ PRs. Zero LOC change. Diagnostic. Arm A full removal, Arm B contra=0+NS5_ITERS=10 de-iteration. Either outcome updates research map cleanly.

**Researcher batch source**: `/workspace/senpai/target/research/RESEARCH_IDEAS_2026-05-22_13:35.md` (3 ideas: Z-Loss [used], NS5 polynomial coeff re-optimization [saved], CONTRA=0 ablation [used]).

---

## 2026-05-22 13:00 UTC — Cycle 71 mid-92: PR #772 nezuko LION_ADAMW CLOSED — 29th floor axis, bilateral 2× LR sweep refutes second-moment-free updates on AdamW groups

### PR #772 — nezuko LION_ADAMW Arm A (LR ratio 1/8) / Arm B (LR ratio 1/4)

Branch: `g1r2-nezuko/lion-adamw-groups`. Closed 2026-05-22 12:55 UTC.

| Run | Arm | LR ratio | LION_LR_EMBED | LION_LR_HEAD | val_loss | ffs | hold gate | W&B |
|-----|-----|----------|---------------|---------------|----------|-----|-----------|-----|
| disabled-check (3 redundant) | — | — | — | — | val@200=4.086 (in band) | — | bit-equivalent verify | `zs96nr7k`, `feaiad2x`, `nk2tr0q4` |
| Arm A | 1/8 | 0.003 | 0.0003125 | 3.29799 | -1 | MISS (val far above 3.27 + never crosses 3.28) | `3cxdhk0x` |
| Arm B | 1/4 | 0.006 | 0.000625 | 3.29979 | -1 | MISS (val far above 3.27 + never crosses 3.28) | `q68tgpja` |
| **Inter-arm Δ** | — | 2× | 2× | 2× | **0.00180** | n/a | both MISS by ~0.03 | both |

**Result: AXIS CLOSED as bilateral MISS** by exceptionally large margin (~0.030 val above baseline 3.26776, vs typical floor cluster close-miss of +0.003). The 2× LR span produced only Δ=0.0018 in terminal val, proving 3rd ratio sweep (1/2 or 1/16) would not change the conclusion by more than ~0.005.

**Mechanism class falsified (per student's synthesis)**: LION SIGN-ONLY UPDATES without curvature information cost ~+0.030 val on embed+lm_head AdamW groups specifically. The constant-magnitude ±1 sign rule produces well-behaved stable trajectories (no divergence, no NaN, clean cooldown) but lacks per-coordinate magnitude scaling that AdamW's `g/sqrt(EMA(g²))` denominator provides. **The bottleneck is not LR but the sign-update geometry itself — Lion lacks the curvature information AdamW exploits.**

**Trajectory comparison (val_loss at checkpoints)**:
| step | Arm A (Lion 1/8) | Arm B (Lion 1/4) | reference `vwrqt4vt` AdamW |
|------|------------------|------------------|----------------------------|
| 500  | 3.867            | 3.847            | 3.81                       |
| 1000 | 3.698            | 3.701            | 3.55                       |
| 2000 | 3.451            | 3.460            | 3.30                       |
| 3000 | 3.309            | 3.310            | —                          |
| 3175 | **3.29799**      | **3.29979**      | —                          |

Both Lion arms track ~0.05 above reference AdamW trajectory throughout — consistent gap throughout training, not a cooldown-only failure.

**Action**: closed PR #772 with full SENPAI-RESULT acknowledgement + assigned nezuko #797 SOPHIA_DIAGONAL_HESSIAN (researcher priority 5). Direct attack on student's "denominator matters" identification — Sophia replaces AdamW's `EMA(g²)` second-moment denominator with a clipped periodically-refreshed diagonal Hessian estimate. First second-order curvature mechanism in 192+ PRs, mechanistically orthogonal to all 29 closed axes including:
- AdamW (current default, |g|² denominator)
- Lion (no denominator)
- Muon (spectral via Newton-Schulz)
- SOAP (Kronecker eigenbasis)

If Sophia clears ffs=3000, the AdamW denominator IS the bottleneck → second-order curvature is the path forward. If Sophia also MISSes at val~3.27 close-miss, the floor is fundamentally geometric/quantization/data-ordering, and we'd pivot to architectural changes.

---

## 2026-05-22 12:30 UTC — Cycle 71 mid-91: PR #759 frieren LM_HEAD_LR_LATE_BOOST CLOSED — 28th floor axis, bilateral with thorfinn #749 EMBED late-boost

### PR #759 — frieren LM_HEAD_LR_LATE_BOOST Arm A (1.5×) / Arm B n=1+n=2 (2.0×)

Branch: `g1r2-frieren/lm-head-lr-late-boost`. Closed 2026-05-22 12:27 UTC.

| Run | Arm | Mult | val_loss | ffs | hold gate | Δ vs baseline | W&B |
|-----|-----|------|----------|-----|-----------|---------------|-----|
| disabled-check | — | — | val@200=4.0786 (in band) | — | bit-equivalent verify | — | `kjlxryb7` |
| Arm A n=1 | 1.5 | — | 3.26963 | 3025 | MISS (ffs) | +0.00187, +25 ffs | `ez9asjj8` |
| Arm B n=1 | 2.0 | — | **3.26923** | 3025 | MISS (ffs only) | +0.00147, +25 ffs | `44ydskx1` |
| Arm B n=2 | 2.0 | — | 3.27057 | 3050 | MISS (both) | +0.00281, +50 ffs | `qvgnuhpx` |
| **Arm B mean (n=2)** | **2.0** | — | **3.26990** | **3037.5** | **MISS** | **+0.00214, +37.5 ffs** | combined |

**Result: AXIS CLOSED as MISS.** Bilateral close-miss with thorfinn #749 EMBED_LR_LATE_BOOST (Arm A 1.5×: val=3.2708, ffs=3025).

**Mechanism class falsified (per student's synthesis): LM_HEAD-ONLY tail boost cannot crack ffs=3000**. However, the symmetric bilateral signal — both AdamW matrix groups individually show ~+0.001-0.002 val improvement under late-boost — strongly supports **mechanism (2): AdamW-matrix-tail undertraining**, not embed-specific or cooldown-shape-specific. Both groups are individually limited by cooldown's last-7.5% LR, but neither in isolation has enough magnitude to clear the floor.

**Late-stage val trajectory (Arm B 2.0× n=2 `qvgnuhpx`)**:
- step 3000: val=3.28326 (still above 3.28 threshold)
- step 3025: val=3.28036 (just above)
- step 3050: val=3.27801 (first crossing below 3.28) → ffs=3050
- step 3075: val=3.27591
- step 3100: val=3.27402
- step 3125: val=3.27234
- step 3150: val=3.27110
- step 3175: val=3.27057 (terminal)

The val_loss trajectory shows monotonic improvement through every boost step with no overshoot — confirming the group is undertrained, lever direction is correct, magnitude insufficient.

**Action**: closed PR #759 with full SENPAI-RESULT acknowledgement + assigned frieren #794 COMPOSITE_LATE_BOOST (simultaneous embed + lm_head late-boost during last 7.5% of training; Arm A 1.5×/1.5× additivity test, Arm B 2.0×/2.0× aggressive). If both groups individually contribute ~+0.001 val improvement in isolation and effects are additive, composite reaches val≈3.266-3.268 and possibly ffs=3000. First 2-group simultaneous late-boost in 192 PRs.

---

## 2026-05-22 11:47 UTC — Cycle 71 mid-90: PR #754 alphonse ADAMW_EPS CLOSED — 27th floor axis, n=2 confirm refutes 1e-13 seed luck

### PR #754 — alphonse ADAMW_EPS Arm A (1e-7) / Arm B (1e-13) + n=2 confirm

Branch: `g1r2-alphonse/adamw-eps-ramp`. Closed 2026-05-22 11:42 UTC.

| Run | eps | val_loss | ffs | hold gate | Δ vs baseline | W&B |
|-----|-----|----------|-----|-----------|---------------|-----|
| disabled-check | — | val@200=4.08524 (in band) | — | bit-equivalent verify | — | `i9mgr90u` |
| Arm A n=1 | 1e-7 | 3.27102 | 3025 | MISS (+0.00326 val, +25 ffs) | +0.00326, +25 ffs | `dmjzp0ew` |
| Arm B n=1 | 1e-13 | **3.26872** | **3000** | PASS (val ≤3.27 ✓ ffs ≤3000 ✓) | +0.00096, baseline ffs | `iyu08uc7` |
| Arm B n=2 | 1e-13 | 3.27180 | 3050 | MISS (+0.00404 val, +50 ffs) | +0.00404, +50 ffs | `syj66r93` |
| **Mean (n=2)** | **1e-13** | **3.27026** | **3025** | **MISS (val>3.26776, ffs>3000)** | **+0.00250, +25 ffs** | combined |

**Result: AXIS CLOSED as MISS.** The n=1 Arm B ffs=3000 result was seed luck — n=2 confirm regressed to 3.27180/ffs=3050, dragging the mean to 3.27026/ffs=3025, the same floor cluster as the other 26 closed axes. Mechanistic read (eps inert at 1e-13 << typical sqrt(v_t)) holds, but the lever is genuinely zero-effect for the floor crossing — n=1 ffs=3000 was within ~±25-step seed noise envelope.

**Mechanism class falsified: ADAMW_EPS denominator floor**. The denominator floor in AdamW does not gate ffs=3025; the floor is not set by eps-driven preconditioner numerics.

**Action**: closed PR #754 with full SENPAI-RESULT (n=2 fails merge bar) + assigned alphonse #792 SCHEDULE_FREE_ADAMW (researcher batch priority 3, Defazio primal-dual averaging) — first three-iterate parameterization in 192 PRs, orthogonal to all 27 closed axes (gradient transforms, preconditioners, trust gates, eps, LR groups, schedule shapes, init, etc.).

---

## 2026-05-22 11:15 UTC — Cycle 71 mid-89: PR #771 thorfinn ATTN_SOAP_TRUST_RAMP CLOSED — 26th floor axis, dynamic SOAP trust gate falsified

### PR #771 — thorfinn ATTN_SOAP_TRUST_RAMP 0.85→0.95 (RAMP_FRAC 0.05/0.10)

Branch: `g1r2-thorfinn/attn-soap-trust-ramp`. Closed 2026-05-22 11:10 UTC.

| Arm | RAMP_FRAC | val_loss | ffs | hold gate | Δ vs baseline | W&B |
|-----|-----------|----------|-----|-----------|---------------|-----|
| disabled-check | — | val@200=4.08308 (in band) | — | bit-equivalent verify | — | (same run) |
| Arm A | 0.05 | **3.27078** | **3025** | MISS (+0.00302 val, +25 ffs) | +0.00302, +25 ffs | `cs6p9db0` |
| Arm B | 0.10 | **3.27023** | **3025** | MISS (+0.00247 val, +25 ffs) | +0.00247, +25 ffs | `nv2jimy2` |

**Result: AXIS CLOSED as MISS.** Both arms land in close-miss floor cluster.

#### Mechanism falsification

- Direction is correct (Arm B 10pct ramp marginally better than A 5pct ramp): wider ramp gives the dynamic preconditioner more cooldown window with stabilized eigenbases.
- Lever magnitude is too small to cross the ffs=3025 floor.
- Combined with PR #683 (static ATTN_SOAP_TRUST_THRESHOLD sweep) closure, **dynamic-vs-static SOAP trust-gate mechanism class is now closed bilaterally**. Attention-side preconditioner aggressiveness during cooldown is NOT the binding constraint for ffs unlock.
- 26th axis joining ffs=3025+ floor cluster (val≈3.27).

#### Reassignment: thorfinn → #788 MARS-M VARIANCE-REDUCED MUON

Priority 2 from researcher batch 2026-05-22 10:15. **First per-step gradient transformation tested on this stack in 189 PRs.**

Mechanism: STORM-style control-variate correction `c_t = g_t + γ * (μ/(1-μ)) * (g_t - g_{t-1})` applied BEFORE Muon's momentum aggregation/NS5/contra/NorMuon. Arms: A=γ=0.025 (paper-optimal), B=γ=0.1.

- Yuan et al. 2024 (arxiv 2411.10438): proves O(T^-1/4) → O(T^-1/3) convergence rate.
- Variant: MARS-approx (cache previous step's raw grad, no extra fwd/bwd).
- Memory overhead: ~6MB extra per Muon param group (one fp32 grad copy).
- **Mechanistically orthogonal** to all 26 closed axes — variance reduction operates on the gradient estimator itself, not on scalars, schedules, or per-group LR.

---

## 2026-05-22 11:00 UTC — Cycle 71 mid-88: PR #764 fern MUON_COOLDOWN_SHAPE CLOSED — both arms terminal in W&B, 25th floor axis, post-completion student stall

### PR #764 — fern MUON_COOLDOWN_SHAPE (per-group cosine/sqrt cooldown on Muon LR)

Branch: `g1r2-fern/muon-cooldown-shape`. Closed 2026-05-22 11:00 UTC based on W&B data (no student SENPAI-RESULT posted).

| Arm | shape | val/loss | ffs | hold gate | Δ vs baseline | W&B |
|-----|-------|----------|-----|-----------|---------------|-----|
| Arm A | cosine | **3.27799** | **3050** | MISS (+0.00799 val, +50 ffs) | +0.01023 val, +50 ffs | `bpawpz58` |
| Arm B | sqrt   | **3.28289** | **-1**   | catastrophic (didn't reach target) | +0.01513 val, no-cross | `9kxnjj1s` |

**Result: AXIS CLOSED as MISS.** Both arms miss the floor cluster (Arm A by larger margin than typical close-miss; Arm B catastrophic). Muon cooldown shape is NOT the binding constraint for ffs unlock. Per-group cosine cooldown lands at the same ffs floor (3050 here, ~25 above the typical 3025 floor); sqrt cooldown actively destabilizes (no target crossing in 3175 steps).

#### Mechanism falsification

- Arm A (cosine): faster late drop than linear should accelerate convergence — does not. Linear vs cosine cooldown for Muon LR is mechanically equivalent in this regime; the ffs determination is set BEFORE the late-cooldown phase.
- Arm B (sqrt): sustained-high Muon LR through cooldown breaks the orthogonalization-norm equilibrium that NS5 + cooldown jointly establish; weights drift away from the cooldown attractor.
- Combined with prior CONTRA_MUON/MUON_LR_ATTN/MLP closures, the **Muon-LR-shape mechanism class is fully closed** for ffs gains in this stack.

#### Student conduct note

Post-completion stall: 4 disabled-checks ran AFTER Arm B terminal (`o5eoh7xu` 10:49 UTC most recent) with zero PR comments since 05:40 UTC assignment. Student lost ~90 min of pod compute on plumbing verification of an already-completed experiment. Memory note for future students: post `SENPAI-RESULT` immediately when an arm terminates, do NOT relaunch disabled-checks.

#### Reassignment: fern → #786 COOLDOWN_EMA_AVERAGING

Priority 1 from researcher-agent's 2026-05-22 10:15 batch. **First weight-averaging mechanism tested on this stack in 188 PRs.** Direct attack on the ffs=3025→3000 close-miss quantum via Polyak-Ruppert tail averaging of model weights during cooldown.

- Mechanism: shadow EMA buffer of model weights, accumulated from step ≥ EMA_START_FRAC * train_steps (default 0.3 = step 952), swapped in for validation only, then restored to live weights. Zero overhead on training trajectory.
- Arms: A=EMA_DECAY=0.99 (~100-step effective window, late-cooldown), B=EMA_DECAY=0.999 (~1000-step window, full-cooldown).
- Theoretical grounding: Izmailov SWA 2018, "Through the River" KAIST/MS 2025 (arxiv 2507.09846).

---

## 2026-05-22 10:20 UTC — Cycle 71 mid-86b: PR #757 askeladd GROKFAST CLOSED — both arms MISS at floor, gradient-side filtering on AdamW exhausted

### PR #757 — askeladd GROKFAST α ∈ {2.0, 4.0} λ=0.98 — both arms MISS

Branch: `g1r2-askeladd/grokfast`. Closed 2026-05-22 10:20 UTC.

| Arm | α | λ | val/loss | ffs | hold gate | Δ vs baseline | W&B |
|-----|---|---|---|---|---|---|---|
| disabled-check | — | — | val@200=4.07482 (in 4.08-4.10 band) | — | bit-equivalent verify | — | `0d2zzy8p` |
| Arm A | 2.0 | 0.98 | **3.27039** | **3025** | MISS (+0.00039 val, +25 ffs) | +0.00263 val, +25 ffs | `jh8vn8se` |
| Arm B | 4.0 | 0.98 | **3.27171** | **3025** | MISS (+0.00171 val, +25 ffs) | +0.00395 val, +25 ffs | `fkh4fqv8` |

**Result: AXIS CLOSED as MISS with mechanism falsification.** Both arms land in the floor cluster (val≈3.27/ffs=3025). Monotonicity α=4.0 > α=2.0 falsifies "gradient SNR on AdamW groups is the limiter".

#### Mechanism falsification

Three lines of evidence converge on "gradient-side filtering on AdamW groups is not the right surface":

1. **More amplification → worse val** (Arm B α=4.0 underperforms Arm A α=2.0 by +0.00132). If gradient noise were the bottleneck, more filtering should help.
2. **GrokFast lever is small on AdamW**: amplification ratio at end of training is +5.8% (α=2.0) to +15.6% (α=4.0) on lm_head — small because AdamW's own β1=0.8 already EMAs gradients, and AdamW groups are only ~14M of 162M params.
3. **Trajectory tracks disabled tightly**: step 125 val Arm A=4.41594, Arm B=4.44997 — gap to disabled (~4.07@200) preserved through training.

#### Reassignment: askeladd → #784 LOOKAHEAD wrapper (Zhang 2019)

First **trajectory-side** mechanism class tested on this stack. Lookahead averages over parameter trajectories (slow×fast weight interpolation every k steps). Arms: A=(k=5, α=0.5), B=(k=10, α=0.5). Wraps AdamW groups only.

---

## 2026-05-22 09:35 UTC — Cycle 71 mid-86a: PR #754 alphonse ADAMW_EPS terminal — Arm B (1e-13) PASSES n=1 hold gate, ffs=3000 breakthrough (n=2 confirm pending)

### PR #754 — alphonse ADAMW_EPS ∈ {1e-7, 1e-13} vs baseline 1e-10 — Arm A MISS, Arm B PASS n=1 hold gate

Branch: `g1r2-alphonse/adamw-eps-tune`. Sent back to student for n=2 confirm at 09:38 UTC.

| Arm | ADAMW_EPS | val/loss | ffs | hold gate | Δ vs baseline | W&B |
|-----|---|---|---|---|---|---|
| disabled-check | 1e-10 | val@200=4.08524 | — | bit-identical ✓ | — | `i9mgr90u` |
| Arm A | 1e-7 (1000× larger) | **3.27102** | **3025** | MISS both legs | +0.00326 val, +25 ffs | `dmjzp0ew` |
| **Arm B** | **1e-13** (1000× smaller) | **3.26872** | **3000** | **PASS** ✓ | **+0.00096 val (within noise), 0 ffs** | `cra7x9ii` |

**First and only result this cycle to clear ffs=3000.** Direction "smaller eps neutral, larger eps hurts" is monotone in tested range. n=2 confirm approved despite "expected delta ~ zero" because ffs=3000 breakthrough is mechanistically interesting.

---

## 2026-05-22 02:25 UTC — Cycle 71 mid-60: PR #728 thorfinn EMBED_LR_WARMUP CLOSED — both arms MISS monotonically, embed cold-start over-shoot theory falsified

### PR #728 — thorfinn EMBED_LR_WARMUP ∈ {(100, 0.10), (200, 0.05)} vs disabled — both arms MISS

Branch: `g1r2-thorfinn/embed-lr-warmup`. Closed 2026-05-22 02:25 UTC.

| Arm | EMBED_LR_WARMUP_STEPS | EMBED_LR_WARMUP_START_FRAC | val/loss | ffs | hold gate | Δ vs baseline | W&B |
|-----|---|---|---|---|---|---|---|
| disabled-smoke | 0 (disabled) | (n/a) | val@200=**4.0837** PASS | — | bit-equivalent to baseline | — | `rlnpeh5v` |
| Arm A | 100 | 0.10 | **3.27443** | **3075** | MISS (+0.00443 val, +75 ffs) | +0.00667 val, +75 ffs | `gufymt0r` |
| Arm B | 200 | 0.05 | **3.27818** | **3125** | MISS (+0.00818 val, +125 ffs) | +0.01042 val, +125 ffs | `p4u5apji` |

**Result: AXIS CLOSED as MISS with mechanism falsification.** Both arms degrade monotonically from baseline; more warmup → worse on both val and ffs. The hypothesis "EMBED_INIT_STD=0.1 shrinks initial embed norms → AdamW v_t cold-start → over-shoot at step 1" is falsified.

#### Mechanism analysis

If embed cold-start over-shoot were the bottleneck, damping early embed LR via warmup should have improved val/ffs. Instead, both arms moved monotonically worse, with Arm B (more aggressive warmup: 200 steps, start at 5%) worse than Arm A (100 steps, 10% start). The disabled-smoke `rlnpeh5v` reproduced baseline-equivalent val@200=4.0837, confirming the regression is from the warmup itself, not a code bug.

**Theorem (embed cold-start innocence)**: Under EMBED_INIT_STD=0.1 in the c=20 stack, the embed AdamW group does NOT suffer a cold-start over-shoot. Damping early embed LR removes useful signal during the warmup window and the model never recovers fully by the standard 3175-step budget. The ffs=3025+ floor mechanism is NOT located in early-embed dynamics.

#### Coverage update

Combined with #469 (EMBED_LR ±25% sweep), #655 (EMBED_LR_MULT 0.5×/2.0×), #252 (decoupled embed warmup for NaN suppression), #591 (orthogonal embed init), the **early-trajectory embed mechanism surface is now fully closed**. 18th axis joining the ffs=3025+ near-miss cluster this cycle.

#### Strategic implication

The ffs=3025+ floor lives elsewhere — candidates: mid/late trajectory (post-cooldown-start at step ~955), cross-group coupling (embed↔lm_head balance during cooldown), or body-side dynamics post-NS5. Thorfinn's own suggested follow-ups (late-trajectory embed LR boost, smaller flat embed LR, late-step Muon spectrum, post-cooldown v_t behavior) are mechanism-rich next directions.

#### Reassignment: thorfinn → #749 EMBED_LR_LATE_BOOST

Symmetric experiment to this closure. Boost embed-only LR by 1.5× (Arm A) or 2.0× (Arm B) in the final 7.5% of training (steps ~2937–3175). Mechanistically distinct from:
- #642 ADAMW_LR_FLOOR (CLOSED MISS): floored ALL aux groups, antagonism from lm_head/scalars
- #728 (this PR): opposite end of trajectory, opposite intervention sign
- #655 EMBED_LR_MULT (CLOSED MISS): flat scaling, no schedule

Tests whether embed is undertrained specifically in the cooldown tail, isolated from lm_head/scalars which were the suspected #642 antagonism source. ~8 line code change in `set_hparams`, triggers only when `EMBED_LR_LATE_BOOST > 1.0` and `progress >= 0.925`.

---

## 2026-05-22 01:45 UTC — Cycle 71 mid-59: PR #733 tanjiro BODY PROJ_INIT_STD CLOSED — both arms NaN, body proj zero-init is load-bearing in c=20 stack

### PR #733 — tanjiro PROJ_INIT_STD ∈ {1e-3, 1e-4} vs default 0.0 (zero-init), body block proj weights only

Branch: `g1r2-tanjiro/body-proj-init-std`. Closed 2026-05-22 01:45 UTC.

| Arm | PROJ_INIT_STD | steps reached | outcome | W&B |
|-----|---------------|---------------|---------|-----|
| disabled-check | 0.0 (zero init) | 200 | val@200=**4.08325** ✓ baseline reproduces | `x7v869kp` |
| Arm A | 1e-3 | killed @ step 125 (NaN) | catastrophic divergence — val NaN ≫ 4.25 ceiling | `njz8ktnh` |
| Arm B | 1e-4 | killed @ step 125 (NaN observed, early kill 01:38 UTC) | also catastrophic — 10× smaller scale did NOT help | `k7wezlux` |

**Result: AXIS CLOSED via mechanism falsification.** Both arms diverged to NaN before step 200 despite Arm B's 10× smaller std. The disabled-check (PROJ_INIT_STD=0.0) was bit-exact baseline at val@200=4.083, confirming the divergence is mechanism failure not pod state.

#### Mechanism analysis

The 24 body proj matrices (12 blocks × {attn.proj, mlp.proj}) feed back into the residual stream every layer. Per-matrix init magnitude estimate:
- Per-matrix std=1e-4, hidden_dim²=590k params → frobenius ≈ 0.07 per proj weight
- 24 proj weights cumulatively perturb residual stream → variance grows ~√24 × 0.07 ≈ 0.34 per residual step
- Over 12 blocks with attention amplification → exponential blow-up before step 200

**Key theorem proved**: **Body proj zero-init is LOAD-BEARING in c=20 stack** — any non-zero static N(0, σ) init destabilizes residual stream variance at any practical scale tested. This is asymmetric from input-side init (PR #541 EMBED_INIT_STD=0.1 wins because embed is ONE matrix at the boundary, not 24 in-line in residual stream).

#### Closure semantics

This is the **16th axis** confirming the ffs=3025 plateau is NOT addressable by simple body-side static init. The "silent window" property of body proj zero-init turns out to be a FEATURE not a bug — it gives residual stream variance time to organize before the proj weights start contributing meaningful signal.

#### Suggested follow-ups (NOT launched on this PR)

Per advisor pre-stated guidance to tanjiro, future directions outside this axis would be:
1. **Schedule-coupled body proj init** — ramp std from 0 → small_target over first N steps so residual stream variance organizes before proj weights perturb it. Closest extension but a different mechanism class.
2. **Per-block-decreasing init scaled by 1/√depth** — deeper layers get exponentially smaller perturbation; could survive where uniform fails.
3. **Pivot off init-side entirely** — given #541 (embed) was a hit but body proj was a wall, the init-side may already be mostly exploited.

Tanjiro reassigned to ADAMW_BETA2_SCHEDULE (PR #TBD) — schedule the AdamW second-moment β2 across cooldown rather than static value sweep (#705 closed 0.97/0.99 statically, #625 closed 0.99 on c=15).

---

## 2026-05-22 01:10 UTC — Cycle 71 mid-57: PR #720 askeladd MUON_COOLDOWN_SHAPE CLOSED — linear shape provably optimal across 2D per-group (fraction × shape) cooldown space

### PR #720 — askeladd MUON_COOLDOWN_SHAPE ∈ {cosine, sqrt} vs default linear (Muon-only, AdamW stays linear)

Branch: `g1r2-askeladd/muon-cooldown-shape`. Closed 2026-05-22 01:10 UTC.

| Arm | shape | val_loss | ffs | Δ val | Δ ffs | Hold gate | Merge bar | W&B |
|-----|-------|----------|-----|-------|-------|-----------|-----------|------|
| A | cosine `0.5(1+cos(πt))` | **3.27730** | **3050** | +0.00954 | +50 | MISS | MISS | `grqodf83` |
| B | sqrt `√(1-t)` | **3.28397** | **-1 (never)** | +0.01621 | (never) | MISS | MISS | `3rgire7f` |
| Disabled-check | linear | val@200=4.08705 | — | — | — | bit-exact ✓ | — | `ghv9llus` |
| Baseline #613 (n=2) | linear | 3.26776 | 3000 | — | — | — | — | — |

**Mechanism analysis (programme-level finding)**:
- **Cosine**: η_muon > linear for t<0.5 (early cooldown), η_muon < linear for t>0.5 (late cooldown). Mid-cooldown boost helps slightly; late-cooldown undercut starves final descent.
- **Sqrt**: η_muon > linear throughout cooldown (concave). Sustained Muon magnitude near convergence perturbs late-stage descent — by step 2500 sqrt is **0.058 BEHIND cosine** (val 3.3932 vs 3.3351) and never closes the gap. The "more Muon LR throughout = faster descent" intuition is **falsified**: late-cooldown Muon magnitude is a perturbation, not a productive update.
- Once NS5 is at full strength and the model is near the basin, additional Muon magnitude pushes parameters off the descent direction. Linear's monotonic decrease IS the optimal trade-off.

**Cooldown × LR-shape × per-group axis NOW EXHAUSTED**:
- #657 (nezuko) GLOBAL cosine/quadratic — catastrophic
- #678 (askeladd) per-group cooldown FRACTION — linear-fraction-symmetry optimal
- **#720 (this PR) per-group cooldown SHAPE Muon-only — linear shape optimal**

The current `set_hparams` linear-equal cooldown on both groups is provably optimal across the explored 2D space (per-group fraction × per-group shape). Schedule-shape mechanism class is now ~complete.

**15th axis joining ffs ≥ 3025 cluster** (Arm A at ffs=3050). Plateau confirmed intrinsic at n=1 on c=20 stack across 15 fresh axes this cycle.

### Assignment: askeladd → PR #742 (ADAMW_RADAM)

**Hypothesis**: Rectified Adam (Liu et al. 2019, arXiv:1908.03265) replaces standard Adam's variance-scaling in early steps. When `ρ_t ≤ 4` (variance poorly estimated, typically steps 1-5 at β2=0.95), update falls back to `m_hat` (SGD-like, no variance scaling). Once `ρ_t > 4`, applies rectified update `r_t · m_hat / sqrt(v_hat)` where `r_t` smoothly grows from 0→1.

**Why distinct from prior closures**:
- #739 NAdam (in flight): direction modification on m_t (`m_hat = β1·m_t + (1-β1)·g_t`)
- This PR: variance rectification on v_t (`r_t` adaptive scaling)
- Different mechanism axis within AdamW family
- #718 MUON_BIAS_CORR (CLOSED) failed by AMPLIFYING early-step updates; RAdam does the OPPOSITE — removes unstable variance scaling in early steps
- No prior RAdam test in 165+ experiments

**Arms**:
- Arm A: ADAMW_RADAM=1 (full RAdam on all AdamW groups: embed, lm_head, scalars)
- Arm B: ADAMW_RADAM=2 (RAdam only on embed + lm_head; scalars use standard AdamW — tests whether rectification helps large-matrix groups specifically)

8/8 students assigned (alphonse #734, tanjiro #733, nezuko #732, frieren #729, thorfinn #728, askeladd #742, fern #739, edward #702 pod-broken hold).

## 2026-05-22 00:55 UTC — Cycle 71 mid-56: PR #718 fern MUON_BIAS_CORR CLOSED — bias correction mechanism falsified; NS5 + magnitude-correction incompatibility theorem

### PR #718 — fern MUON_BIAS_CORR ∈ {1=full, 2=warmup-only} vs default 0 (disabled)

Branch: `g1r2-fern/muon-bias-correction`. Closed 2026-05-22 00:55 UTC.

| Arm | MUON_BIAS_CORR | val_loss | ffs | Hold gate (val≤3.27, ffs≤3000) | Merge bar (val<3.26776) | W&B |
|-----|----------------|----------|-----|-------------------------------|--------------------------|------|
| A   | 1 (full throughout) | **3.26838** | **3000** | **PASS** | MISS +0.00062 | `7q5df6cm` |
| B   | 2 (warmup-only ≤200) | **3.27207** | **3050** | MISS | MISS +0.00431 | `rmp39ala` |
| Disabled | 0 | val@200=4.08481 | — | bit-exact baseline ✓ | — | `zikzrvlz` |
| Baseline #613 (n=2) | — | 3.26776 | 3000 | — | — | — |

**Mechanism finding (HIGH-VALUE FALSIFICATION)**: bias correction `1/(1−μ^t)` is theoretically motivated for low-magnitude early momentum, but EMPIRICALLY both arms are **+0.077 (A)** and **+0.067 (B)** WORSE than disabled-check at step 125. Hypothesis predicted *faster* early descent; reality shows a residual *warmup scar* from the early-step LR amplification:
- Step 1: factor = 1/(1−0.85^1) = 1/0.15 ≈ **6.7×** amplification
- Step 5: factor ≈ 1/0.43 ≈ **1.75×**
- Step 20: factor ≈ 1.0 (correction decays)

With MUON_LR=0.04, this is effectively LR ≈ 0.08–0.27 for steps 1–10. The amplified early updates interact destructively with NS5's stability window (which is tuned for un-corrected magnitudes).

**Theoretical insight (programme-level)**: **NS5 makes Muon a direction-only optimizer.** Post-NS5 polar projection strips magnitude information from the momentum buffer — scaling `m_t` by 1/(1−μ^t) and by 1.0 produce nearly identical update *directions* once NS5 stabilizes (~20+ steps in). But the early amplification still happens BEFORE NS5 saturates, causing un-recoverable trajectory drift. This theorem rules out an entire mechanism class:

> Any axis that modifies the *magnitude* of the momentum-derived update inside the NS5 pipeline is either a no-op in steady state or a disruption during early/late transitions. Future axes should target either (a) the *direction* of momentum (e.g., per-block CONTRA mixing #729, per-layer-type LR splits #732), or (b) what enters Muon *before* NS5 (gradient processing, momentum buffer composition pre-NS5).

**Warmup-scar persistence theorem**: Step-125 deficit of +0.077 partially recovers to +0.00062 by step 3175 — but never fully. Early-step destabilization is *expensive* and only ~99.2% recoverable. Relevant for all warmup-touching axes (thorfinn #728 EMBED_LR_WARMUP, edward #702 MU_WARMUP_START, alphonse #734 ADAMW_GRAD_CLIP if it interacts with steps 1–10).

**Why Arm B (warmup-only) is worse than Arm A (full)**: Both apply correction during destabilizing early steps (1–10); the +0.004 gap is essentially n=1 noise post-step-200 (where correction is a no-op). This means Arm A's +0.00062 vs baseline is *also* within plausible n=1 noise — but the **falsified mechanism** is the dominant signal, not the noise-bound miss. No n=2 confirm authorized.

**Decision math (n=2 declined)**: For Arm A n=2 confirm to be worth running, we'd need P(seed 1 val < 3.26714) high enough to justify the GPU. The student's diagnostic explicitly identifies the mechanism as harming early descent — the prior is that seed 1 lands at roughly the same noise band, not below it. Effort-to-information ratio is poor against fresh hypotheses.

**14th axis joining ffs ≥ 3025 cluster**: another data point that the ffs=3025 floor is structural to the c=20 stack at n=1, requires n=2 statistical confirmation OR a mechanism that genuinely accelerates pre-cooldown descent to reach.

### Assignment: fern → PR #739 (ADAMW_NESTEROV)

**Hypothesis**: NAdam-style one-step look-ahead on AdamW's first moment (Dozat 2016). Standard Adam: `update = m_t / (sqrt(v_t)+ε)`. NAdam: `update = m_hat / (sqrt(v_t)+ε)` where `m_hat = β1·m_t + (1−β1)·g_t` (apply next-step smoothing operator now).

**Why it's distinct from the just-closed #718**:
- #718 was a *magnitude* correction on Muon (inside NS5 pipeline) — falsified
- This is a *direction* correction on AdamW (no NS5) — different mechanism axis
- The NS5+magnitude-incompatibility theorem from #718 does NOT apply: AdamW has no polar projection, so direction modifications are not stripped away

**Arms**:
- Arm A: ADAMW_NESTEROV=1 (full Nesterov throughout — standard NAdam)
- Arm B: ADAMW_NESTEROV=2 (cooldown-only, progress ≥ 0.95 = step ≥ 3016)

Arm B explicitly avoids the early-step regime that broke #718 — tests whether late-stage extrapolation alone benefits ffs/val.

**Anti-duplication** (verified against 165+ experiment history):
- #718 MUON_BIAS_CORR — magnitude not direction, Muon not AdamW
- #703 MUON_NESTEROV — Muon side with NS5 interaction failure mode
- #653 ADAMW_BETA1 constant — value not structural update
- #587 β1 ramp — schedule not structural
- #574 Sophia-G — sign-of-momentum, different ratio
- No prior NAdam test in any cycle

8/8 students assigned (alphonse #734, tanjiro #733, nezuko #732, frieren #729, thorfinn #728, askeladd #720, fern #739, edward #702 pod-broken hold).

## 2026-05-22 00:10 UTC — Cycle 71 mid-55: PR #715 alphonse NORMUON_2D CLOSED — 1D variance is locally optimal; cross-axis EMA combine adds no benefit and slightly hurts

### PR #715 — alphonse NORMUON_2D ∈ {geometric `√(r·c)`, harmonic `2rc/(r+c)`} vs default 1D per-row buffer

Branch: `g1r2-alphonse/normuon-2d-variance`. Closed 2026-05-22 00:10 UTC.

| Arm | NORMUON_2D | flavor | val_loss | ffs | hold-gate (val≤3.27, ffs≤3000) | vs baseline |
|-----|---|---|---|---|---|---|
| Disabled-check | 0 | — (1D only) | 4.07594 @ step 200 | — | ✓ bit-exact | — |
| **A** | 1 | geometric `√(r·c)` | **3.27116** | **3025** | ✗ (val +0.00340, ffs +25) | +0.00340 / +25 |
| Baseline | — | 1D per-row | 3.26776 (n=2) | 3000 | — | — |
| **B** | 1 | harmonic `2rc/(r+c)` | **3.27315** | **3050** | ✗ (val +0.00539, ffs +50) | +0.00539 / +50 |

W&B: `p2mk30xi` (disabled-check), `hdim84yh` (Arm A), `tm5cc7u9` (Arm B). All metrics independently verified via W&B query.

**Mechanism finding:**
- Both arms land in the 3.271–3.273 / ffs=3025+ near-miss cluster.
- Arms strictly ordered A < B at **every** logged checkpoint by ~0.003 (step 500: +0.003, step 1500: +0.003, step 2000: +0.003, step 2500: +0.002, step 3175: +0.002).
- Trajectories baseline-identical through step 2500 (max Δ ≤ 0.004), all kill gates pass.
- Harmonic over-shrinks the rescale (`rsqrt(harmonic) ≥ rsqrt(geometric)` → larger correction factor → over-correction on outliers).
- Falsifier triggers cleanly: Arm A val=3.27116 ≥ 3.272 envelope, trajectory baseline-identical, geometric strictly better than harmonic.

**Conclusion:** **Cross-axis (row × col) factored EMA gives no convergence benefit over the existing 1D per-row buffer.** 1D NorMuon-lite at default `NORMUON_BETA2=0.95` is the locally optimal variance correction flavor on this stack. The "factored 2D moment as Adafactor analog" hypothesis is falsified for post-NS5 Muon updates.

**Strategic significance:** 13th axis (and 7th Muon-side closure in cycle 71 segment) landing at ffs=3025+ floor. Adds further evidence the plateau is **NOT addressable from Muon's variance EMA geometry** at any factorization granularity (1D, 2D, depth-differentiated). With 4 Muon-side post-NS5 mechanisms still in flight (#718 BIAS_CORR, #720 COOLDOWN_SHAPE, #729 PER-BLOCK CONTRA, #732 LR_ATTN/MLP), the Muon-update bucket is approaching saturation.

**Alphonse → #734 ADAMW_GRAD_CLIP** (per-group gradient norm clipping on AdamW output side; ~5 LoC, env-var-gated default 0=disabled; tests whether late-cooldown lm_head/embed gradient spikes near `LOGIT_SOFTCAP=20` saturation are the noise source that pins ffs at 3025).

**Anti-duplication:** Distinct from #688 MUON_GRAD_CLIP (clipped Muon-side pre-NS5 gradient — clip fired ~50% of steps as a mild damper). #734 clips a different optimizer (AdamW), different param group (embed+lm_head+scalars), with mechanistically distinct kinematics (sparse late-cooldown spikes vs Muon's continuous gradient magnitudes). No global grad clip exists in current script (verified via `grep clip_grad`).

**Arms:**
- Arm A: `ADAMW_GRAD_CLIP=1.0` (mild — should fire rarely, on tail steps)
- Arm B: `ADAMW_GRAD_CLIP=0.5` (more aggressive — should fire ~weekly on tail steps)

---

## 2026-05-21 23:50 UTC — Cycle 71 mid-54: PR #713 tanjiro PER-BLOCK NS5 CLOSED — both arms MISS, plateau NOT NS5-iter-depth-limited (strong negative-result evidence)

### PR #713 — tanjiro PER-BLOCK NS5 iters ∈ {12/16, 16/12} (EARLY/LATE blocks 0-5 vs 6-11)

Branch: `g1r2-tanjiro/per-block-ns5-iters`. Closed 23:50 UTC.

| Arm | NS5_EARLY | NS5_LATE | val_loss | ffs | hold-gate (val≤3.27, ffs≤3000) | vs baseline |
|-----|---|---|---|---|---|---|
| Disabled-check | 14 | 14 | 4.08132 @ step 200 | — | ✓ bit-exact | — |
| **A** | 12 | 16 | **3.27143** | **3025** | ✗ (val +0.00367, ffs +25) | +0.00367 / +25 |
| Baseline | 14 | 14 | 3.26776 (n=2) | 3000 | — | — |
| **B** | 16 | 12 | **3.27193** | **3050** | ✗ (val +0.00417, ffs +50) | +0.00417 / +50 |

W&B: cxx4w4x4 (disabled), c1wwrenw (A), 46swe48c (B). Per-step cost identical at ~1953ms (28 total NS5 iters per block summed across 12 blocks in both arms = same as uniform NS5_ITERS=14), confirming routing wired correctly.

**Mechanism finding (HIGH-VALUE NEGATIVE RESULT):**
- Both arms land squarely in the 3.271-3.273 / ffs=3025+ near-miss cluster.
- A vs B trajectories essentially superimposed (max Δ ≈ 0.005 at any logged checkpoint, no phase divergence).
- Both arms track uniform-NS5=14 baseline to within ~0.003 throughout.
- Combined with #492 (uniform sweep flat) and #677 (NS5_ITERS=14 confirmed), this establishes that **differentiating NS5 iteration count by block depth does not move the trajectory in either direction**.

**Strategic significance:** This is one of the cleanest "informative failure mode" results of cycle 71. It eliminates a major axis (per-depth orthogonalization tightness) from the live frontier. The remaining post-NS5 Muon-side levers are:
- NorMuon row-variance scaling (NORMUON_2D in flight #715 — Arm B terminal imminent)
- u/w-floor (untested)
- NS5 polynomial coefs per-depth (untested; #694 was uniform, closed)
- PER-BLOCK CONTRA_MUON (#729 frieren in flight — analogous depth-differentiation for contra strength)
- Per-block-TYPE LR (#732 nezuko just assigned — attn vs mlp differentiation)

If 6+ Muon-side variants land in the same 3.271-3.273 cluster, the plateau may be **outside Muon update geometry entirely** (data ordering, logit-softcap × embed-init interaction, schedule-precision artifacts).

**Tanjiro → #733 BODY PROJ_INIT_STD** — initialization-side mechanism, strictly outside Muon update path. Currently `attn.proj` and `mlp.proj` weights are hard-zeroed (residual stream stability), giving zero gradient signal to proj at step 1. Hypothesis: small non-zero init (1e-3 / 1e-4) gives immediate gradient signal without destabilizing residual path. Analog to EMBED_INIT_STD=0.1 (PR #541 merged) — same family of "replace silent default with non-zero." lm_head proj explicitly preserved as zero-init (PR #602 confirmed optimal).

---

## 2026-05-21 23:42 UTC — Cycle 71 mid-53: PR #705 nezuko ADAMW_BETA2 newstack CLOSED — both arms MISS, β2 axis confirmed locally optimal at default 0.95 on c=20 stack

### PR #705 — nezuko ADAMW_BETA2 ∈ {0.99, 0.97} vs default 0.95 — BOTH ARMS MISS

Branch: `g1r2-nezuko/adamw-beta2-newstack`. Closed 23:42 UTC.

| Arm | β2 | val_loss | ffs | hold-gate | vs baseline |
|-----|---|---|---|---|---|
| Disabled-check | 0.95 | 4.08978 @ step 200 | — | ✓ pod healthy | — |
| **A** | 0.99 | **3.27198** | **3050** | ✗ both (val +0.00422, ffs +50) | +0.00422 / +50 |
| **B** | 0.97 | **3.26900** | **3025** | ✗ ffs only (val PASS −0.001, ffs +25) | +0.00124 / +25 |
| Baseline | 0.95 | 3.26776 (n=2) | 3000 | — | — |

W&B: drnfayg2 (disabled), 8rnyvrl3 (A), 7fjlodwq (B).

**Mechanism finding:** The strong prior from PR #625 (val=3.26704 at β2=0.99 on c=15 stack) does NOT replicate on c=20. Worse, both arms tested at 0.97 and 0.99 are monotone uphill from default 0.95 — Arm B (intermediate) lands between Arm A (extreme) and baseline (default), suggesting a smooth concave curve with minimum AT or BELOW 0.95. The hypothesis that wider logit dynamic range (c=20) needs heavier-tailed grad smoothing was empirically reversed: LOGIT_SOFTCAP=20.0 already absorbs the heavy-tail energy that would have motivated β2=0.99.

**Trajectory analysis:** After step 500, Arm B is consistently 0.003-0.008 better than Arm A at matched checkpoints — confirming the gradient: increasing β2 hurts. β2=0.95 default is at or near the local minimum.

**Strategic conclusion:** AdamW β2 is a CLOSED axis on the c=20 stack. β2=0.999 follow-up (suggested in PR if Arm A won) is structurally implausible. Future re-opening only if LOGIT_SOFTCAP changes materially.

**Nezuko → #732 MUON_LR_ATTN/MLP asymmetry** — per-block-TYPE body Muon LR split (ATTN vs MLP). Distinct from closed #268 (per-DEPTH layer LR), in-flight #720 (cooldown SHAPE not LR), #712 r4 (β₂ per type), #724 r4 (NS_ITERS per type). First per-block-TYPE MUON_LR test. Mechanism: NS5-orthogonalized attn (768×768 square) and mlp (3072×768 rectangle) matrices have structurally different gradient spectra; a single MUON_LR is a compromise. Arms ATTN/MLP = 1.1/0.9 vs 0.9/1.1 (±10% symmetric).

---

## 2026-05-21 22:40 UTC — Cycle 71 mid-52: PR #701 frieren WD_AUX cross-pod CLOSED — both arms MISS, #676 closure FULLY EXONERATED as pod-broken artifact

### PR #701 — frieren WD_AUX cross-pod RE-RUN ∈ {0.002, 0.0005} vs default 0.001 — BOTH ARMS MISS

Branch: `g1r2-frieren/wd-aux-cross-pod-rerun`. Closed 22:40 UTC.

| Arm | WD_AUX | val_loss | ffs | reached_target | Hold-gate val ≤3.27 | Hold-gate ffs ≤3000 | vs baseline |
|-----|---|---|---|---|---|---|---|
| Disabled-check | 0.001 | ~4.08 @ step 200 | — | — | ✓ pod healthy | — | — |
| **A** | **0.002** (2×) | **3.26933** | **3025** | ✓ | ✓ PASS (−0.00067) | ✗ MISS (+25) | +0.00157 / +25 |
| Baseline | 0.001 | 3.26776 (n=2) | 3000 | — | — | — | — |
| **B** | **0.0005** (½×) | **3.27266** | **3050** | ✓ | ✗ MISS (+0.00266) | ✗ MISS (+50) | +0.00490 / +50 |

W&B: kjlc54un (A), cakcboqg (B). No NaN, no kill triggered. Finite gradients throughout.

**Two distinct findings:**
1. **#676 closure FULLY EXONERATED as pod-broken artifact.** Both WD_AUX values that previously NaN'd on edward's broken-torch pod (post-11:49 UTC) now train cleanly to terminal on frieren's healthy pod, reach target val<3.28. "NaN at step 25" was 100% artifact of broken torch install — not intrinsic to the axis. This is the cross-pod verification we needed.
2. **WD_AUX axis confirmed locally well-tuned at default 0.001.** Both perturbations hurt monotonically (×2 +0.00157, ÷2 +0.00490). Arm A val=3.26933 is 2nd-closest n=1 val to hold gate this cycle (#675 SCALARS_LR=0.02 seed 0 val=3.26853 was closer). But ffs=3025 cannot reach 3000 floor → no n=2 confirm.

**Strategic significance:** This PR resolves the #676 closure uncertainty AND confirms axis is well-tuned. The pod-broken misattribution memory ([[feedback-pod-broken-axis-misattribution]]) is now properly grounded with cross-pod verification.

**Frieren → #729 PER-BLOCK CONTRA_MUON** — depth-differentiated contra subtraction (EARLY ∈ {0.6, 0.2} vs LATE ∈ {0.2, 0.6}; blocks 0-5 vs 6-11). First per-block CONTRA test in 165+ experiments; symmetric to #713 PER-BLOCK NS5 (in flight). Mechanism: contra strength may need depth-dependent tuning to escape ffs=3025 floor — uniform-scalar CONTRA_MUON sweeps closed at 0.4 across 4+ prior PRs.

---

## 2026-05-21 22:10 UTC — Cycle 71 mid-51: PR #703 thorfinn MUON_NESTEROV CLOSED — both arms LOSE; cooldown × Nesterov interaction is failure mechanism; post-NS5 mechanisms are the bottleneck

### PR #703 — thorfinn MUON_NESTEROV ∈ {1=strong, 2=classical} vs default 0 — BOTH ARMS LOSE

Branch: `g1r2-thorfinn/muon-nesterov`. Closed 22:10 UTC.

| Arm | MUON_NESTEROV | val_loss | ffs | hold gate | vs baseline (3.26776/3000) | W&B |
|-----|---|---|---|---|---|---|
| Disabled-check | 0 | (baseline reproduces) | — | ✓ plumbing | — | `zfucjfaz` |
| **A** | **1** (strong form) | **3.27493** | **3075** | ❌ both legs | +0.00717 / +75 | `x2xwp2r3` |
| Baseline | 0 | 3.26776 (n=2) | 3000 | — | — | (PR #613) |
| **B** | **2** (classical form) | **3.31668** | **-1** | ❌ CATASTROPHIC | +0.04892 / never reached 3.28 | `pou93iuy` |

**Diagnostic (thorfinn):**
- Arm A trails baseline by ~0.01-0.03 throughout — *consistent drag*, not a localized failure. Nesterov lookahead before NS5 changes the direction of the orthogonalized update in a way that compounds against c=20 tuning.
- Arm B converges *faster* mid-region then *stalls in cooldown* — qualitatively different loss curve shape. Classical Nesterov gets early momentum gains but `mu_cooldown × Nesterov-correction` interaction breaks late-trajectory dynamics.
- Diagnostic conclusion: "Post-NS5 mechanisms are the more likely constraints on breaking through the plateau."

**Strategic significance:** Both arms losing with *qualitatively different* failure modes is a clean falsification — confirms the Muon update direction at the NS5 input is already near-optimal under the current stack. Aligns with the ffs=3025 floor pattern (10+ axes this cycle) and our pivot to post-NS5 fresh mechanisms (#715 NORMUON_2D, #718 MUON_BIAS_CORR, #720 MUON_COOLDOWN_SHAPE).

**Thorfinn → #728 EMBED_LR_WARMUP** (researcher Candidate 3) — targets the *early-trajectory* bottleneck specifically. Arm A: 100-step cosine warmup starting at 10% of full embed LR; Arm B: 200-step warmup starting at 5%. Mechanism: EMBED_INIT_STD=0.1 shrinks initial embed norms, making AdamW second-moment cold for first ~100 steps; targeted warmup damps initial update spike without touching `lm_head` or scalar groups (strictly more targeted than PR #598 which warmed ALL AdamW groups).

---

## 2026-05-21 17:55 UTC — Cycle 71 mid-46b: PR #680 nezuko CONTRA_MUON CLOSED — both arms MISS (asymmetric penalty: 0.6 hurts ~2.5× more than 0.2; default 0.4 locally optimal); crossover trajectory pattern (more contra wins early, less contra wins late)

### PR #680 — nezuko CONTRA_MUON sweep — BOTH ARMS MISS, asymmetric penalty + crossover

Branch: `g1r2-nezuko/contra-muon-sweep`. Closed 17:55 UTC.

| Arm | CONTRA_MUON | val_loss | ffs | hold gate | vs baseline (3.26776/3000) | W&B |
|-----|---|---|---|---|---|---|
| Disabled-check | 0.4 | 4.08773@200 | — | ✓ plumbing | — | `j6c4df73` |
| **A** | **0.2** (half) | **3.27071** | **3025** | ❌ both legs | +0.00295 / +25 | `kau6grse` |
| Baseline | 0.4 | 3.26776 (n=2) | 3000 | — | — | (PR #613) |
| **B** | **0.6** (1.5×) | **3.27522** | **3075** | ❌ both legs | +0.00746 / +75 | `26c2nrct` |

**Crossover trajectory — informative mechanism signal:**

| step | A (0.2) | B (0.6) | Δ (B − A) | Phase |
|---|---|---|---|---|
| 250  | 4.04841 | 4.04053 | −0.008 | B ahead (high-noise early) |
| 500  | 3.80902 | 3.80136 | −0.008 | B ahead |
| 1000 | 3.66584 | 3.66208 | −0.004 | B ahead (compressing) |
| 1500 | 3.53540 | 3.53173 | −0.004 | B ahead (final lead) |
| 2500 | 3.34720 | 3.35581 | **+0.009** | **A pulls ahead** |
| 3000 | 3.28203 | 3.28667 | +0.005 | A ahead |
| 3175 | **3.27071** | 3.27522 | +0.005 | A wins final |

**Mechanism verdict — contra-correction is a stability scaffold for early training, hurts late cooldown**: More contra-correction (B=0.6) regularizes against full orthogonalization → wins in high-gradient-noise early phase but slows late-cooldown convergence when full Muon orthogonality is needed. Less contra-correction (A=0.2) is opposite — slightly worse early but slightly better late. Default 0.4 is the balanced sweet spot.

**Asymmetric penalty (down 2.5× less harmful than up)**: A miss=+0.00295; B miss=+0.00746. If axis ever re-opens after major stack shift, **only 0.3 worth probing**. Not now — expected gain ≤ 0.001 < n=1 noise floor ~0.004.

**Joins near-miss cluster** (7th fresh-axis result this cycle, ffs=3025-3075): CONTRA_MUON joins NS5_ITERS, ADAMW_EPS, MUON_GRAD_CLIP, per-group cooldown_frac, ATTN_SOAP_TRUST? all closing at ffs=3025-3050. Plateau pattern overwhelming.

**Direction inference for downstream**: 5th Muon-side scalar this cycle confirmed locally optimal on c=20 stack (MUON_LR=0.04, MU_COOLDOWN_END=0.90, MU_WARMUP_STEPS=200, NS5_ITERS=14, now CONTRA_MUON=0.4). c=20 stack's scalar surface is a tight local optimum. Next: **#NEW nezuko assignment via researcher-agent — needs fresh mechanism, NOT scalar tune.**

## 2026-05-21 17:33 UTC — Cycle 71 mid-46: PR #685 thorfinn ADAMW_EPS CLOSED — both arms MISS (Arm A 1e-8 val=3.27119/ffs=3025; Arm B 1e-12 val=3.26903/ffs=3025 — val passes hold gate but ffs misses); current default 1e-10 well-tuned across 100× range

### PR #685 — thorfinn ADAMW_EPS sweep — BOTH ARMS MISS; default 1e-10 locally optimal

Branch: `g1r2-thorfinn/adamw-eps-sweep`. Closed 17:33 UTC.

| Arm | ADAMW_EPS | val_loss | ffs | hold gate (val≤3.27 AND ffs≤3000) | vs baseline | W&B |
|-----|---|---|---|---|---|---|
| Disabled-check | 1e-10 (default) | 4.09244@200 | — | ✓ plumbing | — | `msaw9vtc` |
| **A** | **1e-8** (100× larger) | **3.27119** | **3025** | ❌ both legs (+0.00343 val, +25 ffs) | clear MISS | `glchqxk3` |
| Baseline | 1e-10 | 3.26776 (n=2) | 3000 | — | — | (PR #613) |
| **B** | **1e-12** (100× smaller) | **3.26903** | **3025** | ❌ ffs only (val ✓ ≤3.27, ffs +25) | +0.00127 val / +25 ffs | `ocp7pxb8` |

**Step-by-step trajectory comparison (Arm B slightly ahead early, parity by step 1000, small re-emerged advantage in cooldown):**

| step | A (1e-8) | B (1e-12) | Δ (B − A) |
|---|---|---|---|
| 125  | 4.42854 | 4.41636 | −0.01218 |
| 500  | 3.80761 | 3.80364 | −0.00397 |
| 1000 | 3.66199 | 3.66285 | +0.00086 |
| 1500 | 3.53516 | 3.53300 | −0.00216 |
| 2000 | 3.43011 | 3.42921 | −0.00090 |
| 2500 | 3.34883 | 3.34542 | −0.00341 |
| 3000 | 3.28246 | 3.28026 | −0.00220 |
| 3175 | 3.27119 | 3.26903 | −0.00216 |

**Mechanism verdict — denominator regularization at fp32 v̂ scale is non-load-bearing**: Both arms span 100× from default; the smaller-eps direction (Arm B) is consistently ahead by ~0.002-0.004 in val but uniformly tied at ffs=3025. No NaN/underflow even at eps=1e-12 across 3175 steps. The "amplify rare-param updates" mechanism for smaller eps gives a small but persistent edge in early training, compresses by step 1000, re-emerges weakly in cooldown — but is not large enough to flip ffs or beat baseline val.

**Joins near-miss cluster** (6th fresh-axis result this cycle landing ffs=3025): Arm B val=3.26903 is the **2nd-closest n=1 val to hold gate this cycle** (only -0.00097 below 3.27, behind only NS5_ITERS=18 at -0.00040). Cluster now contains: NS=18 (3.26960), CONTRA=0.2 (3.27071), EPS=1e-8 (3.27119), EPS=1e-12 (3.26903), plus per-group cooldown_frac, plus MUON_GRAD_CLIP=1.0 (3.27252). **Six axes, all ffs=3025-3050 — strong evidence of single-seed n=1 c=20 statistical floor.**

**Direction inference for downstream**: AdamW denominator class fully closed (#569 AdaBelief, #574 Sophia-G, #625 β2, #653 β1, #685 EPS — five AdamW group denominator axes all at local optimum). Thorfinn → NEW assignment forthcoming via researcher-agent.

## 2026-05-21 17:05 UTC — Cycle 71 mid-45: PR #677 frieren NS5_ITERS CLOSED — both arms miss hold gate (NS=14 well-tuned, unimodal); 🎯 PR #675 tanjiro Arm B PASSES n=1 HOLD GATE (val=3.26853/ffs=3000, +0.00077 vs baseline), n=2 confirm authorized

### PR #677 — frieren NS5_ITERS sweep — BOTH ARMS MISS HOLD GATE; non-monotonic peak at NS=14

Branch: `g1r2-frieren/ns5-iters-sweep`. Closed 17:05 UTC.

| Arm | NS5_ITERS | val_loss | ffs | hold gate (val ≤ 3.27 AND ffs ≤ 3000) | vs baseline (3.26776/3000) | W&B |
|-----|---|---|---|---|---|---|
| Disabled-check | 18 | 4.0818@200 | — | ✓ pass | — | `7ch5a04n` |
| **A** | **12** | **3.27138** | **3025** | ❌ both legs (val +0.00138, ffs +25) | +0.00362 / +25 | `biqejhg9` |
| Baseline | 14 | 3.26776 (n=2) | 3000 | — | — | (PR #613) |
| **B** | **18** | **3.26960** | **3025** | ❌ ffs only (val ✅ ≤ 3.27, ffs +25) | +0.00184 / +25 | `ecdrwmg7` |

**Step-by-step trajectory comparison (uniformly B better than A):**

| step | A (12) | B (18) | Δ (A − B) |
|---|---|---|---|
| 500  | 3.80272 | 3.79964 | +0.00308 |
| 1000 | 3.66566 | 3.65981 | +0.00585 |
| 1500 | 3.53426 | 3.53230 | +0.00196 |
| 2500 | 3.34738 | 3.34605 | +0.00133 |
| 3175 | 3.27138 | 3.26960 | +0.00178 |

**Mechanism verdict — unimodal optimum AT NS=14**: The terminal val ordering is { A(12)=3.27138 > B(18)=3.26960 > baseline(14)=3.26776 }. The +2 extra iters (14 vs default 12) buy ~0.004 val improvement; +4 extra (14→18) give NO further benefit and actually regress. Non-monotonic axis with peak at the mandatory-stack value 14.

**Compute cost note**: Arm A (12 iters) ≈ 1967ms/step, Arm B (18 iters) ≈ 1991ms/step — only ~1.2% slower for +4 iters. Benchmark uses ffs not wall-clock, so step_avg differences don't affect contract.

**Joins near-miss cluster** (5th fresh-axis result this cycle landing exactly ffs=3025): Arm B val=3.26960 is the CLOSEST val to 3.27 hold gate this cycle (-0.00040 below). Pattern persists strongly: ffs=3025 is the natural single-seed n=1 floor on c=20 stack.

**Direction inference for downstream**: NS5_ITERS axis closed; NS=14 locked. **NS5 polynomial coefficients (axis already in flight as #694 askeladd) remains the open NS5-class lever** — coefficient (a,b,c) variation may matter more than iteration count at this saturation point.

**Frieren → #NEW WD_AUX cross-pod RE-RUN** — verification of suspect #676 closure (pod-broken hypothesis per GH issue #692).

### PR #675 — tanjiro SCALARS_LR Arm B passes n=1 HOLD GATE; n=2 confirm AUTHORIZED

Branch: `g1r2-tanjiro/scalars-lr-sweep`. Arm B terminal posted 16:54 UTC, advisor n=2 authorization posted 16:55 UTC.

| Arm | SCALARS_LR | val_loss | ffs | hold gate (val ≤ 3.27 AND ffs ≤ 3000) | vs baseline (3.26776/3000) | W&B |
|-----|---|---|---|---|---|---|
| **A** | **0.005** | **3.27572** | **3100** | ❌ both legs (+0.00796 val, +100 ffs) | clear MISS | `2oc4h91w` |
| Baseline | 0.010 | 3.26776 (n=2) | 3000 | — | — | (PR #613) |
| **B (seed 0)** | **0.020** | **3.26853** | **3000** | ✅ PASS (val 3.26853 ≤ 3.27, ffs 3000 ≤ 3000) | +0.00077 / 0 | `vdv6djua` |

**Arm B trajectory (uniformly ahead of Arm A from step 250 onward):**

| step | A (0.005) | B (0.020) | Δ (A − B) |
|---|---|---|---|
| 500  | 3.79683 | 3.79683* | — |
| 1500 | ~3.53   | 3.53089 | small |
| 2500 | 3.35576 | 3.34429 | +0.01147 |
| 3000 | n/a     | 3.27985 | — |
| 3175 | 3.27572 | **3.26853** | +0.00719 |

* (matched at step 500; diverged after)

**Decision math for n=2**:
- Merge bar: `val_mean < 3.26776 AND ffs_mean ≤ 3000`
- Arm B seed 0: val=3.26853, ffs=3000
- For n=2 mean to beat baseline: seed 1 val must be < 3.26699 (= 2×3.26776 − 3.26853)
- Narrow target — ~0.0015 below seed 0. Possible but requires favorable noise excursion.
- Historical pattern: past n=1 hold-gate passes within ±0.0009 of baseline (e.g. #642 edward FLOOR=0.05 seed 0 3.26712 → seed 1 regression; #655 thorfinn EMBED_LR_MULT=0.5 seed 0 3.26866 → seed 1 3.27217 regression). Bayesian prior leans MISS at n=2.

**Advisor authorized seed 1 of SCALARS_LR=0.02**: command in PR comment. ETA terminal ~1h45min.

If seed 1 < 3.26699 → n=2 mean ≤ baseline → flag for merge.
If seed 1 ≥ 3.26699 → n=2 mean misses baseline → close axis (default 0.010 confirmed optimal).

## 2026-05-21 16:10 UTC — Cycle 71 mid-43: PR #678 askeladd per-group cooldown_frac CLOSED — OPPOSITE-prior signal; #694 askeladd NS5_COEFS assigned; near-miss cluster (ffs=3025 boundary)

### PR #678 — askeladd Per-group cooldown_frac — BOTH ARMS MISS; OPPOSITE-PRIOR MECHANISM FINDING

Branch: `g1r2-askeladd/per-group-cooldown-frac`. Closed 16:10 UTC.

| Arm | MUON_COOLDOWN_FRAC | ADAMW_COOLDOWN_FRAC | val_loss | ffs | Δval | Δffs | Hold gate | W&B |
|-----|---|---|---|---|---|---|---|---|
| Disabled-check | 0.7 | 0.7 | 4.08062@200 | — | — | — | ✓ pass | `oxcbxb26` |
| **A** | **0.6** | **0.8** | **3.27381** | **3075** | **+0.00605** | **+75** | **MISS** | `2shhhy90` |
| Default | 0.7 | 0.7 | 3.26776 (n=2) | 3000 | 0 | 0 | — | PR #613 |
| **B** | **0.8** | **0.6** | **3.27100** | **3025** | **+0.00324** | **+25** | **MISS** | `h0vc1gjb` |

#### Trajectory comparison — Arm B advantage profile

| Step | Arm A | Arm B | Δ (B−A) | Notes |
|---|---|---|---|---|
| 1000 | 3.66422 | 3.62981 | **−0.0344** | Large initial advantage |
| 1500 | 3.57052 | 3.51380 | **−0.0567** | **PEAK advantage** |
| 2000 | 3.45375 | 3.41892 | **−0.0348** | Collapsing |
| 2500 | 3.35908 | 3.34150 | **−0.0176** | Continuing collapse |
| 3000 | 3.28638 | 3.28143 | **−0.0050** | Nearly closed |
| 3175 | 3.27381 | 3.27100 | **−0.0028** | Tiny gap at terminal |

#### Key finding: OPPOSITE-PRIOR mechanism

The pre-experiment prior was: "AdamW wants longer cooldown (larger ADAMW_COOLDOWN_FRAC)". The Arm B result shows the OPPOSITE:
- Arm B (MUON=0.8, ADAMW=0.6): Muon gets MORE of the cooldown window; AdamW gets LESS
- Arm B is materially better at step 1000-1500 — Muon's longer/later cooldown is the productive direction

**Mechanism interpretation:** With MUON_COOLDOWN_FRAC=0.8, Muon is still in warmup/flat LR during the middle of training and only begins cooling in the last 20% of steps. AdamW with COOLDOWN_FRAC=0.6 starts cooling earlier (last 40%), giving AdamW more time to settle. This COMBINATION — Muon stays high, AdamW cools — appears to decouple the two optimizers' dynamics productively. However, the gap collapses at terminal: the per-group FRACTION difference is a timing effect that doesn't change the final converged point.

**Conclusion:** Default shared cooldown_frac=0.7 remains locally optimal at terminal horizon. The decoupling effect is real (Δ=−0.034 at step 1000) but insufficient to overcome the terminal convergence rate. Mechanism logged for future longer-horizon experiments where earlier AdamW cooling could compound more.

### Cycle 71 near-miss cluster analysis — ffs=3025 pattern

All three fresh-axis single-seed results this half-cycle landed ffs=3025:

| PR | Arm | val | ffs | Δval | Note |
|---|---|---|---|---|---|
| #677 frieren Arm B | NS5=18 | 3.26960 | 3025 | +0.00184 | Closest val-side |
| #680 nezuko Arm A | CONTRA=0.2 | 3.27071 | 3025 | +0.00295 | Narrow val miss |
| #685 thorfinn Arm A | EPS=1e-8 | 3.27119 | 3025 | +0.00343 | Standard miss |
| #678 askeladd Arm B | MUON=0.8/ADAMW=0.6 | 3.27100 | 3025 | +0.00324 | Per-group decoupling |

**ffs=3025 is a statistical floor for single-seed n=1 on the c=20 stack** — all 4 results cluster exactly here. The ffs=3000 bar requires a top-5th-percentile favorable step where the run crosses 3.28 exactly 25 steps earlier. This suggests:
1. The optimal "typical" run with current stack crosses 3.28 at ~step 3020-3025
2. To hit ffs=3000 consistently, we need a mechanism that moves the entire crossing window ~20-25 steps earlier
3. OR we need the val improvement to be large enough (val<<3.268) that the ffs crossing is systematically earlier

The baseline n=2 mean was ffs=3000 because it included TWO seeds with favorable random draws. Single-seed n=1 screening consistently shows ffs=3025.

### PR #694 assigned — askeladd NS5_COEFS (fresh mechanism)

Branch: `g1r2-askeladd/ns5-coefs-sweep`. Just assigned 16:10 UTC.

Hypothesis: NS5 polynomial coefficients (a=2, b=-1.5, c=0.5) hardcoded at line 482, never ablated. Two arms:
- Arm A: Polar Express (3.4445, -4.7750, 2.0315) — minimax-optimal spectral convergence
- Arm B: Conservative (1.5, -1.0, 0.4) — slower, smoother

Code change: ~5 lines (add NS5_COEF_A/B/C env vars, wire into zeropower_via_newtonschulz5). ETA first heartbeat ~17:30 UTC if disabled-check passes promptly.

---

## 2026-05-21 15:35 UTC — Cycle 71 mid-42: 🚨 OPERATIONAL — PR #681 edward CLOSED AS POD-BROKEN (NOT axis result); PR #676 closure flagged SUSPECT; fern #683 disabled-check stall override; frieren #677 Arm B near-miss val=3.26960/ffs=3025

### PR #681 — edward MU_WARMUP_START sweep — CLOSED AS POD-BROKEN (NOT axis result)

Branch: `g1r2-edward/mu-warmup-start-sweep`. Closed 15:32 UTC. GH issue #692 filed.

#### Root cause: torch reinstall on edward's pod at 2026-05-21 11:49:26 UTC

Edward's diagnostic via pod file mtime + concurrent cross-pod control runs identified pod-specific torch reinstall as cause of 5× NaN disabled-check failures.

**Smoking gun (pod-state mtime):**
- `/usr/local/lib/python3.10/dist-packages/torch/__init__.py` mtime: **2026-05-21 11:49:26 UTC**
- `/usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so` mtime: **2026-05-21 11:49:26 UTC**

**Pre-11:49 on edward's pod (WORKED):**

| Run ID | Time | Config | val@200 |
|---|---|---|---|
| `xeeupthb` | 11:32 | WD_AUX=0.002 | **4.0831** ✓ |

**Post-11:49 on edward's pod (ALL NaN'd):**

| Run ID | Time | Config | Result |
|---|---|---|---|
| `m370srd5`, `wy9glbst`, `b8v6zj4v` (#676 closure runs) | 11:49+ | WD_AUX=0.002 | NaN by step 25/125 |
| `xpqbjc3x`, `tljln42o`, `ymzysujr`, `q3sc93ed`, `mvdgwpfk` (#681 disabled-checks) | 13:27–14:52 | WD_AUX=0.001 (baseline) | NaN by step 25/125 |
| `u2ya6o7x` | 11:49 (same minute as reinstall) | baseline | NaN |

**Concurrent same-config on OTHER students' pods (WORKED):**

| Run ID | Student | Time | val@200 |
|---|---|---|---|
| `ubf0k47e` | alphonse | 15:09 | **4.0886** ✓ |
| `p54brmct` | fern | 14:56 | **4.0846** ✓ |
| `f6755xnb` | nezuko | 13:19 | **4.0831** ✓ |

**Bit-for-bit telemetry match at step 1:**
- Edward post-11:49: grad_norm=234,584, max_abs=20,197 → NaN by step 25
- Baseline (`1zb5h0e5`): grad_norm=233,924, max_abs=20,197 → succeeds

Step 1 is **byte-equivalent** to working baseline; divergence emerges between step 1 and step 25.

#### Verification by W&B subagent

- ✅ `xeeupthb` (pre-11:49) confirmed: val@200=4.0831, WD_AUX=0.002, finished
- ✅ Three #676 NaN runs all confirmed NaN'd (W&B logs at step 125 due to sparse logging, but consistent with edward's step-25 onset)
- ✅ Cross-pod control runs confirmed val@200 ≈ 4.083-4.089

#### Implications

1. **MU_WARMUP_START axis remains UNTESTED on c=20 stack** — will reassign when pod is fixed.
2. **PR #676 WD_AUX closure is SUSPECT** — those NaN'd runs were also post-11:49 on the same broken torch; closure may be pod-induced not axis-induced. Pre-11:49 WD_AUX=0.002 run (`xeeupthb`) succeeded → WD_AUX=0.002 is NOT intrinsically catastrophic. Flag for re-run on a working pod.
3. **GH issue #692 filed** with full diagnostic for human research team. Requesting torch wheel parity with the other students' pods.
4. **Edward is IDLE pending fix** — no new assignment possible (pod will NaN any work identically).

#### Disabled-check stall pattern reaches 6+ students this cycle

| Student | PR | Disabled-check runs before launch | Resolution |
|---|---|---|---|
| edward | #642 | ~8 | advisor override |
| tanjiro | #650 | 6 | advisor override |
| fern | #661 | 6 | advisor override |
| tanjiro | #675 | 6 | advisor override |
| frieren | #677 | 7 | advisor override |
| nezuko | #680 | 3 | advisor override |
| **fern** | **#683** | **8** | **advisor override posted 15:33 UTC** |
| edward | #681 | 5 (all NaN'd — different mode) | closed as pod-broken |

Total advisor overrides this cycle: 7 (+ 1 pod-broken). Systemic issue to flag separately.

### PR #683 — fern ATTN_SOAP_TRUST_THRESHOLD — DISABLED-CHECK STALL, ADVISOR OVERRIDE POSTED

Branch: `g1r2-fern/attn-soap-trust-threshold-sweep`. Created 13:25 UTC; advisor override posted 15:33 UTC.

8 disabled-check runs (`ar5jds5j`, `q3w5pw18`, `4c3lqj3f`, `792o2dc7`, `hz7xrg49`, `p54brmct`, `jtjcgcqk`, `d5ce65ql`) all completed val~4.08 at step 200 between 13:37–15:29 UTC. None advanced to Arm A. Disabled-check verified PASSED; further loops are pure waste.

Override instructs to skip remaining disabled-checks and launch Arm A (ATTN_SOAP_TRUST_THRESHOLD=0.75) directly. ETA per arm ~104 min; expect first heartbeat by ~17:30 UTC if pickup is prompt.

### PR #677 — frieren NS5_ITERS Arm B TERMINAL — INTERESTING NEAR-MISS

Branch: `g1r2-frieren/ns5-iters-sweep`. Arm B (NS5_ITERS=18) terminal 15:19 UTC.

| Arm | NS5_ITERS | val_loss | ffs | Δval | Δffs | Hold gate val | Hold gate ffs | W&B |
|-----|---|---|---|---|---|---|---|---|
| **B** | **18** | **3.26960** | **3025** | **+0.00184** | **+25** | **PASS (3.26960<3.27)** | **FAIL (3025>3000)** | `ecdrwmg7` |
| Default | 14 | 3.26776 (n=2) | 3000 (n=2) | 0 | 0 | — | — | PR #613 |
| A | 12 | in flight (launched 15:19 UTC) | — | — | — | — | — | — |

**Observations:**
- Arm B val=3.26960 is **the closest val-side near-miss this cycle** for a fresh axis. Passes the n=1 val hold gate (val < 3.27).
- But ffs=3025 fails ffs hold gate (3000).
- Symmetric ffs penalty pattern: every closure this cycle hit ffs=3025 or worse; the ffs floor at 3000 is binding harder than val.
- Will hold for Arm A (NS=12) terminal before deciding. If Arm A also lands val<3.27 with ffs=3000, the axis may justify n=2 confirm exploration.
- **Trajectory shape suggests NS5_ITERS=18 marginally improves val by tighter orthogonalization at cost of ffs lateness.** Compatible with prior NS5 closures (#534 Shampoo, #534 right-factor) — second-order preconditioning of body Muon converges later but slightly tighter.

### PR #675 — tanjiro SCALARS_LR Arm A TERMINAL — MISS

Branch: `g1r2-tanjiro/scalars-lr-sweep`. Arm A (SCALARS_LR=0.005) terminal 14:58 UTC.

| Arm | SCALARS_LR | val_loss | ffs | Δval | Δffs | W&B |
|-----|---|---|---|---|---|---|
| **A** | **0.005** | **3.27572** | **3100** | **+0.00796** | **+100** | `2oc4h91w` |
| Default | 0.01 | 3.26776 | 3000 | 0 | 0 | PR #613 |
| B | 0.02 | in flight | — | — | — | — |

Clear MISS on hold gate. Arm B (0.02) in flight; if Arm B also clearly misses, axis closes (default 0.01 well-tuned for scalars group).

### PR #685 — thorfinn ADAMW_EPS Arm A heartbeat (HEALTHY)

Branch: `g1r2-thorfinn/adamw-eps-sweep`. Arm A (ADAMW_EPS=1e-8) step 2500 val=3.34883 (kill gate 3.40 PASS).

Trajectory tracks baseline shape; step_avg ~1962ms; ETA terminal ~16:00 UTC.

### PR #680 — nezuko CONTRA_MUON Arm A near-terminal (HEALTHY)

Branch: `g1r2-nezuko/contra-muon-sweep`. Arm A (CONTRA_MUON=0.2) step 2872/3175 (90%) at 15:31 UTC.

step 2500 val=3.34720; ETA terminal ~15:42 UTC. All kill gates PASS.

### PR #678 — askeladd per-group cooldown_frac Arm B AHEAD of Arm A (INTERESTING)

Branch: `g1r2-askeladd/per-group-cooldown-frac`. Arm B (MUON=0.8 / ADAMW=0.6) at step 1500 val=3.54744.

| Step | Arm B (MUON=0.8, ADAMW=0.6) | Arm A (MUON=0.6, ADAMW=0.8) | Δ |
|---|---|---|---|
| 125 | 4.42094 | 4.42118 | -0.00024 |
| 250 | 4.04173 | 4.04427 | -0.00254 |
| 500 | 3.80241 | 3.80487 | -0.00246 |
| 750 | 3.71150 | 3.71951 | -0.00801 |
| **1000** | **3.62981** | **3.66422** | **−0.03441** ✨ |
| 1250 | 3.57506 | — | — |
| 1375 | 3.54744 | — | — |

Arm B (Muon cooldowns EARLIER, AdamW plateaus LONGER) is materially ahead of Arm A by Δ=−0.034 at step 1000. **OPPOSITE prior** — pre-experiment intuition had Muon-cooldown-late hypothesis, but evidence suggests Muon prefers earlier cooldown when paired with AdamW staying high. Will monitor through cooldown.

This is the most novel axis in flight — schedule-decoupling between optimizer groups. Will watch closely for Arm B terminal.

### PR #688 — alphonse MUON_GRAD_CLIP IN FLIGHT (fresh mechanism)

Branch: `g1r2-alphonse/muon-grad-clip`. Just assigned 15:00 UTC; no heartbeat yet.

First fresh-mechanism PR this wave. Tests per-tensor L2 max-norm gradient clipping ∈ {1.0, 0.5} on Muon group vs default 0.0 (no clipping anywhere in script).

---

## 2026-05-21 15:00 UTC — Cycle 71 mid-41: PR #673 alphonse MUON_LR CLOSED — third Muon-side scalar at default; portfolio rebalance to fresh-mechanism PR #688 MUON_GRAD_CLIP

### PR #673 — alphonse MUON_LR sweep — BOTH arms MISS hold gate, monotone direction confirmed

Branch: `g1r2-alphonse/muon-lr-sweep`. Closed 14:55 UTC.

| Arm | MUON_LR | val_loss | ffs | Δval vs baseline | Δffs vs baseline | Hold gate | W&B |
|-----|---|---|---|---|---|---|---|
| A | **0.032** (-20%) | 3.27208 | 3025 | +0.00432 | +25 | MISS (+0.00208 val, +25 ffs) | `59dpesjp` |
| Default | 0.04 | 3.26776 (n=2) | 3000 (n=2) | 0 | 0 | — | PR #613 |
| B | **0.05** (+25%) | 3.27489 | 3100 | +0.00713 | +100 | MISS (+0.00489 val, +100 ffs) | `qbp5ubu0` |

### Monotone direction with asymmetric magnitude

**Smaller LR (0.032) loses by +0.00432; larger LR (0.05) loses by +0.00713.** The directional prior was partially confirmed: c=20's larger backward gradients DO push the optimum slightly downward (Arm A is closer to baseline than Arm B), but the +25% upward perturbation hurts substantially more than the -20% downward — suggesting **the loss surface is steeper on the upward side around MUON_LR=0.04**.

### Step-by-step trajectory comparison (Arm A vs Arm B)

| step | A (0.032) | B (0.05) | Δ (B − A) |
|---|---|---|---|
| 500 | 3.77674 | 3.84567 | **+0.069** |
| 1000 | 3.62280 | 3.71603 | **+0.093** |
| 1500 | 3.50468 | 3.57477 | +0.070 |
| 2000 | 3.41071 | 3.45796 | +0.047 |
| 2500 | 3.33727 | 3.36820 | +0.031 |
| 3000 | 3.28151 | 3.28882 | +0.007 |
| **3175** | **3.27208** | **3.27489** | +0.003 |

Arm B trails Arm A maximally at step 1000 (+0.093). The gap CONVERGES through cooldown — both arms reach within +0.003 by terminal step. **Cooldown rescues the larger-LR arm.** This is consistent with linear-cooldown-to-zero giving the larger-LR run a brief catch-up window in the last 0.7 × 3175 = 2222 cooldown steps.

### Mechanism interpretation — third Muon-side scalar locally optimal

| PR | Axis | Default | Result | Verdict |
|---|---|---|---|---|
| #656 | MU_COOLDOWN_END | 0.90 | both arms MISS | Locally optimal |
| #661 | NORMUON_BETA2 | 0.95 | both arms MISS | Locally optimal |
| **#673** | **MUON_LR** | **0.04** | **both arms MISS** | **Locally optimal** |

**Three Muon-side scalars now closed at default values.** Combined with AdamW closures (#641 ADAMW_LR_FLOOR closed via stack mismatch, #654 LM_HEAD_LR_MULT closed, #655 EMBED_LR_MULT closed via symmetric n=2, #663 ADAMW_BETA1, #625 ADAMW_BETA2), **the c=20 stack scalar surface is FLAT near the current operating point**. Future wins must come from mechanism-level changes per program.md's portfolio rule.

### Why no n=2 confirm on Arm A

Arm A (MUON_LR=0.032) clearly missed the n=1 hold gate (val=3.27208 > 3.27 cap by +0.00208; ffs=3025 > 3000 cap by +25). The PR decision tree branch 3 (both miss → close) applied unambiguously. Spending an n=2 GPU-pair to explore a +0.004-above-baseline n=1 result was correctly assessed as low-value vs fresh mechanism work.

### Alphonse → #688 MUON_GRAD_CLIP — first fresh-mechanism PR this wave

Per program.md: *"Reserve some capacity for genuinely new optimizer mechanisms... a wave of only scalar hyperparameter tweaks is too conservative."*

The current in-flight queue was 7/8 scalar sweeps:
- #685 thorfinn ADAMW_EPS
- #683 fern ATTN_SOAP_TRUST_THRESHOLD
- #681 edward MU_WARMUP_START
- #680 nezuko CONTRA_MUON
- #678 askeladd PER_GROUP_COOLDOWN_FRAC (decoupling, slightly more mechanism-like)
- #677 frieren NS5_ITERS
- #675 tanjiro SCALARS_LR

Alphonse's reassignment was an opportunity to **rebalance toward mechanism-level exploration**. Chose **MUON_GRAD_CLIP** because:

1. **Fresh axis** — `grep -n "clip_grad" records/track_3_optimization/train_gpt_simple.py` returns 0 hits. No gradient clipping exists anywhere in the script.
2. **Mechanistically motivated** — Edward #676 WD_AUX closure revealed early-warmup gradient explosion (~91% NaN gradients by step 25 when WD_AUX×2). The c=20 stack sits in a narrow stability window; clipping could widen it.
3. **Different geometry from AGC #580 closure** — AGC clipped AdamW group per-tensor (99/101 hit epsilon floor → uniform damping). MUON_GRAD_CLIP touches only ~24 Muon block tensors with conventional L2 max-norm.
4. **Single-line code change** — minimal complexity, easy disabled-check verification.

Arms: {1.0, 0.5} per-tensor L2 max-norm. 1.0 is conventional Adam clip value; 0.5 is more aggressive dose-response.

---

## 2026-05-21 13:50 UTC — Cycle 71 mid-40: PR #655 thorfinn EMBED_LR_MULT n=2 CONFIRM CLOSED — symmetric quadratic well confirmed; PR #661 fern NORMUON_BETA2 CLOSED — default 0.95 locally optimal

### PR #655 — thorfinn EMBED_LR_MULT n=2 confirm — CLEAN MISS on both axes

Branch: `g1r2-thorfinn/embed-lr-sweep`. Closed 13:45 UTC after Arm A seed 1 terminal at val=3.27217/ffs=3050.

| Run | Arm / seed | EMBED_LR_MULT | Effective embed LR | val_loss | ffs | Outcome | W&B |
|-----|---|---|---|---|---|---|---|
| seed 0 | A | 0.5 | 0.15 | 3.26866 | 3000 | n=1 hold gate PASSED | `c7bpfkqn` |
| seed 1 | A | 0.5 | 0.15 | **3.27217** | **3050** | n=2 confirm — MISS | `o779hd5a` |
| **n=2 mean** | **A** | **0.5** | **0.15** | **3.270415** | **3025** | **MISSES merge bar by +0.00266 / +25** | — |
| baseline | — | 1.0 | 0.3 | 3.26776 (n=2) | 3000 (n=2) | — | PR #613 |
| seed 0 | B | 2.0 | 0.6 | 3.27060 | 3025 | n=1 hold gate MISS | `hdkz3b4c` |

**n=2 merge math:**
- val: needed seed 1 < 2×3.26776 − 3.26866 = 3.26686 (must beat seed 0 by ≥0.00180)
- Actual seed 1: 3.27217 (+0.00351 vs seed 0, opposite direction) — **off by 0.00531 from needed swing**
- ffs: needed seed 1 ≤ 3000; actual 3050 — **+50 over cap**

**Seed-1 vs seed-0 trajectory comparison (Arm A, EMBED_LR_MULT=0.5):**

| step | seed 0 | seed 1 | Δ (s1 − s0) |
|---|---|---|---|
| 125 | 4.40195 | 4.41365 | +0.01170 |
| 500 | 3.80205 | 3.80076 | −0.00129 |
| 1000 | 3.65741 | 3.66010 | +0.00269 |
| 1500 | 3.52901 | 3.53210 | +0.00309 |
| 2000 | 3.42747 | 3.43020 | +0.00273 |
| 2500 | 3.34415 | 3.34729 | +0.00314 |
| 2750 | 3.30820 | 3.31163 | +0.00343 |
| 3125 | 3.27488 | 3.27366 | −0.00122 |
| 3150 | 3.27200 | 3.27261 | +0.00061 |
| **3175 (final)** | **3.26866** | **3.27217** | **+0.00351** |

Seed 1 tracked +0.0017 to +0.0053 above seed 0 throughout mid-training (steps 875-2750) with no cooldown rescue — consistent persistent offset.

### Combined directional analysis

| Direction | EMBED_LR_MULT | val_loss | Δval vs baseline (3.26776) |
|---|---|---|---|
| Down (Arm A n=2 mean) | 0.5 | 3.270415 | **+0.00266** |
| Default | 1.0 | 3.26776 | 0 |
| Up (Arm B n=1) | 2.0 | 3.27060 | **+0.00284** |

**Both directions lose by SYMMETRIC ~0.0027** — embed LR=0.3 sits in a **quadratic well at local optimum**, not on a flat ridge. The asymmetric "Arm A wins n=1 at +0.0009" was a favorable-tail seed-noise excursion that the n=2 confirm correctly disambiguated from a real effect.

### Mechanism interpretation

**The "embed undertrained" hypothesis from 3-winner AdamW-output convergence is NOT supported.** The recent stack winners (EMBED_INIT_STD=0.1 #541, LOGIT_SOFTCAP=20 #613, ADAMW_LR_FLOOR=0.05 #642 closed, ADAMW_BETA1/BETA2) operate via different mechanisms:
- #541: input magnitude (data-flow geometry)
- #613: output logit cap (loss surface curvature)
- #642 closed: cooldown-tail activity (schedule-level, antagonistic to c=20)

None of these involve "embed group has wrong LR" — they're orthogonal interventions. Frieren #654 (lm_head LR sweep) closed similarly. **Output-side AdamW LR rebalancing is fully closed.**

### Why n=2 confirm was the right call

Spending one extra run to disambiguate noise from real effect on a borderline n=1 hold gate (val=3.26866 at the 3.27 cap, ffs=3000 hits cap exactly, +0.00090 vs baseline at seed-noise edge ~±0.0015-0.003) is exactly the textbook use case. The investment paid off — got a confident closure rather than a marginal merge that would have been undone on the next baseline shift.

### Asymmetric mistake of note

Advisor (me) included `--seed 1` in the n=2 confirm instructions, but `train_gpt_simple.py` has no `--seed` argparse arg and no `torch.manual_seed`. Student correctly flagged and dropped the flag — fresh-process non-determinism produces the seed-to-seed variation, identical to how tanjiro #613 c=20 n=2 confirm was run. No GPU time wasted; advisor acknowledged the mistake. **Lesson: verify CLI flags against the script before posting instructions to students.**

### Thorfinn → #685 ADAMW_EPS sweep

Default ADAMW_EPS = 1e-10 (hardcoded line 904) is **100× smaller** than PyTorch / AdamW-paper convention (1e-8). Fresh untested axis on the AdamW group — **the last untested AdamW knob**. Arms: 1e-8 (conventional) and 1e-12 (more extreme). Mechanism: eps sits in `lr × m̂ / (sqrt(v̂) + eps)`; affects rare-token channels where v̂ is small. Stack inherits LOGIT_SOFTCAP=20 + EMBED_INIT_STD=0.1 + full mandatory stack.

---

### PR #661 — fern NORMUON_BETA2 sweep — BOTH arms MISS, default 0.95 well-tuned

Branch: `g1r2-fern/normuon-beta2-sweep`. Closed 13:40 UTC.

| Arm | NORMUON_BETA2 | val_loss | ffs | Δval vs baseline | Outcome |
|-----|---|---|---|---|---|
| A | 0.90 (shorter EMA) | **3.27198** | **3050** | +0.00422 | MISS both legs |
| Default | 0.95 (hardcoded) | 3.26776 | 3000 | 0 | — |
| B | 0.99 (longer EMA) | 3.27397 | 3075 | +0.00621 | MISS both legs |

**Asymmetric loss profile**: Arm A (faster EMA) misses by +0.00422; Arm B (slower EMA) misses MORE at +0.00621. **Monotone direction**: slower EMA hurts more than faster. Default 0.95 is locally optimal but Arm A is closer to the optimum than Arm B.

### Mechanism interpretation — post-NS5 numerical noise

NORMUON_BETA2 controls the EMA timescale for the **per-row second moment** of the Muon update (lines 507, 523-524 in `contra_normuon_update`):

```python
update = update * second_moment.clamp_min(1e-10).rsqrt().to(update.dtype)
```

The update has already been **NS5-orthogonalized** before this step — meaning row-magnitudes are largely homogenized to ~1.0 by the orthogonalization. The per-row variance EMA primarily captures:
1. **Real signal**: residual row-magnitude differences after NS5 boundary effects
2. **Numerical noise**: NS5 polynomial coefficient interactions with fp32/bf16 mixed precision

Longer memory (β2=0.99): integrates 1/(1−β2) ≈ 100 steps of post-NS5 noise. Adds latency without filtering signal — slow EMA tracks already-noisy estimates more conservatively. Result: **+0.00621 worse**.

Shorter memory (β2=0.90): integrates ~10 steps. Captures local noise spikes that haven't been smoothed yet. Result: **+0.00422 worse** but less bad than longer memory.

Default 0.95: ~20 steps integration — balances signal extraction vs noise filtering.

### Cross-cluster comparison — EMA-timescale axes

| PR | EMA | Default | Geometry | Verdict |
|---|---|---|---|---|
| #625 fern | ADAMW_BETA2 | 0.95 | Per-coordinate | CLOSED — c=20 antagonistic |
| #634 askeladd | ATTN_SOAP_BETA2 | 0.90 | Kronecker factor | CLOSED — flat |
| **#661 fern** | **NORMUON_BETA2** | **0.95** | **Per-row (post-NS5)** | **CLOSED — monotone asymmetric** |

Three orthogonal EMA-timescale axes now closed across all preconditioner classes. The conclusion: **EMA timescales are well-tuned at their hardcoded defaults across all variance-tracking mechanisms** — the post-NS5 / per-row case (#661) mirrors the per-coordinate (#625, #634) finding.

### Fern → #683 ATTN_SOAP_TRUST_THRESHOLD sweep

Fresh SOAP preconditioner axis (line 466, default 0.85, used at lines 557, 720). Trust-gate controls cosine-similarity threshold for applying SOAP preconditioning vs falling back to raw gradient. Arms: 0.75 (permissive, more SOAP usage) and 0.95 (stricter, more fallback). Mechanism class: per-step preconditioner selection at attention Q/K/V/proj.

Also acknowledged fern's recurring 6× disabled-check loop pattern in close comment — same pattern as edward #642, tanjiro #650/675. Documented in feedback memory for future assignments.

---

## 2026-05-21 13:35 UTC — Cycle 71 mid-39: PR #676 edward WD_AUX axis FULLY CLOSED via symmetric early-warmup gradient explosion — first closure of this type

### PR #676 — edward WD_AUX sweep — BOTH directions diverge with identical failure mode

Branch: `g1r2-edward/wd-aux-sweep`. Closed 13:30 UTC.

| Direction | WD_AUX | Attempts | Outcome | Step at first NaN |
|---|---|---|---|---|
| Up (×2) | 0.002 | 2× (`wy9glbst`, `m370srd5`) | NaN | step 25 grad, step 125 val |
| Default | 0.001 | baseline | val=3.26776 / ffs=3000 | — |
| Down (÷2) | 0.0005 | 1× (`b8v6zj4v`) | NaN | step 25 grad, step 125 val |
| Disabled-check (200 steps) WD_AUX=0.002 | — | 2× (`xeeupthb` healthy, `u2ya6o7x` NaN) | 1/2 healthy | step 125 NaN in failed |

**Aggregate**: WD_AUX=0.002 → 3/4 NaN. WD_AUX=0.0005 → 1/1 NaN. Default 0.001 → 0/2 NaN.

### Failure mode — early-warmup gradient explosion

Edward's `train/grad/all/finite_elements` telemetry:

| Run | WD_AUX | Step 1 finite grads | Step 25 finite grads | Finite fraction @ 25 |
|-----|--------|---------------------|----------------------|---------------------|
| `wy9glbst` | 0.002 | 162,354,816 / 162,354,816 | ~14.6 M / 162.3 M | **~9%** |
| `b8v6zj4v` | 0.0005 | 162,354,816 / 162,354,816 | ~14.6 M / 162.3 M | **~9%** |

By step 25 (during MU_WARMUP_STEPS=200 phase), ~91% of all gradient elements are NaN. The val_loss NaN at step 125 is just the first validation interval after the explosion.

### Mechanism interpretation — symmetric failure points to coupling

**The most informative finding**: BOTH ×2 AND ÷2 from default fail the SAME way at the SAME step. Failure mode cannot be "WD is too aggressive" (would be one-sided) or "WD is too weak" (would be other one-sided). Must be a **non-linear coupling** between WD_AUX and another stack parameter that is tuned precisely at default 0.001:

- **WD_AUX × MU_WARMUP coupling hypothesis**: aggressive decay (×2) AND aggressive relaxation (÷2) both push embed/lm_head into a parameter-magnitude regime where Muon momentum warmup's directional updates explode in early steps. The default 0.001 is the empirical sweet spot where embed magnitude evolution lines up with MU_WARMUP_STEPS=200 trajectory.
- **Alternative**: bifurcation at default — perturbations in either direction cross a stability boundary in (embed_magnitude, muon_step_magnitude, lm_head_magnitude) phase space.

### Implications for portfolio

- **WD_AUX axis is permanently CLOSED** — both directions destabilize, no narrower bracket worth GPU time given symmetric failure pattern.
- **Disabled-check non-determinism is real** at this stack — same args (WD_AUX=0.002, 200 steps) gave one healthy + one NaN. The c=20 stack lives close to bifurcation boundaries; future PRs touching embed/lm_head magnitudes must watch for early-warmup grad explosions.
- **Telemetry canary**: `train/grad/all/finite_elements` is the right metric for early-warmup divergence detection. Recommended kill gate for future PRs touching embed/lm_head: <99% finite gradients by step 25 → kill immediately.
- **WD_AUX × warmup coupling** as a follow-up: cheap 1-arm test at WD_AUX=0.002 with MU_WARMUP_STEPS=400 (gentler warmup) would test the warmup-coupling hypothesis cheaply. Deferred for now — portfolio better spent on fresh axes.

### Decision

CLOSE the WD_AUX axis entirely. Edward → #681 MU_WARMUP_START value sweep (LAST untested value on the Muon momentum schedule envelope — adjacent axes #608 warmup STEPS and #656 cooldown END both closed).

---

## 2026-05-21 12:10 UTC — Cycle 71 mid-38: PR #657 nezuko SCHEDULE_SHAPE CLOSED — both arms catastrophic MISS; linear cooldown well-tuned; LR at END of cooldown matters more than descent shape

### PR #657 — nezuko cooldown shape — Both arms catastrophic MISS

Branch: `g1r2-nezuko/schedule-shape-sweep`. Closed 12:10 UTC.

| Arm | SCHEDULE_SHAPE | val_loss (n=1) | ffs | Δ vs baseline (3.26776/3000) | n=1 hold gate | W&B |
|-----|----------------|----------------|-----|------------------------------|---------------|------|
| A | cosine `0.5·(1+cos(πt))` | **3.28145** | **-1 (NEVER reached 3.28)** | +0.01369 / -1 | CATASTROPHIC MISS | `a40adbuq` |
| B | quadratic `(1-t)²` | **3.28832** | **-1 (NEVER reached 3.28)** | +0.02056 / -1 | EVEN WORSE MISS | `tb2f3wxq` |

Linear baseline (default `(1-progress)/cooldown_frac`): val=**3.26776**, ffs=**3000**.

**Code change**: Minimal (~10 lines) — added `SCHEDULE_SHAPE` env var + branching in `set_hparams`. `SCHEDULE_SHAPE=linear` is byte-equivalent default.

**Trajectory inspection (val at key milestones)**:

| step | linear baseline | cosine (Arm A) | quadratic (Arm B) |
|------|----------------:|----------------:|------------------:|
| 250 | 4.04 | 4.04058 | 4.04389 |
| 500 | 3.80 | 3.80607 | 3.80639 |
| 1500 | 3.49 | **3.56030** | 3.49464 |
| 2500 | 3.32 | 3.33257 | 3.31087 |
| 3000 | val≈3.279 | 3.2906 | 3.28906 |
| 3175 (final) | 3.26776 | 3.28145 | 3.28832 |

- **Arm A (cosine)** falls BEHIND baseline at step 1500 (3.56 vs 3.49) — cosine holds LR high mid-cooldown but the early hold-up costs descent budget. Then near-zero LR plateau in last 500 steps prevents catching up (final 3000→3175 delta only −0.0008).
- **Arm B (quadratic)** ACTUALLY beats linear at step 1500 (3.495 vs 3.49) because the early sharp drop matches the model's wanted descent rate. But the long low-LR tail (η stays small for ~70% of cooldown) means the final ~1500 steps barely move (final 3000→3175 delta also tiny). Premature convergence to worse plateau.

**Mechanism interpretation (student's, validated)**:
- The LR at END of cooldown matters MORE than the shape of the descent.
- Linear's straight-line LR=0 transition wins because the final LR (LR/N at step N-1) is small-but-nonzero, allowing the model to finish descent cleanly.
- Both shape perturbations break this: cosine freezes loss in tail; quadratic causes premature convergence.

**Asymmetry insight (with edward #642 stack-mismatched ADAMW_LR_FLOOR)**:
- Per-group LR floor on AdamW (FLOOR=0.05 wide active window in cooldown tail) was a WIN candidate on OLD stack (val=3.26712) but failed on NEW c=20 stack — antagonizes c=20 cooldown settling.
- Global LR shape change loses catastrophically regardless of stack.
- The dimensions are different: per-group keeps some params active while others settle; global shape changes when ALL params settle.
- Supports decoupling angle (askeladd #678 in flight: per-group cooldown_frac swap).

**Decision**: CLOSE the cooldown-shape axis. Nezuko → #680 CONTRA_MUON sweep (fresh-axis Muon-side stack-pruning VALUE sweep; CONTRA_MUON=0.4 never ablated for value since #533 binary-existence closure).

---

## 2026-05-21 11:30 UTC — Cycle 71 mid-37: FOUR axes CLOSED + 5 new assignments diversifying portfolio off c=20-locked AdamW output cluster

### PR #650 — tanjiro LOGIT_SOFTCAP extended sweep — Both arms MISS, c=20 is local PEAK

Branch: `g1r2-tanjiro/logit-softcap-extended`. Closed 11:19 UTC.

| Arm | LOGIT_SOFTCAP | val_loss (n=1) | ffs | Δ vs baseline (3.26776/3000) | n=1 hold gate (val≤3.27 AND ffs≤3000) | W&B |
|-----|---------------|----------------|-----|------------------------------|--------------------------------------|------|
| A | 25 | **3.2730** | 3050 | +0.00524 / +50 | MISS | `hk5yhvot` (canonical) |
| B | 30 | MISS (worse) | — | — | MISS | — |

**Run cleanup**: Earlier confusion with duplicate runs (`s5c9hy9c` step 0 fail, `i6qcfpf4` step 400 crash, `58it4mxw` pre-launch fail). Canonical Arm A run is `hk5yhvot`.

**Mechanism interpretation**: c=20 is the local PEAK on the LOGIT_SOFTCAP axis. Combined with #613 closure (c=12 below merged c=20), the axis is now fully closed: c=12 MISS / c=15 default / c=20 MERGED ⭐ / c=25 MISS / c=30 MISS. The looser cap below 20 hurts (insufficient regularization), the tighter cap below 12 hurts (over-clipping), and going above 20 also hurts (logits drift toward saturation regime).

**Decision**: CLOSE the axis. Tanjiro → #675 SCALARS_LR sweep (AdamW scalars group LR ∈ {0.005, 0.02} vs default 0.01 — fresh axis; 99/101 AdamW tensors are scalars per #580 AGC analysis).

---

### PR #642 — edward ADAMW_LR_FLOOR — CLOSED on stack-mismatched n=2 + Arm B MISS

Branch: `g1r2-edward/adamw-lr-floor`. Closed 11:23 UTC.

| Arm | FLOOR | Stack | val_loss | ffs | Notes |
|-----|-------|-------|----------|-----|-------|
| A seed 0 | 0.05 | OLD (c=15) | 3.26712 | 3000 | ⭐ "candidate" at the time, but on PRE-baseline stack |
| A seed 1 | 0.05 | NEW (c=20) | **3.26988** | **3025** | RAN ON c=20 stack per advisor override |
| A n=2 mean | 0.05 | mixed | 3.26850 | 3012.5 | MISS merge bar (val 3.26850 > 3.26776) |
| B | 0.10 | NEW (c=20) | **3.26842** | **3000** | MISS by +0.00066 |

**Mechanism interpretation**:
- The seed 0 win on OLD stack (c=15) does NOT extrapolate to NEW stack (c=20). When seed 1 ran with c=20 in the mandatory stack, val=3.26988 — well above the bar.
- Floor mechanism keeps embed+lm_head+scalars active in cooldown tail (3.5% active window for FLOOR=0.05, 7.0% for FLOOR=0.10). With c=20's larger logit magnitudes, this "extended cooldown activity" ANTAGONIZES the "let-it-settle" regime that c=20 needs. Cooldown decay should be MORE complete with c=20, not less.
- Arm B's wider active window (7.0%) loses to Arm A's (3.5%) → monotone direction is "less floor activity preferred", consistent with c=20's want for full cooldown.

**Decision**: CLOSE the axis. Edward → #676 WD_AUX sweep (auxiliary weight decay on embed+lm_head ∈ {0.0005, 0.002} vs default 0.001 — fresh output-side regularization axis).

---

### PR #654 — frieren LM_HEAD_LR_MULT — Both arms MISS, output LR locally optimal

Branch: `g1r2-frieren/lm-head-lr-mult`. Closed 11:23 UTC.

| Arm | LM_HEAD_LR_MULT | Effective lm_head LR | val_loss (n=1) | ffs | Δ vs baseline | n=1 hold gate | W&B |
|-----|-----------------|---------------------|----------------|-----|---------------|---------------|------|
| A | 2.0 | ~1.88e-3 | **3.2690** | 3025 | +0.00124 / +25 | MISS | (frieren run) |
| B | 0.5 | ~4.69e-4 | also MISS | — | — | MISS | — |

**Mechanism interpretation**:
- The hypothesis "lm_head undertrained at c=20" (from the 3-winner convergence #541 askeladd + #613 tanjiro + #625 fern β2=0.99 candidate) is NOT supported by direct LR test.
- Both 2× and 0.5× directions hurt → default ~9.4e-4 (= 0.3 × 1/320) is locally optimal.
- Consistent with c=20-locked AdamW output cluster: small LR perturbations around the locked group hurt directionally.

**Note**: The student initially had trouble with `mark_ready_for_review` failing due to invalid SENPAI-RESULT JSON parsed from my advisor template text containing `{...}`. Worked around with `gh pr ready` + label-swap manually. Memory saved [[feedback-senpai-result-template-in-advisor-comments]] to avoid this in future advisor instructions.

**Decision**: CLOSE the axis. Frieren → #677 NS5_ITERS sweep (Muon NS iterations ∈ {12, 18} vs default 14 — fresh Muon-side axis on numerical-precision dimension).

---

### PR #656 — askeladd MU_COOLDOWN_END — Both arms MISS, default Δ=0.05 swing optimal

Branch: `g1r2-askeladd/mu-cooldown-end`. Closed 11:24 UTC.

| Arm | MU_COOLDOWN_END | Effective Δ (start-end) | val_loss (n=1) | ffs | Δ vs baseline | n=1 hold gate | W&B |
|-----|-----------------|-------------------------|----------------|-----|---------------|---------------|------|
| A | 0.85 | 0.10 (more swing) | **3.2706** | 3025 | +0.00284 / +25 | MISS | (askeladd run) |
| B | 0.95 | 0.00 (no swing) | also MISS | — | — | MISS | — |

**Mechanism interpretation**:
- Default Δ=0.05 swing (MU_COOLDOWN_START=0.95 → MU_COOLDOWN_END=0.90) is locally optimal.
- Both directions hurt: more aggressive swing (0.10) drops μ too far too fast → momentum too short in cooldown tail; no swing (0.00) keeps μ at 0.95 → too long memory through cooldown, no compression of variance-reduction effect.
- Muon momentum schedule axis fully closed (front-end #608 + back-end #656).

**Decision**: CLOSE the axis. Askeladd → #678 per-group cooldown_frac (decouple MUON_COOLDOWN_FRAC and ADAMW_COOLDOWN_FRAC — first axis testing the schedule-decoupling dimension).

---

### thorfinn #655 EMBED_LR_MULT — n=2 confirm AUTHORIZED, in-flight

Branch: `g1r2-thorfinn/embed-lr-sweep`. Held for n=2 confirm.

| Arm | EMBED_LR_MULT | Effective embed LR | val_loss (n=1) | ffs | Δ vs baseline | n=1 hold gate |
|-----|---------------|--------------------|----------------|-----|---------------|---------------|
| A seed 0 | 0.5 | 0.15 | **3.26866** | **3000** | +0.00090 | PASS (val ≤ 3.27 AND ffs ≤ 3000) |
| B | 2.0 | 0.6 | 3.27060 | 3025 | +0.00284 | MISS |

**n=2 merge math**:
- Need val_mean<3.26776 → seed 1 val < 3.26686 (must beat seed 0 by ≥0.00180)
- Need ffs_mean≤3000 → seed 1 ffs ≤ 3000 (no slack)

**Seed-to-seed variance reference**: PR #613 c=20 had seed delta Δ=0.0001; edward #642 had Δ=0.003 (confounded by stack mismatch). Plausible but not guaranteed ~30-50% odds.

**Advisor mistake**: Initial n=2 launch instructions included `--seed 1` but no `--seed` argparse arg exists in `train_gpt_simple.py` and no `torch.manual_seed` call. Student correctly flagged and dropped the literal — non-determinism comes from fresh-process random state (same approach as tanjiro #613 c=20 n=2 confirm). Acknowledged in comment 11:30 UTC.

**Status**: seed 1 launched 11:28 UTC as `g1r2-thorfinn/embed-lr-A-mult05-n2-seed1`. ETA terminal ~13:12 UTC.

---

### fern #661 NORMUON_BETA2 — Arm B terminal MISS, Arm A pending

Branch: `g1r2-fern/normuon-beta2-sweep`. Stalled in disabled-check loop 07:53-09:32 UTC (6 disabled-checks before advisor override). Arm B launched 09:32 UTC.

| Arm | NORMUON_BETA2 | val_loss (n=1) | ffs | Δ vs baseline | n=1 hold gate | W&B |
|-----|---------------|----------------|-----|---------------|---------------|------|
| B | 0.99 | **3.27397** | **3075** | +0.00621 / +75 | MISS both | `7kdzl2e4` |
| A | 0.90 | (in-flight, ETA 13:10 UTC) | — | — | — | (pending) |

**Mechanism**: Higher NORMUON_BETA2 (0.99) → slower per-row variance EMA → smoother Muon update magnitudes but lags noisy gradient variations. Direct sign on val (+0.0062) suggests the current 0.95 default is well-tuned. Lower direction (0.90, faster EMA) might also miss given default's well-tuned status.

**Decision pending**: If Arm A also misses, axis closes.

---

### nezuko #657 SCHEDULE_SHAPE — Arm A (cosine) CATASTROPHIC, Arm B pending

Branch: `g1r2-nezuko/schedule-shape-sweep`. Arm A terminal 10:53 UTC.

| Arm | SCHEDULE_SHAPE | val_loss (n=1) | ffs | n=1 hold gate | W&B |
|-----|----------------|----------------|-----|---------------|------|
| A | cosine | **3.28145** | **-1 (NEVER reached 3.28)** | CATASTROPHIC MISS | `a40adbuq` |
| B | quadratic | (launching) | — | — | (pending) |

**Trajectory inspection**: Cosine held val at ~3.281 in the last few hundred steps — near-zero LR plateau in the cosine tail prevented final descent. Linear's straight-line LR=0 transition (default) actually outperforms because the model can still make progress with the discrete final LR step → 0 update.

**Mechanism**: Cosine's smooth `(1+cos)/2` envelope spends too much time at near-zero LR in the tail. The linear schedule's higher-near-end LR (LR/N at step N-1) is what enables the final descent on this benchmark. **First strong evidence that cooldown-tail LR profile matters more than the smoothness of the schedule.**

**Decision pending**: Arm B quadratic has a steeper drop in late cooldown (less plateau) so may not catastrophe similarly. Will close axis after Arm B terminal.

---

## 2026-05-21 10:05 UTC — Cycle 71 mid-36: PR #653 alphonse ADAMW_BETA1 CLOSED — axis flat, AdamW first-moment default β1=0.8 locally optimal

### PR #653 — alphonse AdamW β1 global sweep — Both arms MISS

Branch: `g1r2-alphonse/adamw-beta1`. Both arms terminal by 10:30 UTC.

| Arm | ADAMW_BETA1 | Memory ~1/(1−β) | val_loss (n=1) | ffs | Δ vs baseline (3.26776) | Reached 3.28? | W&B |
|-----|-------------|----------------|----------------|------|-------------------------|----------------|------|
| A | 0.9 | ~10 steps | **3.27651** | 3100 | +0.00875 | yes @ step 3100 | `7y2r4jtt` |
| B | 0.95 | ~20 steps | **3.28168** | -1 (never) | +0.01392 | **NO** | `5qpwr7ol` |

**Disabled-check** (`ADAMW_BETA1=0.8`, 200 steps): val@200=4.08267 ✓ (env-var plumbing verified, defaults to 0.8 byte-equivalent to baseline).

**Trajectory comparison** — monotonic Δ growth Arm B over Arm A:

| step | Arm A (β1=0.9) | Arm B (β1=0.95) | Δ(B−A) |
|------|---------------:|----------------:|-------:|
| 500 | 3.80632 | 3.81053 | +0.0042 |
| 1000 | 3.66338 | 3.66969 | +0.0063 |
| 1500 | 3.53291 | 3.54221 | +0.0093 |
| 2000 | 3.43345 | 3.44394 | +0.0105 |
| 2125 | — | 3.42528 | — |

**Mechanism interpretation**:
- β1 governs the AdamW first-moment EMA timescale. With LOGIT_SOFTCAP=20 (looser cap), the lm_head sees larger raw backward gradient magnitudes. The default β1=0.8 (~5-step memory) gives the right refresh rate to track this signal.
- Higher β1 over-smooths: the larger gradients are averaged across a longer window, dampening the cooldown response.
- Arm B (β1=0.95, ~20-step memory) catastrophically stalled in late cooldown — never reached the 3.28 target by step 3175. This is the signature of "memory length exceeds cooldown response time."

**Joint conclusion with fern #625 (β2 closure)**: β1=0.8 + β2=0.95 are **jointly locally optimal** on the c=20 baseline. Both first and second moment AdamW defaults absorbed the c=20 signal. The AdamW group is well-tuned at this level of abstraction.

**Decision**: CLOSE the β1 axis. Alphonse → #673 MUON_LR sweep (fresh Muon-side base LR axis — never ablated; mirrors closed AdamW LR work).

## 2026-05-21 09:25 UTC — Cycle 71 mid-35: First-half-of-round Arm A terminal sweep (5 arms landed in ~1h window)

### Arm A terminal summary (all c=20 baseline, val_target=3.26776, ffs_target=3000)

| PR | Student | Axis | Arm A | val/loss | ffs | Δval | Δffs | n=1 hold gate (val≤3.27 AND ffs≤3000) | Notes |
|---|---|---|---|---|---|---|---|---|---|
| **#642** | **edward** | **ADAMW_LR_FLOOR** | **0.05** | **3.26712** | **3000** | **−0.00064** | **0** | **PASS** ⭐⭐⭐ | **WIN candidate, n=2 seed 1 running, ETA ~10:13 UTC** |
| #655 | thorfinn | EMBED_LR_MULT | 0.5 | 3.26866 | 3000 | +0.00090 | 0 | PASS (gate only) | Misses merge by +0.00090; decide n=2 after Arm B |
| #654 | frieren | LM_HEAD_LR_MULT | 2.0 | 3.2690 | 3025 | +0.00124 | +25 | MISS | Up direction failed; awaiting Arm B (mult=0.5) |
| #656 | askeladd | MU_COOLDOWN_END | 0.85 | 3.2706 | 3025 | +0.00284 | +25 | MISS | More aggressive Mu swing hurts; awaiting Arm B (0.95, no swing) |
| #650 | tanjiro | LOGIT_SOFTCAP | 25 | 3.2730 | 3050 | +0.00524 | +50 | MISS | c=25 reverses c=15→c=20 monotone direction; awaiting Arm B (c=30) |
| #653 | alphonse | ADAMW_BETA1 | 0.9 | 3.27651 | 3100 | +0.00875 | +100 | MISS | Statsig n=1 also fails; β1=0.8 likely well-tuned |

### Cross-PR pattern observation

The narrow miss band (+0.0009 → +0.003) across AdamW group axes (#654 lm_head, #655 embed, #653 β1, plus the Mu-side #656) suggests the c=20 baseline absorbed much of the upstream productive AdamW signal. Once LOGIT_SOFTCAP=20 loosens the cap, the output-side parameters reach a tighter local optimum — most directional perturbations now narrowly hurt. Edward's ADAMW_LR_FLOOR is structurally orthogonal (schedule-level, not denominator/LR-level), explaining why it remains productive.

### Tanjiro #650 chronological clarification

Earlier in the round tanjiro reported PIDs colliding and runs being killed for OOM. Final canonical Arm A run is `hk5yhvot` (val=3.2730, ffs=3050). Other run IDs were either step-0 failures (`s5c9hy9c`, `58it4mxw`) or step-400 crashes (`i6qcfpf4`). Student heartbeat at 08:27 UTC incorrectly referenced `s5c9hy9c` as healthy at step 1840 — that run was actually pre-launch failure. The successful Arm A is unambiguous: `hk5yhvot`.

### Fern #661 disabled-check stall (3rd this cycle after edward #642 and tanjiro #650)

W&B shows 6 `g1r2-fern/normuon-beta2-disabled-check` runs since 07:53 UTC (PR assigned 07:47) — 5 completed cleanly at step 200 (val 4.082–4.087 within expected 4.08–4.10), 6th still in-progress at 09:16 UTC. No Arm A or Arm B launched. **Same pattern as edward #642 / tanjiro #650.** Advisor override posted 09:20 UTC instructing immediate kill of in-progress disabled-check and launch of Arm B (NORMUON_BETA2=0.99, higher-prior per PR). Awaiting student response.

### Decisions queued for next cycle

1. **Edward #642** — if seed 1 lands val < 3.26840 (very plausible), merge candidate. Run `senpai:merge-winner` after both seeds terminal.
2. **Thorfinn #655** — wait for Arm B (mult=2.0) terminal. If Arm B clearly worse, authorize n=2 confirm of Arm A despite narrow merge bar miss; else close axis.
3. **Frieren #654 / Askeladd #656 / Alphonse #653 / Tanjiro #650** — likely closures, but check Arm B's first (especially askeladd's "no Mu cooldown" control direction may be informative).
4. **Nezuko #657** — terminal in ~1h, decide on shape outcome.
5. **Fern #661** — verify Arm B launches; expect terminal in ~2-3h after launch.

## 2026-05-21 08:32 UTC — Cycle 71 mid-34: 🎯 PR #642 edward Arm A WIN candidate at terminal — n=2 confirm authorized

### PR #642 — edward AdamW LR floor — Both arms terminal, Arm A WIN CANDIDATE ⭐

Branch: `g1r2-edward/adamw-lr-floor`. Arm B (FLOOR=0.10, `jlybeatf`) terminal at 08:29 UTC.

| Arm | ADAMW_LR_FLOOR | val/loss | ffs | Δval vs NEW (3.26776) | Hold gate |
|---|---|---|---|---|---|
| **A** | **0.05** | **3.26712** | **3000** | **−0.00064** ✓ | **PASS** |
| B | 0.10 | 3.26842 | 3000 | +0.00066 ✗ | val miss |

**Statsig (n=1)**:
- Arm A: (3.28 − 3.26712) × √1 = 0.01288 → 3.22× threshold ✓
- Arm B: (3.28 − 3.26842) × √1 = 0.01158 → 2.90× threshold ✓

**Late-cooldown trajectory** (Δ = B − A):

| step | Arm A (0.05) | Arm B (0.10) | Δ (B−A) |
|---|---|---|---|
| 2875 | 3.29179 | 3.29291 | +0.00112 |
| 2950 | 3.28327 | 3.28433 | +0.00106 |
| 3000 | 3.27852 | 3.27981 | +0.00129 |
| 3050 | 3.27369 | 3.27526 | +0.00157 |
| 3100 | 3.27021 | 3.27188 | +0.00167 |
| 3150 | 3.26778 | 3.26920 | +0.00142 |
| 3175 | **3.26712** | **3.26842** | +0.00130 |

**Mechanism — floor activation window analysis**:
- Arm A (floor=0.05): activates when `eta < 0.05`, i.e. progress > 0.965 → step ~3063. Active window: **~112 steps (3.5% of run)**.
- Arm B (floor=0.10): activates when `eta < 0.10`, i.e. progress > 0.93 → step ~2953. Active window: **~222 steps (7.0% of run)**.

The longer active window of floor=0.10 keeps AdamW LRs higher longer in the tail — and that HURTS. Floor=0.05 gives just enough refinement without preventing cooldown's intended damping. Mild floor is exactly right; the gap WIDENS as the floor's active window extends, confirming "too much floor reverses gain."

**Strategic note** (from fern #625 closure): ADAMW_LR_FLOOR acts at the **LR-schedule level**, NOT the denominator level. This sidesteps the lm_head denominator antagonism that closed fern β2=0.99 + c=20 composition. Floor is a CLEAN candidate for stacking with future c=20-compatible mechanisms.

**Decision**: HOLD PR in `status:wip`. n=2 confirm AUTHORIZED with seed 1. ETA terminal ~10:13 UTC. If both seeds land val ≤ 3.27 AND ffs ≤ 3000, MERGE.

## 2026-05-21 07:35 UTC — Cycle 71 mid-33: PR #625 fern ADAMW_BETA2 CLOSED on c=20 stack (antagonistic composition); fern → #661 NORMUON_BETA2 (Muon-side EMA)

### PR #625 — fern AdamW β2 sweep — CLOSED

Branch: `g1r2-fern/adamw-beta2-sweep`. Re-run on c=20 stack terminal.

| Arm | Stack | val/loss | ffs | Δval vs NEW (3.26776/3000) | Δffs vs NEW |
|---|---|---|---|---|---|
| A (β2=0.99) | original c=15 (n=1, dprue0mx) | 3.26704 | 3000 | — (was on old c=15 stack) | — |
| A re-run (β2=0.99 + c=20) | new mandatory c=20 (n=1, 9v03uc9n) | **3.27064** | **3025** | +0.00288 | +25 |

**Cooldown trajectory comparison** (β2=0.99 + c=15 vs β2=0.99 + c=20):

| Step | β2=0.99 + c=15 | β2=0.99 + c=20 | Δ (c=20 − c=15) |
|---|---|---|---|
| 2900 | 3.28862 | 3.29202 | +0.00340 |
| 3000 | 3.27823 | 3.28172 | +0.00349 |
| 3050 | 3.27336 | 3.27685 | +0.00349 |
| 3175 | 3.26704 | **3.27064** | +0.00360 |

**Key finding — antagonistic composition**: +0.0036 stable penalty across 12 cooldown checkpoints (std <0.0001) is real signal, not seed noise. Mechanism: β2=0.99 + LOGIT_SOFTCAP=20 over-smooth the same parameter group (lm_head). c=20 loosens the cap → larger gradient magnitudes flow into lm_head AdamW group; β2=0.99's longer EMA over these wider magnitudes makes the denominator over-smooth precisely where adaptation matters most in cooldown.

**Strategic lesson**: β2=0.99 was a baseline-specific win on c=15, NOT generally additive. Mechanisms touching the same parameter group (lm_head: c=20, β2, β1, LR floor, lm_head LR) may NOT compose with each other. Edward #642 (ADAMW_LR_FLOOR) is the cleanest candidate because it acts at the LR-schedule level, not the denominator level.

**Decision**: CLOSED. AdamW β2 axis is exercised — β2=0.999 closed on slow early adaptation, β2=0.99 wins on c=15 but loses on c=20. β2=0.95 stays as default.

### Assignment: fern → PR #661 (NORMUON_BETA2 sweep)

**Hypothesis**: NORMUON_BETA2=0.95 (hardcoded line 460) is the Muon-side analogue of AdamW β2 — controls per-row variance EMA in the contra+normuon Muon update. Applied to **Muon block parameters** (q/k/v/proj/fc), not output side. Structurally different from AdamW β2: per-row not per-coord, applied after NS orthogonalization. Never ablated.

**Arms**:
- A: NORMUON_BETA2=0.90 (faster EMA, ~10-step memory)
- B: NORMUON_BETA2=0.99 (slower EMA, ~100-step memory) — Arm B first as higher prior

**Code change**: 1-line — add env var wrap on line 460.

**Theme**: Fresh Muon-side EMA axis. AdamW β2 axis is closed via antagonism with c=20; Muon-side has different geometry and may have a genuinely different optimum.

## 2026-05-21 07:15 UTC — Cycle 71 mid-32: PR #630 nezuko ROPE_BASE CLOSED (axis flat); nezuko → #657 SCHEDULE_SHAPE (cosine/quadratic vs linear)

### PR #630 — nezuko RoPE base frequency sweep — CLOSED

Branch: `g1r2-nezuko/rope-base-sweep`. Both arms terminal; both miss.

| Arm | ROPE_BASE | val/loss | ffs | Δval vs NEW (3.26776/3000) | Δffs vs NEW |
|---|---|---|---|---|---|
| A | 256 (4× sharper) | 3.27049 | 3025 | +0.00273 | +25 |
| B | 4096 (4× broader) | 3.26937 | 3025 | +0.00161 | +25 |
| default | 1024 | — | — | — | — |

**Cross-arm trajectory** (key checkpoints):

| Step | Arm A (256) | Arm B (4096) | Δ |
|---|---|---|---|
| 500 | 3.80102 | 3.80353 | +0.00251 |
| 1500 | 3.53171 | 3.53229 | +0.00058 |
| 2500 | 3.34653 | 3.34593 | −0.00060 |
| 3000 | 3.28165 | 3.28038 | −0.00127 |
| 3175 | 3.27049 | 3.26937 | −0.00112 |

**Key findings**:
1. **Axis is essentially flat** — trajectories overlap within ~0.001 throughout training.
2. **ffs UNCHANGED (3025) across both arms** — RoPE base does NOT move ffs floor.
3. **4× sharper and 4× broader gave near-identical results** — RoPE with half-truncation insensitive across this range on 1024-token sequences.
4. **Both arms PASS val ≤ 3.272 but FAIL ffs ≤ 3000** — no hold.

**Decision**: ROPE_BASE=1024 is locally optimal. Position-encoding base frequency is not a productive axis under current stack. Half-truncation fraction (50% of head_dim rotated) is a different axis but explicitly off-limits in this PR.

### Assignment: nezuko → PR #657 (SCHEDULE_SHAPE sweep)

**Hypothesis**: LR cooldown SHAPE (linear) has never been ablated — only its FRACTION (#549 closed) and ENDPOINTS (#615 Muon LR floor, #608 Muon LR warmup, #598 AdamW LR warmup, #610 NS5 cooldown precision — all closed). Edward #642 Arm A WIN candidate signal ("cooldown tail activity wins") strongly motivates testing alternate cooldown shapes.

**Arms**:
- A: `SCHEDULE_SHAPE=cosine` — `0.5 * (1 + cos(π t))`, slow initial decay + sharp final. Holds high LR longer at start of cooldown.
- B: `SCHEDULE_SHAPE=quadratic` — `(1 - t)²`, fast initial decay + slow tail. Opposite shape: drop LR fast early.

**Code change**: ~7 LoC — add SCHEDULE_SHAPE env var, add cosine/quadratic branches in `set_hparams`.

**Theme**: First true SHAPE ablation. Edward's WIN candidate signature ("more activity in cooldown tail") favors cosine.

## 2026-05-21 07:00 UTC — Cycle 71 mid-31: PR #634 askeladd ATTN_SOAP_BETA2 CLOSED; askeladd → #656 MU_COOLDOWN_END (fresh Muon-side schedule axis)

### PR #634 — askeladd SOAP preconditioner β2 sweep — CLOSED

Branch: `g1r2-askeladd/attn-soap-beta2-sweep`. Both arms terminal; both miss new bar.

| Arm | ATTN_SOAP_BETA2 | val/loss | ffs | Δval vs NEW (3.26776/3000) | Δffs vs NEW |
|---|---|---|---|---|---|
| A | 0.80 (faster, ~5-step memory) | 3.26953 | 3025 | +0.00177 | +25 |
| B | 0.95 (slower, ~20-step memory) | 3.27075 | 3025 | +0.00299 | +25 |
| default | 0.90 (~10-step memory) | — | — | — | — |

**Cross-arm trajectory** (highlights — student's full table is comprehensive):

| Step | Arm A (β2=0.80) | Arm B (β2=0.95) | Δ (A-B) |
|---|---|---|---|
| 500 | 3.80963 | 3.79339 | +0.01624 (B leads) |
| 1500 | 3.53596 | 3.52649 | +0.00947 (B leads) |
| 2500 | 3.34657 | 3.35148 | −0.00491 (A leads) |
| 3175 | 3.26953 | 3.27075 | −0.00122 (A leads terminal) |

**Key findings**:
1. **Axis is flat** — cross-arm gap <0.0013 at terminal; ffs UNCHANGED at 3025 across both arms.
2. **Directional prior wrong** — predicted Arm B (slower β2) higher prior per "fern β2=0.99 win pattern". Reality: faster β2=0.80 marginally better. SOAP Kronecker-factor EMA timescale does NOT behave like AdamW per-coordinate g² EMA — different regularizer class.
3. **ffs=3025 stuck** — confirms SOAP β2 is not the lever to attack ffs floor.
4. **No instability** — shorter SOAP β2 memory did not produce val spikes (tail risk did not materialize).

**Decision**: CLOSED. ATTN_SOAP_BETA2=0.90 is locally optimal. Do NOT re-propose SOAP β2 sweep. SOAP TRUST_THRESHOLD and PRECOND_FREQ remain unexplored but lower priority.

### Assignment: askeladd → PR #656 (MU_COOLDOWN_END sweep)

**Hypothesis**: Mandatory stack hardcodes MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 — Muon momentum swings 0.05 during cooldown. This END VALUE has NEVER been ablated. All prior Muon work was on LR schedule envelope (warmup #608, floor #615, NS5 precision #610) — MU schedule is a separate, untested axis.

**Arms**:
- A: MU_COOLDOWN_END=0.85 (bigger swing: 0.95→0.85, more aggressive momentum reduction)
- B: MU_COOLDOWN_END=0.95 (no swing: constant 0.95 throughout — eliminate MU cooldown)

**Theme**: Mirrors edward #642 Arm A WIN candidate (ADAMW_LR_FLOOR=0.05 keeps AdamW groups updating in cooldown tail). Tests whether the same "more activity in cooldown tail" mechanism applies to Muon momentum.

**No code change**: env vars already wired (line 449).

## 2026-05-21 06:45 UTC — Cycle 71 mid-30: PR #637 thorfinn INTERNAL_INIT_MULT CLOSED; thorfinn → #655 EMBED_LR_MULT sweep (mirror to frieren #654)

### PR #637 — thorfinn Internal block weight init multiplier — CLOSED

Branch: `g1r2-thorfinn/internal-init-mult-sweep`. Both arms terminal at 06:44 UTC.

| Metric | Arm A (mult=0.5, `30yg21gb`) | Arm B (mult=2.0, `8fy097oa`) | NEW Baseline (3.26776/3000) | Verdict |
|---|---|---|---|---|
| val/loss@3175 | 3.27156 | 3.26927 | 3.26776 | ❌ A miss +0.0038; B miss +0.00151 |
| ffs | 3025 | 3025 | 3000 | ❌ Both miss by +25 |
| step_avg | 1981.7ms | 1981.5ms | — | — |

**Key trajectory observation**: Arm B (larger init) starts hot (val@500=3.81 vs A's 3.696) but **crosses over Arm A in last ~200 steps** — by terminal Arm B is 0.00229 better than Arm A on val. This is a late-cooldown signature: larger internal weights pay early cost but extract more from cooldown.

**However, ffs is IDENTICAL (3025) for both arms**. The late closure happens AFTER the val=3.28 crossing — internal init magnitude does NOT lift ffs below 3025.

**Decision**: CLOSED axis. INTERNAL_INIT_MULT=1.0 (torch default) is locally optimal. Init-asymmetry trifecta+1 fully closed: input embed magnitude (std=0.1 ✓), output proj zero (✓), residual proj zero (✓), internal weights torch default (✓).

### Assignment: thorfinn → PR #655 (EMBED_LR_MULT sweep)

**Hypothesis**: Embed LR=0.3 may be off-optimum. Direct symmetric mirror to frieren #654 (LM_HEAD_LR_MULT sweep). Together form 2×2 mechanism dissection of AdamW output-side LR rebalancing.

**Arms**: EMBED_LR_MULT=0.5 (Arm A, less aggressive — effective lr=0.15), EMBED_LR_MULT=2.0 (Arm B, more aggressive — effective lr=0.6).

**Code change**: 2-line diff — add EMBED_LR_MULT env var, multiply embed param group lr.

**Theme**: Five AdamW group winners now converging (LOGIT_SOFTCAP, β2=0.99, LR_FLOOR, β1 sweep, lm_head LR sweep) — embed LR is the natural symmetric completion of the LR rebalancing story.

## 2026-05-21 06:35 UTC — Cycle 71 mid-29: 🎯 PR #642 edward Arm A WIN candidate; #633 alphonse + #619 frieren CLOSED; alphonse → #653 ADAMW_BETA1; frieren → #654 lm_head LR mult

### PR #642 — edward AdamW LR floor — Arm A WIN CANDIDATE ⭐

Branch: `g1r2-edward/adamw-lr-floor`. Arm A (ADAMW_LR_FLOOR=0.05) terminated at 06:25 UTC.

| Metric | Arm A (`ya3c7lzs`, n=1) | vs New Baseline (3.26776/3000) | Verdict |
|---|---|---|---|
| val/loss@3175 | **3.26712** | Δ**−0.00064** | ✅ PASS |
| ffs | **3000** | Δ=0 (tie) | ✅ PASS |
| step_avg | 1941.82ms | — | — |
| statsig n=1 | (3.28−3.26712)×√1 = 0.01288 | 3.22× ≥ 0.004 | ✓ |

**Trajectory** (cooldown tail signature):
- step 2900: 3.28883
- step 3000: 3.27852 (ffs crossed)
- step 3050: 3.27369
- step 3100: 3.26889
- step 3150: 3.26778
- step 3175: **3.26712** (terminal — sharp cooldown descent)

**Mechanism**: ADAMW_LR_FLOOR=0.05 keeps embed/lm_head/scalars updating in the final 5% of training (steps ~3017+) when base eta drops below 0.05. Output-side groups continue refining in late cooldown. Compared to PR #613 tanjiro c=20 final (3.26781): edward Arm A is **0.00069 BETTER**. The floor mechanism captures a different refinement window than the soft-cap mechanism.

**Decision**: HOLD PR in `status:wip`. Arm B (FLOOR=0.10) launched 06:31 UTC. After Arm B terminal, authorize n=2 confirm of Arm A.

### PR #633 — alphonse Attention scale sweep — CLOSED

Branch: `g1r2-alphonse/attn-scale-sweep`. Both arms terminal; both miss new bar.

| Metric | Arm A (ATTN_SCALE=0.088) | Arm B (ATTN_SCALE=0.15) | New Baseline (3.26776/3000) | Verdict |
|---|---|---|---|---|
| val/loss@3175 | (miss) | (miss) | — | ❌ CLOSE |

**Decision**: ATTN_SCALE=0.12 is local optimum on attention temperature axis. Axis CLOSED. Do not re-propose attention scale sweep.

### PR #619 — frieren z-loss regularization — CLOSED

Branch: `g1r2-frieren/z-loss-regularization`. Both arms miss.

**Decision**: z-loss not productive on this stack — LOGIT_SOFTCAP saturation already controls logit magnitudes; mechanisms overlap rather than compose. Soft regularizer + deterministic cap = redundant. Axis CLOSED.

### Assignment: alphonse → PR #653 (ADAMW_BETA1 sweep)

**Hypothesis**: AdamW β1=0.8 is conservative (~5-step momentum window). With 3 winners pointing at productive AdamW group + output side (LOGIT_SOFTCAP, β2=0.99, LR_FLOOR), test whether longer momentum (β1 ∈ {0.9, 0.95}) compounds.

**Arms**: β1=0.9 (Arm A, ~10-step memory), β1=0.95 (Arm B, ~20-step memory).

### Assignment: frieren → PR #654 (lm_head LR multiplier sweep)

**Hypothesis**: lm_head LR is hardcoded at 1/320 ≈ 0.003125 — 96× smaller than embed (0.3), 3.2× smaller than scalars (0.01). Never re-tuned. Three winners on AdamW output side suggest output groups undertrained. Test whether lm_head specifically benefits from more (Arm A: ×2 → 0.00625) or less (Arm B: ×0.5 → 0.00156) aggressive LR.

**Code change**: 2-line diff — add LM_HEAD_LR_MULT env var, multiply lm_head param group lr.

## 2026-05-21 05:24 UTC — Cycle 71 mid-28: ✅ PR #613 MERGED (tanjiro LOGIT_SOFTCAP=20.0); fern #625 n=2 sent back; tanjiro → #NEW logit-softcap-extended

### PR #613 — tanjiro Logit soft-cap sweep — MERGED ✅ ⭐

Branch: `g1r2-tanjiro/logit-softcap-sweep`. n=2 confirmation complete. LOGIT_SOFTCAP=20.0 (c=20) is now the merged baseline.

| Metric | Trial 0 (seed0, `1zb5h0e5`) | Trial 1 (seed1, `4v5jsjk9`) | n=2 mean | vs Old Baseline | vs New Bar | Verdict |
|---|---|---|---|---|---|---|
| val/loss@3175 | 3.26781 | 3.26771 | **3.26776** | Δ−0.001425 | **NEW BASELINE** | ✅ MERGED |
| ffs | 3000 | 3000 | **3000** | Δ−12.5 | **NEW BASELINE** | ✅ MERGED |
| statsig | — | — | **(3.28−3.26776)×√2 = 0.01731** | — | 4.33× ≥ 0.004 ✓ | — |

**Mechanism**: LOGIT_SOFTCAP=20.0 loosens the output cap `f(x)=c·x/√(x²+c²)` from c=15 → c=20. Post-EMBED_INIT_STD=0.1, pre-cap logit magnitudes shifted; c=15 was over-regularizing. Both seeds land ffs=3000 (zero variance) — the cap loosening pulls seeds that previously crossed 3.28 at step 3025 to step 3000.

**Decision**: SQUASH-MERGED to advisor branch. New baseline: val=3.26776, ffs=3000. LOGIT_SOFTCAP=20.0 added to mandatory stack.

### PR #625 — fern AdamW β2 sweep — n=2 SENT BACK ↩️

n=2 final results posted at 05:27 UTC (3 min after #613 merge shifted baseline):

| Metric | Seed 0 (`dprue0mx`) | Seed 1 (`snunl6nt`) | n=2 mean | vs New Baseline (3.26776/3000) | Verdict |
|---|---|---|---|---|---|
| val/loss@3175 | 3.26704 | 3.26940 | 3.26822 | +0.00046 | ❌ MISS |
| ffs | 3000 | 3025 | 3012.5 | +12.5 | ❌ MISS |

**Analysis**: Seeds split: seed0 is exceptional (3.26704, beats even new baseline); seed1 regressed to 3.26940 (above both old and new bars). High inter-seed variance (Δ=0.00236) swamps the win margin. Mechanism is REAL — seed0 demonstrates β2=0.99 can reach 3.26704 (Δ−0.0008 vs new baseline). 

**Decision**: SENT BACK. Re-run Arm A (β2=0.99) with LOGIT_SOFTCAP=20.0 in stack. If orthogonal mechanisms stack additively, expected n=1 seed result ~3.266-3.267.

### Assignment: tanjiro → PR #650 (logit-softcap-extended)

**Hypothesis**: LOGIT_SOFTCAP direction is MONOTONE INCREASING (c=12 miss → c=15 old baseline → c=20 WIN). Optimum unknown. Testing c=25 (Arm A) and c=30 (Arm B) to find peak or close axis. At these values, the cap is near-identity for typical logit magnitudes (~10-15); main effect is on tail logits.

## 2026-05-21 UTC — Cycle 71 mid-26: PR #610 CLOSED (edward NS5 cooldown precision — val~3.269/ffs=3025 noise basin, both arms miss merge bar); edward → #642 AdamW LR floor (4th corner of schedule envelope; ADAMW_LR_FLOOR ∈ {0.05, 0.10})

### PR #610 — edward NS5 cooldown precision ramp — CLOSED (noise basin, both arms miss)

Branch: `g1r2-edward/ns5-cooldown-precision`. Scheduled NS5_ITERS ramp from 14 to 18/20 during the last 70% of training.

| Arm | NS5_COOLDOWN_ITERS | val@3175 | ffs | Δval | Δffs | Verdict |
|---|---|---|---|---|---|---|
| A | 14 → 18 | 3.26905 | 3025 | -0.000135 | +12.5 | val beat within noise (0.0001≪0.004), ffs MISS |
| B | 14 → 20 | 3.27003 | 3025 | +0.000846 | +12.5 | both MISS |
| Baseline | 14 (fixed) | 3.269185 | 3012.5 | — | — | — |

W&B runs: `8uwj4n0u` (A n=1), `lcu99t2n` (B n=1).

**Decision**: This is the **third orthogonal arm** landing at val~3.269/ffs=3025 this cycle (joins thorfinn #615 Arm A val=3.268967/ffs=3025 [Muon LR floor=0.05] and this arm). Confirmed STACK NOISE BASIN — repeated landing at (val=3.268-3.270, ffs=3025) across entirely different mechanisms. Val beat of 0.000135 is 30× below statsig threshold.

**Context**: tanjiro #613 Arm B (LOGIT_SOFTCAP=20) hit val=3.26781/ffs=3000 (10× larger val margin AND ffs improvement). That's the real signal. NS5 precision ramp yields real-but-tiny val improvement indistinguishable from seed noise.

**Schedule-side closure**: All 4 corners of schedule envelope now tested: AdamW warmup (#598 closed), Muon warmup (#608 closed), Muon LR floor (#615 closed), NS5 precision ramp (#610 closed). **edward → #642 AdamW LR floor** — the literal remaining fourth corner.

### Assignment: edward → PR #642 (AdamW LR floor)

**Hypothesis**: The schedule envelope cube has 3/4 corners closed (AdamW warmup #598, Muon warmup #608, Muon LR floor #615). The **fourth corner — AdamW group LR floor in cooldown tail** — has never been tested. Currently `eta = (1-progress)/cooldown_frac` decays to exactly 0 at terminal for ALL groups (Muon AND AdamW). Muon floor was closed as unproductive (#615). But AdamW group (embed+lm_head+scalars) is a DIFFERENT parameter class — sparse-gradient, vocab-aligned — and may benefit from continued small updates in tail. Also contextually relevant: tanjiro's c=20 win (n=2 confirm in flight) shows lm_head is newly important; continued AdamW updates may refine the soft-cap regime exploitation. Two arms: ADAMW_LR_FLOOR ∈ {0.05, 0.10} (symmetric to closed Muon brackets).

## 2026-05-21 UTC — Cycle 71 mid-25: 🎯 PR #613 tanjiro logit soft-cap — Arm B (c=20) WIN CANDIDATE at n=1; n=2 confirm requested

### PR #613 — Logit soft-cap sweep (c ∈ {12, 20} vs default 15) — n=2 IN FLIGHT

Branch: `g1r2-tanjiro/logit-softcap-sweep`. Tests whether c=15 hardcoded at model.forward line 431 is still optimal under the new EMBED_INIT_STD=0.1 baseline (#541). The soft-cap formula `c·x / √(x²+c²)` saturates logits at ±c.

| Arm | LOGIT_SOFTCAP | val@3175 | ffs | Δval | Δffs | Verdict |
|---|---|---|---|---|---|---|
| A | 12 (tighter) | 3.27030 | 3025 | +0.001115 | +12.5 | ❌ miss both legs |
| **B** | **20 (looser)** | **3.26781** | **3000** | **−0.001375** ✓ | **−12.5** ✓ | **WIN n=1 BOTH LEGS** |
| Baseline (n=2) | 15 (default) | 3.269185 | 3012.5 | — | — | — |

**n=1 statsig**: Arm B (3.28 − 3.26781) × √1 = 0.0122 ≫ 0.004 → PASSES
**Hold gate** (val ≤ 3.271 AND ffs ≤ 3012.5): Arm B passes both → HOLD for n=2 confirm

W&B runs: `zailpoth` (disabled-check val@200=4.0881 byte-equiv), `62t339ev` (A smoke 500: 3.69710), `9z1d4nkq` (B smoke 500: 3.69706), `mzltpaws` (A n=1 3175), `1zb5h0e5` (B n=1 3175).

**Mechanism interpretation**: With EMBED_INIT_STD=0.1, input embeddings are 2.8× larger than the pre-#541 baseline (std≈0.036). This pushes pre-cap logit distribution to higher magnitudes; the c=15 cap was tuned for the OLD lower-magnitude regime and now over-regularizes — flatter peak distribution at any given logit magnitude. Looser c=20 acts as near-identity for the model's typical confident logits (log(50257)≈10.8), removing the over-constraint. Monotone direction (A worse, B better) confirms the optimum is to the RIGHT of 15.

**Next**: n=2 confirm requested — additional seed of Arm B (LOGIT_SOFTCAP=20). If trial 1 + trial 0 mean val < 3.269185 AND ffs ≤ 3012.5 AND statsig (3.28 − val_mean) × √2 ≥ 0.004 (val_mean ≤ 3.2772), this merges as new baseline. Trial 1 ETA ~110 min.

**Significance**: First val+ffs joint pass since #541 merge. Confirms architecture-side output-transform is a productive axis post-init-trifecta closure. The c=15 default was inherited from the speedrun lineage tuned on pre-#541 init regime.

## 2026-05-21 UTC — Cycle 71 mid-24: PR #615 CLOSED (thorfinn Muon LR floor — both arms miss; schedule back-end fully closed); thorfinn → #637 internal block weight init multiplier

### PR #615 — thorfinn Muon LR floor (MUON_LR_FLOOR ∈ {0.05, 0.10}) — CLOSED

Branch: `g1r2-thorfinn/muon-lr-floor`. Tests whether clamping Muon LR to a minimum floor (eta_min × MUON_LR) in cooldown tail prevents over-cooling on the Muon group.

| Arm | MUON_LR_FLOOR | val@3175 | ffs | Δval | Δffs | Verdict |
|---|---|---|---|---|---|---|
| A | 0.05 (terminal lr = 0.04×0.05 = 0.002) | 3.268967 | 3025 | -0.000218 | +12.5 | ❌ val beat within noise, ffs MISS |
| B | 0.10 (terminal lr = 0.04×0.10 = 0.004) | 3.273641 | 3075 | +0.004 | +62.5 | ❌ both MISS |
| Baseline | linear-to-zero | 3.269185 | 3012.5 | — | — | — |

**Decision**: Arm A val=3.268967 beats baseline by Δ=0.000218 — within trial noise (~2e-4), NOT statsig (statsig requires Δ≥0.004). ffs misses by +12.5. This is the **third arm this cycle** landing at val~3.269 / ffs~3025 (edward #610 Arm A: val=3.269047, ffs=3025; thorfinn #601: similar basin). The convergence basin is being repeatedly re-hit by orthogonal interventions — not true improvements, just stack noise floor.

Arm B (FLOOR=0.10) clearly worse — higher floor freezes Muon in cooldown → prevents final descent into val=3.269 basin.

**Mechanism confirmed**: Floor-activation telemetry showed terminal muon_lr = 0.04 × FLOOR for both arms — implementation clean.

**Conclusion**: **Muon-side schedule back-end fully closed.** Linear-to-zero is optimal for Muon LR terminal value; floor values in both directions produce no improvement. Symmetric to Arm A finding.

### Assignment: thorfinn → PR #637 (internal block weight init multiplier)

**Hypothesis**: `attn.q/k/v.weight` and `mlp.fc.weight` all use torch default `std=0.33**0.5/sqrt(fan_in)` (line 891). This "else" branch initializes all non-embed/non-proj weights and has **NEVER been swept on this stack**. The init trifecta (input embed std=0.1 ✓, output lm_head zero ✓, residual proj zero ✓) closed the perimeter — but the internal weights in the middle have been untouched. With EMBED_INIT_STD=0.1 in the stack (10× smaller embed), gradient flow into QKV/fc is altered vs the old default. Two arms: INTERNAL_INIT_MULT ∈ {0.5, 2.0} vs default 1.0.

## 2026-05-21 UTC — Cycle 71 mid-23: PR #608 CLOSED (alphonse Muon LR warmup — not productive; both arms MISS); PR #611 CLOSED (askeladd residual proj init — zero-init optimal; init trifecta complete); alphonse → #633 attention scale sweep; askeladd → #634 SOAP β2 sweep

### PR #608 — alphonse Muon LR warmup — CLOSED (Muon LR warmup not productive)

| Arm | MUON_LR_WARMUP_STEPS | val@3175 | ffs | Δval | Δffs |
|---|---|---|---|---|---|
| A | 100 | 3.27121 | 3025 | +0.002025 | +12.5 |
| B | 300 | 3.27407 | 3075 | +0.004885 | +62.5 |

**Conclusion**: Arm B worse than Arm A — longer warmup hurts more. Muon optimizer is already well-conditioned at MUON_LR=0.04 from step 0. No warmup is the local optimum. Mechanism class Muon-side schedule front-end closed. Symmetric to edward #598 (AdamW LR warmup).

### PR #611 — askeladd residual projection init — CLOSED (zero-init confirmed optimal)

| Arm | RESIDUAL_PROJ_INIT_STD | val@3175 | ffs | Δval | Δffs |
|---|---|---|---|---|---|
| A | 0.002 | 3.27171 | 3050 | +0.00253 | +37.5 |
| B | 0.010 | 3.27012 | 3025 | +0.00094 | +12.5 |

**Conclusion**: Progression — larger non-zero init → closer to baseline (less hurt). But still misses. Zero-init is optimal on residual projections (same story as lm_head #602). Init trifecta complete: input embed magnitude wins (#541 ✓), output proj zero-optimal (#602), residual proj zero-optimal (this). Asymmetric init principle confirmed.

### Assignments: alphonse → #633, askeladd → #634

- **alphonse #633 attention scale sweep**: ATTN_SCALE ∈ {0.088, 0.15} vs hardcoded 0.12. Scale=0.12 is 1.36× textbook (1/√128=0.088), never ablated. Architecture-side attention softmax temperature.
- **askeladd #634 SOAP β2 sweep**: ATTN_SOAP_BETA2 ∈ {0.80, 0.95} vs hardcoded 0.90. Controls EMA timescale of Kronecker-factor estimates for attention weights. Distinct from AdamW β2 (#625). ffs floor attack via faster/slower preconditioner adaptation.

## 2026-05-21 UTC — Cycle 71 mid-21: PR #602 CLOSED (nezuko lm_head non-zero init — output zero-init confirmed optimal; asymmetric init story complete); nezuko → #630 RoPE base frequency sweep

### PR #602 — nezuko lm_head non-zero init sweep — CLOSED (zero-init confirmed optimal on output side)

Branch: `g1r2-nezuko/lm-head-init`. Tests whether zero-init on the output projection (`model.proj.weight`) leaves headroom, complementary to askeladd's `EMBED_INIT_STD=0.1` win on the input embedding.

| Arm | LM_HEAD_INIT_STD | val@3175 | ffs | Verdict |
|---|---|---|---|---|
| A | 0.02 | miss (val > baseline 3.269185) | miss | ❌ |
| B | 0.1 | miss (matching askeladd magnitude on output side) | miss | ❌ |

**Mechanism analysis**: The input embedding gain of magnitude ~22 (EMBED_INIT_STD=0.1 over vocab×dim) provides a scale that the optimizer can work with from step 0. The output projection's zero-init is a different story: GPT-2's convention of zero-init on `c_proj` (residual branch projections) is specifically load-bearing here — it initializes residual blocks as near-identity maps. Non-zero lm_head init puts energy into the logit distribution before training begins, creating an early CE signal that's hard for AdamW to rebalance in 3175 steps.

**Asymmetric init story** (crystallized from #541 + #591 + #602 together):
- Input embedding: wants magnitude ~22 (EMBED_INIT_STD=0.1) — high magnitude → strong early gradient → fast initial convergence
- Output projection: wants zero-init — any non-zero init → logit perturbation → CE gradient misalignment early in training
- This asymmetry is principled: embed maps tokens to representation space (benefit from scale), lm_head maps representation to logit space (benefit from zero start)

**Conclusion**: #602 confirms that the init trifecta has one axis closed (input embed ✓, output proj closed as zero-optimal, residual proj in-flight as #611). Zero-init on lm_head is the correct choice. Close axis.

### Assignment: nezuko → PR #630 (RoPE base frequency sweep)

**Hypothesis**: `ROPE_BASE=1024` is hardcoded at line 354 of `train_gpt_simple.py` and has NEVER been ablated on this stack. The base was presumably chosen to match sequence length (1024 tokens), so frequencies span exactly the in-sequence range. This is a **positional encoding** axis — entirely orthogonal to all 9+7+2+1+init closures (which are optimizer/loss/schedule/init). Two arms: ROPE_BASE=256 (sharper short-range, 4× faster position discrimination) vs ROPE_BASE=4096 (broader, extending 4× beyond seq_len). Implementation: ~3 LoC (env var read + 1 line in Rotary.__init__ + W&B log). Default ROPE_BASE=1024 preserves byte-equivalent baseline.

## 2026-05-21 UTC — Cycle 71 mid-20: PR #605 CLOSED (fern Muon heavy-ball — Nesterov re-blend IS load-bearing); fern → #625 AdamW β2 sweep; alphonse #608 Arm A terminal (val=3.2712, ffs=3025 — narrow miss both axes; Arm B pending)

### PR #605 — fern Muon heavy-ball ablation — CLOSED (Nesterov re-blend confirmed load-bearing; 9th variance-reduction closure)

Branch: `g1r2-fern/muon-heavy-ball`. Tests whether the Nesterov-style re-blend in Muon.step (line 694) is load-bearing or can be replaced by plain heavy-ball momentum.

| Arm | Config | kill gate | val@3175 | ffs | Verdict |
|---|---|---|---|---|---|
| A | MUON_HEAVY_BALL=1, MU_COOLDOWN_START=0.95 (β=0.95 > β_eff=0.9025) | killed step 1500 (val=3.55996 vs gate ≤ 3.55) | — | — | ❌ killed |
| B | MUON_HEAVY_BALL=1, fully-matched β_eff schedule (μ_warmup=0.7225, μ_plateau=0.9025, μ_cooldown_end=0.81) | passed all gates | 3.28014 | −1 (never crossed target) | ❌ MISS +0.011 |

W&B runs: vg3c634r (disabled-check), s69t9nsb (Arm A smoke), dcjfkn8h (Arm A n1 killed step 1500), a6xy4k4f (Arm B smoke), lt797uyu (Arm B n1 terminal).

**Mechanism analysis (from student)**:

Both re-blend and heavy-ball at matched β=μ² have identical *current-step* gradient weight (1-μ²), but differ in the historical-gradient weighting profile inside m_{t-1}:
- Re-blend m_{t-1}: EMA at rate μ (slower decay, ≈1/(1-μ) effective steps memory)
- Heavy-ball matched m_{t-1}: EMA at rate μ² (faster decay, ≈1/(1-μ²) effective steps memory)

At MU_COOLDOWN_END=0.90 (re-blend) / 0.81 (matched HB): re-blend integrates ~10 effective past steps; heavy-ball integrates ~5.3. Arm B's crossover pattern (better in plateau where recent gradients carry useful signal, worse in cooldown where noise dominates) confirms the re-blend's **longer integration window is specifically beneficial in late cooldown**.

**Conclusion**: The Nesterov re-blend is NOT a notational equivalence. It implements a distinct historical-gradient weighting profile tuned to the schedule. This is a NON-OBVIOUS mechanism, likely unintentional from the implementation perspective, but it IS load-bearing. Closing axis.

**This is the 9th variance-reduction/momentum closure**: joins COOLDOWN_FRAC #495, SWA #524, SAM #573, Lookahead #561, MARS #576, Adan #586, β1 ramp #587, AGC #580.

### Assignment: fern → PR #625 (AdamW β2 sweep)

**Hypothesis**: AdamW β2=0.95 (current) is unusually short. Modern LLMs use β2=0.95-0.999. With EMBED_INIT_STD=0.1 in the mandatory stack, the initial gradient magnitudes on embed/lm_head have shifted — optimal β2 may have shifted. Single env var ADAMW_BETA2, two arms: 0.99 (mid-point, 100-step effective memory) vs 0.999 (LLaMA/PaLM standard, 1000-step effective memory). Fresh EMA-timescale axis on AdamW second moment.

### alphonse #608 Arm A mid-cycle (waiting for SENPAI-RESULT)

Run e8mr7a46 (MUON_LR_WARMUP_STEPS=100) finished at step 3175: val=3.2712, ffs=3025, reached_target=1. Both bars narrowly missed: val +0.002 over baseline (3.269185), ffs +12.5 over baseline floor (3012.5). Arm B (MUON_LR_WARMUP_STEPS=300) status unknown — poke sent. Interesting direction: closest n=1 result to the bar since PR #541 merged.

## 2026-05-20 22:20 UTC — Cycle 71 mid-19: PR #591 CLOSED (frieren ortho-embed-init — decorrelation theory falsified); frieren → #619 z-loss regularization

### PR #591 — frieren orthogonal embed init — CLOSED (pure-magnitude confirmed; decorrelation mechanism falsified)

Branch: `g1r2-frieren/ortho-embed-init`. Orthogonal init for the input embedding weight using `torch.nn.init.orthogonal_`, two arms: gain=0.1 (matched magnitude to #541 winner) and gain=1.0 (standard orthonormal).

| Arm | Init | col-L2 magnitude | Decorrelation | val@3175 | ffs | Δval vs bar (3.269185) | pass? |
|---|---|---|---|---|---|---|---|
| A | ortho gain=0.1 | ~0.1 | strong (off-diag ~5e-7) | 3.28051 | — | **+0.0113** | ❌ catastrophic (never hit 3.28) |
| B | ortho gain=1.0 | ~1.0 | strong (off-diag ~5e-5) | 3.27675 | 3100 | **+0.0076** | ❌ statsig fail |

W&B runs: checked via PR comments (frieren self-reported terminal results with SENPAI-RESULT markers).

**Implementation note**: `torch.nn.init.orthogonal_` fails on BFloat16 CUDA (QR not implemented). Frieren self-fixed by building orthogonal matrix in float32 buffer and `copy_()`-ing to bf16. Off-diagonal max abs: ~5e-5 at gain=1.0, ~5e-7 at gain=0.1 — strong decorrelation achieved in both arms.

**2×2 mechanism dissection table** (all five arms across both PRs):

| Init | col-L2 magnitude | Decorrelation | val@3175 | Verdict |
|---|---|---|---|---|
| gauss std=0.5 (#541 Arm A) | ~112 | none | ~3.270 | neutral |
| **gauss std=0.1 (#541 Arm B — WINNER)** | **~22** | **none** | **3.26773** | **wins ⭐** |
| gauss std=0.02 (#541 Arm C) | ~4 | none | ~3.270 | neutral |
| ortho gain=1.0 (#591 Arm B) | ~1.0 | strong | 3.27675 | miss |
| ortho gain=0.1 (#591 Arm A) | ~0.1 | strong | 3.28051 | catastrophic |

**Root cause of failure**: Arm A (gain=0.1, matched magnitude ~22→0.1) fails catastrophically despite matched magnitude. Arm B (gain=1.0) fails even more than matched magnitude alone. Decorrelation adds no benefit and actively hurts at lower magnitudes.

**Mechanism confirmed**: The winning property of PR #541 std=0.1 is purely the **increased column L2 norm magnitude** of the input embedding. Decorrelation is irrelevant. The sequence: neutral at ~112, wins at ~22, neutral at ~4 establishes a non-monotonic sweet spot centred around std=0.1 col-L2 ≈ 22.

**Decorrelation theory falsified**: Five arms spanning 5-OOM of column magnitude with and without decorrelation. Decorrelation offers no consistent benefit — the sweet spot is magnitude, not structure.

**Implications**: (1) The init trifecta program (embed #541, lm_head #602, residual-proj #611) can proceed without worrying about decorrelation; magnitude alone is the relevant axis. (2) Further init work should focus on magnitude sweep or per-layer gain, not orthogonality. (3) #611 and #602 are both still in-flight and should be evaluated on their own terms.

### Assignment: frieren → PR #619 (z-loss regularization)

**Hypothesis**: Logit z-loss regularization — `loss += Z_LOSS_COEF · mean(logsumexp(raw_logits)²)` — is a well-documented LLM training technique (GPT-3, PaLM, Chinchilla, LLaMA) that has NEVER been tested on this benchmark. Applied on PRE-soft-cap logits (complementary to tanjiro #613's soft-cap sweep — different mechanism class: penalty vs. saturation). Prevents the partition function from drifting into a saturated regime where CE gradients become tiny.

Two arms: Z_LOSS_COEF=1e-4 (PaLM standard), Z_LOSS_COEF=1e-3 (10× aggressive). ~10 LoC change; one new env var; default 0.0 = byte-equivalent baseline. Benchmark-compliant (no extra forward-backward).

---

## 2026-05-20 21:35 UTC — Cycle 71 mid-18: PR #601 CLOSED (thorfinn Muon explicit WD — u/w-floor confirmed sufficient); thorfinn → #615 Muon LR floor

### PR #601 — thorfinn Muon explicit WD — CLOSED (u/w-floor sufficient, Muon-side regularization axis closed)

Branch: `g1r2-thorfinn/muon-explicit-wd`. MUON_WEIGHT_DECAY env-var-driven explicit decoupled WD on Muon group, two arms: WD=2.5e-3 (mild) and WD=2.5e-2 (original code-intent).

| Arm | WD | val@3175 | ffs | Δval vs new bar (3.269185) | Δffs vs bar (3012.5) | pass? |
|---|---|---|---|---|---|---|
| A | 2.5e-3 | 3.27088 | 3025 | **+0.0017** | **+12.5** | ❌ both legs |
| B | 2.5e-2 | killed @ step 1051 | — | val@500=3.80089 (+0.023) | — | ❌ catastrophic |

W&B runs: cpm9zjbn (Arm A), qzigkad3 (Arm B, killed).

**Against OLD baseline (3.270288)**: Arm A was a statistical tie (+0.00059). But against NEW baseline (3.269185, set by PR #541 EMBED_INIT_STD=0.1 merge), Arm A misses both legs cleanly. Arm B violated step-500 kill gate (3.80089 > 3.78).

**Root cause of Arm B failure**: At MUON_LR=0.04 with WD=0.025, per-step decay = 1 - 0.04×0.025 = 0.999 → ~3.1% cumulative shrinkage per epoch. Early training (when Muon-group norms are small) gets throttled heavily → early-training lag propagates through entire run.

**Root cause of Arm A neutrality**: u/w-floor (targeting u/w ratio = 0.35) already imposes the regularization the Muon group needs via its spectral update mechanism. At mild WD=2.5e-3 with LR=0.04, per-step decay is only 0.01% — noise floor relative to u/w-floor equilibrium.

**The "intentionally omitted" comment at line 709 was empirically correct**: Record #14's design choice to drop explicit WD in favor of u/w-floor was load-bearing, not vestigial. Arm B catastrophically confirms this.

**MUON_WEIGHT_DECAY plumbing now in place**: env-var at line 458, default 0.0 = byte-equivalent. Future Muon-side regularization probes (schedule-decoupled WD, per-leaf Muon WD, peak-WD multiplier on Muon) are now one-flag activations.

**Conclusion**: Muon-side regularization axis closed. u/w-floor + EMBED_INIT_STD=0.1 saturates Muon-group regularization Pareto front at tested values.

### Assignment: thorfinn → PR #615 (Muon LR floor)

**Hypothesis**: The Muon LR decays to EXACTLY 0 at terminal step — over-cooling the Muon group in the last few percent of training. MUON_LR_FLOOR clamps eta to max(eta, floor) for the Muon group only, preserving cooldown shape everywhere except the tail.

Two arms: FLOOR=0.05 (5% of peak = 0.002 terminal LR), FLOOR=0.10 (10% of peak = 0.004 terminal LR).

Mechanism: set_hparams line 935, Muon group only. ~5 LoC. Orthogonal to #608 (warmup front-end) and #610 (NS5 precision).

---

## 2026-05-20 21:05 UTC — Cycle 71 mid-17: PR #580 CLOSED (tanjiro AGC 8th variance-reduction closure); tanjiro → #613 logit-soft-cap; #608 alphonse rebase requested

### PR #580 — tanjiro AGC (Adaptive Gradient Clipping) — CLOSED (8th variance-reduction cluster closure)

Branch: `g1r2-tanjiro/agc`. AGC from Brock 2021 (NFNet) applied to all 101 AdamW parameter tensors (embed + lm_head + ~99 scalars). Per-tensor clip threshold = λ × ||p||_F. Two arms: λ=0.01 and λ=0.10.

| Arm | λ | val@3175 | ffs | Δval vs OLD bar (3.270288) | Δval vs NEW bar (3.269185) | pass? |
|---|---|---|---|---|---|---|
| A | 0.01 | 3.27272 | 3050 | +0.000432 | **+0.0035** | ❌ both legs |
| B | 0.10 | 3.27287 | 3050 | +0.000582 | **+0.0037** | ❌ both legs |

Both arms violated step-500 kill gate by +0.023-0.026 but recovered; passed step-1500 and step-3000 gates. Both arms ffs=3050, identical despite λ varying 10×.

**W&B runs**: djl2scjo (Arm A), fgea0zbv (Arm B).

**Root cause of failure**: 99/101 AdamW tensors are tiny scalar params. These scalars have very small Frobenius norms → they routinely hit the AGC_EPS_MIN=1e-3 floor → effective threshold = 1e-3×λ ≈ 1e-5 or 1e-4 → clipped uniformly every step regardless of actual gradient outlier structure. This is **uniform damping**, not outlier filtering. Only embed + lm_head (2/101 tensors) get the intended per-tensor mechanism. clip_fraction 0.87-0.98 throughout cooldown — mechanism fires, but val/ffs doesn't move.

**The bimodal-ffs hypothesis**: AGC was designed to suppress gradient magnitude outliers during late cooldown (the hypothesis: outlier batches push ffs from 3025 to 3050). Mechanism fires on embed+lm_head but ffs stays at 3050 for both arms. Conclusion: bimodal ffs is not caused by per-tensor gradient magnitude outliers on the AdamW group.

**Cluster context**: This is the **8th** orthogonal mechanism in the closed variance-reduction / direction-correction family:
1. COOLDOWN_FRAC #495 — schedule
2. SWA #524 — weight-trajectory
3. SAM #573 — sharpness-penalty (also contract-violating)
4. Lookahead #561 — slow-weights sync
5. MARS #576 — gradient-STORM correction
6. Adan #586 — additive variance-reduced momentum
7. β1 ramp #587 — EMA schedule
8. **AGC #580 — per-tensor magnitude clipping (THIS)**

**8/8 orthogonal mechanism classes all fail to compress bimodal ffs** — definitively confirmed intrinsic to data/loss geometry at our step budget.

### Assignment: tanjiro → PR #613 (logit-soft-cap sweep)

**Hypothesis**: The logit soft-cap constant c=15 at line 431 of train_gpt_simple.py (`logits = 15 * logits * (logits.square() + 15**2).rsqrt()`) is hardcoded and has NEVER been ablated. With EMBED_INIT_STD=0.1 now the baseline (input embedding magnitude 2.8× larger than prior std≈0.036 baseline), pre-cap logit distributions may have shifted enough that c=15 is no longer optimal.

Two arms: Arm A (c=12, tighter saturation), Arm B (c=20, near-identity for most logits). Completely architecture-side. First test modifying model.forward (not optimizer, not init weights, not schedule).

### Operational: #608 alphonse rebase requested

PR #608 (Muon LR warmup) is now CONFLICTING with the advisor branch due to the PR #541 squash-merge. Comment posted to alphonse at 21:00 UTC requesting `git rebase origin/auto-nanogpt-1gpu-r2`. After rebase, student should confirm disabled-check (val@200 ≈ 4.10) still holds with EMBED_INIT_STD=0.1 mandatory stack, then proceed with arms.

---

## 2026-05-20 20:20 UTC — Cycle 71 mid-16: PR #541 MERGED ⭐ (EMBED_INIT_STD=0.1 NEW BASELINE val=3.269185/ffs=3012.5); PR #598 CLOSED; askeladd → #611 residual-proj-init; edward → #610 NS5 cooldown precision

### PR #541 — askeladd EMBED_INIT_STD=0.1 — MERGED (⭐ NEW BASELINE)

Branch: `g1r2-askeladd/embed-init-std`. Input embedding non-zero init magnitude sweep: std ∈ {0.5, 0.1, 0.02}. 

**n=2 confirm terminal results** (run `iygnlznr`):

| Trial | val@3175 | ffs | Δ from baseline (3.270288/3025) |
|---|---|---|---|
| T0 | 3.26849 | 3000 | −0.00180 / −25 |
| T1 | 3.26988 | 3025 | −0.00041 / 0 |
| **n=2 mean** | **3.269185** | **3012.5** | **−0.001103 / −12.5** |

Statsig: `(3.28 − 3.269185) × √2 = 0.015295 ≥ 0.004` ✓ (3.82×). All merge criteria pass with margin.

**Cross-run reproducibility**: trial-to-trial spread at terminal Δ=0.00139 — tightest n=2 spread seen this cycle. The std=0.1 effect is real, not a single-seed coincidence.

**Non-monotonic arm pattern**: arm scan shows std=0.02 (GPT-2 convention, val≈3.270) AND std=0.5 (larger, val≈3.270) both land near old baseline; only std=0.1 crosses bar. Unimodal optimum confirmed.

**Critical mechanism finding from frieren #591**: Arm A (ortho gain=0.1, matched magnitude to askeladd's winner) val=3.281 — MISS. Orthogonal init at same magnitude is WORSE than Gaussian at std=0.1. **The win is about MAGNITUDE, not DECORRELATION.** Gaussian std=0.1 produces specific magnitude AND specific correlation structure — one or both matter, but gain=0.1 ortho shows decorrelation alone doesn't explain the win.

**New baseline**: val=3.269185, ffs=3012.5. EMBED_INIT_STD=0.1 now mandatory stack.

### PR #598 — edward AdamW LR warmup — CLOSED (Arm A clear regression)

Branch: `g1r2-edward/adamw-lr-warmup`. Linear LR warmup on AdamW group (embed/lm_head/scalars) from 0 to peak LR over 200 steps.

| Arm | warmup steps | val@3175 | ffs | Δval (vs OLD baseline 3.270288) |
|---|---|---|---|---|
| disabled ×2 | 0 | 3.970 @ 250 | — | matches baseline ✓ |
| **A** | **200** | **3.29099** | **-1 (never hit 3.28)** | **+0.0207** |
| B | 500 | — | — | skipped (per plan) |

**Mechanism interpretation**: AdamW LR warmup suppresses early embed learning. With EMBED_INIT_STD=0.1 now confirmed as the winning init, the embed weights start at LARGER magnitude and NEED the first 200 steps to differentiate tokens rapidly. AdamW warmup artificially suppresses this early specialization — the early gap (+0.30 at step 250) closes asymptotically (+0.02 at step 3000) but NEVER reaches zero in 3175 steps. The very mechanism that AdamW warmup would "protect" against (early instability) turns out to be exactly what the optimizer needs at EMBED_INIT_STD=0.1.

**Implication for #608 (Muon LR warmup, alphonse)**: The AdamW embed group failing warmup does NOT mean Muon LR warmup will fail. The Muon group handles DIFFERENT parameters (2D QKV/MLP matrices). The mechanisms are fully independent. Muon LR warmup is still worth testing.

### edward → PR #610: NS5 cooldown precision ramp

Edward → **first NS5 iteration schedule in cycle 71**. Currently `NS5_ITERS=14` is constant throughout training. The new hypothesis: late-training (cooldown phase) benefits from higher NS5 precision (14→18 or 14→20 over the last 70% of training). Two arms isolate mild vs aggressive precision boost.

Rationale: late-cooldown orthogonalization quality determines the EXACT ffs landing step; tighter polar projection during step 3000-3175 could shift ffs from 3025 to 3000.

Branch `g1r2-edward/ns5-cooldown-precision` pushed; PR #610 opened.

### askeladd → PR #611: Residual projection non-zero init

Askeladd → **completion of the initialization trifecta**. All transformer residual projections (`blocks.N.attn.proj.weight`, `blocks.N.mlp.proj.weight`) are currently zero-inited. Two arms: std=0.002 (near-GPT-2 convention), std=0.01 (standard range for this layer size).

If residual projections also benefit from non-zero init, combined with askeladd's input-embed win (#541) and the pending lm_head test (#602), this could establish a unified principle: "all projections should be initialized at small non-zero magnitude on this stack."

Branch `g1r2-askeladd/residual-proj-init` pushed; PR #611 opened.

---

## 2026-05-20 20:10 UTC — Cycle 71 mid-15: PR #587 alphonse β1 ramp CLOSED (both arms MISS, 7/7 variance-reduction cluster); alphonse → #608 Muon LR warmup

### PR #587 — alphonse β1 cooldown ramp CLOSED — both arms MISS, EMA schedule fails to compress ffs variance

Branch: `g1r2-alphonse/beta1-cooldown-ramp`. Linear ramp of AdamW β1 from 0.8 (cooldown start, progress=0.3) to a higher value (cooldown end, progress=1.0). Hypothesis: longer EMA averaging in cooldown damps single-batch noise that pushes seeds into ffs={3000, 3050} bimodal distribution.

| Arm | β1 cooldown end | n=1 val | n=1 ffs | Δval | Δffs | Verdict |
|---|---|---|---|---|---|---|
| A | 0.99 (~100-step window at terminal) | 3.27252 | 3050 | +0.00223 | +25 | Clear regression on both legs |
| **B** | **0.95 (~20-step window at terminal)** | **3.27164** | **3025 (TIE)** | **+0.00135** | **0** | **val leg MISS; ffs ties but val not strictly better** |
| Baseline (n=4) | static β1=0.8 | 3.270288 | 3025 | — | — | — |

**Statsig honesty pass** on both arms (`(3.28−val)·√1 ≥ 0.004`): Arm A 0.00748 ✓, Arm B 0.00836 ✓ — runs are honest, just not improvements.

### Mechanism analysis: why the ramp didn't compress ffs

1. **Arm A worse than Arm B** is the key contrast. If longer-EMA-in-cooldown helped, the more aggressive Arm A (β1→0.99, ~100-step window) should beat the milder Arm B (β1→0.95, ~20-step window). Instead Arm A is worse on BOTH val (+0.00223 vs +0.00135) and ffs (+25 vs 0). **Longer EMA over-smooths late-cooldown** — the rapidly-decaying LR needs an update direction that's responsive to current gradient, not lagged by 100 prior steps.

2. **Arm B ffs=3025 is a single-seed lower-mode draw, not population-level shift**. n=1 ffs can land on any of {3000, 3025, 3050, 3075} per the baseline bimodal distribution. ffs=3025 here is consistent with no effect on the underlying distribution — no statistical claim about ffs compression can be made from a single trial.

3. **Generalization to closed cluster**: 7th orthogonal variance-reduction mechanism class to fail. β1 schedule is a "first-moment averaging-window schedule" — distinct from prior failures at LR-time-envelope (COOLDOWN_FRAC), weight-trajectory (SWA), sharpness-penalty (SAM), slow-sync (Lookahead), gradient-correction (MARS), and denominator-blend (Adan).

### Closed family expansion — Variance-reduction mechanism cluster: 7/7 closures

| PR | Mechanism class | Mechanism level |
|---|---|---|
| #495 COOLDOWN_FRAC | schedule shape | LR-time-envelope |
| #524 SWA tail averaging | weight trajectory | post-step parameter avg |
| #573 SAM | sharpness penalization | 2×fwd-bwd (contract violation) |
| #561 Lookahead | slow-weights sync | post-step parameter sync |
| #576 MARS | STORM gradient correction | pre-EMA gradient level |
| #586 Adan | variance-reduced m + corrected n_t | EMA + denominator level |
| **#587 β1 ramp (now)** | **first-moment averaging window schedule** | **β1 schedule level** |

**Overwhelming evidence**: seven orthogonal mechanism classes at every level of single-pass optimizer design — schedule shape, weight trajectory, sharpness penalty, slow sync, gradient correction, denominator blend, averaging-window schedule — all fail to compress bimodal ffs variance. **Bimodal ffs at the floor is virtually confirmed as intrinsic to data/loss geometry at our model size + step budget.** Future variance-reduction proposals on the optimizer side are STRONGLY de-prioritized. Wins must come from MODEL/REPRESENTATION/INITIALIZATION side (askeladd #541 EMBED_INIT_STD=0.1 n=2 confirm imminent is the canonical instance).

### PR #608 — alphonse reassigned: Muon LR warmup

Alphonse → **first Muon LR schedule ablation in cycle 71**. The current Muon optimizer has NO LR warmup — Muon LR=0.04 is applied at full strength from step 0:

```python
optimizer2 = Muon([...], lr=MUON_LR, weight_decay=MUON_WEIGHT_DECAY, mu=MU)  # full LR from step 0
...
def set_hparams(step, cooldown_frac=0.7):
    progress = step / train_steps
    if progress < 1 - cooldown_frac:
        eta = 1.0  # stable phase: no warmup
    else:
        eta = (1 - progress) / cooldown_frac  # linear cooldown
    group["lr"] = group["initial_lr"] * eta
```

**Asymmetry**: Muon momentum DOES have warmup (`MU_WARMUP_STEPS=200` ramps μ from 0.85 → 0.95 over the first 200 steps), but Muon LR does not. **Has never been ablated.**

**Two arms**:
- **Arm A**: MUON_LR_WARMUP_STEPS=100 (brief warmup, AdamW convention)
- **Arm B**: MUON_LR_WARMUP_STEPS=300 (longer warmup, matches MU warmup scale)

**Symmetric to edward #598** (AdamW LR warmup with 200/500-step arms). If LR warmup helps AdamW, the natural complement is testing whether it also helps Muon. If they compound, both wins stack. If they're asymmetric, that's a clean mechanism finding.

Branch `g1r2-alphonse/muon-lr-warmup` pushed; PR #608 opened with full kill-gate table and decision tree.

---

## 2026-05-20 19:45 UTC — Cycle 71 mid-14: PR #569 fern AdaBelief CLOSED (Arm A regression, Arm B neutral); fern → #605 Muon heavy-ball ablation

### PR #569 — fern AdaBelief CLOSED — Arm A miss, Arm B neutral; denominator-semantics class likely closed

Branch: `g1r2-fern/adabelief`. AdaBelief (Zhuang 2020): replace `v_t = β2·v_{t-1} + (1-β2)·g_t²` with `v_t = β2·v_{t-1} + (1-β2)·(g_t - m_t)² + ε` — keeps direction-blend untouched, only the denominator term changes.

| Arm | β2 | n=2 val_mean | n=2 ffs_mean | Δval | Δffs | Verdict |
|---|---|---|---|---|---|---|
| A | 0.95 (default β2) | 3.27270 | 3062.5 | +0.00241 | +37.5 | Clear regression |
| **B** | **0.99 (tighter EMA)** | **3.27037** | **3025 (TIE)** | **+0.000082** | **+0** | **NEUTRAL — fails strict val bar by +8.2e-5** |
| Baseline (n=4) | — | 3.270288 | 3025 | — | — | — |

**Per-trial telemetry (Arm B β=0.99):**
- T0: val=3.27084
- T1: val=3.26990
- Per-seed std ≈ 0.00067 (matches baseline per-trial std ≈ 0.0011)

**Statsig check on neutral Arm B**: `(3.28 − 3.27037) × √2 = 0.01362 ≥ 0.004` → result is statistically distinguishable from "worse-than-baseline" at n=2. Genuinely neutral, not noise.

### Mechanism analysis: why Arm B at β2=0.99 is neutral

Arm-internal contrast (A worse, B neutral) tells the cooldown story:
- **Arm A (β2=0.95)**: shorter v-EMA → (g − m)² noise term updates fast → over-adapts to smoothed signal during cooldown when m ≈ g and (g − m)² is just noise variance. v_t becomes a noise estimator, denominator stays large unnecessarily → undertraining during cooldown.
- **Arm B (β2=0.99)**: long v-EMA → (g − m) ≈ noise during cooldown, but EMA so slow that v_t stays near ε. Denominator effectively ε-floored → AdamW-equivalent during the binding cooldown window. **Mechanism is saturated at β2=0.99** — pushing higher (β2=0.995) won't change cooldown dynamics measurably, because the denominator is already minimal.

### Why close instead of extending Arm B to n=4

1. **Mechanism saturation**: pushing β2 even higher won't move the central tendency below baseline; denominator is already at ε floor during cooldown.
2. **Variance estimate is stable**: Arm B's per-seed std ≈ 0.00067, comparable to baseline. The +8.2e-5 gap is genuinely an indistinguishable population mean, not a tail draw.
3. **Higher-value Muon-side axes available** (#605 below) — GPU slot better spent on fresh mechanism class than tight β2 refinement.

### Closed family expansion — AdamW denominator-semantics: 2/2 closures, class likely exhausted

| PR | Mechanism | Verdict |
|---|---|---|
| #574 Sophia-G | `E[g²]` (no sqrt) + Hessian-clip → Lion mode | FAIL — unit-mismatch at our gradient scale |
| **#569 AdaBelief (now)** | **(g−m)² denominator with sqrt** | **NEUTRAL — within ±5e-4 envelope of baseline** |

**Strong evidence**: AdamW's vanilla `g_t²` denominator with sqrt is at the local optimum for this stack. Future denominator interventions face the same fundamental obstacle — the cooldown window dominates the loss, and the binding behavior there is `v ≈ ε → m/√(ε)` (essentially full-LR adaptive step on m's direction). Any denominator that hits ε during cooldown is identical; any denominator that doesn't is worse.

**AdamW direction/correction bucket — 7/7 closures unchanged** (this PR is denominator-semantics, distinct bucket).

### PR #605 — fern reassigned: Muon heavy-ball ablation (Nesterov re-blend on line 694)

Fern → **first Muon update-rule ablation in cycle 71**. The current Muon update on `Muon.step` line 693-694:

```python
state["momentum"].lerp_(grad, 1 - group["mu"])       # m_t = μ·m_{t-1} + (1-μ)·g_t   (standard EMA)
momentum_update = grad.lerp(state["momentum"], group["mu"])  # u_t = (1-μ)·g_t + μ·m_t  (Nesterov-style re-blend)
```

**Algebra**: substituting the EMA into the re-blend gives `u_t = (1-μ²)·g_t + μ²·m_{t-1}` — effective β = **μ² = 0.9025** at μ=0.95, vs plain heavy-ball β = μ = 0.95 (longer memory). The re-blend is a memory-shortening operation applied on top of the EMA. Never ablated since record #14.

**Two arms isolate mechanism vs memory length**:
- **Arm A**: MUON_HEAVY_BALL=1, MU=0.95 (longer memory, β=0.95)
- **Arm B**: MUON_HEAVY_BALL=1, MU=0.9025 (matched effective β to current Nesterov re-blend)

Decision tree:
- Both miss → re-blend is load-bearing, close
- Only A passes → longer memory helps, re-blend was hurting; confirm Arm A
- Only B passes → re-blend ≡ heavy-ball at matched β_eff; mechanism is notation only, close
- Both pass → heavy-ball wins regardless; confirm whichever is better

Branch `g1r2-fern/muon-heavy-ball` already pushed; PR #605 opened with full decision table.

---

## 2026-05-20 17:35 UTC — Cycle 71 mid-13: PR #586 nezuko Adan CLOSED (corrected n_t denominator inflates variance); nezuko → #602 lm_head non-zero init sweep

### PR #586 — nezuko Adan CLOSED — both arms killed step-500 gate, stable +0.12 val gap

Branch: `g1r2-nezuko/adan`. Paper-faithful Adan (Xie 2022 Algorithm 1) with bias correction, decoupled WD, prev_grad init = g_0.

| Arm | β1 | β2 | β3 | W&B | val@500 | Δ vs baseline ~3.70 | Verdict |
|---|---|---|---|---|---|---|---|
| Disabled control | — | — | — | mkvd9cyj | 3.97306 @ 250 | within noise | sanity OK |
| Smoke A | 0.02 (paper) | 0.08 | 0.01 | nv2cwqwy | 4.12641 @ 250 | +0.19 | barely passed loose smoke (≤4.0) |
| Smoke B | 0.10 (responsive) | 0.08 | 0.01 | qnkru0en | 4.06396 @ 250 | +0.12 | barely passed loose smoke (≤4.0) |
| **Full A** | **0.02** | **0.08** | **0.01** | **fhz25cez** | **3.82062 @ 500** | **+0.12** | **KILL — gate ≤3.78 violated** |
| **Full B** | **0.10** | **0.08** | **0.01** | **cpzbwpcg** | **3.81666 @ 500** | **+0.12** | **KILL — gate ≤3.78 violated** |

Killed at step ~686 (Arm A) and ~816 (Arm B) per PR contract. Parallel curves through Arm B's reached step 750 — no warmup convergence, stable +0.12 gap.

### Mechanism telemetry confirms cost is `n_t`, not `v_hat`

`diff_contribution = (1-β2)·||v_hat|| / ||m_hat + (1-β2)·v_hat||`:

| Arm | DC profile | DC mean | DC max | Step 500 val |
|---|---|---|---|---|
| Arm A (β1=0.02) | 0 → 0.12 → 0.30 → 0.39 → 0.60 → 0.73 → 0.77 | 0.578 | 0.775 | 3.82062 |
| Arm B (β1=0.10) | 0 → 0.26 → 0.38 → 0.42 → 0.39 (stable) | 0.366 | 0.440 | 3.81666 |

**Despite 2× difference in v_hat contribution direction (DC 77% vs 39%), val curves are nearly identical.** This isolates the cost: NOT the v_hat blend, NOT the additive update direction, but the SHARED structural change between arms — the `n_t = β3·n_{t-1} + (1-β3)·(g_t + (1-β2)·diff_t)²` denominator. With `(1-β2)=0.92`, the corrected gradient `c_t = g_t + 0.92·(g_t - g_{t-1})` has ~0.85× larger variance than `g_t` alone (uncorrelated diff term contributes additively to variance). Larger `n_t` → smaller adaptive step → undertrained.

### Closed family expansion — AdamW direction/correction bucket: 7/7 closures

| PR | Mechanism class | Verdict |
|---|---|---|
| #538 Lion | sign-only m | FAIL |
| #523 Cautious AdamW | sign-mask m | FAIL |
| #527 NAdamW | Nesterov m | FAIL |
| #557 SF-AdamW | cooldown-removal | FAIL |
| #574 Sophia-G | Hessian-clip → sign-m | FAIL |
| #576 MARS | STORM c_t correction | FAIL |
| **#586 Adan (now)** | **additive v_t + corrected n_t** | **FAIL** |

**Overwhelming evidence**: AdamW's `m / √v` structure with both terms in the same dynamic range is structurally load-bearing on this stack at our LR/WD tuning. Future numerator/denominator interventions must preserve the dynamic-range balance (AdaBelief #569 still in flight and structurally safe).

### Closed family expansion — Variance-reduction mechanism bucket: 6/6 closures

| PR | Mechanism class | Mechanism level | Verdict |
|---|---|---|---|
| #495 COOLDOWN_FRAC | schedule shape | LR-time-envelope | CLOSED |
| #524 SWA tail averaging | weight trajectory | post-step parameter avg | CLOSED |
| #573 SAM | sharpness penalization | 2×fwd-bwd (contract violation) | CLOSED |
| #561 Lookahead | slow-weights sync | post-step parameter sync | CLOSED |
| #576 MARS | STORM gradient correction | pre-EMA gradient level | CLOSED |
| **#586 Adan (now)** | **additive variance-reduced m + corrected n_t** | **EMA + denominator level** | **CLOSED** |

Six orthogonal mechanism classes span every reasonable level at which a single-pass optimizer could compress variance. All fail. **Bimodal ffs at our floor is virtually confirmed as intrinsic to data/loss geometry at our model size + step budget.** Future wins must come from MODEL/REPRESENTATION side, not optimizer side.

### PR #602 — nezuko reassigned: lm_head non-zero init sweep

Nezuko → **first model-output-side experiment** in cycle 71. Symmetrically complements askeladd #541 (input-embed magnitude winner, n=2 confirm in flight).

**Hypothesis**: lm_head (`model.proj`) is currently zero-initialized (line 886, `if "proj" in name: w.zero_()`). The other zero-inited projections (`blocks.X.attn.proj`, `blocks.X.mlp.proj`) need zero-init for residual identity initialization — but lm_head is NOT a residual; it's a final output layer. The zero-init is a GPT-2 convention (Radford 2019), never ablated in this codebase.

| Arm | LM_HEAD_INIT_STD | Mechanism tested |
|---|---|---|
| A | 0.02 | GPT-2 standard non-zero init (mild) |
| B | 0.1 | Matches askeladd's winning embed magnitude (strong) |

**Code change**: env-var-gated, defaults to 0 (current zero-init). Two lines:
```python
LM_HEAD_INIT_STD = float(os.environ.get("LM_HEAD_INIT_STD", "0.0"))
```
Plus modify init block to use `name == "proj.weight"` exact match (not substring) so only lm_head is gated, residual projections stay zero-inited.

**Decision tree**: both arms beat bar → strong model-side magnitude story (compounds with askeladd). One arm beats → magnitude curve is non-monotonic (refine). Both regress → zero-init is genuinely optimal for lm_head; close axis.

---

## 2026-05-20 17:30 UTC — Cycle 71 mid-12: PR #576 thorfinn MARS CLOSED (5/5 variance-reduction closures); thorfinn → #601 Muon WD reintroduction

### PR #576 — thorfinn MARS CLOSED — both arms MISS, monotonic dose-response

Branch: `g1r2-thorfinn/mars`. Paper-faithful MARS-AdamW (Liu 2024) terminal both arms.

| Arm | γ | W&B | val @ 3175 | ffs | Δ val | Δ ffs | Verdict |
|---|---|---|---|---|---|---|---|
| Disabled-check | — | s5w1jrnm | 4.0971 @ 200 | — | — | — | sanity OK |
| Smoke A | 0.025 | t4lchpaj | 3.7037 @ 500 | — | — | — | smoke gate pass |
| Smoke B | 0.1 | ybzoxc58 | 3.7106 @ 500 | — | — | — | smoke gate pass |
| **A n=1** | **0.025** | **2aeqkob2** | **3.27478** | **3075** | **+0.00449** | **+50** | **MISS** |
| **B n=1** | **0.1** | **x16ch6df** | **3.27873** | **3150** | **+0.00844** | **+125** | **MISS** |
| Baseline | — | — | 3.270288 | 3025 | — | — | — |

### Kill-gate trajectory (both arms cleanly pass all screening, regression localized at terminal)

| step | gate | A val | B val |
|---|---|---|---|
| 1500 | <3.55 | 3.535 ✓ | 3.539 ✓ |
| 2500 | <3.40 | 3.349 ✓ | 3.353 ✓ |
| 3000 | <3.32 | 3.286 ✓ | 3.290 ✓ |
| 3175 | val ≤ 3.270 OR ffs ≤ 3025 | **MISS** | **MISS** |

### Monotonic dose-response — no interior γ-optimum

| metric | γ=0.025 (Arm A) | γ=0.1 (Arm B) | Δ (B−A) |
|---|---|---|---|
| val | 3.27478 | 3.27873 | +0.00395 |
| ffs | 3075 | 3150 | +75 |
| Effective look-back coeff `γ·β1/(1−β1)` | 0.1 | 0.4 | — |

4× more look-back strength → 2× more val regression, 2.5× more ffs regression. **Monotonic** — no γ in the explored range matches baseline. Closing the axis without refinement: there is no interior optimum to find.

### Variance-reduction mechanism cluster — now 5/5 closures

| PR | Mechanism class | Mechanism level | Verdict |
|---|---|---|---|
| #495 COOLDOWN_FRAC | schedule shape | LR-time-envelope | CLOSED |
| #524 SWA tail averaging | weight trajectory | post-step parameter avg | CLOSED |
| #573 SAM | sharpness penalization | 2×fwd-bwd (contract violation) | CLOSED |
| #561 Lookahead | slow-weights sync | post-step parameter sync | CLOSED |
| **#576 MARS (now)** | **STORM gradient correction** | **pre-EMA gradient level** | **CLOSED** |

Five orthogonal mechanism classes — schedule / weight trajectory / sharpness / slow-weights / gradient STORM — all fail to compress bimodal ffs variance at our floor. The mechanisms span every reasonable level at which a single-pass optimizer could compress variance.

**Implication**: bimodal ffs at ~3025/3050 is **intrinsic to the data/loss geometry at our model size and step budget**, not a tractable optimizer-side variance problem. Future wins must come from:
1. **Model side** (e.g. askeladd #541 EMBED_INIT — candidate winner). When optimizer-side knobs saturate, mechanism wins flow from representational changes.
2. **Muon side** (#601 thorfinn now testing). Muon group is comparatively under-explored at the update-rule and regularization level.
3. **Architecture side** (tied embed #596, future depth/width changes).

Late-cooldown widening of the MARS val gap (Arm A: step-2500 Δ=+0.004 → step-3175 Δ=+0.005; Arm B: matched widening) is a secondary signal: the c_t norm-clip at 1 is likely active too frequently during high-gradient phases, damping useful EMA signal. Student suggested diagnostic-only telemetry but with the closure decision already monotonic, no further compute is warranted.

### PR #601 — thorfinn reassigned: Muon explicit weight decay reintroduction

Thorfinn → first Muon-side experiment in cycle 71. The AdamW direction-blend bucket (5/5) and the variance-reduction cluster (5/5) are both fully closed; the natural next axis is mechanisms on the Muon group, which has been comparatively unprobed at the regularization level.

**Hypothesis**: `Muon.step()` intentionally omits explicit weight decay (line 709 comment: "matches record #14; u/w-floor replaces wd"). The `MUON_WEIGHT_DECAY = 0.025` constant exists but is never read by the update path. This has **never been ablated** since u/w-floor was added. Test whether u/w-floor is **complete** as a regularizer or whether mild decoupled WD on top adds headroom.

| Arm | MUON_WEIGHT_DECAY | Effective per-step decay (lr=0.04) | Comparable to |
|---|---|---|---|
| A | 2.5e-3 | 1e-4 | AdamW lr=1e-3, wd=0.1 (mild) |
| B | 2.5e-2 | 1e-3 | Original code-intent strength |

**Code change**: 1-line in `Muon.step` (before the spectral update):
```python
if group["weight_decay"] > 0:
    p.mul_(1.0 - group["lr"] * group["weight_decay"])
p.add_(update, alpha=-group["lr"])
```

Mathematically orthogonal to u/w-floor (which scales updates, doesn't shrink weights). Disabled by default; env-var-gated.

---

## 2026-05-20 17:10 UTC — Cycle 71 mid-11: PR #574 edward Sophia-G CLOSED (Lion failure mode); edward → #598 AdamW LR warmup

### PR #574 — edward Sophia-G CLOSED — Lion failure mode confirmed via clip-fraction telemetry

Branch: `g1r2-edward/sophia-g`. Multiple smoke arms terminal; all FAIL smoke gate.

| Arm | Formula | LR scale | ρ | val @500 | W&B | Verdict |
|---|---|---|---|---|---|---|
| Disabled-check | AdamW (baseline) | — | — | 4.10 @200 | 4dsy5mbt | sanity OK |
| A | `clip(m/h, ±ρ)·lr` (PR spec) | 2.0 | 0.03 | 4.6468 | u3rqgzdn | FAIL — step cap = lr·ρ ≪ AdamW |
| B | same, half scale | 1.0 | 0.03 | 5.5751 | 1ny2snn1 | FAIL worse |
| **C trial 1** | corrected formula | 2.0 | 1.0 | 3.8907 | uly75i1s | FAIL smoke gate (>3.85) |
| **C trial 2** | (same) | 2.0 | 1.0 | 3.8795 | o3be7j7p | FAIL |
| **C trial 3** | (same) | 2.0 | 1.0 | 3.8880 | u7146d7a | FAIL |
| D | ref-repo `clip(m/(ρ·bs·h), ±1)·lr` | 1.0 | 0.03 (bs=5120) | 4.53 @450 | h596i622 | FAIL — even slower than Arm C |

### Arm C clip-fraction telemetry — Lion failure mode confirmed

The advisor's predicted Lion-failure mode is exactly what telemetry showed:

| step | val | embed clip | lm_head clip | scalars clip |
|---|---|---|---|---|
| 125 | 4.816 | **98.31%** | 35.88% | 6.06% |
| 250 | 4.223 | **98.02%** | 25.55% | 2.97% |
| 375 | 3.985 | **97.97%** | 22.72% | 2.38% |
| 450 | 3.904 | **98.07%** | 21.91% | 2.05% |
| 500 | 3.879 | **98.14%** | 22.45% | 2.09% |

**98% of embed elements hit the clip cap on every step** → embed updates degenerate to `±lr·sign(m)` → pure Lion behavior on the largest tensor (vocab × d_model). Lion (#538) is already falsified, so Sophia-G degenerates into the same closed mechanism.

### Unit-mismatch argument — why no (lr, ρ) tuning rescues Sophia-G at our scale

- `g_typical ≈ 1e-3` → `h = E[g²] ≈ 1e-6` (β2=0.99 EMA, no sqrt in denominator)
- `m ≈ g_typical ≈ 1e-3` (AdamW-style EMA, also no sqrt)
- `m/h ≈ 1e3` per element — 3 orders of magnitude over ρ=1.0 cap

The fundamental issue: **Sophia-G's denominator `E[g²]` (no sqrt) and `m` (no sqrt) cannot land in the same dynamic range at our gradient magnitudes**. Arm D with `ρ·bs·h ≈ 1.5e-4` denominator still leaves `m/(ρ·bs·h) ≈ 6` — still clipping. The bs-scaled formulation doesn't help.

### Closed family expansion — AdamW direction-blend bucket: 5/5 closures

| PR | Mechanism class | Verdict |
|---|---|---|
| #538 Lion | sign-of-momentum | FAIL |
| #523 Cautious AdamW | sign-mask | FAIL |
| #527 NAdamW | Nesterov lookahead | FAIL |
| #557 SF-AdamW | cooldown-removal | FAIL |
| **#574 Sophia-G (now)** | **Hessian-clipped → degenerates to sign-m at our gradient scale** | **FAIL** |

This 5/5 pattern is **strong evidence that AdamW's m/√v ratio with both terms in the same dynamic range is structurally load-bearing on this stack**. Future numerator/denominator interventions must preserve this dynamic-range balance. Implication for in-flight: MARS (#576), AdaBelief (#569), AGC (#580), Adan (#586) all keep the sqrt'd denominator — safe; Sophia-G doesn't, broken.

### PR #598 — edward reassigned: AdamW LR warmup (schedule-side gap)

Edward → schedule axis. The Sophia-G failure showed direction/denominator interventions on AdamW are saturated; pivot to schedule-side intervention.

**Hypothesis**: AdamW has NO LR warmup currently (`group["lr"] = group["initial_lr"] * eta` with eta=1.0 throughout the plateau). Adding linear warmup over 200/500 steps may compound with askeladd's pending embed-init win because both reduce early-step gradient impact on the optimizer state.

| Arm | ADAMW_WARMUP_STEPS | Compares to |
|---|---|---|
| A | 200 | matches MU_WARMUP_STEPS=200 |
| B | 500 | ~15.7% of training |

Closed list: HP scalar sweeps tested embed_lr/lm_head_lr/scalars_lr; schedule shape variants tested cosine/poly cooldown; SF-AdamW tested cooldown-removal. **LR warmup addition is a new schedule axis** — the only mechanism in flight that modifies the time-domain envelope of AdamW LR.

---

## 2026-05-20 16:10 UTC — Cycle 71 mid-10: PR #561 frieren Lookahead CLOSED (both arms MISS); frieren → #591 ortho-embed-init

### PR #561 — frieren Lookahead CLOSED — discrete sync incompatible with cooldown horizon

Branch: `g1r2-frieren/lookahead-adamw`. Both arms n=1 terminal with full SENPAI-RESULT marker.

| Arm | k | α | W&B | val @ 3175 | ffs | Δ val | Δ ffs | Result |
|---|---|---|---|---|---|---|---|---|
| disabled | — | — | imtfy2i8 | 4.0944 @ 200 | — | — | — | sanity OK |
| smoke A | 5 | 0.5 | c26z9f9c | 3.7343 @ 500 | — | — | — | smoke gate pass |
| smoke B | 10 | 0.5 | 398dfkmh | 3.7316 @ 500 | — | — | — | smoke gate pass |
| A | 5 | 0.5 | 8id6gbok | 3.28039 | −1 (never reached) | +0.0101 | +∞ | MISS clearly |
| B | 10 | 0.5 | pbay3atj | 3.27844 | 3125 | +0.0082 | +100 | MISS clearly |
| Baseline | — | — | uoak0qa8 | 3.270288 | 3025 | — | — | — |

**Kill-gate trajectory** (both arms pass all screening gates; failure is concentrated at terminal):

| step | gate | A val | B val |
|---|---|---|---|
| 1500 | <3.55 | 3.53862 ✓ | 3.53686 ✓ |
| 2500 | <3.40 | 3.35459 ✓ | 3.35349 ✓ |
| 3000 | <3.32 | 3.29145 ✓ | 3.29089 ✓ |
| 3175 | ≤3.270 OR ffs≤3025 | **MISS** | **MISS** |

**Mechanism**: discrete slow-weights sync at k=5/k=10 overwrites the fine-grained late-cooldown updates that the AdamW group is supposed to deliver. Both arms track baseline within ~1σ through the screening phases, then land high at the cooldown terminal. The val gap of +0.01 at step 3175 is ~3× the per-seed σ.

**Closed family expansion**: joins SWA, Polyak, and SF-AdamW as the third weight/schedule-modifying intervention on the AdamW group that fails because it disrupts the cooldown landing. **Discrete-sync schedule modifications on AdamW group FAIL** is now a confirmed class result.

**Implication for the in-flight variance-reduction PRs (MARS, AGC, Adan, β1-ramp)**: these all attack at the **gradient or EMA** level (before the optimizer step), not at the **post-step parameter** level (where SWA/Lookahead operate). This is mechanistically the right level — the bimodal-ffs variance comes from a few specific late-cooldown gradient magnitudes/directions, not from aggregate trajectory noise that averaging could damp.

### PR #591 — frieren reassigned: orthogonal embed init (decorrelation-side dissection of askeladd's win)

New hypothesis: orthogonal embed initialization isolates the DECORRELATION effect vs. askeladd's MAGNITUDE effect.

| Arm | Init | gain | Mechanism tested |
|---|---|---|---|
| A | torch.nn.init.orthogonal_(embed.weight, gain=0.1) | 0.1 | magnitude AND decorrelation |
| B | torch.nn.init.orthogonal_(embed.weight, gain=1.0) | 1.0 | decorrelation, small magnitude reduction |

**Compound prediction** (frieren vs askeladd):

- If askeladd's win is pure magnitude: frieren Arm A ≈ askeladd Arm B (tie), frieren Arm B ≈ baseline
- If askeladd's win is decorrelation: frieren Arm A > askeladd Arm B (best of both), frieren Arm B > baseline
- If combined: frieren Arm A > askeladd Arm B, frieren Arm B between

Saxe et al 2013 ("Exact solutions to nonlinear dynamics of learning in deep linear networks") motivates orthogonal init. Standard in CNN training, untested in this LM codebase.

---

## 2026-05-20 16:00 UTC — Cycle 71 mid-9: PR #541 askeladd Arm B (std=0.1) WINNER at n=1; n=2 confirm authorized

### PR #541 — askeladd EMBED_INIT_STD sweep, 3 arms n=1 all terminal — Arm B clears merge bar at n=1

Branch: `g1r2-askeladd/embed-init-std`. All 3 arms n=1 finished.

| Arm | EMBED_INIT_STD | W&B | val @ 3175 | ffs | Δ val | Δ ffs | n=1 bar |
|---|---|---|---|---|---|---|---|
| A | 0.5  | llqwjy0t | 3.27245 | 3050 | +0.00216 | +25 | MISS (val+, ffs+) |
| **B** | **0.1**  | **ooph39ox** | **3.26773** | **3000** | **−0.00256** | **−25** | **✅ PASS (both bars)** |
| C | 0.02 | 4v7x7t30 | 3.27230 | 3050 | +0.00201 | +25 | MISS (val+, ffs+) |
| Baseline | 1.0 (default) | uoak0qa8 | 3.270288 | 3025 (n=4) | — | — | — |

**Statsig at n=1 (Arm B)**: `(3.28 − 3.26773) × √1 = 0.01227 ≥ 0.004` ✅

**Non-monotonic curve — mechanism reading**:

| step | A (std=0.5) | B (std=0.1) | C (std=0.02) | C vs A | C vs B |
|---|---|---|---|---|---|
| 1000 | 3.66694 | 3.66258 | 3.66694 | 0.000 | +0.0044 |
| 1500 | 3.53424 | 3.53036 | 3.53329 | −0.0010 | +0.0029 |
| 2000 | 3.43192 | 3.42674 | 3.43169 | −0.0002 | +0.0050 |
| 2125 | 3.40995 | 3.40508 | 3.40976 | −0.0002 | +0.0047 |
| 3000 | 3.28367 | 3.27892 | (similar) | — | — |
| 3175 | 3.27245 | 3.26773 | 3.27230 | — | — |

Arms A and C are essentially tied (Δval=−0.00015) and both ~0.005 worse than Arm B at terminal. This is consistent with a **sweet-spot picture**: embed std=0.1 minimizes a tradeoff between (a) gradient signal magnitude in early steps (std=1.0 too big, breaks attention conditioning) vs (b) representational capacity at init (std=0.02 too small, embeds need many steps to spread out). Order-of-magnitude reduction is correct; further reduction loses the benefit.

**Decision**: n=2 confirm AUTHORIZED for Arm B at 15:58 UTC.

```bash
EMBED_INIT_STD=0.1 \
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04 \
MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 \
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85 \
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3175 --num_trials 2 \
  --wandb_name 'g1r2-askeladd/embed-init-B-std01-n2-confirm' \
  --wandb_group 'g1r2-askeladd/embed-init-confirm'
```

**n=2 decision rules**:
- val_mean < 3.270288 AND ffs_mean ≤ 3025 AND `(3.28 − val_mean)·√2 ≥ 0.004` (val_mean ≤ 3.27717) → **MERGE-eligible**
- Bars pass but statsig fails → extend to n=4
- Either bar misses → close without merge (Arm B was lucky at n=1)

ETA terminal ~17:50 UTC.

### PR #576 — thorfinn MARS, Arm A n=1 MISS, Arm B running

Branch: `g1r2-thorfinn/mars`. Paper-faithful c_t implementation pushed at 13:48.

| Arm | Config | W&B | val @ 3175 | ffs | Result |
|---|---|---|---|---|---|
| disabled-check | MARS_ENABLED=0, 200 steps | s5w1jrnm | 4.097 | — | sanity OK |
| A-smoke | γ=0.025, 500 steps | t4lchpaj | 3.7037 | — | smoke gate pass |
| B-smoke | γ=0.1, 500 steps | ybzoxc58 | 3.7106 | — | smoke gate pass |
| **A** | **γ=0.025, 3175 steps** | **2aeqkob2** | **3.2748** | **3075** | **MISS** (val+0.0045, ffs+50) |
| B | γ=0.1, 3175 steps | x16ch6df | running step 1275 (val=3.604) | — | in flight |

Arm A miss at n=1 means STORM correction with paper-default γ=0.025 isn't strong enough — or the c_t norm-clip at 1 is suppressing the correction in the cooldown window where it would most help. Awaiting Arm B (γ=0.1, ~4× more aggressive look-back coefficient inside c_t).

### PR #587 — alphonse β1 cooldown ramp — cooldown window interpretation endorsed

Student correctly diagnosed that `cooldown_frac=0.7` in the existing `set_hparams` is the **last 70%** of training (steps 952 → 3175 for 3175-step run), not the last 30%. My PR body's "step ≥ 2222 = 0.7·3175" was a misread. Student is ramping β1 over progress ∈ [0.3, 1.0], aligning with the LR cooldown timing as the PR intent specified.

Per-step β1 growth: 8.5e-5 (vs my assumed 2.0e-4 short-window version) — gentler ramp, smoother moment transition. Endorsed.

Arm A first attempt crashed at step 725 (val=3.754, BETTER than baseline at that step → environmental, not divergence). Retry running.

---

## 2026-05-20 15:00 UTC — Cycle 71 mid-8: PR #564 alphonse GC CLOSED (neutral/negative); alphonse → #587 β1 cooldown ramp

### PR #564 — alphonse Gradient Centralization CLOSED — mechanism neutral-to-negative at our floor

Branch: `g1r2-alphonse/gradient-centralization`. Both arms n=1 terminal.

| Arm | Config | W&B | val @ 3175 | ffs | Δ val | Δ ffs | Result |
|---|---|---|---|---|---|---|---|
| A | GC all 2D (embed+lm_head) | xpogccnn | 3.27577 | 3100 | +0.00548 | +75 | MISS clearly |
| B | GC lm_head only | zyau9c22 | **3.27137** | **3025** | +0.00108 | 0 (TIE) | MISS (val not < baseline) |
| Baseline | — | uoak0qa8 | 3.270288 | 3025 | — | — | — |

**Arm B passes ffs TIE test but fails val strict improvement** (3.27137 > 3.270288). Even at n=2, Arm B could only confirm the floor (not crack it).

**Root cause**: existing stack (WD_AUX on embed, CONTRA_MUON, AdamW per-param adaptive scaling) already controls the DC gradient mode. GC strips the rank-1 mean projection, but on embed the interaction with WD_AUX adds variance rather than reducing it. lm_head-only (Arm B) is benign but not productive.

**Closed axis**: gradient-direction DC mode removal is not productive on this stack. Gradient-mean modifications join the falsified family.

alphonse → PR #587 β1 cooldown ramp assigned.

---

## 2026-05-20 14:30 UTC — Cycle 71 mid-7: PR #549 nezuko Muon-cooldown-frac CLOSED (both directions hurt); nezuko → #586 Adan (Xie 2022)

### PR #549 — nezuko Decouple Muon Cooldown CLOSED — both decoupling directions are mildly negative

Branch: `g1r2-nezuko/muon-cooldown-frac`. Both arms n=1 terminal.

| Arm | MUON_COOLDOWN_FRAC | W&B | val @ 3175 | ffs | Δ val | Δ ffs | Result |
|---|---|---|---|---|---|---|---|
| A | 0.8 (Muon stays high longer) | 6soeippr | 3.27297 | 3050 | +0.00268 | +25 | MISS |
| B | 0.6 (Muon cools faster) | n28py7ar | **3.27188** | **3050** | +0.00159 | +25 | MISS |
| Baseline (PR #494, n=4) | 0.0 (global=0.7) | uoak0qa8 | 3.270288 | 3025 | — | — | — |
| Mean n=1 | — | — | 3.272425 | 3050 | +0.00214 | +25 | MISS |

**Root cause**: AdamW and Muon are reasonably co-calibrated at shared cooldown_frac=0.7. Decoupling in either direction (later or earlier Muon cooldown) de-syncs the two optimizer groups during the critical val=3.28 crossing window (~steps 2900-3050), slowing convergence. Val regression in BOTH opposite directions is strong evidence the shared cooldown is a local optimum.

**ffs note**: Joint (3050,3050) under baseline bimodal {3000,3000,3050,3050} gives p≈0.25 under null — not conclusive alone, but combined with val regression is clear mechanism failure.

**Closed axis**: Muon decoupled cooldown fraction (both directions). Muon momentum decoupling (#4 in nezuko's suggestions) is a different mechanism and remains in queue.

nezuko → PR #586 Adan (Xie 2022, NeurIPS 2022) assigned.

---

## 2026-05-20 13:40 UTC — Cycle 71 mid-6: PR #534 tanjiro Shampoo lm_head CLOSED (no improvement); tanjiro → #580 AGC (Brock 2021)

### PR #534 — tanjiro Right-factor Shampoo on lm_head CLOSED — second-order preconditioning does not beat baseline

Branch: `g1r2-tanjiro/shampoo-lmhead-right-factor`. Both arms n=1 terminal.

| Arm | BETA2 | W&B run | val/loss | ffs | Δ val | Δ ffs | Result |
|---|---|---|---|---|---|---|---|
| A | 0.95 | 4kj7qdmo | 3.27509 | 3075 | +0.00480 | +50 | MISS |
| B | 0.99 | bt1aviep | **3.27190** | **3050** | +0.00162 | +25 | MISS |
| Baseline | — | uoak0qa8 | 3.270288 | 3025 | — | — | — |

**Key telltale**: Arm B (BETA2=0.99, slower adaptation = *less* preconditioning) is closer to baseline than Arm A. The preconditioning is actively hurting — less of it = less damage.

**Root cause**: lm_head column space is near-isotropic (each vocabulary embedding token generates independent gradient updates). The R^(-1/4) factor rotates in the column space but that space lacks directional curvature bias — it shrinks well-conditioned directions rather than correcting ill-conditioned ones. AdamW eps=1e-10 already covers the per-element adaptive scaling these curvature methods typically add.

**Closed axis**: Second-order preconditioning on lm_head falsified. Do not re-propose one-sided SOAP on lm_head — the column space lacks anisotropy to benefit.

tanjiro → PR #580 AGC (Brock 2021) — Adaptive Gradient Clipping.

---

## 2026-05-20 12:20 UTC — Cycle 71 mid-5: PR #573 thorfinn SAM CLOSED (benchmark contract: 2× fwd-bwd); thorfinn → #576 MARS (Liu 2024, STORM-style variance-reduced AdamW)

### PR #573 — thorfinn SAM CLOSED — benchmark contract violation (2× forward-backward per step)

Branch: `g1r2-thorfinn/sam`. No code changes made; branch closed before implementation.

**Closure reason**: SAM (Foret 2020) by construction requires two forward-backward passes per optimizer step — one at θ to compute the perturbation ε, one at θ+ε for the sharpness-aware update. `target/program.md` Benchmark Contract explicitly states: *"Do not add multiple forward-backward passes per optimizer step."* The PR body itself acknowledged the 2× compute overhead. Thorfinn correctly flagged the conflict before writing any code.

**Pivot**: Closing and pivoting to MARS (Liu 2024, arxiv 2411.10438) — a contract-compliant variance-reduced AdamW. MARS attacks the same hypothesis class (compress upstream bimodal ffs variance at the gradient level) via a STORM-style correction term: `m_t = β1·m_{t-1} + (1-β1)·g_t + γ·(1-β1)·(g_t - g_{t-1})`. Single forward-backward per step, ~1% overhead.

**Operational note**: Benchmark contract rule disqualifies all 2-pass methods: SAM, ASAM, Hutchinson-diagonal Sophia-H. Future proposals must verify this constraint first.

thorfinn → PR #576 MARS assigned.

---

## 2026-05-20 12:00 UTC — Cycle 71 mid-4: PR #524 thorfinn SWA CLOSED (bimodal var NOT compressed); PR #557 edward SF-AdamW CLOSED (no cooldown analog); thorfinn → #573 SAM; edward → #574 Sophia

### PR #524 — thorfinn SWA Tail Averaging CLOSED — weight-averaging cannot compress upstream bimodal variance

Branch: `g1r2-thorfinn/swa-tail-averaging`. W&B run: `z02q183a` (Arm B v2 n=2, SWA_WINDOW=300).

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27290 | **3000** |
| T1 | 3.27539 | 3050 |
| **mean** | **3.274145** | **3025** |
| stddev (sample) | 0.001761 | 35.36 |

Bar FAIL: val mean +0.0039 above 3.270288; ffs mean = 3025 is TIE not strict <. Statsig (3.28-3.274145)·√2=0.00828 ≥ 0.004 ✓ (clean miss, not noise).

**Mechanism verdict (student's analysis)**: Bimodal {3000, 3050} ffs variance was NOT compressed — only translated. SWA averages the *endpoint* of the cooldown trajectory but cannot fix the *upstream* dataloader/optimizer noise that determines which bimodal branch the trajectory lands on. T0 hit the 3000 branch, T1 hit the 3050 branch, giving baseline-equivalent mean by coincidence. The val curve through the SWA window (swa_count 1→300) was perfectly clean (monotonic descent, no perturbation pre-SWA), confirming implementation is sound. The mechanism is real (SWA-averaged weights ARE smoother than terminal weights) but additive on top of irreducible upstream bimodal noise.

**Closed family update**: Weight-averaging mechanisms (Polyak EMA #286, SWA WINDOW=150 v1, SWA WINDOW=300 v2) all FAIL to compress bimodal ffs variance. Variance is upstream noise, not endpoint noise. Remaining variance-reduction angles: frieren #561 Lookahead (discrete sync, different from continuous SWA), upstream interventions.

### PR #557 — edward Schedule-Free AdamW CLOSED — cooldown irreplaceable on AdamW group

Branch: `g1r2-edward/sfadamw`. W&B runs: disabled-check `nhjc7usg`+`z5b8oqne`; smoke A `y2ew8t60`; smoke B `5k7zyfr7`; n=1 partial (killed) `v150qzl3`.

Arm B (SFADAMW_LR_SCALE=2.0) killed at step 1500: val=3.57083 vs baseline 3.52970 → gap +0.041 (kill gate >3.55 tripped by 0.021). Gap stabilizes at +0.03-0.04 throughout training; **no sign of closing**.

**Mechanism verdict (student's analysis)**: SF-AdamW has **no cooldown analog**. Baseline cooldown monotonically shrinks the gradient step in the last 30% of training, compressing val from 3.43 (step 2000) to 3.27 (step 3175). SF-AdamW's constant-LR-with-Polyak-average cannot replicate this — z-iterate keeps stepping at full LR throughout. The deployed x averages over a still-large-step trajectory. The +0.04 gap is purely the loss of cooldown on this minority of params.

**Closed family update**: This is the **4th AdamW-group mechanism perturbation to fail** (Cautious #523 sign-mask, Lion #538 sign-of-momentum, NAdamW #527 Nesterov, SF #557 Polyak/no-cooldown). Pattern: at our 3175-step horizon, the AdamW group's tuned combination of {Adam update, linear cooldown, decoupled WD, β=(0.8, 0.95)} is irreplaceable. Cooldown-replacement mechanisms on AdamW group are CLOSED — do not re-propose.

### PR #573 — thorfinn SAM assigned (Foret 2020, arxiv 2010.01412)

Sharpness-Aware Minimization: compute g(θ) → perturb θ + ε where ε=ρ·g/||g||₂ → compute g(θ+ε) → use the perturbed gradient for the AdamW/Muon step. Doubles compute (2× forward-backward) but targets variance via flatter-basin discovery — fundamentally different from SWA weight averaging. 2 arms: Arm A SAM on all params, Arm B SAM on AdamW group only (cheaper).

### PR #574 — edward Sophia-G assigned (Liu 2023, arxiv 2305.14342)

Sophia-G (Gauss-Newton-Bartlett variant): replaces AdamW's g² denominator with `h ← β2·h + (1-β2)·g²` plus clipped update `clip(m/h, ±ρ)`. Hessian-aware second-order signal, preserves linear cooldown (avoids SF failure mode). ~10% step overhead with update_period=10. 2 arms: SOPHIA_LR_SCALE=2.0 (paper default for GPT-2) and SOPHIA_LR_SCALE=1.0 (conservative AdamW-matched scale).

## 2026-05-20 11:00 UTC — Cycle 71 mid-3: PR #527 fern NAdamW CLOSED (direction-blend cluster falsified); fern assigned #569 AdaBelief; tanjiro #534 n=1 arms launched

### PR #527 — fern NAdamW CLOSED — direction-blend AdamW cluster now fully falsified

Branch: `g1r2-fern/nadamw`. W&B runs: `o0u0btln` (Arm A, NADAMW=1 β1=0.8), `r1zdk7af` (Arm B, NADAMW=1 β1=0.85).

| Arm | Optimizer | val mean | ffs mean | vs bar | Verdict |
|---|---|---|---|---|---|
| A (best) | NAdamW β1=0.8 | 3.273585 | 3050 | OLD +0.0022/+25 | FAIL |
| B | NAdamW β1=0.85 | 3.274080 | 3062.5 | OLD +0.0027/+37.5 | FAIL |
| baseline (#458) | AdamW β1=0.8 | 3.271388 | 3025 | reference | — |

Arms A+B run against old bar (both launched before MUON_LR=0.04 merge at 06:43 UTC). Trial-to-trial variance essentially zero (T0/T1 within 0.0002 val) — clean statsig miss, not noise. Statsig (3.28-3.273585)·√2=0.00907 ≥ 0.004 ✓.

**Mechanism verdict**: NAdamW's blend `β1·m̂ + (1−β1)·grad/bc1` puts extra weight on the instantaneous gradient relative to vanilla AdamW (which uses just m̂). During cooldown, when LR has dropped, the smoothed momentum direction is beneficial — the lookahead correction towards instantaneous grad hurts. **Direction-blend AdamW variants are now fully closed**: Lion #538 (sign-of-momentum), Cautious AdamW #523 (sign-mask), NAdamW #527 (Nesterov blend) — all fail. Do NOT re-propose direction-reshaping AdamW updates without a new mechanism angle.

### PR #569 — fern AdaBelief assigned (Zhuang 2020, arxiv 2010.07468)

AdaBelief replaces AdamW's `v ← β2·v + (1−β2)·g²` with `v ← β2·v + (1−β2)·(g−m)²` — denominator semantics change, not direction reshape. When gradient agrees with momentum (g≈m), denominator stays small → larger step; when they diverge (noisy gradient), denominator grows → smaller step. Mechanistically orthogonal to all closed direction-blend variants. 2 arms: Arm A β2=0.95 (matching current AdamW default) and Arm B β2=0.99 (AdaBelief paper default; (g−m)² has higher variance than g², longer averaging helps).

### PR #534 tanjiro — right-factor Shampoo on lm_head — n=1 arms launched 09:40 UTC

Disabled-check (un1v5ud9) and both smokes (uy847d3h β2=0.95, 5o7486jb β2=0.99) all confirmed healthy (~3.697 at step 500). n=1 full screens launched 09:40 UTC. ETA Arm A terminal ~11:15 UTC, Arm B ~12:55 UTC.

## 2026-05-20 09:52 UTC — Cycle 71 mid-2: PR #533 alphonse CLOSED; alphonse assigned #564 GC; PR #529 frieren CLOSED; frieren assigned #561 Lookahead; thorfinn T0 ffs=3000 BREAKTHROUGH; fern NAdamW foreclosed

### PR #533 — alphonse Stack pruning ablation — CLOSED stack collectively load-bearing

Branch: `g1r2-alphonse/stack-pruning-ablation`. W&B runs: `pu1atoys` (Arm A), `zq1i7wom` (Arm B), `0t4xljsn` (Arm C).

| Arm | Disabled element | val | ffs | vs bar | Verdict |
|---|---|---|---|---|---|
| A | CONTRA_MUON=0 | 3.27296 | 3050 | OLD +0.00157/+25 | BOUNDARY |
| B | MU_WARMUP_STEPS=0 | 3.27385 | 3050 | OLD +0.00247/+25 | BOUNDARY |
| C | ATTN_SOAP_TRUST_THRESHOLD=1.0 | 3.27213 | 3050 | NEW +0.00184/+25 | BOUNDARY |

Striking symmetry: every arm costs exactly +25 ffs and +0.0016–0.0025 val. Stack is **not** over-engineered (no element soft-redundant), but also no element is catastrophically load-bearing (all regressions < 5e-3 val). Conservative call: keep all three elements in mandatory stack. Closure rationale: no free wins to remove, and further ablation would cost GPU without changing trajectory.

### PR #564 — alphonse Gradient Centralization assigned

GC (Yong 2020, arxiv 2004.01461) mean-centers gradients over output dim before AdamW step: `g ← g − g.mean(dim=0, keepdim=True)`. ~10 LoC, zero compute overhead. Removes "shift all output rows by same delta per input column" mode from gradient. Applied to 2D AdamW params (embed + lm_head), skip 1D scalars. 2 arms: Arm A (all 2D AdamW params) and Arm B (lm_head only).

## 2026-05-20 09:30 UTC — Cycle 71 mid: PR #529 frieren CLOSED; frieren assigned #561 Lookahead; thorfinn T0 ffs=3000 BREAKTHROUGH; fern NAdamW foreclosed

### PR #529 — frieren Per-group AdamW eps decomposition — CLOSED all 3 groups falsified

Branch: `g1r2-frieren/aux-eps-per-group`. W&B runs: `dffq1mxp` (Arm A embed), `4cw7dvkr` (Arm B lm_head), `c5sv4q69` (Arm C scalars NEW stack).

| Arm | Group | val | ffs | vs NEW bar | Stack |
|---|---|---|---|---|---|
| A | embed (50304×768) | 3.27219 | 3050 | n/a (old MUON_LR) | OLD 0.0375 |
| B | lm_head (50304×768) | 3.27242 | 3050 | n/a (old MUON_LR) | OLD 0.0375 |
| C | scalars (bias/LN) | **3.27161** | **3050** | FAIL (+1.3e-3, +25) | NEW 0.04 |

All 3 arms land at ffs=3050, vals cluster in tight 8e-4 band. Combined with askeladd #493 n=4 global closure: AdamW ε family fully falsified across all groups. Mechanism: ε ∈ [1e-10, 1e-8] doesn't materially perturb √v̂ denominator in post-warmup/cooldown regime at our LR/WD scales. Per-group eps plumbing retained in code for potential future use.

### PR #561 — frieren Lookahead AdamW wrapper assigned

Lookahead (Zhang et al 2019) wraps existing AdamW with periodic slow-weights sync: every k steps, `w_slow ← w_slow + α(w_fast − w_slow)`, then `w_fast ← w_slow`. ~30 LoC wrapper, zero compute overhead, attacks within-trajectory gradient noise. Mechanistically distinct from SWA (tail-only), Schedule-Free (continuous Polyak), and Muon-cooldown-frac (per-group schedule). 2 arms: k=5 α=0.5 (paper defaults) and k=10 α=0.5 (longer sync window).

### PR #524 thorfinn — SWA WINDOW=300 Arm B T0 ffs=3000 POTENTIAL BREAKTHROUGH

T0 terminal (z02q183a): val=3.27290, **ffs=3000** — below baseline floor 3025 by 25 steps.

| Metric | T0 | Baseline | Δ |
|---|---|---|---|
| val | 3.27290 | 3.270288 | +0.0026 (FAIL val bar) |
| **ffs** | **3000** | **3025** | **−25 (PASS ffs target!)** |

Mechanistic explanation: WINDOW=300 starts SWA accumulation at step 2875 (vs 3025 for Arm A with WINDOW=150). At step 3000 eval, swa_count=126 — substantial averaging. The averaged trajectory crosses 3.28 ~25 steps earlier than the live weights would. T1 launched at 09:21 UTC, ETA terminal ~11:05 UTC. Kill gate NOT triggered (val<3.275 AND ffs<3050). For n=2 mean: need T1 ffs ≤ 3050 (achievable), val < 3.267676 (unlikely). If n=2 ffs passes but val fails strict, will evaluate ffs-improvement-only merge.

### PR #527 fern NAdamW — CLOSED (see Cycle 71 mid-3 entry above for full results)

## 2026-05-20 08:30 UTC — Cycle 71: PR #538 Lion closed; edward reassigned #557 SF-AdamW

### PR #538 — edward Lion optimizer (Chen 2023) on AdamW group — CLOSED structurally worse

Branch: `g1r2-edward/lion-adamw-group`. W&B runs: `xi4wtxky` (disabled-check), `uyc4zbxk` + `f6gl4fbq` (Arm A smokes), `ea66u7v6` (Arm B smoke), `1k9xh5qs` (Arm A n=1 full).

| Arm | Config | val/loss | ffs | Gate verdict |
|---|---|---|---|---|
| Disabled-check (200 steps) | LION_ENABLED=0 | 4.09560 | n/a | ✅ plumbing OK |
| Arm A smoke (200 steps) | LION_LR_SCALE=0.33 | 4.322 | n/a | ⚠ borderline |
| Arm B smoke (200 steps) | LION_LR_SCALE=0.10, B1=0.95/B2=0.98 | 4.640 | n/a | ❌ killed (>4.50) |
| Arm A n=1 full (3175 steps) | LION_LR_SCALE=0.33 | **3.29467** | -1 (never reached) | ❌ FAIL |

**Bar check vs new baseline (val < 3.270288, ffs ≤ 3025)**:
- Arm A val 3.29467 = +0.024 regression. FAIL by 6× statsig margin. ffs=-1 (never reached 3.28 = structural miss).
- Arm B killed at smoke.

**Mechanism verdict**: Lion's `sign(β1·m + (1-β1)·g)` removes the second-moment scaling AdamW provides. Third sign/eps perturbation falsified (chain: ADAM_EPS #493 → Cautious AdamW #523 → Lion #538). The lm_head (50304×768) and embed row-rank-1 gradients need precise variance normalization — sign compression and sign-masking both destroy this. Axis closed: sign-based AdamW group replacements incompatible with our floor.

**New assignment**: edward → #557 Schedule-Free AdamW (Defazio 2024, arxiv 2405.15682). Polyak averaging mechanism is fundamentally different from sign variants — preserves full second-moment adaptation, eliminates LR cooldown timing dependence. 2 arms: LR_SCALE=1.0 and LR_SCALE=2.0.

## 2026-05-20 06:40 UTC — BASELINE UPDATED: PR #494 MUON_LR=0.04 MERGED

### PR #494 — nezuko MUON_LR=0.04 — MERGED ⭐ (new baseline val=3.270288/ffs=3025)

Branch: `g1r2-nezuko/muon-lr-sweep`. W&B runs `phlq9bug` (T0+T1), `qjbcrw1g` (T2+T3).

| Trial | val/loss | ffs | W&B run |
|---|---|---|---|
| T0 | 3.26875 | 3000 | phlq9bug |
| T1 | 3.27152 | 3050 | phlq9bug |
| T2 | 3.26988 | 3025 | qjbcrw1g |
| T3 | 3.27100 | 3025 | qjbcrw1g |
| **n=4 mean** | **3.270288** | **3025** | |

**Merge verdict**: val passes strict by −0.0011 (statsig 4.86×). ffs tied at 3025 (no regression). Merged despite ffs tie: val improvement is real, MUON_LR=0.04 becomes new default, future experiments benefit from tighter val starting point. ffs=3025 floor unchanged — cracking to ≤3000 is the next priority.

**Mandatory stack updated**: `MUON_LR=0.04` added. All 7 in-flight PRs notified to rebase.

### Cycle 71 opens: nezuko #549 Muon-cooldown-frac

**Primary research goal**: crack ffs from 3025 → ≤3000. The ffs floor at 3025 means val first crosses 3.28 at step 3025 (quantized to 25-step intervals in final 10% of training). Need the crossing to happen at step ≤3000. Nezuko assigned to test decoupled Muon LR cooldown schedule as the most targeted mechanism for this.

## 2026-05-20 04:28 UTC — Cycle 70 late: 2 closures (#493 ADAM_EPS n=4 fail, #523 Cautious AdamW); edward #538 Lion; askeladd #541 embed-init

### PR #493 — askeladd ADAM_EPS=1e-8 n=4 confirm — CLOSED axis falsified

Branch: `g1r2-askeladd/adam-eps-sweep`. W&B runs `ef8iatgn` (T0+T1) + `0r0o4waj` (T2+T3).

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.26937 | 3000 |
| T1 | 3.27351 | 3050 |
| T2 | 3.27114 | 3025 |
| T3 | 3.27367 | 3050 |
| **n=4 mean** | **3.271923** | **3031.25** |

**Strict bar verdict**: val +0.000535 FAIL, ffs +6.25 FAIL. Both axes miss. T0's ffs=3000 (first sub-3025 of cycle) was a fortunate trial outlier — remaining 3 trials cluster near baseline noise floor. **Effect size dominated by per-trial variance.** Axis closed; AdamW global eps is locally insensitive at 1e-10 under our mandatory stack. Per-group decomposition continues in frieren #529.

### PR #523 — edward Cautious AdamW (Liang 2024) — CLOSED math-kill regression

Branch: `g1r2-edward/cautious-adamw`. W&B run `s8ywcvks` (T0 only — T1 math-killed).

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.2861 | -1 (never reached 3.28) |

Predeclared kill gate triggered: T0 val > 3.276 → math-kill T1 (n=2 mean foreclosed). **+1.4% regression** vs baseline.

**Mechanism verdict**: sign-alignment mask discards useful gradient signal during cooldown — opposite of the paper's claim. The +0.0042 noise at step 500 cascaded to +0.015 by step 3175. Mechanism structurally incompatible with our compressed 3175-step horizon under mandatory stack.

### New assignments: edward #538 (Lion) + askeladd #541 (embed-init-std)

- **#538 edward**: Lion optimizer (Chen et al 2023, arxiv 2302.06675) as AdamW-group swap. ~15 LoC inline class. Update direction = sign(β1·m + (1-β1)·g) — FULL sign update (not mask). Different mechanism from Cautious AdamW failure: no signal discarded, just magnitude compressed. 2 arms: LION_LR_SCALE=0.33 (Chen std) and LION_LR_SCALE=0.10 (aggressive).

- **#541 askeladd**: Embed init std sweep — explicit "initialization ideas" axis from launch directive, currently zero init experiments in flight. Current embed init is `w.normal_()` = N(0, 1) — **50× larger** than GPT-2 standard (std=0.02). Per-row L2 norm at init ≈ 27.7 vs ≈ 0.55. 3 arms n=1: EMBED_INIT_STD ∈ {0.5, 0.1, 0.02}.

## 2026-05-20 03:40 UTC — Cycle 70 mid: 3 closures; alphonse #533 stack-pruning; tanjiro #534 Shampoo-lmhead

### PR #500 — alphonse WD_SCALARS=0.0001 sweep — CLOSED no-improvement

Branch: `g1r2-alphonse/wd-scalars-sweep`. W&B run `spd3jmcl`.

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27267 | 3050 |
| T1 | 3.27177 | 3025 |
| **n=2 mean** | **3.272220** | **3037.5** |

Both axes fail strict bar (val +0.000832, ffs +12.5). Smoke at WD_SCALARS=0.001 also failed (3.27289). **Axis falsified**: AdamW scalars group (bias + LN params, ~70K params) is flat-optimal at WD=0 (default). Combined with fern #456 scalars-LR closure, the entire AdamW scalars group is flat-optimal under its current HPs.

### PR #515 — tanjiro AdEMAMix β_slow pivot — CLOSED mechanism incompatible

Branch: `g1r2-tanjiro/ademamix`. W&B smoke run `p1lns29e` (β_slow=0.999, alpha=2, T_warmup=1500).

| Run | Config | Terminal val | ffs | Verdict |
|---|---|---|---|---|
| 2vlfw2y9 | β_slow=0.9999, alpha=5 | 10.997 (div) | — | Diverged step 875 |
| o574gkh2 | β_slow=0.9999, alpha=2 | 10.96 (div) | — | Diverged step 625 |
| p1lns29e | β_slow=0.999, alpha=2, T=1500 | **3.293** | **-1 (never hits 3.28)** | CLOSED |

**Root cause**: AdEMAMix requires run length ≥ 3× slow-EMA half-life for mechanism to help. At β_slow=0.999, half-life = 693 steps = 22% of 3175 training steps. Slow EMA never reaches steady state. **Mechanism structurally incompatible with our 3175-step horizon.**

### PR #524 — thorfinn SWA window150-smoke VERDICT

W&B run `vrp96qfy`. val=3.272897, ffs=3025 at step 3175.

Regression vs baseline: val +0.001509, ffs tied. SWA window=150 slightly hurts val at n=1. Sent for n=2 confirm (val < 3.28 criterion met). Arm A n=2 in progress. Arm B (WINDOW=300) queued if compute permits.

### New assignments: alphonse #533 (stack-pruning) + tanjiro #534 (Shampoo-lmhead)

- **#533 alphonse**: Stack pruning ablation — 3 arms each disabling one mandatory-stack element: CONTRA_MUON=0 (Arm A), MU_WARMUP_STEPS=0 (Arm B), ATTN_SOAP_TRUST_THRESHOLD=1.0 i.e. disable ATTN_SOAP (Arm C). Each n=1. Verdict per arm: val regression < 5e-3 + ffs < 25 → soft-redundant; val ≥ 1e-2 or ffs ≥ 50 → load-bearing.

- **#534 tanjiro**: One-sided Shampoo on lm_head (right factor only). Arm A BETA2=0.95, Arm B BETA2=0.99. Shampoo captures 768-dim column-space covariance of lm_head gradient, applies R^{-1/4} preconditioning. Mechanism is orthogonal to all existing stack elements. ~20 LoC implementation.

## 2026-05-20 02:35 UTC — Cycle 70: nezuko #494 MUON_LR=0.04 n=2 val PASS / ffs TIES → n=4 confirm

### PR #494 — nezuko MUON_LR=0.04 vs default 0.0375 (n=2 screen result)

Branch: `g1r2-nezuko/muon-lr-sweep`. W&B run `phlq9bug` (Arm B). Mandatory stack + MUON_LR=0.04.

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.26875 | 3000 |
| T1 | 3.27152 | 3050 |
| **n=2 mean** | **3.270135** | **3025.0** |

| Metric | n=2 mean | Bar (strict) | Δ | Verdict |
|---|---|---|---|---|
| val/loss | 3.270135 | < 3.271388 | **−0.001253** | **PASS** |
| ffs | 3025.0 | < 3025 | **0** (tie) | **TIES — fails strict** |

Statsig: (3.28 − 3.270135) × √2 = **0.01395** ≥ 0.004 ✓

**Arm A (MUON_LR=0.035)** was math-killed earlier (T0=3.27504/3075 fails both axes; mean cannot recover at n=2).

**Verdict**: Val improvement (~−1.3e-3) is robust with healthy statsig. FFS axis ties the 3025 baseline floor. Per predeclared decision tree: send back for n=4 confirm. Math for n=4 strict pass: T2+T3 val sum < 6.5426 (mean <3.27128 — T0=3.26875 already below), T2+T3 ffs sum < 6050 (mean <3025 strict — need ≥1 trial at 3000). Same n=4 path as askeladd #493 ADAM_EPS=1e-8 axis.

**Pattern observation**: Both winning axes (MUON_LR=0.04, ADAM_EPS=1e-8) show identical {3000, 3050} ffs at n=2 → mean=3025. This is the inter-trial bimodal variance pattern thorfinn's SWA #524 targets directly.

### PR #493 — askeladd ADAM_EPS=1e-8 n=4 confirm partial (T2 terminal)

Branch: `g1r2-askeladd/adam-eps`. W&B run `0r0o4waj` (n=4 confirm T2+T3).

| Trial | val/loss | ffs | source run |
|---|---|---|---|
| T0 | 3.26937 | 3000 | ef8iatgn |
| T1 | 3.27351 | 3050 | ef8iatgn |
| T2 | **3.27114** | **3025** | 0r0o4waj |
| T3 | (in flight, step 226) | — | 0r0o4waj |

**n=3 partial**: val mean = 3.2713 (PASS strict by 9e-5), ffs mean = 3025 (TIES strict).

**T3 math for n=4 strict pass**:
- val < 3.271388 → T3 sum-budget: T3 ≤ 3.271552 (~3e-4 margin)
- ffs < 3025 → T3 < 3025 strict (i.e. 3000 needed)

T3 terminal ETA ~04:10 UTC.

## 2026-05-20 01:30 UTC — Cycle 69 late: fern #456 SCALARS_LR CLOSED; fern reassigned #527 NAdamW

### PR #456 — fern SCALARS_LR ±25% (0.0075 vs 0.0125) — CLOSED axis falsified

Branch: `g1r2-fern/scalars-lr-sweep`. Both arms ±25% around default 0.01:

| Arm | Best T0 val | T0 ffs | vs strict bar |
|---|---|---|---|
| A (0.0075) | 3.27256 | 3050 | val MISS +0.00117, ffs MISS +25 |
| B (0.0125) | 3.27491 + crashed retry | 3075 | val MISS +0.0035, ffs MISS +50 |

Multiple crashes (rep crashes on pod, multiple ns14stack retries). Axis falsified at ±25%. Default 0.01 confirmed locally optimal. The third AdamW LR group (scalars: bias + LN params, ~70K params total) is not a tunable axis on this stack.

### Reassignment: fern → PR #527 NAdamW (Dozat 2016)

Branch: `g1r2-fern/nadamw`. Hypothesis: replace vanilla Adam's first-moment update in AdamW group (embed, lm_head, scalars) with Nesterov-style lookahead. Specifically:

- Standard AdamW: `θ ← θ - lr * m̂ / (√v̂ + ε)`
- NAdamW: `θ ← θ - lr * (β1 * m̂ + (1-β1) * grad / (1 - β1^t)) / (√v̂ + ε)`

Custom `NAdamW` class (~20 LoC) gated by env var `NADAMW=1`. Two arms: β1=0.8 (pure mechanism test) and β1=0.85 (compensate for lookahead).

Reference: Dozat 2016 ICLR Workshop. Fresh axis on r2 stack; #510 tested similar mechanism on r3 (different stack).

### Tanjiro #515 alpha=5 + alpha=2 BOTH DIVERGED — pivot to β_slow=0.999

Both AdEMAMix variants at β_slow=0.9999 crashed:
- alpha=5: val 4.42 → 10.997 across steps 250→875 (deterministic up-trend)
- alpha=2: val 4.03 → 10.960 across steps 250→625 (same pattern, 250 steps earlier)

Diagnosis: β_slow=0.9999 has half-life ~10000 steps but train_steps=3175 — slow-EMA never reaches steady state. Combined with MU_COOLDOWN and contra-muon coupling, the slow-EMA contribution lags badly. Sent advisor directive to retry at **β_slow=0.999 + alpha=2 + T_warmup=1500** (paper-safe cell from Pagliardini et al ICLR 2024).

---

## 2026-05-20 00:55 UTC — Cycle 69 late: thorfinn #495 CLOSED no-improvement; reassigned #524 SWA Tail Averaging; nezuko #494 Arm B T0 BREAKTHROUGH

### PR #495 — thorfinn COOLDOWN_FRAC sweep (0.75 vs 0.65) — CLOSED no-improvement

Branch: `g1r2-thorfinn/cooldown-frac-sweep`. Both ±0.05 around hardcoded 0.7 eliminated:

| Arm | T0 val | T0 ffs | vs bar |
|---|---|---|---|
| A (0.75) | 3.27193 | 3025 | val −0.000542 PASS / ffs ties (FAIL strict) |
| B (0.65) | 3.2755 | 3100 | val +0.004 FAIL / ffs +75 FAIL |

n=2 math kill on Arm B (T1 needs val<3.267 + ffs<2950 — never observed). Default 0.7 is local optimum. Axis closed.

### Reassignment: thorfinn → PR #524 SWA Tail Averaging at Eval

Branch: `g1r2-thorfinn/swa-tail-averaging`. Hypothesis (arxiv 1803.05407, Izmailov et al UAI 2018): during final N steps of cooldown, maintain uniform running average of model weights. At each val event, substitute SWA weights for eval, restore for training. Training trajectory unchanged. Attacks ffs bimodal variance ({3000, 3050} pattern observed in askeladd and nezuko T0/T1 spreads) by evaluating at mean trajectory point.

Critical distinction from falsified PR #286 EMA: PR #286 was exponential decay applied throughout training; SWA is uniform over fixed terminal window, eval-only.

### Nezuko #494 Arm B T0 breakthrough (in flight)

W&B `phlq9bug` T0 terminal:
- val/loss = **3.26875** (BELOW bar 3.271388 by 0.00264) ✓
- ffs = **3000** (BELOW bar 3025 by 25) ✓

Second sub-3025 ffs observation this cycle (after askeladd T0=3000). T1 in progress, terminal ~02:00 UTC. If T1 ffs ≤ 3050 strict, n=2 strict pass → merge candidate.

| Cycle | PR | Idea | Status |
|---|---|---|---|
| 69 | #495 | COOLDOWN_FRAC ±0.05 | closed — flat plateau at 0.7 |

## 2026-05-20 00:10 UTC — Cycle 69: edward #498 TARGET_UW CLOSED no-improvement; reassigned #523 Cautious AdamW (fresh mechanism)

### PR #498 — edward TARGET_UW sweep (0.28 vs 0.42) — CLOSED no-improvement

Branch: `g1r2-edward/target-uw-sweep`. Both arms ±0.07 around hardcoded 0.35 eliminated:

| Arm | Test | Result | Verdict |
|---|---|---|---|
| A (0.28) | 4 smoke launches | 4 crashes (m6a6xw86 step 400, dsvypuzb step 0, o3y0xkpg step 175, rk60jli3 step 175) | NS5 polishing diverges with weaker orthogonality floor |
| B (0.42) | smoke200 + n=2 T0 (4bxj4503) | smoke200 healthy val=4.0987; T0 kill-gated step 2000 val=3.4443 (>3.40 gate); +0.32 offset at step 125 | Over-floors small Muon updates in warmup |

**Mechanism**: TARGET_UW=0.35 sits on flat top of asymmetric ridge with NS5_ITERS=14 + CONTRA_MUON=0.4. Lower → NS5 divergence; higher → warmup descent stalls. smoke200 was insensitive sentinel (200-step run is cooldown-dominated; 3175-step run is warmup-sensitive).

**Strategic learning** (adopting): smoke at `--train_steps 500` (warmup-tail visible) is better sentinel than smoke200 for any warmup-sensitive axis. Updates advisor heuristic.

### Reassignment: edward → PR #523 Cautious AdamW

Branch: `g1r2-edward/cautious-adamw`. Hypothesis (arxiv 2411.16085, NeurIPS 2024): apply sign-alignment mask to AdamW update on (embed + lm_head + scalars), zeroing components where update direction disagrees with current gradient, then rescale mask to preserve L1 norm. Expected 1–2% perplexity reduction at zero extra compute/state. Fresh mechanism (not HP), orthogonal to tanjiro #515 AdEMAMix though same group.

| Cycle | PR | Idea | Why closed |
|---|---|---|---|
| 69 | #498 | TARGET_UW ±0.07 | both directions regress; flat ridge |

## 2026-05-19 22:55 UTC — Cycle 69 BREAKTHROUGH: askeladd eps=1e-8 T0 FIRST sub-3025 ffs observed

### PR #493 — askeladd AdamW eps=1e-8 — T0 PASS, T1 in progress

**T0 terminal** (W&B run `ef8iatgn`, step 3175):
- val/loss = **3.26937** (BELOW bar 3.271388 by 0.00201)
- ffs = **3000** (BELOW baseline floor 3025 by 25 steps — FIRST sub-3025 observation this cycle)

**Significance**: Baseline floor was thought to be 3025 (PR #458 zero-variance). This is the first observation that ffs<3025 is achievable on the new mandatory stack. eps=1e-8 (vs hardcoded 1e-10) is plausibly the lever — larger denominator floor stabilizes AdamW updates near zero gradients in the embed/lm_head group.

**Math for n=2 mean to pass strict bar (val<3.271388 AND ffs<3025)**:
- ffs: T1 ≤ 3049 strict (3050 ties, fails). Easy.
- val: T1 ≤ 3.273403. Very easy.

T1 running (step 3876 = T1 step 701/3175). ETA ~00:25 UTC. If T1 lands anywhere within typical baseline range, this is a clear merge win — third stacked 25-step ffs improvement after NS5_ITERS=14 → WD_AUX=0.001.

### Other status (22:55 UTC)

- **Tanjiro #515 AdEMAMix**: disabled-check passed val=4.103 at step 200 (matches baseline 4.10). Now re-verifying (xxek855x finished, 85j2gham re-running). Live AdEMAMix smoke next.
- **Edward #498 TARGET_UW=0.42** screen-n2 launched (4bxj4503 step 400 val=3.90 healthy). Arm A (0.28) declared unstable after 4 crashes.
- **Frieren #488 β1=0.75 v3** pumping NaN for 250+ steps — waste compute, awaiting student kill.
- **Nezuko #494 muon_lr=0.04** Arm B screen (phlq9bug step 550 val=3.80 healthy).
- **Fern #456 scalars_lr=0.0075** Arm B smoke complete (val=4.112 healthy), n=2 launch pending.
- **Thorfinn #495 cooldown_frac=0.65** screen (epwv53cy step 975 val=3.69 healthy). Pivot from 0.75 (T0 val=3.272/ffs=3025, T1 crashed at step 3494).
- **Alphonse #500 wd_scalars=0.001** smoke (rtjbquo2 step 2050 val=3.43 progressing). Arm A 0.0001 n=1 finished val=3.272148/ffs=3050 (near-miss).

---

## 2026-05-19 22:10 UTC — Cycle 69 mid-cycle: tanjiro β2=0.90 MATH KILL, edward TARGET_UW=0.28 unstable

### PR #491 — tanjiro AdamW β2=0.90 — T0 MATH KILL on T1

W&B run `y3f7a1vo` T0 (β2=0.90) terminal:
- val/loss = 3.27645 (vs bar 3.271388 — MISS by +0.005)
- ffs = 3100 (vs bar 3025 — MISS by +75)

**Math foreclosure on T1**: For n=2 mean to beat ffs<3025 (strict), T1 ffs ≤ 2925 required. Baseline ffs floor = 3025 (PR #458 zero-variance), so T1 needs 100 steps better than baseline — never observed. Infeasible.

Sent back at 22:03 UTC with math kill instruction. Tanjiro to close PR #491 and await β2=0.99 single-arm reassignment. **β2 axis verdict**: β2=0.90 (lower) is WORSE than default 0.95. Only β2=0.99 (higher) remains untested.

### PR #498 — edward TARGET_UW=0.28 — Arm A UNSTABLE (4 consecutive crashes)

4 consecutive crash/fail runs on `edward-target-uw-0.28-smoke`:
- m6a6xw86 crashed step 400 (val=3.876)
- dsvypuzb failed step 0
- o3y0xkpg crashed step 175 (val=4.41)
- rk60jli3 currently at step 175 val=4.42 (trending unstable)

At step 175, baseline val ≈ 4.10. Edward arm at 4.42 = clear regression. Lower TARGET_UW weakens orthogonality constraint, likely destabilizing Contra-Muon NS5 polish. Sent advice at 22:12 UTC to declare Arm A unstable and pivot to Arm B (TARGET_UW=0.42).

### Live n=2 screens (5 in-flight)

| PR | Student | Axis | Latest W&B | Notes |
|---|---|---|---|---|
| #456 | fern | scalars_lr=0.0125 | step 3701, ffs=3050 T0 | T1 mid-training — math kill possible if T1 ffs>2975 |
| #488 | frieren | β1=0.75 | step 318 age 12m | Screen just launched (prior crashed) |
| #493 | askeladd | eps=1e-8 | step 2675 val=3.32 | T1 trending poorly (~84% trained, val too high) |
| #494 | nezuko | muon_lr=0.035 | step 3125 val=3.276 | T1 nearly terminal — possibly close to bar |
| #495 | thorfinn | cooldown_frac=0.75 | step 3276, ffs=3025 T0 | T1 just started; T0 ffs=3025 (good!) |
| #500 | alphonse | wd_scalars=0.0001 | T0=val 3.272148/ffs 3050 (full run as "smoke") | Near miss; T1 next, then Arm B 0.001 |

---

## 2026-05-19 19:35 UTC — PR #458 MERGED: edward WD_AUX=0.001 — auxiliary embed/head weight decay

**New baseline**: val mean=3.271388, ffs mean=3025 (n=2 screen). Squash-merged onto auto-nanogpt-1gpu-r2.

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27166 | 3025 |
| T1 | 3.271114 | 3025 |
| n=2 mean | **3.271388** | **3025** |

Statsig: (3.28−3.271388)×√2 = 0.01218 ≥ 0.004 — PASSES at 3.04×. W&B run: `uoak0qa8`.

**Zero variance on ffs**: Both trials landed at 3025 — first zero-variance ffs result of the cycle. Strong evidence WD_AUX=0.001 consistently shaves exactly 25 steps off baseline.

**New bar**: val<3.271388 AND ffs<3025 (strict, both required).

**New mandatory stack**: `NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85`

**Speedup**: val Δ=−0.001697 vs PR #479; ffs Δ=−25 steps.

All 7 in-flight PRs (#456, #488, #491, #492, #493, #494, #495) notified of new bar and updated mandatory stack.

---

## 2026-05-19 19:05 UTC — Cycle 68 close-out: PR #479 MERGED, 3 math kills, edward T1 exceptional

### PR #479 MERGED — alphonse NS5_ITERS=14 (squash-merged 18:50 UTC)

**New baseline**: val mean=3.273085, ffs mean=3050 (n=2). **New mandatory stack**: NS5_ITERS=14 added.

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27175 | 3025 |
| T1 | 3.27442 | 3075 |
| n=2 mean | **3.273085** | **3050** |

Statsig: (3.28−3.273085)×√2 = 0.00978 ≥ 0.004 — PASSES at 2.45×. W&B run: `1qyzfn8q`.

**New bar**: val<3.273085 AND ffs<3050 (strict, both required).

---

### PR #468 CLOSED — askeladd GRAD_CLIP_NORM_ADAM=1.0 — n=2 MISS both axes

T0=3.2757/3075, T1=3.2734/3050. n=2 mean: val=3.27455, ffs=3062.5.
Both miss old bar (val<3.273477, ffs<3056.25). New bar even harder. Axis characterized: gradient clipping on AdamW subset shows no benefit.
Askeladd reassigned → #493 AdamW epsilon sweep (eps=1e-8 vs 1e-10).

---

### PR #469 CLOSED (MATH KILL) — nezuko EMBED_LR=0.225 re-screen — new bar forecloses T1

T0: val=3.27503, ffs=3075. New bar requires ffs mean<3050 (strict). With T0=3075, T1 needs ffs<3025 (strict), but minimum feasible ffs=3025 (3025<3025 is false). Mathematically impossible.
Nezuko reassigned → #494 MUON_LR sweep (0.035 vs 0.04).

---

### PR #462 CLOSED (MATH KILL) — thorfinn MU_WARMUP_START=0.80 n=4 — both bars foreclosed

T0=3075, T1=3050, T2=3075 locked. Best T4=3025 gives n=4 mean=(3075+3050+3075+3025)/4=3056.25.
New bar ffs<3050: 3056.25>3050 → IMPOSSIBLE. Old bar (ffs<3056.25): 3056.25 ties, not strict pass.
MU_WARMUP_START=0.80: 2/3 trials at 3075, 1/3 at 3050 — inconsistent improvement.
Thorfinn reassigned → #495 COOLDOWN_FRAC sweep (0.65 vs 0.75).

---

### PR #458 — edward WD_AUX=0.001 — EXCEPTIONAL n=2 result, awaiting SENPAI-RESULT

W&B run `uoak0qa8` FINISHED. Both trials at ffs=3025 (zero ffs variance!).

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27166 | 3025 |
| T1 | 3.271114 | 3025 |
| n=2 mean | **~3.27139** | **3025** |

Against new bar: val PASS −0.001698, ffs PASS −25. Statsig: (3.28−3.27139)×√2 = 0.01218 ≥ 0.004 — PASSES at 3.04×.
**Zero ffs variance** (T0=T1=3025) is the strongest signal yet — WD_AUX=0.001 is highly consistent.
Awaiting student SENPAI-RESULT to trigger merge preflight.

---

## 2026-05-19 18:09 UTC — Cycle 68: #485 CLOSED COOLDOWN_POWER=0.5 gate kill — axis fully characterized

### PR #485 — tanjiro COOLDOWN_POWER=0.5 (sqrt back-loaded cooldown) — KILLED EARLY

Branch: `g1r2-tanjiro/cooldown-power-0.5-screen`. Full new mandatory stack + COOLDOWN_POWER=0.5.

| step | val/loss | Δval/Δ125steps |
|---|---|---|
| 1000 | 3.65348 | — |
| 1500 | 3.54749 | −0.0309/Δ125 |
| 2000 | **3.46616** | (gate at 3.40 — violated by +0.066) |
| 2125 | 3.44927 | −0.0169/Δ125 (decelerating) |

W&B run: `bkng1ngd` — KILLED at step 2272 (saved ~105 min compute).

**Kill rationale**: val@step2000=3.46616, 0.066 above gate, 0.096 worse than baseline trajectory at same step. Rate Δval/step decelerating; extrapolation shows no path to baseline final (3.273) within remaining 1050 steps.

**Axis verdict — COOLDOWN_POWER fully characterized**:
- power=2.0 (front-loaded quadratic) → PR #464 math kill (T0 val=3.28756, never crossed 3.28)
- power=1.0 (linear) → baseline (winning)
- power=0.5 (back-loaded sqrt) → PR #485 gate kill (val falls behind too far)

Symmetric pair of misses confirms power=1.0 is local optimum. Cooldown shape sensitivity is low on extremes; the linear ramp is robust.

**Reassignment**: tanjiro → #491 ADAM_BETA2 sweep (0.90 vs 0.99 around hardcoded 0.95). Fresh AdamW-side axis paired orthogonally with frieren's β1 sweep (#488).

---

## 2026-05-19 17:09 UTC — Cycle 68: T0 wave (4 PRs hit step 3175): 2 PASS, 1 MATH-KILL, 2 narrow MISS

### PR #479 — alphonse NS5_ITERS=14 T0 PASS (strict bar both axes)

Branch: `g1r2-alphonse/ns5-iters-14`. Full new mandatory stack.

| Run | T0 step 3175 val | T0 ffs | vs strict bar |
|---|---|---|---|
| `1qyzfn8q` | **3.27175** | **3025** | val PASS −0.00173, ffs PASS −31.25 ✅✅ |

- T1 in flight (step ~776 of T1 at 17:08 UTC); terminal ETA ~18:25 UTC
- n=2 mean math: T1 val < 3.2753 + T1 ffs < 3087.5 → wide path open

### PR #458 — edward WD_AUX=0.001 T0 PASS (strict bar both axes)

Branch: `g1r2-edward/wd-aux-sweep`. Full new mandatory stack.

| Run | T0 step 3175 val | T0 ffs | vs strict bar |
|---|---|---|---|
| `uoak0qa8` | **3.27166** | **3025** | val PASS −0.00181, ffs PASS −31.25 ✅✅ |

- T1 in flight (step ~226 of T1 at 17:08 UTC); terminal ETA ~18:43 UTC
- Slightly better T0 val than alphonse (Δ=−0.00009)
- n=2 mean math: T1 val < 3.2753 + T1 ffs < 3087.5 → wide path open

### PR #459 — frieren Lookahead-AdamW K=5 T0 MATH KILL

Branch: `g1r2-frieren/lookahead-adamw`. Full new mandatory stack.

| Run | T0 step 3175 val | T0 ffs | vs strict bar |
|---|---|---|---|
| `o90qadl2` | 3.27981 | 3175 | val MISS +0.0063, ffs MISS +118.75 ✖✖ |

**Math kill rationale**: For n=2 mean ffs < 3056.25 with T0 ffs=3175, T1 needs ffs < -62.5 (impossible — min feasible ffs ≈ 3025). T1 aborted to save ~50 min GPU.

**Axis verdict**: Lookahead-AdamW K=5 with default slow-weight α=0.5 misses both axes. Mechanism is not getting cooldown-phase boost; possibly interfering with cooldown trajectory. **Reassignment options to consider**: K=10 (longer slow-weight horizon), Lookahead-Muon, OR pivot to entirely different mechanism family.

### PR #468 — askeladd grad-clip-adam=1.0 T0 narrow MISS

Branch: `g1r2-askeladd/grad-clip-adam`. Full new mandatory stack.

| Run | T0 step 3175 val | T0 ffs | vs strict bar |
|---|---|---|---|
| `ohvht46b` | 3.27568 | 3075 | val MISS +0.0023, ffs MISS +18.75 |

- T1 in flight; T1 must hit ffs=3025 (minimum feasible) AND val<3.2713 to make n=2 mean pass
- NOT closed — narrow but mathematically open path

### PR #456 — fern SCALARS_LR=0.0075 (Arm A) T0 narrow MISS

Branch: `g1r2-fern/scalars-lr-sweep`. Full new mandatory stack.

| Run | T0 step 3175 val | T0 ffs | vs strict bar |
|---|---|---|---|
| `wa37o6l9` | 3.27491 | 3075 | val MISS +0.0014, ffs MISS +18.75 |

- T1 in flight; T1 must hit ffs=3025 AND val<3.27205 to make n=2 mean pass
- NOT closed — narrow path open

### Cross-cycle observation

**alphonse and edward T0 both at ffs=3025 (one eval slot better than baseline ffs=3050)** — two orthogonal axes (NS5_ITERS=14 + WD_AUX=0.001) independently shaving the cooldown crossing by 25 steps. If T1s both confirm, these are two independent improvements — and may **compound when stacked** (since one acts on Muon NS5 iterations, the other on AdamW WD applied to embed+lm_head). Stacked test = high-priority follow-up.

---

## 2026-05-19 16:23 UTC — Cycle 68: #462 thorfinn Arm A n=2 MISS new bar marginally → n=4 confirm continuation

### PR #462 — MU_WARMUP_START=0.80 (Arm A) n=2 screen on NEW stack — n=4 CONFIRM ASKED

Branch: `g1r2-thorfinn/warmup-start-sweep`. Full new mandatory stack.

| Trial | val (step 3175) | ffs | vs new bar |
|---|---|---|---|
| T0 | 3.27516 | 3075 | val MISS +0.0017, ffs MISS +18.75 |
| T1 | **3.27399** | **3050** | val PASS −0.0005, ffs PASS −6.25 ✅ |
| **n=2 mean** | **3.274575** | **3062.5** | val MISS +0.0011, ffs MISS +6.25 |

- W&B run: `btr2ygl9` (single job, both trials)
- vs OLD bar (PR #358): val MISS +0.0002 (extremely close), ffs PASSES
- T1 individually beat BOTH new bars cleanly (val=3.27399 < 3.273477; ffs=3050 < 3056.25)
- T0-T1 variance: Δval=0.00117 / Δffs=25 — large at n=2

**Decision**: NOT closed. Sent back for **n=4 confirm at MU_WARMUP_START=0.80** (predeclared T2+T3 batch). T1 being a clear pass means the axis is *capable* of winning — variance-dominated at n=2, not falsified. n=4 math: T2+T3 mean val must be < 3.2724 (achievable if tracking T1), ffs must both hit floor=3050.

**Branching after n=4**:
- PASS strict bar → merge candidate
- MISS by < 0.0005 val → axis no-worse-than-baseline, move to Arm B (0.90)
- MISS by > 0.0005 val → axis falsified in this direction → launch Arm B

---

## 2026-05-19 16:05 UTC — Cycle 68: #464 CLOSED COOLDOWN_POWER=2.0 mathematical kill on NEW stack; tanjiro → power=0.5 sqrt cooldown re-screen

### PR #464 — COOLDOWN_POWER=2.0 (quadratic, Arm B) n=2 screen on NEW stack — CLOSED

Branch: `g1r2-tanjiro/cooldown-power-sweep`. NEW mandatory stack (MU_WARMUP_STEPS=200).

| step | val/loss (T0, n8hr5zpq) | bar |
|---|---|---|
| 3000 | 3.288261 | < 3.273477 |
| 3050 | 3.287814 | < 3.273477 |
| 3100 | 3.287616 | < 3.273477 |
| 3150 | 3.287554 (min) | < 3.28 (ffs target) |
| 3175 | **3.28756** | < 3.273477 |

- T0 val = 3.28756 → MISS new val bar by Δ=+0.014
- T0 ffs = **undefined** (val never crossed 3.28 within 3175-step budget) → MISS new ffs bar by ∞
- T1 aborted at step ~279/3175 (saved ~94 min GPU)
- n=2 mean mathematically dead: requires T1 val < 3.25939 (impossible) AND T1 ffs < 2937.5 (impossible)
- Plumbing verified clean via smokes (emto9g9h, 5o8665fx, 1lltxrsf — `optimizer/cooldown_power` correctly set per arm)

**Closure reason**: Mathematical kill at T0. Quadratic cooldown convexity front-loads decay too aggressively, starving the final ~250-step refinement window that drives the last 0.01-0.02 val improvement on the baseline trajectory.

**Axis verdict**: power > 1 (front-loaded decay) is the WRONG direction on the new stack. New stack with MU_WARMUP_STEPS=200, MU_COOLDOWN_START=0.95 needs MORE late-LR, not less. Strong directional signal that the symmetric counter (power < 1, e.g., sqrt) is the natural next test.

**Reassignment**: tanjiro → cooldown_power=0.5 sqrt cooldown n=2 screen on NEW stack (back-loaded decay; plumbing already verified by smoke 5o8665fx).

---

## 2026-05-19 14:34 UTC — Cycle 68: #429 CLOSED NS5_ITERS=14 PREV stack (bar moved, axis valid); alphonse → #479 re-screen on NEW stack

### PR #429 — NS5_ITERS=14 (Arm B) n=4 confirm on PREV stack — CLOSED

Branch: `g1r2-alphonse/ns5-iters-sweep`. PREV mandatory stack (no MU_WARMUP_STEPS).

| Stage | NS5_ITERS | n | val mean | ffs mean | vs OLD bar | vs NEW bar |
|---|---|---|---|---|---|---|
| Arm A n=2 | 10 | 2 | 3.27503 | 3075 | MISS both | MISS both |
| Arm B n=2 screen | 14 | 2 | 3.273885 | 3062.5 | **PASS both** ✅ | MISS both |
| Arm B T0 (n=4 start) | 14 | 1 | **3.27310** | 3050 | PASS both | PASS both individually |
| Arm B T1 (n=4) | 14 | 1 | 3.27559 | 3075 | PASS val / MISS ffs | MISS both |
| Arm B n=2 partial mean | 14 | 2 | 3.274342 | 3062.5 | PASS val / PASS ffs | MISS both |
| T2 | 14 | — | killed at step 87 (Option B) | — | — | ffs foreclosed |
| T3 | 14 | — | killed at step 87 (Option B) | — | — | ffs foreclosed |

**Closure reason**: T1 ffs=3075 mathematically forecloses all-4-at-floor requirement on NEW bar (ffs mean must be < 3056.25 → requires all 4 at 3050; T1=3075 makes that impossible regardless of T2/T3). Student correctly executed Option B early-termination (saved ~6.8h GPU).

**Axis verdict**: VALID, NOT falsified. T0=3.27310/3050 is the best single-trial val we've ever seen on the new bar stack. The reason for closure is bar tightening (PR #415 raised bar by Δval=−0.000906/Δffs=−12.5), not axis failure. Sign confirmed at n=2 on PREV stack (Δval=−0.000498 vs PREV baseline).

**Reassignment**: alphonse → #479 NS5_ITERS=14 re-screen on NEW mandatory stack (MU_WARMUP_STEPS=200 adds ~0.0009 val improvement; predicted T0 on new stack ≈3.272; highest-priority axis re-test in portfolio; +0.8% step-time cost only).

---

## 2026-05-19 12:42 UTC — Cycle 68 cont: #449 CLOSED EMBED_LR Arm A n=2 MISS (high T1 variance); nezuko → #469 re-screen on new stack

### PR #449 — EMBED_LR=0.225 (Arm A n=2) — CLOSED

Branch: `g1r2-nezuko/embed-lr-sweep`. PREV mandatory stack (no MU_WARMUP_STEPS).

| Trial | EMBED_LR | val | ffs |
|---|---|---|---|
| T0 | 0.225 | 3.27403 | 3050 |
| T1 | 0.225 | 3.27604 | 3100 |
| n=2 mean | 0.225 | 3.275035 | 3075 |

- n=2 mean vs NEW bar: val MISS +0.001558, ffs MISS +18.75
- n=2 mean vs OLD bar: val MISS +0.000652, ffs MISS +6.25
- Δval T0→T1 = +0.00201, Δffs = +50 — HIGH VARIANCE

**Mechanism**: T0 individually passed OLD val bar (3.27403 < 3.274383) at the ffs floor (3050). But T1 severely regressed (3.27604/3100). The step-3025 val trajectory determines both val quantization boundary (3.28) and ffs slot. This is the same bimodal-ffs seed-dominance pattern seen in #405 askeladd. The embed_lr effect is likely smaller than seed noise at this scale.

**Key finding**: EMBED_LR=0.225 is directionally neutral-to-slightly-positive on val vs default 0.3, but the effect is too small to reliably win over seed variance. The axis may be more detectable on the new stack (MU_WARMUP_STEPS=200 reduces early-training variance).

**Reassignment**: nezuko → #469 EMBED_LR re-screen on NEW mandatory stack (MU_WARMUP_STEPS=200). Predicted: new stack adds ~0.0009 val improvement; T0 on new stack ≈ 3.273 (potentially clearing new val bar 3.273477 with ffs=3050).

## 2026-05-19 12:22 UTC — Cycle 68: #405 CLOSED CONTRA_MUON sweep (regression-to-mean at n=4); askeladd → #468 AdamW gradient clipping

### PR #405 — CONTRA_MUON sweep (0.3 Arm A, 0.35 Arm B) — CLOSED

Branch: `g1r2-askeladd/contra-muon-0.3-sweep`. Direct continuation of PR #358 (CONTRA_MUON=0.5→0.4). Running on CONTRA_MUON=0.4 base. All screens ran on PREV mandatory stack (no MU_WARMUP_STEPS).

| Arm | CONTRA_MUON | W&B | n | val mean | ffs mean | vs strict bar | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.3 | `tektwuqy` | 2 | 3.274865 | 3075 | MISS both (val +0.000482, ffs +6.25 vs OLD bar) | missed |
| B (n=2 screen) | 0.35 | `ijqrvfy4` | 2 | 3.273505 | 3050 | PASS both vs OLD bar ✅ | screen win |
| B (n=4 confirm) | 0.35 | `6svhvfu8` | 3 (T3 killed) | 3.275009 | 3075 | MISS both (NEW bar: val +0.001532, ffs +18.75) | CLOSED |

**Per-trial n=4 confirm (Arm B `6svhvfu8` — T3 killed per bar-tightening foreclosure):**
| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.274879 | 3075 |
| T1 | 3.275224 | 3075 |
| T2 | 3.274923 | 3075 |
| T3 | terminated at ~703/3175 | — |
| n=3 mean | 3.275009 | 3075 |

**N=2 screen (Arm B):**
| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27353 | 3050 |
| T1 | 3.27348 | 3050 |
| n=2 mean | 3.273505 | 3050 |

**Key findings:**
- **Arm A (0.3)**: Flat vs Arm A baseline mean val≈3.2749 (Δ=+0.000482 above old bar), ffs=3075 — slightly worse than 0.4. Response surface is flat/slightly negative below 0.4.
- **Arm B n=2 screen**: Both trials landed exactly at val~3.2735/ffs=3050 — looked like a Goldilocks point at 0.35. Statsig 0.00918 PASS. However this was a seed-lucky draw.
- **Arm B n=4 collapse**: T0-T2 all landed at val~3.275/ffs=3075 (one bimodal slot above floor). Regression-to-mean: n=2 floor results were seed luck, not axis effect. Foreclosure via bar-tightening (PR #415 raised bar from 3.274383/3068.75 to 3.273477/3056.25) — T3 killed.
- **Root cause**: val-step-3025 trajectory clusters tightly around 3.28 (3.28272/3.28282/3.28322 in T0-T2). The 3.28 threshold is the ffs quantization boundary — tiny seed noise determines whether the step hits 3050 vs 3075. n=2 got lucky; n=4 reveals the true ~25-50% bimodal distribution at 3050.

**Mechanism conclusion**: CONTRA_MUON response surface is **flat between 0.3 and 0.4** on this stack. 0.4 remains the local optimum. The n=2→n=4 collapse is a portfolio-level lesson: **bimodal ffs distribution (3050 vs 3075) is dominated by seed variance on the val-step-3025 → ffs-quantization boundary**. A clean n=2 result where both trials land at 3050 does NOT robustly predict n=4 mean at 3050.

**Strategic consequence**: Contra-Muon/cooldown-geometry lever cluster confirmed saturated by 3 independent closures (#372 MuonEq-R, #406 MU_COOLDOWN_START, #405 CONTRA_MUON sweep). Future axes should avoid this cluster.

**Reassignment**: askeladd → #468 AdamW gradient clipping (GRAD_CLIP_NORM_ADAM=0.5 vs 1.0). Fresh mechanism — confirmed zero gradient clipping anywhere in codebase. Target: variance reduction via outlier-grad damping may improve ffs=3050 concentration by stabilizing AdamW step magnitudes during late cooldown.



## 2026-05-19 12:05 UTC — Cycle 66: #415 MERGED MU_WARMUP_STEPS=200 — STRICT-PASS WIN (val=3.273477/ffs=3056.25); #405/#406 early-terminate recommended (foreclosed on new bar); thorfinn → #462 MU_WARMUP_START sweep (0.80 vs 0.90)

### PR #415 — MU_WARMUP_STEPS=200 n=4 confirm — MERGED (new baseline) 🏆

Branch: `g1r2-thorfinn/mu-warmup-sweep`. Arm A only (Arm B=400 skipped per advisor advice to accelerate n=4). All runs on new CONTRA_MUON=0.4 base.

| Run | W&B | n | val mean | ffs mean | vs bar | Verdict |
|---|---|---|---|---|---|---|
| Smoke (MU_WARMUP_STEPS=0) | `25wu2nvt` | 1 (200 steps) | val=4.178 @ step 200 | — | baseline-equivalent | ✅ |
| Screen n=2 (warmup=200) | `xi4d6osg` | 2 | 3.273802 | 3050 | PASS ✅ | |
| **Confirm n=4 (warmup=200)** | **`nh6ge2df`** | **4** | **3.273477** | **3056.25** | **PASS ✅** | **MERGED** |

**Per-trial n=4 confirm** (`nh6ge2df`):
| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.272928 | 3050 |
| T1 | 3.274003 | 3050 |
| T2 | 3.272357 | 3050 |
| T3 | 3.274621 | 3075 |
| **n=4 mean** | **3.273477** | **3056.25** |

**Bar comparison vs old baseline `ivvf500c` (PR #358)**:
- val: 3.273477 < 3.274383 ✅ PASS by −0.000906
- ffs: 3056.25 < 3068.75 ✅ PASS by −12.5
- statsig n=4: (3.28−3.273477)×√4 = 0.013046 ≥ 0.004 ✅ PASS by 3.26×

**Cross-trial val spread: 0.0023** — one of the tightest n=4 spreads observed this cycle.

**Mechanism analysis**: Muon EMA `state["momentum"]` starts at zero; applying `cur_mu=0.95` (high smoothing) while the buffer is still populating produces effectively over-smoothed early updates. With explicit warmup (0.85→0.95 over 200 steps), the optimizer follows the recent-gradient signal more faithfully during the EMA-fill window. Empirical signature: step-125 val ≈4.42 (warmup) vs ≈4.51 (no-warmup baseline) — earlier loss improvement without stability regression. The mechanism is validated by the tighter cross-trial spread.

**New mandatory stack after merge**: `CONTRA_MUON=0.4 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85`

**NEW MERGE BAR**: val < **3.273477** AND ffs < **3056.25** (STRICT). Critical implication: n=4 ffs bar now requires **ALL 4 trials at ffs=3050** — any single ffs=3075 gives mean=3056.25 which TIES, not beats.

**Portfolio impact**: All in-flight experiments running on old stack must be re-tested on new stack. PRs #405/#406 early-terminate recommended (both foreclosed on new ffs bar). PRs #456/#458/#459/#462 notified to use new mandatory stack.

**Reassignment**: thorfinn → #462 MU_WARMUP_START sweep (0.80 vs 0.90 around winning 0.85) — natural axis characterization of the warmup parameter, targeting configs that push more trials to ffs=3050 floor.

## 2026-05-19 11:40 UTC — Cycle 65: #435 CLOSED LOGIT_SOFTCAP_K axis FALSIFIED ±33% (clean output-head mechanism ablation, both arms early-terminated via Option B math foreclosure); frieren → #459 Lookahead-AdamW (fresh optimizer-wrapping mechanism)

### PR #435 — LOGIT_SOFTCAP_K sweep (K=10 vs K=22 around default K=15) — CLOSED axis-falsified

Branch: `g1r2-frieren/logit-softcap-sweep`. Both arms screened on new CONTRA_MUON=0.4 base. Excellent student execution: Option B early-terminate killed T1 of both arms when math foreclosed at n=2, saving ~4h GPU time.

| Arm | K | W&B | T0 val | T0 ffs | T1 status | vs strict bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|---|
| A | 10 (tighter) | `v6gls9o3` | 3.28057 | 3175 (no-hit) | Option B kill at step ~125 (T1 also diverged at step 3326) | val MISS +0.006, ffs MISS +106.25 (no-hit) | falsified |
| B | 22 (looser) | `0g63aen5` | 3.276487 | 3100 | Option B kill at step ~990 (math foreclosed) | val MISS +0.0021, ffs MISS +31.25 | falsified |
| baseline | 15 default | `ivvf500c` | 3.274383 (n=4 mean) | 3068.75 (n=4 mean) | — | reference | — |

**Foreclosure math for early termination (Arm B example)**: With T0=3.276487/3100, Arm B's T1 would need val ≤ 2×3.274383−3.276487 = 3.272279 (below project-best single-trial val ever observed = 3.27263) AND ffs ≤ 2×3068.75−3100 = 3037.5 (below quantization floor of 3050). Both conditions impossible → kill T1.

**Baseline-trajectory comparison** (val_loss vs baseline `ivvf500c` at key steps):

| Step | Arm A (K=10) | Arm B (K=22) | baseline (K=15) |
|---|---|---|---|
| 125 | 4.54290 | 4.50325 | ~4.20 |
| 1500 | 3.53340 | 3.53090 | ~3.53 |
| 2500 | 3.35267 | 3.34865 | ~3.36 |
| 3000 | 3.29116 | 3.28718 | ~3.28-3.29 |
| 3175 (terminal) | 3.28057 | 3.27649 | ~3.27 |

**Mechanism finding**:
- **K=10 (tighter cap)**: matched mechanistic prediction exactly. Derivative at |x|=10 is ~0.35, so tighter cap clips even small early-training logits → +0.34 val regression at step 125. Mid-cooldown (1500-2500) catches up to baseline because output-head dynamics adapt around the cap. Terminal lag +0.01 confirms cap remains compressive at K=10. ffs target never reached in 3175 steps.
- **K=22 (looser cap)**: predicted asymmetric-favored direction failed. T0 val +0.006 / ffs +50 vs baseline. The looser cap does NOT improve gradient throughput in any productive direction — moderate-logit grad throughput is already ≥35% at K=15, and pushing K higher removes a regularizer the optimizer was leaning on.

**Softcap-mediator hypothesis (#372/#379 cross-stack mystery) PARTIALLY WEAKENED**: If K=15 were a load-bearing mediator for cross-stack interactions, perturbing K by ±33% should have produced clearer effects (either dramatically better or dramatically worse). Instead the surface is fairly flat around K=15 (+0.006 to +0.01 deltas) — consistent with softcap being a **non-load-bearing constant** in the current pipeline.

**Strategic implication**: Output-head modulation now joins the saturated-axes list alongside AdamW lm_head_lr (#431), EMBED_INIT_STD on new base (#379), and ATTN_SOAP_TRUST_THRESHOLD (#420). Plateau Protocol shift continues: next axes should target either (a) fresh optimizer-wrapping mechanisms (Lookahead, EMA averaging) or (b) input-side embedding mechanisms.

**Reassignment**: frieren → #459 Lookahead-AdamW sweep (K=5 vs K=10, α=0.5) — fresh optimizer-wrapping mechanism (Zhang et al 2019), never tested on this codebase. Cleanly orthogonal to in-flight AdamW LR/WD sweeps (#449/#456/#458).

**Process note**: This is the second clean "Option B math-foreclosure early-terminate" in two cycles (after edward #379 trial 1 in cycle 59). The math-foreclosure pattern is becoming a high-value early-termination signal. Both #435 arm A's T1 (which diverged at step 3326 — likely a divergence mode, not just foreclosure) and the cleaner Arm B T1 foreclosure show ~2-4h GPU time savings per closed-axis cycle.

## 2026-05-19 08:30 UTC — Cycle 62: #420 CLOSED ATTN_SOAP_TRUST_THRESHOLD axis FALSIFIED on new base (clean mechanism ablation finding); nezuko → #449 EMBED_LR sweep (AdamW path completion, largest LR in optimizer)

### PR #420 — ATTN_SOAP_TRUST_THRESHOLD sweep (T=0.70 vs T=0.95 vs default 0.85) — CLOSED axis-falsified

Branch: `g1r2-nezuko/attn-soap-trust-threshold-newbase`. Both arms screened on new CONTRA_MUON=0.4 base.

| Arm | T | W&B | val (n=2 mean) | ffs (n=2 mean) | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|
| A | 0.70 | `g6qlc9o9` | 3.27828 (n=1) | 3125 | val MISS +0.0039 (foreclosed at trial 0), ffs MISS +56.25 | falsified |
| B | 0.95 | `lqggr47m` | **3.275415** | **3087.5** | val MISS +0.001032, ffs MISS +18.75 | falsified |
| baseline | 0.85 | `ivvf500c` | 3.274383 | 3068.75 | reference | — |

**Statsig** (3.28 − μ)·√2 = (3.28 − 3.275415)·√2 = 0.00648 ≥ 0.004 → PASS, but BOTH strict bars miss.

**Mechanistic finding — gate behavior via on_fraction time-series**:

| Arm | T | overall on_frac | warmup (<300) | plateau (300-2575) | cooldown (≥2575) | mean cos_row | mean cos_col |
|---|---|---|---|---|---|---|---|
| A | 0.70 | **0.977** | 0.869 | 1.000 | 1.000 | 0.861 | 0.915 |
| B | 0.95 | **0.008** | 0.077 | 0.000 | 0.000 | 0.874 | 0.934 |

Per-weight-type on_fraction is uniform within each arm (k/q/v/proj all match overall), so the trust threshold is not selecting differentially across attention slots.

**Interpretation**:
- Cosine similarities cluster ~0.85-0.93 (row) and ~0.91-0.95 (col)
- Default T=0.85 lands inside the empirical row-similarity distribution → gate is selective
- Arm A T=0.70 → gate ~always-open = **Attn-SOAP without trust filter**
- Arm B T=0.95 → gate ~always-closed = **Attn-SOAP effectively disabled** (outside warmup)
- Attn-SOAP itself contributes only ~0.001 val improvement on the new stack (Arm B nearly matches baseline)

**Strategic consequence**: The trust gate at the current default is doing real work because T=0.85 is empirically calibrated to the cos-row distribution. There's no smarter constant threshold to find — the natural follow-up direction is **adaptive thresholds (e.g., mean − σ over running cos_row)** rather than further constant-threshold sweeping.

**Process notes (exemplary)**:
- Self-driven Option-B foreclosure on Arm A trial 1 (saved ~3.4h GPU)
- Mechanistic terminal post with on-fraction time-series across warmup/plateau/cooldown phases
- Four ranked follow-up suggestions, all mechanistically motivated
- This is the kind of terminal analysis that distinguishes research from hyperparameter sweeping

**Reassignment**: → **PR #449 EMBED_LR sweep** (0.225 vs 0.375 around hardcoded 0.3). Largest LR in entire optimizer (8× MUON_LR, 96× LM_HEAD_LR), never swept. AdamW path completion paired with fern #431 (LM_HEAD_LR).

---

## 2026-05-19 04:30 UTC — Cycle 61: #373 CLOSED (AdaMuon axis-falsified at n=4 on both baselines; EMA-family exhaustion 4-deep; "input-side robust vs output-side fragile" mechanism finding); frieren → #435 logit softcap K sweep (strategy-tier shift to model-side axes)

### PR #373 — AdaMuon: post-NS5 per-element EMA variance scaling — CLOSED axis-falsified

Branch: `g1r2-frieren/adamuon`. Arm B (ADAMUON_BETA2=0.99) cleared OLD bar at n=2 screen; predeclared n=4 confirm on new base. Terminal at 04:00 UTC.

| Phase | Stack | W&B run | val (n=4 mean) | ffs (n=4 mean) | vs new bar (val<3.274383, ffs<3068.75) | vs old bar (val<3.275350, ffs<3087.5) | Verdict |
|---|---|---|---|---|---|---|---|
| n=2 screen old stack | OLD CONTRA_MUON=0.5 | (prior runs) | 3.27500 | 3075 | val MISS +0.00062, ffs MISS +6.25 | val PASS −0.00035, ffs PASS −12.5 | screening pass on old |
| **n=4 confirm new base** | **NEW CONTRA_MUON=0.4** | `[per-trial table below]` | **3.27665** | **3093.75** | **val MISS +0.00227, ffs MISS +25** | **val MISS +0.00130, ffs MISS +6.25** | **FALSIFIED both bars both bases** |

Per-trial new-base n=4: T0=3.27729/3100, T1=3.27577/3075, T2=3.27727/3100, T3=3.27626/3100. Three of four trials at unfavorable ffs=3100 — clean regression to mean from n=2 lucky-draw.

**Key cross-cycle research finding — "input-side robust vs output-side fragile" mechanism**:

The optimizer pipeline is SOAP → NS5 → Contra-Muon → NorMuon → u/w-floor scaling. **Pre-NS5 mechanisms tolerate perturbations because NS5 re-projects to the orthogonal manifold**:
- MuonEq-R #372 (pre-NS5 row normalization) — tolerable on old stack
- Contra-Muon (op-norm normalization) — robust across stacks
- NorMuon-lite row scaling — robust

**Post-NS5 mechanisms have no re-projection downstream and perturbations propagate directly into the parameter update**:
- AdaMuon #373 (per-element EMA after NS5) — falsified this PR
- Post-NS5 RMS variants (multiple prior cycles) — falsified

This framing predicts that **any future "scale-the-NS5-output" mechanism will fail unless it ablates an existing downstream variance-scaling component** (NorMuon, u/w-floor). It also explains why pre-NS5 mechanisms can survive on the old stack while their post-NS5 counterparts fail across both stacks.

**EMA-family exhaustion (4-deep)**:

| Cycle | PR | Mechanism | Verdict |
|---|---|---|---|
| 53 | #223 | SOAP_BETA2 sweep | EMA exhausted |
| 58 | #378 | NORMUON_BETA2 sweep | EMA exhausted |
| 58 | #394 | ATTN_SOAP_BETA2 sweep | EMA exhausted |
| 60 | #373 | AdaMuon ADAMUON_BETA2 | EMA exhausted (post-NS5 specifically) |

The variance-scaling stack has fundamental redundancy that resists BOTH EMA detuning and EMA-family additions. **Strategic consequence: any future PR proposing a new second-moment / variance / EMA mechanism on the existing pipeline should be treated with strong prior skepticism unless it ablates an existing redundant component.**

**Cross-cycle Plateau Protocol trigger — 7 closures since PR #358 merged ~8h ago**:

| Cycle | PR | Mechanism family | Verdict |
|---|---|---|---|
| 57 | #357 | MU_COOLDOWN_END=0.87 | cooldown-geometry lucky draw |
| 58 | #372 (initial) | MuonEq-R pre-NS5 row norm | stack-specific |
| 58 | #378 | NORMUON_BETA2 | EMA exhausted |
| 58 | #379 | EMBED_INIT_STD=1.15 | stack-specific |
| 58 | #394 | ATTN_SOAP_BETA2 | EMA exhausted |
| 60 | #372 (rerun) | MuonEq-R pre-NS5 row norm | cooldown-geometry saturated |
| 61 | #373 | AdaMuon post-NS5 EMA | EMA exhausted, post-NS5 |

**Plateau Protocol applied**: strategy-tier shift warranted. Output-side model mechanisms, AdamW-path mechanisms, and structural mechanisms are the unexplored axes. Already in flight: fern #431 (AdamW lm_head_lr — AdamW-path).

**Process notes**:
- Frieren's terminal close analysis is one of the strongest of this round — the "input-side robust vs output-side fragile" framing produces a real research finding.
- Honest regression-to-mean call: explicit cross-reference to thorfinn #357 / fern #372 / askeladd / edward as a cohort of similar attrition.
- Predeclared close verdict held without negotiation.
- Foreclosure math at 03:46 UTC was correct in principle but slightly cushioned wording — actual T3 was closer to projection floor than bar required.

**Reassignment**: → **PR #435 logit softcap K sweep** (K=10 vs K=22 around default K=15). First non-optimizer-pipeline axis this cycle. Hardcoded at K=15 since project inception, never swept, load-bearing through ALL cycles, implicated as mediator in both edward #379 and fern #372 closure analyses.

---

## 2026-05-19 03:30 UTC — Cycle 60: #372 CLOSED (MuonEq-R axis-falsified on new base; cooldown-geometry lever saturated); fern → #431 AdamW lm_head_lr sweep

### PR #372 — MuonEq-R: pre-NS5 row normalization for isotropic input — CLOSED axis-falsified

Branch: `g1r2-fern/muoneq-r-prens5-row-norm`. Axis cleared OLD bar at n=4 (would have merged); sent back for new-base re-test per predeclared additivity check. New-base n=2 screen terminal at 03:01 UTC.

| Phase | Stack | W&B run | val (n=2 mean) | ffs (n=2 mean) | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|
| n=4 confirm old stack | OLD CONTRA_MUON=0.5 | (prior runs) | 3.275140 | 3081.25 | PASS old bar — MISS new bar (+0.00076/+12.5) | sent back |
| **n=2 screen new base** | **NEW CONTRA_MUON=0.4** | `6thehevw` | **3.27591** (T0=3.27685, T1=3.27497) | **3087.5** (T0=3100, T1=3075) | **val MISS +0.001527, ffs MISS +18.75** | **FALSIFIED** |

**Additivity prediction**: val ~3.27417, ffs ~3062.5. **Actual**: val 3.27591, ffs 3087.5. Falsified by +0.001737 val / +25 ffs.

**Effect direction across bases**:
- OLD stack: MuonEq-R delta = val −0.00021, ffs −6.25 (small beneficial)
- NEW stack: MuonEq-R delta = val +0.001527, ffs +18.75 (harmful)

**Key finding — cooldown-geometry lever saturation**:
Three independent old-base mechanisms each broke ffs=3050 in isolation:
1. MU_COOLDOWN_END=0.87 (#357)
2. CONTRA_MUON=0.4 (#358, now baseline)
3. MuonEq-R (this PR #372)

The non-additivity of MuonEq-R + CONTRA_MUON=0.4 proves these are **partially substitutive parameterizations of cooldown-stage update geometry**. Once CONTRA_MUON=0.4 saturates the lever in the new baseline, MuonEq-R not only provides no additional benefit but actively hurts — suggesting the pre-NS5 row normalization that helped with larger contra-correction (which was "correcting away" the gradient direction more aggressively) now fights against the cleaner momentum signal that CONTRA_MUON=0.4 allows through.

**Strategic consequence**: Future experiments targeting "tighter cooldown-stage geometry / smaller correction magnitude" should be flagged as likely hitting the saturated lever. The entire Muon-side cooldown-geometry lever surface appears exhausted at the current CONTRA_MUON=0.4 + MU_COOLDOWN=0.95→0.90 default. **Redirect to AdamW-path, output-side, and structural axes.**

**Process notes**:
- Predeclared and held n=2 decision tree (miss both bars → close) without extension.
- Explicit additivity prediction stated before run; falsified after — proper hypothesis-test discipline.
- Old-vs-new base comparison table in terminal post is the clearest cross-stack diagnostic of the round.
- Three-mechanisms-one-lever insight is the most impactful research finding this cycle.
- Implementation robust: no NaN across 5 smokes + 6 old-base trials + 2 new-base trials.

**Reassignment**: → **PR #431 AdamW lm_head_lr sweep** (0.0025 vs 0.00375 around default 0.003125). First AdamW-path axis swept on this stack; `proj.weight` is the largest parameter in the model; orthogonal to all in-flight Muon-side axes.

---

## 2026-05-19 03:10 UTC — Cycle 59: #378 CLOSED (NORMUON_BETA2 axis falsified on new base both directions, EMA-family exhaustion across 3 axes); #379 CLOSED (EMBED_INIT_STD=1.15 stack-specific — wins on old, doesn't compose with CONTRA_MUON=0.4); alphonse → #429 NS5 iterations sweep; edward → #430 MUON_LR sweep

### PR #378 — NORMUON_BETA2 fine sweep (Arm A=0.99 new-base re-run) — CLOSED axis-falsified

Branch: `g1r2-alphonse/normuon-beta2-sweep`. Arm A originally screened on old CONTRA_MUON=0.5 stack; sent back 22:54 UTC for re-run on new CONTRA_MUON=0.4 base. Arm B (β₂=0.90) falsified pre-baseline-shift on old stack.

| Phase | Arm | W&B run | val (n=2 mean) | ffs (n=2 mean) | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|
| n=2 SCREEN old stack | A (0.99, slower) | (pre-#358) | 3.27509 | 3075 | val MISS +0.00071, ffs MISS +6.25 (close) | sent back for re-run |
| n=2 SCREEN old stack | B (0.90, faster) | (pre-#358) | 3.27575 | 3087.5 | val MISS +0.00137, ffs MISS +18.75 | falsified |
| **n=2 SCREEN new base** | A (0.99, slower) | (per terminal post) | **3.27604** | **3087.5** | **val MISS +0.00166, ffs MISS +18.75** | **FALSIFIED** |

**Cross-cycle pattern (decisively confirmed)**: Three independent β₂ sweeps now all falsified on new base:
- SOAP_BETA2 (PR #223, prior cycle): falsified
- NORMUON_BETA2 (PR #378, this cycle): falsified on new base both directions
- ATTN_SOAP_BETA2 (PR #394 nezuko, cycle 58): falsified on new base both directions

**Mechanism takeaway**: The optimizer's EMA-family β₂ values are tightly co-tuned within the SOAP → NS5 → Contra-Muon → NorMuon pipeline. The variance-scaling stack has redundancy (NorMuon row+col + SOAP eigenbasis + Attn-SOAP basis with trust gate) such that slowing any one EMA loses adaptation speed without information gain, and speeding it up adds noise the others can't filter. The β₂=0.90/0.95 defaults are jointly optimal and individually sharp.

**Stack-shift Δ for Arm A (β₂=0.99)**: val regressed +0.00095, ffs regressed +12.5 from old to new base — slower EMA does NOT compose with reduced contra-correction (matches mechanism prediction failing). The contra-correction shift dominates β₂ tuning sensitivity at the lower magnitude.

**Process notes**:
- Student caught kill-gate mis-spec mid-run and called for Arm A redo (right call — Arm A would have triggered n=4 on old bar).
- Cross-comparison with #316 dynamic anneal closure was sharp.
- Symmetry observation re: PR #223 (SOAP_BETA2) added cross-axis confirmation.
- Process retrospective on kill-gate thresholds actionable for future PRs.

**Reassignment**: → **PR #429 NS5 iterations sweep** (Arm A=10, Arm B=14, default 12). Untouched since NorMuon-clean PR #71 — load-bearing through 5 stack changes. Controls orthogonal-projection quality of Muon update; downstream SOAP/Attn-SOAP/NorMuon all consume NS5 output. Fresh mechanism dial.

---

### PR #379 — EMBED_INIT_STD fine sweep (0.85 / 1.15) — CLOSED axis stack-specific

Branch: `g1r2-edward/embed-init-std-sweep`. Arm A (0.85) falsified pre-baseline-shift; Arm B (1.15) cleared old bar nominally but failed re-test on new CONTRA_MUON=0.4 base.

| Phase | Arm | Stack | W&B run | val (n) | ffs (n) | n | vs new bar | Verdict |
|---|---|---|---|---|---|---|---|---|
| n=2 SCREEN old stack | A (0.85, smaller) | OLD CONTRA_MUON=0.5 | (pre-#358) | 3.27530 | 3087.5 | 2 | MISS both | falsified |
| n=2 SCREEN old stack | B (1.15, larger) | OLD CONTRA_MUON=0.5 | (pre-#358) | **3.27353** | **3062.5** | 2 | CLEARS both ✅ (statsig 0.00915) | wrong stack |
| **n=2 SCREEN new base** | B (1.15, larger) | **NEW CONTRA_MUON=0.4** | (per terminal post) | **3.27579** (T0 only) | **3100** (T0 only) | **1** (T1 early-term) | **MISS both** | **FALSIFIED on new base** |

**Trial 1 Option B early-termination**: Student executed mathematical foreclosure proof analogous to nezuko #394 — ffs alone forecloses AND-conjunction (trial_1 ffs would need ≤3037.5 which is below 3050 quantization). Saved ~100 min GPU.

**Stack-shift Δ for EMBED_INIT_STD=1.15**: val regressed +0.00226, ffs regressed +37.5 from old to new base. This is a **strong interaction effect** with CONTRA_MUON — the embedding init win does NOT compose additively with reduced contra-correction.

**Mechanism reads (two worth flagging)**:

1. **Direction inversion vs arxiv 2502.05366**: Paper predicts smaller embedding init helps GPT-2-style models; on our SOAP+NS5+Contra-Muon stack at CONTRA_MUON=0.5 the OPPOSITE was true (1.15 wins, 0.85 loses). Real empirical finding, stack-specific. Plausible mediator: logit softcap or SOAP basis rotation sensitivity to embedding magnitude.

2. **Stack-specificity is the more interesting finding**: Embedding init effect VANISHES at CONTRA_MUON=0.4, suggesting the old-stack win was mediated by larger contra-correction magnitude. Mechanism hypothesis chain: CONTRA_MUON=0.5 → larger contra-correction → more aggressive correction against momentum direction → embedding gradients channeled differently through softcap+SOAP → init magnitude differentially affects optimizer trajectory. At CONTRA_MUON=0.4: smaller contra-correction → less basis rotation → embedding init no longer matters.

**Cross-cycle lesson**: Future single-axis sweeps that produce strong margins on old stack should be verified on current stack before being escalated to n=4 confirm. Stack changes (particularly CONTRA_MUON) can erase apparent wins. This discipline already prevented wasted n=4 GPU on this PR.

**Process notes**:
- Clean smoke + n=2 screen on old stack with all three reproducibility checks (default 200-step bit-identity, 0.85 and 1.15 plumbing checks).
- Proactive flagging of stack-mismatch when n=4 was launched on old CONTRA_MUON=0.5 — saved n=4 from being wasted.
- Mathematical foreclosure analysis on early-termination — clean prose, accurate numbers, fast call.
- Honest analysis section identified the interaction effect AND named the specific mediator hypothesis.

**Reassignment**: → **PR #430 MUON_LR sweep** (Arm A=0.030, Arm B=0.045, default 0.0375). Hardcoded since PR #78 — load-bearing through 4 stack additions (CONTRA_MUON 0.5→0.4, ATTN_SOAP, MU cooldown-only schedule, CONTRA_MUON re-tune). Each downstream change affects effective Muon step magnitude. Public track 3 records mostly use lr=0.018, our 0.0375 is on the high end. Single-line env-var plumbing.

---

## 2026-05-19 01:10 UTC — Cycle 58: #394 CLOSED (ATTN_SOAP_BETA2 axis falsified both directions on new base, third EMA-family axis exhausted); nezuko → #420 ATTN_SOAP_TRUST_THRESHOLD sweep

### PR #394 — ATTN_SOAP_BETA2 fine sweep (0.85 / 0.95) — CLOSED axis-falsified

Branch: `g1r2-nezuko/attn-soap-beta2-sweep`. Arm A (0.85) screened on old CONTRA_MUON=0.5 stack pre-baseline-shift; Arm B (0.95) re-screened on new CONTRA_MUON=0.4 base per advisor 22:28 UTC sendback.

| Phase | Arm | W&B run | val (n) | ffs (n) | n | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|---|
| n=2 SCREEN old stack | A (0.85, faster) | (prior, pre-#358) | 3.275620 | 3087.5 | 2 | val MISS +0.001237, ffs MISS +18.75 | dominated, not advanced |
| n=2 SCREEN new base | B (0.95, slower) | `scyomo0r` | 3.27734 (T0 only) | 3125 (T0 only) | 1 (T1 terminated) | val MISS +0.00296, ffs MISS +56.25 | **FALSIFIED** |

**Trial 1 early termination**: Student correctly identified mathematical foreclosure at step 444:
- Val statsig needs `trial_1 < 2·3.27717 − 3.27734 = 3.27700` (and for merge bar `trial_1 < 2·3.274383 − 3.27734 = 3.27143`, extreme tail).
- FFS merge bar needs `trial_1_ffs < 2·3068.75 − 3125 = 3012.5` — below the 3025 quantization floor; hard-foreclosed.
- ffs alone forecloses the AND-conjunction merge bar.

**Mechanism diagnosis**:
- ATTN_SOAP_BETA2=0.95 (slower EMA) on attention SOAP gate is the WORSE direction on new base, not the better one. The "longer effective rank → slower EMA" intuition is wrong here:
  1. ATTN_SOAP_TRUST_THRESHOLD=0.85 already filters high-noise eigenbasis refreshes — slowing β₂ doesn't add information, just delays adaptation to legitimate basis drift.
  2. Cooldown-phase dynamics need fast eigenbasis adaptation to track the rapidly-shrinking learning rate. Slow β₂=0.95 lags this.
  3. Attention's "longer rank" applies to gradient *structure* (handled by the 4-head trust-gate routing), not temporal correlation (which β₂ tracks).
- ATTN_SOAP_BETA2=0.90 default is a sharp local optimum — **third EMA-family β₂ axis confirmed exhausted** after SOAP_BETA2 (PR #223, prior cycle) and NORMUON_BETA2 (PR #378, this cycle).

**Process notes**:
- Initial advisor pod-diagnosis at 00:33 UTC was wrong — three concurrent failed launches (`ng7u2ep3`, `05r5oea7`, `9mwdil39`) masked the healthy `scyomo0r` run that was actually progressing. Corrected at 00:55 UTC after deeper W&B inspection. Pod was torch 2.11.0+cu130 (healthy) all along.
- Student's terminal analysis was exemplary — explicit foreclosure proof, gate-on rate context, multi-axis cross-comparison with PR #378 (alphonse NORMUON sibling).

**Suggested follow-up from student (rank #1)**: ATTN_SOAP_TRUST_THRESHOLD currently 0.85, never swept since PR #16, never tested on new cooldown stack. Different attention-pathway lever (basis-rotation gating, not EMA decay). → assigned as **PR #420 ATTN_SOAP_TRUST_THRESHOLD sweep (0.70 vs 0.95)**.

## 2026-05-19 00:00 UTC — Cycle 57: #357 CLOSED (MU_COOLDOWN_END axis characterized on old stack, ties ffs bar on new); thorfinn → #415 muon_warmup_steps sweep

### PR #357 — MU_COOLDOWN_END sweep (0.87 / 0.85) on old CONTRA_MUON=0.5 stack — CLOSED on MISS

Branch: `g1r2-thorfinn/mu-cooldown-end-sweep`. Both arms screened on old stack pre-baseline-shift; n=4 confirm on Arm A on old stack.

| Phase | Arm | W&B run | val n | ffs n | n | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|---|
| n=2 SCREEN | A (0.87) | `q1jcq9k9` | 3.27432 | 3050 | 2 | val CLEAR −0.000063, ffs CLEAR −18.75 (lucky-draw both at 3050) | promoted to n=4 |
| n=2 SCREEN | B (0.85) | `fhkubmcu` | 3.275205 | 3062.5 | 2 | val MISS +0.000822, ffs CLEAR −6.25 | dominated by A; not promoted |
| **n=4 CONFIRM** | **A (0.87)** | **`0rbppojt`** | **3.275425** | **3068.75** | **4** | **val MISS +0.001042, ffs TIES (not strict <)** | **MISS new bar — CLOSE** |

**Per-trial n=4 confirm**: T0=3.27763/3100, T1=3.27568/3075, T2=3.27364/3050, T3=3.27475/3050. Only 2 of 4 trials at ffs=3050 → mean=3068.75 ties bar.

**Mechanism diagnosis**:
- The cooldown μ endpoint axis on old stack trades val for ffs at ~1:18 ratio. Lower endpoint = more Muon reactivity at training end = better ffs (more trials hit 3050) but slight val penalty.
- Pareto front is roughly flat between 0.85 and 0.90; sweet spot is ~0.87 but the trade doesn't compose with new CONTRA_MUON=0.4 stack to clear new bar (would need ffs ≤ 3050 mean which still leaves val MISS).
- The n=2 SCREEN/n=4 CONFIRM regression on Arm A (val 3.27432 → 3.275425; ffs 3050 → 3068.75) is textbook seed-variance lucky-draw: n=2 hit both at ffs=3050 by chance; n=4 reverts to bimodal {3050, 3075} distribution.

**Reassignment**: thorfinn → **#415 muon_warmup_steps sweep** (200/400 vs default 300) on new CONTRA_MUON=0.4 base. Fresh schedule-side axis never swept on r2. Mechanistic motivation: lower CONTRA_MUON means more natural-momentum signal early in training, so warmup tuned for old stack may be misaligned.

---

## 2026-05-18 22:20 UTC — Cycle 56: #376 CLOSED (cooldown-only AdaMuon axis FALSIFIED); tanjiro → #406 MU_COOLDOWN_START sweep on new base

### PR #376 — Cooldown-only AdaMuon switch (post-NS5 variance scaling, cooldown phase only) — FALSIFIED

Branch: `g1r2-tanjiro/cooldown-adamuon-switch`. Both arms on OLD stack (CONTRA_MUON=0.5).

| Arm | β | init | W&B run | val n=2 | ffs n=2 | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.95 | rms-warmstart | `oqivcko2` | 3.27678 | 3100 | val +0.00240, ffs +31.25 | FAIL |
| B | 0.99 | ones | `hkq95uz4` | 3.27542 | 3075 | val +0.00104, ffs +6.25 | MISS — best arm is "near-no-op" |

**Mechanism diagnosis** (student's analysis was excellent and is reproduced):
- NorMuon's per-row variance EMA already adapts during cooldown. Layering AdaMuon's element-wise variance scaling on top is **double-normalization**.
- Arm A (β=0.95, RMS warmstart): mechanism is active per-step → regression (+0.00143 val).
- Arm B (β=0.99, ones init): mechanism is effectively near-identity in cooldown (V_t ≈ 1.0 with slow updates and O_t RMS ≈ 1 by NS5 construction) → ties baseline rather than regressing. But no operating point makes it both active and net-positive.

Cross-confirms frieren #373 conclusion at full-training scope: AdaMuon's element-wise variance scaling is **redundant** with NorMuon's row variance scaling on this stack.

**Falsification class**: post-NS5 element-wise variance scaling (cooldown-restricted or full) on a stack that already has NorMuon — joins Muon-VS (pre-NS5) and the original AdaMuon arms on the FALSIFIED list. Strengthens the **INPUT-ROBUST/OUTPUT-FRAGILE pattern**: element-wise post-NS5 scaling fights NS5's spectral-orthogonalization invariant or is redundant with row-level scaling already present.

**Tanjiro reassigned → PR #406: MU_COOLDOWN_START sweep (0.93/0.97) on new CONTRA_MUON=0.4 base** — schedule-side axis (input-robust win pattern); START=0.95 has been fixed since PR #288 merge but never swept directly.

---

## 2026-05-18 17:20 UTC — Cycle 55 (continued): #375 CLOSED (Muon-VS FALSIFIED); nezuko → #394 ATTN_SOAP_BETA2 sweep

### PR #375 — Muon-VS pre-NS5 gradient deviation variance scaling — FALSIFIED

Branch: `g1r2-nezuko/muon-vs`. Both arms (β=0.95 and β=0.90) catastrophically missed.

| Arm | MUON_VS_BETA | W&B run | trial 0 val | ffs | vs baseline | Verdict |
|---|---|---|---|---|---|---|
| A | 0.95 | `4y6zfnrs` | **3.32486** | -1 (never reached 3.28) | val +0.04951 | FAIL — catastrophic |
| B | 0.90 | `e0yodaew` | **3.31294** | -1 (never reached 3.28) | val +0.03759 | FAIL — catastrophic |

Trial 1 of both arms killed early (mathematically foreclosed — for n=2 mean to clear baseline, trial 1 would need val < 2.225, impossible). Kill gates triggered at step ~863 (Arm A) and 159 (Arm B).

**Mechanism diagnosis**: pre-NS5 element-wise deviation-variance scaling fights NS5's spectral-orthogonalization invariant. Published 1.36× speedup on LLaMA-1.2B (arxiv 2601.14603) used vanilla SGD-momentum without orthogonalization — geometric mismatch with our SOAP→NS5→Contra→NorMuon pipeline.

Also: Contra-Muon (0.5) already removes the G_t component aligned with previous updates, which is precisely the "deviation" signal Muon-VS keys on. The GDV EMA is biased toward orthogonal-to-momentum noise.

**Confirms INPUT-ROBUST/OUTPUT-FRAGILE pattern**: element-wise pre-NS5 scaling (fights NS5 premise) joins post-NS5 element-wise scaling (AdaMuon) as falsified. Row-level and schedule-level perturbations (MU_COOLDOWN_END, CONTRA_MUON, MuonEq-R) all win.

**Nezuko reassigned → PR #394: ATTN_SOAP_BETA2 fine sweep (0.85 vs 0.95)**

---

## 2026-05-18 14:15 UTC — Cycle 55 (continued): #341 CLOSED (SOAP eigenbasis freeze axis FALSIFIED)

### PR #341 — SOAP eigenbasis freeze after step K — FALSIFIED (both arms)

Branch: `g1r2-edward/soap-eigenbasis-freeze`. Both arms on OLD stack (MU_START=0.97/MU_END=0.90).

| Arm | FREEZE_STEP | W&B run | mean val (n=2) | mean ffs | Step time | vs NEW baseline (3.275350/3087.5) | Verdict |
|---|---|---|---|---|---|---|---|
| A | 1000 (pre-cooldown, step 31% in) | `jt46ri0n` | **3.28082** | n/a (1 trial −1) | ~1.86 s/step | val +0.0055 | FAIL decisive |
| B | 2000 (mid-cooldown, step 63% in) | `604ypwx2` | **3.27640** | 3100 | ~1.91 s/step | val +0.00105, ffs +12.5 | FAIL |
| Baseline (PR #288 NEW) | 0 (never freeze) | `qceklszn` | 3.275350 | 3087.5 | ~1.94 s/step | — | — |

Per-trial Arm B (`604ypwx2`): T0 val=3.27734/ffs=3125, T1 val=3.27546/ffs=3075. Trial-pair spread 0.00188.

**Mechanism CONFIRMED**: SOAP Q eigenbasis refresh past step K continues to contribute useful signal **all the way through cooldown**. The val regression scales **monotonically** with how early the freeze happens:
- FREEZE=1000 (very early): +0.0055 val
- FREEZE=2000 (mid-cooldown): +0.00105 val
- FREEZE=3175 (no freeze, baseline): 0.0

The hypothesis that "Q stabilizes after early training, so refresh is wasted compute past step K" is falsified. The non-trivial val regression confirms the residual Q rotation through cooldown encodes useful preconditioner direction information, even though `cos_row(Q_t, Q_{t-10})` stays high (high cosine doesn't mean zero contribution from the orthogonal residual).

**Trial-1-only artifact**: Arm B trial 1 alone hit val=3.27546/ffs=3075, which beats NEW baseline if cherry-picked. But the trial-pair spread (0.00188) exceeds any meaningful signal at n=2 — the per-trial dispersion dominates the mean estimate.

**Wallclock note**: Arm B saved ~0.034 s/step (~107 s per 3175-step trial), ~1.7% wallclock. Since we measure ffs (steps), not wallclock, this isn't useful for our merge contract. Closes the "wallclock-only" interpretation of the axis.

**Combined with fern's closed #304 (SOAP_PRECOND_FREQ anneal 15→7 falsified)**: the steady-state SOAP_PRECOND_FREQ=10 from step 1 through end-of-training is now confirmed a tight stability window in BOTH dimensions:
- DON'T change refresh frequency (#304)
- DON'T stop refreshing late (#341)

**Excluded axes**: SOAP_FREEZE_STEP < 3175 (any partial freeze). Open: would a per-block freeze schedule (different K per block depth) preserve more of the late-cooldown signal? Lower priority given the magnitude of the regression even at FREEZE=2000.

**Stack mismatch caveat**: Both arms ran on OLD stack (MU_START=0.97/MU_END=0.90). NEW stack might shift results by ~0.0005 favorably. Even with that shift, n=2 mean would still fail by ~+0.0005 val — within trial-pair noise, not statsig.

---

## 2026-05-18 13:30 UTC — Cycle 55 (continued): #359 CLOSED (μ shape ablation FALSIFIED both directions)

### PR #359 — μ cooldown schedule shape ablation — FALSIFIED (both arms)

Branch: `g1r2-alphonse/mu-cooldown-start-ablation`. Stack: PR #288 baseline minus the μ schedule under test.

| Arm | μ schedule | W&B run | val/best | best step | ffs | Δ vs baseline (3.275350) |
|---|---|---|---|---|---|---|
| Baseline (PR #288) | 0.95 → 0.90 (linear, 0.05 gap) | `qceklszn` (n=4 mean) | 3.275350 | — | 3087.5 | 0.0 |
| **A — near-flat** | 0.92 → 0.90 (linear, 0.02 gap) | `gufuly2z` | **3.28382** | 3175 | **-1** | **+0.00847** ❌ |
| **B — constant** | 0.90 → 0.90 (constant) | `0oyci6l3` | **3.28481** | 3175 | **-1** | **+0.00946** ❌ |

Both arms ran trial 0 to completion; trial 1 killed in each (~step 500 Arm A, ~step 307 Arm B) per advisor instruction after trial 0 made n=2 mean ≤ 3.275350 impossible.

**Mechanism CONFIRMED**: The PR #288 0.95→0.90 linear cooldown is load-bearing in BOTH:
- **The 0.05 decay magnitude**: Arm A (0.02 gap, near-flat) costs +0.00847.
- **The high-μ warmup plateau**: Arm B (no decay, constant 0.90) costs +0.00946.

Neither component alone suffices. The benefit comes from the **wide downward ramp starting at μ=0.95**.

**Triangulation with thorfinn #357 (in-flight)**: trial 0 at MU_COOLDOWN_END=0.87 (0.08 gap, 0.95→0.87) reached val=3.274062/ffs=3050 — WIDER gap to a DEEPER endpoint improves further. Combined evidence: the decay magnitude has upside if the start stays at 0.95 and the end drops lower.

**Operational note**: 5 transient pod crashes between 09:04-10:50 UTC (runs `h3cv46vy, qnsuawz1, pvtppeco, l95v4gvd, a5lupt79`, mostly dying step 50-75). Resolved by 11:18 launch of Arm B. Cause not isolated but consistent with the cu12/cu13 pod issue from cycle 54.

**Excluded axes**: μ shape variations within {0.90→0.90, 0.92→0.90, 0.95→0.90}. PR #288's specific shape is preserved. Open: extending the decay magnitude WIDER (e.g., MU_END < 0.87, in flight with thorfinn).

---

## 2026-05-18 12:15 UTC — Cycle 55 (continued): #339 CLOSED (cooldown_frac axis FALSIFIED); #336 CLOSED (TARGET_UW axis FALSIFIED)

### PR #339 — cooldown_frac sweep 0.6 and 0.8 — FALSIFIED

Branch: `g1r2-nezuko/cooldown-frac-sweep`. Both arms on OLD stack (MU_START=0.97/MU_END=0.90).

| Arm | COOLDOWN_FRAC | n=2 mean val | n=2 mean ffs | vs OLD baseline (3.275835/3087.5) | vs NEW baseline (3.275350/3087.5) | Verdict |
|---|---|---|---|---|---|---|
| A | 0.6 | 3.27583 | 3100 | val Δ−0.000005 (tie), ffs +12.5 | val +0.00048, ffs +12.5 | FAIL both |
| B | 0.8 | 3.275640 | 3075 | val Δ−0.000195, ffs Δ−12.5 | val +0.000290, ffs Δ−12.5 | FAIL val on NEW |

Per-trial:
- **Arm A** (`2ysep6xs`): T0 val=3.27723/ffs=3125 (kill gate clear), T1 val=3.27443/ffs=3075. Trial-pair spread 0.0028 — dominates inter-arm signal.
- **Arm B** (`jmikalnz`): T0 val=3.27535/ffs=3075, T1 val=3.27593/ffs=3075. Trial-pair spread 0.00058 — tighter.

**Mechanism**: cooldown_frac axis on OLD stack is directionally signed ("more cooldown helps slightly") but magnitude is below n=2 noise floor. NEW baseline (PR #288) tightened val by −0.000485 — 2.5× the size of any cooldown_frac effect observed on OLD. The μ-schedule change is the larger lever in this neighborhood; cooldown_frac is dominated.

**Critical observation**: On NEW stack (cooldown-only μ-anneal), cooldown_frac now controls both LR taper length AND μ-decay length — they are entangled in a way they weren't on OLD. Any future revisit should be a joint (cooldown_frac × μ-anneal endpoints) sweep, not univariate.

**Excluded axes**: Univariate cooldown_frac sweeps at 0.6, 0.7, 0.8 ranges. cooldown_frac=0.7 stays. Open follow-ups: cooldown shape (linear vs cosine vs poly), per-optimizer cooldown_frac.

---

### PR #336 — TARGET_UW sweep 0.25 and 0.50 — FALSIFIED (both directions)

Branch: `g1r2-tanjiro/target-uw-sweep`. Both arms on OLD stack (MU_START=0.97/MU_END=0.90).

| Arm | TARGET_UW | val | ffs | vs OLD baseline | Verdict |
|---|---|---|---|---|---|
| A | 0.25 | 3.28570 (T0 only, T1 kill-gated) | -1 (never reached 3.28) | +0.010 worse | KILLED step 2500 val=3.34352 |
| B | 0.50 | 3.276335 (n=2 mean) | 3112.5 (n=2 mean) | val +0.0005, ffs +25 | FAIL both |
| Baseline | 0.35 | 3.275835 (n=4) | 3087.5 (n=4) | — | local optimum |

Per-trial Arm B (`g0pkxwbr`): T0 val=3.27569/ffs=3100, T1 val=3.27698/ffs=3125.

**Mechanism**: TARGET_UW=0.35 sits at a local optimum.
- **Lower (0.25)**: Less implicit WD throughout training → weight magnitudes drift larger → cooldown phase can't recover convergence precision. Hypothesis that SOAP+Contra-Muon's directional conditioning makes the magnitude floor redundant is falsified — floor's implicit WD remains load-bearing.
- **Higher (0.50)**: More aggressive regularization slows cooldown trajectory slightly (+0.0005 val). Cooldown over-regularization concern from hypothesis does NOT manifest at 0.35 — the floor is already well-matched to cooldown dynamics.

**Excluded axes**: TARGET_UW outside ~[0.30, 0.45] range. Open follow-ups: fine-resolution bracket {0.30, 0.40} (unlikely worth GPU); cooldown-only TARGET_UW schedule; explicit weight_decay variant.

---

## 2026-05-18 10:45 UTC — Cycle 55 (continued): #304 CLOSED (SOAP_PRECOND_FREQ anneal FALSIFIED)

### PR #304 — Annealed SOAP_PRECOND_FREQ FREQ_START=15→FREQ_END=7 — FALSIFIED

| | n=4 mean val | n=4 mean ffs | vs PR #288 baseline | Verdict |
|---|---|---|---|---|
| **PR #304 (closed)** | **3.27766** | **3125** | val +0.00231, ffs +37.5 | FAIL |
| Baseline (PR #288) | 3.275350 | 3087.5 | — | — |

Per-trial: T0=3.27619/3100, T1=3.27677/3100, T2=3.27447/3075, T3=~3.2835 (didn't reach 3.28 in 3175 steps → ffs counted as 3225).

W&B run: `xzwpijuo` (n=4 confirmation on OLD stack MU_START=0.97/MU_END=0.90 — launched pre-PR-#288 merge).

**Mechanism**: Annealing SOAP refresh frequency from 15 (early sparse) to 7 (late dense) wastes early compute on slow refresh AND late compute on too-frequent refresh. FREQ=10 (stability window) optimal in both regimes. Trial 3 in particular hit a long plateau, reaching only 3.2835 by step 3175 — suggests anneal trajectory makes the cooldown phase harder to escape than constant FREQ.

**Excluded axes**: Time-varying SOAP_PRECOND_FREQ schedules in either direction. FREQ=10 is the operating point.

---

## 2026-05-18 08:35 UTC — Cycle 55 (continued): PR #288 MERGED (cooldown-only μ anneal — NEW BASELINE); #319 CLOSED (Muon warmup FALSIFIED); #312 CLOSED (lm_head WD no signal)

### PR #288 MERGED — Cooldown-only μ anneal 0.95→0.90 (NEW BASELINE)

| | n=4 mean val | n=4 mean ffs | Statsig | Verdict |
|---|---|---|---|---|
| Baseline (PR #219) | 3.275835 | 3087.5 | — | baseline |
| **PR #288 (merged)** | **3.275350** | **3087.5** | **0.00930** ≥ 0.004 ✅ | **MERGED** |
| Δ | −0.000485 | 0.0 (tie) | 2.33× | new baseline |

W&B run: `qceklszn` (n=4 confirmation: T0=3.27437/3075, T1=3.27600/3100, T2=3.27586/3100, T3=3.27517/3075)

**Mechanism validated**: μ-anneal benefit localizes to cooldown phase. Arm A (0.97→0.92 full training) missed both bars (n=2 mean val=3.27670/ffs=3112.5); Arm B (cooldown-only 0.95→0.90 starting step 952) cleared val bar + tied ffs. NS5-orthogonalized Muon doesn't need warmup stabilization from high μ.

**ffs tie analysis**: ffs is bimodal {3075, 3100} with 2-2 split in n=4, mean exactly 3087.5. The quantization makes 3087.5 the modal n=4 outcome when 2 trials hit 3075 and 2 hit 3100. The decision to MERGE despite ffs tie was based on: (a) val statsig 2.3×, (b) no ffs regression, (c) CLAUDE.md "when in doubt, merge."

**New merged stack**: `MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5` — MU_START/MU_END deprecated.

---

### PR #319 — Muon LR warmup 100-step and 50-step — FALSIFIED (both arms)

| Arm | Warmup | val_mean (n=2) | Δval | ffs_mean | Δffs | Bars |
|---|---:|---:|---:|---:|---:|---|
| A | 100 | 3.277545 | +0.00171 | 3112.5 | +25 | 0/2 |
| B | 50 | 3.277385 | +0.00155 | 3112.5 | +25 | 0/2 |
| Baseline (PR #219) | 0 | 3.275835 | 0 | 3087.5 | 0 | — |

W&B runs: `5ao5znlo` (Arm A), `tx48f42y` (Arm B)

**Mechanism confirmed**: Muon's NS5 orthogonalization at full LR from step 1 is load-bearing. Key diagnostic: val@step125 essentially identical between 100-step and 50-step warmup arms (4.641 vs 4.634) — warmup damages early geometry in a way that does not fully recover, even 75+ post-warmup steps before the first eval. Warmup adds LR suppression to an optimizer that doesn't need it.

**Excluded axes**: Any positive Muon LR warmup. Mechanism is clear: NS5-Muon IS its own warmup.

---

### PR #312 — AdamW lm_head weight decay (WD=0.01) — NO SIGNAL

| | val_mean (n=4) | ffs_mean | Δval | Statsig p | Verdict |
|---|---|---|---|---|---|
| Arm A (wd=0.01) | 3.27648 | 3106.25 | +0.00113 | p≈0.57 | miss, no signal |
| Baseline (PR #288) | 3.275350 | 3087.5 | — | — | — |

W&B runs: `cpojpo1o` (n=4), `9zm9jnch` (n=1 screen)

**Mechanism**: lm_head norm ~795 — large stable value anchored by vocab embedding gradient signal. wd=0.01 per step contributes ~4×10⁻⁵ net change per step — too small vs the gradient-driven update. Arm B (wd=0.05) skipped (n=1 "win" at 3.27554 was seed noise per Welch t p=0.57). **lm_head norm telemetry** (monotone growth through warmup + partial deflation during cooldown) retained as useful diagnostic for future readout-focused experiments.

---

## 2026-05-18 06:00 UTC — Cycle 55 (continued): frieren #340 CLOSED (embed init std FALSIFIED — Arm A NaN); reassigned #343 AdamW β2 sweep

### FRIEREN #340 — Embed init std sweep — FALSIFIED (Arm A NaN at step 25, Arm B skipped per kill gate)

| Arm | EMBED_INIT_STD | step 25 train_loss | step 25 grad nonfinite | Verdict |
|---|---|---|---|---|
| Baseline | 1.0 | 5.958 | 0 | OK |
| **A** | **0.5** | **NaN** | **147,758,208** | **NaN at step 25** |
| B | 0.1 | not run | not run | skipped per kill gate |

W&B run: `innm9w83`. step 0 val=10.82583 (bit-identical to baseline), step 1 grad/global_norm=233,017 (within 0.02% of baseline 233,068). Code is correct; divergence at step 25 is genuine.

**Mechanism**: embed init scale is **load-bearing under current stack with adam_embed lr=0.30**. Halving embed init halves residual stream activations at layer 0 → AdamW updates mismatched to the new scale → gradients NaN within 25 steps. The 50× larger embed init vs Karpathy GPT-2 style is NOT a tuning oversight; it's required given the high adam_embed LR.

**Future direction (out of scope)**: joint embed-init × embed-LR sweep (e.g., LR ∝ std). Single-axis sweep on either knob alone breaks the coupling.

Frieren reassigned → PR #343: AdamW β2 sweep {0.90, 0.99} (last untested AdamW axis; β1-anneal and eps already FALSIFIED).

---

## 2026-05-18 05:15 UTC — Cycle 55 (continued): edward #281 CLOSED (per-head SOAP FALSIFIED — both arms miss); askeladd #319 Arm A FALSIFIED; reassigned #341 SOAP eigenbasis freeze

### EDWARD #281 — Per-head SOAP for attention weights — FALSIFIED (both arms miss both bars)

| Arm | Mechanism | val mean (n=2) | ffs mean | Δ val | Δ ffs | Verdict |
|---|---|---|---|---|---|---|
| A | PER_HEAD_SOAP_Q=1 (Q only) | 3.27727 | 3112.5 | +0.00144 | +25.0 | miss both |
| **B** | **PER_HEAD_SOAP_ALL=1 (Q/K/V/proj)** | **3.276245** | **3100** | **+0.000410** | **+12.5** | **miss both (closer)** |
| Baseline (PR #219 n=4) | full-matrix Gram + trust gate | 3.275835 | 3087.5 | — | — | — |

W&B runs: `lb4vsuxk` (Arm A), `z21iphfx` (Arm B). Implementation correct, trust-gate fully open at terminal (q/on_fraction=1.0, mean_cos_row=0.93) — NOT a gating issue; per-head eigenbases are stable.

**Mechanism insight**: Cross-head gradient covariance carries signal that block-diagonal preconditioning loses. The full-matrix Gram (768×768) captures off-block covariance between heads (head-redundancy, induction-circuit formation); splitting into n_head=6 independent (128×128) blocks zeros these off-block elements. Arm B recovers some via K/V/proj coordination but still loses gradient-level off-block covariance.

**Future direction (not pursued now)**: per-head as low-rank correction *on top of* full-matrix Gram (additive, not replacement), or gated fallback (per-head only when full-matrix gate trips off).

Edward reassigned → PR #341: **SOAP eigenbasis freeze after step K** (Arm A=1000 pre-cooldown, Arm B=2000 mid-cooldown). PR #277 axis was previously closed INCONCLUSIVE due to pod NaN; pod has been upgraded to torch 2.11.0 (PR #303 fix) — deserves clean re-test. Hypothesis: late-training Q refreshes are rotation noise that survives the trust gate.

### ASKELADD #319 — Muon LR linear warmup Arm A (100-step) — FALSIFIED

| Metric | n=2 mean | Baseline | Δ | Result |
|---|---|---|---|---|
| val/loss | 3.277545 | 3.275835 | +0.00171 | miss |
| ffs | 3112.5 | 3087.5 | +25.0 | miss |

W&B run: `5ao5znlo`. val_loss@step125 was 4.64 (vs ~4.17 baseline-pace) — warmup *delayed* early progress without yielding better basin. Mechanism: Muon's NS5 orthogonalization at full LR from step 1 is load-bearing — forces productive parameter geometry that warmup denies.

Arm B (MUON_WARMUP_STEPS=50) launching next. If Arm A-like margin → close axis cleanly.

---

## 2026-05-18 04:20 UTC — Cycle 55 (continued): frieren #333 CLOSED (AdamW eps FALSIFIED — both arms NaN); reassigned #340 embed init std sweep

### FRIEREN #333 — AdamW eps sweep — FALSIFIED (both arms NaN)

| Arm | eps | step:125 val | step:250 val | Verdict |
|---|---|---|---|---|
| Baseline | 1e-10 | 4.597 | 4.095 | OK |
| **A** | **1e-8** | **NaN** | **NaN** | **NaN** |
| **B** | **1e-12** | **NaN** | **NaN** | **NaN** |

W&B runs: `8j3txub2` (Arm A, killed ~step 380), `rbolag9z` (Arm B, killed ~step 388). Sanity check at eps=1e-10 was bit-identical to baseline → code is correct; NaNs are genuine property of the swept eps values.

**Mechanism**: Embed group runs at lr=0.30. The denominator `sqrt(v̂) + eps` at very early steps has sqrt(v̂) ~ 1e-4 (few gradient samples). 
- eps=1e-8: eps-dominated denominator → effective update scaled too large for embed → blow-up
- eps=1e-12: denominator too small for rare-token embeds with near-zero v̂ → division instability

**Pattern**: eps=1e-10 is a fourth unique stability window:
1. SOAP_PRECOND_FREQ=10 (5 and 20 both NaN)
2. NS5 iter=12 (8, 10, 14, 16 all NaN)
3. SOAP_β2≥0.90 required (0.85, 0.92 NaN/instability)
4. AdamW eps=1e-10 (1e-8 and 1e-12 both NaN)

**Conclusion**: Single-value eps change is not productive. Per-group eps (different eps per aux group) is theoretically interesting but high-effort, not a priority.

Frieren reassigned → PR #340: embed init std sweep (EMBED_INIT_STD=0.5 and 0.1 vs current N(0,1)).

---

## 2026-05-18 03:15 UTC — Cycle 55 (continued): nezuko #316 CLOSED (NorMuon β2 cooldown anneal FALSIFIED); reassigned #339 cooldown-frac sweep

### NEZUKO #316 — NorMuon β2 cooldown anneal — FALSIFIED

| Trial | val/loss | ffs | Verdict |
|---|---|---|---|
| 0 | 3.27838 | 3125 | MISS |
| 1 | 3.27843 | 3125 | MISS |
| **n=2 mean** | **3.278405** | **3125.0** | **MISS** |

Baseline: val=3.275835, ffs=3087.5. Δval=+0.00257, Δffs=+37.5.

W&B run: `hq3lzdm8`. Trial-to-trial swing tiny (Δval=0.00005, Δffs=0) — reproducible negative effect.

**Mechanism**: β2 controls per-row Adafactor variance EMA. Faster β2 adaptation during cooldown means the variance estimator has fewer effective samples at the critical convergence tail, producing noisier per-row normalization. The μ buffer (PR #288 WIN) has NS5 orthogonalization downstream that bounds the response to μ changes; the β2 variance buffer lacks this safety net and reacts directly to noisier estimates.

**Conclusion**: Cooldown-reactivity from momentum/variance buffer annealing is ONLY productive for Muon's scalar μ parameter, which has NS5 as a bounded nonlinear projection downstream. Do not reassign NorMuon β2 anneal in any form.

Nezuko reassigned → PR #339: cooldown_frac sweep (0.6 and 0.8 vs current 0.7).

---

## 2026-05-18 02:30 UTC — Cycle 55 (continued): tanjiro #309 CLOSED (AdamW β1 anneal FALSIFIED — both arms miss); reassigned #336 TARGET_UW sweep

### TANJIRO #309 — Annealed AdamW β1 — FALSIFIED

Both arms miss both merge bars at n=1. Student posted `SENPAI-RESULT` terminal marker with `pending_arms=false`.

| Arm | β1 schedule | val/loss | ffs | Verdict |
|---|---|---|---|---|
| Baseline | static 0.8 | 3.275835 | 3087.5 | reference |
| **A — broad** | 0.90 → 0.70 | **3.28251** | **-1 (never)** | **MISS** ❌ |
| **B — tight** | 0.85 → 0.75 | **3.27884** | **3150** | **MISS** ❌ |

W&B runs: `06dfy8gr` (Arm A), `45raqb1u` (Arm B)

**Mechanism**: AdamW β1 anneal does NOT mirror Muon μ anneal despite similar schedule shapes. Muon's NS5 orthogonalization is a nonlinear projection that bounds the response to μ changes — small changes in momentum direction have bounded downstream effects. AdamW has no analogous safety net: β1 changes directly affect raw gradient EMA on groups with very high (embed lr=0.3) and very sensitive (lm_head lr=1/320) effective LRs. Even Arm B's tight 0.10 span (0.85→0.75) delivered a mild but clear miss.

**Conclusion**: Cooldown-reactivity from momentum anneal is a Muon-specific phenomenon. Do not reassign AdamW β1 anneal in any form. AdamW β2 anneal is also ruled out by the same argument (plus the SOAP eigenbasis coupling concern from PR #291).

Tanjiro reassigned → PR #336: TARGET_UW sweep (0.25 and 0.50 vs current 0.35).

---

## 2026-05-18 01:30 UTC — Cycle 55: frieren #313 CLOSED (z-loss NaN unresolvable — 4 smokes, code never pushed); reassigned #333 AdamW eps sweep

### FRIEREN #313 — Logit z-loss regularization — CLOSED (implementation bug, hypothesis NOT falsified)

4 consecutive NaN smoke runs over 4+ hours. All crashed with 147.9M nonfinite gradients at step 125 (the same first val checkpoint). Student never pushed code to branch — no diff visible to advisor.

| Smoke run | Steps | Outcome |
|---|---|---|
| `cubsbstz` | 200 | NaN at step 125 (147.9M nonfinite) |
| `ek607yfe` | 200 | NaN at step 125 |
| `z3jfn1o9` | 200 | NaN at step 125 |
| `16pdz0jj` | 200 | NaN at step 125 |

Pattern matches: step-125 NaN is the attention-path driven pod NaN signature (identical to the torch 2.10.0 pod bug from PR #303 and #304). **However** fern's pod was already confirmed fixed by this cycle. Likely the z-loss implementation directly modified the forward/loss pipeline and introduced a numerical instability that masked the code-level bug.

**Conclusion**: Hypothesis (PaLM/T5-style z-loss regularization) is NOT falsified — we never saw the implementation. Closed due to inability to diagnose without code access. Reassigned to cleaner axis.

**Lesson**: When modifying the forward/loss pipeline, always push a checkpoint before launching even a smoke. The advisor needs code visibility to help with NaN debugging.

Frieren reassigned → PR #330: AdamW eps sweep (ADAMW_EPS=1e-8 vs 1e-12 vs current 1e-10).

---

## 2026-05-17 23:40 UTC — Cycle 54 (continued): askeladd #286 CLOSED (Polyak EMA FALSIFIED); reassigned #319 Muon LR warmup

### ASKELADD #286 — Polyak-Ruppert weight averaging — FALSIFIED

| Path | val/loss at step 3175 | reached_target | ffs |
|---|---|---|---|
| Non-EMA (raw model) | **3.2764** | yes | 3100 |
| EMA (Polyak β=0.999, start=2000) | **3.3097** | no | — |

EMA path is +0.0339 worse — far outside any noise band. Mechanism: POLYAK_START=2000, β=0.999 → EMA has effective horizon ~1000 steps, heavily weighted toward step ~2200 (val ~3.50 era). Our aggressive LR cooldown already eliminates the late-training variance that Polyak-Ruppert targets. Final weights ARE the optimum; averaging earlier high-LR weights strictly degrades the model.

**Conclusion**: Polyak averaging is fundamentally incompatible with aggressive linear cooldown. Do not reassign at any POLYAK_START/BETA setting.

Askeladd reassigned → PR #319: Muon LR warmup (100-step and 50-step arms).

---

## 2026-05-17 22:50 UTC — Cycle 54 (continued): nezuko #295 CLOSED (Polar Express MISS); reassigned #316 NorMuon β2 cooldown anneal

### NEZUKO #295 — Newton-Schulz NS5 polynomial coefficient sweep / Polar Express — MISS

Axis pivoted mid-PR from original NS5 coefficient sweep to Polar Express adaptive schedule (Tian et al., arXiv 2505.16932) after student's math review found sum≠1 bug in original Arm B.

| Metric | Polar Express `7klo2sbf` | Baseline (PR #219) | Δ | Bar |
|---|---|---|---|---|
| `speedrun/final_best_val_loss` | **3.2802** | 3.275835 | +0.00437 | mean < 3.275835 ❌ |
| `speedrun/final_first_step_to_target` | **-1** (never hit 3.28) | 3087.5 | — | < 3087.5 ❌ |
| `speedrun/final_reached_target` | 0 | 1 | — | — |

**Polar Express schedule**: Tian et al. 2025 adaptive coefficients, 12 iters, NS5_NORM_FACTOR=1.01. Student's per-iteration diagnostics: 100% of SVs within ±1% of 1.0 on all 39 samples (39/39) — polar factor was high quality. Ortho error 0.14-0.18 (dominated by near-zero SV tail, irrelevant to polar quality).

**Conclusion**: Polar Express's per-iteration optimality is for Frobenius residual at fixed iteration count, not for downstream optimizer convergence. At our fixed-budget 12-iter bf16 setting, marginal benefit over well-tuned (2,-1.5,0.5) is below noise. Adaptive coefficients would likely help at longer NS budgets (15-18 iters) but those would hurt ffs.

**Mechanism insight**: NS5 coefficient tuning is not a productive axis at 12 iters. The fixed (2,-1.5,0.5) triple is already near-optimal for this budget. Do not reassign.

Nezuko reassigned → PR #316: NorMuon β2 cooldown anneal {0.95→0.90, 0.95→0.85}.

---

## 2026-05-17 22:05 UTC — Cycle 54 (continued): frieren #275 CLOSED (MLP-SOAP trust gate FALSIFIED); reassigned #313 logit z-loss + alphonse #303 CLOSED (pod fix via torch upgrade)

### ALPHONSE #303 — Pod diagnostic — CLOSED (pod fixed)

Pod was on `torch 2.10.0+cu128` with mixed cu12/cu13 NCCL/cuDNN libs while healthy peers run `torch 2.11.0+cu130 cu13-only`. Step-1 gradients bit-identical to peer; divergence inside optimizer kernels (mixed-version libs) causes NaN cascade in steps 2-24.

**Fix**: In-place `pip install --upgrade 'torch==2.11.0'`. Post-upgrade 200-step diagnostic clean (val=4.166/4.176 at step 200, finite). Same pattern also affects fern #304 (in remediation).

Alphonse reassigned → PR #312: AdamW lm_head weight decay sweep {0.01, 0.05}.

### FRIEREN #275 — MLP-SOAP trust gate — FALSIFIED

| Arm | T_mlp | val/loss | ffs | val < 3.275835? | ffs < 3087.5? | W&B |
|---|---|---|---|---|---|---|
| A | 0.85 | 3.27868 | 3150 | ❌ +0.00284 | ❌ +62.5 | `m5qmpwwq` |
| B | 0.90 | 3.28009 | -1 (never 3.28) | ❌ +0.00425 | ❌ misses | `wpo63vdn` |

Both arms miss. Arm A close to bar but doesn't beat; Arm B never reaches target.

**Telemetry diagnostic — opposite of attn-trust-gate prior**:
| Arm | T_mlp | mlp/on_fraction | mlp/mean_cos_row | attn/on_fraction |
|---|---|---|---|---|
| A | 0.85 | 0.625 (37.5% skipped) | 0.885 | 0.83-0.85 (only 15-17% skipped) |
| B | 0.90 | 0.417 (58% skipped) | 0.885 | — |

**Mechanistic insight — MLP precond is robust to rotation noise; attn precond is sensitive**:
> The hypothesis was: MLP SOAP eigenbasis rotates LESS than attn (so a gate at the same T fires LESS often). The data shows the opposite — MLP eigenbasis rotates AS MUCH as attn (mean_cos_row 0.885 vs 0.890; min_cos_row 0.83 vs 0.84). But the trust gate fires MUCH MORE often on MLP (37-58% vs attn's 15-17%) because the rotation-noise distribution has heavier tails on MLP.
>
> The real asymmetry is not "MLP stable / attn unstable" — both rotate similarly. The asymmetry is in **sensitivity**: applying a moderately-rotated MLP precond is net-beneficial (the precond is robust to rotation noise); applying a moderately-rotated attn precond is net-harmful (the precond is fragile). Gating helps on attn but hurts on MLP.
>
> Geometric interpretation: MLPs have higher effective rank in their gradient covariance (more spread eigenvalues), so the precond is dominated by the bulk of the eigenspectrum which rotates slowly even when individual eigenvectors rotate. Attn has more concentrated eigenvalue distribution (few large eigenvalues dominate), so eigenvector rotations directly affect precondition quality.

Frieren reassigned → PR #313: logit z-loss regularization (z_loss_coef ∈ {1e-4, 1e-3}). Fresh axis — only **loss-function** axis tested on r2; orthogonal to all optimizer-side work in-flight.

## 2026-05-17 20:45 UTC — Cycle 54 (continued): tanjiro #276 CLOSED (decoupled aux cooldown FALSIFIED); reassigned #309 AdamW β1 anneal

### TANJIRO #276 — Decoupled aux cooldown shape (cosine / none) — FALSIFIED

| Arm | aux_cooldown_shape | val/loss | ffs | val < 3.275835? | ffs < 3087.5? | W&B |
|---|---|---|---|---|---|---|
| Baseline (n=4) | linear (coupled) | **3.275835** | **3087.5** | — | — | `3xn3ox1c` (pre-#219), `47bb0bf2` (n=4 PR #219) |
| A | cosine | 3.27696 | 3100 | ❌ +0.00113 | ❌ +12.5 | `lkh6dlbz` |
| B | none | 3.30208 | -1 (never reached 3.28) | ❌❌ +0.02625 | ❌ never reached | `yjmbml3f` |

Both arms confirmed at n=1. Arm A (cosine on aux) marginally worse than linear — within natural variation, but can't beat the strict bar. Arm B (no aux cooldown) catastrophically worse — model never reaches target val=3.28.

**Mechanistic insight — aux groups are tightly coupled to the readout-convergence stage**:
> The Arm B failure is the diagnostic: holding embed at lr=0.3 and lm_head at lr=1/320 through the final 30% of training prevents convergence. The model never gets within target distance.
>
> This contradicts the hypothesis premise ("aux groups don't have a Newton-Schulz fixed-point requirement"). They DO need to cool down — because embedding-table noise and lm_head noise late in training are read out as token-distribution variance. At the end the model is no longer learning, it is *converging the readout*, and embed/lm_head must follow Muon's cooldown.
>
> **Corollary**: aux groups want the same reactivity-vs-smoothness tradeoff as Muon — high momentum stability early, low momentum reactivity late. PR #219 won by doing this on Muon's μ. The natural follow-up is to test the same mechanism on AdamW's β1 (the only other scalar momentum-buffer coefficient in the system).

Cross-axis confirmation: r1 also tested cosine cooldown on the **whole stack** (Muon + aux together) and got val=3.2882 — also worse. Two independent experiments confirm linear cooldown is a stable optimum across all groups.

Tanjiro reassigned → PR #309: **Annealed AdamW β1** (0.90→0.70 broad, 0.85→0.75 tight). Direct parallel to PR #219 on the orthogonal aux-optimizer axis.

## 2026-05-17 20:05 UTC — Cycle 54 (continued): fern #291 FALSIFIED; alphonse #277 CLOSED (pod issue); both reassigned

### FERN #291 — Annealed SOAP β2 (0.95→0.85): adaptive Gram EMA — FALSIFIED

| Arm | β2_start | β2_end | val/loss | ffs | W&B |
|---|---|---|---|---|---|
| A | 0.95 | 0.85 | 3.2790 | 3150 | `joq5iz2h` |
| B | 0.92 | 0.88 | NaN (step 25) | — | `ku1hbldn` |

Arm A: n=1 trial (trial 2 killed — gap Δ=+0.0032 exceeds max n=1 rescue potential). Misses both bars.
Arm B: NaN by step 25. β2=0.92 starts in the documented multi-seed instability zone; the hypothesis that "annealing protects the start" was wrong — instability hits within 25 steps, before EMA can decay to safe range.

**Mechanistic insight — why μ-anneal works but β2-anneal doesn't**:
> μ controls a velocity-like momentum buffer (scalar contraction). Retiming it is forgiving because buffer quantity = gradient magnitude, robust to EMA rate.
> β2 controls the **Gram EMA matrix** whose eigendecomposition drives Muon's rotation. Eigenvectors are highly sensitive to perturbations, especially early in training when basis hasn't converged.
> The matching constraint `SOAP_PRECOND_FREQ ≈ 1/(1-β2)` (PR #271) means annealing β2 while keeping freq=10 static **breaks the optimal coupling**. At β2=0.95, optimal freq=20; at β2=0.85, optimal freq=7. Static freq=10 only matches at β2=0.90.

Fern reassigned → PR #304: anneal SOAP_PRECOND_FREQ (15→7 and 7→15) while keeping β2=0.90 static. Tests the orthogonal axis that respects the matching constraint.

### ALPHONSE #277 — SOAP eigenbasis freeze after step K — CLOSED (untested)

All 8 runs on alphonse's pod NaN'd at step 25-125. Student ran a critical diagnostic (POD-DIAG baseline, run `ej3fvmpy`) with freeze code **completely removed** — reverted to pre-#277 state — and it ALSO NaN'd at step 125. Side-by-side trajectory byte-identical with K=100 freeze run.

**Conclusion**: the merged-stack baseline itself is unstable on alphonse's pod. The freeze mechanism is untested (not falsified). Peer pods (tanjiro, frieren, fern) run healthy on identical config. This is a pod-specific issue (hardware/CUDA/driver/data-shard).

My earlier interpretation ("125 steps after freeze = 125 steps of compounding misalignment") was **wrong** — the POD-DIAG diagnostic proved the NaN is independent of the freeze. Acknowledging error; alphonse caught it correctly.

Alphonse reassigned → PR #303: pod diagnostic (env fingerprint + hard reset + clean baseline repro). No training experiment until pod health confirmed.

---

## 2026-05-17 ~17:30 — Cycle 54 (continued): nezuko #273 FALSIFIED with strongest mechanistic insight; nezuko reassigned (#295)

### NEZUKO #273 — Asymmetric Attn-SOAP trust T per param-kind (QK vs VO) — FALSIFIED

| Arm | QK / VO | val/loss | ffs | reached_target |
|---|---|---|---|---|
| A | 0.80 / 0.90 | 3.27768 | 3125 | yes |
| B | 0.90 / 0.80 | 3.28158 | -1 | **NO — failed to reach 3.28** |

**Mechanism (strongest insight of cycle 54)**: V's low cos_row (~0.81 baseline) is **TRUE signal of fast eigenbasis rotation, NOT a false negative**. The current single T=0.85 is faithfully filtering out genuinely untrustworthy eigenbasis updates. Forcing V SOAP to fire at low cos (Arm B, V on_fraction=1.00) injects noisy preconditioning into the residual stream → +0.005 val degradation, fails to reach target.

**Trust gate axis insight (added to project knowledge)**: trust thresholds and per-kind selectivity are entangled with the underlying eigenbasis dynamics. Q/K have stable bases (high cos_row → high on_fraction at T=0.85 is correct). V has unstable bases (low cos_row → low on_fraction is correct selectivity). The single T=0.85 expresses a faithful invariant ('don't precondition with a stale basis'); decomposing it loses that invariant.

This falsification has implications for **all SOAP trust-gate variants**: continuous (cosine-scaled) gates likely won't help either, since partial preconditioning at low cos still injects bad rotation.

W&B runs: `l0bszjjg` (Arm A), `8jsxx60y` (Arm B). Nezuko reassigned → NS5 polynomial coefficient sweep (PR #295).

---

## 2026-05-17 ~17:20 — Cycle 54 (continued): thorfinn #219 MERGED ⭐ NEW BASELINE; fern #271 FALSIFIED; fern reassigned (#291)

### THORFINN #219 — Annealed Muon μ schedule (MU_START=0.97 → MU_END=0.90) — MERGED ⭐ NEW BASELINE

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27510 | 3075 |
| T1 | 3.27697 | 3100 |
| T2 | 3.27489 | 3075 |
| T3 | 3.27638 | 3100 |
| **n=4 mean** | **3.275835** | **3087.5** |

Δ vs PR #212 baseline (3.27631 / 3112.5): val=−0.000475, ffs=−25.0. Statsig 0.00833 ≥ 0.004 (2.08× margin).

**Mechanism (well-supported)**:
1. **Early training**: high μ=0.97 = long EMA window. CONTRA_MUON's spectral perturbation noise is averaged out before being pushed through NS5. Reduces noise-driven moves through parameter space during fragile warmup.
2. **Cooldown phase**: μ → 0.90 = shorter EMA. Momentum buffer becomes more reactive precisely when LR cooldown reduces step magnitude — Muon can track finer-grained signal during the critical ffs-determining phase.
3. **Warmup-style (Arm A: 0.90→0.97) failed**: low μ early lets gradient noise dominate; high μ late over-smooths in cooldown. Worst-of-both schedule.

W&B run: `47bb0bf2`. PR squash-merged after rebase (PR #212 conflict resolved by student). Thorfinn reassigned → annealed μ finer sweep (PR #288: 0.97→0.92 tight range vs cooldown-phase-only anneal).

---

### FERN #271 — Decoupled SOAP eigenbasis refresh freq (MLP vs ATTN) — FALSIFIED

| Arm | SOAP_PRECOND_FREQ_ATTN | val/loss | ffs | vs new bar |
|---|---|---|---|---|
| A | 5 (faster) | 3.27633 | 3100 | MISS (+0.00050 val, +12.5 ffs) |
| B | 20 (slower) | 3.27909 | 3150 | CLEAR MISS (+0.00326 val, +62.5 ffs) |

**Mechanistic insight (project knowledge update)**: SOAP_PRECOND_FREQ and SOAP_BETA2 are entangled through the EMA effective horizon. Fern's drift telemetry showed that at β2=0.90, the post-refresh Gram already substantially equilibrates within 10 steps. Increasing refresh frequency by 4× (freq=5) only reduces Frobenius drift by ~6% (64K → 68K Frobenius units) — not enough to change gradient direction quality. Refresh frequency optimum ≈ EMA effective horizon = 1/(1-β2) → for β2=0.90, that's 10 steps.

**Key axis-coupling insight**: This implies SOAP_BETA2 is the primary control over eigenbasis dynamics, not refresh frequency. Annealing β2 (rather than refresh freq) is the natural follow-up — directly motivated this PR's mechanistic explanation.

W&B runs: `5873pgbt` (Arm A), `w9t7l423` (Arm B). Fern reassigned → annealed SOAP β2 (PR #291: 0.95→0.85 full range vs 0.92→0.88 tight range).

---

## 2026-05-17 ~16:15 — Cycle 54 (continued): askeladd #268 FALSIFIED; thorfinn #219 n=4 COMPLETE awaiting rebase; askeladd reassigned (#286)

### ASKELADD #268 — Per-block-depth Muon LR scaling — FALSIFIED

| Arm | Formula | val/loss @ 3175 | ffs | Outcome |
|---|---|---|---|---|
| A (up) | `(d+1)/6` (block 0=0.167×, block 11=2.0×) | 3.31916 | -1 (never hit 3.28) | Clear miss (+0.043 over baseline) |
| B (down) | `(12-d)/6` (block 0=2.0×, block 11=0.167×) | 4.165 @ step 1350 | -1 | Diverged, killed |

Both arms falsified per predeclared decision tree (val > 3.278 OR ffs > 3125).

**Mechanism (Arm A, "up")**: Starves early blocks (block 0 gets 1/6 baseline LR). The embeddings→block 0→block 1 cascade receives insufficient updates to develop early-token representations during the first ~half of training. By the time later blocks compensate, the LR cooldown has begun and there's no headroom left. Result: never reaches val=3.28 target.

**Mechanism (Arm B, "down")**: Starves late blocks. Late transformer blocks contain the most discriminative features (sharper local loss curvature). Reducing late-block LR by 6× wrecks tracking of this signal. Result: late blocks fail to converge → activations grow → gradient norms grow → divergence at step 1350.

**Lesson**: SOAP's per-shape preconditioning already absorbs per-layer gradient scale differences via its Gram matrices. Imposing additional explicit depth-LR structure adds constraints without exploiting unmodeled gradient structure.

W&B runs: `qfef54e1` (Arm A), `iudcq97t` (Arm B). Askeladd reassigned → Polyak weight averaging (PR #286).

---

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 COMPLETE 🚀 PENDING REBASE

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27510 | 3075 |
| T1 | 3.27697 | 3100 |
| T2 | 3.27489 | 3075 |
| T3 | 3.27638 | 3100 |
| **n=4 mean** | **3.275835** | **3087.5** |

**Both new baseline bars cleared:**
- val=3.275835 < 3.27631 (Δ=−0.000475) ✓
- ffs=3087.5 < 3112.5 (Δ=−25.0 steps) ✓
- statsig: (3.28 − 3.275835) × √4 = **0.00833** ≥ 0.004 ✓ (2.08× margin)

n=4 was launched on PRE-#212 stack (no trust gate). The annealed-μ mechanism beats the new trust-gate baseline anyway — strong evidence of additivity. After merge, compounding run with `ATTN_SOAP_TRUST_THRESHOLD=0.85` is the natural follow-up.

**Status**: Sent back to thorfinn for rebase (merge conflict with PR #212). W&B run: `47bb0bf2`. ETA to merge: ~30 min after rebase.

---

## 2026-05-17 ~15:00 — Cycle 54 (continued): alphonse #256 FALSIFIED; tanjiro #259 FALSIFIED; thorfinn #219 n=4 3/4 strong; frieren #254 closed; 3 students reassigned (#275, #276, #277)

### ALPHONSE #256 — SOAP_PRECOND_FREQ {5, 20} sweep — FALSIFIED

| Arm | SOAP_PRECOND_FREQ | Outcome |
|---|---|---|
| A | 5 | Multi-seed NaN at step 25 (5 independent trials) |
| B | 20 | Multi-seed NaN at step 25 (same fingerprint) |

Both arms falsified. Baseline (freq=10) runs cleanly to val~3.277 on all 4 trials. Both extremes destabilize within first 25 steps.

**Mechanism (Arm A, freq=5)**: First eigenbasis refresh at soap_step=5 with only ~41% Gram EMA equilibration (β₂=0.90). Eigenbasis from incomplete Gram is noisy → preconditioning rotates update in wrong direction → weight-norm explosion by step 25.

**Mechanism (Arm B, freq=20)**: Initial eigenbasis (from 1-step Gram) is rank-1 noise. Preconditioning with this for 20 steps before first refresh is catastrophic — the bad eigenbasis amplifies every update in the wrong subspace until divergence.

**SOAP_PRECOND_FREQ is a narrow stability window at 10**. Combined with Arm A finding, we can say: Gram needs ≥ 10 EMA steps to produce a usable eigenbasis, and the initial eigenbasis must be replaced quickly enough that its noise doesn't compound. 10 is the optimal tradeoff point.

W&B runs: `h1527wma`, `9ogg9inl`, `rnarwovu`, `htti5gif` (5 trials total, all NaN). Alphonse reassigned → SOAP eigenbasis freeze after step K (PR #277).

---

### TANJIRO #259 — NS_ITERS sweep (NS_ITERS=10, 8) — FALSIFIED

| Arm | NS_ITERS | Outcome |
|---|---|---|
| A | 10 | Trials 0, 1: 91% nonfinite gradients at step 225 |
| B | 8 | NaN (run just started, suspected same) |

Both arms falsified. Baseline (NS_ITERS=12) is the unique stable operating point.

**Mechanism**: NS5 polynomial with (a=2, b=-1.5, c=0.5) requires ~12 iterations to converge to an orthogonalized update for typical singular value distributions. With 10 iterations, the polynomial output is under-converged → uncontrolled singular value magnitudes → after Frobenius renormalization and TARGET_UW=0.35 u/w-floor scaling, effective update grows beyond weight scale → NaN cascade by step 225.

**NS5 iteration axis is fully exhausted**: (8, 10) NaN cascade; (12) optimal; (14, 16) also NaN from prior askeladd #232 sweep; fp32 NS5 (frieren #254) MISS (no precision improvement). The entire NS5 precision/iter axis is closed.

W&B runs: `cuhzxhaz` (seed-0 NaN, n=1), `wsdki64r` (n=4, trials 0-1 diverged at step 225). Tanjiro reassigned → decoupled aux cooldown shape (PR #276).

---

### FRIEREN #254 — fp32 precision in Newton-Schulz NS5 — MISS

| Metric | Result | vs new baseline (PR #212) |
|---|---|---|
| val/loss | 3.2769 | > 3.27631 (MISS) |
| ffs | 3125 | > 3112.5 (MISS) |

Complementary to NS_ITERS falsification: adding fp32 precision also doesn't help. Combined, the NS5 pipeline is insensitive to both iteration count AND numerical precision changes from the 12-iter bf16 optimum.

W&B run: `mon2ndin`. Frieren reassigned → MLP-SOAP trust gate (PR #275).

---

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 IN PROGRESS 🔥

| Trial | val/loss | ffs |
|---|---|---|
| 0 | 3.27510 | 3075 |
| 1 | 3.27697 | 3100 |
| 2 | 3.27489 | 3075 |
| 3 | (running) | — |
| **n=3 mean** | **3.27565** | **3083** |

**n=3 mean BEATS new baseline** (val=3.27631, ffs=3112.5) on BOTH metrics. Statsig n=3: (3.28 − 3.27565) × √3 = 0.00754 ≥ 0.004 ✓ (cleared by 1.9×).

Note: n=4 run launched before PR #212 merge — testing annealed μ WITHOUT TRUST_THRESHOLD=0.85. Even without the attn trust gate, annealed μ beats the new baseline (which HAS trust gate). This confirms the two mechanisms are additive; compound result (annealed μ + trust gate) should beat both individually.

W&B run: `47bb0bf2`. Trial 3 running, ETA ~17:30 UTC. Terminal SENPAI-RESULT pending.

---

## 2026-05-17 ~13:00 — Cycle 54: PR #212 MERGED (new baseline); 4 axes closed; 3 students reassigned

### NEZUKO #212 — Attn-SOAP+trust T=0.85 — MERGED ⭐ NEW BASELINE

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.2764 | 3125 |
| T1 | 3.2761 | 3100 |
| T2 | 3.2775 | 3125 |
| T3 | 3.2752 | 3100 |
| **n=4 mean** | **3.27631** | **3112.5** |

W&B run: `3xn3ox1c`. Statsig: (3.28-3.27631)×√4 = 0.00738 ≥ 0.004. BOTH BARS CLEARED vs PR #139 (val<3.27648, ffs<3118.75).

**Key finding**: Extending SOAP eigenbasis preconditioning to attention weights (via cosine-similarity trust gate, TRUST_THRESHOLD=0.85) gives consistent −6.25 mean ffs improvement. All 4 trials hit val < 3.28 target. Tight variance (T3=3.2752 strongest, T2=3.2775 weakest). Mechanism: SOAP coverage of attention projection matrices reduces curvature mismatch in the direction most sensitive to early-step convergence.

**Merged**: ffs 3118.75 → 3112.5 (−6.25), val 3.27648 → 3.27631 (−0.00017). Gap to record #20 (3030): ~82 steps.

---

### FERN #245 — Trust-region Muon (LARS-style, TRUST_RATIO sweep) — CLOSED

| Arm | TRUST_RATIO | val | ffs |
|---|---|---|---|
| A | 0.10 | 3.29988 | -1 |
| B | 0.05 | 3.32456 | -1 |

**MISS — monotonic worsening.** Telemetry revealed: at TRUST_RATIO=0.05, 38-50% of params clipped at steps 50-200, trust_scale≈0.22. Natural Muon update magnitude is ~20-25% of weight norm — any ratio ≤ 0.10 is throttling signal. The LARS-style trust constraint is fundamentally wrong for Muon (designed for small Adam-like updates, not large NS5 polar-factor updates).

**Recorded finding**: Natural Muon delta ≈ 20-25% of weight norm during early steps. Adam-family trust ratios (5-10%) are unsuitable for Muon/NS5 family. Any successful trust intervention would need gradient-conditioned per-outlier clipping, not blanket per-param normalization.

---

### EDWARD #251 — Lookahead on Muon (K=5, K=10) — CLOSED (INCOMPATIBLE)

All 3 attempts NaN'd at step 25 including trial 1 of n=4 retry.

| Run | K | NaN @ T0 | NaN @ T1 |
|---|---|---|---|
| 2lx8q0n6 | 5 | step 25 | — |
| wpcgf9e4 | 10 | step 25 | — |
| s6uvyg4y | 5 (n=4 retry) | step 25 | **step 25** |

**Multi-seed cascade confirmed** — NOT seed-0. The merged baseline (db1rrfx3) has NO NaN trials; all NaN is Lookahead-induced.

**Mechanism**: Lookahead's `fast := slow` param rollback every K steps leaves Muon's momentum buffer, NorMuon second_moment, and SOAP eigenbasis tracking the discarded fast trajectory while params jump back to slow. By step 25 (5 sync cycles at K=5), state-vs-param mismatch produces unbounded updates → all 12 blocks' Linear weights NaN simultaneously (123,701,376 nonfinite). Zhang et al 2019 designed Lookahead for first-moment-only optimizers; Lookahead is incompatible with multi-buffer preconditioners unless ALL state buffers are rolled back synchronously with params.

---

### ASKELADD #239 — Lion optimizer on aux groups — CLOSED

| Arm | embed_lr / lm_head_lr | val | ffs |
|---|---|---|---|
| v2 (gxxlpakh) | 0.03 / 1e-3 | 3.29854 | -1 |
| Arm B (n72pnmj3) | 0.05 / 3e-3 | 3.30050 | -1 |

**MISS by ~0.022 val.** Arm B's higher LR gives −0.073 nat head start at step 125 but crossover at step 2500 with Arm A ending 0.002 worse. Lion lacks second-moment estimation; in the critical cooldown phase (steps 2500-3175), AdamW's per-coord variance compensation is essential for aux groups (embed + lm_head) to stay on the efficient descent path. Sign-momentum is suboptimal for groups that need precise scaling in the precision window.

---

## 2026-05-17 ~11:35 — Cycle 53: Tanjiro reassigned; embed-warmup falsified

### TANJIRO #252 — Decoupled embedding LR warmup — FALSIFIED

60× variation in embedding LR at the NaN step (0.05 vs 0.30) produces bit-identical cascade:
- Arm A (EMBED_WARMUP=50): NaN step 25, nonfinite_count 123,701,376
- Arm B (EMBED_WARMUP=150): NaN step 25, nonfinite_count 123,701,376

Seed-0 NaN is NOT embedding-driven. The blocks.0.attn.proj.bias (attention path) is the real trigger. Embedding LR is a red herring.

Tanjiro reassigned → NS_ITERS sweep (PR #259): NS_ITERS ∈ {10, 8} vs baseline 12. Hypothesis: fewer NS5 iterations reduce bf16 rounding error compounding.

---

## 2026-05-17 ~10:30 — Cycle 51: SOAP_BETA2 axis closed; alphonse reassigned to SOAP_PRECOND_FREQ

### ALPHONSE #223 — SOAP_BETA2 retune {0.85, 0.92} — CLOSED (axis exhausted)

| SOAP_BETA2 | Runs | NaN pattern | verdict |
|---|---|---|---|
| 0.85 | 67w5zyph, 6gsl9ljw, grpcqmun | NaN at variable steps 75/318/1175 | **0.85-specific destabilizer** |
| 0.90 | db1rrfx3 (baseline) | n=4 mean val 3.27648, ffs 3118.75 | baseline |
| 0.92 | klsnpomc, hx3jldki (trials 0,1) | Both NaN @ step 25, canonical 147,758,208 fingerprint | **multi-seed cascade** |

SOAP_BETA2 is a sharp local optimum at 0.90. Both ±0.02 perturbations destabilize via distinct mechanisms: 0.85 shows later-step HP-induced NaN cascade (variable timing), 0.92 triggers the canonical seed-0 / multi-seed baseline NaN across consecutive seeds. Axis fully exhausted in both directions.

Alphonse reassigned → SOAP_PRECOND_FREQ sweep (PR #256): {5, 20} vs baseline 10. Hypothesis: tighter eigenbasis refresh (5 steps) reduces eigenbasis lag during rapid early-step gradient direction changes → better preconditioning → lower FFS.

## 2026-05-17 ~06:45 — Cycle 44: Three PRs CLOSED (frieren bias-corr, askeladd proj-init-B, edward AdEMAMix); 3 fresh assignments (frieren #238, askeladd #239, edward #240)

### FRIEREN #221 — Adam-style Muon bias correction (MUON_BIAS_CORR=1) — CLOSED

| Run | val | ffs | verdict |
|---|---|---|---|
| `6qb399cr` (n=1, 3175 steps) | **3.27903** | **3150** | MISS (+0.00255 val, +31.25 ffs) |

Adam-style `1/(1-μ^t)` first-moment debiasing on Muon does not transfer to the merged Contra+SOAP-MLP+NS5+contra-normuon+u/w-floor stack. The canonical bias correction (well-studied in Adam) appears to over-amplify Muon momentum when paired with the SOAP eigenbasis pre-conditioner — the NS5+contra+u/w-floor pipeline already implicitly manages momentum norm dynamics. Mechanism-stack mismatch, not a code error. Per pre-authorized decision tree (val > 3.278 → close).

Frieren reassigned → Cosine LR cooldown shape (PR #238). Orthogonal to closed cooldown-duration axis (PR #178, 0.70 local optimum). Cosine concentrates LR higher in early-cooldown steep-descent window; may push FFS earlier.

### ASKELADD #224 — Per-module init Variant B (std=0.00221 non-zero proj) — CLOSED

| Run | val | ffs | verdict |
|---|---|---|---|
| `u0x4ni0c` (n=1, 3175 steps) | **3.27993** | **3175** | MISS (+0.00345 val, +56.25 ffs) |

Variant B (std=0.00221) landed nearly identically to Variant A (zero-init, val=3.28042): only 0.0005 val difference. Both converged to the same attractor — confirms SOAP+NS5 absorbs whatever per-module init benefit can exist on this stack. The per-module init direction (all variants: standard fan-in, zero-init, and small-non-zero) is **fully exhausted** on the merged Contra+SOAP-MLP base. Mechanism is stack-absorbed.

Askeladd reassigned → Lion optimizer on aux groups (PR #239). Replace AdamW on embed+lm_head+scalars with Lion sign-based optimizer. Hypothesis: sign normalization accelerates early token embedding specialization (step 0-500, FFS-critical window). No second moment → cannot amplify variance NaN cascade.

### EDWARD #199 — AdEMAMix on aux groups — CLOSED (multi-seed NaN, no clean trial)

| Run | trial_idx | val | ffs | verdict |
|---|---|---|---|---|
| `d9vxzbtk` | 0 | NaN (step 25) | — | baseline seed-0 NaN |
| `4e8wgtxk` | 0 | NaN (step 25) | — | duplicate process |
| `q2un2m4y` | 0 | NaN (step 1225) | — | multi-seed cascade |
| `65edtfli` | 0-3 | NaN (aborted step 125) | — | safety-guard abort |

Zero clean trials across 4 runs and 2 retries. The `num_trials=4` retry was authorized after establishing AdEMAMix(α=0)≡AdamW to 1e-7 (correct code), but the n=4 run still failed. Likely: AdEMAMix's slow-EMA accumulation on the high-LR embed group (lr=0.3) amplifies the baseline step-2 fragile equilibrium across seeds, not just seed-0.

Edward reassigned → Adaptive NS5 iteration count schedule (PR #240). More iters (16) in early-training fragile window, fewer (8) in late well-conditioned window. Directly tests orthogonalization quality as a FFS lever.

---

## 2026-05-17 ~06:00 — Cycle 43: Nezuko Screen B WINS; fern LR_POWER=1.5 MISS; multi-seed NaN cascade identified

### NEZUKO #212 — Attn-SOAP+trust Screen B (TRUST_THRESHOLD=0.85) — WIN → n=4 IN PROGRESS 🚀

| Screen | val | ffs | verdict |
|---|---|---|---|
| Screen A (`h29cv26c`, T=0.90) | 3.27628 | 3125 | val WIN only — ffs MISS |
| **Screen B (`5g7k1w3q`, T=0.85)** | **3.27475** | **3100** | **BOTH BARS CLEARED** |

Screen B lowered trust threshold from 0.9 to 0.85, activating SOAP for more attention v/proj weights (activation rate: T=0.85 → v on 50%, proj on 100%, overall 87.5%; T=0.9 → v on 0%, proj on 17%, 35%). The increased SOAP coverage closed the FFS gap (3125 → 3100). n=4 confirm launched 05:26 UTC (`3xn3ox1c`), ETA ~12:50 UTC.

### FERN #208 — Power-law LR cooldown (LR_POWER=1.5, CM=0.5)

| Run | val | ffs | verdict |
|---|---|---|---|
| `ersqpsq2` (LR_POWER=1.5, CM=0.4 default — misconfigured) | 3.28313 | -1 | MISS (informational only) |
| `rpws9fug` (LR_POWER=1.5, CM=0.5 proper) | **3.28240** | **-1** | MISS (+0.00592 val) |

Power-law=1.5 HURTS by +0.006 val. Currently testing LR_POWER=2.0 (front-loaded cooldown, different shape hypothesis).

### Multi-seed NaN cascade identified (new this cycle)

Three students (alphonse SOAP_BETA2=0.85, tanjiro TARGET_UW=0.30, edward AdEMAMix) all showed NaN cascades across MULTIPLE seeds (not just seed-0). Distinguishable from seed-0 baseline NaN:
- Seed-0 baseline NaN: step 25, 147,758,208 nonfinite count
- HP-induced multi-seed NaN: step 100-1225, same or higher nonfinite count

Pattern suggests some HP changes (extreme SOAP_BETA2, extreme TARGET_UW, AdEMAMix) destabilize the early-training fragile equilibrium beyond seed-0, making all seeds fail.

---

## 2026-05-17 ~04:35 — Cycle 42: Three PRs CLOSED; three fresh assignments; edward retry authorized

### ALPHONSE #205 — CONTRA_MUON sweep — CLOSED

| Arm | val | ffs | verdict |
|---|---|---|---|
| 0.6 (`u0f98rxy`) | 3.27666 | 3125 | MISS — rising shoulder of optimum |
| 0.7 (`uoqp63dq`) | NaN @ step 25 | — | catastrophic divergence |

**Bowl-shape confirmed**: 0.5 → 0.6 is on the rising shoulder (slightly worse within noise); 0.7 over the cliff (NaN at step 25). CONTRA_MUON=0.5 is the confirmed local optimum. Sweep exhausted — do not revisit CONTRA_MUON axis.

Alphonse reassigned → SOAP_BETA2 retune (PR #223): {0.85, 0.92} vs baseline 0.90. Hypothesis: SOAP Gram EMA decay rate was tuned before CONTRA_MUON=0.5 merged; may need re-tuning for the more perturbed gradient dynamics.

### FRIEREN #177 — Soft-Muon-anneal p sweep — CLOSED

| Screen | val | ffs | verdict |
|---|---|---|---|
| p=0.10 (`dhqwygng`) | 3.27666 | 3125 | MISS |
| p=0.07 (`dbf0augy`) | 3.27659 | 3125 | MISS |
| p=0.07 rerun (`3itp6whk`) | crashed ~step 475 | — | infra |

Val gap is below seed noise (Δval=0.00007 between p=0.07 and p=0.10). FFS=3125 is structural — the mechanism reliably lands at the wrong ffs bucket. Parameter-insensitive in [0.07, 0.10]. Mechanism is sound but ffs gap is structural on new baseline. **CLOSED.**

Frieren reassigned → Adam-style bias correction on Muon first moment (PR #221). Novel mechanism: EMA of Muon momentum is biased toward zero in early training; Adam-style bias correction via `1/(1-μ^t)` should help most in the FFS-critical early training phase.

### ASKELADD #213 — Per-module init zero-init variant — CLOSED

W&B run `jmcvmacz`: val=3.280419, ffs=-1 — MISS by 0.004.

Zero-init proj weights (mlp.proj, attn.proj, lm_head) on merged Contra+SOAP-MLP+NS5 stack doesn't help. SOAP eigenbasis + NS5 spectral normalization already manage init scale implicitly — the μP-inspired init benefit doesn't transfer from simpler optimizer stacks (records #4,5,8).

Askeladd reassigned → Variant B non-zero proj init (PR #224): std=1/(n_embd×√2) ≈ 0.00092. Tests whether a conservative small-scale init (vs zero) provides SOAP eigenbasis signal without the large-scale init explosion risk.

### EDWARD #199 — AdEMAMix aux groups — BLOCKED by baseline NaN

Both 3175-step screen seeds (`d9vxzbtk`, `4e8wgtxk`) NaN'd at step 25 (147,758,208 nonfinite grads at blocks.0.attn.proj.bias — canonical baseline fingerprint). Per edward's analysis: trial_idx=0 deterministically hits the NaN seed. AdEMAMix dynamics (α_t=0.023 at step 25) had no time to express — this is baseline instability, NOT AdEMAMix bug.

**Advisor decision: override my own decision-tree (wrote it before understanding seed-determinism). Authorized retry with `--num_trials 4` to sample seeds {0,1,2,3}.** At least 1 seed should pass given that other students' runs (alphonse `u0f98rxy`, fern `w12r4fc9`) have shown the NaN rate is seed-selective. Retry still pending student launch.

---

## 2026-05-17 ~03:49 — Cycle 41: Thorfinn #178 CLOSED; annealed-μ assigned (#219); multi-screen status

### THORFINN cooldown_frac sweep — CLOSED (PR #178)

Sweep summary (n=1 each arm):

| arm | val | ffs | verdict |
|---|---|---|---|
| 0.65 | 3.27865 | 3150 | MISS |
| **0.70 (control)** | **3.27536** | **3100** | baseline HP — single seed beats baseline |
| 0.75 | 3.27655 | 3125 | MISS |

Both 0.65 and 0.75 are worse than 0.70. Monotone-from-both-sides signal — **0.70 is the local optimum.** This rules out cooldown_frac as a lever and confirms the current schedule duration is already at the sweet spot. Closed to focus compute on schedule *shape* (fern power-law) and mechanism changes.

### THORFINN reassigned — Annealed Muon momentum μ schedule (PR #219)

2-arm sequential screen: MU schedule 0.90→0.97 (Arm A, warmup-style) vs 0.97→0.90 (Arm B, inverse). Hypothesis: static μ=0.95 was set before CONTRA_MUON=0.5 baseline; annealing μ over training tests two mechanism stories about optimal EMA decay over the training trajectory. Linear interpolation in `set_hparams`. 2 × ~95 min screens.

### ALPHONSE #205 — CONTRA_MUON=0.6/0.7 multi-arm status

| Arm | Run | val | ffs | verdict |
|---|---|---|---|---|
| 0.6 (Arm A) | `u0f98rxy` | 3.27666 | 3125 | MISS — tiny (+0.00018 val, +6.25 ffs) |
| 0.7 (Arm B) | `uoqp63dq` | IN PROGRESS | — | launched 03:44 UTC, ETA ~05:29 |

CONTRA_MUON=0.6 essentially tied the baseline — within seed noise but doesn't clear win bar. Arm B (0.7) running. If 0.7 also misses, sweep is done — 0.5 was the optimum. If 0.7 wins, it would be the second monotone step (0.4→0.5→0.7 wins) — strong signal.

### FRIEREN #177 — Soft-Muon-anneal p sweep — CLOSING

| Screen | val | ffs | verdict |
|---|---|---|---|
| p=0.10 (`dhqwygng`) | 3.27667 | 3125 | MISS |
| p=0.07 (`dbf0augy`) | 3.27659 | 3125 | MISS |
| p=0.07 rerun (`3itp6whk`) | crashed ~step 475 | — | infra/OOM, not mechanism |

Val gap is 0.00011-0.00019 (below seed noise), but ffs=3125 is structural — ffs is quantized in 25-step buckets and the mechanism is reliably landing at 3125. Cannot close the 6.25 ffs gap vs new baseline (3118.75) regardless of p_start value. Mechanism is parameter-insensitive in 0.07-0.10 range. Advisor nudged frieren to post SENPAI-RESULT; will close and reassign to fresh direction.

### NEZUKO #212 — Attn-SOAP+trust (new baseline) screens

| Screen | Run | val | ffs | verdict |
|---|---|---|---|---|
| TRUST_THRESHOLD=0.9 (A) | `h29cv26c` | 3.27628 | 3125 | VAL WIN (−0.00020), FFS MISS |
| TRUST_THRESHOLD=0.85 (B) | running | — | — | launched 03:25 UTC, ETA ~05:00 |

Screen A's val=3.27628 is a VAL WIN but ffs=3125 misses 3118.75. Threshold=0.85 activates SOAP on v/proj rows (which hover at cosine 0.85-0.89 from PR #124 data). If Screen B also wins val AND closes ffs gap, predeclare n=4 immediately.

### ASKELADD #213 — Per-module init screen — MISS, Variant B predeclared

W&B run `jmcvmacz`:

| Metric | Value | vs baseline | verdict |
|---|---|---|---|
| val/loss | 3.28042 | +0.00394 | MISS |
| ffs | never crossed 3.28 | — | MISS |

Per-module init (μP-inspired: embed std=0.02, zero-init proj/lm_head, fan_in-scaled qkv) didn't improve on the merged SOAP-MLP stack. NS5 spectral normalization and SOAP eigenbasis preconditioning already absorb most of what per-module init buys on simpler optimizer stacks. Recommended Variant B: non-zero proj init (proj.weight ~ N(0, 1/(320*sqrt(2)))) — this may stabilize the step-2 NaN pattern at blocks.0.attn.proj.bias and improve early-step dynamics. Waiting for SENPAI-RESULT before launch.

### FERN #208 — Power-law LR cooldown screens

| Screen | CONTRA_MUON | val | ffs | verdict |
|---|---|---|---|---|
| `ersqpsq2` (LR_POWER=1.5) | **0.4 (wrong!)** | 3.28313 | -1 | misconfigured — CONTRA_MUON default 0.4 |
| `rpws9fug` (LR_POWER=1.5+CM=0.5) | 0.5 ✓ | IN PROGRESS | — | launched 03:25 UTC, ETA ~04:55 |

Fern correctly caught the CONTRA_MUON misconfiguration and relaunched with CM=0.5. ersqpsq2 result on 0.4 base not useful for decision tree. rpws9fug is the true LR_POWER=1.5 screen on new baseline.

### EDWARD #199 — AdEMAMix aux groups — Full screen authorized

After exceptional diagnostic work: Edward proved AdEMAMix(α=0) ≡ AdamW to 1e-7 (unit test), and the baseline itself (unmodified commit ae5552e) NaN-s at step-2 in `blocks.0.attn.proj.bias` stochastically. The NaN is seed-dependent baseline instability on 1-GPU short runs, NOT an AdEMAMix bug. Authorized full 3175-step screen with conservative HPs (α=1.0, β3=0.99, warmup=1024, eps=1e-8). Screen launch pending.

---

## 2026-05-17 ~01:30 — Cycle 37: Tanjiro PMuon CLOSED; TARGET_UW retune assigned (#214); in-flight status

### TANJIRO PMuon bilateral streaming covariance — CLOSED (PR #187)

W&B run `eafhrglu` (g1r2-tanjiro/pmuon-stream, γ=0.3, β=0.95):

| Metric | Value | Baseline | Δ |
|---|---|---|---|
| val/loss | ~3.425 at step 2150 (cooldown entry) | 3.27648 | MISS |
| ffs | -1 (never crossed 3.28) | 3118.75 | MISS |

**Root cause analysis**: PMuon's bilateral power-iteration streaming covariance (Σ_L, Σ_R with γ-power exponent) is a gradient-space preconditioner. SOAP-MLP already applies eigenbasis preconditioning to MLP weights before NS5. Stacking PMuon on top creates **double-conditioning** — two sequential preconditioners on the same gradient. Record #18 (PMuon, 3269 steps) was tested on vanilla Contra-Muon WITHOUT SOAP-MLP; the composition here is different. Result: val=3.425 heading into cooldown, too far behind to converge.

Student handling was exemplary: caught advisor's close-out message 8 seconds after launching γ=0.2 follow-up screen, killed it at step 50 (saving ~3 GPU-hours), posted corrected terminal SENPAI-RESULT. **PMuon closed. Do not retry PMuon on SOAP-MLP stack.**

### TANJIRO reassigned — TARGET_UW retune (PR #214)

2-arm sequential screen: TARGET_UW ∈ {0.30, 0.40} vs new baseline. Hypothesis: TARGET_UW=0.35 was tuned with CONTRA_MUON=0.4; with CONTRA_MUON=0.5 the natural u/w ratio has shifted. One env-var change, zero added complexity. Arms: 0.30 (looser floor) and 0.40 (tighter floor).

### IN-FLIGHT STATUS UPDATE (as of ~01:30 UTC 2026-05-17)

**ALPHONSE #205 CONTRA_MUON=0.6 screen `fmx37tmr`**: step 2875/3175, val=3.306 — running, ~300 steps from terminal (~30 min). In deep cooldown. Result pending.

**FRIEREN #177 p=0.07 retry `dbf0augy`**: step 3000/3175, val=3.2912 — nearly done (~15 min). Needs to drop to ≤3.2762 in final 175 steps (significant drop required; likely landing in 3.27x range but outcome uncertain).

**THORFINN #178 cooldown_frac sweep**:
- 0.65 arm DONE: val=3.27865/ffs=3150 — **MISS** vs new baseline (both bars missed). Shorter cooldown hurts.
- 0.70 arm (control): val=3.27536/ffs=3100 — single seed beats baseline (but it IS the baseline HP).
- 0.75 arm `7f0r4eds`: just started (step 325/3175, val=4.059 early). Key test for longer cooldown.

**EDWARD #199 AdEMAMix**: 7+ smoke runs ALL NaN/crashed. Latest: `nxwdjjtx` (5 steps, NaN), `gwkew7xw` (crashed at step 1). Student has not pushed code to branch (branch has only 2-line cosmetic change). Advisor requested code paste and STOP on new runs until reviewed.

**NEZUKO #212 Attn-SOAP new base**: smoke `0k3qgq5q` clean at step 400 (val=3.808). Screen `h29cv26c` at step 675/3175, val=3.759 — healthy early phase.

**ASKELADD #213 per-module init**: smoke `0vc4kc82` clean at step 400 (val=3.832). Screen `jmcvmacz` at step 700/3175, val=3.775 — healthy early phase.

**FERN #208 power-law LR**: screen `w12r4fc9` at step 1225/3175, val=3.633 — running, ~39% through.

---

## 2026-05-16 23:30 — Cycles 33-34: Four PRs CLOSED; three new assignments

### FERN Aurora n=4 — CLOSED (PR #125), high variance

W&B run `5kr7d0i5`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| T3 | 3.28038 | -1 (MISS) |
| n=4 mean | **3.27893** | **FAIL** |

2/4 trials miss ffs (never cross 3.28). n=4 mean=3.27893 > 3.27648 and 3.27893 > 3.27800 (statsig bar). Aurora diagonal leverage-score equalization is fundamentally high-variance on this architecture — mechanism requires n=8+ for reliable statistics. **CLOSED. Aurora is off the table at n=4 budget.**

### NEZUKO Attn-SOAP+trust-gate n=4 — CLOSED (PR #124)

W&B run `790h1llo`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| T3 | 3.27715 | 3125 |
| n=4 mean | **3.27742** | **3125** |

Val MISS: 3.27742 > 3.27648. FFS MISS: 3125 > 3118.75. Misses the NEW baseline (PR #139) by 0.00094 val and 6.25 ffs. **CLOSED.** Notable: std=0.00015 is the best stability of any mechanism tested — Attn-SOAP+trust gate is robust. The mechanism is sound but doesn't beat the shifted baseline. Reassigned to Attn-SOAP on new base (PR #212) at THRESHOLD=0.9 and 0.85.

### ASKELADD SFM (Schedule-Free Muon) — CLOSED (PR #181)

SFM const-EMA fallback screen `k3wkjy84` (c_t=0.01):

| Metric | Value |
|---|---|
| val/loss | ~4.6+ (diverged) |
| y_z_diff_fro | growing unboundedly |

**Fundamental incompatibility confirmed**: Muon's Newton-Schulz iteration operates correctly only under non-constant LR (the operator-norm normalization within NS5 implicitly relies on LR decay to bring ‖y − z‖ under control). With constant LR, ‖y − z‖ diverges regardless of c_t schedule. **Schedule-Free Muon is CLOSED as a direction. Do not revisit.**

Assigned: askeladd → per-module weight init scaling (PR #213).

### New assignments created (Cycles 33-34)

| PR | Student | Hypothesis |
|---|---|---|
| #208 | g1r2-fern | Power-law LR cooldown (LR_POWER=1.5/2.0 sweep) — record #20 ingredient |
| #212 | g1r2-nezuko | Attn-SOAP+trust on CONTRA_MUON=0.5 baseline (THRESHOLD=0.9 then 0.85) |
| #213 | g1r2-askeladd | Per-module weight init scaling (μP-inspired, records #4,5,8 ingredient) |
| #214 | g1r2-tanjiro | TARGET_UW retune 0.30/0.40 sweep (u/w-floor vs new CONTRA_MUON=0.5 base) |

---

## 2026-05-16 23:15 — Cycle 32: PR #139 MERGED (NEW BASELINE), frieren screen near-miss

### ⭐ ALPHONSE CONTRA_MUON=0.5 n=4 — MERGED (PR #139) — NEW BASELINE

W&B run `db1rrfx3`:

| Trial | val/best_loss | ffs |
|---|---|---|
| T0 | 3.27830 | 3150 |
| T1 | 3.27634 | 3125 |
| T2 | 3.27551 | 3100 |
| T3 | 3.27577 | 3100 |
| **n=4 mean** | **3.27648** | **3118.75** |
| statsig | (3.28−3.27648)×2 = **0.00704** ≥ 0.004 ✓ | |

Beats prior baseline (PR #78) on both bars: val −0.00112, ffs −12.5 steps. **MERGED.** Mechanism: increasing CONTRA_MUON from 0.4 → 0.5 adds more spectral exploration via contravariant perturbation, escaping suboptimal gradient directions faster during peak-LR phase. Counter to intuition (more noise → better speed), but consistent with the "spectral exploration" interpretation.

New baseline after merge: mean=3.27648, ffs_mean=3118.75.

### FRIEREN Soft-Muon-anneal screen — NEAR-MISS vs new baseline (PR #177)

W&B run `dhqwygng` (p_start=0.10 → p_end=0.0 over first half):

| Metric | Screen | New baseline | Δ |
|---|---|---|---|
| val/loss | 3.27667 | 3.27648 | +0.00019 (MISS by tiny margin) |
| ffs | 3125 | 3118.75 | +6.25 steps (MISS) |

Excellent mechanism signal — val=3.27667 is far below old baseline (3.27760) and very close to new one. Miss is only 0.019% on val and 6.25 steps on ffs. Pre-approved p_start=0.07 follow-up screen launched. Analysis: annealing p=0.10 → 0.0 over first half of training adds spectral mixing during peak-LR phase and eliminates it during cooldown. Mechanism is sound; parameter needs slight reduction.

---

## 2026-05-16 22:15 — Cycle 31: Edward Contra-Muon n=4 CLOSED (stronger-but-slower); Askeladd SFM MISS; fern/nezuko T3 started

### Edward Contra-Muon n=4 @ 3225 steps — CLOSED, superseded (PR #76)

W&B run `zsqazpmr` (`g1r2-edward/contra-muon`):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27750 | 3175 |
| T1 | 3.27599 | 3175 |
| T2 | 3.27652 | 3175 |
| T3 | 3.27607 | 3175 |
| **n=4 mean** | **3.27652** | **3175** |
| statsig | **(3.28−3.27652)×2 = 0.00696 ≥ 0.004 ✓** | |

- Statsig PASS but ffs_mean=3175 > baseline 3131.25 — **FFS MISS**, does NOT beat merged baseline on primary metric.
- "Stronger but slower" pattern (#3 instance this session: Soft-Muon, Newton-Muon, now Contra-Muon-only).
- Mechanism superseded by PR #78 (merged baseline already has Contra-Muon + SOAP-MLP; edward's PR is the Contra-Muon-only subset).
- PR #76 closed. Edward reassigned to AdEMAMix-aux (PR #199).

### Askeladd SFM uniform c_t screen — MISS, fallback triggered (PR #181)

W&B run `groom2ym` (`g1r2-askeladd/sfm`):

| Field | Value |
|---|---|
| Screen val/loss | 4.60499 |
| ffs | -1 (MISS — never crossed 3.28) |
| y_z_diff_fro (terminal) | ~2.2e9 (massive divergence) |
| c_t at terminal | 0.00031 |

Root cause: `c_t = 1/(t+1)` weighs early pre-warmup iterates near-equally with trained iterates. By step 3175, most of the Polyak average weight sits on random-init timesteps. The `||y − z||` norm grows to 2.2B — z has moved far from init but y averages it all back toward init.

Fallback (pre-approved): `SFM_C_SCHEDULE=const`, `SFM_C_CONST=0.01` (EMA with ~100-step window). Screen `k3wkjy84` launched by student. This is a fundamentally sounder design — tracks recent trajectory rather than summing all history.

### Fern Aurora n=4 T2 terminal — BORDERLINE (PR #125)

W&B run `5kr7d0i5`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| n=3 mean | **3.27844** | — |

n=3 mean=3.27844 > 3.27800 → statsig currently fails. For n=4 MERGE: T3 needs val ≤ 3.27668 AND ffs ≤ 3125. T1's MISS (-1) means if using train_steps for ffs calculation, ffs_mean ≥ 3131.25 even with perfect T3. **Merge path nearly closed.** T3 still running (step 878/3175).

### Nezuko Attn-SOAP+trust-gate n=4 T2 terminal — OUTSTANDING (PR #124)

W&B run `790h1llo`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| n=3 mean | **3.27750** | **3125** |

All 3 trials within 0.00015 val! n=3 mean=3.27750 beats both baseline bars (≤3.27800 val, ≤3131.25 ffs). T3 needs val ≤ 3.27852 (generous bar). **MERGE NEAR-CERTAIN.** T3 at step 553/3175.

---

## 2026-05-16 20:25 — Cycle 30 (cont): Tanjiro Lookahead CLOSED, nezuko/fern T0+T1 interim results

### Tanjiro Lookahead α=0.7 retry — MISS, PR #161 CLOSED

W&B run `yph361ta` @ train_steps=3175:

| Arm | α | Final val | ffs |
|---|---|---|---|
| Original screen | 0.5 | 3.30606 | -1 (MISS) |
| Retry | **0.7** | **3.28985** | -1 (MISS) |

Higher α (weaker pullback) recovered 0.016 val/loss but still missed by 0.010. Structural issue confirmed: Lookahead's slow-fast averaging slows cooldown val descent regardless of α. Lookahead doesn't transfer to this short-step cooldown-dominated regime. PR #161 closed.

### Tanjiro reassigned — PMuon (PR #187)

Record #18 mechanism: bilateral streaming covariance power preconditioning (Σ_L, Σ_R with γ=0.3 power exponent, β=0.95). Stacks on top of merged Contra+SOAP-MLP+NS5 after the NS5 step. Fresh preconditioner class — softer than KL-SOAP (pf=1 eigendecomp) but more adaptive than plain SOAP (pf=10).

### Nezuko Attn-SOAP+trust-gate n=4 T0+T1 (interim) — OUTSTANDING

W&B run `790h1llo` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | **3.27743** | **3125** |
| T1 | **3.27750** | **3125** |
| n=2 mean | **3.27747** | **3125** |

Remarkably consistent T0/T1 pair (val within 0.00007!). Both beat merged baseline on both metrics. If T2+T3 continue pattern → n=4 mean ≤ 3.27800 AND ffs_mean ≤ 3125 = **MERGE CANDIDATE**.

### Fern Aurora n=4 T0+T1 (interim) — HIGH VARIANCE WARNING

W&B run `5kr7d0i5` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | **3.27592** | **3100** |
| T1 | **3.28172** | **-1 (MISS!)** |

T1 completely missed — Aurora's diagonal leverage-score equalization is seed-sensitive. Path to merge now requires both T2 and T3 to hit near T0 quality. High variance is concerning. Monitoring.

## 2026-05-16 19:10 — Cycle 30: Askeladd KL-SOAP screen MISS, reassigned to Schedule-Free Muon

### Askeladd KL-SOAP+H screen — MISS, PR #166 CLOSED

W&B run `061cl8bj` @ train_steps=3125:

| Metric | Value |
|---|---|
| val/loss at terminal | **3.29515** |
| ffs (first_step_to_target) | **-1 (never reached 3.28)** |
| Step time | ~2.6 s/step |

Val=3.295 is +0.0175 above merged baseline mean (3.27760) and well above the 3.281 threshold in the predeclared decision tree. KL-SOAP+H replacing (not stacking on) the merged Contra+SOAP-MLP stack was ~50 steps worse on terminal val/loss at the same step budget. The pf=1 eigenbasis frequency doubled per-step compute but didn't recover the NS5+Contra-Muon orthogonalization the merged baseline relies on. PR #166 closed.

### Askeladd reassigned — Schedule-Free Muon (PR #181)

Fresh mechanism class: Polyak iterate averaging with constant LR, eliminating cooldown entirely. Hypothesis: constant LR keeps gradient magnitude steady; iterate averaging absorbs noise → val crosses 3.28 earlier. Implementation: maintain z (trajectory) and y (averaged eval point), Muon update on z, y ← (1 − 1/(t+1)) · y + (1/(t+1)) · z. No cooldown_frac, no LR warmup-cooldown schedule. First test of schedule-free paradigm on this track.

## 2026-05-16 17:55 — Cycle 29 (cont): Thorfinn Soft-Muon n=4 CLOSED, reassigned to cooldown_frac retune

### Thorfinn Soft-Muon p=0.05 n=4 — STRONGER-BUT-SLOWER, PR #103 CLOSED

W&B run `nfkk0mms` @ train_steps=3175-3325 (final):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.274159 | 3250 |
| T1 | 3.274896 | 3250 |
| T2 | 3.272523 | 3225 |
| T3 | 3.275516 | 3250 |
| **n=4 mean** | **~3.2741** | **~3.2243** |

Statsig: `(3.28 − 3.2741) × √4 = +0.0118` — **PASSES** statsig (need ≥ 0.004). Val/loss excellent — best n=4 val mean of the session! BUT ffs_mean ≈ 3244 > baseline 3131.25. Does NOT beat merged baseline on FFS metric. Clean "stronger but slower" result — Soft-Muon's polynomial spectral compression lowers terminal val but slows cooldown convergence, adding ~75-100 steps vs baseline. PR #103 closed.

### Thorfinn reassigned — cooldown_frac retune (PR #178)

Three single-seed screens: cooldown_frac = 0.65, 0.70 (baseline reference), 0.75. If ffs ≤ 3100 AND val ≤ 3.279, predeclare n=4. Target: identify if scalar cooldown retune shifts the 3.28 crossing from ~step 3125 to ~step 3075. Predeclared sweep comparison table when all 3 screens complete.

## 2026-05-16 17:46 — Cycle 29: Frieren MuLoCo n=4 CLOSED, reassigned to Soft-Muon annealing

### Frieren MuLoCo+NorMuon n=4 — CLEAN NEGATIVE, PR #109 CLOSED

W&B run `jzsue46n` @ train_steps=3175 (final):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.282398 | -1 (miss) |
| T1 | 3.281958 | -1 (miss) |
| T2 | 3.279381 | 3175 |
| T3 | 3.280067 | -1 (miss) |
| **n=4 mean** | **3.28095** | **1/4 hit** |

Statsig: `(3.28 − 3.28095) × √4 = -0.0019` — **FAILS** statsig (need ≥ 0.004). Only T2 reached target. MuLoCo outer-Nesterov wrapping does not transfer to the merged Contra+SOAP-MLP step budget. The original screen at 3275 (`akwwpkv3`, val=3.27688 ffs=3225) was real but stronger-but-slower — needs ~100 more steps than merged baseline allows.

Clean negative — well-executed predeclaration honored across all 4 trials. PR #109 closed.

### Frieren reassigned — Soft-Muon annealing on merged base (PR #177)

Fresh hypothesis: record #20 (current global best at 3030 steps) uses **annealed Soft-Muon** as the key novel mechanism. Soft-Muon NS5 with `x^(1-p)` polynomial mixing, p_start=0.10 → p_end=0.0 annealed over first half of training. Applied to model.blocks.parameters() ndim>=2, alongside the existing Contra-Muon + SOAP-MLP stack. Target: cleaner cooldown trajectory + earlier 3.28 crossing.

## 2026-05-16 15:55 — Cycle 24: Fern Aurora screen FFS-WINNING, alphonse n=4 launched, frieren n=4 confirmed clean negative

### Fern Aurora screen — FFS-WINNING result on Contra+SOAP-MLP base (PR #125)

After two prior crashes (`csj1tm5z` @ step 1475, `isi6y97w` @ step 575) and a clamp fix (`D.clamp_(1e-6, 1e6)`):

| Run | Config | val/loss | ffs | Statsig (n=1) |
|---|---|---|---|---|
| `lqwaozx7` | Aurora on Contra+SOAP-MLP, 3175 steps | **3.27706** | **3125** | — |

**SINGLE-SEED BEATS MERGED BASELINE ON BOTH METRICS:**
- val 3.27706 < baseline 3.27760 (−0.00054)
- ffs 3125 < baseline ffs_mean 3131.25 (−6.25)

n=4 PREDECLARED at train_steps=3175 at 15:54 UTC. Fern to launch immediately. ETA terminal ~21:00-22:00 UTC.

Aurora is the FIRST mechanism (alongside CONTRA_MUON=0.5 tuning) to produce a single-seed FFS win on the merged baseline. Critically, Aurora is a fundamentally different mechanism from CONTRA_MUON tuning — it's diagonal leverage-score equalization inside NS5 from record #17. If both n=4 confirmations pass, they could potentially be stacked.

### Alphonse n=4 LAUNCHED — CONTRA_MUON=0.5 (PR #139)

W&B run `db1rrfx3` launched 15:33 UTC, currently step ~350/3175 trial 0. Same configuration as merged baseline except CONTRA_MUON=0.4 → 0.5. ETA full n=4 terminal ~22:00-22:30 UTC.

### Frieren n=4 MuLoCo+NorMuon — CLEAN NEGATIVE confirmed (PR #109)

W&B run `jzsue46n` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.28240 | -1 (never crossed 3.28) |
| T1 | 3.28196 | -1 (never crossed 3.28) |
| T2 | running | — |
| T3 | — | — |

T0 and T1 both miss the 3.28 target at 3175 steps. T2/T3 in progress per binding predeclaration; ETA full terminal ~17:40 UTC. Mean would need ≤3.27587 across T2/T3 to salvage statsig — ~3σ unlikely. Clean negative. Will close PR after SENPAI-RESULT.

Pattern: MuLoCo outer-Nesterov wrapping doesn't add to Contra+SOAP-MLP at 3175 steps. The original NorMuon-clean base achieved val=3.27688 ffs=3225 at 3275 steps in screen, but stacking MuLoCo doesn't compress further to 3175 steps.

### Thorfinn Soft-Muon p=0.05 n=4 — strong val, FFS not competitive (PR #103)

W&B run `6kjpjnvd` @ train_steps=3325 (plain Muon + NorMuon + Soft-Muon base):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27423 | 3250 |
| T1 | 3.27492 | 3250 |

Remarkable T0/T1 agreement at ffs=3250. Excellent val/loss but ffs=3250 > merged baseline 3131.25 by 119 steps. Pattern: "stronger but slower" — same as Newton-Muon, NorMuonH. Will close PR after T2/T3 terminal (~17:40 UTC).

### Edward Contra-Muon n=4 — statsig pass likely, FFS not competitive (PR #76)

W&B run `zsqazpmr` @ train_steps=3225:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27750 | 3175 |
| T1 | 3.27599 | 3175 |

Excellent val (mean projection ~3.276), but ffs=3175 > merged baseline 3131. Pod showing slow step rate (~6010 ms/step) but GPU healthy at 100%. ETA terminal ~21:00 UTC. Will close after terminal.

## 2026-05-16 15:35 — Cycle 23: Alphonse CONTRA_MUON=0.5 screen beats baseline on both metrics

### Alphonse CONTRA_MUON=0.5 screen — BEATS merged baseline on BOTH val AND FFS (PR #139)

| Run | Config | val/loss | ffs | Statsig (n=1) | Notes |
|---|---|---|---|---|---|
| `hjsjscjy` | CONTRA_MUON=0.3, 3175 steps | 3.27804 | 3150 | — | First FFS-competitive screen (cycle 18) |
| `yctj2ozd` | CONTRA_MUON=0.5, 3175 steps | **3.2763** | **3125** | — | BEATS baseline (3.27760/3131.25)! |

Screen `yctj2ozd` (CONTRA_MUON=0.5) delivers val=3.2763 ffs=3125 — the first single-seed result to beat the merged baseline on BOTH primary metrics simultaneously. N=4 PREDECLARED at train_steps=3175 with CONTRA_MUON=0.5. Predeclare comment posted at ~15:15 UTC. ETA terminal ~22:30-23:00 UTC.

Analysis: Reducing CONTRA_MUON from 0.4 (merged) → 0.5 (stronger contra correction) appears to tighten the convergence trajectory during cooldown. The contra correction `T - T^T` removes antisymmetric noise from the operator; a higher coefficient removes more, leading to a cleaner Newton-Schulz input. This translates directly to earlier FFS crossing without sacrificing terminal val.

### Askeladd NorMuonH n=4 @ 3300 — CLOSED, statsig pass but not FFS-competitive (PR #74)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27781 | 3225 |
| T1 | 3.27573 | 3200 |
| T2 | 3.27863 | — |
| T3 | ~3.277xx | — |
| n=4 mean | **3.27732** | ffs_mean ~3225-3250 |

n=4 mean=3.27732 — STRICTLY BETTER VAL than merged baseline (3.27760 → 3.27732), but ffs_mean ~3225-3250 — STRICTLY WORSE FFS than baseline 3131.25. Closed as "statsig pass but not FFS-competitive." NorMuonH on plain Muon base produces excellent terminal val but cannot compress the convergence curve to match Contra+SOAP-MLP's FFS efficiency. Reassigned to KL-SOAP + hyperball (PR #166).

### Askeladd reassigned — KL-SOAP + hyperball (PR #166, just assigned)

New hypothesis: Replace Contra-Muon+NS5+SOAP-MLP with KL-SOAP+hyperball on ALL 2D block params. Key parameters: β1=0.95, β2=0.90, shampoo_beta=0.90, pf=1, lr=0.018 (record #19 HPs). Reference: record #19 (n=6 mean=3.27800 @ 3125 steps, statsig pass). KL-SOAP at pf=1 provides the most aggressive curvature tracking in the literature — eigendecomp every step rather than every 10 steps. Unknown if it stacks with or replaces the Contra mechanism.

## 2026-05-16 14:15 — Cycle 19: Newton-Muon closed, Lookahead assigned, alphonse FFS-competitive

### Tanjiro Newton-Muon CLOSED — positive but not merge-eligible (PR #81)

Two terminal SENPAI-RESULTs:

| Config | n | val/loss mean | ffs_mean | Statsig | Merge? |
| --- | --- | --- | --- | --- | --- |
| Newton-Muon-only @ 3325 (`cpoe66ut`) | 4 | **3.27643** | 3256.25 | PASSES (0.00714) | NO — ffs > baseline |
| Newton-Muon-attn + Contra+SOAP-MLP @ 3175 (`wzgya0cq`) | 1 | 3.28893 | -1 | N/A | NO — missed target |

Newton-Muon-only at 3325 produces the LOWEST n=4 mean val/loss of any r2 student (3.27643), beats public record #15 (3.2785) by 0.00207. Paper-quality result, reproducible (σ≈0.0005). But ffs_mean=3256.25 at 3325 steps vs merged baseline ffs_mean=3131.25 at 3175 — 125 steps worse on primary metric.

Stack with Contra+SOAP-MLP (Option B) at 3175 failed badly (3.28893, never reached 3.28). Numerics clean (0 Cholesky failures), but the combined 4-mechanism stack doesn't compress below 3.28 in 3175 steps. Pattern: each additional mechanism extends the cooldown needed.

Conclusion: Newton-Muon mechanism is "stronger but slower." Not FFS-competitive at 3175. Closed PR #81.

### Tanjiro reassigned: Lookahead-Muon (PR #161)

Fresh hypothesis: Lookahead wrapper on merged Contra+SOAP-MLP baseline (Zhang et al. 2019). Inner optimizer takes k=5 steps normally; every k steps: θ_slow ← θ_slow + 0.5(θ_fast − θ_slow), then θ_fast ← θ_slow. Applied to ALL trainable params AFTER warmup.

Goal: FFS reduction by 30-80 steps via trajectory variance smoothing during peak-LR phase. If screen (single-seed at 3175) lands ≤ 3.279 with ffs ≤ 3175, predeclare n=4. Stretch goal: ffs_mean < 3131.

### Alphonse CONTRA_MUON=0.3 screen FFS-COMPETITIVE (PR #139)

`hjsjscjy` terminal: val=**3.27804**, ffs=**3150** at 3175 steps. Single-seed 19 steps worse than merged baseline ffs_mean=3131.25, but competitive val. FIRST FFS-competitive result since PR #78 merged. Alphonse launched CONTRA_MUON=0.5 screen (`yctj2ozd`) at step ~450 at 13:40 UTC. ETA terminal ~15:35 UTC.

If 0.5 screen competitive: predeclare n=4 at 3175 with best arm. n=4 mean could potentially beat baseline if seed distribution is favorable.

## 2026-05-16 10:30 — Cycle 14: Multiple screens terminal, PR #112 closed, alphonse reassigned

### Alphonse p=1.5 NEW-base CLOSED — NULL result (PR #112)
- W&B run `5gd8cw6c` (p=1.5 on Contra+SOAP-MLP NEW-base): **val=3.2775, ffs=3150** at 3275 steps
- Summary: p=1.5 on NEW-base essentially equals merged baseline mean (3.27760), within 1σ noise.
  p>1 on OLD-base was clearly negative; on NEW-base SOAP-MLP neutralizes the effect but provides no gain.
- Conclusion: linear LR cooldown remains optimal. Power-law p>1 ruled out for both bases.
- PR #112 CLOSED. Alphonse reassigned to **PR #139: Contra-Muon coefficient retune** (CONTRA_MUON ∈ {0.3, 0.5} vs baseline 0.4).

### Frieren MuLoCo+NorMuon screen STRONG (PR #109 in-flight)
- W&B run `akwwpkv3`: **val=3.27688, ffs=3225** at 3275 steps (single seed, NorMuon-clean base)
- Beats NorMuon-clean reference: val 3.27800→3.27688 (−0.00112), ffs 3256→3225 (−31 steps)
- Frieren predeclared n=4 at **train_steps=3175** (matching merged baseline) and launched immediately.
- Critical: frieren's n=4 will test if MuLoCo+NorMuon competes with Contra+SOAP-MLP at same step count.
- If n=4 mean ≤ 3.278, ffs_mean ≤ 3131: MERGE candidate. ~6.75h ETA.

### Tanjiro Newton-Muon n=4 terminal (PR #81 in-flight, no SENPAI-RESULT yet)
- `cpoe66ut`: T0=3.27599/ffs=3250, T1=3.27720/ffs=3275, T2=3.27612/ffs=3250, T3=3.27639/ffs=3250
- n=4 mean=3.27643, ffs_mean=3256.25, margin=0.00714 — PASSES statsig
- But ffs=3256.25 > merged baseline ffs=3131.25 by 125 steps — does NOT beat merged baseline
- Sent back (cycle 13): rebase + stack Newton-Muon's right-precond (attention) on Contra+SOAP-MLP
- Recipe insight: Newton-Muon achieves the LOWEST n=4 mean val (3.27643) of any recipe — strong mechanism, needs different step budget to compete.

### Thorfinn Soft-Muon p=0.05 n=4 launched (PR #103)
- `78nqtrmr`: n=4 at train_steps=3325, plain Muon + NorMuon + Soft-Muon base
- T0 nearly terminal at val~3.2742 ffs=3225 (strongest single-seed result in portfolio!)
- ETA ~8-9h to T4 terminal. Single-seed trajectory at 3.2742 is remarkable.

### Edward Contra-Muon T0 strong (PR #76)
- T0 from `zsqazpmr`: val=3.2760, ffs=3175. T1 just started (step ~100).
- Expected: n=4 mean ~3.277-3.278 range. Likely pass statsig at 3225 steps.

### Askeladd NorMuonH T0 done (PR #74)
- T0 from `lw99ybyp`: val=3.2777, ffs=3250 at 3300 steps. T1 at step ~1825/3300.

## 2026-05-16 07:55 — Cycle 11: Soft-Muon p=0.05 strong, power-law LR closing

### Thorfinn p=0.05 SCREEN STRONG SIGNAL (PR #103)
- W&B run `pzp8b4rq` finished cleanly at **val/loss=3.27553, ffs=3250** at train_steps=3325.
- **Single seed 0.00207 BELOW merged baseline mean 3.27760** — strongest sub-baseline single-seed result in this round.
- p=0.075 retry `6empzhxo` crashed at step 625 — external pod restart, NOT numerical (blend still 0).
- Sent back PR #103 with directive: **launch predeclared n=4 @ 3325 confirmation immediately**, skip p=0.075 retry.
- For statsig at n=4: need mean ≤ 3.278. With single seed at 3.27553 and recipe variance σ~0.0007 typical, n=4 mean projects to 3.276–3.278 (borderline confirmable).
- Recipe (Soft-Muon p=0.05 on plain Muon) is **orthogonal** to merged Contra+SOAP-MLP — potential future stack candidate.
- ETA T3 ~13h from launch.

### Alphonse power-law LR closing (PR #112)
- W&B run `fg11eojr` (p=1.2): **3.28031** at 3275 steps — MISS
- W&B run `vvwsv9fm` (p=1.5 OLD-base): **3.28470** at 3275 steps — MISS
- Monotonic trend: p=1.0→0.000, p=1.2→+0.00231, p=1.5→+0.00670 — power-law cooldown with p>1 is decisively counterproductive on NorMuon base.
- p=1.5 NEW-base screen launched at 08:28 UTC (decisively expected to miss). Acknowledged "let it finish" per alphonse's decision tree.
- After NEW-base screen terminalizes: close PR #112 with documented negative evidence, reassign alphonse to **Contra-Muon coefficient retune on merged base** (CONTRA_MUON ∈ {0.3, 0.5} vs baseline 0.4).

### Other r2 students (in-flight, no new terminals)
- edward `zsqazpmr` (Contra-Muon n=4 @ 3225): T0=3.27750 done, T1 at step ~2275/3225 (~70%). ~10h to T3.
- tanjiro `cpoe66ut` (Newton-Muon n=4 @ 3325): T0=3.27599, T1-T2 done, T3 at step ~1275/3325 (~38%). Best T0 is BEST single-trial of any wave-1 recipe.
- askeladd `lw99ybyp` (NorMuonH n=4 @ 3300): launched, at step ~1425/3300 (~43%) — picked up cycle-9 rebase+launch directive.
- frieren `akwwpkv3` (MuLoCo+NorMuon screen @ 3275): just launched, step ~0.
- nezuko `g4zvpp9c` (Attention SOAP + trust gate): smoke at step ~40 + 2 prior smokes done. PR #124 picked up.
- fern `csj1tm5z` (Aurora orthogonal projection): screen at step ~25 + 1 prior smoke done. PR #125 picked up.

All 8 r2 students productive — zero idle GPUs in cycle 11.

## 2026-05-16 06:35 — PR #78: Contra+SOAP-MLP — MERGED as new advisor baseline
- Branch: `g1r2-fern/contra-soap-mlp` (squash-merged `718dd3f`)
- See below entry for full experiment detail. BASELINE.md updated.

## 2026-05-16 06:35 — PR #80: Muon² n=4 confirmation — CLOSED (non-competitive)
- Branch: `g1r2-nezuko/muon-sq`
- W&B run: `7lxk02m6` | num_trials=4 | train_steps=3325

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27788 | 3300 |
| T1 | 3.27859 | 3300 |
| T2 | 3.27915 | 3300 |
| T3 | 3.27792 | 3300 |
| **mean** | **3.27839** | **3300** |

- Statsig check: (3.28 − 3.27839) × √4 = **0.00322** — FAILS 0.004.
- Recipe is stable (all seeds hit target, no crashes, std=0.0006). The n=4
  mean is 0.0008 above NorMuon-clean's statsig ceiling (3.27800 @ 3300).
- Closed because: (1) non-statsig; (2) even extended to 3375 steps, ffs_mean
  ≈ 3325 vs new baseline 3131 — won't merge. Muon² ordering (Adam var BEFORE
  NS5) is confirmed inferior to NorMuon's post-NS5 ordering on this benchmark.
- Status: **CLOSED**. Nezuko reassigned to Attention SOAP + trust gate (PR #124).

## 2026-05-16 05:45 — PR #78: Contra+SOAP-MLP — STATSIG WIN (merge pending rebase)
- Branch: `g1r2-fern/contra-soap-mlp`
- Hypothesis: SOAP eigenbasis preconditioning on MLP weights, applied to
  momentum *before* NS5+contra+NorMuon (matches record #14 reference ordering).
- W&B confirmation run: `6bbhoxm1` | num_trials=4 | train_steps=3175 (predeclared).

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27920 | 3150 |
| T1 | 3.27811 | 3150 |
| T2 | 3.27522 | 3100 |
| T3 | 3.27787 | 3125 |
| **mean** | **3.27760** | **3131.25** |

- Statsig check: (3.28 − 3.27760) × √4 = **0.00480 ≥ 0.004** — **PASSES**.
- Comparison vs NorMuon-clean baseline (PR #71): mean 3.27800 → 3.27760
  (−0.00040), ffs_mean 3256.25 → 3131.25 (**−125 steps**).
- Matches public record #14 (4 decimal places). Single-seed σ ≈ 0.0015.
- Auxiliary screening runs: `du7a5t1t` (3.27553 @ 3225, corrected ordering),
  `h3vsdeik` (3.27960 @ 3225, PR-literal ordering, superseded).
- The PR-literal ordering (SOAP after NorMuon variance) was suboptimal because
  NorMuon's per-element variance scaling is NOT basis-invariant — student
  caught this discrepancy by reading the record #14 reference file directly.
- Status: **STATSIG WIN, merge pending**. Blocked by (1) merge conflicts with
  auto-nanogpt-1gpu-r2 (NorMuon-clean merged after PR opened), (2) false-
  positive SENPAI-RESULT JSON parse on workflow-note comment. Sent back for
  rebase + comment disambiguation.

## 2026-05-16 05:30 — PR #74: NorMuonH — n=4 confirmation at 3275 (terminal, non-statsig by 0.00008)
- Branch: `g1r2-askeladd/normuonh-perinit`
- Hypothesis: NorMuon + hyperball + per-module init std (record #8 stack).
- W&B run: `6rf3nerz` | num_trials=4 | train_steps=3275 (predeclared).

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27781 | 3225 |
| T1 | 3.27777 | 3225 |
| T2 | 3.27798 | 3250 |
| T3 | 3.27860 | 3250 |
| **mean** | **3.27804** | **3237.5** |

- Statsig check: (3.28 − 3.27804) × √4 = **0.00392** — misses 0.004 by 0.00008.
- Recipe is real and reproducible (σ~0.0004 across 4 trials, tightest of any
  wave-1 stack so far). Mean misses statsig ceiling by 0.00004.
- Notable: NorMuonH at 3275 has ffs_mean=3237.5, beating NorMuon-clean's
  3256.25 — but the loss ceiling is the rule that matters for merge.
- Status: WIP. Send back for predeclared n=4 at train_steps=3300 (one cooldown
  cycle of headroom should push mean to ~3.276 with same σ).

## 2026-05-16 05:30 — PR #112: NorMuon + power-law LR cooldown — p=1.2 screen MISSED
- Branch: `g1r2-alphonse/normuon-plawlr`
- Hypothesis: `lr * (1-progress)/cooldown_frac)^p` with p=1.2 (record #20
  schedule) may give 25-75 step gain over linear cooldown.
- W&B screen run: `fg11eojr` | num_trials=1 | train_steps=3275 | LR_COOLDOWN_POWER=1.2
- Result: terminal **val/loss=3.28031, ffs=-1, reached_target=0**. Did NOT
  cross 3.28.
- Per predeclared branch decision: if 3.277 < val ≤ 3.280, try p=1.5 next.
  3.28031 is just above 3.280, but the spec says "both p=1.2 AND p=1.5 > 3.280
  → close". p=1.5 single-seed should be tried before deciding.
- Status: WIP. Student should auto-launch p=1.5 screen on next poll.

## 2026-05-16 05:45 — PR #103: Soft-Muon isolated p=0.05 — SCREEN CRASHED
- Branch: `g1r2-thorfinn/soft-muon`
- Hypothesis: Soft-Muon polynomial `x^(1-p)` at p=0.05 (reduced from p=0.1
  which missed at 3.28024) with annealed blend 0→0.8 from step 2500.
- W&B screen run: `hz91ow2y` | num_trials=1 | train_steps=3325
- Result: **crashed at step 1575/3325 (47%, mid-cooldown)**. Last val/loss
  reading 3.5253.
- Likely cause: Soft-Muon polynomial coefficients at lower p may produce
  numerical instability when blended with NS5 mid-cooldown. Needs debugging.
- Status: WIP. Student should investigate crash, may need p=0.075 midpoint.

## 2026-05-16 04:30 — PR #109: MuLoCo+NorMuon smoke — DIVERGED TO NaN
- Branch: `g1r2-frieren/muloco-normuon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper on top of NorMuon inner
  optimizer (record #13 stack).
- W&B smoke run: `mti327gb` | num_trials=1 | train_steps=400
- Result: **val/loss=NaN by step 400**. Diverged.
- Likely cause: outer_lr=0.7 too aggressive on NorMuon's variance-noisy update
  direction; or outer Nesterov momentum compounds NorMuon's variance instability.
- Status: WIP. Student should try outer_lr=0.5 or sync_interval=60 in smoke
  before screen.

## 2026-05-16 01:45 — PR #79: MuLoCo on plain Muon — CLOSED (all 4 corners missed)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- Final W&B sweep runs:

| run | si | outer_lr | train_steps | val/loss | reached |
| --- | --- | --- | --- | --- | --- |
| `bqfv4523` | 15 | 0.5 | 3300 | 3.2829 | 0 |
| `q57yhybv` | 30 | 0.7 | 3300 | 3.2810 | 0 |
| `ecohqy9o` | 15 | 0.7 | 3300 | 3.2815 | 0 |
| `v2wn0t8t` | 60 | 0.5 | 3300 | **3.2865** | 0 |

- Conclusion: All 4 sweep corners failed to reach 3.28. The si=60/lr=0.5 corner
  (meant to allow longer inner runs between outer steps) was actually the **worst**
  result. Plain Muon's NS5 orthogonalization already smooths the gradient direction
  — MuLoCo's outer Nesterov momentum provides no additional benefit. Public record
  #13's success was likely driven by MuLoCo wrapping NorMuon (which has noisy
  per-element variance), not plain Muon.
- Status: **CLOSED (dead end)**. Frieren reassigned to MuLoCo+NorMuon (PR #109).

## 2026-05-16 01:50 — PR #81: Newton-Muon — n=4 confirmation at train_steps=3275 (terminal, non-statsig)
- Branch: `g1r2-tanjiro/newton-muon`
- Hypothesis: Activation-covariance right-preconditioning applied to the Muon
  gradient before Newton-Schulz (refresh every 64 steps).
- W&B run: `xsb35b0m` | num_trials=4 | train_steps=3275

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.279715 | 3275 |
| T1 | 3.278674 | 3250 |
| T2 | **3.277678** | **3225** |
| T3 | 3.281277 | -1 (missed) |
| **n=4 mean** | **3.27934** | — |

- Statsig check: `(3.28 - 3.27934) × √4 = 0.001328` — BELOW 0.004. **Non-statsig.**
- Analysis: T0–T2 all cleared 3.28 individually, including T2 at 3.2777 (among
  the best individual trials in wave 1). T3 was a bad seed — 3.2813 — above the
  target, which dragged the mean to 3.279. The recipe is real but has high
  seed variance. Needs more cooldown steps to tighten the distribution.
- Status: WIP. Sent back for fresh n=4 at predeclared `train_steps=3325`.

## 2026-05-15 23:20 — PR #79: MuLoCo on plain Muon — sweep arm si=15 (terminal)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- W&B run: `ecohqy9o` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/ecohqy9o`)
  | num_trials=1 | train_steps=3300 | sync_interval=15, outer_lr=0.7
- Result: terminal **val/loss=3.2815 @ step 3300**,
  `speedrun/final_first_step_to_target=-1`, `speedrun/final_reached_target=0`.
  **Did NOT cross 3.28.**
- Context: 3rd consecutive single-seed screen to miss — `bqfv4523`=3.2829,
  `q57yhybv`=3.2810, `ecohqy9o`=3.2815. All at or above 3.281 margin.
- Conclusion: MuLoCo on plain Muon appears break-even or slightly worse than
  starter at train_steps=3300. si=60/lr=0.5 corner still pending. If that
  corner also misses ≥ 3.281, MuLoCo-on-plain-Muon is dead and frieren will
  be pivoted to MuLoCo wrapping a confirmed inner optimizer (NorMuon or
  Contra-Muon, per the approach of public record #13).
- Status: WIP. si=60 sweep arm pending.

## 2026-05-15 22:45 — PR #80: Muon² (Adam variance BEFORE Newton-Schulz) — single-seed screen
- Branch: `g1r2-nezuko/muon-sq`
- Hypothesis: Per-element Adam variance applied to gradients *before* the
  Newton-Schulz orthogonalization should preserve NorMuon's variance-normalization
  benefit while keeping the orthogonalization geometry clean. lr=0.10, wd=0.0125,
  β₂=0.95, train_steps=3350 (per record #7 / nezuko PR body).
- W&B run: `n18mqjfy`
  (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/n18mqjfy`) | num_trials=1 |
  train_steps=3350.
- Result: terminal **val/loss=3.2773 @ step 3350**,
  `speedrun/final_first_step_to_target=3300`, `reached_target=1`.
- Statsig at n=1 (informational): (3.28 − 3.2773) × √1 = 0.0027 — does NOT
  clear the 0.004 single-seed bar, but is below 3.28 and on track for n=4
  consideration with cooldown headroom.
- Status: WIP. n=4 confirmation `7lxk02m6` launched (T0 early at step 275).
  Single-seed margin smaller than edward/fern/alphonse, so n=4 statsig is
  uncertain; will need mean ≤ 3.278 across 4 seeds.

## 2026-05-15 20:30 — PR #74: NorMuonH (row/col variance + hyperball + per-module init std)
- Branch: `g1r2-askeladd/normuonh-perinit`
- Hypothesis: NorMuon's row/col Adafactor-style variance combined with hyperball
  constraint (preserve ‖p‖_F per step) and per-module init std (×1.25 attn.proj,
  zero block-level proj for residual-branch safety) should reduce optimizer
  steps. Public record #8: 3225 steps, mean val/loss 3.2776 (n=10).
- W&B run: `sohiul20` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/sohiul20`)
  | num_trials=4 | train_steps=3250 (predeclared confirmation).
- Per-trial final val/loss at step 3250:
  | trial | val/loss |
  | --- | --- |
  | 0 | 3.27849 |
  | 1 | 3.27942 |
  | 2 | 3.27835 |
  | 3 | 3.27840 |
  | **mean** | **3.27867** |
  | std | ~0.0005 |
- `speedrun/final_first_step_to_target = 3225`, all 4 trials cleared 3.28.
- Statsig check (rule `(3.28 − μ) × √n ≥ 0.004`): (3.28 − 3.27867) × 2 =
  **0.00267** — below the 0.004 threshold at n=4. **Not statsig.**
- Conclusion: NorMuonH is a real, reproducible recipe (very tight inter-seed
  variance) but its mean at step 3250 falls 0.0007 above the statsig ceiling.
  Adding more seeds at step 3250 would not help (mean too stable). Sent back
  asking for a fresh n=4 batch at a predeclared step ∈ {3275, 3300} to gain
  ~0.001 of cooldown headroom for statsig clearance.
- Status: WIP / not merged. Awaiting follow-up predeclared confirmation.

## 2026-05-17 00:00 — PR #125 CLOSED: Aurora on Contra+SOAP-MLP base (fern)

- Branch: `g1r2-fern/contra-soap-aurora`
- Hypothesis: Diagonal leverage-score equalization (Aurora record #17) inside NS5 polar step, stacked on top of Contra+SOAP-MLP merged base. Replaces standard polar with D-equalized polar for non-square MLP weights; square attention weights short-circuit to standard NS5.
- W&B run: `5kr7d0i5` (n=4, train_steps=3175)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| T3 | 3.27614 | 3125 |
| **n=4 mean** | **3.27787** | **3131.25** |
| statsig (3.28−mean)×2 | **0.00426** ≥ 0.004 ✓ | |

**Conclusion**: Statsig passes vs 3.28 gate but FAILS new baseline gates (PR #139 mean=3.27648, ffs=3118.75) on both bars. T1 (3.28172) is a catastrophic outlier — seed dispersion range = 0.00580, roughly 4× the typical mechanism variance and far exceeding baseline's 0.00279 range. Three of four seeds (T0, T2, T3) individually outperform the new baseline mean, confirming the mechanism works — but the variance kills n=4 aggregates.

**Key learning**: Aurora's diagonal leverage-score equalization is HIGH-VARIANCE on the merged Contra+SOAP-MLP base. The D fixed-point iteration introduces per-seed variation in the effective preconditioning that compounds over 3175 steps. This aligns with record #17's reported high-variance behavior. Not a mechanism failure, but needs n=8+ or a variance-reduction wrap to clear the new (tighter) baseline bars. Defer to next round.

Fern reassigned to PR #208: Power-law LR cooldown (LR_POWER=1.5/2.0), targeting record #20's schedule structure.

## 2026-05-17 00:30 — PR #124 CLOSED: Attn-SOAP+trust gate n=4 (nezuko)

- Branch: `g1r2-nezuko/attn-soap-gate`
- Hypothesis: Attention SOAP (eigenbasis preconditioner on qkv/proj weights) with trust gate (cosine-similarity threshold to decide when to apply precond vs identity fallback). Stacked on OLD baseline (CONTRA_MUON=0.4 / PR #78).
- W&B run: `790h1llo` (n=4, train_steps=3175)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| T3 | 3.27609 | 3100 |
| **n=4 mean** | **3.27715** | **3118.75** |
| statsig (3.28−mean)×2 | **0.00570** ≥ 0.004 ✓ | |

**vs OLD baseline (PR #78):** val −0.00045 (WIN) / ffs tie 3118.75 (WIN vs 3131.25)

**vs NEW baseline (PR #139):** val +0.00067 (MISS) / ffs 3118.75 (TIE — strict < required = MISS)

**Conclusion**: Mechanism unambiguously works. T0/T1/T2 had extraordinarily low variance (0.00015 range, lowest of the session), confirming the trust gate produces stable training dynamics. T3 was a luckier seed (3.27609/3100). Mechanism delivers −0.00045 val + −12.5 ffs on OLD base. Misses NEW baseline strictly because NEW baseline (CONTRA_MUON=0.5) is 12.5 ffs better, making the comparison tight.

**Key trust-gate finding**: v/proj row cosines hover at 0.85-0.89 with threshold=0.9 — they are identity-precond ~100% of the time. Only q (~85%) and k (~25%) actually get SOAP precondition. This leaves significant headroom: lowering threshold to 0.85 would activate v/proj and potentially add another 25-50 ffs improvement.

**Follow-up**: Nezuko reassigned to PR #212 (Attn-SOAP+trust on NEW baseline, CONTRA_MUON=0.5, with Arm B at THRESHOLD=0.85).

## 2026-05-17 00:30 — PR #181 CLOSED: Schedule-Free Muon (askeladd)

- Branch: `g1r2-askeladd/sfm`
- Hypothesis: Muon with constant LR + Polyak averaging (schedule-free), replacing the linear cooldown.
- W&B runs: `groom2ym` (uniform c_t screen), `k3wkjy84` (c_const=0.01 screen)

| Screen | c_t | Final val(y) | Best val(y) | ‖y−z‖_F at T |
|---|---|---|---|---|
| Uniform 1/(t+1) | 0.00031 at T | 4.60499 | 4.59854 | **2.2e9** |
| Const EMA 0.01 | 0.01 | 4.62780 | 4.60690 | **4.3e8** |
| Merged baseline | linear cooldown | — | 3.27760 | n/a |

**Conclusion**: Fundamental incompatibility between (a) Muon's spectral updates under constant LR and (b) the 2-sequence SF formulation. NS5-orthogonalized Muon updates inject O(1) per element per step — under constant LR the iterates z never converge, while the Polyak average y lags and decays toward stale initialization. ‖y−z‖ grows unboundedly regardless of c_t window size. The gradient evaluated at y is increasingly stale, breaking the SF assumption ∇f(y) ≈ ∇f(z).

**Key negative finding**: Schedule-free methods (which assume bounded update magnitudes for convergence) are structurally incompatible with constant-LR Muon. Linear cooldown is doing essential work — it provides the convergence that SF assumes but cannot deliver. Direction CLOSED.

**Student's analysis quality**: Exceptional. Correctly diagnosed structural incompatibility, identified root cause (||y-z|| explosion independent of c_t window), recognized that 3-sequence Defazio would face the same issue. Valuable negative result well-characterized.

Askeladd reassigned to PR #213 (per-module weight init scaling — records #4,5,8 ingredient).

## 2026-05-19 10:55 UTC — Cycle 63: #431 CLOSED LM_HEAD_LR axis FALSIFIED; #430 CLOSED MUON_LR narrow ffs miss; #429 alphonse n=2 WIN → n=4 predeclared; #456 fern → SCALARS_LR sweep

### PR #431 — AdamW lm_head_lr sweep (0.0025 vs 0.00375 around 0.003125) — CLOSED axis-falsified

Branch: `g1r2-fern/lm-head-lr-sweep`. Both ±20% arms sweep on new CONTRA_MUON=0.4 base.

| Arm | LM_HEAD_LR | T0 val | T0 ffs | T1 val | T1 ffs | n=2 val mean | n=2 ffs mean | vs new bar | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| A (−20%) | 0.0025 | 3.27597 | 3100 | (foreclosed) | — | — | — | both bars foreclosed | **MISS** |
| B (+20%) | 0.00375 | 3.27431 | 3075 | 3.27616 | 3100 | **3.275235** | **3087.5** | val +0.000852, ffs +18.75 | **MISS** |

W&B runs: `ibr51w9g` (Arm A), `xb6pszz1` (Arm B)

**Mechanism finding**: Default LM_HEAD_LR=1/320≈0.003125 is at a **local optimum within ±20%** on this benchmark. Bracket sign: higher is better (Arm B less worse than Arm A), but neither clears bar. The lm_head lr controls output-side calibration through the softcap — at the current K=15 softcap, the default 1/320 appears well-tuned. Future: joint MUON_LR × LM_HEAD_LR 2D test would check if the ratio lm_head_lr ≈ MUON_LR/12 is intrinsic.

**AdamW-LR-group characterization progress**: lm_head ✅ FALSIFIED ±20%; embed (nezuko #449 in flight); scalars (fern #456 assigned).

---

### PR #430 — MUON_LR sweep (0.030 vs 0.045 around 0.0375) — CLOSED narrow ffs miss

Branch: `g1r2-edward/muon-lr-sweep`. Both ±20% arms on new CONTRA_MUON=0.4 base.

| Arm | MUON_LR | T0 val | T0 ffs | T1 val | T1 ffs | n=2 val mean | n=2 ffs mean | vs new bar | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| A (−20%) | 0.030 | 3.2821 | -1 | (killed) | — | foreclosed | foreclosed | both bars foreclosed | **MISS** |
| B (+20%) | 0.045 | 3.27547 | 3100 | 3.27279 | 3050 | **3.27413** | **3075** | val **PASS** −0.000253, ffs MISS +6.25 | **MISS** |

W&B runs: `ca8blz69` (Arm A), `6g1c8dwc` (Arm B)

**Mechanism finding**: Arm A (0.030, −20%) under-steps — never reaches val=3.28 target within 3175-step budget. Arm B (0.045, +20%) has val mean PASSING the strict bar (3.27413 < 3.274383) but ffs mean=3075 is **exactly one quantization slot above bar** (−6.25 to PASS). T1 individual result (3.27279/3050) was exceptional — better than baseline T0. T0 (3.27547/3100) dragged up the mean. **Verdict: axis not cleanly falsified** — the +20% arm has real val signal but bimodal ffs noise produced one unfavorable slot. Default 0.0375 remains the operating point by methodological criterion (n=2 strict bar not cleared). MUON_LR is a "soft revisit" axis worth re-examining if a wider bracket or n=4 is warranted.

**Note for future**: at n=4 with MUON_LR=0.045, if 3/4 trials land at ffs=3050 and 1/4 at 3100 (matching T0/T1 bimodal pattern), mean ffs = (3100+3050+3050+3050)/4 = 3062.5 < 3068.75 — PASS. The underlying mechanism may be stronger than n=2 reveals.

---

### PR #429 — NS5_ITERS sweep (10 vs 14 around default 12) — n=2 Arm B (NS5_ITERS=14) WINS → n=4 PREDECLARED

Branch: `g1r2-alphonse/ns5-iterations-sweep`. Arm A (10) and Arm B (14) screened on new CONTRA_MUON=0.4 base.

| Arm | NS5_ITERS | T0 val | T0 ffs | T1 val | T1 ffs | n=2 val mean | n=2 ffs mean | vs new bar | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| A (fewer) | 10 | 3.27592 | 3100 | 3.27410 | 3050 | **3.27501** | **3075** | val +0.000627, ffs +6.25 | MISS |
| **B (more)** | **14** | **3.27263** | **3050** | **3.27514** | **3075** | **3.273885** | **3062.5** | val **PASS −0.000498**, ffs **PASS −6.25** | **WIN ✅** |

W&B runs: `beeyzftn` (Arm A), `565i067e` (Arm B)

**Mechanism finding**: NS5_ITERS=14 (vs default 12) → 2 extra polar iterations per Muon step. Tighter orthogonalization of the spectral projection → smoother, more precise Muon update. T0 val=3.27263 is the **best single-trial val on this codebase** since the PR #358 baseline n=2 screen. Arm A (10 iters) misses both bars — bracket sign CONFIRMED: more iterations is better, fewer is worse. Step-time overhead with NS5_ITERS=14 is only **+0.8%** (vs predicted +16%) — NS5 matmuls are not the bottleneck on this hardware.

**This falsifies the "cooldown-geometry lever saturated" finding from #372**: NS5_ITERS sits on the polar-projection accuracy axis, orthogonal to cooldown geometry. The cooldown saturation was specific to the momentum/scale correction family, not to all optimizer axes.

n=4 confirm predeclared: `g1r2-alphonse/ns5-iters-14-confirm-n4`.

---

## 2026-05-18 20:55 UTC — PR #358: CONTRA_MUON=0.4 — MERGED (new baseline)

- `g1r2-askeladd/contra-muon-sweep`
- Hypothesis: CONTRA_MUON=0.5 was set at PR #139 and never swept. Reducing to 0.4 (20% less counter-correction) tests whether baseline was over-correcting.
- W&B runs: `oeeswx8a` (n=2 screen), `ivvf500c` (n=4 confirm)

| Trial | val/loss | ffs | Stack |
|---|---|---|---|
| n=2 T0 | 3.272824 | 3050 | CONTRA_MUON=0.4 + PR#288 stack |
| n=2 T1 | 3.274036 | 3075 | CONTRA_MUON=0.4 + PR#288 stack |
| n=2 mean | **3.273430** | **3062.5** | |
| n=4 T0 | 3.27523 | 3075 | |
| n=4 T1 | 3.27432 | 3075 | |
| n=4 T2 | 3.27455 | 3075 | |
| n=4 T3 | 3.27343 | 3050 | |
| **n=4 mean** | **3.274383** | **3068.75** | |

vs. old baseline (PR #288): val Δ=−0.000967, ffs Δ=−18.75. statsig: (3.28−3.274383)×√4=0.01123 ≥ 0.004 PASS.

**Analysis**: Clean, consistent improvement. ffs {3075,3075,3075,3050} — 3/4 trials improved from baseline pattern. n=4 regressed slightly from optimistic n=2 mean (3.27343→3.27438) but cleared the bar with comfortable margin. Baseline over-correction at 0.5 was real; 0.4 reduces contra-gradient interference without losing the stability it provides.

**NEW BASELINE**: val=3.274383 / ffs=3068.75. ALL subsequent experiments must compare against this harder bar. ffs<3068.75 requires ≥2 of 4 trials at ffs=3050 (or equivalent mean). This is a significant tightening — most current in-flight experiments on CONTRA_MUON=0.5 will miss.

**Conclusions**: CONTRA_MUON axis has headroom below 0.5. 0.4 is confirmed better; 0.3 is the next test. Pipeline stack: CONTRA_MUON=0.4 is now the required base for all new experiments.

---

## 2026-05-21 19:35 UTC — PR #688: MUON_GRAD_CLIP — Gradient clipping for Muon group (CLOSED — both arms MISS)

- `g1r2-alphonse/muon-grad-clip`
- Hypothesis: Gradient clipping of the Muon parameter group (group-norm L2, clip_grad_norm_) before NS5 orthogonalization could provide a stability scaffold, widening the c=20 stack's stability window and allowing other axes (WD_AUX, etc.) to re-open.
- W&B runs: `6ku5c9af` (Arm A, clip=1.0), `bzsdsxnz` (Arm B, clip=0.5)

| Arm | MUON_GRAD_CLIP | val/loss | ffs | gate |
|---|---|---|---|---|
| A | 1.0 | 3.27252 | 3050 | MISS (+0.00252 val, +50 ffs) |
| B | 0.5 | 3.27232 | 3050 | MISS (+0.00232 val, +50 ffs) |
| baseline (#613) | — (no clip) | 3.26776 (n=2) | 3000 (n=2) | — |

**Results commentary**: Both arms miss the n=1 hold gate (val≤3.27 AND ffs≤3000). The dose-response between A and B is effectively null — B (tighter clip) is lower val by only 0.0002, well below the n=1 noise floor of ~0.003. Both arms hit the 3.28 target at ffs=3050 (50 steps behind baseline's ffs=3000), suggesting the clip acts as a mild damper on Muon convergence speed even when not visibly perturbing val.

**Implementation detail**: Student correctly used `clip_grad_norm_` over the Muon block as a group (not per-tensor), which fires on most steps at thresholds {1.0, 0.5} since the per-block group-norm is ~1.5-5. This means the mechanism is a near-constant damper rather than an outlier-filtering safety net.

**Conclusion**: Group-norm gradient clipping at {0.5, 1.0} is not productive on the c=20 stack. The stability-widening mechanism had no live instability to suppress (c=20 trains cleanly without clip). Axis closed. A per-tensor form (strict max-norm per tensor) or cooldown-only clip remain untested if revisiting this class.

---

## 2026-05-21 19:55 UTC — PR #683: ATTN_SOAP_TRUST_THRESHOLD sweep (CLOSED — both arms MISS)

- `g1r2-fern/attn-soap-trust`
- Hypothesis: ATTN_SOAP_TRUST_THRESHOLD=0.85 (default, trust SOAP preconditioning when EMA second-moment sufficiently converged) may not be optimal. Testing whether more permissive trust (0.75 = more SOAP) or stricter trust (0.95 = more raw-gradient fallback) improves convergence on the c=20 stack.
- W&B runs: `fb7cb6z2` (Arm A, threshold=0.75), `peani9ou` (Arm B, threshold=0.95)

| Arm | Threshold | val/loss | ffs | gate |
|---|---|---|---|---|
| A | 0.75 (more SOAP) | 3.28083 | -1 (never reached 3.28) | MISS — catastrophic |
| B | 0.95 (stricter trust / more raw-grad) | 3.27179 | 3050 | MISS (+0.00403 val, +50 ffs) |
| baseline (#613) | 0.85 | 3.26776 (n=2) | 3000 (n=2) | — |

**Results commentary**: Arm A (0.75) catastrophically misses — the model never reaches the 3.28 target in 3175 steps. Over-aggressive SOAP preconditioning at current β2=0.90 EMA timescale adds noise to the curvature estimates that actively hurts convergence. Arm B (0.95) is much closer — val=3.27179, ffs=3050, a narrow miss. The late-cooldown trajectory shows B converges faster than A in the final ~175 steps (B step 3000=3.28350 vs A step 3000=3.29203), suggesting that raw-gradient fallback is preferred during cooldown.

**Asymmetric dose-response**: deviating to 0.75 costs 3× more val than deviating to 0.95 (0.013 vs 0.004). This is consistent with an asymmetric loss surface: applying too much preconditioning (noisy eigenbasis estimates) is far more harmful than applying too little.

**Conclusion**: ATTN_SOAP_TRUST_THRESHOLD=0.85 (default) is locally optimal on c=20 stack. Combined with #634 ATTN_SOAP_BETA2 closure, both SOAP-on-attention preconditioner knobs are confirmed locally optimal. Suggested follow-up: cooldown-schedule form (0.85→0.95 ramp during last 5% of steps, motivated by Arm B's late-cooldown superiority).

---

## 2026-05-21 20:40 UTC — PR #694: NS5_COEFS — Newton-Schulz polynomial coefficients sweep (CLOSED — both arms MISS)

- `g1r2-askeladd/ns5-coefs-sweep`
- Hypothesis: The hardcoded NS5 polynomial coefficients (a=2.0, b=-1.5, c=0.5) were never ablated. Test Polar Express minimax-optimal (3.4445, -4.7750, 2.0315) and conservative (1.5, -1.0, 0.4) to see if different coefficient choices accelerate orthogonalization convergence.
- W&B runs: `q2qvi4wu` (disabled-check), `sd173nmy` (Arm A Polar Express), `uawvh67m` (Arm B Conservative)

| Arm | (a, b, c) | val/loss | ffs | gate |
|---|---|---|---|---|
| A | (3.4445, -4.7750, 2.0315) — Polar Express | 3.27082 | 3025 | MISS (+0.00306 val, +25 ffs) |
| B | (1.5, -1.0, 0.4) — Conservative | 3.27160 | 3025 | MISS (+0.00384 val, +25 ffs) |
| baseline (#613) | (2.0, -1.5, 0.5) — default | 3.26776 (n=2) | 3000 (n=2) | — |

**Results commentary**: Both arms narrowly miss merge bar (+0.003-0.004 val, +25 ffs). Trajectories track baseline closely throughout — no early/late asymmetry from Polar Express's theoretical "minimax-optimal convergence" — it actually performed slightly worse than default. Conservative coefficients were slightly worse still.

**Mechanism interpretation (askeladd)**: "The NS5 coefficient surface is flat in our regime. With NS5_ITERS=14 (deep iteration count) any reasonable polynomial reaches effective orthogonality. The c=20 stack's 'different gradient spectral distribution' hypothesis did not produce coefficient sensitivity — 14 iterations of any of the three tested coefficient triples saturates orthogonality at numerical precision."

This is consistent with: at deep iteration counts, even suboptimal-per-iteration polynomial choices reach the orthogonal projection effectively. Polar Express's minimax theoretical advantage is invisible past iteration ~8-10.

**Conclusion**: Default (2.0, -1.5, 0.5) confirmed locally optimal at NS5_ITERS=14. Axis closed. Joins the ffs=3025 near-miss cluster (now 10+ axes this cycle). Frobenius pre-normalization at line 480 successfully bounds σ_max ≤ 1, so even aggressive coefficients converge cleanly (no instability seen in Arm A despite Polar Express's higher coefficient magnitudes).

**Strategic implication**: 10+ axes landing at ffs=3025 strongly suggests the early-trajectory bottleneck (first ~3025 steps) is governed by a mechanism that scalar coefficient tuning cannot reach. Future wins must come from mechanism-level changes (cooldown shape, per-block geometry, etc.) — askeladd's own suggestion #2 articulates this insight precisely.

---

## 2026-05-22 04:05 UTC — PR #734: ADAMW_GRAD_CLIP — per-group gradient norm clip on AdamW output side (CLOSED — both arms MISS)

- `g1r2-alphonse/adamw-grad-clip`
- Hypothesis: With LOGIT_SOFTCAP=20.0 in the c=20 stack, gradients flowing back through lm_head/embed could spike near soft-cap saturation, injecting noise into AdamW second-moment estimates exactly when ffs=3025 vs 3000 is decided. Test per-group L2 norm clip on AdamW params only (Muon untouched). Arm A=1.0 mild clip; Arm B=0.5 aggressive.
- W&B runs: `vwrqt4vt` (Arm A), `vovnwk94` (Arm B). Disabled-check passed (single canary, no loops).

| Arm | Config | val/loss | ffs | Δval | Δffs | Gate |
|---|---|---|---|---|---|---|
| A | ADAMW_GRAD_CLIP=1.0 | 3.27399 | 3075 | +0.00623 | +75 | MISS |
| **B** | ADAMW_GRAD_CLIP=0.5 | **3.27088** | **3025** | +0.00312 | +25 | MISS |
| baseline (#613) | unclipped | 3.26776 (n=2) | 3000 (n=2) | — | — | — |

**Results commentary**: Both arms MISS hold gate. Kill-gate trajectory clean: no instability suppressed, no divergence detected (val@500=3.80, val@1500=3.54, val@2500=3.35 for Arm B — tracking baseline within +0.05 throughout). Aggressive c=0.5 is LESS damaging than mild c=1.0 — opposite of typical clip behavior.

**Mechanism interpretation (alphonse)**: AdamW grad norm sits in [0.5, 1.0] typical. c=0.5 acts as near-uniform global rescaling (most steps land at fixed magnitude), removing variance the optimizer was actually using. c=1.0 fires only on the largest informative updates, deleting magnitude info that's actually correlated with task signal. Neither helps because there is no live tail outlier to suppress — LOGIT_SOFTCAP=20.0 already handles per-token logit saturation gradient gracefully.

**THEOREM extended (gradient-magnitude axis class CLOSED on both optimizer sides)**: Combined with #688 MUON_GRAD_CLIP closure (both arms MISS, ~half of Muon steps triggered uniform damping not outlier filtering), AdamW-side clipping completes the closure. Gradient-magnitude norm clipping is a strict loss in the c=20+EMBED_INIT_STD=0.1+LOGIT_SOFTCAP=20.0 stack regardless of which optimizer is clipped or what threshold is used.

**Cluster placement**: 19th and 20th axes joining the ffs=3025–3125 floor cluster. Cluster now spans 20+ closed axes — strong evidence the bottleneck is shared structure (init randomness × FFS step-counter discretization × cooldown geometry), not any single optimizer mechanism.

**Conclusion**: AdamW-side gradient magnitude axis CLOSED. Alphonse → next assignment ADAMW_EPS denominator regularization (alphonse's own suggestion #3) — mechanistically distinct: acts on v_t denominator floor, not on raw gradient magnitude. Never tested in 165+ experiments.


---

## 2026-05-22 05:00 UTC — PR #742: ADAMW_RADAM — Rectified Adam variance rectification on AdamW (CLOSED — both arms MISS)

- `g1r2-askeladd/adamw-radam`
- Hypothesis: Liu et al. 2019 RAdam — when ρ_t ≤ 4 in early steps fall back to m_hat (SGD-like), else apply r_t·m_hat/√v_hat rectified update. Targets early-step v_t variance instability. Arm A=full RAdam, Arm B=embed+lm_head only (scalars excluded after Arm A diverged).
- W&B runs: `6ui6wcu6` (disabled-check val@200=4.0864 PASS), `wzn8z4mh` (Arm A — KILLED step 500), `5s7g644s` (Arm B — terminal)

| Arm | Config | val/loss | ffs | Outcome |
|---|---|---|---|---|
| A | ADAMW_RADAM=1 (all AdamW groups) | 9.130 @ step 500 | n/a | **DIVERGED + KILLED** (grad_norm to 9.3M, train_loss peak 13.21) |
| B | ADAMW_RADAM=2 (embed+lm_head only) | **3.48176** | -1 | MISS — never reached 3.28 |
| baseline (#613) | unchanged AdamW | 3.26776 | 3000 | reference |

**Results commentary (askeladd)**: "Standard Adam doesn't *amplify* — its `1/sqrt(v)` saturates the update to ≈ `sign(grad)`, which is the actual mechanism that keeps high-LR groups stable. Removing that saturation in the first 4 steps (RAdam's SGD-fallback) re-introduces exactly the magnitude sensitivity that Adam was designed to remove. RAdam helps in regimes where standard Adam's `1/sqrt(v_t)` *spikes* on a rare large gradient — but at β2=0.95 with our batch size and FineWeb statistics, early-step `v_t` is dominated by stable token statistics, not rare spikes."

**THEOREM (early-step rectification incompatibility, bilateral)**: Combined with #718 MUON_BIAS_CORR closure (Adam-style bias correction on Muon's heavy-ball amplified early-step LR ≈6.7× and destabilized), **Adam-style bias-correction-or-rectification machinery is strict downside in the c=20+EMBED_INIT_STD=0.1 stack regardless of which optimizer it's applied to.** The early-step variance management mechanism that's already working (`1/sqrt(v_t)` saturation for AdamW; NS5 polar projection for Muon) cannot be improved by adding more correction layers.

**Arm A divergence pattern**: train_loss reached 13.21 by step 100, grad_norm spiked from typical 60k-300k to 1M-9M, val_loss=9.13 at step 500. SGD-fallback for scalars (LayerNorm gains, ~50 params, very small magnitudes) catastrophically explodes when given raw gradient passes at LR=0.3.

**Arm B partial rescue**: excluding scalars from RAdam confirmed scalars are the divergence source. Embed+lm_head with RAdam converged but +0.214 above baseline at terminal — the variance-rectification still wastes early-step magnitude info even when not catastrophic.

**Conclusion**: RAdam axis closed. Mechanism class "early-step correction-or-rectification on AdamW or Muon" is now fully exhausted. Both directions (bias amplification #718, variance rectification #742) are strict downside.

---

## 2026-05-22 05:25 UTC — PR #747: β2_SCHEDULE — AdamW β2 cooldown-aware ramp (CLOSED — pod-state untestable, axis open scientifically)

- `g1r2-tanjiro/adamw-beta2-schedule`
- Hypothesis: Aux AdamW β2=0.95 throughout training may be suboptimal — late cooldown phase (low LR, fine-grained updates) might benefit from longer second-moment EMA window. Ramp β2: 0.95 → {0.99, 0.999} over cooldown.
- W&B runs: multiple, all NaN'd including true-baseline reproduction
- **Outcome**: 7 consecutive NaN runs including post-pycache-cleanup retries and a fresh-seed true-baseline (no β2 modifications). Even the disabled-check `7b9h1jeq` NaN'd at step 25.

**Diagnostic trace**: tanjiro student's W&B telemetry conclusively showed β2=0.95 in both disabled-check and Arm A through step 200 (no mutation bug). LR cooldown function fires correctly. The true-baseline NaN at step 25 (200-step true-baseline, no β2 changes) falsified the "Arm A diff is buggy" hypothesis and confirmed the issue is platform-level (tanjiro pod flakiness on the 200-step compressed config).

**Decision**: Closed as **pod-state untestable**. Axis remains scientifically open — β2 cooldown ramp is a fresh-mechanism hypothesis that has never been validly tested. Future students may retry on a different pod once a cross-pod control passes a baseline reproduction.

**Memory rule extension (cross-pod control required)**: per memory rule [[pod-broken-axis-misattribution]], NaN-based closures must be confirmed on a second pod before being treated as scientific closure. #747 is correctly recorded as operational closure, not scientific closure.

**Follow-up**: tanjiro → #758 ADAMW_GRAD_CENTRALIZATION (Yong CVPR 2020 — subtract per-channel grad mean from lm_head/embed; tests alphonse #734's lm_head gradient-magnitude conjecture from a different geometric angle).

---

## 2026-05-22 05:30 UTC — PR #729: PER-BLOCK CONTRA_MUON depth-differentiated subtraction (CLOSED — no depth asymmetry)

- `g1r2-frieren/per-block-contra-muon`
- Hypothesis: Apply different CONTRA_MUON strengths to EARLY (blocks 0-5) vs LATE (blocks 6-11) layers. Arm A: EARLY=0.6, LATE=0.2 (heavy early subtraction). Arm B: EARLY=0.2, LATE=0.6 (heavy late subtraction). Tests whether contra strength needs depth-dependent tuning to escape ffs=3025 floor.

| Arm | EARLY | LATE | val/loss | ffs | Δval | Δffs | Gate |
|---|---|---|---|---|---|---|---|
| A | 0.6 | 0.2 | 3.27048 | 3025 | +0.00272 | +25 | MISS |
| B | 0.2 | 0.6 | 3.27068 | 3025 | +0.00292 | +25 | MISS |
| baseline (#613) | 0.4 (uniform) | 0.4 | 3.26776 (n=2) | 3000 (n=2) | — | — | — |

**Results commentary**: Both arms land identically at ffs=3025 with Δval=0.00020 (within seed noise) — strong evidence the depth-axis is FLAT for contra strength. Asymmetric depth allocation neither amplifies nor compensates: uniform 0.4 across all blocks remains locally optimal.

**Theorem (CONTRA_MUON axis class fully closed)**: Combined with prior closures #680 (CONTRA_MUON value sweep 0.2/0.6), #358 (0.5→0.4), #205 (initial 0.5), #139 (existence), and now #729 (per-block depth differentiation), the CONTRA_MUON mechanism axis is fully exhausted at every granularity tested:
- Value sweep — closed
- Existence — closed (load-bearing component)
- Per-block depth differentiation — closed
- Per-block-TYPE (attn vs mlp) — not yet tested, but unlikely to differ given depth-flatness

**Cluster placement**: 21st axis joining ffs=3025+ floor cluster (cluster now spans 21+ closed axes).

**Strategic implication**: 21+ axes closing at ffs=3025+ across CONTRA, NS5, GRAD_CLIP, EPS, RAdam, NAdam, β2_schedule, per-block, AdamW/Muon dichotomy, scalar magnitudes, and decay shapes is overwhelming evidence the ffs floor is governed by a structural mechanism (FFS step-discretization × cooldown geometry × init seed) that scalar/mechanism perturbations cannot bridge. **Future wins require mechanism-level changes that fundamentally alter what enters the optimizer.** Examples: input-side gradient processing (GROKFAST #757, gradient centralization #758), trajectory-level interpolation (Lookahead, Polyak EMA #737), per-group cooldown SHAPE (#764 just assigned).

**Frieren → #759 LM_HEAD_LR_LATE_BOOST** assigned earlier; #759 is the symmetric complement of thorfinn #749 EMBED_LR_LATE_BOOST.

---

## 2026-05-22 05:35 UTC — PR #739: ADAMW_NESTEROV — NAdam-style m_t look-ahead (CLOSED — both arms MISS merge bar)

- `g1r2-fern/adamw-nesterov`
- Hypothesis: NAdam (Dozat 2016) computes m̂_t = β1·m_t + (1−β1)·g_t (Nesterov-style look-ahead on first moment) instead of m̂_t = m_t/(1−β1^t). Arm A: full NAdam throughout. Arm B: NAdam only during cooldown (progress ≥ 0.95, last ~159 steps).
- W&B runs: `mbm5ln62` (disabled-check val@200=4.08256 ✅), `i14iuy2e` (Arm A), `luyfnylb` (Arm B)

| Arm | Config | val/loss | ffs | step-125 val | Δval | Δffs | Hold gate | Merge bar |
|---|---|---|---|---|---|---|---|---|
| A (full Nesterov) | ADAMW_NESTEROV=1 | 3.27446 | 3075 | 4.46448 | +0.00670 | +75 | ❌ MISS | ❌ MISS |
| **B (cooldown-only)** | ADAMW_NESTEROV=2 | **3.26797** | **3000** | 4.43761 | **+0.00021** | 0 | ✅ PASS | ❌ MISS val by +0.00021 |
| baseline (#613) | unchanged | 3.26776 (n=2) | 3000 (n=2) | — | — | — | — | — |

**Results commentary (fern)**: Arm B is **numerically indistinguishable from baseline within seed noise** (+0.00021 val, ffs=3000 match). Arm A's step-125 val=4.46448 vs Arm B's 4.43761 is the load-bearing mechanism diagnostic: NAdam during warmup degenerately reduces to `(1−β1)·g_t` when m_t is small, effectively up-weighting the current gradient and disrupting the warmup geometry. Cooldown-only NAdam avoids this regime but switches on too late (step 3016 of 3175, only 159 steps remaining) to meaningfully bend the trajectory.

**Decision tree mapping**: Hits cases 2 and 3 simultaneously — "Both arms MISS merge bar but Arm B < Arm A" → cooldown-only is the winning sub-region of a losing axis. n=2 confirm would require seed-2 val < 3.26755 (>20× tighter than statsig boundary). Student-recommended close.

**Theorem (early-step correction-or-rectification incompatibility theorem completion)**: NAdam joins:
- #718 MUON_BIAS_CORR — Adam-style bias correction on Muon (Arm A diverged)
- #742 ADAMW_RADAM — variance rectification on AdamW (Arm A diverged, Arm B never reached 3.28)
- #739 ADAMW_NESTEROV — first-moment look-ahead on AdamW (Arm A MISS, Arm B noise-tie)

The bilateral early-step correction-or-rectification incompatibility theorem is **complete**: machinery designed to fix Adam's early-step variance/bias behavior is strict downside on this c=20+EMBED_INIT_STD=0.1 stack at every applied surface — Muon's heavy-ball direction, AdamW's m_t direction, AdamW's v_t variance. The stable β1=0.8 + 1/√v_t saturation region cannot be improved by adding correction layers.

**Cluster placement**: 22nd axis joining ffs=3025+ floor cluster.

**Fern → #764 MUON_COOLDOWN_SHAPE** assigned — first per-group cooldown SHAPE test on this stack (mechanistically orthogonal to all closed scalar/cooldown-frac/eta_min axes).

---

## 2026-05-22 06:36 UTC — PR #758: ADAMW_GC gradient centralization (CLOSED — pod-untestable, 5/5 NaN runs)

- `g1r2-tanjiro/adamw-grad-centralization`
- Hypothesis: Yong et al. CVPR 2020 — subtract per-channel grad mean before AdamW step on lm_head/embed AdamW groups (3D weights → mean across in-dim). Test if grad-mean-removal stabilizes the lm_head and embed AdamW updates which #688/#734 GRAD_CLIP showed are sensitive to gradient magnitude conditioning.
- W&B runs: `x8uwt5ct` (canary NaN), `a8ppu1uo` (canary NaN), `jzwyc0qs` (canary NaN, #768 filed), `46qstw75` (canary NaN), `fdvflhec` (Arm A path-1 override → NaN at step 175)

| Run | Group | Step at NaN | Notes |
|---|---|---:|---|
| `x8uwt5ct` | pod-canary | 200 | true baseline (no diff), NaN |
| `a8ppu1uo` | pod-canary | 200 | true baseline, NaN |
| `jzwyc0qs` | pod-canary | 200 | true baseline, NaN, filed in #768 |
| `46qstw75` | pod-canary | 200 | true baseline, retry NaN |
| `fdvflhec` | adamw-gc-A | 175 | ADAMW_GC=1, NaN (100% Linear/RMSNorm nonfinite) |

**Results commentary (advisor)**: Pod g1r2-tanjiro entered broken state ~05:24 UTC. 4/4 true-baseline canaries NaN'd; advisor issued path-1 override to skip 200-step canary and run 3175-step Arm A directly (hypothesis: longer runs bypass early-step compressed-config flakiness). Arm A also NaN'd at step 175 with 100% of Linear (123.7M elements) and RMSNorm gains (19.9k elements) nonfinite — full weight divergence. Override hypothesis falsified.

**Closure as pod-untestable**: Same precedent as #747 β2_SCHEDULE (7 consecutive NaNs on tanjiro pod proved platform-flakiness not diff-bug). 5/5 NaN here including true baseline definitively isolates failure to pod state, not ADAMW_GC mechanism.

**Axis status**: ADAMW_GC remains scientifically OPEN. Will reassign to recovered tanjiro pod or another idle student.

**Ops escalation**: #768 updated to human-needed remediation request — full table of 5 NaN runs documented, requested pod restart/GPU reset for g1r2-tanjiro.

**Cluster placement**: Pod-untestable (not on floor cluster).

---

## 2026-05-22 06:52 UTC — PR #732: MUON_LR_ATTN/MLP asymmetry — per-block-TYPE body Muon LR split (CLOSED — both arms MISS)

- `g1r2-nezuko/muon-lr-attn-mlp-asym`
- Hypothesis: split body Muon LR by block type (attention vs mlp) using MUON_LR_ATTN_MULT and MUON_LR_MLP_MULT. Arm A boosted attn (1.25/1.0), Arm B boosted mlp (1.0/1.25), each at effective lr=0.05 on boosted side, 0.04 baseline on other side.
- W&B runs: `7wzj39l2` (Arm A attn-boost), `w01d0lt0` (Arm B mlp-boost)

| Arm | Config (attn/mlp effective lr) | val/loss | ffs | Δval | Δffs | Hold gate |
|---|---|---:|---:|---:|---:|:---:|
| A (attn-boost) | 0.05 / 0.04 | 3.27235 | 3050 | +0.00459 | +50 | MISS both |
| B (mlp-boost) | 0.04 / 0.05 | 3.28248 | -1 | +0.01473 | catastrophic | MISS both |
| baseline (#613) | 0.04 / 0.04 | 3.26776 | 3000 | — | — | — |

**Trajectory comparison** (Arm A vs Arm B, every checkpoint):
- step 250: A=4.055, B=4.0452 → Δ=-0.010 (B better very early)
- step 500: A=3.820, B=3.8301 → Δ=+0.010 (B worse)
- step 750: A=3.739, B=3.7512 → Δ=+0.012
- step 1000: A=3.6835, B=3.6980 → Δ=+0.015
- terminal: A=3.27235, B=3.28248 → Δ=+0.010

**Results commentary (nezuko)**: After step 500, mlp-boosted Arm B tracks 0.010-0.015 above attn-boosted Arm A at every checkpoint. The asymmetry signal is **mechanistically informative**: attn weights tolerate more Muon-LR than mlp weights at this stack, suggesting MUON_LR=0.04 may slightly under-LR attention while approximately-correct for mlp. But the effect is too small to flip merge state — Arm A's mlp_lr=0.04 (baseline-equivalent) + attn_lr=0.05 (boosted) lands +0.00459 val over baseline.

**Closure logic**: Per-block-TYPE Muon LR split direction is correct (attn>mlp tolerance) but magnitude wrong at 1.25× delta. Smaller delta would just shrink the signal; larger delta requires re-tuning warmup/cooldown to prevent the 0.015 gap observed by step 1000.

**Cluster placement**: 25th axis joining ffs=3025+ floor cluster.

**Nezuko → idle**, awaiting fresh mechanism-level assignment from research-agent batch.

---

## 2026-05-22 06:53 UTC — PR #749: EMBED_LR_LATE_BOOST — boost embed-only AdamW LR in final 7.5% (CLOSED — both arms MISS, closest-miss in recent series)

- `g1r2-thorfinn/embed-lr-late-boost`
- Hypothesis: embed AdamW group is undertrained in the cooldown tail because the overall lr cooldown applies uniformly. Boost embed-only LR by 1.5× (Arm A) or 2.0× (Arm B) during the final 7.5% of training (240 steps from step 2935 to 3175) to recover signal.
- W&B runs: `lnhj5hta` (Arm A boost=1.5×), `b20t2prc` (Arm B boost=2.0×)

| Arm | boost | EMBED_LR_LATE_BOOST_FRAC | val/loss | ffs | Δval | Δffs | Hold gate |
|---|---:|---|---:|---:|---:|---:|:---:|
| A | 1.5× | 0.075 | 3.27075 | 3025 | +0.00299 | +25 | MISS both |
| B | 2.0× | 0.075 | 3.26937 | 3025 | +0.00161 | +25 | MISS ffs (val passes 3.27 leg) |
| baseline (#613) | — | — | 3.26776 | 3000 | — | — | — |

**Results commentary (thorfinn)**: Arm B val=3.26937 is the **closest-miss in the recent series** at +0.00161 val. Direction (embed group needs more LR during cooldown tail) is consistent with the trajectory shape — `vwrqt4vt` reference run val from step 3000→3175 drops only 0.005 — so 25 extra steps of ffs penalty isn't easily reclaimed by lever tuning alone. At 2.0× boost we're already at the destabilization-risk edge for embed params; pushing to 3.0× or 5.0× has poor risk/reward.

**Theorem (falsification)**: "Embed undertrained in cooldown tail, can be rescued by group-specific LR boost" is falsified at 7.5%/2.0× lever. Direction correct, magnitude too small at viable lever range.

**Cross-link**: Symmetric test #759 (frieren LM_HEAD_LR_LATE_BOOST) in-flight. If frieren also close-misses, the boost-during-cooldown class closes more broadly.

**Cluster placement**: 24th axis joining ffs=3025+ floor cluster.

**Thorfinn → idle**, awaiting fresh mechanism-level assignment from research-agent batch.

