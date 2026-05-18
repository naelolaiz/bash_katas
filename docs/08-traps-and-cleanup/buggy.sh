#!/usr/bin/env bash
# FAILING EXERCISE — buggy safe-edit. SIX trap/cleanup/errexit bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

file=$1; shift

# Make a temp copy.
tmp=/tmp/safe-edit.$$                                            # BUG #1 (predictable, race)
cp "$file" "$tmp"
trap "rm -f $tmp" EXIT                                            # BUG #2 (no INT/TERM; unquoted in trap)

# Run the command on the temp file.
"$@" "$tmp"

# If it succeeded, replace the original.
mv "$tmp" "$file"                                                # BUG #3 (cross-fs not atomic; tmp in /tmp)

# Mode preservation? Nope.
# Cleanup is idempotent? Let's check the counter:
attempts=0
(( attempts = 0 ))                                                # BUG #4 ((( x=0 )) under set -e)

echo "done"
