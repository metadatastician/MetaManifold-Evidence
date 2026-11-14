<!-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> -->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

<!-- Draft of the pull request body, in the layout of .github/pull_request_template.md.
     Staging only. Square-bracketed items marked TODO cannot be filled in until
     CompositionalDA is in General and the lockfile is committed. Replace the whole
     file's earlier two-method description; ANCOM-BC is no longer part of this PR. -->

## Change and reason

Adds `aldex2` as a value of `analysis.differential.method`: ALDEx2's Dirichlet
posterior log2 CLR comparison, fitted natively in Julia by
[CompositionalDA](https://github.com/hyperpolymath/CompositionalDA.jl) on the
raw counts, with no R session. It sits beside the existing `nb_glm` and
`clr_welch`.

- `padj` is ALDEx2's expected within-instance Benjamini-Hochberg value and is
  not adjusted again. The effect is a log2 CLR difference, not a fold change.
  The row also carries ALDEx2's `effect`, `diff.win`, `rab.all` and Wilcoxon
  columns.
- New config keys `analysis.differential.mc_samples` (2 to 4096, default 128)
  and `seed` (0 to 2147483647, default 1), validated in the constructor and at
  the config route.
- Refusals are explicit: counts that do not fit `Int`, fewer than two retained
  taxa, a package error (reported with its message), a missing taxon or a
  non-finite statistic. A sample with no reads is left out and named. Nothing
  substitutes another method.
- The differential route accepts a per-request `method` override; the panel
  has a method selector, the CSV export records the posterior settings, and
  the config editor and `docs/guide/web-interface.md` describe the method.
- `CompositionalDA` is declared in `[deps]` and `[compat]` (`"0.1"`) and locked
  in `Manifest.toml`. There is no optional loading, no stand-in backend and no
  path or URL dependency.

Issue: refs #23 (proposal for ALDEx2 and ANCOM-BC as a separate package). This
PR does not close it, because ANCOM-BC is left out (below).

## Validation

Run as CI does:

```
julia --project=. -t 2 test/runtests.jl --integration --server
cd frontend && bun run test
```

Native tests only: `julia --project=. test/runtests.jl differential_native`.

Versions tested: TODO fill in from the run after the lockfile is committed.
Staging checks so far, stated exactly:

| Check | Result |
|---|---|
| `test/unit/test_differential_native.jl` (74 assertions) | passed, Julia 1.12.5, CompositionalDA 0.1.0 developed from a local checkout; `differential.jl` loaded with R stubbed out, not through `MetaManifold` |
| `test/unit/test_differential.jl` and the server routes | not run (needs R and the full package) |
| Reference comparison with R ALDEx2 | pending, see Scope |
| `bun run typecheck` | passed, bun 1.4.4 |
| `bun run test` | passed, 66 tests, bun 1.4.4 |
| R | not tested; no R version has been run against this change |
| `reuse lint` | not run (tool not installed) |
| Julia versions other than 1.12.5, other platforms, browsers | not tested |

## Scope

- **Left out: ANCOM-BC.** The package's own launch-readiness notes list its
  small-unbalanced-design FDR inflation as a release blocker, so it comes in a
  separate PR when that is resolved.
- **R reference fixtures are pending.** `test/fixtures/native_da/` holds the
  small synthetic count table (`counts.tsv`), the generator
  (`generate_reference.jl`, which calls Bioconductor ALDEx2 through RCall under
  a fixed seed, plus three other seeds to measure R's own Monte Carlo spread,
  and records the R, ALDEx2 and Bioconductor versions) and the comparison test
  (`test_differential_native_reference.jl`). The fixtures have not been
  generated, because R and Bioconductor were not available where this was
  written. Until they are committed that test reports one broken test, not a
  pass. Generate them with
  `julia --project=. test/fixtures/native_da/generate_reference.jl`.
  Note that ALDEx2 is not in `renv.lock`; the generator is a developer script
  and nothing in the product loads it, but CONTRIBUTING asks that R packages
  used are pinned there, so please say whether it should be.
- **Lockfile.** `Manifest.toml` changes only to add `CompositionalDA` and the
  packages it needs that were not already locked (`Distributions`,
  `HypothesisTests`, `StableRNGs` and their dependencies): TODO list from the
  final diff. No existing entry moves.
- **Not changed:** the CSV comment-marker quoting, which an earlier draft of
  this work also touched, is unrelated and is not part of this PR.
- **Licensing.** New and changed files carry the licence for their path:
  `test/unit/test_differential_native.jl` and the fixture scripts are MPL-2.0,
  the changes to `test/unit/test_differential.jl` stay AGPL-3.0-or-later, and
  the fixture data are CC0-1.0 through `REUSE.toml`. `LICENSE`, `LICENSES/`,
  `CITATION.cff` and `README.md` are unchanged.
- **Dependency policy.** CONTRIBUTING asks that a dependency on a package the
  contributor maintains be registered, independently useful and agreed in an
  issue first. CompositionalDA is registered; agreement on #23 is still open.

## Contribution checks

- [ ] I followed [CONTRIBUTING.md](../CONTRIBUTING.md).
- [ ] This branch starts at current upstream main and contains no merges from fork main.
      (Check with `bash scripts/maintenance/check-pr-freshness.sh --base origin/main`.)
- [ ] CI has run and passes.
- [x] Existing licensing, citation and acknowledgement text is unchanged.

<!-- Authorship (CONTRIBUTING, "Citation and authorship"): add a line here only if the contributor wants to be considered. That is his decision, not made in this draft. -->
