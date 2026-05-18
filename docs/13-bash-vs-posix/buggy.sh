#!/bin/sh
# FAILING EXERCISE — claims to be POSIX (#!/bin/sh) but uses many bashisms.
# Run it under `dash` or `ash` and watch it fail.
#
# FIVE bashisms hidden in code that LOOKS portable.

# shellcheck shell=sh

set -eu     # no pipefail in POSIX sh!

# Read pairs and store in an "associative array".
declare -A counts                                                 # BUG #1 (bashism)

while IFS= read -r line; do
  [[ -z "$line" ]] && continue                                    # BUG #2 ([[ ]] bashism)
  read level component <<< "$line"                                # BUG #3 (here-string bashism)
  counts[$level]=$((${counts[$level]:-0} + 1))
done

# substring extraction
prefix=${1:0:5}                                                   # BUG #4 (bashism)
echo "prefix: $prefix"

# arrays
files=( /etc/*.conf )                                             # BUG #5 (bash arrays)
echo "config count: ${#files[@]}"

for k in "${!counts[@]}"; do
  echo "$k=${counts[$k]}"
done
