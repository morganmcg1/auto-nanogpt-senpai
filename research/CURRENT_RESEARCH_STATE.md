# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-30 04:10 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
- **Human directive #1252:** Prioritize (a) optimizer-state resets at phase boundaries, (b) per-layer/per-block optimizer behavior, (c) short phase-specific mechanisms, (d) momentum/preconditioner state handling, (e) schedules that steepen loss descent before step 2925. Avoid pure scalar β/μ/EMA sweeps.

## 🚧 PLATEAU PROTOCOL ENGAGED — all body Muon scalar axes exhausted; now on Tier-2 structural mechanisms + aux Adam exploration

### Definitively closed axes

**Body Muon pre-target scalar pulses (ALL BILATERAL NULL):**
- LR-UP (#1637), LR-DOWN (#1697), γ (#1680), μ (#1686 — all temporal regimes), NS-coefs (#1660), β₁ (#1592/#1639), β_cov (@975 + @2600 via #1666), weight_decay (#1693), Nesterov, schedule-free

**Structural state interventions (BILATERAL NULL):**
- L_cov/R_cov hard zero RESET at pre-target step 2750 (#1726 nezuko) — Arm A sr=2950 NULL, Arm B sr=2875 close miss +1.07 mnat; cov-state replacement CLOSED at pre-target
- Body Muon momentum buffer hard ZERO RESET at step 2750 (#1730 askeladd) — Arm A CRASHED, Arm B sr=2925 +3.70 mnat NULL; momentum state-discard CLOSED at pre-target boundary
- ADOPT-style async whitening (#1703 alphonse) — Arm A sr=2975, Arm B sr=2950; update-rule asynchrony CLOSED on body PMuon

**Structural decoupling (BILATERAL NULL):**
- Depth-stratified β_cov binary split (#1727 edward) — falsifying Arm B beat mechanistic Arm A; axis FULLY CLOSED across binary split + continuous ramp (#1339)
- Stacked pEMA refresh @ 2750/2850 (#1704 thorfinn) — bilateral NULL; canonical 2600 is singular optimum

**β₂ pulse mechanism:** amplitude, timing, shape, per-group recipient, pre-target re-spike — ALL NULL except canonical 0.95→0.99 @ 975 (#1532 WIN)

**Optimizer replacements:** Lookahead, AdaShift per-element, AdaShift block-wise, SOAP — all closed

**TARGET_UW floor pulse family (FULLY CLOSED):**
- #1708 frieren (short-window 0.45/0.55 @ 2750-2900, n=2 bilateral seed confirmation) — NULL. Five experiments across magnitude × timing × window.

### 🔥 Cross-PR sr=2875 close-miss signal

Two independent mechanisms hit baseline sr (bilateral nulls, but sr=2925→2875 wall IS breakable):
- frieren #1708 Arm B (UW=0.55) seed-1: sr=2875, val_ema 3.263116 (+0.262 mnat above gate) → seed-2 failed to confirm
- nezuko #1726 Arm B (cov-reset + β_cov pulse): sr=2875, val_ema 3.263927 (+1.07 mnat above gate)

**Signal:** val_ema in the final 250 steps (steps 3000–3250) is the tightening bottleneck.

## Active assignments (all 8 students engaged on r1)

| PR | Student | Experiment | Status | Arms |
|---|---|---|---|---|
| **#1780** | **frieren** | **Body PMuon L_cov/R_cov hard zero reset at cooldown onset (step 975 vs 1100)** | **Just assigned** | **Arm A: reset@975; Arm B: reset@1100** |
| #1773 | askeladd | paramEMA β hard step-drop at step 2750 (0.99→0.90 / 0.99→0.95) | Running | Arm A: 0.90; Arm B: 0.95 |
| #1770 | nezuko | Aux Adam m/v hard zero reset at β₂-pulse boundary (step 975 / step 1200) | Running — Arm A `mhzwt7ge` in flight | Arm A: @975; Arm B pending |
| #1771 | edward | ACProp async denominator on aux AdamW — v_t uses g_{t-1}² | Arm A CRASHED (diverged step 293); Arm B embed_only launching | Arm B: embed_only |
| #1752 | alphonse | Newton-Muon activation-Gram right-preconditioner on body PMuon | Running — Arm A `rh2iinb5` in flight | Arm A: diagonal Gram; Arm B pending |
| #1749 | thorfinn | AdEMAMix dual-EMA first moment on aux AdamW | Arm A NULL (sr=2975); Arm B `ctdbjhtv` running | Arm B: α=0.5/β₃=0.9995 |
| #1742 | tanjiro | Pre-target depth-asymmetric per-block LR burst ×1.5 | Arm A NULL (sr=2925); Arm B `p18t6opk` in flight | Arm B: late-higher burst |
| #1739 | fern | Pre-target NS_ITERS burst 12→{14, 18} @ step 2750 | Arm A NULL (sr=2925); Arm B `ossp58zg` in flight | Arm B: NS_ITERS=18 |

## Current research themes

**Aux Adam structural exploration (new this session):**
- Directive (a): Aux Adam m/v state reset at β₂ pulse boundary (nezuko #1770) — phase-boundary intervention at the #1532 WIN step, aux-side
- Directive (d): ACProp async denominator on aux AdamW (edward #1771) — Arm A catastrophically diverged; Arm B embed_only probing sparse-grad failure mode
- Directive (e): paramEMA β step-drop at pre-target (askeladd #1773) — direct EMA tracking improvement

**Body PMuon structural exploration (in-flight):**
- Directive (a): L_cov/R_cov reset at COOLDOWN ONSET step 975 (frieren #1780) — symmetric body-side counterpart to #1532 WIN; DISTINCT from pre-target reset (#1726 closed)
- Directive (b): Activation-Gram right-preconditioner (alphonse #1752) — per-matrix input curvature signal
- Directive (b): Depth-asymmetric per-block LR burst (tanjiro #1742) — per-block LR behavior
- Directive (c): NS_ITERS burst pre-target (fern #1739) — phase-specific iteration count
- Directive (e): AdEMAMix dual-EMA aux Adam (thorfinn #1749) — compound momentum on aux side

## Next hypotheses queue (post current wave)

1. **GrokFast slow-gradient amplification after NS whitening** — zero matches in 329-PR history; slow-EMA gradient amplification in whitened gradient space during cooldown; directive (c/d)
2. **L_cov/R_cov partial reset (early-blocks only) @ step 975** — if frieren #1780 Arm A shows signal, narrow scope to early blocks
3. **Aux Adam m/v state reset at step 2600** (paramEMA refresh boundary) — tests later phase boundary; directive (a)
4. **NS5 polynomial coefficient burst pre-target** — change polar accuracy character at 2750-2900 window; directive (c)
5. **Block-wise AdaShift** (scalar v_t per tensor) — orthogonal to per-element closure (#1709); directive (d)

## Key insights guiding research

- The canonical β₂ pulse at step 975 is a confirmed WIN (#1532); testing the symmetric body-side intervention (L_cov/R_cov reset at same step via frieren #1780) is the natural next move.
- Body Muon state at the PRE-TARGET boundary (step 2750) is consistently load-bearing — hard resets fail (#1726, #1730). This does NOT generalize to cooldown onset (step 975), where the regime is actively shifting.
- Aux Adam ACProp Arm A catastrophic divergence confirms sparse-gradient embed failure: stale denom at step t uses g_{t-1}² but active vocab tokens differ between steps. Arm B embed_only is the remaining signal.
- The sr=2875 wall is breakable (confirmed via 2 independent close-miss experiments). Val_ema in cooldown steps 3000-3250 is the bottleneck.
