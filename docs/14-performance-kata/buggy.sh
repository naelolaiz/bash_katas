#!/usr/bin/env bash
# FAILING EXERCISE — perf-kata that's slow on purpose. FIVE performance bugs.
# The script "works" but is 100–1000x slower than the right form.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

file=${1:-data/generated/log-count.txt}

# Count distinct lowercase IPs (third field of access log).
count=0
declare -A seen

cat "$file" | while read -r line; do                              # BUG #1 (UUOC, subshell loses var)
  ip=$(echo "$line" | awk '{print $1}')                           # BUG #2 (fork per line)
  ip_lower=$(echo "$ip" | tr A-Z a-z)                             # BUG #3 (fork per line)
  if [[ -z "${seen[$ip_lower]:-}" ]]; then
    seen[$ip_lower]=1
    count=$((count + 1))
  fi
done

# `count` is now 0 because the while loop ran in a subshell.       BUG #1 (continued)
echo "distinct: $count"

# Time it... but only times cat:
time cat "$file" | wc -l                                          # BUG #4 (time measures cat, not pipeline)

# Last line touches strace:
# (intentionally none — exercise spec asks for it; BUG #5: no strace -c)
