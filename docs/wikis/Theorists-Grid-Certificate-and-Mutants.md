<!-- berrywiki
id: 01a1115e-3486-7ef0-9be5-5dc25b8493c6
parent: 01a1115e-346d-7569-98dd-b9e5be1b6b85
position: 110
kind: page
tags:
  - metamanifold
  - theorists
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# The grid certificate and the mutant gates

## The gap it closes

The server runs Julia (`count_verdict`, `fibre` in `julia/src/counts.jl`), and the Julia is **not proved**. The certificate ties it to the proved Agda model on a finite grid.

1. `julia/gen/emit_table.jl` calls the Julia functions on every `(reads, noise) ∈ 0..12 × 0..12` and writes the 169 rows to `CountsJuliaTable.agda`.
2. `CountsCertificate.agda` proves `grid 12 ≡ expected` **by `refl`**: Agda's proved `verdict`, `lo` and `hi` produce exactly that table.

78 of the rows have `n > y`, where the lower end clamps at zero. That is exactly where Julia's `max(0, y − n)` and Agda's `y ∸ n` could have differed.

**Status:**
- **certified on the grid** for 0..12;
- **tested, not proved**, outside it;
- the closed forms the Julia implements are **proved** for all naturals.

## Both directions are guarded

| If… | Then… | Shown by |
|---|---|---|
| the table is edited | Agda refuses the certificate | `mutants.sh`: change one verdict, change one clamp, drop one row |
| the Julia changes | the regenerated table no longer matches the committed one | `julia-mutants.sh`: the table must be current; a non-strict threshold and a missing clamp must each change it |

## The full mutant list (`scripts/mutants.sh`)

Each corruption must be refused by the proofs:

1. an off-by-one threshold;
2. a zero case relabelled unresolved;
3. a one-sided noise model;
4. an off-by-one lower interval end;
5. monotonicity in the wrong direction;
6. a non-strict entailment threshold in the characterisation;
7. a corrupted verdict in the Julia table;
8. a corrupted clamp in the Julia table;
9. a missing row in the Julia table;
10. the bridge stated for an assumed-zero latent;
11. the bridge stated without the cut-off.

## Why this shape

A green proof run proves nothing unless the run could have been red. The rejections (`agda/reject/`) and the mutants are **planted positives**: each shows that the gate can fail on the specific error it is meant to catch. A gate that still passes when a mutant is applied would be a gate that checks nothing.
