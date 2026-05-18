# 13. Bash-vs-POSIX rewrite


**Goal:** Know exactly which features are bash-only, and what the POSIX-portable equivalent is.

### Techniques

#### Trick: `[[ ... ]]` vs `[ ... ]` (test)

```bash
# bash
if [[ -d $dir && -r $dir && $dir == /tmp/* ]]; then ...; fi

# POSIX
if [ -d "$dir" ] && [ -r "$dir" ] && [ "${dir#/tmp/}" != "$dir" ]; then ...; fi
```

**What's happening:** `[[ ]]` is a bash *keyword* — no [word splitting](https://www.gnu.org/s/bash/manual/html_node/Word-Splitting.html) on its arguments, supports `&&`/`||`/`==`/`=~`/`<`/`>`. `[ ]` is a *command* (often `/usr/bin/[`); arguments need quoting and `-a`/`-o` (deprecated) or chained `&&`/`||`.
**Gotcha:** inside `[[ ]]`, `==` does globbing on the RHS unless quoted. `[[ $x == foo*bar ]]` is a glob match, `[[ $x == "foo*bar" ]]` is literal. People shoot themselves with `[[ $tag == v1.* ]]` "working" only because no file is named `v1.x`.
**When to use:** `[[ ]]` everywhere in `bash` scripts. `[ ]` only when targeting `/bin/sh` (Alpine `ash`, busybox, dash).

#### Trick: arithmetic — `(( ))` and `$(( ))` are bash; `[ ]` arithmetic is POSIX

```bash
# bash
(( count++ )); (( total = a * b ))
if (( count > 10 )); then ...; fi

# POSIX
count=$((count + 1)); total=$((a * b))
if [ "$count" -gt 10 ]; then ...; fi
```

**What's happening:** `$(( ))` is POSIX. `(( ))` (as a *statement*, no `$`) is bash — it's an arithmetic command returning 0/1 based on the result. POSIX has no equivalent statement form; you use `[ ]` with `-gt`/`-lt`/`-eq`.
**Gotcha:** under [`set -e`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html), `(( count = 0 ))` *exits the script* — its exit code is 1 when the result is 0. Use `count=0` or `: $(( count = 0 ))` instead.
**When to use:** `(( ))` for any condition involving math. POSIX scripts use `-gt`/`-lt`/`-eq` inside `[ ]` and `$(( ))` for the substitution form.

#### Trick: arrays — bash-only

```bash
# bash
arr=(a b c)
arr+=(d)
for x in "${arr[@]}"; do printf '%s\n' "$x"; done

# POSIX (using "$@" as the only array-like construct)
set -- a b c
set -- "$@" d                  # append
for x in "$@"; do printf '%s\n' "$x"; done
```

**What's happening:** POSIX shells have exactly one array — the positional parameters `$1`, `$2`, ..., aka `"$@"`. Use `set --` to assign, `set -- "$@" new` to append.
**Gotcha:** you only get *one* such "array". For multiple, you encode them as space- or newline-delimited strings (and lose NUL-safety). Function call clobbers `$@` — save with a local copy.
**When to use:** bash arrays are a huge ergonomic win — don't write POSIX-portable code unless you actually need it.

#### Trick: [associative array](https://www.gnu.org/s/bash/manual/html_node/Arrays.html)s — bash 4+ only

```bash
# bash
declare -A m
m["one"]=1; m["two"]=2
echo "${m[one]}"
for key in "${!m[@]}"; do echo "$key -> ${m[$key]}"; done

# POSIX workaround: use eval or external storage
get() { eval "echo \$_kv_$1"; }
set_() { eval "_kv_$1=\$2"; }
set_ one 1; get one
```

**What's happening:** bash 4 added associative arrays. Pre-4 (notably macOS bash 3.2), the equivalent uses variable-name prefixes and `eval`, which carries its own quoting hazards.
**Gotcha:** macOS ships bash 3.2 by default. Scripts using [`declare -A`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-declare) either need bash 4+ (homebrew) or the `eval`-based fallback.
**When to use:** any context where bash 4+ is acceptable. The `eval`-based fallback is fragile enough that it is often a reason to switch to the `awk` or `sort | uniq -c` variant (ex. 4).

#### Trick: features that have NO POSIX equivalent

```bash
# bash-only — no clean POSIX form:
mapfile -t lines < file
coproc REPL { python3 -i; }
diff <(sort a) <(sort b)
[[ $line =~ ^([0-9]+):(.*)$ ]] && echo "${BASH_REMATCH[1]}"
local var
declare -i counter=0
${var:0:5}      # substring extraction
```

**What's happening:** [`mapfile`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-mapfile) → `while read`. [`coproc`](https://www.gnu.org/s/bash/manual/html_node/Coprocesses.html) → `mkfifo`. Process substitution → temp file with `trap`. `=~` and [`BASH_REMATCH`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-BASH_005fREMATCH) → `expr` or `case` patterns or `grep -o`. Substring → `expr substr` or pipe to `cut`.
**Gotcha:** the POSIX equivalents exist for *most* features, but lose ergonomics or NUL-safety. `local` is missing from strict POSIX entirely — you simulate by saving and restoring globals.
**When to use:** know the feature/equivalent pairs before claiming a script is "portable".

### The exercise

Pick one earlier script (recommend ex. 4 `log-count` or ex. 5 `filter-lines`) and rewrite it **twice**:

1. `bin/tool.bash` — use everything bash gives you: arrays, `[[ ]]`, `(( ))`, `${var:offset:length}`, `=~` with `BASH_REMATCH`, `mapfile`, [process substitution](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html).
2. `bin/tool.sh` — POSIX-portable, runs under [`dash`](https://man7.org/linux/man-pages/man1/dash.1.html) and Alpine's `ash`. No bashisms.

Verify both pass `shellcheck` (with `-s sh` for the POSIX version). Run the POSIX one under `dash` (`apt install dash`) and confirm.

### Variants comparison

| Feature                | bash form              | POSIX equivalent              | Cost of porting       |
| ---------------------- | ---------------------- | ----------------------------- | --------------------- |
| arrays                 | `arr=(...)`            | `set -- ...`                  | one "array" only      |
| associative arrays     | `declare -A m`         | `eval`-based, or awk          | fragile + injection-prone |
| `[[ ]]`                | `[[ -d $x && $x == * ]]` | chained `[ ]`               | more verbose, quote |
| process substitution   | `<(cmd)`               | temp file + trap              | cleanup boilerplate   |
| `mapfile -t`           | one line               | `while read` loop             | slightly slower       |
| `=~` regex             | `BASH_REMATCH`         | `expr` / `case` / `grep`      | external command      |
| `${var:offset:length}` | builtin                | `expr substr "$var" 2 5`      | fork                  |

### Optional: locked variant

Write the **POSIX version targeting dash specifically** (the Debian `/bin/sh`). Run `shellcheck -s sh` and `dash -n` on it. Surprise yourself with the `local` keyword being missing — work around it.

### Optional: scoring rubric

- [ ] bash version uses ≥3 distinct bash-only features
- [ ] POSIX version produces identical output to bash version on the test corpus
- [ ] POSIX version passes `shellcheck -s sh`
- [ ] POSIX version runs under `dash` (`apt install dash`) without errors
- [ ] you wrote a 1-paragraph diff between the two: what changed, what got uglier

### Break it

- [ ] feed both versions input with embedded newlines
- [ ] run POSIX version with `bash --posix`
- [ ] run POSIX version with `ash` (Alpine, busybox) — even stricter
- [ ] use a feature that's bash-only but `shellcheck -s sh` doesn't catch (rare but exists)



---

[← ex. 12](../12-programmable-completion/) · [ex. 14 →](../14-performance-kata/)
