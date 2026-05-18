# 6. Redirections and file-descriptor drill


**Goal:** Route stdout and stderr explicitly through pipelines, separate FDs, and [process substitution](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html).

### Techniques

#### Trick: order matters in `2>&1` redirects

```bash
{ echo on-stdout; echo on-stderr >&2; } > /tmp/out 2>&1
# both lines end up in /tmp/out

{ echo on-stdout; echo on-stderr >&2; } 2>&1 > /tmp/out
# only on-stdout goes to /tmp/out; on-stderr still hits the terminal
```

**What's happening:** redirections are evaluated left-to-right. `> /tmp/out 2>&1` first points stdout at the file, then dup's stderr to wherever stdout *currently* points (the file). The reverse order dup's stderr to wherever stdout pointed *before* the file redirect (the terminal), then redirects stdout to the file — leaving stderr at the terminal.
**Gotcha:** `&>` and `&>>` are bash shortcuts for "redirect both" — equivalent to `> file 2>&1`. POSIX sh has neither; use the long form for portable scripts.
**When to use:** anywhere you combine stdout and stderr. Internalise the left-to-right rule and the mistake stops happening.

#### Trick: named FDs with `exec {fd}>file` (bash 4+)

```bash
exec {log}>/tmp/run.log
printf 'starting at %(%F %T)T\n' -1 >&"$log"
some-command >&"$log" 2>&"$log"
exec {log}>&-     # close
```

**What's happening:** `{name}>file` opens a fresh FD (3 or higher) and stores its number in `$name`. No conflict with `9` being already-in-use elsewhere. Close with `{name}>&-`.
**Gotcha:** the variable holds an *integer FD number*, not the file. Use it as `>&"$name"`, NOT `>"$name"`. Forgetting to close FDs in a long-running script leaks them.
**When to use:** any script that needs a side-channel (audit log, debug stream) that survives across multiple commands.

#### Trick: process substitution `>(...)` and `<(...)`

```bash
some-command > >(gzip > /tmp/out.gz) 2> >(tee /tmp/err.log >&2)
diff <(sort fileA) <(sort fileB)
```

**What's happening:** `<(list)` runs `list` and returns a filename (usually `/dev/fd/N`) that reads from its stdout. `>(list)` returns a filename that writes to its stdin. Lets you pass "the output of cmd" or "the input to cmd" as if it were a file.
**Gotcha:** process substitution is bash/zsh/ksh, not POSIX. The substituted process runs *asynchronously* — `cmd > >(slow)` returns when `cmd` finishes, even if `slow` is still draining. No PIPESTATUS for `>(...)`. Exit status of the subprocess is lost unless you go out of your way.
**When to use:** `diff`-ing two computed streams; tee-ing to a compressor; anywhere  otherwise create a temp file.

#### Trick: [`PIPESTATUS`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-PIPESTATUS) (and `set -o pipefail`)

```bash
false | true | true
echo "$?"                  # 0  — exit status is the LAST command
echo "${PIPESTATUS[@]}"   # 1 0 0  — all stages

set -o pipefail
false | true | true; echo "$?"   # 1  — pipefail returns first non-zero
```

**What's happening:** `$?` is the exit status of the last command in a pipeline only. `PIPESTATUS` is an indexed array with every stage's exit status. [`pipefail`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html) makes the pipeline return the rightmost non-zero status (or 0 if all succeeded).
**Gotcha:** `PIPESTATUS` is bash-specific (zsh uses `pipestatus`). It's reset by the *next* command — `cmd1 | cmd2; echo "$?"; echo "${PIPESTATUS[@]}"` works, but `cmd1 | cmd2; x=$?; echo "${PIPESTATUS[@]}"` does NOT (the `x=...` is a new command, resetting it). Capture into a variable in one line: `cmd1 | cmd2; codes=("${PIPESTATUS[@]}")`.
**When to use:** any pipeline where intermediate-stage failure matters. Set `set -o pipefail` in scripts.

#### Trick: `tee` to multiple files + send `stderr` through `tee` too

```bash
some-command \
  > >(tee -a /tmp/out.log) \
  2> >(tee -a /tmp/err.log >&2)
```

**What's happening:** `tee` duplicates stdin to one or more files AND stdout. Process substitution makes each `tee` a destination for the corresponding stream. The `>&2` inside the stderr substitution sends `tee`'s output back to the *script's* stderr so the user still sees it.
**Gotcha:** without `>&2` on the stderr branch, error output disappears from the terminal silently (it only ends up in the file). Order of file closure under SIGINT can interleave output unpredictably.
**When to use:** building "show on terminal AND log to file" wrappers (which is exactly the exercise).

### The exercise

Write `bin/runlog`:

```
runlog [--quiet] [--trace] LOGFILE COMMAND [ARGS...]
```

- command's stdout goes to terminal AND to LOGFILE
- command's stderr goes to terminal AND to LOGFILE, marked with a `[stderr]` prefix on log lines
- the script returns the command's real exit status (not `tee`'s)
- `--quiet` suppresses terminal output, log only
- `--trace` enables `set -x` for the wrapper itself, to a separate `LOGFILE.trace`

Implement it **two ways**: (a) using process substitution + `tee`, (b) using named FDs (`exec {fd}>`) + a small helper function that prepends `[stderr]`. Compare: which is shorter? Which preserves exit status more easily? Which is portable past bash?

### Variants comparison

| Approach                   | Bash version  | Portable to /bin/sh | PIPESTATUS available | Async cleanup       |
| -------------------------- | ------------- | ------------------- | -------------------- | ------------------- |
| process substitution + tee | bash/zsh/ksh  | no                  | partly               | tee may still run on exit |
| named FDs `{fd}>`          | bash 4+       | no                  | not needed           | explicit `exec {fd}>&-` |
| FIFOs `mkfifo`             | any           | yes                 | yes                  | manual cleanup       |

### Optional: locked variant

Implement `runlog` **POSIX-portable** — no process substitution, no `{fd}>`, no `&>`. You'll need `mkfifo` and explicit FD shuffling (`3>&1 4>&2 1>file 2>file`). Handle cleanup of the FIFOs with a `trap EXIT`.

### Optional: scoring rubric

- [ ] script exits with the wrapped command's exit code, not 0/1 from tee
- [ ] `[stderr]` prefix only appears on stderr lines, never on stdout
- [ ] LOGFILE contains both streams interleaved in the same order they were written
- [ ] `--quiet` does what it says
- [ ] passes `shellcheck` clean
- [ ] (locked) FIFOs are cleaned up on Ctrl-C, not just normal exit

### Break it

- [ ] command that writes 100 MB to stdout (does tee keep up? buffering issues?)
- [ ] command that fork-execs and exits before children finish writing
- [ ] command killed by SIGKILL externally (does runlog still return 137?)
- [ ] LOGFILE on a full filesystem
- [ ] LOGFILE path doesn't exist (clear error vs. silent failure)
- [ ] command's name is literally `--quiet` (option vs. positional)
- [ ] pipe Ctrl-C through to the wrapped command

### Reference

The bash manual's [Process Substitution](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html) section describes `<(list)` / `>(list)`.



---

[← ex. 5](../05-cli-parsing/) · [ex. 7 →](../07-manifest-diff/)
