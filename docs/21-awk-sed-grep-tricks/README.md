# 21. `awk` / `sed` / `grep` tricks for bash users


**Goal:** Apply less-used features of the classic Unix tools (`awk`, `sed`, `grep`, `comm`, `paste`, `tr`).

### Techniques

#### Trick: `awk 'FNR==NR{...; next} {...}' a b` — two-file lookups

```bash
# print lines from b.txt whose first field appears in a.txt
awk 'FNR==NR { keep[$1]; next } $1 in keep' a.txt b.txt
```

**What's happening:** `FNR` is the record number within the *current* file; `NR` is the running total. They're equal only while processing the first file. The `; next` skips the rest of the rules so the second pattern only fires on subsequent files.
**Gotcha:** `$1 in keep` is the membership test; `keep[$1]` (used in the first file) creates the key with an empty value, which is enough. Don't use `keep[$1]=1` — wastes memory and isn't clearer.
**When to use:** set intersection, filter "things in A by membership in B", any "join" where one side fits in memory.

#### Trick: `awk` [associative array](https://www.gnu.org/s/bash/manual/html_node/Arrays.html)s as a real data structure

```bash
# top 10 IPs by request count from access.log
awk '{ c[$1]++ } END { for (k in c) print c[k], k }' access.log \
  | sort -rn | head -10
```

**What's happening:** every awk array is associative. Keys are strings; values are numbers or strings. `c[$1]++` creates the key on first access (default value 0) and increments.
**Gotcha:** `for (k in c)` iteration order is implementation-defined. GNU awk has `PROCINFO["sorted_in"]` and `--sort`; mawk and BSD don't. Always pipe to `sort` if order matters.
**When to use:** group-and-count, top-N, deduplication, anywhere that would normally use `Counter()` in Python.

#### Trick: `sed -i` portability — GNU vs. BSD

```bash
# GNU (Linux)
sed -i 's/foo/bar/g' file

# BSD (macOS) — REQUIRES an extension argument, '' for none
sed -i '' 's/foo/bar/g' file

# portable across both:
sed -i.bak 's/foo/bar/g' file && rm file.bak
```

**What's happening:** GNU `sed -i` edits in place (no backup unless given `-i.bak`). BSD `sed -i` takes a mandatory backup extension argument — `sed -i 's/...'` on macOS deletes `s/.../g` as the backup extension and fails.
**Gotcha:** the most common cross-platform script bug. Either commit to one platform, or write `sed -i.bak ... && rm file.bak`, or use `perl -i -pe '...'` (consistent everywhere).
**When to use:** any script that edits files in place AND might run on macOS.

#### Trick: `grep -o`, `grep -z`, `grep -P`

```bash
# extract just the matched substring, one per line:
grep -oE 'HTTP/[0-9.]+' access.log | sort -u

# match across newlines (NUL-delimited records):
grep -zo 'BEGIN.*END' multiline.txt

# PCRE — lookahead, lookbehind, \K
grep -oP '(?<=password=)\S+' config.txt
```

**What's happening:** `-o` prints only the matched portion, not the full line. `-z` treats input as NUL-separated records (lets `.` match newlines because the "line" is now the whole file). `-P` enables PCRE — `\K` resets the match start, lookbehinds work, etc.
**Gotcha:** `-P` isn't in busybox. PCRE has well-known performance cliffs — pathological regexes can hang. `-z` output is also NUL-separated; pair with `tr '\0' '\n'`.
**When to use:** `-o` whenever would otherwise need `sed 's/.*\(X\).*/\1/'` — much shorter. `-P` for assertions and `\K`. `-z` for multi-line matches.

#### Trick: `comm` for set operations on sorted input

```bash
# files in B but not in A (added):
comm -13 <(sort a.txt) <(sort b.txt)

# files in A but not in B (removed):
comm -23 <(sort a.txt) <(sort b.txt)

# in both (intersection):
comm -12 <(sort a.txt) <(sort b.txt)
```

**What's happening:** `comm` reads two sorted files, prints three columns: only-in-1, only-in-2, in-both. The digit flags suppress columns: `-13` keeps column 2 only.
**Gotcha:** input MUST be sorted under the SAME locale. `LC_ALL=C sort` on both sides — otherwise `comm` silently misbehaves. Pure set-diff: `comm` beats `diff` for output cleanliness.
**When to use:** any "what's added / removed / common" question on lists.

#### Trick: `paste -sd,` — join lines

```bash
# join all lines of a file with commas
paste -sd, file.txt
# a,b,c,d

# join pairs side by side from two files
paste -d= keys.txt values.txt
# k1=v1
# k2=v2
```

**What's happening:** `paste` columnates files side by side (one column per file). `-s` instead does series mode: concatenate within a single file. `-d` sets the delimiter (cycles through if multiple chars).
**Gotcha:** `paste` doesn't escape — if your lines contain the delimiter, you get ambiguous output. Use a delimiter that doesn't appear in data, or switch to `awk '{printf "%s,", $0}'` with explicit quoting.
**When to use:** building CSV from per-line input; transposing rows/columns; merging parallel datasets.

#### Trick: `tr -d '\r'` and `tr -s ' '` and `tr -c '[:alnum:]' '\n'`

```bash
# strip Windows CRLF -> LF
tr -d '\r' < windows.txt > unix.txt

# squeeze repeated spaces to one
echo 'a    b     c' | tr -s ' '
# a b c

# split on anything NON-alphanumeric, one token per line:
tr -c '[:alnum:]' '\n' < /etc/passwd
```

**What's happening:** `-d` deletes; `-s` squeezes runs of the same character; `-c` complements the set ("everything NOT in this set"). Operates byte-by-byte — fast and locale-friendly with `LC_ALL=C`.
**Gotcha:** `tr` works on bytes, not characters. Multi-byte UTF-8 sequences are not "one character" to `tr`. For Unicode-aware transforms, use `sed` or `perl`.
**When to use:** classic Unix glue. Faster than any equivalent in `sed` or `awk` for byte-level work.

#### Trick: `tac`, `nl`, `expand`, `fold`, `column` — utilities that don't get enough use

```bash
tac file.txt                  # reverse line order
nl -ba file.txt               # number every line including blanks
expand -t 4 file.txt          # tabs -> 4 spaces
fold -sw 80 file.txt          # word-wrap to 80 cols
column -t -s$'\t' file.tsv    # align tab-separated columns
```

**What's happening:** `tac` is `cat` backwards (last line first). `nl` is more flexible than `cat -n`. `expand`/`unexpand` for tab/space conversion. `fold -s` word-wraps. `column -t` aligns columns for human reading.
**Gotcha:** `column -t` is GNU; BSD's version has different flag spelling. `tac` is GNU; BSD calls it... well, there is no BSD `tac` (use `tail -r`).
**When to use:** quick one-off transforms where the right tool saves a long awk one-liner.

### The exercise

Write `bin/log-analyse` that takes an `access.log`-style file and prints:

1. top 10 IPs by request count
2. top 10 URLs by error rate (5xx responses)
3. list of IPs that appear in `access.log` but not in `allowlist.txt`
4. histogram of requests per minute

Implement each capability **two ways**: pure `awk` and shell pipeline (`grep | sort | uniq -c | sort | head`). Compare clarity and speed.

### Variants comparison: "top 10 by count"

| Approach                                             | Forks | Speed (1M lines) | Memory       |
| ---------------------------------------------------- | ----- | ---------------- | ------------ |
| `awk '{c[$1]++} END {for (k in c) print c[k], k}' \| sort -rn \| head` | 2 | fast | distinct keys |
| `cut -d' ' -f1 \| sort \| uniq -c \| sort -rn \| head` | ~5 | medium-fast (sort dominates) | streaming |
| pure bash assoc-array + sort                          | 1     | slow (bash loop) | distinct keys |

### Optional: locked variant

Solve every capability **without `awk` and without `perl`** — bash + coreutils only. Where does it get awkward? Re-solve with `awk` only (no `sort`/`uniq`/`head`). Compare both against the mixed-pipeline version.

### Optional: scoring rubric

- [ ] all capabilities work on a 1M-line `access.log`
- [ ] `comm` calls explicitly set `LC_ALL=C` on both sides
- [ ] handles CRLF line endings (Windows-served logs)
- [ ] passes `shellcheck` clean
- [ ] you wrote a 1-paragraph "when would I use the awk version vs. the pipeline version" note

### Break it

- [ ] log lines with embedded newlines (rare but possible with malformed UAs)
- [ ] timestamps with timezones in the input
- [ ] one IP appears 999,999 times (does the bash variant survive?)
- [ ] CRLF line endings
- [ ] `allowlist.txt` is empty
- [ ] `access.log` is gzipped (must add `zcat`/`zgrep` paths)



---

[← ex. 20](../20-xargs-patterns/) · [ex. 22 →](../22-locking-and-atomic-writes/)
