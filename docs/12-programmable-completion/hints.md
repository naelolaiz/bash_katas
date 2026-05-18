# Hints for `buggy.sh` (exercise 12)

Five bugs. Tab-completion will appear to "kinda work" but fail on weird
filenames or repeated options.

## Hint 1 — locations
1. `compgen -f $cur`          — `$cur` unquoted; if it contains spaces,
   you'll see all files. Also missing `-- "$cur"` (the `--` so a `$cur`
   starting with `-` isn't taken as a compgen option).
2. `compgen -W ... $cur`       — same problem; `compgen` needs `-- "$cur"`
3. `ls $cur*`                  — `ls`-piped-anywhere is broken (BashPitfalls #3);
   `ls` formats for humans, not for parsing. Use `compgen -f -- "$cur"`.
4. No dedupe of already-supplied options — if user types `--quiet --` and
   tabs, `--quiet` should NOT appear in suggestions.
5. No `--output=FILE` support — `cur=--output=foo` should complete files
   under `foo*` and prepend `--output=`.

## Hint 2 — minimal fix sketch
```diff
-    COMPREPLY=( $(compgen -f $cur) )
+    COMPREPLY=( $(compgen -f -- "$cur") )

-    COMPREPLY=( $(compgen -W '--help --quiet --verbose --output' $cur) )
+    local all_opts='--help --quiet --verbose --output'
+    local remaining=''
+    for opt in $all_opts; do
+      [[ " ${COMP_WORDS[*]} " == *" $opt "* ]] || remaining+=" $opt"
+    done
+    COMPREPLY=( $(compgen -W "$remaining" -- "$cur") )

-    COMPREPLY=( $(ls $cur*) )
+    COMPREPLY=( $(compgen -f -- "$cur") )

+  # --output=VALUE case
+  if [[ $cur == --output=* ]]; then
+    local v=${cur#*=}
+    COMPREPLY=( $(compgen -f -- "$v") )
+    return
+  fi
```

## Why
| Bug | Reference |
| --- | --------- |
| 1,2 | ex. 12 "Trick: anatomy of a completion function" — `-- "$cur"` |
| 3   | BashPitfalls #3 (parsing `ls`) |
| 4   | ex. 12 "Trick: filter out already-used options" |
| 5   | ex. 12 "Trick: completion for `--key=value`" |
