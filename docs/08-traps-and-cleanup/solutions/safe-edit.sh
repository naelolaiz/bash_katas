#!/usr/bin/env bash
# Reference: safe-edit FILE COMMAND [ARGS...].
# Copies FILE to a temp on the same fs; runs COMMAND on the temp; if it
# succeeds, atomically replaces FILE preserving mode/ownership/timestamps.
# Cleans up on EXIT/INT/TERM.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

(( $# >= 1 )) || die 2 'usage: safe-edit FILE COMMAND [ARGS...]'
file=$1; shift
(( $# > 0 )) || die 2 'COMMAND required'
[[ -e $file ]] || die 2 "no such file: $file"

# Temp must be on the same filesystem as $file so mv is atomic.
tmpdir=$(mktemp -d "$(dirname -- "$file")/.safe-edit.XXXXXX")
# shellcheck disable=SC2317  # called via trap
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

tmp="$tmpdir/$(basename -- "$file")"
cp --preserve=mode,ownership,timestamps -- "$file" "$tmp"

if "$@" "$tmp"; then
  mv -- "$tmp" "$file"
  exit 0
else
  rc=$?
  err "command exited $rc; original untouched"
  exit "$rc"
fi
