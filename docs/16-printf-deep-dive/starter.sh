#!/usr/bin/env bash
# Exercise 16 — printf deep dive
#
# Summary: read <unix_ts>\\t<msg> on stdin, print <ISO-8601>\\t<msg>
#
# Read docs/16-printf-deep-dive/README.md for the techniques and Break-it checklist.
# When ready, copy this file to bin/timestamp-log and edit there:
#
#   cp docs/16-printf-deep-dive/starter.sh bin/timestamp-log
#
# Required: produce at least 2 distinct solutions for the same problem
# (see "The exercise" section in the README) and a short trade-off paragraph.

set -euo pipefail

# Common helpers (info/verbose/debug/err/die — see lib/log.sh).
# shellcheck source=/dev/null
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  cat >&2 <<USAGE
usage: timestamp-log [options] [args...]
  see docs/16-printf-deep-dive/README.md
USAGE
  exit 2
}

main() {
  # TODO: parse options (see ex. 5 for three styles)
  # TODO: validate inputs
  # TODO: do the work
  # TODO: emit results to stdout, logs to stderr (via info/verbose/debug)
  die 2 'not implemented yet — see docs/16-printf-deep-dive/README.md'
}

main "$@"
