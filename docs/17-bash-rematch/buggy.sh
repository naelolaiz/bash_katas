#!/usr/bin/env bash
# FAILING EXERCISE — buggy parse-log. FIVE regex / =~ bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

# Try to parse: "2026-05-18T14:32:11+0200 [INFO] api.request id=abc-123 took=42ms"
re='^([0-9T:+-]+) \[(INFO|WARN|ERROR)\] (\S+) id=(\S+) took=([0-9]+)ms$'  # BUG #5 (\S not POSIX ERE)

while IFS= read -r line; do
  if [[ "$line" =~ "$re" ]]; then                                # BUG #1 (quoted RHS → literal)
    echo "ts=${BASH_REMATCH[1]} level=${BASH_REMATCH[2]} comp=${BASH_REMATCH[3]}"
  fi
done

# elsewhere: check a hostname
host=$1
if [[ $host =~ [a-z]+\.[a-z]+ ]]; then                            # BUG #2 (not anchored — matches substring)
  echo "ok"
fi

# extract a number from a string
str='value is 42 here'
[[ $str =~ [0-9]+ ]]
n=${BASH_REMATCH[0]}

# do something else that uses =~ ...
[[ '' =~ junk ]]
# now BASH_REMATCH is stale; using it would be wrong               BUG #3 (assumes BASH_REMATCH preserved)
echo "got n=${BASH_REMATCH[0]}"                                   # BUG #4 (wrong array now)

# (BUG #5 above): \S, \d, \w are PCRE, not POSIX ERE
