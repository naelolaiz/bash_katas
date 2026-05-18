# Hints for `buggy.sh` (exercise 18)

Five bugs around `read` flags and `mapfile`.

## Hint 1 — locations
1. `while read line`           — needs `IFS= read -r line || [[ -n $line ]]`
   to handle leading whitespace, backslashes, AND last-line-without-newline
2. `mapfile lines < "$file"`   — without `-t`, every element keeps its
   trailing `\n`. So `"${lines[0]}"` is `"first line\n"`, not `"first line"`.
3. `arr=($(<"$file"))`         — words split on IFS AND each token undergoes
   pathname expansion. A line `*.txt` becomes every matching file
4. `read -p 'continue? ' answer` — missing `-r`; backslashes get processed.
   Also `-p` only works if stdin is a terminal — fine here, but worth noting
5. `find ... | mapfile -t`     — pipeline subshell means `files` is set in
   the subshell and lost. Use process substitution `< <(...)`. Also `-t`
   is wrong here — NUL-delimited input needs `-d ''`

## Hint 2 — fix sketch
```diff
-while read line; do
+while IFS= read -r line || [[ -n $line ]]; do
   count=$((count + 1))
 done < "$file"

-mapfile lines < "$file"
+mapfile -t lines < "$file"

-arr=($(<"$file"))
+mapfile -t arr < "$file"

-read -p 'continue? ' answer
+read -r -p 'continue? ' answer

-find . -type f -print0 | mapfile -t files
+mapfile -d '' files < <(find . -type f -print0)
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 18 "Trick: `-r` + `IFS=`"; BashFAQ/001 |
| 2   | ex. 18 "Trick: `mapfile` (aka `readarray`)" |
| 3   | BashPitfalls #50 (`arr=($(<file))`) |
| 4   | minor — bash docs `read -r` |
| 5   | ex. 18 "Trick: `-d ''`" |
