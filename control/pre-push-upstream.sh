#!/usr/bin/env bash
# Pre-push gate for branches that feed JoshuaJewell/MetaManifold-WebUI.
# Install in a fork clone:  ln -s /path/to/pre-push-upstream.sh .git/hooks/pre-push
# It refuses the push if any new commit breaks a rule that the maintainer's
# CONTRIBUTING.md or the estate rules state. It prints every violation.
# Allowed committer emails: UPSTREAM_ALLOWED_COMMITTERS (space-separated).
# snip: grep checks on commit text; upgrade to a server ruleset when the owner sets one.
set -u
allowed="${UPSTREAM_ALLOWED_COMMITTERS:-355856132+HoTT-stuff@users.noreply.github.com}"
zero=0000000000000000000000000000000000000000
fail=0
say() { echo "pre-push: $1" >&2; fail=1; }

while read -r local_ref local_sha remote_ref remote_sha; do
  [ "$local_sha" = "$zero" ] && continue                       # branch delete
  if [ "$remote_sha" = "$zero" ]; then range="$local_sha --not --remotes"; else range="$remote_sha..$local_sha"; fi
  for c in $(git rev-list $range); do
    s=$(git log -1 --format=%h "$c")
    [ "$(git rev-list --parents -n1 "$c" | wc -w)" -gt 2 ] && say "$s is a merge commit (rule 2)"
    git cat-file -p "$c" | grep -q '^gpgsig ' || say "$s has no signature (rule 3)"
    ce=$(git log -1 --format=%ce "$c")
    case " $allowed " in *" $ce "*) ;; *) say "$s committer $ce is not allowed";; esac
    msg=$(git log -1 --format=%B "$c")
    grep -qiE 'claude-session:|co-authored-by:.*(claude|anthropic)' <<<"$msg" && say "$s has a Claude trailer (SR-008)"
    grep -qiE '\b(opus|sonnet|haiku|fable|mythos) [0-9]' <<<"$msg" && say "$s names a model (SR-008)"
    grep -qE '#[0-9]{3,}' <<<"$msg" && say "$s cites a fork PR number (his review of PR 69)"
    grep -qiE 'review (thread|finding)s?|address(es)? the' <<<"$(head -1 <<<"$msg")" && say "$s subject describes the review, not the change (his review of PR 70)"
  done
done
[ "$fail" -eq 0 ] || { echo "pre-push: refused. Fix the commits, or ask the owner." >&2; exit 1; }
