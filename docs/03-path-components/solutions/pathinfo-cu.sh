#!/usr/bin/env bash
# Reference solution for exercise 3 — coreutils variant.
# See docs/03-path-components/README.md.
#
# Trade-off: 2 forks per path (dirname + basename). Most readable for
# someone not fluent in bash parameter expansion. Ship this for one-shot
# scripts where clarity beats throughput.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

usage() {
  cat >&2 <<'USAGE'
usage: pathinfo-cu PATH [PATH...]
  emit dir/base/stem/ext for each path, via dirname/basename
USAGE
  exit 2
}

(( $# > 0 )) || usage

for path in "$@"; do
  dir=$(dirname  -- "$path")
  base=$(basename -- "$path")

  if [[ "$base" == *.* && "$base" != .* ]]; then
    ext=${base##*.}
    # GNU basename has -s SUFFIX for stripping, but it's GNU-only.
    # Portable: strip via parameter expansion (one small cheat).
    stem=${base%.*}
  else
    ext=''
    stem=$base
  fi

  printf 'original=%s\n' "$path"
  printf 'dir=%s\n'      "$dir"
  printf 'base=%s\n'     "$base"
  printf 'stem=%s\n'     "$stem"
  printf 'ext=%s\n'      "$ext"
  printf '\n'
done
