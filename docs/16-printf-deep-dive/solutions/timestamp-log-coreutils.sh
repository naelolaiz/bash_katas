#!/usr/bin/env bash
# Reference (coreutils): one fork per line via GNU date.
# Slowest for large inputs (N forks), but no awk/perl, no bash-specific %(...)T.

set -euo pipefail

while IFS=$'\t' read -r ts msg; do
  [[ -z $ts ]] && continue
  iso=$(date -d "@$ts" '+%Y-%m-%dT%H:%M:%S%z')
  printf '%s\t%s\n' "$iso" "$msg"
done
