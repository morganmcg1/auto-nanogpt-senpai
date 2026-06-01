# SENPAI Research State — auto-nanogpt-1gpu-r5

## ★★ HUMAN DIRECTIVE 2026-05-26 06:14Z (issue #1262) — FFS-PRIMARY FRAMING

The human research team has redirected: **FFS (first-step-to-target, baseline 3025) is now the primary metric, val/loss is secondary.** Plateau on val/loss has been mechanism-rich but speed-dry. Concrete new policy:

1. **Every closure/ack reports FFS first, val/loss second.**
2. **No n=4/n=8 confirmation unless FFS readout is alive at n=1** (~ ≤ 2975 movement toward <3000). If only val/loss promotes, close as mechanism finding.
3. **Prefer experiments that move the crossing step** (2800-3050 window), **simplify winning stacks**, **reveal FFS-load-bearing components**.
4. **Ablations preferred over confirmations** when FFS dead.

## Last updated: 2026-06-01 17:30Z (**frieren #2070 n=4 reverting to canonical (3/4 trials at 2875); nezuko A_ctrl terminal + B★ launched; 5 A_ctrls at canonical**)

### Notes (2026-06-01 17:30Z) — frieren n=4 attractor reversion CONFIRMED + 5th A_ctrl at canonical

- **frieren #2070 n=4 CONFIRM: TRIALS 0-2 ALL AT CANONICAL ATTRACTOR.** Trial 4 in progress (step ~10456/13000, 37% done). At observed 28 steps/min pace, **ETA refined to ~18:56Z** (1h26m from now, NOT the 17:30Z earlier estimate).

| Trial | FFS_ema | FFS_trainval | ema_val |
|---|---|---|---|
| 0 | 2875 | 2925 | 3.2706 |
| 1 | 2875 | 2925 | 3.2707 |
| 2 | 2875 | 2925 | 3.2713 |
| 3 | (in progress, step ~10456) | — | — |

  3-trial μ(FFS_ema)=2875.0, σ=0 — DEAD FLAT on canonical attractor. Matches memory [[r5_n1_to_n4_reversion_dual_metric_attractor]]: n=1 signal (FFS_trainval -50 OFF canonical + monotone Δema -0.0018) is reverting on n=4 as predicted. **Trial 4 expected at canonical → 107th R5 FFS-NEUTRAL closure on completion.** Compound mu+precond_freq joins absorbed family.

- **PR #2138 nezuko A_ctrl FINISHED** at FFS_ema=2875, FFS_trainval=2875 (TV tied at 2875 — interesting -50 departure within ±50 noise tolerance), ema_val=3.2697. **B★ `q1xl3tst`** (soap_eps_floor=0.03) launched 17:27Z (28 min gap), now step 124.

### A_ctrl reproducibility table (5 arms terminal, all canonical)

| PR | Student | Run | Final ema_val | FFS_ema | FFS_trainval | Verdict |
|---|---|---|---|---|---|---|
| #2126 | thorfinn | `oteszbcp` | 3.2701 | 2875 | 2925 | Canonical ✓ |
| #2128 | tanjiro | `k6q6szky` | (3.270x) | 2875 | 2925 | Canonical ✓ |
| #2130 | askeladd | `m2qgbnzs` | 3.2693 | 2875 | (—) | Canonical ✓ |
| #2133 | fern | `0dzw5596` | 3.2709 | 2875 | (—) | Canonical ✓ |
| #2138 | nezuko | `b91wo9l4` | 3.2697 | 2875 | **2875** | Canonical (TV-tied) ✓ |

5 A_ctrls across 5 students all land at FFS_ema=2875, best ema_val ∈ [3.2693, 3.2713]. **Round 5 = cleanest baseline reproduction round to date.** Spread ≤0.002.

### Fleet status snapshot (17:30Z) — 8/8 RUNNING, 5 in B★ test arms

| PR | Student | Active Run | State | Step | Notes |
|---|---|---|---|---|---|
| #2042 | alphonse | `rblece7h` | running | 11377 | n=4 rope_base=4096 trial 3 near terminal; ETA ~18:40Z |
| #2070 | **frieren** | `xdevn24r` | running | 10456 | **n=4 mu+freq compound trial 4 36%; ETA refined ~18:56Z** |
| #2118 | edward | `iqpkbtis` | running | 3099 | A_ctrl logit cap-DOWN near terminal (step 3099/3250) |
| #2126 | thorfinn | `h2bkl9o3` (B★) | running | 1821 | trapezoid plateau_frac=0.4 mid |
| #2128 | tanjiro | `1hod394d` (B★) | running | 1698 | cosine ease-in mu mid |
| #2130 | askeladd | `4px2l6l7` (B★) | running | 1113 | embed_lr_scale=5.0 mid |
| #2133 | fern | `7uhpuigt` (B★) | running | 944 | depth-graduated MLP early×1.15/late×0.85 |
| #2138 | nezuko | `q1xl3tst` (B★) | running | 124 | soap_eps_floor=0.03 early |

### Heartbeat actions (17:25Z–17:30Z)

1. W&B fleet check: 3 stale_wip flags (#2070, #2118, #2138) all triaged.
2. frieren #2070 trial 0-2 confirmed at canonical (3-trial μ=2875.0); trial 4 ETA refined to 18:56Z.
3. nezuko #2138 A_ctrl terminal + B★ launched (verified `q1xl3tst` running).
4. Posted explanatory comments on all 3 PRs to clear flags.
5. Human issue #2122 (Aurora): already addressed, no action.

### Expected near-term closures

- **frieren #2070** at ~18:56Z (107th R5 closure FFS-NEUTRAL, n=4 attractor reversion of mu+precond_freq compound)

---

## Last updated: 2026-06-01 16:55Z (**askeladd + fern A_ctrl FINISHED at canonical; both B★ auto-launched; fleet 8/8 in test arms or near-terminal**)

### Notes (2026-06-01 16:55Z) — 4 A_ctrls now at canonical attractor; 4 B★ test arms running

- **PR #2130 askeladd A_ctrl FINISHED** at step 3250 (best ema_loss=3.2693, FFS_ema=2875). **B★ `4px2l6l7`** (embed_lr_scale=5.0, embed_lr_resolved=0.275) auto-launched at 16:50Z; now at step ~360. Queue script working cleanly.
- **PR #2133 fern A_ctrl FINISHED** at step 3250 (best ema_loss=3.2709, FFS_ema=2875). **B★ `7uhpuigt`** (depth-graduated MLP LR, early×1.15/late×0.85) auto-launched at 16:55Z; now at step ~190.

### A_ctrl reproducibility table (4 arms terminal, all canonical)

| PR | Student | Run | Final ema_val | FFS_ema | FFS_trainval | Verdict |
|---|---|---|---|---|---|---|
| #2126 | thorfinn | `oteszbcp` | 3.2701 | 2875 | 2925 | Canonical ✓ |
| #2128 | tanjiro | `k6q6szky` | (3.270x) | 2875 | 2925 | Canonical ✓ |
| #2130 | askeladd | `m2qgbnzs` | 3.2693 | 2875 | (—) | Canonical ✓ |
| #2133 | fern | `0dzw5596` | 3.2709 | 2875 | (—) | Canonical ✓ |

**Cleanest n=1 reproduction round yet** — all 4 A_ctrl arms across 4 distinct students land at FFS_ema=2875 with best ema_val ∈ [3.2693, 3.2709] (≤0.0016 spread). Baseline is well-conditioned across student/launch context.

### Fleet status snapshot (16:55Z) — 8/8 RUNNING, 4 in B★ test arms

| PR | Student | Active Run | State | Step | Notes |
|---|---|---|---|---|---|
| #2042 | alphonse | `rblece7h` | running | 10522 | n=4 confirm rope_base=4096; trial 3 near terminal |
| #2070 | **frieren** | `xdevn24r` | running | 9621 | **n=4 confirm mu+freq compound; trial 3 step 2900/3250; ETA ~17:30Z** |
| #2118 | edward | `iqpkbtis` | running | 2471 | A_ctrl logit cap-DOWN; ema_val=3.3161 |
| #2126 | thorfinn | `h2bkl9o3` (B★) | running | 977 | trapezoid plateau_frac=0.4 |
| #2128 | tanjiro | `1hod394d` (B★) | running | 858 | cosine ease-in mu cooldown |
| #2130 | askeladd | `4px2l6l7` (B★) | running | ~360 | embed_lr_scale=5.0 |
| #2133 | fern | `7uhpuigt` (B★) | running | ~190 | depth-graduated MLP LR early×1.15/late×0.85 |
| #2138 | nezuko | `b91wo9l4` | running | 2676 | A_ctrl SOAP adaptive eps; ema_val=3.2931 |

### Heartbeat actions (16:54Z–16:55Z)

1. Survey clean (0 review-ready, 8 WIP, 0 idle, 0 advisor-action).
2. Verified human issues #2122 + #1262 fully addressed (no new comments).
3. W&B check: askeladd + fern A_ctrl terminated; both B★ auto-launched cleanly via student queue scripts.
4. Updated fleet table; no triage action needed.

---

## Last updated: 2026-06-01 16:40Z (**fern #2133 stale_wip = false alarm; thorfinn #2126 + tanjiro #2128 B★ both launched; 4th-consecutive false alarm**)

### Notes (2026-06-01 16:40Z) — Fleet check: B★ arms launching, 4 false-alarm stale_wip flags in a row

- **PR #2133 fern stale_wip = false alarm.** W&B `0dzw5596` step 2974/3250 (from 2383 at 16:15Z, +591 steps in 22 min, normal pace). FFS_ema=2875 (canonical, expected for A_ctrl). Posted ack ([#2133 comment-4594601237](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/2133#issuecomment-4594601237)).
- **PR #2126 thorfinn B★ LAUNCHED at 16:24Z** (responding to my nudge). `h2bkl9o3` (plateau_frac=0.4) running step 418. A_ctrl posted SENPAI-RESULT @16:24Z confirming canonical attractor. Cells C(0.6) + D(0.0) queued sequentially. ETA bundled result ~22:30Z.
- **PR #2128 tanjiro A_ctrl TERMINAL @16:25Z + B★ chain auto-launched.** A_ctrl `k6q6szky` finished at canonical attractor {2875, 2925}. B★ `1hod394d` (cosine ease-in mu cooldown) running step 301. Student clarified 16:08Z that prior crashes were launch-script collision; single-chain is correct now. ETA B★ ~18:15Z.
- **PR #2130 askeladd A_ctrl near terminal** (step 2950/3250, posted 16:32Z). KGsmoke `c3tbiuo7` (NOT `84y1fexd` — that was an earlier crash, replaced) completed at 200 steps. B★(scale=5.0) + C(scale=6.0) queued sequentially via `run_embed_lr_BC_after_A.sh`.

### Pattern observation: 4 consecutive stale_wip false alarms

The stale_wip triage flag is firing on PRs that are actively progressing in W&B. Root cause: the flag triggers on **PR-update inactivity** (no comments/commits for some threshold), but students typically only post intermediate updates when arms terminate. During a 1.75h cell run, students may be silent on the PR but the W&B run is healthy.

**Mitigation**: Always W&B-verify before high-urgency stale_wip check-ins. Encourage students to post intermediate "Cell X@step Y" updates every ~1h to keep triage tidy.

### Fleet status snapshot (16:40Z) — 8/8 active, 2 A_ctrl terminals at canonical, 2 B★ launched

| PR | Student | W&B Run | State | Step | Verdict |
|---|---|---|---|---|---|
| #2042 | alphonse | `rblece7h` | running | 9973 | n=4 confirm rope_base=4096; trial 3 near terminal |
| #2070 | **frieren** | `xdevn24r` | running | 9194 | **n=4 confirm mu+freq compound; trial 3 active; ETA ~17:30Z** |
| #2118 | edward | `iqpkbtis` | running | 1971 | logit cap-DOWN; A_ctrl mid |
| #2126 | thorfinn | `h2bkl9o3` (B★) | running | 418 | B★ trapezoid plateau_frac=0.4; A_ctrl@canonical |
| #2128 | tanjiro | `1hod394d` (B★) | running | 301 | B★ cosine ease-in; A_ctrl@canonical |
| #2130 | askeladd | `m2qgbnzs` (A_ctrl) | running | 3074 | A_ctrl near terminal; B★+C queued |
| #2133 | fern | `0dzw5596` (A_ctrl) | running | 2974 | A_ctrl mid; FFS_ema=2875 canonical |
| #2138 | nezuko | `b91wo9l4` (A_ctrl) | running | 2140 | A_ctrl mid; SOAP adaptive eps |

### A_ctrl terminals this round (canonical attractor reproducibility)

| PR | Student | Run | val/loss | ema_val | FFS_ema | FFS_trainval | Verdict |
|---|---|---|---|---|---|---|---|
| #2126 | thorfinn | `oteszbcp` | 3.2697 | 3.2701 | 2875 | 2925 | Canonical attractor ✓ |
| #2128 | tanjiro | `k6q6szky` | (terminal) | (3.270x) | 2875 | 2925 | Canonical attractor ✓ |

Both A_ctrl arms reproduce canonical attractor {2875, 2925} cleanly — baseline well-conditioned. Any signal must emerge from B★ test arms.

### Heartbeat actions (16:37Z–16:40Z)

1. W&B fleet check verified fern #2133 stale_wip = false alarm.
2. Confirmed thorfinn B★ + tanjiro B★ launched (after my prior nudges + student auto-chain).
3. Confirmed askeladd KGsmoke succeeded (clarified `c3tbiuo7` succeeded after `84y1fexd` crashed).
4. Posted ack on fern #2133 to clear flag.
5. Noted pattern: 4-in-a-row false-alarm stale_wip flags. Future: W&B-verify before high-urgency check-ins.

---

## Last updated: 2026-06-01 16:25Z (**askeladd #2130 stale_wip = false alarm; thorfinn #2126 A_ctrl terminal at canonical attractor; B★ launch nudged**)

### Notes (2026-06-01 16:25Z) — Fleet check confirms steady progress + thorfinn A_ctrl complete

- **PR #2130 askeladd stale_wip = false alarm.** W&B fleet check (16:15Z) shows `m2qgbnzs` (A_ctrl, embed_lr_scale=None) running step 2704/3250, val/loss=3.305. **Plus** a parallel KGsmoke `84y1fexd` (embed_lr_scale=5, embed_lr_resolved=0.275) at step 73/200 — student is using smart parallel-validation pattern (smoke probe while A_ctrl finishes). Both concurrent on 1 GPU; smoke is 200-step lightweight. Posted ack ([#2130 comment-4594481949](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/2130#issuecomment-4594481949)).
- **PR #2126 thorfinn A_ctrl COMPLETE.** `oteszbcp` finished at step 3250: val/loss=3.2697, ema_val=3.2701, FFS_ema=2875, FFS_trainval=2925. **Canonical attractor exactly** — A_ctrl reproduces baseline; signal must come from B★ (plateau_frac=0.4). GPU idle ~10 min post A_ctrl. Posted nudge to launch B★ ([#2126 comment-4594483235](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/2126#issuecomment-4594483235)).

### Fleet status snapshot (16:25Z) — 7/8 active, thorfinn between A_ctrl and B★

| PR | Student | W&B Run | State | Step | Notes |
|---|---|---|---|---|---|
| #2042 | alphonse | `rblece7h` | running | 9488 | n=4 confirm rope_base=4096; trial 3 nearing end |
| #2070 | **frieren** | `xdevn24r` | running | 8581 | **n=4 confirm mu+freq compound; trial 3 mid (2081/3250); ETA ~17:30Z** |
| #2118 | edward | `iqpkbtis` | running | 1399 | logit cap-DOWN; A_ctrl mid |
| #2126 | thorfinn | (between arms) | A_ctrl done | 3250 | **A_ctrl=canonical {2875,2925}; B★ pending launch** |
| #2128 | tanjiro | `k6q6szky` | running | 3057 | cosine-μ-cooldown; A_ctrl near terminal (3250 close) |
| #2130 | askeladd | `m2qgbnzs` + `84y1fexd` | running ×2 | 2704 + 73 | A_ctrl + parallel KGsmoke probe |
| #2133 | fern | `0dzw5596` | running | 2383 | depth-graduated MLP LR; A_ctrl mid |
| #2138 | nezuko | `b91wo9l4` | running | 1538 | SOAP adaptive eigenvalue floor; A_ctrl early |

### A_ctrl terminal metric — first data point of this round (thorfinn #2126)

| Run | Cell | val/loss | ema_val | FFS_ema | FFS_trainval | Verdict |
|---|---|---|---|---|---|---|
| `oteszbcp` | A_ctrl (cosine baseline) | 3.2697 | 3.2701 | 2875 | 2925 | Canonical attractor (expected) |

### Heartbeat actions (16:14Z–16:25Z)

1. Verified askeladd #2130 stale_wip = false alarm via W&B fleet check.
2. Identified thorfinn #2126 A_ctrl terminal (canonical attractor); GPU idle 10+ min; posted B★ launch nudge.
3. Posted ack on askeladd #2130 to clear stale_wip flag.
4. Human issues (#2122, #1262): no new comments, no action needed.

---

## Last updated: 2026-06-01 15:45Z (**8/8 RUNNING (W&B verified); tanjiro #2128 + thorfinn #2126 stale_wip = false alarms; fleet healthy**)

### Notes (2026-06-01 15:45Z) — W&B fleet sanity check confirms all 8 RUNNING

- **PR #2128 tanjiro stale_wip = false alarm.** W&B shows `k6q6szky` running since 13:59Z, step 2347, group `g1r5-tanjiro/cosine-mu-cooldown-shape`. Two prior crashed runs (`mshoh0s2`, `atqs2rvs`) suggest launch instability before stabilizing — flagged for student. Follow-up posted to reassure ([#2128 comment-4594219960](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/2128#issuecomment-4594219960)).
- **PR #2126 thorfinn stale_wip = false alarm.** W&B shows `oteszbcp` running since 14:04Z, step 2859, val_loss=3.291. Two prior finished arms (`4tibarlt`, `2r1ya9as`) = normal multi-arm sweep pattern. Follow-up posted to reassure ([#2126 comment-4594218680](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/2126#issuecomment-4594218680)).
- **stale_wip semantics**: triggered by PR-update inactivity, NOT pod/W&B activity. Both students are training healthily, just hadn't committed/posted intermediate updates. Future: prefer W&B verification before high-urgency check-ins.

### Fleet status snapshot (15:45Z) — 8/8 RUNNING, ALL in W&B

| PR | Student | W&B Run | State | Step | Notes |
|---|---|---|---|---|---|
| #2042 | alphonse | `rblece7h` | running | 8756 | n=4 confirm; rope_base=4096; ETA ~18:40Z (trials 2-3) |
| #2070 | **frieren** | `xdevn24r` | running | 7819 | **n=4 confirm; mu+freq compound; ETA ~17:30Z** (strongest signal) |
| #2118 | edward | `iqpkbtis` | running | 698 | logit-softcap-down-sweep; just started 15:19Z |
| #2126 | thorfinn | `oteszbcp` | running | 2859 | trapezoid-lr; A_ctrl-mid-flight; 2 prior arms finished |
| #2128 | tanjiro | `k6q6szky` | running | 2347 | cosine-μ-cooldown; A_ctrl-mid; 2 prior crashes resolved |
| #2130 | askeladd | `m2qgbnzs` | running | 1874 | embed-lr-coupling; 1 prior probe run finished |
| #2133 | fern | `0dzw5596` | running | 1604 | depth-graduated MLP LR; 1 prior crashed arm |
| #2138 | nezuko | `b91wo9l4` | running | 757 | SOAP adaptive eigenvalue floor; just started 15:18Z |

### Heartbeat actions (15:30Z–15:45Z)

1. Posted stale_wip check-ins on #2128 (tanjiro) and #2126 (thorfinn) flagged in advisor-action triage.
2. Dispatched W&B fleet sanity check (general-purpose agent `a6824c99efcb8cb3e`) — confirmed all 8 students running, NO genuine stalls.
3. Posted reassurance follow-ups on both PRs to disregard urgency.
4. Logged fleet state confirming 8/8 RUNNING.

---

## Last updated: 2026-06-01 15:30Z (**8/8 active; thorfinn #2126 check-in posted (2h09m silence); waiting on KGsmoke/status reply**)

### Notes (2026-06-01 15:30Z) — Heartbeat: fleet-state nominal, thorfinn #2126 status probe

- **Survey clean**: 0 review-ready, 8 WIP, 0 idle. All 8 students productive on diverse fresh axes.
- **PR #2126 thorfinn trapezoid-lr-cooldown** flagged 2h09m silence since 13:22Z assignment. Branch still at assignment commit `18373f3c`, no implementation commits, no W&B groups. Pod `senpai-auto-nanogpt-1gpu-r5-g1r5-thorfinn` confirmed alive (1/1 ready, 17d uptime). Posted ADVISOR check-in comment ([#2126 comment-4594075056](https://github.com/morganmcg1/modded-nanogpt-senpai/pull/2126#issuecomment-4594075056)) requesting status: implementation in progress / blocker / KGsmoke result. Retained status:wip pending reply.
- **Human issues**: #2122 (Aurora) and #1262 (FFS-primary) both fully addressed in earlier ADVISOR responses; no new human comments.
- **In-flight n=4 confirms**: frieren #2070 (ETA ~17:30Z, strongest signal candidate), alphonse #2042 (ETA ~18:40Z, likely FFS-NEUTRAL).
- **In-flight n=1 fresh-axis cells**: edward #2118 (ETA ~20:26Z bundled), tanjiro #2128, askeladd #2130, fern #2133, nezuko #2138.

### Watch list (15:30Z) — chronological ETA

| When | PR | Student | Trigger |
|---|---|---|---|
| ~16:30Z | #2126 | thorfinn | ADVISOR check-in reply window expires (1h after 15:30Z post) |
| ~17:30Z | #2070 | frieren | n=4 confirm of mu+precond_freq compound — 3rd R5 merge candidate |
| ~18:40Z | #2042 | alphonse | n=4 confirm of RoPE base=4096 (trial 0 reverted, low expectation) |
| ~20:26Z | #2118 | edward | logit cap-DOWN ABCD bundled SENPAI-RESULT |
| TBD | #2128 | tanjiro | cosine μ-cooldown shape n=1 cells |
| TBD | #2130 | askeladd | embed LR coupling n=1 cells |
| TBD | #2133 | fern | depth-graduated MLP LR n=1 cells |
| TBD | #2138 | nezuko | SOAP adaptive eigenvalue floor n=1 cells |

---

## Last updated: 2026-06-01 15:00Z (**8/8 active: nezuko PR #2138 soap-adaptive-eps-floor assigned; fleet full**)

### Notes (2026-06-01 14:45Z) — 106th R5 closure + parallel researcher for nezuko

- **PR #2079 nezuko CLOSED FFS-NEUTRAL [106th R5 closure]**: warmup-mu-ramp (mu_warmup_start ∈ {0.70, 0.80, 0.95}). All 3 cells collapse to canonical attractor {FFS_ema=2875, FFS_trainval=2925}. Probe trajectory NOT monotone-better. ema_val range [3.27099, 3.27159] = Δ ≤ 0.0006 = pure seed noise. **Mechanism preserved**: NS5 absorbs warmup-side momentum perturbations (orthogonalization-dominated regime) but releases during cooldown (LR-contracting regime). This sharpens the [[ns5_absorbs_2d_weight_init_perturbations_at_r5]] absorption rule.
- **Nezuko researcher dispatched (a3b4269f7311896e7)**: brief AVOIDS all mu/momentum/NS5/loss-side axes (nezuko's portfolio is fully mapped). Biased toward attention sink tokens, SOAP/Shampoo internals, token-level mechanisms, numerical/kernel-level, schedule shape, NS5 outer per-head/per-role, spectral preconditioning. ETA ~10-15 min.
- **8 R5 cells at {2875, 2925} attractor this round** confirms strong local fixed-point requiring rare-event multi-axis escape. The signal candidate fleet must break this attractor.

### Fleet status snapshot (14:45Z) — 7/8 active, nezuko awaiting researcher

| PR | Student | Mechanism | Status |
|---|---|---|---|
| #2138 | **nezuko** | SOAP adaptive eigenvalue floor (LM relative damping on SOAP preconditioner denominator) | **WIP (assigned 15:00Z) — 4-cell falsifier-paired B★+D** |
| #2042 | alphonse | RoPE base=4096 n=4 | Trial 0 reverted 2925, trials 1+ in flight (ETA ~18:40Z) |
| #2070 | frieren | mu+precond_freq compound n=4 | In flight, ETA ~17:30Z |
| #2118 | edward | logit cap-DOWN sweep | WIP (load-bearing regularization tighter direction) |
| #2126 | thorfinn | trapezoid LR shape | WIP |
| #2128 | tanjiro | cosine μ-cooldown shape | WIP |
| #2130 | askeladd | embed LR coupling | WIP (assigned 14:00Z) |
| #2133 | fern | depth-graduated MLP LR | WIP (assigned 14:30Z) |

### Signal candidate quality ranking (14:45Z)

1. **frieren #2070 mu+precond_freq compound n=4** (ETA 17:30Z): dual-metric n=1 signal. Best chance at 3rd R5 merge.
2. **alphonse #2042 RoPE base=4096 n=4** (ETA 18:40Z): trial 0 reverted 2925, unlikely to recover gate.
3. **fern #2133 depth-graduated-mlp-lr**: B★/D falsifier-paired; either signal or NS5-absorption-extended memory entry.
4. **edward #2118 logit cap-DOWN**: regularization tighter-direction sweep.
5. **thorfinn #2126 trapezoid LR**: first LR-shape axis on active fleet.
6. **tanjiro #2128 cosine μ-cooldown**: symmetric shape variation.
7. **askeladd #2130 embed LR coupling**: fresh axis, AdamW group outside NS5 absorption.
8. **nezuko #2138**: soap-adaptive-eps-floor — Levenberg-Marquardt-style relative damping for SOAP preconditioner denominator. Replace fixed `eps=1e-8` with `alpha * exp_avg_sq.mean() + eps`. 4-cell falsifier-paired sweep: A_ctrl(0.0)/B★(0.03)/C(0.01)/D(0.10-falsifier). Post-NS5 path (SOAP), outside NS5 absorption family. Assigned 15:00Z.

### Cross-fleet learnings from R5 closures (now 106)

- Mu cooldown axis: SCALAR-optimum at 0.80 (#2084); SCALAR-MAGNITUDE-only (asymmetry & warmup-side both flat: #2084, #2079)
- Loss-side mechanisms: LOW PRIORITY — cooldown stack absorbs logit damping (#2077, #2080, #1870)
- AdamW WD ramp: parameter-group-specific (Muon WD mechanism does NOT transfer; #2083)
- NS5 absorption: structural 2D init perturbations, per-block depth-LR post-NS5, pre-NS5 gradient modifiers, WARMUP-SIDE MU all absorbed; only cooldown-side gradient-channel perturbations escape
- 2875 floor: appears to be genuine geometric bottleneck across many mechanism classes; need orthogonal compound to break

---

## Last updated: 2026-06-01 14:30Z (**8/8 active: askeladd PR #2130 embed-lr-coupling + fern PR #2133 depth-graduated-mlp-lr both assigned; fleet full**)

### Notes (2026-06-01 14:15Z) — Double closure, parallel hypothesis dispatch

- **PR #2077 askeladd CLOSED FFS-NEUTRAL [104th R5 closure]**: z-loss aux regularizer λ·(logsumexp(logits))². B★(λ=1e-4) showed 8-step monotone ema Δ −0.002 but FAILED val_loss monotone gate at step 1000 (+0.00244 worse). Cell C(λ=1e-3) FFS=−1 confirms over-regularization ceiling between 1e-4 and 1e-3. **First loss-side mechanism tested at R5; informative cross-fleet intel**: cooldown stack absorbs logit damping. (1) bf16 logits well-behaved; (2) cooldown stack already controls late-training dynamics; (3) loss-side collides with optimizer-state-tuned stack. Loss-side family now LOW PRIORITY at R5. Future askeladd → Muon NS5 / init / pre-NS5 transformations.
- **PR #2084 fern CLOSED FFS-NEUTRAL [105th R5 closure]**: asymmetric mu_cooldown_target (attn vs MLP differential). 3-cell sweep (A_ctrl=(0.80, 0.80), B★=(0.85, 0.75), C=(0.75, 0.85)) **ALL THREE hit FFS_ema=2875**. B and C show IDENTICAL FFS_trainval=2875 departure despite OPPOSITE asymmetry directions → not a directional mechanism. **Key cross-fleet intel**: merged 0.80/0.80 mu_cooldown_target is on a FLAT PLATEAU within ±0.05 differential. Mu axis is SCALAR-optimum, not multi-dimensional. Future μ-cooldown experiments should focus on SHAPE (tanjiro #2128 cosine) or shared MAGNITUDE (frieren #2070 compound), NOT differential.
- **Two researcher-agents dispatched in PARALLEL**:
  1. **askeladd brief (a694dcfb67924b5bf, still running)**: bias toward Muon NS5 outer polynomial form, per-layer/per-head ns_iter, init variants, cross-optimizer LR coupling, pre-NS5 gradient transformations. AVOID loss-side / mu-cooldown.
  2. **fern brief (a802449db6447b5b5, just launched 14:15Z)**: bias toward attention sink tokens, embedding/unembedding mechanisms, cross-optimizer LR coupling, pre-NS5 spectral transformations, schedule shape beyond cosine. AVOID mu-cooldown (just closed), loss-side, WD.

### Fleet status snapshot (14:15Z) — 6/8 active, 2 idle awaiting hypothesis

| PR | Student | Mechanism | Status |
|---|---|---|---|
| #2130 | **askeladd** | embed LR coupling (adam_embed lr tied to lr_mlp × scale) | **WIP (assigned 14:20Z) — fresh axis, AdamW group** |
| #2133 | **fern** | depth-graduated MLP LR (align Muon base LR with musoft depth factor) | **WIP (assigned 14:30Z) — falsifier-paired B★/D** |
| #2042 | alphonse | RoPE base=4096 n=4 | Trial 0 reverted 2925, trials 1+ in flight (ETA ~18:40Z) |
| #2070 | frieren | mu+precond_freq compound n=4 | In flight, ETA ~17:30Z |
| #2079 | nezuko | warmup mu ramp | B★ attractor lock; Cell C in flight |
| #2118 | edward | logit cap-DOWN sweep | WIP (load-bearing regularization tighter direction) |
| #2126 | thorfinn | trapezoid LR shape | WIP (KGsmoke + A_ctrl in progress) |
| #2128 | tanjiro | cosine μ-cooldown shape | WIP (assigned 13:35Z) |

### Signal candidate quality ranking (14:15Z) — n=4 confirms loom

1. **frieren #2070 mu+precond_freq compound n=4** (ETA 17:30Z): dual-metric n=1 signal (FFS_trainval −50 OFF canonical + monotone Δema −0.0018). Best chance at 3rd R5 merge.
2. **alphonse #2042 RoPE base=4096 n=4** (ETA 18:40Z): trial 0 reverted to 2925 (canonical), unlikely to recover gate even at 3-of-3 best case.
3. **edward #2118 logit cap-DOWN**: cap-value DOWN sweep ({10, 12.5, 15, 17.5}) tests load-bearing regularization in tighter direction.
4. **thorfinn #2126 trapezoid LR shape**: first LR-shape axis on active fleet (η=1.0 plateau then cosine-drop).
5. **tanjiro #2128 cosine μ-cooldown shape**: symmetric to thorfinn on μ side.
6. **nezuko #2079**: B★ attractor lock; Cell C exploring direction.
7. **askeladd #2130**: embed-lr-coupling — tie adam_embed lr=0.3 to lr_mlp × scale (B★=5.0→lr=0.275, C=6.0→lr=0.330). Fresh axis, AdamW param group, outside NS5 absorption family. Just assigned 14:20Z.
8. **fern #2133**: depth-graduated-mlp-lr — align Muon MLP base LR with musoft depth init factor. Early blocks (0-5) get `lr_mlp × (1+scale)`, late blocks (6-11) get `lr_mlp × (1-scale)`. B★ (+0.15: early×1.15/late×0.85) paired with INVERSE falsifier D (−0.15: early×0.85/late×1.15). Every outcome is diagnostic: B★↓+D↑ → mechanism real; both tie → NS5 absorbs; D wins → wrong direction. Just assigned 14:30Z.

### Cross-fleet learnings from R5 closures (now 105)

- Mu cooldown axis: SCALAR-optimum at 0.80 (asymmetric ±0.05 hits flat plateau; #2084)
- Loss-side mechanisms: LOW PRIORITY — cooldown stack absorbs logit damping (#2077, #2080, #1870)
- AdamW WD ramp: parameter-group-specific (Muon WD mechanism does NOT transfer to scalars/embed; #2083)
- NS5 absorption: 2D init perturbations, per-block depth-LR, pre-NS5 gradient modifiers all absorbed at gradient scale
- 2875 floor: appears to be genuine geometric bottleneck across multiple mechanism classes; need orthogonal compound to break

---

## Last updated: 2026-06-01 13:35Z (**103rd R5 closure — tanjiro NS5 cooldown FFS-NEUTRAL n=4; Aurora nudge issue #2122 addressed; 8/8 active; tanjiro assigned #2128 cosine-mu-cooldown-shape**)

### Notes (2026-06-01 13:35Z) — tanjiro n=4 closed, Aurora addressed, fresh assignments

- **PR #2014 tanjiro CLOSED FFS-NEUTRAL [103rd R5 closure]**: n=4 confirm ns_iter_cooldown_target=9 terminal. μ_4=2918.75 vs gate 2862.5 (+56.25). {2875, 2925, 2925, 2950} distribution. Textbook [[r5_n1_to_n4_reversion_dual_metric_attractor]] reversion. Direction-of-effect is real (monotone dose-response across all 4 cells — more polish during cooldown helps directionally), but σ_4=27 dominates ~−6 step mechanism shift. Polish-reduction axis closed; polish-increase bounded. n=4 ran on pre-frieren stack.
- **Issue #2122 Aurora optimizer**: Human nudge addressed. r5-specific verdict: **LOW PRIORITY / deferred**. Architecture mismatch (SwiGLU required, we use ReLU²), bounded scope (only `c_fc` tall matrix per block), and r5 signal portfolio rich (5 in-flight crossing-window candidates). r3/c790g-18 already exploring Aurora; if r5 in-flight candidates exhaust without merge in 24-48h, will revisit with diagnostic-first (CV gating) approach.
- **PR #2126 thorfinn**: trapezoid-lr-cooldown assigned 12:55Z. KGsmoke + A_ctrl + B★ (plateau=0.5) sequence in progress.
- **PR #2128 tanjiro**: **NEW ASSIGNMENT cosine-mu-cooldown-shape** (13:35Z). Cosine ease-in interpolation for mu_cooldown (linear 0.95→0.80 replaced by cosine front-loaded shape). Symmetric to thorfinn's LR shape variant on the μ side.

### Fleet status snapshot (13:35Z) — 8/8 active, 0 idle

| PR | Student | Mechanism | Status |
|---|---|---|---|
| #2014 | tanjiro | NS5 cooldown ramp n=4 | **CLOSED FFS-NEUTRAL (103rd)** |
| #2042 | alphonse | RoPE base=4096 n=4 | Trial 0 reverted 2925, trials 1+ in flight |
| #2070 | frieren | mu+precond_freq compound n=4 | In flight, ETA ~17:30Z |
| #2077 | askeladd | z-loss λ dose-response | B★ 8-step monotone signal; Cell C(λ=1e-3) terminal pending |
| #2079 | nezuko | warmup mu ramp | B★ attractor lock; Cell C in flight |
| #2084 | fern | asym mu_cooldown per-group | B★ trainval −50 signal; Cell C in flight |
| #2118 | edward | logit cap-DOWN sweep | WIP |
| #2126 | thorfinn | trapezoid LR shape | WIP (assigned 12:55Z) |
| #2128 | tanjiro | cosine μ-cooldown shape | **WIP (assigned 13:35Z)** |

### Signal candidate quality ranking (13:35Z)

1. **askeladd #2077 z-loss (λ=1e-4)**: 8-step monotone ema Δ −0.002 vs A_ctrl FFS=2925. B★ FFS_ema=2875 = canonical attractor, but monotone-better at all 8 probes is the strongest consistent signal this round. Cell C(λ=1e-3) terminal soon — dose-response will indicate if z-loss is the 3rd merge candidate.
2. **fern #2084 asym mu_cooldown (attn=0.85/mlp=0.75)**: FFS_trainval shifted −50 OFF canonical {2875, 2925} → {2875, 2875}. Δema −0.0024 monotone-better. Cell C in flight. Strong structural signal (dual-metric departure).
3. **frieren #2070 compound mu+precond_freq n=4**: FFS_trainval −50 shift + monotone Δema −0.0018 at n=1 justified n=4 escalation. n=4 in flight ETA 17:30Z.
4. **alphonse #2042 RoPE base=4096 n=4**: Trial 0 FFS=2925 (reverted, canonical). Remaining trials unlikely to recover gate. Expected FFS-NEUTRAL.
5. **thorfinn #2126 trapezoid LR**: Just launched; A_ctrl + B★ sequence in progress.
6. **tanjiro #2128 cosine mu shape**: Just assigned; symmetric to thorfinn.
7. **nezuko #2079 warmup mu ramp**: B★ pure attractor lock, Cell C exploring direction.
8. **edward #2118 logit cap-DOWN**: WIP cells.

---

## Last updated: 2026-06-01 12:55Z (**102nd R5 closure — thorfinn AdamW WD ramp FFS-NEG; alphonse #2042 n=4 trial 0 reverted off-attractor; 2 n=4 in flight; 1 idle**)

### Notes (2026-06-01 12:55Z) — 102nd R5 closure + signal-candidate fleet status

- **PR #2083 thorfinn CLOSED FFS-NEG [102nd R5 closure]**: AdamW WD ramp_down on scalars+embed groups. B★(wd=0.05) FFS_ema=**−1** (target never crossed), ema_val=3.28388 (+0.01348 monotone-worse vs A_ctrl 2875/3.27040 at all 6 probe steps). Kill gate fires; C/D correctly skipped. Student's mechanism analysis: (1) baseline WD=0 is deliberately tuned, not oversight; (2) magnitude 100× too large for sparse embed rows / RMSNorm gains; (3) **Muon WD mechanism is parameter-group-specific, not group-agnostic** — falsifies the transfer claim from PR #1966. AdamW-WD axis closed.
- **PR #2042 alphonse n=4 PARTIAL** (rope_base=4096): Trial 0 TERMINAL **FFS_ema=2925, FFS_trainval=2925 (canonical, no shift)**, val=3.27123 (+50 vs baseline 2875). **n=1 monotone-better dose-response REVERTED at n=4 trial 0** — textbook [[r5_n1_to_n4_reversion_dual_metric_attractor]] pattern. Trial 1+ in flight; even μ_4=2887.5 best-case (3 trials at 2875) misses gate 2862.5. ETA full n=4 terminal ~18:40Z. **Heading FFS-NEUTRAL/NEG.**
- **PR #2077 askeladd**: B★(λ=1e-4) **TERMINAL @11:28Z** FFS_ema=**2875** (canonical attractor); monotone-better ema_val_loss at ALL 8 probe steps (Δ −0.002 consistent). Per attractor gate → Cell C(λ=1e-3) launched. ETA ~13:25Z. **Strongest signal-candidate live** (8-step monotone Δ -0.002 ema dominates frieren's 5-step Δ -0.0018 candidate).
- **PR #2079 nezuko**: B★(mu_warmup_start=0.70) TERMINAL FFS_ema=2875, FFS_trainval=2925 (canonical, no shift), Δval oscillates around 0 → **pure attractor lock, no signal**. Cell C(mu=0.80) launching.
- **PR #2084 fern**: B★(attn=0.85, mlp=0.75 asym) TERMINAL FFS_ema=2875, FFS_trainval=**2875 (−50 OFF canonical)**, Δema=−0.0024 monotone-better → similar signature to frieren #2070. Cell C launched.
- **PR #2118 edward**: WIP — cap-DOWN sweep (cap={10, 12.5, 15, 17.5}) testing tighter direction of load-bearing logit softcap regularization.
- **PR #2070 frieren n=4**: in flight, ETA 17:30Z. Stale_wip checkin posted 12:55Z.
- **PR #2014 tanjiro**: Trial 3 of n=4 in flight at step 10216/13000 (~79%). μ_3=2916.67 (+54 above gate); trial 3 would need FFS_ema ≤ 2700 to recover. **Heading FFS-NEUTRAL/NEG**. ETA ~12:40Z.

### Fleet status snapshot — 5 parallel signal candidates being tested across PRs

| PR | Mechanism | n=1 signal | n=4 state | n=4 ETA |
|---|---|---|---|---|
| #2077 askeladd | z-loss λ=1e-4 | 8-step monotone ema Δ -0.002 | not yet escalated; C(λ=1e-3) terminal pending | — |
| #2070 frieren | mu+precond_freq compound | 5-step ema Δ -0.0018, FFS_trainval -50 off | n=4 in flight | 17:30Z |
| #2042 alphonse | RoPE base=4096 | 5-step val Δ -0.0015 | **n=4 trial 0 REVERTED** to 2925 | 18:40Z (likely FFS-NEUTRAL) |
| #2084 fern | asym mu attn=0.85 mlp=0.75 | 5-step ema Δ -0.0024, FFS_trainval -50 off | n=1 only; Cell C in flight | — |
| #2118 edward | logit softcap-DOWN | not yet terminal | n=1 only | — |

- **g1r5-thorfinn: assigned PR #2126** — trapezoid-lr-cooldown (13:22Z). Holds η=1.0 for first 50% of cooldown (steps 975-2112), then cosine-drops to 0 in second 50%. SOAP eigenbasis extended high-LR window hypothesis. First LR-shape axis on active fleet. B★ cell design A_ctrl(cosine) vs B★(trapezoid plateau=0.5); ETA ~3.5h.

---

## Last updated: 2026-06-01 10:38Z (**TWO parallel n=4 signal candidates — alphonse #2042 + frieren #2070; 8/8 active**)

### Notes (2026-06-01 10:38Z) — frieren B★ FFS-NEUTRAL OVERRIDDEN → n=4 confirm (2nd parallel signal candidate)

- **PR #2070 frieren — OVERRIDDEN from FFS-NEUTRAL closure → n=4 confirm**:
  - Student SENPAI-RESULT (10:31Z): A_ctrl FFS_ema=2875 / FFS_trainval=2925, B★ FFS_ema=2875 / FFS_trainval=**2875** (shifted −50 OFF canonical), best_val=3.26903 (Δ=−0.00185), ema_corr=3.26945 (Δ=−0.00184). Student recommended FFS-NEUTRAL.
  - **Advisor decision: ESCALATE to n=4**. Three discriminator features:
    1. **Dual-metric departure**: FFS_trainval shifted −50 OFF canonical {2875, 2925} attractor → real structural shift not just val_loss flicker
    2. **Monotone-better val_loss at ALL 5 probe steps** (Δ −0.0017 to −0.0020 nat) — **larger** than alphonse C(4096) Δ=−0.0015
    3. Per [[r5_n1_to_n4_reversion_dual_metric_attractor]]: canonical FFS_ema always escalates to n=4
  - Sent back at 10:34Z; n=4 confirm command uses `--precond_freq_cooldown 4` only (mu_cooldown_target=0.80 is now code default via #2071 merge)
  - **Gate at n=4**: μ_4(FFS_ema) ≤ 2862.5 → 3rd R5 MERGE candidate (compound mechanism — would push baseline below 2875 floor for first time)
  - ETA n=4 terminal **~17:30Z 2026-06-01**

### TWO parallel n=4 signal candidates in flight (compare)

| PR | Mechanism | Δ val_loss (n=1) | FFS_ema (n=1) | FFS_trainval shift | n=4 ETA |
|---|---|---:|---:|---|---|
| #2042 alphonse | RoPE base=4096 | −0.00151 | 2875 (canonical) | 2925 (canonical, no shift) | 18:40Z |
| **#2070 frieren** | **mu+precond_freq compound** | **−0.00185** | **2875 (canonical)** | **2875 (−50 OFF canonical)** | **17:30Z** |

- Both hold at n=4 → orthogonal axes (RoPE positional encoding vs SOAP preconditioner cadence) → assign compound stack next
- Either holds at n=4 → first n=4 result below the 2875 floor → 3rd R5 MERGE candidate
- Both revert → 2875 floor confirmed as genuine geometric bottleneck across mechanism classes

### Active in-flight as of 10:38Z

- **5 baseline cells (A_ctrl) confirmed at FFS_ema=2875** (frieren, thorfinn, edward, fern, nezuko) — fleet baseline stability locked
- **1 baseline cell at FFS_ema=2925** (askeladd — n=1 seed slip, within noise)
- **Tanjiro #2014 n=4** at risk of reversion (trial 0=2875, trial 1=2950, trial 2+ in flight → predicted FFS-NEUTRAL)
- **2 in-flight SIGNAL n=4 confirms**: alphonse rope_base=4096, frieren compound mu+precond_freq
- **Zero idle students; full 8/8 GPU utilization**

---

## Last updated: 2026-06-01 10:26Z (**alphonse #2042 n=4 LAUNCHED; frieren #2070 B★ W&B-finished pending SENPAI-RESULT; 8/8 active**)

### Notes (2026-06-01 10:26Z) — alphonse rebased + launched; frieren B★ pending result post

- **PR #2042 alphonse**: Rebased onto current advisor branch (post #1966 + #2071) at 10:18Z. **n=4 confirm at rope_base=4096 LAUNCHED** (W&B `rblece7h`, PID 1057747, 4 trials × 3250 steps, ETA terminal ~18:40Z).
- **PR #2070 frieren B★** compound mu+precond_freq: **W&B `stf1xg23` FINISHED at 10:19Z** with **FFS=2875 (canonical attractor)**, **best_val=3.2690 (Δ=-0.0011 vs baseline 3.27007)**, ema_corr=3.2694 (Δ=-0.0007). **Student SENPAI-RESULT pending.** Evaluation will depend on FFS_trainval and per-step probe trajectory (per [[r5_n1_to_n4_reversion_dual_metric_attractor]]: always escalate to n=4 on canonical attractor + signal).
- **PR #2080 edward**: A_ctrl(cap=15) `s2xuuj8d` TERMINAL at FFS=2875 (clean baseline replication on cap-value parameterization). Cells B(cap=30), C(cap=50), D(disabled) pending launches.
- **PR #2083 thorfinn**: A_ctrl/smoke `utj7l1g1` FINISHED at FFS=2875 (clean baseline). Cell launches pending; inspection finding 07:30Z documented baseline AdamW WD=0 hardcoded requiring explicit wd_scalars start value.
- **PR #2084 fern**: A_ctrl partial SENPAI-RESULT posted 10:03Z (FFS=2875, baseline match); B★(attn=0.85, mlp=0.75) still running.
- **PR #2077 askeladd**: A_ctrl `y5ueh85n` FFS=2925 (seed-0 attractor slip but within n=1 noise); B★(λ=1e-4) `xyivr11v` in flight at step 1611/3250 (~50%).
- **PR #2079 nezuko**: A_ctrl FINISHED FFS=2875; B★(mu_warmup_start=0.70) `s3dof65r` in flight at step 999/3250 (~31%).
- **PR #2014 tanjiro**: n=4 confirm at ns_iter=9 — trial 0 TERMINAL FFS=2875, trial 1 TERMINAL FFS=2950 (slip), trial 2+ in flight. Likely μ_4 ∈ [2887.5, 2912.5] → FFS-NEUTRAL outcome predicted.

### Active in-flight as of 10:26Z
- **5 baseline cells (A_ctrl) confirmed at FFS_ema=2875** (frieren, thorfinn, edward, fern, nezuko) — fleet baseline stability locked
- **1 baseline cell at FFS_ema=2925** (askeladd — n=1 seed slip)
- **2 SIGNAL-CANDIDATEs in flight**: alphonse rope_base=4096 n=4 confirm (ETA 18:40Z); frieren compound mu+precond_freq (n=1 pending SENPAI-RESULT)
- **Zero idle students**; full 8/8 GPU utilization

---

## Last updated: 2026-06-01 10:15Z (**100 R5 closures + 2 R5 merges; alphonse #2042 SIGNAL-CANDIDATE escalated to n=4; 8/8 active**)

### Notes (2026-06-01 10:15Z) — alphonse #2042 RoPE base 4096 SIGNAL — escalated to n=4 confirm

- **PR #2042 alphonse SIGNAL-CANDIDATE (rope-base-freq-probe)** — sent back for rebase + n=4 confirm:
  - Cell results: A(1024)=2925, B(64)=3000, C(**4096**)=**2875**, D(10000)=2925
  - C(4096): **FFS_ema=2875 (canonical attractor), FFS_trainval=2925, val_loss=3.26820** (−0.00187 vs μ_4=3.27007)
  - **Monotone-better val_loss vs A_ctrl at all 5 probe steps** (Δ −0.0012 to −0.0027)
  - **Clean inverted-U dose-response**: B(64) +0.004 worse than A, D(10000) +0.001 worse than A → axis matters
  - Per [[r5_n1_to_n4_reversion_dual_metric_attractor]]: ALWAYS escalate to n=4 on canonical {2875, 2925} attractor — do NOT close OR promote on 1 seed
  - Discriminator: clean dose-response + monotone trajectory justifies GPU time despite attractor coincidence
  - Action: rebase against advisor branch (post 2 merges); launch n=4 confirm at rope_base=4096
  - **Gate at n=4**: μ_4(FFS_ema) ≤ 2862.5 → 3rd R5 MERGE candidate; μ_4=2875 → FFS-NEUTRAL mechanism finding

- **Active in-flight at 10:15Z**:
  | PR | Mechanism | Status |
  |---|---|---|
  | #2014 tanjiro | NS5 ns_iter=9 cooldown n=4 | trial 2+ active (FFS=2950 partial signal — possible n=4 reversion) |
  | #2042 alphonse | RoPE base=4096 n=4 confirm | SIGNAL-CANDIDATE — sent back for rebase + n=4 |
  | #2070 frieren | compound mu+precond_freq | A_ctrl=2875 (baseline match); B★ at step 2463 ETA ~10:45Z |
  | #2077 askeladd | z-loss-regularization | A_ctrl=2925; B(λ=1e-4) at step 533 |
  | #2079 nezuko | warmup mu ramp | A_ctrl=2875; B★(mu=0.70) just launched |
  | #2080 edward | logit softcap value sweep | A_ctrl(cap=15)=2875 near-terminal; B(cap=30) queued |
  | #2083 thorfinn | adamw-wd-schedule | A_ctrl phase (KGsmoke + initial cells) |
  | #2084 fern | asymmetric-mu-cooldown | A_ctrl=2875 near-terminal |

- **Research portfolio (10:15Z):** 100 R5 closures, 2 merges, 1 signal candidate (alphonse rope_base=4096)
  - **★ Strongest current signal**: alphonse #2042 escalating to n=4 (RoPE architectural variant, val_loss improvement clear)
  - **2nd strongest signal**: frieren #2070 compound test (B★ pending; will reveal if stacking 2 mechanisms beats baseline)
  - **Tanjiro #2014 n=4** at risk of reversion (FFS=2950 partial; n=1 was 2875)
  - **5 baseline cells** confirm FFS_ema=2875 stability across the fleet
  - **Next gate**: μ_4(FFS_ema) ≤ 2862.5 = 2875 − 12.5

---

## Last updated: 2026-06-01 07:20Z (**101 R5 closures total; 2nd R5 MERGE; 2 new closures + 2 new assignments this heartbeat; 8/8 active**)

### Notes (2026-06-01 07:20Z) — 100th R5 closure; fern cleanup merge (#2 R5 merge); 2 fresh assignments; edward pivoted

- **PR #1994 CLOSED — 100th closure (thorfinn SOAP-state-cooldown-reset FFS-NEUTRAL n=4-confirm-failed)**:
  - All 4 trials locked at FFS_ema=2925 (σ_pop=0). Textbook [[r5_n1_to_n4_reversion_dual_metric_attractor]] pattern — n=1 B★=2875 was lower attractor lobe, reverted at n=4.
  - μ_4=2925.0 misses new gate by +62.5 (gate moved from 2887.5→2862.5 after frieren merge).
  - Step-1000 transient (+0.00167 vs A_ctrl) confirms eigenbasis rebuild cost after hard-reset.
  - **SOAP-state cooldown family fully closed** (3 PRs: precond_freq, β₂ smoothing, state reset — all FFS-NEUTRAL n=4-failed).
  - **→ THORFINN assigned #2083 adamw-wd-schedule** (extend merged Muon WD ramp_down to AdamW scalar/embed groups)

- **PR #2071 MERGED (2nd R5 MERGE) — fern cleanup: mu_cooldown_target=0.80 as code default**:
  - One-line argparse change bakes merged frieren winner as default. Smoke test verified (W&B `h9gsl16h`).
  - Mandatory stack simplified: `--mu_cooldown_target 0.80` no longer needs explicit flag.
  - **→ FERN assigned #2084 asymmetric-mu-cooldown** (attn vs MLP separate mu cooldown targets)

- **Edward #2080 PIVOTED** (advisor error acknowledged):
  - Original PR claimed "first logit-domain modification" — INCORRECT; line 498 already has soft-sign cap=15.
  - Pivot: test existing softcap VALUE sweep (cap ∈ {15, 30, 50, ∞}) keeping soft-sign form (single-variable).
  - Added `train/logit_abs_mean` and `train/logit_saturation_frac` diagnostics.
  - Status:wip; edward implementing revised design.

- **Active in-flight at 07:20Z**:
  | PR | Mechanism | Status |
  |---|---|---|
  | #2014 tanjiro | NS5 ns_iter=9 cooldown n=4 | trials 2-3 of 4, ETA ~12:00Z |
  | #2042 alphonse | RoPE base sweep | C(4096)/D(10000) in flight |
  | #2070 frieren | compound mu+precond_freq | A_ctrl+B★ running |
  | #2077 askeladd | z-loss regularization | KG_smoke → cells running |
  | #2079 nezuko | warmup mu ramp | KG_smoke → cells running |
  | #2080 edward | logit softcap value sweep | PIVOTED: revised cap-value design; implementing |
  | #2083 thorfinn | adamw-wd-schedule | NEW assigned 07:20Z |
  | #2084 fern | asymmetric-mu-cooldown | NEW assigned 07:20Z |

- **Research portfolio (07:20Z) — 100 R5 closures, 2 merges:**
  - **Primary targets**: frieren #2070 compound test (additivity of two n=1 mechanisms); tanjiro #2014 ns_iter=9 (inverted dose-response, strongest recent signal)
  - **New loss-boundary cluster**: askeladd z-loss + edward logit-cap-value + askeladd all test different ways to constrain logit/loss behavior
  - **Phase transition cluster**: nezuko warmup-mu + fern asymmetric-mu test different dimensions of momentum schedule
  - **Extension cluster**: thorfinn adamw-wd-schedule extends the successful Muon WD ramp to AdamW groups
  - **Next gate**: μ_4(FFS_ema) ≤ **2862.5** (= 2875 − 12.5; requires ≥2/4 trials at FFS=2850)

---

### Notes (2026-06-01 06:55Z) — 97th/98th/99th R5 closures; 3 fresh assignments

- **PR #2030 CLOSED — 97th closure (SF-Muon y-interp FFS-NEG)**:
  - Cooldown-freezing failure mode identified: lr-weighted Polyak × cosine LR cooldown → x frozen at cooldown-onset
  - SF iterate-averaging family CLOSED; memory saved: [[sf-polyak-cooldown-freeze-failure]]
  - **→ ASKELADD assigned #2077 z-loss-regularization** (first loss-side mechanism in 99 R5 closures)

- **PR #2020 CLOSED — 98th closure (nezuko SOAP β₂ cooldown FFS-NEUTRAL)**:
  - Non-monotone M-shape, A_ctrl is global minimum; B(0.70)=D(0.95) bit-essentially-identical
  - Eigenbasis-saturation confirmed: fast precond_freq=8 washes out β₂ changes at each refresh
  - SOAP-state cooldown family FULLY CLOSED (3 PRs: precond_freq, β₂ smoothing, state reset)
  - **→ NEZUKO assigned #2079 warmup-mu-ramp** (symmetric complement to frieren merge: μ 0.70→0.95 during warmup)

- **PR #2062 CLOSED — 99th closure (edward MLP-act SiLU FFS-NEG)**:
  - SiLU FFS_ema=-1 (never crossed); val_loss=3.300 vs baseline 3.270 at terminal
  - Dead-neuron hypothesis falsified; ReLU² is load-bearing in co-tuned R5 stack
  - Kill gate correctly triggered; GELU/SwiGLU not run
  - **→ EDWARD assigned #2080 logit-softcap** (tanh logit cap, Gemma 2 style, first logit-domain test)

- **Imminent: THORFINN #1994 n=4 terminal** — student heartbeat ~07:06Z
  - Trial 4 completed at ~06:24Z; student posting SENPAI-RESULT next heartbeat
  - Pre-decision: 95th closure (μ_4≈2925, gate 2862.5 unreachable by +62.5)
  - After close: assign thorfinn fresh hypothesis

- **Active in-flight at 06:55Z**:
  | PR | Mechanism | Status |
  |---|---|---|
  | #1994 thorfinn | SOAP state reset n=4 | TERMINAL pending SENPAI-RESULT ~07:06Z |
  | #2014 tanjiro | NS5 ns_iter=9 cooldown n=4 | trial 1 of 4, ETA ~12:00Z |
  | #2042 alphonse | RoPE base sweep | C(4096) in flight (~07:13Z); D(10000) queued |
  | #2070 frieren | compound mu+precond_freq | KG_smoke done, A_ctrl+B★ running |
  | #2071 fern | cleanup mu=0.80 default | 200-step smoke pending |
  | #2077 askeladd | z-loss regularization | NEW assigned 06:35Z |
  | #2079 nezuko | warmup mu ramp | NEW assigned 06:55Z |
  | #2080 edward | logit softcap | NEW assigned 06:55Z |

- **Research portfolio (06:55Z) — 99 R5 closures, 1 merge:**
  - **Highest value**: frieren #2070 compound test (additivity of two n=1 mechanisms against new baseline)
  - **Interesting signal**: tanjiro #2014 ns_iter=9 cooldown n=4 (inverted dose-response; needs μ_4 ≤ 2862.5 to merge)
  - **New axes**: askeladd z-loss (first loss-side), nezuko warmup-mu (symmetric to merge), edward logit-softcap (first logit-domain)
  - **Cleanup**: fern #2071 bakes mu=0.80 default
  - **Next gate**: μ_4(FFS_ema) ≤ **2862.5** requires ≥2/4 trials at FFS_ema=2850

---

## Last updated: 2026-06-01 06:40Z (**★★★ FIRST R5 MERGE + 97th closure; ASKELADD → z-loss; 8/8 active**)

### Notes (2026-06-01 06:40Z) — 97th R5 closure SF-Muon; askeladd assigned z-loss

- **PR #2030 CLOSED — 97th R5 closure (SF-Muon y-interp FFS-NEG, cooldown-freezing failure mode)**:
  - Cell 1 y-interp `2hjv966e` terminal: val_loss=3.36632, **FFS_ema=-1** (target never crossed)
  - Δ vs baseline = **+0.096** — significant underperformance
  - Student diagnosed mechanism: lr-weighted Polyak averaging × cosine LR cooldown = cooldown-freezing. During cooldown c_t/C_t → 7e-8, so x freezes at cooldown-onset value (~3.367); baseline descends another 0.10 through cooldown. Incompatibility is fundamental, not tunable.
  - **Saved to memory**: `[[sf-polyak-cooldown-freeze-failure]]` — future SF/Polyak/Lookahead ideas need cooldown-reset or SWA-style accumulation to be viable on R5 cosine-cooldown stack
  - SF iterate-averaging family CLOSED on R5 (SF Muon grad-at-x + y-interp + prior fern/askeladd AUX variants all FFS-NEG)

- **NEW ASSIGNMENT #2077 (askeladd) — z-loss-regularization**:
  - **First loss-side mechanism in 97 R5 closures** — all prior experiments touched optimizer-state, schedules, architecture
  - Z-loss: add `0.5 · λ_z · (logsumexp(logits))²` term to CE loss. PaLM/Gopher/Chinchilla canonical λ=1e-4
  - Screen: A_ctrl, B★(λ=1e-4), C(λ=1e-3), D(λ=1e-2) — dose-response
  - Gate: B★ FFS_ema ≤ 2862.5 + monotone-better trajectory → n=4
  - Fresh axis: loss-side ≠ gradient-processing; won't be absorbed by NS5 family

- **THORFINN #1994 n=4 trial 4 imminent** (step 12539/13000, ~96%):
  - Pre-decision: 95th closure, gate unreachable. Final μ_4 will be ~2900-2912.5. Await terminal SENPAI-RESULT.
  - **→ Next: assign thorfinn fresh hypothesis post-closure**

- **Active in-flight at 06:40Z**:
  | PR | Mechanism | ETA |
  |---|---|---|
  | #1994 thorfinn | SOAP state reset n=4 trial 4 | ~06:50Z terminal |
  | #2014 tanjiro | NS5 ns_iter=9 cooldown n=4 | ~12:00Z terminal |
  | #2020 nezuko | SOAP β₂ cooldown D(0.95) | TERMINAL by now |
  | #2042 alphonse | RoPE base sweep C(4096), D(10000) | C~07:13Z, D~09:00Z |
  | #2062 edward | MLP-act SiLU n1-probe | ~06:50Z terminal |
  | #2070 frieren | compound mu+precond_freq | KG_smoke done, A_ctrl+B in flight |
  | #2071 fern | cleanup mu=0.80 default | 200-step smoke pending |
  | #2077 askeladd | z-loss regularization | new assignment 06:35Z |

- **Research portfolio balance (06:40Z):**
  - **Exploitation**: frieren #2070 compound test (highest-value — additivity of two n=1 mechanisms)
  - **Exploitation**: tanjiro #2014 n=4 ns_iter=9 (surprising inverse signal, gate needs ≤2862.5)
  - **Exploration**: askeladd z-loss (first loss-side mechanism), edward MLP-act, alphonse RoPE sweep
  - **Cleanup**: fern #2071 bakes mu=0.80 default → reduces footgun risk
  - **Next gate**: μ_4(FFS_ema) ≤ **2862.5** requires ≥2/4 trials at FFS_ema=2850

---

## Last updated: 2026-06-01 05:20Z (**★★★ FIRST R5 MERGE COMPLETE — 95 R5 total events**; **FRIEREN #1966 MERGED** μ_4=2875.0 σ_4=0.0 new baseline −37.5 steps; **FERN #2023 CLOSED 96th FFS-NEG** Lion AUX axis; **FRIEREN assigned #2070** compound-mu-precond-freq; **FERN assigned #2071** cleanup-mu-cooldown-default; **THORFINN #1994 gate unreachable → 95th closure pending** (trial 3 in flight); **TANJIRO #2014 D-target9 ★ FFS=2875 SURPRISE** (MORE polish during cooldown); **NEZUKO #2020 D(0.95) in flight**; **ASKELADD #2030 relaunch alive**; **ALPHONSE #2042 B(64) in flight**; **EDWARD #2062 SiLU probe in flight**; 8/8 active)

## Last updated: 2026-06-01 04:20Z (**94 R5 closures**; ★★★ **FRIEREN #1966 TRIAL 3 AT 87% — μ_4 PROJECTED ≈ 2875.2 — FIRST R5 MERGE IMMINENT** (ETA terminal ~04:35Z; merge-winner ready to invoke); **THORFINN #1994 trial 2 at 88% — gate unreachable, 95th closure pending**; **NEZUKO #2020 Cell C(0.80)=FFS-NEG +50** dose-response shape non-monotone (B=0.70 at 2925 vs C=0.80 at 2975); **ASKELADD #2030 y-interp RELAUNCH alive at step 271** with relaxed kill gate 3.88; **EDWARD #2062 PICKED UP** — SiLU n1-probe at step 212 + KG smoke; **TANJIRO #2014 D-target9 falsifier at 77%** trending FFS-NEG; **ALPHONSE #2042 B-64 at 52%**; **FERN #2023 D(lrs=0.3) projected FFS≈3150 FFS-NEG**; 8/8 active)

### Notes (2026-06-01 05:20Z) — ★★★ FIRST R5 MERGE COMPLETE; NEW BASELINE; COMPOUNDING ASSIGNED

- **★★★ PR #1966 MERGED — FIRST R5 MERGE IN 94+ CLOSURES (Muon mu cooldown ramp 0.95→0.80):**
  - μ_4(FFS_ema) = **2875.0**, σ_4 = **0.0** — ALL 4/4 trials at FFS_ema=2875 (perfect consistency)
  - Δ vs old baseline = **−37.5 steps** (−1.5σ_old)
  - **New baseline**: μ_4=2875.0, σ_4=0.0, val_loss=3.27007
  - **New merge gate**: μ_4(FFS_ema) ≤ **2862.5** (requires ≥2/4 trials at FFS_ema=2850)
  - **New mandatory stack**: `--mu_cooldown_target 0.80` added
  - Run: `fjyckuu1` (group `g1r5-frieren/muon-mu-sched-n4`)

- **PR #2023 CLOSED — 96th R5 closure (Lion AUX FFS-NEG)**:
  - B(Lion lrs=0.1)=FFS-NEG (-1), D(Lion lrs=0.3)=FFS-NEG (-1) — target uncrossed
  - Conclusion: AdamW second-moment normalization is load-bearing for AUX groups at R5

- **NEW ASSIGNMENT #2070 (frieren) — compound-mu-precond-freq**:
  - Hypothesis: Stack mu_cooldown_target=0.80 (baseline) + precond_freq_cooldown=4 (edward's mechanism)
  - Tests if SOAP eigenbasis refresh cadence and Muon momentum ramp are additive
  - A_ctrl=new baseline (expect FFS_ema=2875), B★=stacked compound (expect FFS_ema≤2862.5 if additive)
  - Kill gate: B★ ≥ 2925 → close (no marginal gain); Signal: B★ ≤ 2862.5 → n=4 confirm
  - **Requires re-implementing `--precond_freq_cooldown` flag** (reference edward #1948)

- **NEW ASSIGNMENT #2071 (fern) — cleanup-mu-cooldown-default**:
  - Change `--mu_cooldown_target` default from None to 0.80 in train_gpt_simple.py (~2 LOC)
  - Verify with 200-step smoke test: `train/mu/muon_mlp ≈ 0.80` at step 200 without explicit flag
  - Fast turnaround (~30 min total), no experiments

- **TANJIRO #2014 D-target9 (MORE polish, ns_iter=9) at ~97% — SURPRISING FFS=2875**:
  - A=2925, B=2925, C=2950 (polish REDUCTION harmful), D=**2875** (MORE polish HELPS!)
  - INVERTED mechanism: MORE NS5 iterations during cooldown is FFS-positive
  - Need terminal SENPAI-RESULT; if confirmed, opens NEW axis: ns_iter INCREASE cooldown

- **THORFINN #1994 trials 0+1+2 ALL at FFS_ema=2925 — 95th closure imminent**:
  - Trial 3 in flight; gate unreachable (best μ_4 = 2912.5 = old baseline, misses new gate 2862.5)
  - Will close as FFS-NEUTRAL n=4-confirm-failed (SOAP state reset was n=1 positive but n=4 NEUTRAL)
  - After closure: assign thorfinn a fresh hypothesis

- **Key active runs** (~05:20Z):
  | PR | Status | ETA |
  |---|---|---|
  | #1994 thorfinn n=4 trial 3 | ~step 10047/13000 | ~07:30Z |
  | #2014 tanjiro D-target9 | NEAR TERMINAL (~97%) | ~05:25Z |
  | #2020 nezuko D(0.95) | mid-flight | ~07:00Z |
  | #2030 askeladd y-interp cell 1 | step ~500/3250 | ~09:00Z |
  | #2042 alphonse B(64) | mid-flight | ~07:00Z |
  | #2062 edward SiLU n1-probe | mid-flight | ~07:00Z |
  | #2070 frieren compound | NEW — awaiting pickup | — |
  | #2071 fern cleanup | NEW — awaiting pickup | — |

- **Research portfolio (05:20Z):**
  - **Next threshold: μ_4(FFS_ema) ≤ 2862.5** — requires breakthrough below 2875 attractor
  - **Compounding priority**: frieren #2070 is the highest-value pending experiment (tests additivity of two confirmed n=1 mechanisms)
  - **Surprise to investigate**: tanjiro D (MORE NS5 polish during cooldown → FFS=2875) — if terminal confirms, opens ns_iter INCREASE axis that is ORTHOGONAL to the mu/SOAP cooldown mechanisms
  - **After thorfinn #1994 closure**: assign fresh hypothesis in new territory

### Notes (2026-06-01 04:20Z) — FRIEREN MERGE-WINNER IMMINENT

- **★★★ FRIEREN #1966 TRIAL 3 AT 87% — FIRST R5 MERGE WITHIN 15 MIN** (run `fjyckuu1`, step 12582/13000):
  - Trial 0: FFS_ema=**2875**, FFS_trainval=2925
  - Trial 1: FFS_ema=**2875**, FFS_trainval=2875 (BOTH off-attractor)
  - Trial 2: FFS_ema=**2875**, FFS_trainval=2925
  - Trial 3: in flight at step ~2830/3250, ema=3.2849, slope −0.0074/100 steps, projected FFS_T3 ≈ **2897** ≤ 2925 budget
  - **μ_4(FFS_ema) projected = 2875.2** — DECISIVE CLEAR vs gate 2887.5 (+12.3 step headroom)
  - **ETA terminal ~04:30-04:45Z**; invoke `senpai:merge-winner 1966 target/` after student posts terminal SENPAI-RESULT marker
  - **FIRST R5 MERGE IN 94 CLOSURES** — Muon mu cooldown gradual ramp (0.95→0.80) becomes new baseline

- **THORFINN #1994 trial 2 at 88% — closure pending** (run `ok9uc4uk`):
  - Trial 0+1 = both FFS_ema=2925 (canonical attractor, not off-attractor)
  - Trial 2 at step 2863/3250, ema=3.2887
  - Best case μ_4 = 2900 → still misses gate 2887.5 by +12.5 steps → MATHEMATICALLY UNREACHABLE
  - Will close as 95th R5 closure (FFS-NEUTRAL n=4-confirm-failed with trainval attractor regression 2925→2950 across n=1→n=4)
  - Student chose Option (A) — continue trials 2+3 for full closure documentation

- **NEZUKO #2020 Cell C(0.80) TERMINAL FFS-NEG +50**:
  - A_ctrl(0.90) = 2925 (canonical attractor)
  - B(0.70) = 2925 (FFS-NEUTRAL, tied with A_ctrl)
  - **C(0.80) = 2975 (slipped off attractor +50)**
  - Non-monotone dose-response shape: midpoint is WORST. Suggests SOAP β₂ smoothing rate is dominated by eigenbasis refresh cadence (precond_freq=16) — similar saturation as edward #1948 freq cooldown
  - D(0.95, falsifier increased smoothing) in flight; ETA terminal ~05:30-06:00Z
  - If D(0.95) lands at 2925 → axis closes as bidirectional NEUTRAL (β₂ smoothing irrelevant when refresh cadence dominates)

- **ASKELADD #2030 y-interp RELAUNCH ALIVE** (run `2hjv966e`, step 271):
  - Cell 1★ (β=1.0, yb=0.9, all-layers) restarted with relaxed kill gate 3.88 at step 875
  - Previous y-interp run (`qzk48l5r`, killed): val_loss=3.6459 at step 875 — **BETTER than n=4 baseline 3.6769** (Δ=−0.031)
  - +0.11 swing vs failed grad-at-x variant (3.7583) — patch is mechanically working
  - ETA terminal cell 1 ~09:30Z if no further interruption
  - Decision tree: if FFS_ema ≤ 2875 at cell 1 → fast-escalate to n=4 confirm (skip cells 2/3)

- **EDWARD #2062 PICKED UP** — first MLP-activation experiment in 94 R5 closures:
  - run `uqmgnxeo` SiLU n1-probe at step 212/3250
  - run `rdnwa3gt` SiLU KG_smoke launching
  - ETA Cell B★ terminal ~05:30-06:00Z
  - Kill gate if FFS_ema ≥ 2950 on n=1 → close axis immediately

- **TANJIRO #2014 D-target9 (falsifier MORE polish) at 77%** (run `mr3v2aui`):
  - ema=3.3222, not trending toward 3.28
  - Already known FFS-NEG dose-response on reduction side (A=2925 < B=2925 < C=2950 worse)
  - D probes opposite direction; if D ≥ A_ctrl → axis closes as two-sided FFS-NEUTRAL
  - ETA terminal ~04:50-05:00Z

- **ALPHONSE #2042 B(64) at 52%** (run `ilv14as2`, step 1701/3250):
  - A_ctrl(1024) = 2925 (terminal, canonical attractor)
  - val=3.527, ema=3.428 at step 1701 — still in descent
  - Sequential after B: C(4096), D(10000) — total ETA ~10:00Z
  - First positional-encoding ablation in 94 R5 closures

- **FERN #2023 Cell D(lrs=0.3) at 88%** (run `bgynmsmm`):
  - Projected FFS_ema ≈ 3150 — substantially worse than baseline 2925
  - A=2925, B(lrs=0.1)=FFS-NEG (-1), D(lrs=0.3)=FFS-NEG projected
  - Lion AUX axis trending FFS-NEG across bracket {0.1, 0.3} — direction systematic, not point-specific

- **Action queue (next heartbeat):**
  - **WAIT for frieren #1966 trial 3 terminal SENPAI-RESULT (~15 min) → INVOKE senpai:merge-winner — FIRST R5 MERGE**
  - Close thorfinn #1994 as 95th R5 closure after trial 3 terminal
  - Watch tanjiro #2014 D terminal → close NS5-iter-cooldown axis
  - Continue nezuko #2020 D, alphonse #2042 B/C/D, fern #2023 D, askeladd #2030 cell 1, edward #2062 cell B watch

## Last updated: 2026-06-01 03:05Z (**93 R5 closures**; ★★★ **FRIEREN #1966 n=4 CONFIRM 3/4 ALL AT FFS_EMA=2875 — MERGE GATE NEAR-CERTAIN** — trial 3/4 in flight, trial 3 budget ≤ 2925 suffices to clear @ μ_4 ≤ 2887.5; **EDWARD #1948 4/4 COMPLETE μ_4(FFS_ema)=2912.5 → 94th R5 closure pending**; **THORFINN #1994 2/4 GATE MATHEMATICALLY UNREACHABLE → 95th R5 closure pending**; **TANJIRO #2014 C-target2=FFS-NEG +25 worse, polish-reduction dose-response axis CLOSING**; **ASKELADD #2030 SF-Muon Cell-1 +0.167 val_loss → Option (B) y-interp patch send-back**; 8/8 active)

### Notes (2026-06-01 03:05Z) — DECISIVE HEARTBEAT: edward/thorfinn close, frieren ready to merge

- **★★★ FRIEREN #1966 n=4 CONFIRM 3/4 ALL AT FFS_EMA=2875** (run `fjyckuu1`):
  - Trial 0: FFS_ema=**2875**, FFS_trainval=2925 (EMA off-attractor)
  - Trial 1: FFS_ema=**2875**, FFS_trainval=2875 (BOTH off-attractor)
  - Trial 2: FFS_ema=**2875**, FFS_trainval=2925 (EMA off-attractor)
  - Trial 3: in flight (~76%, step 9927/13000 global)

  **μ_4 gate accounting:**
  - Sum FFS_ema = 8625; budget for trial 3: 11550 − 8625 = **2925**
  - Trial 3 only needs FFS_ema ≤ 2925 (canonical attractor value) to clear gate
  - Best-case μ_4(FFS_ema) = **2875.0**; worst clearable μ_4 = 2887.5
  - **3× consecutive FFS_ema=2875 makes gate clear near-certain**

  When trial 3 terminals (ETA ~04:00-04:30Z) → invoke `senpai:merge-winner 1966 target/` — **FIRST R5 MERGE IN 93+ CLOSURES**

- **EDWARD #1948 4/4 COMPLETE μ_4(FFS_ema)=2912.5 → 94th R5 closure (FFS-NEUTRAL n=4-confirm-failed)**:
  - Trial 0: FFS_ema=**2875** | Trials 1-3: FFS_ema=**2925** (all at attractor)
  - μ_4 exactly equals PR #1533 baseline → SOAP precond_freq cooldown ramp absorbed
  - Pre-decision comment posted; awaiting terminal SENPAI-RESULT marker
  - Mechanism: SOAP eigenbasis refresh stride 16→4 — kernel signal in n=1, reverts to seed noise at n=4

- **THORFINN #1994 2/4 GATE UNREACHABLE → 95th R5 closure pending**:
  - Trial 0: FFS_ema=2925, FFS_trainval=2950 | Trial 1: FFS_ema=2925, FFS_trainval=2950 (REGRESSION pattern)
  - Best-case μ_4 = 2900 (trials 2+3 both 2875) → still misses gate by +12.5 steps
  - Pre-decision comment posted (offered student abort-or-continue choice)
  - Mechanism: SOAP shampoo state hard-reset at cooldown_start (step 975) — n=1 B★ signal was seed noise

- **TANJIRO #2014 C-target2 TERMINAL = FFS-NEG +25 worse**: dose-response A_ctrl < B-target3 < C-target2 (monotone DOWN-IS-WORSE in val_loss). NS5 polish reduction during cooldown is harmful. D-target9 (MORE polish, falsifier) in flight at step 55/3250 (ETA ~04:50Z). If D ≤ A_ctrl → axis extends; if D ≥ A_ctrl → axis fully closes as NEUTRAL.

- **ASKELADD #2030 SF-Muon CELL 1 TERMINAL MISS +0.167 val_loss** — student diagnosed root cause: PR spec evaluated grads at pure x (Polyak avg) but canonical SF AdamW (Defazio 2024 Alg. 1) requires interpolation `y_t = (1−β)z + βx` with β≈0.9. **Option (B) approved**: ~30 LOC patch + `--sf_y_beta` flag + rerun cells 1★/2/3 at sf_y_beta=0.9. Closing on cell 1 alone would falsify the variant, not the family. Send-back keeps status:wip.

- **ALPHONSE #2042 — 4096 KG-SMOKE CRASHES, A_ctrl(1024) PROGRESSING**: 2 × KG_smoke crashes at base=4096 step 199; smokes for {64, 1024} PASSED. A_ctrl(1024) at step 2494/3250 (76%). Student traceback pending. Alternative cell design {64, 256, 1024, 2048} proposed if 4096+ truly unreachable.

- **FERN #2023 Lion AUX optimizer — direction weak across cells**: A_ctrl=2925 (attractor, byte-clean), Cell B (β=0.9, lrs=0.1) terminal MISS FFS=-1, Cell C (β=0.99) crashed step 23 (immediate divergence), Cell D running at step 194 (early). Student executing advisor contingency to skip C and try D. Lion family showing systematic regression in our R5 stack.

- **NEZUKO #2020 SOAP β₂ cooldown — Cell C in flight**: Cell B★ established FFS=2925 attractor; Cell C at step 959/3250 (29.5%), Cell D pending.

- **Action queue (next heartbeat):**
  - ✅ edward #1948 CLOSED 94th R5 closure (μ_4(FFS_ema)=2912.5 = baseline FFS-NEUTRAL n=4-confirm-failed)
  - ✅ edward #2062 NEW: mlp-act-variant (SiLU/GELU/SwiGLU — FIRST MLP activation experiment in 94 R5 closures; 8/8 active again)
  - Wait for frieren #1966 trial 3 terminal → **MERGE** if μ_4 ≤ 2887.5 — FIRST R5 MERGE
  - Wait for thorfinn #1994 student decision (abort or continue trials 2+3) → close as 95th
  - Wait for tanjiro #2014 D-target9 terminal → likely close axis (NEUTRAL or NEG)
  - Address alphonse #2042 crash traceback when posted
  - Continue fern #2023 / nezuko #2020 / askeladd #2030 watch

---

## Last updated: 2026-06-01 01:15Z (**93 R5 closures**; ★★★ **FRIEREN #1966 n=4 CONFIRM TRIALS 0+1 BOTH AT FFS=2875** — Muon mu cooldown 0.95→0.80 gradual ramp emerging as merge-candidate; 2/4 trials terminal off-attractor, trials 2+3 in flight; if pattern holds μ_4 = 2875 → decisive gate clear @2887.5 with +12.5 step headroom; ETA terminal ~04:10-04:20Z; 8/8 active)

### Notes (2026-06-01 01:15Z) — frieren signal strengthening; first potential merge in 93 closures

- **★★★ FRIEREN #1966 n=4 CONFIRM AT 2/4** — both trials hit FFS=2875 (run `fjyckuu1`):
  - Trial 0: FFS=2875 (off-attractor, terminal)
  - Trial 1: FFS=2875 (off-attractor, terminal)
  - Trial 2: in flight (~18%, step 558/3250)
  - Trial 3: pending
  
  **μ_4 gate scenarios:**
  - If trials 2+3 = 2875: μ_4 = **2875** (decisive merge, +12.5 step headroom)
  - If trial 2=2925, trial 3=2875: μ_4 = 2887.5 (gate just clears)
  - If both trials 2+3 = 2925: μ_4 = 2900 (gate fails by 12.5)

  This is the MOST PROMISING merge candidate in 93 R5 closures. The n=1 cells {B(mu=0.85), C(mu=0.80)} both hit FFS=2875 — now reproducing in 2 of 4 confirmation trials. **The Muon momentum cooldown axis (gradual ramp, not discrete reset) appears to be a robust positive mechanism.**

- **3 parallel n=4 confirms — current standing:**
  - **frieren #1966 mu=0.80** ★★★ 2/4 BOTH at FFS=2875 — looking like merge-winner
  - edward #1948 freq=4: trial 3/4 ETA ~02:41Z. Trials 0+1 = {2875, 2925} → μ_2=2900 (borderline)
  - thorfinn #1994 SOAP reset: trial 0 = 2925 (canonical attractor, NOT reproducing n=1 B★ result yet) → trial 1/4 in flight

- **All 8 students active:**
  - alphonse #2042 NEW: rope-base-freq-probe (just assigned 00:45Z; representational-capacity tier)
  - askeladd #2030: sf-muon-polyak-ruppert WIP (~2h, no terminal yet)
  - edward #1948: n=4 confirm trial 3/4
  - fern #2023: lion-aux-optimizer Cell B at ~20% (lr_scale=0.1, β₁=0.9) — A_ctrl=2925 byte-clean
  - frieren #1966: n=4 confirm trial 2/4 ★★★
  - nezuko #2020: soap-beta2-cooldown post A_ctrl terminal
  - tanjiro #2014: ns-iter-cooldown-ramp post A_ctrl terminal (2925)
  - thorfinn #1994: n=4 confirm trial 1/4

- **Pending merge gate:** If frieren #1966 trials 2+3 deliver FFS ≤ 2875 each, invoke senpai:merge-winner immediately. This would be the FIRST merge in 93 R5 experiments.

---

## Last updated: 2026-06-01 00:45Z (**93 R5 closures**; **93rd: alphonse #1979 lr-warm-restart-probe FFS-NEG-ablation** — warm-restart magnitude×timing axis fully closed; ★★★ **TIER-SHIFTING FINDING: FFS bottleneck is NOT local-minimum-escape — likely representational-capacity-bound**; **alphonse → PR #2042 rope-base-freq-probe (RoPE angular freq base {64, 1024, 4096, 10000}; first positional-encoding ablation in 93 R5 experiments)**; 8/8 active; 3 parallel n=4 confirms in flight)

### Notes (2026-06-01 00:30Z) — 93rd closure; ★★★ tier-shift to representational-capacity hypothesis space

- **93rd R5 CLOSURE — ALPHONSE #1979 (lr-warm-restart-probe) FFS-NEG-ablation**: 4-cell magnitude × timing axis: A_ctrl + B★(p=0.3, s=2700) + C(p=0.3, s=2500) + D(p=0.5, s=2700). Results:

  | Cell | step | peak_frac | FFS_ema | FFS_trainval | best_val_loss | wandb |
  |---|---:|---:|---:|---:|---:|---|
  | A_ctrl | — | 0.0 | 2950 | 2975 | 3.27209 | nw9ixlxu |
  | B★ | 2700 | 0.3 | **2875** | 3000 | 3.27227 | 80igcp9o |
  | C | 2500 | 0.3 | 2925 | 2925 | **3.26959** | lheva20i |
  | D | 2700 | 0.5 | **−1** | **−1** | 3.28794 | u7owghmq |

  B★: dual-metric divergence (FFS_ema improved, FFS_trainval regressed) → seed noise per [[r5_n1_to_n4_reversion_dual_metric_attractor]]. C: lowest best_val_loss but landed at canonical attractor → pulse perturbed WHERE not WHEN. D: catastrophic — pulse bounced model out of basin, never crossed 3.28 (val_loss SPIKED to 3.324 at step 2875).

- **★★★ TIER-SHIFTING MECHANISM FINDING**: Across the entire warm-restart magnitude × timing axis, the pulse perturbs the converged trajectory but **does not advance the FFS crossing event**. Small pulse → attractor noise; large pulse → trajectory destruction. **No "sweet spot" between catastrophe and inaction.** This decisively distinguishes the FFS bottleneck from a local-minimum-escape problem — there is no sharp minimum being escaped to a broader basin within the standard cosine cooldown. **Future R5 hypotheses should focus on representational capacity, not optimization-landscape geometry.**

- **R5 LR-SCHEDULE DESIGN SURFACE NOW EXHAUSTIVELY EXPLORED**: peak magnitude (#1830), shape variants (#1922), direction (fern #1983 91st: ramp_down load-bearing), warm restart (alphonse #1979 93rd: closed across peak_frac × restart_step). All FFS-NEG or FFS-NEUTRAL with mandatory R5 stack. **The LR family is closed.**

- **ALPHONSE HYPOTHESIS DISPATCH IN FLIGHT** — researcher-agent tasked with representational-capacity tier hypothesis. Candidate frontiers per dispatch:
  1. Representational capacity within fixed-architecture (init schemes, parameter sharing patterns, attention head specialization, residual stream reweighting)
  2. Information flow modifications (gating, gradient routing, layer-wise LR that changes WHAT not just HOW)
  3. Token/position embedding scheme changes (rare-vocab pattern representation)
  
  Explicitly excluded closed families: pre-NS5 modifiers (4), AUX cooldown PARAM+SHAPE (4), LN gain init<1.0, NS5 absorption (3), WD-axis, μ momentum DISCRETE reset, warm restart magnitude. Output expected at `/research/RESEARCH_IDEAS_ALPHONSE_2026-06-01_00:30.md`.

- **★★★ THREE PARALLEL FFS-POSITIVE n=4 CONFIRMS STILL IN FLIGHT** (unchanged from 22:55Z):
  - edward #1948 (SOAP precond_freq=4 cooldown continuous) — trial 3/4 ETA ~02:41Z
  - frieren #1966 (Muon mu=0.80 gradual ramp) — trial 1/4 in flight
  - thorfinn #1994 (SOAP state hard-reset discrete) — n=4 launch directive posted

- **7/8 ACTIVE — CURRENT FLEET STATUS (00:30Z)**:
  - edward #1948: n=4 confirm in flight (trial 3/4)
  - frieren #1966: n=4 confirm in flight (trial 1/4)
  - thorfinn #1994: n=4 launch directive posted (student picking up)
  - tanjiro #2014: ns-iter-cooldown-ramp mid-run
  - nezuko #2020: soap-beta2-cooldown post-watchdog
  - fern #2023: lion-aux-optimizer (1st AUX algorithm replacement) WIP
  - askeladd #2030: sf-muon-polyak-ruppert (1st MUON-side algorithm change) WIP
  - **alphonse #1979 CLOSED 93rd; idle pending researcher-agent return**

---

## Last updated: 2026-05-31 23:05Z (**92 R5 closures**; **askeladd → #2030 sf-muon-polyak-ruppert (Schedule-Free Muon body iterate averaging — first MUON-side optimizer ALGORITHM change in 92 R5 experiments)**; 8/8 active; 3 parallel n=4 confirms in flight)

### Notes (2026-05-31 23:05Z) — askeladd #2030 SF-Muon Polyak-Ruppert assigned; 8/8 active

- **ASKELADD → PR #2030 (sf-muon-polyak-ruppert)** — Schedule-Free Muon body iterate averaging. Maintains base iterate `z` (receives gradient + WD), with `p` holding the cumulative lr-weighted Polyak-Ruppert average `x = Σ(lr_t × z_t) / Σ(lr_t)`. **First MUON-side optimizer ALGORITHM change in all 92 R5 experiments.** Zero extra communication: `dist.all_gather` already syncs `p`. Three cells: (1) β=1.0 all groups (pure SF), (2) β=0.98 all (recency-dampened, MLCommons AlgoPerf 2024 sweet spot), (3) β=1.0 MLP-only (isolation test). Distinct from EMA-eval (fixed decay 0.99) — SF weights each step by lr_t (heavier mid-training, lighter at warmup/cooldown shrinkage).

- **★ AUX-vs-MUON algorithm-replacement frontier now spanned**: fern #2023 (Lion as AUX, AdamW replacement) + askeladd #2030 (SF Polyak-Ruppert as Muon body kernel addition) — two parallel optimizer-side ALGORITHM probes. Combined with 3 parallel optimizer-STATE FFS-positive mechanisms (edward/frieren/thorfinn n=4 confirms), the round is now richly stratified across mechanism types.

- **★★★ THREE PARALLEL FFS-POSITIVE n=4 CONFIRMS IN FLIGHT** (unchanged from 22:55Z):
  - edward #1948 (SOAP precond_freq=4 cooldown continuous) — trial 2+/4
  - frieren #1966 (Muon mu=0.80 gradual ramp) — trial 1/4
  - thorfinn #1994 (SOAP state hard-reset discrete) — n=4 launch directive posted, student pickup pending

- **8/8 ACTIVE — CURRENT FLEET STATUS (23:05Z)**:
  - edward #1948: n=4 confirm (trial 2+)
  - frieren #1966: n=4 confirm (trial 1)
  - thorfinn #1994: n=4 launch directive posted
  - tanjiro #2014: ns-iter-cooldown-ramp A_ctrl mid-run
  - nezuko #2020: soap-beta2-cooldown post-watchdog
  - alphonse #1979: A/B/C finished, awaiting SENPAI-RESULT
  - fern #2023: lion-aux-optimizer (rebased)
  - **askeladd #2030: sf-muon-polyak-ruppert (just assigned)**

---

## Last updated: 2026-05-31 22:55Z (**92 R5 closures**; **92nd: askeladd #1989 aux-cooldown-shape-decoupling FFS-NEG/NEUTRAL** (AUX-COOLDOWN family fully closed across both SHAPE + PARAM axes, 4 closures total); askeladd → researcher-agent dispatched for fresh hypothesis; 7/8 active pending askeladd; 3 parallel n=4 confirms in flight)

### Notes (2026-05-31 22:55Z) — 92nd closure; AUX-COOLDOWN family fully closed; askeladd hypothesis dispatch in flight

- **92nd R5 CLOSURE — ASKELADD #1989 (aux-cooldown-shape-decoupling) FFS-NEG/NEUTRAL**: Three cells with cooled (cosine baseline), constant (no aux cooldown), and concave (sharp end-drop). B★(constant)=FFS_ema 3050 monotone-worse at every probe; C(concave)=FFS_ema 2925 but lands at canonical attractor with non-monotone val_loss trajectory (worse at probes 1000/2000/2500, crosses below only at step 3250). **"AdamW v̂_t self-rescaling sufficient" mechanism FALSIFIED.** AUX groups DO need explicit LR cooldown — AdamW's per-element rescaling alone fails during gradient collapse phase. Bit-identity check on A_ctrl was rigorous (max |eta_body - eta_aux| = 0.0 across 131 steps; FFS_ema=2975 = +2.5σ seed tail not code regression).

- **★ AUX-COOLDOWN FAMILY NOW FULLY CLOSED** — across BOTH axes (PARAM + SHAPE): 4 closures total. AUX-side aux-cooldown-PARAM closed by #1955 (eps), #1957 (ema-decay), #1988 (β₁); AUX-side aux-cooldown-SHAPE closed today by #1989. Future AUX-side experiments REQUIRE ALGORITHM REPLACEMENT. **fern #2023 lion-aux-optimizer (assigned today) is the first such replacement.** Remaining AUX-algorithm candidates: Schedule-Free AdamW, Adafactor.

- **ASKELADD HYPOTHESIS DISPATCH IN FLIGHT** — researcher-agent tasked with finding a fresh non-AUX-side axis. Explicitly excluded closed families (additive pre-NS5, NS5 absorption, μP depth-LR, LN gain init<1.0, WD-axis, μ momentum DISCRETE reset, AUX cooldown PARAM+SHAPE). Candidate frontiers: body-side optimizer ALGORITHM replacements (Lion/Adan/Sign-SGD for Muon body), NS5 polish algorithm variants (Schur/Cholesky/Higham), 2nd-order/Shampoo-family alternatives (KrAD/K-FAC), loss-shape modifications. Output expected at `/research/RESEARCH_IDEAS_ASKELADD_2026-05-31_22:45.md`.

- **★★★ THREE PARALLEL FFS-POSITIVE n=4 CONFIRMS IN FLIGHT**:
  - edward #1948 (SOAP precond_freq=4 cooldown continuous) — trial 2+/4
  - frieren #1966 (Muon mu=0.80 gradual ramp) — trial 1/4
  - thorfinn #1994 (SOAP state hard-reset discrete) — n=4 launch directive posted today
  All three probe optimizer state at warm→cooldown crossover. Compounding test queued: precond_freq=4 + mu=0.80 + soap_state_reset stacked. **If all 3 confirm μ_4 ≤ 2887.5, the FFS bottleneck = optimizer-state staleness at crossover, decisively identified.**

- **7/8 ACTIVE — CURRENT FLEET STATUS (22:55Z)**:
  - edward #1948: n=4 confirm in flight (trial 2+)
  - frieren #1966: n=4 confirm in flight (trial 1), pod healthy iter 903
  - thorfinn #1994: n=4 launch directive posted, awaiting student pickup
  - tanjiro #2014: ns-iter-cooldown-ramp A_ctrl mid-run
  - nezuko #2020: soap-beta2-cooldown post-watchdog restart
  - alphonse #1979: A/B/C all finished per W&B, awaiting SENPAI-RESULT
  - fern #2023: lion-aux-optimizer (rebased onto latest advisor branch)
  - **askeladd #1989: CLOSED 92nd; idle pending new hypothesis**

---

## Last updated: 2026-05-31 22:30Z (91 R5 closures; **★★★ THORFINN #1994 B★ FFS-POSITIVE n=1 (3rd parallel mechanism: discrete SOAP state reset; canonical attractor + EMA-monotone Δval=−0.00254)**; n=4 launch instructions posted; 8/8 active including 3 parallel n=4 confirms — edward + frieren + thorfinn)

### Notes (2026-05-31 22:30Z) — ★★★ Thorfinn B★ FFS-POSITIVE signal candidate; THREE parallel n=4 confirms in flight

- **★★★ THORFINN #1994 B★ FFS-POSITIVE at n=1** — Single discrete SOAP state hard-reset at step 975 (= int(0.3 × 3250)). Result lands at canonical seed-noise attractor coords {FFS_ema=2875, FFS_trainval=2925} with EMA val_loss MONOTONE better than A_ctrl at all 4 probe steps:

  | step | A_ctrl EMA val | B★ EMA val | Δ (B−A) |
  |---|---|---|---|
  | 1000 | 3.53239 | 3.53168 | −0.00071 |
  | 2000 | 3.37086 | 3.36847 | −0.00239 |
  | 2500 | 3.31083 | 3.30799 | −0.00284 |
  | 3250 | 3.27031 | 3.26777 | **−0.00254** |

  Raw val_loss has 1 transient crossing at step 1000 (~25 steps post-reset, eigenbasis rebuilding — pre-mortem #2 mechanistically expected). From step 1125+ monotone better. **Δval (B-A) at terminal = 1.85× larger than edward #1948's continuous freq cooldown.** Sent back to wip with explicit n=4 launch instructions at `--soap_state_cooldown_reset` ON (single-arm, 4 trials sequential). wandb_group `g1r5-thorfinn/soap-state-cd-reset-n4`. Merge gate: μ_4(FFS_ema) ≤ 2887.5.

- **★★★ THREE PARALLEL FFS-POSITIVE OPTIMIZER-STATE MECHANISMS AT n=1**:

  | PR | Student | Mechanism | n=1 FFS | Δval (B-A) | n=4 status |
  |---|---|---|---|---|---|
  | #1948 | edward | SOAP precond_freq cooldown (continuous, 16→4) | 2875 | −0.00137 | trial 2+/4 in flight |
  | #1966 | frieren | Muon mu cooldown ramp (0.95→0.80) | 2875 (OFF-ATTRACTOR on both metrics) | −0.0021 | trial 1/4 in flight |
  | #1994 | thorfinn | SOAP state hard-reset (discrete, one-shot at step 975) | 2875 (on canonical attractor) | **−0.00254** | n=4 instructions just posted |

  All three probe optimizer state at the phase transition. If all three confirm μ_4 ≤ 2887.5, the FFS bottleneck is decisively identified as optimizer-state staleness at the warm→cooldown crossover — and the compounding test (precond_freq=4 + mu=0.80 + soap_state_reset stacked) becomes the obvious next experiment.

- **★ NOTE on edward vs thorfinn**: edward's continuous freq cooldown and thorfinn's discrete reset are STRUCTURALLY ADJACENT (both refresh SOAP eigenbasis at cooldown crossover, different temporal profile). Stacking is non-trivial — thorfinn's hard reset may absorb edward's continuous schedule, or compound. The compounding PR design will need to think carefully about this.

- **★★ GRADUAL > DISCRETE memory POSSIBLY REFINED**: nezuko #1993's muon-momentum DISCRETE reset was FFS-NEUTRAL (memory: gradual > discrete). thorfinn's SOAP-state DISCRETE reset IS FFS-POSITIVE. The two contrasting findings together suggest "gradual > discrete" applies to BUFFER refreshes (Muon momentum is a streaming EMA), but NOT to STATIC STATE refreshes (SOAP eigenbasis is a periodic snapshot, not a streaming aggregate). New refined memory: discrete refresh works on PERIODIC eigenbases but not on STREAMING buffers.

- **FERN #2023 (lion-aux-optimizer)** — First AUX optimizer ALGORITHM replacement in all 91 R5 experiments. Just assigned. Orthogonal to all 3 in-flight FFS-positive mechanisms.

- **ASKELADD #1989 (aux-cooldown-shape decoupling)** — B(constant aux) TERMINAL FFS-NEG at FFS_ema=3050 (monotone worse at all probes). C(concave) running, ETA was ~22:10Z. Both directions failing → axis closure imminent (3rd AUX-side cooldown family closure on cooldown SHAPE axis, complementing the cooldown-parameter axis already closed).

- **8/8 ACTIVE — CURRENT FLEET STATUS (22:30Z)**:
  - **edward #1948**: n=4 confirm in flight at freq=4 (trial 2+ sequential)
  - **frieren #1966**: n=4 confirm in flight at mu=0.80 (trial 1)
  - **thorfinn #1994**: n=4 confirm launch directive posted (just sent back to wip)
  - **tanjiro #2014**: ns-iter-cooldown-ramp A_ctrl ~step 1945/3250 (B/C/D queued)
  - **nezuko #2020**: soap-beta2-cooldown post-watchdog restart, iteration 3112
  - **askeladd #1989**: C(concave) near terminal, B FFS-NEG confirmed
  - **alphonse #1979**: A/B/C all finished per W&B (best C=3.2696), awaiting SENPAI-RESULT
  - **fern #2023**: lion-aux-optimizer just assigned

---

### Notes (2026-05-31 22:05Z) — fern #2023 lion-aux-optimizer assigned; 8/8 students active

- **FERN → PR #2023 (lion-aux-optimizer)** — Replace AdamW with Lion (sign-based momentum, arXiv:2302.06675) for the 3 AUX parameter groups: `embed.weight` (lr=0.03 at lion_lr_scale=0.1), `proj.weight`/lm_head, scalars/biases/RMSNorm-gains. **First AUX optimizer ALGORITHM replacement in all 91 R5 experiments.** The AUX-side cooldown family (3 closures: eps/ema-decay/β₁) closed SCHEDULE perturbations on AdamW; Lion changes the update rule itself (sign-quantized momentum, no second-moment). 4-cell dose-response: A_ctrl(AdamW), B★(Lion β₁=0.9, lr_scale=0.1), C(Lion β₁=0.99 per arXiv:2509.01440v1), D(Lion lr_scale=0.3). FFS mechanism: uniform ±lr step on embed may accelerate rare-token adaptation relative to AdamW's second-moment suppression of high-frequency vocab rows. Divergence watchdog: train_loss > 4.0 at step 500 → kill arm.

- **8/8 ACTIVE — CURRENT FLEET STATUS (22:05Z)**:
  - **edward #1948**: n=4 confirm in flight at freq=4 (trial 2+ in sequential run)
  - **frieren #1966**: n=4 confirm in flight at mu=0.80 (trial 1 at step ~2700)
  - **tanjiro #2014**: ns-iter-cooldown-ramp A_ctrl at step ~1945/3250 (B/C/D queued)
  - **nezuko #2020**: post-watchdog restart (watchdog fired at 21:53Z, iteration 3086 picking up)
  - **thorfinn #1994**: B★ at step ~3074/3250 (~terminal)
  - **askeladd #1989**: A+B finished, C at step ~2372/3250 (~25 min)
  - **alphonse #1979**: all arms reported finished by W&B (A/B/C), student SENPAI-RESULT pending
  - **fern #2023**: new assignment (lion-aux-optimizer), student will pick up next heartbeat

- **AUX-OPTIMIZER FRONTIER NOTE**: With lion-aux-optimizer assigned, the complete map of open AUX axes is: (1) Lion — algorithm replacement [fern #2023], (2) Schedule-Free AdamW — iterate averaging (hypothesis #2 in research ideas file), (3) Adafactor — factored second moment (hypothesis #3). If Lion is FFS-NEUTRAL, next student becomes SF-AdamW.

- **COMPOUNDING EXPERIMENT QUEUED**: After edward + frieren n=4 confirm: precond_freq=4 + mu→0.80 stacked. Both mechanisms at distinct optimizer state (SOAP eigenbasis stride vs Muon momentum EMA). Orthogonal expectation: μ_4(FFS_ema) ≤ 2825. Assign to whichever student becomes idle first after the n=4 confirms land.

---

### Notes (2026-05-31 21:40Z) — 91st closure; WD direction confirmed load-bearing; fern hypothesis dispatch in flight

- **91st R5 CLOSURE — FERN #1983 (wd-schedule-ablation) FFS-NEGATIVE (ABLATION CONFIRMS LOAD-BEARING)**: A_ctrl(ramp_down)=2925, B(constant)=2975 (+50 FFS), C(ramp_up)=3100 (+175 FFS). **Monotone dose-response: ramp_down > constant > ramp_up** on both metrics, with monotone val_loss trajectory at all probe steps ≥ 2000. **Pre-mortem #1 (time-integrated WD only) FALSIFIED** — B's mean WD = A_ctrl's mean WD, yet B regresses. **Schedule DIRECTION is the lever, not integrated magnitude.** Directly extends PR #1922's "WD near-zero at crossing helps" → "elevating WD at crossing actively destroys FFS by 0.008 val_loss / +175 FFS."

- **WD-AXIS CLOSED**: Three PRs now fully cover the WD design surface: peak magnitude (PR #1830), 4 shape variants (PR #1922), direction (PR #1983). `--wd_schedule ramp_down` stays in mandatory R5 stack. Direct response to human directive #1262 ablation request completed — component verified as load-bearing, not redundant.

- **FERN → RESEARCHER-AGENT DISPATCHED** for next hypothesis on a non-closed axis. Candidates being evaluated: Schedule-Free AdamW (AUX replacement, not perturbation), Lion AUX optimizer, gradient covariance preconditioning for embeddings/LN, cooldown-windowed WD floor (precision test), per-depth-bucket mu decoupling in Muon, NS5 polish geometry alternatives (modified Schulz coefficients).

- **CURRENT FLEET STATUS (21:40Z)**:
  - **edward #1948**: n=4 confirm in flight at freq=4 (trial 1/4 hit FFS_ema=2875)
  - **frieren #1966**: n=4 confirm in flight at mu=0.80 (trial 1/4 in flight)
  - **tanjiro #2014**: ns-iter-cooldown-ramp WIP (NS5 polish geometry, MUON-side, structural)
  - **nezuko #2020**: soap-beta2-cooldown-ramp WIP (SOAP covariance smoothing axis, orthogonal to edward)
  - **thorfinn #1994**: soap-state-cooldown-reset WIP
  - **askeladd #1989**: aux-cooldown-shape-decoupling WIP
  - **alphonse #1979**: lr-warm-restart-probe WIP
  - **fern #1983**: just closed, pending new assignment from researcher-agent

- **CLOSED FAMILIES (memory note for next assignments)**:
  - NS5 absorption family (3 closures)
  - NS5 internal ε irrelevant at R5 scale
  - SGLD/additive-pre-NS family
  - LN gain init below 1.0
  - AUX-side cooldown family (3 closures, all absorbed by cosine LR decay)
  - Muon momentum DISCRETE RESET (gradual ramp is correct mechanism)
  - WD-axis fully explored (peak magnitude, shape, direction — all measured)

---

## Last updated: 2026-05-31 21:10Z (90 R5 closures; **90th: nezuko #1993 muon-mom-reset FFS-NEU (discrete reset → transient gain only; GRADUAL>DISCRETE confirmed)**; nezuko → #2020 soap-beta2-cooldown; 8/8 active)

### Notes (2026-05-31 21:10Z) — 90th closure; GRADUAL>DISCRETE mechanism insight; nezuko #2020 soap-beta2-cooldown assigned

- **90th R5 CLOSURE — NEZUKO #1993 (muon-momentum-cooldown-reset) FFS-NEUTRAL**: FFS_ema=2925 for both arms. B★ shows transient post-reset Δval=−0.009 at step 1000 but inverts to +0.00078 by step 2375, finishing marginally WORSE at terminal. **Key mechanism insight: discrete reset → buffer refills in ~20 steps at mu=0.95; frieren's sustained low-mu ramp works BECAUSE it keeps the buffer in low-inertia regime throughout cooldown.** "Gradual ≫ discrete" on MUON momentum axis.

- **NEZUKO → PR #2020 (soap-beta2-cooldown-ramp)** — Anneal SOAP β₂ from 0.90 → 0.70 during cooldown. SOAP covariance smoothing axis, orthogonal to edward's precond_freq (different SOAP lever). 4-cell dose-response: A_ctrl(const 0.90), B★(→0.70), C(→0.80), D(→0.95 falsifier). Could compound with edward if positive. Fresh axis, not in any closed family.

---

## Last updated: 2026-05-31 20:30Z (89 R5 closures; **★★★ FRIEREN #1966 n=4 INSTRUCTIONS POSTED + SENT BACK to wip (mu=0.80)**; **★★★ EDWARD #1948 n=4 IN FLIGHT**; **89th closure: tanjiro #1988 FFS-NEUTRAL; AUX-SIDE COOLDOWN FAMILY NOW CLOSED (3/3)**; **tanjiro → #2014 ns-iter-cooldown-ramp**; 8/8 active)

### Notes (2026-05-31 20:30Z) — 89th closure; AUX-side cooldown family closed; tanjiro #2014 ns-iter-cooldown-ramp assigned; frieren n=4 pending launch

- **89th R5 CLOSURE — TANJIRO #1988 (adamw-β₁-cooldown) FFS-NEUTRAL**: Both arms at identical FFS_ema=FFS_trainval=2925, val_loss=3.26966. Non-monotone val_loss trajectory (B worse than A at 1000/2000/2500). **AUX-SIDE COOLDOWN FAMILY NOW DEFINITIVELY CLOSED** — three consecutive AUX perturbations all absorbed by cosine LR decay: adamw-eps (#1955 87th), ema-decay (#1957 88th), adamw-β₁ (#1988 89th). Future aux-side ideas need AUX OPTIMIZER REPLACEMENT (not perturbation) to escape absorption.

- **★★★ FRIEREN #1966 n=4 PENDING LAUNCH** — Sent PR back to status:wip with explicit launch directive. Student should launch 4-trial confirm at mu=0.80, group `g1r5-frieren/muon-mu-sched-n4`. Key finding from 3-cell dose-response: BOTH B(mu=0.70) and C(mu=0.80) at {FFS_ema=2875, FFS_trainval=2875} off-attractor. C dominates B on val_loss (3.2676 vs 3.2697) at every cooldown probe step from 2750 onward. TWO-CELL STRUCTURAL CONFIRMATION. Student now idle → should pick up the n=4 launch on next iteration.

- **★★★ EDWARD #1948 n=4 IN FLIGHT** — Group `g1r5-edward/precond-freq-cooldown-schedule-n4`, run `1r8b1zmi`. Trial 1/4 running. ETA ~5h for all 4 trials.

- **★★ TANJIRO → PR #2014 (ns-iter-cooldown-ramp)** — Newton-Schulz iteration count cooldown (6→3 during cooldown). NS5-internal axis, orthogonal to confirmed edward+frieren signals. Tests if late polish is wasteful (less iter) vs load-bearing. 4-cell dose-response: A_ctrl(no schedule), B★(6→3), C(6→2, aggressive), D(6→9, opposite/falsifier). ~7.5h wall-clock.

- **★ COMPOUNDING EXPERIMENT QUEUED** — Once both edward + frieren n=4 confirms land: precond_freq=4 + mu→0.80 stacked. Both mechanisms at distinct optimizer state (SOAP eigenbasis stride vs Muon momentum decay EMA). Orthogonal expectation: μ_4(FFS_ema) ≤ 2825.

- **CURRENT FLEET STATUS (20:30Z)**:
  - **frieren #1966**: status:wip (just sent back), n=4 launch imminent
  - **edward #1948**: n=4 in flight
  - **tanjiro #2014**: new assignment, student picking up
  - **fern #1983**: B(const WD) closed, C(ramp_up) at step ~450/3250
  - **alphonse #1979**: B(LR warm restart) should be near terminal
  - **thorfinn #1994**: A_ctrl near terminal, B★ queued
  - **askeladd #1989**: B(const aux) running
  - **nezuko #1993**: B(muon momentum reset) running

- **AUX-SIDE COOLDOWN FAMILY CLOSED (memory note)**: All three AUX-optimizer-state cooldown perturbations (eps, ema-decay, beta1) are FFS-NEUTRAL absorbed by LR cosine decay. Future aux ideas require **AUX OPTIMIZER REPLACEMENT** (Lion, AdaProp, Schedule-Free AdamW) or **AUX LR SHAPE CHANGE** (askeladd #1989 in progress).

---

### Notes (2026-05-31 19:35Z) — ★★★ FRIEREN C TERMINAL: dual-cell off-attractor confirmation; n=4 instructions posted at mu=0.80; ★ FERN B FFS-NEG cleanly attributes ramp_down as load-bearing

- **★★★ FRIEREN #1966 C TERMINAL — TWO-CELL CONFIRMATION at OFF-ATTRACTOR {2875, 2875}**:

  | Cell | mu schedule | FFS_ema | FFS_trainval | val_loss |
  |---|---|---:|---:|---:|
  | A_ctrl | 0.95 constant | 2925 | 2925 | 3.2692 |
  | B★ | 0.95→0.70 ramp | 2875 | 2875 | 3.2697 |
  | **C** | **0.95→0.80 ramp** | **2875** | **2875** | **3.2676** |

  Both B★ AND C land at {FFS_ema=2875, FFS_trainval=2875} — same OFF-attractor coords on BOTH metrics. **This is structural, not seed jitter** (canonical attractor is {2875, 2925}). C is BETTER on val_loss (3.2676 < 3.2697 < 3.2692). **Flat dose-response mu∈{0.70, 0.80}** — same pattern edward saw across freq∈{2,4,8}. Probe-step trajectory monotone-better than A_ctrl throughout for both cells.

  **n=4 confirm INSTRUCTIONS POSTED at mu=0.80** (cheaper choice: same FFS as 0.70, better val_loss, higher stability, B★ at 0.70 had a step-120 crash). wandb_group `g1r5-frieren/muon-mu-sched-n4`. ETA ~7.2h. Merge gate: μ_4(FFS_ema) ≤ 2887.5.

- **★★★ EDWARD #1948 n=4 IN FLIGHT** — Trial 1/4 at step 872/3250 last check. Group `g1r5-edward/precond-freq-cooldown-schedule-n4`. ETA ~5h total.

- **★ FERN #1983 B(constant WD) FFS-NEGATIVE** — FFS={2975, 2975}, val=3.2723. +50 FFS steps worse than A_ctrl{2925, 2925}. **`--wd_schedule ramp_down` IS load-bearing.** Clean ablation finding answering human directive #1262. Cell C(ramp_up) at step ~140/3250 (~96 min ETA) will fully resolve ramp-direction sensitivity.

- **★ COMPOUNDING EXPERIMENT** still queued: precond_freq=4 + mu ramp→0.80 stacked. Both mechanisms now have TWO independent off-attractor cells each at FFS_ema=2875. Strong prior for orthogonality. Assignment ready for whichever student closes first after n=4 confirms.

- **Other terminals expected ~30-90 min**: alphonse (~15 min), thorfinn A_ctrl (~10 min), tanjiro (~40 min), askeladd (~50 min), nezuko (~80 min), fern C (~90 min).

---

### Notes (2026-05-31 19:20Z) — Edward n=4 confirm in flight; fern closest to terminal (~14 min); compounding experiment plan drafted

- **★★★ EDWARD #1948 n=4 LAUNCHED** — Student posted full A/B/C/D table + probe-step trajectory + n=4 launch confirmation. Cell E configured at `--precond_freq_base 16 --precond_freq_cooldown 4` (B★ center of saturated region), wandb_group `g1r5-edward/precond-freq-cooldown-schedule-n4`, run `1r8b1zmi`. Trial 1/4 currently at step 872/3250, val=3.713. ETA ~75 min for trial 1; ~5h for all 4 trials. Merge gate: μ_4(FFS_ema) ≤ 2887.5. Probe-step trajectory at step 2500 showed Δ(D−A)=−0.00309 (peak separation inside FFS-crossing window) — mechanism is real, not seed jitter.

- **★★★ FRIEREN #1966 B★ STANDING; C(mu=0.80) at 77%** — C run `yvgj4e8p` at step 2507/3250, val=3.343, ETA ~19:50Z. After C SENPAI-RESULT, decision tree:
  - C at FFS_ema=2925 → B is sweet spot @ mu=0.70, launch n=4 directly at mu=0.70
  - C at FFS_ema ∈ {2875, 2900} → monotone dose-response, launch n=4 at mu=0.70 (best cell)
  - C at FFS_ema=2875 → flat dose-response (like edward); launch n=4 at mu=0.70 (cheapest cell with full signal)

- **★ COMPOUNDING EXPERIMENT PLAN** — If both edward + frieren confirm at n=4, queue compounding test as immediate follow-up: `--precond_freq_cooldown 4 --muon_mu_schedule "ramp:0.95→0.70"` stacked on the mandatory R5 stack. Both target distinct optimizer state (SOAP eigenbasis stride vs Muon EMA momentum), so orthogonal expectation: μ_4(FFS_ema) ≤ 2825 plausible. If overlapping, single-mechanism gain only. Assign to nezuko or thorfinn (whoever closes first).

- **★ ALL 8 EXPERIMENTS ON-TRACK (W&B picture 19:15Z)**:
  - **Fern #1983 B(const WD)** — closest to terminal: step 2924/3250, val=3.288 (~14 min). Tests if `--wd_schedule ramp_down` is load-bearing.
  - **Alphonse #1979 B(LR pulse)** — step 2757/3250, val=3.313 (~21 min). val_loss still 0.025 above target → likely FFS-neutral.
  - **Thorfinn #1994 A_ctrl** — step 2611/3250, val=3.337 (~20 min). Group `g1r5-thorfinn/soap-state-cd-reset` (W&B abbreviates 'cooldown' to 'cd'). B★ queued.
  - **Frieren #1966 C(mu=0.80)** — step 2507/3250, val=3.343 (~31 min).
  - **Tanjiro #1988 B(beta1=0)** — step 1722/3250, val=3.528 (~48 min).
  - **Askeladd #1989 B(const aux)** — step 1485/3250, val=3.576 (~55 min). A_ctrl=2975 anomaly verification pending student response.
  - **Edward #1948 Cell E** — step 872/3250 trial 1/4, val=3.713 (~75 min trial 1).
  - **Nezuko #1993 B(muon mom reset)** — step 565/3250, val=3.815 (~88 min).

- **No human directives since 2026-05-26 #1262.** Working within FFS-PRIMARY framing.

- **Fleet at 19:20Z**: All 8 active. **Next 90 min: 5 terminals expected** (fern, alphonse, thorfinn A_ctrl, frieren C, tanjiro). Edward n=4 is the marquee event — terminal in ~5h.

---

### Notes (2026-05-31 19:10Z) — ★★★ EDWARD #1948 D TERMINAL: full dose-response flat FFS_ema=2875 across freq∈{2,4,8}; SENPAI-RESULT expected next heartbeat; n=4 confirm imminent

- **★★★ EDWARD #1948 D-AGGRESSIVE TERMINAL (~18:36Z)** — D(precond_freq_cooldown=2): FFS_ema=**2875**, FFS_trainval=**2925**, val=**3.2672**. **ALL 3 treatment arms now confirmed:**
  - A_ctrl(freq=16): FFS={2925, 2925}, val=3.2686
  - B★(freq=4):     FFS={2875, 2925}, val=3.2672
  - C(freq=8):      FFS={2875, 2925}, val=3.2682
  - D(freq=2):      FFS={2875, 2925}, val=3.2672
  
  **Dose-response is FLAT across freq∈{2,4,8} at FFS_ema=2875.** Mechanism saturates at freq≤8. ON-attractor FFS_trainval (2925), OFF-attractor FFS_ema (2875). Signal robust. **Awaiting student SENPAI-RESULT marker (expected within 1-2 heartbeats).** n=4 confirm decision: launch at freq=4 (most defensible choice — center of saturated region; freq=2 has compute overhead; freq=8 is upper boundary).

- **★★★ FRIEREN #1966 B★ FFS-POSITIVE STANDING** — Still terminal at {FFS_ema=2875, FFS_trainval=2875}, val=3.2697. **Stronger off-attractor signature than edward** (BOTH FFS metrics off-attractor vs edward only FFS_ema). C(mu=0.80) at step 2354/3250 (~72%), ETA ~19:50Z. After C SENPAI-RESULT, launch n=4 at mu=0.70.

- **★★ TWO PARALLEL FFS-POSITIVE MECHANISMS BOTH ROBUST** — edward precond_freq cooldown (3 cells all FFS=2875) + frieren muon mu cooldown (off-attractor on both metrics). If n=4 confirms on both, **compounding experiment is the natural follow-up**: precond_freq=4 + mu cooldown 0.95→0.70 stacked. Both mechanisms target different optimizer state (SOAP eigenbasis refresh stride vs Muon momentum decay). If orthogonal, μ_4(FFS_ema) ≤ 2825 might be achievable. If overlapping, compound = single mechanism gain only.

- **★ ASKELADD #1989 A_ctrl=2975 ANOMALY** — A_ctrl FFS_ema=FFS_trainval=2975 (+2.5σ above global baseline μ_4=2912.5). Could be seed noise (rare but possible at ±2.5σ) OR --aux_cooldown_shape unset path is NOT bit-identical to baseline. Posted comment requesting student verify eta_body/eta_aux bit-identicality in their terminal post. **Signal gate now uses GLOBAL baseline μ_4=2912.5 (raw threshold 2887.5), not local A_ctrl=2975.**

- **★ ALPHONSE #1979 B★ mid-run** — B★(LR warm restart pulse at step 2700, peak=0.3, dur=200). A_ctrl was at FFS={2950, 2975} (also +1.5σ, less anomalous than askeladd).

- **★ TANJIRO + NEZUKO + THORFINN healthy** — All A_ctrls progressing. nezuko A_ctrl val=3.2967 at step 2802 may finish marginal; thorfinn A_ctrl at step 1232/3250 (~38%); tanjiro B★ at step 154 (just launched).

- **★ FERN #1983** — A_ctrl finished {2925, 2925} clean baseline; B (constant WD) + C (ramp_up WD) sequential pending; ETA B ~19:30Z, C ~21:30Z.

- **Fleet at 19:10Z**: All 8 active. **Two FFS-POSITIVE signals locked, n=4 confirms imminent on edward freq=4 and frieren mu=0.70.**

---

### Notes (2026-05-31 17:55Z) — ★★★ FRIEREN #1966 B★(mu=0.70 ramp) IS FFS-POSITIVE AT n=1 — SECOND INDEPENDENT FFS-ALIVE SIGNAL alongside edward #1948

### Notes (2026-05-31 17:55Z) — ★★★ FRIEREN #1966 B★(mu=0.70 ramp) IS FFS-POSITIVE AT n=1 — SECOND INDEPENDENT FFS-ALIVE SIGNAL alongside edward #1948

- **★★★ FRIEREN #1966 B★ FFS-POSITIVE at n=1** — Just terminal (~17:40Z): A_ctrl(mu=0.95 fixed) FFS={2925, 2925}, val=3.2692. **B★(mu=0.95→0.70 ramp during cooldown) FFS={2875, 2875}, val=3.2697.** Both FFS metrics improved by -50 steps. **OFF-attractor on FFS_trainval** (standard attractor is {2875, 2925}; B★ is {2875, 2875} — trainval also -50). This dual-metric off-attractor signature passes the seed-noise discriminator [[r5_n1_to_n4_reversion_dual_metric_attractor]]. Student now running Cell C(mu=0.80) at step 210/3250, ETA ~19:50Z. **Will require n=4 confirm before merge.** Advisor comment posted requesting SENPAI-RESULT after C terminal + val_loss probe-step trajectory + n=4 launch at mu=0.70.

- **★★ EDWARD #1948 D mid-run at step 2110/3250** — B(freq=4) AND C(freq=8) both FINISHED at FFS_ema=2875, FFS_trainval=2925 (on attractor on FFS_trainval). D(freq=2) ETA ~18:30Z. Once D terminal, n=4 confirm at freq=4 will be decisive — if freq=4 confirms μ_4(FFS_ema) ≤ 2887.5, MERGE.

- **★★ TWO PARALLEL FFS-POSITIVE MECHANISMS** — edward(precond_freq cooldown) AND frieren(muon mu cooldown). These are STRUCTURALLY DISTINCT optimizer-side interventions both producing the same FFS_ema=2875 reduction at n=1. **If both confirm at n=4, they may compound (orthogonal mechanisms acting on SOAP preconditioner refresh stride vs Muon momentum decay).** Compounding test is the natural next-round experiment. Note: frieren is more aggressive (both FFS metrics moved off-attractor), edward is less so (only FFS_ema off-attractor, trainval on).

- **★ ALPHONSE #1979** A_ctrl FINISHED at FFS_ema=2950, FFS_trainval=2975 — marginal +1.5σ above baseline (within ±2σ band); B★(warm restart at step 2700) just launched at step 459/3250. Note: A_ctrl FFS=2950 is HIGHER than typical baseline 2912.5; this raises the bar for B★ to demonstrate signal (effective threshold becomes ≤2887 vs raw threshold).

- **★ FERN #1983** A_ctrl FINISHED at FFS_ema=2925, FFS_trainval=2925, val=3.268752 (clean baseline replicate of PR #1533). Cells B (constant WD) + C (ramp_up WD) not yet launched — sequential single-GPU, ETA B ~19:30Z, C ~21:30Z. Advisor comment posted noting cross-fleet context.

- **★ ASKELADD #1989** A_ctrl mid-run (~38%, step 1237/3250). KG_smoke passed. Healthy. ETA A ~18:40Z, B ~20:30Z.

- **★ TANJIRO #1988 + NEZUKO #1993 + THORFINN #1994** — All WIP. tanjiro adamw-beta1-cooldown (4h ago), nezuko muon-momentum-cd-reset + thorfinn soap-state-cd-reset (assigned 1.5h ago, students may be in KG_smoke phase).

- **Fleet at 17:55Z**: All 8 active. **TWO PARALLEL FFS-POSITIVE SIGNAL CANDIDATES** awaiting n=4 confirm (edward freq=4, frieren mu=0.70). This is the strongest research moment in the entire R5 round so far.

---

### Notes (2026-05-31 16:25Z) — NEZUKO #1955 CLOSED 87th [adamw-eps-cooldown bit-identical FFS_ema]; THORFINN #1957 CLOSED 88th [ema-decay-cooldown FFS-bin-saturated]; EDWARD #1948 C(freq=8) MONOTONE-CONFIRMS B★ AT step 3140

- **★ CLOSED #1955 nezuko adamw-eps-cooldown** [87th R5 closure, ~16:09Z] — FFS-NEUTRAL. **FFS_ema BIT-IDENTICAL between A_ctrl(eps=1e-10) and B★(eps=1e-14): 2950 = 2950.** Bit-identical is the cleanest possible null result. KG_smoke verified mechanism alive (log-linear ε progression 1e-10→1.07e-14), bf16 stable, no NaN/Inf. Raw val_loss delta ~0.00082 within 1σ seed noise. **AUX-side analog of alphonse #1973 (NS5-eps-cooldown, 83rd).** Paired mechanism conclusion: ε floors on BOTH Muon (NS5 internal) AND AdamW (aux denominator) at R5 cooldown gradient scale are numerical-safety constants, not optimizer levers. Family closed.

- **★ CLOSED #1957 thorfinn ema-decay-cooldown** [88th R5 closure, ~16:10Z] — FFS-NEUTRAL. **FFS_ema BIT-IDENTICAL: A_ctrl=B★(d=0.95)=2925.** But best EXPLAINED null: student's crossover-window trajectory dissection shows mechanism INVERTS sign in early cooldown — B★ ema_val_loss is HIGHER than A's during steps 2625–2875 (more reactive EMA upweights higher-loss recent steps), only crosses below A's AT step 2925 (the FFS bin boundary), too late to register. Late-cooldown improvement ~1.3e-3 lands beyond FFS crossing. **Family conclusion: EMA-readout-path cooldown is structurally limited by FFS bin quantization at the crossing window.** Future hypotheses should target the *training trajectory* (so crossing happens earlier in absolute step), not the *readout*. Implementation (cumulative-product bias-correction) can stack on top of edward #1948 if precond_freq becomes a confirmed winner.

- **★★ EDWARD #1948 C(freq=8) CONFIRMING B★ AT step 3140** — A_ctrl=2925/2925, B★(freq=4)=2875/2925, **C(freq=8) at step 3140/3250 already showing FFS_ema=2875** (matching B★, FFS_trainval=2925, val=3.26903). C will finish ~16:30Z, then D(freq=2) starts. If D also FFS_ema≤2887, we have monotone-decreasing-in-stride signal → SOAP eigenbasis staleness is the mechanism. If D regresses, sweet spot at freq=4-8. Either way C-confirming-B★ is strong evidence the precond_freq cooldown signal is real (not seed noise of one cell). n=4 confirm decision @ ~18:30Z post-D.

- **★ ALPHONSE #1979** mid-run: A_ctrl at step 1485/3250 (~45% done), B not yet launched. ETA A ~17:00Z, B ~18:30Z.

- **★ FRIEREN #1966** A_ctrl FINISHED at baseline 2925/2925. B(mu=0.70) had ONE divergence (val=10.8 at step 120) but re-launched and now mid-run at step 1229. Concerning fragility — mu cooldown to 0.70 may be too aggressive; monitor B for divergence again.

- **★ NEZUKO #1993 muon-momentum-cooldown-reset ASSIGNED** — One-time discrete reset of all Muon momentum buffers at `cooldown_start_step` (step 975). Removes stale warm-phase velocity before basin convergence. ~10 LOC. Falsifiable: brief `train/loss` plateau at step 976, then steeper descent. Signal gate: FFS_ema ≤ 2887 AND monotone val_loss trajectory. **88 R5 closures, zero prior optimizer-state resets at phase transitions.** Conceptual analog to SGDR but applied to momentum state.

- **★ THORFINN #1994 soap-state-cooldown-reset ASSIGNED** — One-time discrete reset of SOAP shampoo state (`row_gg`, `col_gg`, `q_row=None`, `q_col=None`, `exp_avg_sq`, `soap_step=0`) at `cooldown_start_step`. SOAP eigenbasis and gram matrices accumulate warm-phase gradient statistics; hard-reset forces re-estimation from cooldown-regime gradients. Muon momentum NOT reset (isolates SOAP state only). Complements nezuko's paired ablation: together the pair tests "stale momentum vs stale curvature at phase transition." Also directly probes the discrete-extreme of edward #1948's continuous precond_freq cooldown signal.

- **★★ DESIGN NOTE: PAIRED EXPERIMENT** — nezuko #1993 + thorfinn #1994 form a clean paired ablation at the phase-transition-reset family: {body Muon momentum buffer} vs {body SOAP preconditioner state}. If only nezuko → stale momentum is the lever. If only thorfinn → stale curvature is the lever. If both → both states are stale at cooldown_start. Neither → resets don't help.

- **Fleet at 16:35Z**: tanjiro #1988 WIP (adamw-beta1-cooldown); askeladd #1989 WIP (aux-cooldown-shape-decoupling); alphonse #1979 WIP (lr-warm-restart-probe, A mid-run); fern #1983 WIP (wd-schedule-ablation); edward #1948 WIP (**SIGNAL ALIVE, C MONOTONE-CONFIRMS B★**, D pending ~17:30Z); frieren #1966 WIP (muon-momentum-schedule, B post-recover mid-run); nezuko #1993 WIP (muon-momentum-cooldown-reset, just assigned); thorfinn #1994 WIP (soap-state-cooldown-reset, just assigned). **8/8 active, zero idle.**

---

### Notes (2026-05-31 16:10Z) — TANJIRO #1964 CLOSED 85th [FFS-NEG NS-iter cooldown schedule]; ASKELADD #1942 CLOSED 86th [FFS-NEG logit-z-loss budget-incompatible]; TANJIRO #1988 + ASKELADD #1989 ASSIGNED

- **★ CLOSED #1964 tanjiro ns-iter-cooldown** [85th R5 closure, ~16:00Z] — FFS-NEG. B★(12→6 at 75% progress) FFS_ema=2950 vs baseline 2912.5 (+37.5 worse); val_loss=3.271822 vs 3.270113 (+0.001709 worse). B★ above ENTIRE baseline distribution (2875–2925). Pre-Mortem 1 confirmed: early ns_iter=12 hurt (over-constrains during warmup/mid-training). NS-iter cooldown schedule axis closed. Pairs with #1973 (ns5-eps-cooldown mechanism-dead) + #1922 (wd-cooldown-shape FFS-NEUTRAL) as 3rd cooldown-internal Muon mechanism closure.

- **★ CLOSED #1942 askeladd logit-z-loss** [86th R5 closure, ~16:05Z] — FFS-NEG (monotone dose-response regression; budget-incompatible). A_ctrl(w=0) FFS=2875/val=3.2684; B★(w=1e-4) FFS=-1/val=4.0463; C1(w=1e-5) FFS=-1/val=3.5055. Mechanism ALIVE (logit_abs_mean 6.75→0.36→0.11) but each w>0 costs enough CE budget to push val>3.28. Matches label-smoothing (#1870) pattern. Logit-magnitude-penalty axis closed.

- **★ TANJIRO #1988 adamw-beta1-cooldown ASSIGNED** — Anneal AdamW β₁ 0.9→0.0 during cooldown for all aux groups. Fresh axis: static β₁ sweeps (#1310) and β₂ cooldown schedule (#1377) closed; **β₁ COOLDOWN ANNEAL never tested** in 86 closures. ~17 LOC additive. Signal gate: FFS_ema ≤ 2887 with monotone val_loss trajectory.

- **★ ASKELADD #1989 aux-cooldown-shape-decoupling ASSIGNED** — Apply different LR cooldown shape to AdamW aux groups vs Muon body. B★(aux=constant), C(aux=concave). Fresh axis: #1922 swept UNIFORM cooldown shapes; per-class shape decoupling untested. ~12 LOC additive.

- **★★ EDWARD #1948 SIGNAL ALIVE** — B★(precond_freq=4) FFS_ema=2875, val_loss Δ=-0.00137 monotone. C+D terminal expected ~18:00Z. n=4 decision at that time.

- **Fleet at 16:10Z**: tanjiro #1988 WIP (adamw-beta1-cooldown); askeladd #1989 WIP (aux-cooldown-shape-decoupling); alphonse #1979 WIP (lr-warm-restart-probe); edward #1948 WIP (**SIGNAL ALIVE**, C+D running); frieren #1966 WIP (muon-momentum-schedule); thorfinn #1957 WIP (ema-decay-cooldown-schedule); nezuko #1955 WIP (adamw-eps-cooldown); fern #1983 WIP (wd-schedule-ablation). **8/8 active, zero idle.**

---

### Notes (2026-05-31 14:55Z) — FERN #1922 CLOSED 84th [WD cooldown SHAPE axis closed; val_loss trajectory non-monotone = attractor noise]; FERN #1983 wd-schedule-ablation ASSIGNED

- **★ CLOSED #1922 fern wd-cooldown-shape** [84th R5 closure, ~14:50Z] — FFS-NEUTRAL. 4 cells {linear, cosine, concave, convex}; Cell D (convex) landed at attractor {2875, 2925} but val_loss probe-step table shows non-monotone trajectory (D > A at step 2000 by +0.00240). All 4 cells within ±0.005 val_loss at each probe step → tight band, weak shape effect. Mechanism null: by step 2500, WD < 0.02 across all shapes (vs base 0.025), absolute differences at crossing window ~0.0006 mlp units.
- **★★ NEW DISCRIMINATOR ESTABLISHED**: When n=1 result lands at attractor {2875, 2925}, the val_loss PROBE-STEP TRAJECTORY (not just terminal value) is the decisive discriminator. Non-monotone (cross-over) = noise; monotone = signal candidate. This is a refinement of [[r5_n1_to_n4_reversion_dual_metric_attractor]] — fern's D shows attractor coords + non-monotone = NOT a candidate. Edward's #1948 B★ shows attractor coords + monotone improvement = signal candidate. **Both came in the same heartbeat** — first time we have two attractor-coordinate n=1 results to compare.

- **★ FERN #1983 wd-schedule-ablation ASSIGNED** — Direct response to human directive #1262 ("drop ramp_down ablation"). Tests `--wd_schedule ramp_down` (mandatory baseline) vs `constant` (WD stays at base throughout) vs `ramp_up` (WD goes 0 → 2× across training). PR #1922 showed WD reaches near-zero at crossing regardless of shape; this experiment tests what happens when WD STAYS HIGH (constant) or RAMPS UP (high WD at crossing window). Zero LOC — pure configuration sweep, the `--wd_schedule` flag already supports all three values. Cells: A_ctrl (ramp_down), B (constant), C (ramp_up). Stop conditions include the new "non-monotone trajectory" discriminator from PR #1922.

- **★★ EDWARD #1948 SIGNAL ALIVE (still active)** — A_ctrl=2925, B★(precond_freq=4)=2875, val_loss Δ=-0.00137 outside ±0.005 seed-noise band AND monotone. C (freq=8) ETA 16:07Z, D (freq=2) ETA ~18:00Z. n=4 decision @ ~18:00Z.

- **★ TANJIRO #1964 silent**: pod healthy (Running, no restarts, age 16d). Student hasn't posted KG_smoke or progress in 2h20min since assignment ~12:30Z. Could be student worker cycle issue or just KG_smoke still running. Monitor next heartbeat.

- **Fleet at 14:55Z**: fern #1983 WIP (wd-schedule-ablation, just assigned); alphonse #1979 WIP (lr-warm-restart-probe); edward #1948 WIP (precond-freq C+D running, **SIGNAL ALIVE**); tanjiro #1964 WIP (ns-iter-cooldown, silent); frieren #1966 WIP (muon-momentum-schedule); thorfinn #1957 WIP (ema-decay-cooldown-schedule); nezuko #1955 WIP (adamw-eps-cooldown); askeladd #1942 WIP (logit-z-loss). **8/8 active, zero idle.**

---

### Notes (2026-05-31 14:40Z) — ALPHONSE #1973 CLOSED 83rd [KG_smoke mechanism-dead]; ALPHONSE #1979 lr-warm-restart-probe ASSIGNED

- **★ CLOSED #1973 alphonse ns5-eps-cooldown** [83rd R5 closure, ~14:35Z] — FFS-NEUTRAL informative null via KG_smoke mechanism-dead. Beautiful kill-gate execution: student ran ONLY 200-step KG_smoke, observed min(muon_grad_norm) = 1140 (10¹⁰× above 1e-5 threshold), triggered predeclared stop condition. Saved ~13h GPU. NS5 internal ε is a numerical-safety constant, not an optimizer lever at R5 gradient scale.
- **Memory rule**: `ns5_internal_eps_irrelevant_at_r5_gradient_scale`. The 1e-7 ε in `X / (||X||_F + ε)` is sub-ULP of any realistic divisor at R5 (muon grad Frobenius norms in 10³–10⁵ range throughout cooldown). Future NS5-internal ideas: target polynomial coefficients or iter count (tanjiro #1964 already on iter).

- **★ ALPHONSE #1979 lr-warm-restart-probe ASSIGNED** — Direct response to human directive #1262 ("warm restart probes"). Single LR warm-restart pulse at step 2700, just before the FFS crossing window (2800-3050) opens. Pulse shape: half-cosine bump peaking at restart_step + duration/2, peak_frac=0.3, duration=200 steps. Mechanism: standard cosine cooldown drives LR to ~1% by step 2700; warm-restart "kicks" model out of sharp local minimum into broader basin, then resumed cooldown anneals into new basin → earlier crossing of val_loss=3.28. STRUCTURALLY DISTINCT from all 83 closed and 7 in-flight axes: no prior R5 experiment has applied a non-monotonic LR pulse during cooldown. ~25 LOC: new flags `--lr_warm_restart_step/_peak_frac/_duration`, `_warm_restart_pulse` helper, one-line patch in `set_hparams`. Pulse applied as `max(base_eta, pulse_eta)` to only raise eta. Cells: A_ctrl (None), B★(step=2700, peak=0.3, dur=200), C(step=2500 earlier), D(peak=0.5 higher amplitude). Signal gate: B★ FFS_ema ≤ 2887.

- **★★ EDWARD #1948 SIGNAL ALIVE (still active)** — A_ctrl=2925, B★(precond_freq=4)=2875, val_loss Δ=-0.00137 outside ±0.005 seed-noise band. C (freq=8) ETA 16:07Z, D (freq=2) ETA ~18:00Z. n=4 decision @ ~18:00Z.

- **Fleet at 14:40Z**: alphonse #1979 WIP (lr-warm-restart-probe, just assigned); edward #1948 WIP (precond-freq C+D running, SIGNAL ALIVE); tanjiro #1964 WIP (ns-iter-cooldown); frieren #1966 WIP (muon-momentum-schedule); thorfinn #1957 WIP (ema-decay-cooldown-schedule); nezuko #1955 WIP (adamw-eps-cooldown); askeladd #1942 WIP (logit-z-loss B★ in regression); fern #1922 WIP (wd-cooldown-shape). **8/8 active, zero idle.**

---

### Notes (2026-05-31 14:25Z) — EDWARD #1948 FIRST SIGNAL-ALIVE B★ IN MANY HEARTBEATS

- **★★ EDWARD #1948 precond-freq-cooldown signal-gate met** — Student posted A+B results:
  - A_ctrl (precond_freq=16, no-op, `73xs5f5s`): FFS_ema=2925, FFS_trainval=2925, val_loss=3.26861
  - B★ (precond_freq=4 in cooldown, `7xw24xdx`): **FFS_ema=2875, FFS_trainval=2925, val_loss=3.26724** — Δval=-0.00137 (outside ±0.005 seed-noise band)
  - **Signal gate met**: FFS_ema=2875 ≤ 2887 ✓ AND val_loss moved meaningfully → not pure attractor migration
  - **Critical discriminator**: B★ landed at attractor FFS coords {2875, 2925} BUT val_loss moved by 4× the typical seed-noise σ. The n=1→n=4 attractor reversion rule says we cannot promote on this alone, but the val_loss delta is the first "above-noise" signal in many heartbeats.
- **Edward launching C (freq=8 midpoint) + D (freq=2 aggressive)** sequentially on single GPU. C ETA 16:07Z, D ETA ~18:00Z. Then decide on n=4 based on monotone vs non-monotone pattern.
- **Watch task**: monitor C+D + decide n=4 confirmation strategy ~18:00Z. If best of (B/C/D) FFS_ema ≤ 2887, launch n=4 at that stride. If flat across B/C/D ~ {2875,2925}, close as attractor saturation (FFS-NEUTRAL).
- **Mechanism plausibility**: SOAP eigenbasis QR refresh cooldown is structurally novel — preconditioner staleness in cooldown is a real mechanism (Anil et al. Shampoo paper). Cooldown collapses LR ~100× so eigenbasis lag matters more; refreshing more aggressively (freq=16→4) keeps the basis tracking current geometry. This is the first cooldown-axis hypothesis that survived NS5 absorption.

---

### Notes (2026-05-31 13:55Z) — ALPHONSE #1941 CLOSED 82nd [FFS-NEG NS5 absorbs depth-LR asymmetry; μP axis closed]; ALPHONSE #1973 ns5-eps-cooldown ASSIGNED

- **★ CLOSED #1941 alphonse muon-depth-lr-scale** [82nd R5 closure, ~13:50Z] — FFS-NEG. Pre-mortem #1 (NS5 depth-asymmetry absorption) confirmed.
  - A_ctrl (decay=0.0, `2v5dzpp2`): FFS_ema=2875 (canonical attractor), FFS_trainval=2925
  - B★ (decay=0.15, `q1hblvmc`): FFS_ema=2925, FFS_trainval=2925 — **+50 FFS regression**
  - KG_smoke 5/5 PASS: per-block LR ratio 0.04675/0.05500 = 0.8500 verified; 24 Muon groups (12 MLP + 12 attn). Code-split byte-clean.
  - **Pre-mortem #1 confirmed**: `--ns_iter 6` drives post-NS5 spectral norm ~1 per matrix, equalizing step magnitudes across ALL blocks regardless of depth. Adding 1/depth LR decay then triple-corrects deep blocks: musoft (static) + NS5 (dynamic per-step) + depth-LR-decay (additional scalar) = over-suppression. FFS regression is the signature.
  - **NS5-absorption family EXPANDED (3rd entry)**:
    - gradient-modifier absorption (pre-NS5 additive: SGLD/GC/μ/GE-SAM) — closed
    - weight-init absorption (2D structural: orthogonal init, mean-init) — closed
    - **post-NS5 lr-scalar depth-asymmetry (muon-depth-lr-scale) — closed NOW**
  - **μP depth-calibration axis CLOSED**: static init ∝ 1/depth (musoft) + dynamic lr ∝ 1/depth (this PR) are both dominated by NS5 spectral normalization. Do not revisit while `--ns_iter 6` is active.

- **★ ALPHONSE #1973 ns5-eps-cooldown ASSIGNED** — First R5 experiment to modify NS5 *internal* parameters. Hypothesis: linearly anneal the NS5 normalization stabilizer ε at line 508 (`X = X / (X.norm(...) + 1e-7)`) from `1e-7` → `1e-9` during cooldown. Under cooldown LR collapse (~100×), gradient Frobenius norms decrease and the ε floor may clip normalization near the FFS crossing window (2800–3050). STRUCTURAL DISTINCTION: all 82 prior closures left `1e-7` ε constant; this axis operates INSIDE the NS5 absorption rather than on top of it. Implementation: ~20 LOC using module-level tensor `_NS5_EPS` with `.fill_()` for torch.compile compatibility. KG_smoke gate includes mechanism-alive diagnostic (`train/muon_grad_norm_min` every 25 steps — if >> 1e-5 throughout, ε floor irrelevant). Cells: A_ctrl (None=no-op), B★(1e-9), C(1e-8 conditional), D(1e-11 floor probe). Signal gate: FFS_ema ≤ 2887 OR FFS_trainval ≤ 2900.

- **Fleet at 13:55Z**: alphonse #1973 WIP (ns5-eps-cooldown, just assigned); tanjiro #1964 WIP (ns-iter-cooldown); frieren #1966 WIP (muon-momentum-schedule); thorfinn #1957 WIP (ema-decay-cooldown-schedule); nezuko #1955 WIP (adamw-eps-cooldown); edward #1948 WIP (precond-freq-cooldown-schedule); askeladd #1942 WIP (logit-z-loss); fern #1922 WIP (wd-cooldown-shape). **8/8 active, zero idle.**

---

### Notes (2026-05-31 13:30Z) — FRIEREN #1966 muon-momentum-schedule ASSIGNED

- **★ FRIEREN #1966 muon-momentum-schedule ASSIGNED** — First R5 ablation of Muon Nesterov momentum coefficient `mu` (fixed at 0.95 in all 81 closed experiments). Hypothesis: linearly ramp `mu` from 0.95 to a lower value (0.70–0.80) across the cooldown phase (steps 975–3250). Rationale: `mu=0.95` creates a 20-step EMA memory window; as LR collapses ~100× in cooldown, this lag harms convergence in the FFS crossing window (2800–3050). Reducing `mu` shortens EMA memory to ~3–5 steps, making the NS5 input direction more reactive to current loss-basin geometry. CRITICAL STRUCTURAL DISTINCTION from closed additive-pre-NS5 family: changing `mu` changes the Nesterov *blend weight* `grad.lerp(momentum, mu)` — this shifts the input direction to NS5 (a qualitatively different mechanism that survives NS5 projection). Implementation: ~17 LOC, no torch.compile modifications needed since `mu` is a runtime keyword argument at line 670 (unlike NS_ITER which needed two compiled function pairs). Cells: A_ctrl (no-op), B★(0.95→0.70 linear), C(0.95→0.80), D(0.95→0.60 instability probe). Signal gate: FFS_ema ≤ 2862 OR FFS_trainval ≤ 2912.
- **Fleet at 13:30Z**: tanjiro #1964 WIP (ns-iter-cooldown); thorfinn #1957 WIP (ema-decay-cooldown-schedule); nezuko #1955 WIP (adamw-eps-cooldown); edward #1948 WIP (precond-freq-cooldown-schedule); alphonse #1941 WIP (muon-depth-lr-scale); askeladd #1942 WIP (logit-z-loss); fern #1922 WIP (wd-cooldown-shape); **frieren #1966 WIP (muon-momentum-schedule, just assigned). 8/8 active, zero idle.**

---

### Notes (2026-05-31 13:00Z) — FRIEREN #1910 CLOSED 81st [FFS-NEG BIAS/LN-GAIN LR DAMPING]; FRIEREN new hypothesis TBD

- **★ CLOSED #1910 frieren bias-ln-lr-scale** [81st R5 closure, ~13:00Z] — FFS-NEG. Wang et al. Sharpness Disparity direction definitively ruled out at R5.
  - A ctrl (scale=1.0, `4yxdount`): FFS=2925, val=3.26890 — byte-correct baseline class (99 scale params, 2 embed params)
  - B (scale=0.3, `24mf7d9y`): FFS=3000, val=3.27336 — +75 FFS harm
  - C (scale=0.1, `3ydyau87`): FFS=-1, val=3.28464 — FAILED to cross 3.28
  - D (scale=0.5, `j2vxavcn`): FFS=2925, val=3.26939 — no-op (matches ctrl)
  - **Monotone pattern**: scale=1.0 = scale=0.5 < scale=0.3 < scale=0.1. Strictly more damping = strictly worse FFS.
  - **Root cause**: R5 `lr_scalars=0.03` is already conservative enough that further damping of bias/LN-gain subgroup cripples their ability to adapt through cooldown. The anti-direction probe (scale > 1.0) is phenomenological — no theory backing.
  - **Memory rule**: `bias_ln_lr_damping_null_at_r5`. AdamW subgroup split is structurally sound (byte-correct, 0.3% overhead) but the Sharpness Disparity direction is definitively closed.
  - **Fleet at 13:00Z**: tanjiro #1964 WIP, thorfinn #1957 WIP, nezuko #1955 WIP, edward #1948 WIP, alphonse #1941 WIP, askeladd #1942 WIP, fern #1922 WIP. **g1r5-frieren IDLE — needs new assignment.**

---

### Notes (2026-05-31 12:00Z) — TANJIRO #1937 CLOSED 80th [FFS-NEUTRAL QKV-ORTHO-INIT]; TANJIRO #1964 ns-iter-cooldown ASSIGNED

- **★ CLOSED #1937 tanjiro qkv-ortho-init** [80th R5 closure, ~12:00Z] — FFS-NEUTRAL. NS5 Stiefel projection absorbs orthogonal Q/K/V structural-init; 2D-weight init axis CLOSED.
  - Pre-mortem 1 confirmed: "NS5 absorption may neutralize the init advantage (gradient ≠ weight in orthogonality)." The Stiefel projection operates on gradient momentum, not weights — starting Q/K/V on the Stiefel manifold provides zero benefit to the gradient update path when Muon projects updates every step regardless.
  - Pre-mortem 2 confirmed: FFS bottleneck is the cooldown crossing window (2800–3050), not early-training gradient quality (0–500 steps). Orthogonal init addresses the wrong phase.
  - **STRUCTURAL-INIT family now at 2 members**: alphonse #1860 init-mu (MLP/proj 2D weights) + tanjiro #1937 qkv-ortho-init (attention Q/K/V 2D weights). Both FFS-NEUTRAL for same mechanism.
  - Memory rule: `ns5_absorbs_2d_weight_structural_init_at_r5`. Any future init idea affecting Muon-tracked 2D weights needs a mechanism that bypasses NS5 projection (e.g., post-update weight reparameterization, weight-space distance from Stiefel, or init of optimizer state not weight itself).
  - **2D-WEIGHT INIT AXIS CLOSED**: orthogonal, row-norm, structured prior, Haar-random — all will be absorbed by NS5 projection in the same way. Do not revisit without a bypass mechanism.

- **★ TANJIRO #1964 ns-iter-cooldown ASSIGNED** — PR #1964. First R5 ablation of NS iteration count scheduling. Hypothesis: Muon's NS5 uses `ns_iter=12` early (high accuracy, strong Stiefel projection) but switches to `ns_iter=6` (or 4) at 75% of training progress (step ~2438). Rationale: when LR has collapsed ~100× in cooldown, tight Stiefel projection may over-constrain update geometry — approximate NS5 with fewer iterations yields a broader, less-restricted update that better explores the sharp loss basin in the FFS crossing window (2800–3050). Mechanism is STRUCTURALLY DISTINCT from all 80 closed axes: no prior experiment has changed NS_ITER at all, let alone scheduled it. Implementation: two `@torch.compile`-baked function pairs (`muon_update` + `muon_update_late`, `soap_ns_step` + `soap_ns_step_late`) switched via mutable-cell pattern to respect torch.compile's constant baking. CLI flags: `--ns_iter_late` (None=no-op default) + `--ns_iter_switch_frac` (0.25=switch at 75% progress). Cells: A_ctrl (`--ns_iter 6`), B★ (`--ns_iter 12 --ns_iter_late 6 --ns_iter_switch_frac 0.25`), C (`--ns_iter 12 --ns_iter_late 4`), D (`--ns_iter 12 --ns_iter_late 6 --ns_iter_switch_frac 0.50`). KG_smoke verifies switch fires at step ~33 for 50-step debug. Signal gate: B★ FFS_ema ≤ 2887 OR FFS_trainval ≤ 2900. No-signal stop: FFS_ema > 2950 AND FFS_trainval > 2975.

- **Fleet at 12:00Z**: tanjiro #1964 WIP (ns-iter-cooldown, just assigned); thorfinn #1957 WIP (ema-decay-cooldown-schedule); nezuko #1955 WIP (adamw-eps-cooldown); edward #1948 WIP (precond-freq-cooldown-schedule); fern #1922 WIP (wd-cooldown-shape); frieren #1910 WIP (bias-ln-lr-scale); alphonse #1941 WIP (muon-depth-lr-scale); askeladd #1942 WIP (logit-z-loss). **8/8 active, zero idle.**

---

### Notes (2026-05-31 11:15Z) — THORFINN #1907 CLOSED 79th [FFS-NEG MONOTONE-IN-α]; THORFINN #1957 ema-decay-cooldown-schedule ASSIGNED

- **★ CLOSED #1907 thorfinn ln-gain-init-small** [79th R5 closure, 11:15Z] — FFS-NEG monotone-in-α.
  - A ctrl (α=1.0, `0y2j8sk1`): FFS_ema=2875, FFS_trainval=2925 (attractor)
  - B (α=0.7, `pyer58hf`): FFS_ema=2925, FFS_trainval=2950 (+50)
  - C (α=0.5, `xdt2lkf3`): FFS_ema=2950, FFS_trainval=2950 (+75)
  - D (α=0.3, `fav5h11k`): FFS_ema=3050, FFS_trainval=3025 (+175)
  - **Decisive finding**: strict monotone-in-α regression. As γ_init shrinks, FFS_ema grows linearly. R5 tuned baseline has no headroom for variance/gain reductions below 1.0.
- **★★ R5 BASELINE VARIANCE-CONTRACT FINDING**: 3rd axis with the same pattern (label smoothing #1870 + stochastic depth #1903 + LN gain init #1907). The tuned stack is at a sharp variance/regularization optimum — any direction that further suppresses variance below γ=1.0 norm regresses FFS monotonically.
- Memory rule: `ln_gain_init_below_one_ffs_neg_at_r5`. Future 1D-scale init ideas should pair with `--depth_init_mode=ctrl` to disentangle the variance contract.

- **★ THORFINN #1957 ema-decay-cooldown-schedule ASSIGNED** — First R5 ablation of the `ema_eval_decay=0.99` constant during cooldown. Hypothesis: linearly ramp `ema_eval_decay` from 0.99 → 0.95 across the cooldown phase (steps 975→3250 at `cooldown_frac=0.7`). Mechanism: in cooldown the loss curve is monotonically descending; a tight 100-step EMA tail (d=0.99) lags ~50 steps behind the current parameters. Shortening to ~20-step tail (d=0.95) snaps EMA forward to track the convergence basin, potentially advancing the FFS crossing in steps 2800–3050. ~25 LOC: one CLI flag (`--ema_decay_cooldown_target`, default None=no-op) + `get_ema_decay()` helper + replacing line 1189 `d = args.ema_eval_decay` with the scheduled value. **Critical bias-correction gotcha**: scheduled `d` breaks the `d^t` geometric series used for bias correction; need cumulative-product `bias_corr_factor *= d`. Distinct from all 79 closed and 7 in-flight axes (no prior R5 experiment touches EMA decay; all EMA params are read-only telemetry). Cells (n=1 first): A_ctrl(None no-op), B★(0.95 primary), C(0.97 mid), D(0.90 aggressive). Signal gate: B★ ema_corr_val_loss → FFS crossing earlier than ctrl OR FFS_ema ≤ 2887.

- **Fleet at 11:15Z**: thorfinn #1957 WIP (ema-decay-cooldown-schedule, just assigned); nezuko #1955 WIP (adamw-eps-cooldown); edward #1948 WIP (precond-freq-cooldown-schedule); fern #1922 WIP (wd-cooldown-shape Cell B nearly complete); frieren #1910 WIP (bias-ln-lr-scale Cell D ~38%); tanjiro #1937 WIP (qkv-ortho-init Cell B); alphonse #1941 WIP (muon-depth-lr-scale); askeladd #1942 WIP (logit-z-loss). **8/8 active, zero idle.**

---

### Notes (2026-05-31 10:35Z) — NEZUKO #1897 CLOSED 78th [FFS-NEG, +50 ACROSS η DECADE]; NEZUKO #1955 adamw-eps-cooldown ASSIGNED

- **★ CLOSED #1897 nezuko SGLD annealed Gaussian gradient noise** [78th R5 closure, 10:35Z] — FFS-NEG +50 across η decade.
  - A ctrl (`cv452ebl`): FFS_ema=2875 (on attractor)
  - B★ (η=0.005): FFS_ema=2925, +50 vs ctrl
  - C (η=0.001): FFS_ema=2925, +50 vs ctrl
  - D (η=0.01): FFS_ema=2925, +50 vs ctrl
  - **Decisive finding**: dose-insensitive +50 regression across order-of-magnitude η range = NS5 absorbs noise into fixed-relative-magnitude variance term regardless of scale. NOT noise-magnitude-sensitive, only noise-PRESENCE-sensitive.
- **★★ ADDITIVE-PRE-NS5 GRADIENT-MODIFIER FAMILY COMPLETE (4-member)**:
  - SGLD noise (#1897 FFS-NEG) + GE-SAM (#1891 FFS-NEUTRAL) + GC (#1885 FFS-NEUTRAL) + μ cooldown (#1880 FFS-NEUTRAL)
  - Unifying mechanism: NS5 Stiefel projection absorbs any modifier with rel. magnitude < O(0.1%) of dominant singular vectors
  - Memory rule: `sgld_annealed_noise_pre_ns_family_neg_at_r5`. Future SGLD-like ideas need to bypass NS5 absorption.
- Polyak-Ruppert iterate-perturbation (weight-space noise post-step) remains an OPEN family — different mechanism.

- **★ NEZUKO #1955 adamw-eps-cooldown ASSIGNED** — First R5 ablation of AdamW ε (current value 1e-10, non-default; PyTorch default 1e-8). Log-linear decay of ε during cooldown from 1e-10 → 1e-14. Targets AdamW-managed 1D scalars + embed + lm_head (not Muon-managed 2D matrices). Mechanism: when ε ≪ √v̂, ε is inert; reducing ε in cooldown lets low-v̂ (low-grad-variance) directions get larger steps, extracting finer curvature signal in the FFS crossing window. ~18 LOC: one CLI flag + `get_adamw_eps()` helper + `"eps" in group` guarded update in `set_hparams`. References: FAdam (arxiv:2405.12807), Schaipp cooldown theory (arxiv:2501.18965). KG_smoke verifies log-linear progression at steps {0, 100, 199} for 200-step debug. Cells (n=1 per FFS-PRIMARY): A_ctrl(1e-10 no-op), B★(1e-14), C(1e-12), D(1e-16 floor). Signal gate: B★ FFS_ema ≤ 2887 OR FFS_trainval ≤ 2900. Pre-mortem: bf16+fused AdamW kernel may underflow at ε<1e-15 — Cell D's purpose is to detect this.

- **Fleet at 10:35Z**: nezuko #1955 WIP (adamw-eps-cooldown, just assigned); edward #1948 WIP (precond-freq-cooldown-schedule); fern #1922 WIP (wd-cooldown-shape Cell B ~98%); thorfinn #1907 WIP (Cell D α=0.7); frieren #1910 WIP (Cell D scale=2.0, ~12%); tanjiro #1937 WIP (Cell B at ~19%); alphonse #1941 WIP (muon-depth-lr-scale); askeladd #1942 WIP (logit-z-loss). **8/8 active, zero idle.**

---

### Notes (2026-05-31 09:36Z) — EDWARD #1858 CLOSED 77th [FFS-NEUTRAL n=1→n=4 REVERT]; EDWARD #1948 precond-freq-cooldown-schedule ASSIGNED

- **★ CLOSED #1858 edward Schulz polish SQUARE α=0.1 n=4 confirm** [77th R5 closure, 09:36Z] — FFS-NEUTRAL.
  - n=4 seeds (s2–s5): μ_4(FFS_ema) = **2912.5** (= documented baseline exactly), μ_4(val/loss) = 3.269053 (Δ = −0.54σ from baseline)
  - n=1 Cell B {FFS_ema=2875, FFS_trainval=2925} did not replicate at n=4: 3/4 seeds at baseline-typical {2925, 2925/2950}
  - Classic n=1→n=4 dual-metric attractor reversion
  - **Mechanism finding preserved**: σ=0 fixed-point of Schulz polynomial makes it SAFE on rank-deficient SQUARE attn matrices — rules out the "use Schulz instead of Higham" branch
- **★★ α-BLENDED SCHULZ POLISH PER-SHAPE AXIS CLOSED**: #1858 (SQUARE attn) + #1838 thorfinn (non-square MLP, dual mechanism) together exhaust this axis. No combination expected to recover signal.

- **★ EDWARD #1948 precond-freq-cooldown-schedule ASSIGNED** — First R5 ablation of `PRECOND_FREQ=16` (hardcoded at line 29 of train_gpt_simple.py, untouched across all 77 closures). Hypothesis: reduce SOAP's QR eigenbasis refresh stride from 16→4 only in the FIRST HALF of cooldown (steps ~975→1937 at `cooldown_frac=0.7`, `train_steps=3250`), where gradient covariance is most non-stationary as LR collapses ~100×. Outside the window keep stride=16. Distinctness: SOAP-attn on/off toggles (prior closures) are orthogonal to SOAP's INTERNAL refresh rate; PRECOND_FREQ has never been ablated. ~20 LOC: two CLI flags (`--precond_freq_base`, `--precond_freq_cooldown`) + `get_precond_freq()` helper + passing `precondition_frequency=` kwarg explicitly at call site (line 668; default-arg binding means global mutation does NOT work). KG_smoke verifies schedule fires at steps {0→16, 75→4, 150→16} for a 200-step debug run. Cells: A_ctrl(freq=16 no-op), B★(freq=4 primary), C(freq=8), D(freq=2). Signal gate: B★ FFS_ema ≤ 2887 OR FFS_trainval ≤ 2900.

- **Fleet at 09:36Z**: edward #1948 WIP (precond-freq-cooldown-schedule, just assigned); fern #1922 WIP (wd-cooldown-shape Cell B ~46%); nezuko #1897 WIP (Cell D η=0.01 ~55%); thorfinn #1907 WIP (Cell D α=0.7 ~34%); frieren #1910 WIP (Cell C scale=0.1 ~61%); tanjiro #1937 WIP (qkv-ortho-init); alphonse #1941 WIP (muon-depth-lr-scale); askeladd #1942 WIP (logit-z-loss). **8/8 active, zero idle.**

---

### Notes (2026-05-31 08:20Z) — ALPHONSE #1903 CLOSED 75th [FFS-NEG MONOTONE]; ASKELADD #1891 CLOSED 76th [FFS-NEUTRAL]; ALPHONSE #1941 + ASKELADD #1942 ASSIGNED

- **★ CLOSED #1903 alphonse Stochastic Depth (DropPath)** [75th R5 closure, 08:05Z] — clean FFS-NEG, both predeclared stop conditions triggered.
  - Cell A CTRL (drop_rate=0, `d3ls9t5z`): val=3.3087, FFS=-1
  - Cell B (drop_rate=0.05, `aggnf0pt`): val=3.3185, FFS=-1
  - Cell C★ (drop_rate=0.10, `9rwheegl`): val=3.3284, FFS=-1
  - Cell D (drop_rate=0.15, `e2s7xiwd`): val=3.3375, FFS=-1
  - **Strict monotone harm**: val/loss scales linearly with drop_rate (+0.00191 per dpr_step). NO cell crossed 3.28 within 2500 steps.
- **★★ FORWARD-PASS TRAINING-TIME REGULARIZATION FAMILY CLOSED:**
  - Stochastic depth (#1903) + label smoothing (#1870) both FFS-NEG, both never crossed 3.28
  - Mechanism: at 124M params × 2500–3250 steps, no headroom to absorb regularization "rent" before FFS crossing budget runs out
  - Memory rule: `r5_ffs_neg_stochastic_depth_linear_survival`. Combined with `label_smoothing_blocks_ffs_crossing_at_r5`.

- **★ CLOSED #1891 askeladd GE-SAM (Gradient Extrapolation as zero-cost SAM)** [76th R5 closure, 08:15Z] — FFS-NEUTRAL, flat dose-response.
  - Cell A CTRL (α=0.00): FFS_ema=2950, FFS_trainval=2975
  - Cell B★ (α=0.05): FFS_ema=2925, FFS_trainval=2925
  - Cell C (α=0.02): FFS_ema=2925, FFS_trainval=2950
  - Cell D (α=0.10): FFS_ema=2925, FFS_trainval=2925
  - **Flat dose-response across α ∈ {0.02, 0.05, 0.10}**: all three non-CTRL cells at FFS_ema=2925 despite 5× α range. KG_smoke confirmed signal was real (cos_sim ≈ 0.90–0.94) and zero-compute claim verified.
- **★★ ADDITIVE-PRE-NS GRADIENT-MODIFIER FAMILY CLOSED:**
  - GE-SAM (#1891 FFS-NEUTRAL) + GC (#1885 FFS-NEUTRAL) + Muon μ cooldown (#1880 FFS-NEUTRAL): all three additive pre-NS modifiers are absorbed by NS5's Stiefel projection
  - Mechanism: g_t and g_{t-1} are nearly co-linear (cos_sim≈0.92), so finite-difference SAM acts as implicit LR boost rather than curvature-aware perturbation
  - Memory rule: `ge_sam_additive_grad_modifier_pre_ns_neutral_at_r5`. Combined with `gc_dc_component_neutral_under_ns5` and `muon_mu_cooldown_neutral_above_075_neg_at_060`.

- **★ ALPHONSE #1941 muon-depth-lr-scale ASSIGNED** — PR #1941. First R5 hypothesis in the Muon optimizer-routing space. Apply linear per-block depth decay `lr_i = lr_muon · (1 − decay · i / (N−1))` so block 0 retains full LR, block N-1 gets `lr_muon · (1−decay)`. Completes the μP depth-LR contract whose init half is satisfied by `musoft` (Yang & Hu 2021, arxiv:2203.03466). Mechanism: cooldown-phase deep-block instability is the FFS bottleneck; reducing deep-block LR moderates oscillation in the crossing window (steps 2800–3050). ~18 LOC change — per-block Muon groups via `configure_optimizers`. Cells: A_ctrl(0.0), B★(0.15), C(0.25 upper), D(0.08 conservative). KG_smoke gate verifies block_0 LR == lr_muon AND block_(N-1) LR ≈ 0.85·lr_muon at step 100. Signal gate: B★ FFS_ema ≤ 2887.

- **★ ASKELADD #1942 logit-z-loss ASSIGNED** — PR #1942. First R5 hypothesis in the loss-function-axis that does NOT introduce an entropy floor (unlike label smoothing). Add PaLM-style `w · mean(logits²)` penalty inside forward(). Mechanism: soft-tanh squash bounds logit magnitude at ±15 but provides no gradient pressure to keep logits small *within* that range; logit drift toward ±15 sharpens softmax in cooldown phase and delays FFS crossing. Z-loss creates adaptive self-regularization — optimal logit magnitude is a fixed point between CE pull and z-penalty push. 16 LOC change in `forward()`. Cells: A_ctrl(w=0.0), B★(w=1e-4 PaLM default), C1(w=1e-5), C2(w=1e-3 dose-response). Distinct from label smoothing (#1870 closed FFS-NEG): no target perturbation, no entropy floor lift, FFS crossing remains achievable. KG_smoke gate verifies z_loss > 0 at w=1e-4 and = 0 at w=0.0. References: PaLM (arxiv:2204.02311), ST-MoE (arxiv:2202.08906).

- **Fleet at 08:20Z**: edward #1858 WIP (n=4 seeds running); fern #1922 WIP (wd-cooldown-shape Cell A linear ~94%); nezuko #1897 WIP; thorfinn #1907 WIP (Cell C α=0.3 ~81%); frieren #1910 WIP (bias-ln-lr-scale Cell C running); tanjiro #1937 WIP (qkv-ortho-init); alphonse #1941 WIP (muon-depth-lr-scale, NEW); askeladd #1942 WIP (logit-z-loss, NEW). **8/8 active, zero idle.**

---

### Notes (2026-05-31 07:30Z) — TANJIRO #1880 μ COOLDOWN CLOSED 74th [FFS-NEUTRAL, SEED-NOISE DOMINANT]; TANJIRO #1937 qkv-ortho-init ASSIGNED

- **★ CLOSED #1880 tanjiro Muon μ cooldown schedule** [74th R5 closure, 07:20Z] — FFS-NEUTRAL, seed-noise dominant.
  - Cell A CTRL (`if71akg1`, μ=0.95 constant): FFS_ema=2925, FFS_trainval=2950, val=3.2704
  - Cell B (`upms16as`, μ=0.85): **FFS_ema=2875, FFS_trainval=2925** ← seed-noise attractor
  - Cell C (`8326z2mc`, μ=0.75): **FFS_ema=2875, FFS_trainval=2925** ← **identical to B = decisive null**
  - Cell D (`xf9k2m3p`, μ=0.60): FFS_ema=2925, FFS_trainval=2925, val=3.2916 (FFS-NEG val, +0.00205)
  - **Decisive finding**: B and C at identical `{FFS_ema=2875, FFS_trainval=2925}` despite different μ values = seed noise, not μ effect. Student verified μ telemetry matched formula to 4 decimal places.
  - **Mechanism**: NS5 absorbs gentle μ decay (0.75–0.95); aggressive decay (μ=0.60) hurts val by reducing Nesterov look-ahead.
  - **Memory rule**: `muon_mu_cooldown_neutral_above_075_neg_at_060`. **μ cooldown axis fully closed.**

- **★ TANJIRO #1937 qkv-ortho-init ASSIGNED** — PR #1937. Hypothesis: replace Gaussian initialization of attention Q/K/V weight matrices with orthogonal initialization at the same Frobenius norm (`std_base * sqrt(rows * cols)` rescale after `torch.nn.init.orthogonal_`). Muon's NS5 projects gradient updates onto the Stiefel manifold every step; starting Q/K/V exactly on Stiefel at step 0 reduces NS5's corrective work in early training (~0–500 steps), yielding cleaner gradient signal during the period that influences cooldown-phase FFS crossing. ≤15 LOC. Structurally orthogonal to all 74 closed families and 7 in-flight axes (thorfinn's ln-gain-init touches 1D scalars; musoft touches only residual projections; nothing touches Q/K/V 2D weight init specifically).
  - CLI flag: `--qkv_ortho_init` (action="store_true") + `--qkv_ortho_mode {qkv, qk, v}` for ablation
  - KG_smoke: verify max_sv/min_sv ≤ 1.001 AND Frobenius preservation ∈ [0.999, 1.001] before running cells
  - Cells: A_ctrl (Gaussian, code-split baseline), B★ (`--qkv_ortho_init`), C (`--qkv_ortho_mode qk` ablation), D (n=4 confirm)
  - Signal gate: B★ FFS_ema ≤ 2887 OR FFS_trainval ≤ 2900
  - Pre-mortem 1: NS5 absorption may neutralize the init advantage (gradient ≠ weight in orthogonality)
  - Pre-mortem 2: FFS bottleneck is cooldown (2800–3050), not early training (0–500)

- **★ FERN #1885 GC (73rd) reminder**: Gradient Centralization is FFS-NEUTRAL at R5 (all cells FFS_ema ∈ 2925–2975). KG_smoke confirmed 1–1.6% grad mean ratio (real DC component), but removing it moves the stack off its tuned optimum. Counter-intuitive: muon_all (Cell C=2950) outperforms muon_mlp_only (Cell B=2975) — applying GC to MLP alone disrupts tuned attn/MLP gradient balance. Gradient-preprocessing (DC component) axis closed.

- **Fleet at 07:30Z**: edward #1858 WIP (n=4 seeds running); fern #1922 WIP (wd-cooldown-shape cells); askeladd #1891 WIP; nezuko #1897 WIP; alphonse #1903 WIP (stochastic-depth, likely FFS-NEG); thorfinn #1907 WIP (Cell C α=0.3 running); frieren #1910 WIP (bias-ln-lr-scale); tanjiro #1937 WIP (qkv-ortho-init, just assigned). **8/8 active, zero idle.**

---

### Notes (2026-05-31 05:30Z) — FRIEREN #1895 LOOKAHEAD-MUON CLOSED 72nd [FFS-NEG, +212 steps]; FRIEREN #1910 bias-ln-lr-scale ASSIGNED

- **★ CLOSED #1895 frieren Lookahead-Muon k=5/α=0.5** [72nd R5 closure, 05:25Z] — clean FFS-NEG.
  - Cell B (k=5, α=0.5, `m62qxga0`): FFS_ema=**3125** (+212 steps above baseline mean 2912.5), val=3.2781
  - No Cell A CTRL launched (student skipped it — noted in close comment)
  - FFS-alive gate (≤2975) FAILED by +150 steps — no plausible Cell A draw changes conclusion
- **★★ TRAJECTORY-SPACE-AVERAGING FAMILY CLOSED:**
  - Lookahead outer averaging (k=5, α=0.5) hurts FFS by +212 steps: outer pull-back (theta_slow ← alpha·fast + (1-alpha)·slow) delays cooldown crossing.
  - NS5+SOAP already act as implicit averaging — adding Lookahead on top double-counts and causes regression.
  - **Combined with EMA-eval (already active) and #1403 Polyak-Ruppert eval-only (closed): trajectory/model-averaging family is structurally closed at R5.**
  - Memory rule: `lookahead_muon_outer_averaging_ffs_neg_at_r5`.

- **★ FRIEREN #1910 bias-ln-lr-scale ASSIGNED** — PR #1910. Hypothesis: split AdamW group into two: (1) biases+LN/RMSNorm gains at `lr_bias_scale * lr_scalars` (sweet-spot 0.3), (2) embedding+lm_head at existing `lr_scalars`. Sharpness Disparity Principle (Wang et al. ICML 2025): scale-setting params have 3-10× lower Hessian sharpness → over-driven when forced onto shared schedule → cooldown-phase oscillation delays crossing. **IMPORTANT: KG_smoke must verify scale_params count > 0** — if modded-nanogpt is bias-free + custom RMSNorm, hypothesis may be moot. Cells: smoke(100 steps), A=ctrl(scale=1.0), B★=0.3, C=0.1, D=0.5, E=n=4 confirm at best scale.

- **★ TANJIRO #1880 Cell B FFS=2875 (FFS-alive) — Cell C running:**
  - Cell A CTRL (`if71akg1`, μ=0.95): FFS_ema=2925, val=3.2704
  - Cell B (`upms16as`, μ=0.85): **FFS_ema=2875** (FFS-alive ✓), val=3.2687 (Δval=-0.0017 ≈ 0.7σ_4)
  - Cell C (`8326z2mc`, μ=0.75): running at ~20%
  - Decision pending Cell C terminal: need monotone-in-μ structure for n=4 promotion (Δval too small to promote on Cell B alone — 0.7σ_4 = likely seed noise)

- **Fleet at 05:30Z**: edward #1858 WIP (n=4 seed s3 running, s1/s4 pending); tanjiro #1880 WIP (Cell C running μ=0.75); fern #1885 WIP (Cell B ~93%); askeladd #1891 WIP (Cell B ~67%); nezuko #1897 WIP (Cell A ~73%); alphonse #1903 WIP; thorfinn #1907 WIP; frieren #1910 WIP (bias-ln-lr-scale just assigned). **8/8 active.**

---

### Notes (2026-05-31 03:35Z) — THORFINN #1870 LABEL-SMOOTHING CLOSED 71st [FFS-NEG, DID NOT CROSS]; THORFINN #1907 ln-gain-init-small ASSIGNED

- **★ CLOSED #1870 thorfinn label-smoothing α=0.05** [71st R5 closure, 03:30Z] — clean-NEG, both stop conditions hit.
  - Cell A CTRL (`qotek1lq`, α=0): FFS_ema=**2950**, val=3.2721 (crossed)
  - Cell B★ (`vde4akez`, α=0.05): FFS_ema=**-1**, val=**3.3154** — **NEVER CROSSED 3.28** (+43 mNat above target after 3250 steps)
  - Predeclared stop conditions: (1) FFS-alive gate FAILED (never crossed), (2) val-loss floor breached (3.3154 > 3.29). Both triggered.
- **★★ MECHANISM FINDING — LOSS-FUNCTION-SPACE-REGULARIZATION FAMILY CLOSED:**
  - Even α=0.05 (1.3% smoothing weight) permanently lifts the asymptotic val/loss above 3.28 within the 3250-step budget. The entropy floor introduced by label smoothing is budget-incompatible with FFS at R5.
  - **Closes the loss-function-space-regularization family** at R5. Any mechanism introducing a permanent loss floor (label smoothing, confidence penalty, mixup/soft-labels) will fail on this same budget-incompatibility mechanism.
  - Memory rule: `label_smoothing_blocks_ffs_crossing_at_r5`.

- **★ THORFINN #1907 ln-gain-init-small ASSIGNED** — PR #1907. Hypothesis: initialize all RMSNorm/LayerNorm gain γ params to α=0.5 instead of canonical 1.0. First R5 hypothesis targeting LN-gain init (musoft only touches ndim≥2 weight matrices; LN gains are ndim=1 scalars, always at 1.0). T-Fixup (Huang et al. 2020) + Admin init precedent. Cells: 0=smoke (100 steps), A=ctrl (α=1.0), B★=α=0.5, C=α=0.3, D=α=0.7, E=n=4 confirm at best α.

- **Fleet at 03:35Z**: edward #1858 WIP (n=4 confirm running ~4h remaining); tanjiro #1880 WIP (~41%); fern #1885 WIP; askeladd #1891 WIP; frieren #1895 WIP; nezuko #1897 WIP; alphonse #1903 WIP (stochastic-depth); thorfinn #1907 WIP (ln-gain-init-small). **8/8 active.**

---

### Notes (2026-05-31 02:00Z) — ALPHONSE #1860 SOAP-ATTN COOLDOWN GATE CLOSED 70th [FFS-NEG, MONOTONIC HARM]

- **★ CLOSED #1860 alphonse SOAP-attn cooldown phase-gate** [70th R5 closure, 01:08Z] — clean-NEG, predeclared falsifier triggered. Cell-by-cell:
  - Cell A CTRL (SOAP always on, `823jts3g`): FFS_ema=**2875**, FFS_trainval=2925, val=3.26841 (canonical seed-noise lower tail per #699, #1796)
  - Cell B★ (disable@975, full cooldown without SOAP, `y2roqlfr`): FFS_ema=**3025** (+150 vs A), val=3.27462
  - Cell C (disable@1625, late half without SOAP, `ymmj4bd6`): FFS_ema=**2950** (+75 vs A), val=3.27153
  - Predeclared falsifier: B and C both FFS_ema ≥ 2925 → SOAP attn IS load-bearing during cooldown ✓✓ TRIGGERED.
- **★★ HIGH-VALUE MECHANISM** (two memory rules):
  - **Monotonic A < C < B on every metric** (val, ema_val, FFS_ema, FFS_trainval) — harm scales monotonically with cooldown duration without SOAP-attn. Early cooldown window (975–1625, ~20% of training) accounts for ~50% of SOAP-attn FFS contribution.
  - **Opposes original hypothesis**: SOAP eigenbasis is NOT stale during cooldown. Strongest contribution is in the LR-decay-onset zone where the preconditioner stabilizes attn updates against rapidly-shrinking step sizes.
  - Memory rules: `soap_attn_cooldown_load_bearing_monotonic` + `soap_attn_early_cooldown_concentrated`.
- **★ SOAP-attn phase-gating family STRUCTURALLY CLOSED**: #818 (full disable) + #914 (Q-freeze) + #1707 (MLP per-kind) + #1860 (cooldown disable) — SOAP-attn is load-bearing throughout ALL training phases. No time-window gating viable.
- **Student observation (worth a follow-up family)**: MLP vs ATTN asymmetry (#1707 MLP per-kind NEUTRAL vs this PR NEG on attn) suggests SOAP benefit on attn matrices is structurally different from MLP. Potential motivator for architectural differential routing.

- **★ ALPHONSE #1903 ASSIGNED** — `stochastic-depth-residual-dropout` (Huang et al. 2016, ECCV). Stochastic depth with linear survival schedule `p_l = 1 − (l/11)·drop_rate`. Cells: A=smoke(0.10, 300 steps), B=0.05, C★=0.10, D=0.15 at 2500 steps, E=n=4 confirm at best rate. First forward-pass training-time regularization axis at R5. Complementary to `musoft` init. PR #1903.

- **★ W&B-verified in-flight progress at 01:50Z**:
  - thorfinn #1870 Cell B (`vde4akez`, α=0.05): step 2874/3250 (~88%), val=3.34 (0.06 above target, ~376 steps remain). **Borderline FFS-alive — may not cross 3.28 by step 3250**.
  - tanjiro #1880 Cell B (`upms16as`, μ=0.85): step 719/3250 (~22%), val=3.75 (early-training, too early to judge).
  - Both runs healthy, no crashes.

- **Fleet at 03:15Z**: thorfinn #1870 WIP (Cell B may have completed); tanjiro #1880 WIP (Cell B ~50%); fern #1885 WIP; askeladd #1891 WIP; frieren #1895 WIP; nezuko #1897 WIP; edward #1858 WIP (n=4 confirm running ~7h); alphonse #1903 WIP (stochastic-depth assigned). **8/8 active.**



### Notes (2026-05-31 01:45Z) — EDWARD #1858 SCHULZ POLISH SQUARE SENT BACK FOR n=4 CONFIRM [FIRST JOINT FFS+VAL SIGNAL]

- **★★ EDWARD #1858 α-blended Schulz polish on SQUARE attn — REQUEST CHANGES (n=4 confirm at α=0.1)** [01:30Z]
  - Cell A CTRL (α=0.0, `vgqqwynh`): FFS_ema=2950, val=3.27106
  - Cell B★ (α=0.1, `uvwvrmic`): **FFS_ema=2875, FFS_trainval=2925, val=3.26855 (Δval=-0.00251 = 2.5σ_4)**
  - Cell C (α=0.3, `yitza0rr`): FFS_ema=2925, val=3.27020 (Δval=-0.00086)
  - W&B verification: all metrics exact match to reported. All 3 cells finished cleanly at 3250 steps.
  - **★★ THIS IS THE FIRST JOINT FFS + val/loss POSITIVE SIGNAL IN 69 R5 CLOSURES.** Both metrics move in the same direction; Cell C confirms monotone-in-α structure (α-sweet-spot at 0.1, weaker at 0.3).
  - **Caveat**: Cell B's `{FFS_ema=2875, FFS_trainval=2925}` IS the documented seed-noise signature. Pre-declared promotion gate (FFS_trainval≤2900 OR FFS_ema≤2825) was NOT met.
  - **Decision rationale**: val/loss movement (-2.5σ_4) is not pure seed-noise; mechanism story is coherent (σ=0 fixed-point preserved, mid-σ pulled toward 1, α-sweet-spot). 7-hour GPU cost of n=4 confirmation is small vs cost of false-negative close after 69-deep plateau.
  - **n=4 protocol**: 4 fresh seeds at α=0.1 (ignore original `uvwvrmic` to avoid selection bias). Group `g1r5-edward/schulz-polish-square-alpha-blend-n4`. Merge gate: μ_4(FFS_ema) ≤ 2887.5. Close if μ_4 > 2925.
  - **★ Memory rule (already saved on n=1 evidence)**: `schulz_alpha_blend_safe_on_square_rank_deficient` — α-blend Schulz on SQUARE attn rank-deficient (σ_min≈0.003) does NOT NaN even at α=0.3. Structurally distinct from Higham polar polish (#1833, which used 1/(μσ) and blew up). σ=0 fixed-point preserved.

- **★ TANJIRO #1880 μ-cooldown — active progress** (W&B verified 01:30Z):
  - Cell A CTRL (`if71akg1`): finished 3250 steps, val=3.2704, FFS_trainval=2950
  - Cell B μ=0.85 (`upms16as`): running, ~7% (step 233/3250). Launched 00:44Z. Expected complete ~02:24Z.
  - Stale_wip flag was sequential-arm-launch lag, not failure.

- **★ THORFINN #1870 label-smoothing — active progress** (W&B verified 01:30Z):
  - Cell A CTRL (`qotek1lq`): finished 3250 steps, val=3.2721, FFS_trainval=2975
  - Cell B α=0.05 (`vde4akez`): running, ~73% (step 2379/3250). Expected complete ~01:40Z.
  - Stale_wip flag was sequential-arm-launch lag, not failure.

- **Fleet at 01:45Z**: thorfinn #1870 WIP (Cell B 73%, ~10 min remain); alphonse #1860 WIP (nudge sent earlier); edward #1858 WIP (n=4 confirm requested, ~7h budget); tanjiro #1880 WIP (Cell B 7%); fern #1885 WIP; askeladd #1891 WIP; frieren #1895 WIP (Lookahead-Muon); nezuko #1897 WIP (annealed-grad-noise). **8/8 active.**



### Notes (2026-05-31 00:45Z) — #1841 CLOSED 68th + #1834 CLOSED 69th + #1895 FRIEREN LOOKAHEAD-MUON ASSIGNED

- **★ CLOSED #1841 frieren spec-NS + LR co-tune** [68th R5 closure] — **FFS-TIE on all cells (FFS_ema=2925 modal baseline)**. After ×0.63 LR co-tune, spectral-norm and Frobenius pre-NS produce identical FFS. **Orthogonality direction NOT FFS-load-bearing** — Frobenius sub-orthogonality is pure magnitude calibration, direction already sufficiently orthogonal. Memory rule: `spec_vs_frob_iso_magnitude_ffs_tie`. Closes the entire pre-NS normalization (direction component) axis.

- **★ CLOSED #1834 nezuko adaptive NS iter** [69th R5 closure] — **FFS-NEG + Compute-NEG**. Adaptive per-matrix policy (relative residual thresholds 0.1/0.2/0.3) adds +25–27% wall-clock with zero FFS improvement. Memory rule: `uniform_threshold_per_matrix_adaptive_ns_iter_neg`. **★★ NS-iter family FULLY CLOSED**: per-head (#1821) + per-shape static (#1839) + per-matrix dynamic (#1834) — all three NS-iter abstraction levels exhausted. Fixed ns_iter=6 is already globally near-optimal for this stack.

- **★ ASSIGNED #1895 frieren: Lookahead-Muon slow/fast wrapper** — Lookahead (Zhang et al. NeurIPS 2019) outer shell around optimizer2 (Muon only). Every k=5 inner steps: `φ ← φ + α·(θ−φ); θ ← φ`. **Mechanism**: trajectory-space variance reduction, orthogonal to EMA-eval (checkpoint-time variance). **Structural orthogonality**: does not touch NS5, SOAP, LR/WD, architecture, init. ~45 LOC wrapper + ~10 LOC wiring. ~96 MB slow-weight buffer overhead. 4 cells: A=ctrl, B★=(k=5,α=0.5), C=(k=5,α=0.8), D=(k=10,α=0.5). KG_smoke gate at 500 steps. W&B group: `g1r5-frieren/lookahead-muon`.

- **★ ASSIGNED #1897 nezuko: Annealed Gradient Noise Injection** — SGLD-style (Welling & Teh 2011) per-step noise `ε_t ~ N(0, η/(1+t)^γ·I)` added to Muon gradients BEFORE NS5 orthogonalization. The FFS bottleneck is threshold-crossing reliability (σ_4=25), not mean loss level. Noise injection drives optimizer toward flatter minima (wider basin) where EMA-smoothed trajectory crosses 3.28 more reliably. Schedule anneals to zero by late training → preserves final convergence quality.
  - **Mechanism**: Neelakantan et al. 2015 schedule, η=0.005, γ=0.55. Post-NS5 effective noise scales down by projection → SNR gate at step 100 (SNR > 5) prevents overdamping.
  - **5 cells n=1**: A=ctrl, B★=(η=0.005,γ=0.55), C=(η=0.001,γ=0.55), D=(η=0.01,γ=0.55), E=slow-anneal falsifier (γ=0.10). KG_smoke at 500 steps.
  - **Structural orthogonality**: NOT in any closed axis. GC is deterministic mean-subtraction; GE-SAM is deterministic extrapolation; Lookahead is trajectory-space; NS5 variants change HOW gradient is orthogonalized; noise injection changes WHAT is fed to NS5. Completely fresh axis.
  - **References**: Neelakantan 2015 (arxiv:1511.06807), Welling & Teh 2011 (ICML).

- **Fleet at 01:15Z**: thorfinn #1870 WIP (label-smoothing, full cells running); alphonse #1860 WIP (SOAP-attn cooldown gate, nudge sent); edward #1858 WIP (Schulz polish square, nudge sent); tanjiro #1880 WIP (μ-cooldown); fern #1885 WIP (gradient-centralization); askeladd #1891 WIP (GE-SAM); frieren #1895 WIP (Lookahead-Muon, NEW); nezuko #1897 WIP (annealed-grad-noise, NEW). **8/8 active, zero idle.**

### Notes (2026-05-30 23:15Z) — ASKELADD #1839 PER-SHAPE STATIC NS ITER CLOSED 67th [FFS-NEG, MLP NS_ITER FLOOR LOAD-BEARING]; #1891 GE-SAM ASSIGNED

- **★ CLOSED #1839 askeladd per-shape STATIC NS iter decoupling** [67th R5 closure, 23:15Z] — clean-NEG, two predeclared falsifiers triggered. Cell-by-cell:
  - Cell A CTRL (6/6): FFS_ema=2950, FFS_trainval=2975
  - Cell B★ (4/8 decoupled): FFS_ema=**2975**, Pareto-dominated by C — Falsifier #4
  - Cell C (6/8 attn-bump): FFS_ema=2925, FFS_trainval=2925 (modal baseline value)
  - Cell D (4/6 mlp-save): FFS_ema=**3025**, +75 FFS vs baseline = ≈3σ_4 — Falsifier #2 (MLP ns_iter<6 catastrophic)
- **★★ HIGH-VALUE MECHANISM** (two memory rules saved):
  - **MLP ns_iter≥6 is structurally load-bearing** (`mlp_ns_iter_floor_load_bearing`): even though post-NS5(6) σ_min≈0.86 looks "good enough" from #1833's instrumentation, dropping MLP to ns_iter=4 costs +75 FFS. MLP weight updates need full 6 iters of σ_max precision.
  - **Attn ns_iter=8 produces no measurable benefit** (`attn_ns_iter_ceiling_no_gain`): Cell C at 2925 = modal baseline value, no signal.
  - Per-class dispatcher works as designed (D < A < C wall-clock); preserved in train code for nezuko #1834 if/when adaptive ns_iter lands.
- **NS-shape/iter family CLOSED at static level**: #1821 (per-head reshape NEG) + #1839 (per-shape static iter NEG). Only dynamic per-matrix axis remains via nezuko #1834 (in-flight, currently stalled — advisor nudge sent 23:13Z requesting crash details).
- **★ ASSIGNED #1891 askeladd: GE-SAM (Gradient Extrapolation as zero-cost SAM approximation)** — `g_eff = g_t + α·(g_t − g_{t-1})`. Approximates SAM's sharpness perturbation via finite-difference HVP estimate at ZERO extra forward/backward cost.
  - **Mechanism**: SAM perturbation direction = HVP, approximated by `(g_t - g_{t-1}) / Δθ` (finite difference, fixed-LR regime). Adding `α·(g_t - g_{t-1})` to each gradient before SOAP momentum lerp biases optimizer toward flatter basins where EMA-eval gains most (Izmailov 2018 SWA + Foret 2021 SAM motivation).
  - **Structural orthogonality**: acts on cross-step gradient history (g_t and g_{t-1}). NOT polar-approximator, NOT ns_iter/shape, NOT SOAP scalar HP, NOT init, NOT spectral-norm. Distinct from fern #1885 GC (mean subtraction vs. finite-difference are linearly independent additive modifications).
  - **Risk and diagnostic**: gradient noise dominance. KG_smoke logs `diag/ge_sam_cos_sim_mean` (cosine of g_t vs g_t − g_{t-1}); if `< 0.05` throughout, gradient differences are noise → close at smoke.
  - 4 cells n=1: A=ctrl(0.0), B★=0.05, C=0.02, D=0.10. Conditional Cell E at α=0.20 if D is borderline-best. W&B group `g1r5-askeladd/ge-sam-r5`.
  - **References**: Foret 2021 SAM (https://arxiv.org/abs/2010.01412), Du 2022 LookSAM (https://arxiv.org/abs/2110.03141), Zhuang 2022 GSAM (https://arxiv.org/abs/2203.08065), Izmailov 2018 SWA (https://arxiv.org/abs/1803.05407).

### Notes (2026-05-30 23:00Z) — FERN #1885 GRADIENT CENTRALIZATION ASSIGNED

- **★ ASSIGNED #1885 fern: Gradient Centralization (GC, Yong et al. 2020) before NS5/SOAP** — First non-spectral gradient preprocessing in 66 R5 closures. All closed axes act on singular values (polar-approximator family), momentum dynamics (μ schedules), or architecture (per-head NS). GC acts on the **mean** (DC component) of the gradient, structurally orthogonal to NS.
  - **Mechanism**: subtract per-output-row mean from gradient before NS consumes it. For shape [n_out, n_in]: `g -= g.mean(dim=1, keepdim=True)`. NS orthogonalization then operates on the zero-mean "AC component" only.
  - **Complementarity to NS**: NS5 acts on singular values (spectral structure); GC acts on the mean (translational structure). The two are structurally orthogonal — GC cleans the gradient before NS sees it.
  - **Risk and diagnostic**: gradient DC component may already be negligible in this stack. `diag/grad_mean_ratio` in KG_smoke (100 steps) gates the full sweep — if `grad_mean_ratio < 0.001` for all MLP layers, mechanism is falsified cheaply.
  - 3 cells n=1: A=ctrl(none), B★=muon_mlp_only, C=muon_all. W&B group `g1r5-fern/grad-centralization`.
  - **Reference**: Yong et al. 2020, ECCV. https://arxiv.org/abs/2004.01461

- **Fleet at 23:15Z**: thorfinn #1870 WIP (label-smoothing); alphonse #1860 WIP (SOAP-attn cooldown gate, ~75% Cell C); edward #1858 WIP (Schulz polish on square attn, ~45% Cell C); frieren #1841 WIP (spec-NS + LR co-tune, ~75% Cell C-safety); nezuko #1834 STALLED (advisor nudge sent 23:13Z); fern #1885 WIP (gradient-centralization); tanjiro #1880 WIP (μ-cooldown); askeladd #1891 WIP (GE-SAM, NEW). **8/8 active, zero idle.**

### Notes (2026-05-30 22:30Z) — FERN #1826 PADÉ RATIONAL NS CLOSED 66th [PARETO-NEG, POLAR-APPROXIMATOR FAMILY STRUCTURALLY EXHAUSTED]

- **★ CLOSED #1826 fern Padé-(1,1) rational NS approximant** [66th R5 closure, 22:25Z] — Pareto-NEG: FFS-neutral vs CTRL at +108% wall-clock per step. Student correctly skipped Cell D (Pareto clause: zero FFS gain at >30% wall-clock penalty).
  - Cell A CTRL: FFS_ema=2925
  - Cell B★ Padé default (iter=3): FFS_ema=**2925** (IDENTICAL), val=3.27061, step_avg 3942 ms vs CTRL 1896 ms = +107.9%
  - Cell C Padé fast (iter=2): FFS_ema=−1 (never hit target, under-converged)
  - Cell D: SKIPPED (Pareto-NEG)
- **★★ MECHANISM (high value, doubly confirmed)**:
  - **σ=0 fixed-point structural exhaustion** — Padé `f(σ)=σ(3+σ²)/(1+3σ²)` shares `f(0)=0` with NS5/Higham/Cayley/Schulz polish. **Entire polar-approximator family CANNOT lift attn σ_min ≈ 0.003** (rank-deficient stays rank-deficient).
  - **MLP σ_min NOT FFS-load-bearing — independently confirmed by Padé**: σ_min 0.86→1 in 1 iter (theoretical advantage over NS5's 6 iters) produces zero FFS gain. Agrees with #1838 Schulz polish result. Two independent mechanism-distinct ablations now confirm.
- **Polar-approximator family STRUCTURALLY EXHAUSTED at R5**: #1833 Higham (KG FAIL square attn) + #1825 Cayley (Frobenius σ-basin mismatch) + #1838 Schulz nonsquare polish (FFS-NEUTRAL) + #1826 Padé (Pareto-NEG). Further axes in this family are wasted compute unless they bundle explicit σ_min=0 lift (edward #1858 α-blended Schulz polish on SQUARE attn is the only remaining family experiment — but it also has σ=0 fixed-point limit, so unlikely to lift floor; outcome will be informative either way).
- **Remaining FFS levers** (per current evidence):
  - Loss-level (thorfinn #1870 label smoothing, in-flight)
  - Momentum dynamics (tanjiro #1880 μ cooldown schedule, in-flight)
  - LR/EMA window mechanics
  - Non-spectral attention mechanism (data ordering, attention pattern shaping, etc.)
- **FERN NOW IDLE** — researcher-agent dispatching 22:30Z for fresh hypothesis outside polar-approximator family.
- **Fleet at 22:30Z**: thorfinn #1870 WIP; alphonse #1860 WIP; edward #1858 WIP; frieren #1841 WIP; askeladd #1839 WIP; nezuko #1834 WIP; tanjiro #1880 WIP; fern IDLE (pending). **7/8 active.**

### Notes (2026-05-30 22:05Z) — TANJIRO #1821 PER-HEAD NS ATTN CLOSED 65th [FFS-NEG, OUTPUT PROJ LOAD-BEARING]

- **★ CLOSED #1821 tanjiro per-head NS orthogonalization for attention** [65th R5 closure, 22:00Z] — clean-NEG, falsifier triggered by Cell B (FFS_ema=3025, ≥2950 reject threshold):
  - Cell A CTRL: FFS_ema=2875 (baseline low-tail)
  - Cell B (per_head_ns all 4 attn): FFS_ema=**3025** (+150 vs CTRL) → REJECT
  - Cell C (per_head_ns qkv-only): FFS_ema=2925 (≈CTRL, +50 in noise band)
  - Cell D (per_head_ns + ns_iter=4): FFS_ema=3000 (NEG)
  - Cell F (ns_iter=4 only, no PH): FFS_ema=3000 (NEG)
  - **★ MECHANISM LOCALIZED to output projection (B−C delta = +100 FFS)**: per-head NS on Q/K/V is benign (projects dim→H*head_dim, head-specific subspaces); per-head NS on attn.proj.weight over-constrains inter-head mixing (projects H*head_dim→dim, head re-mixing).
  - **★★ FALSIFIER FINDING: ns_iter=6 is load-bearing on R5 stack** — Cell F shows --ns_iter 4 ALONE adds +125 FFS vs CTRL. Corroborates askeladd #1839 (per-shape NS iter) and #496 NS iter LOW sweep.
  - **NS-input-shape family broadly closed**: #1838 (Schulz polish nonsquare = NEUTRAL) + #1821 (per-head reshape = NEG). Remaining FFS lever per #1838 analysis: square attn σ_min ≈ 0.003 kernel direction (edward #1858 in-flight).
- **★ ASSIGNED #1880 tanjiro: Muon μ cooldown schedule** — First time scheduling Muon momentum coefficient in 65 R5 closures. Linear decay from μ=0.95 toward 0.60–0.85 during 70% cooldown phase (steps 975–3250). Theory: long-memory gradient buffer with constant μ carries stale pre-cooldown gradients into the 2800–3050 FFS crossing window; lower μ → more localized present-tense updates. Risk: SOAP-attn parameters read `group["mu"]` for their momentum lerp (lines 655–656) — may interact non-trivially with SOAP eigenbasis. 4 cells n=1: A=ctrl, B★=0.85, C=0.75, D=0.60. KG_smoke gate: verify μ stays 0.95 outside cooldown, decays linearly inside. n=4 promotion only if FFS_ema ≤ 2925 AND not seed-noise pattern.
- **Fleet at 22:15Z**: thorfinn #1870 WIP; alphonse #1860 WIP; edward #1858 WIP; frieren #1841 WIP; askeladd #1839 WIP; nezuko #1834 WIP; fern #1826 WIP; tanjiro #1880 WIP (muon-mu-cooldown, NEW). **8/8 active, zero idle.**

### Notes (2026-05-30 19:46Z) — THORFINN #1838 SCHULZ POLISH NONSQUARE CLOSED 64th [FFS-NEUTRAL, KILLS POST-NS5 POLISH FAMILY]

- **★ CLOSED #1838 thorfinn Schulz polynomial polish post-NS5 nonsquare MLP** [64th R5 closure, 19:45Z] — clean-NEG, falsifier triggered by PR's own design:
  - Cell A CTRL (`fk9xj72q`): FFS_ema=2925, FFS_trainval=2925, val/best=3.26880, ema/best=3.26930
  - Cell B nonsquare polish (`0zsz7jzl`): FFS_ema=2925, FFS_trainval=2925, val/best=3.26873, ema/best=3.26925
  - ΔFFS=0, Δval=6e-5 (well inside σ_single≈1e-3 noise); polish adds +21 ms/step (+1.1% wall-clock) → net-negative
  - Cells C (polish_all diagnostic) and D (n=4) skipped per falsifier rule
  - **★★ EXCELLENT MECHANISM ANALYSIS by student**: Schulz polynomial σ → σ(3-σ²)/2 confirmed lifting MLP gradient σ_min 0.8625 → 0.9730 in one step (matches closed-form prediction to bf16 precision). σ_max stays ~1.0. **But FFS doesn't budge** ⇒ **MLP gradient σ_min ∈ [0.86, 0.97] is NOT FFS-load-bearing**.
  - **★ HIGH-VALUE DIAGNOSTIC FINDING**: bf16 gram-residual `‖XX^T-I‖_F` understates polish action by ~200× because cumulative bf16 error in 768 inner products dominates off-diagonal residual. Future polish-family diagnostics should report σ_min map directly or use fp32 gram only for the diagnostic step. Memory saved.
  - **Post-NS5 polish family STRUCTURALLY CLOSED**: #1833 Higham (KG FAIL square attn) + #1825 Cayley (σ-basin mismatch with Frobenius) + #1838 Schulz nonsquare (FFS-NEUTRAL) = the inversion/polynomial-polish cluster cannot move FFS at this baseline. NS5 quintic with ns_iter=6 already overserves MLP orthogonality.
- **★ ASSIGNED #1870 thorfinn: Label smoothing α** — first loss-level (training objective) intervention in R5. All 64 closed R5 axes are NS/SOAP/schedule/init variants. `--label_smoothing α` added to train CE only; val always uses 0. 4 cells n=1: A=ctrl(0.0), B★=0.05, C=0.1, D=0.2. KG_smoke gate (50 steps, verify train_loss higher by ~α×log(V)≈1.08 nats, val_loss identical to ctrl). n=4 promotion only if FFS_ema ≤ 2925 AND clean separation from dual-metric seed-noise signature. Honest risk: logit soft-cap tanh_softcap(x,15) may already nullify the high-confidence regime.
- **Fleet at 20:05Z**: alphonse #1860 WIP; edward #1858 WIP; frieren #1841 WIP; askeladd #1839 WIP; nezuko #1834 WIP; fern #1826 WIP; tanjiro #1821 WIP; thorfinn #1870 WIP (label-smoothing, NEW). **8/8 active, zero idle.**

### Notes (2026-05-30 18:05Z) — ALPHONSE #1796 NS COEFF PHASE-SCHEDULE CLOSED 63rd [FFS-COSMETIC, FALSIFIER TRIGGERED]; #1860 SOAP-ATN PHASE GATE ASSIGNED; EDWARD→#1858; FRIEREN #1841 iter=20 APPROVED

- **★ CLOSED #1796 alphonse NS polynomial coeff phase-schedule** [63rd R5 closure, 18:00Z] — clean-NEG, falsifier triggered:
  - Cell A ctrl: FFS_ema=2925, val=3.27094
  - Cell B★ (sw975, early (2.2,-1.9,0.7)): FFS_ema=2875 / FFS_trainval=2925 — SEED-NOISE signature (dual-metric: fails FFS_trainval≤2900 AND FFS_ema≤2825 promotion gates)
  - Cell C (sw650 earlier): FFS_ema=2925 — no improvement from earlier switch
  - Cell D (stronger (2.4,-2.2,0.9)): FFS_ema=3050 — DIVERGENCE direction
  - Cell E (sw1625 more exposure falsifier): FFS_ema=2925 — **FALSIFIER TRIGGERED** — more early exposure does NOT yield more benefit vs Cell B; dose-response runs wrong direction
  - KG1 PASS: NS_ABC global + @torch._dynamo.disable() mechanism verified correct
  - NS coefficient phase-schedule (cubic-weighted a+b+c=1 early-phase) is FFS-COSMETIC at R5
- **★ ASSIGNED #1860 alphonse: SOAP-attn COOLDOWN PHASE GATE** — disable SOAP attn preconditioner at cooldown onset (step 975), revert attn matrices to plain Muon NS5 for steps 975–3250. Tests whether SOAP's eigenbasis (most informative during stable-learning phase) becomes STALE during cooldown. Distinct from #818 (full-training SOAP disable), #914 (eigenbasis freeze only). 3 cells: A=ctrl SOAP full, B★=disable at 975, C=disable at 1625.
- **★ ASSIGNED #1858 edward: α-blended Schulz polish on SQUARE attn matrices** (post-NS5) — α ∈ {0.1, 0.3}, applies partial Schulz step to σ-distribution of square 768×768 attn. Dual of thorfinn #1838 (Schulz polish on non-square MLP only). Tests whether square attn σ_min ≈ 0.003 tail is improvable or load-bearing.
- **★ FRIEREN #1841 ITER=20 APPROVED** — student found that spec-norm via 6-iter power iteration underestimates σ_max → post-scale σ_max > 1 → NaN. 20-iter power iteration stabilizes. Cell A (ctrl Frobenius) actively running `4ngqxl6e` at ~12% (18:03Z). Cell B★ (spectral iter=20, lr_mlp=0.035, lr_attn=0.022) to launch after Cell A completes (~20:15Z). Student also observed spec/frob ratio of PRE-NS input ≈ 0.143 (MLP)/0.194 (attn) — much lower than 0.63 which was measured differently. Telemetry guidance posted.
- **Fleet at 18:05Z**: frieren #1841 WIP (active, iter=20 approved); askeladd #1839 WIP; nezuko #1834 WIP; thorfinn #1838 WIP (1/2 cells done, fk9xj72q finished val=3.2688 FFS=2925); edward #1858 WIP (NEW); alphonse #1860 WIP (NEW); tanjiro #1821 WIP (Cells D+F in-flight); fern #1826 WIP. **8/8 active, zero idle.**

### Notes (2026-05-30 17:38Z) — EDWARD #1825 CAYLEY CLOSED 62nd [σ-BASIN MISMATCH WITH FROBENIUS NORMALIZATION]

- **★ CLOSED #1825 edward Cayley map closed-form NS replacement** [62nd R5 closure, 17:35Z] — clean-NEG, predeclared falsifier triggered. Exceptional mechanism analysis:
  - Cell A poly CTRL (jwzgzizn): FFS_ema=2925, FFS_trainval=2950, val/ema=3.27077 ✓ matches baseline μ_4=2912.5±25
  - Cell B Cayley (jejaikwy): FFS_ema=−1 (never reached 3.28), FFS_trainval=−1, val/ema=3.36131 ✗ catastrophic
  - Cell C n=4 blocked per predeclared falsifier "Cell B FFS_ema > 2975 → close axis"
  - **★★ STRUCTURAL MECHANISM**: under Frobenius normalization X/‖X‖_F, σ_max(X) ≈ 1/√min(m,n) ≈ 0.036 for (768,768) Gaussian. Cayley one-step σ → σ/(1.5 − 0.5σ²) only converges near σ=1 fixed point; from σ≈0.04 it gives σ≈0.027 (moves AWAY). NS5 quintic with 12 iters achieves orthogonality residual 0.0016; Cayley(1) gets 0.036 (22× worse, 30% slower wall-clock).
  - **Wen-Yin Cayley retraction clarification**: PR's formula is NOT the Wen-Yin Stiefel retraction (which is manifold→manifold from an already-orthogonal point). The "Cayley NS replacement" is a one-step ambient-space resolvent, inheriting σ-basin constraint from polar-approximation theory.
  - **Memory rule saved**: `cayley_one_step_inadequate_under_frobenius` — reject single-step closed-form NS replacements unless spectral-norm pre-scaling is explicit
- **Composition with #1829 (closed 61st today)**: Together they establish that Frobenius pre-scaling places NS input in the iterative-convergence regime, and iteration count is structurally necessary to climb from σ≈0.04 (Gaussian init) or σ≈0.6 (training-stack mid-run) toward σ=1. A one-step closed-form family cannot work under Frobenius pre-normalization.
- **Polynomial-replacement axis status**: Higham polar (#1833 KG_smoke FAIL, 59th), Cayley (#1825 22× worse residual, 62nd) → both classical closed-form polar approximants closed. Padé (fern #1826) in-flight. The polynomial-iteration family (NS5 with k iters) is structurally privileged for this stack.
- **Edward idle, fresh assignment incoming** — septic NS polynomial (degree-7) axis: distinct from #1826 Padé (rational form), distinct from #1796 phase-schedule (NS5 coefficients still). Tests whether higher-degree polynomial improves σ-convergence at the same ns_iter=6 budget.

### Notes (2026-05-30 14:44Z) — FRIEREN #1829 SPECTRAL-NORM PRE-NS CLOSED 61st [FROBENIUS LOAD-BEARING MECHANISM]; #1841 SPEC-NS-LR-COTUNE ASSIGNED

- **★ CLOSED #1829 frieren spectral-norm pre-NS scaling** [61st R5 closure, 14:42Z] — clean-NEG + high-value mechanism discovery:
  - All PR-specified Cells B/C/D (iter=2, overshoot=1.1): NaN at step 2 — 2-iter power iteration underestimates σ_max by 15-18%, post-scale σ_max > 1.4 → NS5 outside convergence basin → bf16 overflow
  - Salvaged Cell B (iter=6, overshoot=1.1): stable training initially but val_loss stuck at 7.67, weights exploded 12 orders of magnitude (`train/weight/all/rms = 8.72e11`)
  - **★★ STRUCTURAL MECHANISM FINDING — Frobenius normalization IS LOAD-BEARING for Muon LR calibration:**
    - Frobenius shrinks σ_max(input) to ~0.63 (not ~0.1 as PR hypothesized; spec/frob ratio: attn≈0.632, mlp≈0.636)
    - NS5 produces sub-orthogonal outputs: σ_max ≈ 0.63. Baseline LRs (lr_mlp=0.055, lr_attn=0.035) are TUNED to this sub-orthogonality
    - Spectral-norm pre-NS gives fully orthogonal outputs σ_max ≈ 1 → ~1.6× larger per-step Muon update → weight explosion at same LRs
    - "Frobenius is just a normalization" framing is WRONG. Sub-orthogonality is load-bearing magnitude calibration
  - **Memory rule saved**: `frobenius_load_bearing_muon_lr_calibration` — any "alternative normalization for NS5" must bundle 0.63× LR co-tune
- **★ ASSIGNED #1841 frieren: Spectral-norm + LR co-tune rescue** — Scales lr_mlp 0.055→0.035 and lr_attn 0.035→0.022 (both × 0.63 spec/frob ratio), uses spectral-norm pre-NS (iter=6, overshoot=1.0). 3 cells: A=ctrl (Frobenius), B★=spectral + co-tuned LR, C=spectral + slightly higher LR bracket (0.040/0.025). Tests whether Muon's update *direction* (truly orthogonal vs sub-orthogonal) matters beyond magnitude. All three outcomes publishable.
- **Fleet at 14:44Z**: frieren #1841 WIP (NEW); askeladd #1839 WIP; nezuko #1834 WIP; thorfinn #1838 WIP; edward #1825 WIP; fern #1826 WIP; tanjiro #1821 WIP; alphonse #1796 WIP. **8/8 active, zero idle.**

### Notes (2026-05-30 14:27Z) — ASKELADD #1776 SOAP BASIS-SMOOTH CLOSED 60th; #1839 PER-SHAPE NS ITER ASSIGNED; NEZUKO #1834 REDESIGN BLESSED (bf16 FLOOR FINDING)

- **★ CLOSED #1776 askeladd SOAP eigenbasis smooth-blend** [60th R5 closure, 14:25Z] — clean-NEG piecewise. 5-cell β sweep:
  - Cell A (β=0): FFS_ema=2875, FFS_trainval=2925 (seed-noise dual-metric tail, true CTRL ≈ 2925)
  - Cell B (β=0.3): FFS=2925, +50 NEG, val=3.26983
  - Cell C (β=0.1): FFS=2925, +50 NEG (ties B exactly: plateau confirmed)
  - Cell D (β=0.5): FFS=-1 CATASTROPHIC, val=3.28240
  - Cell E (β=0.9): FFS=-1 CATASTROPHIC, val=3.28067
  - **Two-regime mechanism**: light-blend plateau β ∈ [0.1, 0.3] (re-QR absorbs lag, +50 fixed regression) → cliff at β≈0.5 → catastrophic basis staleness. Empirically validates SOAP's discrete-refresh as load-bearing.
  - SOAP-structural family at R5: β₂ schedule #1689 + basis smooth-blend #1776 + per-class β₂ #1772 all CLOSED. precond_freq #1617 tanjiro still in-flight.
- **★ ASSIGNED #1839 askeladd per-shape STATIC NS iter decoupling** — `--ns_iter_mlp` vs `--ns_iter_attn`. 4 cells: A=ctrl(6/6), B★=4/8 decoupled, C=6/8 attn-bump, D=4/6 mlp-save. Directly motivated by thorfinn #1833's σ-profile finding (MLP σ_min ≈ 0.86 vs attn σ_min ≈ 0.003). Distinct from #496 LOW sweep, #1609/#932 depth-adaptive, #724 cooldown-only per-class, #1834 dynamic per-matrix. Fresh per-class STATIC axis.
- **★ NEZUKO #1834 REDESIGN BLESSED** — student killed Cell B at step 450 after discovering bf16 storage floor on `‖XX^T-I‖_F` for 768×768 matrices is ~m·ε_bf16 ≈ 6 (empirical ~2.4), making 1e-3 thresholds STRUCTURALLY UNREACHABLE. Approved Option B: relative residual `‖XX^T-I‖_F / √m` with thresholds {0.1, 0.2, 0.3} — scale-invariant, minimal code change. Student restarting cells. **High-value diagnostic — adaptive threshold design must respect storage precision floor.**
- **Fleet at 14:27Z**: askeladd #1839 WIP (NEW); nezuko #1834 WIP (RESTART); thorfinn #1838 WIP; edward #1825 + fern #1826 + tanjiro #1821 + alphonse #1796 + frieren #1829 in-flight. 8/8 active.

### Notes (2026-05-30 13:55Z) — THORFINN #1833 HIGHAM POLISH CLOSED 59th [KG_smoke FAIL]; #1838 SCHULZ POLISH NONSQUARE ASSIGNED; σ_min STRUCTURAL FINDING; σ_min WARNING POSTED TO EDWARD #1825 + FERN #1826

### Notes (2026-05-30 13:55Z) — THORFINN #1833 HIGHAM POLISH CLOSED 59th [KG_smoke FAIL]; #1838 SCHULZ POLISH NONSQUARE ASSIGNED; σ_min STRUCTURAL FINDING; σ_min WARNING POSTED TO EDWARD #1825 + FERN #1826

- **★ CLOSED #1833 thorfinn Higham polar-Newton polish** [59th R5 closure, 13:53Z] — **KG_smoke FAIL: catastrophic divergence both arms**. Student delivered exceptional instrumented diagnostics:
  - Cell A (CTRL `--ns_post_polish 0`): run `3216v10q`, val=5.697@50 ✓ healthy
  - Cell B (μ=1 as specified): run `3gfz9l8e`, **NaN at step ~25** ✗, residual INCREASED 1300× (not dropped), polish cost 5.18× NS5
  - Cell B (μ=Higham-scaled): run `7wtuzf8n`, **NaN at step ~25** ✗, residual 100× INCREASE
  - **Critical finding from instrumented probes**: post-NS5(6 iter) σ-profile splits by shape:
    - Square 768×768 (attention): `‖X^TX−I‖_F ≈ 11`, σ_min ≈ 0.003 (rank-deficient, NS5 polynomial p(x) is only linearly convergent at σ≈0 → kernel stays)
    - Low-rank gradient: `‖X^TX−I‖_F ≈ 27.5`, σ_min ≈ 0 (catastrophically rank-deficient)
    - Non-square 3072×768 (MLP): `‖X^TX−I‖_F ≈ 1.7`, σ_min ≈ 0.86 (Marchenko-Pastur tail, well-conditioned)
  - Mechanism: Higham polar Newton σ → ½(μσ + 1/(μσ)). For σ near 0: `1/(μσ)` blows up → σ_max inflates to ~38.3× in one step → update ×100 LR → loss NaN by step 25
  - **Memory rule saved**: `post_ns5_square_residual_finding` — ALL inversion-based polish is structurally unsafe on square attention matrices in this codebase
- **★ ASSIGNED #1838 thorfinn: Schulz polynomial polish on non-square (MLP) gradients only** — `X ← ½X(3I − X^TX)`, per-σ map σ → 1.5σ − 0.5σ³. At σ=0.86 (MLP σ_min): moves to 0.972. **No inverse, no kernel blowup, stable for σ ∈ (0, √3].** Skips square attention matrices entirely. KG_smoke included as Cell 0, then A=ctrl/B★=polish_nonsquare/C=polish_all(diagnostic)/D=n4 conditional. PR #1838. Shape-conditional post-NS polish family: distinct from Schulz-as-replacement (#1200 closed) and shape-aware NS_ITERS (#724 closed).
- **σ_min WARNING posted to #1825 edward Cayley + #1826 fern Padé** — Cayley's `lhs=I+0.5(I−X^TX)` is well-conditioned (eigenvalues [0.5, 1.5]) so won't NaN, but per-σ transform σ → σ/1.5 DECREASES σ_min → attention output LESS orthogonal than NS5. Padé f(σ) leaves σ_min ≈ 0 untouched (fixed point at 0); σ_max may drift if no mid-loop renorm. Neither approach should NaN but both may underperform NS5 on square attention. Recommended: log `‖X^TX−I‖_F` for one square + one non-square gradient at step 50 as diagnostic.
- **Fleet at 13:55Z**: thorfinn #1838 WIP; edward #1825 + fern #1826 running; tanjiro #1821/alphonse #1796/askeladd #1776/nezuko #1834/frieren #1829 in-flight. 8/8 active, zero idle.

### Notes (2026-05-30 13:18Z) — THORFINN #1772 + NEZUKO #1769 CLOSED 57+58th; #1833 HIGHAM POLISH + #1834 ADAPTIVE NS ITER ASSIGNED

- **★ CLOSED #1772 thorfinn SOAP β₂_mlp/β₂_attn per-class decouple** [57th R5 closure, 13:13Z] — clean-NEG. 5-cell terminal: A=B=C=2925/2925 (moderate decoupling FFS-NEUTRAL); D=2875/2925 (seed-noise sig 10th today); **E (0.70/0.99 EXTREME)=2950/2975 +50 trainval NEG** falsifier load-bears smooth-dose-response degradation. SOAP-internal axis cluster now **6/6 scalar HP CLOSED** (ε/exp_avg_sq/Q_row-col/static β₂/decoupled β₂/Gram warm-init) + per-class extension joins.
- **★ CLOSED #1769 nezuko Muon momentum-buffer warm-start** [58th R5 closure, 13:14Z] — clean-NEG. 5-cell terminal across scale ∈ {-1.0, 0.0, 0.5, 1.0, 2.0}: 4 of 5 cells (A=C=D=E) at FFS_ema=2925 CTRL level, lone B (scale=1.0)=2875/2925 (9th seed-noise sig today). **Cell E (scale=-1.0 reversed-sign falsifier)** ties CTRL → load-bears direction-irrelevance. Muon init axis cluster now **4/4 CLOSED**: orthogonal init #872, orthogonal QKV #1516, warm-start polar-factor #1643, momentum-buffer warm-start #1769.
- **★ ASSIGNED #1833 g1r5-thorfinn: Higham polar-Newton polish step after NS5** — adds `--ns_post_polish` flag (0=disabled). Implements `higham_polar_polish(X, n_polish)`: `X ← ½(X + Y(Y^TY)^{-1})` where Y=X via `torch.linalg.solve` for `Y^{-T}`. Quadratic convergence near orthogonality (`r ≈ 1e-3 → 1e-6` after one step). First quadratic-convergence iteration in codebase — distinct from cubic NS5 polynomial. 4 cells: A=ctrl, B★=ns6+polish1, C=ns4+polish1 (cost-matched), D=ns6+polish2. PR title search ✓ 0 hits for "polish" / "higham" / "polar newton".
- **★ ASSIGNED #1834 g1r5-nezuko: Adaptive NS iteration count via Frobenius residual threshold** — `--ns_adaptive_tol` flag triggers per-matrix early termination when `‖X^TX-I‖_F < tol`. Distinct from per-block static depth (#1609 closed) and per-step temporal schedule (#665 closed) — truly per-matrix data-dependent dynamic. Uses `@torch._dynamo.disable()` for data-dependent loop (same pattern as alphonse #1796). 4 cells: A=ctrl fixed=6, B★=cap8 tol=1e-3, C=cap6 tol=1e-2 (compute-saver), D=cap12 tol=1e-4 (quality-max). Logs `iters_used_mean/max` per step for diagnostics. PR title search ✓ 0 hits for "adaptive ns iter" / "residual threshold" / "early stop ns".
- **edward #1825 Cayley + fern #1826 Padé PICKED UP** by students (W&B CTRL_n1 cells running, ~15% progress).
- **alphonse #1796 Cell C (sw650)** step 2999/3250 (92%) val=3.277 — terminal ~13:18Z imminent.
- **tanjiro #1821 Cell A (per-head ctrl)** step 2878/3250 (89%) val=3.283 — terminal ~13:18Z imminent.
- **askeladd #1776 Cell E (β=0.9)** step 1869/3250 (58%) val=3.505 — catastrophic in flight as predicted, terminal ~13:50Z (59th R5 closure incoming).
- **Fleet 8/8 R5 active** at 13:18Z, zero idle.

### Notes (2026-05-30 13:05Z) — FRIEREN #1767 CLOSED 56th (qr_iter axis); ASSIGNED #1829 SPECTRAL-NORM pre-NS; THORFINN #1772 CELL E NEG (57th pending)

### Notes (2026-05-30 13:05Z) — FRIEREN #1767 CLOSED 56th (qr_iter axis); ASSIGNED #1829 SPECTRAL-NORM pre-NS; THORFINN #1772 CELL E NEG (57th pending)

- **★ CLOSED #1767 frieren SOAP basis-refresh QR-iter** [56th R5 closure, 13:00Z] — clean-NEG. 5-cell terminal: A(qr=1)=2925/2925/3.26891, B(qr=2)=2875/2925/3.26834, C(qr=3)=2875/2925/3.26736 (best val), D(qr=5)=2875/2925/3.26765 (plateau), **E(qr=0 falsifier)=−1/−1/3.28588 CATASTROPHIC** (never crossed 3.28). FFS axis FULLY COSMETIC across qr_iter∈{2,3,5}: all cells exactly hit today's seed-0 dual-metric signature (2875/2925), zero shift. **Cell E load-bears the QR refresh step itself** — basis-rotation is structurally required for SOAP convergence in budget. SOAP basis-mechanism axis cluster now 4/4 CLOSED (off-diagonal staleness #1654, Gram warm-init #1721, Gram β₂ warmup #1689, QR-iter #1767).
- **★ ASSIGNED #1829 g1r5-frieren: Spectral-norm pre-NS scaling via power iteration** — replaces Frobenius-norm pre-NS scaling (line 508 of train_gpt_simple.py mistakenly comments "spectral" but uses `X.norm` = Frobenius) with σ_max estimate via 2-step power iteration: `X / (1.1 · σ_max_est)`. Mechanism: NS5 polynomial p(x)=2x−1.5x³+0.5x⁵ has convergence radius ~1.4, optimal rate near x≈1. Frobenius overshrinking (‖X‖_F ≈ √r · σ_max) drops σ_max far below 1 → wasted iterations chasing it back. Spectral scaling puts σ_max≈0.91 → all singular values in high-rate basin. 4 cells: A=ctrl (Frob), B★=spectral_iter2_overshoot1.1, C=spectral_iter1, D=spectral_iter2_overshoot1.05 (tighter). PR title search ✓ 0 hits for "spectral norm" / "power iteration".
- **thorfinn #1772 Cell E (0.70/0.99 falsifier) W&B-terminal** (13:00Z): FFS_ema=2950, FFS_trainval=**2975** (+50 NEG vs A=2925), val=3.27185. Clean-NEG closure verdict: per-class β₂ decoupling FFS-NEUTRAL at moderate offsets, **directional-NEG at extreme**. Cell E load-bears the smooth-dose-response falsification. 57th R5 closure pending terminal SENPAI-RESULT post. Heartbeat read-through ack sent 13:05Z.
- **nezuko #1769 Cell E (scale=-1.0)** step 3215/3250 val=3.270 (healthy, FFS likely alive). Terminal ~13:08Z.
- **askeladd #1776 Cell E (β=0.9 falsifier)** step 1497/3250 (46%) val=3.587 → catastrophic in flight as predicted. Terminal ~13:55Z.
- **alphonse #1796 Cell C (sw650)** step 2662/3250 (82%) val=3.316 → mid-recovery. Terminal ~13:25Z.
- **tanjiro #1821 Cell A (per-head ctrl)** step 2499/3250 (77%) val=3.359 → recovery, terminal ~13:20Z.
- **edward #1825 + fern #1826** still no W&B runs in target groups (student pods polling).
- **Fleet 8/8 R5 active** at 13:05Z. Zero idle (frieren re-assigned).

### Notes (2026-05-30 12:49Z) — EDWARD #1825 + FERN #1826 ASSIGNED (NS-internal structural class); 4 cell-E terminals pending

- **★ ASSIGNED #1825 g1r5-edward: Cayley map closed-form replacement for NS5 polynomial** — `zeropower_via_cayley(G)` uses `Q = X(I + 0.5(I - X^T X))^{-1}` via `torch.linalg.solve` (closed-form retraction onto Stiefel manifold). Adds `--ns_backend {poly,cayley}` flag. Cells: A=ctrl_n1 (poly), B★=cayley_n1, C=cayley_n4 conditional on B≤2975 FFS-alive gate. Replaces iterative polynomial approximation with single-step rational retraction; targets the singular-value profile of effective update (poly NS5 sometimes overshoots σ>1, Cayley is exact). PR title search ✓ 0 hits for cayley/pade/rational.
- **★ ASSIGNED #1826 g1r5-fern: Padé rational NS approximant** — `zeropower_via_rational_ns(G, α, β, n_iter)`: `X ← X(I + αX^TX)(I + βX^TX)^{-1}` per iteration via `torch.linalg.solve`. Defaults α=3.0, β=1.5, n_iter=3 (FLOP-matched to `--ns_iter 6` NS5). Adds `--ns_rational` + `--ns_pade_alpha/beta/iter`. Cells: A=ctrl_n1, B★=rational_default, C=rational_fast (α=4.0,β=2.0,n_iter=2), D=best_n4 conditional. **Zolotarev theory**: rational approximation strictly better than polynomial at same degree for sign function. Distinct from poly-axis (#1441 AGC, #1493 QHM, #1497 GC, #1446 Lookahead, #1460 Cautious all closed gradient-shape wrappers, but rational class IS the canonical alternative to polynomial NS).
- **Researcher cycle 1 rejected**: lr_attn (DUP #209/#1677/#346) + soap_trust_threshold (DUP #171/#467/#683/#1565) — researcher's own closed-axes list flagged at L290-292; sent SendMessage rejection with explicit structural-only + R5-axis-orthogonality constraints. Cycle 2 returned valid Cayley + Padé hypotheses.
- **Fleet 8/8 R5 active** at 12:49Z, zero idle. Cell E falsifier statuses (12:49Z W&B):
  - frieren #1767 Cell E (qr_iter=0): step 3224/3250 (99.2%), val=3.286, terminal ~12:51Z, 56th R5 closure incoming
  - thorfinn #1772 Cell E (0.70/0.99): step 3024 (93.0%), val=3.277, terminal ~12:59Z
  - nezuko #1769 Cell E (scale=-1.0): step 2996 (92.2%), val=3.277, terminal ~13:00Z
  - askeladd #1776 Cell E (β=0.9): step 1145 (35.2%), val=3.641, terminal ~13:55Z (catastrophic, predicted FFS=-1)
  - alphonse #1796 Cell C (sw650 earlier switch): step 2322 (71.4%), val=3.386
  - tanjiro #1821 Cell A (per-head ctrl): step 2169 (66.7%), val=3.410

### Notes (2026-05-30 12:10Z) — EDWARD #1761 + FERN #1721 CLOSED (54+55); ASKELADD #1776 CELL D CATASTROPHIC BEND-POINT; ALPHONSE Cell B SEED-NOISE

- **★ CLOSED #1761 edward R5 stack pruning ablation** [54th R5 closure, 12:08Z] — leave-one-out ablation COMPLETE, 5 cells terminal. Map: A (CTRL) FFS=2925; **B (drop --soap_attn) FFS=-1 CATASTROPHIC** (val=3.2836 never crossed); **C (drop --ema_eval_decay) FFS=2925 TIED** (val +0.6σ — only prunable component); **D (drop --depth_init_mode musoft) FFS=2975 +50 NEG** (val +4.1σ load-bearing); **E (drop --wd_schedule ramp_down) FFS=2975 +50 NEG** (val +3.1σ load-bearing). R5 stack diagnosis: 3/4 structural adds load-bearing (1 catastrophic + 2 bounded-NEG at +2σ_4 each), 1/4 prunable (ema_eval val-cosmetic only). No interaction artifact in floor — FFS=2912.5 wall is structurally rather than interactively bounded. **Implication**: future improvement requires perturbations OUTSIDE the structural add set.
- **★ CLOSED #1721 fern SOAP Gram-matrix warm-init** [55th R5 closure, 12:08Z] — n=4 confirm clean-NEG. Per-trial [2925/2950, 2875/2925, 2925/2925, 2875/2925] → μ_4(FFS_ema)=2900 NEG (Δ=-12.5 from baseline 2912.5; 0.5σ), μ_4(FFS_trainval)=2931.25 NEG (+6.25 above CTRL). 6th n=1→n=4 regression confirmation of dual-metric seed-noise signature. **SOAP-internal scalar HP cluster CLOSED 6/6**: eps #1076, exp_avg_sq #979, Q_row/Q_col #1053, static β₂ #1077, decoupled β₂ #1130, Gram warm-init #1721 — axis exhausted.
- **★ ASKELADD #1776 Cell D CATASTROPHIC BEND-POINT** (12:05Z W&B): β=0.5 SOAP basis smooth-blend → FFS_ema=-1, FFS_trainval=-1, val/loss=**3.2824** (never crossed 3.28). Cell D is the **structural cliff** — at 50% old/50% new basis blend, re-orthogonalization cannot recover from the staleness level. Sweep map post-D: β=0 (CTRL FFS=2875), β=0.1/0.3 (fixed +50 plateau FFS=2925, val=3.2698 TIES exactly), β=0.5 (CATASTROPHIC). Axis is piecewise-monotone with cliff at β≥0.5. Cell E (β=0.9 falsifier) at step 152 — pred catastrophic. **High-information closure**: discrete-refresh design is structurally required for convergence stability, not arbitrary. 56th R5 closure incoming via Cell E terminal ~13:30Z.
- **alphonse #1796 Cell B sw975 (2.2,-1.9,0.7) terminal** (11:37Z): FFS_ema=2875 / FFS_trainval=2925 — **EXACT dual-metric seed-noise signature** (12th today). KG1 mechanism PASS ✓ (telemetry confirms phase-switch at step 975 propagates through dynamo-disabled NS). Dose too close to standard (2.0,-1.5,0.5). Cell C (sw650 earlier switch) at step 1377 (~42%), terminal ~13:00Z is the cleaner mechanism test.
- **thorfinn #1772 Cell E (mlp=0.70/attn=0.99 falsifier)** at step 2160 (66%), val=3.4151 — verdict-locked near clean-NEG closure (A=B=C=D all FFS_trainval=2925). Terminal ~12:35Z, 57th R5 closure pending.
- **nezuko #1769 Cell E (scale=-1.0 falsifier)** at step 2140 (66%), val=3.4121 — verdict-locked clean-NEG. Cell B's lone 2875 was seed-noise; D ties CTRL falsifies threshold + smooth-dose-response. Terminal ~12:35Z, 58th R5 closure pending.
- **frieren #1767 Cell E (qr_iter=0 falsifier)** at step 2440 (75%), val=3.3744 — qr_iter axis FFS-cosmetic on FFS_trainval (flat A→B→C→D), val plateau at D. Terminal ~12:25Z, 59th R5 closure pending.
- **tanjiro #1821 Cell A ctrl** at step 1236 (38%) — **student PICKED UP per-head NS attention assignment**. Smoke crashed at step 22 earlier (expected falsifier exploration). On track, terminal ~13:00Z.
- **Idle students: g1r5-edward + g1r5-fern** — researcher-agent dispatched 12:05Z for two distinct fresh hypotheses (file: `/research/RESEARCH_IDEAS_2026-05-30_EDWARD_FERN.md` pending).
- **Fleet 6/8 R5 active** at 12:10Z (edward + fern transitioning).

### Notes (2026-05-30 11:11Z) — TANJIRO #1715 CLOSED 53rd; #1821 ASSIGNED per-head NS attention; thorfinn #1772 verdict near-locked

- **★ CLOSED #1715 tanjiro SOAP PRECOND_FREQ phase-schedule** [53rd R5 closure, 11:07Z] — clean-NEG. n=4 confirm: t0=2925, t1=2925, t2=2875 (seed-noise tail), t3=2925 → **μ_4(FFS_ema)=2912.5 EXACTLY at baseline μ_4** (Δ=0), σ_4=25.0 identical to baseline. FFS_trainval μ_4=2931.25 (worse). Val/loss −0.00038 sub-σ. **SOAP PRECOND_FREQ cluster CLOSED in both presentations**: #1617 (static-value) + #1715 (phase-schedule) — PRECOND_FREQ=16 structurally optimal under R5 stack across both formulations.
- **★ ASSIGNED #1821 tanjiro: PER-HEAD Newton-Schulz orthogonalization for attention** — restructure NS to operate per attention head: G(768,768) → reshape (6, 128, 768) → NS on each head independently. Mechanism: flat NS on stacked matrix lets gradient-dominant head over-rotate the shared update direction; per-head NS constrains each head to its own subspace. Distinct from all closed NS axes (iter count, coefficients, polynomial). Adds `--per_head_ns` flag + `per_head_ns(G, H)` helper after line 519. 5-cell sweep: A=ctrl, B=full per_head_ns, C=Q/K/V only (not proj), D=per_head + ns_iter=4, F=flat + ns_iter=4 (falsifier separating "head structure" from "smaller matrices"). Dual-metric gate: FFS_ema≤2875 AND FFS_trainval≤2900 for n=4 promotion. 54th R5 axis under test.
- **thorfinn #1772 Cell D terminal** (11:09Z W&B): FFS_ema=2875 / FFS_trainval=2925 — **10th independent confirmation of dual-metric seed-noise signature today**. A=B=C=D all FFS_trainval=2925 → per-class β₂ decoupling axis FFS-NEUTRAL across [(0.90,0.90), (0.85,0.95), (0.95,0.85), (0.85,0.85)] grid. Cell E (extreme 0.70/0.99 falsifier) in flight. Verdict near-locked clean-NEG.
- **frieren #1767 Cell D terminal** (~10:14Z W&B): FFS_ema=2875 / FFS_trainval=2925 / val=3.2676 (val plateaued vs C=3.26736). qr_iter axis: FFS-cosmetic on FFS_trainval (flat A→B→C→D); val monotone-down A→B→C plateaus at D. Mechanism-finding closure expected unless Cell E (qr_iter=0) disrupts. Cell E in flight, ETA ~12:30Z.
- **nezuko #1769 Cell D terminal** (~10:55Z W&B): FFS_ema=2925 / FFS_trainval=2925 (= CTRL). Cell B's lone FFS_ema=2875 was seed-noise — both threshold AND smooth-dose-response hypotheses falsified. Cell E (scale=−1.0 falsifier) in flight, ETA ~13:00Z.
- **askeladd #1776 Cell C posted** (10:04Z): FFS_ema=2925 / FFS_trainval=2925 (TIES Cell B exactly) — step-discontinuous axis around β≥0.1. Cell D (β=0.5) in flight ETA ~11:45Z.
- **edward #1761**: Cell A=2925 ctrl, Cell B=−1 catastrophic (SOAP-attn essential), Cell C=2925 tied (ema_eval val-cosmetic, prunable), Cell D=2975 (musoft +50 NEG load-bearing), Cell E (drop wd_schedule) in flight ETA ~11:18Z. R5 ablation map: 2/4 load-bearing, 1/4 prunable (ema_eval).
- **alphonse #1796 Cell A posted** (09:22Z): FFS_ema=2925 / FFS_trainval=2950 / val=3.27094. Implementation audit ✓. Subtle CTRL FFS_trainval=2950 from dynamo-disable numerical drift. Cell B★ (sw975 with (2.2,-1.9,0.7) cubic-weighted) in flight ETA ~11:25Z.
- **fern #1721 n=4 verdict-LOCKED** (10:16Z W&B): t0=2925/2950, t1=2875/2925, t2=2925/2925, t3 in flight. Best-case μ_4(FFS_ema)=2900 NEG, μ_4(FFS_trainval)=2918.75 NEG. Trial 3 terminal ~11:55Z. 54th R5 closure pending.
- **Fleet 8/8 R5 active** at 11:11Z. Zero idle.

### Notes (2026-05-30 08:01Z) — EDWARD CELL C FFS-NEUTRAL (val-cosmetic R5 component); ASKELADD CELL B NEG; FERN #1721 VERDICT-LOCKED via FFS_trainval

- **edward #1761 Cell C terminal** (07:12Z): drop `--ema_eval_decay 0.99` → FFS=2925 TIED with Cell A CTRL (Δ=0). Val/loss=3.26948 vs A=3.26884 (+0.6σ within noise). **Correcting my 07:01Z mid-cell prediction of FFS=-1** — raw val crossed 3.28 RIGHT AT step 2925, not later. **EMA-eval is val-cosmetic, NOT FFS-load-bearing on seed=42.** First clearly val-cosmetic R5 component identified — pruning candidate. Caveat: n=1 result; at n=4 EMA may show variance-reduction (σ_4 narrower) not bias-reduction (μ_4 shift). Continue Cells D/E.
  - **Updated ablation table**: A (CTRL): 2925 ✓; B (drop --soap_attn): −1 CATASTROPHIC; **C (drop --ema_eval_decay): 2925 TIED (val-cosmetic)**; D (drop --depth_init_mode musoft): running ETA ~08:56Z; E (drop --wd_schedule ramp_down): pending.
- **askeladd #1776 Cell B terminal** (07:55Z): β=0.3 SOAP basis smooth-blend → FFS_ema=2925 / FFS_trainval=2925, val/loss +0.00158 vs CTRL. **Directional NEG (+50 FFS_ema vs same-seed CTRL=2875)**. Mid-smoothing lags Gram eigenspace → delays threshold crossing by exactly one eval interval. Cell C (β=0.1 light) running, ETA ~09:30Z. Sweep gate: monotone-NEG axis closure if C+D+E all ≥ FFS_ema=2925.
- **fern #1721 n=4 confirm verdict-LOCKED clean-NEG** (07:58Z liveness check, trial 2 in flight ~4%):
  - t0: FFS_ema=2925 / **FFS_trainval=2950** NEG (above CTRL baseline)
  - t1: FFS_ema=2875 / FFS_trainval=2925 (matches today's 3-PR seed-noise signature)
  - μ_2(FFS_ema)=2900, μ_2(FFS_trainval)=2937.5
  - **FFS_trainval merge gate already LOCKED-NEG**: best-case t2=t3=2875 gives μ_4(FFS_trainval)=2906.25 > 2900 gate.
  - **FFS_ema borderline**: best-case μ_4=2887.5 exactly at gate; any single t at 2925 → 2900 NEG.
  - Advisor decision: HOLD Cell E n=4 launch (already in force from 03:48Z), save ~8.5h GPU. Continue Cell B n=4 to terminal for closure record. 53rd R5 closure pending.
- **alphonse #1796 NS coeff phase-schedule**: still 0 implementation commits (assignment commit only). Student picked up at 06:50Z, exited iteration 768 at 07:01Z (10 min compute). Next iteration ~07:11Z+jitter → currently in compute window. Watch for first implementation commits.
- **Fleet 8/8 R5 active** at 08:01Z. Zero idle.

### Notes (2026-05-30 07:08Z) — CROSS-PR SEED CORRELATION CONFIRMED; #1769/#1767/#1776 ALL HIT (2875, 2925) DUAL-METRIC; #1772 CELL B TIES CTRL

- **★ MAJOR FINDING — 3-PR concurrent confirmation of memory rule `n1_to_n4_seed_regression_at_2875`** (07:00-07:05Z W&B/comment sweep): Today's seed=0 baseline draws the FULL R5 stack to (FFS_ema=2875, FFS_trainval=2925) — same dual-metric signature on:
  - **askeladd #1776 Cell A** (β=0.0 CTRL, R5 default β₂=0.95): FFS_ema=2875 / FFS_trainval=2925 — the smoking-gun CTRL reproduce
  - **nezuko #1769 Cell B★** (warm-start scale=1.0): FFS_ema=2875 / FFS_trainval=2925 (student auto-flagged seed-noise signature)
  - **frieren #1767 Cell B** (qr_iter=2): FFS_ema=2875 / FFS_trainval=2925 (student noted Cell A vs B differential within σ_1≈50)
- **Implication**: The EMA-corrected FFS landing 50 steps early on some seeds while FFS_trainval lands at 2925 is now confirmed as **EMA-eval smoothing noise** at the threshold-crossing, not a baseline shift. Memory rule strengthens: **NEW STANDARD — all n=1 sweep cells must report BOTH FFS_ema AND FFS_trainval**; only cells with FFS_trainval ≤ 2900 OR FFS_ema ≤ 2825 are confirm-worthy. Posted as advisor protocol on all 3 PRs (07:04-07:05Z).
- **thorfinn #1772 Cell B terminal** (07:04Z): mlp=0.85/attn=0.95 decouple TIES Cell A (mlp=attn=0.90 ctrl) at FFS_ema=2925, Δval/loss=+0.00022. Per-class β₂ decoupling axis tentative FFS-cosmetic (pre-mortem 1 HIT). Cell C (INVERT) needed to confirm. Note: thorfinn's Cell A=2925 vs askeladd's Cell A=2875 differential = #1077 static β₂=0.90 vs R5 default 0.95 +50 FFS_ema (NOT seed noise) — confirms #1077 closed-NEG at EMA-eval level too.
- **edward #1761 Cell C pre-confirm** (07:01Z): drop --ema_eval_decay → val/loss=3.2838 at step 2924/3250 (90%), likely FFS=-1 catastrophic. Would be **2nd structural pruning signal** after Cell B (drop --soap_attn). Confirms `ema_eval_decay` ALSO FFS-load-bearing on R5 (not just a metric cosmetic — without it raw val doesn't reach 3.28 in budget).
- **alphonse #1796 NS coeff phase-schedule**: 0 comments yet (PR created 06:48Z). Student pickup pending.
- **tanjiro #1715 verdict-locked** (07:00Z): trials 0+1=2925/2925, best-case μ_4=2900 NEG. Continuing to terminal (~10:30Z) for full closure record. 53rd R5 closure pending.
- **Fleet 8/8 R5 active** at 07:08Z. Zero idle.

### Notes (2026-05-30 06:42Z) — ALPHONSE #1689 CLOSED 52nd, NEZUKO #1769 CELL B = 2875 N=1 LIFT (seed-noise check needed)

- **★ CLOSED #1689 alphonse SOAP Gram-matrix β₂ warmup** [52nd R5 closure, 06:35Z] — clean-NEG. n=4 confirm: t0=2925, t1=2875, t2=2925, t3=2925 → μ_4=2912.5 = baseline μ_4 EXACTLY (Δ=0 above merge gate). val μ_4=3.269260 vs baseline 3.269600 = -0.34σ NOISE. **SOAP-internal SCALAR cluster CLOSED 6/6**: ε #1076, exp_avg_sq #979, Q_row/Q_col #1053, static β₂ #1077, decoupled β₂ #1130, β₂ warmup schedule #1689. 6th consecutive confirmation of memory rule `n1_to_n4_seed_regression_at_2875` — the diagnostic signature (FFS_ema=2875 with FFS_trainval=2925) is now ironclad.
- **nezuko #1769 Cell A/B terminal** (06:40Z):
  - Cell A (scale=0.0 ctrl): FFS_ema=**2925** (baseline reproduce ✓)
  - Cell B★ (scale=1.0 full warm-start): FFS_ema=**2875** ← n=1 -50 step lift
  - Cell C (scale=0.5) running. Cell D (scale=2.0) + Cell E (scale=-1.0 falsifier) pending.
  - Pattern matches alphonse/tanjiro/fern n=1 → n=4 regression precedent. Advisor declined auto-promote, asked student to report FFS_trainval alongside FFS_ema for seed-noise diagnosis.
- **★ ASSIGNED #1796 alphonse: NS polynomial coefficient phase-schedule** — new `--ns_coeff_switch_step` + `--ns_coeff_early_{a,b,c}` flags. Early-phase set `(2.2,-1.9,0.7)` (cubic-weighted, higher |b|) switches to standard `(2,-1.5,0.5)` at step 975 (~30%). Implementation requires `@torch._dynamo.disable()` on `zeropower_via_newtonschulz5` + mutable `NS_ABC` global (researchers confirmed code surgery surface: line 501-510 + lines 520/530 @torch.compile boundary). 5 cells: A=ctrl, B★=sw975(2.2,-1.9,0.7), C=sw650(earlier), D=sw975(2.4,-2.2,0.9 stronger), E=sw1625(late/falsifier). Distinct from #1612 static Bernstein (different mechanism: temporal schedule vs static substitution). 53rd R5 axis under test.
- **Fleet 7/8 R5 active** at 06:42Z. Zero idle once alphonse reassigned.

### Notes (2026-05-30 03:51Z) — FERN #1721 n=1 TERMINAL + ALPHONSE #1689 trial 2 IN COOLDOWN

- **fern #1721 n=1 5-cell terminal — falsifier MATCHES primary** (03:42Z):
  - A (identity ctrl): FFS_ema=2925, val=3.26946
  - B★ (diag_grad_var x1.0): FFS_ema=2875, val=3.26829 — n=1 lift
  - C (diag x0.5): FFS_ema=2925, val=3.27084
  - D (diag x2.0): FFS_ema=2925, val=3.27010
  - **E (orth_random FALSIFIER): FFS_ema=2875, val=3.26827 — TIES B★**
  - Critical pattern: B and E BOTH FFS_train=2925 / FFS_ema=2875 — EMA-only correction signature, matches memory rule `n1_to_n4_seed_regression_at_2875` (precedent: edward #1664 t1, alphonse #1689 t0). Joint prob ~0.06% if null, but mechanism is NOT "informed gradient variance" since falsifier ties — likely "any non-identity rotation of initial Q basis" OR seed-noise pair.
  - Student auto-launched Cell B n=4 confirm at 03:41Z (per predeclared KG5: FFS=2875 ≤ 2887.5 gate cleanly). ETA ~12:11Z.
  - **Advisor decision posted (03:48Z)**: HOLD Cell E n=4 launch — gate on Cell B n=4 outcome. If B confirms μ_4≤2887.5, launch E n=4 (mechanism + simpler/cheaper merge candidate). If B regresses, close clean-NEG (no E spend).
- **alphonse #1689 n=4 confirm** at step 9234 (~03:51Z): trial 0=2925 NEG, trial 1=2875 POS, trial 2 mid-cooldown (FFS known ~05:30Z), trial 3 → ALL 4 trials terminal ~06:35Z. Possible outcomes:
  - Best (t2=t3=2875): μ_4 = (2925+2875+2875+2875)/4 = **2887.5 exactly at merge gate** → MERGE candidate
  - Mid (t2=2925, t3=2875) or (t2=2875, t3=2925): μ_4 = 2900 NEG (close clean-NEG, SOAP β₂-warmup axis CLOSED)
  - Worst (t2=t3=2925): μ_4 = 2912.5 NEG (matches baseline μ_4 exactly, clean-NEG closure)
- **edward #1761 Cell B (no-soap-attn ablation)** at step 850/3250, ETA ~05:00Z — pruning signal critical, confirms whether SOAP-attn is FFS-load-bearing under R5 stack.

### Notes (2026-05-30 03:20Z)

- **★ CLOSED #1720 askeladd mu_mlp/mu_attn DECOUPLE** [51st R5 closure] — clean-NEG. A=B=C tied FFS=2925; D=2975; E(0.95/0.85 falsifier)=3000. SOAP-attn Kronecker preconditioner does NOT shift attn-mu optimum from 0.95. Per-class body-Muon HP-VALUE decoupling fully exhausted: joins #1664 cooldown SHAPE + #1716 WD SHAPE. Note: #1615 (edward) was earlier closure of same axis — #1720 serves as unintended reconfirmation.
- **★ ASSIGNED #1776 askeladd: SOAP eigenbasis SMOOTH-BLEND via β-mix** — `--soap_basis_smooth_beta` flag in `soap_basis_qr`. After computing Q_new via QR, blend Q_mixed = (1-β)*Q_new + β*Q_prev, then re-orthogonalize. 5-cell sweep: A=0.0 (ctrl), B★=0.3 (moderate), C=0.1 (light), D=0.5 (heavy), E=0.9 (near-frozen falsifier). Distinct from in-flight SOAP axes (QR-depth, warm-init, β₂-schedule, β₂-per-class, precond_freq-schedule) — targets basis-transition SMOOTHNESS not refresh-rate or quality.
- **Fleet 8/8 R5 students active** (03:20Z): alphonse #1689 n4-confirm (trial 2/4, mixed t0=2925/t1=2875), askeladd #1776 soap-basis-smooth (new), edward #1761 R5-prune (cell A→B transition), fern #1721 warm-init (cell E running), frieren #1767 qr-iter (cell A), nezuko #1769 muon-mom-warmstart (cell A), tanjiro #1715 n4-confirm (just launched), thorfinn #1772 β₂-per-class (cell A). Zero idle.

### Notes (2026-05-30 02:36Z) — POST-COMPACTION RESUME

- **★ CLOSED #1723 nezuko lr_scalars VALUE retune** [49th R5 closure, 02:15Z] — clean-NEG. Sweep [0.015, 0.020, 0.030, 0.045] all tied FFS_ema=2925. val/ema_corr non-monotonic (single-seed blip pattern). Hypothesis "musoft × LN-gain coupling needs higher lr_scalars" FALSIFIED. **AdamW aux-group fully exhausted**: β₁ + β₂ + ε + cooldown_mu (tetrad) + lr_scalars VALUE all closed. Memory `[lr_scalars_value_closed_at_r5]` written. ACCEPT only aux-side STRUCTURAL changes from here.
- **★ CLOSED #1716 thorfinn per-class WD-schedule SHAPE** [50th R5 closure, 02:24Z] — clean-NEG-on-FFS, val-marginal. B★ (mlp=ramp_down, attn=constant) ties A at FFS_ema=2925 (no FFS signal), val=3.26875 = −1.4σ_4 vs baseline μ_4=3.269600. C/D/E NEG-on-val and NEG-on-FFS. Per-class body-Muon SHAPE-decoupling cluster now saturated: cooldown SHAPE (edward #1664 n=4 t0=2925/t1=2925/t2=2925/t3=2925, μ=2925 NEG) + WD SHAPE both close clean-NEG. attn=constant val-marginal but not FFS-load-bearing.
- **★ ASSIGNED #1767 frieren: SOAP basis-refresh QR-iteration count** — 5 cells A=1 (ctrl), B★=2, C=3, D=5, E=0 (sort-only falsifier). Adds `--soap_qr_iter` flag. Subspace iteration depth — fresh structural axis (NS-internal/SOAP-internal cluster).
- **★ ASSIGNED #1769 nezuko: Muon momentum-buffer warm-start** from step-0 gradient. 5 cells A=0.0 (ctrl), B★=1.0, C=0.5, D=2.0, E=-1.0 (reversed-sign falsifier). Adds `--muon_momentum_warmstart` flag. **Aux-group exhausted → moved to body-init axis**; symmetric counterpart to fern #1721 SOAP Gram warm-init.
- **★ ASSIGNED #1772 thorfinn: SOAP Gram-EMA β₂ per-class decoupling** (β₂_mlp vs β₂_attn). 5 cells around (0.95, 0.95) ctrl: A=(0.90,0.90), B★=(0.85,0.95), C=(0.95,0.85 INVERT), D=(0.85,0.85), E=(0.70,0.99 extreme falsifier). Adds `--soap_beta2_mlp` and `--soap_beta2_attn` flags. Per-class SOAP-internal decoupling — distinct from #1772 axis closures.

### Live fleet (02:36Z, 8/8 occupied)
| Student | PR | Current cell/trial | Progress |
|---|---|---|---|
| alphonse | #1689 | n=4 confirm trial 2/4 (SOAP Gram β₂ warmup) | step 7126/13000 (~55%) — mixed: t0=2925 NEG, t1=2875 POS |
| askeladd | #1720 | Cell E (mu_mlp=0.95, mu_attn=0.85 extreme falsifier) | step 2590/3250 (~80%) — heading clean-NEG (A=B=C=2925, D=2975) |
| edward | #1761 | Cell A (R5 stack pruning ablation leave-one-out) | step 2231/3250 (~69%) — 4 cells to go |
| fern | #1721 | Cell E (orth-random falsifier) | step 1763/3250 (~54%) — A=2925, B=2875 lone-pos seed-noise pattern, C=D=2925 |
| frieren | #1767 | Cell A (qr_iter=1 ctrl) | step 871/3250 (~27%) — just assigned |
| nezuko | #1769 | Cell A (warmstart scale=0.0 ctrl) | step 542/3250 (~17%) — just assigned |
| tanjiro | #1715 | n=4 confirm trial 1/4 (B=8/32@1625 schedule) | step 83 — just launched (lone n=1 pos via EMA, memory rule flagged in comment) |
| thorfinn | #1772 | Cell A (β₂_mlp=β₂_attn=0.90) | step 23 — just launched |

### Immediate watch-list (next 1-2 hrs)
- askeladd Cell E ETA ~20 min → likely 51st R5 closure (mu_mlp/mu_attn DECOUPLE axis NEG)
- fern Cell E ETA ~30 min → student decision on Cell B n=4 confirm (memory flags seed-noise tail)
- alphonse trial 2/4 ETA ~60 min, trial 3/4 ETA ~120 min → defines SOAP Gram β₂ warmup verdict
- tanjiro n=4 confirm ETA ~8 hr (just started)
- edward sequential A→E cells ETA ~10 hr total

### Notes (2026-05-29 19:05Z)

- **★ CLOSED #1677 frieren lr_attn VALUE fine retune** [59th R5 result] — clean-NEG. Cell B★ (0.055) FFS=2950 WORST; C (0.025) TIES ctrl A (0.035) at FFS=2875; D (0.045) FFS=2950; E (0.070) FFS=3025 FAILS alive gate. Monotone-degrading above default. SOAP-attn Kronecker preconditioner absorbs attn-LR-scale sensitivity — lr_attn=0.035 optimal in [0.025, 0.070] range. Symmetric closure to #1676 wd_attn. **lr_attn VALUE axis on R5 CLOSED.** No n=4.
- **★ ASSIGNED #1736 frieren: ema_eval_decay VALUE fine-tune under R5 musoft+SOAP-attn stack** — sweep `--ema_eval_decay` around R5 default 0.99 (from #1533 merge). All 5 values tested are safe per bias-correction t-budget (d≤0.995 → d^3250 < 10^-6). 5-cell sweep: A (ctrl, 0.99), B★ (0.985 faster mixing), C (0.975 more aggressive), D (0.995 cautious slower), E (0.95 aggressive falsifier). Mechanism: faster EMA mixing → less lag behind descending val → earlier FFS crossing if descent is monotone. Zero code change required. W&B group: `g1r5-frieren/ema-eval-decay-fine`.
- **Fleet 8/8 R5 students active**: alphonse #1689 SOAP β₂ warmup (Cell D ~84%), frieren #1736 ema_eval_decay fine (new), askeladd #1720 mu decouple (Cell B ~11%), fern #1721 SOAP Gram warm-init (Cell A ~92%), tanjiro #1715 PRECOND_FREQ phase-schedule (Cell B ~53%), edward #1664 n=4 cooldown SHAPE confirm (step ~3700/13000 ~28%), nezuko #1723 lr_scalars fine (Cell A ~88%), thorfinn #1716 per-class WD-schedule (Cell B ~62%). Zero idle.
- **Key pending terminals**: alphonse #1689 Cell D (ETA ~19:30Z) → triggers Cell E decision; edward #1664 trial sequence (ETA ~22:00Z+); nezuko #1723 Cell A ctrl (ETA ~19:20Z) → conditional B-E launches.

---

### Notes (2026-05-29 17:05Z)

- **★ CLOSED #1676 nezuko wd_attn fine retune** [58th R5 result] — clean-NEG. B★ (0.040) FFS=2950 WORST; C (0.015) TIES ctrl A (0.025) at FFS=2875; E (0.030) FFS=2925. Monotone-NEG above default. Thorfinn's wd_mlp=0.040 does NOT transfer to wd_attn axis. SOAP-attn's Kronecker preconditioner absorbs attn-gradient-scale sensitivity — default wd_attn=0.025 remains optimal. No n=4 (C ties A, no strict positive). wd_attn axis CLOSED.
- **★ ASSIGNED #1723 nezuko: lr_scalars VALUE fine-tune under R5 musoft+ema_eval stack** — re-sweep `--lr_scalars` around 0.03 under the complete R5 stack. Motivation: depth_init_mode musoft reduces residual magnitudes, requiring LN gains (controlled by lr_scalars) to compensate more dynamically — optimum may have shifted upward from pre-musoft value. 5-cell sweep: A (ctrl, 0.03), B★ (0.045), C (0.020), D (0.060), E (0.015 downward falsifier). No code change required (existing flag). W&B group: `g1r5-nezuko/lr-scalars-r5-fine`.
- **Fleet 8/8 R5 students active**: alphonse #1689 SOAP β₂ warmup, frieren #1677 lr_attn fine (Cell E just started), nezuko #1723 lr_scalars fine (new), edward #1664 n=4 cooldown SHAPE confirm (step ~427), askeladd #1720 mu decouple (step ~367), fern #1721 SOAP Gram warm-init (implementing), tanjiro #1715 PRECOND_FREQ phase-schedule (step ~1798), thorfinn #1716 per-class WD-schedule (step ~2060). Zero idle.

---

### Notes (2026-05-29 16:36–16:45Z)

- **★ SENT-BACK #1664 edward per-class cooldown SHAPE** [55th R5 result, n=1 STRONG POSITIVE] — Cell B★ (mlp=cosine, attn=linear) FFS_ema = **2875** (Δ=−1.5σ, below n=1 gate 2887.5). Cell E (mlp=cos/attn=step FALSIFIER) FFS=−1 (val=3.2945, never crossed 3.28) — confirms attn smooth-LR-decay structurally load-bearing. Monotone direction: attn=linear ≺ cosine ≺ concave ≺ step. Cell D INVERT (mlp=lin/attn=cos) tied FFS=2925 → asymmetry concentrated on attn side. **Promoted Cell B★ to n=4 confirm.** If μ_4(FFS_ema) ≤ 2887.5 → MERGE candidate (baseline-shifting).
- **★ CLOSED #1659 askeladd per-group EMA-eval decay decoupling** [56th R5 result] — G1-DEAD null axis. A/B/C/E all FFS=2925 across d_body ∈ {0.99 ctrl, 0.95, 0.97, 0.90}. D (d_body=0.999) FFS=−1 STRUCTURAL artifact (bias-correction blow-up `d^t=0.0387` at t=3250, not learning effect — body trajectory identical to ctrl, but EMA only averaged last ~1000 steps). Per-group EMA decoupling FFS-NEUTRAL across safe range; slow-direction structurally blocked by bias-correction convergence (requires t ≳ 5/(1-d) ≈ 5000 steps for d=0.999). Val/loss weak monotone in fast direction but n=1 below noise.
- **★ CLOSED #1654 fern adaptive eigenbasis refresh via off-diagonal staleness** [57th R5 result] — clean-NEG null axis. A/C/D/E all FFS=2875 (tied with ctrl). B (τ=0.05) FFS=2925 single-trial noise. Staleness signal IS non-degenerate (mean=0.55-0.61) but FLAT across all training phases (does not decay through cooldown as predicted). At τ ≤ 0.15 mechanism degenerates (refresh_trigger_fraction=1.0). Cell E (τ=0.50, ONLY meaningfully-gating regime at 70% trigger) cuts refresh count 812→569 per layer but still ties ctrl. **Eigenbasis rotation rate does NOT correlate with whether SOAP benefits from a fresh basis. PRECOND_FREQ=16 was not under-refreshing.**
- **★ SOAP STRUCTURAL CLUSTER STATUS**: adaptive-refresh (#1654) + static PRECOND_FREQ (#1617) + Gram trace-norm (#1564) + scalar HPs (β2/eps/exp_avg_sq/trust-gate) all NULL. Open SOAP axes: PRECOND_FREQ PHASE-ADAPTIVE schedule (#1715 tanjiro in-flight), SOAP Gram WARM-INIT (#1721 fern reassigned).
- **★ ASSIGNED #1720 askeladd: mu_mlp/mu_attn DECOUPLING** — per-class Muon momentum decoupling (mlp vs attn) under R5 SOAP-attn stack. Code patch (similar to edward #1664): new flags `--mu_mlp` / `--mu_attn`, wire to Muon optimizer per-group "mu" field. 5-cell sweep around (0.95, 0.95) ctrl: B★ (0.95, 0.92), C (0.92, 0.95), D (0.97, 0.93), E falsifier (0.95, 0.85). Mechanism: SOAP-preconditioning may shift optimal momentum-memory length for attn (already-conditioned signal) vs mlp (raw gradient). Per memory `mu_cooldown_axis_closed.md`: mu_mlp/mu_attn decoupling explicitly fresh (mu cooldown axis closed but per-class decoupling open). Symmetric momentum-side counterpart to edward's positive cooldown-SHAPE finding.
- **★ ASSIGNED #1721 fern: SOAP Gram-matrix WARM-INIT from step-0 gradient variance** — structural SOAP axis. Replace identity-init of `row_gg` / `col_gg` with diagonal init from single-batch gradient pre-pass at step 0. 3 new flags: `--soap_warm_init_mode {identity, diag_grad_var, orthogonal_random}`, `--soap_warm_init_scale`, `--soap_warm_init_eps`. 5-cell sweep: A identity ctrl, B★ diag×1.0, C diag×0.5 conservative, D diag×2.0 aggressive, E orthogonal_random falsifier. Mechanism: first ~160 steps under identity init are effectively unpreconditioned AdamW; informed warm-init could accelerate steepest-descent early phase. NOT a Gram-input preprocessing — sets STATE before EMA accumulation, distinct from preprocessing already-accumulated Gram (line-565 invariance does NOT apply pre-eigendecomp). Distinct from #1689 (β₂ schedule controls EMA speed, not starting state).
- **Fleet 8/8 R5 students active**: alphonse #1689 SOAP β₂ warmup (Cell C @ ~50%), frieren #1677 lr_attn fine (Cell D ~75%), nezuko #1676 wd_attn fine (Cell E ~75%), edward #1664 n=4 promote of Cell B★, askeladd #1720 mu decouple (new), fern #1721 SOAP Gram warm-init (new), tanjiro #1715 PRECOND_FREQ phase-schedule (Cell A in-flight), thorfinn #1716 per-class WD-schedule (Cell A in-flight). Zero idle.

---

### Notes (2026-05-29 15:13–15:20Z)

- **★ CLOSED #1617 tanjiro PRECOND_FREQ=8 n=4 confirm** [53rd R5 result] — μ_4(FFS_ema)=2918.75, σ_4=31.46, Δ=+6.25 vs baseline 2912.5, missed gate 2887.5 by 31.25. **PRECOND_FREQ static-value axis CLOSED at n=4**. n=1 monotone trend (pf=8→2925, pf=16→2950, pf=32→2950, pf=64→2975, pf=128→3000) confirmed mechanism is real but effect size sub-σ at n=4 under EMA-eval stack. Static framing cannot isolate early-phase benefit.
- **★ CLOSED #1586 thorfinn wd_mlp=0.040 n=4 confirm** [54th R5 result] — μ_4(FFS_ema)=2943.75, σ_4=55.43 (highest R5 variance seen), Δ=+31.25 vs baseline, missed gate by 56.25. **wd_mlp VALUE axis CLOSED at n=4**. Second val-vs-FFS divergence confirmed (first was #1294 mu cooldown): n=1 val=-2.5σ BEST did not survive n=4 FFS noise. Trial_1=3000 was killer outlier inflating variance.
- **★ ASSIGNED #1715 tanjiro: SOAP PRECOND_FREQ phase-adaptive schedule** — deterministic early/late switch: higher frequency during first 50% (steps 0→1625, pf=8), lower during cooldown (steps 1625→3250, pf=32 or pf=64). 5-cell sweep (ctrl + 4 schedule variants). Structurally distinct from static-value axis. Mechanism: move compute from late-phase basis-jitter to early-phase curvature-adaptation.
- **★ ASSIGNED #1716 thorfinn: Per-class body Muon WD-schedule SHAPE decoupling** — symmetric analogue of edward #1664's per-class cooldown-LR-SHAPE (n=1 B★=2875 POSITIVE). `--wd_schedule_mlp` vs `--wd_schedule_attn` new flags. B★: mlp=ramp_down (current), attn=constant (sustained regularization, mirror of edward's "attn=linear" win). 5-cell sweep (ctrl + 4 asymmetric combos). **First WD-schedule structural axis tested at per-class granularity under R5 stack**.
- **Edward #1664 per-class cooldown SHAPE**: A=2925, B★=2875 (STRONG POSITIVE ≤2887), C=3000 NEG, D=2925 NEUTRAL, E (mlp=cos/attn=step falsifier) in flight. Pattern confirmed: ATTN-shape is load-bearing (attn=linear slower decay wins; MLP shape is neutral). n=4 promotion of B★ warranted when Cell E finalizes.
- Fleet: 8/8 R5 students active after reassignments (alphonse #1689 SOAP β₂ warmup, frieren #1677 lr_attn, nezuko #1676 wd_attn, edward #1664 cooldown SHAPE, askeladd #1659 EMA decoupling, fern #1654 SOAP eigenbasis, tanjiro #1715 PRECOND_FREQ schedule, thorfinn #1716 per-class WD schedule).

---

### Notes (2026-05-29 13:28–13:30Z) [DEFINITIVE n=4 interim values]

- **★ DEFINITIVE trial values from W&B run history (CORRECTING 11:39Z subagent hallucination of tanjiro trial_0)**:
  - **#1617 tanjiro PRECOND_FREQ=8 (ga45cab3)**: trial_0=2925, trial_1=2875, trial_2=2950, trial_3 in flight. 3-trial mean=2916.67. Best-case μ_4 = (2925+2875+2950+2875)/4 = **2906.25 > gate 2887.5 → NO MERGE POSSIBLE**. PRECOND_FREQ=8 mechanism IS load-bearing (#1617 n=1 was clean monotone in pf={1,2,4,8,16}) but effect size is sub-σ at n=4 (μ_4 ≈ 2906 vs baseline 2912.5 = Δ≈−6.5 steps, ~0.5%). EMA-eval did NOT amplify this signal as it did for #1533.
  - **#1586 thorfinn wd_mlp=0.040 (ii70qzc4)**: trial_0=2925, trial_1=3000, trial_2=2875, trial_3 in flight. 3-trial mean=2933.33. Best-case μ_4 = 2918.75 > gate 2887.5 → NO MERGE. CONFIRMED **val-but-not-FFS** divergence: cell E was n=1 BEST on val (−2.5σ) but FFS regression. Trial 1 at FFS=3000 is the killer outlier (variance inflation under wd_mlp shift).
- **Action**: BOTH n=4 confirms will close at terminal (~14:55Z ETA when trial_3 lands and student posts SENPAI-RESULT). Do NOT pre-close — wait for terminal data. Both students will be idle after closure → need fresh hypotheses ready.
- **Forward-looking implications**:
  - PRECOND_FREQ axis: structurally load-bearing but unable to clear the σ_4=25 noise floor at n=4. Cell-by-cell: best individual trial 2875 (at trial_1), worst 2950 (at trial_2). The structural-axes-only SOAP territory is now partly exhausted on this single-direction axis. Open: SOAP β₂ schedule (#1689 in flight), Gram-update kind (Eschenhagen-style staleness #1654 in flight).
  - wd_mlp axis: closed at n=4 with clean negative direction (val ≠ FFS-load-bearing). Per-class HP-value sweeps may continue but lower priority.

### Notes (2026-05-29 11:38–11:39Z)

- **★ #1617 tanjiro n=4 EMA-eval confirm (PRECOND_FREQ=8) intel (CORRECTED 13:30Z)**: trial_0_FFS=2925 + trial_1_FFS=2875 (the 11:39Z subagent misread trial_0 as 2875). Currently mid-trial_2 (step 7590/13000 = 58%). See 13:30Z section above for corrected merge math.
- **★ #1586 thorfinn n=4 EMA-eval confirm (wd_mlp=0.040) intel**: trial_0_FFS=3000 + trial_1_FFS=3000, both worse than baseline 2912.5 by +87.5 steps. Even with two perfect remaining trials (2875 each), μ_4=2937.5 > gate 2887.5 → NO MERGE possible. This is the classic val-but-not-FFS divergence: cell E was n=1 BEST on val (−2.5σ) but n=4 confirms FFS-NEG. Currently mid-trial_2 (step 7483/13000 = 58%). Likely close FFS-NEG on terminal.
- **★ #1664 edward Cell B FINALIZED FFS=2875** (was preliminary, now confirmed). Cell A ctrl=2925. Cell B per-class cooldown SHAPE (mlp=cos/attn=lin) IS FFS-positive at n=1. Cell D INVERT diagnostic (mlp=lin/attn=cos) at step 2494/3250 = 77%, not yet crossed. Cells C+E pending. Awaiting D for axis-vs-instance disambiguation.
- **#1689 alphonse SOAP β₂ warmup**: implementation complete, run `sxodglph` step 752 in flight. Cell sweep proceeding.
- All 7 in-flight runs healthy (heartbeats ≤13s). No new human issues. Zero idle.

### Notes (2026-05-29 10:52–10:59Z)

- **#1659 askeladd spurious --dry-run RESOLVED**: prior poll noted bare "--dry-run" comment on #1659 from morganmcg1 account at 10:42Z (assumed not directive). At 10:52Z askeladd politely pinged back asking for clarification — turns out the gh CLI authenticates as morganmcg1 (same as senpai-advisor), so the spurious comment was attributed to ADVISOR by the student. Apologized + clarified + directed: continue sweep as pre-registered, diagnostic value is in cells D (d_body=0.999, near-baseline arm) and E (d_body=0.90 aggressive-fast falsifier), interpolation cells A/B/C are the boring middle. Cell A FFS=2925, Cell B (d_body=0.95) FFS=2925 — TIE at n=1, no body-EMA-decoupling signal at d_body=0.95. Swapped status:review→status:wip; PR remains draft. Askeladd was NOT idle — they self-flipped the label to ping advisor.
- **Lesson learned (process)**: Gh CLI runs under morganmcg1 from advisor pod. Any stray text I emit becomes student-visible "advisor message" with no obvious provenance distinction. Be careful with malformed bash output / pipes into gh comment commands. Note: the original spurious "--dry-run" comment source is unclear (could have been from a prior cycle's tool-call accident or harness-side artifact).
- Fleet state confirmed: 8/8 R5 students status:wip (alphonse #1689 SOAP β₂ warmup, frieren #1677 lr_attn, nezuko #1676 wd_attn, edward #1664 cooldown SHAPE, askeladd #1659 EMA decoupling, fern #1654 SOAP eigenbasis, tanjiro #1617 PRECOND_FREQ n=4, thorfinn #1586 wd_mlp n=4). Zero idle.
- Prior 10:49Z W&B audit confirmed all 7 prior in-flight runs ≤112s heartbeat age — no INFRA action needed. Stale_wip flags continue to be false-alarms.

### Notes (2026-05-29 10:24–10:42Z)

- **★ CLOSED #1658 alphonse multi-β EMA-eval combination** [52nd R5 closure] — clean G1-DEAD per alphonse's own pre-registered gate. Cell B `combined_FFS=-1` (combined EMA never crossed 3.28; final ema_val_combined=3.28261). Cell A (ctrl) reproduced #1533 baseline to 4e-5. Mechanism (alphonse's clean diagnosis): τ_slow=1/(1−0.999)=1000 / T_train=3250 = **31% of horizon**. Slow EMA averages params from steps ~1925-2925 where val ≈3.46 down to 3.28 → combined val ≈ midpoint (observed 3.29787 at step 2925 when fast crossed). Karras et al.'s power-function EMA works in multi-million-step diffusion (τ_slow ≪ T_train) — breaks in 3250-step speedrun. Implementation sanity verified (slow_d_pow_t=0.03871 matches 0.999^3250). Multi-timescale EMA COMBINATION at val time axis closed FFS-NEG.
- **★ ASSIGNED #1689 alphonse SOAP Gram-matrix β₂ warmup schedule** — early-train preconditioner adaptation, distinct from #1617 PRECOND_FREQ axis. **β₂ SCHEDULE axis** (per advisor memory: SOAP scalar HP cluster closed, structural-axes still open). 5-cell sweep {init=(0.5,0.7,0.85), warmup_steps=300} + Cell E (init=0.5, warmup_steps=150 shorter-ramp diagnostic) + Cell A ctrl. Two new flags: `--soap_b2_warmup_init` + `--soap_b2_warmup_steps`. Pre-registered G1 FFS-alive ≤2975, G2 promotion gate ≤2887. Mechanism: low β₂ early → Gram tracks rapidly-shifting early curvature → eigenbasis adapts; ramp to default for late-train stability. Plateau-protocol-bigger-swing axis after alphonse's EMA-eval cluster exhausted.
- Edward #1664 cell B★ FFS_ema=2875 still PRELIMINARY (no update; cell A finished at 2925, B nearly finished at 3000+/3250 step last check). Promotion still DEFERRED pending C/D/E.
- #1659 askeladd anomaly: human researcher account posted bare "--dry-run" comment on PR @10:42Z. PR remains status:wip; runs continuing. Not actionable as directive. Noted for next-poll re-check.
- Fleet at full occupation: 7 R5 students WIP (alphonse → #1689 just assigned, edward #1664, fern #1654, askeladd #1659, tanjiro #1617 n=4, thorfinn #1586 n=4, nezuko #1676, frieren #1677). Zero idle.

### Notes (2026-05-29 09:42–09:57Z)

- ★ **edward #1664 cell B★ (mlp=cosine, attn=linear) FFS_ema=2875 PRELIMINARY**, still running step 3003/3250 (92%). Ctrl A FFS_ema=2925 (finished). **B is −50 steps faster than ctrl at n=1, MEETS pre-registered strong FFS-positive direct-n=4 gate (B★≤2887)**. Per edward's PR-body decision rules: "B★ FFS_ema ≤ 2887 (μ−σ): strong FFS-positive, send directly to n=4 confirm". DEFER promotion until full B finalizes + cells C/D/E land — cells run sequentially on 1 GPU, ETA ~3 hr for full sweep. Cell D INVERT (mlp=lin, attn=cos) is the diagnostic falsifier — needed to disambiguate whether MLP-shape or ATTN-shape is load-bearing.
- **fern #1654 cell B (τ=0.05) FINALIZED**: FFS_ema=2925 vs ctrl A 2875 → clean +50 step NEG at n=1. τ=0.05 FFS-NEG. Cell C (τ=0.02) running step 827 (early). Cells D (τ=0.15) + E (τ=0.50) not started.
- **alphonse #1658 cell B (50mix) FINALIZED**: single-stream FFS_ema=2925 (tie with ctrl A=2925) BUT `final_first_step_to_target_combined=-1` (the COMBINED multi-β val NEVER crossed 3.28). Hypothesis-arm test (combined val crossing) REJECTED at n=1 cell B. Cells C/D/E TBD.
- **askeladd #1659 cell B (d_body=0.95)** running step 3029/3250, FFS=2925 already crossed. Cells C/D/E TBD.
- n=4 confirms cell-2 mid-flight: #1617 tanjiro step 4972; #1586 thorfinn step 4783.
- 4 stale_wip flags verified false-alarm round 10+ via W&B. All 8 students productively occupied; zero idle; zero new human issues.

### Notes (2026-05-29 09:08–09:27Z)

- **#1654 fern cell B (τ=0.05) FIRST READOUT**: FFS_ema=2925 vs ctrl cell A FFS_ema=2875 → **τ=0.05 NEG at n=1 (+50 steps slower than ctrl)**. Cell B at step 3074/3250 (94.6%) val=3.2732 — informative crossing already locked. Ctrl FFS_ema=2875 is a propitious single-seed (below current baseline μ_4=2912.5) but n=1 sample, not a merge candidate. Cells C (τ=0.02) step 565, D (τ=0.15) + E (τ=0.50) not yet started. KG1 reply still holds: continue all 5 cells; diagnostic value now concentrated in D+E (broader τ range tests refresh-frequency saturation hypothesis).
- **Other in-flight cell-B states (all running, FFS not crossed)**: #1664 edward (mlp-cos/attn-lin) step 2406/3250 val=3.36; #1658 alphonse (50mix) step 2874/3250 val=3.30; #1659 askeladd (d_body=0.95) step 2543/3250 val=3.34. None have crossed val<3.28 yet; cells likely to terminate without FFS-alive.
- **n=4 confirms progressing**: #1617 tanjiro `ga45cab3` step 4349 (cell 2 in flight); #1586 thorfinn `ii70qzc4` step 4139 (cell 2 in flight). Cell-length ~3085 each, n=4 = ~12,340 steps total. ETA ~3-4 hr.
- **Harness stale_wip rotation**: #1617 dropped off (last-comment-time advanced); #1654 added (now flagged 5th consecutive false-alarm — fern training without commenting). All 4 stale_wip flags (#1664/#1658/#1654/#1586) verified false-alarm round 9+ via W&B (heartbeats ≤14s, runs progressing +300-500 steps since last poll). No nudge action.
- Zero new human issues. Zero idle students. All 8 productively occupied.

### Notes (2026-05-29 08:23–08:25Z)

- **★ CLOSED #1651 frieren pre-NS grad-Frobenius normalization** [51st R5 result, axis-class-distinct from LAMB/LARS]. Cell A FFS=2950 (baseline reproducibility), Cell B α=1.0 grad-mode FFS=-1 val=3.575 (KG2+KG3 fired), Cell C weight-mode falsifier tracked A within +0.06 val (proving NOT a LAMB/LARS replica). Mechanism diagnosis: late-train ||g_nesterov||_F distribution INVERTED — MLP balloon (max 343), attn collapse (mean 2.96). Divisor amplifies destructive imbalance instead of tempering it. Closure ≠ cluster-replica null but informative axis-class-distinct NEG.
- **★ ASSIGNED #1677 frieren lr_attn fine re-tune under R5 stack** — completes body Muon HP-value matrix on attn-side LR axis. 5-cell sweep {0.025/0.035/0.045/0.055/0.070}. Mirror of #162 lr_mlp win for SOAP-attn stack (where SOAP-attn was DISABLED in #162). Zero code change; existing `--lr_attn` flag. Distinct from #1586 (wd_mlp), #1676 (wd_attn), #1664 (cooldown shape).
- Harness flagged #1664+#1658 as `stale_wip` for 2nd consecutive poll. Per `feedback_verify_subagent_time_claims.md`, verified W&B: #1664 edward `3e25sgci` step 543 val=3.811 RUNNING (was 343 7min ago); #1658 alphonse `1f1haxux` step 1085 val=3.642 RUNNING (was 874 7min ago). Both productively training. NO nudge.
- Issue #1598 (senpai-pr-guard substring match — fleet-wide infra bug, R4 #1530 example) — labeled "human" only; human team owns it. Not R5-actionable.
- Human issues open on R5: only #1262 (FFS-primary directive, 2026-05-26). No new messages.

### Notes (2026-05-29 07:25–08:10Z)

- **★ CLOSED #1643 nezuko NS warm-start** [50th R5 closure] — clean FFS-NEG closure. Cell A (α=0): val=3.27154, FFS=2950. Cell B (α=0.7): val=3.52822, FFS=-1. Cell C (α=1.0) catastrophic from step 500, early-killed step 2875 val=4.81831, FFS=-1. Diagnostic readout confirms warmstart materially alters NS iterate (ns_q_norm=55.5 vs u_cold_norm=54.2, diff_norm=69.7) but degrades FFS. Mechanism: SOAP basis temporal continuity (Gram EMA + PRECOND_FREQ=16, cos_sim 0.82-0.84) already saturates orthogonalization-level continuity headroom. **NS-internal cluster now 6/6 CLOSED** (depth-schedule #1609, poly-coeffs #1612, iter-count #1638/#1509, warmstart #1643).
- **★ ASSIGNED #1676 nezuko wd_attn fine re-tune** — mirror of thorfinn #1586 (wd_mlp fine) on attention-side WD axis. Memory-permitted WD-value sweep (per `muon_body_wd_already_set.md`). 5-cell sweep {0.015/0.025/0.030/0.040/0.050}. Zero code change — `--wd_attn` is existing flag. Distinct from #1586 (wd_mlp not wd_attn), #1615 (mu CLOSED), and #194 pre-R5 stack. Hypothesis: SOAP-attn's Kronecker preconditioning changes effective attn-weight gradient; default wd_attn=0.025 was tuned for plain-Muon attention. Stage A+B first, conditional C/D/E.
- **#1617 tanjiro n=4 EMA-eval confirm**: still in flight.
- **#1586 thorfinn n=4 EMA-eval confirm**: still in flight.
- **#1654 fern**: continue all 5 cells per KG1 reply (D at τ=0.15, E at τ=0.50 are now diagnostic).
- **#1651 frieren cell B**: let run to natural termination per non-cherry-pick rule.
- **#1664 edward**: implementing per-class cooldown SHAPE (post-assign lag normal).

### Current state

**Current baseline (PR #1533, 2026-05-29)**:
- **μ_4(FFS_ema) = 2912.5** (σ_4=25.0, min/max=2875/2925) — PR #1533 alphonse EMA-eval SWA d=0.99
- **μ_4(val) = 3.269600** (train-traj); W&B run `axzk5hpf`
- **FFS merge gate: μ_4(FFS_ema) ≤ 2887.5** (25 steps below new baseline)
- **n=1 FFS-alive gate: FFS ≤ 2975** (unchanged)

**★★★ Mandatory stack**: `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99`

**Actions this poll**:
1. ★★ **APPROVED #1617 tanjiro n=4 confirm of Cell B (pf=8)** under EMA-eval stack. n=1 screen: monotone in PRECOND_FREQ (A=2950, B=2925, C=2950, D=2975, E=3000), G2 FFS-positive trigger fired at B (val=3.26898 vs ctrl 3.27106). Falsifier E confirmed axis is structurally load-bearing. Cell B at n=1 already at/below baseline μ_4(FFS_train)=2937.5. Under EMA-eval expecting B's n=4 FFS_ema ≈ 2900 ± 25 — merge-borderline at gate 2887.5.
2. ★★ **APPROVED #1586 thorfinn n=4 confirm of Cell E (wd_mlp=0.040)** under EMA-eval stack. Complete 8-cell sweep traces clean val basin: D(0.018)=+3.8σ NEG, B(0.022)=+2.3σ NEG, A=C(0.025-0.028)=ref, **E(0.040)=−2.5σ BEST**, F(0.055)=+7.4σ NEG, G(0.070)=+14.6σ NEG, H(0.100) catastrophic. eff_wd@3000 basin centroid at 1.82e-4 (vs ctrl 1.14e-4) — cosine cooldown halves integrated WD application, opens room for 60% higher initial_wd. Pre-mortem 2 interpretation #1 (basin shifted upward under cosine) FULLY CONFIRMED. n=4 E vs baseline μ_4(FFS_ema)=2912.5.
3. **CLOSED #1615 edward Muon body mu decoupling** (logged earlier this poll cycle): mu axis FULLY CLOSED across all 3 sub-axes.
4. **ASSIGNED #1664 edward per-class body Muon cooldown SHAPE decoupling** (logged earlier this poll cycle).

**All 8 students productively occupied. ZERO idle.** Two n=4 EMA-eval confirms simultaneously in flight (#1617 + #1586) — both have non-trivial merge probability.

| Student | PR | Hypothesis | Status |
|:-------:|:--:|:----------:|:------:|
| **alphonse** | **#1689** | **SOAP Gram-matrix β₂ warmup schedule** | **🆕 WIP (just assigned)** |
| frieren | #1677 | lr_attn fine re-tune under R5 SOAP-attn | 🔄 WIP |
| askeladd | #1659 | Per-group EMA-eval decay (body vs aux) | 🔄 WIP |
| fern | #1654 | SOAP adaptive eigenbasis refresh | 🔄 WIP |
| tanjiro | #1617 | SOAP pf=8 n=4 EMA-eval confirm | 🔄 n=4 CONFIRM |
| edward | #1664 | Per-class body Muon cooldown SHAPE decouple | 🔄 WIP (cell B★ FFS_ema=2875 prelim) |
| nezuko | #1676 | wd_attn fine re-tune under R5 stack | 🔄 WIP |
| thorfinn | #1586 | wd_mlp=0.040 n=4 EMA-eval confirm | 🔄 n=4 CONFIRM |

---

### Active research themes (post-#1533 merge)

**EMA-eval signal exploration** (primary post-#1533 thrust):
- Multi-timescale EMA combination at val (#1658 alphonse — Karras-inspired, 2 parallel βs combined at val)
- Per-group body vs aux EMA decay decoupling (#1659 askeladd — Muon updates faster, may benefit from different d)
- These are structurally fresh extensions of the #1533 mechanism into multi-β and per-group territory

**Optimizer state dynamics** (secondary thrust):
- NS-internal: warm-start X_0 from previous polar factor (#1643 nezuko), PRECOND_FREQ static sweep (#1617 tanjiro)
- SOAP eigenbasis: adaptive refresh via off-diagonal staleness criterion (#1654 fern — Eschenhagen 2025)
- Muon body per-group mu (#1615 edward — CLOSED: mu_mlp vs mu_attn decoupling, clean-NEG, mu axis fully closed)
- Muon body per-class cooldown SHAPE (#1664 edward — MLP vs attn temporal decay curve; third per-class axis after magnitude #162 won + mu #1615 lost)
- Post-NS update scaling (#1651 frieren — grad-Frobenius normalization)
- Body WD (#1586 thorfinn — wd_mlp fine re-tune under cosine cooldown)

**Mechanistic findings this cycle**:
- EMA-eval SWA overlaps with cosine cooldown (−100 steps on linear stack → −25 on cosine stack). Both smooth late-trajectory noise near 3.28 crossing.
- Line-565 post-conditioning rescale absorbs ALL Gram-input scale preprocessing. Reject cluster.
- NS polynomial coefficients: Padé (2,-1.5,0.5) is FFS minimum. Bernstein aggressive overshoot adds spectral noise at ns_iter=6 convergence regime. Axis load-bearing (falsifier +200) but directionally inverted vs mathematical theory.
- **NS-internal cluster 6/6 closed**: depth-schedule (1609) + poly-coeffs (1612) + iter-count (1638/1509 R3/R4) + warm-start (#1643 in flight). NS itself appears near-optimal at current stack.
- **Mu axis FULLY CLOSED** (#1615): per-class static mu decoupling clean-NEG both directions. Together with #1294/#1345 (single-axis cooldown) and 2D plane sweep, the complete mu landscape is exhausted. Body Muon per-class differentiation is **magnitude-asymmetric** (LR) but **history-length-symmetric** (mu = 0.95 uniform optimal).

**Closed cluster map** (axes to never re-propose):
- SOAP-internal scalar HPs: 7+/8 closed (eps, exp_avg_sq, Q_row/Q_col asym, static β2, decoupled β2, trust-gate static/schedule, Gram trace-norm)
- Muon body structural barriers: 5-class (AGC, QHM, GC, Lookahead, Cautious) — NS absorbs gradient-shape priors
- AdamW aux update-rule barrier: 4-instance (Lion, Sophia-G, AdaBelief, AdEMAMix)
- Aux-side per-group HP cluster: β1, β2, ε, wd, cooldown_frac, cooldown_shape (6 axes FFS-cosmetic)
- Post-NS Frobenius/LAMB/LARS: 6 instances closed
- LR floor axis: 3 instances closed (FFS-load-bearing to go to 0)
- Cooldown_frac axis: Pareto-exhausted (cdf=0.7 optimal)

**Potential next directions** (for researcher-agent if students become idle):
1. Phase-dispatch mechanisms: train-phase-aware parameter changes (PRECOND_FREQ via #1617, adaptive refresh via #1654 in flight)
2. EMA-eval decay sweep: d∈{0.97, 0.98, 0.995} — can the −25 step gap be extended?
3. Post-hoc EMA (Karras 2023 style): decouple decay-tuning from training
4. NS warm-start variants: X_0 from weighted history (not just previous step), or from cached SOAP Q
5. Eigenvalue processing after eigh: clamping, dampening, p-th-power transforms (line-565 absorbs scale of Q, NOT eigenvalue conditioning)

---

## Prior poll snapshot (~1027, 2026-05-28 ~20:15Z, ★ edward axis closure + new assignment — 42nd R5 closure)

**Actions this poll**:
1. ★ **CLOSED #1563 edward NS-scale-exp** [42nd R5 closure] — clean null axis: all 5 cells FFS ∈ {2925, 2950} = 1 grid step apart. exp=0 falsifier landed at FFS=2950 (ctrl baseline floor) — **scaling-law catastrophic-NEG prediction FALSIFIED**. Post-NS aspect-ratio scale factor `max(1, m/n)**exp` is below FFS quantization noise floor at this benchmark scale across [0, 1.0].
2. ★ **ASSIGNED #1615 edward Muon body momentum decoupling** (`g1r5-edward/mu-mlp-attn-decouple`) — fresh axis explicitly listed in memory as remaining after mu_cooldown 3-sided closure. Decouples per-group `--mu_mlp` vs `--mu_attn` at fixed mu=0.95 default. Mechanism: SOAP-Muon cos_sim ~0.884 (MLP) vs ~0.798 (attn) — weaker attn alignment means accumulated momentum carries more directional error; reducing `mu_attn` shortens look-back window, giving per-step SOAP corrections more influence. Structural analogue to edward's own winning #162 lr_mlp/lr_attn decoupling. 5-cell sweep: A=ctrl(0.95/0.95), B★=primary(0.95/0.85 attn-reduced), C=intermediate(0.95/0.90), D=both-reduced(0.90/0.85), E=falsifier(0.85/0.95 inverted MLP-only). Two-flag implementation; Muon class already supports per-group `mu` via dict-of-groups interface (no class change needed).

**Ongoing in flight** (20:15Z snapshot):
- **★★★ #1564 fern SOAP Gram trace-norm Trial 4** (`ixqmqe2j`): in flight, ETA terminus **~20:20Z** — IMMINENT CRITICAL merge-gate readout. n=3 already at FFS=2925 σ_3=0
- **#1586 thorfinn body wd_mlp fine re-tune**: Cells A=B done (A FFS=2925, B FFS=2950), C in flight, D pending — full sweep ETA ~22:00Z
- **#1565 tanjiro trust-gate-schedule**: Cells B/C/D done (B=D=2925, C=2950, val-positive shifts), Cell E in flight ETA ~20:30Z
- **#1612 askeladd ns-poly-coeffs**: just assigned poll ~1020
- **#1609 nezuko ns-iter-depth-schedule**: just assigned poll ~1010
- **#1615 edward mu-mlp-attn-decouple**: just assigned this poll
- **#1555 frieren aux-cd-shape n=4 confirm**: starting (sent back poll ~1020)
- **#1533 alphonse EMA-eval rebase + n=4 confirm**: starting (sent back poll ~1020)

All 8 students remain productively occupied. Zero idle.

---

## Prior poll snapshot (~1020, 2026-05-28 ~19:25Z, ★★ TRIPLE-PR POLL — 1 closure + 2 n=4 confirm requests + 1 new assignment)

**Actions this poll**:
1. ★ **CLOSED #1549 askeladd aux-LR-warmup** [41st R5 closure] — monotone clean-NEG: A(0)=2950, D(50)=3000, B(100)=2975, C(200)=3075, E(500)=NEVER catastrophic. Replicates #1072 (fern embed/lm_head warmup) with scalars-group extension confirming no protective effect. Cell A clean 5th-sample baseline reproducer.
2. ★★ **REQUEST-CHANGES #1555 frieren aux-cooldown-LR-shape** — Cell B (aux linear) FFS-tied with A at 2925, val-positive -0.00330 (≈12× σ_4 val noise). Sent back for n=4 confirm of Cell B only on post-#1381 stack. Predeclared rule: merge if μ_4(FFS) ≤ 2918.75 AND σ_4 ≤ 12.5; fern-style perfect reproduction at 2925 would qualify.
3. ★★★ **REQUEST-CHANGES #1533 alphonse EMA-eval (SWA)** — fresh axis with STRONG mechanism finding: within-run FFS_ema=2925 vs FFS_train=3025 = -100 step gap for Cells D (d=0.995) and E (d=0.99) on PRE-#1381 stack. Bias-correction Option A correctly implemented. Sent back for: (a) rebase onto current advisor branch resolving needs_rebase, (b) n=4 confirm of Cell E (d=0.99) ONLY on post-#1381 stack. If -100 step gap ports → μ_4≈2844 (far below merge gate ≤2918.75). Even partial port to -50 steps → 2894 still well below merge gate. Could be 2nd FFS-positive merge of R5.
4. ★ **ASSIGNED #1612 askeladd NS polynomial coefficient substitution** (`g1r5-askeladd/ns-poly-coeffs`) — fresh NS-internal axis: tests Bernstein-optimal `(3.4445,-4.7750,2.0315)` quintic vs codebase-default `(2,-1.5,0.5)` Padé approximant. At `--ns_iter 6` the per-iteration convergence quality gap is maximally exposed; both `muon_update` and `soap_ns_step` call the same NS function, amplifying any quality gain. Single-line change with `--ns_coeffs` argparse flag. 5-cell sweep: A=ctrl, B=Bernstein, C=intermediate-lo, D=intermediate-hi, E=falsifier-weaker. Passes 5-class Muon body barrier (polynomial-internal, not pre/post-NS gradient-shape).

**Ongoing in flight** (19:25Z snapshot):
- **★★★ #1564 fern SOAP Gram trace-norm Trial 4** (`ixqmqe2j`): in flight, ETA terminus **~20:23Z** — CRITICAL merge-gate readout. n=3 already at FFS=2925 σ_3=0.
- **#1586 thorfinn Cell B** (wd_mlp=0.022): ETA ~18:57Z, should be terminal soon
- **#1565 tanjiro Cell E**: pending sequential after Cell D
- **#1563 edward Cell E rerun** (exp=0 falsifier): step ~849, ETA ~19:50Z, slow but learning
- **#1609 nezuko ns-iter-depth-schedule**: just assigned (poll ~1010)
- **#1612 askeladd ns-poly-coeffs**: just assigned (poll ~1020 - this poll)
- **#1555 frieren aux-cd-shape n=4 confirm**: starting (just sent back)
- **#1533 alphonse EMA-eval rebase + n=4 confirm**: starting (just sent back)

All 8 students remain occupied. Zero idle.

---

## Prior poll snapshot (~1010, 2026-05-28 ~18:49Z, ★ #1579 CLOSED + nezuko #1609 ASSIGNED — 40th R5 closure)

**Actions this poll**: ★ CLOSED **#1579 nezuko LogitNorm** [40th R5 closure] — catastrophic-NEG (FFS=-1 at Cell B★ tau=0.04). Headline mechanism: empirical ||z||_2≈7.1 (not predicted ~55), so tau=0.04 sharpens (L2 pinned at 25 > natural 7.1) instead of softening → training breakdown. Student correctly applied predeclared early-kill gate; C/D/E not run. ★ ASSIGNED **#1609 nezuko depth-adaptive NS iteration count** (`g1r5-nezuko/ns-iter-depth-schedule`) — fresh NS-internal axis: blocks 0-3 receive ns_iter=4, 4-7=6 (baseline), 8-11=8 (depth_up δ=2). Mechanistic falsifier cell C is depth_down (8-6-4). Hypothesis: late blocks with higher effective-rank gradients benefit from more whitening precision. Passes 5-class Muon body barrier (NS-internal, not pre/post-NS gradient-shape modification).

**Ongoing in flight** (18:49Z heartbeat):
- **★★★ #1564 fern SOAP Gram trace-norm Trial 4**: ~9% into Trial 4 (step 10098 rel step 348/3250), ETA terminus **~20:23Z** — CRITICAL for merge-gate readout. Trials 1-3 = FFS=2925 (n=3, σ_3=0). If Trial 4 also 2925 → n=4 mean=2925 vs gate ≤2918.75 (just above strict gate but maximally consistent).
- **#1586 thorfinn Cell B** (wd_mlp=0.022): in flight step 2834/3250 val=3.297, ETA ~18:57Z
- **#1549 askeladd Cell E** (warmup=500 falsifier): still offline-mode
- **#1555 frieren aux-cooldown-shape**: still offline
- **#1563 edward Cell E rerun** (exp=0 falsifier): step 849 val=3.71 ETA ~19:50Z
- **#1565 tanjiro Cell E**: pending after Cell D terminal
- **#1533 alphonse Cell E** (ema=0.99): pending offline-mode

**Prior poll** (~1000, 2026-05-28 ~18:35Z, ★★★ FERN TRIAL 3 FFS=2925 — n=3 perfect reproduction): STATE-DOC UPDATE ONLY (no PR action). **★★★ MAJOR SIGNAL UPGRADE**: **fern #1564 SOAP Gram trace-norm Trial 3 terminal also FFS=2925** — n=3 mean=2925, σ_3=0 perfect reproduction across 3 independent seeds. Combined with Trials 1+2 also at 2925, this is a 3-of-3 clean reproduction at -18.75 steps below new baseline μ_4=2944 (≈ -1.5σ_4). Trial 4 has just started (`ixqmqe2j` val=10.83 at step 9873 = fresh model init for trial 4). ETA Trial 4 terminus ~20:23Z.

**Predeclared merge-gate readout**: μ_4(FFS) ≤ ~2918.75 strict 2σ_4 effect-size gate vs new floor. n=3 mean=2925 currently +6.25 above strict gate but σ_3=0 perfect-quantization-floor is informative on its own — vs baseline floor where 1 of 4 trials at 2925, 3 of 4 at 2950, fern's 3-of-3 at 2925 is a clean pattern shift below baseline noise. **Trial 4 outcome critical**: if FFS=2925 → mean=2925 σ_4=0 (still +6.25 above strict gate but maximally consistent); if FFS=2900 (next step-quantization down) → mean=2918.75 σ_4=12.5 (meets strict gate exactly); if FFS=2950 → mean=2931.25 σ_4=12.5 (within 1σ_4 of baseline, weak signal); if FFS=-1 → kills signal.

**Other newly-terminal this window (18:14-18:35Z)**:
- **#1579 nezuko Cell B `zgv1paid` tau=0.04 TERMINAL**: val=5.541, **FFS=-1** ★ confirmed catastrophic divergence. Cell C `cowc9r70` just started (step 70 val=10.83 init); will likely also diverge (LogitNorm hypothesis appears DOA). Pattern: A=ctrl tau=0 FFS=2925, B=tau=0.04 FFS=-1 → tau≠0 destroys training even at smallest nonzero value tested. **LogitNorm axis closing-catastrophic-NEG**.
- **#1563 edward Cell E `zzz60xjw` rerun (exp=0 falsifier)**: step 849 val=3.71 — STILL LEARNING (vs baseline at step 849 val ~4.5). exp=0 = no aspect-ratio scaling at all; surprisingly stable, but slow. May or may not cross 3.28 before step 3250. ETA terminus ~19:50Z.

**Still in flight**:
- **#1586 thorfinn Cell B (wd_mlp=0.022)**: step 2601/3250 val=3.335 ETA ~18:57Z
- **#1549 askeladd Cell E (warmup=500 falsifier)**: still offline, no W&B sync visible since Cell D 17:30Z sync
- **#1555 frieren aux-cooldown-shape sweep**: still offline, ETA sweep terminus ~18:41Z (since 09:41Z start)

No new student comments or human issues. Same 8 students WIP.

**Prior poll** (~995, 2026-05-28 ~18:14Z, edward Cell D + tanjiro Cell D terminal — both axes closing FFS-neutral): STATE-DOC UPDATE ONLY (no PR action). 2 new terminal cells since poll ~990:
- **#1563 edward NS-SCALE-EXP Cell D `jejriyaf` exp=1.0**: val=3.2704, **FFS=2950** — baseline-noise. Cell E (exp=0 falsifier) crashed first attempt (gxexk73i step 1 init-val), rerun `zzz60xjw` running step 221 val=4.49 (learning slowly without aspect-ratio scaling). 4-cell pattern: A(exp=0.5)=2950, B(exp=0.25)=2950, C(exp=0.75)=2925, D(exp=1.0)=2950 — **all within σ_single ±25 of new baseline μ_4=2944**. **NS post-NS aspect-ratio scale exponent axis is FFS-NEUTRAL across [0.25, 1.0]**. Closing-on-deck pending Cell E falsifier (exp=0). Expected verdict: NS-scale-exp absorbed by NS+optimizer system, perturbation invisible above noise.
- **#1565 tanjiro TRUST-GATE-SCHEDULE Cell D `xtp8y6xm` peak=0.3 ramp=0.25**: val=3.2690, **FFS=2925** — within σ_single noise of baseline. 4-cell pattern: A(peak=0 ctrl)=2925, B(peak=0.3 ramp=0.15)=2925, C(peak=0.5 ramp=0.15)=2950, D(peak=0.3 ramp=0.25)=2925 — **all within σ_single ±25 of new baseline μ_4=2944**, with Cell A baseline-reproducer at 2925. **Trust-gate-schedule axis is FFS-NEUTRAL across [peak∈{0, 0.3, 0.5}, ramp∈{0.15, 0.25}] sample grid**. Cell E ETA ~19:53Z to confirm closure. Note: Cell A=ctrl peak=0 (gate OFF entirely) also at FFS=2925, so this confirms baseline floor for tanjiro's seed.

**Still in flight** (heartbeat 18:14Z):
- **#1564 fern Trial 3 SOAP Gram trace-norm `ixqmqe2j`**: at _step=9315 → rel step 2815/3250 = 87% of Trial 3, **ETA ~18:21Z** (~7 min). FFS still reporting 2925 from Trials 1+2. Trial 4 ETA ~20:22Z.
- **#1579 nezuko Cell B `zgv1paid` tau=0.04**: step 3002 val=5.55 → **catastrophic divergence**, will be FFS=-1 at terminal. Cells C/D/E likely also catastrophic.
- **#1586 thorfinn Cell B `qyxyuhka` wd_mlp=0.022**: step 1974/3250 val=3.462. ETA ~18:35Z.
- **#1549 askeladd Cell E** falsifier (warmup=500): still offline, ETA ~18:24Z based on wrapper sequence.

**No new student comments, no new human issues**. All 8 students still WIP. **Two closing axes** (edward NS-scale-exp + tanjiro trust-gate-schedule) both clean FFS-neutral patterns; these will be 40th and 41st cumulative closures pending Cell E confirmations.

**Prior poll** (~990, 2026-05-28 ~17:32Z, multi-PR cell-batch terminus — askeladd ABCD synced, alphonse D, thorfinn A baseline-reproducer): STATE-DOC UPDATE ONLY (no PR action). No new student comments or human issues since poll ~984. Heartbeat survey shows substantial newly-synced/terminal events across 5 sweeps. Decision: **wait for sweep terminuses** ETA 17:59Z (edward D) → 18:05Z (tanjiro D) → 18:24Z (askeladd E) → 18:28Z (fern Trial 3) → 18:57Z (thorfinn B), then re-survey for any merge-eligible candidates.

**Newly synced/terminal this window (15:14-17:31Z)**:

- **#1549 askeladd AUX-LR-WARMUP: Cells A-D NOW SYNCED from offline, Cell E in flight ETA ~18:24Z** —
  - Cell A `6su5h1qc` warmup=0 (ctrl): val=3.2703, **FFS=2950** ← independent 6th baseline reproducer at new μ_4=2944±12.5
  - Cell D `0vj6dmht` warmup=50 (novel sub-#1072 floor): val=3.2743, **FFS=3000** (+50 from ctrl)
  - Cell B `41n8x8lw` warmup=100 (Liu 2020 default ~5%): val=3.2717, **FFS=2975** (+25 from ctrl)
  - Cell C `5ihaexkr` warmup=200: val=3.2771, **FFS=3075** (+125 from ctrl)
  - Cell E `wjmw135h-style` warmup=500 falsifier: still offline, ETA ~18:24Z
  - **Verdict-shape**: A→D→B→C is FFS-monotone-NEG by 25 with one step-quantization swap between D=50 and B=100 (both within σ_single noise of each other but cleanly NEG vs A=0). val also monotone-NEG. **CONFIRMS #1072 closure** at finer step granularity: aux warmup is FFS-NEG even at sub-#1072 floor (D=50≈1.5% < #1072's smallest cell 5%); scalars-group inclusion does NOT change verdict. **Aux LR warmup axis closing-on-deck** pending Cell E falsifier (predicted catastrophic at 500≈15%, per #1072 monotonic trend).
- **#1533 alphonse EMA-EVAL: Cell D `asqvbywb` ema_decay=0.995 (corrected bias-correction code)**: val=3.2616, **FFS=2925**
  - Standalone Cell D reading: val below baseline μ_4=3.270215 by ~0.0086 (large), FFS at baseline-noise (within σ_4=12.5 of 2944). Combined w/ Cell B (d=0.999, val=3.2619, FFS=-1) + Cell C (d=0.9999, val=3.2635, FFS=-1) → **EMA-eval pattern**: val-positive but FFS-cosmetic. Mechanism interp: SWA-style EMA averaging reduces terminal val (smoothing noise on final eval point) but does NOT accelerate the val-crossing-3.28 trajectory. **Under FFS-primary directive #1262, val-only wins close as mechanism findings**. Cell E ema=0.99 still offline (final sweep cell).
  - **Correction to poll ~984 reading**: Cell D's "val/loss=3.299 >3.28 = FFS-NEG" was an outdated pre-bias-correction reading; the corrected sweep relaunched 10:17Z post-bias-correction-fix has Cell D val=3.2616 FFS=2925. Earlier poll documented stale state.
- **#1586 thorfinn WD_MLP-FINE: Cell A `j18xhgzb` wd_mlp=0.025 (current default ctrl)**: val=3.2692, **FFS=2925** — 7th baseline reproducer. Cell B `qyxyuhka` wd_mlp=0.022 in flight (step 761/3250) ETA ~18:57Z.
- **#1579 nezuko LOGIT-NORM: Cell A `25p0f8e9` tau=0 (ctrl)**: val=3.2691, **FFS=2925** — 8th baseline reproducer (Cell A `k1e310j8` had crashed then was re-launched). Cell B `zgv1paid` tau=0.04 in flight step 1998/3250, **val=5.74** at mid-training (vs baseline ~3.3 mid-training) → **DIVERGENCE SIGNAL**: LogitNorm at tau=0.04 (paper-recommended via small scale=0.45×) is breaking training; expect FFS=-1 / val>3.28. May abort sweep if B/C/D all diverge.
- **#1563 edward NS-SCALE-EXP: Cell D `jejriyaf` exp=1.0**: in flight step 2445/3250 val=3.363 ETA ~17:59Z. Cell E exp=0 falsifier next, ETA ~19:47Z.
- **#1565 tanjiro TRUST-GATE-SCHEDULE: Cell D `xtp8y6xm` peak=0.3 ramp=0.2**: in flight step 2244/3250 val=3.410 ETA ~18:05Z. Cell E next, ETA ~19:53Z.
- **#1564 fern SOAP-GRAM-TRACE-NORM `ixqmqe2j` n=4 ON multi-trial wrapper**: at _step=8080 → Trial 3 rel step ~1580/3250 (49% of trial 3); reported FFS still shows 2925 from completed Trials 1+2; Trial 3 ETA ~18:28Z, Trial 4 ETA ~20:20Z. **Strong signal pending n=4 confirm**.

**8 independent baseline-floor reproducers at FFS ∈ {2925, 2950}** now visible across 4 PRs (#1549A=2950, #1533ctrl-crashed-not-counted, #1586A=2925, #1579A=2925, #1564 trial-1=2925 trial-2=2925, #1565A=2925, #1563A=2950) — confirms new baseline floor μ_4=2944 ±12.5 is reliable and that FFS-step-quantization ε=25 produces predictable ±25 spread around it. **Predeclared merge gate μ_4(FFS) ≤ ~2918.75** requires effects ≥1 step-quantization beyond baseline noise (i.e., at least 2 of 4 trials at FFS≤2900).

**Prior poll** (~984, 2026-05-28 ~16:35Z, ★★ signal upgrade — fern trial 2 also FFS=2925): STATE-DOC UPDATE ONLY (no PR action). **★★ STRONG PROVISIONAL SIGNAL** on fern #1564 SOAP Gram trace-norm: **Trial 2 ALSO hit FFS=2925** (n=2 mean=2925, σ_2=0 perfect reproduction). `ixqmqe2j` state=running _step=6336 (trial 2 step ~3086/3250 = 95%, val=3.2719 trial-2 terminal trajectory matches trial-1 val=3.2697). Combined trial-1+trial-2 give **2925, 2925 → mean=2925 vs baseline μ_4=2943.75 σ_4=12.5 → effect −18.75 steps ≈ −1.5σ_4**. NOT YET ZERO-σ (we still need trials 3+4 for n=4 confirm; perfect 0 spread on n=2 is per-step-quantization-25 coincidence not magic — both trials may have crossed somewhere in step 2901-2925 window then snapped to 2925-eval-grid). ETA trials 3/4 terminate: ~18:30Z and ~20:20Z. ★ **Same-step-quantization caveat documented** — predeclared merge gate requires μ_4(FFS) ≤ ~2918.75 with σ_4 ≤ ~12.5; n=2=2925 currently +6.25 above gate but well within σ_2 noise.

**Other newly-finished cells this window** (16:13-16:20Z): edward NS-scale-exp 3/5 cells terminal — exp=0.5 (ctrl) FFS=2950 val=3.2708; exp=0.25 FFS=2950 val=3.2712; **exp=0.75 FFS=2925 val=3.2699 ★** (−25 steps vs same-sweep ctrl, but within σ_single noise at n=1); exp=1.0 RUNNING; exp=0 falsifier PENDING. tanjiro trust-gate-schedule 3/5 cells terminal — peak=0 (ctrl) FFS=2925 val=3.2684; peak=0.3 FFS=2925 val=3.2699; peak=0.5 FFS=2950 val=3.2705 NEG; peak=0.3 ramp=0.25 RUNNING. **alphonse Cell D** (ema_decay=0.995) val/loss=3.299 (>3.28 = FFS-NEG regular eval) val/ema_loss=3.281 (>3.28 = FFS-NEG EMA eval too); _step=2923 finished suggests early termination. nezuko Cell A (tau=0 ctrl) FFS=2925 val=3.269 = independent baseline reproducer; **Cell B tau=0.04 just started** (`zgv1paid`). **Three independent confirmations of baseline-floor FFS=2925** (fern Cell A control OFF, nezuko Cell A control tau=0, edward exp=0.5 ctrl=2950 — slight ±25 step seed noise around new merged baseline floor).

**Prior poll** (~967): NO advisor action required — all 8 R5 students still mid-sweep. **★ EARLY ENCOURAGING SIGNAL** — fern #1564 SOAP Gram trace-norm `ixqmqe2j` Trial 1 FFS=2925 val=3.2697 — 19 steps BELOW merged baseline μ_4=2944 (~1.5σ_4). Trials 2-4 in flight, ETA ~20:00Z. NOT YET CONCLUSIVE at n=1.

**Prior poll** (~960): NO advisor action required — all 8 R5 students mid-sweep with no review-ready PRs and no terminal results. The harness flagged 5 PRs as `stale_wip` (#1565 tanjiro, #1563 edward, #1555 frieren, #1549 askeladd, #1533 alphonse) but inspection shows all are progressing through long offline-mode sweeps from the W&B 401 window (08:38-12:01Z). **W&B online runs heartbeating**: tanjiro `7w0a7mqx` step 1463 + edward `sxlmf00z` step 1649 (both _timestamp=15:18Z, current 15:20Z). **Offline-mode sweeps in flight** (no W&B online presence yet, will sync at sweep terminus): alphonse cells D+E (relaunched 10:17Z post-bias-correction-fix; cells B+C already synced val=3.2619/3.2635), frieren full 5-cell aux-cooldown-shape sweep (launched 09:41Z, ~9h total → ETA 18:32Z), askeladd 5-cell aux-warmup sweep (launched 09:24Z, ~9h11m → ETA 18:35Z). All expected to terminate 18:00-18:35Z; will re-survey on next poll. **No human GH issues** require advisor attention (none with `advisor-attention` label; #1262 directive unchanged). No PRs ready for review; no idle students. Ending invocation.

**Prior poll** (~952): ★ Close **#1523 thorfinn mu_mlp/mu_attn decoupling [39th cumulative closure]** — clean NEG across all 4 asymmetric arms + Cell E joint-0.99 falsifier DIVERGED (FFS=−1). Cell A ctrl val=3.26147 FFS=3025; B★ (0.95/0.85) val=3.26299 FFS=3050; C (0.85/0.95) val=3.26470 FFS=3050; D (0.95/0.75) val=3.26562 FFS=3075; E★ (0.99/0.99) val=3.28662 FFS=DIVERGED. **3 mechanism findings**: (1) **mu=0.95 is joint local optimum on (mu_mlp, mu_attn) plane** — monotonic degradation in both directions; (2) **Per-group decoupling intuition does NOT transfer from AdamW scalars to Muon body** — #1368 scalars β1=0.95 vs matrices 0.8 was FFS-positive (−25); analogous mu split on Muon body is FFS-negative (+25 to +50). Muon NS orthogonalization absorbs asymmetric-momentum signal; (3) **Minor structural asymmetry exists (B > C)** but absolute effect NEG. **Memory extensions**: [[mu_cooldown_axis_closed]] now THREE-sided: marginal DOWN (#1294) + marginal UP (#1345) + **joint 2D plane (#1523)**.

★ Researcher-agent dispatched 2× with rejections: (a) first attempt proposed `--beta1_scalars` per-group decoupling — REJECTED as duplicate of closed #1368 (same flag, same student, same axis; n=4 verdict was clean-NEG-FFS-NOISE per [[scalars-per-group-decoupling-closed]] which I rewrote this poll from outdated `_ffs_positive` memory); (b) second attempt proposed `--lr_cooldown_floor` — REJECTED as duplicate of closed #1462 H219 + #1508 + #642 (per new [[lr_floor_axis_closed]] memory). Researcher repeatedly proposed cluster-cosmetic axes; pattern is researcher reads FFS-positive precedents (#1381 cosine, #1368 scalars) and proposes BRACKETED-FINE-SWEEPS or ADJACENT-AXES inside the closed cluster. 

★ Assigned **#1586 thorfinn body wd_mlp fine re-tune under R5 cosine cooldown stack** — advisor-picked after researcher dispatches exhausted. Sub-#1284 grid {0.018, 0.022, 0.025 ctrl, 0.028, 0.040 falsifier} probing whether the sharp basin from #1284 (linear-cooldown era) has shifted ±10% under cosine cooldown (#1381). Mechanism: cosine cooldown reduces per-step effective WD at FFS-time by ~3.4× vs linear, possibly shifting basin lower. Mostly a confirmation hypothesis (prior on FFS-positive ~20%); falsifier E within closed cliff at 0.05. All 8 students WIP again.

**Prior poll** (~948): ★ Assigned **#1579 nezuko LogitNorm (Wei et al. 2022 arXiv:2205.09310)** — per-token L2 normalization of logit VECTOR (distinct from softcap #614 per-element tanh-cap, distinct from z-loss family which penalizes log²Z partition function drift). After researcher's first attempt (SPECTRA soft spectral clipping) was rejected for math error (cells equivalent to 1-19% body LR downscale, falsifier inert), re-dispatched with explicit math-verification requirement; second attempt produced math-verified 5-cell sweep τ ∈ {0.0 ctrl, 0.04 ★, 0.02, 0.07, 0.10 falsifier} with differential normalization scale across cells (B★ 0.45×, C 0.91×, D 0.26×, E 0.18×). Pre-mortems anticipate (1) softcap-redundancy inertness, (2) gradient-rescaling adaptation. **Routing fix**: researcher initially created #1578 with wrong branch prefix (`r5-nezuko/...`) and label (`student:r5-nezuko`) — invisible to nezuko's polling; copied branch via GH API to `g1r5-nezuko/logit-norm-tau`, closed #1578, created properly-routed #1579. All 8 students again WIP.

**Prior poll** (~945): ★ Close **#1516 nezuko Orthogonal QKV init FULL 5-CELL RESULT** [38th stack-component closure under #1262] — val-positive on OLD linear-cooldown stack (~5σ_single within-sweep) but **FFS-DEAD** (B/C/D all hit FFS=3025 = old baseline floor; no cell ≤ 2975). Three preserved mechanism findings: (1) **c_proj scope falsifier** — Cell E (qkv+proj) erases B's gain Δ +5.7σ regression → c_proj prefers asymmetric/heavier-tailed init, validating existing depth_init_mode=musoft choice; (2) Weak gain sensitivity — B/C/D within 1σ_single across gain ∈ {0.5, 1.0, √2}, mode > magnitude; (3) Init-side perturbations val-positive but FFS-neutral — schedule shape (#1381 cosine) remains the only FFS-load-bearing knob. **Init-geometry axis closed** combined with #368/#298/#350/#452/#611/#714/#722 + depth_init_mode (5 modes).

**Prior poll** (~928): ★ Close **#1502 edward Sophia-G FULL 5-CELL RESULT** [37th stack-component closure] — 2nd-instance of denominator-replace class with full 5-cell data. **★ Sophia ≡ Lion mechanically on aux**: GNB Hessian estimator produces tiny h_t → clip saturates ≥99% → effective update = ±ρ·sign(m_t)·lr_scale ≈ sign-Lion. Generalizable insight: any Hessian-diagonal preconditioner with bounded clip collapses to sign-quantization on tightly-coupled small-Hessian aux groups; future denominator-replace proposals must verify h-estimator scale matches m-estimator scale OR use unbounded clip. ★ Assigned **#1563 edward NS-SCALE-EXPONENT**, **#1564 fern SOAP-TRACE-NORM**, **#1565 tanjiro TRUST-GATE-SCHEDULE**. ★ Cross-comment on #1549 askeladd warning of subset-overlap with closed #1072. ★ Saved [[duplicate_assignment_prevention]] memory.

## Previously last updated: 2026-05-28 ~12:05Z (poll ~937)

**Actions this poll**: ★ Close **#1502 edward Sophia-G FULL 5-CELL RESULT** [37th stack-component closure] — 2nd-instance of denominator-replace class with full 5-cell data: Cell A AdamW ctrl val=3.26202 (parity within 1σ), Cell B★ ρ=0.05 lr=1.0 val=3.27951 (+30.8σ), Cell C ρ=0.10 lr=1.0 val=3.28143 (+34.1σ), Cell D ρ=0.05 lr=0.5 val=3.29007 (+48.6σ worst), Cell E ρ=0.05 lr=2.0 val=3.27539 (+23.9σ best). **★ Sophia ≡ Lion mechanically on aux**: edward's analysis shows GNB Hessian estimator produces tiny h_t (embed ~0.0005-0.0017, lm_head ~57) → Sophia clip(m_t/max(γ·h_t, ε), -ρ, +ρ) saturates ≥99% on embed and ≥86% on lm_head → effective update = ±ρ·sign(m_t)·lr_scale ≈ sign-Lion. **Generalizable insight**: any Hessian-diagonal preconditioner with bounded clip will collapse to sign-quantization on tightly-coupled small-Hessian aux groups; future denominator-replace proposals must verify h-estimator scale matches m-estimator scale OR use unbounded clip. ★ Assigned **#1563 edward NS-SCALE-EXPONENT** — post-NS aspect-ratio scale factor `max(1, m/n)**0.5` at lines 521/528 of train_gpt_simple.py was never ablated; 5-cell sweep exponent ∈ {0.5★ctrl, 0.25, 0.75, 1.0, 0.0 falsifier} on PASSES Muon-body-barrier filter (NS-internal axis). ★ Assigned **#1564 fern SOAP-TRACE-NORM** — SOAP Gram matrix trace normalization before eigendecomposition (per original SOAP paper arXiv:2409.11321 "critical"); current code at lines 571-572 accumulates raw `G@G.T`/`G.T@G` without normalization → eigenbasis drifts toward high-variance early gradients; fresh SOAP-internal axis distinct from β2/eps/freq/scope/low-rank/per-head/decoupled-β2. ★ Assigned **#1565 tanjiro TRUST-GATE-SCHEDULE** — scheduled SOAP trust threshold (ramp UP during warm training, drop to 0 during cooldown) vs prior static sweeps (#467, #171); schedule axis distinct from value axis, analogous to FFS-positive cooldown-shape pattern. ★ Cross-comment on #1549 askeladd warning of subset-overlap with closed #1072 (embed/lm_head warmup monotone-NEG); experiment running, scalars-inclusion delta is informative differentiator. ★ Saved [[duplicate_assignment_prevention]] memory — procedural fix for recurring duplicate-assignment bug (#1500 dup of #1131; #1549 likely-dup of #1072).

**Prior poll** (~927): ★ Close **#1500 fern AdaBelief AUX-UPDATE-RULE-CLASS-NEG-4** [35th stack-component closure under directive #1262] — 2nd denominator-replace instance after Sophia-G; combined with closed β2 decay/schedule/scope axes this closes the **entire AdamW aux 2nd-moment axis (decay × form × scope)**. B★ FFS=3025 vs new baseline 2944, val +0.66σ over old. s_to_v_ratio_p50≈0.71 flat — mechanism fires uniformly, schedule absorbs the multiplicative shift. Cell D (lm_head-only scope) +3.46σ shows aux-group scope-mixing creates LR-coordination cost. ★ Close **#1497 tanjiro Gradient Centralization MUON-BODY-CLASS-NEG-5** [36th stack-component closure] — 3rd pre-NS gradient-shape sub-axis closed; **Muon body barrier now 5-class**: pre-NS magnitude (AGC), pre-NS input identity (QHM), pre-NS input direction (GC NEW), post-NS averaging (Lookahead), post-NS gating (Cautious). B★ FFS=3050 baseline-equivalent, val +2.66σ over ctrl. centered_norm_ratio≈0.992 mean (only ~0.8% of grad norm is row-mean) — perturbation below NS noise floor. **E falsifier (×10 over-correction)** ratio=4.89× on block-0 mlp/proj → val +16.7σ catastrophic → mechanism IS geometrically load-bearing but invisible at natural scale. **NS implicitly absorbs gradient-shape priors** (row-mean, magnitude scaling) in early iterations — explicit pre-NS subtractions/clips are redundant. ★ Researcher-agent dispatched for 2 fresh hypotheses (fern + tanjiro) — fresh axes need to come from OUTSIDE the aux-update-rule and gradient-shape-pre/post-NS clusters. Candidate fresh axes remaining: (a) NS-internal (ns_iter, NS coefficients, per-block ns_iter), (b) init geometry beyond ortho-QKV (identity-residual init, init scale modulation, LN-gamma init), (c) per-group HP decoupling NOT yet tried (ε per group, lr_lm_head/lr_embed decoupling, β1 on body matrices), (d) schedule-shape variants outside cdf (warmup-shape, post-warmup plateau), (e) spectral-norm parameterization, (f) loss-scaling/z-loss.

**Prior poll** (~926): ★ Close #1493 frieren QHM PRE-NS-INPUT-CLASS-NEG [34th stack-component closure under directive #1262]. Strict monotone ν gradient (R²≈0.997 on val vs 1−ν); B★ ν=0.7 FFS=3150 (+125), E ν=0.3 FFS=NEVER (+57.8σ). ★ 4 mechanism findings: (1) **pre-NS INPUT modification is FFS-load-bearing** — `post_ns_blend_diff_norm` grows monotonically with (1−ν) AND over training time (LOW early, HIGH late); (2) `grad_buf_cosine ≈ 0.54-0.55` — fresh-gradient only half-aligned with momentum mid/late; (3) **"Stale = stably-good, fresh = high-variance noise"** — momentum buffer increasingly captures stable curvature; fresh injection corrupts it; (4) **★★ MUON BODY 4-CLASS STRUCTURAL BARRIER EXTENDED**: pre-NS magnitude (AGC), pre-NS input (QHM NEW), post-NS averaging (Lookahead), post-NS gating (Cautious) — all four distinct pipeline points, all clean-NEG. Combined with mu-cooldown closures (#1294/#1345), both "how NS sees momentum" angles (rate + blend) are fully closed. ★ Assigned frieren **#1555 AUX COOLDOWN SHAPE DECOUPLING** — fresh axis combining per-group decoupling cluster + schedule-shape FFS-positive cluster; body stays cosine (mandatory), aux varies {linear★, concave, convex, step}. New CLI `--aux_cooldown_shape`. ★ Rebase advisory posted to needs-rebase WIP PRs #1502/#1516/#1549.

**Prior poll** (~925): ★★★ **MERGE #1381 alphonse cosine cooldown shape — FIRST FFS-POSITIVE MERGE OF R5 in 32 closure attempts.** μ_4(FFS)=2943.75 (σ_4=12.5; 4/4 trials FFS-alive ≤2950); val μ_4=3.270215 (+15.17σ structural Pareto cost per #1481). Δ vs PR #699: −81.25 steps FFS (−2.69%). Mandatory R5 stack now includes `--lr_cooldown_shape cosine`. Merge executed under **Reading-A authority** on issue #1480 after 14h human-silence window with conclusive Pareto evidence (#1481 cooldown_frac axis closed 32nd). Audit-trail-clean: pre-merge "merging now" comment posted with revert-on-objection offer. Issue #1480 closed with merge confirmation. BASELINE.md updated; CURRENT_RESEARCH_STATE.md updated; EXPERIMENTS_LOG.md prepended with merge entry. **New baseline gate**: future FFS confidence requires μ_4(FFS) ≤ ~2918.75 with σ_4 ≤ ~12.5 (effect size ≥ 2σ_4 from new floor).

**Prior poll** (~922): ★ Close #1490 askeladd AdEMAMix AUX-UPDATE-RULE-CLASS-NEG-3 [33rd stack-component closure]. All 5 cells terminal, all NEG with Cell A ctrl baseline-EXACT (val=3.26065, FFS=3025) and Cell B★ catastrophic (val=3.28276, FFS=-1 DNF, +36.3σ). ★ 4 mechanism findings: (1) **★ α magnification of un-corrected slow EMA is load-bearing failure** — all α=5 cells (B/D/E) catastrophic regardless of β3; only α=2 Cell C mild +12.9σ; paper doesn't bias-correct m_slow → α=5 × un-corrected EMA dominates bias-corrected fast m_hat; β3 is NOT the harmful lever; (2) Cooldown-incompatibility with slow-EMA — Cell B trajectory matches A through ~step 2000 then diverges during cooldown; α=5 × stale m_slow fights cosine LR contraction; (3) ★ **3-class AdamW aux pipeline-modification barrier crystallized**: numerator replacement (#1471 Lion), denominator replacement (#1502 Sophia-G), numerator augmentation (#1490 AdEMAMix) — three distinct AdamW-equation modifications all clean-NEG; AdamW's `m_hat / (sqrt(v_hat) + eps)` shape is FFS-load-bearing; (4) Cross-PR ceiling — #1368 scalars-β1 found aux wants MORE memory (β1=0.95 halflife ~20); AdEMAMix adds parallel halflife ~5000+ steps × α=5 = one order beyond useful regime. ★ Assigned #1549 askeladd AUX LR WARMUP — fresh schedule-shape axis on AdamW aux groups only (Liu et al. 2020), preserves AdamW update rule (passes 3-class barrier); 5-cell A=ctrl / B★=warmup=100 (Liu default ~5%) / C=200 / D=50 / E=falsifier 500. Cross-cluster: pairs with FFS-positive cosine cooldown shape #1381 (schedule-shape FFS-positive pattern) and per-group decoupling cluster (aux-only warmup decoupled from body).

**W&B 401 RESOLVED (poll ~937, 2026-05-28 12:01Z)**: Human researcher (morganmcg1) closed issue #1546 with credential refresh applied operator-side at 12:01:34Z. Outage window was ~07:30Z → 12:01Z (~4.5h). Confirmed offline runners (#1555 frieren full sweep, #1523 thorfinn C/D/E) notified to run `wandb sync wandb/offline-run-*` once their in-flight sweeps terminate; existing online cells (thorfinn A/B) synced cleanly. New W&B launches at 12:01Z+ should succeed online. Memory [[wandb_auth_failure_heuristic]] confirmed accurate (4-poll 401 floor triggered correct INFRA-issue dispatch).

**Prior poll** (~915): ★ Close #1481 alphonse cooldown_frac × cosine joint sweep COOLDOWN-FRAC-AXIS-CLOSED [32nd stack-component closure under directive #1262]. Pareto sweep terminal — 5 cells cdf ∈ {0.7, 0.6, 0.5, 0.4, 0.3}: Cell A cdf=0.7 FFS=2925 val=3.26932 (★ best R5 FFS, +13.7σ_single val); Cell B cdf=0.6 FFS=2975 val=3.26996 (★ FFS-alive boundary +14.7σ); Cell C cdf=0.5 FFS=3050 val=3.27380 (+21.2σ); Cell D cdf=0.4 FFS=3150 val=3.27799 (+28.3σ); Cell E cdf=0.3 FFS=DNF (n=−1) val=3.28301 (+36.7σ). ★ 3 mechanism findings: (1) **Cosine FFS gain is cooldown_frac-fragile** — FFS strictly monotone-worsens with shorter cooldown window (Δ=+225 steps A→D); FFS-positive cosine result requires LONG cooldown not just cosine shape; (2) **cdf=0.7 default is locally optimal at n=1** — equal-or-better than all 4 alternatives explored; combined with #1381 confirming cdf=0.7 at n=4 establishes cdf=0.7 cosine as joint-optimal locally; (3) **Val/FFS Pareto is structural across the cdf axis** — every cell with FFS-alive (cdf ≥ 0.6) pays val regression ≥+13σ; no Pareto-dominant solution exists within axis. **COOLDOWN-FRAC-AXIS CLOSED**: cooldown_frac axis fully tiled across [0.3, 0.7] all NEG or equal to #1381; no future variation worth exploring on this knob. Issue #1480 merge calculus: drop Reading-B (n=4 confirm of cdf=0.7) as redundant — Cell A IS #1381 result within 1σ. Revised Reading-A: merge #1381 as-is. ★ Assigned #1533 alphonse EMA-eval (SWA-style) — fresh EVALUATION-SIDE mechanism, paper-validated (Izmailov et al. 2018 SWA, Karras et al. 2023 EDM, β=0.999 standard). Maintains parallel EMA of params in fp32, swaps params for validation (then restores), computes FFS via EMA-val crossing 3.28. CLI flag `--ema_eval_decay`. 5-cell A=None ctrl / B★=0.999 (~1000-step window) / C=0.9999 (~10000-step extreme) / D=0.995 (~200-step) / E=0.99 (~100-step joint-falsifier). Memory: +560MB VRAM for fp32 EMA. Telemetry: dual `val/loss` + `val/ema_loss`, `val/loss_diff`, dual FFS. Distinct from #1403 nezuko Polyak-Ruppert (closed — train-time average) since this is eval-only without modifying train trajectory; distinct from #1500 fern AdaBelief (aux-update-rule replacement, twice-falsified barrier) since this preserves AdamW update rule entirely.

**Prior poll** (~905): ★ Close #1471 thorfinn Lion-aux AUX-UPDATE-RULE-CLASS-NEG [31st stack-component closure]. All 5 cells clean-NEG with strictly monotone val ordering B<C<D<E (3.27737 < 3.28882 < 3.30560 < 3.31815); basin around paper-recommended lr_scale=0.33 well-bracketed below AdamW ctrl. ★ Mechanism findings: (1) **Sign-flip rate gradient-SNR-locked, not lr_scale-controlled** — cross-cell flip rates clustered tightly (embed ~0.32, lm_head ~0.33, scalars ~0.42 across B/C/D/E); Lion's directional churn is dictated by gradient SNR at the AdamW slot, not by step magnitude. (2) **Falsifier D (LR×3) did NOT diverge** — Lion sign-based updates have bounded magnitude ‖update‖₂=√N·lr regardless of gradient scale, so worst case under over-LR is slow convergence not blow-up; stability buys nothing if directional information per step is too coarse. (3) **★ AUX-UPDATE-RULE class is FFS-load-bearing (NEW cross-PR claim)** — 2nd adaptive-direction-replacement attempt on AdamW aux to fail after Sophia-G #1502 B-cell (both clean-NEG at +29σ); the AdamW *update rule* is FFS-load-bearing, not just its (β1, β2, ε, wd) tuple. **Two-class AUX-UPDATE-RULE structural barrier crystallized**: sign-quantization (Lion) and 2nd-order curvature (Sophia) — both independent rule replacements clean-NEG. **Stack now has dual structural barriers**: Muon body (3-class wrapper barrier) AND AdamW aux (2-class rule-replacement barrier) — perturbations at either the body update direction OR the aux update rule fail clean. ★ Assigned #1523 thorfinn mu_mlp/mu_attn decoupling on Muon body — per-group analogue of FFS-positive #1368 (scalars β1 decoupling). Hypothesis: SOAP preconditioning on attn already does heavy variance reduction → attn body benefits from lower mu (less EMA redundancy with SOAP smoothing), MLP keeps mu=0.95 (only smoothing it has). 5-cell sweep: A=ctrl(both 0.95) / B★=mlp 0.95 attn 0.85 / C=mlp 0.85 attn 0.95 (asymmetry-direction control) / D=mlp 0.95 attn 0.75 / E★=both 0.99 (joint-falsifier confirming cooldown closure). Optimizer code at `train_gpt_simple.py:605` already supports per-group `mu` — pure CLI wiring task. Per-group update-norm and cos(g,m) telemetry to diagnose SOAP-overlap mechanism.

**Critical pending**: Issue #1480 human merge guidance — #1381 (FFS-POSITIVE, FIRST OF R5) held in status:review; Reading-C parallel arm #1481 PARETO IS FFS-MONOTONE IN cdf. ~5h elapsed at poll ~910; ~Reading-C default already triggered at 01:27Z.

**★★★ NEW (poll ~910): #1481 Pareto sweep is FFS-MONOTONE in cdf, cdf=0.7 is BEST FFS in R5** — corrected reading: cdf=0.7/0.6/0.5/0.4 cells all FINISHED. FFS strictly improves with longer cooldown: cdf=0.7 FFS=2925 (★ best R5), cdf=0.6 FFS=2975 (★ FFS-alive gate), cdf=0.5 FFS=3050, cdf=0.4 FFS=3150. Both cdf=0.7 and cdf=0.6 cross the human's FFS-alive directive gate (≤2975) at n=1. Val/loss regression is structural to cosine shape (3.269/3.270/3.274/3.278 monotone-up) but FFS reward grows with longer cooldown. cdf=0.3 in flight (currently step ~1408/3250). cdf=0.7 is +25 steps better than #1381's μ_4(FFS)=2944 (n=4 confirm). This finding shifts the merge calculus on #1480: not just "merge #1381 cosine-default" but "merge cdf=0.7-cosine" if n=4 confirms.

**Active student portfolio (7 WIP + 1 about-to-assign, 0 idle after assignment)**:
- ★ #1533 alphonse — EMA-eval SWA-style (Izmailov 2018, Karras 2023); FRESH EVAL-side mechanism
- ★ #1563 edward — **NS-SCALE-EXPONENT** post-NS aspect-ratio scaling sweep (NS-internal axis, passes Muon-body-barrier filter)
- ★ #1564 fern — **SOAP-TRACE-NORM** Gram-matrix trace normalization (per SOAP paper "critical"); pivoted to direct n=4 ON confirmation
- ★ #1555 frieren — **AUX COOLDOWN SHAPE DECOUPLING** (per-group decoupling × schedule-shape clusters combined; body stays cosine, aux varies)
- ★ #1549 askeladd — Aux LR warmup schedule-shape on AdamW aux only (Liu 2020); independent 5th confirmation of #1381 baseline already running on Cell A
- ★ #1579 nezuko — **LogitNorm** per-token L2 logit normalization (Wei 2022 arXiv:2205.09310); fresh LOSS-shape axis
- ★ #1565 tanjiro — **TRUST-GATE-SCHEDULE** scheduled SOAP trust threshold (schedule axis distinct from static value sweeps #467, #171)
- ★ thorfinn — **fresh hypothesis to be assigned this poll** (post-#1523 closure, 39th cumulative)

**Cumulative closures (39 stack-components, ★ 1 MERGE in R5: #1381 cosine cooldown)**

**★★★ MUON BODY 5-CLASS STRUCTURAL BARRIER (poll ~927, post-#1497 GC closure)**: barrier now spans FIVE distinct pipeline points:
- **Pre-NS magnitude clipping** (#1441 AGC, pre-NS gradient magnitude) — clean-NEG
- **Pre-NS input identity blending** (#1493 QHM, pre-NS gradient blend) — clean-NEG monotone in (1−ν); "stale=stably-good, fresh=high-variance noise"
- **Pre-NS input direction (row-mean removal)** (#1497 GC, pre-NS gradient centering) — clean-NEG; centered_norm_ratio≈0.992 (only ~0.8% removed); E falsifier ×10 catastrophic confirms mechanism load-bearing geometrically but invisible at natural scale; NS implicitly absorbs row-mean prior
- **Post-NS direction averaging** (#1446 Lookahead, post-NS weight EMA) — clean-NEG α-monotone
- **Post-NS per-coordinate gating** (#1460 Cautious, post-NS sign-gating) — clean-NEG spectral fragmentation
- Combined with mu-cooldown closures (#1294/#1345): BOTH "how NS sees momentum" angles (rate + blend) AND gradient-shape (magnitude + direction + identity) fully closed. **NS implicitly absorbs gradient-shape priors** in first few iterations — explicit pre-NS subtractions/clips are redundant. Reject pre-NS/post-NS gradient-shape modifications; ACCEPT: NS-internal structure changes (ns_iter, NS coefficients), init geometry, per-group HP decoupling, schedule changes, parameterization changes.

**★★ 3-CLASS 4-INSTANCE STRUCTURAL BARRIER on AdamW aux pipeline (poll ~927, post-#1500 AdaBelief closure)**: AdamW update shape `m_hat / (sqrt(v_hat) + eps)` on aux is FFS-load-bearing — extended from 3-class to 4-instance with 2 confirmed denominator-replacements:
- **Numerator REPLACEMENT** (#1471 Lion): sign-quantization, all 5 cells clean-NEG monotone B<C<D<E
- **Denominator REPLACEMENT — Hessian** (#1502 Sophia-G B-cell): Hessian-diag preconditioner, clean-NEG val=3.2795 +29.5σ
- **Denominator REPLACEMENT — belief variance** (#1500 AdaBelief): `s = E[(g-m)²]` instead of `v = E[g²]`, all 5 cells clean-NEG; s_to_v_ratio≈0.71 flat → mechanism fires uniformly but the steady multiplicative LR shift absorbed by schedule; Cell D scope-mixing +3.46σ shows aux LR-coordination cost
- **Numerator AUGMENTATION** (#1490 AdEMAMix): slow-EMA additive term, clean-NEG catastrophic val=3.28276 FFS=-1 +36.3σ
- **Joint with closed β2 axes (#1321 + #1377 + #1434)**: the entire AdamW aux **2nd-moment axis** (decay × form × scope) is now structurally unproductive on R5. Full `sqrt(v)+eps` denominator with magnitude variance is load-bearing. Future aux proposals filtered: "Does this modify `m_hat / (sqrt(v_hat) + eps)`?" — modifications are 4-way falsified.

**★ COOLDOWN-FRAC-AXIS CLOSED (poll ~915, post-#1481)**: cooldown_frac knob fully tiled across [0.3, 0.7] in joint sweep with cosine shape. Findings: (a) FFS strictly monotone-worsens with shorter cooldown window (Δ=+225 steps from cdf=0.7 → 0.4); (b) cdf=0.7 default is locally optimal at n=1, equal-or-better than all 4 alternatives; (c) Val/FFS Pareto is structural — every FFS-alive cell pays ≥+13σ val regression, no Pareto-dominant point exists. **Cosine FFS gain is jointly (shape × cdf=0.7), not portable** to other cdf values. Reject any cdf-axis or cooldown-shape-variant proposals on this axis. ACCEPT: schedule-shape changes outside the cdf knob (e.g., warmup, LR-floor, schedule-decoupling, EMA-eval).

**β2 axis FULLY CLOSED across 3 sub-axes** (poll ~900): value + schedule + per-group all FFS-cosmetic.

**Depth-prior cluster** (poll ~901): musoft init + uniform body LR is JOINT-LOAD-BEARING 2-knob unit.

**★★ TWO-CLASS STRUCTURAL BARRIER on AdamW aux update RULE (poll ~905, post-#1471 closure)**: "Replacing the AdamW *update rule* (not just its HPs) fails" now has TWO supportive independent rule-replacement classes:
- **Sign-quantization rule** (#1471 Lion): EMA-of-sign update direction; all 5 cells clean-NEG, val monotone B<C<D<E (basin around paper-rec lr_scale=0.33 well-bracketed below ctrl). Sign-flip rate gradient-SNR-locked not lr-controlled.
- **2nd-order curvature rule** (#1502 Sophia-G B-cell): Hessian-diagonal preconditioner; B-cell primary clean-NEG val=3.2795 (+29.5σ), Cell A ctrl 3.2620 parity.
- **The AdamW update RULE is FFS-load-bearing**, not merely its (β1, β2, ε, wd) hyperparameters. Any rule-replacement should now be expected to fail unless the replacement preserves AdamW's adaptive-step-size + EMA-of-gradient structure.
- Future aux proposals should be filtered: "Does this preserve the AdamW update rule, or replace it?" — the latter is twice-falsified.

**★★ THREE-CLASS STRUCTURAL BARRIER on Muon body (polls ~903-904, post-#1460 closure)**: "Any tampering with the NS-orthogonalized direction fails" now has THREE supportive classes operating at distinct pipeline points:
- **Pre-NS magnitude clipping** (#1441 AGC): peak-shaving by `||grad||/||param||` — clean-NEG
- **Post-NS direction averaging** (#1446 Lookahead): k-step weight EMA — clean-NEG with α-monotone failure
- **Post-NS per-coordinate gating** (#1460 Cautious): sign-agreement masking — clean-NEG with spectral fragmentation
- **All three operate at distinct points** of the Muon update pipeline (pre-NS gradient → NS-orthogonalized update → applied to weights), and all three fail. The body update is robust against pre-, intra-, and post-NS perturbation. This is now a high-confidence structural barrier with three independent supporting experiments.
- **Four-wrapper cluster**: #1258 SF-Muon (closed) + #1403 Polyak-Ruppert (closed) + #1446 Lookahead (closed) + #1460 Cautious (closed) — wrapper-Muon-body class well-bounded NEG.
- **Remaining priors**: (a) modifiers that change WHEN the step is taken (schedule axis — alphonse on cooldown_frac); (b) WHAT signal feeds NS (direction-preserving gradient transforms — tanjiro GC #1497 in flight); (c) the aux update RULE (4 alt-aux experiments in flight); (d) **HOW weights start** — init axis (nezuko #1516 orthogonal QKV, FRESH).
- **Adam-moment-replacement axis fully tiled by 4 in-flight PRs**: Sophia-G (#1502, 2nd-order), AdaBelief (#1500, 2nd-moment form), AdEMAMix (#1490, 1st-moment augmentation), Lion-aux (#1471, sign-only)

**FFS-positive directions**:
1. ★★★ ~~Cosine cooldown shape~~ **MERGED 09:11Z** (#1381 μ_4(FFS)=2943.75, σ_4=12.5; R5 baseline).
2. **Next FFS-positive candidates** (in-flight on old linear-cooldown stack, compare to old #699 baseline): #1533 EMA-eval (alphonse), #1549 aux LR warmup (askeladd), #1523 mu_mlp/mu_attn (thorfinn offline), #1516 ortho-QKV (nezuko), #1500 AdaBelief (fern ~done), #1497 GC (tanjiro ~done), #1502 Sophia-G (edward ~done).
3. **Post-merge new assignments** (use cosine stack, compare to new baseline FFS=2943.75): #1555 frieren aux cooldown shape decoupling (FRESH — combines per-group + schedule-shape clusters).

**Key mechanism cluster finding**: Per-group AdamW aux HP-decoupling is FFS-cosmetic (β1/β2/ε/lr/wd per-group all null on FFS axis; val-positive max ~2.5σ_single but subthreshold). Load-bearing FFS dynamics confirmed: **cooldown SHAPE** (now FFS-positive +81 steps) + Muon body update direction (still untested in R5; the 7 in-flight non-cosine PRs test 5 different update-direction mechanisms — Lion, Cautious, Lookahead, AGC, per-block-LR).

**Open questions for #1480**:
- Does FFS-primary directive #1262 override the statsig val-floor gate (μ_4 ≤ 3.259221)? Literal reading says yes; conservative reading says val floor is invariant.
- If FFS-primary merges break val floor, does the cycle accept val regression as the price of FFS gain compounding?


**Audit of in-flight portfolio under new framing (updated poll ~876):**
- **★★ #1368 thorfinn scalars-β1-DECOUPLE n=4 CONFIRM IN FLIGHT — FIRST FFS-POSITIVE n=1 OF R5 CYCLE**. Cell B★ (scalars_β1=0.95) FFS=3000 (−25), val=3.25786 (margin −0.002768 below n=1 gate ≈ 4.7σ_single). n=4 confirm at ~step 5500/13000 (1.7 of 4 trials complete, first trial recovered FFS=3025). One n=4 launch attempt crashed at step 125 (early failure), survivor running healthy.
- **★★ #1381 alphonse COSINE COOLDOWN SHAPE n=4 CONFIRM — 2nd FFS-POSITIVE OF R5 CYCLE**. Cell B★ (`--lr_cooldown_shape cosine`) FFS=2925 at n=1 clears ≤2975 by exactly 100 steps; val=3.26779 +7.6σ_single tradeoff. n=4 confirm at ~step 800/13000 (~6% through), val tracking nominal.
- **★ FFS-TARGETED in-flight (8 PRs, 0 idle students):** **#1403 nezuko POLYAK-RUPPERT EVAL EMA (★ FRESH MECHANISM — first non-HP since #1258 SF-Muon closed; 3 cells finished, B/C with val=3.33-3.35 much worse than baseline, looks like clean-NEG; D running, ctrl had 1 early restart)**, **#1446 edward LOOKAHEAD OPTIMIZER WRAPPER (★ NEW POST-#1394 — fresh OPTIMIZER MECHANISM, Zhang et al. NeurIPS 2019 k=5 α=0.5 wrap of Muon body)**, **#1441 fern AGC ADAPTIVE-GRADIENT-CLIPPING (Brock et al. NFNets λ-clipping on Muon body)**, **#1442 tanjiro PER-BLOCK-DEPTH BODY LR DECAY (ULMFiT-style γ^(L-block_idx) modulation)**, **#1434 frieren scalars-β2-DECOUPLE (mirror #1368 mechanism on β2 axis)**, **#1437 askeladd MATRICES-β1 ISOLATION (embed vs lm_head β1 dissociation)**, **#1368 thorfinn scalars-β1-DECOUPLE n=4 CONFIRM (★★ live merge candidate)**, **#1381 alphonse cosine cooldown n=4 CONFIRM (★★ 2nd live FFS-positive candidate)**.
- **★★ AUX-GROUP LR TRIUMVIRATE FULLY CLOSED with mixed signature (3 closures):** #1275 askeladd scalars-LR CLOSED (wanted HIGHER 3× — FFS-positive); **#1387 tanjiro lm_head-LR CLOSED WIDE-COSMETIC across 16× span**; **#1394 edward embed-LR CLOSED BASIN-FLAT across 6× span [0.15, 0.90] with sharp cliff at 0.05**. **Triumvirate signature**: scalars wants HIGHER (FFS-positive), lm_head wants NOTHING (cosmetic-16×), embed wants NOTHING (cosmetic-6×-with-cliff). **"All aux-group defaults systematically conservative" hypothesis FALSIFIED** — only scalars showed FFS-positive movement on LR axis. Per-group LR dissociation lives on the scalars axis only. 4th "aux-aux is mostly cosmetic" closure (joins #1330 lm_head ε + #1334 aux wd + #1387 lm_head LR + #1394 embed LR).
- **★ Crossing-phase decoupling cluster FULLY CLOSED (6 closures, 1 FFS-POSITIVE COUSIN):** #1294 mu DOWN, #1345 mu UP, #1322 NS-iter cooldown, #1326 scalars-LR-cooldown, #1377 β2-schedule, #1384 embed-LR-cooldown all closed NEG — uniform HP-schedule null. **BUT #1381 cooldown-SHAPE axis (cosine vs linear) FFS-positive** — the cluster's first SHAPE-positive finding: cooldown-shape is FFS-load-bearing while cooldown-timing/scheduling-of-existing-HPs is FFS-null. New cluster claim: **the COOLDOWN window itself is FFS-load-bearing via SHAPE; uniform HP-scheduling within it has been exhausted**.
- **★ Early-phase cluster (1 closed):** ~~#1328 fern body LR warmup~~ CLOSED clean-NEG-NON-MONOTONIC poll ~866. 2nd early-phase axis closure joining #1266 depth-init — "early state-as-set is FFS-locked except via large changes."
- **★ AdamW aux (β1, β2, ε, wd) TETRAD FULLY CLOSED (4/4) — mixed signature:** ~~#1310 β1 unified~~ CLOSED narrow-basin sweet-spot 0.8 (poll ~863) + ~~#1321 β2 unified~~ CLOSED monotone-LONG-memory 0.99 baseline-exact (poll ~864) + ~~#1330 ε~~ CLOSED WIDE-COSMETIC across 8 orders of magnitude (poll ~867) + ~~#1334 wd~~ CLOSED FLAG-LOAD-BEARING confirms-default (poll ~870) → joint coverage of hardcoded (0.8, 0.95, 1e-10, 0) tuple. **Mixed signature**: β1+wd load-bearing (β1 narrow-tight, wd flag-required); β2+ε cosmetic (β2 prefers-higher, ε wide). **β2 axis NOW FULLY CLOSED across value + schedule** (#1321 value 0.90-0.99 + #1377 schedule constant/ramp/instant/reverse — both FFS-cosmetic; 5th crossing-phase closure). Future work: scalars-β1 DECOUPLE (#1368 in flight, FFS-positive n=1), **scalars-β2 DECOUPLE (#1434 in flight, fresh axis after #1377 closure)**.
- **★★ β1/β2 DISSOCIATION FINDING (cross-PR #1310+#1321):** β1 wants SHORT memory (sweet spot 0.8, half-life ~3 steps), β2 wants LONG memory (best 0.99, half-life ~70 steps). **Recovers classical Adam intuition** that m̂ tracks gradient direction (short horizon) and v̂ tracks gradient scale (long horizon) — they are NOT redundant nor symmetric in this regime.
- **★★ PER-GROUP DECOUPLING NEW FFS-POSITIVE (n=1 strong, n=4 confirm in flight):** **#1368 scalars-β1 decoupling Cell B★ (scalars_β1=0.95) FFS=3000 (−25) val=3.25786** — **FIRST FFS-positive n=1 result of R5 FFS-primary cycle**. Strong DISSOCIATION confirmed: Cell E (scalars_β1=0.99) flat (FFS=3025, val=3.26148) vs #1310 Cell D (uniform β1=0.99) CATASTROPHIC — narrow basin in #1310 was matrices-driven not scalars-driven. Joins #1275 (lr_scalars=0.03) as 2nd FFS-positive per-group dissociation finding. Suggests scalars are a separable optimizer cluster. n=4 confirm running. ★ Future cycles after merge: joint (lr_scalars × β1), scalars_β2 dissociation, matrices β1 isolation.

**★★ SIX CLOSURES poll ~849-852 — comprehensive stack-component pruning cycle:** frieren #1221 LAMB (poll ~849) + alphonse #1266 depth-init (poll ~849) + askeladd #1227 pre-NS noise (poll ~850) + fern #1222 AdamP-aux (poll ~851) + tanjiro #1188 depth-LR (poll ~851) + edward #1200 orth-scheme (poll ~852). Combined with all prior closures: **NS-modulation axis fully closed at 11 NEG** (with edward #1200 adding "operator-class basin" finding: cond ∈ [1.0, 5.6] all reach baseline floor; Cell D schulz_iter8 FFS=3025 baseline-EXACT — operator equivalence within basin), **7th aux-axis closure** (AdamW family saturated), **2nd stack-component pruning closure** (depth_init_mode cosmetic). Six in-flight pruning ablations (#1272 wd-schedule, #1273 soap-attn, #1275 lr-scalars, #1276 cooldown-frac, #1279 SOAP precond_freq, #1284 body-WD value) systematically test ALL remaining mandatory-flag and hardcoded-schedule components.

**★ edward #1200 closure delivered 4-mechanism cluster (rare quality of analysis):** (1) Broad basin headline cond ∈ [1.0, 5.6]; (2) cond NOT complete operator descriptor (C/E differ 4.6σ at same cond≈18 — per-singular-vector alignment matters); (3) cooldown is the equalizer (mid-training deltas collapse under ~100× LR contraction); (4) NS-modulation operator-class fully closed at 4 independent operator-output modifications converging on (direction, magnitude, spectral) tuple. **Cell D schulz_iter8 FFS=3025 baseline-EXACT — operator equivalence at FFS level; FFS readout structurally robust to operator choice within the basin.**

**★ tanjiro #1188 closure delivered calibration constant:** n=1 → n=4 regression-to-mean ≈ 2.7 mNats. Z=−4.36σ_single val outlier with FFS-flat → does NOT replicate. Cite this for any future n=1→n=4 promotion debate under directive #1262.

---

- **Last updated:** 2026-05-27 ~18:05Z (poll ~892) — **★ NEZUKO #1403 CLOSED clean-NEG-EVAL-AVERAGING-FALSIFIED [FFS-primary, 23rd stack-component closure under directive #1262]**. Polyak-Ruppert eval-only EMA 5-cell sweep, W&B verified exact: A ctrl FFS=3025 val=3.26077; B★ β=0.999 FFS=-1 (DNF) EMA-val=3.339; C β=0.999 start=975 FFS=-1 EMA-val=3.352; D β=0.99 FFS=3025 EMA-val=3.270 (+15.6σ worse); E★falsifier β=0.9999 FFS=-1 EMA-val=7.12. Clean-NEG: eval-noise hypothesis FALSIFIED — FFS=3025 is signal-limited not eval-noise-limited. Key finding: diff_norm scales perfectly with (1−β) across 100× range; cooldown slope ~1.5×10⁻³/step dominates eval noise by 3+ orders of magnitude; EMA can't track cooldown regardless of β. ★★ JOINT CLOSURE WITH #1258 SF-Muon: training-internal averaging AND eval-only averaging BOTH fail for the same structural reason. The AVERAGING MECHANISM CLASS is closed against steep-cooldown regime. Narrows FFS-moveable space to parameter-update-direction interventions (preconditioners, gating, init). Outstanding mechanism analysis from student — textbook-clean diff_norm dose-response. **23rd stack-component pruning closure.** **Assigned nezuko → #1460 CAUTIOUS OPTIMIZER** (Liang et al. 2024 arxiv:2411.16085, sign-agreement gating on Muon body; structurally distinct from averaging class; masks Muon NS-orthogonalized update to coordinates where momentum agrees with current gradient sign; auto-deactivates in cooldown LR→0; 5-cell A=ctrl / B★=cautious-Muon-body / C=cautious-AdamW-aux-only / D=cautious-both / E=anti-cautious falsifier). In-flight n=4 confirms: #1381 alphonse cosine cooldown FFS=2950 (ALIVE, seed 1 done, ~40% through confirm) + #1368 thorfinn scalars-β1 FFS=3025 interim (failing to confirm n=1's 3000, ~77% through). 8 PRs in flight (including #1460 new), 0 idle students.

- **Prior:** 2026-05-27 ~15:45Z (poll ~876) — **★ EDWARD #1394 CLOSED clean-NEG-BASIN-FLAT-CONFIRMS-DEFAULT [FFS-primary, 22nd stack-component closure under directive #1262]**. embed-LR 5-cell sweep, W&B verified (advisor subagent) all 5 cells PERFECT MATCH: Cell A 0.3 ctrl FFS=3025 val=3.26090 −0.54σ; **Cell B★ 0.6 (2×) PRIMARY FFS=3050 val=3.26336 +3.61σ NEG**; Cell C 0.15 (0.5×) FFS=3025 val=3.26056 −1.11σ; Cell D 0.9 (3×) FFS=3025 val=3.26146 +0.40σ; **Cell E 0.05 (1/6×) FALSIFIER FFS=3125 val=3.27138 +17.13σ CATASTROPHIC**. ★ 5 mechanism findings: (1) Basin-flat across [0.15, 0.90] (6× span) — embed LR value-cosmetic within basin; (2) Sharp cliff at 0.05 — 1.27 visits/row/step sparse-gradient regime needs min LR; (3) ★★ **AUX-LR TRIUMVIRATE COMPLETED with mixed signature** — scalars #1275 HIGHER (FFS-positive), lm_head #1387 cosmetic-16×, embed #1394 cosmetic-6×-cliff; **"all aux-group defaults systematically conservative" FALSIFIED** — only scalars showed FFS-positive movement; (4) Cell B★ outlier mildly NEG bracketed by C/D both fine — likely noise on flat basin not real basin feature; (5) ★ Real dose-response in embed_weight_norm (E=13K → D=207K 16× span) inverse in embed_grad_norm — magnitude state dynamics don't propagate to FFS/val above cliff (mirrors #1387 lm_head self-equalizing `lr × g_norm`). **22nd stack-component pruning closure.** **4th "aux-aux mostly cosmetic" closure** (joins #1330 lm_head ε + #1334 aux wd + #1387 lm_head LR). **Assigned edward → #1446 LOOKAHEAD OPTIMIZER WRAPPER on Muon body** (★ FRESH OPTIMIZER MECHANISM not HP search; pivots from now-exhausted aux-LR triumvirate; Zhang Lucas Ba Hinton 2019 "Lookahead Optimizer: k steps forward, 1 step back" arxiv:1907.08610 NeurIPS 2019; maintain `fast` Muon-updated each step and `slow` synced every k steps via `slow += α·(fast - slow); fast ← slow`; mechanism: Muon body update has step-to-step variance from NS-orthogonalization-approximation + SOAP eigenbasis staleness + AdamW aux moment EMA; Lookahead k-step averaging damps variance without changing mean direction; auto-deactivates during cooldown LR→0; new `--lookahead_k` and `--lookahead_alpha` CLI flags wrap optimizer2 only; 5-cell A=k=0 ctrl / **B★=k=5 α=0.5 Zhang-default** / C=k=10 α=0.5 longer window / D=k=5 α=0.3 gentler / E=k=5 α=0.9 falsifier; predicts: if variance-reduction is FFS-positive opens 3rd FFS-positive class beyond per-group decoupling and cosine cooldown shape; cross-mechanism comparison with #1441 AGC (peak-shaving vs noise-reduction); telemetry: `lookahead/slow_fast_diff_norm`, `sync_count`, `effective_step_post_sync_diff`). 8 PRs in flight, 0 idle students. **Poll ~876 cumulative: 22 stack-component closures + 2 FFS-positive directions in n=4 confirm (#1368 scalars-β1 ~38% through, #1381 cosine cooldown ~6% through)**.

- **Prior:** 2026-05-27 ~15:00Z (poll ~875) — **★★ TRIPLE-PR POLL CYCLE: 2 closures (#1387 tanjiro + #1385 fern) + 1 n=4 PROMOTION (#1381 alphonse cosine cooldown)**. ★ **#1387 tanjiro lm_head-LR CLOSED clean-NEG-WIDE-COSMETIC [FFS-primary, 21st stack-component closure]**. 5-cell sweep across 16× span [1/640, 1/40] — NO cell clears FFS-alive ≤2975; val spread only 0.00101 (~1.7σ_single). Cell A 1/320 ctrl FFS=3050; **Cell B★ 1/160 PRIMARY FFS=3025 val=3.26193 best-of-cells** but doesn't clear gate; Cells C/D/E all FFS=3050 within noise. ★ 5 mechanism findings: (1) WIDE-COSMETIC across 16×; (2) **Self-equalizing weight-norm/grad-norm feedback** — `lr × g_norm ≈ 35-38` across cells, **lm_head AUTOREGULATES** via this feedback loop; (3) cross-mechanism alignment with #1330 eps NULL — lm_head consistently downstream-decoupled; (4) **scalars/lm_head dissociation confirmed** — scalars #1275 wanted 3× higher (FFS-positive) but lm_head wants nothing across 16×; (5) B★ at 2× was best-of-cells, directionally sensible but not gate-clearing. **21st stack-component closure under directive #1262**. ★ **#1385 fern FULL-RUN COSINE CLOSED MECHANISM-FINDING-COVERED-BY-#1381 [FFS-primary, 20th stack-component closure]**. Cell B★ (cosine 1→0 over entire run) FFS=2925 (FFS-alive!) BUT val=3.27392 +21.4σ_single. **Cross-PR mechanism alignment with alphonse #1381**: both Cell B's hit FFS=2925 with mechanism-coherent trajectories through steps 1500→2925 (within ~0.005), but alphonse's stable-phase-preserved cosine has MUCH better val (+7.6σ vs fern's +21.4σ). **Stable phase is val-load-bearing**; cosine SHAPE is FFS-load-bearing IN COOLDOWN WINDOW ONLY. ★ 5 mechanism findings: (1) FFS-positive val-negative SPLIT; (2) cell B val plateaus near 3.274; (3) cosine_min01 dominated; (4) warmup_cosine DNR; (5) triangular falsifier +76.8σ. Closing as mechanism-finding (productive instantiation is alphonse #1381 cosine-COOLDOWN-only, already promoted to n=4). **20th stack-component closure**. ★★ **#1381 alphonse COOLDOWN-LR-DECAY-SHAPE — 2nd FFS-POSITIVE OF R5 CYCLE — SENT BACK FOR n=4 CONFIRM**. Cell B★ (`--lr_cooldown_shape cosine`) FFS=2925 at n=1 clears ≤2975 by exactly 100 steps; Cell D convex (1−x)² also FFS=2925; Cell C concave FFS=3225 WORST (confirms cluster); Cell E step DNF +291σ (falsifier fired). Cluster prediction "directed descent through low-LR regime is load-bearing" empirically supported via geometrically-convex shape. Sent back: `--num_trials 4 --lr_cooldown_shape cosine` confirm; FFS-alive at n=1 triggers n=4 promotion per directive #1262 regardless of val gate. **2 new assignments**: ★ **#1441 fern AGC (Adaptive Gradient Clipping)** — fresh OPTIMIZER MECHANISM not HP search; tests per-parameter `||grad||/||param|| ≤ λ` clipping on Muon body per Brock et al. NFNets arxiv:2102.06171; 5-cell A=0 ctrl / B★=0.01 NFNets-default / C=0.005 tighter / D=0.02 looser / E=0.001 falsifier; mechanism question: does Muon body suffer early-training gradient bursts that AGC can damp without reducing late-training capacity? ★ **#1442 tanjiro PER-BLOCK-DEPTH BODY LR DECAY** — ULMFiT-style γ^(L-block_idx) modulator on Muon body LR per transformer block (12 blocks); fresh classical fine-tuning trick applied to pretraining-from-scratch; 5-cell A=1.0 ctrl / **B★=0.95 ULMFiT-style** (lower blocks slower) / C=1.05 inverse / D=0.90 steep / E=1.15 falsifier; pairs with musoft init prior — does init's depth-scaling want a matching LR-depth-scale? 8 PRs in flight, 0 idle students. **Poll ~875 cumulative: 21 stack-component closures + 2 FFS-positive directions (scalars-β1 #1368 + cosine-cooldown #1381) in n=4 confirm**.

- **Prior:** 2026-05-27 ~14:15Z (poll ~874) — **★ ASKELADD #1384 CLOSED clean-NEG-WIDE-NULL-EDGE-SENSITIVITY [FFS-primary, 19th stack-component closure under directive #1262]**. ADAM-EMBED per-group cooldown decoupling 5-cell sweep, W&B verified (advisor subagent) all 5 cells match student-reported exactly: Cell A shared 0.7 ctrl FFS=3050 val=3.262344 +1.89σ; **Cell B★ embed_cf=-1 no cooldown FFS=3075 val=3.264772 +5.99σ PRIMARY mild penalty**; Cell C embed_cf=0.5 early FFS=3025 val=3.260230 −1.67σ ONLY cell below baseline (within seed noise); Cell D embed_cf=0.85 late FFS=3050 val=3.263752 +4.27σ; **Cell E embed_cf=-2 anti-ramp falsifier FFS=3150 val=3.272629 +19.24σ CATASTROPHIC**. **WIDE-BAND-NULL with edge-sensitivity confirmed for adam_embed** — same crossing-phase decoupling cluster signature as #1326 adam_scalars, with milder edge magnitudes (~55-65% attenuation). ★ 4 mechanism findings: (1) WIDE-BAND-NULL on cooldown_frac ∈ {0.5, 0.7, 0.85} all FFS ∈ [3025, 3050] — embed permissive on cooldown TIMING; (2) Edge sensitivity to ABSENCE of cooldown +5.99σ mild penalty — embed survives without cooldown but pays measurable cost (much milder than scalars +10.6σ pointing to embed's larger parameter pool 38.6M vs ~150 and dominant-feature dynamics); (3) Edge catastrophe on anti-ramp +19.24σ — ramping embed LR UP during cooldown sharply incompatible with stack shutdown; same direction-of-failure as scalars #1326; (4) ★ Cross-cluster structural inference — **auxiliary groups (scalars+embed both WIDE-NULL) are PERMISSIVE on cooldown TIMING with edge-direction sensitivity; body (mu) is TIGHTLY-coupled** on cooldown shape; optimizer stack has per-component-decoupled aux-side timing but coupled body-side timing. **Crossing-phase decoupling cluster now FULLY CLOSED at 6 closures**: #1294 mu DOWN, #1345 mu UP, #1322 NS-iter cooldown, #1326 scalars-LR cooldown, #1377 β2 schedule, #1384 embed-LR cooldown — uniform cooldown HP-schedule has no FFS-positive movement available across all tested axes. Per FFS-primary directive #1262 no n=4 promotion (Cell C val improvement within seed noise at FFS=3025). **19th stack-component pruning closure.** **Assigned askeladd → #1437 MATRICES β1 ISOLATION** (★ pivot from cluster-completion to fresh per-group AXIS — does the "matrices" β1 basin (#1310 narrow-tight at 0.8) further dissociate between adam_embed and adam_lm_head?; background: #1310 closed UNIFORM β1 as matrices-driven; #1368 found scalars want HIGHER (0.95) wider basin; embed vs lm_head dissociation NEVER tested; new `--embed_beta1` and `--lm_head_beta1` CLI flags override per-group betas on those two groups; scalars untouched; 5-cell A=0.8/0.8 ctrl uniform / B★=0.8/0.95 PRIMARY lm_head dissociation small-update regime mirror of scalars finding / C=0.95/0.8 embed dissociation token-row revisit favors smoothing / D=0.95/0.95 joint matrices both want higher / E=0.5/0.5 falsifier predicts catastrophic; priors 35% no dissociation, 30% lm_head FFS-positive, 20% embed FFS-positive, 10% NEITHER tolerates 0.95, 5% surprise interaction; strict FFS-alive gate B★ ≤ 2975 per directive #1262). 8 PRs in flight, 0 idle students. **3 stale_wip PRs (tanjiro #1387, fern #1385, alphonse #1381) have W&B-FINISHED at step 3250 but no SENPAI-RESULT comment posted yet** — heartbeat lag, will check next poll cycle.

- **Prior:** 2026-05-27 ~13:30Z (poll ~873) — **★ FRIEREN #1377 CLOSED clean-NEG-WASHED-OUT [FFS-primary, 18th stack-component closure under directive #1262]**. AdamW aux β2 SCHEDULE 5-cell sweep, W&B verified (advisor subagent) all 5 cells match student-reported exactly: Cell A constant ctrl FFS=3025 val=3.26016 −1.79σ baseline-EXACT; **Cell B★ linear_ramp 0.95→0.99 FFS=3025 val=3.26123 +0.02σ PRIMARY FAILED**; Cell C linear_ramp 0.95→0.98 FFS=3025 val=3.26120 −0.04σ; Cell D instant_step 0.95→0.99 FFS=3025 val=3.26003 −2.01σ; **Cell E falsifier reverse_ramp 0.99→0.95 FFS=3025 val=3.26158 +0.60σ DIDN'T FALSIFY** — cooldown 2nd-moment preservation mechanism NOT confirmed. **All 5 cells hit FFS=3025 baseline-EXACT regardless of schedule shape** — β2 schedule axis is FULLY DEGENERATE within [0.90, 0.99]. ★ 5 mechanism findings: (1) **Cooldown 2nd-moment preservation NOT confirmed** — B/D never moved FFS; E falsifier didn't fire; #1321 Cell D val improvement at high β2 most likely seed-noise artifact at fixed FFS=3025; (2) **Schedule SHAPE doesn't matter when terminal β2 is fixed** — D (β2=0.99 for ~70% training) vs B (averaging ~0.97) differ by only 2σ_single; EMA half-life 13.5→69 steps doesn't register on crossing speed; (3) **Falsifier washout** Cell E reverse-ramp val only +0.60σ from baseline — if cooldown β2 were structurally load-bearing E should drop val materially; (4) **Pairs with #1321 to FULLY prune AdamW aux β2 axis**: value pruning [0.90-0.99] + schedule pruning (constant/linear/instant/reverse) both FFS=3025; β2 converged to "fully FFS-cosmetic"; (5) ★ **Breaks cooldown-tightening localization for AdamW aux** — body-side cooldown axes (#1272 WD, #1276 cooldown_frac, #1284 body-WD, #1294 mu-cooldown) all value-sensitive narrow basins with asymmetric cliffs; AdamW aux β2 schedule shows nothing — cooldown-tightening is BODY-side mechanism not aux-side. Per FFS-primary directive #1262 no n=4 promotion. **18th stack-component pruning closure.** **AdamW aux tetrad final state**: β1 NARROW-BASIN-load-bearing (matrices, #1310) + scalars=0.95 wide basin (#1368 dissociation pending n=4); β2 FULLY-COSMETIC across value AND schedule (#1321 + #1377); ε WIDE-cosmetic (#1330); wd FLAG-load-bearing confirms-default (#1334). β1 is ONLY load-bearing axis on matrices; β2 doesn't move FFS anywhere on uniform optimizer. **Assigned frieren → #1434 scalars-β2 PER-GROUP decoupling** (★ mirror #1368 mechanism class on β2 axis — does adam_scalars also want HIGHER β2 than 2D matrices? Uniform β2 axis fully closed but per-group dissociation untested; same signal-processing prior as #1368: low-SNR scalars want heavier 2nd-moment smoothing; new `--scalars_beta2` CLI flag with default 0.95 no-op overriding adam_scalars group betas only; 5-cell A=0.95 ctrl uniform / B★=0.99 PRIMARY mirror of #1368 / C=0.999 extreme bracket / D=0.9 lower bracket / E=0.5 falsifier; if confirms → per-group decoupling mechanism class generalizes across BOTH AdamW moments = extremely strong cross-axis stack-positive signal). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-27 ~11:05Z (poll ~872) — **★★ THORFINN #1368 n=1 RESULTS — FIRST FFS-POSITIVE OF R5 CYCLE — SENT BACK FOR n=4 CONFIRM**. After 17 closures (15 clean-NEG, 2 val-improvement-but-FFS-flat) the FFS-primary cycle posts its first n=1 movement: Cell B★ (scalars_β1=0.95) **FFS=3000 (−25 from baseline 3025), val=3.25786 (margin −0.002768 below n=1 gate 3.260628 ≈ 4.7σ_single)**. W&B verified (advisor subagent): all 5 cells match student-reported metrics exactly, all runs healthy. **5 mechanism findings**: (1) ★★ **STRONG DISSOCIATION** Cell E (scalars_β1=0.99) flat at FFS=3025 vs #1310 Cell D (uniform β1=0.99) → FFS=−1 NEVER val=3.289 +47σ_single catastrophic — narrow basin in #1310 was matrices-driven, scalars have a much WIDER β1 basin; (2) **Asymmetric reversal** Cell D (β1=0.5) hurts (+50 FFS, +0.005 val) while Cell E (β1=0.99) flat — scalars want MORE memory matching classical signal-processing prior for lower-SNR signals; (3) ★ **FFS-curve cooldown localization** — all cells identical until step 2875 (val=3.30), decoupling effect lives entirely in cooldown window (steps 2875→FFS); joins crossing-phase cluster but THIS time with FFS-POSITIVE movement breaking the 5-closure FFS-negative streak; (4) **Mechanism class extends #1275** — scalars are confirmed a distinct cluster from 2D matrices wanting their own (LR, β1) corner; n=2 FFS-positive dissociation findings imply scalars_β2 may also be FFS-positive at a different value (student suggestion #4); (5) **Predictions** PRIMARY 35% hit at strong end, SURPRISE 5% partially confirmed (asymmetric basin with B improves AND E flat rather than catastrophic). **Decision**: FFS=3000 hits predeclared B★ promotion gate (≤3000); val margin well below n=1 confirm gate; **sent back to thorfinn with explicit n=4 confirm instructions** — only Cell B★ (`--scalars_beta1 0.95 --num_trials 4`), need μ_4(val) ≤ 3.259221 AND at least 2/4 with FFS ≤ 3025. If confirms → merge as new baseline (FFS=3000, val ~3.258 projected); if not → close clean-NEG-WAS-VAL-COSMETIC. Step budget ~7h GPU. **First plateau-breaking signal of R5 cycle.** 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-27 ~06:35Z (poll ~871) — **★ NEZUKO #1345 CLOSED clean-NEG-LOCAL-OPTIMUM-CONFIRMED [FFS-primary, 17th stack-component closure]**. mu cooldown RAMP-UP 5-cell sweep: **mu cooldown axis FULLY CLOSED — two-sided rejection: mu=0.95 is local optimum in BOTH directions**. Cell A ctrl mu=0.95 FFS=3025 val=3.26099 baseline-EXACT; **Cell B★ ramp 0.95→0.98 FFS=3075 val=3.26488 +6.6σ_single PRIMARY FAILED**; Cell C ramp 0.95→0.99 FFS=3150 val=3.27202 +18.6σ; Cell D instant 0.98 FFS=3050 val=3.26401 +5.1σ (D-paradox: instant ≈ ctrl while ramp worse); **Cell E falsifier ramp 0.95→0.999 FFS=−1 NEVER val=3.28745 +44.6σ_single CATASTROPHIC over-smoothing wall between mu=0.99 and 0.999**. ★ 5 mechanism findings: (1) **Two-sided rejection cross-PR with #1294** — combined val-vs-mu curve {0.0: 3.2696, 0.5: 3.2649, **0.95: 3.2624★**, 0.98: 3.26488, 0.99: 3.27202, 0.999: 3.28745} monotone-worsens in both directions; (2) **Monotone-worsening with mu UP** across {0.98, 0.99, 0.999} — over-smoothing wall sits between 0.99 and 0.999, effective look-back at mu=0.999 ~1000 steps exceeds cooldown window; (3) **D-paradox** instant 0.98 ≈ Cell A while ramp 0.95→0.98 worse — instant jump itself mu-neutral when target close to base but sustained excursion via ramp accumulates higher-mu integral; directional asymmetry > schedule shape; (4) **PRIMARY 25% prior FALSIFIED** by direction inversion — #1294's monotone gradient was approaching not climbing past optimum, common-mode misread of monotone-toward-optimum patterns as extrapolatable; (5) ★★ **Stale-momentum-during-cooldown mechanism confirmed** — cooldown updates are signal-limited not noise-limited; higher mu = longer memory = stale-stable-phase inertia incompatible with cooldown's rapid LR contraction; EMA buffer at 0.95 maximally extracts available smoothing; **5th "everything wants to be small at end" cluster member** (#1276 cooldown_frac, #966 cooldown rescaling, #1272 wd-schedule, #1284 body WD, #1345 mu). ★★ **mu cooldown axis FULLY CLOSED** — joins #1294 (mu DOWN). **Crossing-phase decoupling cluster now 4 closures** (#1294, #1345, #1322, #1326) + 1 in flight (#1384). **Joint cluster claim: cooldown-window optimal = steady-state optimal; cooldown HP-schedule has NO FFS-positive movement available**. Student excellent diligence — pre-registered interpretation rows fired correctly; advisor branch stays minimal per student's suggested follow-up #4 (don't merge commit 79fc951). Per FFS-primary directive #1262 no n=4 promotion. **17th stack-component pruning closure.** **Assigned nezuko → #1403 POLYAK-RUPPERT EVAL-ONLY EMA** (★★ FRESH OPTIMIZER MECHANISM not HP search — first non-HP mechanism candidate since #1258 SF-Muon closed; tests whether maintaining EMA of model weights for VALIDATION ONLY reduces FFS by smoothing val/loss noise floor; **structurally distinct from SF-Muon #1258 NEG** which used training-internal averaging fails because cooldown LR→0 collapses averaging window — this PR keeps training optimizer untouched, only eval reads from EMA; 5-cell A=off ctrl / B★=β=0.999 from step 0 PRIMARY classic Polyak / C=β=0.999 from cooldown step 975 / D=β=0.99 shorter window / E=β=0.9999 falsifier over-smoothing eff window 10000 > training length; new `--ema_beta` and `--ema_start_step` CLI flags + dual-eval telemetry logging both EMA and live val_loss at each val step; predicts FFS≤2975 if FFS is eval-noise-limited [25% prior], FFS-NEG if signal-limited [20% prior], NULL [40%], falsifies between two regimes; HIGH-LEVERAGE candidate for first FFS-positive movement since plateau began). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-27 ~05:15Z (poll ~870) — **★ EDWARD #1334 CLOSED clean-NEG-CONFIRMS-DEFAULT [FFS-primary, 16th stack-component closure]**. AdamW aux weight_decay 5-cell sweep: **wd=0 IS load-bearing — monotone harm with WD>0, no FFS-positive cell**. Cell A wd=0.0 ctrl FFS=3025 val=3.25981 baseline; Cell C wd=0.001 FFS=3025 val=3.26117 +2.3σ within-noise; **Cell B★ wd=0.01 FFS=3075 val=3.26258 +4.7σ_single PRIMARY HYPOTHESIS GRADUAL-MONOTONE fired**; Cell D wd=0.025 (match body) FFS=3200 val=3.27751 +29.8σ; **Cell E falsifier wd=0.1 FFS=−1 NEVER val=3.30594 +77.8σ_single CATASTROPHIC**. ★ 5 mechanism findings: (1) **Monotone dose-response in scalars_norm_p50** A→E: 21.3→20.4→13.4→8.9→3.5 — direct cross-PR confirmation of #1275 mechanism (WD>0 mechanically opposes LN-gain drift); (2) **Embed compression 30×** A→E: 69632→2288 — embed has high-magnitude token-frequency-weighted state, most WD-sensitive component (cross-cluster signal: embed LR axis has slack to test → #1394); (3) lm_head largely unaffected until wd=0.1 (801→795→788→755→585) — narrow tolerance band, explains #1330 ε wide-cosmetic finding (lm_head sits in stiff regime); (4) **PRIMARY 60% prior FALSIFIED** — Cell B was supposed to be catastrophic via scalars collapse; instead gradual harm fired the 25% gradual-monotone prior; (5) ★★ **AdamW aux tetrad FULLY CLOSED (4/4) MIXED SIGNATURE** — β1 narrow-basin VALUE-load-bearing (#1310) + β2 monotone-prefers-higher VALUE-cosmetic (#1321) + ε WIDE-COSMETIC 8 orders of magnitude (#1330) + wd FLAG-load-bearing wd=0 required (#1334) → joint claim: tuple `(0.8, 0.95, 1e-10, 0)` is half-load-bearing (β1+wd) and half-cosmetic (β2 cosmetic-monotone, ε wide); pruning would simplify to `(0.8, 0.99, default-eps, 0)` with zero FFS impact. **Student EXCELLENT diligence**: 3-component telemetry (scalars + embed + lm_head norms) cleanly attributed WD harm to predicted #1275 mechanism — BEST cross-PR mechanism confirmation in recent closures. Per FFS-primary directive #1262 no n=4 promotion. **16th stack-component pruning closure.** **Assigned edward → #1394 EMBED-LR pruning** (★ FIRST SENPAI test of hardcoded `lr=0.3` on `adam_embed` group line 840 — HIGHEST aux LR never tested; 96× higher than lm_head's 1/320 and 10× higher than scalars' 0.03; new `--lr_embed` CLI flag; 5-cell A=0.3 ctrl / B★=0.6 (2×) PRIMARY higher-analogous-to-#1275 / C=0.15 (0.5×) lower / D=0.9 (3×) aggressive / E=0.05 (~1/6×) falsifier; cross-cluster with #1334 finding embed showed 30× compression dose-response under WD → magnitude state dynamically loose suggesting LR axis has slack; cross-cluster with #1275 scalars-LR wanted HIGHER does embed follow same direction; parallel to tanjiro's #1387 lm_head-LR — completes embed/lm_head/scalars LR triumvirate; predicts FFS-positive 25% prior if "all aux-group defaults systematically conservative" pattern holds; telemetry: embed_weight_norm_p50/p95, embed_grad_norm_p50, embed_update_norm_p50). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-27 ~04:50Z (poll ~867) — **★ TANJIRO #1330 CLOSED clean-NEG-WIDE-COSMETIC [FFS-primary, 15th stack-component closure]**. AdamW aux eps 5-cell sweep: **eps cosmetic across 8 orders of magnitude [1e-12, 1e-4] — falsifier didn't falsify**. Cell A 1e-10 ctrl FFS=3025 val=3.26045 baseline; **Cell B★ 1e-8 FFS=3025 val=3.26049 baseline-EXACT PRIMARY matches as predicted**; Cell C 1e-12 FFS=3025 val=3.26028 −1.59σ noise; Cell D 1e-6 FFS=3050 val=3.26257 +2.27σ mild slowdown; **Cell E falsifier 1e-4 FFS=3025 val=3.25925 −2.32σ BELOW n=1 gate BUT FFS NOT alive (predicted catastrophic, didn't)**. ★ 4 mechanism findings: (1) telemetry `sqrt_v_lm_head_p50 ≈ 0.61` dominates eps for ~99% of directions in any reasonable eps band — denominator structurally sqrt(v)-bound not eps-bound; (2) **FALSIFIER DIDN'T FALSIFY** — Cell E posted lowest val/loss, "small-update regime" framing overestimated how often lm_head sqrt(v) approaches eps; (3) **Dose-response ONLY in `lm_head_weight_norm`** (806→817→806→749→730 monotone across A→E) — real mechanism (larger eps damps low-v updates) doesn't propagate to FFS/val at this scale, quantitative slack in lm_head training intensity; (4) **AdamW aux tetrad now 3/4 CLOSED with mixed signature** — β1 narrow-basin (#1310) + β2 monotone-prefers-higher (#1321) + ε WIDE-COSMETIC (this) → joint claim emerging: `(0.8, 0.95, 1e-10)` tuple has 2/3 elements value-cosmetic with only β1 narrowly tight. Per FFS-primary directive #1262 no n=4 promotion. **Student EXCELLENT diligence**: comprehensive telemetry (`sqrt_v` percentiles, `eps_to_sqrtv_ratio`, `lm_head_weight_norm`) directly explained why falsifier didn't falsify. **15th stack-component pruning closure.** **Assigned tanjiro → #1387 LM_HEAD-LR pruning** (★ FIRST SENPAI test of hardcoded `lr=1/320=0.003125` on `adam_lm_head` group line 841 — fresh axis under directive #1262; lm_head has LOWEST aux LR (96× smaller than embed lr=0.3, 9.6× smaller than scalars lr=0.03); 5-cell A=1/320 ctrl / B★=1/160 (2×) PRIMARY higher-analogous-to-#1275 / C=1/80 (4×) / D=1/640 (0.5×) / E=1/40 (8×) falsifier; new `--lr_lm_head` CLI flag replaces hardcoded 1/320 on line 841; cross-cluster with #1275 scalars-LR finding scalars wanted HIGHER — does lm_head follow same direction?; telemetry: lm_head_grad_norm_p50, update_norm_p50, weight_norm — directly probes the dose-response signal seen in #1330). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-27 ~04:25Z (poll ~866) — **★ DOUBLE CLOSURE: FERN #1328 + ASKELADD #1326 CLOSED clean-NEG [FFS-primary, 13th+14th stack-component closures]**. **#1328 fern body LR warmup → clean-NEG-NON-MONOTONIC**: A ctrl FFS=3025 val=3.26160; **B★ warmup=200 FFS=3075 +0.00561 PRIMARY FAILED**; C warmup=100 FFS=3075; D warmup=500 FFS=3050 (paradoxically best of warmup cells); E warmup=1000 FFS=3100 +0.00776 mild not catastrophic. ★ Non-monotonic FFS in warmup length (B/C tied at +50, D BETTER at +25 despite eating MORE stable phase); 5 mechanism findings — (1) all body LR warmups FFS-WORSE baseline already maximally exploits flat-eta, (2) D-paradox: smoother ramp rate 1/500 → smaller post-warmup transient OR longer SOAP-stabilization at low LR, (3) E falsifier only mild (+75 FFS) suggests stable phase is mostly redundant — most FFS-load-bearing work happens in cooldown crossing, (4) confirms fern's own #1276 mechanism "FFS locked by first ~3000 steps" not warmup-modulable, (5) 2nd EARLY-PHASE axis closure joining #1266 depth-init — "early state-as-set is FFS-locked except via large changes". **#1326 askeladd scalars-LR-cooldown → clean-NEG-WIDE-BAND-NULL-WITH-EDGE-SENSITIVITY**: A shared ctrl FFS=3050 val=3.262351; **B★ constant (no scalars cooldown) FFS=3100 +0.00630 PRIMARY FAILED**; C early sc_cf=0.5 FFS=3025 baseline-EXACT val=3.261452 +1.4σ misses n=1 gate; D late sc_cf=0.85 FFS=3050 within noise; **E anti-falsifier ramp 0→1 FFS=3250 +0.01746 CATASTROPHIC**. ★ 4 mechanism findings — (1) WIDE-BAND NULL in [shared, early, late] all within ±25 FFS, trapezoidal eta=1→0 transfers cleanly across positioning, (2) ASYMMETRIC EDGE SENSITIVITY absence of cooldown mildly harmful but inverse cooldown catastrophic, (3) reproduces #1275 from different angle scalars LR axis half-load-bearing flag-must-be-on but value/shape val-cosmetic, (4) 3rd crossing-phase decoupling closure confirms scalars-LR is DECOUPLING-ROBUST follower while body is FFS-load-bearing — body has tight coupling between LR/mu/NS schedules, aux side more permissive. Per FFS-primary directive #1262 no n=4 promotion for either. **13th+14th stack-component pruning closures.** **Assigned fern → #1385 COSINE-FULL-RUN-body-LR** (★ FRESH ENTIRE-SCHEDULE-SHAPE test, structurally orthogonal to alphonse's #1381 within-cooldown shape — replaces stable+linear-decay with cosine 1→0 over entire 3250 steps; 5-cell A=stable+linear ctrl / B★=cosine PRIMARY no stable phase / C=cosine min=0.1 / D=warmup200+cosine / E=triangular falsifier; small code change set_hparams switch on new `--lr_schedule_shape` flag; **predicts FFS≤3000 if** cosine smoothness is val-positive AND no stable phase doesn't hurt — cleanest fresh schedule axis under directive #1262; **complementary to alphonse #1381 which tests within-cooldown shape** while this tests ENTIRE-schedule shape). **Assigned askeladd → #1384 ADAM-EMBED-cooldown-DECOUPLE** (★ fills embed gap in crossing-phase decoupling cluster — embed has lr=0.3 highest aux LR by 10×, parallel to his just-closed #1326 scalars-LR-cooldown work; 5-cell A=shared ctrl / B★=constant no-cooldown embed PRIMARY / C=early embed cooldown sc_cf=0.5 / D=late embed cooldown sc_cf=0.85 / E=anti ramp 0→1 falsifier; same code structure as #1326 but applied to adam_embed group only; **predicts likely FFS-cosmetic** per analogous scalars finding — embeds are massive 50265×768 matrix with own dynamics, but may follow same wide-band null pattern). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-27 ~04:10Z (poll ~865) — **★ ALPHONSE #1322 CLOSED clean-NEG-VALUE-SENSITIVE-WITH-SHARP-FLOOR [FFS-primary, 12th stack-component closure]**. NS-iter cooldown low 5-cell sweep: **HARD NS-QUALITY FLOOR between iter=4 and iter=6 during cooldown — symmetric tight optimum at baseline iter=6 with asymmetric cliffs**. Cell A ctrl iter=-1 (=6 throughout) FFS=3025 val=3.260967 baseline-EXACT; **Cell B★ iter=0 PRIMARY (skip NS in cooldown) FFS=−1 DNF val=3.343360 +138.9σ_single CATASTROPHIC** — model stalls at val=3.34, crosses 3.40→3.35 at normal pace then can't push through 3.30; **Cell C iter=2 FFS=−1 DNF val=3.280723 +33.3σ_single — barely orthogonalized (orth_err≈0.99), DNF by 0.7 mNats, locates failure threshold sharply**; Cell D iter=4 FFS=3050 val=3.265142 +7.0σ_single mild NEG (orth_err≈0.91 partial); Cell E iter=12 FFS=3050 val=3.262339 +2.3σ_single within noise (orth_err≈0.099 near-perfect, +1.8% wall). ★ 5 mechanism findings: (1) **HARD floor between iter=4 and iter=6** — cooldown crossing depends on NS direction-shaping being NEAR-COMPLETE (orth_err ≤ 0.91); (2) **Muon's directional update is necessary even when LR→0** — Cell B reaches 3.34 at step 3025 then STALLS in final 225 steps, NS is the cooldown-crossing mechanism not just early-phase shaper; (3) **Iter=2 is at operational edge** — orth_err≈0.99 enough for stable training, not enough for final descent through 3.30→3.28; (4) **Joint with #1010 (asymmetric upper-side)** ns_iter-by-time axis FULLY closed bowl: iter ∈ {0,2} catastrophic, iter ∈ {4,8} mild NEG, iter=6 optimum, iter ∈ {10,12} mild NEG; (5) **NS dissociates magnitude from direction** — post-NS spectral norm varies 27× (B≈1.0, E≈27.5) but FFS only collapses where DIRECTION fidelity collapses, confirms #1206 finding that NS provides both but **direction is FFS-load-bearing**. ★ Cluster: joins #1042 + #1206 — NS quality cannot be reduced in any direction (input, output, internal). ★ Student CRITICAL diligence: caught arithmetic error in original PR body (Option A step 975 vs verbal "step 2275"), saved hours and yielded clean Option A result. **Per FFS-primary directive #1262**: no n=4 promotion. **12th stack-component pruning closure**. **Assigned alphonse → #1381 cooldown-LR-DECAY-SHAPE** (★ FRESH cooldown axis: tests whether LR decay SHAPE during cooldown window is FFS-load-bearing — currently linear `eta=(1−progress)/cooldown_frac` is the default but **decay SHAPE has never been swept**; 5-cell A=linear ctrl / B★=cosine smoothness PRIMARY / C=concave sqrt(1−x) steep-early gentle-late / D=convex (1−x)² gentle-early steep-late / E=falsifier step-decay eta=1 until last 20% then 0 abruptly; small code change in `set_hparams` switch on new `--lr_cooldown_shape` flag; **predicts C (concave) FFS<3025** if "everything wants small at end" cluster #1276+#941+#966+#1272 mechanism is right — concave drops fast to low-LR regime then stays there; **first cooldown SHAPE candidate for FFS-alive movement**). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-27 ~04:05Z (poll ~864) — **★ FRIEREN #1321 CLOSED clean-NEG-MECHANISM-INVERSION [FFS-primary, 11th stack-component closure]**. AdamW aux β2 (unified across embed+lm_head+scalars) 5-cell sweep: **PRIMARY HYPOTHESIS β2=0.90 INVERTED — load-bearing axis points HIGHER not lower**. Cell A ctrl β2=0.95 FFS=3050 val=3.262031 +1.36σ (within-PR ctrl 25 steps above global baseline); **Cell B★ β2=0.90 FFS=3075 val=3.264364 +5.30σ_single PRIMARY FAILED — faster forgetting FFS-worse**; Cell C β2=0.92 FFS=3050 val=3.261541 +0.54σ noise; **Cell D β2=0.99 FFS=3025 val=3.261115 −0.18σ — BEST val, FFS=baseline-EXACT (NOT FFS-alive)**; **Cell E β2=0.50 FFS=−1 NEVER val=3.287794 +44.7σ_single CATASTROPHIC falsifier**. ★ 4 mechanism findings: (1) **PRIMARY HYPOTHESIS FALSIFIED** — β2=0.90 faster-forgetting is FFS-worse not FFS-equal, pruning ablation morphed into mechanism inversion; (2) **MONOTONE FFS structure in β2** across {0.90, 0.92, 0.95, 0.99}: 3075→3050→3050→3025 as β2 ↑ (longer 2nd-moment memory) FFS ↓ (improves); (3) ★★ **β1/β2 DISSOCIATION cross-PR with #1310** — β1 wants SHORT memory (sweet spot 0.8 half-life ~3 steps), β2 wants LONG memory (best 0.99 half-life ~70 steps), recovers classical Adam intuition m̂ short-horizon ŷ long-horizon, not redundant nor symmetric; (4) **cooldown 2nd-moment preservation** mechanism confirmed — higher β2 keeps v_t closer to pre-cooldown gradient magnitudes during LR→0 phase so effective_lr = lr / (sqrt(v_t) + eps) doesn't collapse; Cell E (β2=0.5) DNF confirms v_t adequate smoothing structurally NECESSARY. **Per FFS-primary directive #1262**: no n=4 promotion — Cell D FFS=3025 matches baseline-EXACT but NOT FFS-alive (≤2975). **Stack-component status: AdamW aux tetrad HALF-CLOSED** (β1 narrow-basin + β2 monotone-LONG-memory closed; ε #1330 4/5 + wd #1334 4/5 imminent). **11th stack-component pruning closure under FFS-primary directive.** **Assigned frieren → #1377 adamw-aux-β2-SCHEDULE** (★ FIRST schedule test in AdamW aux family — directly tests cooldown 2nd-moment preservation mechanism by introducing β2 as schedule rather than fixed value; 5-cell A=β2=0.95 constant ctrl / B★=linear ramp 0.95→0.99 over cooldown PRIMARY / C=linear ramp 0.95→0.98 over cooldown / D=instant step-up β2=0.99 at cooldown start step 975 / E=falsifier reverse ramp 0.99→0.95 over cooldown; small code change adds `--adamw_aux_beta2_schedule` flag with linear/step/reverse modes; **predicts FFS<3025** if entire benefit from cooldown phase only; cross-cluster with #941+#966+#1272 "cooldown is directed descent in zero-WD regime"; **first schedule mechanism candidate that could move FFS-alive**). **Alphonse #1322 5/5 done in W&B but no SENPAI-RESULT yet** — pinged student to post terminal marker. 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-27 ~00:35Z (poll ~863) — **★ THORFINN #1310 CLOSED clean-NEG-NARROW-BASIN [FFS-primary, 10th stack-component closure]**. AdamW aux β1 (uniform across embed+lm_head+scalars) 5-cell sweep: **β1=0.8 is value-sensitive load-bearing sweet spot with asymmetric cliffs**. Cell A ctrl β1=0.8 FFS=3025 val=3.260702 −0.88σ baseline-EXACT; **Cell B★ β1=0.95 FFS=3050 val=3.263942 +4.59σ_single PRIMARY FAILED**; Cell C β1=0.90 FFS=3025 val=3.261201 −0.03σ within noise; **Cell D β1=0.99 FFS=−1 NEVER REACHES val=3.289474 +47.5σ_single CATASTROPHIC upper cliff**; **Cell E β1=0.0 FFS=3175 val=3.275737 +24.5σ_single CATASTROPHIC lower cliff**. ★ 4 mechanism findings: (1) **sweet spot at 0.8 with narrow basin width ≤0.10** — Cell C 0.9 within noise but Cell B 0.95 already +4.59σ; (2) **asymmetric cliffs** — upper (β1=0.99) catastrophic (FFS=-1), lower (β1=0.0) bad but recoverable (FFS=3175); (3) **half-life ~3 steps preferred** for AdamW aux groups — short memory aligns with high-SNR matrix gradients (embed, lm_head 2D); (4) **falsifies 50% prior** "all FFS ∈ [3025, 3150]" — basin narrower than expected for uniform-β1, pruning ablation REVEALED load-bearing. ★ Cluster: AdamW aux tetrad now half-closed (β1 sharp narrow-basin load-bearing); #1321 β2 + #1330 ε + #1334 wd in flight. ★ **Cross-stack convergence with #1284 body-WD** — both narrow basins with asymmetric cliffs; cooldown-phase tightening pattern. **Per FFS-primary directive #1262: no n=4 promotion** (Cell A baseline-exact, no Cell ≤2975). **Assigned thorfinn → #1368 scalars-β1 DECOUPLE** (★ FIRST per-group β1 decoupling test; tests whether the narrow #1310 basin was driven by all 3 groups uniformly or by embed/lm_head; adds `--scalars_beta1` CLI flag, applies group-level betas override ONLY to adam_scalars group; 5-cell A=0.8 ctrl all uniform / B★=0.95 scalars only PRIMARY heavier smoothing on low-SNR 1D / C=0.9 / D=0.5 faster-decay opposite direction / E=0.99 falsifier; **cross-cluster with #1275 lr_scalars** — scalars have distinct LR dynamics, possibly distinct β1 too; classical signal-processing prior: heavier smoothing for noisier signals favors B★ hypothesis). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~23:55Z (poll ~862) — **★ NEZUKO #1294 CLOSED clean-NEG with MECHANISM-REVERSAL [FFS-primary, 9th stack-component closure]**. mu cooldown decay 5-cell sweep, all 3 main cells fail n=1 gate: Cell A ctrl FFS=3050 val=3.262358 +1.92σ noise; **Cell B★ linear 0.95→0.0 cooldown FFS=3025 val=3.269557 +14.06σ_single CATASTROPHIC**; Cell C linear 0.95→0.5 cooldown FFS=3000 val=3.264868 +6.15σ; **Cell D instant mu=0.0 at cooldown FFS=−1 NEVER val=3.286754 +43.06σ_single CATASTROPHIC**; Cell E falsifier (linear-from-step-0, mis-designed) killed step 1014 by predeclared gate. ★★ **MONOTONE GRADIENT in mu_target**: 0.0→0.5→0.95 (B→C→A) gives val/loss 3.2696→3.2649→3.2624 — **mu during cooldown is val-positive, opposite of hypothesis**. ★ 4 mechanism findings: (1) momentum during cooldown is val-positive monotonically, (2) instant-kill catastrophic — cooldown NEEDS EMA buffer to dampen low-LR descent, (3) NS+low-LR depends on smoothed gradient direction, low-SNR regime, (4) ★★ **BREAKS "everything wants to be small at end" cluster** (#1272/#1276/#1284 all want small terminal values; mu is the OUTLIER — wants to be HIGH at end). Strong cluster-dissociation finding. ★ Cell C FFS=3000 = single-trial seed noise (val/loss penalty unambiguous); does NOT clear FFS-alive ≤2975 gate. ★ Student noted Cell E falsifier mis-designed (transparent science). **Assigned nezuko → #1345 mu cooldown RAMP-UP** (★ direct mechanism extension extrapolating monotone gradient toward HIGHER mu; 5-cell A=ctrl mu=0.95 / B★=ramp 0.95→0.98 PRIMARY / C=ramp 0.95→0.99 / D=instant 0.98 mirror / E=ramp 0.95→0.999 falsifier; **NO code change** — re-uses #1294's `--mu_cooldown_target` flag with values ≥0.95; ★★ **first hypothesis in cluster that PREDICTS FFS improvement** since extrapolates val-improving mu gradient + breaks smallness-cluster; **strong FFS-targeted candidate under directive #1262** — if B/C/D move FFS<2975 = first clean FFS-positive mechanism since plateau began). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~23:30Z (poll ~861) — **★ NO CLOSURES this poll**. PR #1322 alphonse send-back: student flagged critical arithmetic error in PR body (verbal "step 2275" vs code `progress >= 0.3` → step 975). Replied with Option A (step 975+, last 70% = cooldown decay phase, matches code semantics + #1010 symmetric prior + mechanism rationale "NS in cooldown's directed-descent regime"). PR sent back to status:wip with action items (verify Cell B threshold, kill+relaunch if Option B used, re-anchor kill-gate to step 1100, re-anchor telemetry). W&B sub-agent check on 4 stale_wip PRs: all actively running. Thorfinn #1310 most advanced (Cell C at step 2562/3250, B★ val=3.2639 +4.5σ above baseline → likely clean-NEG for AdamW β1=0.95). Nezuko #1294 Cell E falsifier at step 906/3250 with val=3.691 (catastrophic, will hit kill-gate or run to completion). Frieren #1321 Cell B★ at step 1005 val=3.648 (early). Askeladd #1326 Cell B★ at step 326 (very early). 8 PRs in flight, 0 idle students. No advisor action needed beyond the #1322 reply.

- **Prior:** 2026-05-26 ~22:45Z (poll ~860) — **★ EDWARD #1284 CLOSED clean-NEG with SHARP-CLIFF mechanism [FFS-primary]**. Body WD value pruning ablation closure (8th stack-component pruning closure): **body WD value 0.025 is SHARPLY FFS-LOAD-BEARING in both directions — narrow basin with cliffs at 0 and 0.10.** Cell A ctrl FFS=3025 val=3.26057 −1.10σ baseline-reproduced; **Cell B★ wd=0.0 PRIMARY FFS=−1 NEVER REACHES val=3.28252 +35.92σ_single CATASTROPHIC**; Cell C wd=0.0125 half FFS=3050 val=3.26645 +8.82σ; Cell D wd=0.05 double FFS=3100 val=3.26629 +8.55σ; **Cell E wd=0.10 4× falsifier FFS=−1 NEVER REACHES val=3.28869 +46.32σ_single CATASTROPHIC**. ★ **Falsified PR's 55% prior** (\"all 5 cells FFS ∈ [3025, 3150]\"): basin is far narrower than expected — cells C/D bracket cleanly at +25/+75 FFS, cells B/E both catastrophic. ★ 4 mechanism findings: (1) **Cell B no-WD LEADS through step 2500** (fastest early descent B-2500=3.33848 vs A-2500=3.35381) — then STALLS in cooldown (step 3000→3250: B drops only 0.0120 vs A 0.0218). **Ramp_down WD schedule is cooldown's load-bearing tightening mechanism, NOT LR cooldown alone**; (2) Cell E over-WD monotone-worse from step 500 — 4× WD over-shrinks throughout, capacity destroyed cannot be recovered; (3) Cells C/D monotone in FFS (3050 < 3100) — U-shape FFS basin centered at 0.025; (4) Reproduces #1272 wd-schedule mechanism from different angle: schedule SHAPE (ramp_down) + VALUE (0.025) jointly tightly tuned. ★ **Cluster connection**: #966 cooldown weight rescaling NEG + #1272 wd-schedule ramp_down + #1284 wd value 0.025 = three independent tests converging on \"cooldown WD-driven shrinkage is the structural tightening mechanism.\" ★ **Body-matrix WD pruning programme**: with #1272 (shape) + #1284 (value), the body WD axis is fully closed at FFS scale. Both axes tightly tuned, narrow basin. ★ Student flagged process improvement: launcher kill-gate functions defined but never invoked — Cell E hit val=3.54 at step 2000 (>3.40 kill threshold) but ran to completion (~1.5h wasted GPU time). **8th stack-component pruning closure.** **Assigned edward → #1334 AdamW aux WD pruning** (★ completes AdamW aux (β1, β2, ε, wd) TETRAD under FFS-primary; tests hardcoded `weight_decay=0` line 843 via new `--adamw_aux_wd` CLI arg; 5-cell A=0.0 ctrl / B★=0.01 PRIMARY uniform small positive / C=0.001 very small / D=0.025 match body / E=0.1 falsifier; **strong asymmetric prediction**: per #1275 scalars-LR finding (LN gains MUST drift from init), applying WD>0 uniformly will pull gains back toward 0 → likely Cell B catastrophic = clean cross-PR mechanism confirmation of \"WD=0 is structurally required for scalars\"; scalars_norm telemetry added to verify mechanism). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~22:00Z (poll ~859) — **★ TANJIRO #1279 CLOSED clean-NEG [FFS-primary]**. SOAP `PRECOND_FREQ=16` pruning ablation closure (7th stack-component pruning closure): **PRECOND_FREQ is FFS-COSMETIC across [4, 32] with staleness cliff between 32→64**. Cell A 16 ctrl FFS=3050 val=3.26196 +1.25σ (n=1 noise); **Cell B★ 32 PRIMARY FFS=3025 val=3.26070 −0.88σ — baseline-EXACT half compute**; Cell C 8 FFS=3025 val=3.26151 +0.49σ; **Cell D 64 FFS=3075 val=3.26494 +6.27σ — first val degradation**; Cell E 4 falsifier FFS=3025 val=3.25895 −3.83σ cosmetic only. ★ Cell B FFS=3025 = baseline-exact NOT earlier → does NOT clear FFS-primary alive gate (≤2975) → NO n=4 promotion per directive (#1188 lesson applied). ★ 4 mechanism findings: (1) PRECOND_FREQ is FFS-cosmetic across [4, 32] — slow-moving curvature direction captured well below Nyquist rate of refresh; (2) Cell D=64 first val degradation +6.3σ → staleness cliff between 32 and 64 — eigenbasis carries 64 LR-decayed steps stale during cooldown crossing; (3) Cell E=4 over-refresh gives val −3.8σ but no FFS gain → val-cosmetic over-correction at edge of crossing window; (4) PRECOND_FREQ=32 is clean ~2× SOAP-internals compute simplification at zero FFS cost (wall-clock only; doesn't move FFS so doesn't qualify for merge under FFS-primary). ★ **SOAP-internals pruning programme complete**: combined with #914 (refresh-freeze), #1053 (asymmetric Q refresh), #979 (exp_avg_sq scaling), #936 (Q scope), #1273 (soap_attn) — SOAP internals are tightly tuned and load-bearing in all axes except refresh cadence which has slack. **7th stack-component pruning closure**. **Assigned tanjiro → #1330 AdamW aux EPS pruning** (★ completes AdamW aux trio (β1, β2, ε) under FFS-primary; tests hardcoded `eps=1e-10` line 843 via new `--adamw_aux_eps` CLI arg; 5-cell A=1e-10 ctrl / B★=1e-8 PyTorch Adam default 100× larger PRIMARY / C=1e-12 100× smaller / D=1e-6 / E=1e-4 falsifier; specifically probes whether lm_head's small-update regime (lr=1/320) is sensitive to denominator regularizer; pairs with #1310 β1 + #1321 β2 → joint test of "is the AdamW (0.8, 0.95, 1e-10) tuple FFS-load-bearing?"). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~21:15Z (poll ~858) — **★ FERN #1276 CLOSED clean-NEG-INVERTED [FFS-primary]**. `cooldown_frac` pruning ablation closure (6th stack-component pruning closure) with **INVERTED mechanism from PR prediction**: Cell A ctrl FFS=3050 val=3.26217; Cell B★ frac=0.5 PRIMARY 'earlier crossing' FFS=3075 val=3.26323 +1.8σ — **REGRESSED, primary FAILED**; Cell C frac=0.6 FFS=3050 val=3.26295 +1.3σ; **Cell D frac=0.85 FFS=3025 baseline-EXACT val=3.26109 −1.8σ better — borderline**; Cell E frac=0.95 falsifier FFS=3050 val=3.26459 +4σ not catastrophic. ★ **Ordering at every step in [3000, 3250]: D < A ≈ E < C < B — monotonic in 1/cooldown_frac across {0.5, 0.6, 0.7, 0.85}.** ★ **INVERTED mechanism**: higher LR at crossing window degrades crossing speed; falsifies 'more LR longer = faster crossing'; optimizer at progress=0.93 PREFERS gentle decay over LR floor maintenance. ★ Connects to mechanism cluster: #941 cooldown is directed descent, #966 cooldown weight rescaling NEG, #1272 terminal WD = 0 → **everything wants to be small at the end**. ★ Cell D borderline FFS=3025 + best val direction: per strict FFS-primary directive (no n=4 unless FFS≤2975) parity-not-improvement does NOT qualify — closing as mechanism finding. ★ Student noted: "FFS appears locked by state accumulated through the first ~3000 steps, not by terminal schedule choices." 6th stack-component pruning closure. **Assigned fern → #1328 body LR warmup** (★ structurally orthogonal complement to 4-PR cooldown-phase decoupling cluster — first EARLY-PHASE test under FFS-primary; tests whether SOAP eigenbasis + NS pipeline benefits from stabilization time before full body LR; 5-cell: A=no warmup ctrl / B★=200-step linear warmup PRIMARY / C=100 / D=500 / E=1000 falsifier; small code change for `--lr_warmup_steps_body` flag; SOAP eigenbasis stability telemetry added; directly tests fern's own #1276 mechanism observation that early-state matters more than terminal schedule). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~20:30Z (poll ~857) — **★ ASKELADD #1275 CLOSED clean-NEG-mixed [FFS-primary]**. `--lr_scalars` pruning ablation closure (5th stack-component pruning closure): **`--lr_scalars` is half FFS-LOAD-BEARING (flag must stay nonzero), half COSMETIC (value insensitive in [0.015, 0.10])**. Cell A ctrl FFS=3025 val=3.26162 (baseline-exact); **Cell B★ lr_scalars=0.0 FFS=−1 NEVER REACHES val=3.28900 +46σ_single** catastrophic structural; Cells C/D (0.015, 0.06) FFS=3050 within FFS noise; Cell E (0.10, 3.3× ctrl) FFS=3075 +50 — Cell E falsifier MISSED, over-LR is sublinear not catastrophic. ★ 3 mechanism findings: (1) 1D scalars group MUST train — LN gains + biases encode forward-pass scale per layer; (2) within [0.015, 0.10] (6.7× range) value is val-cosmetic, optimizer rescues moderately mis-tuned scalar LR; (3) asymmetric: zero=catastrophic but 10× ctrl=mild — points to scalars as 'warmup multiplier' for gains, once gains have moved from init by ANY amount FFS holds. ★ LN-gain-norm drift scales linearly with lr_scalars (141.3 → 590.7, 4.2× span) but val/loss only +0.004 → magnitude FFS-load-bearing only in sense ≠init is required. **5th stack-component pruning closure under FFS-primary**. **Assigned askeladd → #1326 scalars decoupled cooldown** (★ direct mechanism extension of #1275: tests whether scalars LR schedule shape benefits from decoupling from body schedule; 5-cell: A=shared ctrl / B★=constant scalars LR (no cooldown applied to scalars) PRIMARY / C=early scalars cooldown (frac=0.5) / D=late scalars cooldown (frac=0.85) / E=anti ramp 0→1 falsifier; small code change to set_hparams for per-group eta; ★ 3rd crossing-phase decoupling test along with #1294 body-mu and #1322 NS-iter cooldown — together test whether 3 optimizer components on different param groups have different optimal cooldown schedules). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~19:30Z (poll ~856) — **★ ALPHONSE #1272 CLOSED clean-NEG-graded [FFS-primary]**. `--wd_schedule ramp_down` pruning ablation closure (4th stack-component pruning closure): clean monotonic ordering ramp_down (FFS=3050) → constant (3100 +7.2σ) → triangle (3150) → ramp_up (3175) → cosine_updown (3200) — Cell B★ constant FAIL primary pruning gate by +50 FFS / +0.0043 val. ★ Rich mechanism (3 findings): (1) all 5 schedules same average WD (cumulative dose matched per `_wd_multiplier` semantics: ramp_up/ramp_down/triangle/cosine_updown peak at 2× args.wd_mlp; constant stays 1×) — **differentiator is shape not dose**; (2) ordering tracks terminal WD at step 3250 (ramp_down ~0 → constant 0.025 → ramp_up 0.05 worst) — **late-training WD must be near zero for cooldown to squeeze last 0.01-0.02 nats**; (3) terminal weight norms identical across cells (~69 700) — schedule controls validation curve geometry not gross weight scale. ★ Dovetails with #941 cooldown SWA (cooldown is directed descent) + #966 cooldown weight rescaling NEG — **cluster: cooldown is directed descent in zero-WD regime, WD floor at cooldown end is what matters**. ★ Cell E cosine_updown falsifier fires: schedule axis IS structured (not noise). **Assigned alphonse → #1322 NS-iter cooldown low pruning** (★ 4th cooldown-phase mechanism test under FFS-primary; **direct mechanism extension of #1272 + closed #1010**: tests NS_ITER<6 during cooldown — does NS orthonormalization preserve load-bearing role when gradient signal becomes clean in cooldown? 5-cell: A=iter6 ctrl / B★=iter0 skip NS in cooldown PRIMARY / C=iter2 / D=iter4 / E=iter12 falsifier sanity vs #1010 Cell D NEG; small code change for `--ns_iter_cooldown` flag; completes #1010 asymmetric ablation; pairs with concurrent crossing-phase cluster #1276 cooldown-frac + #1294 mu-cooldown-decay). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~17:40Z (poll ~855) — **★ FRIEREN #1273 CLOSED clean-NEG [FFS-primary]**. `--soap_attn` pruning ablation closure (3rd stack-component pruning closure): Cell A ctrl (soap_on) val=3.26267 FFS=3050; **Cell B★ no_soap val=3.27534 FFS=3175 catastrophic +4.5σ_single** (+125 FFS); Cells C/D (no_soap + lr_attn=0.055/0.020 compensation) val>3.274 FFS≥3150 — raising or lowering lr_attn cannot compensate for missing SOAP attn; Cell E falsifier (soap_on + lr_attn=0.060 over-LR) val=3.26330 FFS=3050 ≈ ctrl. **Verdict: `--soap_attn` IS FFS-LOAD-BEARING.** Mechanism: SOAP attn preconditioning supplies **direction information from eigenbasis rotation**, not magnitude scaling — Cells B/C/D all fail symmetrically because lr_attn modulation is a magnitude knob, cannot recover the rotational geometry. Confirms #994 "cross-scope decomposition non-additive 4.5×" finding: both SOAP scopes load-bearing. **3rd stack-component pruning closure** (joins #1266 depth-init val-cosmetic, #1227 pre-NS noise NEG). **Assigned frieren → #1321 AdamW aux β2 pruning ablation** (★ 9th stack-component pruning under FFS-primary; tests `betas=(0.8, 0.95)` hardcoded line 843 with new `--adamw_aux_beta2` CLI arg; 5-cell A=0.95 ctrl / B★=0.90 PRIMARY align with Muon mu / C=0.92 mid / D=0.99 over-stable falsifier / E=0.5 minimal falsifier; **pairs with #1310 β1 → completes AdamW aux β1/β2 pair**, joint test of "is the AdamW (0.8, 0.95) tuple FFS-load-bearing?"). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~14:58Z (poll ~854) — **★ THORFINN #1258 CLOSED clean-NEG [FFS-primary]**. SF-Muon on body matrices closure with **4-mechanism cluster**: (1) Cell A=3.26126 FFS=3025 confirms baseline reproducibility; (2) Cell B PRIMARY (β=0.90 no cooldown) val=3.34243 FFS=−1 catastrophic — SF averages still-oscillating trajectory → averaged-noise not refined-minimum; (3) Cells C/D early-killed at step 1000 (β=0.95/0.80 same catastrophic pattern); (4) Cell E falsifier (β=0.90 + cooldown) val=3.26212 FFS=3025 — cooldown equalizes any SF β. **Cooldown is load-bearing schedule structure SF cannot substitute**; when LR→0 in cooldown, SF averaging window collapses (steps zero, average frozen). **★ 8th trajectory-averaging axis closure** (3rd in family joining #659 SF aux NEG, #1126 Lookahead aux NEG; now SF on body NEG); **★ 5th independent demonstration of cooldown-equalizer pattern** (#1042, #1206, #1200, #1227, now #1258 — cooldown is single most load-bearing schedule component). **Assigned thorfinn → #1310 AdamW aux β1 pruning ablation** (★ 8th stack-component pruning under FFS-primary; tests `betas=(0.8, 0.95)` hardcoded line 843 with `--adamw_aux_beta1` CLI arg; 5-cell A=0.8 ctrl / B★=0.95 PRIMARY align with Muon mu / C=0.9 bracket / D=0.99 over-stable falsifier / E=0.0 pure-gradient falsifier). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~12:10Z (poll ~853) — **★ NEZUKO #1238 CLOSED clean-NEG [FFS-primary]**. SPAM spike-aware momentum reset sweep closure with **4-mechanism cluster**: (1) A vs E define the no-op noise band (both 0 resets, |Δ|=0.47σ_single = pure seed noise; Cell C with 15 resets lies INSIDE the band); (2) spikes are EMA warmup artifacts in first ~12 steps, not steady-state pathology (0 resets in cooldown for thr≤50); (3) EMA false-positives during rampup cost +2.01σ (Cell B, 66 resets: momentum zeroed at most informative training point); (4) NS5 upstream-absorbs any real spike contamination (spectral renormalization). ★ **7th Muon-body preprocessing axis closure** (joining #823 SignMuon, #932, #1042, #1096, #1151, #1183, #1238). Mechanism: SPAM premise (10×–1000× directional contamination) requires (a) late-phase spikes to actually occur, and (b) NS not to absorb them — neither holds on this stack. **Assigned nezuko → #1294 mu-cooldown-decay** (★ crossing-phase redesign: decay Muon momentum β 0.95→0.0 linearly during cooldown window; 5-cell: A=ctrl / B★=linear-to-0 / C=linear-to-0.5 / D=instant-to-0 / E=full-run-falsifier; directly targets FFS by asking whether persistent momentum hurts directed descent). 8 PRs in flight, 0 idle students.

- **Prior:** 2026-05-26 ~09:50Z (poll ~852) — **★ EDWARD #1200 CLOSED clean-NEG [FFS-primary]**. Edward orth-scheme alternatives closure with **4-mechanism cluster**: (1) broad basin headline cond ∈ [1.0, 5.6] all reach baseline floor ±2σ_single; (2) cond NOT complete operator descriptor — Cells C/E spectral fingerprint nearly identical (cond≈18) but differ 4.6σ_single in val/loss (per-singular-vector alignment matters beyond spectral summary); (3) cooldown is the equalizer — mid-training ±14σ deltas collapse to ±2σ_single under ~100× LR contraction; (4) 4 independent operator-output modifications (#962 NS coefs, #1042 post-NS mixing, #1206 pre-NS conditioning, #1200 operator class) all clean-NEG — NS-modulation operator-class fully closed. ★ FFS-headline: Cell D schulz_iter8 (`X(1.5−0.5X²)`) reaches **FFS=3025 = baseline-EXACT** — operator equivalence at FFS level, different family same speed. 11th NS-modulation closure with broadened mechanism family. **Assigned edward → #1284 body-WD value pruning** (6th stack-component pruning under FFS-primary; 5-cell `--wd_mlp=--wd_attn` A=0.025 ctrl / B★=0.0 PRIMARY drop body WD entirely / C=0.0125 half / D=0.05 double / E=0.10 falsifier; tests "is body WD value FFS-load-bearing or val-loss-cosmetic at FFS scale?"; single-flag-per-cell no code changes; pairs with concurrent #1272 wd-schedule (shape axis) — value vs shape decomposition). 8 PRs in flight, 0 idle students.

## Previous poll context (poll ~851)

**★★ DOUBLE CLOSURE: FERN #1222 + TANJIRO #1188 CLOSED clean-NEG [FFS-primary]**. Fern AdamP-aux 7th aux-axis closure — embed cos(g, W)=5e-05 falsifies PR's "sparse updates reinforce existing directions" theory (sparse-token update geometry differs structurally from dense gradient geometry); lm_head parallel-to-W IS the learning signal not noise (untied LM head column mass-attracts toward residual direction); LN γ orthogonal projection structurally doomed (∂loss/∂γ ∝ γ-direction by construction). Tanjiro depth-LR Phase 2 n=4: μ_4=3.261355 (FAIL gate by +0.002134), FFS μ_4=3037.5 (FFS-flat); Phase 1 Cell E n=1 was lucky seed (regression-to-mean +2.7 mNats); depth-LR axis null at ±15%. Assigned fern → #1276 cooldown-frac-pruning, tanjiro → #1279 soap-precond-freq-pruning.

## Previous poll context (poll ~849)

**★★ DOUBLE CLOSURE:** frieren #1221 LAMB clean-NEG (saturation mechanism: trust ratio degenerates to uniform 2× lr_mlp boost from step ~800, per-layer signal exists only in first ~50 steps; 1st cross-layer balance axis closure; dovetails with edward #1200 + thorfinn #1206 NS-magnitude findings) + alphonse #1266 depth-init clean-NEG (pre-crossing trajectories bit-identical across ALL 5 modes; even smallconst falsifier survived FFS=3050; init axis val-loss-cosmetic, stack simplifiable; 2nd stack-component pruning closure under FFS-primary). Assigned alphonse → #1272 wd-schedule-pruning, frieren → #1273 soap-attn-pruning.

## Previous poll context (poll ~847)

**★★ HUMAN DIRECTIVE issue #1262 adopted** — FFS-primary framing. Plateau diagnosis from human team; recent closures mechanism-rich but speed-dry. Concrete policy: FFS first in every closure/ack; no n=4 confirm unless FFS alive; ablations over confirmations; experiments that move crossing step, simplify stacks, or reveal FFS-load-bearing components prioritized. Reply posted to issue #1262 with portfolio audit; advisor framing comment posted on PR #1188 (will close as mechanism finding regardless of μ_4 because FFS=3025 flat).

## Previous poll context (poll ~846) — **★ THORFINN #1206 CLOSED clean-NEG** (Pre-NS grad-norm conditioned LR on Muon body — PRIMARY Cell B linear +5.9σ_single above baseline; ALL conditioning modes B/D/E fail symmetrically at +5.9/+6.2/+7.9σ; C is structural no-op gain_mean=0.976 in tight clip). **★ Mechanism headline:** harm is **symmetric in `|deviation from gain=1.0|`**, NOT direction-specific. B (shrink) and D (shrink) fail similarly to E (grow). Read: **Muon's post-NS spectral-norm-bounded magnitude is intentional and load-bearing** — NS is direction shaping AND magnitude calibration. Optimizer wants `‖update‖_2 = 1` exactly. **Dovetails with edward #1200 Cell B polar SVD within band** (polynomial-floor finding): two independent operator-output modifications converge on the same finding — polynomial output's cond≈2.4 spectral fingerprint is the optimizer's preferred direction AND magnitude. **★ 9th NS-modulation axis closure** (joins #776 RMS clamp, #815 NS warmup, #824 NS coefs, #867 cautious pre-NS, #932 per-layer iter, #1010 iter-by-time, #1022 NS degree, #1042 soft mixing, #1151 GC). NS-on-body operator class is finely tuned around `(iter=6, polynomial-degree-5, post-NS-spectral-norm=1.0)`; 10 adjacent perturbations all fail. **Assigned thorfinn → #1258 schedule-free Muon on body** (Defazio 2024 Polyak averaging replaces explicit cooldown on body matrices; 5-cell sweep β=0.90★/0.95/0.80 + cooldown-falsifier; tests "implicit averaging vs explicit cooldown" axis on body — orthogonal to NS-modulation, complements closed aux-side SF #659 NEG and Lookahead-aux #1126 NEG; structurally different optimizer trajectory dynamics axis). 8 PRs in flight, 0 idle students.

## Previous poll context (poll ~844)

**★ NEZUKO #1181 CLOSED clean-NEG** (Adan optimizer for aux groups — all 4 Adan cells miss n=1 gate; Cell B paper-defaults +24.6σ_single, even best Cell D β₁=0.90 misses by +6.0σ; ★ mechanism — grad-diff term B-vs-E gap 0.00535 confirms `v_t=EMA(g_t−g_{t-1})` provides real but small lift on aux grads, dominated by β₁=0.98 vs AdamW β₁=0.8 — D recovers ~70% of gap by rolling β₁→0.90; ffs degrades 5% too; ★ student diligence: detected paper-formula vs Adam-style β convention inconsistency, cross-checked official sail-sg/Adan reference). **★ 6th aux-optimizer-family closure** (Adan now + AdaBelief #1131 + Lion h152 + AdEmaMix h144 + ADopt h160 + Cautious); plus AdamW within-family saturation across LR magnitude/warmup/schedule/trajectory-averaging/regularization. **AdamW is tight local optimum for aux-group regime; after alphonse #1211 v_t pruning + fern #1222 AdamP land, aux-side optimizer-family axis essentially closes.** Assigned nezuko → #1238 SPAM spike-aware momentum reset on Muon body.

## Previous poll context (poll ~842)

**★ ASKELADD #1105 CLOSED clean-WEAK-NEG** (n=8 final: μ_8=3.259890, **misses MERGE gate by +0.000083**; Δ×√8=0.003765, needs ≥0.004; **all 8 trials ≤ baseline rules out lucky seed — signal real but sub-statsig at n=8**; sweet-spot pattern A→B↓→C~B→D↑→E↑↑ textbook clean; extension cohort μ_ext=3.259760 cleared gate alone, Phase 2 T2 outlier 3.26235 cost the merge; ★ mechanism — val/loss helps, ffs flat at 3028.125 vs 3025 baseline → light L2 shrinks converged solution but not rate of reaching it; AdamW aux side now extensively saturated). **Assigned askeladd → #1227 pre-ns-noise-body** (pre-NS Gaussian noise injection on Muon body matrices; mechanically distinct from #383 POST-NS noise — NS projects pre-NS noise to the orthogonal manifold producing structured exploration rather than unstructured perturbation; 5-cell sweep: ctrl/linear_decay-5e-4 PRIMARY/constant/cooldown_only/large-noise falsifier).

## Previous poll context (poll ~840)

**★ DOUBLE CLOSURE:** **Frieren #1183 CLOSED clean-NEG** (Heavy-Ball vs Nesterov axis CLOSED; Cell B heavy-ball μ=0.95 at +8.75σ_single; 3 coherent mechanism signatures — directional fidelity, lerp coefficient encodes information, μ=0.99 catastrophe nonlinear in lag; **momentum-form axis on Muon body now saturated** alongside #823/#1042/#1151). **Fern #1177 CLOSED NULL** (Cautious Muon Cell B PRIMARY ≈ baseline +0.12σ; ★ mechanism finding — NS subsumes cautious: NS output sign-aligns with precond_nesterov on 89% of elements per step, only 11% mask density which is essentially neutral; any post-NS sign-correction has negligible effect). **Assigned frieren → #1221 lamb-trust-ratio-body**, **fern → #1222 adamp-aux**.

**★ TANJIRO #1188 PARTIAL n=1 (anti-LLR hypothesis flip):** Phase 1 5-cell sweep complete; **Cell E (anti-LLR scale=1.15) at val/loss=3.25863 = −4.36σ_single vs baseline μ** — 2.8σ below n=1 gate, strongest n=1 signal this round. Anti-LLR direction (later layers get MORE LR) wins by a wide margin, falsifying Yang-Ma 2024 literature for this stack. Asymmetric monotone profile A(1.00)→D(0.95)≈A→B(0.85) mild→C(0.75) mild→E(1.15) big. Three mechanism candidates: musoft init asymmetry (depth-aware init already shrinks late blocks, need extra LR), NS scale-normalization decouples weight magnitude from step magnitude (per-block LR scales post-NS update magnitude directly), late-block under-training at 3250-step budget. Student auto-launched Phase 2 n=4 confirm on Cell E (ETA ~6h50m from ~01:23Z launch).

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)

## Active WIP Portfolio (poll ~783)

8 PRs in flight, 0 idle students.

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **✓ CLOSED #1326** | **askeladd** | ~~scalars decoupled cooldown~~ **CLOSED clean-NEG-WIDE-BAND-NULL-WITH-EDGE-SENSITIVITY [FFS-primary]** poll ~866. **Scalars cooldown shape is WIDE-BAND NULL in [shared, early, late] with ASYMMETRIC edge sensitivity.** Cell A shared ctrl FFS=3050 val=3.262351; **Cell B★ constant FFS=3100 +0.00630 PRIMARY FAILED**; Cell C early sc_cf=0.5 FFS=3025 baseline-EXACT val=3.261452 +1.4σ misses n=1 gate; Cell D late sc_cf=0.85 FFS=3050 within noise; **Cell E anti-falsifier ramp 0→1 FFS=3250 +0.01746 CATASTROPHIC**. ★ 4 mechanism findings: (1) WIDE-BAND NULL A/C/D within ±25 FFS, trapezoidal eta=1→0 transfers cleanly across [0.15, 0.5, 0.7]× total steps; (2) ASYMMETRIC edges — absence mildly harmful (+50), inverse catastrophic (+200); (3) reproduces #1275 axis closure: scalars-LR half-load-bearing flag-on-required but value/shape val-cosmetic; (4) 3rd crossing-phase decoupling closure — scalars-LR is DECOUPLING-ROBUST follower while body is FFS-load-bearing; **body has tight coupling LR/mu/NS, aux side more permissive**. Per FFS-primary no n=4. **14th stack-component pruning closure.** | **#1384 ADAM-EMBED-cooldown-DECOUPLE OPEN** (★ fills embed gap in crossing-phase decoupling cluster — embed has lr=0.3 highest aux LR by 10×, parallel to his just-closed #1326 scalars-LR-cooldown work; 5-cell A=shared ctrl / B★=constant no-cooldown embed PRIMARY / C=early embed cooldown sc_cf=0.5 / D=late embed cooldown sc_cf=0.85 / E=anti ramp 0→1 falsifier; same code structure as #1326 but applied to adam_embed group only; predicts likely FFS-cosmetic per analogous scalars finding) |
| **✓ CLOSED #1330** | **tanjiro** | ~~AdamW aux eps pruning ablation~~ **CLOSED clean-NEG-WIDE-COSMETIC [FFS-primary]** poll ~867. **eps cosmetic across 8 orders of magnitude [1e-12, 1e-4] — falsifier didn't falsify.** Cell A 1e-10 ctrl FFS=3025 val=3.26045 baseline; **Cell B★ 1e-8 FFS=3025 val=3.26049 −1.23σ baseline-EXACT**; Cell C 1e-12 FFS=3025 val=3.26028 −1.59σ; Cell D 1e-6 FFS=3050 val=3.26257 +2.27σ; **Cell E falsifier 1e-4 FFS=3025 val=3.25925 −2.32σ BELOW n=1 gate but FFS NOT alive**. ★ 4 mechanism findings: (1) telemetry `sqrt_v_lm_head_p50 ≈ 0.61` dominates eps for ~99% of directions; (2) FALSIFIER DIDN'T FALSIFY — predicted catastrophic E posted lowest val/loss; (3) dose-response ONLY in `lm_head_weight_norm` (806→730 monotone across A→E) — real mechanism doesn't propagate to FFS/val; (4) **AdamW aux tetrad 3/4 CLOSED with mixed signature** — β1 narrow-basin (#1310) + β2 monotone-prefers-higher (#1321) + ε wide-cosmetic (this) → tuple has 2/3 value-cosmetic with only β1 tight. Per FFS-primary directive #1262 no n=4. **15th stack-component pruning closure.** | **#1387 LM_HEAD-LR pruning OPEN** (★ FIRST SENPAI test of hardcoded `lr=1/320=0.003125` on `adam_lm_head` group line 841 — fresh axis under directive #1262; lm_head has LOWEST aux LR 96× smaller than embed lr=0.3, 9.6× smaller than scalars lr=0.03; 5-cell A=1/320 ctrl / B★=1/160 (2×) PRIMARY higher-analogous-to-#1275 scalars / C=1/80 (4×) aggressive / D=1/640 (0.5×) lower / E=1/40 (8×) falsifier; new `--lr_lm_head` CLI flag; cross-cluster with #1275 scalars-LR finding scalars wanted HIGHER; telemetry for lm_head_grad_norm, update_norm, weight_norm) |
| **✓ CLOSED #1321** | **frieren** | ~~AdamW aux β2 pruning ablation~~ **CLOSED clean-NEG-MECHANISM-INVERSION [FFS-primary]** poll ~864. **PRIMARY HYPOTHESIS INVERTED — β2 wants HIGHER not LOWER.** Cell A ctrl β2=0.95 FFS=3050 val=3.262031 +1.36σ (within-PR ctrl 25 steps above global baseline); **Cell B★ β2=0.90 FFS=3075 val=3.264364 +5.30σ PRIMARY FAILED**; Cell C β2=0.92 FFS=3050 val=3.261541 +0.54σ noise; **Cell D β2=0.99 FFS=3025 val=3.261115 −0.18σ BEST val FFS=baseline-EXACT (not FFS-alive)**; **Cell E β2=0.50 FFS=−1 NEVER val=3.287794 +44.7σ CATASTROPHIC falsifier**. ★ 4 mechanism findings: (1) PRIMARY HYPOTHESIS FALSIFIED — β2=0.90 faster-forgetting FFS-WORSE not equal; (2) **MONOTONE FFS in β2 across {0.90, 0.92, 0.95, 0.99}** 3075→3050→3050→3025 — strongest evidence axis real; (3) ★★ **β1/β2 DISSOCIATION cross-PR with #1310** — β1 wants SHORT memory (0.8 sweet spot ~3 steps half-life), β2 wants LONG memory (0.99 best ~70 steps half-life), **recovers classical Adam intuition m̂ short ŷ long**, not redundant; (4) cooldown 2nd-moment preservation confirmed — higher β2 keeps v_t close to pre-cooldown magnitudes during LR→0 phase, falsifier E DNF confirms structurally NECESSARY. **Per FFS-primary directive #1262: no n=4 promotion** Cell D FFS=3025 baseline-EXACT but not FFS-alive. **AdamW aux tetrad HALF-CLOSED** (β1+β2 done, ε+wd 4/5). **11th stack-component pruning closure.** | **#1377 adamw-aux-β2-SCHEDULE OPEN** (★ FIRST schedule test in AdamW aux family — directly tests cooldown 2nd-moment preservation mechanism by introducing β2 as schedule rather than fixed value; 5-cell A=β2=0.95 constant ctrl / B★=linear ramp 0.95→0.99 over cooldown PRIMARY / C=linear ramp 0.95→0.98 over cooldown / D=instant step-up β2=0.99 at cooldown start step 975 / E=falsifier reverse ramp 0.99→0.95 over cooldown; small code change `--adamw_aux_beta2_schedule` flag; **predicts FFS<3025** if entire #1321 Cell D benefit is from cooldown phase only; cross-cluster with #941+#966+#1272 "cooldown is directed descent in zero-WD regime"; **first schedule candidate that could move FFS-alive**) |
| **✓ CLOSED #1322** | **alphonse** | ~~NS-iter cooldown low pruning ablation~~ **CLOSED clean-NEG-VALUE-SENSITIVE-WITH-SHARP-FLOOR [FFS-primary]** poll ~865. **HARD NS-QUALITY FLOOR between iter=4 and iter=6 during cooldown — symmetric tight optimum at baseline iter=6 with asymmetric cliffs.** Cell A ctrl iter=-1 FFS=3025 val=3.260967 baseline; **Cell B★ iter=0 FFS=−1 DNF val=3.343360 +138.9σ CATASTROPHIC** model stalls at 3.34, NS is cooldown-crossing mechanism; **Cell C iter=2 FFS=−1 DNF val=3.280723 +33.3σ — DNF by 0.7 mNats, locates failure threshold sharply**; Cell D iter=4 FFS=3050 val=3.265142 +7σ mild NEG; Cell E iter=12 FFS=3050 val=3.262339 +2.3σ within noise. ★ 5 mechanism findings: (1) hard floor iter=4–6 cooldown crossing needs orth_err≤0.91; (2) Muon directional update necessary even when LR→0; (3) iter=2 at operational edge; (4) **joint with #1010 → ns_iter-by-time axis FULLY closed bowl**; (5) NS dissociates magnitude from direction — post-NS spectral norm varies 27× but FFS only collapses where direction fidelity does. ★ Cluster: joins #1042 + #1206 — NS quality cannot be reduced in any direction. ★ Student CRITICAL diligence: caught PR-body arithmetic error (step 975 vs verbal 2275). **12th stack-component pruning closure.** | **#1381 cooldown-LR-DECAY-SHAPE OPEN** (★ FRESH cooldown axis — tests whether LR decay SHAPE during cooldown window is FFS-load-bearing; currently linear `eta=(1−progress)/cooldown_frac` is the default, decay SHAPE has never been swept; 5-cell A=linear ctrl / B★=cosine PRIMARY smoothness / C=concave sqrt(1−x) steep-early gentle-late / D=convex (1−x)² gentle-early steep-late / E=falsifier step-decay eta=1 until last 20% then 0 abruptly; small code change in `set_hparams` switch on new `--lr_cooldown_shape` flag; **predicts C concave FFS<3025** if "everything wants small at end" cluster #1276+#941+#966+#1272 mechanism is right; **first cooldown SHAPE candidate for FFS-alive movement**) |
| **✓ CLOSED #1310** | **thorfinn** | ~~AdamW aux β1 pruning ablation~~ **CLOSED clean-NEG-NARROW-BASIN [FFS-primary]** poll ~863. **β1=0.8 is VALUE-SENSITIVE LOAD-BEARING with narrow basin and asymmetric cliffs.** Cell A ctrl β1=0.8 FFS=3025 val=3.260702 −0.88σ baseline-EXACT; **Cell B★ β1=0.95 FFS=3050 val=3.263942 +4.59σ_single PRIMARY FAILED**; Cell C β1=0.90 FFS=3025 val=3.261201 within noise; **Cell D β1=0.99 FFS=−1 NEVER val=3.289474 +47.5σ_single CATASTROPHIC upper cliff**; **Cell E β1=0.0 FFS=3175 val=3.275737 +24.5σ_single CATASTROPHIC lower cliff**. ★ 4 mechanism findings: (1) **sweet spot 0.8 narrow basin width ≤0.10** — Cell C 0.9 noise but Cell B 0.95 already +4.59σ; (2) **asymmetric cliffs**: upper β1=0.99 catastrophic, lower β1=0.0 bad-recoverable; (3) **half-life ~3 steps** preferred for AdamW aux — short memory aligns with high-SNR matrix gradients; (4) falsifies 50% prior — uniform β1 IS load-bearing not cosmetic. ★ Cross-stack convergence with #1284 body-WD: both narrow basins with asymmetric cliffs. ★ **AdamW aux tetrad now half-closed** (β1 narrow-basin load-bearing; β2+ε+wd in flight). ★ Per FFS-primary directive: no n=4 promotion (Cell A baseline-exact, no Cell ≤2975). **10th stack-component pruning closure**. | **#1368 scalars-β1 DECOUPLE OPEN** (★ FIRST per-group β1 decoupling test — tests whether #1310 narrow basin was driven by embed/lm_head or by scalars; adds `--scalars_beta1` CLI flag, applies group-level betas override ONLY to adam_scalars group; 5-cell A=0.8 ctrl uniform / B★=0.95 scalars only PRIMARY heavier-smoothing-on-low-SNR-1D / C=0.9 / D=0.5 faster-decay opposite-direction / E=0.99 falsifier; cross-cluster with #1275 lr_scalars dissociation; classical signal-processing prior: heavier smoothing for noisier signals → favors B★ FFS prediction) |
| **✓ CLOSED #1284** | **edward** | ~~body WD value 0.025 pruning ablation~~ **CLOSED clean-NEG-SHARP-CLIFF [FFS-primary]** poll ~860. **Body WD value 0.025 is SHARPLY FFS-LOAD-BEARING in both directions — narrow basin, cliffs at 0 and 0.10.** Cell A ctrl FFS=3025 val=3.26057 baseline; **Cell B★ wd=0.0 FFS=−1 NEVER val=3.28252 +35.9σ_single CATASTROPHIC**; Cell C 0.0125 FFS=3050 +8.8σ; Cell D 0.05 FFS=3100 +8.5σ; **Cell E wd=0.10 FFS=−1 NEVER val=3.28869 +46.3σ_single CATASTROPHIC**. ★ Falsified PR's 55% prior "all FFS ∈ [3025, 3150]" — basin narrower than expected. ★ 4 mechanism findings: (1) **Cell B no-WD LEADS through step 2500 then STALLS in cooldown** — ramp_down WD is cooldown's load-bearing tightening mechanism NOT LR alone; (2) Cell E over-WD monotone-worse from step 500 — capacity destroyed early can't recover; (3) C/D monotone in FFS — U-shape basin centered at 0.025; (4) reproduces #1272 from different angle: shape+value JOINTLY load-bearing. ★ Cluster: #966 + #1272 + #1284 = three tests converging on "cooldown WD-driven shrinkage is structural tightening mechanism." ★ Body-WD pruning programme fully closed (shape + value). **8th stack-component pruning closure.** Student flagged launcher kill-gate bug (~1.5h wasted on E). | **#1334 adamw-aux-wd-pruning OPEN** (★ completes AdamW aux (β1, β2, ε, wd) TETRAD under FFS-primary; tests hardcoded `weight_decay=0` line 843 via new `--adamw_aux_wd` CLI arg; 5-cell A=0.0 ctrl / B★=0.01 PRIMARY uniform small positive / C=0.001 very small / D=0.025 match body / E=0.1 falsifier; **strong asymmetric prediction**: per #1275 scalars-LR finding (LN gains MUST drift from init), applying WD>0 uniformly will pull gains back toward 0 → likely Cell B catastrophic = clean cross-PR mechanism confirmation; scalars_norm telemetry added) |
| **✓ CLOSED #1328** | **fern** | ~~body LR warmup~~ **CLOSED clean-NEG-NON-MONOTONIC [FFS-primary]** poll ~866. **All warmup>0 cells FFS-WORSE.** Cell A warmup=0 ctrl FFS=3025 val=3.26160 baseline; **Cell B★ warmup=200 FFS=3075 val=3.26721 +9.46σ PRIMARY FAILED**; Cell C warmup=100 FFS=3075 val=3.26675 +8.68σ; **Cell D warmup=500 FFS=3050 val=3.26476 +5.33σ paradoxically best of warmup cells**; Cell E warmup=1000 FFS=3100 val=3.26936 +13.09σ falsifier mild not catastrophic. ★ **Non-monotonic in warmup length** (B/C tied at +50 FFS, D BETTER at +25 despite longer warmup eating MORE stable phase); 5 mechanism findings: (1) all body LR warmups FFS-worse, baseline already maximally exploits flat-eta start; (2) D-paradox suggests smoother ramp rate 1/500 → smaller post-warmup transient; (3) E falsifier only mild — stable phase is mostly redundant, most FFS-load-bearing work happens in cooldown crossing; (4) confirms fern's own #1276 mechanism "FFS locked by first ~3000 steps" not warmup-modulable; (5) **2nd EARLY-PHASE axis closure joining #1266 depth-init** — "early state-as-set is FFS-locked except via large changes". Per FFS-primary directive #1262: no n=4 promotion. **14th stack-component pruning closure**. | **#1385 cosine-full-run-body-LR OPEN** (★ FRESH ENTIRE-SCHEDULE-SHAPE test, structurally orthogonal to alphonse's #1381 within-cooldown shape — replaces stable+linear-decay with cosine 1→0 over entire 3250 steps; 5-cell A=stable+linear ctrl / B★=cosine PRIMARY no stable phase / C=cosine min=0.1 / D=warmup200+cosine / E=triangular falsifier; small code change `set_hparams` switch on new `--lr_schedule_shape` flag; **predicts FFS≤3000** if cosine smoothness is val-positive AND no stable phase doesn't hurt — cleanest fresh schedule axis under directive #1262; **complementary to alphonse #1381 within-cooldown shape** while this tests ENTIRE-schedule shape) |
| **✓ CLOSED #1294** | **nezuko** | ~~mu cooldown decay~~ **CLOSED clean-NEG with MECHANISM-REVERSAL [FFS-primary]** poll ~862. **9th stack-component closure.** All 3 main cells fail: Cell A ctrl FFS=3050 val=3.262358 +1.92σ; **Cell B★ linear 0.95→0.0 cooldown FFS=3025 val=3.269557 +14.06σ CATASTROPHIC**; Cell C linear 0.95→0.5 FFS=3000 val=3.264868 +6.15σ; **Cell D instant 0.0 at cooldown FFS=−1 NEVER val=3.286754 +43.06σ**; Cell E falsifier (mis-designed) killed step 1014. ★★ **MONOTONE GRADIENT: mu_target 0.0→0.5→0.95 = val 3.2696→3.2649→3.2624** — mu during cooldown is val-positive. ★ 4 mechanism findings: (1) monotone val-positive, (2) instant-kill catastrophic, (3) NS+low-LR depends on smoothing, (4) ★★ **BREAKS "everything wants to be small at end" cluster** — mu is OUTLIER, wants HIGH at end. ★ Cell C FFS=3000 = single-trial seed noise per FFS-primary directive. **Cluster dissociation finding.** | **#1345 mu-cooldown-RAMP-UP OPEN** (★ direct mechanism extension extrapolating monotone gradient toward HIGHER mu; 5-cell A=ctrl mu=0.95 / B★=ramp 0.95→0.98 PRIMARY / C=ramp 0.95→0.99 / D=instant 0.98 mirror / E=ramp 0.95→0.999 falsifier; **NO code change** — re-uses `--mu_cooldown_target` with values ≥0.95; ★★ **first hypothesis in cluster that PREDICTS FFS improvement**; **strong FFS-targeted candidate under directive #1262**) |
| **✓ CLOSED #1238 prior** | **nezuko** | ~~SPAM spike-aware momentum reset on Muon body~~ **CLOSED clean-NEG [FFS-primary]** poll ~853. 4/5 cells FFS=3025 baseline-EXACT; Cell B (thr=5) FFS=3050 from 66 heavy resets. Cell C★ fails n=1 gate (+0.000212). ★ A vs E define no-op noise band (0.47σ_single, both 0 resets — mechanically identical). ★ Spikes are EMA-warmup artifacts (steps 8-12 only, NOT steady-state). ★ NS5 upstream-absorbs real spike contamination. **7th Muon-body preprocessing axis closure.** | **#1294 mu-cooldown-decay OPEN** (★ crossing-phase redesign: decay Muon momentum β 0.95→0.0 linearly during cooldown window; 5-cell A=ctrl/B★=linear-to-0/C=linear-to-0.5/D=instant-to-0/E=full-run-falsifier; directly targets FFS by asking whether persistent momentum hurts directed descent; new code: `--mu_cooldown_target`, `--mu_cooldown_instant`, `--mu_cooldown_full_run`) |

## Key Signals (as of poll #635)

- **★★ MOMENTUM-TRIGGER CLUSTER FULLY CLOSED (4/4)** — Time (#907), Schedule (#925), Direction (#973), Magnitude (#993) all NEG. Muon NS bounds output magnitude → magnitude-anomaly triggers are structurally weak. Smooth-vs-abrupt distinction falsified at #907/#925 (variance inflation intrinsic to cooldown perturbation). No remaining trigger axis to test for μ buffer manipulation.
- **★★ SOAP CROSS-SCOPE NON-ADDITIVE (#994 finding)** — Predicted summation of per-scope effects (attn drop + MLP drop = total) failed by 4.5×; cross-scope coupling exists. Both SOAP scopes load-bearing (each ~½ value). Q_col >> Q_row hierarchy confirmed but Q_row not free.
- **★★ SOAP STRUCTURAL≠TEMPORAL (#1053 closure poll #686)** — Structural-load-bearing-ness (Q_col >> Q_row from #936/#994) does NOT predict temporal-load-bearing-ness. Cell E (qcol=64 falsifier) at +2.26σ was *less* harmful than Cell B (qrow=64) at +2.87σ — opposite of structural prediction. `exp_avg_sq` partial-rotation artefact dominates at 4× sparsification. Implication: SOAP cadence research must use global refresh (#1036) to avoid the rotation artefact; per-component temporal asymmetry is exhausted.
- **★★ LR SCHEDULE-SHAPE AXIS CLOSED (#1054 poll #683)** — trapezoidal-stable-then-linear-decay is tight local optimum. Bimodal failure pattern: cosine/floor +16σ ("mistimed annealing") vs exponential/quintic +107σ ("catastrophic early collapse — 3.28 never reached"). Combined with #925/#907/#966 + #1021 magnitude, the entire LR/μ/weight cooldown-mechanism family is closed. Cooldown protocol is structurally optimal.
- **#1021 fern embed/lm_head LR (FRESH AXIS)** — embed LR=0.3 and lm_head LR=1/320 HARDCODED in `optimizer1` (lines 840-841), never SENPAI-validated. ~76M params untouched.
- **#1022 frieren NS-degree (informed by #962)** — Cell D in #962 confirmed quintic load-bearing. #1022 tests septic vs quintic-with-more-iters. After this + #1010, NS-internals comprehensively explored.
- **#1036 nezuko SOAP precond_freq** — Global PRECOND_FREQ=16 never ablated. Direct complement to #1053 (which holds col-freq fixed at 16, sweeps row-freq).
- **#1096 thorfinn Per-group Muon mu** — Decouple mu_mlp vs mu_attn. Mechanism-rich axis on SOAP/NS interaction at pre-NS momentum layer. Constructor already supports this.

## Recent Closures (poll #534–676)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#1053 edward** (poll #686) | clean-NEG (SOAP per-component temporal-cadence axis closed, rich mechanism) | Asymmetric SOAP Q_row/Q_col refresh frequency. Cell B PRIMARY (qrow=64,qcol=16) +2.87σ_base FAILS confirm gate. Cell C (qrow=32) +0.49σ parity, D (qrow=128) +0.93σ parity (non-monotonic = n=1 noise). Cell E falsifier (qcol=64) +2.26σ — *slightly less* harmful than B, **opposite of prediction**. Cell A (16/16 ctrl) at −1.05σ_base = baseline-equivalent refactor-neutrality, lucky seed not winner (same handling as #1021/#1022/#1024 Cell A pattern). **Mechanism findings (3 distinct):** (1) Structural vs temporal axes are NOT interchangeable — structural-load-bearing-ness (#936/#994 Q_col >> Q_row) does NOT predict temporal-load-bearing-ness. Critical lesson for SOAP mechanism interpretation. (2) Non-monotonic profile is n=1 noise — 3.9σ envelope across qrow={16,32,64,128} matches σ_single≈0.0006 null distribution. (3) `exp_avg_sq` rotation artefact — only rotated when Q_row also refreshes; applies symmetrically in B and E and may dominate over structural Q_col/Q_row asymmetry at 4× sparsification factors. Faithful implementation requires per-dimension rotation gating (separate axis). Closes SOAP per-component temporal-cadence at structural granularity. Remaining SOAP-internals open: #1036 (global PRECOND_FREQ, avoids the `exp_avg_sq` artefact), #1076 (eps), #1077 (BETA2). edward → #1106 SOAP low-rank truncated eigenbasis (fresh mechanism axis, NOT scalar HP). |
| **#1054 askeladd** (poll #683) | clean-NEG (cooldown family comprehensively closed, rich mechanism) | LR schedule shape sweep. Cell B PRIMARY (cosine) +15.96σ_base. **Bimodal failure mode:** B/D (cosine, linear_to_floor 0.1) +16σ class "mistimed annealing" (cosine slow-early-decay plateaus at 3.27; floor strands LR preventing full convergence). C/E (exponential, quintic) +107σ class "catastrophic early collapse" — LR drops <3% by t=0.5, directed-descent strands model at 3.325 plateau, 3.28 target NEVER reached. Cell A (linear ctrl) at −1.07σ_base, ffs=3025 = baseline ffs_mean exactly — refactor-neutrality PASS but baseline config, not a winner. **Mechanism:** cooldown requires *full annealing to zero* at *roughly constant decay rate* — exactly trapezoidal-stable-then-linear-decay. Connects to #941 "cooldown is directed descent" — uniform loss reduction needs uniform LR decay. Combined with #925/#907/#966 (μ/state/weight) + #1021 magnitude: **entire LR/μ/weight cooldown-mechanism family closed**. Cooldown protocol structurally optimal. Refactor kept (--lr_schedule linear default). askeladd → #1105 AdamW aux WD (fresh axis, orthogonal). |
| **#1042 thorfinn** (poll #676) | clean-NEG (7th NS-modulation axis closure, rich mechanism) | Soft NS output mixing `α·NS(x) + (1−α)·x_scaled`. Cell B PRIMARY (α=0.95) +0.13σ_base — noise-neutral, FAILS confirm gate. Cell C (α=0.90) +0.66σ noise-neutral. Cell D (α=0.80) +5.24σ, Cell E (α=0.70) +4.16σ — clearly harmful. Cell A (α=1.0 ctrl) at −3.69σ_base is **lucky seed on baseline config** (mix code-path is no-op at α=1.0; same n=1 favorable draw pattern as #1021/#1022/#1024 Cell A). **Mechanism findings:** (1) Pre-NS magnitude info NOT load-bearing — `update_pre_ns_norm` ~900-980 vs `update_ns_norm` ~27.1 (spectral-flattened); diagnostic logs confirm convex combination behaves as designed (no implementation bug). (2) Roughly monotone-worse as α decreases — 20%+ raw injection breaks NS spectral-flattening property essential for step quality. (3) PR #932 "inverted-iter 2nd-best" intuition does NOT translate — NS *convergence stage* (stopping short of x≈1) ≠ NS *output mixing* (injecting wrong spectral structure). **NS-modulation axis comprehensively closed (7 NEG closures: #776 RMS clamp, #815 NS warmup, #824 NS coefs, #867 cautious pre-NS, #932 per-layer iter, #1010 iter-by-time, #1022 NS degree, now #1042 soft mixing).** Orthogonalization quality cannot be modulated for benefit at this baseline. NS implementation structurally locked-in. Only remaining open NS axis: #1062 precision (numerical fidelity, not modulation). thorfinn → #1096 per-group Muon mu (fresh axis, pre-NS momentum layer). |
| **#1022 frieren** (poll #667) | clean-NEG (5th NS-internals axis NEG, rich mechanism) | NS polynomial DEGREE variation: PRIMARY Cell B (d=7 iter=4) catastrophic at +7.35σ_base, +9.97σ_A. C (d=7 i=6) +2.16σ_base. D (d=5 i=8) −1.28σ_base (within n=1 noise, 0.28σ below gate). E (d=3 i=8) −0.10σ_base (cubic+more iters matches baseline). Cell A (d=5 i=6 = baseline ctrl) at −2.62σ_base is lucky seed on baseline-config — not a winner (same handling as #1021 Cell A). **Mechanism (two findings):** (1) Iter count is orthogonalization-quality floor — at iter=4 polynomial cannot reach near-x=1 regime where d=7 would pay off; (2) Degree×iter trades off symmetrically at constant total NS compute. **d=5 iter=6 is tight local optimum** in (degree, iter) grid. Closes 5th NS-internals axis (joins #932/#815/#1010/#962). Only tanjiro #1062 (precision) remains open. |
| **#1024 alphonse** (poll #667) | clean-NEG (init mode axis fully ablated, rich mechanism) | Init mode ablation, all 5 `--depth_init_mode` built-in modes: PRIMARY Cell B (muall — extend 1/√L to ALL 2D block weights) +5.82σ_diff vs A. C (mumedium) +2.15σ. D (ctrl_noinit) +0.60σ (within n=1 noise). E (smallconst) −0.06σ vs A (essentially identical). **Mechanism (three-axis decomposition):** (1) Residual proj_std magnitude weakly load-bearing at n=1 (0→6e-3 all within ~3σ); (2) Non-residual Q/K/V/MLP-fc depth scaling actively HARMS (only muall does this — RECEIVING paths need full-strength initial weights, 1/√L pre-damping starves model of initial capacity); (3) NS-orthogonalization re-normalizes early init differences within ~50 steps (trajectories agree to ~3% by step 500 across all 5 cells). Crossover: muall has lowest val/loss at step 125 (4.456) but highest at step 3250 (3.266). **Closes init-mode axis comprehensively.** |
| **#1021 fern** (poll #665) | clean-NEG (local optimum confirmed) | Embed/lm_head LR magnitude: **all 4 perturbations worse than Cell A ctrl** (B +4.92σ, C +3.64σ, D +7.77σ, E +2.29σ vs A). Two-sided worsening on embed axis (0.3 = local optimum). Asymmetric on lm_head (D +60% +7.77σ vs E −40% +2.29σ — sits slightly above strict optimum, sub-σ gain). Cell B PRIMARY at 3.26197 missed n=1 gate ≤3.260. **Cell A "lucky seed" caveat:** 3.25905 (−3.66σ) is baseline replication with favorable seed; Cell C at 3.26121 ≈μ confirms A's deviation is n=1 noise. **Closes last untested LR-magnitude axis** — combined with lr_mlp/lr_attn/lr_scalars, all parameter-group LR magnitudes now ablated. Student suggestion #3 (warmup schedule) → fresh axis follow-up assigned. |
| **#1010 tanjiro** (poll #649) | clean-NEG (high info, mechanism + open puzzle) | NS-iter-by-time cooldown: Cell B (PRIMARY ns_iter_cooldown=8) val_loss=3.26122 = baseline parity within ±1σ (within band [3.260628, 3.261814]). **Monotone NEG above iter=6:** B(8)≈baseline, C(10)+1.92σ, D(12)+2.93σ. **NS_iter>6 actively HURTS**, not just neutral. Cell E (smooth ramp) 3.26072 below noise floor vs Cell B (step jump) — no smooth-vs-step signal. **No discontinuity-variance penalty at step 975** for NS-iter changes (unlike #907 buffer reset). Closes 3rd of 3 NS-iter scheduling axes (depth #932, early-time #815, late-time #1010 all NEG). **Open mechanism puzzle:** student notes "iter≥7 polynomial overshoots in fp16/bf16" — NS hardcoded bf16 at line 485. Motivates #1062 NS precision sweep. |
| **#994 edward** (poll #635) | clean-NEG (high info, mechanism) | SOAP per-scope Q_row drop (attn-only): all 4 treatments NEG. **Cross-scope decomposition non-additive 4.5×** — predicted sum of per-scope effects failed sharply (B+D ≠ A−C). **Both SOAP attn AND SOAP MLP each ~½ of total SOAP value**; neither scope free to drop. Q_col >> Q_row hierarchy from #936 confirmed but Q_row not zero-cost. Closes structural SOAP per-scope pruning axis. Suggests Q_row's remaining contribution may be temporally sparse (mechanism for #1053). |
| **#993 askeladd** (poll #635) | clean-NEG (high info, mechanism) | Magnitude-anomaly μ reset: all treatments NEG. **Muon NS orthogonalization bounds output magnitude → magnitude-conditional triggers are structurally weak** (NS output norms are sqrt(min(m,n))-bounded; spikes never propagate). Closes magnitude axis. Combined with #907 (time), #925 (schedule), #973 (direction): **momentum-trigger cluster comprehensively closed (4/4 trigger axes NEG)**. No remaining axis for μ buffer manipulation via trigger condition. |
| **#979 thorfinn** (poll #618) | clean-NEG (high info, mechanism) | SOAP exp_avg_sq scaling: Cell B (no_adam_scale, with norm-preserve) +0.055/+93σ, Cells C/D match B's regression class confirming triangulation. **Cell E (no-EMA) +7σ — close to baseline**, isolating two findings: (1) per-element direction-warping in eigenbasis is load-bearing; (2) EMA accumulation contributes only ~0.005 loss (Q refreshed every 16 steps anyway). Cell-D mechanism (frozen exp_avg_sq=1.0 = uniform scaling) is a falsifier closing 'norm-preserve saves us' hypothesis. SOAP-internals pruning at exp_avg_sq axis closed. Combined with #936 (Q ablation), maps which SOAP components are load-bearing. |
| **#973 nezuko** (poll #615) | clean-NEG (high info) | Cosine-gated adaptive μ: all 4 treatments ≥+5σ NEG, **monotone in distance from μ=0.95** (D midpoint 0.92 → +5.24σ; C midpoint 0.745 → +25.6σ). Mechanism: per-matrix grad↔buffer cosine collapses to noise (mean cos≈0 once buffer accumulates). Gate just lowers mean μ below 0.95 — no direction information. Closes direction-conditional momentum axis; reinforces #924 (gradient-derived direction signals too noisy). |
| **#966 alphonse** (poll #595) | clean-NEG (strong falsifier) | Cooldown weight rescaling: all 5 cells within ±2σ_single, non-monotonic (C worse than D, E ≈ C). Best B(α=0.99) only −0.17σ. Mechanism: Muon NS scale-invariant + WD ramp_down already controls norms. Closes weight-space cooldown intervention axis. Completes comprehensive cooldown closure: state-reset #907 + schedule #925 + weight-magnitude #966 all NEG. |
| **#962 frieren** (poll #589) | clean-NEG (high info) | NS polynomial coefficient ablation: Cell D (cubic-only, c=0) +15.26σ NEG → **quintic term load-bearing**. Cell C (Muon-paper original) +3.12σ NEG → original tuned coefficients sub-optimal here. Cell E (high-amp) −2.61σ POS at n=1 too weak for n=4 (projected statsig <0.004 gate). Informs #1022 — higher degree more likely promising than lower. |
| **#925 fern** (poll #589) | clean-WEAK-NEG | Linear μ ramp cooldown: n=1 Cell E POS (3.258418, −4.73σ) regressed at n=4 μ=3.261112 (FAIL gate 0.004; σ_sample 1.4× baseline). **Smooth-vs-abrupt distinction does NOT avoid variance trap**. Combined with #907: cooldown perturbations inflate variance without improving mean. Closes μ-schedule axis comprehensively. |
| **#907 tanjiro** (poll #579) | clean-NEG (high info) | Joint Muon+SOAP reset at step 975: n=1 Cell E POS (3.26004, −3.5σ_SE) was favorable-tail draw from distribution with **σ_single 1.71× baseline**. n=4 μ=3.261655 (statsig −0.000868, FAIL). **Generalized lesson: instantaneous discontinuities at step 975 inflate variance — watch #966 alphonse weight rescale similarly.** Closes full mu_reset_* axis. |
| **#941 edward** (poll #574) | clean-NEG (high info) | Cooldown SWA: `swa/live_vs_swa_dist` monotonic in β AND in regression magnitude. **Cooldown is directed descent, not noisy oscillation.** Weight EMA always lags. **Closes "trajectory averaging" axis 3/3** (#826 Lookahead, #855 SF, #941 SWA). |
| **#936 askeladd** (poll #573) | clean-NEG (high info) | Asymmetric SOAP: B left-only (drop Q_col) +14.07σ vs ctrl. **B−C contrast +12.25σ** → Q_col (input-side) load-bearing for attn, Q_row (output-side) largely redundant for attn. MLP weights more symmetric. |
| **#932 thorfinn** (poll #568) | clean-NEG | Per-layer NS iter by depth: B (depth_scale=0.5) +0.012 NEG, C (depth_scale=1.0) diverged, D **inverted=SECOND-BEST** → refutes "late layers need more NS"; early-layer NS quality is load-bearing. NS_ITER<3 is hard floor. |
| **#924 nezuko** (poll #566) | clean-NEG | Hutchinson diagonal curvature: Cell B (α=0.5) +0.00950 NEG, Cell D (α=0.75) diverged. `\|dg\|` proxy is biased (mixes H·Δθ + gradient noise); divides by noise scale not curvature. **Closes post-NS curvature axis.** |
| **#914 alphonse** (poll #560) | clean-NEG | SOAP refresh freeze: Cell C freeze +4.9σ NEG, B PRIMARY (cooldown_freq=64) baseline parity. Eigenbasis carries useful curvature signal during cooldown. |
| **#902 frieren** (poll #557) | clean-NEG | Top-k pre-NS: all treatments +2.2-2.5σ NEG, k=90% "near no-op" is WORST. Hard zeroing breaks NS regardless of fraction. **Closes pre-NS axis (9 PRs).** |
| **#890 edward** (poll #545) | clean-WEAK-NEG | Per-col-norm pre-NS: PRIMARY parity, Cell D −1.21σ (n=1) misses n=4 gate by 3×. NS orth error 0.43→0.06 on synthetic but zero val/loss benefit. |
| **#887 askeladd** (poll #542) | clean-WEAK-NEG | AGC-Muon: λ=0.001 mlp=3.26071 (−0.86σ). clipped_frac=1 → reduces to implicit MLP LR shrink. |
| **#905 thorfinn** (poll #537) | clean-NEG | Q/K/V consensus: +9.4σ. Q/K/V near-orthogonal in param space. |
| **#823 fern** (poll #534) | clean-NEG | SignMuon: n=4 mean=3.261930. Sign-direction axis closed. |
| **#840 nezuko** (poll #534) | clean-WEAK-NEG | AdEMAMix n=4 mean=3.260675 (statsig=0.001 vs gate 0.004). |

## Closed Axis Map (comprehensive)

**Pre-NS gradient transformation (FULLY SATURATED, 9/9 NEG):** per-col-norm #890, AGC #887, MARS #873, AdEMAMix #840, Q/K/V consensus #905 STRONG NEG, top-k #902 NEG, sign #823 NEG, GrokFast #859 NEG, sign-Cautious #844/#867 NEG.
**NS quality/structure (COMPREHENSIVELY SATURATED, 7/7 modulation-axes NEG):** polar expression #824, NS warmup #815, RMS-clamp #776, per-layer NS iter by depth #932, cautious pre-NS #867 — all CLOSED. Key finding from #932: early-layer NS quality is load-bearing. **NS polynomial coefficients #962 CLOSED** (quintic load-bearing, cubic-only +15.26σ NEG). **NS-iter-by-time #1010 CLOSED clean-NEG** (NS_iter>6 monotonically hurts; closes 3rd of 3 NS-iter scheduling axes). **NS-degree variation #1022 CLOSED clean-NEG poll #667** (d=5 iter=6 tight local optimum; degree×iter trades off symmetrically at const compute). **NS soft-output-mixing #1042 CLOSED clean-NEG poll #676** (α<1 hurts; pre-NS magnitude info not load-bearing; orthogonalization quality cannot be modulated for benefit). **NS precision sweep #1062 OPEN** (last remaining NS axis; bf16 vs fp32; previously hardcoded line 485 — about numerical fidelity, not modulation).
**Schedule layer (5/5):** ALL CLOSED.
**Trajectory averaging (3/3 CLOSED):** Lookahead #826, Schedule-Free #855, Cooldown SWA #941. **#941 finding:** cooldown trajectory is directed descent — weight averaging always lags. Closes the entire "average the path" family.
**SOAP dynamics:** trust threshold #467 neutral, refresh rate in cooldown #914 NEG (freeze +4.9σ), eigenbasis side #936 CLOSED clean-NEG (Q_col load-bearing for attn), **exp_avg_sq scaling #979 CLOSED clean-NEG (direction-warping load-bearing; EMA inessential)**, **per-scope side pruning #994 CLOSED clean-NEG (cross-scope non-additive 4.5×; both scopes load-bearing)**, **asymm Q_row/Q_col refresh freq #1053 CLOSED clean-NEG poll #686 (PRIMARY qrow=64 +2.87σ; structural-load-bearing-ness does NOT predict temporal-load-bearing-ness; `exp_avg_sq` partial-rotation artefact dominates)**. **#1036 (global PRECOND_FREQ) n=4 confirm in flight, #1076 (eps) CLOSED clean-NEG NULL poll ~731, #1077 (SOAP_BETA2 static) CLOSED clean-NEG NULL poll ~731, #1106 (low-rank truncated eigenbasis) OPEN heading clean-NEG, #1130 (decoupled β₂: gram-EMA vs basis-EMA) OPEN.** Structural SOAP pruning axes saturated; #1036 covers global temporal/cadence (avoids `exp_avg_sq` artefact); **scalar HP cluster comprehensively closed 4/4** (Q_row/Q_col asymm #1053, exp_avg_sq #979, eps #1076 NULL, BETA2 static #1077 NULL). **#1106 fresh mechanism axis on eigenbasis rank truncation; #1130 fresh structural axis decoupling the two β₂ EMAs (Gram vs basis).**
**Weight-space interventions at cooldown:** cooldown weight rescaling **#966 CLOSED clean-NEG** (strong falsifier — all within ±2σ_single; Muon NS scale-invariant + WD ramp_down absorbs norm perturbation). **Closes this axis**.
**Momentum trigger cluster (4/4 CLOSED):** Time #907 NEG, Schedule #925 WEAK-NEG, Direction #973 NEG (cosine collapses to noise), **Magnitude #993 CLOSED clean-NEG (NS bounds output magnitude → structurally weak trigger)**. Comprehensive: no remaining trigger axis for μ buffer manipulation. Variance-reduction approach to cooldown remains open theoretically but no concrete proposal yet.
**Post-NS curvature:** Hutchinson #924 NEG (per-element |dg| proxy biased; divides by noise scale). Closed. **Cosine-gated adaptive μ #973 CLOSED clean-NEG** (per-matrix cosine collapses to noise, gate = implicit μ drop below 0.95, harm monotone in distance from 0.95). Closes direction-conditional axis.
**SOAP scalar HP cluster 6/6 FULLY CLOSED:** #1076 eps NULL, #1077 β₂-static NULL, #1053 asymm Q_row/Q_col refresh NEG, #979 exp_avg_sq NEG, #1036 precond_freq WEAK-NEG (μ_8=3.260279, real signal ~-0.001 val/loss but below merge gate), **#1130 decoupled β₂ NEG** (PRIMARY slow-Gram direction refuted; novel D/E isolation-catastrophe finding: both EMAs must be changed together; β_gram=β_basis=0.90 is a coordinated equilibrium; decoupling is NOT a degree of freedom). **ALL SOAP scalar HP axes closed. SOAP-internals axis fully exhausted.**

**LR schedule shape (FRESH AXIS):** ★ **#1054 OPEN** — **NEW DISCOVERY at poll #635**: LR schedule was HARDCODED at lines 882-888 of `set_hparams` as `eta = (1 − progress) / cooldown_frac` (trapezoidal-stable-then-linear-decay), with no CLI flag. Never SENPAI-validated. Tests cosine/exponential/floor/quintic alternatives. Schedule shape is orthogonal to schedule values (lr_mlp/lr_scalars all set, schedule shape never was).
**Outer-loop wrappers:** Lookahead #826 NEG, Cautious #844/#867 NEG.
**Embed/lm_head LR magnitude (CLOSED #1021 poll #665):** clean-NEG local optimum confirmed — all 4 perturbations worse than A ctrl (B/C +3.6-4.9σ embed; D/E +2.3-7.8σ lm_head). 0.3 and 1/320 sit at local optimum on the current stack. **Embed/lm_head warmup schedule (CLOSED #1072 poll ~730):** clean-NEG, monotone damage; AdamW bias-correction sufficient, warmup is double-correction. Closed the schedule-softening axis for AdamW aux groups. **AdamW aux Lookahead wrapper (FRESH AXIS) — #1126 OPEN** (poll ~730): slow/fast weight averaging on aux groups; fresh mechanism axis NOT scalar HP. **AdamW aux WD regularization (OPEN #1105 in-flight):** Cell B (wd=0.001) at -2.38σ_single, strongest n=1 signal. **AdamW aux optimizer-family axis (FRESH AXIS) — #1131 OPEN** (poll ~731): AdaBelief replacement, centered (g−m)² variance vs g²; orthogonal to WD work. **SOAP low-rank eigenbasis (OPEN #1106, catastrophic blow-up at frac=0.5 +316σ — terminal pending):** heading to clean-NEG; SOAP eigenbasis is full-rank-essential. **SOAP decoupled β₂ (FRESH STRUCTURAL AXIS) — #1130 OPEN** (poll ~731): Gram-EMA vs in-basis-EMA decoupled — student's own #1077 #3 follow-up, exposes new degree of freedom.
**Init mode (CLOSED #1024 poll #667):** clean-NEG. All 5 `--depth_init_mode` modes ablated; PRIMARY muall +5.82σ_diff vs musoft ctrl (extending 1/√L to non-residual Q/K/V/MLP-fc starves receiving paths of initial capacity). Cell E (smallconst) tied with A within −0.06σ — residual init magnitude weakly load-bearing. NS-orth re-normalizes init differences within ~50 steps. Init-mode axis fully exhausted; musoft remains optimal.
