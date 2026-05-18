# 16. `printf` deep-dive


**Goal:** Use `printf` where `echo` is unreliable, and use its builtins (`%(...)T`, `%q`, `-v`) instead of forking `date` / `tr` / `awk`.

### Techniques

#### Trick: `%q` for safe re-quoting

```bash
file=$'weird file\nname.txt'
printf 'cp %q /backup/\n' "$file"
# Output: cp 'weird file'$'\n''name.txt' /backup/
```

**What's happening:** `%q` wraps the argument in whatever quoting bash needs (single quotes, `$'...'` for non-printables) so feeding the output back through `bash -c` reconstructs the original string byte-for-byte. Equivalent to the `${var@Q}` parameter-expansion operator (bash 4.4+).
**Gotcha:** `%q` is bash-only. POSIX `/bin/sh` has no equivalent — write a quoting function or use python.
**When to use:** dry-run output, logging commands you're about to run, building remote shell commands.

#### Trick: `%(...)T` for dates without forking `date`

```bash
printf '%(%Y-%m-%dT%H:%M:%S%z)T\n' -1
# 2026-05-18T14:32:11+0200

printf 'log: %(%F %T)T %s\n' -1 "starting"
```

**What's happening:** the `%(...)T` conversion takes a `strftime(3)` format. `-1` means "now"; a non-negative integer is a Unix timestamp.
**Gotcha:** bash 4.2+. Older bashes (macOS!) need `$(date +...)`. The format string is `strftime` — `%F` is `%Y-%m-%d`, `%T` is `%H:%M:%S`.
**When to use:** hot loops where forking `date` thousands of times costs real time. Single-call cost is also a small win.

#### Trick: repeating format string consumes arrays

```bash
args=(--user alice --port 22 --key ~/.ssh/id_ed25519)
printf '  %s\n' "${args[@]}"
#   --user
#   alice
#   --port
#   22
#   --key
#   /home/me/.ssh/id_ed25519

paths=(/etc/hosts /etc/resolv.conf)
printf 'file %s exists: %s\n' "${paths[0]}" "$([[ -e ${paths[0]} ]] && echo yes || echo no)" \
                              "${paths[1]}" "$([[ -e ${paths[1]} ]] && echo yes || echo no)"
```

**What's happening:** when there are more arguments than format specifiers, `printf` re-applies the format string until all arguments are consumed.
**Gotcha:** if the format string has *zero* conversions, you get an infinite-ish loop of the literal — `printf 'hi\n' a b c` prints `hi\n` three times. The number of conversions must evenly divide the argument count for clean output; leftovers print partially-filled lines.
**When to use:** any "one per line" output without writing a `for` loop. Building tabular output. Consuming any-sized array.

#### Trick: `printf -v` — capture into a variable without a subshell

```bash
printf -v stamp '%(%Y%m%d-%H%M%S)T' -1
printf -v line '%-10s %5d %s' "$type" "$size" "$path"
```

**What's happening:** `-v VARNAME` stores the result in a variable instead of writing to stdout. No fork, no subshell — `$()` would cost both.
**Gotcha:** `-v` is bash-only. The variable name comes *before* the format string. Reading `printf -v "$user_input" ...` is dangerous — user input can name `PATH`, `IFS`, etc.; validate with `[[ $name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]` first.
**When to use:** building strings in hot loops, anywhere `$(...)` would fork.

#### Trick: `printf '%s\0'` for NUL-separated output

```bash
files=("a b.txt" $'line\nbreak.txt' c.txt)
printf '%s\0' "${files[@]}" | xargs -0 ls -l
```

**What's happening:** the `\0` in the format string emits a literal NUL byte (only `printf` knows how to emit a NUL — `echo` typically can't). Pairs with `xargs -0` and `read -d ''` for NUL-safe pipelines.
**Gotcha:** `printf '%s\0' "${arr[@]}"` only emits NULs *between* elements; some consumers want a trailing NUL too. With `printf '%s\0'`, you actually get one NUL per array element including a trailing one — which is what you want.
**When to use:** any pipeline of filenames; whenever you need to feed NUL-delimited records to [`xargs`](https://man7.org/linux/man-pages/man1/xargs.1.html)/`sort -z`/`grep -z`/`mapfile -d ''`.

#### Trick: `%-20s`, `%5d`, `%'d` — alignment and locale separators

```bash
printf '%-15s %10d\n' total 1234567
# total                 1234567

LC_ALL=en_US.UTF-8 printf "%'d\n" 1234567
# 1,234,567
```

**What's happening:** `%-Ns` left-pads to width N (right-aligns without `-`). `%Nd` right-aligns numbers. The `'` flag (POSIX-2008) groups by thousands separator from the locale.
**Gotcha:** `%'d` is silent under `LC_ALL=C`. Field width is *minimum* — overflowing values aren't truncated; use `%.*s` (with precision) for truncation: `printf '%.10s\n' "very long string"`.
**When to use:** any tabular output that humans will read.

### The exercise

Write `bin/timestamp-log` that reads `<unix_ts>\t<message>` lines on stdin and prints `<ISO-8601 timestamp>\t<message>` to stdout. Implement it **three times**:

1. pure-bash using `printf '%(...)T'` and `read`
2. `awk` one-liner using `strftime()`
3. coreutils pipe using `date -d @...`

Then write a paragraph: which one would you ship, and why? Cite the *measured* fork count on 100k input lines.

### Variants comparison: "format a Unix timestamp as ISO 8601"

| Approach                                | Forks per line | Bash version | Notes                              |
| --------------------------------------- | -------------- | ------------ | ---------------------------------- |
| `printf '%(%FT%T%z)T\n' "$ts"`          | 0              | 4.2+         | fastest, builtin                   |
| `date -d "@$ts" '+%FT%T%z'`             | 1              | any          | GNU date; `-d @N` is GNU-specific  |
| `date -r "$ts" '+%FT%T%z'`              | 1              | any          | BSD/macOS form                     |
| `awk -v ts="$ts" 'BEGIN{print strftime("%FT%T%z", ts)}'` | 1 | any | one batched call processes many timestamps |
| `python3 -c 'import sys,datetime; …'`   | 1              | any          | when you also need timezone math   |

### Optional: locked variant

Solve `timestamp-log` **without any external commands at all** — no `date`, no `awk`, no `cut`. Bash builtins and `printf` only. Compare runtime against your `awk` solution on 100k input lines.

### Optional: scoring rubric

- [ ] all three implementations produce identical output on the test corpus
- [ ] each passes `shellcheck` clean
- [ ] trade-off paragraph cites a measured fork count, not a guess
- [ ] handles every Break-it case below
- [ ] (locked) pure-bash variant matches output of the other three byte-for-byte

### Break it

- [ ] format-string injection: `printf "$user_input\n"` with `user_input='%s%s%s%s'`
- [ ] zero-conversion format: `printf 'hi\n' a b c` (surprising loop)
- [ ] `%d` on non-numeric: `printf '%d\n' abc` — exit status 1, still prints 0
- [ ] negative timestamp with `%(...)T` (pre-epoch)
- [ ] very large input (`ARG_MAX` for the coreutils variant)
- [ ] empty stdin
- [ ] line missing the tab separator



---

[← ex. 15](../15-capstone-repo-janitor/) · [ex. 17 →](../17-bash-rematch/)
