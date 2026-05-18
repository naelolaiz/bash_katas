#!/usr/bin/env bash
# FAILING EXERCISE — buggy debug-runner. FIVE bugs around debug-channel hygiene.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

debug=0; verbose=0; dry_run=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug)   debug=1;   shift ;;
    --verbose) verbose=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    *) break ;;
  esac
done

PS4='+ $(date +%T): '                                            # BUG #1 (forks date per traced line)
(( debug )) && set -x

run() {
  if (( dry_run )); then
    echo "DRY: $*"                                                # BUG #2 (echo, no %q)
  else
    "$@"
  fi
}

# A "verbose" log function that goes to STDOUT.
log() {
  (( verbose )) && echo "[verbose] $*"                            # BUG #3 (stdout, not stderr)
}

log "starting"
run rm -rf "$1"
log "done"

# Debug output piped through a regular command that doesn't expect it:
echo "result: $1"                                                 # BUG #4 (set -x output pollutes stdout)

# trace going to /dev/stderr forever, no way to turn it off mid-script
# BUG #5: no BASH_XTRACEFD redirection to a separate file
