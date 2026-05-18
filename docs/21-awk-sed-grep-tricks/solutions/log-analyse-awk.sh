#!/usr/bin/env bash
# Reference (single awk): top-N IPs and 5xx URLs in ONE awk pass.
# Trade-off: fewer forks than the pipeline variant; awk script is longer
# and less composable. Faster for very large logs (10⁷+ lines).

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

n=10
while [[ $# -gt 0 ]]; do
  case $1 in
    -n) n=$2; shift 2 ;;
    --) shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done
(( $# >= 1 )) || die 2 'usage: log-analyse-awk [-n N] LOG'
log=$1

awk -v top="$n" '
  { ip[$1]++ }
  $9 >= 500 { err_url[$7]++ }
  END {
    # PROCINFO sort works in gawk; fall back to no-sort otherwise.
    print "=== top IPs ==="
    PROCINFO["sorted_in"] = "@val_num_desc"
    c = 0
    for (k in ip) {
      print ip[k], k
      if (++c >= top) break
    }
    print ""
    print "=== top 5xx URLs ==="
    c = 0
    for (k in err_url) {
      print err_url[k], k
      if (++c >= top) break
    }
  }
' "$log"
