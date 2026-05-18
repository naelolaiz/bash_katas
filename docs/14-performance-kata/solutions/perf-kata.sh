#!/usr/bin/env bash
# Reference: process N lines four ways, measure each.
# Task: count distinct values of the 3rd whitespace field, lowercased.
#
# Usage: perf-kata.sh --mode {naive|builtin|awk|pipeline} FILE

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

mode=builtin
while [[ $# -gt 0 ]]; do
  case $1 in
    --mode) mode=$2; shift 2 ;;
    *) break ;;
  esac
done
(( $# >= 1 )) || die 2 'usage: perf-kata.sh --mode MODE FILE'
file=$1

# A. naive: external command per line (slow)
naive() {
  declare -A seen
  local count=0 line f
  while read -r line; do
    f=$(echo "$line" | awk '{print $3}')
    f=$(echo "$f" | tr '[:upper:]' '[:lower:]')
    if [[ -z ${seen[$f]+x} ]]; then
      seen[$f]=1
      count=$(( count + 1 ))
    fi
  done < "$file"
  echo "$count"
}

# B. builtin: parameter expansion + bash assoc-array (fastest pure-bash)
builtin_() {
  declare -A seen
  local _a _b f count=0
  while read -r _a _b f _; do
    if [[ -z ${seen[${f,,}]+x} ]]; then
      seen[${f,,}]=1
      count=$(( count + 1 ))
    fi
  done < "$file"
  echo "$count"
}

# C. one awk (recommended once N exceeds ~10^4)
awk_() {
  awk '{ k = tolower($3); seen[k]=1 } END { print length(seen) }' "$file"
}

# D. coreutils pipeline (disk-friendly at any scale)
pipeline() {
  awk '{ print $3 }' "$file" | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u | wc -l
}

case $mode in
  naive)    naive ;;
  builtin)  builtin_ ;;
  awk)      awk_ ;;
  pipeline) pipeline ;;
  *) die 2 "unknown mode: $mode (want naive|builtin|awk|pipeline)" ;;
esac
