#!/usr/bin/env bash
# Reference solution for exercise 3 — pure parameter expansion variant.
# See docs/03-path-components/README.md.
#
# Trade-off: zero forks per path. Fastest at scale. Slightly cryptic if
# you're not fluent in `${x##*/}` etc. Ship this for any hot path or
# anything called in a loop more than a few times.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

usage() {
  cat >&2 <<'USAGE'
usage: pathinfo-pe PATH [PATH...]
  emit dir/base/stem/ext for each path, via parameter expansion only
USAGE
  exit 2
}

(( $# > 0 )) || usage

for path in "$@"; do
  # Extract basename first, then derive ext/stem from it — never from $path
  # (a dot in a parent directory but not in the basename breaks the naive form).
  base=${path##*/}
  if [[ "$base" == "$path" ]]; then
    # no slash in input -> dirname is "."
    dir='.'
  else
    dir=${path%/*}
    # leading-slash edge case: "/foo" -> dir should be "/", not ""
    [[ -z "$dir" ]] && dir='/'
  fi

  if [[ "$base" == *.* && "$base" != .* ]]; then
    # has a non-leading dot -> normal extension
    ext=${base##*.}
    stem=${base%.*}
  else
    # no extension, OR leading-dot file like ".hidden" (no real extension)
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
