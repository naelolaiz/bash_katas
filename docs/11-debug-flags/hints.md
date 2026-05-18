# Hints for `buggy.sh` (exercise 11)

Five bugs around debug-channel hygiene. All fire when this script is used
inside a pipeline.

## Hint 1 — vague
The rule: **data on stdout, logs/traces on stderr (or a separate FD)**.
Several bugs violate it. One bug ruins performance under `--debug`.

## Hint 2 — locations
1. `PS4='+ $(date +%T): '`        — `$(date)` re-evaluates on EVERY traced
   line. On a loop, that's thousands of `date` forks. Use `'+ ${BASH_SOURCE}:${LINENO}: '`
   (no fork; bash-internal).
2. `echo "DRY: $*"`               — concatenates with single space; loses
   the distinction between `arg1` `"arg 2"` and `"arg1 arg"` `2`. Use `printf %q`.
3. `(( verbose )) && echo "[verbose] $*"` — to stdout. Pipes break.
4. `echo "result: $1"`            — fine, but under `--debug` the `set -x`
   prefix is on stderr, while the "result" is on stdout — interleaving
   depends on buffering. Not actually a bug if you accept stderr trace.
5. No `BASH_XTRACEFD`             — trace always goes to stderr; can't
   redirect to a separate trace file as the exercise spec requires.

## Hint 3 — minimal fix sketch
```diff
-PS4='+ $(date +%T): '
+PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-MAIN}: '

+if (( debug )); then
+  exec {tracefd}>>"${LOGFILE:-/dev/stderr}.trace"
+  export BASH_XTRACEFD=$tracefd
+  set -x
+fi

 run() {
   if (( dry_run )); then
-    echo "DRY: $*"
+    printf 'DRY: '; printf '%q ' "$@"; printf '\n'
   else
     "$@"
   fi
 }

 log() {
-  (( verbose )) && echo "[verbose] $*"
+  (( verbose )) && printf '[verbose] %s\n' "$*" >&2
 }
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 11 "Trick: rich PS4" — *keep it cheap; don't fork* |
| 2   | ex. 11 "Trick: safe `--dry-run` printing with `printf %q`" |
| 3   | ex. 11 "Trick: structured logging at multiple levels" |
| 5   | ex. 11 "Trick: `BASH_XTRACEFD`" |
