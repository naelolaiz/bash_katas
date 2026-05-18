# 22. Locking, atomic writes, single-instance scripts


**Goal:** Use race-free idioms for mutual exclusion and file replacement.

### Techniques

#### Trick: [`flock`](https://man7.org/linux/man-pages/man1/flock.1.html) on a file (advisory, but bash-friendly)

```bash
# block until lock acquired, run command, release on exit
flock /var/lock/my-script.lock my-script.sh "$@"

# non-blocking: exit immediately if already locked
flock -n /var/lock/my-script.lock my-script.sh "$@" || {
  echo 'already running' >&2; exit 1
}

# timeout
flock -w 30 /var/lock/my-script.lock my-script.sh "$@" || {
  echo 'gave up after 30s' >&2; exit 1
}
```

**What's happening:** `flock` wraps the command in an advisory file lock. The lock is released when the command exits — automatic cleanup. `-n` is non-blocking, `-w SEC` is bounded wait, `-s` is a shared (read) lock, `-x` is exclusive (default).
**Gotcha:** advisory means processes must opt in — any process that doesn't call `flock` ignores the lock. NFS support is shaky; use only on local filesystems for correctness. The lockfile itself isn't removed (it's the lock holder, not the lock).
**When to use:** the default for "I want only one instance of this script running".

#### Trick: `flock` inside a script — FD-based form

```bash
#!/usr/bin/env bash
exec 200>/var/lock/my-script.lock
if ! flock -n 200; then
  echo 'already running' >&2; exit 1
fi
# ... do work; lock released when FD 200 closes (script exit)
```

**What's happening:** open the lock file on an explicit FD (200 is a high number unlikely to collide), then `flock -n FD` to take the lock. The lock dies when the FD closes — script exit, OR an explicit `exec 200>&-`.
**Gotcha:** the lock is tied to the FD, not the file path. Closing and reopening the same path gives a fresh lock; closing the FD releases the lock even if the file still exists. Choose a path on a persistent filesystem — `/tmp` survives between runs on most systems, but `/run` and `/var/run` may not.
**When to use:** scripts that want to bracket only *part* of the work in the critical section, or that want to convert lock types (`flock -s` → `flock -x`).

#### Trick: atomic file replacement via `mv` (same filesystem)

```bash
target=/etc/myapp/config.json
tmp=$(mktemp "$(dirname "$target")/.config.json.XXXXXX")
trap 'rm -f "$tmp"' EXIT
generate-config > "$tmp"
chmod 0644 "$tmp"
mv -- "$tmp" "$target"      # atomic rename(2)
```

**What's happening:** `mv` within a single filesystem is `rename(2)` — atomic. A concurrent reader sees either the old file or the new file, never a partial write or a missing file. [`mktemp`](https://man7.org/linux/man-pages/man1/mktemp.1.html) in the *target's* directory guarantees same-filesystem.
**Gotcha:** `mv` *across* filesystems falls back to copy+delete, which is NOT atomic. Always create the temp in the target's directory. The file's inode changes after `mv` — open file handles see the old content (this is usually what you want).
**When to use:** any "regenerate a file" — config files, manifests, sitemap.xml, anything readers might race against.

#### Trick: `set -C` (noclobber) — first-writer-wins file creation

```bash
set -C   # noclobber
if (echo "$$" > /var/run/my-script.pid) 2>/dev/null; then
  # we won the race; we own the PID file
  trap 'rm -f /var/run/my-script.pid' EXIT
else
  echo 'another instance owns the lock' >&2
  exit 1
fi
```

**What's happening:** with `noclobber`, the `>` redirect fails if the file already exists. The check-and-write are a single atomic step (`O_CREAT|O_EXCL` syscall). Compare with the *broken* form `[ -f /var/run/.. ] && exit; echo $$ > /var/run/..` which has a window between check and write where another process can win.
**Gotcha:** `>|` (with pipe) is the explicit "I really mean clobber" — don't write that here. `noclobber` is shell-scoped; the subshell `(echo ...)` is needed so the failing `>` doesn't affect later commands' redirects.
**When to use:** PID files done right; "lockfile creation" without `flock`; any "create iff doesn't exist" semantics in pure shell.

#### Trick: PID files done right (combining `flock` and atomicity)

```bash
LOCKFILE=/var/run/my-service.lock
exec 200>"$LOCKFILE"
flock -n 200 || { echo 'already running' >&2; exit 1; }
# write our PID into it (now we own it):
printf '%d\n' $$ >&200
trap 'rm -f "$LOCKFILE"' EXIT
```

**What's happening:** the lock and the PID file are the same file. Taking the lock proves we're the owner; writing PID is informational (for `ps`/monitoring). Deletion on EXIT is courtesy — `flock` released when FD 200 closes, regardless.
**Gotcha:** stale PID files: if the script is killed -9, the trap doesn't fire and the lockfile stays. That's fine — `flock -n` will fail until the OS releases the kernel lock on the dead process's FDs, which happens automatically. The lingering file is harmless.
**When to use:** any long-running script that other tooling (monit, systemd) needs to introspect.

#### Trick: file locking on directories (when you want a queue)

```bash
queue=/var/spool/my-queue
mkdir -p "$queue"
job=$(mktemp -p "$queue" job.XXXXXX)
mv -- "$job" "$queue/processing/" 2>/dev/null || mkdir "$queue/processing"
```

Or with a more proper queue using `flock`:

```bash
( flock -x 200
  next=$(ls -1 "$queue/pending" | head -1)
  [[ -n "$next" ]] && mv "$queue/pending/$next" "$queue/processing/"
) 200>"$queue/.lock"
```

**What's happening:** "pick the next job atomically" is a critical section. Wrap in a subshell with `flock` so the lock scope is clear.
**Gotcha:** `mkdir DIR` is itself atomic (only one process can create a given dir); some "lock without flock" schemes use that property — `mkdir lockdir; trap 'rmdir lockdir' EXIT`. Works on NFS where flock doesn't.
**When to use:** when you need a simple cross-process work queue and don't want to introduce a real broker.

### The exercise

Write `bin/single-instance` — a wrapper that runs its argument exactly once at a time:

```
single-instance [--wait SEC] LOCKFILE COMMAND [ARGS...]
```

- if another instance already holds the lock, exit 1 (or wait up to `--wait` seconds)
- on Ctrl-C, release the lock cleanly
- preserve the wrapped command's exit code

Implement it **two ways**: (a) using `flock`, (b) using `set -C` + a PID file. Compare race-handling.

Also write `bin/atomic-write` that reads stdin and writes it to a target file atomically:

```
atomic-write TARGET
```

Test it: in one shell run `while :; do cat target.txt > /dev/null; done`, in another run `for i in {1..1000}; do generate | atomic-write target.txt; done`. The reader should never see a partial file.

### Variants comparison: "single-instance enforcement"

| Approach                | Race-safe | Cleanup on -9    | NFS    | Notes                       |
| ----------------------- | --------- | ---------------- | ------ | --------------------------- |
| `flock -n FILE`         | yes       | automatic        | flaky  | the modern default          |
| `set -C; echo $$ > FILE` | yes      | manual (PID check) | ok    | classic; survives without flock |
| `mkdir LOCKDIR`         | yes       | manual           | ok     | the only one that works on NFS |
| `[ -f LOCK ] && exit; ...` | NO       | manual           | n/a    | the wrong way; race window  |

### Optional: locked variant

Implement `single-instance` **without `flock`** — `set -C` only. Then test: kill -9 a running instance and try to start another. What happens? Add stale-PID detection: read the PID from the lockfile, `kill -0` it, treat "not running" as "lock is stale, overwrite it" — being careful about the race between checking and writing.

### Optional: scoring rubric

- [ ] two concurrent `single-instance` invocations on the same lockfile: only one runs at a time
- [ ] `atomic-write` never produces a partial file even under heavy concurrent reading
- [ ] Ctrl-C releases the lock (next invocation immediately succeeds)
- [ ] preserves wrapped command's exit code
- [ ] passes `shellcheck` clean
- [ ] (locked) stale-PID detection works after `kill -9`

### Break it

- [ ] lockfile on NFS (does `flock` honour it?)
- [ ] disk full during atomic-write's temp file
- [ ] target file is a symlink — does atomic-write replace the link or the target?
- [ ] lockfile path doesn't exist (parent dir missing)
- [ ] lockfile path is on a read-only filesystem
- [ ] script killed with kill -9 while holding lock (does next invocation succeed?)
- [ ] one instance hangs forever — does `--wait 5` work?



---

[← ex. 21](../21-awk-sed-grep-tricks/) · [ex. 23 →](../23-locale-and-sorting/)
