#!/usr/bin/env bash
# Reference (grep -oP): PCRE with lookbehinds; one fork.
# Trade-off: needs grep with PCRE support (`grep -P`). Not in busybox.
# Output format mirrors the BASH_REMATCH variant for test compatibility.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

# PCRE allows look-arounds and \K (reset match start). The pipeline below
# extracts each field with one grep -oP per line; tab-joins them.
malformed=0
while IFS= read -r line; do
  ts=$(printf '%s' "$line"   | grep -oP '^[0-9T:+-]+'                || true)
  lvl=$(printf '%s' "$line"  | grep -oP '(?<=\[)(INFO|WARN|ERROR)'    || true)
  comp=$(printf '%s' "$line" | grep -oP '(?<=\] )\S+'                 || true)
  id=$(printf '%s' "$line"   | grep -oP '(?<=\bid=)\S+'               || true)
  ms=$(printf '%s' "$line"   | grep -oP '(?<=\btook=)[0-9]+(?=ms\b)' || true)
  if [[ -z $ts || -z $lvl || -z $comp || -z $id || -z $ms ]]; then
    err "malformed: $line"
    malformed=$(( malformed + 1 ))
    continue
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$lvl" "$comp" "$id" "$ms"
done

(( malformed == 0 )) || exit 1
