# 8. Traps, cleanup, and atomic file replacement


**Goal:** Handle temp files, signals, and partial failures correctly.

### Techniques

#### Trick: `trap EXIT` as the universal cleanup hook

```bash
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
# ... work ...
```

**What's happening:** `EXIT` fires on normal exit, on `exit N`, on uncaught error under [`set -e`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html), AND when the script terminates due to a signal it didn't catch. One trap covers all the "shell is going away" paths.
**Gotcha:** `EXIT` does NOT fire if the shell is killed with SIGKILL (nothing can catch that) or if it crashes. It DOES fire if the script `exec`s another program (the trap fires before exec). Multiple `trap '…' EXIT` calls overwrite; they don't stack — use a function that does all your cleanup.
**When to use:** always, as soon as you allocate something that needs cleaning up.

#### Trick: catch signals AND propagate the correct exit code

```bash
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT
trap 'cleanup; exit 130' INT     # 128 + SIGINT(2) = 130
trap 'cleanup; exit 143' TERM    # 128 + SIGTERM(15) = 143
```

**What's happening:** signal traps run, then control returns to the script. If you don't `exit` from the trap, the script keeps going as if nothing happened. `128 + N` is the conventional exit code for "killed by signal N" — propagate it so callers can tell.
**Gotcha:** `EXIT` fires AFTER your signal handler, so cleanup runs twice unless you make it idempotent. Use `trap - EXIT` inside the signal handler if you want to suppress the EXIT trap. The default `exit` (no arg) returns the status of the *previous* command, NOT the signal — be explicit.
**When to use:** any script that runs more than a few seconds, anything a user might Ctrl-C.

#### Trick: atomic file replacement with `mv` (on same filesystem)

```bash
tmp="${target}.tmp.$$"
generate_content > "$tmp"
mv -- "$tmp" "$target"
```

**What's happening:** `mv` on the same filesystem is a `rename(2)` syscall — atomic. Readers of `$target` always see either the old version or the new version, never a half-written file.
**Gotcha:** "same filesystem" means same mount point. `mv` *across* mounts becomes copy+delete, which is NOT atomic. [`mktemp`](https://man7.org/linux/man-pages/man1/mktemp.1.html) defaults to `$TMPDIR` (often `/tmp` = tmpfs) — make the temp file in the *target's* directory: `mktemp "$(dirname "$target")/.tmp.XXXXXX"`.
**When to use:** any "regenerate a file" operation where partial writes would be observable.

#### Trick: [`errexit`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html)/[`pipefail`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html) pitfalls (BashFAQ/105)

```bash
set -euo pipefail

# Pitfall 1: errexit suspended inside conditionals
foo() { return 1; }
if foo; then :; fi    # errexit does NOT fire

# Pitfall 2: command substitution loses exit status by default
result=$(grep missing /etc/hosts)   # under set -e, this DOES exit (bash 4.4+)
result=$(grep missing /etc/hosts) || true   # explicit "I'm handling it"

# Pitfall 3: && chain silently swallows errexit
true && false   # exits (rightmost return)
{ true; false; }   # exits on false
```

**What's happening:** `errexit` has many surprising suspensions: conditionals (`if`, `while`, `||`, `&&`), shell functions called in a non-conditional context (older bash), pipelines (only the last command matters without `pipefail`).
**Gotcha:** the BashFAQ/105 list is long enough that "rely on `set -e` for error handling" is generally not a good plan. Use explicit `|| { ...; exit; }` for things that must succeed.
**When to use:** `set -euo pipefail` as a default safety net, but write explicit error handling for anything important.

#### Trick: `mktemp -d` and umask

```bash
umask 077                              # private by default
tmpdir=$(mktemp -d -t safe-edit.XXXXXX)
trap 'rm -rf "$tmpdir"' EXIT
chmod 700 "$tmpdir"                    # belt + suspenders
```

**What's happening:** `mktemp -d` creates a fresh directory with mode `0700`, guaranteed unique name (race-free). `-t TEMPLATE` keeps the script's name visible in `/tmp` listings — easier debugging.
**Gotcha:** macOS `mktemp` has slightly different `-t` semantics (template can't have a path component). Don't pass user-controlled data as the template prefix.
**When to use:** every script that creates more than one temp file. The directory gives you one path to clean up.

### The exercise

Write `bin/safe-edit`:

```
safe-edit FILE COMMAND [ARGS...]
```

1. copy `FILE` to a temp file
2. run `COMMAND temp-file`
3. if the command succeeds, atomically replace `FILE` with the temp file, preserving original mode/owner
4. on Ctrl-C, error, or normal exit, clean up the temp file

Implement it **two ways**: (a) with `set -euo pipefail` and minimal explicit error handling, (b) without `set -e` and explicit `|| { ...; }` everywhere. Compare: which catches more failure modes? Which is easier to read?

### Variants comparison: "cleanup on exit/signal"

| Strategy                     | Catches Ctrl-C | Catches normal exit | Catches kill -9 | Idempotent? |
| ---------------------------- | -------------- | ------------------- | --------------- | ----------- |
| `trap rm EXIT`               | yes (via EXIT) | yes                 | no              | yes (`rm -rf`) |
| `trap cleanup INT TERM EXIT` | yes (explicit) | yes                 | no              | needs care  |
| process group + `kill 0`     | yes            | needs `wait`        | no              | yes         |

### Optional: locked variant

Implement `safe-edit` **without `mktemp`** — generate the temp name yourself using `$$` and `$RANDOM`. What can go wrong? Now have two `safe-edit` processes run on the same file concurrently — describe what breaks and add [`flock`](https://man7.org/linux/man-pages/man1/flock.1.html) to fix it.

### Optional: scoring rubric

- [ ] cleanup runs on Ctrl-C *and* on normal exit *and* on `exit 1` from a failed command
- [ ] original file's mode is preserved (test with 0600, 0644, 4755)
- [ ] replacement is atomic (a reader sees either pre or post, never empty)
- [ ] script exits with command's actual exit status, not 0
- [ ] passes `shellcheck` clean

### Break it

- [ ] command exits 0 but produces empty output (replace or skip? document)
- [ ] command exits non-zero — original file untouched?
- [ ] Ctrl-C during command execution — temp file gone, original untouched?
- [ ] `FILE` is a symlink — does safe-edit follow it or replace it?
- [ ] `FILE` is on a different filesystem than `/tmp` — does `mv` still atomic? (no)
- [ ] disk full during temp file write
- [ ] FILE name with whitespace, leading `-`, embedded newline

### Reference

[BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105) — the canonical list of `errexit` surprises.



---

[← ex. 7](../07-manifest-diff/) · [ex. 9 →](../09-parallel-worker-pool/)
