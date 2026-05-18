#!/usr/bin/env bash
# FAILING EXERCISE — buggy parallel-hash. FIVE xargs bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

dir=$1; jobs=${2:-4}

# Hash every file. BROKEN on weird filenames.
ls "$dir" | xargs sha256sum                                      # BUG #1 (ls antipattern; no -0)

# A "parallel" version that... isn't.
find "$dir" -type f | xargs -P "$jobs" -I{} sha256sum {}         # BUG #2 (-I{} + -P, but -n1 missing semantics)

# Delete .tmp files... unless there aren't any.
find "$dir" -name '*.tmp' -print0 | xargs -0 rm                  # BUG #3 (no -r; runs rm with no args)

# Process every file's first line.
find "$dir" -type f -print0 | xargs -0 head -1                   # BUG #4 (head prefixes "==> file <==" only sometimes; not really)
# (less of a bug, more a quirk — but interleave-on-parallel is real)

# Pass -n 100 too but also -P:
find "$dir" -type f | xargs -n 100 -P "$jobs" sha256sum          # BUG #5 (no -0; no -d; word-split on whitespace)
