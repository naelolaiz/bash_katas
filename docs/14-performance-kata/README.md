# 14. Performance kata: fork minimisation


**Goal:** Build intuition for when bash is fast, when it's slow, and when you should delegate to `awk`/`sed`/`sort`.

### Techniques

#### Trick: `time` and `TIMEFORMAT` for wall/user/sys

```bash
TIMEFORMAT='real %3R  user %3U  sys %3S'
time ./script
```

**What's happening:** `TIMEFORMAT` controls bash's builtin `time` output. `%R` is wall, `%U` is user-CPU, `%S` is system-CPU. High `sys` with low `user` = lots of fork/exec/IO syscalls (the symptom of "too many small commands"). High `user` with low `sys` = computation; bash itself can be the bottleneck.
**Gotcha:** `/usr/bin/time` (external) is different — `-v` gives RSS, page faults, etc. `time CMD | something` measures `CMD`, not the pipeline; use `time { CMD | something; }` to measure the whole thing.
**When to use:** before optimising. "Slow" without a number is just a guess.

#### Trick: `strace -f -c` to count syscalls (Linux only)

```bash
strace -f -c ./script 2>&1 | tail -20
# % time   seconds  usecs/call    calls  errors  syscall
# ------ --------- ----------- -------- ------- ----------------
#  35.20  0.012345          1     12345         clone
#  20.10  0.007890          1      7890         execve
#  ...
```

**What's happening:** `-c` aggregates syscalls by name with counts. `-f` follows forks. `clone` count ≈ "how many processes did we make"; `execve` ≈ "how many programs did we run". A loop calling `awk` once per line shows millions of `execve` calls; the same logic in one `awk` invocation shows one.
**Gotcha:** [`strace`](https://man7.org/linux/man-pages/man1/strace.1.html) is Linux. macOS uses `dtruss` (requires SIP off). FreeBSD uses `truss`. Be aware that `strace` itself slows the program 2–10×; use it for *counts* and *patterns*, not for wall-clock comparisons.
**When to use:** when `time` says "slow" and you suspect fork/exec is the cause.

#### Trick: replace per-line forks with one batched call

```bash
# slow: forks N times
for f in /var/log/*.log; do
  awk '/ERROR/ {c++} END {print FILENAME, c+0}' "$f"
done

# fast: one fork total
awk '/ERROR/ {c[FILENAME]++} END {for (f in c) print f, c[f]}' /var/log/*.log
```

**What's happening:** awk handles many input files natively (`FILENAME` reports which one). One process does what the loop did N times. The same idea applies to `grep -c`, `sort -m`, `wc -l`.
**Gotcha:** batched form changes ordering and aggregation semantics. `END { ... }` runs once at the very end; you don't get a per-file boundary unless you watch for `FNR==1` to detect a new file.
**When to use:** any time a loop body's only purpose is invoking one external command.

#### Trick: replace `cat | foo` with `foo < file`

```bash
# slow: extra fork, extra pipe buffer
cat big.log | awk '{...}'

# fast: awk reads the file directly
awk '{...}' big.log

# also fine: redirect
awk '{...}' < big.log
```

**What's happening:** "UUOC" (useless use of cat) costs you a process and a pipe — small overhead per command, large in a loop. `awk`/`grep`/`sed`/`sort`/everything POSIX accepts filenames as arguments.
**Gotcha:** there *are* cases where `cat file | cmd` is meaningful — when `cmd` doesn't read filenames (e.g. `tr`), or when you want to combine multiple files (`cat a b c | sort`). Use judgment.
**When to use:** any one-shot pipeline. In scripts that get run constantly, cumulative overhead adds up.

#### Trick: when bash itself is the bottleneck

```bash
# slow: 100k iterations of bash parameter expansion
while IFS= read -r line; do
  echo "${line//foo/bar}"
done < big.log

# fast: one sed process
sed 's/foo/bar/g' < big.log
```

**What's happening:** bash's `while read` loop is genuinely slow — typically 50k–200k lines/sec depending on body complexity. `sed`/`awk` run at 10–100M lines/sec. The breakeven is around 10⁴ lines; below that, bash is fine; above, delegate.
**Gotcha:** "pure bash is always faster because no fork" is a *myth* for anything but tiny inputs. Measure.
**When to use:** know the threshold (~10⁴ lines is a useful rule of thumb on modern hardware) and switch tools at it.

### The exercise

Write a script that processes 100,000 lines, doing something non-trivial (e.g. "for each line, extract the third field, lowercase it, count distinct values"). Implement it **four times**:

- A. naive bash: `while read` + external command per line (`echo | tr | cut`)
- B. bash with [parameter expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html): `while read` + `${var,,}` and `${var##* }`
- C. one `awk` invocation
- D. coreutils pipeline (`cut | tr | sort | uniq -c`)

Measure each with `time` (and `strace -f -c | tail -20` on Linux). Plot or table the results. Write a paragraph: at what input size does each approach become the wrong choice, and why?

### Variants comparison

| Approach              | 1k lines (s)  | 100k lines (s) | 10M lines (s) | Forks    |
| --------------------- | ------------- | -------------- | ------------- | -------- |
| A naive bash + per-line forks | 5            | 500          | hours        | ~300k   |
| B bash + param expansion | 0.05        | 5             | 500          | ~0      |
| C one awk             | 0.01          | 0.1           | 10            | 1        |
| D coreutils pipeline  | 0.01          | 0.05          | 5             | ~4       |

(Numbers vary by hardware; ratios are the point.)

### Optional: locked variant

Solve the same problem in **pure bash with no forks at all** — read with [`mapfile`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-mapfile), transform with parameter expansion, count with [`declare -A`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-declare). Measure against the awk version. At what input size does pure-bash lose, and by how much?

### Optional: scoring rubric

- [ ] all four versions produce identical output (modulo ordering)
- [ ] each version was measured with `time` (record real, user, sys)
- [ ] for at least one version, ran `strace -f -c` and noted the dominant syscall
- [ ] wrote a paragraph identifying the breakeven point between approaches
- [ ] all versions pass `shellcheck` clean

### Break it

- [ ] degenerate input: all lines identical (does the dedup approach behave differently?)
- [ ] very wide lines (~1 MB each) — does `read` keep up?
- [ ] input from a process (`./script < <(big-generator)`) vs. a file — any IO difference?
- [ ] system under memory pressure — does `sort` spill to disk gracefully?
- [ ] CPU pinned to one core (`taskset -c 0`) — does the parallel pipeline still win?



---

[← ex. 13](../13-bash-vs-posix/) · [ex. 15 →](../15-capstone-repo-janitor/)
