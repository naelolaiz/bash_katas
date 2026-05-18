#!/usr/bin/env bash
# Reference (named FDs): explicit FD management instead of process substitution.
# Trade-off: more verbose; PIPESTATUS is straightforward; no async cleanup.
# Useful when finer control over FD lifetimes is needed.

set -euo pipefail
set -o pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

quiet=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --quiet) quiet=1; shift ;;
    --) shift; break ;;
    *)  break ;;
  esac
done

(( $# >= 1 )) || { err 'usage: runlog-namedfd [--quiet] LOGFILE CMD [ARGS...]'; exit 2; }
logfile=$1; shift
(( $# > 0 )) || { err 'command required'; exit 2; }

# Open the log on a high FD (named FD assignment is bash 4+).
exec {logfd}>>"$logfile"

# Save originals so we can still write to terminal under non-quiet mode.
exec {origout}>&1 {origerr}>&2

if (( quiet )); then
  # Send both streams only to the log. Redirect stdout to the FD, then
  # tie stderr to stdout (avoids competing redirections on stderr).
  "$@" >&"$logfd" 2>&1
  status=$?
else
  # tee semantics done by hand: write to terminal AND to logfd.
  # Easier to spawn two sub-pipelines using `tee /dev/fd/$logfd`.
  "$@" \
    >  >(tee "/dev/fd/$logfd" >&"$origout") \
    2> >(sed -u 's/^/[stderr] /' | tee "/dev/fd/$logfd" >&"$origerr")
  status=${PIPESTATUS[0]}
fi

exec {logfd}>&-
exec {origout}>&- {origerr}>&-
exit "$status"
