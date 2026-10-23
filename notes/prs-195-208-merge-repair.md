# Post-merge conflict repair (`hyperpolymath/MetaManifold-WebUI` PRs `#195`–`#208`)

Durable handoff for the unified conflict-reconciliation patch authored and verified against
`hyperpolymath/MetaManifold-WebUI` `main` at `c06c0d456cba6c2e7bede29b09e970e4bd065a4e`
(following sequential squash merges of PRs `#195`–`#208`).

## Companion patch

- `notes/0003-fix-post-merge-conflict-regressions-prs-195-208.patch` — single `git format-patch`
  commit onto `c06c0d4` (26 files changed, +616/−1508).

## Regressions fixed

1. **`src/core/doi.jl` duplicate module header (`#200` + `#203` + `#198`)**
   - `src/core/doi.jl` contained two `module DOI` declarations with a single closing `end`,
     preventing `MetaManifold` from loading (`scripts/check-julia-syntax.jl` calls `Meta.parseall`,
     which returns an `:incomplete` `Expr` without throwing).
   - Removes the duplicate `module DOI` header.

2. **Four-way differential abundance collision (`#204` + `#203` + `#206` + `#196`)**
   - Restores `include("analysis/compositional.jl")` in `src/MetaManifold.jl` ahead of
     `include("analysis/differential.jl")`.
   - Unifies `COMPOSITIONAL_METHODS = ("multinomial", "dirichlet_multinomial")` and all nine
     methods in `Differential.METHODS`:
     `("nb_glm", "clr_welch", "ancom_bc", "aldex2", "songbird", "multinomial", "dirichlet_multinomial", "zinb", "hurdle_nb")`.
   - Restores full `DifferentialConfig` fields/kwargs (`mc_samples`, `mn_reference_taxon`,
     `mn_penalty`, `dm_overdispersion_method`, `max_iter`, `tol`, `max_seconds`), exports
     (`CompositionalRefusal`, `RuntimeRefusal`, `DM_METHODS`, `COMPOSITIONAL_METHODS`,
     `fit_ancom_bc`, `fit_aldex2`, `fit_songbird`, `fit_two_part_nb`, `fit_occupancy`), and all
     dispatch branches in `differential_abundance(...)`.
   - Repairs `src/server/routes/config.jl` (`_differential_settings_error` referenced an undefined
     `keys_` with wrong arity) and `src/server/routes/analysis.jl` (`_differential_config` passes
     all method-specific settings with null-safe lookup and maps `CompositionalRefusal` /
     `RuntimeRefusal` / `RStatsUnavailable` to HTTP 422 / 503).
   - Unifies `config/defaults/pipeline.yml`, `docs/statistics/zero-handling.md`,
     `frontend/src/api/types.ts`, `DifferentialPanel.tsx`, `PipelineStages.tsx`,
     `PipelineStages.test.ts`, `differentialTable.ts`, `differentialTable.test.ts`, and
     contradictory `Differential.METHODS` assertions in `test/unit/test_differential.jl`.

3. **CladeCumulus collision (`#200` vs `#207`)**
   - Deduplicates `include("analysis/clade_cumulus.jl")` in `src/MetaManifold.jl`.
   - Removes superseded `#200` artifacts (`src/server/routes/cladistics.jl`, `bench/cladistics.jl`,
     `frontend/src/cladistics/*`, unrouted `api.cladistics` client stubs, and the unrouted
     `cladistics` tab in `StudyView.tsx`) while preserving `#207`'s Agda-backed `CladeCumulus`
     routes/UI and `docs/cladistics/` (required by `MetaManifold-WebUI_chora.deed`).

4. **`test/runtests.jl` unit list**
   - Deduplicates `"test_clade_cumulus.jl"` and restores `"test_evidence.jl"` and
     `"test_evidence_routes.jl"` (`#201`), matching all 49 files in `test/unit/test_*.jl`.

5. **Validated-statistics unit fixtures (`#198` vs `#202`)**
   - Restores `test/unit/test_high_precision.jl`, `test/unit/test_exact_summaries.jl`, and
     `test/unit/test_numeric_policy.jl` to `e313d97` (`#202`) so
     `python3 test/references/check_high_precision_references.py --check test/unit/test_high_precision.jl`
     agrees at 220 digits, zero-total summaries test `=== nothing`, and `exact_rational_sum`
     triggers `ResourceLimitError` on the running total rather than an individual input.

## Apply in `MetaManifold-WebUI`

```bash
git fetch origin main
git checkout -b fix/reconcile-prs-195-208 c06c0d456cba6c2e7bede29b09e970e4bd065a4e
git am /path/to/MetaManifold-Evidence/notes/0003-fix-post-merge-conflict-regressions-prs-195-208.patch
```

If newer commits have landed on `origin/main` since `c06c0d4`, rebase with `git rebase origin/main`
and re-run:

```bash
python3 test/references/check_high_precision_references.py --check test/unit/test_high_precision.jl
(cd frontend && npm install --ignore-scripts && npm run build && bun test src)
bash proofs/tests/axiom-audit.sh
bash scripts/lint-occupancy-readings.sh
```

## Verification completed when authoring this patch

- `git am` onto clean `c06c0d4`: clean, zero warnings
- `frontend`: `tsc && vite build` (418 modules, 0 errors) and `bun test src` (79 pass, 0 fail, 211 assertions)
- `python3 test/references/check_high_precision_references.py --check test/unit/test_high_precision.jl`:
  `Independent decimal references agree (220-digit context).`
- `bash proofs/tests/axiom-audit.sh`: 7 reachable Agda modules clean
- `bash scripts/lint-occupancy-readings.sh`: clean
- Cross-file audit: all 34 includes in `src/MetaManifold.jl`, all 25 includes in `src/server/server.jl`,
  all 49 `test/unit/test_*.jl` files in `UNIT_FILES`, and all `MetaManifold-WebUI_chora.deed` paths verified.
