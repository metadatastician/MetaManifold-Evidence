<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->
# PR #68 close-out runbook — what is done, what is blocked, what you must do

Read on 2026-11-09. Scope: `JoshuaJewell/MetaManifold-WebUI#68`, "Make SSH
stages recoverable after local interruptions". Companion artifacts:
`notes/0004-pr68-ssh-recovery-coverage.patch` (the fix + regressions),
`notes/pr68-ssh-recovery-review.md` (full audit), and
`notes/pr68-parallel-ssh-and-hardening.md` (pssh / security assessment).

## 1. Conclusive current state

| item | state | evidence |
| --- | --- | --- |
| Evidence PR #13 | **MERGED** at `2026-11-09T10:50:24Z`, merge commit `d2d49aa9c8b838046fbdc228e50b45eb827bef37` | `gh pr view 13` |
| Evidence CI | all green, including the new `PR #68 handoff patch integrity` job | `gh pr checks 13 --watch` |
| Evidence review conversations | 0 unresolved; all 4 open CodeRabbit threads replied to and resolved | GraphQL re-query |
| Companion patch | `From f1bfa293f845cc0adb946d45f92ec30c6e7ab6aa`, 4 files, +306/−24; `git apply --check`, `git am`, `git diff --check` all clean against `5115109` | `scripts/check-pr68-handoff.sh` |
| WebUI PR #68 | **OPEN**, head `5115109be0ef475b35787011e515db134f4dd05f`, `mergeable=MERGEABLE`, `mergeStateStatus=CLEAN`, `reviewDecision=""` | `gh pr view 68` |
| WebUI PR #68 CI at that head | Agda proofs 44s, Julia tests 21m, REUSE compliance 9s, `codecov/patch` pass — run `42442911919` | `gh pr checks 68` |
| Codecov patch at that head | `94.59%`, 315/333 lines hit, 18 misses; **informational**, cannot fail a merge | Codecov v2 compare API |
| Three Codex review threads | **still unresolved**: `PRRT_kwDORbJW48606d5b`, `PRRT_kwDORbJW48606d5n`, `PRRT_kwDORbJW48606lKn` | GraphQL |
| The corrected fix on PR head | **NOT APPLIED** — push to fork head was refused | see §3 |
| Julia execution of the fix | **NEVER RUN** — no `julia`, `agda`, `R`, `bun` or `sshd` in this sandbox | local probes |

The evidence side is conclusively closed. **The WebUI PR is not.** Nothing in this
session can close it, because every write path returns the same 403.

## 2. The single blocker

The session's only GitHub credential is `GH_TOKEN` / `GITHUB_TOKEN` (identical,
24 characters, identity `hyperpolymath`). `GET /repos/...` reports
`admin/maintain/push/triage: true` on the fork and `pull: true` only on the base
repository, but the reported `push: true` on the fork is **not** an effective
grant: it is a GitHub App installation token with read-only contents permission.
There is no SSH key, no `.gitconfig`, no alternative token, and
`list_connector_tools github` returns `unsupported`.

Every write route was attempted on 2026-11-09 and refused:

| attempted operation | target | result |
| --- | --- | --- |
| `git push` via credential helper | `hyperpolymath/MetaManifold-WebUI:fix/66-resumable-ssh-stages` | `403 Permission ... denied to hyperpolymath` |
| `git push` with explicit `x-access-token` | same | `403 Permission ... denied to hyperpolymath` |
| `git push` with `http.extraheader=AUTHORIZATION: bearer …` | same | `403 Permission ... denied to hyperpolymath` |
| `POST /git/blobs` | fork | `403 Resource not accessible by integration` |
| `PATCH /git/refs/heads/fix/66-resumable-ssh-stages` | fork | `403 Resource not accessible by integration` |
| `addPullRequestReviewThreadReply` (GraphQL) | PR #68 thread `…d5b` | `FORBIDDEN: Resource not accessible by integration` |
| `resolveReviewThread` (GraphQL) | PR #68 thread `…d5b` | `FORBIDDEN: Resource not accessible by integration` |
| `POST /issues/68/comments` (REST) | base repo | `403 Resource not accessible by integration` |
| `gh pr merge 68 --merge` | base repo | `Resource not accessible by integration` |

Secondary verification blocker: the companion patch changes production Julia
code and has **only** been checked structurally (pygments token check: zero
bracket imbalance, zero block-depth delta in all four files). CI on the new PR
head is its first execution. Expect to iterate on small, local failures; the
likely first ones are a `withenv` do-block signature, a `JSON3.Object`
`haskey`/`get` detail, `cleanup` refusing a terminal attempt in the retirement
path, and an exact exception type reaching `@test_throws`.

Not blockers:

- The "Unverified" commit badges. They are signature status, not CI. All 11 PR
  commits are in the PR; `24f42ec8`, `f0992480`, `776952fe` are `valid`, the
  other eight are `unsigned`. `branches/main.protected` is `false`, so no
  signed-commit gate exists on the base repository.
- `codecov/patch` being green at 94.59% — it is `informational: true`.
- Branch protection / required checks — `GET /rules/branches/main` on the base
  repository returned no rules in this session.

## 3. Exactly what you must do (I cannot do any of it)

### Prerequisites

A credential with **all three** of these, e.g. your own `gh auth login` with a
classic `repo` token or a fine-grained token granted to both repositories:

1. `contents: write` on `hyperpolymath/MetaManifold-WebUI` (to push
   `fix/66-resumable-ssh-stages`).
2. `pull_requests: write` **and** `issues: write` on
   `JoshuaJewell/MetaManifold-WebUI` (to post replies and resolve threads).
3. Merge rights on `JoshuaJewell/MetaManifold-WebUI:main` (to merge PR #68).

If you prefer to fix this inside Arena, **reconnect GitHub in Arena** with a
credential that has those scopes, then start a new session; the current token
cannot be upgraded from here.

### One command, from a Linux machine with `git`, `gh`, and Julia 1.12.x

```bash
bash scripts/pr68-apply-and-close.sh --all
```

That script (in this repository) does, in order, and aborts on any failure:

1. Re-runs `scripts/check-pr68-handoff.sh` (SPDX, index, pinned SHA, real
   `git apply --check` + `git am`, exact four files, Julia structure delta).
2. Refuses to proceed unless PR #68 head is still exactly `5115109be0ef475b35787011e515db134f4dd05f`.
3. Clones the fork's `fix/66-resumable-ssh-stages`, applies
   `notes/0004-pr68-ssh-recovery-coverage.patch` with `git am`, runs
   `git diff --check`, and pushes the new commit.
4. Waits for `gh pr checks 68 --watch` and refuses to continue unless all four
   checks pass.
5. Posts the three draft replies (verbatim from
   `notes/pr68-ssh-recovery-review.md`) with
   `addPullRequestReviewThreadReply`, resolves the three threads with
   `resolveReviewThread`, verifies `isResolved` for all three, then runs
   `gh pr merge 68 --repo JoshuaJewell/MetaManifold-WebUI --merge`.
6. Prints a final `gh pr view 68 --json state,mergedAt,mergeCommit` as proof.

Use `--verify`, `--push`, or `--close` to run only one phase. `--verify` is
read-only and works with the current token.

### If you would rather do it by hand

```bash
# 1. Apply and push
git clone --depth 1 --branch fix/66-resumable-ssh-stages \
  https://github.com/hyperpolymath/MetaManifold-WebUI.git pr68
cd pr68
git am /path/to/MetaManifold-Evidence/notes/0004-pr68-ssh-recovery-coverage.patch
git push origin HEAD:refs/heads/fix/66-resumable-ssh-stages

# 2. Wait for green CI (Julia tests take ~21 minutes)
gh pr checks 68 --repo JoshuaJewell/MetaManifold-WebUI --watch --interval 20

# 3. Linux rerun of the specific regressions, if Julia is available locally
julia --project=. -t 2 test/runtests.jl test_remote_stages.jl test_phylogeny.jl
julia --project=. -t 2 test/remote_ssh.jl
bash proofs/tests/axiom-audit.sh

# 4. Resolve the three threads (GraphQL only; no REST equivalent)
for id in PRRT_kwDORbJW48606d5b PRRT_kwDORbJW48606d5n PRRT_kwDORbJW48606lKn; do
  gh api graphql -F query="mutation { resolveReviewThread(input: {threadId: \"$id\"}) { thread { id isResolved } } }"
done

# 5. Merge
gh pr merge 68 --repo JoshuaJewell/MetaManifold-WebUI --merge
```

`test/unit/remote_protocol_tests.jl` is included by
`test/unit/test_remote_stages.jl` under `if Sys.islinux()`; the recovery
regressions use `flock`/`setsid`, so **step 3 must be run on Linux**.

### Definition of done — verify with these commands

```bash
gh pr view 68 --repo JoshuaJewell/MetaManifold-WebUI \
  --json state,mergedAt,mergeCommit,headRefOid
# expect state=MERGED, headRefOid != 5115109... (the patch commit)

gh api graphql -F query='query { repository(owner:"JoshuaJewell",name:"MetaManifold-WebUI") {
  pullRequest(number:68) { reviewThreads(first:100) {
    nodes { isResolved } } } } }' \
  --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false)] | length'
# expect 0

gh pr checks 68 --repo JoshuaJewell/MetaManifold-WebUI
# expect every line "pass" on the NEW head
```

### Optional follow-ups (not blockers, explicitly out of scope for #68)

- P0 hardening from `notes/pr68-parallel-ssh-and-hardening.md`: host-key
  pinning, `Base.addenv(cmd, "LC_ALL"=>"C", "LANG"=>"C")` to fix the still-open
  locale-protocol regression from `3cf7c82`, and a `_capture` timeout so a hung
  SSH call cannot hold the journal owner lock. Each needs its own PR, proof and
  loopback-SSH regression.
- `pssh` is **not** a drop-in for this one-attempt/`ControlMaster`/`active ≤ 1`
  protocol. Stage-level concurrency and bounded parallel `scp` over the
  existing master fit without a protocol change.
- Commit signing: `git config commit.gpgsign true` with a registered key, then
  enable `required_signatures` once history is consistent. Do **not** rewrite
  this PR's history just to add signatures.

## 4. What "conclusively closed" means here

- **Closed:** the evidence work, PR #13 (merged), all 5 CodeRabbit review
  comments on it, the strict CI/CD gate, the pssh/security assessment, the
  commit-signature question, and the identification + fix of the fundamental
  `replay` flaw.
- **Not closed, and impossible from this session:** applying the fix to PR #68's
  head, re-running WebUI CI on it, resolving its three conversations, and
  merging it. These are blocked solely by credential scope, not by missing
  code, missing tests, a failing check, an unresolved review decision, or
  branch protection. Once you run `scripts/pr68-apply-and-close.sh --all` with
  a write-capable credential, there is no known remaining technical obstacle.
