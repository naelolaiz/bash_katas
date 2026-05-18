# Hints for `buggy.sh` (exercise 26)

Five bugs. Most fire only when you actually send a signal — `sleep 100`
the child, then Ctrl-C the wrapper, and observe.

## Hint 1 — locations
1. `exit` (no argument)        — exits with `$?` of the previous command
   (`rm -rf "$tmpdir"`). If you wanted to propagate the killing signal as
   `128+N`, you must `exit "$((128 + signo))"` explicitly.
2. `trap cleanup INT TERM EXIT` — same function on three events. When
   `INT` fires, `cleanup` runs once, then EXIT fires and `cleanup` runs
   again. `rm -rf` is idempotent so this LOOKS fine, but it doubles
   logging and burns through any once-only counters.
3. `wait "$pid"`               — in bash <4.3, `wait` is not interruptible
   by signals. Pressing Ctrl-C is queued until `wait` returns. Use
   `wait -n` in a loop, or `kill -0 "$pid"` polling.
4. No `trap '' PIPE`           — if the wrapper's stdout is piped to
   `head -1`, the wrapper dies as soon as it writes after `head` closes.
5. `exit $status`              — if the child was killed by signal N,
   bash's `wait` returns `128+N`. Forwarding it is fine — but the
   exercise asks you to RE-RAISE the signal in some cases (so the
   parent shell sees "killed by signal N"). The minimal "propagate exit"
   is correct; the more correct version is `kill -SIGNAL "$$"` after
   cleanup.

## Hint 2 — fix sketch
```diff
 cleanup() {
   rm -rf "$tmpdir"
-  exit
+  exit "${1:-0}"
 }
-trap cleanup INT TERM EXIT
+# Don't double up: signal handlers explicitly do their cleanup AND exit,
+# then disable EXIT trap so it doesn't re-run.
+trap 'trap - EXIT; cleanup 130' INT      # 128 + 2
+trap 'trap - EXIT; cleanup 143' TERM     # 128 + 15
+trap 'cleanup'         EXIT

+trap '' PIPE              # surviving SIGPIPE

 "$@" &
 pid=$!

-wait "$pid"
+# wait -n + loop is interruptible by signals on modern bash
+while ! wait -n 2>/dev/null; do
+  kill -0 "$pid" 2>/dev/null || break
+done
+wait "$pid" || status=$?
+status=${status:-0}

 echo "child exited $status"
 exit "$status"
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 26 "Trick: propagating killed-by-signal as exit 128+N" — *"plain `exit` returns previous `$?`"* |
| 2   | ex. 26 "Trick: catch signals AND propagate the correct exit code" — *"EXIT fires AFTER your signal handler"* |
| 3   | ex. 26 "Trick: signals + `wait` quirk" |
| 4   | ex. 26 "Trick: surviving SIGPIPE" |
| 5   | exercise spec: "command's killed-by-signal-N exit code propagated as 128+N" |
