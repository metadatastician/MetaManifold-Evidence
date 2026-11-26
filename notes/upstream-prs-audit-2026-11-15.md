Unposted draft.
Recovered from the session transcript; the file was lost from disk on 2026-11-19. Branch facts as of 2026-11-15 only; see pr70-audit-answer-2026-11-21.md for what changed after.

# Audit of the five open upstream PRs (JoshuaJewell/MetaManifold-WebUI 68 to 72)

Made on 15 Nov 2026 by the PR 70 session. Read-only. Use it as the brief for a
new session that has `JoshuaJewell/MetaManifold-WebUI` attached and can edit PR
descriptions. Every fact below was checked at the head commits named; recheck
the head before editing, because a push changes them.

## Ground truth per PR

| PR | Fork branch | Head | Commits | Behind main | Merge commits | Every commit Verified on GitHub | Licence, citation, acknowledgement files changed |
|---|---|---|---|---|---|---|---|
| 68 | `fix/66-resumable-ssh-stages` | `85ea5a1` | 12 | 0 | 0 | yes (all 12) | no |
| 69 | `codex/issue-65-descriptive-statistics` | `c198b8b` | 15 | 0 | 0 | yes (all 15) | no |
| 70 | `validation/issue-23-native-da` | `dbb15c3` | 1 | 0 | 0 | yes | no |
| 71 | `upstream/issue-22-mglm` | `37c9ffa` | 1 | 0 | 0 | yes | no |
| 72 | `feature/high-precision-diversity` | `6e59bd5` | 16 | 0 | 0 | yes (all 16) | no |

Checked with: `git rev-list --count <head>..upstream/main` (behind), `git rev-list
--merges upstream/main..<head>` (merges), merge base equal to the tip of
upstream main (all five: yes), the GitHub commit API `verification` field
(all `verified: true, reason: valid`), and `git diff upstream/main...<head> --
LICENSE LICENSES CITATION.cff` plus README licence/acknowledgement lines (none).

Upstream main at the time: `89be534`.

## Points that affect the boxes

1. **Signed and Verified: true, but by whose key?** Every commit on all five PRs
   has committer `CLAUDE <355856132+HoTT-stuff@users.noreply.github.com>`, and
   GitHub verifies the signature against that account's key. CONTRIBUTING rule 3
   says "signed with a GPG, SSH or S/MIME key registered to your account". The box
   "Every commit is signed and shows as Verified" is literally true. Whether it
   meets rule 3 depends on whether the HoTT-stuff account counts as the
   contributor's own account. **Owner ruling, 15 Nov: it does not count.** Before
   each PR is marked ready, the owner re-signs its commits with his own key (the
   method is `notes/pr70-sign.md` in MetaManifold-Evidence, with the branch name
   changed). Do not tick the signing box on any PR until that is done and every
   commit shows Verified with hyperpolymath as committer.
2. **PR 72 contains all 15 commits of PR 69.** It is stacked on 69. Its
   description must say it depends on #69 and that 69 merges first. Otherwise
   it reads as one PR carrying two logical changes (rule 4). Its 5 uncovered
   lines are 69's lines (below).
3. **CI.** Each PR shows a passing `Julia tests` run (or Agda for 71) on the
   checks page, but the page did not show every job's conclusion from here.
   Tick "CI has run and passes" only after reading every job (Julia tests, Agda
   proofs, REUSE compliance, codecov/patch) on the current head.
4. **PR 70** will be replaced by the ALDEx2-only rebuild (owner's decision)
   after CompositionalDA is in General. Its body is then replaced by
   `notes/pr70-aldex2-rebuild-description.md` in MetaManifold-Evidence. Until
   then, its checklist should say it is a draft waiting on registration.
5. **Each box must be true when ticked.** Fix the cause, then tick. Do not tick
   to match a hope.

## Coverage (Codecov API, compare per PR)

| PR | Patch coverage | Uncovered patch lines |
|---|---|---|
| 68 | 100% | none |
| 69 | 99.52% | 5 (below) |
| 70 | 100% | none |
| 71 | 98.96% | 1: `src/analysis/differential.jl:1236` |
| 72 | 99.57% | the same 5 as 69 (inherited) |

PR 69 (and so 72):

- `src/server/routes/validated_statistics.jl:226-227` (229-230 on 72): the
  `catch` that rewraps a failure inside `_body_filter_params` as "invalid
  filter parameters". No test sends filters that pass normalisation and then
  make `_body_filter_params` throw.
- `src/server/routes/validated_statistics.jl:286` (296 on 72): an **integer**
  `time_limit_seconds` (for example 30). Tests send only floats or wrong types.
- `src/canonical.jl:220`: the `else` branch when `repr(x)` has no `.`. For a
  finite `Float64`, `repr` always has a `.` ("1.0", "1.5e-10"), so this branch
  is reachable only for `Inf`/`NaN`. If those are refused earlier, it is dead
  code to remove, not to test. Verify before choosing.
- `src/analysis/derived_analyses.jl:127`: the race path where `hardlink` fails
  because a concurrent publisher already wrote the same record, and
  `_existing(final, id)` checks it. Creating the final file before publishing does
  not reach it: `persist_derived_analysis` returns at the `isfile(final)` check
  before `hardlink`. The race test needs the destination to appear after that
  check and before `hardlink` runs. Keep the pre-existing-file case as a
  separate test.

PR 71: `differential.jl:1236` is the branch where MGLM returns no refusal
reason but a missing or non-positive standard error, estimate or p-value. It
needs a case or a narrow seam around `fit_mglm` (no skip).

Not a problem, nothing to fix:
- `src/server/routes/duckdb_helpers.jl` 83.49% to 89.20% (+5.71) is a gain.
- `src/server/server.jl` 70.68% is unchanged and not in any diff. Its "-" means
  no patch lines, not a fault.

Owners: the coverage fixes for 69, 71 and 72 were handed to the MetaManifold
#22 thread (session_0136P7ZpWuto1gvzJmE9snCY).
