#!/usr/bin/env bash
# Exercise 25 — heredocs and quoting
#
# Summary: substitute $VAR/${VAR}/${VAR:-default} in a template file
#
# Read docs/25-heredocs-and-quoting/README.md for the techniques and Break-it checklist.
# When ready, copy this file to bin/template and edit there:
#
#   cp docs/25-heredocs-and-quoting/starter.sh bin/template
#
# Required: produce at least 2 distinct solutions for the same problem
# (see "The exercise" section in the README) and a short trade-off paragraph.

set -euo pipefail

# Common helpers (info/verbose/debug/err/die — see lib/log.sh).
# shellcheck source=/dev/null
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  cat >&2 <<USAGE
usage: template [options] [args...]
  see docs/25-heredocs-and-quoting/README.md
USAGE
  exit 2
}

main() {
  # TODO: parse options (see ex. 5 for three styles)
  # TODO: validate inputs
  # TODO: do the work
  # TODO: emit results to stdout, logs to stderr (via info/verbose/debug)
  die 2 'not implemented yet — see docs/25-heredocs-and-quoting/README.md'
}

main "$@"
