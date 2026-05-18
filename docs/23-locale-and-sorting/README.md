# 23. Locale and sorting


**Goal:** Understand why a naive sort/compare/regex can produce different results on a different machine.

### Techniques

#### Trick: default `sort` vs. `LC_ALL=C sort`

```bash
printf '%s\n' Apple banana Cherry date | sort
# Apple
# banana
# Cherry
# date

printf '%s\n' Apple banana Cherry date | LC_ALL=C sort
# Apple
# Cherry
# banana
# date
```

**What's happening:** under a UTF-8 locale, `sort` uses "dictionary" ordering — case-insensitive primary, with case as a tiebreaker. Under `LC_ALL=C` (or `LC_ALL=POSIX`), it sorts by raw byte value — uppercase precedes lowercase because their ASCII values are smaller.
**Gotcha:** "stable across machines" requires `LC_ALL=C`. Two systems with different locales (German vs. English vs. C) will produce different sorts of the same input — and `comm`, `uniq`, `join` all break silently when their input is sorted by a different rule than they expect.
**When to use:** any sort that feeds into `comm`/`uniq`/`join`. Any sort that needs to be reproducible across systems.

#### Trick: `LC_COLLATE=C` vs. `LC_ALL=C`

```bash
LC_COLLATE=C sort   # only collation; numbers, dates, messages stay in user locale
LC_ALL=C sort       # everything: collation, numeric formatting, error messages, etc.
```

**What's happening:** `LC_ALL` is the override-all hammer. The individual `LC_*` vars (`LC_COLLATE`, `LC_NUMERIC`, `LC_TIME`, `LC_MESSAGES`, `LC_CTYPE`) target specific aspects. `LC_COLLATE=C` makes sort/compare deterministic without changing how `date` formats output or how error messages read.
**Gotcha:** the precedence is `LC_ALL > LC_*` > `LANG`. If `LC_ALL` is set in the environment, your `LC_COLLATE=C` is ignored. To set just collation reliably: `LC_ALL='' LC_COLLATE=C cmd`.
**When to use:** for surgical changes — keep human-readable messages in the user's language, just make collation deterministic.

#### Trick: `[A-Z]` and `[[:upper:]]` differ by locale

```bash
LC_ALL=en_US.UTF-8 grep '[A-Z]' <<< 'aBc'    # may match aBc (entire line) — A-Z range can include lowercase!
LC_ALL=C            grep '[A-Z]' <<< 'aBc'    # matches just B (ASCII range)
LC_ALL=en_US.UTF-8 grep '[[:upper:]]' <<< 'aBc'  # matches B (locale-aware "upper")
```

**What's happening:** `[A-Z]` is a *range* by collation order. Under some locales (notably some old `en_US` definitions), the collation interleaves cases, so `[A-Z]` accidentally includes lowercase letters too. Modern UTF-8 locales usually behave, but you can't trust it.
**Gotcha:** **always use `[[:upper:]]` / `[[:lower:]]` / `[[:alpha:]]`** for character class semantics. Reserve ranges for when you genuinely want a byte range (`[0-9]` is safe; alphabetic ranges are not).
**When to use:** anywhere that would normally use `[A-Z]` — replace with `[[:upper:]]`. Same for `[a-z]` and `[a-zA-Z]`.

#### Trick: Turkish dotless-i and other Unicode case-folding surprises

```bash
echo 'I' | tr A-Z a-z    # byte-level: 'i', regardless of locale

LANG=tr_TR.UTF-8 python3 -c 'print("I".lower())'   # 'ı' (dotless i)
LANG=en_US.UTF-8 python3 -c 'print("I".lower())'   # 'i'
```

**What's happening:** Turkish has two letter pairs: i/İ and ı/I (dotless). Locale-aware case folding gives different answers depending on locale. `tr` operates on bytes, not Unicode, and is safe (boringly deterministic) — but tools that do "real" case-folding aren't.
**Gotcha:** "ÜSER == üser == USER" via `tr`/`awk` byte-folding isn't safe internationally. Case-insensitive identifier matching is its own can of worms — Unicode case-folding is locale-dependent for the affected scripts.
**When to use:** be aware of the issue. For ASCII-only data, `tr` is fine. For multilingual data, use a real Unicode library.

#### Trick: numeric vs. lexical sort

```bash
printf '%s\n' 1 10 2 20 100 | sort
# 1   <- lexical: '1' < '10' < '100' < '2' < '20'
# 10
# 100
# 2
# 20

printf '%s\n' 1 10 2 20 100 | sort -n
# 1   <- numeric
# 2
# 10
# 20
# 100

printf '%s\n' v1.10 v1.2 v1.20 v2.1 | sort -V
# v1.2  <- version sort: dotted-numeric segments
# v1.10
# v1.20
# v2.1
```

**What's happening:** default sort is lexical (string compare). `-n` is numeric. `-V` (GNU) is "version sort" — splits on non-digits, compares numeric segments numerically.
**Gotcha:** `-V` is GNU-only. `-h` is GNU's "human numeric" (`1K < 1M < 1G`). Mixing locale-aware decimal separators (`,` vs `.`) under `-n` is locale-dependent.
**When to use:** `-n` for plain numbers; `-V` for version strings, semver, anything with embedded numbers in a non-trivial order.

#### Trick: deterministic CSV/TSV pipelines

```bash
# always set LC_ALL=C at the top of pipelines that involve sort/comm/join/uniq
LC_ALL=C sort -t$'\t' -k1,1 file.tsv | LC_ALL=C uniq -f0
```

**What's happening:** if any stage uses a different locale, intermediate steps silently misalign. Setting `LC_ALL=C` once at the top of the pipeline (via env or `export`) covers every child.
**Gotcha:** putting `LC_ALL=C` only in front of the first command DOESN'T propagate to children of a pipe — each pipeline stage is its own process with its own environment. Either `export LC_ALL=C` in the surrounding script, or repeat it per stage.
**When to use:** any data-processing pipeline that needs to produce identical output on different machines.

### The exercise

Build `bin/locale-bomb`: a script that processes a fixed input corpus three different ways and demonstrates locale-induced bugs.

1. sort lines and `uniq -c` under default locale vs. `LC_ALL=C`
2. grep for `[A-Z]` matches vs. `[[:upper:]]` matches
3. sort version-like strings (`v1.2`, `v1.10`) lexically vs. `-V`
4. compute `comm -12` between two files with one side sorted under `LC_ALL=de_DE.UTF-8` and the other under `LC_ALL=C` — observe the silent failure

Now write `bin/safe-pipeline` — a wrapper that:
- forces `LC_ALL=C` for everything inside
- documents the choice in the script header (with link to ex. 23)
- includes a "trust but verify" check: parse `locale` output and warn if user's environment disagrees with what the script needs

### Variants comparison: "case-insensitive sort"

| Approach                           | Locale-stable? | Speed | Notes                       |
| ---------------------------------- | -------------- | ----- | --------------------------- |
| `sort -f`                          | depends on locale | fast | uses locale's case-fold     |
| `tr '[:upper:]' '[:lower:]' \| sort` | byte-level   | medium | safe; loses original case   |
| `LC_ALL=C sort -f`                 | safe (ASCII) | fast | clear semantics             |
| `python3 -c 'import sys; ...'`     | full Unicode | slow | when you need real Unicode  |

### Optional: locked variant

Re-do every step of `locale-bomb` **under `LC_ALL=tr_TR.UTF-8`** (install with `locale-gen tr_TR.UTF-8` or `localedef -i tr_TR -f UTF-8 tr_TR.UTF-8`). Document what newly breaks (case-fold of `I`/`i`, dotless-i, `[A-Z]` ranges).

### Optional: scoring rubric

- [ ] script demonstrates ≥4 distinct locale-related bugs
- [ ] each demo has a "before" (broken) and "after" (fixed) version
- [ ] `safe-pipeline` actually fails-fast on locale mismatch
- [ ] passes `shellcheck` clean
- [ ] (locked) Turkish locale demo specifically shows the dotless-i issue

### Break it

- [ ] script run in a Docker container with `LANG` unset entirely (defaults to `C`)
- [ ] script run with `LC_ALL=POSIX` (synonym for C — should behave the same)
- [ ] input containing UTF-8 BOM at start of file
- [ ] input containing combining characters (`é` as `e` + combining-acute vs precomposed)
- [ ] German `ß` vs `ss` — does your sort/compare consider them equal? (locale-dependent)
- [ ] CJK input under `LC_ALL=ja_JP.UTF-8` vs. `LC_ALL=C` — different sort orders



---

[← ex. 22](../22-locking-and-atomic-writes/) · [ex. 24 →](../24-arithmetic-gotchas/)
