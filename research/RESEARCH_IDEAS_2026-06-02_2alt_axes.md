# SENPAI R3 Research Ideas — 2026-06-02 — 2 Alt Axes (H390, H391)

Generated at cycle ~2700. Both hypotheses verified novel against EXPERIMENTS_LOG.md.
Banned sources: no primeintellect.ai, no upstream Auto-NanoGPT PRs/branches.

---

## H390 — MEMORY: Per-Matrix Spectral Gram-Diagonal EMA for NorMuon Body Updates

### What it is

After `polar_express` produces a v_chunk with all singular values ≈ 1, different singular
directions can still have systematically different *magnitudes across training steps* — some
directions are more active in early training, others in cooldown. The current rank-1
`second_momentum_buffer` can only see row-mean or col-mean variance; it is blind to which
spectral directions are over- or under-represented. This hypothesis adds a rank-n EMA over
diag(V.T @ V) — the per-singular-direction squared magnitudes — and uses it to equalize
spectral activity, analogous to Adafactor's row/col factored variance but operating in the
spectral basis of the *already-orthogonalized* update.

### Why it might help

- **H238 closed** per-element post-NS5 scaling (bilateral TIE at any β₂ ∈ [0.99, 0.999]).
  The null result at element-level is expected: after polar decomp, element-wise variance
  carries no directional signal. Spectral variance does, because singular directions capture
  coordinated motion of multiple elements.
- **Line 7847 of EXPERIMENTS_LOG.md** explicitly deferred "spectral second-moment variant
  (per-singular-value, not per-element)" — it was flagged as mechanistically coherent but
  never assigned across ~2700 cycles.
- **Line 7586**: student follow-up after H205 closure explicitly suggests "pivot to post-polar
  transforms (e.g., spectral-aware LR scaling)" — never assigned.
- **Line 7760** programme finding: "Body-side mechanism headroom must be spectral-aware
  (manipulating NS5 itself or operating in polar basis), not per-element."
- The buffer shape is rank-n = `(*chunk_shape[:-2], min(n_rows, n_cols))` vs. the existing
  rank-1 `(*chunk_shape[:-1], 1)`. It is genuinely more expressive along the spectral axis.

### Novelty grep proofs (EXPERIMENTS_LOG.md)

```
# All return 0 matches for assigned/closed experiments:
grep -c "per.singular.*ema\|gram.*diag.*ema\|sv.*ema.*body\|spectral.*second.*moment.*assign" EXPERIMENTS_LOG.md
# H191 (line 7847) = deferred, not assigned; H238 = per-element (closed); H248 = diagonal EMA-g²
# Per-tensor STATIC LR axis (H7312) = STATIC, not EMA-adaptive — mechanistically distinct
```

### Distinction from closed axes

| Axis | Closed? | Why H390 is distinct |
|---|---|---|
| H191 per-element PRE-NS5 (49th NULL/NEG) | YES | H390 is POST-polar, spectral basis |
| H238 per-element POST-NS5 (bilateral TIE any β₂) | YES | H390 is per-sv not per-element |
| H248 diagonal EMA-g² post-NS5 (105th NULL/NEG) | YES | H390 uses v_chunk² not raw-grad² |
| H7312 per-tensor STATIC LR (exhausted) | YES | H390 is DYNAMIC EMA, not static |
| Shampoo/CASPR/ARFKE/SOAP (pre-closed) | YES | H390 tracks sv of ORTHOGONALIZED v_chunk, not raw gradient covariance; AGC-collapse argument does not apply |
| Existing rank-1 `second_momentum_buffer` | NO (current code) | H390 is rank-n per-sv, not rank-1 |
| H153 weight-averaging strategy tier | YES (strategy closed) | H390 is inner NorMuon variance reduction, not weight averaging |
| H149+H157 AGC clip_ratio schedule | YES | H390 does not touch AGC |
| H289 SCHEDULE axis (outer) | YES | H390 is inner-loop, no outer loop |
| H370 BLENDING axis (outer) | YES | Orthogonal |
| H377 RESET-on-AUX (outer) | YES | Orthogonal |
| H379v2 FORM-LION (outer) | YES | Orthogonal |
| H381 PER-PARAMETER ALLOCATION (outer) | YES | Orthogonal |
| H382 RESET-on-OUTER (outer) | YES | Orthogonal |
| H91/H99/H100/H101/H103/H108/H111/H113/H116 cluster | YES | Orthogonal to outer-loop |
| H385 AUX→BODY v_t cross-axis (in-flight) | AXIS_DISTINCT=YES | H390 is body-internal spectral EMA, not AUX-to-BODY coupling |
| H389 AUX AdamW warmup (alphonse, in-flight) | AXIS_DISTINCT=YES | Completely different subsystem |

### Mechanism

After `polar_express` produces `v_chunk ∈ R^{B×m×n}` with all sv ≈ 1:

1. Compute **spectral column norms**: `sv_proxy = v_chunk.float().pow(2).sum(dim=-2)` → shape `(*batch, n)` for tall (m≥n), or `v_chunk.float().pow(2).sum(dim=-1)` → shape `(*batch, m)` for wide. These are the per-singular-direction energy proxies (equal to sv² × n_rows for an exactly orthonormal matrix).
2. EMA update: `sv_ema.lerp_(sv_proxy.unsqueeze(-2), 1 - beta_sv)` — buffer shape `(*batch, 1, n)` or `(*batch, m, 1)`.
3. Scale: `step_size = sv_ema.clamp_min(1e-10).rsqrt_()`, renormalize to preserve total update norm, multiply into v_chunk.

This replaces the existing `second_momentum_buffer` when `beta_sv > 0`, or co-exists with it via a separate new buffer.

### Code diff (~20 LoC against train_gpt.py)

**State init** (after line 576, inside `elif p_cfg.optim == "normuon":` block):

```python
# H390: spectral sv EMA buffer — shape (*batch, 1, min_dim)
sv_beta = getattr(p_cfg, 'beta_sv', -1.0)
if sv_beta > 0:
    min_dim = min(chunk_shape[-2], chunk_shape[-1])
    sv_ema_buf = torch.zeros(
        (*chunk_shape[:-2], 1, min_dim), dtype=torch.float32, device=param.device
    )
else:
    sv_ema_buf = None
self.param_states[param]['sv_ema_buf'] = sv_ema_buf
```

**New static method** (add after `_apply_normuon_variance_reduction`):

```python
@staticmethod
@torch.compile(dynamic=False, fullgraph=True)
def _apply_spectral_sv_ema(v_chunk, sv_ema_buf, beta_sv):
    # v_chunk: (B, m, n), post-polar, all sv≈1
    # sv_proxy: per-column energy proxy, shape (B, 1, n) for tall matrices
    sv_proxy = v_chunk.float().pow(2).sum(dim=-2, keepdim=True)      # (B,1,n)
    total_norm = sv_proxy.sum(dim=(-2, -1), keepdim=True).sqrt_()    # (B,1,1)
    sv_ema_buf.lerp_(sv_proxy, 1.0 - beta_sv)
    step_size = sv_ema_buf.clamp_min(1e-10).rsqrt_()                 # (B,1,n)
    scaled_sum = (sv_proxy * step_size.float().square()).sum(dim=(-2,-1), keepdim=True).sqrt_()
    final_scale = step_size * (total_norm / scaled_sum.clamp_min_(1e-10))
    return v_chunk.mul_(final_scale.type_as(v_chunk))
```

**Call site** (in `_normuon_update`, after the existing variance reduction block, lines 882-884):

```python
# H390 gate: spectral sv EMA (after rank-1 variance reduction)
sv_buf = p_state.get("sv_ema_buf")
if sv_buf is not None:
    v_chunk = NorMuonAndAdam._apply_spectral_sv_ema(v_chunk, sv_buf, p_cfg.beta_sv)
```

### 3-arm chain

- **arm_a (CTRL)**: `beta_sv=-1` (sentinel → `sv_ema_buf=None`, standard rank-1 path unchanged). Preserves Pattern A bit-id (step-0 val=10.82583 EXACT).
- **arm_b**: `beta_sv=0.99` (fast EMA, adapts within ~100 steps)
- **arm_c**: `beta_sv=0.999` (slow EMA, adapts within ~1000 steps)

### Estimated cost

3 arms × ~110 min each = ~330 min ≈ 5h30m sequential on 1 GPU.

### WIN probability estimate

**12%**. Reasoning: (1) The deferred mechanism at line 7847 was explicitly flagged as
mechanistically coherent by prior research. (2) Programme finding at line 7760 specifically
states body headroom is spectral-aware. (3) The only reason it was deferred was "plateau
depth" at H191 time, not a principled dismissal. (4) The mechanism targets a real
distributional non-stationarity (singular direction activity shifts across training phases).
Counter-argument: polar_express already drives all sv to ≈ 1 per step, so inter-step sv
variance may be small enough that the EMA signal is weak. If that's true, arm_b/arm_c will
TIE rather than WIN.

---

## H391 — NUMERICS: BF16+Mantissa Precision Extension for Nesterov Momentum Buffer

### What it is

The `momentum_buffer` in NorMuon is stored as FP32 (32 bits per element). The parameter
storage already uses a BF16+uint16 mantissa trick (`_cautious_wd_and_update_inplace`) that
gives FP32-equivalent precision by storing BF16 upper bits plus uint16 lower mantissa bits
separately, enabling 32-bit arithmetic from a 16-bit stored format. This hypothesis applies
the same BF16+uint16 mantissa scheme to the *momentum buffer* (gradient-side accumulation)
rather than the parameter. If the FP32 momentum buffer is numerically redundant — i.e., the
model is insensitive to momentum accumulation precision beyond BF16 — this halves the VRAM
for momentum state, potentially improving memory-bandwidth-bound training throughput. If FP32
precision matters for momentum accumulation (Nesterov lookahead coupling), this should
degrade performance, making arm_c (pure BF16, no mantissa extension) a diagnostic.

### Why it might help

- Current `momentum_buffer` consumes the same VRAM as parameters (FP32 = 2× BF16 params).
  Reducing it to BF16+uint16 = same storage as 2×uint16 = same as FP32 but with a different
  layout, or pure BF16 (arm_c) = half the storage, freeing bandwidth for more useful ops.
- The mantissa trick was designed to recover precision from lossy BF16 storage by preserving
  lower bits separately. For the momentum buffer, the key question is whether the Nesterov
  interpolation `g = grad.lerp_(momentum_buffer, momentum)` is sensitive to lower mantissa
  bits. If not, pure BF16 (arm_c) is a VRAM win. If yes, BF16+uint16 (arm_b) should match
  FP32 quality.
- Novelty: the existing mantissa buffer tracks *parameter* lower bits for weight updates. No
  prior experiment has applied mantissa-extension to the *momentum buffer*.

### Novelty grep proofs (EXPERIMENTS_LOG.md)

```
# Confirmed 0 matches:
grep -c "mantissa.*momentum\|mantissa.*EMA\|momentum.*bf16.*mantissa\|mantissa.*fp32.*extend\|BF16.*mantissa.*optim\|momentum.*buffer.*bf16\|stochastic.*rounding.*momentum" EXPERIMENTS_LOG.md
```

Result: 0 matches. No prior experiment applies mantissa precision extension to gradient-side
accumulation buffers. Existing mantissa work is exclusively parameter-side.

### Distinction from closed axes

| Axis | Closed? | Why H391 is distinct |
|---|---|---|
| H153 weight-averaging strategy tier | YES | H391 is optimizer precision, not weight averaging |
| H149+H157 AGC clip_ratio schedule | YES | Unrelated |
| H266 Polyak-Ruppert EMA (outer, all-param) | YES | H391 is inner-optimizer momentum precision |
| H238 per-element post-NS5 scaling | YES | H391 is buffer precision, not scaling |
| H191 per-element pre-NS5 | YES | H391 is buffer precision |
| H248 diagonal EMA-g² | YES | H391 is buffer precision, not scaling |
| H7312 per-tensor STATIC LR | YES | Unrelated |
| 11-axis outer-loop map (H289/H370/H377/H379v2/H381/H382/H91 cluster) | YES | Fully orthogonal — H391 is inner momentum precision |
| H385 AUX→BODY coupling (in-flight) | AXIS_DISTINCT=YES | H391 is NorMuon momentum buffer precision only |
| H389 AUX AdamW warmup (alphonse, in-flight) | AXIS_DISTINCT=YES | Completely different |
| Existing mantissa param-side (H266 codebase) | NO (current code) | H391 applies same scheme MOMENTUM-SIDE, novel gradient-side use |

### Mechanism

Replace `momentum_buffer` (FP32 tensor, shape `chunk_shape`) with:
- `momentum_bf16` (BF16 tensor, shape `chunk_shape`) — upper 16 bits
- `mantissa_mom` (uint16 tensor, shape `chunk_shape`) — lower 16 bits

The combined precision equals FP32. Encoding/decoding follows the exact scheme in
`_cautious_wd_and_update_inplace`:
```
# Encode: FP32 → BF16+uint16
raw = value.view(torch.uint32)
bf16_hi = (raw >> 16).to(torch.uint16)
uint16_lo = raw.to(torch.uint16)

# Decode: BF16+uint16 → FP32
full = (bf16_hi.to(torch.uint32) << 16) | uint16_lo.to(torch.uint32)
value = full.view(torch.float32)
```

For `polar_express`, the momentum buffer must be decoded to FP32 before the `lerp_` call,
then re-encoded after. This adds 2 cast ops per step but removes the FP32 memory footprint
for momentum — pure BF16 arm_c tests whether the decode/encode cost is worth it at all.

### Code diff (~25 LoC against train_gpt.py)

**State init** (replace lines 553-576 for normuon case):

```python
use_mom_mantissa = getattr(p_cfg, 'use_mom_mantissa', False)  # H391 flag
if use_mom_mantissa:
    # BF16 upper + uint16 lower = FP32-equivalent precision, half VRAM footprint
    momentum_buffer = torch.zeros(chunk_shape, dtype=torch.bfloat16, device=param.device)
    mantissa_mom = torch.zeros(chunk_shape, dtype=torch.uint16, device=param.device)
else:
    momentum_buffer = torch.zeros(chunk_shape, dtype=torch.float32, device=param.device)
    mantissa_mom = None
# ... (second_momentum_buffer and mantissa unchanged)
self.param_states[param] = dict(
    momentum_buffer=momentum_buffer,
    mantissa_mom=mantissa_mom,
    second_momentum_buffer=second_momentum_buffer,
    mantissa=mantissa,
)
```

**In `_normuon_update`** (replace lines 875-878):

```python
# H391: decode BF16+uint16 momentum to FP32 if mantissa-extended
mantissa_mom = p_state.get("mantissa_mom")
if mantissa_mom is not None:
    raw = (p_state["momentum_buffer"].view(torch.uint16).to(torch.uint32) << 16) \
          | mantissa_mom.to(torch.uint32)
    mom_fp32 = raw.view(torch.float32)
else:
    mom_fp32 = p_state["momentum_buffer"]

is_large_matrix = chunk_shape[-2] > 1024
v_chunk = polar_express(
    grad_chunk, mom_fp32, self._momentum_t,
    split_baddbmm=is_large_matrix,
)

# H391: re-encode FP32 momentum back to BF16+uint16
if mantissa_mom is not None:
    raw_out = mom_fp32.view(torch.uint32)
    p_state["momentum_buffer"].view(torch.uint16).copy_((raw_out >> 16).to(torch.uint16))
    mantissa_mom.copy_(raw_out.to(torch.uint16))
```

**Note**: `polar_express` modifies `momentum_buffer` in-place via `lerp_` (line 184 of the
function). Since we pass `mom_fp32` (a view of the decoded tensor, NOT the original BF16
buffer), the in-place writes go to `mom_fp32` and are captured by the re-encode step above.

### 3-arm chain

- **arm_a (CTRL)**: `use_mom_mantissa=False` (sentinel → FP32 momentum as-is). Preserves Pattern A bit-id (step-0 val=10.82583 EXACT).
- **arm_b**: `use_mom_mantissa=True` — BF16+uint16 decode/encode (FP32-equivalent precision, different memory layout)
- **arm_c**: `momentum_buffer` stored as pure `bfloat16` (no mantissa extension, no uint16 buffer) — tests whether FP32 momentum precision matters at all. Add `use_mom_bf16_only=True` flag with matching init path.

### Estimated cost

3 arms × ~110 min each = ~330 min ≈ 5h30m sequential on 1 GPU.

### WIN probability estimate

**8%**. Reasoning: This is a numerics-axis diagnostic as much as a win candidate. The FP32
momentum may matter for Nesterov lookahead stability (arm_c would expose this as degraded
val/FFS). If arm_c is stable and arm_b matches CTRL, there is no mechanism for a WIN —
precision parity gives identical updates. However, if the BF16 encoding introduces beneficial
implicit regularization via quantization noise on the Nesterov interpolation (analogous to
stochastic rounding effects seen in some mixed-precision training literature), there could be
a small positive effect on generalization. More realistically: arm_c failing would be the
most scientifically useful result, narrowing momentum precision requirements for future
architecture decisions.

---

## Summary Table

| ID | Axis | Category | WIN% | Cost | Key buffer shape change |
|---|---|---|---|---|---|
| H390 | MEMORY: per-SV spectral Gram-diagonal EMA | Post-polar spectral variance | 12% | ~5h30m | `(*batch, 1, min_dim)` vs existing rank-1 |
| H391 | NUMERICS: BF16+mantissa momentum buffer | Gradient-side precision | 8% | ~5h30m | BF16+uint16 vs FP32 for `momentum_buffer` |

Both hypotheses are mechanism-distinct from each other and from all 11-axis outer-loop map
entries, all per-element body closures (H191/H238/H248), weight-averaging closure (H153),
AGC schedule closure (H149/H157), STATIC per-tensor LR exhaustion (H7312), and
Kronecker-family pre-closures (Shampoo/CASPR/ARFKE/SOAP).
