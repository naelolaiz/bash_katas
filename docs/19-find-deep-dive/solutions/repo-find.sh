#!/usr/bin/env bash
# Reference: list files with size + mtime, pruning the usual junk dirs.
# Uses GNU find -printf for one-process output.

set -euo pipefail

prune='node_modules .git .cache target dist build .venv __pycache__'
newer=''
while [[ $# -gt 0 ]]; do
  case $1 in
    --newer) newer=$2; shift 2 ;;
    --) shift; break ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done

dir=${1:-.}

prune_expr=()
for p in $prune; do
  prune_expr+=(-name "$p" -o)
done
unset 'prune_expr[${#prune_expr[@]}-1]'

newer_expr=()
[[ -n $newer ]] && newer_expr=(-newermt "$newer")

find "$dir" \
  \( "${prune_expr[@]}" \) -prune -o \
  -type f "${newer_expr[@]}" \
  -printf '%s\t%TY-%Tm-%Td %TH:%TM:%TS\t%p\n'
