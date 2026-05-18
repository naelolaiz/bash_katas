#!/usr/bin/env bash
# FAILING EXERCISE — buggy timestamp-log. SIX printf bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

while IFS=$'\t' read -r ts msg; do
  # format the timestamp
  iso=$(date -d "@$ts" +%Y-%m-%dT%H:%M:%S)                       # BUG #1 (fork per line)
  echo "$iso\t$msg"                                               # BUG #2 (echo + \t literal)
done < "${1:-/dev/stdin}"

# also report the current run time
echo "ran at $(date)"                                             # BUG #3 (could be printf '%(...)T')

# safely dump a user-supplied filename
file=$1
printf "$file\n"                                                  # BUG #4 (format-string injection)

# count lines
echo "lines: \c"                                                  # BUG #5 (\c is not portable echo)
wc -l < "$1"

# print a number with thousands separator (locale-aware)
n=1234567
printf "%d\n" $n                                                  # BUG #6 (no %'d; should be quoted)
