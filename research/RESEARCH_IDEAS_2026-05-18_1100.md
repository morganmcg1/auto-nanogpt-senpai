# Research Ideas — 2026-05-18 11:00

**Baseline (PR #288 merged):** val/loss=3.275350, ffs_mean=3087.5, train_steps=3175
**Stack:** Muon NS5(iter=12) + Contra-Muon=0.5 + SOAP(FREQ=10, β2=0.90) + Attn-SOAP-trust T=0.85 + cooldown-only μ anneal 0.95→0.90 + cooldown_frac=0.7
**Gate:** n=2 screen; advance to n=4 confirm only if √2 × Δval ≥ 0.004. Must clear BOTH val < 3.275350 AND ffs_mean < 3087.5 (≥3/4 trials at ffs=3075).

---

## Idea A — AdaMuon: Post-NS5 Variance Scaling

**Mechanism:** After NS5 orthogonalization, maintain an EMA of squared orthogonalized updates V_t = β·V_{t-1} + (1-β)·O_t⊙O_t and scale the Muon update elementwise by 1/√(V_t+ε), with RMS rescaling γ_t = RMS(O_t) to preserve update scale. Optionally sign-stabilize the momentum buffer before NS5 (take sign(M_t) · |M_t| without changing the direction but reducing outlier magnitudes).

**Why it should beat baseline:** arxiv 2510.25000 ("What Really Matters for LLM Optimizer Performance") establishes that variance adaptation — not spectral accuracy — is the primary source of SOAP's per-step advantage over Muon. AdaMuon (arxiv 2507.11005) implements this as post-NS5 variance and closes ~0.014 val loss on FineWeb-scale GPT, achieving a 2.9% improvement over vanilla Muon. This is categorically distinct from PR #80 ("Muon²"), which applied Adam variance BEFORE Newton-Schulz and ran without improvement. Post-NS5 variance respects the orthogonalized basis; pre-NS5 variance does not.

**n=2 screen env-var flags:**
- Arm A: `ADAMUON_BETA2=0.95 ADAMUON_SIGN_STAB=0 ADAMUON_RMS_RESCALE=1`
- Arm B: `ADAMUON_BETA2=0.99 ADAMUON_SIGN_STAB=1 ADAMUON_RMS_RESCALE=1`

**Falsification criteria:** Declare falsified if both arms yield val_loss ≥ 3.275350 at best checkpoint, or if either arm produces NaN in loss within the first 200 steps (V_t initialization instability).

**Risk factors:** Medium. The RMS rescaling factor γ_t = 0.2·√(mn)/‖Ô_t‖_F in the paper requires careful tuning — wrong scale interacts badly with the existing Attn-SOAP-trust clipping. The sign-transform before NS5 may conflict with Contra-Muon's orthogonalized subtraction (Contra-Muon removes the component of G_t that lies in the span of O_{t-1}, so sign-flipping distorts this alignment). Test sign_stab=0 first (Arm A).

**Key references:** arxiv 2507.11005 (AdaMuon), arxiv 2510.25000 (What Really Matters for LLM Optimizer Performance).

---

## Idea B — MuonEq-R: Pre-NS5 Row Normalization

**Mechanism:** Before each NS5 call, normalize the momentum matrix rows by their Frobenius norms: M̂_t = D_r,t^{-1/2} · M̃_t where D_r,t = diag(rowsum(M̃_t ⊙ M̃_t) + ε), then proceed with standard NS5(iter=12). This is stateless — no EMA buffer, no new hyperparameters. After NS5, the existing NorMuon post-scaling still applies.

**Why it should beat baseline:** MuonEq-R (arxiv 2603.28254) validates on FineWeb GPT2-small, reducing perplexity from 25.23 to 24.88 — a significant gap. The mechanism improves the spectral conditioning entering NS5: row-unequal momentum matrices cause NS5 to converge to a biased pseudo-orthogonal matrix that over-rotates in high-norm directions. Pre-normalization ensures NS5 operates on a near-isotropic input, tightening the orthogonalization. This is fully orthogonal to NorMuon (PR #71 merged), which normalizes post-NS5 using Adafactor row/col variance — these two normalizations act at different positions in the pipeline and should stack.

**n=2 screen env-var flags:**
- Arm A: `MUONEQ_R=1 MUONEQ_EPS=1e-8`
- Arm B: `MUONEQ_R=1 MUONEQ_EPS=1e-6`

**Falsification criteria:** Declare falsified if both arms yield val_loss ≥ 3.275350, or if the mechanism is broken by interaction with Contra-Muon (val_loss > 3.285, significant regression).

**Risk factors:** Low. Stateless operation — no new buffers, no new learnable parameters. Main interaction risk: Contra-Muon orthogonalizes a component of the raw gradient before feeding to Muon, which already partially homogenizes row norms. If Contra-Muon inadvertently pre-conditions row norms, MuonEq-R may be redundant but should not regress. The ε value matters for near-zero momentum rows at initialization (first ~50 steps); use ε=1e-8 as the safe default.

**Key reference:** arxiv 2603.28254 (MuonEq).

---

## Idea C — Muon-VS: Pre-NS5 Gradient Deviation Variance

**Mechanism:** Maintain a buffer of gradient deviation variance Γ_t ← β·Γ_{t-1} + β(1-β)·(M_{t-1} − G_t)⊙² and scale the Muon momentum estimate before NS5 by M̃_t / √(Γ̂_t + ε), where Γ̂_t is bias-corrected. This suppresses momentum coordinates where recent gradients have been noisy relative to the historical average. β=0.95 is shared with Muon's momentum coefficient (zero independent hyperparameters).

**Why it should beat baseline:** arxiv 2601.14603 (Muon-VS) demonstrates a 1.36× optimizer step reduction on LLaMA-1.2B, which at our scale translates directly to ffs reduction. The mechanism is complementary to AdaMuon (Idea A): Muon-VS scales the input to NS5 by coordinate uncertainty, while AdaMuon scales the output of NS5 by output variance. Muon-VS specifically targets the instability of gradient direction in high-curvature coordinates — exactly the regime where our ffs bimodal distribution ({3075, 3100}) suggests per-step inconsistency.

**n=2 screen env-var flags:**
- Arm A: `MUON_VS=1 MUON_VS_BETA=0.95 MUON_VS_GAMMA=10`
- Arm B: `MUON_VS=1 MUON_VS_BETA=0.90 MUON_VS_GAMMA=10`

The γ=10 sensitivity peak for GPT-2 is reported in the paper for the NSR-gated variant; the VS variant uses γ only in the denominator ε stabilizer and is less sensitive.

**Falsification criteria:** Declare falsified if Γ_t produces NaN before step 300 (early-training noise spike), or if val_loss ≥ 3.275350 in both arms at best checkpoint.

**Risk factors:** Medium. The buffer (M_{t-1} − G_t)⊙² will be noisy in the first 100–200 steps when M_{t-1} is near initialization and gradients have not yet settled. Initialize Γ_0 = 1.0 (not zero) to avoid divide-by-near-zero in early steps. The interaction with Contra-Muon's pre-processed gradient is the main unknown: Contra-Muon removes the component of G_t aligned with previous updates, which may reduce the variance signal that Muon-VS relies on.

**Key reference:** arxiv 2601.14603 (Muon-VS and Muon-NSR).

---

## Idea D — Cooldown-Phase AdaMuon Switch

**Mechanism:** Apply AdaMuon's post-NS5 variance scaling ONLY during the cooldown phase (train_step ≥ cooldown_start), using a freshly-initialized variance buffer V_{cooldown,0} = RMS(O_{pre-cooldown})² · 1 at the phase boundary. This is an additive modification to the existing μ-anneal mechanism (PR #288) that already activates at the same boundary.

**Why it should beat baseline:** The cooldown-only μ-anneal (PR #288) established that cooldown-phase specialization is a load-bearing property of the current best stack. The μ-anneal reduces Muon's step magnitude as LR decays; post-NS5 variance scaling provides a coordinate-wise analogue of this shaping. These two mechanisms act on orthogonal aspects of the update (scalar momentum vs elementwise variance), so they should combine additively. Restricting variance scaling to the cooldown phase avoids disrupting the stable mid-training trajectory where the current stack works well.

**n=2 screen env-var flags:**
- Arm A: `ADAMUON_COOLDOWN_ONLY=1 ADAMUON_BETA2=0.95 ADAMUON_COOLDOWN_INIT=rms`
- Arm B: `ADAMUON_COOLDOWN_ONLY=1 ADAMUON_BETA2=0.99 ADAMUON_COOLDOWN_INIT=ones`

**Falsification criteria:** Declare falsified if both arms fail to beat val_loss < 3.275350, or if adding variance scaling during cooldown causes val_loss to regress > 3.278 vs the μ-anneal-only baseline (indicating destructive interference).

**Risk factors:** Low-medium. The buffer initialization at the phase boundary is the primary design choice: initializing from the RMS of recent orthogonalized updates (INIT=rms) provides a warm start that avoids an initial large variance spike; initializing at ones (INIT=ones) is conservative but may take 50–100 warmup steps inside the cooldown to reach steady state. Given cooldown_frac=0.7, cooldown runs ~2222 steps out of 3175 total — sufficient buffer warmup time for either initialization.

**Key references:** arxiv 2507.11005 (AdaMuon), arxiv 2510.25000 (What Really Matters), PR #288 (cooldown-only μ anneal, merged baseline).

---

## Priority Order

1. **Idea B (MuonEq-R)** — lowest risk, highest external validation fidelity (directly tested on FineWeb GPT2-small), stateless and zero new HPs. Run first.
2. **Idea D (Cooldown AdaMuon)** — targets cooldown phase where current stack already has demonstrated sensitivity; limited interaction surface.
3. **Idea A (Full AdaMuon)** — highest expected gain but medium implementation risk; run after B to have a reference for interaction effects.
4. **Idea C (Muon-VS)** — most speculative interaction with Contra-Muon; run last or in parallel with A if capacity allows.

## Do Not Repeat

The following are falsified and must not be re-proposed: Muon LR warmup, Polyak-Ruppert EMA, AdamW β1 anneal, AdamW eps shift, SOAP_PRECOND_FREQ ≠ 10, NS5 iter ≠ 12, SOAP β2-anneal, per-head SOAP block diag, MLP-SOAP trust gate, depth-LR scaling, decoupled SOAP freq per group, lm_head WD, embed init std=0.5, cosine cooldown on Muon/aux, lookahead, NorMuon β2 cooldown anneal, Polar Express adaptive NS5, asymmetric QK/VO trust, Adam variance BEFORE NS5 (PR #80).
