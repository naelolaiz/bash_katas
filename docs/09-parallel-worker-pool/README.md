# 9. Bounded parallel worker pool


**Goal:** Run N jobs at once, propagate failures, clean up children on Ctrl-C.

### Techniques

#### Trick: `wait -n` — block until *any* child finishes (bash 4.3+)

```bash
jobs=4
pids=()
for arg in "$@"; do
  some-cmd "$arg" &
  pids+=("$!")
  if (( ${#pids[@]} >= jobs )); then
    wait -n      # one slot frees up
    # rebuild pids[] by dropping the finished one (approximate; see below)
  fi
done
wait             # all remaining
```

**What's happening:** `wait -n` blocks until *any one* background job finishes. With `-n -p var`, bash 5.1+ also stores the finished PID into `var` — but on 4.x you don't know which one finished without extra bookkeeping (e.g. a per-PID `wait $pid` after `-n` returned, or `jobs -pr` to enumerate the still-running ones).
**Gotcha:** `wait -n` returns the exit status of the finished job, or 127 if there were no children. It does NOT exit with [`pipefail`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html)-style aggregation — you have to OR into a fail variable yourself.
**When to use:** the canonical pure-bash worker pool. Cleaner than the `xargs -P` / `parallel` approach when you need custom error handling.

#### Trick: `xargs -P` — when the workload is "run this command per input"

```bash
printf '%s\0' "$@" | xargs -0 -n1 -P 4 some-cmd
```

**What's happening:** `xargs -P 4` runs up to 4 parallel invocations. `-n1` means "one argument per invocation". `-0` reads NUL-delimited input.
**Gotcha:** by default `xargs -P` *interleaves* output line by line — fine for short lines, garbled for multi-line output. Use `--line-buffered` from `stdbuf` or write to per-job temp files if you care. Exit status: [`xargs`](https://man7.org/linux/man-pages/man1/xargs.1.html) returns 123 if any invocation failed, 124 on hang under `--max-procs`, etc. — different from regular pipeline conventions.
**When to use:** the simplest case: "apply this command to each arg, in parallel". No bash plumbing.

#### Trick: GNU `parallel` — when you need output ordering and progress

```bash
parallel --jobs 4 --keep-order --tag --halt now,fail=1 \
  some-cmd ::: "$@"
```

**What's happening:** `--keep-order` makes per-job output appear in input order (buffered). `--tag` prefixes each line with the input arg. `--halt now,fail=1` stops the whole run on the first failure.
**Gotcha:** GNU `parallel` is a perl script, not always installed. Conflicts on Debian-derivatives with `moreutils`'s `parallel` (different tool, same name). Output buffering can hide errors until the end.
**When to use:** ad-hoc commands where output ordering matters; build/test runners; anywhere you want a progress meter.

#### Trick: signal-safe cleanup of children

```bash
pids=()
cleanup() {
  trap - INT TERM EXIT
  if (( ${#pids[@]} > 0 )); then
    kill "${pids[@]}" 2>/dev/null
    wait "${pids[@]}" 2>/dev/null
  fi
  exit "${1:-130}"
}
trap 'cleanup 130' INT
trap 'cleanup 143' TERM
trap 'cleanup'    EXIT
```

**What's happening:** on signal, send SIGTERM to all known children, then `wait` for them to actually die. `trap -` inside the handler prevents recursive entry. Exit code 130 for SIGINT, 143 for SIGTERM.
**Gotcha:** if a child has spawned its own children, plain `kill PID` only kills the direct child. Use `kill -- -PGID` or start the script with `setsid` and target the process group. Pids in `pids[]` may have already exited — `kill` will warn; redirect or check first.
**When to use:** any pmap-style wrapper. Without this, Ctrl-C leaves orphaned `sha256sum` processes hashing 10 GB files in the background.

#### Trick: aggregating exit status across many children

```bash
fail=0
for pid in "${pids[@]}"; do
  wait "$pid" || fail=$?
done
exit "$fail"     # 0 if all succeeded, else last non-zero
```

**What's happening:** `wait PID` returns that specific child's exit status. Capture into a variable; the last non-zero wins. To preserve *all* failures, store in an array.
**Gotcha:** `wait PID` errors out if `PID` already finished and was reaped (e.g. by an earlier `wait -n`). Track which pids are still alive.
**When to use:** any concurrent runner where the caller cares whether the work succeeded overall.

### The exercise

Write `bin/pmap`:

```
pmap [-j JOBS] [--keep-order] COMMAND ARG...
```

- run at most `JOBS` concurrent invocations of `COMMAND ARG`
- exit with the maximum exit code across all invocations (0 only if all succeeded)
- on SIGINT/SIGTERM, kill outstanding jobs and exit 130/143
- with `--keep-order`, print each job's output in input order (buffer per job)

Implement it **three times** — pure bash (`wait -n`), `xargs -P`, GNU `parallel`. Compare output interleaving, signal handling, and exit-status semantics.

### Variants comparison

| Approach        | Output ordering           | Signal handling   | Failure aggregation     | Forks |
| --------------- | ------------------------- | ----------------- | ----------------------- | ----- |
| bash `wait -n`  | manual (per-job buffers)  | full control      | full control            | 0 + N children |
| `xargs -P`      | interleaved by default    | sometimes leaky   | "any failed" = exit 123 | 1 + N |
| GNU `parallel`  | `--keep-order` built in   | `--halt` policies | `--halt now,fail=1`     | 1 + N |

### Optional: locked variant

Implement `pmap` **without `wait -n`** — POSIX-compatible. You'll need a polling loop with `wait PID` per pid and bookkeeping for which are done. Compare CPU usage of the busy-poll version against `wait -n`.

### Optional: scoring rubric

- [ ] concurrent count never exceeds `-j`
- [ ] exit status is the max of all children (0 iff all 0)
- [ ] Ctrl-C kills all running children within ~1 second
- [ ] `--keep-order` produces deterministic output
- [ ] passes `shellcheck` clean
- [ ] no orphan processes after run (verify with `pgrep -f sha256sum`)

### Break it

- [ ] one of 100 jobs hangs forever — does Ctrl-C clean it up?
- [ ] one job spawns children of its own — do they get cleaned up?
- [ ] `JOBS=1` (degenerates to serial)
- [ ] `JOBS=1000` and 10 actual args (over-provisioned)
- [ ] `COMMAND` doesn't exist (clean error, exit 127)
- [ ] an arg starts with `-` (does it get treated as a flag?)
- [ ] all jobs succeed but one prints a warning to stderr — exit code still 0?



---

[← ex. 8](../08-traps-and-cleanup/) · [ex. 10 →](../10-coprocess-mini-client/)
