#!/usr/bin/env bash
# FAILING EXERCISE — buggy runlog. FIVE FD/redirection bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

logfile=$1; shift

# Run COMMAND with stdout+stderr to logfile AND terminal.
"$@" 2>&1 > "$logfile" | tee -a "$logfile"                       # BUG #1 (order, double-write)

# Get the command's exit status... or do we?
status=$?                                                         # BUG #2 (tee's status, not cmd's)

echo "command exited with $status" >&2
exit $status
