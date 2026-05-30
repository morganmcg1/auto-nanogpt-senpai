# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-30 05:50 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
- **Human directive #1252:** Prioritize (a) optimizer-state resets at phase boundaries, (b) per-layer/per-block optimizer behavior, (c) short phase-specific mechanisms, (d) momentum/preconditioner state handling, (e) schedules that steepen loss descent before step 2925. Avoid pure scalar β/μ/EMA sweeps.

## 🚧 PLATEAU PROTOCOL ENGAGED — all body Muon scalar axes exhausted; now on Tier-2 structural mechanisms + aux Adam exploration

### Definitively closed axes

**Body Muon pre-target scalar pulses (ALL BILATERAL NULL):**
- LR-UP (#1637), LR-DOWN (#1697), γ (#1680), μ (#1686 — all temporal regimes), NS-coefs (#1660), β₁ (#1592/#1639), β_cov (@975 + @2600 via #1666), weight_decay (#1693), Nesterov, schedule-free, **NS_ITERS burst (#1739)**, **per-block depth-asymmetric LR burst (#1742)**

**Structural state interventions (BILATERAL NULL):**
- L_cov/R_cov hard zero RESET at pre-target step 2750 (#1726 nezuko) — Arm A sr=2950 NULL, Arm B sr=2875 close miss +1.07 mnat; cov-state replacement CLOSED at pre-target
- Body Muon momentum buffer hard ZERO RESET at step 2750 (#1730 askeladd) — Arm A CRASHED, Arm B sr=2925 +3.70 mnat NULL; momentum state-discard CLOSED at pre-target boundary
- ADOPT-style async whitening (#1703 alphonse) — Arm A sr=2975, Arm B sr=2950; update-rule asynchrony CLOSED on body PMuon
- **ACProp async denominator on aux AdamW (#1771 edward)** — Arm A diverged @ step 250, Arm B embed_only early-killed @ step 1575 val=3.705; aux-Adam async-denom CLOSED across all-groups + embed_only scopes
- **Newton-Muon activation-Gram right-preconditioner on body PMuon (#1752 alphonse)** — Arm A diag NULL +6.6 mnat (uniform drag from warmup), Arm B full skipped (student-recommended; same double-correction geometry); confirms PMuon bilateral whitening is structurally sufficient for input + output curvature

**Structural decoupling (BILATERAL NULL):**
- Depth-stratified β_cov binary split (#1727 edward) — falsifying Arm B beat mechanistic Arm A; axis FULLY CLOSED across binary split + continuous ramp (#1339)
- Stacked pEMA refresh @ 2750/2850 (#1704 thorfinn) — bilateral NULL; canonical 2600 is singular optimum

**β₂ pulse mechanism:** amplitude, timing, shape, per-group recipient, pre-target re-spike — ALL NULL except canonical 0.95→0.99 @ 975 (#1532 WIN)

**Optimizer replacements:** Lookahead, AdaShift per-element, SOAP — all closed

**TARGET_UW floor pulse family (FULLY CLOSED):**
- #1708 frieren (short-window 0.45/0.55 @ 2750-2900, n=2 bilateral seed confirmation) — NULL. Five experiments across magnitude × timing × window.

**Polar projection accuracy axis (CLOSED):**
- NS_ITERS burst 12→{14, 16} pre-target (#1739 fern) — polar residual fell 3-5× during burst but neither arm crossed target; polar projection accuracy is NOT the cooldown bottleneck. **Cooldown headroom is in update MAGNITUDE / persistence, not direction quality.**

### 🔥 Cross-PR sr=2875 close-miss signal

Two independent mechanisms hit baseline sr (bilateral nulls, but sr=2925→2875 wall IS breakable):
- frieren #1708 Arm B (UW=0.55) seed-1: sr=2875, val_ema 3.263116 (+0.262 mnat above gate) → seed-2 failed to confirm
- nezuko #1726 Arm B (cov-reset + β_cov pulse): sr=2875, val_ema 3.263927 (+1.07 mnat above gate)

**Signal:** val_ema in the final 250 steps (steps 3000–3250) is the tightening bottleneck. The fern #1739 NS-burst closure confirms this bottleneck is **magnitude/persistence**, not polar accuracy.

## Active assignments (all 8 students engaged on r1)

| PR | Student | Experiment | Status | Arms |
|---|---|---|---|---|
| **#1786** | **fern** | **GrokFast slow-EMA gradient amplification on whitened body PMuon during cooldown (α=0.5 / α=2.0)** | **Just assigned 05:10 UTC** | **Arm A: α=0.5; Arm B: α=2.0** |
| **#1785** | **edward** | **Block-wise AdaShift on aux AdamW embed (scalar v_t per tensor, delay=1 / delay=10)** | **Just assigned 05:10 UTC** | **Arm A: delay=1; Arm B: delay=10** |
| #1780 | frieren | Body PMuon L_cov/R_cov hard zero reset at cooldown onset (step 975 vs 1100) | Running | Arm A: reset@975; Arm B: reset@1100 |
| #1773 | askeladd | paramEMA β hard step-drop at step 2750 (0.99→0.90 / 0.99→0.95) | Running | Arm A: 0.90; Arm B: 0.95 |
| #1770 | nezuko | Aux Adam m/v hard zero reset at β₂-pulse boundary (step 975 / step 1200) | Running — Arm A `mhzwt7ge` in flight | Arm A: @975; Arm B pending |
| **#1788** | **alphonse** | **Per-block depth-asymmetric μ on body PMuon (ascending vs descending linear ramp 0.90↔0.99)** | **Just assigned 05:50 UTC** | **Arm A: μ ascending; Arm B: μ descending** |
| #1749 | thorfinn | AdEMAMix dual-EMA first moment on aux AdamW | Arm A NULL (sr=2975); Arm B `ctdbjhtv` running | Arm B: α=0.5/β₃=0.9995 |
| **#1787** | **tanjiro** | **Aux Adam eps transient pulse co-located with β₂ pulse boundary (eps 1e-10→1e-6/1e-4, steps 975-1100)** | **Just assigned 05:30 UTC** | **Arm A: eps=1e-6; Arm B: eps=1e-4** |

## Current research themes

**Aux Adam structural exploration (this session):**
- Directive (a): Aux Adam m/v state reset at β₂ pulse boundary (nezuko #1770) — phase-boundary intervention at the #1532 WIN step, aux-side
- Directive (d): **Block-wise AdaShift on aux AdamW embed group (edward #1785)** — scalar v_t per tensor sidesteps the sparse-grad failure mode that closed per-element AdaShift (#1709) and ACProp (#1771)
- Directive (e): paramEMA β step-drop at pre-target (askeladd #1773) — direct EMA tracking improvement

**Body PMuon structural exploration (in-flight):**
- Directive (a): L_cov/R_cov reset at COOLDOWN ONSET step 975 (frieren #1780) — symmetric body-side counterpart to #1532 WIN; DISTINCT from pre-target reset (#1726 closed)
- Directive (b): Activation-Gram right-preconditioner (alphonse #1752) — per-matrix input curvature signal
- Directive (b): Depth-asymmetric per-block LR burst (tanjiro #1742) — per-block LR behavior
- Directive (c/d): **GrokFast slow-EMA amplification on whitened body PMuon during cooldown (fern #1786)** — zero matches in 329-PR history; targets the magnitude/persistence axis that #1739 isolated as the remaining cooldown bottleneck
- Directive (e): AdEMAMix dual-EMA aux Adam (thorfinn #1749) — compound momentum on aux side
- Directive (a/c/d): **Aux Adam eps transient pulse at β₂ pulse boundary (tanjiro #1787)** — denominator stability floor during v_t re-accumulation transient post-β₂-pulse; compounds #1532 WIN via novel eps axis

## Next hypotheses queue (post current wave)

1. **L_cov/R_cov partial reset (early-blocks only) @ step 975** — if frieren #1780 Arm A shows signal, narrow scope to early blocks
2. **Aux Adam m/v state reset at step 2600** (paramEMA refresh boundary) — tests second phase boundary on aux side; directive (a)
3. **GrokFast cross-application to aux AdamW** — if fern #1786 Arm A shows promise, extend slow-EMA amplification to aux Adam updates
4. **Per-block GrokFast amplification (depth-asymmetric α)** — if fern #1786 ARM B suggests amplification regime works but is too aggressive uniformly
5. **Aux Adam eps pulse wider window (975-1200)** — if tanjiro #1787 shows signal but limited, test wider v_t refill window coverage

## Key insights guiding research

- The canonical β₂ pulse at step 975 is a confirmed WIN (#1532); testing the symmetric body-side intervention (L_cov/R_cov reset at same step via frieren #1780) is the natural next move.
- Body Muon state at the PRE-TARGET boundary (step 2750) is consistently load-bearing — hard resets fail (#1726, #1730). This does NOT generalize to cooldown onset (step 975), where the regime is actively shifting.
- Aux Adam ACProp confirmed sparse-gradient embed failure: stale denom uses g_{t-1}² but active vocab tokens differ between steps. Closure (#1771) motivates **scalar aggregation** path via block-wise AdaShift (#1785).
- The sr=2875 wall is breakable (confirmed via 2 independent close-miss experiments). Val_ema in cooldown steps 3000-3250 is the bottleneck. Fern #1739 polar-accuracy closure further isolates this: the remaining headroom is in update **magnitude/persistence**, not direction quality — motivating GrokFast slow-EMA amplification in the whitened-gradient space (#1786).
- **Per-block LR perturbation is FULLY CLOSED** (#1742 depth-asymmetric bilateral NULL + prior uniform closures). The canonical late-higher pattern (#1289) is the singular optimum for depth-asymmetric LR; any temporary perturbation breaks it. Research focus pivots to aux Adam denominator mechanics (#1787) and body PMuon state handling (#1780, #1786).
