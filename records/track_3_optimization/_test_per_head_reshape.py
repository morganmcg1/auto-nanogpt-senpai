"""Standalone test for per-head SOAP reshape axes.

Verifies:
1. Round-trip reconstruction (PR's sanity check).
2. Per-head matmul equivalence: nn.Linear(W) per-output is the same as per-head
   processing of weights along the head axis.
3. Per-head Gram has the expected block-diagonal interpretation.
"""

import torch
import torch.nn.functional as F


def per_head_view(grad: torch.Tensor, suffix: str, n_heads: int, head_dim: int) -> torch.Tensor:
    """Reshape (d_out, d_in) grad to (n_heads, head_dim, d_other), with per-head axis first."""
    if suffix.endswith(".proj.weight"):
        # grad is (d_out=d_model, d_in=n_heads*head_dim) -> (n_heads, head_dim, d_out)
        d_out, d_in = grad.shape
        assert d_in == n_heads * head_dim, f"proj d_in={d_in} != {n_heads}*{head_dim}"
        # view(d_out, n_heads, head_dim) splits the d_in axis along (n_heads, head_dim).
        # Then permute to put n_heads first and put d_out last.
        return grad.view(d_out, n_heads, head_dim).permute(1, 2, 0).contiguous()
    else:
        # q/k/v: grad is (d_out=n_heads*head_dim, d_in=d_model) -> (n_heads, head_dim, d_model)
        d_out, d_in = grad.shape
        assert d_out == n_heads * head_dim, f"qkv d_out={d_out} != {n_heads}*{head_dim}"
        return grad.view(n_heads, head_dim, d_in)


def per_head_unview(heads: torch.Tensor, suffix: str) -> torch.Tensor:
    """Inverse of per_head_view: (n_heads, head_dim, d_other) -> (d_out, d_in)."""
    n_heads, head_dim, d_other = heads.shape
    if suffix.endswith(".proj.weight"):
        # heads (n_heads, head_dim, d_out) -> (d_out, n_heads, head_dim) -> (d_out, n_heads*head_dim)
        return heads.permute(2, 0, 1).reshape(d_other, n_heads * head_dim)
    else:
        # heads (n_heads, head_dim, d_model) -> (n_heads*head_dim, d_model)
        return heads.reshape(n_heads * head_dim, d_other)


def test_roundtrip():
    """PR's sanity check: view-then-unview must reconstruct exactly."""
    torch.manual_seed(0)
    n_heads, head_dim, d_model = 12, 64, 768
    for suffix in [".attn.q.weight", ".attn.k.weight", ".attn.v.weight", ".attn.proj.weight"]:
        W = torch.randn(d_model, d_model)
        heads = per_head_view(W, suffix, n_heads, head_dim)
        assert heads.shape == (n_heads, head_dim, d_model), (
            f"{suffix}: heads shape {heads.shape} != ({n_heads}, {head_dim}, {d_model})"
        )
        W_back = per_head_unview(heads, suffix)
        assert W_back.shape == W.shape, f"{suffix}: reconstructed shape {W_back.shape} != {W.shape}"
        assert torch.allclose(W_back, W), f"{suffix}: roundtrip FAILED"
        print(f"  {suffix}: roundtrip OK, heads shape {tuple(heads.shape)}")
    print("test_roundtrip PASSED")


def test_qkv_axis_matches_attention_head_structure():
    """For q/k/v: head h's output dims correspond to attention output[..., h*head_dim:(h+1)*head_dim].

    With the model's actual head_dim=128 num_heads=6, the SAME reshape with n_heads_soap=6
    head_dim=128 would exactly match attention heads. With n_heads_soap=12 head_dim=64,
    each soap head is half of one attention head. We test the math is consistent.
    """
    torch.manual_seed(1)
    d_model = 768

    # Test with n_heads=6, head_dim=128 (matches actual attention)
    n_heads, head_dim = 6, 128
    W_q = torch.randn(d_model, d_model)  # q weight shape (d_out=768, d_in=768)
    x = torch.randn(4, 16, d_model)  # (B, T, d_model)
    q_full = F.linear(x, W_q)  # (B, T, d_model)
    q_per_head_full = q_full.view(4, 16, n_heads, head_dim)  # (B, T, H, head_dim)

    # Now apply per-head: each head's q-output is x @ W[h]^T where W[h] is head h's rows
    heads_W = per_head_view(W_q, ".attn.q.weight", n_heads, head_dim)  # (H, head_dim, d_model)
    # For each head h: head_out[h] = x @ heads_W[h]^T
    per_head_outs = torch.einsum('btd,hkd->bthk', x, heads_W)  # (B, T, H, head_dim)
    assert torch.allclose(q_per_head_full, per_head_outs, atol=1e-4), \
        f"q/k/v head reshape MISMATCH; max diff {(q_per_head_full - per_head_outs).abs().max()}"
    print(f"  qkv: head reshape matches attention head structure for n_heads={n_heads}, head_dim={head_dim}")

    # Also test with n_heads_soap=12 (the PR default)
    n_heads, head_dim = 12, 64
    heads_W2 = per_head_view(W_q, ".attn.q.weight", n_heads, head_dim)
    assert heads_W2.shape == (12, 64, 768)
    # Reconstruct: each "soap head" of size 64 is half of an "attention head" of size 128
    # Verify reconstruction is still correct
    W_back = per_head_unview(heads_W2, ".attn.q.weight")
    assert torch.allclose(W_back, W_q), "n_heads=12 reconstruction FAILED"
    print(f"  qkv: n_heads_soap=12 head_dim=64 reconstructs correctly (each soap-head is half an attention head)")

    print("test_qkv_axis_matches_attention_head_structure PASSED")


def test_proj_axis_matches():
    """For proj: head h's input dims are columns h*head_dim:(h+1)*head_dim in input."""
    torch.manual_seed(2)
    d_model = 768
    n_heads, head_dim = 6, 128

    W_proj = torch.randn(d_model, d_model)  # proj weight (d_out=768, d_in=768)
    # input is attention output: per-head (B, T, H, head_dim) reshaped to (B, T, H*head_dim)
    attn_out_per_head = torch.randn(4, 16, n_heads, head_dim)
    attn_out = attn_out_per_head.reshape(4, 16, n_heads * head_dim)
    proj_full = F.linear(attn_out, W_proj)  # (B, T, d_model)

    # Per-head reshape: each head h contributes attn_out_per_head[..., h, :] times heads_W[h]
    heads_W = per_head_view(W_proj, ".attn.proj.weight", n_heads, head_dim)  # (H, head_dim, d_out)
    # For each head h: contribution = attn_out_per_head[..., h, :] @ heads_W[h]
    # heads_W[h] is shape (head_dim, d_out), so contribution shape = (B, T, d_out)
    per_head_contribs = torch.einsum('bthk,hko->btho', attn_out_per_head, heads_W)  # (B, T, H, d_out)
    proj_from_heads = per_head_contribs.sum(dim=2)  # sum over heads
    assert torch.allclose(proj_full, proj_from_heads, atol=1e-4), \
        f"proj reshape MISMATCH; max diff {(proj_full - proj_from_heads).abs().max()}"
    print(f"  proj: head reshape gives same output sum as full linear, n_heads={n_heads}")

    # Verify n_heads_soap=12 also roundtrips
    n_heads, head_dim = 12, 64
    heads_W2 = per_head_view(W_proj, ".attn.proj.weight", n_heads, head_dim)
    assert heads_W2.shape == (12, 64, 768)
    W_back = per_head_unview(heads_W2, ".attn.proj.weight")
    assert torch.allclose(W_back, W_proj), "proj n_heads=12 reconstruction FAILED"
    print(f"  proj: n_heads_soap=12 head_dim=64 reconstructs correctly")

    print("test_proj_axis_matches PASSED")


def test_per_head_gram_block_diagonal():
    """Verify per-head Gram and full Gram relate as expected (block-diagonal)."""
    torch.manual_seed(3)
    d_model = 768
    n_heads, head_dim = 12, 64

    grad = torch.randn(d_model, d_model)  # full grad

    # q/k/v: per-head row Gram should equal block of full row Gram only if W is block-diagonal-friendly
    # In general grad @ grad.T has shape (768, 768); per-head row Grams are diagonal blocks of grad @ grad.T
    # IF the cross-head off-diagonals were zero. They are not in general.
    # The point of per-head SOAP is to EXTRACT the diagonal blocks and ignore cross-head.

    heads_grad = per_head_view(grad, ".attn.q.weight", n_heads, head_dim)  # (12, 64, 768)
    # Per-head row Gram: heads_grad[h] @ heads_grad[h].T
    per_head_row_gg = heads_grad @ heads_grad.transpose(-1, -2)  # (12, 64, 64)
    full_row_gg = grad @ grad.T  # (768, 768)

    # Check: diagonal blocks of full_row_gg match per_head_row_gg
    for h in range(n_heads):
        block = full_row_gg[h * head_dim:(h + 1) * head_dim, h * head_dim:(h + 1) * head_dim]
        assert torch.allclose(block, per_head_row_gg[h], atol=1e-3), \
            f"head {h}: diag block mismatch, max diff {(block - per_head_row_gg[h]).abs().max()}"
    print("  per-head row Gram matches diagonal blocks of full row Gram")

    # Also verify shared col Gram via per-head equals full col Gram
    # Full col Gram = grad.T @ grad = sum over heads of head_grad.T @ head_grad
    full_col_gg = grad.T @ grad  # (768, 768)
    per_head_col_contrib = heads_grad.transpose(-1, -2) @ heads_grad  # (12, 768, 768)
    summed = per_head_col_contrib.sum(dim=0)  # (768, 768)
    assert torch.allclose(summed, full_col_gg, atol=1e-3), \
        f"col Gram from sum-over-heads mismatch, max diff {(summed - full_col_gg).abs().max()}"
    print("  shared col Gram = full col Gram = sum over heads of per-head col contribution")

    print("test_per_head_gram_block_diagonal PASSED")


if __name__ == "__main__":
    test_roundtrip()
    test_qkv_axis_matches_attention_head_structure()
    test_proj_axis_matches()
    test_per_head_gram_block_diagonal()
    print("\nAll per-head reshape tests PASSED")
