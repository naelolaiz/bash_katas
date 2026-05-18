# Hints for `buggy.sh` (exercise 9)

Five bugs around concurrency bookkeeping and signal cleanup.

## Hint 1 — vague
Two failure modes:
- the "bound to N jobs" doesn't actually run N concurrently
- Ctrl-C leaves orphaned children running in the background

## Hint 2 — locations
1. `wait $pids`                  — `$pids` (no `[@]`) is just the first PID;
   `wait` without `-n` waits for ALL specified PIDs; even with `${pids[@]}`
   you'd wait for the whole batch, not "one slot free"
2. `pids=()`                     — drops the array; if you started 4 jobs
   and only 1 finished, you've forgotten the other 3
3. final `wait`                  — fine for waiting, but doesn't AGGREGATE
   exit statuses. If 5 of 100 children failed, you exit 0
4. no `trap INT TERM`            — Ctrl-C kills the script, leaves children
   alive (they're in the same process group; usually they die too, but if
   the script `setsid`'d them, they'd live on)
5. final `echo "all done"; exit 0` (implicit) — should propagate failure

## Hint 3 — minimal fix sketch
```diff
   if [[ ${#pids[@]} -ge $jobs ]]; then
-    wait $pids
-    pids=()
+    wait -n     # block until ONE finishes, freeing a slot
+    # don't reset pids[] -- the finished pid will fail wait $pid later, that's OK
   fi

-wait
+fail=0
+for pid in "${pids[@]}"; do
+  wait "$pid" || fail=$?
+done
+exit "$fail"

+# at top of script:
+cleanup() {
+  trap - INT TERM EXIT
+  (( ${#pids[@]} > 0 )) && kill "${pids[@]}" 2>/dev/null
+  wait 2>/dev/null
+}
+trap 'cleanup; exit 130' INT
+trap 'cleanup; exit 143' TERM
+trap cleanup EXIT
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 9 "Trick: `wait -n`" |
| 2   | ex. 9 — bookkeeping for finished pids |
| 3   | ex. 9 "Trick: aggregating exit status" |
| 4   | ex. 9 "Trick: signal-safe cleanup of children" |
| 5   | exit-status discipline |
