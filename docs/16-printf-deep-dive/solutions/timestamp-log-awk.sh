#!/usr/bin/env bash
# Reference (awk): one fork, processes the entire stream.
# Fastest for any sizeable input.

set -euo pipefail
exec awk -F'\t' '{ printf "%s\t%s\n", strftime("%Y-%m-%dT%H:%M:%S%z", $1), $2 }'
