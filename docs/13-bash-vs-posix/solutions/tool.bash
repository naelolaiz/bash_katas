#!/usr/bin/env bash
# Reference (bash version): count (level, component) pairs from log lines.
# Uses arrays, [[ ]], (( )), declare -A, mapfile, ${var:-}.

set -euo pipefail

declare -A counts
mapfile -t lines

for line in "${lines[@]}"; do
  [[ -z $line ]] && continue
  read -r _date level component _rest <<< "$line"
  [[ -z $level || -z $component ]] && continue
  key="$level $component"
  counts["$key"]=$(( ${counts["$key"]:-0} + 1 ))
done

for key in "${!counts[@]}"; do
  printf '%s %d\n' "$key" "${counts[$key]}"
done | LC_ALL=C sort
