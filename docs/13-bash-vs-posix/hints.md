# Hints for `buggy.sh` (exercise 13)

The script's shebang is `#!/bin/sh` (POSIX) but the body uses bashisms.
Run under `dash` to see which lines fail.

## Hint 1 — vague
ShellCheck with `-s sh` will catch most of them. `shellcheck -s sh
docs/13-bash-vs-posix/buggy.sh` is your hint.

## Hint 2 — locations
1. `declare -A counts`           — `declare` and `-A` are both bashisms;
   POSIX sh has no associative arrays
2. `[[ -z "$line" ]]`            — `[[ ]]` is bash; POSIX is `[ -z "$line" ]`
3. `read level component <<< "$line"` — here-strings (`<<<`) are bash
4. `prefix=${1:0:5}`             — substring extraction `${var:offset:length}` is bash
5. `files=( /etc/*.conf )` and `${files[@]}` — arrays are bash

## Hint 3 — fix paths
Either:
- Change shebang to `#!/usr/bin/env bash` and embrace the bashisms (easiest)
- OR rewrite to be POSIX:
  - assoc-array → `eval`-based or pipe through `awk`
  - `[[ ]]` → `[ ]`
  - `<<<` → `echo "$line" | { read level component; ... }`
  - `${1:0:5}` → `expr substr "$1" 1 5`
  - arrays → `set --` for the one available "array" (`$@`)

The POSIX rewrite is what exercise 13 asks for. Compare the two.

## Why
| Bug | Reference |
| --- | --------- |
| 1–5 | ex. 13 README "Features that have NO POSIX equivalent" |
