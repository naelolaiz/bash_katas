#!/usr/bin/env bash
# Reference (comm): set-diff variant of manifest-diff.
# Reports added/removed/common counts plus the file paths in each set.
# Trade-off vs. the diff-based variant: cleaner output for "what changed";
# loses unified-diff context around mismatches. Pick this when only the
# membership delta matters.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

(( $# >= 2 )) || die 2 'usage: manifest-diff-comm.sh OLD NEW'
old=$1; new=$2
[[ -d $old && -d $new ]] || die 2 'OLD and NEW must be directories'

manifest=$(dirname "$0")/manifest.sh

# comm needs identically-sorted input on both sides. manifest.sh already
# sorts under LC_ALL=C, so the streams are aligned.
added=$(  comm -13 <("$manifest" "$old") <("$manifest" "$new") | wc -l)
removed=$(comm -23 <("$manifest" "$old") <("$manifest" "$new") | wc -l)
common=$( comm -12 <("$manifest" "$old") <("$manifest" "$new") | wc -l)

printf 'added=%d removed=%d common=%d\n' "$added" "$removed" "$common"

if (( added + removed == 0 )); then
  exit 0
fi

if (( added > 0 )); then
  printf '\n--- added (in NEW only) ---\n'
  comm -13 <("$manifest" "$old") <("$manifest" "$new")
fi
if (( removed > 0 )); then
  printf '\n--- removed (in OLD only) ---\n'
  comm -23 <("$manifest" "$old") <("$manifest" "$new")
fi

exit 1
