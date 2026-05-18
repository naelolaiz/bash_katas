#!/usr/bin/env bash
# FAILING EXERCISE — buggy version of collect-ext. There are SIX bugs.
# All six trace to BashPitfalls / the README's "Break it" section.
#
# Your job: find and fix them. Hints in hints.md if you get stuck.
# Verify with `bats docs/02-nul-safe-collector/tests.bats`.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  echo "usage: collect-ext [--nul] [--source find|glob|git] EXT DIR" >&2
  exit 2
}

emit() {
  local p
  for p in $@; do                                                # BUG
    if [[ $nul == 1 ]]; then
      printf '%s\0' $p                                           # BUG
    else
      echo $p                                                    # BUG
    fi
  done
}

source_find() {
  local ext=$1 dir=$2
  find $dir -type f -name "*.$ext" | while read path; do         # BUG (two on one line)
    emit "$path"
  done
}

source_glob() {
  local ext=$1 dir=$2
  shopt -s globstar
  # forgot nullglob — empty match expands to literal pattern
  local files=("$dir"/**/*."$ext")                               # BUG (missing nullglob)
  emit "${files[@]}"
}

source_git() {
  local ext=$1 dir=$2
  cd "$dir" || exit 1
  for f in $(git ls-files "*.$ext"); do                          # BUG
    emit "$dir/$f"
  done
}

# --- option parsing ---
nul=0
backend='find'
positional=()
while (( $# > 0 )); do
  case "$1" in
    --nul)    nul=1; shift ;;
    --source) backend=$2; shift 2 ;;
    -h|--help) usage ;;
    -*) die 2 "unknown option: $1" ;;
    *)  positional+=("$1"); shift ;;
  esac
done

(( ${#positional[@]} == 2 )) || usage
ext=${positional[0]}
dir=${positional[1]}

case "$ext" in
  */*) die 2 "EXT may not contain '/': $ext" ;;
  '')  die 2 "EXT may not be empty" ;;
esac

[[ -d "$dir" ]] || die 2 "no such directory: $dir"

case "$backend" in
  'find') source_find "$ext" "$dir" ;;
  'glob') source_glob "$ext" "$dir" ;;
  'git')  source_git  "$ext" "$dir" ;;
  *)      die 2 "unknown source: $backend" ;;
esac
