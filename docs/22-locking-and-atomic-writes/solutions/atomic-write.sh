#!/usr/bin/env bash
# Reference: atomically replace TARGET with stdin's content.
# Same-filesystem temp + mv (rename(2)) is atomic — readers see old or new,
# never partial.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

(( $# >= 1 )) || die 2 'usage: atomic-write TARGET'
target=$1

dir=$(dirname -- "$target")
[[ -d $dir ]] || die 2 "no such directory: $dir"

tmp=$(mktemp "$dir/.$(basename -- "$target").XXXXXX")
trap 'rm -f -- "$tmp"' EXIT

cat > "$tmp"

# Preserve mode of an existing target, if any.
if [[ -e $target ]]; then
  chmod --reference="$target" -- "$tmp" 2>/dev/null || true
fi

mv -- "$tmp" "$target"
