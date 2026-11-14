<!-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> -->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# After CompositionalDA is registered

Staging note, not for the pull request. `Project.toml` on this branch declares
`CompositionalDA` (UUID `bb1787b7-c25e-80cd-8559-27e3f8d35816`, `[compat]`
`"0.1"`) but `Manifest.toml` is unchanged, because the package is not in General
yet (General PR 175952, expected to merge after the 3-day wait, about 15 Nov)
and a Manifest entry needs the registry's tree hash, which must come from the
registry and not be written by hand.

Until the Manifest is committed, **this branch cannot be instantiated**: its
`Manifest.toml` has no entry for the new dependency, so the Julia CI job fails
at `Pkg.instantiate()`. Do not open the pull request before the steps below.

## 1. Confirm the registration

```
git ls-remote https://github.com/JuliaRegistries/General HEAD
curl -fsS https://raw.githubusercontent.com/JuliaRegistries/General/master/C/CompositionalDA/Versions.toml
```

The second command must show version `0.1.0` with a `git-tree-sha1`. If it
answers 404 the registration has not merged.

## 2. Resolve against General with Julia 1.12.5

Upstream's `Manifest.toml` is manifest format 2.0 written by Julia 1.12.5, the
version pinned in `config/defaults/tool_versions.yml` and in `ci.yml`. Use that
Julia: a different one rewrites the header and may reformat the file.

```
julia --project=. -e 'using Pkg; Pkg.Registry.update(); Pkg.resolve()'
```

Run this on a machine with R: on a fresh depot, `Pkg.resolve()` can download
and build new packages, and RCall's build step needs R. `Pkg.instantiate()`
needs R for the same reason.
Do not run `Pkg.update()`: it moves unrelated packages.

## 3. Check that only CompositionalDA and what it pulls in changed

```
git diff --stat Manifest.toml
git diff Manifest.toml | grep '^-' | grep -v '^---'
```

The second command should print at most the old `project_hash` line. Any other
removed line means resolve moved an existing package: restore `Manifest.toml`
and resolve again; if a package still moves, the cause is a [compat] clash with
CompositionalDA's dependencies, which needs a decision before the PR.

The added entries are `CompositionalDA` itself and its dependencies that
upstream's Manifest does not have yet. Before the first resolve, `Manifest.toml`
has no entry for `Distributions`, `HypothesisTests` or `StableRNGs`, so expect
those and their transitive dependencies. `CompositionalDA` also lists `RCall` as
a weak dependency, which is already in the Manifest. The description's Scope
section must say why the lockfile changed (CONTRIBUTING rule 7).

## 4. Commit only the Manifest, into the declaring commit

The first commit on this branch ("Declare CompositionalDA as a dependency")
says the lockfile belongs in it, so that every commit instantiates on its own
(CONTRIBUTING rule 8). Fold the Manifest into that commit:

```
git add Manifest.toml
git status --short            # Manifest.toml only
git commit -S --fixup=<sha of the "Declare CompositionalDA" commit>
git rebase -i --autosquash --exec 'git commit --amend --no-edit -S' upstream/main
```

The rebase re-signs every commit with your own key (rule 3). Then reword the
first commit's subject to "Declare and lock CompositionalDA" and drop the last
paragraph of its message, which only explains the staging order. No commit
message names a pull request or CI.

## 5. Run what CI runs, then fill in the versions

```
julia --project=. -t 2 test/runtests.jl --integration --server
(cd frontend && bun run test)
```

Record the Julia, R and bun versions in the description's Validation section.
The R reference fixtures are already committed (R 4.5.0, Bioconductor 3.22,
ALDEx2 1.42.0). If you regenerate them, rerun the comparison before committing:

```
julia --project=. test/fixtures/native_da/generate_reference.jl
julia --project=. test/runtests.jl differential_native
```

and run `reuse lint`. ALDEx2 is not in `renv.lock`; see the description's Scope section. Finally check
`git log --format='%h %G? %s' upstream/main..HEAD` shows no `N`.

## 6. These notes are not in any commit

`docs/proposals/` is in upstream's `.gitignore`, so this file and
`description.md` are untracked on the staging branch and are not pushed with it.
Paste `description.md` into the pull request body. Do not `git add -f` them:
they are not part of the upstream change.
