#!/usr/bin/env bash
# Exercise 13 — bash vs posix
#
# Summary: same tool in two scripts: tool.bash and tool.sh (POSIX)
#
# Read docs/13-bash-vs-posix/README.md for the techniques and Break-it checklist.
# When ready, copy this file to bin/tool and edit there:
#
#   cp docs/13-bash-vs-posix/starter.sh bin/tool
#
# Required: produce at least 2 distinct solutions for the same problem
# (see "The exercise" section in the README) and a short trade-off paragraph.

set -euo pipefail

# Common helpers (info/verbose/debug/err/die — see lib/log.sh).
# shellcheck source=/dev/null
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  cat >&2 <<USAGE
usage: tool [options] [args...]
  see docs/13-bash-vs-posix/README.md
USAGE
  exit 2
}

main() {
  # TODO: parse options (see ex. 5 for three styles)
  # TODO: validate inputs
  # TODO: do the work
  # TODO: emit results to stdout, logs to stderr (via info/verbose/debug)
  die 2 'not implemented yet — see docs/13-bash-vs-posix/README.md'
}

main "$@"
