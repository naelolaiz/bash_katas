# 19. `find` deep-dive


**Goal:** Use `find` flags experienced users routinely forget — and stop chaining `find | xargs stat | awk` when `find -printf` already does it.

### Techniques

#### Trick: `-prune` — the *only* correct way to skip a subtree

```bash
# skip node_modules and .git, list everything else
find . \( -name node_modules -o -name .git \) -prune -o -type f -print

# also skip hidden dirs but keep hidden files
find . -type d -name '.*' -prune -o -type f -print
```

**What's happening:** `-prune` is an action that means "don't descend into this directory". The pattern is `\( bad-dirs \) -prune -o real-stuff -print` — without the explicit `-print` on the right side, find's default `-print` applies to pruned dirs too.
**Gotcha:** `find . -type f -not -path '*/node_modules/*'` *also* works but is **massively slower** on large trees — find still descends into `node_modules`, just doesn't print results from there. `-prune` actually skips the directory.
**When to use:** any traversal that should skip `node_modules`, `target`, `build`, `.git`, etc.

#### Trick: `-exec ... +` vs `-exec ... \;`

```bash
# slow: forks `wc -l` per file
find . -name '*.log' -exec wc -l {} \;

# fast: one `wc -l` with all files batched
find . -name '*.log' -exec wc -l {} +
```

**What's happening:** `\;` runs the command *once per file* (one fork each). `+` accumulates as many filenames as fit on a command line and runs the command in batches (typically once total on a normal-sized tree).
**Gotcha:** `+` requires `{}` to be the **last** thing before the terminator. `find -exec cmd --flag {} file +` errors out. Use `-execdir` (next trick) if you need to change directory per match.
**When to use:** always `+` when the command can take multiple files (`wc`, `grep`, `cat`, `chmod`). Only `\;` when the command takes exactly one file or when ordering matters.

#### Trick: `-execdir` — run in the file's directory

```bash
find . -name 'go.mod' -execdir go mod tidy \;
```

**What's happening:** `-execdir` `cd`'s into the file's parent directory before running the command. `{}` is replaced with the basename only (with a `./` prefix for safety).
**Gotcha:** safer than `-exec` because the working directory is always the file's parent (no surprises from a process-wide `cwd`). The `./` prefix protects against `find` matching a file named `-rf` and `cmd {}` becoming `cmd -rf`.
**When to use:** any per-directory action — running formatters, regenerating per-dir output, `git pull`-ing each submodule.

#### Trick: `-printf` formats — eliminates `stat | awk`

```bash
# instead of: find . -type f -exec stat -c '%n %s %Y' {} +
find . -type f -printf '%p\t%s\t%TY-%Tm-%Td %TH:%TM:%TS\n'

# size + path, sorted descending:
find . -type f -printf '%s\t%p\0' | sort -rnz | head -zn 10 | tr '\0' '\n'
```

**What's happening:** GNU `find -printf` understands a wide format vocabulary: `%p` path, `%s` size, `%T@` mtime as Unix timestamp, `%TY-%Tm-%Td` formatted date, `%M` permissions, `%u`/`%g` user/group, `%y` file type. One process, zero `awk`.
**Gotcha:** GNU-only. BSD/macOS `find` doesn't have `-printf` (use `-print` then `stat` per file, or `gfind` from homebrew coreutils).
**When to use:** any "list files with metadata" task on Linux. Faster and shorter than the `find | xargs stat` form.

#### Trick: `-newer FILE` and `-newermt 'DATE'`

```bash
# files modified after a marker file
touch /tmp/marker
sleep 5; touch /tmp/changed
find /tmp -type f -newer /tmp/marker -printf '%p\n'

# files modified after a timestamp
find . -type f -newermt '2026-01-01' -printf '%p\n'

# files modified in the last hour
find . -type f -mmin -60 -printf '%p\n'
```

**What's happening:** `-newer FILE` matches anything newer than FILE's mtime. `-newerXY REF` compares time X (a=access, c=ctime, m=mtime, B=birth) against reference Y (file, mt=mtime, ct=ctime, at=atime, e.g. `-newermt`). `-mmin N` is "modified ≤ N minutes ago" (negative = within).
**Gotcha:** `-mtime -1` is *NOT* "within the last 24h" — `-mtime` units are 24h periods, rounded toward zero. For "last hour" use `-mmin -60`. For "within the last day" use `-mmin -1440`.
**When to use:** incremental builds, "what changed since last run", backup scripts.

#### Trick: `-regex` and `-regextype`

```bash
# default regex is "basic" (broken); fix it
find . -regextype posix-extended -regex '.*/[a-z]+-[0-9]+\.log'

# match against the full path, not just basename:
find . -regextype posix-extended -regex '.*/src/.+\.go$'
```

**What's happening:** `-regex` matches against the *full path* by default (with the leading `./`). `-regextype` selects the engine — POSIX BRE is the default and almost never what you want; POSIX ERE matches the rest of the world.
**Gotcha:** `-regex` is a *full* match (implicit `^...$`), unlike most regex tools. To match part of the path, use `.*` on both sides. `-iregex` is the case-insensitive form.
**When to use:** when `-name`/`-path` glob patterns aren't expressive enough; otherwise prefer `-path` for readability.

#### Trick: `-not`, `!`, `-o`, parentheses — Boolean logic

```bash
# files that are EITHER bigger than 1G OR older than 30 days, but NOT in archive/
find . -type f \
  \( -size +1G -o -mtime +30 \) \
  -not -path '*/archive/*' \
  -print
```

**What's happening:** find expressions form a Boolean tree. Implicit `-a` between adjacent tests. `-o` for OR. `!` or `-not` for NOT. Parentheses `\( ... \)` for grouping (escaped to hide from the shell).
**Gotcha:** operator precedence: `-a` binds tighter than `-o`, as in most programming languages; `-not` binds tightest. `-print` (or any action) is *itself* a predicate — `a -o b -print` means "a OR (b AND print)", which is a frequent source of bugs.
**When to use:** complex predicates that would otherwise need a wrapper script.

### The exercise

Build `bin/repo-find` that lists files in a repo, skipping `node_modules`, `.git`, `target`, and `dist`, with output:

```
<size>\t<mtime-iso>\t<path>
```

Implement it **three times**:

1. `find ... -printf` (one process, GNU only)
2. `find ... -print0 | xargs -0 stat -c ...` (portable, two processes)
3. `find ... | python3 -c 'import os, sys; …'` (portable, one process, more code)

Compare runtime on a 50k-file tree. Then add a `--newer SINCE` option using `-newermt`.

### Variants comparison

| Form                                 | GNU only? | Forks  | Notes                            |
| ------------------------------------ | --------- | ------ | -------------------------------- |
| `find -printf '%p %s %T@'`           | yes       | 1      | fastest; very expressive         |
| `find -print0 \| xargs -0 stat -c …` | no        | 2      | portable; needs `stat` flags     |
| `find -print0 \| while read -d ''`   | no        | 1 + bash loop | slow for large trees      |
| `fd` (Rust replacement)              | extra dep | 1      | nicer defaults; respects gitignore |

### Optional: locked variant

Build `repo-find` **POSIX-portable** — no `-printf`, no `-newermt`, no `-execdir`. Use only POSIX `find` predicates and pipe to `stat`/`date`. Compare LOC and behaviour.

### Optional: scoring rubric

- [ ] all three implementations produce identical output (modulo column whitespace)
- [ ] `--newer` correctly filters by mtime
- [ ] `node_modules`/`.git`/etc. are pruned, not just filtered (verify with `time` on a tree containing one)
- [ ] handles filenames with spaces, tabs, and newlines
- [ ] passes `shellcheck` clean

### Break it

- [ ] tree containing a symlink loop (does `find` follow it? -L vs -P)
- [ ] file owned by another user with no read permission
- [ ] filename with embedded newline
- [ ] directory whose name matches the prune pattern but contains files you wanted
- [ ] `--newer` referencing a future date
- [ ] mtime exactly equal to the boundary (edge case for `-newermt`)



---

[← ex. 18](../18-read-and-mapfile/) · [ex. 20 →](../20-xargs-patterns/)
