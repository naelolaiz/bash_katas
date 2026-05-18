# 2. NUL-safe file collector


**Goal:** Process arbitrary filenames safely, with multiple enumeration strategies.

### Techniques

#### Trick: `find -print0` + `read -r -d ''` — the canonical NUL-safe pair

```bash
mkdir -p /tmp/nul && cd /tmp/nul && touch "a b.txt" $'line\nbreak.txt' c.txt
find . -type f -name '*.txt' -print0 |
  while IFS= read -r -d '' path; do
    printf 'got: %s\n' "$path"
  done
```

**What's happening:** `find -print0` separates filenames with NUL bytes — the one byte that cannot appear in a filename. `read -d ''` sets the delimiter to NUL (empty-string delimiter selects NUL). `IFS=` prevents leading/trailing whitespace stripping. `-r` disables backslash escape processing.
**Gotcha:** `IFS=` and `-r` are easy to forget. Without them, leading spaces get stripped and backslash-newline gets eaten — silently.
**When to use:** the default for "process files from `find` in a loop".

#### Trick: `mapfile -d ''` — read NUL-separated stream into an array (bash 4.4+)

```bash
mapfile -d '' files < <(find . -type f -name '*.txt' -print0)
printf 'count: %d\n' "${#files[@]}"
for f in "${files[@]}"; do printf '  %s\n' "$f"; done
```

**What's happening:** `mapfile -d ''` reads NUL-delimited records into the array directly, one element per record. Process substitution `< <(...)` keeps the array in the current shell — a piped `while read` runs in a subshell so any variable assignment inside dies with it.
**Gotcha:** `-d` is bash 4.4+. macOS system bash is 3.2 — fall back to the `while read` loop.
**When to use:** when you want length, random access, or to iterate twice over the same list.

#### Trick: globstar — let bash enumerate, skip `find` entirely

```bash
shopt -s globstar nullglob dotglob
files=(/tmp/nul/**/*.txt)
printf 'count: %d\n' "${#files[@]}"
for f in "${files[@]}"; do printf '  %s\n' "$f"; done
```

**What's happening:** [`globstar`](https://www.gnu.org/s/bash/manual/html_node/The-Shopt-Builtin.html#index-globstar) makes `**` match across directory boundaries. [`nullglob`](https://www.gnu.org/s/bash/manual/html_node/The-Shopt-Builtin.html#index-nullglob) turns "no match" into an empty array instead of a literal `**/*.txt`. `dotglob` includes dot-files. NUL-safe by construction — each name is its own array element.
**Gotcha:** without `globstar`, `**` is just `*` (one path component). Without `nullglob`, an unmatched glob expands to itself — your `for f in` loop runs once with the literal pattern. `**` follows symlinks; a self-link causes infinite enumeration.
**When to use:** small, known trees. Zero forks. Best when you control the directory layout.

#### Trick: `git ls-files -z` — only the tracked files

```bash
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || exit
git ls-files -z '*.txt' |
  while IFS= read -r -d '' path; do
    printf '  %s\n' "$path"
  done
```

**What's happening:** `git ls-files` reads from the index. Fast, NUL-separated with `-z`, respects `.gitignore` for free.
**Gotcha:** only inside a git repo. Untracked new files are invisible until staged. Add `-o --exclude-standard` to include untracked-but-not-ignored files.
**When to use:** any script that operates on "source files". Faster than `find` on large trees and ignores `node_modules`/`target`/etc. without configuration.

#### Trick: `ls --quoting-style=shell-always` — and why it's still wrong for scripts

```bash
ls --quoting-style=shell-always /tmp/nul
# 'a b.txt'
# 'line'$'\n''break.txt'
# 'c.txt'
```

**What's happening:** GNU `ls` can emit re-parseable quoted output. Looks fixed.
**Gotcha:** still parsed as one *line* per file, and re-parsing requires `eval` — which means a filename containing `` ` `` or `$(…)` becomes code execution. Don't do this in scripts.
**When to use:** never in scripts. Only when you (a human) want to copy a weird filename out of the terminal.

### The exercise

Write `bin/collect-ext`:

```
collect-ext [--nul] [--source SRC] EXT DIR
```

- prints files under `DIR` with extension `EXT`, NUL-separated if `--nul`, newline-separated otherwise
- `--source` selects the backend: `find` (default), `glob` (globstar), `git` (git ls-files)
- rejects extensions containing `/`

Produce **all three backends** and a comparison table covering: speed on a 10k-file tree, behaviour on an empty directory, behaviour on a symlink loop, behaviour outside a git repo.

### Variants comparison

| Backend             | Speed (10k files)   | Empty dir              | Symlink loop      | Outside git   |
| ------------------- | ------------------- | ---------------------- | ----------------- | ------------- |
| `find -print0`      | fast                | empty                  | safe (no follow)  | works         |
| globstar            | slowest (bash loop) | empty (with nullglob)  | infinite!         | works         |
| `git ls-files -z`   | fastest             | empty                  | n/a (index-only)  | fails         |

### Optional: locked variant

Solve **without `find`** — globstar only. Then deliberately create a symlink loop (`ln -s . /tmp/nul/loop`) and observe what happens. Fix it: either avoid `**` and walk the tree iteratively with an explicit visited-set, or fall back to `find -L ... -maxdepth N`.

### Optional: scoring rubric

- [ ] all three backends produce the same set of filenames on a clean tree
- [ ] `--nul` output round-trips through `xargs -0 stat -c %n` without errors on weird filenames
- [ ] extension `foo/bar` is rejected with a useful error and exit code 2
- [ ] passes `shellcheck` clean
- [ ] (locked) symlink loop doesn't hang the script

### Break it

- [ ] filenames containing `$'\n'`, `$'\t'`, `'`, `"`, `\`, leading `-`, leading `--`
- [ ] empty directory
- [ ] directory containing only dot-files (test with and without `dotglob`)
- [ ] symlink loop: `ln -s . /tmp/nul/loop`
- [ ] subdirectory with no read permission
- [ ] `EXT` argument is `*` (literal asterisk in a filename)
- [ ] `DIR` doesn't exist (clean failure, not a stack trace)



---

[← ex. 1](../01-expansion-prediction/) · [ex. 3 →](../03-path-components/)
