<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->
# PR #68 close-out: the three review findings, the 18 uncovered lines, and CI

Durable handoff for `JoshuaJewell/MetaManifold-WebUI#68`, "Make SSH stages
recoverable after local interruptions". Read on 2026-11-09 against PR head
`5115109be0ef475b35787011e515db134f4dd05f`, base `89be534ab5cf5e286b34a8e0bf9310527c492ec5`.

## Companion patch

- `notes/0004-pr68-ssh-recovery-coverage.patch` — one `git format-patch` commit
  onto `5115109` (3 test files, +211/−1). It closes the Codecov gaps listed
  below; it does **not** change production code, because the three review
  findings are already fixed at this head.

## What was asked, and what is actually left

The pasted review comments are anchored to an *earlier* head (`f0992480`). Six
follow-up commits landed after them: `ab576a8`, `a4e2412`, `3cf7c82`, `910eeb7`,
`e147ba9`, `3295f93`, `ca8ab07` and `5115109`. Six of the PR's nine review
threads are already resolved; the three still open are exactly the three pasted
in the request. All three are addressed in the current code. What was genuinely
outstanding was **coverage**, and the **thread resolution state**.

### 1. Reclaim superseded attempts that never launched (thread `PRRT_kwDORbJW48606d5b`)

The finding: a journal archived because inputs or settings changed left behind
an attempt directory with no worker and no exit marker, which `_sweep` skips.

At `5115109`:

- `src/pipeline/remote_session.jl:385-421` reads the *original* host, staging
  root, threads and key out of the archived journal's own identity
  (`JSON3.read(journal["identity"])[2,3,5]`, `old_dir`, `old_ctl`) and reclaims
  through `old_target` before archiving the journal. It never deletes a path on
  the new host.
- `_cancel_remote(ssh, target, dir; reclaim=true)` (`:111-123`) removes the
  directory directly when the status probe reports `missing` (no worker was
  ever installed) or any non-running/non-stopping terminal state; a live attempt
  still goes through `cancel` + `cleanup`, which kills the process group first.
- `_sweep` (`:292-313`) deliberately still refuses directories without a worker
  and an old `.metamanifold/exit`; the direct reclaim above is the path that
  prevents an interrupted preparation from stranding uploaded reads.
- Regressions: `test/unit/remote_protocol_tests.jl:511` ("a superseded
  preparation is reclaimed instead of stranded") and `:534` ("a declined
  reclamation does not block the new attempt"). The new patch adds a case that
  reaches both old-master teardown branches with an owned transport.

### 2. Preserve DADA2 logs when recovering a receipt (thread `PRRT_kwDORbJW48606d5n`)

The finding: an early return on a verified receipt left only a freshly
truncated stage header after remote cleanup.

At `5115109`:

- `_replay_remote_log(ssh, target, dir, log_path)` (`:322-330`) is called at
  `:450`, **before** the `cleanup` control request at `:451-453` removes the
  attempt directory that holds the remote log. It compares bytes, appends only
  when the remote text is not already present, and is therefore idempotent.
- Every stage entry point that used to truncate unconditionally now keeps the
  log when a journal is retained: `src/pipeline/dada2/denoise.jl:180,354,413`,
  `chimera.jl:157`, `qc.jl:41,106`, `taxonomy.jl:131`, and
  `src/pipeline/phylogeny.jl:586`.
- Regressions: `:555` ("a finished attempt keeps its remote diagnostics in the
  stage log"), `:624` ("the retained remote log is replayed once"), and the new
  patch's "receipt recovery cleans up a retained attempt", which pins the
  `cleanup` line reached when a live attempt still sits behind a receipt.

### 3. Retry attempts that finish without required outputs (thread `PRRT_kwDORbJW48606lKn`)

The finding: a zero exit that omits a required file threw before a receipt was
stored, while the `exit 0` marker and `failed=false` journal made `start`
refuse and `retry` refuse.

At `5115109`:

- `_missing_outputs` (`:231-241`) asks the same question the fetch asks and
  reports the missing names at `:526-533`, without clearing the exit marker or
  setting `failed`.
- `src/pipeline/remote_worker.sh:173-195` adds a `replay` action that keeps
  both markers so a successful attempt stays retrievable;
  `remote_session.jl:479-491` uses it on the `exit 0` barrier instead of
  `retry`. The next run fetches the same attempt, checksum-verifies every byte,
  stores the receipt and then cleans up.
- Regressions: `:486` ("a completed attempt is retrieved again instead of
  wedging the stage"), `:597` ("a completed attempt without a required output
  stays retrievable"). The new patch adds a direct test of `_fetch_outputs`'s
  own missing-required-output error.

## Codecov: what the green check does not say

`codecov/patch` is **green** at `5115109`, but its title still reads
`94.59% of diff hit (target 75.73%)`. That is not a contradiction:
`codecov.yml` sets `coverage.status.patch.default.informational: true`, so the
check cannot fail a merge. The Codecov v2 API (pull `68`, compare
`89be534...5115109`, report updated 2026-11-08T03:50:44Z) gives:

| scope | lines | hits | misses | coverage |
| --- | --- | --- | --- | --- |
| whole patch | 333 | 315 | 18 | 94.59% |
| `src/pipeline/remote_session.jl` | 290 | 278 | 12 | 95.86% |
| `src/pipeline/phylogeny.jl` (changed lines) | 7 | 2 | 5 | 28.57% |
| `src/pipeline/remote_exec.jl` (changed line) | 1 | 0 | 1 | 0.00% |

The 18 uncovered changed lines, from `file_report` and the compare diff:

- `remote_session.jl` **259** (`_fetch_outputs` required-output error),
  **402**, **417** (old SSH master teardown on a superseded journal),
  **432-436** (durable `cancel_requested` at reattachment),
  **452** (`cleanup` behind a verified receipt),
  **543** (a non-interrupt `_sweep` failure),
  **548**, **549** (own-master `finally`).
- `phylogeny.jl` **582**, **583**, **584**, **586**, **589** (`run_workflow`'s
  local and remote log/key branch).
- `remote_exec.jl` **53** (`verify_remote_sizes`' new `_sq` quoting).

Many of these are reachable only with `_connection === nothing`: the unit
fixture injects a transport, and `test/remote_ssh.jl` runs without
`--code-coverage=user`, so neither suite attributed those lines to the report.

### What `0004-*.patch` adds

- `test/unit/remote_protocol_tests.jl`: a `fail_sweep` switch and a
  `_refusing_transport` helper (a two-line `ssh`/`scp` on `PATH` inside
  `withenv`), plus six testsets that reach the fetch error, the durable cancel
  request, receipt cleanup, a refused sweep, the own-transport `finally`, and
  both superseded-journal branches (pending and abandoned).
- `test/unit/test_phylogeny.jl`: one testset that calls `run_workflow` through
  both halves of the new branch with steps whose commands cannot run, asserting
  that a local rerun truncates the log and clears stale outputs while a
  retained journal keeps the log and clears only the step key.
- `test/unit/test_remote_stages.jl`: one testset for `verify_remote_sizes`
  with an apostrophe and a space in an uploaded filename, plus a truncated
  upload.

`test/unit/remote_protocol_tests.jl` is included by
`test/unit/test_remote_stages.jl` on Linux, which is in `test/runtests.jl`'s
`UNIT_FILES`, so all three files run in the coverage-instrumented "Run tests"
step. No workflow change is needed.

## CI and merge readiness

`gh pr checks 68` at `5115109` (run `42442911919`):

| check | result |
| --- | --- |
| Agda proofs | pass (44s) |
| Julia tests | pass (21m) |
| REUSE compliance | pass |
| codecov/patch | pass (informational, 94.59%) |

`mergeable: true`, `mergeable_state: clean`, `reviewDecision: null`. The PR is
CI-clean and ready to merge into `JoshuaJewell/MetaManifold-WebUI:main`. A
merge is nonetheless a **write** to that repository: this session's GitHub
token has `admin` on `hyperpolymath/MetaManifold-WebUI` (the fork holding the
PR head) and on `metadatastician/MetaManifold-Evidence`, but only `pull` on
`JoshuaJewell/MetaManifold-WebUI`. `gh pr merge 68 --merge` was attempted and
returned `Resource not accessible by integration`, so merging belongs to a
maintainer of the base repository (or to a token with write access there).

## The review conversations

Nine threads, six already resolved. The three open ones are the three above;
none is outdated, so their anchors still point at live code. Resolving them
needs `resolveReviewThread`, which requires write access to the base
repository. The attempt in this session returned:

```
FORBIDDEN: Resource not accessible by integration
```

For someone with `push`/`triage` on `JoshuaJewell/MetaManifold-WebUI`:

```bash
for id in PRRT_kwDORbJW48606d5b PRRT_kwDORbJW48606d5n PRRT_kwDORbJW48606lKn; do
  gh api graphql -f query="mutation { resolveReviewThread(input: {threadId: \"$id\"}) { thread { id isResolved } } }"
done
```

There is no REST equivalent; the GraphQL node IDs come from
`pullRequest(number: 68) { reviewThreads(first: 100) { nodes { id isResolved } } }`.
All three mutations were attempted in this session and all three were refused,
so the threads are still open. A REST reply to the first thread was also
attempted and refused with the same 403: this token cannot write to the base
repository at all. Draft replies, one per thread, are in the closing section
below for the PR author (or a maintainer) to post; resolution and the final
merge need a credential with `push`/`triage` on
`JoshuaJewell/MetaManifold-WebUI`.

## Apply the companion patch

```bash
git fetch https://github.com/JoshuaJewell/MetaManifold-WebUI.git pull/68/head:pr68
git worktree add ../pr68 -b fix/66-resumable-ssh-stages pr68
cd ../pr68
git am /path/to/MetaManifold-Evidence/notes/0004-pr68-ssh-recovery-coverage.patch
# re-run the checks, then push to the fork that owns the PR head:
julia --project=. -t 2 test/runtests.jl test_remote_stages.jl test_phylogeny.jl
```

Pushing to the PR head and resolving/merging on the base repository are left to
the people who own those timelines, as with `0001`–`0003` in this directory.

## Verification recorded when authoring the patch

- `git apply --check` onto a clean `5115109` tree: clean.
- `git am` in a fresh shallow clone at `5115109`: clean, zero warnings,
  resulting tree byte-identical to the one the patch was made from.
- Token-level structure check with pygments' Julia lexer (strings and comments
  excluded): brackets balanced and block depth unchanged from the baseline in
  all three modified files. The lexer reports a non-zero absolute block depth in
  `test_phylogeny.jl` (9) and `test_remote_stages.jl` (1) both before and after
  the edit — pre-existing `@testset`/`do` constructs the lexer pairs loosely —
  so the meaningful result is the zero delta.
- **Not run: Julia.** This sandbox has no Julia, R or Agda, so the new tests
  have never been executed. CI is their first run, exactly as for the PR #25
  rework in this directory. The three most likely first failures are a `withenv`
  do-block signature detail, a `JSON3.Object` method (`haskey`/`get`) in the
  fabricated receipt, and the exact exception type reaching `@test_throws` from
  a refused `ssh`; all three are one-line fixes. The production code at
  `5115109` is untouched by this patch, so a failure here cannot make the
  already-green PR red before it is applied.

## Draft replies (post under the PR author's account)

**Reclaim superseded attempts that never launched**

> Fixed at `5115109`. A superseded journal is now reclaimed through the
> original host/staging root/key recorded in its own identity (`remote_session.jl:385-421`),
> and `reclaim=true` removes a lock-free preparation directly while a running
> attempt still goes through `cancel` (`:111-123`). `_sweep` keeps its
> worker-plus-old-exit rule; it is no longer the only path that can retire an
> interrupted preparation. Covered by the two reclamation regressions and by
> `notes/0004-pr68-ssh-recovery-coverage.patch`, which adds the two owned-master
> teardown cases.

**Preserve DADA2 logs when recovering a receipt**

> Fixed at `5115109`. Receipt recovery replays the retained remote log before
> `cleanup` deletes the attempt (`remote_session.jl:322-330, 448-453`), byte-wise
> and idempotently, and every DADA2 stage entry point plus the phylogeny step
> now truncates only when no `.remote.json` journal is retained. Covered by the
> "keeps its remote diagnostics" and "replayed once" regressions, and by the new
> receipt-cleanup case.

**Retry attempts that finish without required outputs**

> Fixed at `5115109`. Missing required outputs are reported before any transfer
> (`remote_session.jl:231-241, 526-533`), the zero-exit marker is kept, and the
> worker's new `replay` action lets the next run retrieve the same attempt
> instead of calling a `start`/`retry` that would refuse. The new patch also
> covers `_fetch_outputs`' own missing-output error.
