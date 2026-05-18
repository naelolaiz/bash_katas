# Hints for `buggy.sh` (exercise 10)

Four bugs around coproc lifecycle. The script appears to work — until `bc`
takes a long time, or dies, or you type `quit`.

## Hint 1 — locations
1. `read -r answer <&"${BC[0]}"` — no `-t TIMEOUT`. If `bc` errors and
   produces nothing on stdout (just stderr), this hangs forever.
2. No `trap '' PIPE` and no `kill -0 $BC_PID` check — when `bc` dies,
   writing to it raises SIGPIPE which kills the whole script.
3. `wait $BC_PID` — `bc` keeps reading until its stdin closes. Without
   `exec {BC[1]}>&-` first, the wait hangs.
4. No `bc` restart logic — README requires "if bc dies mid-session,
   restart it transparently".

## Hint 2 — minimal fix sketch
```diff
 coproc BC { bc -l; }
+trap '' PIPE     # SIGPIPE from writes to dead bc becomes a normal EPIPE

 while IFS= read -r -p '> ' expr; do
   [[ -z $expr ]] && continue
   [[ $expr == quit ]] && break

+  # restart bc if it died
+  if ! kill -0 "$BC_PID" 2>/dev/null; then
+    coproc BC { bc -l; }
+    echo 'bc restarted' >&2
+  fi
+
   printf '%s\n' "$expr" >&"${BC[1]}"

-  read -r answer <&"${BC[0]}"
+  if ! read -r -t 5 answer <&"${BC[0]}"; then
+    echo 'bc timed out (5s)' >&2
+    continue
+  fi
   printf '= %s\n' "$answer"
 done

-wait $BC_PID
+exec {BC[1]}>&-      # close write end so bc sees EOF
+wait "$BC_PID"
 echo "bye"
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 10 "Trick: timeout handling with `read -t`" |
| 2   | ex. 10 "Trick: detect coproc death"; ex. 26 (SIGPIPE) |
| 3   | ex. 10 README — "Forgetting to close the write FD before `wait` makes the child block forever" |
| 4   | exercise spec: "if bc dies mid-session, restart it transparently" |
