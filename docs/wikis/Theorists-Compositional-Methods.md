<!-- berrywiki
id: 01a1115e-349f-7529-ba11-706c17175ffe
parent: 01a1115e-346d-7569-98dd-b9e5be1b6b85
position: 130
kind: page
tags:
  - metamanifold
  - theorists
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Compositional methods: NB GLM and CLR

**Status:** neither method is proved.
- The NB GLM is on `main` (#24) and is **tested**.
- CLR + Welch is **proposed** in [PR #25](https://github.com/JoshuaJewell/MetaManifold-WebUI/pull/25).

## Why amplicon counts are awkward

A sequencing run fixes, roughly, the total number of reads per sample. So counts carry only **relative** information: if one taxon blooms, every other taxon's share falls although nothing else changed. Any test of "did taxon *j* change between groups?" has to say *relative to what*.

## Negative-binomial GLM (on `main`)

For taxon `j` in sample `i`:

```
y_ij ~ NB(μ_ij, θ_j),   log μ_ij = log s_i + β0_j + β1_j · [group_i = contrast]
```

- **The reference is the size factor `s_i`**, entered as an offset:
  - TSS: `s_i = Σ_j y_ij`;
  - RLE: the median of ratios to the geometric mean, over taxa present in every sample.
- `β1_j` is a log fold change **relative to that reference**, so the choice of offset is part of the hypothesis.
- **Fitted with `MASS::glm.nb`** on raw integer counts, with no pseudocounts.
- **Degenerate fits** are flagged `boundary`: `θ` at the upper bound (`1e7`) means no overdispersion, collapsing to Poisson; `θ` at the lower bound (`1e-8`) is degenerate the other way.
- **p-values** are from the Wald test on `β1_j`, then BH across the fitted taxa.

## CLR + Welch (proposed in #25)

1. **Zero replacement** with `zCompositions::cmultRepl` (`method = "GBM"`, `output = "prop"`): Bayesian-multiplicative replacement with a geometric-Bayesian-multiplicative prior. The log of zero is undefined, so zeros must go before step 2.
2. **CLR**: `clr(x)_j = log x_j − (1/D) Σ_k log x_k`, which is log abundance relative to the sample's geometric mean.
3. **Welch's t-test** per taxon on the CLR values (`stats::t.test`, Welch form), then BH.

Here **the reference is the geometric mean of the taxa tested in that sample**. It differs from the NB reference, so the two methods can disagree on the same data without either being wrong.

## What to be careful about

- **The zero replacement is a modelling choice, not a neutral step.** Results can move with its `frac` parameter: an imputed proportion above its taxon's smallest observed proportion is lowered to that fraction of it (default 0.65, cmultRepl's own default, after Martín-Fernández et al., 2003).
- **Sparse taxa matter.** In #25 the replacement step refuses a tested taxon with reads in fewer than two samples, because the GBM prior is then undefined. Its error message points at `min_prevalence` as the way to filter such taxa out first.
- **A Julia port is proposed, not done.** [Issue #36](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/36) proposes implementing GBM replacement natively, from Martín-Fernández et al., *Statistical Modelling*, 2015, not translated from zCompositions' GPL source. zCompositions would stay as the oracle. If adopted, that port would be **validated** against R, not proved ([[Theorists-Validated-vs-Proved]]).
