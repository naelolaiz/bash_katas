#!/usr/bin/env bash
# Reference: hash every regular file under DIR with parallelism.
# NUL-safe end-to-end.

set -euo pipefail

jobs=$(nproc 2>/dev/null || echo 4)
alg=sha256
while [[ $# -gt 0 ]]; do
  case $1 in
    -j|--jobs)      jobs=$2; shift 2 ;;
    --algorithm)    alg=$2; shift 2 ;;
    -h|--help) echo 'usage: parallel-hash [-j N] [--algorithm sha256|md5|...] DIR' >&2; exit 2 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *)  break ;;
  esac
done
if (( $# < 1 )); then echo 'usage: parallel-hash [-j N] [--algorithm ALG] DIR' >&2; exit 2; fi
dir=$1

find "$dir" -type f -print0 \
  | xargs -0r -n 64 -P "$jobs" "${alg}sum" --
