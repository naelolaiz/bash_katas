#!/bin/sh
# Reference (POSIX version): same job as tool.bash, runs under dash/ash.
# No arrays, no [[ ]], no (( )), no <<<, no declare -A.

# shellcheck shell=sh

set -eu

# Pipe everything through awk — POSIX's natural associative array.
awk '
  NF >= 3 && $1 !~ /^[^0-9]/ {
    key = $2 " " $3
    c[key]++
  }
  END {
    for (k in c) printf "%s %d\n", k, c[k]
  }
' | LC_ALL=C sort
