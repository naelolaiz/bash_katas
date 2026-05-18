#!/usr/bin/env bash
# Reference: wrap a command with --quiet/--verbose/--debug/--dry-run.
# stdout from the command is preserved (this stays usable in a pipe);
# logs/traces go to stderr (or a separate FD for trace).

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

# rich PS4 — cheap (no fork) and useful when set -x is on
PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-MAIN}: '

quiet=0; verbose=0; debug=0; dry_run=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -q|--quiet)   quiet=1;   shift ;;
    -v|--verbose) verbose=1; shift ;;
    --debug)      debug=1;   shift ;;
    --dry-run)    dry_run=1; shift ;;
    --)           shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done

if (( quiet )); then
  LOG_LEVEL=0
elif (( debug )); then
  LOG_LEVEL=3
elif (( verbose )); then
  LOG_LEVEL=2
fi
export LOG_LEVEL

if (( debug )); then
  trace_file="${LOGFILE:-/dev/stderr}"
  [[ $trace_file == /dev/stderr ]] && trace_file=/dev/stderr || trace_file="${trace_file}.trace"
  exec {tracefd}>>"$trace_file"
  BASH_XTRACEFD=$tracefd
  set -x
fi

run() {
  if (( dry_run )); then
    printf 'DRY: ' >&2; printf '%q ' "$@" >&2; printf '\n' >&2
  else
    debug "running: $(printf '%q ' "$@")"
    "$@"
  fi
}

(( $# > 0 )) || die 2 'usage: debug-runner [--quiet|--verbose|--debug|--dry-run] CMD [ARGS...]'

info "starting"
run "$@"
status=$?
info "exited $status"
exit "$status"
