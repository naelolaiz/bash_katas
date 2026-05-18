#!/usr/bin/env bash
# Reference (awk): single fork, fastest at scale.
# Trade-off: ~10× faster than the bash assoc-array variant at 10⁵+ lines;
# loses bash's conditional dispatch on weird inputs. Ship this for log
# files larger than a few thousand lines.

set -euo pipefail

# `awk` reads stdin natively; the `END` block sorts and emits.
awk '
  /^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
    key = $2 " " $3
    c[key]++
    next
  }
  NF > 0 {
    bad++
    printf("malformed line: %s\n", $0) > "/dev/stderr"
  }
  END {
    for (k in c) print k, c[k]
    exit (bad > 0)
  }
' | LC_ALL=C sort
