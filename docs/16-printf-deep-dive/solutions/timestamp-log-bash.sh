#!/usr/bin/env bash
# Reference (pure-bash): read <unix_ts>\t<msg> on stdin, emit <ISO>\t<msg>.
# Zero forks per line — uses `printf '%(...)T'` (bash 4.2+).

set -euo pipefail

while IFS=$'\t' read -r ts msg; do
  [[ -z $ts ]] && continue
  printf '%(%Y-%m-%dT%H:%M:%S%z)T\t%s\n' "$ts" "$msg"
done
