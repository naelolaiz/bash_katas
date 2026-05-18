# 24. Arithmetic gotchas


**Goal:** Understand the non-obvious corners of bash arithmetic.

### Techniques

#### Trick: `((expr))` exit status — 0 when result is 0

```bash
set -e
count=0
(( count = 0 ))   # result is 0  ->  exit status 1  ->  EXITS THE SCRIPT
echo 'never reached'
```

**What's happening:** `(( ))` returns exit status 0 when the expression evaluates to a *non-zero* number, and 1 when it evaluates to zero. Under [`set -e`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html), that 1 is a fatal error.
**Gotcha:** the workaround is `(( count = 0 )) || true`, or use `count=0` (plain assignment), or use `: $(( count = 0 ))` (the no-op `:` swallows the exit status).
**When to use:** be aware. When you want `(( ))` *as a statement* (assignment, side-effect), prepend `:` or append `|| true` if it might equal zero.

#### Trick: `$((expr))` is for substitution; `((expr))` is for testing

```bash
# substitution (POSIX)
count=$(( count + 1 ))
result=$(( a * b ))

# arithmetic command (bash; tests the result)
if (( count > 10 )); then echo 'big'; fi
while (( i < 100 )); do : $((i++)); done
```

**What's happening:** `$(( ))` evaluates the expression and substitutes its value into the shell command. `(( ))` evaluates and returns exit status (0/1). Different syntaxes, different jobs.
**Gotcha:** inside `$(( ))` and `(( ))`, you can drop the `$` from variable names: `$((count + 1))` works. Outside (e.g. in `[ ]`), you can't.
**When to use:** `(( ))` for conditionals and counters; `$(( ))` for substituting numeric results into other commands or assigning to variables.

#### Trick: leading-zero octal trap

```bash
hour=$(date +%H)
# at 08:something:
echo $((hour + 1))
# bash: 08: value too great for base (error token is "08")
```

**What's happening:** bash interprets a leading-zero integer literal as octal. `08` and `09` aren't valid octal digits, so it errors. Strikes at 08:00 and 09:00 sharp.
**Gotcha:** the symptom is "my script works every other hour". Fix: force decimal with `10#` prefix: `echo $(( 10#$hour + 1 ))`. Or strip leading zeros: `hour=${hour#0}`. The cleanest fix is `printf -v hour '%d' "$(date +%H)"` which normalises to decimal.
**When to use:** any time you parse a number from `date`/`stat`/`ls -l` output that might have a leading zero.

#### Trick: explicit base prefixes

```bash
echo $(( 0x1f ))     # 31  (hex)
echo $(( 010 ))      # 8   (octal — beware)
echo $(( 2#1010 ))   # 10  (binary)
echo $(( 16#ff ))    # 255 (hex via base#digits)
echo $(( 10#08 ))    # 8   (forced decimal)
echo $(( 36#zz ))    # 1295 (bases 2-36 supported)
```

**What's happening:** bash arithmetic supports `0x`/`0X` for hex, `0` prefix for octal, and `BASE#digits` for any base from 2 to 64.
**Gotcha:** mixing bases in one expression works: `$(( 0x10 + 010 ))` is `16 + 8 = 24`. Bases 37–62 use digits, lowercase, uppercase, then `_`, `@`.
**When to use:** binary masks, hex constants, parsing hex from `printf '%x'` output back to integer.

#### Trick: `let` vs. `((...))` vs. `expr`

```bash
let count=count+1      # old; same as (( count = count + 1 ))
let count++            # works; exit status 1 when result is 0 (same trap)
(( count++ ))          # the modern equivalent
count=$(expr "$count" + 1)   # POSIX; forks; spaces required
```

**What's happening:** `let` is the oldest form. `(( ))` superseded it (and works the same way; same exit-status trap). `expr` is the POSIX-portable form — external command, requires spaces around operators, glob-protects `*` (use `\*`).
**Gotcha:** `let` accepts un-quoted assignment but its argument-parsing is fragile with spaces or shell metacharacters. `(( ))` parses its own contents — better. `expr` is slow (fork-per-call) and quirky (different operator escaping on different platforms).
**When to use:** `(( ))` always in bash. `expr` only for `/bin/sh` scripts that must run on systems without `$(( ))` (none in 2026, really).

#### Trick: integer overflow at 2^63

```bash
echo $(( 2 ** 62 ))   # 4611686018427387904
echo $(( 2 ** 63 ))   # -9223372036854775808  <- wraps to negative
echo $(( 2 ** 64 ))   # 0  <- wraps to zero
```

**What's happening:** bash arithmetic uses C signed 64-bit integers. No bignum support. Overflow silently wraps.
**Gotcha:** common pitfall in timestamp math: `seconds_since_epoch * 1000000` for microseconds can overflow. Same risk when computing total file sizes in bytes across large trees.
**When to use:** if you need exact arithmetic past 2^63, delegate to `bc -l` (arbitrary precision) or `python3 -c`.

#### Trick: floating point — bash doesn't have it

```bash
# WRONG: bash arithmetic is integer-only
echo $(( 1 / 3 ))     # 0

# use bc:
echo "scale=6; 1/3" | bc -l    # 0.333333

# or awk:
awk 'BEGIN{printf "%.6f\n", 1/3}'    # 0.333333

# or printf trick (for fixed-precision):
printf '%.6f\n' "$(echo "scale=6; 1/3" | bc -l)"
```

**What's happening:** `$(( ))` and `(( ))` are integer-only. Division truncates toward zero. There is no `0.5`, no `1e6`.
**Gotcha:** `bc -l` requires `scale=N` for non-zero decimal output (default is `scale=0`, i.e. integer division). `awk` defaults to enough precision but uses scientific notation for very large/small numbers; `printf "%.6f"` controls it.
**When to use:** any percentage, average, ratio — `awk 'BEGIN{...}'` is usually cleanest; `bc` if you want arbitrary precision.

### The exercise

Write `bin/uptime-summary` that:

1. reads `/proc/uptime` (e.g. `12345.67 9876.54`)
2. reports uptime as `Xd Yh Zm` (days, hours, minutes)
3. reports system idle percentage as `XX.X%`
4. reports approximate total CPU-seconds used as `1.2 million seconds` (with thousands separator)

The arithmetic spans integer (days/hours/minutes), floating point (percentage), and large-number formatting (thousands separator). Implement **without** invoking `python` or `awk` if possible — use `printf`, `(( ))`, and `bc -l`. Then re-do it with one `awk` call and compare.

### Variants comparison: "arithmetic in bash"

| Tool          | Integer | Float | Big | Locale-aware separators | Forks |
| ------------- | ------- | ----- | --- | ----------------------- | ----- |
| `(( ))`/`$(())` | yes   | no    | 64-bit | no                    | 0     |
| `bc -l`       | yes     | yes   | bignum | no                    | 1     |
| `awk 'BEGIN{}'` | yes   | yes (double) | 53-bit mantissa | yes (via `%'d`) | 1   |
| `printf %'d`  | display only | n/a | n/a | yes                  | 0     |
| `python3 -c`  | yes     | yes (double) | bignum (int)  | yes              | 1     |

### Optional: locked variant

Solve `uptime-summary` **with no external commands** — no `bc`, no `awk`, no `python`. Fixed-point arithmetic using integers only: multiply by `10^N` before division, then `printf '%d.%0*d'` to render. Compare against the `awk` version on accuracy and readability.

### Optional: scoring rubric

- [ ] handles `08`/`09` from `date +%H` without error
- [ ] reports percentages to one decimal place
- [ ] uses thousands separator for large numbers
- [ ] runs safely under `set -e` (no `(( x = 0 ))` traps)
- [ ] passes `shellcheck` clean

### Break it

- [ ] very large uptime (`60 * 86400 * 365 * 100` seconds — ~3 trillion)
- [ ] very small idle (0.01 seconds)
- [ ] negative result (e.g. clock skew)
- [ ] input with leading zero (`echo '08'` to a `$((..))`)
- [ ] under `LC_ALL=C`: thousands separator silently disappears with `%'d`
- [ ] script run when `/proc/uptime` doesn't exist (BSD/macOS)



---

[← ex. 23](../23-locale-and-sorting/) · [ex. 25 →](../25-heredocs-and-quoting/)
