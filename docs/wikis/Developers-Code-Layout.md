<!-- berrywiki
id: 01a1115e-3443-72a0-8f88-0fb3066b5c51
parent: 01a1115e-3436-7208-8dae-d0e5a9d4534b
position: 70
kind: page
tags:
  - metamanifold
  - developers
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Code layout

## MetaManifold-WebUI (`257bcde`)

Adapted from the README's [Architecture](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#architecture) section, with `test/` and `bench/` added from the tree and differential abundance added under `analysis/`:

```
frontend/           TypeScript + React + Vite (SPA), managed with bun
src/
  core/             Types, config cascade, validation, DuckDB store, logging
  pipeline/         Stages: cutadapt, dada2, swarm, vsearch, cd-hit-est, merge_taxa, phylogeny
  analysis/         Diversity metrics, differential abundance, Plotly chart builders
  server/           Oxygen.jl HTTP server (MetaManifold.Server) and its precompile workload
    routes/         REST API route handlers
scripts/            serve.jl (server entry point) and maintenance scripts
config/             Default configs, filters, CI fixtures
test/               unit/, integration/, determinism/, fixtures/
bench/              Benchmarks
```

- **Typed stage results.** Each pipeline stage returns a typed result (`TrimmedReads`, `ASVResult`, `OTUResult`, `TaxonomyHits`, `MergedTables`). A stage is skipped when its outputs are current: by mtime for files, by content hash for configuration.
- **The R boundary.** Statistics run in R through RCall, and every R package is pinned in `renv.lock`. A missing package raises a named error, for example `MASSUnavailable` in `src/analysis/differential.jl`. It never silently substitutes another method ([CONTRIBUTING, Statistics integrity](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/CONTRIBUTING.md#statistics-integrity)).
  - DADA2 lives in `src/pipeline/dada2/`, with R code in `dada2_functions.r`.
  - NMDS and PERMANOVA go through vegan.
  - The NB differential-abundance fit goes through `MASS::glm.nb`.
- **Already native Julia:** Benjamini–Hochberg (`bh_adjust`) and the size factors (`tss_factors`, `rle_factors`) in `src/analysis/differential.jl`.

## MetaManifold-Evidence (`495d9a5`)

```
agda/
  src/MetaManifold/Evidence/   Counts, Bounds, CheckerBridge, CountsJuliaTable, CountsCertificate
  reject/                      Modules that must FAIL to type-check: EntailedAtBound, RefutedUnderNoise,
                               VerdictMislabel, BridgeOutOfRange, BridgeUnclipped
  (also All.agda, CountsGrid.agda)
julia/
  src/                         counts.jl (count_verdict, fibre), server.jl, client.jl, table.jl,
                               receipt.jl, certificate.jl, MetaManifoldEvidence.jl
  gen/emit_table.jl            Writes the 169-row grid table the Agda certificate checks
  test/                        Pkg.test() suite
scripts/                       fetch-layer-a.sh, check.sh, mutants.sh, julia-mutants.sh
docs/wikis/                    This wiki
```

The Julia verdict code is not proved directly. It is tied to the proofs by the grid certificate ([[Theorists-Grid-Certificate-and-Mutants]]). So **if you change `count_verdict` or `fibre`, regenerate the table**, or `julia-mutants.sh` fails in CI.
