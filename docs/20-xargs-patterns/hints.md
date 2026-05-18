# Hints for `buggy.sh` (exercise 20)

Five bugs all about the `xargs` / `find` NUL-pairing.

## Hint 1 — locations
1. `ls "$dir" | xargs sha256sum`  — `ls` for parsing is BashPitfalls #3.
   Splits on whitespace; quote characters get re-interpreted.
2. `xargs -P "$jobs" -I{} sha256sum {}` — `-I{}` implies `-L 1` (one item per
   call). That gives parallelism (`-P`) but loses the batching efficiency of
   `xargs`'s default behaviour. Often fine — but for sha256sum on small
   files, the fork-per-file dominates. Use `xargs -P "$jobs" -n 100`.
3. `xargs -0 rm` (no `-r`)         — if `find` produced no matches, `rm`
   still runs (with no args) and errors out. Add `-r` (GNU) or `--no-run-if-empty`.
4. `xargs -0 head -1`              — parallel doesn't apply here, but output
   interleaving between files is silent without `-n 1` and `--max-args`.
5. `xargs -n 100 -P "$jobs"` with `find ... |` (no `-print0` / `-0`) — back
   to word-splitting on whitespace. Combine NUL on both sides.

## Hint 2 — fix sketch
```diff
-ls "$dir" | xargs sha256sum
+find "$dir" -type f -print0 | xargs -0r sha256sum

-find "$dir" -type f | xargs -P "$jobs" -I{} sha256sum {}
+find "$dir" -type f -print0 | xargs -0r -P "$jobs" -n 1 sha256sum

-find "$dir" -name '*.tmp' -print0 | xargs -0 rm
+find "$dir" -name '*.tmp' -print0 | xargs -0r rm

-find "$dir" -type f -print0 | xargs -0 head -1
+find "$dir" -type f -print0 | xargs -0r -n 1 head -1

-find "$dir" -type f | xargs -n 100 -P "$jobs" sha256sum
+find "$dir" -type f -print0 | xargs -0r -n 100 -P "$jobs" sha256sum
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | BashPitfalls #3 (`ls` parsing); ex. 20 "How to break xargs" |
| 2   | ex. 20 "Trick: `-I{}`" — *"`-I` implies `-L 1`"* |
| 3   | ex. 20 "Trick: `-r` / `--no-run-if-empty`" |
| 4   | ex. 20 "Trick: `-P N`" — output interleaving |
| 5   | ex. 20 "Trick: `-0`" |
