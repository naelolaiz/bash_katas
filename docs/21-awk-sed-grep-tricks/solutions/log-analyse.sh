#!/usr/bin/env bash
# Reference: small log analysis showing several awk/grep/sort idioms.
#   1) top N IPs by request count
#   2) top N URLs by error rate (status >= 500)
#   3) IPs in log but not in allowlist (set diff via comm)

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

n=10
allowlist=''
while [[ $# -gt 0 ]]; do
  case $1 in
    -n)         n=$2; shift 2 ;;
    --allowlist) allowlist=$2; shift 2 ;;
    --) shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done
(( $# >= 1 )) || die 2 'usage: log-analyse [-n N] [--allowlist FILE] LOG'
log=$1

echo "=== top $n IPs ==="
awk '{print $1}' "$log" \
  | LC_ALL=C sort \
  | uniq -c \
  | sort -rn \
  | head -n "$n"

echo
echo "=== top $n URLs by 5xx errors ==="
awk '$9 >= 500 { print $7 }' "$log" \
  | LC_ALL=C sort \
  | uniq -c \
  | sort -rn \
  | head -n "$n"

if [[ -n $allowlist ]]; then
  echo
  echo "=== IPs in log NOT in allowlist ==="
  comm -23 \
    <(awk '{print $1}' "$log" | LC_ALL=C sort -u) \
    <(LC_ALL=C sort -u -- "$allowlist")
fi
