# Requests from the maintainer

Each row is 1 request from Joshua, in his order. Detail and evidence:
`notes/upstream-audit-2026-11-21.md`, section 3.

## Rules for this file

- Use only the 4 states: drafted, handed over, done, done and checked.
- "Done and checked" needs the live head SHA and the date of the check. Write
  both in the row. A row without them is at most "done".
- A change on a branch that is not the pull request head is "drafted".
- A session that cannot read the pull request head does not change a state.

Last check of the heads: 27 Nov 2026, by git fetch of `refs/pull/*/head`.
68 `85ea5a1`, 69 `7d016aa`, 70 `647f8ba`, 71 `74db99d`, 72 `6df7e76`.
No head changed after the audit of 21 Nov.

## PR 68 (his comment of 12 Nov)

| # | Request | State | Open point |
| --- | --- | --- | --- |
| a | Sign every commit | done | Committer is HoTT-stuff, not the contributor. Head `85ea5a1` has a `Co-authored-by: Claude` trailer. R-3: HoTT-stuff is the signer. R-5: every Co-Authored-By trailer must go. That is the Claude trailer on `85ea5a1` and the `arena-agent` trailer on the other 8 commits checked, so all 9 need a reword. |
| b | Reword `78a6c7b`, no fork PR numbers | done and checked, `85ea5a1`, 21 Nov | none |
| c | CI passes on the new SHAs | done and checked, `85ea5a1`, 21 Nov | The description cites `776952f`, which is not in the branch. |

## PR 69 (his comment of 12 Nov)

| # | Request | State | Open point |
| --- | --- | --- | --- |
| 1 | No Python; committed fixtures | done | Description and `issue-65-review.md` still say Python and Decimal. |
| 2 | Drop the Actions upgrades | drafted | 45 lines in `ci.yml`, with `actions/upload-artifact`. |
| 3 | Remove unimplemented methods | done and checked, `7d016aa`, 21 Nov | none |
| 4 | High-precision diversity: develop or keep out | drafted | It came back as PR 72. |
| 5 | Name a reviewer; fill the review form | drafted | `method_catalogue.jl` line 118 accepts only `pending_review`. He has not named a reviewer. |
| 6 | Sign; no fork PR numbers | drafted | `7d016aa` committer is `Claude <noreply@anthropic.com>`. |
| 7 | Issue for the local test failure | drafted | The reply withdraws it. `issue-65-review.md` says "unexplained". |

## PR 70 (his comment of 12 Nov)

| # | Request | State | Open point |
| --- | --- | --- | --- |
| 1 | Register in General; `[deps]`, `[compat]`, Manifest; no optional loading | drafted | Only on fork branch `rebuild/pr70-native-da` `7bd131b` (R-4), without the Manifest. Registry PR 175952 blocked. `647f8ba` makes optional loading stronger. |
| 2 | R comparison; fixtures; tolerance, seed and spread | drafted | Only on `7bd131b`. The ANCOM-BC FDR calibration is open (R-4 puts it in scope). |
| 3 | No merge commit | done and checked, `647f8ba`, 21 Nov | none |
| 4 | Sign every commit | drafted | `647f8ba` committer is `Claude <noreply@anthropic.com>`. |
| 5 | Messages describe the change | drafted | `647f8ba` body says "Addresses the four review findings". |
| 6 | Fill in the description | drafted | 3 sections empty. |

## Issues and PRs 71, 72

| Item | State | Open point |
| --- | --- | --- |
| Issue 23: his yes for native DA | drafted | No answer. CONTRIBUTING says "Statistics: R through RCall". |
| PR 71 and PR 72 to draft; close issue 73 | handed over | Owner ruling R-6. No session can write to his repository. |
