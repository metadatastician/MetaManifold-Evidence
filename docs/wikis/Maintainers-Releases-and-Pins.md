<!-- berrywiki
id: 01a1115e-342a-7e48-8d08-29fec9693ee2
parent: 01a1115e-3406-71a0-b08e-5fc06b74d855
position: 60
kind: page
tags:
  - metamanifold
  - maintainers
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Releases and pins

## Release state

MetaManifold-WebUI has **no git tags and no GitHub releases** (checked 2026-10-06). `docs/release-notes/v0.1.0.md` exists, committed 2026-05-29. It predates the Differential Abundance feature (#24, merged 2026-10-02), so it does not describe that feature. MetaManifold-Evidence has no releases either.

Cutting a release, and choosing its version, is the owner's decision for each repository.

## Pins in MetaManifold-WebUI

| What | Where | How to change it |
|---|---|---|
| Julia, R, bun, external tools | `config/defaults/tool_versions.yml` (Julia repeated in the CI matrix) | Edit the file; `install.jl` and CI both read it. Expect discussion ([CONTRIBUTING, Toolchain and pins](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/CONTRIBUTING.md#toolchain-and-pins)) |
| Julia packages | `Manifest.toml` | `Pkg` operations, committed |
| R packages | `renv.lock` | `renv::install(...)` then `renv::snapshot()` ([README, Reproducing the R environment](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#reproducing-the-r-environment)) |
| Frontend packages | `frontend/bun.lock` | bun |
| CI actions | `uses:` lines in `ci.yml`, pinned by commit SHA | Bump the SHA and the tag comment together |

A lockfile change that the work does not need is refused in review (CONTRIBUTING item 6).

## Pins in MetaManifold-Evidence

| What | Where |
|---|---|
| Agda checker | Debian `agda-bin=2.6.4.3-1+b2`, inside a digest-pinned image, version asserted in CI |
| `residual-evidence-types` | By commit, fetched by `scripts/fetch-layer-a.sh` |
| `ResidualEvidenceTypes.jl` | By commit, through `[sources]` in `julia/Project.toml` (needs Julia ≥ 1.11; not registered in General) |
| Julia for CI | Official tarball, checked against julialang's sha256 |

**Agda versions matter.** The proofs are checked with 2.6.4.3. They have not been checked with 2.7.x. Moving the checker is a change to be made deliberately, with the mutant suite rerun.
