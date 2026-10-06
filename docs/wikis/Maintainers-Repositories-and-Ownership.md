<!-- berrywiki
id: 01a1115e-3412-73b3-92a6-ea1d29f50e4d
parent: 01a1115e-3406-71a0-b08e-5fc06b74d855
position: 40
kind: page
tags:
  - metamanifold
  - maintainers
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Repositories and ownership

## MetaManifold-WebUI

- **Owner and maintainer:** Joshua Benjamin Jewell. The maintainer keeps `CITATION.cff` and decides authorship ([CONTRIBUTING, Citation and authorship](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/CONTRIBUTING.md#citation-and-authorship)).
- **Licence:** AGPL-3.0 for code; `README.md` is CC BY-SA 4.0. Contributed code may be MPL-2.0 when marked with an SPDX identifier.
- **Settled decisions** that a pull request does not reopen ([CONTRIBUTING, Settled decisions](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/CONTRIBUTING.md#settled-decisions)):
  - Oxygen.jl for HTTP;
  - React 18 + TypeScript with Vite and bun for the frontend;
  - **statistics in R through RCall**, every package pinned in `renv.lock`;
  - DuckDB for storage.
- **Contributions** branch from the tip of `main`, contain one logical change, carry no merge commits from `main`, and need CI to run and pass. They are squashed on merge.
- **Open proposal:** [issue #36](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/36) asks whether general-purpose statistics may move from R to Julia method by method, with R kept as a test oracle. It is the maintainer's decision. Until the maintainer decides, "statistics through R" stands.

## MetaManifold-Evidence

- **Owner:** metadatastician. It tracks `hyperpolymath/MetaManifold-WebUI#7`.
- **Licence:** AGPL-3.0-or-later. Its dependencies `residual-evidence-types` (Agda) and `ResidualEvidenceTypes.jl` (Julia) are MPL-2.0. They are used and pinned by commit, never copied.
- **Boundary:** it never imports or modifies MetaManifold. It reads a counts TSV, or the app's `POST /api/v1/studies/{study}/runs/{run}/results/tables/{table}/query` route.

## Where documentation lives

| Material | Home |
|---|---|
| Install, configuration, REST API, output tree | MetaManifold-WebUI `README.md` (canonical; this wiki links to it) |
| Contribution rules | MetaManifold-WebUI `CONTRIBUTING.md` |
| What the proofs say, how they are checked | MetaManifold-Evidence `README.md` |
| Cross-cutting guides for four audiences | This wiki, `docs/wikis/` in MetaManifold-Evidence |
