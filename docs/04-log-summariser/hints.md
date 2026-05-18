# Hints for `buggy.sh` (exercise 4)

Six bugs. Most fail under `set -euo pipefail` or on adversarial input.

## Hint 1 — vague
The script appears to work on the small obvious input. Feed it the 1M-line
corpus from `scripts/gen-log-corpus.sh` and inputs with embedded backslashes.

## Hint 2 — locations
1. `while read date level component msg`  — missing `-r` and `IFS=` ⇒ mangled lines
2. `[ -z "$level" ]`                       — `[ ]` is acceptable, but the script
   mixes `[ ]` and `[[ ]]` inconsistently; use `[[ ]]` throughout
3. `counts[$key]=$((counts[$key] + 1))`    — under `set -u`, missing `:-0`
   default on first access crashes the whole script
4. `printf '... %d\n' $key ${counts[$key]}` — unquoted; `$key` contains a space
   (`"INFO api"`), so it splits into two arguments and the printf line is garbled
5. final `| sort`                          — locale-dependent ordering
6. `if [ $? -eq 0 ]`                       — `$?` here is the exit of the `for`
   loop's done pipe, but it's already been consumed by the redirect-to-sort; also,
   `$?` semantics across pipelines need PIPESTATUS

## Hint 3 — minimal fix sketch
```diff
-while read date level component msg; do
+while IFS= read -r date level component msg; do

-  [ -z "$level" ] && continue
+  [[ -z $level ]] && continue

-  counts[$key]=$((counts[$key] + 1))
+  counts[$key]=$(( ${counts[$key]:-0} + 1 ))

-  printf '%s %d\n' $key ${counts[$key]}
+  printf '%s %d\n' "$key" "${counts[$key]}"

-done | sort
+done | LC_ALL=C sort

-if [ $? -eq 0 ]; then
+# $? already captured by the implicit shell; remove the redundant check
```

## Why these matter
| Bug | Reference |
| --- | --------- |
| 1   | BashFAQ/001 |
| 2   | inconsistency; `[[ ]]` is the bash form (see ex. 13) |
| 3   | the README's "Trick: bash assoc-array" — `${var:-0}` is the fix |
| 4   | BashPitfalls #1 (unquoted) |
| 5   | exercise 23 (locale) |
| 6   | exercise 6 (PIPESTATUS) |
