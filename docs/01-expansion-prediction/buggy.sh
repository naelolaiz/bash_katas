#!/usr/bin/env bash
# FAILING EXERCISE — buggy version of expand-lab. There are FIVE bugs.
# All five trace to entries in the README's "Gotcha" or "Break it" sections.
#
# Your job: find and fix them. Hints in hints.md if you get stuck.
# Verify with `bats docs/01-expansion-prediction/tests.bats`.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  echo "usage: expand-lab [--quoted|--direct] PATH [PATH...]" >&2
  exit 2
}

mode=direct
args=()
for arg in $@; do                                                 # BUG
  case "$arg" in
    --direct) mode=direct ;;
    --quoted) mode=quoted ;;
    -h|--help) usage ;;
    *) args+=("$arg") ;;
  esac
done

[[ ${#args[@]} -gt 0 ]] || usage

emit() {
  local label=$1 value=$2
  if [[ $mode == quoted ]]; then
    printf '  %-8s = %q\n' $label $value                          # BUG
  else
    echo "  $label = $value"                                      # BUG
  fi
}

for path in ${args[@]}; do                                        # BUG
  echo "path: $path"
  emit base   "${path##*/}"
  emit dir    "${path%/*}"
  emit ext    "${path%.*}"                                        # BUG
  emit stem   "${path%.*}"
  emit length "${#path}"
  emit Qform  "${path@Q}"
  echo
done
