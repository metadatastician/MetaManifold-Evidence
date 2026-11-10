# PR #70: the 30 uncovered lines, and the CI that should have caught them

Durable handoff for `JoshuaJewell/MetaManifold-WebUI` PR #70 (`validation/issue-23-native-da`,
"Validation/issue 23 native da"). Authored against `hyperpolymath/MetaManifold-WebUI` at
`be7792f` — the branch head after #314 — and verified to apply there cleanly.

## Status 2026-11-10: executed, and opened as a pull request

This section replaces "Verified here, and not" below. The earlier text is kept as the record of
the first draft, which was never run.

- `0004-pr70-native-adapter-test-seam.patch` is now the commit that was run and pushed:
  `3ed1dfb` on `hyperpolymath/MetaManifold-WebUI`, branch `claude/pr-70-coverage-review-5wvqac`,
  merged 2026-11-10 as [hyperpolymath/MetaManifold-WebUI#319](https://github.com/hyperpolymath/MetaManifold-WebUI/pull/319)
  into `validation/issue-23-native-da`. The head of upstream PR 70 is now `1832f5c`.
- `0005-pr70-coverage-gates-and-estate-lanes.patch` was **not applied**. It no longer applies on
  top of the new `0004` without edits. Its codecov gate, sensitivity test and three estate
  workflows are decisions for the upstream owner. Its workflows pin `hyperpolymath/standards`,
  which moved to `metadatastician/standards` on 2026-10-25.

Changes against the first draft of `0004`:

- `_native_backend` is one line over a constant (`_DEFAULT_NATIVE_BACKEND`). The first draft had a
  `return getfield(@__MODULE__, :CompositionalDA)` line that only runs when the package is
  installed, so it would have been a new uncovered line in CI.
- The one-argument `_native_methods_available(method)` is gone; nothing needed it.
- `test/runtests.jl` no longer lists `test_differential_sensitivity.jl`, a file that only `0005`
  created.

Measured (Julia 1.12.5, R 4.3.3, Ubuntu 24.04):

| check | command | result |
| --- | --- | --- |
| patch line coverage, CI flags | `julia --project=. --code-coverage=user --compiled-modules=no test/runtests.jl differential differential_native` | 1159 pass, 13 skipped; 52 of 52 instrumented lines added to `src/analysis/differential.jl` since upstream `89be534` are covered |
| real package | the same, after `Pkg.develop` of `hyperpolymath/CompositionalDA.jl` at `9903e76` (v0.3.0) in a scratch copy | 1367 pass, 11 skipped; the two real-package testsets ran |
| full unit suite | `julia --project=. -t 2 test/runtests.jl` | 3618 pass, 25 skipped, 1 error: `test_provenance.jl:479` needs the R package `dada2`, which the sandbox does not have |
| planted mutants | 12 corruptions of the adapter, each against `test/runtests.jl differential_native` | baseline green; 12 of 12 killed (BH applied twice, wrong estimate column, log10 for log2, structural decisions ignored, contrast reversed, seam bypassed, one-taxon floor, CompositionError not translated, package name hardcoded, non-finite published, wrong aldex_effect column, structural notes swapped) |

Upstream result at `1832f5c` (2026-11-10 20:25 UTC): the upstream `CI` run passed, and Codecov
reports patch coverage 100% (66 of 66 lines, 0 missing; it was 33 of 63) and project coverage
75.88% (base 75.73%).

Not run locally: the integration, server and frontend tests. The upstream CI ran them.

The mutant runner in `0005` had a defect: it treated `ERROR: LoadError: Some tests did not pass`
as "the mutant failed to load", and every Julia test failure prints that line. A killed mutant
would have been reported as an error. The runner used here counts a kill only when the suite
reaches its `Test Summary` and reports a failure.

### Why PR 70 has no Codex review and no governance comment

- The "Codex Review Summary: Failed" comment is from the ChatGPT Codex connector. The same bot
  posted "You have reached your Codex usage limits for code reviews" twice (7 and 8 November).
  The review did not run because the quota was spent. `@codex review` starts it again when the
  quota resets.
- The fork-governance comment (DEED, K9, Hypatia grid) comes from `.github/workflows/hypatia-scan.yml`
  on fork `main`. Upstream-bound branches start at upstream `main` and contain no merges from fork
  `main`, so they do not carry that file. GitHub then runs only upstream's `ci.yml` for them. The
  Actions run list for `validation/issue-23-native-da` shows only `CI` runs.
- There is no `ponsbot`. gitbot-fleet (at `1a9abe8`) has no such member, and standards has no such
  name. pons asinorum is a built-in row of the Hypatia grid. The word `ponsbot` in the first draft
  of this note and in `0005` was wrong.

## Companion patches

| file | what it is |
| --- | --- |
| `notes/0004-pr70-native-adapter-test-seam.patch` | the test seam and the stand-in backend: the 30 lines, made reachable and measured |
| `notes/0005-pr70-coverage-gates-and-estate-lanes.patch` | patch coverage as a gate, the sensitivity/specificity measurement, the mutant gate, the three estate lanes, the guide section |

Apply, in order, on the PR branch:

```bash
git fetch https://github.com/hyperpolymath/MetaManifold-WebUI.git validation/issue-23-native-da:pr70
git worktree add ../pr70 -b validation/issue-23-native-da pr70
cd ../pr70
git am /path/to/notes/0004-pr70-native-adapter-test-seam.patch \
       /path/to/notes/0005-pr70-coverage-gates-and-estate-lanes.patch
git push origin HEAD:validation/issue-23-native-da     # updates PR #70 in place
```

Not run from here. As with `pr25`, pushing to someone else's PR branch is the step that stays
with the person who owns the timeline; everything up to it is verified (below).

## What the Codecov report was actually saying

> Patch coverage is `52.38095%` with `30 lines` in your changes missing coverage.
> `src/analysis/differential.jl` — 38.77%

The 30 lines were the body of the native adapter: the block that turns a CompositionalDA
`DAResult` into result rows, keeps Benjamini-Hochberg from being applied a second time to
ALDEx2's expected within-instance values, maps `structural_zero` / `structural_zero_both`
verdicts to notes instead of p-values, and records the package provenance.

They were uncovered for a real reason, not an oversight: `CompositionalDA` is not in the General
registry, so it is not a declared dependency (the earlier commits on this branch removed it
deliberately after `Pkg.instantiate()` failed), so **no checkout CI can produce has the
package**. `test/unit/test_differential_native.jl` began with `import CompositionalDA` and the
suite could not load at all; after that was fixed, the adapter's tests skipped. The refusal path
was the only thing that could run, and it was the only thing measured.

Two things were wrong, and only one of them was the missing tests:

1. **The adapter had no seam.** It called `CompositionalDA.aldex2(...)` by name, so nothing short
   of installing the package could exercise it.
2. **Patch coverage was `informational: true`.** The report said "missing lines" and nothing
   failed, so the reason above never had to be stated, let alone fixed. That is the setting this
   change turns around: the next unreachable branch is now visible while there is still a pull
   request to fix it in.

## The seam (patch 0004)

- `differential_abundance(...; native_backend=…)`. `nothing` (default) resolves to the
  `CompositionalDA` this session loaded, or to the existing by-name refusal when it did not. A
  module passed in is used as given. **Production behaviour is unchanged** — the default path is
  the same expression it was, reached through one function call.
- `_is_composition_error(backend, err)` translates the backend's own `CompositionError`, so a
  stand-in's error type is translated exactly as the package's is.
- `diagnostics.native_method.package` now reports `nameof(backend)` rather than the literal
  `"CompositionalDA"`. This is the part that keeps the fix honest: a record produced with the
  stand-in says `NativeDAStub`, so it cannot be mistaken for a record the package produced.

`test/support/native_da_stub.jl` offers the package's two entry points, column names and verdict
strings (`tested`, `structural_zero`, `structural_zero_both`). Two details are deliberate:

- `qvalue` is **not** `bh_adjust(pvalue)`. If it were, a second BH pass inside the adapter would
  produce the same numbers and the test would pass either way.
- structural rows carry `NaN` in `pvalue`/`qvalue` exactly as the package leaves them, so the
  adapter must branch on the verdict *before* it looks at finiteness. A NaN reaching the finiteness
  guard would raise instead of being reported.

`test/unit/test_differential_native.jl` gains four testsets that run on every checkout: the seam;
ALDEx2 wiring (columns, the BH suppression, the group relabelling that keeps the contrast
direction the user asked for even when the reference sorts after the contrast); ANCOM-BC wiring
(units, `effect/log(2)`, structural decisions, a filtered taxon that must not reach the backend, a
feature the caller has no row for); and the refusals in their order (input checks before the
dependency probe, `CompositionError` translated, other failures rethrown untouched, non-finite
statistics refused by name). The real-package comparisons stay: stronger evidence where the
package is developed into the environment, and still loudly skipped where it is not.

`structural_zero_both` cannot be produced through `differential_abundance` — an all-zero column is
filtered out before the backend is called — so the stand-in manufactures that verdict for a
feature that has reads, and the docstring says so. That is a dead branch in production today, and
a dead branch nobody exercises is where a wrong message hides.

## The CI ramp (patch 0005)

### Patch coverage is a gate

`codecov.yml`: patch `target: 90%`, `threshold: 0%`, `informational: false`; `precision: 2`,
`round: down` (a report that rounds 89.6% to 90% passes a gate it did not meet); project threshold
1% → 0.5% with `if_ci_failed: error`; comment layout `reach, diff, files` so the comment answers
"which of the lines I added are untested". 90% rather than 100% because a hundred-percent patch
target invites `# codecov: ignore` on the one line that mattered.

### Precision, sensitivity, specificity

`test/unit/test_differential_sensitivity.jl`: a negative-binomial community (Gamma-Poisson,
dispersion 5) with 8 taxa ×4 in the contrast group, 8 ÷4, 8 unchanged, 16 samples, seeded. The
real analyses are scored after BH at 0.05 for sensitivity, specificity and precision.

Why it is not a tautology, in the file's own words: every other test in the suite compares a
method with a reference implementation *of the same method*, which a method that calls everything
significant would also pass. The label-permuted control re-runs the identical counts with the
labels shuffled; a method whose sensitivity survives that is measuring its own threshold. The
comparison against the control is the strong assertion; the absolute floors (0.625 / 0.625 / 0.6)
are loose on purpose so they hold on any machine, and the metric functions are unit-tested against
a table whose scores are known by hand so a broken counter cannot produce a passing report.

`scripts/ci/check-sensitivity-evidence.jl` reads the measurement. It fails when the file is
missing (a skipped measurement is not a pass), when a claim has no value or floor, when a measured
value contradicts its floor, when `passed` is not what the numbers imply, or when a claim is
graded `Actually-Proven` — this lane cannot produce one. Tiers follow
`hyperpolymath/proven-tests-and-benches`: coverage and provenance are derived from tests that ran,
never declared. The JSON is git-ignored and uploaded as a CI artifact; the step writes the table
into the job summary.

### Test sensitivity (mutants)

`scripts/ci/mutants-differential.sh`, adapted from `scripts/mutants.sh` and
`scripts/julia-mutants.sh` in **this** repository. Ten corruptions of the native adapter, each
with a named catcher in `test_differential_native.jl`:

| label | corruption | caught by |
| --- | --- | --- |
| `bh-not-suppressed` | `if !native_adjustment` → `if true` | padj is the package's qvalue, not BH's |
| `estimate-from-wrong-column` | publishes `effect` where `diff_btw` belongs | ALDEx2 estimate assertions |
| `log2-uses-log10` | `effect / log(2)` → `/ log(10)` | ANCOM-BC log2 fold change |
| `structural-decisions-ignored` | the structural branch never fires | structural rows get status/notes |
| `contrast-direction-reversed` | `"0"`/`"1"` swapped | the recorded group labels |
| `seam-bypassed` | `_native_methods_available(method)` | the stand-in is refused when the package is absent |
| `one-taxon-floor` | `length(tested) >= 2` → `>= 1` | the one-retained-taxon refusal |
| `composition-error-swallowed` | translation removed | the refusal must be an `ErrorException` |
| `package-name-hardcoded` | records `"CompositionalDA"` always | the stand-in is named in diagnostics |
| `nonfinite-published` | the finiteness guard never fires | a NaN must be refused by name |

The unmutated baseline runs first and must pass (a survivor means nothing against a red baseline);
a survivor fails the step; a mutant that dies of a syntax error fails it too, because that proves
the parser works rather than the tests. None needs R — the stand-in backend is what runs.

### The estate lanes

Three workflows, each calling the shared canon instead of copying it, each pinned to
`hyperpolymath/standards@9bdf864cc7f2c8e24b4df84bf00d04158eee3ad5` — a commit at which all four
reusable files were confirmed to exist through the API, not assumed. (The estate's own record on
`pons-asinorum` is that a reusable refused at job setup produces `startup_failure`, no job and no
log, so the pin and the owner spelling are load-bearing.)

- `hypatia-scan.yml` — `hypatia-scan-reusable.yml`, with `hypatia-ref`, `pons-ref` and `panic-ref`
  passed explicitly. The grid's pons row is pons-asinorum (a built-in row; no `ponsbot` exists), its panic row
  is panic-attack (the scanner behind the fleet's `panicbot`); the three values equal the
  reusable's declared defaults at the pin, so nothing changes today and the checker cannot move
  tomorrow without a commit here. `block-on-high: false` **for now**: the first run's findings have
  to be triaged into `.hypatia-baseline.json` or named in `.hypatia-exemptions.adoc` before they
  can be a gate, and gating first would fail pull requests for findings that predate them.
- `k9-deed-conformance.yml` — `deed-conformance.yml` and `k9-conformance.yml` with
  `require-files: false`: this repository carries neither a `.deed` nor a `.k9` yet, so an empty
  corpus is grey rather than red, and the change that adds them flips it. A manifest written to
  satisfy a validator would defeat the lane.
- `cicd-squabbler.yml` — `cicd-squabbler-reusable.yml`. `squabble chains` is the hard gate (exit 4
  cycle or dead upstream, exit 2 tool failure — "a gate that cannot look must not pass"); the fight
  report stays advisory and reports NOT RUN without a credential that can read classic branch
  protection. This is the general case of the defect `ci.yml` already records: a required check
  whose name GitHub does not post verbatim.

None of the three renames or replaces a required check. `Julia tests`, `Agda proofs` and
`REUSE compliance` are untouched, and `test/unit/test_install_pins.jl` keeps enforcing that every
job in `ci.yml` has a non-interpolating name and no matrix.

## Verified here, and not

Verified in the sandbox:

- Both patches `git am` cleanly onto `be7792f` in a fresh clone of the PR branch, and the
  resulting tree is byte-identical (`diff -r`, excluding `.git`) to the tree they were made from.
- All ten mutant `sed` expressions were applied to a copy of `src/analysis/differential.jl` and
  each one changes the file (no stale patterns).
- `bash -n scripts/ci/mutants-differential.sh`; all six YAML files (`ci.yml` and the three new
  workflows) parse; every new file carries SPDX headers (`reuse lint` will see them).
- Every changed and added Julia file parses under tree-sitter-julia (`tree-sitter-julia` 0.23.1).
  That is syntax only: no type inference, no method resolution, no execution.

**Not run, and this is the gap.** There is no Julia, no R, and no access to `pkg.julialang.org` in
the sandbox, so:

- Nothing in the new testsets has been executed. The assertions were derived by hand from the
  stand-in's arithmetic (`diff_btw = 0.5j`, `qvalue = 0.005j`, `effect = log(2)·j/2`, …) and each
  expectation is a number, not a comparison between two implementations — but hand-derived is not
  executed.
- The sensitivity measurement has never met R, so the floors are reasoning, not observation: 4×
  fold change over 8+8 samples with a TSS offset should give near-perfect power for `nb_glm`, and
  the permuted control should give at most one or two calls at BH 0.05 over 24 taxa. If a floor
  is wrong, the fix is the floor, not the measurement.
- The three workflows have never run. They are callers of pinned reusables that other repositories
  in the estate run successfully, and the pins were checked to exist — that is all that is known.
- The Codecov gate is server-side configuration: nothing here can confirm Codecov accepts
  `round: down` / `precision: 2` with these targets until the PR runs.

Likeliest first failures, in order, so they are not a surprise: a Julia detail in
`test/support/native_da_stub.jl` (`DFrame` `push!` with a tuple of nine mixed values;
`map` over `1:n` with `return` in a `do` block); a `@testset`-scope detail around
`@isdefined(HAVE_MASS)` in the sensitivity file; a differential method failing on the simulated
table (a `glm.nb` non-convergence is reported as a `failed` row, which changes specificity but not
the floors); a Codecov config rejection; and the first `hypatia-scan` run's runtime, which builds
three scanners (45-minute timeout).

## Follow-ups this leaves

1. Flip `block-on-high: true` in `hypatia-scan.yml` in the change that lands the triage.
2. Add the repo deed and the K9 contracts, and flip both `require-files` in the same change.
3. When `CompositionalDA` is registered: add the dependency, its `[compat]` bound and the
   regenerated `Manifest.toml` in one change — the real-package testsets then run instead of
   skipping, and the stand-in becomes a fast unit seam rather than the only evidence.
4. `PROPERTY:` the group-direction relabelling and the BH suppression are the two behaviours most
   likely to regress in a refactor; both are asserted against the stand-in and both are mutants.
