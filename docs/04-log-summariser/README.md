# 4. Log summariser, three ways


**Goal:** Count log lines by `(level, component)` using three different toolsets and see where each excels.

Sample input (`/tmp/log.txt`):
```
2026-05-18 INFO api started
2026-05-18 WARN db slow
2026-05-18 ERROR api failed
2026-05-18 INFO api ready
```

Target output (any order):
```
INFO  api 2
WARN  db  1
ERROR api 1
```

### Techniques

#### Trick: bash [associative array](https://www.gnu.org/s/bash/manual/html_node/Arrays.html) (pure builtin, no fork)

```bash
declare -A counts
while read -r _date level component _rest; do
  [[ -z "$level" ]] && continue
  key="$level $component"
  counts["$key"]=$(( ${counts["$key"]:-0} + 1 ))
done < /tmp/log.txt

for key in "${!counts[@]}"; do
  printf '%s %d\n' "$key" "${counts[$key]}"
done
```

**What's happening:** [`declare -A`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-declare) creates an associative array (bash 4+). `_date` / `_rest` swallow fields you don't care about — leading underscore is convention. `${var:-0}` defaults the value before arithmetic so the first increment doesn't error under [`set -u`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html).
**Gotcha:** associative arrays don't exist in bash 3.2 (macOS system bash). Order is undefined — pipe to `sort` if you want stable output. `read` strips a trailing `\r` only if `IFS` includes it; CRLF logs need `tr -d '\r'` first.
**When to use:** when you want zero forks and the input is small-to-medium (under 10⁵ lines is comfortable; above that, bash's loop overhead dominates).

#### Trick: `awk` associative array (one fork, fastest for big inputs)

```bash
awk '/^[0-9]/ { c[$2" "$3]++ } END { for (k in c) print k, c[k] }' /tmp/log.txt
```

**What's happening:** awk arrays are inherently associative. `$2` is the level field, `$3` the component. The `^[0-9]` pattern skips blank lines and continuation lines that don't start with a digit.
**Gotcha:** `for (k in c)` iteration order is implementation-defined — gawk has `--sort` / `PROCINFO["sorted_in"]`, others don't. Pipe to `sort` if you need stable order.
**When to use:** any "count grouped by field" task on >10⁴ lines. The one fork pays for itself many times over.

#### Trick: `sort | uniq -c` (no programming at all)

```bash
awk '/^[0-9]/ { print $2, $3 }' /tmp/log.txt | sort | uniq -c |
  awk '{ printf "%s %s %d\n", $2, $3, $1 }'
```

**What's happening:** extract the `(level, component)` pair, sort so identical pairs are adjacent, `uniq -c` collapses runs and prefixes a count, final awk reformats. Classic Unix data-pipeline.
**Gotcha:** O(n log n) for the sort vs. O(n) for the assoc-array approaches. At 1M lines, sort starts spilling to disk; assoc-array stays in memory. `uniq` requires *adjacent* duplicates — without `sort`, it only collapses runs.
**When to use:** ad-hoc analysis at the command line; shell scripts that should avoid an `awk` dependency; one-liners.

### The exercise

Write `bin/log-count` that reads log lines from stdin and prints level/component counts. Implement it **three times** as above. Validate input: reject lines that aren't `<date> <level> <component> ...` with a useful error and exit code 1. Tolerate blank lines.

Generate a 10k, 100k, and 1M-line corpus (`yes "$(date +%F) INFO api started" | head -n 1000000 > big.log`) and benchmark all three. Write a paragraph: at what input size does each approach become the wrong choice?

### Variants comparison

| Approach            | Forks       | Complexity     | Memory       | Best size              |
| ------------------- | ----------- | -------------- | ------------ | ---------------------- |
| bash assoc-array    | 0           | O(n)           | distinct keys | <10⁵ lines             |
| awk assoc-array     | 1           | O(n)           | distinct keys | 10⁴–10⁹ lines          |
| sort \| uniq -c     | ~4          | O(n log n)     | streaming    | any (disk-friendly)    |

### Optional: locked variant

Solve with **no external commands at all** — pure bash. You can't use `sort`, so handle ordering by inserting into a sorted array as you go (or do a final O(n log n) bash sort). Benchmark against the awk version on 100k lines and observe the cliff.

### Optional: scoring rubric

- [ ] all three implementations produce the same multiset of output lines (ignoring order)
- [ ] all three reject malformed input with exit code 1 and a stderr message
- [ ] each handles blank lines silently
- [ ] benchmarks recorded for 10k / 100k / 1M lines for all three
- [ ] passes `shellcheck` clean

### Break it

- [ ] empty stdin
- [ ] stdin from a pipe vs. a [here-string](https://www.gnu.org/s/bash/manual/html_node/Redirections.html#Here-Strings) vs. `< /dev/null`
- [ ] line with only whitespace
- [ ] line with fewer than 3 fields
- [ ] CRLF line endings (`printf '%s\r\n' ...`)
- [ ] component name containing a space
- [ ] 1M-line input (does the bash assoc-array variant finish in reasonable time?)
- [ ] level field with bash-metacharacters: `2026-05-18 'WARN' api foo`



---

[← ex. 3](../03-path-components/) · [ex. 5 →](../05-cli-parsing/)
