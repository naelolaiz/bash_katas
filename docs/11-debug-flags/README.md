# 11. Debuggable script exercise


**Goal:** Make `--debug`, `--dry-run`, and `--verbose` flags that don't fight each other.

### Techniques

#### Trick: rich [`PS4`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-PS4) for `set -x` output

```bash
PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-MAIN}: '
set -x
foo() { ls /tmp; }
foo
set +x
# + script.sh:42:MAIN: foo
# + script.sh:39:foo: ls /tmp
```

**What's happening:** `PS4` is the prefix bash prepends to each line of `set -x` output. The default is just `+`. Adding source file, line number, and function name turns trace output from "what just ran" into "where, in what function, and at what line".
**Gotcha:** `PS4` is re-expanded for *every* traced line — keep it cheap. Don't put `$(command)` substitutions in it; they'll fork on every line traced. `${FUNCNAME[0]:-MAIN}` handles top-level (no function) cleanly.
**When to use:** any script that is debugged more than once. Set it at the top, even if `set -x` is off — it's free until trace is enabled.

#### Trick: [`BASH_XTRACEFD`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-BASH_005fXTRACEFD) — send trace to a separate stream

```bash
exec {tracefd}>/tmp/script.trace
export BASH_XTRACEFD=$tracefd
set -x
echo "this goes to stdout, trace goes to /tmp/script.trace"
```

**What's happening:** by default, `set -x` writes to stderr. `BASH_XTRACEFD` redirects it to any FD you opened. Lets you keep stderr for *errors* and trace for *trace*.
**Gotcha:** `BASH_XTRACEFD` only works for `set -x` output, not regular stderr from commands. If the FD closes, bash silently reverts to stderr — keep it open for the whole script.
**When to use:** any production script that needs debug logging without polluting the user's stderr.

#### Trick: safe `--dry-run` printing with `printf %q`

```bash
run() {
  if (( dry_run )); then
    printf 'DRY: '; printf '%q ' "$@"; printf '\n'
  else
    "$@"
  fi
}

run rm -rf "$tmpdir"
run cp -- "$src" "$dst"
```

**What's happening:** `printf '%q'` per arg produces a copy-pasteable, re-parseable representation of the exact command that would have run. No string concatenation, no quoting bugs.
**Gotcha:** the naive `echo "$*"` is wrong for anything containing spaces — the user can't tell `"a b"` (one arg) from `a b` (two args). `printf '%q '` always disambiguates.
**When to use:** every `--dry-run` flag, every "what command would I run" log line.

#### Trick: structured logging at multiple levels

```bash
LOG_LEVEL=${LOG_LEVEL:-1}    # 0=quiet 1=normal 2=verbose 3=debug

log() {
  local level=$1; shift
  (( level > LOG_LEVEL )) && return 0
  local prefix
  case $level in
    1) prefix='INFO ' ;;
    2) prefix='VERB ' ;;
    3) prefix='DEBUG' ;;
  esac
  printf '%s [%(%F %T)T] %s\n' "$prefix" -1 "$*" >&2
}

log 1 "starting"
log 2 "processing $count items"
log 3 "internal state: ${state[*]@Q}"
```

**What's happening:** one function, integer levels. Comparison is cheap (integer). Output goes to stderr, never stdout — so the script's actual output stays usable in pipelines. `printf '%(...)T'` adds timestamps for free.
**Gotcha:** people often write to stdout out of habit ("`echo`") and break downstream consumers of the script. Force a discipline: all logging to stderr, all data to stdout.
**When to use:** any script larger than ~50 lines, especially ones used in pipelines.

#### Trick: `trap '...' ERR` for "what just blew up?"

```bash
trap 'printf "ERR at %s:%d (cmd: %s) exit=%d\n" "$BASH_SOURCE" "$LINENO" "$BASH_COMMAND" "$?" >&2' ERR
set -E    # propagate ERR trap to functions, subshells, command subs
```

**What's happening:** the `ERR` trap fires when a command returns non-zero (under [`errexit`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html), or whenever a top-level command fails without being handled). `BASH_COMMAND` is the command that failed; `$?` is its exit status. `set -E` extends the trap into functions/subshells.
**Gotcha:** ERR trap does NOT fire inside conditionals (`if`, `while`, `||`, `&&`) — same suspension list as `errexit` itself ([BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105)). Don't rely on it to catch everything.
**When to use:** scripts where "where did this fail?" is the question that takes the longest to answer.

### The exercise

Take a script from any earlier exercise (recommend ex. 6 `runlog` or ex. 9 `pmap`) and add:

- `--quiet` / `-q`: log level 0
- `--verbose` / `-v`: log level 2 (default 1)
- `--debug`: log level 3 + `set -x` to a separate trace file (`$LOGFILE.trace` or `/dev/stderr`)
- `--dry-run`: print every external command with `printf %q` instead of running it

Constraints: trace output must NOT go to the user's stderr by default; debug output must NOT contaminate the script's stdout; `--dry-run --debug` must do something sensible (don't actually run anything, but show what would have).

### Variants comparison: "how to emit debug output"

| Channel              | Pros                                | Cons                                  |
| -------------------- | ----------------------------------- | ------------------------------------- |
| stderr (`>&2`)       | always visible; standard convention | mixes with command stderr             |
| `BASH_XTRACEFD`      | trace separate from app stderr      | bash-only; FD management              |
| dedicated log file   | searchable, no terminal clutter     | needs cleanup, rotation               |
| syslog (`logger`)    | central, time-sorted                | one more thing to grep                |

### Optional: locked variant

Implement `--debug` **without `set -x`** — write explicit `log 3 "..."` calls at every interesting step. Then turn on `set -x` and compare. Which one tells you more about the failure when something goes wrong inside a `for` loop?

### Optional: scoring rubric

- [ ] `--dry-run` emits a copy-pasteable command for every action
- [ ] `--debug` does NOT change exit status compared to a non-debug run
- [ ] `--verbose` lines go to stderr, not stdout (pipe to `>/dev/null` and confirm)
- [ ] PS4 includes file + line + function
- [ ] passes `shellcheck` clean
- [ ] script's regular output remains usable in `script | wc -l`

### Break it

- [ ] `--debug --quiet` together — which wins?
- [ ] script run with stdin closed (`< /dev/null`)
- [ ] log line containing a filename with embedded newline
- [ ] very long log lines (>4KB) — does line buffering hold?
- [ ] log file path is read-only — clean error vs. silent failure
- [ ] enable trace, then disable trace mid-function — does PS4 stay set?



---

[← ex. 10](../10-coprocess-mini-client/) · [ex. 12 →](../12-programmable-completion/)
