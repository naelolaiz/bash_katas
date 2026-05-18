#!/usr/bin/env bash
# Reference: produce a reproducible content manifest for DIR.
# Output: <sha256>\t<size>\t<%q-quoted relative path>  — sorted under LC_ALL=C.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

(( $# >= 1 )) || die 2 'usage: manifest.sh DIR'
dir=$1
[[ -d $dir ]] || die 2 "no such directory: $dir"

( cd "$dir" && find . -type f -print0 ) |
  while IFS= read -r -d '' rel; do
    sha=$(sha256sum -- "$dir/$rel" | cut -d' ' -f1)
    size=$(stat -c '%s' -- "$dir/$rel")
    printf '%s\t%d\t%q\n' "$sha" "$size" "$rel"
  done | LC_ALL=C sort
