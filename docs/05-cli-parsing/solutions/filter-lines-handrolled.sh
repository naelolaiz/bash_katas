#!/usr/bin/env bash
# Reference (hand-rolled): no external `getopt`, no `getopts`. Supports
# both `-n 10` and `--limit=10` forms.
# Trade-off: most flexible; works in any POSIX-compatible shell with `[[ ]]`
# replaced by `[ ]`. Slightly more verbose than `getopts`.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

usage() {
  cat >&2 <<'USAGE'
usage: filter-lines [-i|--ignore-case] [-v|--invert]
                    [-n|--limit LIMIT] [--limit=LIMIT] PATTERN [FILE...]
USAGE
  exit 2
}

ci=0; invert=0; limit=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--ignore-case) ci=1; shift ;;
    -v|--invert)      invert=1; shift ;;
    -n|--limit)       [[ $# -ge 2 ]] || die 2 "$1 requires an argument"
                      limit=$2; shift 2 ;;
    --limit=*)        limit=${1#*=}; shift ;;
    --) shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done

(( $# >= 1 )) || usage
pattern=$1; shift
[[ $# -gt 0 ]] || set -- -

grep_opts=()
(( ci ))     && grep_opts+=(-i)
(( invert )) && grep_opts+=(-v)
(( limit > 0 )) && grep_opts+=(-m "$limit")

if grep "${grep_opts[@]}" -e "$pattern" -- "$@"; then
  exit 0
else
  rc=$?
  case $rc in 1) exit 1 ;; *) exit "$rc" ;; esac
fi
