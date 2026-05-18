#!/usr/bin/env bash
# FAILING EXERCISE — buggy bc-client. FOUR bugs around coproc/IPC lifecycle.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

coproc BC { bc -l; }

while IFS= read -r -p '> ' expr; do
  [[ -z $expr ]] && continue
  [[ $expr == quit ]] && break

  printf '%s\n' "$expr" >&"${BC[1]}"

  # read the answer (no timeout!)
  read -r answer <&"${BC[0]}"                                    # BUG #1 (no -t timeout)
  printf '= %s\n' "$answer"

  # check if bc is still alive... by ignoring SIGPIPE? no.        BUG #2 (no PIPE handling)
done

# clean up
wait $BC_PID                                                      # BUG #3 (no close before wait, hangs)
echo "bye"

# BUG #4: if bc dies mid-session, the script doesn't recover.
