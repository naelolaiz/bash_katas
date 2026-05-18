#!/usr/bin/env bash
# FAILING EXERCISE — buggy single-instance + atomic-write. FIVE race bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

lockfile=$1; shift

# "Lock" by checking if lockfile exists. CLASSIC race.
if [ -f "$lockfile" ]; then                                       # BUG #1 (TOCTOU)
  echo "already running" >&2
  exit 1
fi
echo "$$" > "$lockfile"
trap 'rm -f "$lockfile"' EXIT                                     # BUG #2 (no INT/TERM)

# Run the command.
"$@"
status=$?

# Atomic write: regenerate /tmp/target by writing to a temp file then mv.
target=/etc/myapp/cache                                           # BUG #3 (privileged + /etc + /tmp tmp = cross-fs)
tmp=$(mktemp)                                                     # BUG #3 cont. (default /tmp)
echo "generated at $(date)" > "$tmp"
mv "$tmp" "$target"                                               # BUG #4 (cross-fs not atomic)

# Replace PID file with new PID. Two processes can race here.
echo $$ > /var/run/my-script.pid                                  # BUG #5 (no exclusive create; race)

exit "$status"
