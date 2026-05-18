# 10. Coprocess mini-client


**Goal:** Drive a persistent subprocess interactively from a bash script.

### Techniques

#### Trick: [`coproc`](https://www.gnu.org/s/bash/manual/html_node/Coprocesses.html) — built-in bidirectional pipe to an async command

```bash
coproc BC { bc -l; }
printf '%s\n' '2+2' >&"${BC[1]}"
read -r answer <&"${BC[0]}"
echo "answer: $answer"
# clean up:
exec {BC[1]}>&-
wait "$BC_PID"
```

**What's happening:** `coproc NAME { cmd; }` runs `cmd` asynchronously, opening two pipes. `${NAME[0]}` is the FD reading the coproc's stdout, `${NAME[1]}` writes to its stdin. `$NAME_PID` is its PID.
**Gotcha:** bash supports only **one** unnamed `coproc` at a time; for multiple, you MUST give each one a name. `coproc` is bash-only (ksh has a different syntax). Forgetting to close the write FD before `wait` makes the child block forever waiting for more input.
**When to use:** any "request/response" loop with a long-lived helper: `bc`, `python -i`, `gnuplot`, a REPL of any kind. Beats restarting the helper per call (which often dominates runtime).

#### Trick: manual FIFOs (POSIX-portable equivalent)

```bash
fifodir=$(mktemp -d)
trap 'rm -rf "$fifodir"' EXIT
mkfifo "$fifodir/in" "$fifodir/out"
bc -l < "$fifodir/in" > "$fifodir/out" &
bcpid=$!
exec 3>"$fifodir/in" 4<"$fifodir/out"

printf '%s\n' '2+2' >&3
read -r answer <&4
echo "answer: $answer"

exec 3>&- 4<&-
wait "$bcpid"
```

**What's happening:** two named FIFOs act as the two halves of the pipe. We open them on FD 3 (writer) and FD 4 (reader). The child sees them as its stdin/stdout.
**Gotcha:** `mkfifo` + open of both ends is order-sensitive: opening the read end blocks until a writer appears, and vice versa. The `bc -l < ... > ... &` does both opens in one shell command, avoiding the deadlock. Cleanup is now your responsibility.
**When to use:** POSIX sh scripts (no `coproc`), or when you need finer control over FD lifetimes than `coproc` allows.

#### Trick: timeout handling with `read -t`

```bash
if ! read -r -t 2 answer <&"${BC[0]}"; then
  printf 'bc timed out after 2s\n' >&2
  kill "$BC_PID" 2>/dev/null
  exit 124
fi
```

**What's happening:** `read -t SEC` returns a non-zero exit (>128) if no data arrives within SEC seconds. The FD stays open — you can retry or give up.
**Gotcha:** `-t` measures *wall* time, not "time since last byte". A slow drip that delivers one byte per second over many seconds will time out even though data is flowing. For that, read with `-N 1` in a loop and reset the timeout.
**When to use:** any IPC where the remote could hang. Avoids the script joining the hang.

#### Trick: detect coproc death

```bash
if ! kill -0 "$BC_PID" 2>/dev/null; then
  printf 'bc died; restarting\n' >&2
  coproc BC { bc -l; }
fi
```

**What's happening:** `kill -0 PID` sends no signal — it just checks "is this process alive AND signal-able by me". Returns 0 if yes, non-zero if dead or not ours.
**Gotcha:** if `bc` died and produced a SIGPIPE-inducing output, the next `write` to `${BC[1]}` will kill the parent script too — install `trap '' PIPE` or check `kill -0` *before* every write.
**When to use:** long-lived coproc clients that need to survive child crashes.

### The exercise

Write `bin/bc-client`:

```
bc-client [--timeout SEC]
```

- starts `bc -l` once at startup, keeps it alive
- reads expressions on stdin, prints answers on stdout
- on `quit` or EOF, cleanly shuts down `bc` (close write FD, `wait $BC_PID`)
- with `--timeout`, errors out (exit 124) if any single expression takes longer than SEC seconds
- if `bc` dies mid-session, restart it transparently and report on stderr

Implement it **two ways**: (a) using `coproc`, (b) using `mkfifo`. Compare lines of code, error handling, and POSIX portability.

### Variants comparison

| Approach              | Shell required        | FD management       | Multiple coprocs | POSIX  |
| --------------------- | --------------------- | ------------------- | ---------------- | ------ |
| bash `coproc`         | bash 4+               | automatic           | named only       | no     |
| `mkfifo` + `exec N>` | any POSIX shell       | manual              | trivial          | yes    |
| Python/expect wrapper | python/tcl installed  | n/a (other lang)    | trivial          | n/a    |

### Optional: locked variant

Implement `bc-client` with **a single anonymous pipe** (`mkfifo` not allowed, `coproc` not allowed). One-way pipes are asymmetric — request/response needs two of them. Document where the design breaks.

### Optional: scoring rubric

- [ ] one persistent `bc` process across many expressions (verify with `pgrep`)
- [ ] `--timeout` actually kills the coprocess if exceeded
- [ ] crash recovery works: kill `bc` externally, next request restarts it
- [ ] clean shutdown: no zombie `bc` process after EOF
- [ ] passes `shellcheck` clean

### Break it

- [ ] expression with syntax error (`bc` prints to stderr — does client survive?)
- [ ] expression that takes 10s (`for(i=0;i<10000000;i++);` in `bc`)
- [ ] SIGPIPE: kill `bc` between request and response
- [ ] empty expression line
- [ ] expression containing newline-in-the-middle (multi-line)
- [ ] 100k rapid requests in a row (FD leak? memory?)

### Reference

The bash manual's [Coprocesses](https://www.gnu.org/s/bash/manual/html_node/Coprocesses.html) section.



---

[← ex. 9](../09-parallel-worker-pool/) · [ex. 11 →](../11-debug-flags/)
