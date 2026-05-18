#!/usr/bin/env bash
# Benchmark harness for exercise 14 (and others).
# Runs each of the four perf-kata modes against the generated corpora and
# reports real/user/sys time + line throughput.

set -euo pipefail
cd "$(dirname "$0")/.."

KATA=docs/14-performance-kata/solutions/perf-kata.sh
CORPUS=${1:-data/generated/big-access.log}

if [[ ! -f $CORPUS ]]; then
  echo "no corpus: $CORPUS" >&2
  echo 'run scripts/gen-log-corpus.sh first' >&2
  exit 2
fi

lines=$(wc -l < "$CORPUS")
echo "corpus: $CORPUS ($lines lines)"
echo

# TIMEFORMAT: bash builtin `time` output template.
# %R wall, %U user-CPU, %S system-CPU (all in seconds with 3 decimals).
export TIMEFORMAT='real %3R  user %3U  sys %3S'

run_mode() {
  local mode=$1
  printf '%-10s ' "$mode"
  { time "$KATA" --mode "$mode" "$CORPUS" >/dev/null; } 2>&1
}

for mode in naive builtin awk pipeline; do
  run_mode "$mode"
done

echo
echo 'Linux only: strace -c summary for awk mode (one invocation):'
if command -v strace >/dev/null; then
  strace -f -c "$KATA" --mode awk "$CORPUS" >/dev/null 2>&1 || true
  strace -f -c "$KATA" --mode awk "$CORPUS" >/dev/null 2>/tmp/strace.out || true
  tail -20 /tmp/strace.out 2>/dev/null || true
else
  echo '  strace not installed; skipping'
fi
