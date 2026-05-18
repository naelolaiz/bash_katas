# 18. `read` variants and [`mapfile`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-mapfile)


**Goal:** Use the right `read` flag for the situation. Most experienced bash users know `-r` and stop there.

### Techniques

#### Trick: `-r` + `IFS=` — the safe defaults

```bash
while IFS= read -r line; do
  printf 'got: %q\n' "$line"
done < input.txt
```

**What's happening:** `-r` disables backslash escape processing (without it, `\\n` in input becomes a literal newline). `IFS=` (empty, scoped to this command) prevents leading/trailing whitespace stripping.
**Gotcha:** the *last* "line" of a file may not have a trailing newline. `read` returns non-zero in that case but `$line` still contains the data. The classic idiom `while ... read ... ; do ... ; done` skips that last partial line; use `while ... read ... || [[ -n $line ]]; do ... ; done` to include it.
**When to use:** every `while read` loop. Memorise this idiom.

#### Trick: `-d ''` — NUL-delimited records

```bash
find . -type f -print0 |
  while IFS= read -r -d '' path; do
    printf '%s\n' "$path"
  done
```

**What's happening:** `-d DELIM` uses `DELIM` as the record terminator instead of newline. Empty-string `''` selects NUL — the only byte that can't appear in a filename, so the only delimiter that's actually filename-safe.
**Gotcha:** `-d '\0'` doesn't work — that's a two-character string. It must be `''`. Some other tools use `-z` for NUL mode (`sort`, `grep`); `read` is the odd one out.
**When to use:** anything taking input from `find -print0`, `xargs -0`, `git ls-files -z`.

#### Trick: `-t TIMEOUT` — bail out if input doesn't arrive

```bash
if read -r -t 2 -p 'continue? [y/N] ' answer; then
  case $answer in y|Y) ;; *) exit 0;; esac
else
  echo $'\ntimed out; assuming no' >&2
  exit 0
fi
```

**What's happening:** `-t SEC` returns >128 if no data within SEC seconds. `-p PROMPT` writes a prompt to stderr first (only if stdin is a terminal).
**Gotcha:** `-t 0` means "non-blocking: succeed iff data is buffered" — not "wait forever". Fractional timeouts (`-t 0.5`) work in bash 4+.
**When to use:** interactive prompts with a fallback default; reading from a slow IPC; testing whether stdin has data right now.

#### Trick: `-n` and `-N` — byte counts

```bash
read -n 1 -s -p 'press any key: ' key && echo
# -n: read up to N bytes OR until newline (whichever first)
# -s: silent (don't echo to terminal)

read -r -N 16 magic < binary-file
# -N: read EXACTLY N bytes, ignore delimiter
printf '%q\n' "$magic"
```

**What's happening:** `-n N` reads at most N bytes but stops early at the delimiter (or EOF). `-N N` reads exactly N bytes regardless of delimiter. `-s` is for passwords and "press any key" — disables terminal echo.
**Gotcha:** `read -s` disables echo only when stdin is a terminal; reading from a pipe shows the data normally. For password prompts, also disable history: `set +o history`.
**When to use:** binary headers, fixed-width protocols, "press any key" prompts, password input.

#### Trick: `-a` and `read -ra` — into an array

```bash
read -ra fields <<< 'one  two   three'
printf '[%s]\n' "${fields[@]}"
# [one]
# [two]
# [three]

IFS=, read -ra row <<< 'a,b,c,d'
echo "second column: ${row[1]}"
```

**What's happening:** `-a NAME` reads words into array `NAME`. Words are split on `IFS` (default: whitespace). Empty fields are *collapsed* by default — set `IFS=,` to keep empties between commas.
**Gotcha:** with `IFS=,`, `read -ra row <<< ',,'` gives a 3-element array of empty strings. With default IFS, `read -ra arr <<< '  a  b  '` gives `[a, b]` — leading/trailing whitespace gone, runs collapsed. For CSV with embedded commas/quotes, write a real CSV parser — bash isn't it.
**When to use:** parsing delimited single lines (CSV-lite, log lines, `cut`-style splits) without forking.

#### Trick: `mapfile` (aka [`readarray`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-readarray)) — read N lines into an array fast

```bash
mapfile -t lines < /etc/passwd
echo "user count: ${#lines[@]}"

mapfile -t -n 10 -s 5 lines < big.log    # skip 5, then 10 lines
mapfile -d '' files < <(find . -type f -print0)   # NUL-delimited, bash 4.4+
```

**What's happening:** `mapfile` reads the whole file (or N lines with `-n`) into an indexed array. `-t` strips trailing newlines. `-s N` skips N lines first. Much faster than `while read` for large inputs.
**Gotcha:** without `-t`, each element retains its trailing `\n`. With `< <(cmd)`, `mapfile` correctly sees the whole substituted stream — unlike `arr=$(cmd)` which collapses whitespace. `readarray` is a synonym; either works.
**When to use:** "I need the whole file as an array" — log analysis, fixture loading, config parsing.

#### Trick: callback `mapfile -C` — process while loading

```bash
mapfile -t -c 1000 -C 'progress() { echo "loaded $1 lines"; }; progress' lines < huge.log
```

**What's happening:** `-c N` calls the function specified by `-C` every N records. The function receives `$1` = current index, `$2` = current line.
**Gotcha:** the `-C` callback is bash code passed as a string, eval-style — quoting hell if you build it dynamically. Define the callback as a named function first and just pass its name.
**When to use:** loading multi-million-line files when you want a progress meter.

### The exercise

Build `bin/read-tester` — a script that exercises every trick above on the same input file (10k lines, mixed content including blank lines, leading whitespace, embedded backslashes, last line without newline). Print, for each technique, what it loaded and how many records.

Then implement `bin/count-lines` (count lines in a file) **four ways**:
1. `wc -l` (canonical)
2. `mapfile -t lines < file; echo "${#lines[@]}"`
3. `count=0; while IFS= read -r _; do ((count++)); done < file; echo "$count"`
4. `awk 'END{print NR}' file`

Benchmark on 1M lines. Why does `wc -l` win? When would each of the others be a better choice?

### Variants comparison: "read all lines into a structure"

| Approach                       | Speed (1M lines)  | Last-line-no-NL | NUL-safe | Bash version |
| ------------------------------ | ----------------- | --------------- | -------- | ------------ |
| `mapfile -t arr < file`        | fast              | included        | no       | 4+           |
| `mapfile -d '' < <(... -print0)` | fast            | n/a             | yes      | 4.4+         |
| `while IFS= read -r line`      | slow              | needs `|| [[ -n $line ]]` | no | any        |
| `while IFS= read -r -d ''`     | slow              | n/a             | yes      | any          |
| `IFS=$'\n' arr=($(<file))`     | medium, unsafe    | depends         | no       | any          |

### Optional: locked variant

Implement `count-lines` **without `read` and without `mapfile`** — using only built-in [parameter expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html) on the contents from `$(<file)`. What breaks? Why?

### Optional: scoring rubric

- [ ] all four `count-lines` variants produce the same number for a normal file
- [ ] all four handle a file whose last line lacks a trailing newline (differently? document)
- [ ] `read-tester` script demonstrates ≥6 of the techniques above
- [ ] passes `shellcheck` clean

### Break it

- [ ] last line without trailing newline
- [ ] file with only blank lines
- [ ] file containing NUL bytes mid-line
- [ ] line >1 MB long (bash `read` line-length limit?)
- [ ] file is a FIFO that takes 5 seconds per line (does the `-t` timeout work?)
- [ ] `IFS=$'\t\n'` set globally (does `IFS=` per-command shielding work?)



---

[← ex. 17](../17-bash-rematch/) · [ex. 19 →](../19-find-deep-dive/)
