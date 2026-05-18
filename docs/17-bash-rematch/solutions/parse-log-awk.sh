#!/usr/bin/env bash
# Reference (awk match()): single fork processes the whole stream.
# Trade-off: fastest for large inputs (no per-line subshell); awk regex is
# POSIX ERE, no lookarounds. Cleanest pick when input is bigger than a
# few hundred lines.

set -euo pipefail
exec awk '
  match($0, /^([0-9T:+.-]+) \[(INFO|WARN|ERROR)\] ([^[:space:]]+) id=([^[:space:]]+) took=([0-9]+)ms$/, m) {
    printf "%s\t%s\t%s\t%s\t%s\n", m[1], m[2], m[3], m[4], m[5]
    next
  }
  {
    printf "malformed: %s\n", $0 > "/dev/stderr"
    bad++
  }
  END { exit (bad > 0) }
'
