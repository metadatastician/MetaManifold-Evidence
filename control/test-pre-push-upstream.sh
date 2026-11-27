#!/usr/bin/env bash
# Self-check for pre-push-upstream.sh. Run: bash control/test-pre-push-upstream.sh
# It exits non-zero at the first case that does not behave as expected.
set -eu
hook="$(cd "$(dirname "$0")" && pwd)/pre-push-upstream.sh"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT; cd "$t"; git init -q
ssh-keygen -q -t ed25519 -N '' -f k
G=(-c commit.gpgsign=false -c user.name=T -c gpg.format=ssh -c user.signingkey="$t/k" -c gpg.ssh.program=ssh-keygen)
commit() { git "${G[@]}" -c user.email="$1" commit -q --allow-empty $2 -m "$3"; }
run() { echo "refs/heads/x $(git rev-parse HEAD) refs/heads/x $base" | UPSTREAM_ALLOWED_COMMITTERS=ok@x "$hook" 2>/dev/null; }
accept() { if run; then echo "pass: $1"; else echo "FAIL: $1" >&2; exit 1; fi; }
refuse() { if run; then echo "FAIL: $1" >&2; exit 1; else echo "pass: $1"; fi; }
fresh() { git reset -q --hard "$base"; }

commit ok@x -S base; base=$(git rev-parse HEAD)
commit ok@x -S "Add a clean change";                     accept "clean signed commit accepted"
fresh; commit ok@x "" "Unsigned change";                 refuse "unsigned commit refused"
fresh; commit bad@x -S "Wrong committer";                refuse "wrong committer refused"
fresh; commit ok@x -S $'Change\n\nCo-Authored-By: Claude <noreply@anthropic.com>'; refuse "Claude trailer refused"
fresh; commit ok@x -S $'Change\n\nCo-authored-by: arena-agent <a@x>'; refuse "any co-author trailer refused"
fresh; commit ok@x -S "Port the Sonnet 5 notes";         refuse "model name refused"
fresh; commit ok@x -S "Fix the parser (#312)";           refuse "fork PR number refused"
fresh; commit ok@x -S "Address the review findings";     refuse "review-shaped subject refused"
fresh; git checkout -q -b side; commit ok@x -S side; git checkout -q -
commit ok@x -S main2
git "${G[@]}" -c user.email=ok@x merge -q -S --no-ff side -m "Join side"; refuse "merge commit refused"
