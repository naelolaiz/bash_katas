#!/usr/bin/env bash
# Reference: demonstrate locale-induced bugs and the LC_ALL=C fix side by side.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

corpus=$(mktemp -d)
trap 'rm -rf "$corpus"' EXIT

printf '%s\n' Apple banana Cherry date Elephant > "$corpus/words"

echo "=== sort under default locale vs LC_ALL=C ==="
echo '-- default:'
sort < "$corpus/words"
echo '-- LC_ALL=C:'
LC_ALL=C sort < "$corpus/words"

echo
echo "=== [A-Z] vs [[:upper:]] ==="
echo '-- [A-Z] (range, locale-dependent):'
LC_ALL=en_US.UTF-8 grep -o '[A-Z]' <<< 'Hello WORLD'
echo '-- [[:upper:]] (semantic class):'
LC_ALL=en_US.UTF-8 grep -o '[[:upper:]]' <<< 'Hello WORLD'

echo
echo "=== version sort ==="
printf '%s\n' v1.10 v1.2 v1.20 v2.1 > "$corpus/versions"
echo '-- lexical sort:'
sort < "$corpus/versions"
echo '-- -V (version):'
sort -V < "$corpus/versions"

echo
echo "=== comm misalignment across locales ==="
printf '%s\n' alpha BETA charlie  > "$corpus/a"
printf '%s\n' alpha CHARLIE beta  > "$corpus/b"
echo '-- comm with default-locale sort (silently misbehaves):'
comm -12 <(sort "$corpus/a") <(sort "$corpus/b") || true
echo '-- comm with LC_ALL=C sort (correct):'
comm -12 <(LC_ALL=C sort "$corpus/a") <(LC_ALL=C sort "$corpus/b") || true
