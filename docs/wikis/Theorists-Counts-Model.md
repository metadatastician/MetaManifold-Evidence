<!-- berrywiki
id: 01a1115e-347a-786f-a781-09d59897629e
parent: 01a1115e-346d-7569-98dd-b9e5be1b6b85
position: 100
kind: page
tags:
  - metamanifold
  - theorists
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# The counts model

Source: [`agda/src/MetaManifold/Evidence/`](https://github.com/metadatastician/MetaManifold-Evidence/blob/495d9a5d3e61b063dfb404608c1c076ca4cd1463/agda/src/MetaManifold/Evidence) (`Counts`, `Bounds`, `CheckerBridge`). Every module is checked with `--safe --without-K`, builtins only, no postulates. Status: **proved**.

## The model

A **world** pairs a latent abundance `x ∈ ℕ` with an observed read count `y ∈ ℕ` that differs from `x` by noise `d` in either direction. The **evidence** for noise bound `n` is `d ≤ n` (the predicate `Bounded`). The observation model is one function, `observed`.

## Interval (`Counts`, `Bounds`)

- **`fibre⇒interval` / `interval⇒fibre`.** The latents consistent with `y` under bound `n` are exactly the `x` with `y ≤ x + n` and `x ≤ y + n`.
- **`fibre⇒bounds` / `bounds⇒fibre`.** With `lo y n = y ∸ n` (truncated subtraction) and `hi y n = y + n`, the fibre is exactly `[lo, hi]`. The two numbers a client shows are proved, not just computed. A fibre is two numbers, so nothing is enumerated, however large `n` is.
- **`never-inconsistent`.** Every observation has an admissible world, so counts never yield `inconsistent`.

## Verdicts

The verdict is complete and sound (`verdict-sound`, `view`):

| Verdict | Holds exactly when | Witness |
|---|---|---|
| `entailed` | `n < y` | every candidate `x ≥ 1` |
| `refuted` | `y = n = 0` | the only candidate is `x = 0` |
| `unresolved` | `y ≤ n` and `n ≥ 1` | `x = 0` and `x = y + n ≥ 1` are both candidates |

## Monotonicity in the noise bound

- **`entailed-anti`**: an entailment survives lowering the bound.
- **`unresolved-mono`**: an unresolved verdict survives raising it.
- **`refuted-only-at-zero`**, **`refuted-fragile`**: refuted occurs only at `y = n = 0`, and any positive bound turns it into unresolved.

So more noise never strengthens a verdict. These hold for all naturals, not on a sampled grid.

## Bridge to the generic finite checker (`CheckerBridge`)

`residual-evidence-types` (MPL-2.0, pinned by commit) has its own certified finite checker, `ResidualEvidence.Finite.Checker`. Its worlds are integer `(latent, noise)` pairs in −6..6, so it also admits negative latents.

On the 49 cells the two models share (`y, n ∈ 0..6`):

- **`presence-agrees`**: the checker's presence verdict equals `verdict y n`. The negative latents it also considers never change it.
- **`latents-agree`**: the natural latents among its candidates are exactly `[lo, hi]`, cut off at its edge 6.

Both premises are needed, and the rejection modules show it:

- `agda/reject/BridgeOutOfRange`: at `y = 7, n = 0` the checker has no candidate while counts says `entailed`.
- `agda/reject/BridgeUnclipped`: `[5, 7]` at `y = 6, n = 1` is not what the checker sees.

## Assumptions (open, for MetaManifold's maintainer)

1. `n` is an **absolute number of reads** per cell, not a proportion.
2. Latent abundance is a **natural number**.

Under a proportional noise model the interval would scale with `y`. That is a different `observed` and a different `Bounded`; nothing else in the development assumes the form.
