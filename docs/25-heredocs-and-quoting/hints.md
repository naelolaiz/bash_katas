# Hints for `buggy.sh` (exercise 25)

Five bugs around heredoc-quoting, atomic writes, and eval.

## Hint 1 — locations
1. `cat <<EOF` (no quotes on delimiter) — `$VAR`, `$(cmd)`, and `\$` are
   expanded in the body. For a SQL/YAML template you almost always want
   `<<'EOF'` (suppress expansion).
2. `echo "$content" > "$target"` — non-atomic write (concurrent readers
   see partial content) AND `echo` is unreliable for content starting with
   `-e` / `-n`. Use `printf '%s\n' ... > tmp && mv tmp target`.
3. `cat <<-EOF` with SPACES — `<<-` strips LEADING TABS only. If your
   editor inserts spaces, `<<-` does nothing. Convert to actual tabs.
4. `eval "$input"`              — RCE. `eval` on anything that touched
   user input is dangerous. For state round-tripping, parse explicitly
   (read line-by-line, validate format).
5. `some_cmd > /tmp/out`        — stderr still hits the terminal. If you
   want to capture both: `some_cmd &> /tmp/out` (bash) or `> /tmp/out 2>&1`
   (POSIX). Or `2> /tmp/err` to a separate file.

## Hint 2 — fix sketch
```diff
-content=$(cat <<EOF
+content=$(cat <<'EOF'
 database:
-  host: \${DB_HOST}
+  host: ${DB_HOST}
   ...
 EOF
 )

-echo "$content" > "$target"
+tmp=$(mktemp "$(dirname "$target")/.tmp.XXXXXX")
+trap 'rm -f "$tmp"' EXIT
+printf '%s\n' "$content" > "$tmp"
+mv -- "$tmp" "$target"

-cat <<-EOF
-    line one
-    line two
-    EOF
+cat <<-EOF
+	line one     <-- these MUST be real tab characters
+	line two
+	EOF

-eval "$input"
+# Don't eval untrusted input. Parse explicitly:
+while IFS='=' read -r key value; do
+  case $key in
+    SAFE_KEY1|SAFE_KEY2) ;; *) continue ;;
+  esac
+  printf -v "$key" '%s' "$value"
+done <<< "$input"

-some_cmd > /tmp/out
+some_cmd > /tmp/out 2>&1     # both to same file
+# OR: some_cmd > /tmp/out 2> /tmp/err   # separate
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 25 "Trick: `<<EOF` (expansion) vs. `<<'EOF'` (no expansion)" |
| 2   | ex. 22 (atomic mv); BashFAQ/072 (echo) |
| 3   | ex. 25 "Trick: `<<-EOF` — strip leading TABS" — *"only tabs, not spaces"* |
| 4   | OWASP-style command injection |
| 5   | ex. 25 "Trick: capturing stdout + stderr together" |
