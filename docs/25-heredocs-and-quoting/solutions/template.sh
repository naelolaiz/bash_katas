#!/usr/bin/env bash
# Reference: substitute $VAR / ${VAR} / ${VAR:-default} from the environment.
# Does NOT execute $(...) or `...` from the template — safe against injection.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

strict=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --strict) strict=1; shift ;;
    --) shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done

(( $# >= 1 )) || die 2 'usage: template [--strict] FILE'
file=$1
[[ -r $file ]] || die 2 "no such file: $file"

# awk-based: explicit parser, no eval, no risk of executing user code.
awk -v strict="$strict" '
function lookup(name) {
  # Check membership BEFORE accessing ENVIRON[name] — accessing an absent
  # key would create the entry in gawk, defeating the membership test.
  if (!(name in ENVIRON)) {
    if (strict == "1") {
      printf("error: variable %s is not set\n", name) > "/dev/stderr"
      exit 2
    }
    return ""
  }
  return ENVIRON[name]
}
{
  line = $0
  out = ""
  while ((idx = match(line, /\$([A-Za-z_][A-Za-z0-9_]*|\{[A-Za-z_][A-Za-z0-9_]*(:-[^}]*)?\})/)) > 0) {
    out = out substr(line, 1, idx - 1)
    raw = substr(line, idx + 1, RLENGTH - 1)
    if (substr(raw, 1, 1) == "{") {
      inner = substr(raw, 2, length(raw) - 2)
      if ((p = index(inner, ":-")) > 0) {
        name = substr(inner, 1, p - 1)
        dflt = substr(inner, p + 2)
      } else {
        name = inner; dflt = ""
      }
    } else {
      name = raw; dflt = ""
    }
    val = lookup(name)
    if (val == "" && dflt != "") val = dflt
    out = out val
    line = substr(line, idx + RLENGTH)
  }
  print out line
}
' "$file"
