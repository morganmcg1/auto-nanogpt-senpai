# Research Ideas — 2026-05-25 05:40

## H1 (alphonse): GALORE_MUON_PREGRAD

**PR title:** `GALORE_MUON_PREGRAD: low-rank SVD gradient projection on body Muon before NS5 orthogonalization`

**Mechanism class:** PRE-NS5-LOW-RANK-PROJECTION (54th mechanism class — categorically new)

**Hypothesis:** GaLore (Zhao et al. 2024, arXiv:2403.03507) demonstrates that LLM gradient matrices exhibit stable low-rank structure throughout training — the top-r singular directions capture the dominant learning signal while the tail is noise. Before NS5 processes each body 2D gradient, project it onto its top-r singular subspace via truncated SVD. NS5 then orthogonalizes within the rank-r subspace rather than the full-rank noisy gradient. If the gradient's low-rank structure is the informationally load-bearing component, this projection either preserves or improves NS5's update quality. If the full-rank gradient is necessary, this will show as a degraded floor.

**Why categorically distinct:**
- NOT pre-NS5-nonlinear (closed): nonlinear activation before NS5; GaLore SVD projection is LINEAR and rank-reducing
- NOT pre-NS5-linear-Frobenius (closed): Frobenius-norm SCALING leaves matrix shape intact; SVD RANK TRUNCATION changes the effective rank — these are orthogonal operations
- NOT SOAP/Shampoo (#534, #797, #804, #837, #842, #879, #894): those are POST-NS5 full-rank preconditioners, not PRE-NS5 rank-reduction
- NOT NS5-iter/schedule interventions (#811, #877, #948): those modify the NS5 algorithm itself, not the gradient INPUT to NS5
- NOT AdaMuon/NorMuon (#71, #828, #906, #910, #939): those scale/normalize the NS5 OUTPUT
- NOT GradSkip/sparsification: SVD projection is dense reconstruction at lower rank, not masking

**Arms:**
- Disabled-check: `GALORE_RANK = 0` (bypass branch, must reproduce ~4.08 at step 200)
- Arm A: `GALORE_RANK = 4`
- Arm B: `GALORE_RANK = 8`

**Code sketch (~10 LOC, insert before muon_step NS5 call):**
```python
GALORE_RANK = 4  # arm A: 4  |  arm B: 8  |  disabled: 0

def galore_project(grad, rank):
    """Project 2D gradient onto top-r singular subspace."""
    U, S, Vt = torch.linalg.svd(grad, full_matrices=False)
    return U[:, :rank] @ torch.diag(S[:rank]) @ Vt[:rank, :]

if GALORE_RANK > 0:
    for p in muon_params:
        if p.grad is not None and p.grad.dim() == 2 and min(p.grad.shape) >= GALORE_RANK:
            p.grad.data.copy_(galore_project(p.grad, GALORE_RANK))
# NS5 proceeds on rank-limited gradient as normal
```

**Expected compute overhead:** SVD of each 2D body gradient per step. Body weights are ~[d_model, d_model] = [1024, 1024] or [d_ff, d_model]. torch.linalg.svd with full_matrices=False is well-optimized on CUDA; overhead is <5% wall clock for rank<<min(dim).

**Expected refute signature:**
- `floor-cluster-touch` monotone-in-rank (rank=8 closer to baseline than rank=4) if low-rank projection preserves enough signal but cannot exceed NS5's current quality
- `degraded` / clear miss if rank=4 destroys too much gradient signal to recover
- `improvement` if gradient noise is genuinely load-bearing bottleneck for NS5

**Both outcomes scientifically valuable:** floor-cluster-touch closes PRE-NS5-LOW-RANK-PROJECTION family (1/1 rank-truncation inert); improvement opens a new frontier.

**Citations:**
- Zhao et al. 2024. GaLore: Memory-Efficient LLM Training by Gradient Low-Rank Projection. arXiv:2403.03507
- Modded-nanogpt NS5 orthogonalization baseline (PR #613)

---

## H2 (nezuko): ADAM_MINI_AUX

**PR title:** `ADAM_MINI_AUX: partitioned second-moment (Adam-mini) on embed/lm_head AUX optimizer groups`

**Mechanism class:** AUX-SECOND-MOMENT-PARTITION (55th mechanism class — categorically new)

**Hypothesis:** Adam-mini (Zhang et al. 2024, arXiv:2406.16793) shows that per-element second moment v in AdamW is redundant — within each parameter block, v values are highly correlated, so one v per block suffices. The AUX optimizer (adam_embed, adam_lm_head) currently uses per-element v over large vocab-dimension matrices (vocab × d_model). Replace per-element v with a partitioned v that computes one estimate per d_model column (for embed) or per d_model row (for lm_head), broadcast back to full shape before the AdamW denominator step. The AUX second-moment STRUCTURE has never been modified across 295 PRs — only LR, WD, beta, and schedule have been swept.

**Why categorically distinct:**
- NOT AUX-AMSGrad (closed): AMSGrad uses running max of per-element v — monotone non-increasing effective LR; Adam-mini partitions v structure, does NOT change monotonicity
- NOT AUX-LR-schedule (closed): schedule modifies the scalar LR multiplier; Adam-mini changes the DENOMINATOR STRUCTURE
- NOT AdamW beta/epsilon sweeps: those change hyperparameters of per-element v, not the structural granularity of v
- NOT SOAP/Shampoo (#534, #797, #804, etc.): those apply to body Muon params; AUX optimizer groups (embed, lm_head) are untouched by all of those
- NOT any body-Muon intervention: embed and lm_head are AUX-only params
- AUX second-moment partition — structural modification of v shape — has ZERO prior art in 295 PRs

**Arms:**
- Disabled-check: `EMBED_MINI_MODE = "disabled"` (standard per-element v, must reproduce ~4.08 at step 200)
- Arm A: `EMBED_MINI_MODE = "col"` — partition by d_model column, v shape [1, d_model] broadcast to [vocab, d_model] for embed; analogously [d_model, 1] broadcast to [d_model, vocab] for lm_head
- Arm B: `EMBED_MINI_MODE = "scalar"` — one v per entire embed/lm_head matrix (extreme compression); v shape [1, 1]

**Code sketch (~12 LOC, modify AUX AdamW step):**
```python
EMBED_MINI_MODE = "col"  # arm A: "col"  |  arm B: "scalar"  |  disabled: "disabled"

def get_partitioned_v(grad, mode):
    """Return partitioned second moment, broadcast to grad shape."""
    if mode == "col":
        # average over vocab (dim 0), keep d_model structure (dim 1)
        return grad.pow(2).mean(dim=0, keepdim=True).expand_as(grad)
    elif mode == "scalar":
        return grad.pow(2).mean(keepdim=True).expand_as(grad)
    else:
        return grad.pow(2)  # standard per-element, disabled baseline

# In the AUX AdamW step for embed_params and lm_head_params:
for p in aux_params:  # embed + lm_head
    if p.grad is not None:
        v_mini = get_partitioned_v(p.grad, EMBED_MINI_MODE)
        # use v_mini in AdamW denominator: p.data -= lr * p.grad / (v_mini.sqrt() + eps)
```

**Expected compute overhead:** negligible — mean reduction over vocab dim is cheap; no SVD or extra state buffers.

**Expected refute signature:**
- `floor-cluster-touch` if partition granularity is too coarse but tolerable
- `shifted-floor` if partition over-smooths embed second moment, raising the floor by 0.01-0.02
- `improvement` if per-element v in embed/lm_head was wasteful/overfit and partitioned v provides better regularization

**Both outcomes scientifically valuable:** any result directly characterizes AUX second-moment structure sensitivity, closing AUX-SECOND-MOMENT-PARTITION family (1/1 or opening further partition granularity axis).

**Citations:**
- Zhang et al. 2024. Adam-mini: Use Fewer Learning Rates To Gain More. arXiv:2406.16793
- Modded-nanogpt AUX optimizer baseline, mandatory stack (PR #613)

---

## Verified Novel Check

**H1 GALORE_MUON_PREGRAD:**
- Banned list cross-check: no entry matches "pre-NS5 low-rank SVD truncation of body gradient INPUT"
- Closest prior PRs: #811/#877/#948 (NS5 algorithm modifications — distinct), #1086/#1101 (pre-NS5 Frobenius scaling — distinct, closed), #534/#797/#804 (post-NS5 full-rank preconditioners — distinct)
- GaLore paper (arXiv:2403.03507) NOT cited in any prior PR per the PR corpus
- **NOVEL: PRE-NS5-LOW-RANK-PROJECTION — 54th mechanism class ✓**

**H2 ADAM_MINI_AUX:**
- Banned list cross-check: no entry matches "AUX optimizer second-moment structural partition"
- Closest prior PRs: #1108 (AUX-AMSGrad — monotone non-increasing v, NOT partition structure), all AUX-LR sweeps (scalar LR, NOT v structure), all SOAP/Shampoo (body Muon only, NOT AUX groups)
- Adam-mini paper (arXiv:2406.16793) NOT cited in any prior PR per the PR corpus
- AUX second-moment STRUCTURE unmodified across all 295 PRs
- **NOVEL: AUX-SECOND-MOMENT-PARTITION — 55th mechanism class ✓**
