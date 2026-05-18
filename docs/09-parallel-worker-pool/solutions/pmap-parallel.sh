#!/usr/bin/env bash
# Reference (GNU parallel): bookkeeping built in.
# Trade-off: extra dependency (perl + GNU parallel), but `--keep-order`,
# `--tag`, `--halt` policies, and progress meters come for free.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

jobs=4
keep_order=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -j) jobs=$2; shift 2 ;;
    --keep-order) keep_order=1; shift ;;
    --) shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done
(( $# >= 1 )) || die 2 'usage: pmap-parallel [-j N] [--keep-order] COMMAND ARG...'
cmd=$1; shift

command -v parallel >/dev/null || die 2 'GNU parallel not installed'

# shellcheck disable=SC2054  # comma is part of GNU parallel's --halt value
opts=(--jobs "$jobs" --halt now,fail=1)
(( keep_order )) && opts+=(--keep-order)

# `--null` makes parallel read NUL-separated input — safe for any argument.
printf '%s\0' "$@" | parallel --null "${opts[@]}" -- "$cmd" {}
