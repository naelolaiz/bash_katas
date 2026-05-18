# Hints for `buggy.sh` (exercise 21)

Five bugs across the classic Unix toolset.

## Hint 1 — locations
1. `cat $log | awk ... | sort | uniq -c | sort -n | head` — UUOC; and
   `sort -n` orders ascending — for top-N you want `sort -rn`.
2. `sed -i 's/foo/bar/g' "$log"` — GNU `sed -i` works; BSD/macOS `sed -i`
   requires an extension argument (use `-i ''` or fall back to `sed -i.bak ...`).
3. `comm -23 <(awk ... "$log") <(sort "$allowlist")` — `awk` output is NOT
   sorted; `comm` silently misbehaves. Also no `LC_ALL=C`, so locales bite.
4. `grep -oP '/api/v1/users/\d+'` — `-P` is PCRE, not in busybox; `\d`
   is PCRE-only too. Use `grep -oE '/api/v1/users/[0-9]+'`.
5. `diff /tmp/a /tmp/b | grep '^<'` — set-diff via diff is fragile;
   prefer `comm -23` for "in A not in B" with sorted input.

## Hint 2 — fix sketch
```diff
-cat "$log" | awk '{print $1}' | sort | uniq -c | sort -n | head
+awk '{print $1}' "$log" | LC_ALL=C sort | uniq -c | sort -rn | head

-sed -i 's/foo/bar/g' "$log"
+# portable across GNU and BSD:
+sed -i.bak 's/foo/bar/g' "$log" && rm -f "$log.bak"

-comm -23 <(awk '{print $1}' "$log") <(sort "$allowlist")
+comm -23 \
+  <(awk '{print $1}' "$log" | LC_ALL=C sort -u) \
+  <(LC_ALL=C sort -u "$allowlist")

-grep -oP '/api/v1/users/\d+' "$log"
+grep -oE '/api/v1/users/[0-9]+' "$log"

-sort "$log" | uniq > /tmp/a
-sort "$allowlist" | uniq > /tmp/b
-diff /tmp/a /tmp/b | grep '^<'
+comm -12 \
+  <(LC_ALL=C sort -u "$log") \
+  <(LC_ALL=C sort -u "$allowlist")
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | BashPitfalls UUOC; sort orientation |
| 2   | ex. 21 "Trick: `sed -i` portability — GNU vs BSD" |
| 3   | ex. 21 "Trick: `comm` for set operations" — *"input MUST be sorted under the SAME locale"* |
| 4   | ex. 21 "Trick: `grep -o`, `grep -z`, `grep -P`" — `-P` pitfalls |
| 5   | ex. 21 "Trick: `comm` for set operations" |
