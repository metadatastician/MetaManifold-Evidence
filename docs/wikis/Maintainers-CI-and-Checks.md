<!-- berrywiki
id: 01a1115e-341e-7da9-a225-dee4ffe044fd
parent: 01a1115e-3406-71a0-b08e-5fc06b74d855
position: 50
kind: page
tags:
  - metamanifold
  - maintainers
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# CI and checks

## MetaManifold-WebUI: `.github/workflows/ci.yml`

One job, `test`, on push and pull request, named `Julia <version> / <os>` at `257bcde` ([`ci.yml` L19–L20](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/.github/workflows/ci.yml#L19-L20)). It:

1. sets up Julia, reads the pins in `config/defaults/tool_versions.yml`, and sets up R;
2. restores R packages from `renv.lock` (with a cache);
3. installs cutadapt, cd-hit, vsearch, swarm, MultiQC and FastQC;
4. builds the frontend with bun and runs its unit tests;
5. downloads the PR2 databases and rebuilds RCall against the installed R;
6. runs `test/runtests.jl`;
7. uploads coverage to Codecov (`codecov/codecov-action`, pinned by SHA).

- **Job name.** `CONTRIBUTING.md` says CI job names carry no version numbers, so that a pin change leaves required checks intact. The job name at `257bcde` still contains the Julia version. [PR #31](https://github.com/JoshuaJewell/MetaManifold-WebUI/pull/31) proposes the version-free name.
- **Branch rules.** At 2026-10-06, `GET /repos/JoshuaJewell/MetaManifold-WebUI/rules/branches/main` returned no rules to a reader with pull-only access (the access this page was written with). The owner, who has admin access, can confirm.
- **Coverage.** `codecov.yml` sets the Codecov policy. `codecov/patch` reports on pull requests.

## MetaManifold-Evidence: `.github/workflows/proofs.yml`

Two jobs ([`proofs.yml`](https://github.com/metadatastician/MetaManifold-Evidence/blob/495d9a5d3e61b063dfb404608c1c076ca4cd1463/.github/workflows/proofs.yml)):

| Job | What it does |
|---|---|
| **Counts proofs, expected rejections and mutants** | Installs Debian's `agda-bin=2.6.4.3-1+b2` in a digest-pinned image, checks the exact version, fetches `residual-evidence-types` by commit, then runs `scripts/check.sh` (proofs, axiom audit, expected rejections) and `scripts/mutants.sh` (every mutant must be refused) |
| **Julia tests and grid certificate** | Installs Julia from the official tarball checked against its published sha256, runs `Pkg.test()`, then runs `scripts/julia-mutants.sh` (the committed table is current, and every Julia mutant changes it) |

CodeQL (`Analyze (actions)`) also reports on `main`.

**Effective rules on `main`** (`rules/branches/main`, 2026-10-06):
- deletion and non-fast-forward are blocked;
- `required_linear_history` and `required_signatures` are set, so **commits must be signed and are squash-merged**;
- `pull_request` review is required;
- `code_scanning` and `code_coverage` rules are active;
- secret-scanning alerts must be resolved.

There are **no required status-check contexts**, so a green run is not itself enforced by a rule.

## What "green" does and does not mean

- A green Evidence run means the proofs type-check, the expected rejections still fail, and every mutant is still caught. It says nothing about inputs outside the 0..12 grid ([[Theorists-Grid-Certificate-and-Mutants]]).
- A green WebUI run means the tests pass on Julia 1.12.x with the pinned R packages. Statistical methods there are **validated or tested, not proved**, except where [[Theorists-BH-and-Size-Factors]] says otherwise, and those proofs are still in an open PR.
