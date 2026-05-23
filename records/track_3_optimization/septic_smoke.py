"""H84 septic convergence smoke (v3).

PR primary coefs (2,-3,3,-1) and fallback (1.875,-1.25,0.375,0.05) both fail
convergence on the smoke. This script also explores a principled septic family
constrained by f(0)=2, f(1)=1, f'(1)=0 to find coefs that converge.

Family: (a,b,c,d) = (2, d-2, 1-2d, d) for free parameter d.
  - d=0: degenerate quintic (2,-2,1,0), f'(1)=0 (one order better than modded-nanogpt).
  - d>0: positive cubic perturbation (mirrors Bjorck-Bowie cubic-step direction)
  - d<0: negative cubic perturbation (mirrors d=-1 PR direction but less extreme)

Output is benchmarked against modded-nanogpt's NS5 quintic k=12 (the current
production baseline).
"""

import torch


def zeropower_via_newtonschulz5(G: torch.Tensor, steps: int = 12,
                                  a: float = 2.0, b: float = -1.5, c: float = 0.5) -> torch.Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    for _ in range(steps):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
    if G.size(-2) > G.size(-1):
        X = X.mT
    return X


def zeropower_via_septic_schulz7(G: torch.Tensor, steps: int,
                                  a: float, b: float, c: float, d: float) -> torch.Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    for _ in range(steps):
        A = X @ X.mT
        A2 = A @ A
        B = b * A + c * A2 + d * (A @ A2)
        X = a * X + B @ X
    if G.size(-2) > G.size(-1):
        X = X.mT
    return X


def orthogonality_error(X: torch.Tensor) -> dict:
    Xf = X.float()
    m, n = Xf.size(-2), Xf.size(-1)
    if m <= n:
        gram = Xf @ Xf.T
        dim = m
    else:
        gram = Xf.T @ Xf
        dim = n
    I = torch.eye(dim, device=gram.device, dtype=gram.dtype)
    err = gram - I
    fro = err.norm().item()
    s = torch.linalg.svdvals(Xf)
    return {
        "fro_err": fro,
        "max_dev": (s - 1.0).abs().max().item(),
        "mean_dev": (s - 1.0).abs().mean().item(),
        "sv_min": s.min().item(),
        "sv_max": s.max().item(),
    }


def main():
    device = torch.device("cuda")
    shapes = [
        (768, 2304, "attn.qkv"),
        (768, 768, "attn.proj"),
        (3072, 768, "mlp.fc"),
        (768, 3072, "mlp.proj"),
    ]

    # Advisor pivot: perturbative family (a,b,c,d) = (2, d-1.5, 0.5-2d, d)
    # Preserves modded-nanogpt's g(1)=1, g'(1)=0 in sigma-space but DOES NOT impose g''(1)=0.
    # At d=0 this is the production quintic (2,-1.5,0.5,0). For d!=0, adds Y^3 rank-3 interaction.
    principled_septic = [
        ((2.0, -1.5, 0.5, 0.0), "d=0 (production quintic sanity)"),
        ((2.0, -1.45, 0.4, 0.05), "d=0.05 ADVISOR arm_b primary"),
        ((2.0, -1.4, 0.3, 0.1), "d=0.10 ADVISOR arm_c"),
        ((2.0, -1.475, 0.45, 0.025), "d=0.025 fallback tighter perturbation"),
    ]

    print("== Quintic baseline (modded-nanogpt) k=12 ==")
    for m, n, name in shapes:
        torch.manual_seed(42 + m * 100 + n)
        G = torch.randn(m, n, device=device).bfloat16()
        X = zeropower_via_newtonschulz5(G, steps=12)
        s = orthogonality_error(X)
        print(f"  {name} ({m},{n}): fro={s['fro_err']:.4f} mean_dev={s['mean_dev']:.5f} "
              f"sv_range=[{s['sv_min']:.3f},{s['sv_max']:.3f}]")
    print()

    for coefs, label in principled_septic:
        a, b, c, d = coefs
        print(f"== {label} coefs=({a},{b},{c},{d}) ==")
        # Coefs are in Y-space (the polynomial is in Y = X X^T).
        # Convergence is actually controlled by the sigma-space map g(sigma) = sigma * f(sigma^2).
        # g(1) = a + b + c + d ;  g'(1) = a + 3b + 5c + 7d.
        f_at_0 = a
        f_at_1 = a + b + c + d
        g_at_1 = a + b + c + d
        gp_at_1 = a + 3 * b + 5 * c + 7 * d
        print(f"  f(0)={f_at_0:.4f}  f(1)={f_at_1:.4f}  g(1)={g_at_1:.4f}  g'(1)={gp_at_1:.4f}")
        for m, n, name in shapes:
            torch.manual_seed(42 + m * 100 + n)
            G = torch.randn(m, n, device=device).bfloat16()
            X12 = zeropower_via_septic_schulz7(G, 12, *coefs)
            s12 = orthogonality_error(X12)
            print(f"  {name} ({m},{n}):")
            print(f"    k=12: fro={s12['fro_err']:.4f} mean_dev={s12['mean_dev']:.5f} "
                  f"sv=[{s12['sv_min']:.3f},{s12['sv_max']:.3f}]")
        print()


if __name__ == "__main__":
    main()
