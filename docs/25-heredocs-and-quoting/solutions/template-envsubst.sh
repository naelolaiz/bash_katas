#!/usr/bin/env bash
# Reference (envsubst): use the gettext-tools utility purpose-built for this.
# Trade-off: shortest implementation but extra dependency (gettext-base /
# `envsubst`). Does NOT support `${VAR:-default}` syntax — only `$VAR` /
# `${VAR}`. Strict mode is not native; emulated by pre-checking.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

command -v envsubst >/dev/null || die 2 "envsubst not installed (apt install gettext-base)"

strict=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --strict) strict=1; shift ;;
    --) shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done

(( $# >= 1 )) || die 2 'usage: template-envsubst [--strict] FILE'
file=$1
[[ -r $file ]] || die 2 "no such file: $file"

if (( strict )); then
  # `envsubst -v FILE` lists every variable mentioned in FILE; verify each is set.
  missing=()
  while IFS= read -r var; do
    [[ -z $var ]] && continue
    if [[ -z ${!var+x} ]]; then
      missing+=("$var")
    fi
  done < <(envsubst -v < "$file")
  if (( ${#missing[@]} > 0 )); then
    err "unset variable(s): ${missing[*]}"
    exit 2
  fi
fi

# envsubst by default reads stdin; pipe the file in.
envsubst < "$file"
