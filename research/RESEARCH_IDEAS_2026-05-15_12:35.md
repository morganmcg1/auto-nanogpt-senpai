# Research Ideas — auto-nanogpt-1gpu-r3 — Wave 1 (2026-05-15 12:35)

Eight ideas, one per idle student, balancing exploitation of strong public
mechanisms with fresh exploration. All build on the plain-Muon starter
(`records/track_3_optimization/train_gpt_simple.py`, 3350 steps,
Muon lr=0.035 wd=0.025, AdamW aux lr=0.3/1-320/0.01 betas=(0.8,0.95)
eps=1e-10).

## Algorithmic exploitation (5)

### 1. NorMuon — alphonse
**Idea:** Replace `Muon` with **NorMuon** (result #10): Muon's NS-orthogonalized
direction multiplied by an Adafactor-style row/col variance preconditioner.
Maintain row-variance `R = EMA(mean(g², dim=cols))` and col-variance
`C = EMA(mean(g², dim=rows))`, then scale the post-NS update by
`sqrt(R[:, None] * C[None, :] / R.mean())`.

**Why:** Result #10 alone reduced 3350 → 3250 (n=20 mean 3.2789). Cheap,
checkin-friendly. Reference impl available in `results/20260503_normuon/`.

### 2. MuonH (hyperball) — askeladd
**Idea:** Apply a Frobenius-ball constraint to hidden matrices after each Muon
update: project `W ← W * min(1, R / ‖W‖_F)` where `R` is a per-tensor budget.
Combine with per-module init std (attn.proj=.026, mlp.proj=.031, mlp.fc=.031).

**Why:** Result #5 lowered step count to 3325 (n=10, 3.2782). Reference impl
in `results/20260430_muonh/train_gpt_simple_muonh.py`.

### 3. Contra-Muon — edward
**Idea:** Add the Contra-Muon coordinated-update mechanism on top of plain
Muon. Contra-Muon partitions the parameter updates so consecutive steps
update orthogonal coordinates (anti-collinear momentum mixing).

**Why:** Result #11 added Contra-Muon to NorMuon and dropped 3250 → 3225;
the mechanism is largely orthogonal to NorMuon and can stack later.
Reference impl in `results/20260501_contra_muon/train_gpt_simple_contra_muon_2.py`.

### 4. SOAP-on-MLP — fern
**Idea:** Precondition the MLP weights (`mlp.fc.weight`, `mlp.proj.weight`)
with SOAP-style two-sided Shampoo before passing into Muon's NS iteration.
Refresh preconditioner every K=32 steps.

**Why:** Result #14 (3.2776 n=4 at 3150) added SOAP precond to MLP weights on
top of Contra-Muon and dropped 3225 → 3150 — a big algorithmic gain.
Reference impl in `results/20260504_contra_muon_mlp_soapish/`.

### 5. MuLoCo outer Nesterov wrapper — frieren
**Idea:** Wrap any inner optimizer in MuLoCo-style outer Nesterov SGD.
Inner steps run normally for `sync_interval=K` micro-steps, then an outer
optimizer takes a Nesterov SGD step with `outer_lr=0.7, outer_momentum=0.5`
across all trainable params.

**Why:** Result #13 reduced 3225 → 3210 by wrapping NorMuonH. The mechanism
is orthogonal to the inner optimizer, so it composes with future winners.
Reference impl in `results/20260504_muloco_normuonh/`.

## Bold optimizer probe (1)

### 6. Lion replacing AdamW and Muon — nezuko
**Idea:** Use Lion (Chen et al. 2023, EvoLved Sign Momentum) on **all
parameters**, replacing both `AdamW` and `Muon`. Settings to screen:
`lr=2e-4, weight_decay=0.1, betas=(0.9, 0.99)`; if loss is far from target,
try `lr=4e-4` and `lr=1e-4`. Use the same linear cooldown schedule.

**Why:** Lion is sign-based and not represented in the bundled records.
Worth a single screening run to see whether it can match Muon's step count
at this scale.

## Clean isolated levers (2)

### 7. Per-module init std on plain Muon — tanjiro
**Idea:** Apply the per-module init std used in #4/#5/#8: `attn.proj
std=0.026`, `mlp.proj std=0.031`, `mlp.fc std=0.031`, keeping `qkv` at the
current default. Otherwise identical to the starter.

**Why:** Cleanly isolates the init lever from optimizer changes. If the
init alone gives a step saving, future PRs can compose it with NorMuon /
MuonH / Contra-Muon. Cheap and fast.

### 8. Cooldown schedule shape sweep — thorfinn
**Idea:** Sweep `set_hparams` cooldown shape ∈ {linear, cosine, square-root,
quadratic} × cooldown_frac ∈ {0.5, 0.7, 0.85, 1.0}. One trial per arm at
3350 steps.

**Why:** Linear cooldown_frac=0.7 is the default but never re-derived for
this benchmark. A small schedule study isolates the schedule lever before
combining with any new mechanism.

## Notes for next wave (post wave 1)

- The strongest wave-1 algorithmic winners should be **stacked** in wave 2.
- Init and schedule winners should be **applied** under the new mechanism for
  fair retuning.
- If Lion is competitive, follow up with sign-based variants (Tiger, ADOPT)
  and adaptive Lion schedules.
- Reserve at least one slot in wave 2 for a fresh preconditioner not yet
  tried (PSGD-Kron, Sophia, KL-SOAP).
