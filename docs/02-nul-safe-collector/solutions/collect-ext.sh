#!/usr/bin/env bash
# Reference solution for exercise 2 (NUL-safe file collector).
# See docs/02-nul-safe-collector/README.md.
#
# Usage:
#   collect-ext [--nul] [--source find|glob|git] EXT DIR
#
# Three backends, picked at runtime. All three are NUL-safe.
#
# Trade-off note: `find` is the default — fastest on large trees, portable
# across systems, no symlink-loop trap. `glob` (bash builtin) is the right
# pick when you want zero forks for a small known tree. `git` wins inside a
# repo because it reads the index (skips node_modules etc. without configuration).

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

usage() {
  cat >&2 <<'USAGE'
usage: collect-ext [--nul] [--source find|glob|git] EXT DIR
  --nul       NUL-separated output instead of newline-separated
  --source    find (default) | glob | git
  EXT         extension without dot (e.g. "txt"); must not contain "/"
  DIR         directory to walk
USAGE
  exit 2
}

# Output one path per item. If $nul, use NUL terminator instead of newline.
emit() {
  local p
  for p in "$@"; do
    if (( nul )); then
      printf '%s\0' "$p"
    else
      printf '%s\n' "$p"
    fi
  done
}

source_find() {
  local ext=$1 dir=$2
  # -name "*.$ext" matches files literally ending in .ext (NOT a regex).
  find "$dir" -type f -name "*.$ext" -print0 |
    while IFS= read -r -d '' path; do
      emit "$path"
    done
}

source_glob() {
  local ext=$1 dir=$2
  # Bash needs globstar for `**`, nullglob so an empty match doesn't expand
  # to a literal pattern, dotglob so dot-files are included.
  shopt -s globstar nullglob dotglob
  local files=("$dir"/**/*."$ext")
  shopt -u globstar nullglob dotglob
  emit "${files[@]}"
}

source_git() {
  local ext=$1 dir=$2
  if ! git -C "$dir" rev-parse --show-toplevel >/dev/null 2>&1; then
    die 2 "git: $dir is not in a git working tree"
  fi
  # `git ls-files -z` prints NUL-separated, repo-relative paths.
  ( cd "$dir" && git ls-files -z "*.$ext" ) |
    while IFS= read -r -d '' path; do
      emit "$dir/$path"
    done
}

# --- option parsing ---------------------------------------------------
nul=0
backend='find'
positional=()
while (( $# > 0 )); do
  case "$1" in
    --nul)    nul=1; shift ;;
    --source) backend=$2; shift 2 ;;
    -h|--help) usage ;;
    --) shift; positional+=("$@"); break ;;
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

# --- dispatch ---------------------------------------------------------
case "$backend" in
  'find') source_find "$ext" "$dir" ;;
  'glob') source_glob "$ext" "$dir" ;;
  'git')  source_git  "$ext" "$dir" ;;
  *)      die 2 "unknown source: $backend (want: find|glob|git)" ;;
esac
