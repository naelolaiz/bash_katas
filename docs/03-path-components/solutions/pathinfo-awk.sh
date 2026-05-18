#!/usr/bin/env bash
# Reference solution for exercise 3 — awk pipeline variant.
# See docs/03-path-components/README.md.
#
# Trade-off: 1 fork TOTAL regardless of input size — wins at scale (10k+
# paths). Hardest to read. Ship this when you're already in a pipeline of
# column-shaped data, or when input size makes per-path forks expensive.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

usage() {
  cat >&2 <<'USAGE'
usage: pathinfo-awk PATH [PATH...]
  emit dir/base/stem/ext for each path, via one awk invocation
USAGE
  exit 2
}

(( $# > 0 )) || usage

printf '%s\n' "$@" | awk '
function dirname(p,    n, parts) {
  n = split(p, parts, "/")
  if (n == 1)              return "."
  if (n == 2 && parts[1] == "") return "/"
  if (parts[n] == "")      n -= 1   # trailing slash
  # rebuild without the last component
  out = parts[1]
  for (i = 2; i < n; i++) out = out "/" parts[i]
  return (out == "") ? "/" : out
}

function basename(p,    n, parts) {
  n = split(p, parts, "/")
  if (parts[n] == "" && n > 1) return parts[n - 1]   # trailing slash
  return parts[n]
}

{
  path = $0
  base = basename(path)
  dir  = dirname(path)

  # leading-dot files have no real extension
  if (base ~ /\./ && base !~ /^\./) {
    nparts = split(base, parts, ".")
    ext = parts[nparts]
    stem = parts[1]
    for (i = 2; i < nparts; i++) stem = stem "." parts[i]
  } else {
    ext = ""
    stem = base
  }

  printf "original=%s\n", path
  printf "dir=%s\n",      dir
  printf "base=%s\n",     base
  printf "stem=%s\n",     stem
  printf "ext=%s\n",      ext
  print ""
}
'
