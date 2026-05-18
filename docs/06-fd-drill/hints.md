# Hints for `buggy.sh` (exercise 6)

This buggy version is short but every line is wrong. The exit code never
reflects the wrapped command's status, and the redirection order writes
nothing useful to the file.

## Hint 1 — vague
Two things to get right:
- Redirection order (`2>&1 > file` vs `> file 2>&1`) — see ex. 6 "Trick: order matters"
- Which command's exit status `$?` actually reports after a pipeline

## Hint 2 — locations
1. `"$@" 2>&1 > "$logfile" | tee -a "$logfile"`
   - `2>&1` BEFORE `> "$logfile"` ⇒ stderr goes to wherever stdout pointed
     *before* the file redirect (the pipe), then stdout goes to the file
     — net effect: only stderr reaches `tee`, stdout sits in the file twice
   - `tee -a "$logfile"` ALSO writes to the same file — interleaving mess
2. `status=$?` — `$?` is `tee`'s exit code (the last command in the pipeline),
   NOT the wrapped command's. Without `set -o pipefail` you can't even detect
   the command's failure. With PIPESTATUS, you can.

## Hint 3 — minimal fix sketch
```diff
-"$@" 2>&1 > "$logfile" | tee -a "$logfile"
-status=$?
+set -o pipefail
+"$@" 2>&1 | tee "$logfile"
+status=${PIPESTATUS[0]}
```

Or with process substitution for separated streams (the proper exercise solution):
```bash
"$@" \
  > >(tee -a "$logfile") \
  2> >(tee -a "$logfile" >&2)
status=${PIPESTATUS[0]}
```

## Why this matters
| Bug | Reference |
| --- | --------- |
| 1   | ex. 6 "Trick: order matters in `2>&1`" |
| 2   | ex. 6 "Trick: PIPESTATUS" |
