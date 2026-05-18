#!/usr/bin/env bash
# Exercise 12 — programmable completion
#
# Summary: bash completion file for ex. 5 filter-lines
#
# Read docs/12-programmable-completion/README.md for the techniques and Break-it checklist.
# When ready, copy this file to bin/filter-lines-completion and edit there:
#
#   cp docs/12-programmable-completion/starter.sh bin/filter-lines-completion
#
# Required: produce at least 2 distinct solutions for the same problem
# (see "The exercise" section in the README) and a short trade-off paragraph.

set -euo pipefail

# Common helpers (info/verbose/debug/err/die — see lib/log.sh).
# shellcheck source=/dev/null
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  cat >&2 <<USAGE
usage: filter-lines-completion [options] [args...]
  see docs/12-programmable-completion/README.md
USAGE
  exit 2
}

main() {
  # TODO: parse options (see ex. 5 for three styles)
  # TODO: validate inputs
  # TODO: do the work
  # TODO: emit results to stdout, logs to stderr (via info/verbose/debug)
  die 2 'not implemented yet — see docs/12-programmable-completion/README.md'
}

main "$@"
