# 3. Path components, three ways


**Goal:** Decompose a path into dir/base/stem/ext using three different toolsets, then choose which to ship.

### Techniques

#### Trick: pure [parameter expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html) (zero forks)

```bash
path='/tmp/archive.tar.gz'
dir="${path%/*}"        # /tmp
base="${path##*/}"      # archive.tar.gz
ext="${base##*.}"       # gz
stem="${base%.*}"       # archive.tar
printf 'dir=%s base=%s stem=%s ext=%s\n' "$dir" "$base" "$stem" "$ext"
```

**What's happening:** `%/*` strips the shortest suffix starting at the last `/` — i.e. drops `/base`. `##*/` strips the longest prefix ending at the last `/` — i.e. drops `dir/`. The glob patterns are greedy with `##`/`%%`, lazy with `#`/`%`.
**Gotcha:** edge cases: bare `foo` (no slash → `dir == base == "foo"`); leading dot `.hidden` (`ext == "hidden"`, wrong); trailing `/` (`base == ""`); path with `.` in dir but not in base (`/foo.bar/baz` → `ext == "bar/baz"` if you skip the basename step). Always extract `base` first, then `ext`/`stem` from `base`, not from `path`.
**When to use:** any hot path; loops over thousands of filenames.

#### Trick: coreutils `basename` / `dirname` (clear, portable)

```bash
path='/tmp/archive.tar.gz'
dir=$(dirname  "$path")
base=$(basename "$path")
# GNU basename supports a -s suffix:
stem=$(basename -s ".${base##*.}" "$path")
ext="${base##*.}"
printf 'dir=%s base=%s stem=%s ext=%s\n' "$dir" "$base" "$stem" "$ext"
```

**What's happening:** `dirname` and `basename` are POSIX coreutils. `basename -s` (GNU) strips a suffix.
**Gotcha:** each call is a fork — at 100k paths the difference is seconds, not microseconds. `basename -s` is GNU-only; BSD/macOS `basename` is `basename PATH [SUFFIX]` (positional). The "strip last extension" idiom isn't directly expressible without knowing the extension first.
**When to use:** one-shot scripts where clarity beats speed; cross-shell scripts where parameter-expansion variant is less obvious to readers.

#### Trick: `awk -F/` (column-oriented when you have many paths)

```bash
paths=(/tmp/a.tar.gz /var/log/syslog.1 /etc/hostname)
printf '%s\n' "${paths[@]}" |
  awk -F/ '{
    base = $NF; sub(/^.*\//, "", $0)
    n = split(base, parts, ".")
    ext = (n > 1) ? parts[n] : ""
    stem = base; sub("\\." ext "$", "", stem)
    dir = base == $0 ? "." : substr($0, 1, length($0) - length(base) - 1)
    printf "dir=%s base=%s stem=%s ext=%s\n", dir, base, stem, ext
  }'
```

**What's happening:** one `awk` invocation processes the whole stream. `$NF` is the last field with `-F/`. `split()` breaks the basename on `.` to find the extension.
**Gotcha:** one fork total regardless of input size — great. But the code is harder to read and modify than the pure-bash version, and edge cases (`.hidden`, trailing `/`) need explicit handling.
**When to use:** column-shaped input from a pipeline; thousands of paths where the bash-loop overhead matters.

### The exercise

Write `bin/pathinfo` that accepts one or more paths and prints:

```
original=<path>
dir=<directory>
base=<basename>
stem=<filename without final extension>
ext=<final extension>
```

Implement it **three times**: `bin/pathinfo-pe` (pure parameter expansion), `bin/pathinfo-cu` (coreutils), `bin/pathinfo-awk` (awk pipeline). Run all three over 10k paths and a script-generated weird corpus; produce a trade-off comparison.

### Variants comparison

| Approach           | Forks per call  | Readability | Portability  | When to ship it              |
| ------------------ | --------------- | ----------- | ------------ | ---------------------------- |
| parameter expansion | 0              | medium      | bash 3.0+    | loops, libraries, hot paths  |
| coreutils           | 2 per path     | high        | POSIX        | one-shot scripts             |
| awk pipeline        | 1 total        | low         | POSIX        | bulk processing from a pipe  |

### Optional: locked variant

Solve **without `basename`, `dirname`, `sed`, `awk`, `cut`, `rev`, or `python`**. Pure parameter expansion only. Compare against the coreutils variant on a 10k-path corpus — what speed-up do you measure?

### Optional: scoring rubric

- [ ] all three implementations produce identical output on the test corpus
- [ ] each handles `.hidden`, `foo` (no ext), `foo.tar.gz`, trailing `/`, empty input
- [ ] each passes `shellcheck` clean
- [ ] trade-off paragraph cites a *measured* fork count and runtime, not a guess
- [ ] (locked) parameter-expansion version is at least 5× faster than coreutils on 10k paths

### Break it

- [ ] empty path: `bin/pathinfo ""`
- [ ] no extension: `bin/pathinfo foo`
- [ ] leading dot: `bin/pathinfo .hidden`
- [ ] multiple dots: `bin/pathinfo archive.tar.gz`
- [ ] dot in directory but not basename: `bin/pathinfo /foo.bar/baz`
- [ ] trailing slash: `bin/pathinfo /tmp/`
- [ ] path with newline: `bin/pathinfo $'a\nb/c'`
- [ ] very long path (>4096 chars)



---

[← ex. 2](../02-nul-safe-collector/) · [ex. 4 →](../04-log-summariser/)
