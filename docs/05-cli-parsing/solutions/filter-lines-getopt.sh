#!/usr/bin/env bash
# Reference (GNU getopt): long options + short options together.
# Trade-off: long-option support, but **GNU-specific** — BSD/macOS `getopt`
# is incompatible. Only ship this when targeting Linux.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

usage() {
  cat >&2 <<'USAGE'
usage: filter-lines [-i|--ignore-case] [-v|--invert]
                    [-n|--limit LIMIT] PATTERN [FILE...]
USAGE
  exit 2
}

# `getopt --test` returns 4 on a sane GNU getopt; anything else is the BSD form.
if ! getopt --test >/dev/null; then
  die 2 'GNU getopt required (BSD getopt is incompatible)'
fi

parsed=$(getopt \
  --options='ivn:' \
  --longoptions='ignore-case,invert,limit:' \
  --name='filter-lines' \
  -- "$@") || exit 2
eval set -- "$parsed"

ci=0; invert=0; limit=0
while true; do
  case "$1" in
    -i|--ignore-case) ci=1; shift ;;
    -v|--invert)      invert=1; shift ;;
    -n|--limit)       limit=$2; shift 2 ;;
    --) shift; break ;;
    *)  die 2 "parser bug at: $1" ;;
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
