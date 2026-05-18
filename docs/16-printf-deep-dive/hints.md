# Hints for `buggy.sh` (exercise 16)

Six printf/echo bugs that every bash user has hit at least once.

## Hint 1 — locations
1. `iso=$(date -d "@$ts" ...)`  — fork per line; use `printf '%(...)T'` (bash 4.2+, no fork)
2. `echo "$iso\t$msg"`            — `echo` doesn't interpret `\t` by default;
   even with `-e`, behaviour varies. Use `printf '%s\t%s\n'`
3. `echo "ran at $(date)"`        — fork; use `printf 'ran at %(%F %T)T\n' -1`
4. `printf "$file\n"`             — **format-string injection**. If `$file` is
   `%s%s%s%s`, printf reads from random memory. Always: `printf '%s\n' "$file"`.
5. `echo "lines: \c"`             — `\c` (no newline) is only honoured by some
   `echo`s under `-e`. Use `printf 'lines: '`.
6. `printf "%d\n" $n`             — unquoted `$n`. Works on plain integers but
   breaks if `$n` contains whitespace; also, for thousands separator use `%'d`.

## Hint 2 — fix sketch
```diff
-  iso=$(date -d "@$ts" +%Y-%m-%dT%H:%M:%S)
-  echo "$iso\t$msg"
+  printf '%(%Y-%m-%dT%H:%M:%S)T\t%s\n' "$ts" "$msg"

-echo "ran at $(date)"
+printf 'ran at %(%F %T)T\n' -1

-printf "$file\n"
+printf '%s\n' "$file"

-echo "lines: \c"
+printf 'lines: '
 wc -l < "$1"

-printf "%d\n" $n
+printf "%'d\n" "$n"
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 16 "Trick: %(...)T" |
| 2,5 | BashFAQ/072 (echo unpredictability) |
| 3   | ex. 16 "Trick: %(...)T for dates without forking" |
| 4   | ex. 16 README Break-it ("format-string injection") |
| 6   | ex. 16 "Trick: %-20s, %5d, %'d" |
