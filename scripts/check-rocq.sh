#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# Check the Rocq recheck leg (route: re-proved) of the Agda counts theorems.
#
#   1. coqc must be The Coq Proof Assistant 8.18.0.
#   2. rocq/CountsJuliaTable.v and rocq/ExplorerTable.v must be exactly what
#      scripts/gen-rocq-table.sh and scripts/gen-rocq-explorer-table.sh
#      generate from the Agda tables (the second needs
#      scripts/fetch-layer-a.sh to have run, or RET_ROOT).
#   3. Every file in rocq/_CoqProject compiles, in that order, with
#      coqc -Q rocq MetaManifoldEvidence; _CoqProject lists every rocq/*.v.
#   4. No escape hatch in the positive set (comment-aware scan).
#   5. All.v prints assumptions for every Theorem and Lemma, and each one is
#      "Closed under the global context".
#   6. The assumptions parser refuses rocq/gate-selftest/AxiomLeak.v.
#   7. Every rocq/reject/*.v fails to compile, with a type error located in
#      its `Definition invalid` declaration.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
export LC_ALL=C

fail() { echo "ERROR: $*" >&2; exit 1; }
coq=(coqc -Q rocq MetaManifoldEvidence)
logs=_build/rocq-logs
mkdir -p "$logs"

# 1. Toolchain -----------------------------------------------------------
version="$(coqc --version)"
version="${version%%$'\n'*}"
echo "$version"
[[ "$version" == "The Coq Proof Assistant, version 8.18.0" ]] ||
  fail "expected coqc 8.18.0, found: $version"

# 2. Generated tables ----------------------------------------------------
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
scripts/gen-rocq-table.sh "$tmpdir/CountsJuliaTable.v" >/dev/null
cmp -- "$tmpdir/CountsJuliaTable.v" rocq/CountsJuliaTable.v ||
  fail "rocq/CountsJuliaTable.v differs from scripts/gen-rocq-table.sh output"
echo "PASS: rocq/CountsJuliaTable.v matches the generator output"
scripts/gen-rocq-explorer-table.sh "$tmpdir/ExplorerTable.v" >/dev/null
cmp -- "$tmpdir/ExplorerTable.v" rocq/ExplorerTable.v ||
  fail "rocq/ExplorerTable.v differs from scripts/gen-rocq-explorer-table.sh output"
echo "PASS: rocq/ExplorerTable.v matches the generator output"

# 3. Compile in _CoqProject order ----------------------------------------
mapfile -t order < <(grep -E '^[A-Za-z0-9_]+\.v$' rocq/_CoqProject)
(( ${#order[@]} > 0 )) || fail "no .v files listed in rocq/_CoqProject"
listed="$(printf '%s\n' "${order[@]}" | sort)"
present="$(cd rocq && ls -1 -- *.v | sort)"
[[ "$listed" == "$present" ]] ||
  fail "rocq/_CoqProject and rocq/*.v disagree:$(diff <(echo "$listed") <(echo "$present") || true)"
[[ "${order[-1]}" == "All.v" ]] || fail "All.v must be compiled last"

for f in "${order[@]}"; do
  log="$logs/${f%.v}.log"
  if ! "${coq[@]}" "rocq/$f" >"$log" 2>&1; then
    cat "$log"
    fail "rocq/$f does not compile"
  fi
  echo "PASS: compiled rocq/$f"
done

# 4. Escape-hatch scan, comments and strings removed ----------------------
strip_comments() {
  awk '
  { line = $0; out = ""; i = 1; n = length(line)
    while (i <= n) {
      c = substr(line, i, 1); c2 = substr(line, i, 2)
      if (instr) { if (c == "\"") instr = 0; i++; continue }
      if (c2 == "(*") { depth++; i += 2; continue }
      if (depth > 0 && c2 == "*)") { depth--; i += 2; continue }
      if (depth > 0) { i++; continue }
      if (c == "\"") { instr = 1; i++; continue }
      out = out c; i++
    }
    printf "%s:%d:%s\n", FILENAME, FNR, out }' "$@"
}
hatches='Admitted|admit|give_up|Axiom|Axioms|Parameter|Parameters|Hypothesis|Hypotheses|Variable|Variables|Conjecture|Context|Abort|Unset|bypass_check|Bypass'
if strip_comments rocq/*.v | grep -wE "$hatches"; then
  fail "escape hatch found in the positive set"
fi
echo "PASS: escape-hatch scan (no Admitted, admit, Axiom, Parameter, Hypothesis, Variable, Unset ...)"

# 5. Print Assumptions ---------------------------------------------------
# Every name given to Print Assumptions in All.v, in order.
mapfile -t names < <(sed -nE 's/^Print Assumptions MetaManifoldEvidence\.([A-Za-z0-9_.]+)\.$/\1/p' rocq/All.v)
(( ${#names[@]} > 0 )) || fail "All.v prints no assumptions"

# Every Theorem and Lemma of the positive set must be among them.
while read -r file decl; do
  printf '%s\n' "${names[@]}" | grep -qE "(^|\.)${decl}\$" ||
    fail "$file: $decl is not given to Print Assumptions in rocq/All.v"
done < <(grep -oE '^(Theorem|Lemma) [A-Za-z0-9_]+' rocq/*.v | sed -E 's/:(Theorem|Lemma) / /')

# Parse coqc output of `Check @X. Print Assumptions X.` blocks: each block
# must name the expected theorem and say exactly "Closed under the global
# context".  Prints one line per theorem; exits non-zero on any other result.
check_assumptions() {
  local log="$1"; shift
  printf '%s\n' "$@" | awk -v src="$log" '
  NR == FNR { want[++n] = $0; next }
  /^@?[A-Za-z_][A-Za-z0-9_.'"'"']*$/ {
    name = $0; sub(/^@/, "", name); k++
    w = want[k]
    if (w != name && substr(w, length(w) - length(name)) != "." name) {
      printf "ERROR: block %d names %s, expected %s\n", k, name, w; bad = 1
    }
    next
  }
  $0 == "Closed under the global context" { closed[k]++; next }
  /^(Axioms|Section Variables|Opaque constants|Transparent constants):/ { dirty[k] = $0; next }
  END {
    if (k != n) { printf "ERROR: %d assumption blocks in %s, expected %d\n", k, src, n; bad = 1 }
    for (i = 1; i <= n; i++) {
      if (closed[i] == 1 && !(i in dirty)) printf "  %-50s Closed under the global context\n", want[i]
      else { printf "ERROR: %s is not closed (%s)\n", want[i], (i in dirty) ? dirty[i] : "no verdict"; bad = 1 }
    }
    exit bad
  }' - "$log"
}

echo "Print Assumptions (rocq/All.v):"
check_assumptions "$logs/All.log" "${names[@]}" ||
  { cat "$logs/All.log"; fail "Print Assumptions does not close every theorem"; }
echo "PASS: all ${#names[@]} theorems closed under the global context"

# 6. The parser must refuse a theorem that rests on an axiom -------------
selftest=rocq/gate-selftest/AxiomLeak.v
"${coq[@]}" "$selftest" >"$logs/AxiomLeak.log" 2>&1 ||
  { cat "$logs/AxiomLeak.log"; fail "$selftest should compile"; }
if check_assumptions "$logs/AxiomLeak.log" leak >/dev/null 2>&1; then
  fail "assumptions parser accepted $selftest, which uses an axiom"
fi
grep -q '^Axioms:' "$logs/AxiomLeak.log" || fail "$selftest did not report its axiom"
echo "PASS: assumptions parser refuses $selftest"

# 7. Expected rejections -------------------------------------------------
shopt -s nullglob
rejects=(rocq/reject/*.v)
shopt -u nullglob
(( ${#rejects[@]} >= 2 )) || fail "fewer than two expected-rejection files under rocq/reject"
for file in "${rejects[@]}"; do
  name="$(basename -- "$file" .v)"
  log="$logs/reject-$name.log"
  if "${coq[@]}" "$file" >"$log" 2>&1; then
    cat "$log"
    fail "invalid proof accepted: $file"
  fi
  start="$(grep -n '^Definition invalid ' "$file" | cut -d: -f1)"
  [[ -n "$start" ]] || fail "$file has no 'Definition invalid' declaration"
  end="$(awk -v s="$start" 'NR >= s && /\.[[:space:]]*$/ { print NR; exit }' "$file")"
  line="$(sed -nE "s|^File \"(\./)?${file}\", line ([0-9]+),.*|\2|p" "$log" | head -n 1)"
  if [[ -z "$line" ]] || (( line < start || line > end )) ||
     ! grep -q 'while it is expected to have type' "$log" ||
     grep -Eq 'was not found|Syntax error|Unable to locate|Cannot find|Unbound' "$log"; then
    cat "$log"
    fail "unexpected failure while checking $file (want a type error in lines $start-$end)"
  fi
  echo "PASS: rejected $name at its invalid declaration (line $line)"
done

echo "PASS: Rocq leg: ${#order[@]} files, ${#names[@]} theorems closed, ${#rejects[@]} expected rejections"
