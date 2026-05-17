"""Functional test for per-head SOAP helper functions (not the whole Muon path)."""

import os
import sys
import importlib.util

# Bypass argparse at import time
sys.argv = ["_test", "--num_trials", "0"]

import torch

# Import the module's helpers by execing the relevant lines (skipping torchrun setup).
# Simpler: just inline the helpers' definitions here using a fresh import after patching.

import torch
from torch import Tensor

SOAP_BETA2 = 0.90
PRECOND_FREQ = 16


def soap_eigenbasis(mat):
    eye = torch.eye(mat.size(0), device=mat.device)
    try:
        _, q = torch.linalg.eigh(mat + 1e-30 * eye)
    except RuntimeError:
        _, q = torch.linalg.eigh(mat.double() + 1e-30 * eye.double())
        q = q.float()
    return torch.flip(q, [1])


def per_head_view(grad, suffix, n_heads, head_dim):
    d_out, d_in = grad.shape
    if suffix.endswith(".proj.weight"):
        assert d_in == n_heads * head_dim
        return grad.view(d_out, n_heads, head_dim).permute(1, 2, 0).contiguous()
    else:
        assert d_out == n_heads * head_dim
        return grad.view(n_heads, head_dim, d_in)


def per_head_unview(heads, suffix):
    n_heads, head_dim, d_other = heads.shape
    if suffix.endswith(".proj.weight"):
        return heads.permute(2, 0, 1).reshape(d_other, n_heads * head_dim)
    else:
        return heads.reshape(n_heads * head_dim, d_other)


def soap_eigenbasis_batched(mat):
    k = mat.size(-1)
    eye = torch.eye(k, device=mat.device).expand_as(mat)
    try:
        _, q = torch.linalg.eigh(mat + 1e-30 * eye)
    except RuntimeError:
        _, q = torch.linalg.eigh(mat.double() + 1e-30 * eye.double())
        q = q.float()
    return torch.flip(q, [-1])


def soap_precondition_momentum_perhead(update, state, suffix, beta2=SOAP_BETA2, eps=1e-8):
    if state["q_row_ph"] is None:
        return update
    update_f = update.float()
    heads = per_head_view(update_f, suffix, state["n_heads"], state["head_dim"])
    q_row_ph = state["q_row_ph"]
    q_col_sh = state["q_col_sh"]
    projected = torch.matmul(q_row_ph.transpose(-1, -2), torch.matmul(heads, q_col_sh))
    state["exp_avg_sq_ph"].mul_(beta2).add_(projected.square(), alpha=1 - beta2)
    inv_sqrt = state["exp_avg_sq_ph"].sqrt().add(eps)
    precond_heads = torch.matmul(q_row_ph, torch.matmul(projected / inv_sqrt, q_col_sh.T))
    precond = per_head_unview(precond_heads, suffix)
    precond.mul_(update_f.norm() / precond.norm().clamp_min(eps))
    return precond.to(update.dtype)


def soap_basis_qr_perhead(row_gg_ph, col_gg_sh, q_row_ph, q_col_sh, exp_avg_sq_ph):
    H, head_dim, _ = q_row_ph.shape
    d_other = q_col_sh.size(0)
    rotated_row = torch.matmul(q_row_ph.transpose(-1, -2), torch.matmul(row_gg_ph, q_row_ph))
    row_eig = torch.diagonal(rotated_row, dim1=-2, dim2=-1)
    row_sort = torch.argsort(row_eig, dim=-1, descending=True)
    q_row_ph = torch.gather(q_row_ph, dim=2, index=row_sort.unsqueeze(1).expand(-1, head_dim, -1))
    exp_avg_sq_ph = torch.gather(exp_avg_sq_ph, dim=1, index=row_sort.unsqueeze(-1).expand(-1, -1, d_other))
    q_row_ph, _ = torch.linalg.qr(torch.matmul(row_gg_ph, q_row_ph))

    col_eig = torch.diag(q_col_sh.T @ col_gg_sh @ q_col_sh)
    col_sort = torch.argsort(col_eig, descending=True)
    q_col_sh = q_col_sh[:, col_sort]
    exp_avg_sq_ph = exp_avg_sq_ph.index_select(-1, col_sort)
    q_col_sh, _ = torch.linalg.qr(col_gg_sh @ q_col_sh)
    return q_row_ph, q_col_sh, exp_avg_sq_ph


def soap_update_preconditioner_perhead(grad, state, suffix, shampoo_beta=SOAP_BETA2, precondition_frequency=PRECOND_FREQ):
    grad_f = grad.float()
    heads = per_head_view(grad_f, suffix, state["n_heads"], state["head_dim"])
    row_gg_ph_new = torch.matmul(heads, heads.transpose(-1, -2))
    state["row_gg_ph"].lerp_(row_gg_ph_new, 1 - shampoo_beta)
    state["col_gg_sh"].lerp_(grad_f.T @ grad_f, 1 - shampoo_beta)

    if state["q_row_ph"] is None:
        state["q_row_ph"] = soap_eigenbasis_batched(state["row_gg_ph"])
        state["q_col_sh"] = soap_eigenbasis(state["col_gg_sh"])
    elif state["soap_step"] > 0 and state["soap_step"] % precondition_frequency == 0:
        state["q_row_ph"], state["q_col_sh"], state["exp_avg_sq_ph"] = soap_basis_qr_perhead(
            state["row_gg_ph"], state["col_gg_sh"], state["q_row_ph"], state["q_col_sh"], state["exp_avg_sq_ph"]
        )
    state["soap_step"] += 1


def init_state(n_heads, head_dim, d_other, device):
    return {
        "n_heads": n_heads,
        "head_dim": head_dim,
        "row_gg_ph": torch.zeros(n_heads, head_dim, head_dim, dtype=torch.float32, device=device),
        "col_gg_sh": torch.zeros(d_other, d_other, dtype=torch.float32, device=device),
        "exp_avg_sq_ph": torch.zeros(n_heads, head_dim, d_other, dtype=torch.float32, device=device),
        "q_row_ph": None,
        "q_col_sh": None,
        "soap_step": 0,
    }


def test_one_step_qkv():
    """One step of per-head SOAP on a q-like grad: should not NaN, output should have same shape and bounded norm."""
    torch.manual_seed(42)
    n_heads, head_dim, d_model = 12, 64, 768
    suffix = ".attn.q.weight"
    state = init_state(n_heads, head_dim, d_model, device=torch.device("cpu"))

    grad = torch.randn(768, 768) * 0.01
    # First step: precondition returns update unchanged (q_row_ph None), then updates state.
    out = soap_precondition_momentum_perhead(grad, state, suffix)
    assert out.shape == grad.shape
    assert torch.allclose(out, grad)  # identity on first step
    soap_update_preconditioner_perhead(grad, state, suffix)
    assert state["q_row_ph"] is not None
    assert state["q_row_ph"].shape == (n_heads, head_dim, head_dim)
    assert state["q_col_sh"].shape == (d_model, d_model)

    # Second step: precondition should now apply
    grad2 = torch.randn(768, 768) * 0.01
    out2 = soap_precondition_momentum_perhead(grad2, state, suffix)
    assert out2.shape == grad2.shape
    assert torch.isfinite(out2).all()
    assert out2.norm() > 0
    print(f"  qkv: precondition shapes & finiteness OK, out norm {out2.norm().item():.4f} vs input {grad2.norm().item():.4f}")
    soap_update_preconditioner_perhead(grad2, state, suffix)
    print(f"  qkv: state soap_step={state['soap_step']}")
    print("test_one_step_qkv PASSED")


def test_one_step_proj():
    torch.manual_seed(43)
    n_heads, head_dim, d_model = 12, 64, 768
    suffix = ".attn.proj.weight"
    state = init_state(n_heads, head_dim, d_model, device=torch.device("cpu"))

    grad = torch.randn(768, 768) * 0.01
    out = soap_precondition_momentum_perhead(grad, state, suffix)
    assert torch.allclose(out, grad)
    soap_update_preconditioner_perhead(grad, state, suffix)
    assert state["q_row_ph"].shape == (n_heads, head_dim, head_dim)
    assert state["q_col_sh"].shape == (d_model, d_model)

    grad2 = torch.randn(768, 768) * 0.01
    out2 = soap_precondition_momentum_perhead(grad2, state, suffix)
    assert torch.isfinite(out2).all()
    assert out2.norm() > 0
    print(f"  proj: precondition shapes & finiteness OK, out norm {out2.norm().item():.4f}")
    print("test_one_step_proj PASSED")


def test_qr_refresh():
    """After 16 SOAP steps, QR refresh should run without errors."""
    torch.manual_seed(44)
    n_heads, head_dim, d_model = 12, 64, 768
    suffix = ".attn.q.weight"
    state = init_state(n_heads, head_dim, d_model, device=torch.device("cpu"))

    for i in range(20):
        grad = torch.randn(768, 768) * 0.01
        soap_precondition_momentum_perhead(grad, state, suffix)
        soap_update_preconditioner_perhead(grad, state, suffix)
    # Should have gone through 1 QR refresh at step 16
    assert state["soap_step"] == 20
    assert torch.isfinite(state["q_row_ph"]).all()
    assert torch.isfinite(state["q_col_sh"]).all()
    assert torch.isfinite(state["exp_avg_sq_ph"]).all()
    print(f"  20 steps including QR refresh at step 16 succeeded, soap_step={state['soap_step']}")
    print("test_qr_refresh PASSED")


def test_norm_preservation():
    """Per-head SOAP precondition should preserve the global norm of the update."""
    torch.manual_seed(45)
    n_heads, head_dim, d_model = 12, 64, 768
    suffix = ".attn.q.weight"
    state = init_state(n_heads, head_dim, d_model, device=torch.device("cpu"))

    # Bootstrap state with a few steps
    for _ in range(5):
        grad = torch.randn(768, 768) * 0.01
        soap_precondition_momentum_perhead(grad, state, suffix)
        soap_update_preconditioner_perhead(grad, state, suffix)

    test_update = torch.randn(768, 768) * 0.05
    pre_norm = test_update.norm().item()
    preconditioned = soap_precondition_momentum_perhead(test_update, state, suffix)
    post_norm = preconditioned.norm().item()
    rel_diff = abs(post_norm - pre_norm) / pre_norm
    assert rel_diff < 1e-3, f"Norm preservation FAILED: pre={pre_norm} post={post_norm} rel_diff={rel_diff}"
    print(f"  norm preserved (rel_diff={rel_diff:.2e})")
    print("test_norm_preservation PASSED")


if __name__ == "__main__":
    test_one_step_qkv()
    test_one_step_proj()
    test_qr_refresh()
    test_norm_preservation()
    print("\nAll per-head SOAP function tests PASSED")
