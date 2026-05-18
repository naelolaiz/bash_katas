# Hints for `buggy.sh` (exercise 14)

The script's RESULT is wrong (count=0) AND it's slow.

## Hint 1 — locations
1. `cat "$file" | while read`    — TWO bugs:
   - "useless use of cat" (UUOC)
   - the `while` runs in a subshell because of the pipe; `count` and `seen`
     assignments are lost when the subshell exits
2. `ip=$(echo "$line" | awk '{print $1}')` — fork TWO processes per line
3. `tr A-Z a-z` per line — another fork per line; bash has `${ip,,}` builtin
4. `time cat "$file" | wc -l` — `time` binds to `cat`, NOT to the pipeline.
   To time the whole thing: `time { cat ... | wc -l; }`. Or just `time wc -l < "$file"`.
5. Missing `strace -f -c` analysis — the README asks for it.

## Hint 2 — minimal fix sketch
```diff
-cat "$file" | while read -r line; do
-  ip=$(echo "$line" | awk '{print $1}')
-  ip_lower=$(echo "$ip" | tr A-Z a-z)
+while read -r ip _; do
+  ip_lower=${ip,,}
   if [[ -z "${seen[$ip_lower]:-}" ]]; then
     seen[$ip_lower]=1
     count=$((count + 1))
   fi
-done
+done < "$file"

-time cat "$file" | wc -l
+time wc -l < "$file"
+strace -f -c bash -c 'wc -l < "$0"' "$file" 2>&1 | tail -10
```

For really big inputs, the bash loop is itself the bottleneck — the
exercise asks you to also write the `awk` and pure-coreutils versions
and benchmark all four.

## Why
| Bug | Reference |
| --- | --------- |
| 1   | BashFAQ/024 (pipeline variable scope); BashPitfalls (UUOC) |
| 2,3 | ex. 14 "Trick: replace per-line forks with one batched call" |
| 4   | ex. 14 "Trick: `time` and `TIMEFORMAT`" — `time CMD | filter` |
| 5   | ex. 14 "Trick: `strace -f -c` to count syscalls" |
