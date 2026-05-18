# Hints for `buggy.sh` (exercise 2)

Six bugs are planted. The whole exercise is about NUL-safe filename handling
— so the bugs are all about places where the script DROPS NUL safety.

## Hint 1 — vague

Every bug breaks on a filename containing whitespace, a newline, or a `-`.
A `touch "a b.txt" $'a\nb.txt' --danger` corpus exposes every one of them.

## Hint 2 — categories

- Three `for x in $list`-style loops that unquote what should be `"$@"` or
  `"${arr[@]}"`.
- One `echo $p` where `printf '%s\n' "$p"` is the safe form.
- One `while read` that's missing the NUL pipeline: `-print0`, `-r`, `IFS=`,
  `-d ''`.
- One `shopt -s globstar` without `nullglob` — an empty glob match expands
  to the literal pattern, and the emit loop processes it as if it were a
  real filename.

## Hint 3 — locations

1. `for p in $@`                              — should be `for p in "$@"`
2. `printf '%s\0' $p`                          — should be `"$p"`
3. `echo $p`                                   — should be `printf '%s\n' "$p"`
4. `find $dir ... | while read path; do`       — three problems on one line:
   - `find $dir` is unquoted (breaks if `$dir` has spaces)
   - missing `-print0` on `find`
   - missing `-r -d '' IFS=` on `read`
5. `shopt -s globstar` (alone)                 — needs `shopt -s globstar nullglob`
6. `for f in $(git ls-files "*.$ext")`         — command substitution + word-split
   breaks on filenames with whitespace; use `git ls-files -z | while read -d ''`

## Hint 4 — minimal fix sketch

```diff
-  for p in $@; do
+  for p in "$@"; do

-      printf '%s\0' $p
+      printf '%s\0' "$p"

-      echo $p
+      printf '%s\n' "$p"

-  find $dir -type f -name "*.$ext" | while read path; do
+  find "$dir" -type f -name "*.$ext" -print0 | while IFS= read -r -d '' path; do

-  shopt -s globstar
+  shopt -s globstar nullglob

-  for f in $(git ls-files "*.$ext"); do
-    emit "$dir/$f"
-  done
+  git ls-files -z "*.$ext" | while IFS= read -r -d '' f; do
+    emit "$dir/$f"
+  done
```
