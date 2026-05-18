# 26. Signal handling beyond EXIT/INT


**Goal:** Catch the signals you didn't know existed and the bash quirks around them.

### Techniques

#### Trick: `trap '...' ERR` — what just blew up?

```bash
set -E   # propagate ERR into functions/subshells/command substitutions
trap 'err_handler $? "$BASH_COMMAND" "$BASH_SOURCE" "$LINENO"' ERR

err_handler() {
  local status=$1 cmd=$2 src=$3 ln=$4
  printf '[ERR] %s:%d: command %q failed with exit %d\n' "$src" "$ln" "$cmd" "$status" >&2
}

cp /nonexistent /tmp/
# [ERR] script.sh:42: command "cp /nonexistent /tmp/" failed with exit 1
```

**What's happening:** `ERR` fires when any command returns non-zero AND that exit status isn't being explicitly handled (`if`, `while`, `||`, `&&`, `!`, command substitutions on the LHS — same suspension rules as [`errexit`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html)). `BASH_COMMAND` holds the failing command, `BASH_SOURCE` and `LINENO` the location.
**Gotcha:** ERR trap **does not fire inside `if`/`while`/`||`/`&&`** — same BashFAQ/105 list as `errexit`. You'll catch `cp missing /tmp/` at top level but NOT `if cp missing /tmp/; then ...`.
**When to use:** any script over ~50 lines that debugged remotely. The trap converts "exit 1" into "where did it happen".

#### Trick: `trap '...' DEBUG` and `RETURN`

```bash
# DEBUG fires before every command
trap 'echo "about to run: $BASH_COMMAND" >&2' DEBUG

# RETURN fires when a function returns
my_func() { :; }
trap 'echo "returning from ${FUNCNAME[1]:-MAIN}" >&2' RETURN
my_func
```

**What's happening:** `DEBUG` fires before every "simple command" — overhead is high if your script does anything in a hot loop. `RETURN` fires when a function or sourced script returns.
**Gotcha:** these are powerful enough to write a step debugger in pure bash (and `bashdb` does exactly that). Don't leave them on in production — every-command overhead is real.
**When to use:** ad-hoc tracing during development. Building a tracer/profiler. Almost never in shipped scripts.

#### Trick: restoring default signal handling

```bash
# install handler
trap 'echo "got INT" >&2' INT

# do work...

# restore default behaviour (terminate on INT)
trap - INT

# ignore the signal entirely
trap '' INT
```

**What's happening:** `trap - SIGNAL` reverts to the default behaviour. `trap '' SIGNAL` (empty string) makes the script *ignore* the signal — Ctrl-C does nothing. Different forms; both useful.
**Gotcha:** ignored (`trap ''`) signals stay ignored for **child processes too** — `bash -c '...'` started under `trap '' INT` won't respond to Ctrl-C either, until *it* explicitly resets. This is rarely what you want.
**When to use:** during critical sections (file rotation, transaction commit) where you want INT deferred. Restore it right after.

#### Trick: surviving SIGPIPE

```bash
# without trap: SIGPIPE kills the producer
generate-lots-of-data | head -1     # writer dies, but exit status is masked

# explicit handling:
trap '' PIPE                        # ignore SIGPIPE entirely
generate-lots-of-data | head -1
# now writer keeps running until it tries to write, get EPIPE error, and *can* handle it
```

**What's happening:** when a downstream consumer closes its end of a pipe, the OS sends SIGPIPE to the next writer. Default action: terminate. With `trap '' PIPE`, the write returns EPIPE instead — your code can decide what to do.
**Gotcha:** ignoring SIGPIPE means your script keeps running after a `head -1` "early termination" — sometimes that's what you want, sometimes you wanted to abort the pipeline. Be deliberate. Many language runtimes (Python, Perl) restore the default handler when they start — bash inherits whatever it was given.
**When to use:** long-running scripts where downstream may legitimately disconnect (network clients, log readers). Almost never in batch scripts.

#### Trick: propagating "killed by signal N" as exit `128 + N`

```bash
on_signal() {
  local sig=$1
  local code=$(( 128 + sig ))
  # cleanup...
  exit "$code"
}

trap 'on_signal 2'  INT     # 130
trap 'on_signal 15' TERM    # 143
trap 'on_signal 3'  QUIT    # 131
```

**What's happening:** Unix convention: exit code N (1..127) means "exited with code N"; exit code 128+N means "killed by signal N". Calling shells (and `make`, `bash`'s `$?`) interpret it this way.
**Gotcha:** plain `exit` (no argument) returns `$?` from the previous command — NOT the signal you were handling. Be explicit. If you `exit` from inside the trap, the `EXIT` trap still fires afterwards — keep cleanup idempotent.
**When to use:** wrapper scripts and CI helpers where the caller's "did this die naturally or get killed?" question matters.

#### Trick: signals + `wait` quirk

```bash
sleep 100 &
pid=$!
trap 'echo "got INT, killing $pid"; kill "$pid"' INT
wait "$pid"     # does NOT return immediately on INT — completes when sleep is killed
```

**What's happening:** bash defers signal-trap execution until the foreground command returns. `wait` *is* interruptible on most modern bashes (4.3+), but the trap doesn't run *during* `wait` — it runs when `wait` returns. This makes the "kill child on INT" pattern look right but be subtly wrong if you also want to do work between the signal and the actual reaping.
**Gotcha:** in older bash, `wait` was not interruptible at all — Ctrl-C just sat there. The workaround was `wait -n` in a loop, or `while ! kill -0 "$pid" 2>/dev/null; do sleep 0.1; done`.
**When to use:** know the version. If your script needs to be responsive to signals during long `wait`s, prefer `wait -n` in a poll loop.

#### Trick: process groups and `setsid`

```bash
# in a launcher:
setsid -w child-program "$@"

# in the script, killing all children of the script's process group:
kill -- -"$$"
```

**What's happening:** every process belongs to a process group, and `kill -- -PGID` (negative PID) signals every process in that group. `setsid` starts a new session/group, isolating the child. Ctrl-C in a terminal sends SIGINT to the foreground PGID — which is why pressing Ctrl-C usually kills not just bash but everything bash spawned.
**Gotcha:** if your script launches `cmd &` in the background, `cmd`'s grandchildren are still in the same PGID and will receive the SIGINT too. To shield them, `setsid cmd` to put them in a new group.
**When to use:** writing a launcher/supervisor that needs to clean up an entire process tree, not just immediate children.

### The exercise

Write `bin/run-with-cleanup` that wraps an arbitrary command and guarantees:

1. on SIGINT (Ctrl-C), terminate the command, clean up temp files, exit 130
2. on SIGTERM (`kill PID`), terminate the command, exit 143
3. on SIGQUIT (Ctrl-\), print a stack/state dump to stderr but DON'T exit (just continue)
4. SIGPIPE is ignored (script keeps running even if downstream closes)
5. command's normal exit code is preserved on clean shutdown
6. command's "killed by signal N" exit code is propagated as 128+N to the caller

Test by piping output to `head -1`, by hitting Ctrl-C mid-run, by `kill -QUIT $(pgrep run-with-cleanup)` from another terminal.

### Variants comparison: "kill a child process tree"

| Approach                     | Kills grandchildren | Works after `setsid` | Notes                       |
| ---------------------------- | ------------------- | -------------------- | --------------------------- |
| `kill "$pid"`                | no                  | yes                  | only direct child           |
| `kill -- -"$pid"` (negative) | yes (PGID)          | only if child = group leader | needs child to be a process group leader |
| `pkill -P "$pid"`            | one level           | yes                  | one level of children       |
| `pkill -P "$pid" --recursive` (GNU 4+) | yes      | yes                  | newer GNU pkill             |
| `cgroup`-based               | yes (every desc.)   | yes                  | needs systemd-run or cgroup mount |

### Optional: locked variant

Build `run-with-cleanup` **without ever using the EXIT trap** — only explicit signal traps. Compare against the EXIT version: what cleanup paths are easy to forget? When is EXIT genuinely better?

### Optional: scoring rubric

- [ ] Ctrl-C exits 130 within 1 second, cleans up temp files
- [ ] `kill PID` exits 143 within 1 second, cleans up
- [ ] `kill -QUIT` prints diagnostic, continues running
- [ ] downstream `| head -1` doesn't kill the script (SIGPIPE ignored)
- [ ] child's normal exit code preserved (try with `exit 42`)
- [ ] child killed by SIGKILL externally — script exits 137
- [ ] passes `shellcheck` clean

### Break it

- [ ] command spawns grandchildren (`bash -c 'sleep 100 & sleep 100'`) — all killed on INT?
- [ ] command ignores SIGTERM (`bash -c 'trap "" TERM; sleep 100'`) — does wrapper escalate to KILL?
- [ ] command's stderr produces 100 MB while we're killing it (race with cleanup)
- [ ] `--quiet` plus debug output mixed — order of cleanup printing
- [ ] EXIT trap from earlier test still installed (`source ./script` twice)
- [ ] script running under `nohup` — does INT still reach it?

### Reference

- [BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105) — what `errexit` *doesn't* catch (and by extension, what `ERR` trap misses).
- `man 7 signal` — the canonical signal list with semantics.



---

[← ex. 25](../25-heredocs-and-quoting/)
