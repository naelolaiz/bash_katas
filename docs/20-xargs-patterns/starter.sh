#!/usr/bin/env bash
# Exercise 20 — xargs patterns
#
# Summary: hash every regular file under DIR in parallel
#
# Read docs/20-xargs-patterns/README.md for the techniques and Break-it checklist.
# When ready, copy this file to bin/parallel-hash and edit there:
#
#   cp docs/20-xargs-patterns/starter.sh bin/parallel-hash
#
# Required: produce at least 2 distinct solutions for the same problem
# (see "The exercise" section in the README) and a short trade-off paragraph.

set -euo pipefail

# Common helpers (info/verbose/debug/err/die — see lib/log.sh).
# shellcheck source=/dev/null
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  cat >&2 <<USAGE
usage: parallel-hash [options] [args...]
  see docs/20-xargs-patterns/README.md
USAGE
  exit 2
}

main() {
  # TODO: parse options (see ex. 5 for three styles)
  # TODO: validate inputs
  # TODO: do the work
  # TODO: emit results to stdout, logs to stderr (via info/verbose/debug)
  die 2 'not implemented yet — see docs/20-xargs-patterns/README.md'
}

main "$@"
