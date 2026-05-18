#!/usr/bin/env bash
# Exercise 17 — bash rematch
#
# Summary: parse structured log lines with [[ =~ ]] + BASH_REMATCH
#
# Read docs/17-bash-rematch/README.md for the techniques and Break-it checklist.
# When ready, copy this file to bin/parse-log and edit there:
#
#   cp docs/17-bash-rematch/starter.sh bin/parse-log
#
# Required: produce at least 2 distinct solutions for the same problem
# (see "The exercise" section in the README) and a short trade-off paragraph.

set -euo pipefail

# Common helpers (info/verbose/debug/err/die — see lib/log.sh).
# shellcheck source=/dev/null
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  cat >&2 <<USAGE
usage: parse-log [options] [args...]
  see docs/17-bash-rematch/README.md
USAGE
  exit 2
}

main() {
  # TODO: parse options (see ex. 5 for three styles)
  # TODO: validate inputs
  # TODO: do the work
  # TODO: emit results to stdout, logs to stderr (via info/verbose/debug)
  die 2 'not implemented yet — see docs/17-bash-rematch/README.md'
}

main "$@"
