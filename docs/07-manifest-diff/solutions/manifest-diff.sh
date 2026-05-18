#!/usr/bin/env bash
# Reference: diff two trees by reproducible manifest.
# Exit: 0 same / 1 different / 2 error.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

(( $# >= 2 )) || die 2 'usage: manifest-diff.sh OLD NEW'
old=$1; new=$2
[[ -d $old && -d $new ]] || die 2 "OLD and NEW must be directories"

manifest=$(dirname "$0")/manifest.sh
diff -u <("$manifest" "$old") <("$manifest" "$new")
rc=$?
case $rc in
  0) exit 0 ;;
  1) exit 1 ;;
  *) exit 2 ;;
esac
