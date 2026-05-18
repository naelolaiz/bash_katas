#!/usr/bin/env bash
# FAILING EXERCISE — buggy log-analyse. FIVE bugs across awk/sed/grep idioms.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

log=$1
allowlist=$2

# Top 10 IPs.
cat "$log" | awk '{print $1}' | sort | uniq -c | sort -n | head  # BUG #1 (UUOC; sort -n should be -rn)

# Replace foo with bar in place. macOS-broken.
sed -i 's/foo/bar/g' "$log"                                       # BUG #2 (no extension; BSD sed errors)

# IPs in log but not in allowlist.
comm -23 <(awk '{print $1}' "$log") <(sort "$allowlist")          # BUG #3 (left side not sorted; locale)

# Match URLs that look like /api/v1/users/N
grep -oP '/api/v1/users/\d+' "$log"                               # BUG #4 (assumes -P; broken on busybox)

# Set intersection: lines in BOTH (no awk?)
sort "$log" | uniq > /tmp/a
sort "$allowlist" | uniq > /tmp/b
diff /tmp/a /tmp/b | grep '^<'                                    # BUG #5 (set intersection via diff; misuses comm)
