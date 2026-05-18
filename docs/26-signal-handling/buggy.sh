#!/usr/bin/env bash
# FAILING EXERCISE — buggy run-with-cleanup. FIVE signal-handling bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

tmpdir=$(mktemp -d)
echo "child started; tmpdir=$tmpdir" >&2

cleanup() {
  rm -rf "$tmpdir"
  exit                                                            # BUG #1 (exits with $? of `rm`, not the signal)
}
trap cleanup INT TERM EXIT                                        # BUG #2 (cleanup runs 3x; not idempotent)

# Run child.
"$@" &
pid=$!

# Wait for child... but Ctrl-C is not properly propagated.
wait "$pid"                                                       # BUG #3 (in old bash, not interruptible)
status=$?

# Survive SIGPIPE: but we forgot to set it up.                    # BUG #4 (no trap '' PIPE)

# Propagate as 128+N if killed by signal:
echo "child exited $status"
exit $status                                                       # BUG #5 (status is 0–255 mod; no "killed by signal" detection)
