#!/usr/bin/env bash
# Reference (set -C / noclobber): mutex without `flock`.
# Trade-off: NFS-safe (unlike flock); slightly more code to detect stale
# locks after a kill -9 (since the file persists). Ship this when targeting
# NFS or environments where `flock` is unavailable.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

while [[ $# -gt 0 ]]; do
  case $1 in
    --) shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done

(( $# >= 2 )) || die 2 'usage: single-instance-noclobber LOCKFILE COMMAND [ARGS...]'
lockfile=$1; shift

acquire() {
  # `set -C` makes `>` fail if the file already exists — atomic create-or-fail.
  if (set -C; printf '%d\n' $$ > "$lockfile") 2>/dev/null; then
    return 0
  fi
  # Lock present. Check if the recorded PID is still running.
  local stale_pid
  stale_pid=$(cat "$lockfile" 2>/dev/null || true)
  if [[ -n $stale_pid ]] && kill -0 "$stale_pid" 2>/dev/null; then
    return 1
  fi
  # Stale lock — remove and retry once.
  err "stale lock from PID $stale_pid; removing"
  rm -f -- "$lockfile"
  (set -C; printf '%d\n' $$ > "$lockfile") 2>/dev/null
}

acquire || die 1 'already running'
trap 'rm -f -- "$lockfile"' EXIT
trap 'rm -f -- "$lockfile"; exit 130' INT
trap 'rm -f -- "$lockfile"; exit 143' TERM

"$@"
