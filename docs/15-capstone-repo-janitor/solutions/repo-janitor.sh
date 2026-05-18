#!/usr/bin/env bash
# Reference: repo-janitor [--apply] [--json|--tab] [--min-size BYTES]
#                         [--exclude PATTERN]... DIR
# Dry-run by default. --apply required to delete anything.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

apply=0
fmt=tab
min_size=$(( 100 * 1024 * 1024 ))
excludes=(node_modules .git .cache target dist build)

while [[ $# -gt 0 ]]; do
  case $1 in
    --apply)    apply=1; shift ;;
    --dry-run)  apply=0; shift ;;
    --json)     fmt=json; shift ;;
    --tab)      fmt=tab;  shift ;;
    --min-size) min_size=$2; shift 2 ;;
    --exclude)  excludes+=("$2"); shift 2 ;;
    --) shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done

(( $# >= 1 )) || die 2 'usage: repo-janitor [OPTIONS] DIR'
dir=$1
[[ -d $dir ]] || die 2 "no such directory: $dir"

# single-instance lock so two --apply runs can't race on the same tree
lockfile="${dir}/.repo-janitor.lock"
exec 200>"$lockfile"
flock -n 200 || die 1 'repo-janitor already running on this tree'
trap 'rm -f "$lockfile"' EXIT

emit() {
  local category=$1 path=$2 size=$3
  if [[ $fmt == json ]]; then
    # path may contain " — escape with jq if available; fall back to %q-ish
    if command -v jq >/dev/null; then
      jq -cn --arg c "$category" --arg p "$path" --argjson s "$size" \
        '{category:$c, path:$p, size:$s}'
    else
      printf '{"category":"%s","size":%d,"path":%q}\n' "$category" "$size" "$path"
    fi
  else
    printf '%s\t%d\t%s\n' "$category" "$size" "$path"
  fi
}

# build prune args
prune_args=()
for ex in "${excludes[@]}"; do
  prune_args+=(-name "$ex" -o)
done
unset 'prune_args[${#prune_args[@]}-1]'   # drop trailing -o

findings=0

# --- large files ---
while IFS= read -r -d '' line; do
  size=${line%% *}
  path=${line#* }
  (( size >= min_size )) && { emit large "$path" "$size"; findings=$(( findings + 1 )); }
done < <(find "$dir" \( "${prune_args[@]}" \) -prune -o \
                    -type f -printf '%s %p\0' 2>/dev/null)

# --- duplicates (hash-based) ---
declare -A first_seen
while IFS= read -r -d '' path; do
  h=$(sha256sum -- "$path" | cut -d' ' -f1)
  if [[ -n "${first_seen[$h]:-}" ]]; then
    size=$(stat -c '%s' -- "$path")
    emit duplicate "$path" "$size"
    findings=$(( findings + 1 ))
    (( apply )) && rm -f -- "$path"
  else
    first_seen[$h]=$path
  fi
done < <(find "$dir" \( "${prune_args[@]}" \) -prune -o \
                    -type f -print0 2>/dev/null)

# --- broken symlinks ---
while IFS= read -r -d '' path; do
  emit broken-symlink "$path" 0
  findings=$(( findings + 1 ))
  (( apply )) && rm -f -- "$path"
done < <(find "$dir" -xtype l -print0 2>/dev/null)

# --- junk dirs (collect first, delete after walk) ---
mapfile -d '' junk < <(
  find "$dir" -type d \( "${prune_args[@]}" \) -print0 2>/dev/null
)
for d in "${junk[@]}"; do
  size=$(du -sb -- "$d" 2>/dev/null | cut -f1)
  size=${size:-0}
  emit junk-dir "$d" "$size"
  findings=$(( findings + 1 ))
  (( apply )) && rm -rf -- "$d"
done

(( findings == 0 )) && exit 0 || exit 1
