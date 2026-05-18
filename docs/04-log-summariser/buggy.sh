#!/usr/bin/env bash
# FAILING EXERCISE — buggy log-count. SIX bugs from BashPitfalls + ex. 4 README.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

declare -A counts
while read date level component msg; do                          # BUG #1 (no -r, no IFS=)
  [ -z "$level" ] && continue                                    # BUG #2 ([ ] vs [[ ]])
  key="$level $component"
  counts[$key]=$((counts[$key] + 1))                             # BUG #3 (unset key under set -u)
done

# print results, ALMOST sorted but missing LC_ALL=C so output varies by locale
for key in "${!counts[@]}"; do
  printf '%s %d\n' $key ${counts[$key]}                          # BUG #4 (unquoted $key)
done | sort                                                       # BUG #5 (no LC_ALL=C)

# done!
if [ $? -eq 0 ]; then                                            # BUG #6 ($? after pipeline)
  exit 0
fi
