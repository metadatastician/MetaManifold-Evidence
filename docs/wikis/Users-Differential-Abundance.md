<!-- berrywiki
id: 01a1115e-33ed-7184-897d-e53ba108b76b
parent: 01a1115e-33d5-7016-9f9d-1888ffbfe940
position: 20
kind: page
tags:
  - metamanifold
  - users
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Differential abundance

The **Differential Abundance** tab of the analysis workspace (`frontend/src/components/AnalysisWorkspace.tsx`, tab `differential`) compares two groups of samples taxon by taxon. It calls `POST /api/v1/studies/{study}/analysis/differential`.

## On `main`: negative-binomial GLM (merged in #24)

For each taxon, MetaManifold fits `MASS::glm.nb(y ~ group + offset(log size factor))` to the **observed integer read counts**, then corrects the p-values with Benjamini–Hochberg ([`differential.jl` L4–L13](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/src/analysis/differential.jl#L4-L13)).

- **No pseudocounts and no rounding.** A count that is not a non-negative integer is refused, not rounded.
- **Library size enters as an offset**, chosen by `analysis.differential.offset` in `pipeline.yml`:
  - `tss` (default): total reads per sample;
  - `rle`: median of ratios over the taxa present in every sample. It is refused when no taxon is present in every sample.
- **`min_prevalence`** (default `0.0`) is the fraction of samples in which a taxon must have reads to be tested. Taxa below it are listed as `filtered`, with no p-value.
- **Every row has a status:** `ok`, `boundary`, `failed` or `filtered` (`frontend/src/api/types.ts`).
  - `boundary` means the dispersion ran to its limit ([`differential.jl` L27–L31](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/src/analysis/differential.jl#L27-L31)).
  - A taxon whose fit fails is reported with its reason, kept out of the BH family, and never given a stand-in p-value.
- **The BH family** is the fitted taxa that produced a p-value. `failed` and `filtered` taxa carry no adjusted p-value.
- **Contaminants:** taxa in the `contamination / Contaminant` category are excluded from this surface by default (`exclude_categories … apply_to: [… differential]` in `config/defaults/pipeline.yml`).

The R package MASS must be available; if it is not, the analysis stops with an error that says so. It does not fall back to a different method.

## Proposed, not merged: CLR + Welch t-test (#25)

[PR #25](https://github.com/JoshuaJewell/MetaManifold-WebUI/pull/25) would add a second method, `clr_welch`:
1. Zeros are replaced with `zCompositions::cmultRepl` (GBM).
2. Each sample is centred-log-ratio transformed.
3. Each taxon gets Welch's two-sample t-test, then BH.

Until #25 merges, this method is not in the app. See [[Theorists-Compositional-Methods]] for why the two methods answer different questions.

## Reading the results

- An adjusted p-value controls the **false discovery rate across the tested taxa**. It is not the probability that a given taxon changed.
- The NB model's fold change is relative to the size-factor offset you chose. Changing `tss` to `rle` can change it.
- A `filtered` or `failed` taxon is **not** evidence that nothing changed. It means no test was possible.
