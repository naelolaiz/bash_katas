#!/usr/bin/env bash
# FAILING EXERCISE — buggy manifest-diff. FIVE bugs that break reproducibility.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

manifest() {
  local dir=$1
  # walk files, print sha + size + path
  find "$dir" -type f | while read path; do                      # BUG #1 (no -print0, no -r -d '')
    sha=$(sha256sum "$path" | cut -d' ' -f1)
    size=$(stat -c '%s' "$path")
    mtime=$(stat -c '%Y' "$path")                                 # BUG #2 (mtime in manifest)
    echo "$sha $size $mtime $path"                                # BUG #3 (echo, unquoted path)
  done | sort                                                     # BUG #4 (no LC_ALL=C)
}

old=$1; new=$2

# diff the two manifests
if diff -u <(manifest "$old") <(manifest "$new"); then           # BUG #5 (exit code under set -e)
  echo "same"
  exit 0
else
  echo "different"
  exit 1
fi
