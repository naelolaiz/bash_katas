#!/usr/bin/env bash
# Reference solution for exercise 1 (Expansion prediction lab).
# See docs/01-expansion-prediction/README.md.
#
# Usage:
#   expand-lab [--quoted|--direct] PATH [PATH...]
#
# Two output modes (the "two implementations" requirement):
#   --direct  : printf '%s\n' of each expansion (default)
#   --quoted  : printf '%q\n' (or ${var@Q}) so each value is unambiguous

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

usage() {
  cat >&2 <<'USAGE'
usage: expand-lab [--quoted|--direct] PATH [PATH...]
  --direct   one printf %s per expansion (default; ambiguous on weird paths)
  --quoted   one printf %q per expansion (unambiguous)
USAGE
  exit 2
}

mode=direct
args=()
while (( $# > 0 )); do
  case "$1" in
    --direct) mode=direct;  shift ;;
    --quoted) mode=quoted;  shift ;;
    -h|--help) usage ;;
    --) shift; args+=("$@"); break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  args+=("$1"); shift ;;
  esac
done

(( ${#args[@]} > 0 )) || usage

emit() {
  local label=$1 value=$2
  if [[ $mode == quoted ]]; then
    # ${var@Q} is bash 4.4+; printf %q works everywhere.
    printf '  %-8s = %q\n' "$label" "$value"
  else
    printf '  %-8s = %s\n' "$label" "$value"
  fi
}

for path in "${args[@]}"; do
  printf 'path: %q\n' "$path"
  emit base   "${path##*/}"
  emit dir    "${path%/*}"
  emit ext    "${path##*.}"
  emit stem   "${path%.*}"
  emit upper  "${path^^}"
  emit lower  "${path,,}"
  emit length "${#path}"
  emit Qform  "${path@Q}"
  printf '\n'
done
