# Hints for `buggy.sh` (exercise 17)

Five bugs all rooted in misunderstandings about `[[ =~ ]]`.

## Hint 1 — locations
1. `[[ "$line" =~ "$re" ]]`   — quoting the RHS forces literal compare.
   The whole regex never matches; the script silently outputs nothing.
2. `[[ $host =~ [a-z]+\.[a-z]+ ]]` — not anchored. `notahost.tld...garbage`
   matches. Use `^...$`.
3. Reusing `BASH_REMATCH` after a second `=~` — it's global and gets
   overwritten by every successful match (and untouched by failed ones).
4. `echo "got n=${BASH_REMATCH[0]}"` — at that point `BASH_REMATCH[0]`
   is from the second `=~` against `junk` (or empty if that failed)
5. `\S` in the regex — bash `[[ =~ ]]` uses POSIX ERE, not PCRE. `\S`,
   `\d`, `\w`, `(?:...)`, lookarounds — all PCRE-only. Use `[^[:space:]]`.

## Hint 2 — fix sketch
```diff
-re='^([0-9T:+-]+) \[(INFO|WARN|ERROR)\] (\S+) id=(\S+) took=([0-9]+)ms$'
+re='^([0-9T:+-]+) \[(INFO|WARN|ERROR)\] ([^[:space:]]+) id=([^[:space:]]+) took=([0-9]+)ms$'

-  if [[ "$line" =~ "$re" ]]; then
+  if [[ $line =~ $re ]]; then

-if [[ $host =~ [a-z]+\.[a-z]+ ]]; then
+if [[ $host =~ ^[a-z]+\.[a-z]+$ ]]; then

 [[ $str =~ [0-9]+ ]]
-n=${BASH_REMATCH[0]}
+n=${BASH_REMATCH[0]}
+# CAPTURE LOCALLY before next =~ call
+rematch=("${BASH_REMATCH[@]}")

-[[ '' =~ junk ]]
-echo "got n=${BASH_REMATCH[0]}"
+echo "got n=${rematch[0]}"
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 17 "Trick: the unquoted-pattern rule (the #1 gotcha)" |
| 2   | ex. 17 "Trick: anchoring and the implicit-substring behaviour" |
| 3,4 | ex. 17 "Trick: capture groups via BASH_REMATCH" — *"global and overwritten by every successful =~"* |
| 5   | ex. 17 "Trick: regex engine flavour — POSIX ERE, not PCRE" |
