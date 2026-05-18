# Hints for `buggy.sh` (exercise 8)

Six bugs around traps, atomicity, and the BashFAQ/105 errexit list. Several
only fire on Ctrl-C or on filesystems other than `/tmp`.

## Hint 1 — vague
Read BashFAQ/105 before fixing. Two of the bugs are explicitly in that list.

## Hint 2 — locations
1. `tmp=/tmp/safe-edit.$$`                  — predictable name; concurrent
   invocations collide; symlink race. Use `mktemp`.
2. `trap "rm -f $tmp" EXIT`                  — `$tmp` is expanded at trap
   INSTALL time, not when the trap fires (use single quotes); AND `EXIT`
   alone doesn't catch Ctrl-C or `kill TERM` cleanup paths.
3. `mv "$tmp" "$file"`                        — when `$file` is on a
   different filesystem than `/tmp` (very common — `/home` vs tmpfs),
   `mv` falls back to copy+delete and is NOT atomic. Concurrent readers
   can observe an empty or partial file.
4. `(( attempts = 0 ))`                       — `(( expr ))` returns exit
   status 1 when the result is 0. Under `set -e`, this LINE EXITS THE
   SCRIPT. Classic BashFAQ/105.
5. Also missing: preserving the original file's mode/ownership/timestamp
6. Also missing: handling the case where `"$@" "$tmp"` fails — the
   `mv` then overwrites the original with corrupted data

## Hint 3 — minimal fix sketch
```diff
-tmp=/tmp/safe-edit.$$
-cp "$file" "$tmp"
-trap "rm -f $tmp" EXIT
+tmp=$(mktemp "$(dirname "$file")/.safe-edit.XXXXXX")
+cp --preserve=mode,ownership,timestamps "$file" "$tmp"
+cleanup() { rm -f "$tmp"; }
+trap cleanup EXIT
+trap 'cleanup; exit 130' INT
+trap 'cleanup; exit 143' TERM

-"$@" "$tmp"
+if ! "$@" "$tmp"; then
+  echo 'command failed; original untouched' >&2
+  exit 1
+fi

-mv "$tmp" "$file"
+mv -- "$tmp" "$file"     # same fs (mktemp in dirname of $file) -> atomic rename

-attempts=0
-(( attempts = 0 ))
+attempts=0
+: $(( attempts = 0 ))     # `:` swallows the (( )) exit status
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | symlink race; mktemp(1) |
| 2   | trap quoting; ex. 8 README "Trick: catch signals" |
| 3   | ex. 8 "Trick: atomic file replacement with `mv`" |
| 4   | BashFAQ/105 |
| 5,6 | exercise spec: "preserve permissions"; "replace only if command succeeds" |
