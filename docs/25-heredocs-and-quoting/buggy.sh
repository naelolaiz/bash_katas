#!/usr/bin/env bash
# FAILING EXERCISE — buggy template. FIVE heredoc / expansion bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

target=$1; shift

# A "config" heredoc that should be literal — but isn't.
# (e.g. some user-supplied YAML/SQL that has $ signs in it).
content=$(cat <<EOF                                              # BUG #1 (unquoted EOF expands $VAR)
database:
  host: \${DB_HOST}
  password: \${DB_PASS}
  query: SELECT * FROM users WHERE id = \$user_id;
EOF
)

# Save it. Atomic? Nope.
echo "$content" > "$target"                                       # BUG #2 (echo, no atomic mv)

# Hand-rolled <<-EOF that uses SPACES for indent — won't strip.
cat <<-EOF                                                        # BUG #3 (<<- strips TABS only)
    line one
    line two
    EOF

# Round-trip an associative array via declare -p, but use eval on user input.
input=$1
eval "$input"                                                     # BUG #4 (RCE via user input)

# Capture both stdout and stderr but only redirect stdout:
some_cmd > /tmp/out                                               # BUG #5 (stderr leaks to terminal)
