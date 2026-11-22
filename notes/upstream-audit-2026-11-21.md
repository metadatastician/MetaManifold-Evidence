# MetaManifold-WebUI: audit of the work sent to JoshuaJewell

Date: 2026-11-21. Auditor: a fresh session with no earlier knowledge of this work.
Scope: the 5 open pull requests on `JoshuaJewell/MetaManifold-WebUI` (68, 69, 70, 71, 72), the open issues (23, 65, 66, 73), and the staged rebuild branch for pull request 70.
Framework: Joshua's own `CONTRIBUTING.md` on `main` (`89be534`), plus each request he wrote. His file says: "Each requirement is checked before the code is read" and a pull request that misses a requirement is "closed without review".

## 1. Verdict

No pull request is ready. Each of the 5 has at least one defect that Joshua's own checklist finds before he reads the code.

| PR | Verdict | First thing his check finds |
|---|---|---|
| 68 | Closest. Not clean. | Description cites CI on a commit that is not in the branch. |
| 69 | Blocked. | The code forces the status `pending_review`. He said he will not merge that. Docs contradict the reply. |
| 70 | Wrong direction. | His item 1 is not done, and the newest commit makes the optional loading stronger. Marked ready after a promise to keep it as a draft. |
| 71 | Sent before the answer. | Issue 22 is closed as "not planned". The pull request was opened one day before the comment that asked if he wants it. |
| 72 | Fails rule 2. | Contains a merge commit. Also contains all of pull request 69. |

## 2. Method and limits

- Read: every commit of the 5 pull request heads (local git), his `CONTRIBUTING.md`, the conversation pages, the checks pages, and the General registry pull request.
- Not possible here: the GitHub API for his repository is blocked. I read his comments as HTML through a fetch tool that paraphrases. The item lists below are complete, but the wording is not his exact wording.
- Not visible: the Verified badge on each commit, the text of the resolved Codex review threads, and the tick state of the description check boxes.
- Not run: the Julia and R test suites. This container has no Julia and no R. CI on his repository shows "Success" for all 5 current heads.

## 3. What Joshua asked, item by item

### PR 68 (his comment of 12 Nov)

| # | Request | State | Evidence |
|---|---|---|---|
| a | Sign every commit | Done locally. Badge not confirmed. | All 12 commits carry an SSH signature. Committer is `CLAUDE <HoTT-stuff>`. |
| b | Reword `78a6c7b`, no fork PR numbers | Done | Head `85ea5a1` has no `#323`. |
| c | CI must pass on the new SHAs | Done | Run 43284676276, Success, on `85ea5a1`. |

Defects he did not list but his rules cover:

1. The description says CI passed on `776952f`. That commit is not in the branch. The correct run is 43284676276 on `85ea5a1`.
2. The description says local bun 1.4.3. The pin is 1.3.10.
3. Rule 8 says every commit must pass the tests. Three commit subjects say the opposite: "Fix the recovery regressions CI exposed", "Point the last two protocol cases at reachable states", "Unwrap the task failure when asserting the cancelled stage's error".
4. Commit `7905f00` says "Address the unresolved review threads on #68". A commit message must describe the change, not the review.
5. The "Agents" rule: the contributor who submits the pull request commits and signs it. The committer on all 12 commits is a second account (`HoTT-stuff`, shown as "CLAUDE"), not `hyperpolymath`.

### PR 69 (his comment of 12 Nov, 7 items)

| # | Request | State | Evidence |
|---|---|---|---|
| 1 | No Python. Use committed fixtures. | Done in the tree. Not in the text. | No `python3` call remains. The PR description still says "Independent Python Fraction/Decimal checks". `issue-65-review.md` line 41 still says the metrics were compared "against Decimal references". |
| 2 | Drop the Actions upgrades | Partly | The version bumps are gone. The pull request still adds 45 lines to `ci.yml`, with a new `actions/upload-artifact` step. That action is on his list. `main` does not use it. |
| 3 | Remove unimplemented methods from the catalogue | Done | Only `exact-descriptive-summaries` remains. |
| 4 | High-precision diversity: develop the existing one, or keep it out | Half | It is out of 69. It came back the same day as pull request 72. See section 4. |
| 5 | Name a scientific reviewer, fill the review form. He will not merge "unreviewed" metadata. | Not done. Blocked in code. | `src/analysis/method_catalogue.jl` line 118 rejects every catalogue status except `pending_review`. The form is empty. The reply asked him who reviews. No answer yet. |
| 6 | Sign all commits. No fork PR numbers. | Partly | No fork numbers remain. Commit `7d016aa` (17 Nov) has the committer `Claude <noreply@anthropic.com>`. GitHub shows it as committed by the account `claude`. This is very probably "Unverified". |
| 7 | Open an issue for the local test failure | Withdrawn in the reply. Contradicted in the pull request. | The reply says 363 of 363 pass and withdraws the failure. `issue-65-review.md` in the same pull request still says the failure "reproduced on untouched upstream `89be534`" and "its cause remains unexplained". |

More defects:

1. The reply said "the loader refuses any status other than supported". That is true for a method. The catalogue itself must be `pending_review`. The reply did not say this.
2. `issue-65-review.md` names commits that are not in the pull request: `ec6d5a8`, `419f2fb`. It cites a CI run that expires on 7 Dec 2026. It names fork PR 260. It says the run "included a high-precision diversity layer".
3. The title still says "and independent pipeline evidence". The independent check was the Python part. It is gone.
4. The description lists fixes by SHA (`d1c955b`, `28f0f39`, `1b45afd`, `ce88ead`, `a1076ec`). None is in the branch.
5. The history adds Python and high-precision code, then removes both (`57bb2fd`, `c198b8b`). On pull request 70 he asked for this kind of commit to be squashed. The same principle applies here.
6. Commit `bce18cc` "Correct three test expectations" shows that earlier commits fail the tests (rule 8).
7. On 13 Nov a comment asked him: add coverage tests now, later, or not at all? On 17 Nov the commit `7d016aa` was pushed with no answer from him.
8. Size: 42 files, 5568 lines, with review forms, a data-use record, a mutation script and a bench script. On pull request 63 he wrote that such a change was "much more than I want to maintain". Expect the same answer.

### PR 70 (his comment of 12 Nov, 6 items)

| # | Request | State | Evidence |
|---|---|---|---|
| 1 | Register CompositionalDA in General. Declare it in `[deps]` and `[compat]`. Regenerate `Manifest.toml`. Remove optional loading and the stand-in. | Not done. Made worse. | Registry PR 175952 is still open and is blocked by a reviewer comment (15 Nov). Commit `647f8ba` (17 Nov) rebuilds the optional loading with `Base.identify_package` and `Base.require`. `Project.toml` has a comment that explains why the package is absent. `test/support/native_da_stub.jl` (170 lines) is still there. |
| 2 | Compare with the R packages. Commit fixtures. Justify tolerances. State seed and spread. | Not done on the PR | No fixture in the pull request. |
| 3 | No merge commit | Done | 2 linear commits. |
| 4 | Sign every commit | Partly | `dbb15c3` is signed by `HoTT-stuff`. `647f8ba` has the committer `Claude <noreply@anthropic.com>`. |
| 5 | Commit messages describe the change here | Partly | `647f8ba` starts with "Addresses the four review findings". |
| 6 | Fill in the description | Not done | "Change and reason", "Validation" and "Scope" are empty. |

More defects:

1. The reply of 13 Nov said: "please treat the PR as not ready; I will mark it as a draft". It was marked as a draft that day. On 15 Nov it was marked ready again. Items 1, 2 and 6 were still open. It is ready now.
2. `docs/guide/web-interface.md` tells the user to install the package with `Pkg.develop(path=...)`. His full rule on issue 23 is "No URL-pinned dependencies: anything added must be registered and pinnable in Manifest.toml." A local path is not a URL pin, but it installs a package that is not registered and cannot be pinned in `Manifest.toml`. That breaks the second half of his rule.
3. The check box "CI has run and passes" counts tests that skip the real estimators. He said CI must run the real estimators.
4. The reply of 13 Nov has a numbering error. It says "Item 3 is not done" for the R comparison (his item 2) and "Item 7 (the description)". He wrote 6 items.
5. The registry reviewer found that the package README says "v0.3 development", that its launch document says registration is on hold, and that the ANCOM-BC calibration is a release blocker. The registration cannot merge until the package repository is corrected and the registration is started again.
6. `647f8ba` was pushed against the staged plan for this branch (standing rule SR-012).

### Issues

| Issue | State | Defect |
|---|---|---|
| 23 | Open. His only answer: no URL-pinned dependencies. | The question "does MetaManifold want native ALDEx2 and ANCOM-BC" has no answer. `CONTRIBUTING.md` requires agreement in an issue first for a package the contributor maintains. Pull request 70 has no agreement. |
| 22 | Closed by him as "not planned" on 7 Nov. | Pull request 71 was opened on 12 Nov. The comment of 13 Nov said a pull request comes only if he says yes. |
| 73 | Open. Title is "issue 22". | The body contains unfilled template text: "[OWNER: name the person who answers for every line, as CONTRIBUTING asks, then delete this bracket.]" It duplicates the comment on issue 22. It says the work is "for my own learning" and a base for Phred and Tree of Life work. His scope rule sends that kind of feature to a fork. |
| 65 | Open, no comment from him. | The 5 acceptance items are all open. |
| 66 | Open, his own bug report. | Pull request 68 closes it. No defect found in the issue. |

## 4. Pull requests he has not commented on yet

### PR 71 (MGLM)

1. Opened without his answer. See issues 22 and 73 above.
2. Commit `74db99d` has the committer `Claude <noreply@anthropic.com>`.
3. The description has empty headings ("Change and reason", "Validation", "Scope") below the text.
4. The text was posted 3 times: issue 22 comment, issue 73, pull request 71.
5. It edits 2 lines of `README.md` and keeps the words "ANCOM-BC is not included". Pull request 70 adds ANCOM-BC. The 2 pull requests conflict on that line.
6. The lockfile change is needed (MGLM 0.2.3). Rule 7 wants the reason in the description. The reason is there. This item passes.

### PR 72 (high-precision diversity)

1. Rule 2: commit `6df7e76` is a merge commit. This alone closes the pull request without review.
2. Rule 4: 18 commits, 16 of them belong to pull request 69. It is not one logical change.
3. His item 4 on pull request 69 gave 2 choices: develop the existing alpha diversity with justification, or keep it out. This pull request does neither. It adds a second Shannon and Gini-Simpson path.
4. The description gives the reason: a base for Phred quality arithmetic and complexity work. His scope rule: "Features that serve another project's research ... belong in a fork".
5. The description says the tests agree with `bc` to 457 digits. The test file has no `bc` call, so there is no external tool at run time. Say this clearly, because his first question will be "is this another unpinned oracle".
6. 3 commits have the committer `Claude <noreply@anthropic.com>`.
7. No issue agreed this feature.

## 5. Defects that repeat across all 5

1. Committer identity. 4 distinct commits pushed on 17 Nov have the committer `Claude <noreply@anthropic.com>`: `7d016aa` (69 and 72), `6df7e76` (72), `647f8ba` (70), `74db99d` (71). Each one came after a reply that told him all commits are signed and Verified.
2. Model names in commit messages. Trailers such as "Co-Authored-By: Claude Opus 5.5" and "Claude Fable 5.2", plus `Claude-Session:` links, are in 69, 70, 71 and 72. The estate rule SR-008 forbids model names in commit messages. `arena-agent` is a co-author on 68 and 69.
3. Stale descriptions. 68, 69 and 70 describe an earlier state of the branch.
4. Cross-reference noise. Fork pull requests named "(upstream PR 68)" and commits in `metadatastician/MetaManifold-Evidence` appear on his timelines. One public entry names "an owner-only signing step". He asked for no fork references. The commit messages are clean, but the fork PR titles still put the references on his page.
5. Bot noise. The Codex connector posted a "usage limit reached" comment on every push. Pull request 68 has 11 of them. Every Codex review on the current heads has the result "Failed". No review ran on the commits he will read.
6. Statements made before the fact. "I will mark it as a draft" (then ready). "Will open a PR if yes" (already open). "Every commit is now signed" (then unsigned-identity commits). This pattern is what his reviewers detect.

## 6. The staged rebuild for PR 70 (`52135fc`, not sent)

It is better than the pull request, but it is not ready either.

1. It drops ANCOM-BC. The pull request title, issue 23 and his item 2 all name ANCOM-BC. He must be told, and the title must change.
2. `Manifest.toml` is not regenerated. Commit `d98795b` cannot build. This waits for the registration, which is blocked (section 3, PR 70, defect 5).
3. `generate_reference.jl` uses the Bioconductor package ALDEx2. ALDEx2 is not in `renv.lock`. His rule: every R package used is pinned in `renv.lock`. Decide: pin it, or keep the generator out of the repository and commit only the fixtures with their recorded versions.
4. The commit message says that on the zero-count table 2 columns (`wi_qvalue`, `diff_btw`) differ from R by more than R's own seed-to-seed spread, and that the tolerance is "not a calibrated test". This is honest. It is also the first thing a reviewer will question. Put the explanation in the description, not only in the commit.
5. All 3 commits have "Co-Authored-By: Claude Sonnet 5.5" and the committer `noreply@anthropic.com`.

## 7. Questions for the session that reported these as fixed

1. Which command output showed "Verified" for `7d016aa`, `6df7e76`, `647f8ba` and `74db99d`? The committer email is `noreply@anthropic.com`. Did you check the badge on GitHub after the push, or only `git log`?
2. Why was pull request 70 marked ready on 15 Nov, when the reply of 13 Nov promised a draft and items 1, 2 and 6 were open?
3. Who pushed `647f8ba` to `validation/issue-23-native-da`, and why does it extend the optional loading that Joshua told you to remove?
4. Why does pull request 72 contain a merge commit, when `CONTRIBUTING.md` rule 2 forbids it and Joshua named a merge commit on pull request 70 five days earlier?
5. Why was pull request 71 opened on 12 Nov, before the 13 Nov comment that asked if he wants it, on an issue he closed as "not planned"?
6. Why was issue 73 posted with the title "issue 22" and with the "[OWNER: ...]" bracket still in the body? Who read it before it was sent?
7. Why does `issue-65-review.md` still say the local failure is "unexplained", when the reply withdrew it? Why does it still name `ec6d5a8`, `419f2fb`, "Decimal references" and fork PR 260?
8. Why were the descriptions of 68, 69 and 70 not updated after each force-push?
9. Before you wrote "done", did you run his 3 checks from `CONTRIBUTING.md` (merge base, `%G?` plus the GitHub badge, no merge commits) on the exact head you pushed?
10. Why do commit messages carry model names and session links, against SR-008?
11. Did you read the registry reviewer's comment of 15 Nov on General PR 175952 before you told Joshua the registration was in progress?

## 8. Order of repair

1. Stop pushes to all 5 branches until a single plan exists.
2. PR 72: close it, or convert it to a draft with a note that it waits for 69 and for his decision on item 4.
3. Issue 73: close it as a duplicate of the issue 22 comment, with one sentence of apology. Do not repost the text.
4. PR 71: convert to a draft and say it waits for his answer on issue 22.
5. PR 70: convert to a draft. Correct the reply numbering in one short comment. Tell him ANCOM-BC is dropped, if that is the decision.
6. CompositionalDA: correct the package README and launch document, delete the existing version tags `v0.1.0` and `v0.2.0`, and install TagBot, as the registry reviewer asked. Then update the open registration from the new commit with `@JuliaRegistrator register`. Do not open a new registration pull request. Nothing on pull request 70 can move before this.
7. PR 69: one rebuild. Remove the stale text from the 2 statistics documents, the title and the description. Remove the new CI steps or justify them. Review has started, so add commits (rule 8). Ask him before any rebuild of the history, as for PR 68. Then the owner signs.
8. PR 68: correct the description (CI run and bun version). Ask him if he wants the history squashed. Do not rebase without his request (rule 8).
9. All: the owner's signing identity on every commit, no model names, and a check of the Verified badge in the browser after each push.
10. Turn off the Codex connector for his repository, or stop the automatic trigger.
