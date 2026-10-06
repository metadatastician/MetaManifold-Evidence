<!-- berrywiki
id: 01a1115e-34ab-78b6-b51d-f22c250870ac
parent: 01a1115e-346d-7569-98dd-b9e5be1b6b85
position: 140
kind: page
tags:
  - metamanifold
  - theorists
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Validated vs proved

Two different claims are made about MetaManifold's statistics, and they should never be blurred.

## Validated

"This Julia method **agrees with R** within tolerance *X* on these inputs."

- R has no formal specification. Its behaviour is defined by its source and its options (`exact = FALSE`, continuity correction, tie handling).
- Floating-point results depend on the order of operations, so bit-identity is generally not available. Agreement is to a stated tolerance.
- The evidence is a **parity test** in CI: fixtures plus randomised inputs, with R kept as the oracle.
- This is the claim [issue #36](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/36) proposes for every method moved from R to Julia. Under that proposal, a method's default switches only once its parity test passes.

## Proved

"This function **meets its mathematical definition**", checked by a proof assistant for every input in the domain.

- It needs a clean definition to prove against: BH's step-up envelope, the properties of TSS proportions, the counts interval.
- It is usually stated over exact numbers (ℕ, ℚ). Floating point is outside the model unless the model says otherwise.
- It says nothing about agreeing with R. A proved function and R's implementation could both meet a definition and still differ in tie order or rounding.

## In between: certified on a grid

The Evidence package adds a third strength. The Julia's output on a finite grid is **proved equal** to the proved model by `refl` ([[Theorists-Grid-Certificate-and-Mutants]]). That is stronger than tested and weaker than proved. Off the grid, it is tested.

## Current inventory

| Thing | Claim |
|---|---|
| Evidence counts model, interval, verdicts, monotonicity | **proved** |
| Evidence ↔ generic checker on 0..6 | **proved** |
| Evidence Julia `count_verdict`, `fibre` | **certified on the grid** 0..12; **tested** elsewhere |
| WebUI `bh_adjust`, `tss_factors`, `rle_factors` | **proposed** proofs (#26, open); **tested** on `main` |
| WebUI NB GLM via `MASS::glm.nb` | **tested**; relies on R |
| WebUI CLR + Welch, cmultRepl | **proposed** (#25, open) |
| R → Julia moves in #36 | **proposed**; would be **validated** |
| DADA2 | relied on as published; not reimplemented |
