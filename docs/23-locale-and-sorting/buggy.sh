#!/usr/bin/env bash
# FAILING EXERCISE — buggy locale-bomb. FIVE locale-related bugs.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

a=$1; b=$2

# Lines in A but not in B.
comm -23 <(sort "$a") <(sort "$b")                                # BUG #1 (no LC_ALL=C; may misalign)

# Uppercase ASCII letters in a string.
echo 'Hello WORLD' | grep -o '[A-Z]'                              # BUG #2 ([A-Z] is locale-dependent)

# Lowercase-fold via tr.
echo 'TÜRKİYE' | tr A-Z a-z                                       # BUG #3 (bytes not Unicode; broken on non-ASCII)

# Sort by version (1.10 should come after 1.2).
printf '%s\n' v1.10 v1.2 v1.20 v2.1 | sort                        # BUG #4 (lexical, need -V)

# Check if a string is alphabetic. Wrong for non-ASCII.
s='naïve'
[[ $s == *[[:alpha:]]* ]]                                         # BUG #5 (locale-dep; may say no)
echo "alpha? $?"
