# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-30 02:50 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
- **Human directive #1252:** Prioritize (a) optimizer-state resets at phase boundaries, (b) per-layer/per-block optimizer behavior, (c) short phase-specific mechanisms, (d) momentum/preconditioner state handling, (e) schedules that steepen loss descent before step 2925. Avoid pure scalar β/μ/EMA sweeps.

## 🚧 PLATEAU PROTOCOL ENGAGED — all body Muon scalar axes exhausted; now on Tier-2 structural mechanisms + aux Adam exploration

### Definitively closed axes

**Body Muon pre-target scalar pulses (ALL BILATERAL NULL):**
- LR-UP (#1637), LR-DOWN (#1697), γ (#1680), μ (#1686 — all temporal regimes), NS-coefs (#1660), β₁ (#1592/#1639), β_cov (@975 + @2600 via #1666), weight_decay (#1693), Nesterov, schedule-free

**Structural state interventions (BILATERAL NULL):**
- L_cov/R_cov hard zero RESET at pre-target step 2750 (#1726 nezuko) — Arm A sr=2950 NULL, Arm B sr=2875 close miss +1.07 mnat; cov-state replacement CLOSED at pre-target
- Body Muon momentum buffer hard ZERO RESET at step 2750 (#1730 askeladd) — Arm A CRASHED (exit 137 pre-reset), Arm B sr=2925 +3.70 mnat NULL; momentum state-discard CLOSED at pre-target boundary
- ADOPT-style async whitening (#1703 alphonse) — Arm A sr=2975, Arm B sr=2950; update-rule asynchrony CLOSED on body PMuon

**Structural decoupling (BILATERAL NULL):**
- Depth-stratified β_cov binary split (#1727 edward) — falsifying Arm B beat mechanistic Arm A (contradicts LR-cov phase-coupling story); axis FULLY CLOSED across binary split + continuous ramp (#1339)
- Stacked pEMA refresh @ 2750/2850 (#1704 thorfinn) — bilateral NULL; canonical 2600 is singular optimum

**β₂ pulse mechanism:** amplitude, timing, shape, per-group recipient, pre-target re-spike — ALL NULL except canonical 0.95→0.99 @ 975 (#1532 WIN)

**Optimizer replacements:** Lookahead, AdaShift per-element, AdaShift block-wise, SOAP — all closed

### 🔥 Cross-PR sr=2875 close-miss signal

Two independent mechanisms hit baseline sr this session:
- frieren #1708 Arm B (UW=0.55) seed-1: sr=2875, val_ema 3.263116 (+0.262 mnat above gate) — seed-2 in flight
- nezuko #1726 Arm B (cov-reset + β_cov pulse): sr=2875, val_ema 3.263927 (+1.07 mnat above gate)

**Signal:** sr=2925→2875 wall IS breakable. Val_ema in the final 250 steps (steps 3000–3250) is the tightening bottleneck. Reorienting new hypotheses toward val_ema descent in the cooldown phase.

## Active assignments (all 8 students engaged on r1)

| PR | Student | Experiment | Status | Arms |
|---|---|---|---|---|
| **#1773** | **askeladd** | **paramEMA β hard step-drop at step 2750 (0.99→0.90 / 0.99→0.95)** | **Just assigned** | **Arm A: 0.90; Arm B: 0.95** |
| **#1770** | **nezuko** | **Aux Adam m/v hard zero reset at β₂-pulse boundary (step 975 / step 1200)** | **Just assigned** | **Arm A: @975; Arm B: @1200** |
| **#1771** | **edward** | **ACProp async denominator on aux AdamW — v_t uses g_{t-1}² (all groups / embed only)** | **Just assigned** | **Arm A: all; Arm B: embed_only** |
| #1752 | alphonse | Newton-Muon activation-Gram right-preconditioner on body PMuon | Running — Arm A `rh2iinb5` in flight | Arm A: diagonal Gram; Arm B pending |
| #1749 | thorfinn | AdEMAMix dual-EMA first moment on aux AdamW | Running — Arm A `1p20ntln` in flight | Arm A: α=0.5/β₃=0.999; Arm B pending |
| #1742 | tanjiro | Pre-target depth-asymmetric per-block LR burst ×1.5 | Arm A NULL (sr=2925); Arm B `p18t6opk` in flight | Arm B: late-higher burst |
| #1739 | fern | Pre-target NS_ITERS burst 12→{14, 18} @ step 2750 | Arm A NULL (sr=2925); Arm B `ossp58zg` in flight | Arm B: NS_ITERS=18 |
| #1708 | frieren | Pre-target Skylight u/w floor pulse (0.45 / 0.55) | Arm A NULL (sr=2925); **Arm B CLOSE MISS sr=2875 val_ema 3.263116; seed-2 `xkr7c9rl` in flight** | HOT WATCH seed-2 |

## Current research themes

**Aux Adam structural exploration (new this session):**
- Directive (a): Aux Adam m/v state reset at β₂ pulse boundary (nezuko #1770)
- Directive (d): ACProp async denominator on aux AdamW optimizer (edward #1771)
- Directive (e): paramEMA β step-drop at pre-target window (askeladd #1773)
- Context: aux Adam β₂ pulse is the most recent WIN (#1532); exploring the β₂ pulse boundary as an optimizer-state phase transition

**Body PMuon structural exploration (in-flight):**
- Directive (b): Activation-Gram right-preconditioner (alphonse #1752) — per-matrix input curvature signal
- Directive (b): Depth-asymmetric per-block LR burst (tanjiro #1742) — per-block LR behavior
- Directive (c): NS_ITERS burst pre-target (fern #1739) — phase-specific iteration count change
- Directive (e): AdEMAMix dual-EMA aux Adam (thorfinn #1749) — compound momentum on aux side

**HOT WATCH:**
- frieren #1708 Arm B (UW=0.55) seed-2 `xkr7c9rl` — if sr=2875 and val_ema < 3.262854, immediate merge

## Next hypotheses queue (post current wave)

1. **GrokFast slow-gradient amplification after NS whitening** — zero matches in 329-PR history; applies slow-EMA gradient amplification in whitened gradient space during cooldown; directive (c/d)
2. **L_cov/R_cov reset at cooldown onset (step 975)** — distinct from pre-target reset (step 2750); resets bilateral whitening at phase boundary where gradient geometry changes sharply; directive (a)
3. **Block-wise AdaShift** (scalar v_t per tensor) — orthogonal to per-element closure (#1709); much cheaper and avoids sparse-grad failure mode
4. **Cov-state PARTIAL reset (early-blocks only)** — if cov reset at step 975 shows any signal, narrow scope
5. **Body Muon SOAP-style off-diagonal L/R refresh** — unexplored preconditioner update structure

## Key insights guiding research

- The canonical β₂ pulse at step 975 is a confirmed WIN (#1532); it converts a phase boundary into an optimizer-state intervention. Testing analogous phase-boundary interventions on different optimizer state (m/v in aux Adam, β in paramEMA) is the natural next direction.
- Body Muon state (first-moment momentum buffer, second-moment L_cov/R_cov) is load-bearing at the pre-target boundary: hard resets at step 2750 consistently fail (#1726, #1730). The momentum buffer especially was providing useful direction (not just staleness).
- The sr=2875 wall is breakable (frieren #1708 seed-1 confirms it). The bottleneck is val_ema in the final 250 steps. This points toward better EMA tracking (paramEMA β drop) and/or cleaner aux Adam state in the cooldown phase.
