#!/usr/bin/env bash
# FAILING EXERCISE — buggy repo-find. FIVE find-flag bugs that look fine until measured.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

dir=${1:-.}

# List files; "skip" node_modules and .git.
find "$dir" -type f \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -exec stat -c '%s %y %n' {} \;                                  # BUG #1 (\; instead of +; BUG #2 too: stat fork per file)

# Find log files modified in the last day.
find "$dir" -type f -name '*.log' -mtime -1                       # BUG #3 (mtime is 24h chunks, not "last 24h")

# Replace stat with find -printf for speed... almost
find "$dir" -type f -printf '%p %T@\n'                            # BUG #4 (epoch time, not iso)

# Find under a regex (matches what?)
find "$dir" -regex '.*/[a-z]+\.go'                                # BUG #5 (default regex is BRE; -regextype missing)
