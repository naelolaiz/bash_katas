# 15. Capstone: repository janitor


**Goal:** Build a real tool that combines everything from exercises 1–14, then test it with [Bats](https://github.com/bats-core/bats-core).

This exercise combines techniques from earlier exercises rather than presenting new ones. The "Techniques" section below cross-references the relevant earlier exercise for each capability.

### Techniques (cross-references to earlier exercises)

#### Capability: enumerate files safely → ex. 2

```bash
# pick a backend per the call site
files=()
mapfile -d '' files < <(find "$dir" -type f -print0)
```

Use the `--source` switch idea from ex. 2 to pick `find` / globstar / `git ls-files` depending on whether you're inside a repo.

#### Capability: find duplicates by hash → ex. 4 (assoc-array counts), ex. 14 (batched awk)

```bash
declare -A first_seen   # hash -> first path
declare -A dupes        # hash -> count
while IFS= read -r -d '' path; do
  h=$(sha256sum "$path" | cut -d' ' -f1)   # or batch — see ex. 14
  if [[ -n "${first_seen[$h]:-}" ]]; then
    dupes["$h"]=$(( ${dupes["$h"]:-1} + 1 ))
  else
    first_seen["$h"]=$path
  fi
done < <(find "$dir" -type f -print0)
```

At 10k+ files, batch the hashing: `find ... -print0 | xargs -0 sha256sum` (ex. 14, ex. 20).

#### Capability: clean shutdown / atomic deletes → ex. 8

```bash
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM
# dry-run by default; --apply switches to real deletes
```

Always default to `--dry-run`. Require an explicit `--apply` (or `--force`) to actually delete. Make `--apply` *interactive* unless `--yes` is also given.

#### Capability: bounded-concurrency hashing → ex. 9

```bash
pmap -j "$(nproc)" sha256sum "${files[@]}"   # if your pmap from ex. 9 produces a stable mapping
```

Or pre-built: `find ... -print0 | xargs -0 -P "$(nproc)" sha256sum`.

#### Capability: structured output (JSON vs. tabular) → ex. 11 (log levels), ex. 16 (printf)

```bash
emit_json() {
  printf '{"category":"%s","path":"%s","size":%d}\n' "$1" "$2" "$3"
}
emit_tab() {
  printf '%s\t%s\t%d\n' "$1" "$2" "$3"
}
emit=${OUTPUT_FORMAT:-tab}_$( … )
```

For JSON, escape the path: bash has no built-in JSON escaper. Use `jq -Rn --arg p "$path" '$p'` for one path, or pipe everything to [`jq`](https://jqlang.github.io/jq/) at the end.

#### Capability: option parsing with `--dry-run`, `--json`, `--apply` → ex. 5

#### Capability: tests → Bats (see below)

### The exercise

Build `bin/repo-janitor`:

```
repo-janitor [--dry-run|--apply] [--json|--tab] [--min-size BYTES]
             [--include PATTERN]... [--exclude PATTERN]... DIR
```

Capabilities:
- list files larger than `--min-size` (default 100 MiB)
- group duplicates by sha256 (show kept + would-delete list)
- detect broken symlinks
- detect "generated junk" by pattern (`node_modules`, `.cache`, `*.pyc`, `target/`)
- `--dry-run` by default; `--apply` performs deletes
- output as JSON (one object per line, NDJSON) or tab-separated
- exit 0 if nothing actionable, 1 if findings, 2 on error

Required techniques (drawn from earlier exercises): arrays, [associative array](https://www.gnu.org/s/bash/manual/html_node/Arrays.html)s, `find -print0`, `read -r -d ''`, `trap`, `printf '%q'` / `printf '%(...)T'`, `mktemp -d`, custom logging at multiple levels, [`getopts`](https://www.gnu.org/s/bash/manual/html_node/Bourne-Shell-Builtins.html#index-getopts)/hand-rolled option parsing, exit-status discipline.

Write a **Bats test suite** for it (see the Bats section below).

### Bats — a primer

```bash
# test/repo-janitor.bats
setup() {
  TESTDIR=$(mktemp -d)
  mkdir -p "$TESTDIR"/{a,b}
  printf 'same\n' > "$TESTDIR/a/x"
  printf 'same\n' > "$TESTDIR/b/y"
}
teardown() { rm -rf "$TESTDIR"; }

@test "detects duplicates" {
  run bin/repo-janitor --json "$TESTDIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *'"category":"duplicate"'* ]]
}

@test "dry-run by default" {
  run bin/repo-janitor "$TESTDIR"
  [ -f "$TESTDIR/a/x" ]    # nothing deleted
}
```

Run with `bats test/`. `run cmd` captures `$status`, `$output`, `$lines[]`. `[ … ]` and `[[ … ]]` work as assertions — non-zero exit fails the test.

### Variants comparison: "find duplicates" backend

| Approach                          | Performance (10k files) | Memory     | Notes                          |
| --------------------------------- | ----------------------- | ---------- | ------------------------------ |
| bash loop + `sha256sum` per file  | slow (10k forks)        | low        | clear code; OK <1k files       |
| `find ... -print0 \| xargs -0 sha256sum` | fast               | low        | batched; one-line; preferred   |
| `fdupes` / `rdfind` (external)    | fastest                 | low        | adds a dependency              |
| pure-bash hashing (read + xor)    | very slow               | high       | educational only; don't ship   |

### Optional: locked variant

Build it **without `find`** (use globstar only, ex. 2 locked variant). Then **without any associative arrays** (use parallel sorted arrays). Notice how the bash version starts to look like reinventing a database — and when that happens, hand the problem to `sqlite3` or `awk` instead.

### Optional: scoring rubric

- [ ] runs `--dry-run` by default; `--apply` required to delete
- [ ] `--apply` without `--yes` prompts before each delete
- [ ] handles symlinks safely (doesn't follow into loops)
- [ ] JSON output is valid (`jq .` accepts each line)
- [ ] passes `shellcheck` clean
- [ ] Bats suite covers: duplicates, large files, broken symlinks, junk patterns, dry-run, --apply
- [ ] tests use `mktemp -d` and clean up in `teardown()`
- [ ] runs cleanly inside a podman container with only coreutils + bash + sha256sum

### Break it

- [ ] DIR with no read permission on a subdirectory
- [ ] DIR containing a symlink loop
- [ ] DIR with 100k files (does it finish in reasonable time?)
- [ ] file with embedded newline in name
- [ ] disk full during `--apply`
- [ ] DIR on a different filesystem than `$TMPDIR`
- [ ] interrupted with Ctrl-C mid-`--apply` (no orphaned state? trap fires?)
- [ ] two `repo-janitor --apply` instances on the same tree concurrently (race — needs [`flock`](https://man7.org/linux/man-pages/man1/flock.1.html) from ex. 22)



---

[← ex. 14](../14-performance-kata/) · [ex. 16 →](../16-printf-deep-dive/)
