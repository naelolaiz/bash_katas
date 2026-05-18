#!/usr/bin/env bash
# Exercise 24 — arithmetic gotchas
#
# Summary: parse /proc/uptime; report days/hours/minutes + idle %
#
# Read docs/24-arithmetic-gotchas/README.md for the techniques and Break-it checklist.
# When ready, copy this file to bin/uptime-summary and edit there:
#
#   cp docs/24-arithmetic-gotchas/starter.sh bin/uptime-summary
#
# Required: produce at least 2 distinct solutions for the same problem
# (see "The exercise" section in the README) and a short trade-off paragraph.

set -euo pipefail

# Common helpers (info/verbose/debug/err/die — see lib/log.sh).
# shellcheck source=/dev/null
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  cat >&2 <<USAGE
usage: uptime-summary [options] [args...]
  see docs/24-arithmetic-gotchas/README.md
USAGE
  exit 2
}

main() {
  # TODO: parse options (see ex. 5 for three styles)
  # TODO: validate inputs
  # TODO: do the work
  # TODO: emit results to stdout, logs to stderr (via info/verbose/debug)
  die 2 'not implemented yet — see docs/24-arithmetic-gotchas/README.md'
}

main "$@"
