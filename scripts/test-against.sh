#!/usr/bin/env bash
# Run the Bats suite (all exercises, or one) with $KATA_SOL_DIR pointed
# at a directory containing the candidate implementations.
#
# Each per-exercise tests.bats resolves its solution paths as:
#   ${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/<file>.sh
# so KATA_SOL_DIR overrides the default reference solutions.
#
# Usage:
#   scripts/test-against.sh DIR              # run every exercise's tests
#   scripts/test-against.sh DIR NN           # run only exercise NN's tests
#   scripts/test-against.sh DIR NN-slug      # full slug also works

set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  cat >&2 <<'USAGE'
usage: test-against.sh DIR [EXERCISE]

  DIR        directory containing candidate implementations (same filenames
             as docs/NN-slug/solutions/*.sh)
  EXERCISE   optional: NN (e.g. 09) or NN-slug (e.g. 09-parallel-worker-pool)

Examples:
  scripts/test-against.sh bin                          # all tests, bin/ as solutions
  scripts/test-against.sh bin 09                       # only ex.9
  scripts/test-against.sh docs/09-parallel-worker-pool 09
USAGE
  exit 2
}

(( $# >= 1 )) || usage
dir=$1
[[ -d $dir ]] || { echo "no such directory: $dir" >&2; exit 2; }

export KATA_SOL_DIR
KATA_SOL_DIR=$(cd "$dir" && pwd)

if (( $# >= 2 )); then
  ex=$2
  # Accept either "NN" or "NN-slug".
  if [[ $ex =~ ^[0-9]+$ ]]; then
    ex=$(printf '%02d' "$ex")
    match=$(find docs -maxdepth 1 -type d -name "${ex}-*" -print -quit)
  else
    match="docs/$ex"
  fi
  [[ -n $match && -d $match ]] || { echo "exercise not found: $2" >&2; exit 2; }
  exec bats "$match/tests.bats"
fi

# All exercises.
find docs -name 'tests.bats' -print0 | xargs -0 -r bats
