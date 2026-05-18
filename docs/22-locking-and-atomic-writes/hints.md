# Hints for `buggy.sh` (exercise 22)

Five concurrency bugs. Run two instances at the same time to expose them.

## Hint 1 — locations
1. `[ -f "$lockfile" ]` + `echo $$ > "$lockfile"`  — classic TOCTOU race.
   Between the check and the write, another process can win. Use `flock`
   or `set -C` (noclobber) for race-free creation.
2. `trap 'rm -f "$lockfile"' EXIT` only  — Ctrl-C leaves the lockfile
   behind. Need INT and TERM traps too.
3. `tmp=$(mktemp)`                       — creates in `$TMPDIR` (usually
   `/tmp`, often tmpfs). If `$target` is on a different filesystem,
   `mv` is copy+delete, NOT atomic. Create the temp in the target's dir.
4. `mv "$tmp" "$target"`                 — same root cause as #3
5. `echo $$ > /var/run/my-script.pid`    — two concurrent runs both write,
   one overwrites the other. Use `flock` on the file, or `set -C` to
   make the create-and-check atomic.

## Hint 2 — fix sketch
```diff
-if [ -f "$lockfile" ]; then
-  echo "already running" >&2
-  exit 1
-fi
-echo "$$" > "$lockfile"
-trap 'rm -f "$lockfile"' EXIT
+exec 200>"$lockfile"
+flock -n 200 || { echo "already running" >&2; exit 1; }
+printf '%d\n' $$ >&200
+trap 'rm -f "$lockfile"' EXIT
+trap 'rm -f "$lockfile"; exit 130' INT
+trap 'rm -f "$lockfile"; exit 143' TERM

-tmp=$(mktemp)
-echo "generated at $(date)" > "$tmp"
-mv "$tmp" "$target"
+tmp=$(mktemp "$(dirname "$target")/.cache.XXXXXX")
+trap 'rm -f "$tmp"' EXIT     # add this on top of the lockfile cleanup
+printf 'generated at %(%F %T)T\n' -1 > "$tmp"
+mv -- "$tmp" "$target"        # same fs -> atomic rename

-echo $$ > /var/run/my-script.pid
+# `set -C` makes ">" fail if the file already exists (race-free).
+( set -C; printf '%d\n' $$ > /var/run/my-script.pid ) 2>/dev/null ||
+  { echo 'pid file owned by another instance' >&2; exit 1; }
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 22 README "Variants" table — `[ -f LOCK ] && exit` IS the wrong way |
| 2   | ex. 8 + ex. 22 (signal cleanup) |
| 3,4 | ex. 22 "Trick: atomic file replacement via `mv` (same filesystem)" |
| 5   | ex. 22 "Trick: `set -C` (noclobber) — first-writer-wins" |
