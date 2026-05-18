#!/usr/bin/env bash
# Reference: wrap a command with strict signal handling.
# - SIGINT  -> kill child, clean tmpdir, exit 130
# - SIGTERM -> kill child, clean tmpdir, exit 143
# - SIGQUIT -> print state to stderr, KEEP running
# - SIGPIPE -> ignored (script survives downstream `| head -1`)
# - normal exit -> preserve child's exit code

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

tmpdir=$(mktemp -d)
child_pid=''

cleanup() {
  if [[ -n $child_pid ]] && kill -0 "$child_pid" 2>/dev/null; then
    kill "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  rm -rf "$tmpdir"
}

on_signal() {
  local sig=$1 code=$2
  cleanup
  trap - EXIT
  exit "$code"
}

on_quit() {
  printf '[run-with-cleanup] SIGQUIT received; child=%s tmpdir=%s\n' \
    "${child_pid:-none}" "$tmpdir" >&2
}

trap 'on_signal INT 130'   INT
trap 'on_signal TERM 143'  TERM
trap on_quit               QUIT
trap '' PIPE
trap cleanup               EXIT

(( $# > 0 )) || die 2 'usage: run-with-cleanup CMD [ARGS...]'

"$@" &
child_pid=$!

# wait is interruptible on bash 4.3+; loop just in case.
while :; do
  if wait "$child_pid"; then
    exit 0
  else
    rc=$?
    # wait returns >128 on signal interruption -- we want to keep waiting
    # for the child unless the child itself has exited.
    if kill -0 "$child_pid" 2>/dev/null; then
      continue
    fi
    exit "$rc"
  fi
done
