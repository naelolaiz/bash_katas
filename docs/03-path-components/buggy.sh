#!/usr/bin/env bash
# FAILING EXERCISE — buggy pathinfo. There are FIVE bugs.
# Some bugs only fire on adversarial inputs from the README's "Break it" list.
# That's the point: a casual test on `/tmp/archive.tar.gz` looks fine.
#
# Verify with `bats docs/03-path-components/tests.bats`.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

usage() {
  echo "usage: pathinfo PATH [PATH...]" >&2
  exit 2
}

(( $# > 0 )) || usage

for path in "$@"; do
  # Compute ext/stem from the FULL path. Looks fine until a parent
  # directory has a dot in its name.
  ext=${path##*.}                                                # BUG #1
  stem=${path%.*}                                                # BUG #2

  # basename via dirname — except this strips trailing slash silently
  # and breaks on a path containing only the basename.
  dir=`dirname $path`                                            # BUG #3 (two on one line)
  base=`basename $path`                                          # BUG #4

  # Leading-dot files like .hidden have NO extension. This treats
  # everything after the first dot as the extension.
  if [[ $base == *.* ]]; then
    ext=${base#*.}                                               # BUG #5
  else
    ext=
  fi

  echo "original=$path"
  echo "dir=$dir"
  echo "base=$base"
  echo "stem=$stem"
  echo "ext=$ext"
  echo
done
