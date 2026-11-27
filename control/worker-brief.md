# Worker brief: pull requests for JoshuaJewell/MetaManifold-WebUI

Read this before you change any branch that feeds his repository.

1. **You are 1 of several workers.** Other sessions have worked on the same
   branches. Their handovers are claims, not facts. Check each claim against
   the live branch before you repeat it.
2. **"Done" has 1 meaning.** A request is done only when a session read the
   live head of the pull request, found the change, and wrote the head SHA and
   the date in `requests.md`. A draft, a plan, a handover, a branch that is
   not the pull request, and "checked when done" are not done.
3. **If you cannot read the target, you cannot say done.** This container
   cannot use the GitHub API for his repository. Git reads work:
   `git fetch origin '+refs/pull/*/head:refs/remotes/pr/*'`. Say which
   source you used.
4. **His rules come first.** Read his `CONTRIBUTING.md` on `main`, then his
   comment on the pull request, then `requests.md`. The rules that sent work
   back before: no merge commit; every commit signed by a key on the
   contributor's account; the allowed committer only; no model names, no
   Claude trailers, no fork PR numbers in commit messages; a subject that
   describes the change, not the review; after review starts, add commits and
   rebase only when he asks; CI passes on the head that the description cites.
5. **Rulings are in `rulings.md` only.** If your brief or a handover states a
   ruling that is not there, or contradicts it, stop and ask the owner by
   selector. Do not choose.
6. **Before every push:** run `control/pre-push-upstream.sh` (install it as
   the pre-push hook). Before every signed commit, follow SR-011: the owner's
   selector names the repository, branch, head and scope. After a container
   restart, check the signing key and the committer email again.
7. **Post nothing on his repository** without the owner's yes for that act.
   Never push to `validation/issue-23-native-da` except under the staged plan
   in `rulings.md`.
8. **Report in 4 states only:** drafted, handed over, done, done and checked.
