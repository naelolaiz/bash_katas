#!/usr/bin/env bash
# Reference: count lines four ways. Usage: count-lines [--method wc|mapfile|while|awk] FILE

set -euo pipefail

method='wc'
while [[ $# -gt 0 ]]; do
  case $1 in
    --method) method=$2; shift 2 ;;
    *) break ;;
  esac
done
if (( $# < 1 )); then echo 'usage: count-lines [--method M] FILE' >&2; exit 2; fi
file=$1

case $method in
  wc)
    wc -l < "$file" | tr -d ' '
    ;;
  mapfile)
    mapfile -t lines < "$file"
    echo "${#lines[@]}"
    ;;
  while)
    n=0
    # `|| [[ -n $line ]]` catches a final line without trailing newline
    while IFS= read -r line || [[ -n $line ]]; do
      n=$(( n + 1 ))
    done < "$file"
    echo "$n"
    ;;
  awk)
    awk 'END { print NR }' "$file"
    ;;
  *)
    echo "unknown method: $method" >&2; exit 2
    ;;
esac
