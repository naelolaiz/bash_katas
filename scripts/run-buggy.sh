#!/usr/bin/env bash
# Run a single exercise's tests against the buggy version (default) or
# against a candidate fix. Shows which @tests fail under the buggy code;
# fix the code and re-run until green.
#
# Usage:
#   scripts/run-buggy.sh NN              # tests against docs/NN-slug/buggy.sh
#   scripts/run-buggy.sh NN PATH         # tests against PATH (your fix)
#
# Mechanism: stages the candidate file in a temp dir under the filename
# the exercise's tests.bats expects, then runs bats with
# KATA_SOL_DIR pointing at the temp dir.
#
# Note: for multi-implementation exercises (3, 13, 16, 22) the candidate
# is staged as the first reference-solution filename only. The other
# implementations still come from docs/NN-slug/solutions/.

set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  cat >&2 <<'USAGE'
usage: run-buggy.sh NN [PATH]

  NN     exercise number (1..26)
  PATH   candidate file to test; defaults to docs/NN-slug/buggy.sh
USAGE
  exit 2
}

(( $# >= 1 )) || usage
ex=$1
src=${2:-}

ex_padded=$(printf '%02d' "$ex" 2>/dev/null) || ex_padded=$ex
ex_dir=$(find docs -maxdepth 1 -type d -name "${ex_padded}-*" -print -quit)
[[ -n $ex_dir && -d $ex_dir ]] || { echo "exercise not found: $ex" >&2; exit 2; }

target_name=$(find "$ex_dir/solutions" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null \
              | LC_ALL=C sort | head -1)
[[ -n $target_name ]] || { echo "no reference solution in $ex_dir/solutions/" >&2; exit 2; }

src_file=${src:-$ex_dir/buggy.sh}
[[ -f $src_file ]] || { echo "no such file: $src_file" >&2; exit 2; }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Copy ALL reference solutions first (so multi-impl tests can still find
# their other variants), then overwrite the primary one with the candidate.
cp -r "$ex_dir/solutions/." "$tmpdir/"
cp -- "$src_file" "$tmpdir/$target_name"
chmod +x "$tmpdir/$target_name"

echo ">>> running ex.$ex tests with $src_file staged as $target_name" >&2
KATA_SOL_DIR=$tmpdir exec bats "$ex_dir/tests.bats"
