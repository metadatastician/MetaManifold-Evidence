#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# One-shot close-out driver for JoshuaJewell/MetaManifold-WebUI#68.
# Run on Linux with git, gh, Julia 1.12.x, and a credential that has:
#   contents:write  on hyperpolymath/MetaManifold-WebUI
#   pull_requests:write + issues:write on JoshuaJewell/MetaManifold-WebUI
#   merge rights on JoshuaJewell/MetaManifold-WebUI:main
#
# The Arena session token has none of these; see notes/pr68-closeout-runbook.md.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$PWD

BASE_REPO=JoshuaJewell/MetaManifold-WebUI
FORK_REPO=hyperpolymath/MetaManifold-WebUI
FORK_BRANCH=fix/66-resumable-ssh-stages
PR=68
PINNED_HEAD=5115109be0ef475b35787011e515db134f4dd05f
PATCH=$ROOT/notes/0004-pr68-ssh-recovery-coverage.patch
THREADS=(PRRT_kwDORbJW48606d5b PRRT_kwDORbJW48606d5n PRRT_kwDORbJW48606lKn)

die() { printf 'ABORT: %s\n' "$*" >&2; exit 1; }
ok()  { printf '  ok: %s\n' "$*"; }

WORK=
QDIR=
cleanup() { [[ -n "$WORK" ]] && rm -rf "$WORK"; [[ -n "$QDIR" ]] && rm -rf "$QDIR"; }
trap cleanup EXIT

MODE=${1:---verify}
case "$MODE" in
  --verify|--push|--close|--all) ;;
  *) printf 'usage: %s [--verify|--push|--close|--all]\n' "$0" >&2; exit 2 ;;
esac

[[ -f "$PATCH" ]] || die "$PATCH is missing"
command -v gh >/dev/null || die "gh is required"
command -v git >/dev/null || die "git is required"

verify() {
  echo "== phase 1: verify the handoff patch =="
  bash "$ROOT/scripts/check-pr68-handoff.sh" || die "handoff integrity gate failed"
  head=$(gh pr view "$PR" --repo "$BASE_REPO" --json headRefOid --jq .headRefOid)
  printf '  PR #68 head: %s\n' "$head"
  if [[ "$MODE" == --push || "$MODE" == --all ]]; then
    [[ "$head" == "$PINNED_HEAD" ]] || \
      die "PR head moved to $head; rebase the patch onto the new head before pushing"
    ok "head is still the pinned $PINNED_HEAD"
  else
    [[ "$head" == "$PINNED_HEAD" ]] || \
      printf '  NOTE: head has moved; the patch is pinned to %s and must be rebased\n' "$PINNED_HEAD"
  fi
}

push_fix() {
  echo "== phase 2: apply the patch to the fork head and push it =="
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated"
  WORK=$(mktemp -d)
  git clone -q --depth 1 --branch "$FORK_BRANCH" \
    "https://github.com/$FORK_REPO.git" "$WORK/pr68"
  cd "$WORK/pr68"
  git -c user.name='MetaManifold evidence agent' \
      -c user.email='297053741+arena-agent@users.noreply.github.com' \
      am -q "$PATCH"
  git diff --check HEAD^ HEAD
  ok "patch applied cleanly as $(git rev-parse --short HEAD)"
  git push origin HEAD:refs/heads/$FORK_BRANCH
  ok "pushed to $FORK_REPO:$FORK_BRANCH"

  echo "== waiting for WebUI CI (Julia tests take about 21 minutes) =="
  gh pr checks "$PR" --repo "$BASE_REPO" --watch --interval 20
  gh pr checks "$PR" --repo "$BASE_REPO"
  ok "all PR #68 checks pass on the new head"
  cd "$ROOT"
}

reply_and_resolve() {
  echo "== phase 3: post the three replies and resolve the three threads =="
  QDIR=$(mktemp -d)
  qdir=$QDIR
  cat > "$qdir/reply.graphql" <<'EOF'
mutation($id: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $id, body: $body}) {
    comment { id }
  }
}
EOF
  cat > "$qdir/resolve.graphql" <<'EOF'
mutation($id: ID!) {
  resolveReviewThread(input: {threadId: $id}) {
    thread { id isResolved }
  }
}
EOF
  cat > "$qdir/threads.graphql" <<'EOF'
query {
  repository(owner: "JoshuaJewell", name: "MetaManifold-WebUI") {
    pullRequest(number: 68) { reviewThreads(first: 100) { nodes { id isResolved } } }
  }
}
EOF

  # Verbatim from notes/pr68-ssh-recovery-review.md, "Draft replies".
  local body1 body2 body3
  body1='Fixed at `5115109`. A superseded journal is now reclaimed through the original host/staging root/key recorded in its own identity (`remote_session.jl:385-421`), and `reclaim=true` removes a lock-free preparation directly while a running attempt still goes through `cancel` (`:111-123`). `_sweep` keeps its worker-plus-old-exit rule; it is no longer the only path that can retire an interrupted preparation. Covered by the two reclamation regressions and by `notes/0004-pr68-ssh-recovery-coverage.patch`, which adds the two owned-master teardown cases.'
  body2='Fixed at `5115109`. Receipt recovery replays the retained remote log before `cleanup` deletes the attempt (`remote_session.jl:322-330, 448-453`), byte-wise and idempotently, and every DADA2 stage entry point plus the phylogeny step now truncates only when no `.remote.json` journal is retained. Covered by the "keeps its remote diagnostics" and "replayed once" regressions, and by the new receipt-cleanup case.'
  body3='Partly fixed at `5115109`, and closed by the companion patch. `replay` removes the `start`/`retry` refusal for a completed attempt whose *download* failed, but it cannot recover a file the command never wrote: replaying that attempt would report the same error on every rerun. `notes/0004-pr68-ssh-recovery-coverage.patch` makes a zero exit with missing required outputs retire the attempt (cleanup plus an archived journal), so an explicit rerun launches a fresh one; a failed cleanup keeps the journal so no attempt is left without an owner. The new regression toggles a flag so the unchanged command writes its output on the rerun and asserts a fresh launch, a new receipt and no stale attempt.'

  local bodies=("$body1" "$body2" "$body3")
  for i in 0 1 2; do
    id=${THREADS[$i]}
    printf '  replying to %s\n' "$id"
    local reply_id
    reply_id=$(gh api graphql -F query=@"$qdir/reply.graphql" -F id="$id" \
      -F body="${bodies[$i]}" --jq '.data.addPullRequestReviewThreadReply.comment.id')
    [[ -n "$reply_id" && "$reply_id" != null ]] || \
      die "could not post a reply on $id (check pull_requests:write / issues:write)"
    printf '  resolving %s\n' "$id"
    local resolved
    resolved=$(gh api graphql -F query=@"$qdir/resolve.graphql" -F id="$id" \
      --jq '.data.resolveReviewThread.thread.isResolved')
    [[ "$resolved" == true ]] || die "could not resolve $id"
  done

  local unresolved
  unresolved=$(gh api graphql -F query=@"$qdir/threads.graphql" \
    --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false)] | length')
  [[ "$unresolved" == 0 ]] || die "$unresolved review threads are still unresolved"
  ok "all PR #68 review threads are resolved"
}

merge_pr() {
  echo "== phase 4: merge PR #68 =="
  if [[ "$MODE" == --close ]]; then
    echo "  --close only: verifying the head has moved off $PINNED_HEAD before merging"
    head=$(gh pr view "$PR" --repo "$BASE_REPO" --json headRefOid --jq .headRefOid)
    [[ "$head" != "$PINNED_HEAD" ]] || \
      die "the companion patch is not on the PR head; run --push first"
  fi
  gh pr checks "$PR" --repo "$BASE_REPO" >/dev/null || die "PR #68 checks are not all green"
  # The merge command must be the last command in this chain, with its exit
  # code unmasked: do not pipe, redirect, or append another shell operator.
  gh pr merge "$PR" --repo "$BASE_REPO" --merge
}

case "$MODE" in
  --verify) verify ;;
  --push)  verify; push_fix ;;
  --close) reply_and_resolve; merge_pr ;;
  --all)   verify; push_fix; reply_and_resolve; merge_pr ;;
esac

printf '\nFinal state:\n'
gh pr view "$PR" --repo "$BASE_REPO" --json state,mergedAt,mergeCommit,headRefOid
