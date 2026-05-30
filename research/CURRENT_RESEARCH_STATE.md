# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-30 21:30 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
- **🔥 STRONGEST HOT WIN CANDIDATE:** nezuko #1815 BILATERAL TERMINAL — Arm A (aux Adam m-only ZERO RESET @ step 975) `nvh1vd60` seed-1: sr=2875, val_ema=**3.262238 (-0.616 mnat below gate)**. Arm B (v×0.5) `366knnhc` NULL sr=2925, val_ema=3.265652. **BILATERAL COMPLETE — seed-2 of Arm A requested at 19:55 UTC.** Mechanistic read: first-moment direction memory is dispensable at cooldown boundary (m-zero benign: 0 mnat transient); v state is load-bearing (v×0.5 still degrades: +16.5 mnat transient). Awaiting nezuko's seed-2 launch and terminal.
- **frieren #1780 CLOSED (16:15 UTC):** cov-reset@1100 Arm B seed-1 thin-pass nullified on n=2 — seed-2 sr=2925, val_ema=3.264785 FAIL. Cov-state full-reset axis fully CLOSED (975/1100/2750). Per-side asymmetric (thorfinn #1849) and frieren #1850 (scalar_lr pulse) now in flight.
- **fern #1831 CLOSED (21:15 UTC):** Body PMuon γ pulse at cooldown onset bilateral NULL — Arm A (γ→0.3 RELAX) sr=2925 val_ema=3.267064 (+4.2 mnat), Arm B (γ→0.5 SHARPEN) sr=2925 val_ema=3.266283 (+3.4 mnat). Both directions miss gate; γ axis CLOSED across cooldown onset AND pre-target (#1680). fern reassigned: body PMuon momentum HARD-ZERO @ cooldown onset (#1876).
- **edward #1830 CLOSED (21:15 UTC):** Aux Adam m+v full zero reset at LATE phase boundaries bilateral NULL — Arm A (reset@2600 pEMA boundary) sr=2925 val_ema=3.265206 (+2.4 mnat), Arm B (reset@2750 pre-target) sr=2925 val_ema=3.265872 (+3.0 mnat). Aux Adam full-zero reset CLOSED across ALL temporal boundaries (975/2600/2750). edward reassigned: body PMuon LR persistent step-down at cooldown onset (#1877).
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
- **Newton-Muon activation-Gram right-preconditioner on body PMuon (#1752 alphonse)** — Arm A diag NULL +6.6 mnat (uniform drag from warmup), Arm B full skipped; PMuon bilateral whitening is structurally sufficient for input + output curvature
- **AdEMAMix dual-EMA first moment on aux AdamW (#1749 thorfinn)** — Arm A sr=2975 +6.6 mnat, Arm B sr=3000 +8.2 mnat; bigger slow component HURTS more; aux Adam first-moment structural modification CLOSED (also: Lookahead, per-element AdaShift #1709, ACProp #1771, SOAP all closed)
- **Aux Adam m+v hard zero reset at β₂-pulse boundary (#1770 nezuko)** — Arm A sr=2975 +7.09 mnat (reset @ 975, +62.9 mnat v-denominator transient at step 1000); Arm B sr=2925 +3.56 mnat (reset @ 1200, +1.7 mnat transient after 225 steps β₂=0.99 pre-fill); v state is load-bearing — full-zero CLOSED; asymmetric partial primitives (m-only reset, v partial decay) assigned to nezuko #1815
- **Body PMuon L_cov/R_cov bilateral ZERO RESET at cooldown boundary (#1780 frieren)** — Arm A (reset@975) sr=2925 val_ema=3.264834 NULL; Arm B seed-1 (reset@1100) sr=2875 val_ema=3.262685 thin-margin PASS clause 2 (−0.169 mnat) — but seed-2 cknk2m33 returned sr=2925 val_ema=3.264785 FAIL; n=2 mean sr=2900, val_ema=3.263735 NULL; single-seed pass was run-to-run noise; cov-state full-reset CLOSED across cooldown onset (975/1100) AND pre-target (#1726 @ 2750); asymmetric per-side primitive (L-only / R-only) in flight as thorfinn #1849
- **paramEMA β hard step-drop at pre-target (#1773 askeladd)** — Arm A sr=2950 +2.30 mnat NULL; Arm B sr=2925 val_ema=3.262675 (-0.18 mnat BELOW gate clause 2 but sr fails clause 1); β-drop fired correctly + collapsed val_ema/val_live gap (+0.59→+0.02 mnat) but didn't change val_live trajectory; pEMA β-drop CLOSED — target crossing speed is a TRAINING trajectory effect, not EMA smoothing artifact
- **Per-block depth-asymmetric μ on body PMuon (#1788 alphonse)** — Arm A ascending sr=-1 val_ema=3.428 (+165 mnat NULL), Arm B descending diverged at step ~850; combined with #1742 per-block LR closure, block-depth asymmetric optimizer axes on body PMuon FULLY EXHAUSTED
- **Aux Adam eps transient pulse at β₂ boundary (#1787 tanjiro)** — Arm A eps=1e-6 sr=2875 ~NULL, Arm B eps=1e-4 sr=2925 worse; v_t transient at step 975 is NOT a numerical stability problem — CLOSED
- **Body PMuon momentum buffer partial SCALE at cooldown onset step 975 (#1797 thorfinn)** — Arm A ×0.5 sr=2925 NULL, Arm B ×0.25 sr=2925 NULL; INVARIANT to attenuation magnitude — ×0.5 and ×0.25 produce identical outcome; momentum-scale at step 975 CLOSED; combined with hard-zero CLOSED (#1730), momentum-state axis fully exhausted across all reset types and temporal boundaries
- **Aux Adam β₁ JOINT pulse synchronous with β₂ pulse at step 975 (#1819 askeladd)** — Arm A (β₁→0.9) sr=2925, val_ema=3.266499 (+3.645 mnat NULL); Arm B (β₁→0.95) sr=2950, val_ema=3.267480 (+4.626 mnat, WORSE than Arm A — more momentum ⇒ worse); β₁ axis FULLY EXHAUSTED across (a) standalone raise #1592, (b) standalone drop #1639, AND (c) joint synchronization with β₂ #1819
- **Body PMuon γ pulse at cooldown onset step 975 (#1831 fern)** — Arm A (γ→0.3 RELAX) sr=2925 val_ema=3.267064 (+4.2 mnat), Arm B (γ→0.5 SHARPEN) sr=2925 val_ema=3.266283 (+3.4 mnat); both directions miss gate identically; γ axis CLOSED across cooldown onset AND pre-target (#1680); whitening exponent well-calibrated at γ=0.4 across all training phases
- **Aux Adam m+v FULL ZERO reset at late phase boundaries (#1830 edward)** — Arm A (reset@2600 pEMA boundary) sr=2925 val_ema=3.265206 (+2.4 mnat), Arm B (reset@2750 pre-target) sr=2925 val_ema=3.265872 (+3.0 mnat); Arm B marginally more disruptive (smaller late-phase v denominator → larger relative reset impact); aux Adam full-zero reset CLOSED across ALL temporal boundaries (975 via #1770, 2600 via Arm A, 2750 via Arm B)

**Structural decoupling (BILATERAL NULL):**
- Depth-stratified β_cov binary split (#1727 edward) — falsifying Arm B beat mechanistic Arm A; axis FULLY CLOSED across binary split + continuous ramp (#1339)
- Stacked pEMA refresh @ 2750/2850 (#1704 thorfinn) — bilateral NULL; canonical 2600 is singular optimum

**β₂ pulse mechanism:** amplitude, timing, shape, per-group recipient, pre-target re-spike — ALL NULL except canonical 0.95→0.99 @ 975 (#1532 WIN)

**Optimizer replacements:** Lookahead, AdaShift per-element, SOAP, AdEMAMix — all closed

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
| **#1815** | **nezuko** | **Aux Adam m-only ZERO RESET @ step 975 — 🔥 HOT WIN seed-2 in progress** | **Seed-2 requested 19:55 UTC** | **Arm A: m-only reset (WIN candidate); Arm B: v×0.5 (NULL)** |
| **#1877** | **edward** | **Body PMuon LR persistent step-down at cooldown onset step 975 (×0.85 vs ×0.70)** | **Assigned 21:30 UTC** | **Arm A: muon_lr ×0.85 @975; Arm B: muon_lr ×0.70 @975** |
| **#1876** | **fern** | **Body PMuon momentum HARD-ZERO reset at cooldown onset (975 vs 1100)** | **Assigned 21:30 UTC** | **Arm A: momentum zero @975; Arm B: momentum zero @1100** |
| #1836 | alphonse | Body PMuon momentum buffer SCALE at pre-target boundary step 2750 (×0.5 vs ×0.25) | Assigned 14:00 UTC | Arm A: ×0.5 @ 2750; Arm B: ×0.25 @ 2750 |
| #1837 | tanjiro | Aux Adam β₂ pulse per-group: embed-only vs lm_head-only localization | Assigned 14:00 UTC | Arm A: embed-only β₂→0.99; Arm B: lm_head-only β₂→0.99 |
| #1849 | thorfinn | Body PMuon per-side L_cov vs R_cov asymmetric ZERO RESET @ step 1100 | Assigned 16:10 UTC — 0 comments (4h), ping sent | Arm A: L-only reset; Arm B: R-only reset |
| #1850 | frieren | Aux Adam scalar_lr PULSE @ cooldown onset step 975 (RMSNorm per-group LR perturbation) | Arm A `t14ojkgw` running at step ~1907/3250, Arm B pending | Arm A: scalar_lr ×2 (→0.050); Arm B: scalar_lr ×0.5 (→0.0125) |
| **#1868** | **askeladd** | **Aux Adam embed_lr PULSE @ cooldown onset step 975 (per-group LR perturbation on adam_embed)** | **Assigned 20:00 UTC** | **Arm A: embed_lr ×2 (0.3→0.6); Arm B: embed_lr ×0.5 (0.3→0.15)** |

## Current research themes

**Aux Adam structural exploration (this session):**
- Directive (a): Aux Adam m-only ZERO RESET @975 (nezuko #1815 Arm A nvh1vd60) — **STRONG WIN on seed-1 (−0.616 mnat below gate)**; seed-2 requested. Bilateral confirms: m-zero benign (0 mnat transient), v×0.5 degrades (+16.5 mnat transient) — first-moment direction memory dispensable, v state load-bearing.
- Directive (a): Aux Adam β₁ JOINT pulse CLOSED (#1819 askeladd bilateral NULL; combined with #1592/#1639 closes β₁ axis fully)
- Directive (b/d): Aux Adam β₂ pulse PER-GROUP localization (tanjiro #1837) — embed-only vs lm_head-only; localizes the #1532 WIN mechanism to specific param group
- Directive (a): Aux Adam m+v full reset at LATE phase boundaries (edward #1830) — step 2600 (pEMA refresh) vs step 2750 (pre-target), avoids step-975 v-collapse failure mode
- Directive (a/b): Aux Adam scalar_lr PULSE @ cooldown onset step 975 (frieren #1850) — per-group LR perturbation on untested RMSNorm scalar group; Arm A `t14ojkgw` ×2 running, Arm B pending
- Directive (a/b): Aux Adam embed_lr PULSE @ cooldown onset step 975 (askeladd #1868) — NEW: per-group LR perturbation on `adam_embed` (vocab×hidden, lr=0.3), largest aux group; Arm A ×2 (→0.6) / Arm B ×0.5 (→0.15); companion to frieren #1850; covers 2-of-3 aux groups for per-group LR sensitivity at cooldown
- Block-wise AdaShift on aux Adam CLOSED (#1785 bilateral NULL); per-element AdaShift also closed (#1709)
- GrokFast on whitened body PMuon CLOSED (#1786 bilateral NULL — mechanism falsified: NS5 polar normalization invariant is broken by additive slow-EMA)

**Body PMuon structural exploration (in-flight):**
- Directive (a/c): Body PMuon γ pulse at cooldown onset step 975 (fern #1831) — symmetric body-side analog of #1532 aux β₂ WIN; relax (γ→0.3) vs sharpen (γ→0.5)
- Directive (a/b/d): Body PMuon per-side L_cov vs R_cov asymmetric ZERO RESET @ step 1100 (thorfinn #1849) — NEW: transfers nezuko #1815's asymmetric-primitive paradigm (m-only vs v-only on aux Adam) to body PMuon covariance preconditioners; Arm A L-only / Arm B R-only (predicted: R-only carries signal — gradient magnitudes shift more than activations under cooldown LR decay)
- Directive (a/c/d): Body PMuon momentum buffer SCALE at PRE-TARGET boundary step 2750 (alphonse #1836) — NEW: momentum scaling at 2750 boundary; Arm A ×0.5 / Arm B ×0.25

## Next hypotheses queue (post current wave)

1. **Aux Adam m-only reset at step 2600** — if nezuko #1815 Arm A (m-only @975) is benign, test at pEMA refresh boundary too
2. **Aux Adam v partial decay factor sweep (×0.25, ×0.75)** — if nezuko #1815 Arm B (v×0.5 @975) shows signal, sweep decay magnitude
3. **L_cov/R_cov partial reset (early-blocks only) @ step 975** — if frieren #1780 Arm B shows signal, narrow scope to early blocks
4. **GrokFast cross-application to aux AdamW** — if fern #1786 Arm B shows promise, extend slow-EMA amplification to aux Adam updates
5. **Aux Adam eps pulse wider window (975-1200)** — if tanjiro #1787 shows signal but limited window, test wider v_t refill window
6. **Body PMuon momentum scaling with depth-asymmetric factor** — if thorfinn #1797 shows scaling works, factor per-block (late blocks higher scale to compensate high-LR velocity overcalibration)
7. **Aux Adam m/v state reset at step 2600** (pEMA refresh boundary) — second phase boundary test; directive (a)

## Key insights guiding research

- The canonical β₂ pulse at step 975 is a confirmed WIN (#1532); testing the symmetric body-side intervention (L_cov/R_cov reset at same step via frieren #1780) is the natural next move.
- Body Muon state at the PRE-TARGET boundary (step 2750) is consistently load-bearing — hard resets fail (#1726, #1730). This does NOT generalize to cooldown onset (step 975), where the regime is actively shifting.
- Aux Adam first-moment structural modifications (Lookahead, per-element AdaShift, ACProp, AdEMAMix) are ALL CLOSED. The remaining open axis is the denominator side (eps pulse #1787, block-wise v_t #1785).
- The sr=2875 wall is breakable (confirmed via 2 independent close-miss experiments). Val_ema in cooldown steps 3000-3250 is the bottleneck. Fern #1739 polar-accuracy closure further isolates this: the remaining headroom is in update **magnitude/persistence**, not direction quality — motivating GrokFast slow-EMA amplification in the whitened-gradient space (#1786) and body PMuon momentum scaling (#1797).
- **Per-block LR perturbation is FULLY CLOSED** (#1742 + prior uniform closures). Research focus pivots to aux Adam denominator mechanics (#1785, #1787), body PMuon covariance state (#1780), body PMuon momentum state (#1797), and depth-asymmetric gradient memory (#1788, #1786).
