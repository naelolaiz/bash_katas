# Hints for `buggy.sh` (exercise 15)

⚠️ This is the destructive one — **only run against a throwaway directory**:

```bash
mkdir -p /tmp/jt && touch /tmp/jt/{a,b,c} && cp /tmp/jt/a /tmp/jt/dup
podman run --rm -v /tmp/jt:/jt:rw localhost/bash-katas:dev \
    bash -c 'cd / && /work/docs/15-capstone-repo-janitor/buggy.sh /jt'
```

Seven bugs that together turn this from "janitor" into "shredder".

## Hint 1 — categories
- Defaults dangerous: `dry_run=0`, no `--apply` gate
- NUL-unsafe traversal (`find $dir | while read`)
- Concurrent runs race because there's no lock
- `xargs rm` ignores `--dry-run`
- `find ... -exec rm -rf {} \;` mid-traversal is a recipe for "walked into a
  directory that got deleted under me"

## Hint 2 — locations
1. `dry_run=0`                    — default must be safe; opt IN to deletion
2. `find $dir ... | while read`    — unquoted `$dir`, no `-print0`, no `-r -d ''`,
   AND the pipeline subshell loses `first[]` updates between iterations
3. `${first[$h]}` (no `:-`)        — fails the first time `$h` isn't in array, under `set -u`
4. `rm -f $path`                   — unquoted, no `--`; if `$path` is `-rf` you
   just got an `rm -f -rf` (no-op for `-rf` as filename, but the principle is the bug)
5. `xargs -0 rm` always runs       — doesn't check `$dry_run`
6. `-exec rm -rf {} \;` on dirs in the SAME traversal — `find` may revisit
   already-deleted paths or descend into them
7. No `flock`                      — two concurrent `repo-janitor /` will both
   delete the duplicates of each other and race on the same files

## Hint 3 — fix sketch
```diff
-dry_run=0
+dry_run=1
+while [[ $# -gt 0 ]]; do
+  case $1 in
+    --apply) dry_run=0; shift ;;
+    --dry-run) dry_run=1; shift ;;
+    *) break ;;
+  esac
+done
+
+exec 200>"/var/lock/repo-janitor.lock"
+flock -n 200 || { echo 'already running' >&2; exit 1; }

-find $dir -type f | while read path; do
+while IFS= read -r -d '' path; do
   ...
-    rm -f $path
+    (( dry_run )) && echo "would delete $path" || rm -f -- "$path"
   ...
-done
+done < <(find "$dir" -type f -print0)

-find $dir -type l -xtype l -print0 | xargs -0 rm
+find "$dir" -type l -xtype l -print0 \
+  | xargs -0r bash -c '
+      for f; do
+        if (( '"$dry_run"' )); then echo "would delete (broken link) $f"
+        else rm -f -- "$f"
+        fi
+      done
+    ' _

-find $dir -type d \( -name node_modules -o -name .cache \) -exec rm -rf {} \;
+# collect first, delete after walk completes
+mapfile -d '' junk < <(find "$dir" -type d \( -name node_modules -o -name .cache \) -print0)
+for d in "${junk[@]}"; do
+  (( dry_run )) && echo "would delete (junk dir) $d" || rm -rf -- "$d"
+done
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | spec: "dry-run by default" |
| 2,3 | ex. 2, ex. 4, ex. 8 |
| 4,5 | BashPitfalls #1; `rm` safety with `--` |
| 6   | `find -exec rm` race on directory traversal |
| 7   | ex. 22 (locking) |
