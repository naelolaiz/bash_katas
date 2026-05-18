#!/usr/bin/env bash
# Reference (coreutils pipeline): no awk, no bash assoc-array.
# Trade-off: O(n log n) instead of O(n), but `sort` spills to disk gracefully
# at unbounded scale. The classic Unix-toolset approach. Ship this when an
# `awk` dependency is undesired.

set -euo pipefail

# 1. drop blanks and malformed lines (anything not starting with a date)
# 2. emit "<level> <component>" per accepted line
# 3. sort + count adjacent runs
# 4. reformat: "<level> <component> <count>"
grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2} ' \
  | awk '{ print $2, $3 }' \
  | LC_ALL=C sort \
  | uniq -c \
  | awk '{ printf "%s %s %d\n", $2, $3, $1 }' \
  | LC_ALL=C sort
