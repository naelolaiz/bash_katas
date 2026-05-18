#!/usr/bin/env bash
# FAILING EXERCISE — buggy count-lines + read demos. FIVE bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

file=$1

# Count lines via while-read.
count=0
while read line; do                                              # BUG #1 (no -r, no IFS=, drops last line)
  count=$((count + 1))
done < "$file"
echo "method 1 (while read): $count"

# Count lines via mapfile.
mapfile lines < "$file"                                          # BUG #2 (no -t; \n in each element)
echo "method 2 (mapfile): ${#lines[@]}"

# `arr=($(<file))` antipattern.
arr=($(<"$file"))                                                # BUG #3 (word-split + glob)
echo "method 3 (arr=$): ${#arr[@]}"

# Read with prompt and timeout.
read -p 'continue? ' answer                                      # BUG #4 (-p stdin must be terminal; no -r)

# NUL-safe mapfile, but forgetting -d ''
find . -type f -print0 | mapfile -t files                        # BUG #5 (NUL needs -d '')
echo "files: ${#files[@]}"
