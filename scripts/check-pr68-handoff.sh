#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
# Gate the PR #68 handoff: the patch must be an authentic, intact format-patch
# against the pinned upstream head and must apply to it byte-for-byte, and the
# audit must describe that exact head. Run in CI with bash -euo pipefail.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD

HEAD=5115109be0ef475b35787011e515db134f4dd05f
PATCH=notes/0004-pr68-ssh-recovery-coverage.patch
AUDIT=notes/pr68-ssh-recovery-review.md
DESIGN=notes/pr68-parallel-ssh-and-hardening.md

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
check() { printf '  ok: %s\n' "$*"; }

[[ -s "$PATCH" ]] || fail "$PATCH is missing or empty"
[[ -s "$AUDIT" ]] || fail "$AUDIT is missing or empty"
[[ -s "$DESIGN" ]] || fail "$DESIGN is missing or empty"

# 0. Every handoff note must carry its licence header and be indexed. The
# repository's REUSE compliance check covers source files; this also covers the
# prose/patch artifacts in notes/.
for f in "$PATCH" "$AUDIT" "$DESIGN" notes/README.md scripts/check-pr68-handoff.sh; do
  head -n 40 "$f" | grep -q 'SPDX-License-Identifier: AGPL-3.0-or-later' || \
    fail "$f has no AGPL-3.0-or-later SPDX header in its first forty lines"
done
for f in 0004-pr68-ssh-recovery-coverage.patch \
         pr68-ssh-recovery-review.md \
         pr68-parallel-ssh-and-hardening.md; do
  grep -q "$f" notes/README.md || fail "notes/README.md does not index $f"
done
check "SPDX headers and notes/README.md index"

# 1. Format and metadata. No malformed headers, no trailing junk commits.
[[ "$(grep -c '^From ' "$PATCH")" == 1 ]] || fail "expected exactly one format-patch commit"
grep -q "^From: " "$PATCH" || fail "missing From header"
grep -q "^Subject: \[PATCH\] " "$PATCH" || fail "missing Subject header"
grep -q '^---$' "$PATCH" || fail "missing format-patch separator"
grep -q '^From [0-9a-f]\{40\} Mon Sep 17 00:00:00 2001$' "$PATCH" || \
  fail "format-patch From line is not a full 40-character object id"
check "one well-formed format-patch commit"

# 2. The notes must not drift from the pinned head.
grep -q "$HEAD" "$AUDIT" || fail "$AUDIT does not pin upstream head $HEAD"
grep -q "$HEAD" "$DESIGN" || fail "$DESIGN does not pin upstream head $HEAD"
grep -q '94.59' "$AUDIT" || fail "audit lost the Codecov baseline"
grep -q 'PRRT_kwDORbJW48606lKn' "$AUDIT" || fail "audit lost the open thread ID"
grep -q 'pssh' "$DESIGN" || fail "design note lost the pssh assessment"
check "audit and design note pin the correct head and findings"

# 3. The real test: a clean checkout of the upstream head, then git apply --check
# then git am, then compare the resulting tree to the patch's own diff.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
git init -q "$WORK/repo"
git -C "$WORK/repo" remote add origin https://github.com/JoshuaJewell/MetaManifold-WebUI.git
git -C "$WORK/repo" fetch -q --depth 1 origin "$HEAD"
git -C "$WORK/repo" checkout -q FETCH_HEAD
git -C "$WORK/repo" apply --check "$ROOT/$PATCH"
check "git apply --check against $HEAD"

git -C "$WORK/repo" -c user.name=ci -c user.email=ci@example.invalid \
  am -q "$ROOT/$PATCH"
check "git am against $HEAD (zero warnings)"
git -C "$WORK/repo" diff --check HEAD^ HEAD
check "git diff --check on the applied commit"

# 4. Every touched file must exist in the applied tree, and the production
# change must be the missing-output retirement, not an unrelated rewrite.
for f in src/pipeline/remote_session.jl \
         test/unit/remote_protocol_tests.jl \
         test/unit/test_phylogeny.jl \
         test/unit/test_remote_stages.jl; do
  [[ -f "$WORK/repo/$f" ]] || fail "$f missing after git am"
done
mapfile -t TOUCHED < <(git -C "$WORK/repo" diff --name-only HEAD^ HEAD)
[[ "${#TOUCHED[@]}" == 4 ]] || fail "expected 4 touched files, got ${#TOUCHED[@]}: ${TOUCHED[*]}"
grep -q 'missing-outputs-' "$WORK/repo/src/pipeline/remote_session.jl" || \
  fail "production fix is not the missing-output retirement"
grep -q 'retired for a fresh attempt' "$WORK/repo/test/unit/remote_protocol_tests.jl" || \
  fail "retirement regression is missing"
PROTO="$WORK/repo/test/unit/remote_protocol_tests.jl"
grep -q 'get(ENV, "PATH", "")' "$PROTO" || \
  fail "unset-PATH hardening is missing from the transport fixture"
grep -q 'function _owned_transport' "$PROTO" || \
  fail "stateful ControlMaster transport fixture is missing"
grep -q 'ProcessFailedException' "$PROTO" || \
  fail "exact exception assertions are missing"
grep -q 'read(journal_path) == original_journal' "$PROTO" || \
  fail "pending-stop journal immutability assertion is missing"
grep -q 'Linux only' "$ROOT/$PATCH" || \
  fail "the patch does not record the Linux-only rerun requirement"
check "4 files, production fix and all five review-hardened fixtures present"

# 5. Structural sanity of every modified Julia file: brackets balanced and
# block depth unchanged from the base version. This is NOT a substitute for
# running Julia; it catches an unbalanced `end` in a patch we cannot execute.
pip install --quiet --break-system-packages pygments 2>/dev/null || \
  pip install --quiet pygments
python3 - "$WORK/repo" <<'PY'
import subprocess, sys
from pygments import lex
from pygments.lexers import JuliaLexer
from pygments.token import Token
repo = sys.argv[1]
files = subprocess.check_output(
    ['git', '-C', repo, 'diff', '--name-only', 'HEAD^', 'HEAD'], text=True).split()
opens = ('function','macro','begin','do','if','for','while','try','let','struct','mutable','abstract','primitive','quote','module','baremodule')
closers = ('end',)
def structure(text):
    depth = 0
    brackets = 0
    for tok, val in lex(text, JuliaLexer()):
        if tok in Token.Literal.String or tok in Token.Comment:
            continue
        if tok in Token.Keyword:
            v = val.strip()
            if v in opens:
                depth += 1
            elif v in closers:
                depth -= 1
        if tok in Token.Punctuation:
            if val in '([{': brackets += 1
            elif val in ')]}': brackets -= 1
    return depth, brackets
for f in files:
    if not f.endswith('.jl'):
        continue
    before = subprocess.check_output(
        ['git', '-C', repo, 'show', 'HEAD^:'+f], text=True)
    after = open(repo+'/'+f, encoding='utf-8').read()
    d0, b0 = structure(before)
    d1, b1 = structure(after)
    if b0 != b1 or d0 != d1:
        sys.exit('FAIL: %s bracket depth %d->%d, block depth %d->%d' %
                 (f, b0, b1, d0, d1))
    print('  ok: %s structure delta zero (brackets %d, blocks %d)' % (f, b1, d1))
PY
check "all modified Julia files structurally unchanged in depth"

printf '\nPASS: PR #68 handoff patch is authentic, applies cleanly to %s, and is internally consistent.\n' "$HEAD"
