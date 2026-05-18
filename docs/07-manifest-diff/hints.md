# Hints for `buggy.sh` (exercise 7)

Five bugs that all break reproducibility: same input → different output on
different machines or different runs.

## Hint 1 — vague
A manifest must produce the **same bytes** for the **same tree contents**
across:
- different filesystems (mtime differs even after `cp`)
- different locales (sort order)
- different filename character sets (NUL safety)

## Hint 2 — locations
1. `find ... | while read path`  — both halves wrong: missing `-print0` AND
   missing `-r -d ''`. Breaks on filenames with `\n` or `\t` or backslash
2. `mtime=$(stat -c '%Y' "$path")` and including it — mtime makes manifests
   non-reproducible across `cp -p` boundaries; only content/size matters
3. `echo "$sha $size $mtime $path"` — `echo` doesn't quote; if `$path` contains
   tabs, the line is ambiguous. Also output isn't `printf '%q\n'`-safe
4. `| sort` — locale-dependent; need `LC_ALL=C sort`
5. `if diff -u <(...)`  — under `set -e`, `diff` returning 1 (different)
   triggers errexit — but only when there's no `|| ...` rescue. Inside `if`
   it IS rescued. The hidden bug: the EXIT status under `else` doesn't
   distinguish "different" (1) from "diff itself errored" (2)

## Hint 3 — minimal fix sketch
```diff
-  find "$dir" -type f | while read path; do
+  ( cd "$dir" && find . -type f -print0 ) | while IFS= read -r -d '' path; do

-    sha=$(sha256sum "$path" | cut -d' ' -f1)
-    size=$(stat -c '%s' "$path")
-    mtime=$(stat -c '%Y' "$path")
-    echo "$sha $size $mtime $path"
-  done | sort
+    sha=$(sha256sum "$dir/$path" | cut -d' ' -f1)
+    size=$(stat -c '%s' "$dir/$path")
+    printf '%s\t%d\t%q\n' "$sha" "$size" "$path"
+  done | LC_ALL=C sort

-if diff -u <(manifest "$old") <(manifest "$new"); then
-  echo "same"; exit 0
-else
-  echo "different"; exit 1
+diff -u <(manifest "$old") <(manifest "$new")
+case $? in
+  0) exit 0 ;;
+  1) exit 1 ;;
+  *) exit 2 ;;
+esac
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 2 "Trick: `find -print0` + `read -r -d ''`" |
| 2   | ex. 7 README "Goal" (reproducibility) |
| 3   | ex. 16 (printf %q) |
| 4   | ex. 23 (LC_ALL=C sort) |
| 5   | ex. 7 "Trick: exit-code propagation"; ex. 8 BashFAQ/105 |
