# 5. Command-line parsing, three ways


**Goal:** Parse `[-i] [-v] [-n LIMIT] PATTERN [FILE...]` three different ways and compare them.

### Techniques

#### Trick: bash builtin [`getopts`](https://www.gnu.org/s/bash/manual/html_node/Bourne-Shell-Builtins.html#index-getopts) (short opts only, fully portable)

```bash
ci=0 invert=0 limit=0
while getopts ':ivn:' opt; do
  case "$opt" in
    i) ci=1 ;;
    v) invert=1 ;;
    n) limit=$OPTARG ;;
    :) printf 'option -%s requires an argument\n' "$OPTARG" >&2; exit 2 ;;
    \?) printf 'unknown option -%s\n' "$OPTARG" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
pattern="${1:?usage: filter-lines [-i] [-v] [-n LIMIT] PATTERN [FILE...]}"
shift
```

**What's happening:** `getopts` is a *bash builtin* — no fork. The leading `:` in the optstring enables silent error mode (we report errors ourselves with proper exit code 2). `OPTARG` holds the argument for `-n`; `OPTIND` advances past consumed options.
**Gotcha:** short options only — no `--limit=10`, no `--invert`. Stacking (`-iv`) works. `getopts` reuses state in `OPTIND`/`OPTARG`; in a function, declare them `local` or the function can break when called twice.
**When to use:** anything where portability and zero forks matter; small CLIs with short flags only.

#### Trick: GNU `getopt` (long options, but portability cost)

```bash
parsed=$(getopt --options=ivn: --longoptions=ignore-case,invert,limit: --name=filter-lines -- "$@") \
  || exit 2
eval set -- "$parsed"

ci=0 invert=0 limit=0
while true; do
  case "$1" in
    -i|--ignore-case) ci=1;     shift ;;
    -v|--invert)      invert=1; shift ;;
    -n|--limit)       limit=$2; shift 2 ;;
    --) shift; break ;;
    *) printf 'parser bug: %q\n' "$1" >&2; exit 2 ;;
  esac
done
pattern="${1:?usage: …}"; shift
```

**What's happening:** GNU `getopt` (note: distinct from `getopts`) re-orders arguments and returns a normalised, properly-quoted command line that `eval set --` re-parses into `$@`. Supports long options.
**Gotcha:** **BSD `getopt` is completely different** and incompatible — no long options, no proper quoting. macOS ships the BSD form by default. The `eval set --` is required to handle quoted arguments correctly; skipping it breaks on filenames with whitespace.
**When to use:** long options matter AND you can require GNU `getopt` (Linux scripts, internal tooling).

#### Trick: hand-rolled `while/case` (maximum flexibility, no extra concepts)

```bash
ci=0 invert=0 limit=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--ignore-case) ci=1; shift ;;
    -v|--invert)      invert=1; shift ;;
    -n|--limit)       limit=$2; shift 2 ;;
    --limit=*)        limit=${1#*=}; shift ;;
    --) shift; break ;;
    -*) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    *)  break ;;
  esac
done
pattern="${1:?usage: …}"; shift
```

**What's happening:** explicit loop, explicit cases, explicit `shift` per option. Supports `--limit=10` and `--limit 10` both. `--` ends option parsing (the convention for "rest are positional, even if they start with `-`").
**Gotcha:** `--` must be handled explicitly. Forgetting a `shift 2` consumes the wrong argument. Validation that `$2` exists for option-with-arg cases is also easy to omit.
**When to use:** when you need `--key=value`, default sub-commands, or per-flag custom validation; when adding a dependency on GNU `getopt` would be a problem.

### The exercise

Write `bin/filter-lines`:

```
filter-lines [-i|--ignore-case] [-v|--invert] [-n|--limit LIMIT] PATTERN [FILE...]
```

- `-i` / `--ignore-case`: case-insensitive match
- `-v` / `--invert`: invert match
- `-n` / `--limit`: stop after LIMIT matches
- read stdin if no files given (and treat `-` as stdin)
- distinguish exit codes: 0 = matched, 1 = no matches, 2 = usage error

Implement it **three times** (one with `getopts`, one with GNU `getopt`, one hand-rolled). The first version may skip long options (`getopts` can't do them). Compare.

### Variants comparison

| Approach           | Long opts | --key=val | Stacked (-iv) | Portability       | Forks |
| ------------------ | --------- | --------- | ------------- | ----------------- | ----- |
| bash `getopts`     | no        | no        | yes           | POSIX, bash       | 0     |
| GNU `getopt`       | yes       | yes       | yes           | GNU only          | 1     |
| hand-rolled        | yes       | yes       | optional      | any POSIX shell   | 0     |

### Optional: locked variant

Implement with **`getopts` only** — no long options, no GNU `getopt`, no hand-rolled loops. Then look at the actual user-facing help text and ask: how often, in this script, do you actually need `--ignore-case` vs. `-i`? Where does the locked constraint hurt usability?

### Optional: scoring rubric

- [ ] all three versions accept the same short-option invocations and produce identical output
- [ ] all three return exit code 2 for usage errors, 1 for no-match, 0 for match
- [ ] all three handle `--` correctly
- [ ] handles `FILE` of `-` as stdin
- [ ] passes `shellcheck` clean

### Break it

- [ ] `filter-lines` (no arguments) — clean usage error, exit 2
- [ ] `filter-lines pattern` with no stdin attached — should hang? error? document the choice
- [ ] `filter-lines -n` (no value) — clean error, exit 2
- [ ] `filter-lines -- -pattern` — `-pattern` as positional, not flag
- [ ] `filter-lines -iv pattern` — stacked short options
- [ ] `filter-lines -n 10 pattern file.txt` — both forms `-n10` and `-n 10`
- [ ] file argument that doesn't exist — clear error, continue with remaining files? abort?



---

[← ex. 4](../04-log-summariser/) · [ex. 6 →](../06-fd-drill/)
