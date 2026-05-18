# Hints for `buggy.sh` (exercise 5)

Five bugs around getopts and exit-code discipline.

## Hint 1 — vague
The conventions a CLI script MUST follow:
- exit 0 on success-with-results
- exit 1 on success-but-no-results (grep convention)
- exit 2 on usage error
- error messages to stderr, not stdout

Most bugs violate one of those.

## Hint 2 — locations
1. `getopts 'ivn:'`        — missing leading `:` ⇒ getopts prints its own
   error messages, you lose control of the exit code and where they go
2. `exit 0` in error case  — usage error should exit 2
3. `shift $OPTIND`         — off by one; should be `shift $((OPTIND-1))`
4. `for f in ${files[@]}`  — unquoted array; breaks on filenames with spaces
5. `exit 0` always         — no-match case should exit 1 (grep semantics)

## Hint 3 — minimal fix sketch
```diff
-while getopts 'ivn:' opt; do
+while getopts ':ivn:' opt; do

-    *) echo "usage error" && exit 0 ;;
+    :) printf 'option -%s requires an argument\n' "$OPTARG" >&2; exit 2 ;;
+    \?) printf 'unknown option: -%s\n' "$OPTARG" >&2; exit 2 ;;

-shift $OPTIND
+shift $((OPTIND - 1))

-for f in ${files[@]}; do
+for f in "${files[@]}"; do

-(( count > 0 )) && exit 0
+(( count > 0 )) && exit 0 || exit 1
```

## Why these matter
| Bug | Reference |
| --- | --------- |
| 1   | ex. 5 README, "Trick: bash builtin `getopts`" |
| 2   | grep/sed/awk all use exit 2 for usage errors |
| 3   | classic getopts off-by-one; bash manual `getopts` |
| 4   | BashPitfalls #1 |
| 5   | grep manpage EXIT STATUS section |
