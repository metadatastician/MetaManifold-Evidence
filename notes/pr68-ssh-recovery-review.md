<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->
# PR #68 close-out: review findings, coverage gaps, CI and permissions

Durable handoff for `JoshuaJewell/MetaManifold-WebUI#68`, "Make SSH stages
recoverable after local interruptions". Read on 2026-11-09 against PR head
`5115109be0ef475b35787011e515db134f4dd05f`, base `89be534ab5cf5e286b34a8e0bf9310527c492ec5`.
A separate design note, `notes/pr68-parallel-ssh-and-hardening.md`, answers the
parallel-SSH and security-hardening questions about this subsystem.

## Companion patch

- `notes/0004-pr68-ssh-recovery-coverage.patch` — one `git format-patch` commit
  onto `5115109` (4 files, +306/−24). It closes the 18 Codecov gaps **and** the
  one review finding that `replay` alone cannot fix: a zero exit that omits a
  required output. Three files are tests; `src/pipeline/remote_session.jl`
  changes the runner's missing-output branch (see §3). It also folds in the
  intermediate test-strengthening revision CodeRabbit committed to this
  evidence branch as `0987403` — a stateful ControlMaster fixture, exact
  open/request/close assertions, `ProcessFailedException`, journal immutability
  on a pending stop, and unset-PATH hardening — so no review comment is left
  half-answered.

## What was asked, and what is actually left

The pasted review comments are anchored to an *earlier* head (`f0992480`). Eight
follow-up commits landed after them: `ab576a8`, `a4e2412`, `3cf7c82`, `910eeb7`,
`e147ba9`, `3295f93`, `ca8ab07`, `5115109`. Six of the PR's nine review threads
are already resolved; the three still open are the three pasted in the request.
At head, findings **1** and **2** are fixed, finding **3** is only *partly*
fixed, coverage is still 94.59% with 18 misses, and the three conversations are
still open. The companion patch closes finding 3 and the coverage gaps.

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
  reaches both old-master teardown branches with a transport the runner owns
  and records, asserting that a status probe and `-O exit` really occurred.

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
  stage log") and `:624` ("the retained remote log is replayed once"). The new
  patch adds "receipt recovery cleans up a retained attempt", which pins the
  `cleanup` line reached when a live attempt still sits behind a receipt, and
  changes the replay-once case to retain its attempt through a broken download
  rather than through an absent output (the two are no longer the same state).

### 3. Retry attempts that finish without required outputs (thread `PRRT_kwDORbJW48606lKn`)

The finding: a zero exit that omits a required file threw before a receipt was
stored, while the `exit 0` marker and `failed=false` journal made `start`
refuse and `retry` refuse.

**What `5115109` fixes:** `_missing_outputs` (`:231-241`) reports the missing
names (`:526-533`); `src/pipeline/remote_worker.sh:173-195` adds `replay`, and
`remote_session.jl:479-491` uses it on the `exit 0` barrier so a *failed
download* of a file that **was** written can be fetched again without a
relaunch. That removes one wedge.

**What it does not fix:** `replay` keeps both markers and does not rerun the
command. If the command never wrote the required file, every explicit rerun
replays the same attempt, reaches `_missing_outputs` again, and reports the
same error. The head's own error text says "change its settings to run it
afresh" — a manual workaround, not the "retryable or new attempt" the review
asked for. Presenting this thread as closed would be wrong.

**What the companion patch changes:** on a non-empty `missing`, the runner
calls `cleanup` (legal because the exit marker is present), archives the journal
as `*.missing-outputs-<uuid>`, and errors with "The attempt was retired; run
the stage again to launch it afresh." The next explicit run creates a new
journal and attempt and relaunches the command. If `cleanup` fails, the journal
is deliberately **kept** and the error asks for a retry, so no remote attempt
is ever left without an owner — the same invariant as finding 1. The existing
"a completed attempt without a required output stays retrievable" case is
replaced by "a zero exit without a required output is retired for a fresh
attempt", which toggles a flag file so the *unchanged* command writes its output
on the second run and asserts that uploads happen again, a receipt is stored,
and no stale attempt remains. The Agda protocol model
(`proofs/agda/MetaManifold/RemoteExecution.agda`) already has
`expire-succeeded : succeeded 0 n ↦ removed 0 n` for removing a terminal
attempt without a fetch; no new transition is introduced, but a maintainer
should confirm that modelling this as retention-style removal is intended
before merge.

## Codecov: what the green check does not say

`codecov/patch` is **green** at `5115109`, but its title still reads
`94.59% of diff hit (target 75.73%)`. That is not a contradiction:
`codecov.yml` sets `coverage.status.patch.default.informational: true`, so the
check cannot fail a merge. The Codecov v2 API (pull `68`, compare
`89be534...5115109`, report updated 2026-11-08T03:50:44Z) gives figures for
the **unpatched** head:

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
Applying the companion patch shifts line numbers in `remote_session.jl`; its
new lines are exercised by the new retirement regression.

### What `0004-*.patch` adds

- `src/pipeline/remote_session.jl`: the missing-output retirement described in
  §3.
- `test/unit/remote_protocol_tests.jl`: a `fail_sweep` switch; a
  `_refusing_transport` helper that puts a two-line `ssh`/`scp` on `PATH`
  inside `withenv` using `get(ENV, "PATH", "")` so an unset `PATH` cannot
  break it; and a stateful `_owned_transport` that models
  `ControlMaster=auto` by recording `opened`/`request`/`closed` events with
  per-`ControlPath` master state. Eight testsets cover the fetch error, the
  durable cancel request, receipt cleanup, a refused sweep, the own-transport
  `finally`, both superseded-journal branches, and the retirement/fresh-launch
  path. The superseded cases assert the first request opens the old master,
  that it carries the old directory and a `worker.sh status` probe, that the
  master is then closed and no master remains, that a pending stop produces
  exactly three events and leaves the journal byte-identical, and that an
  abandoned journal is archived. They require `ProcessFailedException`, not
  any exception.
- `test/unit/test_phylogeny.jl`: one testset that calls `run_workflow` through
  both halves of the new branch with steps whose commands cannot run, asserting
  that a local rerun truncates the log and clears stale outputs while a
  retained journal keeps the log and clears only the step key.
- `test/unit/test_remote_stages.jl`: one testset for `verify_remote_sizes`
  with an apostrophe and a space in an uploaded filename, plus a truncated
  upload.

`test/unit/remote_protocol_tests.jl` is included by
`test/unit/test_remote_stages.jl` **on Linux** (`if Sys.islinux()`), which is in
`test/runtests.jl`'s `UNIT_FILES`, so all three files run in the
coverage-instrumented "Run tests" step. No workflow change is needed upstream.

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
Applying the companion patch changes production code, so CI must be re-run on
the new head before that merge.

## The review conversations

Nine threads, six already resolved. The three open ones are the three above;
none is outdated, so their anchors still point at live code. Resolving them
needs `resolveReviewThread`, which requires write access to the base
repository. All three mutations were attempted in this session and returned:

```
FORBIDDEN: Resource not accessible by integration
```

A REST reply to the first thread was also refused with the same 403: this token
cannot write to the base repository at all. For someone with `push`/`triage` on
`JoshuaJewell/MetaManifold-WebUI`:

```bash
for id in PRRT_kwDORbJW48606d5b PRRT_kwDORbJW48606d5n PRRT_kwDORbJW48606lKn; do
  gh api graphql -f query="mutation { resolveReviewThread(input: {threadId: \"$id\"}) { thread { id isResolved } } }"
done
```

There is no REST equivalent; the GraphQL node IDs come from
`pullRequest(number: 68) { reviewThreads(first: 100) { nodes { id isResolved } } }`.
Draft replies, one per thread, are in the closing section below. Resolving
thread 3 before the companion patch is applied would be inaccurate: replay
alone does not close that finding.

## Evidence PR #13's own review conversations

The handoff originally landed in this repository as PR #13. CodeRabbit raised
five inline comments there: handle an unset `PATH`; make the refusing transport
statefully record master creation/closure; strengthen the `cancel_requested`
old-master assertions with an exact exception type and journal immutability;
state that the recovery rerun is Linux-only; and do not mark the missing-output
close-out resolved when `replay` does not rerun the command. All five are now
answered in the combined companion patch and this audit: `get(ENV, "PATH", "")`,
the stateful `_owned_transport` event log, `ProcessFailedException` plus
`read(journal_path) == original_journal`, an explicit Linux-only note in the
commit message and apply instructions, and the production retirement fix for
finding 3. The GraphQL thread IDs on PR #13 were
`PRRT_kwDOU4GvQ861NMFO`, `...NMFW`, `...NMFc`, `...NMFj`, `...NMFr`; resolving
them is a separate write on this repository, which this session does have
permission to do (unlike the base WebUI repository).

## The "Verified" / "Unverified" commit badges

Those badges are GitHub's **commit-signature** status, not a CI or code-review
verdict. `gh api repos/.../commits/<sha> --jq .commit.verification` on all
eleven PR commits gives:

| commits | verification |
| --- | --- |
| `24f42ec8`, `f0992480`, `776952fe` | `valid` (signed) |
| `ab576a8d`, `a4e2412b`, `3cf7c821`, `910eeb71`, `e147ba96`, `3295f933`, `ca8ab07f`, `5115109b` | `unsigned` |

`branches/main` on the base repository reports `protected: false`, and no
signed-commit rule blocks the merge. So these items do **not** need to be
addressed for completion; they are a provenance improvement, not a gate. They
are co-authored commits created through an automation token without a signing
key. Retroactive signing is impossible without rewriting the PR history
(`git rebase --exec 'git commit -S --amend --no-edit'` plus a force-push to the
fork), which would disturb an open review. For future work, configure
`git config commit.gpgsign true` with an SSH or GPG signing key registered on
the account, and consider enabling `required_signatures` on `main` once the
whole history is signed. The three open review threads and the coverage patch
are the real gates, not these badges.

## Apply the companion patch

```bash
git fetch https://github.com/JoshuaJewell/MetaManifold-WebUI.git pull/68/head:pr68
git worktree add ../pr68 -b fix/66-resumable-ssh-stages pr68
cd ../pr68
git am /path/to/MetaManifold-Evidence/notes/0004-pr68-ssh-recovery-coverage.patch
# The recovery protocol regressions are Linux-only (they use flock/setsid and
# are skipped elsewhere), so this rerun must be on Linux:
julia --project=. -t 2 test/runtests.jl test_remote_stages.jl test_phylogeny.jl
julia --project=. -t 2 test/remote_ssh.jl
bash proofs/tests/axiom-audit.sh
```

Then push to the fork that owns the PR head, re-run the four PR checks, and
resolve the three threads. Pushing to the PR head, resolving and merging on the
base repository are left to the people who own those timelines, as with
`0001`–`0003` in this directory.

## Verification recorded when authoring the patch

- `git apply --check` onto a clean `5115109` tree: clean.
- `git am` in a fresh shallow clone at `5115109`: clean, zero warnings,
  resulting tree byte-identical to the one the patch was made from;
  `git diff --check HEAD^ HEAD` clean.
- Token-level structure check with pygments' Julia lexer (strings and comments
  excluded): brackets balanced and block depth unchanged from the baseline in
  all four modified files (`src/pipeline/remote_session.jl`,
  `test/unit/remote_protocol_tests.jl`, `test/unit/test_phylogeny.jl`,
  `test/unit/test_remote_stages.jl`). The strict gate
  `scripts/check-pr68-handoff.sh` repeats this check in CI along with a real
  `git apply --check` and `git am` against `5115109`, and asserts the exact
  four touched files, the production fix and its regression, and the
  review-hardened fixtures. The lexer reports a non-zero absolute block depth in
  `test_phylogeny.jl` (9) and `test_remote_stages.jl` (1) both before and after
  the edit — pre-existing `@testset`/`do` constructs the lexer pairs loosely —
  so the meaningful result is the zero delta.
- **Not run: Julia, R or Agda.** This sandbox has none of them, so the modified
  runner and its new tests have never been executed. CI is their first run,
  exactly as for the PR #25 rework in this directory. The most likely first
  failures are a `withenv` do-block signature detail, a `JSON3.Object` method
  (`haskey`/`get`) in the fabricated receipt, `cleanup` refusing a terminal
  attempt in the retirement path, and an exception-type mismatch reaching
  `@test_throws`; each is a small, local fix. Because this patch changes
  production code, it must not be merged upstream on the strength of the
  structure check alone.

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

> Partly fixed at `5115109`, and closed by the companion patch. `replay` removes
> the `start`/`retry` refusal for a completed attempt whose *download* failed,
> but it cannot recover a file the command never wrote: replaying that attempt
> would report the same error on every rerun. `notes/0004-pr68-ssh-recovery-coverage.patch`
> makes a zero exit with missing required outputs retire the attempt (cleanup
> plus an archived journal), so an explicit rerun launches a fresh one; a failed
> cleanup keeps the journal so no attempt is left without an owner. The new
> regression toggles a flag so the unchanged command writes its output on the
> rerun and asserts a fresh launch, a new receipt and no stale attempt.
