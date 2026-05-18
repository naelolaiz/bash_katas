#!/usr/bin/env bash
# Lint every shell script in the project.
# Run inside the container via `make lint`.

set -euo pipefail

cd "$(dirname "$0")/.."

mapfile -d '' files < <(
  find bin scripts lib docs \
    \( -name '*.sh' -o -name '*.bash' -o -name 'starter.sh' \) \
    -type f -print0 2>/dev/null
)

if (( ${#files[@]} == 0 )); then
  echo 'no scripts found to lint' >&2
  exit 0
fi

printf 'linting %d file(s):\n' "${#files[@]}"
printf '  %s\n' "${files[@]}"
echo

# Note: shellcheck auto-detects .shellcheckrc in CWD. -x follows `source` lines.
shellcheck -x "${files[@]}"
echo 'shellcheck: clean'
