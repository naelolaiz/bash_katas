#!/usr/bin/env bash
# Exercise 14 — performance kata
#
# Summary: process 100k+ lines; benchmark naive vs builtin vs awk vs pipeline
#
# Read docs/14-performance-kata/README.md for the techniques and Break-it checklist.
# When ready, copy this file to bin/perf-kata and edit there:
#
#   cp docs/14-performance-kata/starter.sh bin/perf-kata
#
# Required: produce at least 2 distinct solutions for the same problem
# (see "The exercise" section in the README) and a short trade-off paragraph.

set -euo pipefail

# Common helpers (info/verbose/debug/err/die — see lib/log.sh).
# shellcheck source=/dev/null
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  cat >&2 <<USAGE
usage: perf-kata [options] [args...]
  see docs/14-performance-kata/README.md
USAGE
  exit 2
}

main() {
  # TODO: parse options (see ex. 5 for three styles)
  # TODO: validate inputs
  # TODO: do the work
  # TODO: emit results to stdout, logs to stderr (via info/verbose/debug)
  die 2 'not implemented yet — see docs/14-performance-kata/README.md'
}

main "$@"
