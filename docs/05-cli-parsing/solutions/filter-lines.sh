#!/usr/bin/env bash
# Reference solution for exercise 5 (filter-lines).
# Implementation: bash builtin `getopts` (short options only).
#
# Exit codes:
#   0 — at least one line matched
#   1 — no matches
#   2 — usage error

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

usage() {
  cat >&2 <<'USAGE'
usage: filter-lines [-i] [-v] [-n LIMIT] PATTERN [FILE...]
  -i        case-insensitive match
  -v        invert match
  -n LIMIT  stop after LIMIT matches
USAGE
  exit 2
}

ci=0; invert=0; limit=0
while getopts ':ivn:' opt; do
  case "$opt" in
    i) ci=1 ;;
    v) invert=1 ;;
    n) limit=$OPTARG ;;
    :) printf 'option -%s requires an argument\n' "$OPTARG" >&2; exit 2 ;;
    \?) printf 'unknown option: -%s\n' "$OPTARG" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

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
  case $rc in
    1) exit 1 ;;   # no matches
    *) exit "$rc" ;;
  esac
fi
