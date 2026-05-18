# 7. Manifest diff


**Goal:** Compare generated streams without temp files. Covers stable serialisation and meaningful exit codes.

### Techniques

#### Trick: [process substitution](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html) to compare two computed streams

```bash
diff -u <(LC_ALL=C find /tmp/a -type f -print0 | LC_ALL=C sort -z) \
        <(LC_ALL=C find /tmp/b -type f -print0 | LC_ALL=C sort -z)
```

**What's happening:** each `<(...)` exposes the output of a command as a filename, so `diff` doesn't need temp files. `LC_ALL=C` makes `sort` use byte ordering (otherwise locale rules can reorder seemingly-identical lines). `-z` keeps NUL-separated records — but most `diff` implementations don't understand NUL, so for diff you usually fall back to newlines + careful escaping.
**Gotcha:** `diff`'s exit code: 0 = same, 1 = different, 2 = trouble. Don't [`set -e`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html) around `diff` and treat 1 as failure.
**When to use:** any "before vs. after" comparison of a derived view (file list, env dump, schema dump, ldd output).

#### Trick: stable, line-safe serialisation format

```bash
manifest() {
  local dir=$1
  (cd "$dir" && find . -type f -print0) |
    while IFS= read -r -d '' rel; do
      local size sha
      size=$(stat -c '%s' "$dir/$rel")
      sha=$(sha256sum "$dir/$rel" | cut -d' ' -f1)
      # tab-separated, with embedded tabs/newlines in `rel` quoted:
      printf '%s\t%d\t%q\n' "$sha" "$size" "$rel"
    done | LC_ALL=C sort
}
```

**What's happening:** `%q` quotes the path so the line is always exactly one line, even for filenames containing tabs or newlines. `LC_ALL=C sort` gives byte-stable ordering that won't shift between systems with different locales.
**Gotcha:** `sha256sum` and `stat` have GNU and BSD variants with different flags (`stat -f '%z'` on macOS). The whole loop forks `stat` and `sha256sum` per file — slow on large trees; consider a single `find -exec sha256sum {} +`.
**When to use:** any "snapshot" format that needs to diff cleanly across runs.

#### Trick: `comm` for set-diff on sorted input (when you only need added/removed)

```bash
# files in B but not in A:
comm -13 <(cd /tmp/a && find . -type f | LC_ALL=C sort) \
         <(cd /tmp/b && find . -type f | LC_ALL=C sort)
```

**What's happening:** `comm` reads two sorted files and prints 3 columns: only-in-1, only-in-2, in-both. `-13` suppresses columns 1 and 3, leaving only-in-2 (i.e. "added in B"). `-23` gives "removed in A→B". `-12` is intersection.
**Gotcha:** input MUST be sorted — under the same locale — or `comm` silently misbehaves. Always force `LC_ALL=C sort` on both sides.
**When to use:** when you only need set diff (added/removed/common), not a line-by-line `diff`. Faster and cleaner output for the "what changed" use case.

#### Trick: exit-code propagation through process substitution

```bash
set -o pipefail
if diff -u <(manifest "$old") <(manifest "$new"); then
  exit 0       # same
fi
case $? in
  1) exit 1 ;; # different — expected
  *) exit 2 ;; # trouble in diff itself
esac
```

**What's happening:** the `if` branch swallows the exit code of the controlled command, so `$?` immediately afterwards is the `diff` exit code. PIPESTATUS does NOT cover process substitutions, so failures inside `<(manifest …)` are invisible to the outer command — you have to capture them differently (write a sentinel file, check after).
**Gotcha:** if `manifest` itself fails inside `<(...)`, `diff` happily diffs whatever partial output came out. Always set [`pipefail`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html) *inside* the substituted command, or have `manifest` exit on error and produce nothing.
**When to use:** any wrapper script that needs to distinguish "different" from "broken".

### The exercise

Write `bin/manifest DIR` producing tab-separated `<sha256>\t<size>\t<quoted-path>` per file, sorted under `LC_ALL=C`. Then write `bin/manifest-diff OLD NEW` returning:
- exit 0 if identical
- exit 1 if different (and print a `diff -u`)
- exit 2 if either manifest couldn't be built

Implement `manifest-diff` **two ways**: (a) using `diff <(manifest …) <(manifest …)`, (b) using `comm -3` on sorted manifests for a cleaner added/removed view. Compare the output and the failure-handling story.

### Variants comparison

| Diff tool         | Output style       | Detects content change   | Detects rename   | Locale-sensitive |
| ----------------- | ------------------ | ------------------------ | ---------------- | ---------------- |
| `diff -u`         | unified context    | yes (hash differs)       | as add+remove    | yes (set `LC_ALL=C`) |
| `comm -3`         | three columns      | yes                      | as add+remove    | yes (set `LC_ALL=C`) |
| `git diff --no-index` | git-style       | yes                      | rename detection | yes              |

### Optional: locked variant

Build `manifest-diff` **without process substitution** — use named pipes (`mkfifo`) or actual temp files cleaned up with `trap EXIT`. Compare ergonomics. Why is the process-substitution version usually preferred?

### Optional: scoring rubric

- [ ] manifest output is byte-identical across runs on the same tree (no timestamp leak, no locale leak)
- [ ] exit codes: 0/1/2 as specified
- [ ] failure to read a file in OLD or NEW exits 2 with a clear error
- [ ] handles filenames with tabs, newlines, spaces, leading dashes
- [ ] passes `shellcheck` clean

### Break it

- [ ] OLD is empty, NEW has files
- [ ] OLD and NEW identical except for mtimes (manifest must not depend on mtime)
- [ ] a file is unreadable (permission denied) in NEW
- [ ] a symlink in NEW points outside the tree
- [ ] filename containing tab: `printf '\t' > /tmp/b/$'a\tb'`
- [ ] very large file (~1 GB) — does hashing complete in reasonable time?
- [ ] OLD is a file, not a directory



---

[← ex. 6](../06-fd-drill/) · [ex. 8 →](../08-traps-and-cleanup/)
