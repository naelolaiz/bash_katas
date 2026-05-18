# 17. Regex with `[[ =~ ]]` and [`BASH_REMATCH`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-BASH_005fREMATCH)


**Goal:** Parse structured strings without forking `grep`/`sed`/`awk`.

### Techniques

#### Trick: the unquoted-pattern rule (the most common mistake)

```bash
line='2026-05-18 ERROR api failed'
re='^([0-9-]+) (INFO|WARN|ERROR) ([a-z]+) (.*)$'

if [[ $line =~ $re ]]; then       # CORRECT: re is unquoted
  printf 'date=%s level=%s component=%s msg=%s\n' \
    "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"
fi

if [[ $line =~ "$re" ]]; then     # WRONG: quoting forces literal match
  echo 'never reached'
fi
```

**What's happening:** the right-hand side of `=~` is treated as a regex *only when unquoted*. Quoting it (`"$re"`) forces a literal-string compare. This is the opposite of every other context in bash, where quoting is the safe default.
**Gotcha:** literal regex like `[[ $x =~ ^[0-9]+$ ]]` works fine, but anything dynamic — building the regex from variables — must go through an intermediate variable to keep the quoting straight. Inside `[[ =~ ]]`, characters like `(`, `)`, `|`, `{`, `}` are regex metacharacters; outside they'd be word-splits or pattern-globs.
**When to use:** any structured-string parse where the regex fits on a line or two.

#### Trick: capture groups via `BASH_REMATCH`

```bash
ip='192.168.1.42'
if [[ $ip =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  for octet in "${BASH_REMATCH[@]:1}"; do
    (( octet >= 0 && octet <= 255 )) || { echo "invalid: $octet"; exit 1; }
  done
fi
```

**What's happening:** `BASH_REMATCH[0]` is the whole match. `[1]`, `[2]`, ... are the capture groups in order. `${BASH_REMATCH[@]:1}` slices off element 0 so you iterate over just the captures.
**Gotcha:** `BASH_REMATCH` is **global** and overwritten by every successful `=~`. If you need to keep the matches across another `=~`, copy: `caps=("${BASH_REMATCH[@]}")`. Failed matches leave the old value untouched, not clear it — check `[[ ... =~ ... ]]` first.
**When to use:** anywhere that would otherwise need `grep -oE` + a separate parse step, when the input is one string.

#### Trick: anchoring and the implicit-substring behaviour

```bash
[[ 'abc123def' =~ [0-9]+ ]]    # true: matches '123'
[[ 'abc123def' =~ ^[0-9]+$ ]]  # false: not full string
```

**What's happening:** `=~` matches *any substring* of the operand. To require a full match, anchor with `^` and `$`. Unlike `grep -x`, there's no flag to enforce full-string match.
**Gotcha:** "passes my regex" doesn't mean "is shaped like my regex" — it means "contains a match". A regex like `[0-9]+` will happily match `notanumber12345garbage`.
**When to use:** by default, anchor. Drop anchors only when you specifically want substring search.

#### Trick: regex engine flavour — POSIX ERE, not PCRE

```bash
[[ 'foo' =~ \w+ ]]      # WRONG: \w is PCRE/Perl, not POSIX ERE
[[ 'foo' =~ [[:alpha:]]+ ]]   # right: POSIX character class
```

**What's happening:** `[[ =~ ]]` uses POSIX *extended* regular expressions (ERE) — same engine as `grep -E` and `awk`, but distinct from `grep -P` (PCRE). `\w`, `\d`, `\s`, `(?:...)`, lookaheads, `\b` etc. are PCRE features and don't work.
**Gotcha:** locale matters: `[[:alpha:]]` includes accented characters under `LC_ALL=en_US.UTF-8` but not under `LC_ALL=C`. `[A-Z]` may include lowercase letters under some collations — use `[[:upper:]]` instead.
**When to use:** know which engine you're in. If you need PCRE features, delegate to `grep -P` or `perl`.

### The exercise

Build `bin/parse-log` that reads log lines like `2026-05-18T14:32:11+0200 [INFO] api.request id=abc-123 took=42ms` and prints `<timestamp> <level> <component> <id> <duration_ms>` per line. Implement it **three times**:

1. `[[ =~ ]]` with `BASH_REMATCH`
2. `grep -oP` (PCRE)
3. `awk` with `match()` and `substr()`

Compare regex syntax differences, error handling on malformed lines, and throughput on 100k lines.

### Variants comparison

| Engine               | Regex flavour    | Where      | Captures             | Speed (100k lines) |
| -------------------- | ---------------- | ---------- | -------------------- | ------------------ |
| `[[ =~ ]]`           | POSIX ERE        | bash       | `BASH_REMATCH[i]`    | slow (bash loop)   |
| `grep -E` / `egrep`  | POSIX ERE        | one fork   | none (use `-o`)      | fast               |
| `grep -P`            | PCRE             | one fork   | `-o`, `\K`           | fast               |
| `sed -E`             | POSIX ERE        | one fork   | `\1`, `\2`           | fast               |
| `awk` `match()`      | POSIX ERE        | one fork   | `RSTART`/`RLENGTH`   | fast               |
| `perl -nE`           | PCRE             | one fork   | `$1`, `$2`           | fast               |

### Optional: locked variant

Implement `parse-log` **without `BASH_REMATCH`** — use `${var#pattern}` / `${var%pattern}` / `${var//pat/repl}` / `IFS=' '; read -ra parts <<< "$line"`. Where does [parameter expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html) run out of expressive power vs. regex?

### Optional: scoring rubric

- [ ] all three implementations produce identical output on a 1000-line test corpus
- [ ] handle malformed lines (skip with a warning to stderr, don't crash)
- [ ] `[[ =~ ]]` version uses an intermediate variable, not inline regex
- [ ] runtime measured on 100k lines for each
- [ ] passes `shellcheck` clean

### Break it

- [ ] line with quotes/backslashes in the message
- [ ] line containing the literal string `BASH_REMATCH` (no false-positive)
- [ ] missing field (no `id=...`) — graceful failure
- [ ] regex containing a `$` followed by a digit ("backreference"? no — `BASH_REMATCH` is array-style)
- [ ] non-ASCII content (UTF-8 emoji in the message)
- [ ] very long line (>1 MB) — bash `read` and regex engine handle it?



---

[← ex. 16](../16-printf-deep-dive/) · [ex. 18 →](../18-read-and-mapfile/)
