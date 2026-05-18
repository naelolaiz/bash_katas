# 20. [`xargs`](https://man7.org/linux/man-pages/man1/xargs.1.html) patterns


**Goal:** Use `xargs` correctly — NUL-safe, parallel, with proper placeholders.

### Techniques

#### Trick: `-0` — NUL-safe input (the default should have been this)

```bash
# WRONG: breaks on any filename containing whitespace
find . -name '*.log' | xargs rm

# RIGHT: NUL-separated on both sides
find . -name '*.log' -print0 | xargs -0 rm
```

**What's happening:** by default `xargs` splits on whitespace (any of space/tab/newline) — so `a b.txt` becomes two arguments. `-0` switches to NUL as the only delimiter, matching `find -print0` and `grep -z` and friends.
**Gotcha:** `xargs` also respects quoting in the input (single/double quotes group, backslash escapes) — unless `-0` is passed. Without `-0`, `xargs echo` on the input `"a b"` is treated as one argument. This behaviour is rarely documented and causes incorrect output on input containing literal quotes.
**When to use:** pair `find -print0` with `xargs -0` as a default.

#### Trick: `-I{}` — placeholder substitution (one item at a time)

```bash
find . -name '*.bak' -print0 | xargs -0 -I{} mv {} {}.old

# multiple placeholders is fine:
ls /var/log/*.log | xargs -I{} cp {} /backup/{}
```

**What's happening:** `-I PLACEHOLDER` causes `xargs` to run the command once per input item, substituting PLACEHOLDER with the item. The literal `{}` is conventional but any string works.
**Gotcha:** `-I` implies `-L 1` (one line per invocation), so you LOSE the batching efficiency of plain `xargs`. Use it only when the command genuinely needs each arg separately. `-I{}` doesn't work with `-0` in all xargs implementations (GNU does, BSD doesn't).
**When to use:** when the placement of the arg isn't at the end (`mv X Y` needs X in the middle). For simple "append" use the no-`-I` form.

#### Trick: `-P N` — parallel invocations

```bash
find . -name '*.gz' -print0 | xargs -0 -n1 -P "$(nproc)" gunzip
```

**What's happening:** `-P N` runs up to N processes in parallel. Combine with `-n1` to make each invocation handle exactly one item (otherwise xargs batches first, then parallelises across batches).
**Gotcha:** output from parallel children is **interleaved**. For short single-line output that's fine; for multi-line output you need `--line-buffered` from `stdbuf` (`stdbuf -oL -eL`) or write to per-job files. `-P 0` means "as many as possible" — may overload the system.
**When to use:** the simplest pure-shell parallelism. Compare with ex. 9 (`pmap`) for finer control.

#### Trick: `-n N` — items per invocation

```bash
# one tar per group of 100 files
find . -name '*.log' -print0 | xargs -0 -n 100 tar czf "batch-$RANDOM.tar.gz"
```

**What's happening:** `-n N` bounds the number of items per invocation. Without `-n`, xargs packs as many as fit in `ARG_MAX` (typically thousands). With `-n 100`, each child gets exactly 100 (last may be fewer).
**Gotcha:** combining with `-P`: total throughput is `-P` invocations × `-n` items each, all running concurrently. `-n 1 -P 4` is "4 parallel, one item each" — fan out per item.
**When to use:** when the per-invocation cost has a sweet spot (e.g. one tar per 100 files balances tar overhead vs. memory).

#### Trick: `-r` / `--no-run-if-empty` — don't run with zero input

```bash
# without -r: `rm` runs with no args -> error
find . -name '*.tmp' -print0 | xargs -0 rm

# with -r: no input -> don't run at all
find . -name '*.tmp' -print0 | xargs -0r rm
```

**What's happening:** by default GNU `xargs` runs the command once even if input is empty (with no extra args). `-r` suppresses that. BSD/macOS xargs has `-r` as the default — opposite behaviour by platform.
**Gotcha:** "the no-input case never happens in production" until it does, and `rm` gets run with no args and exits 1, breaking a previously-quiet cron job. Use `-r` defensively.
**When to use:** any command that errors out on zero arguments (`rm`, `chmod`, `chown`, `mv`).

#### Trick: how to break `xargs` (so you remember not to)

```bash
mkdir -p /tmp/x && cd /tmp/x && touch "rm -rf *"
ls | xargs echo
# echo rm -rf '*'  <-- if xargs respects quoting, this is fine
# echo rm -rf      followed by glob expansion of `*` <-- but if not, disaster

# Always prefer:
find . -maxdepth 1 -type f -print0 | xargs -0 echo
```

**What's happening:** `ls | xargs` is broken on multiple levels — `ls` mangles newlines (one-per-line, no escaping), `xargs` re-interprets quotes/escapes, and `*` gets glob-expanded by the *child* shell if it's invoked through one.
**Gotcha:** the family of "ls | xargs rm" patterns is the #1 source of "I deleted everything" anecdotes. Memorise: never pipe `ls` into anything.
**When to use:** seeing `ls | xargs ...` in a code review is grounds to require a rewrite to `find -print0 | xargs -0 ...`.

### The exercise

Build `bin/parallel-hash`:

```
parallel-hash [-j JOBS] [--algorithm ALG] DIR
```

Hashes every regular file under `DIR` with `<ALG>sum` (default sha256), printing `<hash> <path>` per line, parallel up to `-j` jobs. Implement it **three times**:

1. `find ... -print0 | xargs -0 -P N -n1 sha256sum`
2. `find ... -exec sha256sum {} +` (single batch, no parallelism)
3. GNU `parallel --jobs N sha256sum :::: <(find ...)`

Compare runtime on 1k / 10k / 100k files. At what point does parallelism stop helping (disk IO bottleneck)?

### Variants comparison

| Approach                  | Parallel | Output interleaving | Hangs on empty input | Filename safety  |
| ------------------------- | -------- | ------------------- | -------------------- | ---------------- |
| `xargs -0 -P N -n1`       | yes      | yes (interleaved)   | `-r` to suppress     | with `-0`        |
| `find -exec ... +`        | no       | none (serial)       | runs once anyway     | inherent (no shell) |
| GNU `parallel`            | yes      | `--keep-order` opt  | no                   | NUL via `--null` |
| bash `wait -n` (ex. 9)    | yes      | controllable        | no                   | with care        |

### Optional: locked variant

Build `parallel-hash` using **only `xargs`** (no `parallel`, no bash worker pool). Then test: what happens when `sha256sum` on one file fails (corrupt file, permission denied) — does `xargs` keep going, or stop? How do you get the right exit code out?

### Optional: scoring rubric

- [ ] runs at most `-j` concurrent hashers (verify with `pgrep -c sha256sum`)
- [ ] handles filenames with spaces, newlines, leading `-`
- [ ] exits non-zero if any file failed to hash
- [ ] empty DIR does not produce spurious "no such file" errors
- [ ] passes `shellcheck` clean

### Break it

- [ ] filename with embedded newline
- [ ] filename starting with `-` (xargs's `--` separator)
- [ ] `DIR` doesn't exist
- [ ] one file is a symlink to itself (loop)
- [ ] one file is unreadable (perm denied)
- [ ] `-j 0` (xargs interprets this as "unlimited")
- [ ] very large file (~10 GB) — does parallelism still help, or does disk IO saturate first?



---

[← ex. 19](../19-find-deep-dive/) · [ex. 21 →](../21-awk-sed-grep-tricks/)
