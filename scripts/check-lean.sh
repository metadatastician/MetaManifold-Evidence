#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# The Lean recheck leg (route: re-proved) of the counts theorems.
#
#  1. The prover is Lean 4.24.0 at its release commit (binary from $LEAN,
#     default `lean`). No lake, no Mathlib, no library beyond Lean's core.
#  2. lean/CountsJuliaTable.lean (from the Agda counts table) and
#     lean/ExplorerTable.lean (from residual-evidence-types'
#     tests/correspondence/ExplorerTable.agda, at the commit
#     scripts/fetch-layer-a.sh pins) are regenerated to a temporary path and
#     must be byte-identical to the committed files; the explorer table is
#     also translated back and compared with the Agda rows.
#  3. Escape-hatch audit of the positive set (no sorry, axiom, admit,
#     native_decide, implemented_by, extern, unsafe, partial, opaque,
#     Classical, imports outside the ported modules; set_option only to
#     raise maxRecDepth or maxHeartbeats for one declaration).
#  4. Every module is compiled in dependency order with `lean -o` into a
#     fresh _build/lean; warnings are errors.
#  5. lean/All.lean must print the axioms of exactly the declarations the
#     modules make, and no printed axiom may lie outside ALLOWED_AXIOMS
#     (empty: see lean/CORRESPONDENCE.adoc). The audit is first shown to flag
#     propext on lean/control/AxiomGate.lean.
#  6. Every file under lean/reject must fail to elaborate, with type errors
#     only, located at its `theorem invalid` line.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
export LC_ALL=C.UTF-8

lean="${LEAN:-lean}"
want_version='4.24.0'
want_githash='797c613eb9b6d4ec95db23e3e00af9ac6657f24b'
# The allow-list of axioms a theorem may depend on. Empty: every declaration
# must print "does not depend on any axioms".
ALLOWED_AXIOMS=()

modules=(ResidualEvidence Counts Bounds CheckerBridge CountsGrid CountsJuliaTable CountsCertificate
         ExplorerTable Correspondence)
ret_root="${RET_ROOT:-_build/dependencies/residual-evidence-types}"
build=_build/lean
logs=_build/check-logs/lean

fail() { echo "ERROR: $*" >&2; exit 1; }

# 1. Toolchain.
version="$("$lean" --version)"
echo "$version"
[[ "$version" == "Lean (version $want_version, "* ]] ||
  fail "expected Lean $want_version, got: $version"
[[ "$("$lean" --githash)" == "$want_githash" ]] ||
  fail "expected Lean commit $want_githash, got: $("$lean" --githash)"
echo "PASS: Lean $want_version at $want_githash"

# 2. The generated table matches its generator.
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
bash scripts/gen-lean-table.sh "$tmpdir/CountsJuliaTable.lean"
cmp -- lean/CountsJuliaTable.lean "$tmpdir/CountsJuliaTable.lean" ||
  fail 'lean/CountsJuliaTable.lean differs from scripts/gen-lean-table.sh output'
rows="$(grep -c '^  Row\.row ' lean/CountsJuliaTable.lean)"
[[ "$rows" == 169 ]] || fail "expected 169 table rows (13 x 13), found $rows"
echo "PASS: lean/CountsJuliaTable.lean regenerated identically ($rows rows)"

# The explorer table: the dependency must be at the pinned commit.
pin="$(sed -nE 's/^fetch residual-evidence-types [^ ]+ ([0-9a-f]{40})$/\1/p' scripts/fetch-layer-a.sh)"
[[ "$pin" =~ ^[0-9a-f]{40}$ ]] || fail 'cannot read the residual-evidence-types pin from scripts/fetch-layer-a.sh'
have="$(git -C "$ret_root" rev-parse HEAD 2>/dev/null || true)"
[[ "$have" == "$pin" ]] ||
  fail "residual-evidence-types at $ret_root is '$have', pinned $pin (run scripts/fetch-layer-a.sh)"
git -C "$ret_root" diff --quiet HEAD -- tests/correspondence/ExplorerTable.agda ||
  fail "$ret_root/tests/correspondence/ExplorerTable.agda differs from the pinned commit"
RET_ROOT="$ret_root" bash scripts/gen-lean-explorer-table.sh "$tmpdir/ExplorerTable.lean"
cmp -- lean/ExplorerTable.lean "$tmpdir/ExplorerTable.lean" ||
  fail 'lean/ExplorerTable.lean differs from scripts/gen-lean-explorer-table.sh output'
# Translate the Lean rows back into Agda spelling and compare with the source,
# so a generator that dropped or altered a field cannot pass unnoticed.
sed -nE 's/^(    |  ∷ )(row .*)$/\2/p' "$ret_root/tests/correspondence/ExplorerTable.agda" >"$tmpdir/agda-rows"
sed -nE '/^    Row\.row /{
  s/^    Row\.row /row /; s/,$//
  s/Int\.//g; s/(View|Verdict|IdStatus)\.//g; s/[«»]//g
  s/ \[([^]]+)\]$/ (\1 ∷ [])/; s/, / ∷ /g
  p
}' lean/ExplorerTable.lean >"$tmpdir/lean-rows"
cmp -- "$tmpdir/agda-rows" "$tmpdir/lean-rows" ||
  fail 'lean/ExplorerTable.lean does not translate back to the Agda ExplorerTable rows'
rows="$(wc -l <"$tmpdir/lean-rows")"
[[ "$rows" == 546 ]] || fail "expected 546 explorer rows (13 x 7 x 3 x 2), found $rows"
echo "PASS: lean/ExplorerTable.lean regenerated identically and translates back to the Agda rows ($rows rows, residual-evidence-types $pin)"

# 3. Escape-hatch audit of the positive set.
positive=()
for m in "${modules[@]}" All; do positive+=("lean/$m.lean"); done
# Code only: block comments (/- … -/, including doc comments) and line
# comments are blanked first, so prose about axioms does not trip the audit.
strip_comments() {
  awk '{
    out = ""; s = $0
    while (length(s) > 0) {
      if (depth > 0) {
        o = index(s, "/-"); c = index(s, "-/")
        if (c == 0 && o == 0) { s = ""; break }
        if (o > 0 && (c == 0 || o < c)) { depth++; s = substr(s, o + 2) }
        else { depth--; s = substr(s, c + 2) }
      } else {
        o = index(s, "/-"); l = index(s, "--")
        if (o == 0 && l == 0) { out = out s; s = "" }
        else if (l > 0 && (o == 0 || l < o)) { out = out substr(s, 1, l - 1); s = "" }
        else { out = out substr(s, 1, o - 1); depth = 1; s = substr(s, o + 2) }
      }
    }
    printf "%s:%d:%s\n", FILENAME, FNR, out
  }' "$@"
}
if strip_comments "${positive[@]}" |
   grep -E '\b(sorry|admit|axiom|axioms|native_decide|implemented_by|extern|unsafe|partial|opaque|set_option|Classical|ofReduceBool|ofReduceNat|skipKernelTC|macro|elab|syntax)\b|@\[(csimp|implemented_by|extern)' |
   grep -vE '^lean/All\.lean:[0-9]+:#print axioms [^ ]+$' |
   grep -vE '^[^:]+:[0-9]+:set_option (maxRecDepth|maxHeartbeats) [0-9]+ in$'; then
  fail 'escape hatch found in the positive set'
fi
import_re="import ($(IFS='|'; echo "${modules[*]}"))\$"
if grep -nE '^import ' "${positive[@]}" | grep -vE "^[^:]+:[0-9]+:$import_re"; then
  fail 'import outside the ported modules (Init is implicit; Std, Lean and Mathlib are refused)'
fi
echo 'PASS: escape-hatch audit (no sorry/axiom/admit/native_decide/implemented_by/extern; set_option only for elaborator budgets; core Init only)'

# 4. Compile in dependency order; warnings are errors.
rm -rf -- "$build" "$logs"
mkdir -p -- "$build" "$logs"
export LEAN_PATH="$build"
for m in "${modules[@]}"; do
  if ! "$lean" -E warning --root=lean -o "$build/$m.olean" "lean/$m.lean" >"$logs/$m.log" 2>&1; then
    cat -- "$logs/$m.log"
    fail "lean/$m.lean did not compile"
  fi
  if [[ -s "$logs/$m.log" ]]; then
    cat -- "$logs/$m.log"
    fail "lean/$m.lean printed messages"
  fi
  echo "PASS: compiled lean/$m.lean"
done

# 5. Axiom audit.
# audit FILE: every line must be a #print axioms result; every axiom named must
# be in ALLOWED_AXIOMS. Prints offending lines; returns 1 if there are any.
audit() {
  local out=$1 line axioms ax ok status=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^\'.+\'\ does\ not\ depend\ on\ any\ axioms$ ]]; then
      continue
    elif [[ "$line" =~ ^\'.+\'\ depends\ on\ axioms:\ \[(.*)\]$ ]]; then
      axioms="${BASH_REMATCH[1]}"
      IFS=', ' read -r -a axs <<<"$axioms"
      for ax in "${axs[@]}"; do
        [[ -z "$ax" ]] && continue
        ok=0
        for a in "${ALLOWED_AXIOMS[@]+"${ALLOWED_AXIOMS[@]}"}"; do
          [[ "$ax" == "$a" ]] && ok=1
        done
        if (( ! ok )); then echo "  axiom outside the allow-list: $line"; status=1; fi
      done
    else
      echo "  unexpected output: $line"; status=1
    fi
  done <"$out"
  return "$status"
}

# Gate self-test: the audit must flag propext.
"$lean" lean/control/AxiomGate.lean >"$logs/AxiomGate.log" 2>&1 ||
  { cat -- "$logs/AxiomGate.log"; fail 'gate control lean/control/AxiomGate.lean did not compile'; }
grep -qx "'«uses-propext»' depends on axioms: \[propext\]" "$logs/AxiomGate.log" ||
  { cat -- "$logs/AxiomGate.log"; fail 'gate control: Lean did not report propext'; }
if audit "$logs/AxiomGate.log" >"$logs/AxiomGate.audit"; then
  fail 'gate control: the axiom audit passed a theorem that depends on propext'
fi
grep -q '«uses-propext»' "$logs/AxiomGate.audit" && ! grep -q '«uses-nothing»' "$logs/AxiomGate.audit" ||
  { cat -- "$logs/AxiomGate.audit"; fail 'gate control: the audit flagged the wrong declaration'; }
echo 'PASS: gate control (the axiom audit flags propext and passes an axiom-free theorem)'

# All.lean must cover exactly the declarations of the modules.
declare_names() {
  awk '
    /^namespace / { ns[++d] = $2; next }
    /^end / { if (d > 0 && $2 != "") d--; next }
    /^(theorem|def|abbrev|inductive|structure) / {
      name = $2; sub(/[:({\[].*$/, "", name)
      q = ""; for (i = 1; i <= d; i++) q = q ns[i] "."
      print q name
    }' "$@"
}
declared="$tmpdir/declared"; printed="$tmpdir/printed"
for m in "${modules[@]}"; do declare_names "lean/$m.lean"; done | sort >"$declared"
sed -n 's/^#print axioms //p' lean/All.lean | sort >"$printed"
if ! diff -u "$declared" "$printed"; then
  fail 'lean/All.lean does not print the axioms of exactly the declared names'
fi
"$lean" -E warning --root=lean lean/All.lean >"$logs/All.log" 2>&1 ||
  { cat -- "$logs/All.log"; fail 'lean/All.lean did not compile'; }
n_decls="$(wc -l <"$declared")"
n_out="$(wc -l <"$logs/All.log")"
[[ "$n_out" == "$n_decls" ]] ||
  { cat -- "$logs/All.log"; fail "expected $n_decls axiom reports, got $n_out"; }
if ! audit "$logs/All.log"; then
  fail 'a declaration depends on an axiom outside the allow-list'
fi
n_free="$(grep -c "does not depend on any axioms\$" "$logs/All.log")"
echo "PASS: axiom audit of $n_decls declarations ($n_free depend on no axioms; allow-list: ${ALLOWED_AXIOMS[*]:-empty})"

# 6. Expected rejections.
shopt -s nullglob
rejects=(lean/reject/*.lean)
shopt -u nullglob
(( ${#rejects[@]} >= 2 )) || fail 'fewer than two expected-rejection files under lean/reject'
for file in "${rejects[@]}"; do
  name="$(basename -- "$file" .lean)"
  log="$logs/reject-$name.log"
  line="$(grep -n '^theorem invalid ' "$file" | cut -d: -f1)"
  [[ "$line" =~ ^[0-9]+$ ]] || fail "$file: needs exactly one line starting 'theorem invalid '"
  if "$lean" --root=lean "$file" >"$log" 2>&1; then
    cat -- "$log"
    fail "invalid statement accepted: $name"
  fi
  # Errors only at the invalid declaration, of the type-checking kind.
  if ! grep -qE "^$file:$line:[0-9]+: error: " "$log" ||
     grep -E "^[^ ]+:[0-9]+:[0-9]+: (error|warning)" "$log" | grep -vqE "^$file:$line:[0-9]+: error: " ||
     ! grep -qE 'mismatch|Not a definitional equality' "$log" ||
     grep -qiE 'unknown (identifier|constant|namespace|module)|unexpected token|unknown package|maximum recursion|heartbeats|timeout|sorry' "$log"; then
    cat -- "$log"
    fail "unexpected failure while checking $name"
  fi
  echo "PASS: rejected $name at its invalid statement (line $line)"
done
echo "PASS: Lean leg: ${#modules[@]} modules, $n_decls declarations axiom-free, ${#rejects[@]} expected rejections"
