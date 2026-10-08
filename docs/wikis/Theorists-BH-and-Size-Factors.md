<!-- berrywiki
id: 01a1115e-3492-7542-8bb5-5d14981a8893
parent: 01a1115e-346d-7569-98dd-b9e5be1b6b85
position: 120
kind: page
tags:
  - metamanifold
  - theorists
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Benjamini–Hochberg and size factors

**Status: proposed.** The proofs are in [MetaManifold-WebUI PR #26](https://github.com/JoshuaJewell/MetaManifold-WebUI/pull/26) (head `5cf3ae2`), which is open and not merged. The Julia functions they describe are on `main`, merged with #24: `bh_adjust`, `tss_factors`, `rle_factors` and `_median` in `src/analysis/differential.jl` ([L93–L175](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/src/analysis/differential.jl#L93-L175)).

The summary below is from #26's `proofs/agda/README.md`, and its limits are kept as #26 states them.

## Toolchain and discipline

- Agda **2.6.4.3** with agda-stdlib **2.1**. Not checked with 2.7.x or stdlib ≥ 2.2.
- Every module is `--safe --without-K`: no postulates, no holes, no termination or positivity pragmas.
- `proofs/tests/axiom-audit.sh` enforces this, and fails if a module is not imported by `MetaManifold/All.agda`, because an unimported module is never checked.

## What is modelled

- Values are exact rationals (`ℚ`), not `Float64`. Lists stand in for vectors.
- `bhAdjust` follows the Julia: sort with indices, scale rank `r` by `n/r`, running minimum from the top rank down, clamp at 1, restore input order.
- Input validation (finite and in `[0, 1]`) is a **hypothesis** (`All Valid ps`). The Julia `ArgumentError` paths are assumptions of the theorems, not theorems.

## Theorems

| Theorem | Plain statement |
|---|---|
| `bh-nonneg` | every adjusted value is ≥ 0 |
| `bh-dominates-p` | every adjusted value is ≥ its own p-value |
| `bh-at-most-one` | every adjusted value is ≤ 1 |
| `bh-monotone` | `p_i ≤ p_j` ⇒ `adj_i ≤ adj_j`, so ties get equal values |
| `bh-envelope`, `stepUp-envelope` | at sorted rank `k`, adjusted = `min(1, min_{j ≥ k} p_(j)·n/j)` |
| `bh-length` | one output per input |
| `monotone-in-family-size` | a larger family never gives a smaller scaled value |
| `total-positive` | a non-negative row with a positive entry has a positive total, so TSS refuses exactly the all-zero rows |
| `proportions-sum-to-1`, `proportions-bounded` | `x / Σx` sums to 1 and lies in `[0, 1]` |
| `centre-positive`, `centre-monotone` | dividing by any positive rational keeps factors positive and ordered (the model's stand-in for the geometric mean, which is in general irrational and so not computable over ℚ) |

## What is *not* claimed

- **Two differences from the Julia.**
  - The running minimum starts differently: Julia starts it at `1.0`; the model clamps afterwards. `stepUp-envelope` proves the two produce the same values.
  - Tie order differs. That the tie order cannot change the output is **an argument about the Julia code built on a proved lemma** (`bh-monotone`). It is not a formal Julia≡Agda equivalence proof.
- **Exact rationals, not floats.** Floating-point rounding in the Julia is outside the model.
